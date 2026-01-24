#!/usr/bin/env bash
# scripts/manage-media.sh - Interactive media management tool

set -euo pipefail

GIGS_DIR="website/content/gigs"
MEDIA_DIR="website/assets/media"
OTHERS_FILE="website/content/media/others.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Download file from URL
download_file() {
    local url="$1"
    local output_path="$2"
    
    mkdir -p "$(dirname "$output_path")"
    
    if curl -sL "$url" -o "$output_path"; then
        print_success "Downloaded to $output_path"
        return 0
    else
        print_error "Failed to download from $url"
        return 1
    fi
}

# Generate image versions (thumbnail, display, original)
generate_image_versions() {
    local source_file="$1"
    local base_name="$2"
    local output_dir="$3"
    
    local base="${base_name%.*}"
    local ext="${base_name##*.}"
    
    # Copy original file (Hugo will handle responsive image generation)
    cp "$source_file" "$output_dir/${base_name}"
    print_success "Saved: ${base_name} (Hugo will generate responsive versions)"
    
    return 0
}

# Main menu
show_menu() {
    echo ""
    print_header "Media Management"
    echo "1) Add pictures to gig"
    echo "2) Add video to gig"
    echo "3) Add standalone picture"
    echo "4) Add standalone video"
    echo "5) Add to Others (interview, mention, review)"
    echo "6) List media"
    echo "7) Exit"
    echo ""
    read -rp "Choose an option: " choice
    echo ""
    
    case $choice in
        1) add_pictures ;;
        2) add_video ;;
        3) add_standalone_picture ;;
        4) add_standalone_video ;;
        5) add_others ;;
        6) list_media ;;
        7) exit 0 ;;
        *) print_error "Invalid option"; show_menu ;;
    esac
}

# Add pictures to gig
add_pictures() {
    print_header "Add Pictures to Gig"
    
    # List gigs
    if [[ ! -d "$GIGS_DIR" ]] || [[ -z "$(ls -A "$GIGS_DIR" 2>/dev/null)" ]]; then
        print_warning "No gigs found"
        show_menu
        return
    fi
    
    echo ""
    local -a files=()
    local count=1
    for file in "$GIGS_DIR"/*.md; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            if [[ "$filename" == "_index.md" ]]; then
                continue
            fi
            files+=("$file")
            title=$(grep "^title:" "$file" | sed 's/title: "\(.*\)"/\1/')
            date=$(grep "^date:" "$file" | sed 's/date: \(.*\)/\1/')
            echo -e "${GREEN}$count)${NC} $date - $title"
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
    
    # Get photographer name and URL
    read -rp "Photographer name: " photographer
    read -rp "Photographer URL (optional): " photographer_url
    
    # Get gig slug from filename
    gig_slug=$(basename "$selected_file" .md)
    media_dir="website/static/media/gigs/$gig_slug"
    mkdir -p "$media_dir"
    
    # Add pictures
    echo "Add picture URLs or paths (press Enter when done):"
    declare -a pictures=()
    local pic_counter=1
    while true; do
        read -rp "  Picture URL or path (or press Enter to finish): " pic_input
        if [[ -z "$pic_input" ]]; then
            break
        fi
        
        # Generate descriptive filename: obscvrat-{gig-slug}-performance-{counter}.jpg
        local ext="jpg"
        if [[ "$pic_input" =~ \.(png|gif|jpeg)$ ]]; then
            ext="${BASH_REMATCH[1]}"
        fi
        descriptive_name="obscvrat-${gig_slug}-performance-${pic_counter}.${ext}"
        
        # Get original filename or generate one
        if [[ "$pic_input" =~ ^https?:// ]]; then
            temp_file="/tmp/temp-pic-${pic_counter}.${ext}"
            
            if download_file "$pic_input" "$temp_file"; then
                if generate_image_versions "$temp_file" "$descriptive_name" "$media_dir"; then
                    pictures+=("$descriptive_name")
                    rm "$temp_file"
                fi
            fi
        else
            # Local file
            if generate_image_versions "$pic_input" "$descriptive_name" "$media_dir"; then
                pictures+=("$descriptive_name")
            fi
        fi
        ((pic_counter++))
    done
    
    if [[ ${#pictures[@]} -eq 0 ]]; then
        print_warning "No pictures added"
        show_menu
        return
    fi
    
    # Update gig frontmatter
    # Check if media section exists
    if grep -q "^media:" "$selected_file"; then
        # Media section exists, update it
        print_warning "Media section already exists. Manual edit required."
        echo "Pictures added to $media_dir:"
        for pic in "${pictures[@]}"; do
            echo "  - $pic"
        done
    else
        # Build media section
        media_section="media:\n  pictures:\n    author: \"$photographer\""
        if [[ -n "$photographer_url" ]]; then
            media_section="$media_section\n    author_url: \"$photographer_url\""
        fi
        media_section="$media_section\n    images:"
        for pic in "${pictures[@]}"; do
            media_section="$media_section\n      - $pic"
        done
        
        # Insert before draft line using awk
        awk -v media="$media_section" '/^draft:/ {printf "%s\n", media} {print}' "$selected_file" > "${selected_file}.tmp"
        mv "${selected_file}.tmp" "$selected_file"
        print_success "Added ${#pictures[@]} pictures to gig"
    fi
    
    show_menu
}

# Add video to gig
add_video() {
    print_header "Add Video to Gig"
    
    # List gigs
    if [[ ! -d "$GIGS_DIR" ]] || [[ -z "$(ls -A "$GIGS_DIR" 2>/dev/null)" ]]; then
        print_warning "No gigs found"
        show_menu
        return
    fi
    
    echo ""
    local -a files=()
    local count=1
    for file in "$GIGS_DIR"/*.md; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            if [[ "$filename" == "_index.md" ]]; then
                continue
            fi
            files+=("$file")
            title=$(grep "^title:" "$file" | sed 's/title: "\(.*\)"/\1/')
            date=$(grep "^date:" "$file" | sed 's/date: \(.*\)/\1/')
            echo -e "${GREEN}$count)${NC} $date - $title"
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
    
    # Get YouTube URL and title
    read -rp "YouTube URL: " youtube_url
    read -rp "Video title: " video_title
    
    # Extract YouTube ID
    youtube_id=""
    if [[ "$youtube_url" =~ youtube\.com/watch\?v=([^&]+) ]]; then
        youtube_id="${BASH_REMATCH[1]}"
    elif [[ "$youtube_url" =~ youtu\.be/([^?]+) ]]; then
        youtube_id="${BASH_REMATCH[1]}"
    else
        print_error "Invalid YouTube URL"
        show_menu
        return
    fi
    
    # Collect credits
    echo ""
    echo "Add credits (press Enter on credit type to finish):"
    declare -a credits=()
    while true; do
        read -rp "  Credit type (e.g., Recorded, Mastered, Artwork): " credit_type
        if [[ -z "$credit_type" ]]; then
            break
        fi
        read -rp "  Name: " credit_name
        read -rp "  URL (optional, press Enter to skip): " credit_url
        
        if [[ -n "$credit_url" ]]; then
            credits+=("$credit_type|$credit_name|$credit_url")
        else
            credits+=("$credit_type|$credit_name|")
        fi
        echo ""
    done
    
    # Update gig frontmatter
    if grep -q "^media:" "$selected_file"; then
        # Media section exists, check if videos subsection exists
        if grep -q "^  videos:" "$selected_file"; then
            print_warning "Videos section already exists. Manual edit required."
            echo "Add this to the videos list:"
            echo "    - youtube_id: \"$youtube_id\""
            echo "      title: \"$video_title\""
            if [[ ${#credits[@]} -gt 0 ]]; then
                echo "      credits:"
                for credit in "${credits[@]}"; do
                    IFS='|' read -r type name url <<< "$credit"
                    echo "        - type: \"$type\""
                    echo "          name: \"$name\""
                    if [[ -n "$url" ]]; then
                        echo "          url: \"$url\""
                    fi
                done
            fi
        else
            # Add videos section to existing media
            video_section="  videos:\n    - youtube_id: \"$youtube_id\"\n      title: \"$video_title\""
            if [[ ${#credits[@]} -gt 0 ]]; then
                video_section="$video_section\n      credits:"
                for credit in "${credits[@]}"; do
                    IFS='|' read -r type name url <<< "$credit"
                    video_section="$video_section\n        - type: \"$type\"\n          name: \"$name\""
                    if [[ -n "$url" ]]; then
                        video_section="$video_section\n          url: \"$url\""
                    fi
                done
            fi
            
            # Insert videos section before draft line
            awk -v videos="$video_section" '/^draft:/ {printf "%s\n", videos} {print}' "$selected_file" > "${selected_file}.tmp"
            mv "${selected_file}.tmp" "$selected_file"
            print_success "Added video to gig"
        fi
    else
        # Build media section with YouTube video
        media_section="media:\n  videos:\n    - youtube_id: \"$youtube_id\"\n      title: \"$video_title\""
        
        if [[ ${#credits[@]} -gt 0 ]]; then
            media_section="$media_section\n      credits:"
            for credit in "${credits[@]}"; do
                IFS='|' read -r type name url <<< "$credit"
                media_section="$media_section\n        - type: \"$type\"\n          name: \"$name\""
                if [[ -n "$url" ]]; then
                    media_section="$media_section\n          url: \"$url\""
                fi
            done
        fi
        
        # Insert before draft line using awk
        awk -v media="$media_section" '/^draft:/ {printf "%s\n", media} {print}' "$selected_file" > "${selected_file}.tmp"
        mv "${selected_file}.tmp" "$selected_file"
        print_success "Added YouTube video to gig"
    fi
    
    show_menu
}

# Add standalone picture
add_standalone_picture() {
    print_header "Add Standalone Picture"
    
    read -rp "Picture title: " title
    read -rp "Picture URL or path: " pic_input
    read -rp "Photographer name: " photographer
    read -rp "Photographer URL (optional): " photographer_url
    read -rp "Description (optional): " description
    
    # Optional gig link
    echo ""
    echo "Link to gig? (optional)"
    read -rp "Gig slug (e.g., 2025-10-11-noise-space-xv) or press Enter to skip: " gig_slug
    
    # Generate filename
    slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    date=$(date +%Y-%m-%d)
    filename="${date}-${slug}.md"
    content_file="website/content/media/pictures/$filename"
    
    mkdir -p "$(dirname "$content_file")"
    mkdir -p "website/static/media/standalone"
    
    # Download or copy image and generate versions
    image_name="${date}-${slug}.jpg"
    if [[ "$pic_input" =~ ^https?:// ]]; then
        temp_file="/tmp/${image_name}"
        if ! download_file "$pic_input" "$temp_file"; then
            show_menu
            return
        fi
        if ! generate_image_versions "$temp_file" "$image_name" "website/static/media/standalone"; then
            rm "$temp_file"
            show_menu
            return
        fi
        rm "$temp_file"
    else
        original_name=$(basename "$pic_input")
        image_name="${date}-${slug}.${original_name##*.}"
        if ! generate_image_versions "$pic_input" "$image_name" "website/static/media/standalone"; then
            show_menu
            return
        fi
    fi
    
    # Create content file
    cat > "$content_file" << EOF
---
title: "$title"
date: $date
type: "picture"
image: "/media/standalone/$image_name"
author: "$photographer"
EOF
    
    if [[ -n "$photographer_url" ]]; then
        echo "author_url: \"$photographer_url\"" >> "$content_file"
    fi
    
    if [[ -n "$gig_slug" ]]; then
        echo "gig: \"$gig_slug\"" >> "$content_file"
    fi
    
    if [[ -n "$description" ]]; then
        echo "description: \"$description\"" >> "$content_file"
    fi
    
    cat >> "$content_file" << 'EOF'
draft: false
---
EOF
    
    print_success "Created standalone picture: $filename"
    show_menu
}

# Add standalone video
add_standalone_video() {
    print_header "Add Standalone Video"
    
    read -rp "Video title: " title
    read -rp "YouTube URL: " youtube_url
    read -rp "Description (optional): " description
    
    # Optional gig link
    echo ""
    echo "Link to gig? (optional)"
    read -rp "Gig slug (e.g., 2025-10-11-noise-space-xv) or press Enter to skip: " gig_slug
    
    # Extract YouTube ID
    youtube_id=""
    if [[ "$youtube_url" =~ youtube\.com/watch\?v=([^&]+) ]]; then
        youtube_id="${BASH_REMATCH[1]}"
    elif [[ "$youtube_url" =~ youtu\.be/([^?]+) ]]; then
        youtube_id="${BASH_REMATCH[1]}"
    else
        print_error "Invalid YouTube URL"
        show_menu
        return
    fi
    
    # Generate filename
    slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    date=$(date +%Y-%m-%d)
    filename="${date}-${slug}.md"
    content_file="website/content/media/videos/$filename"
    
    mkdir -p "$(dirname "$content_file")"
    
    # Create content file
    cat > "$content_file" << EOF
---
title: "$title"
date: $date
type: "video"
youtube_id: "$youtube_id"
EOF
    
    if [[ -n "$gig_slug" ]]; then
        echo "gig: \"$gig_slug\"" >> "$content_file"
    fi
    
    if [[ -n "$description" ]]; then
        echo "description: \"$description\"" >> "$content_file"
    fi
    
    cat >> "$content_file" << 'EOF'
draft: false
---
EOF
    
    print_success "Created standalone video: $filename"
    show_menu
}

# Add to Others
add_others() {
    print_header "Add to Others"
    
    # Create others file if it doesn't exist
    mkdir -p "$(dirname "$OTHERS_FILE")"
    if [[ ! -f "$OTHERS_FILE" ]]; then
        cat > "$OTHERS_FILE" << 'EOF'
---
title: "Others"
---

## Interviews

## Reviews

## Mentions
EOF
    fi
    
    echo "1) Interview"
    echo "2) Review"
    echo "3) Mention"
    echo ""
    read -rp "Type: " type_choice
    
    case $type_choice in
        1) section="Interviews" ;;
        2) section="Reviews" ;;
        3) section="Mentions" ;;
        *) print_error "Invalid type"; show_menu; return ;;
    esac
    
    read -rp "Title: " title
    read -rp "URL: " url
    read -rp "Description (optional): " description
    
    # Add to appropriate section
    if [[ -n "$description" ]]; then
        entry="- [$title]($url) - $description"
    else
        entry="- [$title]($url)"
    fi
    
    # Insert after section header
    sed -i.bak "/^## $section/a\\
$entry
" "$OTHERS_FILE"
    rm -f "${OTHERS_FILE}.bak"
    
    print_success "Added to $section"
    show_menu
}

# List media
list_media() {
    print_header "Media Summary"
    
    echo ""
    echo "Gig Media:"
    for file in "$GIGS_DIR"/*.md; do
        if [[ -f "$file" ]] && [[ "$(basename "$file")" != "_index.md" ]]; then
            if grep -q "^media:" "$file"; then
                title=$(grep "^title:" "$file" | sed 's/title: "\(.*\)"/\1/')
                echo "  - $title (has media)"
            fi
        fi
    done
    
    echo ""
    if [[ -f "$OTHERS_FILE" ]]; then
        echo "Others:"
        grep "^- \[" "$OTHERS_FILE" | head -5
        echo "  (see $OTHERS_FILE for full list)"
    else
        echo "Others: None"
    fi
    
    echo ""
    read -rp "Press Enter to continue..."
    show_menu
}

# Start
show_menu
