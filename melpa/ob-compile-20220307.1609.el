;;; ob-compile.el --- Run compile by org-babel -*- lexical-binding: t -*-

;; Copyright (C) 2022 Giap Tran <txgvnn@gmail.com>

;; Author: Giap Tran <txgvnn@gmail.com>
;; Homepage: https://github.com/TxGVNN/giaelpa/tree/recipes/ob-compile
;; Version: 0.1.0
;; Package-Version: 20220307.1609
;; Package-Commit: 4217ae0cfa71793ee1b42bc8e07283f5e269e7cb
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
;; #+begin_src compile :output (format "compile-%s" (format-time-string "%y%m%d-%H%M%S"))
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

;;;###autoload
(defun org-babel-execute:compile (body params)
  "Orgmode Babel COMPILE evaluate function for `BODY' with `PARAMS'."
  (let* ((file (or (cdr (assoc ':output params)) "")))
    (let ((compilation-buffer-name-function
           (lambda (_)
             (format "*ob-compile:%s*" file))))
      (compile (format "true '%s'; %s" params body) t))
    file))

(defvar org-babel-default-header-args:compile '())

(add-to-list 'org-babel-tangle-lang-exts '("compile" . "compile"))
(add-to-list 'org-babel-default-header-args:compile
             '(:results . "output"))

(defun ob-compile-save-file (buffer _)
  "Save ob-compile BUFFER to file."
  (if (equal (substring (buffer-name buffer) 0 12) "*ob-compile:")
      (let* ((bufname (buffer-name buffer))
             (filename (string-trim (replace-regexp-in-string
                                     "*ob-compile:\\(.+\\)\\*" "\\1" bufname))))
        (unless (equal filename "*ob-compile:*")
          (save-excursion
            (write-file (format "%s" filename) t)
            (rename-buffer bufname))))))

(provide 'ob-compile)

;;; ob-compile.el ends here
