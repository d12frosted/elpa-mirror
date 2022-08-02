;;; py-autopep8.el --- Use autopep8 to beautify a Python buffer -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later
;; Copyright (C) 2022  Campbell Barton  <ideasman42@gmail.com>
;; Copyright (C) 2013-2015, Friedrich Paetzke <f.paetzke@gmail.com>

;; Author: Friedrich Paetzk <f.paetzke@gmail.com>

;; URL: https://github.com/ideasman42/emacs-py-autopep8
;; Package-Version: 20220802.1154
;; Package-Commit: 4e5a8d5ddd77b45841f0e55d7c5326854f565830
;; Keywords: convenience
;; Version: 2016.1
;; Package-Requires: ((emacs "26.1"))

;;; Commentary:

;; Provides the `py-autopep8-buffer' command, which uses the external "autopep8"
;; tool to tidy up the current buffer according to Python's PEP8.

;;; Usage

;;
;; To automatically apply when saving a python file, use the
;; following code:
;;
;;   (add-hook 'python-mode-hook 'py-autopep8-mode)
;;
;; To customize the behavior of "autopep8" you can set the
;; `py-autopep8-options' e.g.
;;
;;   (setq py-autopep8-options '("--max-line-length=100" "--aggressive"))
;;

;;; Code:

(defgroup py-autopep8 nil
  "Use autopep8 to beautify a Python buffer manually or using a save hook."
  :group 'convenience)

(defcustom py-autopep8-command "autopep8"
  "The location of the autopep8 command (otherwise find in PATH)."
  :type 'string)

(defcustom py-autopep8-options nil
  "Options used for autopep8.

Note that `-' and '--exit-code' are used by default."
  :type '(repeat (string :tag "option")))

(defcustom py-autopep8-on-save-p 'always
  "Only reformat on save if this function returns non-nil.

You may wish to choose one of the following options:
- `always': To always format on save.
- `py-autopep8-check-pyproject-exists':
  Only reformat when \"pyproject.toml\" exists.
- `py-autopep8-check-pyproject-exists-with-autopep8':
  Only reformat when \"pyproject.toml\" exists and
  contains a [tool.autopep8] entry.

Otherwise you can set this to a user defined function."
  :type 'function)

;; ---------------------------------------------------------------------------
;; Generic Utility Functions

(defun py-autopep8--locate-dominating-file-from-buffer (filename)
  "Return the path to the current buffers FILENAME file or nil."
  (let ((filepath buffer-file-name))
    (when filepath
      (let ((dir (locate-dominating-file (file-name-directory filepath) filename)))
        (when dir
          (concat dir filename))))))

(defun py-autopep8--region-contract-to-whole-lines (beg end)
  "Clamp BEG & END to whole lines."
  (let
    (
      (beg-bol (line-beginning-position beg))
      (end-eol (line-end-position end)))

    ;; If the leading/trailing parts of the beginning/end lines is white-space
    ;; then extend the selection to the bounds, otherwise contract the range
    ;; so a partially selected line is excluded from the range
    ;; as `autopep8' operates on line-ranges.
    (when (< beg-bol beg)
      (save-excursion
        (goto-char beg)
        (skip-chars-backward "[:blank:]" beg-bol)
        (setq beg (point))
        (when (< beg-bol beg)
          ;; Partial line selected, step to the next line.
          (forward-line 1)
          (setq beg (line-beginning-position)))))
    (when (> end-eol end)
      (save-excursion
        (goto-char end)
        (skip-chars-forward "[:blank:]" end-eol)
        (setq end (point))
        (when (> end-eol end)
          ;; Partial line selected, step to the previous line.
          (forward-line -1)
          (setq end (line-end-position))))))

  (cond
    ((< beg end)
      (cons beg end))
    (t
      nil)))

(defun py-autopep8--replace-buffer-contents-with-fastpath (buf)
  "Replace buffer contents with BUF, fast-path when undo is disabled.

Useful for fast operation, especially for automated conversion or tests."
  (let
    (
      (is-beg (eq (point) (point-min)))
      (is-end (eq (point) (point-max))))
    (cond
      ((and (eq t buffer-undo-list) (or is-beg is-end))
        ;; No undo, use a simple method instead of `replace-buffer-contents',
        ;; which has no benefit unless undo is in use.
        (erase-buffer)
        (insert-buffer-substring buf)
        (cond
          (is-beg
            (goto-char (point-min)))
          (is-end
            (goto-char (point-max)))))
      (t
        (replace-buffer-contents buf)))))


;; ---------------------------------------------------------------------------
;; Internal Functions

(defun py-autopep8--buffer-format-impl (range stdout-buffer stderr-buffer)
  "Format current buffer using temporary STDOUT-BUFFER and STDERR-BUFFER.
When RANGE is non-nil it's used as the range to format.
Return non-nil when a the buffer was modified."
  (when (not (executable-find py-autopep8-command))
    (user-error "py-autopep8: %s command not found" py-autopep8-command))

  ;; Set the default coding for the temporary buffers.
  (let
    (
      (sentinel-called nil)
      (command-with-args
        (append (list py-autopep8-command) py-autopep8-options (list "-" "--exit-code")))
      (this-buffer-coding buffer-file-coding-system)
      (stderr-as-string nil)
      (pipe-err-as-string nil)

      ;; Set this for `make-process' as there are no files for autopep8
      ;; to use to detect where to read local configuration from,
      ;; it's important the current directory is used to look this up.
      (default-directory (file-name-directory (buffer-file-name))))

    ;; Support for formatting a limited range.
    (when range
      (setq range (py-autopep8--region-contract-to-whole-lines (car range) (cdr range)))
      (unless range
        (user-error "The range did not include whole lines!"))

      ;; Contract the region around partially selected lines.
      ;; NOTE: no need for special handling of narrowing in save hooks.
      (let*
        (
          (line-beg (count-lines (point-min) (car range)))
          (line-end (+ (1- line-beg) (count-lines (car range) (cdr range)))))
        (nconc
          command-with-args
          (list
            "--line-range" (number-to-string (1+ line-beg)) (number-to-string (1+ line-end))))))

    (let
      (
        (proc
          (make-process
            :name "autopep8-proc"
            :buffer stdout-buffer
            :stderr stderr-buffer
            :coding (cons this-buffer-coding this-buffer-coding)
            :connection-type 'pipe
            :command command-with-args
            :sentinel
            (lambda (_proc _msg)
              (setq sentinel-called t)

              ;; Assign in the sentinel to prevent "Process .. finished"
              ;; being written to `stderr-buffer' otherwise it's difficult
              ;; to know if there was an error or not since an exit value
              ;; of 2 may be used for invalid arguments as well as to check
              ;; if the buffer was re-formatted.
              (unless (zerop (buffer-size stderr-buffer))
                (with-current-buffer stderr-buffer
                  (setq stderr-as-string (buffer-string))
                  (erase-buffer)))))))

      (condition-case err
        (progn
          (process-send-region proc (point-min) (point-max))
          (process-send-eof proc))
        (file-error
          ;; Formatting exited with an error, closing the `stdin' during execution.
          ;; Even though the `stderr' will almost always be set,
          ;; store the error as it may show additional context.
          (setq pipe-err-as-string (error-message-string err))))

      (while (not sentinel-called)
        (accept-process-output))

      (let ((exit-code (process-exit-status proc)))
        (cond
          ((zerop exit-code)
            ;; No difference.
            nil)
          ((or (not (eq exit-code 2)) stderr-as-string pipe-err-as-string)
            (when pipe-err-as-string
              (message "py-autopep8: pipe closed with error (%s)" pipe-err-as-string))
            (when stderr-as-string
              (message "py-autopep8: error output\n%s" stderr-as-string))
            (message
              "py-autopep8: Command %S failed with exit code %d!"
              command-with-args
              exit-code)
            nil)
          (t
            (py-autopep8--replace-buffer-contents-with-fastpath stdout-buffer)
            t))))))

(defun py-autopep8--buffer-format (range)
  "Format the current buffer.
When RANGE is non-nil it's used as the range to format.
Return non-nil when a the buffer was modified."
  (let
    (
      (stdout-buffer nil)
      (stderr-buffer nil)
      (this-buffer (current-buffer)))
    (with-temp-buffer
      (setq stdout-buffer (current-buffer))
      (with-temp-buffer
        (setq stderr-buffer (current-buffer))
        (with-current-buffer this-buffer
          (py-autopep8--buffer-format-impl range stdout-buffer stderr-buffer))))))

(defun py-autopep8--buffer-format-for-save-hook ()
  "Callback for `before-save-hook'."
  ;; Demote errors as this is user configurable, we can't be sure it wont error.
  (when (with-demoted-errors "py-autopep8: Error %S" (funcall py-autopep8-on-save-p))
    (py-autopep8--buffer-format nil))
  ;; Always return nil, continue to save.
  nil)

;; ---------------------------------------------------------------------------
;; Internal Mode Functions

(defun py-autopep8--enable ()
  "Enable the hooks associated with `py-autopep8-mode'."
  (add-hook 'before-save-hook #'py-autopep8--buffer-format-for-save-hook nil t))

(defun py-autopep8--disable ()
  "Disable the hooks associated with `py-autopep8-mode'."
  (remove-hook 'before-save-hook #'py-autopep8--buffer-format-for-save-hook t))


;; ---------------------------------------------------------------------------
;; Public Auto-Format Predicate Functions

(defun py-autopep8-check-pyproject-exists ()
  "Return t when a pyproject.toml file is found."
  (let ((project-file (py-autopep8--locate-dominating-file-from-buffer "pyproject.toml")))
    (not (null project-file))))

(defun py-autopep8-check-pyproject-exists-with-autopep8 ()
  "Return t when a pyproject.toml file is found with a tool.autopep8 entry."
  (let ((project-file (py-autopep8--locate-dominating-file-from-buffer "pyproject.toml")))
    (when project-file
      (with-temp-buffer
        (insert-file-contents project-file)
        (goto-char (point-min))

        (save-match-data
          (let ((case-fold-search nil))
            ;; Final result is true when this search succeeds.
            ;; NOTE: this isn't bullet-proof as it's possible to have this in the
            ;; middle of a multi-line string. In practice this seems unlikely though.
            (re-search-forward "^[[:blank:]]*\\[tool\\.autopep8\\]" nil t)))))))


;; ---------------------------------------------------------------------------
;; Public Functions

;;;###autoload
(defun py-autopep8-buffer ()
  "Use the \"autopep8\" tool to reformat the current buffer.
Return non-nil when a the buffer was modified."
  (interactive)
  (py-autopep8--buffer-format nil))

;;;###autoload
(defun py-autopep8-region (beg end)
  "Use the \"autopep8\" tool to reformat whole lines in the region (BEG, END).
Return non-nil when a the buffer was modified."
  (interactive "r")
  (py-autopep8--buffer-format (cons beg end)))

;; Deprecated (in favor of the minor mode, which can be disabled).
;;;###autoload
(defun py-autopep8-enable-on-save ()
  "Pre-save hook to be used before running autopep8."
  (interactive)
  (message "py-autopep8-enable-on-save is deprecated! use [py-autopep8-mode] instead!")
  (py-autopep8--enable))

;;;###autoload
(define-minor-mode py-autopep8-mode
  "Py-autopep8 minor mode."
  :global nil
  :lighter ""
  :keymap nil

  (cond
    (py-autopep8-mode
      (py-autopep8--enable))
    (t
      (py-autopep8--disable))))

(provide 'py-autopep8)
;;; py-autopep8.el ends here
