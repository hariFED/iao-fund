#!/bin/bash
set -e

# Explicitly export env vars from Railway
export MOONSHOT_API_KEY="${MOONSHOT_API_KEY}"
export MOLTBOOK_API_KEY="${MOLTBOOK_API_KEY}"

echo "[start] Copying config to state dir..."
cp /app/openclaw.json /data/.openclaw/openclaw.json

echo "[start] Setting up auth profiles..."
mkdir -p /data/.openclaw/agents/main/agent

echo "[debug] Checking env vars..."
echo "[debug] MOONSHOT_API_KEY raw: '${MOONSHOT_API_KEY}'"
if [ -z "$MOONSHOT_API_KEY" ]; then
    echo "[debug] MOONSHOT_API_KEY is NOT set (empty or undefined)"
    echo "[debug] All env vars with MOONSHOT:"
    env | grep -i moonshot || echo "(none found)"
else
    echo "[debug] MOONSHOT_API_KEY is set (length: ${#MOONSHOT_API_KEY})"
fi

if [ -n "$MOONSHOT_API_KEY" ]; then
    echo "[start] Creating auth-profiles.json..."
    printf '{"version":1,"profiles":{"moonshot:default":{"provider":"moonshot","mode":"api_key","apiKey":"%s"}}}' "$MOONSHOT_API_KEY" > /data/.openclaw/agents/main/agent/auth-profiles.json
    echo "[start] Auth profiles created"
    ls -la /data/.openclaw/agents/main/agent/auth-profiles.json
    echo "[start] Auth file contents (key hidden):"
    cat /data/.openclaw/agents/main/agent/auth-profiles.json | sed 's/sk-[a-zA-Z0-9]*/sk-***HIDDEN***/g'
    echo ""
else
    echo "[error] MOONSHOT_API_KEY not set! Cannot create auth profiles."
fi

echo "[start] Config check:"
ls -la /data/.openclaw/openclaw.json
cat /data/.openclaw/openclaw.json
echo ""

echo "[start] Starting OpenClaw Gateway..."

# Start gateway in background with explicit config path
OPENCLAW_CONFIG_PATH=/data/.openclaw/openclaw.json openclaw gateway run --allow-unconfigured &
GATEWAY_PID=$!

# Wait for gateway to be ready
sleep 5

# Check if gateway is running
if ! kill -0 $GATEWAY_PID 2>/dev/null; then
  echo "[start] Gateway failed to start!"
  exit 1
fi

# Start wrapper on port 8080
echo "[start] Starting wrapper on port 8080..."
exec node /wrapper.js
