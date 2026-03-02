#!/usr/bin/env python3
"""
Analyze database_helper_upgrade.dart and create a plan.
The file is too large (1234 lines) and needs to be split into version ranges.
"""

import re
from pathlib import Path

filepath = Path('lib/services/database_helper_upgrade.dart')
content = filepath.read_text(encoding='utf-8', errors='ignore')
lines = content.splitlines()

print(f"File: {filepath.name}")
print(f"Total lines: {len(lines)}\n")

# Find version blocks
version_count = 0
total_upgrade_lines = 0

for i, line in enumerate(lines, 1):
    if match := re.search(r'if \(oldVersion < (\d+)\)', line):
        version = match.group(1)
        version_count += 1
        if version_count <= 20:
            print(f"  Version {version} upgrade at line {i}")

print(f"\nTotal version blocks found: {version_count}")
print(f"\nRecommendation:")
print(f"  - Split into 3-4 files by version ranges")
print(f"  - Each file should handle ~10-15 versions")
print(f"  - Estimated: ~300-400 lines per file")
print(f"  - Target: ≤500 lines per file ✓")
print(f"\nManual refactoring recommended due to complexity of migrations.")
