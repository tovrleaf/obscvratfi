#!/usr/bin/env python3
"""
Bump version in CHANGELOG.md

Usage:
    python bump_version.py [major|minor|patch]
"""

import argparse
import re
import sys
from datetime import date
from pathlib import Path


def parse_changelog(content: str) -> dict:
    """
    Parse CHANGELOG.md content to extract current version.

    Args:
        content: CHANGELOG.md file content

    Returns:
        Dict with version info

    Raises:
        ValueError: If no version found
    """
    match = re.search(r'^## \[([0-9]+\.[0-9]+\.[0-9]+)\]', content, re.MULTILINE)
    if not match:
        raise ValueError("Could not find current version in CHANGELOG")
    return {'version': match.group(1)}


def bump_version(current_version: str, bump_type: str) -> str:
    """
    Calculate new version based on bump type.

    Args:
        current_version: Current version string (e.g., "1.0.0")
        bump_type: Type of bump ("major", "minor", "patch")

    Returns:
        New version string

    Raises:
        ValueError: If invalid bump type or version format
    """
    if bump_type not in ['major', 'minor', 'patch']:
        raise ValueError(f"Invalid bump type '{bump_type}'. Use: major, minor, or patch")

    try:
        major, minor, patch = map(int, current_version.split('.'))
    except ValueError as e:
        raise ValueError(f"Invalid version format: {current_version}") from e

    if bump_type == 'major':
        major += 1
        minor = 0
        patch = 0
    elif bump_type == 'minor':
        minor += 1
        patch = 0
    else:  # patch
        patch += 1

    return f"{major}.{minor}.{patch}"


def update_changelog(changelog_path: Path, new_version: str) -> None:
    """
    Update CHANGELOG.md with new version entry.

    Args:
        changelog_path: Path to CHANGELOG.md
        new_version: New version string
    """
    content = changelog_path.read_text()
    today = date.today().strftime('%Y-%m-%d')

    new_entry = f"""## [{new_version}] - {today}

### Added

### Changed

### Fixed
"""

    # Find first version line and insert before it
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if re.match(r'^## \[', line):
            # Insert new entry with blank line before next version
            lines.insert(i, new_entry.rstrip())
            lines.insert(i + 1, '')
            break
    else:
        raise ValueError("Could not find version entry in CHANGELOG")

    changelog_path.write_text('\n'.join(lines))


def update_readme(readme_path: Path, new_version: str) -> None:
    """
    Update README.md with new version.

    Args:
        readme_path: Path to README.md
        new_version: New version string
    """
    content = readme_path.read_text()
    # Update version in footer line
    updated = re.sub(
        r'\*\*Version:\*\* \d+\.\d+\.\d+',
        f'**Version:** {new_version}',
        content
    )
    readme_path.write_text(updated)


def main_function(bump_type: str) -> int:
    """
    Main logic function.

    Args:
        bump_type: Type of version bump

    Returns:
        Exit code (0 for success)
    """
    changelog_path = Path("CHANGELOG.md")
    static_changelog_path = Path("website/static/changelog.txt")
    readme_path = Path("README.md")

    if not changelog_path.exists():
        print(f"Error: {changelog_path} not found", file=sys.stderr)
        return 1

    try:
        content = changelog_path.read_text()
        version_info = parse_changelog(content)
        current_version = version_info['version']
        new_version = bump_version(current_version, bump_type)

        update_changelog(changelog_path, new_version)

        # Copy to website/static for Hugo version.html partial
        static_changelog_path.parent.mkdir(parents=True, exist_ok=True)
        static_changelog_path.write_text(changelog_path.read_text())

        # Update README.md version
        if readme_path.exists():
            update_readme(readme_path, new_version)

        print(new_version)
        return 0

    except (ValueError, OSError) as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bump_type', nargs='?', default='patch',
                       help='Version bump type (major, minor, patch)')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    sys.exit(main_function(args.bump_type))
