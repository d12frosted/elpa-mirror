;;; jape-mode.el --- An Emacs editing mode mode for GATE's JAPE files

;; Copyright (C) 2005 Ilya Goldin -- http://www.pitt.edu/~goldin
;; Copyright (C) 2014 Ryan Smith -- http://www.github.com/tanzoniteblack

;; Authors: Ryan Smith <rnsmith2@gmail.com>
;;      Ilya Goldin
;; URL: http://github.com/tanzoniteblack/jape-mode
;; Package-Version: 20140903.1506
;; Package-Commit: 27dbebc4de93eb887038fda7a11671349efe8dbb
;; Keywords: languages jape gate
;; Version: 0.2.1

;;; Commentary:

;; Provides basic font-lock for the JAPE (Java Annotation Pattern Engine)
;; https://gate.ac.uk/sale/tao/splitch8.html#x12-2150008 language used with GATE
;; (General Architecture for Text Engineering) https://gate.ac.uk/ created by
;; the University of Sheffield.

;; Originally based on "An Emacs language mode creation tutorial" by
;; Scott Andrew Borton, http://two-wugs.net/emacs/mode-tutorial.html

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of the
;; License, or (at your option) any later version.  If you have
;; received this program together with the GATE software, you may
;; choose to use this program under the whatever license applies to
;; GATE itself.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

;;; Code:
(defvar jape-mode-hook nil)

(defvar jape-mode-map
  (let ((jape-mode-map (make-sparse-keymap)))
    jape-mode-map)
  "Keymap for JAPE major mode")

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.jape\\'" . jape-mode))

(defconst jape-font-lock-keywords
  (list '("\\(Input\\|Phases\\|Macro\\|Options\\|Imports\\):" (1 font-lock-builtin-face))
		;; Input: Foo Bar
		'("\\(Input\\):\\s-+\\(\\(?:\\w+\\s-*\\)+\\)" (1 font-lock-builtin-face) (2 font-lock-type-face))
		;; -->
		'("-->" . font-lock-builtin-face)
		;; Rule: Foo; Phase: Foo; Multiphase: Foo;
		'("\\(Phase\\|Multiphase\\):\\s-+\\(\\w+\\)" (1 font-lock-builtin-face) (2 font-lock-type-face))
		;; Rule: Foo;
		'("\\(Rule\\):\\s-+\\(\\w+\\)" (1 font-lock-builtin-face) (2 font-lock-function-name-face))
		;; Priority: 100
		'("\\(Priority\\):\\s-+\\([0-9]+\\)" (1 font-lock-builtin-face) (2 font-lock-keyword-face))
		;; {Number}:number
        '("\\(:\\w+\\)" . font-lock-variable-name-face)
        ;; font lock operators as functions, i.e. + * ? == !=, etc.
        '("\\(|\\|\\(?:=\\|!\\)=\\|?\\|+\\|*\\)" . font-lock-function-name-face))
  "Default highlighting expressions for JAPE mode.")

(defvar jape-mode-syntax-table
  (let ((jape-mode-syntax-table (make-syntax-table)))
	;; Comment styles are same as C++
    (modify-syntax-entry ?/ ". 124b" jape-mode-syntax-table)
    (modify-syntax-entry ?* ". 23" jape-mode-syntax-table)
    (modify-syntax-entry ?\n "> b" jape-mode-syntax-table)
    jape-mode-syntax-table)
  "Syntax table for jape-mode.")

(defalias 'jape-parent-mode
  (if (fboundp 'prog-mode)
	  'prog-mode
	'fundamental-mode))

;;;###autoload
(define-derived-mode jape-mode jape-parent-mode "JAPE"
  "Major mode for editting GATE's JAPE files.

\\{jape-mode-map}"
  (set-syntax-table jape-mode-syntax-table)
  (set (make-local-variable 'indent-tabs-mode) nil)
  (set (make-local-variable 'comment-start) "//")
  (use-local-map jape-mode-map)
  (setq font-lock-defaults '(jape-font-lock-keywords)))

(provide 'jape-mode)
;;; jape-mode.el ends here
