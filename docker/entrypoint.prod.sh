set -euo pipefail

echo "[entrypoint] waiting for postgres..."
until pg_isready -h "${DATABASE_HOST:-postgres}" -p "${DATABASE_PORT:-5432}" -U "${DATABASE_USERNAME:-diario}" >/dev/null 2>&1; do
  sleep 2
done

echo "[entrypoint] waiting for redis..."
until ruby -ruri -e "u=ENV['REDIS_URL']; exit(1) if u.nil? || u.strip.empty?; URI.parse(u); exit(0)" >/dev/null 2>&1; do
  sleep 2
done

echo "[entrypoint] db:migrate..."
bundle exec rails db:migrate

echo "[entrypoint] assets:precompile..."
bundle exec rails assets:precompile

echo "[entrypoint] starting: $*"
exec "$@"
