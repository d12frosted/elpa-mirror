;;; symon-lingr.el --- A notification-based Lingr client powered by symon.el

;; Copyright (C) 2015 zk_phi

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

;; Author: zk_phi
;; URL: http://hins11.yu-yake.com/
;; Package-Version: 20150719.1342
;; Package-Commit: 056d1a473e36992ff5881e5ce6fdc331cead975f
;; Version: 0.1.1
;; Package-Requires: ((symon "1.1.2") (cl-lib "0.5"))

;;; Commentary:

;; This script provides a new symon-monitor `symon-lingr-monitor',
;; that reports number of unread Lingr messages.
;;
;; See Readme.org for more informations.

;;; Change Log:

;; 0.1.0 test release
;; 0.1.1 linkify urls in messages

;;; Code:

(require 'symon)
(require 'cl-lib)

(require 'url)                      ; url-retrieve(-synchronously)
(require 'parse-time)               ; parse-time-string
(require 'timezone)                 ; timezone-make-date-arpa-standard
(require 'json)                     ; json-read-from-string
(require 'button)                   ; make-text-button

(defconst symon-lingr-version "0.1.1")

;; + customs
;;   + core

(defgroup symon-lingr nil
  "A notification-based Lingr client."
  :group 'symon)

(defgroup symon-lingr-timeline nil
  "Timeline settings for symon-lingr.el."
  :group 'symon-lingr)

(defcustom symon-lingr-user-name nil
  "User name to login to Lingr."
  :group 'symon-lingr)

(defcustom symon-lingr-password nil
  "Password to login to Lingr."
  :group 'symon-lingr)

(defcustom symon-lingr-muted-rooms nil
  "List of room names not to subscribe."
  :group 'symon-lingr)

(defcustom symon-lingr-enable-notification t
  "When non-nil, echo new messages in the minibuffer."
  :group 'symon-lingr)

(defcustom symon-lingr-log-file nil
  "File to save `symon-lingr' logs in."
  :group 'symon-lingr)

(defcustom symon-lingr-app-key nil
  "App key to access Lingr API (optional for now)."
  :group 'symon-lingr)

(defcustom symon-lingr-link-regexp
  ;; based on `org-plain-link-re' (C) FSF
  (concat
   "\\<\\("
   (mapconcat 'regexp-quote '("http" "https" "ftp" "mailto" "file"
                              "news" "shell" "elisp" "doi" "message"
                              "file+sys" "file+emacs" "bbdb" "bibtex"
                              "docview" "gnus" "info" "irc" "mew" "mhe"
                              "rmail" "vm" "vm-imap" "wl") "\\|")
   "\\):\\([^\t\n()<>]+\\(?:([[:word:]0-9_]+)\\|\\([^[:punct:]\t\n]\\|/\\)\\)\\)")
  "A regexp that recognizes an url."
  :group 'symon-lingr-timeline)

;;   + faces

(defface symon-lingr-user-id-face
  '((((background light)) (:foreground "#7e7765" :bold t))
    (t (:foreground "#faf5ee" :bold t)))
  "Face used to highlight user IDs in Lingr timelines."
  :group 'symon-lingr-timeline)

(defface symon-lingr-nickname-face
  '((((background light)) (:foreground "#aea89a"))
    (t (:foreground "#e2c69f")))
  "Face used to highlight nicknames in Lingr timelines."
  :group 'symon-lingr-timeline)

(defface symon-lingr-time-face
  '((((background light)) (:foreground "#aea89a"))
    (t (:foreground "#e2c69f")))
  "Face used to highlight timestamps in Lingr timelines."
  :group 'symon-lingr-timeline)

(defface symon-lingr-room-header-face
  '((((background light)) (:background "#e4e3de" :foreground "#d48e2d"))
    (t (:background "#4c4c4c" :foreground "#d48e2d")))
  "Face used to highlight room header in Lingr timelines."
  :group 'symon-lingr-timeline)

;; + utilities

(defun symon-lingr--assoc-ref (k lst) (cdr (assoc k lst)))

(defun symon-lingr--plist-to-alist (plst)
  "Convert (K1 V1 K2 V2 ...) to ((K1 . V1) (K2 . V2) ...)."
  (when plst
    (cons (cons (car plst) (cadr plst))
          (symon-lingr--plist-to-alist (cddr plst)))))

(defun symon-lingr--make-button (str action &rest props)
  "Make a string button and return it. This is NOT a destructive
function unlike `make-text-button'."
  (declare (indent 1))
  (let ((str (copy-sequence str)))
    (apply 'make-text-button str 0 'action action props)
    str))

(defun symon-lingr--linkify-urls (beg end)
  "Linkify URLs in the region."
  (goto-char beg)
  (while (search-forward-regexp symon-lingr-link-regexp end t)
    (make-text-button
     (match-beginning 0) (match-end 0)
     'action (lambda (b) (browse-url (button-get b 'url)))
     'url (match-string 0))))

(defun symon-lingr--parse-time-string (str)
  "Parse and encode Lingr messages' timestamp."
  (apply 'encode-time
         (parse-time-string (timezone-make-date-arpa-standard str))))

;; + Lingr API core

(put 'lingr-error 'error-conditions '(error lingr-error))
(put 'lingr-error 'error-message "Lingr error")

(defun symon-lingr--parse-response ()
  "Read current response buffer as JSON. Return nil on parse
error."
  (save-excursion
    (goto-char 0)
    (when (search-forward "\n\n" nil t) ; skip HTTP headers
      (ignore-errors
        (let ((json-array-type 'list))
          (json-read-from-string
           (decode-coding-string (buffer-substring (point) (point-max)) 'utf-8)))))))

(defun symon-lingr--call-api (api &optional async-callback &rest params)
  "Call Lingr-API API with PARAMS, and return the parsed response
on success, or nil iff Lingr did not return a JSON. This function
may raise an error on connection failure, or signal `lingr-error'
if lingr returned an error status.

 When ASYNC-CALLBACK is non-nil, this function immediately
returns with the process buffer and ASYNC-CALLBACK is called with
the response later. ASYNC-CALLBACK can also be a pair of two
functions of the form (CALLBACK . ERRORBACK). That case,
ERRORBACK is called with a signal, which is a list of the
form (ERROR-SYMBOL DATA ...), on failure. If ERRORBACK is
omitted, errors are demoted to a simple message and never raised.

 PARAMS must be a plist of the form (\"KEY\" \"VALUE\" \"KEY\"
\"VALUE\" ...)."
  (when symon-lingr-app-key
    (setq params (cons "app_key" (cons symon-lingr-app-key params))))
  (let ((url (if (null params)
                 (concat "http://lingr.com/api/" api)
               (concat "http://lingr.com/api/" api "?"
                       (mapconcat (lambda (p) (format "%s=%s" (car p) (cdr p)))
                                  (symon-lingr--plist-to-alist params) "&"))))
        (callback (if (functionp async-callback) async-callback (car async-callback)))
        (errorback (if (functionp async-callback)
                       (lambda (e) (message "%s" (error-message-string e)))
                     (cdr async-callback))))
    (if (null async-callback)
        ;; synchronous call
        (let ((res (with-current-buffer (url-retrieve-synchronously url)
                     (symon-lingr--parse-response))))
          (if (string= (symon-lingr--assoc-ref 'status res) "error")
              (signal 'lingr-error (list (symon-lingr--assoc-ref 'detail res)))
            res))
      ;; asynchronous call
      (condition-case err
          (url-retrieve
           url
           (lambda (s cb eb)
             (cond ((null s)
                    (let ((res (symon-lingr--parse-response)))
                      (if (string= (symon-lingr--assoc-ref 'status res) "error")
                          (funcall eb `(lingr-error ,(symon-lingr--assoc-ref 'detail res)))
                        (funcall cb res))))
                   ((eq (caar s) :error)
                    (funcall eb (cl-cadar s)))
                   (t
                    (funcall eb '(error "Lingr: Unexpected redirection.")))))
           (list callback errorback))
        (error (funcall errorback err))))))

;; + account management

(defvar symon-lingr--session-id nil "The session ID.")
(defvar symon-lingr--nickname   nil "Nickname of the login user.")
(defvar symon-lingr--rooms      nil "List of room names which the login user is attending.")
(defvar symon-lingr--counter    nil "The latest `counter' value returned by the Lingr API.")

;; session/create, user/get_rooms, room/subscribe
(defun symon-lingr--login (&optional cont)
  "Login to Lingr asynchronously. If CONT is non-nil, it must be
a 0-ary function and is called after successfully logging in to
Lingr. [This function calls `session/create', `user/get_rooms',
`room/subscribe' once each.]"
  (let* ((user (or symon-lingr-user-name (read-from-minibuffer "Username: ")))
         (password (or symon-lingr-password (read-passwd "Password: ")))
         (cont (or cont (lambda () nil))))
    (message "Lingr: Logging in to Lingr ...")
    (symon-lingr--call-api
     "session/create"
     `(lambda (json)
        (setq symon-lingr--session-id (symon-lingr--assoc-ref 'session json)
              symon-lingr--nickname   (symon-lingr--assoc-ref 'nickname json))
        (symon-lingr--call-api
         "user/get_rooms"
         (lambda (json)
           (setq symon-lingr--rooms
                 (cl-remove-if (lambda (r) (member r symon-lingr-muted-rooms))
                               (symon-lingr--assoc-ref 'rooms json)))
           (symon-lingr--call-api
            "room/subscribe"
            (lambda (json)
              (setq symon-lingr--counter (symon-lingr--assoc-ref 'counter json))
              (message "Lingr: Successfully logged in as %s." ',user)
              (funcall ',cont))
            "rooms" (mapconcat 'identity symon-lingr--rooms ",")
            "session" symon-lingr--session-id))
         "session" symon-lingr--session-id))
     "user" user "password" password)))

;; session/destroy
(defun symon-lingr--logout ()
  "Logout from Lingr synchronously. [This function calls
`session/destroy' once.]"
  (if (null symon-lingr--session-id)
      (message "Lingr: Not logged in to Lingr.")
    (symon-lingr--call-api "session/destroy" nil "session" symon-lingr--session-id)
    (setq symon-lingr--session-id nil)
    (message "Lingr: Successfully logged out from Lingr.")))

;; + other Lingr API wrappers

(defun symon-lingr--choose-room ()
  "Read a room name with minibuffer."
  (cond ((null symon-lingr--session-id)
         (error "Not logged in to Lingr."))
        ((null symon-lingr--rooms)
         (error "No rooms available."))
        ((null (cdr symon-lingr--rooms))
         (car symon-lingr--rooms))
        (t
         (completing-read "Room: " symon-lingr--rooms))))

;; room/say
(defun symon-lingr-say (&optional str room)
  "Submit message STR to ROOM asynchronously. [This function
calls `room/say' once.]"
  (interactive)
  (let* ((room (or room (symon-lingr--choose-room)))
         (str (read-from-minibuffer (format "Say in %s: " room))))
    (symon-lingr--call-api
     "room/say"
     `(lambda (_)
        (message "Lingr: Successfully posted a message."))
     "session" symon-lingr--session-id "nickname" symon-lingr--nickname
     "room" room "text" str)))

;; room/get_archives
(defun symon-lingr--room-archive (room &optional until-message async-callback)
  "Return recent messages posted in ROOM before UNTIL-MESSAGE (if
specified). When ASYNC-CALLBACK is non-nil, this function returns
immediately and call ASYNC-CALLBACK with the messages
later. [This function calls either `room/show' or
`room/get_archives' once.]"
  (let ((until-id (symon-lingr--assoc-ref 'id until-message)))
    (message "Lingr: Requesting archive of room %s ..." room)
    (cond ((and async-callback until-id)
           (symon-lingr--call-api
            "room/get_archives"
            `(lambda (s)
               (funcall ',async-callback (symon-lingr--assoc-ref 'messages s)))
            "session" symon-lingr--session-id "room" room "before" until-id))
          (async-callback
           (symon-lingr--call-api
            "room/show"
            `(lambda (s)
               (funcall ',async-callback (symon-lingr--assoc-ref
                                          'messages
                                          (car (symon-lingr--assoc-ref 'rooms s)))))
            "session" symon-lingr--session-id "rooms" room))
          (t
           (let ((res
                  (if until-id
                      (symon-lingr--call-api
                       "room/get_archives" nil
                       "session" symon-lingr--session-id "room" room "before" until-id)
                    (car (symon-lingr--assoc-ref
                          'rooms
                          (symon-lingr--call-api
                           "room/show" nil
                           "session" symon-lingr--session-id "rooms" room))))))
             (symon-lingr--assoc-ref 'messages res))))))

;; event/observe
(defun symon-lingr--open-stream (consumer-fn &optional errback -silent)
  "Open a Comet stream. When a new message is arrived to the stream,
CONSUMER-FN is called with the message. -SILENT is an internal
variable and should not be used. [This function calls
`event/observe' repeatedly.]"
  (unless -silent (message "Lingr: Opening a comet stream ..."))
  (let ((buf (symon-lingr--call-api
              "event/observe"
              (cons `(lambda (json)
                       (let ((counter (symon-lingr--assoc-ref 'counter json))
                             (events (symon-lingr--assoc-ref 'events json)))
                         (when counter
                           (setq symon-lingr--counter counter))
                         (mapcar ',consumer-fn events))
                       (symon-lingr--open-stream ',consumer-fn ',errback t))
                    `(lambda (status)
                       ,(when errback `(funcall ,errback status))))
              "session" symon-lingr--session-id "counter" symon-lingr--counter)))
    (set-process-query-on-exit-flag (get-buffer-process buf) nil)))

;; + timeline rendering

(defun symon-lingr--format-timestamp (timestamp)
  "Convert ISO8601 TIMESTAMP to an user-friendly representation."
  (let* ((created-time (symon-lingr--parse-time-string timestamp))
         (diff (time-subtract (current-time) created-time))
         (secs (+ (* (car diff) 65536.0) (cadr diff))))
    (cond ((> secs 86400)              ; >= 24h
           (cl-destructuring-bind (_ __ ___ d m . ____) (decode-time created-time)
             (concat (int-to-string d) " "
                     (cl-case m
                       ((1) "Jan") ((4) "Apr") ((7) "Jul") ((10) "Oct")
                       ((2) "Feb") ((5) "May") ((8) "Aug") ((11) "Nov")
                       ((3) "Mar") ((6) "Jun") ((9) "Sep") ((12) "Dec")))))
          ((> secs 3600) (format "%dh" (/ secs 60 60))) ; >= 1h
          ((> secs 60)   (format "%dm" (/ secs 60)))    ; >= 1m
          ((> secs 1)    (format "%ds" secs))           ; >= 1s
          (t             "now"))))

(defun symon-lingr--insert-message (message)
  "Format and insert MESSAGE at point."
  (let* ((nickname (symon-lingr--assoc-ref 'nickname message))
         (id (symon-lingr--assoc-ref 'speaker_id message))
         (timestamp (symon-lingr--format-timestamp
                     (symon-lingr--assoc-ref 'timestamp message)))
         (align (- fill-column (length timestamp)))
         (text (with-temp-buffer
                 (insert (symon-lingr--assoc-ref 'text message))
                 (fill-region (point-min) (point-max))
                 (goto-char (point-min))
                 (while (progn (insert " ") (zerop (forward-line 1))))
                 (symon-lingr--linkify-urls (point-min) (point-max))
                 (buffer-string))))
    (insert (propertize id 'face 'symon-lingr-user-id-face)
            (propertize (format " (%s)" nickname) 'face 'symon-lingr-nickname-face)
            " :"
            (propertize " " 'display `(space :align-to ,align))
            (propertize timestamp 'face 'symon-lingr-time-face) "\n"
            text "\n")))

;; + the lingr client

(defvar symon-lingr--last-read-message nil)
(defvar symon-lingr--unread-messages-count 0)
(defvar symon-lingr--unread-messages    ; Map[Room, List[Msg]]
  (make-hash-table :test 'equal))

(defun symon-lingr--push-unread-message (message)
  "Mark MESSAGE as unread."
  (let* ((room (symon-lingr--assoc-ref 'room message))
         (oldval (gethash room symon-lingr--unread-messages)))
    (puthash room
             (cons (+ (or (car oldval) 0) 1) (cons message (cdr oldval)))
             symon-lingr--unread-messages)
    (cl-incf symon-lingr--unread-messages-count)))

(defun symon-lingr--pop-unread-messages (room)
  "Unmark and return all unread messages in ROOM."
  (let ((oldval (gethash room symon-lingr--unread-messages)))
    (when (and (cadr oldval)
               (or (null symon-lingr--last-read-message)
                   (symon-lingr--message< symon-lingr--last-read-message (cadr oldval))))
      (setq symon-lingr--last-read-message (cadr oldval)))
    (puthash room nil symon-lingr--unread-messages)
    (cl-decf symon-lingr--unread-messages-count (or (car oldval) 0))
    (nreverse (cdr oldval))))

;; *FIXME* POSSIBLE INTEGER OVERFLOW
;; *NOTE* THIS IMPLEMENTATION ASSUMES THAT UIDs ARE INCREASING
(defun symon-lingr--message< (m1 m2)
  "Return non-nil iff M1 is older than M2."
  (< (string-to-number (symon-lingr--assoc-ref 'id m1))
     (string-to-number (symon-lingr--assoc-ref 'id m2))))

(defun symon-lingr--load-log-file ()
  (when (and symon-lingr-log-file (file-exists-p symon-lingr-log-file))
    (with-temp-buffer
      (insert-file-contents symon-lingr-log-file)
      (goto-char (point-min))
      (setq symon-lingr--last-read-message (read (current-buffer))))))

(defun symon-lingr--save-log-file ()
  (when symon-lingr-log-file
    (with-temp-buffer
      (prin1 symon-lingr--last-read-message (current-buffer))
      (write-region (point-min) (point-max) symon-lingr-log-file))))

(defun symon-lingr--fetch-first-messages (rooms &optional cont)
  (if (null rooms)
      (when cont (funcall cont))
    (symon-lingr--room-archive
     (car rooms) nil
     `(lambda (messages)
        (dolist (message messages)
          (when (or (null symon-lingr--last-read-message)
                    (symon-lingr--message< symon-lingr--last-read-message message))
            (symon-lingr--push-unread-message message)))
        (symon-lingr--fetch-first-messages ',(cdr rooms) ',cont)))))

(defun symon-lingr--initialize ()
  (symon-lingr--load-log-file)
  (symon-lingr--login
   (lambda ()
     (setq symon-lingr--unread-messages-count 0)
     (symon-lingr--fetch-first-messages
      symon-lingr--rooms
      (lambda ()
        (symon-lingr--open-stream
         (lambda (s)
           (let ((message (symon-lingr--assoc-ref 'message s)))
             (when message
               (when symon-lingr-enable-notification
                 (message "New Lingr message in `%s': %s"
                          (symon-lingr--assoc-ref 'room message)
                          (symon-lingr--assoc-ref 'text message)))
               (symon-lingr--push-unread-message message))))
         (lambda (s)
           ;; behave as if Lingr is not available
           ;; *TODO* IMPLEMENT BETTER ERROR HANDLING (MAYBE RECONNECT ?)
           (setq symon-lingr--session-id nil))))))))

(defun symon-lingr--cleanup ()
  (symon-lingr--save-log-file)
  (with-demoted-errors
    (symon-lingr--logout)))

(defun symon-lingr-display ()
  "Display unread messages."
  (interactive)
  (let ((buf (get-buffer-create "*symon-lingr*"))
        (action (lambda (b)
                  (let* ((room (button-get b 'room))
                         (until (button-get b 'until))
                         (messages (symon-lingr--room-archive room until)))
                    (cond (messages
                           (button-put b 'until (car messages))
                           (goto-char (button-end b))
                           (dolist (message messages)
                             (insert "\n")
                             (symon-lingr--insert-message message)))
                          (t
                           (goto-char (button-start b))
                           (delete-region (button-start b) (button-end b))
                           (insert "(No more messages.)\n")))))))
    (with-current-buffer buf
      (erase-buffer)
      (dolist (room symon-lingr--rooms)
        (let ((messages (symon-lingr--pop-unread-messages room)))
          (insert (propertize
                   (concat " " room "\n") 'face 'symon-lingr-room-header-face)
                  "\n"
                  (symon-lingr--make-button "[Fetch older messages]\n"
                    action 'room room 'until (car messages)) "\n")
          (dolist (message messages)
            (symon-lingr--insert-message message)
            (insert "\n"))))
      (select-window (display-buffer buf)))))

(define-symon-monitor symon-lingr-monitor
  :index "Lingr-Unread:" :sparkline nil
  :setup (symon-lingr--initialize)
  :fetch (when symon-lingr--session-id
           symon-lingr--unread-messages-count)
  :cleanup (symon-lingr--cleanup))

;; + provide

(provide 'symon-lingr)

;;; symon-lingr.el ends here
