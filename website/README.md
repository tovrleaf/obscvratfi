# Website Directory

This directory contains the Hugo static site source for Obscvrat.

## Quick Reference

- **Config:** `hugo.toml` - Main Hugo configuration
- **Content:** `content/` - All pages and posts in Markdown
- **Templates:** `layouts/` - Hugo HTML templates
- **Static files:** `static/` - Files served as-is (robots.txt, etc.)
- **Build output:** `public/` - Generated site (do not commit)

## Building

### Local Development
```bash
# From project root:
make serve
```

### Production Build
```bash
make build-prod
```

## Directory Details

### `content/`
- `about/_index.md` - About page
- `gigs/` - Gig listings (one file per gig)
  - `_index.md` - Gigs list page
  - `YYYY-MM-DD-venue-name.md` - Individual gig
- `albums/` - Album releases (one file per album)
  - `_index.md` - Albums list page
  - `slug-name.md` - Individual album

### `layouts/`
- `baseof.html` - Base template with styling
- `index.html` - Homepage
- `_default/` - Default templates for all pages
- `about/` - About section templates
- `gigs/` - Gig section templates
- `albums/` - Album section templates
- `partials/` - Reusable components
- `shortcodes/` - Custom Markdown syntax

### `archetypes/`
Templates for `hugo new` command:
- `gigs.md` - Template for new gigs
- `albums.md` - Template for new albums

### `static/`
Files served directly at root:
- `robots.txt` - Search engine directives

## Hugo Config (hugo.toml)

Key settings:
- `title` - Site title (Obscvrat)
- `baseURL` - Site URL (localhost for dev, obscvrat.fi for prod)
- `outputs` - Output formats (HTML, JSON, RSS, sitemap)
- `menu` - Navigation menu items
- `params` - Site parameters and social links

## File Naming

### Gigs
- **Directory:** `content/gigs/`
- **Pattern:** `YYYY-MM-DD-venue-name.md`
- **Example:** `2025-01-15-tavastia-club.md`
- **URL:** `/gigs/2025-01-15-tavastia-club/`

### Albums
- **Directory:** `content/albums/`
- **Pattern:** `slug-name.md`
- **Example:** `silence-and-resonance.md`
- **URL:** `/albums/silence-and-resonance/`

## Adding Content

### New Gig
```bash
hugo new gigs/2025-04-20-new-venue.md
```

### New Album
```bash
hugo new albums/new-album-name.md
```

Edit the generated file with your content.

## Testing

### Local Server
```bash
make serve
```
Visit http://localhost:1313

### Production Build (Minified)
```bash
make build-minified
```

### Production Build (Real baseURL)
```bash
make build-prod
```

## Output Files

After building, check `public/`:
- `index.html` - Homepage
- `sitemap.xml` - XML sitemap for search engines
- `feed.xml` - RSS feed
- `robots.txt` - Search engine directives
- `index.json` - JSON site data
- `about/` - About page and related
- `gigs/` - Gig pages
- `albums/` - Album pages

## Cleanup

```bash
make clean       # Remove public/ and containers
make distclean   # Complete cleanup
```

## Environment Variables

For CloudFront staging:
```bash
DISTRIBUTION_ID=d1234abcd.cloudfront.net make build-staging
```

## See Also

- `hugo.toml` - Configuration file
- `../Makefile` - Build commands
- `../README.md` - Project documentation
- `../CONTRIBUTING.md` - Commit guidelines
