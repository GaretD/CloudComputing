#!/usr/bin/env bash
set -euo pipefail

echo "[init] Starting CloudComputing stack..."

# --- MariaDB/MySQL (run as mysql user)
if command -v mysqld >/dev/null 2>&1; then
  echo "[mysql] preparing directories..."
  install -d -o mysql -g mysql /var/run/mysqld
  chown -R mysql:mysql /var/lib/mysql || true

  # Initialize data dir if empty
  if [ ! -d /var/lib/mysql/mysql ]; then
    echo "[mysql] initializing data directory..."
    if command -v mariadb-install-db >/dev/null 2>&1; then
      mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
    else
      mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql >/dev/null 2>&1 || true
    fi
  fi

  echo "[mysql] starting mysqld..."
  mysqld --user=mysql --daemonize || echo "[mysql] WARNING: mysqld failed to start (continuing)"
fi

# --- Redis (non-fatal)
if command -v redis-server >/dev/null 2>&1; then
  echo "[redis] starting..."
  redis-server --daemonize yes || echo "[redis] WARNING: failed (continuing)"
fi

# --- Prometheus (optional)
if [ -x /opt/monitoring/prometheus/prometheus ]; then
  echo "[prometheus] starting..."
  nohup /opt/monitoring/prometheus/prometheus \
    --config.file=/opt/monitoring/prometheus/prometheus.yml \
    --storage.tsdb.path=/opt/monitoring/prometheus/data \
    >/var/log/prometheus.log 2>&1 &
fi

# --- Grafana (optional)
if command -v grafana-server >/dev/null 2>&1; then
  echo "[grafana] starting..."
  nohup grafana-server --homepath=/usr/share/grafana >/var/log/grafana.log 2>&1 &
fi

# --- Kafka/Spark (optional; enable if needed)
# if [ -x /opt/kafka/bin/kafka-server-start.sh ]; then
#   echo "[kafka] starting..."
#   nohup /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties >/var/log/kafka.log 2>&1 &
# fi

echo "[nginx] starting in foreground on :80..."
exec nginx -g 'daemon off;'
