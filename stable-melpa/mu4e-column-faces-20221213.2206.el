;;; mu4e-column-faces.el --- Faces for individual mu4e columns -*- lexical-binding: t -*-

;; Copyright (C) 2022 Alexander Miller

;; Author: Alexander Miller <alexanderm@web.de>
;; Package-Requires: ((emacs "25.3"))
;; Package-Version: 20221213.2206
;; Package-Commit: 1bbb646ea07deb1bd2daa4c6eb36e0f65aac40b0
;; Homepage: https://github.com/Alexander-Miller/mu4e-column-faces
;; Version: 1.2.1

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

;; A minor mode for individual column faces in mu4e's mail overview.

;;; Code:

(require 'inline)
(require 'mu4e)

(defgroup mu4e-column-faces nil
  "Mu4e-column-faces configuration options."
  :group 'mu4e-column-faces
  :prefix "mu4e-column-faces-")

(defface mu4e-column-faces-thread-subject
  '((t :inherit font-lock-doc-face))
  "Face for `:thread-subject' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-to-from
  '((t :inherit font-lock-variable-name-face))
  "Face for `:from-or-to', `:to', `:from', `:cc' and `:bcc' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-date
  '((t :inherit font-lock-string-face))
  "Face for `:date' and `:human-date' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-flags
  '((t :inherit font-lock-type-face))
  "Face for `:flags' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-tags
  '((t :inherit font-lock-keyword-face))
  "Face for `:tags' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-mailing-list
  '((t :inherit font-lock-builtin-face))
  "Face for `:list' and `:mailing-list' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-maildir
  '((t :inherit font-lock-function-name-face))
  "Face for `:maildir' and `:path' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-message-id
  '((t :inherit font-lock-keyword-face))
  "Face for `:message-id' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-attachments
  '((t :inherit font-lock-constant-face))
  "Face for `:attachments' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-signature
  '((t :inherit font-lock-preprocessor-face))
  "Face for `:signature' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-decryption
  '((t :inherit font-lock-keyword-face))
  "Face for `:decryption' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-size
  '((t :inherit font-lock-string-face))
  "Face for `:size' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-thread-subject
  '((t :inherit font-lock-type-face))
  "Face for `:thread-subject' columns."
  :group 'mu4e-column-faces)

(defface mu4e-column-faces-user-agent
  '((t :inherit font-lock-doc-face))
  "Face for `:user-agent' columns."
  :group 'mu4e-column-faces)

(defcustom mu4e-column-faces-custom-column-handler nil
  "Function to optionally handle custom columns.

Value must be a function that takes two arguments:
- the column
- the mu4e message object

The return value should be the face used for the column.

For example if you want to define a face for one custom column you can do this:

 (defun special-column-face-handler (column _message)
   (when (eq column :my-custom-column)
     '(background \"green\")))

 (setf mu4e-column-faces-custom-column-handler #'special-column-face-handler)"
  :group 'mu4e-column-faces
  :type 'function)

(defcustom mu4e-column-faces-adjust-face nil
  "Function to optionally further adjust mu4e's column faces.
Can for example be used to assign different faces to different email accounts.

Value must be a function that takes 4 arguments:
- the so far assigned face
- the column
- the column's value
- the mu4e message object

The return value should be the new face for the column (or just the old face
if nothing should change).

For example to use a special face for emails from the emacs-devel mailing list
you can do this:

 (defun mailing-list-face-handler (face column value _message)
   (if (and (eq column :mailing-list)
            (equal value \"emacs-devel\"))
       '(:background \"red\")
     face))

 (setf mu4e-column-faces-adjust-face #'mailing-list-face-handler)"
  :group 'mu4e-column-faces
  :type 'function)

(defun mu4e-column-faces-~headers-append-handler (msglst)
  "Entry point for the mu4e overrides.
Overrides `mu4e~headers-append-handler' out of necessity because all the
functions that actually do need changing are inlined.

The only change is for MSGLST to be passed to
`mu4e-column-faces--msg-header-line'instead of `mu4e~headers-insert-header'."
  (when (buffer-live-p (mu4e-get-headers-buffer))
    (with-current-buffer (mu4e-get-headers-buffer)
      (save-excursion
	    (let ((inhibit-read-only t))
	      (seq-do
	       (lambda (msg)
	         (mu4e-column-faces--insert-header msg (point-max)))
	       msglst))))))

(defun mu4e-column-faces--update-handler (msg is-move maybe-view)
  "Entry point for the mu4e overrides.
Overrides `mu4e~headers-update-handler' out of necessity because all the
functions that actually do need changing are inlined.

Full function body is copied verbatim, the only change is that MSG is passed to
`mu4e-column-faces--insert-header' instead of `mu4e~headers-insert-header'.
IS-MOVE and MAYBE-VIEW remain untouched."
  (when (buffer-live-p (mu4e-get-headers-buffer))
    (with-current-buffer (mu4e-get-headers-buffer)
      (let* ((docid (mu4e-message-field msg :docid))
             (initial-message-at-point (mu4e~headers-docid-at-point))
             (initial-column (current-column))
	         (inhibit-read-only t)
             (point (mu4e~headers-docid-pos docid))
             (markinfo (gethash docid mu4e--mark-map)))
        (when point ;; is the message present in this list?

          ;; if it's marked, unmark it now
          (when (mu4e-mark-docid-marked-p docid)
            (mu4e-mark-set 'unmark))

          ;; re-use the thread info from the old one; this is needed because
          ;; *update* messages don't have thread info by themselves (unlike
          ;; search results)
          ;; since we still have the search results, re-use
          ;; those
          (plist-put msg :meta
                     (mu4e~headers-field-for-docid docid :meta))

          ;; first, remove the old one (otherwise, we'd have two headers with
          ;; the same docid...
          (mu4e~headers-remove-header docid t)

          ;; if we're actually viewing this message (in mu4e-view mode), we
          ;; update it; that way, the flags can be updated, as well as the path
          ;; (which is useful for viewing the raw message)
          (when (and maybe-view (mu4e~headers-view-this-message-p docid))
            (save-excursion (mu4e-view msg)))
          ;; now, if this update was about *moving* a message, we don't show it
          ;; anymore (of course, we cannot be sure if the message really no
          ;; longer matches the query, but this seem a good heuristic.  if it
          ;; was only a flag-change, show the message with its updated flags.
          (unless is-move
	        (save-excursion
	          (mu4e-column-faces--insert-header msg point)))

          ;; restore the mark, if any. See #2076.
          (when (and markinfo (mu4e~headers-goto-docid docid))
            (mu4e-mark-at-point (car markinfo) (cdr markinfo)))

          (if (and initial-message-at-point
                   (mu4e~headers-goto-docid initial-message-at-point))
              (progn
                (move-to-column initial-column)
                (mu4e~headers-highlight initial-message-at-point))
            ;; attempt to highlight the corresponding line and make it visible
            (mu4e~headers-highlight docid))
          (run-hooks 'mu4e-message-changed-hook))))))

(define-inline mu4e-column-faces--insert-header (msg pos)
  "Insert a header for MSG at point POS."
  (inline-letevals (msg pos)
    (inline-quote
     (when-let ((line (mu4e-column-faces--msg-header-line ,msg))
	            (docid (plist-get ,msg :docid)))
       (goto-char ,pos)
       (insert
        (propertize
         (concat
          (mu4e~headers-docid-cookie docid)
          mu4e--mark-fringe line "\n")
         'docid docid 'msg ,msg))))))

(define-inline mu4e-column-faces--msg-header-line (msg)
  "Create a propertized header for the given MSG.
Mostly the same as `mu4e~message-header-line', but without the call to
`mu4e~headers-apply-flags' since applying the the subject column's face based on
the message flags in included in `mu4e-column-faces--apply-face'."
  (inline-letevals (msg)
    (inline-quote
     (unless (and mu4e-headers-hide-predicate
                  (funcall mu4e-headers-hide-predicate ,msg))
       (mapconcat (lambda (f-w) (mu4e-column-faces--apply-face f-w ,msg))
                  mu4e-headers-fields " ")))))

(define-inline mu4e-column-faces--apply-face (f-w msg)
  "Find and apply the face for field of MSG described by F-W."
  (inline-letevals (f-w msg)
    (inline-quote
     (let* ((field (car ,f-w))
            (width (cdr ,f-w))
            (val (mu4e~headers-field-value ,msg field))
            (face (mu4e-column-faces--determine-face field ,msg))
            (face (if (and face mu4e-column-faces-adjust-face)
                      (funcall mu4e-column-faces-adjust-face face field val ,msg)
                    face))
            (val (if width (mu4e~headers-truncate-field field val width) val)))
       (when face
         (put-text-property 0 (length val) 'face face val))
       val))))

(define-inline mu4e-column-faces--determine-face (column msg)
  "Find the right face for the COLUMN of the given MSG."
  (declare (side-effect-free t))
  (inline-letevals (column msg)
    (inline-quote
     (cl-case ,column
       (:subject
        (let ((flags (mu4e-message-field ,msg :flags)))
          (cond
           ((memq 'trashed flags) 'mu4e-trashed-face)
           ((memq 'draft flags)   'mu4e-draft-face)
           ((or (memq 'unread flags) (memq 'new flags))
            'mu4e-unread-face)
           ((memq 'flagged flags) 'mu4e-flagged-face)
           ((memq 'replied flags) 'mu4e-replied-face)
           ((memq 'passed flags)  'mu4e-forwarded-face)
           (t                     'mu4e-header-face)) ))
       ((:to :from :cc :bcc :from-or-to)
        'mu4e-column-faces-to-from)
       (:attachments          'mu4e-column-faces-attachments)
       (:message-id           'mu4e-column-faces-message-id)
       (:thread-subject       'mu4e-column-faces-thread-subject)
       (:flags                'mu4e-column-faces-flags)
       (:tags                 'mu4e-column-faces-tags)
       (:size                 'mu4e-column-faces-size)
       (:signature            'mu4e-column-faces-signature)
       (:decryption           'mu4e-column-faces-decryption)
       (:user-agent           'mu4e-column-faces-user-agent)
       ((:list :mailing-list) 'mu4e-column-faces-mailing-list)
       ((:date :human-date)   'mu4e-column-faces-date)
       ((:maildir :path)      'mu4e-column-faces-maildir)
       (t (if mu4e-column-faces-custom-column-handler
              (funcall mu4e-column-faces-custom-column-handler
                       ,column ,msg)))))))

;;;###autoload
(define-minor-mode mu4e-column-faces-mode
  "Global minor mode for individual column faces in mu4e's email overview.
The view must be refreshed with `mu4e-headers-rerun-search' for the changes to
take effect.
Requires at least mu4e v1.8.0."
  :init-value nil
  :global     t
  :lighter    nil
  :group      'mu4e-column-faces
  (if mu4e-column-faces-mode
      (progn
        (unless (version<= "1.8.0" mu4e-mu-version)
          (user-error
           "Mu4e-column-faces-mode requires at least mu4e 1.8.0, current version is %s"
           mu4e-mu-version))
        (advice-add #'mu4e~headers-append-handler
                    :override #'mu4e-column-faces-~headers-append-handler)
        (advice-add #'mu4e~headers-update-handler
                    :override #'mu4e-column-faces--update-handler))
    (advice-remove #'mu4e~headers-append-handler
                   #'mu4e-column-faces-~headers-append-handler)
    (advice-add #'mu4e~headers-update-handler
                #'mu4e-column-faces--update-handler)))

(provide 'mu4e-column-faces)

;;; mu4e-column-faces.el ends here
