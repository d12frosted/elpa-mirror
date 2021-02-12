
Unfold CSS-selector-like expressions to markup. Intended to be used
with sgml-like languages; xml, html, xhtml, xsl, etc.

See `emmet-mode' for more information.

Copy emmet-mode.el to your load-path and add to your .emacs:

   (require 'emmet-mode)

Example setup:

   (add-to-list 'load-path "~/Emacs/emmet/")
   (require 'emmet-mode)
   (add-hook 'sgml-mode-hook 'emmet-mode) ;; Auto-start on any markup modes
   (add-hook 'html-mode-hook 'emmet-mode)
   (add-hook 'css-mode-hook  'emmet-mode)

Enable the minor mode with M-x emmet-mode.

See ``Test cases'' section for a complete set of expression types.

If you are hacking on this project, eval (emmet-test-cases) to
ensure that your changes have not broken anything. Feel free to add
new test cases if you add new features.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
