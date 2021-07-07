;;; help-find-org-mode.el --- Advise help to find org source over tangled code -*- lexical-binding: t; -*-
;;
;;; Copyright (C) 2018  Free Software Foundation, Inc.
;;
;; Author: Eric Crosson <eric.s.crosson@utexas.com>
;; Version: 1.0.0
;; Package-Version: 20181204.234
;; Package-Commit: aeda7f92c086dab9d8dfcd580fe80b332887a548
;; Keywords: convenience
;; URL: https://github.com/EricCrosson/help-find-org-mode
;; Package-Requires: ((emacs "24.4"))
;;
;; This file is not a part of GNU Emacs.
;;
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.
;;
;;
;;; Commentary:

;; This package advises help functions that find code.  Each function
;; is advised to open org babel-files to the appropriate source-block
;; instead of tangled-code.

;; Opening the org file instead of the tangled code has the advantage
;; of allowing instantaneous code changes, as well as providing
;; whatever additional information is contained in the org file to the
;; user.

;;; Usage:

;; with `use-package:

;; (use-package help-find-org-mode
;;   :ensure t
;;   :pin melpa-stable
;;   :config (help-find-org-mode t))

;; - or -

;; (require 'help-find-org-mode)

;; along with one of the following:

;; (help-find-org-mode t)
;;    or invoke it interactively with
;; M-x help-find-org-mode

;; Note that for this package to work, org source code needs to bt
;; tangled with certain flags. The only non-default flag that needs to
;; be set is ':comments link'.

;; The below code defines an easy template that inserts a source block
;; with linked comments that is tangled to the default file:

;; (add-to-list 'org-structure-template-alist
;; 	     '("S"
;; 	       "#+BEGIN_SRC ? :comments link :tangle yes\n\n#+END_SRC"
;; 	       "<src lang=\"?\">\n\n</src>"))

;; expand it by inserting "<S" and hitting

;;; TODO:
;; - don't find the .el file also (kill it if it wasn't open before,
;;   bury if it was open but not visible)

;;; Code:

(require 'org)
(require 'ob-tangle)

(defgroup help-find-org nil
  "Advise help functions that find source files to find org babel
source blocks instead of tangled source."
  :group 'help)

(defun help-find-org-function (_func)
  "Advise `find-function' to find org-babel source-block defining _FUNC instead of tangled code."
  (ignore-errors
    (org-babel-tangle-jump-to-org)))

(defun help-find-org-variable (_var)
  "Advise `find-variable' to find org-babel source-block defining _VAR instead of code."
  (ignore-errors (org-babel-tangle-jump-to-org)))

(defun help-find-org-library (_library)
  "Advise `find-library' to find org-babel source-block defining _LIBRARY instead of tangled code."
  (ignore-errors (org-babel-tangle-jump-to-org)))

(defun help-find-org-function-at-point ()
  "Advise `find-function-at-point' to find org-babel source-block defining function-at-point instead of tangled code."
  (ignore-errors (org-babel-tangle-jump-to-org)))

(defun help-find-org-variable-at-point ()
  "Advise `find-variable-at-point' to find org-babel source-block defining `variable-at-point' instead of tangled code."
  (ignore-errors (org-babel-tangle-jump-to-org)))

;;;###autoload
(define-minor-mode help-find-org-mode
  "Advise help functions that find source files to find org babel
source blocks instead of tangled source."
  :init-value nil
  :lighter nil
  :global t
  :group 'help-find-org
  :require 'help-find-org-mode
  (if help-find-org-mode
      (progn
        (advice-add 'find-function :after #'help-find-org-function)
        (advice-add 'find-variable :after #'help-find-org-variable)
        (advice-add 'find-library :after #'help-find-org-library)
        (advice-add 'find-function-at-point :after #'help-find-org-function-at-point)
        (advice-add 'find-variable-at-point :after #'help-find-org-variable-at-point))
    (advice-remove 'find-function #'help-find-org-function)
    (advice-remove 'find-variable #'help-find-org-variable)
    (advice-remove 'find-library #'help-find-org-library)
    (advice-remove 'find-function-at-point #'help-find-org-function-at-point)
    (advice-remove 'find-variable-at-point #'help-find-org-variable-at-point)))


(provide 'help-find-org-mode)

;;; help-find-org-mode.el ends here
