;;; pixie-mode.el --- Major mode for Pixie-lang

;; Copyright © 2014 John Walker
;;
;; Author: John Walker <john.lou.walker@gmail.com>
;; URL: https://github.com/johnwalker/pixie-mode
;; Package-Version: 20180626.541
;; Package-Commit: a40c2632cfbe948852a5cdcfd44e6a65db11834d
;; Version: 0.1.0
;; Package-Requires: ((clojure-mode "3.0.1") (inf-clojure "1.0.0"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; A major mode for Pixie-lang.

;;; Code:

(require 'clojure-mode)
(require 'inf-clojure)

(unless (fboundp 'setq-local)
  (defmacro setq-local (var val)
    `(set (make-local-variable ',var) ,val)))

(defcustom pixie-inf-lisp-program "pixie-vm"
  "The program used to start an inferior pixie in Inferior Clojure mode."
  :type 'string
  :group 'pixie
  :safe 'stringp)

(defcustom pixie-inf-lisp-load-command "(load-file \"%s\")"
  "The format string for building an expression that loads a pixie file."
  :type 'string
  :group 'pixie
  :safe 'stringp)

;; I'm not of aware of a way to share variables over small groups of
;; buffers, especially ones that aren't in pixie-mode. Is there a
;; better approach than defadvice with a let?
(defadvice inf-clojure-show-var-documentation (around advice-pixie activate)
  (if (derived-mode-p 'pixie-mode)
      (let ((inf-clojure-var-doc-command "(pixie.stdlib/doc %s)\n"))
	ad-do-it)
    ad-do-it))

;;;###autoload
(define-derived-mode pixie-mode clojure-mode "Pixie"
  "Major mode for editing Pixie code.
\\{pixie-mode-map}"
  (setq-local inf-clojure-load-command pixie-inf-lisp-load-command)
  (setq-local inf-clojure-generic-cmd pixie-inf-lisp-program))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pxi\\'" . pixie-mode))

(provide 'pixie-mode)
;;; pixie-mode.el ends here
