;;; with-venv.el --- Execute with Python virtual environment activated  -*- lexical-binding: t; -*-

;; Author: 10sr <8.slashes [at] gmail [dot] com>
;; URL: https://github.com/10sr/with-venv-el
;; Package-Version: 20210925.2336
;; Package-Commit: 773192d892ec0341e023d8b5e80639f8eb79f2a5
;; Version: 0.0.2
;; Keywords: processes python venv
;; Package-Requires: ((cl-lib "0.5") (emacs "24.4"))

;; This file is not part of GNU Emacs.

;;   Licensed under the Apache License, Version 2.0 (the "License");
;;   you may not use this file except in compliance with the License.
;;   You may obtain a copy of the License at

;;
;;   http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS,
;;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;   See the License for the specific language governing permissions and
;;   limitations under the License.

;;; Commentary:

;; `with-venv' macro executes BODY with Python virtual environment activated:

;; (with-venv
;;   (executable-find "python"))

;; This macro search for suitable venv directory for current evironment:
;; by default it supports `pipenv`, `poetry`, and directories named
;; `".venv"` and `"venv"`.
;; You can modify `with-venv-find-venv-dir-functions' to add or remove
;; these supports.

;; The automatic search result will be cached as a buffer-local variable, so
;; `with-venv' try to find venv dir only at the first time it is used after
;; visiting file.
;; To explicitly update this cache (without re-visiting file) after you
;; created/changed a virtual environment, invoke M-x `with-venv-find-venv-dir'
;; manually.

;; You can also set buffer-local vairable `with-venv-venv-dir' explicitly
;; to specify venv directory for `with-venv' macro.
;; In this case, the automatic search will be totally disabled for that buffer.


;; If you want to always enable `with-venv' for certain functions,
;; `with-venv-advice-add' can be used for that purpose:

;; (with-venv-advice-add 'blacken-buffer)

;; Adviced functions are always wrapped with `with-venv' macro when called.

;; Call `with-venv-advice-remove' to remove these advices.

;;; Code:

(require 'cl-lib)
(require 'nadvice)

(defvar-local with-venv-venv-dir
  nil
  "Venv directory path.

This variable is intended to be explicitly set by user.
When nil, `with-venv' tries to find suitable venv dir.
When empty string (\"\"), it means that venv is not available for this buffer.
When this variable is set to non-empty string, use this value without checking
if it is a valid python environment.")

;;;###autoload
(defmacro with-venv-dir (dir &rest body)
  "Set python environment to DIR and execute BODY.

This macro does not check if DIR is a valid python environemnt.
If dir is nil or empty string (\"\"), execute BODY as usual."
  (declare (indent 1) (debug t))
  (let ((dirval (cl-gensym)))
    `(let ((,dirval ,dir)
           (--with-venv-process-environment-orig (cl-copy-list process-environment))
           (--with-venv-exec-path-orig (cl-copy-list exec-path)))
       (unwind-protect
           (progn
             (when (and ,dirval
                        (not (string= ,dirval
                                      "")))
               (let* ((dir (file-name-as-directory ,dirval))
                      (bin (expand-file-name "bin" dir)))
                 ;; Do the same thing that bin/activate does
                 (setq exec-path
                       (cons bin
                             exec-path))
                 (setenv "VIRTUAL_ENV" dir)
                 (setenv "PATH" (if (string= ""
                                             (or (getenv "PATH") ""))
                                    bin
                                  (concat bin ":" (getenv "PATH"))))
                 (setenv "PYTHONHOME")))
             ,@body)
         (setq process-environment
               --with-venv-process-environment-orig)
         (setq exec-path
               --with-venv-exec-path-orig)))))


(defvar-local with-venv--venv-dir-found nil
  "Previously used venv dir path.
Set by `with-venv-find-venv-dir' using `with-venv-find-venv-dir-functions'.

Default value nil means that venv search has not done for this buffer yet.
When empty string (\"\"), it means that venv is not available for this buffer.
To force search venv again, run `with-venv-find-venv-dir' manually.
")

(defvar-local with-venv-found-type nil
  "`with-venv' directory type of current buffer.

Used by `with-venv-info-mode'.")

(defvar with-venv--last-found-type nil
  "Last found type.")

;;;###autoload
(defmacro with-venv (&rest body)
  "Execute BODY with venv enabled.

This function tries to find suitable venv dir, or run BODY as usual when no
suitable environment was found.

This function calls `with-venv-find-venv-dir' with no-refresh enabled to
search venv dir for current buffer.
The result will be cached so this search won't be done any more for current
session unless you explicitly invoke `with-venv-find-venv-dir' command manually."
  (declare (indent 0) (debug t))
  `(with-venv-dir
       ;; If set explicitly use it
       (or with-venv-venv-dir
           ;; Check previously used directory
           (with-venv-find-venv-dir t))
     ,@body))

(defun with-venv-find-venv-dir (&optional no-refresh)
  "Search for venv dir and set it to `with-venv--venv-dir-found'.

If optional arg NO-REFRESH is non-nil and `with-venv--venv-dir-found' is
already set, do not search for venv dir again.

If suitable dir not found, set the value to empty string (\"\").
Return value of `with-venv--venv-dir-found'."
  (interactive)
  (unless (and with-venv--venv-dir-found
               no-refresh)
    (setq with-venv--venv-dir-found (or (with-venv--find-venv-dir)
                                        ""))
    ;; FIXME: Not work when called in parallel
    (setq with-venv-found-type
          with-venv--last-found-type)
    (setq with-venv--last-found-type
          nil)
    )
  with-venv--venv-dir-found)

(defcustom with-venv-find-venv-dir-functions
  nil
  "Functions to find venv dir.

See `with-venv-find-venv-dir' how this variable is used."
  :type 'hook
  :group 'with-venv)
(add-hook 'with-venv-find-venv-dir-functions
          'with-venv-find-venv-dir-pipenv
          t)
(add-hook 'with-venv-find-venv-dir-functions
          'with-venv-find-venv-dir-poetry
          t)
(add-hook 'with-venv-find-venv-dir-functions
          'with-venv-find-venv-dir-dot-venv
          t)
(add-hook 'with-venv-find-venv-dir-functions
          'with-venv-find-venv-dir-venv
          t)

(defun with-venv--find-venv-dir (&optional dir)
  "Try to find venv dir for DIR.
If none found return nil.

This function processes `with-venv-find-venv-dir-functions' with
`run-hook-with-args-until-success'."
  (with-temp-buffer
    (when dir
      (cd dir))
    (run-hook-with-args-until-success 'with-venv-find-venv-dir-functions)))

(defun with-venv-find-venv-dir-pipenv ()
  "Try to find venv dir via pipenv."
  (when (executable-find "pipenv")
    (with-temp-buffer
      (let ((status (call-process "pipenv" nil t nil "--venv")))
        (when (eq status 0)
          (setq with-venv--last-found-type "Pipenv")
          (goto-char (point-min))
          (buffer-substring-no-properties (point-at-bol)
                                          (point-at-eol)))))))

(defun with-venv-find-venv-dir-poetry ()
  "Try to find venv dir via poetry."
  (when (executable-find "poetry")
    (with-temp-buffer
      (let ((status (call-process "poetry" nil t nil "env" "info" "--path")))
        (when (eq status 0)
          (setq with-venv--last-found-type "Poetry")
          (goto-char (point-min))
          (buffer-substring-no-properties (point-at-bol)
                                          (point-at-eol)))))))

(defun with-venv-find-venv-dir-poetry-legacy ()
  "Try to find venv dir via poetry debug:info command."
  (when (executable-find "poetry")
    (with-temp-buffer
      (let ((status (call-process "poetry" nil t nil "debug:info")))
        (when (eq status 0)
          (goto-char (point-min))
          (save-match-data
            (when (re-search-forward "^ \\* Path: *\\(.*\\)$")
              (setq with-venv--last-found-type "Poetry")
              (match-string 1))))))))

(defun with-venv-find-venv-dir-dot-venv ()
  "Try to find venv dir by its name."
  (let ((dir (locate-dominating-file default-directory
                                     ;; OK on windows?
                                     ".venv/bin/python")))
    (when dir
      (setq with-venv--last-found-type ".venv/")
      (expand-file-name ".venv"
                        dir))))

(defun with-venv-find-venv-dir-venv ()
  "Try to find venv dir by its name."
  (let ((dir (locate-dominating-file default-directory
                                     ;; OK on windows?
                                     "venv/bin/python")))
    (when dir
      (setq with-venv--last-found-type "venv/")
      (expand-file-name "venv"
                        dir))))

;;;###autoload
(defun with-venv-advice-add (func)
  "Setup advice so that `with-venv' macro is always applied to FUNC."
  (advice-add func
              :around
              'with-venv--advice-around))

;;;###autoload
(defun with-venv-advice-remove (func)
  "Remove advice of FUNC added by `with-venv-advice-add'."
  (advice-remove func
                 'with-venv--advice-around))

(defun with-venv--advice-around (orig-func &rest args)
  "Function to be used to advice functions with `with-venv-advice-add'.
When a function is adviced with this function, it is wrapped with `with-venv'.

ORIG-FUNC is the target function, and ARGS is the argument when it is called."
  (with-venv
    (apply orig-func args)))


;; with-venv-info-mode

(defun with-venv-info-lighter ()
  "Genarete status of `with-venv-info-mode'."
  (let ((type (if with-venv-venv-dir
                  "Given"
                (if (string= ""
                             with-venv--venv-dir-found)
                    "-"
                  (or with-venv-found-type
                      "?")))))
    (format " W/V[%s]"
            type)))

;;;###autoload
(define-minor-mode with-venv-info-mode
  "Minor-mode to show info about current `with-venv' activated directory."
  :lighter (:eval (with-venv-info-lighter))
  nil)

(provide 'with-venv)

;;; with-venv.el ends here
