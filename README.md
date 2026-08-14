# Claude Agent Box

A containerized Claude Code agent that can't reach your host system or the
open internet — only the domains explicitly allowlisted in `squid.conf`.

## First run

```bash
docker compose up -d --build
docker compose exec agent bash
```

Inside the container:

```bash
env | grep -i anthropic     # must print NOTHING — an API key blocks OAuth login
claude                      # OAuth: open the printed URL on your host browser, paste the code back
```

Accept the workspace-trust prompt for `/workspace`, then `/exit`. Credentials and the
trust record land on the `claude-home` volume, so this is one-time and survives rebuilds.

## Day to day

```bash
docker compose up -d
docker compose exec agent bash
claude
```

The container runs `sleep infinity` as PID 1, so it stays up between sessions —
`docker compose exec` back in any time, no need to keep a terminal attached.

### Skipping permission prompts

Since the container can't reach anything outside `squid.conf`'s allowlist or touch
anything on the host outside `./workspace`, `claude` is aliased in `.bashrc` to always
run with `--dangerously-skip-permissions` — just run `claude` as normal, no prompts.

## Adding a domain

Agent tries to reach something not on the allowlist → request fails →

```bash
docker compose logs proxy | grep TCP_DENIED
```

Read the exact host, add a `dstdomain` line to `squid.conf`, then:

```bash
docker compose restart proxy
```

No rebuild needed — the config is a read-only bind mount. Resist wildcards:
`.amazonaws.com` to fix one S3 bucket opens every bucket on AWS.

## What's contained, what isn't

- `agent`: no capabilities (`cap_drop: [ALL]`), no privilege escalation, memory/CPU/pids
  capped, no network route except through squid's allowlist.
- `dind` (the Docker daemon the agent drives): runs `privileged: true` — standard for
  Docker-in-Docker, and the one component with a plausible path to host-kernel access if
  something inside it got exploited. Confined to the isolated network, no host ports.
- `./workspace` is bind-mounted read-write, by design — the agent edits files there.
  Nothing outside that path on your host is touched.

## Preview a running app

`preview` reverse-proxies ports 3000, 5173, and 8000→9900 from `dind` to your host, so
you can open an app the agent started without giving the agent itself a route out.

```
localhost:3000, localhost:5173, localhost:9900
```
