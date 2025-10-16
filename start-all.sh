#!/usr/bin/env bash
set -euo pipefail

echo "[init] Starting multi-service Cloud Computing stack (nginx-based)..."

# ----------------------------
# MySQL
# ----------------------------
echo "[mysql] Preparing mysqld..."
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld || true

# MySQL init if needed
if [ ! -d /var/lib/mysql/mysql ]; then
  echo "[mysql] Initializing data directory..."
  mysqld --initialize-insecure
  chown -R mysql:mysql /var/lib/mysql
fi

echo "[mysql] Starting mysqld..."
mysqld --daemonize || (echo "[mysql] mysqld failed to start" && exit 1)

# ----------------------------
# Redis
# ----------------------------
echo "[redis] Starting redis-server..."
redis-server --daemonize yes

# ----------------------------
# ZooKeeper & Kafka
# ----------------------------
echo "[kafka] Starting ZooKeeper..."
/opt/kafka/bin/zookeeper-server-start.sh -daemon /opt/kafka/config/zookeeper.properties
sleep 5
echo "[kafka] Starting Kafka broker..."
/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties || true

# ----------------------------
# Spark
# ----------------------------
echo "[spark] Starting Spark history server..."
/opt/spark/sbin/start-history-server.sh || true

# ----------------------------
# Prometheus
# ----------------------------
echo "[prometheus] Starting Prometheus on :9090 ..."
/opt/monitoring/prometheus/prometheus --config.file=/opt/monitoring/prometheus/prometheus.yml --web.listen-address=:9090 &

# ----------------------------
# Grafana
# ----------------------------
echo "[grafana] Starting Grafana on :3000 ..."
/usr/sbin/grafana-server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini &

# ----------------------------
# cAdvisor
# ----------------------------
echo "[cadvisor] Starting cAdvisor on :8081 ..."
nohup cadvisor --port=8081 >/var/log/cadvisor.log 2>&1 &

# ----------------------------
# nginx (foreground)
# ----------------------------
echo "[nginx] Starting nginx (serving /usr/share/nginx/html) on :80 ..."
exec nginx -g "daemon off;"
