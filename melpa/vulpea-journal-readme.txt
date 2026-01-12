
vulpea-journal provides a day-centric interface for daily note
workflows. It integrates with vulpea-ui's sidebar to show
journal-specific widgets when viewing journal notes.

Main features:
- Daily note identification and navigation
- Integration with vulpea-ui sidebar
- Calendar widget with entry indicators
- Previous years view
- Emacs calendar integration

Quick start:

  (require 'vulpea-journal)
  (vulpea-journal-setup)
  (global-set-key (kbd "C-c j") #'vulpea-journal)
