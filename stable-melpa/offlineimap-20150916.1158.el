;;; offlineimap.el --- Run OfflineIMAP from Emacs

;; Copyright (C) 2010 Julien Danjou
;; Copyright (C) 2014 Benjamin Barenblat

;; Author: Julien Danjou <julien@danjou.info>
;; URL: http://julien.danjou.info/offlineimap-el.html

;; This file is NOT part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; M-x offlineimap

;; We need comint for `comint-truncate-buffer'
(require 'comint)

(defgroup offlineimap nil
  "Run OfflineIMAP."
  :group 'comm)

(defcustom offlineimap-buffer-name "*OfflineIMAP*"
  "Name of the buffer used to run offlineimap."
  :group 'offlineimap
  :type 'string)

(defcustom offlineimap-command "offlineimap -u machineui"
  "Command to run to launch OfflineIMAP."
  :group 'offlineimap
  :type 'string)

(defcustom offlineimap-buffer-maximum-size comint-buffer-maximum-size
  "The maximum size in lines for OfflineIMAP buffer."
  :group 'offlineimap
  :type 'integer)

(defcustom offlineimap-enable-mode-line-p '(member
                                            major-mode
                                            '(offlineimap-mode
                                              gnus-group-mode
                                              wl-folder-mode))
  "Whether enable OfflineIMAP mode line status display.
This form is evaluated and its return value determines if the
OfflineIMAP status should be displayed in the mode line."
  :group 'offlineimap)

(defcustom offlineimap-mode-line-style 'symbol
  "Set what to display in mode-line.
If set to 'symbol, it will only display
`offlineimap-mode-line-symbol' with different colors based on
what OfflineIMAP is doing. If set to 'text, it will display the
action as a text in color instead of a single symbol."
  :group 'offlineimap
  :type '(choice (const :tag "Symbol" symbol)
                 (const :tag "Action text" text)))

(defcustom offlineimap-mode-line-symbols '((run . "✉")
                                           (stop .  "↻")
                                           (exit .  "×")
                                           (signal . "⚑")
                                           (open .  "⊙")
                                           (listen . "⌥")
                                           (closed . "●")
                                           (connect . "…")
                                           (failed . "⌁"))
  "Symbols used to display OfflineIMAP status in mode-line.
These are used when `offlineimap-mode-line-style' is set to
`symbol'."
  :group 'offlineimap
  :type '(repeat (cons :tag "Mode line symbol" (symbol :tag "Signal") (string :tag "Symbol"))))

(defcustom offlineimap-mode-line-text "OfflineIMAP: "
  "Text used to display OfflineIMAP status in mode-line."
  :group 'offlineimap
  :type 'string)

(defcustom offlineimap-timestamp nil
  "Timestamp to add at the beginning of each OffsyncIMAP line."
  :type 'string
  :group 'offlineimap)

(defcustom offlineimap-event-hooks nil
  "Hooks run when OfflineIMAP state changes."
  :type 'hook
  :group 'offlineimap)

(defvar offlineimap-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") 'offlineimap-quit)
    (define-key map (kbd "g") 'offlineimap-resync)
    (define-key map (kbd "K") 'offlineimap-kill)
    map)
  "Keymap for offlineimap-mode.")

(defface offlineimap-msg-acct-face
  '((t (:foreground "purple")))
  "Face used to highlight acct lines."
  :group 'offlineimap)

(defface offlineimap-msg-connecting-face
  '((t (:foreground "gray")))
  "Face used to highlight connecting lines."
  :group 'offlineimap)

(defface offlineimap-msg-syncfolders-face
  '((t (:foreground "blue")))
  "Face used to highlight syncfolders lines."
  :group 'offlineimap)

(defface offlineimap-msg-syncingfolders-face
  '((t (:foreground "cyan")))
  "Face used to highlight syncingfolders lines."
  :group 'offlineimap)

(defface offlineimap-msg-skippingfolder-face
  '((t (:foreground "cyan")))
  "Face used to highlight skippingfolder lines."
  :group 'offlineimap)

(defface offlineimap-msg-loadmessagelist-face
  '((t (:foreground "green")))
  "Face used to highlight loadmessagelist lines."
  :group 'offlineimap)

(defface offlineimap-msg-syncingmessages-face
  '((t (:foreground "blue")))
  "Face used to highlight syncingmessages lines."
  :group 'offlineimap)

(defface offlineimap-msg-copyingmessage-face
  '((t (:foreground "orange")))
  "Face used to highlight copyingmessage lines."
  :group 'offlineimap)

(defface offlineimap-msg-deletingmessages-face
  '((t (:foreground "red")))
  "Face used to highlight deletingmessages lines."
  :group 'offlineimap)

(defface offlineimap-msg-deletingmessage-face
  '((t (:foreground "red")))
  "Face used to highlight deletingmessage lines."
  :group 'offlineimap)

(defface offlineimap-msg-addingflags-face
  '((t (:foreground "yellow")))
  "Face used to highlight addingflags lines."
  :group 'offlineimap)

(defface offlineimap-msg-deletingflags-face
  '((t (:foreground "pink")))
  "Face used to highlight deletingflags lines."
  :group 'offlineimap)

(defface offlineimap-error-face
  '((t (:foreground "red" :weight bold)))
  "Face used to highlight status when offlineimap is stopped."
  :group 'offlineimap)

(defvar offlineimap-mode-line-string nil
  "Variable showed in mode line to display OfflineIMAP status.")

(put 'offlineimap-mode-line-string 'risky-local-variable t) ; allow properties

(defun offlineimap-make-buffer ()
  "Get the offlineimap buffer."
  (let ((buffer (get-buffer-create offlineimap-buffer-name)))
    (with-current-buffer buffer
      (offlineimap-mode))
    buffer))

(defun offlineimap-propertize-face (msg-type action text)
  "Propertize TEXT with correct face according to MSG-TYPE and ACTION."
  (let* ((face-sym (intern (concat "offlineimap-" msg-type "-" action "-face"))))
    (if (facep face-sym)
        (propertize text 'face face-sym)
      text)))

(defun offlineimap-switch-to-buffer (e)
  "Go to OfflineIMAP buffer."
  (interactive "e")
  (save-selected-window
    (select-window
     (posn-window (event-start e)))
    (switch-to-buffer (get-buffer offlineimap-buffer-name))))

(defvar offlineimap-mode-line-map
  (let ((map (make-sparse-keymap)))
    (define-key map (vector 'mode-line 'mouse-2) 'offlineimap-switch-to-buffer)
    map)
  "Keymap used in mode line.")

(defun offlineimap-update-mode-line (process)
  "Update mode line information about OfflineIMAP PROCESS."
  (setq offlineimap-mode-line-string
        (propertize
         (concat " [" offlineimap-mode-line-text
                 (let ((status (process-status process)))
                   (if (eq status 'run)
                       (let ((msg-type (process-get process :last-msg-type))
                             (action (process-get process :last-action)))
                         (offlineimap-propertize-face msg-type action
                                                      (if (eq offlineimap-mode-line-style 'text)
                                                          action
                                                        (cdr (assoc 'run offlineimap-mode-line-symbols)))))
                     (propertize (or (and (eq offlineimap-mode-line-style 'symbol)
                                          (cdr (assoc status offlineimap-mode-line-symbols)))
                                     (symbol-name status))
                                 'face 'offlineimap-error-face)))
                 "]")
         'mouse-face 'mode-line-highlight
         'help-echo "mouse-2: Go to OfflineIMAP buffer"
         'local-map offlineimap-mode-line-map))
  (force-mode-line-update))

(defun offlineimap-insert (process text)
  "Insert TEXT in PROCESS buffer."
  (let ((buffer (process-buffer process)))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (let ((inhibit-read-only t))
          ;; If the cursor is at the end, append text like we would be in
          ;; "tail".
          (if (eq (point) (point-max))
              (progn
                (when offlineimap-timestamp
                  (insert (format-time-string offlineimap-timestamp)))
                (insert text)
                (set-marker (process-mark process) (point)))
            ;; But if not, let the cursor where it is, so `save-excursion'.
            (save-excursion
              (goto-char (point-max))
              (when offlineimap-timestamp
                (insert (format-time-string offlineimap-timestamp)))
              (insert text)
              (set-marker (process-mark process) (point)))))))))

(defun offlineimap-process-filter (process msg)
  "Filter PROCESS output MSG."
  (dolist (msg-line (nbutlast (split-string msg "[\n\r]+")))
    (let* ((msg-data (split-string msg-line ":"))
           (msg-type (nth 0 msg-data))
           (action (nth 1 msg-data))
           (thread-name (nth 2 msg-data))
           (buffer (process-buffer process)))
      (when (buffer-live-p buffer)
        (with-current-buffer buffer
          (offlineimap-insert process
                              (offlineimap-propertize-face
                               msg-type
                               action
                               (concat thread-name "::" action "\n")))
          (let ((comint-buffer-maximum-size offlineimap-buffer-maximum-size))
            (comint-truncate-buffer))))
      (process-put process :last-msg-type msg-type)
      (process-put process :last-action action)
      (offlineimap-update-mode-line process)
      (run-hook-with-args 'offlineimap-event-hooks msg-type action))))

(defun offlineimap-process-sentinel (process state)
  "Monitor STATE change of PROCESS."
  (offlineimap-insert process (concat "*** Process " (process-name process) " " state))
  (offlineimap-update-mode-line process)
  (run-hook-with-args 'offlineimap-event-hooks state))

(defun offlineimap-mode-line ()
  "Return a string to display in mode line."
  (when (eval offlineimap-enable-mode-line-p)
    offlineimap-mode-line-string))

;;;###autoload
(defun offlineimap ()
  "Start OfflineIMAP."
  (interactive)
  (let* ((buffer (offlineimap-make-buffer)))
    (unless (get-buffer-process buffer)
      (let ((process (start-process-shell-command
                      "offlineimap"
                      buffer
                      offlineimap-command)))
        (set-process-filter process 'offlineimap-process-filter)
        (set-process-sentinel process 'offlineimap-process-sentinel))))
  (add-to-list 'global-mode-string '(:eval (offlineimap-mode-line)) t))

(defun offlineimap-quit ()
  "Quit OfflineIMAP."
  (interactive)
  (kill-buffer (get-buffer offlineimap-buffer-name)))

(defun offlineimap-resync ()
  "Send a USR1 signal to OfflineIMAP to force accounts synchronization."
  (interactive)
  (signal-process (get-buffer-process (get-buffer offlineimap-buffer-name)) 'SIGUSR1))

(defun offlineimap-kill (&optional arg)
  "Send a TERM signal to OfflineIMAP."
  (interactive "P")
  (let ((sig (if arg 'SIGKILL 'SIGTERM)))
    (signal-process (get-buffer-process (get-buffer offlineimap-buffer-name)) sig)))

(define-derived-mode offlineimap-mode fundamental-mode "OfflineIMAP"
  "A major mode for OfflineIMAP interaction."
  :group 'comm
  (setq buffer-read-only t)
  (setq buffer-undo-list t))

(provide 'offlineimap)

;;; offlineimap.el ends here
