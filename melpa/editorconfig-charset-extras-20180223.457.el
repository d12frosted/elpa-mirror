;;; editorconfig-charset-extras.el --- Extra EditorConfig Charset Support

;; Author: 10sr <8.slashes@gmail.com>
;; URL: https://github.com/10sr/editorconfig-charset-extras-el
;; Package-Version: 20180223.457
;; Package-Commit: ddf60923c6f4841cb593b2ea04c9c710a01d262f
;; Version: 0.1
;; Package-Requires: ((editorconfig "0.6.0"))
;; Keywords: tools

;; This file is not part of GNU Emacs.

;; This is free and unencumbered software released into the public domain.

;; Anyone is free to copy, modify, publish, use, compile, sell, or
;; distribute this software, either in source code form or as a compiled
;; binary, for any purpose, commercial or non-commercial, and by any
;; means.

;; In jurisdictions that recognize copyright laws, the author or authors
;; of this software dedicate any and all copyright interest in the
;; software to the public domain. We make this dedication for the benefit
;; of the public at large and to the detriment of our heirs and
;; successors. We intend this dedication to be an overt act of
;; relinquishment in perpetuity of all present and future rights to this
;; software under copyright law.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
;; OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
;; ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;; OTHER DEALINGS IN THE SOFTWARE.

;; For more information, please refer to <http://unlicense.org/>

;;; Commentary:

;; This library adds extra charset supports to editorconfig-emacs.
;; The list of supported charsets is taken from the result of
;; `coding-system-list'.

;; For example, add following to your `.editorconfig`
;; and `sjis.txt` will be opend with `sjis' encoding:

;;     [sjis.txt]
;;     charset = sjis

;; Alternatively, you can specify `emacs_charset` as:

;;     [sjis.txt]
;;     emacs_charset = sjis

;; If both `charset' and `emacs_charset' are defined, the value of
;; `emacs_charset' takes precedence.

;;; Code:

(defun editorconfig-charset-extras--decide (charset emacs-charset)
  "Decide whcih charset to use from CHARSET and EMACS-CHARSET.

CHARSET and EMACS-CHARSET are directly passwd from .editorconfig hash object.
If no apropriate charset found return nil."
  (let ((coding-systems (coding-system-list))
        (charset-interned (and charset
                               (not (string= "" charset))
                               (intern charset)))
        (emacs-charset-interned (and emacs-charset
                                     (not (string= "" emacs-charset))
                                     (intern emacs-charset))))
    (if (and emacs-charset-interned
             (memq emacs-charset-interned
                   coding-systems))
        emacs-charset-interned
      (when emacs-charset-interned
        (message "editorconfig-charset-extras: Charset not found: %S"
                 emacs-charset-interned))
      (if (and charset-interned
               (memq charset-interned
                     coding-systems))
          charset-interned
        (when charset-interned
          (message "editorconfig-charset-extras: Charset not found: %S"
                   charset-interned))
        nil))))

;;;###autoload
(defun editorconfig-charset-extras (hash)
  "Add support for extra charsets to editorconfig from editorconfig HASH.

The list of supported charsets is taken from the result of function
`coding-system-list'."
  (let ((charset (gethash 'charset
                          hash))
        (emacs-charset (gethash 'emacs_charset
                                hash)))
    (let ((decided (editorconfig-charset-extras--decide charset emacs-charset)))
      (when decided
        (set-buffer-file-coding-system decided nil t)))))

(provide 'editorconfig-charset-extras)

;;; editorconfig-charset-extras.el ends here
