;;; helm-evil-markers.el --- Show evil markers with helm  -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Bill Xue <github.com/xueeinstein>
;; Author: Bill Xue
;; URL: https://github.com/xueeinstein/helm-evil-markers
;; Package-Version: 20190623.335
;; Package-Commit: 29f9288a73370f26fe431db1472ed948bd63190d
;; Created: 2019
;; Version: 0.1
;; Package-Requires: ((emacs "24.4") (helm "2.0.0") (evil "1.2.10"))
;; Keywords: extensions

;;; Commentary:

;; Helm-evil-markers.el helps you to list evil markers with hints
;; as helm candidates.
;; This file is NOT part of GNU Emacs.

;;; Code:
(require 'helm)
(require 'evil)

(defvar helm-evil-markers-alist nil
  "The alist to record evil markers and corresponding positions.")
(defvar helm-evil-markers-tick 0
  "The chars modified tick of current buffer.")
(defvar helm-evil-markers-buffer-name nil
  "The active buffer name.")
(defvar helm-evil-markers-enabled nil
  "Record whether evil marker keybindings are reset.")

(defun helm-evil-markers-update-alist ()
  "Update cached evil markers alist."
  (setq helm-evil-markers-alist nil)
  (let ((buffer (current-buffer))
        (markers-alist (copy-alist evil-markers-alist)))
    (with-current-buffer buffer
      (dolist (element markers-alist)
        (let* ((code (car element))
               (char (byte-to-string code))
               (marker (cdr element)))
          (if (markerp marker)
              (let ((pos (marker-position marker)))
                (save-excursion
                  (goto-char pos)
                  (add-to-list
                   'helm-evil-markers-alist
                   (cons (format "%s> %s" char
                                 (replace-regexp-in-string "\n$" "" (thing-at-point 'line)))
                         pos)))))))))
  (setq helm-evil-markers-tick (buffer-chars-modified-tick))
  (setq helm-evil-markers-buffer-name (buffer-name)))

(defun helm-evil-markers-list ()
  "Get candidates as alist."
  (unless (and (equal helm-evil-markers-buffer-name (buffer-name))
               (equal helm-evil-markers-tick (buffer-chars-modified-tick)))
    (helm-evil-markers-update-alist))
  helm-evil-markers-alist)

(defun helm-evil-markers-sort (candidates _source)
  "Custom sorting for matching CANDIDATES from SOURCE."
  (let ((pattern helm-pattern))
    (if (string= pattern "")
        candidates
      (sort candidates
            (lambda (_s1 s2)
              (if (string-prefix-p (format "%s> " pattern) (car s2))
                  nil
                t))))))

;;;###autoload
(defun helm-evil-markers ()
  "List evil markers with helm."
  (interactive)
  (helm :sources (helm-build-sync-source "Evil Markers"
                   :candidates (helm-evil-markers-list)
                   :action (lambda (candidate)
                             (goto-char candidate))
                   :filtered-candidate-transformer #'helm-evil-markers-sort)
        :buffer "*helm-evil-markers*"))

;;;###autoload
(defun helm-evil-markers-set (char &optional pos advance)
  "Wrapper to set marker denoted by CHAR to position POS and update markers.
If ADVANCE is t, the marker advances when inserting text at it; otherwise,
it stays behind."
  (interactive (list (read-char)))
  (evil-set-marker char pos advance)
  (helm-evil-markers-update-alist))

;;;###autoload
(defun helm-evil-markers-toggle ()
  "Enable or disable helm-evil-markers keybindings."
  (interactive)
  (if helm-evil-markers-enabled
      (progn
        (define-key evil-normal-state-map (kbd "'") 'evil-goto-mark-line)
        (define-key evil-normal-state-map (kbd "m") 'evil-set-marker)
        (setq helm-evil-markers-enabled nil))
    (progn
      (define-key evil-normal-state-map (kbd "'") 'helm-evil-markers)
      (define-key evil-normal-state-map (kbd "m") 'helm-evil-markers-set)
      (setq helm-evil-markers-enabled t))))

(provide 'helm-evil-markers)
;;; helm-evil-markers.el ends here
