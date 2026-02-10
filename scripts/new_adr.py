#!/usr/bin/env python3
"""Create a new ADR from template."""

import argparse
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path


def find_next_adr_number(adr_dir: Path) -> str:
    """Find the next ADR number by examining existing ADRs."""
    adr_files = list(adr_dir.glob("[0-9][0-9][0-9]-*.md"))
    if not adr_files:
        return "003"  # Start from 003 since 000-002 are initial ADRs

    last_num = max(int(f.name[:3]) for f in adr_files)
    return f"{last_num + 1:03d}"


def title_to_filename(title: str) -> str:
    """Convert title to filename format."""
    filename = title.lower().replace(" ", "-")
    return re.sub(r"[^a-z0-9-]", "", filename)


def create_adr_from_template(template_path: Path, new_adr_path: Path,
                           adr_number: str, title: str) -> None:
    """Create new ADR file from template with replacements."""
    if not template_path.exists():
        raise FileNotFoundError(f"Template not found at {template_path}")

    shutil.copy2(template_path, new_adr_path)

    content = new_adr_path.read_text()
    content = content.replace("[NUMBER]", adr_number)
    content = content.replace("[Title in Imperative Form]", title)
    content = content.replace("YYYY-MM-DD", date.today().isoformat())
    new_adr_path.write_text(content)


def update_readme(readme_path: Path, adr_number: str, filename: str, title: str) -> bool:
    """Update README.md with new ADR entry."""
    if not readme_path.exists():
        return False

    content = readme_path.read_text()
    lines = content.splitlines()

    # Find last table row
    last_table_line = -1
    for i, line in enumerate(lines):
        if re.match(r"^\| \[[0-9]", line):
            last_table_line = i

    if last_table_line == -1:
        return False

    new_row = f"| [{adr_number}]({adr_number}-{filename}.md) | {title} | Proposed | {date.today().isoformat()} |"
    lines.insert(last_table_line + 1, new_row)

    readme_path.write_text("\n".join(lines) + "\n")
    return True


def open_in_editor(file_path: Path) -> None:
    """Open file in nvim if available."""
    if shutil.which("nvim"):
        subprocess.run(["nvim", str(file_path)])
    else:
        print(f"⚠️  nvim not found. Please manually edit: {file_path}")


def main() -> None:
    """Main function to create new ADR."""
    parser = argparse.ArgumentParser(description="Create a new ADR from template")
    parser.add_argument("title", help="Title for the ADR")
    args = parser.parse_args()

    try:
        adr_dir = Path("docs/adr")
        template_path = adr_dir / "template.md"
        readme_path = adr_dir / "README.md"

        adr_number = find_next_adr_number(adr_dir)
        filename = title_to_filename(args.title)
        new_adr_path = adr_dir / f"{adr_number}-{filename}.md"

        create_adr_from_template(template_path, new_adr_path, adr_number, args.title)
        print(f"✅ Created new ADR: {new_adr_path}")
        print()

        if update_readme(readme_path, adr_number, filename, args.title):
            print(f"✅ Updated {readme_path} with new ADR entry")
        else:
            print("⚠️  Could not automatically update README.md - please add entry manually")

        print()
        print("Next steps:")
        print(f"1. Edit the ADR file: {new_adr_path}")
        print("2. Fill in all sections (Context, Decision, Alternatives, Consequences)")
        print("3. Review the README.md entry")
        print("4. Commit the ADR")
        print()
        print("Opening file in nvim...")

        open_in_editor(new_adr_path)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
