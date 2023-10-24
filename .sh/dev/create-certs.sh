#!/bin/bash

# This script generates the secrets for the server and clients.
# It can also be used to regenerate the secrets if they are lost.
# It requires docker to be installed.

# the secrets to generate
clients=("root" "admin" "server")
env_identifier="PALMETTO"
local_cert_directory='./local_certs'
regen_secrets=false # pass as a command line argument to regenerate the secrets

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -r|--regen)
      regen_secrets=true
      shift # past argument
      ;;
    *)
      # Unknown option
      echo "Unknown option: $key"
      exit 1
      ;;
  esac
done

# Create the local cert directory if it doesn't exist
mkdir -p $local_cert_directory
  
# Load environment variables from .env
source .env

# Update .env secrets
if [ "$update_secrets" = true ]; then
  for key in $(printenv | awk -F= '{print $1}'); do
    if [[ "$key" == $env_identifier* ]]; then
      echo "Setting $key"
      flyctl secrets set "$key=${!key}" --app "$server_app_name" --stage
    fi
  done
fi

# Generate a Cockroach CA (requires docker)
create_ca() {
  # 1. Pull the cockroachdb/cockroach Docker image
  docker pull cockroachdb/cockroach:latest

  # 2. Start a temporary Docker container
  container_name='temp_cockroachdb_container'

  # 2.1 remove the container if it exists
  docker rm -f $container_name || true

  # 2.2 start a cockroachdb container
  docker run --name $container_name -d cockroachdb/cockroach:latest start --insecure --join=localhost

  # 3. Generate the CA certificate and key in the Docker container
  docker exec $container_name /cockroach/cockroach cert create-ca --certs-dir=/certs --ca-key=/certs/ca.key


  # 4. Copy the generated CA files to the local folder
  docker cp $container_name:/certs/ca.crt $local_cert_directory
  docker cp $container_name:/certs/ca.key $local_cert_directory

  crt_filename="$local_cert_directory/ca.crt"
  key_filename="$local_cert_directory/ca.key"
  crt_value="$(cat $crt_filename)"
  key_value="$(cat $key_filename)"
      
  for client in "${clients[@]}"; do
      # generate the client crt and key
      docker exec $container_name /cockroach/cockroach cert create-client $client --certs-dir=/certs --ca-key=/certs/ca.key
      echo "generated client $client"

      # copy the client crt and key to the local folder
      docker cp $container_name:/certs/client.$client.crt $local_cert_directory
      docker cp $container_name:/certs/client.$client.key $local_cert_directory
      
      # read the crt and key into temporary variables
      crt_filename="$local_cert_directory/client.$client.crt"
      key_filename="$local_cert_directory/client.$client.key"
      crt_value="$(cat $crt_filename)"
      key_value="$(cat $key_filename)"

      # export the crt and key to the environment
      export ${env_identifier}_${client^^}_CRT="${crt_value}"
      export ${env_identifier}_${client^^}_KEY="${key_value}"
      
      # test for whether the variable is set
      # varname="${env_identifier}_${client^^}_CRT"
      # echo "${!varname}"

      # save the crt and key to fly
      flyctl secrets set ${env_identifier}_${client^^}_CRT="${crt_value}" --app $PALMETTO_APP_NAME --stage
      flyctl secrets set ${env_identifier}_${client^^}_KEY="${key_value}" --app $PALMETTO_APP_NAME --stage
  done

  # 5. Cleanup - Remove the temporary Docker container
  docker rm -f $container_name

  # save server secrets to fly and cycle the app
  flyctl secrets set ${env_identifier}_CA_CRT="${crt_value}" --app $PALMETTO_APP_NAME --stage
  flyctl secrets set ${env_identifier}_CA_KEY="${key_value}" --app $PALMETTO_APP_NAME --stage
}

if [ "$regen_secrets" = true ]; then
  create_ca
fi

# Load local CA files
if [ -f "$local_cert_directory/ca.crt" ] && [ -f "$local_cert_directory/ca.key" ]; then
  for client in "${clients[@]}"; do
  
      # read the crt and key into temporary variables
      crt_filename="$local_cert_directory/client.$client.crt"
      key_filename="$local_cert_directory/client.$client.key"
      crt_value="$(cat $crt_filename)"
      key_value="$(cat $key_filename)"

      # export the crt and key to the environment
      export ${env_identifier}_${client^^}_CRT="${crt_value}"
      
      #echo "exported ${env_identifier}_${client^^}_CRT as $crt_value"
      export ${env_identifier}_${client^^}_KEY="${key_value}"
      #echo "exported ${env_identifier}_${client^^}_KEY as $key_value"
  done
  
  crt_filename="$local_cert_directory/ca.crt"
  key_filename="$local_cert_directory/ca.key"
  crt_value="$(cat $crt_filename)"
  key_value="$(cat $key_filename)"
  export ${env_identifier}_CA_CRT="${crt_value}"
  #echo "exported ${env_identifier}_CA_CRT as $crt_value"
  export ${env_identifier}_CA_KEY="${key_value}"
  #echo "exported ${env_identifier}_CA_KEY as $key_value"
  echo "Local CA files found"
else
  echo "Local CA files not found"
fi
