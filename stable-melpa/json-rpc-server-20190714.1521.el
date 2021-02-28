;;; json-rpc-server.el --- Server-side JSON-RPC library.  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  GitHub user "Jcaw"

;; Author: GitHub user "Jcaw"
;; URL: https://github.com/jcaw/json-rpc-server.el
;; Package-Version: 20190714.1521
;; Package-Commit: 2f41d292b87916f6989e7ff5dc94da18ae6a9e4e
;; Keywords: tools, comm, json, rpc
;; Version: 0.2.0
;; Package-Requires: ((emacs "26"))

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

;; This is a full implementation of the JSON-RPC 2.0 protocol[1] for Emacs. You
;; pass in a JSON string, Emacs executes the specified function(s), and a
;; JSON-RPC 2.0 response is returned.

;; It was originally part of Porthole, a full-fledged HTTP-based RPC server for
;; Emacs:

;; http://www.github.com/jcaw/porthole

;; The underlying JSON-RPC protocol was extracted into a separate package so
;; that it could serve as a framework on which other RPC servers could be built.

;; *No transport logic is included.* This package is designed to sit underneath
;; a transport layer, which is responsible for communicate with external
;; clients. Since JSON-RPC provides no inbuilt mechanism for authenticating
;; requests, the transport layer should also handle authentication.

;; Here's en example request:

;; {
;;   "jsonrpc": "2.0",
;;   "method": "insert",
;;   "params": ["some text to insert"],
;;   "id": "3140983184"
;; }

;; Pass this as a string to `json-rpc-server-handle' - the specified text will
;; be inserted and the return value of the call to `insert' will be encoded into
;; a response.

;; Symbols and keywords can be passed by abusing the JSON-RPC syntax as follows:

;; {
;;   "a symbol": "'a-symbol",
;;   "a keyword": ":a-keyword"
;; }

;; This is a simplified explanation of the package that glosses over a lot of
;; details. Please refer to the full README[3] for an up-to-date and thorough
;; explanation.

;; [1] https://www.jsonrpc.org/specification

;; [2] https://groups.google.com/d/msg/json-rpc/PN462g49yL8/DdMa93870_o

;; [3] http://www.github.com/jcaw/json-rpc-server.el/README.md


;;; Code:


(require 'json)
(require 'cl-lib)


(defgroup json-rpc-server nil
  "Group relating to json-rpc-server.el"
  :prefix "json-rpc-server-"
  :link `(url-link :tag "Send Bug Report"
                   "https://github.com/jcaw/json-rpc-server.el/issues")
  :link '(url-link :tag "Other Emacs packages by Jcaw"
                   "https://github.com/jcaw?utf8=%E2%9C%93&tab=repositories&q=&type=source&language=emacs+lisp")
  :link '(url-link :tag "Homepage"
                   "https://github.com/jcaw/json-rpc-server.el")
  :group 'tools)


(defvar json-rpc-server--error-codes
  '((json-rpc-server-invalid-request-json . -32700)
    (json-rpc-server-invalid-request      . -32600)
    (json-rpc-server-invalid-function     . -32601)
    (json-rpc-server-invalid-params       . -32602)
    (json-rpc-server-error-calling-method . -32603))
  "Alist mapping procedural errors to their JSON-RPC 2.0 error codes.")


(defvar json-rpc-server--unknown-error-code  -32603
  "Error code to be used for unknown errors.")


(defun json-rpc-server--get-error-code (error-symbol)
  "Get the JSON-RPC 2.0 specification error code for an error.

`ERROR-SYMBOL' should be a symbol representing the error."
  (interactive)
  (or (alist-get error-symbol json-rpc-server--error-codes)
      json-rpc-server--unknown-error-code))


(defun json-rpc-server--construct-error-response (error-code
                                    message
                                    &optional
                                    underlying-error)
  "Encode a JSON-RPC 2.0 error response.

The result will be a JSON-RPC 2.0 response string, containing
information about the error. For example:

`((\"jsonrpc\" . \"2.0\")
  (\"error\" . ((code . -32600)
                (message . \"This is an error.\")
                (data . [...]))))

This method does not include an `id' in the response. The id must
be added before this response is actually returned.

Arguments:

`ERROR-CODE' - The error code to respond with.

`MESSAGE' - The message to send.

`UNDERLYING-ERROR' - Optional. You may wish to add an underlying
  Elisp error to the response, for example if there was a problem
  executing the supplied method. Pass it here and it will be
  encoded and attached. Default: nil"
  (let* (
         ;; The additional data should be an alist of additional data keys to
         ;; their data.
         ;;
         ;; Additional data should *only* have a value when additional data exists.
         ;; It should be null otherwise.
         (additional-data nil))
    (when underlying-error
      (setq additional-data
            (append
             additional-data
             `((underlying-error . ((type . ,(car underlying-error))
                                    ;; The data should be a list, since it's a
                                    ;; `cdr'. Encode as much of it as we can.
                                    (data . ,(mapcar 'json-rpc-server--replace-unencodable-object
                                                     (cdr underlying-error)))))))))
    ;; The id will be added later.
    `(("jsonrpc" . "2.0")
      ("error" . ((code . ,error-code)
                  (message . ,message)
                  (data . ,additional-data))))))


(cl-defun json-rpc-server--throw-error-response (error-code message &key (original-error nil))
  "Throw a `json-rpc-server-respond' signal with an error response attached.

`MESSAGE' - the error message to attach.

`:ORIGINAL-ERROR' - Optional. The original error that was thrown.
  Information about this error will be sent back in the
  response."
  (throw 'json-rpc-server-respond
         (json-rpc-server--construct-error-response error-code message original-error)))


(cl-defun json-rpc-server--throw-invalid-json (message &key (original-error nil))
  "Throw a `json-rpc-server-response' with a \"malformed JSON\" error code.

`MESSAGE' - the error message to attach.

`:ORIGINAL-ERROR' - Optional. The original error that was thrown.
  Information about this error will be sent back in the
  response."
  (json-rpc-server--throw-error-response
   (json-rpc-server--get-error-code 'json-rpc-server-invalid-request-json)
   message
   :original-error original-error))


(defun json-rpc-server--throw-invalid-request (message)
  "Throw a `json-rpc-server-response' with an \"invalid request\" error code.

`MESSAGE' is the error message to attach."
  (json-rpc-server--throw-error-response
   (json-rpc-server--get-error-code 'json-rpc-server-invalid-request)
   message))


(defun json-rpc-server--throw-invalid-function (message)
  "Throw a `json-rpc-server-response' with an \"invalid function\" error code.

`MESSAGE' is the error message to attach."
  (json-rpc-server--throw-error-response
   (json-rpc-server--get-error-code 'json-rpc-server-invalid-function)
   message))


(cl-defun json-rpc-server--throw-error-calling-method (message &key original-error)
  "Throw a `json-rpc-server-response' with an \"internal error\" error code.

`MESSAGE' is the error message to attach.

`:ORIGINAL-ERROR' - The original error that was thrown.
  Information about this error will be sent back in the
  response."
  (json-rpc-server--throw-error-response
   (json-rpc-server--get-error-code 'json-rpc-server-error-calling-method)
   message
   :original-error original-error))


(defun json-rpc-server--throw-result (result)
  "Throw a `json-rpc-server-response' with a successful result attached.

`RESULT' should be the raw result of the method execution."
  (throw 'json-rpc-server-respond (json-rpc-server--construct-result-response result)))


(defun json-rpc-server--construct-result-response (result)
  "Create a JSON-RPC 2.0 response with a successful result.

`RESULT' should be the raw result data returned by the procedure
invoked.

Example output:

'((\"jsonrpc\" . \"2.0\")
  (\"result\"  . 6))

This method does not attach an \"id\" to the response. The id
should be added before this response is returned to a client."
  ;; TODO: Handle errors encoding the result. If that happens, the response
  ;; should be a new JSON-RPC error defined by this API to indicate that the
  ;; response could not be encoded.
  ;;
  ;; The id will be added later
  `(("jsonrpc" . "2.0")
    ("result" . ,result)))


;; --------------------------------------------------------------------------


(defun json-rpc-server-null-p (value)
  "Is `VALUE' either nil, or json-null?

Other falsey values, such as 0, do not count. Note that the empty
list is equivalent to nil, so the empty list counts as nil."
  (or (eq value nil)
      (eq value json-null)))


(defun json-rpc-server-alist-get (key alist)
  "Like `alist-get', but works with string keys.

`KEY' is the key to query.
`ALIST' is the alist to search."
  (let ((pair (assoc key alist)))
    (and pair
         (eq (type-of pair) 'cons)
         (cdr pair))))


(defun json-rpc-server--call-function-internal (func args)
  "Apply `FUNC' to `ARGS'.

This wrapper is abstracted from `json-rpc-server--call-function'
to make it easier for developers to debug function calls
themselves, without worrying about broader behavior."
  (apply func args))


(defun json-rpc-server--call-function (func args)
  "Execute the remote procedure call for `FUNC' with `ARGS'."
  ;; TODO: Allow macro calls here too?
  (condition-case err
      (json-rpc-server--call-function-internal func args)
    (error
     (json-rpc-server--throw-error-calling-method
      "There was an error calling the method."
      :original-error err))))


(defun json-rpc-server--execute-request (request exposed-functions)
  "Execute a remote procedure call.

`REQUEST' should be an alist representing a JSON-RPC 2.0 request.

`EXPOSED-FUNCTIONS' should be a list of function symbols that are
allowed to be executed. The method will not be executed unless
it's in this list. See `json-rpc-server-handle' for more details.

An error will be raised if the function in the request does not
exist (or has not been exposed.)"
  (let* ((method-name (json-rpc-server-alist-get "method" request))
         ;; Because we can only transport strings via JSON, the method name has
         ;; to be encoded as a string. That means we have to manually convert it
         ;; into a symbol before invocation.
         (method-symbol
          ;; If the method-name was quoted, it will already have been converted
          ;; to a symbol.
          (if (symbolp method-name)
              method-name
            ;; I don't know what kind of strings fail to convert to symbols, but
            ;; add error handling just in case.
            (condition-case nil
                (intern method-name)
              (error
               (json-rpc-server--throw-invalid-request
                (concat
                 "`method` could not be converted to an Elisp symbol. It "
                 "should be a string that converts into an elisp symbol."))))))
         (args (json-rpc-server-alist-get "params" request)))
    ;; We now check that the function is legal, and callable, before trying to
    ;; call it.
    (unless (member method-symbol exposed-functions)
      (json-rpc-server--throw-invalid-function
       (concat
        "Function has not been exposed (it may or may not exist). Cannot "
        "execute.")))
    (unless (functionp method-symbol)
      (json-rpc-server--throw-invalid-function
       "This symbol has been exposed, but it is not a function. Cannot call it."))
    ;; TODO: Check if function is callable with args. Can the function signature
    ;;   be checked in Elisp?
    (json-rpc-server--call-function method-symbol args)))


(defun json-rpc-server--validate-request (request-alist)
  "Validate that a decoded request has the correct structure.

The request should be provided in the form of an alist, in
`REQUEST-ALIST'.

If the request is invalid, an error response signal will be
thrown. Ensure these signals are caught."
  (when (json-rpc-server-null-p request-alist)
    (json-rpc-server--throw-invalid-request "No request provided"))
  (unless (json-alist-p request-alist)
    (json-rpc-server--throw-invalid-request "The request was not a JSON \"object\""))
  (let* ((jsonrpc       (json-rpc-server-alist-get "jsonrpc" request-alist))
         (method        (json-rpc-server-alist-get "method"  request-alist))
         (params        (json-rpc-server-alist-get "params"  request-alist))
         (id            (json-rpc-server-alist-get "id"      request-alist))
         ;; If there's no `jsonrpc' parameter, we assume this is probably a
         ;; jsonrpc 1.0 request.
         (appears-to-be-jsonrpc-v1 (json-rpc-server-null-p jsonrpc))
         ;; It's jsonrpc 2.0 iff the jsonrpc string is "2.0" *exactly*.
         (is-jsonrpc-v2.0 (and (stringp jsonrpc)
                               (string= jsonrpc "2.0"))))
    ;; The supported jsonrpc versions are 2.0 and lower. Other versions are not
    ;; supported.
    (unless (or is-jsonrpc-v2.0
                appears-to-be-jsonrpc-v1)
      (json-rpc-server--throw-invalid-request
       (concat "Only jsonrpc versions 1 to 2.0 are supported. jsonrpc 2.0 is "
               "preferred. If the `jsonrpc` parameter is included, it must be "
               "\"2.0\" exactly.")))
    (unless method
      (json-rpc-server--throw-invalid-request "`method` was not provided."))
    ;; TODO: Perhaps ensure the function is not a `json-rpc-server' function?
    ;; E.g. disallow the `json-rpc-server-' prefix? Perhaps not. Unlikely to be reliable.
    ;; User should simply never expose those functions.
    (unless (or (stringp method)
                ;; Sometimes users may get confused and send a symbol as the
                ;; method name. That's fine. Tolerate this behavior.
                (symbolp method))
      (json-rpc-server--throw-invalid-request "`method` should be a string."))
    ;; `params' should be a list of arguments, but it is optional. We have to
    ;; allow a nil value.
    (unless (or (json-rpc-server-null-p params)
                (listp params))
      ;; TODO: Should this be a JSON-RPC "invalid params" error?
      (json-rpc-server--throw-invalid-request
       (concat "`params` was provided, but it was not an array. Could "
               "not decode the parameters into a list.")))
    (unless id
      (json-rpc-server--throw-invalid-request "`id` not provided"))
    ;; "id" can be a string or a number. Floats are allowed, which seems odd
    ;; given the potential for rounding errors.
    (unless (or (numberp id)
                (stringp id))
      (json-rpc-server--throw-invalid-request "`id` should be an integer."))
    request-alist))


(defun json-rpc-server--decode-request-json (json)
  "Decode JSON with custom rules and error handling.

Arrays will be decoded into lists, objects (dictionaries) will be
decoded into alists, and keys will be decoded into symbols.

If there is an error parsing the JSON, a response will be thrown
indicating that the request had invalid json. Ensure this
response is caught."
  ;; Decode symbol-like strings into symbols. Do this as part of the JSON
  ;; parsing process.
  (json-rpc-server--replace-symbol-strings
   ;; Set some custom options for the JSON decoder.
   (let (
         ;; Arrays should be decoded as lists, because this is the array-like
         ;; type most methods are going to expect.
         ;;
         ;; This adds a limitation to the RPC server. Some functions may expect
         ;; vectors, but only one type of list can be transferred via JSON. Those
         ;; functions will receive lists. This will have to be fixed manually by
         ;; the user with some kind of proxy function.
         (json-array-type 'list)
         ;; Hash tables are faster, but alists are more common.
         (json-object-type 'alist)
         ;; Keys should be symbols because alists keys should generally be
         ;; symbols, not strings.
         (json-key-type 'string)
         )
     (condition-case err
         (json-read-from-string json)
       (error
        ;; Catch JSON errors and raise a json-rpc-server error that can be more easily
        ;; understood.
        (json-rpc-server--throw-invalid-json
         "There was an error decoding the request's JSON."
         :original-error err))))))


(defun json-rpc-server--replace-symbol-strings (object)
  "Replace symbol-like strings with symbols.

`OBJECT' is the decoded JSON object you want to modify. It should
be composed of only the basic JSON types, decoded into Elisp.

This is a hack that allows symbols (most importantly, keyword
arguments) to be sent over the JSON-RPC protocol. It takes
strings prefixed with a single \"'\" or \":\", and converts them
into symbols. For example:

  \"'some-name\" -> 'some-name

  \":KEYWORD\" -> :KEYWORD

Strings with more than one quote/colon won't be converted. For
example:

  \"'a quote'\" -> \"'a quote'\"

This method replaces the symbols inline in the request structure.
The structure itself will be modified.

This is a recursive function. It will call itself. Ensure
`max-lisp-eval-depth' is high enough to parse your JSON object."
  (cond ((stringp object)
         (cond ((string-match "^:[^:]+$" object)
                ;; If there's an error interning the object, just pass back the
                ;; original string.
                (condition-case nil
                    (intern object)
                  (error object)))
               ((string-match "^'[^']+$" object)
                ;; If there's an error interning the object, just pass back the
                ;; original string.
                (condition-case nil
                    ;; If it's prefixed with a quote, we have to shave off the quote
                    ;; before interning.
                    (intern (substring object 1))
                  (error object)))
               ;; It wasn't a symbol. Return the original string.
               (t object)))
        ((consp object)
         (cons (json-rpc-server--replace-symbol-strings (car object))
               (json-rpc-server--replace-symbol-strings (cdr object))))
        (t object)))


(defun json-rpc-server--replace-unencodable-object (object)
  "Replace `OBJECT' if it can't be encoded into JSON.

This function is designed to sanitise complex objects before they
are encoded.

Method:

  1. This function attempts to encode `OBJECT' into JSON.

  2a. If it works, that's fine - the original `OBJECT' is
      returned, unaltered.

  2b. If it can't be encoded, that's a problem. A string is
      returned instead, indicating that the object could not be
      encoded properly.

Usage example:

  Let's say an error was raised during method execution, and
  we're trying it. This shouldn't be a problem, but an error can
  theoretically contain any kind of data. There is a (very small)
  risk that the error will contain data that can't be encoded,
  crashing the JSON serializer.

  We can call this method on the data in the error to protect
  ourselves. If some part can't be encoded, it will simply be
  replaced with a message for the end user indicating the
  problem."
  ;; TODO: Replace only the lowest-level objects, if possible. Would have to
  ;;   make this function recursive to do that.
  (condition-case nil
      (progn
        (json-encode object)
        object)
    (error
     (format
      (concat "[Object of type %s could not be encoded into JSON. "
              "This string was inserted instead.]")
      (type-of object)))))


(defun json-rpc-server--extract-id (decoded-request)
  "Attempt to extract a valid ID from a request alist and NOTHING ELSE.

If no valid ID could be extracted, returns nil. Valid IDs are
numbers and strings.

This method will not raise errors.

`DECODED-REQUEST' should be a JSON-RPC request (up to 2.0),
decoded from JSON into an alist form."
  (ignore-errors
    (let ((id (json-rpc-server-alist-get "id" decoded-request)))
      (when (or (stringp id)
                (integerp id))
        id))))


(defun json-rpc-server--decode-id (request-in-json)
  "Attempt to decode a valid id from a JSON request and NOTHING ELSE.

If no valid id could be decoded, returns nil.

This method will not raise errors.

`REQUEST-IN-JSON' should be a JSON-RPC request (up to 2.0) in
JSON form."
  (ignore-errors
    (json-rpc-server--extract-id (json-rpc-server--decode-request-json request-in-json))))


(defun json-rpc-server-unknown-error-response (&optional request-in-json)
  "Construct a JSON response indicating an unknown error.

This is a utility method for the transport layer to use when it
wishes to send a JSON-RPC 2.0 error without knowing any details.

If possible, please supply this method with the original JSON-RPC
request, as a JSON string, in `REQUEST-IN-JSON'. It will be used
by this method to extract as much information as possible for the
response."
  (json-rpc-server-internal-error-response "An unknown error occurred"
                                request-in-json))


(defun json-rpc-server-internal-error-response (message &optional request-in-json)
  "Construct a JSON response indicating internal error `MESSAGE'.

This is a utility method for the transport layer to use to
generate a valid JSON-RPC 2.0 response related to an arbitrary
internal error. For example, if there is an internal error in the
transport layer, this could be used to wrap the error into a
valid JSON-RPC 2.0 response.

If possible, please supply this method with the original JSON-RPC
request, as a JSON string, in `REQUEST-IN-JSON'. It will be used
by this method to extract as much information as possible for the
response."
  ;; We manually construct the JSON from a string to minimise the chance of an
  ;; unexpected error, or a strange encoding of the JSON.

  ;; Ensure `MESSAGE' is a string to ensure it encodes predictably (i.e. as a
  ;; string).
  (unless (stringp message)
    (error "%s" "`message' must be a string"))
  (let ((id (or (json-rpc-server--decode-id request-in-json)
                "null")))
    (format
     "
{
    \"jsonrpc\": \"2.0\",
    \"error\": {
        \"code\": -32700,
        \"message\": %s,
        \"data\": null
    },
    \"id\": %s
}"
     ;; We encode the message explicitly to prevent something being injected
     ;; into the JSON.
     (json-encode message)
     id)))


(defun json-rpc-server--ammend-id (id response)
  "Add an \"id\" to a JSON-RPC response.

`ID' should be the id. `RESPONSE' should be the raw response,
before it's encoded into a string."
  (append response `((id . ,id))))


(defun json-rpc-server--handle-single (decoded-request exposed-functions)
  "Handle a single JSON-RPC request.

`DECODED-REQUEST' should be a JSON-RPC (up to 2.0) request,
decoded into an alist.

`EXPOSED-FUNCTIONS' should be a list of function symbols that are
allowed to be executed. The method will not be executed unless
it's in this list. See `json-rpc-server-handle' for more details.

Returns the JSON-RPC response, encoded in JSON."
    (let (
          ;; We attempt to decode the id using a robust method, to give us the
          ;; maximum chance of being able to include it in the response if there is
          ;; an error.
          ;;
          ;; This may still fail - that's OK. We just want to maximize the chance
          ;; of extracting it.
          (id (json-rpc-server--extract-id decoded-request)))
      (json-rpc-server--ammend-id
       id
       (catch 'json-rpc-server-respond
         (json-rpc-server--construct-result-response
          (json-rpc-server--execute-request
           (json-rpc-server--validate-request decoded-request)
           exposed-functions))))))


(defun json-rpc-server-handle (request-in-json exposed-functions)
  "Handle a JSON-RPC request.

Parameters
----------

`REQUEST-IN-JSON' should be a JSON-RPC (up to 2.0) request,
encoded in a JSON string.

`EXPOSED-FUNCTIONS' should be a list of function symbols that are
exposed to RPC calls. The RPC call will only be executed if its
method is in this list.

  - Each function name should be a symbol.

  - Do not include raw functions such as lambdas.

  - Do not include string names.

Returns the JSON-RPC 2.0 response, encoded in a JSON string.

Description
-----------

This is the main entry point into the RPC layer. This is the
method that decodes the RPC request and executes it. This method
is transport-agnostic - transport has to be implemented
separately.

This method can take either a single encoded request, or an
encoded list of requests, per the JSON-RPC 2.0 specification.

Please note that this implementation deviates slightly from the
JSON-RPC 2.0 specification:

  1. Notifications are not supported. All RPC requests will
     receive a response. Notifications may be implemented above
     this layer, at the transport level.

  2. Batch requests are not processed concurrently. Batch
     requests will always be processed in the order they are
     supplied. Responses will be supplied in the same order."
  (json-encode
   (catch 'json-rpc-server-respond
    ;; Per JSON-RPC 2.0 specification, requests can either be single requests or
    ;; a list of requests. Each type has to be handled differently, so we decode
    ;; it up-front.
    (let* ((decoded-request (json-rpc-server--decode-request-json request-in-json))
           ;; Because JSON objects (i.e. dictionaries) will be decoded into
           ;; alists, we can't just assume lists are batch requests. Single
           ;; requests will also look like lists. Instead, ensure the request is
           ;; a list *and* not a dictionary.
           (is-batch-request (and
                              ;; If the request is an empty list (or null), we
                              ;; can't iterate over it. We have to process it
                              ;; as a single request.
                              (not (json-rpc-server-null-p decoded-request))
                              (listp decoded-request)
                              (not (json-alist-p decoded-request)))))
      (if is-batch-request
          ;; Process each request in turn; Return all the results, in a list.
          (mapcar (lambda (request)
                    "Handle a single request from the batch"
                    (json-rpc-server--handle-single request exposed-functions))
                  decoded-request)
        (json-rpc-server--handle-single decoded-request exposed-functions))))))


(provide 'json-rpc-server)
;;; json-rpc-server.el ends here
