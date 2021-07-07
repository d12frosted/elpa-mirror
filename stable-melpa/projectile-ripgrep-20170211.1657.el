;;; projectile-ripgrep.el --- Run ripgrep with Projectile

;; Copyright (C) 2016, 2017 Nicolas Lamirault <nicolas.lamirault@gmail.com>
;;
;; Author: Nicolas Lamirault <nicolas.lamirault@gmail.com>
;; Version: 0.4.0
;; Package-Version: 20170211.1657
;; Package-Commit: 73595f1364f2117db49e1e4a49290bd6d430e345
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
(defun projectile-ripgrep (regexp)
  "Run a Ripgrep search with `REGEXP' rooted at the current projectile project root."
  (interactive
   (list
    (read-from-minibuffer "Ripgrep search for: " (thing-at-point 'symbol))))
  (ripgrep-regexp regexp
                  (projectile-project-root)
                  (mapcar (lambda (val) (concat "--glob !" val))
                          (append projectile-globally-ignored-files
                                  projectile-globally-ignored-directories))))


(provide 'projectile-ripgrep)
;;; projectile-ripgrep.el ends here
