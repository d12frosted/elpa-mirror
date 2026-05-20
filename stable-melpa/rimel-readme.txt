Rimel is a lightweight Chinese input method for Emacs based on liberime.
It directly uses Emacs' built-in `input-method-function' interface with
a read-event loop (similar to quail), providing a native Emacs experience.

Features:
- Candidate display in input prompt
- Inline preedit overlay at cursor
- Pagination support
- Enter key for raw English commit
- Number keys / space for candidate selection

Usage:
  (require 'rimel)
  (set-input-method "rimel")
