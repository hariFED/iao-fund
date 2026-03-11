const http = require('http');
const net = require('net');
const url = require('url');

const PORT = process.env.PORT || 8080;
const GATEWAY_HOST = '127.0.0.1';
const GATEWAY_PORT = 18789;
const GATEWAY_TOKEN = process.env.OPENCLAW_GATEWAY_TOKEN || 'iao-fund-gateway-token-2026';

console.log(`[wrapper] Starting on 0.0.0.0:${PORT}`);
console.log(`[wrapper] Proxying to ${GATEWAY_HOST}:${GATEWAY_PORT}`);

// Headers to strip (but keep Origin for CWS validation)
const PROXY_HEADERS = [
  'x-forwarded-for',
  'x-forwarded-host',
  'x-forwarded-proto',
  'x-forwarded-port',
  'x-real-ip',
  'x-forwarded-server',
  'forwarded',
  'via'
];

// Inject auth token into URL query string for OpenClaw WebSocket protocol
function injectTokenInUrl(originalUrl) {
  const parsed = url.parse(originalUrl, true);
  // OpenClaw expects token in connect.params.auth.token via query string
  parsed.query['auth.token'] = GATEWAY_TOKEN;
  // url.format uses `search` if present, so delete it to use `query`
  delete parsed.search;
  return url.format(parsed);
}

// Simple HTTP proxy server
const server = http.createServer((req, res) => {
  // Health check endpoint
  if (req.url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true, service: 'iao-fund-wrapper' }));
    return;
  }

  // Strip proxy headers but keep Origin
  const headers = { ...req.headers };
  for (const h of PROXY_HEADERS) {
    delete headers[h];
  }
  // Ensure host is set correctly for the gateway
  headers.host = `${GATEWAY_HOST}:${GATEWAY_PORT}`;
  // Also try Authorization header
  headers['authorization'] = `Bearer ${GATEWAY_TOKEN}`;

  // Proxy HTTP requests to gateway
  const options = {
    hostname: GATEWAY_HOST,
    port: GATEWAY_PORT,
    path: injectTokenInUrl(req.url),
    method: req.method,
    headers: headers
  };

  const proxyReq = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });

  proxyReq.on('error', (err) => {
    console.error('[wrapper] HTTP proxy error:', err.message);
    res.writeHead(502, { 'Content-Type': 'text/plain' });
    res.end('Gateway unavailable');
  });

  req.pipe(proxyReq);
});

// Handle WebSocket upgrade - use raw TCP forwarding
server.on('upgrade', (req, socket, head) => {
  console.log('[wrapper] WebSocket upgrade request:', req.url);
  console.log('[wrapper] Origin:', req.headers.origin);

  // Inject token into the WebSocket URL
  const targetUrl = injectTokenInUrl(req.url);
  console.log('[wrapper] Target URL with token:', targetUrl.replace(GATEWAY_TOKEN, '***'));

  // Create a raw TCP connection to the gateway
  const gatewaySocket = net.connect(GATEWAY_PORT, GATEWAY_HOST, () => {
    console.log('[wrapper] Connected to gateway, forwarding WebSocket');

    // Build the HTTP upgrade request, preserving Origin
    const headers = { ...req.headers };
    for (const h of PROXY_HEADERS) {
      delete headers[h];
    }
    headers.host = `${GATEWAY_HOST}:${GATEWAY_PORT}`;
    // Also set Authorization header as fallback
    headers['authorization'] = `Bearer ${GATEWAY_TOKEN}`;

    // Use the token-injected URL
    let upgradeRequest = `${req.method} ${targetUrl} HTTP/${req.httpVersion}\r\n`;
    for (const [key, value] of Object.entries(headers)) {
      if (value !== undefined && value !== null) {
        upgradeRequest += `${key}: ${value}\r\n`;
      }
    }
    upgradeRequest += '\r\n';

    console.log('[wrapper] Sending upgrade request (first 300 chars):', upgradeRequest.substring(0, 300));

    // Send the upgrade request
    gatewaySocket.write(upgradeRequest);

    // If there's initial data, send it
    if (head && head.length > 0) {
      gatewaySocket.write(head);
    }

    // Pipe data between sockets
    gatewaySocket.pipe(socket);
    socket.pipe(gatewaySocket);

    // Handle errors
    gatewaySocket.on('error', (err) => {
      console.error('[wrapper] Gateway socket error:', err.message);
      socket.destroy();
    });

    socket.on('error', (err) => {
      console.error('[wrapper] Client socket error:', err.message);
      gatewaySocket.destroy();
    });

    gatewaySocket.on('close', () => {
      console.log('[wrapper] Gateway socket closed');
      socket.end();
    });

    socket.on('close', () => {
      console.log('[wrapper] Client socket closed');
      gatewaySocket.end();
    });
  });

  gatewaySocket.on('error', (err) => {
    console.error('[wrapper] Failed to connect to gateway:', err.message);
    socket.destroy();
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[wrapper] Listening on 0.0.0.0:${PORT}`);
});

// Handle errors
server.on('error', (err) => {
  console.error('[wrapper] Server error:', err);
});
