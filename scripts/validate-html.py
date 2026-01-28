#!/usr/bin/env python3
"""HTML validation using html5lib (pure Python)"""

import html5lib
from pathlib import Path
import sys

def validate_html_files(html_dir):
    """Validate all HTML files in directory using html5lib"""
    html_files = list(Path(html_dir).rglob('*.html'))
    
    if not html_files:
        print(f"No HTML files found in {html_dir}")
        return True
    
    errors = 0
    for html_file in html_files:
        try:
            with open(html_file, 'rb') as f:
                html5lib.parse(f, treebuilder='etree', namespaceHTMLElements=False)
        except Exception as e:
            print(f"Error in {html_file}: {e}")
            errors += 1
    
    if errors > 0:
        print(f"❌ HTML validation failed: {errors} files with errors")
        return False
    else:
        print("✅ HTML validation passed")
        return True

if __name__ == "__main__":
    html_dir = sys.argv[1] if len(sys.argv) > 1 else "website/public"
    success = validate_html_files(html_dir)
    sys.exit(0 if success else 1)