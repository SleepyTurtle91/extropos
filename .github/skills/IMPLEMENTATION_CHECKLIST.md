---
name: implementation-checklist
description: Official best practices checklist for Agent Skills implementation per agentskills.io specification and VS Code integration guidelines.
---

# Agent Skills Implementation Checklist

Based on official references:
- 🔗 [agentskills.io/specification](https://agentskills.io/specification)
- 🔗 [agentskills.io/skill-creation/using-scripts](https://agentskills.io/skill-creation/using-scripts)
- 🔗 [VS Code Agent Plugins Documentation](https://code.visualstudio.com/docs/copilot/customization/agent-plugins)

---

## ✅ Current Implementation Status

### SKILL.md Files (Specification Compliance)

| Skill | SKILL.md | Frontmatter | Body | References | Status |
|-------|----------|-----------|------|-----------|--------|
| flutter-architecture-refactoring | ✅ | ✅ | ✅ | ✅ ARCHITECTURE_DETAILED.md | Complete |
| pos-business-logic-calculations | ✅ | ✅ | ✅ | ✅ CALCULATIONS_DETAILED.md | Complete |
| pos-ui-responsive-design | ✅ | ✅ | ✅ | ⏳ Pending | Ready for scripts |
| flutter-testing-quality | ✅ | ✅ | ✅ | ⏳ Pending | Ready for scripts |
| pos-hardware-integration | ✅ | ✅ | ✅ | ⏳ Pending | Ready for scripts |

### Frontmatter Implementation

```yaml
# Current - ✅ COMPLIANT
name: skill-name
description: Clear, actionable description
license: Proprietary
metadata:
  # includes: author, version, domain, focus
compatibility:
  # includes agent compatibility info
```

✅ **All 5 SKILL.md files are specification-compliant**

---

## 🚀 Enhancement Opportunities

### Phase 1: Add Scripts (scripts/ directories)

**Official Guidance**: "When a command grows complex enough that it's hard to get right on the first try, a tested script in `scripts/` is more reliable."

#### For flutter-architecture-refactoring

```
scripts/
├── validate-architecture.py
│   Purpose: Check file follows 500-line rule and three-layer separation
│   Usage: python scripts/validate-architecture.py lib/screens/my_screen.dart
│   Output: JSON report with violations
│
├── refactor-check.sh
│   Purpose: Identify candidates for refactoring
│   Usage: bash scripts/refactor-check.sh lib/screens
│   Output: List of files needing refactoring with line counts
│
└── extract-widget.py
    Purpose: Extract a widget from a monolithic file
    Usage: python scripts/extract-widget.py --file src --widget CartItemCard
    Output: Extracted widget file ready to use
```

#### For pos-business-logic-calculations

```
scripts/
├── validate-calculations.py
│   Purpose: Validate cart math accuracy against known test cases
│   Usage: python scripts/validate-calculations.py
│   Output: Pass/fail report, percentage accuracy
│
├── test-rounding.py
│   Purpose: Test Malaysian RM 0.05 rounding edge cases
│   Usage: python scripts/test-rounding.py --amount 123.456
│   Output: Actual amount after rounding
│
└── payment-audit.py
    Purpose: Audit payment calculations in transaction logs
    Usage: python scripts/payment-audit.py --log transactions.json
    Output: Discrepancies found, audit report
```

#### For pos-ui-responsive-design

```
scripts/
├── layout-validator.py
│   Purpose: Check responsive layout compliance
│   Usage: python scripts/layout-validator.py lib/widgets
│   Output: List of non-responsive UI patterns
│
├── breakpoint-calc.sh
│   Purpose: Calculate responsive breakpoints for screen sizes
│   Usage: bash scripts/breakpoint-calc.sh 1920 1080
│   Output: Recommended column counts and spacing
│
└── touch-target-auditor.py
    Purpose: Check touch targets meet 48x48dp minimum
    Usage: python scripts/touch-target-auditor.py lib/widgets
    Output: Widgets with undersized touch targets
```

#### For flutter-testing-quality

```
scripts/
├── coverage-checker.py
│   Purpose: Run tests and report coverage by layer
│   Usage: python scripts/coverage-checker.py --target Layer A
│   Output: Coverage percentage, uncovered lines
│
├── mock-generator.py
│   Purpose: Generate mock classes for services
│   Usage: python scripts/mock-generator.py lib/services/CartService.dart
│   Output: test/mocks/CartService.mock.dart
│
└── test-structure.sh
    Purpose: Validate test file organization
    Usage: bash scripts/test-structure.sh test/
    Output: Compliance report with recommendations
```

#### For pos-hardware-integration

```
scripts/
├── printer-discovery.py
│   Purpose: Find available printers on local network
│   Usage: python scripts/printer-discovery.py --protocol ble
│   Output: JSON list of discovered printers
│
├── receipt-formatter.py
│   Purpose: Format and test receipt templates
│   Usage: python scripts/receipt-formatter.py --width 58mm --template store.json
│   Output: Formatted receipt preview
│
└── device-tester.sh
    Purpose: Test hardware device connections
    Usage: bash scripts/device-tester.sh --device printer --action test-connection
    Output: Connection status, diagnostics
```

---

### Phase 2: Official Best Practices for Scripts

#### ✅ Dos (According to Official Specification)

1. **Version Pinning**
   ```bash
   # Good: explicit versions
   uvx ruff@0.8.0 check .
   uvx black@24.10.0 .
   npx eslint@9.0.0 .
   ```

2. **State Prerequisites**
   ```markdown
   ## Script Requirements
   - Python 3.10+ with uv package manager
   - Node.js 18+ for barcode validation
   - Dart SDK 3.0+ with Flutter installed
   ```

3. **Self-Contained Scripts with Inline Dependencies (PEP 723)**
   ```python
   # /// script
   # dependencies = [
   #   "click>=8.0,<9",
   #   "beautifulsoup4>=4.12,<5"
   # ]
   # requires-python = ">=3.10"
   # ///
   
   import click
   from bs4 import BeautifulSoup
   
   @click.command()
   @click.option('--file', required=True)
   def validate(file):
       """Validate architecture file."""
       # implementation
   ```

4. **Structured Output (JSON/CSV)**
   ```python
   import json
   
   # Good: machine-parseable structure
   result = {
       "violations": [
           {"file": "checkout_screen.dart", "lines": 850, "severity": "critical"},
           {"file": "products_grid.dart", "lines": 320, "severity": "warning"}
       ],
       "summary": {"total_violations": 2, "files_compliant": 12}
   }
   print(json.dumps(result, indent=2))
   ```

5. **Clear `--help` Output**
   ```bash
   $ python scripts/validate-architecture.py --help
   
   Usage: validate-architecture.py [OPTIONS] FILE
   
   Validate Dart file follows three-layer architecture and 500-line max.
   
   Options:
     --strict         Fail on warnings (not just errors)
     --output FILE    Write report to FILE instead of stdout
     --json           Output as JSON (default: human-readable)
     -v, --verbose    Show detailed findings
   
   Examples:
     validate-architecture.py lib/screens/checkout_screen.dart
     validate-architecture.py --strict --json lib/screens/*.dart
   ```

6. **Helpful Error Messages**
   ```python
   # Bad: unhelpful
   # Error: invalid input
   
   # Good: guidance with next steps
   # Error: File not found: lib/screens/checkout_screen.dart
   # Expected: Valid Dart file path in lib/screens/ directory
   # Try: ls lib/screens/*.dart to see available files
   ```

7. **Separate Data from Diagnostics**
   ```bash
   # stdout: clean, structured data
   {"files_analyzed": 42, "violations_found": 3}
   
   # stderr: progress messages, warnings (agent can see but won't parse)
   [INFO] Analyzing 42 files...
   [WARN] File has mixed indentation (will pass)
   [INFO] Found 3 critical violations
   ```

8. **Important Script Considerations**
   - ✅ **Idempotency**: "Create if not exists" > "create and fail on duplicate"
   - ✅ **Input Constraints**: Use enums, validate input clearly
   - ✅ **Dry-run Support**: `--dry-run` flags for destructive operations
   - ✅ **Meaningful Exit Codes**: 0=success, 1=generic error, 2=validation error, 127=not found
   - ✅ **Safe Defaults**: Destructive ops require explicit confirmation
   - ✅ **Output Size**: Default to summary, use `--verbose` for details

#### ❌ Dont's

1. **Interactive Prompts** (HARD REQUIREMENT)
   ```bash
   # Bad: hangs in agent environment
   read -p "Enter target environment: " env
   
   # Good: require flag, clear error if missing
   if [ -z "$ENV" ]; then
     echo "Error: --env required. Options: dev, staging, prod"
     exit 2
   fi
   ```

2. **Unclear Dependencies**
   ```bash
   # Bad: assumes agent has these installed
   $ python scripts/validate.py  # fails silently, agent confused
   
   # Good: state requirements clearly, fail fast
   # Document: "Requires: Python 3.10+, uv (run `pip install uv`)"
   ```

3. **Unparseable Output**
   ```bash
   # Bad: whitespace-aligned, hard to parse
   NAME              STATUS     VIOLATIONS
   checkout_screen   ERROR      3
   products_grid     WARNING    1
   
   # Good: structured format agents can use
   {"file":"checkout_screen.dart","status":"error","violations":3}
   ```

---

### Phase 3: VS Code Integration (Agent Plugins)

#### Current Setup
- ✅ Skills located in `.github/skills/` (accessible locally)
- ✅ Specification-compliant SKILL.md files
- ✅ Progressive disclosure with references/ directories

#### Next Steps for VS Code Plugin Integration

**Option A: Local Plugin Registration** (Recommended for Development)

1. Create `.vscode/settings.json`:
   ```json
   {
     "chat.plugins.enabled": true,
     "chat.plugins.paths": {
       "e:\\extropos\\.github\\skills": true
     }
   }
   ```

2. VS Code will recognize all 5 skills automatically

**Option B: Custom Marketplace** (For Team/Public Distribution)

1. Create `skills-registry.json` in `.github/`:
   ```json
   {
     "skills": [
       {
         "id": "flutter-architecture-refactoring",
         "path": "skills/flutter-architecture-refactoring",
         "version": "1.0"
       },
       {
         "id": "pos-business-logic-calculations",
         "path": "skills/pos-business-logic-calculations",
         "version": "1.0"
       }
     ]
   }
   ```

2. Teams can add marketplace via:
   ```json
   {
     "chat.plugins.marketplaces": [
       "github-username/flutterpos-skills"
     ]
   }
   ```

---

## 📋 Implementation Priority

### Priority 1: Add Scripts (Immediate - High Value)

| Skill | Scripts | Complexity | Value | Timeline |
|-------|---------|-----------|-------|----------|
| flutter-architecture-refactoring | 3 scripts | Medium | High | 2-3 hours |
| pos-business-logic-calculations | 3 scripts | Medium | High | 2-3 hours |
| pos-ui-responsive-design | 3 scripts | Low | Medium | 1-2 hours |
| flutter-testing-quality | 3 scripts | Medium | High | 2-3 hours |
| pos-hardware-integration | 3 scripts | High | Medium | 3-4 hours |

**Total Effort**: ~10-15 hours
**Value**: +200% capability increase through automation

### Priority 2: Complete References (In Progress)

- ⏳ RESPONSIVE_EXAMPLES.md (pos-ui-responsive-design)
- ⏳ TEST_PATTERNS.md (flutter-testing-quality)
- ⏳ PRINTER_SETUP.md (pos-hardware-integration)

---

## 🎯 Success Criteria

### Skills Are "Complete" When:

- ✅ SKILL.md exists and is specification-compliant (< 500 lines)
- ✅ YAML frontmatter includes: name, description, license, metadata, compatibility
- ✅ Body includes clear patterns with ✅ good vs ❌ bad examples
- ✅ References/ folder has 1-2 detailed guides
- ✅ Scripts/ folder has 2-3 automated tools with:
  - PEP 723 inline dependencies or version-pinned commands
  - Clear `--help` output with examples
  - Structured JSON/CSV output
  - Separation of data (stdout) and diagnostics (stderr)
  - Non-interactive input (flags only)
  - Meaningful error messages with guidance

### Agent Integration Is "Ready" When:

- ✅ All 5 skills specification-compliant
- ✅ Skills discoverable in VS Code (@agentPlugins or local path)
- ✅ Scripts executable with clear error handling
- ✅ Documentation includes: when-to-use, prerequisites, usage examples
- ✅ Skills tested with actual agent queries

---

## 📚 Reference Usage in SKILL.md

**Current Format** (Good):
```markdown
## References

See `references/ARCHITECTURE_DETAILED.md` for:
- Complete three-layer pattern explanation
- Refactoring 800-line screen example
- Anti-patterns and how to avoid them
```

**Enhanced Format** (With Scripts):
```markdown
## Available Scripts

- **`scripts/validate-architecture.py`** — Check file follows three-layer pattern
- **`scripts/refactor-check.sh`** — Find files needing refactoring
- **`scripts/extract-widget.py`** — Automate widget extraction

## Workflow Example

1. Identify candidates for refactoring:
   ```bash
   bash scripts/refactor-check.sh lib/screens
   ```

2. Check a specific file:
   ```bash
   python scripts/validate-architecture.py lib/screens/checkout_screen.dart
   ```

3. See detailed patterns:
   ```bash
   cat references/ARCHITECTURE_DETAILED.md  # or open in editor
   ```

## References

See `references/ARCHITECTURE_DETAILED.md` for complete guidance including:
- Layer A/B/C pattern explanations with working code
- Step-by-step 800-line refactoring example
- Anti-patterns and recovery strategies
- Testing patterns for each layer
```

---

## 🔧 Technical Checklist for Scripts

### For Each Script, Verify:

- [ ] **Prerequisites stated in SKILL.md**
  - Required Python version, tools, dependencies
  - How to install (e.g., `pip install uv`)

- [ ] **Versions pinned**
  ```bash
  ✅ uvx ruff@0.8.0
  ✅ npx eslint@9.0.0@latest  # Avoid @latest in production
  ```

- [ ] **Self-contained with inline deps (Python)**
  ```python
  # /// script
  # dependencies = ["click>=8.0,<9", "pydantic>=2.0,<3"]
  # requires-python = ">=3.10"
  # ///
  ```

- [ ] **Non-interactive execution**
  - No `input()`, `getpass()`, or TTY prompts
  - All input via `--flag`, environment variables, or stdin
  - Script exits with error if required inputs missing

- [ ] **Clear `--help` output**
  - Run `python script.py --help` manually
  - Output includes: description, options, examples
  - Output is < 50 lines (agent context efficiency)

- [ ] **Structured output**
  - JSON or CSV format (not whitespace-aligned text)
  - Valid, parseable by `jq` or `csv` tools
  - Data to stdout, diagnostics to stderr

- [ ] **Meaningful error codes**
  - 0 = success
  - 1 = generic error
  - 2 = validation error
  - 127 = not found/missing dependency
  - Document in `--help` output

- [ ] **Safe defaults**
  - Read-only operations preferred
  - Destructive ops require `--confirm` or `--force`
  - `--dry-run` support for stateful operations

- [ ] **Idempotent behavior**
  - "Create if not exists" pattern
  - No-op if already done (not error)
  - Safe to run multiple times

- [ ] **Predictable output**
  - Default to summary (not verbose dumps)
  - Support `--verbose` for details
  - Large output → file output via `--output FILE`

---

## 📝 Document Updates Needed

### Update SKILL.md Files to Include:

```markdown
## Available Scripts

[List all scripts with brief descriptions]

## Quick Start

[Include script examples showing typical usage]

## Prerequisites

[State required tools and versions]
```

### Create scripts/README.md for Each Skill:

```markdown
# Scripts for [SKILL NAME]

## Overview

Scripts directory contains automated helpers for [SKILL NAME].

## Available Scripts

### script-name.py
- **Purpose**: [What it does]
- **Usage**: `python scripts/script-name.py --help`
- **Requirements**: Python 3.10+, pip
- **Output**: JSON with [field descriptions]

## Running Scripts

All scripts support `--help`:

\`\`\`bash
python scripts/validate-architecture.py --help
\`\`\`

## Installing Dependencies

First run:

\`\`\`bash
pip install uv
\`\`\`

Then scripts run with `uv run`:

\`\`\`bash
uv run scripts/validate.py
\`\`\`

## Examples

[Include 2-3 working examples with output]
```

---

## 🎉 Outcome

When complete, your Agent Skills will:

✅ **Be discoverable** in VS Code (@agentPlugins) or via local registration
✅ **Provide automation** through scripts for validation, testing, generation
✅ **Include examples** from real FlutterPOS code
✅ **Follow best practices** per official agentskills.io specification
✅ **Enable expert guidance** for architecture, logic, UI, testing, hardware
✅ **Support teams** with portable, version-controlled knowledge

**Your POS app development will be faster, higher quality, and more consistent.** 🚀

---

## 📖 References for Implementation

1. **Agent Skills Specification**: https://agentskills.io/specification
2. **Scripts Guide**: https://agentskills.io/skill-creation/using-scripts
3. **VS Code Integration**: https://code.visualstudio.com/docs/copilot/customization/agent-plugins
4. **Example Skills**: https://github.com/anthropics/skills

---

*Last Updated: March 5, 2026*  
*Version: 1.0*  
*Status: Ready for implementation*
