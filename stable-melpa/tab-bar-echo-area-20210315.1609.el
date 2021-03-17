;;; tab-bar-echo-area.el --- Display tab names of the tab bar in the echo area -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021 Fritz Grabo

;; Author: Fritz Grabo <me@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/tab-bar-echo-area
;; Package-Version: 20210315.1609
;; Package-Commit: d2ff6b1acb553bf1546e730640397b9e33ca5279
;; Version: 0.2
;; Package-Requires: ((emacs "27.1"))
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

(eval-when-compile (require 'subr-x))

(defgroup tab-bar-echo-area ()
  "Display tab names of the tab bar in the echo area."
  :group 'tab-bar)

(defface tab-bar-echo-area-current-tab
  '((t :inherit bold))
  "Face to use for the current tab name.")

(defface tab-bar-echo-area-other-tab
  '((t :inherit shadow))
  "Face to use for tab names except the current one.")

(defvar tab-bar-echo-area-trigger-display-functions
  '(tab-bar-close-tab
    tab-bar-move-tab-to
    tab-bar-new-tab-to
    tab-bar-rename-tab
    tab-bar-select-tab)
  "List of functions after which to display tab names in the echo area.")

(defvar tab-bar-echo-area-process-tab-name-functions
  (list #'tab-bar-echo-area-propertize-tab-name)
  "List of functions to call to fully process a tab's name for display.

Each function is expected to take a TAB-NAME and its TAB as
arguments, and to return TAB-NAME further processed for
display.")

(defun tab-bar-echo-area-propertize-tab-name (tab-name tab)
  "Propertize TAB-NAME for TAB."
  (let ((face (if (equal (car tab) 'current-tab)
                  'tab-bar-echo-area-current-tab
                'tab-bar-echo-area-other-tab)))
    (font-lock-append-text-property 0 (length tab-name) 'face face tab-name))
  tab-name)

(defun tab-bar-echo-area-processed-tab-names ()
  "Generate a list of processed tab names."
  (mapcar #'tab-bar-echo-area-process-tab-name (funcall tab-bar-tabs-function)))

(defun tab-bar-echo-area-process-tab-name (tab)
  "Process tab name for TAB."
  (let ((tab-name (concat (alist-get 'name tab))))
    (dolist (f tab-bar-echo-area-process-tab-name-functions)
      (setq tab-name (funcall f tab-name tab)))
    tab-name))

;;;###autoload
(defun tab-bar-echo-area-display-tab-names (&rest _args)
  "Display all tab names in the echo area."
  (interactive)
  (message "Tabs: %s" (string-join (tab-bar-echo-area-processed-tab-names) ", ")))

;;;###autoload
(defalias 'tab-bar-echo-area-print-tab-names 'tab-bar-echo-area-display-tab-names)

;;;###autoload
(defun tab-bar-echo-area-display-tab-name ()
  "Display the current tab's name in the echo area."
  (interactive)
  (message "Current Tab: %s" (tab-bar-echo-area-process-tab-name (tab-bar--current-tab))))

;;;###autoload
(defalias 'tab-bar-echo-area-print-tab-name 'tab-bar-echo-area-display-tab-name)

(defun tab-bar-echo-area-display-tab-names-advice (orig-fun &rest args)
  "Call ORIG-FUN with ARGS, then display tab names in the echo area."
  (let ((result (apply orig-fun args)))
    (tab-bar-echo-area-display-tab-names)
    result))

;;;###autoload
(define-minor-mode tab-bar-echo-area-mode
  "Alternative to `tab-bar-mode': display tab names in the echo area after tab bar-related functions."
  :group 'tab-bar
  :global t
  (tab-bar-echo-area-apply-display-tab-names-advice))

(defun tab-bar-echo-area-apply-display-tab-names-advice ()
  "Add or remove advice to display tab names according to variable `tab-bar-echo-area-mode'."
  (dolist (f tab-bar-echo-area-trigger-display-functions)
    (if tab-bar-echo-area-mode
        (advice-add f :around #'tab-bar-echo-area-display-tab-names-advice)
      (advice-remove f #'tab-bar-echo-area-display-tab-names-advice))))

(provide 'tab-bar-echo-area)
;;; tab-bar-echo-area.el ends here
