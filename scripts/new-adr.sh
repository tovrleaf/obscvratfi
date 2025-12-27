#!/bin/bash

# Script to create a new ADR from template
# Usage: ./scripts/new-adr.sh "Decision Title"

set -e

# Check if title is provided
if [ -z "$1" ]; then
    echo "Error: Please provide a title for the ADR"
    echo "Usage: ./scripts/new-adr.sh \"Your Decision Title\""
    exit 1
fi

TITLE="$1"
ADR_DIR="docs/adr"
TEMPLATE="$ADR_DIR/template.md"
README="$ADR_DIR/README.md"

# Find the next ADR number
LAST_ADR=$(ls -1 "$ADR_DIR" | grep -E '^[0-9]{3}-.*\.md$' | sort -r | head -n 1)
if [ -z "$LAST_ADR" ]; then
    NEXT_NUM="003"  # Start from 003 since 000-002 are the initial ADRs
else
    LAST_NUM=$(echo "$LAST_ADR" | cut -d'-' -f1)
    NEXT_NUM=$(printf "%03d" $((10#$LAST_NUM + 1)))
fi

# Convert title to filename (lowercase, replace spaces with hyphens)
FILENAME=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
NEW_ADR="$ADR_DIR/$NEXT_NUM-$FILENAME.md"

# Check if template exists
if [ ! -f "$TEMPLATE" ]; then
    echo "Error: Template not found at $TEMPLATE"
    exit 1
fi

# Create new ADR from template
cp "$TEMPLATE" "$NEW_ADR"

# Replace placeholders
TODAY=$(date +%Y-%m-%d)
sed -i.bak "s/\[NUMBER\]/$NEXT_NUM/g" "$NEW_ADR"
sed -i.bak "s/\[Title in Imperative Form\]/$TITLE/g" "$NEW_ADR"
sed -i.bak "s/YYYY-MM-DD/$TODAY/g" "$NEW_ADR"
rm "$NEW_ADR.bak"

echo "✅ Created new ADR: $NEW_ADR"
echo ""

# Update README.md if it exists
if [ -f "$README" ]; then
    # Find the line with the table and insert new row after it
    # Look for the last ADR entry and add new one after it
    if grep -q "| \[" "$README"; then
        # Create new table row
        NEW_ROW="| [$NEXT_NUM]($NEXT_NUM-$FILENAME.md) | $TITLE | Proposed | $TODAY |"
        
        # Find the last table row and add new row after it
        awk -v new_row="$NEW_ROW" '
            /^\| \[[0-9]/ { last_table_line = NR; last_line = $0 }
            { lines[NR] = $0 }
            END {
                for (i = 1; i <= NR; i++) {
                    print lines[i]
                    if (i == last_table_line) {
                        print new_row
                    }
                }
            }
        ' "$README" > "$README.tmp"
        mv "$README.tmp" "$README"
        echo "✅ Updated $README with new ADR entry"
    else
        echo "⚠️  Could not automatically update README.md - please add entry manually"
    fi
else
    echo "⚠️  README.md not found - please create it manually"
fi

echo ""
echo "Next steps:"
echo "1. Edit the ADR file: $NEW_ADR"
echo "2. Fill in all sections (Context, Decision, Alternatives, Consequences)"
echo "3. Review the README.md entry"
echo "4. Commit the ADR"
echo ""
echo "Opening file in nvim..."

# Open in nvim
if command -v nvim &> /dev/null; then
    nvim "$NEW_ADR"
else
    echo "⚠️  nvim not found. Please manually edit: $NEW_ADR"
fi
