;;; ormolu.el --- Format Haskell source code using the "ormolu" program -*- lexical-binding: t -*-

;; Author: Vasiliy Yorkin <vasiliy.yorkin@gmail.com>
;; Maintainer: Vasiliy Yorkin
;; Version: 0.2.0-snapshot
;; Package-Version: 20211020.2229
;; Package-Commit: 1941a8ce48027b5670d226bacc2fa10b00774b3a
;; URL: https://github.com/vyorkin/ormolu.el
;; Keywords: files, tools
;; Package-Requires: ((emacs "24") (reformatter "0.4"))

;; This file is NOT part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides a minor mode and commands for easily using the "ormolu"
;; program to reformat Haskell code.

;;; Code:

(require 'reformatter)

(defgroup ormolu nil
  "Integration with the \"ormolu\" formatting program."
  :prefix "ormolu-"
  :group 'haskell)

(defcustom ormolu-process-path "ormolu"
  "Location where the ormolu executable is located."
  :group 'ormolu
  :type 'string
  :safe #'stringp)

(defcustom ormolu-extra-args '()
  "Extra arguments to give to ormolu."
  :group 'ormolu
  :type 'sexp
  :safe #'listp)

(defcustom ormolu-cabal-default-extensions nil
  "Whether to use the --cabal-default-extensions flag."
  :group 'ormolu
  :type 'boolean
  :safe #'booleanp)

(defvar ormolu-mode-map (make-sparse-keymap)
  "Local keymap used for `ormolu-format-on-save-mode`.")

;;;###autoload (autoload 'ormolu-format-buffer "ormolu" nil t)
;;;###autoload (autoload 'ormolu-format-region "ormolu" nil t)
;;;###autoload (autoload 'ormolu-format-on-save-mode "ormolu" nil t)
(reformatter-define ormolu-format
  :program ormolu-process-path
  :args (append (if (and ormolu-cabal-default-extensions buffer-file-name)
                    `("--cabal-default-extensions" "--stdin-input-file" ,buffer-file-name)
                  '()) ormolu-extra-args)
  :group 'ormolu
  :lighter " Or"
  :keymap ormolu-mode-map)

(defalias 'ormolu 'ormolu-format-buffer)

(provide 'ormolu)

;;; ormolu.el ends here
