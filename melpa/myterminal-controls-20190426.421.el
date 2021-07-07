;;; myterminal-controls.el --- Quick toggle controls at a key-stroke -*- lexical-binding: t; -*-

;; This file is not part of Emacs

;; Author: Mohammed Ismail Ansari <team.terminal@gmail.com>
;; Version: 1.3
;; Package-Version: 20190426.421
;; Package-Commit: 733cdd7ab4f172b6dca09720fc5ae7dbc248c822
;; Keywords: convenience, shortcuts
;; Maintainer: Mohammed Ismail Ansari <team.terminal@gmail.com>
;; Created: 2015/04/17
;; Package-Requires: ((emacs "24"))
;; Description: Quick toggle controls at a key-stroke
;; URL: http://ismail.teamfluxion.com
;; Compatibility: Emacs24


;; COPYRIGHT NOTICE
;;
;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
;; for more details.
;;

;;; Install:

;; Put this file on your Emacs-Lisp load path and add the following to your
;; ~/.emacs startup file
;;
;;     (require 'myterminal-controls)
;;
;; Set a key-binding to open the quick-toggle controls window anytime
;;
;;     (global-set-key (kbd "C-M-`") 'myterminal-controls-open-controls)
;;
;; You can also set your custom list of quick-toggle controls
;;
;;     (myterminal-controls-set-controls-data
;;         (list '("1" "Invert colors"
;;                 (lambda ()
;;                   (invert-face 'default))
;;                 t)
;;               '("2" "Invert mode-line"
;;                 (lambda ()
;;                   (invert-face 'mode-line)))))
;;
;; Each item in the list should contain 3 to 4 elements:
;;
;; * Key combination information
;; * Text to be displayed in the controls window
;; * Function to be executed against the key combination
;; * [Optional] Whether the controls window should close after the command
;;

;;; Commentary:

;;     You can use myterminal-controls to save a lot of key-bindings by grouping
;;     them into a single controls window. The controls window can be opened
;;     with a key-binding and the rest key-bindings are displayed within the
;;     controls window.
;;
;;  Overview of features:
;;
;;     o   Saves key-bindings for simple toggle operations
;;     o   Groups a lot of toggles into a single window
;;

;;; Code:

(defvar myterminal-controls--controls-data
  nil)

(defvar myterminal-controls--buffer-name
  " *myterminal-controls*")

;;;###autoload
(defun myterminal-controls-set-controls-data (data)
  "Sets details of controls required in the controls window"
  (setq myterminal-controls--controls-data
        data)
  (add-to-list 'myterminal-controls--controls-data
               '("q" "Close"
                 (lambda ())
                 t)
               t))

;;;###autoload
(defun myterminal-controls-open-controls ()
  "Opens the controls window"
  (interactive)
  (let ((my-buffer (get-buffer-create myterminal-controls--buffer-name))
        (my-window (split-window-vertically (- (myterminal-controls--get-required-window-height)))))
    (set-window-buffer my-window
                       my-buffer)
    (other-window 1)
    (myterminal-controls--prepare-controls myterminal-controls--controls-data)))

;;;###autoload
(defun myterminal-controls-close-controls ()
  "Closes the controls window"
  (interactive)
  (let ((my-window (get-buffer-window (get-buffer-create myterminal-controls--buffer-name))))
    (cond ((windowp my-window) (progn
                                 (delete-window my-window)
                                 (kill-buffer (get-buffer-create myterminal-controls--buffer-name))
                                 (other-window -1))))))

(defun myterminal-controls--get-required-window-height ()
  "Gets the approproate window height for controls"
  (let ((half-window-height (/ (window-height)
                               2))
        (padded-controls-data-length (+ (length myterminal-controls--controls-data)
                                        4)))
    (cond ((< half-window-height
              padded-controls-data-length) half-window-height)
          (t padded-controls-data-length))))

(defun myterminal-controls--prepare-controls (pairs)
  "Sets up the controls window"
  (mapc 'myterminal-controls--display-controls-bindings
        pairs)
  (myterminal-controls-mode)
  (mapc 'myterminal-controls--apply-keyboard-bindings
        pairs))

(defun myterminal-controls--apply-keyboard-bindings (pair)
  "Applies key-bindings with a wrapper"
  (let ((func (nth 2 pair)))
    (local-set-key (kbd (car pair))
                   (lambda ()
                     (interactive)
                     (other-window -1)
                     (funcall func)
                     (other-window 1)
                     (if (nth 3
                              pair)
                         (myterminal-controls-close-controls))))))

(defun myterminal-controls--display-controls-bindings (pair)
  "Display controls in the controls window"
  (princ (concat "["
                 (nth 0
                      pair)
                 "] - "
                 (nth 1
                      pair)
                 "\n")
         (get-buffer-create myterminal-controls--buffer-name)))

(define-derived-mode myterminal-controls-mode
  special-mode
  "myterminal-controls"
  :abbrev-table nil
  :syntax-table nil
  (setq cursor-type nil))

(myterminal-controls-set-controls-data
 (list '("1" "Toggle menu-bar"
         (lambda ()
           (cond (menu-bar-mode (menu-bar-mode -1))
                 (t (menu-bar-mode t)))))
       '("2" "Toggle tool-bar"
         (lambda ()
           (cond (tool-bar-mode (tool-bar-mode -1))
                 (t (tool-bar-mode t)))))
       '("3" "Toggle scroll-bar"
         (lambda ()
           (cond (scroll-bar-mode (scroll-bar-mode -1))
                 (t (scroll-bar-mode t)))))
       '("4" "Invert colors"
         (lambda ()
           (invert-face 'default))
         t)))

(provide 'myterminal-controls)

;;; myterminal-controls.el ends here
