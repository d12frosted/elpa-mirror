;;; smart-dash.el --- Smart-Dash minor mode
;; Package-Version: 20210427.1709
;; Package-Commit: bc740889dd81e7dc8a90a33d1f075f21aba9b2d3

;; Copyright (C) 2008-2010 Dennis Lambe Jr.

;; Author: Dennis Lambe Jr. <malsyned@malsyned.net>
;; Webpage: http://malsyned.net/smart-dash.html

;; Smart-Dash is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 2 of the License, or
;; (at your option) any later version.

;; Smart-Dash is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Smart-Dash.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Smart-Dash mode is a minor mode which redefines the dash key to
;; insert an underscore within C-style identifiers and a dash
;; otherwise.

;;; Code:

(defgroup smart-dash nil
  "Intelligently insert either a dash or an underscore depending
on context."
  :group 'convenience
  :prefix "smart-dash")

(defcustom smart-dash-c-modes '(c-mode c++-mode objc-mode)
  ; Remove definition with (makunbound 'smart-dash-c-modes)
  "Major modes in which _> should be replaced by the -> struct
pointer member access operator and __ should be replaced by the
-- post-decrement operator."
  :group 'smart-dash
  :type '(repeat symbol))

;;; Smart-Dash mode Keymaps and Mode Functions ;;;

;; I tried also mapping "_" to the inverse operation, but it made it
;; much more awkward to type double-underscored identifiers like
;; __attribute__.  The default Emacs C-q escape works almost as well
;; and doesn't have nasty interactions with common cases.
;; <kp-subtract> on the numeric keypad can also be used to always
;; insert a dash.
(easy-mmode-defmap smart-dash-mode-keymap
   ; Remove definition with (makunbound 'smart-dash-mode-keymap)
   `(("-" . smart-dash-insert)
     (,(kbd "<kp-subtract>") . smart-dash-insert-dash))
   "Key map for `smart-dash-mode'.")

;;;###autoload
(define-minor-mode smart-dash-mode
  "Redefine the dash key to insert an underscore within C-style
identifiers and a dash otherwise.  This allows you to type
all_lowercase_c_identifiers as comfortably as you would
lisp-style-identifiers.

While Smart-Dash mode is active, you can type \\[quoted-insert] -
or use the minus key on the numeric keypad to override it and
insert a dash after a C-style identifier character.  You might
need to do this if you want to type a cramped-looking expression
like x-5.

If Smart-Dash mode is activated while in a C-like mode (c-mode,
c++-mode, and objc-mode by default, customizable with
`smart-dash-c-modes') it will also activate Smart-Dash-C mode,
which translates \"_>\" into \"->\" and \"__\" into \"--\"
automatically so that struct pointer member access and
postfix-decrement aren't made more difficult by Smart-Dash mode's
tendency to insert underscores at the tail ends of identifiers
whether you want it to or not.  Note that this will necessitate
that you type literal underscores if you want more than one
underscore in a row."
  nil "" smart-dash-mode-keymap
  (if smart-dash-mode
      (progn
        (and (memq major-mode smart-dash-c-modes)
             (smart-dash-c-mode 1))
        (smart-dash-isearch-install))
    (smart-dash-isearch-uninstall)
    (smart-dash-c-mode 0)))

(easy-mmode-defmap smart-dash-c-mode-keymap
   ; Remove definition with (makunbound 'smart-dash-c-mode-keymap)
   '((">" . smart-dash-insert-gt))
   "Key map supplement for `smart-dash-mode' when in a C-like
major mode.  See `smart-dash-c-modes'")

(define-minor-mode smart-dash-c-mode
  "Set the > key to call `smart-dash-insert-gt'.  Also modifies
the behavior of the dash key so that the postfix-- operator can
be typed normally (but shift will be needed for typing more than
one underscore in a row).

DO NOT ACTIVATE THIS MINOR MODE DIRECTLY.  Smart-Dash mode will
activate it if the current major mode is listed in
`smart-dash-c-modes'."
  nil "" smart-dash-c-mode-keymap
  (if smart-dash-c-mode
      (smart-dash-c-isearch-install)
    (smart-dash-c-isearch-uninstall)))

;; in-include code thanks to Josh Huber
(defun smart-dash-in-regular-code-p ()
  (let* ((syntax-ppss (syntax-ppss))
         (in-string (nth 3 syntax-ppss))
         (in-comment (nth 4 syntax-ppss))
         (in-include (and smart-dash-c-mode
                          (looking-back " *# *include +[<\"].*"
                                        (save-excursion (beginning-of-line)
                                                        (point))))))
    (and (not in-string)
         (not in-comment)
         (not in-include))))

(defun smart-dash-char-before-point (&optional n)
  (when (not n)
    (setq n 0))
  (char-before (+ (point) n)))

(defun smart-dash-insert-or-overwrite (text)
  "Insert or overwrite TEXT depending of overwrite-mode status.
TEST can be a single character or a string.
Multi-byte characters are handled properly."
  (when overwrite-mode
    (if (stringp text)
        (delete-char (length text))
      (delete-char 1)))
  (insert text))

;; This function makes all of the decisions about whether to insert a
;; dash or an underscore, and how to change the preceeding text if
;; necessary.  It takes all buffer-inspection and buffer-modification
;; functions as arguments so that it can be used both to edit the
;; actual buffer and to edit the isearch-string.
(defun smart-dash-do-insert (insertf deletef bobpf char-before-f regcodepf)
  (let ((ident-re (if smart-dash-c-mode
                      "[A-Za-z0-9]"
                    "[A-Za-z0-9_]")))
    (if (and (funcall regcodepf)
             (not (funcall bobpf)))
        (cond ((string-match ident-re (string (funcall char-before-f)))
               (funcall insertf ?_))
              ((and smart-dash-c-mode
                    (eql ?_ (funcall char-before-f)))
               (funcall deletef 1)
               (funcall insertf "--"))
              ((and smart-dash-c-mode
                    (eql ?- (funcall char-before-f))
                    (eql ?- (funcall char-before-f -1)))
               (funcall deletef 2)
               (funcall insertf "_--"))
              (t (funcall insertf ?-)))
      (funcall insertf ?-))))

(defun smart-dash-insert ()
  "Insert an underscore following [A-Za-z0-9_], a dash otherwise.

If `smart-dash-c-mode' is activated, also replace __ with --."
  (interactive)
  (smart-dash-do-insert 'smart-dash-insert-or-overwrite
                        'delete-backward-char
                        'bobp
                        'smart-dash-char-before-point
                        'smart-dash-in-regular-code-p))

(defun smart-dash-insert-dash ()
  "Insert a dash regardless of the preceeding character."
  (interactive)
  (smart-dash-insert-or-overwrite ?-))

(defun smart-dash-do-insert-gt (insertf deletef bobpf char-before-f codepf)
  (if (and (not (funcall bobpf))
           (funcall codepf)
           (= (funcall char-before-f) ?_))
      (progn
        (funcall deletef 1)
        (funcall insertf "->"))
    (funcall insertf ?>)))

(defun smart-dash-insert-gt ()
  "Insert a greater-than symbol.  If the preceeding character is
an underscore, replace it with a dash.

This behavior is desirable in order to make struct pointer member
access comfortable."
  (interactive)
  (smart-dash-do-insert-gt 'smart-dash-insert-or-overwrite
                           'delete-backward-char
                           'bobp
                           'smart-dash-char-before-point
                           'smart-dash-in-regular-code-p))

;;; Smart-Dash iSearch Support ;;;

(defun smart-dash-isearch-in-regular-code-p ()
  ;; Punt
  t)

(defun smart-dash-isearch-string (s)
  (when (not (stringp s))
    (setq s (string s)))
  (mapc (lambda (c)
          (let ((last-command-event c))
            (isearch-printing-char)))
        s))

(defun smart-dash-isearch-del-char (&optional n)
  (if (not n)
      (setq n 1))
  (while (> n 0)
    (isearch-del-char)
    (setq n (1- n))))

(defun smart-dash-isearch-char-before (&optional n)
  (when (not n)
    (setq n 0))
  (condition-case nil
      (elt (substring isearch-string
                      (- n 1)
                      (and (/= n 0) n))
           0)
    (args-out-of-range nil)))

(defun smart-dash-isearch-bobp ()
  (= 0 (length isearch-string)))

(defun smart-dash-isearch-insert ()
  "Isearch for an underscore following [A-Za-z0-9_], a dash otherwise.

If `smart-dash-c-mode' is activated, also replace __ with -- in
isearches."
  (interactive)
  (smart-dash-do-insert 'smart-dash-isearch-string
                        'smart-dash-isearch-del-char
                        'smart-dash-isearch-bobp
                        'smart-dash-isearch-char-before
                        'smart-dash-isearch-in-regular-code-p))

(defun smart-dash-isearch-insert-dash ()
  "Isearch for a dash regardless of the preceeding character."
  (interactive)
  (smart-dash-isearch-string ?-))

(defun smart-dash-isearch-install ()
  (let ((map isearch-mode-map))
    (make-local-variable 'isearch-mode-map)
    (setq isearch-mode-map (copy-keymap map)))
  (define-key isearch-mode-map "-" 'smart-dash-isearch-insert)
  (define-key
    isearch-mode-map
    (kbd "<kp-subtract>")
    'smart-dash-isearch-insert-dash))

;; The surest, cleanest way to undo the work of
;; `smart-dash-isearch-install' would be to delete the buffer-local
;; binding for isearch-mode-map, but if other modes have also
;; overridden some isearch-mode-map bindings then that would clobber
;; them as well.  So we leave the local binding alone and just set our
;; bindings back to their default values
(defun smart-dash-isearch-uninstall ()
  (when (local-variable-p 'isearch-mode-map)
    (define-key isearch-mode-map "-" 'isearch-printing-char)
    (define-key isearch-mode-map
      (kbd "<kp-subtract>") 'isearch-printing-char)))

(defun smart-dash-isearch-insert-gt ()
  "Isearch for a greater-than symbol.  If the preceeding
character is an underscore, replace it with a dash.

This behavior is desirable in order to make searching for struct
pointer member access comfortable."
  (interactive)
  (smart-dash-do-insert-gt 'smart-dash-isearch-string
                           'smart-dash-isearch-del-char
                           'smart-dash-isearch-bobp
                           'smart-dash-isearch-char-before
                           'smart-dash-isearch-in-regular-code-p))

(defun smart-dash-c-isearch-install ()
  (let ((map isearch-mode-map))
    (make-local-variable 'isearch-mode-map)
    (setq isearch-mode-map (copy-keymap map)))
  (define-key isearch-mode-map ">" 'smart-dash-isearch-insert-gt))

;; See comments on smart-dash-isearch-uninstall
(defun smart-dash-c-isearch-uninstall ()
  (when (local-variable-p 'isearch-mode-map)
    (define-key isearch-mode-map ">" 'isearch-printing-char)))

;;; Smart-Dash MiniBuffer Support ;;;

;; Turning on Smart-Dash mode in all minibuffers started from a
;; particular buffer seems like a good idea until you actually try
;; it. At that point you realize that it's a nuisance as often as a
;; help - for example, in execute-extended-command and eval-expression
;; minibuffers where you're typing lisp identifiers and expecting
;; dashes to stay dashes.
;;
;; The only way I've been able to come up with for getting around this
;; difficulty is with Allow/Deny lists for commands.  By default,
;; Smart-Dash mode will only come on in minibuffers started by
;; commands in smart-dash-minibuffer-allow-commands.  I encourage my
;; users to send me examples of commands that they add to this list.
;;
;; If you'd like to have Smart-Dash mode on in all minibuffers started
;; from a Smart-Dash buffer, set smart-dash-minibuffer-by-default to t
;; and tweak smart-dash-minibuffer-deny-commands to add exceptions.
;;
;; If you hate this feature altogether, set
;; smart-dash-minibuffer-enabled to nil.

(defgroup smart-dash-minibuffer nil
  "Activate Smart-Dash mode in the minibuffer
for commands that are executed in Smart-Dash mode buffers."
  :prefix "smart-dash-minibuffer"
  :group 'smart-dash)

(defcustom smart-dash-minibuffer-enabled t
  ; Remove definition with (makunbound 'smart-dash-minibuffer-enabled)
  "If non-nil, activate Smart-Dash mode in the minibuffer for
some commands.

The decision of which commands will have Smart-Dash mode
activated in is controlled by `smart-dash-minibuffer-by-default',
`smart-dash-minibuffer-allow-commands' and
`smart-dash-minibuffer-deny-commands'."
  :group 'smart-dash-minibuffer
  :type 'boolean)

(defcustom smart-dash-minibuffer-by-default nil
  ; Remove definition with (makunbound 'smart-dash-minibuffer-by-default)
  "If non-nil, activate Smart-Dash mode in the minibuffer for all
commands except those listed in `smart-dash-minibuffer-deny-commands'.

If nil (the default), activate Smart-Dash mode in the minibuffer
only for commands listed in `smart-dash-minibuffer-allow-commands'."
  :group 'smart-dash-minibuffer
  :type 'boolean)

(defcustom smart-dash-minibuffer-allow-commands
  '(query-replace
    query-replace-regexp
    replace-string
    replace-regexp
    search-forward
    search-forward-regexp
    isearch-edit-string
    string-rectangle
    find-tag
    grep)
  ; Remove definition with
  ; (makunbound 'smart-dash-minibuffer-allow-commands)
  "Commands whose minibuffer inputs should have Smart-Dash mode
activated when `smart-dash-minibuffer-by-default' is nil."
  :group 'smart-dash-minibuffer
  :type '(repeat function))

(defcustom smart-dash-minibuffer-deny-commands
  '(execute-extended-command
    eval-expression
    find-file)
  ; Remove definition with
  ; (makunbound 'smart-dash-minibuffer-deny-commands)
  "Commands whose minibuffer inputs should NOT have Smart-Dash
mode activated when `smart-dash-minibuffer-by-default' is
non-nil."
  :group 'smart-dash-minibuffer
  :type '(repeat function))

;; When a command uses the minibuffer more than once, all but the
;; first will have `this-command' set to the command which exited the
;; previous minibuffer.  Usually this is `exit-minibuffer' or
;; `self-insert-and-exit', but there's no way to know for certain what
;; commands may cause the exit.  When this occurs it prevents
;; `this-command' from matching the Allow and Deny command lists.
;;
;; The solution used by Smart-Dash minibuffer support is to record the
;; command that caused the previous minibuffer exit and, if that's the
;; command that invoked the current minibuffer, to use the previous
;; value of `this-command' to determine whether Smart-Dash minibuffer
;; support should be enabled.

;; The possibility of recursive minibuffers necessitate using stacks
;; rather than simple variables to deduce the current minibffer-using
;; command.
(defvar smart-dash-minibuffer-last-exit-command-stack (list nil))
(defvar smart-dash-minibuffer-this-command-stack (list nil))

(defun smart-dash-minibuffer-exit ()
  (setq smart-dash-minibuffer-last-exit-command-stack
        (cdr smart-dash-minibuffer-last-exit-command-stack)) ; pop
  (setq smart-dash-minibuffer-this-command-stack
        (cdr smart-dash-minibuffer-this-command-stack)) ; pop
  (rplaca smart-dash-minibuffer-last-exit-command-stack this-command))

(add-hook 'minibuffer-exit-hook 'smart-dash-minibuffer-exit)

(defun smart-dash-minibuffer-install ()
  (unless (eq this-command
              (car smart-dash-minibuffer-last-exit-command-stack))
    (rplaca smart-dash-minibuffer-this-command-stack this-command))
  (let* ((selected-buffer (window-buffer (minibuffer-selected-window)))
         (sd-active
          (with-current-buffer selected-buffer smart-dash-mode))
         (sd-c-active
          (with-current-buffer selected-buffer smart-dash-c-mode))
         (local-this-command
          (car smart-dash-minibuffer-this-command-stack))
         (allow (and smart-dash-minibuffer-enabled
                     (if smart-dash-minibuffer-by-default
                         (not (memq local-this-command
                                    smart-dash-minibuffer-deny-commands))
                       (memq local-this-command
                             smart-dash-minibuffer-allow-commands)))))
    (when allow
      (if sd-active
          (smart-dash-mode))
      (if sd-c-active
          (smart-dash-c-mode))))
  (setq smart-dash-minibuffer-last-exit-command-stack
        (cons nil smart-dash-minibuffer-last-exit-command-stack))
  (setq smart-dash-minibuffer-this-command-stack
        (cons nil smart-dash-minibuffer-this-command-stack)))

(add-hook 'minibuffer-setup-hook 'smart-dash-minibuffer-install)

(provide 'smart-dash)

;;; smart-dash.el ends here
