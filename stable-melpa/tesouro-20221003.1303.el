;;; tesouro.el --- Brazilian Portuguese synonym search in dicio.com.br -*- lexical-binding: t; -*-

;;; Copyleft (Ⓚ) 2022   Rafael Beraldo
;;; URL: https://github.com/rberaldo/tesouro.el
;; Package-Version: 20221003.1303
;; Package-Commit: 3dbfc49209237215163be1ea338dea099ddc0795
;;; Version: 1.0
;;; Package-Requires: ((request "0.3.2") (emacs "24.4"))

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Queries dicio.com.br for synonyms of a word using @ThiagoNelsi’s
;; dicio-api (https://github.com/ThiagoNelsi/dicio-api)

;; Heavily based on @AnselmC’s le-thesaurus.el
;; (https://github.com/AnselmC/le-thesaurus.el/)

;;; Code:

(require 'request)

(defvar tesouro--cache
  (make-hash-table :test 'equal)
  "Cache to store previous synonyms.")

(defun tesouro--fetch-synonyms-in-dicio (word)
  "Ask dicio.com.br for synonyms of WORD and return a list of synonyms."
  (let ((cached-syns (gethash word tesouro--cache)))
    (if cached-syns
	cached-syns)
    (let* ((thesaurus-base-url "https://significado.herokuapp.com/v2/synonyms/")
	   (request-string (concat thesaurus-base-url word))
	   (response (request-response-data (request request-string
					      :parser 'json-read
					      :sync t))))
      (if response
	  (let ((synonyms (append response nil)))
	    (puthash word synonyms tesouro--cache)
	    synonyms)
	nil))))

(defun tesouro--determine-word-case (word)
  "Return if WORD is upcase, capitalized or defaults to downcase."
  (cond ((equal (upcase word) word) 'upcase)
	((equal (capitalize word) word) 'capitalized)
	(t 'downcase)))

;;; User functions

;;;###autoload
(defun tesouro-get-synonyms ()
  "Get synonyms for active word or word under the point."
  (interactive)
  (let* ((bounds (if (use-region-p)
                     (cons (region-beginning) (region-end))
                   (bounds-of-thing-at-point 'symbol)))
         (word (buffer-substring-no-properties (car bounds) (cdr bounds)))
	 (case (tesouro--determine-word-case word))
         (synonyms (tesouro--fetch-synonyms-in-dicio word))
         (replace-text (completing-read
                        (format "Select synonym for %S: " word)
                        synonyms)))
    (when bounds
      (delete-region (car bounds) (cdr bounds))
      ;; Insert correct case
      (insert (if (equal case 'upcase)
		  (upcase replace-text)
		(if (equal case 'capitalized)
		    (capitalize replace-text)
		  replace-text))))))

;;;###autoload
(defun tesouro-clear-cache ()
  "Clear the synoynm cache for tesouro."
  (interactive)
  (clrhash tesouro--cache))

(provide 'tesouro)
;;; tesouro.el ends here
