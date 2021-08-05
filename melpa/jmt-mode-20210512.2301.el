;;; jmt-mode.el --- Java Mode Tamed  -*- lexical-binding: t; -*-

;; Copyright © 2019-2021 Michael Allan.
;;
;; Author: Michael Allan <mike@reluk.ca>
;; Version: 0-snapshot
;; Package-Version: 20210512.2301
;; Package-Commit: c5cc024a06684b91da9bb05fecf681426596af5e
;; SPDX-License-Identifier: MIT
;; Package-Requires: ((emacs "24.4"))
;; Keywords: c, languages
;; URL: http://reluk.ca/project/Java/Emacs/
;;
;; This file is not part of GNU Emacs.
;;
;; This file is released under an MIT licence.  A copy of the licence normally accompanies it.
;; If not, then see `http://reluk.ca/project/Java/Emacs/LICENCE.txt`.

;;; Commentary:

;;   This package introduces a derived major mode (`jmt-mode`) that affords better control
;;   of the Java mode built into Emacs, particularly in regard to syntax highlighting.
;;   For more information, see `http://reluk.ca/project/Java/Emacs/`.
;;
;; Installation
;;
;;   If you install this package from MELPA using a package manager, then already `jmt-mode`
;;   should activate for any loaded file that has either a `.java` extension or `java` shebang.
;;   Alternatively you may want to install the mode manually:
;;
;;       1. Put a copy of the present file on your load path.
;;          https://www.gnu.org/software/emacs/manual/html_node/elisp/Library-Search.html
;;
;;       2. Optionally compile that copy.  E.g. load it into an Emacs buffer and type
;;          `M-x emacs-lisp-byte-compile`.
;;
;;       3. Add the following code to your initialization file.
;;          https://www.gnu.org/software/emacs/manual/html_node/emacs/Init-File.html
;;
;;             (autoload 'jmt-mode "jmt-mode" nil t)
;;             (set 'auto-mode-alist (cons (cons "\\.java\\'" 'jmt-mode) auto-mode-alist))
;;             (set 'interpreter-mode-alist
;;                  (cons (cons "\\(?:--split-string=\\|-S\\)?java" 'jmt-mode)
;;                        interpreter-mode-alist))
;;
;;          The `interpreter-mode-alist` entry is for source-launch files encoded with a shebang. [SLS]
;;
;;   For a working example of manual installation, see the relevant lines
;;   of `http://reluk.ca/.config/emacs/lisp/initialization.el`, and follow the reference there.
;;
;; Changes to Emacs
;;
;;   This package applies monkey patches to the runtime session that redefine parts of built-in packages
;;   CC Mode and Font Lock.  The patches are applied on first entrance to `jmt-mode`.  Most of them apply
;;   to function definitions, in which case they are designed to leave the behaviour of Emacs unchanged
;;   in all buffers except those running `jmt-mode`.  The patched functions are:
;;
;;       c-before-change
;;       c-fontify-recorded-types-and-refs
;;       c-font-lock-<>-arglists
;;       c-font-lock-declarations
;;       c-font-lock-doc-comments
;;       font-lock-fontify-region-function
;;
;;   Moreover, one variable is patched:
;;
;;       javadoc-font-lock-doc-comments - To allow for upper case letters in Javadoc block tags.

;;; Code:


;; The `Package-Requires` version of Emacs (above) was obtained from `package-lint-current-buffer`.
(eval-when-compile (require 'cl-lib)); Built into Emacs since version 24.3.
(require 'cc-mode); Among other programming modes, it defines Java Mode.
  ;;; https://www.gnu.org/software/emacs/manual/html_node/ccmode/index.html



;; ══════════════════════════════════════════════════════════════════════════════════════════════════════
;;  P r e l i m i n a r y   d e c l a r a t i o n s
;; ══════════════════════════════════════════════════════════════════════════════════════════════════════


(defun jmt-make-Javadoc-tag-facing (f)
  "Make a face property for a Javadoc tag using face F (symbol) as a base."
  (list f 'font-lock-doc-face)); [PJF]



(defconst jmt-name-character-set "[:alnum:]_$" "\
The set of characters from which a Java identifier may be formed.")
  ;;; https://docs.oracle.com/javase/specs/jls/se15/html/jls-3.html#jls-3.8



(defvar jmt-value-tag-name-f); [FV]



;; ══════════════════════════════════════════════════════════════════════════════════════════════════════
;;  D e c l a r a t i o n s   i n   l e x i c o g r a p h i c   o r d e r
;; ══════════════════════════════════════════════════════════════════════════════════════════════════════


(defgroup delimiter-faces nil "\
Faces for Java separators and other delimiters."
  :group 'jmt
  :prefix "jmt-")



(defgroup javadoc-faces nil "\
Faces for Java API descriptions."
  :group 'jmt
  :prefix "jmt-")



(defgroup jmt nil "\
Customizable items of Java Mode Tamed."
  :group 'languages :group 'faces
  :prefix "jmt-"
  :tag "JMT"
  :link '(url-link "http://reluk.ca/project/Java/Emacs/"))



(defface jmt-angle-bracket `((t . (:inherit jmt-bracket))) "\
The face for an angle bracket, ‘<’ or ‘>’."
  :group 'delimiter-faces)



(defface jmt-annotation-delimiter; This non-replacement face inherits from `c-annotation-face` only
    ;;; for sake of `jmt-is-annotation-terminal-face` and replacement subface `jmt-annotation-mark`.
  `((t . (:inherit c-annotation-face))) "\
The face for the ‘@’, ‘(’ and ‘)’ delimiters of annotation.
Customize it to better distinguish the delimiters from the content
they delimit; making them more prominent or less prominent, for example.
See also ‘jmt-delimiter’ and the faces that inherit from it."
  :group 'delimiter-faces)



(defface jmt-annotation-mark; [RF]
  `((t . (:inherit jmt-annotation-delimiter))) "\
The face for the ‘@’ symbol denoting annotation."
  :group 'delimiter-faces)



(defface jmt-annotation-package-name; [MDF, RF]
  `((t . (:inherit jmt-package-name))) "\
The face for each segment of a package name in an annotation type reference.
It defaults to ‘jmt-package-name’; customize it if the default fits poorly
with your other annotation faces."
  :group 'jmt)



(defface jmt-annotation-string; [BC, LF, RF]
  `((t . (:inherit font-lock-string-face))) "\
The face for a string in an annotation qualifier.  It defaults
to ‘font-lock-string-face’; customize it if the default fits poorly
with your other annotation faces."
  :group 'jmt)



(defface jmt-annotation-string-delimiter; [BC, LF, RF]
  `((t . (:inherit jmt-string-delimiter))) "\
The face for a string delimiter in an annotation qualifier.  It defaults
to ‘jmt-string-delimiter’; customize it if the default fits poorly with your
other annotation faces."
  :group 'delimiter-faces)



(defface jmt-annotation-qualifier `((t . (:inherit c-annotation-face))) "\
The face for the element assignments of annotation.  Customize it
e.g. to give the assignments less prominence than the ‘c-annotation-face’
of the preceding type name."
  :group 'jmt)



(defface jmt-block-tag-name; [NDF, RF]
  `((t . (:inherit jmt-Javadoc-tag-name))) "\
The face for the proper identifier of a Javadoc block tag."
  :group 'javadoc-faces)

(defconst jmt-block-tag-name-f (jmt-make-Javadoc-tag-facing 'jmt-block-tag-name))



(defface jmt-block-tag-parameter; [CI]
  `((t . (:inherit font-lock-doc-face))) "\
The face for a non-descriptive parameter of a Javadoc block tag.
See also subfaces ‘jmt-param-tag-parameter’ and ‘jmt-throws-tag-parameter’."
  :group 'javadoc-faces)



(defface jmt-boilerplate-keyword; [MDF, RF]
  `((t . (:inherit jmt-principal-keyword))) "\
The face for the keyword of a formal Java declaration in the preamble
of a compilation unit."
  :group 'keyword-faces)



(defface jmt-bracket `((t . (:inherit jmt-delimiter))) "\
The face for a bracket.  See also ‘jmt-angle-bracket’, ‘jmt-curly-bracket’,
‘jmt-round-bracket’ and ‘jmt-square-bracket’."
  :group 'delimiter-faces)



(defun jmt--c-put-face-tamed (beg end face)
  "Call ‘c-put-font-lock-face’ with BEG END constrained to a valid region.
The given region is never constrained when ‘jmt-mode’ is inactive, in which
case the call is simply passed through as \\=`c-put-font-lock-face BEG END FACE\\=`.
Otherwise, before calling \\=`c-put-font-lock-face\\=`, BEG and END are clipped
to the region presently under fontification by Font Lock."
  (defvar jmt--is-level-3); [FV]
  (defvar jmt--present-fontification-beg)
  (defvar jmt--present-fontification-end)
  (if (and jmt--is-level-3
           (eq major-mode 'jmt-mode))
      (progn
        (setq beg (max beg jmt--present-fontification-beg)
              end (min end jmt--present-fontification-end))
        (when (< beg end) (c-put-font-lock-face beg end face)))
    (c-put-font-lock-face beg end face)))



(defun jmt--c-put-face-unless-wild (beg end face)
  "Call ‘c-put-font-lock-face’ on condition BEG END delimits a valid region.
The given region is always judged valid when ‘jmt-mode’ is inactive, in which
case the call is simply passed through as \\=`c-put-font-lock-face BEG END FACE\\=`.
Otherwise the call is passed through only if BEG and END lie within the region
presently under fontification by Font Lock."
  (defvar jmt--is-level-3); [FV]
  (defvar jmt--present-fontification-beg)
  (defvar jmt--present-fontification-end)
  (if (and jmt--is-level-3
           (eq major-mode 'jmt-mode))
      (unless (or
               (> end jmt--present-fontification-end)
               (< beg jmt--present-fontification-beg))
        (c-put-font-lock-face beg end face))
    (c-put-font-lock-face beg end face)))



(defface jmt-curly-bracket `((t . (:inherit jmt-bracket))) "\
The face for a curly bracket, ‘{’ or ‘}’."
  :group 'delimiter-faces)



(defface jmt-delimiter nil "\
The face for a delimiter not already faced by Java Mode.  Customize it
to better distinguish the delimiters from the content they delimit; making them
more prominent or less prominent, for example.  See also subfaces ‘jmt-bracket’
‘jmt-separator’.  And for delimiters that *are* already faced by Java Mode,
see ‘jmt-annotation-delimiter’, ‘jmt-annotation-mark’, ‘jmt-string-delimiter’
and ‘font-lock-comment-delimiter-face’."
  :group 'delimiter-faces)



(defvar jmt--early-initialization-was-begun nil)



(defface jmt-expression-keyword; [MDF, RF]
  `((t . (:inherit jmt-principal-keyword))) "\
The face for the keyword of an operator or other element
of a formal Java expression."
  :group 'keyword-faces)



(defvar jmt-f); [GVF]



(defun jmt-faces-are-equivalent (f1 f2)
  "Tell whether Java Mode should treat face symbols F1 and F2 as equivalent."
  (eq (jmt-untamed-face f1) (jmt-untamed-face f2))); [RF]



(defface jmt-HTML-end-tag-name; [NDF, RF]
  `((t . (:inherit jmt-HTML-tag-name))) "\
The face for the tag name in the end tag of an HTML element
in a Javadoc comment."
  :group 'javadoc-faces)

(defconst jmt-HTML-end-tag-name-f (jmt-make-Javadoc-tag-facing 'jmt-HTML-end-tag-name))



(defface jmt-HTML-start-tag-name; [NDF, RF]
  `((t . (:inherit jmt-HTML-tag-name))) "\
The face for the tag name in the start tag of an HTML element
in a Javadoc comment."
  :group 'javadoc-faces)

(defconst jmt-HTML-start-tag-name-f (jmt-make-Javadoc-tag-facing 'jmt-HTML-start-tag-name))



(defface jmt-HTML-tag-name; [NDF, RF]
  `((t . (:inherit jmt-Javadoc-tag-name))) "\
The face for the tag name of an HTML element in a Javadoc comment.
See also subfaces ‘jmt-HTML-start-tag-name’ and ‘jmt-HTML-end-tag-name’."
  :group 'javadoc-faces)



(defconst jmt-identifier-pattern (concat "[" jmt-name-character-set "]+") "\
The regular-expression pattern of a Java identifier.")



(defface jmt-inline-rendered-parameter; [NDF, RF]
  `((t . (:inherit jmt-inline-tag-parameter))) "\
The face for a rendered parameter of a Javadoc inline tag; one that appears
more-or-less literally in the resulting Javadocs, that is."
  :group 'javadoc-faces)

(defconst jmt-inline-rendered-parameter-f (jmt-make-Javadoc-tag-facing 'jmt-inline-rendered-parameter))



(defface jmt-inline-tag-name; [NDF, RF]
  `((t . (:inherit jmt-Javadoc-tag-name))) "\
The face for the proper identifier of a Javadoc inline tag."
  :group 'javadoc-faces)

(defconst jmt-inline-tag-name-f (jmt-make-Javadoc-tag-facing 'jmt-inline-tag-name))



(defface jmt-inline-tag-parameter; [NDF, RF]
  `((t . (:inherit jmt-Javadoc-tag))) "\
The face for a parameter of a Javadoc inline tag, or attribute of an HTML tag.
See also subface ‘jmt-inline-rendered-parameter’. And for block tags,
see ‘jmt-block-tag-parameter’."
  :group 'javadoc-faces)

(defconst jmt-inline-tag-parameter-f (jmt-make-Javadoc-tag-facing 'jmt-inline-tag-parameter))



(defun jmt-is-annotation-ish-before (p)
  "Tell whether the position before P (integer) might be within annotation."
  (let ((f (get-text-property (1- p) 'face)))
    (or (eq 'c-annotation-face (jmt-untamed-face f))
        (eq 'jmt-annotation-string f)
        (eq 'jmt-annotation-string-delimiter f)
        (eq 'jmt-annotation-package-name f); A package name in an annotation type reference.
        (and (eq 'jmt-separator f) (= ?. (char-before p)))))); A dot ‘.’ in the package name.



(defun jmt-is-annotation-terminal-face (f)
  "Tell whether face F (symbol) might occur on the last character of annotation."
  (eq 'c-annotation-face (jmt-untamed-face f)))



(defun jmt-is-Java-Mode-tag-faced (p)
  "Tell whether face property P (symbol or list) might occur on a Javadoc tag."
  (and (consp p); Testing for precisely `(font-lock-constant-face font-lock-doc-face)`. [PJF]
       (eq 'font-lock-constant-face (car p))
       (eq 'font-lock-doc-face (car (setq p (cdr p))))
       (null (cdr p))))



(defun jmt-is-Java-Mode-type-face (f)
  "Tell whether face F (symbol) is a type face that Java Mode might have set."
  (eq f 'font-lock-type-face)); Java Mode sets this face alone.



(defvar-local jmt--is-level-3 nil); An in-buffer cache of this boolean flag.  It works only because any
  ;;; ‘customization of `font-lock-maximum-decoration` should be done *before* the file is visited’.
  ;;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Font-Lock.html



(defun jmt-is-type-declarative-keyword (s)
  "Tell whether string S is the principal keyword of a type declaration."
  (or (string= s "class")
      (string= s "interface")
      (string= s "enum")
      (string= s "record"))); [R]



(defun jmt-is-type-modifier-keyword (s)
  "Tell whether string S is a type declaration modifier in keyword form."
  ;; Keyword form as opposed e.g. to annotation form, that is."
  ;;     `ClassModifier` https://docs.oracle.com/javase/specs/jls/se15/html/jls-8.html#jls-8.1.1
  ;; `InterfaceModifier` https://docs.oracle.com/javase/specs/jls/se15/html/jls-9.html#jls-9.1.1
  (or (string= s "public")
      (string= s "final")
      (string= s "static")
      (string= s "private")
      (string= s "abstract")
      (string= s "protected")
      (string= s "srictfp")))



(defface jmt-Javadoc-outer-delimiter; [CI]
  `((t . (:inherit font-lock-doc-face))) "\
The face for the outermost delimiters \\=`/**\\=` and \\=`*/\\=` that between them
contain a Javadoc comment, and for the left-marginal asterisks \\=`*\\=`
that may lead any of its lines.  Customize it to better distinguish
the delimiters from the content they delimit; making them more prominent
or less prominent, for example."
  :group 'delimiter-faces :group 'javadoc-faces)



(defface jmt-Javadoc-tag; [NDF, RF]
  `((t . (:inherit font-lock-constant-face))) "\
The face for a Javadoc or HTML tag embedded in a Javadoc comment.
It inherits from ‘font-lock-constant-face’; customize it to distinguish
Javadoc tags from other constructs that use ‘font-lock-constant-face’.
See also subfaces ‘jmt-Javadoc-tag-delimiter’, ‘jmt-Javadoc-tag-name’
and  ‘jmt-inline-tag-parameter’."
  :group 'javadoc-faces)



(defface jmt-Javadoc-tag-delimiter; [NDF, RF]
  `((t . (:inherit jmt-Javadoc-tag))) "\
The face for the ‘@’, ‘{’ and ‘}’ delimiters of a Javadoc tag,
and the ‘<’, ‘</’, ‘/>’ and ‘>’ delimiters of an HTML tag.
Customize it to better distinguish the delimiters from the content
they delimit; making them more prominent or less prominent, for example.
See also subface ‘jmt-Javadoc-tag-mark’."
  :group 'javadoc-faces)

(defconst jmt-Javadoc-tag-delimiter-f (jmt-make-Javadoc-tag-facing 'jmt-Javadoc-tag-delimiter))



(defface jmt-Javadoc-tag-mark; [NDF, RF]
  `((t . (:inherit jmt-Javadoc-tag-delimiter))) "\
The face for the ‘@’ symbol denoting a Javadoc tag."
  :group 'javadoc-faces)

(defconst jmt-Javadoc-tag-mark-f (jmt-make-Javadoc-tag-facing 'jmt-Javadoc-tag-mark))



(defface jmt-Javadoc-tag-name; [NDF, RF]
  `((t . (:inherit jmt-Javadoc-tag))) "\
The face for the proper identifier of a Javadoc or HTML tag.  See also subfaces
‘jmt-block-tag-name’, ‘jmt-inline-tag-name’ and ‘jmt-HTML-tag-name’."
  :group 'javadoc-faces)

(defconst jmt-Javadoc-tag-name-f (jmt-make-Javadoc-tag-facing 'jmt-Javadoc-tag-name))



(defun jmt-keyword-face (keyword beg end)
  "Give the face (symbol) proper to a KEYWORD of Java (string).
The buffer position of the keyword is from BEG (number, inclusive)
to END (exclusive).  Point is left indeterminate."
  (defvar jmt-keyword-face-alist); [FV]
  (let ((f (assoc keyword jmt-keyword-face-alist)))
    (if (not f) 'jmt-principal-keyword; Giving either a default face,
      (setq f (cdr f))                ; or, from `jmt-keyword-face-alist`,
      (if (not (functionp f)) f       ; a face either directly named
        (funcall f beg end)))))       ; or got from a named function.



(defconst jmt-keyword-face-alist
  '(
    ;; Frequent
    ;; ────────
    ("assert"       .     jmt-principal-keyword); Of a statement.
;;; ("boolean"      .          jmt-type-keyword); (but faced rather as a type by Java Mode)
    ("break"        .     jmt-principal-keyword); Of a statement.
    ("else"         .     jmt-principal-keyword); Of a statement clause.
    ("final"        .     jmt-qualifier-keyword)
    ("if"           .     jmt-principal-keyword); Of a statement.
    ("import"       .   jmt-boilerplate-keyword)
;;; ("int"          .          jmt-type-keyword); (but faced rather as a type by Java Mode)
;;; ("long"         .          jmt-type-keyword); (but faced rather as a type by Java Mode)
    ("private"      .     jmt-qualifier-keyword)
    ("public"       .     jmt-qualifier-keyword)
    ("return"       .     jmt-principal-keyword); Of a statement.
    ("static"       .   jmt-keyword-face-static); (q.v.)

    ;; Infrequent; typically a few times per buffer
    ;; ──────────
    ("abstract"     .     jmt-qualifier-keyword)
    ("case"         .     jmt-principal-keyword); Of a statement clause.
    ("catch"        .     jmt-principal-keyword); Of a statement clause.
;;; ("char"         .          jmt-type-keyword); (but faced rather as a type by Java Mode)
    ("class"        .    jmt-keyword-face-class); (q.v.)
    ("continue"     .     jmt-principal-keyword); Of a statement.
    ("default"      .  jmt-keyword-face-default); (q.v.)
;;; ("float"        .          jmt-type-keyword); (but faced rather as a type by Java Mode)
    ("for"          .     jmt-principal-keyword); Of a statement.
    ("new"          .    jmt-expression-keyword)
    ("protected"    .     jmt-qualifier-keyword)
    ("super"        .    jmt-expression-keyword)
    ("synchronized" .     jmt-keyword-face-sync); (q.v.)
    ("this"         .    jmt-expression-keyword)
    ("throw"        .     jmt-principal-keyword); Of a statement.
    ("throws"       .     jmt-qualifier-keyword)
    ("try"          .     jmt-principal-keyword); Of a statement.
;;; ("void"         .          jmt-type-keyword); (but faced rather as a type by Java Mode)
    ("while"        .     jmt-principal-keyword); Of a statement.

    ;; Rare; typically once per buffer, if at all
    ;; ────
;;; ("_"            .       jmt-misused-keyword); (reserved, yet unfaced by Java Mode)
;;; ("byte"         .          jmt-type-keyword); (but faced rather as a type by Java Mode)
    ("const"        .     jmt-qualifier-keyword); (but reserved)
    ("enum"         .     jmt-principal-keyword); Of a type declaration.
    ("do"           .     jmt-principal-keyword); Of a statement.
;;; ("double"       .          jmt-type-keyword); (but faced rather as a type by Java Mode)
    ("extends"      .     jmt-qualifier-keyword)
    ("finally"      .     jmt-principal-keyword); Of a statement clause.
    ("goto"         .     jmt-principal-keyword); Of a statement (but reserved)
    ("implements"   .     jmt-qualifier-keyword)
    ("instanceof"   .    jmt-expression-keyword)
    ("interface"    .     jmt-principal-keyword); Of a type declaration.
    ("native"       .     jmt-qualifier-keyword)
    ("package"      .   jmt-boilerplate-keyword)
    ("record"       .     jmt-principal-keyword); Of a type declaration. [R]
;;; ("short"        .          jmt-type-keyword); (but faced rather as a type by Java Mode)
    ("strictfp"     .     jmt-qualifier-keyword)
    ("switch"       .     jmt-principal-keyword); Of a statement.
    ("transient"    .     jmt-qualifier-keyword)
    ("volatile"     .     jmt-qualifier-keyword)) "\
An alist relating Java keywords to their proper facing.
The car of each entry is a Java keyword (string), while the cdr is either
its proper face (symbol) or a function in the form of ‘jmt-keyword-face-class’
that gives a face symbol.  The list excludes the keywords that Java Mode
does not face with ‘font-lock-keyword-face’.")



(defun jmt-keyword-face-class (beg _end)
  "Give the face (symbol) proper to a \\=`class\\=` keyword.
The buffer position of the keyword is from BEG (number, inclusive)
to END (exclusive).  Point is left indeterminate."
  (goto-char beg)
  (forward-comment most-negative-fixnum); [←CW]
  (if (eq ?. (char-before)); [NCE]
      'jmt-expression-keyword
        ;;; https://docs.oracle.com/javase/specs/jls/se15/html/jls-15.html#jls-ClassLiteral
    'jmt-principal-keyword)); Of a type declaration.


(defun jmt-keyword-face-default (_beg end)
  "Give the face (symbol) proper to a \\=`default\\=` keyword.
The buffer position of the keyword is from _BEG (number, inclusive)
to END (exclusive).  Point is left indeterminate."
  (goto-char end)
  (forward-comment most-positive-fixnum); [CW→]
  (let ((c (char-after)))
    (if (or (eq ?: c) (eq ?- c)); [NCE]
        'jmt-principal-keyword; Of a `switch` statement clause.
          ;;; https://docs.oracle.com/javase/specs/jls/se15/html/jls-14.html#jls-14.11
      'jmt-qualifier-keyword))); Of an interface method declaration.



(defun jmt-keyword-face-static (beg end)
  "Give the face (symbol) proper to a \\=`static\\=` keyword.
The buffer position of the keyword is from BEG (number, inclusive)
to END (exclusive).  Point is left indeterminate."
  (goto-char beg)
  (forward-comment most-negative-fixnum); [←CW]
  (setq end (point)); The presumed end of the preceding keyword.
  (if (and (< (skip-chars-backward jmt-name-character-set) 0)
           (string= "import" (buffer-substring-no-properties (point) end)))
      'jmt-boilerplate-keyword; In a static import declaration. [SI]
    'jmt-qualifier-keyword)); Elsewhere.



(defun jmt-keyword-face-sync (_beg end)
  "Give the face (symbol) proper to a \\=`synchronized\\=` keyword.
The buffer position of the keyword is from _BEG (number, inclusive)
to END (exclusive).  Point is left indeterminate."
  (goto-char end)
  (forward-comment most-positive-fixnum); [CW→]
  (if (eq ?\( (char-after)); [NCE]
      'jmt-principal-keyword; Of a statement.
        ;;; https://docs.oracle.com/javase/specs/jls/se15/html/jls-14.html#jls-14.19
    'jmt-qualifier-keyword))



(defvar jmt--late-initialization-was-begun nil)



(defun jmt-message (format-string &rest arguments)
  "Call `‘message’ FORMAT-STRING ARGUMENTS` without translating embedded quotes.
Any quote characters \\=`\\=`\\=` or \\=`\\='\\=` in the FORMAT-STRING are output as is."
  (message "%s" (apply #'format format-string arguments)))



(defface jmt-named-literal; [MDF, RF]
  `((t . (:inherit font-lock-constant-face))) "\
The face for literal of type boolean or null; namely \\=`true\\=`, \\=`false\\=` or \\=`null\\=`.
It inherits from ‘font-lock-constant-face’; customize it to distinguish named
literals from other constructs that use ‘font-lock-constant-face’, or to subdue
the facing if you prefer to have these literals not stand out."
  :group 'jmt)



(defun jmt-new-fontifiers-2 ()
  "Build a ‘font-lock-keywords’ list for fast, untamed highlighting.
See also ‘java-font-lock-keywords-1’, which is for minimal untamed highlighting."
  (java-font-lock-keywords-2)); [L2U]



(defun jmt-new-fontifiers-3 ()
  "Build a ‘font-lock-keywords’ list for accurate, tamed highlighting."
  (defvar jmt-specific-fontifiers-3); [FV]
  (nconc

   ;; Underlying Java Mode fontifiers, lightly modified
   ;; ───────────────────────────────
   (let* ((kk (java-font-lock-keywords-3)); List of Java Mode’s fontifiers.
          was-found-annotation; Whether the annotation fontifier of was found in `kk`.
          (k kk); Current fontifier element of `kk`.
          k-last); Previous fontifier element.
     (while; Searching the list, fontifier by fontifier.
         (progn
           (if (equal (car k) '(eval list "\\<\\(@[a-zA-Z0-9]+\\)\\>" 1 c-annotation-face))
               ;; Dud fontifier: works under Java Mode, fails under Java Mode Tamed unless
               ;; changed in two places `"\\_<\\(@[a-zA-Z0-9]+\\)\\>" 1 c-annotation-face t`.
               (progn;                    1 ↑                                           2 ↑
                 ;; Moreover its pattern does not cover the complete, valid form of annotation.
                 ;; Therefore `jmt-new-fontifiers-3` adds a more general, replacement fontifier.
                 (setq was-found-annotation t)
                 (setcdr k-last (cdr k))); Deleting this one here in case somehow it starts working
             (setq k-last k              ; and interferes with the replacement.
                   k (cdr k)))
           (and (not was-found-annotation) k)))
     (unless was-found-annotation
       (jmt-message "(jmt-mode): Failed to remove unwanted Java Mode fontifier: `%s` = nil"
                    (symbol-name 'was-found-annotation)))
     kk)

   ;; Overlying fontifiers to tame them
   ;; ────────────────────
   jmt-specific-fontifiers-3))



(defvar jmt-p); [GVF]



(defface jmt-package-name; [MDF, RF]
  `((t . (:inherit font-lock-constant-face))) "\
The face for each segment of a package name in a type reference.  It inherits
from ‘font-lock-constant-face’; customize it to distinguish package names from
other constructs that use ‘font-lock-constant-face’."
  :group 'jmt)



(defface jmt-package-name-declared; [MDF, RF]
  `((t . (:inherit jmt-package-name))) "\
The face for each segment of a package name in a package declaration, as op-
posed to a type reference.  Customize it to better distinguish between the two."
  :group 'jmt)



(defface jmt-param-tag-parameter `((t . (:inherit jmt-block-tag-parameter))) "\
The face for the parameter-name parameter of a Javadoc `param` tag.
An exception applies to type parameters; for those, see instead
‘jmt-type-variable-tag-parameter’."
  :group 'javadoc-faces)



(defun jmt--patch (source source-name-base function-symbol patch-function)
  "Apply a source-based monkey patch to function FUNCTION-SYMBOL.
You must call \\=`jmt--patch\\=` from a temporary buffer syntactically equivalent
to a buffer in Emacs Lisp mode.  It monkey-patches the function denoted
by FUNCTION-SYMBOL, originally defined in file SOURCE (with SOURCE-NAME-BASE
as its ‘file-name-base’).  For this, it uses the named PATCH-FUNCTION,
which must give t on success and nil on failure."; [ELM]
  (condition-case x
      (progn

        ;; Verify assumptions
        ;; ──────────────────
        (unless (functionp function-symbol)
          (signal 'jmt-x `("No such function loaded" ,function-symbol)))
        (let ((load-file (symbol-file function-symbol)))
          (unless (string= (file-name-base load-file) source-name-base)
            (signal 'jmt-x `("Function loaded from file of base name contradictory to source file"
                             ,function-symbol ,load-file ,source))))
        (let ((function-name (symbol-name function-symbol))
              beg function-name-beg function-name-end patched-function-name patched-function-symbol)

          ;; Restrict the temporary buffer to the function definition alone
          ;; ─────────────────────────────
          (goto-char (point-min))
          (unless (re-search-forward
                   (concat "^(defun[[:space:]\n]+\\(" function-name "\\)[[:space:]\n]*(") nil t)
            (signal 'jmt-x `("Function definition not found in source file" ,source ,function-symbol)))
          (setq beg (match-beginning 0)
                function-name-beg (match-beginning 1)
                function-name-end (match-end 1))
          (narrow-to-region beg (scan-lists beg 1 0))

          ;; Patch the function definition
          ;; ─────────────────────────────
          (goto-char beg)
          (unless (funcall patch-function)
            (signal 'jmt-x `("Patch failed to apply" ,function-symbol)))

          ;; Load the patched function under a new name
          ;; ─────────────────────────
          (setq patched-function-name (concat "jmt-advice/" function-name))
          (delete-region function-name-beg function-name-end)
          (goto-char function-name-beg)
          (insert patched-function-name)
          (eval-buffer)

          ;; Remove the buffer restriction
          ;; ─────────────────────────────
      ;;; (delete-region beg (point-max)); Removing the definition, in hope it speeds later patching.
      ;;;;;; The deletion time is too likely to exceed the time saved.
          (widen); Undoing the `narrow-to-region` above.

          ;; Replicate the compilation state of the original function
          ;; ───────────────────────────────
          (setq patched-function-symbol (intern-soft patched-function-name))
          (cl-assert patched-function-symbol); Avoiding a silent failure.
          (when (byte-code-function-p (symbol-function function-symbol))
            (run-with-idle-timer; Compile during idle time.  This might improve package load times,
             1.3 nil            ; though early tests (with a single patch) showed no such effect.
             (lambda ()
               (unless (byte-compile patched-function-symbol)
                 (jmt-message
                  "(jmt-mode): Patched function `%s` is running uncompiled" function-name)))))

          ;; Replace the original function with the patched version
          ;; ──────────────────────────────────────────────────────
          (advice-add function-symbol :override patched-function-symbol)))

    ;; Recover from failure, if any
    ;; ────────────────────
    (jmt-x
     (widen); Undoing any `narrow-to-region` still in effect above.
     (delay-warning 'jmt-mode (error-message-string x) :error)))); [DW]



(defun jmt-preceding->-marks-generic-return-type ()
  "Tell whether the ‘>’ before point might terminate a generic return type.
Point is left indeterminate."
  (when
      (condition-case nil
          (progn (forward-sexp -1) t); Move backward to the front of the leading delimiter.
        (scan-error nil))
    (forward-comment most-negative-fixnum); [←CW]
    (not (eq (char-before) ?.)))); [NCE]
      ;;; Here a `.` would indicate a call to the method, as opposed to its declaration.



(defvar jmt--present-fontification-beg 0)
(defvar jmt--present-fontification-end 0); Non-zero only when Font Lock is fontifying via
  ;;; the global `font-lock-fontify-region-function`.



(defface jmt-principal-keyword; [MDF, RF]
  `((t . (:inherit font-lock-keyword-face))) "\
The face for the principal keyword of a declaration, statement or clause.
Cf. ‘jmt-qualifier-keyword’.  See also subfaces
‘jmt-boilerplate-keyword’ and ‘jmt-expression-keyword’."
  :group 'keyword-faces)



(defvar jmt-q); [GVF]



(defface jmt-qualifier-keyword; [MDF, RF]
  `((t . (:inherit font-lock-keyword-face))) "\
The face for a secondary keyword in a declaration.
Cf. ‘jmt-principal-keyword’."
  :group 'keyword-faces)



(defface jmt-round-bracket `((t . (:inherit jmt-bracket))) "\
The face for a round bracket, ‘(’ or ‘)’."
  :group 'delimiter-faces)



(defface jmt-separator `((t . (:inherit jmt-delimiter))) "\
The face for a separator: a comma ‘,’ semicolon ‘;’ colon ‘:’ or dot ‘.’."
  :group 'delimiter-faces)



(defun jmt-set-for-buffer (variable value)
  "Set buffer-local VARIABLE (a symbol) to VALUE.
Signal an error if VARIABLE is not buffer local."
  (set variable value)
  (cl-assert (local-variable-p variable)))



(defface jmt-shebang `((t . (:inherit font-lock-comment-delimiter-face))) "\
The face for a shebang ‘#!’."
  :group 'shebang-faces)



(defface jmt-shebang-body `((t . (:inherit font-lock-comment-face))) "\
The face for the body of a shebang line, exclusive of the shebang itself
and any trailing comment."
  :group 'shebang-faces)



(defface jmt-shebang-comment `((t . (:inherit font-lock-comment-face))) "\
The face for the body of a trailing comment in a shebang line,
in case of an `env` interpreter."
  :group 'shebang-faces
  :link '(url-link "https://www.gnu.org/software/coreutils/manual/html_node/env-invocation.html"))



(defface jmt-shebang-comment-delimiter `((t . (:inherit font-lock-comment-delimiter-face))) "\
The face for the delimiter ‘\\c’ of a trailing comment in a shebang line,
in case of an \\=`env\\=` interpreter."
  :group 'shebang-faces
  :link '(url-link "https://www.gnu.org/software/coreutils/manual/html_node/env-invocation.html"))



(defconst jmt-specific-fontifiers-3
  (list


   ;; ══════════
   ;; Annotation  [A, T↓]
   ;; ══════════

   (list; Fontify each instance of annotation, overriding any misfontification of Java Mode.
    (lambda (limit)
      (catch 'to-fontify
        (let ((m1-beg (point)); Presumed start of leading annotation mark ‘@’.
              (m1-beg-limit (1- limit)); Room for two characters, the minimal length.
              eol face m1-end m2-beg m2-end m3-beg m3-end m4-beg m4-end m5-beg m5-end)
          (while (< m1-beg m1-beg-limit)
            (setq m1-end (1+ m1-beg))
            (if (/= ?@ (char-after m1-beg))
                (setq m1-beg m1-end)
              (goto-char m1-end)
              (catch 'is-annotation
                (when (eolp) (throw 'is-annotation nil)); [SL]
                (while; Capture as group 2 the simple annotation name.
                    (progn
                      (skip-syntax-forward "-" limit); Though unconventional, whitespace is allowed
                        ;;; between ‘@’ and name.  Nevertheless this fontifier excludes newlines; also
                        ;;; commentary, which would be perverse here, not worth coding for. [AST, SL]
                      (setq m2-beg (point))
                      (skip-chars-forward jmt-name-character-set limit)
                      (setq m2-end (point))
                      (unless (< m2-beg m2-end) (throw 'is-annotation nil))
                      (setq face (get-text-property m2-beg 'face))
                      (if (eq face 'font-lock-constant-face); [P↓] Then the (mis)captured name should
                          (progn; be dot terminated, so forming a segment of a package name. [PPN]
                            (skip-syntax-forward "-" limit); [SL]
                            (unless (eq ?. (char-after)); [NCE]
                              (throw 'is-annotation nil))
                            (forward-char); Past the ‘.’.
                            t); Continuing the loop, so skipping past this segment of the name.
                        (unless (or (null face); The most common case.  Else a misfontification:
                                    (eq face 'font-lock-function-name-face); This one occurs in the case,
                                      ;;; for instance, of an empty `()` annotation qualifier.
                                    (jmt-is-Java-Mode-type-face face)); [T↓]
                          (throw 'is-annotation nil))
                        nil))); Quitting the loop, having matched the simple annotation name.
                (skip-syntax-forward "-" limit); [SL]
                (when (eq ?\( (char-after)); [NCE]
                  (setq m3-beg (point); Start of trailing qualifier, it would be.
                        eol (line-end-position))
                  (condition-case nil
                      (progn
                        (forward-list 1)
                        (setq m5-end (point))); End of qualifier.  Point now stays here.
                    (scan-error
                     (setq m5-end (point-max)))); Forcing the qualifier to be ignored below.
                  (if (> m5-end eol); The qualifier crosses lines, or a `scan-error` occured above.
                      (goto-char m2-end); Ignoring it. [SL]

                    ;; Qualified
                    ;; ─────────
                    (setq m3-end (1+ m3-beg); ‘(’
                          m4-beg m3-end
                          m5-beg (1- m5-end); ‘)’
                          m4-end m5-beg)
                    (set-match-data (list m1-beg m5-end m1-beg m1-end m2-beg m2-end m3-beg m3-end
                                          m4-beg m4-end m5-beg m5-end (current-buffer)))
                    (goto-char m5-end)
                    (throw 'to-fontify t))); With point (still) at `m5-end` as Font Lock stipulates.

                ;; Unqualified
                ;; ───────────
                (set-match-data (list m1-beg m2-end m1-beg m1-end m2-beg m2-end (current-buffer)))
                (goto-char m2-end)
                (throw 'to-fontify t))

              (setq m1-beg (point)))))
        nil))
    '(1 'jmt-annotation-mark t) '(2 'c-annotation-face t) '(3 'jmt-annotation-delimiter t t)
    '(4 'jmt-annotation-qualifier nil t)                  '(5 'jmt-annotation-delimiter t t))



   ;; ═══════
   ;; Keyword  [K, T↓]
   ;; ═══════

   (cons; Reface each Java keyword as defined in `jmt-keyword-face-alist`.
    (let (match-beg match-end)
      (lambda (limit)
        (setq match-beg (point)); Presumptively.
        (catch 'to-reface
          (while (< match-beg limit)
            (setq match-end (next-single-property-change match-beg 'face (current-buffer) limit))
            (when (eq 'font-lock-keyword-face (get-text-property match-beg 'face))
              (set 'jmt-f (jmt-keyword-face
                           (buffer-substring-no-properties match-beg match-end) match-beg match-end))
              (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
              (throw 'to-reface t))
            (setq match-beg match-end))
          nil)))
    '(0 jmt-f t))


   (cons; Fontify each `assert` and `record` keyword that was misfaced by Java Mode, or left unfaced.
    (let (f match-beg)
      (lambda (limit)
        (catch 'to-reface
          (while (re-search-forward "\\<assert\\|record\\>" limit t)
            (setq match-beg (match-beginning 0)
                  f (get-text-property match-beg 'face))
            (when (or (null f) (jmt-is-Java-Mode-type-face f)); [T↓]
                ;;; Misfacing as a type name has been seen for both `assert` and `record` keywords.
                ;;; For an instance of `assert` misfacing, see `assert stators.getClass()`. [AM]
                ;;; [https://github.com/Michael-Allan/waymaker/blob/3eaa6fc9f8c4137bdb463616dd3e45f340e1d34e/waymaker/gen/KittedPolyStatorSR.java#L58]
                ;;;     More commonly the `assert` keyword is left unfaced, but no instance of this
                ;;; has been seen in the case of the `record` keyword.
              (set 'jmt-f (jmt-keyword-face (match-string-no-properties 0) match-beg (match-end 0)))
              (throw 'to-reface t)))
          nil)))
    '(0 jmt-f t))



   ;; ═════════
   ;; Type name  [↑K, T]
   ;; ═════════

   (cons; Unface each terminal token of a static import incorrectly faced as a type name by Java Mode.
    (let (i j)
      (lambda (limit)
        (setq i (point)); Presumptively.
        (catch 'to-reface
          (while (< i limit)
            (setq j (next-single-property-change i 'face (current-buffer) limit))
            (when (and (eq 'jmt-boilerplate-keyword (get-text-property i 'face)); [↑K]
                       (string= "static" (buffer-substring-no-properties i j)))
              (goto-char j)
              (when (and (re-search-forward
                          (concat "[[:space:]\n." jmt-name-character-set "]+\\_>"
                              ;;;  └───────────────────────────────────────┘
                              ;;;                 TypeName                       [SI]

                                  "\\.\\(" jmt-identifier-pattern "\\);")
                              ;;;    ·    └──────────────────────┘    ·
                              ;;;   dot         Identifier            ;
                          limit t)
                         (jmt-is-Java-Mode-type-face (get-text-property (match-beginning 1) 'face)))
                (throw 'to-reface t)))
            (setq i j))
          nil)))
    '(1 'default t))


   (list; Reface each Java type name using either `jmt-type-declaration` or  `jmt-type-reference`.
    (lambda (limit)
      (catch 'to-reface
        (while (< (point) limit)
          (let* ((match-beg (point)); Presumptively.
                 (match-end (next-single-property-change match-beg 'face (current-buffer) limit)))
            (when (jmt-is-Java-Mode-type-face (get-text-property match-beg 'face))
              (forward-comment most-negative-fixnum); [←CW]

              ;; Either defining a type
              ;; ───────────────
              (when; Keyword `class`, `enum`, `record` or `interface` directly precedes the type name.
                  (let ((p (point)))
                    (and (< (skip-chars-backward jmt-name-character-set) 0)
                         (jmt-is-type-declarative-keyword (buffer-substring-no-properties (point) p))))
                (set 'jmt-f 'jmt-type-declaration)
                (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
                (throw 'to-reface t))

              ;; Or referring to one already defined
              ;; ────────────
              (set 'jmt-f 'jmt-type-reference)
              (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
              (throw 'to-reface t))

            (goto-char match-end)))
        nil))
    '(0 jmt-f t t))


   ;; Type declaration
   ;; ────────────────
   (cons; Face each name of a type declaration that was misfaced or left unfaced by Java Mode.
    (lambda (limit)
      (catch 'to-face
        (while (< (point) limit)
          (let* ((p (point))
                 (match-end (next-single-property-change p 'face (current-buffer) limit))
                 f keyword match-beg)
            (when (and (eq 'jmt-principal-keyword (get-text-property p 'face)); [↑K]
                       (jmt-is-type-declarative-keyword
                        (setq keyword (buffer-substring-no-properties (point) match-end))))
              (goto-char match-end)
              (forward-comment most-positive-fixnum); [CW→]
              (setq match-beg (point)); Presumptively.
              (when (and (< match-beg limit)
                         (> (skip-chars-forward jmt-name-character-set limit) 0)); A name follows.
                (setq f (get-text-property match-beg 'face))
                (cond

                 ;; Record declaration
                 ;; ──────────────────
                 ((and (string= keyword "record")          ; Always it is misfaced as
                      (eq f 'font-lock-function-name-face)); a function declaration.
                  (set-match-data (list match-beg (point) (current-buffer)))
                  (throw 'to-face t))

                 ;; Other type declaration, viz. based on a `class`, `enum` or `interface` keyword
                 ;; ──────────────────────
                 ((not f); The type name is unfaced (misfacing has not been seen)
                  (setq match-end (point))
                  (let ((annotation-count 0))
                    (goto-char p); Back to the type-declarative keyword.
                    (forward-comment most-negative-fixnum); [←CW]
                    (when (eq (char-before (point)) ?@); [NCE]  A ‘@’ marks this declaration
                      (backward-char); as that of an annotation type.  Move back past the ‘@’.
                      (forward-comment most-negative-fixnum)); [←CW]
                    (catch 'is-modifier; Thrown as nil on discovery the answer is negative.
                      (while t; Now point should (invariant) be directly after such a modifier.  So test:
                        (when (eq (char-before (point)) ?\)); [NCE]  Presumeably a list
                          (condition-case nil               ; of annotation parameters.
                              (forward-sexp -1); Skip to the front of it.
                            (scan-error (throw 'is-modifier nil)))
                          (forward-comment most-negative-fixnum)); [←CW]
                            ;;; Holding still the (would be) loop invariant.
                        (setq p (point))
                        (when (= (skip-chars-backward jmt-name-character-set) 0)
                          (throw 'is-modifier nil))
                        ;; The modifier should be either a keyword or annotation.
                        (if (jmt-is-type-modifier-keyword (buffer-substring-no-properties (point) p))

                            ;; Keyword, the modifier is a keyword
                            ;; ───────
                            (if (= annotation-count 0)
                                (forward-comment most-negative-fixnum); [←CW]
                              (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
                              (throw 'to-face t)); The keyword precedes annotation.  With this,
                                ;;; Java Mode fails at times to face the type name.  This was seen,
                                ;;; for instance, here in the sequence `public @ThreadSafe class ID`.
                                ;;; [https://github.com/Michael-Allan/waymaker/blob/3eaa6fc9f8c4137bdb463616dd3e45f340e1d34e/waymaker/spec/ID.java#L8`]
                                ;;;     It seems Java Mode expects to find keywords *before* annotation,
                                ;;; which, although it ‘is customary’, is nevertheless ‘not required’.
                                ;;; [https://docs.oracle.com/javase/specs/jls/se15/html/jls-8.html#jls-8.1.1]
                                ;;; Here therefore the missing face is applied.

                          ;; Annotation, the modifier is an annotation modifier, or should be
                          ;; ──────────
                          (forward-comment most-negative-fixnum); [←CW]
                            ;;; A form unconventional, but allowed. [AST]
                          (unless (eq (char-before (point)) ?@); [NCE]
                            (throw 'is-modifier nil))
                          (setq annotation-count (1+ annotation-count))
                          (backward-char); To before the ‘@’.
                          (forward-comment most-negative-fixnum))))))))); [←CW]
            (goto-char match-end)))
        nil))
    '(0 'jmt-type-declaration t))


   ;; Formal catch parameter  [FCP]
   ;; ──────────────────────
   (let (eol match-beg match-end); Face each type identifier and parameter identifier
     (list                       ; left unfaced by Java Mode.

      ;; anchor, the whole parameter declaration, aka `CatchFormalParameter` [FCP]
      ;; ┈┈┈┈┈┈
      (lambda (limit); (anchoring matcher)
        (setq match-beg (point)); Presumptively.
        (catch 'to-face
          (while (< match-beg limit)
            (setq match-end (next-single-property-change match-beg 'face (current-buffer) limit))
            (when (and (eq 'jmt-principal-keyword (get-text-property match-beg 'face)); [↑K]
                       (string= "catch" (buffer-substring-no-properties match-beg match-end)))
              (goto-char match-end)
              (setq eol (line-end-position))
              (forward-comment most-positive-fixnum); To the opening paranthesis ‘(’. [CW→]
              (catch 'needs-facing; Thrown as nil on discovery the answer is negative.
                (unless (eq ?\( (char-after)); [NCE]
                  (throw 'needs-facing nil)); Malformed catch block.
                (forward-char); Past the ‘(’.
                (forward-comment most-positive-fixnum); To the start of the parameter declaration. [CW→]
                (setq match-beg (point))
                (up-list); To just after the closing paranthesis ‘)’.
                (unless (eq ?\) (char-before)); On `up-list` error, ‘point is unspecified.’ [NCE]
                  (throw 'needs-facing nil)); Malformed catch block.
                (when (or (> (point) eol); [SL]
                          (> (point) limit))
                  (throw 'needs-facing nil)); Out of bounds.
                (backward-char); Before the ‘)’.
                (forward-comment most-negative-fixnum); To the end of the parameter declaration. [←CW]
                (setq match-end (point))
                (when (= 0 (skip-chars-backward jmt-name-character-set)); Start of parameter identifier.
                  (throw 'needs-facing nil)); Malformed catch block.
                (when (get-text-property (point) 'face)
                  ;; Already faced, in which case Java Mode always faces the type identifier(s), too.
                  (throw 'needs-facing nil))
                (set-match-data (list match-beg match-end (point) match-end (current-buffer)))
                (goto-char match-end)
                (set 'jmt-p match-beg); Saving the anchor’s bounds.
                (set 'jmt-q match-end)
                (throw 'to-face t)))
            (setq match-beg match-end))
          nil))

      ;; parameter identifier
      ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
      '(1 'font-lock-variable-name-face); (regular highlighter)

      ;; type identifiers
      ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
      (list; (anchored highlighter)

       ;; ii) define matches, popping the bounds of each segment from (i)
       (lambda (limit); (anchored matcher)
         (catch 'to-face
           (while (re-search-forward jmt-identifier-pattern limit t)
             (let ((beg (match-beginning 0))
                   (case-fold-search nil))
               ;; Aside from the sought type identifiers, all that could match here is already faced,
               ;; either by Java Mode or the preceding highlighter (parameter identifier), with one
               ;; exception, an edge case in which Java Mode leaves a package qualifier unfaced.
               ;; Assuming ∴ that package names begin in lower case [BUG], these guards should suffice.
               (when (and (null (get-text-property beg 'face)); Unfaced, and the first character
                          (string-match-p "[[:upper:]]" (string (char-after beg)))); is upper case.
                 (throw 'to-face t))))
           nil))

       ;; i) pre-position to the start of the parameter declaration
       '(progn; (pre-form)
          (goto-char jmt-p); To `match-beg` of the anchor effectively.
          jmt-q); Limiting the search region (∵ return value is > point) effectively to `match-end`.

       ;; iv) clean up, recovering the proper position
       '(goto-char jmt-q); (post-form) To `match-end` effectively.

       ;; iii) reface each matched identifier
       '(0 'jmt-type-reference))))



   ;; ════════════
   ;; Package name, or a type name misfaced as such  [↑A, ↑K, P, T]
   ;; ════════════

   ;; Package declaration
   ;; ───────────────────
   (let; Reface each name segment of a package declararation using face `jmt-package-name-declared`.
       (face last-seg-was-found match-beg match-end)
     (list

      (lambda (limit); (1) Anchoring on the `package` keyword that begins each declaration.
        (setq match-beg (point)); Presumptively.
        (catch 'is-package-declaration
          (while (< match-beg limit)
            (setq match-end (next-single-property-change match-beg 'face (current-buffer) limit))
            (when (and (eq 'jmt-boilerplate-keyword (get-text-property match-beg 'face)); [↑K]
                       (string= "package" (buffer-substring-no-properties match-beg match-end)))
              (setq last-seg-was-found nil)
              (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
              (throw 'is-package-declaration t))
            (setq match-beg match-end))
          nil))

      (list; (2, anchored highlighter) Thence scanning rightward for each name segment.
       (lambda (limit)
         (catch 'to-reface
           (when last-seg-was-found (throw 'to-reface nil)); The last segment was already refaced.
           (while (< (point) limit); Now point should (invariant) be before any remaining name segment,
             (skip-syntax-forward "-" limit); with at most whitespace intervening. [PPN, SL]
             (setq match-beg (point))
             (skip-chars-forward jmt-name-character-set limit)
             (setq match-end (point))
             (unless (< match-beg match-end) (throw 'to-reface nil)); Malformed or multi-line. [SL]
             (skip-syntax-forward "-" limit); [SL]
             (if (eq ?. (char-after)); [NCE]
                 (forward-char); To the (would be) loop invariant.
               (setq last-seg-was-found t))
             (setq face (get-text-property match-beg 'face))
             (when (or (null face); Java Mode leaves unfaced all but the last segment.
                       (eq face 'font-lock-constant-face))
               (set-match-data (list match-beg (point) match-beg match-end (current-buffer)))
               (throw 'to-reface t)))
           nil))
       nil nil '(1 'jmt-package-name-declared t))))


   ;; Package qualifier on an annotation type reference
   ;; ─────────────────
   (let (match-beg match-end seg-beg seg-end); Reface each package name segment using
     (list                                   ; face `jmt-annotation-package-name`.

      ;; anchor, the simple type name of each annotation type reference
      ;; ┈┈┈┈┈┈
      (lambda (limit); (anchoring matcher)
        (setq match-beg (point)); Presumptively.
        (catch 'is-type-ref
          (while (< match-beg limit)
            (setq match-end (next-single-property-change match-beg 'face (current-buffer) limit))
            (when (eq 'c-annotation-face (get-text-property match-beg 'face)); [↑A]
              (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
              (set 'jmt-p match-beg); Saving the anchor’s bounds.
              (set 'jmt-q match-end)
              (throw 'is-type-ref t))
            (setq match-beg match-end))
          nil))

      ;; name segments
      ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈
      (list; (anchored highlighter)

       ;; ii) define matches, popping the bounds of each segment from (i)
       (lambda (limit); (anchored matcher)
         (when (setq seg-beg (car jmt-f))
           (set 'jmt-f (cdr jmt-f)); Popping the bounds from the stack.
           (setq seg-end (car jmt-f))
           (set 'jmt-f (cdr jmt-f))
           (cl-assert (<= seg-end limit))
           (set-match-data (list seg-beg (goto-char seg-end) (current-buffer)))
           t))

       ;; i) seek segments leftward of the anchor, stacking the bounds of each  [PPN]
       '(let (seg-beg seg-end); (pre-form)
          (set 'jmt-f nil); The stack of bounds, two per segment, initially empty.
          (goto-char jmt-p); To `match-beg` effectively.
          (while
              (progn; Now point should (invariant) be after the dot delimiter of any preceding segment,
                (skip-syntax-backward "-"); with at most whitespace intervening. [SL]
                (when (eq ?. (char-before)); [NCE]
                  (backward-char); To before the dot.
                  (skip-syntax-backward "-"); [SL]
                  (setq seg-end (point))
                  (skip-chars-backward jmt-name-character-set)
                  (setq seg-beg (point))
                  (when (< seg-beg seg-end)
                    (set 'jmt-f (cons seg-end jmt-f)); Pushing the bounds to the stack.
                    (set 'jmt-f (cons seg-beg jmt-f))))))
          jmt-p); Limiting the search region (∵ return value is > point) effectively to `match-beg`.

       ;; iv) clean up, recovering the proper position
       '(goto-char jmt-q); (post-form) To `match-end` effectively.

       ;; iii) reface each matched segment
       '(0 'jmt-annotation-package-name t))))


   ;; Package name occuring elsewhere
   ;; ────────────
   (cons; Reface each name segment using face `jmt-package-name`, and each apparently misfaced
      ;;; type name using face `jmt-type-reference`.
    (let (c match-beg match-end)
      (lambda (limit)
        (setq match-beg (point)); Presumptively.
        (catch 'to-reface
          (while (< match-beg limit)
            (setq match-end (next-single-property-change match-beg 'face (current-buffer) limit))
            (when (eq 'font-lock-constant-face (get-text-property match-beg 'face))
              (goto-char match-end)
              (forward-comment most-positive-fixnum); [CW→, PPN]
              (when (eobp) (throw 'to-reface nil))
              (setq c (char-after))
              (when (= ?. c)
                (set 'jmt-f
                     (if (string= "Lu" (get-char-code-property (char-after match-beg) 'general-category))
                         'jmt-type-reference; Workaround for a probable misfacing by Java Mode.
                           ;;; It occurs e.g. with a type name qualifying a reference to a type member,
                           ;;; e.g. `Foo.BAR` or `Foo.Bar`.  Java Mode misfaces the type name (`Foo`) as
                           ;;; a package name segment.  This workaround assumes that a real segment would
                           ;;; begin in lower case, an assumption that itself is not quite correct. [BUG]
                       'jmt-package-name))
                (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
                (throw 'to-reface t))
              (when (= ?< c)                     ; Then it cannot be a name segment.  Rather it is likely
                (set 'jmt-f 'jmt-type-reference ); a type name qualifying a reference to a type member.
                (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
                (throw 'to-reface t)))
            (setq match-beg match-end))
          nil)))
    '(0 jmt-f t))



   ;; ═════════
   ;; Delimiter
   ;; ═════════

   (cons; Face each Java delimiter that was left unfaced by Java Mode.
    (let (i j match-beg match-end)
      (lambda (limit)
        (setq match-beg (point)); Presumptively.
        (set
         'jmt-f
         (catch 'face
           (while (< match-beg limit)
             (setq i (syntax-after match-beg)
                   j (car i); Numeric syntax code.
                   match-end (1+ match-beg))
             (when (or (= j 4) (= j 5)); When it has bracket syntax, that is.
               (setq j (cdr i)); The character of the opposing bracket.

               ;; Angle bracket
               ;; ─────────────
               (when (or (= j ?<)
                         (= j ?>))
                 (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
                 (throw 'face 'jmt-angle-bracket))

               ;; Curly bracket
               ;; ─────────────
               (when (or (= j ?{)
                         (= j ?}))
                 (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
                 (throw 'face 'jmt-curly-bracket))

               ;; Round bracket
               ;; ─────────────
               (when (or (= j ?\()
                         (= j ?\)))
                 (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
                 (throw 'face 'jmt-round-bracket))

               ;; Square bracket
               ;; ──────────────
               (when (or (= j ?\[)
                         (= j ?\]))
                 (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
                 (throw 'face 'jmt-square-bracket)))

             ;; Separator
             ;; ─────────
             (setq j (char-after match-beg))
             (when (or (= j ?,)
                       (= j ?\;)
                       (= j ?:)
                       (= j ?.))
               (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
               (throw 'face 'jmt-separator))

             (setq match-beg match-end))
           nil))))
    '(0 jmt-f))



   ;; ═══════════════
   ;; Javadoc comment
   ;; ═══════════════

   ;; Outer delimiter
   ;; ───────────────
   (cons; Reface each Javadoc outermost delimiter `/**` using face `jmt-Javadoc-outer-delimiter`.
    (let (p)
      (lambda (limit)
        (catch 'to-reface
          (while (search-forward "/**" limit t)
            (setq p (match-beginning 0))
            (when (and (eq 'font-lock-doc-face (get-text-property p 'face)); When inside is a Javadoc,
                       (or (= p (point-min))                               ; but outside is not.
                           (not (eq 'font-lock-doc-face (get-text-property (1- p) 'face)))))
              (throw 'to-reface t)))
          nil)))
    '(0 'jmt-Javadoc-outer-delimiter prepend)); [PJF]


   (cons; Reface each Javadoc left-marginal delimiter `*` using face `jmt-Javadoc-outer-delimiter`.
    (lambda (limit)
      (catch 'to-reface
        (while (re-search-forward "^\\s-*\\(\\*\\)" limit t)
          (when (eq 'font-lock-doc-face (get-text-property (match-beginning 1) 'face))
            (throw 'to-reface t)))
        nil))
    '(1 'jmt-Javadoc-outer-delimiter prepend)); [PJF]


   (cons; Reface each Javadoc outermost delimiter `*/` using face `jmt-Javadoc-outer-delimiter`.
    (let (p)
      (lambda (limit)
        (catch 'to-reface
          (while (search-forward "*/" limit t)
            (setq p (match-end 0))
            (when (and (eq 'font-lock-doc-face (get-text-property (1- p) 'face)); When inside is,
                       (or (= p (point-max))                      ; but outside is not, a Javadoc.
                           (not (eq 'font-lock-doc-face (get-text-property p 'face)))))
              (throw 'to-reface t)))
          nil)))
    '(0 'jmt-Javadoc-outer-delimiter prepend)); [PJF]


   ;; Inline tag
   ;; ──────────
   (list; Reface each Javadoc inline tag. [JIL]
    (let (match-beg tag-name)
      (lambda (limit)
        (catch 'to-reface
          (while (re-search-forward
                  (concat "\\({\\)\\s-*\\(@\\)\\s-*\\([[:alnum:]]+\\)";    This search might be made
                      ;;;     ·           ·          └──────────────┘        more reliable. [JIL]
                      ;;;     {           @              tag name

                          "\\(?:\\s-+\\([^[:space:]}\n]+\\)\\)?\\(?:\\s-+\\([^}\n]*\\)\\)?\\(}\\)"); [SL]
                      ;;;              └──────────────────┘                └─────────┘       ·
                      ;;;                 parameters 1,                        2, …          }
                  limit t)
            (setq match-beg (match-beginning 0))
            (when (and (jmt-is-Java-Mode-tag-faced (get-text-property match-beg 'face))
                       (>= (match-end 0); And that facing is uniform.
                           (next-single-property-change match-beg 'face (current-buffer) limit)))
              (setq tag-name (match-string-no-properties 3))
              (cond ((or (string= tag-name "link")
                         (string= tag-name "linkplain"))
                     (setq jmt-f jmt-inline-tag-name-f
                           jmt-p jmt-inline-tag-parameter-f
                           jmt-q jmt-inline-rendered-parameter-f))

                    ((string= tag-name "value")
                     (setq jmt-f jmt-value-tag-name-f
                           jmt-p jmt-inline-tag-parameter-f; (if any)
                           jmt-q jmt-inline-tag-parameter-f))

                    ((or (string= tag-name "code")
                         (string= tag-name "index")
                         (string= tag-name "literal")
                         (string= tag-name "summary"))
                     (setq jmt-f jmt-inline-tag-name-f
                           jmt-p jmt-inline-rendered-parameter-f
                           jmt-q jmt-inline-tag-parameter-f)); (if any)

                    (t; All the rest.
                     (setq jmt-f jmt-inline-tag-name-f
                           jmt-p jmt-inline-tag-parameter-f; (if any)
                           jmt-q jmt-inline-tag-parameter-f)))
              (throw 'to-reface t)))
          nil)))
    '(1 jmt-Javadoc-tag-delimiter-f t) '(2 jmt-Javadoc-tag-mark-f t)
    '(3 jmt-f t) '(4 jmt-p t t) '(5 jmt-q t t) '(6 jmt-Javadoc-tag-delimiter-f t))


   ;; HTML tag
   ;; ────────
   (list; Reface each HTML tag.
    (let (match-beg match-end)
      (lambda (limit)
        (setq match-beg (point)); Presumptively.
        (catch 'to-reface
          (while (< match-beg limit)
            (setq match-end (next-single-property-change match-beg 'face (current-buffer) limit))
            (when (and (= ?< (char-after match-beg))
                       (jmt-is-Java-Mode-tag-faced (get-text-property match-beg 'face)))
              (goto-char match-beg)
              (save-restriction
                (narrow-to-region match-beg match-end)

                ;; End tag
                ;; ───────
                (when (looking-at "\\\(./\\)\\([[:alnum:]]+\\)\\(\\s-*\\)\\(>\\)$"); ‘$’ [NBE]
                              ;;;     └────┘  └──────────────┘              ·
                              ;;;       </        tag name                  >

                  (setq jmt-f jmt-HTML-end-tag-name-f
                        jmt-p jmt-inline-tag-parameter-f); (actually this is just space, if present)
                  (goto-char match-end)
                  (throw 'to-reface t))

                ;; Start tag
                ;; ─────────
                (when (looking-at "\\(.\\)\\([[:alnum:]]+\\)\\(\\s-.*\\)?\\(/?>\\)$"); ‘$’ [NBE]
                              ;;;     ·     └──────────────┘  └────────┘    · ·
                              ;;;     <         tag name      attributes    / >

                  (setq jmt-f jmt-HTML-start-tag-name-f
                        jmt-p jmt-inline-tag-parameter-f); (or maybe just space, if present at all)
                  (goto-char match-end)
                  (throw 'to-reface t))))
            (setq match-beg match-end))
          nil)))
    '(1 jmt-Javadoc-tag-delimiter-f t) '(2 jmt-f t) '(3 jmt-p t t) '(4 jmt-Javadoc-tag-delimiter-f t))


   ;; Block tag
   ;; ─────────
   (let; Reface each Javadoc block tag. [JBL]
       (match-beg match-end tag-name)
     (list

      (lambda (limit); (1) Anchoring on the ‘@’ mark and name that begins each tag.
        (setq match-beg (point)); Presumptively.
        (catch 'to-reface
          (while (< match-beg limit)
            (setq match-end (next-single-property-change match-beg 'face (current-buffer) limit))
            (when (and (= ?@ (char-after match-beg))
                       (jmt-is-Java-Mode-tag-faced (get-text-property match-beg 'face)))
              (goto-char match-beg)
              (save-restriction
                (narrow-to-region match-beg match-end)
                (when (looking-at "\\(.\\)\\([[:alnum:]]+\\)$"); ‘$’ [NBE]
                              ;;;     ·     └──────────────┘
                              ;;;     @         tag name

                  (setq tag-name (match-string-no-properties 2))
                  (goto-char match-end)
                  (throw 'to-reface t))))
            (setq match-beg match-end))
          nil))
      '(1 jmt-Javadoc-tag-mark-f t) '(2 jmt-block-tag-name-f t)

      (list; (2, anchored highlighter) Thence rightward, refacing any parameter that needs it.
       (lambda (_limit)
         (catch 'to-reface
           (cond
            ((string= tag-name "param")
             (when (looking-at (concat "\\s-+<\\s-*\\([" jmt-name-character-set "]+\\).*$"))
               (set 'jmt-f 'jmt-type-variable-tag-parameter)
               (goto-char (match-end 0))
               (throw 'to-reface t))
             (when (looking-at (concat "\\s-+\\([" jmt-name-character-set "]+\\).*$"))
               (set 'jmt-f 'jmt-param-tag-parameter)
               (goto-char (match-end 0))
               (throw 'to-reface t)))

            ((string= tag-name "see")
             (when (looking-at "\\s-+\\([^<\n].*\\)$"); Excepting an HTML tag.
               (set 'jmt-f 'jmt-block-tag-parameter)
               (goto-char (match-end 0))
               (throw 'to-reface t)))

            ((or (string= tag-name "throws")
                 (string= tag-name "exception"))
             (when (looking-at (concat "\\s-+\\([." jmt-name-character-set "]+\\).*$"))
               (set 'jmt-f 'jmt-throws-tag-parameter)
               (goto-char (match-end 0))
               (throw 'to-reface t)))

            ((or (string= tag-name "uses")
                 (string= tag-name "provides"))
             (when (looking-at "\\s-+\\([^[:space:]\n]+\\).*$")
               (set 'jmt-f 'jmt-block-tag-parameter)
               (goto-char (match-end 0))
               (throw 'to-reface t)))

            ((or (string= tag-name "since")
                 (string= tag-name "author")
                 (string= tag-name "version"))
             (when (looking-at "\\s-+\\([^[:space:]\n].+\\)$")
               (set 'jmt-f 'jmt-block-tag-parameter)
               (goto-char (match-end 0))
               (throw 'to-reface t)))

            ((string= tag-name "serial")
             (when (looking-at "\\s-+\\(\\(?:ex\\|in\\)clude\\)\\s-*$")
               (set 'jmt-f 'jmt-block-tag-parameter)
               (goto-char (match-end 0))
               (throw 'to-reface t)))

            ((string= tag-name "serialField")
             (when (looking-at (concat "\\s-+\\([" jmt-name-character-set
                                       "]+\\s-+[" jmt-name-character-set "]+\\).*$"))
               (set 'jmt-f 'jmt-block-tag-parameter)
               (goto-char (match-end 0))
               (throw 'to-reface t))))
           nil))
       nil nil '(1 jmt-f prepend)))); [PJF]



   ;; ════════════════════════════════
   ;; Method or constructor identifier  [↑A, ↑K, ↑T]
   ;; ════════════════════════════════

   (cons; Fontify each identifier that was misfaced by Java Mode, or incorrectly left unfaced.
    (let (face i match-beg match-end predecessor-end)
      (lambda (limit)
        (set
         'jmt-f
         (catch 'face
           (while (re-search-forward jmt-identifier-pattern limit t)
             (setq match-beg (match-beginning 0); Presumptively.
                   match-end (match-end 0)
                   face (get-text-property match-beg 'face))
             (when (or (null face) (eq face 'font-lock-function-name-face)
                       (eq face 'jmt-type-reference)); [↑T]
                 ;;; Vanguard, redundant but for sake of speed.  See the other face guards below.
               (forward-comment most-positive-fixnum); [CW→]
               (and; Any nil evaluation among the following advances `while` to the next identifier.

                (eq ?\( (char-after)); Else this identifier names neither a method nor contructor. [NCE]

                ;; Constructor declaration
                ;; ───────────────────────
                ;; Or some cases of method declaration in need; this section may fontify those, too,
                ;; just because it happens to precede the method declaration section, below.
                (catch 'goto-next
                  (setq predecessor-end nil); [◦↓◦]
                  (unless (or (null face) (eq face 'jmt-type-reference)); [↑T]
                    (throw 'goto-next t)); Only identifiers left unfaced
                    ;;; or misfaced as type references have been seen.  See for instance
                    ;;; the sequences `public @Warning("non-API") ApplicationX()` at
                    ;;; `https://github.com/Michael-Allan/waymaker/blob/3eaa6fc9f8c4137bdb463616dd3e45f340e1d34e/waymaker/gen/ApplicationX.java#L23`,
                    ;;; and `ID( final String string, final int cN ) throws MalformedID` at
                    ;;; `https://github.com/Michael-Allan/waymaker/blob/3eaa6fc9f8c4137bdb463616dd3e45f340e1d34e/waymaker/spec/ID.java#L30`.

                  ;; After the identifier, in any parameter list
                  ;; ·····················
                  (forward-char); Past the ‘(’.
                  (forward-comment most-positive-fixnum); [CW→]
                  (setq i (point))
                  (when (> (skip-chars-forward jmt-name-character-set) 0)
                    (when (string= "final" (buffer-substring-no-properties i (point)))
                      (goto-char match-end)
                      (throw 'face 'font-lock-function-name-face))
                    (catch 'is-past-package; Leaving `i` at either the next token to deal with,
                      (while t; or the buffer end, scan past any itervening package name.
                        ;; Now point lies (invariant) directly after a name (in form).
                        (forward-comment most-positive-fixnum); [CW→, PPN]
                        (when (eobp) (throw 'is-past-package t))
                        (unless (= ?. (char-after))  ; Namely the delimiting dot of a
                          (throw 'is-past-package t)); preceding package name segment.
                        (forward-char); Past the ‘.’.
                        (forward-comment most-positive-fixnum); [CW→] To the next token.
                        (setq i (point)); What follows the package name follows its last dot.
                        (when (= (skip-chars-forward jmt-name-character-set) 0)
                          (throw 'is-past-package t)))))
                  (when (and (/= i (point-max))
                             (or (= ?@ (char-after i))
                                 (eq (get-text-property i 'face) 'jmt-type-reference))); [↑T]
                    (goto-char match-end)
                    (throw 'face 'font-lock-function-name-face))

                  ;; Before the identifier
                  ;; ·····················
                  (goto-char match-beg)
                  (forward-comment most-negative-fixnum); [←CW]
                  (when (bobp) (throw 'goto-next nil)); Skip any remaining §§.
                  (setq predecessor-end (point)); [◦↓◦]

              ;;; (when (= (char-before) ?>)
              ;;;   (if (jmt-preceding->-marks-generic-return-type)
              ;;;       (goto-char match-end)
              ;;;       (throw 'face 'font-lock-function-name-face)
              ;;;     (throw 'goto-next t)))
              ;;;;;;;;; Disabled pending resolution of several problems: 1) Point is left indeterminate
                    ;;; by the call to `jmt-preceding->-marks-generic-return-type`, breaking the code
                    ;;; that follows; 2) nominally a call to `jmt-preceding->-marks-generic-return-type`
                    ;;; makes no sense for constructors which necessarily declare no return type;
                    ;;; and 3) the same code may end up running redundantly in the section that follows.

                  ;; A constructor modifier here before point would also indicate a declaration.
                  ;; However, the earlier test of ‘final’ (above) has eliminated the only case
                  ;; in which Java Mode is known to fail when a keyword modifier appears here.
                  ;; That leaves only the case of an *annotation* modifier to remedy.
                  (when (jmt-is-annotation-terminal-face (get-text-property (1- (point)) 'face)); [↑A]
                    (goto-char match-end)
                    (throw 'face 'font-lock-function-name-face))
                  t)

                ;; Method declaration
                ;; ──────────────────
                (catch 'goto-next
                  (when face (throw 'goto-next t))
                    ;;; No misfaced definitions have been seen, only unfaced.  For instance,
                    ;;; see the sequence `public @Override @Warning("non-API") void onCreate()`.
                    ;;; [https://github.com/Michael-Allan/waymaker/blob/3eaa6fc9f8c4137bdb463616dd3e45f340e1d34e/waymaker/gen/ApplicationX.java#L40]
                  (if predecessor-end; [◦↕◦]
                      (goto-char predecessor-end)
                    (goto-char match-beg)
                    (forward-comment most-negative-fixnum); [←CW]
                    (when (bobp) (throw 'goto-next nil)); Skip any remaining §§.
                    (setq predecessor-end (point)))
                  (setq i (char-before)); The predecessor would have to be the method’s return type.
                  (when (= i ?\]); Return type declared as an array.
                    (goto-char match-end)
                    (throw 'face 'font-lock-function-name-face))
                  (when (= i ?>)
                    (if (jmt-preceding->-marks-generic-return-type)
                        (goto-char match-end)
                        (throw 'face 'font-lock-function-name-face)
                      (throw 'goto-next t)))
                  ;; The return type may be declared simply by a type name.
                  (setq i (get-text-property (1- (point)) 'face))
                  (when (eq i 'jmt-type-reference); [↑T]
                    (goto-char match-end); Indeed it appears to be a type name.
                    (throw 'face 'font-lock-function-name-face))
                  (unless i; What would be the return type has been left unfaced by Java Mode.
                      ;;; Maybe ∵ it became confused by prior annotation?  Try moving there:
                    (when (< (skip-chars-backward jmt-name-character-set) 0)
                      (forward-comment most-negative-fixnum); [←CW]
                      (when (jmt-is-annotation-terminal-face (get-text-property (1- (point)) 'face)); [↑A]
                        (goto-char match-end); Indeed annotation precedes what would be the return type.
                        (throw 'face 'font-lock-function-name-face))))
                  t)

                ;; Method call
                ;; ───────────
                (catch 'goto-next
                  (unless (eq face 'font-lock-function-name-face) (throw 'goto-next t))
                    ;;; Only calls misfaced as declarations have been seen.
                  (if predecessor-end; [◦↑◦]
                      (goto-char predecessor-end)
                    (goto-char match-beg)
                    (forward-comment most-negative-fixnum); [←CW]
                    (when (bobp) (throw 'goto-next nil))); Skip any remaining §§.
                  (when; When the possibility of the method identifier being proper to a declaration
                      ;; as opposed to a call is excluded because it directly follows either: [AM]
                      (or (= (char-before) ?.)
                            ;;; (a) The character ‘.’, as in the sequence `assert stators.getClass()` at
                            ;;; `https://github.com/Michael-Allan/waymaker/blob/3eaa6fc9f8c4137bdb463616dd3e45f340e1d34e/waymaker/gen/KittedPolyStatorSR.java#L58`.
                          (eq (get-text-property (1- (point)) 'face) 'jmt-principal-keyword)); [↑K]
                            ;;; (b) A principal keyword, as in the sequence `assert verify(blocks)` at
                            ;;; `https://github.com/oracle/graal/blob/968c592cc6c1b3e6ee6b23b086adbc3c5007e6be/compiler/src/org.graalvm.compiler.core.common/src/org/graalvm/compiler/core/common/cfg/DominatorOptimizationProblem.java#L52`.
                    (goto-char match-end)
                    (throw 'face 'default))
                  t))
               (goto-char match-end))); Whence the next leg of the search begins.
           nil))))
    '(0 jmt-f t))



   ;; ═════════════
   ;; Named literal
   ;; ═════════════

   (cons; Reface each literal of type boolean or null.
    (let (m match-beg match-end)
      (lambda (limit)
        (setq match-beg (point)); Presumptively.
        (catch 'to-reface
          (while (< match-beg limit)
            (setq match-end (next-single-property-change match-beg 'face (current-buffer) limit))
            (when (eq 'font-lock-constant-face (get-text-property match-beg 'face))
              (setq m (buffer-substring-no-properties match-beg match-end))
              (when (or (string= "true" m) (string= "false" m) (string= "null" m))
                (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
                (throw 'to-reface t)))
            (setq match-beg match-end))
          nil)))
    '(0 'jmt-named-literal t))



   ;; ════════════
   ;; Shebang line, as described in `http://openjdk.java.net/jeps/330#Shebang_files`
   ;; ════════════

   (list; Fontify any shebang line in a source-launch file.
    "\\`\\(#!\\)\\(.+?\\)\\(?:\\(\\\\c\\)\\(.*\\)\\)?$"
      ;;;  ·      └─────┘  └───────────────────────┘
      ;;;  #!      body          comment [CSL]

    '(1 'jmt-shebang t) '(2 'jmt-shebang-body t) '(3 'jmt-shebang-comment-delimiter t t)
    '(4 'jmt-shebang-comment t t))



   ;; ══════════════
   ;; String literal  [↑A]
   ;; ══════════════

   (list; Refontify each Java string literal using face `jmt-string-delimiter`,
      ;;; `or faces jmt-annotation-string` and `jmt-annotation-string-delimiter`.
    (let (body-beg body-end f match-beg match-end)
      (lambda (limit)
        (setq match-beg (point)); Presumptively.
        (catch 'to-refontify
          (while (< match-beg limit)
            (setq match-end (next-single-property-change match-beg 'face (current-buffer) limit))
            (when (eq 'font-lock-string-face (get-text-property match-beg 'face))
              (setq body-beg (1+ match-beg)
                    body-end (1- match-end)
                    f (get-text-property match-end 'face))
              (if (or (eq f 'jmt-annotation-delimiter); A rough test only, it could fail. [↑A, BUG]
                      (eq f 'jmt-annotation-qualifier))
                  (progn

                  ;; Within annotation
                  ;; ─────────────────
                    (set 'jmt-f 'jmt-annotation-string-delimiter)
                    (set-match-data (list match-beg match-end match-beg body-beg body-beg body-end
                                          body-end match-end (current-buffer))))
                ;; Elsewhere
                ;; ─────────
                (set 'jmt-f 'jmt-string-delimiter)
            ;;; (when (>= (- match-end match-beg) 7); Then hypothesize a text block.
            ;;;   (let* ((body-beg? (+ match-beg 3)); Allowing for the longer delimiters.
            ;;;          (body-end? (- match-end 3))
            ;;;          (beg-delimiter (buffer-substring-no-properties match-beg body-beg?))
            ;;;          (end-delimiter (buffer-substring-no-properties match-end body-end?))
            ;;;          (expected "\"\"\"")); In fact `beg-delimiter` would have to end in a newline
            ;;;           ;;; optionally preceded by whitespace, hence the 7 in the guard above.
            ;;;     (when (and (string= beg-delimiter expected) (string= end-delimiter expected))
            ;;;       (setq body-beg body-beg?; Hypothesis verified.
            ;;;             body-end body-end?))))
            ;;;;;; No point at present, Java Mode has stopped facing text blocks as strings. [TB]
                (set-match-data (list match-beg match-end match-beg body-beg nil nil
                                      body-end match-end (current-buffer))))
              (goto-char match-end)
              (throw 'to-refontify t))
            (setq match-beg match-end))
          nil)))
    '(1 jmt-f t) '(2 'jmt-annotation-string t t) '(3 jmt-f t))



   ;; ═════════════
   ;; Type variable in a type parameter declaration  [↑A, ↑T]
   ;; ═════════════

   (cons; Reface each variable using face `jmt-type-variable-declaration`.  See optimization note. [TV]
    (let (depth i j match-beg match-end p p-min)
      (lambda (limit)
        (catch 'to-reface
          (while (< (point) limit)
            (setq match-beg (point); Presumptively.
                  match-end (next-single-property-change match-beg 'face (current-buffer) limit))
            (when (eq 'jmt-type-reference (get-text-property match-beg 'face)); [↑T]
              (setq p-min (point-min))
              (while; Skipping back over both any commentary and/or the annotations that
                  (progn; may appear here, and setting `p` to the resulting point. [TP]
                    (forward-comment most-negative-fixnum); [←CW]
                    (setq p (point))
                    (if (or (= p p-min)
                            (not (jmt-is-annotation-ish-before p))); [↑A]
                        nil; Quitting the `while` loop.
                      (goto-char (previous-single-property-change p 'face))
                      t))); Continuing the loop.
              (setq p (1- p)); Before what should be the delimiter of a type variable list. [TVL]
              (when
                  (and
                   (>= p p-min)
                   (progn
                     (setq i (char-after p))
                     (or; And the character after `p` is indeed such a list delimiter, viz. one of:
                      (eq 'c-<-as-paren-syntax (setq j (get-text-property p 'category))); ‘<’
                      (eq 'c->-as-paren-syntax j)                                       ; ‘>’
                      (and (eq (get-text-property p 'c-type) 'c-<>-arg-sep)             ; ‘,’
                           (eq i ?,)))); Not ‘&’, that is. [NCE]
                     ;;; Leaving `i` set to that delimiter character.
                   (catch 'is-proven; And the matched name occurs at the top level of that list (depth
                     ;; of angle brackets 1).  And the list directly follows either (a) the identifier
                     ;; of a type declaration, indicating the declaration of a generic class or inter-
                     ;; face, or (b) neither a type name, type variable nor `.` delimiter (of a method
                     ;; call), indicating the declaration of a generic method or constructor. [MC]
                     (setq depth 1); Nested depth of name in brackets, presumed to be 1 as required.
                     (while; Ensure `p` has emerged from all brackets,
                         (progn; moving it leftward as necessary.
                           (cond ((= i ?<); Ascending from the present bracket pair.
                                  (setq depth (1- depth))
                                  (when (= 0 depth); Then presumeably `p` has emerged left of list.
                                    (goto-char p)
                                    (forward-comment most-negative-fixnum); [←CW]
                                    (when (bobp) (throw 'is-proven t))
                                      ;;; Apparently a generic method or constructor declaration,
                                      ;;; though outside of any class body and so misplaced.
                                    (setq p (1- (point)); Into direct predecessor of variable list.
                                          i (char-after p))
                                    (when (or (= i ?.); `.` delimiter of a method call.
                                              (= i ?<)); Scan position `p` had *not* emerged, so the
                                                ;;; type variable is *not* at top level, after all.
                                      (throw 'is-proven nil))
                                    (setq j (get-text-property p 'face))
                                    (throw 'is-proven; As the type parameter declaration of:
                                           (or (eq 'jmt-type-declaration j); [↑T]
                                                 ;;; (a) a generic class or interface declaration;
                                               (not (eq 'font-lock-type-face
                                                     (jmt-untamed-face j)))))))
                                                 ;;; (b) a generic method or constructor declaration.
                                 ((= i ?>); Descending into another bracket pair.
                                  (setq depth (1+ depth))))
                           (if (= p p-min)
                               nil; Quitting the `while` loop.
                             (setq p (1- p))
                             (setq i (char-after p))
                             t))); Continuing the loop.
                     nil))
                (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
                (throw 'to-reface t)))
            (goto-char match-end))
          nil)))
    '(0 'jmt-type-variable-declaration t))



   ;; ════════
   ;; Variable identifier in a variable declaration
   ;; ════════

   (cons; Reface each loop-variable identifier that was misfaced by Java Mode.
    (let (match-beg match-end)
      (lambda (limit)
        (setq match-beg (point)); Presumptively.
        (catch 'to-reface
          (while (< match-beg limit)
            (setq match-end (next-single-property-change match-beg 'face (current-buffer) limit))
            (when (eq 'font-lock-function-name-face (get-text-property match-beg 'face))
                ;;; Only an identifier misfaced as a function name has been seen.
              (goto-char match-end)
              (forward-comment most-positive-fixnum); [CW→]
              (when (eobp) (throw 'to-reface nil))
              (when (= ?: (char-after)); Indicating for context an enhanced `for` loop.
                  ;;; Only here has a misfacing been seen.  (And only where the expression on the
                  ;;; right side is a function call, as with `foo` in `for( Foo foo: getFooList() )`.)
                (set-match-data (list match-beg (goto-char match-end) (current-buffer)))
                (throw 'to-reface t)))
            (setq match-beg match-end))
          nil)))
    '(0 'font-lock-variable-name-face t)))
  "\
Elements of ‘jmt-new-fontifiers-3’ which are specific to Java Mode Tamed.")



(defface jmt-square-bracket `((t . (:inherit jmt-bracket))) "\
The face for a square bracket, ‘[’ or ‘]’."
  :group 'delimiter-faces)



(defface jmt-string-delimiter; [BC, LF, RF]
  `((t . (:inherit font-lock-string-face))) "\
The face for the delimiter of a string literal (\" or \"\"\") or character
literal (\\=').  Customize it to better distinguish these delimiters from
the content they delimit; making them less prominent, for example.
See also ‘jmt-delimiter’ and the faces that inherit from it."
  :group 'delimiter-faces)



(defface jmt-throws-tag-parameter `((t . (:inherit jmt-block-tag-parameter))) "\
The face for the type-reference parameter of a Javadoc `throws` tag."
  :group 'jmt)



(defface jmt-type-declaration; [MDF, RF]
  `((t . (:inherit font-lock-type-face))) "\
The face for the identifier of a class or interface in a type declaration.
Customize it to highlight the identifier where initially it is defined (like
‘font-lock-variable-name-face’ does for variable identifiers), as opposed
to merely referenced after the fact.  See also face ‘jmt-type-reference’."
  :group 'jmt)



(defface jmt-type-reference; [MDF, RF]
  `((t . (:inherit font-lock-type-face))) "\
The face for the identifier of a class, interface or type parameter
(viz. type variable) where it appears as a type reference.  See also
faces ‘jmt-type-declaration’ and ‘jmt-type-variable-declaration’."
  :group 'jmt)



(defface jmt-type-variable-declaration; [TP, MDF, RF]
  `((t . (:inherit jmt-type-declaration))) "\
The face for a type variable in a type parameter declaration.
Customize it to highlight the variable where initially it is declared
(as ‘font-lock-variable-name-face’ does for non-type variables), rather than
merely referenced after the fact.  See also face ‘jmt-type-reference’."
  :group 'jmt)



(defface jmt-type-variable-tag-parameter; [NDF, RF]
  `((t . (:inherit jmt-Javadoc-tag))) "\
The face for a type variable in a Javadoc \\=`param\\=` tag."
  ;; Java Mode has misfaced it as an HTML tag (the two have the same delimiters).  Therefore this face
  ;; (like `jmt-HTML-tag-name`, and unlike `jmt-param-tag-parameter`) is necessarily a replacement
  ;; face for `font-lock-constant-face` (via `jmt-Javadoc-tag` as it happens).  A better solution
  ;; would be to repair Java Mode’s error in order to elimate this complication. [BUG]
  :group 'javadoc-faces)



(defun jmt-untamed-face (face)
  "Give FACE itself if untamed, else its nearest untamed ancestor.
Every face defined by Java Mode Tamed (tamed face) ultimately inherits
from an untamed ancestral face defined elsewhere."
  (catch 'untamed-face
    (while (string-prefix-p "jmt-" (symbol-name face))
      (setq face (face-attribute face :inherit nil nil))
      (when (eq 'unspecified face)
        (throw 'untamed-face 'default)))
    face))



(defface jmt-value-tag-name; [NDF, RF]
  `((t . (:inherit jmt-inline-tag-name))) "\
The face for the proper identifier \\=`value\\=` of a Javadoc value tag."
  :group 'javadoc-faces)

(defconst jmt-value-tag-name-f (jmt-make-Javadoc-tag-facing 'jmt-value-tag-name))



(defgroup keyword-faces nil "\
Faces for Java keywords."
  :group 'jmt
  :prefix "jmt-")



(defgroup shebang-faces nil "\
Faces for a shebang line atop a source-launch file."
  :group 'jmt
  :prefix "jmt-"
  :link '(url-link "http://openjdk.java.net/jeps/330#Shebang_files"))



;; ══════════════════════════════════════════════════════════════════════════════════════════════════════
;;  P a c k a g e   p r o v i s i o n
;; ══════════════════════════════════════════════════════════════════════════════════════════════════════


(unless jmt--early-initialization-was-begun
  (set 'jmt--early-initialization-was-begun t)
  (set 'c-default-style (cons '(jmt-mode . "java") c-default-style))); Setting the default style
    ;;; (of indentation etc.) to `java` style, the same as underlying Java Mode.



(defvar jmt--autoload-guard); Bound from here to end of file load, void at all other times.

;;;###autoload
(unless (boundp 'jmt--autoload-guard); To execute only on `package-initialize`, not on file load. [GDA]
   (set 'auto-mode-alist (cons (cons "\\.java\\'" 'jmt-mode) auto-mode-alist))
   (set 'interpreter-mode-alist
        (cons (cons "\\(?:--split-string=\\|-S\\)?java" 'jmt-mode) interpreter-mode-alist)))
    ;;; In these one might wish to append versus cons not to override any pattern previously added
    ;;; by the user.  But a package should not demur in installing itself (and indeed the autoloads
    ;;; of CC Mode would clobber us here if we did).  Rather let the package *manager* mend its own bugs,
    ;;; and the user meantime find recourse in the means that Emacs provides.
    ;;; https://stackoverflow.com/a/35949889/2402790



;;;###autoload
(define-derived-mode jmt-mode java-mode
  "Java Mode Tamed" "\
A derived major mode that affords better control of the Java mode
built into Emacs, particularly in regard to syntax highlighting.
For more information, see URL ‘http://reluk.ca/project/Java/Emacs/’."
  :group 'jmt

  ;; ════════════════════════════
  ;; Finish initializing the mode if necessary
  ;; ════════════════════════════
  ;; Deferred till now, after loading the first Java file, not to needlessly delay the start of Emacs.

  (unless jmt--late-initialization-was-begun
    (set 'jmt--late-initialization-was-begun t)

  ;; Verify assumptions
  ;; ──────────────────
    (cl-assert (= ?> (char-syntax ?\n))); Newlines have endcomment syntax.
      ;;; (Consequently they have no whitespace syntax.)
    (cl-assert parse-sexp-ignore-comments)

  ;; Tell Java Mode of additional faces I
  ;; ────────────────────────────────────
    (set 'c-literal-faces
         (append c-literal-faces; [LF]
                 '(jmt-annotation-string
                   jmt-annotation-string-delimiter
                   jmt-string-delimiter)))

    ;; Apply monkey patches                                 Adding or removing a patch below?
    ;; ────────────────────                                 Sync with §*Changes to Emacs* at top.
    (define-error 'jmt-x "Broken monkey patch")
    (let (source source-name-base)
      (condition-case x
          (progn

            ;; `cc-fonts` functions
            ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
            (setq source (locate-library "cc-fonts.el" t)
                  source-name-base (file-name-base source))
            (unless source (signal 'jmt-x `("No such source file on load path: `cc-fonts.el`")))
            (with-temp-buffer; [ELM]
              (setq-local parse-sexp-ignore-comments t)
              (with-syntax-table emacs-lisp-mode-syntax-table
                (insert-file-contents source)

                ;; `c-fontify-recorded-types-and-refs` [AW]
                ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
                (jmt--patch
                 source source-name-base #'c-fontify-recorded-types-and-refs
                 (lambda ()
                   (let (is-patched)
                     (while (search-forward "(c-put-font-lock-face " nil t)
                       (replace-match "(jmt--c-put-face-unless-wild " t t); [SFP]
                       (setq is-patched t))
                     is-patched)))

                ;; `c-font-lock-<>-arglists` [AW]
                ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
                (jmt--patch
                 source source-name-base #'c-font-lock-<>-arglists
                 (lambda ()
                   (let (is-patched)
                     (while (search-forward "(eq id-face" nil t)
                       (replace-match "(jmt-faces-are-equivalent id-face" t t)
                       (setq is-patched t))
                     is-patched)))

                ;; `c-font-lock-doc-comments` [AW]
                ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
                (jmt--patch
                 source source-name-base #'c-font-lock-doc-comments
                 (lambda ()
                   (let (is-patched)
                     (while (search-forward "(c-put-font-lock-face " nil t)
                       (replace-match "(jmt--c-put-face-tamed " t t); [SFP]
                       (setq is-patched t))
                     is-patched)))

                ;; `c-font-lock-declarations` [AW]
                ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
                (jmt--patch
                 source source-name-base #'c-font-lock-declarations
                 (lambda ()
                   (when (re-search-forward
                          (concat "(\\(eq\\) (get-text-property (point) 'face)[[:space:]\n]*"
                                  "'font-lock-keyword-face)")
                          nil t)
                     (replace-match "jmt-faces-are-equivalent" t t nil 1)
                     t))))))

                ;; `c-font-lock-labels` [AW]
                ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
            ;;; (jmt--patch
            ;;;  source source-name-base #'c-font-lock-labels
            ;;;  (lambda ()
            ;;;    (when (re-search-forward
            ;;;           (concat "(\\(eq\\) (get-text-property (1- (point)) 'face)[[:space:]\n]*"
            ;;;                   "c-label-face-name)"); [FLC]
            ;;;           nil t)
            ;;;      (replace-match "jmt-faces-are-equivalent" t t nil 1)
            ;;;      t))))))
            ;;;;;; ‘This function is only used on decoration level 2’, ∴ no patch is needed. [L2U]
        (jmt-x (delay-warning 'jmt-mode (error-message-string x) :error))); [DW]
      (condition-case x
          (progn

            ;; `cc-mode` functions
            ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
            (setq source (locate-library "cc-mode.el" t)
                  source-name-base (file-name-base source))
            (unless source (signal 'jmt-x `("No such source file on load path: `cc-mode.el`")))
            (with-temp-buffer; [ELM]
              (setq-local parse-sexp-ignore-comments t)
              (with-syntax-table emacs-lisp-mode-syntax-table
                (insert-file-contents source)

                ;; `c-before-change` [AW]
                ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
                (jmt--patch
                 source source-name-base #'c-before-change
                 (lambda (); Java Mode uses the following list of faces for a `memq` test.
                   (when (search-forward "'(font-lock-comment-face font-lock-string-face)" nil t)
                     (backward-char); Before the trailing ‘)’, insert their replacement faces: [BC]
                     (insert
                      " jmt-annotation-string jmt-annotation-string-delimiter jmt-string-delimiter")
                     t))))))
        (jmt-x (delay-warning 'jmt-mode (error-message-string x) :error)))); [DW]

    ;; `font-lock-fontify-region-function` (global binding), typically `font-lock-default-fontify-region`
    ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
    (advice-add
     (default-value 'font-lock-fontify-region-function) :around
       ;;; Locally CC Mode has bound `font-lock-fontify-region-function` to `c-font-lock-fontify-region`,
       ;;; a function that simply calls the original (globally bound) function with an expanded region.
       ;;; In order to track that expansion, the present advice attaches to the globally bound function.
     (lambda (function-name &rest arguments)
       (let ((a arguments))
         (set 'jmt--present-fontification-beg (pop a))
         (set 'jmt--present-fontification-end (pop a)))
       (prog1 (apply function-name arguments)
         (set 'jmt--present-fontification-end 0)))
     '((name . "jmt-advice/font-lock-fontify-region-function")
       (depth . 100))); Deepest.

    ;; `javadoc-font-lock-doc-comments`
    ;; ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
    (let* ((fontifier (nth 1 javadoc-font-lock-doc-comments)); The block tag fontifier.
           (pattern (car fontifier))
           (pattern-end "\\(@[a-z]+\\)"))
      (condition-case x
          (if (not (string-suffix-p pattern-end pattern))
              (signal 'jmt-x `("Patch failed to apply" javadoc-font-lock-doc-comments))
            (setq pattern (substring pattern 0 (- (length pattern-end))); Cutting `pattern-end` and
                  pattern (concat pattern "\\(@[a-zA-Z]+\\)")); replacing it with a version modified
                    ;;; to allow for upper case letters, as in the standard tag `serialData`. [JBL]
            (setcar fontifier pattern))
        (jmt-x (delay-warning 'jmt-mode (error-message-string x) :error))))); [DW]


  ;; ═════════════════════
  ;; Initialize the buffer
  ;; ═════════════════════

  ;; Cache the decoration level in `jmt--is-level-3`, q.v.
  ;; ──────────────────────────
  (let ((level (font-lock-value-in-major-mode font-lock-maximum-decoration)))
    (set 'jmt--is-level-3 (or (eq level t) (and (numberp level) (>= level 3)))))

  ;; Tell Java Mode of additional faces II
  ;; ─────────────────────────────────────
  (jmt-set-for-buffer
   'c-maybe-decl-faces
   (append c-maybe-decl-faces; [MDF]
           ;;   Quoted individually only because `c-maybe-decl-faces` “must be evaluated (with ‘eval’)
           ;; ↙  at runtime to get the actual list of faces”; e.g. `(eval c-maybe-decl-faces)`.
           '('jmt-annotation-package-name
             'jmt-boilerplate-keyword
             'jmt-expression-keyword
             'jmt-named-literal
             'jmt-package-name
             'jmt-package-name-declared
             'jmt-principal-keyword
             'jmt-qualifier-keyword
             'jmt-type-declaration
             'jmt-type-variable-declaration
             'jmt-type-reference)))

  ;; Define the fontification levels
  ;; ───────────────────────────────
  (jmt-set-for-buffer 'font-lock-defaults
       '((java-font-lock-keywords-1; 0 or nil    The alternative values of `font-lock-keywords`,
          java-font-lock-keywords-1; 1           each ordered according to the value of `font-lock-
          jmt-new-fontifiers-2     ; 2           -maximum-decoration` that selects it. [MD]
          jmt-new-fontifiers-3)))) ; 3 or t



(provide 'jmt-mode)



;; NOTES
;; ─────
;;   ◦↓◦  Code that is order dependent with like-marked code (◦↕◦, ◦↑◦) that comes after.
;;
;;   ◦↕◦  Code that is order dependent with like-marked code (◦↓◦, ◦↕◦, ◦↑◦) that comes before and after.
;;
;;   ◦↑◦  Code that is order dependent with like-marked code (◦↓◦, ◦↕◦) that comes before.
;;
;;   A ·· Section *Annotation* of `jmt-specific-fontifiers-3`.
;;
;;  ↑A ·· Code that must execute after section *Annotation*.
;;
;;   AM · This marks misfacings that likely are related.  See the *assert keyword* section
;;        at `http://reluk.ca/project/Java/Emacs/action_plan.brec`.
;;
;;   AST  At-sign as a token.  ‘It is possible to put whitespace between it and the TypeName,
;;        but this is discouraged as a matter of style.’
;;        https://docs.oracle.com/javase/specs/jls/se15/html/jls-9.html#jls-9.7.1
;;
;;   AW · Applying a wrapper using a source-based patch (`jmt--patch`).  A patch so marked either
;;        replaces a call to an original function with a call to a wrapper function, or it could be
;;        implemented this way making the alternatives below applicable all the same.
;;            (1) One alternative would be advice on a containing function that temporarily advises the
;;        original function for the duration of the call in order to wrap the call.  But temporary advice
;;        would be both non-trivial to code and likely to result in slower execution.
;;            (2) Another alternative would be advice on a containing function that temporarily redefines
;;        the original function symbol to that of the wrapper.  This is infeasible, however, because the
;;        wrapper call itself entails a call to the original function. [PGV]
;;            In the case of patches that replace macro calls `c-put-font-lock-face` with function calls,
;;        the symbol to redefine (after macro expansion) would be that of `put-text-property`, a function
;;        the replacement wrapper itself would have to call (invalid self-reference).  The alternative of
;;        redefining the macro symbol seems infeasible, too, considering it would have to be done prior
;;        to macro expansion.
;;
;;   BC · `c-before-change`: Any replacement face [RF] for a face referenced by this function
;;        must be included in its monkey patch.
;;
;;   BUG  This code is incorrect.
;;
;;   CI · Conservative inheritance.  This face inherits from `font-lock-doc-face` only to preserve
;;        the original appearance of the fontified text in default of user action to change it,
;;        and not because it is a replacement face; in fact, it is a prepended face. [PJF, RF]
;;
;;   CSL  A comment in a shebang line is supported by the `env` interpreter.
;;        https://www.gnu.org/software/coreutils/manual/html_node/env-invocation.html
;;
;;  ←CW · Backward across commentary (which in Java Mode includes newlines) and whitespace.
;;
;;   CW→  Forward across commentary (including newlines) and whitespace.
;;
;;   DW · Use of `display-warning` (as opposed to `delay-warning`) would cause all fontifiers
;;        of Java Mode Tamed to fail silently.
;;
;;   ELM  The syntax-related code that directly follows the opening of the temporary buffer effects a
;;        fast simulation of Emacs Lisp mode, faster presumeably than would a call to `emacs-lisp-mode`.
;;
;;   FCP  Formal catch parameters, aka `CatchFormalParameter` in the language specification.
;;        https://docs.oracle.com/javase/specs/jls/se15/html/jls-14.html#jls-CatchFormalParameter
;;            In multi-type parameters, Java Mode tends to leave unfaced the type and variable identi-
;;        fiers.  https://docs.oracle.com/javase/7/docs/technotes/guides/language/catch-multiple.html
;;            It does the same in rare cases of single-type catch parameter.  For example, it leaves
;;        unfaced both `FooException` and `x` in this catch block:``catch( @y.A FooException x ) {}`.
;;            The corrective fontifier implemented here becomes unstable when annotations are attached
;;        to the parameter declaration.  The likely cause is Java Mode making buffer changes outside
;;        the region under fontification by Font Lock. [BUG]
;;
;;   FLC  `font-lock-constant-face`: the Java Mode code refers to `font-lock-constant-face` indirectly
;;        by way of variables `c-constant-face-name`, `c-doc-markup-face-name`, `c-label-face-name`
;;        and `c-reference-face-name`.
;;
;;   FV · Suppressing sporadic compiler warnings ‘reference to free variable’
;;        or ‘assignment to free variable’.
;;
;;   GDA  Guarded definition of autoloads.  It would be simpler to move the autoload definitions to
;;        a separate, non-executing file, except that multi-file packages are difficult to maintain.
;;
;;   GVF  A global variable for the use of fontifiers, e.g. from within forms they quote and pass
;;        to Font Lock to be evaluated outside of their lexical scope.
;;
;;   JBL  Javadoc block tags.
;;        https://docs.oracle.com/en/java/javase/13/docs/specs/javadoc/doc-comment-spec.html#block-tags
;;
;;   JIL  Javadoc inline tags.  Double anchoring the tag search on the bounds of a `jmt-is-Java-Mode-
;;        -tag-faced` region, like the other tag fontifiers do, might make it more reliable.
;;
;;        https://docs.oracle.com/en/java/javase/13/docs/specs/javadoc/doc-comment-spec.html#inline-tags
;;
;;   K ·· Section *Keyword* of `jmt-specific-fontifiers-3`.
;;
;;  ↑K ·· Code that must execute after section *Keyword*.
;;
;;   L2U  Level-two highlighting is untamed.  ‘L2U’ marks code that enforces the fact and code
;;        that depends on it.
;;
;;   LF · `c-literal-faces`: Any replacement face of a face listed in `c-literal-faces` must itself
;;        be appended to that list.  This applies only to replacement faces, not to prepended faces;
;;        all tests against `c-literal-faces` are done using `c-got-face-at`, which knows how to deal
;;        with prepended faces. [PJF, RF]
;;
;;   MC · Method call.  See `MethodInvocation` at
;;        `https://docs.oracle.com/javase/specs/jls/se15/html/jls-15.html#jls-15.12`.
;;
;;   MD · How the value of `font-lock-maximum-decoration` governs the value of `font-lock-keywords`
;;        is described inconsistently by Emacs.  See instead the `font-lock-choose-keywords` function
;;        of `http://git.savannah.gnu.org/cgit/emacs.git/tree/lisp/font-lock.el`.  It verifies the cor-
;;        rectness of `https://www.gnu.org/software/emacs/manual/html_node/elisp/Font-Lock-Basics.html`.
;;
;;   MDF  `c-maybe-decl-faces`: Any replacement face [RF] for a face listed in `c-maybe-decl-faces`
;;        must itself be appended to that list.
;;
;;   NBE  Not ‘\'’ to match only the buffer end.  Rather ‘$’ to include the line end in the event
;;        the (narrowed) buffer happens to cross lines. [SL]
;;
;;   NCE  Not `char-equal` or `=`, which fail if the position is out of bounds.
;;        Rather `eq` which instead gives nil in that case.
;;
;;   NDF  Not a declaration face, therefore it need not be appended to `c-maybe-decl-faces`. [MDF]
;;        The face only appears in Javadoc comments.  Meanwhile `c-maybe-decl-faces` is only used,
;;        in conjunction with `c-decl-start-re`, as a bounding argument in a call to `c-find-decl-spots`.
;;        [http://git.savannah.gnu.org/cgit/emacs.git/tree/lisp/progmodes/cc-fonts.el?id=fd1b34bfba#n1490]
;;            A trace in the source of both references indicates that a ‘decl-spot’ is not something
;;        that would appear in a Javadoc comment.
;;
;;   P↓ · Code that must execute before section *Package name*  of `jmt-specific-fontifiers-3`.
;;
;;   P ·· Section *Package name* itself.
;;
;;   PGV  Patching via generalized variables (`setf`, `cl-letf`) as opposed to source (`jmt--patch`).
;;        Where a ‘patch is just to call an alternative function’ in lieu of the original, it might
;;        be implemented by applying advice that temporarily redefines the function symbol to that of
;;        a replacement function.  https://github.com/melpa/melpa/pull/7131#issuecomment-699530740
;;            The advantage would be simpler code and a faster patch.  Yet to apply this method in cases
;;        where the original function must be called from within the replacement is problematic. [AW]
;;        https://emacs.stackexchange.com/a/16810/21090
;;
;;   PJF  Prepending to the Javadoc face.  In order to duplicate the behaviour of Java Mode
;;        (e.g. see `jmt-is-Java-Mode-tag-faced`), a special face applied within a Javadoc comment
;;        (e.g. to a Javadoc tag) must not replace the `font-lock-doc-face` of the surrounding comment,
;;        but rather prepend to it.  ‘If any face … but those above is used in comments, it doesn’t
;;        replace them.’  http://git.savannah.gnu.org/cgit/emacs.git/tree/lisp/progmodes/cc-fonts.el
;;            See also e.g. the `prepend` value of the highlighter `override` argument.
;;        https://www.gnu.org/software/emacs/manual/html_node/elisp/Search_002dbased-Fontification.html
;;
;;   PPN  Parsing a package name segment.  Compare with similar code elsewhere.
;;
;;   R ·· Records, a preview language feature at time of writing.  https://openjdk.java.net/jeps/384
;;
;;   RF · Replacement face: a tamed face used by `jmt-mode` to override and replace a face
;;        earlier applied by Java Mode.  Every replacement face ultimately inherits from the face
;;        it replaces.  Function `jmt-faces-are-equivalent` depends on this.
;;
;;   SFP  Stabilization of face properties.  This stops the underlying Java Mode code obliterating
;;        the fontifications of Java Mode Tamed.
;;
;;   SI · Static import declaration.
;;        https://docs.oracle.com/javase/specs/jls/se15/html/jls-7.html#jls-7.5.3
;;
;;   SL · Restricting the fontifier to a single line.  Multi-line fontifiers can be hairy. [BUG]
;;        https://www.gnu.org/software/emacs/manual/html_node/elisp/Multiline-Font-Lock.html
;;
;;   SLS  Source-launch files encoded with a shebang.
;;        https://docs.oracle.com/en/java/javase/15/docs/specs/man/java.html#using-source-file-mode-to-launch-single-file-source-code-programs
;;        http://openjdk.java.net/jeps/330#Shebang_files
;;
;;        For a source-launch file that has no `.java` extension, if its shebang uses `-S` instead of
;;        `--split-string`, then it would have to omit the space that typically follows.  If it had the
;;        following shebang line, for instance, then auto-mode would fail:
;;
;;            #!/usr/bin/env -S ${JDK_HOME}/bin/java --source 15
;;
;;        With the above shebang, an `interpreter-mode-alist` entry would have only `-S`
;;        to match against, which does not suffice to indicate a Java file.  To avoid this,
;;        the shebang line would have to appear as:
;;
;;            #!/usr/bin/env -S${JDK_HOME}/bin/java --source 15
;;
;;        Yet, while the above seems to work (GNU coreutils 8.3), omitting the space in this manner
;;        is undescribed.  Therefore it might be better to avoid `-S` in favour of the long form,
;;        `--split-string`, which conventionally uses ‘=’ as a separator instead of a space.
;;        https://www.gnu.org/software/coreutils/manual/html_node/env-invocation.html
;;
;;   T↓ · Code that must execute before section *Type name*  of `jmt-specific-fontifiers-3`.
;;
;;   T ·· Section *Type name* itself, or code that must execute in unison with it.
;;
;;  ↑T ·· Code that must execute after section *Type name*.
;;
;;   TB · Text blocks.  https://docs.oracle.com/javase/specs/jls/se15/html/jls-3.html#jls-3.10.6
;;
;;        Java Mode stopped facing text blocks as strings sometime between Emacs 26.3 and 27.1. [BUG]
;;        Repair would likely be difficult.  http://reluk.ca/project/Java/Emacs/action_plan.brec
;;
;;   TP · See `TypeParameter`.  https://docs.oracle.com/javase/specs/jls/se15/html/jls-4.html#jls-4.4
;;
;;   TV · Type variable in a type parameter declaration.  One might think it slow to seek every
;;        type reference, as this fontifier does, and test each against the form of a type variable.
;;        Yet anchoring the search instead on the relatively infrequent characters that delimit type
;;        variable lists, while it would reduce the number of tests, might not yield the time savings
;;        one would expect; the anchoring matcher would have to extend across multiple lines and the
;;        addition to `font-lock-extend-region-functions` that this entails would burden all fontifiers.
;;
;;   TVL  Type variable list, aka `TypeParameters`.
;;        https://docs.oracle.com/javase/specs/jls/se15/html/jls-8.html#jls-8.1.2


;;; jmt-mode.el ends here
