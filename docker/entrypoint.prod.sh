set -euo pipefail

PG_HOST="${DATABASE_HOST:-postgres}"
PG_PORT="${DATABASE_PORT:-5432}"
PG_USER="${DATABASE_USERNAME:-diario}"
PG_DB="${DATABASE_NAME:-diario}"

echo "[entrypoint] waiting for postgres (${PG_HOST}:${PG_PORT}/${PG_DB})..."
until pg_isready -h "${PG_HOST}" -p "${PG_PORT}" -U "${PG_USER}" -d "${PG_DB}" >/dev/null 2>&1; do
  sleep 2
done

echo "[entrypoint] waiting for redis (${REDIS_URL:-unset})..."
until ruby -ruri -rsocket -rtimeout -e "
  u = ENV['REDIS_URL']
  exit(1) if u.nil? || u.strip.empty?
  uri = URI.parse(u)
  host = uri.host
  port = uri.port || 6379
  Timeout.timeout(2) { TCPSocket.new(host, port).close }
  exit(0)
" >/dev/null 2>&1; do
  sleep 2
done

if [[ \"${SKIP_DB_MIGRATE:-0}\" == \"1\" ]]; then
  echo \"[entrypoint] skipping db:migrate (SKIP_DB_MIGRATE=1)\"
else
  echo \"[entrypoint] db:migrate...\"
  bundle exec rails db:migrate
fi

if [[ \"${SKIP_ASSETS_PRECOMPILE:-0}\" == \"1\" ]]; then
  echo \"[entrypoint] skipping assets:precompile (SKIP_ASSETS_PRECOMPILE=1)\"
else
  echo \"[entrypoint] assets:precompile...\"
  bundle exec rails assets:precompile
fi

echo \"[entrypoint] starting: $*\"
exec \"$@\"
