;;; encrypt-region.el --- Encrypts and decrypts regions

;;; Copyright (c) 2022, Carlton Shepherd

;;; Author: Carlton Shepherd <carlton@linux.com>

;;; Version: 1.0
;; Package-Version: 20220731.1956
;; Package-Commit: d060c8d97bb7e10055626e075ab8c2f834840a7b
;;; Keywords: tools, convenience
;;; License: GPLv3
;;; Package-Requires: ((emacs "26.1"))

;;; This file is not part of GNU Emacs.

;;; Commentary:

;;; Set a 32-char private key using (setq encrypt-region-key "<your key>")
;;; Use M-x encrypt-region-encrypt to encrypt a region
;;; Use M-x encrypt-region-decrypt to decrypt it
;;; URL: https://github.com/cgshep/encrypt-region
;;;
;;; This program is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Code:
(defgroup encrypt-region nil
  "Encrypt region group."
  :group 'text)

(defcustom encrypt-region-key "key"
  "Define a 16-byte/32-hexchar key for encrypting regions."
  :type 'string
  :group 'encrypt-region)

(defvar encrypt-region--encrypt-buf-name "*Encrypt Region*")
(defvar encrypt-region--decrypt-buf-name "*Decrypt Region*")

(defun encrypt-region--pad (input length)
  "Pad string to a given LENGTH using PKCS#7.
Argument INPUT string to pad.
Argument LENGTH pad length."
  ;; Thanks to auth-source.el
  ;; https://github.com/emacs-mirror/emacs/blob/master/lisp/auth-source.el
  (let ((p (- length (mod (length input) length))))
    (concat input (make-string p p))))

(defun encrypt-region--unpad (string)
  "Remove padding from STRING."
  (substring string 0 (- (length string)
			 (aref string (1- (length string))))))
     
(defun encrypt-region-encrypt (start end)
  "Encrypts a region and outputs its base64 encoding.
Argument START region start.
Argument END region end."
  (interactive "r")
  (with-output-to-temp-buffer
    (get-buffer-create encrypt-region--encrypt-buf-name)
    (princ (mapconcat
	    #'base64-encode-string
	    (gnutls-symmetric-encrypt "CHACHA20-POLY1305"
				      (copy-sequence encrypt-region-key)
				      (list 'iv-auto 12)
				      (encrypt-region--pad
				       (encode-coding-string (buffer-substring start end) 'utf-8)
				       64)
				      "") "###"))
    (switch-to-buffer encrypt-region--encrypt-buf-name)))

(defun encrypt-region-decrypt (start end)
  "Decrypt a base64-encoded encrypted region.
Argument START region start.
Argument END region end."
  (interactive "r")
  (with-output-to-temp-buffer
    (get-buffer-create encrypt-region--decrypt-buf-name)
    (princ (encrypt-region--unpad
	    (decode-coding-string
	     (car
	      (let ((ctext-str (split-string
				(buffer-substring start end) "###")))
		(gnutls-symmetric-decrypt "CHACHA20-POLY1305"
					  (copy-sequence encrypt-region-key)
					  ;; Decode the IV
					  (base64-decode-string (cadr ctext-str))
					  ;; Decode the ciphertext
					  (base64-decode-string (car ctext-str)))))
	     'utf-8)))
    ;; Output to the decrypt temporary buffer
    (switch-to-buffer encrypt-region--decrypt-buf-name)))

(provide 'encrypt-region)
;;; encrypt-region.el ends here
