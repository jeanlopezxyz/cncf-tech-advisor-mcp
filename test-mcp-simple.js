#!/usr/bin/env node

const { spawn } = require('child_process');

console.log('Testing MCP Protocol...');

const mcp = spawn('npx', ['cncf-tech-advisor'], {
  stdio: ['pipe', 'pipe', 'pipe'],
  env: { ...process.env, 'JAVA_OPTS': '-XX:+UnlockDiagnosticVMOptions -XX:-LogEvents' }
});

let output = '';
let hasResponded = false;

mcp.stdout.on('data', (data) => {
  output += data.toString();
  if (!hasResponded && output.length > 0) {
    hasResponded = true;
    console.log('✅ MCP server responded with clean output');
    console.log('Output length:', output.length);
    if (output.includes('{') || output.includes('[')) {
      console.log('✅ JSON output detected');
    } else {
      console.log('Output preview:', output.substring(0, 200));
    }
    mcp.kill();
  }
});

mcp.stderr.on('data', (data) => {
  const error = data.toString();
  if (!error.includes('Unsafe') && !error.includes('WARNING')) {
    console.log('❌ MCP Error:', error);
  }
});

mcp.on('close', (code) => {
  if (!hasResponded) {
    console.log('❌ MCP server closed without responding');
  }
});

// Send initialize request
setTimeout(() => {
  const initMessage = JSON.stringify({
    jsonrpc: "2.0",
    id: 1,
    method: "initialize",
    params: {
      protocolVersion: "2024-11-05",
      capabilities: {},
      clientInfo: { name: "test", version: "1.0.0" }
    }
  });
  mcp.stdin.write(initMessage + '\n');
}, 500);

// Timeout after 10 seconds
setTimeout(() => {
  if (!hasResponded) {
    console.log('❌ MCP server timeout');
    mcp.kill();
  }
}, 10000);