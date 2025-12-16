#!/bin/bash

# =============================================================================
# CNCF Tech Advisor MCP - Installation Script for Claude Desktop
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 CNCF Tech Advisor MCP - Claude Desktop Installation${NC}"
echo "=================================================================="

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    OS="macos";;
    Linux*)     OS="linux";;
    CYGWIN*)    OS="windows";;
    *)          OS="unknown";;
esac

echo -e "${BLUE}📍 Detected OS: ${OS}${NC}"

# Configuration paths
if [ "$OS" = "macos" ]; then
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
    CONFIG_FILE="claude_desktop_config.json"
elif [ "$OS" = "linux" ]; then
    CONFIG_DIR="$HOME/.config/claude"
    CONFIG_FILE="claude_desktop_config.json"
elif [ "$OS" = "windows" ]; then
    CONFIG_DIR="$APPDATA/Claude"
    CONFIG_FILE="claude_desktop_config.json"
else
    echo -e "${RED}❌ Unsupported OS${NC}"
    exit 1
fi

CONFIG_PATH="$CONFIG_DIR/$CONFIG_FILE"

echo -e "${BLUE}📁 Configuration path: $CONFIG_PATH${NC}"

# Create backup if file exists
if [ -f "$CONFIG_PATH" ]; then
    echo -e "${YELLOW}💾 Creating backup...${NC}"
    cp "$CONFIG_PATH" "$CONFIG_PATH.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✅ Backup created${NC}"
fi

# Create directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Create/update configuration
echo -e "${YELLOW}⚙️  Creating configuration...${NC}"

# Read existing config or create new
if [ -f "$CONFIG_PATH" ]; then
    # Check if cncf-tech-advisor already exists
    if grep -q "cncf-tech-advisor" "$CONFIG_PATH"; then
        echo -e "${YELLOW}⚠️  CNCF Tech Advisor MCP already configured${NC}"
        echo -e "${BLUE}📝 Current configuration:${NC}"
        grep -A 10 "cncf-tech-advisor" "$CONFIG_PATH" | head -12
    else
        # Add to existing config
        echo -e "${BLUE}➕ Adding to existing configuration...${NC}"

        # Create temporary file with new config
        cat > /tmp/claude_config_temp.json << 'EOF'
{
  "mcpServers": {
    "cncf-tech-advisor": {
      "command": "npx",
      "args": [
        "-y",
        "cncf-tech-advisor@latest"
      ]
    }
  }
}
EOF

        # Merge with existing (simple merge - in production you'd want proper JSON parsing)
        echo -e "${YELLOW}⚠️  Manual merge required. Configuration created at: /tmp/claude_config_temp.json${NC}"
        echo -e "${BLUE}📋 Please merge the contents into your existing $CONFIG_PATH${NC}"
    fi
else
    # Create new configuration
    echo -e "${BLUE}📝 Creating new configuration...${NC}"
    cat > "$CONFIG_PATH" << 'EOF'
{
  "mcpServers": {
    "cncf-tech-advisor": {
      "command": "npx",
      "args": [
        "-y",
        "cncf-tech-advisor@latest"
      ]
    }
  }
}
EOF
    echo -e "${GREEN}✅ Configuration created${NC}"
fi

echo
echo -e "${GREEN}🎉 Installation completed!${NC}"
echo
echo -e "${CYAN}📋 Next Steps:${NC}"
echo "1. ${BLUE}Restart Claude Desktop${NC}"
echo "2. ${BLUE}Open Claude Desktop and check for CNCF Tech Advisor tools${NC}"
echo "3. ${BLUE}Try asking: 'Search for Kubernetes projects in CNCF'${NC}"
echo
echo -e "${CYAN}🧪 Test the MCP server:${NC}"
echo "   • 'Show me all CNCF orchestration projects'"
echo "   • 'Get details about the Prometheus project'"
echo "   • 'List all CNCF categories'"
echo "   • 'Find CNCF projects related to service mesh'"
echo
echo -e "${BLUE}📚 Available tools:${NC}"
echo "   • search_cncf - Search CNCF projects"
echo "   • get_cncf_project - Get project details"
echo "   • list_cncf_categories - List categories"
echo "   • refresh_cncf_data - Refresh data from CNCF Landscape"
echo
echo -e "${GREEN}✨ CNCF Tech Advisor MCP is now ready to use!${NC}"