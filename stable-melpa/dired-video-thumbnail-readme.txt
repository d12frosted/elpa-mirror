This package provides image-dired style thumbnail viewing for video files.
It uses ffmpeg to extract thumbnails and displays them in a grid layout.

Features:
- Persistent thumbnail caching (thumbnails are generated once and reused)
- Async thumbnail generation (Emacs remains responsive)
- Grid layout display similar to image-dired
- Click to play with customisable video player
- Works with marked files or all videos in directory

Requirements:
- ffmpeg must be installed and in your PATH

Usage:
In a Dired buffer, call `dired-video-thumbnail' to display thumbnails
for all video files (or marked files if any are marked).

Keybindings in the thumbnail buffer:
- RET / mouse-1: Play video
- g: Regenerate thumbnail for video at point
- G: Regenerate all thumbnails
- d: Open Dired at video's directory
- q: Quit thumbnail buffer
- n/p: Next/previous video
- +/-: Increase/decrease thumbnail size
