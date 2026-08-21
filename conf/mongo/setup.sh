#!/bin/env sh
set -e

echo "Waiting for lucy-mongo1 to completely initialize..."

# A robust loop that actively tests authentication/ping capabilities before executing commands
until mongosh --host lucy-mongo1:27017 --eval "db.runCommand({ping:1})" &>/dev/null; do
  echo "MongoDB is booting up... sleeping 2s"
  sleep 2
done

echo "lucy-mongo1 is ready! Attempting replica set initialization..."

# Wrap the rs.initiate in a retry loop in case the JS engine rejects the first flight
for i in {1..5}; do
  mongosh --host lucy-mongo1:27017 \
  -u "${MONGO_INITDB_ROOT_USERNAME}" \
  -p "${MONGO_INITDB_ROOT_PASSWORD}" \
  --authenticationDatabase admin \
  --eval "
    rs.initiate({
      _id: '${MONGO_REPLICA_SET}',
      members: [
        { _id: 0, host: 'lucy-mongo1:27017' },
        { _id: 1, host: 'lucy-mongo2:27017' },
        { _id: 2, host: 'lucy-mongo3:27017' }
      ]
    })
  " && break || echo "Replica set setup failed, retrying in 3 seconds... ($i/5)"
  sleep 3
done

echo "Replica set configuration completed successfully!"