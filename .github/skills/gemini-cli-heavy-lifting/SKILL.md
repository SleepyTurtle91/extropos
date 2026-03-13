---
name: gemini-cli-heavy-lifting
description: Use Gemini CLI for large-context coding and bug-fix tasks while preserving FlutterPOS architecture, offline-first behavior, and code quality standards.
license: Proprietary
compatibility: Gemini CLI with local repository access. Optimized for FlutterPOS (Flutter 3.x, Dart 3.x).
metadata:
  author: FlutterPOS
  version: "1.0"
  domain: workflow-orchestration
  focus: large-context-debugging
---

# Gemini CLI Heavy Lifting

**When to use this skill**: Multi-file bug hunts, large refactors,
release blockers, and tasks that need broad repository context.

## Objective

Leverage Gemini CLI for heavy analysis and code generation when context size
is the bottleneck, then apply changes in controlled, testable steps.

## Task Routing Policy

Use Gemini CLI when one or more conditions are true:

- The bug source is unknown and likely spans many modules.
- The task needs reading more than about 3,000 lines.
- The fix will likely touch more than 8 files.
- The input includes large logs, traces, or long documents.
- A Dart file is already above 500 lines and needs structural refactor.

Keep tasks in Copilot when:

- The change is isolated to a few files.
- You already know the exact root cause.
- You only need a small surgical patch.

## FlutterPOS Guardrails (Mandatory)

Gemini output must obey these repository rules:

- Three-layer architecture:
  - Layer A: Pure logic (no Flutter imports)
  - Layer B: Reusable widgets (constructor data + callbacks only)
  - Layer C: Screen orchestration
- Any `.dart` file must stay at or below 500 lines.
- POS entry remains `UnifiedPOSScreen` flow.
- Calculations use `BusinessInfo.instance` settings.
- Responsive grids use `LayoutBuilder` with adaptive breakpoints.
- State management remains local `setState()` (no external state libs).
- Preserve offline-first behavior and avoid forcing cloud dependencies.

## Standard Input Package for Gemini

Before asking Gemini, send one compact context package:

```yaml
task_type: bugfix | refactor | feature
objective: "One clear business outcome"
acceptance_criteria:
  - "Observable pass condition"
  - "No regressions in affected area"
constraints:
  - "FlutterPOS 3-layer architecture"
  - "500-line file limit"
  - "offline-first"
suspected_files:
  - lib/.../file_a.dart
  - lib/.../file_b.dart
artifacts:
  - stack_trace.txt
  - analyzer_output.txt
  - failing_test_names
output_format:
  - root_cause
  - minimal_patch_plan
  - test_plan
```

## Prompt Template: Deep Bug Fix

```text
You are fixing a bug in FlutterPOS.

Goal:
<business outcome>

Symptoms:
<error, logs, reproduction steps>

Constraints:
- Enforce 3-layer architecture (A logic, B widgets, C screens)
- Keep each Dart file <= 500 lines
- No external state management libraries
- Maintain offline-first behavior

Repository Context:
<paste key files, logs, and test failures>

Deliverables:
1) Root cause analysis with confidence level
2) Minimal file-by-file patch plan
3) Updated code snippets for each changed region
4) New or updated tests
5) Regression checklist
```

## Prompt Template: Large Refactor

```text
Refactor the provided module into FlutterPOS three-layer architecture.

Requirements:
- Split concerns into Layer A/B/C
- Keep every file <= 500 lines
- Preserve existing behavior and routes
- Avoid adding new dependencies

Input:
<paste monolithic file and related interfaces>

Output:
- Proposed target file tree
- Migration sequence in safe steps
- Final code per file
- Tests to prove no behavior change
```

## Execution Sequence

1. **Diagnosis pass**
   - Ask Gemini for root cause only (no code first).
2. **Patch design pass**
   - Request minimal patch plan with exact file list.
3. **Implementation pass**
   - Generate code changes constrained to that file list.
4. **Verification pass**
   - Generate tests and validation commands.
5. **Risk pass**
   - Ask for rollback strategy and edge-case checks.

## Output Contract (Require This)

Gemini response should always include:

- Root cause summary in 3-6 bullets.
- Files to modify with reason per file.
- Patch steps ordered from safest to riskiest.
- Tests to run first (targeted), then broader checks.
- Known risks and post-deploy observation points.

## Validation Checklist After Applying Output

- `flutter analyze`
- `flutter test` for affected test files
- Optional full `flutter test` when scope is broad
- Build check for relevant flavor when release-facing

## High-Value Use Cases

- Intermittent cart total bugs involving tax, service charge, and discounts.
- Cross-screen navigation regressions in POS mode routing.
- Large legacy widget extraction into service + widgets + screen layers.
- Deep receipt and printer flow issues with many code paths.

## Practical Notes

- Ask Gemini to avoid speculative changes outside your file list.
- Enforce "minimal diff" in prompts to reduce churn.
- Keep one prompt per objective to avoid mixed outputs.
- Save prompts/results in project notes for repeatable workflows.

---

Use this skill as the default handoff playbook whenever task complexity
exceeds normal single-agent context limits.
