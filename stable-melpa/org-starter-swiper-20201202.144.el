;;; org-starter-swiper.el --- Swiper for org-starter -*- lexical-binding: t -*-

;; Copyright (C) 2019 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.1.1
;; Package-Version: 20201202.144
;; Package-Commit: 786257e682bf147022d5b19e6df6e7c9939193af
;; Package-Requires: ((emacs "25.1") (swiper "0.11") (org-starter "0.2.4"))
;; URL: https://github.com/akirak/org-starter

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This library provides swiper integration for org-starter.
;; At present, only `org-starter-swiper-config-files' is provided.

;;; Code:

(require 'org-starter)
(require 'swiper)
(require 'ivy)

(defgroup org-starter-swiper nil
  "Swiper integration for org-starter."
  :group 'org-starter
  :group 'swiper)

(defcustom org-starter-swiper-max-window-width 120
  "Maximum width of the window of `org-starter-swiper-config-files'.

When this variable is set, `swiper-window-width' of the command
cannot be greater than the value."
  :type 'number
  :group 'org-starter-swiper)

(defcustom org-starter-swiper-width-function
  'org-starter-swiper-default-width
  "Function to determine the width of the swiper contents."
  :type 'function
  :group 'org-starter-swiper)

(defun org-starter-swiper-default-width ()
  "Calculate the inner width of the frame."
  (- (- (frame-width) (if (display-graphic-p) 0 1)) 4))

;;;###autoload
(defun org-starter-swiper-config-files ()
  "Run `swiper-multi' for the config files."
  (interactive)
  (let* ((buffers (mapcar (lambda (file)
                            (or (find-buffer-visiting file)
                                (find-file-noselect file)))
                          (org-starter--get-existing-config-files)))
         (default-width (funcall org-starter-swiper-width-function))
         (max-width org-starter-swiper-max-window-width)
         (swiper-window-width (if max-width
                                  (min max-width default-width)
                                default-width)))
    (ivy-read "Swiper: " (swiper--multi-candidates buffers)
              :action #'swiper-multi-action-2
              ;; :update-fn #'org-starter-swiper--update-fn
              :unwind #'swiper--cleanup
              :caller 'org-starter-swiper-config-files)))

(add-to-list 'ivy-format-functions-alist
             '(org-starter-swiper-config-files . swiper--all-format-function))

(defun org-starter-swiper--config-file-other-window (x)
  "Move to candidate X."
  (when (> (length x) 0)
    (let ((buffer-name (get-text-property 0 'buffer x)))
      (when buffer-name
        (switch-to-buffer-other-window buffer-name)
        (goto-char (point-min))
        (forward-line (1- (read (get-text-property 0 'swiper-line-number x))))
        (re-search-forward
         (ivy--regex ivy-text)
         (line-end-position) t)))))

(ivy-add-actions 'org-starter-swiper-config-files
                 '(("j" org-starter-swiper--config-file-other-window "other window")))

(defun org-starter-swiper--update-fn ()
  "Function run when input is updated in `org-starter-swiper-config-files'."
  (when-let ((current (ivy-state-current ivy-last))
             (buffer-name (get-text-property 0 'buffer current)))
    (with-ivy-window
      (swiper--cleanup)
      (switch-to-buffer buffer-name)
      (goto-char (point-min))
      (forward-line (1- (read (get-text-property 0 'swiper-line-number current))))
      (re-search-forward
       (ivy--regex ivy-text)
       (line-end-position) t)
      (isearch-range-invisible (line-beginning-position)
                               (line-end-position))
      (swiper--add-overlays
       (ivy--regex ivy-text)))))

(provide 'org-starter-swiper)
;;; org-starter-swiper.el ends here
