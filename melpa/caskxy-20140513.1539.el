;;; caskxy.el --- Control Cask in Emacs

;; Copyright (C) 2014  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: convenience
;; Package-Version: 20140513.1539
;; Package-Commit: dc18dcab7ed526070ab76de071c9c5272e6ac40e
;; URL: https://github.com/aki2o/caskxy
;; Version: 0.0.5
;; Package-Requires: ((log4e "0.2.0") (yaxception "0.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; 
;; This extension provides the interface to control Cask on Emacs.

;;; Dependency:
;; 
;; - yaxception.el ( see <https://github.com/aki2o/yaxception> )
;; - log4e.el ( see <https://github.com/aki2o/log4e> )

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your .emacs or site-start.el file.
;; 
;; (require 'caskxy)

;;; Configuration:
;; 
;; ;; Make config suit for you. About the config item, see Customization or eval the following sexp.
;; ;; (customize-group "caskxy")

;;; Customization:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "caskxy/" :docstring t)
;; `caskxy/tester-backend'
;; Feature of running test.
;; `caskxy/cask-cli-path'
;; Path of cask-cli.el.
;; 
;;  *** END auto-documentation

;;; API:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'command :prefix "caskxy/" :docstring t)
;; `caskxy/set-emacs-runtime'
;; Set the condition of emacs runtime.
;; `caskxy/set-cask-file'
;; Set the condition of project path.
;; `caskxy/set-tester-backend'
;; Set BACKEND to `caskxy/tester-backend'.
;; `caskxy/show-condition'
;; Show current condition.
;; `caskxy/do-cask-command'
;; Execute the command of Cask.
;; `caskxy/run-test'
;; Run test of TEST-FILE.
;; 
;;  *** END auto-documentation
;; [EVAL] (autodoc-document-lisp-buffer :type 'function :prefix "caskxy/" :docstring t)
;; `caskxy/add-tester-backend'
;; Add a test function.
;; `caskxy/build-ert'
;; Not documented.
;; `caskxy/build-el-expectations'
;; Not documented.
;; `caskxy/filter-el-expectations'
;; Not documented.
;; `caskxy/build-ert-expectations'
;; Not documented.
;; 
;;  *** END auto-documentation
;; [Note] Functions and variables other than listed above, Those specifications may be changed without notice.

;;; Tested On:
;; 
;; - Emacs ... GNU Emacs 24.2.1 (i386-mingw-nt5.1.2600) of 2012-12-08 on GNUPACK
;; - yaxception.el ... Version 0.1
;; - log4e.el ... Version 0.2.0


;; Enjoy!!!


;; Avoid warning
(eval-when-compile
  (defun erte-find-test-other-window (n) nil))

(eval-when-compile (require 'cl))
(require 'log4e)
(require 'yaxception)
(require 'ert nil t)
(require 'el-expectations nil t)
(require 'ert-expectations nil t)

(defgroup caskxy nil
  "Control Cask in Emacs."
  :group 'convenience
  :prefix "caskxy/")

(defcustom caskxy/tester-backend 'ert
  "Feature of running test."
  :type 'symbol
  :group 'caskxy)

(defcustom caskxy/cask-cli-path (concat (directory-file-name (getenv "HOME")) "/.cask/cask-cli.el")
  "Path of cask-cli.el."
  :type 'file
  :group 'caskxy)


(log4e:deflogger "caskxy" "%t [%l] %m" "%H:%M:%S" '((fatal . "fatal")
                                                    (error . "error")
                                                    (warn  . "warn")
                                                    (info  . "info")
                                                    (debug . "debug")
                                                    (trace . "trace")))
(caskxy--log-set-level 'trace)


(defvar caskxy--cask-commands '("package" "install" "update" "upgrade" "exec" "init" "version" "list"
                                "info" "help" "load-path" "path" "package-directory" "outdated"))
(defvar caskxy--cask-location default-directory)
(defvar caskxy--result-buffer-name "*Caskxy Result*")
(defvar caskxy--tester-backends nil)


;;;;;;;;;;;;;
;; Utility

(defun* caskxy--show-message (msg &rest args)
  (apply 'message (concat "[CASKXY] " msg) args)
  nil)

(defmacro caskxy--awhen (test &rest body)
  (declare (indent 1))
  `(let ((it ,test)) (when it ,@body)))

(defsubst caskxy--get-relate-env-vars ()
  '("EMACSLOADPATH" "EMACS" "INSIDE_EMACS" "PATH"))

(defmacro caskxy--with-clean-env (&rest body)
  (declare (indent 0))
  (let* ((bkup-sym-maker (lambda (s) (intern (concat "bkup-env-" (downcase s)))))
         (let-forms (loop for v in (caskxy--get-relate-env-vars)
                          for sym = (funcall bkup-sym-maker v)
                          collect `(,sym (getenv ,v))))
         (restore-forms (loop for v in (caskxy--get-relate-env-vars)
                              for sym = (funcall bkup-sym-maker v)
                              collect `(setenv ,v ,sym))))
    `(let (,@let-forms)
       (unwind-protect
           (progn
             (setenv "EMACSLOADPATH" nil)
             (setenv "INSIDE_EMACS" nil)
             ,@body)
         ,@restore-forms
         nil))))

(defun caskxy--run-shell-command (cmdstr &optional result-as-string)
  (let ((dbg-tmpl (mapconcat (lambda (s) (concat s ": %s")) (caskxy--get-relate-env-vars) "\n"))
        (dbg-vars (loop for v in (caskxy--get-relate-env-vars)
                        collect (getenv v))))
    (caskxy--trace (concat "execute : %s\n" dbg-tmpl) cmdstr dbg-vars)
    (if result-as-string
        (shell-command-to-string (concat cmdstr " 2>/dev/null"))
      (shell-command cmdstr caskxy--result-buffer-name)
      t)))

(defsubst caskxy--get-emacs-quick-command (argstr)
  (caskxy--trace "start get emacs quick command : %s" argstr)
  (format "'%s' -Q %s" (or (getenv "EMACS") "emacs") argstr))

(defsubst caskxy--get-emacs-batch-command (argstr)
  (caskxy--get-emacs-quick-command (concat "--batch " argstr)))

(defsubst caskxy--get-emacs-script-command (argstr)
  (caskxy--get-emacs-quick-command (concat "--script " argstr)))

(defun caskxy--do-exec (&optional cmdstr result-as-string)
  (when (not cmdstr)
   (setq cmdstr (read-string "Command: ")))
  (caskxy--trace "start do exec : %s" cmdstr)
  (caskxy--with-clean-env
    (setenv "EMACSLOADPATH" (caskxy/do-cask-command "load-path" t))
    (setenv "PATH" (caskxy/do-cask-command "path" t))
    (caskxy--run-shell-command cmdstr result-as-string)))

(defun caskxy--seek-test-files (&optional dir)
  (caskxy--trace "start seek test files : %s" dir)
  (loop with dir = (directory-file-name (or dir caskxy--cask-location))
        for node in (directory-files dir t "\\`[^._]")
        if (and (file-regular-p node)
                (string-match "\\<test\\>" node)
                (string-match "\\.el\\'" node))
        collect (progn (caskxy--trace "found test : %s" node)
                       node)
        else if (file-directory-p node)
        append (caskxy--seek-test-files node)))

(defun caskxy--make-load-file-option (load-files)
  (or (mapconcat (lambda (f) (concat "-l " (shell-quote-argument f))) load-files " ")
      ""))


;;;;;;;;;;;;;;;;;;;;
;; Tester Backend

;;;###autoload
(defun* caskxy/add-tester-backend (backend &key builder filter)
  "Add a test function.

BACKEND is the feature of the function.
BUILDER is the function to make a command string for test.
  The function receives one argument that is the list of test file path.
FILTER is the function to do something for the buffer of the test result.
  The function receives one argument that is the buffer object of the test result.
  If nothing to do, this value is no need."
  (caskxy--trace "start add tester backend[%s]. builder[%s] filter[%s]" backend builder filter)
  (cond ((not (symbolp backend))
         (caskxy--show-message "Failed add tester backend. Backend is not symbol : %s" backend))
        ((not (functionp builder))
         (caskxy--show-message "Failed add tester backend. Builder is not function : %s" builder))
        ((and filter
              (not (functionp filter)))
         (caskxy--show-message "Failed add tester backend. Filter is not function : %s" filter))
        (t
         (caskxy--awhen (assq backend caskxy--tester-backends)
           (setq caskxy--tester-backends (delq it caskxy--tester-backends)))
         (push `(,backend . (:builder ,builder :filter ,filter)) caskxy--tester-backends))))

(defun caskxy/build-ert (test-files)
  (format "%s -f ert-run-tests-batch-and-exit" (caskxy--make-load-file-option test-files)))

(caskxy/add-tester-backend 'ert :builder 'caskxy/build-ert)

(defun caskxy/build-el-expectations (test-files)
  (let* ((tmpdir (loop for envnm in '("TMP" "TEMP" "TMPDIR")
                       for evalue = (getenv envnm)
                       if (and (stringp evalue)
                               (file-directory-p evalue))
                       return evalue
                       finally return "/tmp"))
         (tmpfile (format "%s/.el-expectations.%s.result"
                          (directory-file-name tmpdir)
                          (format-time-string "%Y%m%d%H%M%S"))))
    (format "%s -f batch-expectations %s ; cat %s"
            (caskxy--make-load-file-option test-files)
            (shell-quote-argument tmpfile)
            (shell-quote-argument tmpfile))))

(defun caskxy/filter-el-expectations (buff)
  (caskxy--trace "start filter el expectations.")
  (with-current-buffer buff
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^[0-9].+\\([0-9]\\) failures, \\([0-9]+\\) errors" nil t)
        (put-text-property (match-beginning 0) (match-end 0)
                           'face
                           (if (and (string= "0" (match-string 1))
                                    (string= "0" (match-string 2)))
                               exps-green-face
                             exps-red-face))))))

(caskxy/add-tester-backend 'el-expectations
                           :builder 'caskxy/build-el-expectations
                           :filter 'caskxy/filter-el-expectations)

(defun caskxy/build-ert-expectations (test-files)
  (format "%s -f batch-expectations" (caskxy--make-load-file-option test-files)))

(caskxy/add-tester-backend 'ert-expectations :builder 'caskxy/build-ert-expectations)


;;;;;;;;;;;;;;;;;;
;; User Command

;;;###autoload
(defun caskxy/set-emacs-runtime (&optional emacs)
  "Set the condition of emacs runtime.

EMACS is the executable path of the emacs runtime used for test."
  (interactive
   (list (read-file-name "Emacs executable path (emacs): " "/" "emacs")))
  (yaxception:$
    (yaxception:try
      (caskxy--trace "start set emacs : %s" emacs)
      (setenv "EMACS" (cond ((or (not (stringp emacs))
                                 (string= emacs ""))
                             "emacs")
                            ((executable-find emacs)
                             emacs)
                            (t
                             (expand-file-name emacs))))
      (caskxy--show-message "Set '%s'" (getenv "EMACS")))
    (yaxception:catch 'error e
      (caskxy--show-message "Failed set emacs runtime : %s" (yaxception:get-text e))
      (caskxy--error "failed set emacs runtime : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))))

;;;###autoload
(defun caskxy/set-cask-file (cask-file)
  "Set the condition of project path.

CASK-FILE is the path of 'Cask' file in the tested project."
  (interactive
   (list (read-file-name "Select 'Cask' file: " nil "Cask" t)))
  (yaxception:$
    (yaxception:try
      (caskxy--trace "start set location : %s" cask-file)
      (setq caskxy--cask-location (file-name-directory (expand-file-name cask-file)))
      (caskxy--show-message "Set '%s'" caskxy--cask-location))
    (yaxception:catch 'error e
      (caskxy--show-message "Failed set cask file : %s" (yaxception:get-text e))
      (caskxy--error "failed set cask file : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))))

;;;###autoload
(defun caskxy/set-tester-backend (backend)
  "Set BACKEND to `caskxy/tester-backend'."
  (interactive
   (list (completing-read "Select Backend (ert): " (mapcar 'car caskxy--tester-backends) nil t nil '() 'ert)))
  (yaxception:$
    (yaxception:try
      (caskxy--trace "start set tester backend : %s" backend)
      (when (and (stringp backend)
                 (not (string= backend "")))
        (setq backend (intern backend)))
      (if (not (symbolp backend))
          (caskxy--show-message "Invalid value : %s" backend)
        (setq caskxy/tester-backend backend)
        (caskxy--show-message "Set '%s" backend)))
    (yaxception:catch 'error e
      (caskxy--show-message "Failed set tester backend : %s" (yaxception:get-text e))
      (caskxy--error "failed set tester backend : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))))

;;;###autoload
(defun caskxy/show-condition ()
  "Show current condition."
  (interactive)
  (message (concat "[Cask Condition]\n"
                   (format "  Emacs Runtime: %s\n" (or (getenv "EMACS") "emacs"))
                   (format "  Project Path: %s\n" caskxy--cask-location)
                   (format "  Tester: %s" caskxy/tester-backend))))

;;;###autoload
(defun caskxy/do-cask-command (command &optional result-as-string)
  "Execute the command of Cask.

COMMAND is the string equals the sub command of 'cask' command on shell.
RESULT-AS-STRING is boolean. If non-nil, return the string of the result of 'cask' command."
  (interactive
   (list (completing-read "Select Command: " caskxy--cask-commands nil t nil '() "install")))
  (yaxception:$
    (yaxception:try
      (if (not (file-exists-p caskxy/cask-cli-path))
          (caskxy--show-message "Not found '%s'. Do you not yet install cask?" caskxy/cask-cli-path)
        (caskxy--trace "start do cask command : %s" command)
        (if (string= command "exec")
            (caskxy--do-exec nil result-as-string)
          (caskxy--trace "call cask-cli command : %s" command)
          (let ((default-directory caskxy--cask-location))
            (caskxy--with-clean-env
              (caskxy--run-shell-command
                (caskxy--get-emacs-script-command
                 (format "%s -- %s"
                         (shell-quote-argument (expand-file-name caskxy/cask-cli-path))
                         command))
                result-as-string))))))
    (yaxception:catch 'error e
      (caskxy--show-message "Failed do cask command : %s" (yaxception:get-text e))
      (caskxy--error "failed do cask command : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))))

;;;###autoload
(defun caskxy/run-test (test-file)
  "Run test of TEST-FILE.

TEST-FILE is the path of test file.
But if TEST-FILE is 'all, do the tests of all test files in the project."
  (interactive
   (list (completing-read "Select Test (all): "
                          (append (list 'all)
                                  (caskxy--seek-test-files))
                          nil t nil '() "all")))
  (yaxception:$
    (yaxception:try
      (caskxy--trace "start run test : %s" test-file)
      (when (y-or-n-p (format "Start '%s' test using '%s ?" test-file caskxy/tester-backend))
        (let* ((test-files (cond ((string= test-file "all") (caskxy--seek-test-files))
                                 (t                         (list test-file))))
               (bkendinfo (or (assoc-default caskxy/tester-backend caskxy--tester-backends)
                              (caskxy--show-message "Unknown Backend : %s" caskxy/tester-backend)))
               (builder (or (when bkendinfo (plist-get bkendinfo :builder))
                            (caskxy--show-message "Not exists builder of %s" caskxy/tester-backend)))
               (filter (when bkendinfo (plist-get bkendinfo :filter)))
               (cmdarg (when builder
                         (caskxy--trace "call builder function : %s" builder)
                         (funcall builder test-files)))
               (load-tested (concat "-L " (shell-quote-argument caskxy--cask-location)))
               (cmd (when (and (stringp cmdarg)
                               (not (string= cmdarg "")))
                      (caskxy--get-emacs-batch-command (concat load-tested " " cmdarg))))
               (default-directory caskxy--cask-location))
          (when cmd
            (caskxy--do-exec cmd)
            (caskxy--awhen (and filter
                                (get-buffer caskxy--result-buffer-name))
              (when (buffer-live-p it)
                (caskxy--trace "call filter function : %s" filter)
                (funcall filter it)))))))
    (yaxception:catch 'error e
      (caskxy--show-message "Failed run test : %s" (yaxception:get-text e))
      (caskxy--error "failed run test : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))))


(provide 'caskxy)
;;; caskxy.el ends here
