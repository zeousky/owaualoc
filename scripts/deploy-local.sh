#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd -P)
cd "$ROOT_DIR"

ENV_FILE=${OWAUA_LOCAL_ENV_FILE:-"$ROOT_DIR/.env"}
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Local env file is missing: $ENV_FILE" >&2
  echo "Run ./scripts/install-local.sh" >&2
  exit 1
fi
chmod 600 "$ENV_FILE"

PYTHON=$ROOT_DIR/.venv/bin/python
if [[ ! -x "$PYTHON" ]]; then
  PYTHON=${OWAUA_PYTHON:-python3}
fi

echo "Checking Python dependencies..."
"$PYTHON" -m pip check

echo "Compiling the local runtime..."
OWAUA_ENV_FILE="$ENV_FILE" "$PYTHON" -m py_compile \
  src/owaua/ask.py src/owaua/bot.py src/owaua/cloudflare.py \
  src/owaua/memory.py src/owaua/music.py src/owaua/security.py \
  src/owaua/music_worker.py src/owaua/media_exec.py

if [[ "${OWAUA_RUN_LOCAL_TESTS:-0}" == "1" ]]; then
  empty=$(mktemp)
  OWAUA_ENV_FILE="$empty" OWAUA_LOCAL_ONLY=0 \
    OPENAI_API_KEY=test DEEPSEEK_API_KEY=test PERPLEXITY_API_KEY=test \
    GROQ_API_KEY=test MISTRAL_API_KEY=test \
    PYTHONPATH="$ROOT_DIR/src/owaua:$ROOT_DIR/tests" "$PYTHON" -m unittest -q \
    test_ask test_bot_helpers test_cloudflare test_memory \
    test_channel_commands test_music_attachments test_security
  rm -f "$empty"
fi

echo "Local runtime checks passed."
echo "Start it with: ./scripts/run-bots.sh"
