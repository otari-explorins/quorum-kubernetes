#!/bin/bash

# Variables
POD_NAME="besu-node-validator-4-0"          # Name of the running Pod
NAMESPACE="quorum"        # Namespace of the Pod
# CONTAINER_NAME="your-container"  # Name of the container in the Pod (if multiple containers exist)
SOURCE_DIR="/data/besu/202501/"        # Directory inside the Pod to copy files from
BACKUP_NAME="backup-$(date +%Y%m%d%H%M%S).tar.gz"  # Backup file name
S3_BUCKET="besu-baskup"       # S3 bucket name
S3_PATH="s3://$S3_BUCKET/backups/$BACKUP_NAME"  # S3 path for the backup

# Step 1: Create a backup archive inside the Pod
echo "Creating backup archive inside the Pod..."
# kubectl exec -n $NAMESPACE $POD_NAME -c $CONTAINER_NAME -- tar -czf /tmp/$BACKUP_NAME -C $SOURCE_DIR .
kubectl exec -n $NAMESPACE $POD_NAME -- tar -czf /tmp/$BACKUP_NAME -C $SOURCE_DIR .

# Step 2: Copy the backup archive from the Pod to the local machine
echo "Copying backup archive from the Pod to local machine..."
kubectl cp -n $NAMESPACE $POD_NAME:/tmp/$BACKUP_NAME ./$BACKUP_NAME 

# Step 3: Upload the backup archive to AWS S3
echo "Uploading backup archive to AWS S3..."
aws s3 cp ./$BACKUP_NAME $S3_PATH

# Step 4: Clean up
echo "Cleaning up..."
kubectl exec -n $NAMESPACE $POD_NAME -- rm -f /tmp/$BACKUP_NAME
rm -f ./$BACKUP_NAME

echo "Backup completed successfully!"