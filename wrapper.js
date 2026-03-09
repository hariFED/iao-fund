const http = require('http');
const https = require('https');
const net = require('net');
const url = require('url');

const PORT = process.env.PORT || 8080;
const GATEWAY_HOST = '127.0.0.1';
const GATEWAY_PORT = 18789;

console.log(`[wrapper] Starting on 0.0.0.0:${PORT}`);
console.log(`[wrapper] Proxying to ${GATEWAY_HOST}:${GATEWAY_PORT}`);

// Simple HTTP proxy server
const server = http.createServer((req, res) => {
  // Health check endpoint
  if (req.url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true, service: 'iao-fund-wrapper' }));
    return;
  }

  // Proxy HTTP requests to gateway
  const options = {
    hostname: GATEWAY_HOST,
    port: GATEWAY_PORT,
    path: req.url,
    method: req.method,
    headers: {
      ...req.headers,
      host: `${GATEWAY_HOST}:${GATEWAY_PORT}`,
    }
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

// Handle WebSocket upgrade
server.on('upgrade', (req, socket, head) => {
  console.log('[wrapper] WebSocket upgrade request:', req.url);
  
  const options = {
    hostname: GATEWAY_HOST,
    port: GATEWAY_PORT,
    path: req.url,
    method: req.method,
    headers: {
      ...req.headers,
      host: `${GATEWAY_HOST}:${GATEWAY_PORT}`,
    }
  };

  const proxyReq = http.request(options);
  
  proxyReq.on('error', (err) => {
    console.error('[wrapper] WS upgrade error:', err.message);
    socket.destroy();
  });

  proxyReq.on('response', (res) => {
    // If we get a response instead of upgrade, something went wrong
    console.error('[wrapper] Expected upgrade but got response:', res.statusCode);
    socket.destroy();
  });

  proxyReq.on('upgrade', (res, proxySocket, proxyHead) => {
    console.log('[wrapper] WebSocket upgraded successfully');
    
    // Send upgrade response to client
    socket.write('HTTP/1.1 101 Switching Protocols\r\n' +
                 'Upgrade: websocket\r\n' +
                 'Connection: Upgrade\r\n' +
                 '\r\n');
    
    // Pipe sockets together
    proxySocket.pipe(socket);
    socket.pipe(proxySocket);
    
    if (proxyHead && proxyHead.length) {
      proxySocket.unshift(proxyHead);
    }
    if (head && head.length) {
      socket.unshift(head);
    }
  });

  proxyReq.end();
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[wrapper] Listening on 0.0.0.0:${PORT}`);
});

// Handle errors
server.on('error', (err) => {
  console.error('[wrapper] Server error:', err);
});
