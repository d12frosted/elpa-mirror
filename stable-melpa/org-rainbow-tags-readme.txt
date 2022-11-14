This package adds random colors to your org tags. In order to make colors
random but consistent between same tags, colors are generated from the hash
of the tag names.

Since it's random, results may not make you happy, but there are some custom
fields that you can use as ~seed~ to generate different colors. If you are
really picky, there is already a built-in solution for you, please see
[[https://orgmode.org/manual/Tags.html][org-tag-faces]]. This package aims to
get rid of setting and updating ~org-tag-faces~ manually for each tag you
use.

;; Installation

;;; Manual

1. Clone this repository
2. Add these two lines to your init file:

(add-to-list 'load-path "/path/to/org-rainbow-tags/")
(require 'org-rainbow-tags)

;;; Using ~straight.el~ and ~use-package~

(use-package org-rainbow-tags
  :straight (:host github :repo "KaratasFurkan/org-rainbow-tags"))

;;; MELPA

You need to enable package installations from MELPA if you didn't already.
/(See: https://melpa.org/#/getting-started)/

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)


;;;; Interactively

~M-x package-install RET org-rainbow-tags RET~

;;;; With ~init.el~ or ~.emacs~

(unless (package-installed-p 'org-rainbow-tags)
  (package-install 'org-rainbow-tags))
(require 'org-rainbow-tags)


;;;; With ~use-package~

(use-package org-rainbow-tags
  :ensure t)


;; Usage

You can run ~org-rainbow-tags-mode~ command in the buffer you wanna colorize
the tags.

If you wanna run this minor mode on ~org~ files automatically, you can add a
hook:

(add-hook 'org-mode-hook 'org-rainbow-tags-mode)

To see customization options, you can run ~M-x customize-group RET
org-rainbow-tags RET~ or you can check ~(defcustom ...)~ lines in
~org-rainbow-tags.el~.

If you don't like the auto-generated colors for your favorite tags, you can
change the value of ~org-rainbow-tags-hash-start-index~ between 0-20. This
variable decides which 12 characters of the hash of the tag should be taken
to generate the color.

Example:

(setq org-rainbow-tags-hash-start-index 10)

Full ~use-package~ example:

(use-package org-rainbow-tags
  :ensure t
  :custom
  (org-rainbow-tags-hash-start-index 10)
  (org-rainbow-tags-extra-face-attributes
   ;; Default is '(:weight 'bold)
   '(:inverse-video t :box t :weight 'bold))
  :hook
  (org-mode . org-rainbow-tags-mode))

;; Known Issues
~org-rainbow-tags-mode~ colorizes org tags when it's activated and also when
a new tag is added/updated with ~org-set-tags-command~ or with ~C-c C-c~ on
the headline. However, colors will not updated when you edit the tags
manually. If you wanna update colors in every circumstances, you can add this
line to your configuration:

(add-hook 'org-mode-hook (lambda ()
                           (add-hook 'post-command-hook
                                     'org-rainbow-tags--apply-overlays nil t)))

This is not default because it may cause performance issues on org files. You
can try it and decide if it's okay or not.
