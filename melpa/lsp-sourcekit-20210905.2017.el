;;; lsp-sourcekit.el --- sourcekit-lsp client for lsp-mode     -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Daniel Martín

;; Author: Daniel Martín
;; Version: 0.1
;; Package-Version: 20210905.2017
;; Package-Commit: f877659babd3b5f8ec09a8ad7d08193d95b6822e
;; Homepage: https://github.com/emacs-lsp/lsp-sourcekit
;; Package-Requires: ((emacs "25.1") (lsp-mode "5"))
;; Keywords: languages, lsp, swift, objective-c, c++

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and-or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.
;;
;;; Commentary:

;;
;; Call (lsp) after visiting a file in swift-mode major mode.
;;
;; TODO: Configure the Objective-C/C++ LSP client (requires clangd).

;;; Code:

(require 'lsp)

;; ---------------------------------------------------------------------
;;   Customization
;; ---------------------------------------------------------------------
(defgroup lsp-sourcekit nil
  "LSP support for swift, using sourcekit-lsp."
  :group 'lsp-mode
  :prefix "lsp-sourcekit-"
  :link '(url-link "https://github.com/apple/sourcekit-lsp"))

(defcustom lsp-sourcekit-executable "sourcekit-lsp"
  "Path of the sourcekit-lsp executable."
  :group 'lsp-sourcekit
  :type 'file)

(defcustom lsp-sourcekit-extra-args nil
  "Additional command line options passed to the lsp-sourcekit executable."
  :type '(repeat string)
  :group 'lsp-sourcekit)


;;;###autoload
(defun lsp-sourcekit--find-executable-with-xcrun ()
  "sourcekit-lsp may be installed behind xcrun; if we can't find
the `lsp-sourcekit-executable' on PATH, try it with xcrun."
  (and (not (file-name-absolute-p lsp-sourcekit-executable))
       (executable-find "xcrun")
       (with-demoted-errors "lsp-sourcekit: find server with xcrun(1): %S"
         (car-safe (process-lines "xcrun" "--find" lsp-sourcekit-executable)))))


;; ---------------------------------------------------------------------
;;  Register lsp client
;; ---------------------------------------------------------------------
;;;###autoload
(with-eval-after-load 'lsp-mode
  (lsp-dependency
   'sourcekit-lsp
   (list :system 'lsp-sourcekit-executable)
   (list :system #'lsp-sourcekit--find-executable-with-xcrun))


  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection
                                     (lambda ()(cons lsp-sourcekit-executable lsp-sourcekit-extra-args)))
                    :major-modes '(swift-mode)
                    :server-id 'sourcekit-ls)))

(provide 'lsp-sourcekit)
;;; lsp-sourcekit.el ends here
