# Homepage Terminal Sections

## Overview

The homepage features two terminal-style sections displaying latest live performances and music with a monospace aesthetic, selective borders, and alternating colors.

## Layout

### LIVE Section (Left)
- **Position**: Left side, margin-left: 12ch
- **Borders**: Top + left only
- **Content alignment**: Left-aligned
- **Indentation**: 2 tabs before content

### MUSIC Section (Right)
- **Position**: Right side (float: right), margin-right: 12ch
- **Borders**: Top + right only
- **Content alignment**: Right-aligned
- **Indentation**: Content flows right-to-left

## Date Formatting

- **LIVE**: `Jan 17` format (month first)
- **MUSIC**: `17 Jan` format (day first)
- **Separators**:
  - LIVE: `&#8669;` (⇝ Rightwards Dashed Arrow)
  - MUSIC: `&#8668;` (⇜ Leftwards Dashed Arrow)

## Variable Spacing

Spacing around separators varies per row (1-3 tabs) to break monotony:
- **LIVE**: 1-3 tabs BEFORE arrow
- **MUSIC**: 1-3 tabs AFTER arrow
- **Formula**: `(date.Day + index) mod 3 + 1`
  - Uses day of month + row index for pseudo-random variation

## Alternating Colors

### Row-level alternation (nth-of-type):
- **Odd rows (1, 3, 5)**: Base color 90% white
- **Even rows (2, 4)**: Base color 50% white

### Word-level alternation within rows:
- **Odd rows**:
  - w1 (date): bright (90%)
  - w2 (title): dim (50%)
  - w3 (location): bright (90%)
- **Even rows**:
  - w1 (date): dim (50%)
  - w2 (title): bright (90%)
  - w3 (location): dim (50%)

Creates a checkerboard pattern across rows and columns.

## Border Width

Borders extend beyond content using padding:
- **LIVE**: `padding-right: 12ch` on `.terminal-list`
- **MUSIC**: `padding-left: 12ch` on `.terminal-list-right`

## HTML Structure

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

## Key CSS Classes

### Container Classes
- `.terminal-section` - Base container (display: block, width: fit-content)
- `.terminal-left` - Left border + margin-left: 12ch
- `.terminal-right` - Right border + float: right + margin-right: 12ch

### Content Classes
- `.terminal-title` - Section title (above border)
- `.terminal-header` - "view all" link container (below border with top border)
- `.terminal-list` - Content container (padding-right: 12ch for LIVE)
- `.terminal-list-right` - Right-aligned list (padding-left: 12ch for MUSIC)
- `.terminal-item` - Individual row (span with display: inline !important)
- `.terminal-row-link` - Clickable row link (entire row is clickable)

### Word Segment Classes
- `.w1` - First segment (date)
- `.w2` - Second segment (title)
- `.w3` - Third segment (location, LIVE only)

### Utility Classes
- `.tab` - Spacing element (width: 2ch)

## Interaction

- **Hover**: Entire row changes to accent color (no background change)
- **Click**: Entire row is clickable, links to event/album page

## Technical Notes

1. **Line breaks**: Use `<br />` tags, not block display
2. **nth-of-type**: Used instead of nth-child to ignore `<br />` tags
3. **Tab width**: Set to 2ch (2 character widths)
4. **Border color**: `rgba(255, 255, 255, 0.2)`
5. **Clear float**: Add `<div style="clear: both; margin-bottom: 4rem;"></div>` after sections to prevent overlap with following content

## Files

- **Template**: `/website/layouts/index.html`
- **Styles**: `/website/layouts/_default/baseof.html` (inline CSS)
