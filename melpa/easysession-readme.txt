The easysession Emacs package is a lightweight session manager for Emacs that
can persist and restore file editing buffers, indirect buffers (clones),
Dired buffers, the tab-bar, and Emacs frames (including or excluding the
geometry: frame size, width, and height). It offers a convenient and
effortless way to manage Emacs editing sessions and utilizes built-in Emacs
functions to persist and restore frames.

With Easysession.el, you can effortlessly switch between sessions,
ensuring a consistent and uninterrupted editing experience.

Key features include:
- Minimalist design focused on performance and simplicity, avoiding
  unnecessary complexity.
- Quickly switch between sessions while editing without disrupting the frame
  geometry, enabling you to resume work immediately.
- Save and load file editing buffers, indirect buffers/clones, Dired buffers,
  windows/splits, the Emacs frame (including support for the tab-bar).
- Helper functions: Switch to a session (i.e., load and change the current
  session) with `easysession-switch-to', load the Emacs editing session with
  `easysession-load', save the Emacs editing session with `easysession-save'
  and `easysession-save-as', delete the current Emacs session with
  `easysession-delete', and rename the current Emacs session with
  `easysession-rename'.

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
- (easysession-save-as) to save the current session as the current name or
  another name.

To facilitate session management, consider using the following key mappings:
C-c l for switching sessions with easysession-switch-to, and C-c s for
saving the current session with easysession-save-as:
  (global-set-key (kbd "C-c l") 'easysession-switch-to)
  (global-set-key (kbd "C-c s") 'easysession-save-as)

Links:
------
- More information about easysession (Frequently asked questions, usage...):
  https://github.com/jamescherti/easysession.el
