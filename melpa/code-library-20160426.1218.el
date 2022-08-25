;;; code-library.el --- use org-mode to collect code snippets

;; Copyright (C) 2004-2015 DarkSun <lujun9972@gmail.com>.

;; Author: DarkSun <lujun9972@gmail.com>
;; Created: 2015-11-23
;; Version: 0.1
;; Package-Version: 20160426.1218
;; Package-Commit: 3c79338eae5c892bfb4e4882298422d9fd65d2d7
;; Keywords: lisp, code
;; Package-Requires: ((gist "1.3.1"))

;; This file is NOT part of GNU Emacs.

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

;;; Source code
;;
;; code-library's code can be found here:
;;   http://github.com/lujun9972/code-library

;;; Commentary:

;; code-library is a tool that use org-mode to collect code snippets.

;;; Code:

(require 'gist)

(defgroup code-library nil
  "code library group"
  :prefix "code-library-")

(defcustom code-library-mode-file-alist '((c++-mode . "cpp.org")
                                          (dos-mode . "bat.org")
                                          (emacs-lisp-mode . "elisp.org")
                                          (perl-mode . "perl.org")
                                          (python-mode . "python.org")
                                          (sh-mode . "bash.org")
                                          (js-jsx-mode . "javascript.org")
                                          (js-mode . "javascript.org")
                                          (js2-jsx-mode . "javascript.org")
                                          (js2-mode . "javascript.org"))

  "Mapping the correspondence between `major-mode' and the snippet file."
  :group 'code-library)

(defcustom code-library-directory "~/CodeLibrary/"
  "Snippet files are stored in the directory."
  :group 'code-library)

(defcustom code-library-use-tags-command t
  "Automatically run `org-mode' tags prompt when saving a snippet."
  :group 'code-library)

(defcustom code-library-keep-indentation '(makefile-mode
                                           makefile-gmake-mode)
  "List of modes which will be keep tabs and indentation as is.

Normally code-library removed tabs to normalise indentation
because code can come from a range of sources where the
formatting and buffer local tab width can be in use."
  :group 'code-library)

(defcustom code-library-org-file-header "#+PROPERTY: eval no-export"
  "Header to be inserted in org-files.

This is automatically done by code-library before inserting
snippets into empty or new .org files."
  :group 'code-library)

(defcustom code-library-keyword-format-function 'identity
  "This function will be used to format the org keyword.

'downcase will lower case org mode keywords
'upcase will upper case org mode keywords"
  :group 'code-library)

(defcustom code-library-sync-to-gist nil
  "synchronize to gist or not."
  :group 'code-library)

(defun code-library-trim-left-margin ()
  "Remove common line whitespace prefix."
  (save-excursion
    (goto-char (point-min))
    (let ((common-left-margin) )
      (while (not (eobp))
        (unless (save-excursion
                  (looking-at "[[:space:]]*$"))
          (back-to-indentation)
          (setq common-left-margin
                (min (or common-left-margin (current-column)) (current-column))))
        (forward-line))
      (when (and common-left-margin (> common-left-margin 0))
        (goto-char (point-min))
        (while (not (eobp))
          (delete-region (point)
                         (+ (point)
                            (min common-left-margin
                                 (save-excursion
                                   (back-to-indentation)
                                   (current-column)))))
          (forward-line))))))

(defsubst code-library-buffer-substring (beginning end &optional keep-indent)
  "Return the content between BEGINNING and END.

Tabs are converted to spaces according to mode.

The first line is whitespace padded if BEGINNING is positioned
after the beginning of that line.

Common left margin whitespaces are trimmed.

If KEEP-INDENT is t, tabs and indentation will be kept."
  (let ((content (buffer-substring-no-properties beginning end))
        (content-tab-width tab-width)
        (content-column-start (save-excursion
                                (goto-char beginning)
                                (current-column))))
    (with-temp-buffer
      (let ((tab-width content-tab-width))
        (unless keep-indent
          (insert (make-string content-column-start ?\s)))
        (insert content)
        (unless keep-indent
          (untabify (point-min) (point-max))
          (code-library-trim-left-margin))
        (buffer-substring-no-properties (point-min) (point-max))))))


(defun code-library-get-thing (&optional keep-indent)
  "Return what's supposed to be saved to the conde library as a string."
  (let* ((bod (bounds-of-thing-at-point 'defun))
         (r (cond
             ((region-active-p) (cons (region-beginning) (region-end)))
             (bod bod)
             (t (cons (point-min) (point-max))))))
    (code-library-buffer-substring (car r) (cdr r) keep-indent)))

(defun code-library-create-snippet (head content &optional keep-indent)
  "Create and return a new org heading with source block.

HEAD is the org mode heading"
  (let ((code-major-mode (replace-regexp-in-string "-mode$" "" (symbol-name major-mode)))
        (tangle-file (if (buffer-file-name) (file-name-nondirectory (buffer-file-name)))))
    (with-temp-buffer
      (insert content)
      (org-escape-code-in-region (point-min) (point-max))
      (unless (bolp)
        (insert "\n"))
      (insert (format "#+%s\n" (funcall code-library-keyword-format-function "END_SRC")))
      (goto-char (point-min))
      (insert (format "* %s\n" head))
      (insert (format "#+%s %s" (funcall code-library-keyword-format-function "BEGIN_SRC") code-major-mode))
      (when tangle-file
        (insert (format " :%s %s" (funcall code-library-keyword-format-function "tangle") tangle-file)))
      (insert "\n")
      (buffer-string))))

(defun code-library--newline-if-non-blankline ()
  "add newline if point at non-blankline"
  (when (and (char-before)
             (not (char-equal ?\n (char-before))))
    (newline)))

(defun code-library-save-code-to-file (library-file head content &optional keep-indent)
  "Save the snippet to it's file location."
  (let ((snippet (code-library-create-snippet head content keep-indent))
        (new-or-blank (or (not (file-exists-p library-file))
                          (= 0 (nth 7 (file-attributes library-file))))))
    (with-current-buffer
        (find-file-noselect library-file) ;we can't just use (= 0 (buffer-size)), because find-file-hook or find-file-not-found-functions might change the buffer.
      (when new-or-blank
        (goto-char (point-max))
        (code-library--newline-if-non-blankline)
        (insert code-library-org-file-header)
        (code-library--newline-if-non-blankline))
      (when (and keep-indent
                 (not (buffer-local-value 'org-src-preserve-indentation (current-buffer))))
        (add-file-local-variable-prop-line 'org-src-preserve-indentation t))
      (save-excursion
        (goto-char (point-max))
        (beginning-of-line)
        (unless (looking-at "[[:space:]]*$")
          (newline))
        (insert snippet)
        (when code-library-use-tags-command
          (org-set-tags-command)))
      (save-buffer))))

(defun code-library-save-code-to-gist (head content &optional keep-indent)
  "Save the snippet to it's file location."
  (let* ((file (or (buffer-file-name) (buffer-name)))
         (name (file-name-nondirectory file))
         (ext (or (cdr (assoc major-mode gist-supported-modes-alist))
                  (file-name-extension file)
                  "txt"))
         (fname (concat (file-name-sans-extension name) "." ext))
         (files (list
                 (make-instance 'gh-gist-gist-file
                                :filename fname
                                :content content))))
    (gist-internal-new files nil head nil)))

;;;###autoload
(defun code-library-save-code()
  "Save the snippet to it's file location."
  (interactive)
  (let* ((keep-indent (member major-mode code-library-keep-indentation))
         (head (read-string "Please enter this code description: " nil nil "Untitled"))
         (content (code-library-get-thing keep-indent))
         (code-major-mode (replace-regexp-in-string "-mode$" "" (symbol-name major-mode)))
         (library-base-file (or (cdr (assoc major-mode code-library-mode-file-alist))
                                (concat code-major-mode ".org")))
         (library-file (expand-file-name library-base-file
                                         (file-name-as-directory code-library-directory))))
    (code-library-save-code-to-file library-file head content keep-indent)
    (when code-library-sync-to-gist
      (code-library-save-code-to-gist head content keep-indent))))

(provide 'code-library)

;;; code-library.el ends here
