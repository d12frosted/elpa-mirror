1 php-fill.el
═════════════

  Additional fill commands for PHP code editing.


1.1 Fills string literals by breaking them into smaller ones.
─────────────────────────────────────────────────────────────


1.2 Conditionally use ‘NOSQUEEZE’ on spaces between words in c and c++ style comments.
──────────────────────────────────────────────────────────────────────────────────────


1.3 Use “<return>” to break or add a new line to string literals and doc blocks.
────────────────────────────────────────────────────────────────────────────────


1.4 Use “<backspace>” or “<delete>” at the beginning and at the end to join them.
─────────────────────────────────────────────────────────────────────────────────


1.5 Minor mode Php-Refill.
──────────────────────────


1.6 Add it to your init.el
──────────────────────────

  We recommend using this package with a major mode for PHP, like the
  ones supply by packages like [php-mode] and [phps-mode], to get the
  indentation right and for the hook.

  The following example uses ‘php-mode’, but if a different major mode
  were to be used, just change ‘php-mode’ with something else like
  ‘phps-mode’ instead.

  This package is now available on [elpa], so it’s now the preferred way
  of installation. Being the default repository, it should be easy to
  use the following code on your init.el file.

  ┌────
  │ (use-package php-fill
  │   :ensure t
  │   :requires 'php-mode
  │   ;; :custom
  │   ;; (php-fill-fill-column 120) ;; Default is 80.
  │   ;; (php-fill-sentence-end-double-space t) ;; Default is nil.
  │   ;; (php-fill-nosqueeze-c-comments nil) ;; Default is t
  │   ;; (php-fill-nosqueeze-c++-comments t) ;; Default is nil
  │   ;; Add commands that conflict with php-fill-refill-mode
  │   ;; (php-fill-refill-black-list
  │   ;;  (append '(some-command some-other-command)
  │   ;; 	   php-fill-refill-black-list))
  │   :hook
  │   (php-mode . php-fill-set-local-variables)
  │   ;; You migth omit the follwong if you want to fill literals manually
  │   ;; with ‘M-q’.
  │   (php-mode . php-fill-refill-mode)
  │   ;; The following is recommended unless you are already usign them.
  │   (php-mode . display-fill-column-indicator-mode)
  │   (php-mode . display-line-numbers-mode)
  │   :bind
  │   (:map php-mode-map
  │         ("M-q" . php-fill-paragraph)
  │         ("<return>" . php-fill-newline)
  │         ("C-<return>" . newline) ;; Literal newline on string literals
  │         ("<backspace>" . php-fill-backward-delete)
  │         ("<delete>" . php-fill-delete-forward)))
  └────


[php-mode] <https://elpa.nongnu.org/nongnu/php-mode.html>

[phps-mode] <https://elpa.gnu.org/packages/phps-mode.html>

[elpa] <https://elpa.gnu.org/>


1.7 Special thanks to
─────────────────────

  • The code of commands `fill-paragraph', `c-fill-paragraph' and
    `refill-mode', and their respective developers.
  • [Jen-Chieh Shen]'s [ellsp] and his patience 🙏
  • [Xah Lee] invaluable pages on Emacs. I don't think I can pay the
    full tutorial right now though 😅. But a $20 donation soon for sure
    👍.
  • [gnu.org]'s wonderful manuals on Emacs.
  • In a lesser degree the sites [masteringemacs.org] and
    [emacsdocs.org].

  Finally thanks to the patience of the people of the [emacs-devel]
  mailing list, particularly to [Kenta USAMI] and [Philip
  Kaludercic]. Thank you all.


[Jen-Chieh Shen] <https://github.com/jcs090218>

[ellsp] <https://github.com/elisp-lsp/ellsp>

[Xah Lee] <http://xahlee.info/emacs/>

[gnu.org]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/index.html>

[masteringemacs.org] <https://www.masteringemacs.org/>

[emacsdocs.org] <https://emacsdocs.org/>

[emacs-devel] <https://lists.gnu.org/archive/html/emacs-devel/>

[Kenta USAMI] <https://github.com/zonuexe>

[Philip Kaludercic] <mailto:philipk@posteo.net>
