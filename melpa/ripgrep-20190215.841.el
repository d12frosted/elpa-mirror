;;; ripgrep.el --- Front-end for ripgrep, a command line search tool

;; Copyright (C) 2016 Nicolas Lamirault <nicolas.lamirault@gmail.com>
;;
;; Author: Nicolas Lamirault <nicolas.lamirault@gmail.com>
;; Version: 0.4.0
;; Package-Version: 20190215.841
;; Package-Commit: 40e871dcc4519a70981e9f28acea304692a60978
;; Keywords : ripgrep ack pt ag sift grep search
;; Homepage: https://github.com/nlamirault/ripgrep.el

;;; Commentary:

;; Emacs front-end for ripgrep, a command line search tool

;; Installation:

;; ripgrep.el is available on the two major community maintained repositories
;; Melpa stable (https://stable.melpa.org), and Melpa (https://melpa.org)
;;
;; (add-to-list 'package-archives
;;              '("melpa" . "https://melpa.org/packages/") t)
;;
;; M-x package-install ripgrep

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

;; M-x ripgrep-regexp

;;; Code:

(require 'compile)
(require 'grep)
(require 'thingatpt)
(require 'wgrep nil 'noerror) ;; optional

;; Customization
;; --------------------------

(defgroup ripgrep nil
  "Ripgrep"
  :group 'tools
  :group 'matching)


(defcustom ripgrep-executable
  "rg"
  "Name of the ripgrep executable to use."
  :type 'string
  :group 'ripgrep)


(defcustom ripgrep-arguments
  (list "")
  "Default arguments passed to ripgrep."
  :type '(repeat (string))
  :group 'ripgrep)


(defcustom ripgrep-highlight-search t
  "Non-nil means we highlight the current search term in results.
This requires the ripgrep command to support --color-match, which is only in v0.14+"
  :type 'boolean
  :group 'ripgrep)


;; Faces
;; --------------------------

(defface ripgrep-hit-face '((t :inherit compilation-info))
  "Face name to use for ripgrep hits."
  :group 'ripgrep)

(defface ripgrep-match-face '((t :inherit match))
  "Face name to use for ripgrep matches."
  :group 'ripgrep)

(defface ripgrep-error-face '((t :inherit compilation-error))
  "Face name to use for ripgrep errors."
  :group 'ripgrep)

(defface ripgrep-context-face '((t :inherit shadow))
  "Face name to use for ripgrep errors."
  :group 'ripgrep)



;; Mode
;; --------------------------

(defvar ripgrep--base-arguments '("--no-heading" "--line-number" "--with-filename")
  "Options that are always applied to ripgrep commands.")

(defvar ripgrep-search-finished-hook nil
  "Hook run when ripgrep completes a search in a buffer.")

(defun ripgrep/run-finished-hook (buffer how-finished)
  "Run the ripgrep hook to signal that the search has completed."
  (with-current-buffer buffer
    (run-hooks 'ripgrep-search-finished-hook)))

(defun ripgrep/kill-buffer ()
  "Kill the ripgrep search buffer."
  (interactive)
  (let ((kill-buffer-query-functions))
    (kill-buffer)))

(defvar ripgrep-search-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map compilation-minor-mode-map)
    (define-key map "p" 'compilation-previous-error)
    (define-key map "n" 'compilation-next-error)
    (define-key map "{" 'compilation-previous-file)
    (define-key map "}" 'compilation-next-file)
    (define-key map "k" 'ripgrep/kill-buffer)
    (define-key map "C-c C-p" 'wgrep-change-to-wgrep-mode)

    map)
  "Keymap for ripgrep-search buffers.
`compilation-minor-mode-map' is a cdr of this.")

;; from grep-mode-font-lock-keywords
(defvar ripgrep-search-mode-font-lock-keywords
   '(;; Command output lines.
     (": \\(.+\\): \\(?:Permission denied\\|No such \\(?:file or directory\\|device or address\\)\\)$"
      1 'ripgrep-error-face)
     ;; remove match from grep-regexp-alist before fontifying
     ("^Ripgrep[/a-zA-z]* \\(started\\|finished\\).*"
      (0 '(face nil compilation-message nil help-echo nil mouse-face nil) t))
     ("^Ripgrep[/a-zA-z]* \\(exited abnormally\\|interrupt\\|killed\\|terminated\\)\\(?:.*with code \\([0-9]+\\)\\)?.*"
      (0 '(face nil compilation-message nil help-echo nil mouse-face nil) t)
      (1 'ripgrep-error-face)
      (2 'ripgrep-error-face nil t))
     ;; "filename-linenumber-" format is used for context lines in GNU grep,
     ;; "filename=linenumber=" for lines with function names in "git grep -p".
     ("^.+?\\([-=\0]\\)[0-9]+\\([-=]\\).*\n" (0 'ripgrep-context-face)
      (1 (if (eq (char-after (match-beginning 1)) ?\0)
             `(face nil display ,(match-string 2))))))
   "Additional things to highlight in ripgrep output.
This gets tacked on the end of the generated expressions.")

(define-compilation-mode ripgrep-search-mode "Ripgrep"
  "Ripgrep results compilation mode"
  (set (make-local-variable 'truncate-lines) t)
  (set (make-local-variable 'compilation-disable-input) t)
  (set (make-local-variable 'tool-bar-map) grep-mode-tool-bar-map)
  (let ((symbol 'compilation-ripgrep)
        (pattern '("^\\([^:\n]+?\\):\\([0-9]+\\):" 1 2)))
    (set (make-local-variable 'compilation-error-regexp-alist) (list symbol))
    (set (make-local-variable 'compilation-error-regexp-alist-alist) (list (cons symbol pattern))))
  (set (make-local-variable 'compilation-error-face) 'ripgrep-hit-face)
  (add-hook 'compilation-filter-hook 'ripgrep-filter nil t)
  (when (featurep 'wgrep)
    (add-hook 'ripgrep-search-mode-hook 'wgrep-remove-all-change nil t)
    (add-hook 'ripgrep-search-mode-hook 'wgrep-setup)))

(defvar ripgrep--match-regexp "\e\\[[0-9]*m\e\\[[0-9]*1m\e\\[[0-9]*1m\\(.*?\\)\e\\[[0-9]*0m"
  "Used in `ripgrep-filter' to search for the match via ANSI escape codes")

;; Taken from grep-filter, just changed the color regex.
(defun ripgrep-filter ()
  "Handle match highlighting escape sequences inserted by the rg process.
This function is called from `compilation-filter-hook'."
  (when ripgrep-highlight-search
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
          ;; Highlight rg matches and delete marking sequences.
          (while (re-search-forward ripgrep--match-regexp end 1)
            (replace-match (propertize (match-string 1)
                                       'face nil 'font-lock-face 'ripgrep-match-face)
                           t t))
          ;; Delete all remaining escape sequences
          (goto-char beg)
          (while (re-search-forward "\033\\[[0-9;]*[mK]" end 1)
            (replace-match "" t t)))))))

;; API
;; --------------------------


;;;###autoload
(defun ripgrep-regexp (regexp directory &optional args)
  "Run a ripgrep search with `REGEXP' rooted at `DIRECTORY'.
`ARGS' provides Ripgrep command line arguments."
  (interactive
   (list (read-from-minibuffer "Ripgrep search for: " (thing-at-point 'symbol))
         (read-directory-name "Directory: ")))
  (let ((default-directory directory))
    (compilation-start
     (mapconcat 'identity
                (append (list ripgrep-executable)
                        ripgrep-arguments
                        args
                        ripgrep--base-arguments
                        (when ripgrep-highlight-search '("--color=always"))
                        (when (and case-fold-search
                                   (isearch-no-upper-case-p regexp t))
                          '("--ignore-case"))
                        '("--")
                        (list (shell-quote-argument regexp) ".")) " ")
     'ripgrep-search-mode)))


(provide 'ripgrep)
;;; ripgrep.el ends here
