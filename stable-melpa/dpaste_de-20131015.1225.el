;;; dpaste_de.el --- Emacs mode to paste to dpaste.de

;; Copyright (c) 2013 Thejaswi Puthraya

;; Author: Thejaswi Puthraya <thejaswi.puthraya@gmail.com>
;; Created: 18 Mar 2013
;; Version: 0.2
;; Package-Version: 20131015.1225
;; Package-Commit: ab041443884a7a4bfdc81b055688821e8efc9b02
;; Package-Requires: ((web "0.3.7"))
;; Keywords: pastebin

;; This file is not part of GNU Emacs.

;; This file is distributed under the MIT License
;; Copyright (c) 2013 Thejaswi Puthraya

;; Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:

;; Usage:
;;
;; Dpaste a buffer
;;
;; (require 'dpaste_de)
;;
;; (dpaste-buffer)
;; The url is copied into your clipboard and kill ring
;;
;; On a region
;; (require 'dpaste_de)
;; (dpaste-region)
;;
;; Dpaste a buffer by specifying a name
;; (require 'dpaste_de)
;; (dpaste-buffer-with-name "*scratch*")
;;
;; Special thanks to Martin Mahner (https://github.com/bartTC) for running dpaste.de

;;; Change Log: 

;; 0.2 - Fixes for the latest web.el
;; 0.1 - Initial commit and push into melpa

;;; Code:
(require 'web)

(defvar version 0.2 "dpaste version")
(defvar paste-host "dpaste.de" "dpaste hostname")
(defvar user-agent
  (concat "dpaste_de.el/"
	  (number-to-string version))
  "dpaste user agent")

(defun dpaste-region (start end)
  (interactive "r")
  (with-current-buffer (current-buffer)
    (let ((buffer-contents (buffer-substring-no-properties start end))
	  (query-data (make-hash-table :test 'equal)))
      (puthash 'content buffer-contents query-data)
      (web-http-post
       (lambda (con header data)
	 (with-current-buffer (get-buffer-create "*dpaste-output*")
	   (insert data)
	   (kill-ring-save (+ (point-min) 1) (- (point-max) 1))
	   (clipboard-kill-region (+ (point-min) 1) (- (point-max) 1))
	   (kill-buffer)))
       :url (concat "https://" paste-host "/api/")
       :extra-headers `((Content-Type . "application/x-www-form-urlencoded")
			(User-Agent . ,user-agent))
       :data query-data))))

(defun dpaste-buffer ()
  (interactive)
  (dpaste-region (point-min) (point-max)))

(defun dpaste-buffer-with-name (buffer-name)
  (interactive "bBuffer: ")
  (with-current-buffer (get-buffer buffer-name)
    (dpaste-buffer)))

(provide 'dpaste_de)

;;; dpaste_de.el ends here
