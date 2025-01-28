#!/bin/bash

# Variables
BACKUP_NAME="backup-$(date +%Y%m%d%H%M%S).tar.gz"
BACKUP_DIR="/path/to/backup"
S3_BUCKET="your-s3-bucket-name"
S3_PATH="s3://$S3_BUCKET/backups/$BACKUP_NAME"

# Create backup archive
tar -czvf $BACKUP_NAME $BACKUP_DIR

# Upload to S3
aws s3 cp $BACKUP_NAME $S3_PATH

# Clean up
rm $BACKUP_NAME