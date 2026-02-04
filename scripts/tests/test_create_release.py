"""
Unit tests for create_release.py

Tests version extraction, release notes parsing, and GitHub release creation.
"""

import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock
import subprocess

# Import the module under test
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))
from create_release import extract_version_and_notes, create_github_release, main


@pytest.fixture
def temp_changelog(tmp_path):
    """Create temporary CHANGELOG.md for testing."""
    changelog = tmp_path / "CHANGELOG.md"
    return changelog


@pytest.fixture
def valid_changelog_content():
    """Valid CHANGELOG.md content for testing."""
    return """# Changelog

All notable changes to this project will be documented in this file.

## [1.2.3] - 2026-02-04

### Added
- New feature A
- New feature B

### Changed
- Updated component X
- Improved performance

### Fixed
- Bug fix 1
- Bug fix 2

## [1.2.2] - 2026-02-01

### Fixed
- Previous bug fix

## [1.2.1] - 2026-01-30

### Added
- Previous feature
"""


@pytest.fixture
def changelog_with_empty_lines():
    """CHANGELOG.md with empty lines in release notes."""
    return """# Changelog

## [2.0.0] - 2026-02-05

### Added
- Feature with empty line below

- Another feature after empty line

### Changed

- Change with empty line above

## [1.9.9] - 2026-02-01

### Fixed
- Previous fix
"""


class TestExtractVersionAndNotes:
    """Test version and release notes extraction."""
    
    def test_extract_from_valid_changelog(self, temp_changelog, valid_changelog_content):
        """Test extracting version and notes from valid CHANGELOG."""
        temp_changelog.write_text(valid_changelog_content)
        
        version, notes = extract_version_and_notes(temp_changelog)
        
        assert version == "1.2.3"
        assert "### Added" in notes
        assert "New feature A" in notes
        assert "### Changed" in notes
        assert "### Fixed" in notes
        assert "Bug fix 2" in notes
        # Should not contain the next version's content
        assert "1.2.2" not in notes
        assert "Previous bug fix" not in notes
    
    def test_extract_preserves_markdown_formatting(self, temp_changelog, changelog_with_empty_lines):
        """Test that empty lines and formatting are preserved."""
        temp_changelog.write_text(changelog_with_empty_lines)
        
        version, notes = extract_version_and_notes(temp_changelog)
        
        assert version == "2.0.0"
        # Check that empty lines are preserved
        lines = notes.split('\n')
        assert '' in lines  # Should contain empty lines
        assert "- Feature with empty line below" in notes
        assert "- Another feature after empty line" in notes
        assert "- Change with empty line above" in notes
    
    def test_extract_single_version_changelog(self, temp_changelog):
        """Test extracting from CHANGELOG with only one version."""
        content = """# Changelog

## [1.0.0] - 2026-02-04

### Added
- Initial release
- Basic functionality

### Fixed
- Initial bugs
"""
        temp_changelog.write_text(content)
        
        version, notes = extract_version_and_notes(temp_changelog)
        
        assert version == "1.0.0"
        assert "### Added" in notes
        assert "Initial release" in notes
        assert "### Fixed" in notes
        assert "Initial bugs" in notes
    
    def test_file_not_found(self, tmp_path):
        """Test error when CHANGELOG.md doesn't exist."""
        nonexistent = tmp_path / "nonexistent.md"
        
        with pytest.raises(FileNotFoundError, match="CHANGELOG.md not found"):
            extract_version_and_notes(nonexistent)
    
    def test_no_version_found(self, temp_changelog):
        """Test error when no version is found in CHANGELOG."""
        content = """# Changelog

Some content without version headers.

### Added
- Something
"""
        temp_changelog.write_text(content)
        
        with pytest.raises(ValueError, match="Could not find version in CHANGELOG.md"):
            extract_version_and_notes(temp_changelog)
    
    def test_invalid_version_format(self, temp_changelog):
        """Test error when version format is invalid."""
        content = """# Changelog

## [v1.2] - 2026-02-04

### Added
- Something
"""
        temp_changelog.write_text(content)
        
        with pytest.raises(ValueError, match="Could not find version in CHANGELOG.md"):
            extract_version_and_notes(temp_changelog)
    
    def test_empty_release_notes(self, temp_changelog):
        """Test error when release notes are empty."""
        content = """# Changelog

## [1.0.0] - 2026-02-04

## [0.9.0] - 2026-02-01

### Added
- Previous feature
"""
        temp_changelog.write_text(content)
        
        with pytest.raises(ValueError, match="No release notes found for version 1.0.0"):
            extract_version_and_notes(temp_changelog)


class TestCreateGithubRelease:
    """Test GitHub release creation."""
    
    @patch('subprocess.run')
    def test_create_release_success(self, mock_run):
        """Test successful GitHub release creation."""
        mock_run.return_value = MagicMock(returncode=0)
        
        result = create_github_release("1.2.3", "### Added\n- New feature")
        
        assert result == 0
        mock_run.assert_called_once()
        args = mock_run.call_args[0][0]
        assert args == [
            'gh', 'release', 'create', 'v1.2.3',
            '--title', 'v1.2.3',
            '--notes', '### Added\n- New feature',
            '--latest'
        ]
    
    @patch('subprocess.run')
    def test_create_release_subprocess_error(self, mock_run):
        """Test handling of subprocess error."""
        mock_run.side_effect = subprocess.CalledProcessError(
            1, 'gh', stderr='API error'
        )
        
        result = create_github_release("1.2.3", "### Added\n- New feature")
        
        assert result == 1
    
    @patch('subprocess.run')
    def test_create_release_gh_not_found(self, mock_run):
        """Test handling when gh CLI is not found."""
        mock_run.side_effect = FileNotFoundError()
        
        result = create_github_release("1.2.3", "### Added\n- New feature")
        
        assert result == 1
    
    def test_dry_run_mode(self, capsys):
        """Test dry run mode doesn't execute commands."""
        result = create_github_release("1.2.3", "### Added\n- New feature", dry_run=True)
        
        assert result == 0
        captured = capsys.readouterr()
        assert "Would create GitHub release:" in captured.out
        assert "Tag: v1.2.3" in captured.out
        assert "Title: v1.2.3" in captured.out
        assert "### Added" in captured.out
    
    def test_dry_run_long_notes(self, capsys):
        """Test dry run with long release notes shows preview."""
        long_notes = "\n".join([f"Line {i}" for i in range(10)])
        
        result = create_github_release("1.2.3", long_notes, dry_run=True)
        
        assert result == 0
        captured = capsys.readouterr()
        assert "Release notes preview:" in captured.out
        assert "..." in captured.out  # Should truncate long notes


class TestMain:
    """Test main function integration."""
    
    @patch('create_release.extract_version_and_notes')
    @patch('create_release.create_github_release')
    def test_main_success(self, mock_create, mock_extract):
        """Test successful main function execution."""
        mock_extract.return_value = ("1.2.3", "### Added\n- Feature")
        mock_create.return_value = 0
        
        result = main()
        
        assert result == 0
        mock_extract.assert_called_once()
        mock_create.assert_called_once_with("1.2.3", "### Added\n- Feature", False)
    
    @patch('create_release.extract_version_and_notes')
    def test_main_extraction_error(self, mock_extract):
        """Test main function with extraction error."""
        mock_extract.side_effect = ValueError("Test error")
        
        result = main()
        
        assert result == 1
    
    @patch('create_release.extract_version_and_notes')
    def test_main_file_not_found(self, mock_extract):
        """Test main function with file not found error."""
        mock_extract.side_effect = FileNotFoundError("CHANGELOG.md not found")
        
        result = main()
        
        assert result == 1
    
    @patch('create_release.extract_version_and_notes')
    @patch('create_release.create_github_release')
    def test_main_dry_run(self, mock_create, mock_extract):
        """Test main function in dry run mode."""
        mock_extract.return_value = ("1.2.3", "### Added\n- Feature")
        mock_create.return_value = 0
        
        result = main(dry_run=True)
        
        assert result == 0
        mock_create.assert_called_once_with("1.2.3", "### Added\n- Feature", True)