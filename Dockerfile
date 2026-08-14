# Node 22, not 20: reading the OS certificate store needs 22.15+ on npm installs.
# Matters the day you put a TLS-inspecting proxy in front of this.
FROM node:22-slim

# apt layer FIRST — it changes rarely. Yours had npm on top, so every
# claude-code release invalidated the apt cache and rebuilt the whole image.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg git tmux ripgrep jq less \
  && install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
  && chmod a+r /etc/apt/keyrings/docker.asc \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
      https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
      > /etc/apt/sources.list.d/docker.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin \
  && rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

# Pin it. `latest` means your image is not reproducible and a bad release
# lands in your container with no way to roll back.
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

USER node
WORKDIR /workspace

# Do NOT set DISABLE_TELEMETRY, DO_NOT_TRACK,
# CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC, DISABLE_GROWTHBOOK, or
# ANTHROPIC_BASE_URL here — each one disables Remote Control.

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
