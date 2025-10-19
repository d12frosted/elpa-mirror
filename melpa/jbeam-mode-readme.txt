
This package provides a major mode `jbeam-mode` for editing
JBeam configuration files used in BeamNG.drive.

Features:
- Syntax highlighting
- Comment handling

To enable automatically:
  (require 'jbeam-mode)
  ;; or via auto-mode-alist
  (add-to-list 'auto-mode-alist '("\\.jbeam\\'" . jbeam-mode))
