#!/bin/bash

# Load environment variables from .env
source .env
echo $PALMETTO_APP_NAME

function fly_secret(){
  local secret_value="${!1}"
  flyctl secrets set $1="$secret_value" --app $PALMETTO_APP_NAME --stage
}

# set the environment variables
fly_secret PALMETTO_RPC_PORT
fly_secret PALMETTO_SQL_PORT
fly_secret PALMETTO_MOUNT_SIZE
fly_secret PALMETTO_SERVER_PASSWORD
fly_secret PALMETTO_WEBHOOK_URL

# Deploy the app
fly deploy --remote-only \
  --vm-cpu-kind "shared" \
  --vm-cpus 2 \
  --vm-memory 4096 \
  --volume-initial-size $PALMETTO_MOUNT_SIZE \
  --app $PALMETTO_APP_NAME