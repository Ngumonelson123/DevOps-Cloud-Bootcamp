# Apache Load Balancer Solution – 102

## 🧩 Objective
To configure **Apache HTTP Server** as a load balancer that distributes web traffic evenly across two backend servers. The lab demonstrates request distribution, module configuration, and management through the **Balancer Manager** interface.

---

## 🏗️ Environment Setup

| Role | IP Address | OS |
|------|-------------|----|
| Load Balancer | 34.205.252.223 / 10.0.1.111 | Ubuntu Server 22.04 |
| Web Server 1 | 10.0.1.84 | RHEL |
| Web Server 2 | 10.0.1.128 | RHEL |

Each web server hosts a simple HTML file under `/var/www/html/index.html`:
- **Web Server 1:** `<h1>Web Server 1</h1>`
- **Web Server 2:** `<h1>Web Server 2</h1>`

---

## ⚙️ Apache Configuration

### 1️⃣ Install Apache and required modules
```bash
sudo apt update
sudo apt install apache2 -y
sudo a2enmod proxy proxy_balancer proxy_http lbmethod_byrequests headers rewrite
```

### 2️⃣ Configure the Load Balancer
Edit:
```bash
sudo nano /etc/apache2/sites-available/000-default.conf
```

Paste:
```apache
<VirtualHost *:80>
    ServerName www.example.com
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <Proxy "balancer://mycluster">
        BalancerMember http://10.0.1.84:80 loadfactor=5 timeout=30
        BalancerMember http://10.0.1.128:80 loadfactor=5 timeout=30
        ProxySet lbmethod=byrequests nofailover=On stickysession=None
    </Proxy>

    ProxyPreserveHost Off
    ProxyPass / balancer://mycluster/ connectiontimeout=5 timeout=30
    ProxyPassReverse / balancer://mycluster/
</VirtualHost>
```

![000-default.conf Configuration](Screenshot%20from%202025-10-23%2022-10-08.png)

Validate and restart:
```bash
sudo apachectl configtest
sudo systemctl restart apache2
```

---

## 🧭 Balancer Manager Setup

Create the management interface:
```bash
sudo nano /etc/apache2/conf-available/balancer-manager.conf
```

Add:
```apache
<Location "/balancer-manager">
    SetHandler balancer-manager
    Require all granted
</Location>

ProxyPass "/balancer-manager" "!"
```

Enable and restart:
```bash
sudo a2enconf balancer-manager
sudo systemctl restart apache2
```

Access in a browser:
👉 **http://34.205.252.223/balancer-manager**

Expected view:
- Cluster: `balancer://mycluster`
- Members: `http://10.0.1.84` and `http://10.0.1.128`
- Status: OK

![Balancer Manager Dashboard](Screenshot%20from%202025-10-23%2022-28-42.png)

---

## 🔍 Verification & Testing

### 1️⃣ Check module status
```bash
sudo systemctl status apache2
```
Expected: **active (running)**

![Apache Status Running](Screenshot%20from%202025-10-22%2023-38-20.png)

### 2️⃣ Verify backend connectivity
```bash
curl -I http://10.0.1.84
curl -I http://10.0.1.128
```
Both return `HTTP/1.1 200 OK`.

### 3️⃣ Validate load balancing
```bash
for i in {1..8}; do curl -s -H "Connection: close" http://34.205.252.223/ | grep "Web"; done
```

✅ Output:
```
<h1>Web Server 2</h1>
<h1>Web Server 1</h1>
<h1>Web Server 2</h1>
<h1>Web Server 1</h1>
<h1>Web Server 2</h1>
<h1>Web Server 1</h1>
...
```

![Curl Output Alternating WS1/WS2](Screenshot%20from%202025-10-23%2022-28-50.png)

### 4️⃣ Confirm from logs
```bash
sudo tail -n 30 /var/log/apache2/error.log | grep "elected"
```
Shows alternating worker selection:
```
proxy: byrequests selected worker "http://10.0.1.84"
proxy: byrequests selected worker "http://10.0.1.128"
```

![Apache Configuration and Logs](Screenshot%20from%202025-10-23%2022-28-56.png)

---

## 🧠 Key Learnings
- **lbmethod=byrequests** evenly distributes client requests.
- **ProxySet stickysession=None** disables session affinity for pure round-robin behavior.
- **Balancer Manager** provides real-time health, stats, and manual control.
- Debug logs (`LogLevel proxy_balancer:debug`) are invaluable for tracing backend selection.

---

## 🧹 Optional Enhancements
- Add SSL termination with `mod_ssl`.
- Restrict manager access:
  ```apache
  <Location "/balancer-manager">
      Require ip 192.168.100.17
  </Location>
  ```
- Configure health checks:
  ```apache
  ProxyPass / balancer://mycluster/ retry=5
  ```

---

## 🏁 Result
✅ Apache successfully distributes web traffic alternately between two backend servers with full visibility through the `/balancer-manager` interface.

---

**Author:** Dennis Gachari  
**Date:** October 2025  
**Lab:** Apache Load Balancer Solution 102 – Ubuntu & RHEL Hybrid