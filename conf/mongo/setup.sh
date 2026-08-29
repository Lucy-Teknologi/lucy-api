#!/bin/sh
set -e

echo "Waiting for MongoDB nodes..."

until mongosh --host lucy-mongo1:27017 --eval "db.runCommand({ping:1})" >/dev/null 2>&1
do
  echo "lucy-mongo1 is booting..."
  sleep 2
done

until mongosh --host lucy-mongo2:27017 --eval "db.runCommand({ping:1})" >/dev/null 2>&1
do
  echo "lucy-mongo2 is booting..."
  sleep 2
done

until mongosh --host lucy-mongo3:27017 --eval "db.runCommand({ping:1})" >/dev/null 2>&1
do
  echo "lucy-mongo3 is booting..."
  sleep 2
done

echo "All MongoDB nodes are responding."

echo "Waiting for root authentication..."

until mongosh \
  --host lucy-mongo1:27017 \
  -u "${MONGO_INITDB_ROOT_USERNAME}" \
  -p "${MONGO_INITDB_ROOT_PASSWORD}" \
  --authenticationDatabase admin \
  --eval "db.runCommand({ping:1})" >/dev/null 2>&1
do
  echo "Waiting for root user to become available..."
  sleep 2
done

echo "Root authentication successful."

echo "Initializing replica set..."

mongosh \
  --host lucy-mongo1:27017 \
  -u "${MONGO_INITDB_ROOT_USERNAME}" \
  -p "${MONGO_INITDB_ROOT_PASSWORD}" \
  --authenticationDatabase admin \
  --eval "
    try {
      rs.status();
      print('Replica set already initialized.');
    } catch (e) {
      if (e.codeName === 'NotYetInitialized') {
        rs.initiate({
          _id: '${MONGO_REPLICA_SET}',
          members: [
            { _id: 0, host: 'lucy-mongo1:27017' },
            { _id: 1, host: 'lucy-mongo2:27017' },
            { _id: 2, host: 'lucy-mongo3:27017' }
          ]
        });
        print('Replica set initialized.');
      } else {
        throw e;
      }
    }
  "

echo "Replica set configuration completed successfully!"