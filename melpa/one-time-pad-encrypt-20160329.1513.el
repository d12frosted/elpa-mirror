;;; one-time-pad-encrypt.el --- One time pad encryption within file

;; Copyright (C) 2016 Garvin Guan
;;
;; Author: Garvin Guan <garvin.guan@gmail.com>
;; URL: https://github.com/garvinguan/emacs-one-time-pad/
;; Package-Version: 20160329.1513
;; Package-Commit: 87cc1f124024ce3d277299ca0ac703f182937d9f
;; Version: 1.0
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;;; License:

;; Licensed under the same terms as Emacs.

;;; Commentary:

;; Bind the following commands:
;; one-time-pad-encrypt-string
;;
;; For a detailed introduction see:
;; https://github.com/garvinguan/emacs-one-time-pad/blob/master/README.md

;;; Code:

;;;###autoload
(defun one-time-pad-encrypt (key start end)
  "Encrypt text within a file, your key should be as long if not longer than the marked text"
  (interactive
   (list (let ((minibuffer-history minibuffer-history)) (read-string "Key to use: "))
	 (region-beginning)(region-end)))
  (one-time-pad--encrypt key start end))

;;;###autoload
(defun one-time-pad-encrypt-hide-key (key start end)
  "Encrypt text within a file, your key should be as long if not longer than the marked text"
  (interactive
   (list (read-passwd "Key to use for encryption: ")
	 (region-beginning)(region-end)))
  (one-time-pad--encrypt key start end))

;;;###autoload
(defun one-time-pad--encrypt (key start end)
  "Xor key with data"
  (let* ((data (buffer-substring start end))
	(data-as-list (string-to-list data))
	(key-as-list (string-to-list key))
	(result))
    (barf-if-buffer-read-only)
    (if (< (length key-as-list) (length data-as-list))
	(error "The key must be as long or longer in length than the data"))
    (while data-as-list
      (setq result (cons (logxor (car data-as-list) (car key-as-list)) result))
      (setq data-as-list (cdr data-as-list))
      (setq key-as-list (cdr key-as-list)))
    (delete-region start end)
    (insert (concat (reverse result)))))

(provide 'one-time-pad-encrypt)
;;; one-time-pad-encrypt.el ends here
