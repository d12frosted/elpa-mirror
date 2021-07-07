;;; with-venv.el --- Execute with Python virtual environment activated  -*- lexical-binding: t; -*-

;; Author: 10sr <8.slashes [at] gmail [dot] com>
;; URL: https://github.com/10sr/with-venv-el
;; Package-Version: 20181220.243
;; Package-Commit: d12341b93420f4acd7a277ed0cd4a54767bc5bd6
;; Version: 0.0.1
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

;; Execute BODY with Python virtual environment activated with `with-venv-dir' macro:

;; (with-venv-dir (expand-file-name ".venv" default-directory)
;;   (executable-find "python"))


;; Alternatively, make this package try to find venv directory automatically
;; with `with-venv':

;; (with-venv
;;   (executable-find "python"))


;; This macro uses `with-venv-find-venv-dir' to find suitable venv directory:
;; this function currently support pipenv, poetry, and can find directories
;; named ".venv".
;; Or, you can set buffer-local vairable `with-venv-venv-dir' to explicitly
;; specify which venv directory to use.


;; If you want to always enable `with-venv' for certain functions, you can use
;; `with-venv-advice-add':

;; (with-venv-advice-add 'blacken-buffer)

;; Adviced functions are always wrapped with `with-venv' macro when called.

;; To remove these advices, you can use `with-venv-advice-remove'.

;;; Code:

(require 'cl-lib)
(require 'nadvice)

(defvar-local with-venv-venv-dir
  nil
  "Venv directory path.

This variable is intended to be explicitly set by user.
When nil, `with-venv' tries to find suitable venv dir.
When this variable is set , use this value without checking if it is a valid
python environment.")

;;;###autoload
(defmacro with-venv-dir (dir &rest body)
  "Set python environment to DIR and execute BODY.

This macro does not check if DIR is a valid python environemnt.
If dir is nil, execute BODY as usual."
  (declare (indent 1) (debug t))
  `(let ((--with-venv-process-environment-orig (cl-copy-list process-environment))
         (--with-venv-exec-path-orig (cl-copy-list exec-path)))
     (unwind-protect
         (progn
           (when ,dir
             (let* ((dir (file-name-as-directory ,dir))
                    (bin (expand-file-name "bin" dir)))
               ;; Do the same thing that bin/activate does
               (setq exec-path
                     (cons bin
                           exec-path))
               (setenv "VIRTUAL_ENV" dir)
               (setenv "PATH" (concat bin ":" (or (getenv "PATH") "")))
               (setenv "PYTHONHOME")))
           ,@body)
       (setq process-environment
             --with-venv-process-environment-orig)
       (setq exec-path
             --with-venv-exec-path-orig))))


(defvar-local with-venv-previously-used nil
  "Previously used venv dir path.")

;;;###autoload
(defmacro with-venv (&rest body)
  "Execute BODY with venv enabled.

This function tries to find suitable venv dir, or run BODY as usual when no
suitable environment was found."
  (declare (indent 0) (debug t))
  `(with-venv-dir
       ;; If set explicitly use it
       (or with-venv-venv-dir
           ;; Check previously used directory
           (with-venv-check-exists with-venv-previously-used)
           (setq with-venv-previously-used (with-venv-find-venv-dir)))
     ,@body))

(defun with-venv-find-venv-dir (&optional dir)
  "Try to find venv dir for DIR.
If none found return nil."
  (with-temp-buffer
    (when dir
      (cd dir))
    (or
     ;; Check pipenv
     (with-venv-check-exists (with-venv--find-venv-dir-pipenv))
     ;; Check poetry
     (with-venv-check-exists (with-venv--find-venv-dir-poetry))
     ;; Search for .venv dir
     (with-venv-check-exists (with-venv--find-venv-dir-by-name)))))

(defun with-venv--find-venv-dir-pipenv ()
  "Try to find venv dir via pipenv."
  (with-temp-buffer
    (let ((status (call-process "pipenv" nil t nil "--venv")))
      (when (eq status 0)
        (goto-char (point-min))
        (buffer-substring-no-properties (point-at-bol)
                                        (point-at-eol))))))

(defun with-venv--find-venv-dir-poetry ()
  "Try to find venv dir via poetry."
  (with-temp-buffer
    ;; TODO: Use poetry env info --path
    (let ((status (call-process "poetry" nil t nil "debug:info")))
      (when (eq status 0)
        (goto-char (point-min))
        (save-match-data
          (when (re-search-forward "^ \\* Path: *\\(.*\\)$")
            (match-string 1)))))))

(defun with-venv--find-venv-dir-by-name ()
  "Try to find venv dir by its name."
  (let ((dir (locate-dominating-file default-directory
                                     ".venv")))
    (when dir
      ;; TODO: check with -check-exists
      (expand-file-name ".venv"
                        dir))))

(defun with-venv-check-exists (dir)
  "Return DIR as is if \"bin\" directory was found under DIR."
  (and dir
       (file-directory-p (expand-file-name "bin"
                                           dir))
       dir))

;;;###autoload
(defun with-venv-advice-add (func)
  "Setup advice so that FUNC use `with-env' macro when executing."
  (advice-add func
              :around
              'with-venv--advice-around))

;;;###autoload
(defun with-venv-advice-remove (func)
  "Remove advice FUNC added by `with-venv-advice-add'."
  (advice-remove func
                 'with-venv--advice-around))

(defun with-venv--advice-around (orig-func &rest args)
  "Function to be used to advice functions with `with-venv-advice-add'.
When a function is adviced with this function, it is wrapped with `with-venv'.

ORIG-FUNC is the target function, and ARGS is the argument when it was called."
  (with-venv
    (apply orig-func args)))

(provide 'with-venv)

;;; with-venv.el ends here
