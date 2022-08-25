;;; evil-better-visual-line.el --- gj and gk visual line mode fix  -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Patrick Nuckolls

;; Author:  <nuckollsp at gmail.com>
;; Version: 0.1
;; Package-Version: 20200123.2045
;; Package-Commit: 7a65dfb17ab93857eb4c7a39d4018d9399705293
;; URL: https://github.com/yourfin/evil-better-visual-line
;; Package-Requires: ((evil "1.2.13"))
;; Keywords: evil, vim, motion

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

;; Provides `evil-better-visual-line-next-line' and
;; `evil-better-visual-line-previous-line', which act like
;; `evil-next-visual-line' and `evil-previous-visual-line'
;; unless in visual line or visual block mode, in which case
;; they act as `evil-next-line' and `evil-previous-line'.
;;
;; Also provides `evil-better-visual-line-on', which binds j and k quickly
;; and conveniently

;;; Code:

(require 'evil)
(require 'evil-macros)

;;;###autoload(autoload 'evil-better-visual-line-next-line "evil-better-visual-line")
(evil-define-motion evil-better-visual-line-next-line (count)
  "Falls through to `evil-next-visual-line' except when in visual line mode or visual block mode.

In that case uses `evil-next-line'."
  :type line
  (if (or (not evil-visual-state-minor-mode) (eq (evil-visual-type) 'inclusive))
      (evil-next-visual-line count)
    (evil-next-line count)))

;;;###autoload(autoload 'evil-better-visual-line-previous-line "evil-better-visual-line")
(evil-define-motion evil-better-visual-line-previous-line (count)
  "Falls through to `evil-previous-visual-line' except when in visual line mode or visual block mode.

In that case uses `evil-previous-line'."
  :type line
  (if (or (not evil-visual-state-minor-mode) (eq (evil-visual-type) 'inclusive))
      (evil-previous-visual-line count)
    (evil-previous-line count)))

;;;###autoload
(defun evil-better-visual-line-on ()
  "Quickly bind `evil-better-visual-line-previous-line' and `evil-better-visual-line-previous-line' to j and k."
  (interactive)
  ;; Have the extra binds here to make sure to clobber any manual sets to visual line
  ;; Also appears that the default spacemacs doesn't respect only setting operator state
  (define-key evil-operator-state-map "j" #'evil-better-visual-line-next-line)
  (define-key evil-normal-state-map "j" #'evil-better-visual-line-next-line)
  (define-key evil-visual-state-map "j" #'evil-better-visual-line-next-line)
  (define-key evil-operator-state-map "k" #'evil-better-visual-line-previous-line)
  (define-key evil-normal-state-map "k" #'evil-better-visual-line-previous-line)
  (define-key evil-visual-state-map "k" #'evil-better-visual-line-previous-line))

(provide 'evil-better-visual-line)
;;; evil-better-visual-line.el ends here
