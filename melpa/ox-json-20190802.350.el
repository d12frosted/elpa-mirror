;;; ox-json.el --- JSON export backend for Org mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Jared Lumpe

;; Author: Jared Lumpe <mjlumpe@gmail.com>
;; Version: 0.2.0
;; Package-Version: 20190802.350
;; Package-Commit: aba3face2786d53380ee29459c04d16c999e72ac
;; Keywords: outlines
;; Homepage: https://github.com/jlumpe/ox-json

;; Package-Requires: ((emacs "24") (org "9") (s "1.12"))

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

;; Org mode export backend for exporting the document syntax tree to JSON.
;; The main entry points are `ox-json-export-as-json' and
;; `ox-json-export-to-json'. It can also be used through the built-in
;; export dispatcher through `org-export-dispatch'.

;; Export options:

;; :json-data-type-property (string) - This the name of a property added to all
;;   JSON objects in export to differentiate between structured data and
;;   ordinary key-value mappings. Its default value is "$$data_type". Setting
;;   to nil prevents the property being added altogether.

;; :json-exporters - plist containing exporter functions for different data
;;   types. The keys appear in :json-property-types and can also be used with
;;   `ox-json-encode-with-type'. Functions are called with the value to be
;;   exported and the export info plist. Default values stored in
;;   `ox-json-default-type-exporters'.

;; :json-property-types (plist) - Sets the types of properties of specific
;;   elements/objects. Nested set of plists - the top level is keyed by element
;;   type (see `org-element-type') and the second level by property name (used
;;   with `org-element-property'). Values in 2nd level are keys in the
;;   :json-exporters plist and are used to pick the function that will export
;;   the property value. Properties with a type of t will be encoded using
;;   `ox-json-encode-auto', but this sometimes can produce undesirable
;;   results. The "all" key contains the default property types for all element
;;   types. This option overrides the defaults set in
;;   `ox-json-default-property-types'.

;; :json-strict (bool) - If true an error will be signaled when problems are encountered
;;   in exporting a data structure. If nil the data structure will be exported as an
;;   object containing an error message. Defaults to nil.

;; :json-include-extra-properties (bool) - Whether to export node properties not listed
;;   in the :json-property-types option. If true these properties will be exported
;;   using `ox-json-encode-auto'.

;;; Code:

(eval-when-compile (require 'cl-lib))

(require 'cl-lib)
(require 's)
(require 'json)
(require 'ox)
(require 'org-element)

;; Require json-mode if available, and tell the compiler the json-mode
;; function should be defined
(require 'json-mode nil t)
(declare-function json-mode "ext:json-mode.el")


;;; Private constants

(defconst ox-json-default-type-exporters
  `(
    bool             ,#'ox-json-encode-bool
    string           ,#'ox-json-encode-string
    number           ,#'ox-json-encode-number
    node             ,#'ox-json-export-property-node
    secondary-string ,#'ox-json-export-secondary-string
    array            ,#'ox-json-encode-array
    plist            ,#'ox-json-encode-plist
    alist            ,#'ox-json-encode-alist
    timestamp        ,#'ox-json-export-timestamp-property
    tag-string       ,#'ox-json-encode-tag-string
    t                ,#'ox-json-encode-auto)
  "Default exporter function for each element property type.

Plist mapping property symbols in
`ox-json-default-property-types' to exporter function. These can
be overridden with the :json-exporters option.")

(defconst ox-json-default-property-types
  '(
    all (
      ; Never include parent, leads to infinite recursion
      :parent nil
      ; These properties have to do with absolute buffer positions and thus probably aren't useful to export
      :begin nil
      :end nil
      :contents-begin nil
      :contents-end nil
      ; These can be useful when converting from JSON to another format
      :post-affiliated number
      :pre-blank number
      :post-blank number)
    babel (
      :call string
      :inside-header string
      :arguments string
      :end-header string
      :value string
      :result (array string))
    clock (
      :duration string
      :status string
      :value timestamp)
    code (
      :value string)
    comment (
      :value string)
    comment-block (
      :value string)
    drawer (
      :drawer-name string)
    dynamic-block (
      :arguments string
      :block-name string
      :drawer-name string)
    entity (
      :ascii string
      :ascii string
      :html string
      :latex string
      :latex-math-p bool
      :latin1 string
      :name string
      :use-brackets-p bool
      :utf-8 string)
    example-block (
      :label-fmt string
      :language string
      :number-lines string
      :options string
      :parameters string
      :preserve-indent bool
      :retain-labels bool
      :switches string
      :use-labels bool
      :value string)
    export-block (
      :type string
      :value string)
    export-snipper (
      :back-end string
      :value string)
    footnote-reference (
      :label string
      :type string)
    headline (
      :archivedp bool
      :closed timestamp
      :commentedp bool
      :deadline timestamp
      :footnote-section-p bool
      :level number
      :priority number
      :quotedp bool
      :raw-value string
      :scheduled timestamp
      :tags (array string)
      :title secondary-string
      :todo-keyword string
      :todo-type string)
    inline-babel-call (
      :call string
      :inside-header string
      :arguments string
      :end-header string
      :value string)
    inline-src-block (
      :langauge string
      :parameters string
      :value string)
    inlinetask (
      :closed timestamp
      :deadline timestamp
      :scheduled timestamp
      :title secondary-string)
    item (
      :bullet string
      :checkbox string
      :counter number
      :raw-tag string
      :tag secondary-string
      :structure nil)  ; TODO
    keyword (
      :key string
      :value string)
    latex-environment (
      :value string)
    latex-fragment (
      :value string)
    link (
      :application string
      :format string
      :path string
      :raw-link string
      :search-option string
      :type string)
    macro (
      :args (array string))
    node-property (
      :key string
      :value string)
    plain-list (
      :structure array)
    planning (
      :closed timestamp
      :deadline timestamp
      :scheduled timestamp)
    radio-target (
      :raw-value string)
    special-block (
      :type string
      :raw-value string)
    src-block (
      :label-fmt string
      :language string
      :number-lines string
      :parameters string
      :preserve-indent bool
      :retain-labels bool
      :switches string
      :use-labels bool
      :value string)
    statistics-cookie (
      :value string)
    subscript (
      :use-brackets-p bool)
    superscript (
      :use-brackets-p bool)
    table (
      :tblfm t
      :type string
      :value string)
    table-row (
      :type string)
    target (
      :value string)
    timestamp (
      :day-end nil  ; number
      :day-start nil  ; number
      :hour-end nil  ; number
      :hour-start nil  ; number
      :minute-end nil  ; number
      :minute-start nil  ; number
      :month-end nil  ; number
      :month-start nil  ; number
      :raw-value string
      :repeater-type string
      :repeater-unit string
      :repeater-value number
      :type string
      :warning-type string
      :warning-unit string
      :warning-value number
      :year-end nil  ; number
      :year-start nil)  ; number
    verbatim (
      :value string))
  "Default type symbols for properties of all Org element/object types.

Nested set of plists. Keys are element/object type symbols as
returned by `org-element-type', along with \"all\" which sets the
defaults for all types. The values are plists mapping property
symbols (starting with colons) to type symbols in
`ox-json-default-type-exporters'. A value of nil means to ignore
the property.

These can be overridden with the :json-property-types option.")


;;; Variables
(defgroup ox-json nil "Customization for the ox-json package" :group 'outline)


;;; Generic utility code

(defun ox-json--merge-alists (&rest alists)
  "Merge all alists in ALISTS, with keys in earlier alists overriding later ones."
  (cl-loop
    with keys = (make-hash-table :test 'equal)
    for alist in alists
    append
      (cl-loop
        for item in alist
        unless (gethash (car item) keys)
          collect item
        do (puthash (car item) t keys))))

(defun ox-json--plists-get-default (key default &rest plists)
  "Try getting value for KEY from each plist in PLISTS in order, returning DEFAULT if not found."
  (cl-loop
    for plist in plists
    if (plist-member plist key)
      return (plist-get plist key)
    finally return default))

(defun ox-json--plists-get (key &rest plists)
  "Try getting value for KEY from each plist in PLISTS in order, returning nil if not found."
  (apply #'ox-json--plists-get-default key nil plists))

(cl-defmacro ox-json--loop-plist ((key value plist) &body body)
  "Bind KEY and VALUE to each key-value pair in PLIST and execute BODY within a `cl-loop'."
  (let ((plist-var (gensym)))
    `(let ((,plist-var ,plist)
            (,key nil)
            (,value nil))
      (cl-loop
        while ,plist-var
        do (setq

              ,key (car ,plist-var)
              ,value (cadr ,plist-var)
              ,plist-var (cddr ,plist-var))
        ,@body))))

(defun ox-json--plist-to-alist (plist)
  "Convert plist PLIST to alist."
  (ox-json--loop-plist (key value plist)
    collect (cons key value)))


;;; Org-mode utility code

(defun ox-json-node-properties (node)
  "Get property plist of element/object NODE."
  ; It's the 2nd element of the list
  (cadr node))

(defun ox-json--is-node (value)
  "Check if VALUE is an org element/object."
  (and
    (listp value)
    (listp (cdr value))
    (>= (length value) 2)
    (symbolp (car value))
    (listp (cadr value))))

(defun ox-json-timestamp-isoformat (timestamp suffix _info &optional zone)
  "Convert timestamp time to ISO 8601 format.

TIMESTAMP is a timestamp object from an Org mode parse tree.
SUFFIX is either \"start\" or \"end\".
ZONE is a time zone to pass to `format-time-string'."
  (let* ((minute (org-element-property (intern (concat ":minute-" suffix)) timestamp))
         (hour (org-element-property (intern (concat ":hour-" suffix)) timestamp))
         (day (org-element-property (intern (concat ":day-" suffix)) timestamp))
         (month (org-element-property (intern (concat ":month-" suffix)) timestamp))
         (year (org-element-property (intern (concat ":year-" suffix)) timestamp)))
    (cond
      ; With time
      (hour
        (format-time-string "%Y-%m-%dT%H:%M:00" (encode-time 0 minute hour day month year zone) zone))
      ; Date only (otherwise nil)
      (year
        (format-time-string "%Y-%m-%d" (encode-time 0 0 0 day month year zone) zone)))))


;;; Define the backend

(org-export-define-backend 'json
  ;; Transcoders
  (ox-json--merge-alists
    '(
       (template . ox-json-transcode-template)
       (plain-text . ox-json-transcode-plain-text)
       (headline . ox-json-transcode-headline)
       (link . ox-json-transcode-link)
       (timestamp . ox-json-transcode-timestamp))
    ; Default for all remaining element/object types
    (cl-loop
      for type in (append org-element-all-elements org-element-all-objects)
      collect (cons type #'ox-json-transcode-base)))
  ;; Filters
  :filters-alist '()
  ;; Options
  :options-alist
  '(
     (:json-data-type-property nil "json-data-type-property" "$$data_type")
     (:json-exporters nil nil nil)
     (:json-property-types nil nil nil)
     (:json-strict nil nil nil)
     (:json-include-extra-properties nil nil t))
  ;; Menu
  :menu-entry
  '(?j "Export to JSON" (
	(?J "As JSON buffer" ox-json-export-to-buffer)
	(?j "To JSON file" ox-json-export-to-file))))


;;; User export functions

(defun ox-json-export-to-buffer
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a JSON buffer.

ASYNC, SUBTREEP, VISIBLE-ONLY, BODY-ONLY, and EXT-PLIST are the arguments to
`org-export-to-buffer'."
  ; Modified from org-html-export-as-html:
  (interactive)
  (let ((buffer (org-export-to-buffer 'json "*Org JSON Export*"
                  async subtreep visible-only body-only ext-plist)))
    ; Switch to json mode if available
    (when (fboundp 'json-mode)
      (with-current-buffer buffer
        (json-mode)))
    buffer))


(defun ox-json-export-to-file
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a JSON file.

ASYNC, SUBTREEP, VISIBLE-ONLY, BODY-ONLY, and EXT-PLIST are the arguments to
`org-export-to-file'."
  ; Modified from org-html-export-to-html:
  (interactive)
  (let ((file (org-export-output-file-name ".json" subtreep)))
    (org-export-to-file 'json file
      async subtreep visible-only body-only ext-plist)))


;;; Error handling

(defun ox-json--make-error-obj (info msg args)
  "Create a JSON object with an error message.

INFO is the plist of export options.
MSG is the error message.
ARGS are objects to insert into MSG using `format'."
  (ox-json-make-object "error" info
    `((message string ,(apply #'format msg args)))))

(defun ox-json--error (info msg &rest args)
  "Either signal an error or return an encoded error object.

Behavior is based off the :json-strict export setting.

INFO is the plist of export options.
MSG is the error message.
ARGS are objects to insert into MSG using `format'."
  (if (plist-get info :json-strict)
    (apply #'error msg args)
    (ox-json--make-error-obj info msg args)))

(cl-defun ox-json--type-error (type value info &optional (maxlen 200))
  "Encode or signal an error when asked to encode a value that is not of the expected type."
  (cl-assert (stringp type))
  (let ((value-str (format "%S" value)))
    (when (> (length value-str) maxlen)
      (setq value-str
        (format "%s... (truncated printed value at %d characters)"
          (substring value-str 0 maxlen)
          maxlen)))
    (ox-json--error info "Expected %s, got %s" type value-str)))


;;; Encoders for generic data types

(cl-defun ox-json-encode-bool (value &optional info strict)
  "Encode VALUE to JSON as boolean.

INFO is the plist of export options.
If STRICT is true will only accept t as a true value and raise/return
an error otherwise. If false will accept any truthy value."
  (cond
    ((not value)
      "false")
    ((or (equal value t) (not strict))
      "true")
    (t
      (ox-json--type-error "boolean" value info))))

(defun ox-json-encode-string (value &optional info)
  "Encode VALUE to JSON as string or null.

INFO is the plist of export options.

Also accepts symbols."
  (when (and value (symbolp value))
    (setq value (symbol-name value)))
  (cond
    ((not value)
      "null")
    ((stringp value)
      ; Strip properties, doesn't make a difference to the final output to file
      ; but makes viewing intermediate output while debugging much less messy
      (json-encode-string (substring-no-properties value)))
    (t
      (ox-json--type-error "string or symbol" value info))))

(defun ox-json-encode-number (value &optional info)
  "Encode VALUE to JSON as number or null.

INFO is the plist of export options."
  (cond
    ((numberp value)
      (json-encode-number value))
    ((not value)
      "null")
    (t
      (ox-json--type-error "number" value info))))

(defun ox-json-encode-array-raw (array &optional _info single-line)
  "Encode array to JSON given its already-encoded items.

ARRAY is a list of strings with encoded JSON data.
INFO is the plist of export options.
If SINGLE-LINE is non-nil will put all items on same line, otherwise will use
one line per item."
  (if array
    (if single-line
      (format "[%s]" (s-join ", " array))
      (format "[\n%s\n]" (s-join ",\n" array)))
    "[]"))

(defun ox-json-encode-alist-raw (data-type alist &optional info)
  "Encode alist ALIST containing pre-encoded values into JSON object.

DATA-TYPE is the data type string of the returned object.
INFO is the plist of export options"
  (let ((data-type-property (plist-get info :json-data-type-property)))
    (when (and data-type-property data-type)
      (push (cons data-type-property (json-encode-string data-type)) alist))
    (format "{\n%s\n}"
      (s-join ",\n"
        (cl-loop
          for (key . value) in alist
          collect (format "%s: %s" (json-encode-key key) (s-trim value)))))))

(defun ox-json-encode-plist-raw (data-type plist &optional info)
  "Encode plist PLIST containing pre-encoded values into JSON object.

DATA-TYPE is the data type string of the returned object.
INFO is the plist of export options."
  (ox-json-encode-alist-raw data-type (ox-json--plist-to-alist plist) info))

(defun ox-json-encode-auto (value &optional info)
  "Encode VALUE to JSON when its type is not known ahead of time.

INFO is the plist of export options.

Handles strings, numbers, and org elements/objects without a problem.
Non-empty lists which are not elements/objects are recursively encoded as
JSON arrays. Symbols are encoded as strings except for t which is encoded
as true. This function cannot tell whether a nil value should correspond to an
empty array, false, or null. A null value is arbitrarily returned in this case."
  (cond
    ((not value)
      "null")
    ((stringp value)
      (json-encode-string value))
    ((numberp value)
      (json-encode-number value))
    ((equal value t)
      "true")
    ((symbolp value)
      (json-encode-string (symbol-name value)))
    ((listp value)
      (if (ox-json--is-node value)
        (ox-json-export-data value info)
        (ox-json-encode-array value info)))
    (t
      (ox-json--error info "Don't know how to encode value %S"  value))))

(defun ox-json--get-type-encoder (typekey &optional info)
  "Get the type encoder function for type symbol TYPEKEY.

INFO is the plist of export options."
  (ox-json--plists-get typekey
    (plist-get info :json-exporters)
    ox-json-default-type-exporters))

(defun ox-json-encode-with-type (type value info)
  "Encode a VALUE to JSON given its type.

TYPE is a key in the plist under the :json-exporters option. It may also be list
containing the key followed by additional arguments to pass to the encoder
function.
INFO is the plist of export options."
  (let* ((typekey (if (listp type) (car type) type))
         (args (if (listp type) (cdr type) nil))
         (encoder (ox-json--get-type-encoder typekey info)))
    (if encoder
      (apply encoder value info args)
      (ox-json--error info "Unknown type symbol %s" type))))

(cl-defun ox-json-encode-array (array &optional info (itemtype t) single-line)
  "Encode the list ARRAY as a JSON array.

INFO is the plist of export options.
ITEMTYPE is optional and is the type to pass to `ox-json-encode-with-type'
to encode the items of the array. By default `ox-json-encode-auto' is used.
If SINGLE-LINE is non-nil will put all items on same line, otherwise will use
one line per item."
  (ox-json-encode-array-raw
    (cl-loop
      for item in array
      collect (ox-json-encode-with-type itemtype item info))
    info
    single-line))

(cl-defun ox-json-encode-alist (data-type alist &optional info (valuetype t))
  "Encode the alist ALIST as a JSON object.

DATA-TYPE is a data type string to add to the JSON object.
INFO is the plist of export options.
VALUETYPE is optional and is the type to pass to `ox-json-encode-with-type'
to encode the values of each key-value pair. By default
`ox-json-encode-auto' is used."
  (ox-json-encode-alist-raw
    data-type
    (cl-loop
      for (key . value) in alist
      collect (cons key (ox-json-encode-with-type valuetype value info)))
    info))

(cl-defun ox-json-encode-plist (data-type plist &optional info (valuetype t))
  "Encode the plist PLIST as a JSON object.

DATA-TYPE is a data type string to add to the JSON object.
INFO is the plist of export options.
VALUETYPE is optional and is the type to pass to `ox-json-encode-with-type'
to encode the values of each key-value pair. By default
`ox-json-encode-auto' is used."
  (ox-json-encode-alist
    data-type
    (ox-json--plist-to-alist plist)
    info
    valuetype))

(defun ox-json-make-object (type info properties)
  "Make an encoded JSON object.

TYPE is the data type string to add to the object.
INFO is the plist of export options.
PROPERTIES is an alist of property names and encoded property values."
  (let ((props-alist
          (cl-loop
            for (key type value) in properties
            collect
            (cons
              key
              (if type
                (ox-json-encode-with-type type value info)
                value)))))
    (ox-json-encode-alist-raw type props-alist info)))


;;; Export generic org data

(defun ox-json-export-data (data info)
  "Like `org-export-data' but properly format secondary strings as arrays.

DATA is an org element/object, string, or secondary string.
INFO is the plist of export options."
  (let ((exported (s-trim (org-export-data data info))))
    (if (and (listp data) (not (ox-json--is-node data)))
      (format (if (> (length data) 1) "[\n%s\n]" "[%s]") exported)
      exported)))

(defun ox-json-encode-tag-string (string info)
  "Encode an un-split tag string as a JSON array.

STRING is a collection of tags joined by colon characters.
INFO is the plist of export options."
  (if string
    (ox-json-encode-array (s-split ":" string t) info 'string t)
    "[]"))

(defun ox-json-export-secondary-string (sstring info)
  "Export the secondary string SSTRING as a JSON array.

INFO is the plist of export options.

A secondary string is alist of org elements/objects and strings."
  (if (listp sstring)
    (ox-json-encode-array-raw
      (mapcar
        (lambda (item)
          (cond
            ((stringp item)
              (json-encode-string item))
            ((ox-json--is-node item)
              (ox-json-export-property-node item info))
            (t
              (ox-json--type-error info "org node or string" item))))
        sstring))
    (ox-json--type-error info "list" sstring)))

(defun ox-json-export-property-node (node info)
  "Export an object or element NODE that appears in a property of another node.

INFO is the plist of export options.

Interprets nil as null."
  (cond
    ((ox-json--is-node node)
      (ox-json-export-data node info))
    ((not node)
      "null")
    (t
      (ox-json--type-error "org node or nil" node info))))

(defun ox-json-export-timestamp-property (timestamp info)
  "Export a timestamp object that appears in the properties of another element.

TIMESTAMP is the timestamp object from the org buffer parse tree.
INFO is the plist of export options."
  (ox-json-make-object "timestamp" info
    `(
      (begin string ,(ox-json-timestamp-isoformat timestamp "start" info))
      (end string ,(ox-json-timestamp-isoformat timestamp "end" info))
      (type string ,(org-element-property :type timestamp))
      (raw-value string ,(org-element-property :raw-value timestamp))
      (repeater nil
        ,(ox-json-make-object nil info
           `(
              (type string ,(org-element-property :repeater-type timestamp))
              (unit string ,(org-element-property :repeater-unit timestamp))
              (value number ,(org-element-property :repeater-value timestamp)))))
       (warning nil
         ,(ox-json-make-object nil info
            `(
               (type string ,(org-element-property :warning-type timestamp))
               (unit string ,(org-element-property :warning-unit timestamp))
               (value number ,(org-element-property :warning-value timestamp))))))))

(defun ox-json-export-contents (node info)
  "Export the contents of org element/object NODE as a JSON array.

INFO is the plist of export options.

This is used in place of the \"contents\" argument passed to the transcoder
functions in order to control how the transcoded values of each child node
are joined together, which apparently cannot be overridden. This shouldn't
result in too much extra work being done because the exported value of each
node is memoized."
  (cl-assert (ox-json--is-node node))
  (ox-json-encode-array-raw
    (cl-loop
      with encoded-items = nil
      for item in (org-element-contents node)
      do (let ((encoded (ox-json-export-data item info)))
           (unless (s-blank? encoded)
             (push encoded encoded-items)))
      finally return (nreverse encoded-items))))

(defun ox-json-get-property-type (node-type property info)
  "Get the type of a property in elements/objects of a given type.

NODE-TYPE is a symbol returned by `org-element-type', or 'all to
get the default value.
PROPERTY is the property key to be used with `org-element-property'
\(should start with colon).
INFO is the plist of export options.

The type is looked up from the :json-property-types option, first
looking up the type-specific plist of property types using
NODE-TYPE and then defaulting to the \"all\" type if not found.
The type symbol is then looked up in this plist using PROPERTY.
Returns a symbol which can be passed to `ox-json-encode-with-type'."
  (let ((info-types (plist-get info :json-property-types))
        (include-extra (plist-get info :json-include-extra-properties)))
    (ox-json--plists-get-default
      property
      (if include-extra t nil)
      (plist-get info-types node-type)
      (plist-get info-types 'all)
      (plist-get ox-json-default-property-types node-type)
      (plist-get ox-json-default-property-types 'all))))

(cl-defun ox-json-export-properties-alist (node info &optional (property-plist (ox-json-node-properties node)))
  "Get alist of encoded property values for element/object NODE.

INFO is the plist of export options.
PROPERTY-PLIST is an optional plist of all property values for the node that
overrides the default method of determining them.

Returns an alist where the items are property names and their
JSON-encoded values."
  (let ((node-type (org-element-type node))
        (property-type nil))
    (ox-json--loop-plist (key value property-plist)
      do (setq property-type (ox-json-get-property-type node-type key info))
      if property-type
        collect (cons key (ox-json-encode-with-type property-type value info)))))

(cl-defun ox-json-export-node-base (node info &key extra
                                      (properties (ox-json-export-properties-alist node info))
                                      (contents (ox-json-export-contents node info)))
  "Base export function for a generic org element/object.

NODE is an org element or object and INFO is the export environment plist.
INFO is the plist of export options.
PROPERTIES is an alist of pre-encoded property values that will be used in place
of the return value of `ox-json-export-properties-alist' if given (passing a
value of nil will result in no properties being included).
EXTRA is an alist of keys and pre-encoded values to add directly to the returned
JSON object at the top level (note that this is not checked for conflicts with
the existing keys).
CONTENTS overrides the default way of encoding the node's contents with
`ox-json-export-node-contents'. It can either be a string containing the entire
encoded JSON array or a list of pre-encoded strings.

It is expected for all transcoding functions to call this function to do most
of the work, possibly using the keyword arguments to override behavior."
  (unless (stringp contents)
    (setq contents (ox-json-encode-array-raw contents)))
  (ox-json-encode-alist-raw
    "org-node"
    `(
      (ref . ,(json-encode-string (org-export-get-reference node info)))
      (type . ,(json-encode-string (symbol-name (org-element-type node))))
      ,@extra
      (properties . ,(ox-json-encode-alist-raw "mapping" properties info))
      (contents . ,contents))
    info))


;;; Transcoder functions

(defun ox-json-transcode-plain-text (text &optional _info)
  "Transcode plain text to a JSON string.

TEXT is a string to encode.
INFO is the plist of export options."
  ; Ignore empty strings
  (unless (string= text "")
    (json-encode-string text)))

(cl-defun ox-json-transcode-base (node _contents info)
  "Default transcoding function for all element/object types.

NODE is an element or object to encode.
CONTENTS is a string containing the encoded contents of the node,
but its value is ignored (`ox-json-export-contents' is used instead).
INFO is the plist of export options."
  (ox-json-export-node-base node info))

(defun ox-json--get-doc-info-alist (info)
  "Get alist of top level document properties (values already encoded).

INFO is the plist of export options."
  `(
     (title . ,(ox-json-export-secondary-string (plist-get info :title) info))
     (file_tags . ,(json-encode-list (plist-get info :filetags)))
     (author . ,(ox-json-export-secondary-string (plist-get info :author) info))
     (creator . ,(ox-json-encode-string (plist-get info :creator) info))
     (date . ,(ox-json-export-secondary-string (plist-get info :date) info))
     (description . ,(ox-json-export-secondary-string (plist-get info :description) info))
     (email . ,(ox-json-encode-string (plist-get info :email) info))
     (language . ,(ox-json-encode-string (plist-get info :language) info))))

(defun ox-json-transcode-template (_contents info)
  "Transcode an entire org document to JSON.

CONTENTS is a string containing the encoded document contents,
but its value is ignored (`ox-json-export-contents' is used instead).
INFO is the plist of export options."
  (let* ((docinfo (ox-json--get-doc-info-alist info))
         (parse-tree (plist-get info :parse-tree))
         (contents-encoded (ox-json-export-contents parse-tree info)))
    (ox-json-encode-alist-raw
      "org-document"
      `(
         ,@docinfo
         (contents . ,contents-encoded))
      info)))

(defun ox-json--is-drawer-property-name (name &optional _info)
  "Try to determine if a headline property name came from a property drawer.

NAME is the property name as symbol or string."
  (when (symbolp name)
    (setq name (symbol-name name)))
  (s-uppercase-p name))

(defun ox-json--separate-drawer-properties (properties info)
  "Separate drawer properties from a headline's property plist.

PROPERTIES is a plist of the headline's properties, as from
`ox-json-node-properties'.

INFO is the plist of export options.

Returns a cons cell containing two plists, the regular properties in the car
and the drawer properties in the cdr."
  (let ((regular-props nil)
        (drawer-props nil))
    (ox-json--loop-plist (name value properties)
      do (if (ox-json--is-drawer-property-name name info)
           ; Property drawer
           (let* ((realname (intern (s-replace "+" "" (symbol-name name))))
                  (existing (plist-get drawer-props realname))
                  (strval (format "%s" value))
                  (newval (if existing
                             (concat existing " " strval)
                             strval)))
             (setq drawer-props (plist-put drawer-props realname newval)))
           ; Regular property
           (setq regular-props (plist-put regular-props name value))))
    (cons regular-props drawer-props)))

(defun ox-json-transcode-headline (headline _contents info)
  "Transcode a headline element to JSON.

HEADLINE is the parsed headline to encode.
CONTENTS is a string containing the encoded contents of the headline,
but its value is ignored (`ox-json-export-contents' is used instead).
INFO is the plist of export options."
  (let* ((all-props (ox-json-node-properties headline))
         (rval (ox-json--separate-drawer-properties all-props info))
         (regular-props-plist (car rval))
         (regular-encoded (ox-json-export-properties-alist headline info regular-props-plist))
         (drawer-props-plist (cdr rval))
         (drawer-encoded
             (ox-json-encode-plist "mapping" drawer-props-plist info 'string))
         (extra (when drawer-props-plist `(("property_drawer" . ,drawer-encoded)))))
    (when drawer-encoded
      (cl-assert (stringp drawer-encoded)))
    (ox-json-export-node-base headline info :properties regular-encoded :extra extra)))

(defun ox-json-link-properties (link info)
  "Get properties to export from a link object.

LINK is the parsed link object.
INFO is the plist of export options."
  (let* ((properties (ox-json-export-properties-alist link info))
         (link-type (intern (org-element-property :type link)))
         (is-internal nil))
    ; Check if Org thinks it should be an inline image
    (push
      (cons
        'is-inline-image
        (ox-json-encode-bool (org-export-inline-image-p link) info nil))
        properties)
    ; Handle internal links
    (when (memq link-type '(custom-id fuzzy radio))
      (setq is-internal t)
      (let* ((target
              ; At least one of these functions throws an error if it doesn't resolve
              (condition-case nil
                (cl-case link-type
                  ('custom-id
                    (org-export-resolve-id-link link info))
                  ('fuzzy
                    (org-export-resolve-fuzzy-link link info))
                  ('radio
                    (org-export-resolve-radio-link link info)))
                (error nil)))
             (target-ref (if target (org-export-get-reference target info))))
        (push (cons 'target-ref (ox-json-encode-string target-ref)) properties)))
    (push (cons 'is-internal (ox-json-encode-bool is-internal)) properties)
    properties))

(defun ox-json-transcode-link (link _contents info)
  "Transcode a link object to JSON.

LINK is the parsed link to transcode.
CONTENTS is a string containing the encoded contents of the element,
but its value is ignored (`ox-json-export-contents' is used instead).
INFO is the plist of export options."
  (ox-json-export-node-base link info
    :properties (ox-json-link-properties link info)))

(defun ox-json-timestamp-properties (timestamp info)
  "Get properties to export from a timestamp object.

TIMESTAMP is the parsed timestamp object.
INFO is the plist of export options."
  (let ((properties (ox-json-export-properties-alist timestamp info)))
    (append
      properties
      (list
        (cons 'start (ox-json-encode-string (ox-json-timestamp-isoformat timestamp "start" info)))
        (cons 'end (ox-json-encode-string (ox-json-timestamp-isoformat timestamp "end" info)))))))

(defun ox-json-transcode-timestamp (timestamp _contents info)
  "Transcode a timestamp object to JSON.

TIMESTAMP is the parsed link to transcode.
CONTENTS is a string containing the encoded contents of the element,
but its value is ignored (`ox-json-export-contents' is used instead).
INFO is the plist of export options."
  (ox-json-export-node-base timestamp info
    :properties (ox-json-timestamp-properties timestamp info)))


(provide 'ox-json)

;;; ox-json.el ends here
