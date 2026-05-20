# StegHub Project 21 — Migration to the Cloud with Containerization
## Docker & Docker Compose | CI/CD with Jenkins

**Course:** StegHub DevOps/Cloud Engineering  
**Progress:** 70% Complete (77/109 Steps)

---

## Project Overview

Migrate the **Tooling PHP web app** from a VM-based setup into Docker containers, then automate build + push via a Jenkins CI pipeline. Extend the same pattern to the **PHP-Todo** app.

---

## Repository Structure

```
tooling-containerization/
├── tooling-app/
│   ├── Dockerfile              # PHP-Apache container for Tooling
│   ├── tooling.yaml            # Docker Compose (app + MySQL)
│   ├── Jenkinsfile             # CI pipeline: build → test → push → cleanup
│   ├── .env.example            # Copy to .env with your secrets
│   ├── html/
│   │   └── db_conn.php         # DB connection (reads env vars)
│   └── scripts/
│       ├── create_user.sql     # Creates MySQL user
│       └── tooling_db_schema.sql  # ← Clone from StegHub repo
├── php-todo/
│   ├── Dockerfile              # PHP-Apache container for PHP-Todo
│   └── Jenkinsfile             # CI pipeline with test + cleanup stages
├── jenkins/
│   └── JENKINS_SETUP.md        # Jenkins multi-branch pipeline setup
└── README.md                   # This file
```

---

## PART 1 — Containerize the Tooling App Locally

### Step 1: Pull MySQL Docker Image

```bash
docker pull mysql/mysql-server:latest
docker images ls
```

### Step 2: Deploy MySQL Container

```bash
# Set root password as env var (don't hardcode)
export MYSQL_PW=<root-secret-password>

docker run --network tooling_app_network \
  -h mysqlserverhost \
  --name=mysql-server \
  -e MYSQL_ROOT_PASSWORD=$MYSQL_PW \
  -d mysql/mysql-server:latest
```

Verify it's running:
```bash
docker ps -a
# STATUS should move from "health: starting" → "healthy"
```

### Step 3: Create a Non-Root MySQL User

```bash
# Create the SQL user script
cat > create_user.sql <<EOF
CREATE USER '<user>'@'%' IDENTIFIED BY '<client-secret-password>';
GRANT ALL PRIVILEGES ON *.* TO '<user>'@'%';
FLUSH PRIVILEGES;
EOF

# Run against the MySQL container
docker exec -i mysql-server mysql -uroot -p$MYSQL_PW < ./create_user.sql
```

> ⚠️ Ignore this warning — it's safe:  
> `mysql: [Warning] Using a password on the command line interface can be insecure.`

### Step 4: Connect to MySQL (Two Approaches)

**Approach 1 — Direct exec into container:**
```bash
docker exec -it mysql-server mysql -uroot -p
# Then change root password for security
```

**Approach 2 — Second container as MySQL client (recommended):**
```bash
# Create a dedicated Docker network first
docker network create --subnet=172.18.0.0/24 tooling_app_network

# Connect via client container (auto-removes on exit)
docker run --network tooling_app_network --name mysql-client -it --rm \
  mysql mysql -h mysqlserverhost -u <user-from-sql-script> -p
```

### Step 5: Prepare the Database Schema

```bash
# Clone the Tooling app repo
git clone https://github.com/StegTechHub/tooling-02.git

# Export path to SQL schema file
export tooling_db_schema=<path-to-cloned-repo>/html/tooling_db_schema.sql

# Load schema into MySQL container
docker exec -i mysql-server mysql -uroot -p$MYSQL_PW < $tooling_db_schema
```

### Step 6: Update db_conn.php

Edit `tooling-app/html/db_conn.php`:
```php
$servername = "mysqlserverhost";
$username   = "<user>";
$password   = "<client-secret-password>";
$dbname     = "toolingdb";
```

### Step 7: Build and Run the Tooling Container

```bash
cd tooling-app/

# Build Docker image
docker build -t tooling:0.0.1 .

# Run container on the same network as MySQL
docker run --network tooling_app_network \
  -p 8085:80 \
  -it tooling:0.0.1
```

Open browser → `http://localhost:8085`  
Login: `test@mail.com` / `12345`

> ⚠️ If you see AH00558 ServerName warning — already fixed in the Dockerfile via:
> ```
> RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
> ```

---

## PART 2 — Push to Docker Hub

```bash
# Tag the image
docker tag tooling:0.0.1 <your-dockerhub-username>/tooling:0.0.1

# Login
docker login

# Push
docker push <your-dockerhub-username>/tooling:0.0.1
```

---

## PART 3 — Jenkins CI Multi-Branch Pipeline

See [`jenkins/JENKINS_SETUP.md`](jenkins/JENKINS_SETUP.md) for full Jenkins configuration.

### What the Jenkinsfile does:

| Stage | Action |
|-------|--------|
| **Checkout** | Pulls the correct branch |
| **Build** | `docker build` with branch-prefixed tag (e.g. `feature-0.0.1`) |
| **Test** | Runs container, curls `http` endpoint, asserts HTTP **200** |
| **Push** | `docker push` to Docker Hub |
| **Cleanup** | `docker rmi` removes images from Jenkins server |

---

## PRACTICE TASK 1 — PHP-Todo App

```bash
# Clone the php-todo repo
git clone <php-todo-repo-url>

# Navigate into the directory
cd php-todo/

# Build
docker build -t php-todo:0.0.1 .

# Run with database + app
docker run -p 8086:80 php-todo:0.0.1
```

Use `php-todo/Jenkinsfile` — identical pipeline structure to tooling.

---

## PART 1 (Docker Compose) — Tooling + MySQL Together

```bash
cd tooling-app/

# Copy and edit .env
cp .env.example .env
nano .env   # set MYSQL_USER and MYSQL_PASSWORD

# Start both services (detached)
docker-compose -f tooling.yaml up -d

# Verify running
docker compose ls
docker ps
```

Expected output from `docker compose ls`:
```
NAME        STATUS     CONFIG FILES
tooling     running    /path/to/tooling.yaml
```

---

## Practice Task 2 — Test Stage in Jenkinsfile

Already implemented in both Jenkinsfiles. The test stage:

1. Runs the newly built container on a spare port (8090/8091)
2. Waits 5 seconds for Apache to start
3. Curls the `http` endpoint and captures the HTTP status code
4. Fails the pipeline if status ≠ `200`
5. Stops and removes the test container

```groovy
stage('Test - HTTP 200 Check') {
    steps {
        sh """
            docker run -d --name tooling_test -p 8090:80 ${FULL_IMAGE}
            sleep 5
            STATUS=\$(curl -o /dev/null -s -w "%{http_code}" http://localhost:8090)
            docker stop tooling_test && docker rm tooling_test
            if [ "\$STATUS" != "200" ]; then exit 1; fi
        """
    }
}
```

---

## Key Docker Commands Reference

```bash
# Network
docker network create --subnet=172.18.0.0/24 tooling_app_network
docker network ls

# Images
docker images ls
docker build -t <name>:<tag> .
docker rmi <image>

# Containers
docker ps -a
docker run -d --name <name> -p <host>:<container> <image>
docker exec -it <container> bash
docker stop <container> && docker rm <container>

# Compose
docker-compose -f tooling.yaml up -d
docker compose ls
docker-compose -f tooling.yaml down

# Registry
docker login
docker push <username>/<image>:<tag>
docker pull <username>/<image>:<tag>
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `AH00558: ServerName not set` | Already fixed in Dockerfile — `echo "ServerName localhost"` |
| MySQL container `health: starting` | Wait ~30s; check `docker ps` for `healthy` |
| Jenkins `docker: permission denied` | `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins` |
| Port already in use | `sudo lsof -i :<port>` then kill the process |
| `docker compose ls` empty | Ensure compose started with `-f tooling.yaml` flag |

---

## Resources

- [Docker Compose File Reference v3](https://docs.docker.com/compose/compose-file/compose-file-v3/)
- [Balena Supervisor Docker Compose Docs](https://www.balena.io/docs/reference/supervisor/docker-compose/)
- [Docker Best Practices for Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [StegHub Tooling Repo](https://github.com/StegTechHub/tooling-02.git)
