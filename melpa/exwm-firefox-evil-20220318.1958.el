;;; exwm-firefox-evil.el --- evil-mode implementation of exwm-firefox-core -*- lexical-binding: t -*-

;; Author: Sebastian Wålinder <s.walinder@gmail.com>
;; URL: https://github.com/walseb/exwm-firefox-evil
;; Package-Version: 20220318.1958
;; Package-Commit: a377326e2e4ac386a0abb3fc9b1b356a0d955b61
;; Version: 1.0
;; Package-Requires: ((emacs "24.4") (exwm "0.16") (evil "1.0.0") (exwm-firefox-core "1.0"))
;; Keywords: extensions

;; exwm-firefox-evil.el is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; exwm-firefox-evil.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package implements exwm-firefox-core to allow for modal editing in
;; firefox like in evil-mode and vi
;;
;; To get link-hints you have to define a new key like below and download a
;; link-hint addon to firefox.

;;; Code:

(require 'evil)
(require 'evil-core)
(require 'exwm-firefox-core)

(defvar exwm-firefox-evil-firefox-class-name '("Firefox" "firefox" "Nightly" "Iceweasel" "Icecat")
  "The class name used for detecting if a firefox buffer is selected.")

(defvar exwm-firefox-evil-insert-on-new-tab t
  "If non-nil, auto enter insert mode after opening new tab.")

;;; State transitions
(defun exwm-firefox-evil-normal ()
  "Pass every key directly to Emacs."
  (interactive)
  (setq-local exwm-input-line-mode-passthrough t)
  (evil-normal-state))

(defun exwm-firefox-evil-insert ()
  "Pass every key to firefox."
  (interactive)
  (setq-local exwm-input-line-mode-passthrough nil)
  (evil-insert-state))

(defun exwm-firefox-evil-exit-visual ()
  "Exit visual state properly."
  (interactive)
  ;; Unmark any selection
  (exwm-firefox-core-left)
  (exwm-firefox-core-right)
  (exwm-firefox-evil-normal))

(defun exwm-firefox-evil-visual-change ()
  "Change text in visual mode."
  (interactive)
  (exwm-firefox-core-cut)
  (exwm-firefox-evil-insert))

;;; Keys
(defvar exwm-firefox-evil-mode-map (make-sparse-keymap))

    ;;;; Transitions
;; Bind normal
(define-key exwm-firefox-evil-mode-map [remap evil-exit-visual-state] 'exwm-firefox-evil-exit-visual)
(define-key exwm-firefox-evil-mode-map [remap evil-normal-state] 'exwm-firefox-evil-normal)
(define-key exwm-firefox-evil-mode-map [remap evil-force-normal-state] 'exwm-firefox-evil-normal)
;; Bind insert
(define-key exwm-firefox-evil-mode-map [remap evil-insert-state] 'exwm-firefox-evil-insert)
(define-key exwm-firefox-evil-mode-map [remap evil-insert] 'exwm-firefox-evil-insert)
(define-key exwm-firefox-evil-mode-map [remap evil-substitute] 'exwm-firefox-evil-insert)
(define-key exwm-firefox-evil-mode-map [remap evil-append] 'exwm-firefox-evil-insert)

    ;;;; Normal
;; Basic movements
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "k") 'exwm-firefox-core-up)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "j") 'exwm-firefox-core-down)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "h") 'exwm-firefox-core-left)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "l") 'exwm-firefox-core-right)
;; Move by page
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "C-f") 'exwm-firefox-core-page-down)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "C-b") 'exwm-firefox-core-page-up)
;; Send enter to firefox
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "<return>") '(lambda () (interactive) (exwm-input--fake-key 'return)))
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "RET") '(lambda () (interactive) (exwm-input--fake-key 'return)))
;; Move by half page
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "C-u") 'exwm-firefox-core-half-page-up)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "C-d") 'exwm-firefox-core-half-page-down)
;; Move to top/bot
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "g g") 'exwm-firefox-core-top)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "G") 'exwm-firefox-core-bottom)
;; Tab movement
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "J") 'exwm-firefox-core-tab-next)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "K") 'exwm-firefox-core-tab-previous)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "x") 'exwm-firefox-core-tab-close)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "t") 'exwm-firefox-core-tab-new)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "0") 'exwm-firefox-core-tab-first)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "$") 'exwm-firefox-core-tab-last)
;; Reload page
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "r") 'exwm-firefox-core-reload)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "R") 'exwm-firefox-core-reload-override-cache)
;; History
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "L") 'exwm-firefox-core-history-forward)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "H") 'exwm-firefox-core-history-back)
;; Search
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "o") 'exwm-firefox-core-focus-search-bar)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "O") 'exwm-firefox-core-focus-search-bar)
;; Find
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "/") 'exwm-firefox-core-quick-find)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "n") 'exwm-firefox-core-find-next)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "N") 'exwm-firefox-core-find-previous)
;; Editing
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "w") 'exwm-firefox-core-forward-word)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "e") 'exwm-firefox-core-forward-word)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "b") 'exwm-firefox-core-back-word)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "p") 'exwm-firefox-core-paste)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "y") 'exwm-firefox-core-copy)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "u") 'exwm-firefox-core-undo)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "C-r") 'exwm-firefox-core-redo)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "d") 'exwm-firefox-core-cut)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "D") 'exwm-firefox-core-cut)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "c") 'exwm-firefox-core-cut)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "C") 'exwm-firefox-core-cut)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "<deletechar>") 'exwm-firefox-core-delete)
;; Select all and stop user from entering visual and insert state
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "C-v") 'exwm-firefox-core-select-all)
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "V") 'exwm-firefox-core-select-all)
;; Pass through esc when in normal mode
(evil-define-key 'normal exwm-firefox-evil-mode-map (kbd "<escape>") 'exwm-firefox-core-cancel)

    ;;;; Visual
;; Basic movement
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "k") 'exwm-firefox-core-up-select)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "j") 'exwm-firefox-core-down-select)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "h") 'exwm-firefox-core-left-select)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "l") 'exwm-firefox-core-right-select)
;; Scroll page
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "C-u") 'exwm-firefox-core-half-page-up-select)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "C-d") 'exwm-firefox-core-half-page-down-select)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "C-f") 'exwm-firefox-core-page-down-select)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "C-b") 'exwm-firefox-core-page-up-select)
;; Editing
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "y") 'exwm-firefox-core-copy)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "Y") 'exwm-firefox-core-copy)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "d") 'exwm-firefox-core-cut)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "D") 'exwm-firefox-core-cut)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "c") 'exwm-firefox-evil-visual-change)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "C") 'exwm-firefox-evil-visual-change)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "r") 'exwm-firefox-core-cut)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "R") 'exwm-firefox-core-cut)
;; Send enter to firefox
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "<return>") '(lambda () (interactive) (exwm-input--fake-key 'return)))
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "RET") '(lambda () (interactive) (exwm-input--fake-key 'return)))
;; Move by word
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "w") 'exwm-firefox-core-forward-word-select)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "e") 'exwm-firefox-core-forward-word-select)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "b") 'exwm-firefox-core-back-word-select)
;; Move to top/bot
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "g g") 'exwm-firefox-core-top-select)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "G") 'exwm-firefox-core-bottom-select)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "0") 'exwm-firefox-core-top-select)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "$") 'exwm-firefox-core-bottom-select)
;; Select all
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "C-v") 'exwm-firefox-core-select-all)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "V") 'exwm-firefox-core-select-all)
;; Find
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "/") 'exwm-firefox-core-quick-find)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "n") 'exwm-firefox-core-find-next)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "N") 'exwm-firefox-core-find-previous)
;; Prevent user from exiting visual state without exwm-firefox-evil noticing
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "u") 'exwm-firefox-evil-normal)
(evil-define-key 'visual exwm-firefox-evil-mode-map (kbd "U") 'exwm-firefox-evil-normal)

;;; Mode
;;;###autoload
(define-minor-mode exwm-firefox-evil-mode nil nil nil exwm-firefox-evil-mode-map
  (if exwm-firefox-evil-mode
      (progn
	(exwm-firefox-evil-normal)
	;; Auto enter insert mode on some actions
	(if exwm-firefox-evil-insert-on-new-tab
	    (advice-add #'exwm-firefox-core-tab-new :after #'exwm-firefox-evil-insert))

	(advice-add #'exwm-firefox-core-focus-search-bar :after #'exwm-firefox-evil-insert)
	(advice-add #'exwm-firefox-core-find :after #'exwm-firefox-evil-insert)
	(advice-add #'exwm-firefox-core-quick-find :after #'exwm-firefox-evil-insert))

    ;; Clean up advice
    (advice-remove #'exwm-firefox-core-tab-new #'exwm-firefox-evil-insert)
    (advice-remove #'exwm-firefox-core-focus-search-bar #'exwm-firefox-evil-insert)
    (advice-remove #'exwm-firefox-core-find #'exwm-firefox-evil-insert)
    (advice-remove #'exwm-firefox-core-quick-find #'exwm-firefox-evil-insert)))

;;;###autoload
(defun exwm-firefox-evil-activate-if-firefox ()
  "Activates exwm-firefox mode when buffer is firefox.
Firefox variant can be assigned in 'exwm-firefox-evil-firefox-name`"
  (interactive)
  (if (member exwm-class-name exwm-firefox-evil-firefox-class-name)
      (exwm-firefox-evil-mode 1)))

(provide 'exwm-firefox-evil)

;;; exwm-firefox-evil.el ends here
