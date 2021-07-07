;;; go-impl.el --- impl integration for go-mode -*- lexical-binding: t; -*-

;; Copyright (C) 2017 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-go-impl
;; Package-Version: 20170125.1552
;; Package-Commit: 69f0d0ef05771487e15abec500cd06befd171abf
;; Version: 0.14
;; Package-Requires: ((emacs "24.3") (go-mode "1.3.0"))

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

;; Insert method stubs for implementing an interface by impl.

;;; Code:

(require 'go-mode)
(require 'cl-lib)

(defgroup go-impl nil
  "`impl' integration for go-mode."
  :group 'go)

(defcustom go-impl-command (executable-find "impl")
  "Location of impl command."
  :type 'file)

(defcustom go-impl-aliases-alist nil
  "List of aliases for interface names"
  :type '(alist :key-type (string :tag "Alias")
                :value-type (string :tag "Real interface name")))

(defcustom go-impl-enter-function nil
  "Move point into the first inserted function."
  :type 'boolean)

(defvar go-impl--interface-cache (make-hash-table :test #'equal))
(defvar go-impl--receiver-cache nil)
(defvar go-impl--receiver-history nil)
(defvar go-impl--interface-history nil)

(defun go-impl--real-package-name (package)
  (if (string-match "\\([^/-]+\\)\\'" package)
      (match-string-no-properties 1 package)
    package))

(defun go-impl--collect-receiver-types-1 (buf)
  (with-current-buffer buf
    (save-excursion
      (goto-char (point-min))
      (let (types)
        (while (re-search-forward "^type\\s-+\\(\\S-+\\)\\s-+\\(\\S-+\\)" nil t)
          (unless (string= (match-string-no-properties 2) "interface")
            (push (match-string-no-properties 1) types)))
        types))))

(defun go-impl--collect-receiver-types ()
  (or go-impl--receiver-cache
      (cl-loop with opened-bufs = (buffer-list)
               for file in (directory-files default-directory nil "\\.go\\'")
               unless (string-match-p "_test.go\\'" file)
               append
               (let ((buf (find-file-noselect file)))
                 (prog1 (go-impl--collect-receiver-types-1 buf)
                   (unless (memq buf opened-bufs)
                     (kill-buffer buf))))
               into types
               finally return (setq go-impl--receiver-cache types))))

(defun go-impl--collect-interface (package)
  (with-temp-buffer
    (unless (zerop (process-file "godoc" nil t nil "-src" package))
      (error "Failed: 'godoc -src %s'" package))
    (goto-char (point-min))
    (cl-loop with re = "^type\\s-+\\(\\S-+\\)\\s-+interface"
             with real-package = (go-impl--real-package-name package)
             while (re-search-forward re nil t)
             collect (concat real-package "." (match-string-no-properties 1)) into interfaces
             finally return (progn
                              (puthash package (cl-copy-list interfaces) go-impl--interface-cache)
                              interfaces))))

(defun go-impl--collect-interfaces (packages)
  (cl-loop for package in packages
           if (gethash package go-impl--interface-cache)
           append it
           else
           append (go-impl--collect-interface package)))

(defun go-impl--matched-packages (packages pattern)
  (cl-loop with regexp = (concat pattern "\\'")
           for p in packages
           when (string-match-p regexp p)
           collect p))

(defun go-impl--completing-function (packages input predicate code)
  (let (candidates)
    (if (not (string-match "\\." input))
        (setq candidates
              (delete-dups
               (cl-loop with re = (concat "\\`" input)
                        for package in (mapcar #'go-impl--real-package-name packages)
                        when (string-match-p re package)
                        collect package)))
      (let* ((interface-part (substring input 0 (match-beginning 0)))
             (matched (go-impl--matched-packages packages interface-part)))
        (setq candidates (go-impl--collect-interfaces matched))))
    (if (not code)
        (try-completion input candidates predicate)
      (all-completions input candidates predicate))))

(defun go-impl--execute (receiver interface)
  (with-temp-buffer
    (unless (zerop (process-file go-impl-command nil t nil receiver interface))
      (error "Failed: impl '%s' %s" receiver interface))
    (buffer-string)))

(defun go-impl--receiver-complete ()
  (interactive)
  (let ((input (minibuffer-contents)))
    (when (string-match "\\`\\S-+\\s-+\\*?\\(\\S-*\\)" input)
      (let* ((start-pos (+ (minibuffer-prompt-end) (match-beginning 1)))
             (receiver (match-string-no-properties 1 input))
             (candidates (go-impl--collect-receiver-types))
             (matches (all-completions receiver candidates)))
        (completion-in-region start-pos (point-max) matches)))))

(defvar go-impl--local-command-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map minibuffer-local-map)
    (define-key map "\t" #'go-impl--receiver-complete)
    map))

;;;###autoload
(defun go-impl (receiver interface)
  (interactive
   (let* ((packages (go-packages))
          (comp-fn (lambda (input predicate code)
                     (when (bound-and-true-p helm-mode)
                       (setq input (or (bound-and-true-p helm-input) input)))
                     (go-impl--completing-function packages input predicate code))))
     (setq go-impl--receiver-cache nil)
     (list
      (read-from-minibuffer "Receiver: " nil go-impl--local-command-map nil
                            'go-impl--receiver-history nil t)
      (completing-read "Interface: " comp-fn nil nil nil 'go-impl--interface-history))))
  (when go-impl-aliases-alist
    (setq interface (or (assoc-default interface go-impl-aliases-alist)
                        interface)))
  (let ((stubs (go-impl--execute receiver interface)))
    (save-excursion
      (insert stubs))
    (when go-impl-enter-function
      (forward-line)
      (back-to-indentation))))

(provide 'go-impl)

;;; go-impl.el ends here
