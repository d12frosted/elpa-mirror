;;; projectile-codesearch.el --- Integration of codesearch into projectile
;;
;; Author: Austin Bingham <austin.bingham@gmail.com>
;; Version: 2
;; Package-Version: 20180508.1522
;; Package-Commit: e40efc62e9333db0593bd81b5c78d08b19bfb193
;; URL: https://github.com/abingham/emacs-codesearch
;; Keywords: tools, development, search
;; Package-Requires: ((codesearch "20171122.431") (projectile "20150405.126"))
;;
;; This file is not part of GNU Emacs.
;;
;; Copyright (c) 2014-2017 Austin Bingham
;;
;;; Commentary:
;;
;; Description:
;;
;; This extension makes it convenient to use codesearch with
;; projectile projects.
;;
;; For more details, see the project page at
;; https://github.com/abingham/emacs-codesearch.
;;
;; For more details on projectile, see its project page at
;; http://github.com/bbatsov/projectile
;;
;; Installation:
;;
;; The simple way is to use package.el:
;;
;;     M-x package-install projectile-codesearch
;;
;; Or, copy projectile-codesearch.el to some location in your emacs
;; load path. Then add "(require 'projectile-codesearch)" to your
;; emacs initialization (.emacs, init.el, or something).
;;
;; Example config:
;;
;;   (require 'projectile-codesearch)
;;
;;; License:
;;
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Code:

(require 'listing-codesearch)

(defun projectile-codesearch-search (pattern file-pattern)
  (interactive
   (list
    (read-string "Pattern: " (thing-at-point 'symbol))
    (read-string "File pattern: " ".*")))
  (unless (projectile-project-root) (error "Not in a projectile project."))
  (let ((fpatt (concat (projectile-project-root) file-pattern)))
    (listing-codesearch-search pattern fpatt)))

(provide 'projectile-codesearch)

;;; projectile-codesearch.el ends here
