# Ansible Configuration Management

This repository contains Ansible configuration files for automating server management and deployment tasks. The project demonstrates Infrastructure as Code (IaC) principles using Ansible playbooks and inventory management.

## Project Structures

```
ansible-config-mgt/
├── inventory/
│   └── dev.yml              # Development environment inventory
├── playbooks/
│   └── common.yml           # Common server configuration playbook
├── screenshots/             # Project documentation screenshots
└── README.md               # This file
```

## Features

- **Automated Server Configuration**: Configures web servers with essential tools and directories
- **Package Management**: Installs and manages software packages (Wireshark)
- **Directory Management**: Creates standardized directory structures
- **File Management**: Deploys configuration files and documentation

## Inventory Configuration

The `inventory/dev.yml` file defines the target servers:
- **Web Servers**: Ubuntu-based servers accessible via SSH
- **Authentication**: Uses SSH private key authentication
- **Target IP**: 172.31.27.104

## Playbook Details

The `playbooks/common.yml` playbook performs the following tasks:
1. Updates the apt package cache
2. Installs Wireshark network protocol analyzer
3. Creates a `/opt/tools` directory with proper permissions
4. Deploys a README file indicating automated management

## Usage

```bash
# Run the playbook against development environment
ansible-playbook -i inventory/dev.yml playbooks/common.yml

# Check connectivity to all hosts
ansible -i inventory/dev.yml all -m ping
```

## Prerequisites

- Ansible installed on the control machine
- SSH access to target servers
- Private key file (`steghub.pem`) configured
- Ubuntu target servers with sudo privileges

## Project Screenshots

### Initial Setup and Configuration

![Screenshot 1](screenshots/Screenshot%20from%202025-11-26%2023-08-00.png)

![Screenshot 2](screenshots/Screenshot%20from%202025-11-26%2023-26-28.png)

![Screenshot 3](screenshots/Screenshot%20from%202025-11-26%2023-27-10.png)

![Screenshot 4](screenshots/Screenshot%20from%202025-11-26%2023-29-03.png)

![Screenshot 5](screenshots/Screenshot%20from%202025-11-26%2023-40-46.png)

![Screenshot 6](screenshots/Screenshot%20from%202025-11-26%2023-41-37.png)

### Execution and Results

![Screenshot 7](screenshots/Screenshot%20from%202025-11-27%2000-03-15.png)

![Screenshot 8](screenshots/Screenshot%20from%202025-11-27%2000-03-24.png)

![Screenshot 9](screenshots/Screenshot%20from%202025-11-27%2000-04-02.png)

![Screenshot 10](screenshots/Screenshot%20from%202025-11-27%2000-26-07.png)

![Screenshot 11](screenshots/Screenshot%20from%202025-11-27%2000-27-31.png)

![Screenshot 12](screenshots/Screenshot%20from%202025-11-27%2000-27-35.png)

![Screenshot 13](screenshots/Screenshot%20from%202025-11-27%2000-29-29.png)

![Screenshot 14](screenshots/Screenshot%20from%202025-11-27%2001-03-44.png)

## Security Considerations

- SSH private keys should be properly secured and not committed to version control
- Use Ansible Vault for sensitive data encryption
- Implement proper user privilege management
- Regular security updates and patches

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the playbooks in a development environment
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This configuration is designed for development and testing environments. Ensure proper security measures are in place before using in production.