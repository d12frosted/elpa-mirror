The easysession Emacs package is a session manager for Emacs that can persist
and restore file editing buffers, indirect buffers (clones), Dired buffers,
the tab-bar, and Emacs frames (including or excluding the geometry: frame
size, width, and height). It offers a convenient and effortless way to manage
Emacs editing sessions and utilizes built-in Emacs functions to persist and
restore frames.

With Easysession.el, you can effortlessly switch between sessions,
ensuring a consistent and uninterrupted editing experience.

Key features include:
- Quickly switch between sessions while editing with or without disrupting
  the frame geometry.
- Capture the full Emacs workspace state: file buffers, indirect buffers and
  clones, buffer narrowing, Dired buffers, window layouts and splits, the
  built-in tab-bar with its tabs and buffers, and Emacs frames with optional
  position and size restoration.
- Built from the ground up with an emphasis on speed, minimalism, and
  predictable behavior, even in large or long-running Emacs setups.
- Never lose context with automatic session persistence. (Enable
  `easysession-save-mode' to save the active session at regular intervals
  defined by `easysession-save-interval' and again on Emacs exit.)
- Comprehensive command set for session management: switch sessions instantly
  with `easysession-switch-to', save with `easysession-save', delete with
  `easysession-delete', and rename with `easysession-rename'.
- Highly extensible architecture that allows custom handlers for non-file
  buffers, making it possible to restore complex or project-specific buffers
  exactly as needed.
- Fine-grained control over file restoration by selectively excluding
  individual functions from `find-file-hook' during session loading via
  `easysession-exclude-from-find-file-hook'.
- Clear visibility of the active session through modeline integration or a
  lighter.
- Built-in predicate to determine whether the current session qualifies for
  automatic saving.
- Optional scratch buffer persistence via the `easysession-scratch'
  extension, preserving notes and experiments across restarts.
- Optional Magit state restoration via the `easysession-magit' extension,
  keeping version control workflows intact.
- Exact restoration of narrowed regions in both base and indirect buffers,
  ensuring each buffer reopens with the same visible scope as when it was
  saved.

Installation from MELPA:
------------------------
(use-package easysession
  :ensure t
  :custom
  ;; Interval between automatic session saves
  (easysession-save-interval (* 10 60))
  ;; Make the current session name appear in the mode-line
  (easysession-mode-line-misc-info t)
  :init
  (add-hook 'emacs-startup-hook #'easysession-load-including-geometry 102)
  (add-hook 'emacs-startup-hook #'easysession-save-mode 103))

Usage:
------
It is recommended to use the following functions:
- (easysession-switch-to) to switch to another session or (easysession-load)
  to reload the current one,
- (easysession-save) to save the current session as the current name or
  another name.

To facilitate session management, consider using the following key mappings:
C-c l for switching sessions with easysession-switch-to, and C-c s for
saving the current session with easysession-save:
  (global-set-key (kbd "C-c l") 'easysession-switch-to)
  (global-set-key (kbd "C-c s") 'easysession-save)

Links:
------
- More information about easysession (Frequently asked questions, usage...):
  https://github.com/jamescherti/easysession.el
