;;; autobuild.el --- Define and execute build rules and compilation pipelines -*- lexical-binding: t; -*-
;;
;; Filename: autobuild.el
;; Description: Define and execute composable build rules and compilation pipelines
;; Author: Ernesto Alfonso
;; Maintainer: (concat "erjoalgo" "@" "gmail" ".com")

;; Created: Wed Jan 23 20:45:01 2019 (-0800)
;; Version: 0.0.1
;; Package-Version: 20230518.438
;; Package-Commit: 1cd2d923303392cb1bb93fa0398332c2fce8399c
;; Package-Requires: ((cl-lib "0.3") (emacs "26.1") (selcand "0.0.1"))
;; URL: https://github.com/erjoalgo/autobuild
;; Keywords: compile, build, pipeline, autobuild, extensions, processes, tools
;; Compatibility:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;; A framework for defining and executing composable build rules and
;; synchronous or asynchronous compilation pipelines.
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change Log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:


(require 'cl-lib)
(require 'selcand)
(eval-when-compile (require 'subr-x))

(defvar autobuild-rules-list nil "A list of all known autobuild rules.")

(defvar autobuild-debug nil "Log rule names before generating their action.")

(defvar autobuild-nice nil
  "Dynamic var which an autobuild rule may setq when generating an action.

   This variable defines the 'nice' priority of the last generated action,
   with lower values commanding a higher priority.")

(defconst autobuild-nice-default 10
  "Default nice value for rule invocations that do not setq the variable ‘autobuild-nice’.")

(defcustom autobuild-candidate-default-hints
  "1234acdefqrstvwxz"
  "Default hint chars."
  :type 'string
  :group 'autobuild)

;; buffer-local
(defvar-local autobuild-compilation-start-time nil)
(defvar-local autobuild-last-compilation-buffer nil)
(defvar-local autobuild-last-local-invocation nil)

(defvar-local autobuild-pipeline-rules-remaining nil)

;; TODO
(defvar autobuild-pipeline-finish-hook nil
  "Hook called when the entire pipeline has finished.")


(defvar autobuild-history nil)

(defun autobuild-toggle-debug ()
  "Enable or disable `autobuild-debug`."
  (interactive)
  (message "setting autobuild-debug to %s"
           (setq autobuild-debug (not autobuild-debug))))

(defun autobuild-rule-p (rule)
  "Return non-nil if RULE has been registered as an autobuild rule."
  (and (functionp rule)
       (cl-find rule autobuild-rules-list)))

(defun autobuild-nice (nice)
  "A function wrapper for a rule to set the current action's NICE value."
  (setq autobuild-nice nice))

;; internal struct used to collect a rule's action and it's nice value
(cl-defstruct autobuild--invocation rule action nice)

;;;###autoload
(cl-defmacro autobuild-define-rule (name mode-filter &rest body)
  "Define a build rule NAME.

   When ‘major-mode' is in MODE-FILTER, or when MODE-FILTER is nil,
   the action-generator BODY is evaluated, which returns an action
   which must be one of the following types:

   nil if the generator doesn't know how to generate an action.
   string is interpreted as a ‘compile-command', which is executed via ‘compile'
   function is executed via ‘funcall'"
  (declare (indent defun))
  (unless (listp mode-filter)
    (error "Invalid major mode specification"))
  `(progn
     (defun ,name ()
       (when (autobuild-mode-filter-applicable-p ',mode-filter)
         ,@body))
     (cl-pushnew ',name autobuild-rules-list)))

;;;###autoload
(defmacro autobuild-pipeline (&rest buffer-rule-list)
  "Define a build pipeline.

  Each entry in BUFFER-RULE-LIST has the form (BUFFER RULE),
  where BUFFER is the next buffer in the pipeline, and RULE
  is the rule to invoke within BUFFER to generate an action.

  If ACTION is either a (compile command) string or a function that
  returns a compilation buffer, compilation is executed asynchronously
  and the pipeline is resumed upon compilation finish.  Otherwise, ACTION
  is executed synchronously.

  If any step in the compilation pipeline fails, via either an error or
  an abnormal compilation finish state, any remaining steps in the pipeline
  are aborted."

  `(lambda ()
     (autobuild-pipeline-run
      (list ,@(cl-loop for (buffer rule-name) in buffer-rule-list
                       collect `(list ,buffer ,rule-name))))))

(defun autobuild-rule-generate-action (rule)
  "Funcall wrapper to safely obtain an action for rule RULE."
  (cl-assert (autobuild-rule-p rule))
  (when autobuild-debug
    (message "considering autobuild rule: %s" rule))
  (let ((original-buffer (current-buffer)))
    (prog1
        (condition-case ex (funcall rule)
          (error
           (error "Error while generating action for rule %s: %s" rule ex)))
      (unless (eq (current-buffer) original-buffer)
        (error "‘genaction' of rule %s should not change buffers or have side effects"
               rule)))))

;; TODO(ejalfonso) fix nested pipeline clobbering remaining rules
;; TODO(ejalfonso) support supressing intermediate pipeline step notifications

(defun autobuild-pipeline-run (rules-remaining)
  "Run the RULES-REMAINING of an autobuild pipeline.  See ‘autobuild-pipeline'."
  (autobuild-mode-assert-enabled)
  (when rules-remaining
    (cl-destructuring-bind (buffer rule-or-action) (car rules-remaining)
      (unless rule-or-action
        ;; TODO use dynamic var to get name of pipeline
        (error "Null rule in pipeline"))
      (unless buffer (setq buffer (current-buffer)))
      (with-current-buffer buffer
        (let* ((rule (when (autobuild-rule-p rule-or-action)
                         rule-or-action))
                (action (if rule
                           (autobuild-rule-generate-action rule-or-action)
                         rule-or-action)))
          (unless action
            (error "Rule %s in pipeline should have generated an action" rule-or-action))
          (let ((result (autobuild-run-invocation
                         (make-autobuild--invocation :rule rule
                                                     :action action
                                                     :nice nil))))
            (if (and (bufferp result)
                     (eq 'compilation-mode (buffer-local-value 'major-mode result)))
                (with-current-buffer result
                  (setq-local autobuild-pipeline-rules-remaining (cdr rules-remaining))
                  (message "scheduling remaining rules: %s" autobuild-pipeline-rules-remaining))
              ;; TODO fail early on non-zero exit, error
              ;; or ensure each action errs
              (setq-local autobuild-pipeline-rules-remaining (cdr rules-remaining))
              (autobuild-pipeline-run (cdr rules-remaining)))))))))

(defun autobuild-compilation-succeeded-p (compilation-finished-message)
  "Determine from COMPILATION-FINISHED-MESSAGE whether compilation failed."
  (equal "finished\n" compilation-finished-message))

(defun autobuild-pipeline-continue (compilation-buffer finish-state)
  "Internal.  Used to resume an asynchronous pipeline.

   COMPILATION-BUFFER FINISH-STATE are the arguments passed
   to functions in ‘compilation-finish-functions'."
  (with-current-buffer compilation-buffer
    (when (bound-and-true-p autobuild-pipeline-rules-remaining)
      (if (not (autobuild-compilation-succeeded-p finish-state))
          (progn
            (message "aborting pipeline: %s" autobuild-pipeline-rules-remaining)
            (setq-local autobuild-pipeline-rules-remaining nil))
        (message "resuming pipeline: %s" autobuild-pipeline-rules-remaining)
        (autobuild-pipeline-run autobuild-pipeline-rules-remaining)))))

(defun autobuild-mode-filter-applicable-p (mode-filter)
  "Determine whether mode-filter MODE-FILTER is currently applicable."
  (or (null mode-filter)
      (cl-find major-mode mode-filter)
      (cl-loop for mode in mode-filter
               thereis (and (boundp mode)
                            (symbol-value mode)))))

(defun autobuild-applicable-rule-actions ()
  "Return a list of the currently applicable build actions.

   A rule RULE is applicable if the current major mode is contained in the
   rule's list of major modes, and if the rule generates a non-nil action."
  (cl-loop with actions
           for rule in autobuild-rules-list
           do (autobuild-nice autobuild-nice-default)
           do (if-let* ((action (autobuild-rule-generate-action rule)))
                  (push (make-autobuild--invocation :rule rule
                                                    :action action
                                                    :nice autobuild-nice)
                        actions))
           finally
           (return (autobuild--sort-by
                    #'autobuild--invocation-nice
                    ;; prioritize rules defined first if they have the same nice
                    (reverse actions)))))

(defun autobuild--sort-by (key list)
  "Sort LIST by the key-function KEY."
  (sort list (lambda (a b) (< (funcall key a) (funcall key b)))))

;;;###autoload
(defun autobuild-build (&optional prompt)
  "Build the current buffer.

   If PROMPT is non-nil or if there is no known last rule for
    the current buffer,
   prompt for selection of one of the currently-applicable build rules.
   Otherwise, chose the last-executed build rule, if known,
   or the rule with the lowest NICE property (highest priority)."
  (interactive "P")
  (autobuild-mode-assert-enabled)
  (let* ((cands
          (if-let* ((not-force-prompt (not prompt))
                    (--last-rule-valid-p autobuild-last-local-invocation))
              (progn
                (cl-assert (and
                            (autobuild-rule-p
                             (autobuild--invocation-rule
                              autobuild-last-local-invocation))
                            (autobuild--invocation-action
                             autobuild-last-local-invocation)))
                ;; the last action is still applicable, and prompt was not forced
                (list autobuild-last-local-invocation))
            ;; fall back to generating actions for all applicable rules
            (autobuild-applicable-rule-actions)))
         (choice (cond ((null cands) (error "No build rules matched"))
                       ((not prompt) (car cands))
                       (t (autobuild-candidate-select
                           cands "select build rule: "
                           #'autobuild--invocation-to-string)))))
    (cl-assert choice)
    (let* ((rule (autobuild--invocation-rule choice)))
      (when autobuild-debug (message "selected rule %s" rule))
      (setq-local autobuild-last-local-invocation choice)
      (autobuild-run-invocation choice))))


(defun autobuild--invocation-to-string (invocation)
  "Generate a string representation of an autobuild ACTION."
  (format "%s (%s)"
          (autobuild--invocation-rule invocation)
          (autobuild--invocation-nice invocation)))

(defun autobuild-run-invocation (invocation)
  "Run the given INVOCATION."
  (let* ((action (autobuild--invocation-action invocation))
         (entry (cons (current-buffer) invocation)))
    (setq autobuild-history (delete entry autobuild-history))
    (push entry autobuild-history)
    (autobuild--run-action action)))

(defun autobuild--run-action (action)
  "Execute a rule-generated ACTION as specified in ‘autobuild-define-rule'."

  (cl-assert action)
  (cond
   ((stringp action) (autobuild-run-string-command action))
   ((commandp action) (call-interactively action))
   ((functionp action) (funcall action))
   (t (error "Action must be string or function, not %s" action))))

(defun autobuild-rebuild-last-local ()
  "Rebuilt the last rule invoked in the current buffer."
  (interactive)
  (autobuild--rebuild :last-local))

(defun autobuild-rebuild-recent ()
  "Select a recently built rule to rebuild."
  (interactive)
  (autobuild--rebuild :prompt))

(defun autobuild-rebuild-last-global ()
  "Rebuilt the last rule invoked globally."
  (interactive)
  (autobuild--rebuild :last-global))

(defun autobuild--rebuild (recent-selection)
  "Rebuild a rule.  RECENT-SELECTION is in '(:last-local :last-global :prompt)."
  (setq autobuild-history
        (cl-remove-if-not (lambda (buffer-invocation)
                            (buffer-live-p (car buffer-invocation)))
                          autobuild-history))
  (let ((buffer-invocation
         (cl-case recent-selection
           (:last-local
            (if autobuild-last-local-invocation
                (cons (current-buffer)
                      autobuild-last-local-invocation)
              (error "No autobuild invocation found in the current buffer")))
           (:last-global
            (or
             (car autobuild-history)
             (error "No autobuild global invocation found")))
           (:prompt
            (selcand-select
             autobuild-history
             "Select recent build: "
             (lambda (buffer-invocation)
               (cl-destructuring-bind (buffer . invocation) buffer-invocation
                 (condition-case ()
                     (format "%s: %s"
                             (or (buffer-name buffer) buffer)
                             (autobuild--invocation-to-string invocation))
                   (error (format "2 : %s" buffer-invocation)))
)))))))
    (cl-assert buffer-invocation)
    (cl-destructuring-bind (buffer . invocation) buffer-invocation
      (cl-assert (buffer-live-p buffer))
      (cl-assert (autobuild--invocation-action invocation))
      (with-current-buffer buffer
        (autobuild-run-invocation invocation)))))

(defun autobuild-run-string-command (cmd)
  "Execute CMD as an asynchronous command via ‘compile'."
  (let ((emacs-filename-env-directive
         ;; allow file-local compile commands to use rename-proof filename
         (concat "AUTOBUILD_FILENAME=" (buffer-file-name (current-buffer)))))
    (push emacs-filename-env-directive process-environment)
    (compile cmd)))

(defun autobuild-compilation-buffer-setup (orig command &rest args)
  "‘compilation-start' around advice to add information needed by autobuild.

   ORIG, COMMAND, ARGS should be ‘compilation-start' and its arguments."
  (let* ((original-buffer (current-buffer))
         (compilation-buffer (apply orig command args)))
    (when original-buffer
      (with-current-buffer original-buffer
        (setq-local autobuild-last-compilation-buffer compilation-buffer)))
    (with-current-buffer compilation-buffer
      ;; TODO check if this is already available in compile
      (setq-local autobuild-compilation-start-time (time-to-seconds))
      (setq-local compile-command command))
    compilation-buffer))

(defcustom autobuild-notify-threshold-secs 10
  "Min seconds elapsed since compilation start before a notification is issued.

  If nil, disable notifications.
  If t, always issue notifications."
  :type 'number
  :group 'autobuild)

(defcustom autobuild-notification-function
  #'autobuild-notification-default-function
  "Function used to issue compilation notifications.

   It is called with the same arguments as those in ‘compilation-finish-functions'"
  :type 'function
  :group 'autobuild)

(defun autobuild-notification-default-function (_ compilation-state)
  "Default, simple autobuild notification function.

   This may be redefined with a more fancy notification mechanism,
   e.g. notify-send desktop notifications, audible beep, etc.

   COMPILATION-STATE is as described in ‘compilation-finish-functions'"
  (message "compilation %s: %s"
           (replace-regexp-in-string "\n" " " compilation-state)
           ;; TODO this is a global. this may fail if
           ;; compilation-command is not updated, e.g. build-cleaner
           compile-command))

(defun autobuild-notify (compilation-buffer compilation-state)
  "Hook function called to possibly issue compilation state notifications.

   COMPILATION-BUFFER, COMPILATION-STATE are as described in ‘compilation-finish-functions'"
  (condition-case ex
      (when compilation-state
        (with-current-buffer compilation-buffer
          (when (and
                 ;; this fails when emacs is not raised and therefore not visible...
                 ;; (not (frame-visible-p (selected-frame)))
                 autobuild-notify-threshold-secs
                 (or (eq autobuild-notify-threshold-secs t)
                     (>= (- (time-to-seconds)
                            autobuild-compilation-start-time)
                         autobuild-notify-threshold-secs)))
            (funcall autobuild-notification-function
                     compilation-buffer compilation-state))))
    (error
     ;; avoid interrupting compilation-finish-functions due to
     ;; errors in potentially user-provided ‘autobuild-notification-function'
     (message "Error in autobuild-notify: %s" ex))))


;;;###autoload
(define-minor-mode autobuild-mode
  "Define and execute build rules and compilation pipelines."
  :global t
  ;; add or remove hooks and advice used by autobuild
  (if autobuild-mode
      (progn
        (add-hook 'compilation-finish-functions #'autobuild-pipeline-continue)
        (add-hook 'compilation-finish-functions #'autobuild-notify)
        (advice-add #'compilation-start :around #'autobuild-compilation-buffer-setup))
    (remove-hook 'compilation-finish-functions #'autobuild-pipeline-continue)
    (remove-hook 'compilation-finish-functions #'autobuild-notify)
    (advice-remove #'compilation-start #'autobuild-compilation-buffer-setup)))

(defun autobuild-mode-assert-enabled ()
  "Signal an error if ‘autobuild-mode’ is not enabled."
  (unless autobuild-mode
    (error "`autobuild-mode' is not enabled")))

(defun autobuild-delete-rule (rule)
  "Delete the RULE from the autobuild rules registry."
  (interactive
   (list (autobuild-candidate-select autobuild-rules-list
                                     "select rule to delete: ")))
  (cl-assert (autobuild-rule-p rule))
  (setq autobuild-rules-list (delq rule autobuild-rules-list)))

;; TODO support autobuild-next-buffer and defining one-off pipelines interactively

(defun autobuild-debug-toggle ()
  "Toggle logging rule names before generating their action."
  (interactive)
  (setq autobuild-debug (not autobuild-debug))
  (message "autobuild rule debugging %s"
           (if autobuild-debug "enabled" "disabled")))

(defun autobuild-candidate-hints (candidates &optional chars)
  "Return an alist (HINT . CAND) for each candidate in CANDIDATES.

  Each hint consists of characters in the string CHARS."
  (setf chars (or chars autobuild-candidate-default-hints))
  (cl-assert candidates)
  (cl-loop
   with hint-width = (ceiling (log (length candidates) (length chars)))
   with hints = '("")
   for wi below hint-width do
   (setf hints
         (cl-loop for c across chars
                  append (mapcar (apply-partially
                                  #'concat (char-to-string c))
                                 hints)))
   finally (return (cl-loop for hint in hints
                            for cand in candidates
                            collect (cons hint cand)))))

(defun autobuild-candidate-select (candidates &optional prompt stringify-fn
                                              autoselect-if-single)
  "Use PROMPT to prompt for a selection from CANDIDATES.

  STRINGIFY-FN, if provided, is used to serialize candidates to a
  human-readable string to use during prompting.
  STRINGIFY-FN is required when candidates are not of type string.

  AUTOSELECT-IF-SINGLE, if non-nil, indicates to bypass prompting if
  the length of candidates is one."
  (let* ((hints-cands (autobuild-candidate-hints candidates))
         (sep ") ")
         (stringify-fn (or stringify-fn #'prin1-to-string))
         (choices (cl-loop for (hint . cand) in hints-cands
                           collect (concat hint sep (funcall stringify-fn cand))))
         (prompt (or prompt "select candidate: "))
         (choice (if (and autoselect-if-single (null (cdr choices)))
                     (car choices)
                   (minibuffer-with-setup-hook #'minibuffer-completion-help
                     (completing-read prompt choices
                                      nil
                                      t))))
         (cand (let* ((hint (car (split-string choice sep))))
                 (cdr (assoc hint hints-cands #'equal)))))
    cand))

(autobuild-define-rule autobuild-emacs-lisp-eval-buffer (emacs-lisp-mode)
  "Evaluate the current emacs-lisp buffer"
  (autobuild-nice 9)
  #'eval-buffer)

(provide 'autobuild)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; autobuild.el ends here
