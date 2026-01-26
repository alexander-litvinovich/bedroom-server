# Ansible Conversion Tasks

This document contains the step-by-step tasks to convert the bedroom-server bash scripts to Ansible playbooks. Each task includes a specific prompt that can be used with GitHub Copilot to perform the conversion.

## Phase 1: Foundation Setup

### Task 1.1: Create Ansible Directory Structure ✅ COMPLETED

**Prompt for Copilot:**

```
Create the basic Ansible directory structure for the bedroom-server project:
- Create ansible/ directory with subdirectories: inventory/, playbooks/, roles/, collections/, group_vars/, host_vars/, templates/, files/
- Create ansible.cfg file with basic configuration
- Create .gitignore entries for .env and .vault_pass.txt
```

**Expected Output:**

- Complete directory structure
- Basic ansible.cfg configuration
- Updated .gitignore file

**Status:** ✅ COMPLETED (16/07/2025)

- Created all required directories
- Added ansible.cfg with proper configuration
- Updated .gitignore with vault password file exclusion

### Task 1.2: Create Inventory File ✅ COMPLETED

**Prompt for Copilot:**

```
Create an Ansible inventory file at ansible/inventory/hosts.yml for the bedroom-server project:
- Define a group called 'bedroom_servers'
- Add localhost as the target host
- Configure connection settings for local deployment
- Include basic host variables
```

**Expected Output:**

- `ansible/inventory/hosts.yml` file
- Proper YAML structure for inventory

**Status:** ✅ COMPLETED (16/07/2025)

- Created inventory file with bedroom_servers group
- Configured localhost as target host with local connection
- Added proper user permissions and deployment variables

### Task 1.3: Create Global Variables File ✅ COMPLETED

**Prompt for Copilot:**

```
Create ansible/group_vars/all.yml file with global variables for the bedroom-server project:
- System configuration (timezone: Europe/Helsinki, admin_user: alex)
- Service configuration for immich, pi-hole, n8n with environment variable lookups
- Network configuration
- Use lookup('env', 'VARIABLE_NAME') for all sensitive data with sensible defaults
```

**Expected Output:**

- `ansible/group_vars/all.yml` file
- All services configured with environment variable references

**Status:** ✅ COMPLETED (16/07/2025)

- Created comprehensive global variables file
- Added environment variable lookups for all sensitive data
- Organized variables by service and system configuration

### Task 1.4: Create Host Variables File ✅ COMPLETED

**Prompt for Copilot:**

```
Create ansible/host_vars/bedroom-server.yml file with host-specific variables:
- Hardware configuration (HP Prodesk 405 G4 Mini)
- Storage mount points
- Network-specific settings
- Tailscale configuration with environment variable lookup
```

**Expected Output:**

- `ansible/host_vars/bedroom-server.yml` file
- Host-specific configuration

**Status:** ✅ COMPLETED (16/07/2025)

- Created host-specific variables file for bedroom-server
- Added hardware configuration for HP Prodesk 405 G4 Mini
- Configured storage mount points and data directories
- Added Tailscale configuration with environment variable lookup
- Included firewall, desktop, and power management settings

## Phase 2: Core System Setup

### Task 2.1: Create Common Role ✅ COMPLETED

**Prompt for Copilot:**

```
Create a common Ansible role at ansible/roles/common/ that replaces the functionality from utils/ directory:
- Create role structure (tasks/main.yml, vars/main.yml, defaults/main.yml, meta/main.yml)
- Convert bash utility functions to Ansible tasks
- Include package management, timezone setup, basic security
- Install base packages: toilet, boxes, mc, zsh
- Set up basic directories and permissions
```

**Expected Output:**

- Complete common role structure
- Converted utility functions to Ansible tasks
- Base system configuration

**Status:** ✅ COMPLETED (16/07/2025)

- Created complete common role structure with all required files
- Converted bash utility functions to Ansible tasks
- Added package management, timezone setup, and basic security
- Configured directory creation and permissions
- Added firewall setup and Git configuration

### Task 2.2: Convert SSH Configuration ✅

**Prompt for Copilot:**

```
Create an SSH role at ansible/roles/ssh/ that converts ssh.sh functionality:
- Install OpenSSH server and required packages
- Configure SSH daemon settings
- Set up SSH client configuration from assets/ssh_config
- Configure firewall rules for SSH
- Set up keychain initialization
- Make the role idempotent
```

**Expected Output:**

- Complete SSH role ✅
- Converted ssh.sh functionality ✅
- SSH configuration templates ✅

### Task 2.3: Convert MOTD Setup

**Prompt for Copilot:**

```
Create a MOTD role at ansible/roles/motd/ that converts motd.sh functionality:
- Install and configure custom MOTD
- Copy dynamic-motd.sh from assets to appropriate location
- Disable default Ubuntu MOTD scripts
- Set up dynamic MOTD execution
- Handle backup and restore of original MOTD
```

**Expected Output:**

- Complete MOTD role
- Converted motd.sh functionality
- Dynamic MOTD configuration

### Task 2.4: Convert Power Management

**Prompt for Copilot:**

```
Create a power-management role at ansible/roles/power-management/ that converts power-management.sh:
- Configure systemd power settings
- Set up power button behavior
- Configure desktop environment power settings
- Handle both desktop and server configurations
- Configure sleep prevention settings
```

**Expected Output:**

- Complete power-management role
- Converted power-management.sh functionality
- Power configuration templates

## Phase 3: Application Roles

### Task 3.1: Convert Docker Installation

**Prompt for Copilot:**

```
Create a Docker role at ansible/roles/docker/ that converts install-scripts/docker.sh:
- Add Docker repository and GPG key
- Install Docker CE and Docker Compose
- Configure Docker daemon
- Add specified users to docker group
- Enable and start Docker service
- Set up proper permissions
- Make installation idempotent
```

**Expected Output:**

- Complete Docker role
- Converted docker.sh functionality
- Docker configuration

### Task 3.2: Convert Immich Installation

**Prompt for Copilot:**

```
Create an Immich role at ansible/roles/immich/ that converts install-scripts/immich.sh:
- Create application directory structure
- Download latest docker-compose.yml from GitHub
- Copy and configure environment file from assets/immich.example.env
- Use environment variables for database password
- Start Immich with Docker Compose
- Make deployment idempotent
```

**Expected Output:**

- Complete Immich role
- Converted immich.sh functionality
- Immich configuration templates

### Task 3.3: Convert n8n Installation

**Prompt for Copilot:**

```
Create an n8n role at ansible/roles/n8n/ that converts install-scripts/n8n.sh:
- Create application and data directories
- Copy docker-compose.yml and environment files from assets
- Generate security keys (encryption key, JWT secret)
- Configure environment variables from .env file
- Start n8n with Docker Compose
- Handle data directory permissions
```

**Expected Output:**

- Complete n8n role
- Converted n8n.sh functionality
- n8n configuration templates

### Task 3.4: Convert NGINX Proxy Manager

**Prompt for Copilot:**

```
Create an nginx-proxy-manager role at ansible/roles/nginx-proxy-manager/ that converts install-scripts/nginx-proxy-manager.sh:
- Create application directory
- Copy docker-compose.yaml from assets
- Start NGINX Proxy Manager container
- Configure port mappings
- Set up data volume persistence
- Make deployment idempotent
```

**Expected Output:**

- Complete nginx-proxy-manager role
- Converted nginx-proxy-manager.sh functionality

### Task 3.5: Convert Pi-hole Installation

**Prompt for Copilot:**

```
Create a pi-hole role at ansible/roles/pi-hole/ that converts install-scripts/pi-hole.sh:
- Create application directory
- Copy docker-compose.yaml and environment files from assets
- Configure Pi-hole password from environment variables
- Set up timezone and DNS settings
- Start Pi-hole container
- Configure firewall rules for DNS
```

**Expected Output:**

- Complete pi-hole role
- Converted pi-hole.sh functionality
- Pi-hole configuration templates

### Task 3.6: Convert XRDP Installation

**Prompt for Copilot:**

```
Create an XRDP role at ansible/roles/xrdp/ that converts install-scripts/xrdp.sh:
- Install XRDP and required packages
- Create XRDP user with proper groups
- Copy all XRDP configuration files from assets/xrdp_*
- Set up Polkit rules and permissions
- Configure dummy video driver
- Set up session management
- Configure firewall rules
- Make installation idempotent
```

**Expected Output:**

- Complete XRDP role
- Converted xrdp.sh functionality
- XRDP configuration files

### Task 3.7: Convert Shell Configuration

**Prompt for Copilot:**

```
Create a shell role at ansible/roles/shell/ that converts install-scripts/ohmyzsh.sh:
- Install zsh if not present
- Install Oh My Zsh framework
- Configure zsh as default shell
- Set up Oh My Zsh configuration
- Handle existing shell configurations
- Make installation idempotent
```

**Expected Output:**

- Complete shell role
- Converted ohmyzsh.sh functionality
- Shell configuration

## Phase 4: Integration and Playbooks

### Task 4.1: Create Main Site Playbook

**Prompt for Copilot:**

```
Create ansible/playbooks/site.yml that replaces preflight.sh functionality:
- Include all roles in proper order
- Handle dependencies between roles
- Include pre-tasks and post-tasks
- Add error handling and rollback capabilities
- Configure proper task ordering (common, docker, services, desktop)
- Add environment variable loading
```

**Expected Output:**

- Main site.yml playbook
- Proper role ordering and dependencies
- Error handling

### Task 4.2: Create Specific Setup Playbooks

**Prompt for Copilot:**

```
Create specific playbooks for different deployment scenarios:
- ansible/playbooks/setup-basic.yml (common, ssh, motd, power-management)
- ansible/playbooks/setup-docker.yml (docker role only)
- ansible/playbooks/setup-services.yml (all containerized services)
- ansible/playbooks/setup-desktop.yml (xrdp, shell configuration)
- Each playbook should be runnable independently
```

**Expected Output:**

- Multiple focused playbooks
- Independent execution capability
- Proper role inclusion

### Task 4.3: Create Templates

**Prompt for Copilot:**

```
Convert static configuration files to Jinja2 templates in ansible/templates/:
- Create templates for SSH config, MOTD, and other configuration files
- Use Ansible variables for dynamic content
- Handle different deployment scenarios
- Ensure templates are properly parameterized
```

**Expected Output:**

- Jinja2 templates for configuration files
- Dynamic configuration capability
- Variable substitution

### Task 4.4: Copy Static Files

**Prompt for Copilot:**

```
Copy static files from assets/ to ansible/files/:
- Copy Docker Compose files
- Copy XRDP configuration files
- Copy other static assets
- Organize files by role/service
- Update role tasks to reference correct file locations
```

**Expected Output:**

- Static files organized in ansible/files/
- Updated role references
- Proper file organization

## Phase 5: Testing and Validation

### Task 5.1: Create Test Playbook

**Prompt for Copilot:**

```
Create ansible/playbooks/test.yml for validating the deployment:
- Test all services are running
- Verify configuration files are in place
- Check network connectivity
- Validate Docker containers are healthy
- Test SSH access and XRDP functionality
- Generate deployment report
```

**Expected Output:**

- Test playbook for validation
- Service health checks
- Deployment verification

### Task 5.2: Create Install Script

**Prompt for Copilot:**

```
Create install-ansible.sh script based on the plan in ansible-convert.md:
- Install Ansible via PPA
- Install prerequisites
- Test Ansible connectivity
- Provide usage instructions
- Include error handling
```

**Expected Output:**

- install-ansible.sh script
- Complete Ansible installation automation

### Task 5.3: Update Documentation

**Prompt for Copilot:**

```
Update README.md with Ansible deployment instructions:
- Replace bash script instructions with Ansible commands
- Document environment variable setup
- Add troubleshooting section
- Include examples of running different playbooks
- Document the new workflow
```

**Expected Output:**

- Updated README.md
- Complete Ansible documentation
- Usage examples

## Phase 6: Cleanup and Finalization

### Task 6.1: Create Environment Template

**Prompt for Copilot:**

```
Create .env.example file with all required environment variables:
- Include all variables used in the Ansible playbooks
- Add comments explaining each variable
- Provide example values
- Document required vs optional variables
```

**Expected Output:**

- .env.example file
- Complete environment documentation

### Task 6.2: Final Testing

**Prompt for Copilot:**

```
Create a comprehensive test script that validates the entire Ansible deployment:
- Test fresh installation on clean system
- Verify all services are working
- Test idempotency (run playbooks multiple times)
- Validate all configuration files
- Check port accessibility
- Generate final deployment report
```

**Expected Output:**

- Comprehensive test script
- Deployment validation
- Final verification

### Task 6.3: Migration Script

**Prompt for Copilot:**

```
Create a migration script that helps transition from bash scripts to Ansible:
- Compare current bash script state with Ansible deployment
- Identify any missing configurations
- Provide migration checklist
- Handle backup of existing configurations
- Validate successful migration
```

**Expected Output:**

- Migration assistance script
- Transition validation
- Backup and restore capabilities

## Execution Order

Execute these tasks in the following order:

1. **Phase 1**: Foundation Setup (Tasks 1.1-1.4)
2. **Phase 2**: Core System Setup (Tasks 2.1-2.4)
3. **Phase 3**: Application Roles (Tasks 3.1-3.7)
4. **Phase 4**: Integration and Playbooks (Tasks 4.1-4.4)
5. **Phase 5**: Testing and Validation (Tasks 5.1-5.3)
6. **Phase 6**: Cleanup and Finalization (Tasks 6.1-6.3)

Each task should be completed and tested before moving to the next phase. This ensures a systematic and reliable conversion process.
