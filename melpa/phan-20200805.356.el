;;; phan.el --- Utility functions for Phan (PHP static analizer)  -*- lexical-binding: t -*-

;; Copyright (C) 2018  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@pixiv.com>
;; Created: 28 Jan 2017
;; Version: 0.0.4
;; Package-Version: 20200805.356
;; Package-Commit: b7d523630bb072c4dbcfa9995dc734b25b72a69f
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

;; Phan is static analizer for PHP.  https://github.com/phan/phan
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
  '("array" "associative-array" "bool" "callable" "callable-array"
    "callable-object" "callable-string" "false" "float" "int" "iterable"
    "list" "mixed" "void" "non-empty-array" "non-empty-associative-array"
    "non-empty-list" "null" "resource" "string" "true" "void"))

(defconst phan-issues
  '(;; Issue::CATEGORY_SYNTAX
    "PhanSyntaxError"
    "PhanInvalidConstantExpression"
    "PhanInvalidNode"
    "PhanInvalidWriteToTemporaryExpression"
    "PhanInvalidTraitUse"
    "PhanContinueTargetingSwitch"
    "PhanContinueOrBreakNotInLoop"
    "PhanContinueOrBreakTooManyLevels"
    "PhanSyntaxCompileWarning"
    "PhanSyntaxEmptyListArrayDestructuring"
    "PhanSyntaxMixedKeyNoKeyArrayDestructuring"
    "PhanSyntaxReturnExpectedValue"
    "PhanSyntaxReturnValueInVoid"

    ;; Removed issues
    "PhanCompatibleNullableTypePHP71"
    "PhanTypeInvalidPropertyDefaultReal"
    "PhanUnreferencedMethod"
    "PhanUnreferencedProperty"

    ;; Issue::CATEGORY_UNDEFINED
    "PhanAmbiguousTraitAliasSource"
    "PhanClassContainsAbstractMethodInternal"
    "PhanClassContainsAbstractMethod"
    "PhanEmptyFile"
    "PhanMissingRequireFile"
    "PhanInvalidRequireFile"
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
    "PhanUndeclaredClassProperty"
    "PhanUndeclaredClassReference"
    "PhanUndeclaredClassStaticProperty"
    "PhanUndeclaredClosureScope"
    "PhanUndeclaredConstant"
    "PhanUndeclaredConstantOfClass"
    "PhanUndeclaredMagicConstant"
    "PhanUndeclaredExtendedClass"
    "PhanUndeclaredFunction"
    "PhanUndeclaredInterface"
    "PhanUndeclaredMethod"
    "PhanPossiblyUndeclaredMethod"
    "PhanUndeclaredProperty"
    "PhanPossiblyUndeclaredProperty"
    "PhanUndeclaredStaticMethod"
    "PhanUndeclaredStaticProperty"
    "PhanUndeclaredTrait"
    "PhanUndeclaredTypeParameter"
    "PhanUndeclaredTypeReturnType"
    "PhanUndeclaredTypeProperty"
    "PhanUndeclaredTypeClassConstant"
    "PhanUndeclaredTypeThrowsType"
    "PhanUndeclaredVariable"
    "PhanPossiblyUndeclaredVariable"
    "PhanUndeclaredGlobalVariable"
    "PhanPossiblyUndeclaredGlobalVariable"
    "PhanUndeclaredThis"
    "PhanUndeclaredVariableDim"
    "PhanUndeclaredVariableAssignOp"
    "PhanUndeclaredClassInCallable"
    "PhanUndeclaredStaticMethodInCallable"
    "PhanUndeclaredFunctionInCallable"
    "PhanUndeclaredMethodInCallable"
    "PhanUndeclaredInvokeInCallable"
    "PhanEmptyFQSENInCallable"
    "PhanInvalidFQSENInCallable"
    "PhanEmptyFQSENInClasslike"
    "PhanInvalidFQSENInClasslike"
    "PhanPossiblyUnsetPropertyOfThis"

    ;; Issue::CATEGORY_TYPE
    "PhanNonClassMethodCall"
    "PhanPossiblyNonClassMethodCall"
    "PhanTypeArrayOperator"
    "PhanTypeInvalidBitwiseBinaryOperator"
    "PhanTypeMismatchBitwiseBinaryOperands"
    "PhanTypeArraySuspicious"
    "PhanTypeArrayUnsetSuspicious"
    "PhanTypeArraySuspiciousNullable"
    "PhanTypeArraySuspiciousNull"
    "PhanTypeSuspiciousIndirectVariable"
    "PhanTypeObjectUnsetDeclaredProperty"
    "PhanTypeComparisonFromArray"
    "PhanTypeComparisonToArray"
    "PhanTypeConversionFromArray"
    "PhanTypeInstantiateAbstract"
    "PhanTypeInstantiateAbstractStatic"
    "PhanTypeInstantiateInterface"
    "PhanTypeInstantiateTrait"
    "PhanTypeInstantiateTraitStaticOrSelf"
    "PhanTypeInvalidCloneNotObject"
    "PhanTypePossiblyInvalidCloneNotObject"
    "PhanTypeInvalidClosureScope"
    "PhanTypeInvalidLeftOperand"
    "PhanTypeInvalidRightOperand"
    "PhanTypeInvalidLeftOperandOfAdd"
    "PhanTypeInvalidRightOperandOfAdd"
    "PhanTypeInvalidLeftOperandOfNumericOp"
    "PhanTypeInvalidRightOperandOfNumericOp"
    "PhanTypeInvalidLeftOperandOfIntegerOp"
    "PhanTypeInvalidRightOperandOfIntegerOp"
    "PhanTypeInvalidLeftOperandOfBitwiseOp"
    "PhanTypeInvalidRightOperandOfBitwiseOp"
    "PhanTypeInvalidUnaryOperandNumeric"
    "PhanTypeInvalidUnaryOperandBitwiseNot"
    "PhanTypeInvalidUnaryOperandIncOrDec"
    "PhanTypeInvalidInstanceof"
    "PhanTypeInvalidDimOffset"
    "PhanTypeInvalidDimOffsetArrayDestructuring"
    "PhanTypePossiblyInvalidDimOffset"
    "PhanTypeInvalidCallExpressionAssignment"
    "PhanTypeInvalidExpressionArrayDestructuring"
    "PhanTypeInvalidThrowsNonObject"
    "PhanTypeInvalidThrowsNonThrowable"
    "PhanTypeInvalidThrowStatementNonThrowable"
    "PhanTypeInvalidThrowsIsTrait"
    "PhanTypeInvalidThrowsIsInterface"
    "PhanTypeMagicVoidWithReturn"
    "PhanTypeMismatchArgument"
    "PhanTypeMismatchArgumentProbablyReal"
    "PhanTypeMismatchArgumentReal"
    "PhanTypeMismatchArgumentNullable"
    "PhanTypeMismatchArgumentInternal"
    "PhanTypeMismatchArgumentInternalProbablyReal"
    "PhanTypeMismatchArgumentInternalReal"
    "PhanTypeMismatchArgumentNullableInternal"
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
    "PhanTypeMismatchUnpackKeyArraySpread"
    "PhanTypeMismatchUnpackValue"
    "PhanTypeMismatchArrayDestructuringKey"
    "PhanMismatchVariadicComment"
    "PhanMismatchVariadicParam"
    "PhanTypeMismatchForeach"
    "PhanTypeNoAccessiblePropertiesForeach"
    "PhanTypeNoPropertiesForeach"
    "PhanTypeSuspiciousNonTraversableForeach"
    "PhanTypeMismatchProperty"
    "PhanPossiblyNullTypeMismatchProperty"
    "PhanPossiblyFalseTypeMismatchProperty"
    "PhanPartialTypeMismatchProperty"
    "PhanTypeMismatchReturn"
    "PhanTypeMismatchReturnNullable"
    "PhanTypeMismatchReturnProbablyReal"
    "PhanTypeMismatchReturnReal"
    "PhanPartialTypeMismatchReturn"
    "PhanPossiblyNullTypeReturn"
    "PhanPossiblyFalseTypeReturn"
    "PhanTypeMismatchDeclaredReturn"
    "PhanTypeMismatchDeclaredReturnNullable"
    "PhanTypeMismatchDeclaredParam"
    "PhanTypeMismatchDeclaredParamNullable"
    "PhanTypeMissingReturn"
    "PhanTypeMissingReturnReal"
    "PhanTypeNonVarPassByRef"
    "PhanTypeNonVarReturnByRef"
    "PhanTypeParentConstructorCalled"
    "PhanTypeSuspiciousEcho"
    "PhanTypeSuspiciousStringExpression"
    "PhanTypeVoidAssignment"
    "PhanTypeVoidArgument"
    "PhanTypeVoidExpression"
    "PhanTypePossiblyInvalidCallable"
    "PhanTypeInvalidCallable"
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
    "PhanTypeInvalidMethodName"
    "PhanTypeInvalidStaticMethodName"
    "PhanTypeInvalidCallableMethodName"
    "PhanTypeInvalidRequire"
    "PhanTypeInvalidEval"
    "PhanRelativePathUsed"
    "PhanTypeInvalidTraitReturn"
    "PhanTypeInvalidTraitParam"
    "PhanInfiniteRecursion"
    "PhanPossiblyInfiniteRecursionSameParams"
    "PhanTypeComparisonToInvalidClass"
    "PhanTypeComparisonToInvalidClassType"
    "PhanTypeInvalidPropertyName"
    "PhanTypeInvalidStaticPropertyName"
    "PhanTypeErrorInInternalCall"
    "PhanTypeErrorInOperation"
    "PhanTypeMismatchPropertyDefault"
    "PhanTypeMismatchPropertyDefaultReal"
    "PhanTypeMismatchPropertyProbablyReal"
    "PhanTypeMismatchPropertyReal"
    "PhanTypeMismatchPropertyRealByRef"
    "PhanTypeMismatchPropertyByRef"
    "PhanImpossibleCondition"
    "PhanImpossibleConditionInLoop"
    "PhanImpossibleConditionInGlobalScope"
    "PhanRedundantCondition"
    "PhanRedundantConditionInLoop"
    "PhanRedundantConditionInGlobalScope"
    "PhanInfiniteLoop"
    "PhanImpossibleTypeComparison"
    "PhanImpossibleTypeComparisonInLoop"
    "PhanImpossibleTypeComparisonInGlobalScope"
    "PhanSuspiciousValueComparison"
    "PhanSuspiciousValueComparisonInLoop"
    "PhanSuspiciousValueComparisonInGlobalScope"
    "PhanSuspiciousLoopDirection"
    "PhanSuspiciousWeakTypeComparison"
    "PhanSuspiciousWeakTypeComparisonInLoop"
    "PhanSuspiciousWeakTypeComparisonInGlobalScope"
    "PhanSuspiciousTruthyCondition"
    "PhanSuspiciousTruthyString"
    "PhanCoalescingNeverNull"
    "PhanCoalescingNeverNullInLoop"
    "PhanCoalescingNeverNullInGlobalScope"
    "PhanCoalescingAlwaysNull"
    "PhanCoalescingAlwaysNullInLoop"
    "PhanCoalescingAlwaysNullInGlobalScope"
    "PhanCoalescingNeverUndefined"
    "PhanTypeMismatchArgumentPropertyReference"
    "PhanTypeMismatchArgumentPropertyReferenceReal"
    "PhanDivisionByZero"
    "PhanModuloByZero"
    "PhanPowerOfZero"
    "PhanInvalidMixin"
    "PhanIncompatibleRealPropertyType"

    ;; Issue::CATEGORY_ANALYSIS
    "PhanUnanalyzable"
    "PhanUnanalyzableInheritance"
    "PhanInvalidConstantFQSEN"
    "PhanReservedConstantName"

    ;; Issue::CATEGORY_VARIABLE
    "PhanVariableUseClause"

    ;; Issue::CATEGORY_STATIC
    "PhanStaticCallToNonStatic"
    "PhanStaticPropIsStaticType"
    "PhanAbstractStaticMethodCall"
    "PhanAbstractStaticMethodCallInStatic"
    "PhanAbstractStaticMethodCallInTrait"

    ;; Issue::CATEGORY_CONTEXT
    "PhanContextNotObject"
    "PhanContextNotObjectInCallable"
    "PhanContextNotObjectUsingSelf"
    "PhanSuspiciousMagicConstant"

    ;; Issue::CATEGORY_DEPRECATED
    "PhanDeprecatedClass"
    "PhanDeprecatedInterface"
    "PhanDeprecatedTrait"
    "PhanDeprecatedFunction"
    "PhanDeprecatedFunctionInternal"
    "PhanDeprecatedProperty"
    "PhanDeprecatedClassConstant"
    "PhanDeprecatedCaseInsensitiveDefine"

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
    "PhanParamTooFewInPHPDoc"
    "PhanParamTooMany"
    "PhanParamTooManyUnpack"
    "PhanParamTooManyInternal"
    "PhanParamTooManyUnpackInternal"
    "PhanParamTooManyCallable"
    "PhanParamTypeMismatch"
    "PhanParamSignatureMismatch"
    "PhanParamSignatureMismatchInternal"
    "PhanParamRedefined"
    "PhanParamMustBeUserDefinedClassname"

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
    "PhanParamNameIndicatingUnused"
    "PhanParamNameIndicatingUnusedInClosure"

    ;; Issue::CATEGORY_NOOP
    "PhanNoopArray"
    "PhanNoopClosure"
    "PhanNoopConstant"
    "PhanNoopProperty"
    "PhanNoopArrayAccess"
    "PhanNoopVariable"
    "PhanNoopUnaryOperator"
    "PhanNoopBinaryOperator"
    "PhanNoopStringLiteral"
    "PhanNoopEncapsulatedStringLiteral"
    "PhanNoopNumericLiteral"
    "PhanNoopEmpty"
    "PhanNoopIsset"
    "PhanNoopCast"
    "PhanNoopTernary"
    "PhanNoopNew"
    "PhanNoopNewNoSideEffects"
    "PhanNoopSwitchCases"
    "PhanNoopMatchArms"
    "PhanNoopMatchExpression"
    "PhanNoopRepeatedSilenceOperator"
    "PhanUnreachableCatch"
    "PhanUnreferencedClass"
    "PhanUnreferencedFunction"
    "PhanUnreferencedPublicMethod"
    "PhanUnreferencedProtectedMethod"
    "PhanUnreferencedPrivateMethod"
    "PhanUnreferencedPublicProperty"
    "PhanUnreferencedProtectedProperty"
    "PhanUnreferencedPrivateProperty"
    "PhanUnreferencedPHPDocProperty"
    "PhanReadOnlyPublicProperty"
    "PhanReadOnlyProtectedProperty"
    "PhanReadOnlyPrivateProperty"
    "PhanReadOnlyPHPDocProperty"
    "PhanWriteOnlyPublicProperty"
    "PhanWriteOnlyProtectedProperty"
    "PhanWriteOnlyPrivateProperty"
    "PhanWriteOnlyPHPDocProperty"
    "PhanUnreferencedConstant"
    "PhanUnreferencedPublicClassConstant"
    "PhanUnreferencedProtectedClassConstant"
    "PhanUnreferencedPrivateClassConstant"
    "PhanUnreferencedClosure"
    "PhanUnreferencedUseNormal"
    "PhanUnreferencedUseFunction"
    "PhanUnreferencedUseConstant"
    "PhanDuplicateUseNormal"
    "PhanDuplicateUseFunction"
    "PhanDuplicateUseConstant"
    "PhanUseNormalNoEffect"
    "PhanUseNormalNamespacedNoEffect"
    "PhanUseFunctionNoEffect"
    "PhanUseConstantNoEffect"
    "PhanEmptyPublicMethod"
    "PhanEmptyProtectedMethod"
    "PhanEmptyPrivateMethod"
    "PhanEmptyFunction"
    "PhanEmptyClosure"

    "PhanUnusedVariable"
    "PhanUnusedPublicMethodParameter"
    "PhanUnusedPublicFinalMethodParameter"
    "PhanUnusedPublicNoOverrideMethodParameter"
    "PhanUnusedProtectedMethodParameter"
    "PhanUnusedProtectedFinalMethodParameter"
    "PhanUnusedProtectedNoOverrideMethodParameter"
    "PhanUnusedPrivateMethodParameter"
    "PhanUnusedPrivateFinalMethodParameter"
    "PhanUnusedClosureUseVariable"
    "PhanShadowedVariableInArrowFunc"
    "PhanUnusedClosureParameter"
    "PhanUnusedGlobalFunctionParameter"
    "PhanUnusedVariableValueOfForeachWithKey"
    "PhanEmptyForeach"
    "PhanEmptyForeachBody"
    "PhanSideEffectFreeForeachBody"
    "PhanSideEffectFreeForBody"
    "PhanSideEffectFreeWhileBody"
    "PhanSideEffectFreeDoWhileBody"
    "PhanEmptyYieldFrom"
    "PhanUselessBinaryAddRight"
    "PhanSuspiciousBinaryAddLists"
    "PhanUnusedVariableCaughtException"
    "PhanUnusedGotoLabel"
    "PhanUnusedVariableReference"
    "PhanUnusedVariableStatic"
    "PhanUnusedVariableGlobal"
    "PhanUnusedReturnBranchWithoutSideEffects"
    "PhanRedundantArrayValuesCall"
    "PhanVariableDefinitionCouldBeConstant"
    "PhanVariableDefinitionCouldBeConstantEmptyArray"
    "PhanVariableDefinitionCouldBeConstantString"
    "PhanVariableDefinitionCouldBeConstantFloat"
    "PhanVariableDefinitionCouldBeConstantInt"
    "PhanVariableDefinitionCouldBeConstantTrue"
    "PhanVariableDefinitionCouldBeConstantFalse"
    "PhanVariableDefinitionCouldBeConstantNull"
    "PhanProvidingUnusedParameter"
    "PhanProvidingUnusedParameterOfClosure"

    ;; Issue::CATEGORY_REDEFINE
    "PhanRedefineClass"
    "PhanRedefineClassAlias"
    "PhanRedefineClassInternal"
    "PhanRedefineFunction"
    "PhanRedefineFunctionInternal"
    "PhanRedefineClassConstant"
    "PhanRedefineProperty"
    "PhanIncompatibleCompositionProp"
    "PhanIncompatibleCompositionMethod"
    "PhanRedefinedUsedTrait"
    "PhanRedefinedInheritedInterface"
    "PhanRedefinedExtendedClass"
    "PhanRedefinedClassReference"

    ;; Issue::CATEGORY_ACCESS
    "PhanAccessPropertyPrivate"
    "PhanAccessPropertyProtected"

    "PhanAccessReadOnlyProperty"
    "PhanAccessWriteOnlyProperty"
    "PhanAccessReadOnlyMagicProperty"
    "PhanAccessWriteOnlyMagicProperty"

    "PhanAccessMethodPrivate"
    "PhanAccessMethodPrivateWithCallMagicMethod"
    "PhanAccessMethodProtected"
    "PhanAccessMethodProtectedWithCallMagicMethod"
    "PhanAccessSignatureMismatch"
    "PhanAccessSignatureMismatchInternal"
    "PhanConstructAccessSignatureMismatch"
    "PhanPropertyAccessSignatureMismatch"
    "PhanPropertyAccessSignatureMismatchInternal"
    "PhanConstantAccessSignatureMismatch"
    "PhanConstantAccessSignatureMismatchInternal"
    "PhanAccessStaticToNonStatic"
    "PhanAccessNonStaticToStatic"
    "PhanAccessStaticToNonStaticProperty"
    "PhanAccessNonStaticToStaticProperty"
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
    "PhanAccessOverridesFinalMethodInTrait"
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
    "PhanCompatibleObjectTypePHP71"
    "PhanCompatibleMixedType"
    "PhanCompatibleUseVoidPHP70"
    "PhanCompatibleUseIterablePHP71"
    "PhanCompatibleUseObjectPHP71"
    "PhanCompatibleUseMixed"
    "PhanCompatibleMultiExceptionCatchPHP70"
    "PhanCompatibleNonCapturingCatch"
    "PhanCompatibleNegativeStringOffset"
    "PhanCompatibleAutoload"
    "PhanCompatibleUnsetCast"
    "PhanCompatibleSyntaxNotice"
    "PhanCompatibleDimAlternativeSyntax"
    "PhanCompatibleImplodeOrder"
    "PhanCompatibleUnparenthesizedTernary"
    "PhanCompatibleTypedProperty"
    "PhanCompatibleDefaultEqualsNull"
    "PhanCompatiblePHP8PHP4Constructor"
    "PhanCompatibleScalarTypePHP56"
    "PhanCompatibleAnyReturnTypePHP56"
    "PhanCompatibleUnionType"
    "PhanCompatibleStaticType"
    "PhanCompatibleThrowExpression"

    ;; Issue::CATEGORY_GENERIC
    "PhanTemplateTypeConstant"
    "PhanTemplateTypeStaticMethod"
    "PhanTemplateTypeStaticProperty"
    "PhanGenericGlobalVariable"
    "PhanGenericConstructorTypes"
    "PhanTemplateTypeNotUsedInFunctionReturn"
    "PhanTemplateTypeNotDeclaredInFunctionParams"

    ;; Issue::CATEGORY_COMMENT
    "PhanDebugAnnotation"
    "PhanInvalidCommentForDeclarationType"
    "PhanMisspelledAnnotation"
    "PhanUnextractableAnnotation"
    "PhanUnextractableAnnotationPart"
    "PhanUnextractableAnnotationSuffix"
    "PhanUnextractableAnnotationElementName"
    "PhanCommentParamWithoutRealParam"
    "PhanCommentParamAssertionWithoutRealParam"
    "PhanCommentParamOnEmptyParamList"
    "PhanCommentOverrideOnNonOverrideMethod"
    "PhanCommentOverrideOnNonOverrideConstant"
    "PhanCommentParamOutOfOrder"
    "PhanThrowTypeAbsent"
    "PhanThrowTypeAbsentForCall"
    "PhanThrowTypeMismatch"
    "PhanThrowTypeMismatchForCall"
    "PhanThrowStatementInToString"
    "PhanThrowCommentInToString"
    "PhanCommentAmbiguousClosure"
    "PhanCommentDuplicateParam"
    "PhanCommentDuplicateMagicMethod"
    "PhanCommentDuplicateMagicProperty"
    "PhanCommentObjectInClassConstantType"

    ;;; Plugins

    ;; UnreachableCodePlugin.php
    "PhanPluginUnreachableCode"

    ;; StrictComparisonPlugin
    "PhanPluginComparisonNotStrictInCall"
    "PhanPluginComparisonObjectEqualityNotStrict"
    "PhanPluginComparisonObjectOrdering"

    ;; AlwaysReturnPlugin.php
    "PhanPluginAlwaysReturnFunction"
    "PhanPluginAlwaysReturnMethod"

    ;; PregRegexCheckerPlugin.php
    "PhanPluginInvalidPregRegex"
    "PhanPluginInvalidPregRegexReplacement"

    ;; LoopVariableReusePlugin.php
    "PhanPluginLoopVariableReuse"

    ;; DuplicateArrayKeyPlugin.php
    "PhanPluginDuplicateArrayKey"
    "PhanPluginDuplicateArrayKeyExpression"
    "PhanPluginDuplicateSwitchCase"
    "PhanPluginDuplicateSwitchCaseLooseEquality"
    "PhanPluginMixedKeyNoKey"

    ;; NotFullyQualifiedUsagePlugin.php
    "PhanPluginNotFullyQualifiedFunctionCall"
    "PhanPluginNotFullyQualifiedGlobalConstant"
    "PhanPluginNotFullyQualifiedOptimizableFunctionCall"

    ;; PHPDocToRealTypesPlugin.php
    "PhanPluginCanUseNullableParamType"
    "PhanPluginCanUseNullableReturnType"
    "PhanPluginCanUsePHP71Void"
    "PhanPluginCanUseParamType"
    "PhanPluginCanUseReturnType"

    ;; NoAssertPlugin.php
    "PhanPluginNoAssert"

    ;; InlineHTMLPlugin.php
    "PhanPluginInlineHTML"
    "PhanPluginInlineHTMLLeading"
    "PhanPluginInlineHTMLTrailing"

    ;; UnknownElementTypePlugin.php
    "PhanPluginUnknownArrayClosureParamType"
    "PhanPluginUnknownArrayClosureReturnType"
    "PhanPluginUnknownArrayFunctionParamType"
    "PhanPluginUnknownArrayFunctionReturnType"
    "PhanPluginUnknownArrayMethodParamType"
    "PhanPluginUnknownArrayMethodReturnType"
    "PhanPluginUnknownArrayPropertyType"
    "PhanPluginUnknownClosureParamType"
    "PhanPluginUnknownClosureReturnType"
    "PhanPluginUnknownFunctionParamType"
    "PhanPluginUnknownFunctionReturnType"
    "PhanPluginUnknownMethodParamType"
    "PhanPluginUnknownMethodReturnType"
    "PhanPluginUnknownPropertyType"

    ;; NumericalComparisonPlugin.php
    "PhanPluginNumericalComparison"

    ;; EmptyStatementListPlugin.php
    "PhanPluginEmptyStatementDoWhileLoop"
    "PhanPluginEmptyStatementForLoop"
    "PhanPluginEmptyStatementForeachLoop"
    "PhanPluginEmptyStatementIf"
    "PhanPluginEmptyStatementSwitch"
    "PhanPluginEmptyStatementTryBody"
    "PhanPluginEmptyStatementTryFinally"
    "PhanPluginEmptyStatementWhileLoop"

    ;; DemoPlugin.php
    "PhanPluginInstanceOfObject"

    ;; AvoidableGetterPlugin.php
    "PhanPluginAvoidableGetter"
    "PhanPluginAvoidableGetterInTrait"

    ;; NonBoolBranchPlugin.php
    "PhanPluginNonBoolBranch"

    ;; PHPDocRedundantPlugin.php
    "PhanPluginRedundantClosureComment"
    "PhanPluginRedundantFunctionComment"
    "PhanPluginRedundantMethodComment"
    "PhanPluginRedundantReturnComment"

    ;; PhanSelfCheckPlugin.php
    "PhanPluginTooFewArgumentsForIssue"
    "PhanPluginTooManyArgumentsForIssue"
    "PhanPluginUnknownIssueType"

    ;; RedundantAssignmentPlugin.php
    "PhanPluginRedundantAssignment"
    "PhanPluginRedundantAssignmentInGlobalScope"
    "PhanPluginRedundantAssignmentInLoop"

    ;; DollarDollarPlugin.php
    "PhanPluginDollarDollar"

    ;; InvalidVariableIssetPlugin.php
    "PhanPluginComplexVariableInIsset"
    "PhanPluginInvalidVariableIsset"
    "PhanPluginInvalidVariableIsset"
    "PhanPluginUndeclaredVariableIsset"
    "PhanPluginUnexpectedExpressionIsset"

    ;; WhitespacePlugin.php
    "PhanPluginWhitespaceCarriageReturn"
    "PhanPluginWhitespaceTab"
    "PhanPluginWhitespaceTrailing"

    ;; HasPHPDocPlugin.php
    "PhanPluginDescriptionlessCommentOnClass"
    "PhanPluginDescriptionlessCommentOnFunction"
    "PhanPluginDescriptionlessCommentOnPrivateMethod"
    "PhanPluginDescriptionlessCommentOnPrivateProperty"
    "PhanPluginDescriptionlessCommentOnProtectedMethod"
    "PhanPluginDescriptionlessCommentOnProtectedProperty"
    "PhanPluginDescriptionlessCommentOnPublicMethod"
    "PhanPluginDescriptionlessCommentOnPublicProperty"
    "PhanPluginDuplicateMethodDescription"
    "PhanPluginDuplicatePropertyDescription"
    "PhanPluginNoCommentOnClass"
    "PhanPluginNoCommentOnFunction"
    "PhanPluginNoCommentOnPrivateMethod"
    "PhanPluginNoCommentOnPrivateProperty"
    "PhanPluginNoCommentOnProtectedMethod"
    "PhanPluginNoCommentOnProtectedProperty"
    "PhanPluginNoCommentOnPublicMethod"
    "PhanPluginNoCommentOnPublicProperty"

    ;; PrintfCheckerPlugin.php
    "PhanPluginMyIssue"
    "PhanPluginPrintfIncompatibleArgumentType"
    "PhanPluginPrintfIncompatibleArgumentTypeWeak"
    "PhanPluginPrintfIncompatibleSpecifier"
    "PhanPluginPrintfNoArguments"
    "PhanPluginPrintfNoArguments"
    "PhanPluginPrintfNoSpecifiers"
    "PhanPluginPrintfNonexistentArgument"
    "PhanPluginPrintfNonexistentArgument"
    "PhanPluginPrintfNotPercent"
    "PhanPluginPrintfTranslatedHasMoreArgs"
    "PhanPluginPrintfTranslatedIncompatible"
    "PhanPluginPrintfUnusedArgument"
    "PhanPluginPrintfVariableFormatString"
    "PhanPluginPrintfWidthNotPosition"

    ;; PreferNamespaceUsePlugin.php
    "PhanPluginPreferNamespaceUseParamType"
    "PhanPluginPreferNamespaceUseReturnType"

    ;; SuspiciousParamOrderPlugin.php
    "PhanPluginSuspiciousParamOrder"
    "PhanPluginSuspiciousParamOrderInternal"

    ;; DuplicateExpressionPlugin.php
    "PhanPluginBothLiteralsBinaryOp"
    "PhanPluginDuplicateConditionalNullCoalescing"
    "PhanPluginDuplicateConditionalTernaryDuplication"
    "PhanPluginDuplicateConditionalUnnecessary"
    "PhanPluginDuplicateExpressionAssignment"
    "PhanPluginDuplicateExpressionBinaryOp"
    "PhanPluginDuplicateIfCondition"
    "PhanPluginDuplicateIfStatements"

    ;; NonBoolInLogicalArithPlugin.php
    "PhanPluginNonBoolInLogicalArith"

    ;; PossiblyStaticMethodPlugin.php
    "PhanPluginPossiblyStaticClosure"
    "PhanPluginPossiblyStaticPrivateMethod"
    "PhanPluginPossiblyStaticProtectedMethod"
    "PhanPluginPossiblyStaticPublicMethod"

    ;; UseReturnValuePlugin.php
    "PhanPluginUseReturnValue"
    "PhanPluginUseReturnValueKnown"
    "PhanPluginUseReturnValueInternal"
    "PhanPluginUseReturnValueInternalKnown"
    "PhanPluginUseReturnValueNoopVoid"

    ;; InvokePHPNativeSyntaxCheckPlugin.php

    ;; PHPUnitAssertionPlugin.php
    "PhanPluginPHPUnitAssertionInvalidInternalType")
  "Issue names of Phan.

https://github.com/phan/phan/blob/master/src/Phan/Issue.php
https://github.com/phan/phan/wiki/Issue-Types-Caught-by-Phan")

(defconst phan-log-warning-keywords
  '("can't be"
    "Invalid operator"
    "Suspicious"
    "deprecated"
    "has no return value"
    "not found"
    "only takes"
    "requires"
    "should be compatible"
    "undeclared"
    "unextractable annotation"))

(defconst phan-log-class-prefix-keywords
  '(":" "but" "class" "for" "function" "is" "method" "property" "return" "takes" "to" "type"
    "classlike/namespace" "Class" "Property"))

(defconst phan-log-function-prefix-keywords
  '("function" "Function" "Method"))

(defconst phan-log-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?$  "_" table)
    (modify-syntax-entry ?,  "." table)
    (modify-syntax-entry ?-  "." table)
    (modify-syntax-entry ?.  "." table)
    (modify-syntax-entry ?/  "." table)
    (modify-syntax-entry ?:  "." table)
    (modify-syntax-entry ?<  "(" table)
    (modify-syntax-entry ?>  ")" table)
    (modify-syntax-entry ??  "." table)
    (modify-syntax-entry ?\' "." table)
    (modify-syntax-entry ?\( "(" table)
    (modify-syntax-entry ?\) ")" table)
    (modify-syntax-entry ?\\ "_" table)
    (modify-syntax-entry ?_  "_" table)
    (modify-syntax-entry ?|  "." table)
    table))

(defconst phan-log-font-lock-keywords
  (list
   (list "^\\([^:]+\\):\\([0-9]+\\)"
         '(1 font-lock-doc-face)
         '(2 font-lock-builtin-face))
   (cons (concat "\\??" (regexp-opt phan-php-types 'symbols) "\\(\\[]\\)?")
         '(0 font-lock-type-face))
   (cons (concat " " (regexp-opt phan-issues) " ")
         '(0 font-lock-keyword-face))
   (cons (concat "\\(?:|\\|, \\| " (regexp-opt phan-log-class-prefix-keywords) " \\)"
                 (rx (group (? "\\") (+ (or "|" (syntax word) (syntax symbol))) "()")))
         '(1 font-lock-function-name-face))
   (cons (concat "\\(?:|\\|, \\| " (regexp-opt phan-log-class-prefix-keywords) " \\)"
                 (rx (group "\\" (+ (or "?" "[]" (syntax word) (syntax symbol))))))
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
         '(0 font-lock-variable-name-face))
   (cons (regexp-opt phan-log-warning-keywords 'words)
         '(0 font-lock-warning-face))))

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
