;;; ob-tmux.el --- Babel Support for Interactive Terminal -*- lexical-binding: t; -*-

;; Copyright (C) 2009-2017 Free Software Foundation, Inc.
;; Copyright (C) 2017 Allard Hendriksen

;; Author: Allard Hendriksen
;; Keywords: literate programming, interactive shell, tmux
;; Package-Commit: 8886f31291e979b41215f3eb97670732efffea34
;; URL: https://github.com/ahendriksen/ob-tmux
;; Version: 0.1.5
;; Package-Version: 20180719.1551
;; Package-X-Original-version: 0.1.5
;; Package-Requires: ((emacs "25.1") (seq "2.3") (s "1.9.0"))

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
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-Babel support for tmux.
;;
;; Heavily inspired by 'eev' from Eduardo Ochs and ob-screen.el from
;; Benjamin Andresen.
;;
;; See documentation on https://github.com/ahendriksen/ob-tmux
;;
;; You can test the default setup with
;; M-x org-babel-tmux-test RET

;;; Code:

(require 'ob)
(require 'seq)
(require 's)


(defcustom org-babel-tmux-location "tmux"
  "The command location for tmux.
Change in case you want to use a different tmux than the one in your $PATH."
  :group 'org-babel
  :type 'string)

(defcustom org-babel-tmux-session-prefix "org-babel-session-"
  "The string that will be prefixed to tmux session names started by ob-tmux."
  :group 'org-babel
  :type 'string)

(defcustom org-babel-tmux-default-window-name "ob1"
  "This is the default tmux window name used for windows that are not explicitly named in an org session."
  :group 'org-babel
  :type 'string)

(defvar org-babel-default-header-args:tmux
  '((:results . "silent")
    (:session . "default")
    (:socket . nil)
    (:terminal . "gnome-terminal"))
  "Default arguments to use when running tmux source blocks.")

(add-to-list 'org-src-lang-modes '("tmux" . sh))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; org-babel interface
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun org-babel-execute:tmux (body params)
  "Send a block of code via tmux to a terminal using Babel.
\"default\" session is used when none is specified.
Argument BODY the body of the tmux code block.
Argument PARAMS the org parameters of the code block."
  (message "Sending source code block to interactive terminal session...")
  (save-window-excursion
    (let* ((org-session (cdr (assq :session params)))
	   (terminal (cdr (assq :terminal params)))
	   (socket (cdr (assq :socket params)))
	   (socket (when socket (expand-file-name socket)))
	   (ob-session (ob-tmux--from-org-session org-session socket))
           (session-alive (ob-tmux--session-alive-p ob-session))
	   (window-alive (ob-tmux--window-alive-p ob-session)))
      ;; Create tmux session and window if they do not yet exist
      (unless session-alive (ob-tmux--create-session ob-session))
      (unless window-alive (ob-tmux--create-window ob-session))
      ;; Start terminal window if the session does not yet exist
      (unless session-alive
	(ob-tmux--start-terminal-window ob-session terminal))
      ;; Wait until tmux window is available
      (while (not (ob-tmux--window-alive-p ob-session)))
      ;; Disable window renaming from within tmux
      (ob-tmux--disable-renaming ob-session)
      (ob-tmux--send-body
       ob-session (org-babel-expand-body:generic body params)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ob-tmux object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(cl-defstruct (ob-tmux- (:constructor ob-tmux--create)
			(:copier ob-tmux--copy))
  session
  window
  socket)

(defun ob-tmux--tmux-session (org-session)
  "Extract tmux session from ORG-SESSION string."
  (let* ((session (car (split-string org-session ":"))))
    (concat org-babel-tmux-session-prefix
	    (if (string-equal "" session) "default" session))))
(defun ob-tmux--tmux-window (org-session)
  "Extract tmux window from ORG-SESSION string."
  (let* ((window (cadr (split-string org-session ":"))))
    (if (string-equal "" window) nil window)))

(defun ob-tmux--from-org-session (org-session &optional socket)
  "Create a new ob-tmux-session object from ORG-SESSION specification.
Optional argument SOCKET: the location of the tmux socket (only use if non-standard)."

  (ob-tmux--create
   :session (ob-tmux--tmux-session org-session)
   :window (ob-tmux--tmux-window org-session)
   :socket socket))

(defun ob-tmux--window-default (ob-session)
  "Extracts the tmux window from the ob-tmux- object.
Returns `org-babel-tmux-default-window-name' if no window specified.

Argument OB-SESSION: the current ob-tmux session."
  (if (ob-tmux--window ob-session)
      (ob-tmux--window ob-session)
      org-babel-tmux-default-window-name))

(defun ob-tmux--target (ob-session)
  "Constructs a tmux target from the `ob-tmux-' object.

If no window is specified, use first window.

Argument OB-SESSION: the current ob-tmux session."
  (let* ((target-session (ob-tmux--session ob-session))
	 (window (ob-tmux--window ob-session))
	 (target-window (if window (concat "=" window) "^")))
    (concat target-session ":" target-window)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Process execution functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ob-tmux--execute (ob-session &rest args)
  "Execute a tmux command with arguments as given.

Argument OB-SESSION: the current ob-tmux session.
Optional command-line arguments can be passed in ARGS."
  (if (ob-tmux--socket ob-session)
      (apply 'start-process "ob-tmux" "*Messages*"
	     org-babel-tmux-location
	     "-S" (ob-tmux--socket ob-session)
	     args)
    (apply 'start-process
	   "ob-tmux" "*Messages*" org-babel-tmux-location args)))

(defun ob-tmux--execute-string (ob-session &rest args)
  "Execute a tmux command with arguments as given.
Returns stdout as a string.

Argument OB-SESSION: the current ob-tmux session.  Optional
command-line arguments can be passed in ARGS and are
automatically space separated."
  (let* ((socket (ob-tmux--socket ob-session))
	 (args (if socket (cons "-S" (cons socket args)) args)))
  (shell-command-to-string
   (concat org-babel-tmux-location " "
	   (s-join " " args)))))

(defun ob-tmux--start-terminal-window (ob-session terminal)
  "Start a TERMINAL window with tmux attached to session.

Argument OB-SESSION: the current ob-tmux session."
  (let* ((process-name (concat "org-babel: terminal")))
    (unless (ob-tmux--socket ob-session)
      (if (string-equal terminal "xterm")
	  (start-process process-name "*Messages*"
			 terminal
			 "-T" (ob-tmux--target ob-session)
			 "-e" org-babel-tmux-location "attach-session"
			 "-t" (ob-tmux--target ob-session))
	(start-process process-name "*Messages*"
		       terminal "--"
		       org-babel-tmux-location "attach-session"
		       "-t" (ob-tmux--target ob-session))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tmux interaction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ob-tmux--create-session (ob-session)
  "Create a tmux session if it does not yet exist.

Argument OB-SESSION: the current ob-tmux session."
  (unless (ob-tmux--session-alive-p ob-session)
    (ob-tmux--execute ob-session
     ;; TODO: set socket
     "new-session"
     "-d" ;; just create the session, don't attach.
     "-c" (expand-file-name "~") ;; start in home directory
     "-s" (ob-tmux--session ob-session)
     "-n" (ob-tmux--window-default ob-session))))

(defun ob-tmux--create-window (ob-session)
  "Create a tmux window in session if it does not yet exist.

Argument OB-SESSION: the current ob-tmux session."
  (unless (ob-tmux--window-alive-p ob-session)
    (ob-tmux--execute ob-session
     ;; TODO: set socket
     "new-window"
     "-c" (expand-file-name "~") ;; start in home directory
     "-n" (ob-tmux--window-default ob-session)
     "-t" (ob-tmux--session ob-session))))

(defun ob-tmux--set-window-option (ob-session option value)
  "If window exists, set OPTION for window.

Argument OB-SESSION: the current ob-tmux session."
  (when (ob-tmux--window-alive-p ob-session)
    (ob-tmux--execute ob-session
     ;; TODO set socket
     "set-window-option"
     "-t" (ob-tmux--target ob-session)
     option value)))

(defun ob-tmux--disable-renaming (ob-session)
  "Disable renaming features for tmux window.

Disabling renaming improves the chances that ob-tmux will be able
to find the window again later.

Argument OB-SESSION: the current ob-tmux session."
  (progn
    (ob-tmux--set-window-option ob-session "allow-rename" "off")
    (ob-tmux--set-window-option ob-session "automatic-rename" "off")))

(defun ob-tmux--send-keys (ob-session line)
  "If tmux window exists, send a LINE of text to it.

Argument OB-SESSION: the current ob-tmux session."
  (when (ob-tmux--window-alive-p ob-session)
    (ob-tmux--execute ob-session
     ;; TODO set socket
     "send-keys"
     "-l"
     "-t" (ob-tmux--target ob-session)
     line "\n")))

(defun ob-tmux--send-body (ob-session body)
  "If tmux window (passed in OB-SESSION) exists, send BODY to it.

Argument OB-SESSION: the current ob-tmux session."
  (let ((lines (split-string body "[\n\r]+")))
    (when (ob-tmux--window-alive-p ob-session)
      (mapc (lambda (l) (ob-tmux--send-keys ob-session l)) lines))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tmux interrogation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ob-tmux--session-alive-p (ob-session)
  "Check if SESSION exists by parsing output of \"tmux ls\".

Argument OB-SESSION: the current ob-tmux session."
  (let* ((tmux-ls (ob-tmux--execute-string ob-session "ls -F '#S'"))
	 (tmux-session (ob-tmux--session ob-session)))
    (car
     (seq-filter (lambda (x) (string-equal tmux-session x))
		 (split-string tmux-ls "\n")))))

(defun ob-tmux--window-alive-p (ob-session)
  "Check if WINDOW exists in tmux session.

If no window is specified in OB-SESSION, returns 't."
  (let* ((window (ob-tmux--window ob-session))
	 (target (ob-tmux--target ob-session))
	 (output (ob-tmux--execute-string ob-session
		  "list-panes"
		  "-F 'yes_exists'"
		  "-t" (concat "'" target "'"))))
    (cond (window
	   (string-equal "yes_exists\n" output))
	  ((null window)
	   't))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ob-tmux--open-file (path)
  "Open file as string.

Argument PATH: the location of the file."
(with-temp-buffer
    (insert-file-contents-literally path)
    (buffer-substring (point-min) (point-max))))

(defun ob-tmux--test ()
  "Test if the default setup works.  The terminal should shortly flicker."
  (interactive)
  (let* ((random-string (format "%s" (random 99999)))
         (tmpfile (org-babel-temp-file "ob-tmux-test-"))
         (body (concat "echo '" random-string "' > " tmpfile))
         tmp-string)
    (org-babel-execute:tmux body org-babel-default-header-args:tmux)
    ;; XXX: need to find a better way to do the following
    (while (or (not (file-readable-p tmpfile))
	       (= 0 (length (ob-tmux--open-file tmpfile))))
      ;; do something, otherwise this will be optimized away
      (format "org-babel-tmux: File not readable yet."))
    (setq tmp-string (ob-tmux--open-file tmpfile))
    (delete-file tmpfile)
    (message (concat "org-babel-tmux: Setup "
                     (if (string-match random-string tmp-string)
                         "WORKS."
		       "DOESN'T work.")))))

(provide 'ob-tmux)



;;; ob-tmux.el ends here
