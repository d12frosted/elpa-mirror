;;; symbolist.el --- List and interactively unbind Emacs Lisp symbols -*- lexical-binding: t -*-

;; Copyright 2021 Lassi Kortela
;; SPDX-License-Identifier: ISC

;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-symbolist
;; Package-Version: 20210503.1220
;; Package-Commit: f600e07fe06c19b67f917a8839bbcd6c78f1fbd4
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.5"))
;; Keywords: lisp maint

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Shows a buffer with a table of all Emacs Lisp symbols present in
;; the currently running Emacs session matching the given prefix or
;; regexp.

;; Table columns F V P show whether or not each symbol has a function
;; binding, a variable binding, and a property list, respectively.

;; Press `d' to mark symbols for deletion (i.e. unbinding and
;; uninterning).  Press `x' to delete all marked symbols.

;;; Code:

(defvar-local symbolist-regexp nil
  "Regular expression for symbols listed in a Symbolist buffer.")

(defvar symbolist-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map "d" 'symbolist-mark-for-delete)
    (define-key map "u" 'symbolist-unmark)
    (define-key map "x" 'symbolist-execute)
    map)
  "Keymap for `symbolist-mode'.")

(defun symbolist--delete (symbol)
  "Internal function to unbind SYMBOL from this instance of Emacs."
  (makunbound symbol)
  (fmakunbound symbol)
  (unintern symbol nil))

(defun symbolist--refresh (&optional _buffer-list _old-buffer)
  "Internal function that helps refresh a Symbolist buffer."
  (setq-local tabulated-list-use-header-line t)
  (setq-local
   tabulated-list-entries
   (when symbolist-regexp
     (mapcar (lambda (symbol)
               (list symbol
                     (vector ""
                             (if (fboundp symbol)
                                 (if (commandp symbol) "I" "F")
                               "")
                             (if (boundp symbol) "V" "")
                             (if (symbol-plist symbol) "P" "")
                             (symbol-name symbol))))
             (apropos-internal symbolist-regexp))))
  (tabulated-list-init-header))

(define-derived-mode symbolist-mode tabulated-list-mode "Symbolist"
  "Major mode for Symbolist buffers.

The table columns give the following information about each symbol:

D -- marked for deletion
F -- has a function binding (I means an interactive function)
V -- has a variable binding
P -- has a property list with one or more properties"
  (setq-local tabulated-list-format
              [("D" 1 t)
               ("F" 1 t)
               ("V" 1 t)
               ("P" 1 t)
               ("Symbol" 50 t)])
  (add-hook 'tabulated-list-revert-hook
            'symbolist--refresh nil t))

(defun symbolist--set-mark (string)
  "Internal function to set the mark on the current line to STRING."
  (when (and (eq major-mode 'symbolist-mode)
             (tabulated-list-get-id)
             (tabulated-list-get-entry))
    (tabulated-list-set-col 0 string t)
    (forward-line 1)))

(defun symbolist-unmark ()
  "Unmark the symbol on this line."
  (interactive)
  (symbolist--set-mark ""))

(defun symbolist-mark-for-delete ()
  "Mark the symbol on this line for deletion.

A subsequent \\<symbolist-mode-map>`\\[symbolist-execute]' command
will delete it."
  (interactive)
  (symbolist--set-mark "D"))

(defun symbolist-execute ()
  "Delete all symbols marked for deletion in this buffer.

Symbols marked with \\<symbolist-mode-map>`\\[symbolist-mark-for-delete]' \
are deleted."
  (interactive)
  (let ((deleted-count 0))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (let* ((symbol (tabulated-list-get-id))
               (entry  (tabulated-list-get-entry))
               (delete (and entry (equal "D" (elt entry 0)))))
          (cond (delete
                 (symbolist--delete symbol)
                 (tabulated-list-delete-entry)
                 (setq deleted-count (1+ deleted-count)))
                (t
                 (forward-line))))))
    (cond ((< deleted-count 1)
           (message "No symbols marked for deletion"))
          ((= deleted-count 1)
           (message "Deleted 1 symbol"))
          (t
           (message "Deleted %d symbols" deleted-count)))))

(defun symbolist--make-buffer-name (regexp)
  "Internal function to make a buffer name based on REGEXP."
  (let ((query (if (string-match "^\\^" regexp)
                   (substring regexp 1)
                   regexp)))
    (concat "*Symbolist: " query "*")))

;;;###autoload
(defun symbolist-regexp (regexp)
  "Show a buffer listing all Emacs Lisp symbols that match REGEXP.

Symbol matching respects the value of `case-fold-search'."
  (interactive "sList symbols matching regexp: ")
  (let ((buffer-name (symbolist--make-buffer-name regexp)))
    (switch-to-buffer-other-window buffer-name)
    (symbolist-mode)
    (setq-local symbolist-regexp regexp)
    (revert-buffer)))

;;;###autoload
(defun symbolist-prefix (prefix)
  "Show a buffer listing all Emacs Lisp symbols that start with PREFIX.

Symbol matching respects the value of `case-fold-search'."
  (interactive "sList symbols that start with: ")
  (symbolist-regexp (concat "^" (regexp-quote prefix))))

(provide 'symbolist)

;;; symbolist.el ends here
