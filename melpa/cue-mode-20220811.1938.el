;;; cue-mode.el --- Major mode for CUE language files -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2022  Russell Sim

;; Author: Russell Sim <russell.sim@gmail.com>
;; Keywords: data, languages
;; Package-Version: 20220811.1938
;; Package-Commit: 31c671d56e7884fa87ad0f1d27d0bb439dc65380
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/russell/cue-mode
;; Version: 1.0.11

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides Emacs font-lock, indentation, and some useful functions
;; for the CUE data validation language.
;;
;; This mode has the following keybindings:
;;   'C-c C-c' evaluate the current buffer and show the output
;;   'C-c C-r' reformat the current buffer

;;; Code:

(require 'smie)
(require 'cl-extra)

(defgroup cue '()
  "Major mode for editing CUE files."
  :group 'languages)

(defcustom cue-eval-command
  '("cue" "eval")
  "CUE command to run in ‘cue-eval-buffer’.
See also: `cue-command-options'."
  :type '(repeat string)
  :group 'cue)

(defcustom cue-command-options
  '()
  "A list of options and values to pass to `cue-command'.
For example:
  '(\"-e\" \"Nginx.Out\" \"--out=text\")"
  :group 'cue
  :type '(repeat string))

(defcustom cue-fmt-command
  '("cue" "fmt")
  "CUE format command."
  :type '(repeat string)
  :group 'cue)

(defcustom cue-library-search-directories
  nil "Sequence of CUE package search directories."
  :type '(repeat directory)
  :group 'cue)

(defcustom cue-indent-level
  4
  "Number of spaces to indent with."
  :type '(number)
  :group 'cue)

(defvar cue--identifier-regexp
  "[a-zA-Z_][a-zA-Z0-9_]*"
  "Regular expression matching a CUE identifier.")

(defvar cue-font-lock-keywords
  (let ((builtin-regex (regexp-opt '("package" "import" "for" "in" "if" "let") 'words))
        (constant-regex (regexp-opt '("false" "null" "true") 'words))
        ;; All builtin functions (see https://cue.org/docs/references/spec/#builtin-functions)
        (standard-functions-regex (regexp-opt '("len" "close" "and" "or" "div" "mod" "quo" "rem") 'words)))
    (list
     `(,builtin-regex . font-lock-builtin-face)
     `(,constant-regex . font-lock-constant-face)
     ;; identifiers starting with a # or _ are reserved for definitions
     ;; and hidden fields
     `(,(concat "_?#" cue--identifier-regexp "+:?") . font-lock-type-face)
     `(,(concat cue--identifier-regexp "+:") . font-lock-keyword-face)
     ;; all identifiers starting with __(double underscores) as keywords
     `(,(concat "__" cue--identifier-regexp) . font-lock-keyword-face)
     `(,standard-functions-regex . font-lock-function-name-face)))
  "Minimal highlighting for ‘cue-mode’.")

(defun cue-syntax-stringify ()
  "Put `syntax-table' property correctly on single/triple quotes."
  ;; This function is mostly a copy of the python multi-line string
  ;; code.
  (let* ((ppss (save-excursion (backward-char 3) (syntax-ppss)))
         (string-start (and (eq t (nth 3 ppss)) (nth 8 ppss)))
         (quote-starting-pos (- (point) 3))
         (quote-ending-pos (point)))
    (cond ((or (nth 4 ppss)             ;Inside a comment
               (and string-start
                    ;; Inside of a string quoted with different triple quotes.
                    (not (eql (char-after string-start)
                              (char-after quote-starting-pos)))))
           ;; Do nothing.
           nil)
          ((nth 5 ppss)
           ;; The first quote is escaped, so it's not part of a triple quote!
           (goto-char (1+ quote-starting-pos)))
          ((null string-start)
           ;; This set of quotes delimit the start of a string.
           (put-text-property quote-starting-pos (1+ quote-starting-pos)
                              'syntax-table (string-to-syntax "|")))
          (t
           ;; This set of quotes delimit the end of a string.
           (put-text-property (1- quote-ending-pos) quote-ending-pos
                              'syntax-table (string-to-syntax "|"))))))

(defvar cue-smie-verbose-p nil
  "Emit context information about the current syntax state.")

(defmacro cue-smie-debug (message &rest format-args)
  "Emit debug log for SMIE if `cue-smie-verbose-p' is true.

`MESSAGE' is a format string and a `FORMAT-ARGS' are the list of
values to be formatted."
  `(progn
     (when cue-smie-verbose-p
       (message ,message ,@format-args))
     nil))

(defun cue-smie-rules-verbose (kind token)
  "Apply SMIE indentation rules for a particular KIND, TOKEN.

KIND is :BEFORE, :AFTER, :ELEM, or :LIST-INTRO, and TOKEN in the
syntax that the rule operates on."
  (let ((value (cue-smie-rules kind token)))
    (cue-smie-debug "%s '%s'; sibling-p:%s prev-is-OP:%s hanging:%s == %s" kind token
                    (ignore-errors (smie-rule-sibling-p))
                    (ignore-errors (smie-rule-prev-p "OP"))
                    (ignore-errors (smie-rule-hanging-p))
                    value)
    value))

(defvar cue-smie-grammar
  (smie-prec2->grammar
   (smie-merge-prec2s
    (smie-bnf->prec2
     '((exps (exp "," exp))
       (exp (field)
            ("import" id)
            ("package" id)
            (id))
       (field (id ":" exp))
       (id))
     '((assoc ",") (assoc "\n") (left ":") (left ".") (left "let"))
     '((right "=")))

    (smie-precs->prec2
     '((right "=")
       (left "||" "|")
       (left "&&" "&")
       (nonassoc "=~" "!~" "!=" "==" "<=" ">=" "<" ">")
       (left "+" "-")
       (left "*" "/")))))
  "CUE language grammar tables.")

;; Operators
;; +     &&    ==    <     =     (     )
;; -     ||    !=    >     :     {     }
;; *     &     =~    <=    ?     [     ]     ,
;; /     |     !~    >=    !     _|_   ...   .
;; _|_ bottom

(defun cue-smie-rules (kind token)
  "Apply SMIE indentation rules for a particular KIND, TOKEN.

KIND is :BEFORE, :AFTER, :ELEM, or :LIST-INTRO, and TOKEN in the
syntax that the rule operates on."
  (pcase (cons kind token)
    (`(:elem . basic) smie-indent-basic)
    (`(,_ . ",") (cue-smie--indent-nested))
    (`(,_ . "}") (cue-smie--indent-closing))
    (`(,_ . "]") (smie-rule-parent (- 0 cue-indent-level)))
    (`(,_ . ")") (smie-rule-parent (- 0 cue-indent-level)))))

(defun cue-smie--in-object-p ()
  "Return t if the current block we are in is wrapped in {}."
  (let ((ppss (syntax-ppss)))
    (or (null (nth 1 ppss))
        (and (nth 1 ppss)
             (or
              (eq ?{ (char-after (nth 1 ppss)))
              (eq ?\( (char-after (nth 1 ppss))))))))

(defun cue-smie-forward-token ()
  "Function to scan forward for the next token.
Called with no argument should return a token and move to its end.
If no token is found, return nil or the empty string.
It can return nil when bumping into a parenthesis, which lets SMIE
use syntax-tables to handle them in efficient C code."
  (skip-chars-forward " \t")
  (cond
   ((and (looking-at "[\n]")
         (or (save-excursion (skip-chars-backward " \t")
                             ;; Only add implicit , when needed.
                             (or (bolp) (eq (char-before) ?\,)))
             (cue-smie--in-object-p)))
    (if (eolp) (forward-char 1) (forward-comment 1))
    ;; Why bother distinguishing \n and ;?
    ",") ;;"\n"
   ((progn (forward-comment (point-max)) nil))
   (t
    (buffer-substring-no-properties
     (point)
     (progn (if (zerop (skip-syntax-forward "."))
                (skip-syntax-forward "w_'"))
            (point))))))

(defun cue-smie-backward-token ()
  "Function to scan backward the previous token.
Same calling convention as `cue-smie-forward-token' except
it should move backward to the beginning of the previous token."
  (let ((pos (point)))
    (forward-comment (- (point)))
    (cond
     ((and (not (eq (char-before) ?\,)) ;Coalesce ";" and "\n".
           (> pos (line-end-position))
           (cue-smie--in-object-p))
      (skip-chars-forward " \t")
      ;; Why bother distinguishing \n and ,?
      ",") ;;"\n"
     (t
      (buffer-substring-no-properties
       (point)
       (progn (if (zerop (skip-syntax-backward "."))
                  (skip-syntax-backward "w_'"))
              (point)))))))

(defun cue-smie--indent-nested ()
  "Apply indentation for for a nested element."
  (let ((ppss (syntax-ppss)))
    (if (nth 1 ppss)
        (let ((parent-indentation (save-excursion
                                    (goto-char (nth 1 ppss))
                                    (back-to-indentation)
                                    (current-column))))
          (cons 'column (+ parent-indentation cue-indent-level))))))

(defun cue-smie--indent-closing ()
  "Apply indentation for a closing scope."
  (let ((ppss (syntax-ppss)))
    (if (nth 1 ppss)
        (let ((parent-indentation (save-excursion
                                    (goto-char (nth 1 ppss))
                                    (back-to-indentation)
                                    (current-column))))
          (cons 'column parent-indentation)))))

(defvar cue-syntax-propertize-function
  (syntax-propertize-rules
   ((rx (or "\"\"\"" "'''"))
    (0 (ignore (cue-syntax-stringify))))))

(defconst cue-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; Comments. CUE supports /* */ and // as comment delimiters
    (modify-syntax-entry ?/ ". 124" table)
    ;; Additionally, CUE supports # as a comment delimiter
    (modify-syntax-entry ?\n ">" table)
    ;; ", ', ,""" and ''' are quotations in CUE.
    ;; both """ and ''' are handled by cue--syntax-propertize-function
    (modify-syntax-entry ?' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    ;; Our parenthesis, braces and brackets
    (modify-syntax-entry ?\( "()" table)
    (modify-syntax-entry ?\) ")(" table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    table)
  "Syntax table for `cue-mode'.")

(defvar cue-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'cue-eval-buffer)
    (define-key map (kbd "C-c C-r") 'cue-reformat-buffer)
    map)
  "Keymap used in CUE mode.")

;;;###autoload
(define-derived-mode cue-mode prog-mode "CUE Mode"
  "Major mode for editing CUE files.

\\{cue-mode-map}"
  :syntax-table cue-mode-syntax-table
  (setq-local font-lock-defaults '(cue-font-lock-keywords ;; keywords
                                   nil  ;; keywords-only
                                   nil  ;; case-fold
                                   nil  ;; syntax-alist
                                   nil  ;; syntax-begin
                                   ))

  (setq-local syntax-propertize-function
              cue-syntax-propertize-function)

  ;; cue lang uses tabs for indent by default
  (setq-local indent-tabs-mode t)
  (setq-local tab-width cue-indent-level)

  (smie-setup cue-smie-grammar 'cue-smie-rules-verbose
              :forward-token  #'cue-smie-forward-token
              :backward-token #'cue-smie-backward-token)
  (setq-local smie-indent-basic cue-indent-level)
  (setq-local smie-indent-functions '(smie-indent-fixindent
                                      smie-indent-bob
                                      smie-indent-comment
                                      smie-indent-comment-continue
                                      smie-indent-comment-close
                                      smie-indent-comment-inside
                                      smie-indent-inside-string
                                      smie-indent-keyword
                                      smie-indent-after-keyword
                                      smie-indent-empty-line
                                      smie-indent-exps))

  (setq-local comment-start "// ")
  (setq-local comment-start-skip "//+[\t ]*")
  (setq-local comment-end ""))

;;;###autoload
(add-to-list 'auto-mode-alist (cons "\\.cue\\'" 'cue-mode))

;;;###autoload
(defun cue-eval-buffer ()
  "Run cue with the path of the current file."
  (interactive)
  (let ((file-to-eval (file-truename (buffer-file-name)))
        (search-dirs cue-library-search-directories)
        (output-buffer-name "*cue output*"))
    (save-some-buffers (not compilation-ask-about-save)
                       (let ((directories (cons (file-name-directory file-to-eval)
                                                search-dirs)))
                         (lambda ()
                           (member (file-name-directory (file-truename (buffer-file-name)))
                                   directories))))
    (let ((cmd (car cue-eval-command))
          (args (append (cdr cue-eval-command)
                        cue-command-options
                        (cl-loop for dir in search-dirs
                                 collect "-I"
                                 collect dir)
                        (list file-to-eval))))
      (let* ((outbuf (get-buffer-create output-buffer-name))
             (outwindow (car (get-buffer-window-list outbuf)))
             (outwindow-start (when outwindow (window-start outwindow))))
        (with-current-buffer outbuf
          (setq default-directory (file-name-directory file-to-eval))
          (let ((origional-point (point)))
            (setq buffer-read-only nil)
            (erase-buffer)
            (if (zerop (apply #'call-process cmd nil t nil args))
                (progn
                  (cue-mode)
                  (view-mode))
              (compilation-mode nil))
            (if outwindow
                (set-window-start outwindow outwindow-start)
              (goto-char origional-point))))
        (display-buffer outbuf '(nil (allow-no-window . t)))))))

;;;###autoload
(defun cue-reformat-buffer ()
  "Reformat entire buffer using the CUE format utility."
  (interactive)
  (let ((point (point))
        (file-name (buffer-file-name))
        (stdout-buffer (get-buffer-create "*cue fmt stdout*"))
        (stderr-buffer-name "*cue fmt stderr*")
        (stderr-file (make-temp-file "cue fmt")))
    (when-let ((stderr-window (get-buffer-window stderr-buffer-name t)))
      (quit-window nil stderr-window))
    (unwind-protect
        (let* ((only-test buffer-read-only)
               (exit-code (apply #'call-process-region nil nil (car cue-fmt-command)
                                 nil (list stdout-buffer stderr-file) nil
                                 (append (cdr cue-fmt-command)
                                         (when only-test '("--test"))
                                         '("-")))))
          (cond ((zerop exit-code)
                 (progn
                   (if (or only-test
                           (zerop (compare-buffer-substrings nil nil nil stdout-buffer nil nil)))
                       (message "No format change necessary.")
                     (erase-buffer)
                     (insert-buffer-substring stdout-buffer)
                     (goto-char point))
                   (kill-buffer stdout-buffer)))
                ((and only-test (= exit-code 2))
                 (message "Format change is necessary, but buffer is read-only."))
                (t (with-current-buffer (get-buffer-create stderr-buffer-name)
                     (setq buffer-read-only nil)
                     (insert-file-contents stderr-file t nil nil t)
                     (goto-char (point-min))
                     (when file-name
                       (while (search-forward "<stdin>" nil t)
                         (replace-match file-name)))
                     (set-buffer-modified-p nil)
                     (compilation-mode nil)
                     (display-buffer (current-buffer)
                                     '((display-buffer-reuse-window
                                        display-buffer-at-bottom
                                        display-buffer-pop-up-frame)
                                       .
                                       ((window-height . fit-window-to-buffer))))))))
      (delete-file stderr-file))))

(provide 'cue-mode)
;;; cue-mode.el ends here
