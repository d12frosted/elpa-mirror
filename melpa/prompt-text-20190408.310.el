;;; prompt-text.el --- Configure your minibuffer prompt

;; Author: 10sr <8slashes+el [at] gmail [dot] com>
;; URL: https://github.com/10sr/prompt-text-el
;; Package-Version: 20190408.310
;; Package-Commit: f51cf3d7f08ab8946e9869f7de2082536e45cc22
;; Version: 0.1
;; Keywords: utility minibuffer

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

;; `prompt-text` provides a feature to print additional information
;; always when Emacs asks you something in minibuffer.

;; By default the text includes your login name, hostname and current working
;; directory.
;; For example, when you type `M-x`, Emacs will give you a prompt like:

;;     10sr@mbp0:~/prompt-text-el M-x

;; Enable global minor-mode `prompt-text-mode` to start using.

;; You can set `prompt-text-format` to change the text to print.
;; This value will be formatted with `format-mode-line`: see docstring of
;; `mode-line-format` for available expressions.


;;; Code:

(defgroup prompt-text nil
  "Print various information in minibuffer prompt."
  :group 'mode-line)

(defcustom prompt-text-format
  `(,(concat user-login-name
             "@"
             (car (split-string system-name
                                "\\."))
             ":")
    (:eval (abbreviate-file-name default-directory))
    " ")
  "Format text to be prepended to prompt texts of minibuffer.
The value should be in the mode-line format: see `mode-line-fomat' for details."
  :group 'prompt-text
  :type 'sexp)

(defvar prompt-text--already
  nil
  "Set to non-nil when the test already added.")

(defmacro prompt-text--defadvice (&rest functions)
  "Set prompt-text advices for FUNCTIONS."
  `(progn
     ,@(mapcar (lambda (f)
                 `(defadvice ,f (around prompt-text-modify)
                    "Show info in prompt."
                    (unless prompt-text--already
                      (let ((orig (ad-get-arg 0))
                            (str (format-mode-line prompt-text-format)))
                        (ad-set-arg 0
                                    (concat str
                                            orig))))
                    (let ((prompt-text--already t))
                      ad-do-it)))
               functions)))

(prompt-text--defadvice read-from-minibuffer
                        read-string
                        completing-read)

;;;###autoload
(define-minor-mode prompt-text-mode
  "Print various infomation in minibuffer prompt.
Set `prompt-text-format' to configure what text to print."
  :init-value nil
  :global t
  :lighter ""
  (if prompt-text-mode
      (ad-activate-regexp "\\`prompt-text-modify\\'")
    (ad-deactivate-regexp "\\`prompt-text-modify\\'")))

(provide 'prompt-text)

;;; prompt-text.el ends here
