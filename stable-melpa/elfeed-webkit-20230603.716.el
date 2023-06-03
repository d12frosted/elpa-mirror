;;; elfeed-webkit.el --- Render elfeed entries in embedded webkit widgets -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Fritz Grabo

;; Author: Fritz Grabo <hello@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/elfeed-webkit
;; Package-Version: 20230603.716
;; Package-Commit: 3c9e59ce2e50fa69132524a4aa5a6282cadce5ce
;; Version: 0.1
;; Package-Requires: ((emacs "26.1") (elfeed "3.4.1"))
;; Keywords: comm

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; Render elfeed entries in embedded webkit widgets.

;;; Code:

(require 'elfeed)
(require 'seq)
(require 'xwidget)

(defvar elfeed-webkit--original-refresh-function nil
  "The original value of `elfeed-show-refresh-function'; used for toggling.")

(defvar elfeed-webkit--signature "xwidget-webkit"
  "Text to attach the webkit xwidget to in the elfeed entry buffer.")

(defvar elfeed-webkit-map
  (let ((map (make-composed-keymap xwidget-webkit-mode-map elfeed-show-mode-map)))
    (prog1 map
      (define-key map "+" #'elfeed-show-tag)
      (define-key map "-" #'elfeed-show-untag)
      (define-key map "g" #'elfeed-show-refresh)
      (define-key map "q" #'elfeed-kill-buffer)
      (define-key map "v" #'elfeed-webkit-visit) ;; moved from "b", visit current URL
      (define-key map "y" #'elfeed-webkit-yank)))
  "Keymap for `elfeed-webkit'.")

;;;###autoload
(defun elfeed-webkit-toggle ()
  "Toggle rendering of elfeed entries with webkit on/off."
  (interactive)

  (if (elfeed-webkit--enabled-p)
      (elfeed-webkit--disable)
    (elfeed-webkit--enable))

  (when elfeed-show-entry
    (elfeed-show-entry elfeed-show-entry)))

(defun elfeed-webkit--enabled-p ()
  "Whether elfeed entries are rendered with webkit."
  (eq elfeed-show-refresh-function #'elfeed-webkit-refresh--webkit))

(defun elfeed-webkit--enable ()
  "Render elfeed entries with webkit."
  (setq elfeed-webkit--original-refresh-function elfeed-show-refresh-function)
  (setq elfeed-show-refresh-function #'elfeed-webkit-refresh--webkit)
  (message "Elfeed: webkit enabled"))

(defun elfeed-webkit--disable ()
  "Render elfeed entries with the original/default method."
  (when (null elfeed-webkit--original-refresh-function)
    ;; We must have started out with "webkit" as the initial refresh
    ;; function (never toggled before). Initialize the "original" to
    ;; switch to with elfeed's default, "mail-style".
    (setq elfeed-webkit--original-refresh-function #'elfeed-show-refresh--mail-style))
  (setq elfeed-show-refresh-function elfeed-webkit--original-refresh-function)
  (message "Elfeed: webkit disabled"))

(defun elfeed-webkit-refresh--webkit ()
  "Update the buffer to match the selected entry, using webkit."
  (interactive)

  (unless (featurep 'xwidget-internal)
    (user-error "Your Emacs was not compiled with xwidgets support"))

  (unless (elfeed-webkit--buffer-prepared-p)
    (elfeed-webkit--prepare-buffer))

  (let* ((xwidget (xwidget-at (point-min)))
         (link (elfeed-entry-link elfeed-show-entry)))
    (xwidget-webkit-adjust-size-to-window xwidget)
    (xwidget-webkit-goto-uri xwidget link)))

(defun elfeed-webkit--buffer-prepared-p ()
  "Whether the buffer has been prepared for rendering elfeed entries with webkit."
  (save-excursion
    (goto-char (point-min))
    (and
     (looking-at-p elfeed-webkit--signature)
     (xwidget-at (point)))))

(defun elfeed-webkit--prepare-buffer ()
  "Prepare the buffer for rendering elfeed entries with webkit.

This is split from the actual refresh function because it does
not need to re-run on `elfeed-show-refresh'."
  (elfeed-webkit--kill-xwidgets)

  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert elfeed-webkit--signature)
    (put-text-property (point-min) (+ (point-min) (length elfeed-webkit--signature)) 'invisible t)

    (let ((xwidget (xwidget-insert (point-min) 'webkit (buffer-name) 1 1)))
      (elfeed-webkit--set-cookie-storage-file xwidget)
      (set-xwidget-query-on-exit-flag xwidget nil)))

  (when (boundp 'xwidget-webkit-tool-bar-map) ;; Emacs 29.1
    (setq-local tool-bar-map xwidget-webkit-tool-bar-map))
  (setq-local bookmark-make-record-function #'xwidget-webkit-bookmark-make-record)
  (image-mode-setup-winprops)
  (use-local-map elfeed-webkit-map))

(defun elfeed-webkit--kill-xwidgets ()
  "Kill all xwidgets in the current buffer."
  (when (fboundp 'kill-xwidget) ;; Emacs 29.1
    (mapcar #'kill-xwidget (get-buffer-xwidgets (current-buffer)))))

(defun elfeed-webkit--set-cookie-storage-file (xwidget)
  "Set cookie storage file for XWIDGET (requires Emacs 29.1)."
  (when (and (fboundp 'xwidget-webkit-set-cookie-storage-file) ;; Emacs 29.1
             (boundp 'xwidget-webkit-cookie-file))
    (when xwidget-webkit-cookie-file
      (xwidget-webkit-set-cookie-storage-file
       xwidget (expand-file-name xwidget-webkit-cookie-file)))))

;; Adapted from `elfeed-show-visit': use current webkit URL.
(defun elfeed-webkit-visit (&optional use-generic-p)
  "Visit the current URL in your browser using `browse-url'.
If there is a prefix argument (via USE-GENERIC-P), use the
browser defined by `browse-url-generic-program'."
  (interactive "P")
  (let ((link (xwidget-webkit-uri (xwidget-webkit-current-session))))
    (when link
      (message "Sent to browser: %s" link)
      (if use-generic-p
          (browse-url-generic link)
        (browse-url link)))))

;; Adapted from `elfeed-show-yank': use current webkit URL.
(defun elfeed-webkit-yank ()
  "Copy the current URL to the clipboard."
  (interactive)
  (let ((link (xwidget-webkit-uri (xwidget-webkit-current-session))))
    (when link
      (kill-new link)
      (if (fboundp 'gui-set-selection)
          (gui-set-selection 'PRIMARY link)
        (with-no-warnings
          (x-set-selection 'PRIMARY link)))
      (message "Yanked: %s" link))))

(defvar elfeed-webkit-auto-tags
  '(webkit wk)
  "List of tags that will cause an elfeed entry to render with webkit.")

(defun elfeed-webkit--elfeed-show-entry-advice (orig-fun &rest args)
  "Temporarily adjust `elfeed-show-refresh-function', then call ORIG-FUN with ARGS."
  (let ((tags (elfeed-entry-tags (car args)))
        (original-refresh-function elfeed-show-refresh-function))
    (when (seq-intersection tags elfeed-webkit-auto-tags)
      (setq elfeed-show-refresh-function #'elfeed-webkit-refresh--webkit))
    (prog1
        (apply orig-fun args)
      (setq elfeed-show-refresh-function original-refresh-function))))

;;;###autoload
(defun elfeed-webkit-auto-enable-by-tag ()
  "Automatically render elfeed entries with webkit if they have certain tags.

If an entry has a tag listed in `elfeed-webkit-auto-tags', render
it with webkit when it is shown.  Webkit can still be toggled on
or off manually in the entry's buffer."
  (interactive)
  (advice-add 'elfeed-show-entry :around #'elfeed-webkit--elfeed-show-entry-advice))

(provide 'elfeed-webkit)
;;; elfeed-webkit.el ends here
