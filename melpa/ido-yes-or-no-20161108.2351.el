;;; ido-yes-or-no.el --- Use Ido to answer yes-or-no questions

;; Copyright (C) 2011 Ryan C. Thompson

;; Filename: ido-yes-or-no.el
;; Author: Ryan C. Thompson
;; URL: https://github.com/DarwinAwardWinner/ido-yes-or-no
;; Package-Version: 20161108.2351
;; Package-Commit: c55383b1fce5879e87e7ca6809fc60534508e182
;; Version: 1.4
;; Created: 2011-09-24
;; Package-Requires: ((ido-completing-read+ "0"))
;; Keywords: convenience, completion, ido

;; This file is NOT part of GNU Emacs.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:

;; This package lets you use ido to answer yes-or-no questions. This
;; gives you a middle ground between `yes-or-no-p', which requires you
;; to type out the full word, and `y-or-n-p', which is too easy to
;; unintentionally answer with a single keystroke. To use this
;; package, enable `ido-yes-or-no-mode'.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'ido)

;;;###autoload
(define-minor-mode ido-yes-or-no-mode
  "Use ido for `yes-or-no-p'."
  nil
  :global t
  :group 'ido)

(defun ido-yes-or-no-p (prompt)
  "Ask user a yes-or-no question using ido."
  (let* ((yes-or-no-prompt (concat prompt " "))
         (choices '("yes" "no"))
         (answer (ido-completing-read+ yes-or-no-prompt choices nil 'require-match)))
    ;; Keep asking until they enter a valid choice (needed to work
    ;; around completion allowing exiting with an empty string)
    (while (string= answer "")
      (message "Please answer yes or no.")
      (setq answer (ido-completing-read+
                    (concat "Please answer yes or no.\n"
                            yes-or-no-prompt)
                    choices nil 'require-match)))
    (string= answer "yes")))

(defadvice yes-or-no-p (around use-ido activate)
  (if ido-yes-or-no-mode
      (setq ad-return-value (ido-yes-or-no-p prompt))
    ad-do-it))

(provide 'ido-yes-or-no)
;;; ido-yes-or-no.el ends here
