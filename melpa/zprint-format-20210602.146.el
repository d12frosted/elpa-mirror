;;; zprint-format.el --- Reformat Clojure code using zprint -*- lexical-binding: t -*-

;; Copyright © 2021 Derek Passen

;; Author: Derek Passen <dpassen1@gmail.com>
;; Keywords: clojure, zprint, tools, languages
;; Package-Version: 20210602.146
;; Package-Commit: 6051a5709ea6182974d7239f26e04c9731e04447
;; URL: http://www.github.com/dpassen/zprint-format
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

;; Reformatter for Clojure using zprint.

;;; Code:

(require 'reformatter)

(defgroup zprint-format nil
  "Clojure reformatting using zprint."
  :group 'clojure)

(defcustom zprint-format-command
  "zprint"
  "Name of the zprint executable."
  :group 'zprint-format
  :type 'string)

(defcustom zprint-format-arguments
  '("-w")
  "Arguments to pass to zprint."
  :group 'zprint-format
  :type '(repeat string))

;;;###autoload (autoload 'zprint-format-buffer "zprint-format" nil t)
;;;###autoload (autoload 'zprint-format-region "zprint-format" nil t)
;;;###autoload (autoload 'zprint-format-on-save-mode "zprint-format" nil t)
(reformatter-define
 zprint-format
 :program zprint-format-command
 :args (append zprint-format-arguments (list input-file))
 :stdin nil
 :stdout nil
 :lighter " zprint"
 :group 'zprint-format)

(provide 'zprint-format)

;;; zprint-format.el ends here
