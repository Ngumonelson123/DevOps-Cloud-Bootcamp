# StegTechHub Tooling

A lightweight **PHP + MySQL (LAMP) application** deployed on an **AWS EC2 instance (RHEL 9)** with Apache and PHP-FPM.  
This project demonstrates secure server setup, database connectivity, and deployment of a tooling portal with authentication.

![Application Overview](Screenshot%20from%202025-10-17%2023-03-22.png)

---

## 🚀 Features
- PHP 8.3 + Apache + PHP-FPM integration  
- MySQL 8.0 backend with secure user authentication  
- TailwindCSS frontend for clean UI  
- Central login page with session handling  
- Deployed on AWS EC2 (Red Hat Enterprise Linux)  
- Configured with **php-fpm** and hardened **httpd.conf**

---

## 🛠️ Prerequisites
- **EC2 instance** running RHEL 9  
- **MySQL 8.x** running on a private host (e.g., `10.0.1.75`)  
- Security groups opened for:  
  - Port 22 (SSH – restricted)  
  - Port 80 (HTTP)  
  - Port 443 (HTTPS, optional)  
  - Port 3306 (MySQL – restricted to VPC/private subnet)

---

## 🏗️ Architecture

The application follows a typical LAMP stack architecture deployed on AWS:

![System Architecture](Screenshot%20from%202025-10-16%2023-35-37.png)

---

## ⚙️ Installation

### 1. Update & Install Packages
```bash
sudo dnf update -y
sudo dnf install -y httpd php php-cli php-fpm php-mysqlnd php-json php-xml php-gd mariadb105-server
```

![Package Installation](Screenshot%20from%202025-10-16%2023-35-42.png)

### 2. Configure Apache & PHP-FPM
```bash
# Start and enable services
sudo systemctl start httpd php-fpm
sudo systemctl enable httpd php-fpm

# Configure PHP-FPM
sudo vi /etc/php-fpm.d/www.conf
```

![Service Configuration](Screenshot%20from%202025-10-16%2023-37-50.png)

### 3. Database Setup
```bash
# Connect to MySQL server
mysql -h 10.0.1.75 -u admin -p

# Create database and user
CREATE DATABASE tooling;
CREATE USER 'webaccess'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON tooling.* TO 'webaccess'@'%';
FLUSH PRIVILEGES;
```

![Database Configuration](Screenshot%20from%202025-10-16%2023-55-01.png)

### 4. Deploy Application
```bash
# Clone or upload application files
sudo cp -r /path/to/tooling/* /var/www/html/
sudo chown -R apache:apache /var/www/html/
sudo chmod -R 755 /var/www/html/
```

![Application Deployment](Screenshot%20from%202025-10-17%2000-23-16.png)

---

## 🔧 Configuration

### Apache Virtual Host
```apache
<VirtualHost *:80>
    ServerName tooling.steghub.com
    DocumentRoot /var/www/html
    
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog /var/log/httpd/tooling_error.log
    CustomLog /var/log/httpd/tooling_access.log combined
</VirtualHost>
```

![Apache Configuration](Screenshot%20from%202025-10-17%2000-46-37.png)

### PHP Configuration
```php
<?php
// Database connection
$host = '10.0.1.75';
$dbname = 'tooling';
$username = 'webaccess';
$password = 'password';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die("Connection failed: " . $e->getMessage());
}
?>
```

![PHP Configuration](Screenshot%20from%202025-10-17%2000-55-41.png)

---

## 🎯 Results

### Login Page
The application features a clean, responsive login interface:

![Login Page](Screenshot%20from%202025-10-17%2021-44-01.png)

### Dashboard
After successful authentication, users access the main tooling dashboard:

![Dashboard](Screenshot%20from%202025-10-17%2021-44-08.png)

---

## 🔒 Security Features
- PHP-FPM process isolation
- MySQL user with limited privileges
- Apache security headers
- Session-based authentication
- Input validation and sanitization

---

## 🚀 Deployment

1. **EC2 Instance**: RHEL 9 with security groups configured
2. **Database**: MySQL 8.0 on private subnet
3. **Web Server**: Apache with PHP-FPM
4. **SSL**: Optional HTTPS configuration

---

## 📝 Usage

1. Access the application via browser: `http://your-ec2-public-ip`
2. Login with valid credentials
3. Navigate through the tooling interface
4. Manage users and access controls

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👨‍💻 Author

**Nelson Ngumo**  
DevOps Engineer | Cloud Architect
