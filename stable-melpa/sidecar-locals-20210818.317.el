;;; sidecar-locals.el --- A flexible alternative built-in dir-locals -*- lexical-binding: t -*-

;; Copyright (C) 2021  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-sidecar-locals
;; Package-Version: 20210818.317
;; Package-Commit: 2047fba485d1c4bc2fca7fad96f57b0f13872323
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Side Car Locals supports out-of-source locals,
;; in a way that makes it easy to manage locals for a project
;; without having to keep track of files inside your project,
;; which may not be in version control.
;; This means your local code can be conveniently versioned separately.
;;
;; Besides this, there are some other differences with the built-in `dir-locals'.
;;
;; - Trust is managed by paths with
;;   `sidecar-locals-paths-allow' and `sidecar-locals-paths-deny'.
;; - The files are evaluated instead of looking up individual variables.
;; - It's up to the scripts to set local variables e.g. `setq-local',
;;   and avoid changes to the global state in a way that might cause unexpected behavior.
;;

;;; Usage

;;
;; Write the following code to your .emacs file:
;;
;;   (require 'sidecar-locals)
;;   (sidecar-locals-mode)
;;   (setq sidecar-locals-paths-allow '("/my/trusted/path/" "/other/path/*"))
;;
;; Or with `use-package':
;;
;;   (use-package sidecar-locals
;;     :config
;;     (setq sidecar-locals-paths-allow '("/my/trusted/path/" "/other/path/*")))
;;   (sidecar-locals-mode)
;;

;;; Code:


;; ---------------------------------------------------------------------------
;; Require Dependencies

(require 'subr-x) ;; For `string-empty-p'.


;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup sidecar-locals nil
  "Flexible local settings with support for out-of-source configuration."
  :group 'convenience)

(defcustom sidecar-locals-paths-allow nil
  "List of trusted paths (must contain trailing slashes)."
  :type '(repeat string)
  :group 'sidecar-locals)

(defcustom sidecar-locals-paths-deny nil
  "List of untrusted paths (must contain trailing slashes)."
  :type '(repeat string)
  :group 'sidecar-locals)

(defcustom sidecar-locals-ignore-modes nil
  "List of major-modes where `sidecar-locals' won't be used."
  :type '(repeat symbol)
  :group 'sidecar-locals)

(defvar sidecar-locals-ignore-buffer nil
  "When non-nil, `sidecar-locals' won't be used for this buffer.
This variable can also be a predicate function, in which case
it'll be called with one parameter (the buffer in question), and
it should return non-nil to make Global `sidecar-locals' Mode not
check this buffer.")

(defcustom sidecar-locals-dir-name ".sidecar-locals"
  "The directory name to discover sidecar-locals in."
  :group 'sidecar-locals
  :type 'string)


;; ---------------------------------------------------------------------------
;; Internal Generic Utilities

(defun sidecar-locals--parent-dir-or-nil (dir)
  "Parent directory of DIR or nil."
  (when dir
    (let ((dir-orig dir))
      (when (and (setq dir (directory-file-name dir)) (setq dir (file-name-directory dir)))
        (unless (string-equal dir-orig dir)
          dir)))))

(defun sidecar-locals--parent-dir-or-nil-with-slash (dir)
  "Parent directory of DIR or nil."
  (when dir
    (let ((dir-orig dir))
      (when (and (setq dir (directory-file-name dir)) (setq dir (file-name-directory dir)))
        (unless (string-equal dir-orig dir)
          (file-name-as-directory dir))))))

(defun sidecar-locals--path-explode (dir)
  "Explodes directory DIR.

For example: '/a/b/c' explodes to ('/' 'a/' 'b/' 'c/')"
  (let ((paths (list)))
    (while dir
      (let ((parent (sidecar-locals--parent-dir-or-nil-with-slash dir)))
        (push
          (if parent
            (substring dir (length parent))
            dir)
          paths)
        (setq dir parent)))
    paths))

(defun sidecar-locals--all-major-modes-as-list (mode)
  "Return a list of major modes MODE is derived from, ending with MODE."
  (let ((mode-list (list)))
    (while mode
      (push mode mode-list)
      (setq mode (get mode 'derived-mode-parent)))
    mode-list))

(defun sidecar-locals--locate-dominating-files (path locate)
  "Return a list of paths, the parent of PATH containing LOCATE.
Start with the top-most path."
  (let ((path-list (list)))
    (while path
      (let ((test (locate-dominating-file path locate)))
        (cond
          (test
            (push test path-list)
            (setq path (sidecar-locals--parent-dir-or-nil test)))
          (t
            (setq path nil)))))
    path-list))


;; ---------------------------------------------------------------------------
;; Internal Implementation Functions

(defun sidecar-locals--trusted-p (dir)
  "Check if DIR should be trusted (including any of it's parent directories).

Returns: 1 to trust, -1 is untrusted, nil is untrusted and not configured."
  ;; When `dir' is "/a/b/c/", check in the following order:
  ;; - "/a/b/c/"
  ;; - "/a/b/c/*"
  ;; - "/a/b/*"
  ;; - "/a/*"
  ;; - "/*"
  (let
    (
      (result nil)
      (is-first t))
    (while (and dir (null result))
      (let
        (
          (dir-test
            (if is-first
              dir
              (concat dir "*"))))
        (cond
          ((member dir-test sidecar-locals-paths-deny)
            (setq result -1))
          ((member dir-test sidecar-locals-paths-allow)
            (setq result 1))
          (t
            (unless is-first
              (setq dir (sidecar-locals--parent-dir-or-nil-with-slash dir))))))
      (setq is-first nil))
    result))

(defun sidecar-locals--trusted-p-with-warning (dir)
  "Check if DIR should be trusted, warn if it's not configured."
  (let ((trust (sidecar-locals--trusted-p dir)))
    (cond
      ((eq trust 1)
        t)
      ((eq trust -1)
        nil)
      (t
        (progn
          (message
            (concat
              "sidecar-locals: un-trusted path %S, "
              "add to `sidecar-locals-paths-allow' or `sidecar-locals-paths-deny' "
              "to determine the trust setting silence this message.")
            dir)
          nil)))))

(defun sidecar-locals--apply (cwd mode-base fn no-test)
  "Run FN on all files in `.sidecar-locals' in CWD.

Argument MODE-BASE is typically the current major mode.
This mode and any modes it derives from are scanned.

Order is least to most specific, so the files closest to the root run first,
and non `major-mode' files run first,
with functions closest to the files & mode specific.

When NO-TEST is non-nil checking for existing paths is disabled."
  (let*
    ( ;; Collect all trusted paths containing `sidecar-locals-dir-name'.
      (dominating-files
        (delete nil
          (mapcar
            (lambda (dir-base)
              (if (sidecar-locals--trusted-p-with-warning dir-base)
                (file-name-as-directory dir-base)
                nil))
            (sidecar-locals--locate-dominating-files cwd sidecar-locals-dir-name))))

      ;; Only create this list if there are known directories to scan.
      (major-mode-list
        (if dominating-files
          (sidecar-locals--all-major-modes-as-list mode-base)
          nil)))

    ;; Support multiple `sidecar-locals' parent paths.
    (dolist (dir-base dominating-files)
      (let*
        (
          (dir-root (concat dir-base (file-name-as-directory sidecar-locals-dir-name)))
          (dir-iter dir-root)
          (dir-tail-list (sidecar-locals--path-explode (substring cwd (length dir-base)))))

        ;; Handle all directories as well as files next to the `sidecar-locals-dir-name'.
        ;; All modes.
        (let ((file-test (concat dir-root "().el")))
          (when (or no-test (file-exists-p file-test))
            (funcall fn file-test)))
        ;; Specific modes.
        (dolist (mode major-mode-list)
          (let ((file-test (concat dir-root "(" (symbol-name mode) ").el")))
            (when (or no-test (file-exists-p file-test))
              (funcall fn file-test))))

        ;; Happens if the filename is in the same directory as the `sidecar-locals-dir-name'.
        ;; Discard the empty string in this case.
        (when (and dir-tail-list (string-empty-p (car dir-tail-list)))
          (pop dir-tail-list))

        (while dir-tail-list
          ;; Slashes are ensured.
          (setq dir-iter (concat dir-iter (pop dir-tail-list)))

          (let ((dir-iter-no-slash (directory-file-name dir-iter)))
            ;; All modes.
            (let ((file-test (concat dir-iter-no-slash "().el")))
              (when (or no-test (file-exists-p file-test))
                (funcall fn file-test)))
            ;; Specific modes.
            (dolist (mode major-mode-list)
              (let ((file-test (concat dir-iter-no-slash "(" (symbol-name mode) ").el")))
                (when (or no-test (file-exists-p file-test))
                  (funcall fn file-test)))))

          (unless (or no-test (file-exists-p dir-iter))
            ;; Exit loop.
            ;; There is no need to continue past a missing directory,
            ;; as all it's subdirectories will be missing too.
            (setq dir-tail-list nil)))))))

(defun sidecar-locals-hook ()
  "Load `sidecar-locals' files hook."
  (when (sidecar-locals-predicate)
    (sidecar-locals--apply
      (file-name-directory (buffer-file-name)) major-mode
      #'
      (lambda (filepath)
        ;; Errors here cause the file not to open,
        ;; report them as messages instead.
        (condition-case-unless-debug err
          (load filepath :nomessage t)
          (error (message "sidecar-locals: error %S in %S" err filepath))))
      ;; Only run for files that exist.
      nil)))

(defun sidecar-locals-predicate ()
  "Check if `sidecar-locals' should run."
  (and
    ;; Not in the mini-buffer.
    (not (minibufferp))
    ;; Not a special mode (package list, tabulated data ... etc)
    ;; Instead the buffer is likely derived from `text-mode' or `prog-mode'.
    (not (derived-mode-p 'special-mode))
    ;; Not explicitly ignored.
    (not (memq major-mode sidecar-locals-ignore-modes))
    ;; Optionally check if a function is used.
    (or
      (null sidecar-locals-ignore-buffer)
      (if (functionp sidecar-locals-ignore-buffer)
        (not (funcall sidecar-locals-ignore-buffer (current-buffer)))
        nil))))


;; ---------------------------------------------------------------------------
;; Public Functions

;;;###autoload
(defun sidecar-locals-report ()
  "Report the paths that are used to detect locals."
  (interactive)
  (message "Finding candidates for locals files:")
  (sidecar-locals--apply
    (file-name-directory (buffer-file-name)) major-mode
    #'
    (lambda (filepath)
      (message
        "- %S%s" filepath
        (if (file-exists-p filepath)
          " found"
          "")))
    ;; Run for all files & directories (even if they don't exist).
    t))


;; ---------------------------------------------------------------------------
;; Define Minor Mode
;;
;; Developer note, use global hooks since these run before buffers are loaded.
;; Each function checks if the local mode is active before operating.


(defun sidecar-locals-mode-enable ()
  "Turn on option `sidecar-locals-mode' for the current buffer."

  (add-hook 'after-set-visited-file-name-hook #'sidecar-locals-hook nil nil)
  (add-hook 'find-file-hook #'sidecar-locals-hook nil nil))

(defun sidecar-locals-mode-disable ()
  "Turn off option `sidecar-locals-mode' for the current buffer."
  (remove-hook 'after-set-visited-file-name-hook #'sidecar-locals-hook nil)
  (remove-hook 'find-file-hook #'sidecar-locals-hook nil))

;;;###autoload
(define-minor-mode sidecar-locals-mode
  "Toggle variable `sidecar-locals-mode' in the current buffer."
  :group 'sidecar-locals
  :global t

  (cond
    (sidecar-locals-mode
      (sidecar-locals-mode-enable))
    (t
      (sidecar-locals-mode-disable))))

(provide 'sidecar-locals)
;;; sidecar-locals.el ends here
