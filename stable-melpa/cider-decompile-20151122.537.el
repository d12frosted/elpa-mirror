;;; cider-decompile.el --- decompilation extension for cider

;; Copyright © 2013 Dmitry Bushenko
;;
;; Author: Dmitry Bushenko
;; URL: http://www.github.com/clojure-emacs/cider-decompile
;; Package-Version: 20151122.537
;; Package-Commit: 5d87035f3c3c14025e8f01c0c53d0ce2c8f56651
;; Version: 0.0.2
;; X-Original-Version: 0.0.1
;; Keywords: languages, clojure, cider
;; Package-Requires: ((cider "0.3.0") (javap-mode "9"))

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

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Provides an `cider-decompile' command.

;;; Installation:

;; Available as a package in marmalade-repo.org and melpa.org.

;; (add-to-list 'package-archives
;;              '("marmalade" . "http://marmalade-repo.org/packages/"))
;;
;; or
;;
;; (add-to-list 'package-archives
;;              '("melpa" . "https://melpa.org/packages/") t)
;;
;; M-x package-install cider-decompile

;;; Usage:

;; M-x cider-decompile

;;; Code:

(require 'cider)
(require 'javap-mode)

(defun cider-decompile (fn-name-raw)
  "Decompiles specified function into the java bytecode.
Opens buffer *decompiled* with the result of decompilation,
enables javap-mode on it.  Input: FN-NAME in format 'my-namespace$my-function'.
All dashes will be replaced with underscores, the dollar symbol will be
escaped."
  (let* ((fn-name (replace-regexp-in-string "\?" "_QMARK_"
					    (replace-regexp-in-string "\!" "_BANG_" fn-name-raw)))
	 (buf-name "*decompiled*")
	 (class-name
	  (replace-regexp-in-string "-" "_"
				    (replace-regexp-in-string "\\$" "\\\\$" fn-name)))
	 (cmd
	  (concat "javap -constants -v -c -classpath `lein classpath` "
		  class-name))
	 (decompiled (shell-command-to-string cmd)))
    (with-current-buffer (get-buffer-create buf-name)
      (point-min)
      (insert decompiled)
      (javap-mode))
    (display-buffer buf-name)))

(defun cider-decompile-func* (fn-name)
  (cider-decompile (concat (cider-current-ns) "$" fn-name)))

;;;###autoload
(defun cider-decompile-func ()
  "Asks for the func name (FN-NAME) in the current namespace.and decompiles."
  (interactive)
  (let ((fname (read-string "Function: " (thing-at-point 'symbol))))
    (cider-decompile-func* fname)))

;;;###autoload
(defun cider-decompile-ns-func (fn-name)
  "Asks for the func name (FN-NAME) in a specific namespace and decompiles it.
The FN-NAME should be prefixed with the namespace."
  (interactive "sNamespace/function:  ")
  (cider-decompile (concat (replace-regexp-in-string "\\\/" "$" fn-name))))

(provide 'cider-decompile)
;;; cider-decompile.el ends here
