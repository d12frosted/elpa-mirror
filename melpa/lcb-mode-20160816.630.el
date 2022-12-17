;;; lcb-mode.el --- LiveCode Builder major mode

;; Copyright (C) 2016  Peter Brett <peter@peter-b.co.uk>

;; Author: Peter TB Brett <peter@peter-b.co.uk>
;; Created: 2016-08-13
;; Version: 0.1.0
;; Package-Version: 20160816.630
;; Package-Commit: be0768e9aa6f9b8e76f2230f4f7f4d152a766b9a
;; Url: https://github.com/peter-b/lcb-mode
;; Keywords: languages
;; Package-Requires: ((emacs "24"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:


;;; Code:

;;;; LiveCode specialized regular expressions

(eval-when-compile
  (defconst lcb-rx-constituents
    `((word-sep    . ,(rx (or (any " \t") "\\\n")))
      (word-sep+   . ,(rx (+ (or (any " \t") "\\\n"))))
      (word-sep*   . ,(rx (* (or (any " \t") "\\\n"))))
      (line-prefix . ,(rx line-start (* (or (any " \t") "\\\n"))))
      (keyword     . ,(rx symbol-start (+ (any lower)) symbol-end))
      (identifier  . ,(rx symbol-start
                          (any word ?_) (* (any word digit ?_))
                          symbol-end))
      (block-start . ,(rx symbol-start
                          (or "if" "repeat" "unsafe" "bytecode" "else")
                          symbol-end))
      (block-end   . ,(rx symbol-start
                          (or "end" "else")
                          symbol-end))
      (qualifier   . ,(rx symbol-start
                          (or "public" "private" "unsafe" "foreign")
                          symbol-end))))

  (defmacro lcb-rx (&rest regexps)
    "LiveCode mode specialized rx macro.
This variant of `rx' supports common LiveCode named REGEXPS."
    (let ((rx-constituents (append lcb-rx-constituents rx-constituents)))
      (cond ((null regexps)
             (error "No regexp"))
            ((cdr regexps)
             (rx-to-string `(and ,@regexps) t))
            (t
             (rx-to-string (car regexps) t))))))


;;;; Font-lock and syntax

(defvar lcb-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; Comments
    (modify-syntax-entry ?/ ". 124" st)
    (modify-syntax-entry ?* ". 23b" st)
    (modify-syntax-entry ?\- ". 12" st)
    (modify-syntax-entry ?\n ">" st)
    ;; Angle brackets
    (modify-syntax-entry ?< "(>" st)
    (modify-syntax-entry ?> ")<" st)
    st)
  "Syntax table for LiveCode Builder mode")

(defun lcb-syntax-comment-p (&optional syntax-ppss)
  "Return non-nil if point is in a comment using SYNTAX-PPSS.  It
returns the start character address of the comment."
  (let ((ppss (or syntax-ppss (syntax-ppss))))
    (and (nth 4 ppss) (nth 8 ppss))))

(defun lcb-info-continuation-line-p ()
  "Check if current line is continuation of another.
When current line is continuation of another return the point
where the continued line ends."
  (save-excursion
    (save-restriction
      (widen)
      (let* ((comment-start (progn
                              (back-to-indentation)
                              (lcb-syntax-comment-p)))
             (line-start (line-number-at-pos)))

        ;; Comments can't continue lines.  When not within a comment,
        ;; the only way we are dealing with a continuation line is
        ;; that the previous line contains a backslash, and this can
        ;; only be the previous line from the current one.
        (unless comment-start
          (back-to-indentation)
          (lcb-util-forward-comment -1)
          (when (and (equal (1- line-start) (line-number-at-pos))
                     (lcb-info-line-ends-backslash-p))
            (point-marker)))))))

(defun lcb-info-block-continuation-line-p ()
  "Return non-nil if current line is a continuation of a block
start. When the current line is continuation of a block start
return the point where the continued line ends."
  (save-excursion
    (save-restriction
      (let ((start (lcb-info-continuation-line-p)))
        (when (and start
                   (goto-char (lcb-info-beginning-of-statement))
                   (lcb-info-block-start-line-p))
          start)))))

(defun lcb-info-block-start-line-p ()
  "Return non-nil if current line is a block start."
  (save-excursion
    (save-restriction
      (widen)
      (back-to-indentation)
      (when (or (looking-at (lcb-rx block-start))
                (lcb-info-handler-def-p))
        (point-marker)))))

(defun lcb-info-block-end-line-p (&optional line-number)
  "Return non-nil if the current line is a block end.
With optional argument LINE-NUMBER, check that line instead."
  (save-excursion
    (save-restriction
      (widen)
      (when line-number
        (lcb-util-goto-line line-number))
      (back-to-indentation)
      (when (looking-at (lcb-rx block-end))
        (point-marker)))))

(defun lcb-info-handler-def-start-line-p ()
  "Return non-nil if current line is the first line of a handler definition."
  (save-excursion
    (save-restriction
      (widen)
      (back-to-indentation)
      (when (looking-at
             (lcb-rx (* qualifier word-sep+)
                     "handler" word-sep+
                     identifier word-sep* "("))
        (point-marker)))))

(defun lcb-info-handler-def-p ()
  "Return non-nil if point lies within a handler definition"
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (lcb-info-beginning-of-statement))
      (lcb-info-handler-def-start-line-p))))

(defun lcb-info-line-ends-backslash-p (&optional line-number)
  "Return non-nil if current line ends with a backslash.
With optional argument LINE-NUMBER, check that line instead."
  (save-excursion
    (save-restriction
      (widen)
      (when line-number
        (lcb-util-goto-line line-number))
      (goto-char (line-end-position))
      (when (and (not (lcb-syntax-comment-p))
                 (equal (char-before) ?\\))
        (point-marker)))))

(defun lcb-info-beginning-of-statement (&optional line-number)
  "Return the point where the current statement starts.
Optional argument LINE-NUMBER forces the line number to check against."
  (save-excursion
    (save-restriction
      (widen)
      (when line-number
        (lcb-util-goto-line line-number))
      (while (lcb-info-continuation-line-p)
        (forward-line -1))
      (back-to-indentation)
      (point-marker))))

(defun lcb-info-end-of-statement (&optional line-number)
  "Return the point where the current statement ends (i.e. the
start of the line immediately following the end of the last line
of the current statement).  Optional argument LINE-NUMBER forces
the line-number to check against."
  (save-excursion
    (save-restriction
      (widen)
      (when line-number
        (lcb-util-goto-line line-number))
      (while (and (not (eobp))
                  (lcb-info-line-ends-backslash-p))
        (forward-line 1))
      (line-beginning-position 2))))


;;;; Indentation

(defun lcb-indent-context ()
  "Get information about the current indentation context.
Context is returned in a cons with the form (STATUS . START).

STATUS can be one of the following:

keyword
-------

:no-indent
 - No possible indentation case matches.
 - START is always zero

:after-backslash
 - Fallback case for continuation lines.
 - START is at the position where the continued line starts.
:after-backslash-block-start
 - Point is after a continued block opening line.
 - START is at the position where the block starts.

:after-block-start
 - Point is after a line that starts a block.
 - START is the position where the block starts.
:block-end
 - Point is on a line that ends a block.
 - START is the position where the last line of the block starts.
:after-line
 - Point is after a simple line.
 - START is the position where the previous line starts.
"
  (save-restriction
    (widen)
    (let ((ppss (save-excursion (beginning-of-line)
                                (syntax-ppss))))
      (cond
       ;; Beginning of buffer
       ((= (line-number-at-pos) 1)
        (cons :no-indent 0))

       ;; Continuation line
       ((let ((start (when (lcb-info-continuation-line-p)
                       (lcb-info-beginning-of-statement))))
          (when start
            (cond
             ;; Continuation of block starter
             ((lcb-info-block-continuation-line-p)
              (cons :after-backslash-block-start start))
             ;; Continuation of other line
             (t
              (cons :after-backslash start))))))

       ;; After beginning of block
       ((let ((start (save-excursion
                       (back-to-indentation)
                       (lcb-util-forward-comment -1)
                       (goto-char (lcb-info-beginning-of-statement))
                       (lcb-info-block-start-line-p))))
          (when start
            (cond
             ((lcb-info-block-end-line-p)
              (cons :after-line start))
             (t
              (cons :after-block-start start))))))

       ;; Normal line
       ((let ((start (save-excursion
                       (back-to-indentation)
                       (lcb-util-forward-comment -1)
                       (lcb-info-beginning-of-statement))))
          (cond
           ((lcb-info-block-end-line-p)
            (cons :block-end start))
           (t
            (cons :after-line start)))))))))

(defun lcb-indent-calculate-indentation ()
  "Calculate indentation."
  (save-restriction
    (widen)
    (save-excursion
      (pcase (lcb-indent-context)
        (`(:no-indent . ,_) 0)

        (`(,(or :after-line) . ,start)
         ;; Copy previous indentation
         (goto-char start)
         (current-indentation))

        (`(,(or :after-backslash
                :after-backslash-block-start) . ,start)
         ;; Add two levels of indentation
         (goto-char start)
         (+ (current-indentation) (* 2 tab-width)))

        (`(,:after-block-start . ,start)
         ;; Add one level of indentation
         (goto-char start)
         (+ (current-indentation) tab-width))

        (`(,(or :block-end) . ,start)
         ;; Remove a level of indentation
         (goto-char start)
         (max 0 (- (current-indentation) tab-width)))))))

(defun lcb-indent-line ()
  "Indent current line as Lcb Builder code"
  (interactive)

  (let ((follow-indentation-p
         ;; Check if point is within indentation
         (and (<= (line-beginning-position) (point))
              (>= (+ (line-beginning-position)
                     (current-indentation))
                  (point)))))
    (save-excursion
      (indent-line-to
       (lcb-indent-calculate-indentation)))
    (when follow-indentation-p
      (back-to-indentation))))

(defun lcb-indent-line-function ()
  "`indent-line-function' for LiveCode Builder mode."
  (lcb-indent-line))


;;;; Font lock (syntax highlighting)

(defvar lcb-font-lock-keywords
  `(
    ;; bad user no biscuit
    (,(lcb-rx (group "\\") not-newline)
     (1 font-lock-warning-face))

    ;; if / else if
    (,(lcb-rx line-prefix
              (group (opt (seq "else" word-sep+)) "if")
              symbol-end
              (* (or word-sep not-newline))
              symbol-start
              (group "then")
              symbol-end)
     (1 font-lock-keyword-face)
     (2 font-lock-keyword-face))

    ;; block end
    ,(lcb-rx line-prefix
             "end" word-sep+
             (or "module" "library" "widget" "handler"
                 "if" "repeat" "unsafe" "bytecode" "syntax")
             symbol-end)

    ;; variable definitions
    (,(lcb-rx line-prefix
              (group "variable") word-sep+
              (group identifier)
              symbol-end)
     (1 font-lock-keyword-face)
     (2 font-lock-variable-name-face)
     (,(lcb-rx symbol-start
               (group "as") word-sep+
               (group identifier))
      nil nil
      (1 font-lock-keyword-face)
      (2 font-lock-type-face)))

    ;; constant definitions
    (,(lcb-rx line-prefix
              (group "constant") word-sep+
              (group identifier) word-sep+
              (group "is")
              symbol-end)
     (1 font-lock-keyword-face)
     (2 font-lock-constant-face)
     (3 font-lock-keyword-face))

    ;; type alias definitions
    (,(lcb-rx line-prefix
              (group (opt (or "public" "private") word-sep+)
                     "type") word-sep+
                     (group identifier) word-sep+
                     (group "is") word-sep+
                     (group (opt "optional" word-sep+)
                            identifier)
                     symbol-end)
     (1 font-lock-keyword-face)
     (2 font-lock-type-face)
     (3 font-lock-keyword-face)
     (4 font-lock-type-face))

    ;; handler type definitions
    (,(lcb-rx line-prefix
              (group (* qualifier word-sep+)
                     "handler" word-sep+
                     "type" word-sep+)
              (group identifier) word-sep*
              "(")
     (1 font-lock-keyword-face)
     (2 font-lock-type-face))

    ;; handler definitions
    (,(lcb-rx line-prefix
              (group (* qualifier word-sep+)
                     "handler" word-sep+)
              (group identifier) word-sep*
              "(")
     (1 font-lock-keyword-face)
     (2 font-lock-function-name-face))

    ;; module definitions and use declarations
    (,(lcb-rx line-prefix
              (group (or "module" "library" "widget" "use")) word-sep+
              (group (opt (* identifier ".")))
              (group identifier)
              symbol-end)
     (1 font-lock-keyword-face)
     (2 font-lock-constant-face)
     (3 font-lock-type-face))

    ;; basic statements
    ,(lcb-rx line-prefix
             (or "unsafe" "bytecode"
                 "else" "repeat" "syntax" "return" "throw")
             symbol-end)

    ;; builtin constants
    ,(lcb-rx symbol-start
             (or "true" "false" "nothing")
             symbol-end)

    ;; builtin types
    (,(lcb-rx symbol-start
              (or "Boolean" "Number" "Real" "Integer" "String" "Data"
                  "Array" "List" "Pointer" "optional" "any")
              symbol-end)
     (0 font-lock-type-face))

    ;; standard library types
    (,(lcb-rx symbol-start
              (or "UInt32" "Int32" "UIntSize" "IntSize" "Float32"
                  "Float64"
                  "CBool" "CInt" "CUInt" "CFloat" "CDouble"
                  "LCInt" "LCUInt" "LCIndex" "LCUIndex"
                  "ZStringNative" "ZStringUTF16" "ZStringUTF8")
              symbol-end)
     (0 font-lock-type-face))

    ;; probably builtin keywords
    (,(lcb-rx symbol-start
              (+ lower)
              symbol-end)
     (0 font-lock-builtin-face))

    ;; probably user variables
    (,(lcb-rx symbol-start
              (any "tprxsm")
              (+ (any upper ?_))
              (* (any word digit ?_))
              symbol-end)
     (0 font-lock-variable-name-face))

    ;; probably user constants
    (,(lcb-rx symbol-start
              "k"
              (+ (any upper ?_))
              (* (any word digit ?_))
              symbol-end)
     (0 font-lock-constant-face))
    ))

(defun lcb-font-lock-extend-region-whole-statement ()
  "Move fontification boundaries to beginning of statements."
  (save-excursion
    (let ((changed nil))
      (goto-char font-lock-beg)
      (goto-char (lcb-info-beginning-of-statement))
      (let ((start (line-beginning-position)))
        (unless (equal font-lock-beg start)
          (setq changed t font-lock-beg start)))

      (goto-char font-lock-end)
      (goto-char (lcb-info-end-of-statement))
      (let ((end (line-beginning-position)))
        (unless (equal font-lock-end end)
          (setq changed t font-lock-end end)))

      changed)))


;;;; Navigating around a buffer

(defun lcb-nav-beginning-of-statement ()
  "Move to start of current statement."
  (interactive "^")
  (goto-char (lcb-info-beginning-of-statement)))

(defun lcb-nav-beginning-of-comment ()
  "Move to the start of the current comment."
  (interactive "^")
  (let ((start (lcb-syntax-comment-p)))
    (when start
      (goto-char start))))


;;;; Utility functions

;; Stolen from python-mode
(defun lcb-util-goto-line (line-number)
  "Move point to LINE-NUMBER."
  (goto-char (point-min))
  (forward-line (1- line-number)))

;; Stolen from python-mode
(defun lcb-util-forward-comment (&optional direction)
  "Livecode mode specific version of `forward-comment'.
Optional argument DIRECTION defines the direction to move in."
  (let ((comment-start (lcb-syntax-comment-p))
        (factor (if (< (or direction 0) 0) -99999 99999)))
    (when comment-start
      (goto-char comment-start))
    (forward-comment factor)))


;;;; Mode installation

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lcb\\'" . lcb-mode))

;;;###autoload
(define-derived-mode lcb-mode prog-mode "LiveCode Builder"
  "Major mode for editing LiveCode Builder source files."
  :syntax-table lcb-mode-syntax-table

  (set (make-local-variable 'tab-width) 3)
  (set (make-local-variable 'indent-tabs-mode) t)

  (set (make-local-variable 'comment-start) "--")
  (set (make-local-variable 'comment-end) "")

  (set (make-local-variable 'indent-line-function)
       #'lcb-indent-line-function)

  (setq font-lock-defaults
        '(lcb-font-lock-keywords nil nil nil nil))

  (add-hook 'font-lock-extend-region-functions
            'lcb-font-lock-extend-region-whole-statement)
  )

(provide 'lcb-mode)

;;; lcb-mode.el ends here
