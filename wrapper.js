const http = require('http');
const https = require('https');

const PORT = process.env.PORT || 8080;
const GATEWAY_TARGET = 'http://127.0.0.1:18789';

// Simple health check endpoint
const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true, service: 'iao-fund-wrapper' }));
    return;
  }
  
  // Proxy all other requests to the gateway
  const options = {
    hostname: '127.0.0.1',
    port: 18789,
    path: req.url,
    method: req.method,
    headers: req.headers
  };

  const proxyReq = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });

  proxyReq.on('error', (err) => {
    console.error('Proxy error:', err);
    res.writeHead(502, { 'Content-Type': 'text/plain' });
    res.end('Gateway not ready');
  });

  req.pipe(proxyReq);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[wrapper] Listening on 0.0.0.0:${PORT}`);
  console.log(`[wrapper] Proxying to ${GATEWAY_TARGET}`);
});
