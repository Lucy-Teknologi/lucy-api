#!/bin/bash
sleep 5

mongosh --host lucy-mongo1 \
  --username "${MONGO_INITDB_ROOT_USERNAME}" \
  --password "${MONGO_INITDB_ROOT_PASSWORD}" \
  --authenticationDatabase "admin" <<'EOF'
const rsName = process.env.MONGO_REPLICA_SET;
const cfg = {
  _id: rsName,
  version: 1,
  members: [
    { _id: 1, host: "lucy-mongo1:27017", priority: 3 },
    { _id: 2, host: "lucy-mongo2:27017", priority: 2 },
    { _id: 3, host: "lucy-mongo3:27017", priority: 1 },
  ],
};

function alreadyInit() {
  try { const s = rs.status(); return !!s.set; } catch (_) { return false; }
}

if (alreadyInit()) {
  print("Replica set already initialized. Name:", rs.status().set);
} else {
  print("Initializing replica set:", rsName);
  try { rs.initiate(cfg); } 
  catch (e) {
    if ((e.codeName === "AlreadyInitialized") || /already initialized/i.test(e.message)) {
      print("Replica set was already initialized.");
    } else {
      throw e;
    }
  }
}

// wait until node is primary/secondary
for (let i = 0; i < 30; i++) {
  const isMaster = db.isMaster();
  if (isMaster.ismaster || isMaster.secondary) { 
    print("Node is now", isMaster.ismaster ? "PRIMARY" : "SECONDARY"); 
    break; 
  }
  sleep(1000);
}
EOF