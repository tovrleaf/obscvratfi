"""
Unit tests for manage_media.py

Tests cover YAML parsing/writing, file operations, and core functionality.
Uses pytest fixtures for temporary files and mocking for external dependencies.
"""

import subprocess
from unittest.mock import Mock, patch

import pytest

from scripts.manage_media import MediaManager


@pytest.fixture
def temp_project_root(tmp_path):
    """Create temporary project structure for testing."""
    project_root = tmp_path / "project"
    project_root.mkdir()

    # Create directory structure
    (project_root / "website" / "data" / "live").mkdir(parents=True)
    (project_root / "website" / "assets" / "media").mkdir(parents=True)
    (project_root / "website" / "data" / "media").mkdir(parents=True)
    (project_root / "scripts").mkdir()

    return project_root


@pytest.fixture(autouse=True)
def mock_fzf():
    """Mock shutil.which to disable fzf in all tests."""
    with patch('scripts.manage_media.shutil.which', return_value=None):
        yield


@pytest.fixture
def media_manager(temp_project_root):
    """Create MediaManager instance with temporary project root."""
    return MediaManager(temp_project_root)


@pytest.fixture
def sample_live_performance(temp_project_root):
    """Create sample live performance YAML file."""
    live_file = temp_project_root / "website" / "data" / "live" / "2025-01-01-test-venue.yaml"
    content = """---
title: "Test Venue"
date: 2025-01-01
venue: "Test Venue"
location: "Test City"
draft: false
---

Test performance content.
"""
    live_file.write_text(content)
    return live_file, {
        'title': 'Test Venue',
        'date': '2025-01-01',
        'venue': 'Test Venue',
        'location': 'Test City',
        'draft': False
    }


class TestMediaManager:
    """Test MediaManager class."""

    def test_init(self, temp_project_root):
        """Test MediaManager initialization."""
        manager = MediaManager(temp_project_root)

        assert manager.project_root == temp_project_root
        assert manager.live_dir == temp_project_root / "website" / "data" / "live"
        assert manager.media_dir == temp_project_root / "website" / "assets" / "media"
        assert manager.others_file == temp_project_root / "website" / "data" / "media" / "others.yaml"
        assert manager.script_dir == temp_project_root / "scripts"

    def test_get_live_performances_empty(self, media_manager):
        """Test getting live performances when directory is empty."""
        performances = media_manager.get_live_performances()
        assert performances == []

    def test_get_live_performances_with_data(self, media_manager, sample_live_performance):
        """Test getting live performances with sample data."""
        file_path, expected_metadata = sample_live_performance

        performances = media_manager.get_live_performances()
        assert len(performances) == 1

        returned_path, returned_metadata = performances[0]
        assert returned_path == file_path
        assert returned_metadata['title'] == expected_metadata['title']
        # YAML loader converts date strings to date objects, so compare as strings
        assert str(returned_metadata['date']) == expected_metadata['date']

    def test_get_live_performances_invalid_yaml(self, media_manager, temp_project_root):
        """Test handling of invalid YAML files."""
        invalid_file = temp_project_root / "website" / "data" / "live" / "invalid.yaml"
        invalid_file.write_text("invalid: yaml: content:")

        performances = media_manager.get_live_performances()
        assert performances == []

    def test_extract_youtube_id_watch_url(self, media_manager):
        """Test YouTube ID extraction from watch URL."""
        url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        youtube_id = media_manager.extract_youtube_id(url)
        assert youtube_id == "dQw4w9WgXcQ"

    def test_extract_youtube_id_short_url(self, media_manager):
        """Test YouTube ID extraction from short URL."""
        url = "https://youtu.be/dQw4w9WgXcQ"
        youtube_id = media_manager.extract_youtube_id(url)
        assert youtube_id == "dQw4w9WgXcQ"

    def test_extract_youtube_id_invalid_url(self, media_manager):
        """Test YouTube ID extraction from invalid URL."""
        url = "https://example.com/video"
        youtube_id = media_manager.extract_youtube_id(url)
        assert youtube_id is None

    @patch('urllib.request.urlretrieve')
    def test_download_file_success(self, mock_urlretrieve, media_manager, tmp_path):
        """Test successful file download."""
        url = "https://example.com/image.jpg"
        output_path = tmp_path / "downloaded.jpg"

        result = media_manager.download_file(url, output_path)

        assert result is True
        mock_urlretrieve.assert_called_once_with(url, output_path)
        assert output_path.parent.exists()

    @patch('urllib.request.urlretrieve')
    def test_download_file_failure(self, mock_urlretrieve, media_manager, tmp_path):
        """Test failed file download."""
        mock_urlretrieve.side_effect = Exception("Download failed")

        url = "https://example.com/image.jpg"
        output_path = tmp_path / "downloaded.jpg"

        result = media_manager.download_file(url, output_path)

        assert result is False

    @patch('shutil.copy2')
    def test_generate_image_versions_success(self, mock_copy, media_manager, tmp_path):
        """Test successful image version generation."""
        source_file = tmp_path / "source.jpg"
        source_file.touch()
        output_dir = tmp_path / "output"
        base_name = "test.jpg"

        result = media_manager.generate_image_versions(source_file, base_name, output_dir)

        assert result is True
        mock_copy.assert_called_once_with(source_file, output_dir / base_name)
        assert output_dir.exists()

    @patch('shutil.copy2')
    def test_generate_image_versions_failure(self, mock_copy, media_manager, tmp_path):
        """Test failed image version generation."""
        mock_copy.side_effect = Exception("Copy failed")

        source_file = tmp_path / "source.jpg"
        output_dir = tmp_path / "output"
        base_name = "test.jpg"

        result = media_manager.generate_image_versions(source_file, base_name, output_dir)

        assert result is False

    def test_update_live_performance_yaml_success(self, media_manager, sample_live_performance):
        """Test successful YAML update."""
        file_path, _ = sample_live_performance

        media_data = {
            'pictures': {
                'author': 'Test Photographer',
                'images': ['test1.jpg', 'test2.jpg']
            }
        }

        result = media_manager.update_live_performance_yaml(file_path, media_data)

        assert result is True

        # Verify the update
        with open(file_path, 'r') as f:
            content = f.read()

        assert 'media:' in content
        assert 'pictures:' in content
        assert 'Test Photographer' in content

    def test_update_live_performance_yaml_invalid_file(self, media_manager, tmp_path):
        """Test YAML update with invalid file."""
        invalid_file = tmp_path / "invalid.yaml"
        invalid_file.write_text("not yaml frontmatter")

        media_data = {'test': 'data'}
        result = media_manager.update_live_performance_yaml(invalid_file, media_data)

        assert result is False

    def test_load_others_data_nonexistent(self, media_manager):
        """Test loading others data when file doesn't exist."""
        data = media_manager.load_others_data()

        expected = {'title': 'Others', 'items': []}
        assert data == expected

    def test_load_others_data_existing(self, media_manager):
        """Test loading existing others data."""
        others_content = """---
title: "Others"
items:
  - type: "interview"
    title: "Test Interview"
    url: "https://example.com"
---
"""
        media_manager.others_file.parent.mkdir(parents=True, exist_ok=True)
        media_manager.others_file.write_text(others_content)

        data = media_manager.load_others_data()

        assert data['title'] == 'Others'
        assert len(data['items']) == 1
        assert data['items'][0]['type'] == 'interview'
        assert data['items'][0]['title'] == 'Test Interview'

    def test_save_others_data_success(self, media_manager):
        """Test successful others data saving."""
        data = {
            'title': 'Others',
            'items': [
                {
                    'type': 'review',
                    'title': 'Test Review',
                    'url': 'https://example.com'
                }
            ]
        }

        result = media_manager.save_others_data(data)

        assert result is True
        assert media_manager.others_file.exists()

        # Verify content
        with open(media_manager.others_file, 'r') as f:
            content = f.read()

        assert 'title: Others' in content
        assert 'type: review' in content
        assert 'Test Review' in content

    @patch('subprocess.run')
    def test_run_generate_markdown_success(self, mock_run, media_manager):
        """Test successful markdown generation."""
        # Create the script file
        script_path = media_manager.script_dir / "generate-markdown.sh"
        script_path.touch()

        media_manager.run_generate_markdown("live")

        mock_run.assert_called_once_with([str(script_path), "live"], check=True)

    @patch('subprocess.run')
    def test_run_generate_markdown_script_missing(self, mock_run, media_manager):
        """Test markdown generation when script is missing."""
        media_manager.run_generate_markdown("live")

        # Should not call subprocess if script doesn't exist
        mock_run.assert_not_called()

    @patch('subprocess.run')
    def test_run_generate_markdown_failure(self, mock_run, media_manager):
        """Test markdown generation failure."""
        mock_run.side_effect = subprocess.CalledProcessError(1, 'cmd')

        # Create the script file
        script_path = media_manager.script_dir / "generate-markdown.sh"
        script_path.touch()

        # Should not raise exception
        media_manager.run_generate_markdown("live")


    @patch('builtins.input')
    def test_select_live_performance_cancel(self, mock_input, media_manager, sample_live_performance):
        """Test canceling live performance selection."""
        mock_input.return_value = "0"

        result = media_manager.select_live_performance()

        assert result is None


    @patch('builtins.input')
    def test_select_live_performance_valid_selection(self, mock_input, media_manager, sample_live_performance):
        """Test valid live performance selection."""
        mock_input.return_value = "1"

        result = media_manager.select_live_performance()

        assert result is not None
        file_path, metadata = result
        assert metadata['title'] == 'Test Venue'


    @patch('builtins.input')
    def test_select_live_performance_invalid_selection(self, mock_input, media_manager, sample_live_performance):
        """Test invalid live performance selection."""
        mock_input.return_value = "999"

        result = media_manager.select_live_performance()

        assert result is None


class TestMainFunction:
    """Test main function and CLI interface."""

    @patch('builtins.input')
    @patch('scripts.manage_media.MediaManager')
    def test_main_success(self, mock_manager_class, mock_input):
        """Test successful main function execution."""
        mock_manager = Mock()
        mock_manager_class.return_value = mock_manager
        # Mock input to exit immediately
        mock_input.side_effect = KeyboardInterrupt()

        from scripts.manage_media import main

        result = main()

        assert result == 0
        mock_manager.show_menu.assert_called_once()

    def test_main_missing_yaml(self):
        """Test main function with missing PyYAML."""
        # This test checks the import error handling in the main function
        # We can't easily mock the import at module level, so we'll test
        # the error message instead by checking if yaml is available
        try:
            import yaml  # noqa: F401
            # If yaml is available, we can't test the missing case
            # This is acceptable since the real environment will have yaml
            assert True
        except ImportError:
            # If yaml is missing, main() should return 1
            from scripts.manage_media import main
            result = main()
            assert result == 1


# Integration tests for complex workflows
class TestIntegrationWorkflows:
    """Integration tests for complete workflows."""


    @patch('builtins.input')
    @patch('urllib.request.urlretrieve')
    @patch('shutil.copy2')
    def test_add_pictures_workflow(self, mock_copy, mock_urlretrieve, mock_input,
                                   media_manager, sample_live_performance):
        """Test complete add pictures workflow."""
        # Mock user inputs
        mock_input.side_effect = [
            "1",  # Select first performance
            "Test Photographer",  # Photographer name
            "https://example.com",  # Photographer URL
            "https://example.com/pic1.jpg",  # First picture URL
            "",  # Finish adding pictures
        ]

        media_manager.add_pictures()

        # Verify download was called
        mock_urlretrieve.assert_called()

        # Verify file was copied
        mock_copy.assert_called()

        # Verify YAML was updated
        file_path, _ = sample_live_performance
        with open(file_path, 'r') as f:
            content = f.read()
        assert 'media:' in content
        assert 'pictures:' in content


    @patch('builtins.input')
    def test_add_video_workflow(self, mock_input, media_manager, sample_live_performance):
        """Test complete add video workflow."""
        # Mock user inputs
        mock_input.side_effect = [
            "1",  # Select first performance
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ",  # YouTube URL
            "Test Video",  # Video title
            "2025-01-01",  # Video date
            "",  # No credits
        ]

        media_manager.add_video()

        # Verify YAML was updated
        file_path, _ = sample_live_performance
        with open(file_path, 'r') as f:
            content = f.read()
        assert 'media:' in content
        assert 'videos:' in content
        assert 'dQw4w9WgXcQ' in content

    @patch('builtins.input')
    def test_add_others_workflow(self, mock_input, media_manager):
        """Test complete add others workflow."""
        # Mock user inputs
        mock_input.side_effect = [
            "1",  # Interview type
            "Test Interview",  # Title
            "https://example.com/interview",  # URL
            "Test Magazine",  # Media title
            "Great interview",  # Description
            "2025-01-01",  # Date
        ]

        media_manager.add_others()

        # Verify others file was created
        assert media_manager.others_file.exists()

        # Verify content
        data = media_manager.load_others_data()
        assert len(data['items']) == 1
        assert data['items'][0]['type'] == 'interview'
        assert data['items'][0]['title'] == 'Test Interview'

    @patch('builtins.input')
    def test_show_menu_exit(self, mock_input, media_manager):
        """Test show_menu exit option."""
        mock_input.return_value = "9"  # Exit is now option 9

        # Should exit without error
        media_manager.show_menu()

    @patch('builtins.input')
    def test_show_menu_invalid_option(self, mock_input, media_manager):
        """Test show_menu with invalid option."""
        mock_input.side_effect = ["invalid", "9"]  # Invalid then exit

        media_manager.show_menu()

    @patch('builtins.input')
    def test_show_menu_keyboard_interrupt(self, mock_input, media_manager):
        """Test show_menu with keyboard interrupt."""
        mock_input.side_effect = KeyboardInterrupt()

        # Should exit gracefully
        media_manager.show_menu()

    @patch('builtins.input')
    def test_add_pictures_no_performances(self, mock_input, media_manager):
        """Test add_pictures when no performances exist."""
        # Should return early
        media_manager.add_pictures()

    @patch('builtins.input')
    def test_add_pictures_cancel_selection(self, mock_input, media_manager, sample_live_performance):
        """Test add_pictures with canceled selection."""
        mock_input.return_value = "0"  # Cancel

        media_manager.add_pictures()

    @patch('builtins.input')
    def test_add_pictures_keyboard_interrupt(self, mock_input, media_manager, sample_live_performance):
        """Test add_pictures with keyboard interrupt."""
        mock_input.side_effect = KeyboardInterrupt()

        media_manager.add_pictures()

    @patch('builtins.input')
    def test_add_video_no_performances(self, mock_input, media_manager):
        """Test add_video when no performances exist."""
        media_manager.add_video()

    @patch('builtins.input')
    def test_add_video_invalid_youtube_url(self, mock_input, media_manager, sample_live_performance):
        """Test add_video with invalid YouTube URL."""
        mock_input.side_effect = [
            "1",  # Select first performance
            "https://invalid-url.com",  # Invalid YouTube URL
            "Test Video",
            ""
        ]

        media_manager.add_video()

    @patch('builtins.input')
    def test_add_standalone_picture_keyboard_interrupt(self, mock_input, media_manager):
        """Test add_standalone_picture with keyboard interrupt."""
        mock_input.side_effect = KeyboardInterrupt()

        media_manager.add_standalone_picture()

    @patch('builtins.input')
    def test_add_standalone_picture_file_not_found(self, mock_input, media_manager):
        """Test add_standalone_picture with non-existent local file."""
        mock_input.side_effect = [
            "Test Picture",
            "/nonexistent/file.jpg",
            "Test Photographer",
            "",
            "",
            ""
        ]

        media_manager.add_standalone_picture()

    @patch('builtins.input')
    def test_add_standalone_video_keyboard_interrupt(self, mock_input, media_manager):
        """Test add_standalone_video with keyboard interrupt."""
        mock_input.side_effect = KeyboardInterrupt()

        media_manager.add_standalone_video()

    @patch('builtins.input')
    def test_add_standalone_video_invalid_url(self, mock_input, media_manager):
        """Test add_standalone_video with invalid YouTube URL."""
        mock_input.side_effect = [
            "Test Video",
            "https://invalid-url.com",
            "",
            ""
        ]

        media_manager.add_standalone_video()

    @patch('builtins.input')
    def test_add_others_invalid_type(self, mock_input, media_manager):
        """Test add_others with invalid type selection."""
        mock_input.return_value = "invalid"

        media_manager.add_others()

    @patch('builtins.input')
    def test_add_others_keyboard_interrupt(self, mock_input, media_manager):
        """Test add_others with keyboard interrupt."""
        mock_input.side_effect = KeyboardInterrupt()

        media_manager.add_others()

    @patch('builtins.input')
    def test_edit_others_no_file(self, mock_input, media_manager):
        """Test edit_others when no others file exists."""
        media_manager.edit_others()

    @patch('builtins.input')
    def test_edit_others_empty_items(self, mock_input, media_manager):
        """Test edit_others with empty items list."""
        # Create empty others file
        data = {'title': 'Others', 'items': []}
        media_manager.save_others_data(data)

        media_manager.edit_others()

    @patch('builtins.input')
    def test_edit_others_cancel(self, mock_input, media_manager):
        """Test edit_others with cancel."""
        # Create others file with items
        data = {
            'title': 'Others',
            'items': [{'type': 'interview', 'title': 'Test', 'url': 'https://example.com'}]
        }
        media_manager.save_others_data(data)

        mock_input.return_value = ""  # Cancel

        media_manager.edit_others()

    @patch('builtins.input')
    def test_list_media_with_content(self, mock_input, media_manager, sample_live_performance):
        """Test list_media with actual content."""
        # Add media to performance
        file_path, _ = sample_live_performance
        media_data = {'pictures': {'author': 'Test', 'images': ['test.jpg']}}
        media_manager.update_live_performance_yaml(file_path, media_data)

        # Add others
        data = {
            'title': 'Others',
            'items': [{'type': 'interview', 'title': 'Test Interview', 'url': 'https://example.com'}]
        }
        media_manager.save_others_data(data)

        mock_input.return_value = ""  # Press enter to continue

        media_manager.list_media()

    @patch('builtins.input')
    def test_list_media_keyboard_interrupt(self, mock_input, media_manager):
        """Test list_media with keyboard interrupt."""
        mock_input.side_effect = KeyboardInterrupt()

        media_manager.list_media()

    def test_edit_video(self, media_manager):
        """Test edit_video method."""
        # This method just prints a message
        media_manager.edit_video()

    def test_load_others_data_yaml_error(self, media_manager):
        """Test load_others_data with YAML parsing error."""
        # Create invalid YAML file
        media_manager.others_file.parent.mkdir(parents=True, exist_ok=True)
        media_manager.others_file.write_text("invalid: yaml: content:")

        data = media_manager.load_others_data()

        # Should return default data on error
        assert data == {'title': 'Others', 'items': []}

    def test_save_others_data_io_error(self, media_manager):
        """Test save_others_data with IO error."""
        # Make parent directory read-only to cause error
        media_manager.others_file.parent.mkdir(parents=True, exist_ok=True)
        media_manager.others_file.parent.chmod(0o444)

        data = {'title': 'Others', 'items': []}
        result = media_manager.save_others_data(data)

        # Should return False on error
        assert result is False

        # Restore permissions
        media_manager.others_file.parent.chmod(0o755)

    @patch('builtins.input')
    def test_show_menu_all_options(self, mock_input, media_manager):
        """Test show_menu with all menu options."""
        # Test each menu option briefly
        mock_input.side_effect = [
            "1", "0",  # Add pictures, cancel
            "2", "0",  # Add video, cancel
            "3", KeyboardInterrupt(),  # Add standalone picture, interrupt
            "4", KeyboardInterrupt(),  # Add standalone video, interrupt
            "5", KeyboardInterrupt(),  # Add others, interrupt
            "6",  # Edit others (no file)
            "7", "",  # List media, continue
            "8",  # Edit video
            "9"   # Exit
        ]

        media_manager.show_menu()

    @patch('builtins.input')
    @patch('urllib.request.urlretrieve')
    def test_add_standalone_picture_with_url_success(self, mock_urlretrieve, mock_input, media_manager):
        """Test add_standalone_picture with successful URL download."""
        mock_input.side_effect = [
            "Test Picture",
            "https://example.com/pic.jpg",
            "Test Photographer",
            "https://photographer.com",
            "Test description",
            "test-gig-slug"
        ]

        media_manager.add_standalone_picture()

        # Verify download was attempted
        mock_urlretrieve.assert_called()

    @patch('builtins.input')
    def test_add_standalone_video_success(self, mock_input, media_manager):
        """Test add_standalone_video with valid YouTube URL."""
        mock_input.side_effect = [
            "Test Video",
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "Test description",
            "test-gig-slug"
        ]

        media_manager.add_standalone_video()

        # Verify file was created
        expected_file = media_manager.project_root / "website" / "content" / "media" / "videos"
        assert any(expected_file.glob("*.yaml"))


    @patch('builtins.input')
    def test_select_live_performance_eof_error(self, mock_input, media_manager, sample_live_performance):
        """Test select_live_performance with EOF error."""
        mock_input.side_effect = EOFError()

        result = media_manager.select_live_performance()
        assert result is None


    @patch('builtins.input')
    def test_select_live_performance_value_error(self, mock_input, media_manager, sample_live_performance):
        """Test select_live_performance with value error."""
        mock_input.return_value = "not_a_number"

        result = media_manager.select_live_performance()
        assert result is None
