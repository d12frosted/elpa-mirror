[https://user-images.githubusercontent.com/8352747/33807810-91656488-ddc3-11e7-8029-985f28471a47.png]

[https://travis-ci.org/emacs-evil/evil-surround.svg?branch=master]
[https://melpa.org/packages/evil-surround-badge.svg]
[file:https://stable.melpa.org/packages/evil-surround-badge.svg]
[https://img.shields.io/badge/license-GPLv3-blue.svg]


This package emulates [surround.vim] by [Tim Pope]. The functionality is
wrapped into a minor mode.

This package uses [Evil] as its vi layer.


[https://user-images.githubusercontent.com/8352747/33807810-91656488-ddc3-11e7-8029-985f28471a47.png]
<https://user-images.githubusercontent.com/8352747/33807810-91656488-ddc3-11e7-8029-985f28471a47.png>

[https://travis-ci.org/emacs-evil/evil-surround.svg?branch=master]
<https://travis-ci.org/emacs-evil/evil-surround.svg?branch=master>

[https://melpa.org/packages/evil-surround-badge.svg]
<https://melpa.org/#/evil-surround>

[file:https://stable.melpa.org/packages/evil-surround-badge.svg]
<https://stable.melpa.org/#/evil-surround>

[https://img.shields.io/badge/license-GPLv3-blue.svg]
<https://www.gnu.org/licenses/gpl-3.0.en.html>

[surround.vim] <https://github.com/tpope/vim-surround>

[Tim Pope] <https://github.com/tpope>

[Evil] <https://github.com/emacs-evil/evil>


1 Installation
══════════════

  To enable it through [use-package], add the following lines to
  `~/.emacs' or `~/.emacs.d/init.el':

  ┌────
  │ (use-package evil-surround
  │   :ensure t
  │   :config
  │   (global-evil-surround-mode 1))
  └────

  Alternatively, a user can add the `evil-surround.el' file to your
  load-path and add `(require 'evil-surround)' to your init file.

  Also, Instead of enabling it globally, you can also enable
  `surround-mode' along a major mode by adding `turn-on-surround-mode'
  to the mode hook.


[use-package] <https://github.com/jwiegley/use-package>


2 Usage
═══════

2.1 Add surrounding
───────────────────

  You can surround in visual-state with `S<textobject>' or
  `gS<textobject>'.  Or in normal-state with `ys<textobject>' or
  `yS<textobject>'.


2.2 Change surrounding
──────────────────────

  You can change a surrounding with
  `cs<old-textobject><new-textobject>'.


2.3 Delete surrounding
──────────────────────

  You can delete a surrounding with `ds<textobject>'.


2.4 Add new surround pairs
──────────────────────────

  A surround pair is this (trigger char with textual left and right
  strings):

  ┌────
  │ (?> . ("<" . ">"))
  └────

  or this (trigger char and calling a function):

  ┌────
  │ (?< . surround-read-tag)
  └────

  You can add new by adding them to `evil-surround-pairs-alist'.  For
  more information do: `C-h v evil-surround-pairs-alist'.

  `evil-surround-pairs-alist' is a buffer local variable, which means
  that you can have different surround pairs in different modes. By
  default `<' is used to insert a tag, in C++ this may not be useful -
  but inserting angle brackets is, so you can add this:

  ┌────
  │ (add-hook 'c++-mode-hook (lambda ()
  │ 			   (push '(?< . ("< " . " >")) evil-surround-pairs-alist)))
  └────

  Don't worry about having two entries for `<' surround will take the
  first.

  Or in Emacs Lisp modes using ` to enter ` ' is quite useful, but not
  adding a pair of ` (the default behavior if no entry in
  `evil-surround-pairs-alist' is present), so you can do this:

  ┌────
  │ (add-hook 'emacs-lisp-mode-hook (lambda ()
  │ 				  (push '(?` . ("`" . "'")) evil-surround-pairs-alist)))
  └────

  without affecting your Markdown surround pairs, where the default is
  useful.

  To change the default `evil-surround-pairs-alist' you have to use
  `setq-default', for example to remove all default pairs:

  ┌────
  │ (setq-default evil-surround-pairs-alist '())
  └────

  or to add a pair that surrounds with two ` if you enter ~:

  ┌────
  │ (setq-default evil-surround-pairs-alist
  │ 	      (push '(?~ . ("``" . "``")) evil-surround-pairs-alist))
  └────


2.5 Add new surround pairs through creation of evil objects
───────────────────────────────────────────────────────────

  You can create new evil objects that will be respected by
  evil-surround. Just use the following code:
  ┌────
  │ ;; this macro was copied from here: https://stackoverflow.com/a/22418983/4921402
  │ (defmacro define-and-bind-quoted-text-object (name key start-regex end-regex)
  │   (let ((inner-name (make-symbol (concat "evil-inner-" name)))
  │ 	(outer-name (make-symbol (concat "evil-a-" name))))
  │     `(progn
  │        (evil-define-text-object ,inner-name (count &optional beg end type)
  │ 	 (evil-select-paren ,start-regex ,end-regex beg end type count nil))
  │        (evil-define-text-object ,outer-name (count &optional beg end type)
  │ 	 (evil-select-paren ,start-regex ,end-regex beg end type count t))
  │        (define-key evil-inner-text-objects-map ,key #',inner-name)
  │        (define-key evil-outer-text-objects-map ,key #',outer-name))))
  │ 
  │ (define-and-bind-quoted-text-object "pipe" "|" "|" "|")
  │ (define-and-bind-quoted-text-object "slash" "/" "/" "/")
  │ (define-and-bind-quoted-text-object "asterisk" "*" "*" "*")
  │ (define-and-bind-quoted-text-object "dollar" "$" "\\$" "\\$") ;; sometimes your have to escape the regex
  └────


2.6 Add surround pairs for buffer-local text objects
────────────────────────────────────────────────────

  Buffer-local text objects are useful for mode specific text objects
  that you don't want polluting the global keymap. To make these objects
  work with `evil-surround', do the following (for example to bind pipes
  to `Q'):

  ┌────
  │ (defvar evil-some-local-inner-keymap (make-sparse-keymap)
  │   "Inner text object test keymap")
  │ (defvar evil-some-local-outer-keymap (make-sparse-keymap)
  │   "Outer text object keymap")
  │ (define-key evil-some-local-inner-keymap "Q" #'evil-inner-pipe)
  │ (define-key evil-some-local-outer-keymap "Q" #'evil-a-pipe)
  │ (define-key evil-visual-state-local-map   "iQ" #'evil-inner-pipe)
  │ (define-key evil-operator-state-local-map "iQ" #'evil-inner-pipe)
  │ (define-key evil-visual-state-local-map   "aQ" #'evil-a-pipe)
  │ (define-key evil-operator-state-local-map "aQ" #'evil-a-pipe)
  │ (setq evil-surround-local-inner-text-object-map-list (list evil-some-local-inner-keymap))
  │ (setq evil-surround-local-outer-text-object-map-list (list evil-some-local-outer-keymap))
  │ (setq-local evil-surround-pairs-alist (append '((?Q "|" . "|")) evil-surround-pairs-alist))
  └────

  note that the binding to `evil-some-local-(inner|outer)-keymap' is
  purely for organizational perpouses, you can skip that step and do:

  ┌────
  │ (define-key evil-visual-state-local-map   "iQ" #'evil-inner-pipe)
  │ (define-key evil-operator-state-local-map "iQ" #'evil-inner-pipe)
  │ (define-key evil-visual-state-local-map   "aQ" #'evil-a-pipe)
  │ (define-key evil-operator-state-local-map "aQ" #'evil-a-pipe)
  │ (setq evil-surround-local-inner-text-object-map-list (list (lookup-key evil-operator-state-local-map "i")))
  │ (setq evil-surround-local-outer-text-object-map-list (list (lookup-key evil-operator-state-local-map "a")))
  │ (setq-local evil-surround-pairs-alist (append '((?Q "|" . "|")) evil-surround-pairs-alist))
  └────


2.7 Add new supported operators
───────────────────────────────

  You can add support for new operators by adding them to
  `evil-surround-operator-alist'.  For more information do: `C-h v
  evil-surround-operator-alist'.

  By default, surround works with `evil-change' and `evil-delete'.  To
  add support for the evil-paredit package, you need to add
  `evil-paredit-change' and `evil-paredit-delete' to
  `evil-surround-operator-alist', like so:

  ┌────
  │ (add-to-list 'evil-surround-operator-alist
  │ 	     '(evil-paredit-change . change))
  │ (add-to-list 'evil-surround-operator-alist
  │ 	     '(evil-paredit-delete . delete))
  └────


3 Examples
══════════

  Here are some usage examples (taken from [surround.vim]):

  Press `cs"'' inside

  ┌────
  │ "Hello world!"
  └────

  to change it to

  ┌────
  │ 'Hello world!'
  └────

  Now press `cs'<q>' to change it to

  ┌────
  │ <q>Hello world!</q>
  └────

  To go full circle, press `cst"' to get

  ┌────
  │ "Hello world!"
  └────

  To remove the delimiters entirely, press `ds"'.

  ┌────
  │ Hello world!
  └────

  Now with the cursor on "Hello", press `ysiw]' (`iw' is a text object).

  ┌────
  │ [Hello] world!
  └────

  Let's make that braces and add some space (use `}' instead of `{' for
  no space): `cs]{'

  ┌────
  │ { Hello } world!
  └────

  Now wrap the entire line in parentheses with `yssb' or `yss)'.

  ┌────
  │ ({ Hello } world!)
  └────

  Revert to the original text: `ds{ds)'

  ┌────
  │ Hello world!
  └────

  Emphasize hello: `ysiw<em>'

  ┌────
  │ <em>Hello</em> world!
  └────

  Finally, let's try out visual mode. Press a capital V (for linewise
  visual mode) followed by `S<p class'"important">=.

  ┌────
  │ <p class="important">
  │   <em>Hello</em> world!
  │ </p>
  └────

  Suppose you want to call a function on your visual selection or a text
  object. You can simply press `f' instead of the aforementioned keys
  and are then prompted for a functionname in the minibuffer, like with
  the tags. So with:

  ┌────
  │ "Hello world!"
  └────

  … after selecting the string, then pressing `Sf', entering `print' and
  pressing return you would get

  ┌────
  │ print("Hello world!")
  └────


[surround.vim] <https://github.com/tpope/vim-surround>


4 FAAQ (frequently actually asked questions)
════════════════════════════════════════════

4.1 Why does `vs' no longer surround?
─────────────────────────────────────

  This is due to an upstream change in `vim-surround'. It happened in
  this [commit]. See the discussion in [this] pull request for more
  details.


[commit] <https://github.com/tpope/vim-surround/commit/6f0984a>

[this] <https://github.com/timcharper/evil-surround/pull/48>


5 Contributing
══════════════

  • you are encouraged to test your changes in a standard environment
    with a clean emacs using just the needed plugins.


5.1 interactively
─────────────────

  ┌────
  │ # open a shell and go to the evil-surround directory, after cloning it
  │ # this is a clean emacs with just the absolute minimum dependencies needed to test evil-surround interactivelly.
  │ make
  │ make emacs
  │ 
  │ # now load evil-surround/test/evil-surround-test.el and M-x ert and run the tests
  └────


5.2 command
───────────

  ┌────
  │ # open a shell and go to the evil-surround directory, after cloning it
  │ # this commands ensure that the tests are using a clean emacs with just the absolute minimum dependencies needed.
  │ make
  │ make test
  └────


6 Credits
═════════

  Credits and many [thanks] go to [Tim Harper], the original mantainer
  of the package.


[thanks] <https://github.com/emacs-evil/evil/issues/842>

[Tim Harper] <http://github.com/timcharper>


7 LICENSE
═════════

  • [GNU General Public License v3]
  ┌────
  │ GNU General Public License v3
  │ Copyright (C) 2010 - 2017 Tim Harper
  │ Copyright (c) 2018 - 2020 The evil-surround Contributors
  └────


[GNU General Public License v3]
<https://www.gnu.org/licenses/gpl-3.0.en.html>
