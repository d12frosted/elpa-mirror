;;; uci-mode.el --- Major-mode for chess engine interaction -*- lexical-binding: t -*-

;; Copyright (c) 2019-2021 Dodge Coates and Roland Walker

;; Author: Dodge Coates and Roland Walker
;; Homepage: https://github.com/dwcoates/uci-mode
;; URL: https://raw.github.com/dwcoates/uci-mode/master/uci-mode.el
;; Package-Version: 20210626.1956
;; Package-Commit: 2cdf4de5af96d56108a0a5716416ef3c8ac7bb7c
;; Version: 0.5.1
;; Last-Updated: 18 Jun 2021
;; Package-Requires: ((emacs "25.1"))
;; Keywords: data, games, chess

;;; License

;; Simplified BSD License:

;; Redistribution and use in source and binary forms, with or
;; without modification, are permitted provided that the following
;; conditions are met:
;;
;;   1. Redistributions of source code must retain the above
;;      copyright notice, this list of conditions and the following
;;      disclaimer.
;;
;;   2. Redistributions in binary form must reproduce the above
;;      copyright notice, this list of conditions and the following
;;      disclaimer in the documentation and/or other materials
;;      provided with the distribution.

;; This software is provided by the authors "AS IS" and any express
;; or implied warranties, including, but not limited to, the implied
;; warranties of merchantability and fitness for a particular
;; purpose are disclaimed.  In no event shall the authors or
;; contributors be liable for any direct, indirect, incidental,
;; special, exemplary, or consequential damages (including, but not
;; limited to, procurement of substitute goods or services; loss of
;; use, data, or profits; or business interruption) however caused
;; and on any theory of liability, whether in contract, strict
;; liability, or tort (including negligence or otherwise) arising in
;; any way out of the use of this software, even if advised of the
;; possibility of such damage.

;; The views and conclusions contained in the software and
;; documentation are those of the authors and should not be
;; interpreted as representing official policies, either expressed
;; or implied, of the authors.

;;; Commentary:

;; Quickstart

;;     $ which stockfish
;;     /usr/local/bin/stockfish

;;     (require 'uci-mode)

;;     M-x uci-mode-run-engine

;; Explanation

;;     Uci-mode is a comint-derived major-mode for interacting directly with
;;     a UCI chess engine.  Direct UCI interaction is interesting for
;;     programmers who are developing chess engines, or advanced players who
;;     are doing deep analysis on games.  This mode is not useful for simply
;;     playing chess.

;; See Also

;;     M-x customize-group RET uci RET

;;     M-x customize-group RET comint RET

;;     https://github.com/dwcoates/pygn-mode

;;     http://wbec-ridderkerk.nl/html/UCIProtocol.html

;; Notes

;; Compatibility and Requirements

;;     GNU Emacs version 25.1 or higher

;;     A command-line UCI chess engine such as Stockfish (the default)

;;; Code:

(defconst uci-mode-version "0.5.1")

;;; Imports

(require 'comint)

;;; Declarations

;;; Customizable variables

;;;###autoload
(defgroup uci nil
  "Major-mode for chess engine interaction."
  :version uci-mode-version
  :link '(url-link :tag "Github" "https://github.com/dwcoates/uci-mode")
  :prefix "uci-mode-"
  :group 'data
  :group 'games)

(defcustom uci-mode-engine-command '("stockfish")
  "Command to run a UCI chess engine, given as a list.

The first element in the list should be an executable.  Optional
additional elements are arguments to the executable.  The list
form allows access to remote engines over SSH."
  :group 'uci
  :type '(repeat string))

(defcustom uci-mode-engine-setoptions
  '("setoption name MultiPV value 1")
  "List of UCI \"setoption\" commands to issue at engine startup."
  :group 'uci
  :type '(repeat string))

(defcustom uci-mode-command-history-file
  (expand-file-name "uci-mode-history.txt" user-emacs-directory)
  "Filename to store persistent `uci-mode' command history."
  :group 'uci
  :type 'string)

;;;###autoload
(defgroup uci-faces nil
  "Faces used by uci-mode."
  :group 'uci)

(defface uci-mode-depth-face
   '((t (:inherit font-lock-variable-name-face)))
  "uci-mode face for depth in info output."
  :group 'uci-faces)

(defface uci-mode-multipv-1-face
   '((t (:inherit font-lock-variable-name-face)))
  "uci-mode face for MultiPV 1 in info output."
  :group 'uci-faces)

(defface uci-mode-score-face
   '((t (:inherit font-lock-variable-name-face)))
  "uci-mode face for score in info output."
  :group 'uci-faces)

(defface uci-mode-pv-face
   '((t (:inherit font-lock-string-face)))
  "uci-mode face for pv in info output."
  :group 'uci-faces)

(defface uci-mode-option-name-face
   '((t (:inherit font-lock-string-face)))
  "uci-mode face for option names in uci response output."
  :group 'uci-faces)

(defface uci-mode-finished-face
   '((t (:inherit font-lock-builtin-face)))
  "uci-mode face for various final-line outputs."
  :group 'uci-faces)

;;; Variables

(defvar uci-mode-engine-buffer nil
  "The current `uci-mode' engine process buffer.")

(defvar uci-mode-engine-buffer-name "*UCI*"
  "The name of the `uci-mode' engine process buffer.")

(defvar uci-mode-engine-process-name "UCI"
  "The name of the `uci-mode' engine process.")

;;; Syntax table

(defvar uci-mode-syntax-table
  (let ((st (make-syntax-table text-mode-syntax-table)))
    (with-syntax-table st
    st))
  "Syntax table for `uci-mode'.")

;;; Keymaps

(defvar uci-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map comint-mode-map)
    (define-key map (kbd "C-c C-c") 'uci-mode-send-stop)
    map)
  "Keymap for `uci-mode'.")

;;; Utility functions

(defun uci-mode--get-engine-proc ()
  "Return the engine process at `uci-mode-engine-buffer'."
  (get-buffer-process uci-mode-engine-buffer))

(defun uci-mode--process-alive-p ()
  "Return non-nil iff `uci-mode' engine process is alive."
  (let ((proc (uci-mode--get-engine-proc)))
    (and proc (process-live-p proc))))

(defun uci-mode--get-engine-buffer ()
  "Return the engine comint buffer using `uci-mode-engine-buffer-name'."
  (get-buffer uci-mode-engine-buffer-name))

(defun uci-mode-make-comint (command)
  "Create a UCI engine comint buffer.

COMMAND is the engine command to be executed."
  (unless (comint-check-proc uci-mode-engine-buffer-name)
    (let* ((buf (apply
                 #'make-comint-in-buffer
                 uci-mode-engine-process-name
                 uci-mode-engine-buffer-name
                 (car command)
                 nil
                 (cdr command)))
           (proc (get-buffer-process buf)))
      (sleep-for 0.20)
      (process-put proc 'command-basename (file-name-base (car (reverse command))))
      (process-put proc 'command-full command)
      (with-current-buffer buf
        (uci-mode))
      (set-process-query-on-exit-flag proc nil)
      (setq uci-mode-engine-buffer (uci-mode--get-engine-buffer))
      (uci-mode-send-setoptions)))
  (display-buffer uci-mode-engine-buffer-name)
  (set-window-scroll-bars
   (get-buffer-window uci-mode-engine-buffer-name) nil nil nil 'bottom)
  uci-mode-engine-buffer)

(defun uci-mode-engine-proc ()
  "Return the `uci-mode' inferior engine process."
  (let ((proc (uci-mode--get-engine-proc)))
    (unless (process-live-p proc)
      (error "No UCI engine process.  Try `uci-mode-run-engine' or `uci-mode-restart-engine'"))
    proc))

(defun uci-mode-send-commands (commands)
  "Send COMMANDS (a list of strings) to a running UCI engine."
  (unless uci-mode-engine-buffer
    (error "No UCI engine buffer.  Try `uci-mode-run-engine' or `uci-mode-restart-engine'"))
  (unless (process-live-p
           (get-buffer-process uci-mode-engine-buffer))
    (error "No UCI engine process.  Try `uci-mode-run-engine' or `uci-mode-restart-engine'"))
  (with-current-buffer uci-mode-engine-buffer
    (dolist (cmd commands)
      (sleep-for 0.05)
      (goto-char (point-max))
      (insert (replace-regexp-in-string "\n+\\'" "" cmd))
      (comint-send-input nil t))))

;; buglet: some specified chatter lines still get through the filter,
;; presumably due to buffering
(defun uci-mode-preoutput-reduce-chatter (str)
  "Remove some less-important lines from engine output STR."
  (replace-regexp-in-string
   ;; Komodo
   "^info [^\n]*\\<\\(?:nodes\\|nps\\) [0-9]+\n" ""
   (replace-regexp-in-string
    ;; Stockfish
    "^info [^\n]*\\<\\(?:upperbound\\|lowerbound\\) [^\n]*\n" ""
    (replace-regexp-in-string
     ;; Stockfish
     "^info [^\n]*\\<currmovenumber [0-9]+\n" ""
     str))))

;;; Font-lock

(font-lock-add-keywords
 'uci-mode
 '(
   ;; depth
   ("^info[^\n]*\\s-+\\(depth\\s-+[0-9]+\\)" 1 'uci-mode-depth-face)
   ;; multipv 1
   ("^info[^\n]*\\s-+\\(multipv\\s-+1\\)\\s-" 1 'uci-mode-multipv-1-face)
   ;; score
   ("^info[^\n]*\\s-+\\(\\(?:cp\\|mate\\)\\s-+\\S-+\\)" 1 'uci-mode-score-face)
   ;; pv
   ("^info[^\n]*\\s-+\\(pv\\s-[^\n]+\\)" 1 'uci-mode-pv-face)
   ;; option names
   ("^option\\s-+name\\s-+\\([^\n]*?\\)\\s-+type" 1 'uci-mode-option-name-face)
   ;; finishing strings (a help in the absence of a prompt)
   ("^\\(bestmove\\|uciok\\|readyok\\)[^\n]*" 0 'uci-mode-finished-face)))

;;; Major-mode definition

;;;###autoload
(define-derived-mode uci-mode comint-mode "UCI"
  "Major-mode for chess engine interaction.

Runs a UCI-compatible chess engine as a subprocess of Emacs."
  :syntax-table uci-mode-syntax-table
  :group 'uci
  (setq-local truncate-lines t)
  (setq-local comint-input-ring-file-name uci-mode-command-history-file)
  (comint-read-input-ring 'silent)
  (add-hook 'kill-buffer-hook #'comint-write-input-ring t t)
  (add-hook 'comint-preoutput-filter-functions #'uci-mode-preoutput-reduce-chatter t t)
  (setq-local comint-use-prompt-regexp nil)
  (setq-local comint-input-ignoredups t)
  (setq-local mode-line-process '(":%s"))
  (setq-local comint-output-filter-functions
              '(comint-postoutput-scroll-to-bottom
                comint-truncate-buffer))
  ;; modeline
  (when (process-get (get-buffer-process (current-buffer)) 'command-basename)
    (setq-local
     mode-line-buffer-identification
     (propertize
      (process-get (get-buffer-process (current-buffer)) 'command-basename)
      'help-echo (mapconcat
                  #'identity
                  (process-get (get-buffer-process (current-buffer)) 'command-full)
                  " "))))
  (buffer-disable-undo)
  (font-lock-ensure))

;;; Interactive commands

;;;###autoload
(defun uci-mode-run-engine (&optional command)
  "Run an inferior UCI engine process.

COMMAND defaults to `uci-mode-engine-command'.  When called
interactively with universal `prefix-arg', the user may edit the
command.  When called with two universal prefix-args, the
user may enter a multi-word command which is split using
`split-string-and-unquote'."
  (interactive "P")
  (setq command (cond
                  ((equal command '(4))
                   (list (read-shell-command
                          "Engine: "
                          (car (reverse uci-mode-engine-command)))))
                  ((equal command '(16))
                   (split-string-and-unquote
                    (read-shell-command
                     "Engine (split): "
                     (mapconcat #'identity uci-mode-engine-command " "))))
                  ((and command (listp command))
                   command)
                  (t
                   uci-mode-engine-command)))
  (get-buffer-process
   (uci-mode-make-comint command)))

(defun uci-mode-restart-engine (&optional command)
  "Restart or replace an inferior UCI engine process.

COMMAND defaults to the path of the currently running engine, or
`uci-mode-engine-command' when that information is not available.
When called interactively with a universal `prefix-arg', the user may
edit the command.  When called with two universal prefix-args, the
user may enter a multi-word command which is split using
`split-string-and-unquote'.

When no engine is running, this is equivalent to `uci-mode-run-engine'."
  (interactive "P")
  (let* ((proc (uci-mode--get-engine-proc))
         (command-full (and proc (process-get proc 'command-full))))
    (setq command (cond
                    ((equal command '(4))
                     (list (read-shell-command
                            "Engine: "
                            (car (reverse (or command-full uci-mode-engine-command))))))
                    ((equal command '(16))
                     (split-string-and-unquote
                      (read-shell-command
                       "Engine (split): "
                       (mapconcat #'identity (or command-full uci-mode-engine-command) " "))))
                    ((and command (listp command))
                      command)
                    (t
                     (or command-full uci-mode-engine-command))))
    (when proc
      (delete-process proc))
  (uci-mode-run-engine command)))

(defun uci-mode-send-stop ()
  "Send a \"stop\" message to the UCI engine, without echoing."
  (interactive)
  (let ((proc (uci-mode-engine-proc)))
    (comint-send-string proc "stop\n")))

(defun uci-mode--kill-buffer-window-and-process ()
  "Forcefully kill `uci-mode' engine buffer, window, and process."
  (when (uci-mode--process-alive-p)
    (let ((proc (uci-mode--get-engine-proc)))
      (message "Forcefully quitting uci-mode engine process '%s' peacefully. Sending kill signal." (process-id proc))
      (kill-process proc)))
  (let* ((buf (uci-mode--get-engine-buffer))
         (win (and buf (get-buffer-window uci-mode-engine-buffer-name))))
    (when buf
      (when win
        (with-current-buffer-window buf nil nil
          (kill-buffer-and-window)))
      (kill-buffer buf))))

(defun uci-mode-quit ()
  "Send a \"quit\" message to the UCI engine, quit comint, and clean up the UCI buffer and window."
  (interactive)
  (if (uci-mode--process-alive-p)
      (progn
        (comint-send-string (uci-mode-engine-proc) "quit\n")
        (message "uci-mode engine process sent 'quit' command.")
        (sleep-for 0 20) ;; Give some time for the process to quit.
        (uci-mode--kill-buffer-window-and-process))
    (message "No uci-mode engine process.")
    (uci-mode--kill-buffer-window-and-process)))

(defun uci-mode-send-setoptions ()
  "Send `uci-mode-engine-setoptions' to a running UCI engine."
  (interactive)
  (uci-mode-send-commands uci-mode-engine-setoptions))

(provide 'uci-mode)

;;
;; Emacs
;;
;; Local Variables:
;; coding: utf-8
;; byte-compile-warnings: (not cl-functions redefine)
;; End:
;;
;; LocalWords: ARGS alist devel
;;

;;; uci-mode.el ends here
