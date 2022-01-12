;;; helm-selected.el --- helm extension for selected.el  -*- lexical-binding: t; -*-
;; Copyright (C) 2017 Takaaki ISHIKAWA
;;
;; Author: Takaaki ISHIKAWA <takaxp at ieee dot org>
;; Keywords: extensions, convenience
;; Package-Version: 20171223.210
;; Package-Commit: a9c769998bc56373d19f0ec9cbbbb4bd89a43c2d
;; Version: 0.9.1
;; Maintainer: Takaaki ISHIKAWA <takaxp at ieee dot org>
;; URL: https://github.com/takaxp/helm-selected
;; Package-Requires: ((emacs "24.4") (helm "2.8.6") (selected "1.01"))
;; Twitter: @takaxp

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

;; This package provides a `helm' extension for displaying candidates of associated command or action regarding `selected.el'.

;;; Code:
(eval-when-compile
  (require 'cl-lib))

(require 'helm)
(require 'selected)

(defvar helm-selected--major-mode nil
  "The current `major-mode', not `helm'.")

(defvar helm-selected--source
  `((name . "Helm selected")
    (action . helm-selected--action)
    (candidate-number-limit . 9999)
    (candidates . helm-selected--candidates))
  "A helm source from selected.el.")

(defun helm-selected--action (candidate)
  "An action for selected item specified by `CANDIDATE'."
  (when (string-match "^.+\t\\(.*\\)$" candidate)
    (call-interactively (intern (match-string 1 candidate)))))

(defun helm-selected--candidates ()
  "Generate a list of candidates form `selected-keymap' or extended keymap."
  (helm-selected--get-commands
   (or (helm-selected--major-map)
       selected-keymap)))

(defun helm-selected--get-commands (keymap)
  "Create a list from the specified `KEYMAP'."
  (if (keymapp keymap)
      (cl-loop for i in (cdr keymap)
            when (consp i)
            unless (string= "helm-selected" (format "%s" (cdr i)))
            collect (format "(%s)\t%s"
                            (let ((key (car i)))
                              (if (characterp key)
                                  (string key) key))
                            (cdr i)))
    (error "The argument is NOT keymap")))

(defun helm-selected--major-map ()
  "Generate a list of candidates if a map is specified for major mode."
  (let ((major-map
         (intern
          (concat "selected-"
                  (format "%s" helm-selected--major-mode)
                  "-map"))))
    (and (boundp major-map)
         (keymapp (symbol-value major-map))
         (symbol-value major-map))))

(defun helm-selected--on ()
  "An advice function for `selected-on'."
  (setq helm-selected--major-mode major-mode))

(defun helm-selected-off ()
  "An advice function for `selected-off'."
  (interactive)
  (helm-selected--banish-major-mode-map)
  (setq helm-selected--major-mode nil))

(defun helm-selected--banish-major-mode-map ()
  "Unintern selected-<major-mode>-map."
  (let ((map
         (concat "selected-" (format "%s" helm-selected--major-mode) "-map")))
    (unless (boundp (intern-soft map))
      (unintern map nil))))

(advice-add 'selected--on :after #'helm-selected--on)
(advice-add 'selected-off :before #'helm-selected-off)

;;;###autoload
(defun helm-selected ()
  "Select from selected commands to execute."
  (interactive)
  (when mark-active
    (helm :sources '(helm-selected--source)
          :buffer "*helm selected*")
    (helm-selected--banish-major-mode-map)))

(provide 'helm-selected)

;;; helm-selected.el ends here
