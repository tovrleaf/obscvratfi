# CI/CD Pipeline Documentation

Complete guide to the Obscvrat website CI/CD pipeline using GitHub Actions.

## Overview

The CI/CD pipeline automatically validates code quality, builds the site, and performs security checks on every push and pull request. **The pipeline validates but does not deploy** - deployment is manual and handled separately.

### Pipeline Stages

1. **Lint** - Code quality checks
2. **Build & Validate** - Site compilation and validation
3. **Security** - Secret scanning
4. **Results** - Summary posting
5. **Notifications** - Email alerts

---

## Workflow: `pr-checks.yml`

Runs on every push to any branch and on pull requests to main.

### Job 1: Lint Code

Checks code formatting and style using:
- **shellcheck** - Bash script linting
- **yamllint** - YAML file validation
- **markdownlint** - Markdown documentation linting

**What it checks:**
- `scripts/*.sh` - All shell scripts
- `.github/workflows/*.yml` - GitHub Actions workflows
- `website/hugo.toml` - Hugo configuration
- `README.md`, `website/README.md`, `docs/**/*.md` - Documentation

**Failure mode:** Warnings only (informational), errors block the job

**Time:** ~30 seconds

---

### Job 2: Build & Validate

Builds the Hugo site and validates output.

#### Build Steps

1. **Docker setup** - Prepares Docker build environment
2. **Docker cache** - Uses GitHub Actions cache for faster builds
3. **Hugo build** - Runs Hugo in Docker to generate `website/public/`
   - Dev mode (unminified, for testing)
   - Cached Docker layers for speed
4. **HTML validation** - Validates generated HTML structure
5. **Link checking** - Verifies critical internal links exist

#### Critical Links Checked

- `/` - Homepage
- `/about/` - About page
- `/gigs/` - Gigs listing
- `/music/` - Music listing
- `/feed.xml` - RSS feed
- `/sitemap.xml` - XML sitemap

**Failure mode:** Build or link check failures block merge

**Time:** 30-60 seconds (varies based on Docker cache)

---

### Job 3: Security Scan

Scans code for accidentally committed secrets and sensitive patterns.

**Tools used:**
- **TruffleHog** - Detects AWS keys, API tokens, etc.
- **Regex patterns** - Checks for common AWS key format

**What it prevents:**
- AWS access keys
- API tokens
- Database passwords
- Private keys

**Failure mode:** Secrets found block merge

**Time:** ~20 seconds

---

### Job 4: Post Results

Creates a summary comment on pull requests showing:
- Overall status (✅ PASSED or ❌ FAILED)
- Individual job results
- Link to detailed GitHub Actions logs

**Example comment:**
```
✅ CI Checks: PASSED

All checks passed - ready to review!

### Results Summary
- Lint: success
- Build & Validate: success
- Security Scan: success

[View full logs](...)
```

---

### Job 5: Send Notifications

Sends email notifications for all status events.

#### Email Scenarios

**1. PR Check Success**
- Subject: `✅ CI checks passed - [branch-name]`
- When: All checks pass on a pull request
- Includes: Commit, branch, author, logs link

**2. PR Check Failure**
- Subject: `❌ CI checks failed - [branch-name]`
- When: Any check fails on a pull request
- Includes: Which checks failed, logs link for debugging

**3. Merge Success (Main Branch)**
- Subject: `✅ Code merged to main - Ready for deployment`
- When: Code merged to main and all checks pass
- Includes: Merge details and deployment command reminder

#### Email Configuration

Emails require GitHub Secrets (set up separately):
- `EMAIL_USERNAME` - Gmail address
- `EMAIL_PASSWORD` - Gmail app password (not regular password)
- `NOTIFY_EMAIL` - Your email to receive notifications

---

## How to Interpret Results

### ✅ All Green (PASSED)

**On PR:**
- All linting passed
- Hugo build successful
- HTML valid
- Links verified
- No secrets detected
- Safe to review and merge

**On Main:**
- Code merged successfully
- Ready for manual deployment
- Check email for deployment reminder

### ❌ Any Red (FAILED)

**Common failures:**

1. **Lint errors**
   ```
   shellcheck: error in script.sh
   ```
   Fix: Review the script and correct syntax

2. **Build errors**
   ```
   Hugo build failed: invalid TOML
   ```
   Fix: Check `website/hugo.toml` syntax

3. **Link errors**
   ```
   ❌ about/index.html NOT FOUND
   ```
   Fix: Verify content file exists and frontmatter is valid

4. **Secret detected**
   ```
   ❌ Potential secrets found!
   ```
   Fix: Remove AWS keys, API tokens, etc. Never commit credentials.

---

## Debugging Failed Checks

### View Logs

1. Go to GitHub repository
2. Click "Actions" tab
3. Click the failed workflow run
4. Click the failed job
5. Expand steps to see error details

### Common Issues & Fixes

**Issue: `shellcheck: command not found`**
- Fix: Install shellcheck locally: `brew install shellcheck`
- Run: `shellcheck scripts/*.sh`

**Issue: `yamllint: command not found`**
- Fix: Install yamllint: `pip install yamllint`
- Run: `yamllint .github/workflows/*.yml`

**Issue: `markdownlint: command not found`**
- Fix: Install markdownlint: `npm install -g markdownlint-cli`
- Run: `markdownlint README.md docs/**/*.md`

**Issue: `Hugo build failed`**
- Fix: Build locally: `make build`
- Review error messages
- Check `website/hugo.toml` and markdown frontmatter

**Issue: `Link check failed`**
- Fix: Verify file exists
- Check filename matches URL slug
- Verify `draft: false` in frontmatter

**Issue: `Secret detected`**
- Fix: Remove sensitive data from commit
- Use GitHub Secrets for credentials instead
- Never commit AWS keys, API tokens, passwords

---

## Development Workflow

### Step 1: Create Feature Branch
```bash
git checkout -b feature/my-feature
```

### Step 2: Make Changes
```bash
# Edit files, add content, etc.
```

### Step 3: Push to GitHub
```bash
git push origin feature/my-feature
```

### Step 4: GitHub Actions Runs
- Automatically runs pr-checks.yml
- Posts results as PR comment
- Sends email notification (if configured)

### Step 5: Fix Any Failures (if needed)
```bash
# Make fixes locally
git add .
git commit -m "Fix CI check failures"
git push origin feature/my-feature
```

### Step 6: Create Pull Request
- Open PR on GitHub
- CI checks display in PR
- You review and approve

### Step 7: Merge
```bash
# Via GitHub UI or:
git checkout main
git pull
git merge feature/my-feature
git push origin main
```

### Step 8: Manual Deployment
After merge, deploy manually when ready:
```bash
./scripts/deploy.sh production
```

---

## Email Notifications

### Setup (One-time)

1. Generate Gmail app password (not your regular password)
2. Add to GitHub Secrets:
   - `EMAIL_USERNAME` - Your Gmail address
   - `EMAIL_PASSWORD` - App password from step 1
   - `NOTIFY_EMAIL` - Where to receive notifications

See separate ADR for detailed GitHub Secrets setup.

### Receiving Emails

You'll get emails for:
- ✅ PR checks pass on your branches
- ❌ PR checks fail on your branches
- ✅ Successful merge to main
- ❌ Failed checks on main (rare, would indicate branch protection issue)

---

## Performance

### Build Times

- **First build:** 2-3 minutes (downloads Docker image)
- **Subsequent builds:** 30-60 seconds (uses cached Docker layers)
- **Lint only:** 1-2 minutes
- **Total pipeline:** 5-10 minutes

### Optimization

Docker layer caching significantly speeds up builds. Cache persists across workflow runs unless:
- Dockerfile changes
- Dependencies change
- Cache is manually cleared

---

## Troubleshooting

### No email notifications received

**Check:**
1. Secrets configured: `EMAIL_USERNAME`, `EMAIL_PASSWORD`, `NOTIFY_EMAIL`
2. Gmail app password (not regular password)
3. "Less secure apps" setting if using regular Gmail password
4. Check spam/junk folder

### Workflow not running

**Check:**
1. Workflow file syntax (YAML errors)
2. Branch is included in `on` trigger conditions
3. Repository has Actions enabled

### Docker cache not working

**Check:**
1. GitHub Actions cache is enabled (default)
2. Dockerfile hasn't changed
3. No manual cache clear performed

### Lint warnings blocking merge

**Note:** Lint warnings (non-errors) don't block merge. Only errors block.

---

## Next Steps

### Deployment ADR (Separate)

Future ADR will document:
- GitHub Secrets configuration for AWS credentials
- Manual deployment process
- S3 sync commands
- CloudFront invalidation
- Rollback procedures

### Related Documentation

- `README.md` - Project overview
- `docs/DEPLOYMENT.md` - Manual deployment guide
- `Makefile` - Build commands
- `scripts/build.sh` - Build script
- `scripts/deploy.sh` - Deployment script

---

## Support & Questions

If CI checks fail:
1. Check the error message in GitHub Actions logs
2. Review this documentation
3. Run checks locally to reproduce
4. Fix the issue and push again

For setup questions, see the separate GitHub Secrets setup ADR (coming soon).

---

**Last Updated:** December 2025
**Pipeline Version:** 1.0
**Status:** Ready for use
