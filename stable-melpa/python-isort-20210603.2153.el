;;; python-isort.el --- Reformat python-mode buffer with isort  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Jimmy Yuen Ho Wong

;; Author: Jimmy Yuen Ho Wong <wyuenho@gmail.com>
;; Keywords: languages
;; Package-Version: 20210603.2153
;; Package-Commit: 339814df22b87eebca02137e581f65d6283fce97
;; URL: https://github.com/wyuenho/emacs-python-isort
;; Package-Requires: ((emacs "26") (reformatter "0.6"))
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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; # Usage
;;
;; (require 'python-isort)
;; (add-hook 'python-mode-hook 'python-isort-on-save-mode)

;;

;;; Code:

(require 'reformatter)

(defgroup python-isort nil
  "Python isort."
  :group 'python
  :prefix "python-isort-")

(defcustom python-isort-command "isort"
  "The name or the path to the `isort' command."
  :type 'string
  :group 'python-isort)

(defcustom python-isort-arguments '("--stdout" "--atomic" "-")
  "Arguments to `python-isort-command'."
  :type '(repeat string)
  :group 'python-isort)

;;;###autoload (autoload 'python-isort-buffer "python-isort" nil t)
;;;###autoload (autoload 'python-isort-region "python-isort" nil t)
;;;###autoload (autoload 'python-isort-on-save-mode "python-isort" nil t)
(reformatter-define python-isort
  :program python-isort-command
  :args python-isort-arguments)

(provide 'python-isort)
;;; python-isort.el ends here
