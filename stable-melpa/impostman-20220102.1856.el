;;; impostman.el --- Import Postman collections  -*- lexical-binding: t -*-

;; Copyright (C) 2020-2022 Sébastien Helleu <flashcode@flashtux.org>

;; Author: Sébastien Helleu <flashcode@flashtux.org>
;; Maintainer: Sébastien Helleu <flashcode@flashtux.org>
;; Created: 2020-12-24
;; Keywords: tools
;; Package-Version: 20220102.1856
;; Package-Commit: 5b122f3d5a3421aa2d89bdc9dc4aafaf19cf85d4
;; URL: https://github.com/flashcode/impostman
;; Version: 0.3.0-snapshot
;; Package-Requires: ((emacs "27.1"))

;; This file is not part of GNU Emacs.

;; Impostman is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Impostman is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Impostman.  If not, see <https://www.gnu.org/licenses/>.
;;

;;; Commentary:

;; Import Postman collections/environments to use them with your favorite
;; Emacs HTTP client:
;; - verb
;; - restclient
;; - your custom output.

;;; Code:

(require 'subr-x)

;; customization

(defgroup impostman nil
  "Import Postman collections and environments."
  :prefix "impostman-"
  :group 'tools)

(defcustom impostman-auth-basic-as-elisp-code t
  "Convert Basic authentication header to elisp code for easy edit.

Example with verb:
Authorization: Basic {{(base64-encode-string
  (encode-coding-string \"username:password\" 'utf-8) t)}}

Example with restclient:
:auth := (format \"Basic %s\" (base64-encode-string
  (encode-coding-string \"username:password\" 'utf-8) t))
Authorization: :auth

If nil, the username and password are directly encoded in base64:
Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ="
  :type 'boolean)

(defcustom impostman-use-variables t
  "Keep Postman variables in the output and define variables.

If nil, no variables are used, they are directly replaced by their values
during the import of collection."
  :type 'boolean)

(defconst impostman-version "0.3.0-snapshot"
  "Impostman package version.")

(defconst impostman-output-verb-alist
  '((init . ignore)
    (replace-vars . impostman-output-verb-replace-vars)
    (header . impostman-output-verb-header)
    (item . impostman-output-verb-item)
    (request . impostman-output-verb-request)
    (footer . impostman-output-verb-footer)
    (end . impostman-output-verb-end))
  "Emacs verb output.")

(defconst impostman-output-restclient-alist
  '((init . ignore)
    (replace-vars . impostman-output-restclient-replace-vars)
    (header . impostman-output-restclient-header)
    (item . impostman-output-restclient-item)
    (request . impostman-output-restclient-request)
    (footer . impostman-output-restclient-footer)
    (end . impostman-output-restclient-end))
  "Emacs restclient output.")

(defcustom impostman-outputs-alist
  '(("verb" . impostman-output-verb-alist)
    ("restclient" . impostman-output-restclient-alist))
  "Impostman outputs."
  :type '(alist :key-type string :value-type function))

;; functions common to all outputs

(defun impostman-format-comment (comment &optional prefix)
  "Format a comment, which can be on multiple lines.

COMMENT is a string, where multiple lines are separated by \"\\n\".
PREFIX is the prefix to add in front of each line (default is \"# \")."
  (let ((comment (or comment ""))
        (prefix (or prefix "# ")))
    (if (string-empty-p comment)
        ""
      (concat
       prefix
       (replace-regexp-in-string "\n" (concat "\n" prefix) comment)
       "\n"))))

(defun impostman-get-auth-basic-plain (authorization)
  "Get the plain-text \"username:password\" given an AUTHORIZATION header.

For example with the value \"Basic dXNlcm5hbWU6cGFzc3dvcmQ=\",
the function returns \"username:password\".
Return nil if the authentication is not Basic or if the base64 is invalid."
  (save-match-data
    (when (string-match "^Basic \\(.*\\)" authorization)
      (ignore-errors (base64-decode-string (match-string 1 authorization))))))

;; verb output

(defun impostman-output-verb-replace-vars (string variables)
  "Replace variables in a string, using verb syntax.

STRING any string that can contain variables with format \"{{variable}}\".
VARIABLES is an alist with Postman variables."
  (if impostman-use-variables
      (replace-regexp-in-string
       "{{\\([^}]+\\)}}" "{{(verb-var \\1)}}" (or string ""))
    (replace-regexp-in-string
     "{{[^}]+}}"
     (lambda (s)
       (let* ((name (substring s 2 -2))
              (var (assoc name variables)))
         (if var (cdr var) name)))
     (or string ""))))

(defun impostman-output-verb-header (name description variables)
  "Format the verb header.

NAME is the collection name.
DESCRIPTION is the collection description.
VARIABLES is an alist with Postman variables."
  (ignore variables)
  (concat
   "* " name "  :verb:" "\n"
   (impostman-format-comment description)))

(defun impostman-output-verb-item (level name description variables)
  "Format a verb item.

LEVEL is the level.
NAME is the item name.
DESCRIPTION is the item description.
VARIABLES is an alist with Postman variables."
  (ignore variables)
  (concat
   (if (<= level 2) "\n" "")
   (make-string (max level 1) ?*) " " name "\n"
   (impostman-format-comment description)))

(defun impostman-output-verb-request (description method url headers body variables)
  "Format a verb request.

DESCRIPTION is the request description.
METHOD is the HTTP method.
URL is the URL.
HEADERS is an alist with HTTP headers.
BODY is the request body.
VARIABLES is an alist with Postman variables."
  (ignore variables)
  (let (list-headers)
    (dolist (header (nreverse headers))
      (let* ((header-name (car header))
             (header-value (cdr header))
             (new-value header-value))
        (when (and impostman-auth-basic-as-elisp-code
                   (string= header-name "Authorization"))
          (let ((auth-plain (impostman-get-auth-basic-plain header-value)))
            (when auth-plain
              (setq new-value
                    (concat
                     "Basic "
                     "{{(base64-encode-string (encode-coding-string \""
                     auth-plain "\" 'utf-8) t)}}")))))
        (push (concat header-name ": " new-value) list-headers)))
    (concat
     (impostman-format-comment description)
     (downcase method) " " url "\n"
     (when list-headers
       (concat (string-join (nreverse list-headers) "\n") "\n"))
     (if (string-empty-p body) "" (concat "\n" body "\n")))))

(defun impostman-output-verb-footer (name variables)
  "Format the verb footer.

NAME is the collection name.
VARIABLES is an alist with Postman variables."
  (let (list-vars)
    (when impostman-use-variables
      (dolist (var (nreverse variables))
        (push
         (format "# eval: (verb-set-var \"%s\" \"%s\")" (car var) (cdr var))
         list-vars)))
    (concat
     "\n"
     "* End of " name "\n"
     "\n"
     "# Local Variables:\n"
     "# eval: (verb-mode)\n"
     (when list-vars
       (concat (string-join (nreverse list-vars) "\n") "\n"))
     "# End:\n")))

(defun impostman-output-verb-end (variables)
  "Function evaluated at the end.

VARIABLES is an alist with Postman variables."
  (when (fboundp 'org-mode)
    (org-mode))
  (when (fboundp 'verb-mode)
    (verb-mode))
  ;; evaluate variables now
  (when (and impostman-use-variables (fboundp 'verb-set-var))
    (dolist (var (nreverse variables))
      (verb-set-var (car var) (cdr var)))))

;; restclient output

(defun impostman-output-restclient-replace-vars (string variables)
  "Replace variables in a string, using restclient syntax.

STRING any string that can contain variables with format \"{{variable}}\".
VARIABLES is an alist with Postman variables."
  (if impostman-use-variables
      (replace-regexp-in-string
       "{{\\([^}]+\\)}}" ":\\1" (or string ""))
    (replace-regexp-in-string
     "{{[^}]+}}"
     (lambda (s)
       (let* ((name (substring s 2 -2))
              (var (assoc name variables)))
         (if var (cdr var) name)))
     (or string ""))))

(defun impostman-output-restclient-header (name description variables)
  "Format the restclient header.

NAME is the collection name.
DESCRIPTION is the collection description.
VARIABLES is an alist with Postman variables."
  (let (list-vars)
    (when impostman-use-variables
      (dolist (var (nreverse variables))
        (push (format ":%s = %s" (car var) (cdr var)) list-vars)))
    (concat
     "# -*- restclient -*-\n"
     "#\n"
     "# " name "\n"
     (impostman-format-comment description)
     "#\n"
     (when list-vars
       (concat "\n" (string-join (nreverse list-vars) "\n") "\n")))))

(defun impostman-output-restclient-item (level name description variables)
  "Format a restclient item.

LEVEL is the level.
NAME is the item name.
DESCRIPTION is the item description.
VARIABLES is an alist with Postman variables."
  (ignore variables)
  (concat
   (if (<= level 2) "\n" "")
   (make-string (max level 1) ?#) " " name "\n"
   (impostman-format-comment description)))

(defun impostman-output-restclient-request (description method url headers body variables)
  "Format a restclient request.

DESCRIPTION is the request description.
METHOD is the HTTP method.
URL is the URL.
HEADERS is an alist with HTTP headers.
BODY is the request body.
VARIABLES is an alist with Postman variables."
  (ignore variables)
  (let (list-variables list-headers)
    (dolist (header (nreverse headers))
      (let* ((header-name (car header))
             (header-value (cdr header))
             (new-value header-value))
        (when (and impostman-auth-basic-as-elisp-code
                   (string= header-name "Authorization"))
          (let ((auth-plain (impostman-get-auth-basic-plain header-value)))
            (when auth-plain
              (push (concat
                     ":auth := (format \"Basic %s\" "
                     "(base64-encode-string (encode-coding-string \""
                     auth-plain "\" 'utf-8) t))")
                    list-variables)
              (setq new-value ":auth"))))
        (push (concat header-name ": " new-value) list-headers)))
    (concat
     (impostman-format-comment description)
     (when list-variables
       (concat (string-join (nreverse list-variables) "\n") "\n"))
     method " " url "\n"
     (when list-headers
       (concat (string-join (nreverse list-headers) "\n") "\n"))
     (if (string-empty-p body) "" (concat body "\n")))))

(defun impostman-output-restclient-footer (name variables)
  "Format the restclient footer.

NAME is the collection name.
VARIABLES is an alist with Postman variables."
  (ignore variables)
  (concat
   "\n"
   "# End of " name "\n"))

(defun impostman-output-restclient-end (variables)
  "Function evaluated at the end.

VARIABLES is an alist with Postman variables."
  (ignore variables)
  (when (fboundp 'restclient-mode)
    (restclient-mode)))

;; Postman collection parser

(defun impostman--build-auth-headers (auth)
  "Return an alist with headers, based on the `auth' JSON item.

AUTH is a hash table."
  (let* (headers
         (auth (or auth (make-hash-table :test 'equal)))
         (auth-type (gethash "type" auth "")))
    (cond ((string= auth-type "basic")
           (let (username password (basic (gethash "basic" auth [])))
             (dotimes (i (length basic))
               (let* ((item (elt basic i))
                      (key (gethash "key" item ""))
                      (value (gethash "value" item "")))
                 (cond ((string= key "username")
                        (setq username value))
                       ((string= key "password")
                        (setq password value)))))
             (when (or username password)
               (let ((auth-base64
                      (base64-encode-string
                       (encode-coding-string
                        (concat username ":" password) 'utf-8))))
                 (push
                  (cons "Authorization" (concat "Basic " auth-base64))
                  headers)))))
          ((string= auth-type "apikey")
           (let ((apikey (gethash "apikey" auth []))
                 apikey-key apikey-value apikey-in)
             (dotimes (i (length apikey))
               (let* ((apikey-item (elt apikey i))
                      (key (gethash "key" apikey-item ""))
                      (value (gethash "value" apikey-item "")))
                 (cond ((string= key "key")
                        (setq apikey-key value))
                       ((string= key "value")
                        (setq apikey-value value))
                       ((string= key "in")
                        (setq apikey-in value)))))
             (when (and (not (string= apikey-in "query"))
                        (or apikey-key apikey-value))
               (push (cons apikey-key apikey-value) headers)))))
    (nreverse headers)))

(defun impostman--build-headers (header)
  "Return an alist with headers, based on the `header' JSON item.

HEADER is a vector with hash tables."
  (let (headers)
    (dotimes (i (length header))
      (let* ((header-item (elt header i))
             (key (gethash "key" header-item ""))
             (value (gethash "value" header-item "")))
        (push (cons key value) headers)))
    headers))

(defun impostman--build-auth-query-string (auth)
  "Return query string parameter to add for authentication as an alist.

For example: (\"key\" . \"value\"), or nil if there's no query string to add.

AUTH is a hash table."
  (let (query-string-items)
    (when auth
      (let ((auth-type (gethash "type" auth "")))
        (when (string= auth-type "apikey")
          (let ((apikey (gethash "apikey" auth []))
                apikey-key apikey-value apikey-in)
            (dotimes (i (length apikey))
              (let* ((apikey-item (elt apikey i))
                     (key (gethash "key" apikey-item ""))
                     (value (gethash "value" apikey-item "")))
                (cond ((string= key "key")
                       (setq apikey-key value))
                      ((string= key "value")
                       (setq apikey-value value))
                      ((string= key "in")
                       (setq apikey-in value)))))
            (when (and (string= apikey-in "query")
                       (or apikey-key apikey-value))
              (push (cons apikey-key apikey-value) query-string-items))))))
    (nreverse query-string-items)))

(defun impostman--add-query-string-items-to-url (url query-string-items)
  "Return the URL with updated query string parameters.

URL is a string.
QUERY-STRING-ITEMS is nil or an alist with query strings to add."
  (dolist (query-string query-string-items)
    (setq url (concat
               url
               (if (string-match-p "\\?" url) "&" "?")
               (car query-string)
               "="
               (cdr query-string))))
  url)

(defun impostman--build-variables (values)
  "Return alist with variables using Postman collection/environment.

VALUES is the \"variable\" read from collection (vector) or \"values\" read
from environment (vector) (or concatenation of both)."
  (let (variables)
    (dotimes (i (length (or values [])))
      (let* ((item (elt values i))
             (key (gethash "key" item ""))
             (value (gethash "value" item ""))
             (enabled (equal t (gethash "enabled" item t)))
             (disabled (equal t (gethash "disabled" item nil))))
        (when (and enabled (not disabled))
          (push (cons key value) variables))))
    variables))

(defun impostman--parse-item (items level variables output-alist)
  "Parse a Postman collection item.

ITEMS is the \"item\" read from collection (vector).
LEVEL is the level.
VARIABLES is an alist with Postman variables.
OUTPUT-ALIST is an alist with the output callbacks."
  (dotimes (i (length items))
    (let* ((item (elt items i))
           (name (gethash "name" item ""))
           (description (gethash "description" item ""))
           (subitem (gethash "item" item))
           (request (gethash "request" item)))
      (insert (funcall (alist-get 'item output-alist)
                       level name description variables))
      (if subitem
          (impostman--parse-item subitem (1+ level) variables output-alist)
        (when request
          (let* ((description (gethash "description" request ""))
                 (auth (gethash "auth" request (make-hash-table)))
                 (method (gethash "method" request ""))
                 (header (gethash "header" request []))
                 (body (gethash
                        "raw"
                        (gethash "body" request (make-hash-table)) ""))
                 (url (gethash
                       "raw"
                       (gethash "url" request (make-hash-table)) ""))
                 (auth-headers (impostman--build-auth-headers auth))
                 (other-headers (impostman--build-headers header))
                 (headers (append other-headers auth-headers))
                 (replace-vars (alist-get 'replace-vars output-alist)))
            (setq url (impostman--add-query-string-items-to-url
                       url
                       (impostman--build-auth-query-string auth)))
            (dolist (header headers)
              (setf
               (car header) (funcall replace-vars (car header) variables)
               (cdr header) (funcall replace-vars (cdr header) variables)))
            (let ((method2 (funcall replace-vars method variables))
                  (url2 (funcall replace-vars url variables))
                  (body2 (funcall replace-vars body variables)))
              (insert (funcall
                       (alist-get 'request output-alist)
                       description method2 url2 headers body2 variables)))))))))

(defun impostman--parse-json (collection environment output-alist)
  "Parse a Postman collection using an optional Postman environment.

COLLECTION is a hash table with the Postman collection (parsed JSON).
ENVIRONMENT is a hash table with the Postman environment (parsed JSON).
OUTPUT-ALIST is an alist with the output callbacks."
  (let* ((name (gethash "name"
                        (gethash "info" collection (make-hash-table))
                        "unknown"))
         (description (gethash "description"
                               (gethash "info"
                                        collection (make-hash-table)) ""))
         (item (gethash "item" collection []))
         (variable (gethash "variable" collection []))
         (values (gethash "values" environment []))
         (all-variables (impostman--build-variables (vconcat
                                                     variable values))))
    (pop-to-buffer (generate-new-buffer (concat name ".org")))
    (funcall (alist-get 'init output-alist) all-variables)
    (insert (funcall (alist-get 'header output-alist)
                     name description all-variables))
    (impostman--parse-item item 2 all-variables output-alist)
    (insert (funcall (alist-get 'footer output-alist) name all-variables))
    (goto-char (point-min))
    (funcall (alist-get 'end output-alist) all-variables)
    values))

;;;###autoload
(defun impostman-parse-file (collection environment output-alist)
  "Parse a file with a Postman collection.

COLLECTION is a Postman collection filename.
ENVIRONMENT is a Postman environment filename (optional).
OUTPUT-ALIST is an alist with the output callbacks."
  (let (json_col (json_env (make-hash-table :test 'equal)))
    (with-temp-buffer
      (insert-file-contents collection)
      (setq json_col (json-parse-buffer)))
    (unless (string-empty-p (or environment ""))
      (with-temp-buffer
        (insert-file-contents environment)
        (setq json_env (json-parse-buffer))))
    (impostman--parse-json json_col json_env output-alist)))

;;;###autoload
(defun impostman-parse-string (collection environment output-alist)
  "Parse a string with a Postman collection.

COLLECTION is a string with a Postman collection.
ENVIRONMENT is a string with a Postman environment (optional).
OUTPUT-ALIST is an alist with the output callbacks."
  (let ((json_col (json-parse-string collection))
        (json_env (if (string-empty-p (or environment ""))
                      (make-hash-table :test 'equal)
                    (json-parse-string environment))))
    (impostman--parse-json json_col json_env output-alist)))

;; Postman collection import

(defun impostman-read-collection-filename ()
  "Read Postman collection filename."
  (interactive)
  (read-file-name "Postman collection file (JSON): "))

(defun impostman-read-environment-filename ()
  "Read Postman environment filename."
  (interactive)
  (let (insert-default-directory)
    (read-file-name "Postman environment file (JSON, optional): ")))

(defun impostman-read-output ()
  "Read Postman output type.

It which must be a key from alist `impostman-outputs-alist'.

If the alist size is 1, the value is immediately returned without asking
anything."
  (interactive)
  (let* ((default (caar impostman-outputs-alist))
         (prompt (concat "Output format (default is " default "): ")))
    (if (= (length impostman-outputs-alist) 1)
        default
      (completing-read
       prompt impostman-outputs-alist nil t nil nil default))))

(defun impostman--get-output-alist (name)
  "Get output alist with a given NAME.

A key with this name must exist in `impostman-outputs-alist'."
  (let ((output-alist (assoc name impostman-outputs-alist)))
    (if output-alist
        (symbol-value (cdr output-alist))
      (error "Output \"%s\" is not supported" name))))

;;;###autoload
(defun impostman-import-file (&optional collection environment output-name)
  "Import a file with a Postman collection.

COLLECTION is a Postman collection filename.
ENVIRONMENT is a Postman environment filename (optional).
OUTPUT-NAME is a string with the desired output (eg: \"verb\")."
  (interactive)
  (let* ((collection (or collection (impostman-read-collection-filename)))
         (environment (or environment (impostman-read-environment-filename)))
         (output-name (or output-name (impostman-read-output)))
         (output-alist (impostman--get-output-alist output-name)))
    (impostman-parse-file collection environment output-alist)))

;;;###autoload
(defun impostman-import-string (collection environment &optional output-name)
  "Import a string with a Postman collection.

COLLECTION is a string with a Postman collection.
ENVIRONMENT is a string with a Postman environment (optional).
OUTPUT-NAME is a string with the desired output (eg: \"verb\")."
  (interactive)
  (let* ((output-name (or output-name (impostman-read-output)))
         (output-alist (impostman--get-output-alist output-name)))
    (impostman-parse-string collection environment output-alist)))

;; version

;;;###autoload
(defun impostman-version (&optional print-dest)
  "Return the Impostman version.

PRINT-DEST is the output stream, by default the echo area.

With \\[universal-argument] prefix, output is in the current buffer."
  (interactive (list (if current-prefix-arg (current-buffer) t)))
  (when (called-interactively-p 'any)
    (princ (format "impostman %s" impostman-version) print-dest))
  impostman-version)

(provide 'impostman)

;;; impostman.el ends here
