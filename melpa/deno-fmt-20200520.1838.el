;;; deno-fmt.el --- Minor mode for using deno fmt on save -*- lexical-binding: t; -*-

;;; Author: Russell Clarey <http://github/rclarey>
;; Package-Version: 20200520.1838
;;; Package-X-Original-Version: 0.1.0
;;; URL: https://github.com/russell/deno-emacs
;; Package-Commit: 3b193eef576e2c14fdcf350495955e6e8546dddd
;;; Package-Requires: ((emacs "24"))

;; Copyright (c) 2020 Russell Clarey

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;; This file is not part of GNU Emacs.

;;; Commentary:
;; Formats your TypeScript/JavaScript code with deno fmt on save

;;; Code:

(defun deno-fmt ()
  "Format the current buffer with `deno fmt'."
  (interactive)
  (if (not (executable-find "deno"))
      (error "deno executable not found. Visit \"https://deno.land/#installation\" for installation instructions")
    (let ((tempfile (make-temp-file "deno-fmt-temp" nil ".ts"))
          (outbuffer (get-buffer-create "*deno-fmt-temp.ts*")))
      (unwind-protect
          (progn
            (with-current-buffer outbuffer (erase-buffer))
            (write-region nil nil tempfile)
            (if (zerop (call-process "deno" nil outbuffer nil "fmt" tempfile))
                (let ((p (point)))
                  (save-excursion
                    (with-current-buffer (current-buffer)
                      (erase-buffer)
                      (insert-file-contents tempfile)))
                  (goto-char p)
                  (message "deno-fmt: formatted")
                  (kill-buffer outbuffer))
              (progn
                (message "deno-fmt: failed")
                (display-buffer outbuffer))))
        (delete-file tempfile)))))

;;;###autoload
(define-minor-mode deno-fmt-mode
  "Runs `deno fmt' on save when enabled"
  :lighter " deno-fmt"
  :global nil
  (if deno-fmt-mode
      (add-hook 'before-save-hook #'deno-fmt nil 'local)
    (remove-hook 'before-save-hook #'deno-fmt 'local)))

(provide 'deno-fmt)
;;; deno-fmt.el ends here
