#!/usr/bin/env bash
# scripts/manage-gigs.sh - Interactive gig management tool

set -euo pipefail

GIGS_DIR="website/content/gigs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Main menu
show_menu() {
    echo ""
    print_header "Gig Management"
    echo "1) Create new gig"
    echo "2) List all gigs"
    echo "3) Edit existing gig"
    echo "4) Delete gig"
    echo "5) Exit"
    echo ""
    read -rp "Choose an option: " choice
    echo ""
    
    case $choice in
        1) create_gig ;;
        2) list_gigs ;;
        3) edit_gig ;;
        4) delete_gig ;;
        5) exit 0 ;;
        *) print_error "Invalid option"; show_menu ;;
    esac
}

# Create new gig
create_gig() {
    print_header "Create New Gig"
    
    # Gig name
    read -rp "Gig name: " gig_name
    if [[ -z "$gig_name" ]]; then
        print_error "Gig name is required"
        show_menu
        return
    fi
    
    # Date
    read -rp "Date (YYYY-MM-DD): " date
    if [[ ! $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        print_error "Invalid date format"
        show_menu
        return
    fi
    
    # Venue
    read -rp "Venue name: " venue
    if [[ -z "$venue" ]]; then
        print_error "Venue name is required"
        show_menu
        return
    fi
    
    # City
    read -rp "City: " city
    if [[ -z "$city" ]]; then
        print_error "City is required"
        show_menu
        return
    fi
    
    # Description
    read -rp "Description: " description
    
    # Poster
    read -rp "Poster image path (or press Enter to skip): " poster
    
    # Event page link
    read -rp "Event page link (or press Enter to skip): " event_link
    
    # Other performers
    echo "Other performers (comma-separated, or press Enter to skip): "
    read -r performers_input
    
    # Ticket link
    read -rp "Ticket link (or press Enter to skip): " ticket_link
    
    # Generate filename
    venue_slug=$(echo "$venue" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    filename="${date}-${venue_slug}.md"
    filepath="$GIGS_DIR/$filename"
    
    # Check if file exists
    if [[ -f "$filepath" ]]; then
        print_error "Gig already exists: $filename"
        read -rp "Overwrite? (y/N): " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            show_menu
            return
        fi
    fi
    
    # Build frontmatter
    cat > "$filepath" << 'FRONTMATTER'
---
title: "$gig_name"
date: $date
venue: "$venue"
location: "$city"
description: "$description"
FRONTMATTER
    
    # Replace variables in frontmatter
    sed -i.bak "s/\$gig_name/$gig_name/g; s/\$venue/$venue/g; s/\$date/$date/g; s/\$city/$city/g; s/\$description/$description/g" "$filepath"
    rm -f "${filepath}.bak"
    
    # Add poster if provided
    if [[ -n "$poster" ]]; then
        echo "poster: \"$poster\"" >> "$filepath"
    fi
    
    # Add optional fields
    if [[ -n "$event_link" ]] || [[ -n "$ticket_link" ]]; then
        echo "links:" >> "$filepath"
        if [[ -n "$event_link" ]]; then
            cat >> "$filepath" << EVENTLINK
  - url: "$event_link"
    text: "Event page"
EVENTLINK
        fi
        if [[ -n "$ticket_link" ]]; then
            cat >> "$filepath" << TICKETLINK
  - url: "$ticket_link"
    text: "Buy tickets"
TICKETLINK
        fi
    fi
    
    if [[ -n "$performers_input" ]]; then
        echo "other_performers:" >> "$filepath"
        IFS=',' read -ra PERFORMERS <<< "$performers_input"
        for performer in "${PERFORMERS[@]}"; do
            performer=$(echo "$performer" | xargs) # trim whitespace
            echo "  - \"$performer\"" >> "$filepath"
        done
    fi
    
    # Close frontmatter and add body
    cat >> "$filepath" << 'BODY'
draft: false
---

$description
BODY
    sed -i.bak "s/\$description/$description/g" "$filepath"
    rm -f "${filepath}.bak"
    
    print_success "Created gig: $filename"
    read -rp "Open in editor? (y/N): " open_editor
    if [[ "$open_editor" =~ ^[Yy]$ ]]; then
        ${EDITOR:-vim} "$filepath"
    fi
    
    show_menu
}

# List all gigs
list_gigs() {
    print_header "All Gigs"
    
    if [[ ! -d "$GIGS_DIR" ]] || [[ -z "$(ls -A "$GIGS_DIR" 2>/dev/null)" ]]; then
        print_warning "No gigs found"
        show_menu
        return
    fi
    
    echo ""
    local count=1
    for file in "$GIGS_DIR"/*.md; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            # Skip _index.md files
            if [[ "$filename" == "_index.md" ]]; then
                continue
            fi
            # Extract date and title from filename
            date_part=$(echo "$filename" | cut -d'-' -f1-3)
            title=$(grep "^title:" "$file" | sed 's/title: "\(.*\)"/\1/')
            location=$(grep "^location:" "$file" | sed 's/location: "\(.*\)"/\1/')
            
            echo -e "${GREEN}$count)${NC} $date_part - $title ($location)"
            echo "   File: $filename"
            echo ""
            ((count++))
        fi
    done
    
    read -rp "Press Enter to continue..."
    show_menu
}

# Edit existing gig
edit_gig() {
    print_header "Edit Gig"
    
    if [[ ! -d "$GIGS_DIR" ]] || [[ -z "$(ls -A "$GIGS_DIR" 2>/dev/null)" ]]; then
        print_warning "No gigs found"
        show_menu
        return
    fi
    
    # List gigs with numbers
    echo ""
    local -a files=()
    local count=1
    for file in "$GIGS_DIR"/*.md; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            # Skip _index.md files
            if [[ "$filename" == "_index.md" ]]; then
                continue
            fi
            files+=("$file")
            title=$(grep "^title:" "$file" | sed 's/title: "\(.*\)"/\1/')
            echo -e "${GREEN}$count)${NC} $filename - $title"
            ((count++))
        fi
    done
    
    echo ""
    read -rp "Select gig number (or 0 to cancel): " selection
    
    if [[ "$selection" == "0" ]]; then
        show_menu
        return
    fi
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#files[@]}" ]]; then
        print_error "Invalid selection"
        show_menu
        return
    fi
    
    selected_file="${files[$((selection-1))]}"
    ${EDITOR:-vim} "$selected_file"
    print_success "Edited: $(basename "$selected_file")"
    
    show_menu
}

# Delete gig
delete_gig() {
    print_header "Delete Gig"
    
    if [[ ! -d "$GIGS_DIR" ]] || [[ -z "$(ls -A "$GIGS_DIR" 2>/dev/null)" ]]; then
        print_warning "No gigs found"
        show_menu
        return
    fi
    
    # List gigs with numbers
    echo ""
    local -a files=()
    local count=1
    for file in "$GIGS_DIR"/*.md; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            # Skip _index.md files
            if [[ "$filename" == "_index.md" ]]; then
                continue
            fi
            files+=("$file")
            filename=$(basename "$file")
            title=$(grep "^title:" "$file" | sed 's/title: "\(.*\)"/\1/')
            echo -e "${GREEN}$count)${NC} $filename - $title"
            ((count++))
        fi
    done
    
    echo ""
    read -rp "Select gig number to delete (or 0 to cancel): " selection
    
    if [[ "$selection" == "0" ]]; then
        show_menu
        return
    fi
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#files[@]}" ]]; then
        print_error "Invalid selection"
        show_menu
        return
    fi
    
    selected_file="${files[$((selection-1))]}"
    filename=$(basename "$selected_file")
    
    print_warning "About to delete: $filename"
    read -rp "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm "$selected_file"
        print_success "Deleted: $filename"
    else
        print_warning "Cancelled"
    fi
    
    show_menu
}

# Create gigs directory if it doesn't exist
mkdir -p "$GIGS_DIR"

# Start
show_menu
