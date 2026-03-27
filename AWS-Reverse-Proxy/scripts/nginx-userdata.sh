#!/bin/bash
set -e

# ── System update & packages ──────────────────────────────────
yum update -y
yum install -y python3 ntp net-tools vim wget telnet epel-release htop amazon-efs-utils

# ── Start & enable NTP ────────────────────────────────────────
systemctl enable --now chronyd

# ── Install Nginx ─────────────────────────────────────────────
yum install -y nginx
systemctl enable nginx

# ── Mount EFS ────────────────────────────────────────────────
EFS_ID="${efs_id}"
EFS_MOUNT_POINT="/var/log/nginx/efs"
mkdir -p $EFS_MOUNT_POINT

# Add to fstab for persistent mount
echo "$EFS_ID:/ $EFS_MOUNT_POINT efs defaults,_netdev 0 0" >> /etc/fstab
mount -a

# ── Nginx Reverse Proxy Config ────────────────────────────────
INTERNAL_ALB="${internal_alb_dns}"

cat > /etc/nginx/nginx.conf <<NGINX
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    sendfile      on;
    keepalive_timeout 65;

    # Health check endpoint
    server {
        listen 443 ssl;
        server_name _;

        ssl_certificate     /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        location /healthstatus {
            return 200 'healthy';
            add_header Content-Type text/plain;
        }
    }

    # WordPress – root domain
    server {
        listen 443 ssl;
        server_name ~^(?!tooling\.).*;

        ssl_certificate     /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        location / {
            proxy_pass         https://$INTERNAL_ALB;
            proxy_set_header   Host            \$host;
            proxy_set_header   X-Real-IP       \$remote_addr;
            proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Proto https;
            proxy_ssl_verify   off;
        }
    }

    # Tooling – tooling.* subdomain
    server {
        listen 443 ssl;
        server_name tooling.*;

        ssl_certificate     /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        location / {
            proxy_pass         https://$INTERNAL_ALB;
            proxy_set_header   Host            \$host;
            proxy_set_header   X-Real-IP       \$remote_addr;
            proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Proto https;
            proxy_ssl_verify   off;
        }
    }
}
NGINX

# ── Self-signed cert (ALB terminates real TLS; this is Nginx↔ALB) ──
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx.key \
  -out    /etc/nginx/ssl/nginx.crt \
  -subj "/C=US/ST=State/L=City/O=Org/CN=internal"

# ── Start Nginx ───────────────────────────────────────────────
nginx -t && systemctl start nginx
