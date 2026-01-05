# AWS Infrastructure Setup Guide

This guide walks you through setting up the AWS infrastructure for the Obscvrat website using the pre-configured JSON files in this directory.

**Estimated time:** 30-45 minutes  
**Prerequisites:** AWS account, AWS CLI installed & configured  
**Related:** [ADR-003: Website Hosting & Infrastructure decisions](../docs/adr/003-website-hosting-static-site-generation-seo-strategy.md)

---

## Quick Start Checklist

- [ ] AWS CLI installed and working
- [ ] AWS IAM user created with appropriate permissions
- [ ] AWS profile configured locally
- [ ] Review architecture diagram below
- [ ] Create `aws/variables.json` from template
- [ ] Follow steps 1-7 below (30-45 minutes)
- [ ] Run verification commands
- [ ] Deploy website (see docs/DEPLOYMENT.md)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your Development                         │
│                         Environment                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                      Local Hugo Build
                             │
                             ▼
                    ┌────────────────┐
                    │   S3 Bucket    │  (obscvrat-website)
                    │   (Static      │  Stores: HTML, CSS, JS, Images
                    │   Content)     │  Access: via CloudFront OAI
                    └────────────────┘
                             ▲
                             │
                    ┌────────┴─────────┐
                    │                  │
            ┌───────────────┐  ┌──────────────┐
            │  CloudFront   │  │  Route 53    │
            │  (CDN)        │  │  (DNS)       │
            │  Global Cache │  │  obscvrat.fi │
            └───────────────┘  └──────────────┘
                    │
                    ▼
            ┌──────────────────┐
            │  End User        │
            │  Browser         │
            │  obscvrat.fi     │
            └──────────────────┘
```

---

## Prerequisites

### Required Software

```bash
# Check if AWS CLI is installed
aws --version

# Check if jq is installed (for parsing JSON)
jq --version

# If missing, install:
# macOS:
brew install awscli jq

# Linux (Ubuntu/Debian):
sudo apt-get install awscli jq

# Linux (Fedora):
sudo dnf install awscli jq
```

### AWS Account Setup

1. **Create AWS Account** at https://aws.amazon.com if you don't have one
2. **Create IAM User** with these permissions:
   - S3: `s3:*` (full S3 access for this bucket)
   - CloudFront: `cloudfront:*` (full CloudFront access)
   - Route 53: `route53:ChangeResourceRecordSets` (DNS management)
   - ACM: `acm:*` (SSL certificate management)

3. **Create Access Key** for the IAM user
4. **Configure AWS CLI Profile**:
   ```bash
   aws configure --profile obscvrat
   # Enter: AWS Access Key ID
   # Enter: AWS Secret Access Key
   # Enter: Default region: eu-west-1
   # Enter: Default output format: json
   ```

### Verify Setup

```bash
# Test your AWS profile works
aws s3 ls --profile obscvrat

# Should list your existing S3 buckets (or be empty)
# If error: Check AWS credentials and IAM permissions
```

---

## Part 1: Obtaining Required AWS Values

Before running the infrastructure setup, you need to collect several AWS identifiers. This section explains how to get each one.

### 1.1 Create Origin Access Identity (OAI) and Get OAI_ID

The OAI allows CloudFront to access S3 securely without making the bucket public.

**Run this command:**

```bash
PROFILE=obscvrat  # Change if using different profile name

aws cloudfront create-cloud-front-origin-access-identity \
  --cloud-front-origin-access-identity-config \
    CallerReference=$(date +%s),Comment="Obscvrat OAI" \
  --profile $PROFILE
```

**Expected output:**

```json
{
  "CloudFrontOriginAccessIdentity": {
    "Id": "E1234567890ABC",
    "S3CanonicalUserId": "...",
    "CloudFrontOriginAccessIdentityConfig": {
      "CallerReference": "1234567890",
      "Comment": "Obscvrat OAI"
    }
  },
  "ETag": "..."
}
```

**What to save:**

Extract the `Id` value (without the `E` prefix):

```bash
# Extract OAI_ID and save to file
aws cloudfront create-cloud-front-origin-access-identity \
  --cloud-front-origin-access-identity-config \
    CallerReference=$(date +%s),Comment="Obscvrat OAI" \
  --profile $PROFILE | jq -r '.CloudFrontOriginAccessIdentity.Id' | sed 's/^E//'
```

**Result looks like:** `1234567890ABC`

**Save this value** as `oai_id` in your `aws/variables.json`

---

### 1.2 Verify AWS Profile and Permissions

Before proceeding, ensure your AWS profile has all necessary permissions.

**Test S3 access:**

```bash
PROFILE=obscvrat

aws s3 ls --profile $PROFILE
# Should list your S3 buckets or be empty (no error)

aws s3api list-buckets --profile $PROFILE
# Verify you can list buckets
```

**Test CloudFront access:**

```bash
aws cloudfront list-distributions --profile $PROFILE
# Should list distributions or be empty

# If you get "UnauthorizedOperation" error, your IAM user lacks CloudFront permissions
```

**If you get permission errors**, you need to add more permissions to your IAM user:

1. Log in to AWS Console
2. Go to IAM → Users → Select your user
3. Click "Add permissions" → "Attach policies directly"
4. Add: `CloudFrontFullAccess`, `S3FullAccess`, `Route53FullAccess`, `ACMFullAccess`
5. Wait 1-2 minutes for permissions to apply

---

## Part 2: Setup Configuration Files

### 2.1 Create Your Variables File

This file stores your personal AWS configuration. **Never commit this file to Git** - it contains your AWS resource IDs.

**Step 1:** Copy the template

```bash
cp infrastructure/aws/variables.example.json infrastructure/aws/variables.json
```

**Step 2:** Edit with your values

```bash
nano infrastructure/aws/variables.json
```

**Step 3:** Fill in all values

Refer to the sections below to understand what each value means:

| Variable | What it is | Example |
|----------|-----------|---------|
| `aws_profile` | Your AWS CLI profile name | `obscvrat` |
| `aws_region` | AWS region for S3 | `eu-west-1` |
| `s3_bucket_name` | Name of S3 bucket to create | `obscvrat-website` |
| `domain_name` | Your custom domain | `obscvrat.fi` |
| `oai_id` | Origin Access Identity ID (from section 1.1) | `1234567890ABC` |
| `distribution_id` | CloudFront Distribution ID (created in step 3) | `D1234ABCD` |
| `hosted_zone_id` | Route 53 Hosted Zone ID (from section 1.3) | `Z1234567890ABC` |
| `cloudfront_domain` | CloudFront distribution domain (from step 3) | `d1234abcd.cloudfront.net` |

---

### 2.2 Understand the JSON Configuration Files

The JSON files in `aws/` directory are templates that reference your variables.

**Files:**

- **`s3-bucket-policy.json`** - Allows CloudFront to access S3 bucket
  - Contains: `YOUR_OAI_ID` placeholder (replace with your OAI_ID)
  - Contains: Bucket name `obscvrat-website`

- **`cloudfront-distribution.json`** - CloudFront CDN configuration
  - Contains: `YOUR_OAI_ID` placeholder
  - Contains: S3 bucket domain reference
  - Settings: HTTPS redirect, HTTP/2, caching, price class

- **`route53-dns-changes.json`** - DNS record configuration
  - Contains: `ZONE_ID` placeholder (replace with your Hosted Zone ID)
  - Contains: CloudFront domain reference
  - Creates: A record pointing domain to CloudFront

---

## Part 3: Step-by-Step Infrastructure Setup

### Step 1: Create S3 Bucket

```bash
PROFILE=obscvrat
BUCKET_NAME=obscvrat-website
REGION=eu-west-1

# Create the bucket
aws s3 mb s3://$BUCKET_NAME \
  --region $REGION \
  --profile $PROFILE

echo "✅ Bucket created: s3://$BUCKET_NAME"
```

### Step 2: Enable Versioning on S3 Bucket

Versioning allows you to recover previous versions if something goes wrong.

```bash
PROFILE=obscvrat
BUCKET_NAME=obscvrat-website

aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled \
  --profile $PROFILE

echo "✅ Versioning enabled"
```

### Step 3: Block Public Access to S3 Bucket

Ensure the bucket is private - only CloudFront can access it.

```bash
PROFILE=obscvrat
BUCKET_NAME=obscvrat-website

aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile $PROFILE

echo "✅ Public access blocked"
```

### Step 4: Apply S3 Bucket Policy

This allows CloudFront (via OAI) to read files from S3.

**First, update the JSON file with your OAI_ID:**

```bash
# Edit the file
nano infrastructure/aws/s3-bucket-policy.json

# Find the line with "YOUR_OAI_ID" and replace with your actual OAI_ID
# (from section 1.1 above)
```

**Then apply the policy:**

```bash
PROFILE=obscvrat
BUCKET_NAME=obscvrat-website

aws s3api put-bucket-policy \
  --bucket $BUCKET_NAME \
  --policy file://infrastructure/aws/s3-bucket-policy.json \
  --profile $PROFILE

echo "✅ Bucket policy applied"
```

### Step 5: Create CloudFront Distribution

**First, prepare the JSON configuration:**

```bash
# Edit to set your OAI_ID and S3 bucket domain
nano infrastructure/aws/cloudfront-distribution.json

# Replace:
# - "YOUR_OAI_ID" with your actual OAI_ID (from section 1.1)
# - "obscvrat-website.s3.eu-west-1.amazonaws.com" with your S3 domain
```

**Create the distribution:**

```bash
PROFILE=obscvrat

aws cloudfront create-distribution \
  --distribution-config file://infrastructure/aws/cloudfront-distribution.json \
  --profile $PROFILE > /tmp/cloudfront-response.json

echo "✅ CloudFront distribution created"

# Extract important IDs
DISTRIBUTION_ID=$(jq -r '.Distribution.Id' /tmp/cloudfront-response.json)
CLOUDFRONT_DOMAIN=$(jq -r '.Distribution.DomainName' /tmp/cloudfront-response.json)

echo "Distribution ID: $DISTRIBUTION_ID"
echo "CloudFront Domain: $CLOUDFRONT_DOMAIN"

# Save these to your variables.json
```

**What to save:**

- `distribution_id` = Distribution ID (e.g., `D1234ABCD`)
- `cloudfront_domain` = Domain Name (e.g., `d1234abcd.cloudfront.net`)

---

### Step 6: Get Route 53 Hosted Zone ID

If your domain is already in Route 53, find its Hosted Zone ID.

```bash
PROFILE=obscvrat
DOMAIN_NAME=obscvrat.fi

# List all hosted zones
aws route53 list-hosted-zones --profile $PROFILE

# Find your domain, look for the Id field
# It looks like: /hostedzone/Z1234567890ABC
# Extract just: Z1234567890ABC
```

**Using jq to extract:**

```bash
PROFILE=obscvrat
DOMAIN_NAME=obscvrat.fi

ZONE_ID=$(aws route53 list-hosted-zones \
  --profile $PROFILE | \
  jq -r ".HostedZones[] | select(.Name==\"$DOMAIN_NAME.\") | .Id" | \
  cut -d'/' -f3)

echo "Hosted Zone ID: $ZONE_ID"

# Save this as hosted_zone_id in variables.json
```

**If domain is not in Route 53**, create a hosted zone:

```bash
PROFILE=obscvrat
DOMAIN_NAME=obscvrat.fi

aws route53 create-hosted-zone \
  --name $DOMAIN_NAME \
  --caller-reference $(date +%s) \
  --profile $PROFILE

# Extract Zone ID from response
# Then save the nameservers to your domain registrar
```

---

### Step 7: Create DNS Record Pointing to CloudFront

**Prepare the JSON file:**

```bash
# Edit to set your Zone ID and CloudFront domain
nano infrastructure/aws/route53-dns-changes.json

# Replace:
# - "ZONE_ID" with your Hosted Zone ID (from step 6)
# - "d1234abcd.cloudfront.net" with your CloudFront domain (from step 5)
```

**Create the DNS record:**

```bash
PROFILE=obscvrat
ZONE_ID=Z1234567890ABC  # Your Zone ID from step 6

aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch file://infrastructure/aws/route53-dns-changes.json \
  --profile $PROFILE

echo "✅ DNS record created"
```

---

### Step 8: Request SSL Certificate (ACM)

Request a free SSL/TLS certificate for HTTPS.

```bash
PROFILE=obscvrat
DOMAIN_NAME=obscvrat.fi

# Request certificate in us-east-1 (required for CloudFront)
aws acm request-certificate \
  --domain-name $DOMAIN_NAME \
  --subject-alternative-names www.$DOMAIN_NAME \
  --region us-east-1 \
  --profile $PROFILE

echo "✅ Certificate requested"

# AWS will send verification emails
# Check your email and click verification links
# This can take 5-30 minutes
```

**After certificate is verified:**

1. Go to AWS ACM console (us-east-1 region)
2. Find your certificate
3. Note the Certificate ARN
4. Go to CloudFront distribution
5. Edit → SSL Certificate → Select your certificate
6. Save

---

## Verification Checklist

After completing all steps, verify everything works:

### ✅ S3 Bucket Exists and is Secure

```bash
PROFILE=obscvrat
BUCKET_NAME=obscvrat-website

# Bucket exists
aws s3 ls s3://$BUCKET_NAME --profile $PROFILE

# Bucket is private (no public access block errors)
aws s3api get-public-access-block \
  --bucket $BUCKET_NAME \
  --profile $PROFILE | jq '.PublicAccessBlockConfiguration'
```

### ✅ CloudFront Distribution is Active

```bash
PROFILE=obscvrat
DISTRIBUTION_ID=D1234ABCD

# Distribution exists
aws cloudfront get-distribution \
  --id $DISTRIBUTION_ID \
  --profile $PROFILE | jq '.Distribution.Status'

# Should output: "Deployed" or "InProgress"
```

### ✅ DNS Records Point to CloudFront

```bash
DOMAIN_NAME=obscvrat.fi

# Check DNS resolution
dig $DOMAIN_NAME +short
# Should show CloudFront domain (d*.cloudfront.net)

# Or use nslookup
nslookup $DOMAIN_NAME
```

### ✅ HTTPS Works

```bash
DOMAIN_NAME=obscvrat.fi

# Check SSL certificate
openssl s_client -connect $DOMAIN_NAME:443 -servername $DOMAIN_NAME 2>/dev/null | \
  openssl x509 -noout -dates

# Should show valid dates
```

### ✅ Website is Accessible

```bash
DOMAIN_NAME=obscvrat.fi

# Test HTTP (should redirect to HTTPS)
curl -I http://$DOMAIN_NAME

# Test HTTPS
curl -I https://$DOMAIN_NAME

# Both should return HTTP 200 or 403 (403 is ok - it means CloudFront is responding)
```

---

## Troubleshooting

### Error: "AccessDenied" when creating bucket

**Problem:** Your IAM user doesn't have S3 permissions

**Solution:**
1. Go to AWS IAM console
2. Find your user
3. Add policy: `AmazonS3FullAccess`
4. Wait 1-2 minutes
5. Try again

---

### Error: "The provided token has expired" (ACM certificate)

**Problem:** Session token expired during setup

**Solution:**
```bash
# Refresh your AWS credentials
aws configure --profile obscvrat

# Re-run the failed command
```

---

### Error: "InvalidInput.IncompatibleS3Origin"

**Problem:** CloudFront distribution config has wrong S3 domain

**Solution:**
1. Check S3 domain in `cloudfront-distribution.json`
2. Should be: `bucket-name.s3.region.amazonaws.com`
3. Update and try again

---

### Domain not resolving

**Problem:** DNS record didn't create or DNS cache not refreshed

**Solution:**
```bash
# Force DNS cache clear (macOS)
sudo dscacheutil -flushcache

# Force DNS cache clear (Linux)
sudo systemctl restart nscd

# Wait 5 minutes and try again
# DNS can take up to 48 hours to fully propagate
```

---

### SSL Certificate shows "Not Trusted"

**Problem:** Certificate not attached to CloudFront or still pending verification

**Solution:**
1. Check ACM certificate status (us-east-1 region)
2. Verify it says "Issued" (not "Pending Validation")
3. Edit CloudFront distribution
4. Add certificate to default cache behavior
5. Wait 15-30 minutes for CloudFront to deploy

---

### Website returns 403 Forbidden

**Problem:** Either S3 bucket policy is wrong, or files haven't been uploaded

**Solution:**
```bash
# Check bucket policy is applied
aws s3api get-bucket-policy --bucket obscvrat-website

# Check OAI ID in policy matches your OAI_ID

# Upload test file
echo "test" | aws s3 cp - s3://obscvrat-website/test.txt

# Try CloudFront domain directly
curl https://d1234abcd.cloudfront.net/test.txt
```

---

### CloudFront distribution stuck "InProgress"

**Problem:** Distribution deployment can take 10-15 minutes

**Solution:**
```bash
# Check status
aws cloudfront get-distribution --id D1234ABCD | jq '.Distribution.Status'

# Wait and check again in 5 minutes
# This is normal - be patient
```

---

## Next Steps

### 1. Deploy the Website

Once infrastructure is ready, deploy your built website:

```bash
./scripts/deploy.sh production
```

See `docs/DEPLOYMENT.md` for detailed deployment instructions.

### 2. Monitor and Maintain

See `docs/DEPLOYMENT.md` sections on:
- Monitoring CloudFront metrics
- S3 bucket size
- Cost monitoring
- Rollback procedures

### 3. Setup Automated Deployments (Future)

Consider creating:
- GitHub Actions workflow to auto-deploy on main branch merge
- Lambda functions for smart cache invalidation
- CloudWatch alerts for errors

---

## Cost Estimation

**Rough monthly costs** (based on typical band website traffic):

| Service | Usage | Cost |
|---------|-------|------|
| S3 | 1 GB storage | ~$0.02 |
| CloudFront | 10 GB data transfer | ~$1.20 |
| Route 53 | 1 hosted zone | ~$0.50 |
| ACM | SSL certificate | Free |
| **Total** | | **~$1.70/month** |

*Note: Prices vary by region and traffic. Use AWS Calculator for accurate estimates.*

---

## Related Documentation

- **[ADR-003: Website Hosting & Infrastructure decisions](../docs/adr/003-website-hosting-static-site-generation-seo-strategy.md)**
  - Architecture decisions and rationale
  - Why S3 + CloudFront vs alternatives

- **[docs/DEPLOYMENT.md](../docs/DEPLOYMENT.md)**
  - Deploying website after infrastructure is ready
  - Monitoring and maintenance
  - Rollback procedures

- **AWS Documentation:**
  - [S3 Documentation](https://docs.aws.amazon.com/s3/)
  - [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
  - [Route 53 Documentation](https://docs.aws.amazon.com/route53/)
  - [ACM Documentation](https://docs.aws.amazon.com/acm/)

---

**Last Updated:** January 2026  
**Infrastructure Version:** 1.0  
**Status:** Production Ready
