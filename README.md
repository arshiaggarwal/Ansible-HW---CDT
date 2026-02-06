# Vulnerable vsftpd 3.0.5 Deployment with Privilege Escalation

## Overview

This Ansible playbook automatically deploys a purposefully misconfigured vsftpd 3.0.5 FTP server on Ubuntu 22.04 LTS. The deployment creates a realistic privilege escalation vulnerability through improper cron job configuration - specifically, a root-owned cron job that executes scripts from a directory writable by the FTP user.

This setup is designed for cybersecurity training, CTF competitions, and Red/Blue team exercises, demonstrating how simple misconfigurations in service automation can lead to complete system compromise.

## Vulnerability Description

**Vulnerability Type**: Privilege Escalation via Cron Job Misconfiguration  
**Affected Version**: vsftpd 3.0.5 (with intentional misconfiguration)  
**CVSS Severity**: High (8.8) - Local privilege escalation to root

The vulnerability exists when:
1. A cron job runs as root
2. The cron job executes a script from a directory writable by a low-privilege user (ftpuser)
3. An attacker with FTP access can replace the script with malicious code
4. When cron executes, the malicious script runs with root privileges

This represents a common real-world misconfiguration pattern seen in production environments where automation scripts are placed in shared or improperly permissioned directories.

## Prerequisites

- **Target OS**: Ubuntu 22.04 LTS
- **Ansible version**: 2.9+ (tested with 2.10+)
- **Control Node**: Any system with Ansible installed
- **Required privileges**: sudo/root access on target system
- **Network**: SSH access to target system (or localhost deployment)
- **Disk Space**: ~500MB free space

## Quick Start
```bash
# 1. Clone this repository
git clone <your-repo-url>
cd ansible-vuln-vsftpd

# 2. Update inventory with your target IP (or use localhost)
nano inventory.ini

# 3. Run the playbook
ansible-playbook -i inventory.ini playbook.yml

# 4. Verify deployment
ssh ftpuser@<target-ip>  # Password: ftppass123

# 5. Test FTP access
ftp <target-ip>  # Username: ftpuser, Password: ftppass123
```

## Documentation

- **[Deployment Guide](docs/DEPLOYMENT.md)** - Complete deployment instructions with troubleshooting
- **[Exploitation Guide](docs/EXPLOITATION.md)** - Step-by-step privilege escalation walkthrough

## Competition Use Cases

### Red Team Scenarios
- **Initial Access**: Demonstrate credential stuffing or brute force against FTP services
- **Privilege Escalation**: Show exploitation of misconfigured automation/cron jobs
- **Persistence**: Establish persistent root access through cron modifications
- **Lateral Movement**: Use compromised system as pivot point

### Blue Team Scenarios
- **Detection Practice**: Monitor for suspicious FTP activity and cron modifications
- **Log Analysis**: Identify privilege escalation attempts in syslog/auth.log
- **Hardening**: Practice proper file permissions and cron job security
- **Incident Response**: Respond to a privilege escalation incident

### Grey Team / Purple Team
- **Security Auditing**: Demonstrate how to identify similar misconfigurations
- **Vulnerability Assessment**: Practice reconnaissance and vulnerability discovery
- **Security Awareness**: Train developers/admins on secure automation practices

## Technical Details

The Ansible playbook performs the following actions:

1. **System Preparation**
   - Updates package cache
   - Installs vsftpd 3.0.5 and dependencies

2. **User Configuration**
   - Creates `ftpuser` with known credentials
   - Creates writable home directory at `/home/ftpuser`
   - Configures user shell and permissions

3. **vsftpd Configuration**
   - Enables local user authentication
   - Configures write permissions for FTP users
   - Sets up chroot jail for FTP sessions
   - Enables logging

4. **Vulnerable Cron Job Setup**
   - Creates `/home/ftpuser/scripts/` directory (writable by ftpuser)
   - Places benign script in scripts directory
   - Creates root cron job that executes the script every 5 minutes
   - **Vulnerability**: ftpuser can overwrite the script with malicious code

5. **Service Management**
   - Starts and enables vsftpd service
   - Configures firewall (if UFW is active)

## Troubleshooting

### Cannot Login via FTP
```bash
# Verify user exists
id ftpuser

# Check vsftpd config
sudo cat /etc/vsftpd.conf | grep local_enable

# Check logs
sudo tail -f /var/log/vsftpd.log
```

### Cron Job Not Running
```bash
# Verify cron job exists
sudo crontab -l

# Check cron logs
sudo grep CRON /var/log/syslog

# Manually test script
sudo /home/ftpuser/scripts/backup.sh
```

### Permission Denied on Script Directory
```bash
# Fix permissions
sudo chown ftpuser:ftpuser /home/ftpuser/scripts
sudo chmod 755 /home/ftpuser/scripts
sudo chmod 755 /home/ftpuser/scripts/backup.sh
```
