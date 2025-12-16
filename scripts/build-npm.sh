#!/bin/bash

# =============================================================================
# CNCF Tech Advisor MCP - Build Script for NPM Distribution
# =============================================================================
# Builds native binaries for all platforms and packages them for NPM distribution
# Usage: ./scripts/build-npm.sh
# =============================================================================

set -e

echo "🚀 Building CNCF Tech Advisor MCP for NPM distribution..."

# Clean and build JAR first
echo "📦 Building JAR..."
./mvnw clean package -DskipTests

# Create distribution directory
DIST_DIR="npm-dist"
rm -rf $DIST_DIR
mkdir -p $DIST_DIR

# Base package name
PACKAGE_NAME="cncf-tech-advisor"
VERSION="1.0.0"

echo ""
echo "🔧 Building native binaries for different platforms..."

# Build native binaries for current platform first
echo "📋 Building native binary for current platform..."
./mvnw package -DskipTests -Dnative

# Copy the native binary
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ $(uname -m) == "arm64" ]]; then
        PLATFORM="darwin-arm64"
        BINARY_NAME="${PACKAGE_NAME}-${PLATFORM}"
        mkdir -p "$DIST_DIR/$BINARY_NAME/bin"
        cp target/*-runner "$DIST_DIR/$BINARY_NAME/bin/$BINARY_NAME"
        echo "✅ macOS ARM64 binary built: $BINARY_NAME"
    else
        PLATFORM="darwin-x64"
        BINARY_NAME="${PACKAGE_NAME}-${PLATFORM}"
        mkdir -p "$DIST_DIR/$BINARY_NAME/bin"
        cp target/*-runner "$DIST_DIR/$BINARY_NAME/bin/$BINARY_NAME"
        echo "✅ macOS x64 binary built: $BINARY_NAME"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux-x64"
    BINARY_NAME="${PACKAGE_NAME}-${PLATFORM}"
    mkdir -p "$DIST_DIR/$BINARY_NAME/bin"
    cp target/*-runner "$DIST_DIR/$BINARY_NAME/bin/$BINARY_NAME"
    echo "✅ Linux x64 binary built: $BINARY_NAME"
fi

# Create main package.json
echo ""
echo "📄 Creating main package.json..."
cat > "$DIST_DIR/package.json" << EOF
{
  "name": "$PACKAGE_NAME",
  "version": "$VERSION",
  "description": "MCP Server for CNCF Landscape Technology Data. Access 2,398+ CNCF projects, GitHub metrics, maturity status, and case studies for technology decision support.",
  "keywords": [
    "mcp",
    "mcp-server",
    "cncf",
    "kubernetes",
    "cloud-native",
    "landscape",
    "technology-advisor",
    "devops",
    "observability",
    "oss"
  ],
  "author": {
    "name": "Jean Lopez",
    "email": "jean.lopez@example.com"
  },
  "license": "Apache-2.0",
  "repository": {
    "type": "git",
    "url": "https://github.com/jeanlopezxyz/cncf-tech-advisor-mcp"
  },
  "bin": {
    "cncf-tech-advisor": "./bin/index.js"
  },
  "files": [
    "bin",
    "README.md"
  ],
  "optionalDependencies": {
    "cncf-tech-advisor-darwin-arm64": "$VERSION",
    "cncf-tech-advisor-darwin-x64": "$VERSION",
    "cncf-tech-advisor-linux-x64": "$VERSION",
    "cncf-tech-advisor-windows-x64": "$VERSION"
  },
  "engines": {
    "node": ">=16"
  },
  "scripts": {
    "test": "node test/test.js"
  }
}
EOF

# Copy bin directory and README
echo "📋 Copying wrapper and documentation..."
mkdir -p "$DIST_DIR/bin"
cp npm/cncf-tech-advisor/bin/index.js "$DIST_DIR/bin/"
cp npm/cncf-tech-advisor/README.md "$DIST_DIR/"

# Create platform-specific packages
echo ""
echo "📦 Creating platform-specific packages..."

for PLATFORM_PACKAGE in "$DIST_DIR"/cncf-tech-advisor-*; do
    if [ -d "$PLATFORM_PACKAGE" ]; then
        PLATFORM_NAME=$(basename "$PLATFORM_PACKAGE")
        echo "  📄 Creating package.json for $PLATFORM_NAME..."

        cat > "$PLATFORM_PACKAGE/package.json" << EOF
{
  "name": "$PLATFORM_NAME",
  "version": "$VERSION",
  "description": "Native binary for CNCF Tech Advisor MCP Server - $PLATFORM_NAME",
  "os": ["$(echo $PLATFORM_NAME | cut -d'-' -f1)"],
  "cpu": ["$(echo $PLATFORM_NAME | cut -d'-' -f2)"],
  "main": "./bin/$(basename $PLATFORM_PACKAGE)",
  "bin": {
    "cncf-tech-advisor": "./bin/$(basename $PLATFORM_PACKAGE)"
  },
  "files": [
    "bin"
  ]
}
EOF

        # Make binary executable
        chmod +x "$PLATFORM_PACKAGE/bin/$(basename $PLATFORM_PACKAGE)"
    fi
done

# Create build summary
echo ""
echo "🎉 Build Summary"
echo "=================================="
echo "✅ Main package: $DIST_DIR/"
echo "✅ Platform packages:"

for PLATFORM_PACKAGE in "$DIST_DIR"/cncf-tech-advisor-*; do
    if [ -d "$PLATFORM_PACKAGE" ]; then
        BINARY_PATH=$(find "$PLATFORM_PACKAGE" -type f -executable | head -1)
        if [ ! -z "$BINARY_PATH" ]; then
            SIZE=$(ls -lh "$BINARY_PATH" | awk '{print $5}')
            echo "  📦 $(basename "$PLATFORM_PACKAGE"): $SIZE"
        fi
    fi
done

echo ""
echo "📋 To publish to NPM:"
echo "   cd $DIST_DIR"
echo "   npm publish"
echo ""
echo "🐳 To build Docker image:"
echo "   docker build -t cncf-tech-advisor:latest ."
echo ""
echo "🎯 CNCF Tech Advisor MCP ready for distribution!"