;;; magit-commit-mark.el --- Support marking commits as read -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-2.0-or-later
;; Copyright (C) 2021  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.org/ideasman42/emacs-magit-commit-mark
;; Package-Version: 20220809.625
;; Package-Commit: 9367f7e4038792073f090b2c881cdbde1ab47f40
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1") (magit "3.3.0"))

;;; Commentary:

;; Supports keeping track of read SHA1 commits using data stored persistently
;; (between sessions).
;; As well as functionality to toggle read/unread state.

;;; Usage

;; See readme.rst.
;;

;;; Code:
(require 'magit-diff)

(defgroup magit-commit-mark nil
  "Support marking commits in `magit-log' as read (storing the state persistently)."
  :group 'convenience)

(defcustom magit-commit-mark-on-show-commit t
  "Mark commits as read when displayed (with `magit-show-commit')."
  :type 'boolean)

(defcustom magit-commit-mark-on-skip-to-unread nil
  "Mark commits as read immediately when skipping to the next/previous unread."
  :type 'boolean)

(defcustom magit-commit-mark-on-show-commit-delay 2.0
  "Delay (in seconds) before marking as read."
  :type 'float)

(defcustom magit-commit-mark-sha1-length 12
  "The number of SHA1 characters to store & use to identify commits.

This must not be longer than the value used when displaying the log."
  :type 'integer)

(defcustom magit-commit-mark-directory
  (locate-user-emacs-file "magit-commit-mark" ".emacs-magit-commit-mark")
  "The directory to store the repository marking data."
  :type 'string)

;; Faces.

(defface magit-commit-mark-read-face
  (list (list t (list :inherit 'font-lock-comment-face)))
  "Face used to highlight the commit as read.")

(defface magit-commit-mark-unread-face
  (list (list t (list :inherit 'success)))
  "Face used to highlight the commit as unread.")

(defface magit-commit-mark-star-face
  (list (list t (list :inherit 'warning)))
  "Face used to highlight the commit as starred.")

(defface magit-commit-mark-urgent-face
  (list (list t (list :inherit 'error :extend t)))
  "Face used to highlight the commit as urgent.")


;; ---------------------------------------------------------------------------
;; Internal Variables

;; An `alist' of hashes where the key is the repository
;; and the value is a has of all read sha1's for that repository,
;; lazily initialized as needed.
(defvar magit-commit-mark--repo-hashes nil)

(defvar magit-commit-mark--on-show-commit-global-timer nil)

;; Buffer local overlays to display read/unread status.
(defvar-local magit-commit-mark--overlays nil)

;; Bit indices used for flags in the value of hashes stored in
;; `magit-commit-mark--repo-hashes' (add more as needed).
(defconst magit-commit-mark--bitflag-read 0)
(defconst magit-commit-mark--bitflag-star 1)
(defconst magit-commit-mark--bitflag-urgent 2)


;; ---------------------------------------------------------------------------
;; Internal Utility Functions

(defun magit-commit-mark--make-file-name-from-repo (repo-name)
  "Take the path REPO-NAME and return a name base on this."
  (file-name-concat
    magit-commit-mark-directory
    (concat (url-hexify-string (convert-standard-filename (expand-file-name repo-name))) ".data")))

(defun magit-commit-mark--get-repo-dir ()
  "Return the current repository root directory."
  (let ((repo-dir (magit-toplevel)))
    (when repo-dir
      ;; Ensure no trailing slash.
      (file-name-nondirectory (file-name-as-directory (expand-file-name repo-dir))))))

(defun magit-commit-mark--get-repo-dir-or-error ()
  "Return the current repository root directory or raise an error on failure."
  (let ((repo-dir (magit-commit-mark--get-repo-dir)))
    (unless repo-dir
      (user-error "Unable to find the directory for this GIT repository!"))
    repo-dir))

(defun magit-commit-mark--get-sha1-at-point-or-nil ()
  "Return the SHA1 at point or nil."
  (let
    (
      (sha1
        (or
          (magit-section-value-if 'module-commit)
          (thing-at-point 'git-revision t)
          (magit-branch-or-commit-at-point))))
    (when sha1
      (substring sha1 0 magit-commit-mark-sha1-length))))

(defun magit-commit-mark--get-sha1-at-point-or-error ()
  "Return the SHA1 at point or raise an error."
  (let ((sha1 (magit-commit-mark--get-sha1-at-point-or-nil)))
    (unless sha1
      (user-error "No sha1 found"))
    sha1))

(defun magit-commit-mark--get-context-vars-or-error ()
  "Access repository directory and sha1 from the current context (or error)."
  (let ((repo-dir (magit-commit-mark--get-repo-dir)))
    (let ((sha1 (magit-commit-mark--get-sha1-at-point-or-error)))
      (cons repo-dir sha1))))


;; ---------------------------------------------------------------------------
;; Overlay Management

(defun magit-commit-mark--overlay-clear ()
  "Clear all overlays."
  (mapc 'delete-overlay magit-commit-mark--overlays)
  (setq magit-commit-mark--overlays nil))

(defun magit-commit-mark--overlay-refresh-range (repo-hash point-beg point-end)
  "Refresh SHA1 overlays between POINT-BEG and POINT-END using REPO-HASH."

  (when magit-commit-mark--overlays
    (remove-overlays point-beg point-end 'magit-commit-mark t)
    ;; Remove all overlays from this list which don't have an associated buffer.
    (setq magit-commit-mark--overlays
      (delq nil (mapcar (lambda (ov) (and (overlay-buffer ov) ov)) magit-commit-mark--overlays))))

  (let
    ( ;; Constants.
      (flag-read (ash 1 magit-commit-mark--bitflag-read))
      (flag-star (ash 1 magit-commit-mark--bitflag-star))
      (flag-urgent (ash 1 magit-commit-mark--bitflag-urgent))

      (point-prev nil))

    ;; Set beginning.
    (goto-char point-beg)
    (goto-char (line-beginning-position))

    (while (and (< (point) point-end) (not (eq (point) point-prev)))
      (let
        (
          (point-sha1-beg (point))
          (point-sha1-end nil)
          (point-star-beg nil)
          (point-star-end nil)
          (point-subject-beg nil)
          (point-subject-end (line-end-position)))

        (unless (zerop (skip-chars-forward "^[:blank:]" point-subject-end))
          (setq point-sha1-end (point))
          (goto-char point-sha1-beg)
          (let ((sha1 (buffer-substring-no-properties point-sha1-beg point-sha1-end)))
            ;; Unlikely to fail.
            (when (string-match-p "\\`[[:xdigit:]]+\\'" sha1)
              (setq sha1 (substring sha1 0 magit-commit-mark-sha1-length))
              (let*
                (
                  (value (or (gethash sha1 repo-hash) 0))
                  (is-read (not (zerop (logand value flag-read))))
                  (is-star (not (zerop (logand value flag-star))))
                  (is-urgent (not (zerop (logand value flag-urgent)))))

                (when (or is-urgent is-star)
                  (goto-char point-sha1-end)
                  (skip-chars-forward "[:blank:]*|\\\\/" point-subject-end)
                  (setq point-subject-beg (point))
                  (goto-char point-sha1-beg))

                (when is-star
                  (goto-char point-sha1-end)
                  (skip-chars-forward "^*" point-subject-beg)
                  (cond
                    ((eq ?\* (char-after (point)))
                      (setq point-star-beg (- (point) 1))
                      (setq point-star-end (+ (point) 2)))
                    (t
                      ;; Fallback (unlikely to be needed).
                      (setq point-star-beg point-sha1-end)
                      (setq point-star-end point-subject-beg))))

                ;; Read status.
                (let ((ov (make-overlay point-sha1-beg point-sha1-end)))
                  (overlay-put ov 'magit-commit-mark t)
                  (overlay-put
                    ov 'face
                    (cond
                      (is-read
                        'magit-commit-mark-read-face)
                      (t
                        'magit-commit-mark-unread-face)))
                  (push ov magit-commit-mark--overlays))

                ;; Starred status.
                (when is-star
                  (let ((ov (make-overlay point-star-beg point-star-end)))
                    (overlay-put ov 'magit-commit-mark t)
                    (overlay-put ov 'face 'magit-commit-mark-star-face)
                    (push ov magit-commit-mark--overlays)))

                ;; Urgent status.
                (when is-urgent
                  (let ((ov (make-overlay point-subject-beg (1+ point-subject-end))))
                    (overlay-put ov 'magit-commit-mark t)
                    (overlay-put ov 'face 'magit-commit-mark-urgent-face)
                    (push ov magit-commit-mark--overlays)))))))

        ;; Next sha1.
        (setq point-prev point-sha1-beg))
      (forward-line 1))))

(defun magit-commit-mark--overlay-refresh (repo-hash)
  "Refresh all SHA1 overlays using REPO-HASH."
  (save-excursion
    (magit-commit-mark--overlay-refresh-range
      repo-hash
      (save-excursion
        (goto-char (max (point-min) (window-start)))
        (line-beginning-position))
      (save-excursion
        (goto-char (min (point-max) (window-end)))
        (line-end-position)))))


;; ---------------------------------------------------------------------------
;; Hash Access

(defun magit-commit-mark--hash-create ()
  "Return a new empty hash for the purpose of storing SHA1."
  (make-hash-table :test 'equal))

(defun magit-commit-mark--hash-ensure (repo-dir &optional no-file-read)
  "Ensure REPO-DIR has a hash entry.

When NO-FILE-READ is non-nil, initialize with an empty hash."
  (let ((cell (assoc repo-dir magit-commit-mark--repo-hashes)))
    (cond
      (cell
        (cdr cell))
      ;; Initialize with empty hash.
      (no-file-read
        (let ((repo-hash (magit-commit-mark--hash-create)))
          (push (cons repo-dir repo-hash) magit-commit-mark--repo-hashes)
          repo-hash))
      ;; Initialize from file.
      (t
        (magit-commit-mark--hashfile-read-with-dir repo-dir)))))

(defun magit-commit-mark--hash-set (repo-dir repo-hash)
  "Set REPO-DIR REPO-HASH in `magit-commit-mark--repo-hashes'."
  (let ((cell (assoc repo-dir magit-commit-mark--repo-hashes)))
    (cond
      (cell
        (setcdr cell repo-hash))
      (t
        (push (cons repo-dir repo-hash) magit-commit-mark--repo-hashes)))))


;; ---------------------------------------------------------------------------
;; Hash Disk IO

(defun magit-commit-mark--hashfile-read-with-dir (repo-dir)
  "Load hash file for REPO-DIR."
  (let ((hash-file (magit-commit-mark--make-file-name-from-repo repo-dir)))
    (let
      (
        (repo-hash
          (cond
            ((file-exists-p hash-file)
              (with-temp-buffer
                (insert-file-contents hash-file)
                (goto-char (point-min))
                (read (current-buffer))))
            (t
              (magit-commit-mark--hash-create)))))

      ;; Should never happen, paranoid sanity check!
      (unless (hash-table-p repo-hash)
        (error "Unknown type for internal hash %S" (type-of repo-hash)))

      (magit-commit-mark--hash-set repo-dir repo-hash)

      repo-hash)))

(defun magit-commit-mark--hashfile-read ()
  "Load hash file for the current repository REPO-DIR."
  (let ((repo-dir (magit-commit-mark--get-repo-dir-or-error)))
    (magit-commit-mark--hashfile-read-with-dir repo-dir)))

(defun magit-commit-mark--hashfile-write-with-dir (repo-dir)
  "Write the hash to file for REPO-DIR."
  (unless (file-directory-p magit-commit-mark-directory)
    (make-directory magit-commit-mark-directory t))
  (let ((hash-file (magit-commit-mark--make-file-name-from-repo repo-dir)))
    (let ((repo-hash (magit-commit-mark--hash-ensure repo-dir)))
      (unless (hash-table-p repo-hash)
        (setq repo-hash (magit-commit-mark--hash-create)))

      ;; Backup the file before writing (just in case),
      ;; OK to overwrite the previous backup.
      (when (file-exists-p hash-file)
        (rename-file hash-file (concat hash-file ".backup") t))

      (with-temp-buffer
        (prin1 repo-hash (current-buffer))
        (write-region nil nil hash-file nil 0)))))

(defun magit-commit-mark--hashfile-write ()
  "Write the hash to file for the current REPO-DIR."
  (let ((repo-dir (magit-commit-mark--get-repo-dir-or-error)))
    (magit-commit-mark--hashfile-write-with-dir repo-dir)))


;; ---------------------------------------------------------------------------
;; Internal Commit Mark Set/Clear/Toggle Implementation

(defun magit-commit-mark--commit-at-point-manipulate-with-sha1 (repo-dir sha1 action bit)
  "Mark REPO-DIR repository as read with SHA1 using ACTION operating on BIT."
  (let*
    (
      (repo-hash (magit-commit-mark--hash-ensure repo-dir))
      (flag (ash 1 bit))
      (value-real (gethash sha1 repo-hash))
      (value (or value-real 0))
      (value-next
        (pcase action
          ('set (logior value flag))
          ('clear (logand value (lognot flag)))
          ('toggle (logxor value flag))
          (code (message "Unknown value %S" code)))))

    ;; When the result is true, the value change, update the file.
    (when
      (cond
        ;; Do nothing, no value exist and it remains zero.
        ((and (null value-real) (zerop value-next))
          nil)
        ;; Do nothing, value is unchanged.
        ((eq value value-next)
          nil)
        ;; Value was removed.
        ((zerop value-next)
          (remhash sha1 repo-hash)
          t)
        ;; Value was added or updated.
        (t
          (puthash sha1 value-next repo-hash)
          t))

      (magit-commit-mark--overlay-refresh repo-hash)
      (magit-commit-mark--hashfile-write))))


;; ---------------------------------------------------------------------------
;; Step to Commit by Flag

(defun magit-commit-mark--step-to-bit-test-at-point (repo-hash state flag)
  "Check the REPO-HASH at the current point has it's FLAG set to STATE."
  (let ((sha1 (magit-commit-mark--get-sha1-at-point-or-nil)))
    (when sha1
      (let ((value (or (gethash sha1 repo-hash) 0)))
        (eq state (not (zerop (logand value flag))))))))

(defun magit-commit-mark--step-to-bit-test-at-point-strict (repo-hash state flag)
  "Check the REPO-HASH at the current point has it's FLAG set to STATE.
This is a strict version which requires the SHA1 to be at the line start,
useful for merge commits that show branching lines."
  (unless (eq ?\s (char-after (line-beginning-position)))
    (magit-commit-mark--step-to-bit-test-at-point repo-hash state flag)))

(defun magit-commit-mark--step-to-bit (dir state bit)
  "Move DIR to the next message with BIT set to STATE."
  ;; NOTE: don't depend on the display state, access the hash directly.
  (let*
    (
      (repo-dir (magit-commit-mark--get-repo-dir))
      (repo-hash (magit-commit-mark--hash-ensure repo-dir))
      (flag (ash 1 bit))
      (point-prev nil)
      (found nil)
      (found-point nil))

    (save-excursion
      (forward-line dir)

      (while
        (and
          (not (eq point-prev (point)))
          (not
            (setq found
              (magit-commit-mark--step-to-bit-test-at-point-strict repo-hash state flag))))
        (setq point-prev (point))
        (forward-line dir))

      (when found
        (setq found-point (point))))

    (cond
      (found-point
        (goto-char found-point)

        ;; Use maybe-update with a zero timer instead of `(call-interactively 'magit-show-commit)'
        ;; Because it handles canceling the idle timer, causing an occasional glitch
        ;; where the idle timer opens a different commit than this one.
        (let ((magit-update-other-window-delay 0.0))
          (magit-log-maybe-update-revision-buffer))
        t)
      (t
        nil))))


(defun magit-commit-mark--commit-at-point-action-on-bit (action bit)
  "Perform ACTION on flag BIT."
  (pcase-let ((`(,repo-dir . ,sha1) (magit-commit-mark--get-context-vars-or-error)))
    (magit-commit-mark--commit-at-point-manipulate-with-sha1 repo-dir sha1 action bit)))

;; NOTE: it's important to move to the beginning of the line since the user may have
;; moved the cursor elsewhere, causing the SHA1 not to be detected.
(defun magit-commit-mark--commit-at-point-action-on-bit-bol (action bit)
  "Perform ACTION on flag BIT (at line start)."
  (save-excursion
    (beginning-of-line)
    (magit-commit-mark--commit-at-point-action-on-bit action bit)))

;; ---------------------------------------------------------------------------
;; Internal Integration Functions

(defun magit-commit-mark--show-commit-timer (buf point-beg repo-dir sha1)
  "Timer callback triggered from BUF, to set unread when a timer is called.
POINT-BEG is used to check if the current line has changed.
REPO-DIR and SHA1 are forwarded to
`magit-commit-mark-commit-at-point-set-read-with-sha1'"
  ;; Buffer has not been killed.
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (when (eq point-beg (line-beginning-position))
        (magit-commit-mark--commit-at-point-manipulate-with-sha1
          repo-dir
          sha1
          'set
          magit-commit-mark--bitflag-read)))))

(defun magit-commit-mark--show-commit-advice (old-fn &rest args)
  "Internal function use to advise using `magit-show-commit'.

This calls OLD-FN with ARGS."
  (let
    ( ;; We only care about the SHA1, other values aren't important.
      (sha1 (car args))
      ;; Demote error so it's obvious marking failed and `old-fn' is never prevented from running.
      ;; In practice this should never happen, it's mainly to prevent this package
      ;; from breaking `magit' even in the chance of extremely unlikely situations.
      (repo-dir (with-demoted-errors "%S" (magit-commit-mark--get-repo-dir-or-error))))
    (cond
      ;; The error will have been demoted to a message, do nothing.
      ((null repo-dir)
        nil)
      ;; No delay.
      ((zerop magit-commit-mark-on-show-commit-delay)
        (with-demoted-errors "%S"
          (magit-commit-mark--commit-at-point-manipulate-with-sha1
            repo-dir
            sha1
            'set
            magit-commit-mark--bitflag-read)))
      ;; Use timer for delay.
      (t
        (when magit-commit-mark--on-show-commit-global-timer
          (cancel-timer magit-commit-mark--on-show-commit-global-timer))
        (setq magit-commit-mark--on-show-commit-global-timer
          (run-with-idle-timer
            magit-commit-mark-on-show-commit-delay
            nil
            #'magit-commit-mark--show-commit-timer
            (current-buffer)
            (line-beginning-position)
            repo-dir
            sha1)))))

  ;; Regular function.
  (apply old-fn args))

(defun magit-commit-mark--magit-log-arguments-extra (fn-orig &optional mode)
  "Add extra arguments to git log view around FN-ORIG, optionally passing MODE.
Needed so we can be sure to view the required number of SHA1 chars."
  (pcase-let ((`(,args ,files) (funcall fn-orig mode)))
    (list (append args (list (format "--abbrev=%d" magit-commit-mark-sha1-length))) files)))


;; ---------------------------------------------------------------------------
;; Immediate Font Locking

(defun magit-commit-mark--font-lock-fontify-region (point-beg point-end)
  "Update spelling for POINT-BEG & POINT-END to the queue, checking all text."
  (let ((repo-dir (magit-commit-mark--get-repo-dir)))
    (let ((repo-hash (magit-commit-mark--hash-ensure repo-dir)))
      (magit-commit-mark--overlay-refresh-range repo-hash point-beg point-end))))

(defun magit-commit-mark--immediate-enable ()
  "Enable immediate spell checking."

  ;; It's important this is added with a depth of 100,
  ;; because we want the font faces (comments, string etc) to be set so
  ;; the spell checker can read these values which may include/exclude words.
  (jit-lock-register #'magit-commit-mark--font-lock-fontify-region))

(defun magit-commit-mark--immediate-disable ()
  "Disable immediate spell checking."
  (jit-lock-unregister #'magit-commit-mark--font-lock-fontify-region)
  (magit-commit-mark--overlay-clear))


;; ---------------------------------------------------------------------------
;; Internal Mode Enable/Disable

(defun magit-commit-mark--enable ()
  "Enable the buffer local minor mode."
  ;; Initialize the buffer (can't run directly, use idle timer).

  (advice-add 'magit-log-arguments :around #'magit-commit-mark--magit-log-arguments-extra)

  (when magit-commit-mark-on-show-commit
    (advice-add 'magit-show-commit :around #'magit-commit-mark--show-commit-advice))

  (when (eq major-mode 'magit-log-mode)
    (magit-commit-mark--immediate-enable)))

(defun magit-commit-mark--disable ()
  "Disable the buffer local minor mode."

  (advice-remove 'magit-log-arguments #'magit-commit-mark--magit-log-arguments-extra)

  (when magit-commit-mark-on-show-commit
    (advice-remove 'magit-show-commit #'magit-commit-mark--show-commit-advice))

  (when magit-commit-mark--on-show-commit-global-timer
    (cancel-timer magit-commit-mark--on-show-commit-global-timer))

  (when (eq major-mode 'magit-log-mode)
    (magit-commit-mark--immediate-disable)
    (kill-local-variable 'magit-commit-mark--overlays)))


;; ---------------------------------------------------------------------------
;; Public Functions

;;;###autoload
(defun magit-commit-mark-toggle-read ()
  "Toggle the current commit read status.
ARG is the bit which is toggled, defaulting to 1 (read/unread)."
  (interactive)
  (magit-commit-mark--commit-at-point-action-on-bit-bol 'toggle magit-commit-mark--bitflag-read))

;;;###autoload
(defun magit-commit-mark-toggle-star ()
  "Toggle the current commit star status.
ARG is the bit which is toggled, defaulting to 1 (read/unread)."
  (interactive)
  (magit-commit-mark--commit-at-point-action-on-bit-bol 'toggle magit-commit-mark--bitflag-star))

;;;###autoload
(defun magit-commit-mark-toggle-urgent ()
  "Toggle the current commit urgent status.
ARG is the bit which is toggled, defaulting to 1 (read/unread)."
  (interactive)
  (magit-commit-mark--commit-at-point-action-on-bit-bol 'toggle magit-commit-mark--bitflag-urgent))

;; NOTE: other stepping functions could be added,
;; for now stepping by unread seems the most useful.

;;;###autoload
(defun magit-commit-mark-next-unread ()
  "Jump to the next unread message."
  (interactive)
  (let ((bit magit-commit-mark--bitflag-read))
    (when (magit-commit-mark--step-to-bit 1 nil bit)
      (when magit-commit-mark-on-skip-to-unread
        (magit-commit-mark--commit-at-point-action-on-bit-bol 'set bit))
      t)))

;;;###autoload
(defun magit-commit-mark-prev-unread ()
  "Jump to the previous unread message."
  (interactive)
  (let ((bit magit-commit-mark--bitflag-read))
    (when (magit-commit-mark--step-to-bit -1 nil bit)
      (when magit-commit-mark-on-skip-to-unread
        (magit-commit-mark--commit-at-point-action-on-bit-bol 'set bit))
      t)))

;;;###autoload
(define-minor-mode magit-commit-mark-mode
  "Magit Commit Mark Minor Mode."
  :global nil

  (cond
    (magit-commit-mark-mode
      (magit-commit-mark--enable))
    (t
      (magit-commit-mark--disable))))

(provide 'magit-commit-mark)

;;; magit-commit-mark.el ends here
