#!/usr/bin/env bash
set -euo pipefail

base_url="${1:-http://127.0.0.1:8080}"
expected_version="${2:-dev}"

for attempt in {1..30}; do
  if curl -fsS --connect-timeout 1 --max-time 2 "$base_url/healthz" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

test "$(curl -fsS --max-time 5 "$base_url/healthz")" = "ok"
curl -fsS --max-time 5 "$base_url/" | grep -q 'Дипломный проект'
curl -fsS --max-time 5 "$base_url/version.json" |
  python3 -c 'import json,sys; actual=json.load(sys.stdin)["version"]; assert actual == sys.argv[1], (actual, sys.argv[1])' "$expected_version"
test "$(curl -sS --max-time 5 -o /dev/null -w '%{http_code}' "$base_url/this-page-does-not-exist")" = "404"
echo "Smoke tests passed: health, page, version, 404."
