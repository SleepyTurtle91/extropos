# DNS Setup Guide for extropos.org

## 🌐 DNS Configuration Required

Before running the SSL setup, configure these DNS records:

### Required A Records

| Subdomain | Type | Value | TTL |
|-----------|------|-------|-----|
| `api.extropos.org` | A | `YOUR_SERVER_PUBLIC_IP` | 300 |
| `backend.extropos.org` | A | `YOUR_SERVER_PUBLIC_IP` | 300 |
| `appwrite.extropos.org` | A | `YOUR_SERVER_PUBLIC_IP` | 300 |

### Get Your Public IP

```bash

# Windows PowerShell

(Invoke-WebRequest -Uri "https://api.ipify.org").Content


# Or visit

https://whatismyip.com

```

---

## 📝 Step-by-Step DNS Setup

### If using Cloudflare

1. **Login** to Cloudflare dashboard

2. **Select** `extropos.org` domain

3. **Click** `DNS` in left menu

4. **Add** the following records:

   **Record 1:**

   - Type: `A`

   - Name: `api`

   - IPv4 address: `YOUR_SERVER_IP`

   - Proxy status: `🔴 DNS only` (IMPORTANT: Disable proxy initially)

   - TTL: `Auto`

   **Record 2:**

   - Type: `A`

   - Name: `backend`

   - IPv4 address: `YOUR_SERVER_IP`

   - Proxy status: `🔴 DNS only`

   - TTL: `Auto`

   **Record 3:**

   - Type: `A`

   - Name: `appwrite`

   - IPv4 address: `YOUR_SERVER_IP`

   - Proxy status: `🔴 DNS only`

   - TTL: `Auto`

5. **Wait** 2-5 minutes for DNS propagation

### If using other DNS provider (GoDaddy, Namecheap, etc.)

1. **Login** to your domain registrar

2. **Navigate** to DNS management for `extropos.org`

3. **Add A records** as shown in table above

4. **Save** changes

5. **Wait** 5-15 minutes for DNS propagation

---

## ✅ Verify DNS Configuration

Before proceeding to SSL setup, verify DNS is working:

### Windows PowerShell

```powershell

# Check api subdomain

Resolve-DnsName api.extropos.org -Type A


# Should return your server IP

```

### Alternative test

```powershell

# Check DNS propagation worldwide

Start-Process "https://dnschecker.org/#A/api.extropos.org"

```

**Expected Result:**

```
Name: api.extropos.org
Address: YOUR_SERVER_IP

```

---

## 🔒 After DNS is Confirmed Working

**Run SSL setup:**

```powershell
cd E:\flutterpos\docker


# Edit setup-ssl.ps1 to add your email

notepad setup-ssl.ps1


# Update line 6:

# [string]$Email = "your-actual-email@gmail.com"



# Save and run

.\setup-ssl.ps1

```

---

## 🚨 Firewall Configuration

Ensure your server firewall allows inbound traffic:

### Windows Firewall

```powershell

# Allow HTTP (port 80)

New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow


# Allow HTTPS (port 443)

New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow

```

### Cloud Provider (AWS, Azure, GCP, DigitalOcean)

Add inbound rules in security group/firewall:

- Port 80 (HTTP) from 0.0.0.0/0

- Port 443 (HTTPS) from 0.0.0.0/0

---

## 📊 Troubleshooting

### DNS not resolving?

- **Wait longer** (DNS can take up to 24 hours, usually 5-15 min)

- **Clear DNS cache**: `ipconfig /flushdns`

- **Try different DNS checker**: <https://www.whatsmydns.net>

### SSL certificate fails?

- **Verify DNS** resolves correctly first

- **Check firewall** allows port 80

- **Ensure email** in setup-ssl.ps1 is valid

- **Check rate limits**: Let's Encrypt has limits (5 certs/week per domain)

### API not accessible after SSL?

- **Check containers**: `docker ps`

- **Check NGINX logs**: `docker logs api-nginx`

- **Verify certificate**: `docker exec api-nginx ls -la /etc/letsencrypt/live/`

---

## 📞 Support

If you encounter issues:

1. Check DNS: `Resolve-DnsName api.extropos.org`
2. Check containers: `docker ps`
3. Check NGINX logs: `docker logs api-nginx`
4. Check API logs: `docker logs super-admin-api`
