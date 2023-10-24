#!/bin/bash

# Run the original CockroachDB entrypoint script
#/cockroach/cockroach.sh 

# Get the seeds from the DNS TXT record
seeds=$(dig +short txt vms.${FLY_APP_NAME}.internal)
formatted_seeds=$(bash format-seeds.sh "$seeds")

# write the formatted seeds to a file
echo "$formatted_seeds" > formatted_seeds
echo "Formatted seeds: $formatted_seeds"

CERTS_DIR="/cockroach-data-mount/cockroach-certs"
# nuke the certs dir if it exists
if [ -d "$CERTS_DIR" ]; then
    rm -rf "$CERTS_DIR"
fi
# Check if the folder exists
if [ ! -d "$CERTS_DIR" ]; then
    # Folder does not exist, recreate it
    mkdir "$CERTS_DIR"
fi

# Set the environment variables
#COCKROACH_CERTS_DIR=${CERTS_DIR}
export COCKROACH_CERTS_DIR="${CERTS_DIR}" 
#COCKROACH_CA_KEY=${CERTS_DIR}/ca.key
export COCKROACH_CA_KEY="${CERTS_DIR}/ca.key"
#COCKROACH_PORT=${PALMETTO_RPC_PORT}
export COCKROACH_PORT="${PALMETTO_RPC_PORT}"

# save the certificate to a file
echo "$PALMETTO_CA_CRT" > "${CERTS_DIR}/ca.crt"
echo "$PALMETTO_CA_KEY" > "${CERTS_DIR}/ca.key"

# print the memory usage
echo "Memory usage: $(free -m)"

# create a cert for the CA
# cockroach cert create-ca
    
# create a cert for the node
cockroach cert create-node \
    "${FLY_ALLOC_ID}.vm.${FLY_APP_NAME}.internal" \
    "${FLY_PUBLIC_IP}" \
    "${FLY_REGION}.${FLY_APP_NAME}.internal" \
    "localhost" \
    "[::]:${PALMETTO_SQL_PORT}" \
    "[::]:${PALMETTO_RPC_PORT}" \
    "localhost:${PALMETTO_SQL_PORT}" \
    "localhost:${PALMETTO_RPC_PORT}" \
    "${FLY_ALLOC_ID}" \
    "${FLY_ALLOC_ID}.vm.${FLY_APP_NAME}.internal:${PALMETTO_SQL_PORT}" \
    "${FLY_PUBLIC_IP}:${PALMETTO_SQL_PORT}" \
    "${FLY_REGION}.${FLY_APP_NAME}.internal:${PALMETTO_SQL_PORT}" \
    "${FLY_ALLOC_ID}:${PALMETTO_SQL_PORT}" \
    "${FLY_ALLOC_ID}.vm.${FLY_APP_NAME}.internal:${PALMETTO_RPC_PORT}" \
    "${FLY_PUBLIC_IP}:${PALMETTO_RPC_PORT}" \
    "${FLY_REGION}.${FLY_APP_NAME}.internal:${PALMETTO_RPC_PORT}" \
    "${FLY_ALLOC_ID}:${PALMETTO_RPC_PORT}" \
    --lifetime="43919h" \
    --certs-dir="${CERTS_DIR}"
     
# create a cert for the root user
cockroach cert create-client root \
    --lifetime="43919h"
    
# create a cert for the server user
cockroach cert create-client server \
    --lifetime="43919h"

# list the certs
cockroach cert list \
 --certs-dir=${CERTS_DIR}

# add the certificate to the trusted certificates (unsure if this is needed)
cp "${CERTS_DIR}/ca.crt"  /etc/pki/ca-trust/source/anchors/
cp "${CERTS_DIR}/node.crt"  /etc/pki/ca-trust/source/anchors/
cp "${CERTS_DIR}/client.root.crt"  /etc/pki/ca-trust/source/anchors/
cp "${CERTS_DIR}/client.server.crt"  /etc/pki/ca-trust/source/anchors/
update-ca-trust

# Start cockroachdb in the background
cockroach start \
    --join="$formatted_seeds" \
    --listen-addr="[::]:${PALMETTO_RPC_PORT}" \
    --sql-addr="[::]:${PALMETTO_SQL_PORT}" \
    --advertise-addr="${FLY_ALLOC_ID}.vm.${FLY_APP_NAME}.internal" \
    --locality-advertise-addr="region=${FLY_REGION}@${FLY_REGION}.${FLY_APP_NAME}.internal" \
    --cache=.25 \
    --max-sql-memory=.25 \
    --max-disk-temp-storage=.25 \
    --max-tsdb-memory=.05 \
    --max-offset=250ms \
    --cluster-name="${FLY_APP_NAME}" \
    --locality="region=${FLY_REGION}" \
    --store="path=/cockroach-data-mount,size=${PALMETTO_MOUNT_SIZE}GiB" \
    --certs-dir="${CERTS_DIR}" \
    --accept-sql-without-tls \
    --pid-file=/tmp/cockroach.pid \
    &

# Get the PID of the background process
#CRDB_PID=$(cat /tmp/cockroach.pid) # This is the correct way to do it according to the CRDB docs, but it doesn't work for some reason
CRDB_PID=$!
echo "CockroachDB background process PID: $CRDB_PID"

# If it is the first node, initialize the cluster
if [ "$(echo "$formatted_seeds" | tr -cd ',' | wc -c)" -eq 0 ]; then

    # Wait a bit to ensure the node is running
    echo "Waiting for CockroachDB to start..."
    sleep 10
    echo "CockroachDB wait over"

    # Initialize the cluster
    cockroach init \
        --cluster-name="${FLY_APP_NAME}"  \
        --host="localhost:${PALMETTO_RPC_PORT}" # \
        # --user=server 
        
    # Create the server user
    cockroach sql \
        --execute="CREATE USER server WITH PASSWORD '$PALMETTO_SERVER_PASSWORD';"
    
    # Grant the server user admin privileges
    # (This may be changed later)
    cockroach sql \
        --execute="GRANT admin TO server;"
    
    cockroach sql \
        --execute="CREATE DATABASE palmetto;"
    
fi

# Make sure the server user has an up to date password
cockroach sql \
    --execute="ALTER USER server WITH PASSWORD '$PALMETTO_SERVER_PASSWORD';"
    

# tell the webhook url the node is up
curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"roach up - ${FLY_ALLOC_ID} (${FLY_REGION})\"}" $PALMETTO_WEBHOOK_URL
    
# Wait for the CockroachDB background process to complete (shouldn't happen unless there's an error)
wait $CRDB_PID
    
# tell the webhook url the node is down (this will not trigger if the node is stopped from the cli)
curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"roach down - ${FLY_ALLOC_ID} (${FLY_REGION})\"}" $PALMETTO_WEBHOOK_URL