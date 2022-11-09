;;; helm-frame.el --- open helm buffers in a dedicated frame -*- lexical-binding: t -*-

;; copyright © 2017 chee
;; author: chee <yay@chee.party>
;; keywords: lisp, helm, popup, frame
;; Package-Version: 20220803.1528
;; Package-Commit: 1b5e895e9199deeea049010e5fe4de7a338f41f3
;; version: 0.4.8
;; package-requires: ((emacs "24.4"))

;; this program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; commentary:

;; to configure, (require 'helm-frame) and add lines like these to your init:
;;
;;   (add-hook 'helm-after-action-hook 'helm-frame-delete)
;;   (add-hook 'helm-cleanup-hook 'helm-frame-delete)
;;   (setq helm-split-window-preferred-function 'helm-frame-window)

;;; code:
(require 'cl-lib)

(defun helm-frame--half (number) "Return half a NUMBER." (/ number 2))

(defun helm-frame--current-monitor (&optional frame)
  "Get the current monitor.
If FRAME is provided, then get display that frame is on."
  (cl-find-if
    (lambda (monitor)
      (member (or frame (window-frame)) (assoc 'frames monitor)))
    (display-monitor-attributes-list)))

(defun helm-frame--monitor-pixel-width (&optional monitor)
  "Return pixel width of MONITOR."
  (nth 3 (assoc 'workarea (or monitor (frame-monitor-attributes)))))

(defun helm-frame--monitor-pixel-height (&optional monitor)
  "Return pixel height of MONITOR."
  (nth 4 (assoc 'workarea (or monitor (frame-monitor-attributes)))))

(defun helm-frame--center-frame (frame)
  "Center FRAME on current monitor."
  (let*
    ((monitor (frame-monitor-attributes frame))
      (half-monitor-width (helm-frame--half (helm-frame--monitor-pixel-width monitor)))
      (half-frame-width (helm-frame--half (frame-pixel-width frame)))
      (half-monitor-height (helm-frame--half (helm-frame--monitor-pixel-height monitor)))
      (half-frame-height (helm-frame--half (frame-pixel-height frame))))

    (set-frame-position frame
      (- half-monitor-width half-frame-width)
      (- half-monitor-height half-frame-height))))

(defun helm-frame--frame-named (name)
  "Return frame called NAME."
  (interactive
    (let*
      ((frame-names-alist (make-frame-names-alist))
        (default (car (car frame-names-alist)))
        (input
          (completing-read
            (format "Select Frame (default %s): " default)
            frame-names-alist nil t nil 'frame-name-history)))
      (if (= (length input) 0)
        (list default)
        (list input))))
  (let*
    ((frame-names-alist (make-frame-names-alist))
      (frame (cdr (assoc name frame-names-alist))))
    frame))


(defun helm-frame-create ()
  "Create a new helm-frame."
  (let
    ((old-frame (window-frame))
      (frame (make-frame '((name . "Helm") (width . 80) (height . 20)))))
    (set-frame-width frame 80)
    (set-frame-height frame 20)
    (helm-frame--center-frame frame)
    (lower-frame frame)
    (select-frame-set-input-focus old-frame) frame))

(defun helm-frame-frame ()
  "Return the current frame, or create a new one."
  (let ((frame (or (helm-frame--frame-named "Helm") (helm-frame-create))))
    (set-frame-width frame 80)
    (set-frame-height frame 20)
    (helm-frame--center-frame frame)
    frame))

(defun helm-frame-window (window)
  "Return helm-frame's window.

Takes WINDOW for compatability with 'helm-split-window-preferred-function'."
  (frame-root-window (helm-frame-frame)))

(defun helm-frame-delete ()
  "Throw the frame down a very deep well."
  (delete-frame (helm-frame-frame)))

(provide 'helm-frame)
;;; helm-frame.el ends here
