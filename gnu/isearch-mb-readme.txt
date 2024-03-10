           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            ISEARCH-MB — CONTROL ISEARCH FROM THE MINIBUFFER
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This Emacs package provides an alternative isearch UI based on the
minibuffer. This allows editing the search string in arbitrary ways
without any special maneuver; unlike standard isearch, cursor motion
commands do not end the search. Moreover, the search status information
in the echo area and some keybindings are slightly simplified.

isearch-mb is part of [GNU ELPA] and can be installed with `M-x
package-install RET isearch-mb RET'. To activate it, type `M-x
isearch-mb-mode RET'.


[GNU ELPA] <https://elpa.gnu.org/packages/isearch-mb.html>


1 Keybindings
═════════════

  During a search, `isearch-mb-minibuffer-map' is active. By default, it
  includes the following commands:

  • `C-s', `↓': Repeat search forwards.
  • `C-r', `↑': Repeat search backwards.
  • `M-<': Go to first match (or /n/-th match with numeric argument).
  • `M->': Go to last match (or /n/-th last match with numeric
    argument).
  • `C-v', `<next>': Search forward from the bottom of the window.
  • `M-v', `<prior>': Search backward from the top of the window.
  • `M-%': Replace occurrences of the search string.
  • `C-M-%': Replace occurrences of the search string (regexp mode).
  • `M-s' prefix: similar to standard isearch.

  Everything else works as in a plain minibuffer. For instance, `RET'
  ends the search normally and `C-g' cancels it.


2 Some customization ideas
══════════════════════════

  isearch provides a myriad of customization options, and most of them
  make just as much sense when using isearch-mb. The following are some
  uncontroversial improvements of the defaults:

  ┌────
  │ (setq-default
  │  ;; Show match count next to the minibuffer prompt
  │  isearch-lazy-count t
  │  ;; Don't be stingy with history; default is to keep just 16 entries
  │  search-ring-max 200
  │  regexp-search-ring-max 200)
  └────

  Note that since isearch-mb relies on a regular minibuffer, you can use
  you favorite tool to browse the history of previous search strings
  (say, the `consult-history' command from the excellent [Consult]
  package).

  Using regexp search by default is a popular option as well:

  ┌────
  │ (global-set-key (kbd "C-s") 'isearch-forward-regexp)
  │ (global-set-key (kbd "C-r") 'isearch-backward-regexp)
  └────

  Another handy option is to enable lax whitespace matching in one of
  the two variations indicated below.  You can still toggle strict
  whitespace matching with `M-s SPC' during a search, or escape a space
  with a backslash to match it literally.

  ┌────
  │ (setq-default
  │  isearch-regexp-lax-whitespace t
  │  ;; Swiper style: space matches any sequence of characters in a line.
  │  search-whitespace-regexp ".*?"
  │  ;; Alternative: space matches whitespace, newlines and punctuation.
  │  search-whitespace-regexp "\\W+")
  └────

  Finally, you may want to check out the [isearch-mb wiki] for
  additional tips and tricks.


[Consult] <https://github.com/minad/consult>

[isearch-mb wiki] <https://github.com/astoff/isearch-mb/wiki>


3 Interaction with other isearch extensions
═══════════════════════════════════════════

  Some third-party isearch extensions require a bit of configuration in
  order to work with isearch-mb. There are three cases to consider:

  • *Commands that start a search* in a special state shouldn't require
    extra configuration. This includes PDF Tools, Embark, etc.

  • *Commands that operate during a search session* should be added to
    the list `isearch-mb--with-buffer'. Examples of this case are
    [`loccur-isearch'] and [`consult-isearch'].

    ┌────
    │ (add-to-list 'isearch-mb--with-buffer #'loccur-isearch)
    │ (define-key isearch-mb-minibuffer-map (kbd "C-o") #'loccur-isearch)
    │ 
    │ (add-to-list 'isearch-mb--with-buffer #'consult-isearch)
    │ (define-key isearch-mb-minibuffer-map (kbd "M-r") #'consult-isearch)
    └────

    Most isearch commands that are not made available by default in
    isearch-mb can also be used in this fashion:

    ┌────
    │ (add-to-list 'isearch-mb--with-buffer #'isearch-yank-word)
    │ (define-key isearch-mb-minibuffer-map (kbd "M-s C-w") #'isearch-yank-word)
    └────

  • *Commands that end the isearch session* should be added to the list
    `isearch-mb--after-exit'. Examples of this case are
    [`anzu-isearch-query-replace'] and [`consult-line']:

    ┌────
    │ (add-to-list 'isearch-mb--after-exit #'anzu-isearch-query-replace)
    │ (define-key isearch-mb-minibuffer-map (kbd "M-%") 'anzu-isearch-query-replace)
    │ 
    │ (add-to-list 'isearch-mb--after-exit #'consult-line)
    │ (define-key isearch-mb-minibuffer-map (kbd "M-s l") 'consult-line)
    └────

    Making motion commands quit the search as in standard isearch is out
    of the scope of this package, but you can define your own commands
    to emulate that effect. Here is one possibility:

    ┌────
    │ (defun move-end-of-line-maybe-ending-isearch (arg)
    │ "End search and move to end of line, but only if already at the end of the minibuffer."
    │   (interactive "p")
    │   (if (eobp)
    │       (isearch-mb--after-exit
    │        (lambda ()
    │ 	 (move-end-of-line arg)
    │ 	 (isearch-done)))
    │     (move-end-of-line arg)))
    │ 
    │ (define-key isearch-mb-minibuffer-map (kbd "C-e") 'move-end-of-line-maybe-ending-isearch)
    └────


[`loccur-isearch']
<https://github.com/fourier/loccur#isearch-integration>

[`consult-isearch'] <https://github.com/minad/consult>

[`anzu-isearch-query-replace'] <https://github.com/emacsorphanage/anzu>

[`consult-line'] <https://github.com/minad/consult>


4 Contributing
══════════════

  Discussions, suggestions and code contributions are welcome! Since
  this package is part of GNU ELPA, contributions require a copyright
  assignment to the FSF.
