;;; multi-run.el --- Manage multiple terminals and run commands on them

;; Copyright (C) 2017  Sagar Jha

;; Author: Sagar Jha
;; URL: https://www.github.com/sagarjha/multi-run
;; Package-Version: 20180122.1509
;; Package-Commit: 87d9eed414999fd94685148d39e5308c099e65ca
;; Package-Requires: ((emacs "24") (window-layout "1.4"))
;; Version: 1.0
;; Keywords: tools, terminals

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

;; The functions below are self-explanatory with the documentation string.

;; See the full documentation on https://www.github.com/sagarjha/multi-run

;;; Code:

(require 'window-layout)

(defgroup multi-run nil
  "Run commands in multiple terminal windows."
  :group 'terminals)

(defcustom multi-run-term-type 'eshell
  "Terminal type to run the commands on.")
;; set multi-run-term-type to any of the supported terminals by running the appropriate expression from below
;; (setq multi-run-term-type 'eshell)
;; (setq multi-run-term-type 'shell)
;; (setq multi-run-term-type 'ansi-term)
;; (setq multi-run-term-type 'term)
;; (setq multi-run-term-type 'multi-term)

(defvar multi-run-terminals-list nil
  "List of terminals to run the command on.")

(defvar multi-run-timers-list nil
  "Internal list of timers to cancel when multi-run-kill-all-timers is called.")

(defvar multi-run-hostnames-list nil
  "List of hostnames for multi-run-ssh.")

(defvar multi-run-ssh-username nil
  "SSH username for multi-run-ssh.")

(defun multi-run-match-term-type-p (multi-run-term-type)
  "Return non-nil if MULTI-RUN-TERM-TYPE is one of the supported terminal types."
  (memq multi-run-term-type '(eshell shell ansi-term term multi-term)))

(defun multi-run-get-buffer-name (term-num)
  "Return the name of the buffer for a given terminal number TERM-NUM."
  (let ((term-num-in-str (number-to-string term-num)))
    (pcase multi-run-term-type
      ('eshell (concat "eshell<" term-num-in-str ">"))
      ('shell (concat "shell<" term-num-in-str ">"))
      ('ansi-term (concat "ansi-term<" term-num-in-str ">"))
      ('term (concat "term<" term-num-in-str ">"))
      ('multi-term (concat "terminal<" term-num-in-str ">"))
      (multi-run-term-type (error "Value of multi-run-term-type should be one of the following symbols: eshell, shell, ansi-term, term, multi-term")))))

(defun multi-run-get-input-function ()
  "Return the name of the function that will run the input on the terminal."
  (pcase multi-run-term-type
    ('eshell 'eshell-send-input)
    ('shell 'comint-send-input)
    ((pred multi-run-match-term-type-p) 'term-send-input)
    (multi-run-term-type (error "Value of multi-run-term-type should be one of the following symbols: eshell, shell, ansi-term, term, multi-term"))))

(defun multi-run-get-new-input-point ()
  "Move point to the latest prompt in the terminal buffer."
  (pcase multi-run-term-type
    ('eshell eshell-last-output-end)
    ((pred multi-run-match-term-type-p) (process-mark (get-buffer-process (current-buffer))))
    (multi-run-term-type (error "Value of multi-run-term-type should be one of the following symbols: eshell, shell, ansi-term, term, multi-term"))))

(defun multi-run-open-terminal (term-num)
  "Open terminal number TERM-NUM in a buffer if it's not already open.  In any case, switch to it."
  (unless (get-buffer (multi-run-get-buffer-name term-num))
    (progn
      (pcase multi-run-term-type
        ('eshell (eshell term-num))
        ('shell (shell))
        ('ansi-term (ansi-term "/bin/bash"))
        ('term (term "/bin/bash"))
        ('multi-term (multi-term))
        (multi-run-term-type (error "Value of multi-run-term-type should be one of the following symbols: eshell, shell, ansi-term, term, multi-term")))
      (rename-buffer (multi-run-get-buffer-name term-num))))
  (switch-to-buffer (multi-run-get-buffer-name term-num)))

;; run a command on a single terminal
(defun multi-run-on-single-terminal (command term-num)
  "Run the command COMMAND on a single terminal with number TERM-NUM."
  (set-buffer (multi-run-get-buffer-name term-num))
  (goto-char (multi-run-get-new-input-point))
  (insert command)
  (funcall (multi-run-get-input-function)))

;; run a command on multiple terminals
(defun multi-run-on-terminals (command term-nums &optional delay)
  "Run the COMMAND on terminals in TERM-NUMS with an optional DELAY between running on successive terminals."
  (let ((delay (if delay delay 0))
	(delay-cnt 0))
    (while term-nums
      (let ((evaled-command (if (functionp command)
                                (funcall command (car term-nums)) command)))
        (setq multi-run-timers-list
              (cons (run-at-time (concat (number-to-string (* delay-cnt delay)) " sec")
                                 nil
                                 'multi-run-on-single-terminal evaled-command (car term-nums))
                    multi-run-timers-list))
        (setq term-nums (cdr term-nums))
        (setq delay-cnt (1+ delay-cnt))))))

(defun multi-run-create-terminals (num-terminals)
  "Create NUM-TERMINALS number of terminals."
  (dotimes (i num-terminals)
    (multi-run-open-terminal (1+ i))))

(defun multi-run-make-vertical-or-horizontal-pane (num-terminals offset sym-vec choice)
  "Helper function for multi-run-configure-terminals.  Create NUM-TERMINALS number of windows with buffer names given by OFFSET into SYM-VEC.  The windows are created in a single vertical or horizontal pane determined by CHOICE."
  (if (= num-terminals 1) (aref sym-vec offset)
    (list (if (= choice 0) '| '-) `(,(if (= choice 0) :left-size-ratio :upper-size-ratio)
				    ,(/ (- num-terminals 1.0) num-terminals))
	  (multi-run-make-vertical-or-horizontal-pane (1- num-terminals) (1- offset) sym-vec choice) (aref sym-vec offset))))

(defun multi-run-make-internal-recipe (num-terminals window-batch sym-vec)
  "Helper function for multi-run-configure-terminals.  Create a recipe for wlf:layout for NUM-TERMINALS number of terminal buffers with WINDOW-BATCH of them in one vertical pane.  Get symbol names for terminals from SYM-VEC."
  (let ((num-panes (if (= (% num-terminals window-batch) 0)
		       (/ num-terminals window-batch) (1+ (/ num-terminals window-batch)))))
    (if (<= num-terminals window-batch)
	(multi-run-make-vertical-or-horizontal-pane num-terminals num-terminals sym-vec 1)
      (list '| `(:left-size-ratio ,(/ (- num-panes 1.0) num-panes))
	    (multi-run-make-internal-recipe (- num-terminals (if (= (% num-terminals window-batch) 0)
								 window-batch
							       (% num-terminals window-batch)))
					    window-batch sym-vec)
	    (multi-run-make-vertical-or-horizontal-pane (if (= (% num-terminals window-batch) 0) window-batch
							  (% num-terminals window-batch))
							num-terminals sym-vec 1)))))

(defun multi-run-make-symbols (num-terminals &optional cnt)
  "Create unique symbols for NUM-TERMINALS number of terminals having created recursively symbols for CNT of them."
  (unless cnt
    (setq cnt 0))
  (when (<= cnt num-terminals)
    (vconcat (vector (make-symbol (concat "term" (number-to-string cnt)))) (multi-run-make-symbols num-terminals (1+ cnt)))))

(defun multi-run-make-dict (num-terminals sym-vec &optional cnt)
  "Create a dictionary of terminal symbol names and their associated buffer names for NUM-TERMINALS number of terminals with symbols from SYM-VEC, having created recursively entries for CNT of them."
  (unless cnt
    (setq cnt 1))
  (when (<= cnt num-terminals)
    (cons (list :name (aref sym-vec cnt)
		:buffer (multi-run-get-buffer-name cnt))
	  (multi-run-make-dict num-terminals sym-vec (1+ cnt)))))

(defun multi-run-configure-terminals (num-terminals &optional window-batch)
  "Lay out NUM-TERMINALS number of terminals on the screen with WINDOW-BATCH number of them in one single vertical slot."
  (let* ((window-batch (if window-batch window-batch 5))
	 (master-buffer-name (buffer-name))
	 (sym-vec (multi-run-make-symbols num-terminals))
	 (buffer-dict (cons (list :name (aref sym-vec 0)
				  :buffer master-buffer-name)
			    (multi-run-make-dict num-terminals sym-vec)))
	 (internal-recipe (multi-run-make-internal-recipe num-terminals window-batch sym-vec))
	 (overall-recipe `(- (:upper-size-ratio 0.9)
			     ,internal-recipe ,(aref sym-vec 0))))
    (multi-run-create-terminals num-terminals)
    (wlf:layout
     overall-recipe
     buffer-dict)
    (select-window (get-buffer-window master-buffer-name))
    (setq multi-run-terminals-list (number-sequence 1 num-terminals))
    (concat "Preemptively setting multi-run-terminals-list to " (prin1-to-string multi-run-terminals-list))))

(defun multi-run-with-delay (delay &rest cmd)
  "With the provided DELAY, run one or more commands CMD on multiple terminals - the delay is between running commands on different terminals."
  (let ((delay-now 0))
    (dolist (command cmd)
      (setq multi-run-timers-list (cons (run-at-time (concat (number-to-string delay-now) " sec") nil 'multi-run-on-terminals command multi-run-terminals-list delay) multi-run-timers-list))
      (setq delay-now (+ delay-now (* (length multi-run-terminals-list) delay)))))
  nil)

(defun multi-run-with-delay2 (delay &rest cmd)
  "With the provided DELAY, run one or more commands CMD on multiple terminals - but the delay is between different command invocations at the terminals."
  (let ((delay-now 0))
    (dolist (command cmd)
      (setq multi-run-timers-list (cons (run-at-time (concat (number-to-string delay-now) " sec") nil 'multi-run-on-terminals command multi-run-terminals-list) multi-run-timers-list))
      (setq delay-now (+ delay-now delay))))
  nil)

(defun multi-run (&rest cmd)
  "Run one or more commands CMD on multiple terminals."
  (apply #'multi-run-with-delay 0 cmd))

(defun multi-run-loop (cmd &optional times delay)
  "Loop CMD given number of TIMES with DELAY between successive run(s)."
  (unless times
    (setq times 1))
  (unless delay
    (setq delay 0))
  (let ((delay-cnt 0))
    (dotimes (i times)
      (progn
        (setq multi-run-timers-list (cons (run-at-time (concat (number-to-string (* delay-cnt delay)) " sec")
                                                       nil '(lambda (cmd) (multi-run cmd)) cmd) multi-run-timers-list))
        (setq delay-cnt (1+ delay-cnt))))))

;; convenience function for ssh'ing to the terminals
(defun multi-run-ssh (&optional terminal-num)
  "Establish ssh connections in the terminals (or on terminal number TERMINAL-NUM) with the help of user-defined variables."
  (multi-run-on-terminals (lambda (x) (concat "ssh " (if multi-run-ssh-username
							 (concat multi-run-ssh-username "@") "")
					      (elt multi-run-hostnames-list (- x 1)))) (if terminal-num (list terminal-num) multi-run-terminals-list)))

(defun multi-run-kill-terminals (&optional terminal-num)
  "Kill terminals (or the optional terminal TERMINAL-NUM)."
  (if terminal-num
      (kill-buffer (multi-run-get-buffer-name terminal-num))
    (mapc (lambda (terminal-num) (kill-buffer (multi-run-get-buffer-name terminal-num))) multi-run-terminals-list))
  nil)

(defun multi-run-kill-all-timers ()
  "Cancel commands running on a loop or via delay functions."
  (mapc 'cancel-timer multi-run-timers-list)
  "All timers canceled")


(provide 'multi-run)

;;; multi-run.el ends here
