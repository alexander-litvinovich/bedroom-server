# Ansible Conversion Plan for Bedroom Server

## Overview

This document outlines the strategy for converting the existing bash scripts in the `bedroom-server` repository to Ansible playbooks, roles, and collections. The conversion will maintain the same functionality while providing better infrastructure-as-code practices, idempotency, and maintainability.

## Current State Analysis

### Existing Structure

```
bedroom-server/
├── preflight.sh                    # Main orchestration script
├── install-scripts/                # Application installation scripts
│   ├── docker.sh
│   ├── immich.sh
│   ├── n8n.sh
│   ├── nginx-proxy-manager.sh
│   ├── ohmyzsh.sh
│   ├── pi-hole.sh
│   └── xrdp.sh
├── assets/                         # Configuration files and templates
│   ├── dynamic-motd.sh
│   ├── immich.example.env
│   ├── n8n_docker-compose.yml
│   ├── nginx-proxy-manager.docker-compose.yaml
│   ├── pi-hole.docker-compose.yaml
│   ├── ssh_config
│   └── xrdp_* (multiple files)
├── utils/                          # Utility functions
│   ├── command.sh
│   ├── paths.sh
│   └── print.sh
├── motd.sh                         # MOTD configuration
├── power-management.sh             # Power management setup
├── ssh.sh                          # SSH configuration
└── create-ssh-key.sh               # SSH key generation

```

### Current Applications and Services

- **Docker** - Container runtime
- **Immich** - Photo management (Docker Compose)
- **n8n** - Workflow automation (Docker Compose)
- **NGINX Proxy Manager** - Reverse proxy (Docker Compose)
- **Pi-hole** - DNS sinkhole (Docker Compose)
- **XRDP** - Remote desktop server
- **Oh My Zsh** - Shell framework
- **Tailscale** - VPN mesh network
- **Ollama** - LLM runtime
- **Lazydocker** - Docker management UI

## Target Ansible Structure

### Proposed Directory Structure

```
ansible/
├── inventory/
│   ├── hosts.yml                   # Inventory file
│   └── group_vars/
│       └── all.yml                 # Global variables
├── playbooks/
│   ├── site.yml                    # Main playbook (replaces preflight.sh)
│   ├── setup-basic.yml             # Basic system setup
│   ├── setup-docker.yml            # Docker installation
│   ├── setup-services.yml          # All containerized services
│   └── setup-desktop.yml           # Desktop environment (XRDP, etc.)
├── roles/
│   ├── common/                     # Common system setup
│   ├── docker/                     # Docker installation and configuration
│   ├── immich/                     # Immich photo management
│   ├── n8n/                        # n8n workflow automation
│   ├── nginx-proxy-manager/        # NGINX Proxy Manager
│   ├── pi-hole/                    # Pi-hole DNS sinkhole
│   ├── xrdp/                       # XRDP remote desktop
│   ├── ssh/                        # SSH configuration
│   ├── motd/                       # MOTD setup
│   ├── power-management/           # Power management settings
│   └── shell/                      # Shell configuration (zsh, oh-my-zsh)
├── collections/
│   └── requirements.yml            # External collections
├── group_vars/
│   └── all.yml                     # Global variables
├── host_vars/
│   └── bedroom-server.yml          # Host-specific variables
├── templates/                      # Jinja2 templates
├── files/                          # Static files
└── ansible.cfg                     # Ansible configuration

```

## Conversion Strategy

### Phase 1: Foundation Setup

1. **Create Ansible directory structure**
2. **Convert utility functions to Ansible modules/plugins**
3. **Create inventory and variable files**
4. **Set up basic common role**

### Phase 2: Core System Setup

1. **Convert `preflight.sh` to main playbook**
2. **Create common role** (replaces `utils/` functionality)
3. **Convert system configuration scripts**:
   - `ssh.sh` → `ssh` role
   - `motd.sh` → `motd` role
   - `power-management.sh` → `power-management` role

### Phase 3: Application Roles

1. **Convert installation scripts to roles**:
   - `docker.sh` → `docker` role
   - `immich.sh` → `immich` role
   - `n8n.sh` → `n8n` role
   - `nginx-proxy-manager.sh` → `nginx-proxy-manager` role
   - `pi-hole.sh` → `pi-hole` role
   - `xrdp.sh` → `xrdp` role
   - `ohmyzsh.sh` → `shell` role

### Phase 4: Templates and Files

1. **Convert assets to templates and files**
2. **Create dynamic configuration using Jinja2**
3. **Handle secrets and sensitive data with Ansible Vault**

## Role Specifications

### Common Role

**Purpose**: Base system configuration and utilities
**Tasks**:

- Update package cache
- Install basic packages (toilet, boxes, mc, zsh)
- Configure timezone
- Set up basic security settings
- Create necessary directories

**Variables**:

- `base_packages`: List of packages to install
- `timezone`: System timezone
- `admin_user`: Primary admin user

### Docker Role

**Purpose**: Install and configure Docker
**Tasks**:

- Add Docker repository
- Install Docker and Docker Compose
- Configure Docker daemon
- Add user to docker group
- Enable Docker service

**Variables**:

- `docker_users`: List of users to add to docker group
- `docker_compose_version`: Docker Compose version

### Application Roles (Immich, n8n, Pi-hole, etc.)

**Common Structure**:

- Install dependencies
- Create application directories
- Copy Docker Compose files
- Configure environment variables
- Start services
- Configure firewall rules

**Variables**:

- Service-specific configuration
- Database passwords
- Port mappings
- Volume mounts

### SSH Role

**Purpose**: Configure SSH server and client
**Tasks**:

- Install OpenSSH server
- Configure SSH daemon
- Set up SSH client configuration
- Configure firewall rules
- Set up keychain

**Variables**:

- `ssh_port`: SSH port (default: 22)
- `ssh_allow_users`: List of users allowed to SSH
- `ssh_config_template`: SSH client configuration template

### XRDP Role

**Purpose**: Configure remote desktop access
**Tasks**:

- Install XRDP and dependencies
- Create XRDP user
- Configure Polkit rules
- Set up dummy video driver
- Configure session management

**Variables**:

- `xrdp_user`: Remote desktop user
- `xrdp_port`: XRDP port (default: 3389)

## Variable Management

### Global Variables (`group_vars/all.yml`)

```yaml
# System Configuration
timezone: "Europe/Helsinki"
admin_user: "alex"

# Network Configuration
server_ip: "{{ ansible_default_ipv4.address }}"

# Service Configuration
services:
  immich:
    port: 2283
    db_password: "{{ lookup('env', 'IMMICH_PG_PASS') | default('postgres') }}"
  pi_hole:
    port: 8080
    password: "{{ lookup('env', 'PIHOLE_PASS') | default('piholepass') }}"
  n8n:
    port: 5678
    data_dir: "{{ lookup('env', 'N8N_DATA_DIR') | default('/opt/n8n') }}"
    encryption_key: "{{ lookup('env', 'N8N_ENCRYPTION_KEY') | default('changeme') }}"
    jwt_secret: "{{ lookup('env', 'N8N_JWT_SECRET') | default('changeme') }}"

# Security
ssh_port: 22
xrdp_user: "{{ lookup('env', 'XRDP_USER') | default('rdpuser') }}"
git_email: "{{ lookup('env', 'GIT_EMAIL') | default('user@example.com') }}"
```

### Host-Specific Variables (`host_vars/bedroom-server.yml`)

```yaml
# Hardware-specific configuration
server_model: "HP Prodesk 405 G4 Mini"
storage_mount: "/media/storage"

# Network configuration
tailscale_key: "{{ lookup('env', 'TAILSCALE_KEY') | default('') }}"
```

### Vault Variables

To maintain consistency with your current workflow, use environment variables for sensitive data. This approach keeps your existing `.env` file pattern while integrating with Ansible:

**Directory structure:**

```
ansible/
├── group_vars/
│   └── all.yml                   # Variables referencing environment
├── host_vars/
│   └── bedroom-server.yml        # Host-specific variables
└── .env                          # Environment variables (add to .gitignore)
```

**Environment file (`.env`):**

```bash
# Database passwords
IMMICH_PG_PASS=your-secure-db-password
PIHOLE_PASS=your-secure-pihole-password

# Service secrets
N8N_ENCRYPTION_KEY=your-32-char-encryption-key
N8N_JWT_SECRET=your-jwt-secret-key

# User configuration
GIT_EMAIL=your.email@example.com
XRDP_USER=rdpuser

# Network services
TAILSCALE_KEY=your-tailscale-auth-key
N8N_DATA_DIR=/media/storage/n8n
```

**Variable references in Ansible:**

```yaml
# In group_vars/all.yml
services:
  immich:
    db_password: "{{ lookup('env', 'IMMICH_PG_PASS') | default('postgres') }}"
  pi_hole:
    password: "{{ lookup('env', 'PIHOLE_PASS') | default('piholepass') }}"
  n8n:
    encryption_key: "{{ lookup('env', 'N8N_ENCRYPTION_KEY') | default('changeme') }}"
    jwt_secret: "{{ lookup('env', 'N8N_JWT_SECRET') | default('changeme') }}"
    data_dir: "{{ lookup('env', 'N8N_DATA_DIR') | default('/opt/n8n') }}"

git_email: "{{ lookup('env', 'GIT_EMAIL') | default('user@example.com') }}"
xrdp_user: "{{ lookup('env', 'XRDP_USER') | default('rdpuser') }}"
tailscale_key: "{{ lookup('env', 'TAILSCALE_KEY') | default('') }}"
```

**Usage:**

```bash
# Source environment variables before running playbooks
source .env

# Run playbook with environment variables loaded
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

**Benefits:**

- **Familiar workflow**: Keeps your existing `.env` file approach
- **No additional complexity**: No need to learn vault commands
- **Flexible defaults**: Fallback values if environment variables aren't set
- **Local development**: Easy to modify secrets locally without affecting git

**Security considerations:**

- Add `.env` to `.gitignore` (already done)
- Each team member maintains their own `.env` file
- Provide `.env.example` file in the repository for reference

## Migration Benefits

### Advantages of Ansible Conversion

1. **Idempotency**: Tasks only run when changes are needed
2. **Error Handling**: Better error handling and rollback capabilities
3. **Modularity**: Reusable roles and playbooks
4. **Documentation**: Self-documenting code structure
5. **Testing**: Ability to test with different configurations
6. **Scaling**: Easy to apply to multiple servers
7. **State Management**: Track and manage system state
8. **Secrets Management**: Built-in secrets handling with Vault

### Maintained Functionality

- All existing services and configurations
- Environment variable support
- Configuration templates
- Service dependencies
- Error handling and logging

## Implementation Steps

### Step 1: Initial Setup

1. Create Ansible directory structure
2. Set up inventory file
3. Create basic variable files
4. Test connectivity to target server

### Step 2: Common Role Implementation

1. Create common role structure
2. Convert basic system setup tasks
3. Implement package management
4. Test common role

### Step 3: Core Services

1. Convert Docker installation
2. Convert SSH configuration
3. Convert MOTD setup
4. Convert power management

### Step 4: Application Services

1. Convert each application installation script
2. Create Docker Compose templates
3. Implement service configuration
4. Test each service individually

### Step 5: Integration and Testing

1. Create main site playbook
2. Test full deployment
3. Validate all services are working
4. Document any manual steps still required

### Step 6: Cleanup and Documentation

1. Remove old bash scripts (after validation)
2. Update README with Ansible instructions
3. Create troubleshooting guide
4. Document variable customization

## Execution Commands

### Running the Full Setup

```bash
# Install Ansible
pip install ansible

# Run the main playbook
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# Run specific roles
ansible-playbook -i inventory/hosts.yml playbooks/setup-docker.yml
```

### Development and Testing

```bash
# Check syntax
ansible-playbook --syntax-check playbooks/site.yml

# Dry run
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --check

# Run with increased verbosity
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -vv
```

## Ansible Installation on Ubuntu Desktop

Since the conversion to Ansible eliminates the need for most bash scripts, the only installation script you might need is one to install Ansible itself on a clean Ubuntu Desktop system.

### Installation Script

Create and run the following script to install Ansible on Ubuntu Desktop:

```bash
#!/bin/bash
# install-ansible.sh - Install Ansible on Ubuntu Desktop

set -e

echo "Installing Ansible on Ubuntu Desktop..."

# Update package cache
sudo apt update

# Install prerequisites
sudo apt install -y software-properties-common python3-pip python3-venv git

# Add Ansible PPA for newer versions
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Install Ansible via PPA
sudo apt install -y ansible

# Verify installation
ansible --version

# Test connectivity to localhost
echo "Testing Ansible connectivity..."
ansible localhost -m ping

echo "Ansible installation completed successfully!"
echo "Current user: $(whoami)"
```

### Post-Installation Setup

After installing Ansible, you can clone the repository and use the included configuration:

```bash
# Clone the repository
git clone https://github.com/alexander-litvinovich/bedroom-server.git
cd bedroom-server

# The repository will include ansible.cfg in the ansible/ directory
# This ensures all team members use the same configuration
# and settings are version controlled and updated with git pull
```

The repository will include `ansible/ansible.cfg` with the following configuration:

```ini
[defaults]
host_key_checking = False
inventory = inventory/hosts.yml
roles_path = roles
collections_path = collections
remote_user = ubuntu
private_key_file = ~/.ssh/id_rsa
stdout_callback = yaml
interpreter_python = auto_silent

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
```

This approach provides several benefits:

- **Version Control**: Configuration changes are tracked in git
- **Team Consistency**: All team members use the same settings
- **Easy Updates**: Configuration updates come with `git pull`
- **Documentation**: Configuration is self-documenting in the repository

After cloning, you can immediately run the playbooks to set up the entire bedroom server infrastructure.

## Success Criteria

1. All existing services can be deployed using Ansible
2. Configuration is idempotent and can be run multiple times
3. Sensitive data is properly secured with Vault
4. Documentation is complete and accurate
5. The system can be reproduced on a fresh Ubuntu 24.04 installation
6. All existing functionality is preserved

## Risk Mitigation

1. **Backup Strategy**: Create full system backup before conversion
2. **Parallel Development**: Keep existing scripts during development
3. **Incremental Testing**: Test each role individually
4. **Rollback Plan**: Document steps to revert to bash scripts if needed
5. **Service Validation**: Verify all services work after conversion

This conversion plan provides a structured approach to modernizing the bedroom-server infrastructure while maintaining all existing functionality and improving maintainability.
