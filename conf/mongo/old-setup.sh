#!/bin/bash
# Optional delay to ensure mongod is ready
sleep 5

echo "🔁 Starting Mongo replica set initialization..."

mongo --host "${MONGO_HOST:-lucy-mongo1}" \
  --username "${MONGO_INITDB_ROOT_USERNAME}" \
  --password "${MONGO_INITDB_ROOT_PASSWORD}" \
  --authenticationDatabase "admin" <<EOF
// ===== Mongo Shell Script =====

const rsName = "${MONGO_REPLICA_SET}";
const members = [
  { _id: 1, host: "lucy-mongo1:27017", priority: 3 },
  { _id: 2, host: "lucy-mongo2:27017", priority: 2 },
  { _id: 3, host: "lucy-mongo3:27017", priority: 1 },
];

function isReplicaAlreadyInit() {
  try {
    const s = rs.status();
    return !!s.set;
  } catch (e) {
    return false;
  }
}

if (isReplicaAlreadyInit()) {
  print("✅ Replica set already initialized as:", rs.status().set);
} else {
  print("🚀 Initializing replica set:", rsName);
  try {
    rs.initiate({ _id: rsName, version: 1, members });
  } catch (e) {
    if ((e.codeName === "AlreadyInitialized") || /already initialized/i.test(e.message)) {
      print("ℹ️ Replica set was already initialized by another node.");
    } else {
      throw e;
    }
  }
}

// === Wait until node becomes PRIMARY or SECONDARY ===
for (let i = 0; i < 30; i++) {
  const state = db.isMaster();
  if (state.ismaster || state.secondary) {
    print("✅ Node is now", state.ismaster ? "PRIMARY" : "SECONDARY");
    break;
  }
  print("⏳ Waiting for node to reach PRIMARY/SECONDARY state...");
  sleep(1000);
}

print("🏁 Replica set initialization script complete.");
EOF
