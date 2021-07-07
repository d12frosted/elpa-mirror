;;; projectile-trailblazer.el --- Minor mode for Rails projects using trailblazer

;; Copyright (C) 2017 Michael Dahl

;; Author:            Michael Dahl <michael.dahl84@gmail.com>
;; URL:               https://github.com/micdahl/projectile-trailblazer
;; Package-Version: 20170928.1624
;; Package-Commit: a37a4f7b7f727d98e4c74c0256e059e84263553d
;; Version:           0.2.0
;; Keywords:          rails, projectile, trailblazer, languages
;; Package-Requires:  ((emacs "24.4") (projectile "0.12.0") (inflections "1.1") (inf-ruby "2.2.6") (f "0.13.0") (rake "0.3.2"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; To start it for the rails projects:
;;
;;    (projectile-trailblazer-global-mode)
;;
;;; Code:

(require 'cl)
(require 'projectile)
(require 'projectile-rails)
(require 'inf-ruby)
(require 'inflections)
(require 'f)
(require 'rake)
(require 'json)

(defgroup projectile-trailblazer nil
  "Rails mode for trailblazer based on projectile"
  :prefix "projectile-trailblazer-"
  :group 'projectile)

(defcustom projectile-trailblazer-keymap-prefix (kbd "C-c ;")
  "Keymap prefix for option ‘projectile-trailblazer-mode’."
  :group 'projectile-trailblazer
  :type 'string)

(defvar projectile-trailblazer-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "c") 'projectile-trailblazer-find-cell)
    (define-key map (kbd "o") 'projectile-trailblazer-find-operation)
    (define-key map (kbd "t") 'projectile-trailblazer-find-contract)
    (define-key map (kbd "v") 'projectile-trailblazer-find-view)
    map)
  "Keymap after `projectile-trailblazer-keymap-prefix'.")
(fset 'projectile-trailblazer-command-map projectile-trailblazer-command-map)

(defvar projectile-trailblazer-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map projectile-trailblazer-keymap-prefix 'projectile-trailblazer-command-map)
    map)
  "Keymap for option ‘projectile-trailblazer-mode’.")

(defun projectile-trailblazer-find-cell ()
  "Find a cell."
  (interactive)
  (projectile-rails-find-resource
   "cell: "
   '(("app/concepts/" "/concepts/\\(.+/cell/.+\\)\\.rb$"))))

(defun projectile-trailblazer-find-contract ()
  "Find a contract."
  (interactive)
  (projectile-rails-find-resource
   "contract: "
   '(("app/concepts/" "/concepts/\\(.+/contract/.+\\)\\.rb$"))))

(defun projectile-trailblazer-find-operation ()
  "Find a operation."
  (interactive)
  (projectile-rails-find-resource
   "operation: "
   '(("app/concepts/" "/concepts/\\(.+/operation/.+\\)\\.rb$"))))

(defun projectile-trailblazer-find-view ()
  "Find a view."
  (interactive)
  (projectile-rails-find-resource
   "view: "
   `(("app/concepts/" ,(concat "/concepts/\\(.+/view/.+\\)" projectile-rails-views-re)))))

;;;###autoload
(define-minor-mode projectile-trailblazer-mode
  "Rails trailblazer mode based on projectile-rails"
  :init-value nil
  :lighter nil
)

;;;###autoload
(define-globalized-minor-mode projectile-trailblazer-global-mode
  projectile-trailblazer-mode
  projectile-trailblazer-on)

;;;###autoload
(defun projectile-trailblazer-on ()
  "Enable variable `projectile-trailblazer-mode' if this is a rails project."
  (when (and
         (projectile-project-p)
         (not (projectile-rails--ignore-buffer-p))
         (projectile-rails-root))
    (projectile-trailblazer-mode +1)))

(defun projectile-trailblazer-off ()
  "Disable variable `projectile-trailblazer-mode' minor mode."
  (projectile-trailblazer-mode -1))

(provide 'projectile-trailblazer)
;;; projectile-trailblazer.el ends here
