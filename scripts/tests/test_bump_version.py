"""Tests for bump_version.py script."""


import pytest

from scripts.bump_version import bump_version, main_function, parse_changelog, update_changelog


def test_parse_changelog_valid():
    """Test parsing valid CHANGELOG.md."""
    content = "## [1.0.0] - 2026-01-01\n### Added\n- Feature"
    result = parse_changelog(content)
    assert result['version'] == '1.0.0'


def test_parse_changelog_no_version():
    """Test parsing CHANGELOG.md with no version."""
    content = "# Changelog\n\nNo versions here"
    with pytest.raises(ValueError, match="Could not find current version"):
        parse_changelog(content)


def test_bump_version_patch():
    """Test patch version bump."""
    result = bump_version('1.0.0', 'patch')
    assert result == '1.0.1'


def test_bump_version_minor():
    """Test minor version bump."""
    result = bump_version('1.0.5', 'minor')
    assert result == '1.1.0'


def test_bump_version_major():
    """Test major version bump."""
    result = bump_version('1.5.3', 'major')
    assert result == '2.0.0'


def test_bump_version_invalid_type():
    """Test invalid bump type."""
    with pytest.raises(ValueError, match="Invalid bump type"):
        bump_version('1.0.0', 'invalid')


def test_bump_version_invalid_format():
    """Test invalid version format."""
    with pytest.raises(ValueError, match="Invalid version format"):
        bump_version('invalid', 'patch')


def test_update_changelog(tmp_path):
    """Test updating CHANGELOG.md with new version."""
    changelog = tmp_path / "CHANGELOG.md"
    changelog.write_text("# Changelog\n\n## [1.0.0] - 2026-01-01\n### Added\n- Feature")

    update_changelog(changelog, "1.0.1")

    content = changelog.read_text()
    assert "## [1.0.1]" in content
    assert "### Added" in content
    assert "## [1.0.0]" in content


def test_update_changelog_no_version(tmp_path):
    """Test updating CHANGELOG.md with no existing version."""
    changelog = tmp_path / "CHANGELOG.md"
    changelog.write_text("# Changelog\n\nNo versions")

    with pytest.raises(ValueError, match="Could not find version entry"):
        update_changelog(changelog, "1.0.0")


def test_main_function_success(tmp_path, monkeypatch):
    """Test successful main function execution."""
    # Change to temp directory
    monkeypatch.chdir(tmp_path)

    # Create test CHANGELOG.md
    changelog = tmp_path / "CHANGELOG.md"
    changelog.write_text("# Changelog\n\n## [1.0.0] - 2026-01-01\n### Added\n- Feature")

    # Create website/data directory
    (tmp_path / "website" / "data").mkdir(parents=True)

    result = main_function('patch')
    assert result == 0

    # Check changelog was updated
    content = changelog.read_text()
    assert "## [1.0.1]" in content

    # Check data file was created
    data_file = tmp_path / "website" / "data" / "changelog.txt"
    assert data_file.exists()


def test_main_function_no_changelog(tmp_path, monkeypatch):
    """Test main function with missing CHANGELOG.md."""
    monkeypatch.chdir(tmp_path)

    result = main_function('patch')
    assert result == 1


def test_main_function_invalid_changelog(tmp_path, monkeypatch):
    """Test main function with invalid CHANGELOG.md."""
    monkeypatch.chdir(tmp_path)

    changelog = tmp_path / "CHANGELOG.md"
    changelog.write_text("Invalid changelog")

    result = main_function('patch')
    assert result == 1
