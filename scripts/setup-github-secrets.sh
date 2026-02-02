#!/usr/bin/env bash
set -e

# Setup GitHub Secrets from infrastructure/aws/variables.json
# Requires: gh CLI installed and authenticated

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VARIABLES_FILE="$REPO_ROOT/infrastructure/aws/variables.json"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo "Install: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Not authenticated with GitHub CLI"
    echo "Run: gh auth login"
    exit 1
fi

# Check if variables file exists
if [ ! -f "$VARIABLES_FILE" ]; then
    echo "❌ Error: Variables file not found: $VARIABLES_FILE"
    exit 1
fi

echo "🔍 Reading configuration from: $VARIABLES_FILE"

# Read values from JSON
AWS_REGION=$(jq -r '.aws_region' "$VARIABLES_FILE")
S3_BUCKET_NAME=$(jq -r '.s3_bucket_name' "$VARIABLES_FILE")
CLOUDFRONT_DISTRIBUTION_ID=$(jq -r '.distribution_id' "$VARIABLES_FILE")

echo ""
echo "📝 Configuration values:"
echo "  AWS_REGION: $AWS_REGION"
echo "  S3_BUCKET_NAME: $S3_BUCKET_NAME"
echo "  CLOUDFRONT_DISTRIBUTION_ID: $CLOUDFRONT_DISTRIBUTION_ID"
echo ""

# Prompt for IAM Role ARN
echo "🔐 IAM Role ARN (not in variables.json):"
echo ""
echo "This should be the ARN of the GitHub Actions deployment role you created."
echo "Example: arn:aws:iam::123456789012:role/GitHubActionsDeploymentRole"
echo ""
read -p "Enter AWS_ROLE_ARN: " AWS_ROLE_ARN
echo ""

# Confirm before setting
echo "⚠️  About to set the following GitHub secrets:"
echo "  - AWS_ROLE_ARN"
echo "  - AWS_REGION"
echo "  - S3_BUCKET_NAME"
echo "  - CLOUDFRONT_DISTRIBUTION_ID"
echo ""
read -p "Continue? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 1
fi

echo ""
echo "🚀 Setting GitHub secrets..."

# Set secrets
gh secret set AWS_ROLE_ARN -b "$AWS_ROLE_ARN"
gh secret set AWS_REGION -b "$AWS_REGION"
gh secret set S3_BUCKET_NAME -b "$S3_BUCKET_NAME"
gh secret set CLOUDFRONT_DISTRIBUTION_ID -b "$CLOUDFRONT_DISTRIBUTION_ID"

echo ""
echo "✅ All secrets set successfully!"
echo ""
echo "Verify with: gh secret list"
