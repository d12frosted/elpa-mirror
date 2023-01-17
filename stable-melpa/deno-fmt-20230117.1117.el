;;; deno-fmt.el --- Minor mode for using deno fmt on save -*- lexical-binding: t; -*-

;;; Author: Russell Clarey <http://github/rclarey>
;; Package-Version: 20230117.1117
;;; Package-X-Original-Version: 0.1.0
;;; URL: https://github.com/russell/deno-emacs
;; Package-Commit: 6378966f448a3b9b5ae98af58cd13a031bd26702
;;; Package-Requires: ((emacs "24"))

;; Copyright (c) 2020-2023 Russell Clarey

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

;; Portions modified from go-mode.el
;; https://github.com/dominikh/go-mode.el/blob/166dfb1e090233c4609a50c2ec9f57f113c1da72/go-mode.el
;; Copyright (c) 2014 The go-mode Authors. All rights reserved.

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are
;; met:

;;    * Redistributions of source code must retain the above copyright
;; notice, this list of conditions and the following disclaimer.
;;    * Redistributions in binary form must reproduce the above
;; copyright notice, this list of conditions and the following disclaimer
;; in the documentation and/or other materials provided with the
;; distribution.
;;    * Neither the name of the copyright holder nor the names of its
;; contributors may be used to endorse or promote products derived from
;; this software without specific prior written permission.

;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;; This file is not part of GNU Emacs.

;;; Commentary:
;; Formats your TypeScript/JavaScript code with deno fmt on save

;;; Code:

(defun deno-fmt--apply-rcs-patch (patch-buffer)
  "Apply an RCS-formatted diff from PATCH-BUFFER to the current buffer."
  (let ((target-buffer (current-buffer))
        ;; Relative offset between buffer line numbers and line numbers
        ;; in patch.
        ;;
        ;; Line numbers in the patch are based on the source file, so
        ;; we have to keep an offset when making changes to the
        ;; buffer.
        ;;
        ;; Appending lines decrements the offset (possibly making it
        ;; negative), deleting lines increments it. This order
        ;; simplifies the forward-line invocations.
        (line-offset 0)
        (column (current-column)))
    (save-excursion
      (with-current-buffer patch-buffer
        (goto-char (point-min))
        (while (not (eobp))
          (unless (looking-at "^\\([ad]\\)\\([0-9]+\\) \\([0-9]+\\)")
            (error "Invalid rcs patch or internal error in deno-fmt--apply-rcs-patch"))
          (forward-line)
          (let ((action (match-string 1))
                (from (string-to-number (match-string 2)))
                (len  (string-to-number (match-string 3))))
            (cond
             ((equal action "a")
              (let ((start (point)))
                (forward-line len)
                (let ((text (buffer-substring start (point))))
                  (with-current-buffer target-buffer
                    (setq line-offset (- line-offset len))
                    (goto-char (point-min))
                    (forward-line (- from len line-offset))
                    (insert text)))))
             ((equal action "d")
              (with-current-buffer target-buffer
                (goto-char (point-min))
                (forward-line (- from line-offset 1))
                (setq line-offset (+ line-offset len))
                (let ((start (point)))
                  (forward-line len)
                  (delete-region (point) start))))
             (t
              (error "Invalid rcs patch or internal error in deno-fmt--apply-rcs-patch")))))))
    (move-to-column column)))

(defun deno-fmt ()
  "Format the current buffer with `deno fmt'."
  (interactive)
  (if (not (executable-find "deno"))
      (error "deno executable not found. Visit \"https://deno.land/#installation\" for installation instructions")
    (let ((tempfile (make-temp-file "deno-fmt-temp" nil ".ts"))
          (patchbuffer (get-buffer-create "*deno-fmt patch*"))
          (outbuffer (get-buffer-create "*deno-fmt output*")))
      (unwind-protect
          (progn
            (with-current-buffer patchbuffer (erase-buffer))
            (with-current-buffer outbuffer (erase-buffer))
            (write-region nil nil tempfile)
            (if (zerop (call-process "deno" nil outbuffer nil "fmt" tempfile))
                (progn
                  (call-process-region
                   (point-min) (point-max) "diff" nil patchbuffer
                   nil "-n" "--strip-trailing-cr" "-" tempfile)
                  (deno-fmt--apply-rcs-patch patchbuffer)
                  (message "deno-fmt: formatted"))
              (message "deno-fmt: failed"))))
      (kill-buffer patchbuffer)
      (delete-file tempfile))))

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
