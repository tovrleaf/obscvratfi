#!/usr/bin/env bash
# Create CloudFront Distribution
# This script reads from variables.json and creates CloudFront distribution
# Usage: ./scripts/create-cloudfront-distribution.sh

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

log_info "Reading variables from infrastructure/aws/variables.json..."

# Extract variables using jq
PROFILE=$(jq -r '.aws_profile' infrastructure/aws/variables.json)
BUCKET_NAME=$(jq -r '.s3_bucket_name' infrastructure/aws/variables.json)
AWS_REGION=$(jq -r '.aws_region' infrastructure/aws/variables.json)
OAI_ID=$(jq -r '.oai_id' infrastructure/aws/variables.json)

if [ "$OAI_ID" = "YOUR_OAI_ID" ]; then
    log_error "OAI_ID is still a placeholder. Update infrastructure/aws/variables.json"
    exit 1
fi

# Construct S3 domain
S3_DOMAIN="${BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com"

log_info "Creating CloudFront distribution configuration..."
log_info "S3 Bucket Domain: $S3_DOMAIN"
log_info "OAI ID: $OAI_ID"

# Create temporary distribution config with actual values
TEMP_CONFIG=$(mktemp)
cat > "$TEMP_CONFIG" << 'EOF'
{
  "CallerReference": "CALLER_REFERENCE",
  "Comment": "Obscvrat website distribution",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3Origin",
        "DomainName": "S3_DOMAIN",
        "S3OriginConfig": {
          "OriginAccessIdentity": "origin-access-identity/cloudfront/OAI_ID"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3Origin",
    "ViewerProtocolPolicy": "redirect-to-https",
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000
  },
  "Enabled": true,
  "PriceClass": "PriceClass_100"
}
EOF

# Replace placeholders
sed -i '' "s|CALLER_REFERENCE|$(date +%s)|g" "$TEMP_CONFIG"
sed -i '' "s|S3_DOMAIN|$S3_DOMAIN|g" "$TEMP_CONFIG"
sed -i '' "s|OAI_ID|$OAI_ID|g" "$TEMP_CONFIG"

log_info "Creating CloudFront distribution..."

# Create distribution
aws cloudfront create-distribution \
  --distribution-config file://"$TEMP_CONFIG" \
  --profile "$PROFILE" > /tmp/cloudfront-response.json

# Extract important info
DISTRIBUTION_ID=$(jq -r '.Distribution.Id' /tmp/cloudfront-response.json)
CLOUDFRONT_DOMAIN=$(jq -r '.Distribution.DomainName' /tmp/cloudfront-response.json)

# Clean up
rm -f "$TEMP_CONFIG"

log_success "✅ CloudFront distribution created successfully"
echo ""
log_info "Distribution ID: $DISTRIBUTION_ID"
log_info "CloudFront Domain: $CLOUDFRONT_DOMAIN"
echo ""
echo "Update your variables.json with these values:"
echo "  \"distribution_id\": \"$DISTRIBUTION_ID\","
echo "  \"cloudfront_domain\": \"$CLOUDFRONT_DOMAIN\""
