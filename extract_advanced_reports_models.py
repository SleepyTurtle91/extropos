#!/usr/bin/env python3
"""Extract advanced_reports.dart into separate model files by report type."""

import re
from pathlib import Path

def extract_advanced_reports():
    """Split models file by report type."""
    filepath = Path('lib/models/advanced_reports.dart')
    content = filepath.read_text(encoding='utf-8', errors='ignore')
    lines = content.splitlines()
    
    print(f"Processing: {filepath.name}")
    print(f"Total lines: {len(lines)}\n")
    
    # Parse class definitions
    classes = []
    current_class = None
    brace_count = 0
    in_class = False
    
    for i, line in enumerate(lines):
        # Detect class/abstract class start
        if re.search(r'^(abstract )?class \w+', line):
            if current_class is None:
                match = re.search(r'^(abstract )?class (\w+)', line)
                if match:
                    current_class = {
                        'name': match.group(2),
                        'is_abstract': match.group(1) is not None,
                        'start_idx': i,
                        'lines_content': [line]
                    }
                    brace_count = line.count('{') - line.count('}')
                    in_class = True
        elif in_class:
            current_class['lines_content'].append(line)
            brace_count += line.count('{') - line.count('}')
            
            if brace_count == 0 and '{' in ''.join(current_class['lines_content']):
                current_class['end_idx'] = i
                current_class['line_count'] = len(current_class['lines_content'])
                classes.append(current_class)
                current_class = None
                in_class = False
    
    print(f"Found {len(classes)} classes:")
    for cls in classes:
        marker = "[ABSTRACT]" if cls['is_abstract'] else "[CLASS]"
        print(f"  {marker} {cls['name']}: {cls['line_count']} lines")
    
    # Categorize by domain
    categories = {
        'reports_base': [],  # BaseReport and utility classes
        'reports_sales': [],  # Sales-related reports
        'reports_inventory': [],  # Inventory reports
        'reports_customer': [],  # Customer reports
        'reports_staff': [],  # Staff/employee reports
        'reports_finance': [],  # Finance reports
        'reports_data': [],  # Data classes (supporting models)
    }
    
    for cls in classes:
        name = cls['name']
        if name == 'BaseReport':
            categories['reports_base'].append(cls)
        elif 'Sales' in name or 'Revenue' in name or 'Transaction' in name:
            categories['reports_sales'].append(cls)
        elif 'Inventory' in name or 'Stock' in name or 'Product' in name and 'Sales' not in name:
            categories['reports_inventory'].append(cls)
        elif 'Customer' in name or 'LoyaltyCustomer' in name:
            categories['reports_customer'].append(cls)
        elif 'Staff' in name or 'Employee' in name or 'Shift' in name:
            categories['reports_staff'].append(cls)
        elif 'Finance' in name or 'Tax' in name or 'Expense' in name or 'Cash' in name:
            categories['reports_finance'].append(cls)
        elif 'Data' in name:
            categories['reports_data'].append(cls)
        else:
            # Try to infer from content
            content_str = ' '.join(cls['lines_content'])
            if 'Sales' in content_str or 'Revenue' in content_str:
                categories['reports_sales'].append(cls)
            else:
                categories['reports_data'].append(cls)
    
    # Create models directory
    models_dir = Path('lib/models/reports')
    models_dir.mkdir(exist_ok=True)
    print(f"\n✓ Created directory: {models_dir}")
    
    created_files = []
    
    # Create separate files for each category
    for category, classes_list in categories.items():
        if not classes_list:
            continue
        
        file_content = "/// Auto-generated from advanced_reports.dart - Do not edit manually\n"
        file_content += "///\n"
        file_content += f"/// {category.replace('_', ' ').title()}\n\n"
        
        for cls in classes_list:
            file_content += '\n'.join(cls['lines_content']) + '\n\n'
        
        output_file = models_dir / f'{category}.dart'
        output_file.write_text(file_content, encoding='utf-8')
        
        total_lines = sum(cls['line_count'] for cls in classes_list)
        created_files.append((category, len(classes_list), total_lines))
        print(f"✓ Created: {output_file.name} ({len(classes_list)} classes, {total_lines} lines)")
    
    # Create exports file
    exports_content = "/// Advanced Reports Models\n"
    exports_content += "/// Split into domain-specific files for better maintainability\n\n"
    for category, _, _ in created_files:
        exports_content += f"export 'reports/{category}.dart';\n"
    
    exports_file = Path('lib/models/advanced_reports.dart')
    exports_file.write_text(exports_content, encoding='utf-8')
    
    new_size = len(exports_content.splitlines())
    reduction = len(lines) - new_size
    print(f"\n✓ Updated main file to exports: {len(lines)} → {new_size} lines")
    print(f"  Reduction: {reduction} lines ({reduction/len(lines)*100:.1f}%)")
    print(f"  Created {len(created_files)} domain files")
    
    if new_size <= 500:
        print(f"✓✓✓ SUCCESS: {new_size} lines (≤500) ✓ COMPLIANT")
    
    # Verify no file exceeds 500 lines
    print(f"\n=== FILE SIZE COMPLIANCE ===")
    all_compliant = True
    for category, count, total_lines in created_files:
        status = "✓" if total_lines <= 500 else "⚠"
        print(f"{status} {category}.dart: {total_lines} lines")
        if total_lines > 500:
            all_compliant = False
    
    if all_compliant:
        print("\n✓✓✓ ALL FILES ≤500 LINES!")
    else:
        print("\n⚠ Some files exceed 500 lines - further splitting needed")

if __name__ == '__main__':
    extract_advanced_reports()
