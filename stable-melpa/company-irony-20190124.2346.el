;;; company-irony.el --- company-mode completion back-end for irony-mode  -*- lexical-binding: t -*-

;; Copyright (C) 2014  Guillaume Papin

;; Author: Guillaume Papin <guillaume.papin@epitech.eu>
;; Keywords: convenience
;; Package-Version: 20190124.2346
;; Package-Commit: b44711dfce445610c1ffaec4951c6ff3882b216a
;; Version: 1.1.0
;; URL: https://github.com/Sarcasm/company-irony/
;; Package-Requires: ((emacs "24.1") (company "0.8.0") (irony "1.1.0") (cl-lib "0.5"))

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

;; Usage:
;;
;;     (eval-after-load 'company
;;       '(add-to-list 'company-backends 'company-irony))

;;; Code:

(require 'irony-completion)

(require 'company)
(require 'company-template)

(require 'cl-lib)

(defgroup company-irony nil
  "Company-mode completion back-end for Irony."
  :group 'company
  :group 'irony)

(defcustom company-irony-ignore-case nil
  "If t, ignore case when collecting completion candidates.
If this value is `smart', ignore case only when there is no
uppercase letters."
  :type '(choice (const :tag "off" nil)
		 (const smart)
		 (other :tag "on" t)))

(defsubst company-irony--irony-candidate (candidate)
  (get-text-property 0 'company-irony candidate))

(defun company-irony-prefix ()
  (pcase-let ((`(,symbol-start . ,symbol-end) (irony-completion-symbol-bounds)))
    (if (and symbol-end (> symbol-end (point)))
        'stop
      (when symbol-start
        (let ((prefix (buffer-substring-no-properties symbol-start (point))))
          (save-excursion
            (goto-char symbol-start)
            (if (irony-completion-at-trigger-point-p)
                (cons prefix t)
              prefix)))))))

(defun company-irony--make-candidates (candidates)
  (cl-loop for candidate in candidates
           collect (propertize (car candidate) 'company-irony candidate)))

(defun company-irony--get-matching-style ()
  (cl-case company-irony-ignore-case
    (smart 'smart-case)
    ((nil) 'exact)
    (t 'case-insensitive)))

(defun company-irony--candidates (prefix)
  (cons :async
        (lambda (callback)
          (irony-completion-candidates-async
           (lambda (candidates) ;; closure, lexically bound
             (funcall callback
                      (company-irony--make-candidates candidates)))
           prefix
           (company-irony--get-matching-style)))))

(defun company-irony--annotation (candidate)
  (concat
   (irony-completion-annotation candidate)
   (let ((type (irony-completion-type candidate)))
     (when (not (zerop (length type)))
       (concat " -> " type)))))

(defun company-irony--post-completion (candidate)
  ;; This check is necessary because Company triggers a 'post-completion even if
  ;; the candidate has just been typed without relying on the completion, but it
  ;; doesn't provide the full candidate information.
  (when candidate
    (let ((point-before-post-complete (point)))
      (if (irony-snippet-available-p)
          (irony-completion-post-complete candidate)
        (let ((str (irony-completion-post-comp-str candidate)))
          (insert str)
          (company-template-c-like-templatify str)))
      ;; Here we set this-command to a `self-insert-command' so that company may
      ;; retrigger idle completion after the snippet expansion
      ;; (~`company-post-command'). This is a bit of a hack and maybe that will
      ;; change in the future. This is useful for example when the completed
      ;; candidate is a namespace and the annotation text (inserted snippet) is
      ;; the scope operator.
      ;;
      ;; std| -> std::   (=> idle completion desired here)
      ;;         stderr
      ;;         ...
      ;;
      ;; See https://github.com/company-mode/company-mode/issues/143
      (unless (eq (point) point-before-post-complete)
        (setq this-command 'self-insert-command)))))

;;;###autoload
(defun company-irony (command &optional arg &rest ignored)
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-irony))
    (prefix (and irony-mode (company-irony-prefix)))
    (candidates (company-irony--candidates arg))
    (annotation (company-irony--annotation
                 (company-irony--irony-candidate arg)))
    (meta (irony-completion-brief
           (company-irony--irony-candidate arg)))
    (post-completion (company-irony--post-completion
                      (company-irony--irony-candidate arg)))
    (ignore-case (eq company-irony-ignore-case t))
    (no-cache (eq company-irony-ignore-case 'smart))
    (sorted t)))

;;;###autoload
(defun company-irony-setup-begin-commands ()
  "Include irony trigger commands to `company-begin-commands'.

This allow completion to be automatically triggered after member
accesses (obj.|, obj->|, ...).

This may be useful to company < `0.8.4', newer version of company
include these commands by default."
  (if (listp company-begin-commands)
      (set (make-local-variable 'company-begin-commands)
           (delete-dups
            (append company-begin-commands irony-completion-trigger-commands)))
    (display-warning 'company-irony
                     "`company-irony-setup-begin-commands' expects \
`company-begin-commands' to be a list!")))

(provide 'company-irony)
;;; company-irony.el ends here
