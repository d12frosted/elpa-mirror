;;; ob-compile.el --- Run compile by org-babel -*- lexical-binding: t -*-

;; Copyright (C) 2022 Giap Tran <txgvnn@gmail.com>

;; Author: Giap Tran <txgvnn@gmail.com>
;; Homepage: https://github.com/TxGVNN/ob-compile
;; Version: 0.2
;; Package-Version: 20220830.315
;; Package-Commit: 9a16b3dd0f467c091e91944b90a2ca3d646d6617
;; Keywords:  literate programming, reproducible, processes
;; Package-Requires: ((emacs "24.4"))
;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; Run compile in org-mode.
;; Example:
;; #+begin_src compile :name uname :output (format "compile-%s" (format-time-string "%y%m%d-%H%M%S"))
;; uname -a
;; #+end_src
;;
;; To enable saving the output, you have to config:
;; (add-hook 'compilation-finish-functions #'ob-compile-save-file)

;;; Code:
(require 'org)
(require 'ob)

(defgroup ob-compile nil
  "Org-mode blocks for COMPILE."
  :group 'org)


(defcustom ob-compile:inf-compile-buffer "*ob-compile*"
  "Default COMPILE inferior buffer."
  :group 'ob-compile
  :type 'string)

(defvar-local ob-compile-output nil)

;;;###autoload
(defun org-babel-execute:compile (body params)
  "Orgmode Babel COMPILE evaluate function for `BODY' with `PARAMS'."
  (let* ((file (or (cdr (assoc ':output params)) nil))
         (name (or (cdr (assoc ':name params)) "")))
    (let ((compilation-buffer-name-function
           (lambda (_)
             (format "*ob-compile:%s*" name))))
      (compile (format "true '%s';\n%s" params body) t)
      (when file
        (with-current-buffer (format "*ob-compile:%s*" name)
          (setq-local ob-compile-output file))))
    ""))

(defvar org-babel-default-header-args:compile '())

(add-to-list 'org-babel-tangle-lang-exts '("compile" . "compile"))
(add-to-list 'org-babel-default-header-args:compile
             '(:results . "output"))

(defun ob-compile-save-file (buffer _)
  "Save ob-compile BUFFER to file."
  (let ((bufname (buffer-name buffer)))
    (with-current-buffer buffer
      (when ob-compile-output
        (save-excursion
          (write-file (format "%s" ob-compile-output) t)
          (rename-buffer bufname))))))

(provide 'ob-compile)

;;; ob-compile.el ends here
