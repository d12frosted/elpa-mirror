;;; undohist.el --- Persistent undo history for GNU Emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2009-2015  Tomohiro Matsuyama

;; Author: MATSUYAMA Tomohiro <m2ym.pub@gmail.com>
;; Package-Requires: ((cl-lib "1.0"))
;; Package-Version: 20210517.411
;; Package-Commit: 56c6f58873f8ebb743e4dc5aff143744720375bd
;; Keywords: convenience
;; Version: 0.2.1

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

;; This extension provides a way to use undo history of
;; individual file buffers persistently.
;;
;; Write the following code to your .emacs:
;;
;; (require 'undohist)
;; (undohist-initialize)
;;
;; Now you can record and recover undohist by typing
;; C-x C-s (save-buffer) an C-x C-f (find-file).
;; And then type C-/ (undo).

;;; Code:

(require 'cl-lib)

(defgroup undohist nil
  "Persistent undo history."
  :prefix "undohist-"
  :group 'undohist)

(defcustom undohist-directory
  (expand-file-name
   (concat
    (if (boundp 'user-emacs-directory)
        user-emacs-directory
      "~/.emacs.d")
    "/undohist"))
  "A directory being stored undo history files."
  :type 'undohist)

(defcustom undohist-ignored-files nil
  "List of regexps or functions matching file names to ignore the
recovering of undo history."
  :type 'undohist)

(defun make-undohist-file-name (file)
  (setq file (convert-standard-filename (expand-file-name file)))
  (if (eq (aref file 1) ?:)
      (setq file (concat "/"
                         "drive_"
                         (char-to-string (downcase (aref file 0)))
                         (if (eq (aref file 2) ?/)
                             ""
                           "/")
                         (substring file 2))))
  (setq file (expand-file-name
              (subst-char-in-string
               ?/ ?!
               (replace-regexp-in-string "!" "!!" file))
              undohist-directory)))

(defun undohist-walk-tree (function tree)
  (cond
   ((consp tree)
    (let ((value (funcall function tree)))
      (if (eq value tree)
          (let* ((cons (cons (undohist-walk-tree function (car tree)) nil))
                 (cur cons)
                 cdr)
            (while tree
              (setq cdr (cdr tree))
              (if (consp cdr)
                  (let (next)
                    (setq next (cons (undohist-walk-tree function (car cdr)) nil))
                    (setcdr cur next)
                    (setq cur next)
                    (setq tree cdr))
                (setcdr cur (undohist-walk-tree function cdr))
                (setq tree nil)))
            cons)
        value)))
   ((vectorp tree)
    (let ((value (funcall function tree)))
      (if (eq value tree)
          (cl-loop with length = (length tree)
                   with vector = (make-vector length nil)
                   for i from 0 below length
                   do (aset vector i (undohist-walk-tree function (aref tree i)))
                   finally return vector)
        value)))
   (tree (funcall function tree))))

(defun undohist-encode (tree)
  "Encode `TREE' so that it can be stored as a file."
  (undohist-walk-tree
   (lambda (a)
     (cond
      ((markerp a)
       (cons (if (marker-insertion-type a) 'marker* 'marker)
             (marker-position a)))
      ((overlayp a)
       `(overlay ,(overlay-start a) ,(overlay-end a)))
      ((stringp a)
       (substring-no-properties a))
      (t a)))
   tree))

(defun undohist-decode (tree)
  "Decode `TREE' so that it can be recovered as undo history."
  (undohist-walk-tree
   (lambda (a)
     (if (consp a)
         (cond
          ((eq (car a) 'marker)
           (set-marker (make-marker) (cdr a)))
          ((eq (car a) 'marker*)
           (let ((marker (make-marker)))
             (set-marker marker (cdr a))
             (set-marker-insertion-type marker t)
             marker))
          ((eq (car a) 'overlay)
           (let ((start (cadr a))
                 (end (caddr a)))
             (if (and start end)
                 (make-overlay (cadr a) (caddr a))
               ;; Make deleted overlay
               (let ((overlay (make-overlay (point-min) (point-min))))
                 (delete-overlay overlay)
                 overlay))))
          (t a))
       a))
   tree))

(defun undohist-recover-file-p (file)
  "Return t if undo history of FILE should be recovered."
  (not (cl-some (lambda (matcher)
                  (if (stringp matcher)
                      (string-match matcher file)
                    (funcall matcher file)))
                undohist-ignored-files)))

(defvar buffer-undo-list)

(defun undohist-save-1 ()
  (when (and (consp buffer-undo-list)
             (undohist-recover-file-p (buffer-file-name (current-buffer))))
    (let ((file (make-undohist-file-name (buffer-file-name)))
          (contents `((digest . ,(md5 (current-buffer)))
                      (undo-list . ,(undohist-encode buffer-undo-list)))))
      (with-temp-buffer
        (print contents (current-buffer))
        (write-region (point-min) (point-max) file nil 0)
        (set-file-modes file ?\600)))))

(defun undohist-save-safe ()
  (condition-case var
      (undohist-save-1)
    (error (message "Can not save undo history: %s" var))))

(defun undohist-save ()
  "Save undo history."
  (interactive)
  (undohist-save-safe))

(defun undohist-recover-1 ()
  (let* ((buffer (current-buffer))
         (file (buffer-file-name buffer))
         (undo-file (make-undohist-file-name file))
         undo-list)
    (when (and (undohist-recover-file-p file)
               (file-exists-p undo-file)
               (or (null buffer-undo-list)
                   (yes-or-no-p "buffer-undo-list is not empty. Do you want to recover now? ")))
      (with-temp-buffer
        (insert-file-contents undo-file)
        (goto-char (point-min))
        (let ((alist (undohist-decode (read (current-buffer)))))
          (if (string= (md5 buffer) (assoc-default 'digest alist))
              (setq undo-list (assoc-default 'undo-list alist))
            (message "File digest doesn't match, so undo history will be discarded."))))
      (when (consp undo-list)
        (setq buffer-undo-list undo-list)))))

(defun undohist-recover-safe ()
  (condition-case var
      (undohist-recover-1)
    (error (message "Can not recover undo history: %s" var))))

(defun undohist-initialize ()
  "Initialize undo history facilities.
To use undohist, you just call this function."
  (interactive)
  (when (not (file-directory-p undohist-directory))
    (make-directory undohist-directory t))
  (add-hook 'before-save-hook #'undohist-save-safe)
  (add-hook 'find-file-hook #'undohist-recover-safe))

(defun undohist-recover ()
  "Recover undo history."
  (interactive)
  (undohist-recover-safe))

(defun undohist--test ()
  (cl-loop for f to 100
           with filename = "/tmp/undohist-test"
           with undohist-filename = (make-undohist-file-name filename)
           with contents do
           (if (file-exists-p filename)
               (delete-file filename))
           (if (file-exists-p undohist-filename)
               (delete-file undohist-filename))
           (with-current-buffer (find-file-literally filename)
             (cl-loop for i to 1000
                      for c = (random 3) do
                      (ignore-errors
                        (cl-case c
                          (0 (cl-loop for j to 10 do
                                      (insert (make-string (1+ (random 20))
                                                           (+ (random 26) 65)))))
                          (1 (newline))
                          (2 (insert "\t"))
                          (3 (forward-line))
                          (4 (forward-line -1))
                          (5 (kill-line))
                          (6 (kill-paragraph -1))
                          (7 (yank))
                          (8 (kill-region (+ (point-min) (randppom (point-max))) (+ (point-min) (random (point-max))))))))
             (save-buffer)
             (undohist-save)
             (kill-buffer (current-buffer)))
           (with-current-buffer (find-file-literally filename)
             (undohist-recover)
             (ignore-errors
               (while (prog1 t (undo))))
             (setq contents (buffer-string))
             (set-buffer-modified-p nil)
             (kill-buffer (current-buffer))
             (if (string= contents "")
                 (message "Test succeeded #%s" f)
               (error "Test failed #%s" f)))))

(provide 'undohist)
;;; undohist.el ends here
