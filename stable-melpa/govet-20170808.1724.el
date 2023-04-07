;;; govet.el --- linter/problem finder for the Go source code

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; URL: https://godoc.org/golang.org/x/tools/cmd/vet

;;; Commentary:

;; To install govet.el, add the following lines to your .emacs file:
;;   (add-to-list 'load-path "PATH CONTAINING govet.el" t)
;;   (require 'govet)
;;
;; After this, type M-x govet on Go source code.
;;
;; Usage:
;;   C-x `
;;     Jump directly to the line in your code which caused the first message.
;;
;;   For more usage, see Compilation-Mode:
;;     http://www.gnu.org/software/emacs/manual/html_node/emacs/Compilation-Mode.html

;;;; THIS IS BASICALLY ENTIRELY COPIED AND SLIGHTLY MODIFIED FROM THE GOLINT EMACS MODE
;;;; https://github.com/golang/lint/tree/master/misc/emacs

;;; Code:
(require 'compile)

(defvar govet-setup-hook nil)

(defun govet-process-setup ()
  "Setup compilation variables and buffer for `govet'."
  (run-hooks 'govet-setup-hook))

(define-compilation-mode govet-mode "govet"
  "Govet is a veter for Go source code."
  (set (make-local-variable 'compilation-scroll-output) nil)
  (set (make-local-variable 'compilation-disable-input) t)
  (set (make-local-variable 'compilation-process-setup-function)
       'govet-process-setup)
  )

;;;###autoload
(defun govet ()
  "Run govet on the current file and populate the fix list.
Pressing \\[next-error] will jump directly to the line in your
code which caused the first message."
  (interactive)
  (compilation-start
   (concat "go vet " (mapconcat #'shell-quote-argument
                                (list (expand-file-name buffer-file-name)) " "))
   'govet-mode))

(provide 'govet)

;;; govet.el ends here
