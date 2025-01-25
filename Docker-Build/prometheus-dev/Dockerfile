FROM prom/prometheus

ADD config_files/prometheus.yml /etc/prometheus
ADD config_files/rules.yml /etc/prometheus
ADD config_files/web.yml /etc/prometheus

EXPOSE 9090
