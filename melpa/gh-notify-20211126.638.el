;;; gh-notify.el --- A veneer for Magit/Forge GitHub notifications            -*- lexical-binding: t -*-

;; Copyright (C) 2021 bas@anti.computer
;;               2020 xristos@sdf.org
;;
;; All rights reserved

;; Modified: 2021-11-26
;; Version: 0.1.0
;; Package-Version: 20211126.638
;; Package-Commit: aa4d8bc0c56366d437e7c126e7eedc5938109342
;; Author: Bas Alberts <bas@anti.computer>
;;         xristos <xristos@sdf.org>
;;
;; Maintainer: Bas Alberts <bas@anti.computer>
;; URL: https://github.com/anticomputer/gh-notify
;; Package-Requires: ((emacs "27.1") (magit "3.0.0") (forge "0.2.0"))
;; Keywords: comm

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;;   * Redistributions of source code must retain the above copyright
;;     notice, this list of conditions and the following disclaimer.
;;
;;   * Redistributions in binary form must reproduce the above
;;     copyright notice, this list of conditions and the following
;;     disclaimer in the documentation and/or other materials
;;     provided with the distribution.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;; POSSIBILITY OF SUCH DAMAGE.

;; This project includes code modified from:
;;
;; Magit/Forge (https://github.com/magit/forge)
;;   Copyright (C) 2018-2021  Jonas Bernoulli
;;
;; Magit/Forge modifications are subject to the following license terms:
;;
;; Forge is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; Forge is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Forge.  If not, see http://www.gnu.org/licenses.

;; This project includes code modified from:
;;
;; chrome.el (https://github.com/anticomputer/chrome.el)
;;   Copyright (C) 2020 xristos@sdf.org
;;                 2020 bas@anti.computer
;;
;; More specifically it repurposes the text filtering and rendering engine
;; developed by Xristos <xristos@sdf.org> for chrome.el.
;;
;; All his original author credits and licensing terms apply.

;;; Commentary:

;; This is gh-notify: A thin ui veneer on top of Magit/Forge porcelain for juggling
;; large amounts of GitHub notifications.
;;
;; It provides a more efficient interface to the Magit/Forge notification database
;; suited for rapid searching/narrow/filter based workflows.  It also improves on
;; Magit/Forge's default notification fetching behavior by introducing support for
;; incremental notification fetching, which is a must for interactive notification
;; queue workflow iterations.
;;
;; This code should be plug and play if you already have Magit/Forge set up and have
;; fetched notifications for your GitHub account at least once.  If not, please see:
;; https://magit.vc/manual/forge.html to get started.
;;
;; Note: this requires the latest versions of magit/forge to be installed from melpa
;; as per Feb 18, 2021.
;;
;;; Usage:
;;
;; M-x gh-notify
;;
;; Please see README.org for documentation.

;;; Code:

(require 'magit)
(require 'forge)
(require 'iso8601)

(require 'url)
(require 'json)
(require 'subr-x)
(require 'cl-lib)
(require 'auth-source)
(require 'url-util)

(defgroup gh-notify nil
  "GitHub magit/forge notifications control."
  :group 'comm)

(defface gh-notify-notification-filter-face
  '((((class color) (background dark))  (:foreground "#aaffaa"))
    (((class color) (background light)) (:foreground "#5faf00")))
  "Face used to display current filter."
  :group 'gh-notify)

(defface gh-notify-notification-marked-face
  '((((class color) (background dark))  (:foreground "#ffaaff"))
    (((class color) (background light)) (:foreground "#d70008")))
  "Marked face."
  :group 'gh-notify)

(defface gh-notify-notification-unread-face
  '((((class color) (background dark))  (:weight ultra-bold))
    (((class color) (background light)) (:weight ultra-bold)))
  "Unread face."
  :group 'gh-notify)

(defface gh-notify-notification-repo-face
  '((((class color) (background dark))  (:weight ultra-light))
    (((class color) (background light)) (:weight ultra-light)))
  "Repo face."
  :group 'gh-notify)

(defface gh-notify-notification-reason-face
  '((((class color) (background dark))  (:foreground "#aaffaa"))
    (((class color) (background light)) (:background "#5faf00")))
  "Reason face."
  :group 'gh-notify)

(defface gh-notify-notification-issue-face
  '((((class color) (background dark))  (:foreground "#ff9999"))
    (((class color) (background light)) (:background "#ff9999")))
  "Issue face."
  :group 'gh-notify)

(defface gh-notify-notification-pr-face
  '((((class color) (background dark))  (:foreground "#ffff99"))
    (((class color) (background light)) (:background "#ffff99")))
  "PR face."
  :group 'gh-notify)

(defvar gh-notify-render-function #'gh-notify-render-notification
  "Function that renders a notification into a string for display.

The function must accept one argument, an gh-notify-notification instance,
and return a string that must not span more than one line.")

(defvar gh-notify-limit-function #'gh-notify-limit-notification
  "Function that limits visible notifications based on certain criteria.

Function must accept one argument, an gh-notify-notification instance, and
return t if the notification is included in the limit, nil otherwise.")

(defvar gh-notify-filter-function #'gh-notify-filter-notification
  "Function that filters visible notifications based on a user-typed regexp.

Function must accept one argument, gh-notify-notification instance, and
return t if the notification passes the filter, nil otherwise.  The current
filter can be retrieved by calling `gh-notify-active-filter'.")

(defvar gh-notify-show-timing t
  "Measure and display elapsed time after every operation.

This can be toggled by `gh-notify-toggle-timing'.")

(defvar gh-notify-show-state nil
  "Show open/closed/merged state by default.

This requires an additional forge db query for every notification and makes
inits/refreshes SIGNIFICANTLY less snappy.  Disabled by default and recommended
to use `gh-notify-display-state' via a keybinding instead.")

(defvar gh-notify-default-view :title
  "Show notification titles when equal to :title, URLs otherwise.
This can be toggled by `gh-notify-toggle-url-view'.")

(defvar gh-notify-reason-limit :all
  "Default display limit.")

(defvar gh-notify-default-repo-limit '()
  "List of default repo limits.

Limits are in the form \"owner/repo\".

This will be your repo limit reset state to the exclusion of anything else.
and should only be used if you have a lot of permanent-noise from repositories
you do not care about for the long term.

Most people will want to keep this list empty and use
`gh-notify-exclude-repo-limit' instead.")

(defvar gh-notify-exclude-repo-limit '()
  "List of repos to exclude from notifications display.

Repos are in the form \"owner/repo\".

Use this to muzzle specific repos that you want to silence across sessions.")

(defvar gh-notify-smokescreen-path "~/.gh-notify-smokescreen"
  "The default path for the magit `forge-visit' smokescreen repo.")

(defvar gh-notify-redraw-on-visit t
  "Automatically redraw notifications on `forge-visit'.

If you prefer to manually refresh notification display state after visits, set
this to nil.")

(cl-defstruct (gh-notify-notification
               (:constructor gh-notify-notification-create)
               (:copier nil))
  (forge-obj nil :read-only nil)
  (id nil :read-only t)
  (type nil :read-only t)
  (topic nil :read-only t)
  (repo-id nil :read-only t)
  (repo nil :read-only t)
  (unread nil :read-only t)
  (updated nil :read-only t)
  (ts nil :read-only t)
  (date nil :read-only t)
  (reason nil :read-only t)
  (url nil :read-only t)
  (title nil :read-only t)
  (state nil :read-only t)
  is-marked
  line)

;;;
;;; Internal API
;;;

(defvar gh-notify--current-buffer nil
  "We have to play weird callback magic with Forge with buffer-local capabilities.")

(defvar-local gh-notify--repo-limit '()
  "Repo filter list.")

(defvar-local gh-notify--unread-limit nil
  "State limit.")

(defvar-local gh-notify--type-limit nil
  "Type limit.")

(defvar-local gh-notify--repo-index nil
  "Hash table that contains indexed `gh-notify' notifications.

Keys are repos, strings of form \"owner/repo\".  Values are conses of form:

  (notification-count . notification-list)")

(defun gh-notify--reindex-notifications (notifications)
  "Index NOTIFICATIONS into `gh-notify--repo-index'.
NOTIFICATIONS must be an alist as returned from `gh-notify-get-notifications'."
  (clrhash gh-notify--repo-index)
  (cl-loop
   for (repo . notification-data) in notifications
   for repo-id = (format "%s/%s" (oref repo owner) (oref repo name))
   for notification-count = 0
   for process-notifications = nil
   do
   (cl-loop
    for index from 0
    for forge-notification in notification-data
    ;; get timestamp as an emacs time value to juggle
    for ts = (encode-time (iso8601-parse (oref forge-notification updated)))
    for date = (format-time-string "%F" ts) ; use local time on our end for display
    do
    (let* ((notification
            (gh-notify-notification-create
             ;; retain the obj ref for db interactions
             :forge-obj forge-notification
             ;; yank all the forge crud for convenience
             :id (oref forge-notification id)
             :reason (oref forge-notification reason)
             :updated (oref forge-notification updated)
             :topic (oref forge-notification topic)
             :type (oref forge-notification type)
             :repo-id repo-id
             :repo repo
             :unread (oref forge-notification unread-p)
             :url (oref forge-notification url)
             :title (oref forge-notification title)
             ;; we use this for an accurate sort
             :ts ts
             :date date
             :state (when gh-notify-show-state
                      (gh-notify--get-topic-state
                       (oref forge-notification type)
                       repo
                       (oref forge-notification topic))))))
      (push notification process-notifications))
    finally (cl-incf notification-count index))
   ;; A hash table indexed by repo-id containing all notifications
   (setf (gethash repo-id gh-notify--repo-index)
         ;; sort notifications by timestamp and then reverse for display
         (cons notification-count
               (cl-sort process-notifications
                        (lambda (a b) (not (time-less-p a b)))
                        :key #'gh-notify-notification-ts)))))

(defvar-local gh-notify--visible-notifications nil)
(defvar-local gh-notify--marked-notifications 0)
(defvar-local gh-notify--total-notification-count 0)

(defun gh-notify--init-caches ()
  "Init caches."
  (setq gh-notify--repo-index (make-hash-table :test 'equal)
        gh-notify--visible-notifications (make-hash-table)))

(defvar-local gh-notify--start-time nil)
(defvar-local gh-notify--elapsed-time nil)

(defun gh-notify--start-timer ()
  "Start timer."
  (unless gh-notify--start-time
    (setq gh-notify--start-time (current-time))))

(defun gh-notify--stop-timer ()
  "Stop timer."
  (when gh-notify--start-time
    (setq gh-notify--elapsed-time
          (float-time (time-subtract
                       (current-time)
                       gh-notify--start-time))
          gh-notify--start-time nil)))

(defvar-local gh-notify--header-update nil)

(cl-defmacro gh-notify--with-timing (&body body)
  "Time BODY."
  (declare (indent defun))
  `(unwind-protect
       (progn
         (gh-notify--start-timer)
         ,@body)
     (gh-notify--stop-timer)
     (setq gh-notify--header-update t)))

(defun gh-notify--message (format-string &rest args)
  "Message ARGS as FORMAT-STRING."
  (let ((message-truncate-lines t))
    (message "gh-notify: %s" (apply #'format format-string args))))

;;;
;;; Filtering
;;;

(defvar-local gh-notify--active-filter nil)
(defvar-local gh-notify--last-notification nil)
(defvar-local gh-notify--global-ts-sort t)

(defsubst gh-notify--goto-line (line)
  "Goto LINE."
  (goto-char (point-min))
  (forward-line (1- line)))

(defsubst gh-notify--render-notification (notification &optional skip-goto)
  "Render NOTIFICATION optionally SKIP-GOTO."
  (unless skip-goto (gh-notify-goto-notification notification))
  (delete-region (line-beginning-position) (line-end-position))
  (insert (funcall gh-notify-render-function notification)))

(defsubst gh-notify--limit-notification (notification)
  "Limit NOTIFICATION."
  (funcall gh-notify-limit-function notification))

(defsubst gh-notify--filter-notification (notification)
  "Filter NOTIFICATION."
  (funcall gh-notify-filter-function notification))

(defun gh-notify--filter-notifications ()
  "Filter notifications."
  (when-let ((current-notification (gh-notify-current-notification)))
    (setq gh-notify--last-notification current-notification))
  (when (> (buffer-size) 0)
    (let ((inhibit-read-only t))
      (erase-buffer))
    (clrhash gh-notify--visible-notifications))

  ;; resorting * every time we re-filter is not the most optimal of things :P
  (gh-notify--with-timing
    (cl-loop
     for repo-id being the hash-keys of gh-notify--repo-index
     for repo-notifications = (cdr (gethash repo-id gh-notify--repo-index))
     with line = 1
     with ts-sorted-notifications = '()
     do
     ;; collect all notifications into a single list ... concat is faster here
     (setq ts-sorted-notifications
           (cl-concatenate 'list ts-sorted-notifications repo-notifications))
     finally do
     (progn
       ;; by default notifications are grouped and sorted by their repo blocks
       ;; but this overrides that behavior and lets you re-sort * by timestamp
       (when gh-notify--global-ts-sort
         (setq ts-sorted-notifications
               (cl-sort ts-sorted-notifications
                        (lambda (a b) (not (time-less-p a b)))
                        :key #'gh-notify-notification-ts)))
       ;; filter as a sorted whole list instead of per-repo chunks
       (cl-loop
        for notification in ts-sorted-notifications do
        (progn
          ;; Matching
          (if (and (gh-notify--limit-notification notification)
                   (gh-notify--filter-notification notification))
              ;; Matches filter+limit
              (let ((inhibit-read-only t))
                (setf (gh-notify-notification-line notification) line
                      (gethash line gh-notify--visible-notifications) notification
                      line (1+ line))
                (gh-notify--render-notification notification t)
                (insert "\n"))
            ;; Doesn't match filter/limit
            (setf (gh-notify-notification-line notification) nil))))

       ;; After all notifications have been filtered, determine where to set point
       (when (> line 1)
         ;; Previously selected notification if it's still visible
         (if-let ((last-notification gh-notify--last-notification)
                  (last-line (gh-notify-notification-line last-notification)))
             (gh-notify-goto-notification last-notification)
           (goto-char (point-min)))))))

  (force-mode-line-update))


;;;
;;; Header
;;;

(defvar-local gh-notify--header-function #'gh-notify--header
  "Function that returns a string for notification view header line.")

(defun gh-notify--header-1 ()
  "Generate string for notification view header line."
  (let* ((visible-notifications (hash-table-count gh-notify--visible-notifications))
         (total-repos (hash-table-count gh-notify--repo-index)))
    (cl-flet ((align (width str)
                     (let ((spec (format "%%%ds" width)))
                       (format spec str)))
              (size10 (x) (if (= x 0) 1 (1+ (floor (log x 10))))))
      (concat
       (align (+ 1 (* 2 (size10 gh-notify--total-notification-count)))
              (propertize (format "%s/%s" visible-notifications gh-notify--total-notification-count)
                          'help-echo "Visible / total notifications"))
       " "
       (align (size10 gh-notify--total-notification-count)
              (propertize (int-to-string gh-notify--marked-notifications)
                          'help-echo "Marked notifications"
                          'face 'gh-notify-notification-marked-face))
       " "
       (align (1+ (* 2 (size10 total-repos)))
              (propertize (format "(%s)" total-repos)
                          'help-echo "Total repos"))
       " "
       (format "by: %s " (if gh-notify--global-ts-sort "date" "repo"))
       (when gh-notify--unread-limit
         (format "%s " gh-notify--unread-limit))
       (when gh-notify--type-limit (format "type: %s " gh-notify--type-limit))
       (format "reason: %s " gh-notify-reason-limit)
       ;; if it's active, you already know which repos are in the filter, if not you don't care
       (when gh-notify--repo-limit ":repo ")
       (when gh-notify-show-timing
         (propertize (format " %.4fs " gh-notify--elapsed-time)
                     'help-echo "Elapsed time for last operation"))
       (when-let ((filter (gh-notify-active-filter)))
         (format "Search: %s"
                 (propertize filter
                             'help-echo "Search filter"
                             'face 'gh-notify-notification-filter-face)))))))

(defvar-local gh-notify--header-cache nil)

(defun gh-notify--header ()
  "Return string for notification view header line.
If a previously cached string is still valid, it is returned.
Otherwise, a new string is generated and returned by calling
`gh-notify--header-1'."
  (if (and (null gh-notify--header-update)
           (eql (car gh-notify--header-cache) (buffer-modified-tick)))
      (cdr gh-notify--header-cache)
    (let ((header (gh-notify--header-1)))
      (prog1 header
        (setq gh-notify--header-cache (cons (buffer-modified-tick) header)
              gh-notify--header-update nil)))))


;;;
;;; Major mode
;;;


(defvar gh-notify-mode-map
  ;; Override self-insert-command with fallback to global-map
  (let* ((map        (make-keymap))
         (prefix-map (make-sparse-keymap))
         (char-table (cl-second map)))
    ;; Rebind keys that were bound to self-insert-command
    (map-keymap
     (lambda (event def)
       (when (eq def 'self-insert-command)
         (set-char-table-range
          char-table event 'gh-notify--self-insert-command)))
     global-map)
    ;; Standard bindings
    (define-key map (kbd "DEL")       'gh-notify--self-insert-command)
    (define-key map (kbd "C-c C-l")   'gh-notify-retrieve-notifications)
    (define-key map (kbd "C-c C-k")   'gh-notify-reset-filter)
    (define-key map (kbd "C-c C-t")   'gh-notify-toggle-timing)
    (define-key map (kbd "C-c C-w")   'gh-notify-copy-url)
    (define-key map (kbd "C-c C-s")   'gh-notify-display-state)
    (define-key map (kbd "C-c C-i")   'gh-notify-ls-issues-at-point) ; all on prefix, open by default
    (define-key map (kbd "C-c C-p")   'gh-notify-ls-pullreqs-at-point) ; all on prefix, open by default
    (define-key map (kbd "G")         'gh-notify-forge-refresh)
    (define-key map (kbd "RET")       'gh-notify-visit-notification) ; browse-url on prefix
    (define-key map (kbd "C-c C-v")   'gh-notify-forge-visit-repo-at-point)
    ;; (define-key map (kbd "M-m")       'gh-notify-mark-notification)
    ;; (define-key map (kbd "M-M")       'gh-notify-mark-all-notifications)
    ;; (define-key map (kbd "M-u")       'gh-notify-unmark-notification)
    ;; (define-key map (kbd "M-U")       'gh-notify-unmark-all-notifications)
    (define-key map (kbd "C-<up>")    'previous-line)
    (define-key map (kbd "C-<down>")  'next-line)
    (define-key map (kbd "\\")        'gh-notify-toggle-url-view)
    ;; Prefix bindings
    (define-key map (kbd "/")          prefix-map)
    ;; toggle date/repo sort under this prefix-map for better flow
    (define-key prefix-map (kbd "d")  'gh-notify-toggle-global-ts-sort) ; date/repo sort toggle
    ;; state (read/unread) limit control
    (define-key prefix-map (kbd "u")  'gh-notify-limit-unread) ; resets unread limit on prefix
    ;; repo limit control
    (define-key prefix-map (kbd "'")  'gh-notify-limit-repo) ; pushes by default, pops on prefix
    (define-key prefix-map (kbd "\"") 'gh-notify-limit-repo-none) ; resets to default repo limit
    ;; type limit control
    (define-key prefix-map (kbd "p")  'gh-notify-limit-pr) ; resets type limit on prefix
    (define-key prefix-map (kbd "i")  'gh-notify-limit-issue) ; resets type limit on prefix
    ;; reason limit control
    (define-key prefix-map (kbd "*")  'gh-notify-limit-marked)
    (define-key prefix-map (kbd "a")  'gh-notify-limit-assign)
    (define-key prefix-map (kbd "y")  'gh-notify-limit-author)
    (define-key prefix-map (kbd "m")  'gh-notify-limit-mention)
    (define-key prefix-map (kbd "t")  'gh-notify-limit-team-mention)
    (define-key prefix-map (kbd "s")  'gh-notify-limit-subscribed)
    (define-key prefix-map (kbd "c")  'gh-notify-limit-comment)
    (define-key prefix-map (kbd "r")  'gh-notify-limit-review-requested)
    (define-key prefix-map (kbd "/")  'gh-notify-limit-none) ; resets reason limit
    map)
  "Keymap for `gh-notify-mode'.")

(defun gh-notify--self-insert-command ()
  "Insert command."
  (interactive)
  (let ((event last-input-event)
        updated)
    (cond ((characterp event)
           (if (and (= 127 event)
                    (not (display-graphic-p)))
               (pop gh-notify--active-filter)
             (push event gh-notify--active-filter))
           (setq updated t))
          ((eql event 'backspace)
           (pop gh-notify--active-filter)
           (setq updated t))
          (t (gh-notify--message "Unknown event %s" event)))
    (when updated (gh-notify--filter-notifications))))

(defun gh-notify-mode ()
  "Major mode for manipulating GitHub notifications through Magit/Forge.

\\<gh-notify-mode-map>

Notifications are retrieved from Magit/Forge and displayed in an Emacs buffer,
one notification per line.  Display takes place in date/repo or repo/date
ordered fashion.

Notifications can be further filtered in realtime by a user-specified regular
expression and limited by certain criteria described below.  This mode tries to
remember point so that it keeps its associated notification selected across
filtering/limiting operations, assuming the notification is visible.

To minimize the feedback loop, this mode does not use the minibuffer for input
\(e.g.  when typing a filter regular expression).  You can start typing
immediately and the filter updates, visible on the header line.

Other than regular keys being bound to `gh-notify--self-insert-command', the
following commands are available:

Type \\[gh-notify-visit-notification] to switch to notification at point in
magit/forge.  With a prefix argument, switch to the topic associated to
notification through `browse-url'.

Type \\[gh-notify-retrieve-notifications] to retrieve local notifications from magit/forge.

Type \\[gh-notify-forge-refresh] to retrieve new remote notifications from GitHub.

Type \\[gh-notify-reset-filter] to kill the current Title/URL filter.

Type \\[gh-notify-toggle-url-view] to toggle notifications being shown as titles or API URLs.

Type \\[gh-notify-toggle-timing] to toggle timing information on the header line.

Type \\[gh-notify-copy-url] to copy API URL belonging to notification at point.

Type \\[gh-notify-ls-issues-at-point] to visit any other open issue associated
to the repo of the notification at point.  With a prefix any of all issues
associated to the repo of the notification at point.

Type \\[gh-notify-ls-pullreqs-at-point] to visit any other open pull request
associated to the repo of the notification at point.  With a prefix any of all
issues associated to the repo of the notification at point.

Limiting notifications:

Gh-notify operates on four layers of result limiting, a read-state limit, a
type limit, repo limit and a reason limit.

These are applied in repo -> state -> type -> reason order, which is generally
what you want.  This allows you to intuitively add and remove limits.  Repo
narrows to repo scope, state toggles for unread/read, type narrows for
notification type (issue, pullreq) and finally reason narrows on the reason
for the notification.

Repo limits:

Type \\[gh-notify-limit-repo] to add a repo to the repo limit.  With a prefix argument, remove
a repo from the repo limit.

Type \\[gh-notify-limit-repo-none] to reset the repo limit to the default limit.

State limits:

Type \\[gh-notify-limit-unread] to limit to unread notifications.  With a prefix argument,
remove unread limit.

Reason limits:

Independently from the repo limit are the various reason limits.  These
correlate to the various notification reason states that may be associated
with a GitHub notification.

Type \\[gh-notify-limit-issue] to limit to issue notifications.

Type \\[gh-notify-limit-pr] to limit to pull request notifications.

Type \\[gh-notify-limit-assign] to limit to assign notifications.

Type \\[gh-notify-limit-author] to limit to author notifications.

Type \\[gh-notify-limit-mention] to limit to mention notifications.

Type \\[gh-notify-limit-team-mention] to limit to team-mention notifications.

Type \\[gh-notify-limit-subscribed] to limit to subscribed notifications.

Type \\[gh-notify-limit-comment] to limit to comment notifications.

Type \\[gh-notify-limit-review-requested] to limit to review-requested notifications.

Type \\[gh-notify-limit-none] to remove any active reason limit.

Type \\[gh-notify-limit-marked] to only show marked notifications.

Type \\[gh-notify-limit-none] to remove the current limit and show all notifications.

Marking:

Type \\[gh-notify-mark-notification] to mark notification at point.

Type \\[gh-notify-unmark-notification] to unmark notification at point.

Type \\[gh-notify-mark-all-notifications] to mark all notifications currently visible in Emacs.  If
there is a region, only mark notifications in region.

Type \\[gh-notify-unmark-all-notifications] to unmark all notifications currently visible in Emacs.
If there is a region, only unmark notifications in region.

Note: marking support is currently moot, but will be used to support bulk
actions.

\\{gh-notify-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (use-local-map gh-notify-mode-map)
  (font-lock-mode -1)
  (make-local-variable 'font-lock-function)
  (buffer-disable-undo)
  (setq major-mode 'gh-notify-mode
        mode-name "Gh-Notify"
        truncate-lines t
        buffer-read-only t
        header-line-format '(:eval (funcall gh-notify--header-function))
        font-lock-function (lambda (_) nil)
        gh-notify--repo-limit gh-notify-default-repo-limit
        gh-notify--current-buffer (current-buffer))
  (gh-notify--init-caches)
  (gh-notify--with-timing
    (gh-notify--reindex-notifications (gh-notify-get-notifications))
    (gh-notify--filter-notifications))
  (hl-line-mode)
  (run-mode-hooks 'gh-notify-mode-hook))

;;;
;;; API
;;;

(defun gh-notify-active-filter ()
  "Return currently active filter string or nil."
  (when gh-notify--active-filter
    (apply #'string (reverse gh-notify--active-filter))))

(defun gh-notify-render-notification (notification)
  "Return string representation of NOTIFICATION.
String is used as is to display NOTIFICATION in *github-notifications* buffer.
It must not span more than one line but it may contain text properties."
  (let ((repo-id (gh-notify-notification-repo-id notification))
        (type (gh-notify-notification-type notification))
        (url (gh-notify-notification-url notification))
        (title (gh-notify-notification-title notification))
        (is-marked (gh-notify-notification-is-marked notification))
        (unread (gh-notify-notification-unread notification))
        (reason (gh-notify-notification-reason notification))
        (date (gh-notify-notification-date notification))
        (topic (gh-notify-notification-topic notification))
        (state (gh-notify-notification-state notification)))
    (let* ((unread-str
            (cond (is-marked
                   "*")
                  (unread
                   "U")
                  ((not unread)
                   "R")))
           (date-str (format "%s" date))
           (type-str
            (cond
             ((eq type 'pullreq)
              "P")
             ((eq type 'issue)
              "I")
             (t
              "?")))
           (state-str
            (if gh-notify-show-state
                (cond
                 ((eq state 'open)
                  "O")
                 ((eq state 'closed)
                  "C")
                 ((eq state 'merged)
                  "M")
                 (t
                  "."))
              ""))
           (repo-str (format "%s #%s" repo-id topic))
           (reason-str (format "[%s]" reason))
           (desc-str
            (if (eq gh-notify-default-view :title)
                (if (string-equal "" title) url title)
              url)))

      ;; use type as a visual marker for issue|pullreq
      (pcase type
        ('pullreq
         (setq type-str (propertize type-str 'face 'gh-notify-notification-pr-face)))
        ('issue
         (setq type-str (propertize type-str 'face 'gh-notify-notification-issue-face))))

      ;; repo face is our default face for most components
      (setq date-str (propertize date-str 'face 'gh-notify-notification-repo-face))
      (setq state-str (propertize state-str 'face 'gh-notify-notification-repo-face))
      (setq unread-str (propertize unread-str 'face 'gh-notify-notification-repo-face))
      (setq repo-str (propertize repo-str 'face 'gh-notify-notification-repo-face))
      (setq reason-str (propertize reason-str 'face 'gh-notify-notification-reason-face))

      ;; use the tail of the line for any mutex global state marker like marked/unread
      (cond
       (is-marked
        (setq date-str (propertize date-str 'face 'gh-notify-notification-marked-face))
        (setq unread-str (propertize unread-str 'face 'gh-notify-notification-marked-face))
        (setq repo-str (propertize repo-str 'face 'gh-notify-notification-marked-face))
        (setq desc-str (propertize desc-str 'face 'gh-notify-notification-marked-face)))
       (unread
        (setq date-str (propertize date-str 'face 'gh-notify-notification-unread-face))
        (setq unread-str (propertize unread-str 'face 'gh-notify-notification-unread-face))
        (setq repo-str (propertize repo-str 'face 'gh-notify-notification-unread-face))
        (setq desc-str (propertize desc-str 'face 'gh-notify-notification-unread-face))))

      (concat unread-str " "
              date-str " "
              type-str " "
              state-str (if (string-equal state-str "") "" " ")
              repo-str " "
              reason-str " "
              desc-str))))

(defun gh-notify-limit-notification (notification)
  "Limits NOTIFICATION by status.
Limiting operation depends on `gh-notify-reason-limit', `gh-notify-type-limit'
and `gh-notify--repo-limit'."
  (let ((repo-id (gh-notify-notification-repo-id notification)))
    ;; 3 pass filter: repo -> type -> reason
    (when
        ;; repo limits
        (and (or (member repo-id gh-notify--repo-limit)
                 (not gh-notify--repo-limit))
             (not (member repo-id gh-notify-exclude-repo-limit)))
      ;;
      (and
       ;; state filter
       (if gh-notify--unread-limit
           (gh-notify-notification-unread notification)
         t)
       ;; type filters
       (or (eq (gh-notify-notification-type notification) gh-notify--type-limit)
           (not gh-notify--type-limit))
       ;; reason filters (layer 3 filter)
       (cl-case gh-notify-reason-limit
         (:all t)
         (:mark (gh-notify-notification-is-marked notification))
         (:unread (gh-notify-notification-unread notification))
         (:assign (eq (gh-notify-notification-reason notification) 'assign))
         (:mention (eq (gh-notify-notification-reason notification) 'mention))
         (:team_mention (eq (gh-notify-notification-reason notification) 'team_mention))
         (:subscribed (eq (gh-notify-notification-reason notification) 'subscribed))
         (:author (eq (gh-notify-notification-reason notification) 'author))
         (:review-requested (eq (gh-notify-notification-reason notification) 'review_requested))
         (:comment (eq (gh-notify-notification-reason notification) 'comment)))))))

(defun gh-notify-filter-notification (notification)
  "Filters NOTIFICATION using a case-insensitive match on either URL or title."
  (let ((filter (gh-notify-active-filter)))
    (or (null filter)
        (let ((case-fold-search t)
              (url   (gh-notify-notification-url notification))
              (title (gh-notify-notification-title notification)))
          (or
           (string-match (replace-regexp-in-string " " ".*" filter) url)
           (string-match (replace-regexp-in-string " " ".*" filter) title))))))

(defun gh-notify-current-notification ()
  "Return notification at point or nil."
  (gethash (line-number-at-pos (point))
           gh-notify--visible-notifications))

(defun gh-notify-goto-notification (notification)
  "Move point to NOTIFICATION if it is visible."
  (when-let ((line (gh-notify-notification-line notification)))
    (gh-notify--goto-line line)))


;;;
;;; Forge API
;;;

;; XXX: here be dragons: forge api does not support "since" based refreshes
;; XXX: so add some logic that does not pull _ALL_ notifications EVERY time
;; XXX: unless we explicitly have to ... this is prone to breakage due to
;; XXX: desync with forge code :)

;; warning: this incremental logic does not account for e.g. you being added
;; to a new repo that for some reason has notifications for you that live in
;; the past ... it should work fine for any forward notifications, but you
;; should manage global base-state inits from the regular magit forge ui
;;
;; Nothing we do here will interfere with normal Magit/Forge operation and
;; you can always feel free to fetch all notifications again through Magit/Forge
;; if you feel like something DID get messed up and you need a blank slate to
;; start from.

(defvar-local gh-notify--forge-last-timestamp nil
  "The most recently updated notification `gh-notify' knows about.")

(cl-defmethod gh-notify-forge--pull-notifications
  ((_class (subclass forge-github-repository)) githost &optional callback)
  "An incremental version to retrieve `forge--pull-notifications' from GITHOST.
Optionally provide a CALLBACK."
  ;; The GraphQL API doesn't support notifications and also likes to
  ;; timeout for handcrafted requests, forcing us to perform a major
  ;; rain dance.
  (let ((spec (assoc githost forge-alist)))
    (unless spec
      (error "No entry for %S in forge-alist" githost))
    (forge--msg nil t nil "Pulling notifications")
    (pcase-let*
        ((`(,_ ,apihost ,forge ,_) spec)
         (notifs (-keep (lambda (data)
                          ;; Github may return notifications for repos
                          ;; the user no longer has access to.  Trying
                          ;; to retrieve information for such a repo
                          ;; leads to an error, which we suppress.  See #164.
                          (with-demoted-errors "forge--pull-notifications: %S"
                            (forge--ghub-massage-notification
                             data forge githost)))
                        ;; try to be a bit more clever about how many notifications we need to fetch
                        (let ((params '((all . "true")))
                              (since (if gh-notify--forge-last-timestamp
                                         (iso8601-parse gh-notify--forge-last-timestamp)
                                       nil)))
                          (when since
                            ;; +1 sec since known latest update
                            (setcar since (+ 1 (car since)))
                            (push `(since . ,(format-time-string
                                              "%Y-%m-%dT%H:%M:%SZ"
                                              (encode-time since) t)) params)
                            (message "Refreshing forge updates since %s" (alist-get 'since params)))
                          (forge--ghub-get nil "/notifications"
                            params
                            :host apihost :unpaginate t))))
         (groups (-partition-all 50 notifs))
         (pages  (length groups))
         (page   0)
         (result nil))
      (cl-labels
          ((cb (&optional data _headers _status _req)
               (when data
                 (setq result (nconc result (cdr data))))
               (if groups
                   (progn (cl-incf page)
                          (forge--msg nil t nil
                                      "Pulling notifications (page %s/%s)"
                                      page pages)
                          (ghub--graphql-vacuum
                           (cons 'query (-keep #'caddr (pop groups)))
                           nil #'cb nil :auth 'forge))
                 (forge--msg nil t t   "Pulling notifications")
                 (forge--msg nil t nil "Storing notifications")
                 (emacsql-with-transaction (forge-db)
                   ;; XXX: for gh-notify we don't want to nuke the db, but replace inserts instead
                   ;; XXX: this should not interfere with normal magit/forge operation ... i THINK ;)
                   (when nil
                     (forge-sql [:delete-from notification
                                              :where (= forge $s1)] forge))
                   (pcase-dolist (`(,key ,repo ,query ,obj) notifs)
                     (when nil
                       (message "XXX: obj id=%s" (oref obj id))
                       (message "XXX: obj repository=%s" (oref obj repository))
                       (message "XXX: obj updated_at=%s" (oref obj updated))
                       (message "XXX: obj title=%s" (oref obj title))
                       (message "==="))
                     ;; XXX: enable replace so we don't collide on updates for existing notification id
                     (closql-insert (forge-db) obj t)
                     (forge--zap-repository-cache (forge-get-repository obj))
                     (when query
                       (oset (funcall (if (eq (oref obj type) 'issue)
                                          #'forge--update-issue
                                        #'forge--update-pullreq)
                                      repo (cdr (cadr (assq key result))) nil)
                             unread-p (oref obj unread-p)))))
                 (forge--msg nil t t "Storing notifications")
                 (when callback
                   (funcall callback)))))
        (cb)))))

(defun gh-notify--forge-get-notifications ()
  "Get forge notifications."
  (let ((results '()))
    (when-let ((ns (forge--list-notifications-all)))
      (pcase-dolist (`(,_ . ,ns) (--group-by (oref it repository) ns))
        (let ((repo (forge-get-repository (car ns))))
          (dolist (notify ns)
            ;; id reason updated type topic title url unread-p ... etc.
            (with-slots (updated) notify
              ;; XXX: since-hack support for incremental refresh
              (if gh-notify--forge-last-timestamp
                  ;; update refresh floor if notification is newer
                  (when (time-less-p (encode-time (iso8601-parse gh-notify--forge-last-timestamp))
                                     (encode-time (iso8601-parse updated)))
                    (setq-local gh-notify--forge-last-timestamp updated))
                ;; first seen timestamp
                (setq-local gh-notify--forge-last-timestamp updated))))
          ;; return a forge repo-id and notifications for that repo
          (push (list repo ns) results))))
    results))

(defun gh-notify-get-notifications ()
  "Return a record (alist) containing notification information.

The alist contains (repo-id . notifications) pairs."

  (cl-loop with total-notification-count = 0
           with error-count = 0
           with repo-count = 0
           for repo-results in (gh-notify--forge-get-notifications)
           for repo-id = (car repo-results)
           for repo-notifications = (cadr repo-results)
           when repo-id do (cl-incf repo-count)
           when repo-notifications do
           (setq
            total-notification-count
            (+ total-notification-count
               (length repo-notifications)))
           when repo-notifications collect (cons repo-id repo-notifications)
           finally
           (progn
             (setq gh-notify--total-notification-count total-notification-count)
             (message "Retrieved %d notifications across %d repos%s"
                      total-notification-count
                      repo-count
                      (if (> error-count 0)
                          (format ", %d errors" error-count)
                        "")))))

(defun gh-notify-forge-refresh()
  "Refresh the Forge notification state."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  ;; we fixed some of forge's all-or-nothing approach to notification updates
  ;; we want to routinely refresh without doing a full fetch, so instead we do
  ;; incremental refreshes based on the last known timestamp

  ;; ensure we always start from the most recent Magit/Forge db state
  (call-interactively #'gh-notify-retrieve-notifications)
  (gh-notify-forge--pull-notifications 'forge-github-repository "github.com" #'gh-notify-forge-refresh-cb))

(defun gh-notify-forge-refresh-cb ()
  "Callback for Forge refresh."
  (message "Forge is refreshed!")
  (with-current-buffer gh-notify--current-buffer
    (call-interactively #'gh-notify-retrieve-notifications)))

(defun gh-notify--insert-forge-obj (obj)
  "Insert/Replace a forge db object with OBJ."
  ;; replace the updated object ...
  (emacsql-with-transaction (forge-db)
    (closql-insert (forge-db) obj t)))

(defun gh-notify--get-topic-state (type repo topic)
  "Get current topic state of TYPE from forge REPO db for TOPIC."
  (gh-notify--with-timing
    (pcase type
      ('issue
       (let ((issue (forge-get-issue repo topic)))
         (oref issue state)))
      ('pullreq
       (let ((pullreq (forge-get-pullreq repo topic)))
         (oref pullreq state))))))

;;;
;;; Interactive
;;;

;; modified from forge-read-issue
(defun gh-notify-ls-pullreqs-at-point (P)
  "Navigate a list of open pull requests available for notification at point.
All pull request on prefix P."
  (interactive "P")
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (when-let ((notification (gh-notify-current-notification)))
    (let* ((default-directory gh-notify-smokescreen-path)
           (repo-id (gh-notify-notification-repo-id notification))
           (repo (gh-notify-notification-repo notification))
           (fmt (lambda (obj)
                  (format "#%s %s"
                          (oref obj number)
                          (oref obj title))))
           ;; list all issues on prefix, only open by default
           (pullreqs (if P (forge-ls-pullreqs repo)
                       (forge-ls-pullreqs repo 'open)))
           (choice (completing-read
                    (format "%s visit pull request (%s): " repo-id (if P "all" "open"))
                    (mapcar fmt pullreqs) nil t)))
      (unless (string-equal choice "")
        ;; parse the number we selected back out
        (let ((topic (and (string-match "^#\\([0-9]+\\) " choice)
                          (string-to-number (match-string 1 choice)))))
          (with-demoted-errors "Warning: %S"
            (with-temp-buffer
              (forge-visit (forge-get-pullreq repo topic)))))))))

(defun gh-notify-ls-issues-at-point (P)
  "Navigate a list of open issues available for notification at point.
All issues on prefix P."
  (interactive "P")
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (when-let ((notification (gh-notify-current-notification)))
    (let* ((default-directory gh-notify-smokescreen-path)
           (repo-id (gh-notify-notification-repo-id notification))
           (repo (gh-notify-notification-repo notification))
           (fmt (lambda (obj)
                  (format "#%s %s"
                          (oref obj number)
                          (oref obj title))))
           ;; list all issues on prefix, only open by default
           (issues (if P (forge-ls-issues repo)
                     (forge-ls-issues repo 'open)))
           (choice (completing-read
                    (format "%s visit issue (%s): " repo-id (if P "all" "open"))
                    (mapcar fmt issues) nil t)))
      (unless (string-equal choice "")
        (message "%s" choice)
        ;; parse the number we selected back out
        (let ((topic (and (string-match "^#\\([0-9]+\\) " choice)
                          (string-to-number (match-string 1 choice)))))
          (with-demoted-errors "Warning: %S"
            (with-temp-buffer
              (forge-visit (forge-get-issue repo topic)))))))))

(defun gh-notify-display-state ()
  "Show the current state for an issue or pull request notification."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (when-let ((notification (gh-notify-current-notification)))
    (let ((type (gh-notify-notification-type notification))
          (topic (gh-notify-notification-topic notification))
          (repo (gh-notify-notification-repo notification)))
      (message "state: %s" (gh-notify--get-topic-state type repo topic)))))

(defun gh-notify-toggle-timing ()
  "Toggle timing information on the header line."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (let ((timingp gh-notify-show-timing))
    (setq-local gh-notify-show-timing (if timingp nil t))
    (setq gh-notify--header-update t))
  (force-mode-line-update))

(defun gh-notify-toggle-url-view ()
  "Toggle notifications being displayed as titles or URLs."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (let ((view gh-notify-default-view))
    (setq-local gh-notify-default-view
                (if (eq view :title) :url :title)))
  (gh-notify--filter-notifications))

(defun gh-notify-toggle-global-ts-sort ()
  "Sort * by timestamp, or repo-block by timestamp (default)."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (setq-local gh-notify--global-ts-sort (not gh-notify--global-ts-sort))
  (gh-notify--filter-notifications))

(defun gh-notify-limit-marked ()
  "Only show marked notifications."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (setq-local gh-notify-reason-limit :mark)
  (gh-notify--filter-notifications))

(defun gh-notify-limit-type-none ()
  "Reset type limit to nil."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (setq-local gh-notify--type-limit nil)
  (gh-notify--filter-notifications))

(defun gh-notify-limit-issue (P)
  "Only show issue notifications, remove limit on prefix P."
  (interactive "P")
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (if P (gh-notify-limit-type-none)
    (progn
      (setq-local gh-notify--type-limit 'issue)
      (gh-notify--filter-notifications))))

(defun gh-notify-limit-pr (P)
  "Only show pull request notifications, remove limit on prefix P."
  (interactive "P")
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (if P (gh-notify-limit-type-none)
    (progn
      (setq-local gh-notify--type-limit 'pullreq)
      (gh-notify--filter-notifications))))

(defun gh-notify-limit-unread (P)
  "Only show unread notifications, remove limit on prefix P."
  (interactive "P")
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (if P (setq-local gh-notify--unread-limit nil)
    (setq-local gh-notify--unread-limit :unread))
  (gh-notify--filter-notifications))

(defun gh-notify-limit-assign ()
  "Only show notifications with reason: assign."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (setq-local gh-notify-reason-limit :assign)
  (gh-notify--filter-notifications))

(defun gh-notify-limit-author ()
  "Only show notifications with reason: author."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (setq-local gh-notify-reason-limit :author)
  (gh-notify--filter-notifications))

(defun gh-notify-limit-mention ()
  "Only show notifications with reason: mention."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (setq-local gh-notify-reason-limit :mention)
  (gh-notify--filter-notifications))

(defun gh-notify-limit-team-mention ()
  "Only show notifications with reason: team_mentioned."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (setq-local gh-notify-reason-limit :team_mention)
  (gh-notify--filter-notifications))

(defun gh-notify-limit-subscribed ()
  "Only show notifications with reason: subscribed."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (setq-local gh-notify-reason-limit :subscribed)
  (gh-notify--filter-notifications))

(defun gh-notify-limit-comment ()
  "Only show notifications with reason: comment."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (setq-local gh-notify-reason-limit :comment)
  (gh-notify--filter-notifications))

(defun gh-notify-limit-review-requested ()
  "Only show notifications with reason: review_requested."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (setq-local gh-notify-reason-limit :review-requested)
  (gh-notify--filter-notifications))

(defun gh-notify-limit-repo (P)
  "Only show notifications belonging to a specific repo, remove filter on prefix P."
  (interactive "P")
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (let* ((repos  (vconcat (hash-table-keys gh-notify--repo-index))))
    (if P
        ;; delete a repo filter on prefix
        (when gh-notify--repo-limit
          (setq-local gh-notify--repo-limit
                      (delete (completing-read "repo filter remove: " (append gh-notify--repo-limit nil) nil t)
                              gh-notify--repo-limit)))
      (let ((repo (completing-read "repo filter add: " (append repos nil) nil t)))
        (unless (member repo gh-notify--repo-limit)
          (push repo gh-notify--repo-limit)))))
  (gh-notify--filter-notifications))

(defun gh-notify-limit-none ()
  "Remove current limit and show all notifications."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (unless (eq gh-notify-reason-limit :all)
    (setq-local gh-notify-reason-limit :all)
    (gh-notify--filter-notifications)))

(defun gh-notify-limit-repo-none ()
  "Reset repo limit to default.."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (setq-local gh-notify--repo-limit gh-notify-default-repo-limit)
  (gh-notify--filter-notifications))

(defun gh-notify-copy-url ()
  "Copy URL belonging to notification at point."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (when-let ((notification (gh-notify-current-notification)))
    (let ((url (gh-notify-notification-url notification)))
      (kill-new url)
      (message "Copied: %s" url))))

(defun gh-notify-retrieve-notifications ()
  "Retrieve and filter all Gh-Notify notifications.
This wipes and recreates all notification state in Emacs but keeps the current
filter and limit.  It repositions point to the last notification at point when
possible."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (gh-notify--with-timing
    (setq gh-notify--marked-notifications 0)
    (gh-notify--reindex-notifications (gh-notify-get-notifications))
    (gh-notify--filter-notifications)))

(defun gh-notify-reset-filter ()
  "Kill current notification filter."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (setq gh-notify--active-filter nil)
  (gh-notify--filter-notifications))

;; example code for when we start doing bulk action support:
;;
;; (defun gh-notify-something-marked-notifications ()
;;   "Something all marked notifications."
;;   (interactive)
;;   (cl-assert (eq major-mode 'gh-notify-mode) t)
;;   (when (> gh-notify--marked-notifications 0)
;;     (gh-notify--with-timing
;;       (cl-loop
;;        for session being the hash-keys of gh-notify--repo-index
;;        for session-notifications = (cdr (gethash session gh-notify--repo-index)) do
;;        (cl-loop
;;         for notification in session-notifications
;;         when (gh-notify-notification-is-marked notification)
;;         collect notification into marked-notifications
;;         finally do
;;         (cl-loop for notification in marked-notifications do
;;                  (gh-notify--something notification))))
;;       (gh-notify-retrieve-notifications))))

(defun gh-notify-mark-notification (&optional notification)
  "Mark NOTIFICATION at point."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (let ((move-forward (if notification nil t)))
    (when-let ((notification (or notification (gh-notify-current-notification))))
      (unless (gh-notify-notification-is-marked notification)
        (setf (gh-notify-notification-is-marked notification) t)
        (cl-incf gh-notify--marked-notifications)
        (let ((inhibit-read-only t)
              (point (point)))
          (unwind-protect
              (gh-notify--render-notification notification)
            (goto-char point))))
      (when move-forward (forward-line)))))

(defun gh-notify-unmark-notification (&optional notification)
  "Unmark NOTIFICATION at point."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (let ((move-forward (if notification nil t)))
    (when-let ((notification (or notification (gh-notify-current-notification))))
      (when (gh-notify-notification-is-marked notification)
        (setf (gh-notify-notification-is-marked notification) nil)
        (cl-decf gh-notify--marked-notifications)
        (let ((inhibit-read-only t)
              (point (point)))
          (unwind-protect
              (gh-notify--render-notification notification)
            (goto-char point))))
      (when move-forward (forward-line)))))

(defsubst gh-notify-do-visible-notifications (function)
  "Call FUNCTION once for each visible notification.
Passes notification as an argument."
  (mapc function
        (if (region-active-p)
            (save-excursion
              (let ((begin (region-beginning))
                    (end (region-end)))
                (goto-char begin)
                (cl-loop for pos = (point) while (< pos end)
                         collect (gh-notify-current-notification)
                         do (forward-line))))
          (hash-table-values gh-notify--visible-notifications))))

(defun gh-notify-mark-all-notifications ()
  "Mark all notifications currently visible in Emacs.
If there is a region, only mark notifications in region."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (gh-notify-do-visible-notifications #'gh-notify-mark-notification))

(defun gh-notify-unmark-all-notifications ()
  "Unmark all notifications currently visible in Emacs.
If there is a region, only unmark notifications in region."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (gh-notify-do-visible-notifications #'gh-notify-unmark-notification))

(defun gh-notify-forge-visit-repo-at-point ()
  "Visit repo at point."
  (interactive)
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (when-let ((current-notification (gh-notify-current-notification)))
    (let* ((repo (gh-notify-notification-repo current-notification)))
      ;; XXX: improve me, needs to detect when we don't have a full repo locally
      ;; XXX: which we can probably just pull from the Forge DB
      (if repo
          (forge-visit repo)
        (message "No forge github repo available at point!")))))

(defun gh-notify-mark-notification-read (notification)
  "Mark NOTIFICATION as read."
  ;; XXX: Forge DB hack state hack-arounds:
  ;; XXX: magit/forge will mark a topic as read with GitHub.com itself
  ;; XXX: but this doesn't translate to the notification objects and
  ;; XXX: since we don't want to refresh the entire notification history
  ;; XXX: we just toggle directly on the object ourselves, update the db
  ;; XXX: and re-render our view
  (let ((obj (gh-notify-notification-forge-obj notification)))
    (when (oref obj unread-p)
      (oset obj unread-p nil)
      (gh-notify--insert-forge-obj obj)
      (when gh-notify-redraw-on-visit
        (gh-notify-retrieve-notifications)))))

(defun gh-notify-visit-notification (P)
  "Attempt to visit notification at point in some sane way.
Browse issue or PR on prefix P."
  (interactive "P")
  (cl-assert (eq major-mode 'gh-notify-mode) t)
  (when-let ((current-notification (gh-notify-current-notification)))
    (let* ((repo-id (gh-notify-notification-repo-id current-notification))
           (repo (gh-notify-notification-repo current-notification))
           (topic (gh-notify-notification-topic current-notification))
           (type (gh-notify-notification-type current-notification))
           (title (gh-notify-notification-title current-notification)))
      (if P
          ;; browse url for issue or pull request on prefix
          (gh-notify-browse-notification repo-id type topic)
        ;; handle through magit forge otherwise

        ;; important: we want to re-render on read/unread state before switching
        ;; buffers, that's because we do an auto-magic point reposition based on
        ;; the last notification state, but on a buffer switch, the active point
        ;; is lost in the middle of this logic, this doesn't "break" anything, but
        ;; it can result in a lagging point, so take care of all the state rendering
        ;; first, and THEN trigger the buffer switch

        (let ((default-directory gh-notify-smokescreen-path))

          ;; XXX: this is a really ugly hack until I figure out how to cleanly make
          ;; XXX: magit ignore errors when we don't have a local copy of the repo
          ;; XXX: checked out in our magit paths ... we really don't need a local copy
          ;; XXX: for interacting with issues and even performing reviews ... e.g.
          ;; XXX: github-review will work fine with a template magit buffer from a PR
          ;; XXX: for a non-local repo ...

          ;; XXX: so we throw up a smokescreen with an empty tmp git repo, magit will
          ;; XXX: fall back to default-directory if it can't find the actual repo ;)
          ;; XXX: surely there's some non-ganky way to achieve this, but will have to
          ;; XXX: dig into magit/forge guts a bit more ...

          (unless (file-exists-p default-directory)
            (make-directory default-directory)
            (set-file-modes default-directory #o700)
            (magit-init default-directory))

          (pcase type
            ('issue
             ;;(message "handling an issue ...")
             (gh-notify-mark-notification-read current-notification)
             (with-demoted-errors "Warning: %S"
               (with-temp-buffer
                 (forge-visit (forge-get-issue repo topic))
                 (forge-pull-topic topic))))
            ('pullreq
             ;;(message "handling a pull request ...")
             (gh-notify-mark-notification-read current-notification)
             (with-demoted-errors "Warning: %S"
               (with-temp-buffer
                 (forge-visit (forge-get-pullreq repo topic))
                 (forge-pull-topic topic))))
            ('commit
             (message "Commit not handled yet!"))
            (_
             (message "Handling something else (%s) %s\n" type title))))))))

(defun gh-notify-browse-notification (repo-id type topic)
  "Browse to a TOPIC of TYPE on GitHub REPO-ID."
  (if (member type '(issue pullreq))
      (let ((url (format "https://github.com/%s/%s/%s"
                         repo-id
                         (pcase type
                           ('issue "issues")
                           ('pullreq "pull"))
                         topic)))
        (browse-url url))
    (message "Can't browse to this notification!")))

(defun gh-notify ()
  "Magit/Forge notification juggling."
  (interactive)
  (let ((buf (get-buffer-create "*github-notifications*")))
    (switch-to-buffer buf)
    (unless (eq major-mode 'gh-notify-mode)
      (gh-notify-mode))))

(provide 'gh-notify)
;;; gh-notify.el ends here
