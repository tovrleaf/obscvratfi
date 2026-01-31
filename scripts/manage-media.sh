#!/usr/bin/env bash
# scripts/manage-media.sh - Interactive media management tool

set -euo pipefail

LIVE_DIR="website/content/live"
MEDIA_DIR="website/assets/media"
OTHERS_FILE="website/data/media/others.yaml"
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

# List live performances for selection
list_live_for_selection() {
    local counter=1
    for file in "$LIVE_DIR"/*.yaml; do
        if [[ -f "$file" ]] && [[ "$(basename "$file")" != "_index.md" ]]; then
            local gig_title=$(grep "^title:" "$file" | sed 's/title: "\(.*\)"/\1/')
            local gig_date=$(grep "^date:" "$file" | sed 's/date: //')
            echo "  $counter) $live_title ($live_date)"
            ((counter++))
        fi
    done
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
    echo "1) Add pictures to live performance"
    echo "2) Add video to live performance"
    echo "3) Add standalone picture"
    echo "4) Add standalone video"
    echo "5) Add to Others (interview, mention, review)"
    echo "6) Edit Others item"
    echo "7) List media"
    echo "8) Exit"
    echo "9) Edit video"
    echo ""
    read -rp "Choose an option: " choice || exit 0
    echo ""
    
    case $choice in
        1) add_pictures ;;
        2) add_video ;;
        3) add_standalone_picture ;;
        4) add_standalone_video ;;
        5) add_others ;;
        6) edit_others ;;
        7) list_media ;;
        8) exit 0 ;;
        9) edit_video ;;
        *) print_error "Invalid option"; show_menu ;;
    esac
}

# Add pictures to live performance
add_pictures() {
    print_header "Add Pictures to Gig"
    
    # List live performances
    if [[ ! -d "$LIVE_DIR" ]] || [[ -z "$(ls -A "$LIVE_DIR" 2>/dev/null)" ]]; then
        print_warning "No live performances found"
        show_menu
        return
    fi
    
    echo ""
    local -a files=()
    local count=1
    for file in "$LIVE_DIR"/*.yaml; do
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
    read -rp "Select live performance number (or 0 to cancel): " selection
    
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
    
    # Get live performance slug from filename
    gig_slug=$(basename "$selected_file" .md)
    media_dir="website/static/media/live/$live_slug"
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
    
    # Update live performance frontmatter
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
        print_success "Added ${#pictures[@]} pictures to live performance"
    
    # Generate markdown from YAML
    print_warning "Generating markdown..."
    "$SCRIPT_DIR/generate-markdown.sh" live
    fi
    
    show_menu
}

# Add video to live performance
add_video() {
    print_header "Add Video to Gig"
    
    # List live performances
    if [[ ! -d "$LIVE_DIR" ]] || [[ -z "$(ls -A "$LIVE_DIR" 2>/dev/null)" ]]; then
        print_warning "No live performances found"
        show_menu
        return
    fi
    
    echo ""
    local -a files=()
    local count=1
    for file in "$LIVE_DIR"/*.yaml; do
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
    read -rp "Select live performance number (or 0 to cancel): " selection
    
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
    read -rp "Video date (YYYY-MM-DD, or press Enter to skip): " video_date
    
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
    
    # Update live performance frontmatter
    if grep -q "^media:" "$selected_file"; then
        # Media section exists, check if videos subsection exists
        if grep -q "^  videos:" "$selected_file"; then
            print_warning "Videos section already exists. Manual edit required."
            echo "Add this to the videos list:"
            echo "    - youtube_id: \"$youtube_id\""
            echo "      title: \"$video_title\""
            if [[ -n "$video_date" ]]; then
                echo "      date: $video_date"
            fi
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
            if [[ -n "$video_date" ]]; then
                video_section="$video_section\n      date: $video_date"
            fi
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
            print_success "Added video to live performance"
    
    # Generate markdown from YAML
    print_warning "Generating markdown..."
    "$SCRIPT_DIR/generate-markdown.sh" live
        fi
    else
        # Build media section with YouTube video
        media_section="media:\n  videos:\n    - youtube_id: \"$youtube_id\"\n      title: \"$video_title\""
        
        if [[ -n "$video_date" ]]; then
            media_section="$media_section\n      date: $video_date"
        fi
        
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
        print_success "Added YouTube video to live performance"
    
    # Generate markdown from YAML
    print_warning "Generating markdown..."
    "$SCRIPT_DIR/generate-markdown.sh" live
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
    
    # Optional live performance link
    echo ""
    echo "Link to live performance? (optional)"
    read -rp "Gig slug (e.g., 2025-10-11-noise-space-xv) or press Enter to skip: " gig_slug
    
    # Generate filename
    slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    date=$(date +%Y-%m-%d)
    filename="${date}-${slug}.yaml"
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
    
    if [[ -n "$live_slug" ]]; then
        echo "gig: \"$live_slug\"" >> "$content_file"
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
    
    # Optional live performance link
    echo ""
    echo "Link to live performance? (optional)"
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
    filename="${date}-${slug}.yaml"
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
    
    if [[ -n "$live_slug" ]]; then
        echo "gig: \"$live_slug\"" >> "$content_file"
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
items: []
---
EOF
    fi
    
    echo "1) Interview"
    echo "2) Review"
    echo "3) Mention"
    echo ""
    read -rp "Type: " type_choice
    
    case $type_choice in
        1) item_type="interview" ;;
        2) item_type="review" ;;
        3) item_type="mention" ;;
        *) print_error "Invalid type"; show_menu; return ;;
    esac
    
    read -rp "Title: " title
    read -rp "URL: " url
    read -rp "Media title (optional, e.g., magazine/website name): " media_title
    read -rp "Description (optional): " description
    read -rp "Date (YYYY-MM-DD, optional): " item_date
    
    # Ask if related to a gig
    echo ""
    echo "Related to a gig? (optional)"
    list_live_for_selection
    read -rp "Gig number (or press Enter to skip): " gig_choice
    
    gig_slug=""
    if [[ -n "$live_choice" ]] && [[ "$live_choice" =~ ^[0-9]+$ ]]; then
        gig_files=("$LIVE_DIR"/*.yaml)
        gig_files=("${gig_files[@]##*/}")
        gig_files=("${gig_files[@]%.md}")
        if [[ "$live_choice" -gt 0 ]] && [[ "$live_choice" -le "${#gig_files[@]}" ]]; then
            gig_slug="${gig_files[$((gig_choice-1))]}"
        fi
    fi
    
    # Build YAML item
    local item_lines=()
    item_lines+=("  - type: \"$item_type\"")
    item_lines+=("    title: \"$title\"")
    item_lines+=("    url: \"$url\"")
    [[ -n "$media_title" ]] && item_lines+=("    media_title: \"$media_title\"")
    [[ -n "$description" ]] && item_lines+=("    description: \"$description\"")
    [[ -n "$item_date" ]] && item_lines+=("    date: $item_date")
    [[ -n "$live_slug" ]] && item_lines+=("    gig: \"$live_slug\"")
    
    # Add to items array
    if grep -q "^items: \[\]" "$OTHERS_FILE"; then
        # Empty array, replace with first item
        {
            echo "---"
            grep "^title:" "$OTHERS_FILE"
            echo "items:"
            printf '%s\n' "${item_lines[@]}"
            echo "---"
        } > "$OTHERS_FILE.tmp"
        mv "$OTHERS_FILE.tmp" "$OTHERS_FILE"
    else
        # Append to existing items
        local temp_file="$OTHERS_FILE.tmp"
        while IFS= read -r line; do
            echo "$line"
            if [[ "$line" == "items:" ]]; then
                printf '%s\n' "${item_lines[@]}"
            fi
        done < "$OTHERS_FILE" > "$temp_file"
        mv "$temp_file" "$OTHERS_FILE"
    fi
    
    print_success "Added to Others"
    
    # Generate markdown from YAML
    print_warning "Generating markdown..."
    "$SCRIPT_DIR/generate-markdown.sh" media
    show_menu
}

# Edit Others item
edit_others() {
    print_header "Edit Others Item"
    
    if [[ ! -f "$OTHERS_FILE" ]]; then
        print_error "No Others file found"
        show_menu
        return
    fi
    
    # Parse items from YAML
    local -a items_data=()
    local current_item=""
    local in_items=false
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^items: ]]; then
            in_items=true
            continue
        fi
        if [[ "$in_items" == true ]]; then
            if [[ "$line" =~ ^---$ ]]; then
                break
            fi
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]type: ]]; then
                [[ -n "$current_item" ]] && items_data+=("$current_item")
                current_item="$line"
            else
                current_item+=$'\n'"$line"
            fi
        fi
    done < "$OTHERS_FILE"
    [[ -n "$current_item" ]] && items_data+=("$current_item")
    
    if [[ ${#items_data[@]} -eq 0 ]]; then
        print_error "No items found"
        show_menu
        return
    fi
    
    # List items
    echo "Existing items:"
    for i in "${!items_data[@]}"; do
        local title=$(echo "${items_data[$i]}" | grep "^[[:space:]]*title:" | head -1 | sed 's/.*title: "\(.*\)"/\1/')
        echo "  $((i+1))) $title"
    done
    
    echo ""
    read -rp "Select item to edit (or press Enter to cancel): " item_choice
    
    if [[ -z "$item_choice" ]] || [[ ! "$item_choice" =~ ^[0-9]+$ ]] || [[ "$item_choice" -lt 1 ]] || [[ "$item_choice" -gt ${#items_data[@]} ]]; then
        show_menu
        return
    fi
    
    # Extract current values
    local idx=$((item_choice-1))
    local item="${items_data[$idx]}"
    local current_type=$(echo "$item" | grep "type:" | sed 's/.*type: "\(.*\)"/\1/')
    local current_title=$(echo "$item" | grep "^[[:space:]]*title:" | head -1 | sed 's/.*title: "\(.*\)"/\1/')
    local current_url=$(echo "$item" | grep "url:" | sed 's/.*url: "\(.*\)"/\1/')
    local current_media_title=$(echo "$item" | grep "media_title:" | sed 's/.*media_title: "\(.*\)"/\1/')
    local current_desc=$(echo "$item" | grep "description:" | sed 's/.*description: "\(.*\)"/\1/')
    local current_date=$(echo "$item" | grep "date:" | sed 's/.*date: \(.*\)/\1/')
    local current_gig=$(echo "$item" | grep "gig:" | sed 's/.*gig: "\(.*\)"/\1/')
    
    # Interactive edit
    echo ""
    print_header "Editing: $current_title"
    
    echo "1) Interview"
    echo "2) Review"
    echo "3) Mention"
    read -rp "Type [$current_type]: " new_type
    [[ -z "$new_type" ]] && new_type="$current_type"
    case $new_type in
        1|interview) new_type="interview" ;;
        2|review) new_type="review" ;;
        3|mention) new_type="mention" ;;
        *) new_type="$current_type" ;;
    esac
    
    read -rp "Title [$current_title]: " new_title
    [[ -z "$new_title" ]] && new_title="$current_title"
    
    read -rp "URL [$current_url]: " new_url
    [[ -z "$new_url" ]] && new_url="$current_url"
    
    read -rp "Media title [$current_media_title]: " new_media_title
    [[ -z "$new_media_title" ]] && new_media_title="$current_media_title"
    
    read -rp "Description [$current_desc]: " new_desc
    [[ -z "$new_desc" ]] && new_desc="$current_desc"
    
    read -rp "Date (YYYY-MM-DD) [$current_date]: " new_date
    [[ -z "$new_date" ]] && new_date="$current_date"
    
    echo ""
    echo "Related to a gig? (current: ${current_gig:-none})"
    list_live_for_selection
    read -rp "Gig number (or press Enter to keep current): " gig_choice
    
    new_gig="$current_gig"
    if [[ -n "$live_choice" ]]; then
        if [[ "$live_choice" =~ ^[0-9]+$ ]]; then
            gig_files=("$LIVE_DIR"/*.yaml)
            gig_files=("${gig_files[@]##*/}")
            gig_files=("${gig_files[@]%.md}")
            if [[ "$live_choice" -gt 0 ]] && [[ "$live_choice" -le "${#gig_files[@]}" ]]; then
                new_gig="${gig_files[$((gig_choice-1))]}"
            fi
        elif [[ "$live_choice" == "none" ]] || [[ "$live_choice" == "0" ]]; then
            new_gig=""
        fi
    fi
    
    # Build new item
    local new_item="  - type: \"$new_type\"\n"
    new_item+="    title: \"$new_title\"\n"
    new_item+="    url: \"$new_url\"\n"
    [[ -n "$new_media_title" ]] && new_item+="    media_title: \"$new_media_title\"\n"
    [[ -n "$new_desc" ]] && new_item+="    description: \"$new_desc\"\n"
    [[ -n "$new_date" ]] && new_item+="    date: $new_date\n"
    [[ -n "$new_gig" ]] && new_item+="    gig: \"$new_gig\"\n"
    
    # Replace in array
    items_data[$idx]="$new_item"
    
    # Rebuild file
    {
        echo "---"
        echo "title: \"Others\""
        echo "items:"
        for item_data in "${items_data[@]}"; do
            echo -e "$item_data"
        done
        echo "---"
    } > "$OTHERS_FILE"
    
    print_success "Item updated"
    show_menu
}

# List media
list_media() {
    print_header "Media Summary"
    
    echo ""
    echo "Gig Media:"
    for file in "$LIVE_DIR"/*.yaml; do
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
        local count=0
        local in_items=false
        while IFS= read -r line; do
            if [[ "$line" == "items:" ]]; then
                in_items=true
                continue
            fi
            if [[ "$in_items" == true ]] && [[ "$line" =~ title:[[:space:]]+\"(.*)\" ]]; then
                echo "  - ${BASH_REMATCH[1]}"
                count=$((count + 1))
                [[ $count -ge 5 ]] && break
            fi
        done < "$OTHERS_FILE"
        if [[ $count -eq 0 ]]; then
            echo "  None"
        fi
    else
        echo "Others: None"
    fi
    
    echo ""
    read -rp "Press Enter to continue..." || :
    show_menu
}

# Edit video
edit_video() {
    print_header "Edit Video"
    
    # List all gigs with videos
    if [[ ! -d "$LIVE_DIR" ]]; then
        print_error "No gigs directory found"
        show_menu
        return
    fi
    
    declare -a gigs_with_videos=()
    for file in "$LIVE_DIR"/*.yaml; do
        if [[ -f "$file" ]] && grep -q "youtube_id:" "$file"; then
            gigs_with_videos+=("$file")
        fi
    done
    
    if [[ ${#gigs_with_videos[@]} -eq 0 ]]; then
        print_warning "No gigs with videos found"
        show_menu
        return
    fi
    
    echo "Gigs with videos:"
    for i in "${!gigs_with_videos[@]}"; do
        file="${gigs_with_videos[$i]}"
        title=$(grep "^title:" "$file" | sed 's/title: "\(.*\)"/\1/')
        date=$(grep "^date:" "$file" | awk '{print $2}')
        echo "$((i+1))) $date - $title"
    done
    echo "0) Cancel"
    echo ""
    
    read -rp "Select live performance: " selection || selection="0"
    
    if [[ "$selection" == "0" ]]; then
        show_menu
        return
    fi
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#gigs_with_videos[@]}" ]]; then
        print_error "Invalid selection"
        show_menu
        return
    fi
    
    selected_file="${gigs_with_videos[$((selection-1))]}"
    
    # Extract videos section
    echo ""
    echo "Current videos:"
    awk '/  videos:/,/^[a-z_]+:/ {if (!/^[a-z_]+:/ || /  videos:/) print}' "$selected_file" | grep -v "^[a-z_]*:" | sed 's/^  //'
    
    echo ""
    echo "1) Add new video"
    echo "2) Remove video"
    echo "3) Edit video details"
    echo "0) Cancel"
    read -rp "Choose action: " action || action="0"
    
    case $action in
        1)
            # Add new video
            read -rp "Video URL: " video_url || video_url=""
            read -rp "Video title: " video_title || video_title=""
            read -rp "Video date (YYYY-MM-DD): " video_date || video_date=""
            
            # Add credits
            echo "Add credits (press Enter on credit type to finish):"
            declare -a credits=()
            while true; do
                read -rp "  Credit type: " credit_type || break
                if [[ -z "$credit_type" ]]; then
                    break
                fi
                read -rp "  Name: " credit_name || credit_name=""
                read -rp "  URL (optional): " credit_url || credit_url=""
                
                if [[ -n "$credit_url" ]]; then
                    credits+=("$credit_type|$credit_name|$credit_url")
                else
                    credits+=("$credit_type|$credit_name|")
                fi
            done
            
            # Build video entry
            video_entry="  - url: \"$video_url\"\n    title: \"$video_title\"\n    date: $video_date"
            if [[ ${#credits[@]} -gt 0 ]]; then
                video_entry="$video_entry\n    credits:"
                for credit in "${credits[@]}"; do
                    IFS='|' read -r type name url <<< "$credit"
                    video_entry="$video_entry\n      - type: \"$type\"\n        name: \"$name\""
                    if [[ -n "$url" ]]; then
                        video_entry="$video_entry\n        url: \"$url\""
                    fi
                done
            fi
            
            # Insert before the next frontmatter field or ---
            awk -v entry="$video_entry" '
                /^  videos:/ { in_videos=1; print; next }
                in_videos && /^[a-z_]+:/ { print entry; in_videos=0 }
                in_videos && /^---$/ { print entry; in_videos=0 }
                { print }
                END { if (in_videos) print entry }
            ' "$selected_file" > "$selected_file.tmp" && mv "$selected_file.tmp" "$selected_file"
            
            print_success "Video added"
            ;;
        2)
            # Remove video - open in editor
            ${EDITOR:-vim} "$selected_file"
            print_success "Edit complete"
            ;;
        3)
            # Edit video - open in editor
            ${EDITOR:-vim} "$selected_file"
            print_success "Edit complete"
            ;;
        0)
            show_menu
            return
            ;;
    esac
    
    show_menu
}

# Start
show_menu
