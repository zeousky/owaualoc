# owaua local

The same Discord hangout bot, set up to run on this laptop instead of a remote host.

Ping it and it talks back. By default it tries to sound like a person in the server; `!human off` goes back to the usual hangout-bot voice. It keeps a little of your thread and recent lines from the channel. DMs are off by default. Personas are `rudeish` (default), `nerdish`, `flirty`, `chaotic`, and `cute`.

Replies are generated on this machine by [Qwen3.5-2B](https://huggingface.co/Qwen/Qwen3.5-2B) (Unsloth UD-Q6_K_XL) through llama.cpp. Nothing is sent to Gemini, Groq, or Cloudflare while local mode is on.

## This laptop

Ryzen 5 3500C, 4 cores / 8 threads, Radeon Vega graphics, 8 GB of RAM, CachyOS.

DeepGrove Maple does not fit. The 2-bit checkpoint is about 5 GB and wants around 7 GB while generating, and the system is already using most of that. There were no model weights on disk (the Hugging Face cache only had empty stubs), so this copy downloads a model that can actually stay in memory next to the OS and Discord.

Qwen3.5-2B at UD-Q6_K_XL is about 1.74 GB on disk. It is the strongest 2026 small model that leaves headroom on 8 GB. The 4B build starts around 2.6 GB and would push this machine into swap. The Vega GPU is not used: it has no memory of its own, so offloading would only steal RAM from the model.

llama.cpp is pinned to the four physical cores (`0,2,4,6`). Context is 4096 tokens, one request at a time, thinking mode off, and hangout replies capped at 160 tokens so a short Discord line comes back before the request times out.

## Run it

```sh
./scripts/install-local.sh
```

Put the Discord bot token in `.env` as `DISCORD_TOKEN`, then:

```sh
./scripts/run-bots.sh
```

That starts the local model server if it is not already up, then starts the bot. Stop the model with `./scripts/stop-local-ai.sh`.

The bot needs Message Content intent enabled in the Discord developer portal.

## Commands

`!help` prints these. 25 second cooldown.

- `!persona rudeish|nerdish|flirty|chaotic|cute`
- `!human on|off` — talk like a person (on by default), or the usual hangout-bot voice
- `!language <full name>|reset` — this server's reply language (Manage Server)
- `!music help`
- `!memory erase` — erase server memory (Manage Server)
- `!memory erase mine`
- `!reset all` — reset this bot in this server (Manage Server)
- `!owner's note`

Personas live in `personas/*.txt` and reload on the next reply. `./scripts/update-persona.sh rudeish` only checks that the local file is there.

MIT. Qwen3.5 weights are Apache 2.0.

Thanks [@Perplexity](https://github.com/perplexityai) for the Agent API
