#!/bin/bash

# Variables
ARCHITECTURE="linux-amd64" # Default to Intel. Change to "linux-arm64" for ARM
VERSION="v23.1.11"
DOWNLOAD_URL="https://binaries.cockroachdb.com/cockroach-${VERSION}.${ARCHITECTURE}.tgz"

# Download and extract the binary
wget $DOWNLOAD_URL -O cockroach.tgz
tar -xzf cockroach.tgz

# Move the binary to the PATH
sudo cp -i cockroach-${VERSION}.${ARCHITECTURE}/cockroach /usr/local/bin/

# Copy GEOS libraries for spatial features
mkdir -p /usr/local/lib/cockroach
cp -i cockroach-${VERSION}.${ARCHITECTURE}/lib/libgeos.so /usr/local/lib/cockroach/
cp -i cockroach-${VERSION}.${ARCHITECTURE}/lib/libgeos_c.so /usr/local/lib/cockroach/

rm -rf cockroach-${VERSION}.${ARCHITECTURE}/

echo "CockroachDB installation complete!"
