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
      findutils \
    ; \
    rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# Database: MariaDB (stable on Debian/CI; drop-in for MySQL)
# --------------------------------------------------
RUN set -eux; \
    apt-get update -o Acquire::Retries=5; \
    apt-get install -y --no-install-recommends mariadb-server; \
    rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# Kafka and Spark (optional components)
# --------------------------------------------------
WORKDIR /opt
RUN wget -q https://archive.apache.org/dist/kafka/3.7.0/kafka_2.13-3.7.0.tgz && \
    tar -xzf kafka_2.13-3.7.0.tgz && mv kafka_2.13-3.7.0 kafka && rm kafka_2.13-3.7.0.tgz

RUN wget -q https://archive.apache.org/dist/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz && \
    tar -xzf spark-3.5.1-bin-hadoop3.tgz && mv spark-3.5.1-bin-hadoop3 spark && rm spark-3.5.1-bin-hadoop3.tgz

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
# App + configs
# --------------------------------------------------
WORKDIR /app
COPY . /app
COPY nginx.conf /etc/nginx/nginx.conf
COPY prometheus.yml /opt/monitoring/prometheus/prometheus.yml

# Cache-bust when site changes (forces rebuild on CI)
ARG APP_HASH
RUN echo "APP_HASH=$APP_HASH"

# --------------------------------------------------
# Web content: remove default site, copy index/assets, copy Phase*.html
# --------------------------------------------------
RUN set -eux; \
    rm -f /etc/nginx/conf.d/default.conf || true; \
    rm -rf /usr/share/nginx/html/*; \
    cp /app/index.html /usr/share/nginx/html/index.html; \
    for d in images css js assets static; do \
      if [ -d "/app/$d" ]; then cp -r "/app/$d" "/usr/share/nginx/html/$d"; fi; \
    done; \
    mkdir -p /usr/share/nginx/html/phases; \
    find /app -maxdepth 1 -type f -name 'Phase*.html' -exec cp -t /usr/share/nginx/html/phases {} +

# --------------------------------------------------
# Environment (used by start script)
# --------------------------------------------------
ENV PATH="/opt/spark/bin:/opt/kafka/bin:${PATH}"
ENV MYSQL_ROOT_PASSWORD=root
ENV MYSQL_DATABASE=cloudcomputing
ENV MYSQL_USER=appuser
ENV MYSQL_PASSWORD=app123

# --------------------------------------------------
# Ports
# --------------------------------------------------
EXPOSE 80 9090 3000 8081 9092 3306 6379 4040

# --------------------------------------------------
# Entrypoint
# --------------------------------------------------
RUN chmod +x /app/start-all.sh
ENTRYPOINT ["/app/start-all.sh"]