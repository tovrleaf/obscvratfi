#!/usr/bin/env bash
# Apply S3 Bucket Policy
# This script reads from variables.json and applies the bucket policy
# Usage: ./scripts/apply-s3-bucket-policy.sh

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
OAI_ID=$(jq -r '.oai_id' infrastructure/aws/variables.json)

if [ "$OAI_ID" = "YOUR_OAI_ID" ]; then
    log_error "OAI_ID is still a placeholder. Update infrastructure/aws/variables.json"
    exit 1
fi

log_info "Creating S3 bucket policy with OAI_ID: $OAI_ID"

# Create temporary policy file with actual values
TEMP_POLICY=$(mktemp)
cat > "$TEMP_POLICY" << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity/$OAI_ID"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
    }
  ]
}
EOF

log_info "Applying bucket policy..."

# Apply the policy
aws s3api put-bucket-policy \
  --bucket "$BUCKET_NAME" \
  --policy file://"$TEMP_POLICY" \
  --profile "$PROFILE"

# Clean up
rm -f "$TEMP_POLICY"

log_success "✅ Bucket policy applied successfully"
log_info "Bucket: $BUCKET_NAME"
log_info "OAI ID: $OAI_ID"
