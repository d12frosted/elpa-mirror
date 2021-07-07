;;; jsfmt.el --- Interface to jsfmt command for javascript files

;; Copyright (C) 2014 Brett Langdon

;; Author: Brett Langdon <brett@blangdon.com>
;; URL: https://github.com/brettlangdon/jsfmt.el
;; Package-Version: 20180920.1008
;; Package-Commit: ca141a135c7700eaedef92561d334e1fb7dc28a1
;; Version: 0.2.0

;; License that can be found in the LICENSE section in README.

;;; Commentary:

;; this is basically a copy of the necessary parts from
;; go-mode version 20131222, so all credit goes to
;; The Go Authors
;;
;; See also
;;   `jsfmt': https://rdio.github.io/jsfmt

;;; Code:

(defcustom jsfmt-command "jsfmt"
  "The 'jsfmt' command. https://rdio.github.io/jsfmt"
  :type 'string
  :group 'js)

(defun jsfmt--goto-line (line)
  (goto-char (point-min))
  (forward-line (1- line)))

(defalias 'jsfmt--kill-whole-line
  (if (fboundp 'kill-whole-line)
      #'kill-whole-line
    #'kill-entire-line))

;; Delete the current line without putting it in the kill-ring.
(defun jsfmt--delete-whole-line (&optional arg)
  ;; Emacs uses both kill-region and kill-new, Xemacs only uses
  ;; kill-region. In both cases we turn them into operations that do
  ;; not modify the kill ring. This solution does depend on the
  ;; implementation of kill-line, but it's the only viable solution
  ;; that does not require to write kill-line from scratch.
  (cl-flet ((kill-region (beg end)
                      (delete-region beg end))
         (kill-new (s) ()))
    (jsfmt--kill-whole-line arg)))

(defun jsfmt--apply-rcs-patch (patch-buffer)
  "Apply an RCS-formatted diff from PATCH-BUFFER to the current
buffer."
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
            (error "invalid rcs patch or internal error in jsfmt--apply-rcs-patch"))
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
                    (decf line-offset len)
                    (goto-char (point-min))
                    (forward-line (- from len line-offset))
                    (insert text)))))
             ((equal action "d")
              (with-current-buffer target-buffer
                (jsfmt--goto-line (- from line-offset))
                (incf line-offset len)
                (jsfmt--delete-whole-line len)))
             (t
              (error "invalid rcs patch or internal error in jsfmt--apply-rcs-patch")))))))))

(defun run-jsfmt (&optional save ast)
  "Formats the current buffer according to the jsfmt tool."
  (interactive)
  (let ((tmpfile (make-temp-file "jsfmt" nil (if ast
                                                 ".ast"
                                               ".js")))
        (patchbuf (get-buffer-create "*Jsfmt patch*"))
        (errbuf (get-buffer-create "*Jsfmt Errors*"))
        (coding-system-for-read 'utf-8)
        (coding-system-for-write 'utf-8))

    (with-current-buffer errbuf
      (setq buffer-read-only nil)
      (erase-buffer))
    (with-current-buffer patchbuf
      (erase-buffer))

    (write-region nil nil tmpfile)

    ;; We're using errbuf for the mixed stdout and stderr output. This
    ;; is not an issue because jsfmt --write does not produce any stdout
    ;; output in case of success.
    (if save
        (if ast
            (setq success (zerop (call-process jsfmt-command nil errbuf nil "--save-ast" "--write" tmpfile)))
          (setq success (zerop (call-process jsfmt-command nil errbuf nil "--write" tmpfile))))
      (if ast
          (setq success (zerop (call-process jsfmt-command nil errbuf nil "--ast" "--write" tmpfile)))
        (setq success nil))
      (setq success nil))

    (if 'success
        (if (zerop (call-process-region (point-min) (point-max) "diff" nil patchbuf nil "-n" "-" tmpfile))
            (progn
              (kill-buffer errbuf)
              (message "Buffer is already jsfmted"))
          (jsfmt--apply-rcs-patch patchbuf)
          (kill-buffer errbuf)
          (message "Applied jsfmt"))
      (message "Could not apply jsfmt. Check errors for details")
      (jsfmt--process-errors (buffer-file-name) tmpfile errbuf))

    (kill-buffer patchbuf)
    (delete-file tmpfile)))

;;;###autoload
(defun jsfmt ()
  "Formats the current buffer according to the jsfmt tool."
  (interactive)
  (run-jsfmt t nil))

;;;###autoload
(defun jsfmt-save-ast ()
  "Formats the current buffer according to the jsfmt ast tool."
  (interactive)
  (run-jsfmt t t))

;;;###autoload
(defun jsfmt-load-ast ()
  "Formats the current buffer according to the jsfmt ast tool."
  (interactive)
  (run-jsfmt nil t))

(defun jsfmt--process-errors (filename tmpfile errbuf)
  ;; Convert the jsfmt stderr to something understood by the compilation mode.
  (with-current-buffer errbuf
    (goto-char (point-min))
    (insert "jsfmt errors:\n")
    (while (search-forward-regexp (concat "^\\(" (regexp-quote tmpfile) "\\):") nil t)
      (replace-match (file-name-nondirectory filename) t t nil 1))
    (compilation-mode)
    (display-buffer errbuf)))

;;;###autoload
(defun jsfmt-before-save ()
  "Add this to .emacs to run jsfmt on the current buffer before saving:
 (add-hook 'before-save-hook 'jsfmt-before-save)."
  (interactive)
  (when (memq major-mode '(js-mode js2-mode js3-mode)) (jsfmt)))

;;;###autoload
(defun jsfmt-ast-before-save ()
  "Add this to .emacs to run 'jsfmt --save-ast' on the buffer before saving
 (add-hook 'before-save-hook 'jsfmt-ast-before-save)."
  (interactive)
  (when (memq major-mode '(js-mode js2-mode js3-mode)) (jsfmt-save-ast)))

;;;###autoload
(defun jsfmt-ast-find-file ()
  "Add this to .emacs to run 'jsfmt --ast' on the file being loaded
 (add-hook 'find-file-hook 'jsfmt-ast-find-file)."
  (interactive)
  (when (memq major-mode '(js-mode js2-mode js3-mode)) (jsfmt-load-ast)))

;;;###autoload
(defun jsfmt-ast ()
  "Add this to .emacs to run enabling jsfmt loading .ast files as javascript and saving
   the javascript back as ast
  (add-to-list 'auto-mode-alist '(\"\\.ast$\" . (lambda()
                                                  (jsfmt-ast)
                                                  (js-mode))))"
  (interactive)
  ;; before saving convert to AST
  (defvar jsfmt-current-line (line-number-at-pos))
  (add-hook 'before-save-hook (lambda()
                                (setq jsfmt-current-line (line-number-at-pos))
                                (jsfmt-ast-before-save)))
  ;; after saving convert buffer back to js for editing
  (add-hook 'after-save-hook (lambda()
                               (jsfmt-ast-find-file)
                               (set-buffer-modified-p nil)
                               (goto-line (symbol-value 'jsfmt-current-line))))
  ;; when opening file convert from AST to js
  (add-hook 'find-file-hook 'jsfmt-ast-find-file))

(provide 'jsfmt)

;;; jsfmt.el ends here
