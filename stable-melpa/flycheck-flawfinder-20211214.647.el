;;; flycheck-flawfinder.el --- Integrate flawfinder with flycheck

;; Copyright (c) 2016 Alex Murray

;; Author: Alex Murray <murray.alex@gmail.com>
;; Maintainer: Alex Murray <murray.alex@gmail.com>
;; URL: https://github.com/alexmurray/flycheck-flawfinder
;; Version: 0.1
;; Package-Requires: ((flycheck "0.24") (emacs "24.4"))

;; This file is not part of GNU Emacs.

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

;; This packages integrates flawfinder with flycheck to automatically check for
;; possible security weaknesses within your C/C++ code on the fly.

;;;; Setup

;; (with-eval-after-load 'flycheck
;;   (require 'flycheck-flawfinder)
;;   (flycheck-flawfinder-setup)
;;   ;; chain after cppcheck since this is the last checker in the upstream
;;   ;; configuration
;;   (flycheck-add-next-checker 'c/c++-cppcheck '(warning . flawfinder)))

;; If you do not use cppcheck then chain after clang / gcc / other C checker
;; that you use

;; (flycheck-add-next-checker 'c/c++-clang '(warning . flawfinder))

;;; Code:
(require 'flycheck)

(flycheck-def-args-var flycheck-flawfinder-args flawfinder)

(flycheck-def-option-var flycheck-flawfinder-minlevel 1 flawfinder
  "Set the minlevel to use for flawfinder."
  :type '(integer :tag "minlevel")
  :safe #'integerp)

(flycheck-define-checker flawfinder
  "A checker using flawfinder.

See `https://dwheeler.com/flawfinder/'."
  :command ("flawfinder"
            "-QD" ; just report errors without header / footer
            "-C" ; show column number
            (eval flycheck-flawfinder-args)
            (option "--minlevel" flycheck-flawfinder-minlevel nil flycheck-option-int)
            source)
  :error-patterns ((info line-start
                         (file-name) ":" line ":" column ":  [" (any "012") "]"
                         (message (one-or-more not-newline)
                                  (zero-or-more "\n"
                                                (one-or-more " ")
                                                (one-or-more not-newline))) line-end)
                   (warning line-start
                            (file-name) ":" line ":" column ":  [" (any "345") "]"
                            (message (one-or-more not-newline)
                                     (zero-or-more "\n"
                                                   (one-or-more " ")
                                                   (one-or-more not-newline))) line-end))
  :modes (c-mode c++-mode))

;;;###autoload
(defun flycheck-flawfinder-setup ()
  "Setup flycheck-flawfinder.

Add `flawfinder' to `flycheck-checkers'."
  (interactive)
  ;; append to list and chain after existing checkers
  (add-to-list 'flycheck-checkers 'flawfinder t))

(provide 'flycheck-flawfinder)

;;; flycheck-flawfinder.el ends here
