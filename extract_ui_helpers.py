#!/usr/bin/env python3
"""Extract simple helper/utility methods"""

with open('lib/screens/advanced_reports_screen.dart', 'r') as f:
    lines = f.readlines()

# Find _buildMetricCard - it's only 26 lines, perfect for moving to helpers
# Also _buildReconciliationRow - 19 lines

print(f'Current size: {len(lines)} lines')

# Find these specific methods
targets = ['_buildMetricCard', '_buildReconciliationRow']
methods_to_move = {}

for i, line in enumerate(lines):
    for target in targets:
        if f'Widget {target}' in line:
            # Find method end
            brace_count = 0
            for j in range(i, len(lines)):
                for char in lines[j]:
                    if char == '{':
                        brace_count += 1
                    elif char == '}':
                        brace_count -= 1
                        if brace_count == 0:
                            methods_to_move[target] = (i, j)
                            print(f'{target}: lines {i+1}-{j+1}')
                            break

# Create helpers part
helpers = []
helpers.append('// Part of advanced_reports_screen.dart\n')
helpers.append('// UI helper methods\n')
helpers.append('\n')
helpers.append("part of 'advanced_reports_screen.dart';\n")
helpers.append('\n')
helpers.append('extension AdvancedReportsUIHelpers on _AdvancedReportsScreenState {\n')

for target in sorted(methods_to_move.keys(), key=lambda x: methods_to_move[x][0]):
    start, end = methods_to_move[target]
    for i in range(start, end + 1):
        helpers.append(lines[i])
    helpers.append('\n')

helpers.append('}\n')

with open('lib/screens/advanced_reports_screen_ui_helpers.dart', 'w') as f:
    f.writelines(helpers)

print(f'✓ Created UI helpers part')

# Update main file - remove extracted methods
with open('lib/screens/advanced_reports_screen.dart', 'r') as f:
    main_lines = f.readlines()

# Add part directive after existing parts
for i, line in enumerate(main_lines):
    if "part 'advanced_reports_screen_helpers.dart'" in line:
        main_lines.insert(i + 1, "part 'advanced_reports_screen_ui_helpers.dart';\n")
        break

# Remove methods in reverse order to preserve indices
for target in sorted(methods_to_move.keys(), key=lambda x: methods_to_move[x][0], reverse=True):
    start, end = methods_to_move[target]
    del main_lines[start:end+1]

with open('lib/screens/advanced_reports_screen.dart', 'w') as f:
    f.writelines(main_lines)

print(f'✓ Updated main file: {len(lines)} → {len(main_lines)} lines')

if len(main_lines) < 1000:
    print(f'\n✓✓✓ SUCCESS: {len(main_lines)} lines (<1000) ✓ COMPLIANT')
else:
    print(f'\nNote: {len(main_lines)} lines (need {len(main_lines) - 1000} more)')
