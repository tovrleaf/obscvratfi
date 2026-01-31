#!/usr/bin/env bash
set -euo pipefail

# Generate markdown files from YAML data files
# Usage: ./scripts/generate-markdown.sh [live|music|media|all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$PROJECT_ROOT/website/data"
CONTENT_DIR="$PROJECT_ROOT/website/content"

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "Error: yq is not installed"
    echo "Install with: brew install yq"
    exit 1
fi

# Convert text to HTML with proper link formatting and line breaks
text_to_html() {
    local text="$1"
    
    # Convert URLs to HTML links that open in new window
    text=$(echo "$text" | sed -E 's|(https?://[^[:space:]]+)|<a href="\1" target="_blank" rel="noopener noreferrer">\1</a>|g')
    
    # Use awk to handle paragraph breaks and line breaks
    echo "$text" | awk '
        BEGIN { in_para = 0; output = "" }
        {
            if (NF == 0) {
                # Empty line - close paragraph if open
                if (in_para) {
                    output = output "</p>\n\n"
                    in_para = 0
                }
            } else {
                # Non-empty line
                if (!in_para) {
                    output = output "<p>"
                    in_para = 1
                } else {
                    output = output "<br>\n"
                }
                output = output $0
            }
        }
        END {
            if (in_para) {
                output = output "</p>"
            }
            print output
        }
    '
}

generate_live() {
    local yaml_file="$1"
    local filename
    filename="$(basename "$yaml_file" .yaml)"
    local md_file="$CONTENT_DIR/live/$filename.md"
    
    echo "Generating $md_file"
    
    # Get description and convert to HTML
    local description=$(yq eval '.description // ""' "$yaml_file")
    local html_description=$(text_to_html "$description")
    
    # Use yq to convert YAML frontmatter to markdown frontmatter
    {
        echo "---"
        yq eval 'del(.description) | del(.content)' "$yaml_file"
        echo "---"
        echo ""
        echo "$html_description"
    } > "$md_file"
}

generate_music() {
    local yaml_file="$1"
    local filename
    filename="$(basename "$yaml_file" .yaml)"
    local md_file="$CONTENT_DIR/music/$filename.md"
    
    echo "Generating $md_file"
    
    # Get content and convert to HTML
    local content=$(yq eval '.content // ""' "$yaml_file")
    local html_content=$(text_to_html "$content")
    
    {
        echo "---"
        yq eval 'del(.content)' "$yaml_file"
        echo "---"
        echo ""
        echo "$html_content"
    } > "$md_file"
}

generate_media() {
    local yaml_file="$1"
    local filename
    filename="$(basename "$yaml_file" .yaml)"
    local md_file="$CONTENT_DIR/media/$filename.md"
    
    echo "Generating $md_file"
    
    {
        echo "---"
        yq eval '.' "$yaml_file"
        echo ""
        echo "---"
    } > "$md_file"
}

# Main execution
TYPE="${1:-all}"

case "$TYPE" in
    live)
        for yaml_file in "$DATA_DIR/live"/*.yaml; do
            [ -f "$yaml_file" ] && generate_live "$yaml_file"
        done
        ;;
    music)
        for yaml_file in "$DATA_DIR/music"/*.yaml; do
            [ -f "$yaml_file" ] && generate_music "$yaml_file"
        done
        ;;
    media)
        for yaml_file in "$DATA_DIR/media"/*.yaml; do
            [ -f "$yaml_file" ] && generate_media "$yaml_file"
        done
        ;;
    all)
        for yaml_file in "$DATA_DIR/live"/*.yaml; do
            [ -f "$yaml_file" ] && generate_live "$yaml_file"
        done
        for yaml_file in "$DATA_DIR/music"/*.yaml; do
            [ -f "$yaml_file" ] && generate_music "$yaml_file"
        done
        for yaml_file in "$DATA_DIR/media"/*.yaml; do
            [ -f "$yaml_file" ] && generate_media "$yaml_file"
        done
        ;;
    *)
        echo "Usage: $0 [live|music|media|all]"
        exit 1
        ;;
esac

echo "✅ Markdown generation complete"
