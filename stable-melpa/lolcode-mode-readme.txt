This is a major mode for editing LOLCODE, with the following
features:

* Syntax highlighting.
* Smart indentation.
* Execution of LOLCODE buffers (press C-c C-c).
* Automatic Flymake integration.

; Installation:

Put this file somewhere in your load-path, and put the following in
your .emacs:

  (require 'lolcode-mode)

You may want to install a LOLCODE interpreter. This package comes
preconfigured for lci, which you can get at the following URL:

  http://icanhaslolcode.org/

; Configuration:

This is an example setup which integrates lolcode-mode with
auto-complete-mode and yasnippet. It also sets default indentation
to 2 spaces.

  (require 'lolcode-mode)
  (require 'auto-complete)
  (defvar ac-source-lolcode
    '((candidates . lolcode-lang-all)))
  (add-to-list 'ac-modes 'lolcode-mode)
  (add-hook 'lolcode-mode-hook
            (lambda ()
              (setq default-tab-width 2)
              (add-to-list 'ac-sources 'ac-source-lolcode)
              (add-to-list 'ac-sources 'ac-source-yasnippet)))
