#!/bin/bash

# =============================================================================
# CNCF Tech Advisor MCP Server - Test Script
# =============================================================================

set -e

# Configuration
HOST=${HOST:-localhost}
PORT=${PORT:-8080}
TIMEOUT=${TIMEOUT:-30}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 CNCF Tech Advisor MCP Server - Test Script${NC}"
echo "================================================"

# Function to check if server is running
check_server() {
    echo -e "${YELLOW}🔍 Checking if MCP server is running...${NC}"

    if curl -f -s --max-time 5 "http://$HOST:$PORT/q/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Server is running at http://$HOST:$PORT${NC}"
        return 0
    else
        echo -e "${RED}❌ Server is not accessible at http://$HOST:$PORT${NC}"
        echo "   Make sure the server is started with HTTP transport enabled"
        return 1
    fi
}

# Function to test MCP initialize
test_mcp_initialize() {
    echo -e "${YELLOW}🔌 Testing MCP initialization...${NC}"

    # MCP initialize message
    local init_message='{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {
                "roots": {
                    "listChanged": true
                },
                "sampling": {}
            },
            "clientInfo": {
                "name": "test-client",
                "version": "1.0.0"
            }
        }
    }'

    local response=$(echo "$init_message" | curl -s -X POST \
        -H "Content-Type: application/json" \
        --max-time $TIMEOUT \
        "http://$HOST:$PORT/mcp" 2>/dev/null || echo "")

    if echo "$response" | grep -q '"result"'; then
        echo -e "${GREEN}✅ MCP initialization successful${NC}"
        echo "   Protocol: $(echo "$response" | grep -o '"protocolVersion":"[^"]*"' | cut -d'"' -f4)"
        echo "   Server: $(echo "$response" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)"
        echo "   Version: $(echo "$response" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)"
        return 0
    else
        echo -e "${RED}❌ MCP initialization failed${NC}"
        echo "   Response: $response"
        return 1
    fi
}

# Function to test MCP tools list
test_mcp_tools() {
    echo -e "${YELLOW}🛠️  Testing MCP tools list...${NC}"

    # Complete MCP flow: initialize -> initialized -> tools/list
    local messages='{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {"roots": {"listChanged": true}, "sampling": {}},
            "clientInfo": {"name": "test-client", "version": "1.0.0"}
        }
    }
{
    "jsonrpc": "2.0",
    "method": "notifications/initialized"
}
{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list",
    "params": {}
}'

    local response=$(echo "$messages" | curl -s -X POST \
        -H "Content-Type: application/json" \
        --max-time $TIMEOUT \
        "http://$HOST:$PORT/mcp" 2>/dev/null || echo "")

    if echo "$response" | grep -q '"tools"'; then
        local tool_count=$(echo "$response" | grep -o '"name"' | wc -l)
        echo -e "${GREEN}✅ MCP tools list successful ($tool_count tools found)${NC}"

        # Show first few tools
        echo -e "${BLUE}📋 Available tools:${NC}"
        echo "$response" | grep -o '"name":"[^"]*"' | head -3 | while read -r tool; do
            local tool_name=$(echo "$tool" | cut -d'"' -f4)
            echo "   • $tool_name"
        done
        echo "   ... and $((tool_count - 3)) more"
        return 0
    else
        echo -e "${RED}❌ MCP tools list failed${NC}"
        return 1
    fi
}

# Function to test a specific tool
test_mcp_tool() {
    local tool_name="$1"
    echo -e "${YELLOW}🧪 Testing MCP tool: $tool_name${NC}"

    local tool_message='{
        "jsonrpc": "2.0",
        "id": 3,
        "method": "tools/call",
        "params": {
            "name": "'$tool_name'",
            "arguments": {
                "query": "kubernetes",
                "limit": 5
            }
        }
    }'

    local response=$(echo "$tool_message" | curl -s -X POST \
        -H "Content-Type: application/json" \
        --max-time $TIMEOUT \
        "http://$HOST:$PORT/mcp" 2>/dev/null || echo "")

    if echo "$response" | grep -q '"result"'; then
        echo -e "${GREEN}✅ Tool '$tool_name' executed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Tool '$tool_name' execution failed${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo

    # Check if server is running
    if ! check_server; then
        echo -e "${RED}💥 Tests failed - server not accessible${NC}"
        exit 1
    fi

    echo

    # Run tests
    local failed_tests=0

    if ! test_mcp_initialize; then
        failed_tests=$((failed_tests + 1))
    fi
    echo

    if ! test_mcp_tools; then
        failed_tests=$((failed_tests + 1))
    fi
    echo

    # Test a few sample tools
    for tool in "search_cncf" "get_cncf_project"; do
        if ! test_mcp_tool "$tool"; then
            failed_tests=$((failed_tests + 1))
        fi
        echo
    done

    # Final result
    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed! MCP server is working correctly.${NC}"
        exit 0
    else
        echo -e "${RED}💥 $failed_tests test(s) failed${NC}"
        exit 1
    fi
}

# Run main function
main "$@"