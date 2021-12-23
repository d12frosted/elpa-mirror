;;; rufo.el --- use rufo to automatically format ruby files

;; Copyright (c) 2014 The go-mode Authors. All rights reserved.
;; Portions Copyright (C) 2017 Daniel Ma. All rights reserved.
;; 
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are
;; met:
;; 
;;    * Redistributions of source code must retain the above copyright
;; notice, this list of conditions and the following disclaimer.
;;    * Redistributions in binary form must reproduce the above
;; copyright notice, this list of conditions and the following disclaimer
;; in the documentation and/or other materials provided with the
;; distribution.
;;    * Neither the name of the copyright holder nor the names of its
;; contributors may be used to endorse or promote products derived from
;; this software without specific prior written permission.
;; 
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

;; Author: Daniel Ma <danielhgma@gmail.com> and contributors
;; URL: https://github.com/danielma/rufo.el
;; Package-Commit: 020b02ed6e9ab49e79d2ddf63e4ee2684c1728f4
;; Version: 0.3.0
;; Package-Version: 20170718.1416
;; Package-X-Original-Version: 0.3.0
;; Package-Requires: ((emacs "24.3"))

;;; Commentary:

;; This package provides the rufo-minor-mode minor mode, which will use rufo
;; (https://github.com/ruby-formatter/rufo) to automatically fix ruby code
;; when it is saved.

;; To use it, require it, make sure `rufo' is in your path and add it to
;; your favorite ruby mode:

;;    (add-hook 'ruby-mode-hook #'rufo-minor-mode)

;;; Code:
(defgroup rufo-minor-mode nil
  "Fix ruby code with rufo"
  :group 'tools)

(defcustom rufo-minor-mode-executable "rufo"
  "The rufo executable name."
  :group 'rufo-minor-mode
  :type 'string)

(defcustom rufo-minor-mode-use-bundler nil
  "Whether ‘rufo-minor-mode’ should use the bundler version of rufo."
  :group 'rufo-minor-mode
  :type 'boolean)

(defcustom rufo-minor-mode-debug-mode nil
  "Whether ‘rufo-minor-mode’ should message debug information."
  :group 'rufo-minor-mode
  :type 'boolean)

(defvar-local rufo-minor-mode--verified nil
  "Set to t if rufo has been verified as working for this buffer.")

(defun rufo-minor-mode--goto-line (line)
  "Move point to LINE."
  (goto-char (point-min))
  (forward-line (1- line)))

(defun rufo-minor-mode--apply-rcs-patch (patch-buffer)
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
        (line-offset 0))
    (save-excursion
      (with-current-buffer patch-buffer
        (if rufo-minor-mode-debug-mode
            (message (concat "rufo diff: " (buffer-string))))
        (goto-char (point-min))
        (while (not (eobp))
          (unless (looking-at "^\\([ad]\\)\\([0-9]+\\) \\([0-9]+\\)")
            (error "Invalid rcs patch or internal error in rufo-minor-mode--apply-rcs-patch"))
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
                (rufo-minor-mode--goto-line (- from line-offset))
                (setq line-offset (+ line-offset len))
                (kill-whole-line len)))
             (t
              (error "Invalid rcs patch or internal error in rufo-minor-mode--apply-rcs-patch")))))))))

(defun rufo-minor-mode--executable ()
  "Return the executable for running rufo."
  (if rufo-minor-mode-use-bundler
      (executable-find "bundle")
    (executable-find rufo-minor-mode-executable)))

(defun rufo-minor-mode--args ()
  "Get the args for calling rufo."
  (let ((args
         (append
          (if rufo-minor-mode-use-bundler (list "exec" rufo-minor-mode-executable))
          (if buffer-file-name (list (concat "--filename=" (shell-quote-argument buffer-file-name)))))))
    (if (< 0 (length args)) args)))

(defun rufo-minor-mode--executable-available-p ()
  "Verify that the rufo executable exists."
  (let ((executable (rufo-minor-mode--executable))
        (args (rufo-minor-mode--args)))
    (and executable
         (zerop (call-process-shell-command (concat
                                             "("
                                             executable
                                             " "
                                             (if args (mapconcat 'identity args " "))
                                             " --help"
                                             ")"))))))

(defun rufo-minor-mode--verify ()
  "Set ‘rufo-minor-mode--verified’ to true if the executable is runnable."
  (or rufo-minor-mode--verified
      (cond ((not (rufo-minor-mode--executable-available-p))
             (rufo-minor-mode -1)
             (message "rufo-minor-mode: Could not find rufo.")
             nil)
            (t (setq-local rufo-minor-mode--verified t)))))

(defun rufo-minor-mode--kill-error-buffer (errbuf)
  "Kill buffer ERRBUF."
  (let ((win (get-buffer-window errbuf)))
    (if win
        (quit-window t win)
      (with-current-buffer errbuf
        (erase-buffer))
      (kill-buffer errbuf))))

(defun rufo-minor-mode--should-apply-patch-p (rufo-status-code)
  "Check if the file needs changes based on `RUFO-STATUS-CODE'."
  (eq rufo-status-code 3))

(defun rufo-format ()
  "Format the current buffer with rufo."
  (interactive)
  (let* ((ext (file-name-extension (or buffer-file-name "source.rb") t))
         (outputfile (make-temp-file "rufo-output" nil ext))
         (errorfile (make-temp-file "rufo-errors" nil ext))
         (errbuf (get-buffer-create "*rufo errors*"))
         (patchbuf (get-buffer-create "*rufo patch*"))
         (executable (rufo-minor-mode--executable))
         (coding-system-for-read 'utf-8)
         (coding-system-for-write 'utf-8)
         (rufo-args (rufo-minor-mode--args))
         (rufo-call-result nil)
         )
    (if (rufo-minor-mode--verify)
        (unwind-protect
            (save-restriction
              (with-current-buffer errbuf
                (setq buffer-read-only nil)
                (erase-buffer)))
          (with-current-buffer patchbuf
            (erase-buffer))
          (setq rufo-call-result (if rufo-args
                                     (apply 'call-process-region (point-min) (point-max) executable nil (list :file outputfile) nil rufo-args)
                                   (call-process-region (point-min) (point-max) executable nil (list :file outputfile) nil)))
          (when (rufo-minor-mode--should-apply-patch-p rufo-call-result)
            (call-process-region nil nil "diff" nil patchbuf nil "-n" "--text" "-" outputfile)
            (rufo-minor-mode--apply-rcs-patch patchbuf)
            (message "Applied rufo with args `%s'" rufo-args)
            (if errbuf (rufo-minor-mode--kill-error-buffer errbuf)))))
      (kill-buffer patchbuf)
      (delete-file errorfile)
      (delete-file outputfile)))

;;;###autoload
(define-minor-mode rufo-minor-mode
  "Use rufo to automatically fix ruby before saving."
  :lighter " rufo"
  (if rufo-minor-mode
      (add-hook 'before-save-hook #'rufo-format nil t)
    (setq-local rufo-minor-mode--verified nil)
    (remove-hook 'before-save-hook #'rufo-format t)))

(provide 'rufo)
;;; rufo.el ends here
