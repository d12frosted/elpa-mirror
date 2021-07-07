;;; gnus-desktop-notify.el --- Gnus Desktop Notification global minor mode  -*- lexical-binding: t -*-

;; Author: Yuri D'Elia <wavexx AT thregr.org>
;; Contributors: Philipp Haselwarter <philipp.haselwarter AT gmx.de>
;;               Basil L. Contovounesios <contovob AT tcd.ie>
;; Version: 1.4
;; Package-Version: 20180623.1538
;; Package-Commit: b438feb59136621a8ab979f0e2784f7002398d06
;; URL: http://www.thregr.org/~wavexx/software/gnus-desktop-notify.el/
;; GIT: git://src.thregr.org/gnus-desktop-notify.el/
;; Package-Requires: ((gnus "1.0"))
;; Package-Suggests: ((alert "1.0"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Change Log:

;; 1.4:
;; * Use `alert' package by default if available (`gnus-desktop-notify-alert').
;;
;; 1.3:
;; * Use `notifications' in emacs 24 (if available) by default (new function
;;   `gnus-desktop-notify-dbus').
;; * Renamed `gnus-desktop-notify-send' to `gnus-desktop-notify-behavior'.
;; * `gnus-desktop-notify-behavior' is now consistent across all notification
;;   functions (exec/send/dbus).
;;
;; 1.2:
;; * Collapse group names by default (see
;;   `gnus-desktop-notify-uncollapsed-levels').

;;; Commentary:

;; Desktop notification integration in Gnus!? Ohh goody!
;;
;; ``gnus-desktop-notify.el`` provides a simple mechanism to notify the user
;; when new messages are received. For basic usage, to be used in conjunction
;; with `gnus-daemon', put the following:
;;
;; (require 'gnus-desktop-notify)
;; (gnus-desktop-notify-mode)
;; (gnus-demon-add-scanmail)
;;
;; into your ``.gnus`` file. The default is to use `alert' if available, which
;; works on every operating system and allows the user to customize the
;; notification through Emacs. See https://github.com/jwiegley/alert#for-users
;; for further info. If not available, the `notifications' library (part of
;; Emacs >= 24) is used, so no external dependencies are required. With Emacs
;; <= 23 instead the generic ``notify-send`` program is used, which (in Debian
;; or Ubuntu) is available in the ``libnotify-bin`` package.
;;
;; You can also call any program directly by changing the
;; `gnus-desktop-notify-exec-program' variable, or change the behavior entirely
;; by setting a different `gnus-desktop-notify-function' function.
;;
;; By default, all groups are notified when new messages are received. You can
;; exclude a single group by setting the `group-notify' group parameter to `t'.
;; You can also selectively monitor groups instead by changing the
;; `gnus-desktop-notify-groups' variable to `gnus-desktop-notify-explicit' and
;; then manually selecting which groups to include. Press 'G c' in the group
;; buffer to customize group parameters interactively.
;;
;; The behavior of the notification can be tuned by changing the
;; `gnus-desktop-notify-behavior' variable.
;;
;; See the `gnus-desktop-notify' customization group for more details.
;;
;; Feel free to send suggestions and patches to wavexx AT thregr.org

;;; Code:

(require 'format-spec)
(require 'gnus-group)

(unless (require 'alert nil t)
  (require 'notifications nil t))

(declare-function alert "alert")
(declare-function notifications-notify "notifications")

;;; Custom variables

(defgroup gnus-desktop-notify nil
  "Gnus external notification framework."
  :group 'gnus)

(defcustom gnus-desktop-notify-function
  (cond ((featurep 'alert)         'gnus-desktop-notify-alert)
        ((featurep 'notifications) 'gnus-desktop-notify-dbus)
        (t                         'gnus-desktop-notify-send))
  "Notification backend used when a group receives new messages.
The backend is passed the notification content as a single,
potentially multi-line string argument.

The default is to use `gnus-desktop-notify-alert' if the `alert'
package is available, `gnus-desktop-notify-dbus' on Emacs >= 24,
or fallback to the generic `gnus-desktop-notify-send' otherwise.

The following functions are available (whose documentation see):

`gnus-desktop-notify-alert': Use the `alert' library.
`gnus-desktop-notify-dbus':  Use the `notifications' library.
`gnus-desktop-notify-send':  Call the `notify-send' program.
`gnus-desktop-notify-exec':  Call a customizable program."
  :type 'function)

(defcustom gnus-desktop-notify-exec-program "xmessage"
  "Executable called by the `gnus-desktop-notify-exec' function.
Each argument will be formatted according to
`gnus-desktop-notify-format'."
  :type 'file)

(defcustom gnus-desktop-notify-send-program "notify-send"
  "Path to the `notify-send' executable.
This is usually bundled as part of libnotify's utilities."
  :type 'file)

(defcustom gnus-desktop-notify-send-switches
  '("-i" "/usr/share/icons/gnome/32x32/actions/mail_new.png")
  "List of strings to pass as extra options to `notify-send'.
See `gnus-desktop-notify-send-program'."
  :type '(repeat (string :tag "Argument")))

(defcustom gnus-desktop-notify-behavior 'gnus-desktop-notify-multi
  "Desktop notification aggregation behavior.

Can be either:
`gnus-desktop-notify-single': Display a separate notification per
                              gnus group.
`gnus-desktop-notify-multi':  Display a multi-line notification
                              for all groups at once."
  :type '(choice (const :tag "One per group" gnus-desktop-notify-single)
                 (const :tag "All-in-one"    gnus-desktop-notify-multi)))

(defcustom gnus-desktop-notify-send-subject "New mail"
  "Text used in the notification subject when new messages are received.
Depending on your notification agent, some HTML formatting may be
supported (awesome and KDE are known to work)."
  :type 'string)

(defcustom gnus-desktop-notify-format "%n:%G"
  "Format used to generate the notification text.
When using notifications, some agents may support HTML
formatting (awesome and KDE are known to work).

%n    Number of new messages in the group
%G    Group name"
  :type 'string)

(defcustom gnus-desktop-notify-uncollapsed-levels gnus-group-uncollapsed-levels
  "Number of group name elements to preserve when collapsing.
This variable is similar to `gnus-group-uncollapsed-levels'
\(which see) and comes into effect when shortening group names
for display.

Value can be `gnus-group-uncollapsed-levels', an integer or nil
to deactivate shortening completely."
  :type `(choice (const :tag "Standard `gnus-group-uncollapsed-levels'"
                        ,gnus-group-uncollapsed-levels)
                 (const :tag "nil (deactivate feature)" nil)
                 integer))

(defcustom gnus-desktop-notify-groups 'gnus-desktop-notify-all-except
  "Determine which gnus groups to monitor.

Can be either:
`gnus-desktop-notify-all-except': Monitor all groups by default
                                  except excluded ones.
`gnus-desktop-notify-explicit':   Monitor only specified groups.

Groups can be included or excluded by setting the `group-notify'
group or topic parameter to t or nil, respectively. Group
parameters can be set collectively in the `gnus-parameters'
variable or per group in the group buffer. When point is over the
desired group, `G c' and `G p' give interactive and programmatic
interfaces to group parameter customization, respectively."
  :type '(choice (const :tag "All except"     gnus-desktop-notify-all-except)
                 (const :tag "Only specified" gnus-desktop-notify-explicit)))

;;; Group parameters

(gnus-define-group-parameter
  group-notify
   :type bool
   :parameter-type '(const :tag "Include/exclude this group from
the notification of new messages (depending on the value of
`gnus-desktop-notify-groups')." t))

;;; Internals

(defvar gnus-desktop-notify--counts ()
  "Map Gnus group names to their total number of articles.")

(defun gnus-desktop-notify--read-count (group)
  "Return read count for gnus GROUP."
  (let* ((range (gnus-range-normalize (gnus-info-read group)))
         (count (car (last range))))
    (or (cdr-safe count) count)))

(defun gnus-desktop-notify--short-group-name (group)
  "Collapse GROUP name.
See `gnus-desktop-notify-uncollapsed-levels' for ways to control
collapsing."
  (if gnus-desktop-notify-uncollapsed-levels
      (gnus-short-group-name group gnus-desktop-notify-uncollapsed-levels)
    group))

(defun gnus-desktop-notify--format-1 (group)
  "Convert GROUP to its printed representation.
GROUP should have the form (NAME . COUNT), where NAME is the
group name to display and COUNT is the corresponding number of
articles."
  (let ((name  (url-insert-entities-in-string (car group)))
        (count (cdr group)))
    (format-spec gnus-desktop-notify-format
                 (format-spec-make ?n count
                                   ?G name))))

(defun gnus-desktop-notify--format-n (groups)
  "Return a list of the printed representations of GROUPS.

GROUPS should be a list of cons cells accepted by
`gnus-desktop-notify--format-1', which see.

Depending on the value of `gnus-desktop-notify-behavior', the
returned list will comprise either a single multiline string or
multiple uniline strings."
  (mapcar (lambda (body) (mapconcat #'identity body "\n"))
          ;; Iterate over the groups either individually or as a whole
          (let ((bodies (mapcar #'gnus-desktop-notify--format-1 groups)))
            (cond ((eq gnus-desktop-notify-behavior 'gnus-desktop-notify-single)
                   (mapcar #'list bodies))
                  ((eq gnus-desktop-notify-behavior 'gnus-desktop-notify-multi)
                   `(,bodies))))))

(defun gnus-desktop-notify-check ()
  "Check all groups for and notify of new articles."
  (interactive)
  (let ((updated-groups ()))
    (dolist (group gnus-newsrc-alist)
      (let* ((name   (gnus-info-group group))
             (read   (gnus-desktop-notify--read-count group))
             (unread (gnus-group-unread name)))
        (when (and (numberp read) (numberp unread))
          (let* ((count     (+ read unread))
                 (old-count (lax-plist-get gnus-desktop-notify--counts name))
                 (delta     (- count (or old-count count)))
                 (notify    (gnus-group-find-parameter name 'group-notify)))
            (when (eq gnus-desktop-notify-groups
                      (if notify
                          'gnus-desktop-notify-explicit
                        'gnus-desktop-notify-all-except))
              (setq gnus-desktop-notify--counts
                    (lax-plist-put gnus-desktop-notify--counts name count))
              (when (and (> unread 0) (> delta 0))
                (push (cons (gnus-desktop-notify--short-group-name name) delta)
                      updated-groups)))))))
    (when (and updated-groups (not (called-interactively-p 'any)))
      (mapc gnus-desktop-notify-function
            (gnus-desktop-notify--format-n updated-groups)))))

(defun gnus-desktop-notify--shell-command (&rest args)
  "Execute ARGS as a synchronous shell command without I/O."
  (call-process-shell-command
   (mapconcat #'shell-quote-argument args " ") nil 0 nil))

;;; Notification backends

(defun gnus-desktop-notify-exec (body)
  "Invoke `gnus-desktop-notify-exec-program' with BODY."
  (funcall #'gnus-desktop-notify--shell-command
           gnus-desktop-notify-exec-program body))

(defun gnus-desktop-notify-send (body)
  "Invoke the configured `notify-send' program with BODY.
See `gnus-desktop-notify-send-program' and
`gnus-desktop-notify-send-switches' for configuration options."
  (apply #'gnus-desktop-notify--shell-command
         `(,gnus-desktop-notify-send-program
           ,@gnus-desktop-notify-send-switches
           "--"
           ,gnus-desktop-notify-send-subject
           ,body)))

(defun gnus-desktop-notify-dbus (body)
  "Generate a notification with BODY using `notifications'."
  (notifications-notify :title gnus-desktop-notify-send-subject :body body))

(defun gnus-desktop-notify-alert (body)
  "Generate a notification with BODY using `alert'."
  (alert body :title gnus-desktop-notify-send-subject))

;;; Minor mode

;;;###autoload
(define-minor-mode gnus-desktop-notify-mode
  "Gnus Desktop Notification mode uses libnotify's 'notify-send'
program to generate popup messages or call external executables
whenever a group receives new messages through gnus-demon (see
`gnus-demon-add-handler').

  You can actually call any program by changing the
`gnus-desktop-notify-exec-program' variable, or change the
behavior entirely by setting a different
`gnus-desktop-notify-function' function.

  See the `gnus-desktop-notify' customization group for more
details."
  :init-value nil
  :group 'gnus-desktop-notify
  :require 'gnus
  :global t
  (cond
   (gnus-desktop-notify-mode
    (add-hook 'gnus-after-getting-new-news-hook #'gnus-desktop-notify-check)
    (add-hook 'gnus-started-hook #'gnus-desktop-notify-check))
   (t
    (remove-hook 'gnus-after-getting-new-news-hook #'gnus-desktop-notify-check)
    (remove-hook 'gnus-started-hook #'gnus-desktop-notify-check))))

(provide 'gnus-desktop-notify)
;;; gnus-desktop-notify.el ends here
