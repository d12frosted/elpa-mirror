*NOTICE:* Indentation has temporarily been disabled by default. SEE for
why this was needed and what the plan is.  TLDR indentation is going
through a full rewrite.


1 Contributing
══════════════

  Please contribute ideas on how the new indentation system would work.
  See [rewriting the indentation].


[rewriting the indentation] See section 9.1.2


2 Haskell mode based on treesitter
══════════════════════════════════

  A [Haskell] mode that uses [Tree-sitter].

  <./ss.png>

  The above screenshot is indented and coloured using `haskell-ts-mode',
  with `prettify-symbols-mode' enabled.


[Haskell] <https://www.haskell.org/>

[Tree-sitter] <https://tree-sitter.github.io/tree-sitter/>


3 Usage
═══════

  • `C-c C-r' Open REPL
  • `C-c C-c' Send code to REPL
  • `M-q' Indent the function


4 Features
══════════

  Overview of features:

  • Syntax highlighting
  • Structural navigation
  • Indentation (now disabled)
  • Imenu support
  • REPL (`C-c C-r' in the mode to run)
  • Prettify Symbols mode support


5 Comparison with `haskell-mode'
════════════════════════════════

  The more interesting features are:

  • Logical syntax highlighting:
    • Only arguments that can be used in functions are highlighted,
      e.g., in `f (_:(a:[]))' only `a' is highlighted, as it is the only
      variable that is captured, and that can be used in the body of the
      function.
    • The return type of a function is highlighted.
    • All new variabels are (or should be) highlighted, this includes
      generators, lambda arguments.
    • Highlighting the `=' operator in guarded matches correctly, this
      would be stupidly hard in regexp based syntax.
  • More performant, this is especially seen in longer files.
  • Much, much less code, `haskell-mode' has accumlated 30,000 lines of
    code and features to do with all things Haskell related.
    `haskell-ts-mode' just keeps the scope to basic major mode stuff,
    and leaves other stuff to external packages.


6 Motivation
════════════

  `haskell-mode' contains nearly 30k lines of code, and is about 30
  years old. A lot of features implemented by `haskell-mode' are now
  also available in standard Emacs, and have thus become obsolete.

  In 2018, a mode called [`haskell-tng-mode'] was made to solve some of
  these problems. However, because of Haskell's syntax, it too became
  very complex and required a web of dependencies.

  Both these modes ended up practically parsing Haskell's syntax to
  implement indentation, so I thought why not use Tree-sitter?


[`haskell-tng-mode']
<https://elpa.nongnu.org/nongnu/haskell-tng-mode.html>


7 Structural navigation
═══════════════════════

  This mode provides strucural navigation, for Emacs 30+.

  ┌────
  │ combs (x:xs) = map (x:) c ++ c
  │   where c = combs xs
  └────

  In the above code, if the pointer is right in front of the function
  definition `combs', and you press `C-M-f' (`forward-sexp'), it will
  take you to the end of the second line.


8 Installation
══════════════

  Add this into your init.el:

  ┌────
  │ (use-package haskell-ts-mode
  │   :ensure t
  │   :custom
  │   (haskell-ts-font-lock-level 4)
  │   (haskell-ts-use-indent t)
  │   (haskell-ts-ghci "ghci")
  │   (haskell-ts-use-indent t)
  │   :config
  │   (add-to-list 'treesit-language-source-alist
  │    '(haskell . ("https://github.com/tree-sitter/tree-sitter-haskell" "v0.23.1")))
  │   (unless (treesit-grammar-location 'haskell)
  │    (treesit-install-language-grammar 'haskell)))
  └────

  That is all. This will install the grammars if not already installed.
  However, you might need to update the grammar version in the future.


8.1 Other recommended packages
──────────────────────────────

  Unlike `haskell-mode', this mode has a limited scope to just worrying
  about haskell. There are other packages that I find help a lot with
  development:
  • [consult-hoogle] great interface for `hoogle'.
  • [dante]
  • [hindent] If you want to outsource the indentation and formatting to
    another haskell package.
  • [ormolu] hindent alternative
  • [hcel] Codebase navigator, if you want a lighter alternaitve to a
    full blown LSP.


[consult-hoogle] <https://codeberg.org/rahguzar/consult-hoogle>

[dante] <https://github.com/jyp/dante>

[hindent] <https://github.com/mihaimaruseac/hindent>

[ormolu] <https://github.com/vyorkin/ormolu.el>

[hcel] <https://github.com/emacsmirror/hcel>


9 Customization
═══════════════

9.1 Indentation
───────────────

  *Indentation has been disabled by default*.  To enable it, use the
   following code.

  ┌────
  │ (setq haskell-ts-use-indent t)
  └────


9.1.1 Why indentation has been disabled temporarily
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Simply because the indention code became a monstrosity.  Don't belive
  me? check the `haskell-ts-indent-rules' variable.  Bugs are rampent,
  fixing one bug created another.  Its a torturous game of wack-a-mole
  with no end in sight.


9.1.2 Indentation rewrite
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Check out the `newindent' branch to see the repo to see the progress.

  There are some options to rewriting indentation:

  1. Do the same approach of having strict indentation that doesn't
     modify the syntax tree, just impliment it better, potentilly using
     a style guide, [like this one].
  2. Rely on a external package like [hi2] or [hyai], at the compromise
     they don't use treesitter, so just end up inefficialty reparsing
     haskell.
  3. My prefered: try to impliment haskell-mode type indentation. I have
     no idea how we would do this, since each indentation attempt could
     change the parse tree, changing the treesitter concrete syntax
     tree.
  4. Adaptive indentation: Like `python-mode', we can try memorise the
     user's indentation prefrences.


[like this one]
<https://github.com/tibbe/haskell-style-guide/blob/master/haskell-style.md>

[hi2] <https://github.com/nilcons/hi2>

[hyai] <https://github.com/iquiw/hyai>


9.2 Use a formatter (e.g. hindent, ormolu/formolu)
──────────────────────────────────────────────────

  `C-c C-f' in a haskell formats the current region is it is active, or
  the current function.

  The default formater is [ormolu]. You can adjust
  `haskell-ts-format-command' this to use another formatter.


[ormolu] <https://hackage.haskell.org/package/ormolu>


9.3 Pretify Symbols mode
────────────────────────

  `prettify-symbols-mode' can be used to replace common symbols with
  unicode alternatives.

  Turning on `prettify-symbols-mode' does stuff like turn `->' to
  `→'. If you want to prettify words, set `haskell-ts-prettify-words' to
  non-nil.  This will do stuff like prettify `forall' into `∀' and
  `elem' to `∈'.

  ┌────
  │ (add-hook 'haskell-ts-mode 'prettify-symbols-mode)
  └────


9.4 Adjusting font lock level
─────────────────────────────

  Set `haskell-ts-font-lock-level' accordingly. The default and highest
  value is 4. You are against vibrancy, you can lower it to match your
  dreariness.


9.5 Language server
───────────────────

  `haskell-ts-mode' works with `lsp-mode' and, since Emacs 30, with
  `eglot'.

  To add `eglot' support on Emacs 29 and earlier, add the following code
  to your `init.el':

  ┌────
  │ (with-eval-after-load 'eglot
  │   (defvar eglot-server-programs)
  │   (add-to-list 'eglot-server-programs
  │                '(haskell-ts-mode . ("haskell-language-server-wrapper" "--lsp"))))
  └────


10 TODO list
════════════

  • Support for M-x align, so that calling it will align all the ‘=’
    signs in a region.
  • Imenu support for functions with multiple definitions.
  • Merge the indent branch
