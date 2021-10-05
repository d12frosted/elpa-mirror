;;; dired-recent.el --- Dired visited paths history     -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Wojciech Siewierski

;; Author: Wojciech Siewierski <wojciech dot siewierski at onet dot pl>
;; URL: https://github.com/vifon/dired-recent.el
;; Package-Version: 20211004.1924
;; Package-Commit: a376f53e42fdca80c3286e8111578c65c64b0711
;; Keywords: files
;; Version: 0.9
;; Package-Requires: ((emacs "24"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A simple history keeping for dired buffers.  All the visited
;; directories get saved for reuse later.  Works great with Ivy and
;; other `completing-read' replacements.

;;  HOW TO USE IT:
;;
;;   (require 'dired-recent)
;;   (dired-recent-mode 1)
;;
;;  C-x C-d (`dired-recent-open')

;;; Code:

(require 'seq)

(defgroup dired-recent nil
  "Dired visited paths history."
  :group 'dired)

(defvar dired-recent-directories nil
  "List of the directories recently visited with `dired'.")

(defcustom dired-recent-directories-file (locate-user-emacs-file "dired-history")
  "File with the directories recently visited with dired."
  :type 'file)

(defcustom dired-recent-ignored-prefix nil
  "Directories ignored by `dired-recent-mode'.

A single string or list of strings.  Prefixes ignored by
`dired-recent-mode'.  Should include the trailing slash if the
prefix should be treated as a complete directory."
  :type '(repeat directory))

(defcustom dired-recent-max-directories nil
  "How many last directories should be remembered.

nil means to remember all."
  :type '(choice
          (const :tag "All" nil)
          (integer)))

(defcustom dired-recent-add-virtual-listings nil
  "Whether to add virtual listings to history.

If this option is nil special dired buffers created by
processes (see `find-dired') or created by passing a list to
`dired' are ignored."
  :type 'boolean)

(defvar find-program)
(defvar find-args)

(eval-when-compile
  ;; Ensure we can dynamically let-bind this even when compiled with lexical-let
  (defvar selectrum-should-sort))

;;;###autoload
(defun dired-recent-open ()
  "Show the dired history.  See: `dired-recent-mode'."
  (interactive)
  (unless dired-recent-directories
    (dired-recent-load-list))
  (let* ((selectrum-should-sort nil)
         (label (completing-read "Dired recent: " dired-recent-directories))
         (res (or (get-text-property
                   0 'dired-recent-restore-file-list
                   ;; Get from original string stored in list, completing-read
                   ;; strips the properties.
                   (car (member label dired-recent-directories)))
                  label)))
    (cond ((functionp res)
           (funcall res nil nil)
           (when (equal (buffer-name) "*Find*")
             ;; Message command after finish.
             (let* ((proc (get-buffer-process (current-buffer)))
                    (sentinel (process-sentinel proc)))
               (set-process-sentinel
                proc
                (lambda (proc state)
                  (funcall sentinel proc state)
                  (message "%s Command was: %s %s"
                           (current-message)
                           find-program find-args))))))
          ((or (stringp res)
               (consp res))
           (dired res)))))

(defun dired-recent-ignored-p (path prefix)
  "Check if PATH starts with PREFIX and should be ignored by the dired history.

PREFIX is a list of paths that should not be stored in the dired history."
  (when prefix
    (or (string-prefix-p (car prefix) path)
        (dired-recent-ignored-p path (cdr prefix)))))

(defun dired-recent-path-save (&optional path)
  "Add dired listing to `dired-recent-directories'.

PATH can be string or a list of format as the first argument to
`dired'.

If PATH is not given add listing according to `current-buffer'
using `dired-recent-get-buffer-label'.

Remove the last elements as appropriate according to
`dired-recent-max-directories'."
  (let* ((label (cond ((stringp path)
                       (dired-recent-get-label path))
                      ((consp path)
                       (dired-recent-get-list-label path))
                      ((not path)
                       (dired-recent-get-buffer-label (current-buffer))))))
    (when label
      (setq dired-recent-directories
            (let ((new-list (cons label
                                  (delete label dired-recent-directories))))
              (if dired-recent-max-directories
                  (seq-take new-list dired-recent-max-directories)
                new-list))))))

(defun dired-recent-get-process-label (&optional buf)
  "Get label for process buffer BUF.

BUF is a dired buffer with an associated process. The returned
label is supposed to be added to `dired-recent-directories'."
  (with-current-buffer (or buf (current-buffer))
    (let ((label (format "%s:%s"
                         (buffer-name)
                         ;; Indicate process directory in
                         ;; history name.
                         (abbreviate-file-name
                          default-directory))))
      ;; `revert-buffer-function' is set after `dired-mode'
      ;; call is finished, see `find-dired'.
      (run-at-time
       0 nil
       (lambda ()
         (when (buffer-live-p buf)
           (put-text-property
            0 1 'dired-recent-restore-file-list
            (buffer-local-value
             'revert-buffer-function
             buf)
            label))))
      label)))

(defun dired-recent-get-list-label (lst)
  "Get label for dired listing LST.

LST is a list of format as first argument to `dired'. The
returned label is supposed to be added to
`dired-recent-directories'."
  (let ((label (file-name-nondirectory (car lst))))
    (put-text-property
     0 1 'dired-recent-restore-file-list
     (cons (copy-sequence label)
           (cdr lst))
     label)
    label))

(defun dired-recent-get-label (path)
  "Get label for path PATH.

Label is supposed to be added to `dired-recent-directories'."
  (unless (dired-recent-ignored-p
           (file-name-as-directory path)
           dired-recent-ignored-prefix)
    path))

(defun dired-recent-get-buffer-label (&optional buf)
  "Get label for dired buffer BUF.

BUF is a dired buffer and defaults to `current-buffer'.

Label is supposed to be added to `dired-recent-directories'. See
`dired-recent-add-virtual-listings' to control which listings are
ignored."
  (with-current-buffer (or buf (current-buffer))
    (let ((path (if dired-recent-add-virtual-listings
                    dired-directory
                  default-directory)))
      (cond ((and (derived-mode-p 'dired-mode)
                  (get-buffer-process (current-buffer)))
             (when dired-recent-add-virtual-listings
               (dired-recent-get-process-label (current-buffer))))
            ((consp path)
             (when dired-recent-add-virtual-listings
               (dired-recent-get-list-label path)))
            ((stringp path)
             (dired-recent-get-label path))))))

;;; The default C-x C-d (`list-directory') is utterly useless. I took
;;; the liberty to use this handy keybinding.
(defvar dired-recent-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-x C-d") #'dired-recent-open)
    map))

(defun dired-recent-load-list ()
  "Load the dired history from `dired-recent-directories-file'."
  (interactive)
  (when (file-readable-p dired-recent-directories-file)
    (with-temp-buffer
      (insert-file-contents dired-recent-directories-file)
      (goto-char (point-min))
      (setq dired-recent-directories (read (current-buffer))))))

(defun dired-recent-cleanup ()
  "Remove nonexistent directories from `dired-recent-directories'.

Skips (preserves) the remote files as checking them would be
potentially slow."
  (interactive)
  (setq dired-recent-directories
        (seq-filter (lambda (x)
                      (or (file-remote-p x)
                          (file-directory-p x)))
                    dired-recent-directories)))

(defun dired-recent-save-list ()
  "Save the dired history to `dired-recent-directories-file'."
  (interactive)
  (with-temp-file dired-recent-directories-file
    (let ((print-length nil)
          (print-level nil))
      (prin1 dired-recent-directories (current-buffer)))))

;;;###autoload
(define-minor-mode dired-recent-mode
  "Toggle `dired-recent-mode' on or off.
Turn `dired-recent-mode' if ARG is positive, off otherwise.
Turning it on makes dired save each opened path."
  :keymap dired-recent-mode-map
  :global t
  :require 'dired-recent
  (if dired-recent-mode
      (progn
        (dired-recent-load-list)
        (add-hook 'dired-mode-hook #'dired-recent-path-save)
        (add-hook 'kill-emacs-hook #'dired-recent-save-list))
    (remove-hook 'dired-mode-hook #'dired-recent-path-save)
    (remove-hook 'kill-emacs-hook #'dired-recent-save-list)
    (dired-recent-save-list)))


(provide 'dired-recent)
;;; dired-recent.el ends here
