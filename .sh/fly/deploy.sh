#!/bin/bash

# Load environment variables from .env
source .env
echo $PALMETTO_APP_NAME

# set the rpc and sql ports and the mount size
flyctl secrets set PALMETTO_RPC_PORT=$PALMETTO_RPC_PORT --app $PALMETTO_APP_NAME --stage
flyctl secrets set PALMETTO_SQL_PORT=$PALMETTO_SQL_PORT --app $PALMETTO_APP_NAME --stage
flyctl secrets set PALMETTO_MOUNT_SIZE=$PALMETTO_MOUNT_SIZE --app $PALMETTO_APP_NAME --stage

# Deploy the app
fly deploy --remote-only \
  --vm-cpu-kind "shared" \
  --vm-cpus 2 \
  --vm-memory 4096 \
  --volume-initial-size $PALMETTO_MOUNT_SIZE \
  --app $PALMETTO_APP_NAME