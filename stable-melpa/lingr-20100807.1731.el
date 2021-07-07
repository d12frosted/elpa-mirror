;;; lingr.el --- Lingr Client for GNU Emacs

;; Copyright (C) 2010 lugecy <lugecy@gmail.com>

;; Author: lugecy <lugecy@gmail.com>
;; URL: http://github.com/lugecy/lingr-el
;; Package-Version: 20100807.1731
;; Package-Commit: 4215a8704492d3c860097cbe2649936c22c196df
;; Keywords: chat, client, Internet
;; Version: 0.2

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
;; Lingr (web chat service: http://lingr.com/) client for GNU Emacs

;;; Usage:
;; (require 'lingr)
;; (setq lingr-username <username>
;;       lingr-password <password>)
;; and
;; M-x lingr-login

;;; Code:

(require 'cl)
(require 'json)
(require 'url)
(require 'parse-time)
(require 'timezone)

;;;; Internal variables
(defgroup lingr nil
  "Lingr mode."
  :group 'chat
  :prefix "lingr-")

(defcustom lingr-username nil
  "Lingr username."
  :type 'string
  :group 'lingr)

(defcustom lingr-password nil
  "Lingr password."
  :type 'string
  :group 'lingr)

(defcustom lingr-url-show-status nil
  "If non-nil, show read status of url package."
  :type 'boolean
  :group 'lingr)

(defcustom lingr-show-update-notification t
  "If non-nil, show update summay."
  :type 'boolean
  :group 'lingr)

(defcustom lingr-icon-mode nil
  "if non-nil, use user icon."
  :type 'boolean
  :group 'lingr)

(defcustom lingr-image-convert-program
  (cond ((eq system-type 'windows-nt) "e:/cygwin/bin/convert.exe")
        (t "/usr/bin/convert"))
  "Program path for icon fix size."
  :type 'string
  :group 'lingr)

(defcustom lingr-icon-fix-size 32
  "Icon fix size."
  :type 'integer
  :group 'lingr)

(defcustom lingr-http-use-wget nil
  "If non-nil, http-session use wget command."
  :type 'boolean
  :group 'lingr)

(defcustom lingr-wget-program "wget"
  "Program path for wget."
  :type 'string
  :group 'lingr)

(defcustom lingr-auto-trigger-get-before-archive t
  "If non-nil, lingr-room-previous-nick command trigger get-before-archive in buffer head."
  :type 'boolean
  :group 'lingr)

(defcustom lingr-clear-unread-on-visit nil
  "If non-nil, clears status buffer's notification when buffer visited."
  :type 'boolean
  :group 'lingr)

(defvar lingr-room-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-s") 'lingr-say-command)
    (define-key map (kbd "C-c C-b") 'lingr-switch-room)
    (define-key map (kbd "C-c C-p") 'lingr-get-before-archive)
    (define-key map (kbd "C-c C-l") 'lingr-refresh-room)
    (define-key map (kbd "u") 'lingr-say-command)
    (define-key map (kbd "r") 'lingr-switch-room)
    (define-key map (kbd "g") 'lingr-clear-roster-unread)
    (define-key map (kbd "S") 'lingr-show-status)
    (define-key map (kbd "j") 'lingr-room-next-nick)
    (define-key map (kbd "k") 'lingr-room-previous-nick)
    (define-key map (kbd "n") 'lingr-room-next-message)
    (define-key map (kbd "p") 'lingr-room-previous-message)
    map)
  "Lingr room mode map.")

(defvar lingr-status-buffer-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'lingr-status-switch-room)
    (define-key map (kbd "o") 'lingr-status-switch-room-other-window)
    (define-key map (kbd "n") 'lingr-room-next-message)
    (define-key map (kbd "p") 'lingr-room-previous-message)
    (define-key map (kbd "j") 'lingr-status-next-room)
    (define-key map (kbd "k") 'lingr-status-previous-room)
    (define-key map (kbd "f") 'lingr-status-jump-message)
    map)
  "Lingr status buffer map.")

(defvar lingr-connected-hook nil)
(defvar lingr-message-hook nil)
(defvar lingr-join-hook nil)
(defvar lingr-leave-hook nil)

(defface lingr-nickname-face
  '((t (:foreground "cornflower blue")))
  "Face for nickname.")

(defface lingr-timestamp-face
  '((t (:foreground "gray50")))
  "Face for timestamp.")

(defface lingr-presence-event-face
  '((t (:foreground "gray45")))
  "Face for presence event.")

(defface lingr-status-room-face
  '((t (:foreground "Green")))
  "Face for status buffer room name.")

(defface lingr-status-unread-face
  '((t (:foreground "cornflower blue")))
  "Face for status buffer unread event.")

(defvar lingr-base-url "http://lingr.com/api/")
(defvar lingr-observe-base-url "http://lingr.com:8080/api/")
(defvar lingr-http-response-json nil)
(defvar lingr-observe-response nil)
(defvar lingr-session-data nil)
(defvar lingr-observe-buffer nil)
(defvar lingr-observe-retry-timer nil)
(defvar lingr-get-archives-async-buffer nil)
(defvar lingr-logout-session-flg nil)
(defvar lingr-subscribe-counter nil)
(defvar lingr-buffer-basename "Lingr")
(defvar lingr-buffer-room-id nil)
(defvar lingr-roster-table (make-hash-table :test 'equal))
(defvar lingr-last-say-id nil)
(defvar lingr-say-winconf nil)
(defvar lingr-say-window-height-per 20)
(defvar lingr-say-buffer "*Lingr Say*")
(defvar lingr-status-buffer "*Lingr Status*")
(defvar lingr-get-before-limit 30)
(defvar lingr-image-hash (make-hash-table :test 'equal)) ;; hash-table for caching image data
(defvar lingr-image-request-queue nil)
(defvar lingr-last-say-nick nil)
(defvar lingr-error-icon-data-pair
  '(xpm . "/* XPM */
static char * yellow3_xpm[] = {
\"16 16 2 1\",
\" 	c None\",
\".	c #FF0000\",
\"................\",
\".              .\",
\". .          . .\",
\".  .        .  .\",
\".   .      .   .\",
\".    .    .    .\",
\".     .  .     .\",
\".      ..      .\",
\".      ..      .\",
\".     .  .     .\",
\".    .    .    .\",
\".   .      .   .\",
\".  .        .  .\",
\". .          . .\",
\".              .\",
\"................\"};
"))


;;;; Utility Macro
(defmacro lingr-aif (test-form then-form &rest else-forms)
  (declare (indent 2)
           (debug (form form &rest form)))
  "Anaphoric if. Temporary variable `it' is the result of test-form."
  `(let ((it ,test-form))
     (if it ,then-form ,@else-forms)))

;;;; http access utility
(defun lingr-http-get (url args callback &optional cbargs async)
  "Send ARGS to URL as a GET request."
  (lingr-http-session "GET" url args callback cbargs async))

(defun lingr-http-post (url args callback &optional cbargs async)
  "Send ARGS to URL as a POST request."
  (lingr-http-session "POST" url args callback cbargs async))

(defun lingr-http-session (method url args callback &optional cbargs async)
  (let* ((data-string (mapconcat (lambda (arg)
                                   (concat (url-hexify-string (car arg))
                                           "="
                                           (url-hexify-string (cdr arg))))
                                 args
                                 "&"))
         (request-url (if (and (string-equal method "GET")
                               (> (length data-string) 0))
                          (concat url "?" data-string)
                        url))
         (url-request-method method)
         (url-request-data (if (string-equal method "GET")
                               ""
                             data-string))
         (url-show-status lingr-url-show-status))
    (if lingr-http-use-wget
        (lingr-http-session-use-wget request-url url-request-data callback cbargs async)
      (if async
          (let ((buffer (url-retrieve request-url callback cbargs)))
            (when (buffer-live-p buffer)
              (with-current-buffer buffer
                (set (make-local-variable 'url-show-status)
                     lingr-url-show-status)))
            buffer)
        (lingr-aif (url-retrieve-synchronously request-url)
            (with-current-buffer it
              (apply callback nil cbargs)))))))

(defun lingr-http-session-use-wget (url post-data callback cbargs async)
  (let ((buffer (generate-new-buffer "*lingr-wget*"))
        (wget-args `("-q" "--save-headers" "-O-"
                     ,@(if (> (length post-data) 0)
                           (list "--post-data" post-data))
                     ,url)))
    (with-current-buffer buffer
      (set-buffer-multibyte nil)
      (buffer-disable-undo)
      (make-local-variable 'require-final-newline)
      (setq require-final-newline nil))
    (if async
        (let* ((proc (let ((coding-system-for-read 'binary)
                           (coding-system-for-write 'binary))
                       (apply #'start-process "lingr-wget" buffer lingr-wget-program wget-args))))
          (set-process-sentinel proc
                                (lexical-let ((callback callback)
                                              (cbargs cbargs))
                                  (lambda (proc status)
                                    (with-current-buffer (process-buffer proc)
                                      (apply callback nil cbargs)))))
          buffer)
      (let ((proc (let ((coding-system-for-read 'binary)
                        (coding-system-for-write 'binary))
                    (apply #'call-process lingr-wget-program nil buffer nil wget-args))))
        (with-current-buffer buffer
          (apply callback nil cbargs))))))

(defun lingr-api-access-callback (status func &rest args)
  (unwind-protect
      (progn
        (when (eq (car status) :error)
          (error "GET/POST fail."))
        (goto-char (point-min))
        (unless (looking-at "HTTP/")
          (lingr-debug-observe-log (propertize "Lingr server not response." 'face '(:foreground "Red")))
          (error "Lingr server not response."))
        (let ((json (lingr-get-json-data))
              (buffer (current-buffer)))
          (unless (equal (lingr-response-status json) "ok")
            (lingr-debug-observe-log (format "%s %s" (propertize "Error" 'face '(:foreground "Red")) (list  status func args json)))
            (error "Lingr API Error: %s" json))
          (kill-buffer buffer)
          (apply func (cons json args))))
    (lingr-update-status-buffer)))

;;;; Data struct access functions
(defun lingr-session-id (session) (assoc-default 'session session))
(defun lingr-session-nick (session) (assoc-default 'nickname session))

(defun lingr-response-status (json) (assoc-default 'status json))
(defun lingr-response-counter (json) (assoc-default 'counter json))
(defun lingr-response-events (json) (assoc-default 'events json))
(defun lingr-response-rooms (json) (assoc-default 'rooms json))
(defun lingr-response-messages (json) (assoc-default 'messages json))
(defun lingr-response-message (json) (assoc-default 'message json))

(defun lingr-get-roster (room-id) (gethash room-id lingr-roster-table))
(defun lingr-get-roster-member (username roster)
  (assoc-default username (lingr-roster-members roster)))
(defun lingr-roster-id (roster) (assoc-default 'id roster))
(defun lingr-roster-buffer (roster) (assoc-default 'buffer roster))
(defun lingr-roster-name (roster) (assoc-default 'name roster))
(defun lingr-roster-members (roster) (assoc-default 'members roster))
(defun lingr-roster-unread (roster) (assoc-default 'unread roster))

(defun lingr-member-name (member) (assoc-default 'name member))
(defun lingr-member-online-p (member) (assoc-default 'is_online member))

(defun lingr-event-message (event) (assoc-default 'message event))
(defun lingr-event-presence (event) (assoc-default 'presence event))

(defun lingr-message-nick (message) (assoc-default 'nickname message))
(defun lingr-message-text (message) (assoc-default 'text message))
(defun lingr-message-room (message) (assoc-default 'room message))
(defun lingr-message-timestamp (message) (assoc-default 'timestamp message))
(defun lingr-message-id (message) (assoc-default 'id message))
(defun lingr-message-icon-url (message) (assoc-default 'icon_url message))

(defun lingr-presence-text (presence) (assoc-default 'text presence))
(defun lingr-presence-room (presence) (assoc-default 'room presence))
(defun lingr-presence-timestamp (presence) (assoc-default 'timestamp presence))
(defun lingr-presence-username (presence) (assoc-default 'username presence))
(defun lingr-presence-status (presence) (assoc-default 'status presence))

;;;; Lingr API functions
(defun lingr-call-api (path args &optional callback cbargs error-handler)
  (let ((api-callback (lexical-let ((callback (or callback 'lingr-default-callback))
                                    (error-handler error-handler))
                        (lambda (status &rest args)
                          (condition-case e
                              (apply 'lingr-api-access-callback status callback args)
                            (error (if error-handler
                                       (funcall error-handler)
                                     (error (error-message-string e)))))))))
    (cond ((string= path "event/observe")
           (lingr-http-get (concat lingr-observe-base-url path) args api-callback cbargs t))
          ((member path '("room/show" "room/get_archives"))
           (lingr-http-get (concat lingr-base-url path) args api-callback cbargs t))
          ((member path '("session/create" "session/verify" "user/get_rooms"))
           (lingr-http-get (concat lingr-base-url path) args api-callback cbargs))
          ((member path '("session/set_presence" "session/destroy"
                          "room/subscribe" "room/unsubscribe" "room/say"))
           (lingr-http-post (concat lingr-base-url path) args api-callback cbargs))
          (t
           (error "unsupport api call.")))))

(defun lingr-api-session-create (user password)
  (lingr-call-api "session/create"
                   `(("user" . ,user) ("password" . ,password))
                   (lambda (json &rest args) (setq lingr-session-data json))))

(defun lingr-api-session-verify (session-id)
  (lingr-call-api "session/verify"
                  `(("session" . ,session-id))))

(defun lingr-api-session-destroy (session)
  (lingr-aif (lingr-session-id session)
      (lingr-call-api "session/destroy" `(("session" . ,it)) )))

(defun lingr-api-set-presence (session presence)
  (lingr-aif (lingr-session-id session)
      (lingr-call-api "session/set_presence"
                       `(("session" . ,it) ("presence" . ,presence)
                         ("nickname" . ,(lingr-session-nick session))) )))

(defun lingr-api-get-rooms (session)
  (lingr-aif (lingr-session-id session)
      (lingr-call-api "user/get_rooms" `(("session" . ,it))
                      (lambda (json &rest args) (lingr-response-rooms json)))))

(defun lingr-api-room-show (session room)
  (lingr-aif (lingr-session-id session)
      (let ((single-p (not (string-match "," room))))
        (lingr-call-api "room/show"
                        `(("session" . ,it) ("room" . ,room))
                        'lingr-api-room-show-callback
                        (list it (if single-p room nil))))))

(defun lingr-api-get-archives (session room max_message_id &optional limit)
  (lingr-aif (lingr-session-id session)
      (setq lingr-get-archives-async-buffer
            (lingr-call-api "room/get_archives"
                            `(("session" . ,it) ("room" . ,room)
                              ("before" . ,max_message_id) ("limit" . ,(number-to-string (or limit lingr-get-before-limit))))
                            'lingr-api-get-archives-callback
                            (list it room)))))

(defun lingr-api-subscribe (session room &optional reset)
  (lingr-aif (lingr-session-id session)
      (lingr-call-api "room/subscribe"
                       `(("session" . ,it) ("room" . ,room)
                         ("reset" . ,(or reset "true")))
                       'lingr-api-subscribe-callback)))

(defun lingr-api-unsubscribe (session room)
  (lingr-aif (lingr-session-id session)
      (lingr-call-api "room/unsubscribe"
                       `(("session" . ,it) ("room" . ,room)))))

(defun lingr-api-say (session room text)
  (lingr-aif (lingr-session-id session)
      (lingr-call-api "room/say"
                       `(("session" . ,it) ("room" . ,room)
                         ("nickname" . ,(lingr-session-nick session))
                         ("text" . ,(encode-coding-string text 'utf-8))))))

(defun lingr-api-observe (session)
  (lingr-aif (lingr-session-id session)
      (when lingr-subscribe-counter
        (setq lingr-observe-buffer
              (lingr-call-api "event/observe"
                              `(("session" . ,it) ("counter" . ,(number-to-string lingr-subscribe-counter)))
                              'lingr-api-observe-callback
                              (list it lingr-subscribe-counter)
                              'lingr-api-observe-error-handler)))))

;;;; Lingr API callback functions
(defun lingr-default-callback (json &rest args)
  (setq lingr-http-response-json json))

(defun lingr-api-room-show-callback (json &rest args)
  (setq lingr-http-response-json json)
  (when (lingr-current-session-p (car args))
    (lingr-refresh-rooms json)
    (lingr-aif (cadr args)
        (lingr-switch-room it)
      (lingr-show-status t))))

(defun lingr-api-subscribe-callback (json &rest args)
  (setq lingr-http-response-json json)
  (setq lingr-subscribe-counter (lingr-response-counter json)))

(defun lingr-api-observe-callback (json &rest args)
  (setq lingr-observe-response json)
  (lingr-debug-observe-log json)
  (when (and (lingr-current-session-p (car args))
             (eq lingr-subscribe-counter (cadr args)))
    (lingr-aif (lingr-response-counter json)
        (setq lingr-subscribe-counter it))
    (lingr-aif (lingr-response-events json)
        (save-window-excursion
          (save-excursion
            (let ((updates (loop for event across it
                                 collect (lingr-update-by-event event))))
              (when lingr-show-update-notification
                (lingr-show-update-summay updates))))))
    (setq lingr-observe-buffer nil)
    (when (timerp lingr-observe-retry-timer)
      (cancel-timer lingr-observe-retry-timer)
      (setq lingr-observe-retry-timer nil))
    (unless lingr-logout-session-flg
      (lingr-api-observe lingr-session-data))))

(defun lingr-api-observe-error-handler ()
  (message "Lingr observe error. Retry...")
  (when (timerp lingr-observe-retry-timer)
    (cancel-timer lingr-observe-retry-timer)
    (setq lingr-observe-retry-timer nil))
  (setq lingr-observe-retry-timer
        (run-with-timer 60 nil 'lingr-api-observe lingr-session-data))
  (when (buffer-live-p lingr-observe-buffer)
    (kill-buffer lingr-observe-buffer))
  (lingr-update-status-buffer))

(defun lingr-api-get-archives-callback (json &rest args)
  (setq lingr-http-response-json json)
  (when (lingr-current-session-p (car args))
    (with-current-buffer (lingr-get-room-buffer (cadr args))
      (goto-char (point-min))
      (let ((buffer-read-only nil))
        (save-excursion
          (insert (concat (make-string (window-width) ?-) "\n")))) ;separete mark
      (loop for message across (lingr-response-messages json)
            with last-say-nick
            initially (setq last-say-nick lingr-last-say-nick
                            lingr-last-say-nick nil)
            do
            (let ((buffer-read-only nil))
              (lingr-insert-message message))
            finally (setq lingr-last-say-nick last-say-nick)))
    (setq lingr-get-archives-async-buffer nil)))

;;;; Utility function
(defmacro lingr-update-with-buffer (buffer &rest body)
  (declare (indent 1))
  `(when (buffer-live-p ,buffer)
     (with-current-buffer ,buffer
       (goto-char (point-max))
       (let ((buffer-read-only nil))
         ,@body))))

(defun lingr-get-json-data ()
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "\r?\n\r?\n" nil t)
      (let ((json-object-type 'alist) (json-array-type 'vector)
            (json-key-type nil) (json-false nil))
        (json-read-from-string
         (decode-coding-string (buffer-substring-no-properties (point) (point-max)) 'utf-8))))))

(defun lingr-current-session-p (session-id)
  (and lingr-session-data
       (string-equal (lingr-session-id lingr-session-data) session-id)))

(defun lingr-event-type (event)
  (cond ((lingr-event-message event) 'message)
        ((lingr-event-presence event) 'presence)
        (t nil)))

(defun lingr-observe-alive ()
  (and (buffer-live-p lingr-observe-buffer)
       (get-buffer-process lingr-observe-buffer)))

(defun lingr-get-room-buffer (room-id)
  (or (lingr-aif (lingr-roster-buffer (gethash room-id lingr-roster-table))
          (if (buffer-live-p it) it nil))
      (get-buffer-create (format "%s[%s]" lingr-buffer-basename room-id))))

(defun lingr-get-room-id-list ()
  (loop for key being the hash-keys in lingr-roster-table using (hash-value roster)
        if (buffer-live-p (lingr-roster-buffer roster)) collect key))

(defun lingr-get-icon-data (url)
  (let ((image (gethash url lingr-image-hash)))
    (cond ((eq (car-safe image) 'image) image)
          ((eq image 'convert-error) (create-image (cdr lingr-error-icon-data-pair) (car lingr-error-icon-data-pair) t))
          (t nil))))

(defun lingr-get-image (url)
  (or (lingr-get-icon-data url)
      (member url lingr-image-request-queue)
      (prog1
        (push url lingr-image-request-queue)
        (when (= (length lingr-image-request-queue) 1)
          (lingr-http-get-icon-image url)))))

(defun lingr-http-get-icon-image (url)
  (lingr-http-get url nil 'lingr-regist-icon-image (list url) t))

(defun lingr-regist-icon-image (status &rest args)
  (let ((url (car args)))
    (when (and (goto-char (point-min)) (looking-at "HTTP/"))
      (message "Lingr icon registering...")
      (let* ((type (when (re-search-forward  "Content-Type: image/\\([^\r\n]+\\)" nil t)
                     (intern (match-string 1))))
             (raw-data (when (and type (re-search-forward "\r?\n\r?\n" nil t))
                         (buffer-substring (point) (point-max))))
             (fixed-data-pair (and raw-data (lingr-convert-image-data raw-data type))))
        (if fixed-data-pair
            (puthash url (create-image (car fixed-data-pair) (cdr fixed-data-pair) t) lingr-image-hash)
          (puthash url 'convert-error lingr-image-hash))
        (dolist (room-id (lingr-get-room-id-list))
          (lingr-room-update-icon (lingr-get-room-buffer room-id)))
        (message "Lingr icon registering...Done.")))
    (kill-buffer (current-buffer))
    (setq lingr-image-request-queue (delete url lingr-image-request-queue))
    (when lingr-image-request-queue
      (lingr-http-get-icon-image (car lingr-image-request-queue)))))

(defun lingr-convert-image-data (image-data src-type)
  (if (not (and lingr-image-convert-program
                (file-executable-p lingr-image-convert-program)))
      (cons image-data src-type)
    (with-temp-buffer
      (set-buffer-multibyte nil)
      (buffer-disable-undo)
      (let ((coding-system-for-read 'binary)
            (coding-system-for-write 'binary)
            (require-final-newline nil))
        (insert image-data)
        (let* ((args
                `(,(format "%s:-" src-type)
                  ,@(when (integerp lingr-icon-fix-size)
                      `("-resize"
                        ,(format "%dx%d" lingr-icon-fix-size lingr-icon-fix-size)))
                  "xpm:-"))
               (exit-status
                (apply 'call-process-region (point-min) (point-max)
                       lingr-image-convert-program t t nil args)))
          (if (and (equal 0 exit-status)
                   (> (length (buffer-string)) 0))
              (cons (buffer-string) 'xpm)
            ;; failed to convert the image.
            nil))))))

(defun lingr-icon-image (message)
  (let ((image (lingr-get-image (lingr-message-icon-url message))))
    (cond ((eq (car-safe image) 'image)
           (propertize "_" 'display image))
          (image
           (propertize "_" 'need-to-update (lingr-message-icon-url message)))
          (t ""))))

(defun lingr-decode-timestamp (timestamp)
  (format-time-string "[%x %T]" (apply 'encode-time (parse-time-string (timezone-make-date-arpa-standard timestamp)))))

(defun lingr-insert-message (message)
  (let* ((nick (lingr-message-nick message))
         (text (lingr-message-text message))
         (timestamp (lingr-message-timestamp message))
         (id (lingr-message-id message))
         (fill-str (make-string 2 ? )))
    (unless (string-equal lingr-last-say-nick nick)
      (insert (format "%s%-20s %s\n"
                      (if lingr-icon-mode
                          (lingr-icon-image message)
                        "")
                      (propertize nick 'face 'lingr-nickname-face 'nick nick 'mes-separete t)
                      (propertize (lingr-decode-timestamp timestamp) 'face 'lingr-timestamp-face))))
    (insert (propertize (concat fill-str
                                (mapconcat 'identity (split-string text "\n")
                                           (concat "\n" fill-str))
                                "\n")
                        'message-id id
                        'timestamp timestamp))
    (setq lingr-last-say-nick nick)))

(defun lingr-regist-room-roster (roominfo)
  (let* ((room-id (assoc-default 'id roominfo))
         (buffer (lingr-get-room-buffer room-id))
        roster)
    (dolist (key '(id name))
      (push (assoc key roominfo) roster))
    (push (cons 'members
                (loop for member across (assoc-default 'members (assoc-default 'roster roominfo))
                      collect (cons (assoc-default 'username member) member)))
          roster)
    (push (cons 'buffer buffer) roster)
    (push (cons 'unread nil) roster)
    (puthash room-id roster lingr-roster-table))
  roominfo)

(defun lingr-refresh-rooms (json)
  (loop for roominfo across (lingr-response-rooms json)
        do
        (lingr-regist-room-roster roominfo)
        (with-current-buffer (lingr-get-room-buffer (assoc-default 'id roominfo))
          (lingr-room-mode)
          (setq lingr-buffer-room-id (assoc-default 'id roominfo)
                lingr-last-say-nick nil)
          (let ((buffer-read-only nil))
            (erase-buffer)
            (goto-char (point-min))
            (loop for message across (assoc-default 'messages roominfo)
                  do
                  (lingr-insert-message message))))))

(defun lingr-update-by-event (event)
  (case (lingr-event-type event)
    (message
     (let ((message (lingr-event-message event)))
       (lingr-update-with-buffer (lingr-get-room-buffer (lingr-message-room message))
         (lingr-insert-message message))
       (lingr-update-roster-by-message message)
       (run-hook-with-args 'lingr-message-hook message)
       (list 'message (lingr-message-room message))))
    (presence
     (let ((presence (lingr-event-presence event)))
       ;; presence-event is send to only one room.
       ;; I want update that all rosters that member belongs to.
       (dolist (room-id (lingr-get-rooms-by-username (lingr-presence-username presence)))
         (unless (eq (string-equal (lingr-presence-status presence) "online")
                     (lingr-member-online-p (lingr-get-roster-member (lingr-presence-username presence) (lingr-get-roster room-id))))
           (lingr-update-with-buffer (lingr-get-room-buffer room-id)
             (let ((timestamp (lingr-presence-timestamp presence))
                   (text (lingr-presence-text presence)))
               (insert (propertize (format "%s  %s\n" text (lingr-decode-timestamp timestamp))
                                   'face 'lingr-presence-event-face)))))
         (lingr-update-roster-by-presence presence room-id))
       (run-hook-with-args (if (string-equal (lingr-presence-status presence) "online")
                               'lingr-join-hook
                             'lingr-leave-hook)
                           presence)
       (list 'presence (lingr-presence-room presence))))
    (t nil)))

(defun lingr-get-rooms-by-username (username)
  (loop for room-id being the hash-keys in lingr-roster-table using (hash-value roster)
        if (lingr-get-roster-member username roster)
        collect room-id))

(defun lingr-update-roster-by-presence (presence room-id)
  (let* ((roster (lingr-get-roster room-id))
         (member (lingr-get-roster-member (lingr-presence-username presence) roster))
         (is_online (assoc 'is_online member))
         (timestamp (assoc 'timestamp member)))
    (setcdr is_online (if (string-equal (lingr-presence-status presence) "online") t nil))
    (setcdr timestamp (lingr-presence-timestamp presence))))

(defun lingr-update-roster-by-message (message)
  (unless (string-equal (lingr-message-id message) lingr-last-say-id)
    (let* ((timestamp (lingr-message-timestamp message))
           (roster (lingr-get-roster (lingr-message-room message)))
           (unread (assoc 'unread roster)))
      (setcdr unread (cons message (cdr unread))))))

(defun lingr-update-status-buffer ()
  (let ((status-buffer (get-buffer-create lingr-status-buffer)))
    (with-current-buffer status-buffer
      (let ((buffer-read-only nil))
        (erase-buffer)
        (loop for roster being the hash-values in lingr-roster-table
              do
              (let* ((members (lingr-roster-members roster))
                     (online-members (loop for (name . member) in members
                                           if (lingr-member-online-p member)
                                           collect member))
                     (last-mes-timestamp (with-current-buffer (lingr-roster-buffer roster)
                                           (get-text-property (lingr-previous-property-pos 'message-id (point-max)) 'timestamp))))
                (insert (format "%s\nLast Message %s / %s online members\n%s\n%s\n\n"
                                (propertize (lingr-roster-name roster)
                                            'lingr-room-id (lingr-roster-id roster)
                                            'face 'lingr-status-room-face)
                                (lingr-decode-timestamp last-mes-timestamp)
                                (length online-members)
                                (mapconcat (lambda (m) (lingr-member-name m))
                                           online-members ", ")
                                (mapconcat (lambda (message)
                                             (propertize (format "%s: unread message from %s"
                                                                 (lingr-decode-timestamp (lingr-message-timestamp message))
                                                                 (lingr-message-nick message))
                                                         'face 'lingr-status-unread-face
                                                         'message-id (lingr-message-id message)))
                                           (reverse (lingr-roster-unread roster)) "\n")))))
        (unless (lingr-observe-alive)
          (insert (propertize (format "Lingr observer is Dead!!!\n%s\n"
                                      (if lingr-observe-retry-timer
                                          "Please Wait Connect Retry..."
                                        "Please execute M-x lingr-observe-revive."))
                              'face '(:foreground "Red")))))
      (setq buffer-read-only t)
      (use-local-map lingr-status-buffer-map))))

(defun lingr-status-switch-room ()
  (interactive)
  (lingr-aif (get-text-property (point) 'lingr-room-id)
      (lingr-switch-room it)))

(defun lingr-status-switch-room-other-window ()
  (interactive)
  (lingr-aif (get-text-property (point) 'lingr-room-id)
      (lingr-switch-room it t)))

(defun lingr-status-next-room ()
  (interactive)
  (lingr-aif (lingr-next-property-pos 'lingr-room-id (point))
      (goto-char it)))

(defun lingr-next-property-pos (property &optional pos)
  (let* ((current (or pos (point)))
         (next (next-single-property-change current property)))
    (if next
        (if (get-text-property next property)
            next
          (next-single-property-change next property))
      nil)))

(defun lingr-status-previous-room ()
  (interactive)
  (lingr-aif (lingr-previous-property-pos 'lingr-room-id (point))
      (goto-char it)))

(defun lingr-previous-property-pos (property &optional pos)
  (let ((current (or pos (point))))
    (if (eq current (point-min))
        nil
      (let ((prev (previous-single-property-change current property)))
        (cond
         ((null prev)
          (if (get-text-property (point-min) property)
              (point-min)
            nil))
         ((get-text-property prev property) prev)
         (t
          (let ((prev (previous-single-property-change prev property)))
            (if (null prev)
                (if (get-text-property (point-min) property)
                    (point-min)
                  nil)
              prev))))))))

(defun lingr-status-jump-message ()
  (interactive)
  (let ((mes-id (get-text-property (point) 'message-id))
        (room-id (get-text-property (lingr-previous-property-pos 'lingr-room-id (point)) 'lingr-room-id)))
    (when (and mes-id room-id)
      (pop-to-buffer (lingr-get-room-buffer room-id))
      (loop for pos = (lingr-previous-property-pos 'message-id (point-max))
            then (lingr-previous-property-pos 'message-id pos)
            while pos
            if (equal (get-text-property pos 'message-id) mes-id)
            do (progn
                 (goto-char pos)
                 (lingr-remove-unread-status mes-id room-id))
            and return pos))))

(defun lingr-room-update-icon (&optional buffer)
  (interactive)
  (with-current-buffer (or buffer (current-buffer))
    (let ((pos (point-max)))
      (while (setq pos (lingr-previous-property-pos 'need-to-update pos))
        (lingr-aif (lingr-get-icon-data (get-text-property pos 'need-to-update))
            (let ((buffer-read-only nil))
              (remove-text-properties pos (1+ pos) '(need-to-update nil))
              (put-text-property pos (1+ pos) 'display it)))))))

(defun lingr-presence-online ()
  (lingr-api-set-presence lingr-session-data "online"))

(defun lingr-presence-offline ()
  (lingr-api-set-presence lingr-session-data "offline"))

(defun lingr-room-mode ()
  "Major mode for Lingr.
Special commands:

\\{lingr-room-map}"
  (kill-all-local-variables)
  (setq major-mode 'lingr-room-mode
        mode-name "Lingr-Room"
        buffer-read-only t)
  (make-local-variable 'lingr-buffer-room-id)
  (make-local-variable 'lingr-last-say-nick)
  (use-local-map lingr-room-map))

(defun lingr-room-previous-nick ()
  (interactive)
  (lingr-aif (lingr-previous-property-pos 'nick (point))
      (goto-char it)
    (when (and lingr-auto-trigger-get-before-archive
               (not lingr-get-archives-async-buffer))
      (lingr-get-before-archive))))

(defun lingr-room-next-nick ()
  (interactive)
  (let ((pos (point)))
    (lingr-aif (lingr-next-property-pos 'nick (point))
        (goto-char it))
    (lingr-scroll-view-content (point) 'nick)
    (lingr-remove-unread-region pos (or (lingr-next-property-pos 'nick (point))
                                        (point-max)))))

(defun lingr-scroll-view-content (now-pos property)
  (let* ((next-content-pos (or (lingr-next-property-pos property now-pos) (point-max)))
         (beginning-content-lastline-pos (point))
         (content-height (save-excursion
                           (let ((h 1))
                             (while (and (eq (vertical-motion 1) 1)
                                         (not (>= (point) next-content-pos)))
                               (incf h)
                               (setq beginning-content-lastline-pos (point)))
                             h))))
    (unless (pos-visible-in-window-p beginning-content-lastline-pos)
      (recenter (if (< content-height (window-height)) (- content-height) 0)))))

(defun lingr-room-next-message ()
  (interactive)
  (lingr-aif (lingr-next-property-pos 'message-id (point))
      (progn
        (goto-char it)
        (lingr-scroll-view-content it 'message-id)
        (when lingr-buffer-room-id
          (lingr-remove-unread-status (get-text-property it 'message-id) lingr-buffer-room-id)))))

(defun lingr-room-previous-message ()
  (interactive)
  (lingr-aif (lingr-previous-property-pos 'message-id (point))
      (progn
        (goto-char it)
        (when lingr-buffer-room-id
          (lingr-remove-unread-status (get-text-property it 'message-id) lingr-buffer-room-id)))))

(defun lingr-remove-unread-status (mes-id room-id)
  (let ((unread (assoc 'unread (lingr-get-roster room-id)))
        (remove-id-list (if (listp mes-id) mes-id (list mes-id))))
    (setcdr unread (remove-if (lambda (mes) (member (lingr-message-id mes) remove-id-list)) (cdr unread))))
  (lingr-update-status-buffer))

(defun lingr-remove-unread-region (start end)
  (when lingr-buffer-room-id
    (let ((mes-id-list (loop with mes-id
                             for pos = start then (lingr-next-property-pos 'message-id pos)
                             while (and (integerp pos) (<= pos end))
                             when (setq mes-id (get-text-property pos 'message-id))
                             collect mes-id)))
      (lingr-remove-unread-status mes-id-list lingr-buffer-room-id))))

(defun lingr-show-update-summay (updates)
  (lingr-aif (delete-dups (loop for (type room) in updates
                                if (eq type 'message) collect room))
      (message "Lingr update message in %s." (mapconcat 'identity it ","))))

;;;; Interactive functions
(defun lingr-login (&optional username password)
  (interactive (list (or lingr-username (read-from-minibuffer "Username: "))
                     (or lingr-password (read-passwd "Password: "))))
  (unless username (setq username lingr-username))
  (unless password (setq password lingr-password))
  (unless (and username password)
    (error "Empty username or password."))
  (message "Lingr login...")
  (lingr-aif (lingr-api-session-create username password)
      (let* ((rooms (lingr-api-get-rooms it))
             (rooms-query (mapconcat 'identity rooms ",")))
        (when rooms
          (lingr-api-subscribe it rooms-query)
          (lingr-api-room-show it rooms-query)
          (run-hooks 'lingr-connected-hook)
          (lingr-api-observe it)
          (message "Lingr login...Done.")))))

(defun lingr-logout ()
  (interactive)
  (when lingr-session-data
    (setq lingr-logout-session-flg t)
    (let* ((rooms (lingr-api-get-rooms lingr-session-data))
           (rooms-query (mapconcat 'identity rooms ",")))
      (when rooms
        (lingr-api-unsubscribe lingr-session-data rooms-query)))
    (lingr-api-session-destroy lingr-session-data)
    (setq lingr-subscribe-counter nil
          lingr-session-data nil
          lingr-logout-session-flg nil)))

(defun lingr-say-command ()
  (interactive)
  (unless lingr-buffer-room-id
    (error "This is not Lingr Chat buffer."))
  (setq lingr-say-winconf (current-window-configuration))
  (let ((room-id lingr-buffer-room-id))
    (condition-case nil
        (progn
          (split-window (selected-window)
                        (max (round (* (window-height)
                                       (/ (- 100 lingr-say-window-height-per) 100.0)))
                             5))
          (other-window 1)
          (switch-to-buffer (get-buffer-create lingr-say-buffer))
          (make-local-variable 'lingr-buffer-room-id)
          (setq lingr-buffer-room-id room-id)
          (local-set-key (kbd "C-c C-c") 'lingr-say-execute)
          (local-set-key (kbd "C-c C-k") 'lingr-say-abort))
      (error (call-interactively 'lingr-say-command-internal)))))

(defun lingr-say-command-internal (text)
  (interactive "sLingr-Say: ")
  (if lingr-buffer-room-id
      (lingr-aif (lingr-api-say lingr-session-data lingr-buffer-room-id text)
          (progn
            (setq lingr-last-say-id (lingr-message-id (lingr-response-message it)))
            (lingr-clear-roster-unread)))
    (error "This is not Lingr Chat buffer.")))

(defun lingr-say-execute ()
  (interactive)
  (when (> (length (buffer-string)) 0)
    (lingr-say-command-internal (replace-regexp-in-string "\n+\\'" "" (buffer-string))))
  (kill-buffer (current-buffer))
  (when lingr-say-winconf
    (set-window-configuration lingr-say-winconf)))

(defun lingr-say-abort ()
  (interactive)
  (kill-buffer (current-buffer))
  (when lingr-say-winconf
    (set-window-configuration lingr-say-winconf)))

(defun lingr-switch-room (room-id &optional other-window)
  (interactive (list (completing-read "Switch Room: "
                                      (lingr-get-room-id-list)
                                      nil t)))
  (funcall (if other-window 'pop-to-buffer 'switch-to-buffer) (lingr-get-room-buffer room-id))
  (lingr-room-update-icon)
  (when lingr-clear-unread-on-visit
    (lingr-clear-roster-unread room-id)))

(defun lingr-refresh-all-room ()
  (interactive)
  (lingr-aif (lingr-get-room-id-list)
      (lingr-api-room-show lingr-session-data (mapconcat 'identity it ","))))

(defun lingr-get-before-archive (&optional limit)
  (interactive "P")
  (when lingr-buffer-room-id
    (lingr-api-get-archives lingr-session-data lingr-buffer-room-id
                            (lingr-aif (get-text-property (point-min) 'message-id)
                                it
                              (get-text-property (next-single-property-change (point-min) 'message-id) 'message-id))
                            (if (and (numberp limit) (> limit 0)) limit nil))))

(defun lingr-refresh-room ()
  (interactive)
  (when lingr-buffer-room-id
    (lingr-api-room-show lingr-session-data lingr-buffer-room-id)))

(defun lingr-clear-roster-unread (&optional room-id)
  (interactive)
  (let ((room-id (or room-id lingr-buffer-room-id)))
    (when room-id
      (let ((unread (assoc 'unread (lingr-get-roster room-id))))
        (setcdr unread nil))
      (lingr-update-status-buffer))))

(defun lingr-show-status (&optional this-buffer)
  (interactive "P")
  (lingr-update-status-buffer)
  (funcall (if this-buffer 'switch-to-buffer 'pop-to-buffer) lingr-status-buffer))

;;;; Debug Utility
(defvar lingr-debug nil)
(defvar lingr-debug-log-buffer "*Lingr Debug Log*")
(defun lingr-debug-observe-log (obj)
  (when lingr-debug
    (with-current-buffer (get-buffer-create lingr-debug-log-buffer)
      (goto-char (point-max))
      (ignore-errors
        (insert (format "%s | %s\n" (format-time-string "%x %T") obj))
        (goto-char (point-max))))))

(defun lingr-observe-revive ()
  (interactive)
  (if (and lingr-session-data
           (ignore-errors
             (lingr-api-session-verify (lingr-session-id lingr-session-data))
             t))
      (progn
        (lingr-api-observe lingr-session-data)
        (lingr-update-status-buffer))
    (call-interactively 'lingr-login)))

(provide 'lingr)
;;; lingr.el ends here
