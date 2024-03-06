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

# create the fly.toml file
bash .sh/fly/create-fly-toml.sh $1

# copy Dockerfile.template to Dockerfile and replace PALMETTO_COCKROACHDB_VERSION with $PALMETTO_COCKROACHDB_VERSION
cp Dockerfile.template Dockerfile
sed -i "s/PALMETTO_COCKROACHDB_VERSION/$PALMETTO_COCKROACHDB_VERSION/g" Dockerfile

function fly_secret(){
  local secret_value="${!1}"
  flyctl secrets set $1="$secret_value" --app $PALMETTO_APP_NAME --stage
}

# if the script has the -s flag, set the secrets
if [ "$2" = "-s" ]; then
  fly_secret PALMETTO_RPC_PORT
  fly_secret PALMETTO_SQL_PORT
  fly_secret PALMETTO_VM_DISK_MOUNT_INITIAL_SIZE
  fly_secret PALMETTO_DEFAULT_USER_USERNAME
  fly_secret PALMETTO_DEFAULT_USER_PASSWORD
  fly_secret PALMETTO_DEFAULT_DATABASE_NAME
  fly_secret PALMETTO_WEBHOOK_URL

  # backup settings
  fly_secret PALMETTO_BACKUP_BUCKET_NAME
  fly_secret PALMETTO_BACKUP_BUCKET_ENDPOINT
  fly_secret PALMETTO_BACKUP_BUCKET_REGION
  fly_secret PALMETTO_BACKUP_BUCKET_ACCESS_KEY_ID
  fly_secret PALMETTO_BACKUP_BUCKET_SECRET_ACCESS_KEY
fi


# Deploy the app
fly deploy --remote-only \
  --app $PALMETTO_APP_NAME