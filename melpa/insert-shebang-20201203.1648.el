;;; insert-shebang.el --- Insert shebang line automatically.

;; Copyright (C) 2013-2020  Sachin Patil

;; Author: Sachin Patil <iclcoolster@gmail.com>
;; URL: https://gitlab.com/psachin/insert-shebang
;; Package-Version: 20201203.1648
;; Package-Commit: cc8cea997a8523bce9f303de993af3a73eb0d2e2
;; Keywords: shebang, tool, convenience
;; Version: 0.9.7

;; This file is NOT a part of GNU Emacs.

;; `insert-shebang' is free software distributed under the terms of
;; the GNU General Public License, version 3. For details, see the
;; file COPYING.

;;; Commentary:
;; Inserts shebang line automatically
;; URL: https://gitlab.com/psachin/insert-shebang

;; Install

;; Using `package'
;; M-x package-install insert-shebang

;; Unless installed from a `package', add the directory containing
;; this file to `load-path', and then:
;; (require 'insert-shebang)
;;
;; Customize
;; M-x customize-group RET insert-shebang RET
;;
;; See ReadMe.org for more info.

;;; Code:

(defgroup insert-shebang nil
  "Inserts shebang line automatically."
  :group 'extensions
  :link '(url-link :tag "github" "https://github.com/psachin/insert-shebang"
                   :tag "gitlab" "https://gitlab.com/psachin/insert-shebang"))

(defcustom insert-shebang-env-path "/usr/bin/env"
  "Full path to `env' binary.
You can find the path to `env' by typing `which env' in the
terminal."
  :type '(string)
  :group 'insert-shebang)

(defcustom insert-shebang-file-types
  '(("py" . "python")
    ("groovy" . "groovy")
    ("fish" . "fish")
    ("robot" . "robot")
    ("rb" . "ruby")
    ("lua" . "lua")
    ("php" . "php")
    ("sh" . "bash")
    ("pl" . "perl")
    ("raku" . "raku"))
  "*If nil, add all your file extensions and file types here."
  :type '(alist :key-type (string :tag "Extension")
                :value-type (string :tag "Interpreter"))
  :group 'insert-shebang)

(defcustom insert-shebang-ignore-extensions
  '("txt" "org" "el")
  "*Add extensions you want to ignore.
List of file extensions to be ignored by default."
  :type '(repeat (string :tag "extn"))
  :group 'insert-shebang)

(defcustom insert-shebang-custom-headers nil
  "Put your custom headers for other file types here.
For example '#include <stdio.h>' for c file etc.

Example:

File type: c
Header: #include <stdio.h>

File type: f90
Header: program

File type: f95
Header: program"
  :type '(alist :key-type (string :tag "Extension")
                :value-type (string :tag "Header"))
  :group 'insert-shebang)

(defcustom insert-shebang-header-scan-limit 6
  "Define how much initial characters to scan from starting for custom headers.
This is to avoid differentiating header `#include <stdio.h>` with
`#include <linux/modules.h>` or `#include <strings.h>`."
  :type '(integer :tag "Limit")
  :group 'insert-shebang)

(defcustom insert-shebang-track-ignored-filename "~/.insert-shebang.log"
  "Filepath where list of ignored files are stored.
Set to nil if you do not want to keep log of ignored files."
  :type '(string)
  :group 'insert-shebang)

(defun insert-shebang-get-extension-and-insert (filename)
  "Get extension from FILENAME and insert shebang.
FILENAME is a buffer name from which the extension is to be
extracted."
  (if (file-name-extension filename)
      (let ((file-extn (replace-regexp-in-string "[\<0-9\>]" ""
                                                 (file-name-extension filename))))
        ;; check if this extension is ignored
        (if (car (member file-extn insert-shebang-ignore-extensions))
            (progn (message "Extension ignored"))
          ;; if not, check in extension list
          (progn
            (if (car (assoc file-extn insert-shebang-custom-headers))
                (progn ;; insert custom header
                  (let ((val (cdr (assoc file-extn insert-shebang-custom-headers))))
                    (if (= (point-min) (point-max))
                        ;; insert custom-header at (point-min)
                        (insert-shebang-custom-header val)
                      (progn
                        (insert-shebang-scan-first-line-custom-header val)))))
              (progn
                ;; get value against the key
                (if (car (assoc file-extn insert-shebang-file-types))
                    ;; if key exists in list 'insert-shebang-file-types'
                    (progn
                      ;; set variable val to value of key
                      (let ((val (cdr (assoc file-extn insert-shebang-file-types))))
                        ;; if buffer is new
                        (if (= (point-min) (point-max))
                            (insert-shebang-eval val)
                          ;; if buffer has something, then
                          (progn
                            (insert-shebang-scan-first-line-eval val)))))
                  ;; if key don't exists
                  (progn
                    (message "Can't guess file type. Type: 'M-x customize-group RET \
insert-shebang' to add/customize"))))))))))

(defun insert-shebang-eval (val)
  "Insert shebang with prefix 'eval' string in current buffer.
With VAL as an argument."
  (with-current-buffer (buffer-name)
    (goto-char (point-min))
    (insert (format "#!%s %s" insert-shebang-env-path val))
    (newline)
    (goto-char (point-min))
    (end-of-line)))

(defun insert-shebang-custom-header (val)
  "Insert custom header.
With VAL as an argument."
  (with-current-buffer (buffer-name)
    (goto-char (point-min))
    (insert val)
    (newline)
    (goto-char (point-min))
    (end-of-line)))

(defun insert-shebang-scan-first-line-eval (val)
  "Scan very first line of the file.
With VAL as an argument and look if it has matching shebang-line."
  (save-excursion
    (goto-char (point-min))
    ;; search for shebang pattern
    (if (ignore-errors (re-search-forward "^#![ ]?\\([a-zA-Z_./]+\\)"))
        (message "insert-shebang: File has shebang line")
      ;; prompt user
      (if (y-or-n-p "File do not have shebang line, \
do you want to insert it now? ")
          (progn
            (insert-shebang-eval val))
        (progn
          (insert-shebang-log-ignored-files
           (replace-regexp-in-string "[\<0-9\>]" "" (original-buffer-name))))))))

(defun insert-shebang-scan-first-line-custom-header (val)
  "Scan very first line of the file and look if it has matching header.
With VAL as an argument."
  (save-excursion
    (goto-char (point-min))
    ;; search for shebang pattern
    (if (ignore-errors
          (re-search-forward
           (format "^%s"
                   (substring val 0 insert-shebang-header-scan-limit))))
        (message "insert-shebang: File has header")
      ;; prompt user
      (if (y-or-n-p "File do not have header, do you want to insert it now? ")
          (progn
            (goto-char (point-min))
            (insert-shebang-custom-header val))
        (progn
          (insert-shebang-log-ignored-files
           (replace-regexp-in-string "[\<0-9\>]" "" (original-buffer-name))))))))

(defun insert-shebang-read-log-file (log-file-path)
  "Return a list of ignored files.
LOG-FILE-PATH is set in `insert-shebang-track-ignored-filename'"
  (with-temp-buffer
    (insert-file-contents log-file-path)
    ;; every new line is treated as an element.
    (split-string (buffer-string) "\n" t)))

(defun insert-shebang-write-log-file (log-file-path log-file-list)
  "Write list of files to be ignored to log file.
LOG-FILE-PATH is set in `insert-shebang-track-ignored-filename'
and LOG-FILE-LIST is a list of ignored files with fullpath."
  (with-temp-buffer
    ;; every element on a new line.
    (insert (mapconcat 'identity log-file-list "\n"))
    (when (file-writable-p log-file-path)
      (write-region (point-min)
                    (point-max)
                    log-file-path))))

(defun insert-shebang-create-log-file (logfile)
  "Function to create log file if does not exist.
LOGFILE name is defined in `insert-shebang-track-ignored-filename'."
  (if (not (file-exists-p (expand-file-name logfile)))
      (write-region 1 1 (expand-file-name logfile) t)))

(defun insert-shebang-log-ignored-files (filename)
  "Keep log of ignored files.
Ignore them on next visit.
FILENAME is `buffer-name'."
  ;; if `insert-shebang-track-ignored-filename' is `nil', don't track
  ;; ignored files.
  (if (not (equal insert-shebang-track-ignored-filename nil))
      (progn
        ;; if file not exist, create it
        (insert-shebang-create-log-file insert-shebang-track-ignored-filename)
        ;; set variables
        (let* ((log-file-path (expand-file-name
                               insert-shebang-track-ignored-filename))
               (log-file-list (insert-shebang-read-log-file log-file-path)))
          ;; add new 'ignored' file to the list
          (add-to-list 'log-file-list (expand-file-name filename))
          ;; Updated list in the log-file
          ;; (message "%s" log-file-list)
          (insert-shebang-write-log-file log-file-path log-file-list)))))

(defun insert-shebang-open-log-buffer ()
  "Open log of ignored file(s) in a separate buffer for editing."
  (interactive "*")
  (when (file-readable-p insert-shebang-track-ignored-filename)
    (find-file-other-window insert-shebang-track-ignored-filename)))

(defun original-buffer-name ()
  "Get un-uniquified buffer name."
  (file-name-nondirectory (buffer-file-name)))

;;;###autoload
(defun insert-shebang ()
  "Insert shebang line automatically.
Calls function `insert-shebang-get-extension-and-insert'.  With argument as
`buffer-name'."
  (interactive "*")
  ;; if `insert-shebang-track-ignored-filename' is `nil', don't track
  ;; ignored files.
  (if (not (equal insert-shebang-track-ignored-filename nil))
      (progn
        ;; if file not exist, create it
        (insert-shebang-create-log-file insert-shebang-track-ignored-filename)
        ;; ignore current-buffer, if it's path exist in ignored file list.
        (let* ((log-file-path (expand-file-name
                               insert-shebang-track-ignored-filename))
               (log-file-list (insert-shebang-read-log-file log-file-path))
               (filename (replace-regexp-in-string "[\<0-9\>]" ""
                                                   (expand-file-name
                                                    (original-buffer-name)))))
          (if (member filename log-file-list)
              ;; do nothing.
              (progn)
            ;; call `insert-shebang-get-extension-and-insert'.
            (progn
              (insert-shebang-get-extension-and-insert (original-buffer-name))))))
    (insert-shebang-get-extension-and-insert (original-buffer-name))))

;;;###autoload(add-hook 'find-file-hook 'insert-shebang)

(provide 'insert-shebang)
;;; insert-shebang.el ends here
