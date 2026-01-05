# Deployment Guide

Complete guide for deploying the Obscvrat website to AWS S3 and CloudFront.

> **Initial Setup:** For setting up AWS infrastructure for the first time, see [`infrastructure/README.md`](../infrastructure/README.md). This guide covers infrastructure creation with detailed helper functions and step-by-step instructions.

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

---

## Step 1: Initial AWS Infrastructure Setup

See [`infrastructure/README.md`](../infrastructure/README.md) for complete step-by-step instructions on:
- Creating S3 bucket with proper security
- Setting up CloudFront distribution
- Configuring Route 53 DNS
- Requesting SSL certificates
- Verifying everything works

This is a one-time setup that takes 30-45 minutes.

---

## Step 2: Build the Website

### Build for Development

```bash
# Development (unminified, for testing)
make build
```

### Build for Production

```bash
# Production (minified, optimized)
make build-prod
```

### Build with Specific CloudFront Distribution

```bash
# If deploying to staging before production
make build-staging DISTRIBUTION_ID=d1234abcd.cloudfront.net
```

---

## Step 3: Deploy to S3

### Sync website files to S3 bucket

```bash
# Sync entire website
aws s3 sync website/public/ s3://obscvrat-website \
  --delete \
  --region eu-west-1 \
  --profile YOUR_PROFILE

# Or sync only specific files
aws s3 cp website/public/index.html s3://obscvrat-website/
```

### Verify files uploaded

```bash
# List S3 bucket contents
aws s3 ls s3://obscvrat-website/ --recursive \
  --profile YOUR_PROFILE

# Check file count
aws s3 ls s3://obscvrat-website/ --recursive --profile YOUR_PROFILE | wc -l
```

---

## Step 4: Invalidate CloudFront Cache

After uploading new files, invalidate CloudFront cache so users get fresh content.

```bash
# Replace DISTRIBUTION_ID with your actual ID
DISTRIBUTION_ID=d1234abcd
PROFILE=YOUR_PROFILE

aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*" \
  --profile $PROFILE

echo "✅ Cache invalidation started"
```

### Monitor invalidation progress

```bash
aws cloudfront list-invalidations \
  --distribution-id $DISTRIBUTION_ID \
  --profile $PROFILE | jq '.InvalidationList.Items[0]'
```

---

## Step 5: Verify Deployment

### Check website is live

```bash
# Test CloudFront domain (use your actual domain)
curl -I https://d1234abcd.cloudfront.net/

# Test custom domain
curl -I https://obscvrat.fi/

# Both should return HTTP 200 or 304 (not 403 or 404)
```

### Verify homepage loads

```bash
# Check homepage
curl https://obscvrat.fi/ | head -50

# Check CSS loads
curl https://obscvrat.fi/css/style.css | head -10
```

### Test critical pages

```bash
# Check all critical pages return 200
for page in / /about/ /gigs/ /albums/ /feed.xml /sitemap.xml; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://obscvrat.fi$page)
  echo "$page: $STATUS"
done
```

---

## Deployment Checklist

Before deploying:

- [ ] Site builds successfully: `make build-prod`
- [ ] All content is published (`draft: false` in frontmatter)
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

---

## Automated Deployment Script

A deployment helper script is included for convenience:

```bash
./scripts/deploy.sh production
```

This script:
1. Builds the site for production
2. Syncs to S3
3. Invalidates CloudFront cache
4. Shows deployment status

---

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

### Cache Hit Ratio

High cache hit ratio (>95%) is good - means CloudFront is caching effectively.

```bash
# Check in CloudFront console or via:
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name CacheHitRate \
  --dimensions Name=DistributionId,Value=DISTRIBUTION_ID \
  --start-time 2025-01-01T00:00:00Z \
  --end-time 2025-01-02T00:00:00Z \
  --period 86400 \
  --statistics Average \
  --profile YOUR_PROFILE
```

---

## Rollback Procedure

If something goes wrong after deployment:

### Option 1: Quick Revert and Redeploy

```bash
# Fix the issue locally
# Rebuild
make build-prod

# Redeploy
aws s3 sync website/public/ s3://obscvrat-website --delete

# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id DISTRIBUTION_ID \
  --paths "/*"
```

### Option 2: Restore from S3 Versioning

If S3 versioning is enabled, restore previous version:

```bash
# List previous versions
aws s3api list-object-versions \
  --bucket obscvrat-website \
  --profile YOUR_PROFILE | jq '.Versions'

# Restore specific version
aws s3api copy-object \
  --copy-source obscvrat-website/index.html?versionId=VERSION_ID \
  --bucket obscvrat-website \
  --key index.html \
  --profile YOUR_PROFILE

# Then invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id DISTRIBUTION_ID \
  --paths "/*"
```

---

## Troubleshooting

### 403 Forbidden Errors

- Check S3 bucket policy is set correctly (see `infrastructure/README.md`)
- Verify CloudFront OAI has S3 access
- Check bucket is not blocking all public access
- Wait 5 minutes for policy to propagate

### Site not updating after deploy

- Clear browser cache (Ctrl+Shift+Del or Cmd+Shift+Del)
- Check CloudFront invalidation completed
- Wait for CloudFront cache to expire (usually 24 hours max)
- Manually create invalidation if needed:
  ```bash
  aws cloudfront create-invalidation --distribution-id DISTRIBUTION_ID --paths "/*"
  ```

### SSL Certificate Issues

- Verify certificate is in us-east-1 region
- Check domain is verified in ACM
- Ensure certificate is attached to CloudFront distribution
- See `infrastructure/README.md` for detailed certificate setup

### Slow Performance

- Check CloudFront cache hit rate in CloudWatch
- Verify cache behavior policies are correct
- Review cache headers in responses
- Consider enabling Gzip compression

### S3 Upload Fails

```bash
# Verify AWS credentials
aws sts get-caller-identity --profile YOUR_PROFILE

# Verify bucket access
aws s3 ls s3://obscvrat-website --profile YOUR_PROFILE

# Try uploading single file
aws s3 cp test.txt s3://obscvrat-website/ --profile YOUR_PROFILE
```

---

## Cost Optimization

- Use CloudFront cache aggressively (current cache policy is good)
- Delete old S3 versions regularly if storage costs are high
- Monitor data transfer costs (usually largest cost)
- Use PriceClass_100 for EU-only distribution (current setting)
- Consider S3 Intelligent-Tiering for long-term archival

---

## Additional Resources

- **Infrastructure Setup:** See [`infrastructure/README.md`](../infrastructure/README.md)
- **Architecture Decisions:** See [ADR-003: Website Hosting & Infrastructure](docs/adr/003-website-hosting-static-site-generation-seo-strategy.md)
- **AWS Documentation:**
  - [S3 Documentation](https://docs.aws.amazon.com/s3/)
  - [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
  - [Route 53 Documentation](https://docs.aws.amazon.com/route53/)
  - [ACM Documentation](https://docs.aws.amazon.com/acm/)

---

## Support & Questions

For deployment issues:
1. Check AWS CloudWatch logs
2. Review this guide's Troubleshooting section
3. Review [`infrastructure/README.md`](../infrastructure/README.md) for setup issues
4. Consult AWS documentation
5. Contact AWS support if needed

---

**Last Updated:** January 2026  
**CloudFront Region:** Global  
**S3 Region:** eu-west-1  
**Domain:** obscvrat.fi
