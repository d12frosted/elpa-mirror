;;; undercover.el --- Test coverage library for Emacs Lisp -*- lexical-binding: t -*-

;; Copyright (c) 2014 Sviridov Alexander
;; Copyright (c) 2019, 2021 Vladimir Panteleev

;; Author: Sviridov Alexander <sviridov.vmi@gmail.com>
;; URL: https://github.com/sviridov/undercover.el
;; Package-Version: 20210602.2119
;; Package-Commit: 1d3587f1fad66a747688f36636b67b33b73447d3
;; Created: Sat Sep 27 2014
;; Keywords: lisp, tests, coverage, tools
;; Version: 0.8.0
;; Package-Requires: ((emacs "24") (dash "2.0.0") (shut-up "0.3.2"))

;;; Commentary:

;; Provides test coverage tools for Emacs packages.

;;; Code:

(require 'edebug)
(require 'json)
(require 'dash)
(require 'shut-up)

(defconst undercover-version "0.8.0")


;; ----------------------------------------------------------------------------
;; Global variables

(defvar undercover-force-coverage nil
  "If non-nil, always collect test coverage.

If nil, test coverage will be collected only when running under a
continuous integration service.

Can also be set through the environment, by defining UNDERCOVER_FORCE.")
(setq undercover-force-coverage (getenv "UNDERCOVER_FORCE"))

(defvar undercover--report-format nil
  "Indicates the format of the report file and coverage service to submit to.

If nil, auto-detect from the environment.

Configured using the :report-format configuration option.")

(defvar undercover--report-on-kill t
  "If non-nil, queue generating a report before Emacs exits.

Configured using the :report-on-kill configuration option.")

(defvar undercover--send-report t
  "If non-nil, upload coverage reports to the configured coverage service.

Configured using the :send-report configuration option.")

(defvar undercover--merge-report t
  "If non-nil, try to merge coverage information into existing report files.

Configured using the :merge-report configuration option.")

;; Currently used levels:
;; 1 - non-fatal errors
;; 2 - warnings
;; 4 - potentially useful output which differs across Undercover runs
;; 5 - default
;; 6 - verbose messages which in some situations may point towards a problem
;; 7 - verbose informational messages
(defvar undercover--verbosity 5
  "Controls the amount of messages produced.

Configured using the :verbosity configuration option.")

(defvar undercover--report-file-path nil
  "The path of the file where the coverage report will be written to.

Configured using the :report-file configuration option.")

(defvar undercover--files nil
  "List of files for test coverage check.")

(defvar undercover--files-coverage-statistics (make-hash-table :test 'equal)
  "Table of coverage statistics for each file in `undercover--files'.")

(defvar undercover--old-edebug-make-form-wrapper
  (symbol-function 'edebug-make-form-wrapper))

(defvar undercover--env nil
  "Cached return value of `undercover--build-env'.")


;; ----------------------------------------------------------------------------
;; Utilities

(defun undercover--fill-hash-table (hash-table &rest keys-and-values)
  "Fill HASH-TABLE from KEYS-AND-VALUES."
  (declare (indent 1))
  (cl-loop for (key value) on keys-and-values by #'cddr
           do (puthash key value hash-table))
  hash-table)

;; TODO: make this a macro, so that the values in keys-and-values are lazily
;; evaluated.
(defun undercover--add-to-hash-table (hash-table &rest keys-and-values)
  "Fill HASH-TABLE from KEYS-AND-VALUES, but omit nil VALUES, and
don't overwrite existing KEYS."
  (declare (indent 1))
  (cl-loop for (key value) on keys-and-values by #'cddr
           do (when (and value
                         (not (gethash key hash-table)))
                (puthash key value hash-table)))
  hash-table)

(defun undercover--make-hash-table (&rest keys-and-values)
  "Create new hash-table and fill it from KEYS-AND-VALUES."
  (apply #'undercover--fill-hash-table (make-hash-table :test 'equal) keys-and-values))

(defun undercover--wildcards-to-files (wildcards)
  "Search for and return the list of files matched by WILDCARDS.

Example of WILDCARDS: (\"*.el\" \"subdir/*.el\" (:exclude \"exclude-*.el\"))."
  (let (files)
    (dolist (wildcard wildcards)
      (setq files
            (cond
             ((stringp wildcard)
              (-union files (file-expand-wildcards wildcard)))
             ((and (consp wildcard) (eq :exclude (car wildcard)))
              (-difference files (-mapcat #'file-expand-wildcards (cdr wildcard))))
             ((and (consp wildcard) (eq :files (car wildcard)))
              (-union files (cdr wildcard)))
             (t
              (error "UNDERCOVER: Unrecognized wildcard pattern: %S" wildcard)))))
    files))

(defun undercover--getenv-nonempty (name)
  "Return the value of the environment variable NAME if it exists and is non-empty.

Otherwise, return nil."
  (let ((value (getenv name)))
    (when (not (zerop (length value)))
      value)))

(defun undercover--message (level format-string &rest args)
  "Log a message at the given LEVEL.  FORMAT-STRING and ARGS are as in `message'."
  (declare (indent 1))
  (when (<= level undercover--verbosity)
    (apply #'message (concat "UNDERCOVER: " format-string) args)))


;; ----------------------------------------------------------------------------
;; `edebug' related functions and hacks:

;; http://debbugs.gnu.org/cgi/bugreport.cgi?bug=6415
(def-edebug-spec cl-destructuring-bind (sexp form body))
(def-edebug-spec destructuring-bind (sexp form body))

(def-edebug-spec cl-symbol-macrolet ((&rest (symbolp sexp)) cl-declarations body))
(def-edebug-spec symbol-macrolet ((&rest (symbolp sexp)) cl-declarations body))

(def-edebug-spec cl-type-spec sexp)

(def-edebug-spec when-let ([&or (symbolp form) (&rest (symbolp form))] body))

;; https://github.com/emacs-mirror/emacs/commit/62cf8f1649468fc2f6c4f8926ab5c4bb184bfbe8
(def-edebug-spec gv-define-setter (&define name :name gv-setter sexp def-body))

(defun undercover--fallback-file-handler (operation args)
  "Handle any file OPERATION with ARGS."
  (let ((inhibit-file-name-handlers
         (cons 'undercover-file-handler
               (and (eq inhibit-file-name-operation operation)
                    inhibit-file-name-handlers)))
        (inhibit-file-name-operation operation))
    (apply operation args)))

(defun undercover--load-file-handler (file)
  "Handle the `load' FILE operation."
  (undercover--message 7 "Instrumenting %s for collecting coverage information." file)
  (let ((edebug-all-defs (undercover-enabled-p))
        (load-file-name (file-truename file))
        (load-in-progress t))
    (unwind-protect
        (progn
          (save-excursion (eval-buffer (find-file load-file-name)))
          (push load-file-name undercover--files))
      (switch-to-buffer (current-buffer)))))

(defun undercover--show-load-file-error (filename load-error)
  (undercover--message 1 "Error while loading %s for coverage:" filename)
  (undercover--message 1 "%s" (error-message-string load-error))
  (undercover--message 1 "The problem may be due to edebug failing to parse the file.")
  (undercover--message 1 "You can try to narrow down the problem using the following steps:")
  (undercover--message 1 "1. Open %S in an Emacs buffer;" filename)
  (undercover--message 1 "2. Run M-: `%s';" "(require 'edebug)")
  (undercover--message 1 "3. Run M-x `edebug-all-defs';")
  (undercover--message 1 "4. Run M-x `toggle-debug-on-error'.")
  (undercover--message 1 "5. Run M-x `eval-buffer';")
  (undercover--message 1 "6. In the *Backtrace* buffer, find a numeric position,")
  (undercover--message 1 "   then M-x `goto-char' to it."))

(defun undercover-file-handler (operation &rest args)
  "Handle the `load' OPERATION.  Ignore all ARGS except first."
  (if (eq 'load operation)
      (condition-case load-error
          (undercover--load-file-handler (car args))
        (error
         (undercover--show-load-file-error (car args) load-error)
         (undercover--fallback-file-handler operation args)))
    (undercover--fallback-file-handler operation args)))

(defun undercover--edebug-files (files)
  "Use the `edebug' package to instrument all macros and functions in FILES."
  (undercover--message 6 "Preparing to instrument %d file%s."
                       (length files) (if (= (length files) 1) "" "s"))
  (when files
    (let ((regexp (->> (-map #'expand-file-name files) (regexp-opt) (format "^%s$"))))
      (add-to-list 'file-name-handler-alist (cons regexp 'undercover-file-handler)))))

(setf (symbol-function 'undercover--stop-point-before)
      (lambda (before-index)
        "Increase the number of times that the stop point at BEFORE-INDEX was covered."
        (when (boundp 'edebug-freq-count)
          (cl-incf (aref edebug-freq-count before-index)))
        before-index))

(setf (symbol-function 'undercover--stop-point-after)
      (cons 'macro
            (lambda (before-index after-index form)
              "Increase the number of times that the stop point at AFTER-INDEX was covered."
              `(let ((before-index ,before-index)
                     (after-index ,after-index))
                 (unwind-protect ,form
                   (when (boundp 'edebug-freq-count)
                     (aset edebug-freq-count after-index (+ 1 (aref edebug-freq-count after-index)))
                     (undercover--align-counts-between-stop-points before-index after-index)))))))

(setf (symbol-function 'undercover--align-counts-between-stop-points)
      (lambda (before-index after-index)
        "Decrease the number of times that the stop points between BEFORE-INDEX and AFTER-INDEX are covered."
        (when (boundp 'edebug-freq-count)
          (cl-do ((index (1+ before-index) (1+ index)))
              ((>= index after-index))
            (setf (aref edebug-freq-count index)
                  (min (aref edebug-freq-count index)
                       (aref edebug-freq-count before-index)))))))

(defun undercover--stop-points (name)
  "Return stop points for NAME, ordered by position."
  (append (nth 2 (get name 'edebug)) nil))

(defun undercover--stop-points-covers (name)
  "Return number of covers for each stop point ordered by position for NAME."
  (append (get name 'edebug-freq-count) nil))

(defun undercover--shut-up-edebug-message ()
  "Muffle `edebug' message \"EDEBUG: function\"."
  ;; HACK: I don't use `defadvice' because of cryptic error with `shut-up-sink'.
  ;; https://travis-ci.org/sviridov/multiple-cursors.el/builds/37529750#L1387
  ;; https://travis-ci.org/sviridov/expand-region.el/builds/37576813#L285
  (setf (symbol-function 'edebug-make-form-wrapper)
        (lambda (&rest args)
          (shut-up (apply undercover--old-edebug-make-form-wrapper args)))))

(defun undercover--set-edebug-handlers ()
  "Replace and advise some `edebug' functions with `undercover' handlers."
  (if (boundp 'edebug-behavior-alist)
      ;; Emacs 27.
      (progn
        (push `(undercover ,(nth 0 (cdr (assq 'edebug edebug-behavior-alist))) undercover--stop-point-before undercover--stop-point-after)
              edebug-behavior-alist)
        (setf edebug-new-definition-function #'undercover--new-definition))
    ;; Earlier Emacs versions.
    (defalias 'edebug-before 'undercover--stop-point-before)
    (defalias 'edebug-after 'undercover--stop-point-after))
  (undercover--shut-up-edebug-message)
  ;; HACK: Ensures that debugger is turned off.
  ;; https://travis-ci.org/sviridov/multiple-cursors.el/builds/37672312#L350
  ;; https://travis-ci.org/sviridov/expand-region.el/builds/37577423#L336
  (setq debug-on-error  nil
        debug-on-signal nil
        edebug-on-error nil))

(defun undercover--new-definition (def-name)
  (put def-name 'edebug-behavior 'undercover))


;; ----------------------------------------------------------------------------
;; Coverage statistics related functions:

(defun undercover--symbol-coverage-statistics (edebug-symbol statistics)
  "Collect coverage statistics for EDEBUG-SYMBOL into the STATISTICS hash-table."
  (let* ((start-marker (car (get edebug-symbol 'edebug)))
         (points (undercover--stop-points edebug-symbol))
         (points-covers (undercover--stop-points-covers edebug-symbol))
         (points-and-covers (cl-map 'list #'cons points points-covers)))
    (dolist (point-and-cover points-and-covers)
      (let* ((point (car point-and-cover))
             (line  (line-number-at-pos (+ point start-marker)))
             (cover (cdr point-and-cover))
             (previous-score (gethash line statistics cover))
             (new-score (min previous-score cover)))
        (puthash line new-score statistics)))))

(defun undercover--file-coverage-statistics ()
  "Collect coverage statistics for current-file into a hash-table.

The returned hash-table's keys are line numbers, and the values
are the number of times that line was covered."
  (let ((statistics (make-hash-table)))
    (dolist (edebug-data edebug-form-data)
      (let ((edebug-symbol (car edebug-data)))
        (when (get edebug-symbol 'edebug)
          (undercover--symbol-coverage-statistics edebug-symbol statistics))))
    statistics))

(defun undercover--collect-file-coverage (file)
  "Collect coverage statistics for FILE."
  (save-excursion
    (find-file file)
    (if edebug-form-data
        (undercover--fill-hash-table undercover--files-coverage-statistics
          file (undercover--file-coverage-statistics))
      (setq undercover--files (delq file undercover--files)))))

(defun undercover--collect-files-coverage (files)
  "Collect coverage statistics for each file in FILES."
  (dolist (file files)
    (undercover--collect-file-coverage file)))


;; ----------------------------------------------------------------------------
;; Continuous Integration service support:

(defun undercover--detect-ci (env)
  "Detect and collect information from the CI service we are running under.

Fills the hash-table ENV with all the relevant information we
could acquire

Hash table keys are as follows:

- :ci-type

  An Undercover-specific symbol indicating the CI service.  Can
  be used to enable special behavior in coverage data consumers.

- :ci-name

  The human-readable name of the service.

- :commit

  Git commit SHA1 (of the tested repository) being tested.

  Some CI services may run the tests on a checkout of a commit
  different than the logical commit being tested, for example, if
  they first merge the tested commit into the target branch, to
  test the result of the merge.

- :ref

  Git ref being tested.

  For a branch, this should be the form 'refs/heads/<branch-name>'.

  For a tag, this should be the form 'refs/tags/<tag-name>'.

- :pull-request

  A number identifying the forge's pull request number being
  tested, if any.

- :build-id

  A string (usually a large number) uniquely identifying the
  current build.  This value is unique globally per the CI
  service, not just per repository.

  If the service supports multiple stages, this value is the same
  for all stages.

  If the service supports matrix builds, this value is the same
  for every matrix combination.

- :build-number

  A number identifying the current build.  Usually unique and
  monotonically increasing per-repository, however, some services
  allow manually resetting it to some value.  Can be useful to
  align CI service build numbers with coverage service report
  numbers.

- :job-id

  A string (usually a large number) uniquely identifying the
  current job.  This value is unique globally per the CI service,
  not just per repository or per build.

  If the service supports matrix builds, this value is different
  for every matrix combination.

  If the service does not support matrix builds, this value
  should not be set.

- :job-number

  A number identifying the current job.  Usually unique and
  monotonically increasing per-build.

  If the service does not support matrix builds, this value
  should not be set.

- :job-name

  A human-readable string describing the current job.
  User-specified, or may contain the values of the matrix
  variables for the current job.

These values may be overridden through the environment (see
`undercover--read-env')."
  (cond
   ;; GitHub Actions -- https://docs.github.com/en/actions/reference/environment-variables#default-environment-variables
   ((equal (getenv "GITHUB_ACTIONS") "true")
    (undercover--add-to-hash-table env
      :ci-type      'github-actions
      :ci-name      "GitHub Actions"
      :commit       (undercover--getenv-nonempty "GITHUB_SHA")
      :ref          (undercover--getenv-nonempty "GITHUB_REF")
      :build-id     (undercover--getenv-nonempty "GITHUB_RUN_ID")
      :build-number (undercover--getenv-nonempty "GITHUB_RUN_NUMBER")))

   ;; Travis CI -- https://docs.travis-ci.com/user/environment-variables/#default-environment-variables
   ((equal (getenv "TRAVIS") "true")
    (undercover--add-to-hash-table env
      :ci-type      'travis-ci
      :ci-name      "Travis CI"
      :commit       (or
                     (undercover--getenv-nonempty "TRAVIS_PULL_REQUEST_SHA")
                     (undercover--getenv-nonempty "TRAVIS_COMMIT"))
      :ref          (cond
                     ((undercover--getenv-nonempty "TRAVIS_TAG")
                      (concat "refs/tags/" (getenv "TRAVIS_TAG")))
                     ((undercover--getenv-nonempty "TRAVIS_BRANCH")
                      (concat "refs/heads/" (getenv "TRAVIS_BRANCH"))))
      :pull-request (-when-let (n (undercover--getenv-nonempty "TRAVIS_PULL_REQUEST"))
                      (unless (string-equal n "false")
                        n))
      :build-id     (undercover--getenv-nonempty "TRAVIS_BUILD_ID")
      :build-number (undercover--getenv-nonempty "TRAVIS_BUILD_NUMBER")
      :job-id       (undercover--getenv-nonempty "TRAVIS_JOB_ID")
      :job-number   (-when-let (n (undercover--getenv-nonempty "TRAVIS_JOB_NUMBER"))
                      (cadr (split-string n "\\.")))
      :job-name     (undercover--getenv-nonempty "TRAVIS_JOB_NAME")))

   ;; Shippable -- http://docs.shippable.com/ci/env-vars/#standard-variables
   ((getenv "SHIPPABLE")
    (undercover--add-to-hash-table env
      :ci-type      'shippable
      :ci-name      "Shippable"
      :pull-request (-when-let (n (undercover--getenv-nonempty "PULL_REQUEST"))
                      (unless (string-equal n "false")
                        n))
      :build-id     (undercover--getenv-nonempty "SHIPPABLE_BUILD_ID")
      :build-number (undercover--getenv-nonempty "SHIPPABLE_BUILD_NUMBER")
      :job-id       (undercover--getenv-nonempty "SHIPPABLE_JOB_ID")))

   ;; Drone -- https://docs.drone.io/pipeline/environment/reference/
   ((equal (getenv "DRONE") "true")
    (undercover--add-to-hash-table env
      :ci-type      'drone
      :ci-name      "Drone"
      :commit       (undercover--getenv-nonempty "DRONE_COMMIT")
      :ref          (undercover--getenv-nonempty "DRONE_COMMIT_REF")
      :pull-request (undercover--getenv-nonempty "DRONE_PULL_REQUEST")
      :build-number (undercover--getenv-nonempty "DRONE_BUILD_NUMBER")
      :job-name     (undercover--getenv-nonempty "DRONE_JOB_NAME")))

   ;; Jenkins -- https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#using-environment-variables
   ((or (getenv "JENKINS_URL") (getenv "JENKINS_HOME"))
    (undercover--add-to-hash-table env
      :ci-type      'jenkins
      :ci-name      "Jenkins"
      ;; From the Git plugin -- https://plugins.jenkins.io/git/#environment-variables
      :commit       (undercover--getenv-nonempty "GIT_COMMIT")
      :ref          (-when-let (b (undercover--getenv-nonempty "GIT_BRANCH"))
                      (concat "refs/heads/" b))
      ;; Set in multibranch pipelines -- https://www.jenkins.io/doc/book/pipeline/multibranch/#additional-environment-variables
      :pull-request (undercover--getenv-nonempty "CHANGE_ID")
      :build-number (undercover--getenv-nonempty "BUILD_NUMBER")))

   ;; Circle CI -- https://circleci.com/docs/2.0/env-vars/
   ((equal (getenv "CIRCLECI") "true")
    (undercover--add-to-hash-table env
      :ci-type      'circle-ci
      :ci-name      "Circle CI"
      :commit       (undercover--getenv-nonempty "CIRCLE_SHA1")
      :ref          (-when-let (b (undercover--getenv-nonempty "CIRCLE_BRANCH"))
                      (concat "refs/heads/" b))
      :pull-request (undercover--getenv-nonempty "CIRCLE_PR_NUMBER")
      :build-id     (undercover--getenv-nonempty "CIRCLE_BUILD_NUM")
      :job-number   (undercover--getenv-nonempty "CIRCLE_NODE_INDEX")
      :job-name     (undercover--getenv-nonempty "CIRCLE_CI_JOB_NAME")))

   ;; CloudBees CodeShip -- https://docs.cloudbees.com/docs/cloudbees-codeship/latest/pro-builds-and-configuration/environment-variables#_default_environment_variables
   ((equal (getenv "CI_NAME") "codeship")
    (undercover--add-to-hash-table env
      :ci-type      'codeship
      :ci-name      "CodeShip"
      :commit       (undercover--getenv-nonempty "CI_COMMIT_ID")
      :ref          (-when-let (b (undercover--getenv-nonempty "CI_BRANCH"))
                      (concat "refs/heads/" b))
      :pull-request (undercover--getenv-nonempty "CI_PR_NUMBER")
      :build-id     (undercover--getenv-nonempty "CI_BUILD_ID")))

   ;; Wercker -- https://devcenter.wercker.com/administration/environment-variables/available-env-vars/
   ((getenv "WERCKER")
    (undercover--add-to-hash-table env
      :ci-type      'wercker
      :ci-name      "Wercker"
      :commit       (undercover--getenv-nonempty "WERCKER_GIT_COMMIT")
      :ref          (-when-let (b (undercover--getenv-nonempty "WERCKER_GIT_BRANCH"))
                      (concat "refs/heads/" b))))

   ;; GitLab CI -- https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
   ((getenv "GITLAB_CI")
    (undercover--add-to-hash-table env
      :ci-type      'gitlab-ci
      :ci-name      "GitLab CI"
      :commit       (undercover--getenv-nonempty "CI_COMMIT_SHA")
      :ref          (cond
                     ((undercover--getenv-nonempty "CI_COMMIT_TAG")
                      (concat "refs/tags/" (getenv "CI_COMMIT_TAG")))
                     ((undercover--getenv-nonempty "CI_COMMIT_BRANCH")
                      (concat "refs/heads/" (getenv "CI_COMMIT_BRANCH"))))
      :pull-request (undercover--getenv-nonempty "CI_MERGE_REQUEST_IID")
      :build-id     (undercover--getenv-nonempty "CI_JOB_ID")
      :job-number   (undercover--getenv-nonempty "CI_NODE_INDEX")))

   ;; AppVeyor -- https://www.appveyor.com/docs/environment-variables/
   ((getenv "APPVEYOR")
    (undercover--add-to-hash-table env
      :ci-type      'appveyor
      :ci-name      "AppVeyor"
      :commit       (undercover--getenv-nonempty "APPVEYOR_REPO_COMMIT")
      :ref          (cond
                     ((undercover--getenv-nonempty "APPVEYOR_REPO_TAG_NAME")
                      (concat "refs/tags/" (getenv "APPVEYOR_REPO_TAG_NAME")))
                     ((undercover--getenv-nonempty "APPVEYOR_PULL_REQUEST_NUMBER")
                      nil)
                     ((undercover--getenv-nonempty "APPVEYOR_REPO_BRANCH")
                      (concat "refs/heads/" (getenv "APPVEYOR_REPO_BRANCH"))))
      :pull-request (undercover--getenv-nonempty "APPVEYOR_PULL_REQUEST_NUMBER")
      :build-id     (undercover--getenv-nonempty "APPVEYOR_BUILD_ID")
      :build-number (undercover--getenv-nonempty "APPVEYOR_BUILD_NUMBER")
      :job-id       (undercover--getenv-nonempty "APPVEYOR_JOB_ID")
      :job-number   (undercover--getenv-nonempty "APPVEYOR_JOB_NUMBER")
      :job-name     (undercover--getenv-nonempty "APPVEYOR_JOB_NAME")))

   ;; Surf -- https://github.com/surf-build/surf#surf-build
   ((getenv "SURF_SHA1")
    (undercover--add-to-hash-table env
      :ci-type      'surf
      :ci-name      "Surf"
      :commit       (undercover--getenv-nonempty "SURF_SHA1")
      :ref          (undercover--getenv-nonempty "SURF_REF")
      :pull-request (undercover--getenv-nonempty "SURF_PR_NUM")))

   ;; BuildKite -- https://buildkite.com/docs/pipelines/environment-variables
   ((equal (getenv "BUILDKITE") "true")
    (undercover--add-to-hash-table env
      :ci-type      'buildkite
      :ci-name      "BuildKite"
      :commit       (-when-let (c (undercover--getenv-nonempty "BUILDKITE_COMMIT"))
                      (when (string-match-p "^[0-9a-f]\\{40\\}$" c)
                        c))
      :ref          (cond
                     ((undercover--getenv-nonempty "BUILDKITE_BRANCH")
                      (concat "refs/tags/" (getenv "BUILDKITE_BRANCH")))
                     ((undercover--getenv-nonempty "BUILDKITE_TAG")
                      (concat "refs/heads/" (getenv "BUILDKITE_TAG"))))
      :pull-request (undercover--getenv-nonempty "BUILDKITE_PULL_REQUEST")
      :build-id     (undercover--getenv-nonempty "BUILDKITE_BUILD_ID")
      :build-number (undercover--getenv-nonempty "BUILDKITE_BUILD_NUMBER")
      :job-id       (undercover--getenv-nonempty "BUILDKITE_JOB_ID")
      :job-name     (undercover--getenv-nonempty "BUILDKITE_LABEL")))

   ;; Semaphore CI -- https://docs.semaphoreci.com/ci-cd-environment/environment-variables/
   ((equal (getenv "SEMAPHORE") "true")
    (undercover--add-to-hash-table env
      :ci-type      'semaphore
      :ci-name      "Semaphore"
      :commit       (undercover--getenv-nonempty "SEMAPHORE_GIT_SHA")
      :ref          (undercover--getenv-nonempty "SEMAPHORE_GIT_REF")
      :pull-request (undercover--getenv-nonempty "SEMAPHORE_GIT_PR_NUMBER")
      :build-id     (undercover--getenv-nonempty "SEMAPHORE_JOB_ID")))

   ;; Codefresh -- https://codefresh.io/docs/docs/codefresh-yaml/variables/#system-provided-variables
   ((getenv "CF_REVISION")
    (undercover--add-to-hash-table env
      :ci-type      'codefresh
      :ci-name      "Codefresh"
      :commit       (undercover--getenv-nonempty "CF_REVISION")
      :ref          (-when-let (b (undercover--getenv-nonempty "CF_BRANCH"))
                      (concat "refs/tags/" b)) ; No way to distinguish branch/tag??
      :pull-request (undercover--getenv-nonempty "CF_PULL_REQUEST_NUMBER")
      :build-id     (undercover--getenv-nonempty "CF_BUILD_ID")))

   ;; Template for new services:
   ;; ;; Service -- https://www.service.com/docs/environment-variables/
   ;; ((getenv "SERVICE")
   ;;  (undercover--add-to-hash-table env
   ;;   :ci-type      'service
   ;;   :ci-name      "Service"
   ;;   :commit       (undercover--getenv-nonempty "SERVICE_SHA") ;TODO
   ;;   :ref          (undercover--getenv-nonempty "SERVICE_REF") ;TODO
   ;;   :pull-request (undercover--getenv-nonempty "SERVICE_PULL_REQUEST") ;TODO
   ;;   :build-id     (undercover--getenv-nonempty "SERVICE_BUILD_ID") ;TODO
   ;;   :build-number (undercover--getenv-nonempty "SERVICE_BUILD_NUMBER") ;TODO
   ;;   :job-id       (undercover--getenv-nonempty "SERVICE_JOB_ID") ;TODO
   ;;   :job-number   (undercover--getenv-nonempty "SERVICE_JOB_NUMBER") ;TODO
   ;;   :job-name     (undercover--getenv-nonempty "SERVICE_JOB_NAME"))) ;TODO
   ))

(defun undercover--read-env (env)
  "Read environment settings, allowing them to override auto-detected ones."
  (undercover--add-to-hash-table env
    :ci-type      (-when-let (v (getenv "UNDERCOVER_CI_TYPE"))
                    (intern v))
    :ci-name      (getenv "UNDERCOVER_CI_NAME")
    :commit       (getenv "UNDERCOVER_COMMIT")
    :ref          (getenv "UNDERCOVER_REF")
    :pull-request (getenv "UNDERCOVER_PULL_REQUEST")
    :build-id     (getenv "UNDERCOVER_BUILD_ID")
    :build-number (getenv "UNDERCOVER_BUILD_NUMBER")
    :job-id       (getenv "UNDERCOVER_JOB_ID")
    :job-number   (getenv "UNDERCOVER_JOB_NUMBER")
    :job-name     (getenv "UNDERCOVER_JOB_NAME")))

(defun undercover--build-env ()
  "Calculate and return a hash table representing Undercover's environment."
  (let ((env (make-hash-table :test 'eq)))
    (undercover--detect-ci env)
    (undercover--message 7 "Detected CI: %s"
                         (or (gethash :ci-name env) "None"))
    (undercover--read-env env)
    env))

(defun undercover--need-env ()
  "Ensure `undercover--env' is populated with the result of `undercover--build-env'."
  (setq undercover--env (or undercover--env (undercover--build-env))))


(defun undercover--under-ci-p ()
  "Check if Undercover is running under some continuous integration service."
  (or
   (gethash :ci-type (undercover--need-env))
   (equal (getenv "CI") "true")))


;; ----------------------------------------------------------------------------
;; Git queries:

(defun undercover--get-git-info (&rest args)
  "Execute Git with ARGS, returning the first line of its output."
  (with-temp-buffer
    (when (zerop (apply #'process-file "git" nil t nil "--no-pager" args))
      (goto-char (point-min))
      (buffer-substring-no-properties
       (line-beginning-position)
       (line-end-position)))))

(defun undercover--get-git-info-from-log (format ref)
  "Get first line of Git log in given FORMAT."
  (undercover--get-git-info "log" "-1" (format "--pretty=format:%%%s" format) ref))

(defun undercover--update-with-git (env)
  "Update ENV with Git information."
  (let ((ref (or (gethash :commit env)
                 "HEAD")))
    (undercover--add-to-hash-table env
      :ref             (undercover--get-git-info "symbolic-ref" ref)
      :commit          (undercover--get-git-info-from-log "H"  ref)
      :author-name     (undercover--get-git-info-from-log "aN" ref)
      :author-email    (undercover--get-git-info-from-log "ae" ref)
      :committer-name  (undercover--get-git-info-from-log "cN" ref)
      :committer-email (undercover--get-git-info-from-log "ce" ref)
      :subject         (undercover--get-git-info-from-log "s"  ref))))


;; ----------------------------------------------------------------------------
;; Coverage format / service support:

;; coveralls.io report:

(defun undercover-coveralls--configured-p ()
  "Check if we can submit a report to Coveralls with what we have/know."
  (cl-case (gethash :ci-type (undercover--need-env))
    ;; No / unknown CI
    ((nil) nil)
    ;; Travis CI - supported "magically" by Coveralls
    (travis-ci
     t)
    ;; GitHub Actions - need either a Coveralls repo token or a GitHub access token
    (github-actions
     (or
      (getenv "COVERALLS_REPO_TOKEN")
      (getenv "GITHUB_TOKEN")))
    ;; Something else - need a Coveralls repo token
    (t
     (getenv "COVERALLS_REPO_TOKEN"))))

(defun undercover-coveralls--get-git-remotes ()
  "Return list of Git remotes."
  (with-temp-buffer
    (process-file "git" nil t nil "--no-pager" "remote")
    (let ((remotes (split-string (buffer-string) "\n" t))
          (config-path-format (format "remote.%%s.url"))
          (remotes-info nil))
      (dolist (remote remotes remotes-info)
        (let* ((remote-url (undercover--get-git-info "config" (format config-path-format remote)))
               (remote-table (undercover--make-hash-table
                              "name" remote
                              "url"  remote-url)))
          (push remote-table remotes-info))))))


(defun undercover-coveralls--update-report-with-env (report env)
  "Update test coverage REPORT for coveralls.io with information from ENV."
  (undercover--add-to-hash-table report
    "service_name"         (or
                            (getenv "COVERALLS_SERVICE_NAME")
                            (cl-case (gethash :ci-type env)
                              ((nil)
                               (unless undercover-force-coverage
                                 (error "UNDERCOVER: Failed to detect the CI service")))
                              (github-actions
                               ;; When service_name is set to "github", Coveralls
                               ;; expects "repo_token" to contain the GitHub access
                               ;; token instead of the Coveralls repo token.
                               (cond
                                ((getenv "COVERALLS_REPO_TOKEN")
                                 "undercover-github-actions")
                                ((getenv "GITHUB_TOKEN")
                                 "github")))
                              (travis-ci
                               "travis-ci")
                              (shippable
                               "shippable")      ; presumably
                              (drone
                               "drone")
                              (jenkins
                               "jenkins")
                              (circle-ci
                               "circleci")
                              (codeship
                               "codeship")
                              (wercker
                               "wercker")
                              (gitlab-ci
                               "gitlab-ci")
                              (appveyor
                               "appveyor")
                              (surf
                               "surf")
                              (buildkite
                               "buildkite")
                              (semaphore
                               "semaphore")
                              (codefresh
                               "Codefresh"))
                            (unless undercover-force-coverage
                              (error "UNDERCOVER: Failed to detect Coveralls service_name")))

    "repo_token"           (cond
                            ((and (eq (gethash :ci-type env) 'github-actions)
                                  (getenv "GITHUB_TOKEN"))
                             (getenv "GITHUB_TOKEN"))
                            (t
                             (getenv "COVERALLS_REPO_TOKEN")))

    "service_number"       (or
                            (getenv "COVERALLS_SERVICE_NUMBER")
                            (gethash :build-number env)
                            (gethash :build-id env))

    "service_job_id"       (or
                            (getenv "COVERALLS_SERVICE_JOB_ID")
                            (gethash :job-id env))

    "service_pull_request" (or
                            (getenv "COVERALLS_SERVICE_PULL_REQUEST") ; Not official
                            (gethash :pull-request env))

    "parallel"             (if (getenv "COVERALLS_PARALLEL")
                               t
                             json-false)

    "flag_name"            (or
                            (getenv "COVERALLS_FLAG_NAME")
                            (gethash :job-name env))

    "run_at"               (getenv "COVERALLS_RUN_AT")

    "git" (undercover--add-to-hash-table (undercover--make-hash-table)
            "branch"  (gethash :ref env)
            "remotes" (undercover-coveralls--get-git-remotes)
            "head"    (undercover--make-hash-table
                       "id"              (gethash :commit env)
                       "author_name"     (gethash :author-name env)
                       "author_email"    (gethash :author-email env)
                       "committer_name"  (gethash :committer-name env)
                       "committer_email" (gethash :committer-email env)
                       "message"         (gethash :subject env)))))

(defun undercover-coveralls--file-coverage-report (statistics)
  "Translate file coverage STATISTICS into coveralls.io format."
  (let (file-coverage)
    (dotimes (line (count-lines (point-min) (point-max)))
      (push (gethash (1+ line) statistics) file-coverage))
    (nreverse file-coverage)))

(defun undercover-coveralls--file-report (file)
  "Create part of coveralls.io report for FILE."
  (save-excursion
    (find-file file)
    (let ((file-name (file-relative-name file (locate-dominating-file default-directory ".git")))
          (file-content (buffer-substring-no-properties (point-min) (point-max)))
          (coverage-report (undercover-coveralls--file-coverage-report
                            (gethash file undercover--files-coverage-statistics))))
      (undercover--make-hash-table
       "name"     file-name
       "source"   file-content
       "coverage" coverage-report))))

(defun undercover-coveralls--fill-report (report)
  "Fill test coverage REPORT for coveralls.io."
  (undercover--fill-hash-table report
    "source_files" (mapcar #'undercover-coveralls--file-report undercover--files))
  (let ((env (copy-hash-table (undercover--need-env))))
    (undercover--update-with-git env)
    (undercover-coveralls--update-report-with-env report env)))

(defun undercover-coveralls--merge-report-file-lines-coverage (old-coverage new-coverage)
  "Merge test coverage for lines from OLD-COVERAGE and NEW-COVERAGE."
  (cl-loop for (old-line-coverage . new-line-coverage)
           in (-zip-fill 0 old-coverage new-coverage)
           collect (cond
                    ((null old-line-coverage) new-line-coverage)
                    ((null new-line-coverage) old-line-coverage)
                    (t (+ new-line-coverage old-line-coverage)))))

(defun undercover-coveralls--merge-report-file-coverage (old-file-hash source-files-report)
  "Merge test coverage from OLD-FILE-HASH into SOURCE-FILES-REPORT."
  (let* ((file-name (gethash "name" old-file-hash))
         (old-coverage (gethash "coverage" old-file-hash))
         (new-file-hash (--first (string-equal file-name (gethash "name" it))
                                 source-files-report)))
    (if new-file-hash
        (undercover--fill-hash-table new-file-hash
          "coverage" (undercover-coveralls--merge-report-file-lines-coverage
                      old-coverage (gethash "coverage" new-file-hash)))
      (rplacd (last source-files-report)
              (cons old-file-hash nil)))))

(defun undercover-coveralls--merge-reports (report)
  "Merge test coverage REPORT with existing from `undercover--report-file-path'."
  (condition-case merge-error
      (let* ((json-object-type 'hash-table)
             (json-array-type 'list)
             (old-report (json-read-file undercover--report-file-path))
             (new-source-files-report (gethash "source_files" report)))
        (undercover--message 7
          "Merging existing Coveralls report: %s" undercover--report-file-path)
        (dolist (old-file-hash (gethash "source_files" old-report))
          (undercover-coveralls--merge-report-file-coverage
           old-file-hash new-source-files-report)))
    (error
     (undercover--message 6
       "Failed to merge Coveralls report: %s" merge-error))))

(defun undercover-coveralls--create-report ()
  "Create test coverage report for coveralls.io."
  (undercover--collect-files-coverage undercover--files)
  (let ((report (make-hash-table :test 'equal)))
    (undercover-coveralls--fill-report report)
    (when undercover--merge-report
      (undercover-coveralls--merge-reports report))
    (json-encode report)))

(defun undercover-coveralls--save-report (json-report)
  "Save JSON-REPORT to `undercover--report-file-path'."
  (with-temp-buffer
    (insert json-report)
    (write-region nil nil undercover--report-file-path)))

(defun undercover-coveralls--send-report ()
  "Send report to coveralls.io."
  (let* ((coveralls-endpoint (or (getenv "COVERALLS_ENDPOINT")
                                 "https://coveralls.io"))
         (coveralls-url (concat coveralls-endpoint "/api/v1/jobs")))
    (undercover--message 5 "Uploading report to coveralls.io")
    (unless (zerop (call-process "curl"
                                 nil
                                 (if (>= undercover--verbosity 4)
                                     '(:file "/dev/stderr")
                                   nil)
                                 t
                                 ;; "-v" "--include"
                                 "--fail" "--silent" "--show-error"
                                 "--form"
                                 (concat "json_file=@" undercover--report-file-path)
                                 coveralls-url))
      (error "UNDERCOVER: Upload to coveralls.io failed"))
    ;; curl's output doesn't end with a newline; print one to stderr now
    (external-debugging-output ?\n)
    (undercover--message 5 "Upload OK")))

(defun undercover-coveralls--report ()
  "Create and submit test coverage report to coveralls.io."
  (let ((undercover--report-file-path (or undercover--report-file-path
                                          "/tmp/undercover_coveralls_report")))
    (undercover-coveralls--save-report (undercover-coveralls--create-report))
    (when undercover--send-report
      (undercover-coveralls--send-report))))

;; CodeCov report:

(defun undercover-codecov--report ()
  "Save the coverage information for CodeCov."
  (let ((undercover--report-file-path (or undercover--report-file-path
                                          "coverage-final.json")))
    (undercover-coveralls--save-report (undercover-coveralls--create-report))
    (when undercover--send-report
      (error "UNDERCOVER: Uploading reports to CodeCov is not supported.

Please disable the :send-report option and use CodeCov's upload
script (https://codecov.io/bash) instead"))))

;; LCOV report:

(defconst undercover-lcov--test-name nil
  "The name of the test in the LCOV result set report (for the \"TN:\" line).

If set to nil (the default), no \"TN:\" line will be generated.")

(defun undercover-lcov--create-report ()
  "Create LCOV test coverage report."
  (when (and undercover--merge-report
             (file-readable-p undercover--report-file-path))
    (user-error "Merging of LCOV reports is not implemented. Please delete %s or invoke with (:merge-report nil)."
                undercover--report-file-path))
  (undercover--collect-files-coverage undercover--files)
  (apply #'concat
         ;; Test name
         (if undercover-lcov--test-name
             (concat "TN:" undercover-lcov--test-name "\n")
           "")
         ;; One section per file
         (mapcar
          (lambda (file)
            (let ((statistics (gethash file undercover--files-coverage-statistics))
                  line-numbers)
              ;; Collect line numbers
              (maphash (lambda (k _v)
                         (push k line-numbers))
                       statistics)
              ;; Emit coverage
              (concat
               ;; File name
               "SF:" file "\n"
               ;; Per-line coverage
               (apply #'concat
                      (mapcar
                       (lambda (line)
                         (format "DA:%d,%d\n"
                                 line
                                 (gethash line statistics)))
                       (sort line-numbers #'<)))
               "end_of_record\n")))
          undercover--files)))

(defun undercover-lcov--report ()
  "Create test coverage report in LCOV format."
  (when undercover--send-report
    (error "UNDERCOVER: Cannot upload LCOV reports.

Please disable the :send-report option (or specify a coverage
provider as the :report-format instead of 'lcov)."))
  (let ((undercover--report-file-path (or undercover--report-file-path
                                          "coverage/lcov.info")))
    (make-directory (or (file-name-directory undercover--report-file-path) "") t)
    (with-temp-buffer
      (insert (undercover-lcov--create-report))
      (write-region nil nil undercover--report-file-path))))

;; SimpleCov report:

(defconst undercover-simplecov--report-name "undercover.el"
  "The name of the generated result in the SimpleCov result set report.")

(defalias 'undercover-simplecov--file-coverage-report
  #'undercover-coveralls--file-coverage-report
  "Translate file coverage STATISTICS into SimpleCov format (same as coveralls.io).")

(defalias 'undercover-simplecov--merge-report-file-lines-coverage
  #'undercover-coveralls--merge-report-file-lines-coverage)

(defun undercover-simplecov--file-report (file)
  "Create part of SimpleCov report for FILE."
  (save-excursion
    (find-file file)
    (list file (undercover-simplecov--file-coverage-report
                (gethash file undercover--files-coverage-statistics)))))

(defun undercover-simplecov--fill-report (report)
  "Fill SimpleCov test coverage REPORT."
  (undercover--fill-hash-table report
    undercover-simplecov--report-name
    (undercover--make-hash-table
     "timestamp" (truncate (time-to-seconds))
     "coverage" (apply #'undercover--make-hash-table
                       (apply #'append
                              (mapcar #'undercover-simplecov--file-report
                                      undercover--files))))))

(defun undercover-simplecov--merge-report-file-coverage (target-coverage file-name source-file-coverage)
  "Merge into TARGET-COVERAGE the FILE-NAME's coverage data SOURCE-FILE-COVERAGE."
  (let ((target-file-coverage (gethash file-name target-coverage)))
    (puthash file-name
             (if target-file-coverage
                 (undercover-simplecov--merge-report-file-lines-coverage
                  target-file-coverage
                  source-file-coverage)
               source-file-coverage)
             target-coverage)))

(defun undercover-simplecov--merge-reports (new-report)
  "Merge test coverage NEW-REPORT with existing from `undercover--report-file-path'."
  (when (file-readable-p undercover--report-file-path)
    (undercover--message 7
      "Merging existing SimpleCov report: %s" undercover--report-file-path)
    (let* ((json-object-type 'hash-table)
           (json-array-type 'list)
           (old-report (json-read-file undercover--report-file-path))
           (old-coverage
            (gethash "coverage" (gethash undercover-simplecov--report-name old-report)))
           (new-coverage
            (gethash "coverage" (gethash undercover-simplecov--report-name new-report))))
      (maphash
       (lambda (name old-file-coverage)
         (undercover-simplecov--merge-report-file-coverage new-coverage name old-file-coverage))
       old-coverage)))
  new-report)

(defun undercover-simplecov--create-report ()
  "Create SimpleCov test coverage report."
  (undercover--collect-files-coverage undercover--files)
  (let ((report (make-hash-table :test 'equal)))
    (undercover-simplecov--fill-report report)
    (when undercover--merge-report
      (undercover-simplecov--merge-reports report))
    (json-encode report)))

(defun undercover-simplecov--save-report (json-report)
  "Save JSON-REPORT to `undercover--report-file-path'."
  (with-temp-buffer
    (insert json-report)
    (write-region nil nil undercover--report-file-path)))

(defun undercover-simplecov--report ()
  "Create test coverage report in SimpleCov format."
  (let ((undercover--report-file-path (or undercover--report-file-path
                                          "coverage/.resultset.json")))
    (undercover-simplecov--save-report (undercover-simplecov--create-report))))

;; Simple text report:

(defun undercover-text--create-report ()
  "Print test coverage report for text display."
  (undercover--collect-files-coverage undercover--files)
  (let ((report "== Code coverage text report ==\n"))
    (maphash (lambda (file-name file-coverage)
               (let ((lines-relevant 0)
                     (lines-covered 0))
                 (maphash (lambda (_line-number line-hits)
                            (setq lines-relevant (+ 1 lines-relevant))
                            (when (> line-hits 0)
                              (setq lines-covered (+ 1 lines-covered))))
                          file-coverage)
                 (setq report
                       (format "%s%s : Percent %s%% [Relevant: %s Covered: %s Missed: %s]\n"
                               report
                               (file-name-base file-name)
                               (truncate (* (/ (float lines-covered) (float lines-relevant)) 100))
                               lines-relevant lines-covered (- lines-relevant lines-covered)))))
             undercover--files-coverage-statistics)
    report))

(defun undercover-text--report ()
  "Create and display test coverage."
  (if (null undercover--report-file-path)
      ;; Just print it to the message buffer
      (message "%s" (undercover-text--create-report))
    ;; Write to file
    (with-temp-buffer
      (insert (undercover-text--create-report))
      (write-region nil nil undercover--report-file-path))))

;; Report format selection

(defun undercover--detect-report-format ()
  "Automatic report-format detection."
  (cond
   ((undercover-coveralls--configured-p)
    'coveralls)
   ((not noninteractive)
    'text)))

(defun undercover--report ()
  "Generate and save/upload a test coverage report, as configured."
  (undercover--message 7 "Generating report.")
  (cl-case undercover--report-format
    ((nil)     (error "UNDERCOVER: Report format not configured and auto-detection failed"))
    (coveralls (undercover-coveralls--report))
    (lcov      (undercover-lcov--report))
    (simplecov (undercover-simplecov--report))
    (codecov   (undercover-codecov--report))
    (text      (undercover-text--report))
    (t         (error "UNDERCOVER: Unsupported report-format"))))


;; ----------------------------------------------------------------------------
;; `ert-runner' related functions:

(defun undercover-safe-report ()
  "Like `undercover-report', but makes errors non-fatal."
  (with-demoted-errors
      (undercover-report)))

(defun undercover-report-on-kill ()
  "Queue generating the coverage report before Emacs exits.

To do this, add `undercover-safe-report' to `kill-emacs-hook'."
  (add-hook 'kill-emacs-hook 'undercover-safe-report))


;; ----------------------------------------------------------------------------
;;; Main functions:

(defun undercover-enabled-p ()
  "Return non-nil if `undercover' is enabled."
  (or undercover-force-coverage (undercover--under-ci-p)))

(defun undercover-report (&optional report-format)
  "Generate and save/upload a test coverage report.

If REPORT-FORMAT is non-nil, it specifies the report format (like
the :report-format `undercover' option), overriding previous
configuration."
  (if undercover--files
      (let ((undercover--report-format (or report-format
                                           undercover--report-format
                                           (undercover--detect-report-format))))
        (undercover--report))
    (undercover--message 1
      "No coverage information. Make sure that your files are not compiled?")))

(defun undercover--env-configuration ()
  "Read configuration from UNDERCOVER_CONFIG."
  (let ((configuration (getenv "UNDERCOVER_CONFIG")))
    (when configuration
      (condition-case nil
          (car (read-from-string configuration))
        (error
         (error "UNDERCOVER: Error while parsing configuration"))))))

(defun undercover--set-options (configuration)
  "Extract options from CONFIGURATION and set global variables accordingly.

Options are filtered out, leaving only wildcards, which are returned."
  (cl-destructuring-bind (wildcards options)
      (--separate (or (stringp it)
                      (eq :exclude (car-safe it))
                      (eq :files (car-safe it)))
                  configuration)
    (cl-dolist (option options wildcards)
      (cl-case (car-safe option)
        (:verbosity (setq undercover--verbosity (cadr option)))
        (:report-file (setq undercover--report-file-path (cadr option)))
        (:report-format (setq undercover--report-format (cadr option)))
        (:report-on-kill (setq undercover--report-on-kill (cadr option)))
        (:send-report (setq undercover--send-report (cadr option)))
        (:merge-report (setq undercover--merge-report (cadr option)))
        ;; Note: this option is obsolete and intentionally undocumented.
        ;; Please use (:report-format 'codecov) (:send-report nil) instead.
        (:report-type (undercover--message 2 "The :report-type option is deprecated.")
                      (cl-case (cadr option)
                        (:coveralls (setq undercover--report-format 'coveralls))
                        (:codecov (setq undercover--report-format 'codecov)
                                  (setq undercover--send-report nil))
                        (otherwise (error "UNDERCOVER: Unsupported report-type: %s" (cadr option)))))
        (otherwise (error "UNDERCOVER: Unsupported option: %s" option))))))

(defun undercover--setup (configuration)
  "Enable test coverage for files matched by CONFIGURATION."
  (when (undercover-enabled-p)
    (let ((env-configuration (undercover--env-configuration))
          (default-configuration '("*.el")))
      (undercover--set-edebug-handlers)
      (let ((wildcards (undercover--set-options
                        (or (append configuration env-configuration)
                            default-configuration))))
	(when undercover--report-on-kill
          (undercover-report-on-kill))
        (undercover--edebug-files (undercover--wildcards-to-files wildcards))))))

;;;###autoload
(defmacro undercover (&rest configuration)
  "Enable test coverage for files using CONFIGURATION.

If undercover.el is not enabled, do nothing.  Otherwise,
configure undercover.el using CONFIGURATION, and queue generating
and saving/uploading a coverage report before Emacs exits.

Undercover is enabled if any of the following is true:

- Emacs is detected to be running under a CI service.
- `undercover-force-coverage' is non-nil.
- The \"UNDERCOVER_FORCE\" environment variable exists in Emacs'
  environment.

Each item of CONFIGURATION can be one of the following:

STRING                  Indicates a wildcard of Emacs Lisp files
                        to include in the coverage.  These are
                        globbed using `file-expand-wildcards'.
                        Examples: \"*.el\" \"subdir/*.el\"

(:exclude STRING)       Indicates a wildcard of Emacs Lisp files
                        to exclude from the coverage.
                        Example: (:exclude \"exclude-*.el\")

(:files STRING...)      Indicates a list of Emacs Lisp files to
                        include in the coverage.  These are
                        interpreted verbatim and are not globbed.

(:verbosity NUMBER)     Controls how detailed undercover.el
                        should be in reporting what it's doing
                        using messages, as a number from 0 (no
                        messages, fatal errors only) to 10 (all
                        messages).  The default is 5.

(:report-file STRING)   Sets the path of the file where the
                        coverage report will be written to.

(:report-on-kill BOOLEXP)  Sets whether to queue generating and
                        saving/uploading a repot before Emacs
                        exits.  Enabled by default.

                        If disabled, this can still be done by
                        calling `undercover-report-on-kill'.

(:send-report BOOLEXP)  Sets whether to upload the report to the
                        detected/configured coverage service
                        after generating it.  Enabled by default.

(:merge-report BOOLEXP) If possible, merge collected coverage
                        data into any existing coverage report
                        file.  Enabled by default.  If disabled,
                        undercover.el will always overwrite files
                        when saving reports.

(:report-format SYMBOL) Sets the report target (file format or
                        coverage service), i.e., what to do with
                        the collected coverage information.


Currently supported values for :report-format are:

nil          Detect an appropriate service automatically.

'text        Save or display the coverage information as a simple
             text report.

'coveralls   Upload the coverage information to coveralls.io.

'codecov     Save the coverage information in a format compatible
             with the CodeCov upload script
             (https://codecov.io/bash).

             Because CodeCov natively understands Coveralls'
             report format, all this does (compared to
             'coveralls) is configure the default save path to a
             location that the upload script will look for.

             Uploading from within Undercover is currently not
             supported, and will raise an error.

'lcov        Save the coverage information in the format used by
             GCOV / LCOV / geninfo.

'simplecov   Save the coverage information as a SimpleCov
             .resultset.json file.


Example invocation:

(undercover \"*.el\"
            \"subdir/*.el\"
            (:exclude \"exclude-*.el\")
            (:report-format 'text)
            (:report-file \"coverage.txt\"))

Options may also be specified via the environment variable
\"UNDERCOVER_CONFIG\", which should be formatted as a literal
Emacs Lisp list consisting of items as defined above.
Configuration options in \"UNDERCOVER_CONFIG\" override those in
CONFIGURATION.

If no CONFIGURATION is specified (either as an argument, or via
the environment variable), the default configuration '(\"*.el\")
is used."
  `(undercover--setup
    (list
     ,@(--map (if (atom it) it `(list ,@it))
              configuration))))

(provide 'undercover)
;;; undercover.el ends here
