;;; elmine.el --- Redmine API access via elisp.

;; Copyright (c) 2012 Arthur Leonard Andersen
;;
;; Author: Arthur Andersen <leoc.git@gmail.com>
;; URL: http://github.com/leoc/elmine
;; Package-Version: 20200520.1237
;; Package-Commit: c78cc8705c2dffbf649b858f02b5028225943482
;; Version: 0.3.1
;; Keywords: tools
;; Package-Requires: ((s "1.10.0"))
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; `elmine` provides simple means of accessing the redmine Rest API
;; programmatically. This means that you do not have interactive
;; functions but functions that give and take list representations of
;; JSON objects of the redmine API.

;;; Code:

(require 'json)
(require 's)

(defun plist-merge (base new)
  "Merges two plists. The keys of the second one will overwrite the old ones."
  (let ((key (car new))
        (val (cadr new))
        (new (cddr new)))
    (while (and key val)
      (setq base (plist-put base key val))
      (setq key (car new))
      (setq val (cadr new))
      (setq new (cddr new)))
    base))

(defvar elmine/host nil
  "The default host of the redmine.")

(defvar elmine/api-key nil
  "The default API key for the redmine")

(defun elmine/get (plist key &rest keys)
  "Execute `plist-get` recursively for `plist`.

Example:
  (setq plist '(:a 3
                :b (:c 12
                    :d (:e 31))))

  (elmine/get plist \"a\")
      ;; => 3
  (elmine/get plist :b)
      ;; => (:c 12 :d (:e 31))
  (elmine/get plist :b :c)
      ;; => 12
  (elmine/get plist :b :d :e)
      ;; => 31
  (elmine/get plist :b :a)
      ;; => nil
  (elmine/get plist :a :c)
      ;; => nil"
  (save-match-data
    (let ((ret (plist-get plist key)))
      (while (and keys ret)
        (if (listp ret)
            (progn
              (setq ret (elmine/get ret (car keys)))
              (setq keys (cdr keys)))
          (setq ret nil)))
      ret)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HTTP functions using Emacs URL package ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun elmine/make-key (string)
  (make-symbol (format ":%s" (s-dashed-words string))))

(defun elmine/ensure-string (object)
  "Return a string representation of OBJECT."
  (cond ((stringp object) object)
        ((keywordp object) (substring (format "%s" object) 1 nil))
        ((symbolp object) (symbol-name object))
        ((numberp object) (number-to-string object))
        (t (pp-to-string object))))

(defun elmine/api-build-query-string (plist)
  "Builds a query string from a given plist."
  (if plist
      (let (query-pairs)
        (while plist
          (let ((key (url-hexify-string (elmine/ensure-string (car plist))))
                (val (url-hexify-string (elmine/ensure-string (cadr plist)))))
            (setq query-pairs (cons (format "%s=%s" key val) query-pairs))
            (setq plist (cddr plist))))
        (concat "?" (s-join "&" query-pairs)))
    ""))

(defun elmine/api-build-url (path params)
  "Creates a URL from a relative PATH, a plist of query PARAMS and
the dynamically bound `redmine-api-key` and `redmine-host` variables."
  (let ((host (s-chop-suffix "/" redmine-host))
        (query-str (elmine/api-build-query-string params)))
    (concat host path query-str)))

(defun elmine/api-raw (method path data params)
  "Perform a raw HTTP request with given METHOD, a relative PATH and a
plist of PARAMS for the query."
  (let* ((redmine-host (if (boundp 'redmine-host)
                           redmine-host
                         elmine/host))
         (redmine-api-key (if (boundp 'redmine-api-key)
                              redmine-api-key
                            elmine/api-key))
         (url (elmine/api-build-url path params))
         (url-request-method method)
         (url-request-extra-headers
          `(("Content-Type" . "application/json")
            ("X-Redmine-API-Key" . ,redmine-api-key)))
         (url-request-data data)
         header-end status header body)
    (save-excursion
      (switch-to-buffer (url-retrieve-synchronously url))
      (beginning-of-buffer)
      (setq header-end (save-excursion
                         (if (re-search-forward "^$" nil t)
                             (progn
                               (forward-char)
                               (point))
                           (point-max))))
      (when (re-search-forward "^HTTP/\\(1\\.0\\|1\\.1\\) \\([0-9]+\\) \\([A-Za-z ]+\\)$" nil t)
        (setq status (plist-put status :code (string-to-number (match-string 2))))
        (setq status (plist-put status :text (match-string 3))))
      (while (re-search-forward "^\\([^:]+\\): \\(.*\\)" header-end t)
        (setq header (cons (match-string 1) (cons (match-string 2) header))))
      (unless (eq header-end (point-max))
        (setq body (url-unhex-string
                    (buffer-substring header-end (point-max)))))
      (kill-buffer))
    `(:status ,status
      :header ,header
      :body ,body)))

(defun elmine/api-get (element path &rest params)
  "Perform an HTTP GET request and return a PLIST with the request information.
It returns the "
  (let* ((params (if (listp (car params)) (car params) params))
         (response (elmine/api-raw "GET" path nil params))
         (object (elmine/api-decode (plist-get response :body)))
         )
    (if element
        (plist-get object element)
      object)))

(defun elmine/api-post (element object path &rest params)
  "Does an http POST request and returns response status as symbol."
  (let* ((params (if (listp (car params)) (car params) params))
         (data (elmine/api-encode `(,element ,object)))
         (response (elmine/api-raw "POST" path data params))
         (object (elmine/api-decode (plist-get response :body))))
    object))

(defun elmine/api-put (element object path &rest params)
  "Does an http PUT request and returns the response status as symbol.
Either :ok or :unprocessible."
  (let* ((params (if (listp (car params)) (car params) params))
         (data (elmine/api-encode `(,element ,object)))
         (response (elmine/api-raw "PUT" path data params))
         (object (elmine/api-decode (plist-get response :body)))
         (status (elmine/get response :status :code)))
    (cond ((eq status 200) t)
          ((eq status 404)
           (signal 'no-such-resource `(:response ,response))))))

(defun elmine/api-delete (path &rest params)
  "Does an http DELETE request and returns the body of the response."
  (let* ((params (if (listp (car params)) (car params) params))
         (response (elmine/api-raw "DELETE" path nil params))
         (status (elmine/get response :status :code)))
    (cond ((eq status 200) t)
          ((eq status 404)
           (signal 'no-such-resource `(:response ,response))))))

(defun elmine/api-get-all (element path &rest filters)
  "Return list of ELEMENT items retrieved from PATH limited by FILTERS.

Limiting items by count can be done using `limit' in FILTERS:
- If `limit' is t, return all items.
- If `limit' is number, return items up to that count.
- Otherwise return up to 25 items (redmine api default)."
  (let* ((initial-limit (plist-get filters :limit))
         (initial-limit (when (or
                               (eq t initial-limit)
                               (numberp initial-limit))
                          initial-limit))
         (limit (if (eq t initial-limit) 100 initial-limit))
         (response-object (apply #'elmine/api-get nil path (plist-put filters :limit limit)))
         (offset (elmine/get response-object :offset))
         (limit (elmine/get response-object :limit))
         (total-count (elmine/get response-object :total_count))
         (issue-list (elmine/get response-object element)))
    (if (and offset
             limit
             (< (+ offset limit) total-count)
             (or (eq t initial-limit)
                 (and initial-limit (< (+ offset limit) initial-limit))))
        (let* ((offset (+ offset limit))
               (limit (if (eq t initial-limit)
                          t
                        (- initial-limit offset))))
          (append issue-list (apply #'elmine/api-get-all element path
                                    (plist-merge
                                     filters
                                     `(:offset ,offset :limit ,limit)))))
      issue-list)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Simple JSON decode/encode functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun elmine/api-decode (json-string)
  "Parses a JSON string and returns an object. Per default JSON objects are
going to be hashtables and JSON arrays are going to be lists."
  (if (null json-string)
      nil
    (let ((json-object-type 'plist)
          (json-array-type 'list))
      (condition-case err
          (json-read-from-string json-string)
        (json-readtable-error
         (message "%s: Could not parse json-string into an object. See %s"
                  (error-message-string err) json-string))))))

(defun elmine/api-encode (object)
  "Return a JSON representation from the given object."
  (let ((json-object-type 'plist)
        (json-array-type 'list))
    (condition-case err
        (encode-coding-string (json-encode object) 'utf-8)
      (json-readtable-error
       (message "%s: Could not encode object into JSON string. See %s"
                (error-message-string err) object)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; API functions to retrieve data from redmine ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun elmine/get-issues (&rest filters)
  "Get a list of issues."
  (apply #'elmine/api-get-all :issues "/issues.json" filters))

(defun elmine/get-issue (id &rest params)
  "Get a specific issue via id."
  (elmine/api-get :issue (format "/issues/%s.json" id) params))

(defun elmine/create-issue (&rest params)
  "Create an issue.

You can create an issue with giving each of its parameters or simply passing
an issue object to this function."
  (let ((object (if (listp (car params)) (car params) params)))
    (elmine/api-post :issue object "/issues.json")))

(defun elmine/update-issue (object)
  "Update an issue. The object passed to this function gets updated."
  (let ((id (plist-get object :id)))
    (elmine/api-put :issue object (format "/issues/%s.json" id))))

(defun elmine/delete-issue (id)
  "Deletes an issue with a specific id."
  (elmine/api-delete (format "/issues/%s.json" id)))

(defun elmine/get-issue-time-entries (issue-id &rest filters)
  "Gets all time entries for a specific issue."
  (apply #'elmine/api-get-all :time_entries
         (format "/issues/%s/time_entries.json" issue-id) filters))

(defun elmine/get-issue-relations (issue-id)
  "Get all relations for a specific issue."
  (apply #'elmine/api-get-all :relations
         (format "/issues/%s/relations.json" issue-id) nil))

(defun elmine/get-projects (&rest filters)
  "Get a list with projects."
  (apply #'elmine/api-get-all :projects "/projects.json" filters))

(defun elmine/get-project (project)
  "Get a specific project."
  (elmine/api-get :project (format "/projects/%s.json" project)))

(defun elmine/create-project (&rest params)
  "Create a new project."
  (let ((object (if (listp (car params)) (car params) params)))
    (elmine/api-post :project object "/projects.json")))

(defun elmine/update-project (&rest params)
  "Update a given project."
  (let* ((object (if (listp (car params)) (car params) params))
         (identifier (plist-get object :identifier)))
    (elmine/api-put :project object
                    (format "/projects/%s.json" identifier))))

(defun elmine/delete-project (project)
  "Deletes a project."
  (elmine/api-delete (format "/projects/%s.json" project)))

(defun elmine/get-project-categories (project &rest filters)
  "Get all categories for a project."
  (apply #'elmine/api-get-all :issue_categories
         (format "/projects/%s/issue_categories.json" project) filters))

(defun elmine/get-project-issues (project &rest filters)
  "Get a list of issues for a specific project."
  (apply #'elmine/api-get-all :issues
         (format "/projects/%s/issues.json" project) filters))

(defun elmine/get-project-versions (project &rest filters)
  "Get a list of versions for a specific project."
  (apply #'elmine/api-get-all :versions
         (format "/projects/%s/versions.json" project) filters))

(defun elmine/get-project-memberships (project &rest filters)
  "Get PROJECT memberships limited by FILTERS."
  (apply #'elmine/api-get-all :memberships
         (format "/projects/%s/memberships.json" project) filters))

(defun elmine/get-version (id)
  "Get a specific version."
  (elmine/api-get :version (format "/versions/%s.json" id)))

(defun elmine/create-version (&rest params)
  "Create a new version."
  (let* ((object (if (listp (car params)) (car params) params))
         (project (plist-get object :project_id)))
    (elmine/api-post :version object
                     (format "/projects/%s/versions.json" project))))

(defun elmine/update-version (&rest params)
  "Update a given version."
  (let* ((object (if (listp (car params)) (car params) params))
         (id (plist-get object :id)))
    (elmine/api-put :version object
                    (format "/versions/%s.json" id))))

(defun elmine/get-issue-statuses ()
  "Get a list of available issue statuses."
  (elmine/api-get-all :issue_statuses "/issue_statuses.json"))

(defun elmine/get-issue-priorities (&rest params)
  "Get a list of issue priorities."
  (apply #'elmine/api-get-all :issue_priorities
         "/enumerations/issue_priorities.json" params))

(defun elmine/get-trackers ()
  "Get a list of tracker names and their IDs."
  (elmine/api-get-all :trackers "/trackers.json"))

(defun elmine/get-issue-priorities ()
  "Get a list of issue priorities and their IDs."
  (elmine/api-get-all :issue_priorities "/enumerations/issue_priorities.json"))

(defun elmine/get-time-entries (&rest filters)
  "Get a list of time entries."
  (apply #'elmine/api-get-all :time_entries "/time_entries.json" filters))

(defun elmine/get-time-entry (id)
  "Get a specific time entry."
  (elmine/api-get :time_entry (format "/time_entries/%s.json" id)))

(defun elmine/get-time-entry-activities (&rest params)
  "Get a list of time entry activities."
  (apply #'elmine/api-get-all :time_entry_activities
         "/enumerations/time_entry_activities.json" params))

(defun elmine/create-time-entry (&rest params)
  "Create a new time entry"
  (let* ((object (if (listp (car params)) (car params) params)))
    (elmine/api-post :time_entry object "/time_entries.json")))

(defun elmine/update-time-entry (&rest params)
  "Update a given time entry."
  (let* ((object (if (listp (car params)) (car params) params))
         (id (plist-get object :id)))
    (elmine/api-put :time_entry object (format "/time_entries/%s.json" id))))

(defun elmine/delete-time-entry (id)
  "Delete a specific time entry."
  (elmine/api-delete (format "/time_entries/%s.json" id)))

(defun elmine/get-users (&rest filters)
  "Get a list of users limited by FILTERS."
  (apply #'elmine/api-get-all :users "/users.json" filters))

(defun elmine/get-user (user &rest params)
  "Get USER. PARAMS can be used to retrieve additional details.
If USER is `current', get user whose credentials are used."
  (elmine/api-get :user (format "/users/%s.json" user) params))

(provide 'elmine)

;;; elmine.el ends here
