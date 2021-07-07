;;; buffer-ring.el --- Rings and tori for buffer navigation -*- lexical-binding: t -*-

;; Author: Mike Mattie <codermattie@gmail.com>
;;         Sid Kasivajhula <sid@countvajhula.com>
;; Maintainer: Sid Kasivajhula <sid@countvajhula.com>
;; URL: https://github.com/countvajhula/buffer-ring
;; Package-Version: 20210707.1745
;; Package-Commit: 25c44a39742b21122e1e2adf1f6c5828148cd3ee
;; Created: 2009-4-16
;; Version: 0.2
;; Package-Requires: ((emacs "25.1") (dynaring "0.2.0") (s "1.12.0") (ht "2.0"))

;; This file is NOT a part of Gnu Emacs.

;; This work is "part of the world."  You are free to do whatever you
;; like with it and it isn't owned by anybody, not even the
;; creators.  Attribution would be appreciated and is a valuable
;; contribution in itself, but it is not strictly necessary nor
;; required.  If you'd like to learn more about this way of doing
;; things and how it could lead to a peaceful, efficient, and creative
;; world, and how you can help, visit https://drym.org.
;;
;; This paradigm transcends traditional legal and economic systems, but
;; for the purposes of any such systems within which you may need to
;; operate:
;;
;; This is free and unencumbered software released into the public domain.
;; The authors relinquish any copyright claims on this work.

;;; Commentary:

;; Rings of buffers and tori of buffer rings.

;;; Code:

(defconst buffer-ring-version "0.2")
(require 'dynaring)
(require 's)
(require 'ht)

(defconst buffer-ring-default-ring-name "default")

;;
;; default keymap
;;

;;;###autoload
(define-minor-mode buffer-ring-mode
  "Minor mode to modulate keybindings in buffer-ring mode."
  :lighter " buffer-ring"
  :global t
  :keymap
  (let ((buffer-ring-map (make-sparse-keymap)))
    (define-key buffer-ring-map (kbd "C-c C-b l") #'buffer-ring-list-buffers)
    (define-key buffer-ring-map (kbd "C-c C-b r") #'buffer-ring-torus-list-rings)
    (define-key buffer-ring-map (kbd "C-c C-b w") #'buffer-ring-show-name)
    (define-key buffer-ring-map (kbd "C-c C-b a") #'buffer-ring-add)
    (define-key buffer-ring-map (kbd "C-c C-b d") #'buffer-ring-delete)
    (define-key buffer-ring-map (kbd "C-c C-b c") #'buffer-ring-drop-buffer)
    (define-key buffer-ring-map (kbd "C-c C-b f") #'buffer-ring-next-buffer)
    (define-key buffer-ring-map (kbd "C-c C-b b") #'buffer-ring-prev-buffer)
    (define-key buffer-ring-map (kbd "C-c C-b n") #'buffer-ring-torus-next-ring)
    (define-key buffer-ring-map (kbd "C-c C-b p") #'buffer-ring-torus-prev-ring)
    (define-key buffer-ring-map (kbd "C-c C-b e") #'buffer-ring-torus-delete-ring)

    buffer-ring-map))

(defvar buffer-ring-torus (dynaring-make)
  "A global ring of all the buffer rings.  A torus I believe.")

(defun buffer-ring-initialize ()
  "Set up any hooks needed for buffer rings."
  (interactive)
  ;; TODO: if we want to automatically maintain a "primary"
  ;; ring, we may also need to hook into buffer-list-changed-hook
  ;; or maybe find-file-hook in addition here
  ;; TODO: should this be buffer-local? in that case it can
  ;; be added at the time that the buffer is adding to a ring
  (advice-add 'switch-to-buffer
              :after #'buffer-ring-set-buffer-context))

(defun buffer-ring-disable ()
  "Remove hooks, etc."
  (interactive)
  (advice-remove 'switch-to-buffer #'buffer-ring-set-buffer-context))

;;
;;  buffer ring structure
;;

(defun buffer-ring-make-ring (name)
  "Construct a buffer ring with the name NAME.

A buffer ring is simply a labeled dynamic ring data structure
whose members are expected to be buffers."
  (cons name (dynaring-make)))

(defun buffer-ring-ring-name (buffer-ring)
  "An accessor to get the name of a BUFFER-RING."
  (car buffer-ring))

(defun buffer-ring-ring-ring (buffer-ring)
  "... Hello?

An accessor for the dynamic ring component of the BUFFER-RING."
  (cdr buffer-ring))

;;
;; buffer rings registry
;;
;; TODO: use buffer local variables instead?
(defvar buffer-rings
  (ht)
  "Buffer to rings hash.")

(defun buffer-ring-registry-get-key (buffer)
  "Key to use for BUFFER in the buffer registry."
  (buffer-name buffer))

(defun buffer-ring--parse-buffer (buffer)
  "Extract the buffer object indicated by BUFFER.

BUFFER could be either be the name of the buffer (a string)
or a buffer object, or nil. In the last case, this evaluates to
the current buffer."
  (if buffer
      (if (bufferp buffer)
          buffer
        (get-buffer buffer))
    (current-buffer)))

(defun buffer-ring-get-rings (&optional buffer)
  "All rings that BUFFER is part of."
  (let* ((buffer (buffer-ring--parse-buffer buffer))
         (ring-names (ht-get buffer-rings
                             (buffer-ring-registry-get-key buffer))))
    (seq-map #'buffer-ring-torus--find-ring ring-names)))

(defun buffer-ring-register-ring (buffer bfr-ring)
  "Register that BUFFER has been added to BFR-RING."
  (let ((key (buffer-ring-registry-get-key buffer))
        (ring-name (buffer-ring-ring-name bfr-ring)))
    (ht-set! buffer-rings
             key
             (delete-dups
              (cons ring-name
                    (ht-get buffer-rings
                            key))))))

(defun buffer-ring-registry-delete-ring (buffer bfr-ring)
  "Delete BFR-RING from the list of rings for BUFFER.

This does NOT delete the buffer from the ring, only the ring
identifier from the buffer.  It should only be called either
as part of doing the former or when deleting the ring entirely."
  (let ((key (buffer-ring-registry-get-key buffer))
        (ring-name (buffer-ring-ring-name bfr-ring)))
    (ht-set! buffer-rings
             key
             (remq ring-name
                   (ht-get buffer-rings
                           key)))))

(defun buffer-ring-registry-drop-ring (bfr-ring)
  "Drop BFR-RING from the registry of rings.

This should only be called when deleting the ring entirely."
  (let ((buffers (dynaring-values (buffer-ring-ring-ring bfr-ring))))
    (dolist (buf buffers)
      (buffer-ring-registry-delete-ring buf bfr-ring))))

;;
;; buffer ring interface
;;

(defun buffer-ring-size (&optional bfr-ring)
  "Return the number of buffers in BFR-RING.

If no buffer ring is specified, this defaults to the current ring.  If
there is no active buffer ring, it returns -1 so that you can always
use a numeric operator."
  (let* ((bfr-ring (or bfr-ring (buffer-ring-current-ring)))
         (ring (buffer-ring-ring-ring bfr-ring)))
    (if ring
        (dynaring-size ring)
      -1)))

(defun buffer-ring--add-buffer-to-ring (buffer bfr-ring)
  "Add BUFFER to BFR-RING."
  (let ((ring (buffer-ring-ring-ring bfr-ring)))
    (dynaring-insert ring buffer)
    (buffer-ring-register-ring buffer bfr-ring)
    (with-current-buffer buffer
      (add-hook 'kill-buffer-hook #'buffer-ring-drop-buffer t t))))

(defun buffer-ring--add (bfr-ring buffer)
  "Add BUFFER to BFR-RING."
  (let ((ring (buffer-ring-ring-ring bfr-ring))
        (ring-name (buffer-ring-ring-name bfr-ring)))
    (cond ((dynaring-contains-p ring buffer)
           (message "buffer %s is already in ring \"%s\"" (buffer-name)
                    ring-name)
           nil)
          (t (buffer-ring--add-buffer-to-ring buffer bfr-ring)
             t))))

(defun buffer-ring-add (ring-name &optional buffer)
  "Add the BUFFER to the ring with name RING-NAME.

It will prompt for the ring to add the buffer to.  If no BUFFER
is provided it assumes the current buffer."
  (interactive
   (list
    (let ((default-name (or (buffer-ring-current-ring-name)
                            buffer-ring-default-ring-name)))
      (read-string (format "Add to which ring [%s]? " default-name)
                   nil
                   nil
                   default-name))))
  (let ((bfr-ring (buffer-ring-torus-get-ring ring-name))
        (buffer (buffer-ring--parse-buffer buffer)))
    (let ((result (buffer-ring--add bfr-ring buffer)))
      ;; switch to the ring in all cases, for consistency
      (buffer-ring-torus-switch-to-ring ring-name)
      result)))

(defun buffer-ring-delete (&optional buffer)
  "Delete BUFFER from the current ring.

If no buffer is specified, it assumes the current buffer.

This modifies the ring, it does not kill the buffer."
  (interactive)
  (let ((buffer (buffer-ring--parse-buffer buffer)))
    (if (buffer-ring-current-ring)
        (let ((ring (buffer-ring-ring-ring (buffer-ring-current-ring))))
          (if (dynaring-delete ring buffer)
              (progn
                (buffer-ring-registry-delete-ring buffer (buffer-ring-current-ring))
                (message "Deleted buffer %s from ring %s"
                         buffer
                         (buffer-ring-current-ring-name)))
            (message "This buffer is not in the current ring")
            nil))
      (message "No active buffer ring.")
      nil)))

(defun buffer-ring-drop-buffer ()
  "Drop buffer from all rings.

Not to be confused with the little-known evil cousin
to the koala buffer."
  (interactive)
  (let ((buffer (current-buffer)))
    (save-excursion
      (dolist (bfr-ring (buffer-ring-get-rings buffer))
        ;; TODO: this may muddle torus recency
        (buffer-ring-torus-switch-to-ring (buffer-ring-ring-name bfr-ring))
        (buffer-ring-delete buffer)))
    ;; remove the buffer from the buffer ring registry
    (ht-remove! buffer-rings (buffer-ring-registry-get-key buffer))
    (remove-hook 'kill-buffer-hook #'buffer-ring-drop-buffer t)))

(defun buffer-ring-list-buffers ()
  "List the buffers in the current buffer ring."
  (interactive)
  (let* ((bfr-ring (buffer-ring-current-ring))
         (ring (buffer-ring-ring-ring bfr-ring)))
    (if bfr-ring
        (let ((result (dynaring-traverse-collect ring #'buffer-name)))
          (if result
              (message "buffers in [%s]: %s" (buffer-ring-ring-name bfr-ring) result)
            (message "Buffer ring is empty.")))
      (message "No active buffer ring."))) )

(defun buffer-ring--rotate (direction)
  "Rotate the buffer ring.

DIRECTION must be a function, either `dynaring-rotate-left` (to rotate
left) or `dynaring-rotate-right` (to rotate right)."
  (let ((bfr-ring (buffer-ring-current-ring)))
    (when bfr-ring
      (let ((ring (buffer-ring-ring-ring bfr-ring)))
        (unless (dynaring-empty-p ring)
          (when (= 1 (dynaring-size ring))
            (message "There is only one buffer in the ring."))
          (funcall direction ring)
          (buffer-ring-switch-to-buffer (dynaring-value ring)))))))

(defun buffer-ring-prev-buffer ()
  "Switch to the previous buffer in the buffer ring."
  (interactive)
  (buffer-ring--rotate #'dynaring-rotate-left))

(defun buffer-ring-next-buffer ()
  "Switch to the previous buffer in the buffer ring."
  (interactive)
  (buffer-ring--rotate #'dynaring-rotate-right))

(defun buffer-ring-visit-buffer (&optional buffer)
  "Visit BUFFER.

This makes it current in all rings of which it is part, and
switches the current ring to be the most recent one containing
the buffer. Note that this does not actually switch to the
buffer in question, but is likely to be called in connection
with such a switch occurring."
  (let* ((buffer (buffer-ring--parse-buffer buffer))
         (bfr-rings (buffer-ring-get-rings buffer)))
    ;; if the buffer isn't in any ring, we don't need to do anything
    (when bfr-rings
      ;; ensure that the buffer is re(break)inserted
      ;; in all of its associated rings
      (dolist (bring bfr-rings)
        (dynaring-break-insert (buffer-ring-ring-ring bring)
                               buffer))
      (let ((most-recent-ring (car bfr-rings)))
        ;; switch to the most recent ring containing the buffer
        (buffer-ring--torus-switch-to-ring
         (buffer-ring-ring-name most-recent-ring))
        ;; bring the buffer ring "to the surface" across all
        ;; member buffers, as the most recent one
        (buffer-ring-surface-ring most-recent-ring)))))

(defun buffer-ring-set-buffer-context (&rest _args)
  "Keep buffer rings updated when buffers are visited.

When a buffer is visited directly without rotating to it, this advice
function modifies the ring structure and switches the current ring if
necessary to correctly account for recency.

_ARGS are the arguments that the advised function was invoked with."
  (let ((buffer (current-buffer))
        (ring (buffer-ring-ring-ring (buffer-ring-current-ring))))
    ;; if it's already at the head of the current ring,
    ;; we probably arrived here via a buffer-ring interface
    ;; and don't need to do anything in that case
    (unless (eq buffer (dynaring-value ring))
      (buffer-ring-visit-buffer (current-buffer)))))

(defun buffer-ring-surface-ring (&optional bfr-ring)
  "Make BFR-RING the most recent ring in all member buffers.

We'd want to do this each time the ring becomes current, so that
ring recency is consistent across the board."
  (let ((bfr-ring (or bfr-ring (buffer-ring-current-ring))))
    (dolist (buffer (dynaring-values (buffer-ring-ring-ring bfr-ring)))
      (buffer-ring-register-ring buffer bfr-ring))))

;;
;; buffer torus interface
;;

(defun buffer-ring-torus--create-ring (name)
  "Create ring with name NAME."
  (let ((bfr-ring (buffer-ring-make-ring name)))
    (dynaring-insert buffer-ring-torus bfr-ring)
    bfr-ring))

(defun buffer-ring-torus--find-ring (name)
  "Find a ring with name NAME."
  (let ((segment (dynaring-find-forwards buffer-ring-torus
                                         (lambda (r)
                                           (string= name
                                                    (buffer-ring-ring-name r))))))
    (when segment
      (dynaring-segment-value segment))))

(defun buffer-ring-torus-get-ring (name)
  "Find or create a buffer ring with name NAME.

The buffer-ring is returned."
  (let ((found-ring (buffer-ring-torus--find-ring name)))
    (if found-ring
        (progn
          (message "Found existing ring: %s" name)
          found-ring)
      (message "Creating a new ring \"%s\"" name)
      (buffer-ring-torus--create-ring name))))

(defun buffer-ring--torus-switch-to-ring (name)
  "Switch to ring NAME."
  (let ((segment (dynaring-find-forwards buffer-ring-torus
                                         (lambda (r)
                                           (string= name
                                                    (buffer-ring-ring-name r))))))
    (when segment
      (let ((bfr-ring (dynaring-segment-value segment)))
        ;; switch to ring and reinsert it at the head
        (dynaring-break-insert buffer-ring-torus
                               bfr-ring)
        bfr-ring))))

(defun buffer-ring-torus-switch-to-ring (name)
  "Switch to ring NAME."
  (interactive "sSwitch to ring ? ")
  (let ((bfr-ring (buffer-ring--torus-switch-to-ring name)))
    (when bfr-ring
      (let ((buffer (current-buffer)))
        (buffer-ring--torus-switch-ring-actions bfr-ring buffer)))))

(defun buffer-ring-current-ring ()
  "Get the current (active) buffer ring."
  (dynaring-value buffer-ring-torus))

(defun buffer-ring-current-ring-name ()
  "Get the name of the current buffer ring."
  (buffer-ring-ring-name (buffer-ring-current-ring)))

(defun buffer-ring-show-name ()
  "Display name of current ring."
  (interactive)
  (message (buffer-ring-current-ring-name)))

(defun buffer-ring-current-buffer (&optional bfr-ring)
  "Current buffer in BFR-RING."
  (let ((bfr-ring (or bfr-ring (buffer-ring-current-ring))))
    (dynaring-value (buffer-ring-ring-ring bfr-ring))))

(defun buffer-ring-switch-to-buffer (buffer)
  "Switch to BUFFER while keeping rings consistent."
  (switch-to-buffer buffer)
  (buffer-ring-visit-buffer buffer)
  buffer)

(defun buffer-ring--torus-switch-ring-actions (bfr-ring buffer)
  "Perform any actions in connection with switching to a new ring.

BFR-RING is the new ring switched to, and BUFFER is the original buffer."
  (let ((ring (buffer-ring-ring-ring bfr-ring)))
    ;; bring the buffer ring "to the surface" across all
    ;; member buffers, as the most recent one
    (buffer-ring-surface-ring bfr-ring)
    ;; if original buffer is in the new ring, stay there
    ;; and reinsert it to account for recency
    (when (dynaring-contains-p ring buffer)
      (dynaring-break-insert ring buffer))
    (buffer-ring-switch-to-buffer
     (buffer-ring-current-buffer bfr-ring))))

(defun buffer-ring-torus--rotate (direction)
  "Rotate the buffer ring torus.

DIRECTION must be a function, either `dynaring-rotate-left` (to rotate
left) or `dynaring-rotate-right` (to rotate right)."
  (let ((buffer (current-buffer))
        (initial-bfr-ring (buffer-ring-current-ring)))
    (cond ((dynaring-empty-p buffer-ring-torus)
           (message "There are no rings in the buffer torus.")
           nil)
          ((= 1 (dynaring-size buffer-ring-torus))
           (message "There is only one buffer ring.")
           (unless (dynaring-empty-p (buffer-ring-ring-ring (buffer-ring-current-ring)))
             (buffer-ring-switch-to-buffer
              (buffer-ring-current-buffer (buffer-ring-current-ring))))
           t)
          (t
           ;; rotate past any empties
           (if (dynaring-rotate-until buffer-ring-torus
                                      direction
                                      (lambda (bfr-ring)
                                        ;; we want to rotate at least once
                                        (and (not (eq initial-bfr-ring
                                                      bfr-ring))
                                             (not (dynaring-empty-p
                                                   (buffer-ring-ring-ring bfr-ring))))))
               (progn
                 (message "switching to ring %s" (buffer-ring-current-ring-name))
                 (buffer-ring--torus-switch-ring-actions (buffer-ring-current-ring) buffer))
             (message "All of the buffer rings are empty. Keeping the current ring position")
             nil)))))

(defun buffer-ring-torus-next-ring ()
  "Switch to the previous buffer in the buffer ring."
  (interactive)
  (buffer-ring-torus--rotate 'dynaring-rotate-right))

(defun buffer-ring-torus-prev-ring ()
  "Switch to the previous buffer in the buffer ring."
  (interactive)
  (buffer-ring-torus--rotate 'dynaring-rotate-left))

(defun buffer-ring-torus-list-rings ()
  "List the buffer rings in the buffer torus."
  (interactive)
  (let ((rings (dynaring-traverse-collect buffer-ring-torus
                                          #'buffer-ring-ring-name)))
    (if rings
        (message "Buffer rings: %s" (s-join ", " rings))
      (message "No buffer rings."))))

(defun buffer-ring-torus-delete-ring (&optional ring-name)
  "Delete the buffer ring with name RING-NAME.

If no name is specified, this deletes the current ring."
  (interactive
   (list
    (read-string (format "Delete which ring [default: %s]? "
                         (buffer-ring-current-ring-name))
                 nil
                 nil
                 (buffer-ring-current-ring-name))))
  (let* ((ring-name (or ring-name (buffer-ring-current-ring-name)))
         (bfr-ring (buffer-ring-torus--find-ring ring-name)))
    (message "ring name is %s" ring-name)
    (if bfr-ring
        (progn (buffer-ring-registry-drop-ring bfr-ring)
               (dynaring-delete buffer-ring-torus bfr-ring)
               (message "Ring %s deleted." ring-name))
      (dynaring-destroy (buffer-ring-ring-ring bfr-ring))
      (message "No such ring."))))

(provide 'buffer-ring)
;;; buffer-ring.el ends here
