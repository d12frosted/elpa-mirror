;;; kaesar-file.el --- Encrypt/Decrypt file by AES with password.

;; Author: Masahiro Hayashi <mhayashi1120@gmail.com>
;; Keywords: data, files
;; Package-Version: 20160128.1008
;; Package-Commit: d087075cb1a46c2c85cd075220e09b2eaef9b86e
;; URL: https://github.com/mhayashi1120/Emacs-kaesar
;; Emacs: GNU Emacs 22 or later
;; Version: 0.9.1
;; Package-Requires: ((kaesar "0.1.1"))

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
;;     (require 'kaesar-file)

;; ## Usage:

;; * Simply encrypt/decrypt file.
;; `kaesar-encrypt-file` <-> `kaesar-decrypt-file`

;;; TODO:
;; * brush up interface
;; * physical deletion raw file contents.

;;; Code:

(require 'kaesar)

(defgroup kaesar-file ()
  "Encrypt/Decrypt a file"
  :prefix "kaesar-file-"
  :group 'kaesar)

(defun kaesar-file--prepare-base64 (algorithm)
  (base64-encode-region (point-min) (point-max))
  (goto-char (point-min))
  (insert "-----BEGIN ENCRYPTED DATA-----\n")
  (insert (format "Algorithm: %s\n" algorithm))
  (insert "\n")
  (goto-char (point-max))
  (insert  "\n")
  (insert "-----END ENCRYPTED DATA-----\n"))

(defun kaesar-file--decode-if-base64 ()
  ;; decode buffer if valid base64 encoded.
  ;; return a algorithm of encryption if get.
  (let (algorithm)
    (goto-char (point-min))
    (cond
     ((re-search-forward "^-----BEGIN ENCRYPTED DATA" nil t)
      ;; Encrypted mode is `base64-with-header'
      (when (re-search-forward "^Algorithm: \\(.*\\)" nil t)
        (setq algorithm (match-string 1))
        ;; delete base64 header
        (delete-region (point-min) (line-beginning-position 2)))
      (when (re-search-forward "^-----END ENCRYPTED DATA" nil t)
        ;; delete base64 footer
        (delete-region (line-beginning-position) (line-end-position)))
      (base64-decode-region (point-min) (point-max)))
     ;; TODO FIXME: too high cost of regexp
     ((looking-at "\\`\\([A-Za-z0-9+/]+\n\\)*[A-Za-z0-9+/]+=*\n*\\'")
      ;; Encrypted mode is `base64'
      (base64-decode-region (point-min) (point-max))))
    algorithm))

(defun kaesar-file--write-buffer (file)
  (kaesar-file--write-region (point-min) (point-max) file))

(defun kaesar-file--write-region (start end file)
  ;; to suppress two time encryption
  (let ((inhibit-file-name-handlers '(epa-file-handler))
        (inhibit-file-name-operation 'write-region)
        (coding-system-for-write 'binary)
        (jka-compr-compression-info-list nil))
    (write-region start end file nil 'no-msg)))

(defun kaesar-file--insert-file-contents (file)
  ;; to suppress two time decryption
  (let ((format-alist nil)
        (after-insert-file-functions nil)
        (jka-compr-compression-info-list nil)
        ;; inhibit file name operations
        (file-name-handler-alist nil)
        (coding-system-for-read 'binary))
    (insert-file-contents file)
    (set-buffer-multibyte nil)))

(defun kaesar-file--prepare-encrypt-buffer (algorithm mode)
  (let ((encrypted (kaesar-encrypt-bytes (buffer-string) algorithm)))
    (erase-buffer)
    (insert encrypted)
    (cond
     ((or (null mode) (eq mode 'binary)))
     ((eq mode 'base64-with-header)
      (kaesar-file--prepare-base64 (or algorithm kaesar-algorithm)))
     ((eq mode 'base64)
      (base64-encode-region (point-min) (point-max)))
     (t
      (error "Not a supported mode %s" mode)))))

(defun kaesar-file--detect-encrypt-buffer (algorithm)
  (let* ((detect-algo (kaesar-file--decode-if-base64))
         (contents (buffer-string))
         (algo (or algorithm detect-algo kaesar-algorithm))
         (decrypted (kaesar-decrypt-bytes contents algo)))
    (erase-buffer)
    (insert decrypted)))

;;;###autoload
(defun kaesar-encrypt-file (file &optional algorithm mode save-file)
  "Encrypt a FILE by `kaesar-algorithm'
which contents can be decrypted by `kaesar-decrypt-file-contents'.

MODE: `binary', `base64-with-header', `base64' default is `binary'
"
  (with-temp-buffer
    (kaesar-file--insert-file-contents file)
    (kaesar-file--prepare-encrypt-buffer algorithm mode)
    (kaesar-file--write-buffer (or save-file file))))

;;;###autoload
(defun kaesar-decrypt-file (file &optional algorithm save-file)
  "Decrypt a FILE contents with getting string.
FILE was encrypted by `kaesar-encrypt-file'."
  (with-temp-buffer
    (kaesar-file--insert-file-contents file)
    (kaesar-file--detect-encrypt-buffer algorithm)
    (kaesar-file--write-buffer (or save-file file))))

;;;###autoload
(defun kaesar-encrypt-write-region (start end file &optional algorithm coding-system mode)
  "Write START END region to FILE with encryption.
Warning: this function may be changed in future release."
  (interactive "r\nF")
  (let* ((str (if (stringp start)
                  start
                (buffer-substring-no-properties start end)))
         (cs (or coding-system
                 buffer-file-coding-system
                 default-terminal-coding-system))
         (s (encode-coding-string str cs)))
    (with-temp-buffer
      (set-buffer-multibyte nil)
      (insert s)
      (kaesar-file--prepare-encrypt-buffer algorithm mode)
      (kaesar-file--write-buffer file))))

;;;###autoload
(defun kaesar-decrypt-file-contents (file &optional algorithm coding-system)
  "Get decrypted FILE contents.
FILE was encrypted by `kaesar-encrypt-file'.
Warning: this function may be changed in future release."
  (with-temp-buffer
    (kaesar-file--insert-file-contents file)
    (kaesar-file--detect-encrypt-buffer algorithm)
    (if coding-system
        (decode-coding-string (buffer-string) coding-system)
      (buffer-string))))

(provide 'kaesar-file)

;;; kaesar-file.el ends here
