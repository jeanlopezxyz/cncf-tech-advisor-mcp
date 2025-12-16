#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

console.log('Testing CNCF Tech Advisor MCP...');

// Test the MCP server
const mcp = spawn('npx', ['cncf-tech-advisor'], {
  stdio: ['pipe', 'pipe', 'pipe'],
  env: process.env
});

let timeout = setTimeout(() => {
  console.log('MCP server timeout');
  mcp.kill();
}, 5000);

mcp.stdout.on('data', (data) => {
  clearTimeout(timeout);
  console.log('MCP Response:', data.toString());
  mcp.kill();
});

mcp.stderr.on('data', (data) => {
  console.log('MCP Error:', data.toString());
});

mcp.on('close', (code) => {
  clearTimeout(timeout);
  console.log(`MCP process exited with code ${code}`);
});

// Send a simple JSON-RPC message to initialize
setTimeout(() => {
  const initMessage = JSON.stringify({
    jsonrpc: "2.0",
    id: 1,
    method: "initialize",
    params: {
      protocolVersion: "2024-11-05",
      capabilities: {},
      clientInfo: {
        name: "test-client",
        version: "1.0.0"
      }
    }
  });

  mcp.stdin.write(initMessage + '\n');
}, 1000);