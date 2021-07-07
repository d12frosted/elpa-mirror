;;; evil-anzu.el --- anzu for evil-mode

;; Copyright (C) 2017 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;;         Fredrik Bergroth <fbergroth@gmail.com>
;; URL: https://github.com/syohex/emacs-evil-anzu
;; Package-Version: 20200514.1902
;; Package-Commit: d3f6ed4773b48767bd5f4708c7f083336a8a8a86
;; Version: 0.02
;; Package-Requires: ((evil "1.0.0") (anzu "0.46"))

;; This program is free software; you can redistribute it and/or modify
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

;;; Code:

(require 'evil)
(require 'anzu)

(defun evil-anzu-start-search (string forward &optional regexp-p start)
  (when anzu-mode
    (anzu--cons-mode-line-search)
    (let ((isearch-regexp regexp-p))
      (anzu--update string))))

(defun evil-anzu-search-next (&optional pattern direction nowrap)
  "Make anzu work with the 'evil-search search module.
If PATTERN is not specified the current global pattern `evil-ex-search-pattern' is used."
  (when anzu-mode
    (anzu--cons-mode-line-search)
    (let* ((isearch-regexp t) ; all evil-ex searches are regexp searches
           (current-pattern (or pattern evil-ex-search-pattern))
           (regexp (evil-ex-pattern-regex current-pattern)))
      (save-match-data       ; don't let anzu's searching mess up evil
        (anzu--update regexp)))))

(defun evil-anzu-prevent-flicker (&optional force)
  ;; Prevent flickering, only run if timer is not active
  (when anzu-mode
    (unless (memq evil-flash-timer timer-list)
      (anzu--reset-mode-line))))

(defun evil-anzu-reset (name)
  (when (and anzu-mode
             (eq name 'evil-ex-search))
    (anzu--reset-mode-line)))

(advice-add 'evil-search       :after #'evil-anzu-start-search)
(advice-add 'evil-ex-find-next :after #'evil-anzu-search-next)
(advice-add 'evil-flash-hook   :after #'evil-anzu-prevent-flicker)
(advice-add 'evil-ex-delete-hl :after #'evil-anzu-reset)

(defun evil-anzu-unload-function ()
  "unload evil anzu"
  (advice-remove 'evil-search       #'evil-anzu-start-search)
  (advice-remove 'evil-ex-find-next #'evil-anzu-search-next)
  (advice-remove 'evil-flash-hook   #'evil-anzu-prevent-flicker)
  (advice-remove 'evil-ex-delete-hl #'evil-anzu-reset)
  nil)

(provide 'evil-anzu)

;;; evil-anzu.el ends here
