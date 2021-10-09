;;; http.el --- Yet another HTTP client              -*- lexical-binding: t; -*-

;; Copyright © 2014 Mario Rodas <marsam@users.noreply.github.com>

;; Author: Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/http.el
;; Package-Version: 20201010.920
;; Package-Commit: 5fdceed1fbf36e274e578e349a53ce922c574774
;; Keywords: convenience
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4") (request "0.2.0") (edit-indirect "0.1.4"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
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
;;
;; `http.el' provides an easy way to interact with the HTTP protocol.

;; Usage:
;;
;; Create a file with the following contents, and set `http-mode' as major mode.
;;
;;     # -*- http -*-
;;
;;     POST https://httpbin.org/post?val=key
;;     User-Agent: Emacs24
;;     Content-Type: application/json
;;
;;     {
;;       "foo": "bar"
;;     }
;;
;; Move the cursor somewhere within the description of the http request and
;; execute `M-x http-process` or press <kbd>C-c C-c</kbd>, if everything is went
;; well should show an buffer when the response of the http request:
;;
;; ![http.el screenshot](misc/screenshot.png)
;;
;; More examples are included in file [misc/example.txt](misc/example.http)

;; Customization:
;;
;; Fontify response:
;;
;; If you want to use a custom mode for the fontification of the response buffer
;; with content-type equal to `http-content-type-mode-alist'.  For example, to
;; use [json-mode][] for responses with content-type "application/json":
;;
;;     (add-to-list 'http-content-type-mode-alist
;;                  '("application/json" . json-mode))
;;
;; Prettify response:
;;
;; If you want to use a custom function to prettify the response body you need
;; to add it to `http-pretty-callback-alist', the function is called without
;; arguments.  Examples:
;;
;; + To use [json-reformat][] in responses with content-type "application/json":
;;
;;     (require 'json-reformat)
;;
;;     (defun my/pretty-json-buffer ()
;;       (json-reformat-region (point-min) (point-max)))
;;
;;     (add-to-list 'http-pretty-callback-alist
;;                  '("application/json" . my/pretty-json-buffer))
;;
;; + To display the rendered html in responses with content-type "text/html":
;;
;;     (require 'shr)
;;
;;     (defun my/http-display-html ()
;;       (shr-render-region (point-min) (point-max)))
;;
;;     (add-to-list 'http-pretty-callback-alist
;;                  '("text/html" . my/http-display-html))

;; Related projects:
;;
;; + [httprepl.el][]: An HTTP REPL for Emacs.
;;
;; + [restclient.el][]: HTTP REST client tool for Emacs.  You can use both
;;   projects indistinctly, the main differences between both are:
;;
;;   |            | `restclient.el'   | `http.el'     |
;;   | ---------- | ----------------- | ------------- |
;;   | backend    | `url.el'          | `request.el'  |
;;   | variables  | yes               | no            |
;;
;; [httprepl.el]: https://github.com/gregsexton/httprepl.el "An HTTP REPL for Emacs"
;; [restclient.el]: https://github.com/pashky/restclient.el "HTTP REST client tool for Emacs"
;; [json-mode]: https://github.com/joshwnj/json-mode "Major mode for editing JSON files with Emacs"
;; [json-reformat]: https://github.com/gongo/json-reformat "Reformat tool for JSON"

;;; Code:

(eval-when-compile
  (require 'cl-lib)
  (require 'subr-x)
  (require 'outline))

(require 'request)
(require 'rfc2231)
(require 'url-util)
(require 'edit-indirect)

(defgroup http nil
  "Yet another HTTP client."
  :prefix "http-"
  :group 'applications)

(defcustom http-buffer-response-name "*HTTP Response*"
  "Name for response buffer."
  :type 'string
  :group 'http)

(defcustom http-timeout nil
  "Default request timeout in second."
  :type '(choice (integer :tag "Http timeout seconds")
                 (boolean :tag "No timeout" nil))
  :group 'http)

(defcustom http-show-response-headers t
  "Show response headers."
  :type 'boolean
  :group 'http)

(defcustom http-show-response-headers-top nil
  "If non nil inserts response headers at the top."
  :type 'boolean
  :group 'http)

(defcustom http-prettify-response t
  "If non nil inserts response headers at the top."
  :type 'boolean
  :safe 'booleanp
  :group 'http)

(defcustom http-default-directory nil
  "Default directory for HTTP requests."
  :type '(choice (const nil) string)
  :safe #'stringp
  :group 'http)

(defcustom http-fallback-comment-start "//"
  "Fallback string used as `comment-start'.

Used only when was not possible to guess a response content-type."
  :type 'string
  :group 'http)

;;;###autoload
(defvar-local http-hostname nil
  "Default hostname used when url is an endpoint.")
;;;###autoload
(put 'http-hostname 'safe-local-variable #'stringp)

(defvar http-methods-list
  '("GET" "POST" "DELETE" "PUT" "HEAD" "OPTIONS" "PATCH")
  "List of http methods.")

(defconst http-mode-outline-regexp
  (regexp-opt http-methods-list))

(defconst http-mode-outline-regexp-alist
  (mapcar (lambda (method) (cons method 1)) http-methods-list))

(defconst http-request-line-regexp
  (rx-to-string `(: line-start (* space)
                    (group (or ,@http-methods-list))
                    (+ space)
                    (group (+ not-newline))
                    line-end)
                t))

(defconst http-mode-imenu-generic-expression
  (mapcar (lambda (method)
            (list method
                  (rx-to-string `(: line-start ,method (+ space) (group (+ not-newline))) t)
                  1))
          http-methods-list))

(defconst http-header-regexp
  (rx line-start (* space) (group (+ (in "_-" alnum))) ":" (* space) (group (+ not-newline)) line-end))

(defconst http-header-body-sep-regexp
  (rx line-start (* blank) line-end))

(defvar http-content-type-mode-alist
  '(("text/css"                 . css-mode)
    ("text/xml"                 . xml-mode)
    ("application/xml"          . xml-mode)
    ("application/atom+xml"     . xml-mode)
    ("application/atomcat+xml"  . xml-mode)
    ("application/x-javascript" . js-mode)
    ("application/json"         . js-mode)
    ("text/javascript"          . js-mode)
    ("text/html"                . html-mode)
    ("text/plain"               . text-mode)
    ("image/gif"                . image-mode)
    ("image/png"                . image-mode)
    ("image/jpeg"               . image-mode)
    ("image/x-icon"             . image-mode)
    ("image/svg+xml"            . image-mode))
  "Mapping between 'content-type' and a Emacs mode.

Used to fontify the response buffer and comment the response headers.")

(declare-function json-pretty-print-buffer "json")

;; XXX: Emacs<25 incorrectly escapes the slash character https://github.com/emacs-mirror/emacs/commit/58c8605
(defvar http-pretty-callback-alist
  '(("application/json" . json-pretty-print-buffer))
  "Mapping between 'content-type' and a pretty callback.")

(defun http-query-alist (query)
  "Return an alist of QUERY string."
  (cl-loop for (key val) in (url-parse-query-string query)
           collect (cons key val)))

(defun http-parse-headers (start end)
  "Return the parsed http headers from START to END point."
  (let* ((hdrlines (split-string (buffer-substring-no-properties start end) "\n"))
         (header-alist (mapcar (lambda (hdrline)
                                 (and (string-match http-header-regexp hdrline)
                                      (cons (downcase (match-string 1 hdrline))
                                            (match-string 2 hdrline))))
                               hdrlines)))
    (remove nil header-alist)))

(defun http-capture-headers-and-body (start end)
  "Return a list of the form `(header body)` with the captured valued from START to END point."
  (let* ((sep-point (save-excursion (goto-char start) (re-search-forward http-header-body-sep-regexp end t)))
         (headers (http-parse-headers start (or sep-point end)))
         (rest (and sep-point (buffer-substring-no-properties sep-point end)))
         (body (and rest (not (string-blank-p rest)) (string-trim rest))))
    (list headers body)))

(defun http-start-definition ()
  "Locate the start of the HTTP request definition."
  (or (save-excursion (end-of-line) (re-search-backward http-request-line-regexp nil t))
      (user-error "HTTP request definition not found")))

(defun http-end-definition (&optional start)
  "Locate the end of the HTTP request definition from START point."
  (save-excursion
    (and start (goto-char start))
    (end-of-line)
    (or (and (re-search-forward (concat "^#\\|" http-request-line-regexp) nil t) (1- (point-at-bol)))
        (point-max))))

(cl-defun http-callback (&key data response error-thrown &allow-other-keys)
  (with-current-buffer (get-buffer-create http-buffer-response-name)
    (let ((inhibit-read-only t))
      (erase-buffer)
      (and error-thrown (message (error-message-string error-thrown)))
      (let* ((ctype-header (request-response-header response "content-type"))
             (ctype-list (and ctype-header (rfc2231-parse-string ctype-header)))
             (charset (cdr (assq 'charset (cdr ctype-list))))
             (coding-system (and charset (intern (downcase charset))))
             (ctype-name (car ctype-list))
             (guessed-mode (assoc-default ctype-name http-content-type-mode-alist))
             (pretty-callback (assoc-default ctype-name http-pretty-callback-alist)))
        (if (eq guessed-mode 'image-mode)
            (let ((data (encode-coding-string data 'utf-8))
                  (type (if (or (and (fboundp 'image-transforms-p)
                                     (image-transforms-p))
                                (not (fboundp 'imagemagick-types)))
                            nil
                          'imagemagick)))
              (insert-image (create-image data type t)))
          (when (stringp data)
            (setq data (decode-coding-string data (or coding-system 'utf-8)))
            (let ((text (or (and http-prettify-response
                                 (fboundp pretty-callback)
                                 (with-demoted-errors "Error while prettifying: %S"
                                   (http-prettify-text data pretty-callback)))
                            data)))
              (insert (if (fboundp guessed-mode)
                          (http-fontify-text text guessed-mode)
                        text))))))
      (when http-show-response-headers
        (goto-char (if http-show-response-headers-top (point-min) (point-max)))
        (or http-show-response-headers-top (insert "\n"))
        (let ((hstart (point))
              (raw-header (request-response--raw-header response)))
          (unless (string-empty-p raw-header)
            (insert raw-header)
            (let ((comment-start (or comment-start http-fallback-comment-start)))
              (comment-region hstart (point)))
            (put-text-property hstart (point) 'face 'font-lock-comment-face))))
      (http-response-mode))
    (goto-char (point-min))
    (display-buffer (current-buffer))))

(defun http-urlencode-alist (params)
  "Generate an url query from PARAMS alist."
  (url-build-query-string (cl-loop for (k . v) in params collect (list k v))))

(defun http-prettify-text (text object)
  "Prettify using TEXT using calling OBJECT in a temporal buffer."
  (with-temp-buffer
    (insert text)
    (funcall object)
    (buffer-string)))

(defun http-mode-from-headers (headers)
  "Return a major mode from HEADERS based on its content-type."
  (cl-multiple-value-bind (ctype _attrs)
      (rfc2231-parse-string (or (assoc-default "content-type" headers) ""))
    (or (assoc-default ctype http-content-type-mode-alist) #'normal-mode)))

(defun http-in-context (&optional pos)
  "Return the context of the point POS."
  (save-excursion
    (and pos (goto-char pos))
    (forward-line 0)
    (cond
     ((looking-at-p http-header-regexp)        'header)
     ((looking-at-p http-request-line-regexp)  'request)
     ((looking-at-p "^[ \t]*#")                'comment)
     (t                                        'body))))

(defun http-indent-line ()
  "Indent current line as http mode."
  (interactive)
  (cl-case (http-in-context)
    ((header request comment) (indent-line-to 0))))

;; Stolen from `ansible-doc'.
(defun http-fontify-text (text mode)
  "Add `font-lock-face' properties to TEXT using MODE.

Return a fontified copy of TEXT."
  ;; Graciously inspired by http://emacs.stackexchange.com/a/5408/227
  (with-temp-buffer
    (insert text)
    (delay-mode-hooks                   ; Run mode without any hooks
      (funcall mode)
      (font-lock-mode))
    (if (fboundp 'font-lock-ensure)
        (font-lock-ensure)
      (with-no-warnings
        ;; Suppress warning about non-interactive use of
        ;; `font-lock-fontify-buffer' in Emacs 25.
        (font-lock-fontify-buffer)))
    ;; Convert `face' to `font-lock-face' to play nicely with font lock
    (goto-char (point-min))
    (while (not (eobp))
      (let ((pos (point)))
        (goto-char (next-single-property-change pos 'face nil (point-max)))
        (put-text-property pos (point) 'font-lock-face
                           (get-text-property pos 'face))))
    (buffer-string)))

(defun http-nav-beginning-of-defun ()
  "Move point to the beginning of a HTTP request definition."
  (end-of-line)
  (goto-char (http-start-definition)))

(defun http-nav-end-of-defun ()
  "Move point to the end of a HTTP request definition."
  (goto-char (http-end-definition)))

(defun http-capture ()
  "Capture a http request.

Return a list of the form: \(URL TYPE PARAMS DATA HEADERS\)"
  (let* ((start (http-start-definition))
         (type (match-string-no-properties 1))
         (endpoint (match-string-no-properties 2))
         (url (if (and http-hostname (not (string-match-p url-nonrelative-link endpoint)))
                  ;; FIXME: endpoint needs to be escaped here, else
                  ;;        `url-expand-file-name' strips whitespaces
                  (url-expand-file-name endpoint http-hostname)
                endpoint))
         (urlobj (url-generic-parse-url url))
         (end (http-end-definition start)))
    (cl-destructuring-bind (path . query)
        (url-path-and-query urlobj)
      (let ((params (and query (http-query-alist query))))
        ;; XXX: remove the query string to make it compatible with `request'
        (setf (url-filename urlobj) path)
        (cl-multiple-value-bind (headers data) (http-capture-headers-and-body start end)
          (list (url-recreate-url urlobj) type params data headers))))))

;;;###autoload
(defun http-edit-body-indirect ()
  "Edit body in a indirect buffer."
  (interactive)
  (let* ((start (http-start-definition))
         (end (http-end-definition start))
         (sep-point (save-excursion (goto-char start) (re-search-forward http-header-body-sep-regexp end t)))
         (headers (http-parse-headers start (or sep-point end)))
         (edit-indirect-guess-mode-function (lambda (_parent-buffer _beg _end)
                                              (funcall (http-mode-from-headers headers)))))
    (edit-indirect-region (if (and sep-point (< sep-point end)) (1+ sep-point) end) end 'display-buffer)))

;;;###autoload
(defun http-curl-command ()
  "Kill current http request as curl command."
  (interactive)
  (cl-multiple-value-bind (url type params data headers)
      (http-capture)
    (and params
         (setq url (concat url (if (string-match-p "\\?" url) "&" "?") (http-urlencode-alist params))))
    (let* ((args (append
                  (list "curl" "-X" type)
                  (and headers (cl-loop for (k . v) in headers
                                        collect "--header"
                                        collect (format "%s: %s" k v)))
                  (and data (list "--data-binary" data))
                  (list url)))
           (command (combine-and-quote-strings args)))
      (kill-new (message "%s" command)))))

;;;###autoload
(defun http-process (&optional sync)
  "Process a http request.

If SYNC is non-nil executes the request synchronously."
  (interactive "P")
  (cl-multiple-value-bind (url type params data headers)
      (http-capture)
    (let ((default-directory (or http-default-directory default-directory)))
      (request url
               :type type
               :params params
               :data data
               :headers headers
               :sync sync
               :parser 'buffer-string
               :timeout http-timeout
               :success 'http-callback
               :error 'http-callback))))

(defvar http-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    table)
  "Syntax table for http mode files.")

(defvar http-font-lock-keywords
  `((,http-request-line-regexp
     (1 font-lock-keyword-face)
     (2 font-lock-function-name-face t))
    (,http-header-regexp
     (1 font-lock-variable-name-face)
     (2 font-lock-string-face t))))

(defvar http-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c '") 'http-edit-body-indirect)
    (define-key map (kbd "C-c C-c") 'http-process)
    (define-key map (kbd "C-c C-u") 'http-curl-command)
    (define-key map (kbd "C-c C-n") 'outline-next-heading)
    (define-key map (kbd "C-c C-p") 'outline-previous-heading)
    (define-key map (kbd "C-c C-t") 'outline-toggle-children)
    map))

;;;###autoload
(define-derived-mode http-mode text-mode "HTTP Client"
  "Major mode for HTTP client.

\\{http-mode-map}"
  (setq-local comment-start "# ")
  (setq-local comment-start-skip "#+\\s-*")
  (setq-local beginning-of-defun-function #'http-nav-beginning-of-defun)
  (setq-local end-of-defun-function #'http-nav-end-of-defun)
  (setq-local indent-line-function 'http-indent-line)
  (setq font-lock-defaults '(http-font-lock-keywords))
  (setq outline-regexp http-mode-outline-regexp)
  (setq outline-heading-alist http-mode-outline-regexp-alist)
  (setq imenu-generic-expression http-mode-imenu-generic-expression)
  (add-to-invisibility-spec '(outline . t))
  (imenu-add-to-menubar "Contents"))

;;;###autoload
(define-derived-mode http-response-mode special-mode "HTTP Response"
  "Major mode for HTTP responses from `http-mode'

\\{http-response-mode-map}"
  (setq buffer-read-only t
        buffer-auto-save-file-name nil))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.http\\'" . http-mode))

(provide 'http)

;;; http.el ends here
