;;; tab-bar-echo-area.el --- Display tab names of the tab bar in the echo area -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021 Fritz Grabo

;; Author: Fritz Grabo <me@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/tab-bar-echo-area
;; Package-Version: 20210213.2136
;; Package-Commit: 8fdbe5187ab81f2c2434a2f2d77974aa48d0d239
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (s "1.12.0"))
;; Keywords: convenience

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

;; Provides a global minor mode to temporarily display a list of
;; available tab names (with the current tab's name highlighted) in the
;; echo area after tab-related commands.

;; The list of tab names shows after creating, closing, switching to,
;; and renaming a tab, and remains visible until the next command is
;; issued.

;; This is intended to be used as an unobtrusive replacement for the
;; Emacs built-in display of the tab-bar (that is, when you have
;; `tab-bar-show' set to nil).

;; The idea is to provide but a quick visual orientation aid to the user
;; after tab-related commands, and then get out of the way again.

;; I recommend using this in combination with the tab-bar-lost-commands
;; package, which provides simple and convenient commands that help with
;; common tab bar use-cases regarding the creation, selection and
;; movement of tabs.

;;; Code:

(require 's)

(defun tab-bar-echo-area--highlight-tab-name (tab-name)
  "Return a highlighted version of TAB-NAME."
  (let ((propertized-tab-name (concat tab-name)))
    ;; See https://www.gnu.org/software/emacs/manual/html_node/elisp/Face-Attributes.html#Face-Attributes.
    (font-lock-append-text-property 0 (length tab-name) 'face '(:inverse-video t) propertized-tab-name)
    propertized-tab-name))

;;;###autoload
(defun tab-bar-echo-area-print-tab-names (&rest _args)
  "Prints all tab names with the current tab's name highlighted to the echo area."
  (interactive)
  (let* ((tab-names (mapcar (lambda (tab) (alist-get 'name tab)) (funcall tab-bar-tabs-function)))
         (current-tab-name (alist-get 'name (tab-bar--current-tab)))
         (tab-names-with-current-tab-highlighted
          (mapcar
           (lambda (tab-name)
             (if (string-equal tab-name current-tab-name)
                 (tab-bar-echo-area--highlight-tab-name tab-name)
               tab-name))
           tab-names)))
    (message "Tabs: %s" (s-join ", " tab-names-with-current-tab-highlighted))))

;;;###autoload
(defun tab-bar-echo-area-print-tab-name ()
  "Print the current tab's name to the echo area."
  (interactive)
  (message "Current Tab: %s" (alist-get 'name (tab-bar--current-tab))))

(defvar tab-bar-echo-area-functions
  '(tab-bar-close-tab
    tab-bar-move-tab-to
    tab-bar-new-tab-to
    tab-bar-rename-tab
    tab-bar-select-tab)
  "List of functions after which to print tab names in echo area.")

(defun tab-bar-echo-area-print-tab-names-advice (orig-fun &rest args)
  "Call ORIG-FUN with ARGS, then print tab names in echo area."
  (let ((result (apply orig-fun args)))
    (tab-bar-echo-area-print-tab-names)
    result))

;;;###autoload
(define-minor-mode tab-bar-echo-area-mode
  "Alternative to `tab-bar-mode': print tab names in echo area after tab bar-related functions."
  :group 'tab-bar
  :global t
  (dolist (f tab-bar-echo-area-functions)
    (if tab-bar-echo-area-mode
        (advice-add f :around #'tab-bar-echo-area-print-tab-names-advice)
      (advice-remove f #'tab-bar-echo-area-print-tab-names-advice))))

(provide 'tab-bar-echo-area)
;;; tab-bar-echo-area.el ends here
