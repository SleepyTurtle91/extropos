#!/usr/bin/env python3
"""Single-pass extraction for database_helper.dart."""

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
        if re.search(r'^\s+(static )?(Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+\w+\([^)]*\)\s*(\basync\b)?\s*\{', line):
            if current_method is None:
                match = re.search(r'^\s+(static )?(Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+(\w+)\(', line)
                if match:
                    is_static = match.group(1) is not None
                    return_type = match.group(2)
                    method_name = match.group(3)
                    
                    # Keep essential singleton methods in main file
                    if method_name in ['_initDB', 'getDatabasePath', 'close', 'overrideDatabaseFilePath']:
                        continue
                    
                    current_method = {
                        'name': method_name,
                        'return_type': return_type,
                        'is_static': is_static,
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
    
    # Categorize methods by logical groups
    upgrade_methods = []
    table_methods = []
    backup_methods = []
    reset_methods = []
    
    for m in methods:
        name_lower = m['name'].lower()
        if 'upgrade' in name_lower:
            upgrade_methods.append(m)
        elif 'table' in name_lower or 'index' in name_lower or 'insertdefault' in name_lower:
            table_methods.append(m)
        elif 'backup' in name_lower or 'restore' in name_lower:
            backup_methods.append(m)
        elif 'reset' in name_lower or 'downgrade' in name_lower or 'integrity' in name_lower:
            reset_methods.append(m)
    
    # Create part files
    part_files = []
    
    # Database upgrade operations (includes massive _upgradeDB)
    if upgrade_methods:
        part_content = "part of 'database_helper.dart';\n\n"
        part_content += "extension DatabaseHelperUpgrade on DatabaseHelper {\n"
        for m in upgrade_methods:
            part_content += '\n'.join(m['lines_content']) + '\n\n'
        part_content += "}\n"
        
        part_file = 'lib/services/database_helper_upgrade.dart'
        Path(part_file).write_text(part_content, encoding='utf-8')
        part_files.append(('database_helper_upgrade.dart', len(upgrade_methods), sum(m['line_count'] for m in upgrade_methods)))
        print(f"✓ Created upgrade part: {len(upgrade_methods)} methods, {sum(m['line_count'] for m in upgrade_methods)} lines")
    
    # Table/Index creation and default data
    if table_methods:
        part_content = "part of 'database_helper.dart';\n\n"
        part_content += "extension DatabaseHelperTables on DatabaseHelper {\n"
        for m in table_methods:
            part_content += '\n'.join(m['lines_content']) + '\n\n'
        part_content += "}\n"
        
        part_file = 'lib/services/database_helper_tables.dart'
        Path(part_file).write_text(part_content, encoding='utf-8')
        part_files.append(('database_helper_tables.dart', len(table_methods), sum(m['line_count'] for m in table_methods)))
        print(f"✓ Created tables part: {len(table_methods)} methods, {sum(m['line_count'] for m in table_methods)} lines")
    
    # Backup/Restore operations
    if backup_methods:
        part_content = "part of 'database_helper.dart';\n\n"
        part_content += "extension DatabaseHelperBackup on DatabaseHelper {\n"
        for m in backup_methods:
            part_content += '\n'.join(m['lines_content']) + '\n\n'
        part_content += "}\n"
        
        part_file = 'lib/services/database_helper_backup.dart'
        Path(part_file).write_text(part_content, encoding='utf-8')
        part_files.append(('database_helper_backup.dart', len(backup_methods), sum(m['line_count'] for m in backup_methods)))
        print(f"✓ Created backup part: {len(backup_methods)} methods, {sum(m['line_count'] for m in backup_methods)} lines")
    
    # Reset/Downgrade/Integrity operations
    if reset_methods:
        part_content = "part of 'database_helper.dart';\n\n"
        part_content += "extension DatabaseHelperReset on DatabaseHelper {\n"
        for m in reset_methods:
            part_content += '\n'.join(m['lines_content']) + '\n\n'
        part_content += "}\n"
        
        part_file = 'lib/services/database_helper_reset.dart'
        Path(part_file).write_text(part_content, encoding='utf-8')
        part_files.append(('database_helper_reset.dart', len(reset_methods), sum(m['line_count'] for m in reset_methods)))
        print(f"✓ Created reset part: {len(reset_methods)} methods, {sum(m['line_count'] for m in reset_methods)} lines")
    
    # Rebuild main file
    extracted_method_names = {m['name'] for m in methods}
    new_lines = []
    skip_until = -1
    part_directives_added = False
    
    for i, line in enumerate(lines):
        if i < skip_until:
            continue
        
        # Add part directives after imports, before class
        if not part_directives_added and line.startswith('class DatabaseHelper'):
            for part_name, _, _ in part_files:
                new_lines.append(f"part '{part_name}';")
            new_lines.append('')
            part_directives_added = True
        
        # Check if this line starts a method to extract
        method_match = re.search(r'^\s+(static )?(Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+(\w+)\(', line)
        if method_match:
            method_name = method_match.group(3)
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
    elif new_size < 1500:
        print(f"✓ GOOD: {new_size} lines (<1500)")
    else:
        print(f"⚠ WARNING: {new_size} lines (still large)")
    
    return part_files

if __name__ == '__main__':
    extract_methods('lib/services/database_helper.dart')
