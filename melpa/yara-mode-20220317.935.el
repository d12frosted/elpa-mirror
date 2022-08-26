;;; yara-mode.el --- Major mode for editing yara rule file

;; Copyright 2012 Binjo
;;
;; Author: binjo.cn@gmail.com
;; Version: $Id: yara-mode.el,v 0.0 2012/10/16 14:11:51 binjo Exp $
;; Package-Version: 20220317.935
;; Package-Commit: 4c959b300ce52665c92e04e524dda5ed051c34f3
;; Keywords: yara
;; X-URL: not distributed yet
;; Package-Requires: ((emacs "24"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;;

;;; History:

;; 2012/10/16, init
;; 2016/08/19, 1st pull request from @syohex

;; Put this file into your load-path and the following into your ~/.emacs:
;;   (require 'yara-mode)

;;; Code:

(require 'smie)
(require 'cc-langs)


(defvar yara-mode-hook nil)
(defvar yara-mode-map
  (make-keymap)
  "Keymap for YARA major mode.")

(defgroup yara-mode nil
  "Support for Yara code.")

(defcustom yara-indent-offset 4
  "Indent Yara code by this number of spaces."
  :type 'integer
  :group 'yara-mode
  :safe #'integerp)

(defcustom yara-indent-section 2
  "Indent the sections of rule in Yara code by this number of spaces."
  :type 'integer
  :group 'yara-mode
  :safe #'integerp)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ya?r" . yara-mode))

(defun yara-comment-dwim (arg)
  "Comment or uncomment current line or region in a smart way.
For ARG detail, see `comment-dwim'."
  (interactive "*P")
  (require 'newcomment)
  (let ((comment-start "//")
        (comment-start-skip "//")
        (comment-end ""))
    (comment-dwim arg)))

(defvar yara-smie-grammar nil
  "Yara BNF grammer only for indentation with `smie'.")

(setq yara-smie-grammar
      (smie-prec2->grammar
       (smie-bnf->prec2
        `((stmts (stmts ";" stmts) (stmt))
          (stmt ("import" modulepath)
                ("include" filepath)
                ("rule" ruledecl "{" sections "}"))
          (ruledecl (id)
                    (id ":#" tags "#:"))
          (tags (tags ";" tags) (id))
          (sections (sections "meta" ":*" metalist)
                    (sections "strings" ":*" stringdefs)
                    (sections "condition" ":*" condexpr))
          (metalist)
          (stringdefs (stringdefs ";" stringdefs) (stringdef))
          (stringdef ($id "=" hextex)
                     ($id "=" "{" ":." bytes "}"))
          (condexpr (condexpr "and" condexpr)
                    (condexpr "or" condexpr)
                    ("(" condexpr ")")
                    ("for" qualvar "in" set ":" condexpr))
          (modulepath)
          (filepath)
          (id)
          ($id)
          (hextex)
          (bytes)
          (qualvar)
          (set))
        '((assoc "rule"))
        '((assoc "="))
        '((assoc ":*") (assoc ";"))
        '((assoc ":#") (assoc ","))
        '((assoc "and") (assoc "or") (assoc ":")))))

(defun yara-smie-rules (kind token)
  "Perform indentation of KIND on TOKEN using the `smie' engine."
  (let ((offset (pcase (cons kind token)
                  ('(:elem . args) 0)
                  ('(:elem . basic) yara-indent-offset)
                  ('(:before . "#:") (smie-rule-parent))
                  (`(:before . ,(or "{" "("))
                   (cond ((smie-rule-parent-p ":" ":#")
                          (smie-rule-parent (- yara-indent-offset)))
                         (t (smie-rule-parent))))
                  (`(:before . ,(or ":" ":#"))
                   (cond ((smie-rule-parent-p "rule" "for")
                          (smie-rule-separator kind))))
                  (`(:before . ,(or "condition" "strings" "meta"))
                   (smie-rule-parent yara-indent-section))
                  ('(:after . "=") yara-indent-offset)
                  ('(:after . ":.") (smie-rule-parent yara-indent-offset))
                  ('(:after . ":*") yara-indent-offset)
                  (`(,_ . ";") (smie-rule-separator kind))
                  ('(:list-intro . ":") t)
                  ('(:list-intro . ":*") t)
                  ('(:list-intro . ":#") t)
                  ('(:list-intro . ":.") t))))
    ;; (message "%s '%s' -> %s" kind token offset)
    offset
    ))

(defun yara-smie-forward-token ()
  (let ((token
         (or (yara-smie--forward-token-when
              'yara-smie--looking-at-stmt-end
              'append ";")
             (yara-smie--forward-token-when
              'yara-smie--looking-at-rule-tags-end
              'append "#:")
             (yara-smie--forward-token-when
              'yara-smie--looking-at-rule-tags-begin
              'substitute ":#" t)
             (yara-smie--forward-token-when
              'yara-smie--looking-at-bytes-block-begin
              'append ":.")
             (yara-smie--forward-token-when
              'yara-smie--looking-at-sec-label-end
              'substitute ":*" t)
             (smie-default-forward-token))))
    ;; (message "    >> %s" token)
    token))

(defun yara-smie-backward-token ()
  (let ((token
         (or (yara-smie--backward-token-when
              'yara-smie--looking-at-stmt-end
              'append ";")
             (yara-smie--backward-token-when
              'yara-smie--looking-at-rule-tags-end
              'append "#:")
             (yara-smie--backward-token-when
              'yara-smie--looking-at-rule-tags-begin
              'substitute ":#")
             (yara-smie--backward-token-when
              'yara-smie--looking-at-bytes-block-begin
              'append ":.")
             (yara-smie--backward-token-when
              'yara-smie--looking-at-sec-label-end
              'substitute ":*")
             (smie-default-backward-token))))
    ;; (message "        << %s" token)
    token))

(defun yara-smie--forward-token-when (fn-match action token &rest args)
  (cond
   ((equal action 'append)
    (when (yara--funcall fn-match args)
      (progn (forward-comment (point-max))
             token)))
   ((equal action 'substitute)
    (when (yara--funcall fn-match args)
      (progn (smie-default-forward-token)
             token)))))

(defun yara-smie--backward-token-when (fn-match action token &rest args)
  (cond
   ((equal action 'append)
    (when (and (not (yara--funcall fn-match args))
               (save-excursion
                 (forward-comment (- (point)))
                 (yara--funcall fn-match args)))
      (forward-comment (- (point)))
      token))
   ((equal action 'substitute)
    (when (progn (forward-comment (- (point)))
                 (yara--funcall fn-match args))
      (smie-default-backward-token)
      token))))

(defun yara--funcall (fn args)
  (if args (funcall fn args)
    (funcall fn)))

(defconst yara-smie--re-symbol-operator
  (rx (or "=" "+" "-" "*" "\\" "%" "."
          "~" "<<" ">>" "&" "^" "|"
          "<" ">=" ">" "<=" "==" "!=")))

(defconst yara-smie--re-literal-operator
  (rx (or "and" "or" "not" "none" "at" "in" "of"
          "contains" "icontains" "startswith" "istartswith"
          "endswith" "iendswith" "matches" "iequals" "defined")))

(defconst yara-smie--assoc-left-operator
  (rx (or (or "{" "(" "," ":")
          (eval `(: ,@yara-smie--re-symbol-operator))
          (: (eval `(: ,@yara-smie--re-literal-operator))
             symbol-end))))

(defconst yara-smie--assoc-right-operator
  (rx (or (or "{" "(" "," ":")
          (eval `(: ,@yara-smie--re-symbol-operator))
          (: symbol-start
             (eval `(: ,@yara-smie--re-literal-operator)))
          (: symbol-start
             (or "rule" "import" "include" "for")))))

(defun yara-smie--looking-at-stmt-end ()
  (and (not (save-excursion
              (beginning-of-line)
              (looking-at-p "\\s-*$")))
       (looking-at-p "\\s-*$")
       (not (looking-back yara-smie--assoc-right-operator (- (point) 10)))
       (save-excursion
         (forward-comment (point-max))
         (not (looking-at-p yara-smie--assoc-left-operator)))))

(defun yara-smie--looking-at-bytes-block-begin ()
  (and (looking-back "{" (- (point) 1))
       (save-excursion
         (backward-char)
         (forward-comment (- (point)))
         (looking-back "[^=]=" (- (point) 2)))))

(defun yara-smie--looking-at-sec-label-end (&optional is-forward)
  (and (if is-forward
           (looking-at ":")
         (looking-back ":" (- (point) 1)))
       (save-excursion
         (unless is-forward (backward-char))
         (looking-back "\\(strings\\|condition\\|meta\\)" (- (point) 9)))))

(defun yara-smie--looking-at-rule-decl-begin ()
  (and (looking-back "\\_<rule" (- (point) 5))))

(defun yara-smie--looking-at-rule-tags-end ()
  (and (looking-back "[[:alnum:]_]" (- (point) 1))
       (save-excursion
         (forward-comment (point-max))
         (and (looking-at-p "{")
              (progn (yara-smie--skip-tags-backward)
                     (yara-smie--looking-at-rule-tags-begin t))))))

(defun yara-smie--looking-at-rule-tags-begin (&optional is-forward)
  (and (if is-forward
           (looking-at-p ":")
         (looking-back ":" (- (point) 1)))
       (save-excursion
         (unless is-forward (backward-char))
         (yara-smie--looking-at-rule-id-end))))

(defun yara-smie--looking-at-rule-id-end ()
  (save-excursion
    (forward-comment (- (point)))
    (skip-syntax-backward "w_")
    (forward-comment (- (point)))
    (looking-back "\\_<rule" (- (point) 5))))

(defun yara-smie--skip-tags-backward ()
  (while (progn (forward-comment (- (point)))
                (not (= (skip-syntax-backward "w_ ") 0))))
  (backward-char))

(defvar yara-font-lock-keywords
  `(("^\\_<rule[\s\t]+\\([^\\$\s\t].*\\)\\_>"
     . (1 font-lock-function-name-face))
    ("^[\s\t]+\\([^\\$\s\t].*?\\)[\s\t]*=[\s\t]*"
     . (1 font-lock-constant-face))
    ("\\_<\\(\\$[^\s\t].*?\\)\\_>"
     . (1 font-lock-variable-name-face))
    ("\\([{/].*[}/]\\)"
     . (1 font-lock-string-face))
    ("\\<\\(0x[[:xdigit:]]*\\)\\>"
     . (1 font-lock-constant-face))
    (,(regexp-opt
       '("condition" "meta" "strings")
       'symbols)
     . font-lock-warning-face)
    (,(regexp-opt
       '("all" "and" "any" "ascii" "at" "base64" "base64wide" "contains" "icontains"
         "entrypoint" "false" "filesize" "fullword" "for" "global" "in"
         "import" "include"
         "matches" "nocase" "not" "none" "or" "of"
         "private" "rule" "them" "true"
         "wide" "xor"
         "startswith" "istartswith" "endswith" "iendswith" "iequals" "defined")
       'symbols)
     . font-lock-keyword-face)
    (,(regexp-opt
       '("int8" "int16" "int32" "int8be" "int16be" "int32be"
         "uint8" "uint16" "uint32" "uint8be" "uint16be" "uint32be"
         "math.abs" "math.count" "math.percentage" "math.mode")
       'symbols)
     . font-lock-function-name-face))
  "Keywords to highlight in yara-mode.")

(defvar yara-mode-syntax-table
  (funcall (c-lang-const c-make-mode-syntax-table c))
  "Syntax table for yara-mode.")

;;;###autoload
(define-derived-mode yara-mode prog-mode "Yara"
  "Major Mode for editing yara rule files."
  (define-key yara-mode-map [remap comment-dwim] 'yara-comment-dwim)
  (setq comment-start "//"
        comment-start-skip "//"
        comment-end "")
  (smie-setup yara-smie-grammar #'yara-smie-rules
              :forward-token #'yara-smie-forward-token
              :backward-token #'yara-smie-backward-token)
  (setq font-lock-defaults '(yara-font-lock-keywords nil t))
  (setq tab-width 4))

(provide 'yara-mode)

;;; yara-mode.el ends here
