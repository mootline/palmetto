#!/bin/bash

# kill all child processes on exit
trap 'kill 0' SIGINT SIGTERM EXIT

source .env

flyctl proxy $PALMETTO_HTTP_PORT:$PALMETTO_HTTP_PORT --app $PALMETTO_APP_NAME &
flyctl proxy $PALMETTO_RPC_PORT:$PALMETTO_RPC_PORT --app $PALMETTO_APP_NAME &
flyctl proxy $PALMETTO_SQL_PORT:$PALMETTO_SQL_PORT --app $PALMETTO_APP_NAME

# wait for the child processes to exit
wait
