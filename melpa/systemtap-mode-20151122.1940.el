;;; systemtap-mode.el --- A mode for SystemTap

;; Copyright (C) 2008 Tomoki Sekiyama <sekiyama@yahoo.co.jp>
;; Copyright (C) 2012 Rüdiger Sonderfeld <ruediger@c-plusplus.de>

;; Authors:    2008 Tomoki Sekiyama
;;             2012 Rüdiger Sonderfeld
;; Maintainer: ruediger@c-plusplus.de
;; Keywords:   tools languages
;; Package-Version: 20151122.1940
;; Package-Commit: 8b5086d6b0050a12bb37e33c24c24d1f420afd3b
;; Version:    0.02
;; URL:        https://github.com/ruediger/systemtap-mode

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This code is based on the original systemtap-mode.el written by
;; Tomoki Sekiyama.  It can be found at
;; http://coderepos.org/share/browser/lang/elisp/systemtap-mode/systemtap-mode.el?format=txt

;; TODO:
;;   - indent embedded-C %{ ... %} correctly
;;   - add parameter for indentation
;;   - ...

;;; Code:

(defconst systemtap-mode-version "0.02"
  "SystemTap Mode version number.")

(defgroup systemtap-mode nil
  "A mode for SystemTap."
  :prefix "systemtap-"
  :group 'tools
  :group 'languages)

(require 'cc-mode)
(require 'cc-awk)
(eval-when-compile
  (require 'cc-langs)
  (require 'cc-fonts))

;; Work around emacs bug#18845
(eval-and-compile
  (when (and (= emacs-major-version 24) (>= emacs-minor-version 4))
    (require 'cl)))

(eval-and-compile
  (c-add-language 'systemtap-mode 'awk-mode))

;; Syntax definitions for SystemTap
(c-lang-defconst c-primitive-type-kwds
  systemtap '("string" "long" "global"))

(c-lang-defconst c-modifier-kwds
  systemtap (append '("probe" "function") (c-lang-const c-modifier-kwds)))

(c-lang-defconst c-block-stmt-2-kwds
  systemtap '("else" "for" "foreach" "if" "while"))

(c-lang-defconst c-simple-stmt-kwds
  systemtap '("break" "continue" "delete" "next" "return"))

(c-lang-defconst c-identifier-syntax-modifications
  systemtap '((?. . "_") (?' . ".")))

(defcustom systemtap-font-lock-extra-types nil
  "Font-lock extra types for SystemTap mode."
  :group 'systemtap-mode)

(defconst systemtap-font-lock-keywords-1 (c-lang-const c-matchers-1 systemtap)
  "Minimal highlighting for SystemTap mode.")

(defconst systemtap-font-lock-keywords-2 (c-lang-const c-matchers-2 systemtap)
  "Fast normal highlighting for SystemTap mode.")

(defconst systemtap-font-lock-keywords-3 (c-lang-const c-matchers-3 systemtap)
  "Accurate normal highlighting for SystemTap mode.")

(defvar systemtap-font-lock-keywords systemtap-font-lock-keywords-3
  "Default expressions to highlight in SystemTap mode.")

(defvar systemtap-mode-syntax-table nil
  "Syntax table used in systemtap-mode buffers.")
(unless systemtap-mode-syntax-table
    (setq systemtap-mode-syntax-table
          (funcall (c-lang-const c-make-mode-syntax-table systemtap))))

(defvar systemtap-mode-abbrev-table nil
  "Abbreviation table used in systemtap-mode buffers.")

(defvar systemtap-mode-map
  (let ((map (c-make-inherited-keymap)))
    (define-key map "\C-ce" 'systemtap-execute-script)
    (define-key map "\C-cc" 'systemtap-interrupt-script)
    map)
  "Keymap used in systemtap-mode buffers.")

(easy-menu-define systemtap-menu systemtap-mode-map "SystemTap Mode Commands"
  (cons "SystemTap"
        (append
         '(["Execute This Script" systemtap-execute-script t]
           ["Interrupt Execution of Script" systemtap-interrupt-script (get-process "systemtap-script")]
           "----")
         (c-lang-const c-mode-menu systemtap))))

;; Execution function of Current Script
(defvar systemtap-buffer-name "*SystemTap*"
  "Name of the SystemTap execution buffer.")

(defcustom systemtap-stap-program "stap"
  "SystemTap's stap program to execute scripts."
  :type 'file
  :group 'systemtap-mode)

(defcustom systemtap-stap-options '("-v")
  "A list of options to give to stap."
  :type '(repeat string)
  :group 'systemtap-mode)

(defun systemtap-execute-script ()
  "Execute current SystemTap script."
  (interactive)
  (when (get-buffer systemtap-buffer-name)
    (kill-buffer systemtap-buffer-name))
  (get-buffer-create systemtap-buffer-name)
  (display-buffer systemtap-buffer-name)
  (let* ((file-name (buffer-file-name))
         (options (append systemtap-stap-options (list file-name))))
    (apply #'start-process "systemtap-script" systemtap-buffer-name
           systemtap-stap-program options))
  (message "Execution of SystemTap script started."))

(defun systemtap-interrupt-script ()
  "Interrupt running SystemTap script."
  (interactive)
  (interrupt-process "systemtap-script")
  (message "SystemTap script is interrupted."))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.stp\\'" . systemtap-mode))

(require 'simple)

;;;###autoload
(define-derived-mode systemtap-mode prog-mode "SystemTap"
  "Major mode for editing SystemTap scripts.

Key bindings:
\\{systemtap-mode-map}"
  :group 'systemtap
  :syntax-table systemtap-mode-syntax-table
  :abbrev-table systemtap-mode-abbrev-table
  (c-initialize-cc-mode t)
  (use-local-map systemtap-mode-map)
  (c-init-language-vars systemtap-mode)
  (c-common-init 'systemtap-mode)
  (easy-menu-add systemtap-menu)
  (c-run-mode-hooks 'c-mode-common-hook)
  (c-update-modeline))

(provide 'systemtap-mode)

;;; systemtap-mode.el ends here
