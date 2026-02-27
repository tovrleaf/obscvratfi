# 019. Archived Gear Visibility System

**Status:** Proposed

**Date:** 2026-02-24

## Context

The gear inventory system (ADR-018) displays all gear items on the `/gear/` page. However, musicians often sell or retire gear over time. Without a way to mark gear as archived:

- Sold gear clutters the active inventory
- No historical record of past gear
- Can't distinguish between current and former equipment
- Users may be confused about what's actually in use

Requirements:
- Keep historical record of sold/retired gear
- Hide archived gear by default (avoid clutter)
- Allow viewing archived gear when desired
- Visually distinguish archived items from active gear
- Maintain complete gear history for reference

The gear page should primarily show active equipment while preserving the ability to view past gear.

## Decision

We will implement a **directory-based archived system** with optional visibility toggle:

### Directory Structure

```
website/data/gear/           # Active gear (default view)
website/data/gear/archived/  # Sold/retired gear (hidden by default)
```

**No schema changes needed** - gear YAML files remain unchanged.

### Archiving Workflow

To archive gear, simply move the file:
```bash
mv website/data/gear/big-muff.yaml website/data/gear/archived/
```

To unarchive:
```bash
mv website/data/gear/archived/big-muff.yaml website/data/gear/
```

### Display Behavior

**Default view (`/gear/`):**
- Read only from `website/data/gear/` directory
- Shows active gear only
- Clean, focused view of current equipment

**With archived parameter (`/gear/?archived`):**
- Read from both `website/data/gear/` and `website/data/gear/archived/`
- Display archived items with visual distinction:
  - Grayed out appearance (reduced opacity)
  - "ARCHIVED" badge
  - Sorted to bottom of list
- Active gear displayed normally at top

### Management Tool Updates

Update `scripts/manage_gear.py`:

**Archive gear:**
- New menu option: "Archive gear"
- Select gear from active list
- Move YAML file to `archived/` directory

**Unarchive gear:**
- New menu option: "Unarchive gear"
- Select gear from archived list
- Move YAML file back to main directory

**List gear:**
- Default: show active only (from `gear/`)
- Flag: `--archived` to show archived only (from `gear/archived/`)
- Flag: `--all` to show everything

### Implementation

**Hugo template (`website/layouts/gear/list.html`):**
- Check for `archived` query parameter in URL
- If not present: read only from `site.Data.gear`
- If present: read from both `site.Data.gear` and `site.Data.gear.archived`
- Apply `.archived` CSS class to items from archived directory
- CSS styling for archived items

**CSS styling:**
```css
.gear-item.archived {
  opacity: 0.5;
  font-style: italic;
}

.gear-item.archived::after {
  content: "ARCHIVED";
  background: #5a5a5a;
  padding: 2px 6px;
  margin-left: 8px;
  font-size: 0.8em;
}
```

## Alternatives Considered

### Alternative 1: Delete Sold Gear

Remove gear from inventory when sold.

**Pros:**
- Simplest approach
- No clutter
- Clean active inventory

**Cons:**
- Lose historical record
- Can't reference past gear
- No way to track what you've owned
- Permanent data loss

**Why rejected:** Historical record is valuable for reference and nostalgia

### Alternative 2: Separate Archived Page

Create `/gear/archived/` page for sold gear.

**Pros:**
- Complete separation
- No mixing of active/archived
- Clear distinction

**Cons:**
- Two pages to maintain
- Harder to compare past/present gear
- More navigation required
- Duplicated filtering logic

**Why rejected:** URL parameter on single page is simpler and more flexible

### Alternative 3: Always Show Archived (No Toggle)

Display all gear with archived items visually distinguished.

**Pros:**
- No URL parameter needed
- Complete view always visible
- Simpler implementation

**Cons:**
- Cluttered default view
- Harder to focus on active gear
- Archived items distract from current inventory

**Why rejected:** Default view should focus on active gear; archived is secondary

### Alternative 4: Boolean Archived Field

Add `archived: true/false` field to each gear YAML file.

**Pros:**
- All data in one directory
- Can query archived status easily
- More metadata per item

**Cons:**
- Requires schema change
- Must update all YAML files
- More complex filtering logic
- Field can be forgotten or inconsistent

**Why rejected:** Directory-based approach is simpler; no schema changes needed

## Consequences

### Positive

- **Complete history:** Keep record of all gear ever owned
- **Clean default view:** Active gear not cluttered by sold items
- **Flexible visibility:** URL parameter to view archived when desired
- **Visual distinction:** Clear indication of archived status
- **Simple implementation:** Just move files between directories
- **No schema changes:** Existing YAML files work as-is
- **Easy management:** Archive/unarchive with simple `mv` command
- **Clear separation:** Filesystem structure reflects gear status

### Negative

- **Two directories:** Need to check both locations for complete inventory
- **URL parameter:** Must check query string in template
- **Visual design:** Need to style archived items appropriately
- **Hugo template:** Must read from both directories when parameter present

### Neutral

- **Default hidden:** Archived gear not visible unless `?archived` parameter added
- **Sorting:** Archived items appear at bottom when shown
- **Badge styling:** "ARCHIVED" badge matches site aesthetic

## Notes

### Implementation Checklist

**Phase 1: Data Schema**
- [ ] Create `website/data/gear/archived/` directory
- [ ] Update ADR-018 with archived field
- [ ] Add archived field to gear YAML schema
- [ ] Set default value: `archived: false`

**Phase 2: Management Script**
- [ ] Update `scripts/manage_gear.py` add function
- [ ] Update edit function to toggle archived status
- [ ] Add `--archived` and `--all` flags to list function

**Phase 3: Display Page**
- [ ] Update `website/layouts/gear/list.html` to check for `archived` parameter
- [ ] Read from both directories when parameter present
- [ ] Add CSS styling for archived items

**Phase 4: Testing**
- [ ] Test adding new gear (defaults to active)
- [ ] Test archiving existing gear
- [ ] Test toggle functionality
- [ ] Test visual styling of archived items

### Future Enhancements

- Add `sold_date` field for detailed history
- Add `sold_price` field for tracking value
- Add `reason` field (sold, broken, traded, etc.)
- Timeline view showing gear acquisition/disposal over time
- Statistics: total gear owned, average ownership duration, etc.

## Related Decisions

- **ADR-018:** Gear Inventory Management - defines base gear system
- **ADR-007:** Homepage Design System - archived styling matches dark minimal aesthetic
- **ADR-011:** YAML Data Files - archived field follows YAML pattern

## References

- Hugo data filtering: https://gohugo.io/templates/data-templates/
- JavaScript toggle patterns: https://developer.mozilla.org/en-US/docs/Web/API/Element/classList
