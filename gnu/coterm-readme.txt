;;; coterm.el --- Terminal emulation for comint -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Free Software Foundation, Inc.

;; Filename: coterm.el
;; Author: jakanakaevangeli <jakanakaevangeli@chiru.no>
;; Version: 1.1
;; Keywords: processes
;; Package-Requires: ((emacs "26.1"))
;; URL: https://repo.or.cz/emacs-coterm.git

;; This file is part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; If the global `coterm-mode' is enabled, proper terminal emulation will be
;; supported for all newly spawned comint processes.  This allows you to use
;; more complex console programs such as "less" and "mpv" and full-screen TUI
;; programs such as "vi", "top", "htop" or even "emacs -nw".
;;
;; In addition to that, the following two local minor modes may be used:
;;
;; `coterm-char-mode': If enabled, most characters you type are sent directly
;; to the subprocess, which is useful for interacting with full-screen TUI
;; programs.
;;
;; `coterm-auto-char-mode' If enabled, coterm will enter and leave
;; `coterm-char-mode' automatically as appropriate.  For example, if you
;; execute "less" in a shell buffer, coterm will detect that "less" is running
;; and automatically enable char mode so that you can interact with less
;; normally.  Once you leave the "less" program, coterm will disable char mode
;; so that you can interact with your shell in the normal comint way.  This
;; mode is enabled by default in all coterm comint buffers.
;;
;; Automatic entrance into char mode is indicated by "AChar" in the modeline.
;; Non-automatic entrance into char mode is indicated by "Char".
;; Automatic exit of char mode is indicated by no text in the modeline.
;; Non-automatic exit of char mode is indicated by "Line".
;;
;; The command `coterm-char-mode-cycle' is a handy command to cycle between
;; automatic char-mode, char-mode enabled and char-mode disabled.
;;
;; Installation:
;;
;; Add the following to your Emacs init file:
;;
;;   (add-to-list 'load-path "/path/to/emacs-coterm")
;;   (require 'coterm)
;;   (coterm-mode)
;;
;;   ;; Optional: bind `coterm-char-mode-cycle' to C-; in comint
;;   (with-eval-after-load 'comint
;;     (define-key comint-mode-map (kbd "C-;") #'coterm-char-mode-cycle))
;;
;;   ;; If your process repeats what you have already typed, try customizing
;;   ;; `comint-process-echoes':
;;   ;;   (setq-default comint-process-echoes t)
;;
;;
;; Differences from M-x term:
;;
;; coterm is written as an upgrade to comint.  For existing comint users, the
;; behaviour of comint doesn't change with coterm enabled except for the added
;; functionality that we can now use TUI programs.  It is therefore good for
;; users who generally prefer comint to term.el but sometimes miss the superior
;; terminal emulation that term.el provides.
;;
;; Coterm also provides `coterm-auto-char-mode' which aims to eliminate the
;; need to manually enable and disable char mode.
;;
;;
;; Some common probles:
;;
;; If some TUI programs misbehave, try checking your TERM environment variable
;; with 'echo $TERM' in your coterm enabled M-x shell.  It should normally be
;; set to "coterm-color".  If if isn't, it might be that one of your shell
;; initialization files (~/.bashrc) changes it, so check for that and remove
;; the change.
;;
;; The default "less" prompt, when invoked as 'less ~/some/file', is too
;; generic and isn't recognized by `coterm-auto-char-mode', so char mode isn't
;; entered automatically.  It is recommended to make your "less" prompt more
;; complete and recognizable by adding the character "m" or "M" to your LESS
;; environment variable.  For example, in your ~/.bashrc, add this line:
;;
;;   export LESS="FRXim"
;;
;; The "FRX" options make "less" more compatible with "git", and the "i" option
;; enables case insensitive search in less.  See man page less(1) for more
;; information.  Automatic char mode detection also usually fails if
;; "--incsearch" is enabled in "less".  It is advised to either turn this
;; option off or to use manual char mode.
;;
;;
;; Bugs, suggestions and patches can be sent to
;;
;;    bugs-doseganje (at) groups.io
;;
;; and can be viewed at https://groups.io/g/bugs-doseganje/topics.  As this
;; package is stored in GNU ELPA, non-trivial patches require copyright
;; assignment to the FSF, see info node "(emacs) Copyright Assignment".
;;
;; Some useful information you can send in your bug reports:
;;
;; After enabling `coterm-mode', open up an M-x shell and copy the output of
;; the following shell command:
;;
;;   export | cat -v | grep 'LESS\|TERM'; stty;
;;
;; You can also set the variable `coterm--t-log-buffer' to "coterm-log",
;; reproduce the issue and attach the contents of the buffer named
;; "coterm-log", which now contains all process output that was sent to coterm.

;;; Code:

(require 'term)
(eval-when-compile
  (require 'cl-lib))

;;; Mode functions and configuration

(defcustom coterm-term-name term-term-name
  "Name to use for TERM.
coterm will use this option to set the TERM environment variable
for the subprocess.  TUI programs usually consult this
environment variable to decide which escape sequences it should
send to the terminal.  It is recommended to leave this set to
\"eterm-color\", the terminal type coterm emulates."
  :group 'comint
  :type 'string)

(defvar coterm-termcap-format term-termcap-format
  "Termcap capabilities supported by coterm.")

(defvar coterm-term-environment-function #'comint-term-environment
  "Function to calculate environment for comint processes.
If non-nil, it is called with zero arguments and should return a
list of environment variable settings to apply to comint
subprocesses.")

(defvar coterm-start-process-function #'start-file-process
  "Function called to start a comint process.
It is called with the same arguments as `start-process' and
should return a process.")

(define-advice comint-exec-1 (:around (f &rest args) coterm-config)
  "Make spawning processes for comint more configurable.
With this advice installed on `coterm-exec-1', you use the
settings `coterm-extra-environment-function' and
`coterm-start-process-function' to control how comint spawns a
process."
  (cl-letf*
      ((start-file-process (symbol-function #'start-file-process))
       (comint-term-environment (symbol-function #'comint-term-environment))
       ((symbol-function #'start-file-process)
        (lambda (&rest args)
          (fset #'start-file-process start-file-process)
          (apply coterm-start-process-function args)))
       ((symbol-function #'comint-term-environment)
        (lambda (&rest args)
          (fset #'comint-term-environment comint-term-environment)
          (apply coterm-term-environment-function args))))
    (apply f args)))

;;;###autoload
(define-minor-mode coterm-mode
  "Improved terminal emulation in comint processes.
When this mode is enabled, terminal emulation is enabled for all
newly spawned comint processes, allowing you to use more complex
console programs such as \"less\" and \"mpv\" and full-screen
programs such as \"vi\", \"top\", \"htop\" or even \"emacs -nw\".

Environment variables for comint processes are set according to
variables `coterm-term-name' and `coterm-termcap-format'."
  :global t
  :group 'comint
  (if coterm-mode

      (progn
        (add-hook 'comint-mode-hook #'coterm--init)
        (setq coterm-term-environment-function
              (lambda ()
                (let (ret)
                  (push (format "TERMINFO=%s" data-directory)
                        ret)
                  (when coterm-term-name
                    (push (format "TERM=%s" coterm-term-name) ret))
                  (when coterm-termcap-format
                    (push (format coterm-termcap-format "TERMCAP="
                                  coterm-term-name
                                  (floor (window-screen-lines))
                                  (window-max-chars-per-line))
                          ret))
                  ret)))
        (setq coterm-start-process-function
              (lambda (name buffer command &rest switches)
                (apply #'start-file-process name buffer
                       ;; Adapted from `term-exec-1'
                       "sh" "-c"
                       (format "stty -nl sane -echo 2>%s;\
if [ $1 = .. ]; then shift; fi; exec \"$@\"" null-device)
                       ".." command switches))))

    (remove-hook 'comint-mode-hook #'coterm--init)
    (setq coterm-term-environment-function #'comint-term-environment)
    (setq coterm-start-process-function #'start-file-process)))

;;; Char mode

(defvar coterm-char-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map term-raw-map)
    (define-key map [remap term-char-mode] #'coterm-char-mode-cycle)
    (define-key map [remap term-line-mode] #'coterm-char-mode-cycle)
    map))

(define-minor-mode coterm-char-mode
  "Send characters you type directly to the inferior process.
When this mode is enabled, the keymap `coterm-char-mode-map' is
active, which inherits from `term-raw-map'.  In this map, each
character is sent to the process, except for the escape
character (usually C-c).  You can set `term-escape-char' to
customize it."
  :lighter "")

(defvar-local coterm--char-old-scroll-margin nil)

(define-minor-mode coterm-scroll-snap-mode
  "Keep scroll synchronized.
Useful for full-screen terminal programs to keep them on screen."
  :keymap nil
  (if coterm-scroll-snap-mode
      (progn
        (unless coterm--char-old-scroll-margin
          (setq coterm--char-old-scroll-margin
                (cons scroll-margin
                      (local-variable-p 'scroll-margin)))
          (setq-local scroll-margin 0))
        (add-hook 'coterm-t-after-insert-hook #'coterm--scroll-snap 'append t)
        (coterm--scroll-snap))
    (when-let ((margin coterm--char-old-scroll-margin))
      (setq coterm--char-old-scroll-margin nil)
      (if (cdr margin)
          (setq scroll-margin (car margin))
        (kill-local-variable 'scroll-margin)))
    (remove-hook 'coterm-t-after-insert-hook #'coterm--scroll-snap t)))

(defun coterm--scroll-snap ()
  ;; We need to check for `coterm-scroll-snap-mode' because a function in
  ;; `coterm-t-after-insert-hook' might have changed it
  (when coterm-scroll-snap-mode
    (let* ((buf (current-buffer))
           (pmark (process-mark (get-buffer-process buf)))
           (sel-win (selected-window))
           (w sel-win))
      ;; Avoid infinite loop in strange case where minibuffer window
      ;; is selected but not active.
      (while (window-minibuffer-p w)
        (setq w (next-window w nil t)))
      (while
          (progn
            (when (and (eq buf (window-buffer w))
                       ;; Only snap if point is on pmark
                       (= (window-point w) pmark))
              (if (eq sel-win w)
                  (progn
                    (coterm--t-goto 0 0)
                    (recenter 0)
                    (goto-char pmark))
                (with-selected-window w
                  (coterm--t-goto 0 0)
                  (recenter 0)
                  (goto-char pmark))))
            (setq w (next-window w nil t))
            (not (eq w sel-win)))))))

(defvar coterm-auto-char-mode)

(defun coterm-char-mode-cycle ()
  "Cycle between char mode on, off and auto.

If `coterm-auto-char-mode' is enabled, disable it and enable
both `coterm-char-mode' and `coterm-scroll-snap-mode'.

If `coterm-char-mode' is enabled, disable it along with
`coterm-scroll-snap-mode'.

If it is disabled, enable `coterm-auto-char-mode'."
  (interactive)
  (cond
   (coterm-auto-char-mode
    (coterm-auto-char-mode -1)
    (coterm-char-mode 1)
    (coterm-scroll-snap-mode 1))
   (coterm-char-mode
    (coterm-char-mode -1)
    (coterm-scroll-snap-mode -1))
   (t (coterm-auto-char-mode 1))))

;;;; Automatic entry to char mode

(define-minor-mode coterm-auto-char-mode
  "Whether we should enter or leave char mode automatically.
If enabled, `coterm-auto-char-functions' are consulted to set
`coterm-char-mode' and `coterm-scroll-snap-mode' automatically.

By default, functions in `coterm-auto-char-functions' try to
guess which mode is appropriate based on various heuristics.  See
their doc strings for more information."
  :lighter ""
  (if coterm-auto-char-mode
      (progn
        (add-hook 'coterm-t-after-insert-hook #'coterm--auto-char nil t)
        (add-hook 'post-command-hook #'coterm--auto-char nil t)
        (coterm--auto-char))
    (remove-hook 'coterm-t-after-insert-hook #'coterm--auto-char t)
    (remove-hook 'post-command-hook #'coterm--auto-char t)))

(defvar coterm-auto-char-lighter-mode-format
  '(coterm-char-mode (coterm-auto-char-mode " AChar" " Char")
                     (coterm-auto-char-mode "" " Line")))

(define-minor-mode coterm-auto-char-lighter-mode
  "Show current char mode status in modeline."
  :lighter coterm-auto-char-lighter-mode-format)

(defvar coterm-auto-char-functions
  (list #'coterm--auto-char-less-prompt
        #'coterm--auto-char-mpv-prompt
        #'coterm--auto-char-not-eob
        #'coterm--auto-char-leave-both)
  "Abnormal hook to enter or leave `coterm-char-mode'.
This hook is run after every command and process output, if
`coterm-auto-char-mode' enabled.  It is only called if point is
on process's mark.

Each function is called with zero argumets and with `point-max'
on the end of process output until one returns non-nil.")

(defun coterm--auto-char ()
  "Automatically enter or leave `coterm-char-mode'.
If point is not on process mark, leave `coterm-char-mode' and
`coterm-scroll-snap-mode'.  Otherwise, call functions from
`coterm-auto-char-functions' until one returns non-nil."
  (let* ((proc (get-buffer-process (current-buffer)))
         (pmark (and proc (process-mark proc))))
    (if (and pmark (= (point) pmark))
        (save-restriction
          (coterm--narrow-to-process-output pmark)
          (run-hook-with-args-until-success 'coterm-auto-char-functions))
      (when coterm-char-mode (coterm-char-mode -1))
      (when coterm-scroll-snap-mode (coterm-scroll-snap-mode -1)))))

(defun coterm--auto-char-less-prompt ()
  "Enter `coterm-char-mode' if a \"less\" prompt is detected.
In addition, temporarily modify `coterm-auto-char-functions' such
that char mode is maintained even if the user presses \"/\",
\":\", \"ESC\", \"-\" or a digit."
  (when (and (eobp) (coterm--auto-char-less-prompt-1))
    (unless coterm-char-mode (coterm-char-mode 1))
    (unless coterm-scroll-snap-mode (coterm-scroll-snap-mode 1))
    (cl-labels
        ((hook ()
           (if (not (eobp))
               (rem-hook)
             (or
              (bolp)                    ; Empty last line if "less" is slow
              (coterm--auto-char-less-prompt-1)
              (progn
                (forward-line 0)
                ;; Various secondary prompts that "less" outputs
                (prog1 (looking-at (concat
                                    "\\(?: ESC\\| :\\)\\'\\|"
                                    "Examine: \\|"
                                    "[Ll]og file: \\|"
                                    "Target line: \\|"
                                    "Backwards scroll limit: \\|"
                                    "\\(?:set \\|goto \\||\\)mark: \\|"
                                    "[:_+!-]\\|"
                                    "\\(?:.* \\)?[/?]"))
                  (goto-char (point-max))))
              (rem-hook))))
         (rem-hook ()
           (remove-hook 'coterm-auto-char-functions #'hook t)
           (remove-hook 'coterm-auto-char-mode-hook #'rem-hook t)
           (remove-hook 'coterm-char-mode-hook #'rem-hook t)
           (remove-hook 'coterm-scroll-snap-mode-hook #'rem-hook t)
           nil))
      (add-hook 'coterm-auto-char-functions #'hook nil t)
      (add-hook 'coterm-auto-char-mode-hook #'rem-hook nil t)
      (add-hook 'coterm-char-mode-hook #'rem-hook nil t)
      (add-hook 'coterm-scroll-snap-mode-hook #'rem-hook nil t))
    t))

(defun coterm--auto-char-less-prompt-1 ()
  "Return t if point is after a less prompt."
  (let ((opoint (point)))
    (forward-line 0)
    (prog1 (looking-at
            (concat
             "\\(?:"
             ":\\|"
             "\\(?:.* \\)?" "(END)\\|"
             "byte [0-9]+\\|"
             "lines [0-9]+-[0-9]+\\|"
             "100%\\|"
             "\\(?:.* \\)?" "[0-9]?[0-9]%\\|"
             ".*(press h for help or q to quit)\\|"
             ".*(press RETURN)"
             "\\)\\'"))
      (goto-char opoint))))

(defun coterm--auto-char-mpv-prompt ()
  "Enter `coterm-char-mode' if a mpv prompt is detected.
However, simply entering it isn't satisfactory, because mpv often
erases its status prompt for brief periods of time before
redrawing it again.  Because we don't want to leave char mode for
these brief periods, we temporarily modify
`coterm-auto-char-functions' such that `coterm-char-mode' is kept
active if these status prompt erasures are detected."
  (when (coterm--auto-char-mpv-prompt-1)
    (coterm-char-mode 1)
    (cl-labels
        ((hook ()
           (or (coterm--auto-char-mpv-prompt-1)
               ;; If we are on the last lane and this line is empty, it is
               ;; likely because mpv has erased its status buffer for a brief
               ;; period before redrawing it.
               (and (eobp) (bolp))
               (ignore (rem-hook))))
         (rem-hook ()
           (remove-hook 'coterm-auto-char-functions #'hook t)
           (remove-hook 'coterm-auto-char-mode-hook #'rem-hook t)
           (remove-hook 'coterm-char-mode-hook #'rem-hook t)
           (remove-hook 'coterm-scroll-snap-mode-hook #'rem-hook t)))
      (add-hook 'coterm-auto-char-functions #'hook nil t)
      (add-hook 'coterm-auto-char-mode-hook #'rem-hook nil t)
      (add-hook 'coterm-char-mode-hook #'rem-hook nil t)
      (add-hook 'coterm-scroll-snap-mode-hook #'rem-hook nil t))
    t))

(defun coterm--auto-char-mpv-prompt-1 ()
  "Return t if mpv is likely running."
  (when (bolp)
    (let ((opoint (point)))
      (forward-line -1)
      (prog1 (looking-at
              (concat "\\(?:.*\n\\)?"
                      "\\(?:(Paused) \\)?"
                      "\\(?:[AV]\\|AV\\): "
                      "[0-9][0-9]:[0-9][0-9]:[0-9][0-9] / "
                      "[0-9][0-9]:[0-9][0-9]:[0-9][0-9] "
                      "([0-9]?[0-9]%).*"
                      "\\(?:"
                      "\n\\[-*\\+-*\\]"
                      "\\)?"
                      "\\'"))
        (goto-char opoint)))))

(defun coterm--auto-char-not-eob ()
  "Enter `coterm-char-mode' if a full-screen TUI program is detected.
We assume that if the cursor moves more than 9 lines above the
bottom row, a full-screen program is likely being drawn.  In this
case, enter `coterm-char-mode' and `coterm-scroll-snap-mode' and
temporarily modify `coterm-auto-char-functions' such that we will
only leave these modes once cursor moves to the bottom line."
  (when (looking-at "\\(?:.*\n\\)\\{9,\\}")
    (coterm-char-mode 1)
    (coterm-scroll-snap-mode 1)
    (cl-labels
        ((hook ()
           (or (looking-at ".*\n.")
               (ignore (rem-hook))))
         (rem-hook ()
           (remove-hook 'coterm-auto-char-functions #'hook t)
           (remove-hook 'coterm-auto-char-mode-hook #'rem-hook t)
           (remove-hook 'coterm-char-mode-hook #'rem-hook t)
           (remove-hook 'coterm-scroll-snap-mode-hook #'rem-hook t)))
      (add-hook 'coterm-auto-char-functions #'hook nil t)
      (add-hook 'coterm-auto-char-mode-hook #'rem-hook nil t)
      (add-hook 'coterm-char-mode-hook #'rem-hook nil t)
      (add-hook 'coterm-scroll-snap-mode-hook #'rem-hook nil t))
    t))

(defun coterm--auto-char-leave-both ()
  (when coterm-char-mode (coterm-char-mode -1))
  (when coterm-scroll-snap-mode (coterm-scroll-snap-mode -1))
  t)

(defun coterm--narrow-to-process-output (pmark)
  "Widen and narrow to process output.
If there is no user input at end of buffer, simply widen.  PMARK
is the process mark."
  (widen)
  (unless comint-use-prompt-regexp
    (unless (eq (get-char-property (max 1 (1- (point-max))) 'field)
                'output)
      (narrow-to-region
       (point-min)
       (previous-single-property-change (point-max) 'field nil pmark)))))

;;; Terminal emulation

;; This is essentially a re-implementation of term.el's terminal emulation.  I
;; could have simply reused functions from term.el but that would have been
;; unsatisfactory in my opinion.  That is mostly due to the fact that term.el's
;; terminal emulation inserts a lot of redundant trailing whitespace end empty
;; lines, which I believe is very distracting for ordinary comint usage.
;;
;; Terminal emulation is coordinate based, for example, "move cursor to row 11
;; and column 21".  A coordinate position may not be reachable in an Emacs
;; buffer because the specified line is currently too short or there aren't
;; enough lines in the buffer.  term.el automatically inserts empty lines and
;; spaces in order to move point to a specified coordinate position.  This
;; results in trailing whitespace.
;;
;; coterm takes a different approach.  Instead of moving point, the current
;; terminal cursor coordinates are kept in the variables `coterm--t-row' and
;; `coterm--t-col'.  Moving the terminal cursor simply means adjusting these
;; two variables, no whitespace needs to be inserted.  Point and process mark
;; are usually not guaranteed to be anywhere near the current coordinate
;; position and are only restored at the end of the main filter function
;; `coterm--t-emulate-terminal'.  Only when terminal emulation requires
;; insertion of actual text do we have to be able to reach the current cursor
;; coordinates.  We may have to insert newlines and spaces to make this
;; position reachable, but inserting text after this whitespace means that it
;; isn't trailing or redundant (except if the inserted text consists of only
;; whitespace).
;;
;;
;; Line wrapping:
;;
;; term.el wraps lines correctly and accurately.  When text is to be inserted
;; at the right edge, term.el will first move the cursor to the beginning of
;; the next line.
;;
;; The beauty of comint, on the other hand, is that it inserts long lines
;; unchanged and leaves line wrapping up to Emacs.  One can easily use
;; `toggle-truncate-lines' or even `word-wrap' to change display of long lines
;; from compiler output for example.  That is why it was decided that coterm
;; will follow suit and insert long lines unchanged.  However, this means that
;; terminal emulation isn't fully accurate for long lines.  Up to now, "less"
;; was the only program I've encountered that relies on accurate line wrapping,
;; so a workaround aimed at "less" specifically was implemented (search for the
;; term "less" in the function `coterm--t-emulate-terminal'.

(defconst coterm--t-control-seq-regexp
  ;; Differences from `term-control-seq-regexp':
  ;;
  ;; For optimization, we try matching "\r\n" as whole, if possible, instead of
  ;; \r and \n separately
  ;;
  ;; Removed: \032 (\C-z)
  ;; Added: OSC sequence \e] ... ; ... \e\\ (or \a)
  ;; Added: sequences \e= and \e>
  (concat
   ;; A control character,
   "\\(?:[\n\000\007\t\b\016\017]\\|\r\n?\\|"
   ;; a C1 escape coded character (see [ECMA-48] section 5.3 "Elements
   ;; of the C1 set"),
   "\e\\(?:[DM78c=>]\\|"
   ;; Emacs specific control sequence from term.el.  In coterm, we simply
   ;; ignore them.
   "AnSiT[^\n]+\n\\|"
   ;; OSC seqence.  We print them normally to let
   ;; `comint-output-filter-functions' handle them
   "][0-9A-Za-z]*;.*?\\(?:\a\\|\e\\\\\\)\\|"
   ;; or an escape sequence (section 5.4 "Control Sequences"),
   "\\[\\([\x30-\x3F]*\\)[\x20-\x2F]*[\x40-\x7E]\\)\\)")
  "Regexp matching control sequences handled by coterm.")

(defconst coterm--t-control-seq-prefix-regexp "\e")

(defvar coterm--t-log-buffer nil
  "If non-nil, log process output to this buffer.
Set it to a name of a buffer if you want to record process output
for debugging purposes.")

(defvar-local coterm--t-height nil
  "Number of lines in window.")
(defvar-local coterm--t-width nil
  "Number of columns in window.")
(defvar-local coterm--t-scroll-beg nil
  "First row of the scrolling area.")
(defvar-local coterm--t-scroll-end nil
  "First row after the end of the scrolling area.")

(defvar-local coterm--t-home-marker nil
  "Marks the \"home\" position for cursor addressing.
`coterm--t-home-offset' should be taken into account as well.")
(defvar-local coterm--t-home-offset 0
  "How many rows lower the home position actually is.
This usually is needed if `coterm--t-home-marker' is on the last
line of the buffer.")
(defvar-local coterm--t-row nil
  "Current position from home marker.
If nil, the current position is at process mark.")
(defvar-local coterm--t-col nil
  "Current position from home marker.
If nil, the current position is at process mark.")

(defvar-local coterm--t-pmark-in-sync nil
  "If t, pmark is guaranteed to be in sync.
In sync with variables `coterm--t-home-marker',
`coterm--t-home-offset', `coterm--t-row' and `coterm--t-col'")

(defvar-local coterm--t-saved-cursor nil)
(defvar-local coterm--t-insert-mode nil)
(defvar-local coterm--t-unhandled-fragment nil)

(defvar coterm-t-after-insert-hook nil
  "Hook run after inserting process output.")

(defun coterm--comint-strip-CR (_)
  "Remove all \\r characters from last output."
  (save-excursion
    (goto-char comint-last-output-start)
    (let ((pmark (process-mark (get-buffer-process (current-buffer)))))
      (while (progn (skip-chars-forward "^\r")
                    (< (point) pmark))
        (delete-char 1)))))

(defun coterm--init ()
  "Initialize current buffer for coterm."
  (when-let ((process (get-buffer-process (current-buffer))))
    (setq coterm--t-height (floor (window-screen-lines)))
    (setq coterm--t-width (window-max-chars-per-line))
    (setq coterm--t-home-marker (point-min-marker))
    (setq coterm--t-scroll-beg 0)
    (setq coterm--t-scroll-end coterm--t-height)

    (setq-local comint-inhibit-carriage-motion t)
    (add-hook 'comint-output-filter-functions #'coterm--comint-strip-CR nil t)
    (coterm-auto-char-mode)
    (coterm-auto-char-lighter-mode)

    (add-function :filter-return
                  (local 'window-adjust-process-window-size-function)
                  (lambda (size)
                    (when size
                      (coterm--t-reset-size (cdr size) (car size)))
                    size)
                  '((name . coterm-maybe-reset-size)))

    (add-function :around (process-filter process)
                  #'coterm--t-emulate-terminal)))

(defun coterm--t-reset-size (height width)
  (setq coterm--t-height height)
  (setq coterm--t-width width)
  (setq coterm--t-scroll-beg 0)
  (setq coterm--t-scroll-end height)
  (setq coterm--t-pmark-in-sync nil)

  (when coterm--t-row
    (setq coterm--t-col (max coterm--t-col (1- coterm--t-width)))
    (when (>= coterm--t-row coterm--t-height)
      (cl-incf coterm--t-home-offset (- coterm--t-row coterm--t-height -1))
      (setq coterm--t-row (1- coterm--t-height))
      (let ((opoint (point)))
        (coterm--t-normalize-home-offset)
        (goto-char opoint)))))

(defun coterm--t-goto (row col)
  "Move point to a position that approximates ROW and COL.
Return non-nil if the position was actually reached."
  (goto-char coterm--t-home-marker)
  (and
   (zerop (forward-line
           (+ coterm--t-home-offset row)))
   (bolp)
   (<= col (move-to-column col))))

(defun coterm--t-apply-proc-filt (proc-filt process str)
  "Insert STR using PROC-FILT and PROCESS.
Basically, call PROC-FILT with the arguments PROCESS and STR, but
adjusting `ansi-color-context-region' beforehand."
  (when-let ((context ansi-color-context-region)
             (marker (cadr context)))
    (set-marker marker (process-mark process)))
  (funcall proc-filt process str))

(defun coterm--t-delete-region (row1 col1 &optional row2 col2)
  "Delete text between two positions.
Deletes resulting trailing whitespace as well.  ROW1, COL1, ROW2
and COL2 specify the two positions.  ROW2 and COL2 can be nil, in
which case delete to `point-max'.

This function moves point to the beginning of the deleted
region."
  (coterm--t-goto row1 col1)
  (delete-region (point)
                 (if row2
                     (progn (coterm--t-goto row2 col2) (point))
                   (point-max)))
  ;; Delete resulting trailing whitespace.  This may move the home marker under
  ;; some circumstances ((coterm--t-delete-region 0 0), for example), so adjust
  ;; it afterwards.
  (let* ((home coterm--t-home-marker)
         (old-home (marker-position home)))
    (when (eolp)
      (let ((opoint (point)))
        (skip-chars-backward " ") (delete-region (point) opoint)))
    (when (eobp)
      (let ((opoint (point)))
        (skip-chars-backward "\n") (delete-region (point) opoint)))
    (unless (= old-home home)
      (cl-incf coterm--t-home-offset (- old-home home))
      (goto-char home)
      (forward-line 0)
      (set-marker home (point))))
  (setq coterm--t-pmark-in-sync nil))

(defun coterm--t-open-space (proc-filt process newlines spaces)
  "Insert NEWLINES newlines and SPACES spaces at point.
Insert them using PROC-FILT and PROCESS.  Afterwards, remove
characters that were moved after the column specified by
`coterm--t-width'."
  (unless (eobp)
    (set-marker (process-mark process) (point))
    (coterm--t-apply-proc-filt
     proc-filt process
     (concat (make-string newlines ?\n)
             (unless (eolp)
               (make-string spaces ?\s))))
    ;; Delete chars that are after the width of the terminal
    (goto-char (process-mark process))
    (move-to-column coterm--t-width)
    (delete-region (point) (progn (forward-line 1) (1- (point))))
    (setq coterm--t-pmark-in-sync nil)))

(defun coterm--t-normalize-home-offset ()
  (goto-char coterm--t-home-marker)
  (let ((left-to-move (forward-line coterm--t-home-offset)))
    (unless (bolp)
      (cl-incf left-to-move)
      (forward-line 0))
    (set-marker coterm--t-home-marker (point))
    (setq coterm--t-home-offset (max 0 left-to-move))))

(defun coterm--t-scroll-by-deletion-p ()
  (or (/= coterm--t-scroll-beg 0)
      (/= coterm--t-scroll-end coterm--t-height)))

(defun coterm--t-down-line (proc-filt process)
  "Go down one line or scroll if at bottom.
This takes into account the scroll region as specified by
`coterm--t-scroll-beg' and `coterm--t-scroll-end'.  If required,
PROC-FILT and PROCESS are used to scroll with deletion and
insertion of empty lines."
  (cond
   ((and (= coterm--t-row (1- coterm--t-scroll-end))
         (coterm--t-scroll-by-deletion-p))
    (coterm--t-delete-region coterm--t-scroll-beg 0
                             (1+ coterm--t-scroll-beg) 0)
    (coterm--t-goto coterm--t-row 0)
    (coterm--t-open-space proc-filt process 1 0))
   ((and (= coterm--t-row (1- coterm--t-height))
         (coterm--t-scroll-by-deletion-p))
    ;; Behaviour of xterm
    (ignore))
   ((< coterm--t-row (1- coterm--t-height))
    (cl-incf coterm--t-row))
   (t
    (cl-incf coterm--t-home-offset)
    (coterm--t-normalize-home-offset)))
  (setq coterm--t-pmark-in-sync nil))

(defun coterm--t-up-line (proc-filt process)
  "Go up one line or scroll if at top.
This takes into account the scroll region as specified by
`coterm--t-scroll-beg' and `coterm--t-scroll-end'.  If required,
PROC-FILT and PROCESS are used to scroll with deletion and
insertion of empty lines."
  (cond
   ((and (= coterm--t-row coterm--t-scroll-beg)
         (coterm--t-scroll-by-deletion-p))
    (coterm--t-delete-region (1- coterm--t-scroll-end) 0
                             coterm--t-scroll-end 0)
    (coterm--t-goto coterm--t-row 0)
    (coterm--t-open-space proc-filt process 1 0))
   ((and (= coterm--t-row 0)
         (coterm--t-scroll-by-deletion-p))
    ;; Behaviour of xterm
    (ignore))
   ((< 0 coterm--t-row)
    (cl-decf coterm--t-row))
   (t
    (coterm--t-delete-region (1- coterm--t-scroll-end) 0)
    (cl-decf coterm--t-home-offset)
    (coterm--t-normalize-home-offset)))
  (setq coterm--t-pmark-in-sync nil))

(defun coterm--t-adjust-pmark (proc-filt process)
  "Set PROCESS's mark to `coterm--t-row' and `coterm--t-col'.
If necessary, this function inserts newlines and spaces using
PROC-FILT, so use it sparingly, usually only before inserting
non-whitespace text."
  (unless coterm--t-pmark-in-sync
    (let ((pmark (process-mark process)))
      (goto-char coterm--t-home-marker)

      (let ((newlines (forward-line
                       (+ coterm--t-row coterm--t-home-offset))))
        (unless (bolp)
          (cl-incf newlines))
        (unless (zerop newlines)
          (set-marker pmark (point))
          (coterm--t-apply-proc-filt
           proc-filt process (make-string newlines ?\n))))

      (let ((col (move-to-column coterm--t-col)))
        (set-marker pmark (point))
        (when (< col coterm--t-col)
          (coterm--t-apply-proc-filt
           proc-filt process (make-string (- coterm--t-col col) ?\s)))))
    (setq coterm--t-pmark-in-sync t)
    (coterm--t-normalize-home-offset)))

(defun coterm--t-insert (proc-filt process str newlines)
  "Insert STR using PROC-FILT and PROCESS.
Synchronise PROCESS's mark beforehand and insert at its position.
NEWLINES is the number of newlines STR contains.  Unless it is
zero, insertion must happen at the end of accessible portion of
buffer and the scrolling region must cover the whole screen."
  (coterm--t-adjust-pmark proc-filt process)
  (let ((pmark (process-mark process)))
    (goto-char pmark)
    (coterm--t-apply-proc-filt proc-filt process str)
    (goto-char pmark))
  (let ((column (current-column)))
    (if (zerop newlines)
        (if coterm--t-insert-mode
            ;; In insert mode, delete text outside the width of the terminal
            (progn
              (move-to-column coterm--t-width)
              (delete-region
               (point) (progn (forward-line 1) (1- (point)))))
          ;; If not in insert mode, replace text
          (when (> column coterm--t-col)
            (delete-region
             (point)
             (progn (move-to-column (- (* 2 column) coterm--t-col))
                    (point)))))
      (cl-incf coterm--t-row newlines)
      ;; We've inserted newlines, so we must scroll if necessary
      (when (>= coterm--t-row coterm--t-height)
        (goto-char coterm--t-home-marker)
        (forward-line (+ coterm--t-home-offset
                         (- coterm--t-row coterm--t-height -1)))
        (set-marker coterm--t-home-marker (point))
        (setq coterm--t-home-offset 0)
        (setq coterm--t-row (1- coterm--t-height))))
    (setq coterm--t-col column)))

(defun coterm--t-adjust-from-pmark (pos)
  "Point `coterm--t-row' and `coterm--t-col' POS."
  (coterm--t-normalize-home-offset)
  (goto-char pos)
  (setq coterm--t-col (current-column))
  (forward-line 0)
  (if (> (point) coterm--t-home-marker)
      ;; Here, `coterm--t-home-offset' is guaranteed to be 0
      (save-restriction
        (narrow-to-region coterm--t-home-marker (point))
        (let ((lines-left (forward-line (- 1 coterm--t-height))))
          (when (= 0 lines-left)
            (set-marker coterm--t-home-marker (point)))
          (setq coterm--t-row (+ -1 coterm--t-height lines-left))))
    (progn
      (set-marker coterm--t-home-marker (point))
      (setq coterm--t-home-offset 0)
      (setq coterm--t-row 0))))

(defun coterm--t-emulate-terminal (proc-filt process string)
  (let* ((pmark (process-mark process))
         (match 0)
         (will-insert-newlines 0)
         (inhibit-read-only t)
         restore-point
         last-match-end
         old-pmark
         buf
         ctl-params ctl-end)

    (cl-macrolet
        ;; Macros for looping through control sequences
        ((ins ()
           `(progn
              (let ((str (substring string last-match-end match)))
                (unless (equal "" str)
                  (coterm--t-insert proc-filt process str
                                    will-insert-newlines)
                  (setq will-insert-newlines 0)))
              (setq last-match-end ctl-end)))
         (dirty ()
           `(setq coterm--t-pmark-in-sync nil))
         (pass-through ()
           `(ignore))
         (car-or-1 ()
           `(max 1 (car ctl-params)))
         (cadr-or-0 ()
           `(or (cadr ctl-params) 0)))

      (if (not (and string
                    (setq buf (process-buffer process))
                    (buffer-live-p buf)))
          (funcall proc-filt process string)

        (with-current-buffer buf
          (when coterm--t-log-buffer
            (with-current-buffer (get-buffer-create coterm--t-log-buffer)
              (save-excursion
                (goto-char (point-max))
                (insert (make-string 70 ?=) ?\n)
                (insert string ?\n))))

          (when-let ((fragment coterm--t-unhandled-fragment))
            (setq string (concat fragment string))
            (setq coterm--t-unhandled-fragment nil))

          (setq restore-point (if (= (point) pmark) pmark (point-marker)))
          (setq old-pmark (copy-marker pmark window-point-insertion-type))
          (coterm--t-adjust-from-pmark pmark)
          (setq coterm--t-pmark-in-sync t)

          (save-restriction
            (coterm--narrow-to-process-output pmark)

            (while (setq match (string-match coterm--t-control-seq-regexp
                                             string ctl-end))
              (setq ctl-params (match-string 1 string))
              (setq ctl-end (match-end 0))

              (pcase (aref string match)
                ((and ?\r (guard (= ctl-end (+ 2 match))))
                 ;; A match string of length two and beginning with \r means
                 ;; that we have matched "\r\n".  In this case, and if we are
                 ;; at eob, we pass-through to avoid an unnecessary call to
                 ;; `substring' which is expensive.  In the most common case
                 ;; when the process just outputs text at eob without any
                 ;; control sequences, we will end up inserting the whole
                 ;; string without a single call to `substring'.
                 (if (and coterm--t-pmark-in-sync
                          (= pmark (point-max))
                          (not (coterm--t-scroll-by-deletion-p)))
                     (progn (pass-through)
                            (cl-incf will-insert-newlines))
                   (ins)
                   (setq coterm--t-col 0)
                   (coterm--t-down-line proc-filt process)))
                (?\n (ins) ;; (terminfo: cud1, ind)
                     (coterm--t-down-line proc-filt process))
                (?\r (ins) ;; (terminfo: cr)
                     (setq coterm--t-col 0)
                     (dirty))
                ;; TAB (terminfo: ht)
                ((and ?\t
                      (guard coterm--t-pmark-in-sync)
                      (guard (= pmark (point-max)))
                      (guard (not (coterm--t-scroll-by-deletion-p))))
                 ;; Insert a TAB as is, if at eob
                 (pass-through))
                (?\t
                 ;; Otherwise, move cursor to the next tab stop
                 (ins)
                 (setq coterm--t-col
                       (min (1- coterm--t-width)
                            (+ coterm--t-col 8 (- (mod coterm--t-col 8)))))
                 (dirty))
                (?\b (ins) ;; (terminfo: cub1)

                     (when (and (= coterm--t-col (1+ coterm--t-width))
                                (not (coterm--t-scroll-by-deletion-p))
                                (coterm--t-goto coterm--t-row coterm--t-col)
                                (eq (char-before) ?\s))
                       ;; Awkward hack to make line-wrapping work in "less".
                       ;; Very specific to the way "less" performs wrapping:
                       ;; When reaching the end of line, instead of sending
                       ;; "\r\n" to go to the start of the next line, it sends
                       ;; " \b": a space which wraps to the next line in most
                       ;; terminals and a backspace to move to the start of the
                       ;; line.  Here we detect this and handle it like an
                       ;; ordinary "\r\n".
                       ;;
                       ;; For all other cases, coterm does not perform any
                       ;; wrapping at all.
                       (delete-char -1)
                       (coterm--t-down-line proc-filt process)
                       (setq coterm--t-col 0)
                       (coterm--t-insert proc-filt process " " 0))

                     (setq coterm--t-col (max (1- coterm--t-col) 0))
                     (dirty))
                (?\C-g (ins) ;; (terminfo: bel)
                       (beep t))
                ;; Ignore NUL, Shift Out, Shift In.
                ((or ?\0 14 15 '()) (ins))
                (?\e
                 (pcase (aref string (1+ match))
                   (?D (ins)
                       (coterm--t-down-line proc-filt process))
                   (?M (ins) ;; (terminfo: ri)
                       (coterm--t-up-line proc-filt process))
                   (?7 (ins) ;; Save cursor (terminfo: sc)
                       (setq coterm--t-saved-cursor
                             (list coterm--t-row
                                   coterm--t-col
                                   ansi-color-context-region
                                   ansi-color-context)))
                   (?8 (ins) ;; Restore cursor (terminfo: rc)
                       (when-let ((cursor coterm--t-saved-cursor))
                         (setq coterm--t-row (max (car cursor) (1- coterm--t-height)))
                         (setq cursor (cdr cursor))
                         (setq coterm--t-col (max (car cursor) (1- coterm--t-width)))
                         (setq cursor (cdr cursor))
                         (setq ansi-color-context-region (car cursor))
                         (setq ansi-color-context (cadr cursor))
                         (dirty)))
                   (?c (ins) ;; \Ec - Reset (terminfo: rs1)
                       (erase-buffer)
                       (setq ansi-color-context-region nil)
                       (setq ansi-color-context nil)
                       (setq coterm--t-home-offset 0)
                       (setq coterm--t-row 0)
                       (setq coterm--t-col 0)
                       (setq coterm--t-scroll-beg 0)
                       (setq coterm--t-scroll-end coterm--t-height)
                       (setq coterm--t-insert-mode nil))
                   (?\] (pass-through)) ;; OSC sequence, handled by comint
                   (?A (ins)) ;; Ignore term.el specific \eAnSiT sequences
                   ;; mpv outputs sequences \E= and \E>.  Ignore them
                   ((or ?= ?>) (ins))
                   (?\[
                    (pcase (aref string (1- ctl-end))
                      (?m ;; Let `comint-output-filter-functions' handle this
                       (pass-through))
                      (char
                       (setq ctl-params (mapcar #'string-to-number
                                                (split-string ctl-params ";")))
                       (ins)
                       (pcase char
                         (?H ;; cursor motion (terminfo: cup,home)
                          (setq coterm--t-row
                                (1- (max 1 (min (car-or-1) coterm--t-height))))
                          (setq coterm--t-col
                                (1- (max 1 (min (cadr-or-0) coterm--t-width))))
                          (dirty))
                         (?A ;; cursor up (terminfo: cuu, cuu1)
                          (setq coterm--t-row (max (- coterm--t-row (car-or-1))
                                                   coterm--t-scroll-beg))
                          (dirty))
                         (?B ;; cursor down (terminfo: cud)
                          (setq coterm--t-row (min (+ coterm--t-row (car-or-1))
                                                   (1- coterm--t-scroll-end)))
                          (dirty))
                         (?C ;; \E[C - cursor right (terminfo: cuf, cuf1)
                          (setq coterm--t-col (min (+ coterm--t-col (car-or-1))
                                                   (1- coterm--t-width)))
                          (dirty))
                         (?D ;; \E[D - cursor left (terminfo: cub)
                          (setq coterm--t-col (max (- coterm--t-col (car-or-1))
                                                   0))
                          (dirty))
                         (?E ;; \E[E - cursor down and column 0
                          (setq coterm--t-row (min (+ coterm--t-row (car-or-1))
                                                   (1- coterm--t-scroll-end)))
                          (setq coterm--t-col 0)
                          (dirty))
                         (?F ;; \E[F - cursor up and column 0
                          (setq coterm--t-row (max (- coterm--t-row (car-or-1))
                                                   coterm--t-scroll-beg))
                          (setq coterm--t-col 0)
                          (dirty))
                         (?G ;; \E[G - horizontal cursor position
                          (setq coterm--t-col (min (1- (car-or-1))
                                                   (1- coterm--t-width)))
                          (dirty))
                         ;; \E[J - clear to end of screen (terminfo: ed, clear)
                         ((and ?J (guard (eq 0 (car ctl-params))))
                          (coterm--t-delete-region coterm--t-row coterm--t-col))
                         ((and ?J (guard (eq 1 (car ctl-params))))
                          (coterm--t-delete-region 0 0 coterm--t-row
                                                   coterm--t-col)
                          (coterm--t-open-space
                           proc-filt process coterm--t-row coterm--t-col))
                         (?J (coterm--t-delete-region 0 0))
                         ;; \E[K - clear to end of line (terminfo: el, el1)
                         ((and ?K (guard (eq 1 (car ctl-params))))
                          (coterm--t-delete-region coterm--t-row 0
                                                   coterm--t-row coterm--t-col)
                          (coterm--t-open-space proc-filt process 0 coterm--t-col))
                         (?K (coterm--t-delete-region
                              coterm--t-row coterm--t-col
                              coterm--t-row coterm--t-width))
                         (?L ;; \E[L - insert lines (terminfo: il, il1)
                          (when (<= coterm--t-scroll-beg coterm--t-row
                                    (1- coterm--t-scroll-end))
                            (let ((lines
                                   (min (- coterm--t-scroll-end coterm--t-row)
                                        (car-or-1))))
                              ;; Remove from bottom
                              (coterm--t-delete-region
                               (- coterm--t-scroll-end lines) 0
                               coterm--t-scroll-end 0)
                              ;; Insert at position
                              (coterm--t-goto coterm--t-row 0)
                              (coterm--t-open-space proc-filt process lines 0))))
                         (?M ;; \E[M - delete lines (terminfo: dl, dl1)
                          (when (<= coterm--t-scroll-beg coterm--t-row
                                    (1- coterm--t-scroll-end))
                            (let ((lines
                                   (min (- coterm--t-scroll-end coterm--t-row)
                                        (car-or-1))))
                              ;; Insert at bottom
                              (coterm--t-goto coterm--t-scroll-end 0)
                              (coterm--t-open-space proc-filt process lines 0)
                              ;; Remove at position
                              (coterm--t-delete-region
                               coterm--t-row 0
                               (+ coterm--t-row lines) 0))))
                         (?P ;; \E[P - delete chars (terminfo: dch, dch1)
                          (coterm--t-delete-region
                           coterm--t-row coterm--t-col
                           coterm--t-row (+ coterm--t-col (car-or-1))))
                         (?@ ;; \E[@ - insert spaces (terminfo: ich)
                          (let ((width (min (car-or-1) (- coterm--t-width
                                                          coterm--t-col -1))))
                            (coterm--t-goto coterm--t-row coterm--t-col)
                            (coterm--t-open-space proc-filt process 0 width)
                            (cl-incf coterm--t-col width)
                            (setq coterm--t-col (min coterm--t-col
                                                     (1- coterm--t-width)))
                            (dirty)))
                         (?h ;; \E[?h - DEC Private Mode Set
                          (pcase (car ctl-params)
                            ;; (49 ;; (terminfo: smcup)
                            ;;  (coterm--t-switch-to-alternate-sub-buffer t))
                            (4 ;; (terminfo: smir)
                             (setq coterm--t-insert-mode t))))
                         (?l ;; \E[?l - DEC Private Mode Reset
                          (pcase (car ctl-params)
                            ;; (49 ;; (terminfo: rmcup)
                            ;;  (coterm--t-switch-to-alternate-sub-buffer nil))
                            (4 ;; (terminfo: rmir)
                             (setq coterm--t-insert-mode nil))))
                         (?n ;; \E[6n - Report cursor position (terminfo: u7)
                          (process-send-string
                           process
                           ;; (terminfo: u6)
                           (format "\e[%s;%sR"
                                   (1+ coterm--t-row)
                                   (1+ coterm--t-col))))
                         (?r ;; \E[r - Set scrolling region (terminfo: csr)
                          (let ((beg (1- (car-or-1)))
                                (end (max 1 (cadr-or-0))))
                            (setq coterm--t-scroll-beg
                                  (if (< beg coterm--t-height) beg 0))
                            (setq coterm--t-scroll-end
                                  (if (<= 1 end coterm--t-height)
                                      end coterm--t-height))))))))))))

            (cond
             ((setq match (string-match coterm--t-control-seq-prefix-regexp
                                        string ctl-end))
              (ins)
              (setq coterm--t-unhandled-fragment (substring string match)))
             ((null last-match-end)
              ;; Optimization: no substring means no string copying
              (coterm--t-insert proc-filt process string will-insert-newlines))
             (t
              (ins)))

            ;; Synchronize pmark and remove all trailing whitespace after it.
            (coterm--t-adjust-pmark proc-filt process)
            (widen)
            (goto-char pmark)
            (skip-chars-forward " \n")
            (when (eobp)
              (delete-region pmark (point))))

          ;; Restore point (this restores it only for the selected window)
          (goto-char restore-point)
          (unless (eq restore-point pmark)
            (set-marker restore-point nil))

          ;; Restore points of non-selected windows, if their `window-point'
          ;; was on pmark
          (let* ((sel-win (selected-window))
                 (w (next-window sel-win nil t)))
            ;; Avoid infinite loop in strange case where minibuffer window
            ;; is selected but not active.
            (while (window-minibuffer-p w)
              (setq w (next-window w nil t)))
            (while (not (eq w sel-win))
              (and (eq buf (window-buffer w))
                   (= (window-point w) old-pmark)
                   (set-window-point w pmark))
              (setq w (next-window w nil t)))
            (set-marker old-pmark nil))

          (run-hooks 'coterm-t-after-insert-hook))))))

(provide 'coterm)
;;; coterm.el ends here
