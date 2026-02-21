# Appwrite Automation: Configure DNS, Domain, & Appwrite for external access

This guide automates the common steps to expose self-hosted Appwrite using a public domain and TLS.

We will use these examples with the company/branding you provided:

- Company: Extro Target Sdn Bhd

- Chosen public domain for API: `api.extrotarget.com` (you can change this to your existing domain)

The repo includes two scripts:

- `scripts/dns_cloudflare.sh` — Create/update `A` DNS record for Cloudflare-managed domains.

- `scripts/appwrite_set_domain.sh` — Update the `~/appwrite/.env` with the domain, public ip and restart Appwrite.

- `scripts/run_appwrite_setup.sh` — Orchestrator script that combines DNS + Appwrite domain update and health check

## Quick summary (what the scripts do)

1. `dns_cloudflare.sh` uses Cloudflare API to create or update A record `api.extrotarget.com` → your PUBLIC_IP.
2. `appwrite_set_domain.sh` updates `.env` variables (domain & domain target IP) and restarts Appwrite compose.

NOTE: These scripts use Cloudflare DNS API. If you're using a different DNS provider, you can adapt the approach (Route53, GoDaddy, Cloud DNS, etc.).

---

## 1) Suggestion for web address (you asked me to pick)

- Primary: `api.extrotarget.com` (good default; `extrotarget` = sanitized company name)

- Alternative: `api.extrotarget.com` or `api.extrotarget.my` for Malaysian domains

We'll use `api.extrotarget.com` for the sample script and examples.

---

## 2) DNS automation (Cloudflare example)

Pre-reqs:

- Your domain (extrotarget.com) is added to Cloudflare

- You have a Cloudflare API token with `Zone.DNS` permissions for your domain

Usage:

```bash

# Open terminal in the repo

cd /home/abber/Documents/flutterpos


# Make script executable (done already)

chmod +x scripts/dns_cloudflare.sh


# Export your Cloudflare API token first

export CF_API_TOKEN="<your_cf_api_token>"


# Run the script: domain public-ip [subdomain]

# For example: create A record for api.extrotarget.com -> 203.0.113.10

./scripts/dns_cloudflare.sh extrotarget.com 203.0.113.10 api

```text

---


## 3) Update Appwrite .env and restart (the script)


Pre-reqs:


- Appwrite installed at `~/appwrite` (the script uses $HOME/appwrite by default)

- Ensure your router port-forwarding is set up to forward TCP 80 and 443 to this server

Usage:


```bash

# Edit file path or set APPWRITE_ROOT if you installed Appwrite elsewhere

export APPWRITE_ROOT="$HOME/appwrite"


# Make the script executable

chmod +x scripts/appwrite_set_domain.sh


# Execute the script

./scripts/appwrite_set_domain.sh api.extrotarget.com 203.0.113.10

---

## Orchestrator script

You can run both the DNS step (Cloudflare) and the Appwrite domain update in one command. This script will:
1. Create or update the DNS A record via Cloudflare (if provider is cloudflare)
2. Update the `~/appwrite/.env` and restart the Appwrite containers
3. Check health endpoint `https://<domain>/v1/health/version`

Usage:


```bash

# Export token

export CF_API_TOKEN=your_token
./scripts/run_appwrite_setup.sh api.extrotarget.com 203.0.113.10 cloudflare

---

## Enabling Let's Encrypt (Traefik)


If you want Traefik to automatically request TLS certificates via Let's Encrypt, run the following:

1) Ensure ports 80 and 443 are forwarded and DNS resolved for your domain.
2) Run the Traefik ACME enabler script (it will update docker-compose.yml and prepare the environment):


```bash
./scripts/traefik_enable_acme.sh abber8@gmail.com

```text

1) If you have SELinux enabled (Fedora/RedHat), Traefik may have permission errors reading `/var/run/docker.sock` or `/storage/config`.


- You can temporarily set SELinux to permissive to validate HTTP ACME challenge:


```bash
sudo ./scripts/traefik_selinux_permissive.sh --permissive

```text

1) Configure static Traefik routes using the `traefik_config_static_appwrite.sh` script (we disable Docker provider to avoid socket access):


```bash
./scripts/traefik_config_static_appwrite.sh api.extrotarget.com

```text

1) Verify the HTTPS certificate has been issued (this may take a few minutes). Use the TLS verifier script:


```bash
./scripts/verify_tls.sh api.extrotarget.com

```text

1) Re-enable SELinux enforcement after validation if you temporarily set it to permissive:


```bash
sudo setenforce 1

```text

Notes:


- We intentionally disabled Traefik's Docker provider to avoid volume and socket permission problems. The static config proxies Appwrite services defined in the dynamic file mounted at `/storage/config/dynamic_config.yml`.

- If you require a fully dynamic Docker provider approach in a Fedora host with SELinux, consider adding explicit SELinux policies to allow Traefik access to `/var/run/docker.sock` and `/var/lib/docker/volumes/...` or run Traefik in a different mode (non-sandboxed).


```text


# Verify the health

curl -s https://api.extrotarget.com/v1/health/version

```text

If Traefik fails to start or fails to provision TLS, check `docker compose logs appwrite-traefik` and inspect `.env` for correct `_APP_DOMAIN` values.

---


## 4) Flutter client initialization (update your client code)


The Flutter snippet to use for both mobile and web clients (replace with the actual Project ID from the Appwrite console):


```dart
import 'package:appwrite/appwrite.dart';

final client = Client()
  .setEndpoint('https://api.extrotarget.com/v1')
  .setProject('689965770017299bd5a5'); // Replace with your Project ID

// then create the service clients
final account = Account(client);

```text

On mobile, ensure Android package and SHA-1 (debug and release) were added to Appwrite project settings.

---


## 5) Notes on certificates and TLS


- The default Appwrite deploy uses Traefik and will attempt to get a Let's Encrypt certificate automatically if the domain points to the server IP and ports 80/443 are forwarded.

- If you host behind NAT and use Cloudflare's proxy, make sure to use the proper setup and either use "Full" mode for Cloudflare TLS or use an origin certificate for secure connections.

---


## 6) Recommendations & next steps


- Use Cloudflare (or a similar DNS provider) – it provides API-based control and optional proxying/WAF.

- If Appwrite Traefik fails to access `/var/run/docker.sock` because of file socket permission issues, run compose with `sudo` or add the current user to the `docker` group: `sudo usermod -aG docker $USER` (re-login required).

- Consider automating cert generation and renewal using Traefik's Let’s Encrypt integration in the compose stack.

---


## 7) If you prefer a different DNS provider


- AWS Route53: use `aws-cli` to change A records; replace the Cloudflare logic in `dns_cloudflare.sh` with `aws route53 change-resource-record-sets` calls.

- GoDaddy: use their REST API to add/update records.

---


## 8) Safety & rollback


- The `appwrite_set_domain.sh` script backs up `.env` to `.env.bak` before editing – keep the file safe.

- The `dns_cloudflare.sh` only modifies a single A record; if you want to revert, remove the record in Cloudflare dashboard or use curl/`dns_cloudflare.sh` with `subdomain` set to `api` and comment removal.

---


## 9) Want me to run these scripts for you?


I cannot run commands on your production server directly without credentials, but I can:


- Help you tailor the Cloudflare token scope and commands for your environment

- Generate the exact commands to run in your terminal

- Generate a small CI/CD job (GitHub Actions) that runs these scripts and verifies the host

If you want, I’ll now add an optional GitHub Action workflow (in `.github/workflows/`) that updates DNS records on push and restarts Appwrite on your server over SSH using the provided key. Reply with "Yes, create workflow" and confirm which CI provider you'd like to use (GitHub) and I'll scaffold it for you.
