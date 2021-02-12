This package provides a major mode for editing Constraint Grammar
source files, including syntax highlighting and interactive grammar
development from within Emacs.  Use `C-c C-i' to edit the text you
want to edit, then just `C-c C-c' whenever you want to run the
grammar over that text.  Clicking on a line number in the trace
output will take you to the definition of that rule.

Usage:

(autoload 'cg-mode "/path/to/cg.el"
 "cg-mode is a major mode for editing Constraint Grammar files."  t)
(add-to-list 'auto-mode-alist '("\\.cg3\\'" . cg-mode))
; Or if you use a non-standard file suffix, e.g. .rlx:
(add-to-list 'auto-mode-alist '("\\.rlx\\'" . cg-mode))

I recommend using `company-mode' for tab-completion, and
`smartparens-mode' if you're used to it (`paredit-mode' does not
work well if you have set names with the # character in them). Both
are available from MELPA (see http://melpa.milkbox.net/).

You can lazy-load company-mode for cg-mode like this:

(eval-after-load 'company-autoloads
    '(add-hook 'cg-mode-hook #'company-mode))


TODO:
- investigate bug in `show-smartparens-mode' causing slowness
- different syntax highlighting for sets and tags (difficult)
- use something like prolog-clause-start to define M-a/e etc.
- run vislcg3 --show-unused-sets and buttonise with line numbers (like Occur does)
- indentation function (based on prolog again?)
- the rest of the keywords
- https://visl.sdu.dk/cg3/single/#regex-icase
- keyword tab-completion
- `font-lock-syntactic-keywords' is obsolete since 24.1
- goto-set/list
- show definition of set/list-at-point in modeline
- show section name/number in modeline
