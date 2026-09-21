#!/usr/bin/env bash
# Install the local runtime for this laptop. No sudo: llama.cpp is unpacked
# under vendor/, and the model is downloaded into models/.
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd -P)
cd "$ROOT_DIR"

GGML_URL=https://cdn77.cachyos.org/repo/x86_64_v3/cachyos-extra-v3/ggml-0.23.0-2.1-x86_64_v3.pkg.tar.zst
LLAMA_URL=https://cdn77.cachyos.org/repo/x86_64_v3/cachyos-extra-v3/llama-cpp-0.4.0-2.1-x86_64_v3.pkg.tar.zst
MODEL_URL=https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-UD-Q6_K_XL.gguf
MODEL_PATH=$ROOT_DIR/models/Qwen3.5-2B-UD-Q6_K_XL.gguf
MODEL_BYTES=1864483072
LLAMA_BIN=$ROOT_DIR/vendor/usr/bin/llama-server

mkdir -p "$ROOT_DIR/models" "$ROOT_DIR/data" "$ROOT_DIR/vendor"

if [[ ! -x "$ROOT_DIR/.venv/bin/python" ]]; then
  python3 -m venv "$ROOT_DIR/.venv"
fi
"$ROOT_DIR/.venv/bin/python" -m pip install --upgrade pip
"$ROOT_DIR/.venv/bin/python" -m pip install -r "$ROOT_DIR/requirements.txt"

if [[ ! -x "$LLAMA_BIN" ]]; then
  tmp=$(mktemp -d)
  echo "Downloading the CPU build of llama.cpp..."
  curl -fL --retry 3 -o "$tmp/ggml.pkg.tar.zst" "$GGML_URL"
  curl -fL --retry 3 -o "$tmp/llama.pkg.tar.zst" "$LLAMA_URL"
  tar -I zstd -xf "$tmp/ggml.pkg.tar.zst" -C "$ROOT_DIR/vendor"
  tar -I zstd -xf "$tmp/llama.pkg.tar.zst" -C "$ROOT_DIR/vendor"
  rm -rf "$tmp"
fi

if [[ ! -x "$LLAMA_BIN" ]]; then
  echo "llama-server was not unpacked to $LLAMA_BIN" >&2
  exit 1
fi

current_bytes=0
if [[ -f "$MODEL_PATH" ]]; then
  current_bytes=$(stat -c '%s' "$MODEL_PATH")
fi
if [[ "$current_bytes" != "$MODEL_BYTES" ]]; then
  echo "Downloading Qwen3.5-2B UD-Q6_K_XL ($(numfmt --to=iec "$MODEL_BYTES" 2>/dev/null || echo "$MODEL_BYTES bytes"))..."
  curl -fL --retry 5 --retry-delay 2 -C - -o "$MODEL_PATH" "$MODEL_URL"
fi
if [[ "$(stat -c '%s' "$MODEL_PATH")" != "$MODEL_BYTES" ]]; then
  echo "Model download is incomplete: $MODEL_PATH" >&2
  exit 1
fi
if [[ -f "$ROOT_DIR/models/SHA256SUMS" ]]; then
  (
    cd "$ROOT_DIR/models"
    sha256sum -c SHA256SUMS
  )
fi

if [[ ! -f "$ROOT_DIR/.env" ]]; then
  cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
  chmod 600 "$ROOT_DIR/.env"
  echo "Created $ROOT_DIR/.env. Put your Discord bot token in DISCORD_TOKEN."
fi

chmod +x "$ROOT_DIR/scripts/"*.sh
echo
echo "Local runtime is installed."
echo "Model:  $MODEL_PATH"
echo "Server: $LLAMA_BIN"
echo
echo "Add DISCORD_TOKEN to .env, then start the bot with:"
echo "  ./scripts/run-bots.sh"
