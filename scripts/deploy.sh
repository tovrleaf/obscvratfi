#!/bin/bash

# Obscvrat Website Deployment Script
# Automates building and deploying the site to AWS S3 + CloudFront
# Usage: ./scripts/deploy.sh [--dry-run]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
WEBSITE_DIR="$PROJECT_ROOT/website"
PUBLIC_DIR="$WEBSITE_DIR/public"

# Load environment configuration
load_config() {
    CONFIG_FILE="$SCRIPT_DIR/.deploy-config.production"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Error: Config file not found: $CONFIG_FILE${NC}"
        echo "Please create the config file or run: ./scripts/setup-deploy.sh"
        exit 1
    fi
    
    # Source the config file (sets S3_BUCKET, DISTRIBUTION_ID, AWS_PROFILE, AWS_REGION)
    source "$CONFIG_FILE"
}

# Validate environment variables
validate_config() {
    local required_vars=("S3_BUCKET" "DISTRIBUTION_ID" "AWS_PROFILE" "AWS_REGION")
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo -e "${RED}Error: $var is not set${NC}"
            exit 1
        fi
    done
}

# Build the site
build_site() {
    local dry_run=$1
    
    echo -e "${BLUE}Building site for production...${NC}"
    
    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}(DRY RUN - no changes will be made)${NC}"
    fi
    
    make -C "$PROJECT_ROOT" build-prod
    
    echo -e "${GREEN}✓ Build complete${NC}"
}

# Sync to S3
sync_to_s3() {
    local dry_run=$1
    
    echo -e "${BLUE}Syncing to S3 bucket: $S3_BUCKET${NC}"
    
    if [ ! -d "$PUBLIC_DIR" ]; then
        echo -e "${RED}Error: Build directory not found: $PUBLIC_DIR${NC}"
        exit 1
    fi
    
    local aws_opts="--region $AWS_REGION --profile $AWS_PROFILE"
    
    if [ "$dry_run" = "true" ]; then
        aws_opts="$aws_opts --dryrun"
        echo "Running in DRY RUN mode..."
    fi
    
    # Sync files
    aws s3 sync "$PUBLIC_DIR/" "s3://$S3_BUCKET" \
        --delete \
        $aws_opts
    
    echo -e "${GREEN}✓ S3 sync complete${NC}"
}

# Invalidate CloudFront cache
invalidate_cloudfront() {
    local dry_run=$1
    
    echo -e "${BLUE}Invalidating CloudFront distribution: $DISTRIBUTION_ID${NC}"
    
    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}(DRY RUN - cache would be invalidated for: /*)${NC}"
        return 0
    fi
    
    local invalidation=$(aws cloudfront create-invalidation \
        --distribution-id "$DISTRIBUTION_ID" \
        --paths "/*" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --query 'Invalidation.Id' \
        --output text)
    
    echo -e "${GREEN}✓ Invalidation created: $invalidation${NC}"
    
    # Wait for invalidation (optional, commented out by default)
    # echo "Waiting for invalidation to complete..."
    # aws cloudfront wait invalidation-completed \
    #     --distribution-id "$DISTRIBUTION_ID" \
    #     --id "$invalidation" \
    #     --profile "$AWS_PROFILE"
    # echo -e "${GREEN}✓ Invalidation complete${NC}"
}

# Verify deployment
verify_deployment() {
    local domain=$1
    
    echo -e "${BLUE}Verifying deployment at: $domain${NC}"
    
    # Check if domain responds
    if curl -f -s -o /dev/null -w "%{http_code}" "https://$domain/" | grep -q "200"; then
        echo -e "${GREEN}✓ Website is accessible${NC}"
    else
        echo -e "${YELLOW}⚠ Website returned non-200 status code${NC}"
    fi
    
    # Check SSL certificate
    if echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | grep -q "Verify return code: 0"; then
        echo -e "${GREEN}✓ SSL certificate is valid${NC}"
    else
        echo -e "${YELLOW}⚠ SSL certificate verification failed${NC}"
    fi
}

# Show help
show_help() {
    cat << EOF
${BLUE}Obscvrat Website Deployment Script${NC}

Usage: $0 [options]

Options:
  --dry-run     Show what would be done without making changes
  --no-verify   Skip verification checks after deployment
  --help        Show this help message

Examples:
  # Deploy to production
  $0

  # Test deployment without making changes
  $0 --dry-run

  # Deploy without verification
  $0 --no-verify

Configuration:
  Create .deploy-config.production file in the scripts directory with:
    S3_BUCKET="your-bucket"
    DISTRIBUTION_ID="your-dist-id"
    AWS_PROFILE="your-profile"
    AWS_REGION="eu-west-1"
    DOMAIN="obscvrat.fi"  # For verification

EOF
}

# Main deployment flow
deploy() {
    local dry_run=$1
    local skip_verify=$2
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Obscvrat Website Deployment${NC}"
    echo -e "${BLUE}========================================${NC}"
    if [ "$dry_run" = "true" ]; then
        echo "Mode: DRY RUN"
    fi
    echo ""
    
    # Load and validate configuration
    load_config
    validate_config
    
    # Build
    build_site "$dry_run"
    echo ""
    
    # Sync
    sync_to_s3 "$dry_run"
    echo ""
    
    # Invalidate cache
    invalidate_cloudfront "$dry_run"
    echo ""
    
    # Verify (unless skipped or dry-run)
    if [ "$skip_verify" != "true" ] && [ "$dry_run" != "true" ]; then
        verify_deployment "$DOMAIN"
        echo ""
    fi
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Deployment complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Parse arguments
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

dry_run=false
skip_verify=false

for arg in "$@"; do
    case $arg in
        --dry-run)
            dry_run=true
            ;;
        --no-verify)
            skip_verify=true
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

# Run deployment
deploy "$dry_run" "$skip_verify"
