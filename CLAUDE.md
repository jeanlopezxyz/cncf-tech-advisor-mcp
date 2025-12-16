# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CNCF Tech Advisor MCP Server is a Model Context Protocol (MCP) server that provides intelligent technology recommendations and analysis for cloud-native architectures. It integrates with the CNCF Landscape API to offer real-time insights on 2,398+ CNCF projects.

## Architecture

Hybrid Java/Node.js architecture:
- **Core Backend**: Quarkus-based Java application using Java 25 preview features
- **NPM Package**: Node.js wrapper for distribution
- **MCP Server**: Implements Model Context Protocol for AI integration
- **Multi-transport**: Supports both STDIO and HTTP/SSE transports

Key directories:
- `src/main/java/io/mcp/cncf/` - Core Java application
  - `client/` - CNCF API integration (CncfLandscapeClient)
  - `model/` - Data models and search logic (CncfModel)
  - `tool/` - MCP tool implementations (CncfTool)
  - `service/` - Business logic services
  - `config/` - Configuration constants
  - `util/` - Utility classes
- `bin/` - Entry point scripts
- `npm/` - NPM package distribution files
- `test/` - Integration tests

## Common Development Commands

### Development
```bash
# Run in development mode with hot reload
./mvnw quarkus:dev
make dev

# Run tests
./mvnw test
make test

# Run tests with coverage
./mvnw verify jacoco:report
make test-coverage
```

### Building
```bash
# Build JAR package
./mvnw clean package -DskipTests
make build

# Build native executable (requires GraalVM)
./mvnw clean package -Dnative -DskipTests
make native

# Quick start (build + run)
make quick-start
```

### Running the Application
```bash
# Run built JAR
java -jar target/cncf-tech-advisor-mcp-1.0.0-runner.jar
make run

# Run with STDIO transport (for MCP clients)
java -jar target/cncf-tech-advisor-mcp-1.0.0-runner.jar -Dquarkus.mcp.server.stdio.enabled=true
make run-stdio

# Run with HTTP transport (for testing/development)
java -jar target/cncf-tech-advisor-mcp-1.0.0-runner.jar --port 8080
```

### NPM Package Management
```bash
# Build NPM package
npm run build
npm run postinstall  # builds Maven package silently

# Run NPM package
npm start
npm run dev

# Publish to NPM
npm run release
```

### Docker Operations
```bash
# Build Docker image
docker build -t cncf-tech-advisor-mcp .
make docker

# Run Docker container
docker run -i --rm -p 8080:8080 cncf-tech-advisor-mcp:latest
make docker-run

# Build and push to registry
make docker-push
```

### Code Quality
```bash
# Format code
./mvnw spotless:apply
make format

# Check code style
./mvnw spotless:check
make lint
```

## Configuration

### Environment Variables
- `JAVA_OPTS` - JVM options (e.g., "-Xmx1g -Xms512m")
- `STDIO_ENABLED` - Enable stdio transport
- `HTTP_ENABLED` - Enable HTTP transport
- `QUARKUS_HTTP_PORT` - HTTP server port (default: 8080)
- `QUARKUS_LOG_LEVEL` - Log level (DEBUG, INFO, WARN, ERROR)

### Application Profiles
- Default: STDIO transport enabled, HTTP disabled
- `sse` profile: HTTP/SSE enabled, STDIO disabled (activate with --port)
- `dev` profile: Development settings with relaxed logging
- `prod` profile: Production optimized settings

## MCP Tools Available

The server implements these MCP tools:
- `search_cncf` - Search projects by keyword/category
- `get_cncf_project` - Detailed project information
- `list_cncf_categories` - List all available categories
- `refresh_cncf_data` - Refresh data from CNCF API

## Key Implementation Files

1. `CncfTool.java` - Main MCP tool implementation with @McpTool annotations
2. `CncfModel.java` - Data models including Project record and search logic
3. `CncfLandscapeClient.java` - REST client for CNCF Landscape API integration
4. `bin/cncf-tech-advisor` - Main entry point script that handles JVM options and profiles
5. `application.properties` - Quarkus configuration with MCP server settings

## Development Workflow

1. Local development uses `./mvnw quarkus:dev` for hot reload
2. Tests are written with JUnit 5 and can be run with `./mvnw test`
3. The project uses Java 25 preview features (ensure JDK 25+ is installed)
4. Native builds require GraalVM for optimal performance
5. NPM package automatically builds Java component during postinstall

## Testing

Unit tests in `src/test/java/` verify MCP tool functionality and API integration. Integration tests validate the MCP protocol implementation. Test coverage reports can be generated with JaCoCo.

## Build System

- **Maven**: Primary build tool with Quarkus plugin
- **Makefile**: Convenient shortcuts for common operations
- **NPM**: Wrapper for distribution and publishing
- **GitHub Actions**: CI/CD pipeline for automated builds and releases