;;; powershell.el --- Mode for editing PowerShell scripts  -*- lexical-binding: t; -*-

;; Copyright (C) 2009, 2010 Frédéric Perrin
;; Copyright (C) 2012 Richard Bielawski rbielaws-at-i1-dot-net
;;               http://www.emacswiki.org/emacs/Rick_Bielawski

;; Author: Frédéric Perrin <frederic (dot) perrin (arobas) resel (dot) fr>
;; URL: http://github.com/jschaf/powershell.el
;; Package-Version: 20220103.925
;; Package-Commit: ce1f0ae0b2e41cd0934a9dfbf2ff016b1d14e9c0
;; Version: 0.3
;; Package-Requires: ((emacs "24"))
;; Keywords: powershell, languages

;; This file is NOT part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Installation:

;; Place powershell.el on your `load-path' by adding the following
;; code to your `user-init-file', which is usually ~/.emacs.d/init.el
;; or ~/.emacs.
;;
;; (add-to-list 'load-path "~/path/to/powershell")
;;

;;; Commentary:

;; powershell.el is a combination of powershell.el by Dino Chiesa
;; <dpchiesa@hotmail.com> and powershell-mode.el by Frédéric Perrin
;; and Richard Bielawski.  Joe Schafer combined the work into a single
;; file.

;;; Frédéric Perrin Comments:
;;
;; The original powershell-mode.el was written from scratch, without
;; using Vivek Sharma's code: it had issues I wanted to correct, but
;; unfortunately there were no licence indication, and Vivek didn't
;; answered my mails.
;;
;;; Rick Bielawski Comments 2012/09/28:
;;
;; On March 31, 2012 Frédéric gave me permission to take over support
;; for powershell-mode.el.  I've added support for multi-line comments
;; and here-strings as well as enhancement/features such as: Functions
;; to quote, unquote and escape a selection, and one to wrap a
;; selection in $().  Meanwhile I hope I didn't break anything.
;;
;; Joe Schafer Comments 2013-06-06:
;;
;; I combined powershell.el and powershell-mode.el.  Since
;; powershell.el was licensed with the new BSD license I combined the
;; two files using the more restrictive license, the GPL.  I also
;; cleaned up the documentation and reorganized some of the code.

;;; Updates:

;; 2012/10/01 Fixed several bugs in highlighting variables and types.
;;            Renamed some variables to be more descriptive.
;; 2012/10/02 Enhanced PowerShell-mode indenting & syntax table.
;;            Fixed dangling parens and re-indented the elisp itself.
;; 2012/10/05 Added eldoc support.  Fixed bug where indent could loop.
;;            See comment below on how to generate powershell-eldoc.el
;; 2013/06/06 Merged powershell.el and powershell-mode.el

;;; Code:

(eval-when-compile (require 'thingatpt))
(require 'shell)
(require 'compile)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ps[dm]?1\\'" . powershell-mode))


;; User Variables

(defgroup powershell nil
  "Customization of PowerShell mode."
  :link '(custom-group-link :tag "Font Lock Faces group" font-lock-faces)
  :group 'languages)

(defcustom powershell-indent 4
  "Amount of horizontal space to indent.
After, for instance, an opening brace"
  :type 'integer
  :group 'powershell)

(defcustom powershell-continuation-indent 2
  "Amount of horizontal space to indent a continuation line."
  :type 'integer
  :group 'powershell)

(defcustom powershell-continued-regexp  ".*\\(|[\\t ]*\\|`\\)$"
  "Regexp matching a continued line.
Ending either with an explicit backtick, or with a pipe."
  :type 'integer
  :group 'powershell)

;; Note: There are no explicit references to the variable
;; `explicit-powershell.exe-args'.  It is used implicitly by M-x shell
;; when the shell is `powershell.exe'.  See
;; http://blogs.msdn.com/b/dotnetinterop/archive/2008/04/10/run-powershell-as-a-shell-within-emacs.aspx
;; for details.
(defcustom explicit-powershell.exe-args '("-Command" "-" )
  "Args passed to inferior shell by \\[shell], if the shell is powershell.exe.
Value is a list of strings, which may be nil."
  :type '(repeat (string :tag "Argument"))
  :group 'powershell)

(defun powershell-continuation-line-p ()
  "Return t is the current line is a continuation line.
The current line is a continued line when the previous line ends
with a backtick or a pipe"
  (interactive)
  (save-excursion
    (forward-line -1)
    (looking-at powershell-continued-regexp)))

;; Rick added significant complexity to Frédéric's original version
(defun powershell-indent-line-amount ()
  "Return the column to which the current line ought to be indented."
  (interactive)
  (save-excursion
    (beginning-of-line)
    (if (powershell-continuation-line-p)
        ;; on a continuation line (i.e. prior line ends with backtick
        ;; or pipe), indent relative to the continued line.
        (progn
          (while (and (not (bobp))(powershell-continuation-line-p))
            (forward-line -1))
          (+ (current-indentation) powershell-continuation-indent))
      ;; otherwise, indent relative to the block's opening char ([{
      ;; \\s- includes newline, which make the line right before closing paren not indented
      (let ((closing-paren (looking-at "[ \t]*\\s)"))
            new-indent
            block-open-line)
        (condition-case nil
            (progn
              (backward-up-list)   ;when at top level, throw to no-indent
              (setq block-open-line (line-number-at-pos))
              ;; We're in a block, calculate/return indent amount.
              (if (not (looking-at "\\s(\\s-*\\(#.*\\)?$"))
                  ;; code (not comments) follow the block open so
                  ;; vertically align the block with the code.
                  (if closing-paren
                      ;; closing indent = open
                      (setq new-indent (current-column))
                    ;; block indent = first line of code
                    (forward-char)
                    (skip-syntax-forward " ")
                    (setq new-indent (current-column)))
                ;; otherwise block open is at eol so indent is relative to
                ;; bol or another block open on the same line.
                (if closing-paren       ; this sets the default indent
                    (setq new-indent (current-indentation))
                  (setq new-indent (+ powershell-indent (current-indentation))))
                ;; now see if the block is nested on the same line
                (when (condition-case nil
                          (progn
                            (backward-up-list)
                            (= block-open-line (line-number-at-pos)))
                        (scan-error nil))
                  (forward-char)
                  (skip-syntax-forward " ")
                  (if closing-paren
                      (setq new-indent (current-column))
                    (setq new-indent (+ powershell-indent (current-column))))))
              new-indent)
          (scan-error ;; most likely, we are at the top-level
           0))))))

(defun powershell-indent-line ()
  "Indent the current line of powershell mode.
Leave the point in place if it is inside the meat of the line"
  (interactive)
  (let ((savep (> (current-column) (current-indentation)))
        (amount (powershell-indent-line-amount)))
    (if savep
        (save-excursion (indent-line-to amount))
      (indent-line-to amount))))

(defun powershell-quote-selection (beg end)
  "Quotes the selection between BEG and END.
Quotes with single quotes and doubles embedded single quotes."
  (interactive `(,(region-beginning) ,(region-end)))
  (if (not mark-active)
      (error "Command requires a marked region"))
  (goto-char beg)
  (while (re-search-forward "'" end t)
    (replace-match "''")(setq end (1+ end)))
  (goto-char beg)
  (insert "'")
  (setq end (1+ end))
  (goto-char end)
  (insert "'"))

(defun powershell-unquote-selection (beg end)
  "Unquotes the selected text between BEG and END.
Remove doubled single quotes as we go."
  (interactive `(,(region-beginning) ,(region-end)))
  (if (not mark-active)
      (error "Command requires a marked region"))
  (goto-char beg)
  (cond ((looking-at "'")
         (goto-char end)
         (when (looking-back "'" nil)
           (delete-char -1)
           (setq end (1- end))
           (goto-char beg)
           (delete-char 1)
           (setq end (1- end))
           (while (search-forward "'" end t)
             (delete-char -1)
             (forward-char)
             (setq end (1- end)))))
        ((looking-at "\"")
         (goto-char end)
         (when (looking-back "\"" nil)
           (delete-char -1)
           (setq end (1- end))
           (goto-char beg)
           (delete-char 1)
           (setq end (1- end))
           (while (search-forward "\"" end t)
             (delete-char -1)
             (forward-char)
             (setq end (1- end)))
           (while (search-forward "`" end t)
             (delete-char -1)
             (forward-char)
             (setq end (1- end)))))
        (t (error "Must select quoted text exactly"))))

(defun powershell-escape-selection (beg end)
  "Escape variables between BEG and END.
Also extend existing escapes."
  (interactive `(,(region-beginning) ,(region-end)))
  (if (not mark-active)
      (error "Command requires a marked region"))
  (goto-char beg)
  (while (re-search-forward "`" end t)
    (replace-match "```")(setq end (+ end 2)))
  (goto-char beg)
  (while (re-search-forward "\\(?:\\=\\|[^`]\\)[$]" end t)
    (goto-char (car (cdr (match-data))))
    (backward-char)
    (insert "`")
    (forward-char)
    (setq end (1+ end))))

(defun powershell-doublequote-selection (beg end)
  "Quotes the text between BEG and END with double quotes.
Embedded quotes are doubled."
  (interactive `(,(region-beginning) ,(region-end)))
  (if (not mark-active)
      (error "Command requires a marked region"))
  (goto-char beg)
  (while (re-search-forward "\"" end t)
    (replace-match "\"\"")(setq end (1+ end)))
  (goto-char beg)
  (while (re-search-forward "`'" end t)
    (replace-match "```")(setq end (+ 2 end)))
  (goto-char beg)
  (insert "\"")
  (setq end (1+ end))
  (goto-char end)
  (insert "\""))

(defun powershell-dollarparen-selection (beg end)
  "Wraps the text between BEG and END with $().
The point is moved to the closing paren."
  (interactive `(,(region-beginning) ,(region-end)))
  (if (not mark-active)
      (error "Command requires a marked region"))
  (save-excursion
    (goto-char end)
    (insert ")")
    (goto-char beg)
    (insert "$("))
  (forward-char))

(defun powershell-regexp-to-regex (beg end)
  "Turn the text between BEG and END into a regex.
The text is assumed to be `regexp-opt' output."
  (interactive `(,(region-beginning) ,(region-end)))
  (if (not mark-active)
      (error "Command requires a marked region"))
  (save-restriction
    (narrow-to-region beg end)
    (goto-char (point-min))
    (while (re-search-forward "\\\\(" nil t)
      (replace-match "("))
    (goto-char (point-min))
    (while (re-search-forward "\\\\)" nil t)
      (replace-match ")"))
    (goto-char (point-min))
    (while (re-search-forward "\\\\|" nil t)
      (replace-match "|"))))


;; Taken from About_Keywords
(defvar powershell-keywords
  (concat "\\_<"
          (regexp-opt
           '("begin" "break" "catch" "class" "continue" "data" "define" "do" "default"
             "dynamicparam" "else" "elseif" "end" "enum" "exit" "filter" "finally"
             "for" "foreach" "from" "function" "hidden" "if" "in" "param" "process"
             "return" "static" "switch" "throw" "trap" "try" "until" "using" "var" "where" "while"
             ;; Questionable, specific to workflow sessions
             "inlinescript")
           t)
          "\\_>")
  "PowerShell keywords.")

;; Taken from About_Comparison_Operators and some questionable sources :-)
(defvar powershell-operators
  (concat "\\_<"
          (regexp-opt
           '("-eq" "-ne" "-gt" "-ge" "-lt" "-le"
             ;; case sensitive versions
             "-ceq" "-cne" "-cgt" "-cge" "-clt" "-cle"
             ;; explicitly case insensitive
             "-ieq" "-ine" "-igt" "-ige" "-ilt" "-ile"
             "-band" "-bor" "-bxor" "-bnot"
             "-and" "-or" "-xor" "-not" "!"
             "-like" "-notlike" "-clike" "-cnotlike" "-ilike" "-inotlike"
             "-match" "-notmatch" "-cmatch" "-cnotmatch" "-imatch" "-inotmatch"
             "-contains" "-notcontains" "-ccontains" "-cnotcontains"
             "-icontains" "-inotcontains"
             "-replace" "-creplace" "-ireplace"
             "-is" "-isnot" "-as" "-f"
             "-in" "-cin" "-iin" "-notin" "-cnotin" "-inotin"
             "-split" "-csplit" "-isplit"
             "-join"
             "-shl" "-shr"
             ;; Questionable --> specific to certain contexts
             "-casesensitive" "-wildcard" "-regex" "-exact" ;specific to case
             "-begin" "-process" "-end" ;specific to scriptblock
             ) t)
          "\\_>")
  "PowerShell operators.")

(defvar powershell-scope-names
  '("global"   "local"    "private"  "script"   )
  "Names of scopes in PowerShell mode.")

(defvar powershell-variable-drive-names
  (append '("env" "function" "variable" "alias" "hklm" "hkcu" "wsman") powershell-scope-names)
  "Names of scopes in PowerShell mode.")

(defconst powershell-variables-regexp
  ;; There are 2 syntaxes detected: ${[scope:]name} and $[scope:]name
  ;; Match 0 is the entire variable name.
  ;; Match 1 is scope when the former syntax is found.
  ;; Match 2 is scope when the latter syntax is found.
  (concat
   "\\_<$\\(?:{\\(?:" (regexp-opt powershell-variable-drive-names t)
   ":\\)?[^}]+}\\|"
   "\\(?:" (regexp-opt powershell-variable-drive-names t)
   ":\\)?[a-zA-Z0-9_]+\\_>\\)")
  "Identifies legal powershell variable names.")

(defconst powershell-function-names-regex
  ;; Syntax detected is [scope:]verb-noun
  ;; Match 0 is the entire name.
  ;; Match 1 is the scope if any.
  ;; Match 2 is the function name (which must exist)
  (concat
   "\\_<\\(?:" (regexp-opt powershell-scope-names t) ":\\)?"
   "\\([A-Z][a-zA-Z0-9]*-[A-Z0-9][a-zA-Z0-9]*\\)\\_>")
  "Identifies legal function & filter names.")

(defconst powershell-object-types-regexp
  ;; Syntax is \[name[.name]\] (where the escaped []s are literal)
  ;; Only Match 0 is returned.
  "\\[\\(?:[a-zA-Z_][a-zA-Z0-9]*\\)\\(?:\\.[a-zA-Z_][a-zA-Z0-9]*\\)*\\]"
  "Identifies object type references.  I.E. [object.data.type] syntax.")

(defconst powershell-function-switch-names-regexp
  ;; Only Match 0 is returned.
  "\\_<-[a-zA-Z][a-zA-Z0-9]*\\_>"
  "Identifies function parameter names of the form -xxxx.")

;; Taken from Get-Variable on a fresh shell, merged with man
;; about_automatic_variables
(defvar powershell-builtin-variables-regexp
  (regexp-opt
   '("$"                              "?"
     "^"                              "_"
     "args"                           "ConsoleFileName"
     "Error"                          "Event"
     "EventArgs"
     "EventSubscriber"                "ExecutionContext"
     "false"                          "Foreach"
     "HOME"                           "Host"
     "input"                          "lsCoreCLR"
     "lsLinux"                        "lsMacOS"
     "lsWindows"                      "LASTEXITCODE"
     "Matches"                        "MyInvocation"
     "NestedPromptLevel"              "null"
     "PID"                            "PROFILE"
     "PSBoundParameters"              "PSCmdlet"
     "PSCommandPath"
     "PSCulture"                      "PSDebugContext"
     "PSHOME"                         "PSITEM"
     "PSScriptRoot"                   "PSSenderInfo"
     "PSUICulture"                    "PSVersionTable"
     "PWD"                            "ReportErrorShowExceptionClass"
     "ReportErrorShowInnerException"  "ReportErrorShowSource"
     "ReportErrorShowStackTrace"      "Sender"
     "ShellId"                        "SourceArgs"
     "SourceEventArgs"                "StackTrace"
     "this"                           "true"                           ) t)
  "The names of the built-in PowerShell variables.
They are highlighted differently from the other variables.")

(defvar powershell-config-variables-regexp
  (regexp-opt
   '("ConfirmPreference"           "DebugPreference"
     "ErrorActionPreference"       "ErrorView"
     "FormatEnumerationLimit"      "InformationPreference"
     "LogCommandHealthEvent"
     "LogCommandLifecycleEvent"    "LogEngineHealthEvent"
     "LogEngineLifecycleEvent"     "LogProviderHealthEvent"
     "LogProviderLifecycleEvent"   "MaximumAliasCount"
     "MaximumDriveCount"           "MaximumErrorCount"
     "MaximumFunctionCount"        "MaximumHistoryCount"
     "MaximumVariableCount"        "OFS"
     "OutputEncoding"              "ProgressPreference"
     "PSDefaultParameterValues"    "PSEmailServer"
     "PSModuleAutoLoadingPreference" "PSSessionApplicationName"
     "PSSessionConfigurationName"  "PSSessionOption"
     "VerbosePreference"           "WarningPreference"
     "WhatIfPreference"            ) t)
  "Names of variables that configure powershell features.")


(defun powershell-find-syntactic-comments (limit)
  "Find PowerShell comment begin and comment end characters.
Returns match 1 and match 2 for <# #> comment sequences respectively.
Returns match 3 and optionally match 4 for #/eol comments.
Match 4 is returned only if eol is found before LIMIT"
  (when (search-forward "#" limit t)
    (cond
     ((looking-back "<#" nil)
      (set-match-data (list (match-beginning 0) (1+ (match-beginning 0))
                            (match-beginning 0) (1+ (match-beginning 0)))))
     ((looking-at ">")
      (set-match-data (list (match-beginning 0) (match-end 0)
                            nil nil
                            (match-beginning 0) (match-end 0)))
      (forward-char))
     (t
      (let ((start (point)))
        (if (search-forward "\n" limit t)
            (set-match-data (list (1- start) (match-end 0)
                                  nil nil nil nil
                                  (1- start) start
                                  (match-beginning 0) (match-end 0)))
          (set-match-data (list start (match-end 0)
                                nil nil nil nil
                                (1- start) start))))))
    t))

(defun powershell-find-syntactic-quotes (limit)
  "Find PowerShell hear string begin and end sequences upto LIMIT.
Returns match 1 and match 2 for @' '@ sequences respectively.
Returns match 3 and match 4 for @\" \"@ sequences respectively."
  (when (search-forward "@" limit t)
    (cond
     ((looking-at "'$")
      (set-match-data (list (match-beginning 0) (1+ (match-beginning 0))
                            (match-beginning 0) (1+ (match-beginning 0))))
      (forward-char))
     ((looking-back "^'@" nil)
      (set-match-data (list (1- (match-end 0)) (match-end 0)
                            nil nil
                            (1- (match-end 0)) (match-end 0))))
     ((looking-at "\"$")
      (set-match-data (list (match-beginning 0) (1+ (match-beginning 0))
                            nil nil
                            nil nil
                            (match-beginning 0) (1+ (match-beginning 0))))
      (forward-char))
     ((looking-back "^\"@" nil)
      (set-match-data (list (1- (match-end 0)) (match-end 0)
                            nil nil
                            nil nil
                            nil nil
                            (1- (match-end 0)) (match-end 0)))))
    t))
(defvar powershell-font-lock-syntactic-keywords
  `((powershell-find-syntactic-comments (1 "!" t t) (2 "!" t t)
                                        (3 "<" t t) (4 ">" t t))
    (powershell-find-syntactic-quotes (1 "|" t t) (2 "|" t t)
                                      (3 "|" t t) (4 "|" t t)))
  "A list of regexp's or functions.
Used to add `syntax-table' properties to
characters that can't be set by the `syntax-table' alone.")


(defvar powershell-font-lock-keywords-1
  `( ;; Type annotations
    (,powershell-object-types-regexp . font-lock-type-face)
    ;; syntaxic keywords
    (,powershell-keywords . font-lock-keyword-face)
    ;; operators
    (,powershell-operators . font-lock-builtin-face)
    ;; the REQUIRES mark
    ("^#\\(REQUIRES\\)" 1 font-lock-warning-face t))
  "Keywords for the first level of font-locking in PowerShell mode.")

(defvar powershell-font-lock-keywords-2
  (append
   powershell-font-lock-keywords-1
   `( ;; Built-in variables
     (,(concat "\\$\\(" powershell-builtin-variables-regexp "\\)\\>")
      0 font-lock-builtin-face t)
     (,(concat "\\$\\(" powershell-config-variables-regexp "\\)\\>")
      0 font-lock-builtin-face t)))
  "Keywords for the second level of font-locking in PowerShell mode.")

(defvar powershell-font-lock-keywords-3
  (append
   powershell-font-lock-keywords-2
   `( ;; user variables
     (,powershell-variables-regexp
      (0 font-lock-variable-name-face)
      (1 (cons font-lock-type-face '(underline)) t t)
      (2 (cons font-lock-type-face '(underline)) t t))
     ;; function argument names
     (,powershell-function-switch-names-regexp
      (0 font-lock-reference-face)
      (1 (cons font-lock-type-face '(underline)) t t)
      (2 (cons font-lock-type-face '(underline)) t t))
     ;; function names
     (,powershell-function-names-regex
      (0 font-lock-function-name-face)
      (1 (cons font-lock-type-face '(underline)) t t))))
  "Keywords for the maximum level of font-locking in PowerShell mode.")


(defun powershell-setup-font-lock ()
  "Set up the buffer local value for `font-lock-defaults'."
  ;; I use font-lock-syntactic-keywords to set some properties and I
  ;; don't want them ignored.
  (set (make-local-variable 'parse-sexp-lookup-properties) t)
  ;; This is where all the font-lock stuff actually gets set up.  Once
  ;; font-lock-defaults has its value, setting font-lock-mode true should
  ;; cause all your syntax highlighting dreams to come true.
  (setq font-lock-defaults
        ;; The first value is all the keyword expressions.
        '((powershell-font-lock-keywords-1
           powershell-font-lock-keywords-2
           powershell-font-lock-keywords-3)
          ;; keywords-only means no strings or comments get fontified
          nil
          ;; case-fold (t ignores case)
          t
          ;; syntax-alist nothing special here
          nil
          ;; syntax-begin - no function defined to move outside syntactic block
          nil
          ;; font-lock-syntactic-keywords
          ;; takes (matcher (match syntax override lexmatch) ...)...
          (font-lock-syntactic-keywords
           . powershell-font-lock-syntactic-keywords))))

(defvar powershell-mode-syntax-table
  (let ((powershell-mode-syntax-table (make-syntax-table)))
    (modify-syntax-entry ?$  "_" powershell-mode-syntax-table)
    (modify-syntax-entry ?:  "_" powershell-mode-syntax-table)
    (modify-syntax-entry ?-  "_" powershell-mode-syntax-table)
    (modify-syntax-entry ?^  "_" powershell-mode-syntax-table)
    (modify-syntax-entry ?\\ "_" powershell-mode-syntax-table)
    (modify-syntax-entry ?\{ "(}" powershell-mode-syntax-table)
    (modify-syntax-entry ?\} "){" powershell-mode-syntax-table)
    (modify-syntax-entry ?\[ "(]" powershell-mode-syntax-table)
    (modify-syntax-entry ?\] ")[" powershell-mode-syntax-table)
    (modify-syntax-entry ?\( "()" powershell-mode-syntax-table)
    (modify-syntax-entry ?\) ")(" powershell-mode-syntax-table)
    (modify-syntax-entry ?` "\\" powershell-mode-syntax-table)
    (modify-syntax-entry ?_  "w" powershell-mode-syntax-table)
    (modify-syntax-entry ?=  "." powershell-mode-syntax-table)
    (modify-syntax-entry ?|  "." powershell-mode-syntax-table)
    (modify-syntax-entry ?+  "." powershell-mode-syntax-table)
    (modify-syntax-entry ?*  "." powershell-mode-syntax-table)
    (modify-syntax-entry ?/  "." powershell-mode-syntax-table)
    (modify-syntax-entry ?' "\"" powershell-mode-syntax-table)
    (modify-syntax-entry ?#  "<" powershell-mode-syntax-table)
    powershell-mode-syntax-table)
  "Syntax for PowerShell major mode.")

(defvar powershell-mode-map
  (let ((powershell-mode-map (make-keymap)))
    ;;    (define-key powershell-mode-map "\r" 'powershell-indent-line)
    (define-key powershell-mode-map (kbd "M-\"")
      'powershell-doublequote-selection)
    (define-key powershell-mode-map (kbd "M-'") 'powershell-quote-selection)
    (define-key powershell-mode-map (kbd "C-'") 'powershell-unquote-selection)
    (define-key powershell-mode-map (kbd "C-\"") 'powershell-unquote-selection)
    (define-key powershell-mode-map (kbd "M-`") 'powershell-escape-selection)
    (define-key powershell-mode-map (kbd "C-$")
      'powershell-dollarparen-selection)
    powershell-mode-map)
  "Keymap for PS major mode.")

(defun powershell-setup-menu ()
  "Add a menu of PowerShell specific functions to the menu bar."
  (define-key (current-local-map) [menu-bar powershell-menu]
    (cons "PowerShell" (make-sparse-keymap "PowerShell")))
  (define-key (current-local-map) [menu-bar powershell-menu doublequote]
    '(menu-item "DoubleQuote Selection" powershell-doublequote-selection
                :key-sequence(kbd "M-\"")
                :help
                "DoubleQuotes the selection escaping embedded double quotes"))
  (define-key (current-local-map) [menu-bar powershell-menu quote]
    '(menu-item "SingleQuote Selection" powershell-quote-selection
                :key-sequence (kbd "M-'")
                :help
                "SingleQuotes the selection escaping embedded single quotes"))
  (define-key (current-local-map) [menu-bar powershell-menu unquote]
    '(menu-item "UnQuote Selection" powershell-unquote-selection
                :key-sequence (kbd "C-'")
                :help "Un-Quotes the selection un-escaping any escaped quotes"))
  (define-key (current-local-map) [menu-bar powershell-menu escape]
    '(menu-item "Escape Selection" powershell-escape-selection
                :key-sequence (kbd "M-`")
                :help (concat "Escapes variables in the selection"
                              " and extends existing escapes.")))
  (define-key (current-local-map) [menu-bar powershell-menu dollarparen]
    '(menu-item "DollarParen Selection" powershell-dollarparen-selection
                :key-sequence (kbd "C-$")
                :help "Wraps the selection in $()")))


;;; Eldoc support

(defcustom powershell-eldoc-def-files nil
  "List of files containing function help strings used by function `eldoc-mode'.
These are the strings function `eldoc-mode' displays as help for
functions near point.  The format of the file must be exactly as
follows or who knows what happens.

   (set (intern \"<fcn-name1>\" powershell-eldoc-obarray) \"<helper string1>\")
   (set (intern \"<fcn-name2>\" powershell-eldoc-obarray) \"<helper string2>\")
...

Where <fcn-name> is the name of the function to which <helper string> applies.
      <helper-string> is the string to display when point is near <fcn-name>."
  :type '(repeat string)
  :group 'powershell)

(defvar powershell-eldoc-obarray ()
  "Array for file entries by the function `eldoc'.
`powershell-eldoc-def-files' entries are added into this array.")

(defun powershell-eldoc-function ()
  "Return a documentation string appropriate for the current context or nil."
  (let ((word (thing-at-point 'symbol)))
    (if word
        (eval (intern-soft word powershell-eldoc-obarray)))))

(defun powershell-setup-eldoc ()
  "Load the function documentation for use with eldoc."
  (when (not (null powershell-eldoc-def-files))
    (set (make-local-variable 'eldoc-documentation-function)
         'powershell-eldoc-function)
    (unless (vectorp powershell-eldoc-obarray)
      (setq powershell-eldoc-obarray (make-vector 41 0))
      (condition-case var (mapc 'load powershell-eldoc-def-files)
        (error (message "*** powershell-setup-eldoc ERROR *** %s" var))))))
;;; Note: You can create quite a bit of help with these commands:
;;
;; function Get-Signature ($Cmd) {
;;   if ($Cmd -is [Management.Automation.PSMethod]) {
;;     $List = @($Cmd)}
;;   elseif ($Cmd -isnot [string]) {
;;     throw ("Get-Signature {<method>|<command>}`n" +
;;            "'$Cmd' is not a method or command")}
;;     else {$List = @(Get-Command $Cmd -ErrorAction SilentlyContinue)}
;;   if (!$List[0] ) {
;;     throw "Command '$Cmd' not found"}
;;   foreach ($O in $List) {
;;     switch -regex ($O.GetType().Name) {
;;       'AliasInfo' {
;;         Get-Signature ($O.Definition)}
;;       '(Cmdlet|ExternalScript)Info' {
;;         $O.Definition}          # not sure what to do with ExternalScript
;;       'F(unction|ilter)Info'{
;;         if ($O.Definition -match '^param *\(') {
;;           $t = [Management.Automation.PSParser]::tokenize($O.Definition,
;;                                                           [ref]$null)
;;           $c = 1;$i = 1
;;           while($c -and $i++ -lt $t.count) {
;;             switch ($t[$i].Type.ToString()) {
;;               GroupStart {$c++}
;;               GroupEnd   {$c--}}}
;;           $O.Definition.substring(0,$t[$i].start + 1)} #needs parsing
;;         else {$O.Name}}
;;       'PSMethod' {
;;         foreach ($t in @($O.OverloadDefinitions)) {
;;           while (($b=$t.IndexOf('`1[[')) -ge 0) {
;;             $t=$t.remove($b,$t.IndexOf(']]')-$b+2)}
;;             $t}}}}}
;; get-command|
;;   ?{$_.CommandType -ne 'Alias' -and $_.Name -notlike '*:'}|
;;   %{$_.Name}|
;;   sort|
;;   %{("(set (intern ""$($_.Replace('\','\\'))"" powershell-eldoc-obarray)" +
;;      " ""$(Get-Signature $_|%{$_.Replace('\','\\').Replace('"','\"')})"")"
;;     ).Replace("`r`n"")",""")")} > .\powershell-eldoc.el


(defvar powershell-imenu-expression
  `(("Functions" ,(concat "function " powershell-function-names-regex) 2)
    ("Filters" ,(concat "filter " powershell-function-names-regex) 2)
    ("Top variables"
     , (concat "^\\(" powershell-object-types-regexp "\\)?\\("
               powershell-variables-regexp "\\)\\s-*=")
     2))
  "List of regexps matching important expressions, for speebar & imenu.")

(defun powershell-setup-imenu ()
  "Install `powershell-imenu-expression'."
  (when (require 'imenu nil t)
    ;; imenu doc says these are buffer-local by default
    (setq imenu-generic-expression powershell-imenu-expression)
    (setq imenu-case-fold-search nil)
    (imenu-add-menubar-index)))

(defun powershell-setup-speedbar ()
  "Install `speedbar-add-supported-extension'."
  (when (require 'speedbar nil t)
    (speedbar-add-supported-extension ".ps1?")))

;; A better command would be something like "powershell.exe -NoLogo
;; -NonInteractive -Command & (buffer-file-name)". But it will just
;; sit there waiting...  The following will only work when .ps1 files
;; are associated with powershell.exe. And if they don't contain spaces.
(defvar powershell-compile-command
  '(buffer-file-name)
  "Default command used to invoke a powershell script.")

;; The column number will be off whenever tabs are used. Since this is
;; the default in this mode, we will not capture the column number.
(setq compilation-error-regexp-alist
      (cons '("At \\(.*\\):\\([0-9]+\\) char:\\([0-9]+\\)" 1 2)
            compilation-error-regexp-alist))


(add-hook 'powershell-mode-hook #'imenu-add-menubar-index)

;;;###autoload
(define-derived-mode powershell-mode prog-mode "PS"
  "Major mode for editing PowerShell scripts.

\\{powershell-mode-map}
Entry to this mode calls the value of `powershell-mode-hook' if
that value is non-nil."
  (powershell-setup-font-lock)
  (setq-local indent-line-function 'powershell-indent-line)
  (setq-local compile-command powershell-compile-command)
  (setq-local comment-start "#")
  (setq-local comment-start-skip "#+\\s*")
  (setq-local parse-sexp-ignore-comments t)
  ;; Support electric-pair-mode
  (setq-local electric-indent-chars
              (append "{}():;," electric-indent-chars))
  (powershell-setup-imenu)
  (powershell-setup-speedbar)
  (powershell-setup-menu)
  (powershell-setup-eldoc))

;;; PowerShell inferior mode

;;; Code:
(defcustom powershell-location-of-exe
   (or (executable-find "pwsh") (executable-find "powershell"))
  "A string providing the location of the powershell executable. Since
the newer PowerShell Core (pwsh.exe) does not replace the older Windows
PowerShell (powershell.exe) when installed, this attempts to find the
former first, and only if it doesn't exist, falls back to the latter."
  :group 'powershell
  :type 'string)

(defcustom powershell-log-level 3
  "The current log level for powershell internal operations.
0 = NONE, 1 = Info, 2 = VERBOSE, 3 = DEBUG."
  :group 'powershell
  :type 'integer)

(defcustom powershell-squish-results-of-silent-commands t
  "The function `powershell-invoke-command-silently' returns the results
of a command in a string.  PowerShell by default, inserts newlines when
the output exceeds the configured width of the powershell virtual
window. In some cases callers might want to get the results with the
newlines and formatting removed. Set this to true, to do that."
  :group 'powershell
  :type 'boolean)

(defvar powershell-prompt-regex  "PS [^#$%>]+> "
  "Regexp to match the powershell prompt.
powershell.el uses this regex to determine when a command has
completed.  Therefore, you need to set this appropriately if you
explicitly change the prompt function in powershell.  Any value
should include a trailing space, if the powershell prompt uses a
trailing space, but should not include a trailing newline.

The default value will match the default PowerShell prompt.")

(defvar powershell-command-reply nil
  "The reply of powershell commands.
This is retained for housekeeping purposes.")

(defvar powershell--max-window-width  0
  "The maximum width of a powershell window.
You shouldn't need to ever set this.  It gets set automatically,
once, when the powershell starts up.")

(defvar powershell-command-timeout-seconds 12
  "The timeout for a powershell command.
powershell.el will wait this long before giving up.")

(defvar powershell--need-rawui-resize t
  "No need to fuss with this.  It's intended for internal use
only.  It gets set when powershell needs to be informed that
emacs has resized its window.")

(defconst powershell--find-max-window-width-command
  (concat
  "function _Emacs_GetMaxPhsWindowSize"
  " {"
  " $rawui = (Get-Host).UI.RawUI;"
  " $mpws_exists = ($rawui | Get-Member | Where-Object"
  " {$_.Name -eq \"MaxPhysicalWindowSize\"});"
  " if ($mpws_exists -eq $null) {"
  " 210"
  " } else {"
  " $rawui.MaxPhysicalWindowSize.Width"
  " }"
  " };"
  " _Emacs_GetMaxPhsWindowSize")
  "The powershell logic to determine the max physical window width.")

(defconst powershell--set-window-width-fn-name  "_Emacs_SetWindowWidth"
  "The name of the function this mode defines in PowerShell to
set the window width. Intended for internal use only.")

(defconst powershell--text-of-set-window-width-ps-function
  ;; see
  ;; http://blogs.msdn.com/lior/archive/2009/05/27/ResizePowerShellConsoleWindow.aspx
  ;;
  ;; When making the console window narrower, you mus set the window
  ;; size first. When making the console window wider, you must set the
  ;; buffer size first.

    (concat  "function " powershell--set-window-width-fn-name
             "([string] $pswidth)"
             " {"
             " $rawui = (Get-Host).UI.RawUI;"
             " $bufsize = $rawui.BufferSize;"
             " $winsize = $rawui.WindowSize;"
             " $cwidth = $winsize.Width;"
             " $winsize.Width = $pswidth;"
             " $bufsize.Width = $pswidth;"
             " if ($cwidth -lt $pswidth) {"
             " $rawui.BufferSize = $bufsize;"
             " $rawui.WindowSize = $winsize;"
             " }"
             " elseif ($cwidth -gt $pswidth) {"
             " $rawui.WindowSize = $winsize;"
             " $rawui.BufferSize = $bufsize;"
             " };"
             " Set-Variable -name rawui -value $null;"
             " Set-Variable -name winsize -value $null;"
             " Set-Variable -name bufsize -value $null;"
             " Set-Variable -name cwidth -value $null;"
             " }")

    "The text of the powershell function that will be used at runtime to
set the width of the virtual Window in PowerShell, as the Emacs window
gets resized.")

(defun powershell-log (level text &rest args)
  "Log a message at level LEVEL.
If LEVEL is higher than `powershell-log-level', the message is
ignored.  Otherwise, it is printed using `message'.
TEXT is a format control string, and the remaining arguments ARGS
are the string substitutions (see `format')."
  (if (<= level powershell-log-level)
      (let* ((msg (apply 'format text args)))
        (message "%s" msg))))

;; (defun dino-powershell-complete (arg)
;; "do powershell completion on the given STRING. Pop up a buffer
;; with the completion list."
;;   (interactive
;;    (list (read-no-blanks-input "\
;; Stub to complete: ")))

;;   (let ((proc
;;          (get-buffer-process (current-buffer))))
;;    (comint-proc-query proc (concat "Get-Command " arg "*\n"))
;;    )
;; )

;; (defun dino-powershell-cmd-complete ()
;;   "try to get powershell completion to work."
;;   (interactive)
;;   (let ((proc
;;          (get-buffer-process (current-buffer))))
;; ;;   (comint-proc-query proc "Get-a\t")
;; ;;   (comint-simple-send proc "Get-a\t")
;;        (comint-send-string proc "Get-a\t\n")
;; ;;   (process-send-eof)
;;    )
;; )

(defun powershell--define-set-window-width-function (proc)
  "Sends a function definition to the PowerShell instance
identified by PROC.  The function sets the window width of the
PowerShell virtual window.  Later, the function will be called
when the width of the emacs window changes."
    (if proc
        (progn
          ;;process-send-string
          (comint-simple-send
           proc
           powershell--text-of-set-window-width-ps-function))))

(defun powershell--get-max-window-width  (buffer-name)
  "Gets the maximum width of the virtual window for PowerShell running
in the buffer with name BUFFER-NAME.

In PowerShell 1.0, the maximum WindowSize.Width for
PowerShell is 210, hardcoded, I believe. In PowerShell 2.0, the max
windowsize.Width is provided in the RawUI.MaxPhysicalWindowSize
property.

This function does the right thing, and sets the buffer-local
`powershell--max-window-width' variable with the correct value."
  (let ((proc (get-buffer-process buffer-name)))

    (if proc
        (with-current-buffer buffer-name
          (powershell-invoke-command-silently
           proc
           powershell--find-max-window-width-command
           0.90)

          ;; store the retrieved width
          (setq powershell--max-window-width
                (if (and (not (null powershell-command-reply))
                         (string-match
                          "\\([1-9][0-9]*\\)[ \t\f\v\n]+"
                          powershell-command-reply))
                    (string-to-number (match-string 1 powershell-command-reply))
                  200)))))) ;; could go to 210, but let's use 200 to be safe

(defun powershell--set-window-width (proc)
  "Run the PowerShell function that sets the RawUI width
appropriately for a PowerShell shell.

This is necessary to get powershell to do the right thing, as far
as text formatting, when the emacs window gets resized.

The function gets defined in powershell upon powershell startup."
  (let ((ps-width
         (number-to-string (min powershell--max-window-width (window-width)))))
    (progn
      ;;(process-send-string
      (comint-simple-send
       proc
       (concat powershell--set-window-width-fn-name
               "('" ps-width "')")))))

;;;###autoload
(defun powershell (&optional buffer prompt-string)
  "Run an inferior PowerShell.
If BUFFER is non-nil, use it to hold the powershell
process.  Defaults to *PowerShell*.

Interactively, a prefix arg means to prompt for BUFFER.

If BUFFER exists but the shell process is not running, it makes a
new shell.

If BUFFER exists and the shell process is running, just switch to
BUFFER.

If PROMPT-STRING is non-nil, sets the prompt to the given value.

See the help for `shell' for more details.  \(Type
\\[describe-mode] in the shell buffer for a list of commands.)"
  (interactive
   (list
    (and current-prefix-arg
         (read-buffer "Shell buffer: "
                      (generate-new-buffer-name "*PowerShell*")))))

  (setq buffer (get-buffer-create (or buffer "*PowerShell*")))
  (powershell-log 1 "powershell starting up...in buffer %s" (buffer-name buffer))
  (let ((explicit-shell-file-name (if (eq system-type 'cygwin)
				      (cygwin-convert-file-name-from-windows powershell-location-of-exe)
				    powershell-location-of-exe)))
    ;; set arguments for the powershell exe.
    ;; Does this need to be tunable?

    (shell buffer))

  ;; (powershell--get-max-window-width "*PowerShell*")
  ;; (powershell-invoke-command-silently (get-buffer-process "*csdeshell*")
  ;; "[Ionic.Csde.Utilities]::Version()" 2.9)

  ;;  (comint-simple-send (get-buffer-process "*csdeshell*") "prompt\n")

  (let ((proc (get-buffer-process buffer)))

    (make-local-variable 'powershell-prompt-regex)
    (make-local-variable 'powershell-command-reply)
    (make-local-variable 'powershell--max-window-width)
    (make-local-variable 'powershell-command-timeout-seconds)
    (make-local-variable 'powershell-squish-results-of-silent-commands)
    (make-local-variable 'powershell--need-rawui-resize)
    (make-local-variable 'comint-prompt-read-only)

    ;; disallow backspace over the prompt:
    (setq comint-prompt-read-only t)

    ;; We need to tell powershell how wide the emacs window is, because
    ;; powershell pads its output to the width it thinks its window is.
    ;;
    ;; The way it's done: every time the width of the emacs window changes, we
    ;; set a flag. Then, before sending a powershell command that is
    ;; typed into the buffer, to the actual powershell process, we check
    ;; that flag.  If it is set, we  resize the powershell window appropriately,
    ;; before sending the command.

    ;; If we didn't do this, powershell output would get wrapped at a
    ;; column width that would be different than the emacs buffer width,
    ;; and everything would look ugly.

    ;; get the maximum width for powershell - can't go beyond this
    (powershell--get-max-window-width buffer)

    ;; define the function for use within powershell to resize the window
    (powershell--define-set-window-width-function proc)

    ;; add the hook that sets the flag
    (add-hook 'window-size-change-functions
              '(lambda (&optional x)
                 (setq powershell--need-rawui-resize t)))

    ;; set the flag so we resize properly the first time.
    (setq powershell--need-rawui-resize t)

    (if prompt-string
        (progn
          ;; This sets up a prompt for the PowerShell.  The prompt is
          ;; important because later, after sending a command to the
          ;; shell, the scanning logic that grabs the output looks for
          ;; the prompt string to determine that the output is complete.
          (comint-simple-send
           proc
           (concat "function prompt { '" prompt-string "' }"))

          (setq powershell-prompt-regex prompt-string)))

    ;; hook the kill-buffer action so we can kill the inferior process?
    (add-hook 'kill-buffer-hook 'powershell-delete-process)

    ;; wrap the comint-input-sender with a PS version
    ;; must do this after launching the shell!
    (make-local-variable 'comint-input-sender)
    (setq comint-input-sender 'powershell-simple-send)

    ;; set a preoutput filter for powershell.  This will trim newlines
    ;; after the prompt.
    (add-hook 'comint-preoutput-filter-functions
              'powershell-preoutput-filter-for-prompt)

    ;; send a carriage-return  (get the prompt)
    (comint-send-input)
    (accept-process-output proc))

  ;; The launch hooks for powershell has not (yet?) been implemented
  ;;(run-hooks 'powershell-launch-hook)

  ;; return the buffer created
  buffer)

;; +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
;; Using powershell on emacs23, I get an error:
;;
;;    ansi-color-process-output: Marker does not point anywhere
;;
;; Here's what's happening.
;;
;; In order to be able to read the output from powershell, this shell
;; starts powershell.exe in "interactive mode", using the -i
;; option. This which has the curious side-effect of turning off the
;; prompt in powershell. Normally powershell will return its results,
;; then emit a prompt to indicate that it is ready for more input.  In
;; interactive mode it doesn't emit the prompt.  To work around this,
;; this code (powershell.el) sends an explicit `prompt` command after
;; sending any user-entered command to powershell. This tells powershell
;; to explicitly return the prompt, after the results of the prior
;; command. The prompt then shows up in the powershell buffer.  Lovely.
;;
;; But, `ansi-color-apply-on-region` gets called after every command
;; gets sent to powershell. It gets called with args `(begin end)`,
;; which are both markers. Turns out the very first time this fn is
;; called, the position for the begin marker is nil.
;;
;; `ansi-color-apply-on-region` calls `(goto-char begin)` (effectively),
;; and when the position on the marker is nil, the call errors with
;; "Marker does not point anywhere."
;;
;; The following advice suppresses the call to
;; `ansi-color-apply-on-region` when the begin marker points
;; nowhere.
(defadvice ansi-color-apply-on-region (around
                                       powershell-throttle-ansi-colorizing
                                       (begin end)
                                       compile)
  (progn
    (let ((start-pos (marker-position begin)))
    (cond
     (start-pos
      (progn
        ad-do-it))))))

(defun powershell--silent-cmd-filter (process result)
"A process filter that captures output from a shell and stores it
to `powershell-command-reply', rather than allowing the output to
be displayed in the shell buffer.

This function is intended for internal use only."
  (let ((end-of-result
         (string-match (concat ".*\n\\(" powershell-prompt-regex "\\)[ \n]*\\'")
                       result)))
    (if (and end-of-result (numberp end-of-result))

        (progn
          ;; Store everything except the follow-on prompt.
          ;; The result probably includes a final newline!
          (setq result (substring result 0 (match-beginning 1)))

          (if powershell-squish-results-of-silent-commands
              (setq result
                    (replace-regexp-in-string "\n" "" result)))

          (setq powershell-command-reply
                (concat powershell-command-reply result)))

      (progn
        (if powershell-squish-results-of-silent-commands
              (setq result
                    (replace-regexp-in-string "\n" "" result)))

        (setq powershell-command-reply
              (concat powershell-command-reply result))

        ;; recurse.  For very very long output, the recursion can
        ;; cause stack overflow. Careful!
        (accept-process-output process powershell-command-timeout-seconds)))))

(defun powershell-invoke-command-silently (proc command
                                                &optional timeout-seconds)
  "In the PowerShell instance PROC, invoke COMMAND silently.
Neither the COMMAND is echoed nor the results to the associated
buffer.  Use TIMEOUT-SECONDS as the timeout, waiting for a
response.  The COMMAND should be a string, and need not be
terminated with a newline.

This is helpful when, for example, doing setup work. Or other sneaky
stuff, such as resetting the size of the PowerShell virtual window.

Returns the result of the command, a string, without the follow-on
command prompt.  The result will probably end in a newline. This result
is also stored in the buffer-local variable `powershell-command-reply'.

In some cases the result can be prepended with the command prompt, as
when, for example, several commands have been send in succession and the
results of the prior command were not fully processed by the application.

If a PowerShell buffer is not the current buffer, this function
should be invoked within a call to `with-current-buffer' or
similar in order to insure that the buffer-local values of
`powershell-command-reply', `powershell-prompt-regex', and
`powershell-command-timeout-seconds' are used.

Example:

    (with-current-buffer powershell-buffer-name
      (powershell-invoke-command-silently
       proc
       command-string
       1.90))"

  (let ((old-timeout powershell-command-timeout-seconds)
        (original-filter (process-filter proc)))

    (setq powershell-command-reply nil)

    (if timeout-seconds
        (setq powershell-command-timeout-seconds timeout-seconds))

    (set-process-filter proc 'powershell--silent-cmd-filter)

    ;; Send the command plus the "prompt" command.  The filter
    ;; will know the command is finished when it sees the command
    ;; prompt.
    ;;
    (process-send-string proc (concat command "\nprompt\n"))

    (accept-process-output proc powershell-command-timeout-seconds)

    ;; output of the command is now available in powershell-command-reply

    ;; Trim prompt from the beginning of the output.
    ;; this can happen for the first command through
    ;; the shell.  I think there's a race condition.
    (if (and powershell-command-reply
             (string-match (concat "^" powershell-prompt-regex "\\(.*\\)\\'")
                           powershell-command-reply))
        (setq powershell-command-reply
              (substring powershell-command-reply
                         (match-beginning 1)
                         (match-end 1))))

    ;; restore the original filter
    (set-process-filter proc original-filter)

    ;; restore the original timeout
    (if timeout-seconds
        (setq powershell-command-timeout-seconds old-timeout))

    ;; the result:
    powershell-command-reply))

(defun powershell-delete-process (&optional proc)
  "Delete the current buffer process or PROC."
  (or proc
      (setq proc (get-buffer-process (current-buffer))))
  (and (processp proc)
       (delete-process proc)))

(defun powershell-preoutput-filter-for-prompt (string)
  "Trim the newline from STRING, the prompt that we get back from
powershell.  This fn is set into the preoutput filters, so the
newline is trimmed before being put into the output buffer."
   (if (string-match (concat powershell-prompt-regex "\n\\'") string)
       (substring string 0 -1) ;; remove newline
     string))

(defun powershell-simple-send (proc string)
  "Override of the comint-simple-send function, with logic
specifically designed for powershell.  This just sends STRING,
plus the prompt command.

When running as an inferior shell with stdin/stdout redirected,
powershell is in noninteractive mode. This means no prompts get
emitted when a PS command completes. This makes it difficult for
a comint mode to determine when the command has completed.
Therefore, we send an explicit request for the prompt, after
sending the actual (primary) command. When the primary command
completes, PowerShell then responds to the \"prompt\" command,
and emits the prompt.

This insures we get and display the prompt."
  ;; Tell PowerShell to resize its virtual window, if necessary. We do
  ;; this by calling a resize function in the PowerShell, before sending
  ;; the user-entered command to the shell.
  ;;
  ;; PowerShell keeps track of its \"console\", and formats its output
  ;; according to the width it thinks it is using.  This is true even when
  ;; powershell is invoked with the - argument, which tells it to use
  ;; stdin as input.

  ;; Therefore, if the user has resized the emacs window since the last
  ;; PowerShell command, we need to tell PowerShell to change the size
  ;; of its virtual window. Calling that function does not change the
  ;; size of a window that is visible on screen - it only changes the
  ;; size of the virtual window that PowerShell thinks it is using.  We
  ;; do that by invoking the PowerShell function that this module
  ;; defined for that purpose.
  ;;
  (if powershell--need-rawui-resize
      (progn
        (powershell--set-window-width proc)
        (setq powershell--need-rawui-resize nil)))
  (comint-simple-send proc (concat string "\n"))
  (comint-simple-send proc "prompt\n"))

;; Notes on TAB for completion.
;; -------------------------------------------------------
;; Emacs calls comint-dynamic-complete when the TAB key is pressed in a shell.
;; This is set up in shell-mode-map.
;;
;; comint-dynamic-complete calls the functions in
;; comint-dynamic-complete-functions, until one of them returns
;; non-nil.
;;
;; comint-dynamic-complete-functions is a good thing to set in the mode hook.
;;
;; The default value for that var in a powershell shell is:
;; (comint-replace-by-expanded-history
;;    shell-dynamic-complete-environment-variable
;;    shell-dynamic-complete-command
;;    shell-replace-by-expanded-directory
;;    comint-dynamic-complete-filename)

;; (defun powershell-dynamic-complete-command ()
;;   "Dynamically complete the command at point.  This function is
;; similar to `comint-dynamic-complete-filename', except that it
;; searches the commands from powershell and then the `exec-path'
;; (minus the trailing Emacs library path) for completion candidates.

;; Completion is dependent on the value of
;; `shell-completion-execonly', plus those that effect file
;; completion.  See `powershell-dynamic-complete-as-command'.

;; Returns t if successful."
;;   (interactive)
;;   (let ((filename (comint-match-partial-filename)))
;;     (if (and filename
;;              (save-match-data (not (string-match "[~/]" filename)))
;;              (eq (match-beginning 0)
;;                  (save-excursion (shell-backward-command 1) (point))))
;;         (prog2 (message "Completing command name...")
;;             (powershell-dynamic-complete-as-command)))))

;; (defun powershell-dynamic-complete-as-command ()
;;   "Dynamically complete at point as a command.
;; See `shell-dynamic-complete-filename'.  Returns t if successful."
;;   (let* ((filename (or (comint-match-partial-filename) ""))
;;          (filenondir (file-name-nondirectory filename))
;;          (path-dirs (cdr (reverse exec-path)))
;;          (cwd (file-name-as-directory (expand-file-name default-directory)))
;;          (ignored-extensions
;;           (and comint-completion-fignore
;;                (mapconcat (function (lambda (x) (concat (regexp-quote x) "$")))
;;                           comint-completion-fignore "\\|")))
;;          (dir "") (comps-in-dir ())
;;          (file "") (abs-file-name "") (completions ()))

;;     ;; Go thru each cmd in powershell's lexicon, finding completions.

;;     ;; Go thru each dir in the search path, finding completions.
;;     (while path-dirs
;;       (setq dir (file-name-as-directory (comint-directory (or (car path-dirs) ".")))
;;             comps-in-dir (and (file-accessible-directory-p dir)
;;                               (file-name-all-completions filenondir dir)))
;;       ;; Go thru each completion found, to see whether it should be used.
;;       (while comps-in-dir
;;         (setq file (car comps-in-dir)
;;               abs-file-name (concat dir file))
;;         (if (and (not (member file completions))
;;                  (not (and ignored-extensions
;;                            (string-match ignored-extensions file)))
;;                  (or (string-equal dir cwd)
;;                      (not (file-directory-p abs-file-name)))
;;                  (or (null shell-completion-execonly)
;;                      (file-executable-p abs-file-name)))
;;             (setq completions (cons file completions)))
;;         (setq comps-in-dir (cdr comps-in-dir)))
;;       (setq path-dirs (cdr path-dirs)))
;;     ;; OK, we've got a list of completions.
;;     (let ((success (let ((comint-completion-addsuffix nil))
;;                      (comint-dynamic-simple-complete filenondir completions))))
;;       (if (and (memq success '(sole shortest)) comint-completion-addsuffix
;;                (not (file-directory-p (comint-match-partial-filename))))
;;           (insert " "))
;;       success)))

(provide 'powershell)

;;; powershell.el ends here
