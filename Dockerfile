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

# Copy workspace files
COPY . /data/.openclaw/workspace/

# Copy config to the state dir (this is where OpenClaw reads it from)
COPY openclaw.json /data/.openclaw/openclaw.json
COPY wrapper.js /wrapper.js

WORKDIR /data/.openclaw/workspace

EXPOSE 8080

# Start script that runs gateway and wrapper
RUN echo '#!/bin/bash\n\
echo "[start] Starting OpenClaw Gateway..."\n\
\n\
# Ensure config is in the right place\n\
cp /data/.openclaw/workspace/openclaw.json /data/.openclaw/openclaw.json\n\
\n\
# Start gateway in background\n\
openclaw gateway run --allow-unconfigured &\n\
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
