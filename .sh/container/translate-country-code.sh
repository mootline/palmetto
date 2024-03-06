#!/bin/bash

translate_country_code() {
    case "$1" in
        "ams") echo "europe.netherlands.amsterdam" ;;
        "iad") echo "north_america.us.ashburn" ;;
        "atl") echo "north_america.us.atlanta" ;;
        "bog") echo "south_america.colombia.bogota" ;;
        "bos") echo "north_america.us.boston" ;;
        "otp") echo "europe.romania.bucharest" ;;
        "ord") echo "north_america.us.chicago" ;;
        "dfw") echo "north_america.us.dallas" ;;
        "den") echo "north_america.us.denver" ;;
        "eze") echo "south_america.argentina.ezeiza" ;;
        "fra") echo "europe.germany.frankfurt" ;;
        "gdl") echo "north_america.mexico.guadalajara" ;;
        "hkg") echo "asia.hong_kong.hong_kong" ;;
        "jnb") echo "africa.south_africa.johannesburg" ;;
        "lhr") echo "europe.uk.london" ;;
        "lax") echo "north_america.us.los_angeles" ;;
        "mad") echo "europe.spain.madrid" ;;
        "mia") echo "north_america.us.miami" ;;
        "yul") echo "north_america.canada.montreal" ;;
        "bom") echo "asia.india.mumbai" ;;
        "cdg") echo "europe.france.paris" ;;
        "phx") echo "north_america.us.phoenix" ;;
        "qro") echo "north_america.mexico.queretaro" ;;
        "gig") echo "south_america.brazil.rio" ;;
        "sjc") echo "north_america.us.san_jose" ;;
        "scl") echo "south_america.chile.santiago" ;;
        "gru") echo "south_america.brazil.sao_paulo" ;;
        "sea") echo "north_america.us.seattle" ;;
        "ewr") echo "north_america.us.secaucus" ;;
        "sin") echo "asia.singapore.singapore" ;;
        "arn") echo "europe.sweden.stockholm" ;;
        "syd") echo "australia.australia.sydney" ;;
        "nrt") echo "asia.japan.tokyo" ;;
        "yyz") echo "north_america.canada.toronto" ;;
        "waw") echo "europe.poland.warsaw" ;;
        *) echo "Unknown country code: $1" ;;
    esac
}

# Translate the city code to the desired format
continent_country_city=$(translate_country_code "$1")

# Replace the dots with the desired format
formatted_output=$(echo "$continent_country_city" | awk -F'.' '{print "continent="$1",country="$2",city="$3}')

#echo "$formatted_output,code=$1"
echo "$formatted_output"