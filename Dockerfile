FROM node:22-slim

RUN apt-get update && apt-get install -y git curl ca-certificates python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

# Install latest openclaw
RUN npm install -g openclaw@latest

# Create state directories
RUN mkdir -p /data/.openclaw/workspace /data/.openclaw/canvas /data/.openclaw/identity /data/.openclaw/credentials

# OpenClaw environment variables
ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/.openclaw/workspace
ENV OPENCLAW_HOME=/data/.openclaw
ENV OPENCLAW_CONFIG_DIR=/data/.openclaw
ENV OPENCLAW_GATEWAY_TOKEN=iao-fund-gateway-token-2026
ENV NODE_ENV=production
ENV PORT=8080

# Stage all files in /app (NOT on the volume path)
# start.sh will copy them to the volume at runtime
COPY . /app/workspace/
COPY openclaw.json /app/openclaw.json
COPY wrapper.js /app/wrapper.js
COPY start.sh /app/start.sh

WORKDIR /data/.openclaw/workspace

EXPOSE 8080

RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
