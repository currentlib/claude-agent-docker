#!/usr/bin/env bash
set -euo pipefail

# Seed an empty workspace from the baked-in base. Skipped if anything is there,
# so it never clobbers real work.
if [ -d /opt/base ] && [ -z "$(ls -A /workspace 2>/dev/null)" ]; then
  echo "entrypoint: seeding empty /workspace from /opt/base"
  cp -a /opt/base/. /workspace/
fi

# No credential copying. ~/.claude lives on the `claude-home` volume and you run
# `claude auth login` once inside the container.

# ~/.bashrc lives on the same volume, so a Dockerfile-baked alias would only
# take effect on a brand-new volume. Ensure it here instead, every start, so
# it applies whether the volume is fresh or already has state on it.
grep -q "^alias claude=" /home/node/.bashrc 2>/dev/null || \
  echo "alias claude='claude --dangerously-skip-permissions'" >> /home/node/.bashrc

if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  echo "entrypoint: WARNING — ANTHROPIC_API_KEY is set; Remote Control will refuse to start." >&2
fi

# `exec claude "$@"` bound the container's lifetime to one CLI process. Now the
# container just runs, and you attach:
#   docker compose exec agent bash
#   claude
exec "$@"
