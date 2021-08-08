;;; graphql-doc.el --- GraphQL Documentation Explorer -*- lexical-binding: t -*-

;; Copyright (c) 2021 Ian Fitzpatrick <itfitzpatrick@gmail.com>

;; Author: Ian Fitzpatrick
;; Created: April 25, 2021
;; Version: 0.2.1
;; Package-Version: 20210808.8
;; Package-Commit: 6ba7961fc9c5c9818bd60abce6ba9dfef2dad452
;; Package-Requires: ((emacs "26.1") (request "0.3.2") (promise "1.1"))
;; URL: https://github.com/ifitzpatrick/graphql-doc.el
;; SPDX-License-Identifier: GPL-3.0-only

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; GraphQL Documentation explorer
;;
;; Opens a buffer with clickable graphql documentation for queries and mutations
;; generated from a graphql introspection query.  Use `graphql-doc` to start with
;; a registered graphql api endpoint.  Use `graphql-doc-open-url` to start with
;; an endpoint url.  Use `graphql-doc-add-api` to register an api endpoint.

;;; Code:

(require 'cl-lib)
(require 'promise)
(require 'request)

(defvar graphql-doc--introspection-query
"query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      ...FullType
    }
    directives {
      name
      description
      
      locations
      args {
        ...InputValue
      }
    }
  }
}

fragment FullType on __Type {
  kind
  name
  description
  
  fields(includeDeprecated: true) {
    name
    description
    args {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes {
    ...TypeRef
  }
}

fragment InputValue on __InputValue {
  name
  description
  type { ...TypeRef }
  defaultValue
}

fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
    }
  }
}")

(defun graphql-doc--request (url data headers)
  "GraphQL request to URL with DATA and HEADERS."
  (promise-new
   (lambda (resolve reject)
     (request
       url
       :type "POST"
       :parser 'json-read
       :data
       data
       :headers
       headers
       :error
       (cl-function
        (lambda (&key response &allow-other-keys)
          (funcall reject (request-response-data response))))
       :success
       (cl-function
        (lambda (&key response &allow-other-keys)
          (funcall resolve (request-response-data response))))))))

(defvar-local graphql-doc--introspection-results nil)

(defun graphql-doc--request-introspection (api)
  "Request introspection query from API."
  (promise-chain
      (graphql-doc--request
       (plist-get api :url)
       (append
        (plist-get api :data)
        `(("query" . ,graphql-doc--introspection-query)))
       (plist-get api :headers))
    (then (lambda (data)
            (setq-local graphql-doc--introspection-results data)))
    (promise-catch (lambda (data)
                     (message "error: %s" data)))))

(defgroup graphql-doc nil
  "GraphQL documentation explorer options."
  :prefix "graphql-doc-"
  :group 'tools)

(defcustom graphql-doc-apis nil
  "Alist mapping name to an api plist."
  :group 'graphql-doc
  :type '(alist))

(defun graphql-doc-add-api (name api)
  "Add an entry (NAME . API) to apis alist."
  (add-to-list 'graphql-doc-apis `(,name . ,api)))

(defun graphql-doc--get-api (name)
  "Get api plist NAME out of `graphql-doc-apis.'."
  (cdr (assoc name graphql-doc-apis)))

(defun graphql-doc--get (key-list list)
  "Follow KEY-LIST to get property out of LIST."
  (if (and key-list list)
      (graphql-doc--get (cdr key-list) (assq (car key-list) list))
    (cdr list)))

(defun graphql-doc--get-types ()
  "Get info about types supported by endpoint."
  (graphql-doc--get '(data __schema types) graphql-doc--introspection-results))

(defun graphql-doc--get-type (name)
  "Get info about type NAME."
  (seq-find
   (lambda (type) (equal name (graphql-doc--get '(name) type)))
   (graphql-doc--get-types)))

(defun graphql-doc--get-query-type ()
  "Get name of queryType."
  (graphql-doc--get '(data __schema queryType name)
                    graphql-doc--introspection-results))

(defun graphql-doc--get-mutation-type ()
  "Get name of queryType."
  (graphql-doc--get '(data __schema mutationType name)
                    graphql-doc--introspection-results))

(defun graphql-doc--queries ()
  "Get info about queries supported by endpoint."
  (seq-find
   (lambda (type) (equal (graphql-doc--get '(name) type)
                         (graphql-doc--get-query-type)))
   (graphql-doc--get-types)))

(defun graphql-doc--mutations ()
  "Get info about mutations supported by endpoint."
  (seq-find
   (lambda (type) (equal (graphql-doc--get '(name) type)
                         (graphql-doc--get-mutation-type)))
   (graphql-doc--get-types)))

(defvar-local graphql-doc--history nil
  "List of cons cells with a name and callback that can redraw each entry.")

(defvar-local graphql-doc--current-view-name nil
  "Current view name.")

(defvar-local graphql-doc--current-view-callback nil
  "Current view callback.")

(defun graphql-doc--history-push (name callback)
  "Add history entry with NAME and CALLBACK."
  (when (and graphql-doc--current-view-name graphql-doc--current-view-callback)
    (setq-local graphql-doc--history (cons `(,graphql-doc--current-view-name ,graphql-doc--current-view-callback ,(point)) graphql-doc--history)))
  (setq-local graphql-doc--current-view-name name)
  (setq-local graphql-doc--current-view-callback callback))

(defun graphql-doc-go-back ()
  "Go back to previous history entry."
  (interactive)
  (when (> (length graphql-doc--history) 0)
    (let* ((current-view (car graphql-doc--history))
           (name (nth 0 current-view))
           (callback (nth 1 current-view))
           (old-point (nth 2 current-view)))
      (setq-local graphql-doc--history (cdr graphql-doc--history))
      (setq-local graphql-doc--current-view-name name)
      (setq-local graphql-doc--current-view-callback callback)
      (funcall callback)
      (goto-char old-point))))

(defun graphql-doc--draw-view (callback)
  "Draw view with CALLBACK."
  (let ((inhibit-read-only t))
    (erase-buffer)
    (funcall callback))
  (goto-char (point-min)))

(defun graphql-doc--view (name callback)
  "Draw view with NAME and CALLBACK and and to history."
  (graphql-doc--history-push name (lambda () (graphql-doc--draw-view callback)))
  (graphql-doc--draw-view callback))

(defun graphql-doc--draw-object-type-button (type)
  "Draw a button for TYPE."
  (let ((kind (graphql-doc--get '(kind) type))
        (of-type (graphql-doc--get '(ofType) type))
        (name (graphql-doc--get '(name) type)))
    (cond ((equal kind "LIST")
           (graphql-doc--draw-object-type-button of-type)
           (insert "[]"))
          ((equal kind "NON_NULL")
           (graphql-doc--draw-object-type-button of-type)
           (insert "!"))
          (t (if type
                 (graphql-doc--draw-button
                  name
                  (lambda ()
                    (interactive)
                    (graphql-doc--draw-object-page
                     (graphql-doc--get-type name))))
               (insert name))))))
  
(defun graphql-doc--draw-object-arg-button (arg)
  "Draw a button for ARG."
  (insert (graphql-doc--get '(name) arg) ": ")
  (graphql-doc--draw-object-type-button (graphql-doc--get '(type) arg)))

(defun graphql-doc--draw-object-arg-buttons (args)
  "Draw a list of ARGS."
  (when (> (length args) 0)
    (insert "(")
    (seq-map-indexed
     (lambda (arg idx)
       (graphql-doc--draw-object-arg-button arg)
       (when (< idx (- (length args) 1))
         (insert ", ")))
     args)
    (insert ")")))

(defun graphql-doc--draw-object-name-buttons (item)
  "Draw buttons for ITEM name."
  (let ((name (graphql-doc--get '(name) item))
        (args (graphql-doc--get '(args) item))
        (type (graphql-doc--get '(type) item)))
    (graphql-doc--draw-button name (graphql-doc--get-callback item))
    (graphql-doc--draw-object-arg-buttons args)
    (when type
      (insert ": ")
      (graphql-doc--draw-object-type-button type))
    (insert "\n\n")))

(defun graphql-doc--draw-list-item (item)
  "Draw ITEM in a list."
  (graphql-doc--draw-object-name-buttons item)
  (graphql-doc--draw-object-description item))

(defun graphql-doc--draw-list-separator (title)
  "Draw list item with TITLE."
  (insert "-----" title "-----" "\n\n"))

(defun graphql-doc--draw-list (item-list title)
  "Draw a list of graphql objects ITEM-LIST with TITLE."
  (when (> (length item-list) 0)
    (graphql-doc--draw-list-separator title)
    (seq-map
     #'graphql-doc--draw-list-item
     item-list)))

(defun graphql-doc--draw-key-list (item list-key title)
  "Draw a list of graphql properties from ITEM using LIST-KEY to get the list, with TITLE."
  (graphql-doc--draw-list (graphql-doc--get (list list-key) item) title))

(defun graphql-doc--draw-type-list (item list-key title)
  "Draw a list of graphql properties from ITEM using LIST-KEY to get the list, with TITLE."
  (graphql-doc--draw-list
   (seq-map
    (lambda (list-item) (graphql-doc--get-type (graphql-doc--get '(name) list-item)))
    (graphql-doc--get (list list-key) item))
   title))

(defun graphql-doc--draw-object-description (graphql-object)
  "Draw GRAPHQL-OBJECT description if present."
  (let ((description (graphql-doc--get '(description) graphql-object)))
    (when (> (length description) 0)
      (insert description "\n\n"))))

(defun graphql-doc--draw-object (graphql-object)
  "Draw page for GRAPHQL-OBJECT."
  (insert "Name: " (graphql-doc--get '(name) graphql-object) "\n\n")
  (graphql-doc--draw-object-description graphql-object))

(defun graphql-doc--draw-button (label next)
  "Base button with LABEL and call NEXT when pressed."
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] next)
    (define-key map [?\r] next)
    (insert-text-button label 'keymap map)))

(defun graphql-doc--get-callback (graphql-object)
  "Create view callback for GRAPHQL-OBJECT."
  (lambda ()
     (interactive)
     (graphql-doc--draw-object-page graphql-object)))

(defun graphql-doc--draw-object-page (query-object)
  "Draw page for QUERY-OBJECT."
  (graphql-doc--view
   (graphql-doc--get '(name) query-object)
   (lambda ()
     (graphql-doc--draw-object query-object)
     (graphql-doc--draw-key-list query-object 'args "Arguments")
     (graphql-doc--draw-type-list query-object 'possibleTypes "Implementations")
     (graphql-doc--draw-type-list query-object 'interfaces "Interfaces")
     (graphql-doc--draw-key-list query-object 'fields "Fields")
     (graphql-doc--draw-key-list query-object 'inputFields "Fields")
     (graphql-doc--draw-key-list query-object 'enumValues "Enum Values"))))

(defun graphql-doc--draw-root-page (name items)
  "Draw root page NAME with ITEMS representing root operations."
  (graphql-doc--view
   name
   (lambda ()
     (seq-map
      (lambda (item)
        (let ((name (graphql-doc--get '(name) item))
              (next (graphql-doc--get '(next) item)))
          (graphql-doc--draw-button name next)
          (insert "\n\n")
          (graphql-doc--draw-object-description item)))
      items))))

(defvar graphql-doc-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "C-j") 'forward-button)
    (define-key keymap (kbd "C-k") 'backward-button)
    (define-key keymap (kbd "<backspace>") 'graphql-doc-go-back)
    keymap)
  "The keymap for `graphql-doc-mode'.")

(define-derived-mode graphql-doc-mode
  special-mode "GraphQL Doc"
  "Major mode for GraphQL Doc viewing.")

(defun graphql-doc-reset ()
  "Reset vars."
  (interactive)
  (setq-local graphql-doc--history nil)
  (setq-local graphql-doc--introspection-results nil))

(defun graphql-doc--display-buffer (base-name)
  "Display GraphQL Doc buffer named BASE-NAME."
  (switch-to-buffer (generate-new-buffer-name (concat "*graphql-doc " base-name "*"))))

(defun graphql-doc--display-loading ()
  "Display loading screen."
  (graphql-doc--draw-view (lambda () (insert "Loading..."))))

(defun graphql-doc--start (name api)
  "Initialize GraphQL Doc buffer for API NAME."
  (let ((buf (graphql-doc--display-buffer name)))
    (with-current-buffer buf
      (setq-local graphql-doc--history nil)
      (graphql-doc-mode)
      (graphql-doc--display-loading)
      (promise-chain (graphql-doc--request-introspection api)
        (then
         (lambda (_)
           (graphql-doc--draw-root-page
            "Root"
            '(((name . "queries")
               (description . "Available queries")
               (next . (lambda () (interactive)
                         (graphql-doc--draw-object-page
                          (graphql-doc--queries)))))
              ((name . "mutations")
               (description . "Available mutations")
               (next . (lambda () (interactive)
                         (graphql-doc--draw-object-page
                          (graphql-doc--mutations)))))))))
        (promise-catch (lambda (reason) (message "failed to load %s" reason)))))))

;;;###autoload
(defun graphql-doc-open-url (url)
  "Open URL in graphql doc buffer."
  (interactive "surl: ")
  (graphql-doc--start
   url
   `(:url ,url)))

;;;###autoload
(defun graphql-doc ()
  "Open graphql doc buffer."
  (interactive)
  (let ((name (completing-read
               "Choose API: "
               graphql-doc-apis)))
    (graphql-doc--start name (graphql-doc--get-api name))))

(provide 'graphql-doc)

;;; graphql-doc.el ends here
