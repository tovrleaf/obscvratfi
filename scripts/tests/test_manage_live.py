#!/usr/bin/env python3
"""
Unit tests for manage_live.py

Tests the LiveManager class functionality including:
- YAML file parsing and writing
- File operations
- Interactive prompts (mocked)
- Error handling
"""

import subprocess

# Import the module under test
import sys
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent))
from manage_live import LiveManager


class TestLiveManager:
    """Test cases for LiveManager class."""

    @pytest.fixture(autouse=True)
    def mock_fzf(self):
        """Mock shutil.which to disable fzf in all tests."""
        with patch('manage_live.shutil.which', return_value=None):
            yield

    @pytest.fixture
    def temp_project(self):
        """Create temporary project structure."""
        with tempfile.TemporaryDirectory() as temp_dir:
            project_root = Path(temp_dir)
            live_dir = project_root / "website" / "data" / "live"
            content_dir = project_root / "website" / "content" / "live"
            script_dir = project_root / "scripts"

            live_dir.mkdir(parents=True)
            content_dir.mkdir(parents=True)
            script_dir.mkdir(parents=True)

            yield project_root

    @pytest.fixture
    def manager(self, temp_project):
        """Create LiveManager instance with temp project."""
        return LiveManager(temp_project)

    def test_init(self, temp_project):
        """Test LiveManager initialization."""
        manager = LiveManager(temp_project)

        assert manager.project_root == temp_project
        assert manager.live_dir == temp_project / "website" / "data" / "live"
        assert manager.content_dir == temp_project / "website" / "content" / "live"
        assert manager.script_dir == temp_project / "scripts"

    def test_create_slug(self, manager):
        """Test slug creation from text."""
        assert manager.create_slug("Test Event") == "test-event"
        assert manager.create_slug("Noise Space XV") == "noise-space-xv"
        assert manager.create_slug("Special!@#$%^&*()Characters") == "specialcharacters"
        assert manager.create_slug("Multiple   Spaces") == "multiple-spaces"

    @patch('urllib.request.urlretrieve')
    def test_download_poster_success(self, mock_urlretrieve, manager):
        """Test successful poster download."""
        output_path = manager.project_root / "test_poster.jpg"

        result = manager.download_poster("https://example.com/poster.jpg", output_path)

        assert result is True
        mock_urlretrieve.assert_called_once_with("https://example.com/poster.jpg", output_path)
        assert output_path.parent.exists()

    @patch('urllib.request.urlretrieve', side_effect=Exception("Download failed"))
    def test_download_poster_failure(self, mock_urlretrieve, manager):
        """Test failed poster download."""
        output_path = manager.project_root / "test_poster.jpg"

        result = manager.download_poster("https://example.com/poster.jpg", output_path)

        assert result is False

    @patch('builtins.input', side_effect=['line1', 'line2', 'END'])
    def test_get_multiline_input(self, mock_input, manager):
        """Test multiline input collection."""
        result = manager.get_multiline_input("Enter text")

        assert result == "line1\nline2"

    @patch('builtins.input', side_effect=['Artist 1', 'http://artist1.com', 'Artist 2', '', ''])
    def test_get_performers(self, mock_input, manager):
        """Test performer collection."""
        result = manager.get_performers()

        expected = [
            {"name": "Artist 1", "url": "http://artist1.com"},
            {"name": "Artist 2"}
        ]
        assert result == expected

    def test_get_live_files(self, manager):
        """Test getting live performance files."""
        # Create test files
        (manager.live_dir / "2025-01-01-test-event.yaml").touch()
        (manager.live_dir / "2025-01-02-another-event.yaml").touch()
        (manager.live_dir / "_index.md").touch()  # Should be ignored

        files = manager.get_live_files()

        assert len(files) == 2
        assert all(f.suffix == ".yaml" for f in files)
        assert not any(f.name == "_index.md" for f in files)

    def test_parse_live_file(self, manager):
        """Test parsing live performance YAML file."""
        test_content = """---
title: "Test Event"
date: "2025-01-01"
venue: "Test Venue"
location: "Test City"
draft: false
---

This is the event description."""

        test_file = manager.live_dir / "test.yaml"
        test_file.write_text(test_content)

        data, body = manager.parse_live_file(test_file)

        assert data['title'] == "Test Event"
        assert data['date'] == "2025-01-01"
        assert data['venue'] == "Test Venue"
        assert body == "This is the event description."

    def test_parse_live_file_invalid(self, manager):
        """Test parsing invalid YAML file."""
        test_file = manager.live_dir / "invalid.yaml"
        test_file.write_text("Invalid content without frontmatter")

        with pytest.raises(ValueError, match="Invalid YAML frontmatter"):
            manager.parse_live_file(test_file)

    def test_write_live_file(self, manager):
        """Test writing live performance YAML file."""
        data = {
            'title': 'Test Event',
            'date': '2025-01-01',
            'venue': 'Test Venue',
            'location': 'Test City',
            'draft': False
        }
        body = "Event description"

        test_file = manager.live_dir / "test.yaml"
        manager.write_live_file(test_file, data, body)

        # Verify file was written correctly
        parsed_data, parsed_body = manager.parse_live_file(test_file)
        assert parsed_data == data
        assert parsed_body == body

    @patch('subprocess.run')
    def test_run_generate_markdown_success(self, mock_run, manager):
        """Test successful markdown generation."""
        # Create the script file
        script_path = manager.script_dir / "generate-markdown.sh"
        script_path.touch()

        manager.run_generate_markdown("live")

        mock_run.assert_called_once_with([str(script_path), "live"], check=True)

    @patch('subprocess.run')
    def test_run_generate_markdown_missing_script(self, mock_run, manager):
        """Test markdown generation with missing script."""
        manager.run_generate_markdown("live")

        mock_run.assert_not_called()

    @patch('subprocess.run', side_effect=subprocess.CalledProcessError(1, 'cmd'))
    def test_run_generate_markdown_failure(self, mock_run, manager):
        """Test failed markdown generation."""
        script_path = manager.script_dir / "generate-markdown.sh"
        script_path.touch()

        # Should not raise exception, just print error
        manager.run_generate_markdown("live")

        mock_run.assert_called_once()

    @patch('builtins.input', side_effect=[
        'Test Event',  # event_name
        '2025-01-01',  # date
        'Test Venue',  # venue
        'Test City',   # city
        'line1', 'line2', 'END',  # description
        '',  # poster_input
        '',  # event_url
        '',  # performers (finish immediately)
        'n'  # don't open editor
    ])
    @patch('subprocess.run')
    def test_create_live_basic(self, mock_run, mock_input, manager):
        """Test creating basic live performance."""
        # Create script file for generate-markdown
        script_path = manager.script_dir / "generate-markdown.sh"
        script_path.touch()

        manager.create_live()

        # Check file was created
        expected_file = manager.live_dir / "2025-01-01-test-event.yaml"
        assert expected_file.exists()

        # Check file content
        data, body = manager.parse_live_file(expected_file)
        assert data['title'] == 'Test Event'
        assert data['date'] == '2025-01-01'
        assert data['venue'] == 'Test Venue'
        assert data['location'] == 'Test City'
        assert body == 'line1\nline2'

    @patch('builtins.input', side_effect=['Test Event', 'invalid-date'])
    def test_create_live_invalid_date(self, mock_input, manager):
        """Test creating live performance with invalid date."""
        manager.create_live()

        # No file should be created
        assert len(list(manager.live_dir.glob("*.yaml"))) == 0

    @patch('builtins.input', side_effect=['', '2025-01-01', ''])
    def test_create_live_missing_venue(self, mock_input, manager):
        """Test creating live performance with missing venue."""
        manager.create_live()

        # No file should be created
        assert len(list(manager.live_dir.glob("*.yaml"))) == 0

    @patch('shutil.copy2')
    @patch('builtins.input', side_effect=[
        'Test Event',
        '2025-01-01',
        'Test Venue',
        'Test City',
        'END',  # empty description
        '/path/to/poster.jpg',  # poster_input
        '',  # event_url
        '',  # performers
        'y',  # overwrite existing file
        'n'   # don't open editor
    ])
    @patch('subprocess.run')
    def test_create_live_with_local_poster(self, mock_run, mock_input, mock_copy, manager):
        """Test creating live performance with local poster."""
        script_path = manager.script_dir / "generate-markdown.sh"
        script_path.touch()

        # Create existing file to test overwrite
        existing_file = manager.live_dir / "2025-01-01-test-event.yaml"
        existing_file.write_text("---\ntitle: Old\n---\nOld content")

        # Mock Path.exists to return True for poster
        with patch.object(Path, 'exists', return_value=True):
            manager.create_live()

        # Check poster was copied
        mock_copy.assert_called_once()

        # Check file content includes poster
        data, _ = manager.parse_live_file(existing_file)
        assert 'poster' in data

    def test_list_live_empty(self, manager, capsys):
        """Test listing live performances when none exist."""
        with patch('builtins.input'):  # Mock the "Press Enter" prompt
            manager.list_live()

        captured = capsys.readouterr()
        assert "No live performances found" in captured.out

    def test_list_live_with_files(self, manager, capsys):
        """Test listing live performances with existing files."""
        # Create test file
        test_content = """---
title: "Test Event"
date: 2025-01-01
venue: "Test Venue"
location: "Test City"
---

Description"""

        test_file = manager.live_dir / "2025-01-01-test-event.yaml"
        test_file.write_text(test_content)

        with patch('builtins.input'):  # Mock the "Press Enter" prompt
            manager.list_live()

        captured = capsys.readouterr()
        assert "Test Event" in captured.out
        assert "Test City" in captured.out


    @patch('builtins.input', side_effect=['1'])
    def test_select_live_file_valid(self, mock_input, manager):
        """Test selecting valid live performance file."""
        # Create test file
        test_content = """---
title: "Test Event"
date: 2025-01-01
---
Description"""

        test_file = manager.live_dir / "2025-01-01-test-event.yaml"
        test_file.write_text(test_content)

        result = manager.select_live_file("Test Action")

        assert result == test_file


    @patch('builtins.input', side_effect=['0'])
    def test_select_live_file_cancel(self, mock_input, manager):
        """Test canceling live performance selection."""
        result = manager.select_live_file("Test Action")

        assert result is None


    @patch('builtins.input', side_effect=['999'])
    def test_select_live_file_invalid(self, mock_input, manager):
        """Test selecting invalid live performance number."""
        # Create test file
        test_file = manager.live_dir / "2025-01-01-test-event.yaml"
        test_file.write_text("---\ntitle: Test\n---\nBody")

        result = manager.select_live_file("Test Action")

        assert result is None


    @patch('builtins.input', side_effect=['1', 'y'])
    def test_delete_live_confirm(self, mock_input, manager):
        """Test deleting live performance with confirmation."""
        # Create test file
        test_file = manager.live_dir / "2025-01-01-test-event.yaml"
        test_file.write_text("---\ntitle: Test Event\n---\nBody")

        # Create script for generate-markdown
        script_path = manager.script_dir / "generate-markdown.sh"
        script_path.touch()

        with patch('subprocess.run'):
            manager.delete_live()

        assert not test_file.exists()

    @patch('builtins.input', side_effect=[KeyboardInterrupt()])
    def test_show_menu_keyboard_interrupt(self, mock_input, manager):
        """Test menu handling keyboard interrupt."""
        manager.show_menu()  # Should exit gracefully

    @patch('builtins.input', side_effect=['5'])
    def test_show_menu_exit(self, mock_input, manager):
        """Test menu exit option."""
        manager.show_menu()  # Should exit without error

    @patch('builtins.input', side_effect=[EOFError()])
    def test_get_multiline_input_eof(self, mock_input, manager):
        """Test multiline input with EOF."""
        result = manager.get_multiline_input("Enter text")
        assert result == ""

    @patch('builtins.input', side_effect=[KeyboardInterrupt()])
    def test_get_performers_keyboard_interrupt(self, mock_input, manager):
        """Test performer collection with keyboard interrupt."""
        result = manager.get_performers()
        assert result == []

    @patch('urllib.request.urlretrieve')
    @patch('builtins.input', side_effect=[
        'Test Event',
        '2025-01-01',
        'Test Venue',
        'Test City',
        'END',
        'https://example.com/poster.jpg',  # URL poster
        '',
        '',
        'n'
    ])
    @patch('subprocess.run')
    def test_create_live_with_url_poster(self, mock_run, mock_input, mock_urlretrieve, manager):
        """Test creating live performance with URL poster."""
        script_path = manager.script_dir / "generate-markdown.sh"
        script_path.touch()

        manager.create_live()

        # Check URL download was attempted
        mock_urlretrieve.assert_called_once()

    @patch('builtins.input', side_effect=[EOFError()])
    def test_create_live_eof(self, mock_input, manager):
        """Test create live with EOF."""
        manager.create_live()  # Should exit gracefully

    @patch('builtins.input', side_effect=['', '2025-01-01', ''])
    def test_create_live_missing_city(self, mock_input, manager):
        """Test creating live performance with missing city."""
        manager.create_live()

        # No file should be created
        assert len(list(manager.live_dir.glob("*.yaml"))) == 0

    def test_select_live_file_no_files(self, manager):
        """Test selecting live file when none exist."""
        result = manager.select_live_file("Test Action")
        assert result is None

    @patch('builtins.input', side_effect=[EOFError()])
    def test_select_live_file_eof(self, mock_input, manager):
        """Test selecting live file with EOF."""
        # Create test file
        test_file = manager.live_dir / "2025-01-01-test-event.yaml"
        test_file.write_text("---\ntitle: Test\n---\nBody")

        result = manager.select_live_file("Test Action")
        assert result is None

    @patch('builtins.input', side_effect=['1', 'n'])
    def test_delete_live_cancel(self, mock_input, manager):
        """Test canceling live performance deletion."""
        # Create test file
        test_file = manager.live_dir / "2025-01-01-test-event.yaml"
        test_file.write_text("---\ntitle: Test Event\n---\nBody")

        manager.delete_live()

        assert test_file.exists()


class TestMainFunction:
    """Test cases for main function and CLI."""

    @patch('manage_live.LiveManager')
    @patch('os.chdir')
    def test_main_success(self, mock_chdir, mock_manager_class):
        """Test successful main function execution."""
        from manage_live import main

        mock_manager = MagicMock()
        mock_manager_class.return_value = mock_manager

        result = main()

        assert result == 0
        mock_manager.show_menu.assert_called_once()

    def test_main_missing_yaml(self):
        """Test main function with missing PyYAML."""
        from manage_live import main

        with patch('builtins.__import__', side_effect=ImportError()):
            result = main()

        assert result == 1

    def test_parse_args(self):
        """Test argument parsing."""
        from manage_live import parse_args

        with patch('sys.argv', ['manage_live.py']):
            args = parse_args()

        # Should not raise exception with no arguments
        assert args is not None


# Integration-style tests
class TestIntegration:
    """Integration tests for complete workflows."""

    @pytest.fixture(autouse=True)
    def mock_fzf(self):
        """Mock shutil.which to disable fzf in all tests."""
        with patch('manage_live.shutil.which', return_value=None):
            yield

    @pytest.fixture
    def temp_project_with_script(self):
        """Create temp project with generate-markdown script."""
        with tempfile.TemporaryDirectory() as temp_dir:
            project_root = Path(temp_dir)
            live_dir = project_root / "website" / "data" / "live"
            script_dir = project_root / "scripts"

            live_dir.mkdir(parents=True)
            script_dir.mkdir(parents=True)

            # Create mock generate-markdown script
            script_path = script_dir / "generate-markdown.sh"
            script_path.write_text("#!/bin/bash\necho 'Generated markdown'")
            script_path.chmod(0o755)

            yield project_root

    @patch('builtins.input', side_effect=[
        'Test Event', '2025-01-01', 'Test Venue', 'Test City',
        'Event description', 'END', '', '', '', 'n'
    ])
    @patch('subprocess.run')
    def test_create_and_list_workflow(self, mock_run, mock_input, temp_project_with_script):
        """Test complete create and list workflow."""
        manager = LiveManager(temp_project_with_script)

        # Create live performance
        manager.create_live()

        # Verify file exists
        files = manager.get_live_files()
        assert len(files) == 1

        # Verify content
        data, body = manager.parse_live_file(files[0])
        assert data['title'] == 'Test Event'
        assert body == 'Event description'


    @patch('builtins.input', side_effect=[
        '1',  # select first file
        'Updated Event', '2025-01-02', 'Updated Venue', 'Updated City',
        'Updated description', 'END', '', ''
    ])
    @patch('subprocess.run')
    def test_edit_workflow(self, mock_run, mock_input, temp_project_with_script):
        """Test complete edit workflow."""
        manager = LiveManager(temp_project_with_script)

        # Create initial file
        initial_data = {
            'title': 'Original Event',
            'date': '2025-01-01',
            'venue': 'Original Venue',
            'location': 'Original City',
            'draft': False
        }
        initial_file = manager.live_dir / "2025-01-01-original-event.yaml"
        manager.write_live_file(initial_file, initial_data, "Original description")

        # Edit the file
        manager.edit_live()

        # Verify changes
        files = manager.get_live_files()
        assert len(files) == 1

        data, body = manager.parse_live_file(files[0])
        assert data['title'] == 'Updated Event'
        assert data['date'] == '2025-01-02'
        assert body == 'Updated description'

        # Original file should be gone (renamed)
        assert not initial_file.exists()


if __name__ == '__main__':
    pytest.main([__file__])
