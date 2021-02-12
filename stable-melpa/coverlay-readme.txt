Load coverlay.el in your .emacs

    (require 'coverlay)

Minor mode will toggle overlays in all buffers according to current lcov file

    M-x global-coverlay-mode

Load lcov file into coverlay buffer

    M-x coverlay-load-file /path/to/lcov-file

Load and watch a lcov file for changes

    M-x coverlay-watch-file /path/to/lcov-file

Toggle overlay for current buffer

    M-x coverlay-toggle-overlays

Show a table of coverage across file

    M-x coverlay-display-stats
