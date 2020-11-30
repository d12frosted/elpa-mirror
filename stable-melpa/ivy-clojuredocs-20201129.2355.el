;;; ivy-clojuredocs.el --- Search for help in clojuredocs.org -*- lexical-binding: t; -*-

;; Author: Wanderson Ferreira <iagwanderson@gmail.com>
;; URL: https://github.com/wandersoncferreira/ivy-clojuredocs
;; Package-Version: 20201129.2355
;; Package-Commit: 8b6de19b3578c72d2b88f898e2290d94c04350f9
;; Package-Requires: ((edn "1.1.2") (ivy "0.12.0") (emacs "24.4"))
;; Version: 0.1
;; Keywords: matching

;; Copyright (C) 2019 Wanderson Ferreira <iagwanderson@gmail.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This work is heavily inspired by `helm-clojuredocs'.  Despite the completion
;; engine difference, there are minor implementation details and bug fixes in
;; this first version.

;;; Code:

(require 'ivy)
(require 'browse-url)
(require 'parseedn)
(require 'cl-lib)
(require 'subr-x)

(defgroup ivy-clojuredocs nil
  "Ivy applications"
  :group 'ivy)

(defcustom ivy-clojuredocs-url
  "https://clojuredocs.org/"
  "Url used for searching in ClojureDocs website."
  :type 'string
  :group 'ivy-clojuredocs)

(defcustom ivy-clojuredocs-min-chars-number
  2
  "Value for minimum input character before start searching on ClojureDocs website."
  :type 'integer
  :group 'ivy-clojuredocs)

(defvar ivy-clojuredocs-cache (make-hash-table :test 'equal))

(defun ivy-clojuredocs--parse-entry (entry)
  "Parse each ENTRY returned by ClojureDocs API."
  (let ((cd-namespace (or (gethash ':ns entry) ""))
        (cd-type (or (gethash ':type entry) ""))
        (cd-name (gethash ':name entry)))
    (format "%s %s %s" cd-namespace cd-name cd-type)))

(defun ivy-clojuredocs--parse-response-buffer (buffer)
  "Get the BUFFER with the response content and parse each returned entry."
  (cl-loop for i in (parseedn-read-str buffer)
           collect (ivy-clojuredocs--parse-entry i) into result
           finally return result))

(defun ivy-clojuredocs-fetch (candidate)
  "Call the ClojureDocs API for a given CANDIDATE.
Place the parsed results in cache.T he cache data structure is a
hash-table whose keys are the searched candidates."
  (let ((url (concat ivy-clojuredocs-url "ac-search?query=" candidate)))
    (with-current-buffer (url-retrieve-synchronously url)
      (goto-char (point-min))
      (when (re-search-forward "\\(({.+})\\)" nil t)
        (puthash candidate
                 (ivy-clojuredocs--parse-response-buffer (match-string 0))
                 ivy-clojuredocs-cache)))))

(defun ivy-clojuredocs-candidates (str &rest _u)
  "Orchestrate call to get suggestions to candidate (STR).
There are two behaviors here, at the first search we cache the
returned data for this candidate (STR) in a hash-table data
structure.  Second search in the same candidate, will capture the
data from cache."
  (if (< (length str) ivy-clojuredocs-min-chars-number)
      (ivy-more-chars)
    (let ((candidates (or (gethash str ivy-clojuredocs-cache)
                          (ivy-clojuredocs-fetch str))))
      (if (member str candidates)
          candidates
        (append
         candidates
         (list (format "Search for '%s' on clojuredocs.org" str)))))))

(defun ivy-clojuredocs-fmt-web-entry (entry)
  "Parse an given ENTRY called by ivy-action.
The idea is to return a string that is useful to the `browse-url'
function."
  (if (string-match "on clojuredocs.org$" entry)
      (format "search?q=%s" (cadr (split-string entry "'")))
    (let* ((lentry (cl-remove-if #'string-empty-p
                                 (split-string entry " "))))
      (replace-regexp-in-string "?" "_q"
                                (string-join (nbutlast lentry) "/")))))

(defun ivy-clojuredocs--clean-cache ()
  "Clear the cache data structure for `ivy-clojuredocs' previous search."
  (clrhash ivy-clojuredocs-cache))

(defun ivy-clojuredocs-thing-at-point (thing)
  "Preprocess THING to be given as parameter as a candidate to search."
  (when thing
    (car (last (split-string thing "/")))))

(defun ivy-clojuredocs-invoke (&optional initial-input)
  "Ivy function to read and display candidates to the user.
We can pass an INITIAL-INPUT value to be the first candidate searched."
  (ivy-read "ClojureDocs: " #'ivy-clojuredocs-candidates
            :initial-input initial-input
            :dynamic-collection t
            :action (lambda (entry)
                      (browse-url (concat ivy-clojuredocs-url (ivy-clojuredocs-fmt-web-entry entry))))
            :unwind #'ivy-clojuredocs--clean-cache
            :caller #'ivy-clojuredocs))

;;;###autoload
(defun ivy-clojuredocs ()
  "Search for help at ClojureDocs API."
  (interactive)
  (ivy-clojuredocs-invoke))

;;;###autoload
(defun ivy-clojuredocs-at-point ()
  "Search for help using word at point at ClojureDocs API."
  (interactive)
  (ivy-clojuredocs-invoke (ivy-clojuredocs-thing-at-point (thing-at-point 'symbol))))

(provide 'ivy-clojuredocs)

;; Local Variables:
;; coding: utf-8
;; End:

;;; ivy-clojuredocs.el ends here
