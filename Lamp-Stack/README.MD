# 🌐 LAMP Stack Deployment on AWS EC2

This project demonstrates the deployment of a **LAMP Stack (Linux, Apache, MySQL, PHP)** on an **AWS EC2 Ubuntu 24.04 server**.  

---

## 🚀 Project Overview
- **Platform**: AWS EC2 (t2.micro, Ubuntu 24.04 LTS)  
- **Stack**: Linux + Apache + MySQL + PHP  
- **Public IP**: `18.214.37.24`  
- **Public DNS**: `ec2-18-214-37-24.compute-1.amazonaws.com`  
- **Goal**: Deploy and validate a fully working web stack.

---

## ⚙️ Setup Steps

### 1. Launch EC2 Instance
- Chose Ubuntu 24.04 LTS on AWS Free Tier.  
- Security Group inbound rules:  
  - **22/tcp** → SSH  
  - **80/tcp** → HTTP  
  - **443/tcp** → HTTPS  

### 2. Connect to Instance
```bash
ssh -o IdentitiesOnly=yes -i steghub.pem ubuntu@<EC2-Public-IP>

#Install Apache
sudo apt update
sudo apt install apache2 -y


#Configure Virtual Host
Created /etc/apache2/sites-available/projectlamp.conf:
<VirtualHost *:80>
    ServerName projectlamp
    ServerAlias www.projectlamp
    DocumentRoot /var/www/projectlamp
    <Directory /var/www/projectlamp>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/projectlamp_error.log
    CustomLog ${APACHE_LOG_DIR}/projectlamp_access.log combined
</VirtualHost>


#Enabled and reloaded:
sudo mkdir -p /var/www/projectlamp
sudo a2ensite projectlamp.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2

#Added Metadata Test Page
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

PUB_HOST=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-hostname)

PUB_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)

sudo tee /var/www/projectlamp/index.html >/dev/null <<EOF
<h1>Hello LAMP from hostname ${PUB_HOST}</h1>
<p>with public IP ${PUB_IP}</p>
EOF

#Install PHP
sudo apt install php libapache2-mod-php php-mysql -y
php -v

#Created test file:
echo "<?php phpinfo(); ?>" | sudo tee /var/www/projectlamp/index.php



