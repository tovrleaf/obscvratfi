#!/usr/bin/env bash
# Create CloudFront Origin Access Identity (OAI)
# This script creates a new OAI and displays both the ID and S3 Canonical User ID
# Usage: ./scripts/create-oai.sh

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

# Check if variables.json exists
if [ ! -f "infrastructure/aws/variables.json" ]; then
    log_error "variables.json not found!"
    echo "Create it with: cp infrastructure/aws/variables.example.json infrastructure/aws/variables.json"
    exit 1
fi

# Extract profile
PROFILE=$(jq -r '.aws_profile' infrastructure/aws/variables.json)

log_info "Creating CloudFront Origin Access Identity..."

# Create OAI
RESPONSE=$(aws cloudfront create-cloud-front-origin-access-identity \
  --cloud-front-origin-access-identity-config \
    CallerReference="$(date +%s)",Comment="Obscvrat OAI" \
  --profile "$PROFILE")

# Extract values
OAI_ID=$(echo "$RESPONSE" | jq -r '.CloudFrontOriginAccessIdentity.Id')
S3_CANONICAL_USER_ID=$(echo "$RESPONSE" | jq -r '.CloudFrontOriginAccessIdentity.S3CanonicalUserId')

log_success "✅ CloudFront OAI created successfully"
echo ""
echo "Update your variables.json with these values:"
echo ""
echo "  \"oai_id\": \"$OAI_ID\","
echo "  \"s3_canonical_user_id\": \"$S3_CANONICAL_USER_ID\""
echo ""
echo "Or run this to update automatically:"
echo ""
echo "  jq '.oai_id = \"$OAI_ID\"' infrastructure/aws/variables.json > /tmp/vars.json && mv /tmp/vars.json infrastructure/aws/variables.json"
echo "  jq '.s3_canonical_user_id = \"$S3_CANONICAL_USER_ID\"' infrastructure/aws/variables.json > /tmp/vars.json && mv /tmp/vars.json infrastructure/aws/variables.json"
