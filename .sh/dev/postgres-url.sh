source .env

echo "postgres://server:$PALMETTO_SERVER_PASSWORD@$PALMETTO_APP_NAME.fly.dev:$PALMETTO_SQL_PORT/palmetto?sslmode=disable"