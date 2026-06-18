# Migration to the Cloud with Containerization
### Docker & Docker Compose — StegHub DevOps Project 101

> Migrating the **Tooling Web Application** (PHP + MySQL) from VM-based deployment to a fully containerized setup using Docker, Docker Compose, and a Jenkins CI/CD pipeline.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Project Structure](#project-structure)
4. [Part 1 — Manual Setup (Docker CLI)](#part-1--manual-setup-docker-cli)
5. [Part 2 — Push Image to Docker Hub](#part-2--push-image-to-docker-hub)
6. [Part 3 — CI/CD with Jenkins](#part-3--cicd-with-jenkins)
7. [Part 4 — Docker Compose](#part-4--docker-compose)
8. [Docker Compose Field Reference](#docker-compose-field-reference)
9. [Troubleshooting](#troubleshooting)

---

## Project Overview

The goal is to containerize the existing Tooling PHP application so it can run consistently across any environment using Docker. The project is broken into four parts:

| Part | What you build |
|------|----------------|
| 1 | Run MySQL + Tooling app containers manually on a shared Docker network |
| 2 | Tag the image and push it to Docker Hub |
| 3 | Automate build → test → push → clean with a Jenkins pipeline |
| 4 | Replace all `docker run` commands with a single `docker compose up` |

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Docker Engine | 24+ | [docs.docker.com/engine/install](https://docs.docker.com/engine/install/) |
| Docker Compose | v2 (plugin) | Included with Docker Desktop / `docker-compose-plugin` |
| Jenkins | LTS | [jenkins.io/download](https://www.jenkins.io/download/) |
| Git | Any | `sudo apt install git` |

---

## Project Structure

```
tooling-containerization/
│
├── tooling-app/                  # The PHP Tooling application
│   ├── Dockerfile                # Container build instructions
│   └── html/
│       ├── db_conn.php           # Database connection config (update before running)
│       └── tooling_db_schema.sql # (Download from StegHub repo — see Part 1 Step 5)
│
├── mysql-scripts/
│   └── create_user.sql           # Creates a dedicated MySQL app user
│
├── compose/
│   └── tooling.yaml              # Docker Compose definition
│
├── jenkins/
│   └── Jenkinsfile               # CI/CD pipeline (Build → Test → Push → Clean)
│
├── bootstrap.sh                  # One-shot manual setup script (without Compose)
├── .env.example                  # Template for environment variables
├── .gitignore
└── README.md
```

---

## Part 1 — Manual Setup (Docker CLI)

### Step 1: Install Docker

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# Run Docker without sudo
sudo usermod -aG docker $USER && newgrp docker
```

### Step 2: Create a Docker Network

```bash
docker network create --subnet=172.18.0.0/24 tooling_app_network
```

> Creating a named network with a known subnet lets both containers communicate using hostnames instead of IP addresses.

### Step 3: Run MySQL Container

```bash
export MYSQL_PW=<your-root-secret-password>

docker run \
  --network tooling_app_network \
  -h mysqlserverhost \
  --name=mysql-server \
  -e MYSQL_ROOT_PASSWORD=$MYSQL_PW \
  -d mysql/mysql-server:latest

# Verify it started
docker ps -a
```

### Step 4: Create a Dedicated DB User

```bash
# Run the SQL script against the running container
docker exec -i mysql-server mysql -uroot -p$MYSQL_PW < ./mysql-scripts/create_user.sql
```

Edit `mysql-scripts/create_user.sql` first — replace `<your-db-user>` and `<your-db-password>` with real values.

To verify the user was created, connect via a second MySQL client container:

```bash
docker run --network tooling_app_network --name mysql-client \
  -it --rm mysql \
  mysql -h mysqlserverhost -u <your-db-user> -p
```

### Step 5: Import the Database Schema

```bash
# Clone the StegHub tooling repo to get the SQL schema
git clone https://github.com/StegTechHub/tooling-02.git

# Copy the schema into the project
cp tooling-02/html/tooling_db_schema.sql tooling-app/html/

# Import schema into MySQL container
export tooling_db_schema=./tooling-app/html/tooling_db_schema.sql
docker exec -i mysql-server mysql -uroot -p$MYSQL_PW < $tooling_db_schema
```

Then update `tooling-app/html/db_conn.php`:

```php
$servername = "mysqlserverhost";
$username   = "<your-db-user>";
$password   = "<your-db-password>";
$dbname     = "toolingdb";
```

### Step 6: Build and Run the Tooling App

```bash
# Build the Docker image
docker build -t tooling:0.0.1 ./tooling-app

# Run the container on the shared network
docker run \
  --network tooling_app_network \
  -p 8085:80 \
  -it \
  tooling:0.0.1
```

Open your browser: **http://localhost:8085**

Default credentials: `test@mail.com` / `12345`

---

## Part 2 — Push Image to Docker Hub

```bash
# Login
docker login

# Tag
docker tag tooling:0.0.1 <your-dockerhub-username>/tooling:0.0.1

# Push
docker push <your-dockerhub-username>/tooling:0.0.1
```

---

## Part 3 — CI/CD with Jenkins

### Install Jenkins on EC2

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update && sudo apt install -y jenkins

# Give Jenkins access to Docker
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Configure Jenkins

1. Open `http://<your-ec2-ip>:8080`
2. **Credentials** → Add `dockerhub-credentials` (Username/Password kind)
3. **New Item** → **Multibranch Pipeline** → point to your GitHub repo
4. Jenkins will auto-detect branches with a `Jenkinsfile`

### Jenkinsfile Pipeline Stages

| Stage | What it does |
|-------|-------------|
| **Checkout** | Pulls the branch from GitHub |
| **Build** | `docker build` — tags image as `<image>:<branch-name>` |
| **Test** | Spins up a test container, `curl`s the HTTP endpoint, expects `200` |
| **Push** | Authenticates to Docker Hub and pushes the tagged image |
| **Clean Up** | Removes the local image from the Jenkins server |

Images are tagged with the branch name, e.g. `feature-0.1`, `master`.

---

## Part 4 — Docker Compose

Instead of running 5+ `docker run` commands, bring everything up with one command.

```bash
# Copy and fill in your env file
cp .env.example .env
# Edit .env with your actual MYSQL_USER and MYSQL_PASSWORD

# Start all services in the background
docker-compose -f compose/tooling.yaml up -d

# Check running services
docker compose ls

# Tail logs
docker-compose -f compose/tooling.yaml logs -f

# Tear down
docker-compose -f compose/tooling.yaml down
```

Open **http://localhost:5000**

---

## Docker Compose Field Reference

| Field | Description |
|-------|-------------|
| `version` | Docker Compose file format version (`3.9` used here). Verify with `docker-compose --version` |
| `services` | Defines each container as a named service. All config under a service applies only to that container |
| `build` | Path to the `Dockerfile`. Docker Compose builds the image locally on `up` |
| `ports` | Maps `host:container` ports. Allows accessing the container from your machine |
| `volumes` | Mounts paths or named volumes. Persists data across container restarts |
| `links` | Legacy service-level networking. Replaced by `depends_on` + shared network in v3 |
| `depends_on` | Controls startup order. With `condition: service_healthy`, waits for the health check |
| `environment` | Sets environment variables inside the container |
| `healthcheck` | Docker polls this command to determine when the container is truly ready |
| `restart` | Restart policy (`always`, `unless-stopped`, `on-failure`) |
| `image` | Pre-built image to pull from Docker Hub instead of building locally |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `AH00558: apache2: Could not reliably determine the server's fully qualified domain name` | Add `RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf` to your Dockerfile |
| Port already in use | Change host port mapping, e.g. `8086:80` |
| MySQL `health: starting` | Wait ~30s for MySQL to reach `healthy` status before connecting |
| Jenkins `permission denied` on `docker` | Run `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins` |
| `docker compose ls` shows nothing | Make sure you started with `-f compose/tooling.yaml up -d` |
| Image push fails | Verify `dockerhub-credentials` ID matches exactly in both Jenkins config and Jenkinsfile |

---

## References

- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Balena Compose Reference](https://www.balena.io/docs/reference/supervisor/docker-compose/)
- [StegHub Tooling Repo](https://github.com/StegTechHub/tooling-02)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)

---

*StegHub DevOps/Cloud Engineering Track — Docker & Docker Compose 101*
