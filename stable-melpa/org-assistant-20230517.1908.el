;;; org-assistant.el --- Org babel extension for Chat Assistant APIs -*- lexical-binding: t -*-

;; Author: Tyler Dodge (tyler@tdodge.consulting)
;; Version: 1.5
;; Package-Version: 20230517.1908
;; Package-Commit: 966bb44889f40fa80005f919cffc5f5cb43b731a
;; Keywords: convenience
;; Package-Requires: ((emacs "28.1") (uuidgen "1.2") (deferred "0.5.1") (s "1.12.0") (dash "2.19.1") (ht "0.9"))
;; URL: https://github.com/tyler-dodge/org-assistant
;; Git-Repository: git://github.com/tyler-dodge/org-assistant.git
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

;;;
;;;
;;; Commentary:
;; org-assistant provides support for accessing chat APIs such as
;; ChatGPT in the context of an org notebook.
;;
;; <img src="screenshots/example.gif" alt="example" width="400" />
;;
;; ## Installation
;;
;; Org-assistant is available on [MELPA](http://stable.melpa.org/#/org-assistant)
;;
;; <kbd>M-x</kbd> `package-install` <kbd>[RET]</kbd> `org-assistant` <kbd>[RET]</kbd>
;;
;; ## Usage
;;
;; It provides a function named org-assistant that serves as
;; entrypoint for displaying an org assistant buffer.  Also, it can be
;; used in any org file by using a src block like #+BEGIN_SRC
;; assistant or #+BEGIN_SRC ?.
;;
;; The API Key is looked up via org-assistant-auth-function, which has
;; meen tested using the MacOS Keychain.  Alternatively,
;; org-assistant-auth-function can be a string and directly set to
;; your API key.
;; <example>
;; (setq org-assistant-auth-function "<YOUR_API_KEY>")
;; </example>
;; Calling `org-assistant' interactively will generate an org-assistant buffer for you.
;; It can be set to a keybinding for quick use like below:
;; <example>
;; (global-set-key (kbd "C-x C-o") #'org-assistant)
;; </example>
;;
;; ### Conversation Evaluation Rules
;; - The org tree is traversed up in order to generate the message
;; list when sending information to the chat endpoint.
;; - It will only use messages from the branch of the tree that the block that
;; initiated the request is in.
;; - It does not include example blocks or source blocks that appear later in
;; the org buffer than the initiating block.
;; - noweb support is enabled for all blocks in the conversation based on the
;; initiating block having the :noweb flag set.
;; - Example blocks are treated as being responses from the assistant by default
;; if they occur after user messages.
;; - If the example block is before any user source block, they are
;; treated as system messages to the assistant instead.
;;
;; See [org-babel-execute:assistant](https://github.com/tyler-dodge/org-assistant#org-babel-executeassistant)
;; for more details.
;;
;; ### Example
;; <example>
;; * Chat User Question
;; #+BEGIN_SRC ?
;; Hi
;; #+END_SRC
;;
;; AI Response
;; #+BEGIN_SRC assistant :sender assistant
;; Hello! How can I assist you today?
;; #+END_SRC
;; </example>
;;
;; When the output is set to png file, the image generation APIs are
;; called instead.
;; <example>
;; * Image Generation User Question
;; #+BEGIN_SRC ? :file sphere.png
;; Generate a sphere
;; #+END_SRC
;;
;; AI Response
;; #+RESULTS:
;; file:sphere.png
;; </example>
;;
;; You can introspect the sent conversation using the :echo flag.
;; <example>
;; * Branching Echo
;; #+BEGIN_SRC ?
;; This is the user.  Repeat verbatim only: "This is the system"
;; #+END_SRC
;;
;; #+RESULTS:
;; #+BEGIN_SRC assistant :sender assistant
;; "This is the system"
;; #+END_SRC
;;
;; ** Branch A
;; #+BEGIN_SRC ? :echo
;; Response A
;; #+END_SRC
;;
;; #+RESULTS:
;; #+BEGIN_SRC assistant :sender assistant
;; (user . "This is the user.  Repeat verbatim only: \"This is the system\"")
;; (assistant . "\"This is the system\"")
;; (user . "Response A")
;; #+END_SRC
;;
;; ** Branch B
;; #+BEGIN_SRC ? :echo
;; Response B
;; #+END_SRC
;;
;; #+RESULTS:
;; #+BEGIN_SRC assistant :sender assistant
;; (user . "This is the user.  Repeat verbatim only: \"This is the system\"")
;; (assistant . "\"This is the system\"")
;; (user . "Response B")
;; #+END_SRC
;; </example>
;;
;; ## Comparison With Other AI Packages
;; ### [org-assistant.el](https://github.com/tyler-dodge/org-assistant) and [org-ai.el](https://github.com/rksm/org-ai)
;; - [org-ai.el](https://github.com/rksm/org-ai) is focused more on runtime interaction with AI
;; - [org-assistant.el](https://github.com/tyler-dodge/org-assistant) is focused more on reproducible sessions
;;     via org babel
;; - [org-assistant.el](https://github.com/tyler-dodge/org-assistant) supports branching conversations
;; - [org-assistant.el](https://github.com/tyler-dodge/org-assistant) is not meant to be used downstream
;;      as a library for AI endpoint interactions.
;; - In [org-assistant.el](https://github.com/tyler-dodge/org-assistant), all interaction is async using org-babel, which allows
;;     for notebook style prompt development
;; - In [org-ai.el](https://github.com/rksm/org-ai), interaction is synchronous and inline,
;;     which is better for in-editor use cases
;; - [org-ai.el](https://github.com/rksm/org-ai) supports a lot of other AI use cases like text to speech
;;
;; ### [org-assistant.el](https://github.com/tyler-dodge/org-assistant) and [gptel](https://github.com/karthink/gptel)
;; - Most of the same differences and similarities apply from
;;     [org-assistant.el](https://github.com/tyler-dodge/org-assistant) and [org-ai.el](https://github.com/rksm/org-ai)
;;
;; ### Feel free to add a pull request detailing the differences if there is a package I missed
;;

;;; Code:

(require 'org)
(require 'org-element)
(require 'deferred)
(require 's)
(require 'uuidgen)
(require 'dash)
(require 'url)
(require 'ob-core)
(require 'url-vars)
(require 'auth-source)
(require 'simple)
(require 'evil nil t)
(require 'ht)

(defgroup org-assistant nil "Customization settings for `org-assistant'."
  :group 'org)

(defcustom org-assistant-auth-function #'org-assistant-auth-source-search
  "Function used to get the secret key.
Optionally can be set directly to a string, in which case it will be
used as the OpenAI key."
  :group 'org-assistant
  :type '(string function))

(defcustom org-assistant-mode-visual-line-enabled t
  "When non-nil, `visual-line-mode' is enabled with `org-assistant-mode'."
  :group 'org-assistant
  :type '(boolean))

(defcustom org-assistant-buffer-name "*org-assistant*"
  "The buffer name used for the `org-assistant' buffer."
  :group 'org-assistant
  :type '(string))

(defcustom org-assistant-mode-line-format
  `("***"
    mode-line-buffer-identification "   " mode-line-position
    ,(when (boundp 'evil-mode-line-tag) 'evil-mode-line-tag)
    "  " mode-line-modes mode-line-misc-info
    (:eval (concat "[" (s-join "," (--map (substring it 0 4) org-assistant--inflight-request)) "]") )
    mode-line-end-spaces)
  "The `mode-line-format' used by the `org-assistant' buffer.
Set to nil to use `mode-line-format' instead."
  :group 'org-assistant
  :type '(list))

(defcustom org-assistant-model "gpt-3.5-turbo"
  "The model used for the assistant."
  :group 'org-assistant
  :type '(string))

(defcustom org-assistant-curl-command "curl"
  "The path to the curl command used to run requests."
  :group 'org-assistant
  :type '(string))

(defcustom org-assistant-endpoint "https://api.openai.com"
  "The endpoint used for the assistant.
`org-assistant-endpoint-path-chat' and `org-assistant-endpoint-path-image'
contain the paths for the respective APIs."
  :group 'org-assistant
  :type '(string))

(defcustom org-assistant-endpoint-path-chat "/v1/chat/completions"
  "The path used for the chat API.
See `org-assistant-endpoint' for the domain."
  :group 'org-assistant
  :type '(string))

(defcustom org-assistant-endpoint-path-models "/v1/models"
  "The path used for the list models API.
See `org-assistant-endpoint' for the domain."
  :group 'org-assistant
  :type '(string))

(defcustom org-assistant-endpoint-path-image "/v1/images/generations"
  "The endpoint used for the assistant."
  :group 'org-assistant
  :type '(string))

(defcustom org-assistant-response-completed-hook nil
  "The hook called whenever a `org-assistant' request finishes executing.
Called with the arguments: Stream-Id and Message
Where:
Stream-Id is the stream-id of the request
Message is the full contents of the response from the endpoint.
The buffer and point are set to the the end of the response."
  :group 'org-assistant
  :type 'hook)

(defcustom org-assistant-parallelism 1
  "The max inflight requests to send with `org-assistant' at once."
  :group 'org-assistant
  :type '(number))

(defcustom org-assistant-chat-extra-parameters-alist
  nil
  "Extra parameters to be sent with a chat request.

Known keys are:
temperature
top_p
n
stream
stop
max-tokens
presence-penalty
frequency-penalty
logit-bias
user
Should be a alist like '((max_tokens . 10) (user . \"emacs\")).

This can be overriden on a per-src block basis by specifying the
:params argument.

See https://platform.openai.com/docs/api-reference/chat/create
for reference.

<example>
#+BEGIN_SRC assistant :params '((max_tokens . 10) (user . \"emacs\"))
Hi
#+END_SRC
</example>"
  :group 'org-assistant
  :type '(alist))

(defcustom org-assistant-image-extra-parameters-alist
  nil
  "Extra parameters to be sent with an image request.

Known allowed keys are:
size
user
Should be a alist like '((size . \"1024x1024\") (user . \"emacs\")).

This can be overriden on a per-src block basis by specifying the
:params argument.

See https://platform.openai.com/docs/api-reference/chat/create
for reference.

<example>
#+BEGIN_SRC assistant :params '((max_tokens . 10) (user . \"emacs\"))
Hi
#+END_SRC
</example>"
  :group 'org-assistant
  :type '(alist))

(defcustom org-assistant-execute-curl-process-function
  #'org-assistant--execute-curl-shell-command-request
  "Function used to execute the shell command for `org-assistant'.
See `org-assistant--execute-curl-shell-command-request' for expected arguments."
  :group 'org-assistant
  :type '(function))

(defvar org-babel-default-header-args:assistant
  (list (cons :results "raw") (cons :exports "both") (cons :eval "no-export"))
  "Extra args so that org babel renders the results correctly.
This should match `org-babel-default-header-args:?'")

(defvar org-babel-default-header-args:?
  org-babel-default-header-args:assistant
  "Extra args so that org babel renders the results correctly.
This should match `org-babel-default-header-args:assistant'")

(defvar org-assistant--streaming-overlays (make-hash-table :test #'equal)
  "Hash table that contains the mapping of request ids to overlays.")

(defvar-local org-assistant--process-json-read-pt nil
  "Marker that represents the end of the last read output.
For org-assisant process buffers.")

(defvar-local org-assistant--buffer-requests nil
  "Buffer local list that keeps track of `org-assistant' requests.")

(defvar org-assistant-history nil
  "History variable for `org-assistant'.")

(defun org-assistant-with-initial-message (message)
  "Create and display a buffer named `org-assistant-buffer-name'.

The buffer contains the response from the assistant given the prompt
contained in MESSAGE."
  (let ((buffer (get-buffer-create "*org-assistant*")))
    (with-current-buffer buffer
      (org-mode)
      (org-assistant-mode 1)
      (display-line-numbers-mode -1)
      (goto-char (point-max))
      (insert "\n* Question\n#+BEGIN_SRC ?\n")
      (insert message)
      (let ((pt (point)))
        (save-excursion
          (insert "\n#+END_SRC\n"))
        (run-at-time nil nil
                     (lambda ()
                       (with-current-buffer buffer
                         (goto-char (point-max))
                         (forward-line -1)
                         (cl-loop for window in (get-buffer-window-list buffer)
                                  do (set-window-point window pt))
                         (org-ctrl-c-ctrl-c))))
        (set-window-point
         (select-window (display-buffer buffer))
         pt)))))

(defvar org-assistant-mode-map (make-sparse-keymap)
  "Keymap for `org-assistant-mode' buffers.")

(defconst org-assistant--begin-src-regexp
  (rx line-start "#+BEGIN_SRC"
      (+ whitespace)
      (or "assistant" "?"))
  "Regexp for finding #+BEGIN_SRC ? blocks.")

(defconst org-assistant--end-src-regexp
  (rx line-start "#+END_SRC")
  "Regexp for finding #+END_SRC blocks.")

(defconst org-assistant--begin-example-regexp
  (rx "#+BEGIN_EXAMPLE")
  "Regexp for finding #+BEGIN_EXAMPLE blocks.")

(define-minor-mode org-assistant-mode "Mode for org assistant buffers."
  :init-value nil
  :keymap org-assistant-mode-map
  (add-hook 'kill-buffer-hook #'org-assistant-kill-buffer-requests nil t)
  (when org-assistant-mode-visual-line-enabled
    (visual-line-mode org-assistant-mode))
  (when org-assistant-mode-line-format
    (setq-local mode-line-format org-assistant-mode-line-format)))

(defvar org-assistant--request-queue nil
  "Request queue used by `org-assistant' to limit parallelism of requests.")

(defvar org-assistant--inflight-request nil
  "Tracks inflight requests for `org-assistant'.")

(defvar org-assistant--request-queue-active-p nil
  "Tracks when the request queue is active.

This is used to avoid automatically adjusting the
prompt when multiple are inflight.")

;;;###autoload
(defun org-assistant-setup ()
  "Set up optional libraries like `markdown-mode' to work with `org-assistant'.

If `markdown-mode' is available, it will be used."
  (when (require 'markdown-mode nil t)
    (add-to-list 'org-src-lang-modes '("?" . markdown))
    (add-to-list 'org-src-lang-modes '("assistant" . markdown))))

;;;###autoload
(defun org-assistant ()
  "Prompt the user for an initial prompt for the assistant.

Then display a window with the buffer containing the response."
  (interactive)
  (let ((message (read-from-minibuffer "Chat:" nil nil nil org-assistant-history)))
    (org-assistant-with-initial-message message)))

(defun org-assistant-auth-source-search ()
  "Example auth source function for use with `org-assistant-auth-function'.

This has been tested with the `macos-keychain-generic' auth-source
where openai-key is an application password with the name openai-key."
  (-some-->
      (auth-source-search
       :user "openai-key")
    (car it)
    (plist-get it :secret)
    (aref it 2)
    (aref it 0)))

(defun org-assistant--deferred-decode-response (deferred)
  "After DEFERRED completes, decode the http response in BUFFER."
  (deferred:$
   deferred
   (deferred:nextc
    it
    (lambda (text)
      (or
       (condition-case _
           (--doto (org-assistant--json-decode text)
             (-let [(&alist 'error (&alist 'message error-message 'type error-type)) it]
               (when error-type
                 (error "%s: %s" error-type error-message))))
         (json-readtable-error (error "Unexpected output from server.
%s" text)))
         (error "Response was unexpectedly nil %S" (buffer-string)))))))

(defvar org-assistant--request-id nil
  "Request ID for `org-assistant'.
Set specially by the macro `org-assistant-org-babel-async-response'.")

(defvar org-assistant--request-processes-ht (make-hash-table :test #'equal)
  "Hash table mapping request id to active process.")

;;;###autoload
(defmacro org-assistant-org-babel-async-response (streaming &rest prog)
  "Macro for handling asynchronous responses with `org-mode'.

Provides a function called `babel-response' that can be called in PROG to
substitute the response value in the org buffer that initiated this call.

Returns a UUID placeholder that `org-mode' emits into the buffer, which is
later substituted by `org-assistant'."
  (declare
   (debug t)
   (indent 0))
  (let ((buffer-var (make-symbol "buffer"))
        (start-pt-var (make-symbol "start-pt"))
        (in-src-block-var (make-symbol "in-src-block"))
        (pt-temp-var (make-symbol "temp-pt"))
        (insert-prompt-var (make-symbol "insert-prompt"))
        (error-var (make-symbol "error"))
        (has-output-var (make-symbol "has-output"))
        (replacement-var (make-symbol "replacement")))
    `(let* ((,buffer-var (current-buffer))
            (,replacement-var (org-assistant--generate-replacement-string))
            (,start-pt-var (point))
            (,has-output-var (cons nil nil))
            (org-assistant--request-id ,replacement-var))
       (cl-flet ((babel-output-empty-p () (not (car ,has-output-var)))
                 (babel-response (message &optional response-type streaming)
                   (setcar ,has-output-var t)
                   (run-at-time
                    nil nil
                    (lambda ()
                      (let ((inhibit-message t)
                            (,replacement-var ,replacement-var))
                        (unless streaming
                          (setq org-assistant--buffer-requests
                                (--filter (not (string= it ,replacement-var)) org-assistant--buffer-requests))
                          (setq org-assistant--inflight-request
                                (--filter (not (string= it ,replacement-var)) org-assistant--inflight-request)))
                        (when (buffer-live-p ,buffer-var)
                          (with-current-buffer ,buffer-var
                            (let ((,pt-temp-var (point)))
                              (-some-->
                                  (save-mark-and-excursion
                                    (goto-char (point-min))
                                    (if-let ((overlay (gethash ,replacement-var org-assistant--streaming-overlays)))
                                        (progn
                                          (overlay-put overlay 'before-string (concat (overlay-get overlay 'before-string)
                                                                                     message))
                                          (unless (or
                                                   (not streaming)
                                                   (save-match-data
                                                        (save-excursion
                                                          (goto-char (overlay-start overlay))
                                                          (org-assistant--in-src-block-p))))
                                            (org-assistant--kill-request (overlay-get overlay 'stream-id)))
                                          (when (not streaming)
                                            (let ((text (overlay-get overlay 'before-string))
                                                  (pt (overlay-start overlay)))
                                              (remhash ,replacement-var org-assistant--streaming-overlays)
                                              (delete-overlay overlay)
                                              (when pt
                                                (save-match-data
                                                  (save-excursion
                                                    (goto-char pt)
                                                    (let ((end-block
                                                           (save-excursion
                                                             (when
                                                                 (re-search-forward org-assistant--end-src-regexp nil t))
                                                             (forward-line -1)
                                                             (end-of-line)
                                                             (point))))
                                                      (when (and end-block
                                                                 (save-match-data
                                                                   (save-excursion
                                                                     (org-assistant--in-src-block-p))))
                                                        (insert (org-escape-code-in-string text))
                                                        (run-hook-with-args
                                                         'org-assistant-response-completed-hook
                                                         ,replacement-var
                                                         (buffer-substring-no-properties
                                                          (save-excursion
                                                            (re-search-backward org-assistant--begin-src-regexp)
                                                            (forward-line 1)
                                                            (point))
                                                          end-block)))))))))
                                          nil)
                                      (when (re-search-forward (rx (literal ,replacement-var)) nil t)
                                        (pcase response-type
                                          ('file-list
                                           (replace-match
                                            (string-join (--map (format "%s" it) message) "\n")
                                            nil t)
                                           (goto-char (match-end 0))
                                           (forward-line 0)
                                           (cl-loop with first = t
                                                    while (looking-at (rx (literal (car message)) line-end))
                                                    do
                                                    (if first
                                                        (progn
                                                          (forward-line 1)
                                                          (setq first nil))
                                                      (replace-match ""))))
                                          (_
                                           (let* ((,in-src-block-var (save-match-data
                                                                       (save-excursion
                                                                         (org-assistant--in-src-block-p))))
                                                  (,insert-prompt-var
                                                   (and
                                                    (not ,in-src-block-var)
                                                    (not org-assistant--request-queue-active-p)
                                                    (eq ,pt-temp-var ,start-pt-var)
                                                    (not
                                                     (save-match-data
                                                       (save-mark-and-excursion
                                                         (and
                                                          (re-search-forward org-assistant--begin-src-regexp nil t))))))))
                                             (progn
                                               (save-excursion
                                                 (goto-char (match-beginning 0))
                                                 (when (not streaming) (replace-match ""))
                                                 (delete-region (match-beginning 0) (match-end 0))
                                                 (insert "#+BEGIN_SRC assistant :sender assistant"
                                                         "\n")
                                                 (if streaming
                                                     (--doto (make-overlay (point) (point))
                                                       (overlay-put it 'stream-id ,replacement-var)
                                                       (overlay-put it 'after-string " _")
                                                       (overlay-put it 'before-string message)
                                                       (puthash ,replacement-var it org-assistant--streaming-overlays))
                                                   (insert message))
                                                 (insert
                                                  "
#+END_SRC"
                                                  (if (and ,insert-prompt-var) "\n\n#+BEGIN_SRC ?\n\n#+END_SRC\n" "")))
                                               (when ,insert-prompt-var
                                                 (re-search-forward org-assistant--begin-src-regexp nil t)
                                                 (re-search-forward org-assistant--begin-src-regexp nil t)
                                                 (forward-line 1)
                                                 (point)))))))))
                                (progn
                                  (unless org-assistant--request-queue-active-p
                                    (goto-char it)
                                    (cl-loop for window in (get-buffer-window-list (current-buffer))
                                             do (set-window-point window it))))))
                            (unless (or org-assistant--request-queue
                                        org-assistant--inflight-request)
                              (setq org-assistant--request-queue-active-p nil)))))))))
         (deferred:$
          (condition-case ,error-var
              (progn ,@prog)
            (error (prog1 nil (babel-response ,error-var)))
            (user-error (prog1 nil (babel-response ,error-var))))
          (when (and it (or (deferred-p it)
                            (error "Provided an unexpected type, expected deferred: %S" it)))
            (deferred:error it (lambda (error) (format "%S" error))))
          (when it
            (deferred:nextc it (lambda (response)
                                 (pcase (car-safe response)
                                   ('file-list
                                    (babel-response (cdr response) (car response)))
                                   (_
                                    (babel-response (if (stringp response)
                                                        response
                                                      (if (not (consp (car-safe response)))
                                                          (s-join "" response)
                                                        (org-assistant--json-encode-pretty-print response))))))))))
         (when ,streaming (run-at-time nil nil (lambda () (babel-response "" nil t)))))
       (when (buffer-live-p ,buffer-var) (with-current-buffer ,buffer-var (force-mode-line-update)))
       (with-current-buffer ,buffer-var
         (push ,replacement-var org-assistant--inflight-request))
       ,replacement-var)))

(cl-defun org-assistant--execute-curl-shell-command-request (&key url method request-id buffer headers body)
  "Execute a curl shell command for `org-assistant'.
URL is the endpoint called from `org-assistant'.
METHOD is the Http method used in the request.
REQUEST-ID is the request id, used for debugging purposes.
BUFFER is the buffer that the process should output to
HEADERS are the headers to send in the request
BODY is a JSON object encoded as a string."
  (start-process-shell-command
   (concat "curl " request-id)
   buffer
   (s-join " "
           (->>
            (append
             (list org-assistant-curl-command url)
             (list "--no-buffer")
             (cl-loop for (header . value) in headers
                      append (list "-H" (concat header ":" (shell-quote-argument value))))
             (list "-X" (shell-quote-argument method))
             body
             nil)))))

(defmacro org-assistant--request-lambda (&rest args)
  "Macro for generating a queueable request lambda.

Intended for use with `org-assistant--queue-request'.

ARGS is expected to be a plist with the following keys:
:url The endpoint
:method The HTTP Method
:headers Defaults to (org-assistant--default-headers) if not set
:json See `org-assistant--json-encode'."
  (-let [(&plist :url :stream :method :headers :request-id :json) args]
    (or url (error "Url must be set %S" args))
    (or method (error "Method must be set %S" args))
    (let ((request-id-var (make-symbol "request-id"))
          (start-marker-var (make-symbol "start-marker"))
          (stream-var (make-symbol "stream")))
      `(let ((,start-marker-var (--doto (make-marker) (set-marker it (point) (current-buffer)))))
         (lambda ()
           (let* ((promise (deferred:new))
                  (,stream-var ,stream)
                  (,request-id-var ,request-id)
                  (shell-buffer (generate-new-buffer " *org-assistant-request*"))
                  (callback
                   (lambda ()
                     (let ((process
                            (funcall org-assistant-execute-curl-process-function
                                     :url ,url
                                     :method ,method
                                     :request-id ,request-id-var
                                     :buffer shell-buffer
                                     :headers (or ,headers (org-assistant--default-headers))
                                     :body
                                     (-some-->
                                         (with-current-buffer (marker-buffer ,start-marker-var)
                                           (save-excursion
                                             (goto-char ,start-marker-var)
                                             (set-marker ,start-marker-var nil)
                                             (funcall ,json)))
                                       (org-assistant--dedupe-alist it)
                                       (let ((file (make-temp-file "json")))
                                         (with-temp-file file
                                           (insert (org-assistant--json-encode it)))
                                         (list "--data" (concat "@" file)))))))
                       (puthash ,request-id-var process org-assistant--request-processes-ht)
                       (push ,request-id-var org-assistant--buffer-requests)
                       (set-process-filter
                        process
                        (lambda (process text)
                          (prog1 (internal-default-process-filter process text)
                            (with-current-buffer (process-buffer process)
                              (save-match-data
                                (save-excursion
                                  (unless org-assistant--process-json-read-pt
                                    (setq-local org-assistant--process-json-read-pt (point-min)))
                                  (goto-char org-assistant--process-json-read-pt)
                                  (let* ((json-objects (org-assistant--parse-stream-json-after-point))
                                         (end-of-parse-pt (point)))
                                    (condition-case err
                                        (cl-loop for json in json-objects
                                                 do
                                                 (funcall ,stream-var json))
                                      (user-error (message "Failed to stream object %S" err))
                                      (error (message "Failed to stream object %S" err)))
                                    (when json-objects
                                      (setq-local org-assistant--process-json-read-pt end-of-parse-pt)))))))))
                       (let ((original-sentinel (process-sentinel process)))
                         (set-process-sentinel
                          process
                          (lambda (process status)
                            (run-at-time
                             nil nil
                             (lambda ()
                               (cond
                                ((not (string= (string-trim status) "finished"))
                                 (deferred:errorback-post promise (concat (with-current-buffer shell-buffer (buffer-string)) "\n" status))
                                 t)
                                ((not (buffer-live-p shell-buffer))
                                 (deferred:errorback-post promise (concat "Buffer not live" (buffer-name shell-buffer)))
                                 t)
                                (t
                                 (with-current-buffer shell-buffer
                                   (deferred:callback-post promise
                                                           (buffer-string)))))

                               (remhash ,request-id-var org-assistant--request-processes-ht)
                               (when (functionp original-sentinel)
                                 (funcall original-sentinel process status))
                               (kill-buffer shell-buffer))))))))))
             (run-at-time nil nil (lambda ()
                                    (condition-case err
                                        (funcall callback)
                                      (error (deferred:errorback-post promise err))
                                      (user-error (deferred:errorback-post promise err)))))
             (deferred:$
              promise
              (deferred:nextc
               it
               (lambda (response)
                 (set-marker ,start-marker-var nil)
                 response))
              (deferred:error
               it
              (lambda (error)
                (set-marker ,start-marker-var nil)
                (error (error-message-string error)))))))))))

(defmacro org-assistant--join-endpoint (domain path)
  "Validate and return joined DOMAIN and PATH."
  `(prog1 (concat ,domain ,path)
     (when (string-suffix-p "/" ,domain)
       (user-error "`%s' must not end with /.  Actual: %s" (quote ,domain) ,domain))
     (unless (string-prefix-p "/" ,path)
       (user-error "`%s' must start with with /.  Actual: %s" (quote ,path) ,path))))

;;;###autoload
(defun org-babel-execute:assistant (text params)
  "Execute an `org-assistant' in an org-babel context.

PARAMS is used to enable noweb mode.
If :echo is set, return the conversation that would be sent to the endpoint
instead of evaluating.

If :list-models is set, the `org-assistant-models-endpoint'
will be called instead.

:params can be set to a list like
'((max_tokens . 1)
  (stop . \"stop\")).

See https://platform.openai.com/docs/api-reference/chat/create
for parameters.

TEXT must be empty if :list-models is set.

This is intended to be called via org babel in a src block with Ctrl-C
Ctrl-C like:

<example>
#+BEGIN_SRC assistant
Hi
#+END_SRC
</example>

The response from the assistant will be in the example block
following:

<example>
#+BEGIN_SRC assistant :sender assistant
Response
#+END_SRC
</example>

All of the messages that are in the same branch of the org tree are
included in the request to the assistant.
<example>
* Question
#+BEGIN_SRC assistant
Hi
#+END_SRC

#+BEGIN_SRC assistant :sender assistant
Response
#+END_SRC

#+BEGIN_SRC assistant
What's up?
#+END_SRC
</example>

Running babel on the second assistant block will send the
conversation:

<example>
User: Hi
Assistant: Response
User: What's up?
</example>

Running babel on the first assistant block will only include the
messages before it:

<example>
User: Hi
</example>

Only messages in the same branch will be included:

<example>
* Question
#+BEGIN_SRC assistant
Hi
#+END_SRC

#+BEGIN_SRC assistant :sender assistant
Response
#+END_SRC
** Branch A
#+BEGIN_SRC assistant
Branch A
#+END_SRC

#+BEGIN_SRC assistant :sender assistant
Branch A Response
#+END_SRC

** Branch B
#+BEGIN_SRC assistant
Branch B
#+END_SRC

#+BEGIN_SRC assistant :sender assistant
Branch B Response
#+END_SRC
</example>
If you ran Ctrl-C Ctrl-C on Branch B's src block the conversation sent
to the endpoint would be:

<example>
User: Hi
Assistant: Response
User: Branch B
Assistant: Branch B Response
</example>

`org-assistant' also supports image generation.
If the :file attribute is set, the image API will be used.

The following is an example of using the image endpoint:

<example>
#+BEGIN_SRC assistant :file output.png
An image of the GNU mascot
#+END_SRC
</example>"
  (org-assistant-cancel-block-at-point)
  (unless (> org-assistant-parallelism 0)
    (user-error "`org-assistant-parallelism' set to an invalid value.  Must be greater than 0"))
  (cond
   ((assoc :list-models params)
    (unless (string-blank-p (string-trim text)) (user-error "Cannot use :list-models if body is not empty"))
    (org-assistant-org-babel-async-response nil
      (deferred:$
       (org-assistant--queue-list-models-request org-assistant--request-id))))
   (t
    (let* ((blocks (lambda () (org-assistant--org-blocks (org-babel-noweb-p params :eval)))))
      (cond
       ((assoc :echo params)
        (concat
         "#+BEGIN_EXAMPLE
"
         (s-join "\n" (--map (format "%S" it) (funcall blocks)))
         "
#+END_EXAMPLE
"))
       ((assoc :file params)
        (let ((files (--> (alist-get :file params) (if (listp it) it (list it)))))
          (--each files (when (not (string-suffix-p ".png" it))
                          (user-error "Only .png output files are supported %s" it)))
          (org-assistant-org-babel-async-response nil
            (deferred:$
             (org-assistant--queue-image-request org-assistant--request-id
                                                 (lambda (json) (babel-response json nil t))
                                                 (alist-get :params params)
                                                 blocks)
             (deferred:nextc it (lambda (response) (org-assistant--json-decode response)))
             (deferred:nextc
              it
              (lambda (response)
                (cons
                 'file-list
                 (cl-loop for data across (alist-get 'data response)
                          collect
                          (let ((file (or (pop files) (user-error "More files returned than expected"))))
                            (prog1 (concat "file:" file)
                              (with-temp-file file
                                  (insert
                                   (base64-decode-string (alist-get 'b64_json data))))))))))))))

       (t (org-assistant-org-babel-async-response t
            (deferred:$
             (org-assistant--queue-chat-request org-assistant--request-id
                                                (lambda (json) (babel-response json nil t))
                                                (alist-get :params params) blocks)
             (deferred:nextc it (lambda (response)
                                  (cond ((listp response) (format "%S" response))
                                        ((babel-output-empty-p) response)
                                        (t ""))))))))))))

;;;###autoload
(defun org-babel-execute:? (&rest args)
  "See `org-babel-execute:assistant'.

ARGS is routed as is."
  (apply #'org-babel-execute:assistant args))

(defun org-assistant--org-blocks (noweb)
  "Return a list of the blocks between point and the top heading of the tree.

When NOWEB is non-nil, expand the blocks with
`org-babel-expand-noweb-references'.
Only blocks that are within the top level section of each heading will
be included, so subheadings can represent multiple paths of the
conversation."
  (save-mark-and-excursion
    (when (org-assistant--in-src-block-p)
      (forward-line 0)
      (or (re-search-forward (rx "#+END_SRC") nil t) (goto-char (point-max))))
    (when (org-in-block-p (list "EXAMPLE"))
      (search-forward "#+END_EXAMPLE"))
    (let ((start-pt (point)))
      (org-assistant--coallesce-assistant-messages
       (cl-loop
        with has-prompt = nil
        for block in
        (reverse
         (cl-loop
          with first = t
          while (if first
                    (prog1 t
                      (org-previous-visible-heading 1)
                      (forward-line 0)
                      (setq first nil))
                  (org-up-heading-safe))
          append
          (-let [(range-start range-end) (list
                                          (point)
                                          (save-excursion
                                            (org-next-visible-heading 1)
                                            (point)))]
            (goto-char range-start)
            (save-excursion
              (reverse
               (cl-loop
                while (re-search-forward (rx (or (regexp org-babel-src-block-regexp)
                                                 (regexp (rx "#+BEGIN_EXAMPLE"
                                                             (*? anything)
                                                             "#+END_EXAMPLE"))))
                                         (min start-pt range-end) t)
                if (save-excursion
                     (save-match-data (goto-char (match-beginning 0))
                                      (string-match-p
                                       (rx (or (regexp org-assistant--begin-src-regexp)
                                               (regexp org-assistant--begin-example-regexp)))
                                       (thing-at-point 'line t))))
                collect (let* ((match-start (match-beginning 0))
                               (match-end (match-end 0))
                               (message-type
                                (progn
                                  (goto-char match-start)
                                  (let ((line (thing-at-point 'line t)))
                                    (if (s-contains-p "BEGIN_EXAMPLE" line)
                                        (if (save-excursion
                                              (forward-line -1)
                                              (s-contains-p "#+SYSTEM" (thing-at-point 'line t)))
                                            'system
                                          'assistant)
                                      (pcase (alist-get :sender (org-assistant--org-src-arguments))
                                        ("assistant" 'assistant)
                                        ("system" 'system)
                                        ((or "user" 'nil) 'user)
                                        (sender (user-error "Unexpected value for :sender '%s'.
Should be either assistant, system, or user" sender))))))))
                          (forward-line 1)
                          (cons message-type
                                (string-trim-right
                                 (org-unescape-code-in-string
                                  (if (and noweb (eq message-type 'user))
                                      (org-babel-expand-noweb-references)
                                    (buffer-substring-no-properties
                                     (point)
                                     (save-excursion (goto-char match-end)
                                                     (forward-line 0)
                                                     (point))))))))))))))
        collect
        (if has-prompt
            block
          (if (eq (car block) 'user)
              (prog1 block
                (setq has-prompt t))
            (cons 'system (cdr block)))))))))




(defun org-assistant-models-endpoint ()
  "Return the full endpoint URL for the models API."
  (org-assistant--join-endpoint org-assistant-endpoint
                                org-assistant-endpoint-path-models))

(defun org-assistant-chat-endpoint ()
  "Return the full endpoint URL for the chat API."
  (org-assistant--join-endpoint org-assistant-endpoint
                                org-assistant-endpoint-path-chat))

(defun org-assistant-image-endpoint ()
  "Return the full endpoint URL for the image API."
  (org-assistant--join-endpoint org-assistant-endpoint
                                org-assistant-endpoint-path-image))

;;;###autoload
(defun org-assistant-explain-function ()
  "Ask the assistant to explain the function at point."
  (interactive)
  (org-assistant-with-initial-message (concat (thing-at-point 'defun t) "\nExplain this function for me")))

;;;###autoload
(defun org-assistant-write-docstring ()
  "Ask the assistant to generate a docstring for the function at point."
  (interactive)
  (org-assistant-with-initial-message (concat (thing-at-point 'defun t) "\nWrite a concise docstring for me")))


(defun org-assistant--queue-request (request-id job)
  "Execute or queue the `org-assistant' request for JOB.

REQUEST-ID is used to keep track of the request for later.
Return a deferred object representing the completion of the
request."
  (let* ((promise (deferred:new))
         (job-with-promise
          (lambda ()
            (let ((promise promise))
              (deferred:$
               (condition-case err
                   (funcall job)
                 (user-error (deferred:errorback-post (deferred:new) err))
                 (error (deferred:errorback (deferred:new) err)))
               (deferred:nextc it (lambda (result)
                                    (prog1 t
                                      (deferred:callback-post promise result))))
               (deferred:error it (lambda (error)
                                    (deferred:errorback-post promise error)
                                    "SUPPRESSED")))))))
    (if (>= (hash-table-count org-assistant--request-processes-ht) org-assistant-parallelism)
        (setq org-assistant--request-queue
              (append org-assistant--request-queue
                      (list (cons request-id job-with-promise)) nil))
      (org-assistant--queue-request-execute job-with-promise))
    promise))

(defun org-assistant--queue-image-request (request-id _ block-params blocks)
  "Execute or queue the `org-assistant' request for BLOCKS.

REQUEST-ID is used to keep track of the request for later.
BLOCK-PARAMS contains the params of the calling block.
Return a deferred object representing the completion of the
request."
  (org-assistant--queue-request
   request-id
   (org-assistant--request-lambda
    :request-id request-id
    :url (org-assistant-image-endpoint)
    :method "POST"
    :json (lambda ()
            `(,@(org-assistant--validate-parameters org-assistant-image-extra-parameters-alist)
              ,@(org-assistant--validate-parameters block-params)
              ("response_format" . "b64_json")
              ("prompt" . ,(cl-loop for (name . message) in (funcall blocks)
                                    concat
                                    (concat (symbol-name name)
                                            ": "
                                            message))))))))

(defun org-assistant--default-headers ()
  "Return the headers used by the `org-assistant' endpoint."
  `(("Authorization" . ,(concat "Bearer "
                                (if (stringp org-assistant-auth-function)
                                    org-assistant-auth-function
                                  (funcall org-assistant-auth-function))))
    ("Content-Type" . "application/json; charset=utf-8")
    ("Accept" . "application/json")))

(defun org-assistant--validate-parameters (parameters)
  "Validate that PARAMETERS are valid and emit error messages if not."
  (--doto (org-assistant--dedupe-alist parameters)
    (unless (or (not it) (and (listp it) (consp (car it))))
      (user-error "`org-assistant-chat-extra-parameters-alist' must be an alist: %S" it))
    (when (--first (consp (cdr it)) parameters)
      (user-error "a-list must be all cons cells.  You may have forgotten the dot.  %S" it))))

(defun org-assistant--queue-chat-request (request-id babel-response block-params blocks)
  "Execute or queue the `org-assistant' request for BLOCKS.

BLOCK-PARAMS contains the params of the calling block.
BABEL-RESPONSE contains a callback for streaming the message to babel.
REQUEST-ID is used to keep track of the request for later.
Return a deferred object representing the completion of the
request."
  (org-assistant--queue-request
   request-id
   (org-assistant--request-lambda
    :request-id request-id
    :url (org-assistant-chat-endpoint)
    :method "POST"
    :stream (lambda (diff)
              (if (eq diff 'done)
                  nil ;; Do nothing, the process also ends so handle it there
                (-some--> (alist-get 'choices diff)
                  (aref it 0)
                  (alist-get 'delta it)
                  (alist-get 'content it)
                  (funcall babel-response it))))
    :json
    (lambda ()
      `(("model" . ,org-assistant-model)
        (stream . t)
        ,@(org-assistant--validate-parameters org-assistant-chat-extra-parameters-alist)
        ,@(org-assistant--validate-parameters block-params)
        ("messages" .
         ,(->> (funcall blocks)
               (--map `(("content" . ,(cdr it))
                        ("role" . ,(symbol-name (car it)))))
               (vconcat))))))))

(defun org-assistant--coallesce-assistant-messages (blocks)
  "Return BLOCKS with the consecutive assistant messages merged."
  (cl-loop with output = nil
           for (type . value) in blocks
           do
           (if (and (eq type 'assistant)
                   (eq (caar output) 'assistant))
               (setcdr (car output) (concat (cdar output) value))
               (push (cons type value) output))
           finally return (reverse output)))

(defun org-assistant--dedupe-alist (alist)
  "Dedupe the keys in the ALIST."
  (ht->alist (ht<-alist (reverse alist))))


(defun org-assistant--queue-list-models-request (request-id)
  "Execute or queue the `org-assistant' list-models request.

REQUEST-ID is used to keep track of the request for later.
Return a deferred object representing the completion of the
request."
  (org-assistant--queue-request
   request-id
   (org-assistant--request-lambda
    :request-id request-id
    :url (org-assistant-models-endpoint)
    :method "GET")))

(defun org-assistant-clear-request-queue ()
  "Reset `org-assistant' request queue to orginal state."
  (interactive)
  (cl-loop for process in (hash-table-values org-assistant--request-processes-ht)
           do (ignore-errors (kill-process process)))
  (setq org-assistant--request-processes-ht (make-hash-table :test #'equal))
  (cl-loop for overlay in (hash-table-values org-assistant--streaming-overlays)
           do (delete-overlay overlay))
  (setq org-assistant--streaming-overlays (make-hash-table :test #'equal))
  (setq org-assistant--inflight-request nil)
  (setq org-assistant--request-queue-active-p nil)
  (setq org-assistant--request-queue nil))

(defun org-assistant--queue-request-execute (job)
  "Execute JOB for `org-assistant'.

JOB may be delayed based on `org-assistant-parallelism'.

Return nil."
  (prog1 nil
    (deferred:$
     (deferred:next (lambda (&rest _) (funcall job)))
     (deferred:error it (lambda (_) ;; logged elsewhere
                          "SUPPRESSED"))
     (deferred:nextc
      it
      (lambda (result)
        (prog1 result
          (-some--> (pop org-assistant--request-queue)
            (org-assistant--queue-request-execute (cdr it))))))
     (deferred:nextc it (lambda (&rest arg) arg)))
      (when (or org-assistant--inflight-request
                org-assistant--request-queue)
        (setq org-assistant--request-queue-active-p t))))

(defun org-assistant--json-encode (alist)
  "Return ALIST encoded as json."
  (let ((json-object-type 'alist)
        (json-key-type 'string)
        (json-array-type 'vector))
    (json-encode alist)))

(defun org-assistant--json-encode-pretty-print (alist)
  "Return ALIST encoded as json pretty printed."
  (org-assistant--json-encode alist))

(defun org-assistant--json-decode (json)
  "Return alist decoded from JSON."
  (let ((json-object-type 'alist)
        (json-key-type 'symbol)
        (json-array-type 'vector))
    (json-read-from-string json)))

(defun org-assistant--forward-stream-id-overlay ()
  "Return the next stream id overlay from point."
  (cl-loop with output = nil
           while (not (or output (eobp)))
           do (progn
                (setq output (-some->>
                              (overlays-in (point) (point))
                              (--map (overlay-get it 'stream-id))
                              (car)))
                (forward-line 1))
           finally return output))

(defun org-assistant--kill-request (stream-id)
  "Kill the request with STREAM-ID."
  (let ((process (gethash stream-id org-assistant--request-processes-ht)))
    (when (process-live-p process) (kill-process process))
    (remhash stream-id org-assistant--request-processes-ht)
    (-some--> (gethash stream-id org-assistant--streaming-overlays)
      (with-current-buffer (overlay-buffer it)
        (save-excursion
          (goto-char (overlay-start it))
          (when (save-match-data
                  (save-excursion
                    (goto-char (overlay-start it))
                    (org-assistant--in-src-block-p)))
            (insert (overlay-get it 'before-string))))
        (delete-overlay it)))
    (remhash stream-id org-assistant--streaming-overlays)
    (setq org-assistant--buffer-requests
          (--filter (not (string= it stream-id)) org-assistant--buffer-requests))
    (setq org-assistant--inflight-request
          (--filter (not (string= it stream-id)) org-assistant--inflight-request))))

(defun org-assistant-cancel-block-at-point ()
  "Cancel the `org-assistant' execution at point.

This refers to the streaming block before or after the current block.
It will not cancel a block that is streaming at point."
  (interactive)
  (save-match-data
    (save-excursion
      (forward-line 0)
      (re-search-forward (rx line-start "#+END_SRC") nil t)
      (cond
       ((save-excursion
          (-some-->
              (save-excursion (org-assistant--forward-stream-id-overlay))
            (org-assistant--kill-request it)))
        t)
       (t (let ((end (save-excursion
                       (forward-line 4)
                       (point))))
            (when (re-search-forward (rx line-start "#+RESULTS:") end t)
              (goto-char (match-beginning 0))
              (forward-line 1)
              (cl-flet ((uuid-at-point ()
                          (cond
                           ((looking-at (rx line-start (* whitespace) (+ (any alphanumeric "-")) (* whitespace) line-end))
                            (string-trim (match-string 0)))
                           (t
                            (when (re-search-forward
                                   (rx line-start (* whitespace) (+ (any alphanumeric "-")) (* whitespace) line-end)
                                   (org-babel-result-end)
                                   t)
                              (match-string 0))))))
                (cl-loop with uuid = nil
                         while (setq uuid (uuid-at-point))
                         do
                         (when
                             (gethash uuid org-assistant--request-processes-ht)
                           (progn
                             (replace-match "")
                             (org-assistant--kill-request uuid)))
                         (forward-line 1))))))))))

(defun org-assistant--org-src-arguments ()
  "Return an alist containing the arguments for the src block.

If it cannot find the src block, returns nil."
  (ignore-errors
    (save-excursion
      (org-babel-goto-src-block-head)
      (org-babel-parse-header-arguments
       (s-join " " (cddar (org-parse-arguments)))))))

(defun org-assistant--parse-stream-json-after-point ()
  "Return a list of the jsons after point.
Sets point to the last unparsed line on completion."
  (let ((list nil))
    (forward-line 0)
    (cl-block completed
      (condition-case _
          (cl-loop while (not (eobp))
                   do
                   (progn
                     (when (looking-at (rx "data:" (+ whitespace) "[DONE]"))
                       (push 'done list)
                       (forward-line 1)
                       (cl-return-from completed))
                     (when (looking-at (rx "data:" (* whitespace)))
                       (goto-char (match-end 0))
                       (push (json-read) list))
                     (forward-line 1)))
        (error (forward-line -1))))
    (reverse list)))

(defun org-assistant--generate-replacement-string ()
  "Return a replacement token for the async process."
  (uuidgen-4))

(defun org-assistant-kill-buffer-requests ()
  "Kill all ongoing `org-assistant' requests in buffer."
  (cl-loop for uuid in org-assistant--buffer-requests
           do
           (-some--> (gethash uuid org-assistant--request-processes-ht)
             (when (process-live-p it) (kill-process it)
                   (remhash uuid org-assistant--request-processes-ht))))
  (setq org-assistant--buffer-requests nil))

(defun org-assistant--in-src-block-p ()
  "Return non-nil if in an assistant src block."
  (and (org-in-src-block-p)
       (let* ((start-pt (point))
              (element (org-element-at-point))
              (element-end (org-element-property :end element)))
         (when element-end
           (save-excursion
             (goto-char element-end)
             (and
              (save-excursion
                (when (re-search-backward org-assistant--end-src-regexp (org-element-property :begin element) t)
                  (<= start-pt (match-end 0))))
              (save-excursion
                (when (re-search-backward org-assistant--begin-src-regexp (org-element-property :begin element) t)
                  (and
                   (not (--first (overlay-get it 'stream-id) (overlays-in (point) (point))))
                   (>= start-pt (match-beginning 0)))))))))))

(provide 'org-assistant)
;;; org-assistant.el ends here
