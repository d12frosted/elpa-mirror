;;; asn1-mode.el --- ASN.1/GDMO mode for GNU Emacs

;; Filename: asn1-mode.el
;; Package-Requires: ((emacs "24.3") (s "1.10.0"))
;; Package-Version: 20170729.226
;; Package-Commit: d5d4a8259daf708411699bcea85d322f18beb972
;; Description: ASN.1/GDMO Editing Mode
;; Author: Taichi Kawabata <kawabata.taichi_at_gmail.com>
;; Created: 2013-11-22
;; Version: 1.170729
;; Keywords: languages, processes, tools
;; Namespace: asn1-, gdmo-
;; URL: https://github.com/kawabata/asn1-mode/

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

;; * ASN.1/GDMO mode for GNU Emacs
;;
;; This is a major mode for editing ASN.1/GDMO files.
;;
;; ** References
;;
;; - ITU-T X.680 Information technology – Abstract Syntax Notation
;;   One (ASN.1): Specification of basic notation
;;   (http://www.itu.int/ITU-T/recommendations/rec.aspx?rec=9604)
;;
;; - ITU-T X.681 Information technology – Abstract Syntax Notation
;;   One (ASN.1): Information object specification
;;   (http://www.itu.int/ITU-T/recommendations/rec.aspx?rec=9605)
;;
;; - ITU-T X.722: Information Technology – Open Systems
;;   Interconnection – Structure of Management Information:
;;   Guidelines For The Definition of Managed Objects
;;   (http://www.itu.int/ITU-T/recommendations/rec.aspx?rec=3061)

;;; Code:

(require 'smie)
(require 'cl-lib)
(require 's)
(require 'trace)

(declare-function untrace-function "trace.el")

(defvar asn1-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [foo] 'asn1-mode-do-foo)
    map)
  "Keymap for `asn1-mode'.")

(defvar asn1-mode-debug nil)

(defconst asn1-mode-syntax-table
  ;; cf.  X.680 Sec. 12 Lexical Items (12.6 Comments, 12.37, etc.)
  (let ((syntax-table (make-syntax-table)))
    (modify-syntax-entry '(?A . ?Z) "w" syntax-table)
    (modify-syntax-entry '(?a . ?z) "w" syntax-table)
    (modify-syntax-entry '(?0 . ?9) "w" syntax-table)
    (modify-syntax-entry ?!  "."        syntax-table)
    (modify-syntax-entry ?\" "\""       syntax-table)
    (modify-syntax-entry ?&  "w"        syntax-table) ; field reference, cf. X.681/7.
    (modify-syntax-entry ?'  "\""       syntax-table)
    (modify-syntax-entry ?\( "()"       syntax-table)
    (modify-syntax-entry ?\) ")("       syntax-table)
    (modify-syntax-entry ?*  ". 23b"    syntax-table) ; alternative comment
    (modify-syntax-entry ?,  "."        syntax-table)
    (modify-syntax-entry ?.  "."        syntax-table)
    (modify-syntax-entry ?-  "w 1234"   syntax-table) ; word constituent
    (modify-syntax-entry ?/  ". 14b"    syntax-table) ; alternative comment
    (modify-syntax-entry ?:  "."        syntax-table)
    (modify-syntax-entry ?\; "."        syntax-table)
    (modify-syntax-entry ?<  "(>"       syntax-table) ; XML value
    (modify-syntax-entry ?=  "."        syntax-table)
    (modify-syntax-entry ?>  ")<"       syntax-table) ; XML value
    (modify-syntax-entry ?@  "."        syntax-table)
    (modify-syntax-entry ?\[ "(]"       syntax-table)
    (modify-syntax-entry ?\] ")["       syntax-table)
    (modify-syntax-entry ?^  "."        syntax-table)
    (modify-syntax-entry ?_  "."        syntax-table)
    (modify-syntax-entry ?\{ "(}"       syntax-table)
    (modify-syntax-entry ?|  "."        syntax-table)
    (modify-syntax-entry ?\} "){"       syntax-table)
    (modify-syntax-entry ??  "w"        syntax-table)
    (modify-syntax-entry ?\n ">"        syntax-table) ; comment ender
    (modify-syntax-entry ?\t " "        syntax-table)
    (modify-syntax-entry ?   " "        syntax-table)
    syntax-table))

(defconst asn1-mode-keywords
  '(;; ASN.1 (ITU-T X.680 12.38)
      "ABSENT"
      "ABSTRACT-SYNTAX"
      "ALL"
      "APPLICATION"
      "AUTOMATIC"
      "BEGIN"
      "BIT"
      "BMPString"
      "BOOLEAN"
      "BY"
      "CHARACTER"
      "CHOICE"
      "CLASS"
      "COMPONENT"
      "COMPONENTS"
      "CONSTRAINED"
      "CONTAINING"
      "DATE"
      "DATE-TIME"
      "DEFAULT"
      "DEFINITIONS"
      "DURATION"
      "EMBEDDED"
      "ENCODED"
      "ENCODING-CONTROL"
      "END"
      "ENUMERATED"
      "EXCEPT"
      "EXPLICIT"
      "EXPORTS"
      "EXTENSIBILITY"
      "EXTERNAL"
      "FALSE"
      "FROM"
      "GeneralString"
      "GeneralizedTime"
      "GraphicString"
      "IA5String"
      "IDENTIFIER"
      "IMPLICIT"
      "IMPLIED"
      "IMPORTS"
      "INCLUDES"
      "INSTANCE"
      "INSTRUCTIONS"
      "INTEGER"
      "INTERSECTION"
      "ISO646String"
      "MAX"
      "MIN"
      "MINUS-INFINITY"
      "NOT-A-NUMBER"
      "NULL"
      "NumericString"
      "OBJECT"
      "OCTET"
      "OF"
      "OID-IRI"
      "OPTIONAL"
      "ObjectDescriptor"
      "PATTERN"
      "PDV"
      "PLUS-INFINITY"
      "PRESENT"
      "PRIVATE"
      "PrintableString"
      "REAL"
      "RELATIVE-OID"
      "RELATIVE-OID-IRI"
      "SEQUENCE"
      "SET"
      "SETTINGS"
      "SIZE"
      "STRING"
      "SYNTAX"
      "T61String"
      "TAGS"
      "TIME"
      "TIME-OF-DAY"
      "TRUE"
      "TYPE-IDENTIFIER"
      "TeletexString"
      "UNION"
      "UNIQUE"
      "UNIVERSAL"
      "UTCTime"
      "UTF8String"
      "UniversalString"
      "VideotexString"
      "VisibleString"
      "WITH"
      ;; ITU-T X.681
      "OBJECT IDENTIFIER"
      "IDENTIFIED BY"
      "WITH SYNTAX"))

(defconst gdmo-mode-keywords
  (append
   asn1-mode-keywords
   '(;; GDMO (duplicate keywords may appear)
      "MANAGED OBJECT CLASS"
      "DERIVED FROM"
      "CHARACTERIZED BY"
      "CONDITIONAL PACKAGES"
      "PRESENT IF"
      "REGISTERED AS"
      ;;
      "PACKAGE"
      "BEHAVIOUR"
      "ATTRIBUTES"
      "ATTRIBUTE GROUPS"
      "ACTIONS"
      "NOTIFICATIONS"
      ;;
      "SET-BY-CREATE"
      "REPLACE-WITH-DEFAULT"
      "VALUE"
      "INITIAL"
      "PERMITTED"
      "REQUIRED"
      "DERIVATION" "RULE"
      "GET"
      "REPLACE"
      "GET-REPLACE"
      "ADD"
      "REMOVE"
      "ADD-REMOVE"
      ;;
      "PARAMETER"
      "CONTEXT"
      "ACTION-INFO"
      "ACTION-REPLY"
      "EVENT-INFO"
      "EVENT-REPLY"
      "SPECIFIC-ERROR"
      ;;
      "NAME BINDING"
      "SUBORDINATE OBJECT CLASS"
      "AND SUBCLASSES"
      "NAMED BY"
      "SUPERIOR OBJECT CLASS"
      "WITH ATTRIBUTE"
      "CREATE"
      "DELETE"
      "WITH-REFERENCE-OBJECT"
      "WITH-AUTOMATIC-INSTANCE-NAMING"
      "ONLY-IF-NO-CONTAINED-OBJECTS"
      "DELETES-CONTAINED-OBJECTS"
      ;;
      "ATTRIBUTE"
      "WITH ATTRIBUTE SYNTAX"
      "MATCHES FOR"
      "PARAMETERS"
      "EQUALITY"
      "ORDERING"
      "SUBSTRINGS"
      "SET-COMPARISON"
      "SET-INTERSECTION"
      ;;
      "ATTRIBUTE GROUP"
      "GROUP ELEMENTS"
      "FIXED"
      "DESCRIPTION"
      ;;
      ;;"BEHAVIOUR" ; duplicate
      "DEFINED AS"
      ;;
      "ACTION"
      "MODE CONFIRMED"
      "WITH INFORMATION SYNTAX"
      "WITH REPLY SYNTAX"
      ;;
      ;;"NOTIFICATIONS" ; duplicate
      "AND ATTRIBUTE IDS"
      )))

(defconst asn1-mode-keywords-regexp
  (concat
   "\\<"
   (regexp-opt
    (apply 'nconc (mapcar 'split-string asn1-mode-keywords)))
   "\\>")
  "Regexp to match ASN.1 reserved keywords against token.")

(defconst gdmo-mode-keywords-regexp
  (concat
   "\\<"
   (regexp-opt
    (apply 'nconc (mapcar 'split-string gdmo-mode-keywords)))
   "\\>")
  "Regexp to match GDMO reserved keywords against token.")

(defconst asn1-mode-font-lock-keywords
  `(,asn1-mode-keywords-regexp ; font-lock-keyword-face
    ("([0-9]+)" . font-lock-constant-face)
    ("^[[:space:]]*\\(\\w+\\).+?::=" 1 font-lock-variable-name-face)))

(defconst gdmo-mode-font-lock-keywords
  `(,@asn1-mode-font-lock-keywords
    (,(concat
       "\\(\\w+\\)[[:space:]]+"
       (regexp-opt
        '("::="
          "MANAGED OBJECT CLASS"
          "PACKAGE"
          "PARAMETER"
          "NAME BINDING"
          "ATTRIBUTE"
          "ATTRIBUTE GROUP"
          "BEHAVIOUR"
          "ACTION"
          "NOTIFICATION")))
     1 font-lock-function-name-face)))

;;;; abbrev table
(define-abbrev-table 'asn1-mode-abbrev-table ())

;; abbrev table setup
(defun asn1-mode-abbrev-table ()
  ;; automatically define abbrev table.
  (dolist (kw (sort (copy-sequence asn1-mode-keywords)
                  (lambda (a b) (< (length a) (length b)))))
  (let* ((i 1)
         (split (split-string (downcase kw) "[- ]"))
         (base  (apply 'string (mapcar 'string-to-char split)))
         (last  (car (last split)))
         (abbrev base))
    (while (and (abbrev-expansion abbrev asn1-mode-abbrev-table)
                (< i (length last)))
      (setq i (1+ i))
      (setq abbrev (concat base (substring last 1 i))))
    (define-abbrev asn1-mode-abbrev-table abbrev kw))))

;; (insert-abbrev-table-description 'asn1-mode-abbrev-table)

(defvar asn1-mode-imenu-expression '((nil "^\\([A-Za-z-_]+\\).*::=.*" 1)))

;;;; outline

;; Default outline regexp is based on section number appeared on comment header.
;; e.g.
;; -- 1 <section name>
;; -- 1.1 <subsection name>
;; -- 1.1.1 <subsubsection name>
(defvar asn1-mode-outline-regexp "-- +[0-9]+\\(\\.[0-9]+\\)* ")
(defun asn1-mode-outline-level ()
  "Calculcate outline level of ASN.1 text."
  (1+ (cl-count ?. (match-string 0))))

;; Lexical Tokenizer

(defun asn1-mode-regexp-opt (&rest list)
  (concat "\\b" (regexp-opt list t) "\\b"))

(defvar asn1-mode-token-alist
  `(("_TAG_KIND" . ,(asn1-mode-regexp-opt "IMPLICIT" "EXPLICIT" "AUTOMATIC"))
    ("_WITH_SYNTAX" . "\\b\\(WITH SYNTAX\\)\\b")
    ("_CLASS" . "\\(CLASS\\)")
    ("TAGS" . "\\b\\(TAGS\\)\\b")
    ("DEFINITIONS" . "\\b\\(DEFINITIONS\\)\\b")
    ("EXPORTS" . "\\b\\(EXPORTS\\)\\b")
    ("BEGIN" . "\\b\\(BEGIN\\)\\b")
    ("END" . "\\b\\(END\\)\\b")
    ("SIZE" . "\\b\\(SIZE\\)\\b")
    ("OF" . "\\b\\(OF\\)\\b")
    ("IMPORTS" . "\\b\\(IMPORTS\\)\\b")
    ("_SET" . ,(asn1-mode-regexp-opt "SET OF" "SEQUENCE OF"))
    ("_SEQ" . ,(asn1-mode-regexp-opt "SEQUENCE" "CHOICE" "ENUMERATED"))
    ("_UCASE_ID" .
     ,(asn1-mode-regexp-opt "OBJECT IDENTIFIER" "BIT STRING" "OCTET STRING"))
    ("_LITERAL"  . "\\b\\([0-9]+\\)\\b")
    ("_XML_OPENER" . "\\(<[^<>/]+>\\)")
    ("_XML_CLOSER" . "\\(</[^<>/]+>\\)")
    ("_XML_SINGLE" . "\\(<[^<>/]+/>\\)")
    ("..." . "\\(\\.\\.\\.\\)")
    ("::=" . "\\(::=\\)")))

(defvar gdmo-mode-token-alist
  `(,@asn1-mode-token-alist
    ("_GDMO_OPEN"
     . ,(asn1-mode-regexp-opt
         ;; template
         "MANAGED OBJECT CLASS"
         "BEHAVIOUR"
         "NAME BINDING"
         "PACKAGE"
         ;; To avoid conflict with `WITH ATTRIBUTE', define separately.
         ;; "ATTRIBUTE"
         "ACTION"
         "NOTIFICATION"
         "PARAMETER"
         "ATTRIBUTE GROUP"
         ;; supportings
         "DERIVED FROM"
         "CHARACTERIZED BY"
         "CONDITIONAL PACKAGES"
         "SUBORDINATE OBJECT CLASS"
         "NAMED BY SUPERIOR OBJECT CLASS"
         "WITH ATTRIBUTE"
         "CREATE"
         "DELETE"
         "ATTRIBUTES"
         "ATTRIBUTE GROUPS"
         "ACTIONS"
         "NOTIFICATIONS"
         "MODE CONFIRMED"
         "PARAMETERS"
         "WITH INFORMATION SYNTAX"
         "WITH REPLY SYNTAX"
         "CONTEXT"
         "GROUP ELEMENTS"
         "FIXED"
         "DESCRIPTION"))
    ("_REGISTERED_AS" .
     "\\b\\(REGISTERED AS\\)\\b")))

(defconst asn1-mode-token-alist-2
  `(("FROM" . "\\b\\(FROM\\)\\b")
    ("_LCASE_ID" . "\\b\\([a-z&]\\(?:\\w\\|\\s_\\)+\\)\\b")
    ("_UCASE_ID" . "\\b\\([A-Z]\\(?:\\w\\|\\s_\\)+\\)\\b")))

(defconst gdmo-mode-token-alist-2
  `(,@asn1-mode-token-alist-2
    ("_GDMO_OPEN" . "\\b\\(ATTRIBUTE\\)\\b")))

(defconst asn1-mode-token-regexp
  (mapconcat (lambda (p) (concat (cdr p) )) asn1-mode-token-alist "\\|"))

(defconst asn1-mode-token-regexp-2
  (mapconcat (lambda (p) (concat (cdr p) )) asn1-mode-token-alist-2 "\\|"))

(defconst gdmo-mode-token-regexp
  (mapconcat (lambda (p) (concat (cdr p) )) gdmo-mode-token-alist "\\|"))

(defconst gdmo-mode-token-regexp-2
  (mapconcat (lambda (p) (concat (cdr p) )) gdmo-mode-token-alist-2 "\\|"))

(defun asn1-mode-token-match-group (match-data regexp-alist)
  (car (nth (/ (cl-position-if-not 'null (cddr (match-data))) 2)
            regexp-alist)))

(defun asn1-mode-forward-token ()
  (forward-comment (point-max))
  (skip-syntax-forward " ")
  (let ((case-fold-search nil))
    (condition-case nil ; for scan-error
        (cond
         ((looking-at asn1-mode-token-regexp)
          (goto-char (match-end 0))
          (asn1-mode-token-match-group (match-data) asn1-mode-token-alist))
         ((looking-at asn1-mode-token-regexp-2)
          (goto-char (match-end 0))
          (asn1-mode-token-match-group (match-data) asn1-mode-token-alist-2))
         ((looking-at "\\s\"") (goto-char (scan-sexps (point) 1)) "_LITERAL")
         ((looking-at "{")     (goto-char (scan-sexps (point) 1)) "_BRACE")
         ((looking-at "[([]")  (goto-char (scan-sexps (point) 1)) "_PAREN")
         (t (buffer-substring-no-properties
             (point)
             (progn
               (if (zerop (skip-syntax-forward "w_"))
                   (forward-char 1))
               (point)))))
      (scan-error (forward-char) (char-to-string (char-before (point)))))))

(defun asn1-mode-backward-token ()
  (forward-comment (- (point)))
  (skip-syntax-backward " ")
  (let ((case-fold-search nil))
    (condition-case nil ; for scan-error
        (cond
         ((bobp) nil)
         ((looking-back asn1-mode-token-regexp nil)
          (goto-char (match-beginning 0))
          (asn1-mode-token-match-group (match-data) asn1-mode-token-alist))
         ((looking-back asn1-mode-token-regexp-2 nil)
          (goto-char (match-beginning 0))
          (asn1-mode-token-match-group (match-data) asn1-mode-token-alist-2))
         ((looking-back "\\s\"" nil) (goto-char (scan-sexps (point) -1)) "_LITERAL")
         ((looking-back "}" nil)     (goto-char (scan-sexps (point) -1)) "_BRACE")
         ((looking-back "[])]" nil)  (goto-char (scan-sexps (point) -1)) "_PAREN")
         (t (buffer-substring-no-properties
             (point)
             (progn
               (if (zerop (skip-syntax-backward "w_"))
                   (forward-char -1))
               (point)))))
      (scan-error (forward-char -1) (char-to-string (char-after (point)))))))

(defvar asn1-mode-smie-grammar
  (smie-prec2->grammar
   (smie-bnf->prec2
    `(
      (empty)
      (module-body
       ("DEFINITIONS" tag "::=" begin-end))
      (tag
       (empty)
       ("_TAG_KIND" "TAGS"))
      (begin-end
       ("BEGIN" module-body2 "END"))
      (module-body2
       (exports)
       (imports)
       (assignment))
      (exports
       ("EXPORTS" tokens ";"))
      (imports
       ("IMPORTS" imports-body ";"))
      (imports-body
       (import-labels "FROM" "_UCASE_ID" brace))
      (assignment
       (ucase-id "::=" brace)
       (ucase-id "::=" type)
       (ucase-id "::=" value)
       (ucase-id "::=" xmlvalue)
       (ucase-id "::=" objectclass)
       (brace "::=" type))
      (brace
       ("_BRACE")
       ;;("{" tokens "}")
       )
      (import-labels
       (ucase-id)
       (import-labels "," import-labels)
       (import-labels "," import-labels))
      (ucase-id
       ("_UCASE_ID"))
      (objectclass
       ("_CLASS" "_BRACE" with-syntax))
      (with-syntax
       ("_WITH_SYNTAX" brace))
      (type
       ("_UCASE_ID")
       ("_SET" type)
       ("_SEQ" brace)
       ("_SEQ" size "OF" brace))
      (size
       ("SIZE" paren))
      (value
       (type ":" value)
       (type "." value)
       ("_LCASE_ID")
       ("_LITERAL"))
      (tokens
       (type)
       (value)
       (tokens "," tokens)
       (tokens "|" tokens))
      (token
       ("_UCASE_ID")
       ("_LCASE_ID"))
      (paren
       ("_PAREN")
       ("[" value "]")
       ("(" value ")"))
      (xml-value
       ("_XML_SINGLE")
       ("_XML_OPENER" xml-value "_XML_CLOSER")
       (tokens))
      ;; GDMO
      ;; cf. ITU-T X.722
      (gdmo
       ("_GDMO_OPEN" gdmo-inside ";")
       ("_WITH_SYNTAX" gdmo-inside ";"))
      (gdmo-inside
       (gdmo)
       (gdmo-inside "," gdmo-inside)
       ("_LCASE_ID")
       ("_UCASE_ID")))
    '((assoc "_UCASE_ID" "_LCASE_ID" "," "|")))))

(defun asn1-mode-debug (&rest message)
  (let ((message (apply 'format message)))
    (with-current-buffer (get-buffer-create "*trace-output*")
      (insert message "\n"))))

(defun asn1-mode-backward-token-to (token)
  (while (not (equal (asn1-mode-backward-token) token))))

(defun asn1-mode-smie-rules (kind token)
  "ASN.1 SMIE indentation function for KIND and TOKEN."
  (when asn1-mode-debug
    (asn1-mode-debug "position=%s" (point))
    (asn1-mode-debug "smie-rule-bolp=%s" (smie-rule-bolp))
    (asn1-mode-debug "hanging-p=%s" (smie-rule-hanging-p))
    (asn1-mode-debug "sibling-p=%s" (smie-rule-sibling-p))
    (asn1-mode-debug "indent-parent=%s" (nth 2 (smie-indent--parent))))
  (pcase (cons kind token)
    ;; :before
    (`(:before . ,(or `"IMPORTS" `"EXPORTS"))
     (smie-rule-parent))
    (`(:before . "END") nil)
    ;; if _BRACE is hanging, then the position of "}" is the same as
    ;; indentation of "{" for ASN.1.
    (`(:before . ,(or `"_PAREN" "_BRACE"))
     (if (smie-rule-hanging-p) `(column . ,(current-indentation))))
    (`(:before . ,(or `"," `"|" `"."))
     (if (smie-rule-parent-p "{")
         ;; when parent is {, then indentation should be based on this.
         (save-excursion
           (asn1-mode-backward-token-to "{")
           `(column . ,(+ smie-indent-basic (current-indentation))))
       `(column . ,(current-indentation))))
    (`(:before . "_GDMO_OPEN")
     nil)
    ;; Default is nil, unless parent is "::=".
    (`(:before . ,_) ; for the rest
     (if (smie-rule-parent-p "::=")
       (save-excursion
         (asn1-mode-backward-token-to "::=")
         `(column . ,(current-indentation)))
       (if (smie-rule-parent-p "_BRACE")
           (save-excursion
             (asn1-mode-backward-token-to "_BRACE")
             `(column . ,(current-indentation))))))
    ;; :after
    (`(:after . ";")
     nil)
    ;; AFTER open parenthesis, basic + current indentation is appropriate.
    (`(:after . ,`"_XML_OPENER")
     smie-indent-basic)
    (`(:after . ,(or `"::=" `"{" `"(" `"_GDMO_OPEN" `"IMPORTS" `"EXPORTS"))
     ;;smie-indent-basic)
     `(column . ,(+ smie-indent-basic (current-indentation))))
    ;; for any AFTER, if parent is "::=", then its current-indentation is indentation.
    (`(:after . ,_)
     (if (smie-rule-parent-p "::=")
         (save-excursion
           (asn1-mode-backward-token-to "::=")
           `(column . ,(current-indentation)))))
    ;; misc
    (`(:list-intro . ,_) t)
    (`(:elem . ,_) 0)
    (_ nil)))

(defun asn1-mode-toggle-debug ()
  "Toggle variable `asn1-mode-debug'."
  (interactive)
  (require 'trace)
  (setq asn1-mode-debug (not asn1-mode-debug))
  (message "asn1-mode-debug is %s" asn1-mode-debug)
  (if asn1-mode-debug
      (trace-function 'asn1-mode-smie-rules)
    (untrace-function 'asn1-mode-smie-rules)))

(defun asn1-mode-common-setup ()
  "Local variable settings common to ASN.1/GDMO."
  ;; set local variables
  (smie-setup asn1-mode-smie-grammar #'asn1-mode-smie-rules
              :forward-token 'asn1-mode-forward-token
              :backward-token 'asn1-mode-backward-token)
  ;;(set-syntax-table asn1-mode-syntax-table)
  (asn1-mode-abbrev-table)
  (setq-local parse-sexp-ignore-comments t)
  (setq-local tab-width 4)
  (setq-local comment-start "--")
  (setq-local comment-end "") ; comment ends at end of line
  (setq-local comment-start-skip nil)
  (setq-local outline-regexp asn1-mode-outline-regexp)
  (setq-local outline-level 'asn1-mode-outline-level)
  (setq-local imenu-generic-expression asn1-mode-imenu-expression))

;;;###autoload
(define-derived-mode asn1-mode prog-mode "ASN.1"
  "Major mode for editing ASN.1 text files in Emacs.

\\{asn1-mode-map}
Entry to this mode calls the value of `asn1-mode-hook'
if that value is non-nil."
  :syntax-table asn1-mode-syntax-table
  :abbrev-table asn1-mode-abbrev-table
  (asn1-mode-common-setup)
  (setq-local font-lock-defaults '(asn1-mode-font-lock-keywords nil nil)))


;;;###autoload
(define-derived-mode gdmo-mode prog-mode "GDMO"
  "Major mode for editing GDMO text files in Emacs.

\\{asn1-mode-map}
Entry to this mode calls the value of `asn1-mode-hook'
if that value is non-nil."
  :syntax-table asn1-mode-syntax-table
  :abbrev-table asn1-mode-abbrev-table
  (asn1-mode-common-setup)
  (setq-local font-lock-defaults '(gdmo-mode-font-lock-keywords nil nil)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.asn1$" . asn1-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.gdmo$" . gdmo-mode))
;;(add-to-list 'auto-mode-alist '("\\.mo$" . gdmo-mode))

(provide 'asn1-mode)

;; Local Variables:
;; time-stamp-pattern: "10/Version:\\\\?[ \t]+1.%02y%02m%02d\\\\?\n"
;; End:

;;; asn1-mode.el ends here
