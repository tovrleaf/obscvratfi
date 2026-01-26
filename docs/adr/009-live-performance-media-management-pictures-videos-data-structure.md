# 9. Media Management - Pictures, Videos, and Other Content

**Status:** Proposed

**Date:** 2026-01-24

## Context

The Obscvrat website needs to display media (pictures and videos) associated with live performances, as well as other media like interviews and mentions. Requirements:

- Each live performance can have 0 to many pictures and videos
- Each live performance can have an optional poster image (promotional material)
- Pictures stored locally in S3 (same bucket as site)
- Videos hosted on YouTube (embedded)
- Display media on individual live performance pages
- Poster displayed on live performance page but NOT included in media page
- Separate top-level "Media" page listing all media (excluding posters)
- Media page has three sections: Photos, Videos, and Others
- Others section includes: interviews, mentions, reviews, etc.
- Pictures: display as thumbnails, click to view full-size in modal, downloadable as originals
- Videos: display as thumbnails, click to view in modal with embedded player, link to YouTube
- Others: display as links with title and optional description
- Poster: display on live performance page as promotional image (not in media gallery)
- Event link: single URL to event page
- Other performers: list with optional links to their pages/socials
- Picture sets have author attribution
- Media page uses masonry/waterfall grid layout for photos/videos
- Separate sections for photos, videos, and others with filter/toggle
- Each media set links back to its live performance (if applicable)
- Need easy content management for creating and editing live performances

Technical considerations:
- Hugo static site generator
- Need thumbnail generation at build time
- Modal/lightbox functionality for viewing
- Responsive design for mobile
- Maintain aspect ratios in masonry layout
- Simplify live performance creation workflow

## Decision

We will implement the following data structure, display strategy, and content management tools:

### Data Structure

**Two types of media:**

1. **Embedded media** (in live performance files) - Current approach, backward compatible
2. **Standalone media** (separate files) - Can optionally link to live performances

**Gig Frontmatter (Embedded Media):**
```yaml
---
title: "Event Name"
date: 2025-03-15
venue: "Venue"
location: "City"
description: "Event description"
poster: "/media/live/2025-03-15-event-name/poster.jpg"
event_link: "https://venue.com/events/obscvrat"
other_performers:
  - name: "Artist 1"
    url: "https://artist1.com"
  - name: "Artist 2"
media:
  pictures:
    author: "Photographer Name"
    author_url: "https://photographer.com"  # Optional
    images:
      - pic1.jpg
      - pic2.jpg
  videos:
    - youtube_id: "dQw4w9WgXcQ"
      title: "Full Performance"
      credits:
        - type: "Recorded"
          name: "John Doe"
          url: "https://example.com"  # Optional
        - type: "Mastered"
          name: "Jane Smith"
draft: false
---
```

**Standalone Picture (Separate File):**
```yaml
# /content/media/pictures/2025-01-15-noise-space-photo.md
---
title: "Noise Space XV Performance"
date: 2025-01-15
type: "picture"
image: "/media/standalone/2025-01-15-noise-space.jpg"
author: "Photographer Name"
author_url: "https://photographer.com"  # Optional
gig: "2025-10-11-noise-space-xv"  # Optional: links to gig
description: "Crowd shot during performance"
draft: false
---
```

**Standalone Video (Separate File):**
```yaml
# /content/media/videos/2025-01-15-full-set.md
---
title: "Full Set Recording"
date: 2025-01-15
type: "video"
youtube_id: "dQw4w9WgXcQ"
gig: "2025-10-11-noise-space-xv"  # Optional: links to gig
description: "Complete performance"
draft: false
---
```

**Field Descriptions:**

*Required fields:*
- `title`: Event name (used for page title and URL slug if provided)
- `date`: Event date (YYYY-MM-DD format)
- `venue`: Venue name (used for URL slug if title is empty)
- `location`: City/location

*Optional fields:*
- `description`: Event description
- `poster`: Path to promotional poster image
- `event_link`: URL to event page (where tickets can be found)
- `other_performers`: List of other artists (with optional URLs)
- `media`: Pictures and videos added after the event

### File Organization

**Media files:**
```
# Gig-embedded media (Hugo processes from assets)
/assets/media/live/2025-03-15-event-name/
  poster.jpg              # Promotional poster (gig page only)
  pic1.jpg                # Performance photos (media page)
  pic2.jpg

# Generated at build time by Hugo
/public/media/live/2025-03-15-event-name/
  poster.jpg
  pic1.jpg
  pic2.jpg
  # Hugo generates responsive versions automatically

# Standalone media
/static/media/standalone/
  2025-01-15-noise-space.jpg
  2025-02-20-crowd-shot.jpg
```

**Content structure:**
```
/content/media/
  pictures/
    2025-01-15-noise-space-photo.md
    2025-02-20-crowd-shot.md
  videos/
    2025-01-15-full-set.md
  others.md
```

**URL slug generation:**
- Uses event name (title) if provided: `YYYY-MM-DD-event-name`
- Falls back to venue name if event name is empty: `YYYY-MM-DD-venue-name`

**Poster vs Media distinction:**
- **Poster:** Promotional image for the live performance (flyer, event artwork)
  - Displayed on live performance detail page
  - NOT included in media page gallery
  - Optional field
- **Media (pictures/videos):** Performance documentation
  - Added after the live performance happens
  - Displayed on both live performance page and media page
  - Can be 0 to many items

### Implementation Components

1. **Thumbnail Generation:** Hugo image processing (build-time)
   - Generate thumbnails automatically during build
   - Maintain aspect ratios
   - Optimize file sizes

2. **Modal/Gallery:** SwiperJS
   - Lightbox modal for full-size viewing
   - Navigation arrows to browse between images/videos
   - Click outside or X button to close
   - Display live performance info and photographer/credits
   - Download original image button (right-aligned)
   - Open in YouTube button for videos (right-aligned)
   - Touch/gesture support for mobile
   - Keyboard navigation support

3. **Media Page Layout:** CSS Grid Masonry (4 columns)
   - Waterfall/Pinterest-style grid
   - 4 columns on desktop, 3 on tablet, 2 on mobile, 1 on small mobile
   - Maintain aspect ratios (no cropping)
   - Separate sections: "Photos", "Videos", and "Others"
   - Filter/toggle between types (default: show all)
   - Each media item links to lightbox modal
   - Gig name and photographer/credits shown below thumbnails

4. **Video Display:**
   - YouTube thumbnail as preview in grid
   - Click opens modal with embedded YouTube player
   - Video title displayed above player
   - Credits displayed below player (e.g., "Recorded by John Doe")
   - Open in YouTube button to view on YouTube
   - Support for multiple credits per video (Recorded, Mastered, etc.)

5. **Content Management Tool:** Interactive CLI tool
   - Create new live performances with interactive prompts
   - List all existing live performances
   - Edit existing live performances in $EDITOR
   - Delete live performances with confirmation
   - Validates required fields (date, venue, city)
   - Generates proper filename slugs
   - Accessible via `make live performances` command

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
  - No clear association with live performances
  - Naming conflicts likely
- **Why rejected:** Grouping by live performance provides clear organization and scalability

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
- **Organized files:** Gig-based folders keep media organized in assets/
- **Build-time optimization:** Hugo generates responsive images automatically from assets/
- **Modern UX:** Lightbox modals with navigation provide smooth gallery experience
- **Responsive layout:** Masonry grid adapts (4/3/2/1 columns) to different screen sizes
- **Scalable:** Structure supports unlimited live performances and media
- **SEO-friendly:** Static HTML with proper image alt tags
- **No external dependencies:** All media in same S3 bucket
- **Flexible filtering:** Media page supports multiple view modes (Photos, Videos, Others)
- **Easy content management:** Interactive tool simplifies live performance creation
- **Consistent structure:** Tool enforces proper frontmatter format
- **Fast workflow:** Create live performances in seconds with prompts
- **Centralized media:** All media types accessible from single page
- **Per-video credits:** Flexible credit system for any role (Recorded, Mastered, etc.)
- **Download originals:** Users can download full-resolution images
- **YouTube integration:** Videos open in YouTube with one click

### Negative
- **Build time increase:** Hugo image processing adds to build time
- **Manual media management:** Must manually add media to frontmatter after live performances
- **Storage costs:** Original images in assets/ increase repository size
- **Browser support:** CSS Grid masonry requires modern browsers (fallback needed)
- **JavaScript dependency:** Lightbox modals require JavaScript enabled
- **YouTube dependency:** Videos unavailable if YouTube is blocked/down
- **Tool dependency:** Requires bash shell (not Windows-native)
- **Editor requirement:** Edit functionality needs $EDITOR set
- **Assets directory:** Images must be in assets/ for Hugo processing (not static/)

### Neutral
- **Author per picture set:** One author attribution per gig's pictures (not per individual image)
- **YouTube IDs only:** Store just video IDs, not full URLs (cleaner, but requires URL construction)
- **Aspect ratio handling:** Dominant ratio maintained, but some cropping may occur in masonry layout
- **Filter default:** Shows all media initially, user can filter to photos or videos
- **Tool is optional:** Can still create live performances manually if preferred

## Notes

### Gig Management Tool

An interactive CLI tool provides easy live performance content management:

**Features:**
- Interactive prompts for all required fields
- Optional fields: poster, event link with title, linkable performers
- Automatic filename generation (YYYY-MM-DD-venue-slug.md)
- List/edit/delete existing live performances
- Validates date format and required fields
- Opens editor after creation (optional)
- Color-coded output for better UX

**Usage:**
```bash
make live performances
```

**Menu Options:**
1. Create new live performance - Interactive prompts for all fields
2. List all live performances - Shows date, venue, location
3. Edit existing live performance - Select from numbered list
4. Delete live performance - Select and confirm deletion
5. Exit

This tool simplifies content management and ensures consistent frontmatter structure.

### Implementation Checklist

**Completed:**
- [x] Create live performance management tool
- [x] Add `make live performances` target to Makefile
- [x] Create live performance list page template (grouped by year)
- [x] Create live performance detail page template
- [x] Display event link and linkable performers
- [x] Auto-download posters from URLs
- [x] Interactive edit with prefilled values
- [x] Apply site-wide design system to live performance pages
- [x] Update README.md with live performance management instructions
- [x] Create media management tool (`make media`)
- [x] Support for standalone media items
- [x] Implement Hugo image processing (from assets/)
- [x] Add SwiperJS library and configuration
- [x] Create media page template with masonry layout (4 columns)
- [x] Add filter/toggle functionality (JavaScript) for Photos/Videos/Others
- [x] Add CSS for responsive masonry grid (4/3/2/1 columns)
- [x] Implement modal for full-size viewing with navigation arrows
- [x] Add download links for original images
- [x] Add YouTube embed support in modal
- [x] Add per-video credits system (Recorded by, Mastered by, etc.)
- [x] Add Open in YouTube button for videos
- [x] Display media galleries on live performance pages with same lightbox
- [x] Add video title support

**Pending:**
- [ ] Update media tool to create standalone picture/video files
- [ ] Display standalone media on live performance pages (if linked)
- [ ] Create Others content management (interviews, mentions, reviews)
- [ ] Add Others section to media page
- [ ] Test on mobile devices
- [ ] Add fallback for browsers without CSS Grid masonry support
- [ ] Add lazy loading for images on media page
- [ ] Consider progressive image loading (blur-up technique)

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
# Create/manage live performances interactively
make live performances
```

### Others Content Structure

Others content (interviews, mentions, reviews) can be managed as a simple markdown file:

```markdown
# website/content/media/others.md
---
title: "Others"
---

## Interviews
- [Interview with Noise Magazine](https://example.com) - Discussion about experimental sound (2025-01-15)
- [Podcast: Sound Experiments](https://example.com) - 45-minute conversation about process (2024-12-10)

## Reviews
- [Album Review - Sound Journal](https://example.com) - "Challenging and rewarding" (2024-11-20)
- [Live Performance Review](https://example.com) - Noise Space XIV coverage (2024-10-15)

## Mentions
- [Best of 2024 - Experimental Music Blog](https://example.com) - Featured in year-end list
- [Festival Lineup Announcement](https://example.com) - Confirmed for 2025 tour
```

Or as structured frontmatter for more control:

```yaml
---
title: "Others"
items:
  - type: "interview"
    title: "Interview with Noise Magazine"
    url: "https://example.com"
    description: "Discussion about experimental sound"
    date: 2025-01-15
  - type: "review"
    title: "Album Review - Sound Journal"
    url: "https://example.com"
    description: "Challenging and rewarding"
    date: 2024-11-20
---
```

## SEO and Accessibility

### File Naming Convention

All media files use SEO-friendly descriptive names following this pattern:

**Pattern:** `obscvrat-{live-slug}-{type}-{counter}.{ext}`

**Rules:**
- Use hyphens as separators (not underscores or spaces)
- All lowercase
- Include band name (obscvrat)
- Include live performance identifier from slug
- Include type (poster, performance)
- Include counter for multiple files of same type
- Keep total length reasonable (5-6 words max)
- Use year for posters

**Examples:**
- `obscvrat-noise-space-xv-poster-2025.jpg`
- `obscvrat-noise-space-xv-performance-1.jpg`
- `obscvrat-noise-space-xv-performance-2.jpg`

**Benefits:**
- Improved SEO (search engines read filenames)
- Better accessibility (screen readers can parse names)
- Easier content management (descriptive names)
- Consistent organization across all live performances

### Alt Text Pattern

All images include descriptive alt text for accessibility:

**For performance photos:**
```
Obscvrat live at {live_title}, {location}, {date} - Photo by {author}
```

**For posters:**
```
{live_title} poster
```

**Implementation:**
- Gig single page: `website/layouts/live/single.html`
- Media page: `website/layouts/media/list.html`
- Script generates descriptive filenames: `scripts/manage-media.sh`

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
- RSS feed for Others section (interviews, mentions)
- Tagging system for Others content (interview, review, mention, etc.)
- Date-based filtering for Others content
