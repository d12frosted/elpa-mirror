;;; shell-toggle.el --- Toggle to and from the shell buffer
;;;
;;; Copyright (C) 1997, 1998 Mikael Sjödin (mic@docs.uu.se)
;;; Copyright (C) 2002, 2004 Matthieu Moy
;;; Copyright (C) 2015       Akinori MUSHA
;;;
;;; Author: Mikael Sjödin <mic@docs.uu.se>
;;;         Matthieu Moy
;;;         Akinori MUSHA <knu@iDaemons.org>
;;; URL: https://github.com/knu/shell-toggle.el
;; Package-Version: 20150226.1411
;; Package-Commit: 0d01bd9a780fdb7fe6609c552523f4498649a3b9
;;; Version: 1.3.1
;;; Keywords: processes
;;;
;;; This file is NOT part of GNU Emacs.
;;; You may however redistribute it and/or modify it under the terms of the GNU
;;; General Public License as published by the Free Software Foundation; either
;;; version 2, or (at your option) any later version.
;;;
;;; The file is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; Commentary:
;;; ----------------------------------------------------------------------
;;; Description:
;;;
;;; Provides the command shell-toggle which toggles between the
;;; shell buffer and whatever buffer you are editing.
;;;
;;; This is done in an "intelligent" way.  Features are:
;;; o Starts a shell if none is existent.
;;; o Minimum distortion of your window configuration.
;;; o When done in the shell-buffer you are returned to the same window
;;;   configuration you had before you toggled to the shell.
;;; o If you desire, you automagically get a "cd" command in the shell to the
;;;   directory where your current buffers file exists; just call
;;;   shell-toggle-cd instead of shell-toggle.
;;; o You can conveniently choose if you want to have the shell in another
;;;   window or in the whole frame.  Just invoke shell-toggle again to get the
;;;   shell in the whole frame.
;;;
;;; This file has been tested under Emacs 20.2.
;;;
;;; This file can be obtained from http://www.docs.uu.se/~mic/emacs.html

;;; ----------------------------------------------------------------------
;;; Installation:
;;;
;;; o Place this file in a directory in your 'load-path.
;;; o Put the following in your .emacs file:
;;;   (autoload 'shell-toggle "shell-toggle"
;;;    "Toggles between the shell buffer and whatever buffer you are editing."
;;;    t)
;;;   (autoload 'shell-toggle-cd "shell-toggle"
;;;    "Pops up a shell-buffer and insert a \"cd <file-dir>\" command." t)
;;;   (global-set-key [M-f1] 'shell-toggle)
;;;   (global-set-key [C-f1] 'shell-toggle-cd)
;;; o Restart your Emacs.  To use shell-toggle just hit M-f1 or C-f1
;;;
;;; For a list of user options look in code below.
;;;

;;; ----------------------------------------------------------------------
;;; BUGS:
;;;  No reported bugs as of today

;;; ----------------------------------------------------------------------
;;; Thanks to:
;;;   Christian Stern <Christian.Stern@physik.uni-regensburg.de> for helpful
;;;   suggestions.

;;; (incomplete) changelog
;;
;; Version 1.3.1 (January 4, 2015)
;; - Check `explicit-shell-file-name' and $ESHELL.
;; - Add customize knobs.
;;
;; Version 1.3 (January 10, 2004)
;; - Port to eshell
;;
;; Version 1.2
;; - Added the possibility to use different shells.

;;; Code:

(require 'term)

(declare-function ido-get-buffers-in-frames "ido")
(declare-function eshell-send-input "esh-mode")

(defgroup shell-toggle nil
  "Toggle to and from the shell buffer."
  :group 'shell)

(defvar shell-toggle-shell-buffer nil
  "Buffer of the shell.")

(defcustom shell-toggle-goto-eob t
  "If non-nil `shell-toggle' moves the point to the end of the shell-buffer.

When `shell-toggle-cd' is called the point is always moved to the
end of the shell-buffer."
  :group 'shell-toggle
  :type 'boolean)

(defcustom shell-toggle-automatic-cd t
  "If non-nil `shell-toggle-cd' will send the \"cd\" command to the shell.

If nil `shell-toggle-cd' will only insert the \"cd\" command in
the shell-buffer.  Leaving it to the user to press RET to send
the command to the shell."
  :group 'shell-toggle
  :type 'boolean)

(defcustom shell-toggle-launch-shell 'shell-toggle-ansi-term
  "The command to run to launch a shell.

This must be a function returning a buffer.  (The newly created
shell buffer)

Currently supported are 'shell and 'shell-toggle-ansi-term, and
'shell-toggle-eshell"
  :group 'shell-toggle
  :type '(choice :tag "Command to launch a shell"
		 (const :tag "ansi-term" shell-toggle-ansi-term)
		 (const :tag "eshell" shell-toggle-eshell)
                 function))

(defcustom shell-toggle-full-screen-window-only nil
  "If non-nil, `shell-toggle' will switch between full screen
shell window, and back, with no intermediate step."
  :group 'shell-toggle
  :type 'boolean)

(defcustom shell-toggle-term-shell-to-launch nil
  "If non-nil, is the shell invoked by `shell-toggle-ansi-term'."
  :group 'shell-toggle
  :type '(choice (const :tag "None" nil) file))

(defun shell-toggle-run-this-shell ()
  (or shell-toggle-term-shell-to-launch
      explicit-shell-file-name
      (getenv "ESHELL")
      (getenv "SHELL")
      "/bin/sh"))

(defun shell-toggle-ansi-term ()
  (when (and shell-toggle-shell-buffer (not (get-buffer-process shell-toggle-shell-buffer)))
    (kill-buffer shell-toggle-shell-buffer))
  (ansi-term (shell-toggle-run-this-shell)))

(defun shell-toggle-eshell ()
  (eshell))

(defcustom shell-toggle-leave-buffer-hook nil
  "Hook run before leaving the buffer to switch to the shell."
  :group 'shell-toggle
  :type 'hook)

(defcustom shell-toggle-goto-shell-hook nil
  "Hook run after switching to the shell buffer."
  :group 'shell-toggle
  :type 'hook)

;;; ======================================================================
;;; Commands:

(defun shell-toggle-this-is-the-shell-buffer () (interactive)
  (setq shell-toggle-shell-buffer (current-buffer)))

;;;###autoload
(defun shell-toggle-cd ()
  "Call `shell-toggle' with a prefix argument.
See command `shell-toggle'."
  (interactive)
  (shell-toggle t))

;;;###autoload
(defun shell-toggle (make-cd)
  "Toggle between the shell buffer and whatever buffer you are editing.
With a prefix argument MAKE-CD also insert a \"cd DIR\" command
into the shell, where DIR is the directory of the current buffer.

Call twice in a row to get a full screen window for the shell buffer.

When called in the shell buffer returns you to the buffer you were editing
before calling this the first time.

Options: `shell-toggle-goto-eob'"
  (interactive "P")
  ;; Try to decide on one of three possibilities:
  ;; If not in shell-buffer, switch to it.
  ;; If in shell-buffer and called twice in a row, delete other windows
  ;; If in shell-buffer and not called twice in a row, return to state before
  ;;  going to the shell-buffer
  (if (eq (current-buffer) shell-toggle-shell-buffer)
      (if (and (or (eq last-command 'shell-toggle)
		   (eq last-command 'shell-toggle-cd))
	       (not (eq (count-windows) 1)))
	  (delete-other-windows)
	(shell-toggle-buffer-return-from-shell))
    (progn
      (shell-toggle-buffer-goto-shell make-cd)
      (if shell-toggle-full-screen-window-only (delete-other-windows)))))

;;; ======================================================================
;;; Internal functions and declarations

(defvar shell-toggle-pre-shell-win-conf nil
  "Contains the window configuration before the shell buffer was selected.")

(defvar shell-toggle-pre-shell-selected-frame nil
  "Contains the frame selected before the shell buffer was selected.")

(defun shell-toggle-buffer-return-from-shell ()
  "Restore the window configuration used before switching the shell buffer.
If no configuration has been stored, just burry the shell buffer."
  (if (window-configuration-p shell-toggle-pre-shell-win-conf)
      (progn
	(set-window-configuration shell-toggle-pre-shell-win-conf)
	(setq shell-toggle-pre-shell-win-conf nil)
	(bury-buffer shell-toggle-shell-buffer))
    (bury-buffer))
  (when (framep shell-toggle-pre-shell-selected-frame)
    (select-frame-set-input-focus
     shell-toggle-pre-shell-selected-frame))
  )

;; borrowed from ido-buffer-window-other-frame
(defun shell-toggle-buffer-window-other-frame  (buffer)
  ;; Return window pointer if BUFFER is visible in another frame.
  ;; If BUFFER is visible in the current frame, return nil.
  (let ((blist (ido-get-buffers-in-frames 'current)))
    ;;If the buffer is visible in current frame, return nil
    (if (member buffer blist)
	nil
      ;;  maybe in other frame or icon
      (get-buffer-window buffer 0) ; better than 'visible
      )))

(defun shell-toggle-buffer-goto-shell (make-cd)
  "Switch other window to the shell buffer.
If no shell buffer exists start a new shell and switch to it in
other window.  If argument MAKE-CD is non-nil, insert a \"cd
DIR\" command into the shell, where DIR is the directory of the
current buffer.

Stores the window configuration before creating and/or switching window."
  (setq shell-toggle-pre-shell-win-conf
	(current-window-configuration))
  (setq shell-toggle-pre-shell-selected-frame
	(selected-frame))
  (run-hooks 'shell-toggle-leave-buffer-hook)
  (let ((shell-buffer shell-toggle-shell-buffer)
	(cd-command
	 ;; Find out which directory we are in (the method differs for
	 ;; different buffers)
	 (and make-cd
              (or (and (buffer-file-name)
                       (file-name-directory (buffer-file-name))
                       (concat "cd " (shell-quote-argument
                                      (file-name-directory (buffer-file-name)))))
                  (and list-buffers-directory
                       (concat "cd " (shell-quote-argument
                                      list-buffers-directory)))
                  (and default-directory
                       (concat "cd " (shell-quote-argument
                                      default-directory)))))))

    ;; Switch to an existing shell if one exists, otherwise switch to another
    ;; window and start a new shell
    (run-hooks 'shell-toggle-leave-buffer-hook)
    (if (buffer-live-p shell-buffer)
	  ;; buffer exists, let's see where it is.
	  (let ((in-current-frame
		 (get-buffer-window shell-buffer nil)))
	    (if in-current-frame
		(switch-to-buffer-other-window shell-buffer)
	      (let ((buffer-window
		     (get-buffer-window shell-buffer t)))
		(if buffer-window ;; buffer is active in other frame
		    (progn
		      (select-frame-set-input-focus (window-frame buffer-window))
		      (select-window buffer-window))
		  ;; buffer is shown nowhere
		  (switch-to-buffer-other-window shell-buffer)))))
      ;; Sometimes an error is generated when I call `shell'
      ;; (it has to do with my shell-mode-hook which inserts text into the
      ;; newly created shell-buffer and thats not allways a good idea).
	      (shell-toggle-buffer-switch-to-other-window)
      (condition-case the-error
	  (setq shell-toggle-shell-buffer
		(funcall shell-toggle-launch-shell))
	(error (switch-to-buffer shell-toggle-shell-buffer))))
    (if (or cd-command shell-toggle-goto-eob)
	(goto-char (point-max)))
    (if (not (get-buffer-process (current-buffer)))
        (setq shell-toggle-shell-buffer
              (funcall shell-toggle-launch-shell)))
    (if cd-command
	(progn
          (cond ((eq shell-toggle-launch-shell 'shell)
                 (progn
                   (insert " ")
                   (beginning-of-line)
                   (kill-line)))
                ((eq shell-toggle-launch-shell
                     'shell-toggle-ansi-term)
                 (term-send-raw-string "\^u"))
                ((eq shell-toggle-launch-shell
                     'shell-toggle-eshell))
                (t (message "Shell type not recognized")))
	  (insert cd-command)
	  (if shell-toggle-automatic-cd
	      (cond ((eq shell-toggle-launch-shell 'shell)
		     (comint-send-input))
		    ((eq shell-toggle-launch-shell
			 'shell-toggle-ansi-term)
		     (term-send-input))
                    ((eq shell-toggle-launch-shell
                         'shell-toggle-eshell)
                     (eshell-send-input))
		    (t (message "Shell type not recognized")))
	    )
	  ))
    (run-hooks 'shell-toggle-goto-shell-hook)
    ))

(defun shell-toggle-buffer-switch-to-other-window ()
  "Switch to other window.
If the current window is the only window in the current frame,
create a new window and switch to it.

\(This is less intrusive to the current window configuration than
`switch-buffer-other-window')"
  (let ((this-window (selected-window)))
    (other-window 1)
    ;; If we did not switch window then we only have one window and need to
    ;; create a new one.
    (if (eq this-window (selected-window))
	(progn
	  (split-window-vertically)
          (other-window 1)))))

(provide 'shell-toggle)

;;; shell-toggle.el ends here
