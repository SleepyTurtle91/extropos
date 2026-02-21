# Cloudflare Tunnel Setup for FlutterPOS

## Prerequisites

1. Cloudflare account (free): <https://dash.cloudflare.com/>
2. A domain (can use Cloudflare's free `.cloudflare.com` subdomain)

## Step 1: Create Cloudflare Tunnel

1. Login to Cloudflare Dashboard: <https://dash.cloudflare.com/>
2. Go to **Zero Trust** (left sidebar)

3. Navigate to **Networks** > **Tunnels**

4. Click **Create a tunnel**
5. Choose **Cloudflared** connector

6. Name your tunnel: `flutterpos-backend`
7. Click **Save tunnel**

## Step 2: Install cloudflared (on this machine)

For Manjaro/Arch Linux:

```bash
yay -S cloudflared

# or

paru -S cloudflared

```

Or use Docker approach (recommended):

```bash

# We'll add cloudflared to docker-compose.yml

```

## Step 3: Get Tunnel Token

After creating the tunnel in Cloudflare dashboard:

1. Copy the tunnel token (starts with `eyJ...`)
2. Save it for the next step

## Step 4: Configure Public Hostnames

In the Cloudflare tunnel configuration, add these public hostnames:

| Public Hostname | Service | Type |
|-----------------|---------|------|
| `appwrite.your-domain.com` | `http://traefik:80` | HTTP |
| `backend.your-domain.com` | `http://traefik:80` | HTTP |
| `cloud.your-domain.com` | `http://traefik:80` | HTTP |
| `mail.your-domain.com` | `http://traefik:80` | HTTP |

Or use wildcards:

| Public Hostname | Service | Type |
|-----------------|---------|------|
| `*.your-domain.com` | `http://traefik:80` | HTTP |

## Step 5: Add to Docker Compose

We'll add a cloudflared service to `docker-compose.yml`.

## Benefits

- ✅ No port forwarding required

- ✅ Free SSL certificates

- ✅ DDoS protection

- ✅ Works with any ISP

- ✅ Access control options
