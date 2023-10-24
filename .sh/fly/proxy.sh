#!/bin/bash

# kill all child processes on exit
trap 'kill 0' SIGINT

flyctl proxy 8080:8080 --app $PALMETTO_APP_NAME &
flyctl proxy $PALMETTO_RPC_PORT:$PALMETTO_RPC_PORT --app $PALMETTO_APP_NAME &
flyctl proxy $PALMETTO_SQL_PORT:$PALMETTO_SQL_PORT --app $PALMETTO_APP_NAME

wait
