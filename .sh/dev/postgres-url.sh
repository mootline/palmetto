#!/bin/bash

# Load environment variables from .env
source .env

# Echo the postgres url 
echo "postgres://server:$PALMETTO_SERVER_USER_PASSWORD@$PALMETTO_APP_NAME.fly.dev:$PALMETTO_SQL_PORT/palmetto?sslmode=disable"