;;; factlog.el --- File activity logger

;; Copyright (C) 2012 Takafumi Arakaki

;; Author: Takafumi Arakaki <aka.tkf at gmail.com>
;; Package-Requires: ((deferred "0.3.1"))
;; Package-Version: 20130210.140
;; Package-Commit: 6503d77ea882c995b051d22e72db336fb28770fc
;; Version: 0.0.1alpha0
;; URL: https://github.com/tkf/factlog

;; This file is NOT part of GNU Emacs.

;; factlog.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; factlog.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with factlog.el.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; You need Python program factlog [1] to use this package.
;; factlog can be installed easily by "pip install factlog".
;; If you are using factlog.el from Git repository, you don't
;; need to install factlog separately.

;; To use factlog.el, simply add the following in your configuration:
;;
;;   (require 'factlog)
;;   (factlog-mode)

;; You need helm.el or anything.el to access recently opened file list.
;;
;; * List recently opened files:
;;   `helm-factlog-list' / `anything-factlog-list'
;; * List recently opened notes and choose them by title:
;;   `helm-factlog-list-notes' / `anything-factlog-list-notes'

;; [1] https://github.com/tkf/factlog

;;; Code:

(eval-when-compile (require 'cl))
(require 'recentf)
(require 'deferred)

(defgroup factlog nil
  "File activity logger."
  :group 'convenience
  :prefix "factlog:")

(defvar factlog:lisp-dir (if load-file-name
                             (file-name-directory load-file-name)
                           default-directory))

(defvar factlog:source-dir (expand-file-name
                            ".."
                            (file-name-directory factlog:lisp-dir)))

(defvar factlog:cli-script
  (convert-standard-filename
   (expand-file-name "factlog_cli.py" factlog:source-dir))
  "Full path to FactLog CLI script.")

(defcustom factlog:command
  (if (executable-find "factlog")
      (list "factlog")
    (list "python" factlog:cli-script))
  "Command to run factlog CLI."
  :group 'factlog)

(defcustom factlog:program-name "emacs"
  "Name of the editor to record."
  :group 'factlog)

(defun factlog:call-process (args buffer)
  (let* ((command (append factlog:command args))
         (program (car command))
         (rest (cdr command)))
    (apply #'call-process program nil buffer nil rest)))

(defun factlog:deferred-process (&rest args)
  (apply #'deferred:process (append factlog:command args)))

(defun factlog:record-current-file (access-type)
  (when (and buffer-file-name (recentf-include-p buffer-file-name)) ; [1]_
    (factlog:deferred-process
     "record"
     "--file-point" (format "%s" (point))
     "--access-type" access-type
     "--program" factlog:program-name
     buffer-file-name)))
;; .. [1] (recentf-include-p nil) returns t.
;;        So, let's check if it is non-nil first.

(defun factlog:after-save-handler ()
  (factlog:record-current-file "write"))

(defun factlog:find-file-handler ()
  (factlog:record-current-file "open"))

(defun factlog:kill-buffer-handler ()
  (factlog:record-current-file "close"))

;;;###autoload
(define-minor-mode factlog-mode
  "FactLog mode -- file activity logger.

\\{factlog-mode-map}"
  ;; :keymap factlog-mode-map
  :global t
  :group 'factlog
  (if factlog-mode
      (progn
        (add-hook 'find-file-hook 'factlog:find-file-handler)
        (add-hook 'after-save-hook 'factlog:after-save-handler)
        (add-hook 'kill-buffer-hook 'factlog:kill-buffer-handler))
    (remove-hook 'find-file-hook 'factlog:find-file-handler)
    (remove-hook 'after-save-hook 'factlog:after-save-handler)
    (remove-hook 'kill-buffer-hook 'factlog:kill-buffer-handler)))


;;; Helm/anything compatibility

(defvar factlog:helm-compat-realvalue
  (if (locate-library "helm") 'helm-realvalue 'anything-realvalue))

(defun factlog:helm (&rest args)
  (let ((factlog:helm-compat-realvalue 'helm-realvalue))
    (apply 'helm args)))

(defun factlog:anything (&rest args)
  (let ((factlog:helm-compat-realvalue 'anything-realvalue))
    (apply 'anything args)))


;;; List recently opened files

(defcustom factlog:list-args nil
  "Arguments to be used when `helm-factlog-list' or
`anything-factlog-list' is called.  See ``factlog list --help``
for more information."
  :group 'factlog)

(defun factlog:list-call-process (buffer)
  (factlog:call-process (append '("list") factlog:list-args) buffer))

(defun factlog:list-make-source (helm)
  (let ((get-buffer (intern (format "%s-candidate-buffer" helm))))
    `((name . "factlog list")
      (candidates-in-buffer)
      (init . (lambda ()
                (factlog:list-call-process (,get-buffer 'global))))
      (type . file))))

(defvar helm-c-source-factlog-list (factlog:list-make-source 'helm))
(defvar anything-c-source-factlog-list (factlog:list-make-source 'anything))

;;;###autoload
(defun helm-factlog-list ()
  "List recently opened files.
This can be customized by `factlog:list-args'."
  (interactive)
  (factlog:helm :sources '(helm-c-source-factlog-list)
                :buffer "*helm factlog list*"))

;;;###autoload
(defun anything-factlog-list ()
  "List recently opened files.
See `helm-factlog-list' for more info."
  (interactive)
  (factlog:anything :sources '(anything-c-source-factlog-list)
                    :buffer "*anything factlog list*"))


;;; List recently opened notes

(defcustom factlog:list-notes-args nil
  "Arguments to be used when `helm-factlog-list-notes' or
`anything-factlog-list-notes' is called.  See ``factlog list --help``
for more information."
  :group 'factlog)

(defcustom factlog:list-notes-dirs nil
  "Full path to the directory where you keep notes.

Example::

    (setq factlog:list-notes-dirs '(\"~/howm\"))
"
  :group 'factlog)

(defun factlog:list-notes-get-args ()
  (append
   '("list" "--title")
   factlog:list-notes-args
   (loop for dir in factlog:list-notes-dirs
         collect "--under"
         collect (expand-file-name dir))))

(defun factlog:list-notes-call-process (buffer)
  (factlog:call-process (factlog:list-notes-get-args) buffer))

(defun factlog:list-notes-real-to-display (candidate)
  (if (string-match "^\\([^:]+\\):\\(.+\\)" candidate)
      (let ((file (match-string 1 candidate))
            (title (match-string 2 candidate)))
        (propertize title factlog:helm-compat-realvalue file))
    candidate))

(defun factlog:list-notes-make-source (helm)
  (let ((get-buffer (intern (format "%s-candidate-buffer" helm))))
    `((name . "factlog list notes")
      (candidates-in-buffer)
      (real-to-display . factlog:list-notes-real-to-display)
      (init . (lambda ()
                (factlog:list-notes-call-process (,get-buffer 'global))))
      (type . file))))

(defvar helm-c-source-factlog-list-notes
  (factlog:list-notes-make-source 'helm))
(defvar anything-c-source-factlog-list-notes
  (factlog:list-notes-make-source 'anything))

;;;###autoload
(defun helm-factlog-list-notes ()
  "List recently opened notes.
This can be customized by `factlog:list-notes-args' and
`factlog:list-notes-dirs'."
  (interactive)
  (factlog:helm :sources '(helm-c-source-factlog-list-notes)
                :buffer "*helm factlog list notes*"))

;;;###autoload
(defun anything-factlog-list-notes ()
  "List recently opened notes.
See `helm-factlog-list-notes' for more info."
  (interactive)
  (factlog:anything :sources '(anything-c-source-factlog-list-notes)
                    :buffer "*anything factlog list notes*"))

(provide 'factlog)

;;; factlog.el ends here
