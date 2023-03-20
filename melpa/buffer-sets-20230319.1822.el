;;; buffer-sets.el --- Sets of Buffers for Buffer Management -*- lexical-binding: t -*-

;; Copyright (C) 2016, 2022--2023 Samuel W. Flint

;; Author: Samuel W. Flint <swflint@flintfam.org>
;; Version: 3.7.4
;; Package-Version: 20230319.1822
;; Package-Commit: 951e894ef96d533324f7f24c2a0def45ae89d558
;; Package-Requires: ((cl-lib "0.5"))
;; Keywords: buffer-management
;; URL: https://git.sr.ht/~swflint/buffer-sets
;; SPDX-FileCopyrightText: 2016, 2022 Samuel W. Flint <swflint@flintfam.org>
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This library provides a way to manage sets of buffers/files separate
;; from existing project management systems.  Its goal is to make it easy
;; to load things that may not fit into the definition of a project, or
;; are small subsets of projects, etc.
;;
;;;; Installation
;;
;; Place `buffer-sets.el` somewhere on your load path and `(require
;; 'buffer-sets)`.  This package is also available on Melpa and may be
;; installed through `package.el`.
;;
;;;; Enabling Buffer Sets Mode
;;
;; `buffer-sets-mode` is a global minor mode which will load buffer set
;; definitions if necessary (see below), and ensure that buffer sets are
;; unloaded before Emacs is closed.  It also binds keys for buffer set
;; manipulation in `buffer-sets-mode-map`.
;;
;;;;; Key Bindings
;;
;; - `C-x L l` Load a buffer-set
;; - `C-x L L` List all buffer-sets
;; - `C-x L u` Unload a buffer-set
;; - `C-x L U` Unload *all* buffer sets
;; - `C-x L p` Unload most recently loaded buffer set
;; - `C-x L r` Reload a buffer set
;;
;;;; Configuration
;;
;;;;; Defining Buffer Sets
;;
;; Buffer sets are defined through the alist `buffer-sets`.  These are of
;; the form `(key . definition)`, where `key` is a string name, and
;; `definition` is an alist with the following keys: `:files`, `:select`,
;; `:on-apply` and `:on-remove`, which have the following semantics:
;;
;; - `:files` a list of files/directories to load
;; - `:select` the name of a buffer to select after loading the set
;; - `:on-apply` the name of a function to run after loading the set
;; - `:on-remove` the name of a function to run after loading the set
;;
;; This variable may be `customize`d, and configuration by this method is
;; recommended for new users.
;;
;;;;; Autoloading Buffer Sets
;;
;; Buffer sets may be autoloaded by setting `buffer-sets-start-sets` to a
;; list of buffer set names and running
;; `buffer-sets-install-emacs-start-hook`.  These will be loaded in the
;; order specified.
;;
;;;;; Load and Unload Hooks
;;
;; The hooks `buffer-sets-load-set-hook` and
;; `buffer-sets-unload-set-hook` are run after loading and unloading a
;; set (respectively).
;;
;;;;; Loading Buffer Set Definitions (and migration from old interface)
;;
;; New users of `buffer-sets` should use `customize` (see above).
;;
;; Past users of `buffer-sets` may instead configure `buffer-sets`
;; through an external file or a `setf` expression.  Note, that if you
;; used the old `define-buffer-set` interface, you may use
;; `buffer-sets-save` to automatically migrate to either `customize`
;; or to a setf expression in a file specified by
;; `buffer-sets-definitions-file`.  Which method of saving buffer set
;; definitions is used is controlled by the `buffer-sets-save-method`
;; variable.  If it is `:custom` the `customize` interface is used; if
;; `:file`, the file specified by `buffer-sets-definitions-file` is
;; written; if `nil` an error is signalled.



;;; Code:

(require 'cl-lib)


;;; Variables and structures

(defgroup buffer-sets ()
  "Load and unload sets of buffers with ease."
  :group 'applications
  :link '(url-link :tag "Homepage" "https://git.sr.ht/~swflint/buffer-sets")
  :link '(emacs-library-link :tag "Library Source" "buffer-sets.el")
  :prefix "buffer-sets-")

(defcustom buffer-sets nil
  "Description of buffer sets."
  :group 'buffer-sets
  :type '(alist :key-value (string :tag "Buffer Set Name")
                :value-type (alist
                             :options (((const :tag "Files" :files) (repeat (string :tag "File Name")))
                                       ((const :tag "Description" :description) string)
                                       ((const :tag "Select Buffer?" :select) (string :tag "Buffer Name"))
                                       ((const :tag "Run on apply" :on-apply) sexp)
                                       ((const :tag "Run on remove" :on-remove) sexp)))))

(defcustom buffer-sets-start-sets nil
  "List of buffer sets to load on start."
  :type '(repeat :tag "Buffer Sets:" (string :tag "Buffer Set Name:"))
  :group 'buffer-sets)

(make-obsolete-variable 'buffer-sets-load-on-start 'buffer-sets-start-sets "3.0")

(defcustom buffer-sets-load-set-hook nil
  "Hook to run after loading a buffer-set."
  :group 'buffer-sets
  :type 'hook)

(defcustom buffer-sets-unload-set-hook nil
  "Hook to run after unloading a buffer-set."
  :group 'buffer-sets
  :type 'hook)

(defcustom buffer-sets-definitions-file (locate-user-emacs-file "buffer-set-definitions.el")
  "Location of buffer-sets definitions file."
  :group 'buffer-sets
  :type 'hook)

(defcustom buffer-sets-save-method :custom
  "How should buffer-sets definitions be saved?

:custom (use customize, default)
:file (use `buffer-sets-definitions-file')
nil (don't save)"
  :type '(choice
          (const :tag "Customize" :custom)
          (const :tag "File" :file)
          (const :tag "Don't Save" nil))
  :group 'buffer-sets)

(defcustom buffer-sets-auto-save-p nil
  "Should buffer sets autosave?"
  :type 'boolean
  :group 'buffer-sets)

(defvar buffer-sets-loaded-sets nil
  "List of loaded buffer sets.")

(defvar buffer-sets-sets-to-buffers nil
  "Alist from buffer sets to buffers.")

(defvar buffer-sets-macro-used-p nil
  "Has the macro `define-buffer-set' been used?")


;; Utility functions

(defun buffer-sets-get-set (name)
  "Get the definition for buffer-set NAME."
  (cdr (assoc name buffer-sets #'string=)))

(defun buffer-sets-buffer-in-set-p (buffer-set buffer)
  "Is BUFFER in BUFFER-SET?"
  (when-let ((buffers (cl-rest (assoc buffer-set buffer-sets-sets-to-buffers #'string=))))
    (cl-member buffer buffers :test #'equal)))

(defun buffer-sets-associate-buffer-with-set (buffer-set buffer)
  "Associate BUFFER with BUFFER-SET."
  (let ((associated-sets (cdr (assoc buffer-set buffer-sets-sets-to-buffers #'string=)))
        (assoc-list-no-set (cl-remove-if #'(lambda (x) (string= (cl-first x) buffer-set))
                                         buffer-sets-sets-to-buffers)))
    (setf buffer-sets-sets-to-buffers (cons (cons buffer-set (cons buffer associated-sets))
                                            assoc-list-no-set))))

(defun buffer-sets-loaded-p (buffer-set)
  "Is BUFFER-SET loaded?"
  (member buffer-set buffer-sets-loaded-sets))

(defun buffer-sets-unloaded-buffer-sets ()
  "List all buffer sets which are not loaded."
  (cl-set-difference (mapcar #'car buffer-sets)
                     buffer-sets-loaded-sets
                     :test #'string=))


;; Completion

(defun buffer-sets-completion-annotate (completions)
  "Annotate COMPLETIONS with affixes.

No prefix is generated; however, if a description is provided,
that is used as a suffix."
  (let ((indent-to (+ 4 (apply #'max (mapcar #'length completions)))))
    (mapcar (lambda (completion)
              (if-let ((definition (buffer-sets-get-set completion))
                       (description (cdr (assoc :description definition)))
                       (spaces-to-add (- indent-to (length completion))))
                  (list completion "" (propertize (format "%s%s"
                                                          (make-string spaces-to-add ?\N{Space})
                                                          description)
                                                  'face 'completions-annotations))
                (list completion "" "")))
            completions)
    ))

(defun buffer-sets-completing-read (prompt collection &optional initial-input history)
  "PROMPT for item in COLLECTION using annotated completions.

If INITIAL-INPUT or HISTORY are provided, pas them to `completing-read'"
  (let* ((completion-extra-properties (list :affixation-function #'buffer-sets-completion-annotate)))
    (completing-read prompt collection nil t initial-input history)))


;; Commands

(defun buffer-sets-load-buffer-set (name)
  "Load the buffer-set NAME."
  (interactive (list (buffer-sets-completing-read "Load Set: " (buffer-sets-unloaded-buffer-sets))))
  (if-let ((definition (buffer-sets-get-set name)))
      (progn
        (mapc #'(lambda (x)
                  (buffer-sets-associate-buffer-with-set name (find-file-noselect (expand-file-name x))))
              (cdr (assoc :files definition)))
        (when-let ((on-apply (cdr (assoc :on-apply definition))))
          (funcall on-apply))
        (when-let ((select-buffer (cdr (assoc :select definition))))
          (switch-to-buffer select-buffer))
        (push name buffer-sets-loaded-sets)
        (run-hooks 'buffer-sets-load-set-hook)
        (message "Applied buffer set %s." name))
    (error "Buffer set `%s' is not known" name)))

(defun buffer-sets-unload-buffer-set (name)
  "Unload buffer-set NAME."
  (interactive (list (buffer-sets-completing-read "Unload Set: " buffer-sets-loaded-sets (car buffer-sets-loaded-sets))))
  (if-let ((buffers (cl-rest (assoc name buffer-sets-sets-to-buffers #'string=)))
           (definition (buffer-sets-get-set name)))
      (progn
        (mapc #'(lambda (buf)
                  (when (buffer-live-p buf)
                    (with-current-buffer buf
                      (save-buffer)
                      (kill-buffer buf))))
              buffers)
        (when-let ((on-remove (cdr (assoc :on-remove definition))))
          (funcall on-remove))
        (setf buffer-sets-sets-to-buffers (cl-remove-if
                                           #'(lambda (x) (string= name (cl-first x)))
                                           buffer-sets-sets-to-buffers)
              buffer-sets-loaded-sets (cl-remove-if (apply-partially #'string= name)
                                                    buffer-sets-loaded-sets))
        (run-hooks 'buffer-sets-unload-set-hook)
        (message "Unloaded buffer set %s." name))
    (error "Buffer set `%s' is not loaded" name)))

(defun buffer-sets-reload-buffer-set (buffer-set)
  "Reload BUFFER-SET."
  (interactive (list (buffer-sets-completing-read "Reload Set: " buffer-sets-loaded-sets (car buffer-sets-loaded-sets))))
  (buffer-sets-unload-buffer-set buffer-set)
  (buffer-sets-load-buffer-set buffer-set)
  (message "Reloaded buffer set %s." buffer-set))

(defun buffer-sets-unload-all-buffer-sets ()
  "Unload all loaded buffer-sets."
  (interactive)
  (dolist (buffer-set buffer-sets-loaded-sets)
    (buffer-sets-unload-buffer-set buffer-set)))

(defun buffer-sets-unload-last-loaded-set ()
  "Unload the most recently loaded buffer-set."
  (interactive)
  (unless (null buffer-sets-loaded-sets)
    (buffer-sets-unload-buffer-set (cl-first buffer-sets-loaded-sets))))

(defun buffer-sets-list ()
  "List all buffer-sets.

Show which are currently applied, and which buffers are visible."
  (interactive)
  (when (buffer-live-p "*Buffer Sets*")
    (kill-buffer "*Buffer Sets*"))
  (with-help-window "*Buffer Sets*"
    (with-current-buffer "*Buffer Sets*"
      (insert (propertize "◉ Buffer Sets\n\n"
                          'font-lock-face 'outline-1))
      (mapc #'(lambda (set-name)
                (insert (propertize (propertize (format " ○ %s" (if (buffer-sets-loaded-p set-name)
                                                                    (format "%s (applied)" set-name)
                                                                  (format "%s" set-name)))
                                                'font-lock-face 'outline-2)))
                (insert "\n\n")
                (when-let ((buffers (cdr (assoc set-name buffer-sets-sets-to-buffers #'string=))))
                  (mapc #'(lambda (buffer)
                            (insert "   ➤ ")
                            (insert-text-button (buffer-name buffer)
                                                'action (eval `(lambda (but) (switch-to-buffer ,buffer))))
                            (when (get-buffer-window-list buffer nil t)
                              (insert (format " (%s)"
                                              (propertize "visible"
                                                          'font-lock-face 'italic))))
                            (insert "\n"))
                        buffers)
                  (insert "\n")))
            (mapcar #'cl-first buffer-sets)))))


;; Backward Compatibility
(cl-defmacro define-buffer-set (name &key files select on-apply on-remove)
  "Define buffer-set NAME with FILES, SELECT, ON-APPLY and ON-REMOVE.

Compatibility macro."
  (let (clauses
        (name (or (and (not (stringp name))
                       (format "%s" name))
                  name)))
    (unless (null on-remove)
      (push `(cons :on-remove '(lambda () ,@on-remove)) clauses))
    (unless (null on-apply)
      (push `(cons :on-apply '(lambda () ,@on-apply)) clauses))
    (unless (null select)
      (push `(cons :select ,select) clauses))
    (unless (null files)
      (push `(cons :files ',files) clauses))
    `(progn
       (display-warning 'buffer-sets (format "The `define-buffer-set' macro was used to define \"%s\".  See `buffer-sets-save' for help." ,name) :warning)
       (setf buffer-set-macro-used-p t)
       (setf buffer-sets (cons (cons ,name (list ,@clauses))
                               (cl-remove-if (lambda (item) (string= ,name (car item)))
                                             buffer-sets))))))

(defun buffer-sets-save ()
  "Save buffer-set definitions."
  (interactive)
  (when (or buffer-sets-auto-save-p
            buffer-sets-macro-used-p)
    (setf buffer-sets-macro-used-p nil)
    (cl-case buffer-sets-save-method
      (:custom
       (customize-set-variable 'buffer-sets buffer-sets)
       (message "Saved buffer-set definitions using `customize' interface."))
      (:file
       (with-current-buffer (find-file buffer-sets-definitions-file)
         (kill-region (buffer-end -1) (buffer-end 1))
         (insert (format ";; -*- emacs-lisp -*-\n\n%S\n"
                         `(setf buffer-sets ',buffer-sets)))
         (save-buffer)
         (kill-buffer))
       (message "Saved buffer-set definitions using `setf' interface."))
      (t
       (error "`buffer-sets-save-method' does not provide where to save definitions")))))

(make-obsolete 'buffer-sets-migrate 'buffer-sets-save "3.1")

(defun buffer-sets-load-set-definitions (&optional force)
  "Load buffer-set-definitions from file, optionally FORCE loading.

Only if `buffer-sets' is nil, `buffer-sets-definitions-file' is a
string, and `buffer-sets-save-method' is `:file'."
  (when (or force
            (and (null buffer-sets)
                 (stringp buffer-sets-definitions-file)
                 (equal :file buffer-sets-save-method)))
    (load buffer-sets-definitions-file t t)
    (message "Loaded buffer-sets definitions.")))


;; Automatically load buffer sets

;;;###autoload
(defun buffer-sets-install-emacs-start-hook ()
  "Install the hook to load buffer-sets on Emacs start."
  (add-hook 'after-init-hook #'buffer-sets-after-init))

(defun buffer-sets-after-init ()
  "Load buffer-sets on Emacs start."
  (mapcar #'buffer-sets-load-buffer-set buffer-sets-start-sets))


;; Define Buffer Sets Mode

(defvar buffer-sets-mode-map
  (let ((keymap (make-keymap)))
    (define-key keymap (kbd "C-x L l") #'buffer-sets-load-buffer-set)
    (define-key keymap (kbd "C-x L r") #'buffer-sets-reload-buffer-set)
    (define-key keymap (kbd "C-x L L") #'buffer-sets-list)
    (define-key keymap (kbd "C-x L u") #'buffer-sets-unload-buffer-set)
    (define-key keymap (kbd "C-x L U") #'buffer-sets-unload-all-buffer-sets)
    (define-key keymap (kbd "C-x L p") #'buffer-sets-unload-last-loaded-set)
    keymap)
  "Keymap for buffer-set commands.")

;;;###autoload
(define-minor-mode buffer-sets-mode
  "A mode for managing sets of buffers."
  :lighter " BSM" :global t :keymap buffer-sets-mode-map
  (if buffer-sets-mode
      (progn
        (buffer-sets-load-set-definitions)
        (add-hook 'kill-emacs-hook #'buffer-sets-unload-all-buffer-sets)
        (add-hook 'kill-emacs-hook #'buffer-sets-save))
    (remove-hook 'kill-emacs-hook #'buffer-sets-unload-all-buffer-sets)
    (remove-hook 'kill-emacs-hook #'buffer-sets-save)))


;; Ibuffer integration
(with-eval-after-load 'ibuf-macs
  (define-ibuffer-filter in-buffer-set
      "Check to see if a buffer is in a given buffer-set."
    (:reader  (buffer-sets-completing-read "Buffer Set: " buffer-sets-loaded-sets))
    (buffer-sets-buffer-in-set-p qualifier buf)))

(provide 'buffer-sets)

;;; buffer-sets.el ends here
