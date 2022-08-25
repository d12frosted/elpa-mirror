;;; poly-wdl.el --- Polymode for WDL -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2019 Jean Monlong
;;
;; Author: Jean Monlong <jean.monlong@gmail.com>
;; Version: 0.1
;; Package-Version: 20190712.529
;; Package-Commit: fe2ee0c441795c35a8c127fa1f7006a5f251f564
;; Package-Requires: ((emacs "25") (polymode "0.2") (wdl-mode "20170709"))
;; Keywords: languages
;; URL: https://github.com/jmonlong/poly-wdl
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;; Commentary:

;; Edit WDL files with wdl-mode and sh-mode within the command chunks.

;;; Code:

(require 'polymode)
(require 'wdl-mode)

(defcustom poly-wdl-pm-host-wdl
  (pm-host-chunkmode :name "wdl"
                     :mode 'wdl-mode)
  "WDL host chunkmode."
  :group 'poly-hostmodes
  :type 'object)

(defcustom poly-wdl-pm-inner-command-short
  (pm-inner-chunkmode :name "command"
                      :head-matcher "^[ \t]*command *{ *\n"
                      :tail-matcher "^[ \t]*} *\n"
                      :head-mode 'host
		      :tail-mode 'host
		      :mode 'sh-mode)
  "Short command chunkmode."
  :group 'innermodes
  :type 'object)

(defcustom poly-wdl-pm-inner-command-long
  (pm-inner-chunkmode :name "command"
                      :head-matcher "^[ \t]*command *<<< *\n"
                      :tail-matcher "^[ \t]*>>> *\n"
                      :head-mode 'host
		      :tail-mode 'host
		      :mode 'sh-mode)
  "Long command chunkmode."
  :group 'innermodes
  :type 'object)

;;;###autoload (autoload 'poly-wdl-mode "poly-wdl")
(define-polymode poly-wdl-mode
  :hostmode 'poly-wdl-pm-host-wdl
  :innermodes '(poly-wdl-pm-inner-command-short
		poly-wdl-pm-inner-command-long))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.wdl\\'" . poly-wdl-mode))

(provide 'poly-wdl)

;;; poly-wdl.el ends here
