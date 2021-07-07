;;; phan.el --- Utility functions for Phan (PHP static analizer)  -*- lexical-binding: t -*-

;; Copyright (C) 2018  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@pixiv.com>
;; Created: 28 Jan 2017
;; Version: 0.0.4
;; Package-Version: 20180528.339
;; Package-Commit: 6b077b3421a0b2c0b98a6906b8ab0d14d9d7bf50
;; Keywords: tools php
;; Package-Requires: ((emacs "24") (composer "0.0.8") (f "0.17"))
;; URL: https://github.com/emacs-php/phan.el

;; This file is NOT part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Phan is static analizer for PHP.  https://github.com/etsy/phan
;; This package has utilities and major mode for phan log format.
;;
;; # Major modes
;;
;; ## phan-log-mode
;;
;; A major mode for viewing Phan log format.
;;
;; # Commands
;;
;; ## phan-find-config-file
;;
;; Open `.phan/config.php' of current directory.
;;


;;; Code:
(require 'composer)
(require 'f)

(defgroup phan nil
  "Utilities for Phan (PHP static analizer)"
  :prefix "phan-"
  :link '(url-link :tag "Phan Wiki" "https://github.com/phan/phan/wiki")
  :link '(url-link :tag "phan.el site" "https://github.com/emacs-php/phan.el")
  :group 'tools
  :group 'php)

(defconst phan-php-types
  '("array" "bool" "float" "int" "null" "resource" "string" "void"))

(defconst phan-issues
  '(;; Issue::CATEGORY_SYNTAX
    "PhanSyntaxError"
    ;; Removed issues
    "PhanUnreferencedMethod"
    "PhanUnreferencedProperty"

    ;; Issue::CATEGORY_UNDEFINED
    "PhanAmbiguousTraitAliasSource"
    "PhanClassContainsAbstractMethodInternal"
    "PhanClassContainsAbstractMethod"
    "PhanEmptyFile"
    "PhanParentlessClass"
    "PhanRequiredTraitNotAdded"
    "PhanTraitParentReference"
    "PhanUndeclaredAliasedMethodOfTrait"
    "PhanUndeclaredClass"
    "PhanUndeclaredClassAliasOriginal"
    "PhanUndeclaredClassCatch"
    "PhanUndeclaredClassConstant"
    "PhanUndeclaredClassInstanceof"
    "PhanUndeclaredClassMethod"
    "PhanUndeclaredClassReference"
    "PhanUndeclaredClosureScope"
    "PhanUndeclaredConstant"
    "PhanUndeclaredExtendedClass"
    "PhanUndeclaredFunction"
    "PhanUndeclaredInterface"
    "PhanUndeclaredMethod"
    "PhanUndeclaredProperty"
    "PhanUndeclaredStaticMethod"
    "PhanUndeclaredStaticProperty"
    "PhanUndeclaredTrait"
    "PhanUndeclaredTypeParameter"
    "PhanUndeclaredTypeReturnType"
    "PhanUndeclaredTypeProperty"
    "PhanUndeclaredTypeThrowsType"
    "PhanUndeclaredVariable"
    "PhanUndeclaredVariableDim"
    "PhanUndeclaredClassInCallable"
    "PhanUndeclaredStaticMethodInCallable"
    "PhanUndeclaredFunctionInCallable"
    "PhanUndeclaredMethodInCallable"
    "PhanEmptyFQSENInCallable"
    "PhanEmptyFQSENInClasslike"

    ;; Issue::CATEGORY_TYPE
    "PhanNonClassMethodCall"
    "PhanTypeArrayOperator"
    "PhanTypeArraySuspicious"
    "PhanTypeArrayUnsetSuspicious"
    "PhanTypeArraySuspiciousNullable"
    "PhanTypeSuspiciousIndirectVariable"
    "PhanTypeComparisonFromArray"
    "PhanTypeComparisonToArray"
    "PhanTypeConversionFromArray"
    "PhanTypeInstantiateAbstract"
    "PhanTypeInstantiateInterface"
    "PhanTypeInvalidClosureScope"
    "PhanTypeInvalidLeftOperand"
    "PhanTypeInvalidRightOperand"
    "PhanTypeInvalidInstanceof"
    "PhanTypeInvalidDimOffset"
    "PhanTypeInvalidDimOffsetArrayDestructuring"
    "PhanTypeInvalidThrowsNonObject"
    "PhanTypeInvalidThrowsNonThrowable"
    "PhanTypeInvalidThrowsIsTrait"
    "PhanTypeInvalidThrowsIsInterface"
    "PhanTypeMagicVoidWithReturn"
    "PhanTypeMismatchArgument"
    "PhanTypeMismatchArgumentInternal"
    "PhanPartialTypeMismatchArgument"
    "PhanPartialTypeMismatchArgumentInternal"
    "PhanPossiblyNullTypeArgument"
    "PhanPossiblyNullTypeArgumentInternal"
    "PhanPossiblyFalseTypeArgument"
    "PhanPossiblyFalseTypeArgumentInternal"

    "PhanTypeMismatchDefault"
    "PhanTypeMismatchDimAssignment"
    "PhanTypeMismatchDimEmpty"
    "PhanTypeMismatchDimFetch"
    "PhanTypeMismatchDimFetchNullable"
    "PhanTypeMismatchUnpackKey"
    "PhanTypeMismatchUnpackValue"
    "PhanTypeMismatchArrayDestructuringKey"
    "PhanMismatchVariadicComment"
    "PhanMismatchVariadicParam"
    "PhanTypeMismatchForeach"
    "PhanTypeMismatchProperty"
    "PhanPossiblyNullTypeMismatchProperty"
    "PhanPossiblyFalseTypeMismatchProperty"
    "PhanPartialTypeMismatchProperty"
    "PhanTypeMismatchReturn"
    "PhanPartialTypeMismatchReturn"
    "PhanPossiblyNullTypeReturn"
    "PhanPossiblyFalseTypeReturn"
    "PhanTypeMismatchDeclaredReturn"
    "PhanTypeMismatchDeclaredReturnNullable"
    "PhanTypeMismatchDeclaredParam"
    "PhanTypeMismatchDeclaredParamNullable"
    "PhanTypeMissingReturn"
    "PhanTypeNonVarPassByRef"
    "PhanTypeParentConstructorCalled"
    "PhanTypeSuspiciousEcho"
    "PhanTypeSuspiciousStringExpression"
    "PhanTypeVoidAssignment"
    "PhanTypeInvalidCallableArraySize"
    "PhanTypeInvalidCallableArrayKey"
    "PhanTypeInvalidCallableObjectOfMethod"
    "PhanTypeExpectedObject"
    "PhanTypeExpectedObjectOrClassName"
    "PhanTypeExpectedObjectPropAccess"
    "PhanTypeExpectedObjectPropAccessButGotNull"
    "PhanTypeExpectedObjectStaticPropAccess"

    "PhanTypeMismatchGeneratorYieldValue"
    "PhanTypeMismatchGeneratorYieldKey"
    "PhanTypeInvalidYieldFrom"

    ;; Issue::CATEGORY_ANALYSIS
    "PhanUnanalyzable"
    "PhanUnanalyzableInheritance"

    ;; Issue::CATEGORY_VARIABLE
    "PhanVariableUseClause"

    ;; Issue::CATEGORY_STATIC
    "PhanStaticCallToNonStatic"

    ;; Issue::CATEGORY_CONTEXT
    "PhanContextNotObject"
    "PhanContextNotObjectInCallable"

    ;; Issue::CATEGORY_DEPRECATED
    "PhanDeprecatedClass"
    "PhanDeprecatedInterface"
    "PhanDeprecatedTrait"
    "PhanDeprecatedFunction"
    "PhanDeprecatedFunctionInternal"
    "PhanDeprecatedProperty"

    ;; Issue::CATEGORY_PARAMETER
    "PhanParamReqAfterOpt"
    "PhanParamSpecial1"
    "PhanParamSpecial2"
    "PhanParamSpecial3"
    "PhanParamSpecial4"
    "PhanParamSuspiciousOrder"
    "PhanParamTooFew"
    "PhanParamTooFewInternal"
    "PhanParamTooFewCallable"
    "PhanParamTooMany"
    "PhanParamTooManyInternal"
    "PhanParamTooManyCallable"
    "PhanParamTypeMismatch"
    "PhanParamSignatureMismatch"
    "PhanParamSignatureMismatchInternal"
    "PhanParamRedefined"

    "PhanParamSignatureRealMismatchReturnType"
    "PhanParamSignatureRealMismatchReturnTypeInternal"
    "PhanParamSignaturePHPDocMismatchReturnType"
    "PhanParamSignatureRealMismatchTooManyRequiredParameters"
    "PhanParamSignatureRealMismatchTooManyRequiredParametersInternal"
    "PhanParamSignaturePHPDocMismatchTooManyRequiredParameters"
    "PhanParamSignatureRealMismatchTooFewParameters"
    "PhanParamSignatureRealMismatchTooFewParametersInternal"
    "PhanParamSignaturePHPDocMismatchTooFewParameters"
    "PhanParamSignatureRealMismatchHasParamType"
    "PhanParamSignatureRealMismatchHasParamTypeInternal"
    "PhanParamSignaturePHPDocMismatchHasParamType"
    "PhanParamSignatureRealMismatchHasNoParamType"
    "PhanParamSignatureRealMismatchHasNoParamTypeInternal"
    "PhanParamSignaturePHPDocMismatchHasNoParamType"
    "PhanParamSignatureRealMismatchParamIsReference"
    "PhanParamSignatureRealMismatchParamIsReferenceInternal"
    "PhanParamSignaturePHPDocMismatchParamIsReference"
    "PhanParamSignatureRealMismatchParamIsNotReference"
    "PhanParamSignatureRealMismatchParamIsNotReferenceInternal"
    "PhanParamSignaturePHPDocMismatchParamIsNotReference"
    "PhanParamSignatureRealMismatchParamVariadic"
    "PhanParamSignatureRealMismatchParamVariadicInternal"
    "PhanParamSignaturePHPDocMismatchParamVariadic"
    "PhanParamSignatureRealMismatchParamNotVariadic"
    "PhanParamSignatureRealMismatchParamNotVariadicInternal"
    "PhanParamSignaturePHPDocMismatchParamNotVariadic"
    "PhanParamSignatureRealMismatchParamType"
    "PhanParamSignatureRealMismatchParamTypeInternal"
    "PhanParamSignaturePHPDocMismatchParamType"

    ;; Issue::CATEGORY_NOOP
    "PhanNoopArray"
    "PhanNoopClosure"
    "PhanNoopConstant"
    "PhanNoopProperty"
    "PhanNoopVariable"
    "PhanNoopUnaryOperator"
    "PhanNoopBinaryOperator"
    "PhanNoopStringLiteral"
    "PhanNoopEncapsulatedStringLiteral"
    "PhanNoopNumericLiteral"
    "PhanUnreachableCatch"
    "PhanUnreferencedClass"
    "PhanUnreferencedFunction"
    "PhanUnreferencedPublicMethod"
    "PhanUnreferencedProtectedMethod"
    "PhanUnreferencedPrivateMethod"
    "PhanUnreferencedPublicProperty"
    "PhanUnreferencedProtectedProperty"
    "PhanUnreferencedPrivateProperty"
    "PhanReadOnlyPublicProperty"
    "PhanReadOnlyProtectedProperty"
    "PhanReadOnlyPrivateProperty"
    "PhanWriteOnlyPublicProperty"
    "PhanWriteOnlyProtectedProperty"
    "PhanWriteOnlyPrivateProperty"
    "PhanUnreferencedConstant"
    "PhanUnreferencedPublicClassConstant"
    "PhanUnreferencedProtectedClassConstant"
    "PhanUnreferencedPrivateClassConstant"
    "PhanUnreferencedClosure"
    "PhanUnreferencedUseNormal"
    "PhanUnreferencedUseFunction"
    "PhanUnreferencedUseConstant"

    "PhanUnusedVariable"
    "PhanUnusedPublicMethodParameter"
    "PhanUnusedPublicFinalMethodParameter"
    "PhanUnusedProtectedMethodParameter"
    "PhanUnusedProtectedFinalMethodParameter"
    "PhanUnusedPrivateMethodParameter"
    "PhanUnusedPrivateFinalMethodParameter"
    "PhanUnusedClosureUseVariable"
    "PhanUnusedClosureParameter"
    "PhanUnusedGlobalFunctionParameter"
    "PhanUnusedVariableValueOfForeachWithKey"

    ;; Issue::CATEGORY_REDEFINE
    "PhanRedefineClass"
    "PhanRedefineClassAlias"
    "PhanRedefineClassInternal"
    "PhanRedefineFunction"
    "PhanRedefineFunctionInternal"
    "PhanIncompatibleCompositionProp"
    "PhanIncompatibleCompositionMethod"

    ;; Issue::CATEGORY_ACCESS
    "PhanAccessPropertyPrivate"
    "PhanAccessPropertyProtected"
    "PhanAccessMethodPrivate"
    "PhanAccessMethodPrivateWithCallMagicMethod"
    "PhanAccessMethodProtected"
    "PhanAccessMethodProtectedWithCallMagicMethod"
    "PhanAccessSignatureMismatch"
    "PhanAccessSignatureMismatchInternal"
    "PhanAccessStaticToNonStatic"
    "PhanAccessNonStaticToStatic"
    "PhanAccessClassConstantPrivate"
    "PhanAccessClassConstantProtected"
    "PhanAccessPropertyStaticAsNonStatic"
    "PhanAccessPropertyNonStaticAsStatic"
    "PhanAccessOwnConstructor"

    "PhanAccessConstantInternal"
    "PhanAccessClassInternal"
    "PhanAccessClassConstantInternal"
    "PhanAccessPropertyInternal"
    "PhanAccessMethodInternal"
    "PhanAccessWrongInheritanceCategory"
    "PhanAccessWrongInheritanceCategoryInternal"
    "PhanAccessExtendsFinalClass"
    "PhanAccessExtendsFinalClassInternal"
    "PhanAccessOverridesFinalMethod"
    "PhanAccessOverridesFinalMethodInternal"
    "PhanAccessOverridesFinalMethodPHPDoc"

    ;; Issue::CATEGORY_COMPATIBLE
    "PhanCompatibleExpressionPHP7"
    "PhanCompatiblePHP7"
    "PhanCompatibleNullableTypePHP70"
    "PhanCompatibleShortArrayAssignPHP70"
    "PhanCompatibleKeyedArrayAssignPHP70"
    "PhanCompatibleVoidTypePHP70"
    "PhanCompatibleIterableTypePHP70"
    "PhanCompatibleNullableTypePHP71"

    ;; Issue::CATEGORY_GENERIC
    "PhanTemplateTypeConstant"
    "PhanTemplateTypeStaticMethod"
    "PhanTemplateTypeStaticProperty"
    "PhanGenericGlobalVariable"
    "PhanGenericConstructorTypes"

    ;; Issue::CATEGORY_COMMENT
    "PhanInvalidCommentForDeclarationType"
    "PhanMisspelledAnnotation"
    "PhanUnextractableAnnotation"
    "PhanUnextractableAnnotationPart"
    "PhanUnextractableAnnotationSuffix"
    "PhanUnextractableAnnotationElementName"
    "PhanCommentParamWithoutRealParam"
    "PhanCommentParamOnEmptyParamList"
    "PhanCommentOverrideOnNonOverrideMethod"
    "PhanCommentOverrideOnNonOverrideConstant"
    "PhanCommentParamOutOfOrder"
    )
  "Issue names of Phan.

https://github.com/etsy/phan/blob/master/src/Phan/Issue.php
https://github.com/etsy/phan/wiki/Issue-Types-Caught-by-Phan")

(defconst phan-log-warning-keywords
  '("can't be"
    "deprecated"
    "has no return value"
    "not found"
    "only takes"
    "should be compatible"
    "Suspicious"
    "undeclared"
    "unextractable annotation"))

(defconst phan-log-class-prefix-keywords
  '(":" "but" "class" "for" "function" "is" "method" "property" "return" "takes" "to" "type"
    "Class" "Property"))

(defconst phan-log-function-prefix-keywords
  '("Function" "Method"))

(defconst phan-log-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?$  "_" table)
    (modify-syntax-entry ?-  "_" table)
    (modify-syntax-entry ?.  "_" table)
    (modify-syntax-entry ?/  "_" table)
    (modify-syntax-entry ?:  "." table)
    (modify-syntax-entry ?>  "." table)
    (modify-syntax-entry ?\( "_" table)
    (modify-syntax-entry ?\) "_" table)
    (modify-syntax-entry ?\\ "_" table)
    (modify-syntax-entry ?_  "_" table)
    (modify-syntax-entry ??  "_" table)
    (modify-syntax-entry ?|  "_" table)
    table))

(defconst phan-log-font-lock-keywords
  (list
   (list "^\\([^:]+\\):\\([0-9]+\\)"
         '(1 font-lock-doc-face)
         '(2 font-lock-builtin-face))
   (cons (concat "\\(?:\\`\\|[ |[]\\)\\(" (regexp-opt phan-php-types) "\\)\\(?:[ |,[]\\|$\\)")
         '(1 font-lock-type-face))
   (cons "\\[]" '(0 font-lock-type-face))
   (cons (concat " " (regexp-opt phan-issues) " ")
         '(0 font-lock-keyword-face))
   (cons (concat "\\(?:\\`\\| \\)\\(" (regexp-opt phan-log-warning-keywords) "\\)[ $,]")
         '(1 font-lock-warning-face))
   (cons (concat "\\(?:|\\|, \\| " (regexp-opt phan-log-class-prefix-keywords) " \\)"
                 (rx (group (? "\\") (+ (or "|" (syntax word) (syntax symbol))) "()")))
         '(1 font-lock-function-name-face))
   (cons (concat "\\(?:|\\|, \\| " (regexp-opt phan-log-class-prefix-keywords) " \\)"
                 (rx (group "\\" (+ (or "?" "|" "[]" (syntax word) (syntax symbol))))))
         '(1 font-lock-type-face))
   (cons (concat "\\(?:|\\|, \\| " (regexp-opt phan-log-function-prefix-keywords) " \\)"
                 (rx (group "\\" (+ (or (syntax word) (syntax symbol))))))
         '(1 font-lock-function-name-face))
   (cons " constant \\(\\(?:\\sw\\|\\s_\\)+\\)"
         '(1 font-lock-constant-face))
   (cons "\\(?:::\\|->\\)\\(\\(?:\\sw\\|\\s_\\)+()\\)"
         '(1 font-lock-function-name-face))
   (cons "::\\(\\(?:\\sw\\|\\s_\\)+\\)"
         '(1 font-lock-constant-face))
   (cons " \\(?:Argument [0-9]+\\|annotation for\\) (\\(\\(?:\\sw\\|\\s_\\)+\\))"
         '(1 font-lock-variable-name-face))
   (cons " Argument [0-9]+ (\\(\\(?:\\sw\\|\\s_\\)+\\))"
         '(1 font-lock-variable-name-face))
   (cons " Call to method \\([^\n\\][^\n ]*\\) "
         '(1 font-lock-function-name-face))
   (cons "\\(?:\\$\\|->\\)\\(\\sw\\|\\s_\\)+"
         '(0 font-lock-variable-name-face))))

;; Utility functions
(defun phan--base-dir (directory)
  "Return path to current project root in `DIRECTORY'."
  (or (locate-dominating-file directory ".phan/config.php")
      (composer--find-composer-root directory)))

;; Major modes

;;;###autoload
(define-derived-mode phan-log-mode prog-mode "Phan-Log"
  "Major mode for viewing phan formatted log."
  (setq font-lock-defaults '(phan-log-font-lock-keywords))
  (view-mode))

;;;###autoload
(add-to-list 'auto-mode-alist '("/phan.*\\.log\\'" . phan-log-mode))

;; Commands

;;;###autoload
(defun phan-find-config-file ()
  "Open Phan config file of the project."
  (interactive)
  (if (null default-directory)
      (error "A variable `default-directory' is not set")
    (find-file (f-join (phan--base-dir default-directory) ".phan/config.php"))))

(provide 'phan)
;;; phan.el ends here
