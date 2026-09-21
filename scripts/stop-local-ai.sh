#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd -P)
PID_FILE=${OWAUA_LOCAL_AI_PID:-$ROOT_DIR/data/llama-server.pid}

if [[ ! -f "$PID_FILE" ]]; then
  echo "No local model pid file at $PID_FILE"
  exit 0
fi

pid=$(cat "$PID_FILE")
if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
  kill "$pid"
  echo "Stopped local model server (pid $pid)"
else
  echo "Local model server was not running"
fi
rm -f "$PID_FILE"
