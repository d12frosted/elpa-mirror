;;; helm-evil-markers.el --- Show evil markers with helm  -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Bill Xue <github.com/xueeinstein>
;; Author: Bill Xue
;; URL: https://github.com/xueeinstein/helm-evil-markers
;; Package-Version: 20200506.715
;; Package-Commit: 0245f0c268e0eaec85df51ab2deba7ac961f6770
;; Created: 2019
;; Version: 0.1
;; Package-Requires: ((emacs "25.1") (helm "2.0.0") (evil "1.2.10"))
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
(defvar helm-evil-markers-global-markers-hints nil
  "The alist to cache hints for evil global markers.")
(defvar helm-evil-markers-tick 0
  "The chars modified tick of current buffer.")
(defvar helm-evil-markers-buffer-name nil
  "The active buffer name.")
(defvar helm-evil-markers-enabled nil
  "Record whether evil marker keybindings are reset.")
(defvar helm-evil-markers-hint-max-length 60
  "Maximum length of hint text.")

(defun helm-evil-markers-get-hint ()
  "Get hint text."
  (truncate-string-to-width
   (replace-regexp-in-string "\n$" "" (thing-at-point 'line))
   helm-evil-markers-hint-max-length))

(defcustom helm-evil-markers-exclusion-enabled nil
  "Whether to use helm-evil-markers-exclude-marks to filter out marker list."
  :type 'boolean
  :group 'helm-evil-markers)

(defcustom helm-evil-markers-exclude-marks '("^" "[" "]")
  "Marks which should not be displayed on selection menu."
  :type '(repeat string)
  :group 'helm-evil-markers)

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
          (cond
           ((and (markerp marker)
                 (not (evil-global-marker-p code)))
            (save-excursion
              (goto-char (marker-position marker))
              (add-to-list
               'helm-evil-markers-alist
               (cons (format "%s> %s" char (helm-evil-markers-get-hint))
                     marker))))
           ((and (markerp marker)
                 (evil-global-marker-p code))
            (if (equal buffer (marker-buffer marker))
                (save-excursion
                  (goto-char (marker-position marker))
                  (setf (alist-get code helm-evil-markers-global-markers-hints)
                        (helm-evil-markers-get-hint))))
            (add-to-list
             'helm-evil-markers-alist
             (cons (format "%s> %s\n%s" char (buffer-name (marker-buffer marker))
                           (alist-get code helm-evil-markers-global-markers-hints))
                   marker))))))))
  (setq helm-evil-markers-tick (buffer-chars-modified-tick))
  (setq helm-evil-markers-buffer-name (buffer-name)))

(defun helm-evil-markers-list ()
  "Get candidates as alist."
  (unless (and (equal helm-evil-markers-buffer-name (buffer-name))
               (equal helm-evil-markers-tick (buffer-chars-modified-tick)))
    (helm-evil-markers-update-alist))
  (if helm-evil-markers-exclusion-enabled
      (seq-filter
       (lambda (str)
         (not (member (substring (car str) 0 1) helm-evil-markers-exclude-marks)))
       helm-evil-markers-alist)
    helm-evil-markers-alist))

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
                   :action (lambda (marker)
                             (progn (switch-to-buffer (marker-buffer marker))
                                    (goto-char (marker-position marker))))
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
