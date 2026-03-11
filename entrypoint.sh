#!/bin/sh
set -e

# PolyON-Canvas(AFFiNE) 엔트리포인트
# Postgres/Redis 준비 대기 후 AFFiNE 서버 기동 (Storage-first: RustFS 설정은 초기 주입 또는 Admin Panel)

wait_for_port() {
  _host="$1"
  _port="$2"
  _name="$3"
  _attempt=0
  _max=30
  while ! WAIT_HOST="$_host" WAIT_PORT="$_port" node -e "
    const net = require('net');
    const host = process.env.WAIT_HOST;
    const port = parseInt(process.env.WAIT_PORT, 10) || 5432;
    const s = net.createConnection(port, host, () => { s.destroy(); process.exit(0); });
    s.on('error', () => process.exit(1));
  " 2>/dev/null; do
    _attempt=$((_attempt + 1))
    if [ "$_attempt" -ge "$_max" ]; then
      echo "대기 시간 초과: $_name" >&2
      exit 1
    fi
    echo "대기 중: $_name ($_attempt/$_max)"
    sleep 2
  done
}

# DATABASE_URL이 없고 DB_* 가 있으면 조합 (플랫폼이 개별 필드만 줄 때)
if [ -z "$DATABASE_URL" ] && [ -n "$DB_HOST" ] && [ -n "$DB_USERNAME" ] && [ -n "$DB_PASSWORD" ] && [ -n "$DB_DATABASE" ]; then
  export DATABASE_URL="postgresql://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT:-5432}/${DB_DATABASE}"
fi

# DB 호스트가 있으면 Postgres 대기
if [ -n "$DB_HOST" ] && [ -n "$DB_PORT" ]; then
  wait_for_port "$DB_HOST" "$DB_PORT" "PostgreSQL"
elif [ -n "$DATABASE_URL" ]; then
  # DATABASE_URL만 있는 경우 호스트/포트 추출 대기 생략 (선택: parse or skip)
  :
fi

# Redis 호스트가 있으면 Redis 대기
if [ -n "$REDIS_SERVER_HOST" ]; then
  _redis_port="${REDIS_SERVER_PORT:-6379}"
  wait_for_port "$REDIS_SERVER_HOST" "$_redis_port" "Redis"
fi

echo "AFFiNE을 기동합니다..."
exec "$@"
