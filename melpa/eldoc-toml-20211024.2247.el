;;; eldoc-toml.el --- TOML table name at point for ElDoc -*- lexical-binding: t; -*-
;;
;; Author: Maor Kadosh <git@avocadosh.xyz>
;; URL: https://github.com/it-is-wednesday/eldoc-toml
;; Package-Version: 20211024.2247
;; Package-Commit: 60f1de70942e163034ef093c61f50f29820c3c04
;; Version: 0.1
;; Package-Requires: ((emacs "24.4"))
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Keywords: data
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;; An ElDoc function for displaying the parent table of the field at point in a TOML file, along the
;; key name. Makes it easier to navigate tables with many fields, where you might have the table’s
;; header or the key name off screen while still navigating its fields.
;;
;;; Code:

(require 'cl-lib)
(require 'subr-x)

(defun eldoc-toml--remove-comment (line)
  "Remove comment from end of LINE.
Also remove any space between the actual line's ending to the comment's beginning."
  (replace-regexp-in-string "\s*#.*" "" line))

(defun eldoc-toml--current-table-name ()
  "Find which table the current line is under.
For example, in this scenario, where X is the cursor:

[a]
X
[b]

returns [a].

Returns the table's name. If we aren't under any table (before the first table
of the file), returns nil."
  (save-excursion
    ;; Iterate from current line backwards until we hit a table line or until the first line
    (cl-loop with line do
             (setq line (thing-at-point 'line 'no-properties))

             ;; return line if it's a table header
             (when (string-match-p "^\s*\\[" line)
               ;; Trimming since TOML lines can begin with whitespace
               (cl-return (string-trim (eldoc-toml--remove-comment line))))

             ;; Return nil if we reached the beginning of the buffer without any matching line
             (when (<= (line-number-at-pos) 1)
               (cl-return nil))

             (forward-line -1))))

(defun eldoc-toml--current-key-name ()
  "Return the current key name.
Looks for a line that looks like xxx = yyy, and extracts xxx.
If no such line was found (meaning we're at the top of the doc), returns nil."
  (save-excursion
    ;; Iterate from current line backwards until we see key definition: xxx = ...
    (cl-loop with line do
             (setq line (thing-at-point 'line 'no-properties))

             ;; Return line if it's a decleration line
             (when (string-match-p ".+\s*=" line)
               ;; Remove everything in the matching line except the key name
               (cl-return (string-trim (replace-regexp-in-string "\s*=.*" "" line))))

             ;; Return nil if we reached the beginning of the buffer without any matching line
             (when (<= (line-number-at-pos) 1)
               (cl-return nil))

             ;; Return nil if we aren't inside a long string/array/inline table
             (when (eldoc-toml--toplevel-p)
               (cl-return nil))

             (forward-line -1))))

(defun eldoc-toml--toplevel-p ()
  "Check if we're surrounded by brackets, parens, quotes...
Merely checks if `backward-up-list' says we're at the top level or not.
Returns t if we're at the top level, returns nil if we're surrounded by something."
  (save-excursion
    (beginning-of-line)
    ;; Evaluates to t if cursor couldn't move out of one level of parentheses/quotes/xxx,
    ;; meaning it's at the file's top level. Evaluates to nil otherwise.
    (condition-case nil
        (progn (backward-up-list 1 t) nil)
      (scan-error t))))

(defun eldoc-toml--callback (callback &rest _more)
  "Document the table the value at point is in and pass it to CALLBACK.
Add this to `eldoc-documentation-functions'."
  (let* ((table (eldoc-toml--current-table-name))
         (key (eldoc-toml--current-key-name)))
    ;; make sure we got some table value, because some TOML documents begin with comments - in
    ;; which case we should just be quiet.
    (if table
        (funcall callback
                 ;; If key: [table].key
                 ;; otherwise: [table]
                 (concat table (if key (concat "." key)))))))

;;;###autoload
(defun eldoc-toml ()
  "Add the hook to `eldoc-documentation-functions'."
  (interactive)
  (add-hook 'eldoc-documentation-functions #'eldoc-toml--callback nil 'local))

(provide 'eldoc-toml)
;;; eldoc-toml.el ends here
