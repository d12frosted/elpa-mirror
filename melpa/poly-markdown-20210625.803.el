;;; poly-markdown.el --- Polymode for markdown-mode -*- lexical-binding: t -*-
;;
;; Author: Vitalie Spinu
;; Maintainer: Vitalie Spinu
;; Copyright (C) 2018
;; Version: 0.2.2
;; Package-Version: 20210625.803
;; Package-Commit: e79d811d78da668556a694bb840bea3515b4c6f8
;; Package-Requires: ((emacs "25") (polymode "0.2.2") (markdown-mode "2.3"))
;; URL: https://github.com/polymode/poly-markdown
;; Keywords: emacs
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
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'polymode)
(require 'markdown-mode)

;; Declarations
(defvar markdown-enable-math)

(define-obsolete-variable-alias 'pm-host/markdown 'poly-markdown-hostmode "v0.2")
(define-obsolete-variable-alias 'pm-inner/markdown-yaml-metadata 'poly-markdown-yaml-metadata-innermode "v0.2")
(define-obsolete-variable-alias 'pm-inner/markdown-fenced-code 'poly-markdown-fenced-code-innermode "v0.2")
(define-obsolete-variable-alias 'pm-inner/markdown-inline-code 'poly-markdown-inline-code-innermode "v0.2")
(define-obsolete-variable-alias 'pm-inner/markdown-displayed-math 'poly-markdown-displayed-math-innermode "v0.2")
(define-obsolete-variable-alias 'pm-inner/markdown-inline-math 'poly-markdown-inline-math-innermode "v0.2")
(define-obsolete-variable-alias 'pm-poly/markdown 'poly-markdown-polymode "v0.2")

(define-hostmode poly-markdown-hostmode
  :mode 'markdown-mode
  :init-functions '(poly-markdown-remove-markdown-hooks))

(define-innermode poly-markdown-root-innermode
  :mode nil
  :fallback-mode 'host
  :head-mode 'host
  :tail-mode 'host)

(define-innermode poly-markdown-yaml-metadata-innermode poly-markdown-root-innermode
  :mode 'yaml-mode
  :head-matcher (pm-make-text-property-matcher 'markdown-yaml-metadata-begin :inc-end)
  :tail-matcher (pm-make-text-property-matcher 'markdown-yaml-metadata-end))

;; allow extra . before language name https://github.com/polymode/polymode/issues/296
(define-auto-innermode poly-markdown-fenced-code-innermode poly-markdown-root-innermode
  :head-matcher (cons "^[ \t]*\\(```[ \t]*{?[[:alpha:].].*\n\\)" 1)
  :tail-matcher (cons "^[ \t]*\\(```\\)[ \t]*$" 1)
  :mode-matcher (cons "```[ \t]*{?\\.?\\(?:lang *= *\\)?\\([^ \t\n;=,}]+\\)" 1))

;; Intended to be inherited from by more specialized innermodes.
;; FIXME: Some font-lock issues on deletion.
;; TOTHINK: Can be added to the default configuration for the sake of the
;; default fallback, but it's problematic given that inline code blocks often
;; have arbitrary non-code or language specific content.
(define-innermode poly-markdown-inline-code-innermode poly-markdown-root-innermode
  :head-matcher (cons "[^`]\\(`\\)[[:alpha:]+-&({*[]" 1)
  :tail-matcher (cons "[^`]\\(`\\)[^`]" 1)
  ;; :mode-matcher (cons "`[ \t]*{?\\(?:lang *= *\\)?\\([[:alpha:]+-]+\\)" 1)
  :allow-nested nil)

(defun poly-markdown-displayed-math-head-matcher (count)
  (when markdown-enable-math
    (when (re-search-forward "\\\\\\[\\|^[ \t]*\\(\\$\\$\\)." nil t count)
      (if (match-beginning 1)
          (cons (match-beginning 1) (match-end 1))
        (cons (match-beginning 0) (match-end 0))))))

(defun poly-markdown-displayed-math-tail-matcher (_count)
  (when markdown-enable-math
    (if (match-beginning 1)
        ;; head matched an $$..$$ block
        (when (re-search-forward "[^$]\\(\\$\\$\\)[^$[:alnum:]]" nil t)
          (cons (match-beginning 1) (match-end 1)))
      ;; head matched an \[..\] block
      (when (re-search-forward "\\\\\\]" nil t)
        (cons (match-beginning 0) (match-end 0))))))

(define-innermode poly-markdown-displayed-math-innermode poly-markdown-root-innermode
  "Displayed math $$..$$ innermode.
Tail must be flowed by a new line but head need not (a space or
comment character would do)."
  :mode 'latex-mode
  :head-matcher #'poly-markdown-displayed-math-head-matcher
  :tail-matcher #'poly-markdown-displayed-math-tail-matcher
  :allow-nested nil)

(defun poly-markdown-inline-math-head-matcher (count)
  (when markdown-enable-math
    (when (re-search-forward "\\\\(\\|[ \t\n]\\(\\$\\)[^ $\t[:digit:]]" nil t count)
      (if (match-beginning 1)
          (cons (match-beginning 1) (match-end 1))
        (cons (match-beginning 0) (match-end 0))))))

(defun poly-markdown-inline-math-tail-matcher (_count)
  (when markdown-enable-math
    (if (match-beginning 1)
        ;; head matched an $..$ block
        (when (re-search-forward "[^ $\\\t]\\(\\$\\)[^$[:alnum:]]" nil t)
          (cons (match-beginning 1) (match-end 1)))
      ;; head matched an \(..\) block
      (when (re-search-forward "\\\\)" nil t)
        (cons (match-beginning 0) (match-end 0))))))

(define-innermode poly-markdown-inline-math-innermode poly-markdown-root-innermode
  "Inline math $..$ block.
First $ must be preceded by a white-space character and followed
by a non-whitespace/digit character. The closing $ must be
preceded by a non-whitespace and not followed by an alphanumeric
character."
  :mode 'latex-mode
  :head-matcher #'poly-markdown-inline-math-head-matcher
  :tail-matcher #'poly-markdown-inline-math-tail-matcher
  :allow-nested nil)

;;;###autoload  (autoload 'poly-markdown-mode "poly-markdown")
(define-polymode poly-markdown-mode
  :hostmode 'poly-markdown-hostmode
  :innermodes '(poly-markdown-fenced-code-innermode
                ;; poly-markdown-inline-code-innermode
                poly-markdown-displayed-math-innermode
                poly-markdown-inline-math-innermode
                poly-markdown-yaml-metadata-innermode))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.md\\'" . poly-markdown-mode))

;;; FIXES:
(defun poly-markdown-remove-markdown-hooks (_)
  ;; get rid of aggressive hooks (VS[02-09-2018]: probably no longer necessary)
  (remove-hook 'window-configuration-change-hook 'markdown-fontify-buffer-wiki-links t)
  (remove-hook 'after-change-functions 'markdown-check-change-for-wiki-link t))

;;; Polymode for GitHub Flavored Markdown
(define-hostmode poly-gfm-hostmode poly-markdown-hostmode
  :mode 'gfm-mode)

;;;###autoload  (autoload 'poly-gfm-mode "poly-markdown")
(define-polymode poly-gfm-mode poly-markdown-mode
  :hostmode 'poly-gfm-hostmode)

(provide 'poly-markdown)

;;; poly-markdown.el ends here
