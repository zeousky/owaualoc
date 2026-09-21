#!/usr/bin/env bash
# CPU llama.cpp server for this laptop: Ryzen 5 3500C (4 cores / 8 threads),
# 8 GB RAM, Vega iGPU left unused because it shares system memory.
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd -P)
ENV_FILE=${OWAUA_ENV_FILE:-"$ROOT_DIR/.env"}

env_value() {
  local key=$1
  [[ -f "$ENV_FILE" ]] || return 0
  sed -n -E "s/^${key}=([^#]*)#.*/\\1/p; s/^${key}=([^#]*)$/\\1/p" "$ENV_FILE" \
    | tail -n 1 | sed 's/[[:space:]]*$//'
}

BASE_URL=${OWAUA_LOCAL_BASE_URL:-$(env_value OWAUA_LOCAL_BASE_URL)}
BASE_URL=${BASE_URL:-http://127.0.0.1:8080/v1}
HOST=${OWAUA_LOCAL_AI_HOST:-$(env_value OWAUA_LOCAL_AI_HOST)}
HOST=${HOST:-127.0.0.1}
PORT=${OWAUA_LOCAL_AI_PORT:-$(env_value OWAUA_LOCAL_AI_PORT)}
PORT=${PORT:-8080}
MODEL_PATH=${OWAUA_LOCAL_AI_GGUF:-$(env_value OWAUA_LOCAL_AI_GGUF)}
MODEL_PATH=${MODEL_PATH:-$ROOT_DIR/models/Qwen3.5-2B-UD-Q6_K_XL.gguf}
ALIAS=${OWAUA_LOCAL_MODEL:-$(env_value OWAUA_LOCAL_MODEL)}
ALIAS=${ALIAS:-owaua}
THREADS=${OWAUA_LOCAL_AI_THREADS:-$(env_value OWAUA_LOCAL_AI_THREADS)}
THREADS=${THREADS:-4}
CTX=${OWAUA_LOCAL_AI_CTX:-$(env_value OWAUA_LOCAL_AI_CTX)}
CTX=${CTX:-4096}
# Physical cores on this chip are 0,2,4,6. Leave the SMT siblings for the OS.
CPU_MASK=${OWAUA_LOCAL_AI_CPU_MASK:-$(env_value OWAUA_LOCAL_AI_CPU_MASK)}
CPU_MASK=${CPU_MASK:-0x55}

LLAMA_SERVER=${OWAUA_LOCAL_AI_LLAMA:-$(env_value OWAUA_LOCAL_AI_LLAMA)}
LLAMA_SERVER=${LLAMA_SERVER:-$ROOT_DIR/vendor/usr/bin/llama-server}
LIB_DIR=$ROOT_DIR/vendor/usr/lib
# Arch installs CPU backends in /usr/lib/ggml. This unpacked copy is not on
# that path, and GGML_BACKEND_PATH loads one backend file, not a directory.
# Haswell matches this Zen+ chip (AVX2, no AVX-512).
BACKEND=$LIB_DIR/ggml/libggml-cpu-haswell.so
LOG_FILE=${OWAUA_LOCAL_AI_LOG:-$ROOT_DIR/data/llama-server.log}
PID_FILE=${OWAUA_LOCAL_AI_PID:-$ROOT_DIR/data/llama-server.pid}

if curl -fsS --max-time 2 "$BASE_URL/models" >/dev/null 2>&1; then
  echo "Local AI server is already running at $BASE_URL"
  exit 0
fi

if [[ ! -x "$LLAMA_SERVER" ]]; then
  echo "llama-server is missing ($LLAMA_SERVER). Run ./scripts/install-local.sh" >&2
  exit 1
fi
if [[ ! -f "$MODEL_PATH" ]]; then
  echo "Local model is missing: $MODEL_PATH" >&2
  echo "Run ./scripts/install-local.sh" >&2
  exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$PID_FILE")"
echo "Starting local Qwen3.5-2B at $BASE_URL (threads=$THREADS ctx=$CTX)..."
export LD_LIBRARY_PATH="$LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export GGML_BACKEND_PATH="$BACKEND"
nohup "$LLAMA_SERVER" \
  --model "$MODEL_PATH" \
  --alias "$ALIAS" \
  --host "$HOST" \
  --port "$PORT" \
  --threads "$THREADS" \
  --threads-batch "$THREADS" \
  --cpu-mask "$CPU_MASK" \
  --cpu-mask-batch "$CPU_MASK" \
  --ctx-size "$CTX" \
  --batch-size 512 \
  --ubatch-size 256 \
  --parallel 1 \
  --n-gpu-layers 0 \
  --fit off \
  --load-mode mmap \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --reasoning off \
  --jinja \
  >"$LOG_FILE" 2>&1 < /dev/null &
echo $! > "$PID_FILE"

for _ in $(seq 1 180); do
  if curl -fsS --max-time 2 "$BASE_URL/models" >/dev/null 2>&1; then
    echo "Local model server is ready at $BASE_URL"
    exit 0
  fi
  if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "llama-server exited during startup. See $LOG_FILE" >&2
    tail -n 50 "$LOG_FILE" >&2 || true
    exit 1
  fi
  sleep 1
done

echo "llama-server did not become ready. See $LOG_FILE" >&2
tail -n 50 "$LOG_FILE" >&2 || true
exit 1
