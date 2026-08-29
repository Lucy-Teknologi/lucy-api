FROM mongo:7.0

COPY ./conf/mongo/mongo-keyfile /data/configdb/mongo-keyfile

RUN chmod 400 /data/configdb/mongo-keyfile \
    && chown 999:999 /data/configdb/mongo-keyfile