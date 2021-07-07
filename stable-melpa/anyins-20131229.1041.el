;;; anyins.el --- Insert content at multiple places from shell command or kill-ring

;; Copyright (C) 2013 Anthony HAMON

;; Author: Anthony HAMON <hamon.anth@gmail.com>
;; URL: http://github.com/antham/anyins
;; Package-Version: 20131229.1041
;; Package-Commit: 83844c17ac9b5b6c7655ee556b75689e4c8ea663
;; Version: 0.1.0
;; Keywords: insert, rectangular

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
;;
;; Insert content either from kill-ring or from shell command result at marked
;; point or vertically like rectangular do.
;;
;; Have a look to README at https://github.com/antham/anyins to have more information
;;
;;; Code:

(defface anyins-recorded-positions
  '((((background dark)) :background "green"
     :foreground "white")
    (((background light)) :background "green"
     :foreground "white"))
  "Marker for recorded position"
  :group 'anyins)

(defvar anyins-buffers-positions '()
  "Positions recorded in buffers.")
(make-variable-buffer-local 'anyins-buffers-positions)

(defvar anyins-buffers-overlays '()
  "Overlays recorded in buffers.")
(make-variable-buffer-local 'anyins-buffers-overlays)

(defun anyins-record-position (position)
  "Record cursor line and offset, return true if POSITION doesn't exist yet."
  (let ((previous-length (length anyins-buffers-positions)))
    (setq anyins-buffers-positions (delete-dups (append anyins-buffers-positions (list position))))
    (progn
      (when (/= previous-length (length anyins-buffers-positions))
        t))))

(defun anyins-remove-positions ()
  "Delete recorded positions."
  (setq anyins-buffers-positions '()))

(defun anyins-prepare-content-to-insert (content)
  "Transform CONTENT to list to be inserted."
  (when content
    (split-string content "\n")))

(defun anyins-goto-position (position)
  "Move cursor at POSITION."
  (goto-line (car position))
  (goto-char (+ (line-beginning-position)
                (cadr position))))

(defun anyins-get-current-position ()
  "Get current cursor position."
  (list (line-number-at-pos (point))
        (- (point)
           (line-beginning-position))))

(defun anyins-record-current-position ()
  "Record current cursor position."
  (interactive)
  (when (anyins-record-position (anyins-get-current-position))
    (anyins-create-overlay (point))))

(defun anyins-create-overlay (point)
  "Create an overlay at POINT."
  (let ((overlay (make-overlay point (+ 1 point))))
    (overlay-put overlay 'face 'anyins-recorded-positions)
    (push overlay anyins-buffers-overlays)))

(defun anyins-delete-overlays ()
  "Delete overlays."
  (when anyins-buffers-overlays
    (dolist (overlay anyins-buffers-overlays)
      (delete-overlay overlay))
    (setq anyins-buffers-overlays '())))

(defun anyins-goto-or-create-position (position)
  "Create POSITION if it doesn't exist, filling with space to do so."
  (let* ((end-position nil))
    (goto-line (car position))
    (end-of-line)
    (setq end-position (anyins-get-current-position))
    (if (<= (cadr position)
            (cadr end-position))
        (anyins-goto-position position)
      (progn
        (while (> (cadr position)
                  (cadr end-position))
          (insert " ")
          (setq end-position (anyins-get-current-position)))))))

(defun anyins-compute-position-offset (rows positions)
  "Compute offset for ROWS linked to POSITIONS."
  (let ((ordered-positions nil)
        (computed-positions nil))
    (dotimes (i (length positions))
      (let* ((row (nth i rows))
             (position (nth i positions))
             (line (car position))
             (offset (cadr position))
             (row-list (cadr (assoc line ordered-positions))))
        (when row
          (setq ordered-positions (assq-delete-all line ordered-positions))
          (setq row-list (cons (list offset row) row-list))
          (setq row-list (sort row-list
                               (lambda (a b)
                                 (and (< (car a)
                                         (car b))))))
          (setq ordered-positions (append ordered-positions (list (list line row-list)))))))
    (setq ordered-positions (sort ordered-positions
                                  (lambda (a b)
                                    (and (< (car a)
                                            (car b))))))
    (dolist (row-list ordered-positions)
      (let ((offset 0)
            (line (car row-list))
            (row-list-result))
        (dolist (row (cadr row-list))
          (setq row-list-result (append row-list-result (list (list (+ (car row) offset)
                                                                    (cadr row)))))
          (setq offset (+ offset (length (cadr row)))))
        (setq computed-positions (append computed-positions (list (list line row-list-result))))))
    (progn
      computed-positions)))

(defun anyins-insert-at-recorded-positions (rows positions)
  "Insert ROWS at recorded POSITIONS."
  (let ((computed-positions (anyins-compute-position-offset rows positions)))
    (dolist (row-list computed-positions)
      (let ((line (car row-list)))
        (dolist (row (cadr row-list))
          (anyins-goto-position (list line (car row)))
          (insert (cadr row)))))))

(defun anyins-insert-from-current-position (rows)
  "Insert ROWS from current position."
  (let* ((current-position (anyins-get-current-position))
         (line (car current-position)))
    (while (>= (line-number-at-pos (point-max)) line)
      (anyins-goto-or-create-position (list line (cadr current-position)))
      (let ((data (pop rows)))
        (when (char-or-string-p data)
          (insert data)))
      (setq line (+ 1 line)))))

(defun anyins-insert (content)
  "Insert CONTENT in buffer."
  (let* ((rows (anyins-prepare-content-to-insert content)))
    (if (and anyins-buffers-positions
             rows)
        (progn
          (anyins-insert-at-recorded-positions rows anyins-buffers-positions)
          (anyins-remove-positions))
      (anyins-insert-from-current-position rows))))

(defun anyins-turn-on-mode ()
  "Turn on anyins mode."
  (setq buffer-read-only t)
  )

(defun anyins-turn-off-mode ()
  "Turn off anyins mode."
  (setq buffer-read-only nil)
  (anyins-delete-overlays)
  (anyins-remove-positions)
  )

(defun anyins-disable-mode ()
  "Disable anyins mode."
  (interactive)
  (anyins-mode 0))

(defun anyins-yank ()
  "Yank the contents of the kill ring."
  (interactive)
  (setq buffer-read-only nil)
  (anyins-insert (car kill-ring))
  (anyins-mode 0))

(defun anyins-insert-command (command)
  "Insert the output of COMMAND."
  (interactive "sShell command: ")
  (setq buffer-read-only nil)
  (anyins-insert (shell-command-to-string command))
  (anyins-mode 0))

(defvar anyins-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q")   'anyins-disable-mode)
    (define-key map (kbd "RET") 'anyins-record-current-position)
    (define-key map (kbd "y")   'anyins-yank)
    (define-key map (kbd "!")   'anyins-insert-command)
    map)
  "Keymap for `anyins-mode`.")

;;;###autoload
(define-minor-mode anyins-mode "Anyins minor mode."
  :lighter " Anyins"
  (if anyins-mode
      (anyins-turn-on-mode)
    (anyins-turn-off-mode))
  (message "Anyins mode %s"
           (if anyins-mode "enabled" "disabled")))

(provide 'anyins)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; anyins.el ends here
