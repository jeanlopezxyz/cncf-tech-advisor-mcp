# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of CNCF Tech Advisor MCP Server
- Technology recommendations based on use cases and requirements
- CNCF project search and discovery
- Technology comparison with multiple criteria
- Trend analysis for cloud-native technologies
- Adoption patterns and best practices
- Interactive prompts for common scenarios

### Features

#### Tools
- `searchProjects` - Search CNCF projects by keyword, category, or maturity
- `getProjectDetails` - Get detailed information about specific CNCF projects
- `recommendTechnologies` - Get personalized technology recommendations
- `compareTechnologies` - Compare technologies based on criteria
- `analyzeTrends` - Analyze technology trends in specific categories
- `getAdoptionPatterns` - Get common adoption patterns and best practices

#### Prompts
- `cncf-tech-stack-planning` - Plan complete cloud-native technology stacks
- `cncf-technology-comparison` - Compare different CNCF technologies
- `cncf-adoption-journey` - Plan step-by-step adoption of CNCF technologies
- `cncf-trend-analysis` - Analyze technology trends for strategic planning

#### Supported Categories
- Orchestration (Kubernetes, Docker)
- Runtime (Container runtimes, serverless)
- Provisioning (IaC, cloud provisioning)
- Observability (Monitoring, logging, tracing)
- Service Mesh (Istio, Linkerd)
- Networking (CNI, load balancers)
- Security (Auth, secrets, policies)
- Storage (Persistent storage, databases)
- Streaming (Message queues, event streaming)
- CI/CD (GitOps, pipelines)

### Technical
- Built with Quarkus 3.30.2
- Java 25 with records for immutable models
- Reactive programming with Mutiny Uni
- Type-safe REST clients for CNCF APIs
- Comprehensive caching for performance
- Native image compilation support
- Multi-format distribution (Docker, npm, JAR)

## [1.0.0] - 2024-12-14

### Added
- First stable release
- Complete MCP server implementation
- Docker and npm distribution
- Comprehensive documentation
- GitHub Actions CI/CD pipeline
- Maven multi-stage build for native images

### Documentation
- Complete README with usage examples
- API documentation for all tools and prompts
- Development setup guide
- Docker deployment instructions
- Claude Desktop integration guide