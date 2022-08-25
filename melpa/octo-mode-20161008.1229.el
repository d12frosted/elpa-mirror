;;; octo-mode.el --- Major mode for Octo assembly language

;; Copyright (C) 2016 John Olsson

;; Author: John Olsson <john@cryon.se>
;; Maintainer: John Olsson <john@cryon.se>
;; URL: https://github.com/cryon/octo-mode
;; Package-Version: 20161008.1229
;; Package-Commit: 4b2ed4a61674f73a6ccd390b5ae123474bd0c977
;; Created: 4th October 2016
;; Version: 0.1.0
;; Package-Requires: ((emacs "24"))
;; Keywords: languages

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Major mode for editing Octo source code. A high level assembly
;; language for the Chip8 virtual machine.
;; See: https://github.com/JohnEarnest/Octo
;;
;; The mode could most likely have benefited from deriving asm-mode
;; as Octo is an assembly language. However part of the reasoning
;; behind creating this mode was learning more about Emacs'
;; internals. The language is simple enough to allow the mode to be
;; quite compact anyways.
;;
;; Much inspiration was taken from yaml-mode so there might be
;; similarities in the source structure and naming choices.

;;; Installation:

;; The easiest way to install octo-mode is from melpa.
;; Assuming MELPA is added to your archive list you can list the
;; available packages by typing M-x list-packages, look for
;; octo-mode, mark it for installation by typing 'i' and then execute
;; (install) by typing 'x'. Or install it directly with M-x
;; package-install RET octo-mode.
;;
;; If you want to install it manually, just drop this file anywhere
;; in your `load-path'. Be default octo-mode associates itself with
;; the *.8o file ending. You can enable the mode manually by M-x
;; octo-mode RET.

;;; Code:

;; User definable variables

(defgroup octo nil
  "Support for Octo assembly language."
  :group 'languages
  :prefix "octo-")

(defcustom octo-mode-hook nil
  "Hook run by `octo-mode'."
  :type 'hook
  :group 'octo)

(defcustom octo-indent-offset 2
  "Amount of offset per level of indentation."
  :type 'integer
  :group 'octo)

(defcustom octo-indentation-hint-search-lines 50
  "Maximum number of lines to search for indentation hint."
  :type 'integer
  :group 'octo)

;; Constants

(defconst octo-label-regexp
  ":\\s-+\\(\\sw+\\)"
  "Regexp matching Octo labels")

(defconst octo-constant-name-regexp
  ":const\\s-+\\(\\sw+\\)"
  "Regexp maching name of Octo constant")

(defconst octo-directives-regexp
  (regexp-opt '(":" ":const" ":alias" ":unpack" ":next" ":org" ":breakpoint")
              'words)
  "Regexp maching Octo directives")

(defconst octo-statements-regexp
  (regexp-opt '("clear" "bcd" "save" "load" "sprite" "jump"
                "jump0" "return" "delay" "buzzer" ";")
              'words)
  "Regexp matching Octo statements")

(defconst octo-assignments-regexp
  (regexp-opt '(":=" "+=" "-=" "|=" "&=" "^=" ">>=" "<<=")
              'symbols)
  "Regexp maching Octo assignments")

(defconst octo-conditionals-regexp
  (concat
   (regexp-opt '("==" "!=") 'symbols)
   "\\|"
   (regexp-opt '("key" "-key") 'words))
  "Regexp matching Octo conditionals")

(defconst octo-psuedo-ops-regexp
  (regexp-opt '("<" ">" "<=" ">=") 'symbols)
  "Regexp matching Octo psuedo ops")

(defconst octo-control-statements-regexp
  (regexp-opt '("if" "then" "else" "begin" "end" "loop" "again" "while")
              'words)
  "Regexp matching Octo control statements")

(defconst octo-registers-regexp
  (regexp-opt '("v0" "v1" "v2" "v3"
                "v4" "v5" "v6" "v7"
                "v8" "v9" "va" "vb"
                "vc" "vd" "ve" "vf"
                "i")
              'words)
  "Regexp matching Octo registers")

(defconst octo-special-aliases-regexp
  ":alias\\s-+\\(compare-temp\\)"
  "Regexp matching Octo special aliases")

(defconst octo-breakpoint-name-regexp
  ":breakpoint\\s-+\\(\\sw+\\)"
  "Regexp matching Octo breakpoint name")

(defconst octo-super-chip-statements-regexp
  (regexp-opt '("hires" "lores" "scroll-down" "scroll-left"
                "scroll-right" "bighex" "exit" "saveflags"
                "loadflags")
              'words)
  "Regexp matching SuperChip statements")

(defconst octo-xo-chip-statements-regexp
  (regexp-opt '("long" "plane" "audio" "scroll-up") 'words)
  "Regexp matching XO-Chip statements")

(defconst octo-block-start-regexp
  "\\s-*\\(\\(:\\s-+\\sw*\\>\\)\\|loop\\|else\\|\\(.*begin\\s-*$\\)\\)"
  "Regexp matching block start")

(defconst octo-block-end-regexp
  "\\s-*\\(again\\|end\\)"
  "Regexp matching block end")

;; Custom faces

(defface octo-super-chip-statements-face
  '((t (:inherit font-lock-keyword-face)))
  "Face used to highlight SuperChip statements"
  :group 'octo)

(defface octo-xo-chip-statements-face
  '((t (:inherit font-lock-keyword-face)))
  "Face used to highlight XO-Chip statements"
  :group 'octo)

;; Mode setup

(defvar octo-mode-syntax-table nil
  "Syntax table used on `octo-mode' buffers")

(unless octo-mode-syntax-table
  (setq octo-mode-syntax-table (make-syntax-table))

  ;; # Comments rest of line
  (modify-syntax-entry ?#  "<" octo-mode-syntax-table)
  (modify-syntax-entry ?\n ">" octo-mode-syntax-table)

  ;; : - _ ; Is part of a word
  (modify-syntax-entry ?:  "w" octo-mode-syntax-table)
  (modify-syntax-entry ?-  "w" octo-mode-syntax-table)
  (modify-syntax-entry ?_  "w" octo-mode-syntax-table)
  (modify-syntax-entry ?\; "w" octo-mode-syntax-table))

;; Font-lock support

(defvar octo-highlights
  `((,octo-label-regexp                 . (1 font-lock-function-name-face))
    (,octo-constant-name-regexp         . (1 font-lock-constant-face))
    (,octo-directives-regexp            . (1 font-lock-preprocessor-face))
    (,octo-statements-regexp            . font-lock-keyword-face)
    (,octo-assignments-regexp           . font-lock-constant-face)
    (,octo-conditionals-regexp          . font-lock-builtin-face)
    (,octo-psuedo-ops-regexp            . font-lock-keyword-face)
    (,octo-control-statements-regexp    . font-lock-keyword-face)
    (,octo-registers-regexp             . font-lock-variable-face)
    (,octo-special-aliases-regexp       . (1 font-lock-preprocessor-face))
    (,octo-super-chip-statements-regexp . 'octo-super-chip-statements-face)
    (,octo-xo-chip-statements-regexp    . 'octo-xo-chip-statements-face)
    (,octo-breakpoint-name-regexp       . (1 font-lock-function-name-face)))
  "Expressions to highlight in `octo-mode'")

;; Indentation

(defun octo--current-line-empty-p ()
  "Checks whether the current line is empty or not"
  (save-excursion
    (beginning-of-line)
    (looking-at "\\s-*$")))

(defun octo--previous-line-indentation ()
  "Indentation of previous non-empty line"
  (save-excursion
    (forward-line -1)
    (while (and (octo--current-line-empty-p) (not (bobp)))
      (forward-line -1))
    (current-indentation)))

(defun octo--backwards-indentation-hint (max-iter)
  "Returns indentation hint based on previous `max-iter' lines"
  (save-excursion
    (let ((iter octo-indentation-hint-search-lines)
          (hint 0))
      (while (> iter 0)
        (forward-line -1)
        (if (looking-at octo-block-start-regexp)
            (progn
              (setq hint (+ (current-indentation) octo-indent-offset))
              (setq iter 0)))
        (if (looking-at octo-block-end-regexp)
            (progn
              (setq hint (current-indentation))
              (setq iter 0)))
        (setq iter (- iter 1)))
      hint)))

(defun octo-indent-line ()
  "Indent current line as Octo code"
  (interactive)
  (save-excursion
    (unless (octo--current-line-empty-p)
      (beginning-of-line)
      (indent-line-to
       (let ((unindented-label (concat "\\s-*" octo-label-regexp))
             (unindented-else "\\s-*else"))
         (max 0
              (if (or (bobp) (looking-at unindented-label)) 0
                (if (or
                     (looking-at octo-block-end-regexp)
                     (looking-at unindented-else))
                    (- (octo--previous-line-indentation) octo-indent-offset)
                  (octo--backwards-indentation-hint
                   octo-indentation-hint-search-lines)))))))))

;;;###autoload
(define-derived-mode octo-mode prog-mode "Octo"
  "Major mode for editing Octo assembly language.

\\{octo-mode-map}"
  :syntax-table octo-mode-syntax-table
  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'indent-line-function) 'octo-indent-line)
  (set (make-local-variable 'indent-tabs-mode) nil)

  (setq font-lock-defaults '(octo-highlights)))

;;;###autoload
(add-to-list
 'auto-mode-alist
 '("\\.8o\\'" . octo-mode))

(provide 'octo-mode)

;; Local Variables:
;; coding: utf-8
;; End:

;;; octo-mode.el ends here
