;;; cyphejor.el --- Shorten major mode names using user-defined rules -*- lexical-binding: t; -*-
;;
;; Copyright © 2015–present Mark Karpov <markkarpov92@gmail.com>
;;
;; Author: Mark Karpov <markkarpov92@gmail.com>
;; URL: https://github.com/mrkkrp/cyphejor
;; Package-Version: 20210816.1607
;; Package-Commit: 576d237a46be79449a22e3a7912a3464d7b0c233
;; Version: 0.1.2
;; Package-Requires: ((emacs "24.4"))
;; Keywords: mode-line major-mode
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package shortens major mode names by using a set of user-defined rules.

;;; Code:

(require 'cl-lib)
(require 'subr-x)

(defgroup cyphejor nil
  "Shorten major mode names using user-defined rules"
  :group  'convenience
  :tag    "Cyphejor"
  :prefix "cyphejor-"
  :link   '(url-link :tag "GitHub" "https://github.com/mrkkrp/cyphejor"))

(defcustom cyphejor-rules nil
  "Rules used to convert names of major modes.

Every element of the list must be of the following form:

  (STRING REPLACEMENT &rest PARAMETERS)

where STRING is a word in the major mode's symbol name,
REPLACEMENT is a string to be used instead of that word,
PARAMETERS is a list that may contain the following keywords:

  :prefix—put it at the beginning of result string
  :postfix—put it at the end of result string

The following keywords influence the algorithm in general:

  :downcase—replace words that are not matched explicitly with
  their first letter downcased

  :upcase—replace words that are not matched explicitly with
  their first letter upcased

  :capitalize—replace words that are not matched explicitly with
  the same words but capitalizing their first letters.

If nothing is specified, a word will be used unchanged, separated
from other words with spaces if necessary."
  :tag  "Active rules"
  :type '(repeat
          (choice
           (const :tag "use first downcased letter"  :downcase)
           (const :tag "use first upcased letter"    :upcase)
           (const :tag "capitalize the first letter" :capitalize)
           (list string string)
           (list string string
                 (choice (const :tag "put it in the beginning" :prefix)
                         (const :tag "put it in the end"       :postfix))))))

(defun cyphejor--cypher (old-name rules)
  "Convert the OLD-NAME into its shorter form following RULES.

The format of RULES is described in the doc-string of
`cyphejor-rules'.

OLD-NAME must be a string where words are separated with
punctuation characters."
  (let ((words      (split-string (downcase old-name) "[\b\\-]+" t))
        (downcase   (cl-find :downcase   rules))
        (upcase     (cl-find :upcase     rules))
        (capitalize (cl-find :capitalize rules))
        prefix-words
        postfix-words
        conversion-table
        prefix-result
        result
        postfix-result)
    (dolist (rule (cl-remove-if-not #'listp rules))
      (let ((before (car      rule))
            (after  (cadr     rule))
            (where  (cl-caddr rule)))
        (push (cons before after) conversion-table)
        (cl-case where
          (:prefix  (push before prefix-words))
          (:postfix (push before postfix-words)))))
    (dolist (word words)
      (let ((translated
             (or (cdr (assoc word conversion-table))
                 (cond (downcase   (cl-subseq word 0 1))
                       (upcase     (upcase (cl-subseq word 0 1)))
                       (capitalize (capitalize word))
                       (t          (format " %s " word))))))
        (cond ((member word prefix-words)
               (push translated prefix-result))
              ((member word postfix-words)
               (push translated postfix-result))
              (t
               (push translated result)))))
    (string-trim
     (apply #'concat
            (mapcar (lambda (x) (apply #'concat (reverse x)))
                    (list prefix-result
                          result
                          postfix-result))))))

(defun cyphejor--hook ()
  "Set `mode-name' according to the symbol name in `major-mode'.

This uses `cyphejor--cypher' and `cyphejor-rules' to generate new
mode name."
  (setq mode-name
        (cyphejor--cypher
         (symbol-name major-mode)
         cyphejor-rules)))

(defun cyphejor--fundamental-mode-advice (buffer &optional _inhibit-buffer-hooks)
  "Set `mode-name' of BUFFER according to the symbol name in `major-mode'.

Only do so when the buffer is in fundamental mode.

INHIBIT-BUFFER-HOOKS is accepted for compatibility reasons and
has no effect."
  (with-current-buffer buffer
    (when (eq major-mode 'fundamental-mode)
      (save-match-data
        (cyphejor--hook)))))

;;;###autoload
(define-minor-mode cyphejor-mode
  "Toggle the `cyphejor-mode' minor mode.

With a prefix argument ARG, enable `cyphejor-mode' if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
the mode if ARG is omitted or NIL, and toggle it if ARG is
`toggle'.

This global minor mode shortens names of major modes by using a
set of user-defined rules in `cyphejor-rules'.  See the
description of the variable for more information."
  nil "" nil
  :global t
  (funcall (if cyphejor-mode #'add-hook #'remove-hook)
           'after-change-major-mode-hook
           #'cyphejor--hook)
  (if cyphejor-mode
      (progn
        (advice-add 'wdired-change-to-dired-mode :after #'cyphejor--hook)
        (advice-add 'get-buffer-create :after #'cyphejor--fundamental-mode-advice))
    (advice-remove 'wdired-change-to-dired-mode #'cyphejor--hook)
    (advice-remove 'get-buffer-create #'cyphejor--fundamental-mode-advice))
  (when cyphejor-mode
    (mapc (lambda (buffer)
            (with-current-buffer buffer
              (cyphejor--hook)))
          (buffer-list))))

(provide 'cyphejor)

;;; cyphejor.el ends here
