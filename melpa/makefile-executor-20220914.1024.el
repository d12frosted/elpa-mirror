;;; makefile-executor.el --- Commands for conveniently running makefile targets -*- lexical-binding: t -*-

;; Copyright (C) 2017 Lowe Thiderman

;; Author: Lowe Thiderman <lowe.thiderman@gmail.com>
;; URL: https://github.com/thiderman/makefile-executor.el
;; Package-Commit: b2dd81e4218ed1c19ae48da815be01a55c435417
;; Package-Version: 20220914.1024
;; Package-X-Original-Version: 20220906
;; Version: 0.2.0
;; Package-Requires: ((emacs "27.1") (dash "2.11.0") (f "0.11.0") (s "1.10.0"))
;; Keywords: processes

;; This file is not part of GNU Emacs.

;;; License:

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; A set of tools aimed at working with Makefiles on a project level.
;;
;; Currently available:
;; - Interactively selecting a make target and running it.
;;   Bound to 'C-c C-e' when 'makefile-executor-mode' is enabled.
;; - Re-running the last execution.  We usually run things in
;;   Makefiles many times after all!  Bound to '`C-c C-c'` in `makefile-mode` when
;;   'makefile-executor-mode'` is enabled.
;; - Running a makefile target in a dedicated buffer.  Useful when
;;   starting services and other long-running things!  Bound to
;;   '`C-c C-d'` in `makefile-mode` when 'makefile-executor-mode'` is enabled.
;; - Calculation of variables et.c.; $(BINARY) will show up as what it
;;   evaluates to.
;; - Via `project.el', execution from any buffer in a project.
;;   If more than one makefile is found, an interactive prompt for one is shown.
;;   If `projectile' is installed, this is added to the `projectile-commander' on the 'm' key.
;;
;; To enable it, use the following snippet to add the hook into 'makefile-mode':
;;
;; (add-hook 'makefile-mode-hook 'makefile-executor-mode)
;;
;;; Code:

(require 'compile)
(require 'dash)
(require 'f)
(require 'make-mode)
(require 's)
(require 'projectile nil t)
(require 'project)

(defvar makefile-executor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-e") 'makefile-executor-execute-target)
    (define-key map (kbd "C-c C-c") 'makefile-executor-execute-last)
    (define-key map (kbd "C-c C-d") 'makefile-executor-execute-dedicated-buffer)
    map)
  "Keymap for `makefile-executor-mode'.")

(define-minor-mode makefile-executor-mode
  "Turn `makefile-executor' mode on if ARG is positive, off otherwise.

Bindings in `makefile-mode':
\\{makefile-executor-mode-map}"
  :global nil
  :lighter " executor"
  :keymap makefile-executor-mode-map)

(defvar makefile-executor-special-target "emacs--makefile--list")

(setq makefile-executor-cache (make-hash-table :test 'equal))

(defgroup makefile-executor nil
  "Conveniently running Makefile targets."
  :group 'convenience
  :prefix "makefile-executor-")

(defcustom makefile-executor-projectile-style 'makefile-executor-execute-project-target
  "Decides what to do when executing from `projectile-commander'."
  :type '(choice
          (const :tag "Always choose target"
                 makefile-executor-execute-project-target)
          (const :tag "Run most recently executed target"
                 makefile-executor-execute-last)))

(defcustom makefile-executor-ignore "vendor/"
  "Regexp of paths that should be filtered when looking for Makefiles."
  :type 'string)

;; Based on http://stackoverflow.com/a/26339924/983746
(defvar makefile-executor-list-target-code
  (format
   ".PHONY: %s\n%s:\n	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ \"^[#.]\") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'\n"
   makefile-executor-special-target makefile-executor-special-target)
  "Target used to list all other Makefile targets.")

(defun makefile-executor-get-targets (filename)
  "Return a list of all the targets of a Makefile.

To list them in a computed manner, a new special target is added,
the buffer is written to a temporary Makefile which is executed
with the special target.

Optional argument FILENAME defaults to current buffer."
  (let* ((file (make-temp-file "makefile"))
         (makefile-contents
          (concat
           (with-temp-buffer
             (insert-file-contents filename)
             (buffer-string))
           "\n\n"
           makefile-executor-list-target-code)))

    (f-write-text makefile-contents 'utf-8 file)

    (let ((out (shell-command-to-string
                (format "make -f %s %s"
                        (shell-quote-argument file)
                        makefile-executor-special-target))))
      (delete-file file)
      (s-split "\n" out t))))

(defun makefile-executor-select-target (&optional filename)
  "Prompt the user for a Makefile target.

If there is only one, it is returned immediately."

  (let ((targets (makefile-executor-get-targets (or filename (buffer-file-name)))))
    (if (= (length targets) 1)
        (car targets)
      (completing-read "target: " targets))))

;;;###autoload
(defun makefile-executor-execute-target (filename &optional target)
  "Execute a Makefile target from FILENAME.

FILENAME defaults to current buffer."
  (interactive
   (list (file-truename buffer-file-name)))

  (let ((target (or target (makefile-executor-select-target filename))))
    (makefile-executor-store-cache filename target)
    (compile (format "make -f %s -C %s %s"
                     (shell-quote-argument filename)
                     (shell-quote-argument (file-name-directory filename))
                     target))))

(defun makefile-executor-store-cache (filename target)
  "Store the FILENAME and TARGET in the cache.

If you are in a project, this uses `project-root'. If
  not, it uses the current filename."
  (puthash (makefile-executor--project-root filename)
           (list filename target)
           makefile-executor-cache))

(defun makefile-executor-get-cache ()
  "Gets the cache for the current project or Makefile.

If you are in a project, this uses `project-root'. If
  not, just use the current filename."
  (gethash (makefile-executor--project-root (file-truename buffer-file-name))
           makefile-executor-cache))

(defun makefile-executor-makefile-p (f)
  (and (s-contains? "makefile" (s-downcase f))
       (not (string-match makefile-executor-ignore f))))

(defun makefile-executor-get-makefiles ()
  (-filter 'makefile-executor-makefile-p
           (project-files (project-current))))

(defun makefile-executor--project-root (&optional otherwise)
  (if (project-current)
      (project-root (project-current))
    otherwise))

;;;###autoload
(defun makefile-executor-execute-project-target ()
  "Choose a Makefile target from all of the Makefiles in the project.

If there are several Makefiles, a prompt to select one of them is shown.
If so, the parent directory of the closest Makefile is added
as initial input for convenience in executing the most relevant Makefile."
  (interactive)

  (let* ((files (makefile-executor-get-makefiles)))
    (when (= (length files) 0)
      (user-error "No makefiles found in this project"))

    (makefile-executor-execute-target
      ;; If there is just the one file, return that one immediately
      (if (= (length files) 1)
          (car files)
        ;; If there are more, do a completing read, and use the
        ;; closest makefile in the project as an initial input, if
        ;; possible.
        (completing-read "Makefile: " files nil t
                         (makefile-executor--initial-input)))))))


(defun makefile-executor--initial-input ()
  "Return the Makefile closest to the current buffer.

If none can be found, returns empty string."
  ;; Get the dominating file dir so we can use that as initial input
  ;; This means that if we are in a large project with a lot
  ;; of Makefiles, the closest one will be the initial suggestion.
  (let* ((bn (or (buffer-file-name) default-directory))
         (fn (or (locate-dominating-file bn "Makefile")
                 (locate-dominating-file bn "makefile")))
         (root (makefile-executor--project-root nil))
         (relpath (file-relative-name (or fn root) root)))
    ;; If we are at the root, we don't need the initial
    ;; input. If we have it as `./`, the Makefile at
    ;; the root will not be selectable, which is confusing. Hence, we
    ;; remove that
    (unless fn (user-error "No Makefiles found in project"))
    (if (not (s-equals? relpath "./"))
        relpath
      "")))

;;;###autoload
(defun makefile-executor-execute-dedicated-buffer (filename &optional target)
  "Runs a makefile target in a dedicated compile buffer.

The dedicated buffer will be named \"*<target>*\".  If
`projectile' is installed and the makefile is in a project the
project name will be prepended to the dedicated buffer name."

  (interactive (list
      (buffer-file-name)
      nil))
  (let* ((target (or target (makefile-executor-select-target filename)))
         (buffer-name
          (if (and (featurep 'projectile) (projectile-project-p))
              (format "*%s-%s*" (projectile-project-name) target)
            (format "*%s*" target))))

    (makefile-executor-execute-target filename target)
    (with-current-buffer (get-buffer "*compilation*")
      (rename-buffer buffer-name))))

;;;###autoload
(defun makefile-executor-execute-last (arg)
  "Execute the most recently executed Makefile target.

If none is set, prompt for it using
`makefile-executor-execute-project-target'.  If the universal
argument is given, always prompt."
  (interactive "P")

  (let ((targets (makefile-executor-get-cache)))
    (if (or arg (not targets))
        (if (project-current)
            (makefile-executor-execute-project-target)
          (makefile-executor-execute-target (buffer-file-name)))
      (makefile-executor-execute-target
       (car targets)
       (cadr targets)))))

;;;###autoload
(defun makefile-executor-goto-makefile ()
  "Interactively choose a Makefile to visit."
  (interactive)

  (let ((makefiles (makefile-executor-get-makefiles)))
    (find-file
             (if (= 1 (length makefiles))
                 (car makefiles)
               (completing-read "Makefile: " makefiles)))))

;; This is so that the library is useful even if one does not have
;; `projectile' installed.
(when (featurep 'projectile)
  (def-projectile-commander-method ?m
    "Execute makefile targets in project."
    (funcall makefile-executor-projectile-style)))

(provide 'makefile-executor)

;;; makefile-executor.el ends here
