;;; le-thesaurus.el ---  Query thesaurus.com for synonyms of a given word -*- lexical-binding: t; -*-

;;; Copyright (C) 2022 by Anselm Coogan
;;; URL: https://github.com/AnselmC/le-thesaurus.el
;; Package-Version: 20220920.1924
;; Package-Commit: 4dbe929aeaef7d38e75d52844cf9022244fc94ae
;;; Version: 0.2.0
;;; Package-Requires: ((request "0.3.2") (emacs "24.4"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Uses the Elisp request library (https://github.com/tkf/emacs-request) and the thesaurus.com API to fetch synonyms

;;; Code:

(require 'cl-lib)
(require 'request)

(defvar le-thesaurus--cache
  (make-hash-table :test 'equal)
  "Cache to store previous synonym request results.")


(defun le-thesaurus--flatten-synonyms-for-definition (raw-response)
  "Flatten the parsed json RAW-RESPONSE into a list of alists."
  (let ((synonym-data (assoc-default 'synonyms raw-response))
        (definition (assoc-default 'definition raw-response)))
    (mapcar (lambda (syn) `((similarity . ,(assoc-default 'similarity syn))
                            (vulgar . ,(not (equal (assoc-default 'isVulgar syn) "0")))
                            (informal . ,(not (equal (assoc-default 'isInformal syn) "0")))
                            (definition . ,definition)
                            (term . ,(assoc-default 'term syn)))) synonym-data)))

(defun le-thesaurus--parse-synonyms-in-response (payload)
  "Parse JSON PAYLOAD to extract synonyms from response."
  (let* ((data (assoc-default 'data payload))
         (definition-data (if data
                              (assoc-default 'definitionData data)
                            '()))
         (definitions-list (if definition-data
                               (assoc-default 'definitions definition-data)
                             '())))
    (apply #'append (mapcar (lambda (e) (le-thesaurus--flatten-synonyms-for-definition e)) definitions-list))))

(defun le-thesaurus--ask-thesaurus-for-synonyms (word)
  "Ask thesaurus.com for synonyms for WORD and return vector of synonyms."
  (let ((cached-resp (gethash word le-thesaurus--cache)))
    (if cached-resp
        cached-resp
      (let* ((thesaurus-base-url "https://tuna.thesaurus.com/pageData/")
             (request-string (concat thesaurus-base-url word))
             (response (request-response-data (request request-string
                                                :parser 'json-read
                                                :sync t))))
        (if response
            (let ((synonyms (le-thesaurus--parse-synonyms-in-response response)))
              (puthash word synonyms le-thesaurus--cache)
              synonyms)
          '())))))

(defun le-thesaurus--get-completions (synonyms-data)
  "Create an alist from SYNONYMS-DATA to be used for completions.
Synonyms are sorted by similarity."
  (cl-sort (mapcar
            (lambda (e) `(,(assoc-default 'term e) . ,e))
            synonyms-data)
           #'>
           :key (lambda (x) (string-to-number (assoc-default 'similarity (cdr x))))))

(defun le-thesaurus--get-annotations (completions)
  "Get function initalized with COMPLETIONS to annotate a given word."
  (lambda (word)
    (let* ((metadata (assoc-default word completions))
           (similarity (assoc-default 'similarity metadata))
           (definition (assoc-default 'definition metadata))
           (max-word-length 30)
           (left-padding (- max-word-length (length word))))
      (format
       ;; dynamically determine left padding based on word length
       (concat "%" (number-to-string left-padding) "s%3s\t%s%s\t%s\t%s")
       "Sim: "
       similarity
       "Def: "
       definition
       (if (assoc-default 'informal metadata) "informal" "")
       (if (assoc-default 'vulgar metadata) "vulgar" "")))))



(defun le-thesaurus--get-group (completions)
  "Get fun initialized with COMPLETIONS to get group of a given completion."
  (lambda (completion transform)
    (if transform
        completion
      (assoc-default 'definition (assoc-default completion completions)))))


(defun le-thesaurus--completing-read-collection-fn (completions)
  "Get fun initialized with COMPLETIONS for collection arg to `completing-read'."
  (lambda (str pred flag)
    (cl-case flag
      ('metadata
       `(metadata
         (annotation-function . ,(le-thesaurus--get-annotations completions))
         (group-function . ,(le-thesaurus--get-group completions))
         (display-sort-function . ,#'identity) ;; completions are already sorted
         ))
      (t
       (all-completions str completions pred)))))

(defun le-thesaurus--get-word-case (word)
  "Returns whether WORD is upcase or capitalized, or defaults to downcase."
  (cond ((equal (upcase word) word) 'upcase)
	((equal (capitalize word) word) 'capitalized)
	(t 'downcase)))

;;;###autoload
(defun le-thesaurus-get-synonyms()
  "Interactively get synonyms for symbol at active region or point."
  (interactive)
  (let* ((bounds (if (use-region-p)
                     (cons (region-beginning) (region-end))
                   (bounds-of-thing-at-point 'symbol)))
         (word (buffer-substring-no-properties (car bounds) (cdr bounds)))
	 (word-case (le-thesaurus--get-word-case word))
         (results (le-thesaurus--ask-thesaurus-for-synonyms word))
         (completions (le-thesaurus--get-completions results))
         (replace-text (completing-read
                        (format "Select synonym for %S: " word)
                        (le-thesaurus--completing-read-collection-fn completions))))
    (when bounds
      (delete-region (car bounds) (cdr bounds))
      (insert (cond ((equal word-case 'upcase) (upcase replace-text))
		    ((equal word-case 'capitalized) (capitalize replace-text))
		    (t replace-text))))))



;;;###autoload
(defun le-thesaurus-clear-cache ()
  "Clear the cache for le-thesaurus."
  (interactive)
  (clrhash le-thesaurus--cache))

(provide 'le-thesaurus)
;;; le-thesaurus.el ends here
