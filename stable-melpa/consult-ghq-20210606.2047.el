;;; consult-ghq.el ---  Ghq interface using consult -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Tomoya Otake

;; Author: Tomoya Otake <tomoya.ton@gmail.com>
;; Version: 0.0.4
;; Package-Version: 20210606.2047
;; Package-Commit: c8619d66bd8f8728e43ed15096078b89eb4d2083
;; Homepage: https://github.com/tomoya/consult-ghq
;; Keywords: convenience, usability, consult, ghq
;; Package-Requires: ((emacs "26.1") (consult "0.8") (affe "0.1"))
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This packaage provides qhq interface using Consult.
;;
;; Its main entry points are the commands `consult-ghq-find' and
;; `consult-ghq-grep`.  Default find-function is affe-find.  If you
;; want to use consult-find instead, you can change like bellow:
;;
;; (setq consult-ghq-find-function #'consult-find)

;;; Code:

(require 'consult)
(require 'affe)

(defgroup consult-ghq nil
  "Ghq interface using consult."
  :prefix "consult-ghq-"
  :group 'consult)

(defcustom consult-ghq-command
  "ghq"
  "*A ghq command."
  :type 'string
  :group 'consult-ghq)

(defcustom consult-ghq-find-function #'affe-find
  "Find function that find files after selected repo."
  :type 'function
  :group 'consult-ghq)

(defcustom consult-ghq-grep-function #'affe-grep
  "Grep function that find files after selected repo."
  :type 'function
  :group 'consult-ghq)

(defun consult-ghq--list-candidates ()
  "Return ghq list candidate."
  (with-temp-buffer
    (unless (zerop (apply #'call-process
                          consult-ghq-command nil t nil
                          '("list" "--full-path")))
      (error "Failed: Cannot get ghq list candidates"))
    (let ((paths))
      (goto-char (point-min))
      (while (not (eobp))
        (push
         (buffer-substring-no-properties
          (line-beginning-position) (line-end-position))
         paths)
        (forward-line 1))
      (nreverse paths))))

;;;###autoload
(defun consult-ghq-find ()
  "Find file from selected repo using ghq."
  (interactive)
  (let* ((repo (consult--read (consult-ghq--list-candidates) :prompt "Repo: "))
         (default-directory repo))
    (funcall consult-ghq-find-function repo)))

;;;###autoload
(defun consult-ghq-grep ()
  "Grep from selected repo using ghq."
  (interactive)
  (let* ((repo (consult--read (consult-ghq--list-candidates) :prompt "Repo: "))
         (default-directory repo))
    (funcall consult-ghq-grep-function repo)))

(provide 'consult-ghq)

;;; consult-ghq.el ends here
