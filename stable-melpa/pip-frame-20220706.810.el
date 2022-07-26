;;; pip-frame.el --- Display and manage a PIP frame  -*- lexical-binding: t -*-

;; Copyright (C) 2022 Milan Zamazal <pdm@zamazal.org>

;; Author: Milan Zamazal <pdm@zamazal.org>
;; Version: 1
;; Package-Version: 20220706.810
;; Package-Commit: e8b16420f8e3992b068e17d2936b2b2102ed039e
;; Package-Requires: ((emacs "25.1"))
;; Keywords: frames
;; URL: https://git.zamazal.org/pdm/pip-frame

;; COPYRIGHT NOTICE
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Display a floating Emacs frame with selected buffers.
;; Similar to PIP on screens.  Probably most useful in EXWM.
;;
;; Use `M-x pip-frame-add-buffer' to create the frame and add
;; additional buffers to it and remove the buffers with
;; `M-x pip-frame-remove-buffer' or close the whole frame with
;; `M-x pip-frame-delete-frame'.

;;; Code:

(require 'cl-lib)

(defgroup pip-frame ()
  "Display PIP frame."
  :group 'frames)

(defcustom pip-frame-scale 4
  "How many times to shrink the PIP frame relative to the display size."
  :type 'number
  :group 'pip-frame)

(defcustom pip-frame-font-scale 2
  "How many times to reduce the font size in the PIP frame."
  :type 'number
  :group 'pip-frame)

(defcustom pip-frame-move-step 0.1
  "Movement step relative to the display size in the given direction.

Usually, the value should be larger than 0 and much smaller than 1."
  :type 'number
  :group 'pip-frame)

(defcustom pip-frame-parameters
  '((left . 0.9)
    (top .  0.9)
    (tab-bar-lines . 0)
    (minibuffer . nil))
  "Alist of frame parameters to use for the PIP frame.
The frame size is determined automatically using `pip-frame-scale'
custom option but it can be overriden here."
  :type '(alist :key-type symbol :value-type sexp)
  :group 'pip-frame)

(defcustom pip-frame-face-attributes '()
  "Alist of face attributes to modify `default' face in the PIP frame."
  :type '(alist :key-type symbol :value-type sexp)
  :group 'pip-frame)

(defcustom pip-frame-temporary-buffer-seconds 10
  "Number of seconds to keep a buffer displayed temporarily by default."
  :type 'number
  :group 'pip-frame)

(defvar pip-frame--name "PIP-frame")

(defun pip-frame--get-frame (&optional no-error)
  (let ((frame (cl-find pip-frame--name (frame-list)
                        :key (lambda (f) (frame-parameter f 'name)))))
    (or frame
        (unless no-error
          (error "No PIP frame")))))

(defun pip-frame--make-frame (buffer)
  (let ((frame (make-frame `((name . ,pip-frame--name)
                             (unsplittable . t)
                             ,@pip-frame-parameters
                             (width . ,(/ 1.0 pip-frame-scale))
                             (height . ,(/ 1.0 pip-frame-scale)))))
        (frame-inhibit-implied-resize t)
        (face-height (round (/ (face-attribute 'default :height) pip-frame-font-scale))))
    (set-face-attribute 'default frame :height face-height)
    (dolist (p pip-frame-face-attributes)
      (set-face-attribute 'default frame (car p) (cdr p)))
    (set-window-buffer (car (window-list frame)) buffer)
    frame))

(defun pip-frame-delete-frame ()
  "Delete the PIP frame."
  (interactive)
  (delete-frame (pip-frame--get-frame)))

(defun pip-frame--buffers ()
  (mapcar #'window-buffer (window-list (pip-frame--get-frame))))

(defun pip-frame--add-additional-buffer (buffer temporary)
  (let ((windows (window-list (pip-frame--get-frame))))
    (unless (and temporary
                 (cl-find buffer windows :key #'window-buffer :test #'eq))
      (let* ((sizes (mapcar (lambda (w)
                              (let ((width (window-body-width w t))
                                    (height (window-body-height w t)))
                                (cons (+ (* width width) (* height height))
                                      w)))
                            windows))
             (largest (cdr (cl-first (cl-sort sizes #'> :key #'car))))
             (side (if (> (window-body-width largest t)
                          (* 2 (window-body-height largest t)))
                       'right
                     'below))
             (new-window (split-window largest nil side)))
        (set-window-buffer new-window buffer)))))

(defvar pip-frame--buffer-timers '())

(defun pip-frame--make-buffer-temporary (buffer seconds)
  (when (eq seconds t)
    (setq seconds pip-frame-temporary-buffer-seconds))
  (let ((timer (run-with-timer seconds nil #'pip-frame-remove-buffer buffer)))
    (setq pip-frame--buffer-timers (cons (cons buffer timer)
                                         pip-frame--buffer-timers))))

(defun pip-frame--delete-buffer-timer (buffer)
  (let ((timer (alist-get buffer pip-frame--buffer-timers)))
    (when timer
      (cancel-timer timer)
      (setq pip-frame--buffer-timers
            (assq-delete-all buffer pip-frame--buffer-timers)))))
  
;;;###autoload
(defun pip-frame-add-buffer (&optional buffer-or-name temporary)
  "Add a buffer to the PIP frame.
If there is no PIP frame then create one.
If BUFFER-OR-NAME is specified, add the given buffer to the frame,
otherwise add the current buffer.
If TEMPORARY is given, display the buffer in the PIP frame for that
many seconds and then remove it from the frame.  If t, display it for
`pip-frame-temporary-buffer-seconds'.
A buffer can be added and displayed multiple times in the frame.  If
TEMPORARY is non-nil, the buffer is not displayed again if it is
already present."
  (interactive)
  (let ((frame (pip-frame--get-frame t))
        (buffer (get-buffer (or buffer-or-name (current-buffer)))))
    (if frame
        (progn
          (when temporary
            (pip-frame--delete-buffer-timer buffer))
          (pip-frame--add-additional-buffer buffer temporary))
      (pip-frame--make-frame buffer))
    (when temporary
      (pip-frame--make-buffer-temporary buffer temporary))))

(defun pip-frame-remove-buffer (buffer-or-name)
  "Remove buffer named BUFFER-OR-NAME from the PIP frame.
If it is the last buffer in the PIP frame, delete the frame.
If the buffer is not present in the PIP frame, do nothing."
  (interactive (list (completing-read "Remove PIP buffer: "
                                      (mapcar #'buffer-name (pip-frame--buffers))
                                      nil t)))
  (let* ((windows (window-list (pip-frame--get-frame)))
         (buffer (get-buffer buffer-or-name))
         (windows-to-delete (cl-remove buffer windows
                                       :key #'window-buffer
                                       :test-not #'eq)))
    (if (= (length windows-to-delete) (length windows))
        (pip-frame-delete-frame)
      (seq-do #'delete-window windows-to-delete))))

(defun pip-frame--move (x y)
  (let ((frame (pip-frame--get-frame)))
    (set-frame-parameter frame 'left (+ (frame-parameter frame 'left) x))
    (set-frame-parameter frame 'top (+ (frame-parameter frame 'top) y))))

(defun pip-frame--move-step (vertical)
  (if (integerp pip-frame-move-step)
      pip-frame-move-step
    (let ((workarea (cdr (assoc 'workarea (cl-first (display-monitor-attributes-list))))))
      (round (* pip-frame-move-step (nth (if vertical 3 2) workarea))))))

(defun pip-frame-move-left ()
  "Move the PIP frame left."
  (interactive)
  (pip-frame--move (- (pip-frame--move-step nil)) 0))

(defun pip-frame-move-right ()
  "Move the PIP frame right."
  (interactive)
  (pip-frame--move (pip-frame--move-step nil) 0))

(defun pip-frame-move-up ()
  "Move the PIP frame up."
  (interactive)
  (pip-frame--move 0 (- (pip-frame--move-step t))))

(defun pip-frame-move-down ()
  "Move the PIP frame down."
  (interactive)
  (pip-frame--move 0 (pip-frame--move-step t)))

(defvar pip-frame-move-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<left>") 'pip-frame-move-left)
    (define-key map (kbd "<right>") 'pip-frame-move-right)
    (define-key map (kbd "<up>") 'pip-frame-move-up)
    (define-key map (kbd "<down>") 'pip-frame-move-down)
    map))
  
(defun pip-frame-move ()
  "Move PIP frame interactively.
Use arrow keys to move the frame around.
Any other key stops this command and executes its own command."
  (interactive)
  (message "Use arrow keys to move the frame, any other key to quit")
  (set-transient-map pip-frame-move-map t))

(provide 'pip-frame)

;; Local Variables:
;; checkdoc-force-docstrings-flag: nil
;; End:

;;; pip-frame.el ends here
