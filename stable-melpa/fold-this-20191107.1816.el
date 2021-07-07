;;; fold-this.el --- Just fold this region please -*- lexical-binding: t -*-

;; Copyright (C) 2012-2013 Magnar Sveen <magnars@gmail.com>

;; Author: Magnar Sveen <magnars@gmail.com>
;; Version: 0.4.4
;; Package-Version: 20191107.1816
;; Package-Commit: c3912c738cf0515f65162479c55999e2992afce5
;; Keywords: convenience
;; Homepage: https://github.com/magnars/fold-this.el

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
;; The command `fold-this` visually replaces the current region with `[[…]]`.
;; If you move point into the ellipsis and press enter or `C-g` it is unfolded.
;;
;; You can unfold everything with `fold-this-unfold-all`.
;;
;; You can fold all instances of the text in the region with `fold-this-all`.
;;
;;; Code:
(require 'thingatpt)

(defgroup fold-this nil
  "Just fold this region please."
  :prefix "fold-this-"
  :group 'languages)

(defcustom fold-this-mode-key-prefix (kbd "C-c")
  "The prefix key for `fold-this' mode commands."
  :group 'fold-this
  :type 'sexp)

(defcustom fold-this-skip-chars 0
  "How many chars to skip from selected when creating the overlay.
Define a \"border\" to skip on overly creation."
  :group 'fold-this
  :type 'integer
  :package-version '(fold-this . 0.4.4))

(defvar fold-this--overlay-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<return>") 'fold-this-unfold-at-point)
    (define-key map (kbd "C-g") 'fold-this-unfold-at-point)
    map)
  "Keymap for `fold-this' but only on the overlay.")

(defvar fold-this-keymap
  (let ((map (make-sparse-keymap)))
    (let ((prefix-map (make-sparse-keymap)))
      (define-key prefix-map (kbd "C-f") 'fold-this)
      (define-key prefix-map (kbd "M-C-f") 'fold-this-all)
      (define-key prefix-map (kbd "M-f") 'fold-this-unfold-all)
    (define-key map fold-this-mode-key-prefix prefix-map)
    map))
  "Keymap for `fold-this'.")

(defface fold-this-overlay
  '((t (:inherit default :foreground "green")))
  "Face used to highlight the fold overlay."
  :group 'fold-this)

(defcustom fold-this-overlay-text "[[…]]"
  "Default text for `fold-this' mode overlays."
  :group 'fold-this
  :type '(choice (string :tag "Text")
		 (list (string :tag "Beginning text") (string :tag "Middle text") (string :tag "End text"))))

(defcustom fold-this-persistent-folds nil
  "Should folds survive buffer kills and Emacs sessions.
Non-nil means that folds should survive buffers killing and Emacs
sessions. "
  :group 'fold-this
  :type 'boolean)

(defcustom fold-this-persistent-folds-file (locate-user-emacs-file ".fold-this.el")
  "A file to save persistent fold info to."
  :group 'fold-this
  :type 'file)

(defcustom fold-this-persistent-folded-file-limit 30
  "A max number of files for which folds persist.  Nil for no limit."
  :group 'fold-this
  :type '(choice (integer :tag "Entries" :value 1)
                 (const :tag "No Limit" nil)))

;;;###autoload
(defun fold-this (beg end &optional fold-header)
  "Fold the region between BEG and END.

If FOLD-HEADER is specified, show this text in place of the
folded region.  If not, default to `fold-this-overlay-text'."
  (interactive "r")
  (let* ((fold-header-text (or fold-header fold-this-overlay-text))
	 (fold-header (or (and (listp fold-header-text)
			      (concat (nth 0 fold-header-text)
				      (buffer-substring beg (+ beg fold-this-skip-chars))
				      (nth 1 fold-header-text)
				      (buffer-substring (- end fold-this-skip-chars) end)
				      (nth 2 fold-header-text)))
			 fold-header-text))
        (o (make-overlay beg end nil t nil)))
    (overlay-put o 'type 'fold-this)
    (overlay-put o 'invisible t)
    (overlay-put o 'keymap fold-this--overlay-keymap)
    (overlay-put o 'isearch-open-invisible-temporary
                 (lambda (ov action)
                   (if action
                       (progn
                         (overlay-put ov 'display (propertize fold-header 'face 'fold-this-overlay))
                         (overlay-put ov 'invisible t))
                     (progn
                       (overlay-put ov 'display nil)
                       (overlay-put ov 'invisible nil)))))
    (overlay-put o 'isearch-open-invisible 'fold-this--delete-my-overlay)
    (overlay-put o 'face 'fold-this-overlay)
    (overlay-put o 'modification-hooks '(fold-this--delete-my-overlay))
    (overlay-put o 'display (propertize fold-header 'face 'fold-this-overlay))
    (overlay-put o 'evaporate t))
  (deactivate-mark))

;;;###autoload
(defun fold-this-sexp ()
  "Fold sexp around point.

If the point is at a symbol, fold the parent sexp.  If the point
is in front of a sexp, fold the following sexp."
  (interactive)
  (let* ((region
          (cond
           ((symbol-at-point)
            (save-excursion
              (when (nth 3 (syntax-ppss))
                (goto-char (nth 8 (syntax-ppss))))
              (backward-up-list)
              (cons (point)
                    (progn
                      (forward-sexp)
                      (point)))))
           ((looking-at-p (rx (* blank) "("))
            (save-excursion
              (skip-syntax-forward " ")
              (cons (point)
                    (progn
                      (forward-sexp)
                      (point)))))
           (t nil)))
         (header (when region
                   (save-excursion
                     (goto-char (car region))
                     (buffer-substring (point) (line-end-position))))))
    (when region
      (fold-this (car region) (cdr region) header))))

;;;###autoload
(defun fold-this-all (_beg _end)
  "Fold  all occurences of text in region."
  (interactive "r")
  (let ((string (buffer-substring (region-beginning)
                                  (region-end))))
    (save-excursion
      (goto-char (point-min))
      (while (search-forward string (point-max) t)
        (fold-this (match-beginning 0) (match-end 0)))))
  (deactivate-mark))

(defun fold-active-region (beg end)
  (interactive "r")
  (when (region-active-p)
    (fold-this beg end)))

(defun fold-active-region-all (beg end)
  (interactive "r")
  (when (region-active-p)
    (fold-this-all beg end)))

(defun fold-this-unfold-all ()
  "Unfold all overlays in current buffer.
If narrowing is active, only in it."
  (interactive)
  (mapc 'fold-this--delete-my-overlay
        (overlays-in (point-min) (point-max))))

(defun fold-this-unfold-at-point ()
  "Unfold at point."
  (interactive)
  (mapc 'fold-this--delete-my-overlay
        (overlays-at (point))))

(defun fold-this--delete-my-overlay (overlay &optional _after? _beg _end _length)
  "Delete the OVERLAY overlays only if it's an `fold-this'."
  (when (eq (overlay-get overlay 'type) 'fold-this)
    (delete-overlay overlay)))

;;; Fold-this overlay persistence
;;

(defvar fold-this--overlay-alist nil
  "An alist of filenames mapped to fold overlay positions.")

(defvar fold-this--overlay-alist-loaded nil
  "Non-nil if the alist has already been loaded.")

(defun fold-this--find-file-hook ()
  "A hook restoring fold overlays."
  (when (and fold-this-persistent-folds
             buffer-file-name
             (not (derived-mode-p 'dired-mode)))
    (when (not fold-this--overlay-alist-loaded)
      (fold-this--load-alist-from-file))
    (let* ((file-name buffer-file-name)
           (cell (assoc file-name fold-this--overlay-alist)))
      (when cell
        (mapc (lambda (pair) (fold-this (car pair) (cdr pair)))
              (cdr cell))
        (setq fold-this--overlay-alist
              (delq cell fold-this--overlay-alist))
        (fold-this-mode 1)))))

(defun fold-this--kill-buffer-hook ()
  "A hook saving overlays."
  (when (and fold-this-persistent-folds
             buffer-file-name
             (not (derived-mode-p 'dired-mode)))
    (when (not fold-this--overlay-alist-loaded)
      ;; is it even possible ?
      (fold-this--load-alist-from-file))
    (save-restriction
      (widen)
      (mapc 'fold-this--save-overlay-to-alist
	    (overlays-in (point-min) (point-max))))
    (when (alist-get buffer-file-name fold-this--overlay-alist)
      (fold-this--save-alist-to-file))))

(defun fold-this--kill-emacs-hook ()
  "A hook saving overlays in all buffers and dumping them into a file."
  (when (and fold-this-persistent-folds
             fold-this--overlay-alist-loaded)
    (fold-this--walk-buffers-save-overlays)
    (fold-this--save-alist-to-file)))

(defun fold-this--save-alist-to-file ()
  "Save current overlay alist to file."
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
  "Restore ovelay alist `fold-this--overlay-alist' from file."
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
    (setq fold-this--overlay-alist-loaded t)))

(defun fold-this--walk-buffers-save-overlays ()
  "Walk the buffer list, save overlays to the alist."
  (let ((buf-list (buffer-list)))
    (while buf-list
      (with-current-buffer (car buf-list)
        (when (and buffer-file-name
                   (not (derived-mode-p 'dired-mode)))
          (setq fold-this--overlay-alist
                (delq (assoc buffer-file-name fold-this--overlay-alist)
                      fold-this--overlay-alist))
          (save-restriction
	    (widen)
	    (mapc 'fold-this--save-overlay-to-alist
		  (overlays-in (point-min) (point-max)))))
        (setq buf-list (cdr buf-list))))))

(defun fold-this--save-overlay-to-alist (overlay)
  "Add an OVERLAY position pair to the alist."
  (when (eq (overlay-get overlay 'type) 'fold-this)
    (let* ((pos (cons (overlay-start overlay) (overlay-end overlay)))
           (file-name buffer-file-name)
           (cell (assoc file-name fold-this--overlay-alist))
           overlay-list)
      (unless (member pos cell) ;; only if overlay is not already there
        (when cell
          (setq fold-this--overlay-alist
                (delq cell fold-this--overlay-alist)
                overlay-list (delq pos (cdr cell))))
        (setq fold-this--overlay-alist
              (cons (cons file-name (cons pos overlay-list))
                    fold-this--overlay-alist))))))

(defun fold-this--clean-unreadable-files ()
  "Check if files in the alist exist and are readable.
Drop non-existing/non-readable ones."
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
  "Check if there are more folds than possible.
Drop the tail of the alist."
  (when (> fold-this-persistent-folded-file-limit 0)
    (let ((listlen (length fold-this--overlay-alist)))
      (when (> listlen fold-this-persistent-folded-file-limit)
        (setcdr (nthcdr (1- fold-this-persistent-folded-file-limit) fold-this--overlay-alist)
                nil)))))

;;;###autoload
(define-minor-mode fold-this-mode
  "Toggle folding on or off.
With folding activated add custom map \\[fold-this-keymap]"
  :lighter (:eval (apply 'concat " "
                         (if (listp fold-this-overlay-text)
                             fold-this-overlay-text
                           (list fold-this-overlay-text))))
  :keymap fold-this-keymap
  :group 'fold-this
  :init-value nil
  (unless fold-this-mode
    (fold-this-unfold-all)))

;;;###autoload
(define-minor-mode fold-this-persistent-mode
  "Enable persistence of overlays for `fold-this-mode'"
  :global t
  :group 'fold-this
  :lighter " ft-p"
  (if fold-this-persistent-mode
      (progn
        (unless fold-this-persistent-folds
          (setq fold-this-persistent-folds t))
        (add-hook 'find-file-hook   #'fold-this--find-file-hook)
        (add-hook 'kill-buffer-hook #'fold-this--kill-buffer-hook)
        (add-hook 'kill-emacs-hook  #'fold-this--kill-emacs-hook))
    (progn
      (setq fold-this-persistent-folds (get fold-this-persistent-folds 'standard-value))
      (remove-hook 'find-file-hook 'fold-this--find-file-hook)
      (remove-hook 'kill-buffer-hook 'fold-this--kill-buffer-hook)
      (remove-hook 'kill-emacs-hook 'fold-this--kill-emacs-hook))))

(provide 'fold-this)
;;; fold-this.el ends here
