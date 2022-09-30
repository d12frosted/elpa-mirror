;;; shader-mode.el --- Major mode for shader

;; Author: midnightSuyama <midnightSuyama@gmail.com>
;; URL: https://github.com/midnightSuyama/shader-mode
;; Package-Version: 20220930.1052
;; Package-Commit: fe5a1982ba69e4a98b834141a46a1908f132df15
;; Package-Requires: ((emacs "24"))
;; Version: 0.2.4

;; Copyright (C) 2015 midnightSuyama

;; This program is free software: you can redistribute it and/or modify
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

;; Reference
;; <http://docs.unity3d.com/Manual/>
;; <https://developer.nvidia.com/cg-toolkit>

;;; Code:

(defconst shader-font-lock-keyword-face
  `(,(concat "\\<"
             (regexp-opt '(
                           ;; ShaderLab
                           "Shader" "Properties" "SubShader" "Pass" "UsePass" "GrabPass" "Tags"
                           "Range" "Float" "Int" "Color" "Vector" "2D" "Cube" "3D"
                           "Cull" "ZTest" "ZWrite" "Offset" "Blend" "BlendOp" "AlphaToMask" "ColorMask"
                           "Stencil" "Ref" "ReadMask" "WriteMask" "Comp" "CompFront" "CompBack" "PassFront" "PassBack" "Fail" "FailFront" "FailBack" "ZFail" "ZFailFront" "ZFailBack"
                           "Name"
                           "Material" "Lighting" "SeparateSpecular" "ColorMaterial" "Diffuse" "Ambient" "Specular" "Shininess" "Emission"
                           "SetTexture" "combine" "constantColor"
                           "AlphaTest"
                           "Fog" "Mode" "Density" "Range"
                           "BindChannels" "Bind"
                           "LOD"
                           "Fallback" "CustomEditor" "Category"
                           "CGPROGRAM" "CGINCLUDE" "ENDCG"
                           
                           ;; Cg
                           "asm" "asm_fragment" "auto"
                           "break"
                           "case" "catch" "class" "column_major" "compile" "const" "const_cast" "continue"
                           "decl" "default" "delete" "discard" "do" "dword" "dynamic_cast"
                           "else" "emit" "enum" "explicit" "extern"
                           "for" "friend"
                           "get" "goto"
                           "if" "in" "inline" "inout" "interface"
                           "matrix" "mutable"
                           "namespace" "new"
                           "operator" "out"
                           "packed" "pass" "pixelfragment" "pixelshader" "private" "protected" "public"
                           "register" "reinterpret_cast" "return" "row_major"
                           "sampler_state" "shared" "sizeof" "static" "static_cast" "string" "struct" "switch"
                           "technique" "template" "texture" "texture1D" "texture2D" "texture3D" "textureCUBE" "textureRECT" "this" "throw" "try" "typedef" "typeid" "typename"
                           "uniform" "union" "using"
                           "vector" "vertexfragment" "vertexshader" "virtual" "volatile"
                           "while"))
             "\\>") . font-lock-keyword-face))

(defconst shader-font-lock-constant-face
  `(,(concat "\\<\\("
             (regexp-opt '("TRUE" "true" "FALSE" "false" "NULL"
                           
                           ;; Semantics
                           "BINORMAL" "BLENDINDICES" "BLENDWEIGHT"
                           "CENTROID" "CLPV" "CONTROLPOINT_ID" "COL" "COLOR"
                           "DEPR" "DEPTH" "DIFFUSE"
                           "EDGETESS"
                           "FACE" "FLAT" "FOG" "FOGC" "FOGCOORD" "FOGP"
                           "HPOS"
                           "INNERTESS" "INSTANCEID"
                           "NOPERSPECTIVE" "NORMAL"
                           "PATCH" "POSITION" "PRIMITIVEID" "PSIZ" "PSIZE"
                           "SPECULAR" "SV_Depth" "SV_POSITION" "SV_Target" "SV_VertexID"
                           "TANGENT" "TESSCOORD" "TESSFACTOR"
                           "UV"
                           "VERTEXID" "VFACE" "VPOS"))
             "\\|\\(ATTR\\|BCOL\\|C\\|CLP\\|COL\\|COLOR\\|SV_Target\\|TEX\\|TEXCOORD\\|TEXUNIT\\)[0-9]+"
             "\\)\\>") . font-lock-constant-face))

(defconst shader-font-lock-builtin-face
  `(,(concat "\\<"
             (regexp-opt '(
                           ;; Mathematical
                           "abs" "acos" "all" "any" "asin" "atan" "atan2"
                           "ceil" "clamp" "clip" "cos" "cosh" "cross"
                           "degress" "determinant" "dot"
                           "exp" "exp2"
                           "floor" "fmod" "frac" "frexp" "fwidth"
                           "isfinite" "isinf" "isnan"
                           "ldexp" "lerp" "lit" "log" "log2" "log10"
                           "max" "min" "modf" "mul"
                           "noise"
                           "pow"
                           "radians" "round" "rsqrt"
                           "saturate" "sign" "sin" "sincos" "sinh" "smoothstep" "step" "sqrt"
                           "tan" "tanh" "transpose" "trunc"
                           
                           ;; Geometric
                           "distance" "faceforward" "length" "normalize" "reflect" "refract"
                           
                           ;; Texture Map
                           "tex1D" "tex1Dproj" "tex2D" "tex2Dproj" "tex3D" "tex3Dproj"
                           "texRECT" "texRECTproj" "texCUBE" "texCUBEproj"
                           
                           ;; Derivative
                           "ddx" "ddy"
                           
                           ;; Debugging
                           "debug"))
             "\\>") . font-lock-builtin-face))

(defconst shader-font-lock-type-face
  `(,(concat "\\<\\("
             (regexp-opt '("void" "signed" "unsigned" "cint" "cfloat" "char" "short" "long" "double"))
             "\\|\\(bool\\|fixed\\|float\\|half\\|int\\)\\(\\([1234]\\(x[1234]\\)?\\)?\\)?"
             "\\|sampler\\(\\(1D\\|2D\\)\\(ARRAY\\)?\\|3D\\|RECT\\|CUBE\\)?\\(_half\\|_float\\)?"
             "\\)\\>") . font-lock-type-face))

(defconst shader-font-lock-variable-name-face
  `("\\<_\\sw+\\>"
    . font-lock-variable-name-face))

(defconst shader-font-lock-function-name-face
  `("^[ \t]*\\sw+[ \t]+\\(\\sw+\\)[ \t]*("
    1 font-lock-function-name-face))

(defconst shader-font-lock-preprocessor-face
  `(,(concat "^[ \t]*#[ \t]*"
             (regexp-opt '("define" "elif" "else" "endif" "error" "if" "ifdef" "ifndef" "include" "pragma" "undef"))
             "\\>") . font-lock-preprocessor-face))

(defconst shader-font-lock-keywords
  (list
   shader-font-lock-preprocessor-face
   shader-font-lock-function-name-face
   shader-font-lock-variable-name-face
   shader-font-lock-type-face
   shader-font-lock-builtin-face
   shader-font-lock-constant-face
   shader-font-lock-keyword-face))

(defvar shader-indent-offset 4
  "Indentation offset for shader-mode.")

(defun shader-indent-line ()
  "Indent current line for shader-mode."
  (interactive)
  (let ((current-indent 0))
    (save-excursion
      (beginning-of-line)
      (ignore-errors
        (while t
            (backward-up-list 1)
            (when (looking-at "[{([]")
              (setq current-indent (+ current-indent shader-indent-offset))))))
    (save-excursion
      (back-to-indentation)
      (when (and (looking-at "[])}]") (>= current-indent shader-indent-offset))
        (setq current-indent (- current-indent shader-indent-offset))))
    (if (looking-at "^[ \t]*\n")
        (indent-line-to current-indent)
      (save-excursion (indent-line-to current-indent)))
    ))

;;;###autoload
(define-derived-mode shader-mode prog-mode
  "Shader"
  "Major mode for shader"
  (modify-syntax-entry ?_ "w")
  (modify-syntax-entry ?/ ". 124b")
  (modify-syntax-entry ?* ". 23")
  (modify-syntax-entry ?\n "> b")
  (setq font-lock-defaults '(shader-font-lock-keywords))
  (setq indent-line-function 'shader-indent-line)
  (setq comment-start "// ")
  (setq comment-end "")
  (set (make-local-variable 'electric-indent-chars)
       (append "{}()[]" electric-indent-chars)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.shader$" . shader-mode))

(provide 'shader-mode)

;;; shader-mode.el ends here
