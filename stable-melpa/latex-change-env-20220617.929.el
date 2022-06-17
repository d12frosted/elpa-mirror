;;; latex-change-env.el --- Change in and out of LaTeX environments -*- lexical-binding: t; -*-

;; Copyright (C) 2021, 2022  Tony Zorman
;;
;; Author: Tony Zorman <soliditsallgood@mailbox.org>
;; Keywords: convenience, tex
;; Package-Version: 20220617.929
;; Package-Commit: d2b0a2d1830ccddf2c687752e66b2f3048553ca0
;; Version: 0.2
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

;; This package provides a way to modify LaTeX environments, as well as
;; the display math mode (seeing it as an environment of sorts).  Thus,
;; henceforth the world "environment" shall—in addition to
;; \begin--\end-style environments—also refer to display math.
;;
;; Refer to the README for a full account of the package's
;; functionality, as well as how to install it.  Briefly:
;;
;; + The entry point is the `latex-change-env' function, which—when
;;   invoked from inside an environments—pops up a list of possible
;;   actions, as defined by the `latex-change-env-options' variable.
;;   There is also the option to cycle through arguments in
;;   `latex-change-env-cycle', which depends on the `math-delimiters'
;;   package.
;;
;; + Labels are changed/deleted in a previous way, with an option to
;;   edit the respective label across the whole project; see below.
;;   Also, deleted labels are stored for the current session (based on
;;   the specific contents of the environment) and potentially restored
;;   when switching from e.g. display math to an environment with an
;;   associated label prefix in `latex-change-env-labels'.
;;
;; + What exactly we mean by "display math" is controlled by the
;;   `latex-change-env-math-display' variable.
;;
;; + This package depends on AUCTeX—but you are already using that
;;   anyways.
;;
;; + If you're customizing `latex-change-env-edit-labels-in-project', we
;;   also depend on project.el, meaning Emacs 27.1 and up.

;;; Code:

(eval-when-compile (require 'cl-lib))
(require 'latex)

(defgroup latex-change-env nil
  "Change in and out of LaTeX environments."
  :group 'tex)

(defcustom latex-change-env-options
  '((?k "Delete"       latex-change-env--change         )
    (?d "Display Math" latex-change-env--to-display-math)
    (?m "Modify"       latex-change-env--modify         ))
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

(defcustom latex-change-env-math-display '("\\[" . "\\]")
  "Set the preferred style for display math."
  :group 'latex-change-env
  :type '(choice (const :tag "Brackets" ("\\[" . "\\]"))
                 (const :tag "Dollars"  ("$$"  . "$$"))))

(defcustom latex-change-env-labels '(("remark"     . "rem:")
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
          ((point-at-eol)      (backward-char)))
    (funcall find-match)))

(defun latex-change-env--closest-env ()
  "Find the starting position of the closest environment.
Returns a cons cell of the form (:math . BEG) or (ENV . BEG),
:math is a keyword indicating math-mode, BEG is the starting
position of the environment, and ENV is the name of a non display
math environment."
  (pcase-let* ((`(,math-sym . ,math-beg) (and (texmathp) texmathp-why))
               (in-display (equal math-sym (car latex-change-env-math-display)))
               (env-beg (ignore-errors (save-excursion
                                         (latex-change-env--find-matching-begin)
                                         (point)))))
    (cond
     ;; Possibly fancy math environment.
     ((and math-beg env-beg)
      (if (>= env-beg math-beg)         ; prefer inner
          (cons math-sym env-beg)
        (unless in-display
          (error "Not in a display math environment"))
        (cons :math math-beg)))
     ;; Other non-math environment.
     (env-beg (goto-char env-beg)
              (search-forward "{" (point-at-eol))
              (cons (current-word) env-beg))
     ;; Display math.
     (math-beg (unless in-display
                 (error "Not in a display math environment"))
               (cons :math math-beg))
     (t (error "Not in any environment")))))

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
      (pcase-let ((`(,env . ,beg) (latex-change-env--closest-env))
                  (`(,open . ,close) latex-change-env-math-display))
        (sxhash
         (if (equal env :math)
             ;; Display math
             (get-env (lambda ()
                        (goto-char beg)
                        (forward-char (length open)))
                      (lambda ()
                        (search-forward close)
                        (backward-char (length close))))
           ;; Proper environment
           (get-env (lambda ()
                      (latex-change-env--find-matching-begin)
                      (forward-line))
                    (lambda ()
                      (latex-change-env--find-matching-end)
                      (forward-line -1)
                      (end-of-line)))))))))

(defun latex-change-env--change-label (old-env &optional new-env)
  "Change the label for OLD-ENV to the one for NEW-ENV.
If NEW-ENV is not given, delete (and save) the label instead."
  (let* ((old-lbl (latex-change-env--get-labels old-env))
         (new-lbl (latex-change-env--get-labels new-env)))
    (cl-flet* ((goto-label? ()
                 (search-forward "\\label{"
                                 (save-excursion (forward-line) (point-at-eol))
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
              (delete-region (- (point) (length "\\label{")) (point-at-eol))
              (puthash (latex-change-env--env->hash)
                       val
                       latex-change-env--deleted-labels)
              (replace-label (concat "\\\\ref{" old-lbl label "}") "")))))
       (new-lbl
        ;; No label found -> check if we can restore something.
        (let ((label (gethash (latex-change-env--env->hash)
                              latex-change-env--deleted-labels)))
          (when (and new-lbl label)
            (latex-change-env--find-matching-begin)
            (end-of-line)
            (insert " \\label{" new-lbl label "}"))))))))

;;;; Changing the actual environment

(defun latex-change-env--to-display-math ()
  "Transform an environment to display math."
  (save-mark-and-excursion
    (pcase-let ((`(,env . ,beg) (latex-change-env--closest-env)))
      (latex-change-env--change (car latex-change-env-math-display)
                                (cdr latex-change-env-math-display))
      (goto-char beg)
      (latex-change-env--change-label env))))

(defun latex-change-env--change (&optional beg end)
  "Change an environment.
Delete the old one, and possibly insert new beginning and end
delimiters, as indicated by the optional arguments BEG and END."
  (cl-flet* ((delete-env (env-begin find-end open-end close-beg)
               ;; delete beginning, possibly insert a new one
               (goto-char env-begin)
               (if (not beg)            ; do we want to just kill everything?
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
    (pcase-let ((`(,env . ,beg) (latex-change-env--closest-env))
                (`(,open . ,close) latex-change-env-math-display))
      (if (equal env :math)             ; display math
          (delete-env beg
                      (lambda () (search-forward close))
                      (lambda () (+ (point) (length open)))
                      (lambda () (- (point) (length close))))
        (delete-env beg
                    #'latex-change-env--find-matching-end
                    (lambda () (save-excursion (search-forward "}") (point)))
                    (lambda () (save-excursion (back-to-indentation) (point))))))
    (indent-region (mark) (point))))

(defun latex-change-env--modify (&optional new-env)
  "Modify a LaTeX environment.
Most of the implementation stolen from `LaTeX-environment', just
also act on display math environments.

The optional argument NEW-ENV specifies an environment directly."
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
    (pcase-let ((entry (assoc new-env (LaTeX-environment-list)))
                (`(,old-env . ,old-beg) (latex-change-env--closest-env)))
      (when (null entry)
        (LaTeX-add-environments (list new-env)))
      (save-mark-and-excursion
        (if (equal old-env :math)       ; in a display math environment
            (latex-change-env--change (concat "\\begin{" new-env "}")
                                      (concat "\\end{" new-env "}"))
          (LaTeX-modify-environment new-env))
        (goto-char old-beg)
        (latex-change-env--change-label old-env new-env)))))

;;;; User facing

;;;###autoload
(defun latex-change-env ()
  "Change a LaTeX environment.
When inside an environment or display math, execute an action as
specified by `latex-change-env-options'."
  (interactive)
  (let ((key (read-key (latex-change-env--prompt))))
    (funcall (cadr (alist-get key latex-change-env-options)))))

;;;###autoload
(defun latex-change-env-cycle (envs)
  "Cycle through environments.
ENVS is a list of environments to cycle through.  The special
symbol `math' denotes a display math environment.

This function heavily depends on the `math-delimiters'
package[1].  If one is right at the end of a display or inline
math environment, call `math-delimiters-insert' instead of
cycling through environments.  The same is done when not inside
any environment, which, for our definition of environment, also
includes inline math.  As such, we only use
`math-delimiters-{inline,display}' for figuring out your
preferences, ignoring `latex-change-env-math-display'!.

[1]: https://github.com/oantolin/math-delimiters"
  (interactive)

  (require 'math-delimiters)
  (defvar math-delimiters-display)
  (defvar math-delimiters-inline)

  (setf envs (append envs (list (car envs))))
  (pcase-let* ((env (car (or (ignore-errors (save-excursion
                                              (latex-change-env--closest-env)))
                             (and (texmathp) texmathp-why))))
               (env-sym (intern (if (keywordp env)
                                    (substring (symbol-name env) 1)
                                  env)))
               (`(,dopen . ,dclose) math-delimiters-display)
               (`(,iopen . _) math-delimiters-inline))
    (cl-flet ((change-real-env ()
                (let ((new-env (cadr (memq env-sym envs))))
                  (pcase new-env
                    ('math (latex-change-env--to-display-math))
                    (_     (latex-change-env--modify (symbol-name new-env)))))))
      (cond
       ((or (not env)                   ; not in a math env
            (equal env iopen))          ; in inline math
        (math-delimiters-insert))
       ((equal env dopen)               ; in display math
        (if (looking-back (regexp-quote dclose) (- (point) (length dclose)))
            (math-delimiters-insert)
          (change-real-env)))
       ((and env (not (memq env-sym envs)))
        (math-delimiters-insert))
       (t
        (change-real-env))))))

(provide 'latex-change-env)
;;; latex-change-env.el ends here
