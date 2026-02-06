#!/bin/bash
#
# Benign backup script
# This script runs as root via cron every 5 minutes
# VULNERABILITY: This file is in a directory writable by ftpuser
#

echo "[$(date)] Backup script executed" >> /var/log/backup.log
echo "[$(date)] System uptime: $(uptime)" >> /var/log/backup.log