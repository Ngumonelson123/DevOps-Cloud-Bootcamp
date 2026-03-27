#!/bin/bash
set -e

# ── System update & packages ──────────────────────────────────
yum update -y
yum install -y python3 ntp net-tools vim wget telnet epel-release htop php \
               amazon-efs-utils mysql php-mysqlnd php-fpm php-json \
               php-gd php-mbstring php-xml php-xmlrpc php-soap \
               php-intl php-zip

systemctl enable --now chronyd

# ── Install Apache (httpd) ────────────────────────────────────
yum install -y httpd
systemctl enable httpd

# ── Install mod_ssl for HTTPS ─────────────────────────────────
yum install -y mod_ssl
mkdir -p /etc/pki/tls/private /etc/pki/tls/certs
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/pki/tls/private/apache-selfsigned.key \
  -out    /etc/pki/tls/certs/apache-selfsigned.crt \
  -subj "/C=US/ST=State/L=City/O=Org/CN=internal"

# ── Mount EFS ─────────────────────────────────────────────────
EFS_ID="${efs_id}"
WORDPRESS_DIR="/var/www/html/wordpress"
mkdir -p $WORDPRESS_DIR

echo "$EFS_ID:/wordpress $WORDPRESS_DIR efs _netdev,tls,accesspoint= 0 0" >> /etc/fstab
mount -a || true   # tolerate first-boot race; subsequent boots use fstab

# ── Download & configure WordPress ───────────────────────────
cd /tmp
wget -q https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz

# Only copy files if EFS is empty (first instance wins)
if [ ! -f "$WORDPRESS_DIR/wp-config.php" ]; then
  cp -r wordpress/* $WORDPRESS_DIR/
  cd $WORDPRESS_DIR
  cp wp-config-sample.php wp-config.php

  RDS_ENDPOINT="${rds_endpoint}"
  sed -i "s/database_name_here/wordpressdb/"     wp-config.php
  sed -i "s/username_here/admin/"                wp-config.php
  sed -i "s/password_here/YourStr0ngP@ssword!/"  wp-config.php
  sed -i "s/localhost/$RDS_ENDPOINT/"            wp-config.php

  # Security keys (fetch fresh from WordPress API)
  SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
  printf '%s\n' "g/put your unique phrase here/d" a "$SALT" . w | ed -s wp-config.php
fi

chown -R apache:apache $WORDPRESS_DIR

# ── Apache SSL VirtualHost ────────────────────────────────────
cat > /etc/httpd/conf.d/wordpress-ssl.conf <<'APACHECONF'
<VirtualHost *:443>
    SSLEngine on
    SSLCertificateFile    /etc/pki/tls/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/pki/tls/private/apache-selfsigned.key

    DocumentRoot /var/www/html/wordpress

    <Directory /var/www/html/wordpress>
        AllowOverride All
        Require all granted
    </Directory>

    # Health check
    Alias /healthstatus /var/www/html/healthstatus
    <Location /healthstatus>
        Require all granted
    </Location>
</VirtualHost>
APACHECONF

# Health check file
echo "healthy" > /var/www/html/healthstatus

# ── Enable & start services ───────────────────────────────────
systemctl enable --now php-fpm
systemctl start httpd
