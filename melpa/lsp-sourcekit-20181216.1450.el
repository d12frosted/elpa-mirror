;;; lsp-sourcekit.el --- sourcekit-lsp client for lsp-mode     -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Daniel Martín

;; Author: Daniel Martín
;; Version: 0.1
;; Package-Version: 20181216.1450
;; Package-Commit: ff204ed820df8c3035ebdc4b5a583640d52caeeb
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

(defcustom lsp-sourcekit-executable
  "sourcekit"
  "Path of the lsp-sourcekit executable."
  :type 'file
  :group 'sourcekit)

(defcustom lsp-sourcekit-extra-args
  nil
  "Additional command line options passed to the lsp-sourcekit executable."
  :type '(repeat string)
  :group 'sourcekit)

;; ---------------------------------------------------------------------
;;  Register lsp client
;; ---------------------------------------------------------------------

(defun lsp-sourcekit--lsp-command ()
  "Generate the language server startup command."
  `(,lsp-sourcekit-executable
    ,@lsp-sourcekit-extra-args))

(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection 'lsp-sourcekit--lsp-command)
                  :major-modes '(swift-mode)
                  :server-id 'sourcekit-ls))

(provide 'lsp-sourcekit)
;;; lsp-sourcekit.el ends here
