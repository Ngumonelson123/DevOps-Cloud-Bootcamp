# Project 14 — CI/CD Pipeline with Jenkins, Ansible, Artifactory & SonarQube

## Stack
- **Jenkins** — CI/CD orchestration
- **Ansible** — Configuration management & deployments
- **Artifactory** — Binary artifact repository (JFrog OSS)
- **SonarQube** — Code quality & security analysis
- **Nginx** — Reverse proxy for all tools
- **PHP TODO app** — Sample application pushed through the pipeline

---

## Quick Start

### 1. Provision infrastructure
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

### 2. Populate inventory files from Terraform outputs
```bash
./scripts/update-inventory.sh
```

### 3. Test connectivity to all servers
```bash
./scripts/ping-all.sh
```

### 4. Configure CI environment (Jenkins + SonarQube + Artifactory + Nginx)
```bash
cd ansible
ansible-playbook playbooks/jenkins.yml    -i inventory/ci
ansible-playbook playbooks/sonarqube.yml  -i inventory/ci
ansible-playbook playbooks/artifactory.yml -i inventory/ci
ansible-playbook playbooks/nginx.yml      -i inventory/ci
```

### 5. Configure Dev environment (Tooling + TODO + DB + Nginx)
```bash
ansible-playbook playbooks/db.yml         -i inventory/dev
ansible-playbook playbooks/webservers.yml -i inventory/dev
ansible-playbook playbooks/nginx.yml      -i inventory/dev
```

### 6. Or run everything at once
```bash
ansible-playbook playbooks/site.yml -i inventory/ci
ansible-playbook playbooks/site.yml -i inventory/dev
```

---

## Access URLs (after DNS setup)

| Service        | URL                                    |
|---------------|----------------------------------------|
| Jenkins        | http://\<JENKINS-IP\>:8080             |
| SonarQube      | http://\<SONARQUBE-IP\>:9000           |
| Artifactory    | http://\<ARTIFACTORY-IP\>:8082         |
| TODO App       | http://\<TODO-IP\>                     |

---

## Project Structure

```
project-14/
├── terraform/          # AWS infrastructure (VPC, EC2, SGs, Key Pair)
│   ├── versions.tf
│   ├── variables.tf
│   ├── main.tf
│   └── outputs.tf
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/      # Per-environment host files
│   │   ├── ci
│   │   ├── dev
│   │   └── sit
│   ├── playbooks/      # Role-specific playbooks
│   ├── roles/          # Ansible roles
│   │   ├── common
│   │   ├── jenkins
│   │   ├── sonarqube
│   │   ├── artifactory
│   │   ├── nginx
│   │   ├── webserver
│   │   ├── todo
│   │   └── mysql
│   ├── deploy/
│   │   ├── Jenkinsfile              # Full CI/CD pipeline
│   │   ├── ansible.cfg              # Ansible config for Jenkins
│   │   └── sonar-project.properties
│   ├── env-vars/       # Per-environment variable overrides
│   └── group_vars/
└── scripts/
    ├── update-inventory.sh   # Auto-fill IPs after terraform apply
    └── ping-all.sh           # Verify Ansible connectivity
```

---

## Default Credentials (change after first login)

| Tool         | Username | Password  |
|-------------|----------|-----------|
| SonarQube    | admin    | admin     |
| Artifactory  | admin    | password  |
| Jenkins      | admin    | (printed by Ansible — check the play output) |

---

## Teardown
```bash
cd terraform
terraform destroy -auto-approve
```
