#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

rand() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
  else
    python3 -c 'import secrets; print(secrets.token_hex(32))'
  fi
}

if ! docker compose version >/dev/null 2>&1; then
  echo "error: Docker with the Compose v2 plugin is required." >&2
  exit 1
fi

if [ ! -f .env ]; then
  cp .env.example .env
  sed -i "s/^WEBUI_SECRET_KEY=$/WEBUI_SECRET_KEY=$(rand)/" .env
  sed -i "s/^SEARXNG_SECRET=$/SEARXNG_SECRET=$(rand)/" .env
  sed -i "s/^OPEN_TERMINAL_API_KEY=$/OPEN_TERMINAL_API_KEY=$(rand)/" .env
  chmod 600 .env
  echo "created .env with generated secrets."
fi

if ! grep -q '^OPENROUTER_API_KEY=..*' .env; then
  echo "next: set OPENROUTER_API_KEY in .env (https://openrouter.ai/keys)"
  echo "then: docker compose up -d   (add: --profile agents for the terminal)"
fi

# Install the `webui` launcher into ~/.local/bin (PATH entry, like opencode/orca).
mkdir -p "$HOME/.local/bin"
sed "s|^DIR=.*|DIR=\"$(pwd)\"|" scripts/webui > "$HOME/.local/bin/webui"
chmod +x "$HOME/.local/bin/webui"
echo "installed launcher: webui  (status|up|down|logs|open)"
