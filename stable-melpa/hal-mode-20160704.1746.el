;;; hal-mode.el --- Major mode for editing HAL files -*- lexical-binding: t; -*-

;; Author: Alexander Rössler
;; URL: https://github.com/strahlex/hal-mode/
;; Package-Version: 20160704.1746
;; Package-Commit: cd2f66f219ee520198d4586fb6b169cef7ad3f21
;; Version: 0.1
;; Keywords: language

;; Copyright (C) 2016 Alexander Rössler
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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; To install, see https://github.com/strahlex/hal-mode/blob/master/README.md
;;
;; Known bugs:
;;
;; * None

;;; Code:

(require 'generic-x)

;;;###autoload
(define-generic-mode hal-generic-mode
  '("#")
  (apply 'append
         (mapcar #'(lambda (s) (list (upcase s) (downcase s) (capitalize s)))
                 '("loadrt" "loadusr" "addf" "setp" "sets" "start"
                   "newpin" "newcomp" "sete" "newinst" "stop"
                   "newg" "newsig" "ready" "net" "log" "newthread")))
  '(;;("\\(#<_?[A-Za-z0-9_]+>\\)" (1 font-lock-type-face))
    ("[[:space:]=]+?\\(-?[0-9]+\\(?:\\.?[0-9]+\\)?\\)" (1 font-lock-constant-face))
    ("[[:space:]]+?\\(FALSE\\|TRUE\\)" (1 font-lock-constant-face))
    ("\\(\\[[0-9a-zA-Z_]*\\][0-9a-zA-Z_]+\\)" (1 font-lock-variable-name-face))
    ("[[:space:]]+?\\(u32\\|s32\\|int\\|bit\\|float\\)" (1 font-lock-type-face)))
;;    ("\\([NnGgMmFfSsTtOo]\\)" (1 font-lock-function-name-face))
;;    ("\\([XxYyZzAaBbCcUuVvWwIiJjKkPpQqRr]\\)" (1 font-lock-string-face))
;;
;;    ("\\(#[0-9]+\\)" (1 font-lock-type-face))
;;    ("\\([0-9]+\\)" (1 font-lock-constant-face)))
  '("\\.hal\\'")
  nil
  "Generic mode for HAL files.")

;; disable electric indent
(add-hook 'hal-generic-mode-hook (lambda () (setq electric-indent-inhibit t)))

(provide 'hal-mode)
;;; hal-mode.el ends here
