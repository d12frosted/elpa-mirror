	       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		JIT-SPELL — JUST-IN-TIME SPELL CHECKING
	       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


jit-spell is a spell-checking package for Emacs.  It highlights all
misspelled words in a window, just like a word processor or web browser
does.

<https://raw.githubusercontent.com/astoff/jit-spell/images/screenshot.png>

This behavior is different from the built-in Flyspell package, which
only checks words as the cursor moves over them.  Moreover, unlike
Flyspell, jit-spell communicates with the spell-checking subprocess
entirely asynchronously, which can lead to a noticeable performance
improvement.

jit-spell is part of [GNU ELPA] and can be installed with `M-x
package-install RET jit-spell RET'.


[GNU ELPA] <https://elpa.gnu.org>


1 Usage
═══════

  To enable spell checking in a buffer, type `M-x jit-spell-mode RET'.
  To correct a misspelling, you can right-click the word (assuming you
  have `context-menu-mode' activated) or call the command
  `jit-spell-correct-word', which uses the minibuffer to read a
  correction or accept the word.

  To make your settings permanent, you may wish to add some variant of
  the following to your init file:

  ┌────
  │ (add-hook 'text-mode-hook 'jit-spell-mode)
  │ (add-hook 'prog-mode-hook 'jit-spell-mode)
  │ (with-eval-after-load 'jit-spell
  │   (define-key jit-spell-mode-map (kbd "C-;") 'jit-spell-correct-word))
  └────

  To pick a spell checker and dictionaries, jit-spell uses Emacs's
  built-in ispell support code.  Try `M-x customize-group ispell RET' to
  see a listing of all possible settings.


2 Major mode support
════════════════════

  Some major modes require special settings to avoid checking irrelevant
  parts of the buffer.

  The simplest mechanism to achieve that is the user option
  `jit-spell-ignored-faces'.  Any word fontified with one of these faces
  is ignored for spell-checking purposes.  To find out which faces are
  present on a given character, you can use `M-x describe-char'.

  In all programming language modes, spell checking is restricted to
  comments, docstring and strings.  This can be modified by customizing
  the variable `jit-spell-prog-mode-faces'.

  Some modes, such as Org and TeX-related modes, require more extensive
  adaptations.  This is not yet provided as I am evaluating the possible
  approaches.


3 Contributing
══════════════

  Discussions, suggestions and code contributions are welcome! Since
  this package is part of GNU ELPA, contributions require a copyright
  assignment to the FSF.
