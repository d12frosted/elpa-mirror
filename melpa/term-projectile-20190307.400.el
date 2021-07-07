;;; term-projectile.el --- projectile terminal management -*- lexical-binding: t; -*-

;; Copyright (C) 2016 Ivan Malison

;; Author: Ivan Malison <IvanMalison@gmail.com>
;; Keywords: projectile tools terminals vc
;; Package-Version: 20190307.400
;; Package-Commit: eea7894350a4f31e1df0c666d3fb0bac822d34d2
;; URL: https://www.github.com/IvanMalison/term-manager
;; Version: 0.1.0
;; Package-Requires: ((emacs "24") (term-manager "0.1.0") (projectile "0.13.0"))

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

;; term-projectile defines a projectile based terminal management system.

;;; Code:

(require 'projectile)
(require 'term-manager)

(defvar term-projectile-global-directory "~")

(defun term-projectile ()
  "Make a new term-manger instance configured for projectile usage."
  (interactive)
  (let ((manager
         (make-instance 'term-manager
                        :get-symbol 'term-projectile-get-symbol-for-buffer)))
    (term-manager-enable-buffer-renaming-and-reindexing manager)
    manager))

(defun maybe-intern (value)
  (when value (intern value)))

(defun term-projectile-get-symbol-for-buffer (buffer)
  (maybe-intern (with-current-buffer buffer
            (if (derived-mode-p 'term-mode)
                ;; If we are in a term-mode buffer we should always associate
                ;; with default-directory because we don't want buffers that
                ;; were started in a project but moved to continue to be
                ;; considered as directories of that project.
                default-directory
              (let ((projectile-require-project-root nil))
                (projectile-project-root))))))

(defconst term-projectile-term-manager (term-projectile))

(defun term-projectile-switch (&rest args)
  (apply 'term-manager-display-term term-projectile-term-manager args))

(defun term-projectile-global-switch (&rest args)
  (let ((default-directory term-projectile-global-directory))
    (term-manager-display-buffer (apply 'term-manager-get-next-global-buffer
                                        term-projectile-term-manager args))))

(defun term-projectile-get-all-buffers ()
  (term-manager-get-all-buffers term-projectile-term-manager))

(defun term-projectile-select-existing ()
  (completing-read "Select a term buffer: "
                   (mapcar 'buffer-name
                           (term-projectile-get-all-buffers))))

;;;###autoload
(defun term-projectile-switch-to ()
  "Switch to an existing term-projectile buffer using `completing-read'."
  (interactive)
  (term-manager-display-buffer (term-projectile-select-existing)))

;;;###autoload
(defun term-projectile-forward ()
  "Switch forward to the next term-projectile ansi-term buffer.
Make a new one if none exists."
  (interactive)
  (term-projectile-switch :symbol (maybe-intern (projectile-project-root))))

;;;###autoload
(defun term-projectile-backward ()
  "Switch backward to the next term-projectile ansi-term buffer.
Make a new one if none exists."
  (interactive)
  (term-projectile-switch :delta -1 :symbol (maybe-intern (projectile-project-root))))

;;;###autoload
(cl-defun term-projectile-create-new (&optional (directory (projectile-project-root)))
  "Make a new `ansi-term' buffer for DIRECTORY.
If directory is nil, use the current projectile project"
  (interactive)
  (when (stringp directory) (setq directory (maybe-intern directory)))
  (term-manager-display-buffer
   (term-manager-build-term term-projectile-term-manager directory)))

;;;###autoload
(defun term-projectile-default-directory-forward ()
  "Switch forward to the next term-projectile ansi-term buffer for `defualt-directory'."
  (interactive)
  (term-projectile-switch :symbol default-directory))

;;;###autoload
(defun term-projectile-default-directory-backward ()
  "Switch backward to the next term-projectile ansi-term buffer for `defualt-directory'."
  (interactive)
  (term-projectile-switch :delta -1 :symbol default-directory))

;;;###autoload
(defun term-projectile-default-directory-create-new ()
  "Make a new `ansi-term' buffer in `default-directory'."
  (interactive)
  (let ((directory (if (stringp default-directory) (maybe-intern default-directory))))
    (term-projectile-create-new directory)))

;;;###autoload
(defun term-projectile-global-forward ()
  "Switch forward to the next term-projectile ansi-term buffer.
Make a new one if none exists."
  (interactive)
  (term-projectile-global-switch :delta 1))

;;;###autoload
(defun term-projectile-global-backward ()
  "Switch backward to the next term-projectile ansi-term buffer.
Make a new one if none exists."
  (interactive)
  (term-projectile-global-switch :delta -1))

;;;###autoload
(defun term-projectile-global-create-new ()
  "Make a new `ansi-term' buffer in `term-projectile-global-directory'."
  (interactive)
  (term-projectile-create-new term-projectile-global-directory))

(provide 'term-projectile)
;;; term-projectile.el ends here
