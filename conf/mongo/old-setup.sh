#!/bin/bash
sleep 10

mongo --host lucy-mongo1 <<EOF
var config = {
    "_id": "lucy-mongo",
    "version": 1,
    "members": [
        {
            "_id": 1,
            "host": "lucy-mongo1:27017",
            "priority": 3
        },
        {
            "_id": 2,
            "host": "lucy-mongo2:27017",
            "priority": 2
        },
        {
            "_id": 3,
            "host": "lucy-mongo3:27017",
            "priority": 1
        }
    ]
};
rs.initiate(config, { force: true });
rs.status();
EOF