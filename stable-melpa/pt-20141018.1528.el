;;; pt.el --- A front-end for pt, The Platinum Searcher.
;;
;; Copyright (C) 2014 by Bailey Ling
;; Author: Bailey Ling
;; URL: https://github.com/bling/pt.el
;; Package-Version: 20141018.1528
;; Package-Commit: a539dc11ecb2d69760ff50f76c96f49895ce1e1e
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

(define-compilation-mode pt-search-mode "Pt"
  "Platinum searcher results compilation mode"
  (set (make-local-variable 'truncate-lines) t)
  (set (make-local-variable 'compilation-disable-input) t)
  (let ((symbol 'compilation-pt)
        (pattern '("^\\([^:\n]+?\\):\\([0-9]+\\):[^0-9]" 1 2)))
    (set (make-local-variable 'compilation-error-regexp-alist) (list symbol))
    (set (make-local-variable 'compilation-error-regexp-alist-alist) (list (cons symbol pattern))))
  (set (make-local-variable 'compilation-error-face) grep-hit-face))

;;;###autoload
(defun pt-regexp (regexp directory &optional args)
  "Run a pt search with REGEXP rooted at DIRECTORY."
  (interactive (list (read-from-minibuffer "Pt search for: " (thing-at-point 'symbol))
                     (read-directory-name "Directory: ")))
  (let ((default-directory directory))
    (compilation-start
     (mapconcat 'identity
                (append (list pt-executable)
                        pt-arguments
                        args
                        '("-e" "--nogroup" "--nocolor" "--")
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
                 (mapcar (lambda (val) (concat "--ignore=" val))
                         (append projectile-globally-ignored-files
                                 projectile-globally-ignored-directories)))
    (error "Projectile is not available")))

(provide 'pt)
;;; pt.el ends here
