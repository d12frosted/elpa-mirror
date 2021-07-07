;;; circe-notifications.el --- Add desktop notifications to Circe.

;; Copyright (C) 2014 - 2017 Ruben Maher

;; Version: 1.0
;; Package-Version: 20180102.2318
;; Package-Commit: 291149ac12877bbd062da993479d3533a26862b0
;; Author: Ruben Maher <r@rkm.id.au>
;; URL: https://github.com/eqyiel/circe-notifications
;; Package-Requires: ((emacs "24.4") (circe "2.3") (alert "1.2"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Contributors:

;; Michael McCracken <michael.mccracken@gmail.com>
;; Syohei YOSHIDA <syohex@gmail.com>
;; Steve Purcell <steve@sanityinc.com>
;; Chris Barrett
;; Jay Kamat <jaygkamat@gmail.com>

;;; Code:

(require 'circe)
(require 'alert)

(defgroup circe-notifications nil
  "Add desktop notifications to Circe."
  :prefix "circe-notifications-"
  :group 'circe)

(defvar circe-notifications-emacs-focused nil
  "True if Emacs is currently focused by the window manager.")

(defvar circe-notifications-wait-list nil
  "An alist of nicks that have triggered notifications in the last
`circe-notifications-wait-for' seconds.")

(defcustom circe-notifications-alert-style 'libnotify
  "`alert' style to use.  See `alert-styles' for a list of possibilities.  You
can also define your own."
  :type 'symbol
  :group 'circe-notifications)

(defcustom circe-notifications-alert-severity 'normal
  "Severity of a notification.  Will be passed to `alert'."
  :type 'symbol
  :group 'circe-notifications)

(defcustom circe-notifications-alert-icon alert-default-icon
  "Icon to use for notifications."
  :type 'string
  :group 'circe-notifications)

(defcustom circe-notifications-notify-function nil
  "If you can't get the level of customization you want with `alert', set this
to your own notification function.  Will be called with three arguments: NICK,
BODY and CHANNEL.  Leave nil to use the default."
  :type 'function
  :group 'circe-notifications)

(defcustom circe-notifications-wait-for 90
  "The number of seconds to wait before allowing some nick in
`circe-notifications-wait-list' to trigger a notification again."
  :type 'integer
  :group 'circe-notifications)

(defcustom circe-notifications-watch-strings nil
  "A list of strings which can trigger a notification.  You don't need to put
your nick here, it is added automagically by
`circe-notifications-nicks-on-all-networks' when it checks the values in
`circe-network-options'."
  :type '(repeat string)
  :group 'circe-notifications)

(defcustom circe-notifications-check-window-focus t
  "If true, disable notifications for visible buffers if Emacs is currently
focused by the window manager."
  :type 'boolean
  :group 'circe-notifications)

(defun circe-notifications-PRIVMSG (nick userhost _command target text)
  (when (circe-notifications-should-notify nick userhost target text)
    (circe-notifications-notify nick text target)))

(defun circe-notifications-JOIN (nick userhost _command channel
                                      &optional accountname realname)
  (when (circe-notifications-should-notify nick userhost channel "")
    (circe-notifications-notify nick (concat "/JOIN " channel) channel)))

(defun circe-notifications-QUIT (nick userhost _command
                                      &optional channel reason)
  (when (circe-notifications-should-notify
         nick userhost (or channel "") (or reason ""))
    (circe-notifications-notify nick "/QUIT" (or channel ""))))

(defun circe-notifications-PART (nick userhost _command channel
                                      &optional reason)
  (when (circe-notifications-should-notify nick userhost channel (or reason ""))
    (circe-notifications-notify
     nick (concat "/PART (" channel ")") (or channel ""))))

(defun circe-notifications-should-notify (nick userhost channel body)
  "If NICK is not in either `circe-ignore-list' or `circe-fool-list' (only
applicable if `lui-fools-hidden-p'), CHANNEL is either in `tracking-buffers'
\(i.e., not currently visible) or Emacs is not currently focused by the window
manager (detected if `circe-notifications-check-window-focus' is true), NICK has
not triggered a notification in the last `circe-notifications-wait-for' seconds
and NICK matches any of `circe-notifications-watch-strings', show a desktop
notification."
  (unless (cond ((circe--ignored-p nick userhost body))
                ((and (circe--fool-p nick userhost body)
                      (lui-fools-hidden-p))))
    ;; Checking `tracking-buffers' has the benefit of excluding
    ;; `tracking-ignored-buffers'.  Also if a channel is in `tracking-buffers',
    ;; it is not currently focused by Emacs.
    (when (cond ((or (member channel tracking-buffers) ;; message to a channel
                     (member nick tracking-buffers))) ;; private message
                ((and circe-notifications-check-window-focus
                      (not circe-notifications-emacs-focused))))
      (when (circe-notifications-not-getting-spammed-by nick)
        (when (catch 'return
                (dolist (n circe-notifications-watch-strings)
                  (when (or (string-match n nick)
                            (string-match n body)
                            (string-match n channel))
                    (throw 'return t))))
          (progn
            (if (assoc nick circe-notifications-wait-list)
                (setf (cdr (assoc nick circe-notifications-wait-list))
                      (float-time))
              (setq circe-notifications-wait-list
                    (append circe-notifications-wait-list
                            (list (cons nick (float-time))))))
            t))))))

(defun circe-notifications-notify (nick body channel)
  "Show a desktop notification from NICK with BODY."
  (if (and circe-notifications-notify-function
           (functionp circe-notifications-notify-function))
      (funcall circe-notifications-notify-function
               nick body channel)
    (alert
     body
     :severity circe-notifications-alert-severity
     :title nick
     :icon circe-notifications-alert-icon
     :style circe-notifications-alert-style)))

(defun circe-notifications-not-getting-spammed-by (nick)
  "Return an alist with NICKs that have triggered notifications in the last
`circe-notifications-wait-for' seconds, or nil if it has been less than
`circe-notifications-wait-for' seconds since the last notification from NICK."
  (if (assoc nick circe-notifications-wait-list)
      (circe-notifications-wait-a-bit nick) t))

(defun circe-notifications-wait-a-bit (nick)
  "Has it has been more than `circe-notifications-wait-for' seconds since
the last message from NICK?"
  (let* ((last-time (assoc-default
                     nick
                     circe-notifications-wait-list
                     (lambda (x y)
                       (string-equal y x))))
         (seconds-since (- (float-time) last-time)))
    (when (< circe-notifications-wait-for seconds-since)
      (setf (cdr (assoc nick circe-notifications-wait-list)) (float-time))
      t)))

(defun circe-notifications-nicks-on-all-networks ()
  "Get a list of all nicks in use according to `circe-network-options'."
  (remove nil (delete-dups (mapcar (lambda (opt)
                                     (plist-get (cdr opt) :nick))
                                   circe-network-options))))

(defun circe-notifications-focus-in-hook ()
  (setq circe-notifications-emacs-focused t))

(defun circe-notifications-focus-out-hook ()
  (setq circe-notifications-emacs-focused nil))

;;;###autoload
(defun enable-circe-notifications ()
  "Turn on notifications."
  (interactive)
  (setq circe-notifications-watch-strings
        (remove nil (delete-dups (append circe-notifications-watch-strings
                (circe-notifications-nicks-on-all-networks)
                lui-highlight-keywords))))
  (advice-add 'circe-display-PRIVMSG :after 'circe-notifications-PRIVMSG)
  (advice-add 'circe-display-channel-quit :after 'circe-notifications-QUIT)
  (advice-add 'circe-display-JOIN :after 'circe-notifications-JOIN)
  (advice-add 'circe-display-PART :after 'circe-notifications-PART)
  (add-hook 'focus-in-hook 'circe-notifications-focus-in-hook)
  (add-hook 'focus-out-hook 'circe-notifications-focus-out-hook)
  ;; If alert-user-configuration is nil, the :style keyword is ignored.
  ;; Workaround for now is just to add a dummy rule that does nothing.
  ;; https://github.com/jwiegley/alert/issues/30
  (unless (append alert-user-configuration
                  alert-internal-configuration)
    (alert-add-rule :continue t)))

(defun disable-circe-notifications ()
  "Turn off notifications."
  (interactive)
  (setq circe-notifications-wait-list nil
        circe-notifications-watch-strings nil)
  (advice-remove 'circe-display-PRIVMSG 'circe-notifications-PRIVMSG)
  (advice-remove 'circe-display-channel-quit 'circe-notifications-QUIT)
  (advice-remove 'circe-display-JOIN 'circe-notifications-JOIN)
  (advice-remove 'circe-display-PART 'circe-notifications-PART)
  (remove-hook 'focus-in-hook 'circe-notifications-focus-in-hook)
  (remove-hook 'focus-out-hook 'circe-notifications-focus-out-hook))

(provide 'circe-notifications)
;;; circe-notifications.el ends here
