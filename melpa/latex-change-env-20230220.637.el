;;; latex-change-env.el --- Change in and out of LaTeX environments -*- lexical-binding: t; -*-

;; Copyright (C) 2021, 2022, 2023  Tony Zorman
;;
;; Author: Tony Zorman <soliditsallgood@mailbox.org>
;; Keywords: convenience, tex
;; Version: 0.3
;; Package-Requires: ((emacs "27.1") (auctex "13.1"))
;; Homepage: https://gitlab.com/slotThe/change-env
;;
;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a way to modify LaTeX environments, macros, as
;; well as inline and display maths mode (seeing them as an environment
;; of sorts).  There exists a [blog post], which includes some moving
;; pictures that showcase the functionality of this package.
;;
;; Note that, in the sequel, "environment" shall usually refer to LaTeX
;; environments, macros, as well as inline and display maths mode—not
;; just to LaTeX environments themselves.
;;
;; Refer to the README for a full account of the package's
;; functionality, as well as how to install it.  Briefly:
;;
;; + The entry point is the `latex-change-env' function, which—when
;;   invoked from inside an environments—pops up a list of possible
;;   actions, as defined by the `latex-change-env-options' variable.
;;   There is also the option to cycle through arguments in
;;   `latex-change-env-cycle', which depends on [math-delimiters].
;;
;; + Labels are changed/deleted in a previous way, with an option to
;;   edit the respective label across the whole project; see below.
;;   Also, deleted labels are stored for the current session (based on
;;   the specific contents of the environment) and potentially restored
;;   when switching from e.g. display maths to an environment with an
;;   associated label prefix in `latex-change-env-labels'.
;;
;; + What exactly we mean by "inline" and "display maths" is controlled
;;   by the `latex-change-env-math-inline' and
;;   `latex-change-env-math-display' variables.
;;
;; + This package depends on AUCTeX—but you are already using that
;;   anyways.
;;
;; + If you're customizing `latex-change-env-edit-labels-in-project', we
;;   also depend on project.el, meaning Emacs 27.1 and up.
;;
;; [blog post]: https://tony-zorman.com/posts/latex-change-env-0.3.html
;; [math-delimiters]: https://github.com/oantolin/math-delimiters

;;; Code:

(eval-when-compile (require 'cl-lib))
(require 'latex)

(defgroup latex-change-env nil
  "Change in and out of LaTeX environments."
  :group 'tex)

(defcustom latex-change-env-options
  '((?k "Delete"        latex-change-env--change         )
    (?d "Display Maths" latex-change-env--to-display-math)
    (?m "Modify"        latex-change-env--modify         ))
  "Options for `latex-change-env'.
Takes a list of three items; namely,

  - a key to trigger the action,
  - a label to display to the user in the minibuffer,
  - the action to execute as a function taking no (mandatory)
    arguments."
  :group 'latex-change-env
  :type '(repeat (list
                  (character :tag "Key")
                  (string    :tag "Label")
                  (symbol    :tag "Command"))))

(defcustom latex-change-env-math-inline '("$" . "$")
  "Set the preferred style for inline maths."
  :group 'latex-change-env
  :type '(choice (const :tag "Dollar" ("$"  . "$"))
                 (const :tag "Parens" ("\\(" . "\\)"))))

(defcustom latex-change-env-math-display '("\\[" . "\\]")
  "Set the preferred style for display maths."
  :group 'latex-change-env
  :type '(choice (const :tag "Brackets" ("\\[" . "\\]"))
                 (const :tag "Dollars"  ("$$"  . "$$"))))

(defcustom latex-change-env-labels
  '(("remark"     . "rem:")
    ("definition" . "def:")
    ("lemma"      . "lem:")
    ("theorem"    . "thm:")
    ("equation"   . "eq:" )
    ("corollary"  . "cor:")
    ("example"    . "ex:"))
  "Environments with their associated label prefixes.
Given a cons cell (ENV . PRFX), the environment ENV should have
an optional label \\label{PRFXname}, where name is the actual
name of the environment."
  :group 'latex-change-env
  :type '(repeat (cons
                  (string :tag "Environment")
                  (string :tag "Label prefix"))))

(defcustom latex-change-env-edit-labels-in-project nil
  "Whether to change labels after an edit.
If this is customised to t, whenever a label changes or is
deleted, an interactive `project-query-replace-regexp' session is
started to (potentially) update the label name across the whole
project."
  :group 'latex-change-env
  :type 'boolean
  :set (lambda (symbol value)
         (when value (require 'project))
         (custom-initialize-default symbol value)))

(defvar latex-change-env--deleted-labels (make-hash-table)
  "Environments that used to have labels.
Associated to each is the respective content of the latter.")

(defun latex-change-env--get-labels (env)
  "Return the label prefix for ENV."
  (alist-get env latex-change-env-labels nil nil 'string=))

;;;; Utility

(defun latex-change-env--delete-line ()
  "Delete the current line."
  (delete-region (progn (beginning-of-line) (point))
                 (progn (forward-line 1)    (point))))

(defun latex-change-env--prompt ()
  "How to prompt the user for options."
  (mapconcat (pcase-lambda (`(,key ,label _))
               (format "[%s] %s"
                       (propertize (single-key-description key) 'face 'bold)
                       label))
             latex-change-env-options
             " "))

(defun latex-change-env--prompt-env (&optional new-env)
  "Prompt for an environment and return the result.
Optional argument NEW-ENV means use that environment.  Code
mostly taken from `LaTeX-environment'."
  (let* ((default (cond ((TeX-near-bobp) "document")
                        ((and LaTeX-default-document-environment
                              (string-equal (LaTeX-current-environment) "document"))
                         LaTeX-default-document-environment)
                        (t LaTeX-default-environment)))
         (new-env (or new-env
                      (completing-read (concat "Environment type (default " default "): ")
                                       (LaTeX-environment-list-filtered) nil nil
                                       nil 'LaTeX-environment-history default))))
    (unless (equal new-env default)
      (setq LaTeX-default-environment new-env))
    (let ((entry (assoc new-env (LaTeX-environment-list))))
      (when (null entry)
        (LaTeX-add-environments (list new-env))))
    new-env))

(defun latex-change-env--prompt-macro (&optional new-macro)
  "Prompt for a macro and return the result.
Optional argument NEW-MACRO means use that macro.  Code mostly
taken from `TeX-insert-macro'."
  (let ((selection (or new-macro (completing-read
                                  (concat "Macro (default " TeX-default-macro "): " TeX-esc)
                                  (TeX--symbol-completion-table) nil nil nil
                                  'TeX-macro-history TeX-default-macro))))
    (when (called-interactively-p 'any)
      (setq TeX-default-macro selection))
    selection))

;;;; Finding environments

(defun latex-change-env--find-matching-begin ()
  "Find the beginning of the current environment.
Like `LaTeX-find-matching-begin', but take care of corner cases
like being at the very beginning/end of the current environment."
  (latex-change-env--find-match #'LaTeX-find-matching-begin))

(defun latex-change-env--find-matching-end ()
  "Find the end of the current environment.
Like `LaTeX-find-matching-end', but take care of corner cases
like being at the very beginning/end of the current environment."
  (latex-change-env--find-match #'LaTeX-find-matching-end))

(defun latex-change-env--find-match (find-match)
  "Find match according to FIND-MATCH.
See `latex-change-env--find-matching-begin' and
`latex-change-env--find-matching-end' for documentation."
  (let ((boi (save-excursion (LaTeX-back-to-indentation) (point))))
    (cond ((equal (point) boi) (forward-char))
          ((pos-eol)           (backward-char)))
    (funcall find-match)))

(defun latex-change-env--closest-env ()
  "Find the starting position of the closest environment.
Returns a list of the form (TYPE ENV BEG), where

  - TYPE is one of :inline-math, :display-math, :macro, or :env.

  - ENV is the starting delimiter of the inline/display maths, or
    the name of the relevant macro/environment.

  - BEG is the respective starting position."
  (cl-flet ((find-closest (xs)
              (car (seq-reduce (lambda (acc it)
                                 (if (car it)
                                     (if (>= (cadr acc) (cadr it)) acc it)
                                   acc))
                               xs
                               (list :nothing (point-min))))))
    (save-excursion
      (pcase-let* (;; Maths
                   (`(,math-sym . ,math-beg) (and (texmathp) texmathp-why))
                   ;; Macros
                   (`(,mac-name ,mac-or-env) (ignore-errors (LaTeX-what-macro)))
                   (mac-kw (when (eq 'mac mac-or-env) :macro))
                   (mac-beg (when mac-name (save-excursion (1- (search-backward mac-name)))))
                   ;; Envs
                   (env-beg (ignore-errors (save-excursion
                                             (latex-change-env--find-matching-begin)
                                             (point)))))
        (pcase (find-closest `((,mac-kw ,mac-beg) (,math-sym ,math-beg) (:env ,env-beg)))
          (:nothing
           (error "latex-change-env--closest-env: Not in any environment"))
          ((pred (equal (car latex-change-env-math-display)))
           `(:display-math ,(car latex-change-env-math-display) ,math-beg))
          ((pred (equal (car latex-change-env-math-inline)))
           `(:inline-math ,(car latex-change-env-math-inline) ,math-beg))
          (:macro
           `(:macro ,mac-name ,(1- (search-backward mac-name))))
          (:env
           (let ((env-name (progn (goto-char env-beg)
                                  (search-forward "{" (pos-eol))
                                  (current-word))))
             (if (equal env-name "document")
                 (error "Not touching `document' environment; aborting")
               `(:env ,env-name ,env-beg))))
          (_      ; maths env
           ;; XXX: Should we differentiate between maths envs and
           ;;      "normal" ones?
           `(:env ,math-sym ,env-beg)))))))

;;;; Labels

(defun latex-change-env--env->hash ()
  "Get the hash of the contents in the current environment.
Before hashing, strip all non essential characters (i.e., all
whitespace) from the string."
  (cl-flet* ((get-env (goto-beg goto-end)
               (funcall goto-beg)
               (push-mark)
               (funcall goto-end)
               (replace-regexp-in-string
                "[ \t\n\r]+"
                ""
                (buffer-substring-no-properties (mark) (point)))))
    (save-mark-and-excursion
      (pcase-let ((`(,env-type ,env-name ,beg) (latex-change-env--closest-env))
                  (`(,open . ,close) latex-change-env-math-display))
        (sxhash
         (pcase env-type
           ((or :inline-math :macro)
            (error (format "latex-change-env--env->hash: Encountered %s" env-name)))
           (:display-math
            (get-env (lambda ()
                       (goto-char beg)
                       (forward-char (length open)))
                     (lambda ()
                       (search-forward close)
                       ;; Assumption: the closing delimiter is the same
                       ;; length as the opening one
                       (backward-char (length close)))))
           (:env
            (get-env (lambda ()
                       (latex-change-env--find-matching-begin)
                       (forward-line))
                     (lambda ()
                       (latex-change-env--find-matching-end)
                       (forward-line -1)
                       (end-of-line))))))))))

(defun latex-change-env--change-label (old-env &optional new-env)
  "Change the label for OLD-ENV to the one for NEW-ENV.
If NEW-ENV is not given, delete (and save) the label instead."
  (let* ((old-lbl (latex-change-env--get-labels old-env))
         (new-lbl (latex-change-env--get-labels new-env)))
    (cl-flet* ((goto-label? ()
                 (search-forward "\\label{"
                                 (save-excursion (forward-line) (pos-eol))
                                 t))
               (get-label-text ()
                 (save-excursion
                   (forward-char (length old-lbl))
                   (push-mark)
                   (search-forward "}")
                   (backward-char)
                   (buffer-substring-no-properties (mark) (point))))
               (replace-label (old new)
                 (when latex-change-env-edit-labels-in-project
                   (ignore-errors       ; stop beeping!
                     (project-query-replace-regexp old new)))))
      (cond
       ((goto-label?)
        (let ((label (get-label-text)))
          (if (and old-lbl new-lbl)
              ;; Replace old label with new one.
              (progn
                (delete-char (length old-lbl))
                (insert new-lbl)
                (replace-label (concat old-lbl label) (concat new-lbl label)))
            ;; Only the old label exists: delete and save it.
            (let ((val (get-label-text)))
              (delete-region (- (point) (length "\\label{")) (pos-eol))
              (puthash (latex-change-env--env->hash)
                       val
                       latex-change-env--deleted-labels)
              (replace-label (concat "[~]\\\\\\(eqref\\|ref\\){" old-lbl label "}") "")))))
       (new-lbl
        ;; No label found -> check if we can restore something.
        (let ((label (gethash (latex-change-env--env->hash)
                              latex-change-env--deleted-labels)))
          (when (and new-lbl label)
            (latex-change-env--find-matching-begin)
            (end-of-line)
            (while (looking-back "\s" (pos-bol)) (delete-char -1))
            (insert " \\label{" new-lbl label "}"))))))))

;;;; Changing the actual environment

(defun latex-change-env--to-display-math ()
  "Transform an environment to display maths."
  (save-mark-and-excursion
    (pcase-let ((`(,env-type ,env-name ,beg) (latex-change-env--closest-env)))
      (pcase env-type
        (:macro (error "Not changing from macro to display maths, aborting"))
        (_ (latex-change-env--change (car latex-change-env-math-display)
                                     (cdr latex-change-env-math-display))
           (goto-char beg)
           (latex-change-env--change-label env-name))))))

(defun latex-change-env--change (&optional beg end)
  "Change an environment.
Delete the old one, and possibly insert new beginning and end
delimiters, as indicated by the optional arguments BEG and END."
  (cl-flet* ((delete-env (find-end open-end close-beg)
               ;; delete beginning, possibly insert a new one
               (if (not beg)       ; do we want to just kill everything?
                   (latex-change-env--delete-line)
                 (delete-region (point) (funcall open-end))
                 (insert beg))
               ;; delete end, possibly insert a new one
               (funcall find-end)
               (if (not end)       ; do we want to just kill everything?
                   (latex-change-env--delete-line)
                 (delete-region (funcall close-beg) (point))
                 (insert end))))
    (push-mark)
    (pcase-let ((`(,env-type ,env-name ,env-beg) (latex-change-env--closest-env))
                (`(,open . ,close) latex-change-env-math-display))
      (goto-char env-beg)
      (pcase env-type
        (:inline-math
         (delete-char (length env-name))
         (when beg (TeX-newline) (insert beg) (TeX-newline))
         (search-forward (cdr latex-change-env-math-inline))
         (delete-char (- (length env-name)))
         (when end (TeX-newline) (insert end) (TeX-newline)))
        (:display-math
         (delete-env (lambda () (search-forward close))
                     (lambda () (+ (point) (length open)))
                     (lambda () (- (point) (length close)))))
        (:macro
         (delete-region (point) (save-excursion (search-forward "{") (point)))
         (when beg (insert beg "{"))
         (search-forward "}")
         (unless end (delete-char -1)))
        (:env
         (delete-env #'latex-change-env--find-matching-end
                     (lambda () (save-excursion (search-forward "}") (point)))
                     (lambda () (save-excursion (back-to-indentation) (point)))))))
    (indent-region (mark) (point))))

(defun latex-change-env--modify (&optional new-env)
  "Modify a LaTeX environment.
The optional argument NEW-ENV specifies an environment directly."
  (pcase-let ((`(,old-env-type ,old-env-name ,old-beg) (latex-change-env--closest-env))
              (old-pt (point)))
    (save-mark-and-excursion
      (pcase old-env-type
        ((or :inline-math :display-math)
         (let ((env (latex-change-env--prompt-env new-env)))
           (latex-change-env--change
            (concat "\\begin{" env "}")
            (concat "\\end{" env "}"))
           (goto-char old-beg)
           (latex-change-env--change-label old-env-name env)))
        (:macro
         (let ((env (latex-change-env--prompt-macro new-env)))
           (latex-change-env--change (concat "\\" env) t)
           (goto-char old-pt)))
        (:env
         (let ((env (latex-change-env--prompt-env new-env)))
           (LaTeX-modify-environment env)
           (goto-char old-beg)
           (latex-change-env--change-label old-env-name env)))))))

;;;; User facing

;;;###autoload
(defun latex-change-env ()
  "Change a LaTeX environment.
When inside an environment or display maths, execute an action as
specified by `latex-change-env-options'."
  (interactive)
  (when-let* ((key (read-key (latex-change-env--prompt)))
              (fn (cadr (alist-get key latex-change-env-options))))
    (funcall fn)))

;;;###autoload
(defun latex-change-env-cycle (envs)
  "Cycle through environments.
ENVS is a list of environments to cycle through.  The special
symbol `display-math' denotes a display maths environment.

This function heavily depends on the `math-delimiters'
package[1].  If one is right at the end of a display or inline
maths environment, call `math-delimiters-insert' instead of
cycling through environments.  The same is done when not inside
any environment, which, for our definition of environment, also
includes inline maths.  As such, we only use
`math-delimiters-{inline,display}' for figuring out your
preferences, ignoring `latex-change-env-math-display'!.

[1]: https://github.com/oantolin/math-delimiters"
  (interactive)

  (require 'math-delimiters)
  (defvar math-delimiters-display)
  (defvar math-delimiters-inline)

  (setf envs (append envs (list (car envs))))
  (pcase-let* ((`(,env ,env-name _) (or (ignore-errors (save-excursion
                                                         (latex-change-env--closest-env)))
                                        `(:texmathp ,@(and (texmathp) texmathp-why))))
               (env-sym (pcase env
                          ((or :display-math :inline-math) (intern (substring (symbol-name env) 1)))
                          ((or 'nil :texmathp) nil)
                          (_ (intern env-name))))
               (`(,dopen . ,dclose) math-delimiters-display)
               (`(,iopen . _) math-delimiters-inline))
    (cl-flet ((change-real-env ()
                (let ((new-env (cadr (memq env-sym envs))))
                  (pcase new-env
                    ('display-math (latex-change-env--to-display-math))
                    (_             (latex-change-env--modify (symbol-name new-env)))))))
      (cond
       ((or (not env)                   ; not in a maths env
            (equal env iopen))          ; in inline maths
        (math-delimiters-insert))
       ((equal env dopen)               ; in display maths
        (if (looking-back (regexp-quote dclose) (- (point) (length dclose)))
            (math-delimiters-insert)
          (change-real-env)))
       ((and env (not (memq env-sym envs)))
        (math-delimiters-insert))
       (t
        (change-real-env))))))

(provide 'latex-change-env)
;;; latex-change-env.el ends here
