#!/usr/bin/env bash
set -e

# Generate GitHub Actions deployment policy with actual values
# Reads from infrastructure/aws/variables.json

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VARIABLES_FILE="$REPO_ROOT/infrastructure/aws/variables.json"
POLICY_TEMPLATE="$REPO_ROOT/infrastructure/aws/iam-policy-github-actions-deployment.json"

# Check if variables file exists
if [ ! -f "$VARIABLES_FILE" ]; then
    echo "❌ Error: Variables file not found: $VARIABLES_FILE"
    exit 1
fi

# Check if policy template exists
if [ ! -f "$POLICY_TEMPLATE" ]; then
    echo "❌ Error: Policy template not found: $POLICY_TEMPLATE"
    exit 1
fi

# Read values from JSON
DISTRIBUTION_ID=$(jq -r '.distribution_id' "$VARIABLES_FILE")

if [ "$DISTRIBUTION_ID" = "null" ] || [ -z "$DISTRIBUTION_ID" ]; then
    echo "❌ Error: distribution_id not found in $VARIABLES_FILE"
    exit 1
fi

echo "📋 GitHub Actions Deployment Policy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "CloudFront Distribution ID: $DISTRIBUTION_ID"
echo ""
echo "Copy the policy below and paste it when creating the IAM role:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Replace placeholder and output
jq --arg dist_id "$DISTRIBUTION_ID" \
  '.Statement[1].Resource = "arn:aws:cloudfront::*:distribution/" + $dist_id' \
  "$POLICY_TEMPLATE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
