;;; ob-translate.el --- Translation of text blocks in org-mode.
;; Copyright 2013 Kris Jenkins

;; License: GNU General Public License version 3, or (at your option) any later version
;; Author: Kris Jenkins <krisajenkins@gmail.com>
;; Maintainer: Kris Jenkins <krisajenkins@gmail.com>
;; Keywords: org babel translate translation
;; Package-Version: 20170720.1919
;; Package-Commit: 9d9054a51bafd5a29a8135964069b4fa3a80b169
;; URL: https://github.com/krisajenkins/ob-translate
;; Created: 16th July 2013
;; Version: 0.1.3
;; Package-Requires: ((google-translate "0.11") (org "8"))

;;; Commentary:
;;
;; Supports translation of text blocks in org-mode.

;;; Code:
(require 'org)
(require 'ob)
(require 'google-translate)

(defgroup ob-translate nil
  "Translate org-mode blocks."
  :group 'org)

(defcustom ob-translate:default-src "auto"
  "Default language to translate from."
  :group 'ob-translate
  :type 'string)

(defcustom ob-translate:default-dest "en"
  "Default language to translate to."
  :group 'ob-translate
  :type 'string)

(defun ob-translate:google-translate (src dest text)
  "Translate TEXT from the SRC langauge to the DEST language."
  (let* ((text-stripped (replace-regexp-in-string "[[:space:]\n\r]+" " " text))
		 (json (json-read-from-string
				(google-translate--insert-nulls
				 ;; Google Translate won't let us make a request unless we
				 ;; send a "User-Agent" header it recognizes.
				 ;; "Mozilla/5.0" seems to work.
				 (let ((url-request-extra-headers
						'(("User-Agent" . "Mozilla/5.0"))))
				   (google-translate--request src dest text-stripped))
                 )))
         (text-phonetic (google-translate-json-text-phonetic json))
		 (translation (google-translate-json-translation json))
         (translation-phonetic (google-translate-json-translation-phonetic json))
		 (dict (google-translate-json-detailed-definition json)))
	translation))

;;;###autoload
(defun org-babel-execute:translate (body params)
  "org-babel translation hook."
  (let ((src (or (cdr (assoc :src params))
				 ob-translate:default-src))
		(dest (or (cdr (assoc :dest params))
				  ob-translate:default-dest))
		(text (or (cddr (assoc :var params))
				  body
				  "")))
	(if (string-match "," dest)
		(mapcar (lambda (subdest)
				  (list subdest
						(ob-translate:google-translate src subdest text)))
				(split-string dest ","))
	  (ob-translate:google-translate src dest text))))

;;;###autoload
(eval-after-load "org"
 '(add-to-list 'org-src-lang-modes '("translate" . text)))

(provide 'ob-translate)

;;; ob-translate.el ends here
