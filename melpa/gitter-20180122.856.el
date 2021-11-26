;;; gitter.el --- An Emacs Gitter client  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Chunyang Xu

;; Author: Chunyang Xu <mail@xuchunyang.me>
;; URL: https://github.com/xuchunyang/gitter.el
;; Package-Version: 20180122.856
;; Package-Commit: 11cb9b4b45f67bdc24f055a9bfac21d2bd19ea1a
;; Package-Requires: ((emacs "24.4") (let-alist "1.0.4"))
;; Keywords: Gitter, chat, client, Internet
;; Version: 1

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

;; See https://github.com/xuchunyang/gitter.el

;;; Code:

(require 'json)
(require 'subr-x)

(eval-when-compile (require 'let-alist))


;;; Customization

(defgroup gitter nil
  "An Emacs Gitter client."
  :group 'comm)

(defcustom gitter-token nil
  "Your Gitter Personal Access Token.

To get your token:
1) Visit URL `https://developer.gitter.im'
2) Click Sign in (top right)
3) You will see your personal access token at
   URL `https://developer.gitter.im/apps'

DISCLAIMER
When you save this variable, DON'T WRITE IT ANYWHERE PUBLIC."
  :group 'gitter
  :type '(choice (string :tag "Token")
                 (const :tag "Not set" nil)))

(defcustom gitter-curl-program-name "curl"
  "Name/path by which to invoke the curl program."
  :group 'gitter
  :type 'string)


;;; Variable

(defvar gitter--debug nil
  "When non-nil, print debug information.")

(defconst gitter--root-endpoint "https://api.gitter.im"
  "The Gitter API endpoint.

For its documentation, refer to
URL `https://developer.gitter.im/docs/welcome'.")

(defconst gitter--stream-endpoint "https://stream.gitter.im"
  "The Gitter Streaming API endpoint.

For its documentation, refer to
URL `https://developer.gitter.im/docs/streaming-api'.")

(defvar-local gitter--output-marker nil
  "The marker where process output (i.e., message) should be insert.")

(defvar-local gitter--input-marker nil
  "The markder where input (i.e., composing a new message) begins.")

(defvar-local gitter--last-message nil
  "The last message has been inserted.")

(defvar gitter--input-prompt
  (concat (propertize "──────────[ Compose after this line.  Send C-c C-c"
                      'face 'font-lock-comment-face)
          "\n")
  "The prompt that you will compose your message after.")

(defvar gitter--prompt-function #'gitter--default-prompt
  "function called with message JSON object to return a prompt for chatting logs.")

(defvar gitter--user-rooms nil
  "JSON object of requesing user rooms API.")

(defvar gitter--markup-text-functions '(string-trim
                                        gitter--markup-fenced-code)
  "A list of functions to markup text. They will be called in order.

The functions should take a string as argument and return a string.
The functions are called in the Gitter buffer, you can examine some buffer
local variables etc easily, but you should not modify the buffer or change the
current buffer.")


;;; Utility

(defmacro gitter--debug (format-string &rest args)
  "When `gitter--debug', print debug information almost like `message'."
  `(when gitter--debug
     (message ,(concat "[Gitter] " format-string) ,@args)))

(defun gitter--request (method resource &optional params data _noerror)
  "Request URL at RESOURCE with METHOD.
If PARAMS or DATA is provided, it should be alist."
  (with-current-buffer (generate-new-buffer " *curl*")
    (let* ((p (and params (concat "?" (gitter--url-encode-params params))))
           (d (and data (json-encode-list data)))
           (url (concat gitter--root-endpoint resource p))
           (headers
            (append (and d '("Content-Type: application/json"))
                    (list "Accept: application/json"
                          (format "Authorization: Bearer %s" gitter-token))))
           (args (gitter--curl-args url method headers d)))
      (gitter--debug "Calling curl with %S" args)
      (if (zerop (apply #'call-process gitter-curl-program-name nil t nil args))
          (progn (goto-char (point-min))
                 (gitter--read-response))
        (error "curl failed")
        (display-buffer (current-buffer))))))

(defun gitter--url-encode-params (params)
  "URI-encode and concatenate PARAMS.
PARAMS is an alist."
  (mapconcat
   (lambda (pair)
     (pcase-let ((`(,key . ,val) pair))
       (concat (url-hexify-string (symbol-name key)) "="
               (url-hexify-string val))))
   params "&"))

(defun gitter--curl-args (url method &optional headers data)
  "Return curl command line options/arguments as a list."
  (let ((args ()))
    (push "-s" args)
    ;; (push "-i" args)
    (push "-X" args)
    (push method args)
    (dolist (h headers)
      (push "-H" args)
      (push h args))
    (when data
      (push "-d" args)
      (push data args))
    (nreverse (cons url args))))

(defun gitter--read-response ()
  "Customized `json-read' by using native Emacs Lisp types."
  (let ((json-object-type 'alist)
        (json-array-type  'list)
        (json-key-type    'symbol)
        (json-false       nil)
        (json-null        nil))
    (json-read)))

(defun gitter--open-room (name id)
  (with-current-buffer (get-buffer-create (concat "#" name))
    (unless (process-live-p (get-buffer-process (current-buffer)))
      (gitter-minor-mode 1)
      ;; Setup markers
      (unless gitter--output-marker
        (insert gitter--input-prompt)
        (setq gitter--output-marker (point-min-marker))
        (set-marker-insertion-type gitter--output-marker t)
        (setq gitter--input-marker (point-max-marker)))
      (let* ((url (concat gitter--stream-endpoint
                          (format "/v1/rooms/%s/chatMessages" id)))
             (headers
              (list "Accept: application/json"
                    (format "Authorization: Bearer %s" gitter-token)))
             (proc
              ;; NOTE According to (info "(elisp) Asynchronous Processes")
              ;; we should use a pipe by let-binding `process-connection-type'
              ;; to nil, however, it doesn't working very well on my system
              (apply #'start-process
                     (concat "curl-streaming-process-" name)
                     (current-buffer)
                     gitter-curl-program-name
                     (gitter--curl-args url "GET" headers)))
             ;; Paser response (json) incrementally
             ;; Use a scratch buffer to accumulate partial output
             (parse-buf (generate-new-buffer
                         (concat " *Gitter search parse for " (buffer-name)))))
        (process-put proc 'room-id id)
        (process-put proc 'parse-buf parse-buf)
        (set-process-filter proc #'gitter--output-filter)))
    (switch-to-buffer (current-buffer))))

(defun gitter--output-filter (process output)
  (when gitter--debug
    (with-current-buffer (get-buffer-create "*gitter log*")
      (goto-char (point-max))
      (insert output "\n\n")))

  (let ((results-buf (process-buffer process))
        (parse-buf (process-get process 'parse-buf)))
    (when (buffer-live-p results-buf)
      (with-current-buffer parse-buf
        ;; Insert new data
        (goto-char (point-max))
        (insert output)
        (condition-case err
            (progn
              (goto-char (point-min))
              ;; `gitter--read-response' moves point
              (let* ((response (gitter--read-response)))
                (let-alist response
                  (with-current-buffer results-buf
                    (save-excursion
                      (save-restriction
                        (goto-char (marker-position gitter--output-marker))
                        (if (and gitter--last-message
                                 (string= .fromUser.username
                                          (let-alist gitter--last-message
                                            .fromUser.username)))
                            ;; Delete one newline
                            (delete-char -1)
                          (insert (funcall gitter--prompt-function response)))
                        (insert
                         (let ((text .text))
                           (dolist (fn gitter--markup-text-functions)
                             (setq text (funcall fn text)))
                           text)
                         "\n"
                         "\n")
                        (setq gitter--last-message response))))))
              (delete-region (point-min) (point)))
          (error
           ;; FIXME
           (with-current-buffer (get-buffer-create "*Debug Gitter Log")
             (goto-char (point-max))
             (insert (format "The error was: %s" err)
                     "\n"
                     output))))))))

(defun gitter--default-prompt (response)
  "Default function to make prompt by using the JSON object MESSAGE."
  (let-alist response
    (concat (propertize (format "──────────[ %s @%s"
                                .fromUser.displayName
                                .fromUser.username)
                        'face 'font-lock-comment-face)
            "\n")))

;; The result produced by `markdown-mode' was not satisfying
;;
;; (defun gitter--fontify-markdown (text)
;;   (with-temp-buffer
;;     ;; Work-around for `markdown-mode'. It looks like markdown-mode treats ":"
;;     ;; specially (I don't know the reason), this strips the specificity (I don't
;;     ;; know how either)
;;     (insert "\n\n")
;;     (insert text)
;;     (delay-mode-hooks (markdown-mode))
;;     (if (fboundp 'font-lock-ensure)
;;         (font-lock-ensure)
;;       (with-no-warnings
;;         (font-lock-fontify-buffer)))
;;     (buffer-substring 3 (point-max))))

(defun gitter--fontify-code (code mode)
  "Fontify CODE in major-mode MODE."
  (with-temp-buffer
    (insert code)
    (delay-mode-hooks (funcall mode))
    (if (fboundp 'font-lock-ensure)
        (font-lock-ensure)
      (with-no-warnings
        (font-lock-fontify-buffer)))
    (buffer-string)))

(defun gitter--markup-fenced-code (text)
  "Markup Github-flavored fenced code block.

For reference, see URL
`https://help.github.com/articles/creating-and-highlighting-code-blocks/'."
  (with-temp-buffer
    (insert text)
    (goto-char (point-min))
    ;; Assuming there is only one code block
    (let* ((beg-inner (and (re-search-forward "^\\s-*```\\(.*\\)$" nil t)
                           (line-end-position)))
           (lang (and beg-inner
                      (string-trim (match-string 1))))
           (beg-outter (and lang
                            (line-beginning-position)))
           (end-outter (and beg-outter
                            (re-search-forward "^\\s-*```\\s-*$" nil t)
                            (line-end-position)))
           (end-inner (and end-outter
                           (line-beginning-position)))
           (mode (and end-inner
                      (not (string-empty-p lang))
                      (intern (format "%s-mode" lang)))))
      (when (and mode (fboundp mode))
        (let ((code (buffer-substring beg-inner end-inner)))
          (gitter--debug "Markup code in %s mode" mode)
          (delete-region beg-outter end-outter)
          (insert (gitter--fontify-code code mode)))))
    (buffer-string)))


;;; Minor mode

(defvar gitter-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-c" #'gitter-send-message)
    map)
  "Keymap for `gitter-minor-mode'.")

;; FIXME Maybe it is better to use a major mode
(define-minor-mode gitter-minor-mode
  "Minor mode which is enabled automatically in Gitter buffers.
With a prefix argument ARG, enable the mode if ARG is positive,
and disable it otherwise.  If called from Lisp, enable the mode
if ARG is omitted or nil.

Ustually you don't need to call it interactively, it is
interactive because of the cost of using `define-minor-mode'.
Sorry to make your M-x more chaotic (yes, I think M-x is already
chaotic), that's not my intention but I don't want to bother with
learning how to make commandsnon-interactive."
  :init-value nil
  :lighter " Gitter"
  :keymap gitter-minor-mode-map
  :global nil
  :group 'gitter)


;;; Commands

;;;###autoload
(defun gitter ()
  "Open a room."
  (interactive)
  (unless (stringp gitter-token)
    (let* ((plist (car (auth-source-search :max 1 :host "gitter.im")))
           (k (plist-get plist :secret)))
      (if (functionp k)
          (setq gitter-token (funcall k))
        (user-error "`gitter-token' is not set.  \
Please put this line in your ~/.authinfo or ~/.authinfo.gpg
machine gitter.im password here-is-your-token"))))
  (unless gitter--user-rooms
    (setq gitter--user-rooms (gitter--request "GET" "/v1/rooms")))
  ;; FIXME Assuming room name is unique because of `completing-read'
  (let* ((rooms (mapcar (lambda (alist)
                          (let-alist alist
                            (cons .name .id)))
                        gitter--user-rooms))
         (name (completing-read "Open room: " rooms nil t))
         (id (cdr (assoc name rooms))))
    (gitter--open-room name id)))

(defun gitter-send-message ()
  "Send message in the current Gitter buffer."
  (interactive)
  (let ((proc (get-buffer-process (current-buffer))))
    (when (and proc (process-live-p proc))
      (let* ((id (process-get proc 'room-id))
             (resource (format "/v1/rooms/%s/chatMessages" id))
             (msg (string-trim
                   (buffer-substring
                    (marker-position gitter--input-marker)
                    (point-max)))))
        (if (string-empty-p msg)
            (error "Can't send empty message")
          (gitter--request "POST" resource
                           nil `((text . ,msg)))
          (delete-region (marker-position gitter--input-marker)
                         (point-max)))))))

(provide 'gitter)
;;; gitter.el ends here
