# HOSTING.md - IAO.FUND Deployment Options

## Option 1: OpenClaw Gateway (Recommended)

**What it is:** The OpenClaw daemon that runs persistently, maintains session state, and executes heartbeats.

**How it works:**
- Gateway runs as a system service (systemd, launchd, or Windows service)
- Maintains persistent connection to AI providers
- Handles cron jobs and heartbeats automatically
- Survives reboots, network interruptions
- Memory files persist in `~/.openclaw/workspace/`

**Setup:**
```bash
# Install OpenClaw Gateway
npm install -g openclaw

# Configure gateway
openclaw gateway config

# Start as persistent service
openclaw gateway start

# Enable auto-start on boot
systemctl enable openclaw-gateway  # Linux
launchctl load ~/Library/LaunchAgents/openclaw.plist  # macOS
```

**Pros:**
- Native heartbeat support (every 5 minutes)
- Automatic memory persistence
- Built-in cron scheduling
- Web UI for monitoring
- Handles reconnections automatically

**Cons:**
- Requires always-on machine (VPS, home server, or cloud instance)
- Needs proper environment variable setup

---

## Option 2: VPS / Cloud Instance (Production)

**Recommended providers:**
- DigitalOcean Droplet ($6-12/month)
- Hetzner Cloud (~€5/month)
- AWS EC2 t3.micro (free tier eligible)
- Google Cloud e2-micro (free tier eligible)

**Setup:**
```bash
# 1. Provision Ubuntu 22.04+ server
# 2. Install Node.js 20+
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. Install OpenClaw
npm install -g openclaw

# 4. Set up workspace
mkdir -p ~/.openclaw/workspace
cd ~/.openclaw/workspace

# 5. Create all memory files (IDENTITY.md, SOUL.md, HEARTBEAT.md, etc.)
# 6. Set environment variables (see below)

# 7. Configure gateway
openclaw gateway config --port 8080

# 8. Create systemd service
sudo tee /etc/systemd/system/openclaw-gateway.service > /dev/null <<EOF
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=openclaw
Environment="IAO_API_BASE=https://iao-fund.vercel.app"
Environment="IAO_MANAGER_KEY=clawfunds-manager-secret-key-2026"
Environment="SOLANA_RPC_URL=https://api.devnet.solana.com"
Environment="PLATFORM_WALLET=8i3Mept58tXY85UeP1AeH3yS6DqD9GK4o8NsMapHG7w4"
Environment="IAO_PROGRAM_ID=DKhkk9pdyEE5XAvBjpjaB642RkpxJXqRqa7qTT6PmAuw"
Environment="X_API_KEY=ZSAgGt6pFC0oPNdgk8cdx0WpM"
Environment="X_API_SECRET=zSNs0YbQJf5wh1NmV0V7tb2k3jIddxbzmqn8sHXzGGBFr6umhs"
Environment="X_ACCESS_TOKEN=2031066007029317632-kPJypT0swKLjfxNBHo0eAmLDSRD7CN"
Environment="X_ACCESS_TOKEN_SECRET=caEKj7hmpF0172e3RI5efzm1cj3mQSO3gcVS66luqYjGs"
Environment="MOLTBOOK_API_KEY=moltbook_sk_dW_kCZqQa1-V_HVk7vqWEP5a8peNdm6Y"
Environment="DATABASE_URL=postgresql://neondb_owner:npg_hqcVG8DOmR6x@ep-plain-cherry-adyiqg2d-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"
WorkingDirectory=/home/openclaw/.openclaw/workspace
ExecStart=/usr/bin/openclaw gateway start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 9. Start service
sudo systemctl daemon-reload
sudo systemctl enable openclaw-gateway
sudo systemctl start openclaw-gateway

# 10. Check status
openclaw gateway status
```

---

## Option 3: Docker Container

**Dockerfile:**
```dockerfile
FROM node:20-slim

RUN npm install -g openclaw

# Create workspace
WORKDIR /app/.openclaw/workspace

# Copy memory files
COPY workspace/ ./

# Environment variables (use secrets management in production)
ENV IAO_API_BASE=https://iao-fund.vercel.app
ENV PLATFORM_WALLET=8i3Mept58tXY85UeP1AeH3yS6DqD9GK4o8NsMapHG7w4
ENV IAO_PROGRAM_ID=DKhkk9pdyEE5XAvBjpjaB642RkpxJXqRqa7qTT6PmAuw
# ... other env vars

EXPOSE 8080

CMD ["openclaw", "gateway", "start"]
```

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  iao-fund:
    build: .
    restart: always
    environment:
      - IAO_API_BASE=https://iao-fund.vercel.app
      - IAO_MANAGER_KEY=${IAO_MANAGER_KEY}
      - MOLTBOOK_API_KEY=${MOLTBOOK_API_KEY}
      - X_API_KEY=${X_API_KEY}
      - X_API_SECRET=${X_API_SECRET}
      - X_ACCESS_TOKEN=${X_ACCESS_TOKEN}
      - X_ACCESS_TOKEN_SECRET=${X_ACCESS_TOKEN_SECRET}
    volumes:
      - ./workspace:/app/.openclaw/workspace
    ports:
      - "8080:8080"
```

---

## Option 4: Home Server / Raspberry Pi

**For low-cost always-on operation:**

```bash
# On Raspberry Pi 4/5 or old laptop
# Install Node.js
wget -O - https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20

# Install OpenClaw
npm install -g openclaw

# Set up workspace and memory files
# ...

# Run with PM2 for process management
npm install -g pm2
pm2 start "openclaw gateway start" --name iao-fund
pm2 startup
pm2 save
```

**Pros:**
- One-time hardware cost
- Full control
- No monthly fees

**Cons:**
- Home network reliability
- Power outages
- Dynamic IP (need DDNS)

---

## Environment Variables Required

```bash
# IAO Platform
IAO_API_BASE=https://iao-fund.vercel.app
IAO_MANAGER_KEY=clawfunds-manager-secret-key-2026
PLATFORM_WALLET=8i3Mept58tXY85UeP1AeH3yS6DqD9GK4o8NsMapHG7w4
IAO_PROGRAM_ID=DKhkk9pdyEE5XAvBjpjaB642RkpxJXqRqa7qTT6PmAuw
SOLANA_RPC_URL=https://api.devnet.solana.com

# Twitter/X
X_API_KEY=ZSAgGt6pFC0oPNdgk8cdx0WpM
X_API_SECRET=zSNs0YbQJf5wh1NmV0V7tb2k3jIddxbzmqn8sHXzGGBFr6umhs
X_ACCESS_TOKEN=2031066007029317632-kPJypT0swKLjfxNBHo0eAmLDSRD7CN
X_ACCESS_TOKEN_SECRET=caEKj7hmpF0172e3RI5efzm1cj3mQSO3gcVS66luqYjGs

# Moltbook
MOLTBOOK_API_KEY=moltbook_sk_dW_kCZqQa1-V_HVk7vqWEP5a8peNdm6Y

# Database
DATABASE_URL=postgresql://neondb_owner:npg_hqcVG8DOmR6x@ep-plain-cherry-adyiqg2d-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require

# Optional
OPENCLAW_MODEL=moonshot/kimi-k2.5
OPENCLAW_WORKSPACE=/home/openclaw/.openclaw/workspace
```

---

## Memory Persistence Strategy

**Files that must persist:**
- `IDENTITY.md` — who I am
- `SOUL.md` — how I behave
- `USER.md` — who you are
- `TOOLS.md` — API keys and config
- `HEARTBEAT.md` — my duty cycle
- `SECURITY.md` — safety rules
- `MEMORY.md` — long-term memories
- `memory/YYYY-MM-DD.md` — daily logs

**Backup strategy:**
```bash
# Daily backup to git
0 2 * * * cd ~/.openclaw/workspace && git add . && git commit -m "backup $(date +%Y-%m-%d)" && git push
```

---

## Option 5: Railway (Easiest Deploy)

**What it is:** Railway is a platform that makes deploying from GitHub incredibly simple. Perfect for IAO.FUND.

**Setup:**

1. **Push your workspace to GitHub** (without secrets!)
```bash
# Create repo with just the memory files, not the env vars
git init
git add IDENTITY.md SOUL.md USER.md HEARTBEAT.md SECURITY.md HOSTING.md
git add memory/  # if you have any
git commit -m "IAO.FUND memory files"
git push origin main
```

2. **Create railway.json in your repo:**
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "openclaw gateway start",
    "healthcheckPath": "/status",
    "healthcheckTimeout": 100,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

3. **Create nixpacks.toml for Node.js:**
```toml
[phases.build]
cmds = ['npm install -g openclaw']

[phases.setup]
nixPkgs = ['nodejs_20']
```

4. **Deploy to Railway:**
   - Connect your GitHub repo
   - Railway auto-detects and deploys
   - Add environment variables in Railway dashboard
   - Done

**Environment Variables in Railway:**
Go to your project → Variables → Add all the env vars from the list above.

**Pros:**
- Zero-config deploys from Git
- Automatic HTTPS
- Persistent volumes (add a volume at `/root/.openclaw/workspace`)
- Easy environment variable management
- Auto-restart on crash
- Generous free tier (500 hours/month)

**Cons:**
- Free tier sleeps after inactivity (not ideal for 24/7)
- Need paid plan ($5-20/month) for always-on

**Pricing:**
- Free: 500 hours/month (good for testing)
- Starter: $5/month + usage (perfect for IAO.FUND)
- Pro: $20/month (higher limits)

**Volume Setup (Critical for Memory Persistence):**
1. In Railway dashboard → your service → Volumes
2. Add volume: Mount path = `/root/.openclaw/workspace`
3. Size: 1GB is plenty
4. This ensures memory files survive redeploys

---

## Monitoring

**Health checks:**
```bash
# Check gateway status
curl http://localhost:8080/status

# Check platform health
curl -H "x-manager-key: $IAO_MANAGER_KEY" $IAO_API_BASE/api/platform/health

# Check Moltbook status
curl -H "Authorization: Bearer $MOLTBOOK_API_KEY" https://www.moltbook.com/api/v1/agents/status
```

**Alerts:** Set up alerts for:
- Gateway down
- Platform health URGENT status
- Failed heartbeat executions

---

## Recommendation

**For production IAO.FUND:**
1. **Hetzner Cloud CX21** (€5.35/month) — reliable, cheap, good network
2. **Ubuntu 22.04 LTS**
3. **OpenClaw Gateway** with systemd
4. **Daily git backups** of workspace
5. **Uptime monitoring** (UptimeRobot free tier)

This gives you 24/7 operation with full memory persistence, automatic heartbeats every 5 minutes, and ~99.9% uptime.
