# Cloudflare Tunnel Public Hostname Setup

## Step-by-Step Instructions

1. Click on **"POS-Backend-Tunnel"** in the "Recently modified Tunnels" list

2. You'll see tabs at the top - click on **"Public Hostname"** tab

3. Click **"Add a public hostname"** button

4. Fill in the form for each service:

### Service 1: Appwrite

- Subdomain: `appwrite`

- Domain: `extropos.org`

- Path: (leave empty)

- Service Type: `HTTP`

- URL: `http://172.21.0.3:80`

- Click "Save hostname"

### Service 2: Backend

- Subdomain: `backend`

- Domain: `extropos.org`

- Service Type: `HTTP`

- URL: `http://172.21.0.3:80`

### Service 3: Cloud

- Subdomain: `cloud`

- Domain: `extropos.org`

- Service Type: `HTTP`

- URL: `http://172.21.0.3:80`

### Service 4: Mail

- Subdomain: `mail`

- Domain: `extropos.org`

- Service Type: `HTTP`

- URL: `http://172.21.0.3:80`

### Service 5: Root Domain

- Subdomain: (leave empty)

- Domain: `extropos.org`

- Service Type: `HTTP`

- URL: `http://172.21.0.3:80`

## Important Notes

- All services point to the SAME IP: `172.21.0.3:80` (Traefik)

- Traefik will route based on the hostname

- DNS records will be created automatically

- Changes take effect immediately

## After Setup

Test these URLs:

- <https://appwrite.extropos.org>

- <https://backend.extropos.org>

- <https://cloud.extropos.org>

- <https://mail.extropos.org>
