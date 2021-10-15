;;; learn-ocaml.el --- Emacs frontend for learn-ocaml -*- lexical-binding: t; -*-

;; Copyright (c) 2019-2021  The learn-ocaml.el developers

;; Authors: (see the AUTHORS file distributed along the sources)
;; URL: https://github.com/pfitaxel/learn-ocaml.el
;; Package-Version: 20211003.1412
;; Package-Commit: ac6ef9cbd39f7d9ac0019e28da09aad5bc2cfae5
;; Package-Requires: ((emacs "25.1"))
;; Version: 1.0.0-git

;; This software is free software; you can redistribute it and/or
;; modify it under the terms of the MIT License.

;; You should have received a copy of the MIT License along with this
;; program.  If not, see <https://spdx.org/licenses/MIT>

;;; Commentary:
;;
;; learn-ocaml.el is an Emacs frontend for students using learn-ocaml.
;;
;; It uses learn-ocaml-client, a CLI tool to interact with learn-ocaml
;; that can be installed using the OCaml package manager (OPAM 2.0):
;; https://opam.ocaml.org/packages/learn-ocaml-client/
;;
;; For details, see https://github.com/pfitaxel/learn-ocaml.el#readme

(require 'cl-lib)
(require 'browse-url)
(require 'json)
(require 'subr-x)

(require 'package)  ; for #'learn-ocaml-upgrade-packages

;;; Code:

;; Most features rely on the "learn-ocaml-client" binary, which is run
;; by `learn-ocaml-make-process-wrapper'.  See also the function
;; `learn-ocaml-command-constructor'.  By convention, all functions
;; that call `learn-ocaml-make-process-wrapper' have suffix `-cmd'.
;; These functions are generally tested in
;; "tests/learn-ocaml-tests.el" and will often have an associated
;; interactive/gui counterpart (untested wrapper).

(defgroup learn-ocaml nil
  "learn-ocaml in Emacs "
  :group 'applications
  :prefix "learn-ocaml-")

(defvar learn-ocaml-fail-noisely nil
  "Set `learn-ocaml-fail-noisely' to non-nil for `ert'-testing purposes.")

(defconst learn-ocaml-timeout 4
  "Time in s for `learn-ocaml-await-for' to wait after calling `make-process'.")

(defconst learn-ocaml-mode-version "1.0.0-git")

(defconst learn-ocaml-command-name "learn-ocaml-client")

(defconst learn-ocaml-temp-prefix "learn-ocaml-mode"
  "Prefix of the HTML temporary directory given to `make-temp-file'.")

(defconst learn-ocaml-temp-html-file "results.html"
  "Constant filename created in temporary folder.")

(defvar learn-ocaml-temp-dir nil)

(defvar learn-ocaml-use-passwd nil)

(defvar learn-ocaml-log-buffer nil)

(defun learn-ocaml-log-buffer ()
  "Return the value of variable `learn-ocaml-log-buffer'.
Call `get-buffer-create' if need be, to ensure it is a live buffer."
  (unless (buffer-live-p learn-ocaml-log-buffer)
    (setq learn-ocaml-log-buffer (get-buffer-create "*learn-ocaml-log*")))
    learn-ocaml-log-buffer)

(defvar learn-ocaml-warning-message
  "learn-ocaml.el encountered an error.  Open log?")

(defconst learn-ocaml-exo-list-name "*learn-ocaml-exercise-list*")

(defvar learn-ocaml-exo-list-buffer nil)

(defun learn-ocaml-exo-list-buffer ()
  "Return the value of variable `learn-ocaml-exo-list-buffer'.
Call `get-buffer-create' if need be, to ensure it is a live buffer."
  (unless (buffer-live-p learn-ocaml-exo-list-buffer)
    (setq learn-ocaml-exo-list-buffer (get-buffer-create learn-ocaml-exo-list-name)))
    learn-ocaml-exo-list-buffer)

(defconst learn-ocaml-exo-list-doc
  "g : Refresh list  |  TAB / S-TAB : Navigate  |  q : Close list")

(defvar learn-ocaml-loaded nil)

(defvar-local learn-ocaml-exercise-id nil)

;;
;; Utility functions
;;

(defun learn-ocaml--rstrip (str)
  "Remove the trailing newline in STR."
  (replace-regexp-in-string "\n\\'" "" str))

(defun learn-ocaml-yes-or-no (message &optional dont-trap-quit)
  "Display MESSAGE in a yes-or-no popup.
`\\[keyboard-quit]' is seen as nil, unless DONT-TRAP-QUIT is non-nil."
  (let ((run (lambda ()
               (x-popup-dialog t `(,message ("Yes" . t) ("No" . nil))))))
    (if dont-trap-quit
        (funcall run)
      (condition-case _sig
          (funcall run)
        (quit nil)))))

(defun learn-ocaml-global-disable-mode ()
  "Disable learn-ocaml-mode' in ALL buffers."
  (interactive "a")
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (funcall 'learn-ocaml-mode -1))))

(defun learn-ocaml-get-progression-by-id (id json)
  (if (cdr (assoc (intern id) json))
      (concat (number-to-string (cdr (assoc (intern id) json))) "%")
    "N/A"))

(defun learn-ocaml-print-time-stamp ()
  "Insert date/time in the buffer given by function `learn-ocaml-log-buffer'."
  (set-buffer (learn-ocaml-log-buffer))
  (goto-char (point-max))
  (insert (concat
             "\n\n\n"
             "--------------------- "
             (current-time-string)
             " ---------------------\n")))

(defun escape-secret (secret)
  "Add escape to the secret when it's empty"
  (if-let (secret-option (string= secret ""))
      "\"\""
      secret))

(defun learn-ocaml-file-writter-filter (file _proc string)
  "Write in FILE the given STRING.
To be used as a `make-process' filter."
  (write-region string nil file t))

(defun learn-ocaml-temp-dir ()
  "Return the path of the temp directory attached to current session.
Create this directory if need be, then add `learn-ocaml-delete-temp'
as exit hook."
  (let ((result (or learn-ocaml-temp-dir
                    (make-temp-file learn-ocaml-temp-prefix t))))
    (setq learn-ocaml-temp-dir result)
    (add-hook 'kill-emacs-query-functions #'learn-ocaml-delete-temp)
    result))

(defun learn-ocaml-cd (directory)
  "Change `default-directory' to DIRECTORY and return previous value.
This function is intended to be called before the `make-process'-based
functions writing some .ml file."
  (let ((old default-directory))
    (cd directory)
    old))

(defun learn-ocaml-file-path (dir file)
  "Return the absolute path (w.r.t. to DIR, if applicable) for FILE."
  (if (file-name-absolute-p file)
      file
    (if (directory-name-p dir)
        (concat dir file)
      (concat (file-name-as-directory dir) file))))

(defun learn-ocaml-temp-html-glob ()
  "Generate the glob pattern used by `learn-ocaml-delete-temp'."
  (learn-ocaml-file-path (learn-ocaml-temp-dir)
                         (concat "*" learn-ocaml-temp-html-file)))

(defun learn-ocaml-delete-temp ()
  "Propose to delete temp .html files at exit if not in batch mode.
Function added in the `kill-emacs-query-functions' hook."
  (interactive)
  ;; (unless noninteractive ?)
  (let ((temp-glob (learn-ocaml-temp-html-glob)))
    (when (or noninteractive
              (learn-ocaml-yes-or-no
               (concat
                "learn-ocaml.el automatic cleanup:\n\nDo you want to clear "
                temp-glob " ?")))
      (let ((files (file-expand-wildcards temp-glob)))
        (mapc (lambda (file) (ignore-errors (delete-file file))) files))
      (ignore-errors (delete-directory (learn-ocaml-temp-dir)))))
  t)

(defun learn-ocaml-server-config (json)
  "Set the global variable learn-ocaml-use-passwd according
to the boolean contained in the json returned by the client"
  (if (string= (cdr (assoc 'use_passwd (json-read-from-string json)))
         "true")
    (setq learn-ocaml-use-passwd t)
  (setq learn-ocaml-use-passwd nil)))

(defun learn-ocaml-since-upto (since upto)
  "Return (SINCE . UPTO) with args possibly nil, denoting (SINCE <= v < UPTO).
Both SINCE and UPTO should be valid version strings."
  (unless (or (stringp since) (null since))
    (error "SINCE must be a string"))
  (unless (or (stringp upto) (null upto))
    (error "UPTO must be a string"))
  (cons since upto))

(defun learn-ocaml-compat (pred-pair version)
  "If PRED-PAIR is (since . upto), return (since <= VERSION < upto).
VERSION should be a list-based version, use `version-to-list' if need be.
See also `learn-ocaml-since-upto'."
  (let ((since (car pred-pair)) (upto (cdr pred-pair)))
    (and (if since (version-list-<= (version-to-list since) version) t)
         (if upto (version-list-< version (version-to-list upto)) t))))

;;
;; package.el shortcut
;;

(defun learn-ocaml-upgrade-packages ()
  "Upgrade ELPA packages (using package.el)."
  (interactive)
  (let ((old-async package-menu-async))
    (setq package-menu-async nil)
    (package-list-packages)
    (package-menu-mark-upgrades)
    (let ((use-dialog-box nil))
      ;; make `y-or-n-p' show up within the minibuffer
      ;; even if `learn-ocaml-upgrade-packages' was called interactively
      (package-menu-execute))
    (setq package-menu-async old-async)))

;;
;; Core functions
;;

; Todo: a small integration test?
(defun learn-ocaml-temp-html-file (&optional id)
  "Return the path of the .html file to consider for exercise ID."
  (learn-ocaml-file-path (learn-ocaml-temp-dir)
                         (if id (concat id "-" learn-ocaml-temp-html-file)
                           learn-ocaml-temp-html-file)))

(defun learn-ocaml-update-exec-path (default-dir)
  "Propose to add a directory, e.g. DEFAULT-DIR, to `exec-path'."
  (if noninteractive
      (if default-dir
          (add-to-list 'exec-path default-dir)
        (error "No directory selected (in learn-ocaml-update-exec-path)"))
    (let ((dir (condition-case _sig
                   (read-directory-name "Add folder containing learn-ocaml-client: "
                                        (or default-dir "~/")
                                        (or default-dir "~/")
                                        t "")
                 (quit ""))))
      (if (and dir (not (string-equal "" dir)))
          (add-to-list 'exec-path dir)))))

(defun learn-ocaml-change-default-directory (open-exo-list)
  "Change `default-directory' interactively.
Call `learn-ocaml-display-exercise-list' if OPEN-EXO-LIST is non-nil."
  (interactive)
  (let ((dir
         (read-directory-name "Choose your working directory: "
                              default-directory
                              default-directory
                              nil "")))
    (make-directory dir t)
    (setq default-directory dir))
  (if open-exo-list (learn-ocaml-display-exercise-list)))

(cl-defun learn-ocaml-make-process-wrapper (&rest args &key command &allow-other-keys)
  "Call `make-process' after checking the program is in `exec-path'.
More precisely: if the program is equal to `learn-ocaml-command-name',
check whether it is in the `exec-path'.  Otherwise, query the user to
add \"opam var bin\" (or another directory) in `exec-path'."
  (if (and (listp command) (string-equal learn-ocaml-command-name
                                         (car command))
           (not (executable-find (car command)))) ; not found
           (if (executable-find "opam")
              (progn (message "\"%s\" not found; running \"opam var bin\"..."
                              learn-ocaml-command-name)
                     (let ((client-bin
                            (learn-ocaml--rstrip (shell-command-to-string "opam var bin"))))
                       (learn-ocaml-update-exec-path client-bin)))
             (learn-ocaml-update-exec-path nil)))
  (if (executable-find learn-ocaml-command-name)
      (apply #'make-process args)
    (if noninteractive
        (error "\"%s\" not found!" learn-ocaml-command-name)
      (if (learn-ocaml-yes-or-no
           (format "\"%s\" not found.\n\nCurrent value of exec-path:\n%s\n\nRetry?"
                   learn-ocaml-command-name
                   (concat "(\n" (apply #'concat
                                        (cl-map 'list (lambda (s) (concat s "\n"))
                                                exec-path)) ")")))
          (apply #'learn-ocaml-make-process-wrapper args) ; this could be a loop
        nil))))

(defun learn-ocaml-await-for (fun-kk-body time &optional descr)
  "Run FUN-KK-BODY, wait TIME s for a callback to be called, or failwith DESCR.
Return (t . \"stdout+stderr\") if exit code = 0;
Return (nil . \"stdout+stderr\") if exit code > 0."
  (let ((wip t))
    (catch 'result
      (let ((result
	     #'(lambda (res)
		 (if wip (throw 'result `(t . ,res))
		   (message "learn-ocaml-await-for%s: Got result too late [%s]."
			    (if descr (concat "[" descr "]") "") res))))
	    (failure
	     #'(lambda (res)
		 (if wip (throw 'result `(nil . ,res))
		   (message "learn-ocaml-await-for%s: Got failure too late [%s]."
			    (if descr (concat "[" descr "]") "") res)))))
	;; Note that FUN-K-BODY is not wrapped by `with-timeout'
	;; as FUN-KK-BODY will typically be an async call to `make-process'
	;; and we just wait for the subprocess to terminate within TIME s.
	(funcall fun-kk-body result failure)
        (let ((end-time (+ (float time) (float-time)))) ;; start counting here
	  (while (< (float-time) end-time)
	    (accept-process-output nil 0.1)))
	  (setq wip nil)
	(error
	 "learn-ocaml-await-for%s: didn't receive result after %ds."
	 (if descr (concat "[" descr "]") "") time)))))

;; ;; TEST-CASE
;; (let ((buffer (generate-new-buffer "test")))
;;   (learn-ocaml-await-for
;;    #'(lambda (result failure)
;;        (make-process
;;      :name "arg1"
;;      :command '("sh" "-c" "echo output1; sleep 1s; echo error >&2; false")
;;      :buffer buffer
;;      :sentinel (apply-partially
;;                 #'learn-ocaml-error-handler-nosplit-catch
;;                 buffer
;;                 #'(lambda (s) (funcall result s))
;;                 #'(lambda (s) (funcall failure s)))))
;;    2 ;; or 0
;;   "test"))

(defun learn-ocaml-command-to-string-await-cmd (args)
  "Run \"learn-ocaml-client ARGS\".
This is a `learn-ocaml-update-exec-path'-enhanced replacement for
(shell-command-to-string (combine-and-quote-strings
  (cons \"learn-ocaml-client\" args))), relying on `learn-ocaml-await-for'.
Return (t . \"stdout+stderr\") if exit code = 0;
Return (nil . \"stdout+stderr\") if exit code > 0;
Raise (error \"learn-ocaml-await-for...\") if `learn-ocaml-timeout' exceeded."
  ;; (learn-ocaml-print-time-stamp) ;; FIXME: enable?
  (unless (and args (listp args))
    (error "ARGS must be a nonempty list (of strings)"))
  (let ((buffer (generate-new-buffer (concat (car args) "-std-out"))))
    (learn-ocaml-await-for
     #'(lambda (result failure)
	 (learn-ocaml-make-process-wrapper
	  :name (car args)
	  :command (cons learn-ocaml-command-name args)
	  :buffer buffer
	  :sentinel (apply-partially
                     #'learn-ocaml-error-handler-nosplit-catch
                     buffer
                     #'(lambda (s) (funcall result s))
                     #'(lambda (s) (funcall failure s)))))
     learn-ocaml-timeout (car args))))

(defun learn-ocaml-client-version ()
  "Run \"learn-ocaml-client --version\"."
  (string-trim
   (cdr (learn-ocaml-command-to-string-await-cmd (list "--version")))))

(defconst learn-ocaml-client-server-min-version-compat
  (learn-ocaml-since-upto "0.13.0" nil))

;; (learn-ocaml-client-server-min-version
;; (learn-ocaml-client-server-min-version "http://localhost:8080")
(defun learn-ocaml-client-server-min-version (&optional server)
  "Return the min of the learn-ocaml server and learn-ocaml-client versions."
  (let* ((client (learn-ocaml-client-version))
         (command (list "server-version" "--min"))
         (version-string
          (if (learn-ocaml-compat learn-ocaml-client-server-min-version-compat
                                  (version-to-list client))
              ;; TODO: Take errors into account in a better way,
              ;; instead of waiting that `version-to-list' fails
              (string-trim (cdr (learn-ocaml-command-to-string-await-cmd
                                 (if server (append command
                                                    (list "-s" server))
                                   command))))
            client))
         (_check (version-to-list version-string)))
    version-string))

;;
;; Higher-order functions, sentinels of the make-process wrapper
;;
;; NOTE: if we want to get stdout+stderr output in one go, we need to
;; omit the :stderr argument of make-process.  Otherwise, to get the
;; streams apart (e.g., for grade), the :stderr arg must be specified.

;; FIXME: Move this docstring?
;; Summary of the workflow for sign-up/sign-in
;; - Choice (Sign-up/Login ?)
;; - Sign-up:
;;   - Ask login, password, nickname, secret
;;   - learn-ocaml-client init-user
;;   - message-box stdout+stderr (e-mail sent)
;;   - GoTo Choice
;; - Login:
;;   - Ask login, password (TODO Check that OK if C-g)
;;   - learn-ocaml-client init-user
;;   - if exit code 0: callback “open exo list?”
;;   - if exit code >0:
;;     - message-box stdout+stderr (which will contain ERROR)
;;     - GoTo Login

;; FIXME: Add buffer-err argument, copied to (learn-ocaml-log-buffer)
(defun learn-ocaml-error-handler (buffer callback proc string)
  "Get text from BUFFER and pass it to the CALLBACK.
To be used as a `make-process' sentinel, using args PROC and STRING."
  (let ((result (if (not buffer)
                    ""
                  (set-buffer buffer)
                  (buffer-string))))
    (when buffer (kill-buffer buffer))
    (if  (or (string-equal string "finished\n")
             (string-match "give-token" (process-name proc))
             (string-match "give-server" (process-name proc)))
        (funcall callback result)
      (progn (set-buffer (learn-ocaml-log-buffer))
             (goto-char (point-max))
             (let ((message
                    ;; FIXME(Bug): this returns the whole buffer text!
                    (if (search-backward "[ERROR]" nil t 1)
                        (buffer-substring (point) (point-max)) "")))
               (cl-case (x-popup-dialog
                         t `(,message
                             ("Ok" . 1)
                             ("Check full learn-ocaml-log" . 2)))
                 (2 (switch-to-buffer-other-window "*learn-ocaml-log*")))))
      (when learn-ocaml-fail-noisely
        (with-current-buffer (learn-ocaml-log-buffer)
          ;; Remark: the log will contain earlier, unrelated info...
          (let ((log (buffer-string)))
            (error "Process errored.  Full log:\n%s" log)))))))

(defun learn-ocaml-error-handler-nosplit-catch (buffer callback-ok callback-err _proc string)
  "Get text from BUFFER, pass it to CALLBACK-OK ($?=0) or CALLBACK-ERR.
To be used as a `make-process' sentinel, using args PROC and STRING."
  (let ((result (if (not buffer)
                    ""
                  (set-buffer buffer)
                  (buffer-string))))
    (when buffer (kill-buffer buffer))
    (if  (or (string-equal string "finished\n"))
               (funcall callback-ok result)
      (progn (set-buffer (learn-ocaml-log-buffer))
             (insert result)
             (funcall callback-err result)))))

;;
;; CLI constructors
;;

(cl-defun learn-ocaml-command-constructor (&key command token server local id html dont-submit param1 param2)
  "Construct a shell command with `learn-ocaml-command-name' and options."
  (let* ((server-option (when server (concat "--server=" server)))
         (token-option (when token (concat "--token=" token)))
         (local-option (when local "--local"))
         (id-option (when id (concat "--id=" id)))
         (html-option (when html "--html"))
         (dont-submit-option (when dont-submit "-n"))
         (list (list learn-ocaml-command-name command token-option server-option id-option html-option dont-submit-option local-option param1 param2)))
    (cl-remove-if-not 'stringp list)))

(cl-defun learn-ocaml-init-user-command-constructor (&key server login password nickname secret)
  "Construct a shell command with `learn-ocaml-command-name' and options."
  (let* ((nickname-option (when nickname nickname))
         (secret-option (when secret secret))
         (server-option (when server (concat "--server=" server)))
         (list (list learn-ocaml-command-name "init-user" server-option login password nickname-option secret-option)))
    (cl-remove-if-not 'stringp list)))

;;
;; Low-level functions 0.12
;;

;; a useful one-liner:
;; VERSION=0.12; docker run --rm -i ocamlsf/learn-ocaml-client:"$VERSION" --help | perl -wne 'BEGIN{my $at=0;} $at=0 if /ARGUMENTS/; s/^ {7}//; print if $at && /./ && ! /^ /; $at=1 if /COMMANDS/;'
;;
;; create-token
;; exercise-list
;; fetch
;; grade
;; init
;; print-server
;; print-token
;; set-options
;; template

;; TODO: Rename them below if need be

;; TODO: Use cl-defun
(defun learn-ocaml-create-token-cmd (nickname secret callback)
  "Create a new token for NICKNAME.
Argument SECRET may be needed by the server.
Argument CALLBACK will receive the token."
  (learn-ocaml-print-time-stamp)
  (let ((buffer (generate-new-buffer "create-token")))
    (learn-ocaml-make-process-wrapper
     :name "create-token"
     :command (learn-ocaml-command-constructor
               :command "create-token"
               :param1 nickname
               :param2 secret)
     :stderr (learn-ocaml-log-buffer)
     :buffer buffer
     :sentinel (apply-partially
                #'learn-ocaml-error-handler
                buffer
                (lambda (s)
                  (funcall-interactively
                   callback
                   (replace-regexp-in-string "\n\\'" "" s)))))))

(defun learn-ocaml-give-exercise-list-cmd (callback)
  "Give to the CALLBACK a json containing the exercise list."
  (learn-ocaml-print-time-stamp)
  (let ((buffer (generate-new-buffer "exercise-list")))
    (learn-ocaml-make-process-wrapper
     :name "exercise-list"
     :command (learn-ocaml-command-constructor
               :command "exercise-list")
     :stderr (learn-ocaml-log-buffer)
     :buffer buffer
     :sentinel (apply-partially
                #'learn-ocaml-error-handler
                buffer
                (lambda (s)
                  (funcall-interactively
                   callback (json-read-from-string s)))))))

(cl-defun learn-ocaml-download-server-file-cmd (&key token server id directory callback)
  "Download from the SERVER the last version of exercise ID in DIRECTORY."
  (learn-ocaml-print-time-stamp)
  (let ((old (learn-ocaml-cd directory)))
  (learn-ocaml-make-process-wrapper
   :name (concat "download-" id)
   :command (learn-ocaml-command-constructor
             :token token
             :server server
             :param1 id
             :command "fetch")
   :stderr (learn-ocaml-log-buffer)
   :sentinel (apply-partially
              #'learn-ocaml-error-handler
              nil
              callback))
  (cd old)))

(cl-defun learn-ocaml-grade-file-cmd (&key id token server dont-submit file callback)
  "Grade a .ml file, optionally submitting the code and the note to the server."
  (learn-ocaml-print-time-stamp)
  (let ((html (learn-ocaml-temp-html-file id)))
    (write-region "" nil html nil)      ; erase the html file
  (learn-ocaml-make-process-wrapper
   :name (concat "upload-" id)
   :command (learn-ocaml-command-constructor
             :token token
             :server server
             :id id
             :dont-submit dont-submit
             :param1 file
             :html t
             :command "grade")
   :stderr (learn-ocaml-log-buffer)
   :filter (apply-partially
            #'learn-ocaml-file-writter-filter
            html)
   :sentinel (apply-partially
              #'learn-ocaml-error-handler
              nil
              (lambda (_arg)
                (funcall-interactively
                 callback
                 html))))))

;; TODO: Handle --local?
(cl-defun learn-ocaml-init-cmd (&key token server nickname secret callback)
  "Run \"learn-ocaml-client init\" with options."
  (learn-ocaml-print-time-stamp)
  (learn-ocaml-make-process-wrapper
   :name "init"
   :command (learn-ocaml-command-constructor
             :token token
             :server server
             :param1 nickname
             :param2 secret
             :command "init")
   :stderr (learn-ocaml-log-buffer)
   :sentinel (apply-partially
              #'learn-ocaml-error-handler
              nil
              callback)))

(defun learn-ocaml-give-server-cmd (callback)
  "Give the current server url to the CALLBACK."
  (learn-ocaml-print-time-stamp)
  (let ((buffer (generate-new-buffer "give-server")))
    (learn-ocaml-make-process-wrapper
     :name "give-server"
     :command (learn-ocaml-command-constructor
               :command "print-server")
     :stderr (learn-ocaml-log-buffer)
     :buffer buffer
     :sentinel (apply-partially
                #'learn-ocaml-error-handler
                buffer
                (lambda (s)
                  (funcall-interactively
                   callback

                   (learn-ocaml--rstrip s)))))))

(defun learn-ocaml-give-token-cmd (callback)
  "Gives the current token to the CALLBACK."
  (learn-ocaml-print-time-stamp)
  (let ((buffer (generate-new-buffer "give-token")))
    (learn-ocaml-make-process-wrapper
     :name "give-token"
     :command (learn-ocaml-command-constructor
               :command "print-token")
     :stderr (learn-ocaml-log-buffer)
     :buffer buffer
     :sentinel (apply-partially
                #'learn-ocaml-error-handler
                buffer
                (lambda (s)
                  (funcall-interactively
                   callback
                   (learn-ocaml--rstrip s)))))))

(defun learn-ocaml-use-metadata-cmd (token server callback)
  "Set TOKEN, SERVER, and run CALLBACK."
  (learn-ocaml-print-time-stamp)
  (learn-ocaml-make-process-wrapper
   :name "use-metadata"
   :command (learn-ocaml-command-constructor
             :token token
             :server server
             :command "set-options")
   :stderr (learn-ocaml-log-buffer)
   :sentinel (apply-partially
              #'learn-ocaml-error-handler
              nil
              callback)))

(cl-defun learn-ocaml-download-template-cmd (&key token server id local directory callback)
  "Download from the SERVER the template code for exercise ID in DIRECTORY."
  ;; TODO: argument LOCAL is not taken into account in the mode
  (learn-ocaml-print-time-stamp)
  (let ((old (learn-ocaml-cd directory)))
  (learn-ocaml-make-process-wrapper
   :name (concat "template-" id)
   :command (learn-ocaml-command-constructor
             :command "template"
             :token token
             :server server
             :local local
             :param1 id)
   :stderr (learn-ocaml-log-buffer)
   :sentinel (apply-partially
              #'learn-ocaml-error-handler
              nil
              callback))
  (cd old)))

;;
;; Low-level functions 0.15
;;

;; TODO: Refine

(defun learn-ocaml-client-exercise-score-cmd ()
  "Run \"learn-ocaml-client exercise-score\"."
  (let* ((cmd "exercise-score")
         (result (learn-ocaml-command-to-string-await-cmd (list cmd))))
    (if (car result) (json-read-from-string (cdr result))
      ;; FIXME: Use learn-ocaml-log-buffer
      (error "%s %s: failed with [%s]." learn-ocaml-command-name cmd
             (string-trim (cdr result))))))

(cl-defun learn-ocaml-init-server-cmd (&key server callback)
  "Run \"learn-ocaml-client init\" with options."
  (learn-ocaml-print-time-stamp)
  (learn-ocaml-make-process-wrapper
   :name "init-server"
   :command (learn-ocaml-command-constructor
             :server server
             :command "init-server")
   :stderr (learn-ocaml-log-buffer)
   :sentinel (apply-partially
              #'learn-ocaml-error-handler
              nil
              callback)))

(cl-defun learn-ocaml-client-sign-in-cmd (&key server login password callback-ok callback-err)
  "Run \"learn-ocaml-client init-user\" with SERVER LOGIN PASSWORD to login an user."
  (learn-ocaml-print-time-stamp)
  (let ((buffer (generate-new-buffer "sign-in-std-out")))
    (learn-ocaml-make-process-wrapper
     :name "init-user"
     :command (learn-ocaml-init-user-command-constructor :server server
                                                         :login login
                                                         :password password)
     :buffer buffer
     :sentinel (apply-partially
                       #'learn-ocaml-error-handler-nosplit-catch
                       buffer
                       callback-ok
                       callback-err))))

(cl-defun learn-ocaml-client-sign-up-cmd (&key server login password nickname secret callback-ok callback-err)
  "Run \"learn-ocaml-client init-user\" with SERVER LOGIN PASSWORD NICKNAME and SECRET to sign-up an user."
  (learn-ocaml-print-time-stamp)
  (let ((buffer (generate-new-buffer "sign-up-std-out")))
    (learn-ocaml-make-process-wrapper
     :name "init-user"
     :command (learn-ocaml-init-user-command-constructor :server server
                                                         :login login
                                                         :password password
                                                         :nickname nickname
                                                         :secret secret)
     :buffer buffer
     :sentinel (apply-partially
                #'learn-ocaml-error-handler-nosplit-catch
                buffer
                callback-ok
                callback-err))))

(defun learn-ocaml-client-config-cmd ()
  "Run \"learn-ocaml-client server-config\"."
  (let* ((cmd "server-config")
         (result (learn-ocaml-command-to-string-await-cmd (list cmd))))
    (if (car result) (cdr result)
      ;; FIXME: Use learn-ocaml-log-buffer
      (error "%s %s: failed with [%s]." learn-ocaml-command-name cmd (string-trim (cdr result))))))

;;
;; Wrappers
;;

(defconst learn-ocaml-compute-questions-url-token1-compat
  (learn-ocaml-since-upto "0.13.0" nil))

(defun learn-ocaml-compute-questions-url (server id token)
  "Get subject url for SERVER, exercise ID and user TOKEN."
  (let ((token-param
         (if (learn-ocaml-compat
              learn-ocaml-compute-questions-url-token1-compat
              (version-to-list (learn-ocaml-client-server-min-version server)))
             (concat "#token1=" (base64-encode-string (format "%192s" token) t))
           (concat "#token=" token))))
    (concat server "/description/" id token-param)))

(defun learn-ocaml-show-questions (id)
  "Open the questions for exercise ID in the default browser."
  (interactive)
  (learn-ocaml-give-server-cmd
   (lambda (server)
     (learn-ocaml-give-token-cmd
      (lambda (token)
        ;; very important if you don't do it you risk to open eww
	(setq browse-url-browser-function 'browse-url-default-browser)
	(browse-url (learn-ocaml-compute-questions-url server id token)))))))

(defun learn-ocaml-show-metadata ()
  "Display the token and server url in mini-buffer and `message-box'."
  (interactive)
  (learn-ocaml-give-server-cmd
   (lambda (server)
     (learn-ocaml-give-token-cmd
      (lambda (token)
        (message "learn-ocaml: token %s @ %s" token server)
        (message-box "Current token: %s\nCurrent server: %s" token server))))))

(cl-defun learn-ocaml-create-token (nickname secret)
  "Create a new token for NICKNAME.
Argument SECRET may be needed by the server."
  (interactive "sWhat nickname you want to use for the token? \nsWhat secret does the server require? ")
  (learn-ocaml-create-token-cmd
   nickname
   secret
   (lambda (token)
     (learn-ocaml-use-metadata-cmd
      token
      nil
      (lambda (_)
        (message-box "Token created succesfully")
        (learn-ocaml-show-metadata))))))

(defun learn-ocaml-change-server ()
  "Interactively change the server url."
  (interactive)
  (learn-ocaml-give-server-cmd
   (lambda (s)
     (if (learn-ocaml-yes-or-no
          (concat "The current configured server is: " s "\n Do you want to change it?"))
         (let ((server (read-string "Enter server URL: " "https://")))
           (learn-ocaml-use-metadata-cmd
            nil
            server
            (lambda (_)
              (message-box "Server changed succesfully")
               (cl-case (x-popup-dialog
             t `("The old token may not work with the new server.\n What do you want to do?\n"
                 ("Enter my token" . 1)
                 ("Create new token" . 2)))
        (1 (let ((token (read-string "Enter token: ")))
           (learn-ocaml-use-metadata-cmd
            token
            nil
            (lambda (_)
              (message-box "Token changed succesfully")))))
        (2 (call-interactively 'learn-ocaml-create-token)))
               (learn-ocaml-show-metadata)
               (learn-ocaml-display-exercise-list))))))))

(defun learn-ocaml-change-token ()
  "Interactively change the user token."
  (interactive)
  (learn-ocaml-give-token-cmd
   (lambda (token)
     (if (learn-ocaml-yes-or-no
          (concat "The current configured token is: "
                  token
                  "\n Do you want to change it?"))
         (let ((token (read-string "Enter token: ")))
           (learn-ocaml-use-metadata-cmd
            token
            nil
            (lambda (_)
              (message-box "Token changed succesfully")
              (learn-ocaml-show-metadata))))))))

(defun learn-ocaml-download-server-file (id &optional directory)
  "Download the last saved code for exercise ID in DIRECTORY."
  (interactive `(,(let ((input (read-string (concat
                                             "Enter the id of the exercise (default "
                                             learn-ocaml-exercise-id
                                             "): "))))
                    (if (string-equal "" input)
                        learn-ocaml-exercise-id
                      input))))
  (learn-ocaml-download-server-file-cmd
   :id id
   :directory (or directory default-directory)
   :callback (lambda (_) (message-box "File(s) downloaded correctly"))))

(defun learn-ocaml-download-template (id &optional directory)
  "Download the template code for exercise ID in DIRECTORY."
  (interactive `(,(let ((input (read-string (concat
                                             "Enter the id of the exercise (default "
                                             learn-ocaml-exercise-id
                                             "): "))))
                    (if (string-equal "" input)
                        learn-ocaml-exercise-id
                      input))))
  (learn-ocaml-download-template-cmd
   :id id
   :directory (or directory default-directory)
   :callback (lambda (_) (message-box "Template downloaded correctly"))))

;;;###autoload
(defun learn-ocaml-grade ()
  "Grade the current .ml buffer."
  (interactive)
  (learn-ocaml-setup nil)
  (save-buffer)
  (learn-ocaml-grade-file-cmd
   :id learn-ocaml-exercise-id
   :file buffer-file-name
   :callback (lambda (html)
               (setq browse-url-browser-function 'browse-url-default-browser)
               (browse-url-of-file html))))

;;
;; exercise list display
;;

(require 'widget)
(define-widget 'learn-ocaml-button 'push-button ""
  :button-face 'button)

(defface learn-ocaml-group-title-face
  '((t (
	:inherit variable-pitch
	:foreground "blue1"
	:underline nil :weight bold :height 1.2)))
  "Face group titles.")

(define-widget 'learn-ocaml-group-title 'lazy ""
  :format "%{%t%}"
  :sample-face 'learn-ocaml-group-title-face)

(define-widget 'learn-ocaml-exercise-title 'lazy ""
  :format "%{%t%}"
  :sample-face 'bold)

(defface learn-ocaml-header-hint-face
  '((t (
	:underline nil :slant italic :height 0.9)))
  "Face header hint.")

(define-widget 'learn-ocaml-header-hint 'lazy ""
  :format "%{%t%}"
  :sample-face 'learn-ocaml-header-hint-face)

(defun learn-ocaml-print-exercise-info (indent tuple json-progression)
  "Render an exercise item with leading INDENT from the data in TUPLE."
  (let* ((id (elt tuple 0))
         (exo (elt tuple 1))
         (title (assoc-default 'title exo) )
         (short_description (assoc-default 'short_description exo))
         (stars (assoc-default 'stars exo))
         (progression (learn-ocaml-get-progression-by-id id json-progression)))
    (widget-insert "\n")
    (widget-insert indent)
    (widget-create 'learn-ocaml-exercise-title
                   :tag title)
    (widget-insert "\n")
    (widget-insert (concat indent " "))
    (widget-insert (if short_description short_description "No description available"))
    (widget-insert "\n")
    (widget-insert (concat indent " "))
    (widget-insert (concat "Difficulty: " (number-to-string stars) "/4"
                           "      progression: "
                           progression "    id: " id ))
    (widget-insert "\n")
    (widget-insert (concat indent " "))
    (widget-create 'learn-ocaml-button
                   :notify (lambda (&rest _ignore)
                             (learn-ocaml-show-questions id))
                   "Browse subject")
    (widget-insert " ")
    (widget-create 'learn-ocaml-button
                   :notify (lambda (&rest _ignore)
                             (learn-ocaml-download-template id))
                   "Get template")
    (widget-insert " ")
    (widget-create 'learn-ocaml-button
                   :notify (lambda (&rest _ignore)
                             (find-file (concat id ".ml")))
                   "Open .ml")
    (widget-insert " ")
    (widget-create 'learn-ocaml-button
                   :notify (lambda (&rest _ignore)
                             (learn-ocaml-download-server-file id))
                   "Get last saved version")
    (widget-insert "\n")))

(defun learn-ocaml-print-groups (indent json)
  "Render an exercise group with leading INDENT from the data in JSON."
  (let ((json-progression
         () ;; TODO (learn-ocaml-client-exercise-score-cmd)
         )
        (head (car json))
        (queue (cdr json)))
    (if (eq 'groups head)
        (progn
          (seq-do
           (lambda (group)
             (widget-create
              'learn-ocaml-group-title
              :tag (concat indent
                           (cdr (car (cdr group)))
                           "\n"))
             (learn-ocaml-print-groups (concat indent " ")
                                       (car (cdr (cdr group)))))
           queue))
      (seq-do (lambda (elt)
                (learn-ocaml-print-exercise-info
                 (concat indent " ") elt json-progression))
              queue)
      (widget-insert "\n"))))

(defun learn-ocaml-display-exercise-list-aux (json)
  "Render the exercise list from the server-provided JSON."
  (set-buffer (learn-ocaml-exo-list-buffer))
  (kill-all-local-variables)
  (let ((inhibit-read-only t))
    (erase-buffer))
  (remove-overlays)  (widget-create
                      'learn-ocaml-header-hint
                      :tag learn-ocaml-exo-list-doc)
  (widget-insert "\n")
  (widget-create
   'learn-ocaml-header-hint
   :tag (make-string (length learn-ocaml-exo-list-doc) 45)) ; 45='-'
  (widget-insert "\n\n")
  (widget-insert "LearnOCaml ")
  (widget-create 'learn-ocaml-button
                 :notify (lambda (&rest _ignore)
                           (find-file default-directory))
                 "directory")
  (widget-create
   'learn-ocaml-header-hint
   :tag (concat " (" default-directory ") "))
  (widget-create 'learn-ocaml-button
                 :notify (lambda (&rest _ignore)
                           (learn-ocaml-change-default-directory t))
                 "Change & refresh")
  (widget-insert "\n\n")
  (learn-ocaml-print-groups "" json)
  (use-local-map widget-keymap)
  (widget-setup)
  (goto-char (point-min))
  (local-set-key "g" (lambda () (interactive)
                       (message "Refreshing %s..." learn-ocaml-exo-list-name)
                       (learn-ocaml-display-exercise-list)))
  (local-set-key "q" #'bury-buffer)
  (with-current-buffer learn-ocaml-exo-list-buffer ; just to be safe
    (read-only-mode 1))
  ;; should be in the end, after (read-only-mode 1):
  (learn-ocaml-mode)
  (switch-to-buffer-other-window learn-ocaml-exo-list-buffer))

;;;###autoload
(defun learn-ocaml-display-exercise-list ()
  "Get the exercise list and render it in buffer `learn-ocaml-exo-list-name'."
  (interactive)
  (learn-ocaml-setup nil)               ; nil, otherwise may loop
  (learn-ocaml-give-exercise-list-cmd
   (lambda (brut-json)
     (learn-ocaml-display-exercise-list-aux (elt (elt brut-json 0) 1)))))

;;
;; on-load management
;;

(cl-defun learn-ocaml-init
    (&key new-server-value new-token-value nickname secret callback)
  "Call `learn-ocaml-init-cmd' if NEW-SERVER-VALUE is nil.
Otherwise, call `learn-ocaml-create-token-cmd' if NEW-TOKEN-VALUE is nil.
Otherwise, call `learn-ocaml-use-metadata-cmd'.
Finally, run the CALLBACK.
Note: this function will be used by `learn-ocaml-login-with-token'."
  (if new-server-value
      ;; without config file
      (learn-ocaml-init-cmd
       :server new-server-value
       :secret secret
       :token new-token-value
       :nickname nickname
       :callback callback)
    ;; with config file
    (if new-token-value
        ;; use token
        (learn-ocaml-use-metadata-cmd
         new-token-value
         nil
         callback)
      ;; create token
      (learn-ocaml-create-token-cmd
       nickname
       secret
       (lambda (token)
         (learn-ocaml-use-metadata-cmd
          token
          nil
          callback))))))

(defun learn-ocaml-login-possibly-with-passwd (server callback)
  "Connect the user when learn-ocaml-use-passwd=true with an (email,passwd) or a token and continue with the no-arg CALLBACK."
  (cl-case (x-popup-dialog
            t `("Welcome to Learn OCaml mode for Emacs.\nWhat do you want to do?\n"
                ("Login" . 1)
                ("Sign-up" . 2)
                ("Login with a legacy token" . 3)))
    (1 (let* ((login_password (learn-ocaml-sign-in))
              (login (nth 0 login_password))
              (password (nth 1 login_password)))
         (learn-ocaml-client-sign-in-cmd
          :server server
          :login login
          :password password
          :callback-ok (lambda(_)
                         (funcall callback))
          :callback-err (lambda(s)
                          (message-box s)
                          (learn-ocaml-login-possibly-with-passwd server callback)))))
    (2 (let* ((infos (learn-ocaml-sign-up))
              (login (nth 0 infos))
              (password (nth 1 infos))
              (nickname (nth 2 infos))
              (secret (nth 3 infos)))
         (learn-ocaml-client-sign-up-cmd
          :server server
          :login login
          :password password
          :nickname nickname
          :secret secret
          :callback-ok (lambda(s)
                          (message-box s)
                          (learn-ocaml-login-possibly-with-passwd server callback))
          :callback-err (lambda(s)
                          (message-box s)
                          (learn-ocaml-login-possibly-with-passwd server callback)))))
    (3 (let ((token (read-string "Enter token: ")))
         (learn-ocaml-use-metadata-cmd
          token
          nil
          (lambda (_)
            (message-box "Token saved.")))))))

(defun learn-ocaml-sign-in ()
  "Ask interactively the e-mail and the password for the user to login"
  (list (read-string "Enter e-mail: ") (read-passwd "Enter password: ")))

(defun learn-ocaml-sign-up ()
  "Ask interactively the e-mail,password(with confirmation),nickname,secret"
  (let* ((login (read-string "Enter e-mail: "))
        (pswd (read-passwd "Enter password: "))
        (pswd-conf (read-passwd "Enter password confirmation: "))
        (nickname (read-string "Enter nickname: "))
        (secret (read-string "Enter secret: ")))
  (while (not (string= pswd pswd-conf))
    (setq pswd (read-passwd "Password are not the same. Enter password: "))
    (setq pswd-conf (read-passwd "Enter password confirmation: ")))
  (list login pswd nickname secret)))

(defun learn-ocaml-login-with-token (token new-server-value callback)
  "At load time: ensure a TOKEN and SERVER are set, then run CALLBACK.
If TOKEN is \"\", interactively ask a token."
   (let* ((rich-callback (lambda (_)
                          (funcall callback)
                          (learn-ocaml-show-metadata))))
    (cl-destructuring-bind (token-phrase use-found-token use-another-token)
        (if (or (not token)
                (string-equal token ""))
            '("No token found"
              "Use found token" ("Use existing token" . 1))
          `(,(concat "Token found: " token)
            ("Use found token" . 0) ("Use another token" . 1)))
      (cl-case (x-popup-dialog
             t `(,(concat token-phrase "\n What do you want to do?\n")
                 ,use-found-token
                 ,use-another-token
                 ("Create new token" . 2)))
        (0 (funcall rich-callback nil))
        (1 (let ((token (read-string "Enter token: ")))
             (learn-ocaml-init
              :new-server-value new-server-value
              :new-token-value token
              :callback rich-callback)))
        (2 (let ((nickname (read-string "What nickname do you want to use for the token? "))
                 (secret (read-string "What secret does the server require? ")))
             (learn-ocaml-init
              :new-server-value new-server-value
              :nickname nickname
              :secret secret
              :callback rich-callback)))))))

(defconst learn-ocaml-feature-passwd-compat
  (learn-ocaml-since-upto "0.15.0" nil))

(defun learn-ocaml-on-load (callback)
  "Call `learn-ocaml-login-with-token' and CALLBACK when loading mode."
  (learn-ocaml-give-server-cmd
   (lambda (server)
     (learn-ocaml-give-token-cmd
      (lambda (token)
        (let* ((new-server-value (if (or (not server)
                                         (string-equal server ""))
                                     (progn (message-box "No server found. Please enter the server url.")
                                            (read-string "Enter server URL: " "https://"))
                                   server)))
          ;; https://github.com/pfitaxel/learn-ocaml.el/pull/26#pullrequestreview-758063532
          (if (learn-ocaml-compat learn-ocaml-feature-passwd-compat
                                  (version-to-list
                                   (learn-ocaml-client-server-min-version new-server-value)))
              (progn (learn-ocaml-init-server-cmd
                      :server new-server-value
                      :callback
                      (lambda(_)
                        (learn-ocaml-server-config (learn-ocaml-client-config-cmd))
                        (if learn-ocaml-use-passwd
                            (learn-ocaml-login-possibly-with-passwd new-server-value callback)
                          (learn-ocaml-login-with-token token new-server-value callback)))))
            (learn-ocaml-login-with-token token new-server-value callback))))))))

(defun learn-ocaml-logout ()
  "Logout the user from the server by removing the token from the file client.json"
  (interactive)
  (let* ((cmd "logout")
         (result (learn-ocaml-command-to-string-await-cmd (list cmd))))
    (if (car result)
        (progn (message-box "You have been successfully disconnected\n\n%s"
                            (cdr result))
               (learn-ocaml-global-disable-mode))
      ;; FIXME: Use learn-ocaml-log-buffer
      (error "%s %s: failed with [%s]." learn-ocaml-command-name cmd
             (string-trim (cdr result))))))

(defun learn-ocaml-deinit ()
  "Logout the user and forget the server by removing the file client.json"
  ;; FIXME(Bug):
  ;; $ learn-ocaml-client deinit
  ;; should fail with exit code > 0
  ;; if Cannot remove ~/.config/learnocaml/client.json : no such file or directory.
  (interactive)
  (let* ((cmd "deinit")
         (result (learn-ocaml-command-to-string-await-cmd (list cmd))))
    (if (car result)
        (progn (message-box "You have been successfully disconnected\n\n%s"
                            (cdr result))
               (learn-ocaml-global-disable-mode))
      ;; FIXME: Use learn-ocaml-log-buffer
      (error "%s %s: failed with [%s]." learn-ocaml-command-name cmd
             (string-trim (cdr result))))))

;;
;; menu definition
;;

(defvar learn-ocaml-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-m C-l") #'learn-ocaml-display-exercise-list)
    (define-key map (kbd "C-c C-m l") #'learn-ocaml-display-exercise-list)
    (define-key map (kbd "C-c C-m C-m") #'learn-ocaml-grade)
    (define-key map [menu-bar] nil)
    map))

(easy-menu-define learn-ocaml-mode-menu
  learn-ocaml-mode-map
  "LearnOCaml Mode Menu."
  '("LearnOCaml"
    :filter
    (lambda (list-items)
      (let ((name (buffer-file-name)))
        (if (and (<= 3 (length name))  ; nil if (buffer-file-name)=nil
                 (string-equal ".ml" (substring name -3 nil)))
            list-items                 ; keep all items for a .ml file
          (cl-remove-if (lambda (item) ; remove "Grade" otherwise
                          (and (vectorp item)
                               (string-equal "Grade" (aref item 0))))
                        list-items))))
    ["Show metadata" learn-ocaml-show-metadata]
    ["Change server" learn-ocaml-change-server]
    ["Change token" learn-ocaml-change-token]
    ["Create token" learn-ocaml-create-token]
    "---"
    ["Show exercise list" learn-ocaml-display-exercise-list]
    ["Download template" learn-ocaml-download-template]
    ["Download server version" learn-ocaml-download-server-file]
    ["Grade" learn-ocaml-grade]
    "---"
    ["Logout" learn-ocaml-logout nil];TODO support >= 0.14
    ["Logout & Forget server" learn-ocaml-deinit nil];TODO support >= 0.12
    "---"
    ["Upgrade Emacs packages..." learn-ocaml-upgrade-packages]
    ))
;;
;; id management
;;

(defun learn-ocaml-compute-exercise-id ()
  "Store the exercise id of current buffer in `learn-ocaml-exercise-id'."
  (when buffer-file-name
    (setq-local learn-ocaml-exercise-id
        (file-name-sans-extension (file-name-base buffer-file-name)))))

(defun learn-ocaml-update-exercise-id-view ()
  "Update the \"Exercise-id:\" menu according to `learn-ocaml-exercise-id'."
  (unless learn-ocaml-exercise-id
    (learn-ocaml-compute-exercise-id))
  (define-key-after
    learn-ocaml-mode-map
    [menu-bar exercise-id]
     `(,(concat "Exercise-id: " learn-ocaml-exercise-id) .
          ,(make-sparse-keymap "Exercise-id")))
  (define-key
    learn-ocaml-mode-map
    [menu-bar exercise-id reset]
    '("Reset id" . learn-ocaml-exercise-id-initializer))
  (define-key
    learn-ocaml-mode-map
    [menu-bar exercise-id change]
    '("Change id" . learn-ocaml-change-exercise-id))
  (force-mode-line-update)) ; a random instruction is needed to update menu bar

(defun learn-ocaml-exercise-id-initializer ()
  "Reset `learn-ocaml-exercise-id' using variable `buffer-file-name'."
  (interactive)
  (setq-local learn-ocaml-exercise-id nil)
  (learn-ocaml-update-exercise-id-view))

(defun learn-ocaml-change-exercise-id (new-id)
  "Change `learn-ocaml-exercise-id' to NEW-ID."
  (interactive "sEnter new id: ")
  (setq-local learn-ocaml-exercise-id new-id)
  (learn-ocaml-update-exercise-id-view))

(add-hook 'window-configuration-change-hook #'learn-ocaml-update-exercise-id-view)

;;
;; definition of the mode
;;

(defun learn-ocaml-setup (&optional open-exo-list)
  "Initialisation function to check whether a token and server is set.
Do nothing if `learn-ocaml-loaded' is non-nil.
Call (`learn-ocaml-change-default-directory' t) if OPEN-EXO-LIST holds.
Used by function `learn-ocaml-mode' and autoloads."
  (unless learn-ocaml-loaded
    (if open-exo-list
        (learn-ocaml-on-load
         (lambda ()
           (when (learn-ocaml-yes-or-no
                  "Do you want to open the list of exercises available on the server?")
             (learn-ocaml-change-default-directory t))))
      (learn-ocaml-on-load (lambda () nil)))
    (add-hook 'caml-mode-hook #'learn-ocaml-mode)
    (add-hook 'tuareg-mode-hook #'learn-ocaml-mode)
    (setq learn-ocaml-loaded t)))

;;;###autoload
(define-minor-mode learn-ocaml-mode
  "Minor mode for students using the LearnOCaml platform.

Version of learn-ocaml.el: `learn-ocaml-mode-version'

Shortcuts for the learn-ocaml mode:
\\{learn-ocaml-mode-map}
"
  :lighter " LearnOCaml"
  :keymap learn-ocaml-mode-map
  (if learn-ocaml-mode
      (progn
        (learn-ocaml-update-exercise-id-view)
        (easy-menu-add learn-ocaml-mode-menu)
        (learn-ocaml-setup t))
    (setq learn-ocaml-loaded nil)
    (remove-hook 'caml-mode-hook #'learn-ocaml-mode)
    (remove-hook 'tuareg-mode-hook #'learn-ocaml-mode)))

(provide 'learn-ocaml)

;;; learn-ocaml.el ends here
