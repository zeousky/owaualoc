# Changelog

All notable releases of Owaua are documented here.

## [0.2.0] - 2026-09-22

Local-hosting build for the Ryzen 5 3500C laptop with 8 GB of RAM.

- Chat defaults to an on-device Qwen3.5-2B server instead of a hosted model API.
- llama.cpp is limited to the four physical cores, a 4096-token context, and one reply at a time.
- Local generations are capped and given a longer timeout so short Discord replies can finish on this CPU.
- FFmpeg's input whitelist includes `fd`, which this machine's FFmpeg uses for stdin audio.
- Thinking mode is disabled so the token budget is spent on the visible reply.
- Remote deploy helpers are not part of this copy.

## [0.1.0] - 2026-09-18

First packaged release of the Discord bot.

- Persona-driven Discord chat with per-user profile selection.
- Opt-in full mode with provider routing and bounded usage limits.
- Server memory, language profiles, reset, and owner security controls.
- Optional music playback with URL-only media handling.
- Local-only AI mode and Linux/CachyOS installation helpers.
- Cloudflare audit integration and security-focused CI checks.
- Reproducible source archives with SHA-256 checksums.
