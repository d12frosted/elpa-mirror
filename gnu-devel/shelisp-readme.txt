Comint process (likely shell-mode) can write out Emacs Lisp
expressions and have them executed.

When the shell process writes out a string of the form:
  \e_#EMACS# elisp-expr \a

Where, "elisp-expr" is a valid elisp expression.  The elisp
expression is executed as if you had invoked the function
within Emacs itself.  The elisp expression may include a call to
the function `f' which will expand the filename parameter into an
appropriate filename for Emacs using the appropriate Tramp prefix
if necessary.

This script also defines an Alist variable that creates shell
commands and the `printf'-style format to generate the full elisp
expression with command parameters substituted into the command.  A
function is placed in the `shell-mode-hook' to actually create the
shell functions and aliases to format the elisp expressions and
embed them in an escape sequence so that they are detected and
executed.

In most usage this mode merely allows you to type "e filename"
rather than "C-x C-f filename" which isn't much of a savings.
However, with this mode enabled, you can write shell scripts to
invoke Emacs Lisp functions.  But beware, the shell script will not
wait for completion of the elisp expression, nor return anything
back (see ToDo's below).

INSTALLATION

After installing this package from ELPA, you must add the following
to your Emacs initialization script:

  (add-hook 'shell-mode-hook #'shelisp-mode)
  (add-hook 'term-mode-hook #'shelisp-mode)

  ;; iff `vterm' package was installed
  (add-hook 'vterm-mode-hook #'shelisp-mode)

TO DOs:

* Provide a security feature that prompts the Emacs user to approve
  the execution of any elisp expressions submitted thru the shelisp
  escape sequence.

* Support for bash, ksh, and fish is provided (thank you for your
  motivation and effort, Eduardo Ochs <eduardoochs@gmail.com>);
  support for csh, tcsh, ksh, ash, dash, mosh, and sh is welcomed.

  Support for non-Linux shells is left as an exercise for a
  masochistic hacker.

* Implement a wait for completion facility similar to `emacsclient'
  or the work done in `with-editor' with the "sleeping editor."
  That is, pause the shell activity with a long sleep, until C-c
  C-c or C-c C-k is typed in Emacs and the caller is awoken with a
  signal.

KNOWN BUGS

The simplistic implementation of the shell functions will not
properly handle filenames containing double quote characters (\")
nor backslashes (\\).  While this is an error, it does not
represent a significant limitation in the implementation.  The
caller can properly add backslashes to the filename string before
passing it to printf to generate the elisp expression.  In the end,
the purpose is to create a valid elisp expression string.