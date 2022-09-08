;;; pyimport.el --- Manage Python imports!

;; Copyright (C) 2016 Wilfred Hughes <me@wilfred.me.uk>
;;
;; Author: Wilfred Hughes <me@wilfred.me.uk>
;; Created: 25 Jun 2016
;; Version: 1.1
;; Package-Version: 20220908.1610
;; Package-Commit: c006a5fd0e5c9e297aa2ad71b2f02f463286b5e3
;; Package-Requires: ((dash "2.8.0") (s "1.9.0") (shut-up "0.3.2"))
;;; Commentary:

;; This package can remove unused Python imports, or insert missing
;; Python imports.

;;; License:

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(require 'rx)
(require 's)
(require 'dash)
(require 'shut-up)

(defun pyimport--current-line ()
  "Return the whole line at point, excluding the trailing newline."
  (buffer-substring-no-properties (line-beginning-position) (line-end-position)))

(defun pyimport--last-line-p ()
  "Return non-nil if the current line is the last in the buffer."
  (looking-at (rx (0+ not-newline) buffer-end)))

(defun pyimport--in-string-p ()
  "Return non-nil if point is inside a string."
  (nth 3 (syntax-ppss)))

(defun pyimport--buffer-lines (buffer)
  "Return all the lines in BUFFER, ignoring lines that are within a string."
  (let (lines)
    (with-current-buffer buffer
      (save-excursion
        (goto-char (point-min))
        (while (not (eobp))
          (unless (pyimport--in-string-p)
            (push (pyimport--current-line) lines))
          (forward-line 1))))
    (nreverse lines)))

(defun pyimport--import-lines (buffer)
  "Return all the lines in this Python BUFFER that look like imports."
  (->> (pyimport--buffer-lines buffer)
       (--filter (string-match (rx (or (seq bol "from ")
                                       (seq bol "import "))) it))
       (--map (propertize it 'pyimport-path (buffer-name buffer)))))

(defmacro pyimport--for-each-line (&rest body)
  "Execute BODY for every line in the current buffer.
To terminate the loop early, throw 'break."
  (declare (indent 0))
  `(save-excursion
     (catch 'break
       (goto-char (point-min))
       (while (not (pyimport--last-line-p))
         ,@body
         (forward-line))
       ,@body)))

(defun pyimport--same-module (import1 import2)
  "Return t if both lines of Python imports are from the same module."
  (-let (((keyword1 mod1 ...) (s-split " " import1))
         ((keyword2 mod2 ...) (s-split " " import2)))
    (and (string= keyword1 "from")
         (string= keyword2 "from")
         (string= mod1 mod2))))

(defun pyimport--insert-from-symbol (symbol)
  "When point is a on an import line, add SYMBOL."
  ;; Assumes the current line is of the form 'from foo import bar, baz'.

  ;; Step past the 'from '.
  (goto-char (line-beginning-position))
  (while (not (looking-at "import "))
    (forward-char 1))
  (forward-char (length "import "))

  (insert
   (->> (delete-and-extract-region (point) (line-end-position))
        (s-split ", ")
        (cons symbol)
        (-sort #'string<)
        (-uniq)
        (s-join ", "))))

(defun pyimport--insert-import (line)
  "Insert LINE, a python import statement, in the current buffer."
  (let* ((current-lines (pyimport--import-lines (current-buffer)))
         (same-pkg-lines (--filter (pyimport--same-module it line) current-lines)))
    (if same-pkg-lines
        ;; Find the first matching line, and append there
        (pyimport--for-each-line
          (when (pyimport--same-module (pyimport--current-line) line)
            (-let [(_ _module _ name) (s-split " " line)]
              (pyimport--insert-from-symbol name))
            ;; Break from this loop.
            (throw 'break nil)))

      ;; We don't have any imports for this module yet, so just insert
      ;; LINE as-is.
      (save-excursion
        (goto-char (point-min))
        (let ((insert-pos (point)))
          (catch 'found
            ;; Find the first non-comment non-blank line.
            (dotimes (_ 30)
              (forward-line 1)
              (let* ((ppss (syntax-ppss))
                     ;; Since point is at the start of the line, we
                     ;; are outside single line comments or
                     ;; strings. However, we might be in a multiline
                     ;; comment.
                     (string-comment-p (nth 8 ppss)))
                (when (and (not (looking-at "\n"))
                           (not (looking-at "#"))
                           (not (looking-at "\""))
                           (not string-comment-p))
                  (setq insert-pos (point))
                  (throw 'found nil)))))
          (insert line "\n"))))))

(defun pyimport--get-alias (import-as symbol)
  "Return the original symbol name, the aliased name, or nil, if
SYMBOL is in IMPORT-AS."
  (let ((parts (s-split " as " import-as)))
    (cond
     ((equal (nth 0 parts) symbol) symbol)
     ((equal (nth 1 parts) symbol) import-as))))

(defun pyimport--extract-simple-import (line symbol)
  "Given LINE 'from foo import x, y as z', if SYMBOL is 'z',
return 'from foo import y as z'."
  (let ((parts (s-split " " (s-collapse-whitespace line))))
    (cond
     ((s-starts-with-p "from " line)
      (let* ((raw-aliases (nth 1 (s-split " import " line)))
             (aliases (s-split "," raw-aliases))
             (matching-aliases (--map (pyimport--get-alias (s-trim it) symbol) aliases)))
        (setq matching-aliases (-non-nil matching-aliases))
        (when matching-aliases
          (format "from %s import %s"
                  (nth 1 parts)
                  (nth 0 matching-aliases)))))
     ((s-starts-with-p "import " line)
      (let* ((raw-aliases (nth 1 (s-split "import " line)))
             (aliases (s-split "," raw-aliases))
             (matching-aliases (--map (pyimport--get-alias (s-trim it) symbol) aliases)))
        (setq matching-aliases (-non-nil matching-aliases))
        (when matching-aliases
          (format "import %s" (nth 0 matching-aliases))))))))

(defun pyimport--buffers-in-mode (mode)
  "Return a list of all the buffers with major mode MODE."
  (--filter (with-current-buffer it
              (eq major-mode mode))
            (buffer-list)))

(defun pyimport--syntax-highlight (str)
  "Apply font-lock properties to a string STR of Python code."
  (with-temp-buffer
    (insert str)
    (delay-mode-hooks (python-mode))
    (if (fboundp 'font-lock-ensure)
        (font-lock-ensure)
      (with-no-warnings
        (font-lock-fontify-buffer)))
    (buffer-string)))

;;;###autoload
(defun pyimport-insert-missing (prefix)
  "Try to insert an import for the symbol at point.
If called with a prefix, choose which import to use.

This is a simple heuristic: we just look for imports in all open Python buffers."
  (interactive "P")
  (let ((symbol (thing-at-point 'symbol))
        (matching-lines nil)
        (case-fold-search nil))
    (unless symbol
      (user-error "No symbol at point"))
    (setq symbol (substring-no-properties symbol))
    ;; Find all the import lines in all Python buffers
    (dolist (buffer (pyimport--buffers-in-mode 'python-mode))
      (dolist (line (pyimport--import-lines buffer))
        (-if-let (import (pyimport--extract-simple-import line symbol))
            (push import matching-lines))))

    ;; Remove duplicates.
    (setq matching-lines (-uniq matching-lines))

    ;; Syntax highlight, to give a prettier choice in the minibuffer.
    (setq matching-lines
          (-map #'pyimport--syntax-highlight matching-lines))

    ;; Sort by string length, because the shortest string is usually best.
    (setq matching-lines
          (--sort (< (length it) (length other)) matching-lines))

    (if matching-lines
        (let ((line
               (if prefix
                   (completing-read "Choose import: " matching-lines)
                 (-first-item matching-lines))))
          (pyimport--insert-import line)
          (message "%s (from %s)" line (get-text-property 0 'pyimport-path line)))
      (user-error "No matches found for %s" symbol))))

(defun pyimport--extract-unused-var (flycheck-message)
  "Extract the import variable name from FLYCHECK-MESSAGE.
FLYCHECK-MESSAGE should take the form \"'foo' imported but unused\"."
  (->> flycheck-message
       (s-match "'\\(.*\\)' imported but unused")
       -last-item
       (s-split (rx "."))
       -last-item
       (s-split (rx " as "))
       -last-item))

(defun pyimport--remove-on-line (text)
  "Remove the first occurrence of TEXT on the current line, if present.
Returns t on success, nil otherwise."
  (save-excursion
    (move-beginning-of-line nil)
    (let ((next-line-pos (save-excursion (forward-line 1) (point))))
      ;; Search forward, until we find the text on this line.
      (when (search-forward text next-line-pos t)
        ;; If we found it, delete it.
        (delete-char (- (length text)))
        t))))

(defun pyimport--delete-current-line ()
  (save-excursion
    (let ((line-start (progn (move-beginning-of-line nil) (point)))
          (next-line-start (progn (forward-line 1) (point))))
      (delete-region line-start next-line-start))))

(defun pyimport--remove-import (line var)
  "Given a line of Python code of the form

from foo import bar, baz, biz

on line number LINE, remove VAR (e.g. 'baz')."
  (let ((case-fold-search nil))
    (save-excursion
      (goto-char (point-min))
      (forward-line (1- line))

      (cond
       ;; If it's just 'import foo' or 'import foo.bar', just remove it.
       ((looking-at (rx "import"
                        (+ space)
                        (+ (or (syntax word) (syntax symbol) (syntax punctuation)))
                        (0+ space)
                        (? "as" (+ space) (+ (or (syntax word) (syntax symbol))))
                        (0+ space)
                        line-end))
        (pyimport--delete-current-line))

       ;; Otherwise, it's '... import foo' or '... import foo as bar'
       (t
        ;; Remove the variable reference.
        (or (pyimport--remove-on-line (format ", %s" var))
            (pyimport--remove-on-line (format "%s, " var))
            (pyimport--remove-on-line var))
        ;; If we only have "from foo import " left, remove the rest of the line.
        (when (or (looking-at (rx "from" (+ space)
                                  (+ (or (syntax word) (syntax symbol) (syntax punctuation))) (+ space)
                                  "import" (1+ space)
                                  line-end))
                  (looking-at (rx "from " (1+ (not (any space))) " import " (1+ (not (any space))) " as" (1+ space) line-end))
                  (looking-at (rx "import " (1+ (not (any space))) " as" (1+ space) line-end)))
          (pyimport--delete-current-line)))))))

;; TODO: defcustom
(defvar pyimport-pyflakes-path
  (executable-find "pyflakes")
  "Path to pyflakes executable.
If pyflakes is alread on your $PATH, this should work with
modification.

Required for `pyimport-remove-unused'.")

;;;###autoload
(defun pyimport-remove-unused ()
  "Remove unused imports in the current Python buffer."
  (interactive)

  (unless pyimport-pyflakes-path
    (user-error "You need to install pyflakes or set pyimport-pyflakes-path"))

  (let (flycheck-output)
    (shut-up
      (shell-command-on-region
       (point-min) (point-max) pyimport-pyflakes-path "*pyimport*"))
    (with-current-buffer "*pyimport*"
      (setq flycheck-output (buffer-string)))
    (kill-buffer "*pyimport*")

    (let* ((raw-lines (s-split "\n" (s-trim flycheck-output)))
           (lines (--map (s-split-up-to ":" it 2) raw-lines))
           (import-lines (--filter (s-ends-with-p "imported but unused" (-last-item it)) lines))
           (unused-imports (--map (cons (read (nth 1 it))
                                        (pyimport--extract-unused-var (nth 2 it))) import-lines)))
      ;; Iterate starting from the last unused import, so our line
      ;; numbers stay correct, even when we delete lines.
      (--each (reverse unused-imports)
        (-let [(line . var ) it]
          (pyimport--remove-import line var))))))

(provide 'pyimport)
;;; pyimport.el ends here
