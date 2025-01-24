FROM prom/alertmanager
ADD config_files/alertmanager.yml /etc/alertmanager/
COPY templates/* /etc/alertmanager/templates/
EXPOSE 9093