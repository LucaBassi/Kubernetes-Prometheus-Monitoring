# based on the official image
FROM influxdb:1.8
#ADD influxdb/influxdb.conf /etc/influxdb
COPY init.iql  /docker-entrypoint-initdb.d/
