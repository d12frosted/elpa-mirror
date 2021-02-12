
* About auto-indent-mode
Provides auto-indentation minor mode for Emacs.  This allows the
following:

  - Return automatically indents the code appropriately (if enabled)

  - Pasting/Yanking indents the appropriately

  - Killing line will take off unneeded spaces (if enabled)

  - On visit file, indent appropriately, but DONT SAVE. (Pretend like
    nothing happened, if enabled)

  - On save, optionally unttabify, remove trailing white-spaces, and
    definitely indent the file (if enabled).

  - TextMate behavior of keys if desired (see below)

  - Deleting the end of a line will shrink the whitespace to just one
    (if desired and enabled)

  - Automatically indent balanced parenthetical expression, or sexp, if desired
    `auto-indent-current-pairs' or `auto-indent-next-pair' is set
    to be true (disabled by default).  This is not immediate but occurs
    after a bit to allow better responsiveness in emacs.

  - Attempts to set the indentation level (number of spaces for an
    indent) for a major-mode.

All of these options can be customized. (customize auto-indent)
* Installing auto-indent-mode

To use put this in your load path and then put the following in your emacs
file:

  (setq auto-indent-on-visit-file t) ;; If you want auto-indent on for files
  (require 'auto-indent-mode)


If you (almost) always want this on, add the following to ~/.emacs:


   (auto-indent-global-mode)



Excluded modes are defined in `auto-indent-disabled-modes-list'

If you only want this on for a single mode, you would add the following to
~/.emacs


  (add-hook 'emacs-lisp-mode-hook 'auto-indent-mode)



You could always turn on the minor mode with the command
`auto-indent-mode'
* Auto-indent and repositories
auto-indent-mode will now be more conservative when it determines
that you are in a repository.  It will only indent the local area you
are editing.  This can be changed to be conservative everywhere by:

  (setq auto-indent-indent-style 'conservative)


You can revert to the old behavior of aggressive by:


  (setq auto-indent-indent-style 'aggressive)



* Setting the number of spaces for indenting major modes
While this is controlled by the major mode, as a convenience,
auto-indent-mode attempts to set the default number of spaces for an
indentation for specific major mode.

This is done by:
1. Making local variables of all the variables specified in
   `auto-indent-known-indent-level-variables' and setting them to
   auto-indent's `auto-indent-assign-indent-level'
2. Looking to see if major mode variables
   `major-mode-indent-level' and `major-mode-basic-offset' variables
   are present.  If either of these variables are present,
   `auto-indent-mode' sets these variables to the default
   `auto-indent-assign-indent-level'.

* TextMate Meta-Return behavior
If you would like TextMate behavior of Meta-RETURN going to the
end of the line and then inserting a newline, as well as
Meta-shift return going to the end of the line, inserting a
semi-colon then inserting a newline, use the following:


  (setq auto-indent-key-for-end-of-line-then-newline "<M-return>")
  (setq auto-indent-key-for-end-of-line-insert-char-then-newline "<M-S-return>")
  (require 'auto-indent-mode)
  (auto-indent-global-mode)


This may or may not work on your system.  Many times emacs cannot
distinguish between M-RET and M-S-RET, so if you don't mind a
slight redefinition use:


  (setq auto-indent-key-for-end-of-line-then-newline "<M-return>")
  (setq auto-indent-key-for-end-of-line-insert-char-then-newline "<C-M-return>")
  (require 'auto-indent-mode)
  (auto-indent-global-mode)


If you want to insert something other than a semi-colon (like a
colon) in a specific mode, say colon-mode, do the following:


  (add-hook 'colon-mode-hook (lambda () (setq auto-indent-eol-char ":")))

* Notes about autopair-mode and yasnippet compatibility
If you wish to use this with autopairs and yasnippet, please load
this library first.
* Using specific functions from auto-indent-mode

Also if you wish to just use specific functions from this library
that is possible as well.

To have the auto-indentation delete characters use:



  (autoload 'auto-indent-delete-char "auto-indent-mode" "" t)
  (define-key global-map [remap delete-char] 'auto-indent-delete-char)

  (autoload 'auto-indent-kill-line "auto-indent-mode" "" t)
  (define-key global-map [remap kill-line] 'auto-indent-kill-line)




However, this does not honor the excluded modes in
`auto-indent-disabled-modes-list'


* Making certain modes perform tasks on paste/yank.
Sometimes, like in R, it is convenient to paste c:\ and change it to
c:/.  This can be accomplished by modifying the
`auto-indent-after-yank-hook'.

The code for changing the paths is as follows:


  (defun kicker-ess-fix-path (beg end)
    "Fixes ess path"
    (save-restriction
      (save-excursion
        (narrow-to-region beg end)
        (goto-char (point-min))
        (when (looking-at "[A-Z]:\\\\")
          (while (search-forward "\\" nil t)
            (replace-match "/"))))))

  (defun kicker-ess-turn-on-fix-path ()
    (interactive)
    (when (string= "S" ess-language)
      (add-hook 'auto-indent-after-yank-hook 'kicker-ess-fix-path t t)))
  (add-hook 'ess-mode-hook 'kicker-ess-turn-on-fix-path)


Another R-hack is to take of the ">" and "+" of a command line
copy. For example copying:

 >
 > availDists <- c(Normal="rnorm", Exponential="rexp")
 > availKernels <- c("gaussian", "epanechnikov", "rectangular",
 + "triangular", "biweight", "cosine", "optcosine")


Should give the following code on paste:


 availDists <- c(Normal="rnorm", Exponential="rexp")
 availKernels <- c("gaussian", "epanechnikov", "rectangular",
 "triangular", "biweight", "cosine", "optcosine")


This is setup by the following code snippet:


  (defun kicker-ess-fix-code (beg end)
    "Fixes ess path"
    (save-restriction
      (save-excursion
        (save-match-data
          (narrow-to-region beg end)
          (goto-char (point-min))
          (while (re-search-forward "^[ \t]*[>][ \t]+" nil t)
            (replace-match "")
            (goto-char (point-at-eol))
            (while (looking-at "[ \t\n]*[+][ \t]+")
              (replace-match "\n")
              (goto-char (point-at-eol))))))))

  (defun kicker-ess-turn-on-fix-code ()
    (interactive)
    (when (string= "S" ess-language)
      (add-hook 'auto-indent-after-yank-hook 'kicker-ess-fix-code t t)))
  (add-hook 'ess-mode-hook 'kicker-ess-turn-on-fix-code)


* Auto-indent and org-mode
Auto-indent does not technically turn on for org-mode.  Instead the
following can be added/changed:

1. `org-indent-mode' is turned on when `auto-indent-start-org-indent'
   is true.
2. The return behavior is changed to newline and indent in code blocks
   when `auto-indent-fix-org-return' is true.
3. The backspace behavior is changed to auto-indent's backspace when
   `auto-indent-delete-backward-char' is true.  This only works in
   code blocks.
4. The home beginning of line behavior is changed to auto-indent's
   when `auto-indent-fix-org-move-beginning-of-line' is true.
5. The yank/paste behavior is changed to auto-indent in a code block
   when `auto-indent-fix-org-yank' is true.
6. The auto-filling activity in source-code blocks can break your code
   depending on the language.  When `auto-indent-fix-org-auto-fill' is
   true, auto-filling is turned off in`org-mode' source blocks.
* FAQ
** Why isn't my mode indenting?
Some modes are excluded for compatability reasons, such as
text-modes.  This is controlled by the variable
`auto-indent-disabled-modes-list'
** Why isn't my specific mode have the right number of spaces?
Actually, the number of spaces for indentation is controlled by the
major mode. If there is a major-mode specific variable that controls
this offset, you can add this variable to
`auto-indent-known-indent-level-variables' to change the indentation
for this mode when auto-indent-mode starts.

See:

- [[http://www.pement.org/emacs_tabs.htm][Understanding GNU Emacs and tabs]]
- [[http://kb.iu.edu/data/abde.html][In Emacs how can I change tab sizes?]]
*** How do I add a variable to the auto-indent tab offset?
You can add the variable by using =M-x customize-group
auto-indent-mode= and then add the variable to
`auto-indent-known-indent-levels'.  Another way is to use lisp:


  (add-to-list 'auto-indent-known-indent-levels 'c-basic-offset)


*** How do I change the auto-indent default offset?
You can change auto-indent's default offset by:


  (setq auto-indent-assign-indent-level 4) ; Changes the indent level to
                                          ; 4 spaces instead of 2.


*** How do I turn of auto-indent assignment?
When auto-indent finds a tab-size variable, it assigns the indentation
level to the globally defined `auto-indent-assign-indent-level'.  If
you do not want this to happen you can turn it off by

  (setq auto-indent-assign-indent-level-variables nil)


** Why is auto-indent-mode changing tabs to spaces
I prefer tabs instead of spaces.  You may prefer the other way.  The
options to change this are:


  (setq auto-indent-mode-untabify-on-yank-or-paste nil)


to keep tabs upon paste.


  (setq auto-indent-untabify-on-visit-file nil) ; Already disabled



To keep tabs upon visiting a file.


  (setq auto-indent-untabify-on-save-file nil)


to turn off changing tabs to spaces on file save.


  (setq auto-indent-backward-delete-char-behavior nil) ; Just delete one character.


So that backspace doesn't change tabs to spaces.

If you wish to be more extreme you can also change spaces to tabs by:


  (setq auto-indent-mode-untabify-on-yank-or-paste 'tabify)


to keep tabs upon paste.


  (setq auto-indent-untabify-on-visit-file 'tabify) ; I would suggest
                                          ; leaving this off.



To keep tabs upon visiting a file.


  (setq auto-indent-untabify-on-save-file 'tabify)



** Argh -- Auto-indent is messing with my indentation.  What can I do?
If you do not like the default indentation style of a particular
mode, sometimes you may adjust the indetation by hand.  Then you
press the return button and all your hard work is erased.  This can
be quite frustrating.

What is happening, is that auto-indent is fixing the current line's
indentation and then indenting the next line on pressing enter.  This
can be turned off customizing the `auto-indent-newline-function' to


  (setq auto-indent-newline-function 'newline-and-indent)


This will insert a newline and then indent.  Not reindent according
to the major mode's conventions.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
