# create the fly app

# if no $1, say environment is required
if [ -z "$1" ]; then
  echo "Error: environment is required"
  exit 1
fi

# Load environment variables from .env
source .env

# add environment to the app name
PALMETTO_APP_NAME_HYPHENS=$(echo "$PALMETTO_APP_NAME" | sed 's/_/-/g')
PALMETTO_APP_NAME="${PALMETTO_APP_NAME_HYPHENS}-$1"
fly app create $PALMETTO_APP_NAME

# create the fly.toml file
bash .sh/fly/create-fly-toml.sh $1