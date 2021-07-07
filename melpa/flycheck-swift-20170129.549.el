;;; flycheck-swift.el --- Flycheck extension for Apple's Swift. -*- lexical-binding: t -*-

;; Copyright (C) 2014-2016 taku0, Chris Barrett, Bozhidar Batsov, Arthur Evstifeev

;; Authors: taku0 (http://github.com/taku0)
;;       Chris Barrett <chris.d.barrett@me.com>
;;       Bozhidar Batsov <bozhidar@batsov.com>
;;       Arthur Evstifeev <lod@pisem.net>
;; Version: 2.0
;; Package-Version: 20170129.549
;; Package-Commit: 4c5ad401252400a78da395fd56a71e67ff8c2761
;; Package-Requires: ((emacs "24.4") (flycheck "0.25"))
;; Keywords: languages swift

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

;; Flycheck extension for Apple's Swift.

;;; Code:

(require 'flycheck)
(require 'cl-lib)

;;; Flycheck

(flycheck-def-executable-var swift "swiftc")

(flycheck-def-option-var flycheck-swift-extra-flags nil swift
  "Extra flags prepended to arguments of swiftc"
  :type '(repeat (string :tag "Flags"))
  :safe #'flycheck-string-list-p)

(flycheck-def-option-var flycheck-swift-sdk-path nil swift
  "A name of the targeted SDK or path to the targeted SDK"
  :type '(choice (const :tag "Don't link against sdk" nil)
                 (string :tag "Targeted SDK path or name"))
  :safe #'stringp)

(flycheck-def-option-var flycheck-swift-linked-sources '("*.swift") swift
  "Source files path to link against. Can be glob, i.e. *.swift"
  :type '(repeat (string :tag "Linked Sources"))
  :safe #'flycheck-string-list-p)

(flycheck-def-option-var flycheck-swift-framework-search-paths nil swift
  "A list of framework search paths"
  :type '(repeat (directory :tag "Include directory"))
  :safe #'flycheck-string-list-p)

(flycheck-def-option-var flycheck-swift-cc-include-search-paths nil swift
  "A list of include file search paths to pass to the Objective-C compiler"
  :type '(repeat (directory :tag "Include directory"))
  :safe #'flycheck-string-list-p)

(flycheck-def-option-var flycheck-swift-target nil swift
  "Target used by swift compiler"
  :type '(choice (const :tag "Don't specify target" nil)
                 (string :tag "Build target"))
  :safe #'stringp)

(flycheck-def-option-var flycheck-swift-import-objc-header nil swift
  "Objective C header file to import, if any"
  :type '(choice (const :tag "Don't specify objective C bridging header" nil)
                 (string :tag "Objective C bridging header path"))
  :safe #'stringp)

(flycheck-define-checker swift
  "Flycheck plugin for for Apple's Swift programming language."
  :command ("swiftc"
            (eval flycheck-swift-extra-flags)
            "-parse"
            (option "-sdk" flycheck-swift-sdk-path)
            (option-list "-F" flycheck-swift-framework-search-paths)
            ;; Swift compiler will complain about redeclaration
            ;; if we will include original file along with
            ;; temporary source file created by flycheck.
            ;; We also don't want a hidden emacs interlock files.
            (eval
             (let ((source-original (expand-file-name
                                     (car
                                      (flycheck-substitute-argument
                                       'source-original
                                       'swift))))
                   (default-directory-old default-directory))
               (unwind-protect
                   (progn
                     (setq default-directory
                           (file-name-directory source-original))
                     (cl-remove-if
                      #'(lambda (path)
                          (or
                           (string-match "^\\.#" (file-name-nondirectory path))
                           (equal source-original path)))
                      (cl-mapcan
                       #'(lambda (path) (file-expand-wildcards path t))
                       flycheck-swift-linked-sources)))
                 (setq default-directory default-directory-old))))
            (option "-target" flycheck-swift-target)
            (option "-import-objc-header" flycheck-swift-import-objc-header)
            (option-list "-Xcc" flycheck-swift-cc-include-search-paths
                         flycheck-swift-prepend-for-cc-include-search-path)
            source)
  :error-patterns ((error line-start (file-name) ":" line ":" column ": "
                          "error: " (message) line-end)
                   (warning line-start (file-name) ":" line ":" column ": "
                            "warning: " (message) line-end))
  :modes (swift-mode swift3-mode))

(defun flycheck-swift-prepend-for-cc-include-search-path (opt path)
  "Return list for -Xcc -I option.

OPT is assumed to be -Xcc.
PATH is a include search path."
  (list opt (concat "-I" path)))

;;;###autoload
(defun flycheck-swift-setup ()
  "Setup Flycheck for Swift."
  (interactive)
  ;; Add checkers in reverse order, because `add-to-list' adds to front.
  (add-to-list 'flycheck-checkers 'swift))

(provide 'flycheck-swift)

;;; flycheck-swift.el ends here
