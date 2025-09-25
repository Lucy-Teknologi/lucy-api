#!/bin/bash

set -e

ENV_FILE=".env"
KEYFILE_PATH="conf/mongo/mongo-keyfile"
MONGO_UID=999
MONGO_GID=999

# Step 1: Copy .env.example → .env if missing
if [ ! -f "$ENV_FILE" ]; then
  echo "📄 Creating .env file from .env.example..."
  cp .env.example "$ENV_FILE"
  cp app/.env.example app/.env 2>/dev/null || true
fi

# Step 2: Ask user for replica set name
read -p "Enter replica set name [default: lucy-mongo]: " REPLICA_NAME
REPLICA_NAME=${REPLICA_NAME:-lucy-mongo}

# Update or append MONGO_REPLICA_SET in .env
if grep -q "^MONGO_REPLICA_SET=" "$ENV_FILE"; then
  sed -i.bak "s/^MONGO_REPLICA_SET=.*/MONGO_REPLICA_SET=${REPLICA_NAME}/" "$ENV_FILE"
  rm -f "$ENV_FILE.bak"
else
  echo "MONGO_REPLICA_SET=${REPLICA_NAME}" >> "$ENV_FILE"
fi
echo "✅ Replica set name set to: ${REPLICA_NAME}"

# Step 3: Generate mongo-keyfile if requested
read -p "Generate mongo-keyfile? [Y/n]: " GEN_KEYFILE
GEN_KEYFILE=${GEN_KEYFILE:-Y}

if [[ "$GEN_KEYFILE" =~ ^[Yy]$ ]]; then
  mkdir -p conf/mongo

  # Prevent directory mistake
  if [ -d "$KEYFILE_PATH" ]; then
    echo "❌ ERROR: $KEYFILE_PATH is a directory. Please remove it (rm -rf $KEYFILE_PATH)."
    exit 1
  fi

  if [ ! -f "$KEYFILE_PATH" ]; then
    echo "🔑 Generating mongo-keyfile..."
    openssl rand -base64 756 > "$KEYFILE_PATH"
    chmod 400 "$KEYFILE_PATH"
    chown $MONGO_UID:$MONGO_GID "$KEYFILE_PATH" || true
    echo "✅ mongo-keyfile generated at $KEYFILE_PATH"
  else
    echo "ℹ️ mongo-keyfile already exists, skipping..."
  fi
else
  echo "ℹ️ Skipping keyfile generation."
fi

echo "🎉 Setup complete. You can now run: docker compose up -d"
