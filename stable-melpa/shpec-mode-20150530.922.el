;;; shpec-mode.el --- Minor mode for shpec specification

;; Copyright (C) 2015  Adriean Khisbe

;; Author: AdrieanKhisbe <adriean.khisbe@live.fr>
;; Version: 0.1.0
;; Package-Version: 20150530.922
;; Package-Commit: 146adc8281d0f115df39a3a3f982ac59ab61b754
;; Keywords: languages, tools
;; URL: http://github.com/shpec/shpec-mode
;; Package-Requires: ()

;; This file is NOT part of GNU Emacs.

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

;; This is a minimal, *in-building* emacs mode for shpec shell
;; specifications. So far, just a derived mode of `sh-mode'
;; with fontification of shpec keywords

;;; Code:


(defvar shpec-keywords
  `( (,(regexp-opt '( "describe" "it" "end") ; keywords
                   'words) . 'font-lock-function-name-face)
     ("assert" . 'font-lock-type-face) ; improve with arg
     (,(regexp-opt '("stub_command" "unstub_command")
                   'words) . 'font-lock-function-name-face)
     ;;matchers:
     (,(regexp-opt '("equal" "unequal" "gt" "lt" "match" "no_match"
                     "present" "blank" "file_present" "file_absent" "symlink" "test")
                   'words) . 'font-lock-builtin-face)
     )
  "Keyword for shpec specification.")

(define-derived-mode shpec-mode sh-mode "Shepc"
  "A mode for shpec specification"
  (font-lock-add-keywords nil shpec-keywords))

;; §TODO: hook

;; §TODO: make it extend sh-mode
;; hook to run test


(provide 'shpec-mode)
;;; shpec-mode.el ends here
