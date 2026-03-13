#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "click>=8.1.7",
#   "rich>=13.7.1",
# ]
# ///

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import click
from rich.console import Console
from rich.table import Table

MAX_ALLOWED_LINES = 500
MAX_INDENTATION_STREAK = 10
TAB_WIDTH_SPACES = 2

DISALLOWED_LAYER_A_IMPORTS = (
    "package:flutter/material.dart",
    "package:flutter/widgets.dart",
)

SKIP_DIRECTORIES = {
    ".dart_tool",
    ".git",
    ".idea",
    ".vscode",
    ".venv",
    "build",
    "coverage",
    "node_modules",
}

GENERATED_FILE_SUFFIXES = (
    ".g.dart",
    ".freezed.dart",
    ".gr.dart",
    ".mocks.dart",
)


@dataclass
class FileValidationResult:
    file: str
    status: str
    line_count: int
    max_indentation_streak: int
    layer_a_file: bool
    checks: dict[str, dict[str, Any]]
    messages: list[str]

    def to_dict(self) -> dict[str, Any]:
        return {
            "file": self.file,
            "status": self.status,
            "line_count": self.line_count,
            "max_indentation_streak": self.max_indentation_streak,
            "layer_a_file": self.layer_a_file,
            "checks": self.checks,
            "messages": self.messages,
        }


def should_skip(file_path: Path) -> bool:
    lower_parts = {part.lower() for part in file_path.parts}
    if lower_parts.intersection(SKIP_DIRECTORIES):
        return True
    return file_path.name.endswith(GENERATED_FILE_SUFFIXES)


def resolve_target(target: Path | None, option_path: Path | None) -> Path:
    if target is None and option_path is None:
        raise ValueError("Provide a target path via --path or positional TARGET.")

    if target is not None and option_path is not None and target != option_path:
        raise ValueError(
            "Received both positional TARGET and --path with different values. Use one path input."
        )

    selected = option_path if option_path is not None else target
    if selected is None:
        raise ValueError("No path provided.")

    selected = selected.resolve()
    if not selected.exists():
        raise FileNotFoundError(f"Path does not exist: {selected}")
    return selected


def discover_dart_files(scan_path: Path) -> list[Path]:
    if scan_path.is_file():
        if scan_path.suffix != ".dart":
            raise ValueError(f"Target must be a .dart file or directory: {scan_path}")
        return [scan_path]

    if not scan_path.is_dir():
        raise ValueError(f"Unsupported target type: {scan_path}")

    files = [file for file in sorted(scan_path.rglob("*.dart")) if not should_skip(file)]
    if not files:
        raise ValueError(f"No .dart files found under: {scan_path}")
    return files


def is_layer_a_file(file_path: Path) -> bool:
    normalized = f"/{file_path.as_posix().lower()}/"
    return "/services/" in normalized or "/models/" in normalized


def find_layer_a_import_violations(content: str) -> list[str]:
    violations: list[str] = []
    for forbidden_import in DISALLOWED_LAYER_A_IMPORTS:
        if forbidden_import in content:
            violations.append(forbidden_import)
    return violations


def estimate_max_indentation_streak(content: str) -> int:
    previous_depth: int | None = None
    current_streak = 0
    max_streak = 0

    for raw_line in content.splitlines():
        stripped = raw_line.strip()
        if not stripped:
            continue

        leading_whitespace = raw_line[: len(raw_line) - len(raw_line.lstrip(" \t"))]
        expanded = leading_whitespace.replace("\t", " " * TAB_WIDTH_SPACES)
        depth = len(expanded) // TAB_WIDTH_SPACES

        if previous_depth is None:
            current_streak = 0
        elif depth > previous_depth:
            current_streak += 1
        elif depth < previous_depth:
            current_streak = 0

        if current_streak > max_streak:
            max_streak = current_streak

        previous_depth = depth

    return max_streak


def analyze_file(file_path: Path, cwd: Path) -> FileValidationResult:
    content = file_path.read_text(encoding="utf-8", errors="replace")
    line_count = len(content.splitlines())
    max_indentation_streak = estimate_max_indentation_streak(content)
    layer_a = is_layer_a_file(file_path)

    line_count_status = "PASS" if line_count <= MAX_ALLOWED_LINES else "FAIL"
    import_violations = find_layer_a_import_violations(content) if layer_a else []
    layer_status = "FAIL" if import_violations else "PASS"
    nesting_status = "WARN" if max_indentation_streak > MAX_INDENTATION_STREAK else "PASS"

    messages: list[str] = []
    if line_count_status == "FAIL":
        messages.append(
            f"Line count {line_count} exceeds {MAX_ALLOWED_LINES} (500-Line Rule violation)."
        )
    if layer_status == "FAIL":
        messages.append(
            "Layer A file imports Flutter UI package(s): " + ", ".join(import_violations)
        )
    if nesting_status == "WARN":
        messages.append(
            f"Estimated indentation streak {max_indentation_streak} exceeds {MAX_INDENTATION_STREAK}."
        )

    if line_count_status == "FAIL" or layer_status == "FAIL":
        overall_status = "FAIL"
    elif nesting_status == "WARN":
        overall_status = "WARN"
    else:
        overall_status = "PASS"

    checks: dict[str, dict[str, Any]] = {
        "line_count": {
            "status": line_count_status,
            "actual": line_count,
            "limit": MAX_ALLOWED_LINES,
        },
        "layer_a_flutter_import": {
            "status": layer_status,
            "layer_a_file": layer_a,
            "forbidden_imports_found": import_violations,
        },
        "widget_nesting_basic": {
            "status": nesting_status,
            "actual": max_indentation_streak,
            "warn_threshold": MAX_INDENTATION_STREAK,
        },
    }

    try:
        relative = file_path.relative_to(cwd)
        file_display = relative.as_posix()
    except ValueError:
        file_display = file_path.as_posix()

    return FileValidationResult(
        file=file_display,
        status=overall_status,
        line_count=line_count,
        max_indentation_streak=max_indentation_streak,
        layer_a_file=layer_a,
        checks=checks,
        messages=messages,
    )


def summarize(results: list[FileValidationResult]) -> dict[str, Any]:
    pass_count = sum(1 for result in results if result.status == "PASS")
    warn_count = sum(1 for result in results if result.status == "WARN")
    fail_count = sum(1 for result in results if result.status == "FAIL")
    return {
        "files_scanned": len(results),
        "pass": pass_count,
        "warn": warn_count,
        "fail": fail_count,
        "has_violations": fail_count > 0,
    }


def render_human_report(results: list[FileValidationResult], summary_data: dict[str, Any]) -> None:
    console = Console(stderr=True)

    table = Table(title="FlutterPOS Architecture Validation", show_lines=False)
    table.add_column("File", style="cyan", overflow="fold")
    table.add_column("Status", justify="center")
    table.add_column("Lines", justify="right")
    table.add_column("Layer A Import", justify="center")
    table.add_column("Nesting", justify="center")
    table.add_column("Notes", overflow="fold")

    for result in results:
        status_style = {
            "PASS": "green",
            "WARN": "yellow",
            "FAIL": "bold red",
        }[result.status]

        layer_check_status = result.checks["layer_a_flutter_import"]["status"]
        nesting_status = result.checks["widget_nesting_basic"]["status"]

        notes = " | ".join(result.messages) if result.messages else "OK"

        table.add_row(
            result.file,
            f"[{status_style}]{result.status}[/{status_style}]",
            str(result.line_count),
            layer_check_status,
            nesting_status,
            notes,
        )

    console.print(table)
    console.print(
        (
            f"Scanned: {summary_data['files_scanned']} | "
            f"PASS: {summary_data['pass']} | "
            f"WARN: {summary_data['warn']} | "
            f"FAIL: {summary_data['fail']}"
        ),
        style="bold",
    )


def build_json_payload(scan_target: Path, results: list[FileValidationResult]) -> dict[str, Any]:
    summary_data = summarize(results)
    return {
        "tool": "validate-architecture",
        "version": "1.0.0",
        "target": scan_target.as_posix(),
        "summary": summary_data,
        "results": [result.to_dict() for result in results],
    }


def validate_architecture(
    target: Path,
    cwd: Path,
) -> tuple[dict[str, Any], list[FileValidationResult], int]:
    files = discover_dart_files(target)
    results = [analyze_file(file_path=file, cwd=cwd) for file in files]
    payload = build_json_payload(scan_target=target, results=results)

    exit_code = 2 if payload["summary"]["has_violations"] else 0
    return payload, results, exit_code


def print_error_json(message: str) -> None:
    payload = {
        "tool": "validate-architecture",
        "error": message,
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2), file=sys.stdout)


@click.command(context_settings={"help_option_names": ["-h", "--help"]})
@click.argument("target", required=False, type=click.Path(path_type=Path))
@click.option(
    "--path",
    "option_path",
    type=click.Path(path_type=Path),
    help="Path to a .dart file or directory to validate.",
)
@click.option(
    "--json",
    "_json_output",
    is_flag=True,
    help="Compatibility flag. JSON output is always written to stdout.",
)
def main(target: Path | None, option_path: Path | None, _json_output: bool) -> None:
    cwd = Path.cwd()

    try:
        scan_target = resolve_target(target=target, option_path=option_path)
        payload, results, exit_code = validate_architecture(target=scan_target, cwd=cwd)

        render_human_report(results=results, summary_data=payload["summary"])
        print(json.dumps(payload, ensure_ascii=False, indent=2), file=sys.stdout)
        return exit_code

    except Exception as exc:  # noqa: BLE001
        console = Console(stderr=True)
        console.print(f"[bold red]Execution error:[/bold red] {exc}")
        print_error_json(str(exc))
        return 1


if __name__ == "__main__":
    try:
        code = main(standalone_mode=False)
        raise SystemExit(int(code or 0))
    except click.ClickException as exc:
        exc.show(file=sys.stderr)
        print_error_json(str(exc))
        raise SystemExit(1)