This package provides commands for indenting and dedenting Lisp
code such that close parentheses and brackets are automatically
adjusted to be consistent with the new level of indentation.

When reading Lisp, the programmer pays attention to open parens and
the close parens on the same line. But when a sexp spans more than
one line, she deduces the close paren from indentation alone. Given
that's how we read Lisp, this package aims to enable editing Lisp
similarly: automatically adjust the close parens programmers ignore
when reading. A result of this is an editing experience somewhat
like python-mode, which also offers "indent" and "dedent" commands.
There are differences because lisp-mode knows more due to existing
parens.

To use:
  (require 'adjust-parens)
  (add-hook 'emacs-lisp-mode-hook #'adjust-parens-mode)
  (add-hook 'clojure-mode-hook #'adjust-parens-mode)
  ;; etc

This binds two keys in Lisp Mode:
  (local-set-key (kbd "TAB") 'lisp-indent-adjust-parens)
  (local-set-key (kbd "<backtab>") 'lisp-dedent-adjust-parens)

lisp-indent-adjust-parens potentially calls indent-for-tab-command
(the usual binding for TAB in Lisp Mode). Thus it should not
interfere with other TAB features like completion-at-point.

Some examples follow. | indicates the position of point.

  (let ((x 10) (y (some-func 20))))
  |

After one TAB:

  (let ((x 10) (y (some-func 20)))
    |)

After three more TAB:

  (let ((x 10) (y (some-func 20
                             |))))

After two Shift-TAB to dedent:

  (let ((x 10) (y (some-func 20))
        |))

When dedenting, the sexp may have sibling sexps on lines below. It
makes little sense for those sexps to stay at the same indentation,
because they cannot keep the same parent sexp without being moved
completely. Thus they are dedented too. An example of this:

  (defun func ()
    (save-excursion
      (other-func-1)
      |(other-func-2)
      (other-func-3)))

After Shift-TAB:

  (defun func ()
    (save-excursion
      (other-func-1))
    |(other-func-2)
    (other-func-3))

If you indent again with TAB, the sexps siblings aren't indented:

  (defun func ()
    (save-excursion
      (other-func-1)
      |(other-func-2))
    (other-func-3))

Thus TAB and Shift-TAB are not exact inverse operations of each
other, though they often seem to be.