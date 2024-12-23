Grab link and title from Firefox and Chromium, insert into Emacs buffer as
plain, markdown or org link.

To use, invoke `M-x grab-x-link' and other commands provided by this package.

Prerequisite:
- xdotool(1)
- xsel(1) or xclip(1) if you are running Emacs inside a terminal emulator

Changes:
- 2024-12-24 v0.6 Support Vivaldi
- 2018-02-05 v0.5 Support Google Chrome
- 2016-12-01 v0.4 Handle case that app is not running
- 2016-12-01 v0.3 Add the command `grab-x-link'
- 2016-11-19 v0.2 Rename grab-x11-link to grab-x-link
- 2016-11-19 v0.1 Support Emacs running inside terminal emulator
