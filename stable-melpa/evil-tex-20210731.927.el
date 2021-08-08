;;; evil-tex.el --- Useful features for editing LaTeX in evil-mode -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2020-2021 Yoav Marco, Itai Y. Efrat
;;
;; Authors: Yoav Marco <https://github.com/ymarco>, Itai Y. Efrat <https://github.com/iyefrat>
;; Maintainers: Yoav Marco <yoavm448@gmail.com>, Itai Y. Efrat <itai3397@gmail.com>
;; Created: February 01, 2020
;; Modified: August 02, 2020
;; Version: 1.0.2
;; Package-Version: 20210731.927
;; Package-Commit: aa0ddf8e768a24cda6d50d07f04c8e7813a2dccd
;; Keywords: tex, emulation, vi, evil, wp
;; Homepage: https://github.com/iyefrat/evil-tex
;; Package-Requires: ((emacs "26.1") (evil "1.0") (auctex "11.88"))
;;
;; This file is NOT part of GNU Emacs.
;;
;;; License:
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;;  Useful features for editing LaTeX in evil-mode
;;
;;; Code:


(require 'cl-lib)
(require 'latex) ; from auctex
(require 'evil)
(require 'subr-x)

(defgroup evil-tex nil
  "Advanced `evil' editing shortcuts to (la)tex."
  :version "25.1"
  :group 'applications
  :prefix "evil-tex-")

;;; declaring optional external functions used

(defvar which-key-idle-delay)
(defvar which-key-replacement-alist)
(defvar evil-surround-pairs-alist)
(defvar evil-surround-local-inner-text-object-map-list)
(defvar evil-surround-local-outer-text-object-map-list)
(defvar evil-embrace-evil-surround-keys)
(defvar evil-snipe--last-direction)
(declare-function evil-snipe-t "ext:evil-snipe")
(declare-function which-key--hide-popup "ext:which-key")
(declare-function which-key--show-keymap "ext:which-key")

;;; helper functions for text objects

(defun evil-tex-max-key (seq fn &optional compare-fn)
  "Return the element of SEQ for which FN gives the biggest result.

Comparison is done with COMPARE-FN if defined, and with `>' if not.
\(evil-tex-max-key '(1 2 -4) (lambda (x) (* x x))) => -4"
  (let* ((res (car seq))
         (res-val (funcall fn res))
         (compare-fn (or compare-fn #'>)))
    (dolist (cur (cdr seq))
      (let ((cur-val (funcall fn cur)))
        (when (funcall compare-fn cur-val res-val)
          (setq res-val cur-val
                res cur))))
    res))

(defun evil-tex--delim-compare (x y)
  "Return t if the X delims are closer the point than Y.

X and Y have the format of (left-outer right-outer left-inner right-inner),
chose [[\\left(]] over \\left[[(]], etc."
  (let ((lax (nth 0 x))
        (lix (nth 2 x))
        (lay (nth 0 y))
        (liy (nth 2 y)))
    (cond
     ((not x)                        nil)
     ((not y)                        t)
     ((> lix liy)                    t)
     ((and (= lix liy) (< lax lay))  t)
     (t nil))))

(defun evil-tex--delim-finder (deliml delimr args)
  "Return delimiter locations for `evil-tex--select-delim'.

DELIML and DELIMR are strings of the left and right delimiters respectively.
ARGS is the information about the text object needed for the functions to work

The format for the return is (outer-beg outer-end inner-beg inner-end)."
  (let ((delim-pair-outer (ignore-errors
                            (apply #'evil-select-paren
                                   (regexp-quote deliml)
                                   (regexp-quote delimr) (append args '(t)))))
        (delim-pair-inner (ignore-errors
                            (apply #'evil-select-paren
                                   (regexp-quote deliml)
                                   (regexp-quote delimr) (append args '(nil))))))
    (when (and delim-pair-outer delim-pair-inner)
      (nconc (nbutlast delim-pair-outer 3) (nbutlast delim-pair-inner 3)))))

(defun evil-tex--select-delim (&rest args)
  "Return (outer-beg outer-end inner-beg inner-end) of closest delimiter object.

ARGS passed to `evil-select-paren', within `evil-tex--delim-finder'."
  (evil-tex-max-key
   (cl-loop for (l r)
            in (list '( "(" ")" )
                     '( "[" "]" )
                     '( "\\{" "\\}" )
                     '( "\\langle" "\\rangle" ))
            append (cl-loop for (pre-l pre-r)
                            in (list '( "" "" )
                                     '( "\\left" "\\right"  )
                                     '( "\\bigl" "\\bigr"   ) '( "\\big" "\\big"   )
                                     '( "\\biggl" "\\biggr" ) '( "\\bigg" "\\bigg" )
                                     '( "\\Bigl" "\\Bigr"   ) '( "\\Big" "\\Big"   )
                                     '( "\\Biggl" "\\Biggr" ) '( "\\Bigg" "\\Bigg" ))
                            collect (evil-tex--delim-finder (concat pre-l l) (concat pre-r r) args)))
   (lambda (arg) (when (consp arg) ; check if selection succeeded
                   arg))
   #'evil-tex--delim-compare))

(defvar evil-tex--last-command-empty nil
  "Global to hold if the last command text object used was empty.

For example, \\epsilon is empty, \\dv{x} is not.")

(defun evil-tex--select-command ()
  "Return (outer-beg outer-end inner-beg inner-end) of command (macro) object.

Inner commmand defined to be what is inside {}'s and []'s, or empty if none exist."

  (let ((beg-an (TeX-find-macro-start))
        (end-an (TeX-find-macro-end))
        beg-inner end-inner)
    (save-excursion
      (goto-char beg-an)
      (if (re-search-forward "{\\|\\[" end-an t)
          (setq evil-tex--last-command-empty nil)
        (setq evil-tex--last-command-empty t)))
    (unless beg-an
      (user-error "No surrounding command found"))
    (save-excursion
      (goto-char beg-an)
      (if (re-search-forward "{\\|\\[" end-an t)
          (setq beg-inner (point))
        (setq beg-inner end-an))) ;goto opeing brace if exists.
    (save-excursion
      (goto-char end-an)
      (when (looking-back "}\\|\\]" (- (point) 2))
        (backward-char))
      (setq end-inner (point)) ; set end of inner to be {|} only in command is not empty
      (list beg-an end-an beg-inner end-inner))))

(defcustom evil-tex-include-newlines-in-envs t
  "Whether include newlines with env insersion.

When non-nil, env insersions would force separate lines for
\\begin, inner text, and \\end."
  :type 'boolean
  :group 'evil-tex)

(defcustom evil-tex-select-newlines-with-envs t
  "Whether to select newlines with env commands.

When non-nil, the newline proceeding \\begin{...} and preceding
\\end{...} is selected as part of the delimiter. This way, when
doing 'cie' you're placed on a separate line."
  :type 'boolean
  :group 'evil-tex)

(defun evil-tex--select-env ()
  "Return (outer-beg outer-end inner-beg inner-end) for enviornment object.

If `evil-tex-select-newlines-in-envs' is non-nil, the inner
variant would NOT include newlines proceeding the \\begin and
preceding the \\end.

\\begin{foobar}{bar}[baz]
^outer-beg              ^inner-beg
qux
\\end{foobar}
^inner-end  ^outer-end"
  (let (outer-beg outer-end inner-beg inner-end)
    (save-excursion
      (cond
       ;; `LaTeX-find-matching-begin' doesn't like being exactly on the \\begin
       ((looking-at (regexp-quote "\\begin{"))
        t)
       ;; `LaTeX-find-matching-begin' doesn't like being near the } of \\end{}
       ((or (= (char-before) ?})
            (= (char-after) ?}))
        (backward-char 2)
        (LaTeX-find-matching-begin))
       (t
        (LaTeX-find-matching-begin)))
      ;; We are at backslash of \\begin
      (setq outer-beg (point))
      (forward-sexp)
      (while (or
              (= (char-after) ?{)
              (= (char-after) ?\[))
        (forward-sexp))
      (when (and evil-tex-select-newlines-with-envs
                 (looking-at "\n[ \t]*"))
        (goto-char (match-end 0)))
      (setq inner-beg (point))
      (goto-char (1+ outer-beg))
      (LaTeX-find-matching-end)        ; we are at closing brace
      (setq outer-end (point))
      (search-backward "\\end")        ; goto backslash
      (when (and evil-tex-select-newlines-with-envs
                 (looking-back "\n[ \t]*" (- (point) 10)))
        (goto-char (match-beginning 0)))
      (setq inner-end (point))
      (list outer-beg outer-end inner-beg inner-end))))

(defun evil-tex--select-math (&rest args)
  "Return (outer-beg outer-end inner-beg inner-end) of closest LaTeX math match.

ARGS passed to `evil-select-paren' or `evil-select-quote'.
Math includes inline and display math, e.g. \\(foo\\), \\=\\[bar\\], and $baz$"

  (evil-tex-max-key
   (list
    (nconc (nbutlast (ignore-errors (apply #'evil-select-paren
                                           (regexp-quote "\\(") (regexp-quote "\\)") (append args '(t)))) 3)
           (nbutlast (ignore-errors (apply #'evil-select-paren
                                           (regexp-quote "\\(") (regexp-quote "\\)") (append args '(nil)))) 3))
    (nconc (nbutlast (ignore-errors (apply #'evil-select-paren
                                           (regexp-quote "\\[") (regexp-quote "\\]") (append args '(t)))) 3)
           (nbutlast (ignore-errors (apply #'evil-select-paren
                                           (regexp-quote "\\[") (regexp-quote "\\]") (append args '(nil)))) 3))
    (nconc (nbutlast (ignore-errors (apply #'evil-select-paren
                                           (regexp-quote "$") (regexp-quote "$") (append args '(t)))) 3)
           (nbutlast (ignore-errors (apply #'evil-select-paren
                                           (regexp-quote "$") (regexp-quote "$") (append args '(nil)))) 3)))
   (lambda (arg) (if (and (consp arg) ; selection succeeded
                          ;; Selection is close enough to point.
                          ;; evil-select-quote can select things further down in
                          ;; the buffer.
                          (<= (- (nth 0 arg) 2) (point))
                          (>= (+ (nth 1 arg) 3) (point)))
                     (car arg)
                   most-negative-fixnum))))

(defvar evil-tex--section-regexp
  "\\\\\\(part\\|chapter\\|subsubsection\\|subsection\\|section\\|subparagraph\\|paragraph\\)\\*?\\>"
  "Regexp for matches for LaTeX heading markup.")

(defun evil-tex--section-regexp-higher (str)
  "For heading of type STR, return a regexp for matching headings with an equal or more important level."
  (cond
   ((string-match "\\\\part\\*?\\>" str)
    "\\\\part\\*?\\>")
   ((string-match "\\\\chapter\\*?\\>" str)
    "\\\\\\(?:part\\|chapter\\)\\*?\\>")
   ((string-match "\\\\section\\*?\\>" str)
    "\\\\\\(?:part\\|chapter\\|section\\)\\*?\\>")
   ((string-match "\\\\subsection\\*?\\>" str)
    "\\\\\\(?:part\\|chapter\\|subsection\\|section\\)\\*?\\>")
   ((string-match "\\\\subsubsection\\*?\\>" str)
    "\\\\\\(?:part\\|chapter\\|subsubsection\\|subsection\\|section\\)\\*?\\>")
   ((string-match "\\\\paragraph\\*?\\>" str)
    "\\\\\\(?:part\\|chapter\\|subsubsection\\|subsection\\|section\\|paragraph\\)\\*?\\>")
   ((string-match "\\\\subparagraph\\*?\\>" str)
    "\\\\\\(?:part\\|chapter\\|subsubsection\\|subsection\\|section\\|subparagraph\\|paragraph\\)\\*?\\>")))

(defun evil-tex--select-section ()
  "Return (outer-beg outer-end inner-beg inner-end type) for section object.

The outer variant is defined from the first character of the
heading command, down to the line above the next heading of equal
or higher importance.

The inner variant starts after the end of the command, and
respects a following newline if exists.

'type' is the type of the heading, e.g subsection, chapter*.

Asterisk variation (e.g \\section{} and \\section*{}) are treated the same."
  (let (outer-beg outer-end inner-beg inner-end what-section)
    (save-excursion
      ;; back searching won't work if we are on the \section itself
      (search-backward "\\" (line-beginning-position) t)
      (if (looking-at evil-tex--section-regexp)
          (setq what-section (match-string 0))
        (re-search-backward evil-tex--section-regexp)
        (setq what-section (match-string 0)))
      ;; We are at backslash
      (setq outer-beg (point))
      (skip-chars-forward "^{")         ; goto opening brace
      (forward-sexp)                    ; goto closing brace
      (when (and evil-tex-select-newlines-with-envs
                 (looking-at "\n"))
        (forward-line 1))
      (setq inner-beg (point))
      (re-search-forward (concat (evil-tex--section-regexp-higher what-section) "\\|\\\\end{document}\\|\\'"))
      (move-beginning-of-line 1)
      (setq inner-end (point)
            outer-end (point))
      (list outer-beg outer-end inner-beg inner-end what-section))))

(defun evil-tex--goto-script-prefix (subsup)
  "Go to end of the found SUBSUP (\"^\" or \"_\").

{(ab)}_c => {(ab)}_c
    ^              ^"
  (let ((orig-point (point))
        subsup-end)
    (or
     ;; subsup after point
     (when (search-forward subsup (line-end-position 2) t) ; 2 lines down
       (let (beg end)
         (setq subsup-end (match-end 0))
         (goto-char (match-beginning 0))
         (setq end (point))
         (when
             (cond
              ;; {}^
              ((= (char-before) ?})
               (backward-sexp)
               (setq beg (point)))
              ;; \command^
              ((save-excursion (and (search-backward "\\" (line-beginning-position) t)
                                    (looking-at "\\\\[A-Za-z@*]+")
                                    (= end (match-end 0))))
               (search-backward "\\" (line-beginning-position) t)
               (setq beg (match-beginning 0)))
              ;; a^
              (t
               (setq beg (1- (point)))))
           ;; require point to be inside the base bounds
           (<= beg orig-point end))))
     ;; subsup before point
     (when (progn (goto-char orig-point)
                  (search-backward subsup (line-beginning-position 0)))
       (setq subsup-end (match-end 0)))
     (user-error "No surrounding %s found" subsup))
    (goto-char subsup-end)))

(defun evil-tex--select-script (subsup)
  "Return (outer-beg outer-end inner-beg inner-end) for script object.
SUBSUP should be either _ or ^. The outer selections will include SUBSUP,
and the inner ones will not include it or surrounding {} if they exist."
  (let (outer-beg outer-end inner-beg inner-end)
    (save-excursion
      (evil-tex--goto-script-prefix subsup)
      (setq outer-beg (1- (point)))
      (when (looking-at "{") ; select brace if present
        (forward-char 1))
      (setq inner-beg (point)))
    (save-excursion
      (evil-tex--goto-script-prefix subsup)
      (cond
       ;; a_{something}
       ((looking-at "{")
        (forward-sexp)
        (setq inner-end (1- (point))
              outer-end (point)))
       ;; a_\something
       ((looking-at "\\\\[a-zA-Z@*]+")
        (goto-char (match-end 0))
        ;; skip command arguments
        (while (looking-at "{\\|\\[")
          (forward-sexp))
        (setq inner-end (point)
              outer-end (point)))
       (t ;; a_1 a_n
        (forward-char)
        (setq inner-end (point)
              outer-end (point)))))
    (list outer-beg outer-end inner-beg inner-end)))

(defun evil-tex--select-table-cell ()
  "Return (outer-beg outer-end inner-beg inner-end) for table cell object."
  (let ((env (evil-tex--select-env))
        outer-beg outer-end
        inner-beg inner-end
        env-beg env-end
        (cell-at-line-beg nil)
        (found-beg nil) (found-end nil))
    (save-excursion
      (setq env-beg (nth 2 env)
            env-end (nth 3 env))
      (when (or (> env-beg (point)) (<= env-end (point))) ;; for when you are on \begin or \end of a sub-env.
        (save-excursion
          (goto-char (1- (nth 0 env)))
          (setq env (evil-tex--select-env)
                env-beg (nth 2 env)
                env-end (nth 3 env))))
      (while (not found-beg)
        (cond
         ((looking-at "&")
          (setq outer-beg (point)
                inner-beg (1+ (point))
                found-beg t))
         ((looking-at "\\\\end")
          (forward-char 4))
         ((and (looking-at "end") (looking-back "\\\\" (- (point) 1)))
          (forward-char 3))
         ((and (looking-at "nd") (looking-back "\\\\e" (- (point) 2)))
          (forward-char 2))
         ((and (looking-at "d") (looking-back "\\\\en" (- (point) 3)))
          (forward-char)))

        (unless found-beg ;; repeatd searches to jump over nested envs
          (if (re-search-backward "&\\|\\\\\\\\\\|\\\\end" env-beg t)
              (cond
               ((looking-at "&")
                (setq outer-beg (point)
                      inner-beg (1+ (point))
                      found-beg t))
               ;; \\ and end of line, with allowence for whitespace and comments
               ((looking-at "\\\\\\\\\\(?:\s*\\(?:%.*\\)?\\)?\n")
                (setq outer-beg (+ 3 (point))
                      inner-beg (+ 3 (point))
                      cell-at-line-beg t
                      found-beg t))
               ((looking-at "\\\\\\\\")
                (setq outer-beg (point)
                      inner-beg (+ 2 (point))
                      found-beg t))
               ((looking-at "\\\\end")
                (LaTeX-find-matching-begin)))
            (setq outer-beg env-beg
                  inner-beg env-beg
                  found-beg t))))
      (goto-char inner-beg)
      (while (not found-end)
        (if (re-search-forward "&\\|\\\\\\\\\\|\\\\begin" env-end t)
            (progn
              (backward-char)
              (cond
               ((looking-at "&")
                (setq outer-end (if cell-at-line-beg (1+ (point)) (point))
                      inner-end (point)
                      found-end t))
               ((looking-at "\\\\")
                (setq outer-end (1- (point))
                      inner-end (1- (point))
                      found-end t))
               ((looking-at "n")
                (LaTeX-find-matching-end))))
          (setq outer-end env-end
                inner-end env-end
                found-end t)))
      (list outer-beg outer-end inner-beg inner-end))))


;;; Toggles

(defun evil-tex--overlay-replace (over string)
  "Replace text in overlay OVER with STRING."
  (goto-char (overlay-start over))
  (insert string)
  (delete-region (point) (overlay-end over)))

(defun evil-tex-toggle-delim ()
  "Toggle surrounding delimiters between e.g. (foo) and \\left(foo\\right).
Also change e.g \\bigl(foo\bigr) to (foo), but this is one way."
  (interactive)
  (let* ((outer (evil-tex-a-delim)) (inner (evil-tex-inner-delim))
         (left-over (make-overlay (car outer) (car inner)))
         (right-over (make-overlay (cadr inner) (cadr outer))))
    (save-excursion
      (let ((left-str (buffer-substring-no-properties (overlay-start left-over) (overlay-end left-over)))
            (right-str (buffer-substring-no-properties (overlay-start right-over) (overlay-end right-over))))
        (goto-char (overlay-start left-over))
        (cl-destructuring-bind (l . r)
            (cond
             ((looking-at "\\\\\\(?:left\\|big\\|bigg\\|Big\\|Bigg\\)?l?" )
              (cons (replace-regexp-in-string
                     "\\\\\\(?:left\\|big\\|bigg\\|Big\\|Bigg\\)?l?" "" left-str)
                    (replace-regexp-in-string
                     "\\\\\\(?:right\\|big\\|bigg\\|Big\\|Bigg\\)?r?" "" right-str)))
             (t (cons (concat "\\left" left-str)
                      (concat "\\right" right-str))))
          (evil-tex--overlay-replace left-over  l)
          (evil-tex--overlay-replace right-over r)))
      (delete-overlay left-over) (delete-overlay right-over))))

(defun evil-tex-toggle-env ()
  "Toggle surrounding enviornments between e.g. \\begin{equation} and \\begin{equation*}."
  (interactive)
  (let* ((outer (evil-tex-an-env)) (inner (evil-tex-inner-env))
         (left-over (make-overlay (car outer) (car inner)))
         (right-over (make-overlay (cadr inner) (cadr outer))))
    (save-excursion
      (goto-char (overlay-start left-over))
      (skip-chars-forward "^}")
      (backward-char 1)
      (if (= ?* (char-after)) (delete-char 1) (progn (forward-char 1) (insert-char ?*)))
      (goto-char (overlay-start right-over))
      (skip-chars-forward "^}")
      (backward-char 1)
      (if (= ?* (char-after)) (delete-char 1) (progn (forward-char 1) (insert-char ?*))))
    (delete-overlay left-over) (delete-overlay right-over)))

(defun evil-tex-toggle-math ()
  "Toggle surrounding math between \\(foo\\) and \\=\\[foo\\]."
  (interactive)
  (let* ((outer (evil-tex-a-math)) (inner (evil-tex-inner-math))
         (left-over (make-overlay (car outer) (car inner)))
         (right-over (make-overlay (cadr inner) (cadr outer))))
    (save-excursion
      (goto-char (overlay-start left-over))
      (cond
       ((looking-at (regexp-quote "\\("))
        (evil-tex--overlay-replace left-over  "\\[")
        (evil-tex--overlay-replace right-over "\\]" ))
       ((looking-at (regexp-quote "\\["))
        (evil-tex--overlay-replace left-over  "\\(")
        (evil-tex--overlay-replace right-over "\\)" ))))
    (delete-overlay left-over) (delete-overlay right-over)))

(defun evil-tex-toggle-math-align ()
  "Toggle surrounding math between display and align*.

Respect the value of `evil-tex-include-newlines-in-envs'.

\\(foo\\), \\=\\[foo\\] -> \\begin{align*}foo\\end{align*}
\\begin{align*}foo\\end{align*} -> \\=\\[foo\\]"
  (interactive)
  (let* ((outer-math (ignore-errors (evil-tex-a-math)))
         (inner-math (when outer-math (evil-tex-inner-math)))
         (env (unless outer-math (evil-tex--select-env)))
         (left-ol-to-replace (if outer-math
                                 (make-overlay (nth 0 inner-math) (nth 0 outer-math))
                               (make-overlay (nth 0 env) (nth 2 env))))
         (right-ol-to-replace (if outer-math
                                  (make-overlay (nth 1 inner-math) (nth 1 outer-math))
                                (make-overlay (nth 1 env) (nth 3 env))))
         (replacement (if outer-math
                          (evil-tex-get-env-for-surrounding "align*")
                        '("\\[" . "\\]"))))
    ;; put the \begin on a line of its own
    (when (and outer-math
               (/= (char-before (overlay-start left-ol-to-replace)) ?\n))
      (setcar replacement (concat "\n" (car replacement))))
    (evil-tex--overlay-replace left-ol-to-replace (car replacement))
    (evil-tex--overlay-replace right-ol-to-replace (cdr replacement))
    (delete-overlay left-ol-to-replace) (delete-overlay right-ol-to-replace)))

(defun evil-tex-toggle-command ()
  "Toggle command between \\foo and \\foo*."
  (interactive)
  (save-excursion
    (goto-char (car (evil-tex-inner-command)))
    ;; now either inside {}[] or after the macro
    (backward-char 1)
    (when (or (= ?{ (char-after)) (= ?\[ (char-after)))
      (backward-char 1))
    (if (= ?* (char-after))
        (delete-char 1)
      (forward-char 1)
      (insert-char ?*))))

(defvar evil-tex-section-name-history nil
  "History used for changing section names with `evil-tex-toggle-section'.")

(defun evil-tex-toggle-section ()
  "Enter new name for surrounding section. Meta-n for original name."
  (interactive)                         ; Sadly can't use interactive for the
                                        ; new name, as we need orig-name first
  (cl-destructuring-bind
      (outer-beg _outer-end _inner-beg _inner-end section-type)
      (evil-tex--select-section)
    (save-excursion
      (goto-char outer-beg)
      (skip-chars-forward "^{")
      (when-let ((curly (evil-inner-curly))
                 (orig-name (buffer-substring-no-properties
                             (nth 0 curly) (nth 1 curly)))
                 (new-name
                  (minibuffer-with-setup-hook
                      (lambda () (add-hook 'pre-command-hook #'evil-ex-remove-default))
                    (read-string (concat (substring section-type 1) ": ")
                                 (propertize orig-name 'face 'shadow)
                                 'evil-tex-section-name-history
                                 orig-name t))))
        (goto-char (nth 0 curly))
        (delete-region (nth 0 curly) (nth 1 curly))
        (insert new-name)))))


;;; Some movement commands

(declare-function org-previous-visible-heading "org")
(declare-function org-next-visible-heading "org")
(declare-function evil-org-inner-object "evil-org")

(defun evil-tex-go-back-section (&optional arg)
  "Go back to the closest part/section/subsection etc.

If given, go ARG sections up."
  (interactive)
  (cond
   ((derived-mode-p 'org-mode) (org-previous-visible-heading (or arg 1)))
   (t (re-search-backward evil-tex--section-regexp nil t arg))))

(defun evil-tex-go-forward-section (&optional arg)
  "Go forward to the closest part/section/subsection etc.

If given, go ARG sections down."
  (interactive)
  (cond
   ((derived-mode-p 'org-mode) (org-next-visible-heading (or arg 1)))
   (t
    ;; skip current looked-at section
    (when (looking-at evil-tex--section-regexp)
      (goto-char (match-end 0)))
    (when (re-search-forward evil-tex--section-regexp nil arg)
      (goto-char (match-beginning 0))))))

(defun evil-tex-brace-movement ()
  "Brace movement similar to TAB in cdlatex.

Example: (| symbolizes point)
\bar{h|} => \bar{h}|
\frac{a|}{} => \frac{a}{|}
\frac{a|}{b} => \frac{a}{b|}
\frac{a}{b|} => \frac{a}{b}|"
  (interactive)
  ;; go to the closing } of the current scope
  (search-backward "{" (line-beginning-position))
  (forward-sexp)
  ;; encountered a {? go to just before its terminating }
  (when (looking-at "{")
    (forward-sexp)
    (backward-char)))


;;; Text object definitions
;; some of which stolen from  https://github.com/hpdeifel/evil-latex-textobjects

(evil-define-text-object evil-tex-a-math (count &optional beg end type)
  "Select a \\=\\[foo\\], \\(bar\\), or $baz$."
  :extend-selection nil
  (nbutlast (evil-tex--select-math beg end type count) 2))

(evil-define-text-object evil-tex-inner-math (count &optional beg end type)
  "Select inner \\=\\[foo\\], \\(bar\\), or $baz$."
  :extend-selection nil
  (last (evil-tex--select-math beg end type count) 2))

(evil-define-text-object evil-tex-a-delim (count &optional beg end type)
  "Select a delimiter, e.g. (foo), \\left[bar\\right] or \\bigl\\=\\{baz\\bigr\\}."
  :extend-selection nil
  (nbutlast (evil-tex--select-delim beg end type count) 2))

(evil-define-text-object evil-tex-inner-delim (count &optional beg end type)
  "Select inner delimiter, e.g. (foo), \\left[bar\\right] or \\bigl\\=\\{baz\\bigr\\}."
  :extend-selection nil
  (last (evil-tex--select-delim beg end type count) 2))

(evil-define-text-object evil-tex-a-command (count &optional beg end type)
  "Select a LaTeX command (macro)."
  (nbutlast (evil-tex--select-command) 2))

(evil-define-text-object evil-tex-inner-command (count &optional beg end type)
  "Select inner LaTeX command (macro)."
  (last (evil-tex--select-command) 2))

(defvar evil-tex-env-fallback-evil-org t
  "When non-nil, fallback to `evil-org-an-object' and `evil-org-inner-object'
when `org-mode' and `evil-org-mode' are enabled.")

(evil-define-text-object evil-tex-an-env (count &optional beg end type)
  "Select a LaTeX environment."
  (condition-case err (nbutlast (evil-tex--select-env) 2)
    (error (cond
            ;; Fallback to evil-org binding in org-mode
            ((and evil-tex-env-fallback-evil-org
                  (derived-mode-p 'org-mode)
                  (fboundp 'evil-org-an-object))
             (evil-org-an-object count beg end type))
            ;; Rethrow error otherwise
            (t (signal (car err) (cdr (err))))))))

(evil-define-text-object evil-tex-inner-env (count &optional beg end type)
  "Select inner LaTeX environment."
  (condition-case err (last (evil-tex--select-env) 2)
    (error (cond
            ;; Fallback to evil-org binding in org-mode
            ((and evil-tex-env-fallback-evil-org
                  (derived-mode-p 'org-mode)
                  (fboundp 'evil-org-an-object))
             (evil-org-inner-object count beg end type))
            ;; Rethrow error otherwise
            (t (signal (car err) (cdr err)))))))

(evil-define-text-object evil-tex-a-section (count &optional beg end type)
  "Select a LaTeX section."
  ;; evil-tex--select-section returns section type too
  (nbutlast (evil-tex--select-section) 3))

(evil-define-text-object evil-tex-inner-section (count &optional beg end type)
  "Select inner LaTeX section."
  ;; evil-tex--select-section returns section type too
  (last (nbutlast (evil-tex--select-section)) 2))

(evil-define-text-object evil-tex-a-subscript (count &optional beg end type)
  "Select a LaTeX subscript."
  (nbutlast (evil-tex--select-script "_") 2))

(evil-define-text-object evil-tex-inner-subscript (count &optional beg end type)
  "Select inner LaTeX subscript."
  :extend-selection nil
  (last (evil-tex--select-script "_") 2))

(evil-define-text-object evil-tex-a-superscript (count &optional beg end type)
  "Select a LaTeX superscript."
  (nbutlast (evil-tex--select-script "^") 2))

(evil-define-text-object evil-tex-inner-superscript (count &optional beg end type)
  "Select inner LaTeX superscript."
  :extend-selection nil
  (last (evil-tex--select-script "^") 2))

(evil-define-text-object evil-tex-a-table-cell (count &optional beg end type)
  "Select a LaTeX table cell."
  (nbutlast (evil-tex--select-table-cell) 2))

(evil-define-text-object evil-tex-inner-table-cell (count &optional beg end type)
  "Select inner LaTeX table cell."
  (last (evil-tex--select-table-cell) 2))


;;; evil-surround setup

(defun evil-tex--populate-surround-keymap (keymap generator-alist prefix
                                                  single-strings-fn &optional cons-fn)
  "Populate KEYMAP with keys and callbacks from GENERATOR-ALIST.

See `evil-tex-env-map-generator-alist' the the alist fromat.
PREFIX is the prefix to give the generated functions created
by (lambda () (interactive) (SINGLE-STRINGS-FN env)) if the input is a string,
and by (lambda () (interactive) (CONS-FN env)) if it's a cons
Return KEYMAP."
  (dolist (pair generator-alist)
    (let ((key (car pair))
          (env (cdr pair))
          name)
      (cond
       ((stringp env)
        (setq name (intern (concat prefix env)))
        (fset name (lambda () (interactive) (funcall single-strings-fn env)))
        (define-key keymap key name))
       ((consp env)
        (setq name (intern (concat prefix (car env))))
        (if cons-fn
            (fset name (lambda () (interactive) (funcall cons-fn env)))
          (fset name (lambda () (interactive) env)))
        (define-key keymap key name))
       ((or (functionp env) (not env))
        (define-key keymap key env)))))
  keymap)

(defun evil-tex-read-with-keymap (keymap)
  "Prompt the user to press a key from KEYMAP.

Return the result of the called function, or error if the key
pressed isn't found."
  (let (key map-result)
    (when (require 'which-key nil t)
      (run-with-idle-timer
       which-key-idle-delay nil
       (lambda () (unless key
                    (which-key--show-keymap nil keymap nil nil t)))))
    (setq key (string (read-char)))
    (when (functionp #'which-key--hide-popup)
      (which-key--hide-popup))
    (setq map-result (lookup-key keymap key))
    (cond
     ((or (not map-result) (numberp map-result))
      (user-error "%s not found in keymap" key))
     ((functionp map-result)
      (call-interactively map-result))
     ((keymapp map-result)
      (evil-tex-read-with-keymap map-result)))))

;; working code courtesy of @hlissner
(defmacro evil-tex-dispatch-single-key (catch-key callback &optional fallbacks)
  "Define an evil command to execute CALLBACK when given CATCH-KEY.

Otherwise try to call any of the functions in FALLBACKS (a symbol),
until any of them succeeds (returns non-nil.)"
  `(evil-define-command
     ,(intern (concat "evil-tex-dispath-" (string catch-key))) (count key)
     (interactive "<c><C>")
     (if (= key ,catch-key)
         (funcall ,callback)
       (run-hook-with-args-until-success ,fallbacks
                                         count key))))

(defun evil-tex-get-env-for-surrounding (env-name)
  "Format strings the env named ENV-NAME for surrounding.

Return a cons of (\"\\begin{ENV-NAME}\" . \"\\end{ENV-NAME}\").

Respect the value of `evil-tex-include-newlines-in-envs'."
  (interactive (list (read-from-minibuffer "env: " nil
                                           minibuffer-local-ns-map)))
  (cons (format "\\begin{%s}%s"
                env-name
                (if evil-tex-include-newlines-in-envs "\n" ""))
        (format "%s\\end{%s}"
                (if evil-tex-include-newlines-in-envs "\n" "")
                env-name)))

(defun evil-tex-format-env-cons-for-surrounding (env-cons)
  "Format ENV-CONS for surrounding.

Add newlines if `evil-tex-include-newlines-in-envs' is t"
  (declare (side-effect-free t))
  (if evil-tex-include-newlines-in-envs
      (cons (concat (car env-cons) "\n")  (concat "\n" (cdr env-cons)))
    env-cons))

(defun evil-tex-format-cdlatex-accent-for-surrounding (accent)
  "Format ACCENT for surrounding: return a cons of ( \\ACCENT{ . } )."
  (declare (pure t) (side-effect-free t))
  (cons (concat "\\" accent "{") "}"))

(defun evil-tex-format-command-for-surrounding (command)
  "Format COMMAND for surrounding: return a cons of (\\COMMAND{ . } )."
  (declare (side-effect-free t))
  (if evil-tex--last-command-empty
      (cons (concat "\\" command "") "")
    (cons (concat "\\" command "{") "}")))

(defvar evil-tex--env-function-prefix "evil-tex-envs---"
  "Prefix used when generating env functions from `evil-tex-env-map-generator-alist'.")

(defvar evil-tex--cdlatex-accents-function-prefix "evil-tex-cdlatex-accents---"
  "Prefix used when generating accent functions from `evil-tex-cdlatex-accent-map-generator-alist'.")

(defvar evil-tex--delim-function-prefix "evil-tex-delims---"
  "Prefix used when generating delimiter functions from `evil-tex-delim-map-generator-alist'.")


(defmacro evil-tex--texmathp-dispatch (math-format regular-format)
  "Return cons for wrapping text in.

If inside math, wrap with the marco constructed by MATH-FORMAT (string).
Otherwise, with the macro constructed by REGULAR-FORMAT."
  `(if (texmathp)
       '(,(format "\\%s{" math-format) . "}")
     '(,(format "\\%s{" regular-format) . "}")))

(defun evil-tex-cdlatex-accents---rm ()
  "Return the (start . end) that would make text rm style if wrapped between start and end."
  (interactive) (evil-tex--texmathp-dispatch "mathrm" "textrm"))
(defun evil-tex-cdlatex-accents---it ()
  "Return the (start . end) that would make text it style if wrapped between start and end."
  (interactive) (evil-tex--texmathp-dispatch "mathit" "textit"))
(defun evil-tex-cdlatex-accents---sl ()
  "Return the (start . end) that would make text sl style if wrapped between start and end."
  (interactive)
  (unless (texmathp) '("\\textsl{" . "}")))
(defun evil-tex-cdlatex-accents---bold ()
  "Return the (start . end) that would make text bold style if wrapped between start and end."
  (interactive) (evil-tex--texmathp-dispatch "mathbf" "textbf"))
(defun evil-tex-cdlatex-accents---emph ()
  "Return the (start . end) that would make text emph style if wrapped between start and end."
  (interactive) (evil-tex--texmathp-dispatch "mathem" "emph"))
(defun evil-tex-cdlatex-accents---tt ()
  "Return the (start . end) that would make text tt style if wrapped between start and end."
  (interactive) (evil-tex--texmathp-dispatch "mathtt" "texttt"))
(defun evil-tex-cdlatex-accents---sf ()
  "Return the (start . end) that would make text sf style if wrapped between start and end."
  (interactive) (evil-tex--texmathp-dispatch "mathsf" "textsf"))

(defvar evil-tex-inner-text-objects-map (make-sparse-keymap)
  "Inner text object keymap for `evil-tex'.")

(defvar evil-tex-outer-text-objects-map (make-sparse-keymap)
  "Outer text object keymap for `evil-tex'.")

(defvar evil-tex-mode-map
  (let ((keymap (make-sparse-keymap)))
    (evil-define-key* '(motion normal) keymap
      "[[" #'evil-tex-go-back-section
      "]]" #'evil-tex-go-forward-section)
    (define-key keymap (kbd "M-n") #'evil-tex-brace-movement)
    (evil-define-key '(visual operator) 'evil-tex-mode
      "i" evil-tex-inner-text-objects-map
      "a" evil-tex-outer-text-objects-map)
    keymap)
  "Basic keymap for `evil-tex'.")

(cl-destructuring-bind (inner-map . outer-map)
    (if (and (boundp  'evil-surround-local-inner-text-object-map-list)
             (boundp  'evil-surround-local-outer-text-object-map-list))
        ;; deifine everything on local keymaps if evil-surround is up-to-date
        ;; i.e before https://github.com/emacs-evil/evil-surround/pull/165
        (cons evil-tex-inner-text-objects-map evil-tex-outer-text-objects-map)
      ;; pollute the global namespace if evil-surround is too old
      (cons evil-inner-text-objects-map evil-outer-text-objects-map))

  (define-key inner-map "e" 'evil-tex-inner-env)
  (define-key inner-map "c" 'evil-tex-inner-command)
  (define-key inner-map "m" 'evil-tex-inner-math)
  (define-key inner-map "d" 'evil-tex-inner-delim)
  (define-key inner-map "S" 'evil-tex-inner-section)
  (define-key inner-map "^" 'evil-tex-inner-superscript)
  (define-key inner-map "_" 'evil-tex-inner-subscript)
  (define-key inner-map "T" 'evil-tex-inner-table-cell)

  (define-key outer-map "e" 'evil-tex-an-env)
  (define-key outer-map "c" 'evil-tex-a-command)
  (define-key outer-map "m" 'evil-tex-a-math)
  (define-key outer-map "d" 'evil-tex-a-delim)
  (define-key outer-map "S" 'evil-tex-a-section)
  (define-key outer-map "^" 'evil-tex-a-superscript)
  (define-key outer-map "_" 'evil-tex-a-subscript)
  (define-key outer-map "T" 'evil-tex-a-table-cell))


(defvar evil-tex-env-map (make-sparse-keymap)
    "Keymap for surrounding with environments.
Used in `evil-tex-surround-env-prompt'.")

(defun evil-tex-bind-to-env-map (key-generator-alist &optional keymap)
  "Bind envs from KEY-GENERATOR-ALIST.

Bind to `evil-tex-env-map', or to KEYMAP if given.

See the definition of `evil-tex-env-map' for an example of what
it should look like.

Each item is in KEY-GENERATOR-ALIST a cons. The car is the key (a
string) to the keymap. The cdr should be any of:

- A string: then the inserted env would be an env with that name

- A cons of strigs: then the text would be wrapped between the
car and the cdr. For example, you can make a cons of
\(\"\\begin{figure}[!ht]\" . \"\\end{figure}\")
to have default placements for the figure.
Note that these definitions will respect `evil-tex-include-newlines-in-envs', so
there is no need to manually include newlines in provided strings.

- A function: then the function would be called, and the result
is assumed to be a cons. The text is wrapped in the resulted
cons. `evil-tex-include-newlines-in-envs' has no effect in this case."
  (evil-tex--populate-surround-keymap
   (or keymap evil-tex-env-map)
   key-generator-alist
   evil-tex--env-function-prefix
   #'evil-tex-get-env-for-surrounding
   #'evil-tex-format-env-cons-for-surrounding))

(setq evil-tex-env-map
  (let ((keymap (make-sparse-keymap)))
    (evil-tex-bind-to-env-map
     '(("x" . evil-tex-get-env-for-surrounding)
       ("e" . "equation")
       ("E" . "equation*")
       ("f" . "figure")
       ("i" . "itemize")
       ("I" . "enumerate")
       ("b" . "frame")
       ("a" . "align")
       ("A" . "align*")
       ("y" . "array")
       ("n" . "alignat")
       ("N" . "alignat*")
       ("r" . "eqnarray")
       ("l" . "flalign")
       ("L" . "flalign*")
       ("g" . "gather")
       ("G" . "gather*")
       ("m" . "multline")
       ("M" . "multline*")
       ("c" . "cases")
       ("z" . "tikzpicture")
       ;; prefix t - theorems
       ("ta" . "axiom")
       ("tc" . "corollary")
       ("tC" . "claim")
       ("td" . "definition")
       ("te" . "examples")
       ("ts" . "exercise")
       ("tl" . "lemma")
       ("tp" . "proof")
       ("tq" . "question")
       ("tr" . "remark")
       ("tt" . "theorem"))
     keymap)
    keymap))

(defvar evil-tex-cdlatex-accents-map (make-sparse-keymap)
  "Keymap for surrounding with environments, usually through `evil-tex-surround-cdlatex-accents-prompt'.")

(defun evil-tex-bind-to-cdlatex-accents-map (key-generator-alist &optional keymap)
  "Bind accent macros from KEY-GENERATOR-ALIST.

Bind to `evil-tex-cdlatex-accents-map', or to KEYMAP if given.

Format is identical to `evil-tex-bind-to-env-map', see that for explaination."
  (evil-tex--populate-surround-keymap
   (or keymap evil-tex-cdlatex-accents-map)
   key-generator-alist
   evil-tex--cdlatex-accents-function-prefix
   #'evil-tex-format-cdlatex-accent-for-surrounding))

(setq evil-tex-cdlatex-accents-map
  (let ((keymap (make-sparse-keymap)))
    (evil-tex-bind-to-cdlatex-accents-map
     '(("." . "dot")
       (":" . "ddot")
       ("~" . "tilde")
       ("N" . "widetilde")
       ("^" . "hat")
       ("H" . "widehat")
       ("-" . "bar")
       ("T" . "overline")
       ("_" . "underline")
       ("{" . "overbrace")
       ("}" . "underbrace")
       (">" . "vec")
       ("/" . "grave")
       ("\"". "acute")
       ("v" . "check")
       ("u" . "breve")
       ("m" . "mbox")
       ("c" . "mathcal")
       ("r" . evil-tex-cdlatex-accents---rm)
       ("i" . evil-tex-cdlatex-accents---it)
       ("l" . evil-tex-cdlatex-accents---sl)
       ("b" . evil-tex-cdlatex-accents---bold)
       ("e" . evil-tex-cdlatex-accents---emph)
       ("y" . evil-tex-cdlatex-accents---tt)
       ("f" . evil-tex-cdlatex-accents---sf)
       ("0"   "{\\textstyle " . "}")
       ("1"   "{\\displaystyle " . "}")
       ("2"   "{\\scriptstyle " . "}")
       ("3"   "{\\scriptscriptstyle " . "}"))
     keymap)
    keymap))

(defun evil-tex-bind-to-delim-map (key-generator-alist &optional keymap)
  "Bind delimiters from KEY-GENERATOR-ALIST.

Bind to `evil-tex-delim-map', or to KEYMAP if given.

Format is identical to `evil-tex-bind-to-env-map', see that for
explaination."
  (evil-tex--populate-surround-keymap
   (or keymap evil-tex-cdlatex-accents-map)
   key-generator-alist
   evil-tex--delim-function-prefix
   #'identity))

(defvar evil-tex-delim-map
  (let ((keymap (make-sparse-keymap)))
    (evil-tex-bind-to-delim-map
     '(("P"  "(" . ")")
       ("p"  "\\left(" . "\\right)")
       ("S"  "[" . "]")
       ("s"  "\\left[" . "\\right]")
       ("C"  "\\{" . "\\}")
       ("c"  "\\left\\{" . "\\right\\}")
       ("R"  "\\langle " . "\\rangle")
       ("r"  "\\left\\langle " . "\\right\\rangle"))
     keymap)
    keymap)
  "Keymap for surrounding with environments, usually through `evil-tex-delim-map'.")

(defun evil-tex-surround-env-prompt ()
  "Prompt user for an env to surround with using `evil-tex-env-map'."
  (evil-tex-read-with-keymap evil-tex-env-map))

(defun evil-tex-surround-cdlatex-accents-prompt ()
  "Prompt user for an accent to surround with using `evil-tex-cdlatex-accents-map'."
  (evil-tex-read-with-keymap evil-tex-cdlatex-accents-map))

(defun evil-tex-surround-delim-prompt ()
  "Prompt user for an delimiter to surround with using `evil-tex-delim-map'."
  (evil-tex-read-with-keymap evil-tex-delim-map))

(defun evil-tex-surround-command-prompt ()
  "Ask the user for the command they'd like to surround with."
  (evil-tex-format-command-for-surrounding
   (read-from-minibuffer "command: \\" nil minibuffer-local-ns-map)))


;;; Text object keybindings and surround declirations.

;; Shorten which-key descriptions in auto-generated keymaps
(when (require 'which-key nil t)
  (push
   '(("\\`." . "evil-tex-.*---\\(.*\\)") . (nil . "\\1"))
   which-key-replacement-alist))


(defvar evil-tex-surround-delimiters
  `((?m "\\(" . "\\)")
    (?M "\\[" . "\\]")
    (?c . ,#'evil-tex-surround-command-prompt)
    (?e . ,#'evil-tex-surround-env-prompt)
    (?d . ,#'evil-tex-surround-delim-prompt)
    (?\; . ,#'evil-tex-surround-cdlatex-accents-prompt)
    (?^ "^{" . "}")
    (?_ "_{" . "}")
    (?T "&" . "&"))
  "Delimiter pairs for `evil-surround'.")

(defun evil-tex-set-up-surround ()
  "Configure evil-surround so things like 'csm' work."
  (setq-local evil-surround-pairs-alist
              (append evil-tex-surround-delimiters evil-surround-pairs-alist))
  ;; making use of https://github.com/emacs-evil/evil-surround/pull/165
  (when (and (boundp 'evil-surround-local-inner-text-object-map-list)
             (boundp 'evil-surround-local-outer-text-object-map-list))
    (add-to-list 'evil-surround-local-inner-text-object-map-list
                 evil-tex-inner-text-objects-map)
    (add-to-list 'evil-surround-local-outer-text-object-map-list
                 evil-tex-outer-text-objects-map)))

(defun evil-tex-set-up-embrace ()
  "Configure evil-embrace not to steal our evil-surround keybinds."
  (setq-local evil-embrace-evil-surround-keys
              (append
               ;; embrace only needs the key chars, not the whole delimiters
               (mapcar #'car evil-tex-surround-delimiters)
               evil-embrace-evil-surround-keys)))


;;; Set up text object toggling.

(defcustom evil-tex-toggle-override-t nil
  "Set to t to bind evil-tex toggles to 'ts' keybindings.

Override normal 't' functionality for 's' only, so 'st' now
executes toggles from `evil-tex-toggle-map'.

Set this before loading evil-tex!"
  :type 'boolean
  :group 'evil-tex)

(defcustom evil-tex-toggle-override-m t
  "Set to t to bind evil-tex toggles to 'mt*' keybindings.

Override normal `m' functionality for 't' only, so 'mt' now
executes toggles from `evil-tex-toggle-map'.

Set this before loading evil-tex!"
  :type 'boolean
  :group 'evil-tex)

(defvar evil-tex-t-functions
  (list (defun evil-tex-try-evil-snipe (count key)
          (when (bound-and-true-p evil-snipe-mode)
            (setq evil-snipe--last-direction t)
            (evil-snipe-t count (list key))
            t)
          #'evil-find-char-to))
  "Functions that should run the evil normal-state 't' key by default.

The functions are called one by one, with arguments (count key),
until one of them returns non-nil.")

(defvar evil-tex-m-functions
  (list (lambda (_count key)
          (evil-set-marker key)
          t))
  "Functions that should run on the evil normal-state 'm' key by default.

The functions are called one by one, with arguments (count key),
until one of them returns non-nil.")

(defvar evil-tex-toggle-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap "d" #'evil-tex-toggle-delim)
    (define-key keymap "e" #'evil-tex-toggle-env)
    (define-key keymap "m" #'evil-tex-toggle-math)
    (define-key keymap "M" #'evil-tex-toggle-math-align)
    (define-key keymap "c" #'evil-tex-toggle-command)
    (define-key keymap "S" #'evil-tex-toggle-section)
    keymap)
  "Keymap for delimiter surrounding.")

(defun evil-tex-read-and-execute-toggle ()
  "Prompt user with `evil-tex-toggle-map' to toggle something."
  (evil-tex-read-with-keymap evil-tex-toggle-map))

(when evil-tex-toggle-override-t
  (evil-define-key 'normal evil-tex-mode-map "t"
    (evil-tex-dispatch-single-key ?s #'evil-tex-read-and-execute-toggle
                                  'evil-tex-t-functions)))

(when evil-tex-toggle-override-m
  (evil-define-key 'normal evil-tex-mode-map "m"
    (evil-tex-dispatch-single-key ?t #'evil-tex-read-and-execute-toggle
                                  'evil-tex-m-functions)))

;;;###autoload
(define-minor-mode evil-tex-mode
  "evil toolbox for LaTeX editing. Provides many text objects
fully utilizing evil-surround, some useful movements, and keymaps
for quickly entering environments or cdlatex-like accents. And
useful toggles.

See URL `https://github.com/iyefrat/evil-tex' for the full feature
list."
  :init-value nil
  :keymap evil-tex-mode-map
  (when evil-tex-mode
    (evil-normalize-keymaps)
    (when (require 'evil-surround nil t)
      (evil-tex-set-up-surround))
    (when (require 'evil-embrace nil t)
      (evil-tex-set-up-embrace))))

(provide 'evil-tex)
;;; evil-tex.el ends here
