#!/bin/bash

# Run the original CockroachDB entrypoint script
#/cockroach/cockroach.sh 

# Get the seeds from the DNS TXT record
seeds=$(dig +short txt vms.${FLY_APP_NAME}.internal)
FORMATTED_SEEDS=$(bash format-seeds.sh "$seeds")
echo "$FORMATTED_SEEDS" > FORMATTED_SEEDS
echo "Formatted seeds: $FORMATTED_SEEDS"

# translate the $FLY_REGION to the locality format
FORMATTED_LOCALITY="$(bash translate-country-code.sh "$FLY_REGION")"
echo "Formatted locality: $FORMATTED_LOCALITY"

# get the data mount directories
PALMETTO_APP_NAME_HYPHENS=$(echo "$FLY_APP_NAME" | sed 's/_/-/g')
PALMETTO_APP_NAME_UNDERSCORES=$(echo "$FLY_APP_NAME" | sed 's/-/_/g')
PALMETTO_MOUNT_SOURCE="$PALMETTO_APP_NAME_UNDERSCORES_data_mount"
PALMETTO_MOUNT_DESTINATION="$PALMETTO_APP_NAME_HYPHENS-data-mount"

PALMETTO_S3_BACKUP_URL="'s3://${PALMETTO_BACKUP_BUCKET_NAME}/${PALMETTO_APP_NAME_UNDERSCORES}?AWS_ACCESS_KEY_ID=${PALMETTO_BACKUP_BUCKET_ACCESS_KEY_ID}&AWS_SECRET_ACCESS_KEY=${PALMETTO_BACKUP_BUCKET_SECRET_ACCESS_KEY}&AWS_REGION=${PALMETTO_BACKUP_BUCKET_REGION}&AWS_ENDPOINT=${PALMETTO_BACKUP_BUCKET_ENDPOINT}'"

# Create the certs directory
CERTS_DIR="/$PALMETTO_MOUNT_DESTINATION/cockroach-certs"
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
export COCKROACH_CERTS_DIR="${CERTS_DIR}" 
export COCKROACH_CA_KEY="${CERTS_DIR}/ca.key"
export COCKROACH_PORT=${PALMETTO_RPC_PORT}
# append to the bashrc
echo "export COCKROACH_CERTS_DIR=\"${CERTS_DIR}\"" >> ~/.bashrc
echo "export COCKROACH_CA_KEY=\"${CERTS_DIR}/ca.key\"" >> ~/.bashrc
echo "export COCKROACH_PORT=\"${PALMETTO_RPC_PORT}\"" >> ~/.bashrc
source ~/.bashrc


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
    "${FLY_APP_NAME}.internal" \
    "${FLY_APP_NAME}.internal:${PALMETTO_SQL_PORT}" \
    "${FLY_ALLOC_ID}.vm.${FLY_APP_NAME}.internal:${PALMETTO_SQL_PORT}" \
    "${FLY_PUBLIC_IP}:${PALMETTO_SQL_PORT}" \
    "${FLY_REGION}.${FLY_APP_NAME}.internal:${PALMETTO_SQL_PORT}" \
    "${FLY_REGION}.${FLY_APP_NAME}.internal" \
    "${FLY_ALLOC_ID}.vm.${FLY_APP_NAME}.internal:${PALMETTO_SQL_PORT}" \
    "${FLY_ALLOC_ID}.vm.${FLY_APP_NAME}.internal:${PALMETTO_RPC_PORT}" \
    "${FLY_ALLOC_ID}.vm.${FLY_APP_NAME}.internal" \
    "${FLY_PUBLIC_IP}:${PALMETTO_RPC_PORT}" \
    "${FLY_REGION}.${FLY_APP_NAME}.internal:${PALMETTO_RPC_PORT}" \
    "${FLY_ALLOC_ID}:${PALMETTO_RPC_PORT}" 
    
# create a cert for the root user
cockroach cert create-client root
    
# create a cert for the default user
cockroach cert create-client $PALMETTO_DEFAULT_USER_USERNAME

# list the certs
cockroach cert list

# add the certificate to the trusted certificates (unsure if this is needed)
#cp "${CERTS_DIR}/ca.crt"  /etc/pki/ca-trust/source/anchors/
#cp "${CERTS_DIR}/node.crt"  /etc/pki/ca-trust/source/anchors/
#cp "${CERTS_DIR}/client.root.crt"  /etc/pki/ca-trust/source/anchors/
#cp "${CERTS_DIR}/client.$PALMETTO_DEFAULT_USER_USERNAME.crt"  /etc/pki/ca-trust/source/anchors/
#update-ca-trust

PALMETTO_DISK_MOUNT_SIZE=$(df -BG /$PALMETTO_MOUNT_DESTINATION | awk 'NR==2{print $2}' | grep -o '[0-9]*')

# Start cockroachdb in the background
cockroach start \
    --join="$FORMATTED_SEEDS" \
    --listen-addr="[::]:${PALMETTO_RPC_PORT}" \
    --sql-addr="[::]:${PALMETTO_SQL_PORT}" \
    --advertise-addr="${FLY_ALLOC_ID}.vm.${FLY_APP_NAME}.internal" \
    --cache=.25 \
    --max-sql-memory=.25 \
    --max-disk-temp-storage=.25 \
    --max-tsdb-memory=.05 \
    --max-offset=250ms \
    --cluster-name="${FLY_APP_NAME}" \
    --locality="${FORMATTED_LOCALITY}" \
    --store="path=/$PALMETTO_MOUNT_DESTINATION,size=${PALMETTO_DISK_MOUNT_SIZE}GiB" \
    --accept-sql-without-tls \
    --pid-file=/tmp/cockroach.pid \
    --certs-dir="${CERTS_DIR}" \
    &
    # --locality-advertise-addr="code=${FLY_REGION}@${FLY_REGION}.${FLY_APP_NAME}.internal" \ # i don't think this is needed

# Get the PID of the background process
#CRDB_PID=$(cat /tmp/cockroach.pid) # This is the correct way to do it according to the CRDB docs, but it doesn't work for some reason
CRDB_PID=$!
echo "CockroachDB background process PID: $CRDB_PID"


function sql(){
    cockroach sql \
        --certs-dir="${CERTS_DIR}" \
        --port="${PALMETTO_SQL_PORT}" \
        --execute="$1"
}

# If it is the first node, initialize the cluster
if [ "$(echo "$FORMATTED_SEEDS" | tr -cd ',' | wc -c)" -eq 0 ]; then

    # Wait a bit to ensure the node is running
    echo "Waiting for CockroachDB to start..."
    sleep 10
    echo "CockroachDB wait over"

    # Initialize the cluster
    cockroach init \
        --cluster-name="${FLY_APP_NAME}"  \
        --host="localhost:${PALMETTO_RPC_PORT}" \
        --certs-dir="${CERTS_DIR}" 
        # --user=root 
        
    # Create the default user
    sql "CREATE USER $PALMETTO_DEFAULT_USER_USERNAME WITH PASSWORD '$PALMETTO_DEFAULT_USER_PASSWORD';"
    
    # Grant the default user admin privileges
    # (This may be changed later)
    sql "GRANT admin TO $PALMETTO_DEFAULT_USER_USERNAME;"
    
    # restore from the backup
    sql "GRANT SYSTEM RESTORE TO $PALMETTO_DEFAULT_USER_USERNAME;"
    
    # Restores are to be run manually if required with
    ### sql "RESTORE FROM LATEST IN ${PALMETTO_S3_BACKUP_URL};"
    # the s3 url can be generated with the .sh/dev/s3-url.sh script
    # restores should be done with the same version of cockroach as the backup was made with
    # restores are really only for disaster recovery, not for migrating data between versions of cockroach
    
    # Create the default database
    sql "CREATE DATABASE IF NOT EXISTS $PALMETTO_DEFAULT_DATABASE_NAME;"
    
    # automate daily backups
    # the free version only allows full backups
    sql "GRANT SYSTEM BACKUP TO $PALMETTO_DEFAULT_USER_USERNAME;"
    sql "CREATE SCHEDULE IF NOT EXISTS ${PALMETTO_APP_NAME_UNDERSCORES}_backup_schedule FOR BACKUP INTO ${PALMETTO_S3_BACKUP_URL} RECURRING '@daily' FULL BACKUP ALWAYS WITH SCHEDULE OPTIONS first_run = 'now';"
    
    # backups can be pushed manually if required with 
    ### BACKUP INTO ${PALMETTO_S3_BACKUP_URL};
fi

# Make sure the default user has an up to date password
sql "ALTER USER $PALMETTO_DEFAULT_USER_USERNAME WITH PASSWORD '$PALMETTO_DEFAULT_USER_PASSWORD';"

# function to send the node up/down/crashed message to the webhook url, takes input "status"
function send_status_to_webhook(){
    curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"roach $1 - ${PALMETTO_APP_NAME_HYPHENS}:${FLY_REGION}:${FLY_ALLOC_ID}\"}" $PALMETTO_WEBHOOK_URL
}


# tell the webhook url the node is up
send_status_to_webhook "up"

# Handle exit signals
# disabled for now, seems to trigger twice
#handle_exit() {
#    # tell the webhook url the node got scaled down
#    send_status_to_webhook "down"
#    exit 1
#}

# Trap the SIGINT, SIGTERM and EXIT signals to call the handle_exit function
trap handle_exit SIGINT SIGTERM EXIT

# Wait for the CockroachDB background process to complete (shouldn't happen unless there's an error)
wait $CRDB_PID
    
# tell the webhook url that cockroach crashed (this should not trigger if the node is stopped from the cli)
send_status_to_webhook "down"