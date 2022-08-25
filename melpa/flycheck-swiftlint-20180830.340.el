;;; flycheck-swiftlint.el --- Flycheck extension for Swiftlint. -*- lexical-binding: t -*-

;; Copyright (C) 2017 James Nguyen

;; Authors: James Nguyen <james@jojojames.com>
;; Maintainer: James Nguyen <james@jojojames.com>
;; URL: https://github.com/jojojames/flycheck-swiftlint
;; Package-Version: 20180830.340
;; Package-Commit: 65101873c4c9f8e7eac9471188b161eeddda1555
;; Version: 1.0
;; Package-Requires: ((emacs "25.1") (flycheck "0.25"))
;; Keywords: languages swiftlint swift emacs

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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
;; Flycheck extension for Swiftlint.
;;
;; (with-eval-after-load 'flycheck
;;   (flycheck-swiftlint-setup))

;;; Code:

(require 'flycheck)
(require 'cl-lib)

;; Compatibility
(eval-and-compile
  (with-no-warnings
    (if (version< emacs-version "26")
        (progn
          (defalias 'flycheck-swiftlint-if-let* #'if-let)
          (defalias 'flycheck-swiftlint-when-let* #'when-let)
          (function-put #'flycheck-swiftlint-if-let* 'lisp-indent-function 2)
          (function-put #'flycheck-swiftlint-when-let* 'lisp-indent-function 1))
      (defalias 'flycheck-swiftlint-if-let* #'if-let*)
      (defalias 'flycheck-swiftlint-when-let* #'when-let*))))

;; Customization
(defcustom flycheck-swiftlint-should-run-swiftlint-function
  'flycheck-swiftlint-should-run-p
  "Function used to determine if swiftlint should run."
  :type 'function
  :group 'flycheck)

;;; Flycheck

(flycheck-def-executable-var swiftlint "swiftlint")

(flycheck-define-checker swiftlint
  "Flycheck plugin for for Swiftlint."
  :command ("swiftlint")
  :error-patterns ((error line-start (file-name) ":" line ":" column ": "
                          "error: " (message) line-end)
                   (warning line-start (file-name) ":" line ":" column ": "
                            "warning: " (message) line-end))
  :modes (swift-mode)
  :predicate
  (lambda ()
    (funcall flycheck-swiftlint-should-run-swiftlint-function))
  :working-directory
  (lambda (_)
    (flycheck-swiftlint--find-swiftlint-directory)))

;;;###autoload
(defun flycheck-swiftlint-setup ()
  "Setup Flycheck for Swiftlint."
  (interactive)
  (unless (memq 'swiftlint flycheck-checkers)
    (add-to-list 'flycheck-checkers 'swiftlint)
    (if (memq 'xcode flycheck-checkers)
        (flycheck-add-next-checker 'swiftlint 'xcode)
      (with-eval-after-load 'flycheck-xcode
        (flycheck-add-next-checker 'xcode 'swiftlint)))))

;;;###autoload
(defun flycheck-swiftlint-autocorrect ()
  "Automatically fix Swiftlint errors."
  (interactive)
  (if (not (executable-find "swiftlint"))
      (user-error "Swiftlint not found!")
    (flycheck-swiftlint-when-let*
        ((default-directory
           (flycheck-swiftlint--find-swiftlint-directory)))
      (compile "swiftlint autocorrect"))))

(defun flycheck-swiftlint--find-swiftlint-directory ()
  "Return directory for use with Swiftlint."
  (or
   (locate-dominating-file buffer-file-name ".swiftlint.yml")
   (locate-dominating-file buffer-file-name ".git")
   (flycheck-swiftlint--find-xcodeproj-directory)))

(defun flycheck-swiftlint--find-xcodeproj-directory (&optional _checker)
  "Return directory containing .xcodeproj file or nil if file is not found."
  (flycheck-swiftlint-when-let* ((xcode-project-path
                                  (flycheck-swiftlint--project-find-xcodeproj buffer-file-name)))
    (file-name-directory xcode-project-path)))

(defun flycheck-swiftlint--project-find-xcodeproj (directory-or-file)
  "Search DIRECTORY-OR-FILE and parent directories for an Xcode project file.
Returns the path to the Xcode project, or nil if not found.

Taken from https://github.com/nhojb/xcode-project/blob/master/xcode-project.el."
  (if directory-or-file
      (let (xcodeproj
            (directory (if (file-directory-p directory-or-file)
                           directory-or-file
                         (file-name-directory directory-or-file))))
        (setq directory (expand-file-name directory))
        (while (and (not xcodeproj) (not (equal directory "/")))
          (setq xcodeproj (directory-files directory t ".*\.xcodeproj$" nil))
          (setq directory (file-name-directory (directory-file-name directory))))
        (car xcodeproj))))

(defun flycheck-swiftlint-should-run-p ()
  "Return whether or not swiftlint should run."
  (executable-find "swiftlint"))

(provide 'flycheck-swiftlint)
;;; flycheck-swiftlint.el ends here
