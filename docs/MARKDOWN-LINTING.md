# Markdown Linting Configuration

This document explains the markdown linting rules disabled for Hugo compatibility.

## Tool: pymarkdown

Configuration file: `.pymarkdownlnt`

## Disabled Rules

The following markdown linting rules are disabled because they conflict with Hugo's markdown conventions:

### MD033: Inline HTML
- **Why disabled:** Hugo content uses HTML for embeds (Bandcamp iframes), custom styling, and shortcodes
- **Example:** `<iframe>` tags for media embeds

### MD013: Line length
- **Why disabled:** Hugo content files can have long lines, especially in frontmatter and URLs
- **Example:** Long URLs in frontmatter

### MD031: Fenced code blocks spacing
- **Why disabled:** Hugo allows flexible spacing around code blocks

### MD036: Emphasis as heading
- **Why disabled:** Hugo content sometimes uses emphasis for visual hierarchy

### MD032: Lists spacing
- **Why disabled:** Hugo allows flexible list formatting

### MD007: List indentation
- **Why disabled:** Hugo supports various list indentation styles

### MD034: Bare URLs
- **Why disabled:** Common in Hugo frontmatter and content

### MD040: Code language specification
- **Why disabled:** Not all code blocks need language specification in Hugo

### MD012: Multiple blank lines
- **Why disabled:** Hugo content uses blank lines for visual separation

### MD003: Heading style consistency
- **Why disabled:** Hugo content mixes ATX and Setext heading styles

### MD024: Duplicate headings
- **Why disabled:** Common in Hugo content (e.g., multiple "Description" headings)

### MD009: Trailing spaces
- **Why disabled:** Hugo markdown allows trailing spaces

### MD026: Trailing punctuation in headings
- **Why disabled:** Hugo headings can have punctuation

### MD010: Hard tabs
- **Why disabled:** Some Hugo content uses tabs

### MD029: Ordered list numbering
- **Why disabled:** Hugo supports various list numbering styles

### MD025: Multiple top-level headings
- **Why disabled:** Hugo content can have multiple H1 headings

### MD005: List indentation consistency
- **Why disabled:** Hugo supports flexible list indentation

## Rationale

Hugo's markdown implementation is more permissive than strict markdown. It supports:
- Inline HTML for rich content
- Flexible formatting for readability
- Various content structures for different page types

These disabled rules prevent false positives while maintaining important structural validation.

## Testing

Run markdown linting:
```bash
make test md              # All markdown files
make test md-commit       # Files in last commit
```

## References

- ADR-004: Development Testing and Validation Requirements
- Hugo Markdown Documentation: https://gohugo.io/content-management/formats/
- Pymarkdown Rules: https://github.com/jackdewinter/pymarkdown
