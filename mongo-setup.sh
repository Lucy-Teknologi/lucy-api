#!/bin/bash

set -euo pipefail

ENV_FILE=".env"
APP_ENV_FILE="app/.env"
KEYFILE_PATH="conf/mongo/mongo-keyfile"

echo "🚀 MongoDB Replica Set Setup"

# Create .env if missing
if [ ! -f "$ENV_FILE" ]; then
    echo "📄 Creating .env from .env.example..."
    cp .env.example "$ENV_FILE"
fi

# Create app/.env if missing
if [ ! -f "$APP_ENV_FILE" ] && [ -f "app/.env.example" ]; then
    echo "📄 Creating app/.env from app/.env.example..."
    cp app/.env.example "$APP_ENV_FILE"
fi

# Ask for replica set name
read -rp "Enter replica set name [default: lucy-mongo]: " REPLICA_NAME
REPLICA_NAME=${REPLICA_NAME:-lucy-mongo}

# Validate replica set name
if ! [[ "$REPLICA_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "❌ Invalid replica set name."
    echo "   Allowed characters: letters, numbers, hyphens (-), underscores (_)"
    exit 1
fi

# Update or append MONGO_REPLICA_SET
if grep -q "^MONGO_REPLICA_SET=" "$ENV_FILE"; then
    sed -i.bak "s/^MONGO_REPLICA_SET=.*/MONGO_REPLICA_SET=${REPLICA_NAME}/" "$ENV_FILE"
    rm -f "${ENV_FILE}.bak"
else
    echo "MONGO_REPLICA_SET=${REPLICA_NAME}" >> "$ENV_FILE"
fi

echo "✅ Replica set name set to: ${REPLICA_NAME}"

# Generate keyfile
read -rp "Generate mongo-keyfile? [Y/n]: " GEN_KEYFILE
GEN_KEYFILE=${GEN_KEYFILE:-Y}

if [[ "$GEN_KEYFILE" =~ ^[Yy]$ ]]; then

    mkdir -p "$(dirname "$KEYFILE_PATH")"

    if [ -d "$KEYFILE_PATH" ]; then
        echo "❌ ERROR: $KEYFILE_PATH is a directory."
        echo "   Remove it first:"
        echo "   rm -rf $KEYFILE_PATH"
        exit 1
    fi

    if [ ! -f "$KEYFILE_PATH" ]; then
        echo "🔑 Generating mongo-keyfile..."

        # MongoDB recommended keyfile generation
        openssl rand -base64 756 | tr -d '\n' > "$KEYFILE_PATH"

        chmod 400 "$KEYFILE_PATH"

        echo "✅ mongo-keyfile generated at $KEYFILE_PATH"
    else
        echo "ℹ️ mongo-keyfile already exists, skipping..."
    fi
else
    echo "ℹ️ Skipping keyfile generation."
fi

echo ""
echo "🎉 Setup complete."
echo "Run:"
echo "    docker compose up -d"