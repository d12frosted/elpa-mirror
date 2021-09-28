;;; mu4e-column-faces.el --- Faces for individual mu4e columns -*- lexical-binding: t -*-

;; Copyright (C) 2021 Alexander Miller

;; Author: Alexander Miller <alexanderm@web.de>
;; Package-Requires: ((emacs "25.3"))
;; Package-Version: 20210927.1759
;; Package-Commit: b76a5989cafe88a263688488854187a015beef41
;; Homepage: https://github.com/Alexander-Miller/mu4e-column-faces
;; Version: 1.1

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

(defface mu4e-column-faces-thead-subject
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
- the mu4e message object"
  :group 'mu4e-column-faces)

(defcustom mu4e-column-faces-adjust-face nil
  "Function to optionally further adjust mu4e's column faces.
Can for example be used to assign different faces to different email accounts.

Value must be a function that takes 2 arguments:
- the so far assigned face
- the column
- the column's value
- the mu4e message object"
  :group 'mu4e-column-faces)

(defun mu4e-column-faces--header-handler (msg &optional point)
  "Entry point for the mu4e overrides.
Overrides `mu4e~headers-header-handler' out of necessity because all the
functions that actually do need changing are inlined.

The only change is for MSG to be passed to
`mu4e-column-faces--msg-header-line' to create a line with column faces,
POINT remains untouched."
  (when (buffer-live-p (mu4e-get-headers-buffer))
    (with-current-buffer (mu4e-get-headers-buffer)
      (let ((line (mu4e-column-faces--msg-header-line msg)))
        (when line
          (mu4e~headers-add-header line (mu4e-message-field msg :docid)
                                   point msg))))))

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
Requires at least mu4e v1.6.0."
  :init-value nil
  :global     t
  :lighter    nil
  :group      'mu4e-column-faces
  (if mu4e-column-faces-mode
      (progn
        (unless (version<= "1.6.0" mu4e-mu-version)
          (user-error
           "Mu4e-column-faces-mode requires at least mu4e 1.6.0, current version is %s"
           mu4e-mu-version))
        (advice-add #'mu4e~headers-header-handler
                    :override #'mu4e-column-faces--header-handler))
    (advice-remove #'mu4e~headers-header-handler
                   #'mu4e-column-faces--header-handler)))

(provide 'mu4e-column-faces)

;;; mu4e-column-faces.el ends here
