# Ansible Community Roles

This project demonstrates the use of Ansible community roles for infrastructure automation and configuration management across multiple environments.

## Project Structure

```
ansible-community-roles/
├── playbooks/          # Main playbooks
├── roles/              # Ansible roles (common, mysql, nginx, webserver)
├── static-assignments/ # Static playbook assignments
├── dynamic-assignments/# Dynamic playbook assignments
├── inventory/          # Environment-specific inventory files
├── env-vars/           # Environment variables
└── screenshots/        # Project documentation screenshots
```

## Roles

### Community Roles
- **mysql** - MySQL database server configuration
- **nginx** - Nginx web server setup
- **webserver** - Apache/web server configuration
- **common** - Common tasks across all servers

## Environments

The project supports multiple environments:
- **dev** - Development environment
- **uat** - User Acceptance Testing
- **stage** - Staging environment
- **prod** - Production environment

## Configuration

The `ansible.cfg` file is configured with:
- Default inventory: `inventory/dev`
- Roles path: `./roles`
- Host key checking: Disabled

## Usage

### Running Playbooks

```bash
# Run the main site playbook
ansible-playbook -i inventory/dev playbooks/site.yml

# Run for specific environment
ansible-playbook -i inventory/prod playbooks/site.yml
```

### Main Playbook Structure

The `site.yml` playbook imports:
1. Common configurations
2. Dynamic environment variables
3. Webserver configurations
4. Load balancer configurations

## Screenshots

### Project Setup
![Initial Setup](screenshots/Screenshot%20from%202026-03-04%2000-35-59.png)

### Configuration
![Configuration](screenshots/Screenshot%20from%202026-03-04%2000-36-14.png)

### Role Implementation
![Role Implementation](screenshots/Screenshot%20from%202026-03-04%2000-36-33.png)

### Inventory Setup
![Inventory Setup](screenshots/Screenshot%20from%202026-03-04%2000-36-44.png)

### Playbook Execution
![Playbook Execution](screenshots/Screenshot%20from%202026-03-04%2000-36-58.png)

### Testing
![Testing](screenshots/Screenshot%20from%202026-03-04%2000-42-13.png)

### Deployment Results
![Deployment Results](screenshots/Screenshot%20from%202026-03-04%2000-44-24.png)

### Final Verification
![Final Verification](screenshots/Screenshot%20from%202026-03-04%2000-44-41.png)

## Requirements

- Ansible 2.9+
- Python 3.x
- SSH access to target hosts

## Getting Started

1. Clone the repository
2. Update inventory files with your server details
3. Configure environment variables in `env-vars/`
4. Run the playbook for your target environment

## License

This project is for educational purposes as part of the DevOps Cloud Bootcamp.
