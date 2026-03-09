const { execSync } = require('child_process');
const https = require('https');

const IAO_API_BASE = process.env.IAO_API_BASE || 'https://iao-fund.vercel.app';
const IAO_MANAGER_KEY = process.env.IAO_MANAGER_KEY;
const MOLTBOOK_API_KEY = process.env.MOLTBOOK_API_KEY;

function log(msg) {
  console.log(`[${new Date().toISOString()}] ${msg}`);
}

async function fetch(url, options = {}) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch {
          resolve(data);
        }
      });
    });
    req.on('error', reject);
    req.setTimeout(30000, () => reject(new Error('Timeout')));
  });
}

async function checkPlatformHealth() {
  try {
    const result = await fetch(`${IAO_API_BASE}/api/platform/health`, {
      headers: { 'x-manager-key': IAO_MANAGER_KEY }
    });
    log(`Platform health: ${result.data?.status || 'UNKNOWN'}`);
    
    if (result.data?.status === 'URGENT') {
      log('URGENT status detected - action required');
      // Handle urgent items
    }
    
    return result;
  } catch (err) {
    log(`Health check failed: ${err.message}`);
    return null;
  }
}

async function checkRounds() {
  try {
    const result = await fetch(`${IAO_API_BASE}/api/platform/rounds`, {
      headers: { 'x-manager-key': IAO_MANAGER_KEY }
    });
    const rounds = result.data?.rounds || [];
    log(`Active rounds: ${rounds.length}`);
    return rounds;
  } catch (err) {
    log(`Rounds check failed: ${err.message}`);
    return [];
  }
}

async function checkQueue(status) {
  try {
    const result = await fetch(`${IAO_API_BASE}/api/platform/queue?status=${status}`, {
      headers: { 'x-manager-key': IAO_MANAGER_KEY }
    });
    const projects = result.data?.projects || [];
    log(`${status} projects: ${projects.length}`);
    return projects;
  } catch (err) {
    log(`Queue check failed: ${err.message}`);
    return [];
  }
}

async function checkMoltbook() {
  if (!MOLTBOOK_API_KEY) {
    log('Moltbook API key not set, skipping');
    return;
  }
  
  try {
    const result = await fetch('https://www.moltbook.com/api/v1/home', {
      headers: { 'Authorization': `Bearer ${MOLTBOOK_API_KEY}` }
    });
    
    const unread = result.your_account?.unread_notification_count || 0;
    log(`Moltbook unread notifications: ${unread}`);
    
    if (unread > 0) {
      log('Moltbook activity detected - manual engagement needed');
    }
  } catch (err) {
    log(`Moltbook check failed: ${err.message}`);
  }
}

async function runHeartbeat() {
  log('=== Starting heartbeat cycle ===');
  
  // Priority 1-5: Platform checks
  const health = await checkPlatformHealth();
  if (!health) {
    log('Platform health check failed, skipping remaining checks');
    return;
  }
  
  const rounds = await checkRounds();
  const registered = await checkQueue('REGISTERED');
  const pending = await checkQueue('PENDING_REVIEW');
  const verifying = await checkQueue('UNDER_VERIFICATION');
  
  // Priority 6: Moltbook
  await checkMoltbook();
  
  // Summary
  const needsAttention = 
    health.data?.urgent?.length > 0 ||
    rounds.some(r => new Date(r.endTime) < new Date()) ||
    registered.length >= 3 ||
    pending.length > 0 ||
    verifying.length > 0;
  
  if (needsAttention) {
    log('ATTENTION: Items require action');
  } else {
    log('HEARTBEAT_OK: Nothing needs attention');
  }
  
  log('=== Heartbeat cycle complete ===');
}

// Run immediately, then every 5 minutes
runHeartbeat();
setInterval(runHeartbeat, 5 * 60 * 1000);

// Keep alive
log('IAO.FUND heartbeat service started');
