;;; cycle-themes.el --- A global minor mode to make switching themes easier

;; Copyright (C) 2015 Katherine Whitlock
;;
;; Authors: Katherine Whitlock <toroidalcode@gmail.com>
;; URL: http://github.com/toroidal-code/cycle-themes.el
;; Package-Version: 20150403.309
;; Package-Commit: 2660c3178be7b28c2cb5dde2dd70a4bd51dae3a2
;; Version: 1.0
;; Package-Requires: ((cl-lib "0.5"))
;; Keywords: Themes, Utility, Global Minor Mode

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Allows switching between themes easily.

;;; Installation

;; In your Emacs config, define a list of themes you want to be
;; able to switch between.  Then, enable the global minor mode.
;;
;;     (setq cycle-themes-theme-list
;;           '(leuven monokai solarized-dark))
;;     (require 'cycle-themes)
;;     (cycle-themes-mode)
;;
;; `cycle-themes' is bound to 'C-c C-t' by default.
;;
;; You can optionally add hooks to be run after switching themes:
;;
;; (add-hook 'cycle-themes-after-cycle-hook
;;           #'(lambda () (Do-something-fn ...)))
;;

;;; License:

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 3 of the License, or (at your option) any later
;; version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along with
;; GNU Emacs; see the file COPYING.  If not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
;; USA.

;;; Code:

(eval-when-compile
  (require 'cl-lib))

(defgroup cycle-themes nil
  "The cycle-themes group"
  :group 'appearance
  :prefix "cycle-themes-")

(defcustom cycle-themes-after-cycle-hook nil
  "Hooks that are run after switching themes."
  :group 'cycle-themes
  :type 'hook)

(defcustom cycle-themes-theme-list (custom-available-themes)
  "The list of themes to cycle through on calling `cycle-themes'."
  :group 'cycle-themes
  :type '(list symbol))

(defcustom cycle-themes-allow-multiple-themes nil
  "Whether to allow the application of more than one theme at once."
  :group 'cycle-themes
  :type 'boolean)

(defconst cycle-themes-last-theme-set custom-enabled-themes
  "Used with multiple theme layering.")

(defconst cycle-themes-first-start t
  "load-theme reapplies all minor-modes, so we need this to avoid a stack overflow.")

(defun cycle-themes-get-next-valid-theme ()
  "Get the next valid theme from the list."
  ;; save our starting theme for a infinite-loop check
  ;; if there's no theme applied,
  (let* ((start-theme (or (first custom-enabled-themes)
                          (car (last cycle-themes-theme-list))))
         (current-theme start-theme))
    ;; do-while
    (while
        (progn
          ;; Fancy way to move to the next theme
          ;; with modular arithmetic so we never reach the end.
          (setq current-theme
                (nth (mod (1+ (cl-position current-theme cycle-themes-theme-list))
                          (length cycle-themes-theme-list))
                     cycle-themes-theme-list))
          ;; Make sure we didn't loop all the way through
          (when (eq current-theme start-theme)
            (error "No valid themes in cycle-themes-theme-list"))
          (not (custom-theme-p current-theme))))
    current-theme))


(defun cycle-themes ()
  "Cycle to the next theme."
  (interactive)
  (let ((new-theme (cycle-themes-get-next-valid-theme))
        (current-theme (first custom-enabled-themes))
        (current-theme-set custom-enabled-themes))
    ;; disable the current theme only if we want multiple themes
    ;; and we had it before
    (unless (and cycle-themes-allow-multiple-themes
                 (member current-theme cycle-themes-last-theme-set))
      (disable-theme current-theme))
    (load-theme new-theme t)
    (setq cycle-themes-last-theme-set current-theme-set)
    (run-hooks 'cycle-themes-after-cycle-hook)))

;;;###autoload
(define-minor-mode cycle-themes-mode
  "Minor mode for cycling between themes."
  :lighter ""
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c C-t") 'cycle-themes)
            map)
  :global t
  (progn
    ;; remove any lingering themes other than the primary
    (dolist (theme (cl-set-difference (custom-available-themes)
                                      custom-enabled-themes))
      (disable-theme theme))

    ;; If we _aren't_ already trying to start up
    (when cycle-themes-first-start
      (setq cycle-themes-first-start nil)

      ;; if there are no themes enabled, enable
      ;; the first one in the list
      (if (null custom-enabled-themes)
          (add-hook 'emacs-startup-hook
                    #'(lambda ()
                        (load-theme (car cycle-themes-theme-list))
                        (run-hooks 'cycle-themes-after-cycle-hook)))
        
        ;; otherwise, ensure they're _actually_ loaded
        (add-hook 'emacs-startup-hook #'(lambda ()
                                          (dolist (theme (reverse custom-enabled-themes))
                                            (load-theme theme))
                                          (run-hooks 'cycle-themes-after-cycle-hook)))))))

(provide 'cycle-themes)
;;; cycle-themes.el ends here
