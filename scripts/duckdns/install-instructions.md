DuckDNS systemd installer instructions

1) Copy the files to the system paths and make the script executable

```bash
sudo cp scripts/duckdns/update_duckdns.sh /usr/local/bin/update_duckdns.sh
sudo chmod +x /usr/local/bin/update_duckdns.sh
sudo cp scripts/duckdns/duckdns-update.service /etc/systemd/system/duckdns-update.service
sudo cp scripts/duckdns/duckdns-update.timer /etc/systemd/system/duckdns-update.timer

```

1) Edit the service to fill in your DuckDNS token/domain either in the ExecStart line or use an environment file. Example recommended alternative (safer):

Create `/etc/duckdns/duckdns.conf` with restricted perms:

```
DOMAIN=extropos
TOKEN=YOUR_DUCKDNS_TOKEN

```

Change the service ExecStart line to:

```
ExecStart=/usr/local/bin/update_duckdns.sh $DOMAIN $TOKEN

```

1) Reload systemd and enable timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now duckdns-update.timer
sudo systemctl status duckdns-update.timer

```

1) Verify the update log

```bash
sudo journalctl -u duckdns-update.service --no-pager -n 200

```

1) OPTIONAL: If you want to use Cron instead of systemd:

```

# run every 5 minutes

*/5 * * * * /usr/local/bin/update_duckdns.sh extropos YOUR_DUCKDNS_TOKEN >> /var/log/duckdns-update.log 2>&1

```

Security notes:

- Do not store secret token in world-readable files. Use root-only-readable files or environment variables only accessible to root.

- Validate DNS update success with:

```bash
curl "https://www.duckdns.org/update?domains=extropos&token=TOKEN&ip="


### Fedora notes


- Enable firewall ports with `firewalld`:
 ```bash
 sudo firewall-cmd --permanent --add-service=http
 sudo firewall-cmd --permanent --add-service=https
 sudo firewall-cmd --reload
 ```

- If you are using SELinux, remember to configure proper labeling for the update script dataset or directories if you store the token under `/etc/duckdns`:

 ```bash
 sudo semanage fcontext -a -t etc_t '/etc/duckdns(/.*)?'
 sudo restorecon -Rv /etc/duckdns
 ```

Note: `semanage` is provided by `policycoreutils-python-utils` which you can install with `sudo dnf install -y policycoreutils-python-utils`.

```
