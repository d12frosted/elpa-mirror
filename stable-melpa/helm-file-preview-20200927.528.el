;;; helm-file-preview.el --- Preview the current helm file selection  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Shen, Jen-Chieh
;; Created date 2019-06-18 14:03:53

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Preview the current helm selection.
;; Keyword: file helm preview select selection
;; Version: 0.1.5
;; Package-Version: 20200927.528
;; Package-Commit: 0828c3c8975b34394d6ac7b73940113020cd50ab
;; Package-Requires: ((emacs "25.1") (helm "2.0"))
;; URL: https://github.com/jcs-elpa/helm-file-preview

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Preview the current helm file selection.
;;

;;; Code:


(require 'helm)

(defgroup helm-file-preview nil
  "Preview the current helm file selection."
  :prefix "helm-file-preview-"
  :group 'tools
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/helm-file-preview"))

(defcustom helm-file-preview-only-when-line-numbers t
  "Find the file only when the line numbers appears in the selection."
  :type 'boolean
  :group 'helm-file-preview)

(defcustom helm-file-preview-preview-only t
  "Preview the file instead of actually opens the file."
  :type 'boolean
  :group 'helm-file-preview)

(defvar helm-file-preview--prev-window nil
  "Record down the previous window before we do `helm-' related commands.")

(defvar helm-file-preview--file-buffer-list '()
  "List of file buffer that are previewing, and ready to be killed again.")

(defvar helm-file-preview--current-select-fb nil
  "Record current selecting file buffer.")

(defvar helm-file-preview--prev-buffer-list '()
  "Record the previous buffer list.")

(defvar helm-file-preview--exiting t
  "Exit flag for this minor mode.")

;;; Core

(defun helm-file-preview--do-preview (fp ln cl)
  "Do preview with filepath (FP), line number (LN), column (CL)."
  (let (did-find-file)
    (save-selected-window
      (when (or (not helm-file-preview-only-when-line-numbers)
                (and helm-file-preview-only-when-line-numbers ln))
        (select-window helm-file-preview--prev-window)

        (find-file fp)
        (setq did-find-file t)

        (when helm-file-preview-preview-only
          (setq helm-file-preview--current-select-fb (current-buffer))
          (push helm-file-preview--current-select-fb helm-file-preview--file-buffer-list)
          (delete-dups helm-file-preview--file-buffer-list)))

      (when did-find-file
        (let (ln-num cl-num)
          (when ln
            (setq ln-num (string-to-number ln))
            (when (< 0 ln-num)
              (goto-char (point-min))
              (forward-line (1- ln-num))
              (when cl
                (setq cl-num (string-to-number cl))
                (when (< 0 cl-num)
                  (move-to-column (1- cl-num)))))))))))

(defun helm-file-preview--helm-move-selection-after-hook (&rest _args)
  "Helm after move selection for `helm-' related commands preview action.
ARGS : rest of the arguments."
  (let ((selection-str (helm-get-selection nil t)))
    (when (and helm-file-preview--prev-window
               selection-str)
      (let* ((sel-lst (split-string selection-str ":"))
             (fn (nth 0 sel-lst))   ; filename
             (ln (nth 1 sel-lst))   ; line
             (cl (nth 2 sel-lst))   ; column
             (root (cdr (project-current)))
             (fp (concat root fn))  ; file path
             )
        ;; NOTE: Try expand file, if the file not found relative to
        ;; project directory.
        (unless (file-exists-p fp) (setq fp (expand-file-name fn)))
        (when (file-exists-p fp)
          (helm-file-preview--do-preview fp ln cl))))))

(defun helm-file-preview--opened-buffer (in-list in-buf)
  "Check if the IN-BUF in the opened buffer list, IN-LIST."
  (cl-some #'(lambda (buf) (equal buf in-buf)) in-list))

(defun helm-file-preview--helm-before-initialize-hook ()
  "Record all necessary info for `helm-file-preview' package to work."
  (setq helm-file-preview--prev-window (selected-window))
  (setq helm-file-preview--file-buffer-list '())
  (setq helm-file-preview--current-select-fb nil)
  (setq helm-file-preview--prev-buffer-list (buffer-list))
  (setq helm-file-preview--exiting nil))

(defun helm-file-preview--cleanup ()
  "Clean up and kill preview files."
  (when (and helm-file-preview-preview-only
             (not helm-file-preview--exiting))
    (dolist (fb helm-file-preview--file-buffer-list)
      (when (and (not (equal helm-file-preview--current-select-fb fb))
                 (not (helm-file-preview--opened-buffer helm-file-preview--prev-buffer-list fb)))
        (kill-buffer fb)))
    (setq helm-file-preview--exiting t)))

(defun helm-file-preview--exit ()
  "When exit this minor mode."
  (setq helm-file-preview--current-select-fb nil)
  (helm-file-preview--cleanup))

;;; Entry

(defun helm-file-preview--enable ()
  "Enable `helm-file-preview'."
  (add-hook 'helm-before-initialize-hook #'helm-file-preview--helm-before-initialize-hook)
  (add-hook 'helm-cleanup-hook #'helm-file-preview--cleanup)
  (add-hook 'minibuffer-exit-hook #'helm-file-preview--exit)
  (advice-add 'helm-mark-current-line :after 'helm-file-preview--helm-move-selection-after-hook))

(defun helm-file-preview--disable ()
  "Disable `helm-file-preview'."
  (remove-hook 'helm-before-initialize-hook #'helm-file-preview--helm-before-initialize-hook)
  (remove-hook 'helm-cleanup-hook #'helm-file-preview--cleanup)
  (remove-hook 'minibuffer-exit-hook #'helm-file-preview--exit)
  (advice-remove 'helm-mark-current-line 'helm-file-preview--helm-move-selection-after-hook))

;;;###autoload
(define-minor-mode helm-file-preview-mode
  "Minor mode 'helm-file-preview-mode'."
  :global t
  :require 'helm-file-preview
  :group 'helm-file-preview
  (if helm-file-preview-mode (helm-file-preview--enable) (helm-file-preview--disable)))

(provide 'helm-file-preview)
;;; helm-file-preview.el ends here
