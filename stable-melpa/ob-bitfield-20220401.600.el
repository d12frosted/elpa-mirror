;;; ob-bitfield.el --- Babel Functions for bitfield -*- lexical-binding: t; -*-

;; Author: Gulshan Singh
;; Version: 0.1
;; Package-Version: 20220401.600
;; Package-Commit: abe3d8fe49dc53c4663def689ceb5c0433638652
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/gsingh93/ob-bitfield

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-Babel support for bitfield: https://github.com/Arth-ur/bitfield

;;; Code:
(require 'ob)

;; Highlight bitfield source blocks using the `js' package
(add-to-list 'org-src-lang-modes '("bitfield" . js))

(defun ob-bitfield--get-arg (key argname params)
  "Return the bitfield command line flag for the given KEY.
If KEY is in PARAMS, get the argument value for that key from
PARAMS and combine it with ARGNAME to construct the command line
flag passed to the bitfield command line program.  If KEY is not
in PARAMS, return nil."
  (let* ((arg (cdr (assq key params)))
         (string-arg (if (numberp arg) (number-to-string arg) arg)))
    (when string-arg
      (format "--%s %s" argname (shell-quote-argument string-arg)))))

(defvar org-babel-default-header-args:bitfield
  '((:results . "file graphics") (:exports . "results"))
  "Default arguments to use when evaluating a bitfield source block.")

(defun org-babel-execute:bitfield (body params)
  "Execute bitfield with the JSON block as input using org-babel.
This function is called by `org-babel-execute-src-block' with
BODY set to the contents of the source block and PARAMS set to
the header args."
  (let* ((out-file
          (cdr (or (assq :file params)
                   (user-error "You need to specify a :file parameter"))))
         (file-ext (file-name-extension out-file))
         (lanes (ob-bitfield--get-arg :lanes "lanes" params))
         (vspace (ob-bitfield--get-arg :vspace "vspace" params))
         (hspace (ob-bitfield--get-arg :hspace "hspace" params))
         (bits (ob-bitfield--get-arg :bits "bits" params))
         (fontfamily (ob-bitfield--get-arg :fontfamily "fontfamily" params))
         (fontweight (ob-bitfield--get-arg :fontweight "fontweight" params))
         (fontsize (ob-bitfield--get-arg :fontsize "fontsize" params))
         (compact (when (assq :compact params) "--compact"))
         (in-file (org-babel-temp-file "bitfield-" ".json"))
         ;; We only need to create a temporary SVG file if the output file is
         ;; not an SVG
         (svg-file (if (or (null file-ext) (string-equal file-ext "svg"))
                       out-file
                     (org-babel-temp-file "bitfield-" ".svg")))
         ;; Any nil argument passed to `string-join' is converted to an empty
         ;; string
         (args (string-join (list "--input" in-file
                                  lanes vspace hspace bits
                                  fontfamily fontweight fontsize
                                  compact)
                            " ")))
    (with-temp-file in-file
      (insert body))
    (with-temp-file svg-file
      (insert (org-babel-eval (concat "python3 -m bit_field " args) "")))
    ;; If our output format is not an SVG, we need to convert our SVG to the
    ;; correct format
    (unless (string-equal svg-file out-file)
      (with-temp-buffer
        (let ((exit-code (call-process "convert" nil t nil svg-file out-file)))
          (when (/= exit-code 0)
            (org-babel-eval-error-notify exit-code (buffer-string))))))))

(defun org-babel-prep-session:bitfield (_session _params)
  "Return an error because bitfield does not support sessions."
  (user-error "bitfield does not support sessions"))

(provide 'ob-bitfield)

;;; ob-bitfield.el ends here
