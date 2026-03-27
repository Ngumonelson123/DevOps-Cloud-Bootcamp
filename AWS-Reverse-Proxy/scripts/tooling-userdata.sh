#!/bin/bash
set -e

# ── System update & packages ──────────────────────────────────
yum update -y
yum install -y python3 ntp net-tools vim wget telnet epel-release htop php \
               amazon-efs-utils mysql php-mysqlnd php-fpm php-json php-gd

systemctl enable --now chronyd

# ── Install Apache ────────────────────────────────────────────
yum install -y httpd mod_ssl
systemctl enable httpd

# ── Self-signed cert for internal HTTPS ──────────────────────
mkdir -p /etc/pki/tls/private /etc/pki/tls/certs
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/pki/tls/private/apache-selfsigned.key \
  -out    /etc/pki/tls/certs/apache-selfsigned.crt \
  -subj "/C=US/ST=State/L=City/O=Org/CN=internal"

# ── Mount EFS (tooling access point) ─────────────────────────
EFS_ID="${efs_id}"
TOOLING_DIR="/var/www/html/tooling"
mkdir -p $TOOLING_DIR

echo "$EFS_ID:/tooling $TOOLING_DIR efs _netdev,tls 0 0" >> /etc/fstab
mount -a || true

# ── Clone tooling app if not already on EFS ───────────────────
if [ ! -f "$TOOLING_DIR/index.php" ]; then
  yum install -y git
  git clone https://github.com/darey-io/tooling.git /tmp/tooling-src
  cp -r /tmp/tooling-src/html/* $TOOLING_DIR/

  # Update DB connection details
  RDS_ENDPOINT="${rds_endpoint}"
  DB_CONF="$TOOLING_DIR/inc/db_connect.php"
  if [ -f "$DB_CONF" ]; then
    sed -i "s|DB_HOST|$RDS_ENDPOINT|g"       $DB_CONF
    sed -i "s|DB_USER|admin|g"               $DB_CONF
    sed -i "s|DB_PASS|YourStr0ngP@ssword!|g" $DB_CONF
    sed -i "s|DB_NAME|toolingdb|g"           $DB_CONF
  fi
fi

chown -R apache:apache $TOOLING_DIR

# ── Apache SSL VirtualHost for Tooling ───────────────────────
cat > /etc/httpd/conf.d/tooling-ssl.conf <<'APACHECONF'
<VirtualHost *:443>
    SSLEngine on
    SSLCertificateFile    /etc/pki/tls/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/pki/tls/private/apache-selfsigned.key

    DocumentRoot /var/www/html/tooling

    <Directory /var/www/html/tooling>
        AllowOverride All
        Require all granted
    </Directory>

    Alias /healthstatus /var/www/html/healthstatus
    <Location /healthstatus>
        Require all granted
    </Location>
</VirtualHost>
APACHECONF

echo "healthy" > /var/www/html/healthstatus

systemctl enable --now php-fpm
systemctl start httpd
