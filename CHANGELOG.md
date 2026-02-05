# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-02-05

### Added
- Python script conversion: bump_version.py, create_release.py, manage_media.py, manage_live.py (ADR-014)
- Comprehensive test suite: 120 tests with 92% average coverage
- Dual licensing system: MIT for code, CC BY-NC-SA 4.0 for content (ADR-013)
- License page with styled two-column layout and credits section
- Scroll-triggered fade-in animation on about page
- @pr prompt for streamlined pull request creation
- Markdown linting documentation (MARKDOWN-LINTING.md)
- Shell script conversion priority list for future work

### Changed
- Extracted inline CSS (27KB) and JS (1.5KB) to external files for browser caching
- Reduced baseof.html from 30KB to 2.5KB (92% smaller)
- Improved CI/CD: Deploy workflow now waits for pr-checks to pass
- Pre-commit hooks now use local Hugo instead of Docker
- Shellcheck configured to show errors only (warnings suppressed)
- YAML linting: Increased line length limit to 300 characters
- Markdown linting: Disabled Hugo-incompatible rules (MD033, MD013, etc.)
- Media page: Reduced left margin on Others section descriptions (mobile)
- Footer: Added "License: MIT & CC BY-NC-SA 4.0" link

- Python linting: Fixed 549 ruff errors across all scripts
- YAML linting: Fixed trailing spaces and blank lines in deploy.yml
- Shellcheck: Fixed array comparison error in remove-branch-protection.sh
- Hugo configuration: Fixed deprecated minify, taxonomyTerm, and :filename settings
- HTML validation: Fixed unescaped ampersand in Google Fonts URL
- Pre-commit hooks: Fixed deprecated stage names (push→pre-push, commit→pre-commit)
- Secret detection: Created baseline file to suppress false positives

### Infrastructure
- Testing: pytest with 80% minimum coverage enforcement
- Linting: ruff, mypy, shellcheck, yamllint, pymarkdown
- Pre-commit hooks: Automated validation before commit and push
- Documentation: Consolidated homepage docs into DESIGN.md
- ADRs: Created ADR-013 (dual licensing) and ADR-014 (Python conversion)
## [1.1.1] - 2026-02-03


### Added
- Year headers on live page (2026, 2025, etc.)
- Content grid pattern documentation in DESIGN.md

### Changed
- Music and Live pages: 2-column layout on all mobile sizes
- Live page: Card layout matching music page style
- Live page: Venue/location displayed before date
- Footer version link points to specific release tag
- GitHub release script preserves Markdown formatting

- Mobile layout: No horizontal overflow on 390px width screens
- Mobile layout: Reduced gaps on small screens (400px and below)
- Artist names: Nowrap on desktop, wrap on mobile
- Release formatting: Proper Markdown rendering in GitHub releases

## [1.1.0] - 2026-02-02

### Added
- Semantic versioning system with CHANGELOG.md
- Version bump automation script (scripts/bump-version.sh)
- GitHub Release creation script (scripts/create-github-release.sh)
- Version display in footer with link to releases
- Glitch effect on "n o i s e" text on about page
- Glitch effect on "Enter the void →" link on homepage
- ADR-012: Semantic Versioning for AI-Driven Development

### Changed
- GitHub Actions deploy workflow now creates releases automatically
- Commit Agent can now write to CHANGELOG.md and create git tags
- Footer displays version on separate line with styled link
- Footer font size reduced to 0.8rem

- Date wrapping on mobile (28 Sep now stays on one line)
- Venue name wrapping on mobile (e.g., Vihdin Kultsan Halloween)
- Music section no longer shows "Releases" index page
- Tab spacing reduced on mobile to prevent text wrapping

## [1.0.0] - 2026-02-02

### Added
- Initial release with semantic versioning
- Homepage with band information
- Music page with Bandcamp integration
- Live performances page with upcoming and past gigs
- Media page with photo gallery
- About page with band details
- GitHub Actions deployment with OIDC authentication
- CloudFront CDN with SSL certificate
- Pre-commit hooks for local validation
- Architecture Decision Records (ADRs)
