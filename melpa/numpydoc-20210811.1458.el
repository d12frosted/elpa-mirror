;;; numpydoc.el --- NumPy style docstring insertion -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Doug Davis

;; Author: Doug Davis <ddavis@ddavis.io>
;; Maintainer: Doug Davis <ddavis@ddavis.io>
;; URL: https://github.com/douglasdavis/numpydoc.el
;; Package-Version: 20210811.1458
;; Package-Commit: 2d280dd704a1a54bcb3e8091f06656c3311894bc
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Version: 0.5
;; Package-Requires: ((emacs "25.1") (s "1.12.0") (dash "2.18.0"))
;; Keywords: convenience

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

;; This package provides a function to automatically generate NumPy
;; style docstrings for Python functions: `numpydoc-generate'. The
;; NumPy docstring style guide can be found at
;; https://numpydoc.readthedocs.io/en/latest/format.html
;;
;; There are three ways that one can be guided to insert descriptions
;; for the components:
;;
;; 1. Minibuffer prompt (the default).
;; 2. yasnippet expansion (requires `yasnippet' to be installed)
;; 3. Nothing (placeholding template text is inserted).
;;
;; Convenience functions are provided to interactively configure the
;; insertion style symbol:
;; - `numpydoc-use-prompt'
;; - `numpydoc-use-yasnippet'
;; - `numpydoc-use-templates'
;;
;;; Code:

(require 'cl-lib)
(require 'python)
(require 'subr-x)

(require 'dash)
(require 's)

;; forward declare some yasnippet code.
(defvar yas-indent-line)
(declare-function yas-expand-snippet "yasnippet")

;;; customization code.

(defgroup numpydoc nil
  "NumPy docstrings."
  :group 'convenience
  :prefix "numpydoc-")

(defcustom numpydoc-insertion-style 'prompt
  "Which insertion guide to use when generating the docstring.
When set to 'prompt the minibuffer will be used to prompt for
docstring components. Setting to 'yas requires yasnippet to be
installed and `yas-expand-snippet' will be used to insert components.
When nil, template text will be inserted."
  :group 'numpydoc
  :type '(choice (const :tag "None" nil)
                 (const :tag "Prompt" prompt)
                 (const :tag "Yasnippet" yas)))

(defcustom numpydoc-quote-char ?\"
  "Character for docstring quoting style (double or single quote)."
  :group 'numpydoc
  :type 'character)

(defcustom numpydoc-insert-examples-block t
  "Flag to control if Examples section is inserted into the buffer."
  :group 'numpydoc
  :type 'boolean)

(defcustom numpydoc-insert-parameter-types t
  "Flag to control if Parameter types are inserted based on type hints."
  :group 'numpydoc
  :type 'boolean)

(defcustom numpydoc-insert-raises-block t
  "Flag to control if the Raises section is inserted.
This section will only be inserted if the flag is on and the function
body has raise statements."
  :group 'numpydoc
  :type 'boolean)

(defcustom numpydoc-template-short "FIXME: Short description."
  "Template text for the short description in a docstring."
  :group 'numpydoc
  :type 'string)

(defcustom numpydoc-template-long "FIXME: Long description."
  "Template text for the long description in a docstring."
  :group 'numpydoc
  :type 'string)

(define-obsolete-variable-alias
  'numpydoc-template-desc 'numpydoc-template-arg-desc
  "numpydoc 0.4")

(defcustom numpydoc-template-arg-desc "FIXME: Add docs."
  "Template text for individual component descriptions.
This will be added for individual argument and return description
text, and below the Examples section."
  :group 'numpydoc
  :type 'string)

(defcustom numpydoc-template-type-desc "FIXME: Add type."
  "Template text for individual component type descriptions."
  :group 'numpydoc
  :type 'string)

;;; package implementation code.

(cl-defstruct numpydoc--def
  args
  rtype
  raises)

(cl-defstruct numpydoc--arg
  name
  type
  defval)

(defconst numpydoc--yas-replace-pat "--NPDOCYAS--"
  "Temporary text to be replaced for yasnippet usage.")

(defun numpydoc--prompt-p ()
  (eq numpydoc-insertion-style 'prompt))

(defun numpydoc--yas-p ()
  (eq numpydoc-insertion-style 'yas))

(defun numpydoc--arg-str-to-struct (argstr)
  "Convert ARGSTR to an instance of `numpydoc--arg'.
The argument takes on one of four possible styles:
1. First we check for a typed argument with a default value, so it
   contains both ':' and '='. Example would be 'x: int = 5'.
2. Then we check for a typed argument without a default value,
   containing only ':'. Example would be 'x: int'.
3. Then we check for an untyped argument with a default value,
   containing only '='. Example would be 'x=5'.
4. Finally the default is an untyped argument without a default
   value. Example would be `x`."
  (cond (;; type hint and default value (or maybe a dict without a typehint)
         (and (s-contains-p ":" argstr) (s-contains-p "=" argstr))
         (let* ((comps1 (s-split-up-to "=" argstr 1))
                (comps2 (s-split-up-to ":" (car comps1) 1))
                (defval (s-trim (cadr comps1)))
                (name (s-trim (car comps2)))
                (type (cadr comps2)))
           (make-numpydoc--arg :name name
                               :type (if type (s-trim type) nil)
                               :defval defval)))
        ;; only a typehint
        ((and (string-match-p ":" argstr)
              (not (s-contains-p "=" argstr)))
         (let* ((comps1 (s-split-up-to ":" argstr 1))
                (name (s-trim (car comps1)))
                (type (s-trim (cadr comps1))))
           (make-numpydoc--arg :name name
                               :type type
                               :defval nil)))
        ;; only a default value
        ((s-contains-p "=" argstr)
         (let* ((comps1 (s-split-up-to "=" argstr 1))
                (name (s-trim (car comps1)))
                (defval (s-trim (cadr comps1))))
           (make-numpydoc--arg :name name
                               :type nil
                               :defval defval)))
        ;; only a name
        (t (make-numpydoc--arg :name argstr
                               :type nil
                               :defval nil))))

(defun numpydoc--split-args (fnargs)
  "Split FNARGS on comma but ignore those in type [brackets]."
  (let ((bc 0)
        (indquote nil)
        (insquote nil)
        (cursor -1)
        (strs '()))
    (dotimes (i (length fnargs))
      (let ((ichar (aref fnargs i)))
        (cond ((= ichar ?\[) (setq bc (1+ bc)))
              ((= ichar ?\]) (setq bc (1- bc)))
              ((= ichar ?\() (setq bc (1+ bc)))
              ((= ichar ?\)) (setq bc (1- bc)))
              ((= ichar ?\{) (setq bc (1+ bc)))
              ((= ichar ?\}) (setq bc (1- bc)))
              ((= ichar ?\") (if indquote
                                 (setq bc (1- bc)
                                       indquote nil)
                               (setq bc (1+ bc)
                                     indquote t)))
              ((= ichar ?\') (if insquote
                                 (setq bc (1- bc)
                                       insquote nil)
                               (setq bc (1+ bc)
                                     insquote t)))
              ((and (= ichar ?,) (= bc 0))
               (setq strs (append strs (list (substring fnargs
                                                        (1+ cursor)
                                                        i))))
               (setq cursor i)))))
    (setq strs (append strs (list (substring fnargs (1+ cursor)))))))

(defun numpydoc--extract-def-sig ()
  "Extract function definition string from the buffer.
This function assumes the cursor to be in the function body."
  (save-excursion
    (buffer-substring-no-properties
     (progn
       (python-nav-beginning-of-defun)
       (point))
     (progn
       (python-nav-end-of-statement)
       (point)))))

(defun numpydoc--parse-def (buffer-substr)
  "Parse the BUFFER-SUBSTR; return instance of numpydoc--def."
  (save-excursion
    (let* ((fnsig buffer-substr)
           ;; trimmed string of the function signature
           (trimmed (s-collapse-whitespace fnsig))
           ;; split into parts (args and return type)
           (parts (s-split "->" trimmed))
           ;; raw return
           (rawret (if (nth 1 parts)
                       (s-trim (nth 1 parts))
                     nil))
           ;; save return type as a string (or nil)
           (rtype (when rawret
                    (substring rawret 0 (1- (length rawret)))))
           ;; raw signature without return type as a string
           (rawsig (cond (rtype (substring (s-trim (car parts)) 0 -1))
                         (t (substring (s-trim (car parts)) 0 -2))))
           ;; function args as strings
           (rawargs (-map #'s-trim
                          (numpydoc--split-args
                           (substring rawsig
                                      (1+ (string-match-p (regexp-quote "(")
                                                          rawsig))))))
           ;; function args as a list of structures (remove some special cases)
           (args (-remove (lambda (x)
                            (-contains-p (list "" "self" "*" "/")
                                         (numpydoc--arg-name x)))
                          (-map #'numpydoc--arg-str-to-struct rawargs)))
           ;; look for exceptions in the function body
           (exceptions (numpydoc--find-exceptions)))
      (make-numpydoc--def :args args :rtype rtype :raises exceptions))))

(defun numpydoc--has-existing-docstring-p ()
  "Check for an existing docstring.
This function assumes the cursor to be in the function body."
  (save-excursion
    (python-nav-beginning-of-defun)
    (python-nav-end-of-statement)
    (end-of-line)
    (right-char)
    (back-to-indentation)
    (right-char 1)
    (and (eq numpydoc-quote-char (preceding-char))
         (eq numpydoc-quote-char (following-char))
         (progn
           (right-char)
           (eq numpydoc-quote-char (preceding-char)))
         t)))

(defun numpydoc--detect-indent ()
  "Detect necessary indent for current function docstring.
This function assumes the cursor to be in the function body."
  (save-excursion
    (let ((beg (progn
                 (python-nav-beginning-of-defun)
                 (point)))
          (ind (progn
                 (back-to-indentation)
                 (point))))
      (+ python-indent-offset (- ind beg)))))

(defun numpydoc--fnsig-range ()
  "Find the beginning and end of the function signature.
This function assumes the cursor to be in the function body."
  (save-excursion
    (vector (progn (python-nav-beginning-of-defun) (point))
            (progn (python-nav-end-of-statement) (point)))))

(defun numpydoc--function-range ()
  "Find the beginning and end of the function definition.
This function assumes the cursor to be in the function body."
  (save-excursion
    (vector (progn (python-nav-beginning-of-defun) (point))
            (progn (python-nav-end-of-defun) (point)))))

(defun numpydoc--find-exceptions ()
  "Find exceptions in the function body.
This function assumes the cursor to be in the function body."
  (save-excursion
    (let ((lines '())
          (fnrange (numpydoc--function-range))
          (pat (rx (one-or-more blank)
                   "raise"
                   (= 1 blank)
                   (any upper-case)
                   anything)))
      (goto-char (elt fnrange 0))
      (while (re-search-forward pat (elt fnrange 1) t)
        (save-excursion
          (let ((p1 (progn
                      (move-beginning-of-line nil)
                      (back-to-indentation)
                      (point)))
                (p2 (progn
                      (move-end-of-line nil)
                      (point))))
            (push (buffer-substring-no-properties p1 p2) lines))))
      (-uniq
       (-map (lambda (x)
               (car (s-split (rx (or eol "("))
                             (s-chop-prefix "raise " x))))
             lines)))))

(defun numpydoc--fill-last-insertion ()
  "Fill paragraph on last inserted text."
  (save-excursion
    (move-beginning-of-line nil)
    (back-to-indentation)
    (set-mark-command nil)
    (move-end-of-line nil)
    (fill-paragraph nil t)
    (deactivate-mark)))

(defun numpydoc--insert (indent &rest lines)
  "Insert all elements of LINES at indent level INDENT."
  (dolist (s lines)
    (insert (format "%s%s" (make-string indent ?\s) s))))

(defun numpydoc--insert-short-and-long-desc (indent)
  "Insert short description with INDENT level."
  (let ((ld nil)
        (tmps (cond ((numpydoc--yas-p) numpydoc--yas-replace-pat)
                    (t numpydoc-template-short)))
        (tmpl (cond ((numpydoc--yas-p) numpydoc--yas-replace-pat)
                    (t numpydoc-template-long))))
    (insert "\n")
    (numpydoc--insert indent
                      (concat (make-string 3 numpydoc-quote-char)
                              (if (numpydoc--prompt-p)
                                  (read-string
                                   (format "Short description: "))
                                tmps)
                              "\n\n")
                      (make-string 3 numpydoc-quote-char))
    (forward-line -1)
    (beginning-of-line)
    (if (numpydoc--prompt-p)
        (progn
          (setq ld (read-string (concat "Long description "
                                        "(or press return to skip): ")
                                nil nil "" nil))
          (unless (string-empty-p ld)
            (insert "\n")
            (numpydoc--insert indent ld)
            (numpydoc--fill-last-insertion)
            (insert "\n")))
      (insert "\n")
      (numpydoc--insert indent tmpl)
      (insert "\n"))))

(defun numpydoc--insert-item (indent name &optional type)
  "Insert parameter with NAME and TYPE at level INDENT."
  (numpydoc--insert indent
                    (if type
                        (format "%s : %s\n" name type)
                      (format "%s\n" name))))

(defun numpydoc--insert-item-and-type (indent name type)
  "Insert parameter with NAME and TYPE at level INDENT."
  (let ((tp type)
        (tmpt (cond ((numpydoc--yas-p) numpydoc--yas-replace-pat)
                    (t numpydoc-template-type-desc))))
    (if numpydoc-insert-parameter-types
        (progn
          (unless tp
            (setq tp (if (numpydoc--prompt-p)
                         (read-string (format "Type of %s: "
                                              name))
                       tmpt)))
          (numpydoc--insert indent (format "%s : %s\n" name tp)))
      (numpydoc--insert-item indent name))))

(defun numpydoc--insert-item-desc (indent element)
  "Insert ELEMENT parameter description at level INDENT."
  (let* ((tmpd (cond ((numpydoc--yas-p) numpydoc--yas-replace-pat)
                     (t numpydoc-template-arg-desc)))
         (desc (concat (make-string 4 ?\s)
                      (if (numpydoc--prompt-p)
                          (read-string (format "Description for %s: "
                                               element))
                        tmpd))))
    (numpydoc--insert indent desc)
    (numpydoc--fill-last-insertion)
    (insert "\n")))

(defun numpydoc--insert-parameters (indent fnargs)
  "Insert FNARGS (function arguments) at INDENT level."
  (when fnargs
    (insert "\n")
    (numpydoc--insert indent
                      "Parameters\n"
                      "----------\n")
    (dolist (element fnargs)
      (numpydoc--insert-item-and-type indent
                                      (numpydoc--arg-name element)
                                      (numpydoc--arg-type element))
      (numpydoc--insert-item-desc indent
                                  (numpydoc--arg-name element)))))

(defun numpydoc--insert-return (indent fnret)
  "Insert FNRET (return) description (if exists) at INDENT level."
  (let ((tmpr (cond ((numpydoc--yas-p) numpydoc--yas-replace-pat)
                    (t numpydoc-template-arg-desc))))
    (when (and fnret (not (string= fnret "None")))
      (insert "\n")
      (numpydoc--insert indent
                        "Returns\n"
                        "-------\n"
                        fnret)
      (insert "\n")
      (numpydoc--insert indent
                        (concat (make-string 4 ?\s)
                                (if (numpydoc--prompt-p)
                                    (read-string "Description for return: ")
                                  tmpr)))
      (numpydoc--fill-last-insertion)
      (insert "\n"))))

(defun numpydoc--insert-exceptions (indent fnexcepts)
  "Insert FNEXCEPTS (exception) elements at INDENT level."
  (when (and numpydoc-insert-raises-block fnexcepts)
    (insert "\n")
    (numpydoc--insert indent
                      "Raises\n"
                      "------\n")
    (dolist (exstr fnexcepts)
      (numpydoc--insert-item indent exstr)
      (numpydoc--insert-item-desc indent exstr))))

(defun numpydoc--insert-examples (indent)
  "Insert function examples block at INDENT level."
  (let ((tmpd (cond ((numpydoc--yas-p) numpydoc--yas-replace-pat)
                    (t numpydoc-template-arg-desc))))
    (when numpydoc-insert-examples-block
      (insert "\n")
      (numpydoc--insert indent
                        "Examples\n"
                        "--------\n"
                        (concat tmpd "\n")))))

(defun numpydoc--yasnippetfy ()
  "Take the template and convert to yasnippet then execute."
  ;; replace the template
  (save-excursion
    (python-nav-beginning-of-defun)
    (let ((i 1)
          (start (point)))
      (goto-char start)
      (while (re-search-forward numpydoc--yas-replace-pat nil t)
        (replace-match (format "${%s}" i))
        (setq i (+ 1 i)))))
  ;; execute the yasnippet
  (save-excursion
    (let ((ds-start (progn
                      (python-nav-beginning-of-statement)
                      (forward-char 3)
                      (point)))
          (ds-end (progn
                    (python-nav-end-of-statement)
                    (forward-char -3)
                    (point))))
      (goto-char ds-start)
      (set-mark-command nil)
      (goto-char ds-end)
      (kill-region 1 1 t)
      (yas-expand-snippet (current-kill 0 t)
                          nil nil '((yas-indent-line 'nothing))))))

(defun numpydoc--insert-docstring (indent fndef)
  "Insert FNDEF with indentation level INDENT."
  (numpydoc--insert-short-and-long-desc indent)
  (numpydoc--insert-parameters indent (numpydoc--def-args fndef))
  (numpydoc--insert-return indent (numpydoc--def-rtype fndef))
  (numpydoc--insert-exceptions indent (numpydoc--def-raises fndef))
  (numpydoc--insert-examples indent)
  (when (numpydoc--yas-p)
    (numpydoc--yasnippetfy)))

(defun numpydoc--delete-existing ()
  "Delete existing docstring."
  (let ((3q (make-string 3 numpydoc-quote-char)))
    (when (numpydoc--has-existing-docstring-p)
      (python-nav-beginning-of-defun)
      (python-nav-end-of-statement)
      (re-search-forward 3q)
      (left-char 3)
      (set-mark-command nil)
      (re-search-forward 3q)
      (re-search-forward 3q)
      (right-char 1)
      (delete-region (region-beginning) (region-end))
      (deactivate-mark)
      (indent-for-tab-command))))

;;; public API

;;;###autoload
(defun numpydoc-use-yasnippet ()
  "Enable yasnippet insertion (see `numpydoc-insertion-style')."
  (interactive)
  (setq numpydoc-insertion-style 'yas))

;;;###autoload
(defun numpydoc-use-prompt ()
  "Enable minibuffer prompt insertion (see `numpydoc-insertion-style')."
  (interactive)
  (setq numpydoc-insertion-style 'prompt))

;;;###autoload
(defun numpydoc-use-templates ()
  "Enable template text insertion (see `numpydoc-insertion-style')."
  (interactive)
  (setq numpydoc-insertion-style nil))

;;;###autoload
(defun numpydoc-generate ()
  "Generate NumPy style docstring for Python function.
Assumes that the current location of the cursor is somewhere in the
function that is being documented."
  (interactive)
  (let ((good-to-go t)
        (fnsig (numpydoc--extract-def-sig)))
    (when (numpydoc--has-existing-docstring-p)
      (if (y-or-n-p "Docstring exists; destroy and start new? ")
          (numpydoc--delete-existing)
        (setq good-to-go nil)))
    (when good-to-go
      (python-nav-beginning-of-defun)
      (python-nav-end-of-statement)
      (numpydoc--insert-docstring (numpydoc--detect-indent)
                                  (numpydoc--parse-def fnsig)))))

;; Local Variables:
;; sentence-end-double-space: nil
;; End:
(provide 'numpydoc)
;;; numpydoc.el ends here
