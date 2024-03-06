#!/bin/bash

# kill all child processes on exit
trap 'kill 0' SIGINT SIGTERM EXIT


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

flyctl proxy $PALMETTO_HTTP_PORT:$PALMETTO_HTTP_PORT --app $PALMETTO_APP_NAME &
flyctl proxy $PALMETTO_RPC_PORT:$PALMETTO_RPC_PORT --app $PALMETTO_APP_NAME &
flyctl proxy $PALMETTO_SQL_PORT:$PALMETTO_SQL_PORT --app $PALMETTO_APP_NAME

# wait for the child processes to exit
wait
