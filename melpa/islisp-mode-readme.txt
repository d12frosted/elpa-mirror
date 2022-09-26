Quick intro

Major mode for the ISLisp programming language
With features like:
 ISLisp major-mode with custom map keybindings
 Inferior-mode for REPL integration
 Syntax highlighting
 Interactive REPL commands (eg: islisp-eval-defun)
 Interactive ISLispHyperDraft documentation search
 Implementations support (Easy-ISLisp)
 Imenu support
 Advance features (autocompletions, tags support and symbol navigation)

To install this

To install, put this repository somewhere in your Emacs load path,
and add a require to your main Emacs elisp file:
 (require 'islisp-mode)

To add a custom location to the load path:
 (add-to-list 'load-path "/path/to/islisp-mode/")

WARNING: This major-mode binds the .lsp files to ISLisp mode
If you are a Common Lisp hacker that is using Lisp Server Pages,
feel free to remove the last line of the islisp-mode.el file
