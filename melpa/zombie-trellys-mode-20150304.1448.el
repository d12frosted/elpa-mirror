;;; zombie-trellys-mode.el --- A minor mode for interaction with Zombie Trellys  -*- lexical-binding: t; -*-

;; Copyright (C) 2015  David Raymond Christiansen

;; Author: David Raymond Christiansen <david@davidchristiansen.dk>
;; Keywords: languages
;; Package-Version: 20150304.1448
;; Package-Commit: 7f0c45fdda3a44c3b6d1762d116abb1421b8fba2
;; Package-Requires: ((emacs "24") (cl-lib "0.5") (haskell-mode "1.5"))
;; Version: 0.2.1

;; This program is free software; you can redistribute it and/or modify
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

;; This is a minor mode for interaction with Zombie - a
;; dependently-typed language that is a result of the Trellys
;; project. Due to limited time, zombie-trellys-mode is implemented as
;; a minor mode with a command for loading the current buffer's file
;; into Zombie and viewing the results. This mode inherits
;; `haskell-mode' to get a somewhat reasonable highlighting
;; experience.
;;
;; Zombie is available from https://code.google.com/p/trellys/

;;; Code:
(require 'compile)
(require 'cl-lib)
(require 'haskell-mode)



(defgroup zombie-trellys nil
  "Customization options for working with Zombie."
  :prefix 'zombie-trellys-
  :group 'languages)

(defcustom zombie-trellys-command "trellys"
  "The path to the Zombie executable."
  :type '(string)
  :group 'zombie-trellys)

(defcustom zombie-trellys-mode-hook '(zombie-trellys-disable-haskell-modes)
  "The major mode hook for `zombie-trellys-mode'."
  :type 'hook
  :group 'zombie-trellys)



(defun zombie-trellys--compilation-buffer-name-function (_mode)
  "Compute a buffer name for the zombie-trellys-mode compilation buffer."
  "*zombie*")

(defun zombie-trellys-compile-buffer ()
  "Load the current file into Zombie."
  (interactive)
  (let* ((filename (buffer-file-name))
         (dir (file-name-directory filename))
         (file (file-name-nondirectory filename))
         (command (concat zombie-trellys-command " " file))

         ;; Emacs compile config stuff - these are special vars
         (compilation-buffer-name-function
          'zombie-trellys--compilation-buffer-name-function)
         (default-directory dir))
    (compile command)))



(defun zombie-trellys-disable-haskell-modes ()
  "Disable Haskell minor modes that are useless for Zombie."
  (interactive)
  ;; Disable interactive-haskell-mode, which is useless for Zombie
  (when (and (fboundp 'interactive-haskell-mode)
             (boundp 'interactive-haskell-mode)
             interactive-haskell-mode)
    (interactive-haskell-mode -1))
  ;; Disable structured-haskell-mode, which is useless for Zombie
  (when (and (fboundp 'structured-haskell-mode)
             (boundp 'structured-haskell-mode)
             structured-haskell-mode)
    (structured-haskell-mode -1)))


;; Copied from the keywords list in the Zombie parser
(defconst zombie-trellys-keywords
  '("ord" "ordtrans" "join" "pjoin" "smartjoin"
    "smartpjoin" "unfold" "punfold" "rec" "ind"
    "Type" "data" "where" "case" "of" "with"
    "abort" "contra" "let" "in" "prog" "log"
    "axiom" "erased" "termcase" "TRUSTME"
    "injectivity" "if" "then" "else")
  "The keywords to add for Zombie.")


;;;###autoload
(define-derived-mode zombie-trellys-mode haskell-mode "Zombie-Trellys"
  "A major mode for Zombie."
  (add-to-list 'compilation-error-regexp-alist-alist
               '(zombie-trellys-type-error
                 "\\(Type Error:\\)\\s-+\\(\\([^:]+\\):\\([0-9]+\\):\\([0-9]+\\):\\)"
                 3 4 5 nil 2 (1 "compilation-error")))
  (cl-pushnew 'zombie-trellys-type-error
              compilation-error-regexp-alist))

(define-key zombie-trellys-mode-map (kbd "C-c C-l")
  #'zombie-trellys-compile-buffer)

(font-lock-add-keywords 'zombie-trellys-mode
                        `((,(regexp-opt zombie-trellys-keywords 'words)
                           1 haskell-keyword-face)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.trellys$" . zombie-trellys-mode))



(provide 'zombie-trellys-mode)
;;; zombie-trellys-mode.el ends here
