;;; cern-root-mode.el --- Major-mode for running C++ code with ROOT  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Jay Morgan

;; Author: Jay Morgan <jay@morganwastaken.com>
;; Keywords: languages, tools
;; Package-Version: 20220520.1817
;; Package-Commit: 2df8781df1d807bf522eb19ac7b03b4bfaeb89c0
;; Version: 0.1.4
;; Homepage: https://github.com/jaypmorgan/cern-root-mode
;; Package-Requires: ((emacs "26.1"))

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

;; ROOT (https://root.cern/) is a framework for performing data
;; analysis.  This package means to integrate this framework within the
;; ecosystem of Emacs.  More specifically, root.el provides functions
;; to run C++ code within the ROOT REPL and execute org-mode source
;; code blocks, replicating the jupyter environment in `root
;; --notebook'.

;;; Code:

(require 'ob) ;; org-babel
(require 'comint)
(require 'cl-lib)
(require 'cc-cmds)
(unless (require 'vterm nil 'noerror)
  ;; if vterm isn't available then we need these to prevent
  ;; byte-compilation warnings
  (defvar vterm-shell)
  (declare-function vterm "vterm" (buffer-name))
  (declare-function vterm-send-return "vterm" ()))

(defcustom cern-root-mode nil
  "Major-mode for running C++ code with ROOT."
  :group 'languages
  :type 'mode)

(defcustom cern-root-filepath "root"
  "Path to the ROOT executable."
  :type 'string
  :group 'cern-root-mode)

(defcustom cern-root-command-options ""
  "Command line options for running ROOT."
  :type 'string
  :group 'cern-root-mode)

(defcustom cern-root-prompt-regex "^\\(?:root \\(?:(cont'ed, cancel with .@) \\)?\\[[0-9]+\\]\s?\\)"
  "Regular expression to find prompt location in ROOT-repl."
  :type 'string
  :group 'cern-root-mode)

(defcustom cern-root-terminal-backend 'inferior
  "Type of terminal to use when running ROOT."
  :type 'symbol
  :options '(inferior vterm)
  :group 'cern-root-mode)

(defcustom cern-root-buffer-name "*ROOT*"
  "Name of the newly create buffer for ROOT."
  :type 'string
  :group 'cern-root-mode)

;;; end of user variables

(defmacro cern-root--remembering-position (&rest body)
  "Execute BODY and return to exact position in buffer and window."
  `(save-window-excursion (save-excursion ,@body)))

(defun cern-root--push-new (element lst)
  "Push ELEMENT onto LST if it doesn't yet exist in LST."
  (if (memq element lst)
      lst
    (push element lst)))

(defun cern-root--pluck-item (el lst)
  "Return the value of EL in the plist LST."
  (cdr (assoc el lst)))

(defun cern-root--make-earmuff (name)
  "Give a NAME earmuffs, i.e. some-name -> *some-name*."
  (if (or (not (stringp name))  ;; only defined for strings
	  (= (length name) 0)   ;; but not empty strings
	  (and (string= "*" (substring name 0 1))
	       (string= "*" (substring name (1- (length name))))))
      name
    (format "*%s*" name)))

(defun cern-root--make-no-earmuff (name)
  "Remove earmuffs from a NAME if it has them, *some-name* -> some-name."
  (if (and (stringp name)
	   (> (length name) 0)
	   (string= "*" (substring name 0 1))
	   (string= "*" (substring name (1- (length name)))))
      (substring name 1 (1- (length name)))
    name))

(defun cern-root-->> (&rest body)
  "Process BODY sequentially."
  (cl-reduce (lambda (prev next) (funcall (eval next) prev))
	     (cdr body)
	     :initial-value (eval (car body))))

(defvar cern-root--backend-functions
  '((vterm . ((start-terminal . cern-root--start-vterm)
	      (send-function . cern-root--send-vterm)
	      (previous-prompt . vterm-previous-prompt)
	      (next-prompt . vterm-next-prompt)))
    (inferior . ((start-terminal . cern-root--start-inferior)
		 (send-function . cern-root--send-inferior)
		 (previous-prompt . comint-previous-prompt)
		 (next-prompt . comint-next-prompt))))
  "Mapping from terminal type to various specific functions.")

(defun cern-root--get-functions-for-terminal (terminal)
  "Get all functions defined for TERMINAL."
  (cern-root--pluck-item terminal cern-root--backend-functions))

(defun cern-root--get-function-for-terminal (terminal function-type)
  "Get function of FUNCTION-TYPE for TERMINAL."
  (cern-root--pluck-item function-type (cern-root--get-functions-for-terminal terminal)))

(defun cern-root--get-function-for-current-terminal (function-type)
  "Get function of FUNCTION-TYPE for currently defined terminal."
  (cern-root--get-function-for-terminal cern-root-terminal-backend function-type))

(defalias 'cern-root--ctfun #'cern-root--get-function-for-current-terminal
  "ctfun -- current terminal function")

(defun cern-root--send-vterm (proc input)
  "Send INPUT (a string) to the vterm REPL running as PROC."
  (ignore proc)
  (cern-root--remembering-position
   (cern-root-switch-to-repl)
   (when (fboundp 'vterm-send-string)
     (vterm-send-string input)
     (vterm-send-return))))

(defun cern-root--send-inferior (proc input)
  "Send INPUT to an inferior REPL running as PROC."
  (comint-send-string proc (format "%s\n" input)))

(defun cern-root--preinput-clean (input)
  "Clean INPUT before sending to the process."
  ;; move the template definition onto the same line as the function declaration
  (replace-regexp-in-string "template<\\(.*\\)>\n" "template<\\1>" (format "%s" input)))

(defun cern-root--send-string (proc input)
  "Send INPUT to the ROOT repl running as PROC."
  (funcall (cern-root--ctfun 'send-function) proc (cern-root--preinput-clean input)))

(defun cern-root--start-vterm ()
  "Run an instance of ROOT in vterm."
  (let ((vterm-shell cern-root-filepath))
    (vterm cern-root-buffer-name)))

(defun cern-root--start-inferior ()
  "Run an inferior instance of ROOT."
  (let ((cern-root-exe cern-root-filepath)
	(buffer (comint-check-proc (cern-root--make-no-earmuff cern-root-buffer-name)))
	(created-vars (cern-root--set-env-vars)))
    (pop-to-buffer-same-window
     (if (or buffer (not (derived-mode-p 'cern-root-mode))
	     (comint-check-proc (current-buffer)))
	 (get-buffer-create (or buffer cern-root-buffer-name))
       (current-buffer)))
    (unless buffer
      (make-comint-in-buffer (cern-root--make-no-earmuff cern-root-buffer-name) buffer cern-root-exe nil cern-root-command-options)
      (cern-root-mode))
    (when created-vars
      (sleep-for 0.1)  ;; give enough time for ROOT to start before removing vars
      (cern-root--unset-env-vars))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Input buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cern-root--make-text-property (input)
  "Add initial text-properties to INPUT."
  (propertize "root_input_2"
	      'buffer-state input
	      'face 'kaiti-red
	      'read-only t))

(defun cern-root--text-property-get-contents (text)
  "Get the buffer-state text-property from TEXT."
  (get-text-property 0 'buffer-state text))

(defun cern-root--make-temporary-buffer (text)
  "Create a temporary file and populate it with TEXT."
  (cern-root--remembering-position
   (let* ((temp-file (format "%s.C" (make-temp-file "root")))
	  (buf       (find-file temp-file)))
     (switch-to-buffer buf)
     (insert (cern-root--text-property-get-contents text))
     (write-file temp-file nil)
     (kill-buffer buf)
     temp-file)))

(defun cern-root--send-input-buffer (input)
  "Send INPUT to the currently running process."
  (let* ((text (cern-root--make-text-property input))
	 (file (cern-root--make-temporary-buffer text)))
    (cern-root--remembering-position
     (cern-root-switch-to-repl)
     (let ((pos (point)))
       (print pos)
       (cern-root-eval-file file)
       (sleep-for 0.5)
       (goto-char (point-max))
       (let ((end-post (point)))
	 (delete-region pos end-post)
	 (goto-char (point-max))
	 (let ((new-point (point)))
	   (cern-root--send-string cern-root-buffer-name "\n")
	   (sleep-for 0.5)
	   (goto-char new-point)
	   (insert text)
	   (goto-char (point-max))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Major mode & comint functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar cern-root--rcfile "./.rootrc")

(defun cern-root--set-env-vars ()
  "Set the environment variable for current directory.

Setup the environment variables so that no colours or bold fonts
will be used in the REPL.  This prevents comint from creating
duplicated input in trying to render the ascii colour codes.

Function returns t if the variables have been set, else nil.  This
return value is very useful for deciding if the variables should
be unset, as we will want not want to remove the user's existing
rcfiles."
  (if (not (file-exists-p cern-root--rcfile))  ;; don't clobber existing rcfiles
    (let ((vars (list "PomptColor" "TypeColor" "BracketColor" "BadBracketColor" "TabComColor"))
	  (val  "default")
	  (buf  (create-file-buffer cern-root--rcfile)))
      (with-current-buffer buf
	(insert (apply #'concat (mapcar (lambda (v) (format "Rint.%s\t\t%s\n" v val)) vars)))
	(write-file cern-root--rcfile nil))
      (kill-buffer buf))
    nil))

(defun cern-root--unset-env-vars ()
  "Remove the environment file from the directory."
  (delete-file cern-root--rcfile))

(defun cern-root--initialise ()
  "Set the comint variables for buffer."
  (setq comint-process-echoes t
	comint-use-prompt-regexp t))

(defvar cern-root-mode-map
  (let ((map (nconc (make-sparse-keymap) comint-mode-map)))
    (define-key map "\t" 'completion-at-point)
    map)
  "Basic mode map for ROOT.")

(define-derived-mode cern-root-mode comint-mode
  "ROOT"
  "Major for `cern-root-run'.

\\<cern-root-mode-map>"
  nil "ROOT"
  (setq comint-prompt-regexp cern-root-prompt-regex
	comint-prompt-read-only nil
	process-connection-type 'pipe)
  (set (make-local-variable 'paragraph-separate) "\\'")
  (set (make-local-variable 'paragraph-start) cern-root-prompt-regex)
  (set (make-local-variable 'comint-input-sender) 'cern-root--send-string)
  (cern-root--initialise))

;; (defun org-babel-execute:root (body params)
;;   "Execute a block of C++ code with ROOT in org-mode."
;;   (message "Executing C++ source code block in ROOT"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Completion framework
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar cern-root--keywords nil)

(defvar cern-root--completion-buffer-name "*ROOT Completions*")

(defun cern-root--get-last-output ()
  "Get output of the last command."
  ;; TODO: needs improvement to better capture the last output
  (cern-root--remembering-position
   (cern-root-switch-to-repl)
   (goto-char (point-max))
   (let* ((regex (format "%s.*" (substring cern-root-prompt-regex 1)))
	  (np (re-search-backward regex))
	  (pp (progn (re-search-backward regex)
		    (forward-line)
		    (point))))
     (buffer-substring-no-properties pp np))))

(defun cern-root--completion-filter-function (text)
  "Set the list of keywords to be the output of tab (TEXT)."
  (setf cern-root--keywords text))

(defun cern-root--clear-completions ()
  "Clear the output of completions from the comint buffer."
  (when (get-buffer cern-root--completion-buffer-name)
    (with-current-buffer cern-root--completion-buffer-name
      (erase-buffer))))

(defun cern-root--get-partial-input (beg end)
  "Get the partially entered input from the buffer starting from BEG to END."
  (buffer-substring-no-properties beg end))

(defun cern-root--remove-ansi-escape-codes (string)
  "Remove ansi escape codes from STRING."
  (let ((regex "\\[[0-9;^kD]+m?"))
    (replace-regexp-in-string regex "" string)))

(defun cern-root--get-completions-from-buffer ()
  "Get the list of possible completions from the comint buffer."
  (with-current-buffer cern-root--completion-buffer-name
    (while (not comint-redirect-completed)
      (sleep-for 0.01))
    (setq cern-root--keywords (split-string (cern-root--remove-ansi-escape-codes (buffer-string)) "\n"))))

(defun cern-root--comint-dynamic-completion-function ()
  "Return the list of possible completions.  UNUSED."
  (cl-return)
  (when-let* ((bound (bounds-of-thing-at-point 'symbol))
	      (beg   (car bound))
	      (end   (cdr bound)))
    (when (> end beg)
      (let ((partial-input (cern-root--get-partial-input beg end)))
	(message partial-input)
	(cern-root--clear-completions)
	(comint-redirect-send-command-to-process
	 (format "%s\t" partial-input) cern-root--completion-buffer-name cern-root-buffer-name "" nil)
	(list beg end cern-root--keywords . nil)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org-babel definitions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(add-to-list 'org-src-lang-modes '("cern-root" . c++))

;;;###autoload
(defun org-babel-execute:root (body params)
  "Execute a C++ `org-mode' source code block (BODY) with PARAMS in ROOT REPL."
  (message "Executing C++ source code block with ROOT")
  (print params)
  (let ((session (cern-root--pluck-item :session params)))
    (if (not (string= session "none"))  ;; handle the user set session parameter
	(cern-root--org-babel-execute-session session body params)
      (cern-root--org-babel-execute-temp-session body params))))

(defun cern-root--org-babel-cmdline-clean-result (string filename)
  "Clean the STRING of running ROOT from the command line using FILENAME."
  (replace-regexp-in-string (format "\nProcessing %s...\n" filename) "" string))

(defun cern-root--org-babel-cmdline-simple-wrapper (body func)
  "Wrap the BODY within a void FUNC call."
  (format "void %s() {\n%s\n}" func body))

(defun cern-root--org-babel-kill-session ()
  "Kill the current ROOT session."
  (cern-root--send-string cern-root-buffer-name ".q"))

(defun cern-root--org-babel-start-session ()
  "Start a root session."
  (cern-root--remembering-position (cern-root-run)))

(defun cern-root--org-babel-execute-temp-session (body params)
  "Run BODY in a temporary session, ignoring PARAMS."
  (ignore params)
  (unwind-protect
      (progn
	(cern-root--org-babel-start-session)
	(cern-root--send-string cern-root-buffer-name body)
	(sleep-for 0.5)  ;; wait for the output to be printed in the REPL
	(let ((output (cern-root--get-last-output)))
	  (cern-root--org-babel-kill-session)
	  output))
    (cern-root--org-babel-kill-session)))

(defun cern-root--org-babel-execute-session (session body params)
  "Run BODY in SESSION, ignoring PARAMS."
  (ignore params)
  (let ((cern-root-buffer-name (cern-root--make-earmuff session)))
    (unless (get-buffer cern-root-buffer-name)
      (cern-root--remembering-position
       (cern-root-run)))
    (cern-root--send-string cern-root-buffer-name body)
    (sleep-for 0.5)
    (cern-root--get-last-output)))

(defun cern-root--org-babel-execute-no-session (body params)
  "Run BODY with no session, ignoring PARAMS."
  (ignore params)
  (let* ((file (org-babel-temp-file "root" ".C"))
	 (func (replace-regexp-in-string ".C" "" (car (last (split-string file "/")))))
	 (cmd  (format "%s -b -l -q %s" cern-root-filepath file)))
    (org-babel-with-temp-filebuffer file
      (insert (cern-root--org-babel-cmdline-simple-wrapper body func))
      (save-buffer))
    (cern-root--org-babel-cmdline-clean-result (org-babel-eval cmd "") file)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defun cern-root-run ()
  "Run an inferior instance of ROOT."
  (interactive)
  (funcall (cern-root--ctfun 'start-terminal)))

;;;###autoload
(defun cern-root-run-other-window ()
  "Run an inferior instance of ROOT in an different window."
  (interactive)
  (split-window-sensibly)
  (other-window 1)
  (cern-root-run))

(defun cern-root-switch-to-repl ()
  "Switch to the ROOT REPL."
  (interactive)
  (let ((win (get-buffer-window cern-root-buffer-name)))
    (if win
	(select-window win)
      (switch-to-buffer cern-root-buffer-name))))

(defun cern-root-eval-region (beg end)
  "Evaluate a region from BEG to END in ROOT."
  (interactive "r")
  (kill-ring-save beg end)
  (let ((string (format "%s" (buffer-substring beg end))))
    (cern-root-switch-to-repl)
    (cern-root--send-string cern-root-buffer-name string)))

(defun cern-root-eval-string (string)
  "Send and evaluate a STRING in the ROOT REPL."
  (cern-root--send-string cern-root-buffer-name string))

(defun cern-root-eval-line ()
  "Evaluate this line in ROOT."
  (interactive)
  (let ((beg (point-at-bol))
	(end (point-at-eol)))
    (cern-root-eval-region beg end)))

(defun cern-root-eval-defun ()
  "Evaluate a function in ROOT."
  (interactive)
  (cern-root--remembering-position
   (c-mark-function)
   (cern-root-eval-region (region-beginning) (region-end))))

(defun cern-root-eval-defun-maybe ()
  "Evaluate a defun in ROOT if in declaration else just the line."
  (interactive)
  (condition-case err
      (cern-root-eval-defun)
    ('error (progn (ignore err)
		   (cern-root-eval-line)))))

(defun cern-root-eval-buffer ()
  "Evaluate the buffer in ROOT."
  (interactive)
  (cern-root--remembering-position
   (cern-root-eval-region (point-min) (point-max))))

(defun cern-root-eval-file (filename)
  "Evaluate FILENAME in ROOT."
  (interactive "fFile to load: ")
  (comint-send-string cern-root-buffer-name (concat ".U " filename "\n"))
  (comint-send-string cern-root-buffer-name (concat ".L " filename "\n")))

(defun cern-root-change-working-directory (dir)
  "Change the working directory of ROOT to DIR."
  (interactive "DChange to directory: ")
  (comint-send-string cern-root-buffer-name (concat "gSystem->cd(\"" (expand-file-name dir) "\")\n")))

(defun cern-root-list-input-history ()
  "List the history of previously entered statements."
  (interactive)
  (comint-dynamic-list-input-ring))

(provide 'cern-root-mode)
;;; cern-root-mode.el ends here
