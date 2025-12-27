#!/bin/bash

# Script to list all ADRs with their status
# Usage: ./scripts/list-adrs.sh [status]

ADR_DIR="docs/adr"

# Check if ADR directory exists
if [ ! -d "$ADR_DIR" ]; then
    echo "Error: ADR directory not found at $ADR_DIR"
    exit 1
fi

# Filter by status if provided
FILTER_STATUS="$1"

echo "📋 Architecture Decision Records"
echo "================================"
echo ""

# Find all ADR files (numbered)
for adr_file in $(ls -1 "$ADR_DIR" | grep -E '^[0-9]{4}-.*\.md$' | sort); do
    ADR_PATH="$ADR_DIR/$adr_file"
    
    # Extract status from the file
    STATUS=$(grep -m 1 "^\*\*Status:\*\*" "$ADR_PATH" | sed 's/\*\*Status:\*\* //' | sed 's/\[//' | sed 's/\]//' | awk '{print $1}')
    
    # Extract title (first heading)
    TITLE=$(grep -m 1 "^# " "$ADR_PATH" | sed 's/^# //')
    
    # Extract date
    DATE=$(grep -m 1 "^\*\*Date:\*\*" "$ADR_PATH" | sed 's/\*\*Date:\*\* //')
    
    # Apply filter if provided
    if [ -n "$FILTER_STATUS" ] && [ "$STATUS" != "$FILTER_STATUS" ]; then
        continue
    fi
    
    # Color code by status
    case "$STATUS" in
        Accepted)
            STATUS_DISPLAY="✅ $STATUS"
            ;;
        Proposed)
            STATUS_DISPLAY="🤔 $STATUS"
            ;;
        Deprecated)
            STATUS_DISPLAY="⚠️  $STATUS"
            ;;
        Superseded)
            STATUS_DISPLAY="🔄 $STATUS"
            ;;
        *)
            STATUS_DISPLAY="❓ $STATUS"
            ;;
    esac
    
    echo "$TITLE"
    echo "   Status: $STATUS_DISPLAY"
    echo "   Date: $DATE"
    echo "   File: $adr_file"
    echo ""
done

# Summary
TOTAL=$(ls -1 "$ADR_DIR" | grep -E '^[0-9]{4}-.*\.md$' | wc -l | tr -d ' ')
echo "================================"
echo "Total ADRs: $TOTAL"

if [ -n "$FILTER_STATUS" ]; then
    FILTERED=$(ls -1 "$ADR_DIR" | grep -E '^[0-9]{4}-.*\.md$' | while read f; do grep -m 1 "^\*\*Status:\*\*.*$FILTER_STATUS" "$ADR_DIR/$f" > /dev/null && echo "$f"; done | wc -l | tr -d ' ')
    echo "Filtered ($FILTER_STATUS): $FILTERED"
fi
