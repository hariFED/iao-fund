#!/bin/bash
set -e

echo "========================================="
echo "[start] OpenClaw Gateway Startup"
echo "========================================="

# --- 1. Create required directories ---
mkdir -p /data/.openclaw/identity
mkdir -p /data/.openclaw/agents/main/agent
mkdir -p /data/.openclaw/credentials
mkdir -p /data/.openclaw/workspace

# --- 2. Copy all files from staging to volume (overwrite with latest deploy) ---
echo "[start] Syncing workspace files from deploy to volume..."
cp -rf /app/workspace/* /data/.openclaw/workspace/ 2>/dev/null || true
cp -rf /app/workspace/.* /data/.openclaw/workspace/ 2>/dev/null || true
cp -f /app/openclaw.json /data/.openclaw/openclaw.json
cp -f /app/wrapper.js /wrapper.js
echo "[start] Workspace files synced."
ls -la /data/.openclaw/workspace/

# --- 3. Create .env file for OpenClaw to read API keys ---
# OpenClaw reads API keys from environment variables, NOT from config files
echo "[start] Writing /data/.openclaw/.env with API keys..."
cat > /data/.openclaw/.env << 'ENVEOF'
# Auto-generated at container startup
ENVEOF

if [ -n "$MOONSHOT_API_KEY" ]; then
    echo "MOONSHOT_API_KEY=${MOONSHOT_API_KEY}" >> /data/.openclaw/.env
    echo "[start] MOONSHOT_API_KEY written to .env (length: ${#MOONSHOT_API_KEY})"
else
    echo "[warn] MOONSHOT_API_KEY is NOT set in Railway environment variables!"
    echo "[warn] Go to Railway > Service > Variables and add MOONSHOT_API_KEY"
fi

if [ -n "$MOLTBOOK_API_KEY" ]; then
    echo "MOLTBOOK_API_KEY=${MOLTBOOK_API_KEY}" >> /data/.openclaw/.env
fi

# --- 4. Verify gateway token ---
if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
    echo "[start] OPENCLAW_GATEWAY_TOKEN is set (length: ${#OPENCLAW_GATEWAY_TOKEN})"
else
    echo "[warn] OPENCLAW_GATEWAY_TOKEN not set, using default from Dockerfile"
fi

# --- 5. Debug: show final config ---
echo "[start] Final openclaw.json:"
cat /data/.openclaw/openclaw.json
echo ""

echo "[start] Environment check:"
echo "  OPENCLAW_STATE_DIR=${OPENCLAW_STATE_DIR}"
echo "  OPENCLAW_WORKSPACE_DIR=${OPENCLAW_WORKSPACE_DIR}"
echo "  OPENCLAW_GATEWAY_TOKEN set: $([ -n "$OPENCLAW_GATEWAY_TOKEN" ] && echo 'yes' || echo 'no')"
echo "  MOONSHOT_API_KEY set: $([ -n "$MOONSHOT_API_KEY" ] && echo 'yes' || echo 'no')"
echo "  NODE_ENV=${NODE_ENV}"
echo ""

# --- 6. Start gateway ---
echo "[start] Starting OpenClaw Gateway on port 18789..."

# Token comes from OPENCLAW_GATEWAY_TOKEN env var (set in Dockerfile)
# --allow-unconfigured in case gateway.mode validation is strict
OPENCLAW_CONFIG_PATH=/data/.openclaw/openclaw.json \
OPENCLAW_HOME=/data/.openclaw \
OPENCLAW_CONFIG_DIR=/data/.openclaw \
  openclaw gateway run \
    --allow-unconfigured \
    --bind loopback \
    --auth token \
    --verbose &
GATEWAY_PID=$!

# Wait for gateway to be ready
echo "[start] Waiting for gateway to start (PID: $GATEWAY_PID)..."
sleep 8

# Check if gateway is running
if ! kill -0 $GATEWAY_PID 2>/dev/null; then
    echo "[start] ERROR: Gateway failed to start!"
    echo "[start] Check logs above for errors"
    exit 1
fi

echo "[start] Gateway is running!"

# --- 7. Start wrapper proxy on port 8080 ---
echo "[start] Starting wrapper proxy on port 8080..."
exec node /wrapper.js
