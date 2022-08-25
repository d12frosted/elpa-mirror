;;; counsel-pydoc.el --- run pydoc with counsel -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Hao Deng

;; Author: Hao Deng(denghao8888@gmail.com)
;; URL: https://github.com/co-dh/pydoc_utils
;; Package-Version: 20171018.2042
;; Package-Commit: 08a4a1020da3d06604156303024c8a5e31ec36e4
;; Keywords: completion, matching
;; Package-Requires: ((emacs "24.3") (ivy "0.9.1"))
;; Version: 1.0.0

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

;; Run pydoc with counsel.
;; It use python -m pydoc_utils to generate a list of modules, classes, methods, and functions.
;; To invalidate the cache after new package installed, run counsel-pydoc with universal arguments.
;;
;; Usage:
;;   with virtual env:
;;     1. pip install pydoc_utils (into a virtualenv)
;;     2. activate your virtual environment. (pyvenv-activate recommended)
;;     3. M-x counsel-pydoc
;;   without virtual env:
;;    1. sudo pip install pydoc_utils
;;    2. M-x counsel-pydoc
;;; Code:

(require 'ivy)

(defun counsel-pydoc-run(x)
  (with-output-to-temp-buffer "*pydoc*"
    (call-process "python" nil "*pydoc*" t "-m" "pydoc" x)
    ))

(setq counsel-pydoc-names nil)

;;;###autoload
(defun counsel-pydoc (arg)
  "Run pydoc with counsel.
ARG: Run with universal argument to invalidate cache."
  (interactive "P")
  (if arg
      (setq counsel-pydoc-names nil))
  (unless counsel-pydoc-names
    (setq counsel-pydoc-names (process-lines "python" "-m"  "pydoc_utils")))
  (ivy-read "Pydoc: " counsel-pydoc-names
            :action #'counsel-pydoc-run))

(provide 'counsel-pydoc)
;;; counsel-pydoc.el ends here
