#!/bin/bash
set -e

# Explicitly export env vars from Railway
export MOONSHOT_API_KEY="${MOONSHOT_API_KEY}"
export MOLTBOOK_API_KEY="${MOLTBOOK_API_KEY}"

echo "[start] Copying config to state dir..."
cp /app/openclaw.json /data/.openclaw/openclaw.json

echo "[start] Setting up auth profiles and device identity..."
mkdir -p /data/.openclaw/agents/main/agent
mkdir -p /data/.openclaw/identity
mkdir -p /data/.openclaw/devices

# Create device identity so gateway doesn't reject WebSocket connections
DEVICE_ID="railway-$(hostname)-$(date +%s)"
echo "[start] Creating device identity: $DEVICE_ID"
cat > /data/.openclaw/identity/device.json << DEVEOF
{
  "deviceId": "$DEVICE_ID",
  "deviceName": "railway-production",
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
  "trusted": true
}
DEVEOF
cat > /data/.openclaw/identity/device-auth.json << AUTHEOF
{
  "deviceId": "$DEVICE_ID",
  "authorized": true,
  "autoApprove": true,
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
}
AUTHEOF

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
    echo "[start] Creating auth-profiles.json in multiple locations..."
    AUTH_JSON=$(printf '{"version":1,"profiles":{"moonshot:default":{"type":"api_key","provider":"moonshot","key":"%s"}}}' "$MOONSHOT_API_KEY")

    # Write to all possible locations OpenClaw may look for auth profiles
    mkdir -p /data/.openclaw/agents/main/agent
    mkdir -p /data/.openclaw/credentials
    mkdir -p /data/.openclaw/identity

    echo "$AUTH_JSON" > /data/.openclaw/agents/main/agent/auth-profiles.json
    echo "$AUTH_JSON" > /data/.openclaw/credentials/auth-profiles.json
    echo "$AUTH_JSON" > /data/.openclaw/auth-profiles.json

    echo "[start] Auth profiles created in multiple locations"
    echo "[start] Auth file contents (key hidden):"
    echo "$AUTH_JSON" | sed 's/sk-[a-zA-Z0-9]*/sk-***HIDDEN***/g'
    echo ""

    # Also patch the openclaw.json to include the API key directly in the provider config
    echo "[start] Patching openclaw.json with API key..."
    if command -v node &> /dev/null; then
        node -e "
            const fs = require('fs');
            const cfg = JSON.parse(fs.readFileSync('/data/.openclaw/openclaw.json', 'utf8'));
            if (cfg.models && cfg.models.providers && cfg.models.providers.moonshot) {
                cfg.models.providers.moonshot.apiKey = process.env.MOONSHOT_API_KEY;
                cfg.models.providers.moonshot.key = process.env.MOONSHOT_API_KEY;
            }
            if (cfg.auth && cfg.auth.profiles && cfg.auth.profiles['moonshot:default']) {
                cfg.auth.profiles['moonshot:default'].apiKey = process.env.MOONSHOT_API_KEY;
                cfg.auth.profiles['moonshot:default'].key = process.env.MOONSHOT_API_KEY;
            }
            fs.writeFileSync('/data/.openclaw/openclaw.json', JSON.stringify(cfg, null, 2));
            console.log('[start] openclaw.json patched with API key');
        "
    fi
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
