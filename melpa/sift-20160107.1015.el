;;; sift.el --- Front-end for sift, a fast and powerful grep alternative

;; Copyright (C) 2015 Nicolas Lamirault <nicolas.lamirault@gmail.com>
;;
;; Author: Nicolas Lamirault <nicolas.lamirault@gmail.com>
;; Version: 0.2.0
;; Package-Version: 20160107.1015
;; Package-Commit: 8c3f3d14a351a2394027d72ee0599aa73b9f0d13
;; Keywords : sift ack pt ag grep search
;; Homepage: https://github.com/nlamirault/sift.el

;;; Commentary:

;; Please see README.md for documentation, or read it online at
;; https://github.com/nlamirault/sift.el

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301, USA.

;;; Commentary:

;; Usage :

;; M-x sift-regexp

;;; Code:

(require 'compile)
(require 'grep)
(require 'thingatpt)


;; Customization
;; --------------------------


(defcustom sift-executable
  "sift"
  "Name of the sift executable to use."
  :type 'string
  :group 'sift)


(defcustom sift-arguments
  (list "-I")
  "Default arguments passed to sift."
  :type '(repeat (string))
  :group 'sift)


(defcustom sift-highlight-search t
  "Non-nil means we highlight the current search term in results.
This requires the sift command to support --color-match, which is only in v0.14+"
  :type 'boolean
  :group 'sift)


;; Faces
;; --------------------------


(defface sift-hit-face '((t :inherit compilation-info))
  "Face name to use for sift matches."
  :group 'sift)


(defface sift-match-face '((t :inherit match))
  "Face name to use for sift matches."
  :group 'sift)



;; Mode
;; --------------------------


(defvar sift-search-finished-hook nil
  "Hook run when sift completes a search in a buffer.")

(defun sift/run-finished-hook (buffer how-finished)
  "Run the sift hook to signal that the search has completed."
  (with-current-buffer buffer
    (run-hooks 'sift-search-finished-hook)))

(defvar sift-search-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map compilation-minor-mode-map)
    (define-key map "p" 'compilation-previous-error)
    (define-key map "n" 'compilation-next-error)
    (define-key map "{" 'compilation-previous-file)
    (define-key map "}" 'compilation-next-file)
    (define-key map "k" '(lambda ()
                           (interactive)
                           (let ((kill-buffer-query-functions))
                             (kill-buffer))))
    map)
  "Keymap for sift-search buffers.
`compilation-minor-mode-map' is a cdr of this.")


(define-compilation-mode sift-search-mode "Sift"
  "Platinum searcher results compilation mode"
  (set (make-local-variable 'truncate-lines) t)
  (set (make-local-variable 'compilation-disable-input) t)
  (set (make-local-variable 'tool-bar-map) grep-mode-tool-bar-map)
  (let ((symbol 'compilation-sift)
        (pattern '("^\\([^:\n]+?\\):\\([0-9]+\\):[^0-9]" 1 2)))
    (set (make-local-variable 'compilation-error-regexp-alist) (list symbol))
    (set (make-local-variable 'compilation-error-regexp-alist-alist) (list (cons symbol pattern))))
  (set (make-local-variable 'compilation-error-face) 'sift-hit-face)
  (add-hook 'compilation-filter-hook 'sift-filter nil t))


;; Taken from grep-filter, just changed the color regex.
(defun sift-filter ()
  "Handle match highlighting escape sequences inserted by the ag process.
This function is called from `compilation-filter-hook'."
  (when sift-highlight-search
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
          ;; Highlight ag matches and delete marking sequences.
          (while (re-search-forward "\033\\[30;43m\\(.*?\\)\033\\[[0-9]*m" end 1)
            (replace-match (propertize (match-string 1)
                                       'face nil 'font-lock-face 'sift-match-face)
                           t t))
          ;; Delete all remaining escape sequences
          (goto-char beg)
          (while (re-search-forward "\033\\[[0-9;]*[mK]" end 1)
            (replace-match "" t t)))))))



;; API
;; --------------------------


;;;###autoload
(defun sift-regexp (regexp directory &optional args)
  "Run a sift search with `REGEXP' rooted at `DIRECTORY'.
`ARGS' provides Sift command line arguments."
  (interactive
   (list (read-from-minibuffer "Sift search for: " (thing-at-point 'symbol))
         (read-directory-name "Directory: ")))
  (let ((default-directory directory))
    (compilation-start
     (mapconcat 'identity
                (append (list sift-executable)
                        sift-arguments
                        args
                        '("--color" "-n" "--stats")
                        (list (shell-quote-argument regexp) ".")) " ")
     'sift-search-mode)))


(provide 'sift)
;;; sift.el ends here
