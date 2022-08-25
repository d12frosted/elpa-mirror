;;; hlinum.el --- Extension for linum.el to highlight current line number

;; Copyright (C) 2011-2016  by Tomoya Tanjo

;; Author: Tomoya Tanjo <ttanjo@gmail.com>
;; URL: https://github.com/tom-tan/hlinum-mode/
;; Package-Version: 20180422.412
;; Package-Commit: f17360fe93de6df99a05b4b64b0a1ca4ee45abb6
;; Package-Requires: ((cl-lib "0.2"))
;; Keywords: convenience, extensions

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

;; Extension for linum-mode to highlight current line number.
;;
;; To use this package, add these lines to your .emacs file:
;;     (require 'hlinum)
;;     (hlinum-activate)
;; And by using M-x linum-mode, you can see line numbers
;; with highlighting current line number.
;;
;; You can customize the color of highlighting current line by
;; changing `linum-highlight-face'.
;; By default, hlinum highlights current line only in the active buffer.
;; To highlight current line in all buffers, change
;; `linum-highlight-in-all-buffersp' to t.

;;; Code:

(require 'linum)
(require 'cl-lib)

(defface linum-highlight-face
    '((t (:inherit default :foreground "black"
          :background "gray")))
  "Face for highlighting current line"
  :group 'linum)

(defcustom linum-highlight-in-all-buffersp
  nil
  "Non-nil means hlinum highlights current line in all buffers.
Otherwise hlinum will highlight only in the active buffer."
  :type 'boolean
  :group 'linum)

(defun hlinum-color (face &optional line)
  "Highlight line number LINE by using face FACE.
If LINE is nil, highlight current line."
  (save-excursion
    (when line (forward-line (- line (line-number-at-pos))))
    (let* ((pt (max (window-start)
                    (progn (move-beginning-of-line nil)
                           (point))))
           (ov (cl-find-if
                (lambda (e) (stringp (overlay-get e 'linum-str)))
                (overlays-in pt pt))))
      (when ov
        (let* ((str (overlay-get ov 'before-string))
               (lstr (overlay-get ov 'linum-str))
               (nov (move-overlay ov pt pt)))
          (add-text-properties 0 (length lstr)
                               `(face ,face) lstr)
          (add-text-properties 0 1 `(display ((margin left-margin)
                                              ,lstr)) str)
          (overlay-put nov 'before-string str)
          (overlay-put nov 'linum-str lstr))))))

(defun hlinum-highlight-line (&optional line)
  (hlinum-color 'linum-highlight-face line))
(defun hlinum-unhighlight-line (&optional line)
  (unless linum-highlight-in-all-buffersp
    (hlinum-color 'linum line)))

(defun hlinum-highlight-region ()
  (when mark-active
    (cl-loop for l
             from (line-number-at-pos (region-beginning))
             to   (line-number-at-pos (region-end))
             do   (hlinum-highlight-line l))))

(defun hlinum-after-scroll (win start)
  (when (eq (current-buffer) (window-buffer))
    (if mark-active
        (hlinum-highlight-region)
      (hlinum-highlight-line))))

;;;###autoload
(defun hlinum-activate ()
  "Enable highlighting current line number."
  (interactive)
  (advice-add 'linum-update-current :after 'hlinum-highlight-line)
  (advice-add 'linum-after-scroll :after 'hlinum-after-scroll)
  (add-hook 'pre-command-hook 'hlinum-unhighlight-line)
  (add-hook 'post-command-hook 'hlinum-highlight-region))

;;;###autoload
(defun hlinum-deactivate ()
  "Disable highlighting current line number."
  (interactive)
  (remove-hook 'pre-command-hook 'hlinum-unhighlight-line)
  (remove-hook 'post-command-hook 'hlinum-highlight-region)
  (advice-remove 'linum-update-current 'hlinum-highlight-line)
  (advice-remove 'linum-after-scroll 'hlinum-after-scroll))

(provide 'hlinum)
;;; hlinum.el ends here
