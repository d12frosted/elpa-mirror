;;; helm-make.el --- Select a Makefile target with helm

;; Copyright (C) 2014 Oleh Krehel

;; Author: Oleh Krehel <ohwoeowho@gmail.com>
;; URL: https://github.com/abo-abo/helm-make
;; Package-Version: 20141208.1607
;; Package-Commit: 6558a79d20d04465419b312da198190be6832647
;; Version: 0.1
;; Package-Requires: ((helm "1.5.3") (projectile "0.11.0"))
;; Keywords: makefile

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; A call to `helm-make' will give you a `helm' selection of this directory
;; Makefile's targets.  Selecting a target will call `compile' on it.

;;; Code:

(require 'helm)

(defgroup helm-make nil
  "Select a Makefile target with helm."
  :group 'convenience)

(defcustom helm-make-do-save nil
  "If t, save all open buffers visiting files from Makefile's directory."
  :type 'boolean
  :group 'helm-make)

(defun helm-make-action (target)
  "Make TARGET."
  (compile (format "make %s" target)))

;;;###autoload
(defun helm-make (&optional makefile)
  "Use `helm' to select a Makefile target and `compile'.
If makefile is specified use it as path to Makefile"
  (interactive)
  (let ((file (expand-file-name (if makefile makefile "Makefile")))
        targets)
    (if (file-exists-p file)
        (progn
          (when helm-make-do-save
            (let* ((regex (format "^%s" default-directory))
                   (buffers
                    (cl-remove-if-not
                     (lambda (b)
                       (let ((name (buffer-file-name b)))
                         (and name
                              (string-match regex (expand-file-name name)))))
                     (buffer-list))))
              (mapc
               (lambda (b)
                 (with-current-buffer b
                   (save-buffer)))
               buffers)))
          (with-helm-default-directory (file-name-directory file)
              (with-temp-buffer
                (insert-file-contents file)
                (goto-char (point-min))
                (let (targets)
                  (while (re-search-forward "^\\([^: \n]+\\):" nil t)
                    (let ((str (match-string 1)))
                      (unless (string-match "^\\." str)
                        (push str targets))))
                  (helm :sources
                        `((name . "Targets")
                          (candidates . ,(nreverse targets))
                          (action . helm-make-action)))
                  (message "%s" targets)))))
      (error "No Makefile in %s" default-directory))))

;;;###autoload
(defun helm-make-projectile ()
  "Call `helm-make' for `projectile-project-root'."
  (interactive)
  (require 'projectile)
  (let ((makefile (expand-file-name
                   "Makefile"
                   (projectile-project-root))))
    (helm-make
     (and (file-exists-p makefile) makefile))))

(provide 'helm-make)

;;; helm-make.el ends here
