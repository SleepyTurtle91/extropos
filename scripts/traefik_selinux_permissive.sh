#!/usr/bin/env bash
# Show SELinux status and optionally set to permissive mode
# Usage: sudo ./traefik_selinux_permissive.sh [--permissive]

set -euo pipefail

if ! command -v getenforce >/dev/null 2>&1; then
  echo "SELinux not installed or getenforce not found"
  exit 0
fi

echo "SELinux status: $(getenforce)"
if [ "$#" -ge 1 ] && [ "$1" == "--permissive" ]; then
  echo "Setting SELinux to Permissive (temporary)..."
  sudo setenforce 0
  echo "SELinux status: $(getenforce)"
  echo "Remember to set back to enforcing with: sudo setenforce 1"
else
  echo "To set SELinux to permissive run: sudo ./traefik_selinux_permissive.sh --permissive"
fi
