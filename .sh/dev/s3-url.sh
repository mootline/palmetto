#!/bin/bash

# if no $1, say environment is required
if [ -z "$1" ]; then
  echo "Error: environment is required"
  exit 1
fi

# Load environment variables from .env
source .env

# add environment to the app name
PALMETTO_APP_NAME_HYPHENS=$(echo "$PALMETTO_APP_NAME" | sed 's/_/-/g')
PALMETTO_APP_NAME="${PALMETTO_APP_NAME_HYPHENS}-$1"
PALMETTO_APP_NAME_UNDERSCORES=$(echo "$PALMETTO_APP_NAME" | sed 's/-/_/g')


# Echo the s3 url 
echo "'s3://${PALMETTO_BACKUP_BUCKET_NAME}/${PALMETTO_APP_NAME_UNDERSCORES}?AWS_ACCESS_KEY_ID=${PALMETTO_BACKUP_BUCKET_ACCESS_KEY_ID}&AWS_SECRET_ACCESS_KEY=${PALMETTO_BACKUP_BUCKET_SECRET_ACCESS_KEY}&AWS_REGION=${PALMETTO_BACKUP_BUCKET_REGION}&AWS_ENDPOINT=${PALMETTO_BACKUP_BUCKET_ENDPOINT}'"