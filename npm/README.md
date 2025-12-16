# mcp-cncf-tech-advisor

MCP Server for CNCF Landscape Technology Data. Access 2,398+ CNCF projects, GitHub metrics, maturity status, and case studies for technology decision support.

## Quick Start

```bash
# Installation and usage
npx mcp-cncf-tech-advisor@latest

# With HTTP transport (for MCP Inspector)
npx mcp-cncf-tech-advisor@latest --port 8080
```

## Configuration

Add to `~/.claude/settings.json` (Claude Code) or your MCP client config:

```json
{
  "mcpServers": {
    "cncf-tech-advisor": {
      "command": "npx",
      "args": ["-y", "mcp-cncf-tech-advisor@latest"]
    }
  }
}
```

## Requirements

- Node.js 16+ (for npx)

> **Note:** No Java required! Native binaries are automatically downloaded for your platform.

## Tools (8)

| Tool | Description |
|------|-------------|
| `searchProjects` | Search CNCF projects by keyword, category, or maturity level |
| `getProjectDetails` | Get detailed information about a specific CNCF project |
| `getProjectMetrics` | GitHub metrics and community statistics for projects |
| `getProjectMaturity` | CNCF maturity status and progression timeline |
| `getProjectsByCategory` | List all projects in a specific category |
| `searchCaseStudies` | Search for CNCF case studies and end-user examples |
| `getCaseStudiesByProject` | Get case studies that use a specific project |
| `getAllCaseStudies` | Get all available CNCF case studies with filtering |

## Example Prompts

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

## Supported Platforms

- macOS (ARM64, x64)
- Linux (x64)
- Windows (x64)

## Documentation

Full docs: https://github.com/jeanlopezxyz/cncf-tech-advisor-mcp

## License

Apache-2.0