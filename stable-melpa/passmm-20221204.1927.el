;;; passmm.el --- A minor mode for pass (Password Store)  -*- lexical-binding: t -*-

;; Copyright (C) 2016-2022 Peter Jones <pjones@devalot.com>

;; Author: Peter Jones <pjones@devalot.com>
;; Homepage: https://github.com/pjones/passmm
;; Package-Requires: ((emacs "25") (password-store "1.7.4"))
;; Package-Version: 20221204.1927
;; Package-Commit: 66691e301dff476eaff7c6e817ed9df96d4404c8
;; Version: 1.0.0
;;
;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;; This is a minor mode that uses `dired' to display all password
;; files from the password store.

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

(defcustom passmm--password-length 15
  "Length of generated passwords."
  :type 'integer
  :group 'passmm)

(defcustom passmm-hide-password t
  "Narrow password entries so the password is hidden."
  :type 'boolean
  :group 'passmm)

(defcustom passmm-prompt-action 'kill
  "What to do with a password selected from a completion menu."
  :type '(choice
          (const :tag "Kill the password" kill)
          (const :tag "Edit the password entry" open)
          (function))
  :group 'passmm)

(defcustom passmm-dired-action 'open
  "Action to perform when selecting a password entry from Dired."
  :type '(choice
          (const :tag "Kill the password" kill)
          (const :tag "Edit the password entry" open)
          (function))
  :group 'passmm)

;;; Nothing interesting after this point.
(defvar passmm-buffer-name "*passwords*"
  "Name to use for the Dired buffer.")

(defvar passmm-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "C-c +")      #'passmm-generate-password)
    (define-key map (kbd "RET")        #'passmm-dired-action)
    (define-key map (kbd "<return>")   #'passmm-dired-action)
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
(defun passmm-completing-read (&optional alt-action)
  "Prompt for a password and then do something with it.
The default action is taken from `passmm-prompt-action'.

If ALT-ACTION is non-nil then perform the action not specified by
`passmm-prompt-action'.  For example, if `passmm-prompt-action'
is set to kill, the the alt action would be to open the file."
  (interactive "P")
  (let ((entry (completing-read "Password: " (password-store-list))))
    (passmm--act-on-entry entry passmm-prompt-action alt-action)))

(defun passmm-dired-action (entry &optional keep-password)
  "Perform the default `dired' action for ENTRY.

The default action is taken from `passmm-dired-action'.

If ENTRY is nil, use the file under point in the `dired' buffer.

If KEEP-PASSWORD is non-nil then no narrowing will be used and
the entire file will be shown.  In other words, treat
`passmm-hide-password' as if it were nil."
  (interactive (list (dired-get-file-for-visit)
                     current-prefix-arg))
  (let ((passmm-hide-password (if keep-password nil
                                passmm-hide-password)))
    (if (and (derived-mode-p 'dired-mode)
             (file-directory-p entry))
        (dired-maybe-insert-subdir entry)
      (passmm--act-on-entry entry passmm-dired-action))))

(defun passmm--edit-entry-direct (entry)
  "Internal version of `passmm-edit-entry'.
ENTRY is a password entry."
  (let ((name (passmm--entry-to-file-name entry)))
    (when (and (file-exists-p name)
               (not (file-directory-p name)))
      (find-file name)
      (when passmm-hide-password
        (passmm--narrow-buffer (current-buffer))))))

(defun passmm-kill-password (entry)
  "Store a password on the kill ring for ENTRY.

The password is taken from the file that is at point.  After
`passmm-kill-timeout' seconds, the password will be removed from
the kill ring and the system clipboard."
  (interactive (list (dired-get-file-for-visit)))
  (let ((password (passmm--get-password entry))
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

(defun passmm--get-password (entry)
  "Return the password for ENTRY."
  (let ((name (passmm--entry-to-file-name entry)))
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
    (passmm--pass jump "generate" (concat (file-name-as-directory rdir) name)
                 (number-to-string passmm--password-length))))

(defun passmm--narrow-buffer (buffer)
  "Narrow BUFFER so that it doesn't include the first line."
  (with-current-buffer buffer
    (widen)
    (goto-char (point-min))
    (forward-line)
    (forward-whitespace 1)
    (forward-line 0)
    (narrow-to-region (point) (point-max))))

(defun passmm--entry-to-file-name (entry)
  "Convert ENTRY into an absolute file name."
  (let* ((ext (file-name-extension entry))
         (file (if (and ext (string= ext "gpg")) entry
                 (concat entry ".gpg"))))
    (if (file-name-absolute-p entry) file
      (concat (file-name-as-directory
               (expand-file-name passmm-store-directory))
              file))))

(defun passmm--pass (callback &rest args)
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

(defun passmm--act-on-entry (entry action &optional use-alt)
  "Perform ACTION on ENTRY.
If USE-ALT is non-nil then perform the opposite action."
  (let ((real-action
         (if use-alt
             (pcase action
               ('kill 'open)
               ('open 'kill)
               (other other))
           action)))
    (pcase real-action
      ('kill (passmm-kill-password entry))
      ('open (passmm--edit-entry-direct entry))
      ((pred functionp) (funcall real-action entry))
      (_ (passmm-kill-password entry)))))

(define-minor-mode passmm-mode
  "Use Dired to show the password store.

This is a minor mode that uses `dired' to display all password
files from the password store.  It supports the following features:

  * Generate new passwords, storing them in the current `dired'
    subdir (or optionally prompting for a directory).  (See:
    `passmm-generate-password'.)

  * Store the password of a file into the Emacs kill ring and the
    system clipboard for N seconds.  (See:
    `passmm-kill-password'.)

  * Edit a password file with narrowing so the password isn't
    show.  (See: `passmm-dired-action'.)

Typically you'll want to start passmm by calling
`passmm-list-passwords'."
  :lighter " pass"
  :group 'applications
  :keymap passmm-mode-map)

(provide 'passmm)
;;; passmm.el ends here
