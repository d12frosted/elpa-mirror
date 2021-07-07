;;; org-starter.el --- A basic configuration framework for org mode -*- lexical-binding: t -*-

;; Copyright (C) 2018-2020 by Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.2.9
;; Package-Version: 20210314.1558
;; Package-Commit: 786257e682bf147022d5b19e6df6e7c9939193af
;; Package-Requires: ((emacs "25.1") (dash "2.18"))
;; URL: https://github.com/akirak/org-starter

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package helps you configure org mode.  See README for details.

;;; Code:

(require 'org)
(require 'cl-lib)
(require 'subr-x)
(require 'dash)
(require 'org-capture)

(declare-function posframe-show "ext:posframe")
(declare-function posframe-delete-frame "ext:posframe")
(declare-function posframe-poshandler-frame-center "ext:posframe")
(declare-function posframe-workable-p "ext:posframe")
(defvar org-agenda-custom-commands)
(defvar org-agenda-window-setup)
(defvar org-agenda-sticky)
(defvar org-agenda-buffer-name)

;;;; Compatibility

(eval-and-compile
  (with-no-warnings
    (defalias 'org-starter--when-let* #'when-let)
    (function-put #'org-starter--when-let* 'lisp-indent-function 1)))

(defconst org-starter-message-buffer "*org-starter message*")

;;;; Custom variables
(defcustom org-starter-capture-template-map-function nil
  "A function used to transform each entry in `org-capture' templates."
  :type 'function
  :group 'org-starter)

(defcustom org-starter-alternative-find-function
  (cond
   ((fboundp 'helm-org-rifle-files) #'helm-org-rifle-files)
   (t #'org-starter-sparse-tree-on-file))
  "An alternative function to find an Org file.

This function is called by `org-starter-find-file-by-key' when
a sequence of two universal arguments are given."
  :group 'org-starter
  :type 'function)

(defcustom org-starter-use-child-frame t
  "If non-nil, use child frames for multi line messages.

You will need posframe.el for actually using this feature."
  :type 'boolean
  :group 'org-starter)

(defcustom org-starter-child-frame-border-width 2
  "Border width of child frames."
  :type 'number
  :group 'org-starter)

(defcustom org-starter-child-frame-border-color
  "white"
  "Border color of child frames."
  :type 'color
  :group 'org-starter)

(defcustom org-starter-child-frame-foreground-color nil
  "Border color of child frames."
  :type '(choice color nil)
  :group 'org-starter)

(defcustom org-starter-child-frame-background-color nil
  "Border color of child frames."
  :type '(choice color nil)
  :group 'org-starter)

(defcustom org-starter-child-frame-override-parameters nil
  "Override posframe parameters with this plist."
  :type 'plist
  :group 'org-starter)

(defcustom org-starter-child-frame-poshandler
  #'posframe-poshandler-frame-center
  "Poshandler function."
  :type 'function
  :group 'org-starter)

(defcustom org-starter-verify-agenda-configuration t
  "Whether to verify configuration in `org-starter-add-agenda-custom-command'."
  :type 'boolean
  :group 'org-starter)

(define-widget 'org-starter-bindings 'lazy
  "List of custom keybindings."
  :tag "Keybindings"
  :type '(repeat (list (string :tag "Key")
                       (function :tag "Command")
                       (choice :tag "Help"
                               string
                               (const nil)))))

(defcustom org-starter-find-file-visit-window
  nil
  "When non-nil, visit the window displaying a file if any.

When this variable is set to non-nil,
`org-starter-find-file-by-key' selects a window displaying the
target file if there is such a window in the same frame."
  :type 'boolean
  :group 'org-starter)

(defcustom org-starter-extra-find-file-map
  nil
  "Extra bindings available in `org-starter-find-file-by-key'."
  :group 'org-starter
  :type 'org-starter-bindings)

(defcustom org-starter-extra-refile-map
  '(("/" org-refile "normal refile"))
  "Extra bindings available in `org-starter-refile-by-key'."
  :group 'org-starter
  :type 'org-starter-bindings)

(defcustom org-starter-extra-alternative-find-file-map
  nil
  "Extra keybindings in `org-starter-alternative-find-file-by-key'."
  :group 'org-starter
  :type 'org-starter-bindings)

(defcustom org-starter-require-file-by-default t
  "When non-nil, require defined files by default.

This is the default value of \":required\" option in
`org-starter-define-file'.  If this option is non-nil,
all files defined by org-starter must exist.  If a file does not
exist, it throws an error.

This option does not affect the behavior of directory definitions."
  :group 'org-starter
  :type 'boolean)

(defcustom org-starter-config-file-name ".org-config.el"
  "File name of external config files for org-starter.

See function `org-starter-load-config-files' for details."
  :group 'org-starter
  :type 'string)

(defcustom org-starter-load-config-files nil
  "When non-nil, load config files in known directories.

Org-Starter loads configuration files with
`org-starter-config-file-name' if this variable is set to non-nil.

When this variable is set to non-nil, org-starter loads Emacs
Lisp configuration files with from the following places:

- When org-starter.el is loaded, org-starter loads configuration files
  in `org-starter-path'.

- After org-starter.el is loaded, org-starter loads configuration
  files as directories are defined using
  `org-starter-define-directory' (or `org-starter-def' on a
  directory).

If a file with `org-starter-config-file-name' does not exist in a
given directory, the file will not be loaded."
  :group 'org-starter
  :type 'boolean)

(defcustom org-starter-refresh-agenda-on-redefinition t
  "When non-nil, refresh an existing agenda buffer on redefinition.

If you set this variable to non-nil, both
`org-starter-add-agenda-custom-command' and
`org-starter-add-block-agenda-command' refreshes a corresponding existing agenda
buffer if it is updates an existing buffer of the same key.
This is useful for experimenting with a new custom agenda command.

If `org-agenda-sticky' is non-nil, it checks for a stick agenda
buffer of the same key.  If such a buffer exists, the buffer is
killed and the agenda is redispatched.

If `org-agenda-sticky' is nil, it checks if there is an agenda buffer
and redispatches the redefined agenda, no matter which agenda command
is currently displayed in the agenda buffer.

If the value is \"confirm\" instead of t, it asks the user if he/she
wants to redispatches the agenda."
  :group 'org-starter
  :type '(choice (const :tag "Without confirmation" t)
                 (const :tag "With confirmation" confirm)
                 (const :tag "Never" nil)))

(defcustom org-starter-override-agenda-window-setup
  nil
  "If non-nil, override `org-agenda-window-setup' when redispatching an agenda.

This is effective if and only if an agenda command is dispatched
by org-starter as documented for
`org-starter-refresh-agenda-on-redefinition'.

If you are experimenting with a custom agenda command, you
probably don't want to display the agenda in the same buffer as
the source code.  To handle such a situation, this option lets you
override `org-agenda-window-setup' only when an agenda command is
dispatched due to redefining it.  The options are the same as
`org-agenda-window-setup'.

If this variable is nil, it doesn't take effect, and the same
  window setup is used."
  :group 'org-starter
  :type '(choice (const current-window)
                 (const other-window)
                 (const only-window)
                 (const reorganize-frame)
                 (const other-frame)
                 (const nil)))

;;;; Variables
(defvar org-starter-suppress-override-messages-once nil)

;;;; The error buffer and error logging
;; This is used by `org-starter-verify-configuration'.

(defcustom org-starter-enable-local-variables nil
  "Override `enable-local-variables' when files are loaded.

When this variable is set to a value other than nil and function
`org-starter-mode' is turned on, `enable-local-variables' is set
to the value temporarily when a file in `org-starter-known-files'
is loaded.  For example, if the variable is set to `:all', all
local variables defined in the file are applied when it is loaded
without confirmation.  As variables defined in your own files are
supposed to be safe, this is also usually safe.  However, when
this option is set to `:all', please don't add a file that can be
edited by someone else, as local variables can bring
vulnerability.

When the variable is set to nil, org-starter does not override the
value of `enable-local-variables`."
  :group 'org-starter
  :type 'symbol)

(defconst org-starter-error-buffer "*org-starter errors*")

(defvar org-starter-found-errors nil
  "Non-nil if an error is found while configuring org-starter.")

(defvar org-starter-prevent-local-config-directories nil
  "List of directories from which config files shouldn't be loaded.

This is updated by `org-starter-define-directory'.
The user should not update this value.")

;;;###autoload
(define-minor-mode org-starter-mode
  "Turn on/off features of org-starter.

This includes the following features:

- Activate a function advice around `find-file-noselect', so
  `org-starter-enable-local-variables' option is respected.

- When Org files are loaded, set file-local variables defined as
  :local-variables option in `org-starter-define-file'."
  :lighter " Org-Starter"
  :require 'org-starter
  :global t
  :group 'org-starter
  (cond
   ;; Turn on
   (org-starter-mode
    (add-hook 'org-mode-hook #'org-starter-org-mode-hook t)
    (advice-add #'find-file-noselect :around
                #'org-starter--ad-around-find-file-noselect))
   ;; Turn off
   (t
    (advice-remove #'find-file-noselect
                   #'org-starter--ad-around-find-file-noselect)
    (remove-hook 'org-mode-hook #'org-starter-org-mode-hook))))

(defun org-starter--clear-errors ()
  "Reset the status of the error buffer."
  (org-starter--when-let* ((buf (get-buffer org-starter-error-buffer)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer))))
  (setq org-starter-found-errors nil))

(defun org-starter--create-error-buffer ()
  "Return the error buffer."
  (or (get-buffer org-starter-error-buffer)
      (with-current-buffer (generate-new-buffer org-starter-error-buffer)
        (local-set-key "q" 'quit-window)
        (local-set-key "g" 'org-starter-verify-configuration)
        (setq buffer-read-only t)
        (current-buffer))))

(defun org-starter--log-error-no-newline (format-string &rest args)
  "Variant of `org-starter--log-error' that does not append a newline.

FORMAT-STRING is the format spec, and ARGS are parameters."
  (declare (indent 0))
  (with-current-buffer (org-starter--create-error-buffer)
    (let ((inhibit-read-only t))
      (insert (apply #'format format-string args))))
  (setq org-starter-found-errors (1+ (or org-starter-found-errors 0))))

(defun org-starter--log-error (format-string &rest args)
  "Like `message', but logs a string to `org-starter-error-buffer'.

FORMAT-STRING is the format spec, and ARGS are parameters."
  (declare (indent 0))
  (org-starter--log-error-no-newline (concat format-string "\n") args))

;;;; File registry: known files and directories, path, deprecated files, etc.
(defvar org-starter-known-files nil
  "List of files registered by `org-starter-define-file'.")

(defcustom org-starter-path nil
  "List of directories to search org files for."
  :group 'org-starter
  :type '(repeat string)
  :set (lambda (key value)
         (if (featurep 'org-starter)
             (let ((added (-difference value (symbol-value key))))
               (set-default key value)
               (message "Add directories to org-starter-path: %s"
                        (string-join added " "))
               (mapc #'load-file (org-starter--get-existing-config-files added)))
           (set-default key value))))

(defvar org-starter-deprecated-files nil
  "List of deprecated org files currently existing.")

(defvar org-starter-known-directories nil)

(defun org-starter--lookup-known-file (filename)
  "Look up a FILENAME (without a directory) in `org-starter-known-files'."
  (car (cl-remove-if-not (lambda (fpath)
                           (equal filename
                                  (file-name-nondirectory fpath)))
                         org-starter-known-files)))

(defun org-starter--search-file (filename &optional check-known-files)
  "Search FILENAME from `org-starter-path'.

If CHECK-KNOWN-FILES is non-nil, `org-starter-known-files' is first checked for
the FILENAME."
  (or (and check-known-files
           (org-starter--lookup-known-file filename))
      (cl-loop for dir in org-starter-path
               for fpath = (expand-file-name filename dir)
               when (file-exists-p fpath)
               return fpath)))

(defun org-starter-locate-file (filename &optional directory check-known-files)
  "Search FILENAME from DIRECTORY and `org-starter-path' and return its path.

This function returns an existing path to a file which has the same
sans-directory file name as FILENAME.  If such a file is not found, this
function returns nil.

If CHECK-KNOWN-FILES is non-nil, `org-starter-known-files' is first checked for
the FILENAME."
  (cond
   ((file-name-absolute-p filename)
    (when (file-exists-p filename)
      filename))
   ((null directory)
    (org-starter--search-file filename check-known-files))
   (t
    (let* ((dir (cond
                 ((stringp directory) directory)
                 ((symbolp directory) (symbol-value directory))
                 (t (error "Unsupported type of directory: %s"
                           (prin1-to-string directory)))))
           (default-file (expand-file-name filename dir)))
      (if (file-exists-p default-file)
          default-file
        (let ((found-file (org-starter--search-file filename
                                                    check-known-files)))
          (when (and found-file
                     (yes-or-no-p (format "%s does not exist, but %s is found. Add it instead?"
                                          default-file found-file)))
            found-file)))))))

(defun org-starter--to-symbol-list (obj)
  "Make a list of symbols from a symbol or a list.

OBJ should be a symbol, or a list of symbols."
  (cond
   ((null obj) nil)
   ((symbolp obj) (list obj))
   ((listp obj) obj)))

;;;; Exclude files in org-starter from recentf

(defcustom org-starter-exclude-from-recentf nil
  "If non-nil, exclude items in `org-starter-known-files' from recentf."
  :group 'org-starter
  :type '(set (const :tag "Exclude known files" 'known-files)
              (const :tag "Exclude files in path" 'path)))

(defun org-starter-recentf-excluded-p (file)
  "Check if FILE is an org-starter file that should be excluded from recentf."
  (and (listp org-starter-exclude-from-recentf)
       org-starter-exclude-from-recentf
       (or (and (memq 'known-files org-starter-exclude-from-recentf)
                (cl-member file org-starter-known-files
                           :test #'file-equal-p))
           (and (memq 'path org-starter-exclude-from-recentf)
                (string-match-p org-agenda-file-regexp file)
                (cl-member (file-name-directory file) org-starter-path
                           :test #'file-equal-p)))))

(add-hook 'recentf-exclude #'org-starter-recentf-excluded-p t)

;;;; Defining directories

(defvar org-starter-directory-origins nil
  "Alist of pairs of a directory and its origin.

Each item in this alist is a cons of a path to a local directory and its origin
repository URL.")

(defun org-starter--clone (origin dest)
  "Clone a repository at ORIGIN to DEST."
  ;; TODO: check origin URL
  (process-lines "git" "clone" origin dest))

(defun org-starter-clone-all ()
  "Clone all missing repositories specified in `org-starter-directory-origins'."
  (interactive)
  (cl-loop for (dest . origin) in org-starter-directory-origins
           unless (file-directory-p dest)
           do (org-starter--clone origin dest)))

(defun org-starter--define-glob-function (dpath id)
  "Define a function to glob entries in a directory.

This function defines a function to glob a list of org files in a directory.
DPATH is a path to the directory, and ID is a symbol/string to uniquely
identify the directory."
  (let ((name (intern (format "org-starter-glob-files/%s"
                              (cl-etypecase id
                                (symbol (symbol-name id))
                                (string id))))))
    (eval `(defun ,name ()
             (when (file-directory-p ,dpath)
               (directory-files ,dpath t org-agenda-file-regexp))))))

(cl-defun org-starter-define-directory (dpath &key
                                              agenda
                                              refile
                                              id
                                              origin
                                              ensure
                                              add-to-path
                                              custom-vars
                                              no-config-file
                                              files)
  "Define a directory for org files.

DPATH is a path to the directory. This option cannot be nil.

If AGENDA is non-nil, the directory is added to `org-agenda-files'.

If REFILE is set, files in the directory are added to
`org-refile-targets'.  In this case, you have to also specify ID
to uniquely identify the directory.  This identifier is used to
determine the name of a function to glob files in the directory,
which is called by `org-refile'.

ORIGIN is a repository URL from which you want to clone the
repository.  If this option is set and ENSURE option is non-nil,
this function automatically clones the repository when the
directory does not exist.

If ADD-TO-PATH is non-nil, the directory is added to
`org-starter-path'.

CUSTOM-VARS can be either a symbol or a list of symbols.
These symbols are names of variables that should be set to the path
of the directory.  `customize-set-variable' is used to set the value.

If NO-CONFIG-FILE is set to non-nil, the configuration file in
the directory will not be loaded even if
`org-starter-load-config-files' is set and the directory contains
the file.

FILES is a list whose item accepts the same options as
`org-starter-define-file', except for `:directory' option.
You can define files in the directory.

If the directory exists and the configuration is done properly,
the path to the directory is returned as the result of this function."
  (declare (indent 1))
  (let ((exists (file-directory-p dpath)))
    (setq dpath (expand-file-name (file-name-as-directory dpath)))
    (when (and ensure (not exists))
      (unless origin
        (error "%s is a required directory, but `:ensure' property is unset" dpath))
      (org-starter--clone origin dpath))
    (when agenda
      (add-to-list 'org-agenda-files dpath 'append #'file-equal-p))
    (when origin
      (add-to-list 'org-starter-directory-origins (cons dpath origin)))
    (when (and add-to-path exists)
      (cl-adjoin dpath org-starter-path :test #'file-equal-p))
    (when refile
      (unless id
        (error "To add %s to refile targets, you must set `:id' property" dpath))
      (let* ((func (org-starter--define-glob-function dpath id))
             (pair (assq func org-refile-targets)))
        (if pair
            (setf (cdr pair) refile)
          (add-to-list 'org-refile-targets (cons func refile) 'append))))
    (dolist (symbol (cl-typecase custom-vars
                      (list custom-vars)
                      (symbol (list custom-vars))))
      (customize-set-variable symbol dpath))
    (when no-config-file
      (add-to-list 'org-starter-prevent-local-config-directories dpath))
    (cl-loop for (filename . options) in files
             do (apply #'org-starter-define-file filename :directory dpath
                       options))
    (add-to-list 'org-starter-known-directories dpath)
    (when (and add-to-path
               after-init-time
               (not (cl-member dpath org-starter-prevent-local-config-directories
                               :test #'file-equal-p)))
      (let ((file (expand-file-name org-starter-config-file-name dpath)))
        (when (file-exists-p file)
          (load-file file))))
    dpath))

;;;; Defining files
;;;;; File-local variables and modes
(defvar org-starter-file-local-variables nil
  "Alist of file-local variable definitions.")

(defvar org-starter-file-local-minor-modes nil
  "Alist of file-local minor modes.")

(defvar org-starter-file-local-hooks nil
  "Alist of file-local load hooks.")

(defun org-starter-org-mode-hook ()
  "Apply file-local settings."
  (org-starter--when-let* ((fpath (buffer-file-name)))
    (mapc (pcase-lambda
            (`(,symbol . ,value))
            (cl-assert (symbolp symbol))
            (set (make-local-variable symbol) value))
          (cdr (cl-assoc fpath org-starter-file-local-variables
                         :test #'file-equal-p)))
    (mapc (pcase-lambda
            ((or `(,mode ,arg) (and (let arg 1) mode)))
            (funcall mode arg))
          (cdr (cl-assoc fpath org-starter-file-local-minor-modes
                         :test #'file-equal-p)))
    (org-starter--when-let*
        ((hook (cdr (cl-assoc fpath org-starter-file-local-hooks
                              :test #'file-equal-p))))
      (funcall hook))))

(define-obsolete-function-alias 'org-starter-load-local-variables
  #'org-starter-org-mode-hook
  "0.2.9")

;;;;; Keymap for visiting a known file (deprecated)
(defvar org-starter-file-map (make-sparse-keymap)
  "Keymap used to find a file.")

(defcustom org-starter-define-file-commands 'with-keys
  "Define commands to find a specific file.

When non-nil, org-starter define commands to find (or jump to) a specific file
defined by `org-starter-define-file'.  The defined commands are also used to
bind keys to files.

This is convenient for the follwing
reasons:

- You can access a file quickly using \\[execute-command\\].
- You can use the command names for which-key replacements."
  :group 'org-starter
  :type '(choice (const :tag "All defined files" all)
                 (const :tag "Files with keys" with-keys)
                 (const :tag "Never" nil)))

(defcustom org-starter-file-command-template "org-starter-find-file:%s"
  "Template used to determine command names for files.

'%s' in the template is replaced with the base name of the file.

This is applicable when `org-starter-define-file-commands' is non-nil."
  :type 'string
  :group 'org-starter)

(defmacro org-starter--file-command-name (fpath)
  "Build a command name for FPATH."
  `(intern (format org-starter-file-command-template (file-name-base ,fpath))))

(defun org-starter--define-file-command (fpath)
  "Define a command to find FPATH."
  (eval
   `(defun ,(org-starter--file-command-name fpath) ()
      (interactive)
      (find-file ,fpath))))

(defvar org-starter-key-file-alist nil)

(defun org-starter--funcall-on-file-by-key (func &optional
                                                 prompt
                                                 extra-map
                                                 extra-help)
  "Pick an Org file by key and apply a function on it.

This function picks an Org file by a key specified as :key argument
of `org-starter-define-file', and apply FUNC on it.

If PROMPT is given, use it as the prompt.

If EXTRA-MAP is given, use it as the extra map.
The original bindings defined by :key property are overridden by it.

EXTRA-HELP is an alist for the items in the extra map."
  (let* ((map (make-sparse-keymap))
         (message-log-max nil)
         (help-items (mapcar (lambda (cell)
                               (format "[%s]: %s"
                                       (car cell) (cdr cell)))
                             (cl-union extra-help
                                       (mapcar (lambda (cell)
                                                 (cons (car cell)
                                                       (file-name-nondirectory (cdr cell))))
                                               org-starter-key-file-alist)
                                       :key #'car))))
    (dolist (cell org-starter-key-file-alist)
      (define-key map (car cell)
        (lambda () (interactive) (funcall func (cdr cell)))))
    (org-starter--display-options prompt help-items)
    (set-transient-map (if extra-map
                           (make-composed-keymap extra-map map)
                         map))))

;;;###autoload
(defun org-starter-find-file-by-key (&optional arg)
  "Visit an Org file quickly by key.

With this command, you can quickly open a file by a key sequence
specified as :key property of the file.

To access a file which is not assigned a key, you can select it
using `completing-read' by pressing \"/\" key.

If a universal prefix is given as ARG, open the file in other
window.

If two universal prefix arguments (C-u C-u) is given, call a function
specified as `org-starter-alternative-find-function' with the file
as the argument."
  (interactive "P")
  (let* ((map (make-sparse-keymap))
         (extra-help (cl-loop for (key command . help) in org-starter-extra-find-file-map
                              do (define-key map (kbd key) command)
                              when help
                              collect (cons key (car help)))))
    (pcase arg
      ('(4) (progn
              (define-key map (kbd "/") #'org-starter-select-file-other-window)
              (org-starter--funcall-on-file-by-key
               #'org-starter--find-file-other-window
               "Find an Org file in other window:"
               map extra-help)))
      ('(16) (progn
               (define-key map (kbd "/")
                 (lambda ()
                   (interactive)
                   (funcall org-starter-alternative-find-function
                            (org-starter-select-file "Select an Org file: "))))
               (org-starter--funcall-on-file-by-key
                org-starter-alternative-find-function
                (format "Call %s:"
                        (if (symbolp org-starter-alternative-find-function)
                            (symbol-name org-starter-alternative-find-function)
                          "the function"))
                map extra-help)))
      (_ (progn
           (define-key map (kbd "/") #'org-starter-select-file)
           (org-starter--funcall-on-file-by-key
            #'org-starter--find-file
            "Find an Org file:"
            map extra-help))))))

(defun org-starter--find-file (file)
  "Switch to a buffer visiting FILE."
  (org-starter--select-file-window file
                                   #'switch-to-buffer))

(defun org-starter--find-file-other-window (file)
  "Switch to a buffer visiting FILE in other window."
  (org-starter--select-file-window file
                                   #'switch-to-buffer-other-window))

(defun org-starter--select-file-window (file fallback)
  "Select a window displaying a file or open the file.

If there is a window displaying the buffer of FILE, select the window.
Otherwise, switch to the buffer of the file using FALLBACK function."
  (let ((buffer (or (find-buffer-visiting file)
                    (find-file-noselect file))))
    (if-let ((window (and org-starter-find-file-visit-window
                          (get-buffer-window buffer))))
        (select-window window)
      (funcall fallback buffer))))

;;;###autoload
(defun org-starter-alternative-find-file-by-key (&optional arg)
  "Visit an Org file using `org-starter-alternative-find-function'.

This is like `org-starter-find-file-by-key' but uses
`org-starter-alternative-find-function' to visit a file.
Keys are configured as :key properties of files, which are the same
as `org-starter-find-file-by-key'.

To access a file which is not assigned a key, you can select it
using `completing-read' by pressing \"/\" key.

If a universal prefix is given as ARG, visit the file using
`find-file'.

Extra commands are configured in
`org-starter-extra-alternative-find-file-map'."
  (interactive "P")
  (let* ((map (make-sparse-keymap))
         (extra-help (cl-loop for (key command . help) in org-starter-extra-alternative-find-file-map
                              do (define-key map (kbd key) command)
                              when help
                              collect (cons key (car help)))))
    (pcase arg
      ('(4) (progn
              (define-key map (kbd "/") #'org-starter-select-file)
              (org-starter--funcall-on-file-by-key
               #'find-file "Find an Org file:"
               map extra-help)))
      (_ (progn
           (define-key map (kbd "/") #'org-starter-select-file-alternative)
           (org-starter--funcall-on-file-by-key
            org-starter-alternative-find-function
            "Visit an Org file using the alternative command:"
            map extra-help))))))

(defun org-starter--refile-target-of-file (file)
  "Get a refile target spec to FILE."
  (cl-assoc file (cl-remove-if-not (lambda (cell) (stringp (car cell)))
                                   org-refile-targets)
            :test 'file-equal-p))

;;;###autoload
(defun org-starter-refile-by-key (&optional arg)
  "Run `org-refile' with the target limited to a file by key.

With this command, you can quickly refile the current entry to a file by a key
sequence specified as :key property of the file.

ARG is passed to `org-refile' function.

You can also access keybindings defined in
`org-starter-extra-refile-map'.
For example, you can run a normal `org-refile' by pressing \"/\" key
by default."
  (interactive "P")
  (unless (derived-mode-p 'org-mode)
    (error "Not in org-mode"))
  (let* ((extra-map (make-sparse-keymap))
         (extra-help (cl-loop for (key command . help) in org-starter-extra-refile-map
                              do (define-key extra-map (kbd key) command)
                              when help
                              collect (cons key (car help)))))
    (org-starter--funcall-on-file-by-key
     (lambda (file)
       (let ((org-refile-targets (list (or (org-starter--refile-target-of-file file)
                                           `(,file :maxlevel . 9)))))
         (org-refile arg)))
     "Refile to file:" extra-map extra-help)))

(defun org-starter--bind-file-key (key fpath)
  "Bind KEY to a command to visit FPATH."
  ;; (let ((command-name (org-starter--file-command-name fpath)))
  ;;   (define-key 'org-starter-file-map key
  ;;     (if (and org-starter-define-file-commands
  ;;              (fboundp command-name))
  ;;         command-name
  ;;       `(lambda () (interactive) (find-file ,fpath)))))
  (cl-pushnew (cons key fpath) org-starter-key-file-alist
              :key 'car :test 'equal))

;;;;; Defining a file

(cl-defun org-starter-define-file (filename &key
                                            directory
                                            (required t)
                                            deprecated
                                            agenda
                                            refile
                                            custom-vars
                                            minor-modes
                                            set-default
                                            capture
                                            key
                                            local-variables
                                            local-config)
  "Define an org file.

FILENAME is the file name of the org file. This can be either a file name
without a directory or an absolute file path.

DIRECTORY is a directory that should contain the file. FILENAME and DIRECTORY
are passed to `org-starter-locate-file' function to find an actual path to the
file.

By default, this function raises an error if the file does not exist. This can
be prevented by setting REQUIRED to nil or DEPRECATED to t.

If DEPRECATED is non-nil, this file is not added to `org-refile-targets' even if
the refile option is specified. The file is added to
`org-starter-deprecated-files' which you can use for testing.

If AGENDA is non-nil, the file is added to `org-agenda-files'.

If REFILE is set, the file is added to `org-refile-targets' with the option
value. For example, if you set REFILE to \"'(:maxlevel . 5)\", then
\"'(PATH (:maxlevel . 5))\" is added to `org-refile-targets'.

REFILE can be also a function.  If it is a function, the function
is used in `org-starter-refile-by-key'.  See
`org-starter-extras-def-reverse-datetree-refile' for example.  You
also have to specify KEY, and the file won't be added to
`org-refile-targets'.

If you specify variable names as a list of symbols in CUSTOM-VARS, those
variables are set to the path of the defined file using
`customize-set-variable'.
For example, you can use this function to set `org-default-notes-file' based
on the actual path.

MINOR-MODES is a list of minor modes to turn on in the file. Each
item is usually a symbol like `org-recur-mode', and in that case,
the mode is turned on after the file is loaded. Alternatively, it
can be a cell like \"(org-recur-mode -1)\" to ensure the mode is
turned off in the file.

SET-DEFAULT is almost the same as CUSTOM-VARS.  It exists only for
backwards-compatibility.  It uses `set-default' instead of
`customize-set-variable'.

CAPTURE specifies a list of `org-capture' templates into the file.
To properly override an existing template with the same key, items in
`org-capture-templates' should be sorted lexicographically by key.

KEY is a string to represent a key binding used to jump to the file.
If this property is nil, the file will not be bound on the map.

LOCAL-VARIABLES allows you to specify file-local variables which should be set
after org-mode is initialized. This can be done in the file footer, but it is
sometimes convenient to be able to define them outside of the file, especially
if you define a complex function. This option should be an alist of variable
names and values.

LOCAL-CONFIG can be a function or an expression called or
evaluated after the file is loaded. For example, you can call
`add-hook' to add buffer-local hooks via this property.

If the file exists and it is properly defined, the path to the file
is returned as the result of this function."
  (declare (indent 1))
  (let ((fpath (org-starter-locate-file filename directory)))
    (cond
     (fpath (progn
              (when (cl-ecase org-starter-define-file-commands
                      (all t)
                      (with-keys key)
                      (nil nil))
                (org-starter--define-file-command fpath))
              (when deprecated
                (org-starter--log-error "%s file is deprecated"
                                        (abbreviate-file-name fpath))
                (add-to-list 'org-starter-deprecated-files fpath))
              (if agenda
                  (add-to-list 'org-agenda-files fpath 'append #'file-equal-p)
                (cl-delete fpath org-agenda-files :test #'file-equal-p))
              (mapc (lambda (symbol) (customize-set-variable symbol fpath))
                    (org-starter--to-symbol-list custom-vars))
              (mapc (lambda (symbol) (set-default symbol fpath))
                    (org-starter--to-symbol-list set-default))
              (when (and refile (not deprecated))
                (cl-etypecase refile
                  (function
                   (if key
                       (let* ((item (list key refile filename))
                              (cell (assoc (car item) org-starter-extra-refile-map)))
                         (if cell
                             (setcdr cell (cdr item))
                           (push item org-starter-extra-refile-map)))
                     (user-error "You have to specify KEY if REFILE is a function")))
                  (list
                   (let ((pair (assoc fpath org-refile-targets)))
                     (if pair
                         (setf (cdr pair) refile)
                       (add-to-list 'org-refile-targets (cons fpath refile) 'append))))))
              (unless deprecated
                (dolist (spec (mapcar (or org-starter-capture-template-map-function
                                          #'identity)
                                      capture))
                  (org-starter-add-file-capture-template fpath spec)))
              (when key
                (org-starter--bind-file-key key fpath))
              (when local-variables
                (push (cons fpath local-variables) org-starter-file-local-variables))
              (when minor-modes
                (push (cons fpath minor-modes) org-starter-file-local-minor-modes))
              (when local-config
                (push (cons fpath
                            (cl-etypecase local-config
                              (function local-config)
                              ;; sexp
                              (list `(lambda () ,local-config))))
                      org-starter-file-local-hooks))
              (add-to-list 'org-starter-known-files fpath)
              fpath))
     ((and (not deprecated)
           org-starter-require-file-by-default
           required)
      (error "Required org file %s is not found" filename))
     ((not deprecated)
      (org-starter--log-error "%s is missing" filename)))))

(defmacro org-starter-def (path &rest options)
  "Define a file or a directory.

This function calls either `org-starter-define-file' or
`org-starter-define-directory' depending on the type of the file at
PATH.  PATH should be an absolute path.

OPTIONS are passed to the function after preprocessing.

As well as options to one of those functions, `org-starter-def'
supports an additional option \":config\", which is evaluated after
the file/directory is defined.  This accepts multiple arguments."
  (declare (indent 1))
  (setq options (org-starter--flatten-plist options))
  (let ((config (plist-get options :config)))
    (cl-remf options :config)
    `(if (file-directory-p ,path)
         (let ((r (apply #'org-starter-define-directory
                         ,path
                         (quote ,options))))
           ,@config
           r)
       (when-let ((path (org-starter-locate-file ,path
                                                 (plist-get (quote ,options)
                                                            :directory)))
                  (r (apply #'org-starter-define-file
                            path
                            (quote ,options))))
         ,@config
         r))))

(defun org-starter--flatten-plist (plist)
  "Flatten PLIST for use in `org-starter-def'."
  (let (result
        arg)
    (while (setq arg (pop plist))
      (pcase arg
        (:config
         (-let [(args plist2) (-split-with (-not #'org-starter--plist-keyword-p) plist)]
           (setq plist plist2)
           (push arg result)
           (push args result)))
        (:files
         (-let [(args plist2) (-split-with (-not #'org-starter--plist-keyword-p) plist)]
           (setq plist plist2)
           (push arg result)
           (push (org-starter--files-arg args) result)))
        ((pred org-starter--plist-keyword-p)
         (progn
           (push arg result)
           (push (pop plist) result)))))
    (nreverse result)))

(defun org-starter--files-arg (args)
  "Normalize ARGS given as \":files\" option."
  (if (and (= 1 (length args))
           (listp (caar args)))
      (car args)
    args))

(defun org-starter--plist-keyword-p (arg)
  "Return non-nil if ARG is a symbol starting with \":\"."
  (and (symbolp arg)
       (string-equal (substring (symbol-name arg) 0 1) ":")))

(defun org-starter--add-capture-template (spec)
  "Insert SPEC into `org-capture-templates'."
  (cl-destructuring-bind
      (former latter)
      (--split-with (string< (car it) (car spec))
                    org-capture-templates)
    (setq org-capture-templates
          `(,@former
            ,spec
            ,@(if (string-equal (caar latter) (car spec))
                  (cdr latter)
                latter)))
    ;; Return information during interactive evaluation
    (when after-init-time
      (and (string-equal (caar latter) (car spec))
           (cons (cadr (car latter)) (cadr spec))))))

(defcustom org-starter-initial-capture-templates nil
  "List of capture templates unassociated with files.

This is basically the same as `org-capture-templates', but when you
set this variable using the customization interface, it doesn't delete
existing capture templates.  This is convenient for developing
templates with non-file targets when you have some templates defined
by `org-starter-define-file'."
  ;; This type definition is copied from org-capture.el
  :type
  (let ((file-variants '(choice :tag "Filename       "
                                (file :tag "Literal")
                                (function :tag "Function")
                                (variable :tag "Variable")
                                (sexp :tag "Form"))))
    `(repeat
      (choice :value ("" "" entry (file "~/org/notes.org") "")
              (list :tag "Multikey description"
                    (string :tag "Keys       ")
                    (string :tag "Description"))
              (list :tag "Template entry"
                    (string :tag "Keys           ")
                    (string :tag "Description    ")
                    (choice :tag "Capture Type   " :value entry
                            (const :tag "Org entry" entry)
                            (const :tag "Plain list item" item)
                            (const :tag "Checkbox item" checkitem)
                            (const :tag "Plain text" plain)
                            (const :tag "Table line" table-line))
                    (choice :tag "Target location"
                            (list :tag "File"
                                  (const :format "" file)
                                  ,file-variants)
                            (list :tag "ID"
                                  (const :format "" id)
                                  (string :tag "  ID"))
                            (list :tag "File & Headline"
                                  (const :format "" file+headline)
                                  ,file-variants
                                  (string :tag "  Headline"))
                            (list :tag "File & Outline path"
                                  (const :format "" file+olp)
                                  ,file-variants
                                  (repeat :tag "Outline path" :inline t
                                          (string :tag "Headline")))
                            (list :tag "File & Regexp"
                                  (const :format "" file+regexp)
                                  ,file-variants
                                  (regexp :tag "  Regexp"))
                            (list :tag "File [ & Outline path ] & Date tree"
                                  (const :format "" file+olp+datetree)
                                  ,file-variants
                                  (option (repeat :tag "Outline path" :inline t
                                                  (string :tag "Headline"))))
                            (list :tag "File & function"
                                  (const :format "" file+function)
                                  ,file-variants
                                  (sexp :tag "  Function"))
                            (list :tag "Current clocking task"
                                  (const :format "" clock))
                            (list :tag "Function"
                                  (const :format "" function)
                                  (sexp :tag "  Function")))
                    (choice :tag "Template       "
                            (string)
                            (list :tag "File"
                                  (const :format "" file)
                                  (file :tag "Template file"))
                            (list :tag "Function"
                                  (const :format "" function)
                                  (function :tag "Template function")))
                    (plist :inline t
                           ;; Give the most common options as checkboxes
                           :options (((const :format "%v " :prepend) (const t))
                                     ((const :format "%v " :immediate-finish) (const t))
                                     ((const :format "%v " :jump-to-captured) (const t))
                                     ((const :format "%v " :empty-lines) (const 1))
                                     ((const :format "%v " :empty-lines-before) (const 1))
                                     ((const :format "%v " :empty-lines-after) (const 1))
                                     ((const :format "%v " :clock-in) (const t))
                                     ((const :format "%v " :clock-keep) (const t))
                                     ((const :format "%v " :clock-resume) (const t))
                                     ((const :format "%v " :time-prompt) (const t))
                                     ((const :format "%v " :tree-type) (const week))
                                     ((const :format "%v " :unnarrowed) (const t))
                                     ((const :format "%v " :table-line-pos) (string))
                                     ((const :format "%v " :kill-buffer) (const t))))))))
  :group 'org-starter
  :set (lambda (symbol value)
         (set-default symbol value)
         (mapc #'org-starter--add-capture-template
               (cl-sort value #'string< :key #'car))))

;;;###autoload
(defun org-starter-undefine-file (filename)
  "Delete an entry with FILENAME from the list of known files."
  (interactive (list (completing-read "Known file to undefine: "
                                      org-starter-known-files nil t)))
  (let ((fpath (expand-file-name
                (cond
                 ((file-name-absolute-p filename) filename)
                 (t (org-starter--lookup-known-file filename))))))
    (cl-delete fpath org-starter-deprecated-files)
    (cl-delete fpath org-agenda-files)
    (cl-delete fpath org-refile-targets :key #'car)
    (cl-delete fpath org-capture-templates
               :test #'equal
               :key (lambda (spec)
                      (pcase (nth 3 spec)
                        (`(file ,fpath) fpath)
                        (`(,key ,fpath . ,_)
                         (when (string-prefix-p "file+"
                                                (symbol-name key))
                           fpath)))))
    (cl-delete fpath org-starter-known-files)
    (message "Deleted %s from org-starter-known-files" fpath)))

;;;;; Configure a particular aspect of a file
(defun org-starter-add-file-capture-template (file spec)
  "Add a capture template for an already defined file.

FILE is a file name or a file path as passed to `org-starter-locate-file'
as the first argument.

SPEC is the same as an item in :capture option of `org-starter-define-file'."
  (declare (indent 1))
  (let* ((fpath (org-starter-locate-file file nil t))
         (target (pcase (nth 3 spec)
                   ('file `(file ,fpath))
                   (`(file+headline ,headline) `(file+headline ,fpath ,headline))
                   (`(file+olp . ,olp) `(file+olp ,fpath ,@olp))
                   (`(file+regexp ,regexp)
                    `(file+regexp ,fpath ,regexp))
                   (`(file+olp+datetree . ,olp)
                    `(file+olp+datetree ,fpath ,@olp))
                   (`(file+function ,function)
                    `(file+function ,fpath ,function))
                   (orig orig))))
    ;; Override the target if and only if it has one
    ;; The spec can be a list of two elements, i.e. a group
    (when target
      (setf (car (nthcdr 3 spec)) target))
    (org-starter--add-capture-template spec)))

(cl-defmacro org-starter-def-capture (keys
                                      description
                                      &optional
                                      type
                                      target
                                      template
                                      &key
                                      prepend
                                      immediate-finish
                                      jump-to-captured
                                      empty-lines
                                      empty-lines-before
                                      empty-lines-after
                                      clock-in
                                      clock-keep
                                      clock-resume
                                      time-prompt
                                      tree-type
                                      unnarrowed
                                      table-line-pos
                                      kill-buffer
                                      no-save
                                      &allow-other-keys)
  "Define a single capture template to a known file.

This macro lets you insert an entry into
`org-capture-templates'.  The resulting template list will be
sorted by alphabetical order, so templates are grouped with
prefix letters.

It has the same functionality as
`org-starter-add-file-capture-template', but this is intended to
provide a better API.

KEYS, DESCRIPTION, and TYPE are basically the same as in
`org-capture-templates' variable.  However, KEYS can also be a symbol
whose variable is a string.

TARGET is almost the same, but if the template type is a file or
part of it, e.g. \"file+headline\", the file name in the
expression is replaced with its absolute path as given by
`org-starter-locate-file'.

TEMPLATE is the same.

You can pass the following options as a plist as in
`org-capture-templates':

PREPEND, IMMEDIATE-FINISH, JUMP-TO-CAPTURED, EMPTY-LINES,
EMPTY-LINES-BEFORE, EMPTY-LINES-AFTER, CLOCK-IN, CLOCK-KEEP,
CLOCK-RESUME, TIME-PROMPT, TREE-TYPE, UNNARROWED, TABLE-LINE-POS,
KILL-BUFFER, and NO-SAVE.

The entire template spec is transformed by
`org-starter-capture-template-map-function'.

If TYPE and its following arguments are omitted, this macro inserts
a template group."
  (declare (indent 2))
  ;; If KEYS is a symbol, use its value as the key sequence.
  (when (symbolp keys)
    (setq keys (symbol-value keys)))
  (let* ((ok t)
         (target1 (pcase target
                    (`(file ,file)
                     `(file ,(setq ok (if (stringp file)
                                          (org-starter-locate-file file nil t)
                                        file))))
                    (`(file+headline ,file ,headline)
                     `(file+headline ,(setq ok (if (stringp file)
                                                   (org-starter-locate-file file nil t)
                                                 file)) ,headline))
                    (`(file+olp ,file . ,olp)
                     `(file+olp ,(setq ok (if (stringp file)
                                              (org-starter-locate-file file nil t)
                                            file)) ,@olp))
                    (`(file+regexp ,file ,regexp)
                     `(file+regexp ,(setq ok (if (stringp file)
                                                 (org-starter-locate-file file nil t)
                                               file)) ,regexp))
                    (`(file+olp+datetree ,file . ,olp)
                     `(file+olp+datetree ,(setq ok (if (stringp file)
                                                       (org-starter-locate-file file nil t)
                                                     file)) ,@olp))
                    (`(file+function ,file ,function)
                     `(file+function ,(setq ok (if (stringp file)
                                                   (org-starter-locate-file file nil t)
                                                 file)) ,function))
                    (orig orig)))
         (properties (-flatten-n
                      1 (--filter (nth 1 it)
                                  `((:prepend ,prepend)
                                    (:immediate-finish ,immediate-finish)
                                    (:jump-to-captured ,jump-to-captured)
                                    (:empty-lines ,empty-lines)
                                    (:empty-lines-before ,empty-lines-before)
                                    (:empty-lines-after ,empty-lines-after)
                                    (:clock-in ,clock-in)
                                    (:clock-keep ,clock-keep)
                                    (:clock-resume ,clock-resume)
                                    (:time-prompt ,time-prompt)
                                    (:tree-type ,tree-type)
                                    (:unnarrowed ,unnarrowed)
                                    (:table-line-pos ,table-line-pos)
                                    (:kill-buffer ,kill-buffer)
                                    (:no-save ,no-save)))))
         (spec (if type
                   (funcall (or org-starter-capture-template-map-function
                                #'identity)
                            (append (list keys description type target1 template)
                                    properties))
                 (list keys description))))
    (when ok
      `(when-let ((result (org-starter--add-capture-template (quote ,spec))))
         (concat "Overrode an existing template "
                 (if (string-equal (car result) (cdr result))
                     "of the same name"
                   (format "'%s'" (car result))))))))

;;;; Org-agenda
(defvar org-starter-suppress-override-messages-once nil)

;;;###autoload
(defun org-starter-add-agenda-custom-command (key desc
                                                  &optional
                                                  type match settings files)
  "`org-add-agenda-custom-command' with extra features.

This function basically adds (KEY DESC TYPE MATCH SETTINGS FILES) to
`org-agnda-custom-commands', but if it also checks if KEY does not
conflict with existing custom agenda commands.

You can also define a group using this function by omitting TYPE,
MATCH, SETTINGS, and FILES passed to it.

Some extra features may be added in the future."
  (declare (indent 2))
  ;; (unless (and key desc)
  ;;   (user-error "You cannot omit KEY and DESC"))
  (when (and (featurep 'org-starter)
             org-starter-verify-agenda-configuration)
    (unless (stringp key)
      (user-error "KEY must be a string"))
    (unless (stringp desc)
      (user-error "DESC must be a string"))
    ;; TODO: Verify match, settings, and files
    (org-starter--verify-agenda-type type t))
  (let ((args (let ((args (list type match settings files)))
                (nreverse (-drop-while #'not (nreverse args))))))
    (if-let ((current (assoc key org-agenda-custom-commands))
             (old-desc (nth 1 current)))
        ;; If it has the same description, override it
        (when (or (string-equal desc old-desc)
                  (not after-init-time)
                  org-starter-suppress-override-messages-once
                  ;; Otherwise, confirmation is needed
                  (yes-or-no-p (format "Replace custom agenda command '%s' with '%s'?"
                                       old-desc desc)))
          (setcdr current (cons desc args))
          (when org-starter-refresh-agenda-on-redefinition
            (cond
             (org-agenda-sticky
              (let ((sticky-agenda-buffer (get-buffer (format "*Org Agenda(%s)*" key))))
                (when (and sticky-agenda-buffer
                           (or (not (eq 'confirm org-starter-refresh-agenda-on-redefinition))
                               (yes-or-no-p (format "Kill existing sticky agenda buffer %s and rerun it?" key))))
                  (let ((agenda-window (get-buffer-window sticky-agenda-buffer t))
                        (orig-buffer (window-buffer)))
                    (unwind-protect
                        (if agenda-window
                            (with-selected-window agenda-window
                              (kill-buffer sticky-agenda-buffer)
                              (let ((org-agenda-window-setup 'current-window))
                                (org-agenda nil key)))
                          (kill-buffer sticky-agenda-buffer)
                          (org-agenda nil key))
                      (if-let ((orig-window (get-buffer-window orig-buffer)))
                          (select-window orig-window)
                        (switch-to-buffer orig-buffer)))))))
             ((and (get-buffer org-agenda-buffer-name)
                   (or (not (eq 'confirm org-starter-refresh-agenda-on-redefinition))
                       (yes-or-no-p (format "Run agenda %s immediately?" key))))
              (let ((agenda-window (get-buffer-window org-agenda-buffer-name t))
                    (orig-buffer (window-buffer)))
                (unwind-protect
                    (if agenda-window
                        (with-selected-window agenda-window
                          (let ((org-agenda-window-setup 'current-window))
                            (org-agenda nil key)))
                      (org-starter-agenda-with-window-setup nil key))
                  (if-let ((orig-window (get-buffer-window orig-buffer)))
                      (select-window orig-window)
                    (switch-to-buffer orig-buffer)))))))
          `(,key ,desc ,@args))
      (push `(,key ,desc ,@args) org-agenda-custom-commands))))

(defun org-starter--agenda-current-window (&rest args)
  "Call `org-agenda' with ARGS in the current window."
  (let ((orig-value org-agenda-window-setup))
    (setq org-agenda-window-setup 'current-window)
    (unwind-protect
        (apply #'org-agenda args)
      (setq org-agenda-window-setup orig-value))))

(defun org-starter-agenda-with-window-setup (&rest args)
  "Run `org-agenda' with ARGS with `org-starter-override-agenda-window-setup'."
  (let ((orig-buffer (window-buffer))
        (org-agenda-window-setup (or org-starter-override-agenda-window-setup
                                     org-agenda-window-setup)))
    (apply #'org-agenda args)
    (select-window (get-buffer-window orig-buffer))))

;;;###autoload
(cl-defun org-starter-add-block-agenda-command (key desc
                                                    &rest list-of-type-match-settings-files
                                                    &key settings files
                                                    &allow-other-keys)
  "Define a block agenda.

An entry consisting KEY, DESC, LIST-OF-TYPE-MATCH-SETTINGS-FILES,
SETTINGS, and FILES are added to `org-agenda-custom-commands'."
  (declare (indent 2))
  (cl-remf list-of-type-match-settings-files :settings)
  (cl-remf list-of-type-match-settings-files :files)
  (org-starter-add-agenda-custom-command key desc
    list-of-type-match-settings-files settings files))

(defconst org-starter-agenda-allowed-types
  '(agenda todo search tags-tags-todo todo-tree tags-tree))

(defun org-starter--verify-agenda-type (type &optional verbose)
  "Check if an agenda type is an allowed value.

This function checks if TYPE is a value allowed in
`org-agenda-custom-commands'.

If the value is correct, the function returns non-nil.

If VERBOSE is non-nil, displays an error instead if returning
nil."
  (or (or (member type org-starter-agenda-allowed-types)
          (functionp type)
          ;; block agenda
          (listp type))
      (and verbose
           (user-error "An agenda TYPE must be one of %s, a function, or a list"
                       org-starter-agenda-allowed-types))))

;;;; File operations

;;;###autoload
(defun org-starter-add-to-refile-targets ()
  "Add the current buffer to `org-refile-targets' temporarily."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))
  (if-let ((filename (buffer-file-name)))
      (when (or (not (cl-member filename org-refile-targets
                                :test #'file-equal-p))
                (yes-or-no-p (message "org-refile-targets already includes %s.\nAre you sure you want to override the entry?"
                                      filename)))
        (cl-case (read-char "Refile target type [l: level, m: maxlevel, q: tag, t: todo, r: regexp]: ")
          (?l (org-starter--add-refile-target filename
                `(:level . ,(org-starter--read-refile-level))))
          (?m (org-starter--add-refile-target filename
                `(:maxlevel . ,(org-starter--read-refile-level))))
          (?q (org-starter--add-refile-target filename
                `(:tag . ,(org-starter--read-refile-level))))
          (?t (org-starter--add-refile-target filename
                `(:tag . ,(org-starter--read-refile-level))))
          (?r (org-starter--add-refile-target filename
                `(:regexp . ,(org-starter--read-refile-level))))))
    (user-error "Not visiting a file")))

(defun org-starter--read-refile-level ()
  "Read a character between 0 and 9 and return the number."
  (let ((level-char (read-char "Refile level [0-9]: ")))
    (if (and (>= level-char ?0) (<= level-char ?9))
        (- level-char ?0)
      (user-error "Please enter a character between 0 and 9"))))

(defun org-starter--read-tag (prompt)
  "Read Org tag with PROMPT."
  (completing-read prompt 'org-tags-completion-function))

(defun org-starter--add-refile-target (filename spec)
  "Add a pair of FILENAME and SPEC to `org-refile-targets'."
  (declare (indent 1))
  (let ((existing (cl-assoc filename org-refile-targets :test #'file-equal-p)))
    (if existing
        (push (cons filename spec) org-refile-targets)
      (setcdr existing spec))))

;;;; Miscellaneous functionality

;;;###autoload
(defun org-starter-cleanup-entries (&optional all)
  "Remove missing files and directories from various variables.

This function removes files and directories that no longer exists from the
following variables:

- `org-starter-known-directories'
- `org-starter-known-files'

If ALL is non-nil, variable `org-agenda-files' and
`org-refile-targets' are also checked for missing entries."
  (interactive "P")
  (cl-remove-if-not #'file-directory-p org-starter-known-directories)
  (cl-remove-if-not #'file-exists-p org-starter-known-files)
  (when all
    (cl-remove-if-not #'file-exists-p org-agenda-files)
    (cl-remove-if (lambda (pair)
                    (let ((path (car pair)))
                      (and (stringp path)
                           (not (file-exists-p path)))))
                  org-refile-targets)))

;;;###autoload
(defun org-starter-verify-configuration ()
  "Check the current configuration."
  (interactive)
  (org-starter--clear-errors)
  (cl-loop for fpath in org-starter-known-files
           unless (file-exists-p fpath)
           do (when (yes-or-no-p (format "%s no longer exists. Delete it from the known file list?"
                                         fpath))
                (org-starter-undefine-file fpath)))
  (org-starter--when-let* ((deprecated-files (cl-remove-if-not #'file-exists-p
                                                               org-starter-deprecated-files)))
    (org-starter--log-error-no-newline "%d deprecated files still exist:\n%s"
                                       (length deprecated-files)
                                       (cl-loop for fpath in deprecated-files
                                                concat (format "- %s\n"
                                                               (abbreviate-file-name fpath)))))
  (if org-starter-found-errors
      (progn
        (pop-to-buffer org-starter-error-buffer)
        (message "%d errors found" org-starter-found-errors))
    (message "No error")))

(defun org-starter-sparse-tree-on-file (file)
  "Run `org-sparse-tree' on FILE."
  (find-file file)
  (call-interactively #'org-sparse-tree))

;;;; Loading files

(defun org-starter--load-file (fpath)
  "If there is no buffer visiting FPATH, load it into Emacs.

Unlike `find-file-noselect', this function does not care about changes in files
that are already loaded."
  (unless (find-buffer-visiting fpath)
    (let* ((default-directory (file-name-directory fpath))
           (enable-local-variables (or org-starter-enable-local-variables
                                       enable-local-variables))
           (buf (find-file-noselect fpath)))
      ;; TODO: Set options
      ;; (with-current-buffer buf)
      buf)))

(defun org-starter--ad-around-find-file-noselect (orig filename &rest args)
  "Advice around `find-file-noselect'.

ORIG is the original function of `find-file-noselect'.

If FILENAME is an Org file as defined by `org-agenda-file-regexp'
and included in `org-starter-known-files', the adviced function
alternates the value of `enable-local-variables' variable so
`org-starter-enable-local-variables' is respected.

ARGS is the rest of arguments passed to the function."
  (if (and (string-match-p org-agenda-file-regexp filename)
           (cl-member filename org-starter-known-files :test #'file-equal-p))
      (let* ((enable-local-variables
              (or org-starter-enable-local-variables
                  (let ((default-directory (file-name-directory filename)))
                    enable-local-variables))))
        (apply orig filename args))
    (apply orig filename args)))

(cl-defun org-starter--complete-file (prompt &key exclude-loaded-files)
  "Select a known file or an agenda file using `completing-read'.

PROMPT is the prompt displayed in the selection interface.

When EXCLUDE-LOADED-FILES is set to non-nil, exclude files that have
been loaded."
  (expand-file-name
   (completing-read prompt
                    (cl-remove-if
                     (lambda (fpath)
                       (and exclude-loaded-files
                            (find-buffer-visiting fpath)))
                     (cl-remove-duplicates
                      (mapcar #'abbreviate-file-name
                              (append org-starter-known-files
                                      (org-agenda-files)))
                      :test #'string-equal))
                    nil 'require-match)))

;;;###autoload
(defun org-starter-select-file (prompt)
  "Select a file from known files and agenda files.

This function select an Org file using `completing-read' with PROMPT.

If this function is called interactively, it visits the selected file.
If a prefix argument is given, it visits the selected file in
other window.

If this function is called non-interactively, it returns the file path
of the selected file."
  (interactive
   (list "Select an Org file: "))
  (let ((file (org-starter--complete-file prompt)))
    (if (called-interactively-p nil)
        (if current-prefix-arg
            (find-file-other-window file)
          (find-file file))
      file)))

;;;###autoload
(defun org-starter-select-file-other-window ()
  "A variant of `org-starter-select-file' targetting other window."
  (interactive)
  (find-file-other-window
   (org-starter-select-file "Select an Org file in other window: ")))

;;;###autoload
(defun org-starter-select-file-alternative ()
  "Select a file and visit it using the alternative command.

This function behaves like `org-starter-select-file' but uses
`org-starter-alternative-find-function' to visit a selected file."
  (interactive)
  (funcall org-starter-alternative-find-function
           (org-starter--complete-file
            "Visit a file using the alternative command: ")))

;;;###autoload
(defun org-starter-load-file (file)
  "Load FILE using org-starter."
  (interactive (list (org-starter--complete-file "Load an Org file: "
                                                 :exclude-loaded-files t)))
  (if (cl-member file org-starter-known-files :test #'file-equal-p)
      (org-starter--load-file file)
    (error "%s is not in org-starter-known-files" file)))

;;;###autoload
(defun org-starter-load-all-known-files ()
  "Load all files registered in `org-starter-known-files' into Emacs.

This can be convenient in some situations where you want ensure that all org
files are in buffers."
  (interactive)
  (mapc #'org-starter--load-file org-starter-known-files))

(defun org-starter-get-all-files-in-path ()
  "Get a list of org files in `org-starter-path'.

`org-agenda-file-regexp' is used to match the files."
  (cl-loop for dpath in org-starter-path
           append (directory-files dpath t org-agenda-file-regexp)))

;;;###autoload
(defun org-starter-load-all-files-in-path ()
  "Load all org files in `org-starter-path' into Emacs.

This can be convenient in some situations where you want ensure that all org
files are in buffers.

`org-starter-get-all-files-in-path' is used to get a list of org files."
  (interactive)
  (mapc #'org-starter--load-file (org-starter-get-all-files-in-path)))

;;;; Loading external config files

;;;###autoload
(defun org-starter-load-config-files ()
  "Load config files in `org-starter-path'."
  (interactive)
  (mapc #'load-file (org-starter--get-existing-config-files))
  (setq org-starter-suppress-override-messages-once nil))

(defun org-starter--get-existing-config-files (&optional dirs)
  "Return a list of existing config files.

DIRS is a list of directories to check.
If it is non-nil, search config files from the directories.
Otherwise, it searches from `org-starter-path'."
  (org-starter--get-files-in-path org-starter-config-file-name dirs))

(defun org-starter--get-files-in-path (filename &optional dirs)
  "Return a list of files in the path with a particular file name.

This function looks for files with FILENAME in directories. By
default, the directories are `org-starter-path', but you can also
specify DIRS.

It returns only existing files."
  (let ((dirs (or dirs org-starter-path)))
    (->> (if org-directory
             (cons org-directory
                   (cl-remove org-directory dirs :test #'file-equal-p))
           (copy-sequence dirs))
         (-map #'expand-file-name)
         (funcall (-flip #'-difference)
                  (-map #'expand-file-name
                        org-starter-prevent-local-config-directories))
         (--map (concat (file-name-as-directory it) filename))
         (-filter #'file-exists-p))))

;; Export it as a utility function
;;;###autoload
(defalias 'org-starter-get-files-in-path #'org-starter--get-files-in-path)

;;;###autoload
(defun org-starter-find-config-file ()
  "Visit an existing config file for org-starter."
  (interactive)
  (find-file (completing-read "Config file: "
                              (org-starter--get-existing-config-files)
                              nil t)))

;;;; UI utilities

(defun org-starter--display-options (header items)
  "Display items possibly in a child frame.

HEADER is a line inserted at the beginning of the string,
ITEMS is a list of strings."
  (if (and org-starter-use-child-frame
           (or (require 'posframe nil t)
               (progn
                 (message "org-starter: posframe is not installed, so falling back to the echo area")
                 nil))
           ;; Child frames don't work well by default in EXWM,
           ;; but it is up to the user to work around this issue.
           ;; (not (derived-mode-p 'exwm-mode))
           (or (posframe-workable-p)
               (progn
                 (message "org-starter: posframe does not work here, so falling back to the echo area")
                 nil)))
      (let ((lines (cons header
                         (org-starter--format-table
                          items
                          (min 80 (frame-width))))))
        (posframe-show org-starter-message-buffer
                       :internal-border-width org-starter-child-frame-border-width
                       :internal-border-color org-starter-child-frame-border-color
                       :foreground-color org-starter-child-frame-foreground-color
                       :background-color org-starter-child-frame-background-color
                       :override-parameters org-starter-child-frame-override-parameters
                       :string (string-join lines "\n")
                       :height (1+ (length lines))
                       :width (-max (-map #'length lines))
                       :poshandler org-starter-child-frame-poshandler)
        (add-hook 'pre-command-hook #'org-starter--delete-message-frame))
    (message (string-join
              (cons header
                    (org-starter--format-table items
                                               (frame-width)))
              "\n"))))

(defun org-starter--format-table (cells frame-width)
  "Format CELLS in columns in FRAME-WIDTH in total."
  (let* ((cell-width (min 24 (-max (-map #'length cells))))
         (cols (/ frame-width (1+ cell-width)))
         (rows (-partition-all cols cells)))
    (-map (lambda (cells)
            (mapconcat (lambda (content)
                         (if (> (length content) cell-width)
                             (substring content 0 cell-width)
                           (concat content
                                   (make-string (- cell-width (length content))
                                                32))))
                       cells " "))
          rows)))

(defun org-starter--delete-message-frame ()
  "Delete the child frame for messages."
  (posframe-delete-frame org-starter-message-buffer)
  (remove-hook 'pre-command-hook #'org-starter--delete-message-frame))

(provide 'org-starter)
;;;; Load external configuration files
(when org-starter-load-config-files
  ;; If Emacs has been started. load the files immediately.
  (if after-init-time
      (org-starter-load-config-files)
    ;; Otherwise, load them after startup.
    (setq org-starter-suppress-override-messages-once t)
    (add-hook 'after-init-hook #'org-starter-load-config-files)))
;;; org-starter.el ends here
