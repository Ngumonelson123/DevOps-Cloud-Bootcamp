# Ansible Configuration Management – UAT Deployment

## 📌 Project Overview

This project automates the deployment and configuration of UAT webservers using Ansible.

Infrastructure includes:
- 1 Ansible Control Node (Ubuntu 24.04)
- 2 UAT Web Servers (RHEL 8)
- Apache Web Server
- Tooling application deployment

---

## 🏗 Architecture

Laptop
  ↓ SSH
Control Node (Ubuntu)
  ↓ Ansible
UAT Webservers (RHEL)

---

## 📂 Project Structure

- ansible.cfg → Project configuration
- inventory/ → Host definitions
- playbooks/ → Entry playbooks
- static-assignments/ → Playbook imports
- roles/ → Reusable configurations

---

## 🚀 How To Run

From project root:

```bash
ansible-playbook -i inventory/uat.yml playbooks/site.yml