;;; python-mls.el --- Multi-line shell for (i)Python  -*-lexical-binding: t-*-

;; Copyright (C) 2021-2022 J.D. Smith

;; Author: J.D. Smith
;; Homepage: https://github.com/jdtsmith/python-mls
;; Package-Requires: ((emacs "27.1"))
;; Package-Version: 20221003.1451
;; Package-Commit: 398ba92372cc37bae5d63e4d4c42e65edf7db74b
;; Keywords: languages, processes
;; Version: 0.1.4

;;; Commentary:

;; Python-MLS provides multi-line shell capatibilities for (i)Python
;; run in an inferior shell, building on the Emacs-bundled python.el's
;; python-mode.
;; 
;; Features:
;; - Works with both python and ipython.
;; - Accepts arbitrary multi-line command lengths.
;; - Auto-detects and handles native continuation prompts.
;; - Auto-indents multi-line commands.
;; - Replaces buffer-based fontifications with in-buffer python-mode
;;   fontification for dramatic speedup.
;; - Up/Down arrow history browsing with and without block movement
;;   (try shift arrow).
;; - Saves and restore (multi-line) command history.
;; - Directly kill/yank multi-line code blocks to & from Python
;;   buffers.

;; Python-MLS is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; Python-MLS is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Code:
(require 'python)

(defgroup python-mls nil
  "Setup for command parameters of the Python Multi-Line Shell."
  :group 'python
  :prefix "python-mls")

(defcustom python-mls-save-command-history t
  "Non-nil means preserve command history between sessions.
The file `python-mls-command-history-file' is used to save and restore
the history."
  :group 'python-mls
  :type 'boolean)

(defcustom python-mls-command-history-file "pyhist"
  "The file root for the command history file.
Unless this is an absolute file name, the history file is formed
by appending -`python-shell-buffer-name' to this value, within
`user-emacs-directory'.  To change the size of the history ring,
see the variable `comint-input-ring-size'.  History is only saved
if the variable `python-mls-save-command-history' is non-nil."
  :group 'python-mls
  :type 'file)

(defcustom python-mls-kill-buffer-process-quit nil
  "Whether to kill the python buffer when the process completes."
  :group 'python-mls
  :type 'boolean)

(defcustom python-mls-multiline-history-modifier '(shift)
  "Modifier key for up/down arrow multi-line history navigation.
List of symbols, or nil to disable."
  :group 'python-mls
  :type '(choice (const :tag "None" nil) (repeat :tag "List of modifiers" symbol)))

(defcustom python-mls-import-python-nav-command-list
  '(python-nav-backward-block
    python-nav-forward-block
    python-nav-backward-up-list)
  "Python mode nav commands to import.
Limited to region after prompt.  Binds in the inferior shell with
the same key or (if provided as a cons cell (function . key) to
KEY."
  :group 'python-mls
  :type '(repeat (choice function (cons function key-sequence))))

(defcustom python-mls-prompt-change-functions nil
  "A list of functions to run when the prompt type changes.
Each function should take a single argument -- the prompt type (a symbol)."
  :group 'python-mls
  :type 'hook
  :local t)

(defcustom python-mls-sentinel-hooks nil
  "Hooks to run when the process dies, before saving history."
  :group 'python-mls
  :type 'hook
  :local t)

(defvar-local python-mls-after-prompt-hook '()
  "Hook run each time a new input prompt is found.")

(defvar python-mls-continuation-prompt-regexp "^\s*\\.\\.\\.: \s*$")
(defun python-mls-in-continuation (&optional trim-trailing-ws)
  "Test whether we are in an continued input statement.
We are in a continuation statement if at least one non-empty line
exists after the line containing the prompt.  Trailing empty lines
don't count.  If TRIM-TRAILING-WS is non-nil, any final space
after the output field will be trimmed."
  (let ((prompt-end
	 (if (and comint-last-prompt
		  (> (point) (cdr comint-last-prompt)))
	     (cdr comint-last-prompt)
	   (field-beginning))))
    (and (not (eq (field-at-pos (point)) 'output))
	 (> (save-excursion
	      (goto-char (field-end))
	      (skip-chars-backward "[:space:]\n\r")
	      (prog1 (line-number-at-pos)
		(when trim-trailing-ws
		  (if (eq (field-at-pos (point)) 'output) ;no space in prompt
		      (goto-char (field-end)))
		  (delete-region (point) (field-end)))))
	    (line-number-at-pos prompt-end)))))

(defun python-mls--indent-line ()
  "Indent line, narrowing to region after prompt if in continuation.
If the line is at the end of the buffer, insert an invisible
newline to allow for a prefix prompt."
  (if-let ((end (cdr-safe comint-last-prompt)))
      (save-restriction
	(narrow-to-region end (point-max))
	(python-indent-line-function))
    (python-indent-line-function))
  (if (= (line-beginning-position) (point-max))
      (python-mls-invisible-newline)))

(defun python-mls-line-empty-p (&optional line-off pos)
  "Whether a line is empty.
LINE-OFF can be a positive or negative integer, specificying a
line number relative to the current.  If not set, POS can be a
position in the buffer to go to."
  (save-excursion
    (if line-off (forward-line line-off)
      (if pos (goto-char pos)))
    (beginning-of-line)
    (looking-at-p "[[:space:]]*$")))

(defvar-local python-mls--check-prompt t) ;; start checking by default

(defun python-mls-send-input (proc input)
  "Strip space and newlines from end of input and send.
Use as `comint-input-sender'."
  (setq python-mls--check-prompt t)
  (python-shell-send-string input proc))

(defun python-mls-get-old-input ()
  "Get old input.
Omits extra newlines at end, and preserves (some) text properties."
  (let* ((bof (field-beginning))
	 (field-prop (get-char-property bof 'field))
	 (str (if (not field-prop) ; regular input
		  (field-string bof)
		(comint-bol)
		(buffer-substring
		 (point)
		 (if (eq field-prop 'output)
		     (line-end-position)
		   (field-end))))))
    (remove-text-properties 0 (length str)
			    '(fontified nil
					font-lock-face  nil
					help-echo nil mouse-face nil)
			    str)
    (string-trim-right str "[\n\r]+")))

(defun python-mls-continue-or-send-input ()
  "Either continue an ongoing continued command, or send input."
  (interactive)
  (let ((ln (line-number-at-pos)))
    (if (or
	 (< ln (line-number-at-pos (cdr comint-last-prompt))) ; old input
	 (not (python-mls-in-continuation)) ;; simple command
	 (and (python-mls-line-empty-p)	    ;;final blank lines
	      (let ((lnmx (line-number-at-pos (point-max))))
		(or (eq ln lnmx)
		    (and (eq ln (1- lnmx)) ;trailing blank line OK
			 (python-mls-line-empty-p 1))))))
	(comint-send-input) 		; this is input
      (newline)				;(comint-accumulate)
      (funcall indent-line-function)))) ; NO completion please

(defun python-mls--strip-input-history-properties (_str)
  "Remove 'line-prefix properties from the just-added comint history."
  (if (and comint-input-ring
	   (not (ring-empty-p comint-input-ring)))
      (let ((last (ring-ref comint-input-ring 0)))
	(remove-text-properties
	 0 (length last)
	 '(line-prefix nil font-lock-face nil fontified nil) last))))

(defun python-mls-send-eof (&optional proc)
  (setq python-mls--check-prompt t)
  (process-send-eof proc))

(defun python-mls-delete-or-eof (arg)
  "Delete or send process EOF if at end of buffer.
Does not considering final newline.  With ARG, delete that many characters."
  (interactive "p")
  (let ((proc (get-buffer-process (current-buffer))))
    (if (and proc
	     (= (point) (marker-position (process-mark proc)))
	     (save-excursion (forward-line) (python-mls-line-empty-p)))
	(progn
	  (goto-char (point-max))
	  (comint-kill-input)
	  (python-mls-send-eof proc))
      (delete-char arg))))

(defun python-mls-interrupt (process)
  "Interrupt the PROCESS."
  (interrupt-process process comint-ptyp)
  (process-send-string process "\n"))

(defvar-local python-mls-interrupt-process-function
  #'python-mls-interrupt
  "Function to interrupt the sub-job.  Passed the process.")

(defun python-mls-interrupt-quietly (&optional process)
  "Interrupt the python process and bury any output.
Use PROCESS if it is set."
  (let ((comint-preoutput-filter-functions '(python-shell-output-filter))
        (python-shell-output-filter-in-progress t)
	(python-shell-output-filter-buffer nil)
	(inhibit-quit nil))
    (funcall python-mls-interrupt-process-function process)
    (while python-shell-output-filter-in-progress
      (accept-process-output process)) 	; prompt received
    ;; Interrupted command could have returned before canceled, accept
    ;; any more output
    (accept-process-output process 0.05))
  (setq python-shell-output-filter-buffer nil))

(defun python-mls-invisible-newline ()
  "Insert an invisible, cursor-intangible newline without moving point.
Since continuation prompts use 'line-prefix property, and the
line after a final newline is entirely empty, it has no prompt.
To solve this we keep an invisible and intangible newline at the
end of the buffer."
  (save-excursion
    (insert (propertize "\n"
			'invisible t
			'cursor-intangible t
			'rear-nonsticky '(invisible)))))

(defvar python-mls-continuation-prompt nil
  "Current computed continuation prompt.")
(defvar python-mls-old-prompt nil
  "Last prompt before recent send.")
(defvar-local python-mls-prompt-type nil
  "The type of prompt.
Can be t for normal input prompts, 'pdb for a (i)PDB prompt, or
'unknown for all others.")

;;;###autoload
(defun python-mls-check-prompt (_process output &rest _)
  "Check for prompt, after input is sent.
If a continuation prompt is found in the buffer, fix up comint to
handle it.  Multi-line statements are handled directly.  If a
single command sent to (i)Python is the start of multi-line
statment, the process will return a continuation prompt.  Remove
it, sanitize the history, and then bring the last input forward
to continue.  When the prompt type changes, run the hooks in
`python-mls-prompt-change-functions' (supplying the type as the
argument).  Run the hooks in `python-mls-after-prompt-hook' each
time a know prompt type is detected.  Note that an unknown prompt
type could correspond either to a real non-standard
prompt (e.g. from a python call to input()) or to a 'false
prompt', which may appear if the process produces output in
chunks.  This is because comint is configured to mark any text
not ending in a newline as a prompt, and has no way of knowing
whether all of the output is yet received.  Any hook functions on
`python-mls-prompt-change-functions' should guard against this
possibility by examining their PTYPE argument. "
  (when-let ((python-mls--check-prompt)
	     (process (python-shell-get-process))
	     (pmark (process-mark process)))
    (with-current-buffer (process-buffer process)
      (goto-char pmark)
      (forward-line 0)
      (if (and (looking-at python-mls-continuation-prompt-regexp)
	       (or (not comint-process-echoes) (string-empty-p output)))
	  ;; Continuation prompt: comint performs input echo deletion
	  ;; in comint-send-string, which implicitly calls this filter
	  ;; function while waiting for echoed input to appear.  But
	  ;; echo-detection/deletion must run _first_, before our
	  ;; continuation prompt deletion (which itself would delete
	  ;; the echoed input).  Since comint-send-input calls us
	  ;; finally with an empty string (after echo detection), if
	  ;; process-echoes is set, check and run this only at that
	  ;; time.
	  (let* ((start (marker-position comint-last-input-start))
		 (input (buffer-substring-no-properties
			 start
			 comint-last-input-end))
		 (inhibit-read-only t))
	    (let ((python-mls--check-prompt nil)) ; prevent reentry
	      (python-mls-interrupt-quietly process)) ; re-enters!
	    (delete-region start pmark) ;out with the old
	    (insert input)
	    (funcall indent-line-function)
	    (if (and comint-input-ring
		     (not (ring-empty-p comint-input-ring)))
		(ring-remove comint-input-ring 0)))
	;; All other prompts
	(let ((ptype (if (looking-at python-shell--prompt-calculated-input-regexp)
			 (cond ((< (match-end 0) (point-max)) 'unknown) 
			       ((string-match-p python-shell-prompt-pdb-regexp
						(match-string 0))
				'pdb)
			       (t t))	; just a normal prompt
		       'unknown)) 	; possibly a false prompt due to chunked output
	      (python-mls--check-prompt nil)) ; inhibit re-entry
	  (if (eq ptype t)
	      (python-mls-compute-continuation-prompt (match-string 0)))
	  (unless (eq ptype 'unknown)
	    (let ((inhibit-read-only t))
	      (add-text-properties (line-beginning-position) (1- pmark)
				   '(cursor-intangible t))))
	  (goto-char pmark)
	  (when (not (eq ptype python-mls-prompt-type))
	    (setq python-mls-prompt-type ptype)
	    (run-hook-with-args 'python-mls-prompt-change-functions ptype))
	  (unless (eq ptype 'unknown) 	; could be a "false prompt"
	    (run-hooks 'python-mls-after-prompt-hook)))))))

(defun python-mls-compute-continuation-prompt (prompt)
  "Compute a prompt to use for continuation based on the text of PROMPT."
  (let* ((len (length prompt))
	 (has-colon (string-suffix-p ": " prompt))
	 (spaces (- len 3 (if has-colon 2 1))))
    (setq python-mls-continuation-prompt
	  (if (> len 3)
	      (propertize
	       (concat (make-string spaces ?\s) "..." (if has-colon ": " " "))
	       'font-lock-face 'comint-highlight-prompt)))))

(defun python-mls-strip-last-output-read-only ()
  "Remove any spurious read-only properties from the output.
Since python output can arrive in chunks, and
`inferior-python-mode' enables `comint-prompt-read-only', a
number of false prompts (text not ending in a newline) may be
encountered before the final true prompt.  Comint sets read only
properties on these false prompts, but does not clear them.  When
used as a hook on `python-mls-after-prompt-hook', this function
does so."
  (if-let ((start comint-last-input-end)
	   (prompt (car-safe comint-last-prompt))
	   (inhibit-read-only t))
      (remove-text-properties start (1- prompt) '(read-only))))

(defun python-mls-move-or-history (up &optional arg nocont-move)
  "Move line or recall command history.
When in the first or last line of input, do
`comint-previous-input' for next or previous input, moving by ARG
lines.  Otherwise just move the line.  Move down unless UP is
non-nil.  Also move normally inside of continued commands, unless
NOCONT-MOVE is non-nil."
  (interactive)
  (let* ((prompt (cdr comint-last-prompt))
	 (arg (or arg 1))
	 (arg (if up arg (- arg))))
    (if (and prompt
	     (or nocont-move
		 (if up (and (>= (point) prompt)
			     (= (line-number-at-pos)
				(line-number-at-pos prompt)))
		   (>= (line-number-at-pos)
		       (save-excursion	; Down
			 (goto-char (point-max))
			 (skip-chars-backward "\r\n" (1- (point)))
			 (line-number-at-pos))))))
	(comint-previous-input arg)
      (line-move (- arg)))))

(defun python-mls-up-or-history (&optional arg)
  "When in last line of process buffer, move to previous input.
Otherwise just go up ARG lines."
  (interactive "p")
  (python-mls-move-or-history t arg))

(defun python-mls-down-or-history (&optional arg)
  "When in last line of process buffer, move to next input.
Otherwise just go down ARG line."
  (interactive "p")
  (python-mls-move-or-history nil arg))

(defun python-mls-noblock-up-or-history (&optional arg)
  "Move up in history by ARG without moving through block."
  (interactive "p")
  (python-mls-move-or-history t arg 'noblock))

(defun python-mls-noblock-down-or-history (&optional arg)
  "Move down in history by ARG without moving through block."
  (interactive "p")
  (python-mls-move-or-history nil arg 'noblock))

(defvar-local python-mls-font-lock-keywords nil)
(defun python-mls--fontify-region-function (beg end &optional verbose)
  "Fontification function from BEG to END.
With VERBOSE print fontification status messages."
  (if-let ((process (get-buffer-process (current-buffer)))
	   (pmark (process-mark process)))
      (if (> end pmark)
	  (let ((font-lock-keywords python-mls-font-lock-keywords)
		(font-lock-syntactic-face-function
		 #'python-font-lock-syntactic-face-function)
		(font-lock-dont-widen t)
		(start (max pmark beg)))
	    (put-text-property start end 'line-prefix
			       python-mls-continuation-prompt)
	    (save-restriction
	      (narrow-to-region pmark (point-max))
	      (with-syntax-table python-mode-syntax-table
		(font-lock-default-fontify-region start end verbose)))))))

(defun python-mls--save-input ()
  "Save command input history between sessions."
  (if (and python-mls-save-command-history
	   (stringp python-mls-command-history-file))
      (condition-case nil
	  (let ((comint-input-ring-separator " "))
	    (comint-write-input-ring))
	(error nil))))

(defun python-mls-sentinel (process event)
  "The sentinel function for the mls shell process.
Kill buffer when PROCESS completes on EVENT."
  (let ((buf (process-buffer process)))
    (if (buffer-live-p buf)
	(with-current-buffer buf
	  (run-hooks 'python-mls-sentinel-hooks)
	  (goto-char (point-max))
	  (insert (format "\n\n  Process %s %s" process event))
	  (python-mls--save-input)
	  (if python-mls-kill-buffer-process-quit
	      (kill-buffer buf)
	    (setq python-mls--check-prompt t))))))

(defun python-mls-narrowed-command (command)
  "Call a COMMAND, narrowing to region after prompt."
  (lambda (&rest r)
    (interactive)
    (save-restriction
      (narrow-to-region (cdr-safe comint-last-prompt) (point-max))
      (apply command r))))

(defvar python-mls-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\r"
      #'python-mls-continue-or-send-input)
    (define-key map [(meta return)] #'comint-send-input)
    (define-key map [(shift return)] #'comint-send-input)
    (define-key map [remap previous-line] #'python-mls-up-or-history)
    (define-key map [remap next-line] #'python-mls-down-or-history)
    (define-key map [remap python-shell-completion-complete-or-indent]
      #'indent-for-tab-command) ; restore
    (define-key map [(meta up)] #'comint-previous-matching-input-from-input)
    (define-key map [(meta down)] #'comint-next-matching-input-from-input)
    (define-key map (kbd "C-d") #'python-mls-delete-or-eof)
    (cl-loop for cmd in python-mls-import-python-nav-command-list
	     do
	     (if (consp cmd)
		 (define-key map (cdr cmd)
		   (python-mls-narrowed-command (consp cmd)))
	       (substitute-key-definition
		cmd (python-mls-narrowed-command cmd) map python-mode-map)))
    map))

(defun python-mls--comint-output-filter-fix-rear-nonsticky (&rest _r)
  "Works around a text property comint bug in Emacs <28.
Used as :after advice for `comint-output-filter'."
  (if comint-last-prompt
      (let ((inhibit-read-only t))
	(add-text-properties
	 (car comint-last-prompt)
	 (cdr comint-last-prompt)
	 '(rear-nonsticky ; work around bug#47603
	   (field inhibit-line-move-field-capture
		  read-only font-lock-face))))))

(defun python-mls-python-setup ()
  "Set `python-mode' buffers to exclude `line-prefix' on yank."
  (make-local-variable 'yank-excluded-properties) ; for python-mls
  (cl-pushnew 'line-prefix yank-excluded-properties))

;;;###autoload
(defun python-mls-setup (&optional disable)
  "Enable python-mls for python shells and buffers.
If DISABLE is non-nil, disable instead."
  (interactive)
  (if disable
      (progn
	(remove-hook 'inferior-python-mode-hook #'python-mls-mode)
	(remove-hook 'python-mode-hook #'python-mls-python-setup)
	(if (version< emacs-version "28")
	    (advice-remove #'comint-output-filter
			   #'python-mls--comint-output-filter-fix-rear-nonsticky)))
    ;; Shift up/C-p: skips blocks
    (when python-mls-multiline-history-modifier
      (dolist (key (where-is-internal 'previous-line))
	(let ((new (vector `(,@python-mls-multiline-history-modifier
			     ,(aref key 0)))))
	  (define-key python-mls-mode-map new 'python-mls-noblock-up-or-history)))
      (dolist (key (where-is-internal 'next-line))
	(let ((new (vector `(,@python-mls-multiline-history-modifier
			     ,(aref key 0)))))
	  (define-key python-mls-mode-map new 'python-mls-noblock-down-or-history))))
    (add-hook 'inferior-python-mode-hook #'python-mls-mode)
    (add-hook 'python-mode-hook #'python-mls-python-setup)
    (setq-default python-shell-font-lock-enable nil) ; we do our own
    ;; Fix bug in rear-nonsticky
    (if (version< emacs-version "28")
	(advice-add 'comint-output-filter :after
		    #'python-mls--comint-output-filter-fix-rear-nonsticky))))

;;;###autoload
(define-minor-mode python-mls-mode
  "Minor mode enabling multi-line statements in inferior (i)Python buffers."
  :keymap python-mls-mode-map
  (if python-mls-mode
      (progn
	;; command history
	(when python-mls-save-command-history
	  (make-local-variable 'python-mls-command-history-file)
	  (unless (file-name-absolute-p python-mls-command-history-file)
	    (setq python-mls-command-history-file
		  (expand-file-name (concat python-mls-command-history-file
					    "-"
					    python-shell-buffer-name)
				    user-emacs-directory)))
	  (when (stringp python-mls-command-history-file)
	    (set (make-local-variable 'comint-input-ring-file-name)
		 python-mls-command-history-file)
	    (if (file-regular-p python-mls-command-history-file)
		(let ((comint-input-ring-separator " "))
		  (comint-read-input-ring))))
	  (let ((process (get-buffer-process (current-buffer))))
	    (set-process-sentinel process #'python-mls-sentinel))
	  (add-hook 'kill-buffer-hook #'python-mls--save-input nil t))
	(setq-local comint-history-isearch 'dwim)

	;; font-lock handling
	(setq-local
	 font-lock-keywords-only nil
	 syntax-propertize-function python-syntax-propertize-function
	 comment-start-skip "#+\\s-*"
	 parse-sexp-ignore-comments t
	 forward-sexp-function #'python-nav-forward-sexp
	 parse-sexp-lookup-properties t
	 font-lock-fontify-region-function
	 #'python-mls--fontify-region-function
	 comint-move-point-for-output t
	 comint-input-sender #'python-mls-send-input)
	(setq python-mls-font-lock-keywords
	      (symbol-value
	       (font-lock-choose-keywords
		python-font-lock-keywords (font-lock-value-in-major-mode
					   font-lock-maximum-decoration))))

	(setq-local comint-get-old-input #'python-mls-get-old-input
		    comint-history-isearch 'dwim)
	(add-hook 'comint-input-filter-functions
		  #'python-mls--strip-input-history-properties nil t)

	;; We run this :after so that  `comint-last-prompt' is already set
	(advice-add #'comint-output-filter :after #'python-mls-check-prompt)
	(cursor-intangible-mode 1)

	;; indentation
	(electric-indent-local-mode -1) ; We handle [Ret] indentation ourselves
	(setq-local indent-line-function #'python-mls--indent-line)
	(add-hook 'python-mls-after-prompt-hook
		  #'python-mls-strip-last-output-read-only -95 t))
    (python-mls-setup 'disable)
    (message "Python-MLS disabled for future inferior python shells.")))

(provide 'python-mls)

;;; python-mls.el ends here
