# Design System

This document defines the visual design patterns and UI components for the Obscvrat website.

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

```
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
