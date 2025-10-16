# CloudComputing Project Dockerfile (nginx-based)
# Multi-service container with nginx (serving static site), Python, MySQL, Redis,
# Kafka (w/ ZooKeeper), Spark Mini, Grafana, Prometheus, and cAdvisor.
# Works with Docker and Podman.

FROM nginx:latest

LABEL maintainer="your-name@example.com"
LABEL description="Cloud Computing demo container with nginx + monitoring/analytics stack"

ENV DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------
# Install system packages and runtimes
# --------------------------------------------------
RUN apt-get update && apt-get install -y \
    wget curl git gnupg2 software-properties-common lsb-release \
    python3 python3-pip python3-venv \
    openjdk-11-jre-headless \
    mysql-server redis-server \
    adduser libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# Install Kafka and Spark Mini
# --------------------------------------------------
WORKDIR /opt

# Kafka
RUN wget -q https://archive.apache.org/dist/kafka/3.6.1/kafka_2.13-3.6.1.tgz && \
    tar -xzf kafka_2.13-3.6.1.tgz && mv kafka_2.13-3.6.1 kafka && rm kafka_2.13-3.6.1.tgz

# Spark
RUN wget -q https://archive.apache.org/dist/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz && \
    tar -xzf spark-3.5.1-bin-hadoop3.tgz && mv spark-3.5.1-bin-hadoop3 spark && rm spark-3.5.1-bin-hadoop3.tgz

ENV PATH="/opt/spark/bin:/opt/kafka/bin:$PATH"

# --------------------------------------------------
# Install Prometheus, Grafana, and cAdvisor
# --------------------------------------------------
RUN mkdir -p /opt/monitoring

# Prometheus
RUN wget -q https://github.com/prometheus/prometheus/releases/download/v2.54.0/prometheus-2.54.0.linux-amd64.tar.gz && \
    tar -xzf prometheus-2.54.0.linux-amd64.tar.gz && mv prometheus-2.54.0.linux-amd64 /opt/monitoring/prometheus && rm prometheus-2.54.0.linux-amd64.tar.gz

# Grafana
RUN wget -q https://dl.grafana.com/oss/release/grafana_11.1.0_amd64.deb && apt-get update && apt-get install -y ./grafana_11.1.0_amd64.deb && rm grafana_11.1.0_amd64.deb

# cAdvisor
RUN wget -q -O /usr/local/bin/cadvisor https://github.com/google/cadvisor/releases/download/v0.49.1/cadvisor && chmod +x /usr/local/bin/cadvisor

# --------------------------------------------------
# Copy app content and configs
# --------------------------------------------------
WORKDIR /app
COPY . /app

# Serve static site via nginx document root
RUN rm -rf /usr/share/nginx/html/* && \
    mkdir -p /usr/share/nginx/html && \
    cp -r /app/* /usr/share/nginx/html/

# Python libs (optional for clients/tools)
RUN pip install --no-cache-dir flask redis mysql-connector-python kafka-python pyspark prometheus-client

# Prometheus config
COPY prometheus.yml /opt/monitoring/prometheus/prometheus.yml

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Startup script orchestrates all services then execs nginx in foreground
COPY start-all.sh /usr/local/bin/start-all.sh
RUN chmod +x /usr/local/bin/start-all.sh

# --------------------------------------------------
# Expose ports
#   80    nginx (web)
#   9090  Prometheus
#   3000  Grafana
#   8081  cAdvisor
#   9092  Kafka
#   3306  MySQL
#   6379  Redis
#   4040  Spark UI
# --------------------------------------------------
EXPOSE 80 9090 3000 8081 9092 3306 6379 4040

# --------------------------------------------------
# Entrypoint
# --------------------------------------------------
CMD ["/usr/local/bin/start-all.sh"]
