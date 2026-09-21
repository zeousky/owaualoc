#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd -P)
cd "$ROOT_DIR"

ENV_FILE=${OWAUA_ENV_FILE:-"$ROOT_DIR/.env"}
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Runtime env file is missing: $ENV_FILE" >&2
  echo "Run ./scripts/install-local.sh" >&2
  exit 1
fi
export OWAUA_ENV_FILE="$ENV_FILE"
export PYTHONPATH="$ROOT_DIR/src/owaua${PYTHONPATH:+:$PYTHONPATH}"
export PATH="$ROOT_DIR/vendor/usr/bin:$ROOT_DIR/.venv/bin:$PATH"
export LD_LIBRARY_PATH="$ROOT_DIR/vendor/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

PYTHON=$ROOT_DIR/.venv/bin/python
if [[ ! -x "$PYTHON" ]]; then
  PYTHON=${OWAUA_PYTHON:-python3}
fi

if ! "$PYTHON" -c 'import discord, httpx, dotenv, PIL, nacl, yt_dlp' >/dev/null 2>&1; then
  echo "Python dependencies are missing. Run ./scripts/install-local.sh" >&2
  exit 1
fi
chmod 600 "$ENV_FILE"

local_only=${OWAUA_LOCAL_ONLY:-$(grep -E '^OWAUA_LOCAL_ONLY=' "$ENV_FILE" | tail -n 1 | cut -d= -f2- || true)}
case "$local_only" in
  1|true|yes|on|TRUE|YES|ON)
    OWAUA_ENV_FILE="$ENV_FILE" "$ROOT_DIR/scripts/start-local-ai.sh"
    ;;
esac

exec "$PYTHON" src/owaua/bot.py
