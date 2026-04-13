Complete keyword slot arguments inside `cl-defstruct' constructor
calls with slot names, types, and documentation.

Basic usage:

    (add-hook 'emacs-lisp-mode-hook #'struct-completion-mode)

When typing keyword arguments inside a constructor call like
(make-my-struct :sl|), the package offers slot-aware completion
with type annotations and per-slot documentation.

All candidate data comes from runtime introspection via
`cl--class-slots' cross-referenced with constructor arglists
from `help-split-fundoc'.  The struct definition must be
evaluated in the current session for completion to work.

The package provides:
- `struct-completion-mode': buffer-local minor mode
- `struct-completion-at-point': capf for keyword slot completion
- `struct-completion-detectors': extensible detector registry
