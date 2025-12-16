#!/bin/bash

# =============================================================================
# CNCF Tech Advisor MCP - Cross-Platform Build Script
# =============================================================================
# Uses Docker to build native binaries for multiple platforms
# Usage: ./scripts/cross-build.sh
# =============================================================================

set -e

echo "🌍 Building CNCF Tech Advisor MCP for multiple platforms..."

# Base directory
BASE_DIR=$(pwd)
DIST_DIR="npm-dist"
rm -rf $DIST_DIR
mkdir -p $DIST_DIR

PACKAGE_NAME="cncf-tech-advisor"
VERSION="1.0.0"

# Build JAR first (needed for all platforms)
echo "📦 Building JAR..."
./mvnw clean package -DskipTests

# Platform configurations
declare -A PLATFORMS=(
    ["linux-x64"]="quay.io/quarkus/ubi-quarkus-mandrel-builder-image:jdk-21"
    ["darwin-x64"]="quay.io/quarkus/ubi-quarkus-mandrel-builder-image:jdk-21"
    ["darwin-arm64"]="quay.io/quarkus/ubi-quarkus-mandrel-builder-image:jdk-21"
    # Note: Windows requires different approach - would need Windows container
)

echo ""
echo "🔧 Building native binaries using Docker..."

for PLATFORM in "${!PLATFORMS[@]}"; do
    BUILDER_IMAGE="${PLATFORMS[$PLATFORM]}"
    BINARY_NAME="${PACKAGE_NAME}-${PLATFORM}"

    echo "  🏗️  Building for $PLATFORM using $BUILDER_IMAGE..."

    # Create platform-specific build directory
    mkdir -p "$DIST_DIR/$BINARY_NAME/bin"

    # Build using Docker
    docker run --rm \
        -v "$BASE_DIR":/workspace \
        -w /workspace \
        "$BUILDER_IMAGE" \
        bash -c "
            chown -R quarkus:quarkus /workspace
            su quarkus -c './mvnw package -DskipTests -Dnative'
            exit 0
        " || {
            echo "⚠️ Docker build failed for $PLATFORM, trying alternative approach..."
            continue
        }

    # Copy built binary
    if [ -f "target/*-runner" ]; then
        cp target/*-runner "$DIST_DIR/$BINARY_NAME/bin/$BINARY_NAME"
        chmod +x "$DIST_DIR/$BINARY_NAME/bin/$BINARY_NAME"
        echo "  ✅ $PLATFORM binary built successfully"

        # Show binary size
        SIZE=$(ls -lh "$DIST_DIR/$BINARY_NAME/bin/$BINARY_NAME" | awk '{print $5}')
        echo "     Size: $SIZE"
    else
        echo "  ❌ Failed to build $PLATFORM binary"
    fi
done

# Create platform-specific packages
echo ""
echo "📦 Creating platform-specific packages..."

for PLATFORM_PACKAGE in "$DIST_DIR"/$PACKAGE_NAME-*; do
    if [ -d "$PLATFORM_PACKAGE" ]; then
        PLATFORM_NAME=$(basename "$PLATFORM_PACKAGE")
        echo "  📄 Creating package.json for $PLATFORM_NAME..."

        # Extract OS and CPU from platform name
        OS=$(echo "$PLATFORM_NAME" | sed "s/$PACKAGE_NAME-//" | cut -d'-' -f1)
        CPU=$(echo "$PLATFORM_NAME" | sed "s/$PACKAGE_NAME-//" | cut -d'-' -f2)

        cat > "$PLATFORM_PACKAGE/package.json" << EOF
{
  "name": "$PLATFORM_NAME",
  "version": "$VERSION",
  "description": "Native binary for CNCF Tech Advisor MCP Server - $PLATFORM_NAME",
  "os": ["$OS"],
  "cpu": ["$CPU"],
  "main": "./bin/$(basename $PLATFORM_PACKAGE)",
  "bin": {
    "cncf-tech-advisor": "./bin/$(basename $PLATFORM_PACKAGE)"
  },
  "files": [
    "bin"
  ]
}
EOF
    fi
done

# Create main package
echo ""
echo "📄 Creating main package.json..."

# Copy wrapper and README
mkdir -p "$DIST_DIR/bin"
cp npm/cncf-tech-advisor/bin/index.js "$DIST_DIR/bin/"
cp npm/cncf-tech-advisor/README.md "$DIST_DIR/"

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
    "cncf-tech-advisor-linux-x64": "$VERSION",
    "cncf-tech-advisor-darwin-x64": "$VERSION",
    "cncf-tech-advisor-darwin-arm64": "$VERSION",
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

echo ""
echo "🎉 Cross-Platform Build Summary"
echo "=================================="

for PLATFORM_PACKAGE in "$DIST_DIR"/$PACKAGE_NAME-*; do
    if [ -d "$PLATFORM_PACKAGE" ]; then
        BINARY_PATH=$(find "$PLATFORM_PACKAGE" -type f -executable | head -1)
        if [ ! -z "$BINARY_PATH" ] && [ -f "$BINARY_PATH" ]; then
            SIZE=$(ls -lh "$BINARY_PATH" | awk '{print $5}')
            echo "✅ $(basename "$PLATFORM_PACKAGE"): $SIZE"
        else
            echo "❌ $(basename "$PLATFORM_PACKAGE"): Build failed"
        fi
    fi
done

echo ""
echo "📋 Distribution directory: $DIST_DIR/"
echo "📋 To publish to NPM:"
echo "   cd $DIST_DIR"
echo "   npm publish"
echo ""
echo "🎯 CNCF Tech Advisor MCP cross-platform build complete!"