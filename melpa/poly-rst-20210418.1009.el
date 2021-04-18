;;; poly-rst.el --- poly-rst-mode polymode -*- lexical-binding: t -*-
;;
;; Author: Gustaf Waldemarson, Vitalie Spinu
;; Copyright (C) 2018 Gustaf Waldemarson, Vitalie Spinu
;; Version: 0.2.2
;; Package-Version: 20210418.1009
;; Package-Commit: e71f2ae6a00683cdb8006f953e5db0673043e144
;; Package-Requires: ((emacs "25") (polymode "0.2.2"))
;; URL: https://github.com/polymode/poly-rst
;; Keywords: languages, multi-modes
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This file is *NOT* part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; Polymode for working with files using ReStructured Text (ReST or rst) markup
;; syntax.  This allows the user to work in regions marked with code using the
;; appropriate Emacs major mode.
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'polymode)
(require 'rst)

(define-obsolete-variable-alias 'pm-host/rst 'poly-rst-hostmode "v0.2")
(define-obsolete-variable-alias 'pm-inner/rst 'poly-rst-innermode "v0.2")

(defvar poly-rst-code-tags '("code" "code-block" "sourcecode" "highlight")
  "List of rst code block tags.")

(defvar poly-rst-head-start-regexp (format "\.\. +%s::[^:]" (regexp-opt poly-rst-code-tags))
  "Regexp to match start of the header.")

(defun poly-rst-head-matcher (ahead)
  "ReST heads end with an empty line.
Find the ReST header that are AHEAD or -AHEAD number of headers
away from the current location."
  (when (re-search-forward poly-rst-head-start-regexp nil t ahead)
    (cons (match-beginning 0)
          (if (re-search-forward "^[ \t]*\n" nil t)
              (match-end 0)
            (point-max)))))

(define-hostmode poly-rst-hostmode nil
  "ReSTructured text hostmode."
  :mode 'rst-mode)

(define-auto-innermode poly-rst-innermode nil
  "ReSTructured text innermode."
  :head-matcher #'poly-rst-head-matcher
  :tail-matcher #'pm-same-indent-tail-matcher
  :mode 'host
  :head-mode 'host
  :indent-offset 4
  :mode-matcher (cons "\.\. .*:: +\\(.+\\)" 1))

;;;###autoload (autoload #'poly-rst-mode "poly-rst")
(define-polymode poly-rst-mode
  :hostmode 'poly-rst-hostmode
  :innermodes '(poly-rst-innermode))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.re?st\\'" . poly-rst-mode))

(provide 'poly-rst)
;;; poly-rst.el ends here
