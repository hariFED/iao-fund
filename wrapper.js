const http = require('http');
const net = require('net');

const PORT = process.env.PORT || 8080;
const GATEWAY_HOST = '127.0.0.1';
const GATEWAY_PORT = 18789;

console.log(`[wrapper] Starting on 0.0.0.0:${PORT}`);
console.log(`[wrapper] Proxying to ${GATEWAY_HOST}:${GATEWAY_PORT}`);

// Headers added by reverse proxies that we should strip
// to make the gateway treat connections as local/trusted
const STRIP_HEADERS = [
  'x-forwarded-for',
  'x-forwarded-host',
  'x-forwarded-proto',
  'x-forwarded-port',
  'x-real-ip',
  'x-forwarded-server',
  'forwarded',
  'via'
];

// HTTP proxy
const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true, ts: Date.now() }));
    return;
  }

  const headers = { ...req.headers };
  for (const h of STRIP_HEADERS) delete headers[h];
  headers.host = `${GATEWAY_HOST}:${GATEWAY_PORT}`;

  const proxyReq = http.request({
    hostname: GATEWAY_HOST,
    port: GATEWAY_PORT,
    path: req.url,
    method: req.method,
    headers
  }, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });

  proxyReq.on('error', (err) => {
    console.error('[wrapper] HTTP error:', err.message);
    if (!res.headersSent) {
      res.writeHead(502, { 'Content-Type': 'text/plain' });
      res.end('Gateway unavailable');
    }
  });

  req.pipe(proxyReq);
});

// WebSocket proxy - transparent TCP forwarding
// The OpenClaw Control UI handles auth at the WebSocket message level
// (first message is a "connect" request with auth token)
// We just need to transparently forward the connection
server.on('upgrade', (req, socket, head) => {
  console.log('[wrapper] WS upgrade:', req.url, 'origin:', req.headers.origin);

  const gwSocket = net.connect(GATEWAY_PORT, GATEWAY_HOST, () => {
    // Build clean upgrade request - strip proxy headers so gateway
    // sees this as a local/trusted connection
    const headers = { ...req.headers };
    for (const h of STRIP_HEADERS) delete headers[h];
    headers.host = `${GATEWAY_HOST}:${GATEWAY_PORT}`;

    let raw = `${req.method} ${req.url} HTTP/${req.httpVersion}\r\n`;
    for (const [k, v] of Object.entries(headers)) {
      if (v != null) raw += `${k}: ${v}\r\n`;
    }
    raw += '\r\n';

    gwSocket.write(raw);
    if (head && head.length) gwSocket.write(head);

    gwSocket.pipe(socket);
    socket.pipe(gwSocket);

    gwSocket.on('error', (e) => { console.error('[wrapper] gw err:', e.message); socket.destroy(); });
    socket.on('error', (e) => { console.error('[wrapper] client err:', e.message); gwSocket.destroy(); });
    gwSocket.on('close', () => socket.end());
    socket.on('close', () => gwSocket.end());
  });

  gwSocket.on('error', (err) => {
    console.error('[wrapper] connect err:', err.message);
    socket.destroy();
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[wrapper] Listening on 0.0.0.0:${PORT}`);
});

server.on('error', (err) => {
  console.error('[wrapper] Server error:', err);
});
