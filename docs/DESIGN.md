# Design System

This document defines the visual design patterns and UI components for the
Obscvrat website.

## Design Principles

- **Dark Minimal Aesthetic** - Clean, focused, high contrast
- **Typography-driven** - Text as primary visual element
- **Subtle Interactions** - Hover effects reveal information
- **Consistent Spacing** - Predictable rhythm and alignment

## Typography

### Font Usage

- **Body text:** Typo (var(--font-body))
- **Structural elements:** Fira Mono (var(--font-display))
  - Navigation
  - Dates
  - Metadata
  - Technical information

### Sizes

- **Headings:** Default browser sizes (h1, h2, h3)
- **Body:** 1rem
- **Metadata:** 0.9rem
- **Small text:** 0.85rem
- **Superscript:** 0.7rem

## Colors

### Usage Patterns

- **Primary color** (white): Main text, headings, links
- **Secondary color** (gray): Metadata, dates, descriptions
- **Accent color**: Hover states, active elements
- **Background:** Black or very dark

### Dark Overlays

- **Standard overlay:** `rgba(0, 0, 0, 0.8)`
- **Use cases:**
  - Text backgrounds for readability over images
  - Modal/lightbox backgrounds
  - Hover state backgrounds

## Spacing

### Standard Units

- **Small gap:** 0.5rem
- **Medium gap:** 1rem
- **Large gap:** 2rem
- **Tab width:** 4ch (for aligned lists)

### Margins

- **Section spacing:** 2rem top/bottom
- **Item spacing:** 1.5rem between items
- **Inline spacing:** 0.3rem for small gaps

## Lists

### Standard List Pattern

```text
Date (Fira Mono, secondary color)
[4ch spacing]
Title (primary color, linked)
Superscript metadata (secondary color, 0.7rem)
Description (indented, secondary color, 0.9rem)
```

**Example:** Others section on media page

### Implementation

```html
<div class="list-item">
    <span class="item-date">January 29, 2026</span>
    <a href="#" class="item-title">Title</a><sup class="item-type">type</sup>
    <p class="item-description">Description text</p>
</div>
```

```css
.item-date {
    font-family: var(--font-display);
    color: var(--secondary-color);
    font-size: 0.9rem;
    display: inline-block;
    margin-right: 4ch;
}

.item-description {
    margin-top: 0.5rem;
    margin-left: calc(4ch + 10rem);
    color: var(--secondary-color);
    font-size: 0.9rem;
}
```

## Galleries & Media

### Hover Effects

**Standard image hover:**
- `scale(1.05)` - Subtle zoom, contained by `overflow: hidden`
- `blur(2px)` - Softens image to emphasize overlay
- `brightness(0.5)` - Dims to 50% for text contrast
- Transition: 0.3s ease

### Text Overlays

**Photos:**
- Dark background on event title only
- Text shadows for other elements
- Camera icon for photographer credit
- Dotted separator between date and photographer

**Videos:**
- Dark background on all text elements
- Venue, date, and title displayed
- No photographer credits

### Overlay Specifications

```css
.media-item {
    overflow: hidden;
    position: relative;
}

.media-item:hover img {
    transform: scale(1.05);
    filter: blur(2px) brightness(0.5);
    transition: all 0.3s ease;
}

.media-info {
    position: absolute;
    opacity: 0;
    transition: opacity 0.3s ease;
}

.media-item:hover .media-info {
    opacity: 1;
}
```

### Text Readability

**Strong text shadows for overlays:**

```css
text-shadow: 0 0 8px rgba(0, 0, 0, 0.9), 0 0 4px rgba(0, 0, 0, 0.9);
```

**Dark backgrounds when needed:**

```css
background: rgba(0, 0, 0, 0.8);
padding: 0.5rem;
```

## Interactive Elements

### Links

- **Default:** No underline, primary color
- **Hover:** Accent color or underline (context-dependent)
- **Overlay links:** Never underlined

### Buttons

- **Background:** Secondary background color
- **Border:** 1px solid border color
- **Padding:** 0.5rem 1rem
- **Hover:** Accent color or background change

### Transitions

- **Standard duration:** 0.3s
- **Easing:** ease (default)
- **Properties:** opacity, transform, color, background

## Icons

### Font Awesome Usage

- **Camera icon:** `fa-solid fa-camera` for photo credits
- **Size:** Match surrounding text
- **Color:** Inherit from parent

### Icon Patterns

```html
<i class="fa-solid fa-camera"></i> Photographer Name
```

## Grid Layouts

### Content Grid (Music, Live, Media)

**Responsive auto-fill pattern:**

```css
.content-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: 2rem;
}
```

**Behavior:**
- ~1000px+ width = 4 columns
- ~750-1000px = 3 columns
- ~500-750px = 2 columns
- Mobile (<768px) = forced 2 columns via media query

**Mobile override:**

```css
@media (max-width: 768px) {
    .content-grid {
        grid-template-columns: repeat(2, 1fr);
        gap: 1rem;
    }
}

@media (max-width: 400px) {
    .content-grid {
        gap: 0.75rem;
    }
}
```

**Used in:**
- Music page (`/music/`)
- Live page (`/live/`)
- Media page (`/media/`)

### 4-3-2 Column Layout

**Responsive column layout for content grids (see ADR-009):**

```css
.content-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 2rem;
}

@media (max-width: 1200px) {
    .content-grid {
        grid-template-columns: repeat(3, 1fr);
    }
}

@media (max-width: 768px) {
    .content-grid {
        grid-template-columns: repeat(2, 1fr);
        gap: 1rem;
    }
}
```

**Breakpoints:**
- **Desktop (>1200px):** 4 columns
- **Medium (768px-1200px):** 3 columns  
- **Small (<768px):** 2 columns

**Implementation:**
- Fixed column counts at each breakpoint
- Consistent gap spacing (2rem desktop, 1rem mobile)
- Used for music, live, and media listing pages

### Media Grid

```css
.media-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 2rem;
}
```

### Responsive Behavior

- Auto-fill based on container width
- Minimum item width: 300px
- Consistent gap: 2rem

## Special Elements

### Homepage Terminal Sections

The homepage features two terminal-style sections displaying latest live
performances and music with a monospace aesthetic, selective borders, and
alternating colors.

#### Layout

**LIVE Section (Left):**
- Position: Left side, margin-left: 12ch
- Borders: Top + left only
- Content alignment: Left-aligned
- Indentation: 2 tabs before content

**MUSIC Section (Right):**
- Position: Right side (float: right), margin-right: 12ch
- Borders: Top + right only
- Content alignment: Right-aligned
- Indentation: Content flows right-to-left

#### Date Formatting

- **LIVE:** `Jan 17` format (month first)
- **MUSIC:** `17 Jan` format (day first)
- **Separators:**
  - LIVE: `&#8669;` (⇝ Rightwards Dashed Arrow)
  - MUSIC: `&#8668;` (⇜ Leftwards Dashed Arrow)

#### Variable Spacing

Spacing around separators varies per row (1-3 tabs) to break monotony:
- **LIVE:** 1-3 tabs BEFORE arrow
- **MUSIC:** 1-3 tabs AFTER arrow
- **Formula:** `(date.Day + index) mod 3 + 1`

#### Alternating Colors

**Row-level alternation (nth-of-type):**
- Odd rows (1, 3, 5): Base color 90% white
- Even rows (2, 4): Base color 50% white

**Word-level alternation within rows:**
- **Odd rows:** w1 (date): bright (90%), w2 (title): dim (50%),
  w3 (location): bright (90%)
- **Even rows:** w1 (date): dim (50%), w2 (title): bright (90%),
  w3 (location): dim (50%)

#### HTML Structure

```html
<!-- LIVE Section -->
<section class="terminal-section terminal-left">
    <div class="terminal-title">LIVE</div>
    <div class="terminal-header">
        <span class="tab"></span><span class="tab"></span><span class="tab"></span>
        <a href="/live/">view all</a>
    </div>
    <div class="terminal-list">
        <span class="terminal-item">
            <a href="..." class="terminal-row-link">
                <span class="tab"></span><span class="tab"></span>
                <span class="w1">Jan 17[1-3 tabs]&#8669;</span>
                <span class="tab"></span>
                <span class="w2">Title</span>
                <span class="tab"></span>
                <span class="w3">Location</span>
            </a>
        </span><br />
    </div>
</section>

<!-- MUSIC Section -->
<section class="terminal-section terminal-right">
    <div class="terminal-title terminal-title-right">MUSIC</div>
    <div class="terminal-header terminal-header-right">
        <a href="/music/">view all</a>
        <span class="tab"></span><span class="tab"></span><span class="tab"></span>
    </div>
    <div class="terminal-list terminal-list-right">
        <span class="terminal-item">
            <a href="..." class="terminal-row-link">
                <span class="w2">Title</span>
                <span class="tab"></span>
                <span class="w1">&#8668;[1-3 tabs]17 Jan</span>
                <span class="tab"></span><span class="tab"></span>
            </a>
        </span><br />
    </div>
</section>
```

#### CSS Classes

**Container Classes:**
- `.terminal-section` - Base container (display: block, width: fit-content)
- `.terminal-left` - Left border + margin-left: 12ch
- `.terminal-right` - Right border + float: right + margin-right: 12ch

**Content Classes:**
- `.terminal-title` - Section title (above border)
- `.terminal-header` - "view all" link container (below border with top border)
- `.terminal-list` - Content container (padding-right: 12ch for LIVE)
- `.terminal-list-right` - Right-aligned list (padding-left: 12ch for MUSIC)
- `.terminal-item` - Individual row (span with display: inline !important)
- `.terminal-row-link` - Clickable row link (entire row is clickable)

**Word Segment Classes:**
- `.w1` - First segment (date)
- `.w2` - Second segment (title)
- `.w3` - Third segment (location, LIVE only)

**Utility Classes:**
- `.tab` - Spacing element (width: 2ch)

#### Technical Notes

- Line breaks: Use `<br />` tags, not block display
- nth-of-type: Used instead of nth-child to ignore `<br />` tags
- Tab width: Set to 2ch (2 character widths)
- Border color: `rgba(255, 255, 255, 0.2)`
- Clear float: Add `<div style="clear: both; margin-bottom: 4rem;"></div>`
  after sections

### Dotted Separators

**Use case:** Separating inline metadata (photos only)

```css
border-bottom: 1px dotted rgba(255, 255, 255, 0.3);
padding-bottom: 0.5rem;
max-width: 60%;
margin: 0 auto;
```

### Superscript Metadata

**Use case:** Type labels, small annotations

```html
<sup class="metadata-type">mention</sup>
```

```css
.metadata-type {
    color: var(--secondary-color);
    font-size: 0.7rem;
    margin-left: 0.3rem;
}
```

## Implementation Notes

### CSS Variables

Always use CSS variables for colors and fonts:
- `var(--primary-color)`
- `var(--secondary-color)`
- `var(--accent-color)`
- `var(--font-body)`
- `var(--font-display)`

### Accessibility

- Maintain sufficient contrast ratios
- Use semantic HTML (h1-h6, nav, section)
- Ensure interactive elements are keyboard accessible
- Provide alt text for images

### Performance

- Use `transform` and `opacity` for animations (GPU-accelerated)
- Contain zoom effects with `overflow: hidden`
- Optimize images before upload

## Examples

See implementations in:
- `website/layouts/media/list.html` - Gallery hover effects, Others section
- `website/layouts/baseof.html` - Base typography and color variables
- `website/layouts/live/list.html` - List patterns for gigs

---

**Last Updated:** January 2026
