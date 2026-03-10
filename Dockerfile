FROM node:22-slim

RUN apt-get update && apt-get install -y git curl ca-certificates python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw

RUN mkdir -p /data/.openclaw/workspace /data/.openclaw/canvas

ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/.openclaw/workspace
ENV OPENCLAW_GATEWAY_TOKEN=iao-fund-gateway-token-2026
ENV NODE_ENV=production
ENV PORT=8080

# Copy config to app dir (volume will override /data/.openclaw at runtime)
COPY openclaw.json /app/openclaw.json

# Copy wrapper
COPY wrapper.js /wrapper.js

# Copy workspace files
COPY . /data/.openclaw/workspace/

WORKDIR /data/.openclaw/workspace

EXPOSE 8080

# Start script that copies config and runs gateway
RUN echo '#!/bin/bash\n\
echo "[start] Copying config to state dir..."\n\
cp /app/openclaw.json /data/.openclaw/openclaw.json\n\
echo "[start] Setting up auth profiles..."\n\
mkdir -p /data/.openclaw/agents/main/agent\n\
if [ -n "$MOONSHOT_API_KEY" ]; then\n\
  echo "{\\"version\\":1,\\"profiles\\":{\\"moonshot:default\\":{\\"provider\\":\\"moonshot\\",\\"mode\\":\\"api_key\\",\\"apiKey\\":\\"$MOONSHOT_API_KEY\\"}}}" > /data/.openclaw/agents/main/agent/auth-profiles.json\n\
  echo "[start] Auth profiles created with API key"\n\
fi\n\
echo "[start] Config check:"\n\
ls -la /data/.openclaw/openclaw.json\n\
cat /data/.openclaw/openclaw.json\n\
echo ""\n\
echo "[start] Starting OpenClaw Gateway..."\n\
\n\
# Start gateway in background with explicit config path\n\
OPENCLAW_CONFIG_PATH=/data/.openclaw/openclaw.json openclaw gateway run --allow-unconfigured &\n\
GATEWAY_PID=$!\n\
\n\
# Wait for gateway to be ready\n\
sleep 5\n\
\n\
# Check if gateway is running\n\
if ! kill -0 $GATEWAY_PID 2>/dev/null; then\n\
  echo "[start] Gateway failed to start!"\n\
  exit 1\n\
fi\n\
\n\
# Start wrapper on port 8080\n\
echo "[start] Starting wrapper on port 8080..."\n\
exec node /wrapper.js\n\
' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
