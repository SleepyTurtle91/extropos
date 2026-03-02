#!/usr/bin/env python3
"""Analyze mock_database_service.dart for extraction opportunities."""

import re
from pathlib import Path

def analyze_file(filepath):
    """Analyze file structure and identify extractable methods."""
    content = Path(filepath).read_text(encoding='utf-8', errors='ignore')
    lines = content.splitlines()
    
    print(f"File: {filepath}")
    print(f"Total lines: {len(lines)}\n")
    
    # Find all methods
    methods = []
    current_method = None
    brace_count = 0
    in_method = False
    
    for i, line in enumerate(lines, 1):
        # Detect method start
        if re.search(r'^\s+(Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+\w+\([^)]*\)\s*(\basync\b)?\s*\{', line):
            if current_method is None:
                match = re.search(r'^\s+(Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+(\w+)\(', line)
                if match:
                    return_type = match.group(1)
                    method_name = match.group(2)
                    current_method = {
                        'name': method_name,
                        'return_type': return_type,
                        'start': i,
                        'start_line': line
                    }
                    brace_count = line.count('{') - line.count('}')
                    in_method = True
        
        elif in_method:
            brace_count += line.count('{') - line.count('}')
            
            if brace_count == 0:
                current_method['end'] = i
                current_method['lines'] = i - current_method['start'] + 1
                methods.append(current_method)
                current_method = None
                in_method = False
    
    # Categorize methods by operation type
    insert_methods = [m for m in methods if 'insert' in m['name'].lower() or 'create' in m['name'].lower() or 'add' in m['name'].lower()]
    update_methods = [m for m in methods if 'update' in m['name'].lower()]
    delete_methods = [m for m in methods if 'delete' in m['name'].lower()]
    query_methods = [m for m in methods if 'get' in m['name'].lower() or 'fetch' in m['name'].lower() or 'load' in m['name'].lower()]
    other_methods = [m for m in methods if m not in insert_methods + update_methods + delete_methods + query_methods]
    
    print("=== METHOD BREAKDOWN ===")
    print(f"Total methods found: {len(methods)}")
    print(f"  Insert/Create/Add: {len(insert_methods)}")
    print(f"  Update: {len(update_methods)}")
    print(f"  Delete: {len(delete_methods)}")
    print(f"  Query/Get/Fetch: {len(query_methods)}")
    print(f"  Other: {len(other_methods)}")
    
    print("\n=== TOP 20 LARGEST METHODS ===")
    largest = sorted(methods, key=lambda x: x['lines'], reverse=True)[:20]
    for m in largest:
        print(f"  {m['name']}: {m['lines']} lines (type: {m['return_type']})")
    
    # Calculate extraction potential
    total_extractable = sum(m['lines'] for m in methods)
    print(f"\n=== EXTRACTION ESTIMATE ===")
    print(f"Total extractable lines: {total_extractable}")
    print(f"Estimated remaining lines: {len(lines) - total_extractable}")
    
    return methods

if __name__ == '__main__':
    analyze_file('lib/services/mock_database_service.dart')
