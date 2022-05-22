;;; passmm.el --- A minor mode for pass (Password Store).  -*- lexical-binding: t -*-

;; Copyright (C) 2016-2021 Peter Jones <pjones@devalot.com>

;; Author: Peter Jones <pjones@devalot.com>
;; Homepage: https://github.com/pjones/passmm
;; Package-Requires: ((emacs "24.4") (password-store "0"))
;; Package-Version: 20210109.8
;; Package-Commit: d78d1bf4f397180d2256248df589f33aafb4c8b4
;; Version: 0.4.2
;;
;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;; This is a minor mode that uses `dired' to display all password
;; files from the password store.  It also contains an optional
;; interface for Ivy/Helm/Embark.

;;; License:
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Code:

(require 'dired)
(require 'embark nil t)
(require 'helm nil t)
(require 'password-store)

(defgroup passmm nil
  "A minor mode for pass (Password Store)."
  :version "25.3"
  :prefix "passmm-"
  :group 'applications)

(defcustom passmm-store-directory
  (or (getenv "PASSWORD_STORE_DIR") "~/.password-store")
  "The directory pass uses to store passwords in."
  :type 'string
  :group 'passmm)

(defcustom passmm-kill-timeout
  (let ((env (getenv "PASSWORD_STORE_CLIP_TIME")))
    (if env (string-to-number env) 45))
  "How long to wait before removing a password from the kill ring."
  :type 'number
  :group 'passmm)

(defcustom passmm-password-length 15
  "Length of generated passwords."
  :type 'integer
  :group 'passmm)

(defcustom passmm-completion-package 'ivy
  "Which minibuffer completion framework to use."
  :type '(choice
          (const :tag "None" nil)
          (const :tag "Ivy"  ivy)
          (const :tag "Helm" helm))
  :group 'passmm)

;;; Nothing interesting after this point.
(defvar passmm-buffer-name "*passwords*"
  "Name to use for the dired buffer.")

(defvar passmm-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "C-c +")      #'passmm-generate-password)
    (define-key map (kbd "RET")        #'passmm-edit-entry)
    (define-key map (kbd "C-<return>") #'passmm-kill-password)
    map)
  "Default keymap for passmm.")

;;;###autoload
(defun passmm-list-passwords ()
  "List all passwords using a `dired' buffer.

The created `dired' buffer will have `passmm' running inside it.
If a `passm' buffer already exists it is made to be the current
buffer and refreshed."
  (interactive)
  (let ((buf (or (get-buffer passmm-buffer-name)
                 (dired-noselect (expand-file-name passmm-store-directory)
                                 (concat dired-listing-switches " -R")))))
    (if (string= (buffer-name buf) passmm-buffer-name)
        (with-current-buffer buf
          (revert-buffer))
      (with-current-buffer buf
        (rename-buffer passmm-buffer-name)
        (passmm-mode 1)))
    (switch-to-buffer buf)))

;;;###autoload
(defun passmm-completing-read ()
  "Prompt for a password and then put it in the `kill-ring'."
  (interactive)
  (cond
   ((and (fboundp 'ivy-read) (eq passmm-completion-package 'ivy))
    (ivy-read "Password: " (password-store-list)
              :action 'passmm-maybe-kill-password
              :caller 'passmm-completing-read
              :require-match nil
              :history 'passmm-completing-read-history))
   ((and (fboundp 'helm) (eq passmm-completion-package 'helm))
    (helm :sources 'passmm-helm-source
          :buffer "*helm-passmm*"))
   (t
    (passmm-maybe-kill-password
     (completing-read
      "Password: "
      (lambda (string predicate action)
        (if (eq action 'metadata)
            '(metadata (category . password))
          (complete-with-action
           action (password-store-list) string predicate))))))))

(when (fboundp 'ivy-set-actions)
  (ivy-set-actions
   'passmm-completing-read
   '(("k" passmm-maybe-kill-password "Kill Password")
     ("e" passmm-edit-entry-direct "Edit Password"))))

(when (boundp 'embark-keymap-alist)
  (defvar embark-password-actions
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "e") #'passmm-edit-entry-direct)
      (define-key map (kbd "k") #'passmm-maybe-kill-password)
      map)
    "Keymap actions for passwords in the password-store.")
  (add-to-list
   'embark-keymap-alist
   '(password . embark-password-actions)))

(defvar passmm-helm-source
  (when (fboundp 'helm)
    (helm-make-source "Password File" 'helm-source-sync
      :candidates #'password-store-list
      :action '(("Kill Password" . passmm-kill-password)
                ("Edit Password" . passmm-edit-entry-direct))))
  "Internal variable to track password files for Helm.")

(defun passmm-edit-entry (entry &optional keep-password)
  "Edit a password file for ENTRY.

If ENTRY is nil, use the file under point in the `dired' buffer.

The buffer will be narrowed so that it doesn't actually show the
password (the first line).  If KEEP-PASSWORD is non-nil then no
narrowing will be used and the entire file will be shown."
  (interactive (list (dired-get-file-for-visit)
                     current-prefix-arg))
  (passmm-edit-entry-direct entry keep-password)
  ;; Entry might be a directory in the dired buffer:
  (when (and (derived-mode-p 'dired-mode)
             (file-directory-p entry))
    (dired-maybe-insert-subdir entry)))

(defun passmm-edit-entry-direct (entry &optional keep-password)
  "Internal version of `passmm-edit-entry'.
ENTRY is a password entry.  KEEP-PASSWORD, when non-nil, means don't
narrow the file buffer."
  (interactive "fPassword: ")
  (let ((name (passmm-entry-to-file-name entry)))
    (when (and (file-exists-p name)
               (not (file-directory-p name)))
      (find-file name)
      (when (not keep-password)
        (passmm-narrow-buffer (current-buffer))))))

(defun passmm-maybe-kill-password (entry)
  "Kill ENTRY if it exists, otherwise offer to create it."
  (interactive "fPassword: ")
  (let ((file (passmm-entry-to-file-name entry)))
    (if (and (file-exists-p file) (not (file-directory-p file)))
        (passmm-kill-password entry)
      (when (yes-or-no-p (format "Password %s doesn't exist, create it? " entry))
        (let* ((callback (lambda () (passmm-kill-password entry)))
               (store (expand-file-name passmm-store-directory))
               (path (concat (file-name-as-directory store) entry))
               (name (file-relative-name path store)))
          (passmm-pass callback "generate" name
                       (number-to-string passmm-password-length)))))))

(defun passmm-kill-password (entry)
  "Store a password on the kill ring for ENTRY.

The password is taken from the file that is at point.  After
`passmm-kill-timeout' seconds, the password will be removed from
the kill ring and the system clipboard.

If SHOW-ENTRY is non-nil also display the password file narrowed
so that it doesn't show the password line."
  (interactive (list (dired-get-file-for-visit)))
  (let ((password (passmm-get-password entry))
        history-pointer)
    (kill-new password)
    (setq history-pointer kill-ring-yank-pointer)
    (message "Copied %s to clipboard. Will clear in %s seconds."
             entry passmm-kill-timeout)
    (run-at-time passmm-kill-timeout nil
      (lambda ()
        ;; This is a bit of a mess.  We need to figure out if
        ;; the system clipboard still contains the original
        ;; password, and if so remove it.  However, if the
        ;; clipboard hasn't changed since we last set it then
        ;; Emacs reports the system clipboard as `nil'.
        (when (and interprogram-paste-function interprogram-cut-function)
          (let ((clipboard (funcall interprogram-paste-function)))
            (when (or (string-equal password clipboard)
                      (and (not clipboard)
                           (eq history-pointer kill-ring-yank-pointer)))
              (funcall interprogram-cut-function ""))))
        (setcar history-pointer "")
        (message "Password cleared.")))))

(defun passmm-get-password (entry)
  "Return the password for ENTRY."
  (let ((name (passmm-entry-to-file-name entry)))
    (if (and (file-exists-p name) (not (file-directory-p name)))
        (save-excursion
          (with-temp-buffer
            (insert-file-contents name)
            (goto-char (point-min))
            (buffer-substring-no-properties
             (point) (progn (end-of-line) (point)))))
      (error "Password %s does not exist" entry))))

(defun passmm-generate-password (ask-dir)
  "Generate a password entry after asking for its name.

If ASK-DIR is non-nil then you'll be prompted for the name of
directory to store the entry in.  Otherwise it's taken from the
current directory in the `dired' buffer."
  (interactive "P")
  (let* ((store (expand-file-name passmm-store-directory))
         (adir (if (and (string= major-mode "dired-mode") (not ask-dir))
                   (dired-current-directory)
                 (read-directory-name "New Password Location: " store)))
         (rdir (file-relative-name adir store))
         (name (read-string (concat "Password Name (in " rdir "): ")))
         (jump (lambda nil (dired-goto-file (concat adir name ".gpg")))))
    (passmm-pass jump "generate" (concat (file-name-as-directory rdir) name)
                 (number-to-string passmm-password-length))))

(defun passmm-relative-path (path)
  "Make the absolute PATH relative to the password store."
  (let ((store (expand-file-name passmm-store-directory)))
    (file-name-sans-extension (file-relative-name path store))))

(defun passmm-narrow-buffer (buffer)
  "Narrow BUFFER so that it doesn't include the first line."
  (with-current-buffer buffer
    (widen)
    (goto-char (point-min))
    (forward-line)
    (forward-whitespace 1)
    (forward-line 0)
    (narrow-to-region (point) (point-max))))

(defun passmm-entry-to-file-name (entry)
  "Convert ENTRY into an absolute file name."
  (let* ((ext (file-name-extension entry))
         (file (if (and ext (string= ext "gpg")) entry
                 (concat entry ".gpg"))))
    (if (file-name-absolute-p entry) file
      (concat (file-name-as-directory
               (expand-file-name passmm-store-directory))
              file))))

(defun passmm-pass (callback &rest args)
  "Run the pass program and invoke CALLBACK when it completes.
ARGS are given directly to pass unchanged.  (Note: CALLBACK is
invoked with the passmm/dired buffer active.)"
  (let ((p (apply 'start-process "pass" "*pass*" "pass" args)))
    (set-process-sentinel p
      (lambda (_process _event)
        (save-excursion
          (with-current-buffer (or (get-buffer passmm-buffer-name)
                                   (passmm-list-passwords))
            (revert-buffer t t t)
            (and callback (funcall callback))))))))

(define-minor-mode passmm-mode
  "This is a minor mode that uses `dired' to display all password
files from the password store.  It supports the following features:

  * Generate new passwords, storing them in the current `dired'
    subdir (or optionally prompting for a directory).  (See:
    `passmm-generate-password'.)

  * Store the password of a file into the Emacs kill ring and the
    system clipboard for N seconds.  (See:
    `passmm-kill-password'.)

  * Edit a password file with narrowing so the password isn't
    show.  (See: `passmm-edit-entry'.)

Typically you'll want to start passmm by calling
`passmm-list-passwords'."
  :lighter " pass"
  :group 'applications
  :keymap passmm-mode-map)

(provide 'passmm)
;;; passmm.el ends here
