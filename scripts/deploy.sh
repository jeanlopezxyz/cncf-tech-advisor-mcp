#!/bin/bash

# =============================================================================
# CNCF Tech Advisor MCP Server - Deployment Script
# =============================================================================
# Automated deployment script for different environments and platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default configuration
PLATFORM=${PLATFORM:-"docker"}
ENVIRONMENT=${ENVIRONMENT:-"production"}
VERSION=${VERSION:-"latest"}
REGISTRY=${REGISTRY:-"ghcr.io/jeanlopezxyz"}
IMAGE_NAME="cncf-tech-advisor-mcp"

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ENV="$PROJECT_ROOT/target/quarkus-app"
DOCKERFILE="$PROJECT_ROOT/Dockerfile"

# Help function
show_help() {
    echo -e "${CYAN}🚀 CNCF Tech Advisor MCP Server - Deployment Script${NC}"
    echo "================================================================"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -p, --platform PLATFORM    Deployment platform (docker|k8s|npm) [default: docker]"
    echo "  -e, --environment ENV     Environment (dev|staging|production) [default: production]"
    echo "  -v, --version VERSION       Version tag [default: latest]"
    echo "  -r, --registry REGISTRY    Container registry [default: ghcr.io/jeanlopezxyz]"
    echo "  -t, --tag TAG             Additional tag for image"
    echo "  --native                    Build native image"
    echo "  --dev                       Development mode"
    echo "  --skip-tests               Skip build tests"
    echo "  --push                     Push to registry after build"
    echo "  --help                     Show this help message"
    echo
    echo "Platforms:"
    echo "  docker       Build Docker container image"
    echo "  k8s          Deploy to Kubernetes cluster"
    echo "  npm           Publish to NPM registry"
    echo
    echo "Examples:"
    echo "  $0                                    # Build Docker image for production"
    echo "  $0 -p docker -e dev --dev           # Build development Docker image"
    echo "  $0 -p docker --native --push        # Build native Docker image and push"
    echo "  $0 -p k8s -e staging                 # Deploy to Kubernetes staging"
    echo "  $0 -p npm --tag beta                # Publish to NPM with beta tag"
    echo
}

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Build function
build_application() {
    log_info "Building application..."

    cd "$PROJECT_ROOT"

    if [ "$SKIP_TESTS" = "true" ]; then
        log_warning "Skipping tests as requested"
        ./mvnw package -DskipTests -q
    else
        log_info "Running tests..."
        ./mvnw verify -q
    fi

    log_success "Application built successfully"
}

# Docker deployment functions
build_docker_image() {
    log_info "Building Docker image..."

    local build_args=""
    local target_tag=""

    if [ "$PLATFORM" = "docker" ]; then
        build_args="-t $REGISTRY/$IMAGE_NAME:$VERSION"

        if [ -n "$TAG" ]; then
            build_args="$build_args -t $REGISTRY/$IMAGE_NAME:$TAG"
        fi

        if [ "$ENVIRONMENT" = "development" ]; then
            build_args="$build_args --build-arg MODE=development"
            target_tag="--target jvm-runtime"
        elif [ "$NATIVE" = "true" ]; then
            build_args="$build_args --target native"
        fi

        if [ "$ENVIRONMENT" = "development" ]; then
            build_args="$build_args -t cncf-tech-advisor:dev"
        fi
    fi

    cd "$PROJECT_ROOT"

    log_info "Docker build command: docker build $build_args $target_tag"
    docker build $build_args $target_tag .

    log_success "Docker image built: $REGISTRY/$IMAGE_NAME:$VERSION"
}

push_docker_image() {
    log_info "Pushing Docker image to registry..."

    local tags="$REGISTRY/$IMAGE_NAME:$VERSION"
    if [ -n "$TAG" ]; then
        tags="$tags $REGISTRY/$IMAGE_NAME:$TAG"
    fi

    for tag in $tags; do
        log_info "Pushing $tag..."
        docker push "$tag"
    done

    log_success "Docker images pushed successfully"
}

# Kubernetes deployment functions
deploy_to_k8s() {
    log_info "Deploying to Kubernetes..."

    local namespace="cncf-tech-advisor"
    if [ "$ENVIRONMENT" != "production" ]; then
        namespace="$namespace-$ENVIRONMENT"
    fi

    # Create namespace if it doesn't exist
    kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

    # Apply Kubernetes manifests
    if [ -f "$PROJECT_ROOT/k8s/deployment.yaml" ]; then
        log_info "Applying Kubernetes deployment..."
        kubectl apply -f "$PROJECT_ROOT/k8s/" --namespace="$namespace"
    else
        log_error "Kubernetes manifests not found in k8s/ directory"
        exit 1
    fi

    log_success "Deployed to Kubernetes namespace: $namespace"
}

# NPM deployment functions
deploy_to_npm() {
    log_info "Preparing NPM package..."

    cd "$PROJECT_ROOT"

    # Update version if specified
    if [ "$VERSION" != "latest" ]; then
        npm version "$VERSION" --no-git-tag-version
    fi

    # Ensure package.json exists and is valid
    if [ ! -f "package.json" ]; then
        log_error "package.json not found"
        exit 1
    fi

    log_success "NPM package prepared"
}

publish_to_npm() {
    log_info "Publishing to NPM registry..."

    cd "$PROJECT_ROOT"

    if [ -n "$TAG" ] && [ "$TAG" != "latest" ]; then
        npm publish --tag "$TAG"
    else
        npm publish
    fi

    log_success "Published to NPM registry"
}

# Test deployment
test_deployment() {
    log_info "Testing deployment..."

    case "$PLATFORM" in
        docker)
            log_info "Testing Docker container..."
            if [ "$ENVIRONMENT" = "development" ]; then
                docker run --rm -p 8080:8080 \
                    -e QUARKUS_MCP_SERVER_STDIO_ENABLED=false \
                    "$REGISTRY/$IMAGE_NAME:$VERSION" \
                    java -jar quarkus-app/quarkus-run.jar &
                local container_id=$!
                sleep 10

                if curl -f http://localhost:8080/q/health >/dev/null 2>&1; then
                    log_success "Docker container is healthy"
                    docker stop "$container_id"
                else
                    log_error "Docker container health check failed"
                    docker stop "$container_id"
                    exit 1
                fi
            else
                log_warning "Skipping container test in production mode"
            fi
            ;;
        k8s)
            log_info "Checking Kubernetes deployment..."
            kubectl get pods -l app=cncf-tech-advisor --namespace="$namespace"
            ;;
        npm)
            log_info "Testing NPM installation..."
            npm install -g .
            log_success "NPM package installed globally"
            ;;
    esac

    log_success "Deployment test completed"
}

# Main deployment function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--platform)
                PLATFORM="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -r|--registry)
                REGISTRY="$2"
                shift 2
                ;;
            -t|--tag)
                TAG="$2"
                shift 2
                ;;
            --native)
                NATIVE="true"
                shift
                ;;
            --dev)
                ENVIRONMENT="development"
                DEV_MODE="true"
                shift
                ;;
            --skip-tests)
                SKIP_TESTS="true"
                shift
                ;;
            --push)
                PUSH="true"
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Validate configuration
    if [ ! -d "$PROJECT_ROOT" ]; then
        log_error "Project root directory not found: $PROJECT_ROOT"
        exit 1
    fi

    # Show configuration
    log_info "Deployment Configuration:"
    echo "   Platform: $PLATFORM"
    echo "   Environment: $ENVIRONMENT"
    echo "   Version: $VERSION"
    echo "   Registry: $REGISTRY"
    echo "   Native Build: ${NATIVE:-false}"
    echo "   Push: ${PUSH:-false}"
    echo

    # Execute deployment based on platform
    case "$PLATFORM" in
        docker)
            log_info "Starting Docker deployment..."
            build_application
            build_docker_image

            if [ "$PUSH" = "true" ]; then
                push_docker_image
            fi

            test_deployment
            ;;
        k8s)
            log_info "Starting Kubernetes deployment..."
            build_application
            deploy_to_k8s
            test_deployment
            ;;
        npm)
            log_info "Starting NPM deployment..."
            deploy_to_npm

            if [ "$PUSH" = "true" ]; then
                publish_to_npm
            fi

            test_deployment
            ;;
        *)
            log_error "Unsupported platform: $PLATFORM"
            show_help
            exit 1
            ;;
    esac

    log_success "Deployment completed successfully! 🎉"

    # Show next steps
    echo
    echo -e "${CYAN}📋 Next Steps:${NC}"
    case "$PLATFORM" in
        docker)
            echo "   Run: docker run -i --rm -p 8080:8080 $REGISTRY/$IMAGE_NAME:$VERSION"
            echo "   MCP STDIO: docker run -i --rm $REGISTRY/$IMAGE_NAME:$VERSION -Dquarkus.mcp.server.stdio.enabled=true"
            ;;
        k8s)
            echo "   Check: kubectl get pods -l app=cncf-tech-advisor --namespace=$namespace"
            echo "   Forward: kubectl port-forward deployment/cncf-tech-advisor 8080:8080 -n $namespace"
            ;;
        npm)
            echo "   Install: npm install -g cncf-tech-advisor"
            echo "   Run: cncf-tech-advisor"
            ;;
    esac
}

# Execute main function
main "$@"