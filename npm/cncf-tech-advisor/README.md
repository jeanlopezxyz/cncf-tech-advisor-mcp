# cncf-tech-advisor

MCP Server for CNCF Landscape Technology Data. Access 2,398+ CNCF projects, GitHub metrics, maturity status, and case studies for technology decision support.

## Quick Start

```bash
# Default configuration
npx cncf-tech-advisor@latest

# With HTTP transport (for MCP Inspector)
npx cncf-tech-advisor@latest --port 8080
```

## Configuration

Add to `~/.claude/settings.json` (Claude Code) or your MCP client config:

```json
{
  "mcpServers": {
    "cncf-tech-advisor": {
      "command": "npx",
      "args": ["-y", "cncf-tech-advisor@latest"]
    }
  }
}
```

## Requirements

- Node.js 16+ (for npx)
- Internet connection (for live CNCF Landscape data)

> **Note:** No Java required! Native binaries are automatically downloaded for your platform.

## Tools (8)

| Tool | Description |
|------|-------------|
| `searchProjects` | Search CNCF projects by keyword, category, or maturity |
| `getProjectDetails` | Get detailed information about a specific CNCF project |
| `getProjectMetrics` | GitHub metrics and community statistics for projects |
| `getProjectMaturity` | CNCF maturity status and progression timeline |
| `getProjectsByCategory` | List all projects in a specific category |
| `searchCaseStudies` | Search for CNCF case studies and end-user examples |
| `getCaseStudiesByProject` | Get case studies that use a specific project |
| `getAllCaseStudies` | Get all available CNCF case studies with filtering |

## Example Prompts

```
"Search for observability technologies in CNCF"
"Show me graduated projects related to service mesh"
"Compare Prometheus and Grafana metrics"
"Find case studies using Kubernetes"
"What's the maturity status of Istio?"
"List all runtime category projects"
"Show me popular container orchestration tools"
"Find end-user case studies for monitoring solutions"
```

## Features

- **O(1) Search**: Ultra-fast indexing of 2,398+ CNCF projects
- **Live Data**: Automatic updates from CNCF Landscape API
- **Smart Scoring**: Relevance and popularity algorithms
- **Comprehensive**: Project details, GitHub metrics, maturity status
- **Real-world Examples**: Case studies and end-user implementations

## Supported Platforms

- macOS (ARM64, x64)
- Linux (x64)
- Windows (x64)

## Data Sources

- [CNCF Landscape API](https://landscape.cncf.io/) - 2,398+ projects
- [CNCF Case Studies](https://www.cncf.io/case-studies/) - Real implementations
- GitHub APIs - Live metrics and community data

## Documentation

Full docs: https://github.com/jeanlopezxyz/cncf-tech-advisor-mcp

## License

Apache-2.0