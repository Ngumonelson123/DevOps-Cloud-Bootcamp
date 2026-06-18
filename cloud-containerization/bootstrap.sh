#!/usr/bin/env bash
# bootstrap.sh
# Manually sets up MySQL + Tooling app containers on a shared Docker network.
# Run this script from the project root.
# Usage: chmod +x bootstrap.sh && ./bootstrap.sh

set -e

# ── Config ──────────────────────────────────────────────────────────────────
NETWORK_NAME="tooling_app_network"
NETWORK_SUBNET="172.18.0.0/24"
MYSQL_CONTAINER="mysql-server"
MYSQL_HOSTNAME="mysqlserverhost"
APP_IMAGE="tooling:0.0.1"
APP_HOST_PORT=8085

# ── Prompt for secrets ───────────────────────────────────────────────────────
read -rsp "Enter MySQL root password: " MYSQL_PW; echo
read -rsp "Enter app DB user password: " DB_USER_PW; echo
DB_USER="tooling_user"

# ── 1. Create Docker network ─────────────────────────────────────────────────
echo ">>> Creating network: $NETWORK_NAME"
docker network create --subnet="$NETWORK_SUBNET" "$NETWORK_NAME" 2>/dev/null || \
  echo "    Network already exists, skipping."

# ── 2. Run MySQL container ───────────────────────────────────────────────────
echo ">>> Starting MySQL container..."
docker run \
  --network "$NETWORK_NAME" \
  -h "$MYSQL_HOSTNAME" \
  --name "$MYSQL_CONTAINER" \
  -e MYSQL_ROOT_PASSWORD="$MYSQL_PW" \
  -d mysql/mysql-server:latest

echo "    Waiting for MySQL to be healthy..."
until docker exec "$MYSQL_CONTAINER" mysqladmin ping -uroot -p"$MYSQL_PW" --silent 2>/dev/null; do
  printf "."
  sleep 3
done
echo " MySQL is ready!"

# ── 3. Create app DB user ────────────────────────────────────────────────────
echo ">>> Creating DB user: $DB_USER"
docker exec -i "$MYSQL_CONTAINER" mysql -uroot -p"$MYSQL_PW" <<EOF
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_USER_PW}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# ── 4. Import DB schema ──────────────────────────────────────────────────────
SCHEMA_PATH="./tooling-app/html/tooling_db_schema.sql"
if [ -f "$SCHEMA_PATH" ]; then
  echo ">>> Importing database schema from $SCHEMA_PATH"
  docker exec -i "$MYSQL_CONTAINER" mysql -uroot -p"$MYSQL_PW" < "$SCHEMA_PATH"
else
  echo "    WARNING: Schema file not found at $SCHEMA_PATH — skipping import."
  echo "    Clone the tooling repo and place tooling_db_schema.sql in tooling-app/html/"
fi

# ── 5. Build Tooling app image ───────────────────────────────────────────────
echo ">>> Building Tooling app image: $APP_IMAGE"
docker build -t "$APP_IMAGE" ./tooling-app

# ── 6. Run the Tooling app container ─────────────────────────────────────────
echo ">>> Starting Tooling app container..."
docker run \
  --network "$NETWORK_NAME" \
  -p "${APP_HOST_PORT}:80" \
  -it \
  "$APP_IMAGE"

echo ""
echo "✅  Done! Open http://localhost:${APP_HOST_PORT} in your browser."
echo "    Default login: test@mail.com / 12345"
