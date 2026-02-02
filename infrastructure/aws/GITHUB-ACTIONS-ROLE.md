# GitHub Actions Deployment Role Setup

This directory contains IAM policies for setting up a GitHub Actions deployment role using OIDC (OpenID Connect).

## Overview

Instead of storing AWS credentials as GitHub secrets, we use OIDC to allow GitHub Actions to assume an IAM role. This is more secure because:
- No long-lived credentials stored in GitHub
- Automatic credential rotation
- Can restrict access to specific repository and branches
- Follows AWS security best practices

## Files

- **`iam-policy-github-actions-deployment.json`** - Permissions policy for deployment
  - S3 sync permissions for `obscvratfi` bucket
  - CloudFront invalidation for all distributions (uses wildcard)
  
- **`iam-trust-policy-github-actions.json`** - Trust policy for GitHub OIDC
  - Allows GitHub Actions from `tovrleaf/obscvratfi` repository to assume the role
  - Replace `YOUR_AWS_ACCOUNT_ID` with your AWS account ID

## Setup Instructions

### Step 1: Create OIDC Identity Provider (One-time)

If you haven't already set up GitHub as an OIDC provider:

1. Go to AWS Console → IAM → Identity providers
2. Click **Add provider**
3. Select **OpenID Connect**
4. Provider URL: `https://token.actions.githubusercontent.com`
5. Audience: `sts.amazonaws.com`
6. Click **Add provider**

### Step 2: Create IAM Role

1. Go to AWS Console → IAM → Roles
2. Click **Create role**
3. Select **Web identity**
4. Identity provider: `token.actions.githubusercontent.com`
5. Audience: `sts.amazonaws.com`
6. Click **Next**

### Step 3: Attach Permissions Policy

1. Click **Create policy** (opens new tab)
2. Select **JSON** tab
3. Copy contents of `iam-policy-github-actions-deployment.json`
4. Paste into editor
5. Click **Next**
6. Name: `GitHubActionsDeploymentPolicy`
7. Click **Create policy**
8. Return to role creation tab
9. Refresh policies and select `GitHubActionsDeploymentPolicy`
10. Click **Next**

### Step 4: Configure Trust Policy

1. Role name: `GitHubActionsDeploymentRole`
2. Description: `Allows GitHub Actions to deploy Obscvrat website`
3. Click **Create role**
4. Find the newly created role and click on it
5. Go to **Trust relationships** tab
6. Click **Edit trust policy**
7. Copy contents of `iam-trust-policy-github-actions.json`
8. Replace `YOUR_AWS_ACCOUNT_ID` with your AWS account ID
9. Paste into editor
10. Click **Update policy**

### Step 5: Copy Role ARN

1. On the role summary page, copy the **ARN**
2. It will look like: `arn:aws:iam::123456789012:role/GitHubActionsDeploymentRole`
3. Save this ARN - you'll need it for GitHub secrets

### Step 6: Add Role ARN to GitHub Secrets

```bash
gh secret set AWS_ROLE_ARN -b "arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsDeploymentRole"
```

Or via GitHub UI:
1. Go to repository → Settings → Secrets and variables → Actions
2. Click **New repository secret**
3. Name: `AWS_ROLE_ARN`
4. Value: (paste the role ARN)
5. Click **Add secret**

## Verification

Test that the role works:

```bash
# This will be done automatically by GitHub Actions
# But you can test locally if you have the role ARN

aws sts assume-role-with-web-identity \
  --role-arn "arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsDeploymentRole" \
  --role-session-name "test-session" \
  --web-identity-token "YOUR_GITHUB_TOKEN"
```

## Security Notes

- The trust policy restricts access to the `tovrleaf/obscvratfi` repository only
- The permissions policy grants minimal access (S3 sync + CloudFront invalidation only)
- No access to other AWS resources
- No ability to modify IAM, EC2, or other services
- Credentials are temporary and automatically rotated

## Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

- Check that OIDC provider is created correctly
- Verify trust policy has correct repository name
- Ensure AWS account ID is correct in trust policy

### Error: "Access Denied" during deployment

- Check that permissions policy is attached to role
- Verify S3 bucket name and CloudFront distribution ID are correct
- Ensure role has both S3 and CloudFront permissions

## References

- [GitHub Actions OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM OIDC Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
