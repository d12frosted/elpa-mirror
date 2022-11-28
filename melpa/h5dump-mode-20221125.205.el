;;; h5dump-mode.el --- Major mode for navigating h5dump output -*- lexical-binding: t -*-

;; Copyright (C) 2022 Eric Berquist

;; Author: Eric Berquist
;; Version: 0.1.0
;; Package-Commit: 6b8309f41f94e9801729b189652a21d2f9f8e059
;; Package-Version: 20221125.205
;; Package-X-Original-Version: 0.1.0
;; Created: 2022-11-25
;; Package-Requires: ((emacs "25.1"))
;; Keywords: languages hdf5
;; URL: https://github.com/berquist/h5dump-mode

;; This file is not part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; h5dump (https://docs.hdfgroup.org/hdf5/develop/_view_tools_view.html) is a
;; tool for creating a textual representation of HDF5 files and appears
;; similar to JSON.  The mode currently enables `hs-minor-mode' for braced
;; blocks and basic font locking of non-data tokens.

;; h5dump output is not useful for data transfer but rather as a summary of
;; the group hierarchy within a given HDF5 file, along with a programming
;; language-independent way of inspecting the raw contents of datasets.  When
;; datasets get large, understanding the hierarchy while still viewing some
;; data can be difficult, so hideshow can be used to selectively hide groups
;; and datasets.

;; A future goal is to have tree-sitter integration
;; (https://github.com/berquist/tree-sitter-h5dump) for complete font locking.

;;; Code:

(require 'rx)

(defgroup h5dump nil
  "Major mode for navigating files with h5dump output."
  :group 'languages
  :prefix "h5dump-"
  :link '(url-link :tag "Site" "https://github.com/berquist/h5dump-mode")
  :link '(url-link :tag "Repository" "https://github.com/berquist/h5dump-mode"))

(defconst h5dump--hdf5-keywords
  '("ATTRIBUTE"
    "COMMENT"
    "DATA"
    "DATASET"
    "DATASPACE"
    "DATATYPE"
    "GROUP"
    "SOFTLINK"))

(defconst h5dump--hdf5-datatypes-integer
  '("H5T_STD_I8BE"
    "H5T_STD_I8LE"
    "H5T_STD_I16BE"
    "H5T_STD_I16LE"
    "H5T_STD_I32BE"
    "H5T_STD_I32LE"
    "H5T_STD_I64BE"
    "H5T_STD_I64LE"
    "H5T_STD_U8BE"
    "H5T_STD_U8LE"
    "H5T_STD_U16BE"
    "H5T_STD_U16LE"
    "H5T_STD_U32BE"
    "H5T_STD_U32LE"
    "H5T_STD_U64BE"
    "H5T_STD_U64LE"
    "H5T_NATIVE_CHAR"
    "H5T_NATIVE_UCHAR"
    "H5T_NATIVE_SHORT"
    "H5T_NATIVE_USHORT"
    "H5T_NATIVE_INT"
    "H5T_NATIVE_UINT"
    "H5T_NATIVE_LONG"
    "H5T_NATIVE_ULONG"
    "H5T_NATIVE_LLONG"
    "H5T_NATIVE_ULLONG"))

(defconst h5dump--hdf5-datatypes-float
  '("H5T_IEEE_F32BE"
    "H5T_IEEE_F32LE"
    "H5T_IEEE_F64BE"
    "H5T_IEEE_F64LE"
    "H5T_NATIVE_FLOAT"
    "H5T_NATIVE_DOUBLE"
    "H5T_NATIVE_LDOUBLE"))

(defconst h5dump--hdf5-datatypes-bitfield
  '("H5T_STD_B8BE"
    "H5T_STD_B8LE"
    "H5T_STD_B16BE"
    "H5T_STD_B16LE"
    "H5T_STD_B32BE"
    "H5T_STD_B32LE"
    "H5T_STD_B64BE"
    "H5T_STD_B64LE"))

(defconst h5dump--hdf5-datatypes
  (append
   h5dump--hdf5-datatypes-integer
   h5dump--hdf5-datatypes-float
   h5dump--hdf5-datatypes-bitfield
   '("H5T_ARRAY"
     "H5T_COMPOUND"
     "H5T_REFERENCE"
     "H5T_STRING"
     "H5T_VLEN")))

(defconst h5dump--hdf5-constants
  '("SCALAR"
    "SIMPLE"))

(defconst h5dump--hdf5-variables
  '("CSET"
    "CTYPE"
    "HARDLINK"
    "LINKTARGET"
    "STRPAD"
    "STRSIZE"))

(defvar h5dump--font-lock-definitions
  (append
   `((,(eval `(rx symbol-start "HDF5" symbol-end)) . font-lock-warning-face)
     (,(eval `(rx symbol-start (or ,@h5dump--hdf5-keywords) symbol-end)) . font-lock-keyword-face)
     (,(eval `(rx symbol-start (or ,@h5dump--hdf5-datatypes) symbol-end)) . font-lock-type-face)
     (,(eval `(rx symbol-start (or ,@h5dump--hdf5-constants) symbol-end)) . font-lock-constant-face)
     (,(eval `(rx symbol-start (or ,@h5dump--hdf5-variables) symbol-end)) . font-lock-variable-face))))

;;;###autoload
(define-derived-mode h5dump-mode prog-mode "h5dump"
  "Major mode for navigating files with h5dump output."
  :group 'h5dump
  ;; Since this isn't really code, more like semi-structured text, there are
  ;; no comments, just block delimiters.  We need these only in order to
  ;; satisfy `hs-grok-mode-type'.
  (setq-local comment-start ""
              comment-end "")
  (setq-local font-lock-defaults '(h5dump--font-lock-definitions))
  (add-to-list 'hs-special-modes-alist '(h5dump-mode "{" "}" nil nil)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.h5dump\\'" . h5dump-mode))

(provide 'h5dump-mode)

;; Local Variables:
;; coding: utf-8
;; End:

;;; h5dump-mode.el ends here
