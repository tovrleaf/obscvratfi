#!/usr/bin/env bash
# Create DNS Record for CloudFront
# This script reads from variables.json and creates Route 53 DNS record
# Usage: ./scripts/create-dns-record.sh

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
DOMAIN_NAME=$(jq -r '.domain_name' infrastructure/aws/variables.json)
HOSTED_ZONE_ID=$(jq -r '.hosted_zone_id' infrastructure/aws/variables.json)
CLOUDFRONT_DOMAIN=$(jq -r '.cloudfront_domain' infrastructure/aws/variables.json)

if [ "$HOSTED_ZONE_ID" = "YOUR_ZONE_ID" ]; then
    log_error "hosted_zone_id is still a placeholder. Update infrastructure/aws/variables.json"
    exit 1
fi

if [ "$CLOUDFRONT_DOMAIN" = "YOUR_DISTRIBUTION_DOMAIN.cloudfront.net" ]; then
    log_error "cloudfront_domain is still a placeholder. Update infrastructure/aws/variables.json"
    exit 1
fi

log_info "Creating DNS record configuration..."
log_info "Domain: $DOMAIN_NAME"
log_info "CloudFront Domain: $CLOUDFRONT_DOMAIN"
log_info "Hosted Zone ID: $HOSTED_ZONE_ID"

# Create temporary DNS changes file with actual values
TEMP_CHANGES=$(mktemp)
cat > "$TEMP_CHANGES" << EOF
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "$DOMAIN_NAME",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "$CLOUDFRONT_DOMAIN",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

log_info "Creating DNS record..."

# Create the DNS record
aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch file://"$TEMP_CHANGES" \
  --profile "$PROFILE"

# Clean up
rm -f "$TEMP_CHANGES"

log_success "✅ DNS record created successfully"
log_info "Domain: $DOMAIN_NAME now points to CloudFront: $CLOUDFRONT_DOMAIN"
echo ""
echo "DNS may take up to 48 hours to fully propagate."
echo "You can check with: dig $DOMAIN_NAME +short"
