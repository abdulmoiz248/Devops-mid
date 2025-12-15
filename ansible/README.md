# Ansible Configuration Management

This directory contains Ansible playbooks and configurations for automating the setup and deployment of the DevOps Mid project on AWS EC2 instances.

## 📁 Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── playbook.yaml           # Main playbook
├── test-connection.yaml    # Connectivity test playbook
├── requirements.txt        # Python dependencies
├── requirements.yml        # Ansible collections
├── inventory/
│   ├── hosts.ini          # Static inventory file
│   └── aws_ec2.yaml       # Dynamic AWS inventory
├── templates/
│   └── env.j2             # Environment file template
└── roles/                 # Custom roles (future use)
```

## 🎯 What the Playbook Does

The main playbook ([playbook.yaml](playbook.yaml)) automates:

1. **System Configuration**
   - Updates all packages
   - Installs Git, Python, Docker, and essential tools
   - Configures system limits and networking

2. **Docker Setup**
   - Installs Docker Engine
   - Installs Docker Compose
   - Configures Docker daemon
   - Adds ec2-user to docker group

3. **Application Environment**
   - Creates application directories
   - Sets up logging and monitoring
   - Configures environment variables
   - Creates health check scripts

4. **Database Configuration**
   - Installs PostgreSQL client
   - Tests database connectivity
   - Configures connection strings

## 📋 Prerequisites

### On Your Local Machine (Control Node)

1. **Python 3.8+**
   ```bash
   python --version
   ```

2. **Ansible**
   ```bash
   # Install Ansible
   pip install ansible

   # Or using system package manager
   # On Ubuntu/Debian:
   sudo apt-get install ansible
   
   # On macOS:
   brew install ansible
   ```

3. **AWS CLI** (for dynamic inventory)
   ```bash
   aws configure
   ```

4. **SSH Key**
   - Same SSH key used in Terraform configuration
   - Located at `~/.ssh/id_rsa`

### On AWS

1. **EC2 instances** provisioned via Terraform
2. **Security groups** allowing SSH (port 22)
3. **RDS PostgreSQL** instance

## 🚀 Setup Instructions

### Step 1: Install Ansible Dependencies

```bash
cd ansible

# Install Python packages
pip install -r requirements.txt

# Install Ansible collections
ansible-galaxy collection install -r requirements.yml
```

### Step 2: Generate Inventory

After running Terraform, generate the inventory file:

**On Linux/macOS:**
```bash
cd ../scripts
chmod +x generate_inventory.sh
./generate_inventory.sh
```

**On Windows (PowerShell):**
```powershell
cd ..\scripts
.\generate_inventory.ps1
```

**Or manually update** [inventory/hosts.ini](inventory/hosts.ini):
```ini
[ec2_instances]
ec2-1 ansible_host=YOUR_EC2_PUBLIC_IP

[ec2_instances:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### Step 3: Test Connectivity

```bash
cd ansible

# Test connection to all hosts
ansible all -m ping -i inventory/hosts.ini

# Or use the test playbook
ansible-playbook -i inventory/hosts.ini test-connection.yaml
```

Expected output:
```
ec2-1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Step 4: Run the Main Playbook

```bash
# Run with default inventory
ansible-playbook -i inventory/hosts.ini playbook.yaml

# Run with verbose output
ansible-playbook -i inventory/hosts.ini playbook.yaml -v

# Run with extra verbosity (for debugging)
ansible-playbook -i inventory/hosts.ini playbook.yaml -vvv

# Run specific tags only
ansible-playbook -i inventory/hosts.ini playbook.yaml --tags "docker,app"

# Dry run (check mode)
ansible-playbook -i inventory/hosts.ini playbook.yaml --check
```

### Step 5: Verify Installation

After the playbook completes:

```bash
# Check what was installed
ansible ec2_instances -i inventory/hosts.ini -a "docker --version"
ansible ec2_instances -i inventory/hosts.ini -a "docker-compose --version"
ansible ec2_instances -i inventory/hosts.ini -a "python3 --version"

# Check Docker status
ansible ec2_instances -i inventory/hosts.ini -a "systemctl status docker" -b
```

## 🔧 Using Dynamic Inventory (AWS EC2)

For automatic discovery of EC2 instances:

### Setup

1. **Ensure AWS credentials are configured:**
   ```bash
   aws configure list
   ```

2. **Install boto3:**
   ```bash
   pip install boto3 botocore
   ```

3. **Use dynamic inventory:**
   ```bash
   # Test dynamic inventory
   ansible-inventory -i inventory/aws_ec2.yaml --list

   # Run playbook with dynamic inventory
   ansible-playbook -i inventory/aws_ec2.yaml playbook.yaml
   ```

## 📝 Playbook Tags

Run specific parts of the playbook using tags:

| Tag | Description |
|-----|-------------|
| `system` | System updates and package installation |
| `docker` | Docker installation and configuration |
| `python` | Python and pip setup |
| `app` | Application directory and configuration |
| `database` | Database client and connectivity |
| `firewall` | Firewall configuration |
| `logging` | Log rotation setup |

**Examples:**
```bash
# Install only Docker
ansible-playbook -i inventory/hosts.ini playbook.yaml --tags docker

# Skip database configuration
ansible-playbook -i inventory/hosts.ini playbook.yaml --skip-tags database

# Run system and Docker only
ansible-playbook -i inventory/hosts.ini playbook.yaml --tags "system,docker"
```

## 🔐 Managing Secrets

### Method 1: Ansible Vault (Recommended)

```bash
# Create encrypted vars file
ansible-vault create vars/secrets.yml

# Add your secrets:
# db_password: YourSecurePassword123!
# secret_key: your-secret-key

# Run playbook with vault
ansible-playbook -i inventory/hosts.ini playbook.yaml --ask-vault-pass

# Or use password file
echo "vault_password" > .vault_pass
ansible-playbook -i inventory/hosts.ini playbook.yaml --vault-password-file .vault_pass
```

### Method 2: Environment Variables

```bash
# Export variables
export DB_PASSWORD="YourSecurePassword123!"
export SECRET_KEY="your-secret-key"

# Pass to playbook
ansible-playbook -i inventory/hosts.ini playbook.yaml \
  -e "db_password=$DB_PASSWORD" \
  -e "secret_key=$SECRET_KEY"
```

### Method 3: Extra Vars File

Create `vars/extra_vars.yml`:
```yaml
db_password: YourSecurePassword123!
secret_key: your-secret-key
db_host: your-rds-endpoint.rds.amazonaws.com
```

Run with:
```bash
ansible-playbook -i inventory/hosts.ini playbook.yaml -e @vars/extra_vars.yml
```

## 📸 Screenshots for Assignment

### 1. Inventory Check
```bash
ansible-inventory -i inventory/hosts.ini --list
```
Screenshot: Shows all discovered hosts

### 2. Connectivity Test
```bash
ansible all -m ping -i inventory/hosts.ini
```
Screenshot: Shows successful ping to all hosts

### 3. Playbook Execution
```bash
ansible-playbook -i inventory/hosts.ini playbook.yaml
```
Screenshot: Shows playbook running with PLAY RECAP showing all successful tasks

### 4. Verification
```bash
ansible ec2_instances -i inventory/hosts.ini -a "docker --version"
ansible ec2_instances -i inventory/hosts.ini -a "systemctl status docker" -b
```
Screenshot: Shows Docker installed and running

## 🛠️ Troubleshooting

### Issue: "Permission denied (publickey)"

**Solution:**
```bash
# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa

# Test manual SSH connection
ssh -i ~/.ssh/id_rsa ec2-user@<EC2_IP>

# Update ansible.cfg with correct key path
```

### Issue: "Host key verification failed"

**Solution:**
```bash
# Add host to known_hosts
ssh-keyscan -H <EC2_IP> >> ~/.ssh/known_hosts

# Or disable host key checking (less secure)
export ANSIBLE_HOST_KEY_CHECKING=False
```

### Issue: "Module not found" errors

**Solution:**
```bash
# Reinstall collections
ansible-galaxy collection install -r requirements.yml --force

# Check installed collections
ansible-galaxy collection list
```

### Issue: Playbook fails on specific task

**Solution:**
```bash
# Run with verbosity
ansible-playbook -i inventory/hosts.ini playbook.yaml -vvv

# Check specific host
ansible ec2-1 -i inventory/hosts.ini -m setup

# Run in check mode first
ansible-playbook -i inventory/hosts.ini playbook.yaml --check
```

### Issue: "Connection timeout"

**Solution:**
1. Check security group allows SSH from your IP
2. Verify EC2 instance is running
3. Check VPC/subnet routing
4. Verify EC2 has public IP

## 🎓 Common Ansible Commands

### Ad-hoc Commands

```bash
# Check disk space
ansible all -i inventory/hosts.ini -a "df -h"

# Check memory
ansible all -i inventory/hosts.ini -a "free -m"

# Restart Docker
ansible all -i inventory/hosts.ini -a "systemctl restart docker" -b

# Copy file to all servers
ansible all -i inventory/hosts.ini -m copy -a "src=app.py dest=/opt/app/"

# Run shell command
ansible all -i inventory/hosts.ini -m shell -a "docker ps"
```

### Gathering Facts

```bash
# Gather all facts
ansible all -i inventory/hosts.ini -m setup

# Specific facts
ansible all -i inventory/hosts.ini -m setup -a "filter=ansible_distribution*"

# Save facts to file
ansible all -i inventory/hosts.ini -m setup --tree /tmp/facts
```

## 📚 Additional Resources

### Ansible Best Practices
- Use roles for complex playbooks
- Always use version control
- Tag your tasks appropriately
- Use variables and templates
- Implement idempotency
- Use handlers for service restarts

### Useful Modules
- `ansible.builtin.yum` - Package management
- `ansible.builtin.systemd` - Service management
- `ansible.builtin.copy` - Copy files
- `ansible.builtin.template` - Jinja2 templates
- `community.docker.docker_container` - Docker containers
- `ansible.builtin.uri` - HTTP requests

### Documentation Links
- [Ansible Documentation](https://docs.ansible.com/)
- [AWS EC2 Dynamic Inventory](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html)
- [Docker Module](https://docs.ansible.com/ansible/latest/collections/community/docker/index.html)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

## 🔄 Integration with Terraform

The workflow for using Terraform with Ansible:

```bash
# 1. Provision infrastructure
cd infra
terraform init
terraform apply

# 2. Generate Ansible inventory
cd ../scripts
./generate_inventory.sh  # or .ps1 on Windows

# 3. Configure servers
cd ../ansible
ansible-playbook -i inventory/hosts.ini playbook.yaml

# 4. Deploy application (after configuration)
# ... deploy your Docker containers

# 5. Cleanup (when done)
cd ../infra
terraform destroy
```

## ✅ Assignment Deliverables Checklist

- [x] `ansible/playbook.yaml` - Main automation playbook
- [x] `ansible/inventory/hosts.ini` - Static inventory file
- [x] `ansible/inventory/aws_ec2.yaml` - Dynamic inventory
- [ ] Screenshot: Ansible inventory listing
- [ ] Screenshot: Successful `ansible all -m ping` output
- [ ] Screenshot: Playbook execution showing PLAY RECAP
- [ ] Screenshot: Verification of installed packages

---

**Created for DevOps Mid Assignment - Step 4: Configuration Management with Ansible**
