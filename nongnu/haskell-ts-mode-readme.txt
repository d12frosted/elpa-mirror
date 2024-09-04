1 Context
═════════

  A haskell mode that uses treesitter.


2 Screenshot
════════════

  <./ss.png>

  The above screenshot is indented coloured using haskell-ts-mode, with
  prettify-symbols-mode enabled.


3 Features
══════════

  an overview of the features are:
  • Syntax highliting
  • Indentation
  • Imenu support
  • REPL
  • Prettify symbols mode support


4 Comparasion with haskell-mode
═══════════════════════════════

  The more interesting features are:
  • Logical syntax highlighting:
    • Only arguments that can be used in functions are highlighted, eg
      in `f (_:(a:[])) only 'a' is highlighted, as it is the only
      variable that is captured that can be used in body of function
    • The return type of a function is highlighted
    • All new variabels are(or should be) highlighted, this includes
      generators, lambda args.
    • highlighting the '=' operaotr in guarded matches correctly, this
      would be stupidly hard in regexp based syntax
  • Unlike haskell-mode, quasi quotes are understood and do not confuse
    the mode, thanks to treesitter
  • Predictable (but less powerful) indentation: haskell-mode's
    indentation works in a cyclical way, it cycles through where you
    might want indentation.  haskell-ts-mode, meanwhile relies on you to
    set the concrete syntax tree changing whitespace.
  • More perfomant, this is especially seen in longer files
  • Much much less code, haskell mode has accumlated 30,000 lines of
    features to do with all things haskell related, this mode just keeps
    the scope to basic major mode stuff, and leaves other stuff for
    external packages.


5 Motivation
════════════

  haskell-mode contains nearly 30k lines of code, and is about 30 years
  old.  Therefore, a lot of stuff emacs has gained the ability to do in
  those years, haskell-mode already has implemented them.

  In 2018, a mode called haskell-tng-mode was made to solve some of
  these problems. However because of haskell's syntax, it too became
  very complex and required a web of dependencies.

  Both these modes ended up practically parsing haskells syntax to
  implement indentation, so I thought why not use tree sitter?


6 Installation
══════════════

  #+BEGIN_SRC: elisp (add-to-list 'load-path "path/to/haskell-ts-mode")
  (require 'haskell-ts-mode) #+END_SRC


7 Customization
═══════════════

  if colour is too much or too less for you, adjust
  treesit-font-lock-level accordingly.

  If that is not enough, you can customize
  haskell-ts-font-lock-feature-list


7.1 how to disable haskell-ts-mode indentation
──────────────────────────────────────────────

  #+begin_src: emacs-lisp (setq haskell-ts-use-indent nil) #+end_src


7.2 Pretify symbols mode
────────────────────────

  prettify symbols mode can be used to replace common symbols with
  unicode alternatives.

  #+begin_src: emacs-lisp (add-hook 'haskell-ts-mode
  'prettify-symbols-mode) #+end_src


7.3 Adjusting font lock level
─────────────────────────────

  set haskell-ts-font-lock-level accordingly.


8 TODO and limitations
══════════════════════

  • support for customization UI
  • Imenu support for functions with multiple definitions

  Limitations: _Proper indenting of multiline signatures_: the
  treesitter grammer does not flatten the signautes, rather leaves them
  to the standard infix interpretatoin. This makes indentation hard, as
  it will mean the only way to check if the the signature node is an
  ancestor of node at point is to perfom a recursive ascent, which is
  horrible for perfomance.
