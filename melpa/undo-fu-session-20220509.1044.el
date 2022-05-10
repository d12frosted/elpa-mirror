;;; undo-fu-session.el --- Persistent undo, available between sessions -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later
;; Copyright (C) 2020-2022  Campbell Barton
;; Copyright (C) 2009-2015  Tomohiro Matsuyama

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.com/ideasman42/emacs-undo-fu-session
;; Package-Version: 20220509.1044
;; Package-Commit: 52c71b1cee2fe944e0013a2823e6fde10b26bc65
;; Keywords: convenience
;; Version: 0.2
;; Package-Requires: ((emacs "28.1"))

;;; Commentary:

;; This extension provides a way to use undo steps of
;; individual file buffers persistently.
;;

;;; Usage

;;
;; Write the following code to your .emacs file:
;;
;;   (require 'undo-fu-session)
;;   (global-undo-fu-session-mode)
;;
;; Or with `use-package':
;;
;;   (use-package undo-fu-session)
;;   (global-undo-fu-session-mode)
;;
;; If you prefer to enable this per-mode, you may do so using
;; mode hooks instead of calling `global-undo-fu-session-mode'.
;; The following example enables this for org-mode:
;;
;;   (add-hook 'org-mode-hook (lambda () (undo-fu-session-mode))
;;

;;; Code:

;; ---------------------------------------------------------------------------
;; Custom variables.

(defgroup undo-fu-session nil
  "Persistent undo steps, stored on disk between sessions."
  :group 'undo)

(defcustom undo-fu-session-linear nil
  "Store linear history (without redo), otherwise store the full history."
  :type 'boolean)

(defcustom undo-fu-session-directory
  (locate-user-emacs-file "undo-fu-session" ".emacs-undo-fu-session")
  "The directory to store undo data."
  :type 'string)

(defcustom undo-fu-session-ignore-encrypted-files t
  "Ignore encrypted files for undo session."
  :type 'boolean)

(defcustom undo-fu-session-compression 'gz
  "The type of compression to use or nil.

After changing, run `undo-fu-session-compression-update'
to convert existing files to the newly selected format."
  :type
  '
  (choice
    (const :tag "BZip2" bz2)
    (const :tag "GZip" gz)
    (const :tag "XZ" xz)
    (const :tag "Z-Standard" zst)

    (const :tag "No Compression" nil)))

(defcustom undo-fu-session-incompatible-files '()
  "List of REGEXP or FUNCTION for matching files to ignore for undo session."
  :type '(repeat (choice regexp function)))

(defcustom undo-fu-session-incompatible-major-modes nil
  "List of major-modes in which saving undo data should not be performed."
  :type '(repeat symbol))

(defcustom undo-fu-session-file-limit nil
  "Number of files to store, nil to disable limiting entirely.

Enforcing removes the oldest files."
  :type 'integer)


;; ---------------------------------------------------------------------------
;; Utility Functions
;;

(defmacro undo-fu-session--message-without-echo (str &rest args)
  "Wrap `message' passing in STR and ARGS, without showing in the echo area."
  `
  (let ((inhibit-message t))
    (message ,str ,@args)))

;; ---------------------------------------------------------------------------
;; Undo List Make Linear
;;
;; Note that this only works for `buffer-undo-list', not `pending-undo-list'.

(defun undo-fu-session--linear-undo-list (undo-list equiv-table)
  "Collapse UNDO-LIST using EQUIV-TABLE making it linear.

This gives the same behavior as running `undo-only',
ignoring all branches that aren't included in the current undo state."
  (let ((linear-list (cons nil nil)))
    ;; Store the last `cons' cell to build a list in-order
    ;; (saves pushing to the front of the list then reversing).
    (let ((tail-cdr linear-list))
      (while
        ;; Collapse all redo branches (giving the same results as if running `undo-only')
        (let ((undo-list-next nil))
          (while (setq undo-list-next (gethash undo-list equiv-table))
            (setq undo-list undo-list-next))
          (and undo-list (not (eq t undo-list))))

        ;; Pop all steps until the next boundary 'nil'.
        (let ((undo-elt t))
          (while undo-elt
            (setq undo-elt (pop undo-list))
            (setq tail-cdr (setcdr tail-cdr (cons undo-elt nil))))))
      ;; Remove the place holder `cons' cell.
      (setq linear-list (cdr linear-list)))

    ;; Pass through 'nil', when there is no undo information.
    ;; Also convert '(list nil)' to 'nil', since this is no undo info too.
    ;;
    ;; Note that we use 'nil' as this is what `buffer-undo-list' is set
    ;; to when there are no undo steps yet.
    (cond
      ((and linear-list (not (equal (list nil) linear-list)))
        linear-list)
      (t
        nil))))

;; ---------------------------------------------------------------------------
;; Undo Encode/Decode Functionality

(defun undo-fu-session--walk-tree (fn tree)
  "Operate recursively on undo-list, calling FN TREE."
  (cond
    ((consp tree)
      (let ((value (funcall fn tree)))
        (cond
          ((eq value tree)
            (let*
              (
                (cons (cons (undo-fu-session--walk-tree fn (car tree)) nil))
                (cur cons))
              (while tree
                (let ((cdr (cdr tree)))
                  (cond
                    ((consp cdr)
                      (let ((next (cons (undo-fu-session--walk-tree fn (car cdr)) nil)))
                        (setcdr cur next)
                        (setq cur next)
                        (setq tree cdr)))
                    (t
                      (setcdr cur (undo-fu-session--walk-tree fn cdr))
                      (setq tree nil)))))
              cons))
          (t
            value))))
    ((vectorp tree)
      (let ((value (funcall fn tree)))
        (cond
          ((eq value tree)
            (let*
              (
                (length (length tree))
                (vector (make-vector length nil)))
              (dotimes (i (1- length))
                (aset vector i (undo-fu-session--walk-tree fn (aref tree i))))
              vector))
          (t
            value))))
    (tree
      (funcall fn tree))))

(defun undo-fu-session--encode (tree)
  "Encode `TREE' so that it can be stored as a file."
  (undo-fu-session--walk-tree
    (lambda (a)
      (cond
        ((markerp a)
          (cons
            (cond
              ((marker-insertion-type a)
                'marker*)
              (t
                'marker))
            (marker-position a)))
        ((overlayp a)
          (list 'overlay (overlay-start a) (overlay-end a)))
        ((stringp a)
          (substring-no-properties a))
        (t
          a)))
    tree))

(defun undo-fu-session--decode (tree)
  "Decode `TREE' so that it can be recovered as undo data."
  (undo-fu-session--walk-tree
    (lambda (a)
      (cond
        ((consp a)
          (cond
            ((eq (car a) 'marker)
              (set-marker (make-marker) (cdr a)))
            ((eq (car a) 'marker*)
              (let ((marker (make-marker)))
                (set-marker marker (cdr a))
                (set-marker-insertion-type marker t)
                marker))
            ((eq (car a) 'overlay)
              (let
                (
                  (start (cadr a))
                  (end (caddr a)))
                (cond
                  ((and start end)
                    (make-overlay (cadr a) (caddr a)))
                  ;; Make deleted overlay
                  (t
                    (let ((overlay (make-overlay (point-min) (point-min))))
                      (delete-overlay overlay)
                      overlay)))))
            (t
              a)))
        (t
          a)))
    tree))

(defun undo-fu-session--next-step (list)
  "Get the next undo step in LIST.

Argument LIST compatible list `buffer-undo-list'."
  (while (car list)
    (setq list (cdr list)))
  (while (and list (null (car list)))
    (setq list (cdr list)))
  list)

(defun undo-fu-session--list-to-index-map (list index index-step step-to-index-hash)
  "Populate the STEP-TO-INDEX-HASH with LIST element.

List elements are used as keys mapping to INDEX by INDEX-STEP."
  (unless (eq list t)
    (while list
      (puthash list index step-to-index-hash)
      (setq index (+ index index-step))
      (setq list (undo-fu-session--next-step list)))))

(defun undo-fu-session--list-from-index-map (list index index-step step-from-index-hash)
  "Populate the STEP-FROM-INDEX-HASH with INDEX by INDEX-STEP.

INDEX-STEP are used as keys mapping to LIST elements."
  (unless (eq list t)
    (while list
      (puthash index list step-from-index-hash)
      (setq index (+ index index-step))
      (setq list (undo-fu-session--next-step list)))))

(defun undo-fu-session--equivtable-encode (equiv-table buffer-list pending-list)
  "Convert the EQUIV-TABLE into an alist of buffer list indices.
Argument BUFFER-LIST typically `undo-buffer-list'.
Argument PENDING-LIST typically `pending-undo-list'."
  (let
    ( ;; Map undo-elem -> index.
      ;; Negative indices for 'pending-list'.
      (step-to-index-hash (make-hash-table :test 'eq))
      (equiv-table-alist (list)))

    (undo-fu-session--list-to-index-map buffer-list 0 1 step-to-index-hash)
    (undo-fu-session--list-to-index-map pending-list -1 -1 step-to-index-hash)

    (maphash
      (lambda (key val)
        (let
          (
            (key-num (gethash key step-to-index-hash))
            (val-num
              (cond
                ((eq t val)
                  t)
                (t
                  (gethash val step-to-index-hash)))))
          (when (and key-num val-num)
            (push (cons key-num val-num) equiv-table-alist))))
      equiv-table)
    equiv-table-alist))


(defun undo-fu-session--equivtable-decode (equiv-table-alist buffer-list pending-list)
  "Convert EQUIV-TABLE-ALIST into a hash compatible with `undo-equiv-table'.
Argument BUFFER-LIST an `undo-buffer-list' compatible list.
Argument PENDING-LIST an `pending-undo-list' compatible list."

  (let*
    (
      (equiv-table-length (length equiv-table-alist))
      ;; Map index -> undo-elem.
      ;; Negative indices for 'pending-list'.
      (step-from-index-hash (make-hash-table :test 'eq))
      (equiv-table-hash (make-hash-table :test 'eq :weakness t :size equiv-table-length)))

    (unless (zerop equiv-table-length)

      (undo-fu-session--list-from-index-map buffer-list 0 1 step-from-index-hash)
      (undo-fu-session--list-from-index-map pending-list -1 -1 step-from-index-hash)

      (dolist (item equiv-table-alist)
        (pcase-let ((`(,key-num . ,val-num) item))
          (let
            (
              (key (gethash key-num step-from-index-hash))
              (val
                (cond
                  ((eq t val-num)
                    t)
                  (t
                    (gethash val-num step-from-index-hash)))))
            (puthash key val equiv-table-hash)))))
    equiv-table-hash))

;; ---------------------------------------------------------------------------
;; Undo Session Limiting Functionality

(defun undo-fu-session--file-limit-enforce ()
  "Limit the number of session files to the `undo-fu-session-file-limit' newest."
  ;; While errors are highly unlikely in this case,
  ;; clearing old files should _never_ interfere with other operations,
  ;; so surround with error a check & error message.
  (condition-case err-1
    (when (file-directory-p undo-fu-session-directory)
      (dolist
        (file-with-attrs
          (nthcdr ;; Skip new files, removing old.
            undo-fu-session-file-limit
            (sort ;; Sort new files first.
              (delq
                nil ;; Non-file.
                (mapcar
                  #'
                  (lambda (x)
                    (unless (nth 1 x)
                      x))
                  (directory-files-and-attributes undo-fu-session-directory t nil t)))
              (lambda (x y) (time-less-p (nth 6 y) (nth 6 x))))))
        (let ((file (car file-with-attrs)))
          (condition-case err-2
            (delete-file file)
            (error
              (message
                "Undo-Fu-Session error deleting '%s' for '%s'"
                (error-message-string err-2)
                file))))))
    (error (message "Undo-Fu-Session error limiting files '%s'" (error-message-string err-1)))))


;; ---------------------------------------------------------------------------
;; Undo Session Compression Conversion Functionality

(defun undo-fu-session--compression-update-impl ()
  "Use the current compression settings."
  (let
    ( ;; Quiet compression messages for `with-auto-compression-mode'.
      (jka-compr-verbose nil)
      ;; The new extension to use.
      (ext-dst (undo-fu-session--file-name-ext))
      ;; The files to operate on
      (files-to-convert (list))
      (count-complete 0)
      (count-pending 0)
      (size-src 0)
      (size-dst 0))

    (dolist
      (file-src
        (cond
          ((file-directory-p undo-fu-session-directory)
            (directory-files undo-fu-session-directory))
          (t
            (list))))
      (let ((file-src-full (file-name-concat undo-fu-session-directory file-src)))
        (unless (file-directory-p file-src-full)
          (unless (string-suffix-p ext-dst file-src)
            (setq count-pending (1+ count-pending))
            (push file-src-full files-to-convert)))))

    (message "Operating on %d file(s) in \"%s\"" count-pending undo-fu-session-directory)
    (with-auto-compression-mode
      (dolist (file-src-full files-to-convert)
        (let ((file-dst-full (file-name-with-extension file-src-full ext-dst)))
          (message
            "File %d of %d: %s"
            count-complete
            count-pending
            (file-name-nondirectory file-dst-full))
          (condition-case-unless-debug err
            (progn
              (with-temp-buffer
                (insert-file-contents file-src-full)
                (write-region nil nil file-dst-full nil 0))

              (setq size-src (+ size-src (file-attribute-size (file-attributes file-src-full))))
              (setq size-dst (+ size-dst (file-attribute-size (file-attributes file-dst-full))))

              (delete-file file-src-full)
              (setq count-complete (1+ count-complete)))

            (error (message "Error: %s" (error-message-string err)))))))

    (message
      "Completed %d file(s) (size was %s, now %s)"
      count-complete
      (file-size-human-readable size-src)
      (file-size-human-readable size-dst))))


;; ---------------------------------------------------------------------------
;; Undo Save/Restore Functionality

(defun undo-fu-session--file-name-ext ()
  "Return the current file name extension in use."
  (cond
    ((symbolp undo-fu-session-compression)
      (concat "." (symbol-name undo-fu-session-compression)))
    ((eq undo-fu-session-compression t)
      ;; Used for older versions where compression was a boolean.
      ".gz")
    (t
      ".el")))

(defun undo-fu-session--make-file-name (filename)
  "Take the path FILENAME and return a name base on this."
  (concat
    (file-name-concat
      undo-fu-session-directory
      (url-hexify-string (convert-standard-filename (expand-file-name filename))))
    (undo-fu-session--file-name-ext)))

(defun undo-fu-session--match-file-name (filename test-files)
  "Return t if FILENAME match any item in TEST-FILES."
  (catch 'found
    (dolist (matcher test-files)
      (when
        (cond
          ((stringp matcher)
            (string-match-p matcher filename))
          (t
            (funcall matcher filename)))
        (throw 'found t)))))

(defun undo-fu-session--directory-ensure ()
  (unless (file-directory-p undo-fu-session-directory)
    (make-directory undo-fu-session-directory t)
    ;; These files should only readable by the owner, see #2.
    ;; Setting the executable bit is important for directories to be writable.
    (set-file-modes undo-fu-session-directory #o700)))

(defun undo-fu-session--recover-buffer-p (buffer)
  "Return t if undo data of BUFFER should be recovered."
  (let
    (
      (filename (buffer-file-name buffer))
      (test-files undo-fu-session-incompatible-files)
      (test-modes undo-fu-session-incompatible-major-modes))
    (cond
      ((null filename)
        nil)
      ( ;; Ignore encryped files.
        (and
          undo-fu-session-ignore-encrypted-files
          epa-file-handler
          (string-match-p (car epa-file-handler) filename))
        nil)
      ((and test-files (undo-fu-session--match-file-name filename test-files))
        nil)
      ((and test-modes (memq (buffer-local-value 'major-mode buffer) test-modes))
        nil)
      (t
        t))))

(defun undo-fu-session--save-impl ()
  "Internal save logic, resulting in t on success."

  ;; Paranoid as it's possible the directory was removed since the mode was enabled.
  (undo-fu-session--directory-ensure)

  (let
    (
      (buffer (current-buffer))
      (filename (buffer-file-name))
      (undo-file nil)
      (content-header nil)
      (content-data nil)

      ;; Ensure we can include undo information for the buffer being operated on, see #3.
      (coding-system-for-write buffer-file-coding-system)

      ;; Quiet compression messages for `with-auto-compression-mode'.
      (jka-compr-verbose nil))

    (catch 'exit
      ;; No need for a message, exit silently since there is nothing to do.
      (unless (undo-fu-session--recover-buffer-p buffer)
        (throw 'exit nil))

      (unless (or (consp buffer-undo-list) (consp pending-undo-list))
        (throw 'exit nil))

      (let
        ( ;; Variables to build the `content-data'.
          (emacs-buffer-undo-list nil)
          (emacs-pending-undo-list nil)
          (emacs-undo-equiv-table nil))

        (cond
          ;; Simplified linear history (no redo or implicit tree-structure).
          ;; Only store steps reachable by calling `undo-only'.
          (undo-fu-session-linear
            (setq emacs-buffer-undo-list
              (undo-fu-session--encode
                (undo-fu-session--linear-undo-list buffer-undo-list undo-equiv-table))))
          ;; Full non-linear history (full undo/redo).
          (t
            (setq emacs-buffer-undo-list (undo-fu-session--encode buffer-undo-list))
            (setq emacs-pending-undo-list (undo-fu-session--encode pending-undo-list))
            (setq emacs-undo-equiv-table
              (undo-fu-session--equivtable-encode
                undo-equiv-table
                buffer-undo-list
                pending-undo-list))))

        (setq content-header
          (list (cons 'buffer-size (buffer-size)) (cons 'buffer-checksum (sha1 buffer))))
        (setq content-data
          (list
            (cons 'emacs-buffer-undo-list emacs-buffer-undo-list)
            (cons 'emacs-pending-undo-list emacs-pending-undo-list)
            (cons 'emacs-undo-equiv-table emacs-undo-equiv-table)))))

    (when content-data
      (setq undo-file (undo-fu-session--make-file-name filename))

      ;; Only enforce the file limit when saving new files,
      ;; this avoids scanning the undo session directory on every successive save.
      (when undo-fu-session-file-limit
        (unless (file-exists-p undo-file)
          (undo-fu-session--file-limit-enforce)))

      (with-auto-compression-mode
        (with-temp-buffer
          (prin1 content-header (current-buffer))
          (write-char ?\n (current-buffer))
          (prin1 content-data (current-buffer))
          (write-region nil nil undo-file nil 0)
          t)))))

(defun undo-fu-session--save-safe ()
  "Public save function, typically called by `write-file-functions'."
  (when (bound-and-true-p undo-fu-session-mode)
    (condition-case err
      (undo-fu-session--save-impl)
      (error (message "Undo-Fu-Session can not save undo data: %s" (error-message-string err)))))
  ;; Important to return NIL, to show the file wasn't saved.
  nil)

(defun undo-fu-session--recover-impl ()
  "Internal restore logic, resulting in t on success."
  (let
    (
      (buffer (current-buffer))
      (filename (buffer-file-name))
      (undo-file nil)
      (content-header nil)
      (content-data nil)

      ;; Ensure we can include undo information for the buffer being operated on, see #3.
      (coding-system-for-read buffer-file-coding-system)

      ;; Quiet compression messages for `with-auto-compression-mode'.
      (jka-compr-verbose nil))

    (catch 'exit
      ;; No need for a message, exit silently since there is nothing to do.
      (unless (undo-fu-session--recover-buffer-p buffer)
        (throw 'exit nil))

      (setq undo-file (undo-fu-session--make-file-name filename))

      (unless (file-exists-p undo-file)
        (throw 'exit nil))

      (with-auto-compression-mode
        (with-temp-buffer
          (insert-file-contents undo-file)
          (goto-char (point-min))
          (setq content-header (read (current-buffer)))

          ;; Use `undo-fu-session--message-without-echo' to avoid distracting the user
          ;; when a common-place reason for failing to load is hit.
          ;;
          ;; These issues are common when working with others on documents.
          ;; This way users may find out why undo didn't load if they need,
          ;; without distracting them with noisy info.
          (unless (= (buffer-size buffer) (cdr (assoc 'buffer-size content-header)))
            (undo-fu-session--message-without-echo
              "Undo-Fu-Session discarding: file length mismatch for %S"
              filename)
            (throw 'exit nil))

          (unless (string-equal (sha1 buffer) (cdr (assoc 'buffer-checksum content-header)))
            (undo-fu-session--message-without-echo
              "Undo-Fu-Session discarding: file checksum mismatch for %S"
              filename)
            (throw 'exit nil))

          ;; No errors... decode all undo data.
          (setq content-data (read (current-buffer))))))

    (when content-data
      (let*
        ( ;; `emacs-buffer-undo-list' may not exist, nil is OK.
          (emacs-buffer-undo-list
            (undo-fu-session--decode (cdr (assoc 'emacs-buffer-undo-list content-data))))
          ;; `emacs-pending-undo-list' may not exist, nil is OK.
          (emacs-pending-undo-list
            (undo-fu-session--decode (cdr (assoc 'emacs-pending-undo-list content-data))))
          ;; `emacs-undo-equiv-table' may not exist, nil is OK as it's treated as an empty list.
          (emacs-undo-equiv-table
            (undo-fu-session--equivtable-decode
              (cdr (assoc 'emacs-undo-equiv-table content-data))
              emacs-buffer-undo-list
              emacs-pending-undo-list)))

        ;; It's possible the history was saved with undo disabled.
        ;; In this case simply reset the values so loading history never disables undo.
        (when (eq t emacs-buffer-undo-list)
          (setq emacs-buffer-undo-list nil)
          (setq emacs-pending-undo-list nil)
          (setq emacs-undo-equiv-table '()))

        ;; Assign undo data to the current buffer.
        (setq buffer-undo-list emacs-buffer-undo-list)
        (setq pending-undo-list emacs-pending-undo-list)
        ;; Merge the the hash-table since this is a global-variable, share between
        ;; buffers otherwise this interferes with other buffers undo-only/redo.
        (when (hash-table-p emacs-undo-equiv-table)
          (maphash (lambda (key val) (puthash key val undo-equiv-table)) emacs-undo-equiv-table))
        t))))

(defun undo-fu-session--recover-safe ()
  "Public restore function, typically called by `find-file-hook'."
  (when (bound-and-true-p undo-fu-session-mode)
    (condition-case err
      (undo-fu-session--recover-impl)
      (error
        (message "Undo-Fu-Session can not recover undo data: %s" (error-message-string err))))))


;; ---------------------------------------------------------------------------
;; Public Functions

;;;###autoload
(defun undo-fu-session-save ()
  "Save undo data."
  (interactive)
  (undo-fu-session--save-safe))

;;;###autoload
(defun undo-fu-session-recover ()
  "Recover undo data."
  (interactive)
  (undo-fu-session--recover-safe))

;;;###autoload
(defun undo-fu-session-compression-update ()
  "Update existing undo session data after changing compression settings."
  (interactive)
  (undo-fu-session--compression-update-impl))


;; ---------------------------------------------------------------------------
;; Define Minor Mode
;;
;; Developer note, use global hooks since these run before buffers are loaded.
;; Each function checks if the local mode is active before operating.

(defun undo-fu-session--mode-in-any-buffer ()
  "Return non-nil if the `undo-fu-session-mode' is enabled in any buffer."
  (let
    (
      (mode-in-any-buffer nil)
      (buffers (buffer-list)))
    (while buffers
      (let ((buf (pop buffers)))
        (when (buffer-local-value 'undo-fu-session-mode buf)
          (setq mode-in-any-buffer t)
          (setq buffers nil))))
    mode-in-any-buffer))

(defun undo-fu-session--mode-enable ()
  "Turn on 'undo-fu-session-mode' for the current buffer."
  ;; Even though this runs on save, call here since it's better the user catches
  ;; errors when the mode is enabled instead of having the hook fail.
  (undo-fu-session--directory-ensure)

  (add-hook 'write-file-functions #'undo-fu-session--save-safe)
  (add-hook 'find-file-hook #'undo-fu-session--recover-safe))

(defun undo-fu-session--mode-disable ()
  "Turn off 'undo-fu-session-mode' for the current buffer."
  (unless (undo-fu-session--mode-in-any-buffer)
    (remove-hook 'write-file-functions #'undo-fu-session--save-safe)
    (remove-hook 'find-file-hook #'undo-fu-session--recover-safe)))

(defun undo-fu-session--mode-turn-on ()
  "Enable command `undo-fu-session-mode'."
  (when
    (and
      ;; Not already enabled.
      (not (bound-and-true-p undo-fu-session-mode))
      ;; Not in the mini-buffer.
      (not (minibufferp))
      ;; Not a special mode (package list, tabulated data ... etc)
      ;; Instead the buffer is likely derived from `text-mode' or `prog-mode'.
      (not (derived-mode-p 'special-mode)))
    (undo-fu-session-mode 1)))

;;;###autoload
(define-minor-mode undo-fu-session-mode
  "Toggle saving the undo data in the current buffer (Undo-Fu Session Mode)."
  :global nil

  (cond
    (undo-fu-session-mode
      (undo-fu-session--mode-enable))
    (t
      (undo-fu-session--mode-disable))))

;;;###autoload
(define-globalized-minor-mode
  global-undo-fu-session-mode
  undo-fu-session-mode
  undo-fu-session--mode-turn-on)

(provide 'undo-fu-session)
;;; undo-fu-session.el ends here
