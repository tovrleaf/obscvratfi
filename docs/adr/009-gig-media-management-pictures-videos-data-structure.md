# 9. Gig Media Management - Pictures and Videos Data Structure

**Status:** Proposed

**Date:** 2026-01-24

## Context

The Obscvrat website needs to display media (pictures and videos) associated with gigs. Requirements:

- Each gig can have 0 to many pictures and videos
- Each gig can have an optional poster image (promotional material)
- Pictures stored locally in S3 (same bucket as site)
- Videos hosted on YouTube (embedded)
- Display media on individual gig pages
- Poster displayed on gig page but NOT included in media page
- Separate top-level "Media" page listing all media (excluding posters)
- Pictures: display as thumbnails, click to view full-size in modal, downloadable as originals
- Videos: display as thumbnails, click to view in modal with embedded player, link to YouTube
- Poster: display on gig page as promotional image (not in media gallery)
- Links: support multiple links (event page, ticket sales, etc.)
- Picture sets have author attribution
- Media page uses masonry/waterfall grid layout
- Separate sections for photos and videos with filter/toggle
- Each media set links back to its gig
- Need easy content management for creating and editing gigs

Technical considerations:
- Hugo static site generator
- Need thumbnail generation at build time
- Modal/lightbox functionality for viewing
- Responsive design for mobile
- Maintain aspect ratios in masonry layout
- Simplify gig creation workflow

## Decision

We will implement the following data structure, display strategy, and content management tools:

### Data Structure

**Gig Frontmatter:**
```yaml
---
title: "Venue Name"
date: 2025-03-15
venue: "Venue"
location: "City"
description: "Event description"
poster: "/media/gigs/2025-03-15-venue-name/poster.jpg"
links:
  - url: "https://venue.com/events/obscvrat"
    text: "Event page"
  - url: "https://tickets.com"
    text: "Buy tickets"
other_performers: ["Artist 1", "Artist 2"]
media:
  pictures:
    author: "Photographer Name"
    images:
      - pic1.jpg
      - pic2.jpg
  videos:
    - youtube_id: "dQw4w9WgXcQ"
      title: "Full Performance"
draft: false
---
```

### File Organization

**Media files:**
```
/static/media/gigs/2025-03-15-venue-name/
  poster.jpg              # Promotional poster (gig page only)
  pic1.jpg                # Performance photos (media page)
  pic2.jpg
  pic1-thumb.jpg          # Generated thumbnails
  pic2-thumb.jpg
```

**Poster vs Media distinction:**
- **Poster:** Promotional image for the gig (flyer, event artwork)
  - Displayed on gig detail page
  - NOT included in media page gallery
  - Optional field
- **Media (pictures/videos):** Performance documentation
  - Added after the gig happens
  - Displayed on both gig page and media page
  - Can be 0 to many items

### Implementation Components

1. **Thumbnail Generation:** Hugo image processing (build-time)
   - Generate thumbnails automatically during build
   - Maintain aspect ratios
   - Optimize file sizes

2. **Modal/Gallery:** SwiperJS
   - Swipe between media items
   - Touch/gesture support
   - Navigation arrows + pagination
   - Works for both pictures and videos

3. **Media Page Layout:** CSS Grid Masonry
   - Waterfall/Pinterest-style grid
   - Maintain aspect ratios based on dominant ratio
   - Separate sections: "Photos" and "Videos"
   - Filter/toggle between types (default: show all)
   - Each media set grouped by gig with link to gig page

4. **Video Display:**
   - YouTube thumbnail as preview
   - Click opens modal with embedded player
   - Link to original YouTube video

5. **Content Management Tool:** Interactive CLI tool
   - Create new gigs with interactive prompts
   - List all existing gigs
   - Edit existing gigs in $EDITOR
   - Delete gigs with confirmation
   - Validates required fields (date, venue, city)
   - Generates proper filename slugs
   - Accessible via `make gigs` command

## Alternatives Considered

### Alternative 1: External Image Hosting (Cloudinary/imgix)
- **Pros:**
  - Automatic thumbnail generation and optimization
  - CDN delivery
  - Dynamic image transformations
  - Reduces build time
- **Cons:**
  - External dependency
  - Additional cost
  - Less control over files
  - Requires API integration
- **Why rejected:** Keeping media in same S3 bucket simplifies architecture and avoids external dependencies

### Alternative 2: Self-Hosted Videos
- **Pros:**
  - Full control over video files
  - No YouTube dependency
  - Custom player styling
- **Cons:**
  - Large file sizes
  - Bandwidth costs
  - Need video encoding/optimization
  - Streaming infrastructure complexity
- **Why rejected:** YouTube provides free hosting, encoding, and streaming; videos already on YouTube

### Alternative 3: PhotoSwipe for Modal
- **Pros:**
  - Popular, mature library
  - Excellent mobile support
  - Lightweight
- **Cons:**
  - Less flexible than Swiper
  - Primarily for images (videos require workarounds)
  - Less modern API
- **Why rejected:** SwiperJS handles both images and videos elegantly with consistent UX

### Alternative 4: Masonry.js Library
- **Pros:**
  - Better browser support than CSS Grid masonry
  - More control over layout
  - Proven solution
- **Cons:**
  - JavaScript dependency
  - Performance overhead
  - CSS Grid masonry is native and faster
- **Why rejected:** CSS Grid masonry is modern, performant, and reduces JavaScript dependencies

### Alternative 5: Flat Media Structure (No Gig Grouping)
```
/static/media/
  pic1.jpg
  pic2.jpg
```
- **Pros:**
  - Simpler file structure
  - Easier to manage
- **Cons:**
  - Hard to organize as media grows
  - No clear association with gigs
  - Naming conflicts likely
- **Why rejected:** Grouping by gig provides clear organization and scalability

### Alternative 6: Manual Gig Creation (No Tool)
- **Pros:**
  - No additional tooling needed
  - Direct file editing
  - More control
- **Cons:**
  - Error-prone (typos, wrong format)
  - Inconsistent frontmatter structure
  - Slow workflow
  - Need to remember all fields
  - Manual filename generation
- **Why rejected:** Interactive tool ensures consistency and speeds up workflow

## Consequences

### Positive
- **Clear data structure:** Frontmatter clearly defines media relationships
- **Organized files:** Gig-based folders keep media organized
- **Build-time optimization:** Hugo generates thumbnails automatically
- **Modern UX:** SwiperJS provides smooth, touch-friendly gallery experience
- **Responsive layout:** Masonry grid adapts to different screen sizes
- **Scalable:** Structure supports unlimited gigs and media
- **SEO-friendly:** Static HTML with proper image alt tags
- **No external dependencies:** All media in same S3 bucket
- **Flexible filtering:** Media page supports multiple view modes
- **Easy content management:** Interactive tool simplifies gig creation
- **Consistent structure:** Tool enforces proper frontmatter format
- **Fast workflow:** Create gigs in seconds with prompts

### Negative
- **Build time increase:** Thumbnail generation adds to Hugo build time
- **Manual media management:** Must manually add media to frontmatter after gigs
- **Storage costs:** Original + thumbnail images increase S3 storage
- **Browser support:** CSS Grid masonry requires modern browsers (fallback needed)
- **SwiperJS dependency:** Adds ~50KB JavaScript library
- **YouTube dependency:** Videos unavailable if YouTube is blocked/down
- **Tool dependency:** Requires bash shell (not Windows-native)
- **Editor requirement:** Edit functionality needs $EDITOR set

### Neutral
- **Author per picture set:** One author attribution per gig's pictures (not per individual image)
- **YouTube IDs only:** Store just video IDs, not full URLs (cleaner, but requires URL construction)
- **Aspect ratio handling:** Dominant ratio maintained, but some cropping may occur in masonry layout
- **Filter default:** Shows all media initially, user can filter to photos or videos
- **Tool is optional:** Can still create gigs manually if preferred

## Notes

### Gig Management Tool

An interactive CLI tool provides easy gig content management:

**Features:**
- Interactive prompts for all required fields
- Optional fields: poster, event page link, ticket link, other performers
- Automatic filename generation (YYYY-MM-DD-venue-slug.md)
- List/edit/delete existing gigs
- Validates date format and required fields
- Opens editor after creation (optional)
- Color-coded output for better UX

**Usage:**
```bash
make gigs
```

**Menu Options:**
1. Create new gig - Interactive prompts for all fields
2. List all gigs - Shows date, venue, location
3. Edit existing gig - Select from numbered list
4. Delete gig - Select and confirm deletion
5. Exit

This tool simplifies content management and ensures consistent frontmatter structure.

### Implementation Checklist
- [ ] Create gig management tool
- [ ] Add `make gigs` target to Makefile
- [ ] Create Hugo shortcode for media gallery
- [ ] Implement Hugo image processing for thumbnails
- [ ] Add SwiperJS library and configuration
- [ ] Create media page template with masonry layout
- [ ] Add filter/toggle functionality (JavaScript)
- [ ] Create gig page template with media display
- [ ] Add CSS for responsive masonry grid
- [ ] Implement modal for full-size viewing
- [ ] Add download links for original images
- [ ] Add YouTube embed support in modal
- [ ] Test on mobile devices
- [ ] Add fallback for browsers without CSS Grid masonry support
- [ ] Update README.md with gig management instructions

### Hugo Image Processing Example
```go-html-template
{{ $image := resources.Get .path }}
{{ $thumb := $image.Resize "400x" }}
<img src="{{ $thumb.RelPermalink }}" alt="{{ .title }}">
```

### SwiperJS Configuration
```javascript
const swiper = new Swiper('.swiper', {
  navigation: true,
  pagination: { clickable: true },
  keyboard: true,
  loop: true
});
```

### Gig Management Example
```bash
# Create/manage gigs interactively
make gigs
```

### Related Decisions
- **ADR-003:** Website hosting and static site generation (Hugo + S3)
- **ADR-007:** Homepage design system (dark minimal aesthetic applies to media page)

### Future Considerations
- Add lazy loading for images on media page
- Consider progressive image loading (blur-up technique)
- Add image captions/descriptions if needed
- Implement search functionality on media page
- Add EXIF data display for photos
- Consider video thumbnails with play button overlay
- Add batch media upload functionality to script
- Support for other video platforms (Vimeo, etc.)
- Automatic Instagram integration for photos
