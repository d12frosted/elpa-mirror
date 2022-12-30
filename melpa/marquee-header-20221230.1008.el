;;; marquee-header.el --- Code interface for displaying marquee in header  -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2022  Shen, Jen-Chieh
;; Created date 2019-07-21 12:03:34

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/jcs-elpa/marquee-header
;; Package-Version: 20221230.1008
;; Package-Commit: 1fee5bbec486d0755954f5cafda67f342dc7daa1
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: wp animation marquee

;; This file is NOT part of GNU Emacs.

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

;;; Commentary:
;;
;; Code interface for displaying marquee in header.
;;

;;; Code:

(require 'cl-lib)
(require 'rect)

(defgroup marquee-header nil
  "Code interface for displaying marquee in header."
  :prefix "marquee-header-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/marquee-header"))

(defcustom marquee-header-display-time 10.0
  "How long you want to show the marquee message."
  :type 'float
  :group 'marquee-header)

(defcustom marquee-header-direction 'left
  "The direction this marquee is going towards to."
  :type '(choice (const :tag "none" none)
                 (const :tag "left" left)
                 (const :tag "right" right))
  :group 'marquee-header)

(defcustom marquee-header-loop nil
  "Loop the animation if non-nil."
  :type 'boolean
  :group 'marquee-header)

(defcustom marquee-header-after-display-hook nil
  "Hooks run after animation is done displayed."
  :type 'hook
  :group 'marquee-header)

(defvar-local marquee-header--message ""
  "Current message.")

(defvar-local marquee-header--message-decoration ""
  "Decorate the current message for displaying animation.")

(defvar-local marquee-header--time 0.0
  "Current show time.")

(defvar-local marquee-header--speed 0.0
  "The animation speed for time calculation.")

(defvar-local marquee-header--timer nil
  "Timer pointer for updating marquee animation.")

(defvar-local marquee-header--direction nil
  "Record the marquee direction.")

(defvar-local marquee-header--loop nil
  "Loop flag.")

(defvar-local marquee-header--previous-header-line-format nil
  "Record down the previous header format.")

(defvar-local marquee-header--frame-counter 0
  "Count the frame.")

(defun marquee-header--cancel-timer ()
  "Cancel all timer for marquee."
  (when (timerp marquee-header--timer)
    (cancel-timer marquee-header--timer))
  (setq marquee-header--timer nil))

(defun marquee-header--revert-header ()
  "Reset header line format to previous value."
  (setq-local header-line-format marquee-header--previous-header-line-format)
  (setq marquee-header--previous-header-line-format nil))

(defun marquee-header--cleanup-display ()
  "Cleanup the animation display."
  (marquee-header--revert-header)
  (marquee-header--cancel-timer)
  (if marquee-header--loop
      (marquee-header-notify marquee-header--message
                             :time marquee-header--time
                             :direction marquee-header--direction
                             :loop marquee-header--loop)
    (setq marquee-header--message nil))
  (run-hooks 'marquee-header-after-display-hook))

(defmacro marquee-header--with-live-buffer (buffer &rest body)
  "Like macro `with-current-buffer' but ensure the BUFFER.

Rest argument BODY is the exeuction."
  (declare (indent 1))
  `(when (buffer-live-p ,buffer) (with-current-buffer ,buffer ,@body)))

(defun marquee-header--display-header (buffer)
  "Display the header animation in the BUFFER."
  (marquee-header--with-live-buffer buffer
    (cond
     ((equal marquee-header--direction 'none)
      (setq header-line-format marquee-header--message)  ; Just displayed it directly.
      (setq marquee-header--timer
            (run-at-time marquee-header--time nil
                         'marquee-header--cleanup-display)))
     (t
      (setq marquee-header--speed (/ (float marquee-header--time) (window-width)))
      (cl-case marquee-header--direction
        (`left
         ;; Remove the first character.
         (setq marquee-header--message-decoration
               (substring marquee-header--message-decoration
                          1 (length marquee-header--message-decoration))))
        (`right
         (setq marquee-header--message-decoration
               (concat " " marquee-header--message-decoration))))
      (setq header-line-format marquee-header--message-decoration)
      (setq marquee-header--frame-counter (1- marquee-header--frame-counter))
      (if (= 0 marquee-header--frame-counter)
          (marquee-header--cleanup-display)
        (marquee-header--cancel-timer)
        (setq marquee-header--timer
              (run-at-time marquee-header--speed nil
                           'marquee-header--display-header buffer)))))))

(defun marquee-header-stop ()
  "Stop display."
  (let (marquee-header--loop)
    (marquee-header--cleanup-display)))

(defun marquee-header--max-window-width (&optional buffer-or-name)
  "Return max window width from a BUFFER-OR-NAME."
  (let ((width 0))
    (dolist (window (get-buffer-window-list buffer-or-name))
      (with-selected-window window
        (setq width (max width (window-width)))))
    width))

;;;###autoload
(cl-defun marquee-header-notify (msg &key time direction loop)
  "Show the marquee notification with MSG.

- TIME is the time that will show on screen.
- DIRECTION is for marquee animation.
- LOOP weather to loop the animation."
  (unless marquee-header--message
    (setq marquee-header--previous-header-line-format header-line-format))
  (cond ((null msg)
         (error "Message can't be null"))
        ((and (stringp msg) (string-empty-p msg))
         (error "Message can't be empty string"))
        (t
         (setq marquee-header--message msg)))
  (setq marquee-header--time (if (numberp time) time
                               marquee-header-display-time))
  (setq marquee-header--direction (if (memq direction '(none left right))
                                      direction
                                    marquee-header-direction))
  (setq marquee-header--loop (if (memq loop '(t nil))
                                 loop
                               marquee-header-loop))
  (let ((win-width (marquee-header--max-window-width)))
    (cl-case marquee-header--direction
      (`left (setq marquee-header--message-decoration (concat (spaces-string win-width) marquee-header--message)))
      (`right (setq marquee-header--message-decoration marquee-header--message)))
    (setq marquee-header--frame-counter (+ win-width (length marquee-header--message)))  ; Reset frame counter.
    (marquee-header--display-header (current-buffer))))

(provide 'marquee-header)
;;; marquee-header.el ends here
