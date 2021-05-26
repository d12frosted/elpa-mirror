Quick intro

To install, put this file (as well as maxima-font-lock.el) somewhere in your
Emacs load path. To make sure that `maxima.el' is loaded when necessary,
whether to edit a file in maxima mode or interact with Maxima in an Emacs
buffer, put the lines (or for use-package users see below)
 (autoload 'maxima-mode "maxima" "Maxima mode" t)
 (autoload 'maxima "maxima" "Maxima interaction" t)
in your `.emacs' file.  If you want any file ending in `.mac' to begin
in `maxima-mode', for example, put the line
 (setq auto-mode-alist (cons '("\\.mac" . maxima-mode) auto-mode-alist))
to your `.emacs' file.

for users of use-package, the maxima package can be loaded with the form

(use-package maxima
  :init
  (add-hook 'maxima-mode-hook #'maxima-hook-function)
  (add-hook 'maxima-inferior-mode-hook #'maxima-hook-function)
  (setq
	 org-format-latex-options (plist-put org-format-latex-options :scale 2.0)
	 maxima-display-maxima-buffer nil)
  :mode ("\\.mac\\'" . maxima-mode)
  :interpreter ("maxima" . maxima-mode))
