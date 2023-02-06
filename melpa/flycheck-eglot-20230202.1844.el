;;; flycheck-eglot.el --- Flycheck support for eglot -*- lexical-binding: t -*-

;; Copyright (C) 2023 Sergey Firsov

;; Author: Sergey Firsov <intramurz@gmail.com>
;; Maintainer: Sergey Firsov <intramurz@gmail.com>
;; Version: 0.1
;; Package-Version: 20230202.1844
;; Package-Commit: 31905ad676d67fb2967a3b6d907312380696615f
;; Package-Requires: ((emacs "28.1") (eglot "1.9") (flycheck "32"))
;; URL: https://github.com/intramurz/flycheck-eglot
;; Keywords: convenience language tools


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; This software has its origin in a piece of Doom Emacs code
;; which was distributed under the following terms:

;;  The MIT License (MIT)

;;  Copyright (c) 2014-2022 Henrik Lissner.

;;  Permission is hereby granted, free of charge, to any person obtaining
;;  a copy of this software and associated documentation files (the "Software"),
;;  to deal in the Software without restriction, including
;;  without limitation the rights to use, copy, modify, merge, publish,
;;  distribute, sublicense, and/or sell copies of the Software, and to
;;  permit persons to whom the Software is furnished to do so, subject to
;;  the following conditions:

;;  The above copyright notice and this permission notice shall be
;;  included in all copies or substantial portions of the Software.

;;; Commentary:

;; A simple "glue" minor mode that allows Flycheck and Eglot to work together.
;;
;; You just need to enable `global-flycheck-eglot-mode'.
;; Put the following in your init file:
;;
;;      (require 'flycheck-eglot)
;;      (global-flycheck-eglot-mode 1)
;;
;; By default, the Flycheck-Eglot considers the Eglot to be the only provider
;; of syntax checks.  Other Flycheck checkers are ignored.
;; There is a variable `flycheck-eglot-exclusive' that controls this.
;; You can override it system wide or for some major modes.

;;; Code:

(require 'cl-lib)
(require 'flycheck)
(require 'flymake)
(require 'eglot)


(defgroup flycheck-eglot nil
  "Flycheck-Eglot compatibility customizations."
  :prefix "flycheck-eglot-"
  :group 'flycheck)


(defcustom flycheck-eglot-exclusive t
  "Is the flycheck-eglot checker exclusive or in a chain of others."
  :type 'boolean
  :local t
  :group 'flycheck-eglot)


(defvar-local flycheck-eglot--current-errors nil)


(defun flycheck-eglot--start (checker callback)
  "Start function for generic checker definition.
CHECKER is the current checker (assuming eglot-check).
CALLBACK is a callback function provided by Flycheck."
  (when (eq checker 'eglot-check)
    (funcall callback
             'finished
             flycheck-eglot--current-errors)))


(defun flycheck-eglot--report-eglot-diagnostics (diags &rest _)
  "Report function for the `eglot-flymake-backend'.
DIAGS is the Eglot diagnostics list in Flymake format."
  (cl-flet
      ((diag-to-err (diag)
                    ;; Translate flymake to flycheck
                    (with-current-buffer (flymake-diagnostic-buffer diag)
                      (flycheck-error-new-at-pos
                       (flymake-diagnostic-beg diag) ; POS
                       (pcase (flymake-diagnostic-type diag) ; LEVEL
                         ('eglot-note 'info)
                         ('eglot-warning 'warning)
                         ('eglot-error 'error)
                         (_ (error "Unknown diagnostic type: %S" diag)))
                       (flymake-diagnostic-text diag)  ; MESSAGE
                       :end-pos (flymake-diagnostic-end diag)
                       :checker 'eglot-check
                       :buffer (current-buffer)
                       :filename (buffer-file-name)))))

    (setq flycheck-eglot--current-errors
          (mapcar #'diag-to-err diags))
    (flycheck-buffer-automatically '(idle-change new-line))))


(defun flycheck-eglot--eglot-available-p ()
  "Is Eglot available."
  (and (fboundp 'eglot-managed-p)
       (eglot-managed-p)))


(flycheck-define-generic-checker 'eglot-check
  "Reports Eglot-provided diagnostics with Flycheck."
  :start #'flycheck-eglot--start
  :predicate #'flycheck-eglot--eglot-available-p
  :modes '(prog-mode text-mode))


(defun flycheck-eglot--setup ()
  "Setup flycheck-eglot."
  (when (flycheck-eglot--eglot-available-p)
    (add-to-list 'flycheck-checkers 'eglot-check)
    (setq flycheck-disabled-checkers
          (remove 'eglot-check
                  flycheck-disabled-checkers))
    (let ((current-checker (flycheck-get-checker-for-buffer)))
      (flycheck-add-mode 'eglot-check major-mode)
      (if (or flycheck-eglot-exclusive
              (null current-checker))
          (setq flycheck-checker 'eglot-check)
        (unless (eq current-checker 'eglot-check)
          (flycheck-add-next-checker 'eglot-check current-checker))))
    (eglot-flymake-backend #'flycheck-eglot--report-eglot-diagnostics)
    (flymake-mode -1)
    (flycheck-mode 1)))


(defun flycheck-eglot--teardown ()
  "Teardown flycheck-eglot."
  (when (flycheck-eglot--eglot-available-p)
    (eglot-flymake-backend #'ignore)
    (setq flycheck-checker nil)
    (setq flycheck-disabled-checkers
          (cl-adjoin 'eglot-check
                     flycheck-disabled-checkers))
    (setq flycheck-eglot--current-errors nil)
    (flycheck-buffer-deferred)))


;;;###autoload
(define-minor-mode flycheck-eglot-mode
  "Minor mode for using Flycheck with Eglot."
  :init-value nil
  :lighter nil
  (if flycheck-eglot-mode
      (flycheck-eglot--setup)
    (flycheck-eglot--teardown)))


;;;###autoload
(define-globalized-minor-mode global-flycheck-eglot-mode
  flycheck-eglot-mode
  (lambda ()
    (when (flycheck-eglot--eglot-available-p)
      (flycheck-eglot-mode 1)))
  :group 'flycheck-eglot
  (if global-flycheck-eglot-mode
      (add-hook 'eglot-managed-mode-hook #'flycheck-eglot-mode)
    (remove-hook 'eglot-managed-mode-hook #'flycheck-eglot-mode)
    (setq flycheck-checkers
          (remove 'eglot-check
                  flycheck-checkers))))


(provide 'flycheck-eglot)
;;; flycheck-eglot.el ends here
