;;; cwl-mode.el --- A major mode for editing CWL

;; Copyright (C) 2017 by Tomoya Tanjo

;; Version: 0.2.6
;; Package-Version: 20210510.1150
;; Package-Commit: 23a333119efaac78453cba95d316109805bd6aec
;; Author: Tomoya Tanjo <ttanjo@gmail.com>
;; URL: https://github.com/tom-tan/cwl-mode
;; Package-Requires: ((yaml-mode "0.0.13") (emacs "24.4"))
;; Keywords: languages, cwl, common workflow language

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

;; This library helps you to write Common Workflow Language in Emacs.
;;
;; Requirements:
;;   * Emacs 24.4 or later
;;   * yaml-mode.el
;;   * flycheck.el (optional)
;;
;; To use this package, add the following line to your .emacs file:
;;     (require 'cwl-mode)
;; cwl-mode highlights some keywords for usability.

;;; Code:

(require 'yaml-mode)
(require 'rx)

(defconst cwl-mode-keywords
  '("inputs" "outputs" "class" "steps" "id"
    "requirements" "hints" "label" "doc"
    "cwlVersion" "secondaryFiles" "streamable"
    "outputBinding" "format" "outputSource"
    "linkMerge" "type" "glob" "loadContents"
    "outputEval" "merge_nested" "merge_flattened"
    "location" "path" "basename" "dirname"
    "nameroot" "nameext" "checksum" "size" "format"
    "contents" "listing" "fields" "name" "symbols" "items"
    "in" "out" "run" "scatter" "scatterMethod"
    "source" "default" "valueFrom" "expressionLib"
    "types" "linkMerge" "inputBinding" "position"
    "prefix" "separate" "itemSeparator" "valueFrom"
    "shellQuote" "packages" "package" "version"
    "specs" "entry" "entryname" "writable"
    "baseCommand" "arguments" "stdin" "stderr"
    "stdout" "successCodes" "temporaryFailCodes"
    "permanentFailCodes" "dockerPull" "dockerLoad"
    "dockerFile" "dockerImport" "dockerImageId"
    "dockerOutputDirectory" "envDef" "envName"
    "envValue" "coresMin" "coresMax" "ramMin"
    "ramMax" "tmpdirMin" "tmpdirMax" "outdirMin"
    "outdirMax"))

(defvar cwl-mode-syntax-table
  (let ((table (copy-syntax-table yaml-mode-syntax-table)))
    (modify-syntax-entry ?_ "w" table)
    (modify-syntax-entry ?- "w" table)
    table))

;;;###autoload
(define-derived-mode cwl-mode
    yaml-mode "CWL"
    "Major mode for Common Workflow Language"
    :syntax-table cwl-mode-syntax-table
    :keymap cwl-mode-map
    (font-lock-add-keywords
     nil
     (list
      (cons
       (eval `(rx word-boundary
                  (group (regexp ,(regexp-opt cwl-mode-keywords)))
                  (zero-or-more blank) ":"))
       '(1 font-lock-keyword-face)))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.cwl\\'" . cwl-mode))

(defvar cwl-mode-map
  (let ((map (copy-keymap yaml-mode-map)))
    map))

(provide 'cwl-mode)
;;; cwl-mode.el ends here
