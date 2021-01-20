;;; register-channel.el --- Jump around fast using registers -*- lexical-binding: t -*-

;; Copyright (C) 2021  Yang Zhao

;; Author: Yang Zhao <YangZhao11@users.noreply.github.com>
;; Keywords: convenience
;; Package-Version: 20210120.1618
;; Package-Commit: ed7f563e92170b758dc878fcb5df88d46d5d44cc

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; This package provides key bindings to quickly switch between
;; predefined places, and move text to these places. With the default
;; binding, use M-g 1 to store current point to register 1, use M-1 to
;; go to it later; this works for 1~5. With an active region, M-1 will
;; copy text to the place stored in register 1. 6~8 stores / recalls
;; window configuration by default.

;; To use, put into your init.el:
;; (require 'register-channel)
;; (register-channel-mode 1)

;;; Code:

(require 'register)

(defgroup register-channel nil
  "Jump around fast using registers."
  :group 'convenience
  :prefix "register-channel-")

(defcustom register-channel-backup-register ?`
  "The backup register used to save the current point / window
  configuration etc. when you do register-channel switching."
  :type '(character))

;; Keep track of backup type; only backup in the first of same
;; type. E.g. swithcing to marker position 1 then 2, the backup stores
;; old pointer position before jumping to marker position 1.
(setq register-channel-last-save-type nil)
(defun register-channel-save-backup (type register-val)
  (unless (and (eq last-command 'register-channel-jump-or-insert)
               (eq register-channel-last-save-type type))
    (set-register register-channel-backup-register register-val)
    (setq register-channel-last-save-type type)))

(defun register-channel-last-command-char ()
  "Returns the character corresponding to last command, stripping
  any modifiers. E.g. if last command is M-1, should return 1."
  ;; C.f. digit-argument
  (let ((char (if (integerp last-command-event)
                   last-command-event
                 (get last-command-event 'ascii-character))))
    (logand char ?\177)))

(defun register-channel-jump-or-insert (&optional arg)
  "Utilize the register pressed with the last key. If the command
is invoked with M-1, then the last key is `1'.

Will utilize register content intelligently, e.g. jump to
what's in register 1 if it is a position or window / frame
configuration, otherwise insert the contents.

The replaced content is saved in register
`register-channel-backup-register' (defaults to \`), so that you
can jump back easily."
  (interactive "P")
  ;; Refer to code in register.el.
  (let* ((register (register-channel-last-command-char))
         (val (get-register register)))
    (cond ((not val)
           (user-error "No content in register %c" register))
          ((or (markerp val)
               (and (consp val)
                    (or (eq (car val) 'file)
                        (eq (car val) 'file-query))))
           (let ((save-point (point-marker)))
             (jump-to-register register arg)
             (register-channel-save-backup 'point save-point)))
          ((or (and (consp val)
                    (frame-configuration-p (car val)))
               (and (registerv-p val)
                    (vectorp (registerv-data val))
                    (frameset-p (elt (registerv-data val) 0))))
           (let ((save-frame-configuration (current-frame-configuration))
                 (save-point (point-marker)))
             (jump-to-register register arg)
             (register-channel-save-backup
              'frame
              (list save-frame-configuration save-point))))
          ((and (consp val)
                (window-configuration-p (car val)))
           (let ((save-window-configuration (current-window-configuration))
                 (save-point (point-marker)))
             (jump-to-register register arg)
             (register-channel-save-backup
              'window
              (list save-window-configuration save-point))))
          ('t
           (insert-register register arg)))))

(defcustom register-channel-marker-advance t
"If true, by default register markers will advance when you
insert text at it."
:type '(boolean))

(defun register-channel-save-point (&optional arg)
  "Save point to register defined by last key press. E.g. if this
function is bound to M-g M-1, the point is saved in register 1.

With prefix ARG, the register marker will not advance when text
is inserted at its position. This behavior can be customized by
setting `register-channel-marker-advance'."
  (interactive "P")
  (let ((digit-char (register-channel-last-command-char)))
    (point-to-register digit-char)
    (if register-channel-marker-advance
        (setq arg (not arg)))
    (set-marker-insertion-type (get-register digit-char) arg)
    (message "Point stored in register %c [%s]"
             digit-char
             (if arg "advance" "stay"))))

(defcustom register-channel-move-by-default nil
  "If true, register-channel-move-text deletes original text
without prefix argument."
  :type '(boolean))

(defun register-channel-move-text (start end &optional delete-flag)
  "Copy region to register location. If DELETE-FLAG is true,
perform a kill instead of copy; this does not modify the kill
ring.

Customize `register-channel-move-by-default' to toggle the
copy/kill behavior."
  (interactive "r\nP")
  (if register-channel-move-by-default
      (setq delete-flag (not delete-flag)))
  (let* ((register (register-channel-last-command-char))
         (m (get-register register)))
    (if (not (markerp m))
        (user-error "Register %c is not a marker" register)
      (let* ((rect (and (boundp 'rectangle-mark-mode) rectangle-mark-mode))
             (content (cond
                       ((not rect) (filter-buffer-substring start end delete-flag))
                       (delete-flag (delete-extract-rectangle start end))
                       ('t (extract-rectangle start end)))))
        (with-current-buffer (marker-buffer m)
          (save-excursion
            (goto-char (marker-position m))
            (if rect (insert-rectangle content)
              (insert content)))))
      (if (and (not delete-flag)
               (called-interactively-p 'interactive))
          (indicate-copied-region)))))

(defun register-channel-dwim (&optional arg)
  "Either save point to register, or move text if there is an
  active region and register contains marker."
  (interactive "P")
  (let* ((register (register-channel-last-command-char))
         (m (get-register register))
         (command 'register-channel-jump-or-insert))
    (if (and (use-region-p) (markerp m))
        (setq command 'register-channel-move-text))
    (call-interactively command)
    (setq this-command command)))

(defun register-channel-describe-register ()
  "Show content of register. Bind to M-g N for read-only effect."
  (interactive)
  (let ((digit-char (register-channel-last-command-char)))
    (message
     (with-output-to-string
       (describe-register-1 digit-char)))))

(defun register-channel-save-window-configuration ()
  "Save window configuration to register defined by last key press."
  (interactive)
  (let ((digit-char (register-channel-last-command-char)))
    (window-configuration-to-register digit-char)
    (message "Window configuration saved in register %c" digit-char)))

(defun register-channel-save-frame-configuration ()
  "Save frame configuration to register defined by last key press."
  (interactive)
  (let ((digit-char (register-channel-last-command-char)))
    (frameset-to-register digit-char)
    (message "Frame configuration saved in register %c" digit-char)))

(defun register-channel-default-keymap ()
  (let ((map (make-sparse-keymap)))
  ;; TODO: more customization; maybe define a prefix key.
  (define-key map (kbd "M-g 1") 'register-channel-save-point)
  (define-key map (kbd "M-g 2") 'register-channel-save-point)
  (define-key map (kbd "M-g 3") 'register-channel-save-point)
  (define-key map (kbd "M-g 4") 'register-channel-save-point)
  (define-key map (kbd "M-g 5") 'register-channel-save-point)
  (define-key map (kbd "M-g 6") 'register-channel-save-window-configuration)
  (define-key map (kbd "M-g 7") 'register-channel-save-window-configuration)
  (define-key map (kbd "M-g 8") 'register-channel-save-window-configuration)
  ;; TODO: use register-channel-backup-register.
  (define-key map (kbd "M-`") 'register-channel-dwim)
  (define-key map (kbd "M-1") 'register-channel-dwim)
  (define-key map (kbd "M-2") 'register-channel-dwim)
  (define-key map (kbd "M-3") 'register-channel-dwim)
  (define-key map (kbd "M-4") 'register-channel-dwim)
  (define-key map (kbd "M-5") 'register-channel-dwim)
  (define-key map (kbd "M-6") 'register-channel-dwim)
  (define-key map (kbd "M-7") 'register-channel-dwim)
  (define-key map (kbd "M-8") 'register-channel-dwim)
  map))

(defvar register-channel-mode-map (register-channel-default-keymap)
  "Key map for register-channel minor mode")

;;;###autoload
(define-minor-mode register-channel-mode
  "Toggle register-channel mode."
  :keymap register-channel-mode-map
  :global t)

(provide 'register-channel)
;;; register-channel.el ends here
