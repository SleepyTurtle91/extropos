#!/usr/bin/env python3
"""Extract mock_database_service.dart into domain-specific modules."""

import re
from pathlib import Path

def extract_mock_database_service():
    """Split mock database service by domain (retail/restaurant)."""
    filepath = Path('lib/services/mock_database_service.dart')
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
        if re.search(r'^\s+(Future<[^>]+>|Future|void)\s+\w+\([^)]*\)\s*(\basync\b)?\s*\{', line):
            if current_method is None:
                match = re.search(r'^\s+(Future<[^>]+>|Future|void)\s+(\w+)\(', line)
                if match:
                    current_method = {
                        'name': match.group(2),
                        'return_type': match.group(1),
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
    
    # Categorize by domain
    retail_methods = [m for m in methods if 'retail' in m['name'].lower()]
    restaurant_methods = [m for m in methods if 'restaurant' in m['name'].lower()]
    utility_methods = [m for m in methods if m not in retail_methods + restaurant_methods]
    
    print(f"Found {len(methods)} methods:")
    print(f"  Retail: {len(retail_methods)} methods ({sum(m['line_count'] for m in retail_methods)} lines)")
    print(f"  Restaurant: {len(restaurant_methods)} methods ({sum(m['line_count'] for m in restaurant_methods)} lines)")
    print(f"  Utility: {len(utility_methods)} methods ({sum(m['line_count'] for m in utility_methods)} lines)")
    
    # Create directory
    mock_dir = Path('lib/services/mock_data')
    mock_dir.mkdir(exist_ok=True)
    print(f"\n✓ Created directory: {mock_dir}")
    
    # Create retail mock data file
    retail_content = "part of '../mock_database_service.dart';\n\n"
    retail_content += "extension RetailMockData on MockDatabaseService {\n"
    for m in retail_methods:
        retail_content += '\n'.join(m['lines_content']) + '\n\n'
    retail_content += "}\n"
    
    retail_file = mock_dir / 'retail_mock_data.dart'
    retail_file.write_text(retail_content, encoding='utf-8')
    print(f"✓ Created: {retail_file} ({len(retail_methods)} methods, {sum(m['line_count'] for m in retail_methods)} lines)")
    
    # Create restaurant mock data file
    restaurant_content = "part of '../mock_database_service.dart';\n\n"
    restaurant_content += "extension RestaurantMockData on MockDatabaseService {\n"
    for m in restaurant_methods:
        restaurant_content += '\n'.join(m['lines_content']) + '\n\n'
    restaurant_content += "}\n"
    
    restaurant_file = mock_dir / 'restaurant_mock_data.dart'
    restaurant_file.write_text(restaurant_content, encoding='utf-8')
    print(f"✓ Created: {restaurant_file} ({len(restaurant_methods)} methods, {sum(m['line_count'] for m in restaurant_methods)} lines)")
    
    # Rebuild main file
    extracted_method_names = {m['name'] for m in methods}
    new_lines = []
    skip_until = -1
    part_directives_added = False
    
    for i, line in enumerate(lines):
        if i < skip_until:
            continue
        
        # Add part directives after imports, before class
        if not part_directives_added and line.startswith('class MockDatabaseService'):
            new_lines.append("part 'mock_data/retail_mock_data.dart';")
            new_lines.append("part 'mock_data/restaurant_mock_data.dart';")
            new_lines.append('')
            part_directives_added = True
        
        # Check if this line starts a method to extract
        method_match = re.search(r'^\s+(Future<[^>]+>|Future|void)\s+(\w+)\(', line)
        if method_match:
            method_name = method_match.group(2)
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

if __name__ == '__main__':
    extract_mock_database_service()
