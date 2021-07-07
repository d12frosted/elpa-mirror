;;; texfrag.el --- preview LaTeX fragments in alien major modes  -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2018 Tobias Zawada

;; Author: Tobias Zawada <i@tn-home.de>
;; Keywords: tex, languages, wp
;; Package-Commit: a5f59e0c5f43578f139a2943bd08e5b3140f4c2b
;; Package-Version: 20200716.1331
;; Package-X-Original-Version: 1.0.1
;; URL: https://github.com/TobiasZawada/texfrag
;; Package-Requires: ((emacs "25") (auctex "11.90.2"))

;; This program is free software; you can redistribute it and/or modify
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

;; Enable AUCTeX-preview in non-LaTeX modes.
;; Strategy:
;; - collect all header contents and latex fragments from the source buffer
;; - prepare a LaTeX document from this information
;; - let preview do its stuff in the LaTeX document
;; - move the preview overlays from the LaTeX document to the source buffer
;;
;; Install texfrag via Melpa by M-x package-install texfrag.
;;
;; If texfrag is activated for some buffer the image overlays for LaTeX fragments
;; such as equations known from AUCTeX preview can be generated
;; with the commands from the TeX menu (e.g. "Generate previews for document").
;;
;; The major mode of the source buffer should have a
;; texfrag setup function registered in `texfrag-setup-alist'.
;; Thereby, it is sufficient if the major mode is derived
;; from one already registered in `texfrag-setup-alist'.
;;
;; The default prefix-key sequence for texfrag-mode is the same as for preview-mode, i.e., C-c C-p.
;; You can change the default prefix-key sequence by customizing `texfrag-prefix'.
;; If you want to modify the prefix key sequence just for one major mode use
;; `texfrag-set-prefix' in the major mode hook before you run texfrag-mode.
;;
;; You can adapt the LaTeX-header to your needs by buffer-locally setting
;; the variable `texfrag-header-function' to a function without arguments
;; that returns the LaTeX header as a string.  Inspect the definition of
;; `texfrag-header-default' as an example.
;;
;; There are three ways to add TeXfrag support for your new major mode.
;;
;;  1. Derive your major mode from one of the already supported major modes
;;     (see doc of variable `texfrag-setup-alist').
;;     You do not need to do anything beyond that if your major mode does not
;;     change the marks for LaTeX equations (e.g., "\f$...\f$" for LaTeX equations
;;     in doxygen comments for `prog-mode').
;;
;;  2. Add a setup function to `texfrag-setup-alist' (see the doc for that variable).
;;     The minor mode function `texfrag-mode' calls that setup function
;;     if it detects that your major mode out of all major modes
;;     registered in `texfrag-setup-alist' has the closest relationship
;;     to the major mode of the current buffer.
;;     The setup function should adapt the values of the buffer local special variables
;;     of texfrag to the needs of the major mode.
;;     In many cases it is sufficient to set `texfrag-comments-only' to nil
;;     and `texfrag-frag-alist' to the equation syntax appropriate for the major mode.
;;
;;  3. Sometimes it is necessary to call `texfrag-mode' without corresponding
;;     setup function.  For an instance editing annotations with `pdf-annot-edit-contents-mouse'
;;     gives you a buffer in `text-mode' and the minor mode `pdf-annot-edit-contents-minor-mode'
;;     determines the equation syntax.
;;     One should propably not setup such general major modes like `text-mode' for texfrag.  Thus, it is
;;     better to call `TeXfrag-mode' in the hook of `pdf-annot-edit-contents-minor-mode'.
;;     Note, that the initial contents is not yet inserted when `pdf-annot-edit-contents-minor-mode' becomes active.
;;     Therefore, one needs to call `texfrag-region' in an advice of `pdf-annot-edit-contents-noselect'
;;     to render formulas in the initial contents.
;;     Further note, that there is already a working version for equation preview in pdf-tools annotations.
;;     Pityingly, that version is not ready for public release.
;;
;; The easiest way to adapt the LaTeX fragment syntax of some major mode
;; is to set `texfrag-frag-alist' in the mode hook of that major mode.
;; For `org-mode' the function `texfrag-org'
;; can be used as minimal implementation of such a hook function.
;; Note that this function only handles the most primitive
;; syntax for LaTeX fragments in org-mode buffers, i.e., $...$ and \[\].
;;
;; For more complicated cases you can install your own
;; parsers of LaTeX fragments in the variable
;; `texfrag-next-frag-function' (see the documentation of that variable).
;;

;;; Requirements:
;; - depends on Emacs "25" (because of when-let)
;; - requires AUCTeX with preview.el.

;;; Important changes
;; Here we list changes that may have an impact on the user configuration.
;;
;; 2018-03-05:
;; - `texfrag-header-function' is now called with `texfrag-source-buffer' as current buffer.
;; - adopted LaTeX header generation from `org-latex-make-preamble'
;;
;; 2019-05-04:
;; - `texfrag-region' for `texfrag-preview-buffer-at-start' has been moved to `post-command-hook'
;;   That is an important step to make `texfrag-preview-buffer-at-start' really work.
;;   (No repeated LaTeX processing on the same document within one command.)
;; - This version of texfrag is tagged 1.0.
;;
;; 2019-11-29:
;; - Let TeXfrag scale the images according to `text-scale-mode'.
;; - That is actually like a bugfix for `preview.el'.  In the original version of preview
;;   the function registered at `preview-scale-function' is run in the TeX process buffer and not in
;;   the associated LaTeX source buffer.  The newly registered function `texfrag-scale-from-face'
;;   switches to `TeX-command-buffer' (which is actually the source buffer) before it
;;   calculates the scaling factor.  In that way the settings in the source buffer are taken into account.
;;   Added the scaling factor `texfrag-scale'.  You can use that factor to scale all preview images up.
;;
;;; Code:

(defgroup texfrag nil "Preview LaTeX fragments in buffers with non-LaTeX major modes."
  :group 'preview)

(defcustom texfrag-preview-buffer-at-start nil
  "Preview buffer at start of command `texfrag-mode' when non-nil."
  :group 'texfrag
  :type 'boolean)

(defcustom texfrag-setup-alist
  '((texfrag-html html-mode)
    (texfrag-eww eww-mode)
    (texfrag-sx sx-question-mode)
    (texfrag-prog prog-mode)
    (texfrag-trac-wiki trac-wiki-mode)
    (texfrag-markdown markdown-mode)
    (texfrag-org org-mode))
  "Alist that maps texfrag setup functions to lists of major modes.
Each element is a `cons'.
The `car' of the cons is the symbol of the texfrag setup function
and the `cdr' of the cons is the list of major modes supported by that
setup function."
  :group 'texfrag
  :type '(repeat (cons :tag "Pair of texfrag setup function and list of corresponding major modes"
		       (symbol :tag "Symbol of texfrag setup function")
		       (repeat :tag "Major modes" (symbol)))))

(defcustom texfrag-header-default
  "\\documentclass{article}
\\usepackage{amsmath,amsfonts}
\\usepackage[utf8]{inputenc}
\\usepackage[T1]{fontenc}"
  "LaTeX header inserted by the function `texfrag-header-default' into the LaTeX buffer."
  :group 'texfrag
  :type 'string)

(defcustom texfrag-subdir "texfrag"
  "Name of the sub-directory for the preview data."
  :group 'texfrag
  :type 'string)

(defcustom texfrag-prefix (kbd "C-c C-p")
  "Prefix for texfrag keys.
Defaults to the prefix of preview-mode.
If there is a collision with the major mode you can change this prefix in the major mode's hook function."
  :type 'key-sequence
  :group 'texfrag)

(defcustom texfrag-LaTeX-max-file-name-length 72
  "Maximal length of LaTeX file names."
  :type 'integerp
  :group 'texfrag)

(defcustom texfrag-poll-time 0.25
  "Polling time for `texfrag-region-synchronously' in seconds."
  :type 'numberp
  :group 'texfrag)

(defcustom texfrag-eww-default-file-name '(make-temp-file "texfrag-eww" nil ".tex")
  "LaTeX file name for TeX fragments in eww if the url is not a file:// url.
This can be a file name or a sexp that generates the file name."
  :group 'texfrag
  :type '(choice file sexp))

(defcustom texfrag-pdf-annot-LaTeX-file '(make-temp-file "texfrag-pdf" nil ".tex")
  "LaTeX file name for TeX fragments in pdf-annotations.
This can be a file name or a sexp that generates the file name."
  :group 'texfrag
  :type '(choice file sexp))

(defconst texfrag-frag-alist-type
  '(repeat
    (list :tag "Equation filter"
	  (regexp :tag "Regexp matching the fragment beginning")
	  (texfrag-regexp :tag "Regexp matching the fragment end")
	  (string :tag "Replacement of beginning in LaTeX buffer")
	  (string :tag "Replacement of end in LaTeX buffer")
	  (set :tag "Fragment type" :inline t
	       (list :tag "Show as display equation" :inline t (const :display) (const t))
	       (list :tag "Generator function" :inline t (const :generator) (function identity)))))
  "Customization type for `texfrag-frag-alist'.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar texfrag-inhibit nil
  "Inhibit call of function `texfrag-mode' through `texfrag-global-mode-fun'.")

(define-widget 'texfrag-regexp 'string
  "A regular expression."
  :match 'texfrag-widget-regexp-match
  :validate 'texfrag-widget-regexp-validate
  ;; Doesn't work well with terminating newline.
  ;; :value-face 'widget-single-line-field
  :tag "Regexp")

(defun texfrag-not-regexp-with-refs-p (val)
  "Check whether VAL is *not* a valid regular expression with group references.
Returns the error message of `string-match' if VAL is not a regular expression.
Group references are just ignored.
If VAL is a widget instead of a string (widget-value val) is tested."
  (when (widgetp val)
    (setq val (widget-value val)))
  (let ((pos 0))
    (while (string-match "\\(?:^\\|[^\\\\]\\)\\(?:\\\\\\\\\\)*\\(\\\\\\)[0-9]" val pos)
      (setq val (replace-match "\\\\\\\\" nil nil val 1)
            pos (match-end 0))))
  (condition-case err
      (string-match val "")
    (error (error-message-string err))))

(defun texfrag-widget-regexp-match (_widget value)
  "Return non-nil if VALUE is a valid regexps with additional group references."
  (and (stringp value)
       (null (texfrag-not-regexp-with-refs-p value))))

(defun texfrag-widget-regexp-validate (widget)
  "Return WIDGET with non-nil :error property if VALUE is not a valid regexps with additional group references."
  (let ((err (texfrag-not-regexp-with-refs-p widget)))
    (when err
      (widget-put widget :error err)
      widget)))

(defcustom texfrag-LaTeX-frag-alist
  '(("\\$\\$" "\\$\\$" "$$" "$$" :display t)
    ("\\$" "\\$" "$" "$")
    ("\\\\\\[" "\\\\\\]" "\\\\[" "\\\\]" :display t)
    ("\\\\(" "\\\\)" "\\\\(" "\\\\)")
    ("\\\\begin{\\([a-z*]+\\)}" "\\\\end{\\1}" "\\\\begin{\\2}" "\\\\end{\\2}" :display t)
    )
  "`texfrag-frag-alist' for LaTeX."
  :group 'texfrag
  :type texfrag-frag-alist-type)

(defcustom texfrag-org-class-options ""
  "LaTeX class options for texfrag in orgmode.
Defaults to the empty string.  Should include the enclosing brackets."
  :type 'string
  :group 'texfrag)

(defcustom texfrag-org-add-to-header ""
  "LaTeX commands added between `org-format-latex-header' and \\begin{document}."
  :type 'string
  :group 'texfrag)

(defcustom texfrag-scale 1.0
  "Additional scaling factor for preview images."
  :type 'float
  :group 'texfrag
  :safe #'numberp)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'tex-site nil t)
(require 'preview nil t)
(require 'cl-lib)
(require 'tex-site)
(require 'tex)
(require 'subr-x)
(require 'face-remap) ;;< `text-scale-mode'
(require 'seq)

(defvar-local texfrag-header-function #'texfrag-header-default
  "Function that collects all LaTeX header contents from the current buffer.")

(defvar-local texfrag-tail-function "\n\\end{document}\n%%Local Variables:\n%%TeX-master: t\n%%End:\n"
  "String with the LaTeX tail or Function that collects all preview-LaTeX tail contents from the current buffer.")

(defvar-local texfrag-next-frag-function #'texfrag-next-frag-default
  "Function that searches for the next LaTeX fragment starting at point.
It is called with:

\(funcall texfrag-next-frag-function BOUND)

It returns nil if there is no LaTeX fragment within the region.
Otherwise it returns a list
\(b e eqn match)
with
b: beginning of equation region
e: end of equation region
eqn: equation text inclusive delimiters, e.g.,
     $ or \\begin{align*}...\\end{align*}
     (it is not necessarily equal to (buffer-substring b e))
match: entry from `texfrag-frag-alist' associated with the match")

(defvar-local texfrag-previous-frag-function #'texfrag-previous-frag-default
  "Function that searches for the previous LaTeX fragment starting at point.
It is called with:

\(funcall \\[texfrag-next-frag-function] BOUND)

It returns nil if there is no LaTeX fragment within the region.
Otherwise it returns a list
\(b e eqn)
with
b: beginning of equation region
e: end of equation region
eqn: equation text inclusive delimiters,
     e.g., $ or \\begin{align*}...\\end{align*}
     (it is not necessarily equal to (buffer-substring b e))
match: entry from `texfrag-frag-alist' associated with the match")

(defvar-local texfrag-comments-only t
  "Only collect LaTeX fragments from comments.
Modify this variable in the major mode hook.")

(defvar-local texfrag-frag-alist
  '(("\\\\f\\$" "\\\\f\\$" "$" "$" embedded)
    ("\\\\f\\[" "\\\\f\\]" "\\\\[" "\\\\]" display)
    ("\\\\f{\\([a-z]+[*]?\\)}[{]?" "\\\\f}" "\\\\begin{\\2}" "\\\\end{\\2}" display) ;; e.g., \f{align*}{ some formula \f}
    )
  "Regular expressions for the beginning and the end of formulas.
Override the default in the hook for the major mode.
The default works for some LaTeX fragments in doxygen.

The value is a list of equation-filters.
Each equation-filter is a list of two matchers, two replacement strings, and further property-value pairs.
The first matcher can be a regular expression string matching the beginning of a formula
or a list with the regular expression string as its first element and a function
as its second element. The function returns non-nil if the match really starts a LaTeX fragment.
The second matcher can only be regular expression.

The regular expressions of the first two matchers match the beginning and the end of an equation in the original buffer.
The last two strings are the beginning and the end of the corresponding equation in the LaTeX buffer.
They have the format of the NEWTEXT argument of `replace-match'.
You need to escape the backslash character ?\\\\ and you can refer to groups as explained further below.

Capturing groups can be used in the first two regular expressions. These groups can be referred to in the last two replacement strings.
The indexes for the captures are determined as match for the combined regular expression
\\(beginning regexp\\)\\(end regexp\\).

Following properties are recognized:

:display (default: nil) if the :display property is non-nil fragments are wrapped
into newlines by `texfrag-fix-display-math'.

:generator (default: nil)
May be nil or a generator function to be called with the transformed match as argument.
The generator should return the image or a file name to the image to be displayed.
")

(defvar-local texfrag-equation-filter #'identity
  "Filter function transforming the equation text from the original buffer into the equation text in the LaTeX buffer.")

(defun texfrag-combine-regexps (re-template data &optional str)
  "Return a regular expression constructed from RE-TEMPLATE (a string).
Thereby use the previous `match-data' DATA with corresponding string STR
if this was a `string-match'.
Let N be the number of sub-expressions of the previous match then
\\n with n=0,...,N are replaced by the quoted matches from the previous match
and \\n with n=N+1,... are replaced by n-(N+1).

Example:
With str equal to \"foo bar\" and preceeding match
\(string-match \"f\\\\(o+\\\\)\" str)
the form
\(texfrag-combine-regexps \"\\\\(ba\\\\)zz.*\\\\1G\\\\2\" (match-data) str)
returns:
\"\\\\(ba\\\\)zz.*ooG\\\\1\""
  (let ((data-n (/ (length data) 2))
	new-pos
	(pos 0)
	(re ""))
    (while (setq new-pos (string-match "\\\\" re-template pos))
      (setq re (concat re (substring re-template pos new-pos))
	    pos (1+ new-pos))
      (cond
       ((eq pos (length re-template))
	(setq re (concat re "\\"))) ;; next match will fail
       ((eq (aref re-template pos) ?\\)
	(setq re (concat re "\\\\"))
	(cl-incf pos))
       ((eq (string-match "[0-9]+" re-template pos) pos)
	(let* ((num-str (match-string 0 re-template))
	       (num (string-to-number num-str)))
	  (setq re (concat re (if (< num data-n)
				  (regexp-quote (save-match-data
						  (set-match-data data)
						  (or (match-string num str) "")))
				(format "\\%d" (- num data-n -1))))
		pos (+ pos (length num-str)))
	  ))
       (t (setq re (concat re "\\")))))
    (setq re (concat re (substring re-template pos)))
    re))
;; Test:
;; (string-equal "\\(ba\\)zz.*ooG\\1" (let ((str "foo bar")) (string-match "f\\(o+\\)" str) (texfrag-combine-regexps "\\(ba\\)zz.*\\1G\\2" (match-data) str)))
;; 

(defun texfrag-combine-match-data (&rest args)
  "Combines the match data in ARGS of multiple `string-match' commands.
The combined data appears as if it originates from one `string-match' command.
Let str_1, str_2, ... be strings and re_1, re_2, ... regular expressions.
Set matches_k to the `match-data' of (`string-match' re_k str_k) for k=1,2,....
\(texfrag-combine-match-data str_1 matches_1 str_2 matches_2 ...)
returns the result of
\(string-match \"\\\\(re_1\\\\)\\\\(re_2\\\\)...\" \"str_1str_2...\")

\(fn str_1 re_1 str_2 re_2 ...)"
  (let (ret
	(offset 0))
    (while args
      (let* ((str (car args))
	     (match-data (cadr args))
	     (str-length (length str)))
	(setq ret (append ret
			  (mapcar (lambda (i) (+ i offset)) match-data))
	      offset (+ offset str-length)
	      args (cddr args))))
    (cons 0 (cons offset ret))))
;; Test:
;; (equal '(0 15 4 7 5 6 11 14 12 14) (let* ((str1 "foo bar") (data1 (progn (string-match "b\\(a\\)r" str1) (match-data))) (str2 "baz booz") (data2 (progn (string-match "b\\(o+\\)" str2) (match-data)))) (texfrag-combine-match-data str1 data1 str2 data2)))

(defun texfrag-regexp-begin (frag)
  "Extract the beginning regexp from FRAG.
FRAG is a LaTeX fragment entry in `texfrag-frag-alist'."
  (while (consp frag) ;; regular expression
    (setq frag (car frag)))
  frag)

(defun texfrag-next-frag-default (bound)
  "Search for the next LaTeX fragment in region from `point' to BOUND.
See the documentation of variable `texfrag-next-frag-function'
for further details about the argument and the return value."
  (let ((re-b (concat (mapconcat #'texfrag-regexp-begin
				 texfrag-frag-alist "\\|")))
	found)
    (while (and (null found)
		(re-search-forward re-b bound t))
      (let* ((bOuter (match-beginning 0))
             (bInner (point))
             (bStr (match-string 0))
             (matchList (cl-assoc bStr texfrag-frag-alist
				  :test
				  (lambda (key candidate)
				    (string-match
				     (texfrag-regexp-begin candidate)
				     key)))))
	(when (or (stringp (car matchList))
		  (funcall (cadar matchList)))
	  (setq found
		(let*
		    ((bMatches (match-data))
		     (e-re (texfrag-combine-regexps (nth 1 matchList) bMatches bStr))
		     (eOuter (re-search-forward e-re nil t))
		     (eInner (match-beginning 0))
		     (eStr (match-string 0)) ;; for consistency
		     (eMatches (progn (string-match e-re eStr) (match-data))) ;; for consistency
		     (cStr (concat bStr eStr)) ;; combined string
		     (cMatches (texfrag-combine-match-data bStr bMatches eStr eMatches))
		     )
		  (unless eOuter
		    (user-error "LaTeX fragment beginning at %s with %s in buffer %s not closed" bOuter bStr (current-buffer))) ;; Changed %d for bOuter to %s to handle case bOuter==nil.
		  (set-match-data cMatches)
		  (list bOuter eOuter
			(concat (replace-match (nth 2 matchList) nil nil cStr)
				(funcall texfrag-equation-filter (buffer-substring-no-properties bInner eInner))
				(replace-match (nth 3 matchList) nil nil cStr))
			matchList))))))
    found))

(defun texfrag-previous-frag-default (bound)
  "Search for the next LaTeX fragment in the region from `point' to BOUND.
See the documentation of `texfrag-previous-frag-function'
for further details about the argument and the return value."
  (let ((re-e (concat (mapconcat 'cadr texfrag-frag-alist "\\|"))))
    (when (re-search-backward re-e bound t)
      (let* ((eInner (match-beginning 0))
             (eOuter (match-end 0))
             (eStr (match-string 0))
             (matchList (cl-rassoc eStr texfrag-frag-alist :test (lambda (key candidate) (string-match (car candidate) key))))
	     (eMatches (match-data))
             (bOuter (re-search-backward (texfrag-regexp-begin matchList) nil t))
             (bInner (match-end 0))
	     (bStr (match-string 0))
	     (bMatches (progn (string-match (car matchList) bStr) (match-data)))
	     (cMatches (texfrag-combine-match-data bStr bMatches eStr eMatches))
	     (cStr (concat bStr eStr))
	     )
	(unless bOuter
	  (user-error "LaTeX fragment ending at %d with %s has no start string" bOuter eStr))
	(set-match-data cMatches)
        (list bOuter eOuter
              (concat (replace-match (nth 2 matchList) nil nil cStr)
                      (funcall texfrag-equation-filter (buffer-substring-no-properties bInner eInner))
                      (replace-match (nth 3 matchList) nil nil cStr))
	      matchList)))))

(defun texfrag-header-default ()
  "Just return the value of the variable `texfrag-header-default'."
  texfrag-header-default)

(defun texfrag-reduce-any (binop pred &rest args)
  "Reduce via BINOP all PRED satisfying ARGS.
Returns nil if none of the args are numbers."
  (let (ret)
    (mapc (lambda (x)
	    (when (funcall pred x)
	      (setq ret (or (and (funcall pred ret)
				 (funcall binop x ret))
			    x))))
	  args)
    ret))

(defun texfrag-comment-start-position ()
  "The position of the start of the current comment, or nil."
  ;; Partial copy from:
  ;; http://emacs.stackexchange.com/questions/21812/if-i-am-in-a-comment-including-empty-lines-how-do-i-get-to-the-beginning-of-t
  (save-excursion
    (let ((res nil))
      (while (progn
               (skip-chars-backward " \t\n")
               (let ((state (syntax-ppss)))
                 (if (nth 4 state)
                     (let ((start (nth 8 state)))
                       (setq res start)
                       (goto-char start)
                       t)
                   nil))))
      res)))

(defun texfrag-comment-end-position ()
  "The position of the end of the current comment, or nil."
  (save-excursion
    (let ((res nil))
      (while (progn
               (if (and
		    (> (skip-chars-forward " \t\n") 0)
		    (null (eobp)))
		   (forward-char))
               (let ((state (syntax-ppss)))
                 (if (nth 4 state)
		     (progn
		       (parse-partial-sexp (point) (point-max) nil nil state 'syntax-table)
		       (setq res (point))
		       (null (eobp)))
                   nil))))
      res)))

(defun texfrag-search-forward-fragment (&optional bound)
  "Search for the next LaTeX fragment in the region from `point' to BOUND.
list with the entries as in `texfrag-next-frag-function':
;(b e str)
b: beginning of LaTeX fragment
e: end of LaTeX fragment
str: LaTeX equation to be inserted in the target LaTeX file"
  (let (found
	e)
    (if texfrag-comments-only
        (while (and (or (null bound) (< (point) bound))
		    (or
		     (setq e (texfrag-comment-end-position)) ;; test whether we are already in a comment
		     (comment-search-forward bound t))
		    (null (setq found (funcall texfrag-next-frag-function (texfrag-reduce-any #'min #'numberp bound (or e (texfrag-comment-end-position)))))))
	  (comment-search-forward bound t))
      (setq found (funcall texfrag-next-frag-function bound)))
    (when found (goto-char (nth 1 found)))
    found))

(defun texfrag-search-backward-fragment (&optional bound)
  "Search backward for next LaTeX fragment in region from `point' to BOUND.
See `texfrag-search-forward-fragment' for further details."
  (let (found
	b)
    (if texfrag-comments-only
        (while (and (or
		     (setq b (texfrag-comment-start-position)) ;; test whether we are already in a comment
		     (comment-search-backward bound t))
		    (null (setq found (funcall texfrag-previous-frag-function (or b (texfrag-comment-start-position))))))
	  (comment-search-backward bound t))
      (setq found (funcall texfrag-previous-frag-function bound)))
    (when found (goto-char (car found)))
    found))

(defvar-local texfrag-LaTeX-file nil
  "Used instead of `buffer-file-name' for function `texfrag-LaTeX-file' when non-nil.
Can be modified in the major mode hook.")

(defun texfrag-file-name-option (opt)
  "Get file name from option OPT.
OPT can be a file name string or a Lisp form
that generates the file name string."
  (if (stringp opt)
      opt
    (eval opt)))

(defun texfrag-file-name-escape (name &optional re)
  "Replace chars in NAME that are not ASCII and do not match RE.
RE is a regular expression defaulting to \"[^]<>:\"/\\|?*+{}[]\".
Relevant characters are replaced by _hex-number."
  (unless re
    (setq re "[^]<>:\"/\\|?*+{}[]"))
  (mapconcat (lambda (char)
               (let ((str (char-to-string char)))
                 (if (and (/= char ?_)
                          (> char #x20)
                          (< char #x80)
                          (string-match re str))
                     str
                   (format "_%0.2X" char))))
               name ""))

(defun texfrag-LaTeX-dir (&optional mkdir)
  "Return directory where to write preview files.
Allow creation of temporary directory if MKDIR is non-nil."
  (if (or
       (and
	(file-name-absolute-p texfrag-subdir)
	(or
	 (when (file-exists-p texfrag-subdir)
	   (unless (file-writable-p texfrag-subdir)
	     (user-error "Existing directory texfrag-subdir cannot be written to"))
	   t)
	 (when-let ((dir (file-name-directory texfrag-subdir))) ;; should never fail for absolute directories
	   (file-writable-p dir))))
       (file-writable-p default-directory))
      (directory-file-name (expand-file-name texfrag-subdir))
    (unless mkdir
      (user-error "Default directory is write protected and texfrag-LaTeX-file is not allowed to create a temporary directory"))
    (make-temp-file (concat "texfrag-"
			    (substring (buffer-name)
				       nil
				       (min
					(- texfrag-LaTeX-max-file-name-length 20) ;; Leave space for the appended random characters.
					(length (buffer-name)))
				       )
			    "-")
		    t)))

(defun texfrag-LaTeX-file (&optional absolute mkdir prv-dir)
  "Return name of LaTeX file corresponding to the current buffers source file.
Return the absolute file name if ABSOLUTE is non-nil.
Create the directory of the LaTeX file (inclusive parent directories)
if it does not exist yet and MKDIR is non-nil.
Return the preview directory instead of the LaTeX file name if PRV-DIR is non-nil."
  (let* ((tex-path (or texfrag-LaTeX-file
		       (and (buffer-live-p texfrag-tex-buffer)
			    (buffer-file-name texfrag-tex-buffer))))
	 (tex-dir (or (and tex-path (file-name-directory tex-path))
		      (texfrag-LaTeX-dir mkdir)))
         (tex-file (and tex-path (file-name-nondirectory tex-path))))
    ;; File names generated from buffer names of org source edit buffers can be pretty long.
    ;; Pityingly I had to note that the TeX toolchain including gs
    ;; does not work properly with file names longer than 72 characters.
    ;; Version info:
    ;; - Ubuntu 16.04.3 LTS
    ;; - gs 9.18
    ;; - pdfTeX 3.14159265-2.6-1.40.16 (TeX Live 2015/Debian)
    ;; - kpathsea version 6.2.1
    ;; I do not know what exactly breaks with longer file names.
    ;; But, the next limitation avoids the error
    ;; LaTeX: No preview images found.
    ;; for org source edit buffers.
    (unless (and
	     tex-file
	     (null (string-empty-p tex-file)))
      (setq tex-file (texfrag-file-name-escape
		      (file-name-nondirectory
		       (or (buffer-file-name)
			   (buffer-name)))))
      (when (> (length tex-file) texfrag-LaTeX-max-file-name-length)
	(setq tex-file (substring tex-file 0 texfrag-LaTeX-max-file-name-length)))
      (let ((ext (file-name-extension tex-file)))
	(when (and ext (assoc-string ext TeX-file-extensions))
          (setq tex-file (concat tex-file "-"))))
      (setq tex-file (concat tex-file
			     (unless (and (stringp tex-file)
					  (string-suffix-p "." tex-file))
			       ".")
                             (if prv-dir
				 "prv"
                               TeX-default-extension))))
    (when (and mkdir (null (file-directory-p tex-dir)))
      (mkdir tex-dir t))
    (if absolute
	(expand-file-name tex-file tex-dir)
      tex-file)))

(defun texfrag-preview-dir (&optional buf absolute mkdir)
  "Return preview directory for the LaTeX file with texfrags for BUF.
ABSOLUTE and MKDIR have the same meaning as for function `texfrag-LaTeX-file'.
BUF defaults to `current-buffer'."
  (with-current-buffer (or buf (current-buffer))
    (texfrag-LaTeX-file absolute mkdir t)))

(defvar-local texfrag-tex-buffer nil
  "`texfrag-region' generates this buffer as a LaTeX target buffer.")

(defvar-local texfrag-source-buffer nil
  "`texfrag-region' generates a LaTeX-buffer.
This variable is the link back from the LaTeX-buffer to the source buffer.")

(defmacro texfrag-with-source-buffer (&rest body)
  "Run BODY in `texfrag-source-buffer'."
  (declare (debug body))
  `(progn
     (unless (buffer-live-p texfrag-source-buffer)
       (user-error "TeXfrag source buffer %S not ready in LaTeX target buffer %S" texfrag-source-buffer (current-buffer)))
     (with-current-buffer texfrag-source-buffer
       ,@body)))

(defmacro texfrag-with-tex-buffer (&rest body)
  "Run BODY in `texfrag-source-buffer'."
  (declare (debug body))
  `(progn
     (unless (buffer-live-p texfrag-tex-buffer)
       (user-error "TeXfrag LaTeX buffer %S not ready in LaTeX target buffer %S" texfrag-tex-buffer (current-buffer)))
     (with-current-buffer texfrag-tex-buffer
       ,@body)))

(defmacro texfrag-match-transformed-eqn (match)
  "Get the transformed equation entry from return value MATCH of `texfrag-next-frag-function'."
  `(nth 2 ,match))

(defmacro texfrag-match-frag (match)
  "Get FRAG entry from return value MATCH of `texfrag-next-frag-function'."
  `(nth 3 ,match))

(defmacro texfrag-frag-plist (frag)
  "Get the property list in entry FRAG of `texfrag-frag-alist'."
  `(nthcdr 4 ,frag))

(defmacro texfrag-match-plist (match)
  "Get the property list in the FRAG entry of MATCH."
  `(texfrag-frag-plist (texfrag-match-frag ,match)))

(defvar-local texfrag-running nil
  "Set in `texfrag-region' and reset in `texfrag-after-tex' in the source buffer.
A non-nil value indicates that `preview-region' is running in the LaTeX target buffer.
The actual value is the LaTeX target buffer.")

(defun texfrag-after-tex ()
  "Buffer-local hook function for `texfrag-after-preview-hook'.
It is used in LaTeX buffers generated by texfrag."
  (texfrag-with-source-buffer
   (setq texfrag-running nil))
  (cl-loop for ol being the overlays ;; ol is an overlay in the LaTeX buffer
           if (eq (overlay-get ol 'category) 'preview-overlay)
           do
           (when-let ((ol-src (get-text-property (overlay-start ol) 'texfrag-src))
                      (buf-src (overlay-buffer ol-src))
                      (b-src (overlay-start ol-src))
                      (e-src (overlay-end ol-src))
                      (str-src (with-current-buffer buf-src
                                 (buffer-substring-no-properties b-src e-src))))
             ;; The user might change the source string while LaTeX is running.
             ;; We don't generate overlays for those LaTeX fragments.
             (if (string= str-src (overlay-get ol-src 'texfrag-string))
                 (move-overlay ol b-src e-src buf-src)
               (delete-overlay ol))
             (delete-overlay ol-src))))

(defvar texfrag-cleanup-hook nil
  "Hook run as last action before `texfrag-tex-buffer' is killed.
`TeX-output-buffer' has already been closed.")

(defun texfrag-cleanup ()
  "Delete the buffer registered at `texfrag-tex-buffer'.
Delete also the corresponding output buffer."
  ;; org-mode does crazy stuff:
  ;; It copies local variables of the original org buffer to temp buffers.
  ;; If we do not double check the tex buffer is killed together with the temp buffer.
  (when (and
	 (buffer-live-p texfrag-tex-buffer)
	 (eq (current-buffer) (texfrag-with-tex-buffer texfrag-source-buffer)))
    (with-current-buffer texfrag-tex-buffer
      (let* ((output-buffer (TeX-process-buffer (file-name-sans-extension (buffer-file-name))))
	     (proc (and (buffer-live-p output-buffer) (get-buffer-process output-buffer)))
	     kill-buffer-query-functions)
	(when (buffer-live-p output-buffer)
	  (when (process-live-p proc)
	    (kill-process proc))
	  (set-buffer-modified-p nil)
	  (kill-buffer output-buffer))
	(run-hooks 'texfrag-cleanup-hook)
	(set-buffer-modified-p nil)
	(kill-buffer (current-buffer))))
    (cl-assert (null (buffer-live-p texfrag-tex-buffer)) nil
	       "Texfrag-tex-buffer %s still live." texfrag-tex-buffer)
    (setq texfrag-tex-buffer nil)))

(defvar texfrag-after-preview-hook nil
  "Buffer-local hook run after the preview images have been created.
\(i.e., after `preview-parse-messages').
The current buffer is the one stored in variable `TeX-command-buffer'.")

(defun texfrag-after-preview (&rest _)
  "Run hooks from `texfrag-after-preview-hook' as after-advice for `preview-parse-messages'."
  (with-current-buffer TeX-command-buffer
    (run-hooks 'texfrag-after-preview-hook)))

(advice-add #'preview-parse-messages :after #'texfrag-after-preview)

(defun texfrag-clearout-region (b e)
  "Clear out all texfrag overlays within region from B to E."
  (cl-loop for ol the overlays from b to e
	   if (or (overlay-get ol 'texfrag-string)
		  (equal (overlay-get ol 'category) 'preview-overlay))
	   do (delete-overlay ol)))

(defmacro texfrag-insert-tex-part (fun)
  "Insert part of the TeX buffer described by FUN.
FUN may be a function returning the string to be inserted
or the string itself."
  (declare (debug form))
  `(insert (texfrag-with-source-buffer
	    (cond
	     ((stringp ,fun) ,fun)
	     ((functionp ,fun) (funcall ,fun))
	     (t
	      (user-error "Unrecognized format of %s: %s" (quote ,fun) ,fun)
	      )))))

(defun texfrag-generator-place-preview (ov img _box &optional _counters _tempdir &rest _place-opts)
  "Call me like `preview-gs-place'.
Return OV after setting 'preview-image to a cons (IMG . IMG)
assuming that img is already an image."
  (when (stringp img)
    (setq img (expand-file-name img))
    (if	(and (file-readable-p img)
	     (null (file-directory-p img)))
      (progn
	(setq img (create-image img))
	(overlay-put ov 'preview-image (cons img img)))
      (warn "Cannot find image file %S" img)))
  ov)

(defun texfrag-scale-from-face ()
  "Compute `preview-scale' from face like `preview-scale-from-face'.
But take `text-scale-mode-amount' into account."
  ;; The original version `preview-scale-from-face'
  ;; is called with the TeX process buffer active.
  ;; But, we want the images be scaled like the font in `TeX-command-buffer'!
  `(lambda ()
     (with-current-buffer (or (and (buffer-live-p TeX-command-buffer)
				   TeX-command-buffer)
			      (current-buffer))
       (* (funcall ,(preview-scale-from-face))
	  texfrag-scale
	  (expt text-scale-mode-step
		text-scale-mode-amount)))))

(defvar auto-insert-alist)
(defvar auto-insert)
(defvar texfrag--text-scale-mode-step)
(defvar text-scale-mode-step)
(defun texfrag-region (&optional b e)
  "Collect LaTeX fragments in region from B to E in the LaTeX target file.
Thereby, the LaTeX target file is that one returned by
function `texfrag-LaTeX-file'.
Afterwards start `preview-document' on the target file.
The function `texfrag-after-tex' is hooked into `texfrag-after-preview-hook'
which runs after `preview-document'.
`texfrag-after-tex' transfers the preview images
from the LaTeX target file buffer to the source buffer.
B defaults to `point-min' and E defaults to `point-max'."
  (interactive "r")
  (unless b (setq b (point-min)))
  (unless e (setq e (point-max)))
  (let ((make-backup-files nil)
	(texfrag-inhibit t)
	(tex-path (texfrag-LaTeX-file t t))
		(src-buf (current-buffer))
        (coding-sys (intern-soft ;; LaTeX does not accept a byte order mark:
					 (replace-regexp-in-string
					  "-with-signature" ""
					  (symbol-name (or coding-system-for-write buffer-file-coding-system)))))
		tex-buf
		found
		found-str
		(texfrag--scale texfrag-scale)
		(texfrag--preview-scale-function preview-scale-function)
		(texfrag--text-scale-mode-amount text-scale-mode-amount))
    (let (auto-insert-alist auto-insert)
      (setq tex-buf (find-file-noselect tex-path)
            texfrag-tex-buffer tex-buf))
    (texfrag-clearout-region b e)
    (save-excursion
      (goto-char b)
      (while (setq found (texfrag-search-forward-fragment e))
	(let* ((found-b (nth 0 found))
	       (found-e (nth 1 found))
	       ol
	       (generator (plist-get (texfrag-match-plist found) :generator)))
	  (if generator
	      (progn
		(unless (functionp generator)
		  (user-error "Generator %S used at %s in buffer %s is not a function" generator found-b (current-buffer)))
		(let ((preview-image-type 'texfrag)
		      (preview-image-creators '((texfrag (place texfrag-generator-place-preview)))))
		  (setq ol (preview-place-preview (funcall generator (texfrag-match-transformed-eqn found)) found-b found-e nil nil (cl-copy-list TeX-active-tempdir) nil))
		  ))
	    (setq ol (make-overlay found-b found-e))
	    (unless found-str ; only modify the buffer there if at least one LaTeX fragment
	      (with-current-buffer tex-buf
			(set-buffer-file-coding-system coding-sys)
			(delete-region (point-min) (point-max))))
	    (setq found-str (buffer-substring-no-properties found-b found-e))
	    (overlay-put ol 'texfrag-string found-str)
	    (with-current-buffer tex-buf
	      (insert "\n" (propertize (nth 2 found) 'texfrag-src ol)))))))
    ;;; end of tex-buf:
    (if found-str ;; avoid error messages if no LaTeX fragments were found
	(progn
	  (cl-assert (buffer-live-p tex-buf))
	  (with-current-buffer tex-buf
	    (message "Running texfrag with LaTeX target buffer %S and source buffer %S" tex-buf src-buf)
	    (setq-local texfrag-source-buffer src-buf)
	    (put 'texfrag-source-buffer 'permanent-local t)
	    (texfrag-insert-tex-part texfrag-tail-function)
	    (goto-char (point-min))
	    (texfrag-insert-tex-part texfrag-header-function)
            (texfrag-insert-tex-part "\n\\begin{document}")
	    (save-buffer)
	    (let (TeX-mode-hook
		  LaTeX-mode-hook) ;; Don't activate texfrag-mode in style buffers (Elisp files).
	      (TeX-latex-mode)
	      (add-hook 'texfrag-after-preview-hook #'texfrag-after-tex t t)
	      (with-current-buffer src-buf
		(setq texfrag-running tex-buf))
	      (let ((preview-auto-cache-preamble t))
		(setq texfrag-scale texfrag--scale
		      preview-scale-function texfrag--preview-scale-function
		      text-scale-mode-amount texfrag--text-scale-mode-amount)
		(preview-document)
		))))
      (setq texfrag-running nil))))

(defun texfrag-ready-p (b e)
  "Check whether the overlays in region from B to E are ready for use."
  (cl-loop for ol being the overlays from b to e
	   when (and (overlay-buffer ol) ;; Emacs 26.3 sometimes returns "overlay in no buffer"
		     (eq (overlay-get ol 'category) 'preview-overlay) ;; Hopefully this identifies preview overlays.
		     )
           unless (and (memq (overlay-get ol 'preview-state) '(active inactive))
                       (null (overlay-get ol 'queued))
                       (cdr (overlay-get ol 'preview-image)))
           return nil
           finally return t))

(defmacro texfrag-while-not-quit-and (test seconds &rest body)
  "While TEST is non-nil and SECONDS long quit is not sent run BODY.
When the user presses a key other than \\[keyboard-quit] the event is available
as let-bound variable EVENT in BODY.
Returns t when it exits on \\[keyboard-quit] and nil when TEST evaluates to nil."
  (declare (debug (sexp sexp body)) (indent 2))
  ;; In cygwin emacs keyboard-quit does not work in a loop like
  ;; (while running (sit-for SECONDS))
  ;; waiting for a state flag set by a sentinel.
  ;; Therfore we need this hack.
  `(let ((inhibit-quit t) event)
     (while (and ,test
                 (null
                  (eq (setq event (read-event "Press C-g to abort." nil ,seconds)) ?\C-g)))
       ,@body)
     (eq event ?\C-g)))

;;;###autoload:
(defun texfrag-region-synchronously (b e)
  "Call `texfrag-region' on region from B to E synchronously.
It waits for `texfrag-after-tex' to finish.
Usage example:
File content of \"test.org\":
--8<------------------------------------------------------------------
Start texfrag region.
First TeX-fragment: \\\(z=\sqrt{x^2 + y^2}\\\)
Second TeX-fragment:
  \\\(s(x) = \\int_0^x \\sqrt{1 + f'(\\bar x)^2}\\;d\\bar x\\\)
Stop texfrag region.

#+begin_src emacs-lisp :results silent
 (preview-clearout-buffer)
 (goto-char (point-min))
 (texfrag-region-synchronously
    (point-min) (search-forward \"Stop texfrag region.\"))
 (goto-char (point-min))
 (search-forward \"\\\\(\"))
 (let ((b (match-beginning 0)))
   (message \"%S\" (overlays-at b)))
#+end_src

* Local Variables :noexport:
Local Variables:
mode: org
eval: (texfrag-mode)
read-only-mode: nil
End:
-->8------------------------------------------------------------------"
  (interactive "r")
  (texfrag-region b e)
  (when (texfrag-while-not-quit-and texfrag-running texfrag-poll-time)
    (keyboard-quit))
  ;; preview-parse-message has run
  ;; now we are waiting for (e.g.) preview-gs-close
  ;; to convert the ps file into png images
  ;; We can only check whether the images are prepared.
  (when (texfrag-while-not-quit-and (null (texfrag-ready-p b e)) texfrag-poll-time)
    (keyboard-quit)))

(defvar-local texfrag-preview-region-function nil
  "A function registered here will override the behavior of `preview-region'.
The function is called with two arguments the beginning and the end of the region to be processed.
It defaults to the original function.")

(defun texfrag-document ()
  "Process LaTeX fragments in the whole document."
  (interactive)
  (funcall texfrag-preview-region-function (point-min) (point-max)))

(defvar texfrag-submap
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-d") #'texfrag-document)
    (define-key map (kbd "C-p") #'preview-at-point)
    (define-key map (kbd "C-l") #'texfrag-show-log)
    map)
  "Keymap of command `texfrag-mode' to be bound to some prefix-key.")

(advice-add #'preview-region :around #'texfrag-preview-region-ad)

(defvar texfrag-mode-map (make-sparse-keymap)
  "Menu for command `texfrag-mode'.")

(easy-menu-define nil texfrag-mode-map "Generating or removing previews with texfrag."
  '("TeX"
    ["Turn off texfrag mode" (texfrag-mode -1) t]
    ["Help for texfrag mode" (describe-function 'texfrag-mode) t]
    "--"
    "Generate previews"
    ["at point" preview-at-point t]
    ["for region" texfrag-region t]
    ["for document" texfrag-document t]
    "--"
    "Remove previews"
    ["at point" preview-clearout-at-point t]
    ["from region" preview-clearout t]
    ["from document" preview-clearout-document t]
    "--"
    "Log"
    ["Show log file" texfrag-show-log t]
    ))

(defun texfrag-set-prefix (prefix)
  "In texfrag mode set the prefix key sequence buffer-locally to PREFIX.
Example:
\(texfrag-set-prefix (kbd \"<C-f12>\"))"
  (define-key texfrag-mode-map texfrag-prefix nil)
  (setq texfrag-prefix prefix)
  (define-key texfrag-mode-map texfrag-prefix texfrag-submap))

(defun texfrag-find-setup-function ()
  "Find the setup function associated to current buffer's major mode."
  (let ((supported-modes (apply 'append (mapcar 'cdr texfrag-setup-alist)))
	(mode major-mode))
    (while
	(and
	 (null (member mode supported-modes))
	 (setq mode (get mode 'derived-mode-parent))))
    (and
     mode
     (car-safe (cl-rassoc-if (lambda (modes) (member mode modes)) texfrag-setup-alist)))))

;; What `define-globalized-minor-mode' does:
;; Function `texfrag-global-mode-cmhh' is registered in `change-major-mode-hook'.
;; It temporarily registers `texfrag-global-mode-enable-in-buffers' in `post-command-hook'.
;; Function `texfrag-global-mode-enable-in-buffers' calls
;; for all buffers in `texfrag-global-mode-buffers'
;; first (texfrag-mode -1) and (texfrag-global-mode-fun) afterwards.
;; All hooks are registered globally in `define-globalized-minor-mode'.
;; We can exploit that and register our stuff buffer locally to ensure that it really runs last.
;; ==>>
;; If `texfrag-preview-buffer-at-start' is non-nil we put
;; texfrag-buffer at the end of post-command-hook
;; via `texfrag-post-command-preview'.
(defun texfrag-post-command-preview ()
  "Deregister me from `post-command-hook' and run `texfrag-region' for the full buffer."
  (remove-hook 'post-command-hook #'texfrag-post-command-preview t)
  (texfrag-region (point-min) (point-max)))

(defvar texfrag-global-show-last-mode) ;;< forward declaration

;;;###autoload
(define-minor-mode texfrag-mode
  "Preview LaTeX fragments in current buffer with the help of the
`preview' package."
  nil
  " TeX"
  nil
  (let ((setup-function (texfrag-find-setup-function)))
    (when setup-function
      (funcall setup-function)))
  (if texfrag-mode
      (let ((texfrag-inhibit t))
	;; (message "Switching on texfrag-mode for buffer %S" (current-buffer))
	;; (backtrace-message)
        (unless texfrag-preview-region-function
          (setq texfrag-preview-region-function #'texfrag-region))
	(define-key texfrag-mode-map texfrag-prefix texfrag-submap)
	(require 'tex-mode)
	(LaTeX-preview-setup)
	(preview-mode-setup)
	(setq-local preview-scale-function #'texfrag-scale-from-face)
	(when texfrag-preview-buffer-at-start
	  ;; Protect against multiple activation in derived major modes:
	  (add-hook 'post-command-hook #'texfrag-post-command-preview t t))
	(add-hook 'kill-buffer-hook #'texfrag-cleanup nil t)
	(add-hook 'change-major-mode-hook #'texfrag-cleanup nil t)
	(when texfrag-global-show-last-mode
	  (texfrag-show-last-mode))
	)
    ;; (message "Switching off texfrag-mode for buffer %S" (current-buffer))
    ;; (backtrace-message)
    ;; (texfrag-cleanup)
    (remove-hook 'kill-buffer-hook #'texfrag-cleanup t)
    (remove-hook 'change-major-mode-hook #'texfrag-cleanup t)
    (preview-clearout-document)))

(defun texfrag-global-mode-fun ()
  "Helper function for command `texfrag-global-mode'.
Switch texfrag mode on if the major mode of the current buffer supports it."
  (when (and
	 (null texfrag-inhibit)
	 (null texfrag-mode)
	 (null texfrag-source-buffer)
	 (texfrag-find-setup-function))
    ;; Note: Function `texfrag-mode' inhibits `texfrag-global-mode'
    ;; during execution.
    (texfrag-mode)))

;;;###autoload
(define-global-minor-mode texfrag-global-mode texfrag-mode
  texfrag-global-mode-fun
  :group 'texfrag
  :require 'texfrag)

(defun texfrag-preview-region-ad (oldfun b e)
  "Around advice for `preview-region'.
It overrides the behavior of `preview-region' with the function
registered at `texfrag-preview-region-function'.
The original `preview-region' function is passed through argument OLDFUN.
B and E are the boundaries of the region to be processed."
  (let ((inhibit-read-only t)) ; we are just putting text properties
					; e.g., required for pdf-annot.
    (if (and
	 texfrag-mode
	 texfrag-preview-region-function)
	(funcall texfrag-preview-region-function b e)
      (funcall oldfun b e))))

(defun texfrag-show-log ()
  "Show log-file of last preview process of current buffer."
  (interactive)
  (TeX-recenter-output-buffer nil))

(defun texfrag-fix-display-math (&optional b e)
  "Insert line breaks around displayed math environments in region from B to E."
  (save-excursion
    (let ((end-marker (make-marker))
	  (eq-end-marker (make-marker)))
      (unwind-protect
          (progn
            (set-marker end-marker (or e (point-max)))
            (goto-char (or b (point-min)))
            (let (math)
              (while (setq math (funcall texfrag-next-frag-function end-marker))
		(when (let ((props (texfrag-match-plist math)))
			(or
			 (plist-get props :display)
			 (eq 'display (car props)) ;;< compatibility
			 ))
		  (set-marker eq-end-marker (nth 1 math))
		  (goto-char eq-end-marker)
		  (unless (looking-at "[[:space:]]*$")
		    (insert "\n"))
		  (goto-char (nth 0 math))
		  (unless (looking-back "^[[:space:]]*" (line-beginning-position))
		    (insert "\n"))
		  (goto-char eq-end-marker)
		  ))))
	(set-marker eq-end-marker nil)
	(set-marker end-marker nil)))))

(defun texfrag-MathJax-filter (str)
  "`texfrag-equation-filter' filtering STR for `texfrag-MathJax-mode'.
Replaces &amp; with &, &lt; with <, and &gt; with >."
  (setq str (replace-regexp-in-string "&amp;" "&" str))
  (setq str (replace-regexp-in-string "&lt;" "<" str))
  (replace-regexp-in-string "&gt;" ">" str))

(defvar texfrag-MathJax-alist
  '(("\\$\\$" "\\$\\$" "$$" "$$")
    ("\\\\\\[" "\\\\\\]" "\\\\[" "\\\\]")
    ("\\\\(" "\\\\)" "\\\\(" "\\\\)")
    ("\\\\begin{\\([a-z*]+\\)}" "\\\\end{\\1}" "\\\\begin{\\2}" "\\\\end{\\2}"))
  "Value for `texfrag-frag-alist' in modes with MathJax-like syntax.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; prog-mode

(defun texfrag-prog ()
  "Texfrag setup for `prog-mode'."
  ;; That is just a dummy since the default values are appropriate for prog-mode.
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; org-mode

(defvar org-preview-latex-default-process)
(defvar org-preview-latex-process-alist)
(defvar org-format-latex-header)
(declare-function org-latex-make-preamble "org")
(declare-function org-export-get-backend "org")
(declare-function org-export-get-environment "org")
(declare-function org-element-type "org-element")
(declare-function org-element-context "org-element")

(defun texfrag-org-header ()
  "Generate LaTeX header for org-files."
  (require 'org)
  (let* ((processing-type org-preview-latex-default-process)
         (processing-info (assq processing-type org-preview-latex-process-alist))
         (latex-header org-format-latex-header)
         (my-class-opts texfrag-org-class-options))
    (when (string-match "[[:space:]]*\\[\\(.*\\)\\][[:space:]]*" my-class-opts)
      (setq my-class-opts (match-string 1 my-class-opts)))
    (when (and
           (null (string-empty-p my-class-opts))
           (string-match "\\\\documentclass\\(\\[.*\\]\\)?{" latex-header))
      (let ((opts (match-string 1 latex-header)))
        (setq latex-header
              (if opts
                  (replace-match
                   (concat (substring opts nil -1) "," my-class-opts "]")
                   nil t latex-header 1)
                (replace-match
                 (format "\\documentclass[%s]{" my-class-opts)
                 nil t latex-header)))))
    (when (stringp texfrag-org-add-to-header)
      (setq latex-header (concat latex-header
                                 texfrag-org-add-to-header)))
    (or (plist-get processing-info :latex-header)
        (org-latex-make-preamble
         (org-export-get-environment (org-export-get-backend 'latex))
         latex-header
         'snippet))))

(defun texfrag-org-latex-p ()
  "Return non-nil if point is in a LaTeX formula of an org document.
Formulas can be LaTeX fragments or LaTeX environments."
  (require 'org-element)
  (memq (org-element-type
	 (save-match-data
	   (org-element-context)))
	'(latex-fragment latex-environment)))

(defvar org-html-with-latex)

(defun texfrag-org ()
  "Texfrag setup for `org-mode'."
  (setq texfrag-frag-alist
	'((("\\$\\$" texfrag-org-latex-p) "\\$\\$" "$$" "$$" :display t)
	  (("\\$" texfrag-org-latex-p) "\\$" "$" "$")
          (("\\\\(" texfrag-org-latex-p) "\\\\)" "$" "$")
	  (("\\\\\\[" texfrag-org-latex-p) "\\\\\\]" "\\\\[" "\\\\]" :display t)
          (("\\\\begin{\\([a-z*]+\\)}" texfrag-org-latex-p) "\\\\end{\\1}" "\\\\begin{\\2}" "\\\\end{\\2}" :display t))
	texfrag-comments-only nil
        texfrag-header-function #'texfrag-org-header
        org-html-with-latex 'dvipng) ;; Export of LaTeX formulas as embedded formulas only works this way.
  )

(defcustom texfrag-org-keep-minor-modes 'texfrag
  "Let `org-mode' restore minor modes after restart.
Possible values:
'texfrag : preserve option `texfrag-mode' only
t: preserve as many minor modes as possible
nil: dont preserve any minor modes"
  :type '(choice (item texfrag) (item t) (item nil))
  :group 'texfrag)

(defun texfrag-org-keep-minor-modes (oldfun &rest args)
  "Call OLDFUN with ARGS but remember active minor modes and restart them."
  (let ((active-minor-modes
	 (cl-case texfrag-org-keep-minor-modes
	   (texfrag
	    (and texfrag-mode '(texfrag-mode)))
	   (t
	    (cl-remove-if-not
	     (lambda (minor-mode)
	       (unless (string-match "\\(\\`\\|-\\)global-" (symbol-name minor-mode))
		 (and (boundp minor-mode)
		      (symbol-value minor-mode))))
	     minor-mode-list)))))
    (apply oldfun args)
    (dolist (minor-mode active-minor-modes)
      (unless (symbol-value minor-mode)
	(funcall minor-mode)))))

(advice-add 'org-mode-restart :around #'texfrag-org-keep-minor-modes)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; trac-wiki-mode

(defun texfrag-trac-wiki ()
  "Preview TeX-fragments in MathJax html-pages."
  (setq texfrag-comments-only nil
        texfrag-frag-alist '(("^{{{\n#!latex" "^}}}" "" "")
                             ("\\$" "\\$" "$" "$")
                             ("\\\\(" "\\\\)" "\\\\(" "\\\\)")
                             ("\\\\\\[" "\\\\\\]" "\\\\[" "\\\\]")
                             ("\\\\(" "\\\\)" "\\\\(" "\\\\)")
                             ("\\\\begin{\\([a-z*]+\\)}" "\\\\end{\\1}" "\\\\begin{\\2}" "\\\\end{\\2}"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; markdown-mode

(defcustom texfrag-markdown-preview-image-links t
  "Should `texfrag-mode' also preview image links?"
  :type 'boolean
  :group 'texfrag)

(defun texfrag-markdown ()
  "Preview TeX-fragments in markdown files."
  (setq texfrag-comments-only nil
        texfrag-frag-alist (append
			    texfrag-LaTeX-frag-alist
			    (and texfrag-markdown-preview-image-links
				 (list (list "!\\[[^]]*\\](" "\\(?: *\\([\"']\\).*?\\1\\)?)" "" "" :generator #'identity))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; html-mode

(defcustom texfrag-html-frag-alist
  (append texfrag-LaTeX-frag-alist
	  '(("<img[[:space:]]+src=\"" "\"[^>]*>" "" "" :generator identity)))
  "Regular expression for TeX fragments in HTML pages."
  :group 'texfrag
  :type texfrag-frag-alist-type)

(defun texfrag-html-region-function (b e)
  "Special `texfrag-region' for region from B to E in html mode.
It differs from `texfrag-region' by skipping the text from buffer-beginning up to <body>."
  (save-excursion
    (goto-char b)
    (unless (search-backward "<body" nil t)
      (goto-char b)
      (setq b (search-forward "<body" e t))))
  (when b
    (texfrag-region b e)))

(defun texfrag-html ()
  "Texfrag setup for `html-mode'."
  (interactive)
  (setq texfrag-comments-only nil
        texfrag-equation-filter #'texfrag-MathJax-filter
        texfrag-frag-alist texfrag-html-frag-alist
        texfrag-preview-region-function #'texfrag-html-region-function))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; eww-mode

(defun texfrag-eww-file-name ()
  "Retrieve file name from ‘eww-data’."
  (texfrag-file-name-option texfrag-eww-default-file-name))

(defvar texfrag-eww-restore-history-functions nil
  "Functions run after `eww-restore-history' with its ELEM arg.")

(defun texfrag-eww-restore-history-ad (elem)
  "After advice for `eww-restore-history'.
It runs `texfrag-eww-reload-redisplay-hook' with arg ELEM."
  (run-hook-with-args 'texfrag-eww-restore-history-functions elem))

(eval-after-load "eww"
  (lambda ()
    (advice-add 'eww-restore-history :after #'texfrag-eww-restore-history-ad)))

(defun texfrag-eww-restore-history-fun (elem)
  "Run `texfrag-eww-set-LaTeX-file' if ELEM has nonempty :text property."
  (when (plist-get elem :text)
    (texfrag-eww-set-LaTeX-file)))

(defun texfrag-eww ()
  "Texfrag setup for `eww-mode'."
  (if texfrag-mode
      (progn
	(setq texfrag-comments-only nil
	      texfrag-equation-filter #'texfrag-MathJax-filter
	      texfrag-frag-alist '(("\\$\\$" "\\$\\$" "$$" "$$")
				   ("\\$" "\\$" "$" "$")
				   ("\\\\\\[" "\\\\\\]" "\\\\[" "\\\\]")
				   ("\\\\(" "\\\\)" "\\\\(" "\\\\)")
				   ("\\\\begin{\\([a-z*]+\\)}" "\\\\end{\\1}" "\\\\begin{\\2}" "\\\\end{\\2}")))
	(add-hook 'eww-after-render-hook #'texfrag-eww-set-LaTeX-file nil t)
	(add-hook 'texfrag-eww-restore-history-functions #'texfrag-eww-restore-history-fun nil t))
    (remove-hook 'eww-after-render-hook #'texfrag-eww-set-LaTeX-file t)
    (remove-hook 'texfrag-eww-restore-history-functions #'texfrag-eww-restore-history-fun t)))

(defun texfrag-eww-set-LaTeX-file ()
  "Render LaTeX fragments in the current eww buffer.
Set variable `texfrag-LaTeX-file' to the file name of the current eww window."
  (unless (and
	   (stringp texfrag-LaTeX-file)
	   (file-readable-p texfrag-LaTeX-file))
    (setq texfrag-LaTeX-file (texfrag-eww-file-name)))
  (when texfrag-LaTeX-file
    (texfrag-region (point-min) (point-max))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sx-question-mode

(defun texfrag-sx-after-print (&rest _args)
  "Set LaTeX formulas after printing of the stackexchange question is done.
Can be used for advice of `sx-question-mode--print-question'
or as `sx-question-mode-after-print-hook'."
  (when texfrag-mode ;;< if sx.el works with global advice
    (remove-hook 'post-command-hook #'texfrag-post-command-preview t) ;; Don't preview twice if texfrag-preview-buffer-at-start is non-nil.
    (texfrag-fix-display-math)
    (texfrag-document)))

(declare-function sx-question-mode--print-question
		  "sx-question-print.el")

(defun texfrag-sx ()
  "Texfrag setup for `sx-question-mode'."
  (setq
   texfrag-comments-only nil
   texfrag-frag-alist texfrag-LaTeX-frag-alist)
  (if texfrag-mode
      (if (special-variable-p 'sx-question-mode-after-print-hook)
	  (add-hook 'sx-question-mode-after-print-hook #'texfrag-sx-after-print nil t)
	(advice-add #'sx-question-mode--print-question :after #'texfrag-sx-after-print)
	;;> Eventually the advice should completely be replaced by the hook.
	)
    (if (special-variable-p 'sx-question-mode-after-print-hook)
	(remove-hook 'sx-question-mode-after-print-hook #'texfrag-sx-after-print t)
      (advice-remove #'sx-question-mode--print-question #'texfrag-sx-after-print))
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun texfrag-scale (scale)
  "Set SCALE factor for `preview-scale'."
  (interactive "nScale Factor:")
  (setq-local texfrag-scale scale)
  (texfrag-region (point-min) (point-max)))

(easy-menu-add-item texfrag-mode-map '(menu-bar TeX) ["Set Preview Scale" texfrag-scale t])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar preview-icon)

(defun texfrag-set-overlay-icon (ol &optional icon)
  "Set preview ICON of overlay OL.
ICON defaults to the preview image."
  (when-let ((img (car (overlay-get ol 'preview-image)))
	     (strings (overlay-get ol 'strings))
	     (str (seq-copy (cdr strings)))
	     (props (text-properties-at 0 str)))
    (plist-put props 'display (or icon img))
    (set-text-properties 0 1 props str)
    (setcdr strings str)))

(define-minor-mode texfrag-show-last-mode
  "Show the last preview image instead of the placeholder symbol."
  :lighter ""
  (save-excursion
    (save-restriction
      (widen)
      (let ((icon (and (null texfrag-show-last-mode) preview-icon)))
	(dolist (ol (overlays-in (point-min) (point-max)))
	  (texfrag-set-overlay-icon ol icon))))))

(defun texfrag-show-last-inactive-string (fun ov)
  "Show last preview when editing source code.
This is an around advice for `preview-inactive-string' as FUN with arg OV."
  (if (and texfrag-show-last-mode
	   (overlay-get ov 'preview-state))
      (let ((preview-icon (or (car-safe (overlay-get ov 'preview-image)) preview-icon)))
	(overlay-put ov 'texfrag-last-image preview-icon)
	(funcall fun ov))
    (funcall fun ov)))

(advice-add 'preview-inactive-string :around #'texfrag-show-last-inactive-string)

(defun texfrag-show-last-disabled-string (fun ov)
  "Show last preview when editing source code.
This is an around advice for `preview-disabled-string' as FUN with arg OV."
  (if (and texfrag-show-last-mode
	   (overlay-get ov 'preview-state))
      (let ((preview-icon (or (overlay-get ov 'texfrag-last-image) preview-icon)))
	(funcall fun ov))
    (funcall fun ov)))

(advice-add 'preview-disabled-string :around #'texfrag-show-last-disabled-string)

(defun texfrag-show-last-mode-turn-on ()
  "Turn on `texfrag-show-last-mode' in LaTeX and texfrag buffers."
  (when (or (derived-mode-p 'tex-mode)
	    texfrag-mode)
    (texfrag-show-last-mode)))

(define-globalized-minor-mode
  texfrag-global-show-last-mode
  texfrag-show-last-mode
  texfrag-show-last-mode-turn-on)

(easy-menu-add-item texfrag-mode-map '(menu-bar TeX) ["Show Last Preview When Editing" (texfrag-show-last-mode 'toggle) :enable t :style toggle :selected texfrag-show-last-mode])

(defun texfrag-show-last--preview-menu ()
  "Add `texfrag-show-last-mode' entry to `preview-menu'."
  (when (and
	 (boundp 'preview-menu)
	 (keymapp preview-menu))
    (easy-menu-add-item preview-menu nil ["Show Last Preview When Editing" (texfrag-show-last-mode 'toggle) :enable t :style toggle :selected texfrag-show-last-mode] "Read documentation")))

(add-hook 'LaTeX-mode-hook #'texfrag-show-last--preview-menu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'texfrag)
;;; texfrag.el ends here
