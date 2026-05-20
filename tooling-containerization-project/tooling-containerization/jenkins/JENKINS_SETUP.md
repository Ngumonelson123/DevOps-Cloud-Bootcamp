# Jenkins Multi-Branch Pipeline Setup
# StegHub Project 21 - Containerization with Docker & Docker Compose

## Prerequisites on Jenkins Server

```bash
# Install Docker on Jenkins EC2 instance
sudo apt-get update
sudo apt-get install -y docker.io curl

# Add jenkins user to docker group (no sudo needed)
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Verify
docker --version
curl --version
```

## Add Docker Hub Credentials in Jenkins

1. Go to **Manage Jenkins → Credentials → Global → Add Credentials**
2. Kind: **Username with password**
3. ID: `dockerhub-credentials`  ← must match Jenkinsfile exactly
4. Username: your Docker Hub username
5. Password: your Docker Hub password or access token

## Create Multi-Branch Pipeline for Tooling App

1. **New Item** → Name: `tooling-app` → **Multibranch Pipeline**
2. Branch Sources → **Git**
3. Repository URL: `https://github.com/<your-username>/tooling-02.git`
4. Credentials: add your GitHub credentials if private repo
5. Build Configuration → by Jenkinsfile
6. Script Path: `tooling-app/Jenkinsfile`
7. Save → Jenkins scans branches and creates pipelines automatically

## Create Multi-Branch Pipeline for PHP-Todo

Same steps, but:
- Name: `php-todo`
- Repository URL: your php-todo repo
- Script Path: `php-todo/Jenkinsfile`

## Branch Naming Convention for Image Tags

| Branch       | Image Tag Example        |
|--------------|--------------------------|
| `main`       | `main-42`                |
| `feature`    | `feature-0.0.1` → `feature-7` |
| `develop`    | `develop-15`             |

The Jenkinsfile uses: `${BRANCH_NAME.replace('/', '-')}-${BUILD_NUMBER}`

## Verify Pushed Images

```bash
# Check Docker Hub via CLI
docker pull <your-username>/tooling:main-1
docker pull <your-username>/php-todo:feature-1
```

Or visit: https://hub.docker.com/u/<your-username>
