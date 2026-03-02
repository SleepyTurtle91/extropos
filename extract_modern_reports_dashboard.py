#!/usr/bin/env python3
"""Single-pass extraction for modern_reports_dashboard.dart."""

import re
from pathlib import Path

def extract_methods(filepath):
    """Extract methods into categorized part files."""
    content = Path(filepath).read_text(encoding='utf-8', errors='ignore')
    lines = content.splitlines()
    
    print(f"Input: {len(lines)} lines")
    
    # Find all methods
    methods = []
    current_method = None
    brace_count = 0
    in_method = False
    
    for i, line in enumerate(lines):
        # Detect method start
        if re.search(r'^\s+(Widget|Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+\w+\([^)]*\)\s*(\basync\b)?\s*\{', line):
            if current_method is None:
                match = re.search(r'^\s+(Widget|Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+(\w+)\(', line)
                if match:
                    return_type = match.group(1)
                    method_name = match.group(2)
                    # Skip build() method - keep in main file
                    if method_name == 'build':
                        continue
                    current_method = {
                        'name': method_name,
                        'return_type': return_type,
                        'start_idx': i,
                        'lines_content': []
                    }
                    current_method['lines_content'].append(line)
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
    
    print(f"Found {len(methods)} methods to extract")
    
    # Categorize methods
    widget_large = []
    widget_medium = []
    widget_small = []
    future_methods = []
    void_methods = []
    helper_methods = []
    
    for m in methods:
        if m['return_type'] == 'Widget':
            if m['line_count'] >= 100:
                widget_large.append(m)
            elif m['line_count'] >= 50:
                widget_medium.append(m)
            else:
                widget_small.append(m)
        elif 'Future' in m['return_type']:
            future_methods.append(m)
        elif m['return_type'] == 'void':
            void_methods.append(m)
        else:
            helper_methods.append(m)
    
    # Create part files
    part_files = []
    
    # Medium widgets (50-99 lines)
    if widget_medium:
        part_content = "part of 'modern_reports_dashboard.dart';\n\n"
        part_content += "extension ModernReportsDashboardMediumWidgets on _ModernReportsDashboardState {\n"
        for m in widget_medium:
            part_content += '\n'.join(m['lines_content']) + '\n\n'
        part_content += "}\n"
        
        part_file = 'lib/screens/modern_reports_dashboard_medium_widgets.dart'
        Path(part_file).write_text(part_content, encoding='utf-8')
        part_files.append(('modern_reports_dashboard_medium_widgets.dart', len(widget_medium), sum(m['line_count'] for m in widget_medium)))
        print(f"✓ Created medium widgets part: {len(widget_medium)} methods, {sum(m['line_count'] for m in widget_medium)} lines")
    
    # Small widgets (<50 lines)
    if widget_small:
        part_content = "part of 'modern_reports_dashboard.dart';\n\n"
        part_content += "extension ModernReportsDashboardSmallWidgets on _ModernReportsDashboardState {\n"
        for m in widget_small:
            part_content += '\n'.join(m['lines_content']) + '\n\n'
        part_content += "}\n"
        
        part_file = 'lib/screens/modern_reports_dashboard_small_widgets.dart'
        Path(part_file).write_text(part_content, encoding='utf-8')
        part_files.append(('modern_reports_dashboard_small_widgets.dart', len(widget_small), sum(m['line_count'] for m in widget_small)))
        print(f"✓ Created small widgets part: {len(widget_small)} methods, {sum(m['line_count'] for m in widget_small)} lines")
    
    # Future methods
    if future_methods:
        part_content = "part of 'modern_reports_dashboard.dart';\n\n"
        part_content += "extension ModernReportsDashboardFutures on _ModernReportsDashboardState {\n"
        for m in future_methods:
            part_content += '\n'.join(m['lines_content']) + '\n\n'
        part_content += "}\n"
        
        part_file = 'lib/screens/modern_reports_dashboard_futures.dart'
        Path(part_file).write_text(part_content, encoding='utf-8')
        part_files.append(('modern_reports_dashboard_futures.dart', len(future_methods), sum(m['line_count'] for m in future_methods)))
        print(f"✓ Created futures part: {len(future_methods)} methods, {sum(m['line_count'] for m in future_methods)} lines")
    
    # Void methods
    if void_methods:
        part_content = "part of 'modern_reports_dashboard.dart';\n\n"
        part_content += "extension ModernReportsDashboardOperations on _ModernReportsDashboardState {\n"
        for m in void_methods:
            part_content += '\n'.join(m['lines_content']) + '\n\n'
        part_content += "}\n"
        
        part_file = 'lib/screens/modern_reports_dashboard_operations.dart'
        Path(part_file).write_text(part_content, encoding='utf-8')
        part_files.append(('modern_reports_dashboard_operations.dart', len(void_methods), sum(m['line_count'] for m in void_methods)))
        print(f"✓ Created operations part: {len(void_methods)} methods, {sum(m['line_count'] for m in void_methods)} lines")
    
    # Helper methods
    if helper_methods:
        part_content = "part of 'modern_reports_dashboard.dart';\n\n"
        part_content += "extension ModernReportsDashboardHelpers on _ModernReportsDashboardState {\n"
        for m in helper_methods:
            part_content += '\n'.join(m['lines_content']) + '\n\n'
        part_content += "}\n"
        
        part_file = 'lib/screens/modern_reports_dashboard_helpers.dart'
        Path(part_file).write_text(part_content, encoding='utf-8')
        part_files.append(('modern_reports_dashboard_helpers.dart', len(helper_methods), sum(m['line_count'] for m in helper_methods)))
        print(f"✓ Created helpers part: {len(helper_methods)} methods, {sum(m['line_count'] for m in helper_methods)} lines")
    
    # Rebuild main file
    extracted_method_names = {m['name'] for m in methods}
    new_lines = []
    skip_until = -1
    part_directives_added = False
    
    for i, line in enumerate(lines):
        if i < skip_until:
            continue
        
        # Add part directives after imports
        if not part_directives_added and (line.startswith('class ') or line.startswith('enum ')):
            for part_name, _, _ in part_files:
                new_lines.append(f"part '{part_name}';")
            new_lines.append('')
            part_directives_added = True
        
        # Check if this line starts a method to extract
        method_match = re.search(r'^\s+(Widget|Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+(\w+)\(', line)
        if method_match:
            method_name = method_match.group(2)
            if method_name in extracted_method_names:
                # Find the end of this method
                for m in methods:
                    if m['name'] == method_name and m['start_idx'] == i:
                        skip_until = m['end_idx'] + 1
                        break
                continue
        
        new_lines.append(line)
    
    # Write updated main file
    Path(filepath).write_text('\n'.join(new_lines), encoding='utf-8')
    
    new_size = len(new_lines)
    reduction = len(lines) - new_size
    print(f"✓ Updated main file: {len(lines)} → {new_size} lines")
    print(f"  Reduction: {reduction} lines")
    
    if new_size < 1000:
        print(f"✓✓✓ SUCCESS: {new_size} lines (<1000) ✓ COMPLIANT")
    else:
        print(f"⚠ WARNING: {new_size} lines (still ≥1000)")
    
    return part_files

if __name__ == '__main__':
    extract_methods('lib/screens/modern_reports_dashboard.dart')
