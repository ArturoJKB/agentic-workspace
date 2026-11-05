# Agentic Workspace

A small, reproducible kit for a self-hosted **open-source agentic workspace**:
AI chat + citations, iterative deep research, and a sandboxed agent terminal
over your codebase — three containers, one `.env`, no vendor lock-in.

```
 you ──> Open WebUI (:8080)  chat, RAG, agents, arena
              │
              ├─ OpenRouter (any provider/model: Qwen, DeepSeek, Kimi, GLM, …)
              ├─ SearXNG (:8888)  keyless web search backend (cited answers)
              └─ Open Terminal (:8000, optional profile)  shell sandbox that
                   sees your project read-only at /workspace
```

Everything binds to `127.0.0.1`. Nothing leaves your machine except model API
calls and search queries made on your behalf.

## Quick start

Requirements: Docker with the Compose v2 plugin, ~3 GB free RAM.

```bash
git clone https://github.com/ArturoJKB/agentic-workspace.git
cd agentic-workspace
./scripts/bootstrap.sh          # creates .env with generated secrets
$EDITOR .env                    # paste your OPENROUTER_API_KEY
docker compose up -d            # chat + web search stack
open http://127.0.0.1:8080      # first account created = admin
```

Optionally also start the **agent terminal** (chat-over-your-code):

```bash
# either drop a project into ./sources/, or set AGENT_WORKSPACE_DIR in .env
docker compose --profile agents up -d
```

## Daily launcher

`bootstrap.sh` installs a `webui` command into `~/.local/bin` (same pattern as
`opencode`/`orca`) that manages the stack and opens the browser — it even
self-elevates into the `docker` group via `newgrp` if your shell session lacks it:

```bash
webui          # start everything (agents profile included), wait healthy, open browser
webui status   # container states
webui logs     # follow open-webui logs
webui down     # stop and remove containers
webui open     # just open the browser
```

## What is pre-configured

| Feature | How it is wired |
|---|---|
| OpenRouter models | `OPENAI_API_BASE_URL` + key from `.env`; model picker appears automatically |
| Web Search (cited answers) | `ENABLE_WEB_SEARCH` + `WEB_SEARCH_ENGINE=searxng`; toggle in the chat `+` menu |
| SearXNG engines | `searxng/settings.yml`: bing, brave, mojeek, wikipedia/wikidata, arxiv, reuters, hackernews (keyless). `duckduckgo` sometimes CAPTCHAs home IPs — the aggregator tolerates it |
| Deep Research | see one-time setup below |
| Model comparison / Arena | multi-select models in chat; Arena enabled (`ENABLE_EVALUATION_ARENA_MODELS`) |
| Agent Terminal | `open-terminal:slim` (profile `agents`), your project mounted **read-only** at `/workspace`; registered into Open WebUI via `TERMINAL_SERVER_CONNECTIONS` incl. `chat_uploads: filesystem` (files uploaded in a terminal chat land in the sandbox) |

## One-time: Deep Research (2 min, UI only)

The iterative research tool ships in the marketplace, not in this kit:

1. **Admin Panel → Settings → Tools → `+` → Get Tool from URL**, paste:
   `https://raw.githubusercontent.com/the-real-t30d0r/research-openwebui/main/code.json`
   Activate it, open it, and set its valve **SRNXG API BASE URL** to:
   `http://searxng:8080`
2. **Admin Panel → Settings → Prompts → `+` New Prompt**, command `research`,
   content:

   ```
   Perform iterative deep research on the TOPIC below using the `search_web`
   function from the Research tool (SearXNG powered).

   Process:
   1. Call `search_web` with the core topic.
   2. If evidence is thin or contradictory, call `search_web` again with a
      refined sub-question. Repeat until at least 5 solid sources.
   3. Write a final Markdown report: executive summary, findings by theme,
      contradictions/limitations, and a numbered citations section using only
      URLs returned by the tool. Never invent sources.

   TOPIC:
   ```

Then: new chat → activate **Research** (wrench menu) → type `/research`.
Tip: Web Search and the Research tool are alternative retrieval pipelines —
use one at a time (Web Search = deep on ~5 pages; Research = broad across
dozens of sources).

## Terminal chats (agent over your code)

With the `agents` profile up: new chat → `+` menu → **Terminal** ON.
Ask things like *"list /workspace and tell me what this project is"*. The
model runs real shell commands in the sandbox; your mounted project is
read-only. For editing code, use a dedicated coding agent (e.g. opencode) —
this kit is the chat/research layer, not an IDE.

## Security notes

- All ports are loopback-only. Do not expose `:8080`/`:8888`/`:8000` directly;
  put them behind a reverse proxy with TLS if you need remote access.
- The first account you create is the admin. Keep sign-up closed afterward.
- `OPEN_TERMINAL_API_KEY` guards the sandbox API; rotate by regenerating it
  in `.env` and re-running `docker compose up -d`.
- The agent terminal container mounts your project **read-only** on purpose.

## Update policy

Pinned: `open-webui:v0.13.0`. Rolling by upstream convention:
`searxng:latest`, `open-terminal:slim`. To upgrade Open WebUI, change the tag
and `docker compose up -d` (data persists in `./data/`).

## License

MIT — see [LICENSE](LICENSE). This kit glues together upstream projects
(Open WebUI, SearXNG, Open Terminal, the Research tool) whose licenses apply
to their own code.
