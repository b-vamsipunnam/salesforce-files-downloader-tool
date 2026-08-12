#!/usr/bin/env bash
set -euo pipefail

python /app/docker/healthcheck.py --startup
exec "$@"
