# Owaua local operations

This copy runs on the laptop it was built for: a Ryzen 5 3500C with 8 GB of RAM. Chat stays on the machine. Discord is the only required network service.

## Project layout

- `src/owaua/` is the bot.
- `personas/`, `pfps/`, and `banners/` are runtime content.
- `models/Qwen3.5-2B-UD-Q6_K_XL.gguf` is the local model. It is not committed.
- `vendor/` is the unpacked llama.cpp 0.4.0 CPU build and ggml 0.23.0. It is not committed. `./scripts/install-local.sh` downloads both again.
- `data/` holds SQLite memory and the model-server log. Keep it.
- `scripts/install-local.sh` creates the virtualenv, unpacks llama.cpp, and downloads the model.
- `scripts/run-bots.sh` starts the model server, then the bot.
- `scripts/stop-local-ai.sh` stops the model server.
- `scripts/deploy-local.sh` type-checks the runtime and, with `OWAUA_RUN_LOCAL_TESTS=1`, runs the unit tests without loading `.env`.

## Model server

`scripts/start-local-ai.sh` listens on `127.0.0.1:8080` and serves an OpenAI-compatible API at `/v1`. The bot calls it as model name `owaua`. On this machine the server sits at about 1.9 GB of RAM, and a short reply came back in a few seconds with thinking mode off.

Settings baked in for this CPU:

| Setting | Value | Why |
| --- | --- | --- |
| Threads | 4 | One thread per physical core |
| CPU mask | `0x55` | Cores 0, 2, 4, and 6. SMT siblings stay free |
| Context | 4096 | Covers the persona prompt and a short history. The model's native 256k context does not fit |
| GPU layers | 0 | Vega graphics share system RAM |
| Parallel slots | 1 | A second generation would swap |
| KV cache | q8_0 | Smaller than f16, still accurate enough for chat |
| Reasoning | off | Thinking mode would spend the whole reply budget before any visible text |
| Load mode | mmap | The weights can be paged instead of pinned. `mlock` would freeze the rest of the desktop |

`BOT_MAX_INFLIGHT=1` matches the single slot.

Hangout replies request at most 160 tokens and wait up to 180 seconds. On this CPU a short reply should land well inside that. Full mode is capped at 512 tokens for the same reason.

## First start

```sh
./scripts/install-local.sh
```

Edit `.env` and set `DISCORD_TOKEN`. Then:

```sh
./scripts/run-bots.sh
```

Enable the Message Content intent on the bot application. Invite it with permission to read and send messages. Music also needs permission to speak in voice channels. FFmpeg is already on this machine. YouTube links need `deno` on `PATH`; the runtime check reports that if it is missing.

## Checks

```sh
OWAUA_RUN_LOCAL_TESTS=1 ./scripts/deploy-local.sh
```

Tests load an empty env file so the local `.env` cannot redirect them at the laptop model.

## What is not in this copy

The public website, the Cloudflare worker, and the Daki upload scripts are not part of running the bot here. The Python Cloudflare client remains, and it does nothing unless those keys are filled in and `OWAUA_LOCAL_ONLY` is turned off.
