;;; terminal-focus-reporting.el --- Minor mode for terminal focus reporting. -*- lexical-binding: t; -*-

;; Copyright © 2018 Vitalii Elenhaupt <velenhaupt@gmail.com>
;; Author: Vitalii Elenhaupt
;; URL: https://github.com/veelenga/terminal-focus-reporting.el
;; Package-Version: 20180830.719
;; Package-Commit: 6b1dbb2e96b3ff680dbe88153c4c569adbbd64ce
;; Keywords: convenience
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.4"))

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Minor mode for terminal focus reporting.
;;
;; This plugin restores `focus-in-hook`, `focus-out-hook` functionality.
;; Now Emacs can, for example, save when the terminal loses a focus, even if it's inside the tmux.
;;
;; Usage:
;;
;; 1. Install it from Melpa
;;
;; 2. Add code to the Emacs config file:
;;
;;       (unless (display-graphic-p)
;;         (require 'terminal-focus-reporting)
;;         (terminal-focus-reporting-mode))
;;; Code:

(defgroup terminal-focus-reporting nil
  "Minor mode for terminal focus reporting."
  :prefix "terminal-focus-reporting-"
  :group 'convenience
  :group 'tools
  :link '(url-link :tag "GitHub" "https://github.com/veelenga/terminal-focus-reporting.el"))

(defconst terminal-focus-reporting-enable-seq "\e[?1004h")
(defconst terminal-focus-reporting-disable-seq "\e[?1004l")

(defun terminal-focus-reporting--in-tmux? ()
  "Running in tmux."
  (getenv "TMUX"))

(defun terminal-focus-reporting--make-tmux-seq (seq)
  "Make escape sequence SEQ for tmux."
  (let ((prefix "\ePtmux;\e")
        (suffix "\e\\"))
    (concat prefix seq suffix seq)))

(defun terminal-focus-reporting--make-focus-reporting-seq (mode)
  "Make focus reporting escape sequence for MODE."
  (let ((seq (cond ((eq mode 'on) terminal-focus-reporting-enable-seq)
                   ((eq mode 'off) terminal-focus-reporting-disable-seq)
                   (t nil))))
    (if seq
        (progn
          (if (terminal-focus-reporting--in-tmux?)
              (terminal-focus-reporting--make-tmux-seq seq)
            seq))
      nil)))

(defun terminal-focus-reporting--apply-to-terminal (seq)
  "Send escape sequence SEQ to a terminal."
  (when (and seq (stringp seq))
    (send-string-to-terminal seq)
    (send-string-to-terminal seq)))

(defun terminal-focus-reporting--activate ()
  "Enable terminal focus reporting."
  (terminal-focus-reporting--apply-to-terminal
   (terminal-focus-reporting--make-focus-reporting-seq 'on)))

(defun terminal-focus-reporting--deactivate ()
  "Disable terminal focus reporting."
  (terminal-focus-reporting--apply-to-terminal
   (terminal-focus-reporting--make-focus-reporting-seq 'off)))

;;; Minor mode
(defcustom terminal-focus-reporting-keymap-prefix (kbd "M-[")
  "Terminal focus reporting keymap prefix."
  :group 'terminal-focus-reporting
  :type 'string)

(defvar terminal-focus-reporting-mode-map
  (let ((map (make-sparse-keymap)))
    (let ((prefix-map (make-sparse-keymap)))
      (define-key prefix-map (kbd "i") (lambda () (interactive) (handle-focus-in 0)))
      (define-key prefix-map (kbd "o") (lambda () (interactive) (handle-focus-out 0)))
      (define-key map terminal-focus-reporting-keymap-prefix prefix-map))
    map)
  "Keymap for Terminal Focus Reporting mode.")

;;;###autoload
(define-minor-mode terminal-focus-reporting-mode
  "Minor mode for terminal focus reporting integration."
  :init-value nil
  :global t
  :lighter " Terminal Focus Reporting"
  :group 'terminal-focus-reporting
  (if terminal-focus-reporting-mode
      (progn
        (terminal-focus-reporting--activate)
        (add-hook 'kill-emacs-hook 'terminal-focus-reporting--deactivate))
    (terminal-focus-reporting--deactivate)
    (remove-hook 'kill-emacs-hook 'terminal-focus-reporting--deactivate)))

(provide 'terminal-focus-reporting)
;;; terminal-focus-reporting.el ends here
