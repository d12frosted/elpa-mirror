;;; wisp-mode.el --- Tools for wisp: the Whitespace-to-Lisp preprocessor

;; Copyright (C) 2013--2016  Arne Babenhauserheide <arne_bab@web.de>
;; Copyright (C) 2015--2016  Kevin W. van Rooijen — indentation and tools
;;               from https://github.com/kwrooijen/indy/blob/master/indy.el

;; Author: Arne Babenhauserheide <arne_bab@web.de>
;; Version: 0.2.9
;; Package-Version: 20210405.1410
;; Package-Commit: a144cfd1604c308f65f990a1e994ab0d5d7fe244
;; Keywords: languages, lisp, scheme
;; Homepage: http://www.draketo.de/english/wisp
;; Package-Requires: ((emacs "24.4"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; To use, add wisp-mode.el to your Emacs Lisp path and add the following
;; to your ~/.emacs or ~/.emacs.d/init.el
;; 
;; (require 'wisp-mode)
;; 
;; For details on wisp, see
;; https://www.draketo.de/english/wisp
;;
;; If you came here looking for wisp the lisp-to-javascript
;; compiler[1], have a look at wispjs-mode[2].
;; 
;; [1]: http://jeditoolkit.com/try-wisp
;; 
;; [2]: http://github.com/krisajenkins/wispjs-mode
;; 
;; ChangeLog:
;;
;;  - 0.2.9: enabled imenu - thanks to Greg Reagle!
;;  - 0.2.8: use electric-indent-inhibit instead of electric-indent-local-mode
;;           rename gpl.txt to COPYING for melpa
;;           use the variable defined by define-derived-mode
;;  - 0.2.7: dependency declared, always use wisp--prefix, homepage url
;;  - 0.2.6: remove unnecessary autoloads
;;  - 0.2.5: backtab chooses existing lower indentation values from previous lines.
;;  - 0.2.4: better indentation support:
;;           cycle forward on tab,
;;           cycle backwards on backtab (s-tab),
;;           keep indentation on enter.
;;  - 0.2.1: Disable electric-indent-local-mode in wisp-mode buffers.
;;  - 0.2: Fixed the regular expressions.  Now org-mode HTML export works with wisp-code.
;; 
;;; Code:

(require 'scheme)

; see http://www.emacswiki.org/emacs/DerivedMode

; font-lock-builtin-face 	font-lock-comment-delimiter-face
; font-lock-comment-face 	font-lock-constant-face
; font-lock-doc-face 	font-lock-fic-author-face
; font-lock-fic-face 	font-lock-function-name-face
; font-lock-keyword-face 	font-lock-negation-char-face
; font-lock-preprocessor-face 	font-lock-reference-face
; font-lock-string-face
; font-lock-type-face 	font-lock-variable-name-face
; font-lock-warning-face

; note: for easy testing: emacs -Q wisp-mode.el -e eval-buffer wisp-guile.w -e delete-other-windows


(defvar wisp-builtin '("and" "char=?" "define" "define-syntax" "define-syntax-rule" "defun" "if" "let" "let*" "not" "or" "set!" "set!" "set" "setq" "syntax-case" "syntax-rules" "when" "while")) ; alphabetical order

; TODO: Add special treatment for defun foo : bar baz ⇒ foo = function, bar and baz not.
; TODO: Add highlighting for `, , and other macro-identifiers.
; TODO: take all identifiers from scheme.el
(defvar wisp-font-lock-keywords
  `((
     ("\\`#!.*" . font-lock-comment-face) ; initial hashbang
     ("\"\\.\\*\\?" . font-lock-string-face) ; strings (anything between "")
     ("[{}]" . font-lock-string-face)      ; emphasize curly infix
     ; ("^_+ *$" . font-lock-default-face) ; line with only underscores
                                           ; and whitespace shown as
                                           ; default text. This is just
                                           ; a bad workaround.
                                           ; Which does not work because
                                           ; *-default-face is not guaranteed
                                           ; to be defined.
     ("^\\(?:_* +\\| *\\): *$" . font-lock-keyword-face) ; line with only a : + whitespace, not at the beginning
     ("^\\(?:_* +\\| *\\): \\| *\\. " . font-lock-keyword-face) ; leading : or .
     ( ,(regexp-opt wisp-builtin 'symbols) . font-lock-builtin-face) ; generic functions
     ;                                 v there is a tab here.
     ("^\\(?:_*\\)\\(?: +\\)\\([^:][^ 	]*\\)" . font-lock-function-name-face) ; function calls as start of the line
     ;                     v there is a tab here.
     ("^\\(?: *\\)[^ :][^ 	]*" . font-lock-function-name-face) ; function calls as start of the line
     (" : " "\\=\\([^ 	]+\\)" nil nil (1 font-lock-function-name-face)) ; function calls with inline :
     ("[^']( *" "\\=\\([^ 	)]+\\)" nil nil (1 font-lock-function-name-face)) ; function calls with (
     ("#[tf]"  . font-lock-constant-face) ; #t and #f
     ("#\\\\[^ 	]+"  . font-lock-constant-face) ; character literals
     (";" . 'font-lock-comment-delimiter-face)
     ; TODO: Doublecheck this regexp. I do not understand it completely anymore.
     ("\\_<[+-]?[0-9]+\\_>\\|\\_<[+-][0-9]*\\.[0-9]*\\(e[+-]?[0-9]+\\)?\\_>" . font-lock-constant-face) ; numbers
     ("'()" . font-lock-constant-face) ; empty list
     ("[ 	]'[^	 ]+" . font-lock-constant-face) ; 'name
     ; FIXME: This is too general (it will capture a . 'b, making it
     ; impossible to have 'b highlighted)
     (" : \\| \\. " . font-lock-keyword-face) ; leading : or .
     ))
  "Default highlighting expressions for wisp mode.")
(defun wisp--prev-indent ()
  "Get the amount of indentation spaces of the previous line."
  (save-excursion
    (forward-line -1)
    (while (wisp--line-empty?)
      (forward-line -1))
    (back-to-indentation)
    (current-column)))

(defun wisp-prev-indent-lower-than (indent)
  "Get the indentation which is lower than INDENT among previous lines."
  (save-excursion
    (forward-line -1)
    (while (or (wisp--line-empty?)
               (and (>= (wisp--current-indent) indent)
                    (> (wisp--current-indent) 0)))
      (forward-line -1))
    (back-to-indentation)
    (current-column)))

(defun wisp--line-empty? ()
  "Check if the current line is empty."
  (string-match "^\s*$" (wisp--get-current-line)))

(defun wisp--get-current-line ()
  "Get the current line as a string."
  (buffer-substring-no-properties (point-at-bol) (point-at-eol)))

(defun wisp--current-indent ()
  "Get the amount of indentation spaces if the current line."
  (save-excursion
    (back-to-indentation)
    (current-column)))

(defun wisp--fix-num (num)
  "Make sure NUM is a valid number for calculating indentation."
  (cond
   ((not num) 0)
   ((< num 0) 0)
   (t num)))

(defun wisp--indent (num)
  "Indent the current line by the amount of provided in NUM."
  (let ((currcol (current-column))
        (currind (wisp--current-indent)))
    (unless (equal currind num)
      (let ((num (max num 0)))
        (indent-line-to num))
      (unless (<= currcol currind)
        (move-to-column (wisp--fix-num (+ num (- currcol currind))))))))

(defun wisp--tab ()
  "Cycle through indentations depending on the previous line.

If the current indentation is equal to the previous line,
   increase indentation by one tab,
if the current indentation is zero,
   indent up to the previous line
if the current indentation is less than the previous line,
   increase by one tab, but at most to the previous line."
  (interactive)
  (let* ((curr (wisp--current-indent))
         (prev (wisp--prev-indent))
         (width
          (cond
           ((equal curr prev) (+ prev tab-width))
           ((= curr 0) prev)
           ((< curr prev) (min prev (+ curr tab-width)))
           (t  0))))
    (wisp--indent width)))

(defun wisp--backtab ()
  "Cycle through indentations depending on the previous line.

This is the inverse of 'wisp--tab', except that it jums from 0 to
prev, not to prev+tab."
  (interactive)
  (let* ((curr (wisp--current-indent))
         (prev (wisp--prev-indent))
         (width
          (cond
           ((<= curr prev)
            (wisp-prev-indent-lower-than curr))
           ((= curr 0) prev)
           ((> curr prev) prev)
           (t  0))))
    (wisp--indent width)))

(defun wisp--return ()
  "Enter a newline while keeping indentation."
  (interactive)
  (let* ((curr (wisp--current-indent))
         (prev (wisp--prev-indent)))
    (newline)
    (wisp--indent curr)))



; use this mode automatically
;;;###autoload
(define-derived-mode wisp-mode
  emacs-lisp-mode "Wisp"
  "Major mode for whitespace-to-lisp files.

  \\{wisp-mode-map}"
  ;; :group wisp
  (set (make-local-variable 'indent-tabs-mode) nil)
  (setq comment-start ";")
  (setq comment-end "")
  ;; delimiters from https://docs.racket-lang.org/guide/symbols.html
  ;; ( ) [ ] { } " , ' ` ; # | \
  (setq imenu-generic-expression
    '((nil "^define\\(/contract\\)? +:? *\\([^[ \n(){}\",'`;#|\\\]+\\)" 2)))
  (set (make-local-variable 'font-lock-comment-start-skip) ";+ *")
  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  (set (make-local-variable 'font-lock-defaults) wisp-font-lock-keywords)
  (set (make-local-variable 'mode-require-final-newline) t)
  ;; bind keys to \r, not (kbd "<return>") to allow completion to work on RET
  (define-key wisp-mode-map (kbd "C-c i") '("imenu" . imenu))
  (define-key wisp-mode-map (kbd "<tab>") '("indent line" . wisp--tab))
  (define-key wisp-mode-map (kbd "<backtab>") '("unindent line" . wisp--backtab))
  (define-key wisp-mode-map "\r" '("wisp newline" . wisp--return)))

; use this mode automatically
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.w\\'" . wisp-mode))
;;;###autoload
(add-hook 'wisp-mode-hook
          (lambda ()
            (setq electric-indent-inhibit t)))


                        

(provide 'wisp-mode)
;;; wisp-mode.el ends here
