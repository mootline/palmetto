#!/bin/bash

# This script takes a list of identifiers and locations and formats them for use as cockroach join nodes.

# Check if an argument was provided
if [ $# -ne 1 ]; then
    #echo "Usage: $0 <list>"
    exit 1
fi

# Input list of identifiers and locations, stripping off quotes
input_list="$(echo "$1" | tr -d '"')"
#echo "Received input: $input_list"  # Debug line

# Check FLY_APP_NAME
#echo "FLY_APP_NAME: $FLY_APP_NAME"  # Debug line

# Initialize the output list
output_list=""
seed_counter=0

# Split the input list into individual pairs using ',' as the delimiter
IFS=',' read -ra pairs <<< "$input_list"

# Iterate through the pairs
for pair in "${pairs[@]}"; do
    # Break out of the loop if we have already appended 3 seeds
    if [ "$seed_counter" -ge 3 ]; then
        break
    fi
    
    # Split each pair into identifier and location using ' ' as the delimiter
    IFS=' ' read -r identifier location <<< "$pair"
    
    #echo "Processing pair: $pair"  # Debug line
    #echo "Identifier: $identifier, Location: $location"  # Debug line
    
    # Append the formatted entry to the output list, excluding the location
    output_list="${output_list}${identifier}.vm.$FLY_APP_NAME.internal,"
    
    # Increment the seed counter
    ((seed_counter++))
done

# Remove the trailing comma
output_list="${output_list%,}"

# Check if the output list is empty, and set it to "localhost" if it is
if [ -z "$output_list" ]; then
    output_list="localhost"
fi

# check if the output list has no commas, and set it to "localhost" if it does
if [[ "$output_list" != *","* ]]; then
    output_list="localhost"
fi

# Return the formatted list as a result
echo "$output_list"
