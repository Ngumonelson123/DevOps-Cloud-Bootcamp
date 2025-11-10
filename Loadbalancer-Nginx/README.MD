# Nginx Load Balancer Solution

## 🎯 Objective
Configure **Nginx** as a load balancer to distribute web traffic across multiple backend servers, demonstrating high availability and scalability in web infrastructure.

---

## 🏗️ Architecture Overview

This project implements an Nginx-based load balancing solution that:
- Distributes incoming requests across multiple backend web servers
- Provides high availability and fault tolerance
- Implements various load balancing algorithms
- Monitors backend server health

---

## ⚙️ Configuration Steps

### 1️⃣ Nginx Installation & Setup
```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 2️⃣ Load Balancer Configuration
Configure Nginx upstream servers and load balancing:

```nginx
upstream backend_servers {
    server 10.0.1.84:80;
    server 10.0.1.128:80;
    # Add more servers as needed
}

server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## 📊 Implementation Screenshots

### Initial Setup and Configuration
![Nginx Configuration Setup](Screenshot%20from%202025-11-11%2000-04-35.png)

### Load Balancer Status Verification
![Load Balancer Status Check](Screenshot%20from%202025-11-11%2000-04-44.png)

### Backend Server Configuration
![Backend Servers Configuration](Screenshot%20from%202025-11-11%2000-09-57.png)

### Load Balancing in Action
![Load Balancing Testing](Screenshot%20from%202025-11-11%2000-10-20.png)

### Final Verification and Results
![Final Load Balancer Verification](Screenshot%20from%202025-11-11%2000-17-25.png)

---

## 🔍 Testing & Verification

### Load Balancing Test
```bash
# Test multiple requests to verify distribution
for i in {1..10}; do
    curl -s http://your-load-balancer-ip/ | grep "Server"
    sleep 1
done
```

### Health Check Verification
```bash
# Check Nginx status
sudo systemctl status nginx

# Verify configuration
sudo nginx -t

# Check access logs
sudo tail -f /var/log/nginx/access.log
```

---

## 🚀 Load Balancing Methods

Nginx supports various load balancing algorithms:

- **Round Robin** (default): Requests distributed sequentially
- **Least Connections**: Routes to server with fewest active connections
- **IP Hash**: Routes based on client IP hash
- **Weighted**: Assigns different weights to servers

---

## 🛡️ High Availability Features

- **Health Checks**: Automatic detection of failed servers
- **Failover**: Automatic traffic redirection when servers fail
- **Session Persistence**: Sticky sessions when required
- **SSL Termination**: Centralized SSL/TLS handling

---

## 📈 Benefits Achieved

✅ **Improved Performance**: Traffic distributed across multiple servers  
✅ **High Availability**: No single point of failure  
✅ **Scalability**: Easy addition of new backend servers  
✅ **Load Distribution**: Optimal resource utilization  
✅ **Health Monitoring**: Automatic server health detection  

---

## 🔧 Troubleshooting

Common issues and solutions:
- **502 Bad Gateway**: Check backend server availability
- **Connection refused**: Verify firewall rules and server status
- **Uneven distribution**: Review load balancing algorithm configuration

---

## 📝 Key Learnings

- Nginx provides efficient Layer 7 load balancing
- Proper health checks ensure high availability
- Configuration flexibility allows various deployment scenarios
- Monitoring and logging are crucial for troubleshooting

---

**Project:** Nginx Load Balancer Implementation  
**Date:** November 2025  
**Technology Stack:** Nginx, Ubuntu Server, Load Balancing