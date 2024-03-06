#!/bin/bash

# Source the .env file
source .env

# Copy the example file to the output file
cp fly.toml.example fly.toml

# Loop over the lines in the .env file
while IFS='=' read -r VAR_NAME VAR_VALUE
do
  # Use sed to replace the placeholder with the actual value in the output file
  sed -i "s/${VAR_NAME}/${VAR_VALUE}/g" fly.toml
done < .env