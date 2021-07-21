;;; nswbuff.el --- Quick switching between buffers.  -*- lexical-binding: t; -*-

;; Copyright (C) 1998, 2000, 2001, 2003, 2004 by David Ponce
;; Copyright (C) 2001, 2002, 2003 Free Software Foundation, Inc.
;; Copyright (C) 2017-2020 Joost Kremers

;; Author: David Ponce <david@dponce.com>
;;         Kahlil (Kal) HODGSON <dorge@tpg.com.au>
;;         Joost Kremers <joostkremers@fastmail.fm>
;; Maintainer: Joost Kremers <joostkremers@fastmail.fm>
;; Created: 18 May 2017
;; Keywords: extensions convenience
;; Package-Commit: fa9dcf131697ea7af066e11a1edcc881c397e07f
;; Package-Version: 20210721.741
;; Package-X-Original-Version: 1.3
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/joostkremers/nswbuff

;; This file is not part of Emacs

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;; `nswbuff' is an Emacs library for quick buffer switching based on swbuff.el,
;; incorporating the changes from swbuff-x.el and a few new features not present
;; in either.
;;
;; This package provides two commands: `nswbuff-switch-to-next-buffer' and
;; `nswbuff-switch-to-previous-buffer' to switch to the next or previous buffer
;; in the buffer list, respectively.  During buffer switching, the list of
;; switchable buffers is visible at the bottom of the frame.
;;
;; Switching buffers pops-up a status window at the bottom of the selected
;; window.  The status window shows the list of switchable buffers where the
;; switched one is highlighted using `nswbuff-current-buffer-face'.  This window
;; is automatically discarded after any command is executed or after the delay
;; specified by `nswbuff-clear-delay'.
;;
;; The bufferlist is sorted by how recently the buffers were used.  If you
;; prefer a fixed (cyclic) order set `nswbuff-recent-buffers-first' to nil.
;;
;; There are several options to manipulate the list of switchable buffers.
;; The option `nswbuff-exclude-buffer-regexps' defines a list of regular
;; expressions for excluded buffers.  The default setting excludes
;; buffers whose name begin with a blank character.  To exclude all the
;; internal buffers (that is *scratch*, *Message*, etc...) you could
;; use the following regexps '("^ .*" "^\\*.*\\*").
;;
;; Buffers can also be excluded by major mode using the option
;; `nswbuff-exclude-mode-regexp'.
;;
;; The option `nswbuff-include-buffer-regexps' defines a list of regular
;; expressions of buffers that must be included, even if they already match a
;; regexp in `nswbuff-exclude-buffer-regexps'.  (The same could be done by using
;; more sophisticated exclude regexps, but this option keeps the regexps cleaner
;; and easier to understand.)
;;
;; You can further customize the list of switchable buffers by setting the
;; option `nswbuff-buffer-list-function' to a function that returns a list of
;; buffers.  Only the buffers returned by this function will be offered for
;; switching.  If this function returns nil, the buffers returned by
;; `buffer-list' is used instead.  Note that this list is still checked against
;; `nswbuff-exclude-buffer-regexps', `nswbuff-exclude-mode-regexp' and
;; `nswbuff-include-buffer-regexps'.
;;
;; One function already provided that makes use of this option is
;; `nswbuff-projectile-buffer-list', which returns the buffers of the current
;; [Projectile](http://batsov.com/projectile/) project plus any buffers in
;; `(buffer-list)' that match `nswbuff-include-buffer-regexps'.

;;; History:
;;

;;; Code:
(require 'timer)
(require 'seq)
(require 'subr-x)

;;; Options

(defgroup nswbuff nil
  "Quick switching between Emacs buffers."
  :group 'extensions
  :group 'convenience
  :prefix "nswbuff-")

(defcustom nswbuff-status-window-layout nil
  "Method used to ensure the switched buffer is always visible.
This occurs when the buffer list is larger than the status window
width.  The possible choices are:

- - 'Default'    If there is only one window in the frame (ignoring the
                 minibuffer one and the status window itself) the status
                 window height is adjusted.
                 Otherwise horizontal scrolling is used.
- - 'Scroll'     Horizontal scrolling is always used.
- - 'Adjust'     Only adjust the window height.
- - 'Minibuffer' Use the minibuffer."
  :group 'nswbuff
  :type '(choice (const :tag "Default"     nil)
                 (const :tag "Scroll"      scroll)
                 (const :tag "Adjust"      adjust)
                 (const :tag "Minibuffer"  minibuffer)))

(defcustom nswbuff-clear-delay 3
  "Time in seconds to delay before discarding the status window."
  :group 'nswbuff
  :type '(number :tag "Seconds"))

(defcustom nswbuff-recent-buffers-first t
  "Show recent buffers first.
If non-nil the buffer list is sorted by how recently the buffers were
used.  If nil, it is as a cyclic list with fixed order.  Note that
other commands (switch-to-buffer) still change the order."
  :group 'nswbuff
  :type 'boolean)

(defcustom nswbuff-separator " | "
  "String used to separate buffer names in the status line.
It is possible to include a newline character in order to obtain
a vertical buffer display."
  :group 'nswbuff
  :type 'string)

(defcustom nswbuff-header ""
  "Status line header string."
  :group 'nswbuff
  :type 'string)

(defcustom nswbuff-trailer ""
  "Status line trailer string."
  :group 'nswbuff
  :type 'string)

(defcustom nswbuff-status-window-at-top nil
  "If set, put the status window at the top of the current window."
  :group 'nswbuff
  :type 'boolean)

(define-obsolete-variable-alias 'nswbuff-window-min-text-height 'nswbuff-status-window-min-text-height "1.1")

(defcustom nswbuff-status-window-min-text-height 1
  "Minimum text height of the status window."
  :group 'nswbuff
  :type 'integer)

(defface nswbuff-default-face '((t (:inherit highlight)))
  "Default face used for buffer names."
  :group 'nswbuff)

(defface nswbuff-current-buffer-face '((t (:inherit font-lock-keyword-face)))
  "Face used to highlight the current buffer name."
  :group 'nswbuff)

(defface nswbuff-separator-face '((t (:inherit font-lock-comment-face)))
  "Face used for separators."
  :group 'nswbuff)

(defcustom nswbuff-exclude-buffer-regexps '("^ ")
  "List of regular expressions for excluded buffers.
The default setting excludes buffers whose name begin with a
blank character.  To exclude all the internal buffers (that is
*scratch*, *Message*, etc...) use the following regexps:
  (\"^ \" \"^\\*.*\\*\")."
  :group 'nswbuff
  :type '(repeat (regexp :format "%v")))

(defcustom nswbuff-this-frame-only t
  "If non-nil, skip buffers displayed in other visble or iconified frames.
This is a convient way of temporarily excluding a particluar
buffer from the cycle list."
  :group 'nswbuff
  :type 'boolean)

(defcustom nswbuff-exclude-mode-regexp ""
  "Regular expression matching major modes to skip when cycling."
  :group 'nswbuff
  :type '(string :tag "Regexp"))

(defcustom nswbuff-include-buffer-regexps nil
  "List of buffer names to always be included."
  :group 'nswbuff
  :type '(repeat (regexp :format "%v")))

(defcustom nswbuff-buffer-list-function nil
  "Function to obtain a list of switchable buffers.
The list of buffers returned by this function is further filtered
according to the options `nswbuff-exclude-buffer-regexps',
`nswbuff-exclude-mode-regexp' and
`nswbuff-include-buffer-regexps'.

The function should return a list of buffers or nil if no
eligible buffers exist.  When nil is returned, buffer switching
defaults to the standard `buffer-list' function.

One predefined function is `nswbuff-projectile-buffer-list',
which returns the buffers in the current projectile project plus
any buffers from the standard buffer list that match
`nswbuff-include-buffer-regexps'."
  :group 'nswbuff
  :type '(choice (const :tag "Use Default Buffer List" :value nil)
                 (const :tag "Use Project Buffer List" :value nswbuff-project-buffer-list)
                 (const :tag "Use Projectile Buffer List" :value nswbuff-projectile-buffer-list)
                 (function :tag "Use Custom Function")))

(declare-function project-current "ext:project")
(declare-function project-root "ext:project")

(defun nswbuff-project-buffer-list ()
  "Return the buffers of the current project.el project.
Added to the list are buffers that are not part of the current
project but that match `nswbuff-include-buffer-regexps'.  If the
current buffer is not part of a project, return nil."
  (when-let ((curr-proj (project-current)))
    (let ((conn (file-remote-p (project-root curr-proj))))
      (seq-filter (lambda (buf)
                    ;; Most of this defun is copied from upstream
                    ;; project.el. There, it is assumed that a project
                    ;; resides entirely on one host, and it is noted
                    ;; that they may relax that in the future.
                    ;; https://github.com/emacs-straight/project/blob/4072f35d85bf0a1c669329d66633e4819f497c1c/project.el#L1126-L1128
                    (and (equal conn
                                (file-remote-p (buffer-local-value 'default-directory buf)))
                         (or
                          (equal curr-proj
                                 (with-current-buffer buf
                                   (project-current)))
                          (nswbuff-include-p (buffer-name buf)))))
                  (buffer-list)))))

(defun nswbuff-projectile-buffer-list ()
  "Return the buffers of the current Projectile project.
Added to the list are buffers that are not part of the current
project but that match `nswbuff-include-buffer-regexps'.  If the
current buffer is not part of a project, return nil."
  (if (and (fboundp 'projectile-project-p)
           (projectile-project-p default-directory))
      (let ((projectile-buffers (projectile-project-buffers)))
        (dolist (buf (buffer-list) projectile-buffers)
          (if (and (nswbuff-include-p (buffer-name buf))
                   (not (memq buf projectile-buffers)))
              (setq projectile-buffers (append projectile-buffers (list buf))))))))

(defcustom nswbuff-pre-switch-hook nil
  "Standard hook containing functions to be called before a switch.
This option can be made buffer-local.  This may be useful for
handling modes that use more than one window for display.  For
example, VM uses one (small) window for its Summary buffer and
the remaining frame for the Presentation buffer.  Switching
buffers and retaining the window configuration doesn't make sense
in this context, so by setting the following hooks, these extra
windows can be deleted before switching:

\(defun my-vm-mode-hook ()
  \"Delete other windows before a switch.\"
  (make-local-hook 'swbuff-pre-switch-hook)
  (add-hook 'swbuff-pre-switch-hook #'delete-other-windows t t))

\(add-hook 'vm-mode-hook              #'my-vm-mode-hook)
\(add-hook 'vm-summary-mode-hook      #'my-vm-mode-hook)
\(add-hook 'vm-presentation-mode-hook #'my-vm-mode-hook)"
  :group 'nswbuff
  :type 'hook)

(defcustom nswbuff-start-with-current-centered nil
  "If t, center the current buffer in the buffer list."
  :group 'nswbuff
  :type 'boolean)

(defcustom nswbuff-delay-switch nil
  "If t, just show the buffer list upon first call.
When set, the functions `nswbuff-next-buffer' and
`nswbuff-previous-buffer' simply display the buffer list when
they are first called rather than switching buffers immediately.
Only a second call to either of these functions actually switches
the buffer."
  :group 'nswbuff
  :type 'boolean)

(defcustom nswbuff-display-intermediate-buffers nil
  "If t, show intermediate buffers while switching.
When set, each call to `nswbuff-next-buffer' or
`nswbuff-previous-buffer' in a sequence causes a new buffer to be
displayed.  If nil only the last buffer in the sequence is
actually displayed."
  :group 'nswbuff
  :type 'boolean)

(defcustom nswbuff-left ""
  "String placed immediately before a buffer name in the status line.
For example, try \"(\"."
  :group 'nswbuff
  :type 'string)

(defcustom nswbuff-right ""
  "String placed immediately after a buffer name in the status line.
For example, try \")\"."
  :group 'nswbuff
  :type 'string)

(defcustom nswbuff-special-buffers-re "^\\*"
  "Regular expression matching special buffers.
Buffers matching this regular expression are highlighted with
`nswbuff-special-buffers-face'."
  :group 'nswbuff
  :type 'string)

(defface nswbuff-special-buffers-face '((t (:inherit warning)))
  "Face for highlighting special buffers in the buffer list."
  :group 'nswbuff)

(defcustom nswbuff-mode-line-format nil
  "Mode line format of the nswbuff status window.
If set to nil, no mode line is displayed.  See `mode-line-format'
for a detailed format description."
  :group 'nswbuff
  :type 'sexp)

;;; Internals
;;
(defvar nswbuff-buffer-list nil "List of currently switchable buffers.")

;; Store the initial buffer-list, buffer, window, and frame at the
;; time the switch sequence was called.
(defvar nswbuff-initial-buffer-list nil "Initial buffer list when switching is initiated.")
(defvar nswbuff-initial-buffer nil "Initial buffer when switching is initiated.")
(defvar nswbuff-initial-window nil "Initial window when switching is initiated.")
(defvar nswbuff-initial-frame nil "Initial frame when switching is initiated.")

(defvar nswbuff-current-buffer nil "Current buffer being displayed during switching.")

(defvar-local nswbuff-exclude nil "Buffer-local variable that can be set to exclude a buffer from the buffer list.")
(put 'nswbuff-exclude 'safe-local-variable 'booleanp)

(defvar nswbuff-status-window nil
  "The status buffer window.
This window is saved in case any external code that runs on a
timer changes the current window.")

(defvar nswbuff-status-buffer nil
  "The status buffer.")

(defvar nswbuff-display-timer nil "The timer used to remove the status window after 'nswbuff-clear-delay'.")

(defvar nswbuff-override-map
  (let ((map (make-sparse-keymap)))
    map)
  "Override map for nswbuff.
This map becomes active whenever ‘nswbuff-switch-to-next-buffer’ or
‘nswbuff-switch-to-previous-buffer’ is invoked.  It can be used to
bind functions for buffer handling which then become available
during buffer switching.")

;; Make sure status buffer is reset when window layout is changed.
(add-variable-watcher
 'nswbuff-status-window-layout
 (lambda (_oldval _newval _operation _where)
   (setq nswbuff-status-buffer nil)))

(defun nswbuff-status-buffer-name ()
  "Name of the working buffer used by nswbuff to display the buffer list."
  (if (eq nswbuff-status-window-layout 'minibuffer) " *Minibuf-0*" " *nswbuff*"))

(defun nswbuff-get-status-buffer ()
  "Create or return the nswbuff status buffer."
  (if (buffer-live-p nswbuff-status-buffer)
      nswbuff-status-buffer
    (let ((buffer (get-buffer-create (nswbuff-status-buffer-name))))
      (with-current-buffer buffer
        (set (make-local-variable 'face-remapping-alist)
             '((default nswbuff-default-face)))
        (setq cursor-type nil)
        (setq mode-line-format nswbuff-mode-line-format)
        (setq nswbuff-status-buffer (current-buffer))))))

(defun nswbuff-initialize ()
  "Initialize nswbuff variables prior to a switch sequence."
  (setq nswbuff-buffer-list (nswbuff-buffer-list)
        nswbuff-initial-buffer-list nswbuff-buffer-list
        nswbuff-initial-buffer (car nswbuff-initial-buffer-list)
        nswbuff-initial-window (selected-window)
        nswbuff-initial-frame (selected-frame)))

(defun nswbuff-kill-this-buffer ()
  "Kill the current buffer but retain the status window.
This function can be bound to a key in `nswbuff-override-map' to kill
the current buffer without ending the buffer switching sequence."
  (interactive)
  (let ((dead-buffer nswbuff-current-buffer))
    (if (condition-case nil (kill-buffer dead-buffer))
        (progn
          (if nswbuff-initial-buffer
              (setq nswbuff-buffer-list
                    (delq dead-buffer nswbuff-buffer-list)
                    nswbuff-initial-buffer-list
                    (delq dead-buffer nswbuff-initial-buffer-list))
            (nswbuff-initialize))
          ;; Update status info based on remaining buffer list
          (cond
           ;; Two or more buffers left
           ((cadr nswbuff-buffer-list)
            (nswbuff-previous-buffer)
            (nswbuff-show-status-window))
           ;; Only one buffer let
           ((car nswbuff-buffer-list)
            (nswbuff-previous-buffer)
            (nswbuff-discard-status-window))
           ;; No buffer left
           (t (nswbuff-discard-status-window))))
      (nswbuff-discard-status-window))))

(defun nswbuff-buffer-list ()
  "Return the list of switchable buffers.
Buffers whose name matches `nswbuff-exclude-buffer-regexps' are
excluded, unless they match one of the regular expressions in
`include-buffer-regexps'.  If `nswbuff-this-frame-only' is
non-nil, buffers that are currently displayed in other visible or
iconified frames are also excluded."
  (let ((blist (seq-filter (lambda (buf)
                             (and (not (buffer-local-value 'nswbuff-exclude buf))
                                  (not (nswbuff-exclude-mode-p buf))
                                  (or (nswbuff-include-p (buffer-name buf))
                                      (not (nswbuff-exclude-p (buffer-name buf))))
                                  (not (and nswbuff-this-frame-only
                                            (nswbuff-in-other-frame-p buf)))))
                           (or (and nswbuff-buffer-list-function
                                    (funcall nswbuff-buffer-list-function))
                               (buffer-list)))))
    (when blist
      ;; add the current buffer if it would normally be skipped
      (unless (memq (current-buffer) blist)
        (push (current-buffer) blist)))
    blist))

(defun nswbuff-window-lines ()
  "Return the number of lines in the current buffer.
This number may be greater than the number of actual lines in the
buffer if any wrap on the display due to their length."
  (count-lines (point-min) (point-max)))

(defun nswbuff-adjust-window (&optional text-height)
  "Adjust window height to fit its buffer contents.
If optional TEXT-HEIGHT is non-nil adjust window height to this
value."
  (setq text-height (max nswbuff-status-window-min-text-height
                         (or text-height
                             (nswbuff-window-lines))))
  (if (fboundp 'set-window-text-height)
      (set-window-text-height nil text-height)
    (let ((height (window-height))
          (lines  (+ 2 text-height)))
      (enlarge-window (- lines height))))
  (goto-char (point-min)))

;; Used to prevent discarding the status window on some mouse event.
(defalias 'nswbuff-ignore 'ignore)

(defun nswbuff-scroll-window (position)
  "Adjust horizontal scrolling to ensure that POSITION is visible."
  (setq truncate-lines t)
  (let ((auto-hscroll-mode t))
    (goto-char position)))

;; Use mouse-1, mouse-3 on mode line buffer identification to
;; respectively switch to previous or next buffer.  And mouse-2 to
;; kill the current buffer.
(let ((map mode-line-buffer-identification-keymap))
  (define-key map [mode-line mouse-1] 'nswbuff-switch-to-previous-buffer)
  (define-key map [mode-line drag-mouse-1] 'nswbuff-ignore)
  (define-key map [mode-line down-mouse-1] 'nswbuff-ignore)
  (define-key map [mode-line mouse-2] 'nswbuff-kill-this-buffer)
  (define-key map [mode-line mouse-3] 'nswbuff-switch-to-next-buffer))

(defun nswbuff-one-window-p (window)
  "Return non-nil if there is only one window in this frame.
Ignore WINDOW and the minibuffer window."
  (let ((count 0))
    (walk-windows #'(lambda (w)
                      (or (eq w window) (setq count (1+ count)))))
    (= count 1)))

(defvar nswbuff-buffer-list-holder nil
  "Hold the current displayed buffer list.")

(defun nswbuff-layout-status-line (window bcurr)
  "Layout a status line in WINDOW current buffer.
BCURR is the buffer name to highlight."
  (let* ((blist nswbuff-initial-buffer-list)
         (head  (or nswbuff-header    "" ))
         (separ (or nswbuff-separator " "))
         (trail (or nswbuff-trailer   "" ))
         (left  (or nswbuff-left     "" ))
         (right (or nswbuff-right     "" ))
         (width (window-width window))
         (lines 0)
         (adjust (or (eq nswbuff-status-window-layout 'adjust)
                     (nswbuff-one-window-p window)))
         ;; Okay, it's crazy logic but it works. :-)
         (half-way (1- (/
                        (if (= (% (length blist) 2) 0) ;; If even ...
                            (length blist)
                          (1+ (length blist))) ;; make it even.
                        2)))
         start end buffer bname fillr)
    (when nswbuff-start-with-current-centered
      ;; Rearrange blist so that the first elt is in the middle
      (setq blist (append (last blist half-way)      ;; last half
                          (butlast blist half-way)))) ;; first half
    (save-selected-window
      (select-window window)
      (erase-buffer)
      (setq start (point))
      (insert head)
      (if (> (point) start)
          (set-text-properties
           start (point) '(face nswbuff-separator-face)))
      (while blist
        (setq buffer (car blist)
              blist  (cdr blist))
        (when (buffer-live-p buffer)
          (setq bname (buffer-name buffer)
                start (point)
                fillr (if blist separ trail))
          ;; Add a newline if we will run out of space.
          (when (and adjust
                     (> (- (+ start (length bname)
                              (length (concat left fillr right)))
                           (* lines width))
                        width))
            (newline)
            (setq start (point)
                  lines (1+ lines)))
          (insert left)
          (if (> (point) start)
              (set-text-properties
               start (point) '(face nswbuff-separator-face)))
          (setq start (point))
          (insert bname)
          ;; Highlight it if it is the current one.
          (cond
           ((string-equal bname bcurr)
            (setq end (point))
            (set-text-properties
             start end '(face nswbuff-current-buffer-face)))
           ((and (not (string= nswbuff-special-buffers-re ""))
                 (string-match-p nswbuff-special-buffers-re bname))
            (set-text-properties
             start (point) '(face nswbuff-special-buffers-face)))
           (t
            (set-text-properties
             start (point) '(face nswbuff-default-face))))
          (setq start (point))
          (insert right)
          (if (> (point) start)
              (set-text-properties
               start (point) '(face nswbuff-separator-face)))
          (setq start (point))
          (insert fillr)
          (if (> (point) start)
              (set-text-properties
               start (point) '(face nswbuff-separator-face)))))
      (if adjust
          (nswbuff-adjust-window)
        (nswbuff-adjust-window 1)
        (nswbuff-scroll-window end)))))

(defun nswbuff-show-status-window ()
  "Pop-up the nswbuff status window at the bottom of the selected window.
The status window shows the list of switchable buffers where the
switched one is highlighted using `nswbuff-current-buffer-face'.
It is automatically discarded after any command is executed or
after the delay specified by `nswbuff-clear-delay'."
  (if nswbuff-initial-buffer-list
      (let ((buffer-name (buffer-name nswbuff-current-buffer))
            (window-min-height 1)
            (cursor-in-non-selected-windows nil))
        (with-current-buffer (nswbuff-get-status-buffer)
          (let ((window (or (and (eq nswbuff-status-window-layout 'minibuffer) (minibuffer-window))
                            (get-buffer-window (nswbuff-status-buffer-name))
                            (if nswbuff-status-window-at-top
                                (split-window nil (- nswbuff-status-window-min-text-height) 'above)
                              (split-window-vertically (- nswbuff-status-window-min-text-height))))))
            ;; If we forget this we may end up with multiple status
            ;; windows (kal).
            (setq nswbuff-status-window window)
            (set-window-buffer window (current-buffer))
            (nswbuff-layout-status-line window buffer-name)
            (set-transient-map nswbuff-override-map nil #'nswbuff-maybe-discard-status-window)
            (if (timerp nswbuff-display-timer)
                (cancel-timer nswbuff-display-timer))
            (setq nswbuff-display-timer
                  (run-with-timer nswbuff-clear-delay nil
                                  #'nswbuff-discard-status-window)))))
    (nswbuff-discard-status-window)
    (message "No buffers eligible for switching.")))

(defun nswbuff-in-other-frame-p (buffer)
  "Return non-nil if BUFFER is being displayed in another visible frame."
  (let ((found-in-other-frame nil)
        (window nil)
        (window-list (get-buffer-window-list buffer nil 0)))
    (while (and (setq window (car window-list))
                (not found-in-other-frame))
      (unless (eq (window-frame window) nswbuff-initial-frame)
        (setq found-in-other-frame t))
      (pop window-list))
    found-in-other-frame))

(defun nswbuff-exclude-mode-p (buffer)
  "Return non-nil if BUFFER should be excluded from the buffer list.
This is the case if BUFFER's major mode matches one of the
regexps in `nswbuff-exclude-mode-regexps'."
  (unless (string-equal "" nswbuff-exclude-mode-regexp)
    (with-current-buffer buffer
      (string-match-p nswbuff-exclude-mode-regexp
                      (symbol-name major-mode)))))

(defun nswbuff-exclude-p (buffer)
  "Return non-nil if BUFFER should be excluded from the buffer list.
BUFFER should be a buffer name.  It is tested against the regular expressions in
`nswbuff-exclude-buffer-regexps', and if one matches, BUFFER is excluded."
  (let ((rl (cons (regexp-quote (nswbuff-status-buffer-name))
                  (delete "" nswbuff-exclude-buffer-regexps))))
    (while (and rl (car rl) (not (string-match-p (car rl) buffer)))
      (setq rl (cdr rl)))
    (not (null rl))))

(defun nswbuff-include-p (name)
  "Return non-nil if buffer NAME can be included in the buffer list.
BUFFER should be a buffer name.  It is tested against the regular expressions in
`nswbuff-include-buffer-regexps', and if one matches, BUFFER is included."
  (let ((rl (delete "" nswbuff-include-buffer-regexps)))
    (while (and rl (car rl) (not (string-match-p (car rl) name)))
      (setq rl (cdr rl)))
    (not (null rl))))

(defun nswbuff-maybe-discard-status-window ()
  "Discard the status window conditionally."
  (when (eq (selected-frame) nswbuff-initial-frame)
    (if (timerp nswbuff-display-timer)
        (cancel-timer nswbuff-display-timer))
    (setq nswbuff-display-timer nil)
    (cond
     ;; If this-command is a command bound in `nswbuff-override-map', we renew the
     ;; timer and the map.
     ((where-is-internal this-command (list nswbuff-override-map))
      (setq nswbuff-display-timer
            (run-with-timer nswbuff-clear-delay nil
                            #'nswbuff-discard-status-window))
      (set-transient-map nswbuff-override-map nil #'nswbuff-maybe-discard-status-window))
     ;; If this-command is a buffer-switching command, we do nothing.
     ((memq this-command '(nswbuff-switch-to-previous-buffer
                           nswbuff-switch-to-next-buffer
                           nswbuff-ignore))
      t)
     ;; If this-command is anything else, we discard the status window.
     (t (nswbuff-discard-status-window)))))

(defun nswbuff-discard-status-window ()
  "Discard the status window.
This function is called directly by the nswbuff timer."
  (let ((buffer (get-buffer (nswbuff-status-buffer-name)))
        (buffer-list (nreverse nswbuff-buffer-list)))
    ;; Cleanup status window and status buffer
    (if (eq nswbuff-status-window-layout 'minibuffer)
        (with-current-buffer buffer (erase-buffer))
      (when (window-live-p nswbuff-status-window)
        (delete-window nswbuff-status-window))
      (when buffer
        (kill-buffer buffer)))
    (unwind-protect
        (when (and nswbuff-initial-buffer nswbuff-current-buffer)
          (save-window-excursion
            ;; Because this may be called from a timer we have to be really
            ;; careful that we are in the right frame, window and buffer at that
            ;; time --- other timers (e.g., those called by speedbar) may put us
            ;; elsewhere. :-)
            (select-frame nswbuff-initial-frame)
            (select-window nswbuff-initial-window)
            ;; Reset visit order to what it was before the sequence began.
            (while (setq buffer (car buffer-list))
              (switch-to-buffer buffer)
              (setq buffer-list (cdr buffer-list))))
          ;; Then switch between the first and last buffers in the sequence.
          (and nswbuff-initial-buffer
               (switch-to-buffer nswbuff-initial-buffer))
          (and nswbuff-current-buffer
               (switch-to-buffer nswbuff-current-buffer)))
      ;; Protect forms.
      (setq nswbuff-initial-buffer      nil
            nswbuff-initial-buffer-list nil
            nswbuff-current-buffer      nil
            nswbuff-initial-frame       nil
            nswbuff-initial-window      nil
            nswbuff-status-window       nil))))

(defun nswbuff-previous-buffer ()
  "Display and activate the buffer at the end of the buffer list."
  (let ((buf (car (last nswbuff-buffer-list))))
    (when buf
      (when nswbuff-display-intermediate-buffers
        (switch-to-buffer buf t))
      (setq nswbuff-current-buffer buf)
      (setq nswbuff-buffer-list (butlast nswbuff-buffer-list))
      (setq nswbuff-buffer-list (cons buf nswbuff-buffer-list)))))

(defun nswbuff-next-buffer ()
  "Display and activate the next buffer in the buffer list."
  (let ((buf (car nswbuff-buffer-list)))
    (when buf
      (setq nswbuff-buffer-list (cdr nswbuff-buffer-list))
      (setq nswbuff-buffer-list (append nswbuff-buffer-list (list buf)))
      (setq nswbuff-current-buffer (car nswbuff-buffer-list))
      (when nswbuff-display-intermediate-buffers
        (switch-to-buffer (car nswbuff-buffer-list) t)))))  ;; no record

;;; Commands

;;;###autoload
(defun nswbuff-switch-to-previous-buffer ()
  "Switch to the previous buffer in the buffer list."
  (interactive)
  (run-hooks 'nswbuff-pre-switch-hook)
  (if nswbuff-initial-buffer
      (and nswbuff-delay-switch (nswbuff-previous-buffer))
    (nswbuff-initialize))
  (or nswbuff-delay-switch (nswbuff-previous-buffer))
  (nswbuff-show-status-window))

;;;###autoload
(defun nswbuff-switch-to-next-buffer ()
  "Switch to the next buffer in the buffer list."
  (interactive)
  (run-hooks 'nswbuff-pre-switch-hook)
  (if nswbuff-initial-buffer
      (nswbuff-next-buffer)
    ;; First call in the sequence.
    (nswbuff-initialize)
    (unless nswbuff-delay-switch
      (nswbuff-next-buffer)))
  (nswbuff-show-status-window))

(provide 'nswbuff)

;;; nswbuff.el ends here
