# Deployment Guide

Complete guide for deploying the Obscvrat website to AWS S3 and CloudFront.

## Overview

The Obscvrat website is deployed using:
- **S3 Bucket**: Stores the static HTML, CSS, JS, and media files
- **CloudFront**: Content Delivery Network (CDN) for fast global distribution
- **Route 53**: DNS (optional, if using AWS for domain management)
- **ACM**: SSL/TLS certificates for HTTPS

## Architecture

```
Developer
    ↓ (push to GitHub)
GitHub Repository
    ↓ (CI/CD pipeline or manual build)
Hugo Build
    ↓ (generates website/public/)
S3 Bucket (static content)
    ↓ (cached by CDN)
CloudFront Distribution
    ↓ (serve to users)
obscvrat.fi (custom domain)
```

## Prerequisites

- AWS Account with appropriate permissions (S3, CloudFront, Route 53)
- AWS CLI configured locally
- Make (for build commands)
- Docker (for building)

### Required AWS Permissions

Your IAM user should have permissions for:
- S3: `s3:PutObject`, `s3:GetObject`, `s3:ListBucket`, `s3:DeleteObject`
- CloudFront: `cloudfront:CreateInvalidation`
- Route 53: `route53:ChangeResourceRecordSets` (if managing DNS)

## Step 1: Create S3 Bucket

### 1.1 Create the bucket

```bash
aws s3 mb s3://obscvrat-website \
  --region eu-west-1 \
  --profile YOUR_PROFILE
```

### 1.2 Enable versioning (optional but recommended)

```bash
aws s3api put-bucket-versioning \
  --bucket obscvrat-website \
  --versioning-configuration Status=Enabled \
  --region eu-west-1 \
  --profile YOUR_PROFILE
```

### 1.3 Block public access

```bash
aws s3api put-public-access-block \
  --bucket obscvrat-website \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --region eu-west-1 \
  --profile YOUR_PROFILE
```

### 1.4 Set bucket policy for CloudFront access

Save this as `bucket-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity/YOUR_OAI_ID"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::obscvrat-website/*"
    }
  ]
}
```

Apply the policy:

```bash
aws s3api put-bucket-policy \
  --bucket obscvrat-website \
  --policy file://bucket-policy.json \
  --region eu-west-1 \
  --profile YOUR_PROFILE
```

## Step 2: Create CloudFront Distribution

### 2.1 Create Origin Access Identity (OAI)

```bash
aws cloudfront create-cloud-front-origin-access-identity \
  --cloud-front-origin-access-identity-config \
    CallerReference=$(date +%s),Comment="Obscvrat OAI" \
  --profile YOUR_PROFILE
```

Note the `Id` from the output - you'll need it in the bucket policy above.

### 2.2 Create CloudFront distribution

Save this as `cloudfront-config.json`:

```json
{
  "CallerReference": "obscvrat-2025",
  "Comment": "Obscvrat noisework website",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3Origin",
        "DomainName": "obscvrat-website.s3.eu-west-1.amazonaws.com",
        "S3OriginConfig": {
          "OriginAccessIdentity": "origin-access-identity/cloudfront/YOUR_OAI_ID"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3Origin",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"]
    },
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": { "Forward": "none" }
    }
  },
  "CacheBehaviors": [
    {
      "PathPattern": "/index.html",
      "TargetOriginId": "S3Origin",
      "ViewerProtocolPolicy": "redirect-to-https",
      "AllowedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      },
      "CachePolicyId": "4135ea3d-c35d-46eb-81d7-reeSJsGjpQe",
      "ForwardedValues": {
        "QueryString": false,
        "Cookies": { "Forward": "none" }
      }
    }
  ],
  "Enabled": true,
  "HttpVersion": "http2and3",
  "PriceClass": "PriceClass_100",
  "WebACLId": ""
}
```

Create the distribution:

```bash
aws cloudfront create-distribution \
  --distribution-config file://cloudfront-config.json \
  --profile YOUR_PROFILE
```

Note the `Id` and `DomainName` from the output.

### 2.3 Configure error page handling

```bash
aws cloudfront create-distribution-config \
  --distribution-config file://cloudfront-config.json \
  --profile YOUR_PROFILE
```

## Step 3: Setup Custom Domain (Route 53)

### 3.1 Create or transfer domain to Route 53

```bash
# List hosted zones
aws route53 list-hosted-zones --profile YOUR_PROFILE

# Create hosted zone (if needed)
aws route53 create-hosted-zone \
  --name obscvrat.fi \
  --caller-reference $(date +%s) \
  --profile YOUR_PROFILE
```

### 3.2 Create DNS records for CloudFront

Get your CloudFront distribution domain name and ID from Step 2.3.

```bash
# Create A record pointing to CloudFront
aws route53 change-resource-record-sets \
  --hosted-zone-id ZONE_ID \
  --change-batch file://dns-changes.json \
  --profile YOUR_PROFILE
```

Save as `dns-changes.json`:

```json
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "obscvrat.fi",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "d1234abcd.cloudfront.net",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
```

### 3.3 Setup SSL/TLS certificate (ACM)

Request a certificate in AWS Certificate Manager:

```bash
aws acm request-certificate \
  --domain-name obscvrat.fi \
  --subject-alternative-names www.obscvrat.fi \
  --region us-east-1 \
  --profile YOUR_PROFILE
```

Verify the certificate in Route 53 and attach to CloudFront distribution.

## Step 4: Deploy the Website

### 4.1 Build the site

```bash
# Development
make build

# Production (minified, optimized)
make build-prod

# For CloudFront staging
make build-staging DISTRIBUTION_ID=d1234abcd.cloudfront.net
```

### 4.2 Sync to S3

```bash
# Sync website/public/ to S3 bucket
aws s3 sync website/public/ s3://obscvrat-website \
  --delete \
  --region eu-west-1 \
  --profile YOUR_PROFILE

# Or copy individual files:
aws s3 cp website/public/index.html s3://obscvrat-website/
```

### 4.3 Invalidate CloudFront cache

```bash
aws cloudfront create-invalidation \
  --distribution-id DISTRIBUTION_ID \
  --paths "/*" \
  --profile YOUR_PROFILE
```

## Step 5: Verify Deployment

1. **Check S3 bucket:**
   ```bash
   aws s3 ls s3://obscvrat-website/ --recursive --profile YOUR_PROFILE
   ```

2. **Test CloudFront distribution:**
   ```bash
   # Using CloudFront domain
   curl -I https://d1234abcd.cloudfront.net/
   
   # Using custom domain
   curl -I https://obscvrat.fi/
   ```

3. **Verify SSL certificate:**
   ```bash
   openssl s_client -connect obscvrat.fi:443
   ```

4. **Check caching headers:**
   ```bash
   curl -I https://obscvrat.fi/ | grep -i cache
   ```

## Deployment Checklist

Before deploying:
- [ ] Site builds successfully: `make build-prod`
- [ ] All content is published (`draft: false`)
- [ ] Links are correct for production domain
- [ ] Images and assets load correctly locally
- [ ] SEO metadata is set (title, description, og tags)
- [ ] Analytics/tracking codes updated if applicable

After deploying:
- [ ] Website loads at https://obscvrat.fi
- [ ] All pages accessible and rendering correctly
- [ ] Links work (internal and external)
- [ ] Images and assets load
- [ ] Mobile responsive design working
- [ ] SSL certificate valid
- [ ] Redirect from www.obscvrat.fi works (if configured)

## Automated Deployment Script

Save as `deploy.sh`:

```bash
#!/bin/bash

set -e

BUCKET="obscvrat-website"
DISTRIBUTION_ID="d1234abcd"
PROFILE="YOUR_PROFILE"
REGION="eu-west-1"

echo "Building site for production..."
make build-prod

echo "Syncing to S3..."
aws s3 sync website/public/ s3://$BUCKET \
  --delete \
  --region $REGION \
  --profile $PROFILE

echo "Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*" \
  --profile $PROFILE

echo "✓ Deployment complete!"
echo "Website: https://obscvrat.fi"
```

Make executable and run:

```bash
chmod +x deploy.sh
./deploy.sh
```

## Monitoring & Maintenance

### CloudFront Metrics

```bash
# Get distribution statistics
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=DISTRIBUTION_ID \
  --start-time 2025-01-01T00:00:00Z \
  --end-time 2025-01-02T00:00:00Z \
  --period 86400 \
  --statistics Sum \
  --profile YOUR_PROFILE
```

### S3 Bucket Size

```bash
aws s3 ls s3://obscvrat-website --summarize --human-readable --recursive \
  --profile YOUR_PROFILE
```

## Rollback Procedure

If something goes wrong:

1. **Identify the issue** in the deployed version
2. **Fix locally** and rebuild: `make build-prod`
3. **Re-sync to S3**:
   ```bash
   aws s3 sync website/public/ s3://obscvrat-website --delete
   ```
4. **Invalidate cache**:
   ```bash
   aws cloudfront create-invalidation \
     --distribution-id DISTRIBUTION_ID \
     --paths "/*"
   ```

Or restore from S3 versioning:

```bash
# List versions
aws s3api list-object-versions --bucket obscvrat-website

# Restore previous version
aws s3api copy-object \
  --copy-source obscvrat-website/index.html?versionId=VERSION_ID \
  --bucket obscvrat-website \
  --key index.html
```

## Troubleshooting

### 403 Forbidden Errors

- Check S3 bucket policy is set correctly
- Verify CloudFront OAI has S3 access
- Check bucket is not blocking all public access

### Site not updating after deploy

- Clear browser cache (Ctrl+Shift+Del or Cmd+Shift+Del)
- Check CloudFront invalidation completed
- Wait for CloudFront cache to expire (usually 24 hours max)
- Manually create invalidation if needed

### SSL Certificate Issues

- Verify certificate is in us-east-1 region
- Check domain is verified in ACM
- Ensure certificate is attached to CloudFront distribution

### Slow Performance

- Check CloudFront cache hit rate in CloudWatch
- Verify cache behavior policies are correct
- Review cache headers in responses
- Consider enabling Gzip compression

## Cost Optimization

- Use CloudFront cache aggressively
- Delete old S3 versions regularly
- Monitor data transfer costs
- Use PriceClass_100 for EU-only distribution (current setting)

## Additional Resources

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Route 53 Documentation](https://docs.aws.amazon.com/route53/)
- [ACM Documentation](https://docs.aws.amazon.com/acm/)

## Support & Questions

For deployment issues:
1. Check AWS CloudWatch logs
2. Review IAM permissions
3. Consult AWS documentation
4. Contact AWS support if needed

---

**Last Updated:** December 2025
**CloudFront Region:** Global
**S3 Region:** eu-west-1
**Domain:** obscvrat.fi
