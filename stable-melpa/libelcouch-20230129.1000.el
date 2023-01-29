;;; libelcouch.el --- Communication with CouchDB  -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2023  Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>
;; Keywords: tools
;; Package-Version: 20230129.1000
;; Package-Commit: 595697f4199519dd018fe489e885f237c54b0675
;; Url: https://gitlab.petton.fr/elcouch/libelcouch/
;; Package-requires: ((emacs "26.1") (request "0.3.0"))
;; Version: 0.11.0

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

;; The package libelcouch is an Emacs library client to communicate with
;; CouchDB (https://couchdb.apache.org/), a database focusing on ease of
;; use and having a scalable architecture.  For a user interface, please
;; check the elcouch project instead (which depends on this one).

;;; Code:
(require 'cl-lib)
(require 'request)
(require 'json)
(require 'map)

(require 'subr-x)


;;; Customization

(defgroup libelcouch nil
  "View and manipulate CouchDB databases."
  :group 'external)

(defcustom libelcouch-couchdb-instances nil
  "List of CouchDB instances."
  :type 'list)

(defcustom libelcouch-timeout 10
  "Timeout in seconds for calls to the CouchDB instance.
Number of seconds before a call to CouchDB without answer is
considered to have failed."
  :type 'number)


;;; Structures

(cl-defstruct (libelcouch-named-entity
               (:constructor libelcouch--named-entity-create)
               (:conc-name libelcouch--named-entity-))
  (name nil :read-only t)
  (parent nil :read-only t))

(cl-defstruct (libelcouch-instance
               (:include libelcouch-named-entity)
               (:constructor libelcouch--instance-create)
               (:conc-name libelcouch--instance-))
  (url nil :read-only t))

(cl-defstruct (libelcouch-database
               (:include libelcouch-named-entity)
               (:constructor libelcouch--database-create)
               (:conc-name libelcouch--database-))
  nil)

(cl-defstruct (libelcouch-document
               (:include libelcouch-named-entity)
               (:constructor libelcouch--document-create)
               (:conc-name libelcouch--document-))
  nil)

(cl-defstruct (libelcouch-design-document
               (:include libelcouch-named-entity)
               (:constructor libelcouch--design-document-create)
               (:conc-name libelcouch--design-document-))
  nil)

(cl-defstruct (libelcouch-view
               (:include libelcouch-named-entity)
               (:constructor libelcouch--view-create)
               (:conc-name libelcouch--view-))
  nil)

(cl-defstruct (libelcouch-view-row
               (:include libelcouch-named-entity)
               (:constructor libelcouch--view-row-create)
               (:conc-name libelcouch--view-row-))
  (key nil :read-only t)
  (value nil :read-only t))


;;; Accessors

(cl-defgeneric libelcouch-entity-name ((entity libelcouch-named-entity))
  "Return the name of ENTITY."
  (libelcouch--named-entity-name entity))

(cl-defgeneric libelcouch-entity-parent ((entity libelcouch-named-entity))
  "Return the entity containing ENTITY, nil if none."
  (libelcouch--named-entity-parent entity))

(cl-defgeneric libelcouch-entity-full-name ((entity libelcouch-named-entity))
  "Return the full name of ENTITY's parent followed by ENTITY name."
  (format "%s/%s"
          (libelcouch-entity-name (libelcouch-entity-parent entity))
          (libelcouch-entity-name entity)))

(cl-defmethod libelcouch-entity-full-name ((entity libelcouch-instance))
  "Return the name of ENTITY."
  (libelcouch-entity-name entity))

(cl-defgeneric libelcouch-entity-instance (entity)
  "Return the CouchDB instance of ENTITY."
  (and entity (libelcouch-entity-instance (libelcouch-entity-parent entity))))

(cl-defmethod libelcouch-entity-instance ((instance libelcouch-instance))
  "Return INSTANCE."
  instance)

(cl-defgeneric libelcouch-entity-database (entity)
  "Return the DATABASE containing ENTITY."
  (and entity (libelcouch-entity-database (libelcouch-entity-parent entity))))

(cl-defmethod libelcouch-entity-database ((database libelcouch-database))
  "Return DATABASE."
  database)

(cl-defun libelcouch-entity-weburl (entity)
  "Return the URL of the web application to edit ENTITY."
  (format "%s/_utils/#database%s%s"
          (libelcouch--instance-url (libelcouch-entity-instance entity))
          (libelcouch-entity-baseurl entity)
          (if (equal (type-of entity) 'libelcouch-database)
              "/_all_docs"
            "")))

(cl-defun libelcouch-entity-url (entity)
  "Return the API URL of ENTITY."
  (format "%s%s"
          (libelcouch--instance-url (libelcouch-entity-instance entity))
          (libelcouch-entity-baseurl entity)))

(cl-defgeneric libelcouch-entity-baseurl (entity)
  "Return the base URL of ENTITY."
  (format "%s/%s"
          (libelcouch-entity-baseurl (libelcouch-entity-parent entity))
          (libelcouch-entity-name entity)))

(cl-defmethod libelcouch-entity-baseurl ((_ libelcouch-instance))
  "Return the base URL of INSTANCE."
  "")

(cl-defmethod libelcouch-entity-baseurl ((design-document libelcouch-design-document))
  "Return the base URL of DESIGN-DOCUMENT."
  (format "%s/_design/%s"
          (libelcouch-entity-baseurl (libelcouch-entity-parent design-document))
          (libelcouch-entity-name design-document)))

(cl-defmethod libelcouch-entity-baseurl ((view libelcouch-view))
  "Return the base URL of VIEW."
  (format "%s/_view/%s"
          (libelcouch-entity-baseurl (libelcouch-entity-parent view))
          (libelcouch-entity-name view)))

(defun libelcouch-entity-from-url (url)
  "Return an entity by reading URL, a string."
  (let* ((url-obj (url-generic-parse-url url))
         (host (url-host url-obj))
         (path (car (url-path-and-query url-obj)))
         (path-components (split-string path "/" t))
         ;; authority is the beginning of the url until the path starts:
         (authority (substring url 0 (unless (string-empty-p path)
                                       (- (length path)))))
         (instance (libelcouch--instance-create
                    :name host
                    :url authority))
         (database (when (and instance (>= (length path-components) 1))
                     (libelcouch--database-create
                      :name (car path-components)
                      :parent instance)))
         (document (when (and database (>= (length path-components) 2))
                     (libelcouch--document-create
                      :name (cadr path-components)
                      :parent database))))
    (or document database instance)))

(defun libelcouch-view-row-key (view-row)
  "Return the key associated with VIEW-ROW."
  (libelcouch--view-row-key view-row))

(defun libelcouch-view-row-value (view-row)
  "Return the value associated with VIEW-ROW."
  (libelcouch--view-row-value view-row))

(defun libelcouch-view-row-document (view-row)
  "Create and return the document associated with VIEW-ROW."
  (let ((document-name (libelcouch-entity-name view-row))
        (database (libelcouch-entity-database view-row)))
    (libelcouch--create-document document-name database)))

(defun libelcouch-choose-instance ()
  "Ask user for a CouchDB instance among `libelcouch-couchdb-instances'."
  (let* ((instances (libelcouch-instances))
         (instance-name (completing-read "CouchDB instance: "
                                         (mapcar #'libelcouch-entity-name instances)
                                         nil
                                         t)))
    (cl-find instance-name instances :test #'string= :key #'libelcouch-entity-name)))


;;; Private helpers

(cl-defgeneric libelcouch--entity-create-children-from-json (entity json)
  "Create and return children of ENTITY from a JSON object.")

(cl-defmethod libelcouch--entity-create-children-from-json ((instance libelcouch-instance) json)
  "Return the list of INSTANCE's databases as stored in JSON."
  (mapcar
   (lambda (database-name) (libelcouch--database-create :name database-name :parent instance))
   json))

(cl-defmethod libelcouch--entity-create-children-from-json ((database libelcouch-database) json)
  "Return the list of DATABASE's documents as stored in JSON."
  (let ((documents-json (map-elt json 'rows)))
    (mapcar
     (lambda (document-json)
       (libelcouch--create-document (map-elt document-json 'id) database))
     documents-json)))

(cl-defmethod libelcouch--entity-create-children-from-json ((design-document libelcouch-design-document) json)
  "Return the list of DESIGN-DOCUMENT's views as stored in JSON."
  (let ((views-json (map-elt json 'views)))
    (mapcar
     (lambda (view-json)
       (libelcouch--view-create :name (symbol-name (car view-json)) :parent design-document))
     views-json)))

(cl-defmethod libelcouch--entity-create-children-from-json ((view libelcouch-view) json)
  "Return the list of VIEW's rows as stored in JSON."
  (let ((views-json (map-elt json 'rows)))
    (mapcar
     (lambda (view-json)
       (libelcouch--view-row-create
        :name (map-elt view-json 'id)
        :parent view
        :key (map-elt view-json 'key)
        :value (map-elt view-json 'value)))
     views-json)))

(defun libelcouch--create-document (name database)
  "Create either a normal document or a design document.

NAME is the name of the new document.  If it starts with
\"_design\", a design document will be created.

DATABASE is the parent of the new document."
  (save-match-data
    (if (string-match "^_design/\\(.*\\)$" name)
        (libelcouch--design-document-create :name (match-string-no-properties 1 name) :parent database)
      (libelcouch--document-create :name name :parent database))))

(cl-defgeneric libelcouch--entity-children-url (entity)
  "Return the path to query all children of ENTITY."
  (libelcouch-entity-url entity))

(cl-defmethod libelcouch--entity-children-url ((instance libelcouch-instance))
  "Return the URL of INSTANCE's databases."
  (format "%s/%s" (libelcouch-entity-url instance) "_all_dbs"))

(cl-defmethod libelcouch--entity-children-url ((database libelcouch-database))
  "Return the URL of DATABASE's documents."
  (format "%s/%s" (libelcouch-entity-url database) "_all_docs"))

(cl-defun libelcouch--request-error (&rest args &key error-thrown &allow-other-keys)
  "Report an error when communication with an instance fails.

Displays ERROR-THROWN, ignore ARGS."
  (message "Got error: %S" error-thrown))

(defun libelcouch--auth-search (instance)
  "Return (USER . PASSWORD) associated with INSTANCE.
Return nil if no authentication information is found for INSTANCE."
  (if-let* ((url-obj (url-generic-parse-url (libelcouch--instance-url instance)))
            (host (url-host url-obj))
            (port (or (url-portspec url-obj) 5984))
            (entry (car (auth-source-search
                         :max 1
                         :host host
                         :port port)))
            (user (map-elt entry :user))
            (password (map-elt entry :secret)))
      (cons user
            (if (stringp password)
                password
              (funcall password)))))

(defun libelcouch--basic-auth-header (instance)
  "Return a basic authentication header for INSTANCE."
  (pcase-let ((`(,username . ,password) (libelcouch--auth-search instance)))
    (format "Basic %s" (base64-encode-string (concat username ":" password)))))


;;; Navigating

(defun libelcouch-instances ()
  "Return a list of COUCHDB instances built from `libelcouch-couchdb-instances'."
  (mapcar
   (lambda (instance-data)
     (libelcouch--instance-create
      :name (car instance-data)
      :url (cadr instance-data)))
   libelcouch-couchdb-instances))

(cl-defgeneric libelcouch-entity-list (entity function)
  "Evaluate FUNCTION with the children of ENTITY as parameter."
  (request
    (url-encode-url (libelcouch--entity-children-url entity))
    :timeout libelcouch-timeout
    :headers `(("Content-Type" . "application/json")
               ("Accept" . "application/json")
               ("Authorization" . ,(libelcouch--basic-auth-header (libelcouch-entity-instance entity))))
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (let* ((children (libelcouch--entity-create-children-from-json entity data)))
                  (funcall function children))))
    :error #'libelcouch--request-error)
  nil)

(defun libelcouch-document-content (document function)
  "Evaluate FUNCTION with the content of DOCUMENT as parameter."
  (request
    (url-encode-url (libelcouch-entity-url document))
    :timeout libelcouch-timeout
    :parser (lambda () (decode-coding-string (buffer-substring-no-properties (point) (point-max)) 'utf-8))
    :headers `(("Accept" . "application/json")
               ("Authorization" . ,(libelcouch--basic-auth-header (libelcouch-entity-instance document))) )
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (funcall function data)))
    :error #'libelcouch--request-error)
  nil)

(defun libelcouch-document-save (document content function)
  "Evaluate FUNCTION when CONTENT is saved as new value for DOCUMENT."
  (request
    (url-encode-url (libelcouch-entity-url document))
    :type "PUT"
    :headers `(("Content-Type" . "application/json")
               ("Authorization" . ,(libelcouch--basic-auth-header (libelcouch-entity-instance document))) )
    :data (or content (encode-coding-string (buffer-substring-no-properties (point-min) (point-max)) 'utf-8))
    :success (cl-function (lambda (&rest _args) (funcall function)))
    :error #'libelcouch--request-error)
  nil)

(defun libelcouch-document-latest-revision (document function)
  "Pass the revision of DOCUMENT to FUNCTION."
  (libelcouch-document-content
   document
   (lambda (content)
     (with-temp-buffer
       (insert content)
       (goto-char (point-min))
       (funcall function (map-elt (json-read) '_rev))))))

(defun libelcouch-document-delete (document revision &optional function)
  "Delete DOCUMENT and evaluate FUNCTION.
If REVISION is not the latest, signal an error."
  (request
    (url-encode-url (libelcouch-entity-url document))
    :type "DELETE"
    :params `(("rev" . ,revision))
    :headers `(("Content-Type" . "application/json")
               ("Accept" . "application/json")
               ("Authorization" . ,(libelcouch--basic-auth-header (libelcouch-entity-instance document))))
    :success (cl-function (lambda (&rest _args) (when function (funcall function))))
    :error #'libelcouch--request-error)
  nil)

(defun libelcouch-document-delete-latest (document &optional function)
  "Delete DOCUMENT and evaluate FUNCTION."
  (libelcouch-document-latest-revision
   document
   (lambda (revision)
     (libelcouch-document-delete document revision function))))

(defun libelcouch-browse-weburl (entity)
  "Open ENTITY in a web browser."
  (browse-url (libelcouch-entity-weburl entity)))

(provide 'libelcouch)
;;; libelcouch.el ends here

;; LocalWords:  CouchDB
