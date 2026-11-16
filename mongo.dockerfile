FROM mongo:7.0

COPY ./conf/mongo/mongo-keyfile /etc/mongo/mongo-keyfile

RUN chmod 400 /etc/mongo/mongo-keyfile \
    && chown 999:999 /etc/mongo/mongo-keyfile