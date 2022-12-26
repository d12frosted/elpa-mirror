;;; p4.el --- Simple Perforce-Emacs Integration

;; Copyright (c) 1996-1997 Eric Promislow
;; Copyright (c) 1997-2004 Rajesh Vaidheeswarran
;; Copyright (c) 2005      Peter Osterlund
;; Copyright (c) 2009      Fujii Hironori
;; Copyright (c) 2012      Jason Filsinger
;; Copyright (c) 2013-2015 Gareth Rees <gdr@garethrees.org>

;; Author: Gareth Rees <gdr@garethrees.org>
;; URL: https://github.com/gareth-rees/p4.el
;; Package-Version: 20150721.1937
;; Package-Commit: eff047caa75dbe4965defca9d1212454cdb755d5
;; Version: 12.0

;;; Commentary:

;; p4.el integrates the Perforce software version management system
;; into Emacs. It is designed for users who are familiar with Perforce
;; and want to access it from Emacs: it provides Emacs interfaces that
;; map directly to Perforce commands.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Installation:

;; In your .emacs, ensure the path to the directory containing p4.el
;; is in the `load-path' variable:
;;
;;     (add-to-list 'load-path "/full/path/to/dir/containing/p4.el/")
;;
;; Then load the library:
;;
;;     (require 'p4)
;;
;; By default, the P4 global key bindings start with C-x p. If you
;; prefer a different key prefix, then you should customize the
;; setting `p4-global-key-prefix'.
;;
;; To compile the Perforce help text into the Emacs documentation
;; strings for each command, you must byte-compile this file:
;;
;;     $ emacs -Q -batch -f batch-byte-compile /full/path/to/file/p4.el


;;; Code:

(require 'compile) ; compilation-error-regexp-alist
(require 'comint) ; comint-check-proc
(require 'dired) ; dired-get-filename
(require 'diff-mode) ; diff-font-lock-defaults, ...
(require 'ps-print) ; ps-print-ensure-fontified
(eval-when-compile (require 'cl)) ; defstruct, loop, dolist, lexical-let, ...

(defvar p4-version "12.0" "Perforce-Emacs Integration version.")

;; Forward declarations to avoid byte-compile warning "reference to
;; free variable"
(defvar p4-global-key-prefix)
(defvar p4-basic-mode-map)
(defvar p4-annotate-mode-map)


;;; User options:

(defgroup p4 nil "Perforce VC System." :group 'tools)

(eval-and-compile
  ;; This is needed at compile time by p4-help-text.
  (defcustom p4-executable
    (locate-file "p4" (append exec-path '("/usr/local/bin" "~/bin" ""))
                 (if (memq system-type '(ms-dos windows-nt)) '(".exe")))
    "The p4 executable."
    :type 'string
    :group 'p4))

(defcustom p4-cygpath-exec "cygpath"
  "Path to cygpath binary on cygwin systems."
  :type 'string
  :group 'p4)

(defcustom p4-default-diff-options "-du"
  "Options to pass to diff, diff2, describe, and resolve.
Set to:
-dn     (RCS)
-dc[n]  (context; optional argument specifies number of context lines)
-ds     (summary)
-du[n]  (unified; optional argument specifies number of context lines)
-db     (ignore whitespace changes)
-dw     (ignore whitespace)
-dl     (ignore line endings)"
  :type 'string
  :group 'p4)

(defcustom p4-auto-refresh t
  "If non-NIL, automatically refresh files under Perforce control
when they change on disk."
  :type 'boolean
  :group 'p4)

(defcustom p4-check-empty-diffs nil
  "If non-NIL, check for files with empty diffs before submitting."
  :type 'boolean
  :group 'p4)

(defcustom p4-follow-symlinks nil
  "If non-NIL, call `file-truename' on all opened files."
  :type 'boolean
  :group 'p4)

(defcustom p4-synchronous-commands '(add delete edit lock logout reopen revert
                                     unlock)
  "List of Perforce commands that are run synchronously."
  :type (let ((cmds '(add branch branches change changes client clients delete
                      describe diff diff2 edit filelog files fix fixes flush
                      fstat group groups have info integ job jobs jobspec label
                      labels labelsync lock logout move opened passwd print
                      reconcile reopen revert set shelve status submit sync
                      tickets unlock unshelve update user users where)))
          (cons 'set (loop for cmd in cmds collect (list 'const cmd))))
  :group 'p4)

(defcustom p4-password-source nil
  "Action to take when Perforce needs a password.
If NIL, prompt the user to enter password.
Otherwise, this is a string containing a shell command that
prints the password. This command is run in an environment where
P4PORT and P4USER and set from the current Perforce settings."
  :type '(radio (const :tag "Prompt user to enter password." nil)
                (const :tag "Fetch password from OS X Keychain.\n\n\tFor each Perforce account, use Keychain Access to create an\n\tapplication password with \"Account\" the Perforce user name\n\t(P4USER) and \"Where\" the Perforce server setting (P4PORT).\n"
                       "security find-generic-password -s $P4PORT -a $P4USER -w")
                (const :tag "Fetch password from Python keyring.\n\n\tFor each Perforce account, run:\n\t    python -c \"import keyring,sys;keyring.set_password(*sys.argv[1:])\" \\\n\t        P4PORT P4USER PASSWORD\n\treplacing P4PORT with the Perforce server setting, P4PORT with the\n\tPerforce user name, and PASSWORD with the password.\n"
                       "python -c \"import keyring, sys; print(keyring.get_password(*sys.argv[1:3]))\" \"$P4PORT\" \"$P4USER\"")
                (string :tag "Run custom command"))
  :group 'p4)

(defcustom p4-mode-hook nil
  "Hook run by `p4-mode'."
  :type 'hook
  :group 'p4)

(defcustom p4-form-mode-hook nil
  "Hook run by `p4-form-mode'."
  :type 'hook
  :group 'p4)

(defcustom p4-edit-hook nil
  "Hook run after opening a file for edit."
  :type 'hook
  :group 'p4)

(defcustom p4-set-client-hooks nil
  "Hook run after client is changed."
  :type 'hook
  :group 'p4)

(defcustom p4-strict-complete t
  "If non-NIL, `p4-set-my-client' requires an exact match."
  :type 'boolean
  :group 'p4)

;; This is also set by the command `p4-toggle-vc-mode'.
(defcustom p4-do-find-file t
  "If non-NIL, display Perforce revision and opened status in the
mode line."
  :type 'boolean
  :group 'p4)

(defcustom p4-cleanup-time 600
  "Time in seconds after which a cache of information from the
Perforce server becomes stale."
  :type 'integer
  :group 'p4)

(defcustom p4-my-clients nil
  "The list of Perforce clients that the function
`p4-set-client-name' will complete on, or NIL if it should
complete on all clients."
  :type '(repeat (string))
  :group 'p4)

(eval-and-compile
  ;; This is needed at compile time by p4-help-text.
  (defcustom p4-modify-args-function #'identity
    "Function that modifies a Perforce command line argument list.
All calls to the Perforce executable are routed through this
function to enable global modifications of argument vectors.  The
function will be called with one argument, the list of command
line arguments for Perforce (excluding the program name).  It
should return a possibly modified command line argument list.
This can be used to e.g. support wrapper scripts taking custom
flags."
    :type 'function
    :group 'p4))

(defgroup p4-faces nil "Perforce VC System Faces." :group 'p4)

(defface p4-description-face '((t))
  "Face used for change descriptions."
  :group 'p4-faces)

(defface p4-heading-face '((t))
  "Face used for section heading."
  :group 'p4-faces)

(defface p4-link-face '((t (:weight bold)))
  "Face used to highlight clickable links."
  :group 'p4-faces)

(defface p4-action-face '((t (:inherit p4-link-face)))
  "Face used to highlight Perforce actions (add/edit/integrate/delete)."
  :group 'p4-faces)

(defface p4-branch-face '((t (:inherit p4-link-face)))
  "Face used to highlight Perforce branches."
  :group 'p4-faces)

(defface p4-change-face '((t (:inherit p4-link-face)))
  "Face used to highlight Perforce change numbers."
  :group 'p4-faces)

(defface p4-client-face '((t (:inherit p4-link-face)))
  "Face used to highlight Perforce users."
  :group 'p4-faces)

(defface p4-filespec-face '((t (:inherit p4-link-face)))
  "Face used to highlight Perforce filespec."
  :group 'p4-faces)

(defface p4-job-face '((t (:inherit p4-link-face)))
  "Face used to highlight Perforce job names."
  :group 'p4-faces)

(defface p4-label-face '((t (:inherit p4-link-face)))
  "Face used to highlight Perforce labels."
  :group 'p4-faces)

(defface p4-revision-face '((t (:inherit p4-link-face)))
  "Face used to highlight Perforce revision numbers."
  :group 'p4-faces)

(defface p4-user-face '((t (:inherit p4-link-face)))
  "Face used to highlight Perforce users."
  :group 'p4-faces)

(defface p4-depot-add-face
  '((((class color) (background light)) (:foreground "blue"))
    (((class color) (background dark)) (:foreground "cyan")))
  "Face used for files open for add."
  :group 'p4-faces)

(defface p4-depot-branch-face
  '((((class color) (background light)) (:foreground "blue4"))
    (((class color) (background dark)) (:foreground "sky blue")))
  "Face used for files open for integrate."
  :group 'p4-faces)

(defface p4-depot-delete-face
  '((((class color) (background light)) (:foreground "red"))
    (((class color) (background dark)) (:foreground "pink")))
  "Face used for files open for delete."
  :group 'p4-faces)

(defface p4-depot-edit-face
  '((((class color) (background light)) (:foreground "dark green"))
    (((class color) (background dark)) (:foreground "light green")))
  "Face used for files open for edit."
  :group 'p4-faces)

(defface p4-form-comment-face '((t (:inherit font-lock-comment-face)))
  "Face for comment in P4 Form mode."
  :group 'p4-faces)

(defface p4-form-keyword-face '((t (:inherit font-lock-keyword-face)))
  "Face for keyword in P4 Form mode."
  :group 'p4-faces)

;; Local variables in all buffers.
(defvar p4-mode nil "P4 minor mode.")
(defvar p4-vc-revision nil
  "Perforce revision to which this buffer's file is synced.")
(defvar p4-vc-status nil
  "Perforce status for this buffer. A symbol:
NIL if file is not known to be under control of Perforce.
`add' if file is opened for add.
`branch' if file opened for branch.
`delete' if file is opened for delete.
`edit' if file is opened for edit.
`integrate' if file is opened for integrate.
`sync' if file is synced but not opened.
`depot' if the file is from the depot.")

;; Local variables in P4 process buffers.
(defvar p4-process-args nil "List of p4 command and arguments.")
(defvar p4-process-callback nil
  "Function run when p4 command completes successfully.")
(defvar p4-process-after-show nil
  "Function run after showing output of successful p4 command.")
(defvar p4-process-auto-login nil
  "If non-NIL, automatically prompt user to log in.")
(defvar p4-process-buffers nil
  "List of buffers whose status is being updated here.")
(defvar p4-process-pending nil
  "Pending status update structure being updated here.")
(defvar p4-process-pop-up-output nil
  "Function that returns non-NIL to display output in a pop-up
window, or NIL to display it in the echo area.")
(defvar p4-process-synchronous nil
  "If non-NIL, run p4 command synchronously.")

;; Local variables in P4 Form buffers.
(defvar p4-form-commit-command nil
  "p4 command to run when committing this form.")
(defvar p4-form-commit-success-callback nil
  "Function run if commit succeeds. It receives two arguments:
the commit command and the buffer containing the output from the
commit command.")
(defvar p4-form-commit-failure-callback nil
  "Function run if commit fails. It receives two arguments:
the commit command and the buffer containing the output from the
commit command.")
(defvar p4-form-head-text
  (format "# Created using Perforce-Emacs Integration version %s.
# Type C-c C-c to send the form to the server.
# Type C-x k to cancel the operation.
#\n" p4-version)
  "Text added to top of generic form.")

;; Local variables in P4 depot buffers.
(defvar p4-default-directory nil "Original value of default-directory.")

(dolist (var '(p4-mode p4-vc-revision p4-vc-status
               p4-process-args p4-process-callback
               p4-process-buffers p4-process-pending
               p4-process-after-show p4-process-auto-login
               p4-process-pop-up-output p4-process-synchronous
               p4-form-commit-command
               p4-form-commit-success-callback
               p4-form-commit-failure-callback p4-default-directory))
  (make-variable-buffer-local var)
  (put var 'permanent-local t))


;;; P4 minor mode:

(add-to-list 'minor-mode-alist '(p4-mode p4-mode))


;;; Keymap:

(defvar p4-prefix-map
  (let ((map (make-sparse-keymap)))
    (define-key map "a" 'p4-add)
    (define-key map "b" 'p4-branch)
    (define-key map "B" 'p4-branches)
    (define-key map "c" 'p4-client)
    (define-key map "C" 'p4-changes)
    (define-key map "d" 'p4-diff2)
    (define-key map "D" 'p4-describe)
    (define-key map "e" 'p4-edit)
    (define-key map "E" 'p4-reopen)
    (define-key map "\C-f" 'p4-depot-find-file)
    (define-key map "f" 'p4-filelog)
    (define-key map "F" 'p4-files)
    (define-key map "G" 'p4-get-client-name)
    (define-key map "g" 'p4-update)
    (define-key map "h" 'p4-help)
    (define-key map "H" 'p4-have)
    (define-key map "i" 'p4-info)
    (define-key map "I" 'p4-integ)
    (define-key map "j" 'p4-job)
    (define-key map "J" 'p4-jobs)
    (define-key map "l" 'p4-label)
    (define-key map "L" 'p4-labels)
    (define-key map "\C-l" 'p4-labelsync)
    (define-key map "m" 'p4-move)
    (define-key map "o" 'p4-opened)
    (define-key map "p" 'p4-print)
    (define-key map "P" 'p4-set-p4-port)
    (define-key map "q" 'quit-window)
    (define-key map "r" 'p4-revert)
    (define-key map "R" 'p4-refresh)
    (define-key map "\C-r" 'p4-resolve)
    (define-key map "s" 'p4-status)
    (define-key map "S" 'p4-submit)
    (define-key map "t" 'p4-toggle-vc-mode)
    (define-key map "u" 'p4-user)
    (define-key map "U" 'p4-users)
    (define-key map "v" 'p4-version)
    (define-key map "V" 'p4-annotate)
    (define-key map "w" 'p4-where)
    (define-key map "x" 'p4-delete)
    (define-key map "X" 'p4-fix)
    (define-key map "z" 'p4-reconcile)
    (define-key map "=" 'p4-diff)
    (define-key map (kbd "C-=") 'p4-diff-all-opened)
    (define-key map "-" 'p4-ediff)
    map)
  "The prefix map for global p4.el commands.")

(fset 'p4-prefix-map p4-prefix-map)

(defun p4-update-global-key-prefix (symbol value)
  "Update the P4 global key prefix based on the
`p4-global-key-prefix' user setting."
  (set symbol value)
  (let ((map (current-global-map)))
    ;; Remove old binding(s).
    (dolist (key (where-is-internal p4-prefix-map map))
      (define-key map key nil))
    ;; Add new binding.
    (when p4-global-key-prefix
      (define-key map p4-global-key-prefix p4-prefix-map))))

(defcustom p4-global-key-prefix (kbd "C-x p")
  "The global key prefix for P4 commands."
  :type '(radio (const :tag "No global key prefix" nil) (key-sequence))
  :set 'p4-update-global-key-prefix
  :group 'p4)


;;; Menu:

;; The menu definition is in the XEmacs format. Emacs parses and converts
;; this definition to its own menu creation commands.

(defvar p4-menu-spec
  '(["Specify Arguments..." universal-argument t]
    ["--" nil nil]
    ["Open for Add" p4-add
     (and buffer-file-name (or (not p4-do-find-file) (not p4-vc-status)))]
    ["Open for Edit" p4-edit
     (and buffer-file-name (or (not p4-do-find-file) (eq p4-vc-status 'sync)))]
    ["Reopen" p4-reopen
     (and buffer-file-name (or (not p4-do-find-file) (eq p4-vc-status 'edit)))]
    ["Revert" p4-revert
     (and buffer-file-name (or (not p4-do-find-file) (memq p4-vc-status '(add branch edit delete integrate))))]
    ["Open for Delete" p4-delete
     (and buffer-file-name (or (not p4-do-find-file) (eq p4-vc-status 'sync)))]
    ["Move Open File" p4-move
     (and buffer-file-name (or (not p4-do-find-file) (eq p4-vc-status 'edit)))]
    ["Submit Changes"  p4-submit t]
    ["--" nil nil]
    ["Update Files from Depot" p4-update t]
    ["Status of Files on Client" p4-status t]
    ["Reconcile Files with Depot" p4-reconcile t]
    ["--" nil nil]
    ["Show Opened Files" p4-opened t]
    ["File info" p4-fstat
     (and buffer-file-name (or (not p4-do-find-file) p4-vc-status))]
    ["Filelog" p4-filelog
     (and buffer-file-name (or (not p4-do-find-file) p4-vc-status))]
    ["Changes" p4-changes t]
    ["Describe Change" p4-describe t]
    ["--" nil nil]
    ["Diff 2 Versions" p4-diff2
     (and buffer-file-name (or (not p4-do-find-file) p4-vc-status))]
    ["Diff Current" p4-diff
     (and buffer-file-name (or (not p4-do-find-file) (eq p4-vc-status 'edit)))]
    ["Diff All Opened Files" p4-diff-all-opened t]
    ["Diff Current with Ediff" p4-ediff
     (and buffer-file-name (or (not p4-do-find-file) (eq p4-vc-status 'edit)))]
    ["Diff 2 Versions with Ediff" p4-ediff2
     (and buffer-file-name (or (not p4-do-find-file) p4-vc-status))]
    ["--" nil nil]
    ["Open for Integrate" p4-integ t]
    ["Resolve Conflicts" p4-resolve t]
    ["--" nil nil]
    ["Print" p4-print
     (and buffer-file-name (or (not p4-do-find-file) p4-vc-status))]
    ["Print with Revision History" p4-annotate
     (and buffer-file-name (or (not p4-do-find-file) p4-vc-status))]
    ["Find File using Depot Spec" p4-depot-find-file t]
    ["--" nil nil]
    ["Edit a Branch Specification" p4-branch t]
    ["Edit a Label Specification" p4-label t]
    ["Edit a Client Specification" p4-client t]
    ["Edit a User Specification" p4-user t]
    ["--" nil nil]
    ["Disable Status Check" p4-toggle-vc-mode-off p4-do-find-file]
    ["Enable Status Check" p4-toggle-vc-mode-on (not p4-do-find-file)]
    ["--" nil nil]
    ["Set P4CONFIG" p4-set-p4-config t]
    ["Set P4CLIENT" p4-set-client-name t]
    ["Set P4PORT" p4-set-p4-port t]
    ["Show client info" p4-set t]
    ["Show server info" p4-info t]
    ["--" nil nil]
    ["About P4" p4-version t]
    )
  "The P4 menu definition")

(easy-menu-change '("tools") "P4" p4-menu-spec "Version Control")


;;; Macros (must be defined before use if compilation is to work)

(defmacro p4-with-temp-buffer (args &rest body)
  "Run p4 ARGS in a temporary buffer, place point at the start of
the output, and evaluate BODY if the command completed successfully."
  `(let ((dir (or p4-default-directory default-directory)))
     (with-temp-buffer
       (cd dir)
       (when (zerop (p4-run ,args)) ,@body))))

(put 'p4-with-temp-buffer 'lisp-indent-function 1)

(defmacro p4-with-set-output (&rest body)
  "Run p4 set in a temporary buffer, place point at the start of
the output, and evaluate BODY if the command completed successfully."
  ;; Can't use `p4-with-temp-buffer' for this, because that would lead
  ;; to infinite recursion via `p4-coding-system'.
  `(let ((dir (or p4-default-directory default-directory)))
     (with-temp-buffer
       (cd dir)
       (when (zerop (save-excursion
                      (p4-call-process nil t nil "set")))
         ,@body))))

(put 'p4-with-set-output 'lisp-indent-function 0)

(defmacro p4-with-coding-system (&rest body)
  "Evaluate BODY with coding-system-for-read and -write set to
the result of `p4-coding-system'."
  `(let* ((coding (p4-coding-system))
          (coding-system-for-read coding)
          (coding-system-for-write coding))
     ,@body))

(put 'p4-with-coding-system 'lisp-indent-function 0)


;;; Environment:

(defun p4-version ()
  "Describe the Emacs-Perforce Integration version."
  (interactive)
  (message "Emacs-P4 Integration version %s" p4-version))

(defun p4-current-setting (var &optional default)
  "Return the current Perforce client setting for VAR, or DEFAULT
if there is no setting."
  (or (p4-with-set-output
        (let ((re (format "^%s=\\(\\S-+\\)" (regexp-quote var))))
          (when (re-search-forward re nil t)
            (match-string 1))))
      default))

(defun p4-current-environment ()
  "Return `process-environment' updated with the current Perforce
client settings."
  (append
   (p4-with-set-output
     (loop while (re-search-forward "^P4[A-Z]+=\\S-+" nil t)
           collect (match-string 0)))
   ;; Default values for P4PORT and P4USER may be needed by
   ;; p4-password-source even if not supplied by "p4 set". See:
   ;; http://www.perforce.com/perforce/doc.current/manuals/cmdref/P4PORT.html
   ;; http://www.perforce.com/perforce/doc.current/manuals/cmdref/P4USER.html
   (list
    "P4PORT=perforce:1666"
    (concat "P4USER="
            (or (getenv "USER") (getenv "USERNAME") (user-login-name))))
   process-environment))

(defvar p4-coding-system-alist
  ;; I've preferred the IANA name, where possible. See
  ;; <http://www.iana.org/assignments/character-sets/character-sets.xhtml>
  ;; Note that Emacs (as of 24.3) does not support utf-32 and its
  ;; variants; these will lead to an error in `p4-coding-system'.
  '(("cp1251"      . windows-1251)
    ("cp936"       . windows-936)
    ("cp949"       . euc-kr)
    ("cp950"       . big5)
    ("eucjp"       . euc-jp)
    ("iso8859-1"   . iso-8859-1)
    ("iso8859-15"  . iso-8859-15)
    ("iso8859-5"   . iso-8859-5)
    ("koi8-r"      . koi8-r)
    ("macosroman"  . macintosh)
    ("shiftjis"    . shift_jis)
    ("utf16"       . utf-16-with-signature)
    ("utf16-nobom" . utf-16)
    ("utf16be"     . utf-16be)
    ("utf16be-bom" . utf-16be-with-signature)
    ("utf16le"     . utf-16le)
    ("utf16le-bom" . utf-16le-with-signature)
    ("utf8"        . utf-8)
    ("utf8-bom"    . utf-8-with-signature)
    ("winansi"     . windows-1252)
    ("none"        . utf-8)
    (nil           . utf-8))
  "Association list mapping P4CHARSET to Emacs coding system.")

(defun p4-coding-system ()
  "Return an Emacs coding system equivalent to P4CHARSET."
  (let* ((charset (p4-current-setting "P4CHARSET"))
         (c (assoc charset p4-coding-system-alist)))
    (if c (cdr c)
      (error "Coding system %s not available in Emacs" charset))))

(defun p4-set-process-coding-system (process)
  "Set coding systems of PROCESS appropriately."
  (let ((coding (p4-coding-system)))
    (set-process-coding-system process coding coding)))

(defun p4-current-client ()
  "Return the current Perforce client."
  (p4-current-setting "P4CLIENT"))

(defun p4-get-client-name ()
  "Display the name of the current Perforce client."
  (interactive)
  (message "P4CLIENT=%s" (p4-current-client)))

(defun p4-current-server-port ()
  "Return the current Perforce port."
  ;; http://www.perforce.com/perforce/doc.current/manuals/cmdref/P4PORT.html
  (or (p4-current-setting "P4PORT") "perforce:1666"))

(defvar p4-server-version-cache nil
  "Association list mapping P4PORT to Perforce server version on that port.")

(defun p4-server-version ()
  "Return the version number of the Perforce server, or NIL if unknown."
  (let ((p4-port (p4-current-server-port)))
    (or (cdr (assoc p4-port p4-server-version-cache))
        (p4-with-temp-buffer '("info")
          (when (re-search-forward "^Server version: .*/\\([1-9][0-9]\\{3\\}\\)\\.[0-9]+/" nil t)
            (let ((version (string-to-number (match-string 1))))
              (push (cons p4-port version) p4-server-version-cache)
              version))))))

(defun p4-set-client-name (value)
  "Set the P4CLIENT environment variable to VALUE.
If the setting `p4-set-my-clients' is non-NIL, complete on those
clients only. If `p4-strict-complete' is non-NIL, require an
exact match."
  (interactive
   (list
    (completing-read
     "P4CLIENT="
     (or p4-my-clients
         (p4-completion-arg-completion-fn (p4-get-completion 'client)))
     nil p4-strict-complete (p4-current-client) 'p4-client-history)))
  (setenv "P4CLIENT" (unless (string-equal value "") value))
  (run-hooks 'p4-set-client-hooks))

(defun p4-set-p4-config (value)
  "Set the P4CONFIG environment variable to VALUE."
  (interactive (list (read-string "P4CONFIG=" (p4-current-setting "P4CONFIG"))))
  (setenv "P4CONFIG" (unless (string-equal value "") value)))

(defun p4-set-p4-port (value)
  "Set the P4PORT environment variable to VALUE."
  (interactive (list (read-string "P4PORT=" (p4-current-setting "P4PORT"))))
  (setenv "P4PORT" (unless (string-equal value "") value)))


;;; File handler:

(defun p4-dirs-and-attributes (dir)
  (let ((now (current-time)))
    (loop for f in (p4-output-matches (list "dirs" (concat dir "*"))
                                      "^//[^ \n]+$")
          collect (list f t 0 0 0 now now now 0 "dr--r--r--" nil 0 0))))

(defun p4-files-and-attributes (dir)
  (let ((now (current-time)))
    (loop for f in (p4-output-matches (list "files" (concat dir "*"))
                                      "^\\(//[^#\n]+#[1-9][0-9]*\\) - " 1)
          collect (list f nil 0 0 0 now now now 0 "-r--r--r--" nil 0 0))))

(defun p4-directory-files-and-attributes (dir &optional full match nosort id-format)
  (let* ((from (length dir))
         (files (loop for f in (append (p4-dirs-and-attributes dir)
                                       (p4-files-and-attributes dir))
                      unless (and match (not (string-match match (first f))))
                      collect (if full f
                                (cons (substring (first f) from) (cdr f))))))
    (if nosort files
      (sort files 'file-attributes-lessp))))

(defun p4-file-exists-p (filename)
  (or (p4-file-directory-p filename)
      (p4-with-temp-buffer (list "-s" "files" filename) (looking-at "info:"))))

(defun p4-file-directory-p (filename)
  (p4-with-temp-buffer (list "-s" "dirs" filename) (looking-at "info:")))

(defun p4-file-name-sans-versions (filename &optional keep-backup-version)
  (string-match "\\(.*?\\)\\(?:#[1-9][0-9]*\\|@[^#@ \t\n]+\\)?$" filename)
  (match-string 1 filename))

(defun p4-insert-directory (file switches &optional wildcard full-directory-p)
  (message "%s" (list file switches wildcard full-directory-p))
  (loop for f in (p4-directory-files-and-attributes file)
        do (insert (format "  %s   - -  -  %d %s %s\n" (nth 9 f)
                           (nth 8 f) (format-time-string "%b %e %Y" (nth 6 f))
                           (nth 0 f)))))

(defun p4-insert-file-contents (filename &optional visit beg end replace)
  (unless (zerop (p4-run (list "print" "-q" filename)))
    (signal 'file-error (buffer-substring (point-min) (point-max))))
  (when visit
    (p4-update-mode (current-buffer) 'depot nil)
    (setq p4-default-directory (or p4-default-directory default-directory))
    (setq buffer-file-name filename)
    (set-buffer-modified-p nil))
  (setq buffer-read-only t))

(defun p4-file-name-handler (operation &rest args)
  (case operation
    ((expand-file-name file-truename substitute-in-file-name)
     (car args))
    (directory-files (apply 'p4-directory-files args))
    (file-directory-p (apply 'p4-file-directory-p args))
    (file-exists-p (apply 'p4-file-exists-p args))
    (file-name-sans-versions (apply 'p4-file-name-sans-versions args))
    (file-remote-p t)
    (file-writable-p nil)
    (insert-directory (apply 'p4-insert-directory args))
    (insert-file-contents (apply 'p4-insert-file-contents args))
    (vc-registered nil)
    ((add-name-to-file delete-directory delete-file dired-compress-file
      make-directory make-directory-internal make-symbolic-link rename-file
      set-file-modes set-file-times shell-command write-region)
     (error "%s not supported for Perforce depot files." operation))
    (t
     (message "(p4-file-name-handler %s %s)" operation args)
     (let ((inhibit-file-name-handlers
            (cons 'p4-file-name-handler
                  (and (eq inhibit-file-name-operation operation)
                       inhibit-file-name-handlers)))
           (inhibit-file-name-operation operation))
       (apply operation args)))))


;;; Utilities:

(defun p4-find-file-or-print-other-window (client-name depot-name)
  (if client-name
      (find-file-other-window client-name)
    (p4-depot-find-file depot-name)))

(defvar p4-filespec-buffer-cache nil
  "Association list mapping filespec to buffer visiting that filespec.")

(defun p4-purge-filespec-buffer-cache ()
  "Remove stale entries from `p4-filespec-buffer-cache'."
  (let ((stale (time-subtract (current-time)
                              (seconds-to-time p4-cleanup-time))))
    (setf p4-filespec-buffer-cache
          (loop for c in p4-filespec-buffer-cache
                when (and (time-less-p stale (second c))
                          (buffer-live-p (third c)))
                collect c))))

(defun p4-visit-filespec (filespec)
  "Visit FILESPEC in some buffer and return the buffer."
  (p4-purge-filespec-buffer-cache)
  (let ((cached (assoc filespec p4-filespec-buffer-cache)))
    (if cached (third cached)
      (let ((args (list "print" filespec)))
        (set-buffer (p4-make-output-buffer (p4-process-buffer-name args)))
        (if (zerop (p4-run args))
            (progn
              (p4-activate-print-buffer t)
              (push (list filespec (current-time) (current-buffer))
                    p4-filespec-buffer-cache)
              (current-buffer))
          (p4-process-show-error))))))

(defun p4-depot-find-file-noselect (filespec)
  "Read depot FILESPEC in to a buffer and return the buffer.
If a buffer exists visiting FILESPEC, return that one."
  (string-match "\\(.*?\\)\\(#[1-9][0-9]*\\|\\(@\\S-+\\)\\)?$" filespec)
  (let* ((file (match-string 1 filespec))
         (spec (match-string 2 filespec))
         (change (match-string 3 filespec)))
    (if change
        ;; TODO: work out if we have the file synced at this
        ;; changelevel, perhaps by running sync -n and seeing if it
        ;; prints "files(s) up to date"?
        (p4-visit-filespec filespec)
      (with-temp-buffer
        (if (and (zerop (p4-run (list "have" file)))
                 (not (looking-at "//[^ \n]+ - file(s) not on client"))
                 (looking-at "//.*?\\(#[1-9][0-9]*\\) - \\(.*\\)$")
                 (or (not spec) (string-equal spec (match-string 1))))
            (find-file-noselect (match-string 2))
          (p4-visit-filespec filespec))))))

(defun p4-depot-find-file (filespec &optional line offset)
  "Visit the client file corresponding to depot FILESPEC,
if the file is mapped (and synced to the right revision if
necessary), otherwise print FILESPEC to a new buffer
synchronously and pop to it. With optional arguments LINE and
OFFSET, go to line number LINE and move forward by OFFSET
characters."
  (interactive (list (p4-read-arg-string "Enter filespec: " "//" 'filespec)))
  (let ((buffer (p4-depot-find-file-noselect filespec)))
    (when buffer
      (pop-to-buffer buffer)
      (when line (p4-goto-line line)
            (when offset (forward-char offset))))))

(defun p4-make-derived-map (base-map)
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map base-map)
    map))

(defun p4-goto-line (line)
  (goto-char (point-min))
  (forward-line (1- line)))

(defun p4-join-list (list) (mapconcat 'identity list " "))

;; Break up a string into a list of words
;; (p4-make-list-from-string "ab 'c de'  \"'f'\"") -> ("ab" "c de" "'f'")
(defun p4-make-list-from-string (str)
  (let (lst)
    (while (or (string-match "^ *\"\\([^\"]*\\)\"" str)
               (string-match "^ *\'\\([^\']*\\)\'" str)
               (string-match "^ *\\([^ ]+\\)" str))
      (setq lst (append lst (list (match-string 1 str))))
      (setq str (substring str (match-end 0))))
    lst))

(defun p4-force-mode-line-update ()
  "Force the mode line update."
  (if (featurep 'xemacs)
      (redraw-modeline)
    (force-mode-line-update)))

(defun p4-dired-get-marked-files ()
  ;; Wrapper for `dired-get-marked-files'. In Emacs 24.2 (and earlier)
  ;; this raises an error if there are no marked files and no file on
  ;; the current line, so we suppress the error here.
  ;;
  ;; The (delq nil ...) works around a bug in Dired+. See issue #172
  ;; <https://github.com/gareth-rees/p4.el/issues/172>
  (ignore-errors (delq nil (dired-get-marked-files nil))))

(defun p4-follow-link-name (name)
  (p4-cygpath
   (if p4-follow-symlinks
       (file-truename name)
     name)))

(defun p4-buffer-file-name (&optional buffer)
  "Return name of file BUFFER is visiting, or NIL if none,
respecting the `p4-follow-symlinks' setting."
  (let ((f (buffer-file-name buffer)))
    (when f (p4-follow-link-name f))))

(defun p4-process-output (cmd &rest args)
  "Run CMD (with the given ARGS) and return the output as a string,
except for the final newlines."
  (with-temp-buffer
    (apply 'call-process cmd nil t nil args)
    (skip-chars-backward "\n")
    (buffer-substring (point-min) (point))))

(defun p4-cygpath (name)
  (if (and (memq system-type '(cygwin32 cygwin))
           (not (p4-with-temp-buffer '("-V") (search-forward "CYGWIN" nil t))))
      (p4-process-output p4-cygpath-exec "-w" name)
    name))

(defun p4-startswith (string prefix)
  "Return non-NIL if STRING starts with PREFIX."
  (let ((l (length prefix)))
    (and (>= (length string) l) (string-equal (substring string 0 l) prefix))))


;;; Running Perforce:

(eval-and-compile
  ;; This is needed at compile time by p4-help-text.
  (defun p4-executable ()
    "Check if `p4-executable' is NIL, and if so, prompt the user
for a valid `p4-executable'."
    (interactive)
    (or p4-executable (call-interactively 'p4-set-p4-executable))))

(defun p4-set-p4-executable (filename)
  "Set `p4-executable' to the argument FILENAME.
To set the executable for future sessions, customize
`p4-executable' instead."
  (interactive "fFull path to your p4 executable: ")
  (if (and (file-executable-p filename) (not (file-directory-p filename)))
      (setq p4-executable filename)
    (error "%s is not an executable file." filename)))

(eval-and-compile
  ;; This is needed at compile time by p4-help-text.
  (defun p4-call-process (&optional infile destination display &rest args)
    "Call Perforce synchronously in separate process.
The program to be executed is taken from `p4-executable'; INFILE,
DESTINATION, and DISPLAY are to be interpreted as for
`call-process'.  The argument list ARGS is modified using
`p4-modify-args-function'."
    (apply #'call-process (p4-executable) infile destination display
           (funcall p4-modify-args-function args))))

(defun p4-call-process-region (start end &optional delete buffer display &rest args)
  "Send text from START to END to a synchronous Perforce process.
The program to be executed is taken from `p4-executable'; START,
END, DELETE, BUFFER, and DISPLAY are to be interpreted as for
`call-process-region'.  The argument list ARGS is modified using
`p4-modify-args-function'."
  (apply #'call-process-region start end (p4-executable) delete buffer display
         (funcall p4-modify-args-function args)))

(defun p4-start-process (name buffer &rest program-args)
  "Start Perforce in a subprocess.  Return the process object for it.
The program to be executed is taken from `p4-executable'; NAME
and BUFFER are to be interpreted as for `start-process'.  The
argument list PROGRAM-ARGS is modified using
`p4-modify-args-function'."
  (apply #'start-process name buffer (p4-executable)
         (funcall p4-modify-args-function program-args)))

(defun p4-compilation-start (args &optional mode name-function highlight-regexp)
  "Run Perforce with arguments ARGS in a compilation buffer.
The program to be executed is taken from `p4-executable'; MODE,
NAME-FUNCTION, and HIGHLIGHT-REGEXP are to be interpreted as for
`compilation-start'.  ARGS, however, is an argument vector, not a
shell command.  It will be modified using
`p4-modify-args-function'."
  (apply #'compilation-start
         (mapconcat #'shell-quote-argument
                    (cons (p4-executable)
                          (funcall p4-modify-args-function args))
                    " ")
         mode name-function highlight-regexp))

(defun p4-make-comint (name &optional startfile &rest switches)
  "Make a Comint process NAME in a buffer, running Perforce.
The program to be executed is taken from `p4-executable';
STARTFILE is to be interpreted as for `p4-make-comint'.  SWITCHES
is modified using `p4-modify-args'."
  (apply #'make-comint name (p4-executable) startfile
         (funcall p4-modify-args-function switches)))

(defun p4-make-output-buffer (buffer-name &optional mode)
  "Make a read-only buffer named BUFFER-NAME and return it.
Run the function MODE if non-NIL, otherwise `p4-basic-mode'."
  (let ((dir (or p4-default-directory default-directory))
        (inhibit-read-only t))
    (with-current-buffer (get-buffer-create buffer-name)
      (erase-buffer)
      (funcall (or mode 'p4-basic-mode))
      (setq buffer-read-only t)
      (setq buffer-undo-list t)
      (cd dir)
      (current-buffer))))

(defvar p4-no-session-regexp
  (concat "\\(?:error: \\)?"
          "\\(?:Perforce password (P4PASSWD) invalid or unset\\|"
          "Your session has expired, please login again\\)")
  "Regular expression matching output from Perforce when you are logged out.")

(defvar p4-untrusted-regexp
  (concat "\\(?:error: \\)?"
          "\\(?:The authenticity of '.*' can't be established"
          "\\|\\** WARNING P4PORT IDENTIFICATION HAS CHANGED! \\**\\)")
  "Regular expression matching output from an untrusted Perforce server.")

(defvar p4-connect-failed-regexp
  (concat "\\(?:error: \\)?"
          "Perforce client error:\n"
          "\tConnect to server failed")
  "Regular expression matching output from Perforce when it can't
connect to the server.")

(defun p4-request-trust ()
  "Ask the user for permission to trust the Perforce server."
  (with-selected-window (display-buffer (current-buffer))
    (goto-char (point-min)))
  (unless (yes-or-no-p "Trust server? ")
    (error "Server not trusted."))
  (with-temp-buffer
    (insert "yes\n")
    (p4-with-coding-system
      (p4-call-process-region (point-min) (point-max)
                              t t nil "trust" "-f"))))

(defun p4-iterate-with-login (fun)
  "Call FUN in the current buffer and return its result.
If FUN returns non-zero because the user is not logged in, login
and repeat."
  (let ((incomplete t)
        (default-directory (or p4-default-directory default-directory))
        (inhibit-read-only t)
        status)
    (while incomplete
      (save-excursion
        (save-restriction
          (setq incomplete nil)
          (narrow-to-region (point) (point))
          (setq status (funcall fun))
          (goto-char (point-min))
          (cond ((zerop status))
                ((looking-at p4-no-session-regexp)
                 (setq incomplete t)
                 (p4-login)
                 (delete-region (point-min) (point-max)))
                ((looking-at p4-untrusted-regexp)
                 (setq incomplete t)
                 (p4-request-trust))))))
    status))

(defun p4-ensure-logged-in ()
  "Ensure that user is logged in, prompting for password if necessary."
  (p4-with-temp-buffer '("login" "-s")
    ;; Dummy body avoids byte-compilation warning.
    'logged-in))

(defun p4-run (args)
  "Run p4 ARGS in the current buffer, with output after point.
Return the status of the command. If the command cannot be run
because the user is not logged in, prompt for a password and
re-run the command."
  (p4-iterate-with-login
   (lambda ()
     (p4-with-coding-system
       (apply #'p4-call-process nil t nil args)))))

(defun p4-refresh-callback (&optional hook)
  "Return a callback function that refreshes the status of the
current buffer after a p4 command successfully completes (and, if
p4-auto-refresh is non-NIL, refresh all buffers visiting files
under Perforce control too). If optional argument HOOK is
non-NIL, run that hook."
  (lexical-let ((buffer (current-buffer))
                (hook hook))
    (lambda ()
      (with-current-buffer buffer
        (p4-refresh-buffer 'force)
        (when hook (run-hooks hook))
        (p4-refresh-buffers)))))

(defun p4-process-show-output ()
  "Show the current buffer to the user and maybe kill it."
  (let ((lines (count-lines (point-min) (point-max))))
    (if (or p4-process-after-show
            (get-buffer-window) ; already visible
            (if p4-process-pop-up-output
                (funcall p4-process-pop-up-output)
              (> lines 1)))
        (unless (eq (window-buffer) (current-buffer))
          (with-selected-window (display-buffer (current-buffer))
            (goto-char (point-min))))
      (if (zerop lines)
          (message "Running p4 %s...done (no output)"
                   (p4-join-list p4-process-args))
        (goto-char (point-max))
        (message (buffer-substring (point-min) (line-end-position 0))))
      (kill-buffer (current-buffer)))))

(defun p4-process-show-error (&rest args)
  "Show the contents of the current buffer as an error message.
If there's no content in the buffer, pass ARGS to `error'
instead."
  (cond ((and (bobp) (eobp))
         (kill-buffer (current-buffer))
         (apply 'error args))
        ((eql (count-lines (point-min) (point-max)) 1)
         (goto-char (point-min))
         (let ((message (buffer-substring (point) (line-end-position))))
           (kill-buffer (current-buffer))
           (error message)))
        (t
         (let ((set (p4-with-set-output
                      (buffer-substring (point-min) (point-max))))
               (inhibit-read-only t))
           (with-selected-window (display-buffer (current-buffer))
             (goto-char (point-max))
             (if (string-match "\\S-" set)
                 (insert "\n\"p4 set\" shows that you have the following Perforce configuration:\n" set)
               (insert "\n\"p4 set\" shows that you have no Perforce configuration.\n"))
             (goto-char (point-min))))
         (apply 'error args))))

(defun p4-process-finished (buffer process-name message)
  (let ((inhibit-read-only t))
    (with-current-buffer buffer
      (cond ((and p4-process-auto-login
                  (save-excursion
                    (goto-char (point-min))
                    (looking-at p4-no-session-regexp)))
             (p4-login)
             (p4-process-restart))
            ((save-excursion
               (goto-char (point-min))
               (looking-at p4-untrusted-regexp))
             (p4-request-trust)
             (p4-process-restart))
            ((not (string-equal message "finished\n"))
             (p4-process-show-error "Process %s %s" process-name
                                    (replace-regexp-in-string "\n$" ""
                                                              message)))
            (t
             (when p4-process-callback (funcall p4-process-callback))
             (set-buffer-modified-p nil)
             (p4-process-show-output)
             (when p4-process-after-show
               (funcall p4-process-after-show)))))))

(defun p4-process-sentinel (process message)
  (let ((buffer (process-buffer process)))
    (when (buffer-live-p buffer)
      (p4-process-finished buffer (process-name process) message))))

(defun p4-process-restart ()
  "Start a Perforce process in the current buffer with command
and arguments taken from the local variable `p4-process-args'."
  (interactive)
  (unless p4-process-args
    (error "Can't restart Perforce process in this buffer."))
  (let ((inhibit-read-only t))
    (erase-buffer)
    (if p4-process-synchronous
        (p4-with-coding-system
          (let ((status (apply #'p4-call-process nil t nil
                               p4-process-args)))
            (p4-process-finished (current-buffer) "P4"
                                 (if (zerop status) "finished\n"
                                   (format "exited with status %d\n" status)))))
      (let ((process (apply #'p4-start-process "P4" (current-buffer)
                            p4-process-args)))
        (set-process-query-on-exit-flag process nil)
        (set-process-sentinel process 'p4-process-sentinel)
        (p4-set-process-coding-system process)
        (message "Running p4 %s..." (p4-join-list p4-process-args))))))

(defun p4-revert-buffer (&optional ignore-auto noconfirm)
  (p4-process-restart))

(defun p4-process-buffer-name (args)
  "Return a suitable buffer name for the p4 ARGS command."
  (format "*P4 %s*" (p4-join-list args)))

(defun* p4-call-command (cmd &optional args &key mode callback after-show
                             (auto-login t) synchronous pop-up-output)
  "Start a Perforce command.
First (required) argument CMD is the p4 command to run.
Second (optional) argument ARGS is a list of arguments to the p4 command.
Remaining arguments are keyword arguments:
:mode is a function run when creating the output buffer.
:callback is a function run when the p4 command completes successfully.
:after-show is a function run after displaying the output.
If :auto-login is NIL, don't try logging in if logged out.
If :synchronous is non-NIL, or command appears in
`p4-synchronous-commands', run command synchronously.
If :pop-up-output is non-NIL, call that function to determine
whether or not to pop up the output of a command in a window (as
opposed to showing it in the echo area)."
  (with-current-buffer
      (p4-make-output-buffer (p4-process-buffer-name (cons cmd args)) mode)
    (set (make-local-variable 'revert-buffer-function) 'p4-revert-buffer)
    (setq p4-process-args (cons cmd args)
          p4-process-after-show after-show
          p4-process-auto-login auto-login
          p4-process-callback callback
          p4-process-pop-up-output pop-up-output
          p4-process-synchronous
          (or synchronous (memq (intern cmd) p4-synchronous-commands)))
    (p4-process-restart)))

;; This empty function can be passed as an :after-show callback
;; function to p4-call-command where it has the side effect of
;; displaying the output buffer even if it contains a single line.
(defun p4-display-one-line ())


;;; Form commands:

(defun p4-form-value (key)
  "Return the value in the current form corresponding to key, or
NIL if the form has no value for that key."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward (format "^%s:" (regexp-quote key)) nil t)
      (if (looking-at "[ \t]\\(.+\\)")
          (match-string-no-properties 1)
        (forward-line 1)
        (loop while (looking-at "[ \t]\\(.*\\(?:\n\\|\\'\\)\\)")
              do (forward-line 1)
              concat (match-string-no-properties 1))))))

(defun p4-form-callback (regexp cmd success-callback failure-callback
                                mode head-text)
  (goto-char (point-min))
  ;; The Windows p4 client outputs this line before the spec unless
  ;; run via CMD.EXE.
  (when (looking-at "Found client MATCH : .*\n") (replace-match ""))
  (insert head-text)
  (funcall mode)
  (pop-to-buffer (current-buffer))
  (setq p4-form-commit-command cmd)
  (setq p4-form-commit-success-callback success-callback)
  (setq p4-form-commit-failure-callback failure-callback)
  (setq buffer-offer-save t)
  (set-buffer-modified-p nil)
  (setq buffer-undo-list nil)
  (setq buffer-read-only nil)
  (when regexp (re-search-forward regexp nil t))
  (message "C-c C-c to finish editing and exit buffer."))

(defun* p4-form-command (cmd &optional args &key move-to commit-cmd
                             success-callback
                             (failure-callback
                              'p4-form-commit-failure-callback-default)
                             (mode 'p4-form-mode)
                             (head-text p4-form-head-text))
  "Maybe start a form-editing session.
cmd is the p4 command to run \(it must take -o and output a form\).
args is a list of arguments to pass to the p4 command.
If args contains -d, then the command is run as-is.
Otherwise, -o is prepended to the arguments and the command
outputs a form which is presented to the user for editing.
The remaining arguments are keyword arguments:
:move-to is an optional regular expression to set the cursor on.
:commit-cmd is the command that will be called when
`p4-form-commit' is called \(it must take -i and a form on
standard input\). If not supplied, cmd is reused.
:success-callback is a function that is called if the commit succeeds.
:failure-callback is a function that is called if the commit fails.
:mode is the mode for the form buffer.
:head-text is the text to insert at the top of the form buffer."
  (unless mode (error "mode"))
  (when (member "-i" args)
    (error "'%s -i' is not supported here." cmd))
  (if (member "-d" args)
      (p4-call-command (or commit-cmd cmd) args)
    (let* ((args (cons "-o" (remove "-o" args)))
           (buf (get-buffer (p4-process-buffer-name (cons cmd args)))))
      ;; Is there already a form with the same name? If so, just
      ;; switch to it.
      (if buf
          (select-window (display-buffer buf))
        (lexical-let* ((move-to move-to)
                       (commit-cmd (or commit-cmd cmd))
                       (success-callback success-callback)
                       (failure-callback failure-callback)
                       (mode mode)
                       (head-text head-text))
          (p4-call-command cmd args
           :callback (lambda ()
                       (p4-form-callback move-to commit-cmd success-callback
                                         failure-callback mode head-text))))))))

(defun p4-form-commit-failure-callback-default (cmd buffer)
  (with-current-buffer buffer
    (p4-process-show-error "%s -i failed to complete successfully." cmd)))

(defun p4-form-commit ()
  "Commit the form in the current buffer to the server."
  (interactive)
  (lexical-let* ((form-buf (current-buffer))
                 (cmd p4-form-commit-command)
                 (args '("-i"))
                 (buffer (p4-make-output-buffer (p4-process-buffer-name
                                                 (cons cmd args)))))
    (cond ((with-current-buffer buffer
             (zerop
              (p4-iterate-with-login
               (lambda ()
                 (with-current-buffer form-buf
                   (save-restriction
                     (widen)
                     (p4-with-coding-system
                       (apply #'p4-call-process-region (point-min)
                              (point-max)
                              nil buffer nil cmd args))))))))
           (setq mode-name "P4 Form Committed")
           (when p4-form-commit-success-callback
             (funcall p4-form-commit-success-callback cmd buffer))
           (set-buffer-modified-p nil)
           (with-current-buffer buffer
             (p4-process-show-output))
           (p4-partial-cache-cleanup
            (if (string= cmd "change") 'pending (intern cmd))))
          (p4-form-commit-failure-callback
           (funcall p4-form-commit-failure-callback cmd buffer)))))


;;; P4 mode:

(defvar p4-update-status-pending-alist nil
  "Association list mapping Perforce settings (the output of p4
set) to the value of (current-time) when the status update for
these Perforce settings was created or last run; and a list of
buffers with these Perforce settings whose status needs
updating.")

(defvar p4-update-status-timeout 600
  "Retry a status update on a Perforce server after this many seconds.")

(defun p4-update-status-pending-add (set buffer &optional force)
  "Add BUFFER to the set of pending updates for the Perforce settings SET.
If optional argument FORCE is non-NIL, reset the update timeout
for those settings."
  (let ((pending (assoc set p4-update-status-pending-alist)))
    (unless pending
      (setq pending (list set (seconds-to-time 0) nil))
      (push pending p4-update-status-pending-alist))
    (when force
      (setf (second pending) (seconds-to-time 0)))
    (pushnew buffer (third pending))))

(defun p4-update-status-pending-sort ()
  "Tidy up `p4-update-status-pending-alist': discard buffers that
no longer exist; discard servers for which no updates are
pending; and sort pending updates into order by time of last
update (oldest first)."
  (setq p4-update-status-pending-alist
        (sort (loop for pending in p4-update-status-pending-alist
                    do (setf (third pending)
                             (loop for b in (third pending)
                                   if (and (buffer-live-p b)
                                           (buffer-file-name b))
                                   collect b))
                    if (third pending)
                    collect pending)
              (lambda (a b) (time-less-p (second a) (second b))))))

(defun p4-update-mode (buffer status revision)
  "Turn p4-mode on or off in BUFFER according to Perforce status.
Argument STATUS is a symbol (see `p4-vc-status' for the possible
values and what they mean). Argument REVISION is the revision
number of the file on the client, or NIL if such a revision
number is not known or not applicable."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (setq p4-vc-status status
            p4-vc-revision revision)
      (let ((new-mode (case status
                        (sync (format " P4:%d" revision))
                        (depot (format " P4:%s" status))
                        ((add branch edit integrate) (format " P4:%s" status))
                        (t nil))))
        (when (and new-mode (not p4-mode))
          (run-hooks 'p4-mode-hook))
        (setq p4-mode new-mode)))))

(defun p4-update-status-sentinel-2 (process message)
  (let ((buffer (process-buffer process)))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (when (string-equal message "finished\n")
          (goto-char (point-min))
          (while (not (eobp))
            (let ((b (pop p4-process-buffers)))
              (cond ((looking-at "^info: //[^#\n]+#\\([1-9][0-9]*\\) - ")
                     (p4-update-mode b 'sync
                                     (string-to-number (match-string 1))))
                    (t (p4-update-mode b nil nil))))
            (forward-line 1)))
        (kill-buffer (current-buffer))
        (p4-maybe-start-update-statuses)))))

(defun p4-update-status-sentinel-1 (process message)
  ;; Don't check (string= message "finished\n"): "p4 opened" exits
  ;; with status 1 if asked to determine the status of a file outside
  ;; the workspace root, but we still want to process the output in
  ;; that case.
  ;;
  ;; If user is logged out, or p4-executable wrongly configured, don't
  ;; spam user with errors, just quietly ignore. When they log in or
  ;; fix the configuration, the update process will restart.
  (let (have-buffers (buffer (process-buffer process)))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (goto-char (point-min))
        (while (not (eobp))
          (let ((b (pop p4-process-buffers))
                (processed t))
            (cond ((looking-at "^info: //[^#\n]+#\\([1-9][0-9]*\\) - \\(\\(?:move/\\)?add\\|branch\\|\\(?:move/\\)?delete\\|edit\\|integrate\\) ")
                   (p4-update-mode b (intern (match-string 2))
                                   (string-to-number (match-string 1))))
                  ((looking-at "^error: .* - file(s) not opened on this client")
                   (push b have-buffers))
                  (t (setq processed nil)))
            (when processed
              (setf (third p4-process-pending)
                    (remove b (third p4-process-pending)))))
          (forward-line 1))
        (erase-buffer)
        (if (and p4-executable have-buffers)
            (let ((process (p4-start-process "P4" (current-buffer)
                                             "-s" "-x" "-" "have")))
              (setq p4-process-buffers have-buffers)
              (set-process-query-on-exit-flag process nil)
              (set-process-sentinel process 'p4-update-status-sentinel-2)
              (p4-set-process-coding-system process)
              (loop for b in have-buffers
                    do (process-send-string process (p4-buffer-file-name b))
                    do (process-send-string process "\n"))
              (process-send-eof process))
          (kill-buffer (current-buffer))
          (p4-maybe-start-update-statuses))))))

(defvar p4-update-status-process-buffer " *P4 update status*"
  "Name of the buffer in which the status update may be running.")

(defun p4-maybe-start-update-statuses ()
  "Start an asychronous update of the Perforce statuses of some
of the buffers in `p4-update-status-pending-alist', unless such
an update is running already."
  (p4-update-status-pending-sort)
  (when (and p4-executable
             p4-update-status-pending-alist
             (not (get-buffer-process p4-update-status-process-buffer)))
    (let* ((pending (first p4-update-status-pending-alist))
           (last-updated (second pending))
           (timeout (time-add last-updated
                              (seconds-to-time p4-update-status-timeout)))
           (buffers (third pending))
           (now (current-time)))
      (when (and buffers (time-less-p timeout now))
        (setf (second pending) now)
        (with-current-buffer
            (get-buffer-create p4-update-status-process-buffer)
          (setq default-directory
                (with-current-buffer (car buffers)
                  (or p4-default-directory default-directory)))
          (let ((process (p4-start-process "P4" (current-buffer)
                                           "-s" "-x" "-" "opened")))
            (set-process-query-on-exit-flag process nil)
            (set-process-sentinel process 'p4-update-status-sentinel-1)
            (p4-set-process-coding-system process)
            (setq p4-process-buffers (copy-sequence buffers))
            (setq p4-process-pending pending)
            (loop for b in buffers
                  do (process-send-string process (p4-buffer-file-name b))
                  do (process-send-string process "\n"))
            (process-send-eof process)))))))

(defun p4-update-status (&optional force)
  "Start an asynchronous update of the Perforce status of the
current buffer. If the asynchronous update completes
successfully, then `p4-vc-revision' and `p4-vc-status' will be
set in this buffer, `p4-mode' will be set appropriately, and if
`p4-mode' is turned on, then `p4-mode-hook' will be run.
If optional argument FORCE is non-NIL, reset the update timeout
for the current Perforce settings."
  (let ((b (current-buffer)))
    (when (and p4-executable p4-do-find-file buffer-file-name
               (not p4-default-directory)
               (file-accessible-directory-p default-directory))
      (p4-with-set-output
        (let ((set (buffer-substring-no-properties (point-min) (point-max))))
          (p4-update-status-pending-add set b force)))
      (p4-maybe-start-update-statuses))))

(defun p4-refresh-buffer (&optional force verify-modtime)
  "Refresh the current buffer if it is under Perforce control and
the file on disk has changed. If it has unsaved changes, prompt
first."
  (and (or force
           (not p4-do-find-file)
           (memq p4-vc-status '(add branch delete edit integrate sync)))
       (not (and verify-modtime (verify-visited-file-modtime (current-buffer))))
       buffer-file-name
       (file-readable-p buffer-file-name)
       (revert-buffer t (not (buffer-modified-p))))
  (p4-update-status force))

(defun p4-refresh-buffers ()
  "Refresh all buffers that are known to be under Perforce
control."
  (interactive)
  (when (and p4-auto-refresh p4-do-find-file)
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (p4-refresh-buffer nil 'verify-modtime)))))

(defun p4-toggle-vc-mode ()
  "In case, the Perforce server is not available, or when working
off-line, toggle the status check on/off when opening files."
  (interactive)
  (setq p4-do-find-file (not p4-do-find-file))
  (message "P4 status check %s" (if p4-do-find-file "enabled." "disabled.")))

(defalias 'p4-toggle-vc-mode-off 'p4-toggle-vc-mode)
(defalias 'p4-toggle-vc-mode-on 'p4-toggle-vc-mode)

(defun p4-toggle-read-only ()
  "Toggle between `p4-edit' and `p4-revert'."
  (interactive)
  (case p4-vc-status
    (edit (p4-revert))
    (sync (p4-edit))))


;;; Context-aware arguments:

(defun p4-context-single-filename ()
  "Return a single filename based on the current context, or NIL
if no filename can be found in the current context. Try the
following, in order, until one succeeds:
1. the file that the current buffer is visiting;
2. the link at point;
3. the marked file in a Dired buffer;
4. the file at point in a Dired buffer;
5. the file on the current line in a P4 Basic List buffer."
  (cond ((p4-buffer-file-name))
        ((get-char-property (point) 'link-client-name))
        ((get-char-property (point) 'link-depot-name))
        ((get-char-property (point) 'block-client-name))
        ((get-char-property (point) 'block-depot-name))
        ((let ((f (p4-dired-get-marked-files)))
           (and f (p4-follow-link-name (first f)))))
        ((p4-basic-list-get-filename))))

(defun p4-context-filenames-list ()
  "Return a list of filenames based on the current context."
  (let ((f (p4-dired-get-marked-files)))
    (if f (mapcar 'p4-follow-link-name f)
      (let ((f (p4-context-single-filename)))
        (when f (list f))))))

(defcustom p4-open-in-changelist nil
  "If non-NIL, prompt for a numbered pending changelist when opening files."
  :type 'boolean
  :group 'p4)

(defun p4-context-filenames-and-maybe-pending ()
  "Return a list of filenames based on the current context,
preceded by \"-c\" and a changelist number if the user setting
p4-open-in-changelist is non-NIL."
  (append (and p4-open-in-changelist
              (list "-c" (p4-completing-read 'pending "Open in change: ")))
          (p4-context-filenames-list)))

(defun p4-context-single-filename-args ()
  "Return an argument list consisting of a single filename based
on the current context, or NIL if no filename can be found in the
current context."
  (let ((f (p4-context-single-filename)))
    (when f (list f))))

(defun p4-context-single-filename-revision-args ()
  "Return an argument list consisting of a single filename with a
revision or changelevel, based on the current context, or NIL if
the current context doesn't contain a filename with a revision or
changelevel."
  (let ((f (p4-context-single-filename)))
    (when f
      (let ((rev (get-char-property (point) 'rev)))
        (if rev (list (format "%s#%d" f rev))
          (let ((change (get-char-property (point) 'change)))
            (if change (list (format "%s@%d" f change))
              (list f))))))))


;;; Defining Perforce command interfaces:

(eval-when (compile)
  ;; When byte-compiling, get help text by running "p4 help cmd".
  (defun p4-help-text (cmd text)
    (with-temp-buffer
      (if (and (stringp p4-executable)
               (file-executable-p p4-executable)
               (zerop (p4-call-process nil t nil "help" cmd)))
          (concat text "\n" (buffer-substring (point-min) (point-max)))
        text))))

(eval-when (eval load)
  ;; When interpreting, don't run "p4 help cmd" (takes too long).
  (defun p4-help-text (cmd text) text))

(defmacro defp4cmd (name arglist help-cmd help-text &rest body)
  "Define a function, running p4 help HELP-CMD at compile time to
get its docstring."
  `(defun ,name ,arglist ,(p4-help-text help-cmd help-text) ,@body))

(defmacro defp4cmd* (name help-text args-default &rest body)
  "Define an interactive p4 command.

NAME -- command name
HELP-TEXT -- text to prepend to the Perforce help
ARGS-DEFAULT -- form that evaluates to default list of p4 command arguments
BODY -- body of command.

Inside BODY: `cmd' is NAME converted to a string, `args-orig'
is the list of p4 command arguments passed to the command, and
`args' is the actual list of p4 command arguments (either
`args-orig' if non-NIL, or the result of evaluating
`args-default' otherwise. Note that `args-default' thus appears
twice in the expansion."
  `(defp4cmd
     ,(intern (format "p4-%s" name))
     (&optional args-orig)
     ,(format "%s" name)
     ,(format "%s\n\nWith a prefix argument, prompt for \"p4 %s\" command-line options."
              help-text name)
     (interactive
      (when current-prefix-arg
        (let* ((args ,args-default)
               (args-string (p4-join-list args)))
          (list (p4-read-args (format "p4 %s: " ',name) args-string)))))
     (let ((cmd (format "%s" ',name))
           (args (or args-orig ,args-default)))
       ,@body)))


;;; Perforce command interfaces:

(defp4cmd* add
  "Open a new file to add it to the depot."
  (p4-context-filenames-and-maybe-pending)
  (p4-call-command cmd args :mode 'p4-basic-list-mode
                   :callback (p4-refresh-callback)))

(defp4cmd* annotate
  "Print file lines and their revisions."
  (p4-context-single-filename-revision-args)
  (when (null args) (error "No file to annotate!"))
  (when (> (length args) 1) (error "Can't annotate multiples files."))
  (let ((f (car args)))
    (p4-annotate-internal f (and (string-equal f (p4-buffer-file-name))
                                 (line-number-at-pos (point))))))

(defp4cmd p4-branch (&rest args)
  "branch"
  "Create, modify, or delete a branch view specification."
  (interactive (p4-read-args "p4 branch: " "" 'branch))
  (unless args
    (error "Branch must be specified!"))
  (p4-form-command "branch" args :move-to "Description:\n\t"))

(defp4cmd* branches
  "Display list of branch specifications."
  nil
  (p4-call-command cmd args
   :callback (lambda ()
               (p4-regexp-create-links "^Branch \\([^ \t\n]+\\).*\n" 'branch
                                       "Describe branch"))))

(defun p4-change-update-form (buffer new-status re)
  (let ((change (with-current-buffer buffer
                  (when (re-search-forward re nil t)
                    (match-string 1)))))
    (when change
      (rename-buffer (p4-process-buffer-name (list "change" "-o" change)))
      (save-excursion
        (save-restriction
          (widen)
          (goto-char (point-min))
          (when (re-search-forward "^Change:\\s-+\\(new\\)$" nil t)
            (replace-match change t t nil 1))
          (goto-char (point-min))
          (when (re-search-forward "^Status:\\s-+\\(new\\)$" nil t)
            (replace-match new-status t t nil 1))))
      (set-buffer-modified-p nil))))

(defun p4-change-success (cmd buffer)
  (p4-change-update-form buffer "pending" "^Change \\([0-9]+\\) created"))

(defvar p4-change-head-text
  (format "# Created using Perforce-Emacs Integration version %s.
# Type C-c C-c to update the change description on the server.
# Type C-c C-s to submit the change to the server.
# Type C-c C-d to delete the change.
# Type C-x k to cancel the operation.
#\n" p4-version)
  "Text added to top of change form.")

(defp4cmd p4-change (&rest args)
  "change"
  "Create or edit a changelist description."
  (interactive (p4-read-args* "p4 change: " "" 'pending))
  (p4-form-command "change" args :move-to "Description:\n\t"
                   :mode 'p4-change-form-mode
                   :head-text p4-change-head-text
                   :success-callback 'p4-change-success))

(defp4cmd* changes
  "Display list of pending and submitted changelists."
  '("-m" "200" "...")
  (p4-file-change-log cmd args))

(defp4cmd p4-client (&rest args)
  "client"
  "Create or edit a client workspace specification and its view."
  (interactive (p4-read-args* "p4 client: " "" 'client))
  (p4-form-command "client" args :move-to "\\(Description\\|View\\):\n\t"))

(defp4cmd* clients
  "Display list of clients."
  nil
  (p4-call-command cmd args
   :callback (lambda ()
               (p4-regexp-create-links "^Client \\([^ \t\n]+\\).*\n" 'client
                                       "Describe client"))))

(defp4cmd* delete
  "Open an existing file for deletion from the depot."
  (p4-context-filenames-and-maybe-pending)
  (when (yes-or-no-p "Really delete from depot? ")
    (p4-call-command cmd args :mode 'p4-basic-list-mode
                     :callback (p4-refresh-callback))))

(defp4cmd p4-describe (&rest args)
  "describe"
  "Display a changelist description."
  (interactive (p4-read-args "p4 describe: "
                             (concat p4-default-diff-options " ")))
  (p4-call-command "describe" args :mode 'p4-diff-mode
                   :callback 'p4-activate-diff-buffer))

(defp4cmd* diff
  "Display diff of client file with depot file."
  (cons p4-default-diff-options (p4-context-filenames-list))
  (p4-call-command cmd args :mode 'p4-diff-mode
                   :callback 'p4-activate-diff-buffer))

(defun p4-diff-all-opened ()
  (interactive)
  (p4-diff (list p4-default-diff-options)))

(defun p4-get-file-rev (rev)
  "Return the full filespec corresponding to revision REV, using
the context to determine the filename if necessary."
  (cond ((integerp rev)
         (format "%s#%d" (p4-context-single-filename) rev))
        ((string-match "^\\([1-9][0-9]*\\|none\\|head\\|have\\)$" rev)
         (format "%s#%s" (p4-context-single-filename) rev))
        ((string-match "^\\(?:[#@]\\|$\\)" rev)
         (format "%s%s" (p4-context-single-filename) rev))
        (t
         rev)))

(defp4cmd p4-diff2 (&rest args)
  "diff2"
  "Compare one set of depot files to another."
  (interactive
   (if current-prefix-arg
       (p4-read-args* "p4 diff2: " (concat p4-default-diff-options " ") 'branch)
     (let* ((rev (or (get-char-property (point) 'rev) p4-vc-revision 0))
            (rev1 (p4-read-arg-string
                   "First filespec/revision to diff: "
                   (when (> rev 1) (number-to-string (1- rev)))))
            (rev2 (p4-read-arg-string
                   "Second filespec/revision to diff: "
                   (when (> rev 1) (number-to-string rev))))
            (opts (p4-read-arg-string
                   "Optional arguments: "
                   (concat p4-default-diff-options " "))))
       (append (p4-make-list-from-string opts)
               (mapcar 'p4-get-file-rev (list rev1 rev2))))))
  (p4-call-command "diff2" args
                   :mode 'p4-diff-mode :callback 'p4-activate-diff-buffer))

(defun p4-activate-ediff-callback ()
  "Return a callback function that runs ediff on the current
buffer and the P4 output buffer."
  (lexical-let ((orig-buffer (current-buffer)))
    (lambda ()
      (when (buffer-live-p orig-buffer)
        (p4-fontify-print-buffer t)
        (lexical-let ((depot-buffer (current-buffer)))
          (ediff-buffers orig-buffer depot-buffer))))))

(defun p4-ediff (prefix)
  "Use ediff to compare file with its original client version."
  (interactive "P")
  (if prefix
      (call-interactively 'p4-ediff2)
    (p4-call-command "print" (list (concat (p4-context-single-filename) "#have"))
                     :after-show (p4-activate-ediff-callback))))

(defun p4-activate-ediff2-callback (other-file)
  "Return a callback function that runs ediff on the P4 output
buffer and OTHER-FILE."
  (lexical-let ((other-file other-file))
    (lambda ()
      (p4-fontify-print-buffer t)
      (p4-call-command "print" (list other-file)
                       :after-show (p4-activate-ediff-callback)))))

(defun p4-ediff2 (rev1 rev2)
  "Use ediff to compare two versions of a depot file.
When visiting a depot file, type \\[p4-ediff2] and enter the versions."
  (interactive
   (let ((rev (or (get-char-property (point) 'rev) p4-vc-revision 0)))
     (list (p4-read-arg-string "First filespec/revision to diff: "
                               (when (> rev 1) (number-to-string (1- rev))))
           (p4-read-arg-string "Second filespec/revision to diff: "
                               (when (> rev 1) (number-to-string rev))))))
  (p4-call-command "print" (list (p4-get-file-rev rev1))
   :after-show (p4-activate-ediff2-callback (p4-get-file-rev rev2))))

(defun p4-edit-pop-up-output-p ()
  "Show the output of p4 edit in the echo area if it concerns a
single file (but possibly with \"... also opened by\"
continuation lines); show it in a pop-up window otherwise."
  (save-excursion
    (goto-char (point-min))
    (not (looking-at ".*\n\\(?:\\.\\.\\. .*\n\\)*\\'"))))

(defp4cmd* edit
  "Open an existing file for edit."
  (p4-context-filenames-and-maybe-pending)
  (p4-call-command cmd args
                   :mode 'p4-basic-list-mode
                   :pop-up-output 'p4-edit-pop-up-output-p
                   :callback (p4-refresh-callback 'p4-edit-hook)))

(defp4cmd* filelog
  "List revision history of files."
  (p4-context-filenames-list)
  (p4-file-change-log cmd args))

(defp4cmd* files
  "List files in the depot."
  (p4-context-filenames-list)
  (p4-call-command cmd args :mode 'p4-basic-list-mode))

(defp4cmd p4-fix (&rest args)
  "fix"
  "Mark jobs as being fixed by the specified changelist."
  (interactive (p4-read-args "p4 fix: " "" 'job))
  (p4-call-command "fix" args))

(defp4cmd* fixes
  "List jobs with fixes and the changelists that fix them."
  nil
  (p4-call-command cmd args :callback 'p4-activate-fixes-buffer
                   :pop-up-output (lambda () t)))

(defp4cmd* flush
  "Synchronize the client with its view of the depot (without copying files)."
  nil
  (p4-call-command cmd args :mode 'p4-basic-list-mode
                   :callback 'p4-refresh-buffers))

(defp4cmd* fstat
  "Dump file info."
  (p4-context-filenames-list)
  (p4-call-command cmd args))

(defp4cmd p4-grep (&rest args)
  "grep"
  "Print lines matching a pattern."
  (interactive (p4-read-args "p4 grep: " '("-e  ..." . 3)))
  (p4-ensure-logged-in)
  (p4-compilation-start
   (append (list "grep" "-n") args)
   'p4-grep-mode))

(defp4cmd p4-group (&rest args)
  "group"
  "Change members of user group."
  (interactive (p4-read-args* "p4 group: " "" 'group))
  (p4-form-command "group" args))

(defp4cmd p4-groups (&rest args)
  "groups"
  "List groups (of users)."
  (interactive (p4-read-args* "p4 groups: " "" 'group))
  (p4-call-command "groups" args
   :callback (lambda ()
               (p4-regexp-create-links "^\\(.*\\)\n" 'group
                                       "Describe group"))))

(defp4cmd* have
  "List the revisions most recently synced to the current workspace."
  (p4-context-filenames-list)
  (p4-call-command cmd args :mode 'p4-basic-list-mode))

(defp4cmd p4-help (&rest args)
  "help"
  "Print help message."
  (interactive (p4-read-args "p4 help: " "" 'help))
  (p4-call-command "help" args
   :callback (lambda ()
               (let ((case-fold-search))
                 (loop for re in '("\\<p4\\s-+help\\s-+\\([a-z][a-z0-9]*\\)\\>"
                                   "'p4\\(?:\\s-+-[a-z]+\\)*\\s-+\\([a-z][a-z0-9]*\\)\\>"
                                   "^\t\\([a-z][a-z0-9]*\\) +[A-Z]")
                       do (p4-regexp-create-links re 'help))))))

(defp4cmd p4-info ()
  "info"
  "Display client/server information."
  (interactive)
  (p4-call-command "info"))

(defp4cmd p4-integ (&rest args)
  "integ"
  "Integrate one set of files into another."
  (interactive (p4-read-args "p4 integ: " "-b "))
  (p4-call-command "integ" args :mode 'p4-basic-list-mode))

(defun p4-job-success (cmd buffer)
  (let ((job (with-current-buffer buffer
               (when (looking-at "Job \\(.+\\) saved\\.$")
                 (match-string 1)))))
    (when job
      (save-excursion
        (save-restriction
          (widen)
          (goto-char (point-min))
          (when (re-search-forward "Job:\\s-+\\(new\\)$" nil t)
            (replace-match job t t nil 1)
            (rename-buffer (p4-process-buffer-name (list "job" "-o" job)))
            (set-buffer-modified-p nil)))))))

(defvar p4-job-head-text
  (format "# Created using Perforce-Emacs Integration version %s.
# Type C-c C-c to update the job description on the server.
# Type C-c C-f to show the fixes associated with this job.
# Type C-x k to cancel the operation.
#\n" p4-version)
  "Text added to top of job form.")

(defp4cmd p4-job (&rest args)
  "job"
  "Create or edit a job (defect) specification."
  (interactive (p4-read-args* "p4 job: " "" 'job))
  (p4-form-command "job" args :move-to "Description:\n\t"
                   :mode 'p4-job-form-mode
                   :head-text p4-job-head-text
                   :success-callback 'p4-job-success))

(defp4cmd* jobs
  "Display list of jobs."
  nil
  (p4-call-command cmd args
   :callback (lambda () (p4-find-jobs (point-min) (point-max)))))

(defp4cmd p4-jobspec ()
  "jobspec"
  "Edit the job template."
  (interactive)
  (p4-form-command "jobspec"))

(defp4cmd p4-label (&rest args)
  "label"
  "Create or edit a label specification."
  (interactive (p4-read-args "p4 label: " "" 'label))
  (if args
      (p4-form-command "label" args :move-to "Description:\n\t")
    (error "label must be specified!")))

(defp4cmd* labels
  "Display list of defined labels."
  nil
  (p4-call-command cmd args
   :callback (lambda ()
               (p4-regexp-create-links "^Label \\([^ \t\n]+\\).*\n" 'label
                                       "Describe label"))))

(defp4cmd p4-labelsync (&rest args)
  "labelsync"
  "Apply the label to the contents of the client workspace."
  (interactive (p4-read-args* "p4 labelsync: "))
  (p4-call-command "labelsync" args :mode 'p4-basic-list-mode))

(defp4cmd* lock
  "Lock an open file to prevent it from being submitted."
  (p4-context-filenames-list)
  (p4-call-command cmd args :callback (p4-refresh-callback)))

(defp4cmd* login
  "Log in to Perforce by obtaining a session ticket."
  nil
  (if (member "-s" args)
      (p4-call-command cmd args)
    (let ((first-iteration t)
          (logged-in nil)
          (prompt "Enter password for %s: "))
      (while (not logged-in)
        (with-temp-buffer
          (or (and first-iteration (stringp p4-password-source)
                   (let ((process-environment (p4-current-environment)))
                     (zerop (call-process-shell-command p4-password-source
                                                        nil '(t nil)))))
              (insert (read-passwd (format prompt (p4-current-server-port))) "\n"))
          (setq first-iteration nil)
          (p4-with-coding-system
            (apply #'p4-call-process-region (point-min) (point-max)
                   t t nil cmd "-a" args))
          (goto-char (point-min))
          (when (re-search-forward "Enter password:.*\n" nil t)
            (replace-match ""))
          (goto-char (point-min))
          (if (looking-at "Password invalid")
              (setq prompt "Password invalid. Enter password for %s: ")
            (setq logged-in t)
            (message "%s" (buffer-substring (point-min) (1- (point-max))))))))
    ;; There might have been failed status updates while the user was
    ;; logged out, so try re-running them now that the user is logged
    ;; in.
    (p4-maybe-start-update-statuses)))

(defp4cmd* logout
  "Log out from Perforce by removing or invalidating a ticket."
  nil
  (p4-call-command cmd args :auto-login nil))

(defun p4-move-complete-callback (from-file to-file)
  (lexical-let ((from-file from-file) (to-file to-file))
    (lambda ()
      (let ((buffer (get-file-buffer from-file)))
        (when buffer
          (with-current-buffer buffer
            (find-alternate-file to-file)))))))

(defp4cmd p4-move (from-file to-file)
  "move"
  "Move file(s) from one location to another.
If the \"move\" command is unavailable, use \"integrate\"
followed by \"delete\"."
  (interactive
   (list
    (p4-read-arg-string "move from: " (p4-context-single-filename))
    (p4-read-arg-string "move to: " (p4-context-single-filename))))
  (if (< (p4-server-version) 2009)
      (p4-call-command "integ" (list from-file to-file)
       :callback (lambda () (p4-call-command "delete" (list from-file))))
    (p4-call-command "move" (list from-file to-file)
     :mode 'p4-basic-list-mode
     :callback (p4-move-complete-callback from-file to-file))))

(defalias 'p4-rename 'p4-move)

(defp4cmd* opened
  "List open files and display file status."
  nil
  (p4-call-command cmd args :mode 'p4-opened-list-mode
   :callback (lambda ()
               (p4-regexp-create-links "\\<change \\([1-9][0-9]*\\) ([a-z]+)"
                                       'pending "Edit change"))
   :pop-up-output (lambda () t)))

(defp4cmd* print
  "Write a depot file to a buffer."
  (p4-context-single-filename-revision-args)
  (p4-call-command cmd args :callback 'p4-activate-print-buffer))

(defp4cmd p4-passwd (old-pw new-pw new-pw2)
  "passwd"
  "Set the user's password on the server (and Windows client)."
  (interactive
   (list (read-passwd "Enter old password: ")
         (read-passwd "Enter new password: ")
         (read-passwd "Re-enter new password: ")))
  (if (string= new-pw new-pw2)
      (p4-call-command "passwd" (list "-O" old-pw "-P" new-pw2))
    (error "Passwords don't match")))

(defp4cmd* reconcile
  "Open files for add, delete, and/or edit to reconcile client
with workspace changes made outside of Perforce."
  '("...")
  (p4-call-command cmd args :mode 'p4-basic-list-mode))

(defp4cmd* refresh
  "Refresh the contents of an unopened file. Alias for \"sync -f\"."
  (cons "-f" (p4-context-filenames-list))
  (p4-call-command "sync" args :mode 'p4-basic-list-mode
                   :callback 'p4-refresh-buffers))

(defp4cmd* reopen
  "Change the filetype of an open file or move it to another
changelist."
  (p4-context-filenames-list)
  (p4-call-command cmd args :mode 'p4-basic-list-mode
                   :callback (p4-refresh-callback)))

(defp4cmd* resolve
  "Resolve integrations and updates to workspace files."
  (list (concat p4-default-diff-options " "))
  (let (buffer (buf-name "*P4 resolve*"))
    (setq buffer (get-buffer buf-name))
    (if (and (buffer-live-p buffer)
             (not (comint-check-proc buffer)))
        (let ((cur-dir default-directory))
          (with-current-buffer buffer
            (cd cur-dir)
            (goto-char (point-max))
            (insert "\n--------\n\n"))))
    (setq args (cons cmd args))
    (let ((process-environment (cons "P4PAGER=" process-environment)))
      (p4-ensure-logged-in)
      (setq buffer (apply #'p4-make-comint "P4 resolve" nil args)))
    (with-selected-window (display-buffer buffer)
      (goto-char (point-max)))))

(defvar p4-empty-diff-regexp
  "\\(?:==== .* ====\\|--- .*\n\\+\\+\\+ .*\\)\n\\'"
  "Regular expression matching p4 diff output when there are no changes.")

(defp4cmd* revert
  "Discard changes from an opened file."
  (p4-context-filenames-list)
  (let ((prompt t))
    (unless args-orig
      (let* ((diff-args (append (cons "diff" (p4-make-list-from-string p4-default-diff-options)) args))
             (inhibit-read-only t))
        (with-current-buffer
            (p4-make-output-buffer (p4-process-buffer-name diff-args)
                                   'p4-diff-mode)
          (p4-run diff-args)
          (cond ((looking-at ".* - file(s) not opened on this client")
                 (p4-process-show-error))
                ((looking-at ".* - file(s) not opened for edit")
                 (kill-buffer (current-buffer)))
                ((looking-at p4-empty-diff-regexp)
                 (kill-buffer (current-buffer))
                 (setq prompt nil))
                (t
                 (p4-activate-diff-buffer)
                 (display-buffer (current-buffer)))))))
    (when (or (not prompt) (yes-or-no-p "Really revert? "))
      (p4-call-command cmd args :mode 'p4-basic-list-mode
                       :callback (p4-refresh-callback)))))

(defp4cmd p4-set ()
  "set"
  "Set or display Perforce variables."
  (interactive)
  (p4-call-command "set"))

(defun p4-shelve-failure (cmd buffer)
  ;; The failure might be because no files were shelved. But the
  ;; change was created, so this counts as a success for us.
  (if (with-current-buffer buffer
        (looking-at "^Change \\([0-9]+\\) created\\.\nShelving files for change \\1\\.\nNo files to shelve\\.$"))
      (p4-change-success cmd buffer)
    (p4-form-commit-failure-callback-default cmd buffer)))

(defp4cmd p4-shelve (&optional args)
  "shelve"
  "Store files from a pending changelist into the depot."
  (interactive
   (cond ((integerp current-prefix-arg)
          (list (format "%d" current-prefix-arg)))
         (current-prefix-arg
          (list (p4-read-args "p4 shelve: " "" 'pending)))))
  (save-some-buffers nil (lambda () (or (not p4-do-find-file) p4-vc-status)))
  (p4-form-command "change" args :move-to "Description:\n\t"
                   :commit-cmd "shelve"
                   :success-callback 'p4-change-success
                   :failure-callback 'p4-shelve-failure))

(defp4cmd* status
  "Identify differences between the workspace with the depot."
  '("...")
  (p4-call-command cmd args :mode 'p4-status-list-mode))

(defun p4-empty-diff-buffer ()
  "If there exist any files opened for edit with an empty diff,
return a buffer listing those files. Otherwise, return NIL."
  (let ((args (list "diff" "-sr")))
    (with-current-buffer (p4-make-output-buffer (p4-process-buffer-name args))
      (when (zerop (p4-run args))
        ;; The output of p4 diff -sr can be:
        ;; "File(s) not opened on this client." if no files opened at all.
        ;; "File(s) not opened for edit." if files opened (but none for edit)
        ;; Nothing if files opened for edit (but all have changes).
        ;; List of filenames (otherwise).
        (if (or (eobp) (looking-at "File(s) not opened"))
            (progn (kill-buffer (current-buffer)) nil)
          (current-buffer))))))

(defun p4-submit-success (cmd buffer)
  (p4-change-update-form buffer "submitted" "^Change \\(?:[0-9]+ renamed change \\)?\\([0-9]+\\)\\(?: and\\)? submitted\\.$")
  (p4-refresh-buffers))

(defun p4-submit-failure (cmd buffer)
  (p4-change-update-form buffer "pending"
                         "^Submit failed -- fix problems above then use 'p4 submit -c \\([0-9]+\\)'\\.$")
  (with-current-buffer buffer
    (p4-process-show-error "submit -i failed to complete successfully.")))

(defvar p4-submit-head-text
  (format "# Created using Perforce-Emacs Integration version %s.
# Type C-c C-c to submit the change to the server.
# Type C-c C-p to save the change description as a pending changelist.
# Type C-x k to cancel the operation.
#\n" p4-version)
  "Text added to top of change form.")

(defp4cmd p4-submit (&optional args)
  "submit"
  "Submit open files to the depot."
  (interactive
   (cond ((integerp current-prefix-arg)
          (list (format "%d" current-prefix-arg)))
         (current-prefix-arg
          (list (p4-read-args "p4 change: " "" 'pending)))))
  (p4-with-temp-buffer (list "-s" "opened")
    (unless (re-search-forward "^info: " nil t)
      (error "Files not opened on this client.")))
  (save-some-buffers nil (lambda () (or (not p4-do-find-file) p4-vc-status)))
  (let ((empty-buf (and p4-check-empty-diffs (p4-empty-diff-buffer))))
    (when (or (not empty-buf)
              (save-window-excursion
                (pop-to-buffer empty-buf)
                (yes-or-no-p
                 "File with empty diff opened for edit. Submit anyway? ")))
      (p4-form-command "change" args :move-to "Description:\n\t"
                       :commit-cmd "submit"
                       :mode 'p4-change-form-mode
                       :head-text p4-submit-head-text
                       :success-callback 'p4-submit-success
                       :failure-callback 'p4-submit-failure))))

(defp4cmd* sync
  "Synchronize the client with its view of the depot."
  nil
  (p4-call-command cmd args :mode 'p4-basic-list-mode
                   :callback 'p4-refresh-buffers))

(defalias 'p4-get 'p4-sync)

(defp4cmd* tickets
  "Display list of session tickets for this user."
  nil
  (p4-call-command cmd args))

(defp4cmd* unlock
  "Release a locked file, leaving it open."
  (p4-context-filenames-list)
  (p4-call-command cmd args :callback (p4-refresh-callback)))

(defp4cmd p4-unshelve (&rest args)
  "unshelve"
  "Restore shelved files from a pending change into a workspace."
  (interactive
   (if current-prefix-arg
       (p4-read-args "p4 unshelve: " "" 'shelved)
     (append (list "-s" (p4-completing-read 'shelved "Unshelve from: "))
             (when p4-open-in-changelist
               (list "-c" (p4-completing-read 'pending "Open in change: "))))))
  (p4-call-command "unshelve" args :mode 'p4-basic-list-mode))

(defp4cmd* update
  "Synchronize the client with its view of the depot (with safety check)."
  nil
  (p4-call-command cmd args :mode 'p4-basic-list-mode
                   :callback 'p4-refresh-buffers))

(defp4cmd p4-user (&rest args)
  "user"
  "Create or edit a user specification."
  (interactive (p4-read-args* "p4 user: " "" 'user))
  (p4-form-command "user" args))

(defp4cmd p4-users (&rest args)
  "users"
  "List Perforce users."
  (interactive (p4-read-args* "p4 users: " "" 'user))
  (p4-call-command "users" args
   :callback (lambda ()
               (p4-regexp-create-links "^\\([^ \t\n]+\\).*\n" 'user
                                       "Describe user"))))

(defp4cmd* where
  "Show how file names are mapped by the client view."
  (p4-context-filenames-list)
  (p4-call-command cmd args))


;;; Output decoration:

(defun p4-create-active-link (start end prop-list &optional help-echo)
  (add-text-properties start end prop-list)
  (add-text-properties start end '(active t face bold mouse-face highlight))
  (when help-echo
    (add-text-properties start end
                         `(help-echo ,(concat "mouse-1: " help-echo)))))

(defun p4-create-active-link-group (group prop-list &optional help-echo)
  (p4-create-active-link (match-beginning group) (match-end group)
                         prop-list help-echo))

(defun p4-file-change-log (cmd file-list-spec)
  (p4-call-command cmd (cons "-l" file-list-spec) :mode 'p4-filelog-mode
                   :callback 'p4-activate-file-change-log-buffer))

(defun p4-activate-file-change-log-buffer ()
  (save-excursion
    (p4-mark-print-buffer)
    (goto-char (point-min))
    (while (re-search-forward (concat
                               "^\\(\\.\\.\\. #\\([1-9][0-9]*\\) \\)?[Cc]hange "
                               "\\([1-9][0-9]*\\) \\([a-z]+\\)?.*on.*by "
                               "\\([^ @\n]+\\)@\\([^ \n]+\\).*\n"
                               "\\(\\(?:\n\\|[ \t].*\n\\)*\\)") nil t)
      (let* ((rev-match 2)
             (rev (and (match-string rev-match)
                       (string-to-number (match-string rev-match))))
             (ch-match 3)
             (change (string-to-number (match-string ch-match)))
             (act-match 4)
             (action (match-string-no-properties act-match))
             (user-match 5)
             (user (match-string-no-properties user-match))
             (cl-match 6)
             (client (match-string-no-properties cl-match))
             (desc-match 7))
        (when rev
          (p4-create-active-link-group rev-match `(rev ,rev) "Print revision"))
        (p4-create-active-link-group ch-match `(change ,change) "Describe change")
        (when action
          (p4-create-active-link-group act-match `(action ,action rev ,rev)
                                       "Show diff"))
        (p4-create-active-link-group user-match `(user ,user) "Describe user")
        (p4-create-active-link-group cl-match `(client ,client) "Describe client")
        (add-text-properties (match-beginning desc-match)
                             (match-end desc-match)
                             '(invisible t isearch-open-invisible t))))
    (p4-find-change-numbers (point-min) (point-max))
    (setq buffer-invisibility-spec (list))))

(defvar p4-plaintext-change-regexp
  (concat "\\(?:[#@]\\|number\\|no\\.\\|\\)\\s-*"
          "\\([1-9][0-9]*\\)[-,]?\\s-*"
          "\\(?:and/or\\|and\\|&\\|or\\|\\)\\s-*")
  "Regexp matching a Perforce change number in plain English text.")

(defun p4-find-change-numbers (start end)
  "Scan region between START and END for plain-text references to
change numbers, and make the change numbers clickable."
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (goto-char (point-min))
      (while (re-search-forward
              "\\(?:changes?\\|submit\\|p4\\)[:#]?[ \t\n]+" nil t)
        (save-excursion
          (while (looking-at p4-plaintext-change-regexp)
            (p4-create-active-link-group
             1 `(change ,(string-to-number (match-string 1)))
             "Describe change")
            (goto-char (match-end 0))))))))

(defun p4-find-jobs (start end)
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (goto-char (point-min))
      (while (re-search-forward "^\\([^ \n]+\\) on [0-9]+/[0-9]+/[0-9]+ by \\([^ \n]+\\)" nil t)
        (p4-create-active-link-group 1 `(job ,(match-string-no-properties 1))
                                     "Describe job")
        (p4-create-active-link-group 2 `(user ,(match-string-no-properties 2))
                                     "Describe user")))))

(defun p4-mark-depot-list-buffer (&optional print-buffer)
  (save-excursion
    (let ((depot-regexp
           (if print-buffer
               "\\(^\\)\\(//[^/@# \n][^/@#\n]*/[^@#\n]+#[1-9][0-9]*\\) - "
             "^\\(\\.\\.\\. [^/\n]*\\|==== \\)?\\(//[^/@# \n][^/@#\n]*/[^#\n]*\\(?:#[1-9][0-9]*\\)?\\)")))
      (goto-char (point-min))
      (while (re-search-forward depot-regexp nil t)
        (let* ((p4-depot-file (match-string-no-properties 2))
               (start (match-beginning 2))
               (end (match-end 2))
               (branching-op-p (and (match-string 1)
                                    (string-match "\\.\\.\\. \\.\\.\\..*"
                                                  (match-string 1))))
               (prop-list `(link-depot-name ,p4-depot-file)))
          ;; some kind of operation related to branching/integration
          (when branching-op-p
            (setq prop-list (append `(history-for ,p4-depot-file
                                      face p4-depot-branch-face)
                                      prop-list)))
          (p4-create-active-link start end prop-list "Visit file"))))))

(defun p4-fontify-print-buffer (&optional delete-filespec)
  "Fontify a p4-print buffer according to the filename in the
first line of outputput from \"p4 print\". If the optional
argument DELETE-FILESPEC is non-NIL, remove the first line."
  (save-excursion
    (goto-char (point-min))
    (when (looking-at "^//[^#@\n]+/\\([^/#@\n]+\\).*\n")
      (let ((buffer-file-name (match-string 1))
            (first-line (match-string-no-properties 0))
            (inhibit-read-only t))
        (replace-match "" t t)
        (set-auto-mode)
        ;; Ensure that the entire buffer is fontified, even if jit-lock or
        ;; lazy-lock is being used.
        (ps-print-ensure-fontified (point-min) (point-max))
        ;; But then turn off the major mode, freezing the fontification so that
        ;; when we add contents to the buffer (such as restoring the first line
        ;; containing the filespec, or adding annotations) these additions
        ;; don't get fontified.
        (remove-hook 'change-major-mode-hook 'font-lock-change-mode t)
        (fundamental-mode)
        (goto-char (point-min))
        (unless delete-filespec (insert first-line))))))

(defun p4-mark-print-buffer (&optional print-buffer)
  (save-excursion
    (p4-mark-depot-list-buffer print-buffer)
    (let ((depot-regexp
           (if print-buffer
               "^\\(//[^/@# \n][^/@#\n]*/\\)[^@#\n]+#[1-9][0-9]* - "
             "^\\(//[^/@# \n][^/@#\n]*/\\)")))
      (goto-char (point-min))
      (while (re-search-forward depot-regexp nil t)
        (let ((link-client-name (get-char-property (match-end 1)
                                                   'link-client-name))
              (link-depot-name (get-char-property (match-end 1)
                                                  'link-depot-name))
              (start (match-beginning 1))
              (end (point-max)))
          (save-excursion
            (when (re-search-forward depot-regexp nil t)
              (setq end (match-beginning 1))))
          (when link-client-name
            (add-text-properties start end
                                 `(block-client-name ,link-client-name)))
          (when link-depot-name
            (add-text-properties start end
                                 `(block-depot-name ,link-depot-name)))
          (p4-find-change-numbers start
                                  (save-excursion
                                    (goto-char start)
                                    (line-end-position))))))))

(defun p4-activate-print-buffer (&optional delete-filespec)
  (p4-fontify-print-buffer delete-filespec)
  (p4-mark-print-buffer t)
  (use-local-map p4-basic-mode-map))

(defun p4-buffer-set-face-property (regexp face-property)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward regexp nil t)
      (let ((start (match-beginning 0))
            (end (match-end 0)))
        (add-text-properties start end `(face ,face-property))))))

(defun p4-activate-diff-buffer ()
  (save-excursion
    (p4-mark-depot-list-buffer)
    (p4-find-jobs (point-min) (point-max))
    (goto-char (point-min))
    (while (re-search-forward "^\\(==== //\\).*\n"
                              nil t)
      (let* ((link-depot-name (get-char-property (match-end 1) 'link-depot-name))
             (start (match-beginning 0))
             (end (save-excursion
                    (if (re-search-forward "^==== " nil t)
                        (match-beginning 0)
                      (point-max)))))
        (when link-depot-name
          (add-text-properties start end `(block-depot-name ,link-depot-name)))))

    (goto-char (point-min))
    (while (re-search-forward
            (concat "^[@0-9].*\\([cad+]\\)\\([0-9]*\\).*\n"
                    "\\(\\(\n\\|[^@0-9\n].*\n\\)*\\)") nil t)
      (let ((first-line (string-to-number (match-string 2)))
            (start (match-beginning 3))
            (end (match-end 3)))
        (add-text-properties start end `(first-line ,first-line start ,start))))

    (goto-char (point-min))
    (let ((stop
           (if (re-search-forward "^\\(\\.\\.\\.\\|====\\)" nil t)
               (match-beginning 0)
             (point-max))))
      (p4-find-change-numbers (point-min) stop))

    (goto-char (point-min))
    (when (looking-at "^Change [1-9][0-9]* by \\([^ @\n]+\\)@\\([^ \n]+\\)")
      (p4-create-active-link-group 1 `(user ,(match-string-no-properties 1))
                                   "Describe user")
      (p4-create-active-link-group 2 `(client ,(match-string-no-properties 2))
                                   "Describe client"))))

(defun p4-activate-fixes-buffer ()
  (let ((inhibit-read-only t))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^\\(\\S-+\\) fixed by change \\([0-9]+\\) on [0-9/]+ by \\([^ @\n]+\\)@\\([^ \n]+\\)" nil t)
        (p4-create-active-link-group 1 `(job ,(match-string-no-properties 1)))
        (p4-create-active-link-group 2 `(change ,(string-to-number (match-string 2))))
        (p4-create-active-link-group 3 `(user ,(match-string-no-properties 3)))
        (p4-create-active-link-group 4 `(client ,(match-string-no-properties 4)))))))

(defun p4-regexp-create-links (regexp property &optional help-echo)
  (let ((inhibit-read-only t))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward regexp nil t)
        (p4-create-active-link-group
         1 (list property (match-string-no-properties 1)) help-echo)))))


;;; Annotation:

(defconst p4-blame-change-regex
  (concat "^\\.\\.\\. #"     "\\([1-9][0-9]*\\)"   ; revision
          "\\s-+change\\s-+" "\\([1-9][0-9]*\\)"   ; change
          "\\s-+"            "\\([^ \t\n]+\\)"       ; type
          "\\s-+on\\s-+"     "\\([^ \t\n]+\\)"       ; date
          "\\s-+by\\s-+"     "\\([^ \t\n]+\\)"       ; author
          "@.*\n\n\t\\(.*\\)"))                    ; description

(defconst p4-blame-revision-regex
  (concat "^\\([0-9]+\\),?"
          "\\([0-9]*\\)"
          "\\([acd]\\)"
          "\\([0-9]+\\),?"
          "\\([0-9]*\\)"))

(defalias 'p4-blame 'p4-annotate)
(defalias 'p4-print-with-rev-history 'p4-annotate)
(defalias 'p4-annotate-line 'p4-annotate)
(defalias 'p4-blame-line 'p4-annotate)

(defstruct p4-file-revision filespec filename revision change date user description links desc)

(defun p4-link (width value properties &optional help-echo)
  "Insert VALUE, right-aligned, into a field of WIDTH.
Make it into an active link with PROPERTIES.
Optional argument HELP-ECHO is the text to display when hovering
the mouse over the link."
  (let* ((text (format (format "%%%ds" width) value))
         (length (length text))
         (text (if (< length width) text (substring text 0 width)))
         (p (point)))
    (insert text)
    (p4-create-active-link p (point) properties help-echo)))

(defun p4-file-revision-annotate-links (rev)
  (let ((links (p4-file-revision-links rev)))
    (or links
        (with-temp-buffer
          (let ((change (p4-file-revision-change rev))
                (filename (p4-file-revision-filename rev))
                (revision (p4-file-revision-revision rev))
                (user (p4-file-revision-user rev)))
            (p4-link 7 (format "%d" change) `(change ,change) "Describe change")
            (insert " ")
            (p4-link 5 (format "#%d" revision)
                     `(rev ,revision link-depot-name ,filename)
                     "Print revision")
            (insert " ")
            (insert (format "%10s " (p4-file-revision-date rev)))
            (p4-link 8 user `(user ,user) "Describe user")
            (insert ": "))
          (setf (p4-file-revision-links rev)
                (buffer-substring (point-min) (point-max)))))))

(defun p4-file-revision-annotate-desc (rev)
  (let ((links (p4-file-revision-desc rev)))
    (or links
        (let ((desc (p4-file-revision-description rev)))
          (setf (p4-file-revision-desc rev)
                (if (<= (length desc) 33)
                    (format "%-33s: " desc)
                  (format "%33s: " (substring desc 0 33))))))))

(defun p4-parse-filelog (filespec)
  "Parse the filelog for FILESPEC.
Return an association list mapping revision number to a
`p4-file-revision' structure, in reverse order (earliest revision
first)."
  (let (head-seen       ; head revision not deleted?
        change-alist    ; alist mapping change to p4-file-revision structures
        current-file    ; current filename in filelog
        (args (list "filelog" "-l" "-i" filespec)))
    (message "Running p4 %s..." (p4-join-list args))
    (p4-with-temp-buffer args
      (while (not (eobp))
        (cond ((looking-at "^//.*$")
               (setq current-file (match-string 0)))
              ((looking-at p4-blame-change-regex)
               (let ((op (match-string 3))
                     (revision (string-to-number (match-string 1)))
                     (change (string-to-number (match-string 2))))
                 (if (string= op "delete")
                     (unless head-seen (goto-char (point-max)))
                   (push (cons change
                               (make-p4-file-revision
                                :filespec (format "%s#%d" current-file revision)
                                :filename current-file
                                :revision revision
                                :change change
                                :date (match-string 4)
                                :user (match-string 5)
                                :description (match-string 6)))
                         change-alist)
                   (setq head-seen t)))))
        (forward-line))
      change-alist)))

(defun p4-annotate-changes (filespec)
  "Return a list of change numbers, one for each line of FILESPEC."
  (let ((args (list "annotate" "-i" "-c" "-q" filespec)))
    (message "Running p4 %s..." (p4-join-list args))
    (p4-with-temp-buffer args
      (loop while (re-search-forward "^\\([1-9][0-9]*\\):" nil t)
            collect (string-to-number (match-string 1))))))

(defun p4-annotate-changes-by-patching (filespec change-alist)
  "Return a list of change numbers, one for each line of FILESPEC.
This builds the result by walking through the changes in
CHANGE-ALIST one at a time, fetching the diff, and applying the
patch. This is very slow for files with many revisions, so should
only be used when p4 annotate is unavailable."
  (let* ((base (cdar change-alist))
         (base-change (caar change-alist))
         (base-change-string (format "%d\n" base-change))
         (buffer (get-buffer-create "*P4 annotate tmp*")))
    (with-current-buffer buffer
      (erase-buffer)
      (message "Patching for change %d..." base-change)
      (p4-run (list "print" "-q" (p4-file-revision-filespec base)))
      (while (re-search-forward ".*\n" nil t)
        (replace-match base-change-string t t))
      (loop for (c1 . f1) in change-alist
            and (c2 . f2) in (cdr change-alist)
            for change-string = (format "%d\n" c2)
            do (p4-with-temp-buffer
                   (list "diff2"
                         (p4-file-revision-filespec f1)
                         (p4-file-revision-filespec f2))
                 (message "Patching for change %d..." c2)
                 (goto-char (point-max))
                 (while (re-search-backward p4-blame-revision-regex nil t)
                   (let ((la (string-to-number (match-string 1)))
                         (lb (string-to-number (match-string 2)))
                         (op (match-string 3))
                         (ra (string-to-number (match-string 4)))
                         (rb (string-to-number (match-string 5))))
                     (when (= lb 0) (setq lb la))
                     (when (= rb 0) (setq rb ra))
                     (cond ((string= op "a") (incf la))
                           ((string= op "d") (incf ra)))
                     (with-current-buffer buffer
                       (p4-goto-line la)
                       (delete-region (point)
                                      (progn (forward-line (1+ (- lb la)))
                                             (point)))
                       (while (<= ra rb)
                         (insert change-string)
                         (incf ra)))))))
      (goto-char (point-min))
      (loop while (re-search-forward "[1-9][0-9]*" nil t)
            collect (string-to-number (match-string 0))))))

(defun p4-annotate-internal (filespec &optional src-line)
  ;; make sure the filespec is unambiguous
  (p4-with-temp-buffer (list "files" filespec)
    (when (> (count-lines (point-min) (point-max)) 1)
      (error "File pattern maps to more than one file.")))
  (let ((buf (p4-process-buffer-name (list "annotate" filespec))))
    (unless (get-buffer buf)
      (let ((file-change-alist (p4-parse-filelog filespec)))
        (unless file-change-alist (error "%s not available" filespec))
        (with-current-buffer (p4-make-output-buffer buf)
          (let* ((line-changes
                  (if (< (p4-server-version) 2004)
                      (p4-annotate-changes-by-patching filespec file-change-alist)
                    (p4-annotate-changes filespec)))
                 (lines (length line-changes))
                 (inhibit-read-only t)
                 (inhibit-modification-hooks t)
                 (current-line 0)
                 (current-repeats 0)
                 (current-percent -1)
                 current-change)
            (p4-run (list "print" filespec))
            (p4-fontify-print-buffer)
            (forward-line 1)
            (dolist (change line-changes)
              (incf current-line)
              (let ((percent (/ (* current-line 100) lines)))
                (when (> percent current-percent)
                  (message "Formatting...%d%%" percent)
                  (incf current-percent 10)))
              (if (eql change current-change)
                  (incf current-repeats)
                (setq current-repeats 0))
              (let ((rev (cdr (assoc change file-change-alist))))
                (case current-repeats
                  (0 (insert (p4-file-revision-annotate-links rev)))
                  (1 (insert (p4-file-revision-annotate-desc rev)))
                  (t (insert (format "%33s: " "")))))
              (setq current-change change)
              (forward-line))
            (goto-char (point-min))
            (p4-mark-print-buffer)
            (message "Formatting...done")
            (setq truncate-lines t)
            (use-local-map p4-annotate-mode-map)))))
    (with-selected-window (display-buffer buf)
      (when src-line
        (p4-goto-line (+ 1 src-line))))))


;;; Completion:

(defstruct p4-completion
  cache                ; association list mapping query to list of results.
  cache-exact          ; cache lookups must be exact (not prefix matches).
  history              ; symbol naming the history variable.
  query-cmd            ; p4 command to fetch completions from depot.
  query-arg            ; p4 command argument to put before the query string.
  query-prefix         ; string to prepend to the query string.
  regexp               ; regular expression matching results in p4 output.
  group                ; group in regexp containing the completion (default 1).
  annotation           ; group in regexp containing the annotation.
  fetch-completions-fn ; function to fetch completions from the depot.
  completion-fn        ; function to do the completion.
  arg-completion-fn)   ; function to do completion in arg list context.

(defun p4-output-matches (args regexp &optional group)
  "Run p4 ARGS and return a list of matches for REGEXP in the output.
With optional argument GROUP, return that group from each match."
  (p4-with-temp-buffer args
    (let (result)
      (while (re-search-forward regexp nil t)
        (push (match-string (or group 0)) result))
      (nreverse result))))

;; Completions are generated as needed in completing-read, but there's
;; no way for the completion function to return the annotations as
;; well as completions. We don't want to query the depot for each
;; annotation (that would be disastrous for performance). So the only
;; way annotations can work at all efficiently is for the function
;; that gets the list of completions (p4-complete) to also update this
;; global variable (either by calling p4-output-annotations, or by
;; getting the annotation table out of the cache).

(defvar p4-completion-annotations nil
  "Hash table mapping completion to its annotation (for the most
recently generated set of completions), or NIL if there are no
annotations.")

(defun p4-completion-annotate (key)
  "Return the completion annotation corresponding to KEY, or NIL if none."
  (when p4-completion-annotations
    (let ((annotation (gethash key p4-completion-annotations)))
      (when annotation (concat " " annotation)))))

(defun p4-output-annotations (args regexp group annotation)
  "As p4-output-matches, but additionally update
p4-completion-annotations so that it maps the matches for GROUP
to the matches for ANNOTATION."
  (p4-with-temp-buffer args
    (let (result (ht (make-hash-table :test #'equal)))
      (while (re-search-forward regexp nil t)
        (let ((key (match-string group)))
          (push key result)
          (puthash key (match-string annotation) ht)))
      (setq p4-completion-annotations ht)
      (nreverse result))))

(defun p4-completing-read (completion-type prompt &optional initial-input)
  "Wrapper around completing-read."
  (let ((completion (p4-get-completion completion-type))
        (completion-extra-properties
         '(:annotation-function p4-completion-annotate)))
    (completing-read prompt
                     (p4-completion-arg-completion-fn completion)
                     nil nil initial-input
                     (p4-completion-history completion))))

(defun p4-fetch-change-completions (completion string status)
  "Fetch change completions (with status STATUS) for STRING from
the depot."
  (let ((client (p4-current-client)))
    (when client
      (cons "default"
            (p4-output-annotations `("changes" "-s" ,status "-c" ,client)
                                   "^Change \\([1-9][0-9]*\\) .*'\\(.*\\)'"
                                   1 2)))))

(defun p4-fetch-pending-completions (completion string)
  "Fetch pending change completions for STRING from the depot."
  (p4-fetch-change-completions completion string "pending"))

(defun p4-fetch-shelved-completions (completion string)
  "Fetch shelved change completions for STRING from the depot."
  (p4-fetch-change-completions completion string "shelved"))

(defun p4-fetch-filespec-completions (completion string)
  "Fetch file and directory completions for STRING from the depot."
  (append (loop for dir in (p4-output-matches (list "dirs" (concat string "*"))
                                              "^//[^ \n]+$")
                collect (concat dir "/"))
          (p4-output-matches (list "files" (concat string "*"))
                             "^\\(//[^#\n]+\\)#[1-9][0-9]* - " 1)))

(defun p4-fetch-help-completions (completion string)
  "Fetch help completions for STRING from the depot."
  (append (p4-output-matches '("help") "^\tp4 help \\([^ \n]+\\)" 1)
          (p4-output-matches '("help" "commands") "^\t\\([^ \n]+\\)" 1)
          (p4-output-matches '("help" "administration") "^\t\\([^ \n]+\\)" 1)
          '("undoc")
          (p4-output-matches '("help" "undoc")
                             "^    p4 \\(?:help \\)?\\([a-z0-9]+\\)" 1)))

(defun p4-fetch-completions (completion string)
  "Fetch possible completions for STRING from the depot and
return them as a list. Also, update the p4-completion-annotations
hash table."
  (let* ((cmd (p4-completion-query-cmd completion))
         (arg (p4-completion-query-arg completion))
         (prefix (p4-completion-query-prefix completion))
         (regexp (p4-completion-regexp completion))
         (group (or (p4-completion-group completion) 1))
         (annotation (p4-completion-annotation completion))
         (have-string (> (length string) 0))
         (args (append (if (listp cmd) cmd (list cmd))
                       (and arg have-string (list arg))
                       (and (or arg prefix) have-string
                            (list (concat prefix string "*"))))))
    (if annotation
        (p4-output-annotations args regexp group annotation)
      (p4-output-matches args regexp group))))

(defun p4-purge-completion-cache (completion)
  "Remove stale entries from the cache for COMPLETION."
  (let ((stale (time-subtract (current-time)
                              (seconds-to-time p4-cleanup-time))))
    (setf (p4-completion-cache completion)
          (loop for c in (p4-completion-cache completion)
                when (time-less-p stale (second c))
                collect c))))

(defun p4-complete (completion string)
  "Return list of items of type COMPLETION that are possible
completions for STRING, and update the annotations hash table.
Use the cache if available, otherwise fetch them from the depot
and update the cache accordingly."
  (p4-purge-completion-cache completion)
  (let* ((cache (p4-completion-cache completion))
         (cached (assoc string cache)))
    ;; Exact cache hit?
    (if cached
        (progn
          (setq p4-completion-annotations (fourth cached))
          (third cached))
      ;; Any hit on a prefix (unless :cache-exact)
      (or (and (not (p4-completion-cache-exact completion))
               (loop for (query timestamp results annotations) in cache
                     for best-results = nil
                     for best-length = -1
                     for l = (length query)
                     when (and (> l best-length) (p4-startswith string query))
                     do (setq best-length l best-results results)
                     finally return best-results))
          ;; Fetch from depot and update cache.
          (let* ((fetch-fn (or (p4-completion-fetch-completions-fn completion)
                               'p4-fetch-completions))
                 (results (funcall fetch-fn completion string))
                 (timestamp (current-time)))
            (push (list string timestamp results p4-completion-annotations)
                  (p4-completion-cache completion))
            results)))))

(defun p4-completion-builder (completion)
  (lexical-let ((completion completion))
    (completion-table-dynamic
     (lambda (string) (p4-complete completion string)))))

(defun p4-arg-completion-builder (completion)
  (lexical-let ((completion completion))
    (lambda (string predicate action)
      (string-match "^\\(\\(?:.* \\)?\\)\\([^ \t\n]*\\)$" string)
      (let* ((first (match-string 1 string))
             (remainder (match-string 2 string))
             (f (p4-completion-completion-fn completion))
             (completions (unless (string-match "^-" remainder)
                            (funcall f remainder predicate action))))
       (if (and (null action)             ; try-completion
                (stringp completions))
           (concat first completions)
         completions)))))

(defun p4-make-completion (&rest args)
  (let* ((c (apply 'make-p4-completion args)))
    (setf (p4-completion-completion-fn c) (p4-completion-builder c))
    (setf (p4-completion-arg-completion-fn c) (p4-arg-completion-builder c))
    c))

(defvar p4-arg-string-history nil "P4 command-line argument history.")
(defvar p4-branch-history nil "P4 branch history.")
(defvar p4-client-history nil "P4 client history.")
(defvar p4-filespec-history nil "P4 filespec history.")
(defvar p4-group-history nil "P4 group history.")
(defvar p4-help-history nil "P4 help history.")
(defvar p4-job-history nil "P4 job history.")
(defvar p4-label-history nil "P4 label history.")
(defvar p4-pending-history nil "P4 pending change history.")
(defvar p4-shelved-history nil "P4 shelved change history.")
(defvar p4-user-history nil "P4 user history.")

(defvar p4-all-completions
  (list
   (cons 'branch   (p4-make-completion
                    :query-cmd "branches" :query-arg "-E"
                    :regexp "^Branch \\([^ \n]*\\) [0-9]+/"
                    :history 'p4-branch-history))
   (cons 'client   (p4-make-completion
                    :query-cmd "clients" :query-arg "-E"
                    :regexp "^Client \\([^ \n]*\\) [0-9]+/"
                    :history 'p4-client-history))
   (cons 'filespec (p4-make-completion
                    :cache-exact t
                    :fetch-completions-fn 'p4-fetch-filespec-completions
                    :history 'p4-filespec-history))
   (cons 'group    (p4-make-completion
                    :query-cmd "groups"
                    :regexp "^\\([^ \n]+\\)"
                    :history 'p4-group-history))
   (cons 'help     (p4-make-completion
                    :fetch-completions-fn 'p4-fetch-help-completions
                    :history 'p4-help-history))
   (cons 'job      (p4-make-completion
                    :query-cmd "jobs" :query-arg "-e" :query-prefix "job="
                    :regexp "\\([^ \n]*\\) on [0-9]+/.*\\* '\\(.*\\)'"
                    :annotation 2
                    :history 'p4-job-history))
   (cons 'label    (p4-make-completion
                    :query-cmd "labels" :query-arg "-E"
                    :regexp "^Label \\([^ \n]*\\) [0-9]+/"
                    :history 'p4-label-history))
   (cons 'pending  (p4-make-completion
                    :fetch-completions-fn 'p4-fetch-pending-completions
                    :history 'p4-pending-history))
   (cons 'shelved  (p4-make-completion
                    :fetch-completions-fn 'p4-fetch-shelved-completions
                    :history 'p4-shelved-history))
   (cons 'user     (p4-make-completion
                    :query-cmd "users" :query-prefix ""
                    :regexp "^\\([^ \n]+\\)"
                    :history 'p4-user-history))))

(defun p4-get-completion (completion-type &optional noerror)
  "Return the `p4-completion' structure for COMPLETION-TYPE.
If there is no such completion type, report the error if NOERROR
is NIL, otherwise return NIL."
  (let ((res (assq completion-type p4-all-completions)))
    (when (not (or noerror res))
      (error "Unsupported completion type %s" completion-type))
    (cdr res)))

(defun p4-cache-cleanup ()
  "Empty all the completion caches."
  (loop for (type . completion) in p4-all-completions
        do (setf (p4-completion-cache completion) nil)))

(defun p4-partial-cache-cleanup (completion-type)
  "Cleanup a specific completion cache."
  (let ((completion (p4-get-completion completion-type 'noerror)))
    (when completion (setf (p4-completion-cache completion) nil))))

(defun p4-read-arg-string (prompt &optional initial-input completion-type)
  (let* ((minibuffer-local-completion-map
          (copy-keymap minibuffer-local-completion-map)))
    (define-key minibuffer-local-completion-map " " 'self-insert-command)
    (if completion-type
        (p4-completing-read completion-type prompt initial-input)
      (completing-read prompt #'p4-arg-string-completion nil nil
                       initial-input 'p4-arg-string-history))))

(defun p4-read-args (prompt &optional initial-input completion-type)
  (p4-make-list-from-string
   (p4-read-arg-string prompt initial-input completion-type)))

(defun p4-read-args* (prompt &optional initial-input completion-type)
  (p4-make-list-from-string
   (if current-prefix-arg
       (p4-read-arg-string prompt initial-input completion-type)
     initial-input)))

(defun p4-arg-complete (completion-type &rest args)
  (let ((completion (p4-get-completion completion-type)))
    (apply (p4-completion-arg-completion-fn completion) args)))

(defun p4-arg-string-completion (string predicate action)
  (let ((first-part "") completion)
    (if (string-match "^\\(.* +\\)\\(.*\\)" string)
        (progn
          (setq first-part (match-string 1 string))
          (setq string (match-string 2 string))))
    (cond ((string-match "-b +$" first-part)
           (setq completion (p4-arg-complete 'branch string predicate action)))
          ((string-match "-t +$" first-part)
           (setq completion (p4-list-completion
                             string (list "text " "xtext " "binary "
                                          "xbinary " "symlink ")
                             predicate action)))
          ((string-match "-j +$" first-part)
           (setq completion (p4-arg-complete 'job string predicate action)))
          ((string-match "-l +$" first-part)
           (setq completion (p4-arg-complete 'label string predicate action)))
          ((string-match "\\(.*status=\\)\\(.*\\)" string)
           (setq first-part (concat first-part (match-string 1 string)))
           (setq string (match-string 2 string))
           (setq completion (p4-list-completion
                             string (list "open " "closed " "suspended ")
                             predicate action)))
          ((or (string-match "\\(.*@.+,\\)\\(.*\\)" string)
               (string-match "\\(.*@\\)\\(.*\\)" string))
           (setq first-part (concat first-part (match-string 1 string)))
           (setq string (match-string 2 string))
           (setq completion (p4-arg-complete 'label string predicate action)))
          ((string-match "\\(.*#\\)\\(.*\\)" string)
           (setq first-part (concat first-part (match-string 1 string)))
           (setq string (match-string 2 string))
           (setq completion (p4-list-completion
                             string (list "none" "head" "have")
                             predicate action)))
          ((string-match "^//" string)
           (setq completion (p4-arg-complete 'filespec string predicate action)))
          ((string-match "\\(^-\\)\\(.*\\)" string)
           (setq first-part (concat first-part (match-string 1 string)))
           (setq string (match-string 2 string))
           (setq completion (p4-list-completion
                             string (list "a " "af " "am " "as " "at " "ay "
                                          "b " "c " "d " "dc " "dn "
                                          "ds " "du " "e " "f " "i " "j "
                                          "l " "m " "n " "q " "r " "s " "sa "
                                          "sd " "se " "sr " "t " "v ")
                             predicate action)))
          (t
           (setq completion (p4-file-name-completion string predicate action))))
    (if (and (null action)              ; try-completion
             (stringp completion))
        (concat first-part completion)
      completion)))

(defun p4-list-completion (string lst predicate action)
  (let ((collection (mapcar 'list lst)))
    (cond ((not action)
           (try-completion string collection predicate))
          ((eq action t)
           (all-completions string collection predicate))
          (t
           (eq (try-completion string collection predicate) t)))))

(defun p4-file-name-completion (string predicate action)
  (if (string-match "//\\(.*\\)" string)
      (setq string (concat "/" (match-string 1 string))))
  (setq string (substitute-in-file-name string))
  (setq string (p4-follow-link-name (expand-file-name string)))
  (let ((dir-path "") completion)
    (if (string-match "^\\(.*[/\\]\\)\\(.*\\)" string)
        (progn
          (setq dir-path (match-string 1 string))
          (setq string (match-string 2 string))))
    (cond ((not action)
           (setq completion (file-name-completion string dir-path))
           (if (stringp completion)
               (concat dir-path completion)
             completion))
          ((eq action t)
           (file-name-all-completions string dir-path))
          (t
           (eq (file-name-completion string dir-path) t)))))


;;; Basic mode:

;; Major mode used for most P4 output buffers, and as the parent mode
;; for specialized modes below.

(defvar p4-basic-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (if (featurep 'xemacs) [button1] [mouse-1]) 'p4-buffer-mouse-clicked)
    (define-key map "\t" 'p4-forward-active-link)
    (define-key map "\e\t" 'p4-backward-active-link)
    (define-key map [(shift tab)] 'p4-backward-active-link)
    (define-key map "\C-m" 'p4-buffer-commands)
    (define-key map "q" 'quit-window)
    (define-key map "g" 'revert-buffer)
    (define-key map "k" 'p4-scroll-down-1-line)
    (define-key map "j" 'p4-scroll-up-1-line)
    (define-key map "b" 'p4-scroll-down-1-window)
    (define-key map "n" 'next-line)
    (define-key map "p" 'previous-line)
    (define-key map [backspace] 'p4-scroll-down-1-window)
    (define-key map " " 'p4-scroll-up-1-window)
    (define-key map "<" 'p4-top-of-buffer)
    (define-key map ">" 'p4-bottom-of-buffer)
    (define-key map "=" 'delete-other-windows)
    map))

(define-derived-mode p4-basic-mode nil "P4 Basic")

(defun p4-buffer-mouse-clicked (event)
  "Call `p4-buffer-commands' at the point clicked on with the mouse."
  (interactive "e")
  (select-window (if (featurep 'xemacs) (event-window event)
                   (posn-window (event-end event))))
  (goto-char (if (featurep 'xemacs) (event-point event)
               (posn-point (event-start event))))
  (when (get-text-property (point) 'active)
    (p4-buffer-commands (point))))

(defun p4-buffer-commands (pnt &optional arg)
  "Function to get a given property and do the appropriate command on it"
  (interactive "d\nP")
  (let ((action (get-char-property pnt 'action))
        (active (get-char-property pnt 'active))
        (branch (get-char-property pnt 'branch))
        (change (get-char-property pnt 'change))
        (client (get-char-property pnt 'client))
        (filename (p4-context-single-filename))
        (group (get-char-property pnt 'group))
        (help (get-char-property pnt 'help))
        (job (get-char-property pnt 'job))
        (label (get-char-property pnt 'label))
        (pending (get-char-property pnt 'pending))
        (user (get-char-property pnt 'user))
        (rev (get-char-property pnt 'rev)))
    (cond ((and (not action) rev)
           (p4-call-command "print" (list (format "%s#%d" filename rev))
                            :callback 'p4-activate-print-buffer))
          (action
           (when (<= rev 1)
             (error "There is no earlier revision to diff."))
           (apply #'p4-diff2
            (append (p4-make-list-from-string p4-default-diff-options)
                    (mapcar 'p4-get-file-rev (list (1- rev) rev)))))
          (change (apply #'p4-describe
                   (append (p4-make-list-from-string p4-default-diff-options)
                           (list (format "%d" change)))))
          (pending (p4-change pending))
          (user (p4-user user))
          (group (p4-group group))
          (client (p4-client client))
          (label (p4-label (list label)))
          (branch (p4-branch (list branch)))
          (job (p4-job job))
          (help (p4-help help))
          ((and (not active) (eq major-mode 'p4-diff-mode))
           (p4-diff-goto-source arg))

          ;; Check if a "filename link" or an active "diff buffer area" was
          ;; selected.
          (t
           (let ((link-client-name (get-char-property pnt 'link-client-name))
                 (link-depot-name (get-char-property pnt 'link-depot-name))
                 (block-client-name (get-char-property pnt 'block-client-name))
                 (block-depot-name (get-char-property pnt 'block-depot-name))
                 (history-for (get-char-property pnt 'history-for))
                 (first-line (get-char-property pnt 'first-line))
                 (start (get-char-property pnt 'start)))
             (cond
              (history-for
               (p4-file-change-log "filelog" (list history-for)))
              ((or link-client-name link-depot-name)
               (p4-find-file-or-print-other-window
                link-client-name link-depot-name))
              ((or block-client-name block-depot-name)
               (if first-line
                   (let ((c (max 0 (- pnt
                                      (save-excursion
                                        (goto-char pnt)
                                        (beginning-of-line)
                                        (point))
                                      1)))
                         (r first-line))
                     (save-excursion
                       (goto-char start)
                       (while (re-search-forward "^[ +>].*\n" pnt t)
                         (setq r (1+ r))))
                     (p4-find-file-or-print-other-window
                      block-client-name block-depot-name)
                     (p4-goto-line r)
                     (if (not block-client-name)
                         (forward-line 1))
                     (beginning-of-line)
                     (goto-char (+ (point) c)))
                 (p4-find-file-or-print-other-window
                  block-client-name block-depot-name)))))))))

(defun p4-forward-active-link ()
  (interactive)
  (while (and (not (eobp))
              (goto-char (next-overlay-change (point)))
              (not (get-char-property (point) 'face)))))

(defun p4-backward-active-link ()
  (interactive)
  (while (and (not (bobp))
              (goto-char (previous-overlay-change (point)))
              (not (get-char-property (point) 'face)))))

(defun p4-scroll-down-1-line ()
  "Scroll down one line"
  (interactive)
  (scroll-down 1))

(defun p4-scroll-up-1-line ()
  "Scroll up one line"
  (interactive)
  (scroll-up 1))

(defun p4-scroll-down-1-window ()
  "Scroll down one window"
  (interactive)
  (scroll-down
   (- (window-height) next-screen-context-lines)))

(defun p4-scroll-up-1-window ()
  "Scroll up one window"
  (interactive)
  (scroll-up
   (- (window-height) next-screen-context-lines)))

(defun p4-top-of-buffer ()
  "Top of buffer"
  (interactive)
  (goto-char (point-min)))

(defun p4-bottom-of-buffer ()
  "Bottom of buffer"
  (interactive)
  (goto-char (point-max)))


;;; Basic List Mode:

;; This is for the output of files, sync, have, integ, labelsync, and
;; reconcile, which consists of a list of lines starting with a depot
;; filespec.

(defvar p4-basic-list-mode-map
  (let ((map (p4-make-derived-map p4-basic-mode-map)))
    (define-key map "\C-m" 'p4-basic-list-activate)
    map)
  "The keymap to use in P4 Basic List Mode.")

(defvar p4-basic-list-font-lock-keywords
  '(("^\\(//.*#[1-9][0-9]*\\) - \\(?:\\(?:unshelved, \\)?opened for \\)?\\(?:move/\\)?add" 1 'p4-depot-add-face)
    ("^\\(//.*#[1-9][0-9]*\\) - \\(?:\\(?:unshelved, \\)?opened for \\)?\\(?:branch\\|integrate\\)" 1 'p4-depot-branch-face)
    ("^\\(//.*#[1-9][0-9]*\\) - \\(?:\\(?:unshelved, \\)?opened for \\)?\\(?:move/\\)?delete" 1 'p4-depot-delete-face)
    ("^\\(//.*#[1-9][0-9]*\\) - \\(?:\\(?:unshelved, \\)?opened for \\)?\\(?:edit\\|updating\\)" 1 'p4-depot-edit-face)))

(define-derived-mode p4-basic-list-mode p4-basic-mode "P4 Basic List"
  (setq font-lock-defaults '(p4-basic-list-font-lock-keywords t)))

(defvar p4-basic-list-filename-regexp
  "^\\(\\(//.*\\)#[1-9][0-9]*\\) - \\(\\(?:move/\\)?add\\)?")

(defun p4-basic-list-get-filename ()
  (save-excursion
    (beginning-of-line)
    (when (looking-at p4-basic-list-filename-regexp)
      (match-string (if (eq major-mode 'p4-opened-list-mode) 2 1)))))

(defun p4-basic-list-activate ()
  (interactive)
  (if (get-char-property (point) 'active)
      (p4-buffer-commands (point))
    (save-excursion
      (beginning-of-line)
      (when (looking-at p4-basic-list-filename-regexp)
        (if (match-string 3)
            (let ((args (list "where" (match-string 2))))
              (p4-with-temp-buffer args
                (when (looking-at "//[^ \n]+ //[^ \n]+ \\(.*\\)")
                  (find-file (match-string 1)))))
          (p4-depot-find-file (match-string 1)))))))


;;; Opened list mode:

;; This is for the output of p4 opened, where each line starts with
;; the depot filename for an opened file.

(defvar p4-opened-list-mode-map
  (let ((map (p4-make-derived-map p4-basic-list-mode-map)))
    (define-key map "r" 'p4-revert)
    (define-key map "t" 'p4-opened-list-type)
    (define-key map "c" 'p4-opened-list-change)
    map)
  "The key map to use in P4 Status List Mode.")

(defvar p4-opened-list-font-lock-keywords
  (append p4-basic-list-font-lock-keywords
          '(("\\<change \\([1-9][0-9]*\\) ([a-z]+)" 1 'p4-change-face))))

(define-derived-mode p4-opened-list-mode p4-basic-list-mode "P4 Opened List"
  (setq font-lock-defaults '(p4-opened-list-font-lock-keywords t)))

(defun p4-opened-list-type (type)
  (interactive "sNew filetype: ")
  (save-excursion
    (beginning-of-line)
    (when (looking-at p4-basic-list-filename-regexp)
      (p4-reopen (list "-t" type (match-string 2))))))

(defun p4-opened-list-change (change)
  (interactive 
   (list (p4-completing-read 'pending "New change: ")))
  (save-excursion
    (beginning-of-line)
    (when (looking-at p4-basic-list-filename-regexp)
      (p4-reopen (list "-c" change (match-string 2))))))


;;; Status List Mode:

;; This is for the output of p4 status, where each line starts with a
;; client filename.

(defvar p4-status-list-mode-map
  (let ((map (p4-make-derived-map p4-basic-list-mode-map)))
    (define-key map "\C-m" 'p4-status-list-activate)
    map)
  "The key map to use in P4 Status List Mode.")

(defvar p4-status-list-font-lock-keywords
  '(("^\\(.*\\) - reconcile to add" 1 'p4-depot-add-face)
    ("^\\(.*\\) - reconcile to delete" 1 'p4-depot-delete-face)
    ("^\\(.*\\) - reconcile to edit" 1 'p4-depot-edit-face)))

(define-derived-mode p4-status-list-mode p4-basic-list-mode "P4 Status List"
  (setq font-lock-defaults '(p4-status-list-font-lock-keywords t)))

(defun p4-status-list-activate ()
  (interactive)
  (save-excursion
    (beginning-of-line)
    (when (looking-at "^\\(.*\\) - reconcile to ")
      (find-file-other-window (match-string 1)))))


;;; Form mode:

(defvar p4-form-font-lock-keywords
  '(("^#.*$" . 'p4-form-comment-face)
    ("^[^ \t\n:]+:" . 'p4-form-keyword-face)))

(defvar p4-form-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-x\C-s" 'p4-form-commit)
    (define-key map "\C-c\C-c" 'p4-form-commit)
    map)
  "Keymap for P4 form mode.")

(define-derived-mode p4-form-mode indented-text-mode "P4 Form"
  "Major mode for P4 forms."
  (setq fill-column 80
        indent-tabs-mode t
        font-lock-defaults '(p4-form-font-lock-keywords t)))


;;; Change form mode::

(defvar p4-change-form-mode-map
  (let ((map (p4-make-derived-map p4-form-mode-map)))
    (define-key map "\C-c\C-s" 'p4-change-form-submit)
    (define-key map "\C-c\C-p" 'p4-change-form-update)
    (define-key map "\C-c\C-d" 'p4-change-form-delete)
    map)
  "Keymap for P4 change form mode.")

(define-derived-mode p4-change-form-mode p4-form-mode "P4 Change")

(defun p4-change-form-delete ()
  "Delete the change in the current buffer."
  (interactive)
  (let ((change (p4-form-value "Change")))
    (when (and change (not (string= change "new"))
               (yes-or-no-p "Really delete this change? "))
      (p4-change "-d" change)
      (p4-partial-cache-cleanup 'pending)
      (p4-partial-cache-cleanup 'shelved))))

(defun p4-change-form-submit ()
  "Submit the change in the current buffer to the server."
  (interactive)
  (let ((p4-form-commit-command "submit"))
    (p4-form-commit)))

(defun p4-change-form-update ()
  "Update the changelist description on the server."
  (interactive)
  (let ((p4-form-commit-command "change"))
    (p4-form-commit)))


;;; Job form mode::

(defvar p4-job-form-mode-map
  (let ((map (p4-make-derived-map p4-form-mode-map)))
    (define-key map "\C-c\C-f" 'p4-job-form-fixes)
    map)
  "Keymap for P4 job form mode.")

(define-derived-mode p4-job-form-mode p4-form-mode "P4 Job")

(defun p4-job-form-fixes ()
  "Show the fixes for this job."
  (interactive)
  (let ((job (p4-form-value "Job")))
    (when (and job (not (string= job "new")))
      (p4-fixes (list "-j" job)))))


;;; Filelog mode:

(defvar p4-filelog-mode-map
  (let ((map (p4-make-derived-map p4-basic-mode-map)))
    (define-key map "d" 'p4-diff2)
    (define-key map "f" 'p4-find-file-other-window)
    (define-key map "s" 'p4-filelog-short-format)
    (define-key map "l" 'p4-filelog-long-format)
    (define-key map "k" 'p4-scroll-down-1-line-other-w)
    (define-key map "j" 'p4-scroll-up-1-line-other-w)
    (define-key map "b" 'p4-scroll-down-1-window-other-w)
    (define-key map [backspace] 'p4-scroll-down-1-window-other-w)
    (define-key map " " 'p4-scroll-up-1-window-other-w)
    (define-key map "<" 'p4-top-of-buffer-other-w)
    (define-key map ">" 'p4-bottom-of-buffer-other-w)
    (define-key map "=" 'p4-delete-other-windows)
    (define-key map "n" 'p4-goto-next-change)
    (define-key map "p" 'p4-goto-prev-change)
    (define-key map "N" (lookup-key map "p"))
    map)
  "The key map to use for selecting filelog properties.")

(defvar p4-filelog-font-lock-keywords
  '(("^//.*" . 'p4-filespec-face)
    ("\\(?:^\\.\\.\\. #\\([1-9][0-9]*\\) \\)?[Cc]hange \\([1-9][0-9]*\\)\\(?: \\([a-z]+\\)\\)? on [0-9]+/[0-9]+/[0-9]+ by \\(\\S-+\\)@\\(\\S-+\\).*"
     (1 'p4-revision-face nil t) (2 'p4-change-face) (3 'p4-action-face nil t)
     (4 'p4-user-face) (5 'p4-client-face))
    ("^\\.\\.\\. \\.\\.\\. [^/\n]+ \\(//[^#\n]+\\).*" (1 'p4-filespec-face))
    ("^\t.*" . 'p4-description-face)))

(define-derived-mode p4-filelog-mode p4-basic-mode "P4 File Log"
  (setq font-lock-defaults '(p4-filelog-font-lock-keywords t)))

(defun p4-find-file-other-window ()
  "Open/print file"
  (interactive)
  (let ((link-client-name (get-char-property (point) 'link-client-name))
        (link-depot-name (get-char-property (point) 'link-depot-name))
        (block-client-name (get-char-property (point) 'block-client-name))
        (block-depot-name (get-char-property (point) 'block-depot-name)))
    (cond ((or link-client-name link-depot-name)
           (p4-find-file-or-print-other-window
            link-client-name link-depot-name)
           (other-window 1))
          ((or block-client-name block-depot-name)
           (p4-find-file-or-print-other-window
            block-client-name block-depot-name)
           (other-window 1)))))

(defun p4-filelog-short-format ()
  "Short format"
  (interactive)
  (setq buffer-invisibility-spec t)
  (redraw-display))

(defun p4-filelog-long-format ()
  "Long format"
  (interactive)
  (setq buffer-invisibility-spec (list))
  (redraw-display))

(defun p4-scroll-down-1-line-other-w ()
  "Scroll other window down one line"
  (interactive)
  (scroll-other-window -1))

(defun p4-scroll-up-1-line-other-w ()
  "Scroll other window up one line"
  (interactive)
  (scroll-other-window 1))

(defun p4-scroll-down-1-window-other-w ()
  "Scroll other window down one window"
  (interactive)
  (scroll-other-window
   (- next-screen-context-lines (window-height))))

(defun p4-scroll-up-1-window-other-w ()
  "Scroll other window up one window"
  (interactive)
  (scroll-other-window
   (- (window-height) next-screen-context-lines)))

(defun p4-top-of-buffer-other-w ()
  "Top of buffer, other window"
  (interactive)
  (other-window 1)
  (goto-char (point-min))
  (other-window -1))

(defun p4-bottom-of-buffer-other-w ()
  "Bottom of buffer, other window"
  (interactive)
  (other-window 1)
  (goto-char (point-max))
  (other-window -1))

(defun p4-goto-next-change ()
  "Next change"
  (interactive)
  (let ((c (current-column)))
    (forward-line 1)
    (while (get-char-property (point) 'invisible)
      (forward-line 1))
    (move-to-column c)))

(defun p4-goto-prev-change ()
  "Previous change"
  (interactive)
  (let ((c (current-column)))
    (forward-line -1)
    (while (get-char-property (point) 'invisible)
      (forward-line -1))
    (move-to-column c)))


;;; Diff mode:

(defvar p4-diff-mode-map
  (let ((map (p4-make-derived-map p4-basic-mode-map)))
    (define-key map "n" 'diff-hunk-next)
    (define-key map "N" 'diff-file-next)
    (define-key map "p" 'diff-hunk-prev)
    (define-key map "P" 'diff-file-prev)
    (define-key map "\t" 'diff-hunk-next)
    (define-key map [backtab] 'diff-hunk-prev)
    (define-key map "}" 'diff-file-next)
    (define-key map "{" 'diff-file-prev)
    (define-key map "\C-m" 'p4-buffer-commands)
    (define-key map [mouse-2] 'p4-buffer-commands)
    (define-key map "o" 'p4-buffer-commands)
    map))

(defvar p4-diff-font-lock-keywords
  '(("^Change \\([1-9][0-9]*\\) by \\(\\S-+\\)@\\(\\S-+\\) on [0-9]+/.*"
     (1 'p4-change-face) (2 'p4-user-face) (3 'p4-client-face))
    ("^\\(\\S-+\\) on [0-9]+/[0-9]+/[0-9]+ by \\(\\S-+\\).*"
     (1 'p4-job-face) (2 'p4-user-face))
    ("^\t.*" . 'p4-description-face)
    ("^[A-Z].* \\.\\.\\." . 'p4-heading-face)
    ("^\\.\\.\\. \\(//[^# \t\n]+\\).*" (1 'p4-filespec-face))
    ("^==== .* ====" . 'diff-file-header)))

(define-derived-mode p4-diff-mode p4-basic-mode "P4 Diff"
  (diff-minor-mode 1)
  (use-local-map p4-diff-mode-map)
  (set (make-local-variable 'diff-file-header-re)
       (concat "^==== .* ====\\|" diff-file-header-re))
  (setq font-lock-defaults diff-font-lock-defaults)
  (font-lock-add-keywords nil p4-diff-font-lock-keywords))

(defun p4-diff-find-file-name (&optional reverse)
  "Return the filespec where this diff location can be found.
Return the new filespec, or the old filespec if optional argument
REVERSE is non-NIL."
  (save-excursion
    (unless (looking-at diff-file-header-re)
      (or (ignore-errors (diff-beginning-of-file))
          (re-search-forward diff-file-header-re nil t)))
    (cond ((looking-at "^==== \\(//[^#\n]+#[1-9][0-9]*\\).* - \\(//[^#\n]+#[1-9][0-9]*\\).* ====")
           ;; In the output of p4 diff and diff2 both the old and new
           ;; revisions are given.
           (match-string-no-properties (if reverse 1 2)))
          ((looking-at "^==== \\(//[^@#\n]+\\)#\\([1-9][0-9]*\\).* ====")
           ;; The output of p4 describe contains just the new
           ;; revision number: the old revision number is one less.
           (let ((revision (string-to-number (match-string 2))))
             (format "%s#%d" (match-string-no-properties 1)
                     (max 1 (if reverse (1- revision) revision)))))
          ((looking-at "^--- \\(//[^\t\n]+\\)\t\\([1-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\\)[.0-9]* \\([+-]?\\)\\([0-9][0-9][0-9][0-9]\\).*\n\\+\\+\\+ \\([^\t\n]+\\)\t")
           (if reverse
               (let ((time (date-to-time (format "%s %s%s" (match-string 2)
                                                 ;; Time zone sense seems to be backwards!
                                                 (if (string-equal (match-string 3) "-") "+" "-")
                                                 (match-string 4)))))
                 (format "%s@%s" (match-string-no-properties 1)
                         (format-time-string "%Y/%m/%d:%H:%M:%S" time t)))
             (match-string-no-properties 5)))
          (t
           (error "Can't find filespec(s) in diff file header.")))))

;; This is modelled on diff-find-source-location in diff-mode.el.
(defun p4-diff-find-source-location (&optional reverse)
  "Return (FILESPEC LINE OFFSET) for the corresponding source location.
FILESPEC is the new file, or the old file if optional argument
REVERSE is non-NIL. The location in the file can be found by
going to line number LINE and then moving forward OFFSET
characters."
  (save-excursion
    (let* ((char-offset (- (point) (diff-beginning-of-hunk t)))
           (_ (diff-sanity-check-hunk))
           (hunk (buffer-substring
                  (point) (save-excursion (diff-end-of-hunk) (point))))
           (old (diff-hunk-text hunk nil char-offset))
           (new (diff-hunk-text hunk t char-offset))
           ;; Find the location specification.
           (line (if (not (looking-at "\\(?:\\*\\{15\\}.*\n\\)?[-@* ]*\\([0-9,]+\\)\\([ acd+]+\\([0-9,]+\\)\\)?"))
                     (error "Can't find the hunk header")
                   (if reverse (match-string 1)
                     (if (match-end 3) (match-string 3)
                       (unless (re-search-forward
                                diff-context-mid-hunk-header-re nil t)
                         (error "Can't find the hunk separator"))
                       (match-string 1)))))
           (file (or (p4-diff-find-file-name reverse)
                     (error "Can't find the file"))))
      (list file (string-to-number line) (cdr (if reverse old new))))))

;; Based on diff-goto-source in diff-mode.el.
(defun p4-diff-goto-source (&optional other-file event)
  "Jump to the corresponding source line.
The old file is visited for removed lines, otherwise the new
file, but a prefix argument reverses this."
  (interactive (list current-prefix-arg last-input-event))
  (if event (posn-set-point (event-end event)))
  (let ((reverse (save-excursion (beginning-of-line) (looking-at "[-<]"))))
    (let ((location (p4-diff-find-source-location
                     (diff-xor other-file reverse))))
      (when location
        (apply 'p4-depot-find-file location)))))


;;; Annotate mode:

(defvar p4-annotate-mode-map
  (let ((map (p4-make-derived-map p4-basic-mode-map)))
    (define-key map "n" 'p4-next-change-rev-line)
    (define-key map "p" 'p4-prev-change-rev-line)
    (define-key map "N" (lookup-key map "p"))
    (define-key map "l" 'p4-toggle-line-wrap)
    map)
  "The key map to use for browsing annotate buffers.")

(define-derived-mode p4-annotate-mode p4-basic-mode "P4 Annotate")

(defun p4-moveto-print-rev-column (old-column)
  (let ((colon (save-excursion
                 (move-to-column 0)
                 (if (looking-at "[^:\n]*:")
                     (progn
                       (goto-char (match-end 0))
                       (current-column))
                   0))))
    (move-to-column old-column)
    (if (and (< (current-column) colon)
             (re-search-forward "[^ \n][ :]" nil t))
        (goto-char (match-beginning 0)))))

(defun p4-next-change-rev-line ()
  "Next change/revision line"
  (interactive)
  (let ((c (current-column)))
    (move-to-column 1)
    (re-search-forward "^ *[0-9]+ +[0-9]+[^:\n]+:" nil "")
    (p4-moveto-print-rev-column c)))

(defun p4-prev-change-rev-line ()
  "Previous change/revision line"
  (interactive)
  (let ((c (current-column)))
    (forward-line -1)
    (move-to-column 32)
    (re-search-backward "^ *[0-9]+ +[0-9]+[^:\n]*:" nil "")
    (p4-moveto-print-rev-column c)))

(defun p4-toggle-line-wrap ()
  "Toggle line wrap mode"
  (interactive)
  (setq truncate-lines (not truncate-lines))
  (save-window-excursion
    (recenter)))


;;; Grep Mode:

(defvar p4-grep-regexp-alist
  '(("^\\(//.*?#[1-9][0-9]*\\):\\([1-9][0-9]*\\):" 1 2))
  "Regexp used to match p4 grep hits. See `compilation-error-regexp-alist'.")

(define-derived-mode p4-grep-mode grep-mode "P4 Grep"
  (set (make-local-variable 'compilation-error-regexp-alist)
       p4-grep-regexp-alist)
  (set (make-local-variable 'next-error-function)
       'p4-grep-next-error-function))

(defun p4-grep-find-file (marker filename directory &rest formats)
  (p4-depot-find-file-noselect filename))

(defun p4-grep-next-error-function (n &optional reset)
  "Advance to the next error message and visit the file where the error was.
This is the value of `next-error-function' in P4 Grep buffers."
  (interactive "p")
  (let ((cff (symbol-function 'compilation-find-file)))
    (unwind-protect
        (progn (fset 'compilation-find-file 'p4-grep-find-file)
               (compilation-next-error-function n reset))
      (fset 'compilation-find-file cff))))


;;; Hooks:

(add-hook 'find-file-hooks 'p4-update-status)

;(add-to-list 'file-name-handler-alist '("\\`//\\(?:[^/#@ \t\n]+/\\)+[^/#@ \t\n]*\\(?:#[1-9][0-9]*\\|@[^/#@ \n\t]+\\)?$" . p4-file-name-handler))

(provide 'p4)

;;; p4.el ends here
