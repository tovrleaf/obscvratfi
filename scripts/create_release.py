#!/usr/bin/env python3
"""
Create GitHub Release from CHANGELOG.md

Reads the latest version from CHANGELOG.md and creates a GitHub release
with the corresponding release notes.

Usage:
    python create_release.py [--dry-run]
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import Tuple


def extract_version_and_notes(changelog_path: Path) -> Tuple[str, str]:
    """
    Extract version and release notes from CHANGELOG.md.
    
    Args:
        changelog_path: Path to CHANGELOG.md file
        
    Returns:
        Tuple of (version, release_notes)
        
    Raises:
        FileNotFoundError: If CHANGELOG.md doesn't exist
        ValueError: If version or release notes can't be extracted
    """
    if not changelog_path.exists():
        raise FileNotFoundError(f"CHANGELOG.md not found at {changelog_path}")
    
    content = changelog_path.read_text()
    
    # Extract version from first ## [x.x.x] line
    version_match = re.search(r'^## \[([0-9]+\.[0-9]+\.[0-9]+)\]', content, re.MULTILINE)
    if not version_match:
        raise ValueError("Could not find version in CHANGELOG.md")
    
    version = version_match.group(1)
    
    # Extract release notes between first and second ## [ lines
    lines = content.split('\n')
    start_idx = None
    end_idx = None
    header_count = 0
    
    for i, line in enumerate(lines):
        if line.startswith('## ['):
            header_count += 1
            if header_count == 1:
                start_idx = i + 1
            elif header_count == 2:
                end_idx = i
                break
    
    if start_idx is None:
        raise ValueError(f"Could not extract release notes for version {version}")
    
    # If no second header found, take until end of file
    if end_idx is None:
        end_idx = len(lines)
    
    release_notes = '\n'.join(lines[start_idx:end_idx]).strip()
    
    if not release_notes:
        raise ValueError(f"No release notes found for version {version}")
    
    return version, release_notes


def create_github_release(version: str, release_notes: str, dry_run: bool = False) -> int:
    """
    Create GitHub release using gh CLI.
    
    Args:
        version: Version string (e.g., "1.0.0")
        release_notes: Markdown formatted release notes
        dry_run: If True, print what would be done without executing
        
    Returns:
        Exit code (0 for success)
    """
    tag = f"v{version}"
    title = f"v{version}"
    
    if dry_run:
        print(f"Would create GitHub release:")
        print(f"  Tag: {tag}")
        print(f"  Title: {title}")
        print(f"  Notes: {len(release_notes)} characters")
        print(f"  Release notes preview:")
        print("  " + "\n  ".join(release_notes.split('\n')[:5]))
        if len(release_notes.split('\n')) > 5:
            print("  ...")
        return 0
    
    try:
        cmd = [
            'gh', 'release', 'create', tag,
            '--title', title,
            '--notes', release_notes,
            '--latest'
        ]
        
        print(f"Creating GitHub release {tag}...")
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print(f"✓ Release {tag} created successfully")
        return 0
        
    except subprocess.CalledProcessError as e:
        print(f"Error creating GitHub release: {e}", file=sys.stderr)
        if e.stderr:
            print(f"stderr: {e.stderr}", file=sys.stderr)
        return 1
    except FileNotFoundError:
        print("Error: gh CLI not found. Please install GitHub CLI.", file=sys.stderr)
        return 1


def main(dry_run: bool = False) -> int:
    """
    Main function to create GitHub release.
    
    Args:
        dry_run: If True, show what would be done without executing
        
    Returns:
        Exit code (0 for success)
    """
    changelog_path = Path("CHANGELOG.md")
    
    try:
        version, release_notes = extract_version_and_notes(changelog_path)
        return create_github_release(version, release_notes, dry_run)
        
    except (FileNotFoundError, ValueError) as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dry-run', action='store_true', 
                       help='Show what would be done without executing')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    sys.exit(main(args.dry_run))