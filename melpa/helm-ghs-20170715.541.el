;;; helm-ghs.el --- ghs with helm interface -*- lexical-binding: t; -*-

;; Copyright (C) 2017 by iory

;; Author: iory <ab.ioryz@gmail.com>
;; Version: 0.0.2
;; Package-Version: 20170715.541
;; Package-Commit: f9d4ab80e8a33b21cd635285289ec5779bbe629f
;; URL: https://github.com/iory/emacs-helm-ghs
;; Package-Requires: ((emacs "24") (helm "2.2.0"))

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

;; helm-ghs is a wrapper of ghs.

;;; Code:

(require 'helm)
(require 'helm-mode)
(require 'helm-files)
(require 'helm-ghq)

(defgroup helm-ghs nil
  "ghs with helm interface"
  :prefix "helm-ghs-"
  :group 'helm)

(defcustom helm-ghs-command-ghs
  "ghs"
  "*A ghs command."
  :type 'string
  :group 'helm-ghs)

(defcustom helm-ghs-command-ghq-arg-list
  "get"
  "*Arguments for getting ghq list."
  :type 'string
  :group 'helm-ghs)

(defun helm-ghs--list-candidates (args)
  "*Listup ghs list. args of ARGS is query."
  (with-temp-buffer
    (unless (zerop (apply #'call-process
                          helm-ghs-command-ghs nil t nil args))
      (error "Failed: Can't get ghs list candidates"))
    (let ((repos))
      (goto-char (point-min))
      (while (not (eobp))
        (push (helm-ghq--line-string) repos)
        (forward-line 1))
      (reverse repos))))

;;;###autoload
(defun helm-ghs (query)
  "Interactively call ghs and show repos matching QUERY using helm."
  (interactive (list (read-string "Query: ")))
  (let* ((repo (helm-comp-read "ghs-list: "
                               (helm-ghs--list-candidates (split-string query " "))
                               :name "ghs list"
                               :must-match t))
         (username/repo (car (split-string repo " "))))
    (async-shell-command (concat helm-ghq-command-ghq " "
                                 helm-ghs-command-ghq-arg-list " "
                                 username/repo))))

(provide 'helm-ghs)
;;; helm-ghs.el ends here
