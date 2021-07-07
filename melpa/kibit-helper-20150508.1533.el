;;; kibit-helper.el --- Conveniently use the Kibit Leiningen plugin from Emacs

;; Copyright © 2012-2015 Jonas Enlund
;; Copyright © 2015 James Elliott
;;
;; Author: Jonas Enlund
;;         James Elliott <james@brunchboy.com>
;; URL: http://www.github.com/brunchboy/kibit-helper
;; Package-Version: 20150508.1533
;; Package-Commit: 16bdfff785ee05d8e74a5780f6808506d990cef7
;; Version: 0.1.1
;; Package-Requires: ((s "0.8") (emacs "24"))
;; Keywords: languages, clojure, kibit

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Provides functions that make it easy to work with the Kibit
;; Leiningen plugin for detecting and improving non-idiomatic
;; Clojure source code, from within GNU Emacs. See
;; <https://github.com/jonase/kibit> for more information about
;; Kibit.

;; This package does not require Cider, although if you are working
;; with Clojure in Emacs, you should almost certaily be using it.
;; <http://www.github.com/clojure-emacs/cider>

;;; Installation:

;; Available as a package in melpa.org

;; (add-to-list 'package-archives
;;              '("melpa" . "http://melpa.org/packages/") t)
;;
;; M-x package-install kibit-helper

;;; Usage:

;; M-x kibit
;; M-x kibit-current-file
;; M-x kibit-accept-proposed-change

;; You will likely want to bind the last function to C-x C-`
;; so it is easy to alternate with the next-error function
;; (conventionally C-x `) as you walk through the suggestions
;; made by Kibit:

;; (global-set-key (kbd "C-x C-`") 'kibit-accept-proposed-change)

;; Note that some changes cannot be automatically applied.
;; Kibit strips comments from the source code, and so they
;; will be missing from both the "original" and suggested
;; versions of the code being examined. You will need to
;; manually apply these changes, and kibit-accept-proposed-change
;; will tell you when that happens. It will also tell you if
;; you seem to be running it twice on the same change, i.e.
;; the suggested improvements have already been made.


;;; Code:

;; Teach compile the syntax of the kibit output
(require 'compile)
(add-to-list 'compilation-error-regexp-alist-alist
             '(kibit "At \\([^:]+\\):\\([[:digit:]]+\\):" 1 2 nil 2))
(add-to-list 'compilation-error-regexp-alist 'kibit)

;; Low-level function to create a compilation buffer with an
;; appropriate name, generating Kibit suggestions for either the
;; entire project associated with the current directory, or a specific
;; file, if supplied.
(defun kibit-compilation-do (&optional filename)
  (save-some-buffers (not compilation-ask-about-save)
                     (when (boundp 'compilation-save-buffers-predicate)
                       compilation-save-buffers-predicate))
  (let ((this-dir default-directory)
        (command (concat "lein kibit"
                         (when filename (concat " " (shell-quote-argument filename))))))
    (with-current-buffer (get-buffer-create "*Kibit Suggestions*")
      (setq default-directory this-dir)
      (compilation-start
       command
       'compilation-mode
       (lambda (m) (buffer-name))))))

;; A convenient command to run "lein kibit" in the project to which
;; the current emacs buffer belongs to.
;;;###autoload
(defun kibit ()
  "Run kibit on the current Leiningen project.
Display the results in a hyperlinked *compilation* buffer."
  (interactive)
  (kibit-compilation-do))
  
;;;###autoload
(defun kibit-current-file ()
  "Run kibit on the current file of a Leiningen project.
Display the results in a hyperlinked *compilation* buffer."
  (interactive)
  (kibit-compilation-do buffer-file-name))

(require 's)

;;;###autoload
(defun kibit-accept-proposed-change ()
  (interactive)
  "Automatically make the changes proposed by Kibit as the
current error in the *compilation* buffer. If you decide you do
not like the results after all (perhaps the indentation and other
changes to whitespace or commas were too extreme), a simple undo
will restore your former source code. If you then manually make
just the semantic change suggested by Kibit and re-run this
command, you can validate your manual change by the fact that
kibit-accept-proposed-change will report that the change has
already been made."
  (if (setq next-error-last-buffer (next-error-find-buffer))
      (with-current-buffer next-error-last-buffer
        (unless compilation-current-error
          (next-error)
          (unless compilation-current-error
            (error "No Kibit suggestions to apply.")))
        (goto-char compilation-current-error)
        (beginning-of-line)
        (if (looking-at "At \\([^:]+\\):\\([[:digit:]]+\\):\nConsider using:\\s-+\\(\\(.*\n\\)*?\\)instead of:\n\\(\\(.*\n\\)*?\\)\n")
            (let* ((filename (match-string-no-properties 1))
                   (linenum (match-string-no-properties 2))
                   (raw-suggestion (match-string-no-properties 3))
                   (raw-existing (match-string-no-properties 5)))
              (next-error 0)
              (let* ((msg (compilation-next-error 0))
                     (loc (compilation--message->loc msg))
                     (replace-marker (compilation--loc->marker loc))
                     (suggestion (s-trim raw-suggestion))
                     (existing (replace-regexp-in-string "[, \n\t]+" "[, \n\t]+" (regexp-quote (s-trim raw-existing)) t t))
                     (pattern (concat ".*\\(" existing "\\)")))
                (with-current-buffer (marker-buffer replace-marker)
                  (if (looking-at pattern)
                      (progn  (replace-match suggestion t  t nil 1)
                              (indent-region (match-beginning 1) (+ (match-beginning 1) (length suggestion)))
                              (message "Suggested replacement made."))
                    (let* ((sug-expr (replace-regexp-in-string "[, \n\t]+" "[, \n\t]+" (regexp-quote suggestion) t t))
                           (sug-pattern (concat ".*\\(" sug-expr "\\)")))
                      (if (looking-at sug-pattern)
                          (error "Suggested replacement already made.")
                        (error "Cannot match source. (Comments and manual edits prevent automated replacement.)")))))))
          (message "Do not seem to be currently processing Kibit errors.")))
    (message "Do not seem to be currently processing Kibit errors.")))

(provide 'kibit-helper)

;;; kibit-helper.el ends here
