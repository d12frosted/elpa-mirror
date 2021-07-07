;;; flycheck-vdm.el --- Syntax checking for vdm-mode -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Peter W. V. Tran-Jørgensen
;; Author: Peter W. V. Tran-Jørgensen <peter.w.v.jorgensen@gmail.com>
;; Maintainer: Peter W. V. Tran-Jørgensen <peter.w.v.jorgensen@gmail.com>
;; URL: https://github.com/peterwvj/vdm-mode
;; Package-Version: 20190304.839
;; Package-Commit: 89e7db6ee1a89b8c1f7ce36ce6800c32b5c4ba2d
;; Created: 29th August 2018
;; Version: 0.0.4
;; Keywords: languages
;; Package-Requires: ((emacs "24") (flycheck "32-cvs") (vdm-mode "0.0.4"))

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
;; Defines a flycheck based syntax checker that works with both
;; Overture and VDMJ

;;; Code:

(require 'vdm-mode-util)
(require 'flycheck)

(flycheck-def-option-var flycheck-vdm-tool-jar-path nil vdm
  "A path to the VDMJ or Overture jar file."
  :type 'string
  :safe #'stringp)

(flycheck-def-option-var flycheck-vdm-extra-args nil vdm
  "Extra arguments passed to the checker."
  :type '(repeat string)
  :safe #'flycheck-string-list-p)

(flycheck-define-checker vdm
    "A syntax checker for VDM."
  :command ("java"
            (option "-jar" flycheck-vdm-tool-jar-path)
            (eval (vdm-mode-util-get-dialect-arg))
            (eval flycheck-vdm-extra-args)
            source
            ;; Additional sources to type check
            (eval (vdm-mode-util-find-vdm-files t)))
  :error-patterns
  (;; Error 2013: Expected 'operations', 'state', 'functions', 'types' or 'values' in 'A.vdmsl' at line 1:1
   (error line-start "Error" (message) " in '" (file-name) "' at line " line ":" column line-end)
   ;; Error 3051: Expression does not match declared type in 'DEFAULT' (A.vdmsl) at line 4:1
   (error line-start "Error" (message) "(" (file-name) ")" " at line " line ":" column line-end)
     ;; Warning 5015: LaTeX source should start with %comment, \document, \section or \subsection in 'ex.vdmsl' at line 1:1
   (warning line-start "Warning" (message) " in '" (file-name) "' at line " line ":" column line-end)
   ;; Warning 5007: Duplicate definition: x in 'A' (lol.vdmsl) at line 11:1
   (warning line-start "Warning" (message) "(" (file-name) ")" " at line " line ":" column))
  
  :modes vdm-mode

  :predicate
  (lambda ()
    (and
     ;; The buffer must be saved
     ;; (flycheck-buffer-saved-p)
     ;; The VDM tool jar must exist
     (file-exists-p flycheck-vdm-tool-jar-path)
     ;; The buffer we're checking must be associated with a VDM file
     (vdm-mode-util-is-vdm))))

(add-to-list 'flycheck-checkers 'vdm)

(provide 'flycheck-vdm)

;;; flycheck-vdm.el ends here
