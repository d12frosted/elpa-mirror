;;; cljr-ivy.el --- Access clojure refactor with ivy completion -*- lexical-binding: t; -*-

;; Author: Wanderson Ferreira <iagwanderson@gmail.com>
;; URL: https://github.com/wandersoncferreira/cljr-ivy
;; Package-Version: 20200602.1607
;; Package-Commit: 18e6e3526e872010a643c91aa71ff1d429431b83
;; Package-Requires: ((clj-refactor "2.5.0") (ivy "0.13.0") (emacs "24.3") (cl-lib "0.6.1"))
;; Version: 0.1
;; Keywords: convenience, matching

;; Copyright (C) 2020 Wanderson Ferreira <wanderson.ferreira@protonmail.com>

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

;; Ivy version of `cljr-helm` to access clojure-refactor from ivy completing framework.

;;; Code:

(require 'ivy)
(require 'clj-refactor)

(defun cljr-ivy-candidates (&rest _u)
  "Generate suggestions to candidate."
  (mapcar (lambda (c)
	    (concat (car c) ": " (cl-second (cdr c))))
	  cljr--all-helpers))

(defun cljr-ivy-invoke ()
  "Ivy function to read and display candidates to the user."
  (ivy-read "Clojure Refactor: " #'cljr-ivy-candidates
	    :action (lambda (entry)
		      (string-match "^\\(.+?\\): " entry)
		      (call-interactively
		       (cadr (assoc (match-string 1 entry) cljr--all-helpers))))
	    :caller #'cljr-ivy))

;;;###autoload
(defun cljr-ivy ()
  "Access clojure-refactor tools from ivy."
  (interactive)
  (cljr-ivy-invoke))

(provide 'cljr-ivy)
;;; cljr-ivy.el ends here
