#!/usr/bin/env python3
"""
Gear inventory management tool for Obscvrat website.
Manages YAML data files for musical gear (pedals, synths, instruments).

For AI-assisted gear addition, just tell Kiro: "add BOSS BD-2 to gear"
"""

import os
import sys
import yaml
import re
import shutil
import subprocess
from pathlib import Path
from typing import List, Optional

# Set UTF-8 encoding for stdin/stdout
if sys.stdin.encoding != 'utf-8':
    sys.stdin.reconfigure(encoding='utf-8')
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

GEAR_DIR = Path(__file__).parent.parent / "website" / "data" / "gear"

def fzf_select(options: List[str], prompt: str = "Select") -> Optional[str]:
    """Use fzf for selection if available, otherwise fall back to numbered menu."""
    if not options:
        return None

    # Check if fzf is available
    if shutil.which("fzf"):
        try:
            result = subprocess.run(
                [
                    "fzf",
                    "--prompt", f"{prompt}> ",
                    "--height", "40%",
                    "--reverse",
                    "--border",
                    "--no-mouse"
                ],
                input="\n".join(options),
                capture_output=True,
                text=True,
                check=False,
                env={**os.environ, "FZF_DEFAULT_OPTS": ""}
            )
            if result.returncode == 0:
                return result.stdout.strip()
            return None
        except Exception:
            pass

    # Fallback: numbered selection
    print(f"\n{prompt}:")
    for i, option in enumerate(options, 1):
        print(f"{i}) {option}")

    try:
        selection = input("\nSelect number (or 0 to cancel): ").strip()
        if selection == "0":
            return None
        idx = int(selection) - 1
        if 0 <= idx < len(options):
            return options[idx]
    except (ValueError, EOFError, KeyboardInterrupt):
        pass

    return None

def slugify(text):
    """Convert text to URL-friendly slug."""
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[-\s]+', '-', text)
    return text

def load_gear():
    """Load all gear from YAML files."""
    gear_list = []
    if not GEAR_DIR.exists():
        return gear_list
    
    for file in GEAR_DIR.glob("*.yaml"):
        if file.name == '.gitkeep':
            continue
        with open(file, 'r') as f:
            data = yaml.safe_load(f)
            data['_filename'] = file.name
            gear_list.append(data)
    
    return sorted(gear_list, key=lambda x: (x['manufacturer'], x['name']))

def save_gear(data):
    """Save gear data to YAML file."""
    GEAR_DIR.mkdir(parents=True, exist_ok=True)
    
    slug = slugify(f"{data['manufacturer']}-{data['name']}")
    filename = GEAR_DIR / f"{slug}.yaml"
    
    with open(filename, 'w') as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)
    
    return filename

def add_gear():
    """Add new gear interactively."""
    print("\n=== Add New Gear ===\n")
    print("💡 Tip: For AI-assisted entry, tell Kiro: 'add [manufacturer] [model] to gear'\n")
    
    manufacturer = input("Manufacturer: ").strip()
    if not manufacturer:
        print("❌ Manufacturer required")
        return
    
    name = input("Name/Model: ").strip()
    if not name:
        print("❌ Name required")
        return
    
    # Category selection
    categories = ["Pedal", "Synth"]
    category = fzf_select(categories, "Select category")
    if not category:
        print("❌ Cancelled")
        return
    
    # Types
    print("\nTypes (comma-separated):")
    print("Examples: Distortion, Overdrive, Delay, Reverb, Chorus")
    types_input = input("Types: ").strip()
    types = [t.strip() for t in types_input.split(',') if t.strip()]
    
    # Technology
    technologies = ["Analog", "Digital", "Hybrid"]
    technology = fzf_select(technologies, "Select technology")
    if not technology:
        print("❌ Cancelled")
        return
    
    # Settings
    print("\nSettings/Controls (comma-separated):")
    print("Example: Volume, Tone, Gain")
    settings_input = input("Settings: ").strip()
    settings = [s.strip() for s in settings_input.split(',') if s.strip()]
    
    # Description
    description = input("\nDescription (optional): ").strip()
    
    # URL
    url = input("URL (manufacturer page, optional): ").strip()
    
    # Build data
    data = {
        'name': name,
        'manufacturer': manufacturer,
        'category': category,
        'types': types,
        'technology': technology,
        'settings': settings,
        'description': description,
        'url': url or ''
    }
    
    # Save
    filename = save_gear(data)
    print(f"\n✅ Gear saved: {filename.name}")

def list_gear(filter_category=None, filter_manufacturer=None, filter_type=None):
    """List all gear with optional filters."""
    gear_list = load_gear()
    
    if not gear_list:
        print("\n📦 No gear found")
        return
    
    # Apply filters
    if filter_category:
        gear_list = [g for g in gear_list if g['category'] == filter_category]
    if filter_manufacturer:
        gear_list = [g for g in gear_list if filter_manufacturer.lower() in g['manufacturer'].lower()]
    if filter_type:
        gear_list = [g for g in gear_list if any(filter_type.lower() in t.lower() for t in g.get('types', []))]
    
    if not gear_list:
        print("\n📦 No gear matches filters")
        return
    
    print(f"\n=== Gear List ({len(gear_list)} items) ===\n")
    for i, gear in enumerate(gear_list, 1):
        types_str = ', '.join(gear.get('types', []))
        print(f"{i}. {gear['manufacturer']} - {gear['name']}")
        print(f"   Category: {gear['category']} | Types: {types_str} | Tech: {gear['technology']}")
    
    return gear_list

def search_gear():
    """Search gear by keyword."""
    keyword = input("\nSearch keyword: ").strip().lower()
    if not keyword:
        return
    
    gear_list = load_gear()
    results = []
    
    for gear in gear_list:
        searchable = f"{gear['manufacturer']} {gear['name']} {gear.get('description', '')} {' '.join(gear.get('types', []))}"
        if keyword in searchable.lower():
            results.append(gear)
    
    if not results:
        print(f"\n📦 No gear found matching '{keyword}'")
        return
    
    print(f"\n=== Search Results ({len(results)} items) ===\n")
    for i, gear in enumerate(results, 1):
        print(f"{i}. {gear['manufacturer']} - {gear['name']}")

def edit_gear():
    """Edit existing gear."""
    gear_list = load_gear()
    if not gear_list:
        print("\n📦 No gear found")
        return
    
    # Build options for fzf
    options = [f"{g['manufacturer']} - {g['name']}" for g in gear_list]
    selected = fzf_select(options, "Select gear to edit")
    
    if not selected:
        print("❌ Cancelled")
        return
    
    # Find selected gear
    idx = options.index(selected)
    gear = gear_list[idx]
    filename = GEAR_DIR / gear['_filename']
    
    editor = os.environ.get('EDITOR', 'nano')
    os.system(f"{editor} {filename}")
    print(f"✅ Edited: {filename.name}")

def delete_gear():
    """Delete gear."""
    gear_list = load_gear()
    if not gear_list:
        print("\n📦 No gear found")
        return
    
    # Build options for fzf
    options = [f"{g['manufacturer']} - {g['name']}" for g in gear_list]
    selected = fzf_select(options, "Select gear to delete")
    
    if not selected:
        print("❌ Cancelled")
        return
    
    # Find selected gear
    idx = options.index(selected)
    gear = gear_list[idx]
    
    confirm = input(f"Delete '{gear['manufacturer']} - {gear['name']}'? (yes/no): ").strip().lower()
    
    if confirm == 'yes':
        filename = GEAR_DIR / gear['_filename']
        filename.unlink()
        print(f"✅ Deleted: {gear['manufacturer']} - {gear['name']}")
    else:
        print("❌ Cancelled")

def archive_gear():
    """Archive gear by moving to archived directory."""
    gear_list = load_gear()
    
    if not gear_list:
        print("No gear found")
        return
    
    options = [f"{g['manufacturer']} - {g['name']}" for g in gear_list]
    selected = fzf_select(options, "Select gear to archive")
    
    if not selected:
        print("❌ Cancelled")
        return
    
    idx = options.index(selected)
    gear = gear_list[idx]
    
    archived_dir = GEAR_DIR / "archived"
    archived_dir.mkdir(exist_ok=True)
    
    src = GEAR_DIR / gear['_filename']
    dst = archived_dir / gear['_filename']
    
    shutil.move(str(src), str(dst))
    print(f"✅ Archived: {gear['manufacturer']} - {gear['name']}")

def unarchive_gear():
    """Unarchive gear by moving back to main directory."""
    archived_dir = GEAR_DIR / "archived"
    
    if not archived_dir.exists():
        print("No archived gear found")
        return
    
    gear_list = []
    for file in archived_dir.glob("*.yaml"):
        with open(file, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
            data['_filename'] = file.name
            gear_list.append(data)
    
    if not gear_list:
        print("No archived gear found")
        return
    
    options = [f"{g['manufacturer']} - {g['name']}" for g in gear_list]
    selected = fzf_select(options, "Select gear to unarchive")
    
    if not selected:
        print("❌ Cancelled")
        return
    
    idx = options.index(selected)
    gear = gear_list[idx]
    
    src = archived_dir / gear['_filename']
    dst = GEAR_DIR / gear['_filename']
    
    shutil.move(str(src), str(dst))
    print(f"✅ Unarchived: {gear['manufacturer']} - {gear['name']}")

def main_menu():
    """Display main menu."""
    while True:
        options = [
            "Add gear",
            "List all gear",
            "List by category",
            "List by manufacturer",
            "Search gear",
            "Edit gear",
            "Delete gear",
            "Archive gear",
            "Unarchive gear",
            "Exit"
        ]
        
        choice = fzf_select(options, "OBSCVRAT GEAR MANAGEMENT")
        
        if not choice or choice == "Exit":
            print("\n👋 Goodbye!")
            break
        elif choice == "Add gear":
            add_gear()
        elif choice == "List all gear":
            list_gear()
        elif choice == "List by category":
            categories = ["Pedal", "Synth"]
            cat = fzf_select(categories, "Filter by category")
            if cat:
                list_gear(filter_category=cat)
        elif choice == "List by manufacturer":
            mfr = input("\nFilter by manufacturer: ").strip()
            if mfr:
                list_gear(filter_manufacturer=mfr)
        elif choice == "Search gear":
            search_gear()
        elif choice == "Edit gear":
            edit_gear()
        elif choice == "Delete gear":
            delete_gear()
        elif choice == "Archive gear":
            archive_gear()
        elif choice == "Unarchive gear":
            unarchive_gear()

if __name__ == '__main__':
    try:
        main_menu()
    except KeyboardInterrupt:
        print("\n\n👋 Goodbye!")
        sys.exit(0)
