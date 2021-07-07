;;; phpt-mode.el --- Major mode for editing PHPT test code  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 12 May 2019
;; Version: 0.0.1
;; Package-Version: 20190512.1809
;; Package-Commit: deb386f1a81003074c476f15e1975d445ff6df01
;; Keywords: languages, php
;; Homepage: https://github.com/emacs-php/phpt-mode
;; Package-Requires: ((emacs "25") (polymode "0.1.5") (php-mode "1.21.2"))
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Major mode for editing PHPT test code.
;; Files of this format are used as test code for the PHP interpreter.
;; Also, a subset of this format is included in PHPUnit.
;;
;; ## Specification
;;
;; http://qa.php.net/phpt_details.php

;;; Code:
(require 'polymode)
(require 'php-mode)

(eval-when-compile
  (declare-function poly-phpt-mode "polymode" (&optional ARG)))

;; Constants
(defvar phpt-mode-syantax-table
  (let ((table (make-syntax-table)))
    table))

(defconst phpt-sections
  '("TEST" "DESCRIPTION" "CREDITS" "SKIPIF" "CAPTURE_STDIO" "EXTENSIONS"
    "POST" "PUT" "POST_RAW" "GZIP_POST" "DEFLATE_POST" "GET" "COOKIE"
    "STDIN" "INI" "ARGS" "ENV" "PHPDBG" "FILE" "FILEEOF" "FILE_EXTERNAL"
    "REDIRECTTEST" "CGI" "XFAIL" "EXPECTHEADERS" "EXPECT" "EXPECTF"
    "EXPECTREGEX" "EXPECT_EXTERNAL" "EXPECTF_EXTERNAL" "EXPECTREGEX_EXTERNAL"
    "CLEAN"))

(defconst phpt-mode-keywords
  (list
   (cons (rx-to-string `(: line-start "--" (or ,@phpt-sections) "--" line-end))
         '(0 font-lock-function-name-face))))

;; Polymode
(define-innermode phpt-php-innermode
  :mode 'php-mode
  :head-matcher "^--\\(?:FILE\\|SKIPIF\\)--\n"
  :tail-matcher "\\?>"
  :head-mode 'host
  :tail-mode 'host)

(define-innermode phpt-ini-innermode
  :mode 'conf-mode
  :head-matcher "^--\\(?:INI\\)--\n"
  :tail-matcher "\n--"
  :head-mode 'host
  :tail-mode 'host)

(define-polymode poly-phpt-mode
  :innermodes '(phpt-php-innermode phpt-ini-innermode))

;;;###autoload
(define-derived-mode phpt-mode prog-mode "phpt"
  "Major mode for editing phpt test code.

\\{phpt-mode-map}"
  :syntax-table phpt-mode-syantax-table
  (setq font-lock-defaults '(phpt-mode-keywords nil t))
  (poly-phpt-mode))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.phpt\\'" . phpt-mode))

(provide 'phpt-mode)
;;; phpt-mode.el ends here
