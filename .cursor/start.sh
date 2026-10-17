#!/usr/bin/env bash
# Cloud Agent start. Brings up Postgres, Redis, migrations, and the API on boot.
set -euo pipefail

cd /workspace

if ! pg_lsclusters --no-header | awk '{print $4}' | grep -qx online; then
  while read -r ver name _port status _; do
    if [[ "$status" != "online" ]]; then
      sudo pg_ctlcluster "$ver" "$name" start
    fi
  done < <(pg_lsclusters --no-header)
fi

for _ in $(seq 1 30); do
  pg_isready -q && break
  sleep 1
done
pg_isready -q

if ! redis-cli ping 2>/dev/null | grep -q PONG; then
  sudo redis-server /etc/redis/redis.conf --daemonize yes
fi
for _ in $(seq 1 30); do
  redis-cli ping 2>/dev/null | grep -q PONG && break
  sleep 1
done
redis-cli ping | grep -q PONG

sudo -u postgres psql -v ON_ERROR_STOP=1 <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'saleor') THEN
    CREATE ROLE saleor LOGIN PASSWORD 'saleor' SUPERUSER CREATEDB;
  ELSE
    ALTER ROLE saleor WITH LOGIN PASSWORD 'saleor' SUPERUSER CREATEDB;
  END IF;
END
$$;
SQL

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='saleor'" | grep -q 1; then
  sudo -u postgres createdb -O saleor saleor
fi

if [[ ! -f .env ]]; then
  cp .env.example .env
fi

uv run poe migrate
exec uv run poe start
