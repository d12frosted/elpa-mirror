;;; twig-mode.el --- A major mode for twig

;; Copyright (C) 2013 Bojan Matic aka moljac024

;; Author: Bojan Matic aka moljac024
;; Version: 0.1
;; Package-Version: 20130220.1850
;; Package-Commit: 51bcd41666a234119a855b9fd348d3dae7832de1

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

;;   This is an emacs major mode for twig with:
;;        syntax highlighting
;;        sgml/html integration
;;        indentation (working with sgml)

;; This file comes from http://github.com/moljac024/twig-mode

;;; Code:

(require 'sgml-mode)

(defgroup twig nil
  "Major mode for editing twig code."
  :prefix "twig-"
  :group 'languages)

(defcustom twig-user-keywords nil
  "Custom keyword names"
  :type '(repeat string)
  :group 'twig)

(defcustom twig-user-functions nil
  "Custom function names"
  :type '(repeat string)
  :group 'twig)

;; (defcustom twig-debug nil
;;   "Log indentation logic"
;;   :type 'boolean
;;   :group 'twig)

(defun twig-closing-keywords ()
  (append
   twig-user-keywords
   '("if" "for" "block" "filter" "with"
     "raw" "macro" "autoescape" "trans" "call")))

(defun twig-indenting-keywords ()
  (append
   (twig-closing-keywords)
   '("else" "elif")))

(defun twig-builtin-keywords ()
  '("as" "autoescape" "debug" "extends"
    "firstof" "in" "include" "load"
    "now" "regroup" "ssi" "templatetag"
    "url" "widthratio" "elif" "true"
    "false" "none" "False" "True" "None"
    "loop" "super" "caller" "varargs"
    "kwargs" "break" "continue" "is"
    "not" "or" "and"
    "do" "pluralize" "set" "from" "import"
    "context" "with" "without" "ignore"
    "missing" "scoped"))

(defun twig-functions-keywords ()
  (append
   twig-user-functions
   '("abs" "attr" "batch" "capitalize"
     "center" "default" "dictsort"
     "escape" "filesizeformat" "first"
     "float" "forceescape" "format"
     "groupby" "indent" "int" "join"
     "last" "length" "list" "lower"
     "pprint" "random" "replace"
     "reverse" "round" "safe" "slice"
     "sort" "string" "striptags" "sum"
     "title" "trim" "truncate" "upper"
     "urlize" "wordcount" "wordwrap" "xmlattr")))

(defun twig-find-open-tag ()
  (if (search-backward-regexp
       (rx-to-string
        `(and "{%"
              (? "-")
              (* whitespace)
              (? (group
                  "end"))
              (group
               ,(append '(or)
                        (twig-closing-keywords)
                        ))
              (group
               (*? anything))
              (* whitespace)
              (? "-")
              "%}")) nil t)
      (if (match-string 1) ;; End tag, going on
          (let ((matches (twig-find-open-tag)))
            (if (string= (car matches) (match-string 2))
                (twig-find-open-tag)
              (list (match-string 2) (match-string 3))))
        (list (match-string 2) (match-string 3)))
    nil))

(defun twig-close-tag ()
  "Close the previously opened template tag."
  (interactive)
  (let ((open-tag (save-excursion (twig-find-open-tag))))
    (if open-tag
        (insert
         (if (string= (car open-tag) "block")
             (format "{%% end%s%s %%}"
                     (car open-tag)(nth 1 open-tag))
           (format "{%% end%s %%}"
                   (match-string 2))))
      (error "Nothing to close")))
  (save-excursion (twig-indent-line)))

(defun twig-insert-tag ()
  "Insert an empty tag"
  (interactive)
  (insert "{% ")
  (save-excursion
    (insert " %}")
    (twig-indent-line)))

(defun twig-insert-var ()
  "Insert an empty tag"
  (interactive)
  (insert "{{ ")
  (save-excursion
    (insert " }}")
    (twig-indent-line)))

(defun twig-insert-comment ()
  "Insert an empty tag"
  (interactive)
  (insert "{# ")
  (save-excursion
    (insert " #}")
    (twig-indent-line)))

(defconst twig-font-lock-comments
  `(
    (,(rx "{#"
          (* whitespace)
          (group
           (*? anything)
           )
          (* whitespace)
          "#}")
     . (1 font-lock-comment-face t))))

(defconst twig-font-lock-keywords-1
  (append
   twig-font-lock-comments
   sgml-font-lock-keywords-1))

(defconst twig-font-lock-keywords-2
  (append
   twig-font-lock-keywords-1
   sgml-font-lock-keywords-2))

(defconst twig-font-lock-keywords-3
  (append
   twig-font-lock-keywords-1
   twig-font-lock-keywords-2
   `(
     (,(rx "{{"
           (* whitespace)
           (group
            (*? anything)
            )
           (*
            "|" (* whitespace) (*? anything))
           (* whitespace)
           "}}") (1 font-lock-variable-name-face t))
     (,(rx  (group "|" (* whitespace))
            (group (+ word))
            )
      (1 font-lock-keyword-face t)
      (2 font-lock-warning-face t))
     (,(rx-to-string `(and (group "|" (* whitespace))
                           (group
                            ,(append '(or)
                                     (twig-functions-keywords)
                                     ))))
      (1 font-lock-keyword-face t)
      (2 font-lock-function-name-face t)
      )
     (,(rx-to-string `(and word-start
                           (? "end")
                           ,(append '(or)
                                    (twig-indenting-keywords)
                                    )
                           word-end)) (0 font-lock-keyword-face))
     (,(rx-to-string `(and word-start
                           ,(append '(or)
                                    (twig-builtin-keywords)
                                    )
                           word-end)) (0 font-lock-builtin-face))

     (,(rx (or "{%" "%}" "{%-" "-%}")) (0 font-lock-function-name-face t))
     (,(rx (or "{{" "}}")) (0 font-lock-type-face t))
     (,(rx "{#"
           (* whitespace)
           (group
            (*? anything)
            )
           (* whitespace)
           "#}")
      (1 font-lock-comment-face t))
     (,(rx (or "{#" "#}")) (0 font-lock-comment-delimiter-face t))
     )))

(defvar twig-font-lock-keywords
  twig-font-lock-keywords-1)

(defun sgml-indent-line-num ()
  "Indent the current line as SGML."
  (let* ((savep (point))
         (indent-col
          (save-excursion
            (back-to-indentation)
            (if (>= (point) savep) (setq savep nil))
            (sgml-calculate-indent))))
    (if (null indent-col)
        0
      (if savep
          (save-excursion indent-col)
        indent-col))))

(defun twig-calculate-indent-backward (default)
  "Return indent column based on previous lines"
  (let ((indent-width sgml-basic-offset) (default (sgml-indent-line-num)))
    (forward-line -1)
    (if (looking-at "^[ \t]*{%-? *end") ; Don't indent after end
        (current-indentation)
      (if (looking-at (concat "^[ \t]*{%-? *.*?{%-? *end" (regexp-opt (twig-indenting-keywords))))
          (current-indentation)
        (if (looking-at (concat "^[ \t]*{%-? *" (regexp-opt (twig-indenting-keywords)))) ; Check start tag
            (+ (current-indentation) indent-width)
          (if (looking-at "^[ \t]*<") ; Assume sgml block trust sgml
              default
            (if (bobp)
                0
              (twig-calculate-indent-backward default))))))))


(defun twig-calculate-indent ()
  "Return indent column"
  (if (bobp)  ; Check begining of buffer
      0
    (let ((indent-width sgml-basic-offset) (default (sgml-indent-line-num)))
      (if (looking-at "^[ \t]*{%-? *e\\(nd\\|lse\\|lif\\)") ; Check close tag
          (save-excursion
            (forward-line -1)
            (if
                (and
                 (looking-at (concat "^[ \t]*{%-? *" (regexp-opt (twig-indenting-keywords))))
                 (not (looking-at (concat "^[ \t]*{%-? *.*?{% *end" (regexp-opt (twig-indenting-keywords))))))
                (current-indentation)
              (- (current-indentation) indent-width)))
        (if (looking-at "^[ \t]*</") ; Assume sgml end block trust sgml
            default
          (save-excursion
            (twig-calculate-indent-backward default)))))))

(defun twig-indent-line ()
  "Indent current line as Twig code"
  (interactive)
  (let ((old_indent (current-indentation)) (old_point (point)))
    (move-beginning-of-line nil)
    (let ((indent (max 0 (twig-calculate-indent))))
      (indent-line-to indent)
      (if (< old_indent (- old_point (line-beginning-position)))
          (goto-char (+ (- indent old_indent) old_point)))
      indent)))


;;;###autoload
(define-derived-mode twig-mode sgml-mode  "Twig"
  "Major mode for editing twig files"
  :group 'twig
  ;; Disabling this because of this emacs bug:
  ;;  http://lists.gnu.org/archive/html/bug-gnu-emacs/2002-09/msg00041.html
  ;; (modify-syntax-entry ?\'  "\"" sgml-mode-syntax-table)
  (set (make-local-variable 'comment-start) "{#")
  (set (make-local-variable 'comment-start-skip) "{#")
  (set (make-local-variable 'comment-end) "#}")
  (set (make-local-variable 'comment-end-skip) "#}")
  ;; it mainly from sgml-mode font lock setting
  (set (make-local-variable 'font-lock-defaults)
       '((
          twig-font-lock-keywords
          twig-font-lock-keywords-1
          twig-font-lock-keywords-2
          twig-font-lock-keywords-3)
         nil t nil nil
         (font-lock-syntactic-keywords
          . sgml-font-lock-syntactic-keywords)))
  (set (make-local-variable 'indent-line-function) 'twig-indent-line))

(define-key twig-mode-map (kbd "C-c c") 'twig-close-tag)
(define-key twig-mode-map (kbd "C-c t") 'twig-insert-tag)
(define-key twig-mode-map (kbd "C-c v") 'twig-insert-var)
(define-key twig-mode-map (kbd "C-c #") 'twig-insert-comment)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.twig\\'" . twig-mode))

(provide 'twig-mode)

;;; twig-mode.el ends here
