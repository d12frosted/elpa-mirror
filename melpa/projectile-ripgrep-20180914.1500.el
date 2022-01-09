;;; projectile-ripgrep.el --- Run ripgrep with Projectile

;; Copyright (C) 2016, 2017 Nicolas Lamirault <nicolas.lamirault@gmail.com>
;;
;; Author: Nicolas Lamirault <nicolas.lamirault@gmail.com>
;; Version: 0.4.0
;; Keywords : ripgrep projectile
;; Homepage: https://github.com/nlamirault/ripgrep.el
;; Package-Requires: ((ripgrep "0.3.0") (projectile "0.14.0"))

;;; Commentary:

;; Please see README.md for documentation, or read it online at
;; https://github.com/nlamirault/ripgrep.el

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301, USA.

;;; Commentary:

;; Usage :

;; M-x projectile-ripgrep

;;; Code:

(require 'projectile)
(require 'ripgrep)

;;;###autoload
(defun projectile-ripgrep (search-term &optional arg)
  "Run a Ripgrep search with `SEARCH-TERM' rooted at the current projectile project root.

With an optional prefix argument `ARG' `SEARCH-TERM' is interpreted as a
regular expression."
  (interactive
   (list
    (read-from-minibuffer (projectile-prepend-project-name (format "Ripgrep %ssearch for: "
                                                                   (if current-prefix-arg
                                                                       "regexp "
                                                                     "")))
                          (projectile-symbol-or-selection-at-point))
    current-prefix-arg))
  (let ((args (mapcar (lambda (val) (concat "--glob !" val))
                      (append (projectile-ignored-files-rel)
                              (projectile-ignored-directories-rel)))))
    (ripgrep-regexp search-term
                    (projectile-project-root)
                    (if current-prefix-arg
                        args
                      (cons "--fixed-strings" args)))))


(provide 'projectile-ripgrep)
;;; projectile-ripgrep.el ends here
