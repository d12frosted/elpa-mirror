;;; nash-mode.el --- Nash major mode                      -*- lexical-binding: t; -*-

;; Copyright 2016 Tiago Natel de Moura. All rights reserved.
;; Use of this source code is governed by a BSD-style
;; license that can be found in the LICENSE file.

;; Author: Tiago Natel de Moura
;; Version: 0.1
;; Package-Version: 20160830.1212
;; Package-Commit: bb7ae728a16812a0ef506483b877f6221c92ca9c
;; Keywords: nash languages
;; URL: https://github.com/tiago4orion/nash-mode.el

;; This package is not part of GNU Emacs.
;; Based on go-mode.el

;;; Code:

(defvar nash-keywords '("if" "else" "for" "import" "bindfn" "dump" "setenv" "fn") )
(defvar nash-builtins '("len"))

(defconst nash-comment-regexp "#.*")
(defconst nash-identifier-regexp "[[:word:][:multibyte:]]+")
(defconst nash-variable-regexp (concat "$" nash-identifier-regexp))

(defvar nash-keywords-regexp (regexp-opt nash-keywords 'words))
(defvar nash-builtins-regexp (regexp-opt nash-builtins 'words))

(defgroup nash nil
  "Major mode for editing Nash code."
  :link '(url-link "https://github.com/tiago4orion/nash-mode.el")
  :group 'languages)

(defcustom nash-mode-hook nil
  "Hook called by `nash-mode'."
  :type 'hook
  :group 'nash)

(defcustom nash-fmt-command "nashfmt"
  "The 'nashfmt' command."
  :type 'string
  :group 'nash)


(defcustom nash-fmt-args nil
  "Additional arguments to pass to nashfmt."
  :type '(repeat string)
  :group 'nash)

(defcustom nash-fmt-show-errors 'buffer
  "Where to display nashfmt error output.
It can either be displayed in its own buffer, in the echo area, or not at all.
Please note that Emacs outputs to the echo area when writing
files and will overwrite nashfmt's echo output if used from inside
a `before-save-hook'."
  :type '(choice
          (const :tag "Own buffer" buffer)
          (const :tag "Echo area" echo)
          (const :tag "None" nil))
  :group 'nash)

(defun nash-fmt--kill-error-buffer (errbuf)
  (let ((win (get-buffer-window errbuf)))
    (if win
        (quit-window t win)
      (kill-buffer errbuf))))

(defun nash--apply-rcs-patch (patch-buffer)
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
        (goto-char (point-min))
        (while (not (eobp))
          (unless (looking-at "^\\([ad]\\)\\([0-9]+\\) \\([0-9]+\\)")
            (error "invalid rcs patch or internal error in nash-fmt--apply-rcs-patch"))
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
                    (cl-decf line-offset len)
                    (goto-char (point-min))
                    (forward-line (- from len line-offset))
                    (insert text)))))
             ((equal action "d")
              (with-current-buffer target-buffer
                (goto-char (point-min))
                (forward-line (- from line-offset 1))
                (setq line-offset (+ line-offset len))
                (kill-whole-line len)))
             (t
              (error "invalid rcs patch or internal error in nash--apply-rcs-patch")))))))))

(defun nash-fmt--process-errors (filename tmpfile errbuf)
  (with-current-buffer errbuf
    (if (eq nash-fmt-show-errors 'echo)
        (progn
          (message "%s" (buffer-string))
          (nash-fmt--kill-error-buffer errbuf))

      ;; Convert the nash-fmt stderr to something understood by the compilation mode.
      (goto-char (point-min))
      (insert "nash-fmt errors:\n")
      (let ((truefile tmpfile))
        (while (search-forward-regexp (concat "^\\(" (regexp-quote truefile) "\\):") nil t)
          (replace-match (file-name-nondirectory filename) t t nil 1)))
      (compilation-mode)
      (display-buffer errbuf))))

(defun nash-fmt ()
  "Format the current buffer according to the nashfmt tool."
  (interactive)

  (let ((tmpfile (make-temp-file "nashfmt" nil ".sh"))
        (patchbuf (get-buffer-create "*Nashfmt patch*"))
        (errbuf (if nash-fmt-show-errors (get-buffer-create "*Nashfmt Errors*")))
        (coding-system-for-read 'utf-8)
        (coding-system-for-write 'utf-8)
        our-nashfmt-args)

    (unwind-protect
        (save-restriction
          (widen)
          (if errbuf
              (with-current-buffer errbuf
                (setq buffer-read-only nil)
                (erase-buffer)))
          (with-current-buffer patchbuf
            (erase-buffer))

          (write-region nil nil tmpfile)

          (setq our-nashfmt-args (append our-nashfmt-args
                                       nash-fmt-args
                                       (list "-w" tmpfile)))
          (message "Calling nashfmt: %s %s" nash-fmt-command our-nashfmt-args)
          ;; We're using errbuf for the mixed stdout and stderr output. This
          ;; is not an issue because nashfmt -w does not produce any stdout
          ;; output in case of success.
          (if (zerop (apply #'call-process nash-fmt-command nil errbuf nil our-nashfmt-args))
              (progn
                (if (zerop (call-process-region (point-min) (point-max) "diff" nil patchbuf nil "-n" "-" tmpfile))
                    (message "Buffer is already nashfmted")
                  (nash--apply-rcs-patch patchbuf)
                  (message "Applied nashfmt"))
                (if errbuf (nash-fmt--kill-error-buffer errbuf)))
            (message "Could not apply nashfmt")
            (if errbuf (nash-fmt--process-errors (buffer-file-name) tmpfile errbuf))))

      (kill-buffer patchbuf)
      (delete-file tmpfile)
      )))

(defvar nash-font-lock-keywords
  `(
    (,nash-variable-regexp . font-lock-constant-face)
    (,nash-builtins-regexp . font-lock-function-name-face)
    (,nash-keywords-regexp . font-lock-keyword-face)
    (,nash-comment-regexp . font-lock-comment-face)
    ;; note: order above matters, because once colored, that part won't change.
    ;; in general, longer words first
    ))

;;;###autoload
(defun nash-fmt-enable-on-save ()
  "Add this to `nash-mode-hook' to run nashfmt on the current buffer when saving.
e.g. include something like the following in your emacs startup file:
   (add-hook 'nash-mode-hook 'nash-fmt-enable-on-save)"
  (interactive)
  (add-hook 'before-save-hook 'nash-fmt nil 'local))

;;;###autoload
(define-derived-mode nash-mode fundamental-mode
  "nash mode"
  "Major mode for editing Nash (github.com/NeowayLabs/nash)"
  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'comment-end) "")
  (setq indent-tabs-mode t)

       ;; code for syntax highlighting

  (setq font-lock-defaults '((nash-font-lock-keywords))))

(provide 'nash-mode)

;; Local Variables:
;; coding: utf-8
;; End:

;;; nash-mode.el ends here
