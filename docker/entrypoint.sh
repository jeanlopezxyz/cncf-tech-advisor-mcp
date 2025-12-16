#!/bin/sh

# =============================================================================
# CNCF Tech Advisor MCP Server - Docker Entrypoint Script
# =============================================================================

set -e

echo "🚀 CNCF Tech Advisor MCP Server - Docker Entrypoint"
echo "================================================="

# Default values
MODE=${MODE:-production}
HTTP_ENABLED=${HTTP_ENABLED:-true}
STDIO_ENABLED=${STDIO_ENABLED:-false}
QUARKUS_HTTP_HOST=${QUARKUS_HTTP_HOST:-0.0.0.0}
QUARKUS_HTTP_PORT=${QUARKUS_HTTP_PORT:-8080}
JAVA_OPTS=${JAVA_OPTS:--Xmx512m -Xms256m}

# Display configuration
echo "📋 Configuration:"
echo "   Mode: $MODE"
echo "   HTTP Transport: $HTTP_ENABLED"
echo "   STDIO Transport: $STDIO_ENABLED"
echo "   HTTP Host: $QUARKUS_HTTP_HOST"
echo "   HTTP Port: $QUARKUS_HTTP_PORT"
echo "   Java Options: $JAVA_OPTS"
echo

# Set environment variables based on mode
if [ "$MODE" = "development" ]; then
    echo "🛠️  Development mode enabled"
    export QUARKUS_LOG_LEVEL=DEBUG
    export QUARKUS_MCP_SERVER_TRAFFIC_LOGGING_ENABLED=true
    export QUARKUS_MCP_SERVER_HTTP_ROOT_PATH=/mcp
    export QUARKUS_HTTP_CORS_ENABLED=true
    export QUARKUS_HTTP_CORS_ORIGINS=*
    export QUARKUS_DEV_MODE=true
else
    echo "🚀 Production mode enabled"
    export QUARKUS_LOG_LEVEL=INFO
    export QUARKUS_MCP_SERVER_HTTP_ROOT_PATH=/mcp
    export QUARKUS_HTTP_CORS_ENABLED=true
    export QUARKUS_HTTP_CORS_ORIGINS=*
    export QUARKUS_PROFILE=prod
fi

# Configure transport settings
export QUARKUS_MCP_SERVER_STDIO_ENABLED="$STDIO_ENABLED"
export QUARKUS_MCP_SERVER_HTTP_ROOT_PATH="/mcp"

# Add STDIO transport Java property if enabled
if [ "$STDIO_ENABLED" = "true" ]; then
    JAVA_OPTS="$JAVA_OPTS -Dquarkus.mcp.server.stdio.enabled=true"
    echo "🔌 STDIO transport enabled"
fi

# Disable banner for clean output
export QUARKUS_BANNER_ENABLED=false

# Set final Java options
export JAVA_OPTS="$JAVA_OPTS"

echo "⚡ Starting MCP Server..."
echo "   MCP HTTP Endpoint: http://$QUARKUS_HTTP_HOST:$QUARKUS_HTTP_PORT/mcp"
echo "   MCP SSE Endpoint: http://$QUARKUS_HTTP_HOST:$QUARKUS_HTTP_PORT/mcp/sse"
echo

# Health check function
health_check() {
    local max_attempts=30
    local attempt=1

    echo "🏥 Performing health check..."

    while [ $attempt -le $max_attempts ]; do
        if curl -f -s http://localhost:$QUARKUS_HTTP_PORT/q/health >/dev/null 2>&1; then
            echo "✅ Server is healthy!"
            return 0
        fi

        echo "   Attempt $attempt/$max_attempts: Server not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo "❌ Health check failed after $max_attempts attempts"
    return 1
}

# Start health check in background
if [ "$HTTP_ENABLED" = "true" ]; then
    health_check &
    HEALTH_PID=$!
fi

# Trap signals for graceful shutdown
trap 'echo "🛑 Received shutdown signal..."; kill $HEALTH_PID 2>/dev/null; exit 0' INT TERM

# Run the application
exec java $JAVA_OPTS -jar quarkus-app/quarkus-run.jar "$@"