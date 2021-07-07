;;; helm-robe.el --- completing read function for robe -*- lexical-binding: t; -*-

;; Copyright (C) 2015 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL:https://github.com/syohex/emacs-helm-robe
;; Package-Version: 20151209.355
;; Package-Commit: 6e69543b4ee76c5f8f3f2510c76e6d9aed17a370
;; Version: 0.02
;; Package-Requires: ((helm "1.7.7"))

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

;; helm-robe.el provides function for setting `robe-completing-read-func'.
;;
;; You can use its function for robe completing with following configuration
;;
;; (custom-set-variables
;;  '(robe-completing-read-func 'helm-robe-completing-read))
;;

;;; Code:

(require 'helm)
(require 'helm-mode)

;;;###autoload
(defun helm-robe-completing-read (prompt choices &optional predicate require-match &rest _args)
  (let ((collection (mapcar (lambda (c) (if (listp c) (car c) c)) choices)))
    (helm-comp-read prompt collection :test predicate :must-match require-match)))

(provide 'helm-robe)

;;; helm-robe.el ends here
