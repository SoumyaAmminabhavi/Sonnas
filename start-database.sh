#!/usr/bin/env bash
# Use this script to start a docker container for a local development database

# TO RUN ON WINDOWS:
# 1. Install WSL (Windows Subsystem for Linux) - https://learn.microsoft.com/en-us/windows/wsl/install
# 2. Install Docker Desktop or Podman Deskop
# - Docker Desktop for Windows - https://docs.docker.com/docker-for-windows/install/
# - Podman Desktop - https://podman.io/getting-started/installation
# 3. Open WSL - `wsl`
# 4. Run this script - `./start-database.sh`

# On Linux and macOS you can run this script directly - `./start-database.sh`

# import env variables from .env
set -a
source .env

# Robustly parse DATABASE_URL using Node.js
DB_PASSWORD=$(node -e "try { console.log(new URL(process.argv[1]).password); } catch(e) { process.exit(1); }" "$DATABASE_URL")
DB_PORT=$(node -e "try { console.log(new URL(process.argv[1]).port || '5432'); } catch(e) { process.exit(1); }" "$DATABASE_URL")
DB_NAME=$(node -e "try { console.log(new URL(process.argv[1]).pathname.slice(1)); } catch(e) { process.exit(1); }" "$DATABASE_URL")

# Validate parsed values
if [ -z "$DB_PASSWORD" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ]; then
  echo -e "\033[31mError: Failed to parse DATABASE_URL.\033[0m"
  echo "Please check your .env file. Expected format: postgresql://user:password@host:port/dbname"
  echo "Current DATABASE_URL: $DATABASE_URL"
  exit 1
fi

DB_CONTAINER_NAME="$DB_NAME-postgres"


if ! [ -x "$(command -v docker)" ] && ! [ -x "$(command -v podman)" ]; then
  echo -e "Docker or Podman is not installed. Please install docker or podman and try again.\nDocker install guide: https://docs.docker.com/engine/install/\nPodman install guide: https://podman.io/getting-started/installation"
  exit 1
fi

# determine which docker command to use
if [ -x "$(command -v docker)" ]; then
  DOCKER_CMD="docker"
elif [ -x "$(command -v podman)" ]; then
  DOCKER_CMD="podman"
fi

if ! $DOCKER_CMD info > /dev/null 2>&1; then
  echo "$DOCKER_CMD daemon is not running. Please start $DOCKER_CMD and try again."
  exit 1
fi

if command -v nc >/dev/null 2>&1; then
  if nc -z localhost "$DB_PORT" 2>/dev/null; then
    echo "Port $DB_PORT is already in use."
    exit 1
  fi
else
  echo "Warning: Unable to check if port $DB_PORT is already in use (netcat not installed)"
  read -p "Do you want to continue anyway? [y/N]: " -r REPLY
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting."
    exit 1
  fi
fi

if [ "$($DOCKER_CMD ps -q -f name="$DB_CONTAINER_NAME")" ]; then
  echo "Database container '$DB_CONTAINER_NAME' already running"
  exit 0
fi

if [ "$($DOCKER_CMD ps -q -a -f name="$DB_CONTAINER_NAME")" ]; then
  $DOCKER_CMD start "$DB_CONTAINER_NAME"
  echo "Existing database container '$DB_CONTAINER_NAME' started"
  exit 0
fi

if [ "$DB_PASSWORD" = "password" ]; then
  echo "You are using the default database password"
  read -p "Should we generate a random password for you? [y/N]: " -r REPLY
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Please change the default password in the .env file and try again"
    exit 1
  fi
  # Generate a random URL-safe password
  DB_PASSWORD=$(openssl rand -base64 12 | tr '+/' '-_')
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS requires an empty string to be passed with the `i` flag
    sed -i '' "s#:password@#:$DB_PASSWORD@#" .env
  else
    sed -i "s#:password@#:$DB_PASSWORD@#" .env
  fi
fi

$DOCKER_CMD run -d \
  --name "$DB_CONTAINER_NAME" \
  -e POSTGRES_USER="postgres" \
  -e POSTGRES_PASSWORD="$DB_PASSWORD" \
  -e POSTGRES_DB="$DB_NAME" \
  -p "$DB_PORT":5432 \
  docker.io/postgres && echo "Database container '$DB_CONTAINER_NAME' was successfully created"
