# CNCF Tech Advisor MCP Server

MCP Server for CNCF Landscape Technology Data. Access 2,398+ CNCF projects, GitHub metrics, maturity status, and case studies for technology decision support.

## ✨ Quick Start

```bash
# Install and run (no Java required!)
npx mcp-mcp-mcp-cncf-tech-advisor@latest

# With HTTP transport (for MCP Inspector)
npx mcp-mcp-mcp-cncf-tech-advisor@latest --port 8080
```

## 🚀 Installation

### Option 1: NPM (Recommended) - No Java Required! 📦

#### Claude Desktop / Claude Code Integration

Add to `~/.claude/settings.json` (Claude Code) or your MCP client config:

```json
{
  "mcpServers": {
    "mcp-cncf-tech-advisor": {
      "command": "npx",
      "args": ["-y", "mcp-mcp-mcp-cncf-tech-advisor@latest"]
    }
  }
}
```

#### VS Code / Cursor / Windsurf

```json
{
  "mcpServers": {
    "mcp-cncf-tech-advisor": {
      "command": "npx",
      "args": ["-y", "mcp-mcp-mcp-cncf-tech-advisor@latest"]
    }
  }
}
```

#### Global Installation

```bash
npm install -g mcp-mcp-cncf-tech-advisor

# Start the MCP server
mcp-mcp-cncf-tech-advisor

# HTTP mode for testing
mcp-mcp-cncf-tech-advisor --port 8080
```

### Option 2: Docker (Production) 🐳

```bash
# Pull and run native image
docker run -i --rm -p 8080:8080 ghcr.io/jeanlopezxyz/mcp-cncf-tech-advisor:latest

# MCP STDIO usage
docker run -i --rm ghcr.io/jeanlopezxyz/mcp-cncf-tech-advisor:latest \
  -Dquarkus.mcp.server.stdio.enabled=true
```

### Option 3: Build from Source (Development) 🔧

```bash
git clone https://github.com/jeanlopezxyz/mcp-cncf-tech-advisor-mcp.git
cd mcp-cncf-tech-advisor-mcp

# Build native binary
./mvnw package -DskipTests -Dnative

# Run
./target/*-runner
```

## 🚢 Deployment Scripts

### Automated Deployment

The project includes automated deployment scripts for different platforms:

#### Docker Deployment
```bash
# Build and push to registry
./scripts/deploy.sh -p docker --push

# Development deployment
./scripts/deploy.sh -p docker -e dev --dev

# Native build with push
./scripts/deploy.sh -p docker --native --push
```

#### Kubernetes Deployment
```bash
# Deploy to staging
./scripts/deploy.sh -p k8s -e staging

# Deploy to production
./scripts/deploy.sh -p k8s -e production
```

#### NPM Deployment
```bash
# Publish to NPM registry
./scripts/deploy.sh -p npm --push

# Publish with custom tag
./scripts/deploy.sh -p npm --tag beta
```

### Configuration Options

#### Environment Variables
```bash
# Java options
export JAVA_OPTS="-Xmx1g -Xms512m"

# MCP transport configuration
export STDIO_ENABLED=true
export HTTP_ENABLED=true

# Application settings
export QUARKUS_HTTP_PORT=8080
export QUARKUS_LOG_LEVEL=INFO
```

#### Application Properties
```properties
# application.properties
quarkus.mcp.server.stdio.enabled=true
quarkus.mcp.server.http.root-path=/mcp
quarkus.http.cors.enabled=true
quarkus.http.cors.origins=*
```

## ☸️ Kubernetes Deployment

### Kubernetes Manifests
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-cncf-tech-advisor
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mcp-cncf-tech-advisor
  template:
    metadata:
      labels:
        app: mcp-cncf-tech-advisor
    spec:
      containers:
      - name: mcp-cncf-tech-advisor
        image: ghcr.io/jeanlopezxyz/mcp-cncf-tech-advisor-mcp:latest
        ports:
        - containerPort: 8080
        env:
        - name: QUARKUS_MCP_SERVER_STDIO_ENABLED
          value: "false"
        - name: QUARKUS_MCP_SERVER_HTTP_ROOT_PATH
          value: "/mcp"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /q/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /q/health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: mcp-cncf-tech-advisor
spec:
  selector:
    app: mcp-cncf-tech-advisor
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
```

### Deploy with Helm (Optional)
```bash
# Add Helm repository
helm repo add mcp-cncf-tech-advisor https://charts.jeanlopez.tech
helm repo update

# Install chart
helm install mcp-cncf-tech-advisor mcp-cncf-tech-advisor/mcp-cncf-tech-advisor \
  --set image.tag=latest \
  --set replicas=3 \
  --set resources.requests.memory=512Mi
```

## 🔄 CI/CD Pipeline

The project includes a comprehensive CI/CD pipeline using GitHub Actions:

### Automated Workflows
- **Testing**: Multi-platform tests (Linux, macOS, Windows)
- **Building**: JVM and native builds
- **Scanning**: Security vulnerability scanning with Trivy
- **Deployment**: Docker image publishing, NPM publishing
- **Integration**: End-to-end MCP protocol testing

### Build Triggers
- Push to main/develop branches
- Pull requests
- Release events

### Manual Testing
```bash
# Run full test suite
./scripts/test.sh

# Test MCP protocol
docker/scripts/mcp-test.sh

# Health check
curl -f http://localhost:8080/q/health
```

## 🔧 Configuration

### Environment Variables

- `QUARKUS_MCP_SERVER_STDIO_ENABLED=true` - Enable stdio transport (default for CLI)
- `QUARKUS_MCP_SERVER_HTTP_ROOT_PATH=/mcp` - HTTP endpoint path
- `QUARKUS_HTTP_PORT=8080` - HTTP server port
- `CNCF_ADVISOR_LOG_LEVEL=INFO` - Log level (DEBUG, INFO, WARN, ERROR)

### Claude Desktop Integration

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "cncf-tech-advisor": {
      "command": "mcp-cncf-tech-advisor"
    }
  }
}
```

## 🛠️ Available Tools (8)

### Project Search & Analysis
- **searchProjects** - Search CNCF projects by keyword, category, or maturity level
- **getProjectDetails** - Get detailed information about a specific CNCF project
- **getProjectMetrics** - GitHub metrics and community statistics for projects
- **getProjectMaturity** - CNCF maturity status and progression timeline
- **getProjectsByCategory** - List all projects in a specific category

### Case Studies & Real-World Examples
- **searchCaseStudies** - Search for CNCF case studies and end-user examples
- **getCaseStudiesByProject** - Get case studies that use a specific project
- **getAllCaseStudies** - Get all available CNCF case studies with filtering

## ✨ Features

- **O(1) Search**: Ultra-fast indexing of 2,398+ CNCF projects
- **Live Data**: Automatic updates from CNCF Landscape API
- **Smart Scoring**: Relevance and popularity algorithms
- **Comprehensive**: Project details, GitHub metrics, maturity status
- **Real-world Examples**: Case studies and end-user implementations
- **Multi-platform Support**: macOS (ARM64/x64), Linux (x64), Windows (x64)
- **No Java Dependencies**: Native binaries for production deployment

## 💡 Example Prompts

### Project Discovery

```
"Search for observability technologies in CNCF"
"Show me graduated projects related to service mesh"
"Find container runtime projects"
"List all projects in the serverless category"
```

### Project Analysis

```
"Compare Prometheus and Grafana metrics"
"What's the maturity status of Istio?"
"Show me GitHub metrics for Kubernetes"
"Find popular container orchestration tools"
```

### Case Studies & Real-World Examples

```
"Find case studies using Kubernetes"
"Search for microservices case studies"
"Show me end-user implementations of monitoring solutions"
"Get case studies about service mesh in production"
```

### Technology Decision Support

```
"What are the best CNCF projects for logging?"
"Recommend projects for API gateway needs"
"Show me mature networking projects"
"Find projects with high community activity"

## 🏗️ Architecture

```
mcp-cncf-tech-advisor-mcp/
├── src/main/java/io/mcp/cncf/
│   ├── analyzer/      # Analysis and recommendation engine
│   ├── client/        # CNCF API integration
│   ├── config/        # Configuration classes
│   ├── model/         # Data models and records
│   ├── prompt/        # MCP prompt templates
│   └── tool/          # MCP tool implementations
├── src/main/resources/
│   └── application.properties
├── src/test/java/
├── npm/               # NPM wrapper for easy distribution
└── Dockerfile         # Multi-stage native build
```

## 🔧 Development

### Prerequisites

- Java 25+ (for development/builder)
- Maven 3.9+
- Docker (optional, for native build)

### Building

```bash
# Build JAR
./mvnw package

# Build native executable
./mvnw package -Dnative

# Run tests
./mvnw test

# Run in dev mode
./mvnw quarkus:dev
```

### Testing the MCP Server

```bash
# Start with stdio transport
java -jar target/mcp-cncf-tech-advisor-mcp-1.0.0-runner.jar \
  -Dquarkus.mcp.server.stdio.enabled=true

# Or start with HTTP transport
java -jar target/mcp-cncf-tech-advisor-mcp-1.0.0-runner.jar
# MCP endpoint: http://localhost:8080/mcp
# SSE endpoint: http://localhost:8080/mcp/sse
```

## 📊 Supported Technology Categories

- **Orchestration** - Kubernetes, Docker, etc.
- **Runtime** - Container runtimes, serverless platforms
- **Provisioning** - Infrastructure as code, cloud provisioning
- **Observability** - Monitoring, logging, tracing
- **Service Discovery** - Service discovery and configuration
- **Service Mesh** - Service mesh implementations
- **Networking** - CNI, load balancers, ingress
- **Security** - Authentication, authorization, secrets
- **Database** - Databases and data stores
- **Storage** - Persistent storage solutions
- **Streaming** - Message queues and streaming platforms
- **Serverless** - FaaS and serverless platforms
- **Integration** - Integration and messaging
- **Policy** - Policy as code, authorization
- **Artifact Management** - Artifact repositories and registries

## 🤝 Contributing

Contributions are welcome! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [CNCF](https://cncf.io/) for the amazing cloud-native ecosystem
- [Quarkus](https://quarkus.io/) for the supersonic subatomic Java framework
- [MCP](https://modelcontextprotocol.io/) for the Model Context Protocol

## 📞 Support

- **Documentation**: [Project Wiki](https://github.com/jeanlopezxyz/mcp-cncf-tech-advisor-mcp/wiki)
- **Issues**: [GitHub Issues](https://github.com/jeanlopezxyz/mcp-cncf-tech-advisor-mcp/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jeanlopezxyz/mcp-cncf-tech-advisor-mcp/discussions)

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=jeanlopezxyz/mcp-cncf-tech-advisor-mcp&type=Date)](https://star-history.com/#jeanlopezxyz/mcp-cncf-tech-advisor-mcp&Date)

---

Made with ❤️ by [Jean Lopez](https://github.com/jeanlopezxyz)