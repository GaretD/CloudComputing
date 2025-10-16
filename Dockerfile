# --------------------------------------------------
# CloudComputing Project - Unified Container
# Base: NGINX (serves /app via /usr/share/nginx/html)
# --------------------------------------------------
FROM nginx:1.25-bookworm

LABEL maintainer="CloudComputing Project"
ENV DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------
# Base deps (with retries; no MySQL yet)
# NOTE: Use default-jre-headless on Debian 12 (bookworm) instead of openjdk-11-jre-headless.
# --------------------------------------------------
RUN set -eux; \
    apt-get update -o Acquire::Retries=5; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl wget git gnupg lsb-release debconf-utils \
      python3 python3-pip python3-venv \
      default-jre-headless \
      redis-server \
      adduser libfontconfig1 \
    ; \
    rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# Oracle MySQL APT repo via mysql-apt-config (noninteractive)
# - Preseed selection to mysql-8.4-lts to avoid interactive prompt
# - Then install mysql-server
# --------------------------------------------------
RUN set -eux; \
    wget -q -O /tmp/mysql-apt-config.deb https://repo.mysql.com/mysql-apt-config_0.8.33-1_all.deb; \
    echo "mysql-apt-config mysql-apt-config/select-server select mysql-8.4-lts" | debconf-set-selections; \
    dpkg -i /tmp/mysql-apt-config.deb; \
    rm -f /etc/apt/sources.list.d/mysql.list.save || true; \
    apt-get update -o Acquire::Retries=5; \
    apt-get install -y --no-install-recommends mysql-server; \
    rm -rf /var/lib/apt/lists/* /tmp/mysql-apt-config.deb

# --------------------------------------------------
# Kafka + Spark Mini Setup
# --------------------------------------------------
WORKDIR /opt
RUN wget -q https://archive.apache.org/dist/kafka/3.7.0/kafka_2.13-3.7.0.tgz && \
    tar -xzf kafka_2.13-3.7.0.tgz && \
    mv kafka_2.13-3.7.0 kafka && \
    rm kafka_2.13-3.7.0.tgz

RUN wget -q https://archive.apache.org/dist/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz && \
    tar -xzf spark-3.5.1-bin-hadoop3.tgz && \
    mv spark-3.5.1-bin-hadoop3 spark && \
    rm spark-3.5.1-bin-hadoop3.tgz

# --------------------------------------------------
# Prometheus + Grafana + cAdvisor
# --------------------------------------------------
WORKDIR /opt/monitoring
RUN wget -q https://github.com/prometheus/prometheus/releases/download/v2.54.0/prometheus-2.54.0.linux-amd64.tar.gz && \
    tar -xzf prometheus-2.54.0.linux-amd64.tar.gz && \
    mv prometheus-2.54.0.linux-amd64 prometheus && \
    rm prometheus-2.54.0.linux-amd64.tar.gz

# NOTE: This .deb is amd64. If you later build multi-arch (arm64),
# either pin the workflow to amd64 or fetch the arch dynamically.
RUN apt-get update -o Acquire::Retries=5 && \
    wget -q https://dl.grafana.com/oss/release/grafana_11.1.0_amd64.deb && \
    apt-get install -y ./grafana_11.1.0_amd64.deb && \
    rm -rf /var/lib/apt/lists/* grafana_11.1.0_amd64.deb

RUN wget -q https://github.com/google/cadvisor/releases/download/v0.47.0/cadvisor && \
    chmod +x cadvisor && mv cadvisor /usr/local/bin/

# --------------------------------------------------
# Copy application + nginx config + monitoring
# --------------------------------------------------
WORKDIR /app
COPY . /app
COPY nginx.conf /etc/nginx/nginx.conf
COPY prometheus.yml /opt/monitoring/prometheus/prometheus.yml

# --------------------------------------------------
# Environment variables
# --------------------------------------------------
ENV PATH="/opt/spark/bin:/opt/kafka/bin:${PATH}"
ENV MYSQL_ROOT_PASSWORD=root
ENV MYSQL_DATABASE=cloudcomputing
ENV MYSQL_USER=appuser
ENV MYSQL_PASSWORD=app123

# --------------------------------------------------
# Expose ports
# --------------------------------------------------
EXPOSE 80 9090 3000 8081 9092 3306 6379 4040

# --------------------------------------------------
# Startup script
# --------------------------------------------------
RUN chmod +x /app/start-all.sh
ENTRYPOINT ["/app/start-all.sh"]

