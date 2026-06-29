<a href="<https://elpa.gnu.org/packages/buffer-expose.html>"><img
alt="GNU ELPA" src="<https://elpa.gnu.org/favicon.png"/>></a>


1 Description
═════════════

  Visual buffer switching using a window grid ([ace-window ]key hints
  are optional):

  <./images/grid-aw.png>


[ace-window ] <https://github.com/abo-abo/ace-window>


2 Installation
══════════════

  For manual installation, clone the repository and call:

  ┌────
  │ (package-install-file "/path/to/buffer-expose.el")
  └────


3 Config
════════

  To use the default bindings for switching buffers with buffer-expose
  use buffer-expose-mode:

  ┌────
  │ (buffer-expose-mode 1)
  └────

  The default bindings are defined in buffer-expose-mode-map:

  ┌────
  │ (defvar buffer-expose-mode-map
  │   (let ((map (make-sparse-keymap)))
  │     (define-key map (kbd "<s-tab>") 'buffer-expose)
  │     (define-key map (kbd "<C-tab>") 'buffer-expose-no-stars)
  │     (define-key map (kbd "C-c <C-tab>") 'buffer-expose-current-mode)
  │     (define-key map (kbd "C-c C-m") 'buffer-expose-major-mode)
  │     (define-key map (kbd "C-c C-d") 'buffer-expose-dired-buffers)
  │     (define-key map (kbd "C-c C-*") 'buffer-expose-stars)
  │     map)
  │   "Mode map for command `buffer-expose-mode'.")
  └────

  There are user options to customize which buffers are shown and you
  can easily write your own command, like this:

  ┌────
  │ (defun my-expose-command (&optional max)
  │   (interactive "P")
  │   (buffer-expose-show-buffers
  │     <your-buffer-list> max [<hide-regexes> <filter-func>]))
  └────
