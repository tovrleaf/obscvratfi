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

# Download poster from URL
download_poster() {
    local url="$1"
    local output_path="$2"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output_path")"
    
    # Download using curl
    if curl -sL "$url" -o "$output_path"; then
        print_success "Downloaded poster to $output_path"
        return 0
    else
        print_error "Failed to download poster from $url"
        return 1
    fi
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
    
    # Event name
    read -rp "Event name (or press Enter to use venue name): " event_name
    
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
    
    # Use event name for slug, fallback to venue
    if [[ -z "$event_name" ]]; then
        event_name="$venue"
        slug_base="$venue"
    else
        slug_base="$event_name"
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
    read -rp "Poster image URL or path (or press Enter to skip): " poster_input
    
    # Handle poster download if URL provided
    poster=""
    if [[ -n "$poster_input" ]]; then
        if [[ "$poster_input" =~ ^https?:// ]]; then
            # It's a URL, download it
            slug=$(echo "$slug_base" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
            poster_dir="website/static/media/gigs/${date}-${slug}"
            poster_path="$poster_dir/poster.jpg"
            
            if download_poster "$poster_input" "$poster_path"; then
                poster="/media/gigs/${date}-${slug}/poster.jpg"
            fi
        else
            # It's a local path, use as-is
            poster="$poster_input"
        fi
    fi
    
    # Event link
    read -rp "Event link URL (or press Enter to skip): " event_url
    if [[ -n "$event_url" ]]; then
        read -rp "Event title: " event_title
    fi
    
    # Other performers
    echo "Other performers (press Enter when done):"
    declare -a performers=()
    while true; do
        read -rp "  Performer name (or press Enter to finish): " performer_name
        if [[ -z "$performer_name" ]]; then
            break
        fi
        read -rp "  Performer URL (or press Enter to skip): " performer_url
        performers+=("$performer_name|$performer_url")
    done
    
    # Generate filename
    slug=$(echo "$slug_base" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    filename="${date}-${slug}.md"
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
title: "$event_name"
date: $date
venue: "$venue"
location: "$city"
description: "$description"
FRONTMATTER
    
    # Replace variables in frontmatter
    sed -i.bak "s/\$event_name/$event_name/g; s/\$venue/$venue/g; s/\$date/$date/g; s/\$city/$city/g; s/\$description/$description/g" "$filepath"
    rm -f "${filepath}.bak"
    
    # Add poster if provided
    if [[ -n "$poster" ]]; then
        echo "poster: \"$poster\"" >> "$filepath"
    fi
    
    # Add event link if provided
    if [[ -n "$event_url" ]]; then
        cat >> "$filepath" << EVENTLINK
event_link:
  url: "$event_url"
  title: "$event_title"
EVENTLINK
    fi
    
    # Add performers if provided
    if [[ ${#performers[@]} -gt 0 ]]; then
        echo "other_performers:" >> "$filepath"
        for performer in "${performers[@]}"; do
            IFS='|' read -r name url <<< "$performer"
            if [[ -n "$url" ]]; then
                cat >> "$filepath" << PERFORMER
  - name: "$name"
    url: "$url"
PERFORMER
            else
                echo "  - name: \"$name\"" >> "$filepath"
            fi
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
    
    # Parse existing values
    local old_title=$(grep "^title:" "$selected_file" | sed 's/title: "\(.*\)"/\1/')
    local old_date=$(grep "^date:" "$selected_file" | sed 's/date: \(.*\)/\1/')
    local old_venue=$(grep "^venue:" "$selected_file" | sed 's/venue: "\(.*\)"/\1/')
    local old_location=$(grep "^location:" "$selected_file" | sed 's/location: "\(.*\)"/\1/')
    local old_description=$(grep "^description:" "$selected_file" | sed 's/description: "\(.*\)"/\1/')
    local old_poster=$(grep "^poster:" "$selected_file" | sed 's/poster: "\(.*\)"/\1/')
    
    # Interactive edit with prefilled values
    echo ""
    print_header "Edit Gig: $old_title"
    echo ""
    
    read -rp "Event name [$old_title]: " event_name
    event_name=${event_name:-$old_title}
    
    read -rp "Date [$old_date]: " date
    date=${date:-$old_date}
    if [[ ! $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        print_error "Invalid date format"
        show_menu
        return
    fi
    
    read -rp "Venue [$old_venue]: " venue
    venue=${venue:-$old_venue}
    
    # Use event name for slug, fallback to venue
    if [[ -z "$event_name" ]] || [[ "$event_name" == "$venue" ]]; then
        slug_base="$venue"
    else
        slug_base="$event_name"
    fi
    
    read -rp "City [$old_location]: " city
    city=${city:-$old_location}
    
    read -rp "Description [$old_description]: " description
    description=${description:-$old_description}
    
    read -rp "Poster [$old_poster]: " poster_input
    poster_input=${poster_input:-$old_poster}
    
    # Handle poster download if URL provided
    poster=""
    if [[ -n "$poster_input" ]]; then
        if [[ "$poster_input" =~ ^https?:// ]]; then
            # It's a URL, download it
            slug=$(echo "$slug_base" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
            poster_dir="website/static/media/gigs/${date}-${slug}"
            poster_path="$poster_dir/poster.jpg"
            
            if download_poster "$poster_input" "$poster_path"; then
                poster="/media/gigs/${date}-${slug}/poster.jpg"
            fi
        else
            # It's a local path, use as-is
            poster="$poster_input"
        fi
    fi
    
    # Event link
    read -rp "Event link URL (or press Enter to skip): " event_url
    if [[ -n "$event_url" ]]; then
        read -rp "Event title: " event_title
    fi
    
    # Other performers
    echo "Other performers (press Enter when done):"
    declare -a performers=()
    while true; do
        read -rp "  Performer name (or press Enter to finish): " performer_name
        if [[ -z "$performer_name" ]]; then
            break
        fi
        read -rp "  Performer URL (or press Enter to skip): " performer_url
        performers+=("$performer_name|$performer_url")
    done
    
    # Generate filename
    slug=$(echo "$slug_base" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    filename="${date}-${slug}.md"
    filepath="$GIGS_DIR/$filename"
    
    # Build updated frontmatter
    cat > "$filepath" << 'FRONTMATTER'
---
title: "$event_name"
date: $date
venue: "$venue"
location: "$city"
description: "$description"
FRONTMATTER
    
    # Replace variables
    sed -i.bak "s/\$event_name/$event_name/g; s/\$venue/$venue/g; s/\$date/$date/g; s/\$city/$city/g; s/\$description/$description/g" "$filepath"
    rm -f "${filepath}.bak"
    
    # Add poster if provided
    if [[ -n "$poster" ]]; then
        echo "poster: \"$poster\"" >> "$filepath"
    fi
    
    # Add event link if provided
    if [[ -n "$event_url" ]]; then
        cat >> "$filepath" << EVENTLINK
event_link:
  url: "$event_url"
  title: "$event_title"
EVENTLINK
    fi
    
    # Add performers if provided
    if [[ ${#performers[@]} -gt 0 ]]; then
        echo "other_performers:" >> "$filepath"
        for performer in "${performers[@]}"; do
            IFS='|' read -r name url <<< "$performer"
            if [[ -n "$url" ]]; then
                cat >> "$filepath" << PERFORMER
  - name: "$name"
    url: "$url"
PERFORMER
            else
                echo "  - name: \"$name\"" >> "$filepath"
            fi
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
    
    # Remove old file if filename changed
    if [[ "$selected_file" != "$filepath" ]]; then
        rm "$selected_file"
        print_success "Updated and renamed: $(basename "$filepath")"
    else
        print_success "Updated: $(basename "$filepath")"
    fi
    
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
