;;; age.el --- The Age Encryption Library -*- lexical-binding: t -*-

;; EPG/EPA modified to work with Age: https://github.com/FiloSottile/age

;; Author: Daiki Ueno <ueno@unixuser.org>
;;        Bas Alberts <bas@anti.computer>
;;
;; Maintainer: Bas Alberts <bas@anti.computer>
;; Homepage: https://github.com/anticomputer/age.el
;; Package-Requires: ((emacs "28.1"))
;; Package-Version: 20230109.2139
;; Package-Commit: 045c3f9127b431d4dd61e855b7d1c3fa92d6cf91
;; Keywords: data
;; Version: 0.1.4

;; This file is NOT part of GNU Emacs.

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

;; age.el provides transparent Age file encryption and decryption in Emacs. It
;; is based on the Emacs EasyPG code and offers similar Emacs file handling
;; for Age encrypted files.

;; Using age.el you can, for example, maintain .org.age encrypted Org files,
;; provide Age encrypted authentication information out of .authinfo.age, and
;; open/edit/save Age encrypted files via TRAMP.

;;; Code:

(require 'rfc6068)
(eval-when-compile (require 'cl-lib))
(eval-when-compile (require 'subr-x))
(eval-when-compile (require 'tramp-sh))

;;; Configuration

(defconst age-package-name "age"
  "Name of this package.")

(defconst age-version-number "0.1.4"
  "Version number of this package.")

;;; Options

(defgroup age ()
  "Interface to Age."
  :tag "Age"
  :group 'data
  :group 'external)

(defcustom age-default-recipient (expand-file-name "~/.ssh/id_rsa.pub")
  "Default recipient to use for age (public key).

This file can contain multiple recipients, one per line.

This variable can be a string representing a public key, a file path
to a collection of public keys, or a list with a mix of both.

By default it is a file path.

A nil value indicates that you want to use passphrase encryption only.
This is mostly provided for let-binding convenience."
  :type 'file)

(defcustom age-default-identity (expand-file-name "~/.ssh/id_rsa")
  "Default identity to use for age (private key).

This file can contain multiple identities, one per line.

This variable can be a file path to a collection of private keys, or
a list of file paths to collections of private keys.

A nil value indicates that you want to use passphrase decryption only.
This is mostly provided for let-binding convenience."
  :type 'file)

(defcustom age-always-use-default-keys t
  "If non-nil, use default identities and recipients without nagging."
  :type 'boolean)

(defcustom age-program (executable-find "age")
  "Say what age program to prefer."
  :type 'string)

(defcustom age-passphrase-coding-system nil
  "Coding system to use with messages from `age-program'."
  :type 'symbol)

;; In the doc string below, we say "symbol `error'" to avoid producing
;; a hyperlink for `error' the function.
(defcustom age-pinentry-mode nil ;; XXX: leaving this in for now
  "The pinentry mode."
  :type '(choice (const nil)
		 (const ask)
		 (const cancel)
		 (const error)))

(defcustom age-debug nil
  "If non-nil, debug output goes to the \"*age-debug*\" buffer."
  :type 'boolean)

;;; Constants

(defconst age-minimum-version "1.0.0")

(defconst age-config--program-alist
  `((Age
     age-program
     ("rage" . "0.9.0")
     ("age" . ,age-minimum-version)))
  "Alist used to obtain the usable configuration of executables.
The first element of each entry is protocol symbol, which is
`Age'.  The second element is a symbol where the executable name
is remembered.  The rest of the entry is an alist mapping executable
names to the minimum required version suitable for the use with Emacs.")

(defconst age-config--configuration-constructor-alist
  '((Age . age-config--make-age-configuration))
  "Alist used to obtain the usable configuration of executables.
The first element of each entry is protocol symbol, which is
either `Age'.  The second element is a function which constructs
a configuration object (actually a plist).")

;;; "Configuration"

(defvar age--configurations nil)

;;;###autoload
(defun age-find-configuration (protocol &optional no-cache program-alist)
  "Find or create a usable configuration to handle PROTOCOL.
This function first looks at the existing configuration found by
the previous invocation of this function, unless NO-CACHE is non-nil.

Then it walks through PROGRAM-ALIST or
`age-config--program-alist'.  If `age-program' is already set
with custom, use it.

Otherwise, it tries the programs listed in the entry until the
version requirement is met."
  (unless program-alist
    (setq program-alist age-config--program-alist))
  (let ((entry (assq protocol program-alist)))
    (unless entry
      (error "Unknown protocol `%S'" protocol))
    (cl-destructuring-bind (symbol . alist)
        (cdr entry)
      (let ((constructor
             (alist-get protocol age-config--configuration-constructor-alist)))
        (or (and (not no-cache) (alist-get protocol age--configurations))
            ;; If the executable value is already set with M-x
            ;; customize, use it without checking.
            (if (and symbol (or (get symbol 'saved-value)
                                (get symbol 'customized-value)))
                (let ((configuration
                       (funcall constructor (symbol-value symbol))))
                  (push (cons protocol configuration) age--configurations)
                  configuration)
              (catch 'found
                (dolist (program-version alist)
                  (let ((executable (executable-find (car program-version))))
                    (when executable
                      (let ((configuration
                             (funcall constructor executable)))
                        (when (ignore-errors
                                (age-check-configuration configuration
                                                         (cdr program-version))
                                t)
                          (unless no-cache
                            (push (cons protocol configuration)
                                  age--configurations))
                          (throw 'found configuration)))))))))))))

;; Create an `age-configuration' object for `age', using PROGRAM.
(defun age-config--make-age-configuration (program)
  "Make an age configuration for PROGRAM."
  (let ((version
         (let ((v (shell-command-to-string (format "%s --version" program))))
           ;; assuming https://semver.org/
           (when (string-match "\\([0-9]+\\.[0-9]+\\.[0-9]+\\)" v)
             (match-string 1 v)))))
    (list (cons 'program program)
          (cons 'version version))))

;;;###autoload
(defun age-configuration ()
  "Return a list of internal configuration parameters of `age-program'."
  (age-config--make-age-configuration age-program))

;;;###autoload
(defun age-check-configuration (config &optional req-versions)
  "Verify that a sufficient version of Age is installed.
CONFIG should be a `age-configuration' object (a plist).
REQ-VERSIONS should be a list with elements of the form (MIN
. MAX) where MIN and MAX are version strings indicating a
semi-open range of acceptable versions.  REQ-VERSIONS may also be
a single minimum version string."
  (let ((version (alist-get 'version config)))
    (unless (stringp version)
      (error "Undetermined version: %S" version))
    (catch 'version-ok
      (pcase-dolist ((or `(,min . ,max)
                         (and min (let max nil)))
                     (if (listp req-versions) req-versions
                       (list req-versions)))
        (when (and (version<= (or min age-minimum-version)
                              version)
                   (or (null max)
                       (version< version max)))
          (throw 'version-ok t)))
      (error "Unsupported version: %s" version))))

(defun age-required-version-p (protocol required-version)
  "Verify a sufficient version of Age for specific protocol.
PROTOCOL is `Age'.  REQUIRED-VERSION is a string containing
the required version number.  Return non-nil if that version
or higher is installed."
  (let ((version (cdr (assq 'version (age-find-configuration protocol)))))
    (and (stringp version)
         (version<= required-version version))))

(define-error 'age-error "Age error")

;;; Variables

(defvar age-read-point nil)
(defvar age-process-filter-running nil)
(defvar age-context nil)
(defvar age-debug-buffer nil)

;;; Enums

(defconst age-invalid-recipients-reason-alist
  '((0 . "unknown recipient type")))

(defconst age-no-data-reason-alist
  '((1 . "did you mean to use -a/--armor")))

(defconst age-unexpected-reason-alist nil)

(defvar age-prompt-alist nil)

;;; Structs

;;;; Data Struct

(cl-defstruct (age-data
               (:constructor nil)
               (:constructor age-make-data-from-file (file))
               (:constructor age-make-data-from-string (string))
               (:copier nil)
               (:predicate nil))
  (file nil :read-only t)
  (string nil :read-only t))

;;;; Context Struct

(cl-defstruct (age-context
               (:constructor nil)
               (:constructor age-context--make
                             (protocol &optional armor
                                       &aux
                                       (program
                                        (let ((configuration (age-find-configuration protocol)))
                                          (unless configuration
                                            (signal 'age-error
                                                    (list "no usable configuration" protocol)))
                                          (alist-get 'program configuration)))))
               (:copier nil)
               (:predicate nil))
  protocol
  program
  armor
  passphrase
  (passphrase-callback (list #'age-passphrase-callback-function))
  edit-callback
  process
  output-file
  result
  operation
  (pinentry-mode age-pinentry-mode)
  (error-output "")
  error-buffer)

;;;; Context Methods

(cl-defmacro age-with-dev-shm (&body body)
  "Bind variable `temporary-file-directory' to /dev/shm for BODY."
  `(let ((temporary-file-directory
          (if (file-directory-p "/dev/shm/")
              "/dev/shm/"
            ,temporary-file-directory)))
     ,@body))

;; This is not an alias, just so we can mark it as autoloaded.
;;;###autoload
(defun age-make-context (&optional protocol armor)
  "Return a context object for PROTOCOL with ARMOR."
  (age-context--make (or protocol 'Age) armor))

;; XXX: unused currently, so... untested.
(defun age-context-set-passphrase-callback (context
					    passphrase-callback)
  "Set the function used to query passphrase for CONTEXT.

PASSPHRASE-CALLBACK is either a function, or a cons-cell whose
car is a function and cdr is a callback data.

The function gets three arguments: the context, the key-id in
question, and the callback data (if any)."
  (setf (age-context-passphrase-callback context)
        (if (functionp passphrase-callback)
	    (list passphrase-callback)
	  passphrase-callback)))

;;; Functions

(defun age-context-result-for (context name)
  "Return the result of CONTEXT associated with NAME."
  (cdr (assq name (age-context-result context))))

(defun age-context-set-result-for (context name value)
  "Set the result of CONTEXT associated with NAME to VALUE."
  (let* ((result (age-context-result context))
	 (entry (assq name result)))
    (if entry
	(setcdr entry value)
      (setf (age-context-result context) (cons (cons name value) result)))))

(defun age-error-to-string (error)
  "Translate ERROR into a string."
  (cond
   ;; general age-error
   ((eq (car error) 'age-error)
    (cadr error))
   ;; XXX: give me a heads up if I'm not handling something yet
   (t (message "XXX: Translate this error: %s" error))))

(defun age-errors-to-string (errors)
  "Return a list of ERRORS as a string."
  (mapconcat #'age-error-to-string errors "; "))

(defun age--start (context args)
  "Start `age-program' in a subprocess with given ARGS for CONTEXT."
  (if (and (age-context-process context)
	   (eq (process-status (age-context-process context)) 'run))
      (error "%s is already running in this context"
	     (age-context-program context)))
  (let* ((args (append
		(if (age-context-armor context) '("--armor"))
		(if (age-context-output-file context)
		    (list "--output" (age-context-output-file context)))
		args))
	 (process-environment process-environment)
	 (buffer (generate-new-buffer " *age*"))
	 error-process
	 process)
    ;; XXX: don't need this, but probably will come in handy at some point
    (setq process-environment
	  (cons (format "INSIDE_EMACS=%s,age" emacs-version)
		process-environment))
    (if age-debug
	(save-excursion
	  (unless age-debug-buffer
	    (setq age-debug-buffer (generate-new-buffer "*age-debug*")))
	  (set-buffer age-debug-buffer)
	  (goto-char (point-max))))
    (with-current-buffer buffer
      (if (fboundp 'set-buffer-multibyte)
	  (set-buffer-multibyte nil))
      (setq-local age-read-point (point-min))
      (setq-local age-process-filter-running nil)
      (setq-local age-context context))
    ;; make sure our error buffer has access to buffer local context as well
    (let ((error-buffer (generate-new-buffer "*age-error")))
      (with-current-buffer error-buffer
        (setq-local age-context context))
      (setq error-process
	    (make-pipe-process :name "age-error"
			       :buffer error-buffer
			       ;; Suppress "XXX finished" line.
			       :sentinel #'ignore
                               :filter #'age--process-stderr-filter
			       :noquery t))
      (setf (age-context-error-buffer context) error-buffer))
    (with-existing-directory
      (with-file-modes 448
        (setq process (make-process :name "age"
				    :buffer buffer
				    :command (cons (age-context-program context)
						   args)
				    :connection-type 'pipe
				    :coding 'raw-text
				    :filter #'age--process-stdout-filter
				    :stderr error-process
				    :noquery t))))
    (setf (age-context-process context) process)))

(defun age--process-stdout-filter (_process input)
  "Filter for age client process stdout displaying INPUT in debug mode."
  (when age-debug
    (message "debug: age stdout: %s" input)))

(defun age--process-stderr-filter (process input)
  "Filter for age client PROCESS stderr INPUT."
  (when age-debug
    (with-current-buffer
        (or age-debug-buffer
            (setq age-debug-buffer (generate-new-buffer "*age-debug*")))
      (goto-char (point-max))
      (insert input)))
  (when (buffer-live-p (process-buffer process))
    (with-current-buffer (process-buffer process)
      (unless age-process-filter-running
        (let ((age-process-filter-running t))
          (string-match "\\(?:age: error:\\|Error:\\) \\(.*\\)" input)
          (let ((error-msg (match-string 1 input)))
            (when error-msg
              ;; age-context is buffer local
              (age-context-set-result-for age-context 'error `((age-error ,error-msg)))
              (age--status-AGE_FAILED age-context error-msg))))))))

(defun age-read-output (context)
  "Read the output file CONTEXT and return the content as a string."
  (with-temp-buffer
    (if (fboundp 'set-buffer-multibyte)
	(set-buffer-multibyte nil))
    (if (file-exists-p (age-context-output-file context))
	(let ((coding-system-for-read 'binary))
	  (insert-file-contents (age-context-output-file context))
	  (buffer-string)))))

(defun age-wait-for-completion (context)
  "Wait until the `age-program' process completes for CONTEXT."
  (while (eq (process-status (age-context-process context)) 'run)
    (accept-process-output (age-context-process context) 1))
  ;; This line is needed to run the process-filter right now.
  (sleep-for 0.1)
  (age-context-set-result-for
   context 'error
   (nreverse (age-context-result-for context 'error)))
  (setf (age-context-error-output context)
	(with-current-buffer (age-context-error-buffer context)
	  (buffer-string))))

(defun age-reset (context)
  "Reset the CONTEXT."
  (if (and (age-context-process context)
	   (buffer-live-p (process-buffer (age-context-process context))))
      (kill-buffer (process-buffer (age-context-process context))))
  (if (buffer-live-p (age-context-error-buffer context))
      (kill-buffer (age-context-error-buffer context)))
  (setf (age-context-process context) nil)
  (setf (age-context-edit-callback context) nil))

(defun age-delete-output-file (context)
  "Delete the output file of CONTEXT."
  (if (and (age-context-output-file context)
	   (file-exists-p (age-context-output-file context)))
      (delete-file (age-context-output-file context))))

;; XXX: completely untested, artifact from EPA's status handling
;; XXX: rework this when we get a pinentry solution available
(defun age--status-GET_PASSPHRASE (context string)
  "Retrieve a passphrase out of CONTEXT if STRING indicates a prompt."
  (when (string-match "\\`passphrase\\." string)
    (unless (age-context-passphrase-callback context)
      (error "Variable `passphrase-callback' not set"))
    (let (inhibit-quit
	  passphrase
	  passphrase-with-new-line
	  encoded-passphrase-with-new-line)
      (unwind-protect
	  (condition-case nil
	      (progn
		(setq passphrase
		      (funcall
		       (car (age-context-passphrase-callback context))
		       context
		       (cdr (age-context-passphrase-callback context))))
		(when passphrase
		  (setq passphrase-with-new-line (concat passphrase "\n"))
		  (clear-string passphrase)
		  (setq passphrase nil)
		  (if age-passphrase-coding-system
		      (progn
			(setq encoded-passphrase-with-new-line
			      (encode-coding-string
			       passphrase-with-new-line
			       (coding-system-change-eol-conversion
				age-passphrase-coding-system 'unix)))
			(clear-string passphrase-with-new-line)
			(setq passphrase-with-new-line nil))
		    (setq encoded-passphrase-with-new-line
			  passphrase-with-new-line
			  passphrase-with-new-line nil))
		  (process-send-string (age-context-process context)
				       encoded-passphrase-with-new-line)))
	    (quit
	     (age-context-set-result-for
	      context 'error
	      (cons '(quit)
		    (age-context-result-for context 'error)))
	     (delete-process (age-context-process context))))
	(if passphrase
	    (clear-string passphrase))
	(if passphrase-with-new-line
	    (clear-string passphrase-with-new-line))
	(if encoded-passphrase-with-new-line
	    (clear-string encoded-passphrase-with-new-line))))))

;;; Status Functions

(defun age--status-AGE_FAILED (context _string)
  "Set age status for CONTEXT to AGE_FAILED."
  (age-context-set-result-for context 'age-failed t))

;;; Public Functions

(defun age-cancel (context)
  "Cancel the age client process for CONTEXT."
  (if (buffer-live-p (process-buffer (age-context-process context)))
      (with-current-buffer (process-buffer (age-context-process context))
	(age-context-set-result-for
	 age-context 'error
	 (cons '(quit)
	       (age-context-result-for age-context 'error)))))
  (if (eq (process-status (age-context-process context)) 'run)
      (delete-process (age-context-process context))))

(defun age-start-decrypt (context cipher)
  "Initiate a decrypt operation on CIPHER for CONTEXT.
CIPHER must be a file data object.

If you use this function, you will need to wait for the completion of
`age-program' by using `age-wait-for-completion' and call
`age-reset' to clear a temporary output file.
If you are unsure, use synchronous version of this function
`age-decrypt-file' or `age-decrypt-string' instead."
  (unless (age-data-file cipher)
    (error "Not a file"))
  (setf (age-context-operation context) 'decrypt)
  (setf (age-context-result context) nil)
  (let ((identity
         ;; only nag if we're not in passphrase mode
         (unless (or (age-context-passphrase context) (not age-default-identity))
           (if (or age-always-use-default-keys
                   (y-or-n-p "Use default identity? "))
               age-default-identity
             (expand-file-name (read-file-name "Path to identity: " (expand-file-name "~/")))))))
    (age--start context
                (append '("--decrypt")
                        ;; identity may be a list of identities, skip in passphrase mode
                        (unless (or (age-context-passphrase context) (not age-default-identity))
                          (if (listp identity)
                              (apply #'nconc
			             (mapcar
			              (lambda (id)
                                        (when age-debug
                                          (message "Adding id: %s" id))
                                        (when (file-exists-p (expand-file-name id))
                                          (list "-i" (expand-file-name id))))
			              identity))
                            (list "-i" (expand-file-name identity))))
                        (list "--" (age-data-file cipher))))))

(defun age--check-error-for-decrypt (context)
  "Check CONTEXT for decrypt errors."
  (let ((errors (age-context-result-for context 'error)))
    (if (age-context-result-for context 'age-failed)
	(signal 'age-error
		(list "Age failed with error" (age-errors-to-string errors))))))

(defun age-decrypt-file (context cipher plain)
  "Decrypt a file CIPHER under CONTEXT and store the result to a file PLAIN.
If PLAIN is nil, it returns the result as a string."
  (unwind-protect
      (progn
	(setf (age-context-output-file context)
              (or plain (age-with-dev-shm (make-temp-file "age-output"))))
        (age-start-decrypt context (age-make-data-from-file cipher))
        (age-wait-for-completion context)
	(age--check-error-for-decrypt context)
        (unless plain
	  (age-read-output context)))
    (unless plain
      (age-delete-output-file context))
    (age-reset context)))

(defun age-decrypt-string (context cipher)
  "Decrypt a string CIPHER under CONTEXT and return the plain text."
  (let ((input-file (age-with-dev-shm (make-temp-file "age-input")))
	(coding-system-for-write 'binary))
    (unwind-protect
	(progn
	  (write-region cipher nil input-file nil 'quiet)
	  (setf (age-context-output-file context)
                (age-with-dev-shm (make-temp-file "age-output")))
	  (age-start-decrypt context (age-make-data-from-file input-file))
	  (age-wait-for-completion context)
	  (age--check-error-for-decrypt context)
	  (age-read-output context))
      (age-delete-output-file context)
      (if (file-exists-p input-file)
	  (delete-file input-file))
      (age-reset context))))

(defun age-start-encrypt (context plain recipients)
  "Initiate an encrypt operation on PLAIN under CONTEXT for RECIPIENTS.
PLAIN is a data object.
If RECIPIENTS is nil, it performs symmetric encryption.

If you use this function, you will need to wait for the completion of
`age-program' by using `age-wait-for-completion' and call
`age-reset' to clear a temporary output file.
If you are unsure, use synchronous version of this function
`age-encrypt-file' or `age-encrypt-string' instead."
  (setf (age-context-operation context) 'encrypt)
  (setf (age-context-result context) nil)
  (let ((recipients
         ;; ... unless we're in passphrase mode :P
         (unless (or (age-context-passphrase context) (not age-default-recipient))
           (or recipients
               (age-select-keys
                context
                "Select recipients for encryption.")))))
    (age--start
     context
     ;; if recipients is nil, we go to the default identity
     (append
      '("--encrypt")
      ;; only add recipients if we're not in passphrase mode
      (if (or (age-context-passphrase context) (not age-default-recipient))
          ;; passphrase mode, requires rage for pinentry support
          (list "-p")
        ;; recipient mode
	(apply #'nconc
	       (mapcar
		(lambda (recipient)
                  ;; recipients is a list of age public keys
                  (when age-debug
                    (message "Adding recipient: %s" recipient))
                  (if (file-exists-p (expand-file-name recipient))
                      (progn
                        (when age-debug
                          (message "Adding file based recipient(s)."))
                        (list "-R" (expand-file-name recipient)))
                    (when age-debug
                      (message "Adding string based recipient."))
		    (list "-r" recipient)))
		recipients)))
      (if (age-data-file plain)
	  (list "--" (age-data-file plain))))))
  (when (age-data-string plain)
    (if (eq (process-status (age-context-process context)) 'run)
	(process-send-string (age-context-process context)
			     (age-data-string plain)))
    (if (eq (process-status (age-context-process context)) 'run)
	(process-send-eof (age-context-process context)))))

(defun age-encrypt-file (context plain recipients cipher)
  "Encrypt a file PLAIN under CONTEXT and store the result to a file CIPHER.
If CIPHER is nil, it returns the result as a string.
If RECIPIENTS is nil, it performs symmetric encryption."
  (unwind-protect
      (progn
        (setf (age-context-output-file context)
              (or cipher (age-with-dev-shm (make-temp-file "age-output"))))
	(age-start-encrypt context (age-make-data-from-file plain) recipients)
	(age-wait-for-completion context)
	(let ((errors (age-context-result-for context 'error)))
	  (if errors
	      (signal 'age-error
		      (list "Encrypt failed" (age-errors-to-string errors)))))
	(unless cipher
	  (age-read-output context)))
    (unless cipher
      (age-delete-output-file context))
    (age-reset context)))

(defun age-encrypt-string (context plain recipients)
  "Encrypt a string PLAIN under CONTEXT.
If RECIPIENTS is nil, it performs symmetric encryption."
  (let ((input-file
         ;; XXX: this is always true, but keep the protocol flexibility for now
	 (when (eq (age-context-protocol context) 'Age)
	   (age-with-dev-shm (make-temp-file "age-input"))))
	(coding-system-for-write 'binary))
    (unwind-protect
	(progn
	  (setf (age-context-output-file context)
                (age-with-dev-shm (make-temp-file "age-output")))
	  (if input-file
	      (write-region plain nil input-file nil 'quiet))
	  (age-start-encrypt context
			     (if input-file
				 (age-make-data-from-file input-file)
			       (age-make-data-from-string plain))
			     recipients)
	  (age-wait-for-completion context)
	  (let ((errors (age-context-result-for context 'error)))
	    (if errors
		(signal 'age-error
			(list "Encrypt failed" (age-errors-to-string errors)))))
	  (age-read-output context))
      (age-delete-output-file context)
      (if input-file
	  (delete-file input-file))
      (age-reset context))))

;;; Decode Functions

(defun age--decode-percent-escape (string)
  "Decode percent escapes in STRING."
  (setq string (encode-coding-string string 'raw-text))
  (let ((index 0))
    (while (string-match "%\\(\\(%\\)\\|\\([[:xdigit:]][[:xdigit:]]\\)\\)"
			 string index)
      (if (match-beginning 2)
	  (setq string (replace-match "%" t t string)
		index (1- (match-end 0)))
	(setq string (replace-match
		      (byte-to-string
                       (string-to-number (match-string 3 string) 16))
		      t t string)
	      index (- (match-end 0) 2))))
    string))

(defun age--decode-percent-escape-as-utf-8 (string)
  "Decode percent escape as utf-8 in STRING."
  (declare (obsolete rfc6068-unhexify-string "28.1"))
  (decode-coding-string (age--decode-percent-escape string) 'utf-8))

(defun age--decode-hexstring (string)
  "Decode hexstring in STRING."
  (declare (obsolete rfc6068-unhexify-string "28.1"))
  (let ((index 0))
    (while (eq index (string-match "[[:xdigit:]][[:xdigit:]]" string index))
      (setq string (replace-match (string (string-to-number
					   (match-string 0 string) 16))
				  t t string)
	    index (1- (match-end 0))))
    string))

(defun age--decode-quotedstring (string)
  "Decode quotedstring STRING."
  (let ((index 0))
    (while (string-match "\\\\\\(\\([,=+<>#;\\\"]\\)\\|\
\\([[:xdigit:]][[:xdigit:]]\\)\\)"
			 string index)
      (if (match-beginning 2)
	  (setq string (replace-match "\\2" t nil string)
		index (1- (match-end 0)))
	(if (match-beginning 3)
	    (setq string (replace-match (string (string-to-number
						 (match-string 0 string) 16))
					t t string)
		  index (- (match-end 0) 2)))))
    string))

;;; File mode hooks

(defcustom age-file-name-regexp "\\.age\\'"
  "Age file name regexp."
  :type 'regexp
  :group 'age-file)

(defcustom age-file-inhibit-auto-save t
  "If non-nil, disable auto-saving when opening an encrypted file."
  :type 'boolean
  :group 'age-file)

(defvar age-file-encrypt-to nil
  "Recipient(s) used for encrypting files.
May either be a string or a list of strings.")

(put 'age-file-encrypt-to 'safe-local-variable
     (lambda (val)
       (or (stringp val)
	   (and (listp val)
		(catch 'safe
		  (mapc (lambda (elt)
			  (unless (stringp elt)
			    (throw 'safe nil)))
			val)
		  t)))))

(put 'age-file-encrypt-to 'permanent-local t)

(defvar age-file-handler
  (cons age-file-name-regexp 'age-file-handler))

(defvar age-file-auto-mode-alist-entry
  (list age-file-name-regexp nil 'age-file))

(defun age-file-find-file-hook ()
  "Age find file hook."
  (if (and buffer-file-name
	   (string-match age-file-name-regexp buffer-file-name)
	   age-file-inhibit-auto-save)
      (auto-save-mode 0)))

;;;###autoload
(define-minor-mode age-encryption-mode
  "Toggle automatic Age file encryption/decryption (Age Encryption mode)."
  :global t :init-value t :group 'age-file :version "0.1"
  ;;:initialize 'custom-initialize-delay
  (age-advise-tramp t)
  (setq file-name-handler-alist (delq age-file-handler file-name-handler-alist))
  (remove-hook 'find-file-hook #'age-file-find-file-hook)
  (setq auto-mode-alist (delq age-file-auto-mode-alist-entry auto-mode-alist))
  (when age-encryption-mode
    (age-advise-tramp)
    (setq file-name-handler-alist (cons age-file-handler file-name-handler-alist))
    (add-hook 'find-file-hook #'age-file-find-file-hook)
    (setq auto-mode-alist (cons age-file-auto-mode-alist-entry auto-mode-alist))))

(put 'age-file-handler 'safe-magic t)
(put 'age-file-handler 'operations '(write-region insert-file-contents))

;;; age-file

;;; Options

(defcustom age-file-cache-passphrase-for-symmetric-encryption nil
  "If non-nil, cache passphrase for symmetric encryption."
  :type 'boolean
  :group 'age-file)

(defcustom age-file-select-keys nil
  "Control whether or not to pop up the key selection dialog.

If t, always ask user to select recipients.
If nil, query user only when `age-file-encrypt-to' is not set.
If neither t nor nil, don't ask user.  In this case, symmetric
encryption is used."
  :type '(choice (const :tag "Ask always" t)
		 (const :tag "Ask when recipients are not set" nil)
		 (const :tag "Don't ask" silent))
  :group 'age-file)

;;; Other

(defvar age-file-passphrase-alist nil)

;; XXX: fixme when we have a pinentry available
(defun age-passphrase-callback-function (context handback)
  "Age passphrase callback under CONTEXT with HANDBACK."
  (read-passwd
   (format "Passphrase%s: "
	   ;; Add the file name to the prompt, if any.
	   (if (stringp handback)
	       (format " for %s" handback)
	     ""))
   (eq (age-context-operation context) 'encrypt)))

;; XXX: fixme when we have a pinentry available
(defun age-file-passphrase-callback-function (context _key-id file)
  "Age file passphrase callback under CONTEXT for FILE."
  (if age-file-cache-passphrase-for-symmetric-encryption
      (progn
        (setq file (file-truename file))
        (let ((entry (assoc file age-file-passphrase-alist))
	      passphrase)
	  (or (copy-sequence (cdr entry))
	      (progn
	        (unless entry
		  (setq entry (list file))
		  (setq age-file-passphrase-alist
		        (cons entry
			      age-file-passphrase-alist)))
	        (setq passphrase (age-passphrase-callback-function context
								   file))
	        (setcdr entry (copy-sequence passphrase))
	        passphrase))))
    (age-passphrase-callback-function context file)))

;;; Utilities

(defvar age-error-buffer nil)
(defvar age-suppress-error-buffer nil)

(defun age-display-error (context)
  "Display error for CONTEXT."
  (unless (or (equal (age-context-error-output context) "")
              age-suppress-error-buffer)
    (let ((buffer (get-buffer-create "*Error*")))
      (save-selected-window
	(unless (and age-error-buffer (buffer-live-p age-error-buffer))
	  (setq age-error-buffer (generate-new-buffer "*Error*")))
	(if (get-buffer-window age-error-buffer)
	    (delete-window (get-buffer-window age-error-buffer)))
	(with-current-buffer buffer
	  (let ((inhibit-read-only t)
		buffer-read-only)
	    (erase-buffer)
	    (insert (format
		     (pcase (age-context-operation context)
		       ('decrypt "Error while decrypting with \"%s\":")
		       ('encrypt "Error while encrypting with \"%s\":")
		       (_ "Error while executing \"%s\":\n\n"))
		     (age-context-program context))
		    "\n\n"
		    (age-context-error-output context)))
          (goto-char (point-min)))
	(display-buffer buffer)))))

;;; File Handler

(defvar age-inhibit nil
  "Non-nil means don't try to decrypt .age files when operating on them.")

(defun age-scrypt-p (file)
  "Check for passphrase scrypt stanza in age FILE."
  (when (file-exists-p (expand-file-name file))
    (with-temp-buffer
      ;; disable age file handling for this insert, we just want to grab a header
      (cl-letf (((symbol-value 'age-inhibit) t))
        (insert-file-contents-literally file nil 0 100))
      (let ((lines
             ;; grab the first two lines
             (cl-loop repeat 2
                      unless (eobp)
                      collect
                      (prog1 (buffer-substring-no-properties
                              (line-beginning-position)
                              (line-end-position))
                        (forward-line 1)))))
        ;; deal with empty/new files as well by checking for no lines
        (when (and lines (= (length lines) 2))
          ;; if the first line is the ascii armor marker, base64 decode the second line
          (let ((b64 (string-match-p
                      "-----BEGIN AGE ENCRYPTED FILE-----" (car lines)))
                (l2 (cadr lines)))
            ;; if the second line contains the scrypt stanza, it is a passphrase file
            (when (string-match-p "-> scrypt " (if b64 (base64-decode-string l2) l2))
              t)))))))

;;; TRAMP inhibit age advice

(defun age-inhibit-advice (orig-func &rest args)
  "This advice inhibits age file handling operations in ORIG-FUNC with ARGS."
  (cl-letf (((symbol-value 'age-inhibit) t))
    (apply orig-func args)))

(defvar age-tramp-inhibit-funcs
  #'(tramp-sh-handle-write-region
     tramp-do-copy-or-rename-file-via-buffer)
  "List of TRAMP functions to inhibit age.el file operations for.")

(defun age-advise-tramp (&optional remove)
  "This prevents TRAMP from triggering intermediate age file decryption operations.

Adds or optionally REMOVE's function `age-inhibit-advice' to|from all
functions listed in variable `age-tramp-inhibit-funcs'.

This is similar to how function `epa-file-handler' is inhibited, but since we're
not part of Emacs we have to advice TRAMP to inhibit function `age-file-handler'
instead."
  (cl-loop for tramp-func in age-tramp-inhibit-funcs
           for member = (advice-member-p #'age-inhibit-advice tramp-func)
           do
           (when age-debug (message "%s age inhibit advice for: %s"
                                    (if remove "Removing" "Adding") tramp-func))
           (if (and remove member)
               (advice-remove tramp-func #'age-inhibit-advice)
             (unless member
               (advice-add tramp-func :around #'age-inhibit-advice)))))

;;;###autoload
(defun age-file-handler (operation &rest args)
  "Run age file OPERATION handler with ARGS."
  (save-match-data
    (let ((op (get operation 'age-file)))
      (if (and op (not age-inhibit))
          (apply op args)
  	(age-file-run-real-handler operation args)))))

(defun age-file-run-real-handler (operation args)
  "Run age file OPERATION handler with ARGS."
  (let ((inhibit-file-name-handlers
	 (cons 'age-file-handler
	       (and (eq inhibit-file-name-operation operation)
		    inhibit-file-name-handlers)))
	(inhibit-file-name-operation operation))
    (apply operation args)))

(defun age-file-decode-and-insert (string file visit beg end replace)
  "Insert STRING as if it is read from FILE.
Optional arguments VISIT, BEG, END, and REPLACE are the same as those
of the function `insert-file-contents'"
  (save-restriction
    (narrow-to-region (point) (point))
    (insert string)
    (decode-coding-inserted-region
     (point-min) (point-max)
     (substring file 0 (string-match age-file-name-regexp file))
     visit beg end replace)
    (goto-char (point-max))
    (- (point-max) (point-min))))

(defvar age-file-error nil)
(defun age-file--find-file-not-found-function ()
  "File not found function."
  (let ((error age-file-error))
    (save-window-excursion
      (kill-buffer))
    (if (nth 3 error)
        (user-error "Wrong passphrase: %s" (nth 3 error))
      (signal 'file-missing
	      (cons "Opening input file" (cdr error))))))

(defun age--wrong-password-p (context)
  "Check for incorrect passphrase error in CONTEXT."
  (let ((error-string (age-context-error-output context)))
    (and (string-match "\\(incorrect passphrase\\)"
                       error-string)
         (match-string 1 error-string))))

(defvar last-coding-system-used)
(defun age-file-insert-file-contents (file &optional visit beg end replace)
  "Insert file contents for filename FILE.
Optional arguments VISIT, BEG, END and REPLACE are the same as those
of the function `insert-file-contents'."
  (barf-if-buffer-read-only)
  (if (and visit (or beg end))
      (error "Attempt to visit less than an entire file"))
  (setq file (expand-file-name file))
  (let* ((local-copy
	  (condition-case nil
	      (age-file-run-real-handler #'file-local-copy (list file))
	    (error)))
	 (local-file (or local-copy file))
	 (context (age-make-context))
         (buf (current-buffer))
	 string length entry)
    (if visit
	(setq buffer-file-name file))
    (setf (age-context-passphrase context) (age-scrypt-p file))
    (age-context-set-passphrase-callback
     context
     (cons #'age-file-passphrase-callback-function
	   local-file))
    (unwind-protect
	(progn
	  (condition-case error
	      (setq string (age-decrypt-file context local-file nil))
	    (error
             (if (setq entry (assoc file age-file-passphrase-alist))
		 (setcdr entry nil))
	     ;; If the decryption program can't be found,
	     ;; signal that as a non-file error
	     ;; so that find-file-noselect-1 won't handle it.
	     ;; Borrowed from jka-compr.el.
	     (if (and (memq 'file-error (get (car error) 'error-conditions))
		      (equal (cadr error) "Searching for program"))
		 (error "Decryption program `%s' not found"
			(nth 3 error)))
	     (let ((exists (file-exists-p local-file)))
	       (when exists
                 (if-let ((wrong-password (age--wrong-password-p context)))
                     ;; Don't display the *error* buffer if we just
                     ;; have a wrong password; let the later error
                     ;; handler notify the user.
                     (setq error (append error (list wrong-password)))
		   (age-display-error context))
                 (if (equal (caddr error) "Unexpected; Exit")
                     (setq string (with-temp-buffer
                                    (insert-file-contents-literally local-file)
                                    (buffer-string)))
		   ;; Hack to prevent find-file from opening empty buffer
		   ;; when decryption failed (bug#6568).  See the place
		   ;; where `find-file-not-found-functions' are called in
		   ;; `find-file-noselect-1'.
		   (setq-local age-file-error error)
		   (add-hook 'find-file-not-found-functions
			     #'age-file--find-file-not-found-function
			     nil t)))
	       (signal (if exists 'file-error 'file-missing)
		       (cons "Opening input file" (cdr error))))))
          (set-buffer buf) ;In case timer/filter changed/killed it (bug#16029)!
	  (setq-local age-file-encrypt-to
                      (mapcar #'car (age-context-result-for
                                     context 'encrypted-to)))
	  (if (or beg end)
              (setq string (substring string
                                      (or beg 0)
                                      (and end (min end (length string))))))
	  (save-excursion
	    ;; If visiting, bind off buffer-file-name so that
	    ;; file-locking will not ask whether we should
	    ;; really edit the buffer.
	    (let ((buffer-file-name
		   (if visit nil buffer-file-name)))
              (setq length
                    (if replace
                        (age-file--replace-text string file visit beg end)
		      (age-file-decode-and-insert
                       string file visit beg end replace))))
	    (if visit
		(set-visited-file-modtime))))
      (if (and local-copy
	       (file-exists-p local-copy))
	  (delete-file local-copy)))
    (list file length)))

(put 'insert-file-contents 'age-file 'age-file-insert-file-contents)

(defun age-file--replace-text (string file visit beg end)
  "Replace text with STRING for filename FILE.
The VISIT, BEG, END arguments are as described in the function
`age-file-decode-and-insert'"
  ;; The idea here is that we want to replace the text in the buffer
  ;; (for instance, for a `revert-buffer'), but we want to touch as
  ;; little of the text as possible.  So we compare the new and the
  ;; old text and only starts replacing when the text changes.
  (let ((orig-point (point))
        new-start length)
    (goto-char (point-max))
    (setq new-start (point))
    (setq length
	  (age-file-decode-and-insert
           string file visit beg end t))
    (if (equal (buffer-substring (point-min) new-start)
               (buffer-substring new-start (point-max)))
        ;; The new text is equal to the old, so just keep the old.
        (delete-region new-start (point-max))
      ;; Compute the region the hard way.
      (let ((p1 (point-min))
            (p2 new-start))
        (while (and (< p1 new-start)
                    (< p2 (point-max))
                    (eql (char-after p1) (char-after p2)))
          (cl-incf p1)
          (cl-incf p2))
        (delete-region new-start p2)
        (delete-region p1 new-start)))
    ;; Restore point, if possible.
    (if (< orig-point (point-max))
        (goto-char orig-point)
      (goto-char (point-max)))
    length))

(defvar age-armor t
  "Controls whether or not Age encrypted files will be ASCII armored.")

(defun age-select-keys (_context _msg &optional recipients)
  "Select the RECIPIENTS to encrypt to for the current age buffer."
  ;; file mode
  (let* ((selected-recipients
          ;; use age-file-encrypt-to if it's set, so we don't repeat the nag each save
          (cond (age-file-encrypt-to age-file-encrypt-to)
                ((or age-always-use-default-keys (y-or-n-p "Use default recipient(s)? "))
                 age-default-recipient)
                (t (expand-file-name (read-file-name "Path to recipient(s): "
                                                     (expand-file-name "~/")))))))
    ;; make sure this is buffer-local, after its set the first time, reuse it
    (setq-local age-file-encrypt-to
                (cond ((listp selected-recipients) (append recipients selected-recipients))
                      (t (append recipients (list selected-recipients)))))))

(defun age-file-write-region (start end file &optional append visit lockname mustbenew)
  "Write current region from START to END into specified FILE.
Optional arguments APPEND, VISIT, LOCKNAME, MUSTBENEW are as described in
function `write-region'."
  (if append
      (error "Can't append to the file"))
  (setq file (expand-file-name file))
  (let* ((coding-system (or coding-system-for-write
			    (if (fboundp 'select-safe-coding-system)
			        (let ((buffer-file-name file))
				  (select-safe-coding-system
				   (point-min) (point-max)))
			      buffer-file-coding-system)))
	 (context (age-make-context))
	 (coding-system-for-write 'binary)
	 string entry
	 (recipients
	  (cond
	   ((listp age-file-encrypt-to) age-file-encrypt-to)
	   ((stringp age-file-encrypt-to) (list age-file-encrypt-to))))
	 buffer)
    (setf (age-context-passphrase context) (age-scrypt-p file))
    (age-context-set-passphrase-callback
     context
     (cons #'age-file-passphrase-callback-function
	   file))
    (setf (age-context-armor context) age-armor)
    (condition-case error
	(setq string
	      (age-encrypt-string
	       context
	       (if (stringp start)
		   (encode-coding-string start coding-system)
		 (unless start
		   (setq start (point-min)
			 end (point-max)))
		 (setq buffer (current-buffer))
		 (with-temp-buffer
		   (insert-buffer-substring buffer start end)
		   ;; Translate the region according to
		   ;; `buffer-file-format', as `write-region' would.
		   ;; We can't simply do `write-region' (into a
		   ;; temporary file) here, since it writes out
		   ;; decrypted contents.
		   (format-encode-buffer (with-current-buffer buffer
					   buffer-file-format))
		   (encode-coding-string (buffer-string)
					 coding-system)))
	       (if (or (eq age-file-select-keys t)
		       (and (null age-file-select-keys)
			    (not (local-variable-p 'age-file-encrypt-to
						   (current-buffer)))))
		   (age-select-keys
		    context
		    "Select recipients for encryption."
		    recipients))))
      (error
       (age-display-error context)
       (if (setq entry (assoc file age-file-passphrase-alist))
	   (setcdr entry nil))
       (signal 'file-error (cons "Opening output file" (cdr error)))))
    (age-file-run-real-handler
     #'write-region
     (list string nil file append visit lockname mustbenew))
    (if (boundp 'last-coding-system-used)
	(setq last-coding-system-used coding-system))
    (if (eq visit t)
	(progn
	  (setq buffer-file-name file)
	  (set-visited-file-modtime))
      (if (stringp visit)
	  (progn
	    (set-visited-file-modtime)
	    (setq buffer-file-name visit))))
    (if (or (eq visit t)
	    (eq visit nil)
	    (stringp visit))
	(message "Wrote %s" buffer-file-name))))

(put 'write-region 'age-file 'age-file-write-region)

;;; Commands

(defun age-file-select-keys ()
  "Select recipients for encryption."
  (interactive)
  (setq-local age-file-encrypt-to
              (age-select-keys
               (age-make-context)
               "Select recipients for encryption.")))

;;;###autoload
(defun age-file-enable ()
  "Enable age file handling."
  (interactive)
  (age-advise-tramp)
  (if (memq age-file-handler file-name-handler-alist)
      (message "`age-file' already enabled")
    (setq file-name-handler-alist
	  (cons age-file-handler file-name-handler-alist))
    (add-hook 'find-file-hook #'age-file-find-file-hook)
    (setq auto-mode-alist (cons age-file-auto-mode-alist-entry auto-mode-alist))
    (message "`age-file' enabled")))

;;;###autoload
(defun age-file-disable ()
  "Disable age file handling."
  (interactive)
  (age-advise-tramp t)
  (if (memq age-file-handler file-name-handler-alist)
      (progn
	(setq file-name-handler-alist
	      (delq age-file-handler file-name-handler-alist))
	(remove-hook 'find-file-hook #'age-file-find-file-hook)
	(setq auto-mode-alist (delq age-file-auto-mode-alist-entry
				    auto-mode-alist))
	(message "`age-file' disabled"))
    (message "`age-file' already disabled")))

(provide 'age)

;;; age.el ends here
