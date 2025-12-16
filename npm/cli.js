#!/usr/bin/env node

/**
 * CNCF Tech Advisor MCP Server - NPM CLI Wrapper
 *
 * This wrapper script manages the lifecycle of the CNCF Tech Advisor MCP server.
 * It handles:
 * - Downloading the appropriate JAR or native binary
 * - Managing server startup and shutdown
 * - Providing stdio transport for MCP protocol communication
 * - Environment configuration and validation
 */

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const https = require('https');
const os = require('os');

// Configuration
const CONFIG = {
    version: '1.0.0',
    repo: 'jeanlopezxyz/cncf-tech-advisor-mcp',
    jarName: 'cncf-tech-advisor-mcp-1.0.0-runner.jar',
    nativeName: 'cncf-tech-advisor-mcp-1.0.0-runner',
    downloadUrl: 'https://github.com',
    installDir: path.join(os.homedir(), '.cncf-tech-advisor-mcp')
};

class CncfTechAdvisorServer {
    constructor() {
        this.serverProcess = null;
        this.isNative = this.detectNativeSupport();
    }

    /**
     * Detect if native binary is supported on this platform
     */
    detectNativeSupport() {
        const platform = os.platform();
        const arch = os.arch();

        const supportedPlatforms = {
            'linux': ['x64'],
            'darwin': ['x64', 'arm64'],
            'win32': ['x64']
        };

        return supportedPlatforms[platform]?.includes(arch) || false;
    }

    /**
     * Ensure the server binary is available
     */
    async ensureBinary() {
        const binaryPath = this.getBinaryPath();

        if (fs.existsSync(binaryPath)) {
            return binaryPath;
        }

        console.error('# CNCF Tech Advisor MCP Server');
        console.error('');
        console.error('Binary not found. Please install using one of these methods:');
        console.error('');
        console.error('## Option 1: Docker (Recommended)');
        console.error('```bash');
        console.error('docker run -i --rm -p 8080:8080 \\');
        console.error('  ghcr.io/jeanlopezxyz/cncf-tech-advisor-mcp');
        console.error('```');
        console.error('');
        console.error('## Option 2: Build from Source');
        console.error('```bash');
        console.error('git clone https://github.com/jeanlopezxyz/cncf-tech-advisor-mcp.git');
        console.error('cd cncf-tech-advisor-mcp');
        console.error('./mvnw package -DskipTests');
        console.error('```');
        console.error('');
        console.error('## Option 3: Download Pre-built Binary');
        console.error(`Visit: https://github.com/${CONFIG.repo}/releases`);
        console.error('');

        process.exit(1);
    }

    /**
     * Get the path to the binary file
     */
    getBinaryPath() {
        const filename = this.isNative ? CONFIG.nativeName : CONFIG.jarName;
        return path.join(CONFIG.installDir, filename);
    }

    /**
     * Start the MCP server
     */
    async start() {
        const binaryPath = await this.ensureBinary();

        // Prepare environment
        const env = {
            ...process.env,
            QUARKUS_MCP_SERVER_STDIO_ENABLED: 'true',
            QUARKUS_MCP_SERVER_HTTP_ROOT_PATH: '/mcp',
            QUARKUS_LOG_LEVEL: process.env.CNCF_ADVISOR_LOG_LEVEL || 'INFO',
            QUARKUS_BANNER_ENABLED: 'false'
        };

        // Build command
        const args = [];
        let command;

        if (this.isNative) {
            // Native binary
            command = binaryPath;
        } else {
            // JAR file
            command = 'java';
            args.push('-jar', binaryPath);
        }

        // Start the process
        this.serverProcess = spawn(command, args, {
            env,
            stdio: ['inherit', 'inherit', 'inherit']
        });

        // Handle process events
        this.serverProcess.on('error', (error) => {
            console.error(`Failed to start server: ${error.message}`);
            process.exit(1);
        });

        this.serverProcess.on('exit', (code) => {
            if (code !== 0) {
                console.error(`Server exited with code: ${code}`);
                process.exit(code);
            }
        });

        // Handle signals
        process.on('SIGINT', () => this.stop());
        process.on('SIGTERM', () => this.stop());
    }

    /**
     * Stop the MCP server
     */
    stop() {
        if (this.serverProcess) {
            console.error('\nShutting down CNCF Tech Advisor MCP Server...');
            this.serverProcess.kill('SIGTERM');
        }
    }

    /**
     * Show version information
     */
    showVersion() {
        console.log(`cncf-tech-advisor-mcp v${CONFIG.version}`);
        console.log('');
        console.log('Platform:', os.platform(), os.arch());
        console.log('Node.js:', process.version);
        console.log('Native support:', this.isNative ? 'Yes' : 'No');
        console.log('');
        console.log('Repository:', `https://github.com/${CONFIG.repo}`);
        console.log('Documentation:', `https://github.com/${CONFIG.repo}#readme`);
    }

    /**
     * Show help information
     */
    showHelp() {
        console.log(`
CNCF Tech Advisor MCP Server

USAGE:
  cncf-tech-advisor [OPTIONS]

OPTIONS:
  --version, -v    Show version information
  --help, -h       Show this help message
  --download-url   Show download URL for manual installation

ENVIRONMENT VARIABLES:
  CNCF_ADVISOR_LOG_LEVEL    Set log level (DEBUG, INFO, WARN, ERROR)
  JAVA_HOME               Java installation path (for JAR mode)

EXAMPLES:
  # Start the MCP server (stdio transport)
  cncf-tech-advisor

  # Start with debug logging
  CNCF_ADVISOR_LOG_LEVEL=DEBUG cncf-tech-advisor

  # Use with Claude Desktop
  # Add to claude_desktop_config.json:
  # {
  #   "mcpServers": {
  #     "cncf-tech-advisor": {
  #       "command": "cncf-tech-advisor"
  #     }
  #   }
  # }

SERVER FEATURES:
  - Search CNCF projects and technologies
  - Get personalized technology recommendations
  - Compare technologies based on criteria
  - Analyze technology trends
  - View adoption patterns and best practices
  - Plan technology roadmaps

FOR MORE INFORMATION:
  https://github.com/${CONFIG.repo}#readme
        `);
    }

    /**
     * Show download information
     */
    showDownloadUrl() {
        console.log(`# CNCF Tech Advisor MCP Server Download\n`);
        console.log(`## Pre-built Binaries\n`);
        console.log(`Download from: https://github.com/${CONFIG.repo}/releases\n`);
        console.log(`## Docker Image\n`);
        console.log(`Pull: docker pull ghcr.io/jeanlopezxyz/cncf-tech-advisor-mcp\n`);
    }
}

// Main execution
async function main() {
    const server = new CncfTechAdvisorServer();

    // Parse command line arguments
    const args = process.argv.slice(2);

    if (args.includes('--help') || args.includes('-h')) {
        server.showHelp();
        return;
    }

    if (args.includes('--version') || args.includes('-v')) {
        server.showVersion();
        return;
    }

    if (args.includes('--download-url')) {
        server.showDownloadUrl();
        return;
    }

    // Start the server
    await server.start();
}

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    console.error(`Uncaught exception: ${error.message}`);
    process.exit(1);
});

process.on('unhandledRejection', (reason) => {
    console.error(`Unhandled rejection: ${reason}`);
    process.exit(1);
});

// Run main function
main().catch(error => {
    console.error(`Failed to start server: ${error.message}`);
    process.exit(1);
});