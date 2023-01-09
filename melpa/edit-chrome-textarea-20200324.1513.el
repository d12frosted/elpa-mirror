;;; edit-chrome-textarea.el --- Edit Chrome Textarea  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Xu Chunyang

;; Author: Xu Chunyang
;; Homepage: https://github.com/xuchunyang/edit-chrome-textarea.el
;; Package-Requires: ((emacs "25.1") (websocket "1.4"))
;; Keywords: tools
;; Version: 0

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

;; Edit Chrome Textarea via Chrome DevTools Protocol
;; <https://chromedevtools.github.io/devtools-protocol/>

;; How to use:
;; 1. Focus a textarea or input
;; 2. M-x edit-chrome-textarea
;; 3. C-c C-c

;;; Code:

(require 'websocket)
(require 'cl-lib)
(require 'json)

(defvar url-http-end-of-headers)
(defvar url-http-response-status)

(defgroup edit-chrome-textarea nil
  "Edit Chrome Textarea."
  :group 'applications)

(defcustom edit-chrome-textarea-host "127.0.0.1"
  "Host where the Chrome DevTools Protocol is running."
  :type 'string)

(defcustom edit-chrome-textarea-port 9222
  "Port where the Chrome DevTools Protocol is running."
  :type 'integer)

(defcustom edit-chrome-textarea-persistent-message t
  "Non-nil means show persistent exit help message while editing textarea.
The message is shown in the header-line, which will be created in the
first line of the window showing the editing buffer."
  :type 'boolean)

(defcustom edit-chrome-textarea-guess-mode-function
  #'edit-chrome-textarea-default-guess-mode-function
  "The function used to guess the major mode of an editing buffer.
It's called with the editing buffer as the current buffer.
It's called with three arguments, URL, TITLE and CONTENT."
  :type 'function)

(defun edit-chrome-textarea-default-guess-mode-function (_url _title _content)
  "Set major mode for editing buffer depending on URL, TITLE and CONTENT."
  ;; no-op
  (text-mode))

(defvar-local edit-chrome-textarea-current-connection nil
  "A `edit-chrome-textarea-connection' object associated with the current buffer.")

(defun edit-chrome-textarea--json-read-from-string (string)
  "Read JSON in STRING."
  (let ((json-object-type 'alist)
        (json-key-type 'symbol)
        (json-array-type 'list)
        (json-false nil)
        (json-null nil))
    (json-read-from-string string)))

(defun edit-chrome-textarea--url-request (url)
  "Request URL, decode response body as JSON and return it."
  (with-current-buffer (url-retrieve-synchronously url)
    (goto-char url-http-end-of-headers)
    (cl-assert (= 200 url-http-response-status))
    (prog1 (edit-chrome-textarea--json-read-from-string
            (decode-coding-string
             (buffer-substring-no-properties (point) (point-max))
             'utf-8))
      (kill-buffer))))

(defun edit-chrome-textarea--first-page ()
  "Return first page of Chrome, that is, the active tab's page."
  (car (edit-chrome-textarea--url-request
        (format "http://%s:%d/json"
                edit-chrome-textarea-host
                edit-chrome-textarea-port))))

(defvar edit-chrome-textarea-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'edit-chrome-textarea-finalize)
    (define-key map (kbd "C-c C-s") 'edit-chrome-textarea-send)
    (define-key map (kbd "C-c C-k") 'edit-chrome-textarea-discard)
    map)
  "The minor mode keymap.")

(defun edit-chrome-textarea-finalize ()
  "Send current buffer to Chrome, close connection, kill buffer."
  (interactive)
  (pcase edit-chrome-textarea-current-connection
    ('nil (user-error "No connection associated with current buffer"))
    (conn
     (let-alist (edit-chrome-textarea--request
                 conn
                 'Runtime.evaluate
                 (list :expression
                       (format "_ECT.value = decodeURIComponent('%s')"
                               (url-hexify-string (buffer-string)))))
       (if (stringp .result.value)
           (message "edit-chrome-textarea-finalize: Success")
         (message "edit-chrome-textarea-finalize: Error: result: %s" .result))
       (edit-chrome-textarea-connection-close)
       (kill-buffer)))))

(defun edit-chrome-textarea-send ()
  "Send current buffer to Chrome."
  (interactive)
  (pcase edit-chrome-textarea-current-connection
    ('nil (user-error "No connection associated with current buffer"))
    (conn
     (let-alist (edit-chrome-textarea--request
                 conn
                 'Runtime.evaluate
                 (list :expression
                       (format "_ECT.value = decodeURIComponent('%s')"
                               (url-hexify-string (buffer-string)))))
       (if (stringp .result.value)
           (message "edit-chrome-textarea-send: Success")
         (message "edit-chrome-textarea-finalize: Error: result: %s" .result))))))

(defun edit-chrome-textarea-discard ()
  "Discard current buffer, close connection, kill buffer."
  (interactive)
  (pcase edit-chrome-textarea-current-connection
    ('nil (user-error "No connection associated with current buffer"))
    (_
     (edit-chrome-textarea-connection-close)
     (kill-buffer))))

(define-minor-mode edit-chrome-textarea-mode
  "Minor mode enabled on buffers opened by Edit Chrome Textarea."
  :lighter " Edit Chrome Textarea"
  (when edit-chrome-textarea-mode
    (when edit-chrome-textarea-persistent-message
      (setq header-line-format
            (substitute-command-keys
             "Edit, then commit with `\\[edit-chrome-textarea-finalize]' or abort with \
`\\[edit-chrome-textarea-discard]'")))
    (add-hook 'kill-buffer-hook #'edit-chrome-textarea-connection-close nil t)))

(defun edit-chrome-textarea-new-buffer-name (title url)
  "Return a new buffer name for TITLE and URL."
  (pcase title
    ("" url)
    (_ title)))

(cl-defstruct (edit-chrome-textarea-connection
               (:constructor edit-chrome-textarea-connection-make-1)
               (:copier nil))
  "Represent a websocket connections.
WS is the websocket.
ID is the JSONRPC ID.
CALLBACKS is a hash-table, its key is ID, its value is a
function, which takes a argument, the JSON result."
  ws (id 0) (callbacks (make-hash-table :test #'eq))
  url title)

(defun edit-chrome-textarea--ws-on-message (ws frame)
  "Dispatch connections callbacks according to WS and FRAME."
  (let* ((conn (process-get (websocket-conn ws) 'edit-chrome-textarea-connection))
         (callbacks (edit-chrome-textarea-connection-callbacks conn))
         ;; => ((id . 1) (method . "Runtime.evaluate") (params (expression . "document.activeElement.value")))
         ;; <= ((id . 1) (result (result (type . "string") (value . "hello"))))
         (json (edit-chrome-textarea--json-read-from-string
                (websocket-frame-text frame)))
         (id (alist-get 'id json))
         (result (alist-get 'result json)))
    (pcase (gethash id callbacks)
      ('nil (message "[edit-chrome-textarea] Ignored response, id=%d" id))
      (func
       (remhash id callbacks)
       (funcall func result)))))

(defun edit-chrome-textarea-connection-make (ws-url url title)
  "Connect to websocket at WS-URL, store URL and TITLE, return a connection."
  (let ((ws (websocket-open ws-url :on-message #'edit-chrome-textarea--ws-on-message))
        (conn (edit-chrome-textarea-connection-make-1)))
    (setf (edit-chrome-textarea-connection-ws conn) ws)
    (setf (process-get (websocket-conn ws) 'edit-chrome-textarea-connection) conn)
    (setf (edit-chrome-textarea-connection-url conn) url)
    (setf (edit-chrome-textarea-connection-title conn) title)
    conn))

(defun edit-chrome-textarea--async-request (conn method params callback)
  "Make a JSONRPC request to CONN, expecting a reply, return immediately.
The request is formed by METHOD, a symbol, and PARAMS a
JSON object.
CALLBACK will be called with the response result."
  (unless params
    ;; so `json-encode' can encode nil as empty object
    (setq params #s(hash-table)))
  (pcase-let (((cl-struct edit-chrome-textarea-connection ws id callbacks) conn))
    (cl-incf (edit-chrome-textarea-connection-id conn))
    (puthash id callback callbacks)
    (websocket-send-text ws (json-encode (list :id id :method method :params params)))
    ;; for `edit-chrome-textarea--request'
    id))

(defun edit-chrome-textarea--request (conn method params)
  "Make a request to CONN, wait for a reply.
METHOD is the JSONRPC request method, a symbol.
PARAMS is the JSONRPC request params, a plist."
  (let* ((tag (cl-gensym "edit-chrome-textarea--request-catch-tag"))
         id
         (retval
          (unwind-protect
              (catch tag
                (setq id
                      (edit-chrome-textarea--async-request
                       conn method params
                       (lambda (result)
                         (throw tag `(done ,result)))))
                (while t (accept-process-output nil 30)))
            ;; user-quit (C-g)
            (remhash id (edit-chrome-textarea-connection-callbacks conn)))))
    (pcase-exhaustive retval
      (`(done ,result) result))))

(defun edit-chrome-textarea-connection-close (&optional conn)
  "Close connection CONN."
  (cond
   (conn
    (pcase-let (((cl-struct edit-chrome-textarea-connection ws) conn))
      (websocket-close ws)))
   (edit-chrome-textarea-current-connection
    (pcase-let (((cl-struct edit-chrome-textarea-connection ws)
                 edit-chrome-textarea-current-connection))
      (websocket-close ws))
    (setq edit-chrome-textarea-current-connection nil))))

(defun edit-chrome-textarea ()
  "Edit current focused textarea in Chrome."
  (interactive)
  (let (title url ws-url conn initial)
    ;; Make connection
    ;;
    (let-alist (edit-chrome-textarea--first-page)
      (setq title .title
            url .url
            ws-url .webSocketDebuggerUrl))
    (message "Editing %s - %s" title url)
    ;; (message "Connecting to %s..." ws-url)
    (setq conn (edit-chrome-textarea-connection-make ws-url url title))
    (accept-process-output nil 0.1)
    ;; (message "Connecting to %s...done" ws-url)
    ;; (message nil)

    ;; Fetch initial content
    ;;
    ;; ((result (type . "undefined")))
    ;; ((result (type . "string") (value . "xxxxy123")))
    (let-alist (edit-chrome-textarea--request
                conn
                'Runtime.evaluate
                '(:expression "_ECT = document.activeElement; _ECT.value"))
      (unless (stringp .result.value)
        (edit-chrome-textarea-connection-close conn)
        (user-error "Can't find focused textarea: result: %s" .result))
      (setq initial .result.value))

    ;; Create buffer
    ;; 
    (with-current-buffer (generate-new-buffer
                          (edit-chrome-textarea-new-buffer-name title url))
      (funcall edit-chrome-textarea-guess-mode-function url title initial)
      (edit-chrome-textarea-mode)
      (insert initial)
      (goto-char (point-min))
      (setq edit-chrome-textarea-current-connection conn)
      (select-window (display-buffer (current-buffer))))))

(provide 'edit-chrome-textarea)
;;; edit-chrome-textarea.el ends here
