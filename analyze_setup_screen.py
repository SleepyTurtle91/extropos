#!/usr/bin/env python3
"""Analyze setup_screen.dart for extraction opportunities."""

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
        if re.search(r'^\s+(Widget|Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+\w+\([^)]*\)\s*(\basync\b)?\s*\{', line):
            if current_method is None:
                match = re.search(r'^\s+(Widget|Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+(\w+)\(', line)
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
    
    # Categorize methods
    widget_methods = [m for m in methods if m['return_type'] == 'Widget']
    future_methods = [m for m in methods if 'Future' in m['return_type']]
    void_methods = [m for m in methods if m['return_type'] == 'void']
    other_methods = [m for m in methods if m not in widget_methods + future_methods + void_methods]
    
    # Sort by size
    large_widgets = [m for m in widget_methods if m['lines'] >= 100]
    medium_widgets = [m for m in widget_methods if 50 <= m['lines'] < 100]
    small_widgets = [m for m in widget_methods if m['lines'] < 50]
    
    print("=== METHOD BREAKDOWN ===")
    print(f"Total methods found: {len(methods)}")
    print(f"  Widget methods: {len(widget_methods)}")
    print(f"    - Large (≥100 lines): {len(large_widgets)}")
    print(f"    - Medium (50-99 lines): {len(medium_widgets)}")
    print(f"    - Small (<50 lines): {len(small_widgets)}")
    print(f"  Future methods: {len(future_methods)}")
    print(f"  void methods: {len(void_methods)}")
    print(f"  Other methods: {len(other_methods)}")
    
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
    analyze_file('lib/screens/setup_screen.dart')
