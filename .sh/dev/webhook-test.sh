#!/bin/bash

# Load environment variables from .env
source .env

# Message to send
message="Hello, Discord!"

# Send the message to the webhook
curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"$message\",\"username\":\"${PALMETTO_APP_NAME}\"}" $PALMETTO_WEBHOOK_URL
