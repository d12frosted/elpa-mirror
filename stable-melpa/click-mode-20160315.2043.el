;;; click-mode.el --- Major mode for the Click Modular Router Project

;; Copyright (c) 2016 Brian Malehorn. All rights reserved.
;; Use of this source code is governed by a MIT-style
;; license that can be found in the LICENSE.txt file.

;; Author: Brian Malehorn <bmalehorn@gmail.com>
;; Version: 0.0.3
;; Package-Version: 20160315.2043
;; Package-Commit: c074e7b5b0a88434d0d3411f18884d1f6e288b33
;; Package-Requires: ((emacs "24"))
;; Keywords: click router
;; URL: https://github.com/bmalehorn/click-mode

;; This file is not part of Emacs.


;;; Commentary:

;; See https://github.com/bmalehorn/click-mode for more.

;;; Code:

;; pilfered from https://www.emacswiki.org/emacs/wpdl-mode.el
(defvar click-mode-syntax-table
  (let ((click-mode-syntax-table (make-syntax-table)))
    ;; Comment styles are same as C++
    (modify-syntax-entry ?/ ". 124b" click-mode-syntax-table)
    (modify-syntax-entry ?* ". 23" click-mode-syntax-table)
    (modify-syntax-entry ?\n "> b" click-mode-syntax-table)
    click-mode-syntax-table)
  "Syntax table for `click-mode'.")

(defvar click-arguments
  (concat
   "append\\|" "end\\|" "error\\|" "errorq\\|" "exit\\|" "export\\|"
   "exportq\\|" "goto\\|" "init\\|" "initq\\|" "label\\|" "loop\\|"
   "pause\\|" "print\\|" "printn\\|" "printnq\\|" "printq\\|" "read\\|"
   "readq\\|" "return\\|" "returnq\\|" "save\\|" "set\\|" "setq\\|"
   "stop\\|" "wait\\|" "wait_for\\|" "wait_step\\|" "wait_stop\\|"
   "wait_time\\|" "write\\|" "writeq\\|" "[A-Z][A-Z_0-9]*")

  "Argument names for `click-mode', e.g.
    Paint(ANNO FOO, COLOR BAR)
          ----      -----
We also include

   Script(write foo.x 1, write foo.y 2)

...Script arguments, since those are typically non-capitalized."
  )

(defun click-indent-line ()
  "\"Correct\" the indentation for the current line."
  (save-excursion
    (back-to-indentation)
    (or (when (looking-at "#\\|elementclass") (indent-line-to 0) t)
        (click-indent-copycat "\\[")
        (click-indent-copycat "->")
        (click-indent-copycat "=>")
        (click-indent-paren)
        (indent-line-to (save-excursion
                          (click-previous-interesting-line)
                          (current-indentation)))))
        ;; ))
  (when (< (current-column) (current-indentation))
    (back-to-indentation)))

(defun click-indent-copycat (regexp)
  "Indent the same as the previous line.
e.g. (click-indent-copycat 1 2 [) will indent this:

1:    => ( [0] -> foo;
2:      [1] -> bar; )

to this:

1:    => ( [0] -> foo;
2:         [1] -> bar; )

If the line with different indentation does not contain REGEXP,
returns nil. Otherwise, returns the new indentation.

"
  (let* ((indent
          (save-excursion
            (back-to-indentation)
            (when (and (not (bobp))
                       (looking-at regexp)
                       (progn
                         (click-previous-interesting-line)
                         (back-to-indentation)
                         (looking-at (concat ".*" regexp))))
              (while (not (looking-at regexp))
                (forward-char))
              (let* ((bracket (point))
                     (bol (progn (beginning-of-line) (point))))
                     (- bracket bol))))))
    (when indent
      (indent-line-to indent)
      indent)))

(defun click-previous-interesting-line ()
  "Moves the point back until reaching a line, skipping blank lines and
comment lines."
  (forward-line -1)
  (while (and (click-boring-line) (not (bobp)))
    (forward-line -1))
  (end-of-line)
  (forward-char -1)
  (while (looking-at "[; ]")
    (forward-char -1))
  (when (looking-at "[})]\\|]")
    (end-of-line)
    (backward-list)))

(defun click-boring-line ()
  (save-excursion
    (back-to-indentation)
    (or
     (looking-at "#")
     (looking-at "$")
     (looking-at "//"))))

(defun click-indent-paren ()
  "

Idents:

      foo (
      bar

to:

      foo (
          bar

"
  (let* ((indent
          (save-excursion
            (let* ((this-paren-count (click-paren-count))
                   (previous-paren-count
                    (progn
                      (click-previous-interesting-line)
                      (click-paren-count)))
                   (previous-indent (current-indentation)))
              (if (< this-paren-count 0)
                  ;; bar)
                  ;; indent to the same indentation as the matching )
                  (max 0
                       (+ previous-indent
                          (* previous-paren-count click-basic-offset)))
                  nil
                (when (< 0 previous-paren-count)
                  ;; foo {
                  ;;     bar
                  ;; indent +1 level
                  (+ previous-indent click-basic-offset)))))))
    (when indent
      (indent-line-to indent)
      indent)))


(defun click-paren-count ()
  "\"({}[\" -> 2
\"}][]) -> 3
"
  (save-excursion
    (let* ((c 0))
      (back-to-indentation)
      (while (not (eolp))
        (when (looking-at "[{([]")
          (setq c (1+ c)))
        (when (looking-at "[})]\\|]")
          (setq c (1- c)))
        (forward-char))
      c)))

(defvar click-basic-offset 4
  "How many spaces to \"correct\" indentation to.
Analogous to `c-basic-offset'.")

(defvar click-highlights
  `(
    ;; #define FOO 5
    ("#\\s-*[a-z]*" . font-lock-preprocessor-face)
    ;; %file foo.click
    ("^%[a-z]+" . font-lock-keyword-face)
    ;; elementclass
    (,(concat
       "\\(^\\|[^a-zA-Z_0-9.]\\)\\("
       "elementclass\\|output\\|input\\|require"
       "\\)\\([^a-zA-Z_0-9.]\\|$\\)")
     . (2 font-lock-keyword-face))
    ;; Foo(
    ("\\([a-zA-Z_][a-zA-Z_/0-9]*\\)("
     . (1 font-lock-function-name-face))
    ;; :: Foo
    ("::\\s-*\\([a-zA-Z_][a-zA-Z_/0-9]*\\)"
     . (1 font-lock-function-name-face))
    ;; -> Foo
    ("->\\s-*\\([A-Z][a-zA-Z_/0-9]*\\)"
     . (1 font-lock-function-name-face))
    ;; Foo ->
    ("\\([A-Z][a-zA-Z_/0-9]*\\)\\s-*->"
     . (1 font-lock-function-name-face))
    ;; foo
    ("^\\s-*\\([a-z_][a-zA-Z_/0-9]*\\)\\s-*$"
     . font-lock-variable-name-face)
    ;; foo ::
    ("\\([a-zA-Z_][a-zA-Z_/0-9]*\\) *\\(, *[a-zA-Z_][a-zA-Z_/0-9]*\\)* *::"
     . (1 font-lock-variable-name-face))
    ;; [0,1,2] foo
    ("\\(\\[[0-9, ]*\\]\\) *\\([a-z_][a-zA-Z_/0-9]*\\)"
     . (2 font-lock-variable-name-face))
    ;; foo [0,1,2]
    ("\\([a-z_][a-zA-Z_/0-9]*\\) *\\(\\[[0-9, ]*\\]\\)"
     . (1 font-lock-variable-name-face))
    ;; -> foo
    ("-> *\\([a-z_][a-zA-Z_/0-9]*\\)"
     . (1 font-lock-variable-name-face))
    ;; foo ->
    ("\\([a-z_][a-zA-Z_/0-9]*\\) *->"
     . (1 font-lock-variable-name-face))
    ;; elementclass Foo {
    ("elementclass *\\([a-zA-Z_][a-zA-Z_/0-9]*\\) "
     . (1 font-lock-type-face))
    ;; Foo(BAR bar)
    (,(concat "(\\(" click-arguments "\\) ")
     . (1 font-lock-constant-face))
    ;; Foo(BAR bar, ACK ack)
    (,(concat ", *\\(" click-arguments "\\) ")
     . (1 font-lock-constant-face))
    ;; ACTIVE false,
    (,(concat
       "^\\s-*\\(" click-arguments "\\) .*\\(,\\|);?\\) *$")
     . (1 font-lock-constant-face))
    )

  "Syntax highlighting for `click-mode'."
  )


;;;###autoload
(define-derived-mode click-mode prog-mode "Click"
  (setq comment-start "// ")
  (setq comment-start-skip "//+\\s-*")
  (set (make-local-variable 'indent-line-function) 'click-indent-line)
  (setq font-lock-defaults '(click-highlights)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.click\\'" . click-mode))
(add-to-list 'auto-mode-alist '("\\.testie\\'" . click-mode))
;; you may also want:
;; (add-to-list 'auto-mode-alist '("\\.template\\'" . click-mode))
;; (add-to-list 'auto-mode-alist '("\\.inc\\'" . click-mode))


(provide 'click-mode)

;;; click-mode.el ends here
