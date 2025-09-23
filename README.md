# Client Server Architecture with MySQL

## Overview
This project demonstrates the implementation of a client-server architecture using MySQL database. The setup involves configuring separate client and server instances to establish secure database connections and perform database operations.

## Architecture
- **Server**: MySQL Database Server
- **Client**: MySQL Client connecting remotely to the database server
- **Communication**: TCP/IP connection over network

## Prerequisites
- Two Linux servers (Ubuntu/CentOS)
- MySQL Server and Client packages
- Network connectivity between servers
- Proper firewall configuration

## Implementation Steps

### 1. Server Setup (MySQL Database Server)
- Install MySQL Server
- Configure MySQL for remote connections
- Create database and user accounts
- Configure firewall rules

### 2. Client Setup (MySQL Client)
- Install MySQL Client
- Configure connection parameters
- Test connectivity to remote database

### 3. Security Configuration
- Configure MySQL bind-address
- Set up user privileges
- Enable secure connections
- Configure firewall rules (port 3306)

## Key Features
- Remote database connectivity
- Secure client-server communication
- Database user management
- Network-based database operations

## Screenshots

### Initial Server Configuration
![Server Setup](Screenshot%20from%202025-09-23%2021-41-58.png)

### MySQL Installation and Configuration
![MySQL Installation](Screenshot%20from%202025-09-23%2021-42-10.png)

### Database Configuration
![Database Config](Screenshot%20from%202025-09-23%2021-42-20.png)

### Client Connection Setup
![Client Setup](Screenshot%20from%202025-09-23%2021-47-43.png)

### Remote Connection Testing
![Connection Test](Screenshot%20from%202025-09-23%2022-26-56.png)

### Successful Client-Server Communication
![Success](Screenshot%20from%202025-09-23%2022-31-16.png)

## Configuration Files
- `/etc/mysql/mysql.conf.d/mysqld.cnf` - MySQL server configuration
- Firewall rules for port 3306
- User privileges and database permissions

## Commands Used
```bash
# Server side
sudo apt update
sudo apt install mysql-server
sudo mysql_secure_installation
sudo ufw allow 3306

# Client side
sudo apt install mysql-client
mysql -h <server-ip> -u <username> -p
```

## Testing
- Verify remote connection from client to server
- Test database operations (CREATE, INSERT, SELECT)
- Confirm secure communication

## Troubleshooting
- Check firewall settings on both servers
- Verify MySQL bind-address configuration
- Ensure user has remote connection privileges
- Test network connectivity between servers

## Security Considerations
- Use strong passwords for database users
- Limit user privileges to necessary operations only
- Consider SSL/TLS encryption for production
- Regular security updates and patches

## Technologies Used
- MySQL Server
- MySQL Client
- Ubuntu/Linux
- TCP/IP networking
- UFW Firewall

## Author
Nelson Ngumo

## Project Structure
```
Client-Server-Architecture/
├── README.md
├── Screenshot from 2025-09-23 21-41-58.png
├── Screenshot from 2025-09-23 21-42-10.png
├── Screenshot from 2025-09-23 21-42-20.png
├── Screenshot from 2025-09-23 21-47-43.png
├── Screenshot from 2025-09-23 22-26-56.png
└── Screenshot from 2025-09-23 22-31-16.png
```

## Learning Outcomes
- Understanding client-server architecture
- MySQL remote configuration
- Network security basics
- Database user management
- Firewall configuration
- Remote database connectivity troubleshooting