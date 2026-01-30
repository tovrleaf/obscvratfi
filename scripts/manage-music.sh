#!/usr/bin/env bash
# scripts/manage-music.sh - Interactive music release management tool

set -uo pipefail

MUSIC_DIR="website/content/music"
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

# Generate slug from title
generate_slug() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-'
}

# Validate date format
validate_date() {
    if [[ ! $1 =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 1
    fi
    return 0
}

# Validate Bandcamp URL
validate_bandcamp_url() {
    if [[ ! $1 =~ ^https://.*\.bandcamp\.com/.* ]]; then
        return 1
    fi
    return 0
}

# Validate Discogs URL
validate_discogs_url() {
    if [[ ! $1 =~ ^https://www\.discogs\.com/release/.* ]]; then
        return 1
    fi
    return 0
}

# Download/copy cover image
handle_cover() {
    local cover_input="$1"
    local slug="$2"
    
    if [[ -z "$cover_input" ]]; then
        return 0
    fi
    
    local cover_dir="website/static/images/music"
    mkdir -p "$cover_dir"
    
    if [[ "$cover_input" =~ ^https?:// ]]; then
        # Download from URL
        local ext="jpg"
        if [[ "$cover_input" =~ \.(png|jpg|jpeg|gif)$ ]]; then
            ext="${BASH_REMATCH[1]}"
        fi
        local cover_filename="${slug}-cover.${ext}"
        local cover_path="$cover_dir/$cover_filename"
        
        if curl -sL "$cover_input" -o "$cover_path"; then
            print_success "Downloaded cover to $cover_path"
            echo "$cover_filename"
        else
            print_error "Failed to download cover from $cover_input"
            return 1
        fi
    else
        # Copy local file
        if [[ -f "$cover_input" ]]; then
            local ext="${cover_input##*.}"
            local cover_filename="${slug}-cover.${ext}"
            local cover_path="$cover_dir/$cover_filename"
            cp "$cover_input" "$cover_path"
            print_success "Copied cover to $cover_path"
            echo "$cover_filename"
        else
            print_error "Cover file not found: $cover_input"
            return 1
        fi
    fi
}

# Convert comma-separated artists to YAML array
format_artists() {
    local artists_input="$1"
    if [[ -z "$artists_input" ]]; then
        return 0
    fi
    
    echo "artists:"
    IFS=',' read -ra ARTISTS <<< "$artists_input"
    for artist in "${ARTISTS[@]}"; do
        artist=$(echo "$artist" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        echo "  - \"$artist\""
    done
}

# Main menu
show_menu() {
    echo ""
    print_header "Music Release Management"
    echo "1) Add Release"
    echo "2) Edit Release"
    echo "3) Remove Release"
    echo "4) List Releases"
    echo "5) Exit"
    echo ""
    read -rp "Choose an option: " choice || exit 0
    echo ""
    
    case $choice in
        1) add_release ;;
        2) edit_release ;;
        3) remove_release ;;
        4) list_releases ;;
        5) exit 0 ;;
        *) print_error "Invalid option"; show_menu ;;
    esac
}

# Add new release
add_release() {
    print_header "Add New Release"
    
    # Title (required)
    read -rp "Title: " title || true
    if [[ -z "$title" ]]; then
        print_error "Title is required"
        show_menu
        return
    fi
    
    # Date (required, validated)
    read -rp "Date (YYYY-MM-DD): " date || true
    if ! validate_date "$date"; then
        print_error "Invalid date format"
        show_menu
        return
    fi
    
    # Description (multi-line, using $EDITOR)
    local temp_desc=$(mktemp)
    echo "# Enter description below (lines starting with # are ignored)" > "$temp_desc"
    ${EDITOR:-vim} "$temp_desc"
    description=$(grep -v '^#' "$temp_desc" | sed '/^$/d')
    rm "$temp_desc"
    
    # Release type
    echo "Release type:"
    echo "1) album"
    echo "2) compilation"
    read -rp "Choose (1-2): " type_choice || type_choice="1"
    case $type_choice in
        1) release_type="album" ;;
        2) release_type="compilation" ;;
        *) release_type="album" ;;
    esac
    
    # Artists (comma-separated)
    read -rp "Artists (comma-separated): " artists_input || true
    
    # Label (required)
    read -rp "Label: " label || true
    if [[ -z "$label" ]]; then
        print_error "Label is required"
        show_menu
        return
    fi
    
    # Label URL (optional)
    read -rp "Label URL (optional): " label_url || true
    
    # Format
    read -rp "Format (e.g., 'Digital Album, 3 tracks'): " format || true
    
    # Country
    read -rp "Country: " country || true
    
    # Cover image
    read -rp "Cover image (URL or local path, optional): " cover_input || true
    
    # Bandcamp album ID
    read -rp "Bandcamp album ID: " bandcamp_album || true
    
    # Bandcamp URL
    read -rp "Bandcamp URL: " bandcamp_url || true
    if [[ -n "$bandcamp_url" ]] && ! validate_bandcamp_url "$bandcamp_url"; then
        print_error "Invalid Bandcamp URL format"
        show_menu
        return
    fi
    
    # Discogs URL
    read -rp "Discogs URL (optional): " discogs_url || true
    if [[ -n "$discogs_url" ]] && ! validate_discogs_url "$discogs_url"; then
        print_error "Invalid Discogs URL format"
        show_menu
        return
    fi
    
    # Generate slug and filename
    slug=$(generate_slug "$title")
    filename="${slug}.md"
    filepath="$MUSIC_DIR/$filename"
    
    # Check if file exists
    if [[ -f "$filepath" ]]; then
        print_error "Release already exists: $filename"
        read -rp "Overwrite? (y/N): " overwrite || overwrite="n"
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            show_menu
            return
        fi
    fi
    
    # Handle cover image
    cover=""
    if [[ -n "$cover_input" ]]; then
        cover=$(handle_cover "$cover_input" "$slug")
    fi
    
    # Create the file
    {
        echo "---"
        echo "title: \"$title\""
        echo "date: $date"
        echo "release_type: \"$release_type\""
        
        if [[ -n "$artists_input" ]]; then
            format_artists "$artists_input"
        fi
        
        echo "label: \"$label\""
        
        if [[ -n "$label_url" ]]; then
            echo "label_url: \"$label_url\""
        fi
        
        if [[ -n "$format" ]]; then
            echo "format: \"$format\""
        fi
        
        if [[ -n "$country" ]]; then
            echo "country: \"$country\""
        fi
        
        if [[ -n "$cover" ]]; then
            echo "cover: \"$cover\""
        fi
        
        if [[ -n "$bandcamp_album" ]]; then
            echo "bandcamp_album: \"$bandcamp_album\""
        fi
        
        if [[ -n "$bandcamp_url" ]]; then
            echo "bandcamp_url: \"$bandcamp_url\""
        fi
        
        if [[ -n "$discogs_url" ]]; then
            echo "discogs_url: \"$discogs_url\""
        fi
        
        echo "draft: false"
        echo "---"
        echo ""
        echo "$description"
    } > "$filepath"
    
    print_success "Created release: $filename"
    show_menu
}

# Edit existing release
edit_release() {
    print_header "Edit Release"
    
    if [[ ! -d "$MUSIC_DIR" ]] || [[ -z "$(ls -A "$MUSIC_DIR" 2>/dev/null)" ]]; then
        print_warning "No releases found"
        show_menu
        return
    fi
    
    # List releases with numbers
    echo ""
    local -a files=()
    local count=1
    for file in "$MUSIC_DIR"/*.md; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
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
    read -rp "Select release number (or 0 to cancel): " selection || true
    
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
    
    print_success "Opening $selected_file in editor"
    ${EDITOR:-vim} "$selected_file"
    
    show_menu
}

# Remove release
remove_release() {
    print_header "Remove Release"
    
    if [[ ! -d "$MUSIC_DIR" ]] || [[ -z "$(ls -A "$MUSIC_DIR" 2>/dev/null)" ]]; then
        print_warning "No releases found"
        show_menu
        return
    fi
    
    # List releases with numbers
    echo ""
    local -a files=()
    local count=1
    for file in "$MUSIC_DIR"/*.md; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
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
    read -rp "Select release number to delete (or 0 to cancel): " selection || true
    
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
    else
        print_warning "Cancelled"
    fi
    
    show_menu
}

# List all releases
list_releases() {
    print_header "All Releases"
    
    if [[ ! -d "$MUSIC_DIR" ]] || [[ -z "$(ls -A "$MUSIC_DIR" 2>/dev/null)" ]]; then
        print_warning "No releases found"
        show_menu
        return
    fi
    
    echo ""
    local count=1
    for file in "$MUSIC_DIR"/*.md; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            if [[ "$filename" == "_index.md" ]]; then
                continue
            fi
            
            title=$(grep "^title:" "$file" | sed 's/title: "\(.*\)"/\1/')
            date=$(grep "^date:" "$file" | sed 's/date: \(.*\)/\1/')
            label=$(grep "^label:" "$file" | sed 's/label: "\(.*\)"/\1/')
            
            echo -e "${GREEN}$count)${NC} $date - $title"
            echo "   Label: $label"
            echo "   File: $filename"
            echo ""
            ((count++))
        fi
    done
    
    read -rp "Press Enter to continue..."
    show_menu
}

# Create music directory if it doesn't exist
mkdir -p "$MUSIC_DIR"

# Start
show_menu