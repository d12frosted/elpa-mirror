;;; bento.el --- Flycheck integration for the Bento code checker -*- lexical-binding: t; -*-

;; Copyright (C) 2019 r2c

;; Author: Ash Zahlen <ash@returntocorp.com>
;; License: GPLv3
;; URL: https://github.com/returntocorp/bento-emacs
;; Package-Commit: 31546a03475fc2b3ffd3159fe1beda55f7762224
;; Version: 0.1.0
;; Package-Version: 20191024.2123
;; Package-X-Original-Version: 0.1.0
;; Package-Requires: ((flycheck "0.22") (emacs "25.1") (f "0.20"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;; bento is a code quality/productivity tool. This provides flycheck integration
;; with it. See https://pypi.org/project/bento-cli/.

;;; Code:

(eval-when-compile (require 'subr-x))
(require 'f)
(require 'flycheck)
(require 'json)

(defun bento--parse-flycheck (output checker buffer)
  "Parse OUTPUT as bento JSON.
CHECKER and BUFFER are supplied by Flycheck and indicate the checker that ran
and the buffer that were checked."
  (when-let ((buffer-path (buffer-file-name buffer))
             (bento-dir (bento--find-base-dir buffer-path))
             (findings (car (flycheck-parse-json output))))
    (mapcar
     (apply-partially #'bento--finding-to-flycheck checker buffer)
     findings)))

(defun bento--finding-to-flycheck (checker _buffer finding)
  "Convert FINDING into a Flycheck error found by CHECKER in BUFFER."
  (let-alist finding
    (flycheck-error-new-at
     .line
     .column
     (pcase .severity
       (1 'warning)
       (2 'error)
       (_ 'error))
     .message
     :id .check_id
     :checker checker)))

(defun bento--find-base-dir (path)
  "Starting from the directory containing PATH, find the first .bento.yml file."
  (locate-dominating-file path ".bento.yml"))

(flycheck-define-checker bento
  "Multi-language checker using Bento."
  :command ("bento" "check" "--formatter" "json" source-inplace)
  :error-parser bento--parse-flycheck
  :enabled (lambda () (bento--find-base-dir buffer-file-name))
  ;; Bento needs to be run from the directory with the .bento.yml.
  :working-directory (lambda (_checker) (bento--find-base-dir buffer-file-name))
  :modes (python-mode js-mode js2-mode js-jsx-mode))

(provide 'bento)
;;; bento.el ends here
