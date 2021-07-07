;;; kaesar-mode.el --- Encrypt/Decrypt buffer by AES with password.

;; Author: Masahiro Hayashi <mhayashi1120@gmail.com>
;; Keywords: data, convenience
;; Package-Version: 20160128.1008
;; Package-Commit: d087075cb1a46c2c85cd075220e09b2eaef9b86e
;; URL: https://github.com/mhayashi1120/Emacs-kaesar
;; Emacs: GNU Emacs 22 or later
;; Version: 0.9.1
;; Package-Requires: ((kaesar "0.1.4") (cl-lib "0.3"))

(defconst kaesar-mode-version "0.9.0")

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; ## Install:

;; Put this file into load-path'ed directory, and byte compile it if
;; desired. And put the following expression into your ~/.emacs.
;;
;;     (require 'kaesar-mode)

;; ## Usage:

;; This package intention to `enable-local-variables` as default value `t`
;; If you change this variable to `nil` then you must execute M-x kaesar-mode
;; explicitly.

;;; TODO:
;; * buffer-undo-list may contain secret data.
;;   To make matters worse, many other major-mode may contain
;;   secret data in local/global variable

;;; Code:

(require 'cl-lib)
(require 'kaesar)

(defgroup kaesar-mode nil
  "Handling buffer with AES cipher."
  :group 'kaesar
  :prefix "kaesar-mode-")

(defcustom kaesar-mode-cache-password nil
  "This variable control password cache for each editing buffer."
  :group 'kaesar-mode
  :type 'boolean)

;; for testing purpose. DO NOT USE THIS normally.
(defvar kaesar-mode--test-password nil)

;;TODO http://epg.sourceforge.jp/
;; how to hide password more safely. consider:
;; 1. create internal password automatically. `kaesar-mode--volatile-password'
;; 2. above password never hold to variable otherwise clear immediately.
;; 3. volatile after emacs process is killed.
(defvar kaesar-mode--secure-password nil)
(make-variable-buffer-local 'kaesar-mode--secure-password)

(defvar kaesar-mode-algorithm nil)
(make-variable-buffer-local 'kaesar-mode-algorithm)

;; this variable only set when viewing kaesar-mode buffer as a binary.
(defvar kaesar-mode-meta-alist nil)
(put 'kaesar-mode-meta-alist 'safe-local-variable (lambda (_) t))

(defface kaesar-mode-lighter-face
  '((t (:inherit font-lock-warning-face)))
  "Face used for mode-line"
  :group 'kaesar-mode)

(defvar kaesar-mode)                    ; to suppress bytecomp warning

(defun kaesar-mode--encrypt (file bytes algorithm)
  (let ((kaesar-password (kaesar-mode--password file t)))
    (kaesar-encrypt-bytes bytes algorithm)))

(defun kaesar-mode--decrypt (file bytes algorithm)
  (let ((kaesar-password (kaesar-mode--password file nil)))
    (condition-case err
        (kaesar-decrypt-bytes bytes algorithm)
      (kaesar-decryption-failed
       ;; clear cached password if need
       (when (and kaesar-mode-cache-password
                  kaesar-mode--secure-password)
         (setq kaesar-mode--secure-password nil))
       (signal (car err) (cdr err))))))

(defun kaesar-mode--password (file encrypt-p)
  (let* ((fn (file-name-nondirectory file))
         (prompt
          (if encrypt-p
              (format "Password to encrypt `%s': " fn)
            (format "Password to decrypt `%s': " fn))))
    (cond
     (kaesar-mode--test-password
      ;;TODO when wrong password.
      (vconcat kaesar-mode--test-password))
     ((not kaesar-mode-cache-password)
      (read-passwd prompt encrypt-p))
     (kaesar-mode--secure-password
      (let ((kaesar-password (kaesar-mode--volatile-password)))
        (kaesar-decrypt-bytes kaesar-mode--secure-password)))
     (t
      (let ((pass (read-passwd prompt encrypt-p)))
        (setq kaesar-mode--secure-password
              (let ((kaesar-password (kaesar-mode--volatile-password)))
                (kaesar-encrypt-string pass)))
        ;; delete after encrypt raw data
        pass)))))

(defun kaesar-mode--file-guessed-encrypted-p (file)
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (let ((coding-system-for-read 'binary))
      ;; encrypted file must have Salted__ prefix and have at least one block.
      (insert-file-contents file nil 0 1024))
    (kaesar-mode--buffer-have-header-p)))

(defun kaesar-mode--buffer-have-header-p ()
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (looking-at "\\`##### -\\*-.* mode: *kaesar;"))))

;;TODO volatile password to suppress core file contains this.
;; TODO really volatile this value??
(defun kaesar-mode--volatile-password ()
  (string-as-unibyte
   (format "%s:%s:%s"
           (emacs-pid)
           (format-time-string "%s" after-init-time)
           (format-time-string "%s" before-init-time))))

(defun kaesar-mode--cleanup-backups (file)
  (cl-loop for b in (find-backup-file-name file)
           do (when (and (file-exists-p b)
                         (eq (car (file-attributes b)) nil))
                (kaesar-mode--purge-file b))))

(defun kaesar-mode--purge-file (file)
  (let* ((size (nth 7 (file-attributes file)))
         (coding-system-for-write 'binary))
    (write-region (make-string size 0) nil file nil 'no-msg))
  (let ((delete-by-moving-to-trash nil))
    (delete-file file)))

;; * META is a alist of following:
;; - algorithm: (require)
;; - coding-system: (optional)
;; - mode: (optional)
;; And automatically added `version'
(defun kaesar-mode--write-data (file meta data)
  (setq meta (cons `(version . ,kaesar-mode-version) meta))
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert "##### -*- ")
    (insert "mode: kaesar; ")
    (insert "kaesar-mode-meta-alist: ")
    (insert (let ((print-escape-newlines t))
              (prin1-to-string meta)))
    (insert "; ")
    (insert "-*- \n")
    (insert data)
    (let ((coding-system-for-write 'binary))
      (write-region (point-min) (point-max) file nil 'no-msg))))

(defun kaesar-mode--write-encrypt-data ()
  (let* ((file buffer-file-name)
         (text (buffer-string))
         (cs (or buffer-file-coding-system 'binary))
         (bytes (encode-coding-string text cs))
         (algorithm (or kaesar-mode-algorithm kaesar-algorithm))
         (encrypt/bytes (kaesar-mode--encrypt file bytes algorithm))
         (mode major-mode)
         (meta-info `((coding-system . ,cs)
                      (algorithm . ,algorithm)
                      (mode . ,mode))))
    (kaesar-mode--write-data file meta-info encrypt/bytes)
    (setq last-coding-system-used cs)))

(defun kaesar-mode--read-data (file)
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (let ((coding-system-for-write 'binary))
      (insert-file-contents file))
    (goto-char (point-min))
    (let* ((props (hack-local-variables-prop-line))
           (meta (assq 'kaesar-mode-meta-alist props))
           (bytes (buffer-substring-no-properties
                   (line-beginning-position 2) (point-max))))
      (list meta bytes))))

(defun kaesar-mode--read-encrypt-data ()
  (cl-destructuring-bind (meta bytes)
      (kaesar-mode--read-data buffer-file-name)
    ;; handle `universal-coding-system-argument'
    (list (or coding-system-for-read
              (cdr (assq 'coding-system meta)))
          (cdr (assq 'algorithm meta))
          (cdr (assq 'mode meta))
          ;; old version have no version
          (or (cdr (assq 'version meta)) "0.1.4")
          bytes)))

(defun kaesar-mode--save-buffer ()
  (kaesar-mode--write-encrypt-data)
  (set-buffer-modified-p nil)
  (set-visited-file-modtime)
  (kaesar-mode--cleanup-backups
   buffer-file-name))

;; re-open encrypted file
(defun kaesar-mode--decrypt-buffer ()
  (cl-destructuring-bind (cs algorithm mode version data)
      ;; buffer may be a multibyte buffer.
      ;; re read buffer from file.
      (kaesar-mode--read-encrypt-data)
    (let* ((file buffer-file-name)
           (decrypt/bytes (kaesar-mode--decrypt file data algorithm))
           (contents (decode-coding-string decrypt/bytes cs)))
      (let ((inhibit-read-only t)
            buffer-read-only)
        (erase-buffer)
        (when (multibyte-string-p contents)
          (set-buffer-multibyte t))
        (insert contents)
        (setq buffer-file-coding-system cs))
      (setq kaesar-mode-algorithm algorithm)
      (set-buffer-modified-p nil)
      (setq buffer-undo-list nil)
      (goto-char (point-min))
      ;;TODO should call interface function?
      (when mode
        (with-demoted-errors
          (funcall mode))
        (unless kaesar-mode
          (kaesar-mode 1))))))

(defun kaesar-mode-ensure-encrypt-file (file)
  (cond
   ((not (file-exists-p file)))
   ((kaesar-mode--file-guessed-encrypted-p file))
   (t
    (let* ((algorithm kaesar-algorithm)
           (meta `((algorithm . ,algorithm)))
           encrypt/bytes)
      (with-temp-buffer
        (set-buffer-multibyte nil)
        (let ((coding-system-for-read 'binary))
          (insert-file-contents file))
        (let ((bytes (buffer-string)))
          (setq encrypt/bytes (kaesar-mode--encrypt file bytes algorithm))
          (clear-string bytes)
          ;;TODO how to clear buffer contents
          ))
      (kaesar-mode--write-data file meta encrypt/bytes)))))

(defun kaesar-mode-ensure-decrypt-file (file)
  (cond
   ((not (file-exists-p file)))
   ((not (kaesar-mode--file-guessed-encrypted-p file)))
   (t
    (cl-destructuring-bind (meta encrypt/bytes)
        (kaesar-mode--read-data file)
      (let* ((algorithm (cdr (assq 'algorithm meta)))
             (bytes (kaesar-mode--decrypt file encrypt/bytes algorithm)))
        (with-temp-buffer
          (set-buffer-multibyte nil)
          (insert bytes)
          (let ((coding-system-for-write 'binary))
            (write-region (point-min) (point-max) file nil 'no-msg))))))))

;;TODO test
(defun kaesar-mode-change-file-password (file)
  (unless (file-exists-p file)
    (error "File %s is not exists" file))
  (unless (kaesar-mode--file-guessed-encrypted-p file)
    (error "File %s is not encrypted" file))
  ;;TODO
  ;; decrypt body -> encrypt raw body -> clear raw body
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (let ((coding-system-for-read 'binary))
      (insert-file-contents file))
    (goto-char (point-min))
    (let* ((props (hack-local-variables-prop-line))
           (meta (assq 'kaesar-mode-meta-alist props))
           (algorithm (cdr (assq 'algorithm meta)))
           (encrypt/bytes
            (buffer-substring-no-properties
             (line-beginning-position 2) (point-max)))
           (bytes (kaesar-mode--decrypt file encrypt/bytes algorithm)))
      (delete-region (line-beginning-position 2) (point-max))
      (setq encrypt/bytes (kaesar-mode--encrypt file bytes algorithm))
      (clear-string bytes)
      (goto-char (point-max))
      (insert encrypt/bytes)
      (write-region (point-min) (point-max) file nil 'no-msg))))

(defun kaesar-mode-save-buffer ()
  (cond
   ((buffer-modified-p)
    (kaesar-mode--save-buffer)
    (message "Wrote %s with kaesar encryption"
             buffer-file-name))
   (t
    (message "(No changes need to be saved)")))
  ;; explicitly return non-nil
  t)

(defun kaesar-mode--after-revert ()
  (kaesar-mode 1))

(defun kaesar-mode-clear-cache-password ()
  (interactive)
  (unless (and kaesar-mode-cache-password
               kaesar-mode--secure-password)
    (error "No need to clear the password"))
  (setq kaesar-mode--secure-password nil)
  (set-buffer-modified-p t))

;; `find-file-noselect' -> `normal-mode' -> `set-auto-mode'

;;;###autoload
(define-minor-mode kaesar-mode
  "Automatically encrypt buffer with password.
todo about header which prepend by `kaesar-mode'
todo how to grep encrypt file
todo `kaesar-mode-cache-password'
 "
  :init-value nil
  :lighter (" [" (:propertize "KaesarEncrypt" face kaesar-mode-lighter-face) "]")
  :group 'kaesar-mode
  ;; Suppress two time `kaeasr-mode' call.
  ;; `normal-mode': `set-auto-mode' -> `hack-local-variables'
  (add-hook 'before-hack-local-variables-hook
            (lambda ()
              (setq file-local-variables-alist
                    (assq-delete-all 'mode file-local-variables-alist)))
            nil t)
  (cond
   ((not buffer-file-name)
    (message "Buffer has no physical file.")
    (kaesar-mode -1))
   ((not kaesar-mode)
    (remove-hook 'write-contents-functions 'kaesar-mode-save-buffer t)
    (remove-hook 'after-revert-hook 'kaesar-mode--after-revert t)
    (kill-local-variable 'kaesar-mode-algorithm)
    (when (and (kaesar-mode--file-guessed-encrypted-p buffer-file-name)
               (not (kaesar-mode--buffer-have-header-p)))
      ;; trick to execute `basic-save-buffer'
      (set-buffer-modified-p t)
      (basic-save-buffer)))
   (t
    (make-local-variable 'kaesar-mode-algorithm)
    (unless (kaesar-mode--file-guessed-encrypted-p buffer-file-name)
      ;; first time call `kaesar-mode'
      (kaesar-mode--save-buffer))
    (when (kaesar-mode--buffer-have-header-p)
      (let ((done nil))
        (condition-case quit
            (while (not done)
              (condition-case err
                  (progn
                    (kaesar-mode--decrypt-buffer)
                    (setq done t))
                (kaesar-decryption-failed
                 (message "Password wrong!")
                 (sit-for 1))
                (error
                 (kaesar-mode -1)
                 (signal (car err) (cdr err)))))
          (quit
           (kaesar-mode -1)))))
    (when kaesar-mode
      (add-hook 'write-contents-functions 'kaesar-mode-save-buffer nil t)
      (add-hook 'after-revert-hook 'kaesar-mode--after-revert nil t)))))

(provide 'kaesar-mode)

;;; kaesar-mode.el ends here
