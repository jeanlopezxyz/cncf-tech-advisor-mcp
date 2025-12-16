# Contributing to CNCF Tech Advisor MCP Server

Thank you for your interest in contributing to the CNCF Tech Advisor MCP Server! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Bugs

If you find a bug, please open an issue on GitHub with the following information:

1. **Bug Description**: Clear description of the issue
2. **Steps to Reproduce**: Detailed steps to reproduce the bug
3. **Expected Behavior**: What you expected to happen
4. **Actual Behavior**: What actually happened
5. **Environment**:
   - Operating system
   - Java version
   - MCP client (Claude Desktop, etc.)
   - Version of cncf-tech-advisor-mcp

### Suggesting Features

Feature suggestions are welcome! Please open an issue with:

1. **Feature Description**: Clear description of the feature
2. **Use Case**: Why this feature would be useful
3. **Implementation Ideas**: (Optional) How you think it could be implemented

### Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 🛠️ Development Setup

### Prerequisites

- Java 25 or higher
- Maven 3.9.0 or higher
- Docker (for native builds)
- Git

### Building the Project

```bash
# Clone the repository
git clone https://github.com/jeanlopezxyz/cncf-tech-advisor-mcp.git
cd cncf-tech-advisor-mcp

# Build the project
./mvnw clean install

# Run in development mode
./mvnw quarkus:dev

# Build native executable
./mvnw package -Dnative
```

### Running Tests

```bash
# Run all tests
./mvnw test

# Run specific test class
./mvnw test -Dtest=CncfToolTest

# Run with coverage
./mvnw verify jacoco:report
```

### Development Workflow

1. **Create a Feature Branch**: Always create a new branch for your work
2. **Make Small Changes**: Keep commits focused on a single feature or fix
3. **Write Tests**: Add tests for new functionality
4. **Update Documentation**: Update relevant documentation
5. **Check Formatting**: Ensure code follows the project's style

## 📝 Code Style

### Java Code Style

We follow the standard Java conventions:

- Use 4 spaces for indentation (no tabs)
- Maximum line length: 120 characters
- Use camelCase for variable and method names
- Use PascalCase for class names
- Use UPPER_SNAKE_CASE for constants

### Documentation

- Add Javadoc comments for public classes and methods
- Keep comments concise and relevant
- Update README.md when adding new features

### Example Code Style

```java
/**
 * Service for analyzing and recommending CNCF technologies.
 */
@ApplicationScoped
public class TechAnalyzer {

    private static final Logger LOG = Logger.getLogger(TechAnalyzer.class);

    /**
     * Analyzes requirements and provides technology recommendations.
     *
     * @param request the recommendation request containing requirements and constraints
     * @return a Uni emitting a list of technology recommendations
     */
    public Uni<List<TechRecommendation>> analyzeAndRecommend(RecommendationRequest request) {
        // Implementation...
    }
}
```

## 🧪 Testing

### Test Structure

- Unit tests: `src/test/java/io/mcp/cncf/`
- Integration tests: `src/test/java/io/mcp/cncf/integration/`
- Test resources: `src/test/resources/`

### Writing Tests

1. **Test Naming**: Use descriptive test method names
2. **AAA Pattern**: Arrange, Act, Assert
3. **Mock Dependencies**: Use Mockito for external dependencies
4. **Test Coverage**: Aim for high test coverage

```java
@QuarkusTest
class TechAnalyzerTest {

    @Inject
    TechAnalyzer analyzer;

    @Test
    void shouldRecommendKubernetesForMicroservices() {
        // Arrange
        RecommendationRequest request = new RecommendationRequest(
            "microservices", List.of(), List.of(),
            List.of(), ExperienceLevel.INTERMEDIATE, ScaleType.MEDIUM
        );

        // Act
        List<TechRecommendation> recommendations =
            analyzer.analyzeAndRecommend(request).await().indefinitely();

        // Assert
        assertFalse(recommendations.isEmpty());
        assertTrue(recommendations.stream()
            .anyMatch(r -> r.primary().name().equals("Kubernetes")));
    }
}
```

## 📦 Project Structure

```
cncf-tech-advisor-mcp/
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
├── npm/               # NPM wrapper
├── .github/workflows/ # CI/CD workflows
└── docs/             # Additional documentation
```

## 🚀 Pull Request Process

### Before Submitting

1. **Run Tests**: Ensure all tests pass
2. **Check Formatting**: Verify code formatting
3. **Update Docs**: Update relevant documentation
4. **Clean History**: Squash commits if necessary

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Added tests for new functionality
- [ ] All tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

## 🏷️ Release Process

Releases are automated through GitHub Actions:

1. Create a release tag: `git tag v1.0.0`
2. Push the tag: `git push origin v1.0.0`
3. GitHub Actions will:
   - Build and test
   - Create GitHub release
   - Build and upload binaries
   - Publish Docker image
   - Publish NPM package

## 💬 Getting Help

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For general questions and ideas
- **Discord**: [Community Discord] (link TBD)

## 📄 Code of Conduct

Please be respectful and inclusive. Follow these guidelines:

- Be welcoming to newcomers
- Focus on what is best for the community
- Show respect for different opinions and perspectives

## 🎯 Contribution Areas

We welcome contributions in these areas:

- **New Technology Categories**: Add support for new CNCF project categories
- **Enhanced Recommendations**: Improve recommendation algorithms
- **Additional Prompts**: Create new interactive prompts
- **Documentation**: Improve documentation and examples
- **Testing**: Add more comprehensive tests
- **Performance**: Optimize performance and caching

### Good First Issues

Look for issues labeled `good first issue` for beginner-friendly contributions.

Thank you for contributing to the CNCF Tech Advisor MCP Server! 🙏