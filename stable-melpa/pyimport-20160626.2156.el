;;; pyimport.el --- Manage Python imports!

;; Copyright (C) 2016 Wilfred Hughes <me@wilfred.me.uk>
;;
;; Author: Wilfred Hughes <me@wilfred.me.uk>
;; Created: 25 Jun 2016
;; Version: 1.0
;; Package-Version: 20160626.2156
;; Package-Commit: 2c05712748f6b6624b15d524323f6391612683f4
;; Package-Requires: ((dash "2.8.0") (s "1.9.0"))
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

(defun pyimport--current-line ()
  "Return the whole line at point, excluding the trailing newline."
  (save-excursion
    (let ((line-start (progn (beginning-of-line) (point)))
          (line-end (progn (end-of-line) (point))))
      (buffer-substring line-start line-end))))

(defun pyimport--last-line-p ()
  "Return non-nil if the current line is the last in the buffer."
  (looking-at (rx (0+ not-newline) buffer-end)))

(defun pyimport--buffer-lines (buffer)
  (with-current-buffer buffer
    (s-split "\n" (buffer-string))))

(defun pyimport--import-lines (buffer)
  "Return all the lines in this Python BUFFER that look like imports."
  (->> (pyimport--buffer-lines buffer)
       (--filter (string-match (rx (or (seq bol "from ")
                                       (seq bol "import "))) it))
       (--map (propertize it 'pyimport-path (buffer-name)))))

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

(defun pyimport--insert-import (line)
  "Insert LINE, a python import statement, in the current buffer."
  (let* ((current-lines (pyimport--import-lines (current-buffer)))
         (same-pkg-lines (--filter (pyimport--same-module it line) current-lines)))
    (if same-pkg-lines
        ;; Find the first matching line, and append there
        (pyimport--for-each-line
          (when (pyimport--same-module (pyimport--current-line) line)
            (goto-char (point-at-eol))
            (-let [(_ _module _ name) (s-split " " line)]
              (insert ", " name))
            ;; Break from this loop.
            (throw 'break nil)))

      ;; We don't have any imports for this module yet, so just insert
      ;; LINE as-is.
      (save-excursion
        (goto-char (point-min))
        (insert line "\n")))))

(defun pyimport--import-simplify (line symbol)
  "Given LINE 'from foo import bar, baz', simplify it to 'from foo import baz', where
baz is SYMBOL."
  ;; TODO: simplify "from foo import bar, baz as biz" -> "from foo import baz as biz"
  (cond ((string-match "from .* import .* as .*" line)
         line)
        ((s-starts-with-p "from " line)
         (let ((parts (s-split " " line)))
           (format "from %s import %s" (nth 1 parts) symbol)))
        (t
         line)))

(defun pyimport--buffers-in-mode (mode)
  "Return a list of all the buffers with major mode MODE."
  (--filter (with-current-buffer it
              (eq major-mode mode))
            (buffer-list)))

;;;###autoload
(defun pyimport-insert-missing ()
  "Try to insert an import for the symbol at point.
Dumb: just scans open Python buffers."
  (interactive)
  (let ((symbol (substring-no-properties (thing-at-point 'symbol)))
        (matching-lines nil)
        (case-fold-search nil))
    ;; Find all the import lines in all Python buffers
    (dolist (buffer (pyimport--buffers-in-mode 'python-mode))
      (dolist (line (pyimport--import-lines buffer))
        ;; If any of them contain the current symbol:
        (when (string-match (rx-to-string `(seq symbol-start ,symbol symbol-end)) line)
          (push line matching-lines))))

    ;; Sort by string length, because the shortest string is usually best.
    (setq matching-lines
          (--sort (< (length it) (length other)) matching-lines))

    (if matching-lines
        (let* ((example-line (-first-item matching-lines))
               (line (pyimport--import-simplify example-line symbol)))
          (pyimport--insert-import line)
          (message "%s (from %s)" line (get-text-property 0 'pyimport-path example-line)))
      (user-error "No matches found"))))

(defun pyimport--extract-unused-var (flycheck-message)
  "Extract the import variable name from FLYCHECK-MESSAGE.
FLYCHECK-MESSAGE should take the form \"'foo' imported but unused\"."
  (->> flycheck-message
       (s-match "'\\(.*\\)' imported but unused")
       -last-item
       (s-split (rx "."))
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
       ((looking-at (rx "import " (1+ (not (any space))) line-end))
        (pyimport--delete-current-line))

       ;; Otherwise, it's '... import foo' or '... import foo as bar'
       (t
        ;; Remove the variable reference.
        (or (pyimport--remove-on-line (format ", %s" var))
            (pyimport--remove-on-line (format "%s, " var))
            (pyimport--remove-on-line var))
        ;; If we only have "from foo import " left, remove the rest of the line.
        (when (or (looking-at (rx "from " (1+ (not (any space))) " import " line-end))
                  (looking-at (rx "import " (1+ (not (any space))) " as " line-end)))
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
  
  (let* ((filename (buffer-file-name))
         (flycheck-output (shell-command-to-string
                           (format "%s %s"
                                   pyimport-pyflakes-path
                                   filename)))
         (raw-lines (s-split "\n" (s-trim flycheck-output)))
         (lines (--map (s-split ":" it) raw-lines))
         (import-lines (--filter (s-ends-with-p "imported but unused" (-last-item it)) lines))
         (unused-imports (--map (cons (read (nth 1 it))
                                      (pyimport--extract-unused-var (nth 2 it))) import-lines)))
    ;; Iterate starting form the last unused import, so our line
    ;; numbers stay correct, even when we delete lines.
    (--each (reverse unused-imports)
      (-let [(line . var ) it]
        (pyimport--remove-import line var)))))

(provide 'pyimport)
;;; pyimport.el ends here
