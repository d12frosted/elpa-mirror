;;; sas-py.el --- SAS with SASPy                     -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Shuguang Sun <shuguang79@qq.com>

;; Author: Shuguang Sun <shuguang79@qq.com>
;; Created: 2023/01/26
;; Version: 0.2
;; Package-Version: 20230131.523
;; Package-Commit: 76a2226eb49ec37f211904c6395ee066bd440560
;; URL: https://github.com/ShuguangSun/sas-py
;; Package-Requires: ((emacs "28.1") (ess "18.10.1"))
;; Keywords: tools

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

;; SAS with SASPy

;; It runs an interactive python shell and wraps the utilities from SASPy to
;; make it convenient to work with SAS for any kind of SASPy supported SAS
;; deployments, for example, IOM for local installed SAS on Windows, IOM for
;; remote workspace server (e.g. SAS OA), and HTTP for SAS Viya.  For more access
;; method, please refer to the documents of SASPy

;; To install SASPy in Python:
;; pip install saspy

;; Usage:
;; 1. Set `sas-py-cfgname' to the config.
;; 2. Call `run-sas-py'
;; 3. `sas-py-submit-file' or `sas-py-submit-region'

;;; Code:

(require 'python)
(require 'ess-sas-d)

(defgroup sas-py ()
  "SAS-py, SAS with SASPy."
  :group 'ess
  :prefix "sas-py-")


(defcustom sas-py-cfgname "winlocal"
  "The cfgname.

Using default or defined in the `sascfg_personal.py'."
  :type 'string
  :local t
  :group 'sas-py-)

(defcustom sas-py-results-format "TEXT"
  "The results_format, `TEXT', `HTML' or `Pandas'."
  :type '(choice (string :tag "TEXT" "TEXT")
                 (string :tag "HTML" "HTML")
                 (string :tag "Pandas" "Pandas"))
  :group 'sas-py-)

(defcustom sas-py-batchp t
  "Sets the batch attribute for the SASsession object or not."
  :type 'booleanp
  :group 'sas-py-)


(defcustom sas-py-remote-name-ip-map nil
  "A list of the server name and ip mapping.

For example, the workspace server may have a name `foo.bar.com'
and IP address `192.168.6.1'.  Sometimes it only accepts the IP
address, but `disconnect' returns a `reconuri' with server name.
It needs to replace the server name with IP address in the
`reconuri'.

For example,
      (setq sas-py-remote-name-ip-map \\='(\"foo.bar.com\" \"192.168.6.1\"))"
  :type 'listp
  :group 'sas-py-)

(defcustom sas-py-interpreter-args ""
  "String of arguments used when starting Python for SASpy."
  :type 'string
  :group 'sas-py)


(defcustom sas-py-python-shell-dedicated 'project
  "Whether to make Python shells dedicated by default.

See also `python-shell-dedicated' for more information.."
  :type '(choice (const :tag "To buffer" buffer)
                 (const :tag "To project" project)
                 (const :tag "Not dedicated" nil))
  :group 'sas-py)

(defcustom sas-py-sleep-for-shell
  (if (memq system-type '(ms-dos windows-nt)) 5 1)
  "Pause before sending output to the shell."
  :type  'number
  :group 'sas-py)


(defvaralias 'sas-py-current-process-name 'sas-py-local-process-name)
(defvar-local sas-py-local-process-name nil
  "The name of the Python process associated with the current buffer.")
(put 'sas-py-local-process-name 'risky-local-variable t)
(put 'sas-py-local-process-name 'permanent-local t)

(defvar sas-py-process-name-list nil
  "Alist of active Python processes.")


(defvar sas-py-regex-parse-log
  (downcase
   (concat
    "^ERROR [0-9]+-[0-9]+:|^ERROR:|_ERROR_=1|ERROR DETECTED"
    "|^WARNING [0-9]+-[0-9]+:|^WARNING:"
    "|^NOTE [0-9]+-[0-9]+:"
    "|^NOTE: SAS went to a new line when INPUT statement reached past"
    "|^NOTE: Compressing data set .* increased size by"
    "|^note.+not (included|met|positive def|found|used)"
    "|^note.+(more than one|uninitialized|be singular|infinite likelihood|nonpositive definite|no statistics|undefined|invalid data)"
    "|Bus Error In Task|Segmentation Violation In Task"))
  "The grep extended regex for parsing the SAS LOG.")


(defvar sas-py-python-init-string "
import saspy
import timeit
from datetime import timedelta
from datetime import datetime
import re
import warnings

print(datetime.now())
tic = timeit.default_timer()

try:
    emacs_session

    if emacs_session is None:
        emacs_session = saspy.SASsession(cfgname='%1$s', results='%2$s')
    elif emacs_session.reconuri:
        emacs_session = saspy.SASsession(reconuri = emacs_session.reconuri.replace(
            \"%3$s\", \"%4$s\"))
    elif not emacs_session.SASpid:
        emacs_session = saspy.SASsession(cfgname='%1$s', results='%2$s')
except NameError:
    # emacs_session = None
    emacs_session = saspy.SASsession(cfgname='%1$s', results='%2$s')


print(emacs_session)

emacs_log_pattern = re.compile(\"^error [0-9]+-[0-9]+:|^error:|_error_=1 _n_=|_error_=1[ ]?$|^warning [0-9]+-[0-9]+:^warning:|note: sas went to a new line when input statement reached past|note: compressing data set .* increased size by|note: error detected in annotate=|^note.+not (included|met|positive def|found|used)|^note.+(more than one|uninitialized|be singular|infinite likelihood|nonpositive definite|no statistics|undefined)|bus error in task|segmentation violation in task\", re.IGNORECASE)


def emacs_saspy_submit_file(sas_fname : str,
                            log_fname : str,
                            lst_fname : str,
                            results_format : str = 'HTML'):

    print(datetime.now())
    tic = timeit.default_timer()

    try:
        emacs_session

        if emacs_session is None:
            print(\"No SAS session attached!\")
    except NameError:
        print(\"No SAS session attached!\")

    with open(sas_fname,mode='r') as sas_file:
        sas_code_txt = sas_file.read()

    ll = emacs_session.submit(sas_code_txt, results=results_format.upper())

    with open(log_fname, 'w') as f1:
        f1.write(ll['LOG'])

    with open(lst_fname, 'w') as f2:
        f2.write(ll['LST'])

    print(\"Is there an error:\", emacs_session.check_error_log)

    line_number = 0
    with open(log_fname, 'r') as f1:
        for line in f1:
            line_number += 1
            if re.search(emacs_log_pattern, line):
                print(f\"{log_fname}:{line_number}:{line}\")

    toc = timeit.default_timer()
    print(\"Time elapsed:\", toc - tic)


def emacs_saspy_submit_region(sas_code : str,
                              log_fname : str,
                              lst_fname : str,
                              results_format : str = 'HTML'):

    print(datetime.now())
    tic = timeit.default_timer()

    try:
        emacs_session

        if emacs_session is None:
            print(\"No SAS session attached!\")
    except NameError:
        print(\"No SAS session attached!\")

    ll = emacs_session.submit(sas_code, results=results_format.upper())

    with open(log_fname, 'w') as f1:
        f1.write(ll[\"LOG\"])

    with open(lst_fname, 'w') as f2:
        f2.write(ll[\"LST\"])

    print(\"Is there an error: \", emacs_session.check_error_log)

    line_number = 0
    with open(log_fname, 'r') as f1:
        for line in f1:
            line_number += 1
            if re.search(emacs_log_pattern, line):
                print(f\"{log_fname}:{line_number}:{line}\")

    toc = timeit.default_timer()
    print(\"Time elapsed:\", toc - tic)


def emacs_saspy_submit_context(sas_code : str,
                               log_fname : str,
                               lst_fname : str,
                               results_format : str = 'HTML'):

    print(datetime.now())
    tic = timeit.default_timer()

    with saspy.SASsession() as sas:
        ll = sas.submit(sas_code, results=results_format.upper())

        with open(log_fname, 'w') as f1:
            f1.write(ll['LOG'])

        with open(lst_fname, 'w') as f2:
            f2.write(ll['LST'])

        print(\"Is there an error: \", sas.check_error_log)

    line_number = 0
    with open(log_fname, 'r') as f1:
        for line in f1:
            line_number += 1
            if re.search(emacs_log_pattern, line):
                print(f\"{log_fname}:{line_number}:{line}\")

    toc = timeit.default_timer()
    print(\"Time elapsed:\", toc - tic)


# FIXME: not work well now
def emacs_saspy_reconnect(sas : 'saspy.SASsession' = emacs_session,
                          log_fname : str = ' ') -> 'saspy.SASsession' :
    print(log_fname)
    print(sas)
    print(sas.reconuri)

    if not sas.reconuri:
        with open(log_fname,mode='r') as log_file:
            reconuri = log_file.read()

        emacs_session = saspy.SASsession(reconuri = reconuri)
    else:
        emacs_session = saspy.SASsession(reconuri = sas.reconuri.replace(
            \"%3$s\", \"%4$s\"))

    print(emacs_session)
    print(emacs_session.reconuri)
    return emacs_session


def emacs_saspy_disconnect(log_fname : str) :

    try:
        emacs_session

        if emacs_session is None:
            print(\"No SAS session attached!\")
    except NameError:
        print(\"No SAS session attached!\")

    emacs_session.disconnect()

    with open(log_fname, 'w') as f1:
        f1.write(emacs_session.reconuri)

    print(\"Disconnected!\")

toc = timeit.default_timer()
print(\"Time elapsed:\", toc - tic)

"
  "Init code for saspy.")


;;; * init stuff

(defun sas-py-initialize-on-start ()
  "This function is run after the first R prompt.
Executed in process buffer."
  (interactive)
  (let ((sas-py-python-init-string
         (format sas-py-python-init-string
                 sas-py-cfgname
                 sas-py-results-format
                 (if sas-py-remote-name-ip-map
                     (car sas-py-remote-name-ip-map) " ")
                 (if sas-py-remote-name-ip-map
                     (cadr sas-py-remote-name-ip-map) " "))))
    (python-shell-send-string sas-py-python-init-string)))

;;;###autoload
(defun run-sas-py (&optional start-args dedicated show)
  "Call `run-python' with optional arugment START-ARGS and DEDICATED.

If you have certain command line arguments that should always be passed
to `run-python', put them in the variable `sas-py-interpreter-args'.

START-ARGS can be a string representing an argument.
When numeric prefix arg is other than 0 or 4 do not SHOW.

See also DEDICATED in `run-pthon'."
  (interactive
   (if current-prefix-arg
       (list
        (read-shell-command "Run Python: "
                            (concat (python-shell-calculate-command)
                                    sas-py-interpreter-args))
        (alist-get (car (read-multiple-choice "Make dedicated process?"
                                              '((?b "to buffer")
                                                (?p "to project")
                                                (?n "no"))))
                   '((?b . buffer) (?p . project)))
        (= (prefix-numeric-value current-prefix-arg) 4))
     (list (concat (python-shell-calculate-command)
                   sas-py-interpreter-args)
           sas-py-python-shell-dedicated
           t)))

  (let* ((inf-proc (run-python start-args dedicated show))
         (proc-name (process-name inf-proc))
         (inf-buf (process-buffer inf-proc)))
    (with-current-buffer inf-buf
      (sleep-for sas-py-sleep-for-shell)
      (sas-py-initialize-on-start)
      (comint-goto-process-mark)
      (setq-local ess-dialect "SAS")
      (setq-local sas-py-local-process-name proc-name)
      (let ((conselt (assoc proc-name sas-py-process-name-list)))
        (unless conselt
          (setq sas-py-process-name-list
                (cons (cons proc-name nil) sas-py-process-name-list)))))
    ;; set local process name of SAS file
    (if (equal "SAS" ess-dialect)
        (setq-local sas-py-local-process-name proc-name))
    inf-buf))

;;;###autoload
(defun sas-py (&optional start-args dedicated)
  "Run `sas-py' in the same directory of the SAS file.

START-ARGS can be a string representing an argument.
When numeric prefix arg is other than 0 or 4 do not SHOW.

See also DEDICATED in `run-pthon'."
  (interactive "P")
  (set-buffer (run-sas-py start-args dedicated)))


(defun sas-py-switch-to-python ()
  "Switch to the current inferior Python process buffer.

See also `ess-switch-to-ESS'."
  (interactive)
  (pop-to-buffer
   (buffer-name (process-buffer (sas-py-get-process)))
   '(nil . ((inhibit-same-window . t))))
  (goto-char (point-max)))

(defun sas-py-switch-to-inferior-or-script-buffer ()
  "Switch between script and process buffer.

See also `ess-switch-to-inferior-or-script-buffer'."
  (interactive)
  ;; this make it not to use ESS function directly.
  (if (derived-mode-p 'inferior-python-mode)
      (let ((dialect "SAS")
            (proc-name sas-py-local-process-name)
            (blist (buffer-list)))
        (while (and (pop blist)
                    (with-current-buffer (car blist)
                      (not (or (and (ess-derived-mode-p)
                                    (equal dialect ess-dialect)
                                    (null sas-py-local-process-name))
                               (and (ess-derived-mode-p)
                                    (equal proc-name sas-py-local-process-name)))))))
        (if blist
            (pop-to-buffer (car blist))
          (message "Found no buffers for `ess-dialect' %s associated with process %s"
                   dialect proc-name)))
    (sas-py-switch-to-python)))

(defun sas-py-get-process-buffer (&optional name)
  "Return the buffer associated with the Python process named by NAME.

See also `ess-get-process-buffer'."
  (process-buffer (sas-py-get-process (or name sas-py-local-process-name))))

(defun sas-py-update-process-name-list ()
  "Remove names with no process.

See also `update-ess-process-name-list'."
  (let (defunct)
    (dolist (conselt sas-py-process-name-list)
      (let ((proc (get-process (car conselt))))
        (unless (and proc (eq (process-status proc) 'run))
          (push conselt defunct))))
    (dolist (pointer defunct)
      (setq sas-py-process-name-list (delq pointer sas-py-process-name-list))))
  (if (eq (length sas-py-process-name-list) 0)
      (setq sas-py-current-process-name nil)))

(defun sas-py-get-process (&optional name use-another)
  "Return the Python process named by NAME.
If USE-ANOTHER is non-nil, and the process NAME is not
running (anymore), try to connect to another if there is one. By
default (USE-ANOTHER is nil), the connection to another process
happens interactively (when possible).

See also `ess-get-process'."
  (setq name (or name sas-py-local-process-name))
  (cl-assert name nil "No Python process is associated with this buffer now")
  (sas-py-update-process-name-list)
  (cond ((assoc name sas-py-process-name-list)
         (get-process name))
        ((= 0 (length sas-py-process-name-list))
         (save-current-buffer
           (message "trying to (re)start process %s for language SAS ..."
                    name)
           (run-sas-py nil sas-py-python-shell-dedicated t)
           ;; and return the process: "call me again"
           (sas-py-get-process name)))
        ;; else: there are other running processes
        (use-another ; connect to another running process : the first one
         (let ((other-name (car (elt sas-py-process-name-list 0))))
           ;; "FIXME": try to find the process name that matches *closest*
           (message "associating with *other* process '%s'" other-name)
           (sas-py-get-process other-name)))
        (t (error "Process %s is not running" name))))

(defun sas-py-request-a-process (message &optional noswitch ask-if-1)
  "Ask for a process, and make it the current Python process.
If there is exactly one process, only ask if ASK-IF-1 is non-nil.
Also switches to the process buffer unless NOSWITCH is non-nil.
Interactively, NOSWITCH can be set by giving a prefix argument.
Returns the name of the selected process. MESSAGE may get passed
to `completing-read'.

See also `ess-request-a-process'."
  (interactive (list "Switch to which Python process? " current-prefix-arg))
  (sas-py-update-process-name-list)
  (let* ((pname-list (delq nil ;; keep only those matching dialect
                           (append
                            (mapcar (lambda (lproc)
                                      (and (equal "SAS"
                                                  (buffer-local-value
                                                   'ess-dialect
                                                   (process-buffer (get-process (car lproc)))))
                                           (not (equal sas-py-local-process-name (car lproc)))
                                           (car lproc)))
                                    sas-py-process-name-list)
                            ;; append local only if running
                            (when (assoc sas-py-local-process-name sas-py-process-name-list)
                              (list sas-py-local-process-name)))))
         (num-processes (length pname-list))
         proc auto-started?)
    (when (= 0 num-processes)
      (run-sas-py nil sas-py-python-shell-dedicated t)
      (setq num-processes 1
            pname-list (car sas-py-process-name-list)
            auto-started? t))
    ;; now num-processes >= 1 :
    (let* ((proc-buffers (mapcar (lambda (lproc)
                                   (buffer-name (process-buffer (get-process lproc))))
                                 pname-list)))
      (setq proc
            (if (or auto-started?
                    (and (not ask-if-1)
                         (= 1 num-processes)
                         (message "Using process `%s'" (car proc-buffers))))
                (car pname-list)
              (unless (and sas-py-current-process-name
                           (get-process sas-py-current-process-name))
                (setq sas-py-current-process-name nil))
              ;; ask for buffer name not the *real* process name:
              (let ((buf (completing-read message (append proc-buffers (list "*new*")) nil t nil nil)))
                (if (not (equal buf "*new*"))
                    (process-name (get-buffer-process buf))
                  ;; Prevent new process buffer from being popped
                  ;; because we handle display depending on the value
                  ;; of `no-switch`
                  (run-sas-py nil sas-py-python-shell-dedicated t)
                  (caar sas-py-process-name-list))))))
    ;; Always display buffer if auto-started but do not select it if
    ;; NOSWITCH is set
    (when (or auto-started? (not noswitch))
      (let ((proc-buf (sas-py-get-process-buffer proc)))
        (if noswitch
            (display-buffer proc-buf)
          (pop-to-buffer proc-buf))))
    proc))


(defun sas-py-force-buffer-current (&optional prompt force no-autostart ask-if-1)
  "Make sure the current buffer is attached to an Python process.
If not, or FORCE (prefix argument) is non-nil, prompt for a
process name with PROMPT. If NO-AUTOSTART is nil starts the new
process if process associated with current buffer has
died. `sas-py-local-process-name' is set to the name of the process
selected.  ASK-IF-1 asks user for the process, even if
there is only one process running.  Returns the inferior buffer if
it was successfully forced, throws an error otherwise.

See also `ess-force-buffer-current'."
  (interactive
   (list (concat "SAS" " process to use: ") current-prefix-arg nil))
  (let ((proc-name sas-py-local-process-name))
    (cond ((and (not force) proc-name (get-process proc-name)))
          ;; Make sure the source buffer is attached to a process
          ((and sas-py-local-process-name (not force) no-autostart)
           (error "Process %s has died" sas-py-local-process-name))
          ;; Request a process if `sas-py-local-process-name' is nil
          (t
           (let* ((prompt (or prompt "Process to use: "))
                  (proc (sas-py-request-a-process prompt 'no-switch ask-if-1)))
             (setq sas-py-local-process-name proc)))))
  (process-buffer (get-process sas-py-local-process-name)))


;;;###autoload
(defun sas-py-python-init (&optional cfgname results_format)
  "Init SASPy session with optional CFGNAME and RESULTS_FORMAT.

Optional argument CFGNAME is defined in `sascfg_personal.py'.
Optional argument RESULTS_FORMAT is one of `TEXT', `HTML' or `Pandas'."
  (interactive (list sas-py-cfgname sas-py-results-format))
  (when current-prefix-arg
    (setq cfgname (read-string "cfgname: " sas-py-cfgname nil sas-py-cfgname))
    (setq results_format (completing-read "results_format: "
                                          '("TEXT" "HTML" "PANDAS") nil t
                                          sas-py-results-format)))
  (let ((sas-py-python-init-string
         (format sas-py-python-init-string
                 cfgname
                 results_format
                 (if sas-py-remote-name-ip-map
                     (car sas-py-remote-name-ip-map) " ")
                 (if sas-py-remote-name-ip-map
                     (cadr sas-py-remote-name-ip-map) " "))))
    (python-shell-send-string sas-py-python-init-string)))




(defun sas-py-set_results ()
  "Set the format of results."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((res-format (completing-read "results_format:" '("Pandas" "HTML" "TEXT") nil t))
        (proc (sas-py-get-process)))
    (setq sas-py-results-format (upcase res-format))
    (python-shell-send-string
     (format "emacs_session.set_results('%s')" res-format)
     proc)))

(defun sas-py-set_batch ()
  "Toggle batch mode.

Set `set_batch' to `True' or `False'."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((batchp (completing-read "batch:" '("True" "False") nil t))
        (proc (sas-py-get-process)))
    (setq sas-py-batchp (string= batchp "True"))
    (python-shell-send-string
     (format "emacs_session.set_batch(%s)" batchp)
     proc)))

(defun sas-py-submit-string ()
  "Submit a string or a piece of SAS code."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((sas-code (read-string "sas code: " nil nil))
        (res-format (completing-read "results_format:" '("Pandas" "HTML" "TEXT") nil t "TEXT"))
        (proc (sas-py-get-process)))
    (python-shell-send-string
     (format "emacs_session.submitLST(\"\"\"%s\"\"\", '%s')"
             sas-code
             res-format)
     proc)))

;;; * submit stuff

;;;###autoload
(defun sas-py-submit-file (&optional res-format)
  "Submit SAS code file.

Optional argument RES-FORMAT results_format of `HTML' or `TEXT'."
  (interactive
   (if current-prefix-arg
      (list (completing-read "results_format:" '("HTML" "TEXT") nil t))
     (list sas-py-results-format)))

  (ess-sas-file-path)
  (ess-sas-goto-sas)
  (save-buffer)
  (hack-local-variables)

  (sas-py-force-buffer-current "Process to use: ")

  (let* ((tmpnm (file-name-sans-extension ess-sas-file-path))
         (saspy-code
         (format "emacs_saspy_submit_file(%s, %s, %s, results_format ='%s')\n"
                 (shell-quote-argument ess-sas-file-path)
                 (shell-quote-argument (concat tmpnm ".log"))
                 (if (string= (upcase res-format) "TEXT")
                     (shell-quote-argument (concat tmpnm ".lst"))
                   (shell-quote-argument (concat tmpnm ".html")))
                 (upcase res-format)))
         (proc (sas-py-get-process)))
    (python-shell-send-string saspy-code proc)))


;;;###autoload
(defun sas-py-submit-region (&optional res-format)
  "Submit region.

Optional argument RES-FORMAT results_format of `HTML' or `TEXT'."
  (interactive
   (if current-prefix-arg
      (list (completing-read "results_format:" '("HTML" "TEXT") nil t))
     (list sas-py-results-format)))

  (ess-sas-file-path)
  (hack-local-variables)
  (sas-py-force-buffer-current "Process to use: ")

  (if (use-region-p)
      (write-region (region-beginning) (region-end)
                    (concat (ess-sas-temp-root) ".sas"))
    (write-region (point-min) (point-max)
                  (concat (ess-sas-temp-root) ".sas")))

  (let* ((tmpnm (concat (file-name-sans-extension ess-sas-file-path)
                        ess-sas-temp-root))
         (saspy-code
          (format "emacs_saspy_submit_file(%s, %s, %s, results_format ='%s')\n"
                  (shell-quote-argument (concat tmpnm ".sas"))
                  (shell-quote-argument (concat tmpnm ".log"))
                  (if (string= (upcase res-format) "TEXT")
                      (shell-quote-argument (concat tmpnm ".lst"))
                    (shell-quote-argument (concat tmpnm ".html")))
                  (upcase res-format)))
         (proc (sas-py-get-process)))
    (python-shell-send-string saspy-code proc)))

;;;###autoload
(defun sas-py-submit-to-pyshell (&optional res-format)
  "Submit without creating temporary SAS code file.

Optional argument RES-FORMAT results_format of `HTML' or `TEXT'."
  (interactive
   (if current-prefix-arg
      (list (completing-read "results_format:" '("HTML" "TEXT") nil t))
     (list sas-py-results-format)))

  (ess-sas-file-path)
  (ess-sas-goto-sas)
  (save-buffer)
  (hack-local-variables)

  (sas-py-force-buffer-current "Process to use: ")

  (let* ((tmpnm (concat (file-name-sans-extension ess-sas-file-path)
                        (if (use-region-p) ess-sas-temp-root)))
         (code-string
          (if (use-region-p)
              (buffer-substring-no-properties (region-beginning) (region-end))
            (buffer-substring-no-properties (point-min) (point-max))))
         (saspy-code
          (format "emacs_saspy_submit_region(\"\"\"%s\"\"\", %s, %s, results_format ='%s')\n"
                  code-string
                  (shell-quote-argument (concat tmpnm ".log"))
                  (if (string= (upcase res-format) "TEXT")
                      (shell-quote-argument (concat tmpnm ".lst"))
                    (shell-quote-argument (concat tmpnm ".html")))
                  (upcase res-format)))
         (proc (sas-py-get-process)))
    (python-shell-send-string saspy-code proc)))


;;;###autoload
(defun sas-py-submit-in-context (&optional res-format)
  "Submit in context.

Run the code in a temporary SAS session.

Optional argument RES-FORMAT results_format of `HTML' or `TEXT'."
  (interactive
   (if current-prefix-arg
      (list (completing-read "results_format:" '("HTML" "TEXT") nil t))
     (list sas-py-results-format)))

  (ess-sas-file-path)
  (ess-sas-goto-sas)
  (save-buffer)
  (hack-local-variables)

  (sas-py-force-buffer-current "Process to use: ")

  (let* ((tmpnm (concat (file-name-sans-extension ess-sas-file-path)
                        (if (use-region-p) ess-sas-temp-root)))
         (code-string
          (if (use-region-p)
              (buffer-substring-no-properties (region-beginning) (region-end))
            (buffer-substring-no-properties (point-min) (point-max))))
         (saspy-code
          (format "emacs_saspy_submit_context(\"\"\"%s\"\"\", %s, %s, results_format ='%s')\n"
                  code-string
                  (shell-quote-argument (concat tmpnm ".log"))
                  (shell-quote-argument
                   (concat tmpnm (if (string= (upcase res-format) "TEXT")
                                     ".lst" ".html")))
                  (upcase res-format)))
         (proc (sas-py-get-process)))
    (python-shell-send-string saspy-code proc)))


;;; * Utilities

(defun sas-py-getwd ()
  "Print current working directory."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((proc (sas-py-get-process)))
    (python-shell-send-string
     "emacs_session.submitLST('%put %sysfunc(dlgcdir());','TEXT')"
     proc)))

(defun sas-py-setwd ()
  "Change current working directory.

If working with a remote server, it should be the path in the remote."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((dir (read-string "Remote Directory: " "%sysget(USERPROFILE)/Documents"))
        (proc (sas-py-get-process)))
    (python-shell-send-string
     (format "emacs_session.submitLST('%%put %%sysfunc(dlgcdir(\"%s\"));','TEXT')"
             dir)
     proc)))

(defun sas-py-list-options ()
  "List SAS options."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((proc (sas-py-get-process)))
    (python-shell-send-string
     (if current-prefix-arg
         ;; all options
         "emacs_session.submitLST('proc options;run;','TEXT')"
       ;; only portable
       "emacs_session.submitLST('proc options nohost;run;','TEXT')")
     proc)))

(defun sas-py-list-macro-vars ()
  "List macro variables."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((proc (sas-py-get-process)))
    (python-shell-send-string
     (if current-prefix-arg
         ;; all options
         "emacs_session.submitLST('%put _all_;','TEXT')"
       ;; only portable
       "emacs_session.submitLST('%put _global_;','TEXT')")
     proc)))


(defun sas-py-sascfg ()
  "Show the config file used in this session."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((proc (sas-py-get-process)))
    (python-shell-send-string "print(saspy.SAScfg)" proc)))

(defun sas-py-list_configs ()
  "List config files."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((proc (sas-py-get-process)))
    (python-shell-send-string "print(saspy.list_configs())"
                              proc)))

;;;###autoload
(defun sas-py-grep-log ()
  "Grep the log file for error or warnings."
  (interactive)
  (ess-sas-file-path)
  (ess-sas-goto-sas)
  (save-buffer)
  (hack-local-variables)
  (let ((compile-command
         (concat
          "grep -i -n -H -E \"" sas-py-regex-parse-log "\" "
          (shell-quote-argument
           (concat (file-name-sans-extension (file-name-nondirectory ess-sas-file-path))
                   (if current-prefix-arg
                       (concat ess-sas-temp-root ".log")
                       ".log"))))))
    (compile compile-command)
    (pop-to-buffer next-error-last-buffer)))

(defun sas-py-disconnect ()
  "Disconnect."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let* ((reconuri-file (read-file-name "reconuri-file: "
                                        (project-root (project-current t))
                                        "saspy" nil))
         (saspy-code
          (format "emacs_saspy_disconnect(%s)\n"
                  (shell-quote-argument
                   (concat reconuri-file ".reconuri"))))
         (proc (sas-py-get-process)))
    (python-shell-send-string saspy-code proc)))

(defun sas-py-reconnect ()
  "Reconnect."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let* ((proc (sas-py-get-process))
         (session (python-shell-send-string-no-output
                    "try: emacs_session\nexcept NameError: emacs_session = None"
                    proc))
         (reconuri (python-shell-send-string-no-output
                    "if emacs_session is not None:\n    print(emacs_session.reconuri)\n"
                    proc))
         reconuri-file
         saspy-code)
    (if (> (length reconuri) 0)
        (setq saspy-code
              (if sas-py-remote-name-ip-map
                  (format "emacs_session = saspy.SASsession(reconuri = emacs_session.reconuri.replace(
    \"%s\", \"%s\"))"
                          (car sas-py-remote-name-ip-map)
                          (cadr sas-py-remote-name-ip-map))
                "emacs_session = saspy.SASsession(reconuri = emacs_session.reconuri"))
      ;; if there is no reconuri returned
      (when (= (length session) 0)
        (setq reconuri-file (read-file-name "reconuri file: "
                                            (project-root (project-current t))))
        (with-temp-buffer
          (insert-file-contents reconuri-file)
          (setq saspy-code (buffer-substring-no-properties
                            (line-beginning-position) (line-end-position)))
          (if sas-py-remote-name-ip-map
              ;; Better to use `string-replace' for Emacs 28.1
              (setq saspy-code
                    (let ((case-fold-search nil))
                      (replace-regexp-in-string
                       (car sas-py-remote-name-ip-map)
                       (cadr sas-py-remote-name-ip-map)
                       saspy-code
                       t t))))
          (setq saspy-code (format "emacs_session = saspy.SASsession(reconuri = \"%s\")" saspy-code)))))
    (python-shell-send-string saspy-code proc))
  (python-shell-send-string "print(emacs_session)\nprint(emacs_session.reconuri)"
                            (sas-py-get-process)))


(defun sas-py-endsas ()
  "End SAS session."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((proc (sas-py-get-process)))
    (python-shell-send-string "emacs_session.endsas()" proc)))

(defun sas-py-lastlog ()
  "Print lastlog."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((proc (sas-py-get-process)))
    (python-shell-send-string "print(emacs_session.lastlog())" proc)))

(defun sas-py-saslog ()
  "Print the full saslog."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((proc (sas-py-get-process)))
    (python-shell-send-string "print(emacs_session.saslog())" proc)))

(defun sas-py-assigned_librefs ()
  "Print assigned librefs."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let ((proc (sas-py-get-process)))
    (python-shell-send-string "print(emacs_session.assigned_librefs())"
                              proc)))

(defun sas-py-list_tables ()
  "Print the list of tables in a library (libref)."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let* ((proc (sas-py-get-process))
         (lib-names (python-shell-send-string-no-output
                     "'&'.join(emacs_session.assigned_librefs())"
                     proc))
         (lib-name (completing-read
                    "library:"
                    (split-string (replace-regexp-in-string
                                   "\\`'\\(.+\\)'\\(?:\\'\\|$\\)" "\\1"
                                   lib-names) "&")))
         (saspy-code
          (format "print(emacs_session.list_tables('%s'))" lib-name)))
    (python-shell-send-string saspy-code proc)))


(defun sas-py-datasets ()
  "Print the list of datasets in a library (libref) using `PROC DATASETS'."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let* ((proc (sas-py-get-process))
         (lib-names (python-shell-send-string-no-output
                     "'&'.join(emacs_session.assigned_librefs())"
                     proc))
         (lib-name (completing-read
                    "library:"
                    (split-string (replace-regexp-in-string
                                   "\\`'\\(.+\\)'\\(?:\\'\\|$\\)" "\\1"
                                   lib-names) "&")))
         (saspy-code
          (format "print(emacs_session.datasets('%s'))" lib-name)))
    (python-shell-send-string saspy-code proc)))

(defun sas-py-get-dataset ()
  "Get a dataset."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let* ((proc (sas-py-get-process))
         (lib-names (python-shell-send-string-no-output
                     "'&'.join(emacs_session.assigned_librefs())"
                     proc))
         (lib-name (completing-read
                    "library:"
                    (split-string (replace-regexp-in-string
                                   "\\`'\\(.+\\)'\\(?:\\'\\|$\\)" "\\1"
                                   lib-names) "&")))
         (datasets (python-shell-send-string-no-output
                     (format "'&'.join([d[0] for d in emacs_session.list_tables('%s') if d[1] == 'DATA'])" lib-name)
                     proc))
         (dataset (completing-read
                   "Dataset:"
                   (split-string (replace-regexp-in-string
                                  "\\`'\\(.+\\)'\\(?:\\'\\|$\\)" "\\1"
                                  datasets) "&")))
         (saspy-code
          (format (concat "%1$s = emacs_session.sasdata('%1$s',libref='%2$s',results='TEXT')\n"
                          "print(%1$s)\n%1$s.columnInfo()")
                  dataset lib-name)))
    (python-shell-send-string saspy-code proc)))


(defun sas-py-lib_path ()
  "Print lib_path."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let* ((proc (sas-py-get-process))
         (lib-names (python-shell-send-string-no-output
                     "'&'.join(emacs_session.assigned_librefs())"
                     proc))
         (lib-name (completing-read
                    "library:"
                    (split-string (replace-regexp-in-string
                                   "\\`'\\(.+\\)'\\'" "\\1"
                                   lib-names) "&")))
         (saspy-code
          ;; libname work list;
          (format "print(emacs_session.lib_path('%s'))" lib-name)))
    (python-shell-send-string saspy-code proc)))


(declare-function shr-render-buffer "shr")
(defun sas-py-data-describe ()
  "Show describe/means of sas data."
  (interactive)
  (sas-py-force-buffer-current "Process to use: ")
  (let* ((proc (sas-py-get-process))
         (lib-names (python-shell-send-string-no-output
                     "'&'.join(emacs_session.assigned_librefs())"
                     proc))
         (lib-name (completing-read
                    "library:"
                    (split-string (replace-regexp-in-string
                                   "\\`'\\(.+\\)'\\(?:\\'\\|$\\)" "\\1"
                                   lib-names) "&")))
         (datasets (python-shell-send-string-no-output
                     (format "'&'.join([d[0] for d in emacs_session.list_tables('%s') if d[1] == 'DATA'])" lib-name)
                     proc))
         (dataset (completing-read
                   "Dataset:"
                   (split-string (replace-regexp-in-string
                                  "\\`'\\(.+\\)'\\(?:\\'\\|$\\)" "\\1"
                                  datasets) "&")))
         (saspy-code
          (format (concat
                   (if (string= (upcase sas-py-results-format) "HTML")
                       "emacs_session.set_batch('True')\n")
                   "___%1$s_ = emacs_session.sasdata('%1$s',libref='%2$s',results='%3$s')\n"
                   (if (string= (upcase sas-py-results-format) "HTML")
                       (if sas-py-batchp
                           "emacs_session.set_batch('True')\n"
                         "emacs_session.set_batch('False')\n"))
                   (if sas-py-batchp
                       "print(___%1$s_.describe()['LST'])\n"
                     "print(___%1$s_.describe())\n"))
                  dataset lib-name sas-py-results-format))
         (res (python-shell-send-string-no-output
               saspy-code
               proc)))
    (with-current-buffer (get-buffer-create "*saspy*")
      (erase-buffer)
      (insert res)
      (if (string= (upcase sas-py-results-format) "HTML")
          (progn (require 'shr)
                 (shr-render-buffer (current-buffer))))
      (goto-char (point-min))
      (pop-to-buffer (current-buffer)))))




(provide 'sas-py)
;;; sas-py.el ends here
