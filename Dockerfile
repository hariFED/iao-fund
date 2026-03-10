FROM node:22-slim

RUN apt-get update && apt-get install -y git curl ca-certificates python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw

RUN mkdir -p /data/.openclaw/workspace /data/.openclaw/canvas

ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/.openclaw/workspace
ENV OPENCLAW_GATEWAY_TOKEN=iao-fund-gateway-token-2026
ENV OPENCLAW_TRUSTED_PROXIES=*
ENV NODE_ENV=production
ENV PORT=8080

COPY . /data/.openclaw/workspace/

COPY openclaw.json /data/.openclaw/openclaw.json
COPY wrapper.js /wrapper.js

WORKDIR /data/.openclaw/workspace

EXPOSE 8080

CMD ["sh", "-c", "openclaw gateway run --allow-unconfigured --auth token --token iao-fund-gateway-token-2026 --port $PORT --bind lan"]
