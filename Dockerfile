# --------------------------------------------------
# CloudComputing Project - Unified Docker Image
# Base: NGINX (serves content from /usr/share/nginx/html)
# --------------------------------------------------
FROM nginx:1.25-bookworm

LABEL maintainer="CloudComputing Project"
ENV DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------
# Base dependencies
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
# Install MySQL 8.4 LTS
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
# Install Kafka and Spark
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
# Monitoring: Prometheus, Grafana, cAdvisor
# --------------------------------------------------
WORKDIR /opt/monitoring
RUN wget -q https://github.com/prometheus/prometheus/releases/download/v2.54.0/prometheus-2.54.0.linux-amd64.tar.gz && \
    tar -xzf prometheus-2.54.0.linux-amd64.tar.gz && \
    mv prometheus-2.54.0.linux-amd64 prometheus && \
    rm prometheus-2.54.0.linux-amd64.tar.gz

RUN apt-get update -o Acquire::Retries=5 && \
    wget -q https://dl.grafana.com/oss/release/grafana_11.1.0_amd64.deb && \
    apt-get install -y ./grafana_11.1.0_amd64.deb && \
    rm -rf /var/lib/apt/lists/* grafana_11.1.0_amd64.deb

# Install cAdvisor
ARG CADVISOR_VERSION=v0.53.0
RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
      amd64) CAD_ARCH="linux-amd64" ;; \
      arm64) CAD_ARCH="linux-arm64" ;; \
      armhf|arm) CAD_ARCH="linux-arm" ;; \
      s390x) CAD_ARCH="linux-s390x" ;; \
      *) echo "Unsupported arch: ${ARCH}"; exit 1 ;; \
    esac; \
    curl -fL --retry 5 -o /usr/local/bin/cadvisor \
      "https://github.com/google/cadvisor/releases/download/${CADVISOR_VERSION}/cadvisor-${CADVISOR_VERSION}-${CAD_ARCH}"; \
    chmod +x /usr/local/bin/cadvisor

# --------------------------------------------------
# Copy application files and monitoring configs
# --------------------------------------------------
WORKDIR /app
COPY . /app
COPY nginx.conf /etc/nginx/nginx.conf
COPY prometheus.yml /opt/monitoring/prometheus/prometheus.yml

# --------------------------------------------------
# ✅ Option A Permanent Fix
# Replace Nginx default site with our app’s index.html + assets
# --------------------------------------------------
RUN rm -rf /usr/share/nginx/html/* && \
    cp /app/index.html /usr/share/nginx/html/index.html && \
    if [ -d /app/images ]; then cp -r /app/images /usr/share/nginx/html/; fi && \
    if [ -d /app/css ]; then cp -r /app/css /usr/share/nginx/html/; fi && \
    if [ -d /app/js ]; then cp -r /app/js /usr/share/nginx/html/; fi && \
    rm -f /etc/nginx/conf.d/default.conf || true

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
# Entrypoint
# --------------------------------------------------
RUN chmod +x /app/start-all.sh
ENTRYPOINT ["/app/start-all.sh"]
# --------------------------------------------------
# CloudComputing Project - Unified Container
# Base: NGINX (serves /app via /usr/share/nginx/html)
# --------------------------------------------------
FROM nginx:1.25-bookworm

LABEL maintainer="CloudComputing Project"
ENV DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------
# Base deps (with retries; no MySQL yet)
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
# - Preseed the selection to mysql-8.4-lts to avoid any prompt
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

# cAdvisor (use correct architecture-specific binary name from releases)
ARG CADVISOR_VERSION=v0.53.0
# Map Debian arch to release suffix
RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
      amd64) CAD_ARCH="linux-amd64" ;; \
      arm64) CAD_ARCH="linux-arm64" ;; \
      armhf|arm) CAD_ARCH="linux-arm" ;; \
      s390x) CAD_ARCH="linux-s390x" ;; \
      *) echo "Unsupported arch: ${ARCH}"; exit 1 ;; \
    esac; \
    curl -fL --retry 5 -o /usr/local/bin/cadvisor \
      "https://github.com/google/cadvisor/releases/download/${CADVISOR_VERSION}/cadvisor-${CADVISOR_VERSION}-${CAD_ARCH}"; \
    chmod +x /usr/local/bin/cadvisor
# (If you only build on GH runners (amd64), you could simplify to .../cadvisor-${CADVISOR_VERSION}-linux-amd64)

# --------------------------------------------------
# Copy application + nginx config + monitoring
# --------------------------------------------------
WORKDIR /app
COPY . /app

COPY nginx.conf /etc/nginx/nginx.conf
COPY prometheus.yml /opt/monitoring/prometheus/prometheus.yml

# --------------------------------------------------
# Serve project files via Nginx web root
# --------------------------------------------------
RUN rm -rf /usr/share/nginx/html/*
COPY index.html /usr/share/nginx/html/index.html
COPY images /usr/share/nginx/html/images

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

# --------------------------------------------------
# CloudComputing Project - Unified Container (Docker)
# Base: NGINX (serves /app via /usr/share/nginx/html)
# --------------------------------------------------
FROM nginx:1.25-bookworm

LABEL maintainer="CloudComputing Project"
ENV DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------
# Base dependencies (no MySQL yet)
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
# Oracle MySQL APT repo and MySQL server install
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
# Kafka + Spark mini setup
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

RUN apt-get update -o Acquire::Retries=5 && \
    wget -q https://dl.grafana.com/oss/release/grafana_11.1.0_amd64.deb && \
    apt-get install -y ./grafana_11.1.0_amd64.deb && \
    rm -rf /var/lib/apt/lists/* grafana_11.1.0_amd64.deb

# cAdvisor binary (auto-arch detection)
ARG CADVISOR_VERSION=v0.53.0
RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
      amd64) CAD_ARCH="linux-amd64" ;; \
      arm64) CAD_ARCH="linux-arm64" ;; \
      armhf|arm) CAD_ARCH="linux-arm" ;; \
      s390x) CAD_ARCH="linux-s390x" ;; \
      *) echo "Unsupported arch: ${ARCH}"; exit 1 ;; \
    esac; \
    curl -fL --retry 5 -o /usr/local/bin/cadvisor \
      "https://github.com/google/cadvisor/releases/download/${CADVISOR_VERSION}/cadvisor-${CADVISOR_VERSION}-${CAD_ARCH}"; \
    chmod +x /usr/local/bin/cadvisor

# --------------------------------------------------
# Copy app files and monitoring configs
# --------------------------------------------------
WORKDIR /app
COPY . /app
COPY nginx.conf /etc/nginx/nginx.conf
COPY prometheus.yml /opt/monitoring/prometheus/prometheus.yml

# --------------------------------------------------
# ✅ Permanent fix — serve custom site via Nginx
# --------------------------------------------------
RUN rm -rf /usr/share/nginx/html/* && \
    cp /app/index.html /usr/share/nginx/html/index.html && \
    if [ -d /app/images ]; then cp -r /app/images /usr/share/nginx/html/; fi && \
    if [ -d /app/css ]; then cp -r /app/css /usr/share/nginx/html/; fi && \
    if [ -d /app/js ]; then cp -r /app/js /usr/share/nginx/html/; fi

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
