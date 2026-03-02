#!/usr/bin/env python3
"""Split database_helper_upgrade.dart into smaller upgrade batch files (<=500 lines)."""

import re
from pathlib import Path

SOURCE_PATH = Path('lib/services/database_helper_upgrade.dart')
MAIN_PATH = Path('lib/services/database_helper.dart')
OUT_DIR = Path('lib/services/database_upgrades')


def _find_upgrade_method(lines):
    start = None
    end = None
    depth = 0
    in_method = False

    for i, line in enumerate(lines):
        if '_upgradeDB' in line and 'Future<void>' in line:
            start = i
            depth = line.count('{') - line.count('}')
            in_method = True
            continue

        if in_method:
            depth += line.count('{') - line.count('}')
            if depth == 0:
                end = i
                break

    return start, end


def _extract_version_blocks(lines, start, end):
    blocks = []
    i = start + 1

    while i <= end:
        line = lines[i]
        match = re.search(r'if \(oldVersion < (\d+)\)', line)
        if match:
            version = int(match.group(1))
            block_lines = [line]
            block_depth = line.count('{') - line.count('}')
            i += 1
            while i <= end and block_depth > 0:
                block_lines.append(lines[i])
                block_depth += lines[i].count('{') - lines[i].count('}')
                i += 1
            blocks.append({
                'version': version,
                'lines': block_lines,
            })
            continue

        i += 1

    return blocks


def _group_blocks(blocks, max_lines=450):
    groups = []
    current = []
    current_lines = 0

    for block in blocks:
        block_size = len(block['lines'])
        if current and current_lines + block_size > max_lines:
            groups.append(current)
            current = []
            current_lines = 0
        current.append(block)
        current_lines += block_size

    if current:
        groups.append(current)

    return groups


def _write_group_files(groups):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    part_files = []

    for idx, group in enumerate(groups, start=1):
        versions = [b['version'] for b in group]
        min_v = min(versions)
        max_v = max(versions)
        filename = f'upgrade_v{min_v}_v{max_v}.dart'
        part_files.append(filename)

        content = ["part of '../database_helper.dart';", "", f"extension DatabaseHelperUpgradePart{idx} on DatabaseHelper {{"]
        content.append(
            f"  Future<void> _applyUpgrades_v{min_v}_v{max_v}(Database db, int oldVersion) async {{"
        )

        for block in group:
            content.extend(block['lines'])

        content.append("  }")
        content.append("}")
        content.append("")

        (OUT_DIR / filename).write_text('\n'.join(content), encoding='utf-8')

    return part_files


def _write_coordinator(part_files):
    lines = ["part of 'database_helper.dart';", "", "extension DatabaseHelperUpgrade on DatabaseHelper {", "  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {", "    for (final run in ["]

    for filename in part_files:
        match = re.search(r'upgrade_v(\d+)_v(\d+)\.dart', filename)
        if not match:
            continue
        min_v = match.group(1)
        max_v = match.group(2)
        lines.append(f"      () => _applyUpgrades_v{min_v}_v{max_v}(db, oldVersion),")

    lines.append("    ]) {")
    lines.append("      await run();")
    lines.append("    }")
    lines.append("  }")
    lines.append("}")
    lines.append("")

    SOURCE_PATH.write_text('\n'.join(lines), encoding='utf-8')


def _update_main_parts(part_files):
    main_lines = MAIN_PATH.read_text(encoding='utf-8', errors='ignore').splitlines()
    new_lines = []
    inserted = False

    for line in main_lines:
        new_lines.append(line)
        if not inserted and line.strip() == "part 'database_helper_upgrade.dart';":
            for filename in part_files:
                new_lines.append(f"part 'database_upgrades/{filename}';")
            inserted = True

    MAIN_PATH.write_text('\n'.join(new_lines), encoding='utf-8')


def main():
    lines = SOURCE_PATH.read_text(encoding='utf-8', errors='ignore').splitlines()
    start, end = _find_upgrade_method(lines)
    if start is None or end is None:
        print('ERROR: _upgradeDB not found')
        return

    blocks = _extract_version_blocks(lines, start, end)
    if not blocks:
        print('ERROR: no version blocks found')
        return

    groups = _group_blocks(blocks, max_lines=450)
    part_files = _write_group_files(groups)
    _write_coordinator(part_files)
    _update_main_parts(part_files)

    print(f"Created {len(part_files)} upgrade parts in {OUT_DIR}")


if __name__ == '__main__':
    main()
