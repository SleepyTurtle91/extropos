#!/usr/bin/env bash
# Find & optionally remove Flutter appwrite/firebase references across the repo
# Use with caution.
# Usage:
#   ./remove_appwrite_firebase.sh --report  # only report
#   ./remove_appwrite_firebase.sh --report --fix  # attempt basic removal (import lines commented)

set -euo pipefail

MODE=report
if [ "$#" -gt 0 ]; then
  if [ "$1" = "--fix" ]; then
    MODE=fix
  elif [ "$1" = "--report" ]; then
    MODE=report
  fi
fi

REPO_ROOT="$(pwd)"

# Detect pubspec
if [ -f "$REPO_ROOT/pubspec.yaml" ]; then
  echo "Found pubspec.yaml. Current dependencies lines (partial):"
  grep -E "appwrite|firebase|firestore|cloud_firestore|firebase_core|firebase_messaging" pubspec.yaml || true
fi

# List Dart files importing Appwrite/Firebase
echo "\nSearching for imports across Dart files..."
FILES=$(grep -R --line-number --include=*.dart -E "package:(appwrite|firebase)" . || true)

if [ -z "$FILES" ]; then
  echo "No imports found for appwrite/firebase in Dart files."
  exit 0
fi

echo "$FILES"

if [ "$MODE" = "fix" ]; then
  echo "\nRunning automatic fix (commenting import lines) -- make sure to inspect changes after this operation."
  while IFS= read -r line; do
    # line format: ./lib/foo.dart:12: import 'package:appwrite/appwrite.dart';
    file_path=$(echo "$line" | cut -d ':' -f 1)
    line_num=$(echo "$line" | cut -d ':' -f 2)
    # comment the import line
    echo "Commenting import in $file_path:$line_num"
    sed -i "${line_num}s|^|// REMOVED_IMPORT: |" "$file_path" || true
  done <<< "$FILES"
  echo "Done. Please run 'git status' and review the changes."
else
  echo "Report mode only. If you want to automatically comment import lines, rerun with '--fix'."
fi

# Suggest flutter pub remove commands
echo "\nSuggested flutter pub remove commands (execute manually):"
cat <<'EOF'
flutter pub remove appwrite
flutter pub remove firebase_core cloud_firestore firebase_messaging firebase_analytics
EOF

echo "\nEnd of report"
