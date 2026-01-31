# 11. YAML Data Files for Content Management

**Status:** Accepted

**Date:** 2026-01-31

## Context

The current content management scripts (`make live`, `make music`,
`make media`) directly edit markdown files using `sed` and `awk`
commands. This approach has several critical problems:

**Current Issues:**

- **File corruption risk:** In-place editing with `sed -i` can corrupt
  files if the script fails mid-operation
- **Data loss:** If editing fails, user input is lost (stored only in
  memory)
- **No backup:** Original content is overwritten with no recovery option
- **Fragile parsing:** Complex regex patterns are error-prone and hard
  to maintain
- **No validation:** Can't validate changes before writing to file
- **Recent incidents:** Multiple file corruption events where markdown
  files were reduced to 0 bytes

**Example of risky code:**

```bash
sed -i '' "s|^title:.*|title: \"$new_title\"|" "$selected_file"
sed -i '' "s|^date:.*|date: $new_date|" "$selected_file"
# If script crashes here, file is partially modified
```

**User experience problems:**
- Lost work when scripts fail
- Fear of using edit functions
- Manual file recovery from git
- Time wasted re-entering data

We need a safer approach that:

1. Preserves user data even if scripts fail
2. Separates data from presentation
3. Enables proper validation
4. Makes editing safer and more reliable

## Decision

We will implement a **hybrid YAML data files + generated markdown**
architecture:

### Architecture Overview

```text
website/
├── data/                          # Source of truth (YAML)
│   ├── live/
│   │   ├── 2025-10-11-noise-space-xv.yaml
│   │   └── ...
│   └── music/
│       ├── fractured-frequencies.yaml
│       └── ...
├── content/                       # Generated markdown
│   ├── live/
│   │   ├── 2025-10-11-noise-space-xv.md (generated)
│   │   └── ...
│   └── music/
│       ├── fractured-frequencies.md (generated)
│       └── ...
```

### Data Flow

1. **Scripts edit YAML files** in `website/data/`
2. **Generator function** creates markdown from YAML
3. **Hugo builds site** from generated markdown

### YAML Data File Format

```yaml
# website/data/live/2025-10-11-noise-space-xv.yaml
title: "Noise Space XV"
date: 2025-10-11
venue: "Kulttuuritalo"
location: "Helsinki"
poster: "/media/live/2025-10-11-noise-space-xv/poster.jpg"
event_link: "https://example.com/event"
other_performers:
  - name: "Artist 1"
    url: "https://artist1.com"
  - name: "Artist 2"
description: |
  Event description here.
  Can be multiple lines.
  Supports markdown formatting.
draft: false
```

### Markdown Generation

Generator function reads YAML and produces markdown:

```bash
generate_markdown_from_yaml() {
    local yaml_file="$1"
    local md_file="$2"
    
    # Parse YAML using yq
    title=$(yq eval '.title' "$yaml_file")
    date=$(yq eval '.date' "$yaml_file")
    description=$(yq eval '.description' "$yaml_file")
    # ... parse other fields
    
    # Generate markdown with frontmatter
    cat > "$md_file" <<EOF
---
title: "$title"
date: $date
venue: "$venue"
location: "$location"
---

$description
EOF
}
```

### Script Workflow

```bash
make live
  → User selects "Add" or "Edit"
  → Script edits YAML file in data/live/
  → Generator creates/updates markdown in content/live/
  → Done (data preserved in YAML)
```

### Tools Required

- **yq** - YAML processor (like jq for YAML)
  - Install: `brew install yq` (macOS)
  - Alternative: Python with `pyyaml` library

### Why Hybrid (YAML + Markdown)?

#### Option A: YAML only (Hugo data files)

- Hugo can read YAML directly from `data/`
- No markdown generation needed
- But: Can't use Hugo's markdown rendering for descriptions
- But: Need custom templates for everything

#### Option B: Generate markdown on edit (chosen)

- YAML is source of truth
- Markdown generated for Hugo
- Hugo's markdown rendering works
- SEO benefits (content in HTML)
- Easy to preview locally

#### Option C: Generate on build

- YAML edited separately
- Markdown generated during build
- But: Extra build step complexity
- But: Harder to preview changes

We chose **Option B** because it:

- Preserves data safety (YAML)
- Leverages Hugo's markdown features
- Generates immediately (no build step)
- Easy to preview changes

## Alternatives Considered

### Alternative 1: Atomic File Replacement with Backup

Continue using `sed`/`awk` but with safety measures.

**Approach:**

```bash
cp "$file" "$file.bak"
sed ... > "$file.tmp"
if validate "$file.tmp"; then
    mv "$file.tmp" "$file"
    rm "$file.bak"
else
    mv "$file.bak" "$file"
fi
```

**Pros:**
- Minimal code changes
- No new dependencies
- Works with existing approach

**Cons:**
- Still using fragile sed/awk
- Data only in markdown (no separate source)
- Validation logic complex
- Doesn't solve root problem

**Why rejected:** Doesn't address fundamental issue of data
preservation; still risky

### Alternative 2: Template-Based Generation (No YAML)

Generate markdown from scratch using shell templates.

**Approach:**

```bash
cat > "$file" <<EOF
---
title: "$title"
date: $date
---
$content
EOF
```

**Pros:**
- No YAML parser needed
- Simple implementation
- Consistent output

**Cons:**
- Data still only in memory during edit
- No structured data storage
- Lost if script crashes
- Can't easily query/process data

**Why rejected:** Doesn't preserve data between edits; same data loss
risk

### Alternative 3: Interactive Editor for All Changes

Open file in editor, let user make all changes.

**Approach:**

```bash
${EDITOR:-vim} "$file"
# Validate after editor closes
```

**Pros:**
- Maximum flexibility
- No parsing needed
- User sees full context

**Cons:**
- Not user-friendly for simple edits
- Requires editor knowledge
- Can't provide field-by-field prompts
- No structured data

**Why rejected:** Poor UX for simple edits; doesn't solve data
preservation

### Alternative 4: Database (SQLite)

Store all content in SQLite database.

**Pros:**
- Structured data
- Easy queries
- ACID transactions
- No file corruption

**Cons:**
- Overkill for static site
- Binary format (not git-friendly)
- Requires database management
- Migration complexity
- Not human-readable

**Why rejected:** Too complex for static site needs; YAML is simpler
and git-friendly

## Consequences

### Positive

- **Data preservation:** YAML files are source of truth, never lost
- **Safe editing:** YAML parsers handle validation properly
- **No corruption risk:** Generate fresh markdown each time
- **Easy to edit:** Clean, readable YAML format
- **Version control friendly:** Clear diffs in git
- **Separation of concerns:** Data vs presentation
- **Easy migration:** Can change markdown format anytime
- **Proper validation:** YAML parser catches errors
- **Backup-friendly:** YAML files easy to backup/restore
- **Queryable:** Can process YAML data with scripts

### Negative

- **Extra build step:** Need to generate markdown from YAML
- **New dependency:** Requires `yq` or Python with `pyyaml`
- **Migration effort:** Need to convert existing markdown to YAML
- **Two files per item:** YAML + generated markdown
- **Learning curve:** Team needs to understand YAML format
- **Complexity:** More moving parts than direct editing

### Neutral

- **File count:** More files in repository (YAML + markdown)
- **Git history:** YAML changes tracked separately from markdown
- **Hugo compatibility:** Works with existing Hugo setup
- **Performance:** Negligible impact (generation is fast)

## Notes

### Implementation Plan

#### Phase 1: Setup

- Create `website/data/live/` and `website/data/music/` directories
- Install `yq` tool
- Write YAML generator function
- Add to scripts

#### Phase 2: Migration

- Convert existing markdown to YAML (one-time script)
- Verify generated markdown matches original
- Test with sample edits

#### Phase 3: Update Scripts

- Modify `manage-live.sh` to edit YAML
- Modify `manage-music.sh` to edit YAML
- Call generator after each edit
- Remove sed/awk editing code

#### Phase 4: Testing

- Test add/edit/delete operations
- Verify markdown generation
- Check Hugo builds correctly
- Test with various edge cases

#### Phase 5: Deployment

- Update documentation
- Deploy to production
- Monitor for issues

### Generator Function Location

Create `scripts/generate-markdown.sh`:

```bash
#!/usr/bin/env bash
# Generate markdown from YAML data files

generate_live_markdown() {
    local yaml_file="$1"
    # ... implementation
}

generate_music_markdown() {
    local yaml_file="$1"
    # ... implementation
}
```

### YAML Validation

Use `yq` to validate YAML before generation:

```bash
if ! yq eval '.' "$yaml_file" > /dev/null 2>&1; then
    echo "Error: Invalid YAML in $yaml_file"
    exit 1
fi
```

### Backward Compatibility

During migration:
- Keep existing markdown files
- Generate new markdown alongside
- Compare outputs
- Switch over when confident

### Future Enhancements

- Bulk operations on YAML files
- Data export/import tools
- YAML schema validation
- Automated backups
- Content search across YAML files

## Related Decisions

- **ADR-009:** Live Performance Media Management - defines content
  structure
- **ADR-004:** Development Testing Requirements - validation approach
  applies here

## References

- yq documentation: <https://github.com/mikefarah/yq>
- Hugo data files: <https://gohugo.io/templates/data-templates/>
- YAML specification: <https://yaml.org/spec/>
