;;; switch-buffer-functions.el --- Hook run when current buffer changed

;; Author: 10sr <8slashes+el [at] gmail [dot] com>
;; URL: https://github.com/10sr/switch-buffer-functions-el
;; Package-Version: 20200127.409
;; Package-Commit: 95a846baa93bac4c3b3c028b9d53507f1042b23a
;; Version: 0.0.1
;; Keywords: hook utility

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

;; This package provides a hook variable `switch-buffer-functions'.

;; This hook will be run when the current buffer has been changed after each
;; interactive command, i.e. `post-command-hook' is called.

;; When functions are hooked, they will be called with the previous buffer and
;; the current buffer.  For example, if you eval:

;; (add-hook 'switch-buffer-functions
;;           (lambda (prev curr)
;;             (cl-assert (eq curr (current-buffer)))  ;; Always t
;;             (message "%S -> %S" prev curr)))

;; then the message like "#<buffer *Messages*> -> #<buffer init.el<.emacs.d>>"
;; will be displayed to the echo area each time when you switch the current
;; buffer.

;;; Code:

;;;###autoload
(defvar switch-buffer-functions
  nil
  "A list of functions to be called when the current buffer has been changed.
Each is passed two arguments, the previous buffer and the current buffer.")

(defvar switch-buffer-functions--last-buffer
  nil
  "The last current buffer.")

;;;###autoload
(defun switch-buffer-functions-run ()
  "Run `switch-buffer-functions' if needed.

This function checks the result of `current-buffer', and run
`switch-buffer-functions' when it has been changed from
the last buffer.

This function should be hooked to `post-command-hook'."
  (unless (eq (current-buffer)
              switch-buffer-functions--last-buffer)
    (let ((current (current-buffer))
          (previous switch-buffer-functions--last-buffer))
      (setq switch-buffer-functions--last-buffer
            current)
      (run-hook-with-args 'switch-buffer-functions
                          previous
                          current))))

;;;###autoload
(add-hook 'post-command-hook
          'switch-buffer-functions-run)

(provide 'switch-buffer-functions)

;;; switch-buffer-functions.el ends here
