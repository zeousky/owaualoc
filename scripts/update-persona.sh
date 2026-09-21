#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd -P)
cd "$ROOT_DIR"

name=${1:-}
if [[ -z "$name" ]]; then
  echo "usage: ./scripts/update-persona.sh <rudeish|nerdish|flirty|chaotic|cute>" >&2
  exit 1
fi

file="personas/${name}.txt"
if [[ ! -f "$file" ]]; then
  echo "Unknown persona: $name" >&2
  exit 1
fi

echo "Persona file is live: $ROOT_DIR/$file"
echo "The running local bot reloads it on the next reply."
