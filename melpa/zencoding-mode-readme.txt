
Unfold CSS-selector-like expressions to markup. Intended to be used
with sgml-like languages; xml, html, xhtml, xsl, etc.

See `zencoding-mode' for more information.

Copy zencoding-mode.el to your load-path and add to your .emacs:

   (require 'zencoding-mode)

Example setup:

   (add-to-list 'load-path "~/Emacs/zencoding/")
   (require 'zencoding-mode)
   (add-hook 'sgml-mode-hook 'zencoding-mode) ;; Auto-start on any markup modes

Enable the minor mode with M-x zencoding-mode.

See ``Test cases'' section for a complete set of expression types.

If you are hacking on this project, eval (zencoding-test-cases) to
ensure that your changes have not broken anything. Feel free to add
new test cases if you add new features.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
