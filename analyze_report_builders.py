#!/usr/bin/env python3
"""Extract all content builder methods from reports_screen.dart."""

with open('lib/screens/reports_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Starting file size: {len(lines)} lines\n')

# Find all Widget _build methods
content_builders = []
for i, line in enumerate(lines):
    if line.strip().startswith('Widget _build') and 'Content()' in line:
        method_name = line.strip().split('(')[0].replace('Widget ', '')
        # Find closing brace
        brace_count = 0
        for j in range(i, len(lines)):
            brace_count += lines[j].count('{') - lines[j].count('}')
            if brace_count == 0 and j > i:
                size = j - i + 1
                content_builders.append((method_name, i, j + 1, size))
                print(f'{method_name:40s}: lines {i+1:4d}-{j+1:4d} ({size:4d} lines)')
                break

print(f'\nTotal methods found: {len(content_builders)}')
total_lines = sum(size for _, _, _, size in content_builders)
print(f'Total lines in content builders: {total_lines}')
print(f'Would reduce file from {len(lines)} → {len(lines) - total_lines} lines')
print(f'Compliance target: <1,000 lines')
print(f'Status: {"✓ COMPLIANT" if (len(lines) - total_lines) < 1000 else f"Needs -{(len(lines) - total_lines) - 1000} more"}')
