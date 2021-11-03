fb2-reader.el provides a major mode for reading FB2 books.

Features:

- read .fb2 and .fb2.zip files
- rich book formatting
- showing current title in header line
- internal links (select from keyboard, jumb back and forth)
- navigation (next/previous chapters, imenu support)
- restoring last read position
- displaying raw xml

Coming soon:

- book info screen
- integration with https://github.com/jumper047/librera-sync
- rendering book in org-mode

Installation:
Add these strings to your config:

   (use-package fb2-reader
     :mode (("\\.fb2\\(.zip\\|\\)$" . fb2-reader-mode))
     :custom
     ;; This mode renders book with fixed width, adjust to your preferences.
     (fb2-reader-page-width 120)
     (fb2-reader-image-max-width 400)
     (fb2-reader-image-max-height 400))
