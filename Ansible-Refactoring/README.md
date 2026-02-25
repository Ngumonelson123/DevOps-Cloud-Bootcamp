# Ansible Refactoring & Static Assignments

This project demonstrates the refactoring of Ansible code using imports, roles, and static assignments to improve code organization and reusability.

## Project Overview

This Ansible project automates the configuration and deployment of UAT (User Acceptance Testing) webservers using a modular, role-based structure. The refactored architecture promotes code reusability and maintainability.

## Architecture

- **Playbooks**: Main orchestration files
- **Roles**: Reusable automation components
- **Static Assignments**: Modular playbook imports
- **Inventory**: Environment-specific host definitions

---

## Setup & Configuration

### 1. Project Structure Setup

![Project Structure](project-screenshots/Screenshot%202026-02-25%20142306.png)

Initial project directory structure showing the organized layout with roles, playbooks, inventory, and static assignments folders.

---

### 2. Creating the Webserver Role

![Webserver Role Creation](project-screenshots/Screenshot%202026-02-25%20142342.png)

Creating the webserver role using `ansible-galaxy init` command to generate the standard role directory structure.

---

### 3. Role Directory Structure

![Role Structure](project-screenshots/Screenshot%202026-02-25%20142406.png)

The generated webserver role structure containing tasks, handlers, defaults, vars, templates, and meta directories.

---

### 4. Configuring Role Tasks

![Role Tasks Configuration](project-screenshots/Screenshot%202026-02-25%20142424.png)

Defining the main tasks for the webserver role including Apache installation, Git setup, and repository cloning.

---

### 5. Inventory Configuration

![Inventory Setup](project-screenshots/Screenshot%202026-02-25%20142450.png)

Configuring the UAT inventory file with target webserver hosts and connection parameters.

---

### 6. Static Assignment Creation

![Static Assignment](project-screenshots/Screenshot%202026-02-25%20143453.png)

Creating the static assignment file `uat-webservers.yml` to apply the webserver role to UAT hosts.

---

### 7. Main Playbook Configuration

![Main Playbook](project-screenshots/Screenshot%202026-02-25%20143515.png)

Configuring the main `site.yml` playbook to import static assignments for modular execution.

---

### 8. Ansible Configuration File

![Ansible Config](project-screenshots/Screenshot%202026-02-25%20143641.png)

Setting up `ansible.cfg` with inventory path, roles path, and other Ansible configurations.

---

### 9. Running the Playbook

![Playbook Execution](project-screenshots/Screenshot%202026-02-25%20143916.png)

Executing the Ansible playbook against the UAT webservers inventory.

---

### 10. Task Execution Progress

![Task Progress](project-screenshots/Screenshot%202026-02-25%20144900.png)

Monitoring the execution of tasks including Apache installation, Git installation, and repository cloning.

---

### 11. Playbook Completion

![Execution Complete](project-screenshots/Screenshot%202026-02-25%20150404.png)

Successful completion of the playbook run showing all tasks executed without errors.

---

### 12. Verifying Apache Installation

![Apache Verification](project-screenshots/Screenshot%202026-02-25%20150603.png)

Verifying that Apache is installed and running on the target webservers.

---

### 13. Checking Deployed Files

![Deployed Files](project-screenshots/Screenshot%202026-02-25%20151736.png)

Inspecting the deployed application files in `/var/www/html` directory on the webserver.

---

### 14. Testing Web Application

![Web Application Test](project-screenshots/Screenshot%202026-02-25%20152242.png)

Accessing the deployed web application through a browser to verify successful deployment.

---

### 15. Application Homepage

![Application Homepage](project-screenshots/Screenshot%202026-02-25%20153146.png)

The tooling application homepage displaying correctly, confirming successful deployment.

---

### 16. Application Functionality

![Application Features](project-screenshots/Screenshot%202026-02-25%20153642.png)

Testing the application's functionality and user interface elements.

---

### 17. Final Verification

![Final Check](project-screenshots/Screenshot%202026-02-25%20153717.png)

Final verification showing the complete working application deployed via Ansible automation.

---

## Project Structure

```
Ansible-Refactoring/
├── ansible.cfg                 # Ansible configuration
├── inventory/
│   └── uat.yml                # UAT environment inventory
├── playbooks/
│   └── site.yml               # Main playbook
├── static-assignments/
│   ├── common.yml             # Common configurations
│   └── uat-webserver.yml      # UAT webserver assignment
└── roles/
    └── webserver/             # Webserver role
        ├── tasks/
        │   └── main.yml       # Role tasks
        ├── handlers/
        │   └── main.yml       # Event handlers
        ├── defaults/
        │   └── main.yml       # Default variables
        └── vars/
            └── main.yml       # Role variables
```

## Key Components

### Webserver Role Tasks

The webserver role performs the following tasks:
- Installs Apache HTTP Server
- Installs Git
- Clones the tooling repository
- Disables default RHEL welcome page
- Restarts and enables Apache service

### Static Assignments

- **common.yml**: Applies common configurations across all servers
- **uat-webserver.yml**: Configures UAT webservers using the webserver role

### Inventory

UAT inventory defines two webservers:
- 172.31.24.208
- 172.31.20.105

Both use `ec2-user` for SSH connections.

## Usage

### Running the Playbook

```bash
ansible-playbook -i inventory/uat.yml playbooks/site.yml
```

### Testing Specific Roles

```bash
ansible-playbook -i inventory/uat.yml static-assignments/uat-webserver.yml
```

## Benefits of Refactoring

1. **Modularity**: Code is organized into reusable roles
2. **Maintainability**: Easier to update and manage configurations
3. **Scalability**: Simple to add new roles and assignments
4. **Reusability**: Roles can be shared across multiple projects
5. **Clarity**: Clear separation of concerns and responsibilities

## Requirements

- Ansible 2.9+
- SSH access to target servers
- Python 3.6+ on target servers
- RHEL/CentOS based systems

## Author

Nelson Ngumo

## License

This project is part of the StegHub DevOps Cloud Bootcamp.
