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

COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
