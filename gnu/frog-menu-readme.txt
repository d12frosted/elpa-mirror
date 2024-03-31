<p> <a href="<https://elpa.gnu.org/packages/frog-menu.html>"><img
alt="GNU ELPA" src="<https://elpa.gnu.org/favicon.png"/>></a> <a
href="<https://travis-ci.com/clemera/frog-menu>"><img alt="Travis CI"
src="<https://travis-ci.com/clemera/frog-menu.svg?branch=master"/>></a>
</p>


1 Description
═════════════

  This package lets you quickly pick strings from ad hoc menus. Just
  like a frog would catch a fly. The menu is built "on the fly" from a
  collection of strings. It's presented to the user to choose one of
  them by pressing a single key. One example where this kind of menu is
  useful are spelling correction suggestions:

  <./images/spellcheck.png>

  The user can specify a prompt and additional action keys as you can
  see in the bottom of the menu. Usage in the terminal is also
  supported:

  <./images/spellcheck2.png>


  Inspired by [ace-popup-menu].


[ace-popup-menu] <https://github.com/mrkkrp/ace-popup-menu>


2 Example
═════════

  To invoke the menu users can call `frog-menu-read'. How items are
  displayed and choosen depends on `frog-menu-type'. For graphical
  displays the type `avy-posframe' uses [avy] and [posframe]. In
  terminals the type `avy-side-window' is used. The implemented handler
  functions can be used as reference if you want to define your own
  `frog-menu-type'.

  Here is an example how you would invoke a frog menu:

  ┌────
  │ (frog-menu-read "Choose a string"
  │ 		'("a" "list" "of strings"))
  └────

  It is also possible to define additional action keys (as shown in the
  screenshot). Here is an example how you could use `frog-menu-read' to
  implement a [flyspell-correct-interface]:

  ┌────
  │ (require 'flyspell-correct)
  │ 
  │ (defun frog-menu-flyspell-correct (candidates word)
  │   "Run `frog-menu-read' for the given CANDIDATES.
  │ 
  │ List of CANDIDATES is given by flyspell for the WORD.
  │ 
  │ Return selected word to use as a replacement or a tuple
  │ of (command . word) to be used by `flyspell-do-correct'."
  │   (let* ((corrects (if flyspell-sort-corrections
  │ 		       (sort candidates 'string<)
  │ 		     candidates))
  │ 	 (actions `(("C-s" "Save word"         (save    . ,word))
  │ 		    ("C-a" "Accept (session)"  (session . ,word))
  │ 		    ("C-b" "Accept (buffer)"   (buffer  . ,word))
  │ 		    ("C-c" "Skip"              (skip    . ,word))))
  │ 	 (prompt   (format "Dictionary: [%s]"  (or ispell-local-dictionary
  │ 						   ispell-dictionary
  │ 						   "default")))
  │ 	 (res      (frog-menu-read prompt corrects actions)))
  │     (unless res
  │       (error "Quit"))
  │     res))
  │ 
  │ (setq flyspell-correct-interface #'frog-menu-flyspell-correct)
  └────

  Afterwards calling `M-x flyspell-correct-wrapper' will prompt you with
  a `frog-menu'.

  And here is yet another example I use to navigate the menubar:

  ┌────
  │ (require 'tmm)
  │ 
  │ (defun tmm-init-km-list+ (menu)
  │   (setq tmm-km-list nil)
  │   (map-keymap (lambda (k v) (tmm-get-keymap (cons k v))) menu)
  │   (setq tmm-km-list (nreverse tmm-km-list))
  │   ;; filter unenabled items
  │   (setq tmm-km-list
  │ 	(cl-remove-if
  │ 	 (lambda (item)
  │ 	   (eq (cddr item) 'ignore)) tmm-km-list)))
  │ 
  │ (defun frog-tmm-prompt (menu &optional entry)
  │   "Adapted from `counsel-tmm-prompt'."
  │   (let (out
  │ 	choice
  │ 	chosen-string)
  │     (setq tmm-km-list (tmm-init-km-list+ menu))
  │     (setq out (or entry (frog-menu-read "Menu: " (mapcar #'car tmm-km-list))))
  │     (setq choice (cdr (assoc out tmm-km-list)))
  │     (setq chosen-string (car choice))
  │     (setq choice (cdr choice))
  │     (cond ((keymapp choice)
  │ 	   (frog-tmm-prompt choice))
  │ 	  ((and choice chosen-string)
  │ 	   (setq last-command-event chosen-string)
  │ 	   (call-interactively choice)))))
  │ 
  │ (defun frog-tmm (&optional entry)
  │   "Adapted from `counsel-tmm'."
  │   (interactive)
  │   (run-hooks 'menu-bar-update-hook)
  │   (setq tmm-table-undef nil)
  │   (frog-tmm-prompt (tmm-get-keybind [menu-bar]) entry))
  │ 
  │ (defun frog-tmm-mode ()
  │   "Adapted from `counsel-tmm'."
  │   (interactive)
  │   (frog-tmm mode-name))
  └────


[avy] <https://github.com/abo-abo/avy>

[posframe] <https://github.com/tumashu/posframe>

[flyspell-correct-interface]
<https://github.com/d12frosted/flyspell-correct>
