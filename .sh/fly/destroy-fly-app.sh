# create the fly app

# Load environment variables from .env
source .env

# add environment to the app name
PALMETTO_APP_NAME_HYPHENS=$(echo "$PALMETTO_APP_NAME" | sed 's/_/-/g')
PALMETTO_APP_NAME="${PALMETTO_APP_NAME_HYPHENS}-$1"
fly app destroy $PALMETTO_APP_NAME