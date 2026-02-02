# GitHub Actions Deployment Guide

This guide walks you through setting up automated deployment to AWS using GitHub Actions with OIDC authentication.

## Overview

The deployment workflow uses GitHub Actions to:
1. Build the Hugo static site
2. Sync files to S3 bucket
3. Invalidate CloudFront cache

**Security:** Uses OIDC (OpenID Connect) to assume an IAM role instead of storing AWS credentials as secrets.

## Prerequisites

Before setting up GitHub Actions deployment, you need:

- **AWS Infrastructure:** S3 bucket and CloudFront distribution already created (see `infrastructure/README.md`)
- **GitHub CLI:** `gh` command installed and authenticated
- **jq:** JSON processor installed
- **Local configuration:** `infrastructure/aws/variables.json` file with your AWS settings

### Install Prerequisites

```bash
# macOS
brew install gh jq

# Linux (Ubuntu/Debian)
sudo apt-get install gh jq

# Authenticate with GitHub
gh auth login
```

## Setup Steps

### Step 1: Generate IAM Policy

Generate the deployment policy with your CloudFront distribution ID:

```bash
make deploy generate-deployment-policy
```

This outputs a JSON policy. Copy the entire JSON (everything between `{` and `}`).

### Step 2: Create IAM Policy in AWS Console

1. Go to **AWS Console** → **IAM** → **Policies**
2. Click **Create policy**
3. Click **JSON** tab
4. Paste the JSON from Step 1
5. Click **Next**
6. Policy name: `GitHubActionsDeploymentPolicy`
7. Description: "Allows GitHub Actions to deploy Obscvrat website"
8. Click **Create policy**

### Step 3: Create OIDC Identity Provider (One-time)

If you haven't already set up GitHub as an OIDC provider:

1. Go to **AWS Console** → **IAM** → **Identity providers**
2. Click **Add provider**
3. Select **OpenID Connect**
4. Provider URL: `https://token.actions.githubusercontent.com`
5. Audience: `sts.amazonaws.com`
6. Click **Add provider**

### Step 4: Create IAM Role

1. Go to **AWS Console** → **IAM** → **Roles**
2. Click **Create role**
3. Select **Web identity**
4. Identity provider: Select `token.actions.githubusercontent.com` from dropdown
5. Audience: `sts.amazonaws.com`
6. Click **Next**
7. Search for and select `GitHubActionsDeploymentPolicy`
8. Click **Next**
9. Role name: `GitHubActionsDeploymentRole`
10. Description: "Allows GitHub Actions to deploy Obscvrat website"
11. Click **Create role**

### Step 5: Configure Trust Policy

1. Find the newly created role and click on it
2. Go to **Trust relationships** tab
3. Click **Edit trust policy**
4. Replace the policy with:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:tovrleaf/obscvratfi:*"
        }
      }
    }
  ]
}
```

5. Replace `YOUR_AWS_ACCOUNT_ID` with your AWS account ID
6. Click **Update policy**

### Step 6: Copy Role ARN

1. On the role summary page, copy the **ARN**
2. It looks like: `arn:aws:iam::123456789012:role/GitHubActionsDeploymentRole`
3. Save this - you'll need it in the next step

### Step 7: Configure GitHub Secrets

Run the setup script:

```bash
make deploy setup-github-secrets
```

The script will:
1. Read AWS region, S3 bucket, and CloudFront distribution ID from `infrastructure/aws/variables.json`
2. Prompt you for the IAM role ARN (paste what you copied in Step 6)
3. Set 4 GitHub secrets:
   - `AWS_ROLE_ARN`
   - `AWS_REGION`
   - `S3_BUCKET_NAME`
   - `CLOUDFRONT_DISTRIBUTION_ID`

### Step 8: Verify Secrets

Check that secrets were created:

```bash
gh secret list
```

You should see all 4 secrets listed.

## How It Works

### Workflow Trigger

The deployment workflow runs:
- **Manually:** Via GitHub Actions UI (workflow_dispatch)
- **Automatically:** On push to `main` branch (after PR merge)

### Deployment Process

1. **Checkout code:** Gets latest code from repository
2. **Assume IAM role:** Uses OIDC to get temporary AWS credentials
3. **Setup Hugo:** Installs Hugo static site generator
4. **Build site:** Runs `hugo --minify` to generate production build
5. **Sync to S3:** Uploads files to S3 bucket with `--delete` flag
6. **Invalidate cache:** Creates CloudFront invalidation for `/*`

### Security

- **No long-lived credentials:** AWS credentials are temporary (1 hour)
- **Automatic rotation:** New credentials generated for each workflow run
- **Minimal permissions:** Role can only sync S3 and invalidate CloudFront
- **Repository-specific:** Role can only be assumed by `tovrleaf/obscvratfi` repository

## Manual Deployment

To deploy manually via GitHub Actions:

1. Go to repository on GitHub
2. Click **Actions** tab
3. Select **Deploy to AWS** workflow
4. Click **Run workflow**
5. Select branch (usually `main`)
6. Click **Run workflow**

## Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Cause:** Trust policy is incorrect or OIDC provider not set up

**Solution:**
- Verify OIDC provider exists: AWS Console → IAM → Identity providers
- Check trust policy has correct AWS account ID
- Verify repository name in trust policy: `repo:tovrleaf/obscvratfi:*`

### Error: "Access Denied" during S3 sync

**Cause:** IAM policy doesn't have S3 permissions

**Solution:**
- Verify `GitHubActionsDeploymentPolicy` is attached to role
- Check policy has `s3:PutObject`, `s3:DeleteObject`, `s3:ListBucket` permissions
- Verify bucket name matches in policy and secrets

### Error: "Access Denied" during CloudFront invalidation

**Cause:** IAM policy doesn't have CloudFront permissions

**Solution:**
- Verify policy has `cloudfront:CreateInvalidation` permission
- Check CloudFront distribution ID matches in policy and secrets
- Ensure distribution ID is correct in `variables.json`

### Workflow fails but no error message

**Cause:** GitHub secrets not set correctly

**Solution:**
```bash
# List secrets
gh secret list

# Re-run setup script
make deploy setup-github-secrets
```

### Changes not visible on website

**Cause:** CloudFront cache not invalidated or still propagating

**Solution:**
- Wait 5-10 minutes for invalidation to complete
- Check CloudFront invalidations in AWS Console
- Try hard refresh in browser (Cmd+Shift+R or Ctrl+Shift+R)

## Monitoring

### View Deployment Status

1. Go to repository on GitHub
2. Click **Actions** tab
3. Click on latest workflow run
4. View logs for each step

### Check S3 Sync

```bash
aws s3 ls s3://obscvratfi --profile obscvratfi
```

### Check CloudFront Invalidations

```bash
aws cloudfront list-invalidations \
  --distribution-id E3JDJIKZ9L5C95 \
  --profile obscvratfi
```

## Cost Considerations

- **S3 storage:** ~$0.023 per GB per month
- **CloudFront data transfer:** First 1 TB free per month
- **CloudFront invalidations:** First 1,000 paths free per month
- **GitHub Actions:** 2,000 minutes free per month for public repos

Typical deployment costs: **< $1/month**

## Additional Resources

- [GitHub Actions OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM OIDC Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [Hugo Documentation](https://gohugo.io/documentation/)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)

## Related Documentation

- [infrastructure/README.md](../infrastructure/README.md) - AWS infrastructure setup
- [infrastructure/aws/GITHUB-ACTIONS-ROLE.md](../infrastructure/aws/GITHUB-ACTIONS-ROLE.md) - Detailed IAM role setup
- [DEPLOYMENT.md](DEPLOYMENT.md) - Manual deployment guide
- [ADR-003](adr/003-website-hosting-static-site-generation-seo-strategy.md) - Hosting decisions
