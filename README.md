# Obscvrat Website Documentation

Official noisework website for Obscvrat - a static site built with Hugo and deployed to AWS CloudFront.

## Quick Start

### Prerequisites

- Hugo Extended v0.128.2 or later ([installation instructions](https://gohugo.io/installation/))

### Development

```bash
# Start local development server (http://localhost:1313)
make serve

# Build the site locally
make build

# View all available commands
make help
```

### Production

```bash
# Build for production (minified, optimized)
make build-prod
```

## Local Development Setup

### Prerequisites

- Python 3.9+ (for local development tools)
- Hugo Extended v0.128.2 or later ([installation instructions](https://gohugo.io/installation/))

### Setup Development Tools

To catch validation issues **before** committing, set up local development tools:

```bash
# One-time setup (creates .venv and installs all tools)
make hooks setup
```

This creates a local Python virtual environment (`.venv/`) and installs:
- **pre-commit** - Git hook framework
- **shellcheck-py** - Shell script linting
- **yamllint** - YAML file linting
- **pymarkdownlnt** - Markdown file linting

All tools are installed locally in `.venv/` - no global installation needed.

### What Local Hooks Check

Hooks automatically validate before commit and push:

**Pre-commit (before commit):**
- ✅ Shell scripts (`.sh`) - shellcheck
- ✅ YAML files (`.yml`, `.yaml`) - yamllint
- ✅ Markdown files (`.md`) - pymarkdown

**Pre-push (before push):**
- ✅ Hugo site builds correctly
- ✅ Generated HTML is valid
- ✅ Critical internal links exist
- ✅ No secrets accidentally committed

**Feedback in seconds** instead of waiting 5-15 minutes for GitHub Actions!

### Manual Testing

Run linters manually anytime:

```bash
# Test all files
make test sh       # All shell scripts
make test yaml     # All YAML files
make test md       # All Markdown files

# Test files in last commit
make test sh-commit
make test yaml-commit
make test md-commit

# Run all pre-push checks
make hooks run
```

### Uninstall Hooks

```bash
make hooks uninstall
```

See `docs/adr/004-development-testing-and-validation-requirements.md` for detailed information about local validation.

## CI/CD Pipeline

The repository includes an automated CI/CD pipeline that **validates code quality but does not deploy**.

### Automated Checks

When you push code or create a pull request, GitHub Actions automatically runs:

- **Linting** - Code style and formatting checks
  - Shell scripts (`shellcheck`)
  - YAML files (`yamllint`)
  - Markdown files (`markdownlint`)

- **Build & Validation** - Site compilation and correctness
  - Hugo site build
  - HTML validation (errors only)
  - Critical internal link verification

- **Security** - Secret scanning
  - Detects accidentally committed AWS keys
  - Prevents API tokens in code

### Email Notifications

Receive email alerts for:
- ✅ All CI checks passed (PR ready to review)
- ❌ CI checks failed (see logs for details)
- ✅ Code merged to main (ready for manual deployment)

### Workflow

```
Your PR
  ↓
GitHub Actions validates
  ↓
✅ PASS or ❌ FAIL (emailed)
  ↓
You review & approve PR
  ↓
Merge to main
  ↓
✅ Merge notification (email)
  ↓
Manual deployment (separate ADR)
```

### Deployment

**Important:** The CI/CD pipeline validates code but does **not automatically deploy** to production.

After merging to main and CI checks pass, deploy manually:

```bash
make deploy-production
```

See `docs/DEPLOYMENT.md` for detailed deployment instructions.

For complete CI/CD documentation, see `docs/CI-CD.md`.

## Project Structure

```
website/
├── archetypes/          # Content templates for new posts
│   ├── gigs.md         # Template for new gig listings
│   └── music.md       # Template for new music pages
├── content/            # All site content in Markdown
│   ├── about/          # About page
│   ├── live/           # Gig listings and details
│   └── music/         # Music releases and details
├── layouts/            # Hugo templates
│   ├── baseof.html     # Base template with styling
│   ├── index.html      # Homepage
│   ├── about/          # About page templates
│   ├── music/         # Music page templates
│   ├── live/           # Gig page templates
│   ├── _default/       # Default templates
│   ├── partials/       # Reusable template components
│   └── shortcodes/     # Custom Markdown shortcodes
├── static/             # Static files (robots.txt, etc.)
├── hugo.toml           # Hugo configuration
└── .gitignore          # Git ignore rules
```

## Content Management

### Adding a New Live Performance

1. **Using the archetype (recommended):**
   ```bash
   hugo new live/YYYY-MM-DD-venue-name.md
   ```

2. **Manual creation:**
   Create a file in `website/content/live/` with the following structure:

   ```markdown
   ---
   title: "Venue Name"
   date: 2025-03-15
   venue: "Venue Name"
   location: "City"
   other_performers: ["Artist Name 1", "Artist Name 2"]
   youtube: "https://www.youtube.com/watch?v=VIDEO_ID"
   ticket_link: "https://ticketing-service.com/event"
   draft: false
   ---

   Event description and details here.
   ```

3. **Fields:**
   - `title`: Event title (required)
   - `date`: Event date in YYYY-MM-DD format (required)
   - `venue`: Venue name (required, displayed on gigs listing)
   - `location`: City/region name (required, displayed on gigs listing)
   - `other_performers`: Optional list of other artists performing
   - `youtube`: Optional YouTube link for performance recordings
   - `ticket_link`: Optional link to ticket purchasing
   - `draft`: Set to `false` to publish, `true` to keep as draft

### Adding a New Music Release

1. **Using the archetype:**
   ```bash
   hugo new music/music-slug-name.md
   ```

2. **Manual creation:**
   Create a file in `website/content/music/` with:

   ```markdown
   ---
   title: "Music Title"
   date: 2024-06-15
   bandcamp_album: "1111111"
   description: "Music description"
   ---

   Detailed music information, track listing, and production notes.
   ```

3. **Fields:**
   - `title`: Album title (required)
   - `date`: Release date (required)
   - `bandcamp_album`: Bandcamp album ID for embed (required for Bandcamp integration)
   - `description`: Short description (displayed in album listing)
   - `draft`: Set to `false` to publish (optional)

4. **Getting Bandcamp Album ID:**
   - Visit your Bandcamp album page
   - Look at the URL: `https://username.bandcamp.com/album/album-slug`
   - Or find the album ID in the embed code

### Updating the About Page

Edit `website/content/about/_index.md` to update the About page content. The page supports:
- Headings (h1-h3)
- Paragraphs
- Lists (ordered and unordered)
- Links
- Bold and italic text

## Development Guide

### Local Development Environment

**Prerequisites:**
- Docker (or Docker Desktop for macOS/Windows)
- Make

**Starting the dev server:**
```bash
make serve
```

This starts Hugo in Docker and watches for file changes. The site auto-reloads at `http://localhost:1313`.

### Building the Site

**Development build:**
```bash
make build
```
Output: `website/public/`

**Production build (minified, optimized):**
```bash
make build-prod
```

**Test minification locally:**
```bash
make build-minified
```

### File Organization

- All content goes in `website/content/`
- All templates in `website/layouts/`
- Static files (that don't change) in `website/static/`
- Configuration in `website/hugo.toml`

### Making Template Changes

Templates use Go's `html/template` syntax. Key files:
- `baseof.html` - Main page wrapper
- `index.html` - Homepage layout
- `_default/single.html` - Single page layout
- `_default/list.html` - List page layout
- `partials/` - Reusable components

### Adding Shortcodes

Shortcodes are custom Markdown syntax. Example: `{{< bandcamp album="123456" >}}`

To create a new shortcode:
1. Create `website/layouts/shortcodes/name.html`
2. Use in Markdown: `{{< name param="value" >}}`

Current shortcodes:
- `{{< bandcamp album="ID" size="large" >}}` - Embed Bandcamp player

## SEO & Metadata

### Automatic SEO Features

- **Sitemap**: Auto-generated at `/sitemap.xml`
- **Robots.txt**: Located at `/robots.txt`
- **RSS Feed**: Available at `/feed.xml`
- **Schema.org Markup**:
  - MusicGroup schema on homepage
  - Event schema on gig pages
- **Open Graph Tags**: Social media sharing metadata

### Customizing Metadata

Update `website/hugo.toml`:
```toml
title = "Obscvrat"
description = "Official noisework website for Obscvrat"
baseURL = "https://obscvrat.fi"

[params]
youtube = "https://www.youtube.com/..."
instagram = "https://www.instagram.com/..."
bandcamp = "https://obscvrat.bandcamp.com"
```

## Deployment

### GitHub Actions Deployment (Recommended)

Automated deployment via GitHub Actions with OIDC authentication.

**One-time setup:**

1. **Generate IAM policy:**
   ```bash
   make deploy generate-deployment-policy
   ```

2. **Create IAM resources in AWS Console:**
   - Create IAM policy (use generated JSON)
   - Create OIDC identity provider
   - Create IAM role with web identity

3. **Configure GitHub secrets:**
   ```bash
   make deploy setup-github-secrets
   ```

**Deploy:**
- Automatically on push to `main` branch
- Manually via GitHub Actions UI

See [docs/GITHUB-ACTIONS.md](docs/GITHUB-ACTIONS.md) for detailed setup guide.

### Manual Deployment (Alternative)

For manual deployment to S3 + CloudFront:

```bash
make deploy production
```

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for manual deployment instructions.

### Build for Production

```bash
make build-prod
```

Output: `website/public/`

## Git Workflow

### Commit Message Format

Follow the format from `CONTRIBUTING.md`:
```
Type: Brief description (under 72 chars)

Longer explanation if needed, wrapped at 72 chars.
Explain the "why" not just the "what".

Fixes #123
```

### Branch Naming

- Feature: `feature/user-friendly-description`
- Bug fix: `fix/bug-description`
- Documentation: `docs/what-changed`

## Troubleshooting

### Build fails with "unexpected EOF"

Check for unclosed template tags in `layouts/` files.

### Content not showing up

1. Make sure `draft: false` in frontmatter
2. Check the date isn't in the future
3. Verify file is in correct `content/` subdirectory
4. Run `make clean` then `make build`

### Homepage shows empty sections

Verify content files have proper frontmatter and `draft: false`.

### Images or static files not loading

Place them in `website/static/` directory. They'll be served at the root path.

## Useful Commands

```bash
# List all content
make list-content

# Clean build artifacts
make clean

# Complete cleanup
make distclean

# View all Make targets
make help

# List ADRs
make adr-list

# Create new ADR
make adr-new TITLE="Decision Title"
```

## Additional Resources

- [Hugo Documentation](https://gohugo.io/documentation/)
- [Architecture Decision Records](docs/adr/README.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Deployment Guide](docs/DEPLOYMENT.md) (coming soon)
- [Agent Guidelines](AGENTS.md)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review existing ADRs in `docs/adr/`
3. Consult Hugo documentation
4. Report issues at https://github.com/sst/opencode

---

**Last Updated:** December 2025
**Hugo Version:** 0.128.2
**Site URL:** https://obscvrat.fi

# Test: No approval required
