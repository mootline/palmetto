#!/bin/bash

# Load environment variables from .env
source .env

# add environment to the app name
PALMETTO_APP_NAME_HYPHENS=$(echo "$PALMETTO_APP_NAME" | sed 's/_/-/g')
PALMETTO_APP_NAME="${PALMETTO_APP_NAME_HYPHENS}-$1"


if [ -z "$1" ]; then
  # if no $1, use localhost
  POSTGRES_URL="localhost"
elif [ -z "$2" ]; then
  # if the environment is dev, use the internal fly hostname
  POSTGRES_URL="${PALMETTO_APP_NAME}.internal"
else
  # otherwise, use the extenal fly hostname
  POSTGRES_URL="${PALMETTO_APP_NAME}.fly.dev"
fi 

# Echo the postgres url 
echo "postgres://$PALMETTO_DEFAULT_USER_USERNAME:$PALMETTO_DEFAULT_USER_PASSWORD@$POSTGRES_URL:$PALMETTO_SQL_PORT/$PALMETTO_DEFAULT_DATABASE_NAME?sslmode=disable"