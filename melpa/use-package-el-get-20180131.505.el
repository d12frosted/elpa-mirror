;;; use-package-el-get.el --- el-get support for use package

;; Copyright (C) 2018 Edward Knyshov

;; Author: Edward Knyshov <edvorg@gmail.com>
;; Created: 15 Jan 2018
;; Version: 0.1
;; Package-Version: 20180131.505
;; Package-Commit: cba87c4e9a3a66b7c10962e3aefdf11c83d737bc
;; Package-Requires: ((use-package "1.0"))
;; Keywords: dotemacs startup speed config package tools
;; X-URL: https://github.com/edvorg/use-package-el-get
;; Homepage: https://github.com/edvorg/use-package-el-get
;; URL: https://github.com/edvorg/use-package-el-get

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU Lesser General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU Lesser General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; (require 'use-package-el-get)
;; (use-package-el-get-setup)

;; (use-package req-package
;;   :el-get t)

;; ;; or

;; (use-package req-package
;;   :el-get req-package)

;;; Code:

(require 'use-package)
(require 'el-get)

(defun use-package-normalize/:el-get (name-symbol keyword args)
  "use-package :el-get keyword handler."
  (use-package-only-one (symbol-name keyword) args
    (lambda (label arg)
      (cond
       ((booleanp arg) (when arg
                         name-symbol))
       ((symbolp arg) arg)
       (t
        (use-package-error
         ":el-get wants a package name or boolean value"))))))

(defun use-package-handler/:el-get (name-symbol keyword archive-name rest state)
  "use-package :el-get keyword handler."
  (let ((body (use-package-process-keywords name-symbol rest state)))
    ;; This happens at macro expansion time, not when the expanded code is
    ;; compiled or evaluated.
    (if (null archive-name)
        body
      (el-get-install archive-name)
      body)))

(defun use-package-el-get-setup ()
  "Set up use-package keyword :el-get ."
  (add-to-list 'use-package-keywords :el-get))

(provide 'use-package-el-get)

;;; use-package-el-get.el ends here
