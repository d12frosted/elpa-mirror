;;; cljstyle-format.el --- Reformat Clojure code using cljstyle -*- lexical-binding: t -*-

;; Copyright © 2022 Derek Passen

;; Author: Derek Passen <dpassen1@gmail.com>
;; Keywords: clojure, cljstyle, tools, languages
;; Package-Version: 20220706.309
;; Package-Commit: 31a43dfbeea12bbd4639dcec4fbb043cc0ff86d3
;; URL: http://www.github.com/dpassen/cljstyle-format
;; Package-Requires: ((emacs "24") (reformatter "0.3"))
;; Version: 1.0.0

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

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Reformatter for Clojure using cljstyle.

;;; Code:

(require 'reformatter)

(defgroup cljstyle-format nil
  "Clojure reformatting using cljstyle."
  :group 'clojure)

(defcustom cljstyle-format-command
  "cljstyle"
  "Name of the cljstyle executable."
  :group 'cljstyle-format
  :type 'string)

(defcustom cljstyle-format-arguments
  '("pipe")
  "Arguments to pass to cljstyle."
  :group 'cljstyle-format
  :type '(repeat string))

;;;###autoload (autoload 'cljstyle-format-buffer "cljstyle-format" nil t)
;;;###autoload (autoload 'cljstyle-format-region "cljstyle-format" nil t)
;;;###autoload (autoload 'cljstyle-format-on-save-mode "cljstyle-format" nil t)
(reformatter-define
 cljstyle-format
 :program cljstyle-format-command
 :args cljstyle-format-arguments
 :lighter " cljstyle"
 :group 'cljstyle-format)

(provide 'cljstyle-format)

;;; cljstyle-format.el ends here
