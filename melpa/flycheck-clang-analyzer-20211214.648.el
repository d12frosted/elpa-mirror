;;; flycheck-clang-analyzer.el --- Integrate Clang Analyzer with flycheck     -*- lexical-binding: t; -*-

;; Copyright (c) 2017 Alex Murray

;; Author: Alex Murray <murray.alex@gmail.com>
;; Maintainer: Alex Murray <murray.alex@gmail.com>
;; URL: https://github.com/alexmurray/flycheck-clang-analyzer
;; Package-Version: 20211214.648
;; Package-Commit: 646d9f3a80046ab231a07526778695d5decad92d
;; Version: 0.8
;; Package-Requires: ((flycheck "0.24") (emacs "24.4"))

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

;; This packages integrates the Clang Analyzer `clang --analyze` tool with
;; flycheck to automatically detect any new defects in your code on the fly.
;;
;; It depends on and leverages either the existing c/c++-clang flycheck
;; backend, or `emacs-cquery', `emacs-ccls' `irony-mode' or `rtags' to provide
;; compilation arguments etc and so provides automatic static analysis with
;; zero setup.
;;
;; Automatically chains itself as the next checker after c/c++-clang, lsp-ui,
;; irony and rtags flycheck checkers.

;;;; Setup

;; (with-eval-after-load 'flycheck
;;    (require 'flycheck-clang-analyzer)
;;    (flycheck-clang-analyzer-setup))

;;; Code:
(require 'cl-lib)
(require 'flycheck)

(defvar flycheck-clang-analyzer--backends
  '(((:name . cquery)
     (:active . flycheck-clang-analyzer--cquery-active)
     (:get-compile-options . flycheck-clang-analyzer--cquery-get-compile-options)
     (:get-default-directory . flycheck-clang-analyzer--cquery-get-default-directory))
    ((:name . ccls)
     (:active . flycheck-clang-analyzer--ccls-active)
     (:get-compile-options . flycheck-clang-analyzer--ccls-get-compile-options)
     (:get-default-directory . flycheck-clang-analyzer--ccls-get-default-directory))
    ((:name . irony)
     (:active . flycheck-clang-analyzer--irony-active)
     (:get-compile-options . flycheck-clang-analyzer--irony-get-compile-options)
     (:get-default-directory . flycheck-clang-analyzer--irony-get-default-directory))
    ((:name . rtags)
     (:active . flycheck-clang-analyzer--rtags-active)
     (:get-compile-options . flycheck-clang-analyzer--rtags-get-compile-options)
     (:get-default-directory . flycheck-clang-analyzer--rtags-get-default-directory))
    ((:name . flycheck-clang)
     (:active . flycheck-clang-analyzer--flycheck-clang-active)
     (:get-compile-options . flycheck-clang-analyzer--flycheck-clang-get-compile-options)
     (:get-default-directory . flycheck-clang-analyzer--flycheck-clang-get-default-directory))))

(defun flycheck-clang-analyzer--backend ()
  "Get current backend which is active."
  (car (cl-remove-if-not (lambda (backend) (funcall (cdr (assoc :active backend))))
                         flycheck-clang-analyzer--backends)))

(defun flycheck-clang-analyzer--buffer-is-header ()
  "Determine if current buffer is a header file."
  (when (buffer-file-name)
    (let ((extension (file-name-extension (buffer-file-name))))
      ;; capture .h, .hpp, .hxx etc - all start with h
      (string-equal "h" (substring extension 0 1)))))

(defun flycheck-clang-analyzer--predicate ()
  "Return t when should be active, nil if not."
  (and (not (flycheck-clang-analyzer--buffer-is-header))
       (flycheck-clang-analyzer--backend)))

;; cquery
(defun flycheck-clang-analyzer--cquery-active ()
  "Check if 'cquery-mode' is available and active."
  (and (fboundp 'cquery--is-cquery-buffer) (cquery--is-cquery-buffer)))

(defun flycheck-clang-analyzer--cquery-get-compile-options ()
  "Get compile options from cquery."
  (if (fboundp 'cquery-file-info)
      (gethash "args" (cquery-file-info))))

(defun flycheck-clang-analyzer--cquery-get-default-directory ()
  "Get default directory from cquery."
  (if (fboundp 'cquery--get-root)
      (cquery--get-root)))

;; ccls
(defun flycheck-clang-analyzer--ccls-active ()
  "Check if 'ccls-mode' is available and active."
  (and (fboundp 'ccls-file-info) (ccls-file-info)))

(defun flycheck-clang-analyzer--ccls-get-compile-options ()
  "Get compile options from ccls."
  (if (fboundp 'ccls-file-info)
      ;; needs to be a list not a vector
      (append (gethash "args" (ccls-file-info)) nil)))

(defun flycheck-clang-analyzer--ccls-get-default-directory ()
  "Get default directory from ccls."
  (if (fboundp 'ccls--get-root)
      (ccls--get-root)))

;; irony
(defun flycheck-clang-analyzer--irony-active ()
  "Check if 'irony-mode' is available and active."
  (and (fboundp 'irony-mode) (boundp 'irony-mode) irony-mode))

(defun flycheck-clang-analyzer--irony-get-compile-options ()
  "Get compile options from irony."
  (if (fboundp 'irony-cdb--autodetect-compile-options)
      (nth 1 (irony-cdb--autodetect-compile-options))))

(defun flycheck-clang-analyzer--irony-get-default-directory ()
  "Get default directory from irony."
  (if (fboundp 'irony-cdb--autodetect-compile-options)
      (nth 2 (irony-cdb--autodetect-compile-options))))

;; rtags
(defun flycheck-clang-analyzer--rtags-active ()
  "Check if rtags is available and active."
  (and (boundp 'rtags-enabled)
       rtags-enabled
       (fboundp 'rtags-is-running)
       (rtags-is-running)
       (fboundp 'rtags-compilation-flags)
       (> (length (rtags-compilation-flags)) 0)))

(defun flycheck-clang-analyzer--rtags-get-compile-options ()
  "Get compile options from rtags."
  (if (fboundp 'rtags-compilation-flags)
      (rtags-compilation-flags)))

(defun flycheck-clang-analyzer--rtags-get-default-directory ()
  "Get default directory from rtags."
  (if (boundp 'rtags-current-project)
      rtags-current-project))

;; flycheck-clang
(defun flycheck-clang-analyzer--flycheck-clang-active ()
  "Get active from flycheck-clang."
  t)

(defun flycheck-clang-analyzer--flycheck-clang-get-default-directory ()
  "Get default directory from flycheck-clang."
  default-directory)

(defun flycheck-clang-analyzer--flycheck-clang-get-compile-options ()
  "Get compile options from flycheck clang backend."
  (append (when flycheck-clang-language-standard (list (concat "-std=" flycheck-clang-language-standard)))
          (when flycheck-clang-standard-library (list (concat "-stdlib=" flycheck-clang-standard-library)))
          (when flycheck-clang-ms-extensions (list "-fms-extensions"))
          (when flycheck-clang-no-exceptions (list "-fno-exceptions"))
          (when flycheck-clang-no-rtti (list "-fno-rtti"))
          (when flycheck-clang-blocks (list "-fblocks"))
          (apply #'append (mapcar (lambda (i) (list "-include" i)) flycheck-clang-includes))
          (mapcar (lambda (i) (concat "-D" i)) flycheck-clang-definitions)
          (apply #'append (mapcar (lambda (i) (list "-I" i)) flycheck-clang-include-path))
          flycheck-clang-args))

(defun flycheck-clang-analyzer--get-compile-options ()
  "Get compile options for clang."
  (let ((backend (flycheck-clang-analyzer--backend)))
    (when backend
      (funcall (cdr (assoc :get-compile-options backend))))))

(defun flycheck-clang-analyzer--get-default-directory (_checker)
  "Get default directory for clang."
  (let ((backend (flycheck-clang-analyzer--backend)))
    (when backend
      (funcall (cdr (assoc :get-default-directory backend))))))

(defun flycheck-clang-analyzer--verify (_checker)
  "Verify CHECKER."
  (let ((backend (flycheck-clang-analyzer--backend)))
    (list
     (flycheck-verification-result-new
      :label "Backend"
      :message (format "%s" (if backend (cdr (assoc :name backend))
                              "No active supported backend."))
      :face (if backend 'success '(bold error))))))

(defun flycheck-clang-analyzer--filter-compile-options (options)
  "Filter OPTIONS to remove options which conflict with the clang static analyzer."
  (let ((remove-next nil))
    (cl-remove-if #'(lambda (option)
                      ;; remove any instance of the source file itself or -c
                      ;; which is not relevant for analysis and the name of the
                      ;; compiler itself since rtags likes to return this
                      (or (and remove-next (progn (setq remove-next nil) t))
                          (string= (expand-file-name buffer-file-name) option)
                          (string= "-c" option)
                          (string-prefix-p "-m" option)
                          (string-prefix-p "-f" option)
                          (executable-find option)
                          (and (string= "-o" option)
                               (setq remove-next t))))
                  options)))

(flycheck-define-checker clang-analyzer
  "A checker using clang-analyzer.

See `https://clang-analyzer.llvm.org/'."
  :command ("clang"
            "--analyze"
            (eval (flycheck-clang-analyzer--filter-compile-options
                   (flycheck-clang-analyzer--get-compile-options)))
            ;; disable after compdb options to ensure stay disabled
            "-fno-color-diagnostics" ; don't include color in output
            "-fno-caret-diagnostics" ; don't indicate location in output
            "-fno-diagnostics-show-option" ; don't show warning group
            "-Xanalyzer" "-analyzer-output=text"
            source-inplace)
  :predicate flycheck-clang-analyzer--predicate
  :working-directory flycheck-clang-analyzer--get-default-directory
  :verify flycheck-clang-analyzer--verify
  :error-patterns ((warning line-start (file-name) ":" line ":" column
                            ": warning: " (optional (message))
                            line-end)
                   (error line-start (file-name) ":" line ":" column
                          ": error: " (optional (message))
                          line-end))
  :error-filter
  (lambda (errors)
    (let ((errors (flycheck-sanitize-errors errors)))
      (dolist (err errors)
        ;; Clang will output empty messages for #error/#warning pragmas without
        ;; messages.  We fill these empty errors with a dummy message to get
        ;; them past our error filtering
        (setf (flycheck-error-message err)
              (or (flycheck-error-message err) "no message")))
      (flycheck-fold-include-levels errors "In file included from")))
  :modes (c-mode c++-mode objc-mode))

;;;###autoload
(defun flycheck-clang-analyzer-setup ()
  "Setup flycheck-clang-analyzer.

Add `clang-analyzer' to `flycheck-checkers'."
  (interactive)
  ;; append to list and chain after existing checkers
  (add-to-list 'flycheck-checkers 'clang-analyzer t)
  (dolist (feature-checker '((lsp-mode . lsp)
                             (lsp-ui . lsp-ui)
                             (flycheck-irony . irony)
                             (flycheck-rtags . rtags)
                             (flycheck . c/c++-clang)))
    (with-eval-after-load (car feature-checker)
      (when (flycheck-valid-checker-p (cdr feature-checker))
        (flycheck-add-next-checker (cdr feature-checker) '(warning . clang-analyzer))))))

(provide 'flycheck-clang-analyzer)

;;; flycheck-clang-analyzer.el ends here
