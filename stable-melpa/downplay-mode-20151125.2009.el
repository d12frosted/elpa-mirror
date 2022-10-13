;;; downplay-mode.el --- focus attention on a region of the buffer

;; Coyright (C) 2013-2014 Toby Crawley

;; Author: Toby Crawley <toby@tcrawley.org>
;; URL: https://github.com/tobias/downplay-mode/
;; Package-Version: 20151125.2009
;; Package-Commit: 4a2c3addc73c8ca3816345c3c11c08af265baedb
;; Created: 2013-12-21
;; Version: 0.1

;; This file is not part of GNU Emacs.

;;; Copyright Notice:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Downplay is a minor Emacs mode that provides facilities to apply a
;; face (via overlays) to all but the current region or line. 
;;
;; To enable Downplay minor mode, type M-x downplay-mode.
;; This applies only to the current buffer.
;;
;; When 'downplay is called, it will change the downplayed state of
;; the buffer depending on the current state:
;;
;; - when the downplay is inactive:
;;   - if the region is active and transient-mark-mode is active,
;;     downplay-face is applied to all of the buffer except the region
;;   - else downplay-face is applied to all of the buffer except the
;;     current line
;; - when the downplay is active:
;;   - if the region is active and transient-mark-mode is active and
;;     the region has changed since the downplay was activated,
;;     downplay-face is reapplied to all of the buffer except the
;;     region
;;   - else if the current line has changed, downplay-face is
;;     reapplied to all of the buffer except the current line
;;   - else the downplay is deactivated (downplay-face is unapplied
;;     from the entire buffer) 
;;
;; By default, 'downplay is bound to C-c z when downplay-mode is
;; active. The default downplay-face sets the height of the text to
;; 0.75. 

;;; Code:

(eval-when-compile
  (require 'cl))

(make-variable-buffer-local
 (defvar downplay-overlays))

(defface downplay-face
  `((t . (:height 0.75)))
  "Face used for downplayed sections of the buffer.")

(defun downplay-active-p ()
  (overlay-buffer (first downplay-overlays)))

(defun downplay-all-but (start end)
  (move-overlay (first downplay-overlays) (point-min) start)
  (move-overlay (second downplay-overlays) end (point-max)))

(defun downplay-region-changed-p (start end)
  (and (downplay-active-p)
       (or (not (eq start (overlay-end (first downplay-overlays))))
           (not (eq end (overlay-start (second downplay-overlays)))))))

(defun downplay-quit ()
  (mapcar 'delete-overlay downplay-overlays))

(defun downplay-region-prefix-overlay-end ()
  (let ((start (if (region-active-p)
                   (region-beginning)
                 (line-beginning-position))))
    (if (<= start (point-min))
        (point-min)
      (- start 1))))

(defun downplay-region-postfix-overlay-start ()
  (let ((end (if (region-active-p)
                 (region-end)
               (line-end-position))))
    (if (>= end (point-max))
        (point-max)
      (+ end 1))))

(defun downplay ()
  (interactive)
  (let ((start (downplay-region-prefix-overlay-end))
        (end   (downplay-region-postfix-overlay-start)))
    (cond
     ((downplay-region-changed-p start end) (downplay-all-but start end))
     ((downplay-active-p)                   (downplay-quit))
     ((downplay-all-but start end)))))

;;;###autoload
(define-minor-mode downplay-mode
  "Downplay all but the region or the current line."
  :lighter " dp"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c z") 'downplay)
            map)
  (if downplay-mode
      (setq downplay-overlays
            (mapcar (lambda (_)
                      (let ((overlay (make-overlay (point-min) (point-min))))
                        (overlay-put overlay
                                     'font-lock-face 'downplay-face)
                        (delete-overlay overlay)
                        overlay))
                    '(nil nil)))
    (downplay-quit))) 

(provide 'downplay-mode)

;;; downplay-mode.el ends here
