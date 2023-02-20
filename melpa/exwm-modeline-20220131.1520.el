;;; exwm-modeline.el ---  A modeline segment for EXWM workspaces -*- lexical-binding: t -*-

;; Copyright (C) 2021-2022 Korytov Pavel
;; Copyright (C) 2021 Ellis Kenyő
;; Copyright (C) 2008-2020 Natalie Weizenbaum <nex342@gmail.com>

;; Author: Korytov Pavel <thexcloud@gmail.com>
;; Maintainer: Korytov Pavel <thexcloud@gmail.com>
;; Version: 0.1.3
;; Package-Version: 20220131.1520
;; Package-Commit: 86bce1d91089b9a1517e1abfca86bac47be91be3
;; Package-Requires: ((emacs "27.1") (exwm "0.26"))
;; Homepage: https://github.com/SqrtMinusOne/exwm-modeline

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A modeline segment to display exwm workspaces.
;;
;; Features:
;; - Supports `exwm-randr' to display only of workspaces related to
;;   the the current monitor.
;; - The segment is clickable.
;;
;; Take a look at `exwm-modeline-mode' for more info.

;;; Code:
(require 'exwm)
(require 'exwm-randr)
(require 'exwm-workspace)
(require 'exwm-manage)

(defgroup exwm-modeline nil
  "A modeline segment to show EXWM workspaces."
  :group 'mode-line)

(defcustom exwm-modeline-dividers '("[" "]" "|")
  "Plist of strings used to create the string shown in the modeline.

The first string is the start of the modestring, second is the
closing of the modestring, and the last is the divider between
workspaces."
  :group 'exwm-modeline
  :type '(list (string :tag "Open")
               (string :tag "Close")
               (string :tag "Divider")))

(defcustom exwm-modeline-short nil
  "When set, display only the current workspace in the modeline."
  :group 'exwm-modeline
  :type 'boolean
  :set (lambda (sym value)
         (set-default sym value)
         (when (bound-and-true-p exwm-modeline-mode)
           (exwm-modeline-update))))

(defcustom exwm-modeline-randr t
  "When set, only show workspaces on the current monitor."
  :group 'exwm-modeline
  :type 'boolean
  :set (lambda (sym value)
         (set-default sym value)
         (when (bound-and-true-p exwm-modeline-mode)
           (exwm-modeline-update))))

(defcustom exwm-modeline-display-urgent t
  "When set, display the urgent status in the modeline.

With that set, the modeline will be updated on every workspace
switch, so the number of updates is increased significantly."
  :group 'exwm-modeline
  :type 'boolean
  :set (lambda (sym value)
         (set-default sym value)
         (when (bound-and-true-p exwm-modeline-mode)
           (exwm-modeline-update)
           (if value
               (progn
                 (advice-add #'exwm--update-hints :after #'exwm-modeline--urgency-advice)
                 (add-hook 'exwm-workspace-switch-hook #'exwm-modeline--urgency-advice))
             (advice-remove #'exwm--update-hints #'exwm-modeline--urgency-advice)
             (remove-hook 'exwm-workspace-switch-hook #'exwm-modeline--urgency-advice)))))

(defface exwm-modeline-current-workspace
  ;; I'd rather :inherit and override warning there, but well
  `((t :foreground ,(face-foreground 'warning) :weight bold))
  "Face for the current workspace."
  :group 'exwm-modeline)

(defface exwm-modeline-populated-workspace
  '((t (:inherit success)))
  "Face for any workspace populated with an X window."
  :group 'exwm-modeline)

(defface exwm-modeline-empty-workspace
  `((t (:inherit mode-line)))
  "Face for any workspace without an X window."
  :group 'exwm-modeline)

(defface exwm-modeline-urgent-workspace
  '((t (:inherit error)))
  "Face for any workspace that is tagged as urgent by X."
  :group 'exwm-modeline)

(defun exwm-modeline--urgent-p (frame)
  "Determine if FRAME is tagged as urgent.

Always return nil if `exwm-modeline-display-urgent' is not set."
  (when exwm-modeline-display-urgent
    (frame-parameter frame 'exwm-urgency)))

(defun exwm-modeline--populated-p (frame)
  "Determine if FRAME has any X windows."
  (cl-loop for item in exwm--id-buffer-alist
           if (eq frame (buffer-local-value 'exwm--frame (cdr item)))
           return t))

(defun exwm-modeline--click (event)
  "Process a click EVENT on the modeline segment."
  (interactive "e")
  (when-let
      (target
       (cl-loop with name = (format "%s" (car (posn-string (event-start event))))
                for i from 0 to (1- (length exwm-workspace--list))
                if (string-equal (funcall exwm-workspace-index-map i) name)
                return i))
    (exwm-workspace-switch target)))

(defconst exwm-modeline-line-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line mouse-1] #'exwm-modeline--click)
    map)
  "A keymap for the modeline segment.")

(defun exwm-modeline--format-list (workspace-list)
  "Format the modestring for the current frame.

WORKSPACE-LIST is the list of frames to display."
  (cl-loop for frame in workspace-list
           for i from 0 to (length workspace-list)
           for workspace-name = (funcall exwm-workspace-index-map
                                         (exwm-workspace--position frame))
           with current-frame = (selected-frame)
           if (= i 0) collect (nth 0 exwm-modeline-dividers)
           collect
           (propertize workspace-name
                       'face
                       (cond ((exwm-modeline--urgent-p frame)
                              'exwm-modeline-urgent-workspace)
                             ((eq frame current-frame)
                              'exwm-modeline-current-workspace)
                             ((exwm-modeline--populated-p frame)
                              'exwm-modeline-populated-workspace)
                             (t 'exwm-modeline-empty-workspace))
                       'local-map (unless (eq frame current-frame)
                                    exwm-modeline-line-map)
                       'mouse-face (unless (eq frame current-frame)
                                     'mode-line-highlight))
           if (= i (1- (length workspace-list)))
           collect (nth 1 exwm-modeline-dividers)
           else collect (nth 2 exwm-modeline-dividers)))

(defun exwm-modeline--randr-workspaces ()
  "Get workspaces on the same monitor as current frame."
  (if-let ((monitor (plist-get exwm-randr-workspace-monitor-plist
                               (cl-position (selected-frame)
                                            exwm-workspace--list)))
           ;; This list of frame actually can be wrongly ordered,
           ;; hence the second loop.  The number of values is quite
           ;; small, so it's not like o(n^2) can cause any issues.
           (frames (cl-loop for (key value) on exwm-randr-workspace-monitor-plist
                            by 'cddr
                            if (string-equal value monitor)
                            collect (nth key exwm-workspace--list))))
      (cl-loop for frame in exwm-workspace--list
               if (member frame frames)
               collect frame)
    (cl-loop with indices = (cl-loop
                             for (key _) on exwm-randr-workspace-monitor-plist
                             by 'cddr collect key)
             for i from 0 to (1- (length exwm-workspace--list))
             for frame in exwm-workspace--list
             unless (member i indices)
             collect frame)))

(defun exwm-modeline--format ()
  "Format a modeline string for the current workspace."
  (exwm-modeline--format-list
   (cond ((or exwm-modeline-short exwm--floating-frame)
          (list (selected-frame)))
         (exwm-modeline-randr (exwm-modeline--randr-workspaces))
         (t exwm-workspace--list))))

(defun exwm-modeline-update ()
  "Update EXWM modefine for every frame."
  (interactive)
  (cl-loop for frame in exwm-workspace--list
           do (with-selected-frame frame
                (set-frame-parameter nil 'exwm-modeline--string
                                     (exwm-modeline--format)))))

(defun exwm-modeline-segment ()
  "Get a modeline string for the current EXWM frame."
  (frame-parameter nil 'exwm-modeline--string))

(defun exwm-modeline--unmanage-advice (&rest _)
  "Update the modeline after unmanaging a window.

This function is meant to be advised :after
`exwm-manage--unmanage-window', because that's when a workspace can
lose all its X windows and thus may become \"unpopulated\",i.e. the
face in the segment has to change."
  (exwm-modeline-update))

(defun exwm-modeline--urgency-advice (&rest _)
  "Update the modeline after a change in the urgency status.

This function is meant to be advised :after `exwm--update-hints' and
be in the hook `exwm-workspace-switch-hook'.

The modeline is updated if `exwm-workspace--switch-history-outdated'
is set to t, because EXWM sets that variable whenever a window updates
it urgency status.  To avoid running the function too often,
`exwm-workspace--update-switch-history' is also called, which resets
the variable.

However, one issue with the mentioned variable is that it is also
set whenever the workspace is switched, so using that advice also
increases the number of required updates.  Optimizing that would
require more substantial modifications to EXWM code, so in this
package applying that advice is made optional with the
`exwm-modeline-display-urgent' variable.

Because the first function is very much critical for the normal
functioning of EXWM, the entire thing is wrapped in
`with-demoted-errors'."
  (with-demoted-errors "Error in exwm-modeline--urgency-advice: %S"
    (when exwm-workspace--switch-history-outdated
      (exwm-modeline-update)
      (exwm-workspace--update-switch-history))))

;;;###autoload
(define-minor-mode exwm-modeline-mode
  "A mode for displaying EXWM workspaces in the modeline.

Make sure to call this after EXWM was initialized, for instance
in `exwm-init-hook'.

By default, the mode displays all the workspaces on the current
monitor.  To display only the current workspace, enable
`exwm-modeline-short', and to disable the filtering by the
monitor, disable `exwm-modeline-randr'.

If `exwm-modeline-display-urgent' is set, the mode also displays
if the workspace has a window market as urgent.  However, this
option forces the modeline to update after every workspace
switch, so it may be wise to disable that in case of performance
issues.

Also, take a look at the `exwm-modeline' group for faces
customization.

This implementation intends to reduce the count of times of
evaluating the modestring; the rendered modestring is saved as a
frame parameter, and `exwm-modeline-segment' just returns it.

The update itself is done via the `exwm-modeline-update'
function.  You may need to run it manually after updating the
parameters, but other than that, this mode should cover all the
cases when the workspace list changes."
  :global t
  (if exwm-modeline-mode
      (progn
        (exwm-modeline-update)
        (add-to-list 'global-mode-string '(:eval (exwm-modeline-segment)))
        (add-hook 'exwm-workspace-list-change-hook #'exwm-modeline-update)
        (add-hook 'exwm-randr-refresh-hook #'exwm-modeline-update)
        (add-hook 'exwm-manage-finish-hook #'exwm-modeline-update)
        (advice-add #'exwm-manage--unmanage-window
                    :after #'exwm-modeline--unmanage-advice)
        (when exwm-modeline-display-urgent
          (advice-add #'exwm--update-hints :after #'exwm-modeline--urgency-advice)
          (add-hook 'exwm-workspace-switch-hook #'exwm-modeline--urgency-advice)))
    (setq global-mode-string (delete '(:eval (exwm-modeline-segment))
                                     global-mode-string))
    (remove-hook 'exwm-workspace-list-change-hook #'exwm-modeline-update)
    (remove-hook 'exwm-randr-refresh-hook #'exwm-modeline-update)
    (remove-hook 'exwm-manage-finish-hook #'exwm-modeline-update)
    (advice-remove #'exwm-manage--unmanage-window
                   #'exwm-modeline--unmanage-advice)
    (advice-remove #'exwm--update-hints #'exwm-modeline--urgency-advice)
    (remove-hook 'exwm-workspace-switch-hook #'exwm-modeline--urgency-advice)))

(provide 'exwm-modeline)
;;; exwm-modeline.el ends here
