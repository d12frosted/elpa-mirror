;;; counsel-at-point.el --- Context sensitive project search -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-2.0-or-later
;; Copyright (C) 2021  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.org/ideasman42/emacs-counsel-at-point
;; Package-Version: 20230113.1015
;; Package-Commit: f80f6b23d2184fec14af14198a8621a609a474bf
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "26.2") (counsel "0.13.0"))

;;; Commentary:

;; Perform project wide search using the current context.
;;

;;; Usage

;;
;; Write the following code to your .emacs file:
;;
;;   (require 'counsel-at-point)
;;
;; Or with `use-package':
;;
;;   (use-package counsel-at-point)
;;

;;; Code:

(require 'counsel)

(eval-when-compile
  ;; For `pcase-dolist'.
  (require 'pcase))

;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup counsel-at-point nil
  "Context sensitive commands for counsel."
  :group 'convenience)

(defcustom counsel-at-point-project-root 'counsel-at-point-project-root-default
  "Function to call that returns the root path of the current buffer.
A nil return value will fall back to the `default-directory'."
  :type 'function)

(defcustom counsel-at-point-thing-at-point 'symbol-at-point
  "Function that returns the text at the point (defaults to `symbol-at-point')."
  :type 'function)


;; ---------------------------------------------------------------------------
;; Generic Functions/Macros

(defmacro counsel-at-point--with-advice (fn-orig where fn-advice &rest body)
  "Execute BODY with WHERE advice on FN-ORIG temporarily enabled."
  (declare (indent 3))
  `(let ((fn-advice-var ,fn-advice))
     (unwind-protect
         (progn
           (advice-add ,fn-orig ,where fn-advice-var)
           ,@body)
       (advice-remove ,fn-orig fn-advice-var))))

(defun counsel-at-point--combine-plists (&rest plists)
  "Create a single property list from all plists in PLISTS.
The process starts by copying the first list, and then setting properties
from the other lists.  Settings in the last list are the most significant
ones and overrule settings in the other lists."
  (let ((result (copy-sequence (pop plists))))
    (while plists
      (let ((ls (pop plists)))
        (while ls
          (let ((p (pop ls)))
            (setq result (plist-put result p (pop ls)))))))
    result))

(defmacro counsel-at-point--ivy-read-with-extra-plist-args (extra-plist-args &rest body)
  "Wrapper for `ivy-read' that call BODY with EXTRA-PLIST-ARGS."
  (declare (indent 1))
  `(counsel-at-point--with-advice #'ivy-read :around
                                  (lambda (fn-orig &rest args)
                                    (apply fn-orig
                                           (counsel-at-point--combine-plists
                                            args
                                            ,extra-plist-args)))
     ,@body))


;; ---------------------------------------------------------------------------
;; Internal Functions/Macros

(defun counsel-at-point-project-root-default ()
  "Function to find the project root from the current buffer.
This checks `ffip', `projectile' & `vc' root,
using `default-directory' as a fallback."
  (cond
   ((fboundp 'ffip-project-root)
    (funcall #'ffip-project-root))
   ((fboundp 'projectile-project-root)
    (funcall #'projectile-project-root))
   (t
    (or (when buffer-file-name
          (let ((vc-backend
                 (ignore-errors
                   (vc-responsible-backend buffer-file-name))))
            (when vc-backend
              (vc-call-backend vc-backend 'root buffer-file-name))))))))

(defun counsel-at-point--thing-at-point-impl ()
  "Return the value for `counsel-at-point-thing-at-point' callback."
  (let ((val (funcall counsel-at-point-thing-at-point)))
    (cond
     ((null val)
      "")
     ((symbolp val)
      (symbol-name val))
     (t
      (set-text-properties 0 (length val) nil val)
      val))))


;; ---------------------------------------------------------------------------
;; Counsel Wrapper Implementations

(defun counsel-at-point--project-search-impl (backend)
  "Wrap various counsel grep commands (see BACKEND)."
  (let ((initial-search-text
         (regexp-quote
          (or (cond
               ((region-active-p)
                (prog1 (buffer-substring-no-properties (region-beginning) (region-end))
                  ;; Keeping the selection active causes problems
                  ;; if results in the current buffer are jumped to.
                  ;; NOTE: avoid hard avoid hard dependencies on evil-mode.
                  (when (fboundp 'evil-exit-visual-state)
                    (funcall #'evil-exit-visual-state))))
               (t ; Will be nil when over white-space (which is fine).
                (counsel-at-point--thing-at-point-impl)))
              ;; Fail-safe in case the `thing-at-point' function returns nil.
              "")))

        (base-path (or (funcall counsel-at-point-project-root) default-directory))
        (preselect-text nil)
        ;; Don't use (point-min) as there is never a reason to respect narrowing.
        (line-number (count-lines 1 (point))))

    (when (and base-path buffer-file-name)
      ;; Use regex so there is no need to include the contents of the line
      ;; (for an exact match). While this probably works OK for the most-part,
      ;; it could be susceptible to minor differences in encoding when reading
      ;; the output back from the sub-process.
      (setq preselect-text
            (concat
             ;; Match the string start.
             "\\`"
             ;; Quote the path name & line number.
             (regexp-quote
              (pcase backend
                ('grep (format "%d:" line-number))
                (_
                 (format "%s:%d:"
                         (file-relative-name buffer-file-name base-path)
                         line-number)))))))

    (counsel-at-point--ivy-read-with-extra-plist-args (list :preselect preselect-text)
      (pcase backend
        ('rg (counsel-rg initial-search-text base-path))
        ('ag (counsel-ag initial-search-text base-path))
        ('git-grep (counsel-git-grep initial-search-text base-path))
        ;; Ignores base-path.
        ('grep (counsel-grep initial-search-text))
        (_ (error "Unknown back-end: %s" backend))))))

(defun counsel-at-point--find-file-impl (backend)
  "Wrap various counsel grep commands (see BACKEND)."
  (let ((counsel-preselect-current-file t)
        (base-path (or (funcall counsel-at-point-project-root) default-directory)))
    ;; Without this the order from 'find' is not useful (unordered?).
    (pcase backend
      ('file-jump (counsel-file-jump nil base-path))
      ('find-file (counsel-find-file nil base-path))
      (_ (error "Unknown back-end: %s" backend)))))

(defun counsel-at-point--find-file-with-preselect-impl (backend)
  "Wrap various counsel grep commands (see BACKEND)."
  (let ((base-path (or (funcall counsel-at-point-project-root) default-directory))
        (preselect-text nil))
    (when (and base-path buffer-file-name)
      (setq preselect-text (file-relative-name buffer-file-name base-path)))

    (counsel-at-point--ivy-read-with-extra-plist-args (list :preselect preselect-text)
      (pcase backend
        ('fzf (counsel-fzf nil base-path))
        (_ (error "Unknown back-end: %s" backend))))))

;; Note, by default counsel uses the `thing-at-point' (symbol),
;; however this is very often not part of the imenu, so - replace this
;; with the nearest item above the cursor.
(defun counsel-at-point--imenu-impl ()
  "Wrap `counsel-imenu'."
  (let ((eol (pos-eol)))
    (counsel-at-point--with-advice #'ivy-read :around
                                   (lambda (fn-orig &rest args)
                                     (let ((imenu-data (nth 1 args))
                                           (key-best nil)
                                           (val-best nil))

                                       (pcase-dolist (`(,key . (,_ . ,val)) imenu-data)
                                         (when (markerp val)
                                           (setq val (marker-position val)))
                                         ;; Get the closest point prior to the end of the line.
                                         ;; This avoids the problem when the imenu item but some
                                         ;; characters afterwards.
                                         (when (< val eol)
                                           (when (or (null val-best) (< val-best val))
                                             (setq key-best key)
                                             (setq val-best val))))

                                       (apply fn-orig
                                              (counsel-at-point--combine-plists
                                               args
                                               (list :preselect key-best)))))

      (counsel-imenu))))


;; ---------------------------------------------------------------------------
;; Public Functions

;; Grep Wrappers
;; =============

;;;###autoload
(defun counsel-at-point-rg ()
  "Context sensitive wrapper for `counsel-rg'."
  (interactive)
  (counsel-at-point--project-search-impl 'rg))

;;;###autoload
(defun counsel-at-point-ag ()
  "Context sensitive wrapper for `counsel-ag'."
  (interactive)
  (counsel-at-point--project-search-impl 'ag))

;;;###autoload
(defun counsel-at-point-git-grep ()
  "Context sensitive wrapper for `counsel-git-grep'."
  (interactive)
  (counsel-at-point--project-search-impl 'git-grep))

;;;###autoload
(defun counsel-at-point-grep ()
  "Context sensitive wrapper for `counsel-grep'."
  (interactive)
  (counsel-at-point--project-search-impl 'grep))

;; Find File Wrappers
;; ==================

;;;###autoload
(defun counsel-at-point-file-jump ()
  "Context sensitive wrapper for `counsel-file-jump'."
  (interactive)
  (counsel-at-point--find-file-impl 'file-jump))

;;;###autoload
(defun counsel-at-point-find-file ()
  "Context sensitive wrapper for `counsel-find-file'."
  (interactive)
  (counsel-at-point--find-file-impl 'find-file))

;;;###autoload
(defun counsel-at-point-fzf ()
  "Context sensitive wrapper for `counsel-find-file'."
  (interactive)
  (counsel-at-point--find-file-with-preselect-impl 'fzf))

;; Imenu Wrapper
;; =============

;;;###autoload
(defun counsel-at-point-imenu ()
  "Context sensitive wrapper for `counsel-imenu'."
  (interactive)
  (counsel-at-point--imenu-impl))

(provide 'counsel-at-point)
;; Local Variables:
;; fill-column: 99
;; indent-tabs-mode: nil
;; End:
;;; counsel-at-point.el ends here
