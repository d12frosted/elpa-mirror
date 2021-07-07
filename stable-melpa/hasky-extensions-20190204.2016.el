;;; hasky-extensions.el --- Toggle Haskell language extensions -*- lexical-binding: t; -*-
;;
;; Copyright © 2016–2019 Mark Karpov <markkarpov92@gmail.com>
;;
;; Author: Mark Karpov <markkarpov92@gmail.com>
;; URL: https://github.com/hasky-mode/hasky-extensions
;; Package-Version: 20190204.2016
;; Package-Commit: 4a0d1d9beb3be8ff4a1857eb920c916734dcc8e1
;; Version: 0.2.0
;; Package-Requires: ((emacs "24.4") (avy-menu "0.2"))
;; Keywords: programming
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; The package provides a way to add and remove Haskell language extensions
;; easily from any place in a file without moving the point.  This is done
;; with help of a menu where the most popular language extensions are
;; assigned just one letter to toggle, while the others require two key
;; strokes.
;;
;; Naturally, when performing toggling of the extensions, they are kept
;; sorted and aligned automatically for you.

;;; Code:

(require 'avy-menu)
(require 'cl-lib)
(require 'simple)

(defgroup hasky-extensions nil
  "Toggle Haskell language extensions."
  :group  'programming
  :tag    "Hasky Extensions"
  :prefix "hasky-extensions-"
  :link   '(url-link :tag "GitHub"
                     "https://github.com/hasky-mode/hasky-extensions"))

(defface hasky-extensions-disabled
  '((t (:inherit font-lock-comment-face)))
  "Face used to print disabled Haskell extensions in the menu.")

(defface hasky-extensions-enabled
  '((t (:inherit font-lock-keyword-face)))
  "Face used to print enabled Haskell extensions in the menu.")

(defcustom hasky-extensions
  '("OverloadedStrings"
    "RecordWildCards"
    "CPP"
    "FlexibleContexts"
    "FlexibleInstances"
    "TemplateHaskell"
    "Arrows"
    "BangPatterns"
    "DataKinds"
    "DeriveAnyClass"
    "DeriveFoldable"
    "DeriveFunctor"
    "DeriveGeneric"
    "DeriveTraversable"
    "DerivingVia"
    "ExistentialQuantification"
    "ExplicitForAll"
    "ForeignFunctionInterface"
    "FunctionalDependencies"
    "GADTs"
    "GeneralizedNewtypeDeriving"
    "InstanceSigs"
    "KindSignatures"
    "LambdaCase"
    "MagicHash"
    "MultiParamTypeClasses"
    "MultiWayIf"
    "NoImplicitPrelude"
    "OverloadedLists"
    "PolyKinds"
    "QuantifiedConstraints"
    "QuasiQuotes"
    "RankNTypes"
    "RecursiveDo"
    "ScopedTypeVariables"
    "StandaloneDeriving"
    "TupleSections"
    "TypeApplications"
    "TypeFamilies"
    "TypeOperators"
    "TypeSynonymInstances"
    "UndecidableInstances")
  "List of commonly used Haskell extensions."
  :tag "List of commonly used Haskell extensions"
  :type '(repeat (string :tag "Extension name")))

(defcustom hasky-extensions-docs
  '(("AllowAmbiguousTypes"        "ambiguous-types-and-the-ambiguity-check")
    ("ApplicativeDo"              "applicative-do-notation")
    ("Arrows"                     "arrow-notation")
    ("BangPatterns"               "bang-patterns-informal")
    ("BinaryLiterals"             "ghc-flag--XBinaryLiterals")
    ("ConstrainedClassMethods"    "constrained-class-method-types")
    ("ConstraintKinds"            "the-constraint-kind")
    ("DataKinds"                  "datatype-promotion")
    ("DefaultSignatures"          "default-method-signatures")
    ("DeriveAnyClass"             "deriving-any-other-class")
    ("DeriveDataTypeable"         "deriving-data-instances")
    ("DeriveFoldable"             "deriving-instances-of-extra-classes-data-etc")
    ("DeriveFunctor"              "deriving-instances-of-extra-classes-data-etc")
    ("DeriveGeneric"              "deriving-instances-of-extra-classes-data-etc")
    ("DeriveLift"                 "deriving-instances-of-extra-classes-data-etc")
    ("DeriveTraversable"          "deriving-instances-of-extra-classes-data-etc")
    ("DerivingStrategies"         "deriving-strategies")
    ("DerivingVia"                "extension-DerivingVia")
    ("DisambiguateRecordFields"   "record-field-disambiguation")
    ("EmptyCase"                  "empty-case-alternatives")
    ("EmptyDataDecls"             "data-types-with-no-constructors")
    ("ExistentialQuantification"  "existentially-quantified-data-constructors")
    ("ExplicitForAll"             "explicit-universal-quantification-forall")
    ("ExplicitNamespaces"         "explicit-namespaces-in-import-export")
    ("FlexibleContexts"           "the-superclasses-of-a-class-declaration")
    ("FlexibleInstances"          "relaxed-rules-for-the-instance-head")
    ("FunctionalDependencies"     "functional-dependencies")
    ("GADTSyntax"                 "declaring-data-types-with-explicit-constructor-signatures")
    ("GADTs"                      "generalised-algebraic-data-types-gadts")
    ("GeneralizedNewtypeDeriving" "generalised-derived-instances-for-newtypes")
    ("ImplicitParams"             "implicit-parameters")
    ("ImpredicativeTypes"         "impredicative-polymorphism")
    ("IncoherentInstances"        "overlapping-instances")
    ("InstanceSigs"               "instance-signatures-type-signatures-in-instance-declarations")
    ("KindSignatures"             "explicitly-kinded-quantification")
    ("LambdaCase"                 "lambda-case")
    ("LiberalTypeSynonyms"        "liberalised-type-synonyms")
    ("MagicHash"                  "the-magic-hash")
    ("MonadComprehensions"        "monad-comprehensions")
    ("MonoLocalBinds"             "let-generalisation")
    ("MultiParamTypeClasses"      "multi-parameter-type-classes")
    ("MultiWayIf"                 "multi-way-if-expressions")
    ("NamedFieldPuns"             "record-puns")
    ("NamedWildCards"             "named-wildcards")
    ("NegativeLiterals"           "negative-literals")
    ("NoImplicitPrelude"          "rebindable-syntax-and-the-implicit-prelude-import")
    ("NoMonomorphismRestriction"  "switching-off-the-dreaded-monomorphism-restriction")
    ("NoTraditionalRecordSyntax"  "traditional-record-syntax")
    ("NullaryTypeClasses"         "nullary-type-classes")
    ("NumDecimals"                "fractional-looking-integer-literals")
    ("OverlappingInstances"       "overlapping-instances")
    ("OverloadedLists"            "overloaded-lists")
    ("OverloadedStrings"          "overloaded-string-literals")
    ("PackageImports"             "package-qualified-imports")
    ("ParallelListComp"           "parallel-list-comprehensions")
    ("PartialTypeSignatures"      "partial-type-signatures")
    ("PatternSynonyms"            "pattern-synonyms")
    ("PolyKinds"                  "kind-polymorphism-and-type-in-type")
    ("PostfixOperators"           "postfix-operators")
    ("QuantifiedConstraints"      "quantified-constraints")
    ("QuasiQuotes"                "template-haskell-quasi-quotation")
    ("Rank2Types"                 "arbitrary-rank-polymorphism")
    ("RankNTypes"                 "arbitrary-rank-polymorphism")
    ("RebindableSyntax"           "rebindable-syntax-and-the-implicit-prelude-import")
    ("RecordWildCards"            "record-wildcards")
    ("RecursiveDo"                "the-recursive-do-notation")
    ("RoleAnnotations"            "role-annotations")
    ("Safe"                       "safe-imports")
    ("ScopedTypeVariables"        "lexically-scoped-type-variables")
    ("StandaloneDeriving"         "stand-alone-deriving-declarations")
    ("StaticPointers"             "static-pointers")
    ("StrictData"                 "strict-by-default-data-types")
    ("TemplateHaskell"            "template-haskell")
    ("TransformListComp"          "generalised-sql-like-list-comprehensions")
    ("Trustworthy"                "safe-imports")
    ("TupleSections"              "tuple-sections")
    ("TypeFamilies"               "type-families")
    ("TypeFamilyDependencies"     "injective-type-families")
    ("TypeInType"                 "kind-polymorphism-and-type-in-type")
    ("TypeOperators"              "type-operators")
    ("TypeSynonymInstances"       "relaxed-rules-for-the-instance-head")
    ("UnboxedTuples"              "unboxed-tuples")
    ("UndecidableInstances"       "instance-termination-rules")
    ("UnicodeSyntax"              "unicode-syntax")
    ("Unsafe"                     "safe-imports")
    ("ViewPatterns"               "view-patterns"))
  "A collection of extensions with links to GHC user guide."
  :tag "List of all Haskell extensions with links to docs"
  :type '(repeat (list (string :tag "Extension name")
                       (string :tag "Anchor"))))

(defcustom hasky-extensions-reach 5000
  "Max number of characters from beginning of file to search.

Very large files can either slow down the process of extensions
detection or cause stack overflows, thus we limit number of
characters the package traverses.  The default value should be
appropriate for most users since language extension pragmas are
typically placed at the beginning of a file.  If you wish to
disable the limitation, set this value to NIL (not recommended)."
  :tag "How many characters from beginning of file to scan"
  :type 'integer)

(defcustom hasky-extensions-sorting t
  "Whether to keep the collection of extensions sorted."
  :tag "Keep list of extensions sorted"
  :type 'boolean)

(defcustom hasky-extensions-aligning t
  "Whether to keep closing braces of extension pragmas aligned."
  :tag "Keep closing braces of extension pragmas aligned"
  :type 'boolean)

(defcustom hasky-extensions-prettifying-hook nil
  "Hook to run after prettifying of extension section."
  :tag "Hooks to run after prettifying list of extensions"
  :type 'hook)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The editing itself

(defun hasky-extensions--next-ext (&optional ext)
  "Find and return name of next extension in the file or NIL.

If EXT is supplied, find this particular extension."
  (re-search-forward
   (concat "^\\s-*{-#\\s-*LANGUAGE\\s-+\\("
           (if ext
               (regexp-quote ext)
             "[[:alnum:]]+")
           "\\)\\s-*#-}\\s-*?$")
   hasky-extensions-reach t))

(defun hasky-extensions-list ()
  "List all active Haskell extensions in current file.

Returned list is always a fresh one (you can perform destructive
operations on it without fear).

This does not take into account extensions enabled in Cabal file
with “default-extensions” or similar settings."
  (let (exts)
    (save-excursion
      (goto-char (point-min))
      (while (hasky-extensions--next-ext)
        (push (match-string-no-properties 1) exts)))
    exts))

(defun hasky-extensions--prettify-exts ()
  "Find, sort, and align extensions in current file if necessary."
  (save-excursion
    (goto-char (point-min))
    (let ((beg (when (hasky-extensions--next-ext)
                 (match-beginning 0))))
      (when beg
        (goto-char beg)
        (while (progn
                 (forward-line)
                 (when (looking-at "\\(^\\s-+\\){-#")
                   (delete-region (match-beginning 1) (match-end 1)))
                 (looking-at "^\\s-*{-#.*?#-}\\s-*?$")))
        (let ((end (point))
              (indent-tabs-mode nil))
          (when hasky-extensions-sorting
            (sort-lines nil beg end))
          (when hasky-extensions-aligning
            (align-regexp beg end "\\(\\s-*\\)#-}"))))))
  (run-hooks 'hasky-extensions-prettifying-hook))

(defun hasky-extensions-add (extension)
  "Insert EXTENSION into appropriate place in current file."
  ;; NOTE There are several scenarios we should support.  First, if file
  ;; contains some extensions already, we should add the new one to them.
  ;; If there is no extensions in the file yet, place the new one before
  ;; module declaration (with one empty line between them).  If The file
  ;; contains no module declaration yet, place the new extension after
  ;; header.  If the file has no header, place the new extension at the
  ;; beginning of the file.
  (save-excursion
    (let ((ext (format "{-# LANGUAGE %s #-}\n" extension)))
      (cond ((progn
               (goto-char (point-min))
               (hasky-extensions--next-ext))
             (beginning-of-line))
            ((progn
               (goto-char (point-min))
               (re-search-forward
                "^module"
                hasky-extensions-reach
                t))
             (beginning-of-line)
             (open-line 1))
            ((let (going)
               (goto-char (point-min))
               (while (re-search-forward
                       "^--.*?$"
                       hasky-extensions-reach
                       t)
                 (setq going t))
               going)
             (goto-char (match-end 0))
             (forward-line)
             (newline))
            (t (goto-char (point-min))))
      (insert ext)
      (hasky-extensions--prettify-exts))))

(defun hasky-extensions-remove (extension)
  "Remove EXTENSION from current file (if present)."
  (save-excursion
    (goto-char (point-min))
    (when (hasky-extensions--next-ext extension)
      (delete-region (match-beginning 0) (match-end 0))
      (unless (eobp)
        (when (looking-at "$")
          (delete-char 1)))
      (hasky-extensions--prettify-exts))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User interface

;;;###autoload
(defun hasky-extensions ()
  "Invoke a menu for managing Haskell language extensions."
  (interactive)
  (let ((exts (hasky-extensions-list))
        (selected t))
    (while selected
      (setq
       selected
       (avy-menu
        "*hasky-extensions*"
        (cons
         "Haskell Extensions"
         (list
          (cons
           "Pane"
           (mapcar
            (lambda (x)
              (let ((active (cl-find x exts :test #'string=)))
                (cons
                 (propertize
                  x
                  'face
                  (if active
                      'hasky-extensions-enabled
                    'hasky-extensions-disabled))
                 (cons x active))))
            hasky-extensions))))))
      (when selected
        (cl-destructuring-bind (ext . active) selected
          (if active
              (progn
                (hasky-extensions-remove ext)
                (setq exts (cl-delete ext exts :test #'string=)))
            (hasky-extensions-add ext)
            (cl-pushnew ext exts :test #'string=)))))))

;;;###autoload
(defun hasky-extensions-browse-docs (extension)
  "Browse documentation about EXTENSION from GHC user guide in browser."
  (interactive
   (list
    (let ((exts (mapcar #'car hasky-extensions-docs)))
      (completing-read
       "Extension: "
       exts
       nil t nil nil
       (car exts)))))
  (browse-url
   (concat "https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/glasgow_exts.html#"
           (cadr (assoc extension hasky-extensions-docs)))))

(provide 'hasky-extensions)

;;; hasky-extensions.el ends here
