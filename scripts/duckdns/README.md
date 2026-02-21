DuckDNS update helper scripts

Files:

- update_duckdns.sh - simple curl-based updater to update IP for a DuckDNS domain

Example usage:

```bash
./update_duckdns.sh extropos YOUR_DUCKDNS_TOKEN

```

To run regularly, install the systemd unit and timer (see next files) or use cron.

Security:

- Avoid storing tokens in plain text; you may choose to store them in a root-only-readable file or use environment-based secrets.

All scripts here are intentionally small and POSIX-compliant.
