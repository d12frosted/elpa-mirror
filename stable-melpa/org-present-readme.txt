
This is meant to be an extremely minimalist presentation tool for
Emacs org-mode.

Usage:

Add the following to your emacs config:

  (add-to-list 'load-path "~/path/to/org-present")
  (autoload 'org-present "org-present" nil t)

  (add-hook 'org-present-mode-hook
            (lambda ()
              (org-present-big)
              (org-display-inline-images)))

  (add-hook 'org-present-mode-quit-hook
            (lambda ()
              (org-present-small)
              (org-remove-inline-images)))

Open an org-mode file with each slide under a top-level heading.
Start org-present with org-present-mode, left and right keys will move forward
and backward through slides. C-c C-q will quit org-present.

This works well with hide-mode-line (http://webonastick.com/emacs-lisp/hide-mode-line.el),
which hides the mode-line when only one frame and buffer are open.

If you're on a Mac you might also want to look at the fullscreen patch here:
http://cloud.github.com/downloads/typester/emacs/feature-fullscreen.patch
