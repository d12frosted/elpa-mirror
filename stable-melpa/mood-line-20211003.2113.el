;;; mood-line.el --- A minimal mode-line inspired by doom-modeline -*- lexical-binding: t; -*-

;; Author: Jessie Hildebrandt <jessieh.net>
;; Homepage: https://gitlab.com/jessieh/mood-line
;; Keywords: mode-line faces
;; Package-Version: 20211003.2113
;; Package-Commit: ef1c752679a8f92faa7b4828adbbb300b6942f22
;; Version: 1.2.5
;; Package-Requires: ((emacs "25.1"))

;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;; mood-line is a minimal mode-line configuration that aims to replicate
;; some of the features of the doom-modeline package.
;;
;; Features offered:
;; * Clean, minimal design
;; * Anzu and multiple-cursors counter
;; * Version control status indicator
;; * Flycheck status indicator
;; * Flymake support
;; * Lightweight with no dependencies
;;
;; To enable mood-line:
;; (mood-line-mode)

;;; License:
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Code:

;;
;; Variable declarations
;;

(defvar flycheck-current-errors)
(defvar flymake--mode-line-format)
(defvar anzu-cons-mode-line-p)
(defvar anzu--state)
(defvar anzu--cached-count)
(defvar anzu--overflow-p)
(defvar anzu--current-position)
(defvar anzu--total-matched)
(defvar multiple-cursors-mode)

;;
;; Function prototypes
;;

(declare-function flycheck-count-errors "flycheck" (errors))
(declare-function mc/num-cursors "multiple-cursors" ())

;;
;; Config
;;

(defgroup mood-line nil
  "A minimal mode-line configuration inspired by doom-modeline."
  :group 'mode-line)

(defcustom mood-line-show-eol-style nil
  "If t, the EOL style of the current buffer will be displayed in the mode-line."
  :group 'mood-line
  :type 'boolean)

(defcustom mood-line-show-encoding-information nil
  "If t, the encoding format of the current buffer will be displayed in the mode-line."
  :group 'mood-line
  :type 'boolean)

(defcustom mood-line-show-cursor-point nil
  "If t, the value of `point' will be displayed next to the cursor position in the mode-line."
  :group 'mood-line
  :type 'boolean)

(defface mood-line-buffer-name
  '((t (:inherit (mode-line-buffer-id))))
  "Face used for major mode indicator in the mode-line."
  :group 'mood-line)

(defface mood-line-major-mode
  '((t (:inherit (bold))))
  "Face used for major mode indicator in the mode-line."
  :group 'mood-line)

(defface mood-line-status-neutral
  '((t (:inherit (shadow))))
  "Face used for neutral or inactive status indicators in the mode-line."
  :group 'mood-line)

(defface mood-line-status-info
  '((t (:inherit (font-lock-keyword-face))))
  "Face used for generic status indicators in the mode-line."
  :group 'mood-line)

(defface mood-line-status-success
  '((t (:inherit (success))))
  "Face used for success status indicators in the mode-line."
  :group 'mood-line)

(defface mood-line-status-warning
  '((t (:inherit (warning))))
  "Face for warning status indicators in the mode-line."
  :group 'mood-line)

(defface mood-line-status-error
  '((t (:inherit (error))))
  "Face for error stauts indicators in the mode-line."
  :group 'mood-line)

(defface mood-line-unimportant
  '((t (:inherit (shadow))))
  "Face used for less important mode-line elements."
  :group 'mood-line)

(defface mood-line-modified
  '((t (:inherit (error))))
  "Face used for the 'modified' indicator symbol in the mode-line."
  :group 'mood-line)

;;
;; Helper functions
;;

(defun mood-line--string-trim-left (string)
  "Remove whitespace at the beginning of STRING."
  (if (string-match "\\`[ \t\n\r]+" string)
      (replace-match "" t t string)
    string))

(defun mood-line--string-trim-right (string)
  "Remove whitespace at the end of STRING."
  (if (string-match "[ \t\n\r]+\\'" string)
      (replace-match "" t t string)
    string))

(defun mood-line--string-trim (string)
  "Remove whitespace at the beginning and end of STRING."
  (mood-line--string-trim-left (mood-line--string-trim-right string)))

(defun mood-line--format (left right)
  "Return a string of `window-width' length containing LEFT and RIGHT, aligned respectively."
  (let ((reserve (length right)))
    (concat left
            " "
            (propertize " "
                        'display `((space :align-to (- right (- 0 right-margin) ,reserve))))
            right)))

;;
;; Update functions
;;

(defvar-local mood-line--vc-text nil)
(defun mood-line--update-vc-segment (&rest _)
  "Update `mood-line--vc-text' against the current VCS state."
  (setq mood-line--vc-text
        (when (and vc-mode buffer-file-name)
          (let ((backend (vc-backend buffer-file-name))
                (state (vc-state buffer-file-name (vc-backend buffer-file-name))))
            (let ((face 'mode-line-neutral))
              (concat (cond ((memq state '(edited added))
                             (setq face 'mood-line-status-info)
                             (propertize "+ " 'face face))
                            ((eq state 'needs-merge)
                             (setq face 'mood-line-status-warning)
                             (propertize "⟷ " 'face face))
                            ((eq state 'needs-update)
                             (setq face 'mood-line-status-warning)
                             (propertize "↑ " 'face face))
                            ((memq state '(removed conflict unregistered))
                             (setq face 'mood-line-status-error)
                             (propertize "✖ " 'face face))
                            (t
                             (setq face 'mood-line-status-neutral)
                             (propertize "✔ " 'face face)))
                      (propertize (substring vc-mode (+ (if (eq backend 'Hg) 2 3) 2))
                                  'face face
                                  'mouse-face face)
                      "  "))))))

(defvar-local mood-line--flycheck-text nil)
(defun mood-line--update-flycheck-segment (&optional status)
  "Update `mood-line--flycheck-text' against the reported flycheck STATUS."
  (setq mood-line--flycheck-text
        (pcase status
          ('finished (if flycheck-current-errors
                         (let-alist (flycheck-count-errors flycheck-current-errors)
                           (let ((sum (+ (or .error 0) (or .warning 0))))
                             (propertize (concat "⚑ Issues: "
                                                 (number-to-string sum)
                                                 "  ")
                                         'face (if .error
                                                   'mood-line-status-error
                                                 'mood-line-status-warning))))
                       (propertize "✔ Good  " 'face 'mood-line-status-success)))
          ('running (propertize "Δ Checking  " 'face 'mood-line-status-info))
          ('errored (propertize "✖ Error  " 'face 'mood-line-status-error))
          ('interrupted (propertize "⏸ Paused  " 'face 'mood-line-status-neutral))
          ('no-checker ""))))

;;
;; Segments
;;

(defun mood-line-segment-modified ()
  "Displays a color-coded buffer modification/read-only indicator in the mode-line."
  (if (not (string-match-p "\\*.*\\*" (buffer-name)))
      (if (buffer-modified-p)
          (propertize "● " 'face 'mood-line-modified)
        (if (and buffer-read-only (buffer-file-name))
            (propertize "■ " 'face 'mood-line-unimportant)
          "  "))
    "  "))

(defun mood-line-segment-buffer-name ()
  "Displays the name of the current buffer in the mode-line."
  (propertize "%b  " 'face 'mood-line-buffer-name))

(defun mood-line-segment-anzu ()
  "Displays color-coded anzu status information in the mode-line (if available)."
  (when (and (boundp 'anzu--state) anzu--state)
    (cond ((eq anzu--state 'replace-query)
           (format #("Replace: %d  " 0 11 (face mood-line-status-warning)) anzu--cached-count))
          (anzu--overflow-p
           (format #("%d/%d+  " 0 3 (face mood-line-status-info) 3 6 (face mood-line-status-error)) anzu--current-position anzu--total-matched))
          (t
           (format #("%d/%d  " 0 5 (face mood-line-status-info)) anzu--current-position anzu--total-matched)))))

(defun mood-line-segment-multiple-cursors ()
  "Displays the number of active multiple-cursors in the mode-line (if available)."
  (when (and (boundp 'multiple-cursors-mode) multiple-cursors-mode)
    (concat "MC"
            (format #("×%d  " 0 3 (face mood-line-status-warning)) (mc/num-cursors)))))

(defun mood-line-segment-position ()
  "Displays the current cursor position in the mode-line."
  (concat "%l:%c"
          (when mood-line-show-cursor-point (propertize (format ":%d" (point)) 'face 'mood-line-unimportant))
          (propertize " %p%%  " 'face 'mood-line-unimportant)))

(defun mood-line-segment-eol ()
  "Displays the EOL style of the current buffer in the mode-line."
  (when mood-line-show-eol-style
    (pcase (coding-system-eol-type buffer-file-coding-system)
      (0 "LF  ")
      (1 "CRLF  ")
      (2 "CR  "))))

(defun mood-line-segment-encoding ()
  "Displays the encoding and EOL style of the buffer in the mode-line."
  (when mood-line-show-encoding-information
    (concat (let ((sys (coding-system-plist buffer-file-coding-system)))
              (cond ((memq (plist-get sys :category) '(coding-category-undecided coding-category-utf-8))
                     "UTF-8")
                    (t (upcase (symbol-name (plist-get sys :name))))))
            "  ")))

(defun mood-line-segment-vc ()
  "Displays color-coded version control information in the mode-line."
  mood-line--vc-text)

(defun mood-line-segment-major-mode ()
  "Displays the current major mode in the mode-line."
  (concat (format-mode-line mode-name 'mood-line-major-mode) "  "))

(defun mood-line-segment-misc-info ()
  "Displays the current value of `mode-line-misc-info' in the mode-line."
  (let ((misc-info (format-mode-line mode-line-misc-info 'mood-line-unimportant)))
    (unless (string= (mood-line--string-trim misc-info) "")
      (concat (mood-line--string-trim misc-info) "  "))))

(defun mood-line-segment-flycheck ()
  "Displays color-coded flycheck information in the mode-line (if available)."
  mood-line--flycheck-text)

(defun mood-line-segment-flymake ()
  "Displays information about the current status of flymake in the mode-line (if available)."
  (when (and (boundp 'flymake-mode) flymake-mode)
    ;; Depending on Emacs version, flymake stores the mode-line segment using one of two variable names
    (let ((flymake-segment-format (if (boundp 'flymake-mode-line-format)
                                      flymake-mode-line-format
                                    flymake--mode-line-format)))
      (concat (mood-line--string-trim (format-mode-line flymake-segment-format)) "  "))))

(defun mood-line-segment-process ()
  "Displays the current value of `mode-line-process' in the mode-line."
  (let ((process-info (format-mode-line mode-line-process)))
    (unless (string= (mood-line--string-trim process-info) "")
      (concat (mood-line--string-trim process-info) "  "))))

;;
;; Activation function
;;

(defvar-local mood-line--default-mode-line mode-line-format)
(defvar-local mood-line--anzu-cons-mode-line-p nil)

;;;###autoload
(define-minor-mode mood-line-mode
  "Toggle mood-line on or off."
  :group 'mood-line
  :global t
  :lighter nil
  (if mood-line-mode
      (progn

        ;; Setup flycheck hooks
        (add-hook 'flycheck-status-changed-functions #'mood-line--update-flycheck-segment)
        (add-hook 'flycheck-mode-hook #'mood-line--update-flycheck-segment)

        ;; Setup VC hooks
        (add-hook 'find-file-hook #'mood-line--update-vc-segment)
        (add-hook 'after-save-hook #'mood-line--update-vc-segment)
        (advice-add #'vc-refresh-state :after #'mood-line--update-vc-segment)

        ;; Disable anzu's mode-line segment setting, saving the previous setting to be restored later (if present)
        (when (boundp 'anzu-cons-mode-line-p)
          (setq mood-line--anzu-cons-mode-line-p anzu-cons-mode-line-p))
        (setq-default anzu-cons-mode-line-p nil)

        ;; Save previous mode-line-format to be restored later
        (setq mood-line--default-mode-line mode-line-format)

        ;; Set the new mode-line-format
        (setq-default mode-line-format
                      '((:eval
                         (mood-line--format
                          ;; Left
                          (format-mode-line
                           '(" "
                             (:eval (mood-line-segment-modified))
                             (:eval (mood-line-segment-buffer-name))
                             (:eval (mood-line-segment-anzu))
                             (:eval (mood-line-segment-multiple-cursors))
                             (:eval (mood-line-segment-position))))

                          ;; Right
                          (format-mode-line
                           '((:eval (mood-line-segment-eol))
                             (:eval (mood-line-segment-encoding))
                             (:eval (mood-line-segment-vc))
                             (:eval (mood-line-segment-major-mode))
                             (:eval (mood-line-segment-misc-info))
                             (:eval (mood-line-segment-flycheck))
                             (:eval (mood-line-segment-flymake))
                             (:eval (mood-line-segment-process))
                             " ")))))))
    (progn

      ;; Remove flycheck hooks
      (remove-hook 'flycheck-status-changed-functions #'mood-line--update-flycheck-segment)
      (remove-hook 'flycheck-mode-hook #'mood-line--update-flycheck-segment)

      ;; Remove VC hooks
      (remove-hook 'file-find-hook #'mood-line--update-vc-segment)
      (remove-hook 'after-save-hook #'mood-line--update-vc-segment)
      (advice-remove #'vc-refresh-state #'mood-line--update-vc-segment)

      ;; Restore anzu's mode-line segment setting
      (setq-default anzu-cons-mode-line-p mood-line--anzu-cons-mode-line-p)

      ;; Restore the original mode-line format
      (setq-default mode-line-format mood-line--default-mode-line))))

;;
;; Provide mood-line
;;

(provide 'mood-line)

;;; mood-line.el ends here
