#!/bin/bash

# Build script for Hugo site with various configurations
# Provides convenient build options without having to remember Hugo flags

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Build function
build() {
    local build_type=$1
    local target_dir="${PROJECT_ROOT}/website/public"
    
    echo -e "${BLUE}Building Hugo site...${NC}"
    echo "Build type: $build_type"
    echo "Output directory: $target_dir"
    echo ""
    
    case $build_type in
        dev)
            echo "Building for development (unminified, localhost)..."
            cd "$PROJECT_ROOT"
            make build
            ;;
        prod)
            echo "Building for production (minified, obscvrat.fi)..."
            cd "$PROJECT_ROOT"
            make build-prod
            ;;
        staging)
            if [ -z "$DISTRIBUTION_ID" ]; then
                echo -e "${RED}Error: DISTRIBUTION_ID environment variable not set${NC}"
                echo "Usage: DISTRIBUTION_ID=d1234.cloudfront.net $0 staging"
                exit 1
            fi
            echo "Building for staging (minified, $DISTRIBUTION_ID)..."
            cd "$PROJECT_ROOT"
            make build-staging DISTRIBUTION_ID="$DISTRIBUTION_ID"
            ;;
        minify)
            echo "Building with minification enabled (localhost)..."
            cd "$PROJECT_ROOT"
            make build-minified
            ;;
        *)
            echo -e "${RED}Unknown build type: $build_type${NC}"
            show_help
            exit 1
            ;;
    esac
    
    # Show build results
    echo ""
    echo -e "${GREEN}✓ Build complete!${NC}"
    echo ""
    
    # Count files
    local file_count=$(find "$target_dir" -type f | wc -l)
    local dir_count=$(find "$target_dir" -type d | wc -l)
    local total_size=$(du -sh "$target_dir" | cut -f1)
    
    echo "Build statistics:"
    echo "  Files: $file_count"
    echo "  Directories: $dir_count"
    echo "  Total size: $total_size"
    echo ""
    
    # Show key files
    echo "Key files generated:"
    ls -lh "$target_dir"/index.html "$target_dir"/feed.xml "$target_dir"/sitemap.xml
}

# Show help
show_help() {
    cat << EOF
${BLUE}Obscvrat Hugo Build Script${NC}

Usage: $0 <build-type> [options]

Build types:
  dev        Development build (unminified, localhost)
  prod       Production build (minified, obscvrat.fi)
  staging    Staging build (minified, CloudFront)
  minify     Test minification (localhost)

Options:
  --clean    Remove build directory before building
  --watch    Watch for changes (dev builds only)
  --help     Show this help message

Examples:
  # Build for development
  $0 dev

  # Build for production
  $0 prod

  # Build for staging with CloudFront domain
  DISTRIBUTION_ID=d1234.cloudfront.net $0 staging

  # Clean and rebuild
  $0 dev --clean

  # Watch for changes during development
  $0 dev --watch

Environment variables:
  DISTRIBUTION_ID  CloudFront distribution ID (for staging builds)

EOF
}

# Parse arguments
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

build_type=$1
shift

# Process options
clean_build=false
watch_mode=false

for arg in "$@"; do
    case $arg in
        --clean)
            clean_build=true
            ;;
        --watch)
            watch_mode=true
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Clean build directory if requested
if [ "$clean_build" = true ]; then
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    rm -rf "${PROJECT_ROOT}/website/public"
fi

# Handle watch mode
if [ "$watch_mode" = true ]; then
    if [ "$build_type" != "dev" ]; then
        echo -e "${YELLOW}Warning: Watch mode is only recommended for dev builds${NC}"
    fi
    
    echo -e "${BLUE}Starting development server with hot reload...${NC}"
    echo "Visit: http://localhost:1313"
    echo "Press Ctrl+C to stop"
    echo ""
    
    cd "$PROJECT_ROOT"
    make serve
else
    build "$build_type"
fi
