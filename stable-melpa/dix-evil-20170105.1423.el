;;; dix-evil.el --- optional evil-integration with dix.el

;; Copyright (C) 2015-2016 Kevin Brubeck Unhammer

;; Author: Kevin Brubeck Unhammer <unhammer@fsfe.org>
;; Version: 0.1.0
;; Url: http://wiki.apertium.org/wiki/Emacs
;; Keywords: languages
;; Package-Requires: ((dix "0.3.0") (evil "1.0.7"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Extensions to dix.el for using it with evil-mode.

;; Usage:

;; (eval-after-load 'evil (eval-after-load 'dix '(require 'dix-evil)))

;;; Code:


;;;============================================================================
;;;
;;; Evil integration
;;;

(require 'evil)
(require 'dix)

(evil-declare-motion #'dix-next)
(evil-declare-motion #'dix-previous)
(evil-declare-motion #'dix-move-to-top)
(evil-declare-motion #'dix-backward-up-element)
(evil-declare-motion #'dix-goto-pardef)
(evil-declare-not-repeat #'dix-view-pardef)
(evil-declare-not-repeat #'dix-grep-all)

(advice-add #'dix-goto-pardef :before (defun dix-goto-pardef-push-jump (&rest ignore)
                                        (evil--jumps-push)))

(add-hook 'dix-mode-hook
          (defun dix-avoid-slow-paren-matching ()
            "Avoid `evil-highlight-closing-paren-at-point-states' in `dix-mode'.
That functionality is very slow in big nXML files."
            (set (make-local-variable 'evil-highlight-closing-paren-at-point-states) nil)))

(provide 'dix-evil)

;;;============================================================================

;;; dix-evil.el ends here
