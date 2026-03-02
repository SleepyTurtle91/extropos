#!/usr/bin/env python3
"""
Three-Layer Architecture Extraction Tool

Extracts a monolithic Dart file into three layers:
A. Logic layer (*_logic.dart) - Business logic, state, operations
B. Widget Components (*_widgets/ or *_widgets.dart) - Reusable UI components
C. Screen Assembler (*_screen.dart) - Main screen orchestration

Target: Each file <500 lines
"""

import re
from pathlib import Path
from typing import List, Dict, Tuple

class ThreeLayerExtractor:
    def __init__(self, filepath: str):
        self.filepath = Path(filepath)
        self.content = self.filepath.read_text(encoding='utf-8', errors='ignore')
        self.lines = self.content.splitlines()
        self.methods = []
        self.imports = []
        self.class_name = None
        self.state_class_name = None
        
    def analyze(self):
        """Analyze file structure."""
        print(f"Analyzing: {self.filepath.name}")
        print(f"Total lines: {len(self.lines)}")
        
        # Extract imports
        for line in self.lines:
            if line.startswith('import ') or line.startswith('export '):
                self.imports.append(line)
        
        # Find class names
        for line in self.lines:
            if match := re.search(r'^class (\w+) extends Stateful', line):
                self.class_name = match.group(1)
            if match := re.search(r'^class _(\w+)State extends State', line):
                self.state_class_name = f"_{match.group(1)}State"
        
        # Extract methods
        self._extract_methods()
        
        print(f"Found: {len(self.methods)} methods")
        print(f"StatefulWidget: {self.class_name}")
        print(f"State class: {self.state_class_name}")
        
        return self
    
    def _extract_methods(self):
        """Extract all methods from the file."""
        current_method = None
        brace_count = 0
        in_method = False
        
        for i, line in enumerate(self.lines):
            # Detect method start
            if re.search(r'^\s+(Widget|Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+\w+\([^)]*\)\s*(\basync\b)?\s*\{', line):
                if current_method is None:
                    match = re.search(r'^\s+(Widget|Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+(\w+)\(', line)
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
                    self.methods.append(current_method)
                    current_method = None
                    in_method = False
    
    def categorize_methods(self):
        """Categorize methods into logic, widgets, and core."""
        logic_methods = []
        widget_large = []
        widget_small = []
        core_methods = []
        
        for m in self.methods:
            name = m['name']
            lines = m['line_count']
            return_type = m['return_type']
            
            # Core methods (keep in main screen)
            if name in ['build', 'initState', 'dispose', 'didUpdateWidget', 'didChangeDependencies']:
                core_methods.append(m)
            # Logic layer
            elif return_type in ['void', 'bool', 'String', 'int', 'double'] or 'Future' in return_type:
                logic_methods.append(m)
            # Widget layer
            elif return_type == 'Widget':
                if lines >= 100:
                    widget_large.append(m)
                else:
                    widget_small.append(m)
            else:
                logic_methods.append(m)  # Default to logic
        
        return {
            'logic': logic_methods,
            'widget_large': widget_large,
            'widget_small': widget_small,
            'core': core_methods
        }
    
    def print_analysis(self):
        """Print detailed analysis."""
        categories = self.categorize_methods()
        
        print("\n=== CATEGORIZATION ===")
        print(f"Logic methods: {len(categories['logic'])} ({sum(m['line_count'] for m in categories['logic'])} lines)")
        print(f"Large widgets (≥100L): {len(categories['widget_large'])} ({sum(m['line_count'] for m in categories['widget_large'])} lines)")
        print(f"Small widgets (<100L): {len(categories['widget_small'])} ({sum(m['line_count'] for m in categories['widget_small'])} lines)")
        print(f"Core methods (main screen): {len(categories['core'])} ({sum(m['line_count'] for m in categories['core'])} lines)")
        
        print("\n=== TOP METHODS BY CATEGORY ===")
        
        if categories['logic']:
            print("\nLogic methods:")
            for m in sorted(categories['logic'], key=lambda x: x['line_count'], reverse=True)[:5]:
                print(f"  {m['name']}: {m['line_count']} lines ({m['return_type']})")
        
        if categories['widget_large']:
            print("\nLarge widgets:")
            for m in sorted(categories['widget_large'], key=lambda x: x['line_count'], reverse=True):
                print(f"  {m['name']}: {m['line_count']} lines")
        
        if categories['widget_small']:
            print("\nSmall widgets (top 10):")
            for m in sorted(categories['widget_small'], key=lambda x: x['line_count'], reverse=True)[:10]:
                print(f"  {m['name']}: {m['line_count']} lines")
        
        return categories

# Example usage
if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python three_layer_extractor.py <file_path>")
        sys.exit(1)
    
    filepath = sys.argv[1]
    
    extractor = ThreeLayerExtractor(filepath)
    extractor.analyze()
    categories = extractor.print_analysis()
    
    print(f"\n=== EXTRACTION PLAN ===")
    logic_lines = sum(m['line_count'] for m in categories['logic'])
    widget_lines = sum(m['line_count'] for m in categories['widget_large'] + categories['widget_small'])
    core_lines = sum(m['line_count'] for m in categories['core'])
    
    print(f"\nLayer A - Logic file: ~{logic_lines} lines")
    print(f"Layer B - Widget files: ~{widget_lines} lines")
    print(f"  - Large widgets: {len(categories['widget_large'])} files")
    print(f"  - Small widgets grouped: 1 file")
    print(f"Layer C - Main screen: ~{core_lines + 100} lines (core + glue code)")
    
    estimated_final = max(logic_lines, widget_lines, core_lines + 100)
    print(f"\nEstimated max file size after extraction: ~{estimated_final} lines")
    
    if estimated_final <= 500:
        print("✓ Target <500 lines achievable!")
    else:
        print(f"⚠ Additional splitting needed (current estimate: {estimated_final} lines)")
