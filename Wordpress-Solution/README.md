# WordPress + MySQL Deployment on AWS EC2

This project demonstrates the deployment of a WordPress application with MySQL database on Amazon EC2 instances, showcasing a complete LAMP stack implementation.

## Architecture Overview

- **Web Server**: Apache HTTP Server
- **Application**: WordPress (PHP-based CMS)
- **Database**: MySQL Server
- **Infrastructure**: AWS EC2 instances
- **Operating System**: Linux (Ubuntu/Amazon Linux)

## Prerequisites

- AWS Account with appropriate permissions
- Basic knowledge of Linux commands
- Understanding of web server configuration
- SSH key pair for EC2 access

## Deployment Steps

### 1. EC2 Instance Setup

Launch and configure EC2 instances for the WordPress deployment.

![EC2 Instance Configuration](Screenshot%20from%202025-09-30%2022-49-42.png)

### 2. Security Group Configuration

Configure security groups to allow necessary traffic (HTTP, HTTPS, SSH, MySQL).

![Security Group Setup](Screenshot%20from%202025-09-30%2022-51-14.png)

### 3. Server Environment Preparation

Install and configure the LAMP stack components on the EC2 instance.

![Server Environment Setup](Screenshot%20from%202025-09-30%2022-55-55.png)

### 4. MySQL Database Configuration

Set up MySQL server and create the WordPress database.

![MySQL Database Setup](Screenshot%20from%202025-09-30%2023-34-46.png)

### 5. WordPress Installation

Download and configure WordPress files on the web server.

![WordPress Installation](Screenshot%20from%202025-09-30%2023-48-23.png)

### 6. Apache Web Server Configuration

Configure Apache virtual hosts and enable necessary modules.

![Apache Configuration](Screenshot%20from%202025-10-01%2000-13-03.png)

### 7. WordPress Database Connection

Configure WordPress to connect to the MySQL database.

![WordPress Database Connection](Screenshot%20from%202025-10-01%2000-23-06.png)

### 8. WordPress Initial Setup

Complete the WordPress installation through the web interface.

![WordPress Initial Setup](Screenshot%20from%202025-10-01%2001-11-40.png)

### 9. WordPress Dashboard Access

Access and verify the WordPress admin dashboard functionality.

![WordPress Dashboard](Screenshot%20from%202025-10-02%2022-04-03.png)

### 10. Site Verification

Verify the WordPress site is accessible and functioning properly.

![Site Verification](Screenshot%20from%202025-10-02%2022-07-34.png)

### 11. Final Configuration

Complete final configurations and optimizations.

![Final Configuration](Screenshot%20from%202025-10-02%2022-08-56.png)

## Key Components Installed

### Web Server Stack
- **Apache HTTP Server**: Web server to serve WordPress
- **PHP**: Server-side scripting language
- **MySQL**: Relational database management system

### WordPress Components
- WordPress Core Files
- wp-config.php configuration
- Database tables and structure
- Admin user account

## Security Considerations

- Security groups configured with minimal required ports
- MySQL access restricted to web server
- Regular security updates recommended
- Strong passwords for all accounts
- SSL/TLS certificate implementation (recommended)

## Performance Optimizations

- Apache modules optimization
- PHP configuration tuning
- MySQL query optimization
- Caching mechanisms (recommended)

## Maintenance Tasks

- Regular WordPress updates
- Plugin and theme updates
- Database backups
- Security monitoring
- Performance monitoring

## Troubleshooting

### Common Issues
- **Database Connection Errors**: Verify MySQL credentials and connectivity
- **Permission Issues**: Check file permissions for WordPress directories
- **Apache Configuration**: Validate virtual host configuration
- **PHP Errors**: Check PHP error logs and configuration

### Log Locations
- Apache Error Log: `/var/log/apache2/error.log`
- Apache Access Log: `/var/log/apache2/access.log`
- MySQL Error Log: `/var/log/mysql/error.log`
- WordPress Debug Log: `/wp-content/debug.log` (if enabled)

## Cost Optimization

- Use appropriate EC2 instance types
- Implement auto-scaling for traffic spikes
- Consider Reserved Instances for long-term usage
- Monitor and optimize resource utilization

## Next Steps

- Implement SSL/TLS certificates
- Set up automated backups
- Configure monitoring and alerting
- Implement CDN for better performance
- Set up staging environment

## Technologies Used

- **AWS EC2**: Virtual server hosting
- **Apache**: Web server
- **MySQL**: Database server
- **PHP**: Server-side scripting
- **WordPress**: Content Management System
- **Linux**: Operating system

## Project Structure

```
Wordpress-Solution/
├── README.md
├── Screenshot from 2025-09-30 22-49-42.png
├── Screenshot from 2025-09-30 22-51-14.png
├── Screenshot from 2025-09-30 22-55-55.png
├── Screenshot from 2025-09-30 23-34-46.png
├── Screenshot from 2025-09-30 23-48-23.png
├── Screenshot from 2025-10-01 00-13-03.png
├── Screenshot from 2025-10-01 00-23-06.png
├── Screenshot from 2025-10-01 01-11-40.png
├── Screenshot from 2025-10-02 22-04-03.png
├── Screenshot from 2025-10-02 22-07-34.png
└── Screenshot from 2025-10-02 22-08-56.png
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is for educational purposes as part of the StegHub DevOps Cloud Bootcamp.

---

**Author**: Nelson Ngumo  
**Project**: StegHub DevOps Cloud Bootcamp  
**Date**: September-October 2025