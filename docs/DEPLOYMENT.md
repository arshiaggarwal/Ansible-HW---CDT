# Deployment Guide - Vulnerable vsftpd 3.0.5

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation Steps](#installation-steps)
3. [Verification](#verification)
4. [Configuration Details](#configuration-details)
5. [Troubleshooting](#troubleshooting)

## Prerequisites

### Control Node (where you run Ansible)
- Ansible 2.9 or higher installed
- SSH access to target system
- Git (to clone repository)

### Target System
- Ubuntu 22.04 LTS
- Minimum 1GB RAM
- 10GB free disk space
- Root/sudo access
- Internet connection for package installation

### Installing Ansible (if not already installed)

**On Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install ansible -y
ansible --version
```

**On macOS:**
```bash
brew install ansible
```

**On RHEL/CentOS:**
```bash
sudo yum install ansible -y
```

## Installation Steps

### Step 1: Clone the Repository
```bash
git clone <your-repository-url>
cd ansible-vuln-vsftpd
```

### Step 2: Configure Inventory

**For localhost deployment (testing on same machine):**

The default `inventory.ini` is already configured for localhost. No changes needed.

**For remote deployment:**

Edit `inventory.ini`:
```bash
nano inventory.ini
```

Comment out localhost and add your target:
```ini
[vulnerable_servers]
# localhost ansible_connection=local

# Replace with your target details
target_server ansible_host=192.168.1.100 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### Step 3: Test Connectivity
```bash
# For localhost
ansible -i inventory.ini vulnerable_servers -m ping

# For remote host
ansible -i inventory.ini vulnerable_servers -m ping --ask-pass
```

Expected output:
```
localhost | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Step 4: Run the Playbook

**Full deployment:**
```bash
ansible-playbook -i inventory.ini playbook.yml
```

**With sudo password prompt (if needed):**
```bash
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass
```

**Dry run (check mode):**
```bash
ansible-playbook -i inventory.ini playbook.yml --check
```

**Verbose output (for debugging):**
```bash
ansible-playbook -i inventory.ini playbook.yml -v
```

### Step 5: Expected Output

You should see output similar to:
```
PLAY [Deploy Vulnerable vsftpd 3.0.5 with Privilege Escalation] ****************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [Update apt cache] ********************************************************
changed: [localhost]

TASK [Install required packages] ***********************************************
changed: [localhost]

...

TASK [Display deployment information] ******************************************
ok: [localhost] => {
    "msg": [
        "==========================================",
        "Vulnerable vsftpd Deployment Complete!",
        "==========================================",
        "FTP Server: 192.168.1.100",
        "FTP Username: ftpuser",
        "FTP Password: ftppass123",
        ...
    ]
}

PLAY RECAP *********************************************************************
localhost                  : ok=14   changed=8    unreachable=0    failed=0
```

## Verification

### Verify vsftpd Service
```bash
# Check service status
sudo systemctl status vsftpd

# Should show "active (running)"
```

### Verify FTP User
```bash
# Check if user exists
id ftpuser

# Expected output:
# uid=1001(ftpuser) gid=1001(ftpuser) groups=1001(ftpuser)
```

### Verify Vulnerable Script
```bash
# Check script exists and permissions
ls -la /home/ftpuser/scripts/

# Expected output:
# drwxr-xr-x 2 ftpuser ftpuser 4096 Feb  5 10:00 .
# -rwxr-xr-x 1 ftpuser ftpuser  267 Feb  5 10:00 backup.sh
```

**IMPORTANT**: Note that ftpuser owns both the directory AND the script!

### Verify Cron Job
```bash
# Check root crontab
sudo crontab -l

# Should see:
# */5 * * * * /home/ftpuser/scripts/backup.sh >> /var/log/backup.log 2>&1
```

### Test FTP Login

**Via command line:**
```bash
ftp localhost
# Username: ftpuser
# Password: ftppass123

ftp> ls
ftp> cd scripts
ftp> ls
ftp> quit
```

**Via FTP client (FileZilla, WinSCP, etc.):**
- Host: `<target-ip>`
- Port: `21`
- Username: `ftpuser`
- Password: `ftppass123`

### Verify Cron Execution
```bash
# Wait 5 minutes, then check log
sudo tail -f /var/log/backup.log

# You should see entries like:
# [Tue Feb  5 10:05:01 2026] Backup script executed
# [Tue Feb  5 10:05:01 2026] System uptime: 10:05:01 up 2 days, 14:32, 1 user, load average: 0.00, 0.01, 0.05
```

## Configuration Details

### vsftpd Configuration

The playbook modifies `/etc/vsftpd.conf` with these key settings:
```ini
local_enable=YES              # Allow local users to login
write_enable=YES              # Allow FTP commands which change filesystem
chroot_local_user=NO          # Don't restrict users to home directory
allow_writeable_chroot=YES    # Allow writable chroot
local_umask=022               # Default file permissions
xferlog_enable=YES            # Enable logging
listen=YES                    # Run standalone
pam_service_name=vsftpd       # PAM configuration
```

### User Configuration

- **Username**: ftpuser
- **Password**: ftppass123 (hashed with SHA-512)
- **Home Directory**: /home/ftpuser
- **Shell**: /bin/bash
- **Groups**: ftpuser

### Cron Job Configuration

- **Schedule**: Every 5 minutes (`*/5 * * * *`)
- **User**: root
- **Command**: `/home/ftpuser/scripts/backup.sh >> /var/log/backup.log 2>&1`
- **Vulnerability**: Script location is writable by ftpuser!

## Troubleshooting

### Issue: "vsftpd: unrecognized service"

**Solution:**
```bash
# Reinstall vsftpd
sudo apt remove vsftpd
sudo apt install vsftpd
sudo systemctl start vsftpd
```

### Issue: "500 OOPS: vsftpd: refusing to run with writable root inside chroot()"

**Solution:**
Already handled by playbook with `allow_writeable_chroot=YES`, but if you see this:
```bash
sudo nano /etc/vsftpd.conf
# Add: allow_writeable_chroot=YES
sudo systemctl restart vsftpd
```

### Issue: Cannot connect to FTP from remote machine

**Solution:**
```bash
# Check firewall
sudo ufw status
sudo ufw allow 21/tcp
sudo ufw reload

# Check if vsftpd is listening
sudo netstat -tlnp | grep :21
```

### Issue: Cron job not executing

**Solution:**
```bash
# Check cron service
sudo systemctl status cron

# Check syslog for cron errors
sudo grep CRON /var/log/syslog

# Manually test the script
sudo /home/ftpuser/scripts/backup.sh
```

### Issue: Permission denied when uploading via FTP

**Solution:**
```bash
# Fix home directory permissions
sudo chown -R ftpuser:ftpuser /home/ftpuser
sudo chmod 755 /home/ftpuser

# Check vsftpd write permissions
grep write_enable /etc/vsftpd.conf
# Should show: write_enable=YES
```

### Issue: Playbook fails on "password_hash" filter

**Solution:**
```bash
# Install required Python package
pip3 install passlib

# Or on Ubuntu
sudo apt install python3-passlib
```

## Screenshots Required

Take screenshots of:

1. **Ansible playbook execution** - Full terminal output showing success
2. **Service status** - `sudo systemctl status vsftpd` showing active
3. **FTP login** - Successful FTP connection
4. **File listing** - Showing scripts directory via FTP
5. **Cron job listing** - `sudo crontab -l` output
6. **Backup log** - `sudo cat /var/log/backup.log` showing execution

Save all screenshots in `screenshots/deployment/` directory.