;;; turnip.el --- Interacting with tmux from Emacs

;; Copyright (C) 2014 Johann Klähn

;; Author: Johann Klähn <kljohann@gmail.com>

;; Keywords: terminals, tools
;; Package-Version: 20150309.629
;; Package-Commit: 2fd32562fc6fc1cda6d91aa939cfb29f9b16e9de
;; Package-Requires: ((dash "2.6.0") (s "1.9.0"))

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

;; Turnip is a package to ease interacting with a tmux session from Emacs.
;; Its scope and philosophy is inspired by Tim Pope's vim-tbone.

;;; Code:

(require 'dash)
(require 's)

;;;; Custom Options

(defgroup turnip nil
  "Interacting with tmux from Emacs."
  :group 'tools)

(defcustom turnip-send-region-before-keys nil
  "Keys to send to a tmux pane before sending any other text.
This may be useful to reset REPLs to a known state, for example.
See `turnip-send-region' for where this is used."
  :group 'turnip
  :type '(repeat (string :tag "Key name or text")))

(defcustom turnip-send-region-prepare-hook nil
  "Hook to run when sending text to tmux.
The hook will run on a temporary buffer containing the text to be sent.
The original buffer and the start and end character positions will be
passed as a parameters.
This may be useful to unindent code intended for a python REPL, for example."
  :group 'turnip
  :type 'hook)

(defcustom turnip-output-buffer-name "*turnip-output*"
  "Name of buffer where output of tmux commands is put."
  :group 'turnip
  :type 'string)

;;;; Internal Variables

(defvar turnip:attached-session nil
  "Name of the tmux session turnip is currently attached to.
Can be changed using `turnip-attach'.")
(defvar turnip:last-pane nil
  "Pane id of the last pane used with `turnip-send-region'.")
(defvar turnip:special-panes
  '("last" "top" "bottom" "left" "right"
    "top-left" "top-right" "bottom-left" "bottom-right")
  "Special values that may be used instead of a pane index.")

;;;; Utility Functions

(defun turnip:session (&optional session silent)
  "Fall back to `turnip:attached-session' if SESSION is nil.
If both session values and SILENT are nil, display an error."
  (or session
      turnip:attached-session
      (unless silent
        (user-error "No session specified or attached to"))))

;;;; tmux Panes

(defun turnip:pane-id-p (target)
  "Return t if TARGET has the form of a pane id."
  (and t (s-match "^%[0-9]+$" target)))

(defun turnip:format-pane-id (pane &optional fmt)
  "Format PANE according to the tmux format string FMT."
  (unless fmt
    (setq fmt "#S:#W.#P"))
  (ignore-errors (turnip:call "display-message" "-p" "-t" pane fmt)))

(defun turnip:panes-displaying-emacs ()
  "Return a list of tmux panes that contain frames of this emacs session."
  (->> (frame-list)
    (-map (lambda (frame) (getenv "TMUX_PANE" frame)))
    (-uniq)
    (-filter #'identity)))

(defun turnip:qualify (target &optional session)
  "Prefix TARGET with SESSION or `turnip:attached-session' if it has
no prefix yet and isn't a pane id."
  (let ((maybe-session (turnip:session session 'silent)))
    (if (not maybe-session)
        target
      (setq target (s-chop-prefix ":" target))
      (when (-contains? turnip:special-panes target)
        (setq target (s-prepend "." target)))
      (if (s-match ":\\|^%" target)
          target
        (concat maybe-session ":" target)))))

(defun turnip:pane-id (target &optional session)
  "Return the unique pane id of TARGET in SESSION if it exists, else nil."
  (if (s-prefix? "%" target)
      ;; Check if pane exists, else return nil.
      (if (-contains?
           (turnip:call->lines "list-panes" "-a" "-F" "#{pane_id}")
           target)
          target)

    (setq target (turnip:qualify target session))

    (if (s-suffix? ".last" target)
        ;; To determine the last pane we need to temporarily switch to it.
        (let* ((window (s-chop-suffix ".last" target))
               (lines
                (turnip:call->lines
                 "select-pane" "-t" window "-l"
                 ";" "list-panes" "-t" window "-F" "#{pane_id} #{pane_active}"
                 ";" "select-pane" "-t" window "-l"))
               (active (-first (lambda (line) (s-suffix? "1" line)) lines)))
          (when active
            (car (s-split "\\s-+" active))))
      (turnip:format-pane-id target "#{pane_id}"))))

(defun turnip:normalize-and-check-target-pane (target)
  "Convert TARGET to a pane id and check that writing to it is sensible.
See `turnip:pane-id' and `turnip:panes-displaying-emacs'."
  (let ((pane (turnip:pane-id target)))
    (when (not pane)
      (user-error "Pane '%s' not found" target))
    (when (-contains? (turnip:panes-displaying-emacs) pane)
      (user-error "Refusing to write to Emacs pane '%s'" pane))
    pane))

;;;; Calling tmux Processes

(defun turnip:format-status (status &optional extra)
  "Format the exit status of a tmux call for display to the user.
See the return value of `call-process' for possible values for STATUS.
EXTRA may contain further information that is appended to the message."
  (setq extra (if extra (s-prepend ": " extra) ""))
  (cond
   ((stringp status)
    (format "(tmux killed by signal %s%s)" status extra))
   ((not (equal 0 status))
    (format "(tmux failed with code %d%s)" status extra))
   (t (format "(tmux succeeded%s)" extra))))

(defun turnip:call (&rest arguments)
  "Call tmux with the specified arguments."
  (with-temp-buffer
    (let ((status (apply #'call-process "tmux" nil t nil arguments))
          (output (s-chomp (buffer-string))))
      (unless (equal 0 status)
        (error (turnip:format-status status output)))
      output)))

(defun turnip:call->lines (&rest arguments)
  "Call tmux with the specified arguments.
The command output will be split on newline characters."
  (s-lines (apply #'turnip:call arguments)))

;;;; Completion Data Providers

(defun turnip:list-sessions ()
  "Return a list of tmux sessions."
  (turnip:call->lines "list-sessions" "-F" "#S"))

(defun turnip:list-windows (&optional session)
  "Return a list of tmux windows.
If SESSION is provided or `turnip:attached-session' is set, windows from that
session are included without a session prefix."
  (let ((maybe-session (turnip:session session 'silent)))
    (append (when maybe-session
              (turnip:call->lines "list-windows" "-F" "#W" "-t" maybe-session))
            (turnip:call->lines "list-windows" "-F" "#S:#W" "-a"))))

(defun turnip:list-panes (&optional session)
  "Return a list of tmux panes.
If SESSION is provided or `turnip:attached-session' is set, panes from that
session are included without a session prefix."
  (let ((maybe-session (turnip:session session 'silent)))
    (append (when maybe-session
              (turnip:call->lines "list-panes" "-F" "#W.#P" "-s" "-t" maybe-session))
            (turnip:call->lines "list-panes" "-F" "#S:#W.#P" "-a")
            turnip:special-panes)))

(defun turnip:list-clients ()
  "Return a list of clients attached to tmux."
  (turnip:call->lines "list-clients" "-F" "#{client_tty}"))

(defun turnip:list-buffers ()
  "Return a list of tmux buffers."
  (-map #'number-to-string
        (number-sequence
         0 (1- (length (turnip:call->lines "list-buffers"))))))

(defun turnip:parse-command-options (line)
  "Parse command line options as formatted in tmux' list-commands output."
  (let
      ((option-names
        (->> line
          (s-match-strings-all (rx (any "[|") "-" (group (+ word))))
          (-map #'cadr)
          (apply #'concat)))
       (option-arguments
        (-when-let*
            ((matches (s-match-strings-all
                       (rx (any "[|")
                           (group "-" word)
                           (+ whitespace)
                           (group (+ (not (any "|]"))))
                           (any "|]"))
                       line)))
          (-map
           (lambda (match)
             (cons (cadr match) (-last-item match)))
           matches))))
    (cons option-names option-arguments)))

(defun turnip:parse-command (line)
  "Parse LINE as formatted in tmux' list-commands output."
  (-when-let*
      ((match (s-match
               (rx bol
                   ;; command name
                   (group (+ (not (any whitespace))))
                   ;; rest (alias, options)
                   (optional (+ whitespace)
                             (group (+ nonl)))
                   eol)
               line))
       (cmd (cadr match))
       (rest (-last-item match)))
    (let ((options (turnip:parse-command-options rest))
          (alias (cadr (s-match
                        (rx "(" (group (+? nonl)) ")")
                        rest))))
      (append
       (list (cons cmd options))
       (when alias
         (list (cons alias options)))))))

(defun turnip:list-commands ()
  (let ((lines (turnip:call->lines "list-commands")))
    (apply #'append (mapcar #'turnip:parse-command lines))))

(defun turnip:completions-for-argument (arg &optional session)
  (cond
   ((s-suffix? "-pane" arg) (turnip:list-panes session))
   ((s-suffix? "-window" arg) (turnip:list-windows session))
   ((s-suffix? "-session" arg) (turnip:list-sessions))
   ((s-suffix? "-client" arg) (turnip:list-clients))
   ((s-equals? "buffer-index" arg) (turnip:list-buffers))))

(defun turnip:normalize-argument-type (arguments current)
  (when current
    (or (let ((cmd (car arguments)))
          (when (s-prefix? "target" current)
            (cond
             ((-contains? '("list-panes" "lsp") cmd)
              (if (-contains? arguments "-s")
                  "target-session"
                "target-window"))
             ((-contains? '("set-option" "set" "show-options" "show") cmd)
              (if (-contains? arguments "-w")
                  "target-window"
                "target-session")))))
        current)))

(defun turnip:normalize-argument-value (argument value &optional session)
  (cond
   ((or (s-suffix? "-pane" argument)
        (s-suffix? "-window" argument))
    (turnip:qualify value session))
   (t value)))

(defun turnip:prompt-for-command (&optional initial-arguments session)
  "Interactively prompts for a tmux command to execute.
See `turnip-command'."
  (-when-let* ((commands (turnip:list-commands))
               (command-names (-map #'car commands))
               (choice (or (pop initial-arguments)
                           (completing-read "tmux " command-names nil t))))
    (let* ((options (cdr (assoc choice commands)))
           (option-names
            (-map
             (lambda (char)
               (concat "-" (list char)))
             (car options)))
           (option-arguments (cdr options))
           (arguments))

      (while (not (s-equals? choice ""))
        (setq arguments (-snoc arguments choice))
        (setq option-names
              (-remove
               (lambda (maybe-flag)
                 (s-equals? choice maybe-flag))
               option-names))
        (let ((prompt (format "tmux %s " (s-join " " arguments)))
              (takes-argument
               (turnip:normalize-argument-type
                arguments (cdr (assoc choice option-arguments)))))
          (if (not takes-argument)
              (setq choice (or (pop initial-arguments)
                               (completing-read prompt option-names)))
            (setq choice "")
            (while (s-equals? choice "")
              (setq choice
                    (or (pop initial-arguments)
                        (completing-read
                         (format "%s[%s] " prompt takes-argument)
                         (turnip:completions-for-argument takes-argument session)))))
            (setq choice
                  (turnip:normalize-argument-value
                   takes-argument choice session)))))
      arguments)))

;; FIXME: Maybe pass a session argument to pane-id?
(defun turnip:send-keys (target &rest keys)
  (setq target (turnip:normalize-and-check-target-pane target))
  (apply #'turnip:call "send-keys" "-t" target "" keys))

(defun turnip:send-text (target &rest strings)
  (setq target (turnip:normalize-and-check-target-pane target))
  (apply #'turnip:call "send-keys" "-l" "-t" target "" strings))

;;;###autoload
(defun turnip-attach (session)
  "Prompt for and attach to a particular tmux session.
If only one session is available, it will be used without displaying a prompt.
This also resets the last used pane."
  (interactive
   (let* ((sessions (turnip:list-sessions))
          (choice (if (= (length sessions) 1)
                      (car sessions)
                    (completing-read "Session: " sessions nil t))))
     (when (s-equals? choice "")
       (user-error "No session name provided"))
     (list choice)))

  (setq turnip:attached-session session
        turnip:last-pane nil))

;;;###autoload
(defun turnip-choose-pane (target)
  "Prompt for a tmux pane if called interactively.
The last used pane is saved and used as a default on subsequent calls. "
  (interactive
   (let* ((default (turnip:format-pane-id turnip:last-pane "#S:#W.#P"))
          (prompt (if default
                      (concat "Pane [" default "]: ")
                    "Pane: "))
          (choice (completing-read prompt (turnip:list-panes)
                                   nil t nil nil default)))

     (when (s-equals? choice "")
       (user-error "No target pane provided"))
     (list choice)))

  (setq turnip:last-pane (turnip:normalize-and-check-target-pane target)))

;;;###autoload
(defun turnip-command (&rest initial-arguments)
  "Interactively prompts for a tmux command to execute.
The command will be built in several steps.  First the user can choose
the tmux command to run.  In the next prompts completion for the options
of this command is provided.  The command will be executed once the user
gives an empty answer."
  (interactive)
  (let* ((arguments (turnip:prompt-for-command initial-arguments))
         (command (car arguments))
         (argument-types (cddr (assoc command (turnip:list-commands)))))
    (when turnip:attached-session
      (when (-contains? '("list-panes" "lsp") command)
        (unless (or (-contains? arguments "-a")
                    (-contains? arguments "-t"))
          (setq arguments (-snoc arguments "-s" "-t" turnip:attached-session))))
      (-when-let* ((option (rassoc "target-session" argument-types))
                   (flag (car option)))
        (unless (or (-contains? arguments flag)
                    (-contains? arguments "-a"))
          (setq arguments (-snoc arguments flag turnip:attached-session)))))
    (with-current-buffer (get-buffer-create turnip-output-buffer-name)
      (setq buffer-read-only nil)
      (erase-buffer)
      (let ((status (apply #'call-process "tmux" nil t nil arguments)))
        (setq mode-line-process
              (format "tmux %s%s" (s-join " " arguments)
                      (cond
                       ((stringp status)
                        (format " => Signal [%s]" status))
                       ((not (equal 0 status))
                        (format " => Exit [%d]" status))
                       (t ""))))
        (if (> (point-max) (point-min))
            (display-message-or-buffer (current-buffer))
          (message (turnip:format-status status)))))))

;;;###autoload
(defun turnip-yank-from-buffer (&optional buffer)
  "Yank from tmux buffer with index BUFFER.
If no argument is provided the paste-buffer is used."
  (interactive
   (let* ((buffers (turnip:call->lines "list-buffers" "-F" "#{line}: #{buffer_sample}"))
          (choice (completing-read "Buffer: " buffers nil 'confirm)))
     (list
      (when (string-match "^[0-9]+" choice)
        (match-string-no-properties 0 choice)))))

  (insert
   (apply #'turnip:call "show-buffer"
          (when buffer (list  "-b" buffer)))))

;;;###autoload
(defun turnip-send-region-to-buffer (start end &optional tmux-buffer with-buffer)
  "Send region to a tmux buffer.
If no mark is set defaults to send the whole buffer."
  (interactive
   (let ((choice (completing-read "Buffer: " (turnip:list-buffers))))
     (append
      (if (use-region-p)
          (list (region-beginning) (region-end))
        (list (point-min) (point-max)))
      (list choice))))

  (when (s-equals? tmux-buffer "")
    (setq tmux-buffer nil))

  (let ((buffer (current-buffer))
        (temp (make-temp-file "turnip")))
    (unwind-protect
        (progn
          (with-temp-file temp
            (insert-buffer-substring-no-properties buffer start end)
            (run-hook-with-args
             'turnip-send-region-prepare-hook buffer start end))
          (apply #'turnip:call "load-buffer"
                 (-snoc (when tmux-buffer (list "-b" tmux-buffer)) temp))
          (when with-buffer
            (funcall with-buffer tmux-buffer)))
      (delete-file temp))))

;;;###autoload
(defun turnip-send-region (start end target &optional before-keys)
  "Send region to pane.
If no mark is set defaults to send the whole buffer.
If called interactively the last used pane is saved and used as a default on subsequent calls."
  (interactive
   (append
    (if (use-region-p)
        (list (region-beginning) (region-end))
      (list (point-min) (point-max)))
    (list (call-interactively #'turnip-choose-pane))))

  (unless before-keys
    (setq before-keys turnip-send-region-before-keys))

  (unless (called-interactively-p 'any)
    (setq target (turnip:normalize-and-check-target-pane target)))

  (turnip-send-region-to-buffer
   start end nil
   (lambda (buffer)
     (when before-keys
       (apply #'turnip:send-keys target before-keys))
     (turnip:call "paste-buffer" "-d" "-t" target)
     (message "(region sent to pane '%s')" (turnip:format-pane-id target)))))

(provide 'turnip)

;;; turnip.el ends here
