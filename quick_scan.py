#!/usr/bin/env python3
from pathlib import Path

lib_dir = Path('lib')
large_files = []

print("Scanning...")

for file in lib_dir.rglob('*.dart'):
    if '.g.dart' in file.name or '.freezed.dart' in file.name:
        continue
    
    try:
        content = file.read_text(encoding='utf-8', errors='ignore')
        lines = len(content.splitlines())
        
        if lines > 500:
            relative_path = str(file.relative_to('lib'))
            large_files.append((relative_path, lines))
    except Exception as e:
        print(f"Error reading {file}: {e}")

# Sort by size
large_files.sort(key=lambda x: x[1], reverse=True)

print(f"\n=== FOUND {len(large_files)} FILES >500 LINES ===\n")

print("Top 40 files:")
for i, (path, lines) in enumerate(large_files[:40], 1):
    marker = "[X]" if lines >= 1000 else "[!]" if lines >= 800 else "[*]"
    print(f"{i:2}. {marker} {lines:4} lines - {path}")

# Statistics
critical = [f for f in large_files if f[1] >= 1000]
high = [f for f in large_files if 800 <= f[1] < 1000]
medium = [f for f in large_files if 500 <= f[1] < 800]

print(f"\n=== STATISTICS ===")
print(f"Critical (>=1000 lines): {len(critical)} files")
print(f"High (800-999 lines): {len(high)} files")
print(f"Medium (500-799 lines): {len(medium)} files")
print(f"Total lines to refactor: {sum(f[1] for f in large_files):,}")
