;;; cpu-sos.el --- S.O.S. from a CPU in distress  -*- lexical-binding:t -*-

;; Copyright (C) 2020 Bruno Félix Rezende Ribeiro <oitofelix@gnu.org>

;; Author: Bruno Félix Rezende Ribeiro <oitofelix@gnu.org>
;; Keywords: processes
;; Package-Version: 20200409.2356
;; Package-Commit: 1594b76d4ad3a6e3c471d82da366226d156e6226
;; Package: cpu-sos
;; Homepage: https://github.com/oitofelix/cpu-sos
;; Version: 20200409.2056
;; Package-Requires: ((emacs "25.1"))

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;; ‘cpu-sos’ is a buffer-local minor-mode designed to track the
;; visibility of buffers associated with sub-processes or EXWM managed
;; windows and send a SIGSTOP signal to those processes (and their
;; related ones) as soon as their buffers become buried, eventually
;; reverting this by sending a SIGCONT signal as soon as they become
;; visible again.  This has the effect of limiting CPU consumption of
;; processes managed by Emacs at the user’s discretion.  Useful for
;; programs whose background processing the user is not interested in.
;; For example, web-browsers running JavaScript aggressively on
;; background for no good reason.  Other legitimate use is to forcibly
;; disable background app notifications while one’s attention focus is
;; elsewhere.

;; CAVEATS: Notice that the concept of "visibility" used by this
;; package is defined by the semantics of the value ‘visible’ given to
;; the parameter ‘ALL-FRAMES’ of function ‘get-buffer-window’.  This
;; is necessary, but not sufficient for actual view of the buffer at
;; hand.  For instance, if a buffer is in a window of a frame that is
;; totally occluded by another it still is regarded as "visible",
;; although one can’t actually see it.  Aside from imprecise detection
;; of visual interaction, there is no attempt to detect sound
;; interaction.  Therefore, buffers running music players or recording
;; programs should not have this mode enabled.  The same is true if
;; one wants to have asynchronous processes delivering notifications
;; at arrival.  Keep also in mind that trying to yank selection from
;; stopped processes is problematic.

;;; Code:


(eval-when-compile
  (require 'subr-x))

(require 'eieio)
(require 'cl-lib)
(require 'cl-extra)
(require 'exwm nil :noerror)


(defcustom cpu-sos-mode-lighter " CPUSOS"
  "String displayed in the mode line when CPU-SOS mode is on.
For instance, \" 🆘\" is a nice one."
  :type 'string
  :group 'cpu-sos)

;;;###autoload
(define-minor-mode cpu-sos-mode
  "Toggle CPU-SOS mode on or off.
With a prefix argument ARG, enable CPU-SOS mode if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
the mode if ARG is omitted or nil, and toggle it if ARG is ‘toggle’.

For a description of this mode: \\[decribe-package] cpu-sos RET."
  :group 'cpu-sos
  :init-value nil
  :lighter cpu-sos-mode-lighter
  (cond
    (cpu-sos-mode
     ;; If enabling, at least one buffer is in ‘cpu-sos-mode’.  Thus
     ;; register ‘cpu-sos’ to run at any window configuration change.
     (add-hook 'window-configuration-change-hook #'cpu-sos))
    ((null (cpu-sos--buffer-list))
     ;; If disabling, and no other buffer in ‘cpu-sos-mode’ has been
     ;; left, unhook ‘cpu-sos’.
     (remove-hook 'window-configuration-change-hook #'cpu-sos)))
  ;; Enabling or disabling should send the appropriate signals.
  (cpu-sos))

(defun cpu-sos-unload-function ()
  "Take appropriate steps to unload ‘cpu-sos’ library smoothly.
Invoked by ‘unload-feature’."
  (ignore
   ;; Return nil so ‘unload-feature’ proceeds to take the normal
   ;; unload actions.
   (mapc
    ;; Disable ‘cpu-sos-mode’ for all buffers in which it’s enabled so
    ;; ‘cpu-sos’ gets the chance to dispatch the final SIGCONT
    ;; signals.
    (lambda (buffer)
      ;; Disable ‘cpu-sos-mode’ in BUFFER.
      (with-current-buffer buffer (cpu-sos-mode -1)))
    (cpu-sos--buffer-list))))

(defun cpu-sos--buffer-list ()
  "Return list of all buffers for which ‘cpu-sos-mode’ is enabled."
  (cl-remove-if-not
   (apply-partially #'buffer-local-value 'cpu-sos-mode)
   (buffer-list)))

(defun cpu-sos ()
  "Send all appropriate signals for process of buffers in ‘cpu-sos-mode’."
  (cl-flet ((buffer-pid (buffer)
              ;; BUFFER-PID: return BUFFER’s process PID or EXWM
              ;;   window’s process PID (in this order), in case there
              ;;   is any.  Otherwise return nil.
              (or
               ;; Return BUFFER’s process PID, if there is any.
               (when-let (proc (get-buffer-process buffer))
                 (process-id proc))
               ;; Return BUFFER’s EXWM window’s process PID, if there
               ;; is any.
               (when (featurep 'exwm)
                 (ignore-errors
                   (slot-value (xcb:+request-unchecked+reply exwm--connection
                                   (make-instance 'xcb:ewmh:get-_NET_WM_PID
                                                  :window
                                                  (exwm--buffer->id buffer)))
                               'value))))))
    (let* ((sos-buffers-1st
            ;; SOS-BUFFER-1ST: all buffers that have ‘cpu-sos-mode’
            ;;   enabled and non-nil BUFFER-PIDs.
            (cl-remove-if-not #'buffer-pid (cpu-sos--buffer-list)))
           (pids
            ;; PIDS: all non-nil BUFFER-PIDs of buffers in
            ;;   SOS-BUFFER-1ST.
            (mapcar #'buffer-pid sos-buffers-1st))
           (sos-buffers-2nd
            ;; SOS-BUFFERS-2ND: buffers that haven’t ‘cpu-sos-mode’
            ;;   enabled but must be considered because they have the
            ;;   same BUFFER-PID of some buffer in SOS-BUFFER-1ST.
            (cl-remove-if-not
             (lambda (buffer)
               ;; Return non-nil if the BUFFER-PID of BUFFER is in
               ;; PIDS.
               (member (buffer-pid buffer) pids))
             ;; Omit buffers in SOS-BUFFERS-1ST.
             (cl-set-difference (buffer-list) sos-buffers-1st)))
           (sos-buffers
            ;; SOS-BUFFERS: all buffers that should be considered;
            ;;   union of SOS-BUFFERS-1ST and SOS-BUFFERS-2ND.
            (append sos-buffers-1st sos-buffers-2nd))
           (all-pids
            ;; ALL-PIDS: all PIDs in the system.
            (list-system-processes))
           (signals
            ;; SIGNALS: alist of elements (PID . SIGNAL), where each
            ;;   PID is related to a buffer in SOS-BUFFERS and is
            ;;   candidate for receiving SIGNAL.
            (cl-remove-duplicates
             ;; SIGNALS has no duplicates.
             (apply
              ;; Splice results into a plain list of pairs (PID
              ;; . SIGNAL).
              #'append
              (mapcar
               ;; For each buffer in SOS-BUFFERS collect a list in
               ;; which each element has the form (PID . SIGNAL).
               (lambda (buffer)
                 ;; Return a list with all pairs (PID . SIGNAL) where
                 ;; PID is related to BUFFER.  A PID is related to
                 ;; BUFFER, if it is related to BUFFER-PID.
                 (let ((buffer-pid
                        ;; BUFFER-PID: the BUFFER-PID of BUFFER.
                        (buffer-pid buffer))
                       (signal
                        ;; SIGNAL: signal to be sent to BUFFER
                        ;;   according to its visibility status:
                        ;;   SIGCONT if visible, SIGSTOP otherwise.
                        (if (get-buffer-window buffer 'visible)
                            'SIGCONT 'SIGSTOP)))
                   (mapcar
                    ;; Collect all pairs (PID . SIGNAL) where PID is
                    ;; related to BUFFER-PID.
                    (lambda (pid) (cons pid signal))
                    (cl-remove-if-not
                     ;; Collect PIDs in ALL-PIDS that are related to
                     ;; BUFFER-PID.
                     (lambda (pid)
                       ;; Return non-nil if PID is related to
                       ;; BUFFER-PID.  PID is related to a BUFFER-PID
                       ;; if both are the same, or if BUFFER-PID is
                       ;; either the tpgid, sess, pgrp or ppid of PID.
                       ;; See ‘process-attributes’ for their meanings.
                       ;; TODO: is this definition of "related PID"
                       ;; good enough?
                       (or (equal pid buffer-pid)
                           (when-let ((attr (process-attributes pid)))
                             (cl-some
                              (lambda (id)
                                ;; Return non-nil if process attribute
                                ;; ID of PID is equal to BUFFER-PID.
                                (when-let (rpid (alist-get id attr))
                                  (equal rpid buffer-pid)))
                              ;; Attributes to consider.
                              '(tpgid sess pgrp ppid)))))
                     all-pids))))
               sos-buffers))
             :test #'equal)))
      ;; Send SIGNALS appropriately.
      (mapc (lambda (signal-pair)
              ;; Handle SIGNAL-PAIR, which is (PID . SIGNAL),
              ;; meaning that SIGNAL is a candidate to be sent to
              ;; PID.
              (pcase signal-pair
                ;; If SIGNAL is SIGCONT, send it.
                (`(,pid . SIGCONT) (signal-process pid 'SIGCONT))
                ;; Otherwise, if it’s SIGSTOP, send it as long as
                ;; there is no SIGCONT to be sent to the same PID.
                ((and `(,pid . SIGSTOP)
                      (guard (not (member `(,pid . SIGCONT) signals))))
                 (signal-process pid 'SIGSTOP))))
            signals))))


(provide 'cpu-sos)

;;; cpu-sos.el ends here
