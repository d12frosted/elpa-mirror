;;; org-sync-snippets.el --- Export snippets to org-mode and vice versa

;; Copyright (C) 2017, Adrien Brochard

;; This file is NOT part of Emacs.

;; This  program is  free  software; you  can  redistribute it  and/or
;; modify it  under the  terms of  the GNU  General Public  License as
;; published by the Free Software  Foundation; either version 2 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT  ANY  WARRANTY;  without   even  the  implied  warranty  of
;; MERCHANTABILITY or FITNESS  FOR A PARTICULAR PURPOSE.   See the GNU
;; General Public License for more details.

;; You should have  received a copy of the GNU  General Public License
;; along  with  this program;  if  not,  write  to the  Free  Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
;; USA

;; Version: 1.0
;; Package-Version: 20210111.1726
;; Package-Commit: 88f995dea188b8a645a3388c42b62a2bb88953d3
;; Author: Adrien Brochard
;; Keywords: snippet org-mode yasnippet tools
;; URL: https://github.com/abrochard/org-sync-snippets
;; License: GNU General Public License >= 3
;; Package-Requires: ((org "8.3.5") (emacs "24.3") (f "0.17.3"))

;;; Commentary:

;; Simple extension to export snippets to org-mode and vice versa.
;; It was designed with Yasnippet in mind.

;;; Install:

;; Install from MELPA with
;;
;; M-x package-install org-sync-snippets
;;
;; or load the present file.

;;; Usage:

;; Load with
;;
;; (require 'org-sync-snippets)
;;
;; To export your snippets to an org-mode file, use
;;
;; M-x org-sync-snippets-snippets-to-org
;;
;; Alternatively, to turn your org-mode file into snippets
;;
;; M-x org-sync-snippets-org-to-snippets
;;
;; Notice: you can prevent certain snippets from being exported to org by adding the `tangle: no` tag in them.

;;; Customize:

;; By default, snippets are taken from the 'user-emacs-directory' (typically '~/.emacs.d/snippets/') folder.
;; You can change this with
;;
;; (setq org-sync-snippets-snippets-dir "~/your/path/to/snippets")
;;
;; Similarly, the org file compiled goes to your 'org-directory' (usually '~/org/snippets.org').
;; You can define a different one with
;;
;; (setq org-sync-snippets-org-snippets-file "~/your/path/to/snippet/file")
;;
;; Finally, if you want to save your snippets regularly, I recommend using a hook like
;;
;; (add-hook 'yas-after-reload-hook 'snippets-to-org)

;;; Code:
(require 'org)
(require 'f)

(defgroup org-sync-snippets nil
  "Export snippets to org-mode and vice versa.")

(defcustom org-sync-snippets-org-snippets-file (concat (file-name-as-directory org-directory) "snippets.org")
  "Location of the snippets.org file."
  :type 'file
  :group 'org-sync-snippets)

(defcustom org-sync-snippets-snippets-dir (locate-user-emacs-file "snippets")
  "Location the snippets folder."
  :type 'directory
  :group 'org-sync-snippets)

(defcustom org-sync-snippets-collection-title "Snippets Collection"
  "Title of the snippets.org collection."
  :type 'string
  :group 'org-sync-snippets)

(defcustom org-sync-snippets-dir-prefix "{SNIPPETS-DIR}"
  "Prefix for snippets file path."
  :type 'string
  :group 'org-sync-snippets)

(defun org-sync-snippets--encode-snippets-dir (snippets-dir snippets-file)
  "Turn the snippets dir into an encoded location.

SNIPPETS-DIR the snippet directory.
SNIPPETS-FILE the snippet file."
  (replace-regexp-in-string (expand-file-name snippets-dir) org-sync-snippets-dir-prefix snippets-file))

(defun org-sync-snippets--decode-snippets-dir (snippets-dir encoded-snippets-file)
  "Decode the encoded snippets file into a real path.

SNIPPETS-DIR the snippets location.
ENCODED-SNIPPETS-FILE the encoded snippet destination."
  (replace-regexp-in-string org-sync-snippets-dir-prefix snippets-dir encoded-snippets-file t))

(defun org-sync-snippets--parse-dir (snippets-dir level)
  "Recursive function to  write snippets to org file.

SNIPPETS-DIR the location of the snippets file.
LEVEL the current folder level."
  (if (< 0 level)
      (insert (make-string level (aref "*" 0)) " " (file-name-base snippets-dir) "\n\n"))
  (dolist (mode (f-directories snippets-dir))
    (org-sync-snippets--parse-dir mode (+ level 1)))
  (dolist (snippet-file (f-files snippets-dir))
    (let ((content (f-read-text snippet-file 'utf-8))
          (destination (org-sync-snippets--encode-snippets-dir
                        org-sync-snippets-snippets-dir snippet-file)))
      (unless (string-match "^# tangle: no" content)
        (insert (make-string (+ 1 level) (aref "*" 0)) " " (file-name-base snippet-file) "\n\n"
                "#+BEGIN_SRC snippet "
                ":tangle " destination
                "\n"
                (replace-regexp-in-string "^" "  "  content) "\n"
                "#+END_SRC\n\n")))))

(defun org-sync-snippets--to-org (snippets-dir org-file)
  "Write snippets to org file.

SNIPPETS-DIR is the location of the snippet files.
ORG-FILE the location of the compiled org file."
  (with-temp-file org-file
    (insert "#+TITLE: " org-sync-snippets-collection-title "\n")
    (insert "#+AUTHOR: org-sync-snippets\n\n")
    (org-sync-snippets--parse-dir snippets-dir 0)))

(defun org-sync-snippets--create-dir-structure (destination)
  "Make sure that the destination folder exists.

DESTINATION the destination of the snippet."
  (let ((directory (f-dirname destination)))
    (if (not (f-dir? directory))
        (make-directory directory t))))

(defun org-sync-snippets--iterate-org-src (org-file)
  "Iterate over source blocks of ORG-FILE.
Return list of cons '((destination content)"
  (with-temp-buffer
    (insert-file-contents org-file)
    (org-element-map (org-element-parse-buffer) 'src-block
      (lambda (el)
        (cons
         (org-sync-snippets--decode-snippets-dir
          org-sync-snippets-snippets-dir
          (replace-regexp-in-string "^:tangle " "" (org-element-property :parameters el)))
         (org-element-property :value el))))))

(defun org-sync-snippets--create-snippet-file (entry)
  "Create a snippet file from ENTRY (cons destination content."
  (let ((destination (car entry))
        (content (cdr entry)))
    (org-sync-snippets--create-dir-structure destination)
    (with-temp-file destination
      (insert (replace-regexp-in-string "^\s\\{2\\}" "" content))
      (delete-char -1))))

(defun org-sync-snippets--parse-snippet-org-file (org-file)
  "Parse the org file similar to org-babel, but without a newline at the end.

ORG-FILE the location of the compiled org file."
  (mapcar
   #'org-sync-snippets--create-snippet-file
   (org-sync-snippets--iterate-org-src org-file)))

(defun org-sync-snippets--to-snippets (org-file snippets-dir)
  "Tangle org file to snippets.

ORG-FILE the location of the compiled org file
SNIPPETS-DIR is the location of the snippet files."
  (org-sync-snippets--parse-snippet-org-file org-file))

;;;###autoload
(defun org-sync-snippets-snippets-to-org ()
  "Compile snippet files to an 'org-mode' file."
  (interactive)
  (org-sync-snippets--to-org org-sync-snippets-snippets-dir org-sync-snippets-org-snippets-file)
  (message "Done"))

(defun org-sync-snippets-org-to-snippets ()
  "Export the 'org-mode' file back to snippet files."
  (interactive)
  (org-sync-snippets--to-snippets org-sync-snippets-org-snippets-file org-sync-snippets-snippets-dir)
  (message "Done"))

(provide 'org-sync-snippets)
;;; org-sync-snippets.el ends here
