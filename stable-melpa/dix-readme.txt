Basic usage:

(add-hook 'nxml-mode-hook
	  (lambda () (and buffer-file-name
			  (string-match "^modes\\.xml$\\|\\.\\(dix\\|metadix\\|t[0-9s]x\\|lrx\\)$"
                                     buffer-file-name)
			  (dix-mode 1))))

Unless you installed from MELPA, you'll also need

(add-to-list 'load-path "/path/to/dix.el-folder")
(autoload 'dix-mode "dix"
  "dix-mode is a minor mode for editing Apertium XML dictionary files."  t)

If you actually work on Apertium packages, you'll probaby want some
other related Emacs extensions as well; see
http://wiki.apertium.org/wiki/Emacs#Quickstart for an init file
that installs and configures both dix.el and some related packages.

If you want keybindings that use `C-c' followed by letters, you
should also add
(add-hook 'dix-mode-hook #'dix-C-c-letter-keybindings)
These are not turned on by default, since `C-c' followed by letters
is meant to be reserved for user preferences.

Useful functions (some using C-c-letter-keybindings): `C-c <left>'
creates an LR-restricted copy of the <e>-element at point, `C-c
<right>' an RL-restricted one.  `C-TAB' cycles through the
restriction possibilities (LR, RL, none), while `M-n' and `M-p'
move to the next and previous "important bits" of <e>-elements
(just try it!).  `C-c S' sorts a pardef, while `M-.'  moves point
to the pardef of the entry at point, leaving mark where you left
from (`M-.' will go back).  `C-c \' greps the pardef/word at point
using the dictionary files represented by the string
`dix-dixfiles', while `C-c D' gives you a list of all pardefs which
use these suffixes (where a suffix is the contents of an
<l>-element).

`M-x dix-suffix-sort' is a general function, useful outside of dix
XML files too, that just reverses each line, sorts them, and
reverses them back.  `C-c % %' is a convenience function for
regexp-replacing text within certain XML elements, eg. all <e>
elements; `C-c % r' and `C-c % l' are specifically for <r> and <l>
elements, respectively.

I like having the following set too:
(setq nxml-sexp-element-flag t 		; treat <e>...</e> as a sexp
      nxml-completion-hook '(rng-complete t) ; C-RET completes based on DTD
      rng-nxml-auto-validate-flag nil)       ; 8MB of XML takes a while
You can always turn on validation again with C-c C-v.  Validation
is necessary for the C-RET completion, which is really handy in
transfer files.

I haven't bothered with defining a real indentation function, but
if you like having all <i> elements aligned at eg. column 25, the
align rules defined here let you do M-x align on a region to
achieve that, and also aligns <p> and <r>.  Set your favorite
column numbers with M-x customize-group RET dix.

Plan / long term TODO:
- Yank into <i/l/r> or pardef n="" should replace spaces with either
  a <b/> or a _
- Functions shouldn't modify the kill-ring.
- Functions should be agnostic to formatting (ie. only use nxml
  movement functions, never forward-line).
- Real indentation function for one-entry-one-line format.
- `dix-LR-restriction-copy' should work on a region of <e>'s.
- `dix-expand-lemma-at-point' (either using `dix-goto-pardef' or
  `lt-expand')
- Some sort of interactive view of the translation process . When
  looking at a word in monodix, you should easily get confirmation on
  whether (and what) it is in the bidix or other monodix (possibly
  just using `apertium-transfer' and `lt-proc' on the expanded
  paradigm).
- Function for creating a prelimenary list of bidix entries from
  monodix entries, and preferably from two such lists which
  we "paste" side-by-side.
- `dix-LR-restriction-copy' (and the other copy functions) could
  add a="author"
- `dix-dixfiles' could auto-add files from Makefile?
- `dix-sort-e-by-r' doesn't work if there's an <re> element after
  the <r>; and doesn't sort correctly by <l>-element, possibly to
  do with spaces
- `dix-reverse' should be able to reverse on a regexp match, so
  that we can do `dix-suffix-sort' by eg. <l>-elements.
- Investigate if Emacs built-in `tildify-mode' should be used to
  implement `dix-space'.
