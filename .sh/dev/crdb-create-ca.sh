#!/bin/bash

# This script generates the secrets for the server and clients.
# It can also be used to regenerate the secrets if they are lost.

local_cert_directory='./local_certs'
regen_secrets=false
update_fly_secrets=false # add a new flag to decide whether to update fly.io secrets

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -r|--regen)
      rm -rf $local_cert_directory
      regen_secrets=true
      shift # past argument
      ;;
    -u|--update_fly)
      update_fly_secrets=true
      shift # past argument
      ;;
    *)
      # Unknown option
      echo "Unknown option: $key"
      exit 1
      ;;
  esac
done

# Load environment variables from .env
source .env

save_to_fly() {
  local secret_name="$1"
  local secret_value="$2"
  if [ "$update_fly_secrets" = true ]; then
    flyctl secrets set "$secret_name=$secret_value" --app "$PALMETTO_APP_NAME" --stage
  fi
}

create_ca() {
  # Generate the CA certificate and key using the cockroach binary directly
  cockroach cert create-ca --certs-dir=$local_cert_directory --ca-key=$local_cert_directory/ca.key
  save_to_fly "PALMETTO_CA_CRT" "$(cat $local_cert_directory/ca.crt)"
  save_to_fly "PALMETTO_CA_KEY" "$(cat $local_cert_directory/ca.key)"
}

create_ca