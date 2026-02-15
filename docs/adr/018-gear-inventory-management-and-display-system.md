# 18. Gear Inventory Management and Display System

**Status:** Proposed

**Date:** 2026-02-15

## Context

The Obscvrat website needs a dedicated page to document musical gear (pedals, synthesizers, instruments, modular equipment). Requirements:

- Store detailed information: name, manufacturer, category, type(s), analog/digital, settings, description, links
- Easy content management via CLI tool (`make gear`)
- Auto-fill specifications via web search when possible
- Searchable and filterable by manufacturer, type, or keyword
- Hidden from search engines (accessible only via link in about page)
- Dynamic display with expandable list view
- No images initially (may add later)

The page should serve as a personal inventory and reference, not a public showcase. It needs structured data storage for easy querying and filtering, while maintaining the dark minimal aesthetic of the site.

## Decision

We will implement a **YAML-based gear inventory system** with interactive CLI management and dynamic web display.

### Data Structure

**Storage:** YAML data files in `website/data/gear/` (one file per item)

**File naming:** `manufacturer-model-slug.yaml`

**Data schema:**
```yaml
name: "Big Muff Pi"
manufacturer: "Electro-Harmonix"
category: "Pedal"  # Pedal, Synth, Instrument, Modular, Other
types:  # Multiple types allowed (tags)
  - "Distortion"
  - "Fuzz"
technology: "Analog"  # Analog, Digital, Hybrid
settings:  # Knob/control names only
  - "Volume"
  - "Tone"
  - "Sustain"
description: "Classic fuzz pedal with thick, creamy sustain..."
manufacturer_url: "https://www.ehx.com/products/big-muff-pi/"
pedal_url: "https://reverb.com/p/electro-harmonix-big-muff-pi"
```

### Management Tool

**Command:** `make gear`

**Features:**
1. **Add gear:**
   - User provides: manufacturer + name
   - Script searches web for specifications (type, technology, settings, URLs)
   - Auto-fills YAML fields where possible
   - Prompts user for missing information
   - Creates YAML file in `website/data/gear/`

2. **List gear:**
   - Show all gear (manufacturer + name only)
   - Filter by category (Pedals, Synths, etc.)
   - Filter by manufacturer
   - Filter by type (Distortion, Delay, etc.)

3. **Search gear:**
   - Keyword search across all fields
   - Works on filtered subsets

4. **Edit gear:**
   - Select from list
   - Opens YAML in $EDITOR

5. **Delete gear:**
   - Select from list
   - Confirm deletion

**Web Search Integration:**
- Use web search API to find gear specifications
- Search query: "[manufacturer] [name] specifications"
- Parse results for: type, analog/digital, controls/settings, URLs
- If auto-fill fails, prompt user for manual entry

### Display Page

**URL:** `/gear/` (hidden from search engines)

**Layout:**
- **Default view:** List of manufacturer + name only
- **Filtering controls:** Dropdowns/buttons for category, manufacturer, type
- **Search box:** Keyword filter
- **Expandable items:** Click to expand inline, showing full details
- **Collapsed state:** Just "Manufacturer - Name"
- **Expanded state:** All fields (type, technology, settings, description, links)

**Styling:**
- Match dark minimal aesthetic (ADR-007)
- Typo font for body text, Fira Mono for structure
- Subtle expand/collapse animation
- External links open in new tab

**JavaScript:**
- Client-side filtering (no page reload)
- Expand/collapse functionality
- Search across visible items
- Filter combinations (e.g., "Pedals" + "Delay" + "Analog")

### SEO & Privacy

**Hidden from search engines:**
- Add to `robots.txt`: `Disallow: /gear/`
- Exclude from sitemap generation
- No meta tags for indexing

**Access:**
- Only link from about page: "broken circuits, and [analog filth](/gear/)—"
- No navigation menu entry
- Direct URL access allowed (not password-protected)

### Implementation Components

1. **Python script:** `scripts/manage_gear.py`
   - Interactive CLI menu
   - Web search integration
   - YAML file management
   - Validation and error handling

2. **Hugo template:** `website/layouts/gear/list.html`
   - Reads YAML data from `website/data/gear/`
   - Generates expandable list
   - Includes filtering JavaScript

3. **CSS:** Expand/collapse styling in `website/static/css/main.css`

4. **robots.txt:** Add `/gear/` disallow rule

5. **About page:** Add link to `/gear/`

## Alternatives Considered

### Alternative 1: Single Markdown File

Store all gear in one markdown file with manual formatting.

**Pros:**
- Simplest approach
- No script needed
- Easy to edit

**Cons:**
- No structured data (can't filter/search programmatically)
- Hard to maintain as list grows
- No auto-fill capabilities
- Manual formatting tedious

**Why rejected:** Lacks structure and automation needed for detailed inventory

### Alternative 2: Single Type Classification

Each item has only one type (primary classification).

```yaml
type: "Fuzz"  # Must choose one
```

**Pros:**
- Simpler data model
- Clearer categorization
- Easier filtering logic

**Cons:**
- Many pedals serve multiple purposes (Big Muff is both distortion AND fuzz)
- Less accurate representation
- User must choose arbitrary primary type
- Harder to find gear under secondary use case

**Why rejected:** Multi-purpose gear is common; tags provide better flexibility

### Alternative 3: Database (SQLite)

Store gear in SQLite database.

**Pros:**
- Powerful querying
- Relational data
- ACID transactions

**Cons:**
- Overkill for static site
- Binary format (not git-friendly)
- Requires database management
- Not human-readable
- Adds complexity

**Why rejected:** YAML files are simpler, git-friendly, and sufficient for needs

### Alternative 4: Manual Entry Only (No Web Search)

User manually enters all information for each item.

**Pros:**
- No web search API dependency
- No API key needed
- Full control over data

**Cons:**
- Tedious and time-consuming
- Error-prone (typos, inconsistent formatting)
- Discourages adding gear
- No time savings

**Why rejected:** Auto-fill significantly improves UX and reduces friction

### Alternative 5: Modal Popup for Details

Click item opens modal overlay with full details.

**Pros:**
- Cleaner visual separation
- Focus on single item
- Common UI pattern

**Cons:**
- Requires closing modal to view another item
- More clicks to compare items
- Harder to scan multiple items quickly
- More complex JavaScript

**Why rejected:** Expandable list allows easier comparison and scanning

## Consequences

### Positive

- **Structured data:** YAML enables programmatic filtering and searching
- **Auto-fill:** Web search saves time entering specifications
- **Flexible categorization:** Multiple types per item (tags) accurately represents multi-purpose gear
- **Easy management:** CLI tool simplifies adding/editing gear
- **Dynamic filtering:** JavaScript filtering provides smooth UX without page reloads
- **Hidden from search:** Privacy maintained while still accessible via direct link
- **Expandable list:** Easy to scan and compare items
- **Scalable:** Can add hundreds of items without performance issues
- **Git-friendly:** YAML files track changes clearly
- **Future-proof:** Can add images, signal chains, or other features later

### Negative

- **Web search dependency:** Auto-fill requires web search API (may fail or require API key)
- **Manual fallback:** If auto-fill fails, user must enter all info manually
- **JavaScript required:** Filtering won't work without JavaScript enabled
- **Maintenance:** Must keep script updated if data schema changes
- **Learning curve:** User must understand YAML structure for manual edits
- **No images initially:** Visual reference missing (can add later)

### Neutral

- **One file per item:** More files in repository but better organization
- **Hidden page:** Not discoverable via navigation, only via about page link
- **Multiple types:** More flexible but requires careful tagging
- **CLI tool:** Requires terminal access (not web-based admin)

## Notes

### Web Search API Options

**Option 1: Tavily Search API**
- Kiro CLI has built-in web search capability
- No additional API key needed
- Returns structured results

**Option 2: DuckDuckGo (via Python library)**
- Free, no API key
- Simple integration
- May have rate limits

**Option 3: Manual entry fallback**
- If search fails, prompt user for each field
- Always available as backup

**Recommendation:** Use Kiro CLI web search (Tavily) with manual fallback.

### Type Categories

**Common pedal types:**
- Distortion, Overdrive, Fuzz
- Delay, Reverb, Echo
- Chorus, Flanger, Phaser
- Tremolo, Vibrato
- Compressor, Limiter
- EQ, Filter
- Looper, Sampler
- Noise, Glitch

**Synth categories:**
- Analog Synth, Digital Synth, Hybrid
- Modular, Semi-Modular
- Drum Machine, Sampler
- Sequencer, Groovebox

### Future Enhancements

- Add images of gear (photos or manufacturer images)
- Signal chain diagrams showing how gear connects
- Track gear used on specific releases/performances
- Maintenance logs (repairs, modifications, settings changes)
- Purchase date and price tracking
- Condition notes (mint, good, modified, etc.)
- Favorite settings presets
- Audio samples or demo links

### Implementation Checklist

**Phase 1: Data Structure**
- [ ] Create `website/data/gear/` directory
- [ ] Define YAML schema
- [ ] Create example gear file for testing

**Phase 2: Management Script**
- [ ] Create `scripts/manage_gear.py`
- [ ] Implement add/list/search/edit/delete functions
- [ ] Integrate web search API
- [ ] Add manual entry fallback
- [ ] Test with real gear data

**Phase 3: Display Page**
- [ ] Create `website/layouts/gear/list.html`
- [ ] Implement expandable list layout
- [ ] Add filtering controls (category, manufacturer, type)
- [ ] Add search box
- [ ] Style with dark minimal aesthetic

**Phase 4: JavaScript**
- [ ] Implement client-side filtering
- [ ] Add expand/collapse functionality
- [ ] Add search functionality
- [ ] Test filter combinations

**Phase 5: Integration**
- [ ] Add `/gear/` to robots.txt
- [ ] Update about page with link
- [ ] Test hidden page behavior
- [ ] Verify search engine exclusion

**Phase 6: Testing**
- [ ] Add multiple gear items
- [ ] Test all filtering combinations
- [ ] Test search functionality
- [ ] Test expand/collapse
- [ ] Test on mobile devices

## Related Decisions

- **ADR-007:** Homepage Design System - dark minimal aesthetic applies to gear page
- **ADR-011:** YAML Data Files for Content Management - same approach used here
- **ADR-009:** Live Performance Media Management - similar YAML + CLI pattern

## References

- YAML specification: https://yaml.org/spec/
- Hugo data files: https://gohugo.io/templates/data-templates/
- Web search APIs: Tavily, DuckDuckGo
- Expandable list UI patterns: https://www.w3.org/WAI/ARIA/apg/patterns/accordion/
