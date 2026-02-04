#!/usr/bin/env python3
"""
Interactive media management tool for Obscvrat website.

Manages pictures, videos, and other media content for live performances
and standalone content. Handles YAML file processing, file operations,
and interactive prompts.

Usage:
    python manage_media.py
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import urllib.request
from datetime import date
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import yaml


class MediaManager:
    """Manages media content for the Obscvrat website."""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.live_dir = project_root / "website" / "content" / "live"
        self.media_dir = project_root / "website" / "assets" / "media"
        self.others_file = project_root / "website" / "data" / "media" / "others.yaml"
        self.script_dir = project_root / "scripts"
        
    def show_menu(self) -> None:
        """Display main menu and handle user selection."""
        while True:
            print("\n" + "=" * 20 + " Media Management " + "=" * 20)
            print("1) Add pictures to live performance")
            print("2) Add video to live performance")
            print("3) Add standalone picture")
            print("4) Add standalone video")
            print("5) Add to Others (interview, mention, review)")
            print("6) Edit Others item")
            print("7) List media")
            print("8) Exit")
            print("9) Edit video")
            
            try:
                choice = input("\nChoose an option: ").strip()
            except (EOFError, KeyboardInterrupt):
                print("\nExiting...")
                return
                
            if choice == "1":
                self.add_pictures()
            elif choice == "2":
                self.add_video()
            elif choice == "3":
                self.add_standalone_picture()
            elif choice == "4":
                self.add_standalone_video()
            elif choice == "5":
                self.add_others()
            elif choice == "6":
                self.edit_others()
            elif choice == "7":
                self.list_media()
            elif choice == "8":
                return
            elif choice == "9":
                self.edit_video()
            else:
                print("✗ Invalid option")
                
    def get_live_performances(self) -> List[Tuple[Path, Dict]]:
        """Get list of live performance files with metadata."""
        performances = []
        if not self.live_dir.exists():
            return performances
            
        for file_path in self.live_dir.glob("*.yaml"):
            if file_path.name == "_index.md":
                continue
            try:
                with open(file_path, 'r') as f:
                    content = f.read()
                    # Extract frontmatter
                    if content.startswith('---\n'):
                        end_idx = content.find('\n---\n', 4)
                        if end_idx != -1:
                            frontmatter = yaml.safe_load(content[4:end_idx])
                            performances.append((file_path, frontmatter))
            except (yaml.YAMLError, IOError) as e:
                print(f"✗ Error reading {file_path}: {e}")
                
        return performances
        
    def select_live_performance(self) -> Optional[Tuple[Path, Dict]]:
        """Interactive selection of live performance."""
        performances = self.get_live_performances()
        if not performances:
            print("⚠ No live performances found")
            return None
            
        print("\nLive performances:")
        for i, (file_path, metadata) in enumerate(performances, 1):
            title = metadata.get('title', 'Unknown')
            date_str = metadata.get('date', 'Unknown')
            print(f"{i}) {date_str} - {title}")
            
        try:
            selection = input("\nSelect live performance number (or 0 to cancel): ").strip()
            if selection == "0":
                return None
                
            idx = int(selection) - 1
            if 0 <= idx < len(performances):
                return performances[idx]
            else:
                print("✗ Invalid selection")
                return None
        except (ValueError, EOFError, KeyboardInterrupt):
            return None
            
    def download_file(self, url: str, output_path: Path) -> bool:
        """Download file from URL."""
        try:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            urllib.request.urlretrieve(url, output_path)
            print(f"✓ Downloaded to {output_path}")
            return True
        except Exception as e:
            print(f"✗ Failed to download from {url}: {e}")
            return False
            
    def generate_image_versions(self, source_file: Path, base_name: str, output_dir: Path) -> bool:
        """Generate image versions (Hugo handles responsive images)."""
        try:
            output_dir.mkdir(parents=True, exist_ok=True)
            output_path = output_dir / base_name
            shutil.copy2(source_file, output_path)
            print(f"✓ Saved: {base_name} (Hugo will generate responsive versions)")
            return True
        except Exception as e:
            print(f"✗ Error saving image: {e}")
            return False
            
    def extract_youtube_id(self, url: str) -> Optional[str]:
        """Extract YouTube video ID from URL."""
        patterns = [
            r'youtube\.com/watch\?v=([^&]+)',
            r'youtu\.be/([^?]+)'
        ]
        
        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                return match.group(1)
        return None
        
    def update_live_performance_yaml(self, file_path: Path, media_data: Dict) -> bool:
        """Update live performance YAML file with media data."""
        try:
            with open(file_path, 'r') as f:
                content = f.read()
                
            # Parse frontmatter
            if not content.startswith('---\n'):
                print("✗ Invalid YAML frontmatter")
                return False
                
            end_idx = content.find('\n---\n', 4)
            if end_idx == -1:
                print("✗ Invalid YAML frontmatter")
                return False
                
            frontmatter = yaml.safe_load(content[4:end_idx])
            body = content[end_idx + 5:]
            
            # Update media section
            if 'media' not in frontmatter:
                frontmatter['media'] = {}
                
            frontmatter['media'].update(media_data)
            
            # Write back
            with open(file_path, 'w') as f:
                f.write('---\n')
                yaml.dump(frontmatter, f, default_flow_style=False, allow_unicode=True)
                f.write('---\n')
                f.write(body)
                
            return True
        except Exception as e:
            print(f"✗ Error updating YAML: {e}")
            return False
            
    def run_generate_markdown(self, content_type: str) -> None:
        """Run generate-markdown.sh script."""
        try:
            script_path = self.script_dir / "generate-markdown.sh"
            if script_path.exists():
                subprocess.run([str(script_path), content_type], check=True)
                print("⚠ Generated markdown...")
        except subprocess.CalledProcessError as e:
            print(f"✗ Error generating markdown: {e}")
            
    def add_pictures(self) -> None:
        """Add pictures to live performance."""
        print("\n" + "=" * 20 + " Add Pictures to Gig " + "=" * 20)
        
        performance = self.select_live_performance()
        if not performance:
            return
            
        file_path, metadata = performance
        
        # Get photographer info
        try:
            photographer = input("Photographer name: ").strip()
            photographer_url = input("Photographer URL (optional): ").strip()
        except (EOFError, KeyboardInterrupt):
            return
            
        # Get gig slug from filename
        gig_slug = file_path.stem
        media_dir = self.project_root / "website" / "static" / "media" / "live" / gig_slug
        media_dir.mkdir(parents=True, exist_ok=True)
        
        # Add pictures
        pictures = []
        pic_counter = 1
        
        print("Add picture URLs or paths (press Enter when done):")
        while True:
            try:
                pic_input = input(f"  Picture URL or path (or press Enter to finish): ").strip()
                if not pic_input:
                    break
                    
                # Generate descriptive filename
                ext = "jpg"
                if pic_input.lower().endswith(('.png', '.gif', '.jpeg')):
                    ext = pic_input.split('.')[-1].lower()
                    
                descriptive_name = f"obscvrat-{gig_slug}-performance-{pic_counter}.{ext}"
                
                # Handle URL or local file
                if pic_input.startswith(('http://', 'https://')):
                    temp_file = Path(f"/tmp/temp-pic-{pic_counter}.{ext}")
                    if self.download_file(pic_input, temp_file):
                        if self.generate_image_versions(temp_file, descriptive_name, media_dir):
                            pictures.append(descriptive_name)
                        temp_file.unlink(missing_ok=True)
                else:
                    source_path = Path(pic_input)
                    if source_path.exists():
                        if self.generate_image_versions(source_path, descriptive_name, media_dir):
                            pictures.append(descriptive_name)
                    else:
                        print(f"✗ File not found: {pic_input}")
                        
                pic_counter += 1
            except (EOFError, KeyboardInterrupt):
                break
                
        if not pictures:
            print("⚠ No pictures added")
            return
            
        # Update YAML
        media_data = {
            'pictures': {
                'author': photographer,
                'images': pictures
            }
        }
        
        if photographer_url:
            media_data['pictures']['author_url'] = photographer_url
            
        if self.update_live_performance_yaml(file_path, media_data):
            print(f"✓ Added {len(pictures)} pictures to live performance")
            self.run_generate_markdown("live")
            
    def add_video(self) -> None:
        """Add video to live performance."""
        print("\n" + "=" * 20 + " Add Video to Gig " + "=" * 20)
        
        performance = self.select_live_performance()
        if not performance:
            return
            
        file_path, metadata = performance
        
        try:
            youtube_url = input("YouTube URL: ").strip()
            video_title = input("Video title: ").strip()
            video_date = input("Video date (YYYY-MM-DD, or press Enter to skip): ").strip()
        except (EOFError, KeyboardInterrupt):
            return
            
        youtube_id = self.extract_youtube_id(youtube_url)
        if not youtube_id:
            print("✗ Invalid YouTube URL")
            return
            
        # Collect credits
        credits = []
        print("\nAdd credits (press Enter on credit type to finish):")
        while True:
            try:
                credit_type = input("  Credit type (e.g., Recorded, Mastered, Artwork): ").strip()
                if not credit_type:
                    break
                credit_name = input("  Name: ").strip()
                credit_url = input("  URL (optional, press Enter to skip): ").strip()
                
                credit = {'type': credit_type, 'name': credit_name}
                if credit_url:
                    credit['url'] = credit_url
                credits.append(credit)
            except (EOFError, KeyboardInterrupt):
                break
                
        # Build video data
        video_data = {
            'youtube_id': youtube_id,
            'title': video_title
        }
        
        if video_date:
            video_data['date'] = video_date
        if credits:
            video_data['credits'] = credits
            
        # Update YAML
        media_data = {'videos': [video_data]}
        
        if self.update_live_performance_yaml(file_path, media_data):
            print("✓ Added YouTube video to live performance")
            self.run_generate_markdown("live")
            
    def add_standalone_picture(self) -> None:
        """Add standalone picture."""
        print("\n" + "=" * 20 + " Add Standalone Picture " + "=" * 20)
        
        try:
            title = input("Picture title: ").strip()
            pic_input = input("Picture URL or path: ").strip()
            photographer = input("Photographer name: ").strip()
            photographer_url = input("Photographer URL (optional): ").strip()
            description = input("Description (optional): ").strip()
            gig_slug = input("Gig slug (e.g., 2025-10-11-noise-space-xv) or press Enter to skip: ").strip()
        except (EOFError, KeyboardInterrupt):
            return
            
        # Generate filename
        slug = re.sub(r'[^a-z0-9-]', '', title.lower().replace(' ', '-'))
        today = date.today().strftime('%Y-%m-%d')
        filename = f"{today}-{slug}.yaml"
        
        content_file = self.project_root / "website" / "content" / "media" / "pictures" / filename
        content_file.parent.mkdir(parents=True, exist_ok=True)
        
        standalone_dir = self.project_root / "website" / "static" / "media" / "standalone"
        standalone_dir.mkdir(parents=True, exist_ok=True)
        
        # Process image
        image_name = f"{today}-{slug}.jpg"
        if pic_input.startswith(('http://', 'https://')):
            temp_file = Path(f"/tmp/{image_name}")
            if not self.download_file(pic_input, temp_file):
                return
            if not self.generate_image_versions(temp_file, image_name, standalone_dir):
                temp_file.unlink(missing_ok=True)
                return
            temp_file.unlink(missing_ok=True)
        else:
            source_path = Path(pic_input)
            if not source_path.exists():
                print(f"✗ File not found: {pic_input}")
                return
            original_ext = source_path.suffix.lower()
            image_name = f"{today}-{slug}{original_ext}"
            if not self.generate_image_versions(source_path, image_name, standalone_dir):
                return
                
        # Create content file
        frontmatter = {
            'title': title,
            'date': today,
            'type': 'picture',
            'image': f'/media/standalone/{image_name}',
            'author': photographer,
            'draft': False
        }
        
        if photographer_url:
            frontmatter['author_url'] = photographer_url
        if gig_slug:
            frontmatter['gig'] = gig_slug
        if description:
            frontmatter['description'] = description
            
        with open(content_file, 'w') as f:
            f.write('---\n')
            yaml.dump(frontmatter, f, default_flow_style=False, allow_unicode=True)
            f.write('---\n')
            
        print(f"✓ Created standalone picture: {filename}")
        
    def add_standalone_video(self) -> None:
        """Add standalone video."""
        print("\n" + "=" * 20 + " Add Standalone Video " + "=" * 20)
        
        try:
            title = input("Video title: ").strip()
            youtube_url = input("YouTube URL: ").strip()
            description = input("Description (optional): ").strip()
            gig_slug = input("Gig slug (e.g., 2025-10-11-noise-space-xv) or press Enter to skip: ").strip()
        except (EOFError, KeyboardInterrupt):
            return
            
        youtube_id = self.extract_youtube_id(youtube_url)
        if not youtube_id:
            print("✗ Invalid YouTube URL")
            return
            
        # Generate filename
        slug = re.sub(r'[^a-z0-9-]', '', title.lower().replace(' ', '-'))
        today = date.today().strftime('%Y-%m-%d')
        filename = f"{today}-{slug}.yaml"
        
        content_file = self.project_root / "website" / "content" / "media" / "videos" / filename
        content_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Create content file
        frontmatter = {
            'title': title,
            'date': today,
            'type': 'video',
            'youtube_id': youtube_id,
            'draft': False
        }
        
        if gig_slug:
            frontmatter['gig'] = gig_slug
        if description:
            frontmatter['description'] = description
            
        with open(content_file, 'w') as f:
            f.write('---\n')
            yaml.dump(frontmatter, f, default_flow_style=False, allow_unicode=True)
            f.write('---\n')
            
        print(f"✓ Created standalone video: {filename}")
        
    def load_others_data(self) -> Dict:
        """Load others.yaml data."""
        if not self.others_file.exists():
            return {'title': 'Others', 'items': []}
            
        try:
            with open(self.others_file, 'r') as f:
                content = f.read()
                if content.startswith('---\n'):
                    end_idx = content.find('\n---\n', 4)
                    if end_idx != -1:
                        return yaml.safe_load(content[4:end_idx])
                return yaml.safe_load(content)
        except Exception as e:
            print(f"✗ Error loading others data: {e}")
            return {'title': 'Others', 'items': []}
            
    def save_others_data(self, data: Dict) -> bool:
        """Save others.yaml data."""
        try:
            self.others_file.parent.mkdir(parents=True, exist_ok=True)
            with open(self.others_file, 'w') as f:
                f.write('---\n')
                yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
                f.write('---\n')
            return True
        except Exception as e:
            print(f"✗ Error saving others data: {e}")
            return False
            
    def add_others(self) -> None:
        """Add to Others."""
        print("\n" + "=" * 20 + " Add to Others " + "=" * 20)
        
        print("1) Interview")
        print("2) Review")
        print("3) Mention")
        
        try:
            type_choice = input("\nType: ").strip()
        except (EOFError, KeyboardInterrupt):
            return
            
        type_map = {'1': 'interview', '2': 'review', '3': 'mention'}
        item_type = type_map.get(type_choice)
        if not item_type:
            print("✗ Invalid type")
            return
            
        try:
            title = input("Title: ").strip()
            url = input("URL: ").strip()
            media_title = input("Media title (optional, e.g., magazine/website name): ").strip()
            description = input("Description (optional): ").strip()
            item_date = input("Date (YYYY-MM-DD, optional): ").strip()
        except (EOFError, KeyboardInterrupt):
            return
            
        # Build item
        item = {
            'type': item_type,
            'title': title,
            'url': url
        }
        
        if media_title:
            item['media_title'] = media_title
        if description:
            item['description'] = description
        if item_date:
            item['date'] = item_date
            
        # Load and update data
        data = self.load_others_data()
        data['items'].append(item)
        
        if self.save_others_data(data):
            print("✓ Added to Others")
            self.run_generate_markdown("media")
            
    def edit_others(self) -> None:
        """Edit Others item."""
        print("\n" + "=" * 20 + " Edit Others Item " + "=" * 20)
        
        data = self.load_others_data()
        items = data.get('items', [])
        
        if not items:
            print("✗ No items found")
            return
            
        print("Existing items:")
        for i, item in enumerate(items, 1):
            title = item.get('title', 'Unknown')
            print(f"  {i}) {title}")
            
        try:
            item_choice = input("\nSelect item to edit (or press Enter to cancel): ").strip()
            if not item_choice:
                return
                
            idx = int(item_choice) - 1
            if not (0 <= idx < len(items)):
                print("✗ Invalid selection")
                return
        except (ValueError, EOFError, KeyboardInterrupt):
            return
            
        # Edit item interactively
        item = items[idx]
        print(f"\nEditing: {item.get('title', 'Unknown')}")
        
        # This is a simplified edit - in practice you'd want full interactive editing
        print("✗ Interactive editing not implemented - please edit the YAML file manually")
        print(f"File: {self.others_file}")
        
    def list_media(self) -> None:
        """List media summary."""
        print("\n" + "=" * 20 + " Media Summary " + "=" * 20)
        
        print("\nGig Media:")
        performances = self.get_live_performances()
        for file_path, metadata in performances:
            if 'media' in metadata:
                title = metadata.get('title', 'Unknown')
                print(f"  - {title} (has media)")
                
        print("\nOthers:")
        data = self.load_others_data()
        items = data.get('items', [])
        if items:
            for item in items[:5]:  # Show first 5
                title = item.get('title', 'Unknown')
                print(f"  - {title}")
            if len(items) > 5:
                print(f"  ... and {len(items) - 5} more")
        else:
            print("  None")
            
        try:
            input("\nPress Enter to continue...")
        except (EOFError, KeyboardInterrupt):
            pass
            
    def edit_video(self) -> None:
        """Edit video (simplified implementation)."""
        print("\n" + "=" * 20 + " Edit Video " + "=" * 20)
        print("✗ Video editing not implemented - please edit YAML files manually")


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
        
    manager = MediaManager(project_root)
    manager.show_menu()
    return 0


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    sys.exit(main())