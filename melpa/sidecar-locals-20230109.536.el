;;; sidecar-locals.el --- A flexible alternative to built-in dir-locals -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-2.0-or-later
;; Copyright (C) 2021  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.org/ideasman42/emacs-sidecar-locals
;; Package-Version: 20230109.536
;; Package-Commit: 882923811e9de84c8ebc2f9fe65e9673d7d1f469
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))

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
;; Custom Variables

(defgroup sidecar-locals nil
  "Flexible local settings with support for out-of-source configuration."
  :group 'convenience)

(defcustom sidecar-locals-paths-allow nil
  "List of trusted paths (must contain trailing slashes)."
  :type '(repeat string))

(defcustom sidecar-locals-paths-deny nil
  "List of untrusted paths (must contain trailing slashes)."
  :type '(repeat string))

(defcustom sidecar-locals-ignore-modes nil
  "List of major-modes where `sidecar-locals' won't be used."
  :type '(repeat symbol))

(defvar sidecar-locals-ignore-buffer nil
  "When non-nil, `sidecar-locals' won't be used for this buffer.
This variable can also be a predicate function, in which case
it'll be called with one parameter (the buffer in question), and
it should return non-nil to make Global `sidecar-locals' Mode not
check this buffer.")

(defcustom sidecar-locals-dir-name ".sidecar-locals"
  "The directory name to discover sidecar-locals in."

  :type 'string)


;; ---------------------------------------------------------------------------
;; Internal Variables

;; Store the paths that were last checked, this way - setting new paths will be
;; checked and there is no need to validate paths every time `sidecar-locals' runs.
;; When non-nil this is a `cons' cell storing paths-allow & paths-deny.
(defvar sidecar-locals--last-checked-paths nil)


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

For example: \"/a/b/c\" explodes to (\"/\" \"a/\" \"b/\" \"c/\")"
  (let ((paths (list)))
    (while dir
      (let ((parent (sidecar-locals--parent-dir-or-nil-with-slash dir)))
        (push (cond
               (parent
                (substring dir (length parent)))
               (t
                dir))
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

(defun sidecar-locals--locate-dominating-file-simple (path name)
  "A simple version of `locate-dominating-file', find NAME in PATH.
PATH must be an expanded directory as it is not interpreted."
  ;; Ensure trailing slash.
  (setq path (file-name-as-directory path))
  (let ((result nil))
    (while path
      (let ((path-test (concat path name)))
        (cond
         ((file-exists-p path-test)
          (setq result path)
          (setq path nil))
         (t
          (setq path (sidecar-locals--parent-dir-or-nil-with-slash path))))))
    result))

(defun sidecar-locals--locate-dominating-files (path locate)
  "Return a list of paths, the parent of PATH containing LOCATE.
Start with the top-most path."
  (let ((path-list (list)))
    (while path
      (let ((test (sidecar-locals--locate-dominating-file-simple path locate)))
        (cond
         (test
          (push test path-list)
          (setq path (sidecar-locals--parent-dir-or-nil test)))
         (t
          (setq path nil)))))
    path-list))

(defun sidecar-locals--canonicalize-path (path)
  "Return the canonical PATH.

This is done without adjusting trailing slashes or following links."
  ;; Some pre-processing on `path' since it may contain the user path
  ;; or be relative to the default directory.
  ;;
  ;; Notes:
  ;; - This is loosely based on `f-same?'` from the `f' library.
  ;;   However it's important this only runs on the user directory and NOT trusted directories
  ;;   since there should never be any ambiguity (which could be caused by expansion)
  ;;   regarding which path is trusted.
  ;; - Avoid `file-truename' since this follows symbolic-links,
  ;;   `expand-file-name' handles `~` and removing `/../' from paths.
  (let ((file-name-handler-alist nil))
    ;; Expand user `~' and default directory.
    (expand-file-name path)))

(defun sidecar-locals--safe-expand-file-name (path)
  "Run a restricted `expand-file-name' on PATH."
  (when (not (string-empty-p path))
    (let ((ch (aref path 0)))
      ;; Currently only expand `~`.
      (cond
       ((eq ch ?~)
        (when (string-prefix-p (file-name-as-directory "~") path)
          (setq path (concat (expand-file-name "~") (substring path 1))))))))
  path)


;; ---------------------------------------------------------------------------
;; Internal Implementation Functions

(defun sidecar-locals--trusted-p (dir path-trust)
  "Check if DIR should be trusted, this includes any of it's parent directories.
PATH-TRUST is cons cell: (paths-deny . paths-allow)
derived from `sidecar-locals-paths-deny' & `sidecar-locals-paths-allow'.

Returns: 1 to trust, -1 is untrusted, nil is untrusted and not configured."
  ;; When `dir' is "/a/b/c/", check in the following order:
  ;; - "/a/b/c/"
  ;; - "/a/b/c/*"
  ;; - "/a/b/*"
  ;; - "/a/*"
  ;; - "/*"

  ;; Note that `dir' should be derived from a path that has been processed using
  ;; `sidecar-locals--canonicalize-path' to ensure the comparisons are valid.
  (let ((result nil)
        (is-first t)
        (paths-deny (car path-trust))
        (paths-allow (cdr path-trust)))
    (while (and dir (null result))
      (let ((dir-test
             (cond
              (is-first
               dir)
              (t
               (concat dir "*")))))
        (cond
         ((member dir-test paths-deny)
          (setq result -1))
         ((member dir-test paths-allow)
          (setq result 1))
         (t
          (unless is-first
            (setq dir (sidecar-locals--parent-dir-or-nil-with-slash dir))))))
      (setq is-first nil))
    result))

(defun sidecar-locals--trusted-p-with-warning (dir path-trust)
  "Check if DIR should be trusted by PATH-TRUST, warn if it's not configured."
  (let ((trust (sidecar-locals--trusted-p dir path-trust)))
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
          "add to `sidecar-locals-paths-allow' or `sidecar-locals-paths-deny' to silence this message.")
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

  ;; Ensure comparisons with `sidecar-locals--trusted-p' occur on an expanded path.
  (setq cwd (sidecar-locals--canonicalize-path cwd))

  (let* ((path-trust
          ;; Expand user paths (safely).
          (cons
           (mapcar #'sidecar-locals--safe-expand-file-name sidecar-locals-paths-deny)
           (mapcar #'sidecar-locals--safe-expand-file-name sidecar-locals-paths-allow)))

         ;; Collect all trusted paths containing `sidecar-locals-dir-name'.
         (dominating-files
          (delete
           nil
           (mapcar
            (lambda (dir-base)
              (cond
               ((or no-test (sidecar-locals--trusted-p-with-warning dir-base path-trust))
                (file-name-as-directory dir-base))
               (t
                nil)))
            (sidecar-locals--locate-dominating-files cwd sidecar-locals-dir-name))))

         ;; Only create this list if there are known directories to scan.
         (major-mode-list
          (cond
           (dominating-files
            (sidecar-locals--all-major-modes-as-list mode-base))
           (t
            nil))))

    ;; Support multiple `sidecar-locals' parent paths.
    (dolist (dir-base dominating-files)
      (let* ((dir-root (concat dir-base (file-name-as-directory sidecar-locals-dir-name)))
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
        (when (and dir-tail-list (string-equal "" (car dir-tail-list)))
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
   (or (null sidecar-locals-ignore-buffer)
       (cond
        ((functionp sidecar-locals-ignore-buffer)
         (not (funcall sidecar-locals-ignore-buffer (current-buffer))))
        (t
         nil)))))

(defun sidecar-locals--apply-all-for-directory (buffer-directory)
  "Apply sidecar-locals for BUFFER-DIRECTORY."
  ;; There is no ideal place to call this function,
  ;; so ensure the user is informed of bad settings once.
  (sidecar-locals--report-malformed-paths-once)

  (sidecar-locals--apply
   buffer-directory major-mode
   (lambda (filepath)
     ;; Errors here cause the file not to open,
     ;; report them as messages instead.
     (condition-case-unless-debug err
         (load filepath :nomessage t)
       (error (message "sidecar-locals: error %s in %S" (error-message-string err) filepath))))
   ;; Only run for files that exist.
   nil))

(defun sidecar-locals-hook ()
  "Load `sidecar-locals' files hook."
  (when (sidecar-locals-predicate)
    (sidecar-locals--apply-all-for-directory (file-name-directory (buffer-file-name)))))

;; For non-file buffers to run sidecar-locals, as is done for dir-locals.
;; There is no hook for this case, piggyback on dir-locals.
;;
;; Needed DIRED to run sidecar-locals when changing directories, see #8.
(defun sidecar-locals--dir-locals-for-non-file-buffers-advice ()
  "Load `sidecar-locals', advice for dir-locals (non-file buffer hack)."
  (when (sidecar-locals-predicate)
    ;; By convention, the default directory is expected to be used in this case.
    (sidecar-locals--apply-all-for-directory default-directory)))


;; ---------------------------------------------------------------------------
;; Internal Path Validation

(defun sidecar-locals--report-malformed-paths ()
  "Report problems path settings."
  (let ((has-error nil))
    (dolist (var (list 'sidecar-locals-paths-allow 'sidecar-locals-paths-deny))
      (dolist (path (symbol-value var))
        (let ((path-no-star (string-remove-suffix "*" path)))
          (let ((path-no-star-as-dir (file-name-as-directory path-no-star)))
            (unless (string-equal path-no-star path-no-star-as-dir)
              (message "sidecar-locals: %s path must end with a slash (and optional \"*\"): %S"
                       (symbol-name var)
                       path)
              (setq has-error t))))))
    has-error))

(defun sidecar-locals--report-malformed-paths-once ()
  "Report problems path settings (only once)."
  ;; NOTE: this is not a perfect solution, a developer could manipulate paths
  ;; without changing the start of the list, so it's not fool-proof.
  ;; Just a hint to users who have invalid configuration.
  (pcase-let ((`(,prev-paths-allow . ,prev-paths-deny) sidecar-locals--last-checked-paths))
    (unless (and (eq prev-paths-allow sidecar-locals-paths-allow)
                 (eq prev-paths-deny sidecar-locals-paths-deny))
      (unless (sidecar-locals--report-malformed-paths)
        ;; When there are no errors - don't check again unless the paths change.
        ;; Otherwise report whenever a new file is opened (so the user doesn't miss the warning).
        (setq sidecar-locals--last-checked-paths
              (cons sidecar-locals-paths-allow sidecar-locals-paths-deny))))))


;; ---------------------------------------------------------------------------
;; Internal Report Buffer

(defun sidecar-locals--buffer-insert-filepath (filepath map)
  "Insert FILEPATH as a clickable link using key-map MAP in a buffer."
  (let ((found (file-exists-p filepath)))
    (insert
     (propertize filepath
                 'face
                 (cond
                  (found
                   'success)
                  (t
                   'default))
                 'mouse-face
                 'highlight
                 'help-echo
                 "click to visit this file in other window"
                 'keymap
                 map
                 'loc
                 filepath))

    (when found
      (insert (propertize " [found]" 'face 'success)))

    (insert "\n")))


(defun sidecar-locals--buffer-report-impl ()
  "Implementation of `sidecar-locals-report'."
  (let* ((buf (get-buffer-create "*sidecar-locals-report*"))
         (filepath (buffer-file-name))
         (directory
          (cond
           (filepath
            (file-name-directory filepath))
           (t
            default-directory)))
         (map (make-sparse-keymap))

         ;; Called when a file-path is clicked (access the click from EVENT).
         (buffer-find-file-on-click-fn
          (lambda (event)
            (interactive "e")
            (let* ((pos (posn-point (event-end event)))
                   (loc (get-text-property pos 'loc)))
              (find-file loc)))))

    (define-key map [mouse-2] buffer-find-file-on-click-fn)
    (define-key map [mouse-1] buffer-find-file-on-click-fn)

    (with-current-buffer buf
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert (propertize "Sidecar locals applicable to:" 'face 'font-lock-doc-face) "\n")
      (insert (or filepath directory) "\n\n")
      (insert (propertize "Click to edit, q to quit:\n" 'face 'font-lock-doc-face)))

    (sidecar-locals--apply
     directory major-mode
     (lambda (filepath)
       (with-current-buffer buf
         (sidecar-locals--buffer-insert-filepath filepath map)))
     t)
    (pop-to-buffer buf)
    (view-mode-enter nil (lambda (buf) (kill-buffer buf)))))


;; ---------------------------------------------------------------------------
;; Public Functions

;;;###autoload
(defun sidecar-locals-report ()
  "Report paths that are used to detect locals.

This creates a buffer with links that visit that file."
  (interactive)
  (sidecar-locals--buffer-report-impl))

;; ---------------------------------------------------------------------------
;; Define Minor Mode
;;
;; Developer note, use global hooks since these run before buffers are loaded.
;; Each function checks if the local mode is active before operating.

(defun sidecar-locals--mode-enable ()
  "Turn on option `sidecar-locals-mode' globally."
  (setq sidecar-locals--last-checked-paths nil)
  (add-hook 'after-set-visited-file-name-hook #'sidecar-locals-hook nil nil)
  (add-hook 'find-file-hook #'sidecar-locals-hook nil nil)

  (advice-add
   'hack-dir-local-variables-non-file-buffer
   :after #'sidecar-locals--dir-locals-for-non-file-buffers-advice))

(defun sidecar-locals--mode-disable ()
  "Turn off option `sidecar-locals-mode' globally."
  (setq sidecar-locals--last-checked-paths nil)
  (remove-hook 'after-set-visited-file-name-hook #'sidecar-locals-hook nil)
  (remove-hook 'find-file-hook #'sidecar-locals-hook nil)

  (advice-remove
   'hack-dir-local-variables-non-file-buffer
   #'sidecar-locals--dir-locals-for-non-file-buffers-advice))

;;;###autoload
(define-minor-mode sidecar-locals-mode
  "Toggle variable `sidecar-locals-mode' globally."
  :global t

  (cond
   (sidecar-locals-mode
    (sidecar-locals--mode-enable))
   (t
    (sidecar-locals--mode-disable))))

(provide 'sidecar-locals)
;; Local Variables:
;; fill-column: 99
;; indent-tabs-mode: nil
;; End:
;;; sidecar-locals.el ends here
