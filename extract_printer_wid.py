#!/usr/bin/env python3
"""Split printers_management_screen_widgets.dart into individual widget components."""

import re
from pathlib import Path

def extract_printer_widgets():
    filepath = Path('lib/screens/printers_management_screen_widgets.dart')
    content = filepath.read_text(encoding='utf-8', errors='ignore')
    lines = content.splitlines()
    
    print(f"Processing: {filepath.name}")
    print(f"Total lines: {len(lines)}\n")
    
    # Extract methods
    methods = []
    current_method = None
    brace_count = 0
    in_method = False
    
    for i, line in enumerate(lines):
        if re.search(r'^\s+Widget\s+\w+\([^)]*\)\s*\{', line):
            if current_method is None:
                match = re.search(r'^\s+Widget\s+(\w+)\(', line)
                if match:
                    current_method = {
                        'name': match.group(1),
                        'start_idx': i,
                        'lines_content': [line]
                    }
                    brace_count = line.count('{') - line.count('}')
                    in_method = True
        elif in_method:
            current_method['lines_content'].append(line)
            brace_count += line.count('{') - line.count('}')
            
            if brace_count == 0:
                current_method['end_idx'] = i
                current_method['line_count'] = len(current_method['lines_content'])
                methods.append(current_method)
                current_method = None
                in_method = False
    
    print(f"Found {len(methods)} widget methods:")
    for m in methods:
        print(f"  {m['name']}: {m['line_count']} lines")
    
    # Create widgets directory
    widgets_dir = Path('lib/screens/printers_management/widgets')
    widgets_dir.mkdir(parents=True, exist_ok=True)
    print(f"\n✓ Created directory: {widgets_dir}")
    
    created_files = []
    
    # Create individual files for large widgets (≥100 lines)
    large_widgets = [m for m in methods if m['line_count'] >= 100]
    small_widgets = [m for m in methods if m['line_count'] < 100]
    
    for m in large_widgets:
        # Convert method name to file name
        # _buildRightPanel -> right_panel_widget.dart
        widget_name = m['name'].replace('_build', '').replace('_', ' ').title().replace(' ', '')
        filename = re.sub(r'([A-Z])', r'_\1', widget_name).lower().strip('_') + '_widget.dart'
        
        # Build file content
        file_content = "part of '../../printers_management_screen_widgets.dart';\n\n"
        file_content += "extension PrintersManagementWidget_" + widget_name + " on _PrintersManagementScreenState {\n"
        file_content += '\n'.join(m['lines_content']) + '\n'
        file_content += "}\n"
        
        output_file = widgets_dir / filename
        output_file.write_text(file_content, encoding='utf-8')
        
        created_files.append((filename, m['line_count']))
        print(f"✓ Created: {filename} ({m['line_count']} lines)")
    
    # Create small widgets file
    if small_widgets:
        file_content = "part of '../../printers_management_screen_widgets.dart';\n\n"
        file_content += "extension PrintersManagementSmallWidgets on _PrintersManagementScreenState {\n"
        for m in small_widgets:
            file_content += '\n'.join(m['lines_content']) + '\n\n'
        file_content += "}\n"
        
        output_file = widgets_dir / 'small_widgets.dart'
        output_file.write_text(file_content, encoding='utf-8')
        
        total_small_lines = sum(m['line_count'] for m in small_widgets)
        created_files.append(('small_widgets.dart', total_small_lines))
        print(f"✓ Created: small_widgets.dart ({len(small_widgets)} methods, {total_small_lines} lines)")
    
    # Rebuild main widgets file
    extracted_method_names = {m['name'] for m in methods}
    new_lines = []
    skip_until = -1
    part_directives_added = False
    
    for i, line in enumerate(lines):
        if i < skip_until:
            continue
        
        # Add part directives after "part of" declaration
        if not part_directives_added and line.startswith('extension PrintersManagementScreenWidgets'):
            # Add all part directives before the extension
            for filename, _ in created_files:
                new_lines.append(f"part 'printers_management/widgets/{filename}';")
            new_lines.append('')
            part_directives_added = True
        
        # Check if this line starts a method to extract
        method_match = re.search(r'^\s+Widget\s+(\w+)\(', line)
        if method_match:
            method_name = method_match.group(1)
            if method_name in extracted_method_names:
                for m in methods:
                    if m['name'] == method_name and m['start_idx'] == i:
                        skip_until = m['end_idx'] + 1
                        break
                continue
        
        new_lines.append(line)
    
    # Write updated main file
    filepath.write_text('\n'.join(new_lines), encoding='utf-8')
    
    new_size = len(new_lines)
    reduction = len(lines) - new_size
    print(f"\n✓ Updated main file: {len(lines)} → {new_size} lines")
    print(f"  Reduction: {reduction} lines ({reduction/len(lines)*100:.1f}%)")
    
    if new_size <= 500:
        print(f"✓✓✓ SUCCESS: {new_size} lines (≤500) ✓ COMPLIANT")
    else:
        print(f"⚠ {new_size} lines (target: ≤500)")
    
    # Check individual file sizes
    print(f"\n=== FILE SIZE COMPLIANCE ===")
    all_compliant = True
    for filename, file_lines in created_files:
        status = "✓" if file_lines <= 500 else "⚠"
        print(f"{status} {filename}: {file_lines} lines")
        if file_lines > 500:
            all_compliant = False
    
    if not all_compliant:
        print("\n⚠ Some widget files still exceed 500 lines - may need further splitting")

if __name__ == '__main__':
    extract_printer_widgets()
