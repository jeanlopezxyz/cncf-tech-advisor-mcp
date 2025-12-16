#!/bin/sh

# =============================================================================
# CNCF Tech Advisor MCP Server - Health Check Script
# =============================================================================

set -e

# Default port
PORT=${QUARKUS_HTTP_PORT:-8080}
HOST=${QUARKUS_HTTP_HOST:-localhost}

# Health check endpoint
HEALTH_URL="http://$HOST:$PORT/q/health"

echo "🏥 Performing health check..."

# Perform health check
if curl -f -s "$HEALTH_URL" >/dev/null 2>&1; then
    echo "✅ Health check passed"

    # Show server info if available
    if curl -f -s "http://$HOST:$PORT/q/info" >/dev/null 2>&1; then
        echo "📊 Server info:"
        curl -f -s "http://$HOST:$PORT/q/info" | head -5
    fi

    exit 0
else
    echo "❌ Health check failed"
    echo "   URL: $HEALTH_URL"

    # Show error details
    if curl -s "$HEALTH_URL" 2>&1 | grep -q "Connection refused"; then
        echo "   Server is not running or not accessible"
    elif curl -s "$HEALTH_URL" 2>&1 | grep -q "404"; then
        echo "   Health endpoint not found"
    else
        echo "   Unknown error occurred"
    fi

    exit 1
fi