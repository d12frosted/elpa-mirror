;;; fold-this.el --- Just fold this region please

;; Copyright (C) 2012-2013 Magnar Sveen <magnars@gmail.com>

;; Author: Magnar Sveen <magnars@gmail.com>
;; Version: 0.3.0
;; Package-Version: 20150601.1042
;; Package-Commit: 90b41d7b588ab1c3295bf69f7dd87bf31b543a6a
;; Keywords: convenience

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Just fold the active region, please.
;;
;; ## How it works
;;
;; The command `fold-this` visually replaces the current region with `...`.
;; If you move point into the ellipsis and press enter or `C-g` it is unfolded.
;;
;; You can unfold everything with `fold-this-unfold-all`.
;;
;; You can fold all instances of the text in the region with `fold-this-all`.
;;
;; ## Setup
;;
;; I won't presume to know which keys you want these functions bound to,
;; so you'll have to set that up for yourself. Here's some example code,
;; which incidentally is what I use:
;;
;;     (global-set-key (kbd "C-c C-f") 'fold-this-all)
;;     (global-set-key (kbd "C-c C-F") 'fold-this)
;;     (global-set-key (kbd "C-c M-f") 'fold-this-unfold-all)

;;; Code:

(defvar fold-this-keymap (make-sparse-keymap))
(define-key fold-this-keymap (kbd "<return>") 'fold-this-unfold-at-point)
(define-key fold-this-keymap (kbd "C-g") 'fold-this-unfold-at-point)

(defface fold-this-overlay
  '((t (:inherit default)))
  "Face used to highlight the fold overlay."
  :group 'fold-this)

(defcustom fold-this-persistent-folds nil
  "Non-nil means that folds survive between buffer kills and
Emacs sessions."
  :group 'fold-this
  :type 'boolean)

(defcustom fold-this-persistent-folds-file (locate-user-emacs-file ".fold-this.el")
  "A file to save persistent fold info to."
  :group 'fold-this
  :type 'file)

(defcustom fold-this-persistent-folded-file-limit 30
  "A max number of files for which folds persist. Nil for no limit."
  :group 'fold-this
  :type '(choice (integer :tag "Entries" :value 1)
                 (const :tag "No Limit" nil)))

;;;###autoload
(defun fold-this (beg end)
  (interactive "r")
  (let ((o (make-overlay beg end nil t nil)))
    (overlay-put o 'type 'fold-this)
    (overlay-put o 'invisible t)
    (overlay-put o 'keymap fold-this-keymap)
    (overlay-put o 'face 'fold-this-overlay)
    (overlay-put o 'modification-hooks '(fold-this--unfold-overlay))
    (overlay-put o 'display (propertize "." 'face 'fold-this-overlay))
    (overlay-put o 'before-string (propertize "." 'face 'fold-this-overlay))
    (overlay-put o 'evaporate t))
  (deactivate-mark))

;;;###autoload
(defun fold-this-all (beg end)
  (interactive "r")
  (let ((string (buffer-substring (region-beginning)
                                  (region-end))))
    (save-excursion
      (goto-char (point-min))
      (while (search-forward string (point-max) t)
        (fold-this (match-beginning 0) (match-end 0)))))
  (deactivate-mark))

;;;###autoload
(defun fold-active-region (beg end)
  (interactive "r")
  (when (region-active-p)
    (fold-this beg end)))

;;;###autoload
(defun fold-active-region-all (beg end)
  (interactive "r")
  (when (region-active-p)
    (fold-this-all beg end)))

;;;###autoload
(defun fold-this-unfold-all ()
  (interactive)
  (mapc 'fold-this--delete-my-overlay
        (overlays-in (point-min) (point-max))))

;;;###autoload
(defun fold-this-unfold-at-point ()
  (interactive)
  (mapc 'fold-this--delete-my-overlay
        (overlays-at (point))))

(defun fold-this--delete-my-overlay (it)
  (when (eq (overlay-get it 'type) 'fold-this)
    (delete-overlay it)))

(defun fold-this--unfold-overlay (overlay after? beg end &optional length)
  (delete-overlay overlay))

;;; Fold-this overlay persistence
;;

(defvar fold-this--overlay-alist nil
  "An alist of filenames mapped to fold overlay positions")

(defvar fold-this--overlay-alist-loaded nil
  "Non-nil if the alist has already been loaded")

(defun fold-this--find-file-hook ()
  "A hook restoring fold overlays"
  (when (and fold-this-persistent-folds
             buffer-file-name
             (not (derived-mode-p 'dired-mode)))
    (when (not fold-this--overlay-alist-loaded)
      (fold-this--load-alist-from-file)
      (setq fold-this--overlay-alist-loaded t))
    (let* ((file-name buffer-file-name)
           (cell (assoc file-name fold-this--overlay-alist)))
      (when cell
        (mapc (lambda (pair) (fold-this (car pair) (cdr pair)))
              (cdr cell))
        (setq fold-this--overlay-alist
              (delq cell fold-this--overlay-alist))))))
(add-hook 'find-file-hook 'fold-this--find-file-hook)

(defun fold-this--kill-buffer-hook ()
  "A hook saving overlays"
  (when (and fold-this-persistent-folds
             buffer-file-name
             (not (derived-mode-p 'dired-mode)))
    (when (not fold-this--overlay-alist-loaded)
      (fold-this--load-alist-from-file)
      (setq fold-this--overlay-alist-loaded t))
    (mapc 'fold-this--save-overlay-to-alist
          (overlays-in (point-min) (point-max)))))
(add-hook 'kill-buffer-hook 'fold-this--kill-buffer-hook)

(defun fold-this--kill-emacs-hook ()
  "A hook saving overlays in all buffers and dumping them into a
  file"
  (when (and fold-this-persistent-folds
             fold-this--overlay-alist-loaded)
    (fold-this--walk-buffers-save-overlays)
    (fold-this--save-alist-to-file)))
(add-hook 'kill-emacs-hook 'fold-this--kill-emacs-hook)

(defun fold-this--save-alist-to-file ()
  (fold-this--clean-unreadable-files)
  (when fold-this-persistent-folded-file-limit
    (fold-this--check-fold-limit))
  (let ((file (expand-file-name fold-this-persistent-folds-file))
        (coding-system-for-write 'utf-8)
        (version-control 'never))
    (with-current-buffer (get-buffer-create " *Fold-this*")
      (delete-region (point-min) (point-max))
      (insert (format ";;; -*- coding: %s -*-\n"
                      (symbol-name coding-system-for-write)))
      (let ((print-length nil)
            (print-level nil))
        (pp fold-this--overlay-alist (current-buffer)))
      (let ((version-control 'never))
        (condition-case nil
            (write-region (point-min) (point-max) file)
          (file-error (message "Fold-this: can't write %s" file)))
        (kill-buffer (current-buffer))))))

(defun fold-this--load-alist-from-file ()
  (progn
    (let ((file (expand-file-name fold-this-persistent-folds-file)))
      (when (file-readable-p file)
        (with-current-buffer (get-buffer-create " *Fold-this*")
          (delete-region (point-min) (point-max))
          (insert-file-contents file)
          (goto-char (point-min))
          (setq fold-this--overlay-alist
                (with-demoted-errors "Error reading fold-this-persistent-folds-file %S"
                  (car (read-from-string
                        (buffer-substring (point-min) (point-max))))))
          (kill-buffer (current-buffer))))
      nil)))

(defun fold-this--walk-buffers-save-overlays ()
  "Walk the buffer list, save overlays to the alist"
  (let ((buf-list (buffer-list)))
    (while buf-list
      (with-current-buffer (car buf-list)
        (when (and buffer-file-name
                   (not (derived-mode-p 'dired-mode)))
          (mapc 'fold-this--save-overlay-to-alist
                (overlays-in (point-min) (point-max))))
        (setq buf-list (cdr buf-list))))))

(defun fold-this--save-overlay-to-alist (overlay)
  "Add an overlay position pair to the alist"
  (when (eq (overlay-get overlay 'type) 'fold-this)
    (let* ((pos (cons (overlay-start overlay) (overlay-end overlay)))
           (file-name buffer-file-name)
           (cell (assoc file-name fold-this--overlay-alist))
           overlay-list)
      (when cell (setq fold-this--overlay-alist
                       (delq cell fold-this--overlay-alist))
            (setq overlay-list (cdr cell)))
      (setq fold-this--overlay-alist
            (cons (cons file-name (cons pos overlay-list))
                  fold-this--overlay-alist)))))

(defun fold-this--clean-unreadable-files ()
  "Check if files in the alist exist and are readable, drop
  non-existing/non-readable ones"
  (when fold-this--overlay-alist
    (let ((orig fold-this--overlay-alist)
          new)
      (dolist (cell orig)
        (let ((fname (car cell)))
          (when (file-readable-p fname)
            (setq new (cons cell new)))))
      (setq fold-this--overlay-alist
            (nreverse new)))))

(defun fold-this--check-fold-limit ()
  "Check if there are more folds than possible, drop the tail of
  the alist."
  (when (> fold-this-persistent-folded-file-limit 0)
    (let ((listlen (length fold-this--overlay-alist)))
      (when (> listlen fold-this-persistent-folded-file-limit)
        (setcdr (nthcdr (1- fold-this-persistent-folded-file-limit) fold-this--overlay-alist)
                nil)))))

(provide 'fold-this)
;;; fold-this.el ends here
