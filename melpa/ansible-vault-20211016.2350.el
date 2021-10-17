;;; ansible-vault.el --- Minor mode for editing ansible vault files

;; Copyright (C) 2016-2019 Zachary Elliott
;;
;; Authors: Zachary Elliott <contact@zell.io>
;; Maintainer: Zachary Elliott <contact@zell.io>
;; URL: http://github.com/zellio/ansible-vault-mode
;; Package-Version: 20211016.2350
;; Package-Commit: 71c783384de8f2db05453db0dd3ff0cd256d6ea9
;; Created: 2016-09-25
;; Version: 0.4.2
;; Keywords: ansible, ansible-vault, tools
;; Package-Requires: ((emacs "24.3") (seq "2.20"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;;

;;; License:

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3 of the License, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.

;; You should have received a copy of the GNU General Public License along
;; with GNU Emacs; see the file COPYING.  If not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
;; USA.

;;; Code:

(require 'seq)

(defconst ansible-vault-version "0.4.2"
  "`ansible-vault' version.")

(defgroup ansible-vault nil
  "`ansible-vault' application group."
  :group 'applications
  :link '(url-link :tag "Website for ansible-vault-mode"
                   "https://github.com/zellio/ansible-vault-mode")
  :prefix "ansible-vault-")

(defcustom ansible-vault-command "ansible-vault"
  "`ansible-vault' shell command."
  :type 'string
  :group 'ansible-vault)

(define-obsolete-variable-alias
  'ansible-vault-pass-file 'ansible-vault-password-file "0.4.0"
  "Migrated to unify naming conventions.")

(defcustom ansible-vault-password-file (expand-file-name ".vault-pass" "~")
  "File containing `ansible-vault' password.

This file is used for encryption and decryption of ansible vault
files.  If it is set to nil `ansible-vault-mode' will prompt
you for a password."
  :type 'string
  :group 'ansible-vault)

(defvar ansible-vault--file-header-regex
  (rx line-start
      "$ANSIBLE_VAULT;1." (in (?0 . ?2)) ";AES" (optional "256")
      (optional ";" (one-or-more any))
      line-end)
  "Regex for `ansible-vault' header for identifying of encrypted buffers.")

(defvar ansible-vault--point 0
  "Internal variable for `ansible-vault-mode'.

This is used to store the point between the encryption and
decryption process on save to maintain continuity.")

(defvar ansible-vault--password-file-list '()
  "Internal variable for `ansible-vault-mode'.

This is used to store the list of password files that ansible
vault must clear on close.")

(defvar ansible-vault--password-file '()
  "Internal variable for `ansible-vault-mode'.

This is used to store the location of the ansible vault password
file as we don't trust the user.")

(defvar ansible-vault--password '()
  "Internal variable for `ansible-vault-mode'.

This is used to store the password for a file in memory so we
don't have to keep asking the user for it.")

;;;###autoload
(defun ansible-vault--is-vault-file ()
  "Identifies if the current buffer is an encrypted `ansible-vault' file.

This function just looks to see if the first line of the buffer
is matched by `ansible-vault--file-header-regex'."
  (save-excursion
    (goto-char (point-min))
    (let ((file-header (thing-at-point 'line t)))
      (zerop (string-match ansible-vault--file-header-regex file-header)))
    ))

(defun ansible-vault--error-buffer ()
  "Generate or return `ansible-vault' error report buffer."
  (or (get-buffer "*ansible-vault-error*")
      (let ((buffer (get-buffer-create "*ansible-vault-error*")))
        (save-current-buffer
          (set-buffer buffer)
          (setq-local buffer-read-only t))
        buffer)))

(defun ansible-vault--shell-command (subcommand &optional pass-file)
  "Generate Ansible Vault command with common args and SUBCOMMAND.

The command \"ansible-vault\" is called with the same arguments whether
decrypting, encrypting a file, or encrypting a string.  This function
generates the shell string for any such command.

SUBCOMMAND is the \"ansible-vault\" subcommand to use.

PASS-FILE is the path to the vault password file on disk."
  (concat (format "%s %s --output=-" ansible-vault-command subcommand) " "
          (when pass-file (format "--vault-password-file=%S" pass-file))))

(defun ansible-vault--process-config-files ()
  "Attempts to discover if vault_password_file is defined in any
known Ansible Vault configuration file.

This function is patching over the fact that ansible-vault cannot
handle multiple definitions for vault_password_file.  This means
we need to figure out if it is defined before adding a
commandline flag for it."
  (let ((config-file
         (seq-find (lambda (file) (and file (file-readable-p file) file))
                   (list (getenv "ANSIBLE_CONFIG")
                         "ansible.cfg"
                         "~/.ansible.cfg"
                         "/etc/ansible/ansible.cfg"))))
    (unless (= (length config-file) 0)
      (with-temp-buffer
        (insert-file-contents config-file)
        (let ((content (buffer-string)))
          (string-match
           (rx line-start "vault_password_file"
               (zero-or-more blank) "=" (zero-or-more blank)
               (group (minimal-match (one-or-more not-newline)))
               (zero-or-more blank) (zero-or-more ";" (zero-or-more not-newline))
               line-end) content)
          (match-string 1 content))))
    ))

(defun ansible-vault--guess-password-file ()
  "Attempts to locate an already configured password file.

Ansible Vault has several locations to store the location of its password
file.  This method searches several of them in order of: the ENV var
ANSIBLE_VAULT_PASSWORD_FILE, the ansible vault configuration files, and the
minor-mode configured value.  If that fails, it will prompt the user for
input."
  (interactive)
  (let ((env-val (getenv "ANSIBLE_VAULT_PASSWORD_FILE")))
    (cond ((> (length env-val) 0) env-val)
          ((> (length (ansible-vault--process-config-files)) 0) '())
          (t (or ansible-vault-password-file (ansible-vault--request-password))))
    ))

(defun ansible-vault--request-password ()
  "Requests vault password from the user.

This method writes the password to disk temporarily.  The file's permission
is set to 0600."
  (interactive)
  (unless ansible-vault--password
    (setq-local ansible-vault--password (read-passwd "Vault password: "))
    (setq-local ansible-vault--password-file (make-temp-file "ansible-vault-mode-password-file-" ))
    (set-file-modes ansible-vault--password-file #o600)
    (append-to-file ansible-vault--password nil ansible-vault--password-file)
    (push ansible-vault--password-file ansible-vault--password-file-list))
  ansible-vault--password-file)

(defun ansible-vault--flush-password ()
  "Clears internal password state."
  (when ansible-vault--password
    (delete-file ansible-vault--password-file)
    (delete ansible-vault--password-file ansible-vault--password-file-list)
    (setq-local ansible-vault--password nil)
    (setq-local ansible-vault--password-file nil)))

(defmacro ansible-vault--env-mask (env &optional val &rest body)
  "Masks system ENV as VAL for BODY execution."
  (let ((env-val (make-symbol "env-val")))
    `(let ((,env-val (getenv ,env)))
       (unwind-protect
           (progn
             (setenv ,env ,val)
             ,@body)
         (setenv ,env ,env-val)))))

(defun ansible-vault--execute-on-region (command &optional start end buffer error-buffer)
  "In place execution of a given COMMAND using `ansible-vault'.

START defaults to `point-min'.
END defaults to `point-max'.
BUFFER defaults to current buffer.
ERROR-BUFFER defaults to `ansible-vault--error-buffer'."
  (let* ((inhibit-message t)
         (message-log-max nil)
         (start (or start (point-min)))
         (end (or end (point-max)))
         (ansible-vault-stdout (get-buffer-create "*ansible-vault-stdout*"))
         (ansible-vault-stderr (get-buffer-create "*ansible-vault-stderr*"))
         (password-file (ansible-vault--guess-password-file))
         (shell-command (ansible-vault--shell-command command password-file)))
    (unwind-protect
        (progn
          (ansible-vault--env-mask
           "ANSIBLE_VAULT_PASSWORD_FILE" nil
           (shell-command-on-region
            start end
            shell-command
            ansible-vault-stdout nil ansible-vault-stderr nil))
          (if (= (buffer-size ansible-vault-stderr) 0)
              (progn
                (delete-region start end)
                (insert-buffer-substring ansible-vault-stdout))
            (let ((inhibit-read-only t))
              (switch-to-buffer (ansible-vault--error-buffer))
              (goto-char (point-max))
              (insert shell-command "\n")
              (insert-buffer-substring ansible-vault-stderr)
              (insert "\n")

              ;; flush password on error (because probably the password
              ;; provided is wrong and we already saved it).
              (ansible-vault--flush-password))))
      (kill-buffer ansible-vault-stdout)
      (kill-buffer ansible-vault-stderr))
    ))

(defun ansible-vault-decrypt-current-buffer ()
  "In place decryption of `current-buffer' using `ansible-vault'."
  (ansible-vault--execute-on-region "decrypt"))

(defun ansible-vault-encrypt-current-buffer ()
  "In place encryption of `current-buffer' using `ansible-vault'."
  (ansible-vault--execute-on-region "encrypt"))

(defun ansible-vault-decrypt-region (start end)
  "In place decryption of region from START to END using `ansible-vault'."
  (interactive "r")
  (let ((inhibit-read-only t))
    ;; Restrict the following operations to the selected region.
    (narrow-to-region start end)
    ;; Delete the vault header, if any.
    (let ((end-of-first-line (progn (goto-char 1) (end-of-line) (point))))
      (goto-char 1)
      (when (re-search-forward (rx line-start "!vault |" line-end) end-of-first-line t)
        (replace-match "")
        (kill-line)))
    ;; Delete any leading whitespace in the region.
    (goto-char 1)
    (delete-horizontal-space)
    (while (= 0 (forward-line 1))
      (delete-horizontal-space))
    ;; Decrypt the region.
    (ansible-vault-decrypt-current-buffer)
    ;; Show the rest of the buffer.
    (widen)))

(defun ansible-vault-encrypt-region (start end)
  "In place encryption of region from START to END using `ansible-vault'."
  (interactive "r")
  (ansible-vault--execute-on-region "encrypt_string" start end))

(defvar ansible-vault-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Keymap for `ansible-vault' minor mode.")

(defun ansible-vault--before-save-hook ()
  "`before-save-hook' for files managed by `ansible-vault-mode'.

Saves the current position and encrypts the file before writing
to disk."
  (setq-local ansible-vault--point (point))
  (ansible-vault-encrypt-current-buffer))

(defun ansible-vault--after-save-hook ()
  "`after-save-hook' for files managed by `ansible-vault-mode'.

Decrypts the file, and returns the point to the position saved by
the `before-save-hook'."
  (ansible-vault-decrypt-current-buffer)
  (set-buffer-modified-p nil)
  (goto-char ansible-vault--point)
  (setq-local ansible-vault--point 0))

(defun ansible-vault--kill-buffer-hook ()
  "`kill-buffer-hook' for buffers managed by `ansible-vault-mode'.

Flushes saved password state."
  (when ansible-vault--password-file
    (ansible-vault--flush-password)))

;;;###autoload
(defun ansible-vault--kill-emacs-hook ()
  "`kill-emacs-hook' for Emacs when `ansible-vault-mode' is loaded.

Ensures deletion of ansible-vault generated password files."
  (dolist (file ansible-vault--password-file-list)
    (when (file-readable-p file)
      (message file)
      (delete-file file))
    ))

;;;###autoload
(define-minor-mode ansible-vault-mode
  "Minor mode for manipulating ansible-vault files"
  :lighter " ansible-vault"
  :keymap ansible-vault-mode-map
  :group 'ansible-vault

  (if ansible-vault-mode
      ;; Enable the mode
      (progn
        ;; Disable backups
        (setq-local backup-inhibited t)

        ;; Disable auto-save
        (if auto-save-default (auto-save-mode -1))

        ;; Decrypt the current buffer first if it needs to be
        (when (ansible-vault--is-vault-file)
          (ansible-vault-decrypt-current-buffer)
          (set-buffer-modified-p nil))

        ;; Add mode hooks
        (add-hook 'before-save-hook 'ansible-vault--before-save-hook t t)
        (add-hook 'after-save-hook 'ansible-vault--after-save-hook t t)
        (add-hook 'kill-buffer-hook 'ansible-vault--kill-buffer-hook t t))


    ;; Disable the mode
    (remove-hook 'after-save-hook 'ansible-vault--after-save-hook t)
    (remove-hook 'before-save-hook 'ansible-vault--before-save-hook t)
    (remove-hook 'kill-buffer-hook 'ansible-vault--kill-buffer-hook t)

    ;; Only re-encrypt the buffer if buffer is changed; otherwise revert
    ;; to on-disk contents.
    (if (and (buffer-modified-p) (not (ansible-vault--is-vault-file)))
        (ansible-vault-encrypt-current-buffer)
      (revert-buffer nil t nil))

    ;; Clean up password state
    (ansible-vault--flush-password)

    (if auto-save-default (auto-save-mode 1))

    (setq-local backup-inhibited nil)))

(add-hook 'kill-emacs-hook 'ansible-vault--kill-emacs-hook t)

(provide 'ansible-vault)

;;; ansible-vault.el ends here
