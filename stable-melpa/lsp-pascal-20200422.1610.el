;;; lsp-pascal.el --- LSP client for Pascal -*- lexical-binding: t; -*-

;; Copyright 2020 Arjan Adriaanse

;; Author: Arjan Adriaanse <arjan@adriaan.se>
;; Version: 0.1
;; Package-Version: 20200422.1610
;; Package-Commit: 9b65bf9e923b1459d1feb1d7528e5855e7bd4ef2
;; Package-Requires: ((emacs "24.4") (lsp-mode "6.3"))
;; Keywords: languages, tools
;; URL: https://github.com/arjanadriaanse/lsp-pascal

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;; LSP client to support Pascal through the lsp-mode package using the
;; Pascal Language Server which can be found here:
;; https://github.com/arjanadriaanse/pascal-language-server

;;; Code:

(defcustom lsp-pascal-command "pasls"
  "Command to invoke the Pascal Language Server."
  :type '(file)
  :group 'lsp-pascal)

(defcustom lsp-pascal-fpcdir ""
  "Path to the FPC sources."
  :type '(choice (const :tag "Default" "")
                 (directory :tag "Other" "~/freepascal/fpc"))
  :group 'lsp-pascal)

(defcustom lsp-pascal-pp ""
  "Path to the Free Pascal compiler executable."
  :type '(choice (const :tag "Default" "")
                 (file :tag "Other" "fpc"))
  :group 'lsp-pascal)

(defcustom lsp-pascal-lazarusdir ""
  "Path to the Lazarus sources."
  :type '(choice (const :tag "Default" "")
                 (directory :tag "Other" "~/pascal/lazarus"))
  :group 'lsp-pascal)

(defcustom lsp-pascal-fpctarget ""
  "Target operating system for cross compiling."
  :type '(choice (const :tag "Default" "")
                 (string :tag "Other" ""))
  :group 'lsp-pascal)

(defcustom lsp-pascal-fpctargetcpu ""
  "Target CPU for cross compiling."
  :type '(choice (const :tag "Default" "")
                 (string :tag "Other" ""))
  :group 'lsp-pascal)

(require 'lsp-mode)

(add-to-list 'lsp-language-id-configuration '(pascal-mode . "pascal"))
(add-to-list 'lsp-language-id-configuration '(opascal-mode . "pascal"))

(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection (lambda ()
                                                          lsp-pascal-command))
                  :major-modes '(opascal-mode pascal-mode)
                  :environment-fn (lambda ()
                                    '(("FPCDIR" . lsp-pascal-fpcdir)
                                      ("PP" . lsp-pascal-pp)
                                      ("LAZARUSDIR" . lsp-pascal-lazarusdir)
                                      ("FPCTARGET" . lsp-pascal-fpctarget)
                                      ("FPCTARGETCPU" . lsp-pascal-fpctargetcpu)))
                  :server-id 'pasls))

(provide 'lsp-pascal)
;;; lsp-pascal.el ends here
