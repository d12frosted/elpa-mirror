;;; ansible-vault.el --- Minor mode for editing ansible vault files

;; Copyright (C) 2016-2021 Zachary Elliott
;;
;; Authors: Zachary Elliott <contact@zell.io>
;; Maintainer: Zachary Elliott <contact@zell.io>
;; URL: http://github.com/zellio/ansible-vault-mode
;; Package-Version: 20211119.1500
;; Package-Commit: 8da2ad658dbe94c71aad1c75d6fd22888338030c
;; Created: 2016-09-25
;; Version: 0.5.2
;; Keywords: ansible, ansible-vault, tools
;; Package-Requires: ((emacs "24.3"))

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

(eval-when-compile (require 'subr-x))

(defconst ansible-vault-version "0.5.2"
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

(defcustom ansible-vault-vault-id-alist '()
  "Associative list of strings containing (vault-id . password-file) pairs.

This list allows for managing `ansible-vault' password files via
the 1.2 vault-id syntax."
  :type '(alist :key-type string :value-type string)
  :group 'ansible-vault)

(defcustom ansible-vault-minor-mode-prefix "C-c a"
  "Chord prefix for ansible-vault minor mode."
  :type 'string
  :group 'ansible-vault)

;; Global vars
(defvar ansible-vault--password-file-list '()
  "Global variable for `ansible-vault-mode'.

List of generated password files that must be deleted on close.")

(defvar ansible-vault--sub-command-type-alist
  '(("create" . :encrypt)
    ("decrypt" . :decrypt)
    ("edit" . :encrypt)
    ("view" . :decrypt)
    ("encrypt" . :encrypt)
    ("encrypt_string" . :encrypt)
    ("rekey" . :unimplemented))
  "Internal variable for `ansible-vault-mode'.

Mapping of ansible-vault sub-commands to internal types for flag
generation.")

(defvar ansible-vault--file-header-regex
  (rx line-start
      "$ANSIBLE_VAULT;1." (in (?0 . ?2)) ";AES" (optional "256")
      (optional ";" (one-or-more any))
      line-end)
  "Regex for `ansible-vault' header for identifying of encrypted buffers.")

;; Buffer local vars
(defvar ansible-vault--header-format-id '()
  "Buffer local variable for `ansible-vault-mode'.")

(defvar ansible-vault--header-version '()
  "Buffer local variable for `ansible-vault-mode'.")

(defvar ansuble-vault--header-cipher-algorithm '()
  "Buffer local variable for `ansible-vault-mode'.")

(defvar ansible-vault--header-vault-id '()
  "Buffer local variable for `ansible-vault-mode'.")

(defvar ansible-vault--point 0
  "Buffer local variable for `ansible-vault-mode'.

Point for location continuity during encrypt and save.")

(defvar ansible-vault--password-file '()
  "Internal variable for `ansible-vault-mode'.

Path of the password file for current buffer.")

(defvar ansible-vault--vault-id '()
  "Internal variable for `ansible-vault-mode'.

Ansible vault-id, used for v1.2 encryption / decryption.")

(defvar ansible-vault--auto-encryption-enabled '()
  "Internal variable for `ansible-vault-mode'.

Ansible vault auto-encryption flag.  Tells the before / after
save hooks to treat ansible-vault file as encrypted on disk.")

;;;###autoload
(defun ansible-vault--fingerprint-buffer ()
  "Parse and store the ansible-vault header values."
  (save-excursion
    (goto-char (point-min))
    (let* ((first-line (string-trim-right (or (thing-at-point 'line t) "")))
           (header-tokens (split-string first-line ";" t))
           (format-id (car header-tokens))
           (version (cadr header-tokens))
           (cipher-algorithm (caddr header-tokens))
           (vault-id (cadddr header-tokens)))
      (when (string= "$ANSIBLE_VAULT" format-id)
        (setq-local
         ansible-vault--header-format-id format-id
         ansible-vault--header-version version
         ansuble-vault--header-cipher-algorithm cipher-algorithm
         ansible-vault--header-vault-id vault-id)))))

;;;###autoload
(defun ansible-vault--is-encrypted-vault-file ()
  "Identifies if the current buffer is an encrypted `ansible-vault' file.

This function just looks to see if the first line of the buffer
is matched by `ansible-vault--file-header-regex'."
  (save-excursion
    (goto-char (point-min))
    (let* ((file-header (or (thing-at-point 'line t) ""))
           (first-match
            (string-match ansible-vault--file-header-regex file-header)))
      (and first-match (zerop first-match)))))

(define-obsolete-variable-alias
  'ansible-vault--is-vault-file 'ansible-vault--is-encrypted-vault-file "0.4.2"
  "Renamed for semantic correctness.")

(defun ansible-vault--sub-command-type (sub-command)
  "Identify type of ansible-vault subcommand for flag generation.

SUB-COMMAND ansible-vault cli sub-command to type."
  (cdr (assoc sub-command ansible-vault--sub-command-type-alist)))

(defun ansible-vault--command-flags (sub-command)
  "Generate the command flags for calling `ansible-vault'.

SUB-COMMAND the sub-command of ansible vault as a string.  Valid
values can be found in `ansible-vault--sub-command-type-alist'."
  (let* ((type (ansible-vault--sub-command-type sub-command))
         (v1.2-p (or (string= ansible-vault--header-version "1.2")
                     ansible-vault--header-vault-id
                     ansible-vault--vault-id)))
    (append
     '("--output=-")
     (if v1.2-p
         (let* ((vault-id-pair (assoc ansible-vault--vault-id ansible-vault-vault-id-alist))
                (vault-id-str (concat (car vault-id-pair) "@" (cdr vault-id-pair))))
           (list
            (format "--vault-id=%S" vault-id-str)
            (when (eq type :encrypt) (format "--encrypt-vault-id=%S" ansible-vault--vault-id))))
       (list (format "--vault-password-file=%S" ansible-vault--password-file))))
    ))

(defun ansible-vault--shell-command (sub-command)
  "Generate Ansible Vault shell call for SUB-COMMAND.

The command \"ansible-vault\" flags are generated via the
`ansible-vault--command-flags' function.  The flag values are
dictated by the buffer local variables.

SUB-COMMAND is the \"ansible-vault\" subcommand to use."
  (let* ((command-flags (ansible-vault--command-flags sub-command)))
    (format "%s %s %s" ansible-vault-command sub-command
            (mapconcat 'identity command-flags " "))))

(defun ansible-vault--process-config-files ()
  "Locate vault_password_file definitions in ansible config files.

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

(defun ansible-vault--create-password-file (password)
  "Generate a temporary file to store PASSWORD.

The generated file is located in TMPDIR, and is marked read-only
for owner."
  (let* ((temp-file (make-temp-file "ansible-vault-secret-")))
    (set-file-modes temp-file #o0600)
    (append-to-file password nil temp-file)
    (set-file-modes temp-file #o0400)
    (setq-local ansible-vault--password-file temp-file)
    (push ansible-vault--password-file ansible-vault--password-file-list)
    temp-file))

(defun ansible-vault--request-password (password)
  "Prompt user a for the password for the current buffer.

PASSWORD ansible-vault password to be stored."
  (interactive
   (list (read-passwd "Vault Password: ")))
  (ansible-vault--create-password-file password))

(defun ansible-vault--request-vault-id (vault-id &optional password-file)
  "Prompt user for a vault-id for the current buffer.

If the vault-id doesn't have an associated password file, request
a password from the user as well.

VAULT-ID ansible-vault vault id.
PASSWORD-FILE path to the stored secret for provided VAULT-ID."
  (interactive "sVault Id: ")
  (let* ((vault-id-pair
          (or (assoc vault-id ansible-vault-vault-id-alist)
              (let* ((password-file (or password-file
                                        (call-interactively 'ansible-vault--request-password))))
                (car (push (cons vault-id password-file) ansible-vault-vault-id-alist)))))
         (password-file (or password-file (cdr vault-id-pair))))
    (setq-local
     ansible-vault--vault-id vault-id
     ansible-vault--password-file password-file)
    vault-id-pair))

(defun ansible-vault--flush-password-file ()
  "Delete password file and associated buffer local variables."
  (when ansible-vault--password-file
    (when (member ansible-vault--password-file ansible-vault--password-file-list)
      (setq ansible-vault--password-file-list
            (remove ansible-vault--password-file ansible-vault--password-file-list))
      (delete-file ansible-vault--password-file))
    (setq-local ansible-vault--password-file nil)))

(define-obsolete-variable-alias
  'ansible-vault--flush-password 'ansible-vault--flush-password-file "0.4.2"
  "Renamed for semantic correctness.")

(defun ansible-vault--flush-vault-id ()
  "Delete vault-id pair and associated buffer local variables."
  (when ansible-vault--vault-id
    (when (map-contains-key ansible-vault-vault-id-alist ansible-vault--vault-id)
      (setq ansible-vault-vault-id-alist
            (map-filter (lambda (key _)
                          (not (string= key ansible-vault--vault-id)))
                        ansible-vault-vault-id-alist)))
    (setq-local ansible-vault--vault-id nil)
    (ansible-vault--flush-password-file)))

(defun ansible-vault--error-buffer ()
  "Generate or return `ansible-vaul't error report buffer."
  (or (get-buffer "*ansible-vault-error*")
      (let ((buffer (get-buffer-create "*ansible-vault-error*")))
        (save-current-buffer
          (set-buffer buffer)
          (setq-local buffer-read-only t))
        buffer)))

(defmacro ansible-vault--env-mask (env &optional val &rest body)
  "Masks system ENV as VAL for BODY execution."
  (let ((env-val (make-symbol "env-val")))
    `(let ((,env-val (getenv ,env)))
       (unwind-protect
           (progn
             (setenv ,env ,val)
             ,@body)
         (setenv ,env ,env-val)))))

(defun ansible-vault--guess-password-file ()
  "Attempts to determine the correct ansible-vault password file.

Ansible vault has several locations to store the configuration of
its password file."
  (interactive)
  (when (not ansible-vault--password-file)
    (let* ((env-val (or (getenv "ANSIBLE_VAULT_PASSWORD_FILE") ""))
           (vault-id-pair (assoc ansible-vault--header-vault-id ansible-vault-vault-id-alist))
           (ansible-config-path (ansible-vault--process-config-files)))
      (cond
       (vault-id-pair
        (setq-local
         ansible-vault--vault-id (car vault-id-pair)
         ansible-vault--password-file (cdr vault-id-pair)))
       (ansible-vault--header-vault-id
        (ansible-vault--request-vault-id ansible-vault--header-vault-id))
       (t (let* ((password-file
                  (or (and (not (string-empty-p env-val)) env-val)
                      ansible-config-path
                      ansible-vault-password-file)))
            (setq-local
             ansible-vault--password-file password-file))))
      ))
  (when (not (and ansible-vault--password-file (file-readable-p ansible-vault--password-file)))
    (let* ((vault-id (or ansible-vault--header-vault-id ansible-vault--vault-id)))
      (cond (vault-id (ansible-vault--request-vault-id vault-id))
            (t (call-interactively 'ansible-vault--request-password)))
      ))
  ansible-vault--password-file)

(defun ansible-vault--cleanup-password-error ()
  "Flush both vault and password values."
  (when ansible-vault--vault-id
    (ansible-vault--flush-vault-id))
  (when ansible-vault--password-file
    (ansible-vault--flush-password-file)))

(defun ansible-vault--execute-on-region (command &optional start end buffer error-buffer)
  "In place execution of a given COMMAND using `ansible-vault'.

START defaults to `point-min'.
END defaults to `point-max'.
BUFFER defaults to current buffer.
ERROR-BUFFER defaults to `ansible-vault--error-buffer'."
  (let* (;; Silence messages
         (inhibit-message t)
         (message-log-max nil)

         ;; Set default arguments
         (start (or start (point-min)))
         (end (or end (point-max)))
         (buffer (or buffer (current-buffer)))
         (error-buffer (or error-buffer (ansible-vault--error-buffer)))

         ;; Local variables
         (ansible-vault-stdout (get-buffer-create "*ansible-vault-stdout*"))
         (ansible-vault-stderr (get-buffer-create "*ansible-vault-stderr*"))
         (password-file (ansible-vault--guess-password-file)))
    (unwind-protect
        (progn
          (let ((shell-command (ansible-vault--shell-command command)))
            (ansible-vault--env-mask
             "ANSIBLE_VAULT_PASSWORD_FILE" nil
             (shell-command-on-region start end shell-command
                                      ansible-vault-stdout nil
                                      ansible-vault-stderr nil))
            (if (zerop (buffer-size ansible-vault-stderr))
                (progn
                  (delete-region start end)
                  (insert-buffer-substring ansible-vault-stdout))
              (let ((inhibit-read-only t))
                (switch-to-buffer error-buffer)
                (goto-char (point-max))
                (insert "$ " shell-command "\n")
                (insert-buffer-substring ansible-vault-stderr)
                (insert "\n")
                (ansible-vault--cleanup-password-error)))
            ))
      (kill-buffer ansible-vault-stdout)
      (kill-buffer ansible-vault-stderr))
    ))

(defun ansible-vault-decrypt-current-buffer ()
  "In place decryption of `current-buffer' using `ansible-vault'."
  (interactive)
  (ansible-vault--execute-on-region "decrypt"))

(defun ansible-vault-decrypt-current-file ()
  "Decrypts the current buffer and writes the file."
  (interactive)
  (setq-local ansible-vault--auto-encryption-enabled nil)
  (ansible-vault-decrypt-current-buffer)
  (save-buffer 0))

(defun ansible-vault-encrypt-current-buffer ()
  "In place encryption of `current-buffer' using `ansible-vault'."
  (interactive)
  (ansible-vault--execute-on-region "encrypt"))

(defun ansible-vault-encrypt-current-file ()
  "Encrypts the current buffer and writes the file."
  (interactive)
  (setq-local ansible-vault--auto-encryption-enabled t)
  (set-buffer-modified-p t)
  (save-buffer 0)
  (ansible-vault--fingerprint-buffer))

(defun ansible-vault-decrypt-region (start end)
  "In place decryption of region from START to END using `ansible-vault'."
  (interactive "r")
  (let ((inhibit-read-only t))
    ;; Restrict the following operations to the selected region.
    (narrow-to-region start end)
    (goto-char (point-min))
    ;; Delete header and save non-vault values
    (let* ((first-line (thing-at-point 'line t))
           (match-data (string-match (rx line-start (group (zero-or-more any)) "!vault |" line-end) first-line))
           (header (match-string 1 first-line)))
      ;; remove header if it exists
      (when (and match-data (zerop match-data))
        (kill-whole-line))
      ;; realign encrypted data
      (goto-char (point-min))
      (let* ((line-count 0))
        (while (zerop line-count)
          (delete-horizontal-space)
          (setq
           line-count (forward-line))))
      ;; fingerprint new buffer
      (ansible-vault--fingerprint-buffer)
      ;; decrypt region
      (ansible-vault-decrypt-current-buffer)
      ;; replace header
      (when header
        (goto-char (point-min))
        (insert header)))
    ;; show the whole buffer again
    (widen)))

(defun ansible-vault-encrypt-region (start end)
  "In place encryption of region from START to END using `ansible-vault'."
  (interactive "r")
  (ansible-vault--execute-on-region "encrypt_string" start end))

(defun ansible-vault--chord (chord)
  "Key sequence generator for ansible-vault minor mode.

CHORD is the trailing key sequence to append ot the mode prefix."
  (kbd (concat ansible-vault-minor-mode-prefix " " chord)))

(defvar ansible-vault-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (ansible-vault--chord "d") 'ansible-vault-decrypt-current-file)
    (define-key map (ansible-vault--chord "D") 'ansible-vault-decrypt-region)
    (define-key map (ansible-vault--chord "e") 'ansible-vault-encrypt-current-file)
    (define-key map (ansible-vault--chord "E") 'ansible-vault-encrypt-region)
    (define-key map (ansible-vault--chord "p") 'ansible-vault--request-password)
    (define-key map (ansible-vault--chord "i") 'ansible-vault--request-vault-id)
    map)
  "Keymap for `ansible-vault' minor mode.")

(defun ansible-vault--before-save-hook ()
  "`before-save-hook' for files managed by `ansible-vault-mode'.

Saves the current position and encrypts the file before writing
to disk."
  (when (and ansible-vault--auto-encryption-enabled
             (not (ansible-vault--is-encrypted-vault-file)))
    (setq-local ansible-vault--point (point))
    (ansible-vault-encrypt-current-buffer)))

(defun ansible-vault--after-save-hook ()
  "`after-save-hook' for files managed by `ansible-vault-mode'.

Decrypts the file, and returns the point to the position saved by
the `before-save-hook'."
  (when (and ansible-vault--auto-encryption-enabled
             (ansible-vault--is-encrypted-vault-file))
    (ansible-vault-decrypt-current-buffer)
    (set-buffer-modified-p nil)
    (goto-char ansible-vault--point)
    (setq-local ansible-vault--point 0)))

(defun ansible-vault--kill-buffer-hook ()
  "`kill-buffer-hook' for buffers managed by `ansible-vault-mode'.

Flushes saved password state."
  (when ansible-vault--vault-id
    (ansible-vault--flush-vault-id))
  (when ansible-vault--password-file
    (ansible-vault--flush-password-file)))

;;;###autoload
(defun ansible-vault--kill-emacs-hook ()
  "`kill-emacs-hook' for Emacs when `ansible-vault-mode' is loaded.

Ensures deletion of ansible-vault generated password files."
  (dolist (file ansible-vault--password-file-list)
    (when (file-readable-p file)
      (delete-file file))
    ))

(defun ansible-vault--clear-local-variables ()
  "Unset all buffer local variables."
  (dolist (var '(ansible-vault--header-format-id
                 ansible-vault--header-version
                 ansuble-vault--header-cipher-algorithm
                 ansible-vault--header-vault-id
                 ansible-vault--point
                 ansible-vault--password-file
                 ansible-vault--vault-id
                 ansible-vault--auto-encryption-enabled))
    (makunbound var)))

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
        (setq-local
         backup-inhibited t)

        ;; Disable auto-save
        (when auto-save-default
          (auto-save-mode -1))

        ;; Decrypt the current buffer first if it needs to be
        (when (ansible-vault--is-encrypted-vault-file)
          (setq-local
           ansible-vault--auto-encryption-enabled t)
          (ansible-vault--fingerprint-buffer)
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
    (if (and (buffer-modified-p) (not (ansible-vault--is-encrypted-vault-file)))
        (ansible-vault-encrypt-current-buffer)
      (revert-buffer nil t nil))

    ;; Clean up password state
    (ansible-vault--flush-password-file)
    (ansible-vault--flush-vault-id)

    (if auto-save-default (auto-save-mode 1))

    (setq-local
     backup-inhibited nil)

    (ansible-vault--clear-local-variables)))

(add-hook 'kill-emacs-hook 'ansible-vault--kill-emacs-hook t)

(provide 'ansible-vault)

;;; ansible-vault.el ends here
