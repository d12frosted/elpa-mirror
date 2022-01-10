;;; rcirc-alertify.el --- Cross platform notifications for rcirc

;; Copyright (C) 2014 Fabián Ezequiel Gallina

;; Author: Fabián Ezequiel Gallina <fgallina@gnu.org>
;; Keywords: comm, convenience
;; Package-Version: 20140407.119
;; Package-Commit: ea5cafc55893f375eccbe013d12dbaa94bf6e259
;; Version: 0.1
;; Package-Requires: ((alert "20140406.1353"))

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

;; This is a notification system for rcirc that uses jwiegley's
;; `alert' for sending notifications transparently across platforms.
;; It was born out of the frustrations caused by the rcirc-notify.el
;; non-maintenance plus the need of tight integration with rcirc
;; existing mechanisms such as `rcirc-keywords' and
;; `rcirc-ignore-list'.

;; Three types of notifications are provided: keywords, nickname
;; mentions and private messages.  Each have a severity setting called
;; `rcirc-alertify-keywords-severity' `rcirc-alertify-me-severity' and
;; `rcirc-alertify-privmsg-severity' respectively.

;; Event flooding is prevented with the
;; `rcirc-alertify-nickname-timeout' variable which is the time in
;; seconds for which notifications will be ignored in case same events
;; are happening for a given user.

;; If keywords notifications are not desired, they can be easily
;; deactivated by toggling `rcirc-alertify-keywords-p'.

;; Finally, if you are a new user of alert.el, you might need to set
;; your preferred notifier, here is an example config for libnotify:

;; (setq alert-default-style 'libnotify)

;;; Installation:

;; The recommended installation method is using `package-install'.
;; After that's done, just add this to your .emacs:

;; (rcirc-alertify-enable)

;; If you go the hard way, you need a copy of alert.el and add both
;; files to your `load-path' and require rcirc-alertify.

;;; Code:
(require 'alert)
(require 'rcirc)


(defgroup rcirc-alertify nil
  "Cross platform notifications for rcirc"
  :group 'rcirc)

(defvar rcirc-alertify--timeout-alist nil
  "Alist of nicknames and last notification timestamps.
Used to prevent notification flooding from the same person, the
cdr of a key is a cons where the first element is the event
type (:keyword, :me, :privmsg) and the cdr is the timestamp.")

(defun rcirc-alertify--severities ()
  "A mapping of alert severities."
  '(choice (const :tag "Urgent" urgent)
           (const :tag "High" high)
           (const :tag "Moderate" moderate)
           (const :tag "Normal" normal)
           (const :tag "Low" low)
           (const :tag "Trivial" trivial)))

(defcustom rcirc-alertify-nickname-timeout 60
  "Time in seconds new events for a nickname will be ignored.
This is used to prevent flooding."
  :group 'rcirc-alertify
  :type 'integer)

(defcustom rcirc-alertify-keywords-p t
  "When non-nil send notification for keywords.
Keywords are the one listed in the `rcirc-keywords' variable."
  :group 'rcirc-alertify
  :type 'boolean)

(defcustom rcirc-alertify-keywords-severity 'low
  "Severity for keyword notifications."
  :group 'rcirc-alertify
  :type (rcirc-alertify--severities))

(defcustom rcirc-alertify-me-severity 'normal
  "Severity for nickname mention notifications."
  :group 'rcirc-alertify
  :type (rcirc-alertify--severities))

(defcustom rcirc-alertify-privmsg-severity 'high
  "Severity for private message notifications."
  :group 'rcirc-alertify
  :type (rcirc-alertify--severities))

(defun rcirc-alertify-p (proc sender response target text event)
  "Return non-nil if notification should be sent.
PROC, SENDER, RESPONSE, TARGET, TEXT are inherited from
`rcirc-alertify-nickname-timeout'.  Arguments RESPONSE and TEXT
are not used for now.  Argument EVENT is the event type and can
be any of the following keywords: :keyword, :me, :privmsg.  This
function is intended to be used as the last predicate of all
checks as it populates `rcirc-alertify--timeout-alist', see
`rcirc-alertify-keywords' for an example."
  (setq sender (substring-no-properties sender))
  (when (and
         ;; Check this is not an ignored nick
         (not (member sender rcirc-ignore-list))
         ;; Check that the buffer triggering the event is not visible.
         (not (member (rcirc-get-buffer proc target)
                      (rcirc-visible-buffers)))
         ;; Check you are not talking to yourself
         (not (string= (rcirc-nick proc) sender))
         ;; Ignore server messages
         (not (string= (rcirc-server-name proc) sender))
         ;; Force a target, there should be always one, if not this
         ;; event may have happened on an internal buffer.
         target)
    (let* ((now (float-time (current-time)))
           (data (assoc sender rcirc-alertify--timeout-alist))
           (pair (cdr data))
           (last-event (car pair))
           (last-time (cdr pair)))
      (if (not data)
          (push (cons sender (cons event now))
                rcirc-alertify--timeout-alist)
        (setcdr data (cons event now))
        ;; Send an alert if the sender triggered a different event
        ;; this time or if the current event (that is the same type as
        ;; previous) is happening after the specified timeout.
        (or (not (eq last-event event))
            (> (- now last-time) rcirc-alertify-nickname-timeout))))))

(defun rcirc-alertify-keywords (proc sender response target text)
  "Notify keywords.
This function is called from the `rcirc-print-functions' so
arguments PROC, SENDER, RESPONSE, TARGET and TEXT are inherited
from that.  Returns non-nil if a notification has been sent."
  (when (and rcirc-alertify-keywords-p
             rcirc-keywords
             (string-match
              (concat "\\<" (regexp-opt rcirc-keywords) "\\>") text)
             (rcirc-alertify-p proc sender response target text :keywords))
    (alert
     (format "%s mentioned the keyword %s in %s"
             sender (match-string-no-properties 0 text) target)
     :title "rcirc"
     :severity rcirc-alertify-keywords-severity)))

(defun rcirc-alertify-me (proc sender response target text)
  "Notify mentions.
This function is called from the `rcirc-print-functions' so
arguments PROC, SENDER, RESPONSE, TARGET and TEXT are inherited
from that.  Returns non-nil if a notification has been sent."
  (when (and (string-match (rcirc-nick proc) text)
             (rcirc-alertify-p proc sender response target text :me))
    (alert
     (format "%s mentioned you in %s" sender target)
     :title "rcirc"
     :severity rcirc-alertify-me-severity)
    t))

(defun rcirc-alertify-privmsg (proc sender response target text)
  "Alert private messages.
This function is intended to be added into the
`rcirc-print-functions' so arguments PROC, SENDER, RESPONSE,
TARGET and TEXT are inherited from that.  Returns non-nil if a
notification has been sent."
  (when (and (string= response "PRIVMSG")
             (not (string= sender (rcirc-nick proc)))
             (not (rcirc-channel-p target))
             (rcirc-alertify-p proc sender response target text :privmsg))
    (alert
     (format "%s sent you a private message" sender)
     :title "rcirc"
     :severity rcirc-alertify-privmsg-severity)
    t))

(defun rcirc-alertify (proc sender response target text)
  "Execute notification functions until one return non-nil.
Executes `rcirc-alertify-privmsg', `rcirc-alertify-me' and
`rcirc-alertify-keywords' in that order.  The first one to return
non-nil wins.  This function is called from the
`rcirc-print-functions' so arguments PROC, SENDER, RESPONSE,
TARGET and TEXT are inherited from that.  Returns non-nil if a
notification has been sent."
  (or (rcirc-alertify-privmsg proc sender response target text)
      (rcirc-alertify-me proc sender response target text)
      (rcirc-alertify-keywords proc sender response target text)))

;;;###autoload
(defun rcirc-alertify-enable ()
  "Enable alerts for rcirc."
  (add-hook 'rcirc-print-functions #'rcirc-alertify))

(defun rcirc-alertify-disable ()
  "Disable alerts for rcirc."
  (remove-hook 'rcirc-print-functions #'rcirc-alertify))


(provide 'rcirc-alertify)
;;; rcirc-alertify.el ends here
