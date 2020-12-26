;;; fill-function-arguments.el --- Convert function arguments to/from single line -*- lexical-binding: t; -*-

;; Copyright (C) 2015 Free Software Foundation, Inc.

;; Author: David Shepherd <davidshepherd7@gmail.com>
;; Version: 0.9
;; Package-Version: 20201223.819
;; Package-Commit: a0a2f8538c80ac08e497dea784fcb90c93ab465b
;; Package-Requires: ((emacs "24.4"))
;; Keywords: convenience
;; URL: https://github.com/davidshepherd7/fill-function-arguments

;;; Commentary:

;; Add/remove line breaks between function arguments and similar constructs
;;
;; Put point inside the brackets and call `fill-function-arguments-dwim` to convert
;;
;; frobinate_foos(bar, baz, a_long_argument_just_for_fun, get_value(x, y))
;;
;; to
;;
;; frobinate_foos(
;;                bar,
;;                baz,
;;                a_long_argument_just_for_fun,
;;                get_value(x, y)
;;                )
;;
;; and back.
;;
;; Also works with arrays (`[x, y, z]`) and dictionary literals (`{a: b, c: 1}`).
;;
;; If no function call is found `fill-function-arguments-dwim` will call `fill-paragraph`,
;; so you can replace an existing `fill-paragraph` keybinding with it.
;;


;;; Code:

(defgroup fill-function-arguments '()
  "Add/remove line breaks between function arguments and similar constructs."
  :group 'convenience)


(defcustom fill-function-arguments-fall-through-to-fill-paragraph
  t
  "If non-nil `fill-function-arguments-dwim' will fill paragraphs when in comments or strings."
  :group 'fill-function-arguments
  :type 'boolean)

(defcustom fill-function-arguments-first-argument-same-line
  nil
  "If non-nil keep the first argument on the same line as the opening paren (e.g. as needed by xml tags)."
  :group 'fill-function-arguments
  :type 'boolean)

(defcustom fill-function-arguments-second-argument-same-line
  nil
  "If non-nil keep the second argument on the same line as the first argument.

e.g. as used in lisps like `(foo x
                                 bar)'"
  :group 'fill-function-arguments
  :type 'boolean)

(defcustom fill-function-arguments-last-argument-same-line
  nil
  "If non-nil keep the last argument on the same line as the closing paren (e.g. as done in Lisp)."
  :group 'fill-function-arguments
  :type 'boolean)

(defcustom fill-function-arguments-argument-separator
  ","
  "Character separating arguments."
  :group 'fill-function-arguments
  :type 'boolean)

(defcustom fill-function-arguments-trailing-separator
  nil
  "When converting to multiline form, include the separator on the final line."
  :group 'fill-function-arguments
  :type 'boolean)

(defcustom fill-function-arguments-indent-after-fill
  nil
  "If non-nil then after converting to multiline form re-indent the affected lines.

If set to a function, the function is called to indent the region, otherwise `indent-region' is used.

In either case the indentation function is called with arguments `start' and `end' which are the point
of the opening and closing brackets respectively."
  :group 'fill-function-arguments
  :type '(choice 'boolean 'function))




;;; Helpers

(defun fill-function-arguments--in-comment-p ()
  "Check if we are inside a comment."
  (nth 4 (syntax-ppss)))

(defun fill-function-arguments--in-docs-p ()
  "Check if we are inside a string or comment."
  (nth 8 (syntax-ppss)))

(defun fill-function-arguments--opening-paren-location ()
  "Find the location of the current opening parenthesis."
  (nth 1 (syntax-ppss)))

(defun fill-function-arguments--enclosing-paren ()
  "Return the opening parenthesis of the enclosing parens, or nil if not inside any parens."
  (let ((ppss (syntax-ppss)))
    (when (nth 1 ppss)
      (char-after (nth 1 ppss)))))

(defun fill-function-arguments--paren-locations ()
  "Get a pair containing the enclosing parens."
  (let ((start (fill-function-arguments--opening-paren-location)))
    (when start
      (cons start
            ;; matching paren
            (save-excursion
              (goto-char start)
              (forward-sexp)
              (point))))))

(defun fill-function-arguments--narrow-to-brackets ()
  "Narrow to region inside current brackets."
  (interactive)
  (let ((l (fill-function-arguments--paren-locations)))
    (when l
      (narrow-to-region (car l) (cdr l)))
    t))

(defun fill-function-arguments--single-line-p()
  "Is the current function call on a single line?"
  (equal (line-number-at-pos (point-max)) 1))

(defun fill-function-arguments--do-argument-fill-p ()
  "Should we call fill-paragraph?"
  (and fill-function-arguments-fall-through-to-fill-paragraph
       (or (fill-function-arguments--in-comment-p)
           (fill-function-arguments--in-docs-p)
           (and (derived-mode-p 'sgml-mode)
                (not (equal (fill-function-arguments--enclosing-paren) ?<))))))


(defun fill-function-arguments--trim-right (s)
  "Remove whitespace at the end of S.

Borrowed from s.el to avoid a dependency"
  (save-match-data
    (if (string-match "[ \t\n\r]+\\'" s)
        (replace-match "" t t s)
      s)))



;;; Main functions

;;;###autoload
(defun fill-function-arguments-to-single-line ()
  "Convert current bracketed list to a single line."
  (interactive)
  (save-excursion
    (save-restriction
      (fill-function-arguments--narrow-to-brackets)
      (while (not (fill-function-arguments--single-line-p))
        (goto-char (point-max))
        (delete-indentation))

      ;; Clean up trailing commas
      (goto-char (point-max))
      (backward-char)
      (when (looking-back (regexp-quote fill-function-arguments-argument-separator)
                          (length fill-function-arguments-argument-separator))
        (delete-char (- (length fill-function-arguments-argument-separator)))))))

;;;###autoload
(defun fill-function-arguments-to-multi-line ()
  "Convert current bracketed list to one line per argument."
  (interactive)
  (let ((initial-opening-paren (fill-function-arguments--opening-paren-location))
        (argument-separator-no-trailing-whitespace (fill-function-arguments--trim-right fill-function-arguments-argument-separator)))
    (save-excursion
      (save-restriction
        (fill-function-arguments--narrow-to-brackets)
        (goto-char (point-min))

        ;; newline after opening paren
        (forward-char)
        (when (not fill-function-arguments-first-argument-same-line)
          (insert "\n"))

        (when fill-function-arguments-second-argument-same-line
          ;; Just move point after the second argument before we start
          (search-forward fill-function-arguments-argument-separator nil t))

        ;; Split the arguments
        (while (search-forward fill-function-arguments-argument-separator nil t)
          ;; We have to save the match data here because the functions below
          ;; could (and sometimes do) modify it.
          (let ((saved-match-data (match-data)))
            (when (save-excursion (and (not (fill-function-arguments--in-docs-p))
                                       (equal (fill-function-arguments--opening-paren-location) initial-opening-paren)))
              (set-match-data saved-match-data)
              (replace-match (concat argument-separator-no-trailing-whitespace "\n")))))

        ;; Newline before closing paren
        (when (not fill-function-arguments-last-argument-same-line)
          (goto-char (point-max))
          (backward-char)
          (when fill-function-arguments-trailing-separator
            (insert argument-separator-no-trailing-whitespace))
          (insert "\n"))

        (when fill-function-arguments-indent-after-fill
          (if (functionp fill-function-arguments-indent-after-fill)
              (funcall fill-function-arguments-indent-after-fill (point-min) (point-max))
            (indent-region (point-min) (point-max))))))))

;;;###autoload
(defun fill-function-arguments-dwim ()
  "Fill the thing at point in a context-sensitive way.

If point is a string or comment and
`fill-function-arguments-fall-through-to-fill-paragraph' is
enabled, then just run `fill-paragragh'.

Otherwise if point is inside a bracketed list (e.g. a function
call, an array declaration, etc.) then if the list is currently
on a single line call `fill-function-arguments-to-multi-line',
otherwise call `fill-function-arguments-to-single-line'."
  (interactive)
  (save-restriction
    (fill-function-arguments--narrow-to-brackets)
    (cond
     ((fill-function-arguments--do-argument-fill-p) (fill-paragraph))
     ((fill-function-arguments--single-line-p) (fill-function-arguments-to-multi-line))
     (t (fill-function-arguments-to-single-line)))))



(provide 'fill-function-arguments)

;;; fill-function-arguments.el ends here
