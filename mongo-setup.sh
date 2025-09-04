#!/bin/bash

set -e

# Step 1: Copy .env.example → .env if missing
if [ ! -f ".env" ]; then
  echo "Creating .env file from .env.example..."
  cp .env.example .env
  cp app/.env.example app/.env
fi

# Step 2: Ask user for replica set name
read -p "Enter replica set name [default: lucy-mongo]: " REPLICA_NAME
if [ -z "$REPLICA_NAME" ]; then
  REPLICA_NAME="lucy-mongo"
fi

# Update or append MONGO_REPLICA_SET in .env
if grep -q "^MONGO_REPLICA_SET=" .env; then
  sed -i.bak "s/^MONGO_REPLICA_SET=.*/MONGO_REPLICA_SET=${REPLICA_NAME}/" .env
  rm -f .env.bak
else
  echo "MONGO_REPLICA_SET=${REPLICA_NAME}" >> .env
fi

echo "Replica set name set to: ${REPLICA_NAME}"

# Step 3: Ask user if they want to generate a keyfile
read -p "Generate mongo-keyfile? [Y/n]: " GEN_KEYFILE
GEN_KEYFILE=${GEN_KEYFILE:-Y} # default is Y if empty

if [[ "$GEN_KEYFILE" =~ ^[Yy]$ ]]; then
  mkdir -p conf/mongo
  if [ ! -f "conf/mongo/mongo-keyfile" ]; then
    echo "Generating mongo-keyfile..."
    openssl rand -base64 741 > conf/mongo/mongo-keyfile
    chown 999:999 conf/mongo/mongo-keyfile
    chmod 400 conf/mongo/mongo-keyfile
    echo "mongo-keyfile generated at conf/mongo/mongo-keyfile"
  else
    echo "mongo-keyfile already exists, skipping..."
  fi
else
  echo "Skipping keyfile generation."
fi

echo "✅ Setup complete. You can now run: docker compose up -d"