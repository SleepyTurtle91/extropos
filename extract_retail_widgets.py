import re

# Read original file
with open('lib/screens/retail_pos_screen_modern.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print('=' * 80)
print('EXTRACTING WIDGET BUILDERS FROM retail_pos_screen_modern.dart')
print('=' * 80)
print()

# Find all _build* methods
methods_to_extract = []
for i, line in enumerate(lines, 1):
    stripped = line.strip()
    if re.match(r'^Widget _build\w+', stripped):
        # Extract method name
        match = re.match(r'^Widget\s+(_build\w+)', stripped)
        if match:
            methods_to_extract.append({
                'line': i,
                'name': match.group(1),
                'full': stripped
            })

print(f'Found {len(methods_to_extract)} Widget _build* methods:')
for m in methods_to_extract:
    print(f'  - {m["name"]} at line {m["line"]}')
print()

# Calculate method boundaries
for idx, method in enumerate(methods_to_extract):
    start_line = method['line']
    
    # Find end by looking for next method or end of class
    if idx + 1 < len(methods_to_extract):
        end_line = methods_to_extract[idx + 1]['line'] - 1
    else:
        # Find next non-build method or end of class
        end_line = len(lines)
        for i in range(start_line, len(lines)):
            # Look for next method at same indentation that's not a build method
            if i > start_line and re.match(r'^\s\s(Widget|Future|void)\s+_\w+', lines[i]):
                # Check if it's a build method
                if not re.match(r'^\s\sWidget\s+_build', lines[i]):
                    end_line = i - 1
                    break
            # Or end of class
            if re.match(r'^\}', lines[i]):
                end_line = i - 1
                break
    
    method['end_line'] = end_line
    method['size'] = end_line - start_line + 1

# Sort by line number to maintain order
methods_to_extract.sort(key=lambda m: m['line'])

total_lines = sum(m['size'] for m in methods_to_extract)
print(f'Total lines to extract: {total_lines}')
print()

# Extract methods
extracted_methods = []
for method in methods_to_extract:
    start_idx = method['line'] - 1  # Convert to 0-based
    end_idx = method['end_line']     # Already 0-based (inclusive)
    
    method_lines = lines[start_idx:end_idx]
    extracted_methods.append({
        'name': method['name'],
        'lines': method_lines,
        'original_start': method['line'],
        'original_end': method['end_line']
    })
    print(f'Extracted {method["name"]}: {len(method_lines)} lines [Line {method["line"]}-{method["end_line"]}]')

# Create part file with extension
part_content = []
part_content.append("// Part of retail_pos_screen_modern.dart\n")
part_content.append("// Widget Builders Extension\n")
part_content.append("\n")
part_content.append("part of 'retail_pos_screen_modern.dart';\n")
part_content.append("\n")
part_content.append("extension RetailPOSWidgets on _RetailPOSScreenModernState {\n")

for method in extracted_methods:
    part_content.extend(method['lines'])
    part_content.append('\n')  # Add spacing between methods

part_content.append("}\n")

# Write part file
with open('lib/screens/retail_pos_screen_modern_widgets.dart', 'w', encoding='utf-8') as f:
    f.writelines(part_content)

print()
print(f'✓ Created lib/screens/retail_pos_screen_modern_widgets.dart ({len(part_content)} lines)')
print()

# Remove extracted methods from original file (in reverse order to maintain line numbers)
new_lines = lines.copy()
for method in reversed(methods_to_extract):
    start_idx = method['line'] - 1
    end_idx = method['end_line']
    
    # Remove the method
    del new_lines[start_idx:end_idx]

# Add part directive after imports (find the last import line)
last_import_idx = 0
for i, line in enumerate(new_lines):
    if line.strip().startswith('import '):
        last_import_idx = i

# Insert part directive after last import
new_lines.insert(last_import_idx + 1, "\npart 'retail_pos_screen_modern_widgets.dart';\n")

# Write updated main file
with open('lib/screens/retail_pos_screen_modern.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f'✓ Updated retail_pos_screen_modern.dart: {len(lines)} → {len(new_lines)} lines')
print(f'  Reduction: {len(lines) - len(new_lines)} lines')
print()

# Verify
if len(lines) - len(new_lines) > 0:
    print('✓ EXTRACTION SUCCESSFUL')
    print(f'  Main file: {len(new_lines)} lines')
    print(f'  Part file: {len(part_content)} lines')
    print(f'  Status: {"✓ COMPLIANT" if len(new_lines) < 1000 else "⚠️ Still needs work"}')
else:
    print('✗ ERROR: No lines were removed')
