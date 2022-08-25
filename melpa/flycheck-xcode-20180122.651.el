;;; flycheck-xcode.el --- Flycheck extension for Apple's Xcode. -*- lexical-binding: t -*-

;; Copyright (C) 2017 James Nguyen

;; Authors: James Nguyen <james@jojojames.com>
;; Maintainer: James Nguyen <james@jojojames.com>
;; URL: https://github.com/jojojames/flycheck-xcode
;; Package-Version: 20180122.651
;; Package-Commit: 6147ab777e2c08e4f5ffdbd85d3013ca700fa835
;; Version: 1.0
;; Package-Requires: ((emacs "25.1") (flycheck "0.25"))
;; Keywords: languages xcode

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
;; Flycheck extension for Apple's Xcode.
;;
;; (with-eval-after-load 'flycheck
;;   (flycheck-xcode-setup))

;;; Code:

(require 'flycheck)
(require 'cl-lib)

;; Compatibility
(eval-and-compile
  (with-no-warnings
    (if (version< emacs-version "26")
        (progn
          (defalias 'flycheck-xcode-if-let* #'if-let)
          (defalias 'flycheck-xcode-when-let* #'when-let)
          (function-put #'flycheck-xcode-if-let* 'lisp-indent-function 2)
          (function-put #'flycheck-xcode-when-let* 'lisp-indent-function 1))
      (defalias 'flycheck-xcode-if-let* #'if-let*)
      (defalias 'flycheck-xcode-when-let* #'when-let*))))

;;; Flycheck

(flycheck-def-executable-var xcode "xcodebuild")

(flycheck-def-option-var flycheck-xcode-extra-flags nil xcode
  "Extra flags prepended to arguments of xcodebuild."
  :type '(repeat (string :tag "Flags"))
  :safe #'flycheck-string-list-p)

(flycheck-def-option-var flycheck-xcode-sdk nil xcode
  "A name of the targeted SDK or path to the targeted SDK."
  :type '(choice (const :tag "Don't link against sdk." nil)
                 (string :tag "Targeted SDK path or name."))
  :safe #'stringp)

(flycheck-def-option-var flycheck-xcode-target nil xcode
  "Target used by xcode compiler."
  :type '(choice (const :tag "Don't specify target." nil)
                 (string :tag "Build target."))
  :safe #'stringp)

(flycheck-define-checker xcode
  "Flycheck plugin for for Apple's Xcode."
  :command ("xcodebuild"
            (eval (flycheck-xcode-warm-or-cold-build))
            (eval flycheck-xcode-extra-flags)
            (option "-sdk" flycheck-xcode-sdk)
            (option "-target" flycheck-xcode-target)
            "-quiet")
  :error-patterns ((error line-start (file-name) ":" line ":" column ": "
                          "error: " (message) line-end)
                   (warning line-start (file-name) ":" line ":" column ": "
                            "warning: " (message) line-end)
                   (info line-start (file-name) ":" line ":" column ": "
                         "note: " (message) line-end))
  :modes (c-mode c++-mode objc-mode swift-mode)
  :predicate
  (lambda ()
    (funcall #'flycheck-xcode--xcodeproj-available-p))
  :working-directory
  (lambda (checker)
    (flycheck-xcode--find-xcodeproj-directory checker)))

;;;###autoload
(defun flycheck-xcode-setup ()
  "Setup Flycheck for Xcode."
  (interactive)
  (add-to-list 'flycheck-checkers 'xcode))

(defun flycheck-xcode-warm-or-cold-build ()
  "Return whether or not xcodebuild should be ran with clean."
  (if (flycheck-has-current-errors-p 'error)
      '("build")
    '("clean" "build")))

(defun flycheck-xcode--xcodeproj-available-p ()
  "Return whether or not current buffer is part of an Xcode project."
  (flycheck-xcode--find-xcodeproj-directory 'xcode))

(defun flycheck-xcode--find-xcodeproj-directory (&optional _checker)
  "Return directory containing .xcodeproj file or nil if file is not found."
  (flycheck-xcode-when-let*
      ((xcode-project-path
        (flycheck-xcode--project-find-xcodeproj buffer-file-name)))
    (file-name-directory xcode-project-path)))

(defun flycheck-xcode--project-find-xcodeproj (directory-or-file)
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

(provide 'flycheck-xcode)
;;; flycheck-xcode.el ends here
