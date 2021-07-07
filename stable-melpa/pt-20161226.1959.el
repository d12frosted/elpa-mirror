;;; pt.el --- A front-end for pt, The Platinum Searcher.
;;
;; Copyright (C) 2014 by Bailey Ling
;; Author: Bailey Ling
;; URL: https://github.com/bling/pt.el
;; Package-Version: 20161226.1959
;; Package-Commit: 6d99b2aaded3ece3db19a20f4b8f1d4abe382622
;; Filename: pt.el
;; Description: A front-end for pt, the Platinum Searcher
;; Created: 2014-04-27
;; Version: 0.0.3
;; Keywords: pt ack ag grep search
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Install:
;;
;; Autoloads will be set up automatically if you use package.el.
;;
;; Usage:
;;
;; M-x pt-regexp
;; M-x pt-regexp-file-pattern
;; M-x projectile-pt
;;
;;; Code:

(eval-when-compile (require 'cl))
(require 'compile)
(require 'grep)
(require 'thingatpt)

(defcustom pt-executable
  "pt"
  "Name of the pt executable to use."
  :type 'string
  :group 'pt)

(defcustom pt-arguments
  (list "--smart-case")
  "Default arguments passed to pt."
  :type '(repeat (string))
  :group 'pt)

(defvar pt-search-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map compilation-minor-mode-map)
    (define-key map "n" 'next-error-no-select)
    (define-key map "j" 'next-error-no-select)
    (define-key map "p" 'previous-error-no-select)
    (define-key map "k" 'previous-error-no-select)
    (define-key map "{" 'compilation-previous-file)
    (define-key map "}" 'compilation-next-file)
    map)
  "Keymap for pt-search buffers.
`compilation-minor-mode-map' is a cdr of this.")

(define-compilation-mode pt-search-mode "Pt"
  "Platinum searcher results compilation mode"
  (set (make-local-variable 'truncate-lines) t)
  (set (make-local-variable 'compilation-disable-input) t)
  (set (make-local-variable 'tool-bar-map) grep-mode-tool-bar-map)
  (let ((symbol 'compilation-pt)
        (pattern '("^\\([^:\n]+?\\):\\([0-9]+\\):[^0-9]" 1 2)))
    (set (make-local-variable 'compilation-error-regexp-alist) (list symbol))
    (set (make-local-variable 'compilation-error-regexp-alist-alist) (list (cons symbol pattern))))
  (set (make-local-variable 'compilation-error-face) grep-hit-face)
  (add-hook 'compilation-filter-hook 'pt-filter nil t))

;; Based on grep-filter
(defun pt-filter ()
  "Handle match highlighting escape sequences inserted by the process.
This function is called from `compilation-filter-hook'."
  (save-excursion
    (forward-line 0)
    (let ((end (point)) beg)
      (goto-char compilation-filter-start)
      (forward-line 0)
      (setq beg (point))
      ;; Only operate on whole lines so we don't get caught with part of an
      ;; escape sequence in one chunk and the rest in another.
      (when (< (point) end)
        (setq end (copy-marker end))
        ;; Highlight matches and delete marking sequences.
        (while (re-search-forward "\033\\[30;43m\\(.*?\\)\033\\[0m" end 1)
          (replace-match (propertize (match-string 1)
                                     'face nil 'font-lock-face grep-match-face)
                         t t))
        ;; Delete all remaining escape sequences
        (goto-char beg)
        (while (re-search-forward "\033\\[[0-9;]*[mK]" end 1)
          (replace-match "" t t))))))

;;;###autoload
(defun pt-regexp (regexp directory &optional args)
  "Run a pt search with REGEXP rooted at DIRECTORY."
  (interactive (list (read-from-minibuffer "Pt search for: " (thing-at-point 'symbol))
                     (read-directory-name "Directory: ")))
  (let ((default-directory (file-name-as-directory directory)))
    (compilation-start
     (mapconcat 'identity
                (append (list pt-executable)
                        pt-arguments
                        args
                        '("-e" "--nogroup" "--color" "--")
                        (list (shell-quote-argument regexp) ".")) " ")
     'pt-search-mode)))

;;;###autoload
(defun pt-regexp-file-pattern (regexp directory pattern)
  "Run a pt search with REGEXP rooted at DIRECTORY with FILE-FILTER."
  (interactive (list (read-from-minibuffer "Pt search for: " (thing-at-point 'symbol))
                     (read-directory-name "Directory: ")
                     (read-from-minibuffer "File pattern: ")))
  (pt-regexp regexp
             directory
             (list (concat "--file-search-regexp=" (shell-quote-argument pattern)))))

;;;###autoload
(defun projectile-pt (regexp)
  "Run a pt search with REGEXP rooted at the current projectile project root."
  (interactive (list (read-from-minibuffer "Pt search for: " (thing-at-point 'symbol))))
  (if (fboundp 'projectile-project-root)
      (pt-regexp regexp
                 (projectile-project-root)
                 (mapcar (lambda (val) (concat "--ignore=" (shell-quote-argument val)))
                         (append projectile-globally-ignored-files
                                 projectile-globally-ignored-directories)))
    (error "Projectile is not available")))

(provide 'pt)
;;; pt.el ends here
