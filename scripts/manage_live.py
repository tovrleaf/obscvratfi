#!/usr/bin/env python3
"""
Interactive live performance management tool for Obscvrat website.

Manages live performance YAML files and content generation.
Handles file operations, interactive prompts, and poster downloads.

Usage:
    python manage_live.py
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import yaml


class LiveManager:
    """Manages live performances for the Obscvrat website."""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.live_dir = project_root / "website" / "data" / "live"
        self.content_dir = project_root / "website" / "content" / "live"
        self.script_dir = project_root / "scripts"
        
    def show_menu(self) -> None:
        """Display main menu and handle user selection."""
        while True:
            print("\n" + "=" * 20 + " Live Performance Management " + "=" * 20)
            print("1) Create new live performance")
            print("2) List all live performances")
            print("3) Edit existing live performance")
            print("4) Delete live performance")
            print("5) Exit")
            
            try:
                choice = input("\nChoose an option: ").strip()
            except (EOFError, KeyboardInterrupt):
                print("\nExiting...")
                return
                
            if choice == "1":
                self.create_live()
            elif choice == "2":
                self.list_live()
            elif choice == "3":
                self.edit_live()
            elif choice == "4":
                self.delete_live()
            elif choice == "5":
                return
            else:
                print("✗ Invalid option")
                
    def download_poster(self, url: str, output_path: Path) -> bool:
        """Download poster from URL."""
        try:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            urllib.request.urlretrieve(url, output_path)
            print(f"✓ Downloaded poster to {output_path}")
            return True
        except Exception as e:
            print(f"✗ Failed to download poster from {url}: {e}")
            return False
            
    def get_multiline_input(self, prompt: str) -> str:
        """Get multiline input ending with 'END'."""
        print(f"{prompt} (enter text, then type END on a new line and press Enter):")
        lines = []
        while True:
            try:
                line = input()
                if line == "END":
                    break
                lines.append(line)
            except (EOFError, KeyboardInterrupt):
                break
        return '\n'.join(lines)
        
    def get_performers(self) -> List[Dict[str, str]]:
        """Get other performers interactively."""
        performers = []
        print("Other performers (press Enter when done):")
        while True:
            try:
                name = input("  Performer name (or press Enter to finish): ").strip()
                if not name:
                    break
                url = input("  Performer URL (or press Enter to skip): ").strip()
                performer = {"name": name}
                if url:
                    performer["url"] = url
                performers.append(performer)
            except (EOFError, KeyboardInterrupt):
                break
        return performers
        
    def create_slug(self, text: str) -> str:
        """Create URL-friendly slug from text."""
        # Replace spaces with hyphens, then remove non-alphanumeric chars except hyphens
        slug = text.lower().replace(' ', '-')
        slug = re.sub(r'[^a-z0-9-]', '', slug)
        # Replace multiple consecutive hyphens with single hyphen
        slug = re.sub(r'-+', '-', slug)
        return slug
        
    def create_live(self) -> None:
        """Create new live performance."""
        print("\n" + "=" * 20 + " Create New Live Performance " + "=" * 20)
        
        try:
            event_name = input("Event name (or press Enter to use venue name): ").strip()
            date = input("Date (YYYY-MM-DD): ").strip()
            
            if not re.match(r'^\d{4}-\d{2}-\d{2}$', date):
                print("✗ Invalid date format")
                return
                
            venue = input("Venue name: ").strip()
            if not venue:
                print("✗ Venue name is required")
                return
                
            slug_base = event_name if event_name else venue
            if not event_name:
                event_name = venue
                
            city = input("City: ").strip()
            if not city:
                print("✗ City is required")
                return
                
            description = self.get_multiline_input("Description")
            poster_input = input("Poster image URL or path (or press Enter to skip): ").strip()
            
        except (EOFError, KeyboardInterrupt):
            return
            
        # Handle poster
        poster = ""
        if poster_input:
            slug = self.create_slug(slug_base)
            poster_dir = self.project_root / "website" / "assets" / "media" / "gigs" / f"{date}-{slug}"
            poster_filename = f"obscvrat-{slug}-poster-{date.split('-')[0]}.jpg"
            poster_path = poster_dir / poster_filename
            
            if poster_input.startswith(('http://', 'https://')):
                if self.download_poster(poster_input, poster_path):
                    poster = poster_filename
            else:
                source_path = Path(poster_input)
                if source_path.exists():
                    poster_dir.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(source_path, poster_path)
                    poster = poster_filename
                    print(f"✓ Copied poster to {poster_path}")
                else:
                    print(f"✗ Poster file not found: {poster_input}")
                    
        try:
            event_url = input("Event link URL (or press Enter to skip): ").strip()
        except (EOFError, KeyboardInterrupt):
            event_url = ""
            
        performers = self.get_performers()
        
        # Generate filename
        slug = self.create_slug(slug_base)
        filename = f"{date}-{slug}.yaml"
        filepath = self.live_dir / filename
        
        # Check if file exists
        if filepath.exists():
            print(f"✗ Live performance already exists: {filename}")
            try:
                overwrite = input("Overwrite? (y/N): ").strip().lower()
                if overwrite != 'y':
                    return
            except (EOFError, KeyboardInterrupt):
                return
                
        # Build data
        data = {
            'title': event_name,
            'date': date,
            'venue': venue,
            'location': city,
            'draft': False
        }
        
        if poster:
            data['poster'] = poster
        if event_url:
            data['event_link'] = event_url
        if performers:
            data['other_performers'] = performers
            
        # Write file
        self.live_dir.mkdir(parents=True, exist_ok=True)
        with open(filepath, 'w') as f:
            f.write('---\n')
            yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
            f.write('---\n\n')
            f.write(description)
            
        print(f"✓ Created live performance: {filename}")
        
        # Generate markdown
        self.run_generate_markdown("live")
        
        try:
            open_editor = input("Open in editor? (y/N): ").strip().lower()
            if open_editor == 'y':
                editor = os.environ.get('EDITOR', 'vim')
                subprocess.run([editor, str(filepath)])
        except (EOFError, KeyboardInterrupt):
            pass
            
    def get_live_files(self) -> List[Path]:
        """Get list of live performance YAML files."""
        if not self.live_dir.exists():
            return []
        return [f for f in self.live_dir.glob("*.yaml") if f.name != "_index.md"]
        
    def list_live(self) -> None:
        """List all live performances."""
        print("\n" + "=" * 20 + " All Gigs " + "=" * 20)
        
        files = self.get_live_files()
        if not files:
            print("⚠ No live performances found")
            try:
                input("Press Enter to continue...")
            except (EOFError, KeyboardInterrupt):
                pass
            return
            
        for i, file_path in enumerate(files, 1):
            try:
                with open(file_path, 'r') as f:
                    content = f.read()
                    if content.startswith('---\n'):
                        end_idx = content.find('\n---\n', 4)
                        if end_idx != -1:
                            data = yaml.safe_load(content[4:end_idx])
                            title = data.get('title', 'Unknown')
                            date_part = file_path.stem.split('-')[:3]
                            date_str = '-'.join(date_part)
                            location = data.get('location', 'Unknown')
                            print(f"{i}) {date_str} - {title} ({location})")
                            print(f"   File: {file_path.name}")
                            print()
            except Exception as e:
                print(f"✗ Error reading {file_path.name}: {e}")
                
        try:
            input("Press Enter to continue...")
        except (EOFError, KeyboardInterrupt):
            pass
            
    def select_live_file(self, action: str) -> Optional[Path]:
        """Select live performance file interactively."""
        files = self.get_live_files()
        if not files:
            print("⚠ No live performances found")
            return None
            
        print(f"\n{action}:")
        for i, file_path in enumerate(files, 1):
            try:
                with open(file_path, 'r') as f:
                    content = f.read()
                    if content.startswith('---\n'):
                        end_idx = content.find('\n---\n', 4)
                        if end_idx != -1:
                            data = yaml.safe_load(content[4:end_idx])
                            title = data.get('title', 'Unknown')
                            print(f"{i}) {file_path.name} - {title}")
            except Exception:
                print(f"{i}) {file_path.name} - (error reading)")
                
        try:
            selection = input(f"\nSelect live performance number (or 0 to cancel): ").strip()
            if selection == "0":
                return None
                
            idx = int(selection) - 1
            if 0 <= idx < len(files):
                return files[idx]
            else:
                print("✗ Invalid selection")
                return None
        except (ValueError, EOFError, KeyboardInterrupt):
            return None
            
    def parse_live_file(self, file_path: Path) -> Tuple[Dict, str]:
        """Parse live performance YAML file."""
        with open(file_path, 'r') as f:
            content = f.read()
            
        if not content.startswith('---\n'):
            raise ValueError("Invalid YAML frontmatter")
            
        end_idx = content.find('\n---\n', 4)
        if end_idx == -1:
            raise ValueError("Invalid YAML frontmatter")
            
        frontmatter = yaml.safe_load(content[4:end_idx])
        body = content[end_idx + 5:].strip()
        
        return frontmatter, body
        
    def write_live_file(self, file_path: Path, data: Dict, body: str) -> None:
        """Write live performance YAML file."""
        with open(file_path, 'w') as f:
            f.write('---\n')
            yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
            f.write('---\n\n')
            f.write(body)
            
    def edit_live(self) -> None:
        """Edit existing live performance."""
        selected_file = self.select_live_file("Edit Live Performance")
        if not selected_file:
            return
            
        try:
            old_data, old_body = self.parse_live_file(selected_file)
        except Exception as e:
            print(f"✗ Error reading file: {e}")
            return
            
        print(f"\n" + "=" * 20 + f" Edit Live Performance: {old_data.get('title', 'Unknown')} " + "=" * 20)
        
        try:
            # Get updated values with defaults
            event_name = input(f"Event name [{old_data.get('title', '')}]: ").strip()
            event_name = event_name if event_name else old_data.get('title', '')
            
            date = input(f"Date [{old_data.get('date', '')}]: ").strip()
            date = date if date else old_data.get('date', '')
            
            if not re.match(r'^\d{4}-\d{2}-\d{2}$', date):
                print("✗ Invalid date format")
                return
                
            venue = input(f"Venue [{old_data.get('venue', '')}]: ").strip()
            venue = venue if venue else old_data.get('venue', '')
            
            city = input(f"City [{old_data.get('location', '')}]: ").strip()
            city = city if city else old_data.get('location', '')
            
            # Description
            old_desc_preview = old_body[:50] + "..." if len(old_body) > 50 else old_body
            print(f"Description (current: {old_desc_preview}) - type END on a new line to finish, or just END to keep current:")
            description = self.get_multiline_input("")
            if not description:
                description = old_body
                
            poster_input = input(f"Poster [{old_data.get('poster', '')}]: ").strip()
            poster_input = poster_input if poster_input else old_data.get('poster', '')
            
            event_url = input("Event link URL (or press Enter to skip): ").strip()
            
        except (EOFError, KeyboardInterrupt):
            return
            
        # Handle poster (simplified - just keep existing or update)
        poster = poster_input
        
        # Build updated data
        slug_base = event_name if event_name != venue else venue
        new_data = {
            'title': event_name,
            'date': date,
            'venue': venue,
            'location': city,
            'draft': False
        }
        
        if poster:
            new_data['poster'] = poster
        if event_url:
            new_data['event_link'] = event_url
        if 'other_performers' in old_data:
            new_data['other_performers'] = old_data['other_performers']
            
        # Generate new filename
        slug = self.create_slug(slug_base)
        new_filename = f"{date}-{slug}.yaml"
        new_filepath = self.live_dir / new_filename
        
        # Write file
        self.write_live_file(new_filepath, new_data, description)
        
        # Remove old file if filename changed
        if selected_file != new_filepath:
            selected_file.unlink()
            print(f"✓ Updated and renamed: {new_filename}")
        else:
            print(f"✓ Updated: {new_filename}")
            
        self.run_generate_markdown("live")
        
    def delete_live(self) -> None:
        """Delete live performance."""
        selected_file = self.select_live_file("Delete Live Performance")
        if not selected_file:
            return
            
        print(f"⚠ About to delete: {selected_file.name}")
        try:
            confirm = input("Are you sure? (y/N): ").strip().lower()
            if confirm == 'y':
                selected_file.unlink()
                print(f"✓ Deleted: {selected_file.name}")
                self.run_generate_markdown("live")
            else:
                print("⚠ Cancelled")
        except (EOFError, KeyboardInterrupt):
            print("⚠ Cancelled")
            
    def run_generate_markdown(self, content_type: str) -> None:
        """Run generate-markdown.sh script."""
        try:
            script_path = self.script_dir / "generate-markdown.sh"
            if script_path.exists():
                subprocess.run([str(script_path), content_type], check=True)
                print("⚠ Generated markdown...")
        except subprocess.CalledProcessError as e:
            print(f"✗ Error generating markdown: {e}")


def main() -> int:
    """Main function."""
    # Find project root
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    # Change to project root
    os.chdir(project_root)
    
    # Check for required tools
    try:
        import yaml
    except ImportError:
        print("Error: PyYAML is not installed")
        print("Install with: pip install PyYAML")
        return 1
        
    # Create directories
    live_dir = project_root / "website" / "data" / "live"
    live_dir.mkdir(parents=True, exist_ok=True)
    
    manager = LiveManager(project_root)
    manager.show_menu()
    return 0


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    sys.exit(main())