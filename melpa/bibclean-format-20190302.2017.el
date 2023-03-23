;;; bibclean-format.el --- Reformat BibTeX and Scribe using bibclean -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Peter W. V. Tran-Jørgensen
;; Author: Peter W. V. Tran-Jørgensen <peter.w.v.jorgensen@gmail.com>
;; Maintainer: Peter W. V. Tran-Jørgensen <peter.w.v.jorgensen@gmail.com>
;; URL: https://github.com/peterwvj/bibclean-format
;; Package-Version: 20190302.2017
;; Package-Commit: b4003950a925d1c659bc359ab5e88e4441775d77
;; Created: 21st February 2019
;; Version: 0.0.2
;; Keywords: languages
;; Package-Requires: ((emacs "24.3") (reformatter "0.3"))

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Emacs commands for prettyprinting and syntax checking BibTeX and
;; Scribe bibliography files using bibclean.

;;; Code:

(require 'reformatter)

(defgroup bibclean-format nil
  "Prettyprinting and syntax checking for BibTeX and Scribe
bibliography data base files."
  :group 'bibtex)

(defcustom bibclean-format-command "bibclean"
  "Command used to normalize bibliography files.
Should be bibclean or the complete path to your bibclean
executable."
  :type 'file
  :group 'bibclean-format
  :safe 'stringp)

(defcustom bibclean-format-args '()
  "Arguments passed to bibclean."
  :type '(repeat string)
  :group 'bibclean-format)

;;;###autoload (autoload 'bibclean-format-buffer "bibclean-format" nil t)
;;;###autoload (autoload 'bibclean-format-region "bibclean-format" nil t)
;;;###autoload (autoload 'bibclean-format-on-save-mode "bibclean-format" nil t)
(reformatter-define bibclean-format
  :program bibclean-format-command
  :args bibclean-format-args)

(provide 'bibclean-format)

;;; bibclean-format.el ends here
