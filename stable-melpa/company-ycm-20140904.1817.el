;;; company-ycm.el --- company-ycm

;; Copyright (C) 2014  Ajay Gopinathan

;; Author: Ajay Gopinathan <ajay@gopinathan.net>
;; Keywords: abbrev
;; Package-Version: 20140904.1817
;; Package-Commit: b2cb611503cf8d256fa19fc76362d7d5d9449d01
;; Package-Requires: ((ycm "0.1"))

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

;; Company-mode backend that provides completion using the YouCompleteMe
;; (https://github.com/Valloric/YouCompleteMe) code-completion engine.

;; Usage:
;; Add the following to your init file:
;;   ;; Enable company mode:
;;   (add-hook 'after-init-hook 'global-company-mode)
;;
;;   ;; Enable company-ycm.
;;  (add-to-list 'company-backends 'company-ycm)
;;  (add-to-list 'company-begin-commands 'c-electric-colon)
;;  (add-to-list 'company-begin-commands 'c-electric-lt-gt)

;;; Code:

(eval-when-compile
  (require 'company))
(require 'ycm)

;;;###autoload
(defun company-ycm (command &optional arg &rest ignored)
  (pcase command
    (`prefix (and (memq major-mode ycm-modes)
                  (or (and (not (company-in-string-or-comment))
                           (company-ycm--grab-symbol-or-word))
                      'stop)))
    (`interactive (company-begin-backend 'company-ycm))
    (`init (when (memq major-mode ycm-modes)
             (ycm-startup)))
    (`annotation (concat " "
                         (get-text-property 0 :extra_menu_info arg)
                         " "
                         (get-text-property 0 :kind arg)))
    (`meta (get-text-property 0 :detailed_info arg))
    (`require-match `never)
    (`candidates (cons :async 'ycm-query-completions))
    (`sorted t)))


(defun company-ycm--grab-symbol-or-word ()
  "Grab symbol or word."
  (or (company-grab-symbol-cons "\\.\\|->\\|::" 2)
      (company-grab-symbol)
      (company-grab-word)))

(provide 'company-ycm)

;;; company-ycm.el ends here
