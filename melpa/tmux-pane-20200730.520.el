;;; tmux-pane.el --- Provide integration between emacs window and tmux pane  -*- lexical-binding: t; -*-

;; Copyright (C) 2018

;; URL: https://github.com/laishulu/emacs-tmux-pane
;; Package-Version: 20200730.520
;; Package-Commit: 923524efe8e6e5e0d269de6bb253b45e02d9a663
;; Created: November 1, 2018
;; Keywords: convenience, terminals, tmux, window, pane, navigation, integration
;; Package-Requires: ((names "0.5") (emacs "24") (s "0"))
;; Version: 0.1

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
;;; This package provide integration between Emacs window and tmux pane.
;;; For more information see the README in the github repo.

;;; Code:

;; `define-namespace' is autoloaded, so there's no need to require
;; `names'. However, requiring it here means it will also work for
;; people who don't install through package.el.
(eval-when-compile (require 'names))
(require 'subr-x)

;;;###autoload
(define-namespace tmux-pane-

(defcustom vertical-percent 25
  "Horizontal percent of the vertical pane."
  :type 'integer
  :group 'tmux-pane)

(defcustom horizontal-percent 25
  "Horizontal percent of the horizontal pane."
  :type 'integer
  :group 'tmux-pane)

(defvar before-leave-hook nil
  "Hook to run before leaving emacs to tmux.")

(defvar after-leave-hook nil
  "Hook to run after leaving emacs to tmux.")

(defmacro -ensure-dir (&rest body)
  "Ensure BODY runs in home directory."
  `(let ((default-directory "~"))
     ,@body))

:autoload
(defun -windmove(dir flag)
  "Move focus to window according to DIR and TMUX-CMD."
  (interactive)
  (if (ignore-errors (funcall (intern (concat "windmove-" dir))))
      nil                       ; Moving within emacs
    ;; At edges, send command to tmux
    (run-hooks 'tmux-pane-before-leave-hook)
    (-ensure-dir (call-process "tmux" nil nil nil "select-pane" flag))
    (run-hooks 'tmux-pane-after-leave-hook)))

:autoload
(defun open-vertical ()
  "Open a vertical pane."
  (interactive)
  (-ensure-dir
   (call-process "tmux" nil nil nil
                 "split-window" "-h" "-p" (format "%s" vertical-percent))))

:autoload
(defun open-horizontal ()
  "Open a horizontal pane."
  (interactive)
  (-ensure-dir
   (call-process "tmux" nil nil nil
                 "split-window" "-v" "-p" (format "%s" vertical-percent))))

:autoload
(defun close ()
  "Close last pane."
  (interactive)
  (-ensure-dir
   (call-process "tmux" nil nil nil "kill-pane" "-t" "{last}")))

:autoload
(defun rerun ()
  "Rerun command in the last pane."
  (interactive)
  (-ensure-dir 
   (call-process "tmux" nil nil nil "send-keys" "-t" "{last}" "C-c")
   (call-process "tmux" nil nil nil "send-keys" "-t" "{last}" "Up" "Enter")))

:autoload
(defun toggle-vertical()
  "Toggle vertical pane."
  (interactive)
  ;; have more than one pane
  (if (< 1 (length
            (split-string
             (string-trim
              (-ensure-dir
               (shell-command-to-string "tmux list-panes")) "\n"))))
      (close)
    (open-vertical)))

:autoload
(defun toggle-horizontal()
  "Toggle horizontal pane."
  (interactive)
  ;; have more than one pane
  (if (< 1 (length
            (split-string
             (string-trim
              (-ensure-dir 
               (shell-command-to-string "tmux list-panes")) "\n"))))
      (close)
(open-horizontal)))

:autoload
(defun omni-window-last ()
  "Switch to the last window of Emacs or tmux."
  (interactive)
  (-windmove "last" "-l"))

:autoload
(defun omni-window-up ()
  "Switch to the up window of Emacs or tmux."
  (interactive)
  (-windmove "up" "-U"))

:autoload
(defun omni-window-down ()
  "Switch to the down window of Emacs or tmux."
  (interactive)
  (-windmove "down" "-D"))

:autoload
(defun omni-window-left ()
  "Switch to the left window of Emacs or tmux."
  (interactive)
  (-windmove "left" "-L"))

:autoload
(defun omni-window-right ()
  "Switch to the right window of Emacs or tmux."
  (interactive)
  (-windmove "right" "-R"))

(defvar -override-map-enable nil
  "Enabe the override keymap.")

(defvar -override-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-\\") #'omni-window-last)
    (define-key map (kbd "C-k") #'omni-window-up)
    (define-key map (kbd "C-j") #'omni-window-down)
    (define-key map (kbd "C-h") #'omni-window-left)
    (define-key map (kbd "C-l") #'omni-window-right)
    map)
  "keymap overriding existing ones.")

(defvar -override-map-alist
  `((tmux-pane--override-map-enable
     .
     ,tmux-pane--override-keymap))
  "Map alist for override.")

(defvar -override-map-alist-order 0
  "Order of map alist in `emulation-mode-map-alists'.")

(defun in-tmux-p()
  "Predicate on Emacs run in tmux."
  (string=
   "Emacs"
   (string-trim
    (-ensure-dir
     (shell-command-to-string
      "tmux display-message -p '#{pane_current_command}'")) "\n")))

:autoload
(define-minor-mode mode
  "Seamlessly navigate between tmux pane and emacs window."
  :init-value nil
  :global t
  (cond
   (mode
    (add-to-ordered-list
     'emulation-mode-map-alists
     'tmux-pane--override-map-alist
     -override-map-alist-order)
    (setq -override-map-enable t))
   ((not mode)
    (setq -override-map-enable nil))))

;; end of namespace
)

(defun windmove-last ()
  "Focus to the last Emacs window."
  (interactive)
  (let ((win (get-mru-window t t t)))
    (unless win (error "Last window not found"))
    (let ((frame (window-frame win)))
      (select-frame-set-input-focus frame)
      (select-window win))))

(provide 'tmux-pane)
;;; tmux-pane.el ends here
