;;; rib-mode.el --- RenderMan® Interface Bytestream (RIB) Major Mode

;; Description: RenderMan® Interface Bytestream (RIB) Emacs Major Mode
;; Author: Remik Ziemlinski and Daniel Blezek <daniel.blezek@gmail.com>
;; URL: https://github.com/blezek/rib-mode
;; Package-Version: 20170726.1448
;; Package-Commit: 97470158784c3c212e22e2c20b8471ee65ba59af
;; Version: 1.0
;; Copyright © 2006 Remik Ziemlinski
;; Package-Requires: ((emacs "24"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

;; RenderMan® is a registered trademark of Pixar.
;; VERSION = $Id: rib-mode.el,v 1.1.1.1 2006/05/26 16:02:21 rsz Exp $

;; Changelog:
;; 20060524 rsz Created with basic highlighting and indentation support.
;; 20170718 djb Published in MELPA.

;;; Commentary:

;; rib-mode is intended to be an (X)Emacs plugin in order to add
;; syntax highlighting and indentation automatically to the text
;; editing of RenderMan® Interface Bytestream (RIB) files that are in
;; ASCII.  The plugin code is in Lisp which is interpreted by the
;; Emacs environment upon application startup.
;;
;; I was unable to find such a plugin on the web, yet I do know that
;; those using RenderMan tools also use Emacs editors.  For example,
;; there is a plugin for the RenderMan Shading Language (very similar
;; to the C language), but none for the scene description interface
;; known as RIB (a pascal-like language).  RIB is intended to be human
;; readable and editable to allow for the highest level of control of
;; your scenes without resorting to C programming.
;;
;; References:
;; [1] Pixar, RenderMan Interface Specification 3.2.1
;; [2] Borton, S.A., "An Emacs language mode creation tutorial"

;;; Code:

;; Put buffer in this mode for files with this extension.
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.rib\\'" . rib-mode))

;; Syntax highlighting.
;; level 1
(defconst rib-font-lock-keywords-1
  (list
   '("\\(#.*$\\)" . font-lock-comment-face)
   '("\\<\\(Attribute\\(?:Begin\\|End\\)\\|Begin\\|End\\|Frame\\(?:Begin\\|End\\)\\|Motion\\(?:Begin\\|End\\)\\|Object\\(?:Begin\\|End\\)\\|Solid\\(?:Begin\\|End\\)\\|Transform\\(?:Begin\\|End\\)\\|World\\(?:Begin\\|End\\)\\)\\>" . font-lock-builtin-face)
   '("\\<\\(ErrorHandler\\)\\>" . font-lock-warning-face)
   )
  "Minimal highlighting expressions for RIB mode.")

;; level 2
(defconst rib-font-lock-keywords-2
  (append rib-font-lock-keywords-1
          (list
           '("\\<\\(Make\\(?:CubeFaceEnvironment\\|LatLongEnvironment\\|Shadow\\|Texture\\)\\)\\>" . font-lock-variable-name-face)
           '("\\<\\(B\\(?:asis\\|lobby\\)\\|C\\(?:one\\|urves\\|ylinder\\)\\|Disk\\|Ge\\(?:neralPolygon\\|ometry\\)\\|Hyperboloid\\|NuPatch\\|ObjectInstance\\|P\\(?:a\\(?:raboloid\\|tch\\(?:Mesh\\)?\\)\\|o\\(?:ints\\(?:GeneralPolygons\\|Polygons\\)?\\|lygon\\)\\|rocedural\\)\\|S\\(?:phere\\|ubdivisionMesh\\)\\|T\\(?:orus\\|rimCurve\\)\\)\\>" . font-lock-keyword-face)))
  "Additional keywords to highlight in RIB mode.")

;; level 3
(defconst rib-font-lock-keywords-3
  (append rib-font-lock-keywords-2
          (list
           '("\\<\\(A\\(?:r\\(?:chiveRecord\\|eaLightSource\\)\\|t\\(?:mosphere\\|tribute\\)\\)\\|Bound\\|Bxdf\\|C\\(?:lipping\\(?:Plane\\)?\\|o\\(?:lor\\(?:Samples\\)?\\|ncatTransform\\|ord\\|amera\\(?:SysTransform\\|inateSystem\\)\\)\\|ropWindow\\)\\|D\\(?:e\\(?:clare\\|pthOfField\\|tail\\(?:Range\\)?\\)\\|ispla\\(?:cement\\|y\\)\\)\\|Ex\\(?:posure\\|terior\\)\\|F\\(?:ormat\\|rameAspectRatio\\)\\|GeometricApproximation\\|Hider\\|I\\(?:dentity\\|lluminate\\|mager\\|nterior\\|ntegrator\\)\\|LightSource\\|Matte\\|O\\(?:p\\(?:acity\\|tion\\)\\|rientation\\)\\|P\\(?:erspective\\|ixel\\(?:Filter\\|Samples\\|Variance\\)\\|rojection\\)\\|Quantize\\|R\\(?:e\\(?:adArchive\\|lativeDetail\\|verseOrientation\\)\\|otate\\)\\|S\\(?:c\\(?:ale\\|reenWindow\\)\\|h\\(?:ading\\(?:Interpolation\\|Rate\\)\\|utter\\)\\|ides\\|kew\\|urface\\|copetdCoordinateSystem\\)\\|T\\(?:extureCoordinates\\|rans\\(?:form\\(?:Points\\)?\\|late\\)\\)\\)\\>" . font-lock-function-name-face)
           '("\".*\"" . font-lock-string-face)))
  "Highlight it all for RIB mode.")

(defvar rib-font-lock-keywords rib-font-lock-keywords-3
  "Default highlighting expressions for RIB mode.")

;; Indentation rules.
;; 1. If at beginning of buffer, indent to column 0.
;; 2. If at an End line, de-indent relative to prev line.
;; 3. If there is an End line before the current line, indent the same as the End line.
;; 4. If we see a Begin line before the current line, then increase indent relative to the Begin line.
;; 5. If none of the above apply, don't indent.

(defun rib-indent-line()
  "Indent current line as RIB code"
  (interactive)
  (beginning-of-line)
  (if (bobp) ; rule 1.
      (indent-line-to 0)
    (let  ((not-indented t) cur-indent)
      (if (looking-at "^[ \t]*[a-zA-Z]*End") ; rule 2.
          (progn
            (save-excursion
              (forward-line -1)
              (setq cur-indent (- (current-indentation) tab-width)))
            (if (< cur-indent 0)
                (setq cur-indent 0)))
        ;; else
        (save-excursion
          (while not-indented
            (forward-line -1)
            (if (looking-at "^[ \t]*[a-zA-Z]*End") ; rule 3.
                (progn
                  (setq cur-indent (current-indentation))
                  (setq not-indented nil)) ; return.
                                        ; else
              (if (looking-at "^[ \t]*[a-zA-Z]*Begin") ; rule 4.
                  (progn
                    (setq cur-indent (+ (current-indentation) tab-width))
                    (setq not-indented nil)) ; return.
                (if (bobp) ; rule 5.
                    (setq not-indented nil))))))
        )
      ;; Indent if cur-indent is defined from above.
      (if cur-indent
          (indent-line-to cur-indent)
        (indent-line-to 0)))))

(defvar rib-mode-syntax-table
  (let ((rib-mode-syntax-table (make-syntax-table)))
    ;; Make comment symbol apply until end of line.
    (modify-syntax-entry ?# "<" rib-mode-syntax-table)
    (modify-syntax-entry ?\n ">" rib-mode-syntax-table)
    rib-mode-syntax-table)
  "Syntax table for ‘rib-mode’.")

;;;###autoload
(define-derived-mode rib-mode prog-mode "RIB"
  "Major mode for editing RenderMan(R) Interface Bytestream ASCII files"
  (set (make-local-variable 'font-lock-defaults) '(rib-font-lock-keywords))
  (set (make-local-variable 'indent-line-function) 'rib-indent-line))

(provide 'rib-mode)
;;; rib-mode.el ends here

