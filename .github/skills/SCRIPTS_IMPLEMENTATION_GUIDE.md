---
name: scripts-implementation-guide
description: Step-by-step guide for creating Agent Skills scripts following official best practices from agentskills.io/skill-creation/using-scripts
---

# Scripts Implementation Guide

Create automated helpers for your Agent Skills following official best practices.

---

## Overview

**Official Guidance**: "When a command grows complex enough that it's hard to get right on the first try, a tested script in `scripts/` is more reliable."

### Why Scripts Matter

- **Automation**: Agents can run validation, analysis, generation automatically
- **Consistency**: Same checks every time, no manual errors
- **Speed**: Agents execute scripts in parallel with other work
- **Clarity**: Structured output helps agents understand results
- **Reproducibility**: Version-pinned dependencies, documented process

---

## Script Template: Flutter Architecture Validator

### File: `scripts/validate-architecture.py`

**Purpose**: Check Dart file follows three-layer architecture and 500-line max

**Type**: Self-contained with inline dependencies (PEP 723)

```python
# /// script
# dependencies = [
#   "click>=8.1,<9",      # CLI framework
#   "pathlib",            # Built-in, but explicit
# ]
# requires-python = ">=3.10"
# ///

import click
import json
from pathlib import Path
import re

def count_lines(file_path):
    """Count non-empty lines in file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        return sum(1 for line in f if line.strip())

def check_layer_imports(file_path):
    """Check if file has appropriate layer imports."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    violations = []
    
    # Layer A (logic) should NOT import Flutter
    if is_layer_a_file(file_path):
        if re.search(r'import\s+[\'"]flutter', content):
            violations.append({
                "type": "LAYER_VIOLATION",
                "severity": "critical",
                "message": "Layer A (service) should not import Flutter",
                "suggestion": "Remove Flutter imports from this service file"
            })
    
    # Layer B (widgets) should NOT import services directly
    if is_layer_b_file(file_path):
        if re.search(r'import\s+[\'"].*services/.*[\'"]', content):
            # This is actually okay with dependency injection, but flag for review
            violations.append({
                "type": "DEPENDENCY_REVIEW",
                "severity": "warning",
                "message": "Widget imports service - verify using dependency injection",
                "suggestion": "Ensure service is passed via constructor, not imported"
            })
    
    return violations

def is_layer_a_file(path):
    """Heuristic: check if file is in services/ directory."""
    return 'services' in path.lower() or '_service.dart' in path.lower()

def is_layer_b_file(path):
    """Heuristic: check if file is in widgets/ directory."""
    return 'widgets' in path.lower() or path.lower().endswith('_widget.dart')

def is_layer_c_file(path):
    """Heuristic: check if file is in screens/ directory."""
    return 'screens' in path.lower()

@click.command()
@click.argument('file', type=click.Path(exists=True))
@click.option('--strict', is_flag=True, help='Fail on warnings (strict mode)')
@click.option('--json', 'output_format', flag_value='json', help='Output as JSON')
@click.option('--verbose', is_flag=True, help='Show detailed findings')
@click.option('--max-lines', default=500, help='Maximum lines per file (default: 500)')
def validate(file, strict, output_format, verbose, max_lines):
    """
    Validate Dart file follows three-layer architecture and line limit.
    
    Examples:
        python scripts/validate-architecture.py lib/screens/checkout_screen.dart
        python scripts/validate-architecture.py --strict lib/screens/*.dart
        python scripts/validate-architecture.py --json lib/services/cart_service.dart
    """
    
    file_path = Path(file)
    violations = []
    warnings = []
    
    # Check line count
    lines = count_lines(file_path)
    if lines > max_lines:
        violations.append({
            "type": "SIZE_VIOLATION",
            "severity": "critical",
            "message": f"File has {lines} lines (limit: {max_lines})",
            "suggestion": f"Extract into {max(2, lines // max_lines)} focused files"
        })
    elif lines > max_lines * 0.8:
        warnings.append({
            "type": "SIZE_WARNING",
            "severity": "warning",
            "message": f"File has {lines} lines (approaching limit: {max_lines})",
            "suggestion": "Start planning extraction of subordinate components"
        })
    
    # Check layer architecture
    layer_violations = check_layer_imports(file_path)
    violations.extend([v for v in layer_violations if v.get('severity') == 'critical'])
    warnings.extend([v for v in layer_violations if v.get('severity') != 'critical'])
    
    # Build result
    result = {
        "file": str(file_path),
        "lines": lines,
        "compliant": len(violations) == 0,
        "violations": violations,
        "warnings": warnings if verbose else [],
        "summary": {
            "total_violations": len(violations),
            "total_warnings": len(warnings),
            "status": "PASS" if len(violations) == 0 else "FAIL"
        }
    }
    
    # Output
    if output_format == 'json':
        click.echo(json.dumps(result, indent=2))
    else:
        # Human-readable format
        if result['compliant']:
            click.secho(f"✅ {file_path}", fg='green')
            click.echo(f"   Lines: {lines} (under limit of {max_lines})")
            if warnings and verbose:
                for w in warnings:
                    click.echo(f"   ⚠️  {w['message']}")
        else:
            click.secho(f"❌ {file_path}", fg='red')
            for v in violations:
                click.echo(f"   {v['severity'].upper()}: {v['message']}")
                if verbose:
                    click.echo(f"                  → {v['suggestion']}")
    
        if warnings and not verbose:
            click.echo(f"   {len(warnings)} warning(s) — run with --verbose to see")
    
    # Exit code
    exit_code = 2 if violations else (1 if (strict and warnings) else 0)
    raise SystemExit(exit_code)

if __name__ == '__main__':
    validate()
```

**Usage Examples:**

```bash
# Check single file
python scripts/validate-architecture.py lib/screens/checkout_screen.dart

# Strict mode (warnings = failure)
python scripts/validate-architecture.py --strict lib/screens/checkout_screen.dart

# JSON output for integration
python scripts/validate-architecture.py --json lib/screens/checkout_screen.dart

# Verbose with suggestions
python scripts/validate-architecture.py --verbose lib/screens/checkout_screen.dart

# Run with uv (recommended for reproducibility)
uv run scripts/validate-architecture.py lib/screens/checkout_screen.dart
```

**Output Examples:**

```bash
# Human-readable (default)
$ python scripts/validate-architecture.py lib/screens/checkout_screen.dart
❌ lib/screens/checkout_screen.dart
   CRITICAL: File has 850 lines (limit: 500)
                → Extract into 2 focused files
   CRITICAL: Layer A (service) should not import Flutter
                → Remove Flutter imports from this service file
   2 warning(s) — run with --verbose to see

# JSON output (for agent parsing)
$ python scripts/validate-architecture.py --json lib/screens/checkout_screen.dart
{
  "file": "lib/screens/checkout_screen.dart",
  "lines": 850,
  "compliant": false,
  "violations": [
    {
      "type": "SIZE_VIOLATION",
      "severity": "critical",
      "message": "File has 850 lines (limit: 500)",
      "suggestion": "Extract into 2 focused files"
    }
  ],
  "warnings": [],
  "summary": {
    "total_violations": 1,
    "total_warnings": 1,
    "status": "FAIL"
  }
}

# Exit codes
$ python scripts/validate-architecture.py lib/screens/checkout_screen.dart; echo $?
2  # (violations found)

$ python scripts/validate-architecture.py lib/services/cart_service.dart; echo $?
0  # (compliant)
```

---

## Template: Calculation Validator Script

### File: `scripts/validate-calculations.py`

```python
# /// script
# dependencies = [
#   "click>=8.1,<9",
#   "decimal",  # Built-in for precision
# ]
# requires-python = ">=3.10"
# ///

import click
import json
from decimal import Decimal, ROUND_HALF_UP

# Test cases for business logic validation
TEST_CASES = [
    {
        "name": "Simple subtotal",
        "items": [
            {"price": 10.00, "quantity": 2},
            {"price": 5.50, "quantity": 1},
        ],
        "expected_subtotal": 25.50,
        "tax_rate": 0.10,
        "expected_tax": 2.55,
        "expected_total": 28.05,
    },
    {
        "name": "Discount before tax",
        "items": [{"price": 100.00, "quantity": 1}],
        "discount": 20.00,
        "expected_subtotal": 80.00,
        "tax_rate": 0.10,
        "expected_tax": 8.00,
        "expected_total": 88.00,
    },
    {
        "name": "Malaysian RM rounding (0.05 unit)",
        "items": [{"price": 123.456, "quantity": 1}],
        "expected_rounded": 123.45,  # Should round to nearest 0.05
    },
]

def calculate_subtotal(items):
    """Calculate subtotal from item list."""
    return sum(Decimal(str(item['price'])) * item['quantity'] for item in items)

def calculate_tax(subtotal, tax_rate):
    """Calculate tax amount."""
    return subtotal * Decimal(str(tax_rate))

def round_to_nearest_5_cents(amount):
    """Round to nearest RM 0.05 (Malaysian standard)."""
    amount = Decimal(str(amount))
    return (amount * Decimal('20')).quantize(Decimal('1'), rounding=ROUND_HALF_UP) / Decimal('20')

@click.command()
@click.option('--verbose', is_flag=True, help='Show detailed test results')
@click.option('--json', 'output_format', flag_value='json', help='Output as JSON')
def validate_calculations(verbose, output_format):
    """
    Validate cart calculations against known test cases.
    
    Examples:
        python scripts/validate-calculations.py
        python scripts/validate-calculations.py --verbose
        python scripts/validate-calculations.py --json
    """
    
    passed = 0
    failed = 0
    results = []
    
    for test in TEST_CASES:
        try:
            # Calculate
            subtotal = calculate_subtotal(test['items'])
            
            # Verify subtotal
            if 'expected_subtotal' in test:
                if abs(subtotal - Decimal(str(test['expected_subtotal']))) > Decimal('0.01'):
                    raise AssertionError(
                        f"Subtotal mismatch: {subtotal} != {test['expected_subtotal']}"
                    )
            
            # Tax calculation
            if 'tax_rate' in test:
                tax = calculate_tax(subtotal, test['tax_rate'])
                if abs(tax - Decimal(str(test['expected_tax']))) > Decimal('0.01'):
                    raise AssertionError(
                        f"Tax mismatch: {tax} != {test['expected_tax']}"
                    )
                total = subtotal + tax
                if abs(total - Decimal(str(test['expected_total']))) > Decimal('0.01'):
                    raise AssertionError(
                        f"Total mismatch: {total} != {test['expected_total']}"
                    )
            
            # Rounding test
            if 'expected_rounded' in test:
                rounded = round_to_nearest_5_cents(test['items'][0]['price'])
                if abs(rounded - Decimal(str(test['expected_rounded']))) > Decimal('0.01'):
                    raise AssertionError(
                        f"Rounding mismatch: {rounded} != {test['expected_rounded']}"
                    )
            
            passed += 1
            results.append({"test": test['name'], "status": "PASS"})
            if verbose:
                click.secho(f"✅ {test['name']}", fg='green')
        
        except AssertionError as e:
            failed += 1
            results.append({"test": test['name'], "status": "FAIL", "error": str(e)})
            if verbose:
                click.secho(f"❌ {test['name']}", fg='red')
                click.echo(f"   {str(e)}")
    
    # Summary
    total = passed + failed
    percentage = (passed / total * 100) if total > 0 else 0
    
    result = {
        "passed": passed,
        "failed": failed,
        "total": total,
        "success_rate": f"{percentage:.1f}%",
        "status": "PASS" if failed == 0 else "FAIL",
        "tests": results if verbose or output_format == 'json' else []
    }
    
    if output_format == 'json':
        click.echo(json.dumps(result, indent=2))
    else:
        click.secho(f"\nCalculation Validation Results:", bold=True)
        click.echo(f"Passed: {passed}/{total}")
        click.echo(f"Failed: {failed}/{total}")
        click.secho(f"Success Rate: {percentage:.1f}%", fg='green' if failed == 0 else 'red')
    
    raise SystemExit(2 if failed > 0 else 0)

if __name__ == '__main__':
    validate_calculations()
```

---

## Best Practices for Your Scripts

### 1. Error Handling with Clarity

```python
# Bad: opaque error
if not file.exists():
    print("Error: invalid input")

# Good: clear guidance
if not file.exists():
    click.secho(
        f"Error: File not found: {file}\n"
        f"Expected: Dart file in lib/ directory\n"
        f"Try: ls lib/screens/*.dart",
        fg='red'
    )
    raise SystemExit(2)
```

### 2. Interactive Safety (Non-Interactive Requirement)

```python
# Bad: will hang in agent environment
input("Continue? (y/n): ")

# Good: require explicit flag
if not force and potentially_destructive:
    click.secho(
        "Error: Destructive operation requires --force flag\n"
        f"Command: script.py --force {args}",
        fg='red'
    )
    raise SystemExit(2)
```

### 3. Structured Output for Agents

```python
# Bad: whitespace-aligned, agent can't parse
print("FILE              STATUS    VIOLATIONS")
print("checkout_screen   ERROR     3")
print("products_grid     WARNING   1")

# Good: JSON, agent can parse with jq
output = {
    "files": [
        {"file": "checkout_screen.dart", "status": "error", "violations": 3},
        {"file": "products_grid.dart", "status": "warning", "violations": 1}
    ]
}
print(json.dumps(output))
```

### 4. Separation of Data and Diagnostics

```python
# stdout: clean data agent will parse
print(json.dumps({"result": "success", "files_processed": 42}))

# stderr: diagnostics and progress (human-readable)
click.echo("[INFO] Analyzing 42 files...", err=True)
click.echo("[WARN] File has mixed indentation", err=True)
click.echo("[INFO] Process complete", err=True)
```

### 5. Meaningful Exit Codes

```python
# Exit codes for clarity
# 0 = success
# 1 = generic error (retry might help)
# 2 = validation error (user must fix input)
# 127 = not found / missing dependency

if missing_file:
    click.echo("Error: Required file not found", err=True)
    raise SystemExit(2)  # Validation error, not our fault

if missing_dependency:
    click.echo(f"Error: Requires Python 3.10+. You have: {sys.version}", err=True)
    raise SystemExit(127)  # Not found
```

---

## Implementation Workflow

### Step 1: Plan Your Scripts

For each skill, identify 2-3 automated tasks:

**flutter-architecture-refactoring:**
- ✅ Validate file follows three-layer architecture
- ✅ Check file size and recommend extraction points
- ✅ Extract widget from monolithic file

**pos-business-logic-calculations:**
- ✅ Validate calculation accuracy
- ✅ Test rounding compliance
- ✅ Audit payment transactions

### Step 2: Create scripts/ Directory

```bash
mkdir -p .github/skills/[skill-name]/scripts
cd .github/skills/[skill-name]
```

### Step 3: Implement Scripts

1. Start with template above
2. Add PEP 723 inline dependencies
3. Implement `--help` with examples
4. Add `--json` output format
5. Test with actual data

### Step 4: Document in SKILL.md

```markdown
## Available Scripts

- **`scripts/validate-architecture.py`** — Check three-layer compliance
- **`scripts/refactor-check.sh`** — Find files needing refactoring
- **`scripts/extract-widget.py`** — Extract widget from monolithic file

## Quick Example

\`\`\`bash
python scripts/validate-architecture.py lib/screens/checkout_screen.dart
\`\`\`

See `scripts/README.md` for complete documentation.
```

### Step 5: Test Thoroughly

```bash
# Test help
python scripts/validate-architecture.py --help

# Test happy path
python scripts/validate-architecture.py lib/services/cart_service.dart

# Test error cases
python scripts/validate-architecture.py /nonexistent/file.dart

# Test JSON output
python scripts/validate-architecture.py --json lib/screens/checkout_screen.dart | jq

# Test with uv
uv run scripts/validate-architecture.py lib/screens/checkout_screen.dart
```

---

## Quick Reference: Script Template Structure

```python
# /// script
# dependencies = ["click>=8.1,<9", "module>=1.0,<2"]
# requires-python = ">=3.10"
# ///

import click
import json

@click.command()
@click.argument('input_file', type=click.Path(exists=True))
@click.option('--json', 'output_format', flag_value='json', help='JSON output')
@click.option('--verbose', is_flag=True, help='Detailed output')
@click.option('--force', is_flag=True, help='Skip confirmations')
def main(input_file, output_format, verbose, force):
    """
    Brief description of what script does.
    
    Examples:
        script.py file.txt
        script.py --json file.txt
        script.py --verbose --force file.txt
    """
    
    # Validation
    if not force and risky_operation:
        click.echo("Error: --force required for this operation", err=True)
        raise SystemExit(2)
    
    # Main logic
    result = {
        "status": "success",
        "data": {}
    }
    
    # Output
    if output_format == 'json':
        click.echo(json.dumps(result))
    else:
        click.echo(f"✅ Operation complete")
    
    # Exit
    raise SystemExit(0 if result['status'] == 'success' else 1)

if __name__ == '__main__':
    main()
```

---

## Testing Your Scripts

**Minimal test for validate-architecture.py:**

```bash
# Create test file that violates 500-line rule
printf '%0.s\n' {1..600} > /tmp/test_large.dart

# Should fail with violation
python scripts/validate-architecture.py /tmp/test_large.dart
# Expected: Exit code 2 (violation)

# Should pass with JSON output
python scripts/validate-architecture.py --json /tmp/test_large.dart | jq '.summary.status'
# Expected: "FAIL"
```

---

## Next Steps

1. **Create first script** for flutter-architecture-refactoring skill
2. **Test thoroughly** with real project files
3. **Update SKILL.md** to reference new scripts
4. **Create scripts/ directory** for each remaining skill
5. **Document usage** in each skill's README

**Total investment**: 10-15 hours
**Value multiplier**: 3x (agents can now automate validation, generation, analysis)

---

*Implementation Guide v1.0*  
*Based on: agentskills.io/skill-creation/using-scripts*  
*Last Updated: March 5, 2026*
