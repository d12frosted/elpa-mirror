;;; recently.el --- Track recently opened files to visit them again  -*- lexical-binding: t; -*-

;; Author: 10sr <8.slashes [at] gmail [dot] com>
;; URL: https://github.com/10sr/recently-el
;; Package-Version: 20210930.159
;; Package-Commit: 94b31f6bf1dab6af942948fec975e37424938a62
;; Version: 0.1
;; Keywords: utility files
;; Package-Requires: ((cl-lib "0.5") (emacs "24"))

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a copy of the GPL see https://www.gnu.org/licenses/gpl.txt.

;;; Commentary:

;; Track recently opened files to visit them again.

;; M-x recently-mode:  Start saving file paths on visiting them
;; M-x recently-show:  Display buffer that shows list of recently visited files


;;; Code:

(require 'cl-lib)

(defgroup recently nil
  "Recently visited files"
  :tag "Recently"
  :prefix "recently-"
  :group 'tools)
(defcustom recently-file
  (expand-file-name (locate-user-emacs-file "recently.el"))
  "File to store recent file list."
  :type 'string
  :group 'recently)

(defcustom recently-max
  100
  "Recently list max length."
  :type 'integer
  :group 'recently)

(defcustom recently-excludes
  '()
  "List of regexps for filenames excluded from the recent list."
  :type '(repeat string)
  :group 'recently)
(add-to-list 'recently-excludes
             (eval-when-compile (rx "/COMMIT_EDITMSG" eot)))

(defvar recently--list
  '()
  "Recently list.")

(defvar recently-file-mtime
  nil
  "Modified time of `recently-file' when last read file.")

(defun recently--write ()
  "Write to file."
  ;; Failsafe to avoid purging all existing entries
  (cl-assert recently--list)
  (let ((inhibit-message t)
        (print-length nil))
    (with-temp-buffer
      (prin1 recently--list
             (current-buffer))
      (write-region (point-min)
                    (point-max)
                    recently-file))))

(defun recently--read ()
  "Read file."
  (when (file-readable-p recently-file)
    (with-temp-buffer
      (insert-file-contents recently-file)
      (goto-char (point-min))
      (setq recently--list
            (read (current-buffer))))
    (setq recently-file-mtime
          (nth 5
               (file-attributes recently-file)))))

(defun recently--reload ()
  "Reload file and update `recently--list' value.

This function does nothing when there is no update to `recently-file' since last
read."
  (when (and (file-readable-p recently-file)
             (not (equal recently-file-mtime
                         (nth 5
                              (file-attributes recently-file)))))
    (recently--read)
    (cl-assert (equal recently-file-mtime
                      (nth 5
                           (file-attributes recently-file))))))

(defun recently-add (path)
  "Add PATH to list."
  (setq path
        (expand-file-name path))
  (when (cl-loop for re in recently-excludes
                 if (string-match re path) return nil
                 finally return t)
    (recently--reload)
    (let* ((l (cl-copy-list recently--list))
           (l (cl-remove-if-not 'stringp
                                l))
           (l (delete path
                      l))
           (l (cl-loop for e in l
                       unless (file-in-directory-p path e)
                       collect e))
           (l (cons path
                    l))
           (l (recently---truncate l
                                   recently-max)))
      (unless (equal recently--list
                     l)
        (setq recently--list l)
        (recently--write)
        (setq recently-file-mtime
              (nth 5
                   (file-attributes recently-file)))))))

(defun recently-list ()
  "Get latest recently opened file list."
  (recently--reload)
  recently--list)

(defun recently---truncate (list len)
  "Truncate LIST to LEN."
  (if (> (length list)
         len)
      (cl-subseq list
                 0
                 len)
    list))

(defun recently-hook-buffer-file-name ()
  "Add current file."
  (when buffer-file-name
    (recently-add buffer-file-name))
  ;; Return nil to call from `write-file-functions'
  nil)

(defun recently-hook-default-directory ()
  "Add current directory."
  (recently-add (expand-file-name default-directory)))

;;;###autoload
(define-minor-mode recently-mode
  "Track recently opened files.
When enabled it records recently opened file paths, and
view list and visit again via `recently-show' command."
  :global t
  :lighter " Rcntly"
  :require 'recently
  (let ((f (if recently-mode
               'add-hook
             'remove-hook)))
    (funcall f
             'find-file-hook
             'recently-hook-buffer-file-name)
    (funcall f
             'write-file-functions
             'recently-hook-buffer-file-name)
    (funcall f
             'after-set-visited-file-name-hook
             'recently-hook-buffer-file-name)
    (funcall f
             'dired-mode-hook
             'recently-hook-default-directory)))

;;;;;;;;;;;;;;;;
;; recently-show

(defvar recently-show-window-configuration nil
  "Used for internal.")

(defvar recently-show-abbreviate t
  "Non-nil means use `abbreviate-file-name' when listing recently opened files.")

;;;###autoload
(defun recently-show (&optional buffer-name)
  "Show buffet that lists recently opened files.
BUFFER-NAME, if given, should be a string for buffer to create."
  (interactive)
  (let ((bf (recently-show--create-buffer buffer-name)))
    (if bf
        (progn
          (setq recently-show-window-configuration (current-window-configuration))
          (pop-to-buffer bf))
      (message "No recent file!"))))

(defun recently-show--create-buffer (&optional buffer-name)
  "Create buffer listing recently files.
BUFFER-NAME, if given, should be a string for buffer to create."
  (let ((bname (or buffer-name
                   "*Recently*")))
    (when (get-buffer bname)
      (kill-buffer bname))
    (with-current-buffer (get-buffer-create bname)
      ;; (setq tabulated-list-sort-key (cons "Name" nil))
      (recently-show--set-tabulated-list-mode-variables)
      (recently-show-tabulated-mode)
      (current-buffer))))

(defun recently-show--set-tabulated-list-mode-variables ()
  "Set variables for `tabulated-list-mode'."
  (setq tabulated-list-entries
        (mapcar (lambda (f)
                  (list f
                        (vector (or (file-name-nondirectory f) "")
                                (if recently-show-abbreviate
                                    (abbreviate-file-name f)
                                  f))))
                (recently-list)
                ))
  (let ((max
         (apply 'max
                (mapcar (lambda (l)
                          (length (elt (cadr l) 0)))
                        tabulated-list-entries))))
    (setq tabulated-list-format
          `[("Name"
             ,(min max
                   30)
             t)
            ("Full Path" 0 t)])))

(defun recently-show-tabulated-find-file ()
  "Find file at point."
  (interactive)
  (let ((f (tabulated-list-get-id)))
    (cl-assert f nil "No entry at point")
    (recently-show-tabulated-close)
    (find-file f)))

(defun recently-show-tabulated-view-file ()
  "View file at point."
  (interactive)
  (let ((f (tabulated-list-get-id)))
    (cl-assert f nil "No entry at point")
    (recently-show-tabulated-close)
    (view-file f)))

(defun recently-show-tabulated-dired()
  "Open dired buffer of directory at point."
  (interactive)
  (let ((f (tabulated-list-get-id)))
    (cl-assert f nil "No entry at point")
    (recently-show-tabulated-close)
    (dired (if (file-directory-p f)
               f
             (or (file-name-directory f)
                 ".")))))

(defvar recently-show-tabulated-mode-map
  (let ((map (make-sparse-keymap)))
    (suppress-keymap map)
    (define-key map (kbd "C-m") 'recently-show-tabulated-find-file)
    (define-key map "v" 'recently-show-tabulated-view-file)
    (define-key map "@" 'recently-show-tabulated-dired)
    (define-key map (kbd "C-g") 'recently-show-tabulated-close)
    (define-key map "/" 'isearch-forward)
    map))

(define-derived-mode recently-show-tabulated-mode tabulated-list-mode "Recently-Show"
  "Major mode for browsing recently opened files and directories."
  (setq tabulated-list-padding 2)
  (add-hook 'tabulated-list-revert-hook
            'recently-show--set-tabulated-list-mode-variables
            nil
            t)
  (tabulated-list-init-header)
  (tabulated-list-print nil nil))

(defun recently-show-tabulated-close ()
  "Close `recently-show' window."
  (interactive)
  (kill-buffer (current-buffer))
  (set-window-configuration recently-show-window-configuration))


(provide 'recently)

;;; recently.el ends here
