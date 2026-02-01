#!/usr/bin/env bash
# scripts/manage-live.sh - Interactive live performance management tool

set -uo pipefail

LIVE_DIR="website/data/live"
CONTENT_DIR="website/content/live"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "Error: yq is not installed"
    echo "Install with: brew install yq"
    exit 1
fi

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
    print_header "Live Performance Management"
    echo "1) Create new live performance"
    echo "2) List all live performances"
    echo "3) Edit existing live performance"
    echo "4) Delete live performance"
    echo "5) Exit"
    echo ""
    read -rp "Choose an option: " choice || exit 0
    echo ""
    
    case $choice in
        1) create_live ;;
        2) list_live ;;
        3) edit_live ;;
        4) delete_live ;;
        5) exit 0 ;;
        *) print_error "Invalid option"; show_menu ;;
    esac
}

# Create new live performance
create_live() {
    print_header "Create New Live Performance"
    
    # Event name
    read -rp "Event name (or press Enter to use venue name): " event_name || true
    
    # Date
    read -rp "Date (YYYY-MM-DD): " date || true
    if [[ ! $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        print_error "Invalid date format"
        show_menu
        return
    fi
    
    # Venue
    read -rp "Venue name: " venue || true
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
    read -rp "City: " city || true
    if [[ -z "$city" ]]; then
        print_error "City is required"
        show_menu
        return
    fi
    
    # Description
    echo "Description (enter text, then type END on a new line and press Enter):"
    description=""
    while IFS= read -r line; do
        if [[ "$line" == "END" ]]; then
            break
        fi
        if [[ -n "$description" ]]; then
            description+=$'\n'
        fi
        description+="$line"
    done
    
    # Poster
    read -rp "Poster image URL or path (or press Enter to skip): " poster_input || true
    
    # Handle poster download if URL provided
    poster=""
    if [[ -n "$poster_input" ]]; then
        slug=$(echo "$slug_base" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
        poster_dir="website/assets/media/gigs/${date}-${slug}"
        mkdir -p "$poster_dir"
        
        if [[ "$poster_input" =~ ^https?:// ]]; then
            # It's a URL, download it
            poster_filename="obscvrat-${slug}-poster-${date%%%-*}.jpg"
            poster_path="$poster_dir/$poster_filename"
            
            if download_poster "$poster_input" "$poster_path"; then
                poster="$poster_filename"
            fi
        else
            # It's a local path, copy and rename it
            if [[ -f "$poster_input" ]]; then
                poster_filename="obscvrat-${slug}-poster-${date%%%-*}.jpg"
                poster_path="$poster_dir/$poster_filename"
                cp "$poster_input" "$poster_path"
                poster="$poster_filename"
                print_success "Copied poster to $poster_path"
            else
                print_error "Poster file not found: $poster_input"
            fi
        fi
    fi
    # Event link
    read -rp "Event link URL (or press Enter to skip): " event_url || true
    
    # Other performers
    echo "Other performers (press Enter when done):"
    declare -a performers=()
    while true; do
        read -rp "  Performer name (or press Enter to finish): " performer_name || break
        if [[ -z "$performer_name" ]]; then
            break
        fi
        read -rp "  Performer URL (or press Enter to skip): " performer_url || performer_url=""
        performers+=("$performer_name|$performer_url")
    done
    
    # Generate filename
    slug=$(echo "$slug_base" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    filename="${date}-${slug}.yaml"
    filepath="$LIVE_DIR/$filename"
    
    # Check if file exists
    if [[ -f "$filepath" ]]; then
        print_error "Live performance already exists: $filename"
        read -rp "Overwrite? (y/N): " overwrite || overwrite="n"
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            show_menu
            return
        fi
    fi
    
    # Build frontmatter
    {
        echo "---"
        echo "title: \"$event_name\""
        echo "date: $date"
        echo "venue: \"$venue\""
        echo "location: \"$city\""
        
        # Add poster if provided
        if [[ -n "$poster" ]]; then
            echo "poster: \"$poster\""
        fi
        
        # Add event link if provided
        if [[ -n "$event_url" ]]; then
            echo "event_link: \"$event_url\""
        fi
        
        # Add performers if provided
        if [[ ${#performers[@]} -gt 0 ]]; then
            echo "other_performers:"
            for performer in "${performers[@]}"; do
                IFS='|' read -r name url <<< "$performer"
                if [[ -n "$url" ]]; then
                    echo "  - name: \"$name\""
                    echo "    url: \"$url\""
                else
                    echo "  - name: \"$name\""
                fi
            done
        fi
        
        echo "draft: false"
        echo "---"
        echo ""
        echo "$description"
    } > "$filepath"
    
    print_success "Created live performance: $filename"
    
    # Generate markdown from YAML
    print_warning "Generating markdown..."
    "$SCRIPT_DIR/generate-markdown.sh" live
    read -rp "Open in editor? (y/N): " open_editor || open_editor="n"
    if [[ "$open_editor" =~ ^[Yy]$ ]]; then
        ${EDITOR:-vim} "$filepath"
    fi
    
    show_menu
}

# List all live performances
list_live() {
    print_header "All Gigs"
    
    if [[ ! -d "$LIVE_DIR" ]] || [[ -z "$(ls -A "$LIVE_DIR" 2>/dev/null)" ]]; then
        print_warning "No live performances found"
        show_menu
        return
    fi
    
    echo ""
    local count=1
    for file in "$LIVE_DIR"/*.yaml; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            # Skip _index.md files
            if [[ "$filename" == "_index.md" ]]; then
                continue
            fi
            # Extract date and title from filename
            date_part=$(echo "$filename" | cut -d'-' -f1-3)
            title=$(yq eval '.title' "$file")
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

# Edit existing live performance
edit_live() {
    print_header "Edit Live Performance"
    
    if [[ ! -d "$LIVE_DIR" ]] || [[ -z "$(ls -A "$LIVE_DIR" 2>/dev/null)" ]]; then
        print_warning "No live performances found"
        show_menu
        return
    fi
    
    # List gigs with numbers
    echo ""
    local -a files=()
    local count=1
    for file in "$LIVE_DIR"/*.yaml; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            # Skip _index.md files
            if [[ "$filename" == "_index.md" ]]; then
                continue
            fi
            files+=("$file")
            title=$(yq eval '.title' "$file")
            echo -e "${GREEN}$count)${NC} $filename - $title"
            ((count++))
        fi
    done
    
    echo ""
    read -rp "Select live performance number (or 0 to cancel): " selection || true
    
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
    
    # Parse existing values using yq
    local old_title=$(yq eval '.title' "$selected_file")
    local old_date=$(yq eval '.date' "$selected_file")
    local old_venue=$(yq eval '.venue' "$selected_file")
    local old_location=$(yq eval '.location' "$selected_file")
    local old_description=$(yq eval '.description // ""' "$selected_file")
    local old_poster=$(yq eval '.poster // ""' "$selected_file")
    
    # Interactive edit with prefilled values
    echo ""
    print_header "Edit Live Performance: $old_title"
    echo ""
    
    read -rp "Event name [$old_title]: " event_name || true
    event_name=${event_name:-$old_title}
    
    read -rp "Date [$old_date]: " date || true
    date=${date:-$old_date}
    if [[ ! $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        print_error "Invalid date format"
        show_menu
        return
    fi
    
    read -rp "Venue [$old_venue]: " venue || true
    venue=${venue:-$old_venue}
    
    # Use event name for slug, fallback to venue
    if [[ -z "$event_name" ]] || [[ "$event_name" == "$venue" ]]; then
        slug_base="$venue"
    else
        slug_base="$event_name"
    fi
    
    read -rp "City [$old_location]: " city || true
    city=${city:-$old_location}
    
    echo "Description (current: ${old_description:0:50}...) - type END on a new line to finish, or just END to keep current:"
    description=""
    while IFS= read -r line; do
        if [[ "$line" == "END" ]]; then
            break
        fi
        if [[ -n "$description" ]]; then
            description+=$'\n'
        fi
        description+="$line"
    done
    # If empty, keep old description
    if [[ -z "$description" ]]; then
        description="$old_description"
    fi
    
    read -rp "Poster [$old_poster]: " poster_input || true
    poster_input=${poster_input:-$old_poster}
    
    # Handle poster download if URL provided
    poster=""
    if [[ -n "$poster_input" ]]; then
        slug=$(echo "$slug_base" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
        poster_dir="website/assets/media/gigs/${date}-${slug}"
        mkdir -p "$poster_dir"
        
        if [[ "$poster_input" =~ ^https?:// ]]; then
            # It's a URL, download it
            poster_filename="obscvrat-${slug}-poster-${date%%%-*}.jpg"
            poster_path="$poster_dir/$poster_filename"
            
            if download_poster "$poster_input" "$poster_path"; then
                poster="$poster_filename"
            fi
        else
            # It's a local path, copy and rename it
            if [[ -f "$poster_input" ]]; then
                poster_filename="obscvrat-${slug}-poster-${date%%%-*}.jpg"
                poster_path="$poster_dir/$poster_filename"
                cp "$poster_input" "$poster_path"
                poster="$poster_filename"
                print_success "Copied poster to $poster_path"
            else
                print_error "Poster file not found: $poster_input"
            fi
        fi
    fi
    # Event link
    read -rp "Event link URL (or press Enter to skip): " event_url || true
    
    # Other performers - parse existing
    echo ""
    echo "Other performers:"
    declare -a performers=()
    local performer_count=0
    
    # Parse existing performers from file
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]name:[[:space:]]*\"(.*)\" ]]; then
            local perf_name="${BASH_REMATCH[1]}"
            # Read next line for URL
            read -r next_line
            local perf_url=""
            if [[ "$next_line" =~ url:[[:space:]]*\"(.*)\" ]]; then
                perf_url="${BASH_REMATCH[1]}"
            fi
            performers+=("$perf_name|$perf_url")
            ((performer_count++))
            echo "  $performer_count) $perf_name${perf_url:+ ($perf_url)}"
        fi
    done < "$selected_file"
    
    if [[ $performer_count -eq 0 ]]; then
        echo "  (none)"
    fi
    
    echo ""
    echo "1) Add performer"
    echo "2) Remove performer"
    echo "3) Keep as is"
    read -rp "Choose action: " perf_action || perf_action="3"
    
    case $perf_action in
        1)
            # Add performer
            while true; do
                read -rp "  Performer name (or press Enter to finish): " performer_name || break
                if [[ -z "$performer_name" ]]; then
                    break
                fi
                read -rp "  Performer URL (or press Enter to skip): " performer_url || performer_url=""
                performers+=("$performer_name|$performer_url")
            done
            ;;
        2)
            # Remove performer
            if [[ $performer_count -gt 0 ]]; then
                read -rp "Enter performer number to remove: " remove_num || remove_num=""
                if [[ "$remove_num" =~ ^[0-9]+$ ]] && [[ "$remove_num" -ge 1 ]] && [[ "$remove_num" -le $performer_count ]]; then
                    unset 'performers[$((remove_num-1))]'
                    performers=("${performers[@]}")  # Re-index array
                fi
            fi
            ;;
        3|*)
            # Keep as is
            ;;
    esac
    
    # Generate filename
    slug=$(echo "$slug_base" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    filename="${date}-${slug}.yaml"
    filepath="$LIVE_DIR/$filename"
    
    # Build updated frontmatter
    {
        echo "---"
        echo "title: \"$event_name\""
        echo "date: $date"
        echo "venue: \"$venue\""
        echo "location: \"$city\""
        
        # Add poster if provided
        if [[ -n "$poster" ]]; then
            echo "poster: \"$poster\""
        fi
        
        # Add event link if provided
        if [[ -n "$event_url" ]]; then
            echo "event_link: \"$event_url\""
        fi
        
        # Add performers if provided
        if [[ ${#performers[@]} -gt 0 ]]; then
            echo "other_performers:"
            for performer in "${performers[@]}"; do
                IFS='|' read -r name url <<< "$performer"
                if [[ -n "$url" ]]; then
                    echo "  - name: \"$name\""
                    echo "    url: \"$url\""
                else
                    echo "  - name: \"$name\""
                fi
            done
        fi
        
        echo "draft: false"
        echo "---"
        echo ""
        echo "$description"
    } > "$filepath"
    
    # Remove old file if filename changed
    if [[ "$selected_file" != "$filepath" ]]; then
        rm "$selected_file"
        print_success "Updated and renamed: $(basename "$filepath")"
    
    # Generate markdown from YAML
    print_warning "Generating markdown..."
    "$SCRIPT_DIR/generate-markdown.sh" live
    else
        print_success "Updated: $(basename "$filepath")"
    
    # Generate markdown from YAML
    print_warning "Generating markdown..."
    "$SCRIPT_DIR/generate-markdown.sh" live
    fi
    
    show_menu
}

# Delete live performance
delete_live() {
    print_header "Delete Live Performance"
    
    if [[ ! -d "$LIVE_DIR" ]] || [[ -z "$(ls -A "$LIVE_DIR" 2>/dev/null)" ]]; then
        print_warning "No live performances found"
        show_menu
        return
    fi
    
    # List gigs with numbers
    echo ""
    local -a files=()
    local count=1
    for file in "$LIVE_DIR"/*.yaml; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            # Skip _index.md files
            if [[ "$filename" == "_index.md" ]]; then
                continue
            fi
            files+=("$file")
            filename=$(basename "$file")
            title=$(yq eval '.title' "$file")
            echo -e "${GREEN}$count)${NC} $filename - $title"
            ((count++))
        fi
    done
    
    echo ""
    read -rp "Select live performance number to delete (or 0 to cancel): " selection || true
    
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
    read -rp "Are you sure? (y/N): " confirm || confirm="n"
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm "$selected_file"
        print_success "Deleted: $filename"
    
    # Generate markdown from YAML
    print_warning "Generating markdown..."
    "$SCRIPT_DIR/generate-markdown.sh" live
    else
        print_warning "Cancelled"
    fi
    
    show_menu
}

# Create gigs directory if it doesn't exist
mkdir -p "$LIVE_DIR"

# Start
show_menu
