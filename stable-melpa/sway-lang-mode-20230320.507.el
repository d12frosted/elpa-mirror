;;; sway-lang-mode.el --- Major mode for sway  -*- lexical-binding: t; -*-

;; Version: 0.0.1
;; Package-Version: 20230320.507
;; Package-Commit: 1d4615cc99d57280fb4b301d8339f408d987d317
;; Author: Hamza Hamud
;; Url: https://github.com/hhamud/sway-mode
;; Keywords: languages
;; Package-Requires: ((emacs "25.1")(lsp-mode "6.0")(rust-mode "1.0.5"))
;; SPDX-License-Identifier: Apache-2.0

;; This file is distributed under the terms of both the MIT license and the
;; Apache License (version 2.0).

;;; commentary:

;; This package implements a major-mode for editing Sway source code.


;;; code:

(require 'lsp-mode)
(require 'rust-mode)

(eval-when-compile
  (require 'rx))

(defun sway-lang-mode-fmt-custom (path)
  "Formats sway files within the supplied PATH."
  (interactive "spath to toml file:")
  (shell-command "forc fmt --path %s" path))

(defun sway-lang-mode-fmt ()
  "Formats a single sway file."
  (interactive)
  (let ((default-directory (expand-file-name "../")))
    (shell-command "forc fmt")))

(defun sway-lang-mode-test ()
  "Run forc test."
  (interactive)
  (let ((default-directory (expand-file-name "../")))
    (shell-command "forc test")))

(defun sway-lang-mode-build ()
  "Build a forc project."
  (interactive)
  (let ((default-directory (expand-file-name "../")))
    (shell-command "forc build")))

(defun sway-lang-mode-deploy ()
  "Build a forc project."
  (interactive)
  (let ((default-directory (expand-file-name "../")))
    (shell-command "forc deploy")))

(defvar sway-lang-function-call-highlights "\\(\\(?:\\w\\|\\s_\\)+\\)\\(<.+>\\)?\s*("
  "Regex for general Sway function calls.")

(defvar sway-lang-function-call-type-highlights "\\b\\([A-Za-z][A-Za-z0-9_]*\\|_[A-Za-z0-9_]+\\)\\(::\\)\\(<.*>\s*\\)\("
  "Regex for Sway function calls with type.")

(defvar sway-lang-declarations-without-name '("contract" "script" "predicate")
  "Sway specific declarations.")

(defvar sway-lang-type-level-declaration  "\\b\\(abi\\|library\\)\\s-"
  "Sway specific type level declaration.")

(defvar sway-lang-highlights
      `(
        (,(regexp-opt sway-lang-declarations-without-name 'symbols) . 'font-lock-keyword-face)
        (, sway-lang-type-level-declaration . 'font-lock-keyword-face)
        (,sway-lang-function-call-highlights . (1 'font-lock-function-name-face))
        (,sway-lang-function-call-type-highlights . (1 'font-lock-function-name-face))))



;;; KeyMap
(defvar sway-lang-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "C-c C-c") 'sway-lang-mode-fmt)
    (define-key keymap (kbd "C-c C-a") 'sway-lang-mode-fmt-custom)
    (define-key keymap (kbd "C-c C-t") 'sway-lang-mode-test)
    (define-key keymap (kbd "C-c C-b") 'sway-lang-mode-build)
    (define-key keymap (kbd "C-c C-d") 'sway-lang-mode-deploy)
    keymap)
  "Keymap for `sway-lang-mode'.")


;;;###autoload
(define-derived-mode sway-lang-mode rust-mode
  "Sway"
  (font-lock-add-keywords nil sway-lang-highlights)
  (use-local-map sway-lang-mode-map))


;;;###autoload
(when (featurep 'lsp-mode)
  (add-to-list 'lsp-language-id-configuration
               '(sway-lang-mode . "sway"))
  (lsp-dependency 'forc-lsp
                  '(:system "forc-lsp"))
  (lsp-register-client
   (make-lsp-client :major-modes '(sway-lang-mode)
                    :server-id 'forc-lsp
                    :new-connection (lsp-stdio-connection
                                     (lambda () `(,(lsp-package-path 'forc-lsp)))))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sw\\'" . sway-lang-mode))

;; add to feature list
(provide 'sway-lang-mode)
;;; sway-lang-mode.el ends here
