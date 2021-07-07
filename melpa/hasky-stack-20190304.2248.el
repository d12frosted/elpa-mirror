;;; hasky-stack.el --- Interface to the Stack Haskell development tool -*- lexical-binding: t; -*-
;;
;; Copyright © 2017–2019 Mark Karpov <markkarpov92@gmail.com>
;;
;; Author: Mark Karpov <markkarpov92@gmail.com>
;; URL: https://github.com/hasky-mode/hasky-stack
;; Package-Version: 20190304.2248
;; Package-Commit: 9ef133ed831a95a2b9990a46a3c57f1918d0274f
;; Version: 0.9.0
;; Package-Requires: ((emacs "24.4") (f "0.18.0") (magit-popup "2.10"))
;; Keywords: tools, haskell
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This is an Emacs interface to the Stack Haskell development tool.  Bind
;; the following useful commands:
;;
;;     (global-set-key (kbd "<next> h e") #'hasky-stack-execute)
;;     (global-set-key (kbd "<next> h h") #'hasky-stack-package-action)
;;     (global-set-key (kbd "<next> h i") #'hasky-stack-new)
;;
;; * `hasky-stack-execute' opens a popup with a collection of stack commands
;;   you can run.  Many commands have their own sub-popups like in Magit.
;;
;; * `hasky-stack-package-action' allows to perform actions on package that
;;   the user selects from the list of all available packages.
;;
;; * `hasky-stack-new' allows to create a new project in current directory
;;   using a Stack template.

;;; Code:

(require 'cl-lib)
(require 'f)
(require 'magit-popup)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Settings & Variables

(defgroup hasky-stack nil
  "Interface to the Stack Haskell development tool."
  :group  'programming
  :tag    "Hasky Stack"
  :prefix "hasky-stack-"
  :link   '(url-link :tag "GitHub"
                     "https://github.com/hasky-mode/hasky-stack"))

(defface hasky-stack-project-name
  '((t (:inherit font-lock-function-name-face)))
  "Face used to display name of current project.")

(defface hasky-stack-project-version
  '((t (:inherit font-lock-doc-face)))
  "Face used to display version of current project.")

(defvar hasky-stack--last-directory nil
  "Path to project's directory last time `hasky-stack--prepare' was called.

This is mainly used to check when we need to reload/re-parse
project-local settings that user might have.")

(defvar hasky-stack--cabal-mod-time nil
  "Time of last modification of \"*.cabal\" file.

This is usually set by `hasky-stack--prepare'.")

(defvar hasky-stack--project-name nil
  "Name of current project extracted from \"*.cabal\" file.

This is usually set by `hasky-stack--prepare'.")

(defvar hasky-stack--project-version nil
  "Version of current project extracted from \"*.cabal\" file.

This is usually set by `hasky-stack--prepare'.")

(defvar hasky-stack--project-targets nil
  "List of build targets (strings) extracted from \"*.cabal\" file.

This is usually set by `hasky-stack--prepare'.")

(defvar hasky-stack--package-action-package nil
  "This variable is temporarily bound to name of package.")

(defcustom hasky-stack-executable nil
  "Path to Stack executable.

If it's not NIL, this value is used in invocation of Stack
commands instead of the standard \"stack\" string.  Set this
variable if your Stack is not on PATH.

Note that the path is quoted with `shell-quote-argument' before
being used to compose command line."
  :tag  "Path to Stack Executable"
  :type '(choice (file :must-match t)
                 (const :tag "Use Default" nil)))

(defcustom hasky-stack-config-dir "~/.stack"
  "Path to Stack configuration directory."
  :tag  "Path to Stack configuration directory"
  :type 'directory)

(defcustom hasky-stack-read-function #'completing-read
  "Function to be called when user has to choose from list of alternatives."
  :tag  "Completing Function"
  :type '(radio (function-item completing-read)))

(defcustom hasky-stack-ghc-versions '("8.6.3" "8.4.4" "8.2.2" "8.0.2" "7.10.3" "7.8.4")
  "GHC versions to pick from (for commands like \"stack setup\")."
  :tag  "GHC versions"
  :type '(repeat (string :tag "Extension name")))

(defcustom hasky-stack-auto-target nil
  "Whether to automatically select the default build target."
  :tag  "Build auto-target"
  :type 'boolean)

(defcustom hasky-stack-auto-open-coverage-reports nil
  "Whether to attempt to automatically open coverage report in browser."
  :tag  "Automatically open coverage reports"
  :type 'boolean)

(defcustom hasky-stack-auto-open-haddocks nil
  "Whether to attempt to automatically open Haddocks in browser."
  :tag  "Automatically open Haddocks"
  :type 'boolean)

(defcustom hasky-stack-auto-newest-version nil
  "Whether to install newest version of package without asking.

This is used in `hasky-stack-package-action'."
  :tag  "Automatically install newest version"
  :type 'boolean)

(defcustom hasky-stack-templates
  '("chrisdone"
    "foundation"
    "franklinchen"
    "ghcjs"
    "ghcjs-old-base"
    "hakyll-template"
    "haskeleton"
    "hspec"
    "new-template"
    "protolude"
    "quickcheck-test-framework"
    "readme-lhs"
    "rio"
    "rubik"
    "scotty-hello-world"
    "scotty-hspec-wai"
    "servant"
    "servant-docker"
    "simple"
    "simple-hpack"
    "simple-library"
    "spock"
    "tasty-discover"
    "tasty-travis"
    "unicode-syntax-exe"
    "unicode-syntax-lib"
    "yesod-minimal"
    "yesod-mongo"
    "yesod-mysql"
    "yesod-postgres"
    "yesod-simple"
    "yesod-sqlite")
  "List of known templates to choose from when creating new project."
  :tag "List of known stack templates"
  :type '(repeat (string :tag "Template name")))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Various utilities

(defun hasky-stack--all-matches (regexp)
  "Return list of all stings matching REGEXP in current buffer."
  (let (matches
        (case-fold-search t))
    (goto-char (point-min))
    (while (re-search-forward regexp nil t)
      (push (match-string-no-properties 1) matches))
    (reverse matches)))

(defun hasky-stack--parse-cabal-file (filename)
  "Parse \"*.cabal\" file with name FILENAME and set some variables.

The following variables are set:

  `hasky-stack--project-name'
  `hasky-stack--project-version'
  `hasky-stack--project-targets'

This is used by `hasky-stack--prepare'."
  (with-temp-buffer
    (insert-file-contents filename)
    ;; project name
    (setq hasky-stack--project-name
          (car (hasky-stack--all-matches
                "^[[:blank:]]*name:[[:blank:]]+\\([[:word:]-]+\\)")))
    ;; project version
    (setq hasky-stack--project-version
          (car (hasky-stack--all-matches
                "^[[:blank:]]*version:[[:blank:]]+\\([[:digit:]\\.]+\\)")))
    ;; project targets
    (setq
     hasky-stack--project-targets
     (append
      ;; library
      (mapcar (lambda (_) (format "%s:lib" hasky-stack--project-name))
              (hasky-stack--all-matches
               "^[[:blank:]]*library[[:blank:]]*"))
      ;; executables
      (mapcar (lambda (x) (format "%s:exe:%s" hasky-stack--project-name x))
              (hasky-stack--all-matches
               "^[[:blank:]]*executable[[:blank:]]+\\([[:word:]-]+\\)"))
      ;; test suites
      (mapcar (lambda (x) (format "%s:test:%s" hasky-stack--project-name x))
              (hasky-stack--all-matches
               "^[[:blank:]]*test-suite[[:blank:]]+\\([[:word:]-]+\\)"))
      ;; benchmarks
      (mapcar (lambda (x) (format "%s:bench:%s" hasky-stack--project-name x))
              (hasky-stack--all-matches
               "^[[:blank:]]*benchmark[[:blank:]]+\\([[:word:]-]+\\)"))))))

(defun hasky-stack--home-page-from-cabal-file (filename)
  "Parse package home page from \"*.cabal\" file with FILENAME."
  (with-temp-buffer
    (insert-file-contents filename)
    (or
     (car (hasky-stack--all-matches
           "^[[:blank:]]*homepage:[[:blank:]]+\\(.+\\)"))
     (let ((without-scheme
            (car
             (hasky-stack--all-matches
              "^[[:blank:]]*location:[[:blank:]]+.*:\\(.+\\)\\(\\.git\\)?"))))
       (when without-scheme
         (concat "https:" without-scheme))))))

(defun hasky-stack--find-dir-of-file (regexp)
  "Find file whose name satisfies REGEXP traversing upwards.

Return absolute path to directory containing that file or NIL on
failure.  Returned path is guaranteed to have trailing slash."
  (let ((dir (f-traverse-upwards
              (lambda (path)
                (directory-files path t regexp t))
              (f-full default-directory))))
    (when dir
      (f-slash dir))))

(defun hasky-stack--mod-time (filename)
  "Return time of last modification of file FILENAME."
  (nth 5 (file-attributes filename 'integer)))

(defun hasky-stack--executable ()
  "Return path to stack executable if it's available and NIL otherwise."
  (let ((default "stack")
        (custom  hasky-stack-executable))
    (cond ((executable-find default)     default)
          ((and custom (f-file? custom)) custom))))

(defun hasky-stack--index-file ()
  "Get path to Hackage index file."
  (f-expand "indices/Hackage/00-index.tar" hasky-stack-config-dir))

(defun hasky-stack--index-dir ()
  "Get path to directory that is to contain unpackaed Hackage index."
  (file-name-as-directory
   (f-expand "indices/Hackage/00-index" hasky-stack-config-dir)))

(defun hasky-stack--index-stamp-file ()
  "Get path to Hackage index time stamp file."
  (f-expand "ts" (hasky-stack--index-dir)))

(defun hasky-stack--ensure-indices ()
  "Make sure that we have downloaded and untar-ed Hackage package indices.

This uses external ‘tar’ command, so it probably won't work on
Windows."
  (let ((index-file (hasky-stack--index-file))
        (index-dir (hasky-stack--index-dir))
        (index-stamp (hasky-stack--index-stamp-file)))
    (unless (f-file? index-file)
      ;; No indices in place, need to run stack update to get them.
      (message "Cannot find Hackage indices, trying to download them")
      (shell-command (concat (hasky-stack--executable) " update")))
    (if (f-file? index-file)
        (when (or (not (f-file? index-stamp))
                  (time-less-p (hasky-stack--mod-time index-stamp)
                               (hasky-stack--mod-time index-file)))
          (f-mkdir index-dir)
          (let ((default-directory index-dir))
            (message "Extracting Hackage indices, please be patient")
            (shell-command
             (concat "tar -xf " (shell-quote-argument index-file))))
          (f-touch index-stamp)
          (message "Finished preparing Hackage indices"))
      (error "%s" "Failed to fetch indices, something is wrong!"))))

(defun hasky-stack--packages ()
  "Return list of all packages in Hackage indices."
  (hasky-stack--ensure-indices)
  (mapcar
   #'f-filename
   (f-entries (hasky-stack--index-dir) #'f-directory?)))

(defun hasky-stack--package-versions (package)
  "Return list of all available versions of PACKAGE."
  (mapcar
   #'f-filename
   (f-entries (f-expand package (hasky-stack--index-dir))
              #'f-directory?)))

(defun hasky-stack--latest-version (versions)
  "Return latest version from VERSIONS."
  (cl-reduce (lambda (x y) (if (version< y x) x y))
             versions))

(defun hasky-stack--package-with-version (package version)
  "Render identifier of PACKAGE with VERSION."
  (concat package "-" version))

(defun hasky-stack--completing-read (prompt &optional collection require-match)
  "Read user's input using `hasky-stack-read-function'.

PROMPT is the prompt to show and COLLECTION represents valid
choices.  If REQUIRE-MATCH is not NIL, don't let user input
something different from items in COLLECTION.

COLLECTION is allowed to be a string, in this case it's
automatically wrapped to make it one-element list.

If COLLECTION contains \"none\", and user selects it, interpret
it as NIL.  If user aborts entering of the input, return NIL.

Finally, if COLLECTION is nil, plain `read-string' is used."
  (let* ((collection
          (if (listp collection)
              collection
            (list collection)))
         (result
          (if collection
              (funcall hasky-stack-read-function
                       prompt
                       collection
                       nil
                       require-match
                       nil
                       nil
                       (car collection))
            (read-string prompt))))
    (unless (and (string= result "none")
                 (member result collection))
      result)))

(defun hasky-stack--select-target (prompt &optional fragment)
  "Present the user with a choice of build target using PROMPT.

If given, FRAGMENT will be as a filter so only targets that
contain this string will be returned."
  (if hasky-stack-auto-target
      hasky-stack--project-name
    (hasky-stack--completing-read
     prompt
     (cons hasky-stack--project-name
           (if fragment
               (cl-remove-if
                (lambda (x)
                  (not (string-match-p (regexp-quote fragment) x)))
                hasky-stack--project-targets)
             hasky-stack--project-targets)
           )
     t)))

(defun hasky-stack--select-package-version (package)
  "Present the user with a choice of PACKAGE version."
  (let ((versions (hasky-stack--package-versions package)))
    (if hasky-stack-auto-newest-version
        (hasky-stack--latest-version versions)
      (hasky-stack--completing-read
       (format "Version of %s: " package)
       (cl-sort versions (lambda (x y) (version< y x)))
       t))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Preparation

(defun hasky-stack--prepare ()
  "Locate, read, and parse configuration files and set various variables.

This commands searches for first \"*.cabal\" files traversing
directories upwards beginning with `default-directory'.  When
Cabal file is found, the following variables are set:

  `hasky-stack--project-name'
  `hasky-stack--project-version'
  `hasky-stack--project-targets'

At the end, `hasky-stack--last-directory' and
`hasky-stack--cabal-mod-time' are set.  Note that this function
is smart enough to avoid re-parsing all the stuff every time.  It
can detect when we are in different project or when some files
have been changed since its last invocation.

Returned value is T on success and NIL on failure (when no
\"*.cabal\" files is found)."
  (let* ((project-directory
          (hasky-stack--find-dir-of-file "^.+\.cabal$"))
         (cabal-file
          (car (and project-directory
                    (f-glob "*.cabal" project-directory)))))
    (when cabal-file
      (if (or (not hasky-stack--last-directory)
              (not (f-same? hasky-stack--last-directory
                            project-directory)))
          (progn
            ;; We are in different directory (or it's the first
            ;; invocation). This means we should unconditionally parse
            ;; everything without checking of date of last modification.
            (hasky-stack--parse-cabal-file cabal-file)
            (setq hasky-stack--cabal-mod-time (hasky-stack--mod-time cabal-file))
            ;; Set last directory for future checks.
            (setq hasky-stack--last-directory project-directory)
            t) ;; Return T on success.
        ;; We are in an already visited directory, so we don't need to reset
        ;; `hasky-stack--last-directory' this time. We need to
        ;; reread/re-parse *.cabal file if it has been modified though.
        (when (time-less-p hasky-stack--cabal-mod-time
                           (hasky-stack--mod-time cabal-file))
          (hasky-stack--parse-cabal-file cabal-file)
          (setq hasky-stack--cabal-mod-time (hasky-stack--mod-time cabal-file)))
        t))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Low-level construction of individual commands

(defun hasky-stack--format-command (command &rest args)
  "Generate textual representation of a command.

COMMAND is the name of command and ARGS are arguments (strings).
Result is expected to be used as argument of `compile'."
  (mapconcat
   #'identity
   (append
    (list (shell-quote-argument (hasky-stack--executable))
          command)
    (mapcar #'shell-quote-argument
            (remove nil args)))
   " "))

(defun hasky-stack--exec-command (package dir command &rest args)
  "Call stack for PACKAGE as if from DIR performing COMMAND with arguments ARGS.

Arguments are quoted if necessary and NIL arguments are ignored.
This uses `compile' internally."
  (let ((default-directory dir)
        (compilation-buffer-name-function
         (lambda (_major-mode)
           (format "*%s-%s*"
                   (downcase
                    (replace-regexp-in-string
                     "[[:space:]]"
                     "-"
                     (or package "hasky")))
                   "stack"))))
    (compile (apply #'hasky-stack--format-command command args))
    nil))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables

(defun hasky-stack--cycle-bool-variable (symbol)
  "Cycle value of variable named SYMBOL."
  (custom-set-variables
   (list symbol (not (symbol-value symbol)))))

(defun hasky-stack--format-bool-variable (symbol label)
  "Format a Boolean variable named SYMBOL, label it as LABEL."
  (let ((val (symbol-value symbol)))
    (concat
     (format "%s " label)
     (propertize
      (if val "enabled" "disabled")
      'face
      (if val
          'magit-popup-option-value
        'magit-popup-disabled-argument)))))

(defun hasky-stack--acp (fun &rest args)
  "Apply FUN to ARGS partially and return a command."
  (lambda (&rest args2)
    (interactive)
    (apply fun (append args args2))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Popups

(magit-define-popup hasky-stack-build-popup
  "Show popup for the \"stack build\" command."
  'hasky-stack
  :variables `((?a "auto-target"
                   ,(hasky-stack--acp
                     #'hasky-stack--cycle-bool-variable
                     'hasky-stack-auto-target)
                   ,(hasky-stack--acp
                     #'hasky-stack--format-bool-variable
                     'hasky-stack-auto-target
                     "Auto target"))
               (?c "auto-open-coverage-reports"
                   ,(hasky-stack--acp
                     #'hasky-stack--cycle-bool-variable
                     'hasky-stack-auto-open-coverage-reports)
                   ,(hasky-stack--acp
                     #'hasky-stack--format-bool-variable
                     'hasky-stack-auto-open-coverage-reports
                     "Auto open coverage reports"))
               (?d "auto-open-haddocks"
                   ,(hasky-stack--acp
                     #'hasky-stack--cycle-bool-variable
                     'hasky-stack-auto-open-haddocks)
                   ,(hasky-stack--acp
                     #'hasky-stack--format-bool-variable
                     'hasky-stack-auto-open-haddocks
                     "Auto open Haddocks")))
  :switches '((?r "Dry run"           "--dry-run")
              (?t "Pedantic"          "--pedantic")
              (?f "Fast"              "--fast")
              (?F "File watch"        "--file-watch")
              (?s "Only snapshot"     "--only-snapshot")
              (?d "Only dependencies" "--only-dependencies")
              (?p "Profile"           "--profile")
              (?c "Coverage"          "--coverage")
              (?b "Copy bins"         "--copy-bins")
              (?g "Copy compiler tool" "--copy-compiler-tool")
              (?l "Library profiling" "--library-profiling")
              (?e "Executable profiling" "--executable-profiling"))
  :options  '((?o "GHC options"         "--ghc-options=")
              (?b "Benchmark arguments" "--benchmark-arguments=")
              (?t "Test arguments"      "--test-arguments=")
              (?h "Haddock arguments"   "--haddock-arguments="))
  :actions  '((?b "Build"   hasky-stack-build)
              (?e "Bench"   hasky-stack-bench)
              (?t "Test"    hasky-stack-test)
              (?h "Haddock" hasky-stack-haddock))
  :default-action 'hasky-stack-build)

(defun hasky-stack-build (target &optional args)
  "Execute \"stack build\" command for TARGET with ARGS."
  (interactive
   (list (hasky-stack--select-target "Build target: ")
         (hasky-stack-build-arguments)))
  (apply
   #'hasky-stack--exec-command
   hasky-stack--project-name
   hasky-stack--last-directory
   "build"
   target
   args))

(defun hasky-stack-bench (target &optional args)
  "Execute \"stack bench\" command for TARGET with ARGS."
  (interactive
   (list (hasky-stack--select-target "Bench target: " ":bench:")
         (hasky-stack-build-arguments)))
  (apply
   #'hasky-stack--exec-command
   hasky-stack--project-name
   hasky-stack--last-directory
   "bench"
   target
   args))

(defun hasky-stack-test (target &optional args)
  "Execute \"stack test\" command for TARGET with ARGS."
  (interactive
   (list (hasky-stack--select-target "Test target: " ":test:")
         (hasky-stack-build-arguments)))
  (apply
   #'hasky-stack--exec-command
   hasky-stack--project-name
   hasky-stack--last-directory
   "test"
   target
   args))

(defun hasky-stack-haddock (&optional args)
  "Execute \"stack haddock\" command for TARGET with ARGS."
  (interactive
   (list (hasky-stack-build-arguments)))
  (apply
   #'hasky-stack--exec-command
   hasky-stack--project-name
   hasky-stack--last-directory
   "haddock"
   args))

(magit-define-popup hasky-stack-init-popup
  "Show popup for the \"stack init\" command."
  'hasky-stack
  :switches '((?s "Solver"         "--solver")
              (?o "Omit packages"  "--omit-packages")
              (?f "Force"          "--force")
              (?i "Ignore subdirs" "--ignore-subdirs"))
  :actions  '((?i "Init" hasky-stack-init))
  :default-action 'hasky-stack-init)

(defun hasky-stack-init (&optional args)
  "Execute \"stack init\" with ARGS."
  (interactive
   (list (hasky-stack-init-arguments)))
  (apply
   #'hasky-stack--exec-command
   hasky-stack--project-name
   hasky-stack--last-directory
   "init"
   args))

(magit-define-popup hasky-stack-setup-popup
  "Show popup for the \"stack setup\" command."
  'hasky-stack
  :switches '((?r "Reinstall"     "--reinstall")
              (?c "Upgrade Cabal" "--upgrade-cabal"))
  :actions  '((?s "Setup" hasky-stack-setup))
  :default-action 'hasky-stack-setup)

(defun hasky-stack-setup (ghc-version &optional args)
  "Execute \"stack setup\" command to install GHC-VERSION with ARGS."
  (interactive
   (list (hasky-stack--completing-read
          "GHC version: "
          (cons "implied-by-resolver"
                hasky-stack-ghc-versions)
          t)
         (hasky-stack-setup-arguments)))
  (apply
   #'hasky-stack--exec-command
   hasky-stack--project-name
   hasky-stack--last-directory
   "setup"
   (unless (string= ghc-version "implied-by-resolver")
     ghc-version)
   args))

(magit-define-popup hasky-stack-upgrade-popup
  "Show popup for the \"stack upgrade\" command."
  'hasky-stack
  :switches '((?s "Source only" "--source-only")
              (?b "Binary only" "--binary-only")
              (?f "Force download" "--force-download")
              (?g "Git" "--git"))
  :options  '((?p "Binary platform" "--binary-platform=")
              (?v "Binary version" "--binary-version=")
              (?r "Git repo" "--git-repo="))
  :actions  '((?g "Upgrade" hasky-stack-upgrade))
  :default-arguments '("--git-repo=https://github.com/commercialhaskell/stack")
  :default-action 'hasky-stack-upgrade)

(defun hasky-stack-upgrade (&optional args)
  "Execute \"stack upgrade\" command with ARGS."
  (interactive
   (list (hasky-stack-upgrade-arguments)))
  (apply
   #'hasky-stack--exec-command
   hasky-stack--project-name
   hasky-stack--last-directory
   "upgrade"
   args))

(magit-define-popup hasky-stack-upload-popup
  "Show popup for the \"stack upload\" command."
  'hasky-stack
  :switches '((?i "Ignore check" "--ignore-check")
              (?n "No signature" "--no-signature")
              (?t "Test tarball" "--test-tarball"))
  :options  '((?s "Sig server" "--sig-server="))
  :actions  '((?p "Upload" hasky-stack-upload))
  :default-arguments '("--no-signature")
  :default-action 'hasky-stack-upload)

(defun hasky-stack-upload (&optional args)
  "Execute \"stack upload\" command with ARGS."
  (interactive
   (list (hasky-stack-upload-arguments)))
  (apply
   #'hasky-stack--exec-command
   hasky-stack--project-name
   hasky-stack--last-directory
   "upload"
   "."
   args))

(magit-define-popup hasky-stack-sdist-popup
  "Show popup for the \"stack sdist\" command."
  'hasky-stack
  :switches '((?i "Ignore check" "--ignore-check")
              (?s "Sign"         "--sign")
              (?t "Test tarball" "--test-tarball"))
  :options  '((?s "Sig server"   "--sig-server="))
  :actions  '((?d "SDist" hasky-stack-sdist))
  :default-action 'hasky-stack-sdist)

(defun hasky-stack-sdist (&optional args)
  "Execute \"stack sdist\" command with ARGS."
  (interactive
   (list (hasky-stack-sdist-arguments)))
  (apply
   #'hasky-stack--exec-command
   hasky-stack--project-name
   hasky-stack--last-directory
   "sdist"
   args))

(defun hasky-stack-exec (cmd)
  "Execute \"stack exec\" command running CMD."
  (interactive
   (list (read-string "Command to run: ")))
  (cl-destructuring-bind (app . args)
      (progn
        (string-match
         "^[[:blank:]]*\\(?1:[^[:blank:]]+\\)[[:blank:]]*\\(?2:.*\\)$"
         cmd)
        (cons (match-string 1 cmd)
              (match-string 2 cmd)))
    (hasky-stack--exec-command
     hasky-stack--project-name
     hasky-stack--last-directory
     (if (string= args "")
         (concat "exec " app)
       (concat "exec " app " -- " args)))))

(defun hasky-stack-run (cmd)
  "Execute \"stack run\" command running CMD."
  (interactive
   (list (read-string "Command to run: ")))
  (cl-destructuring-bind (app . args)
      (progn
        (string-match
         "^[[:blank:]]*\\(?1:[^[:blank:]]+\\)[[:blank:]]*\\(?2:.*\\)$"
         cmd)
        (cons (match-string 1 cmd)
              (match-string 2 cmd)))
    (hasky-stack--exec-command
     hasky-stack--project-name
     hasky-stack--last-directory
     (if (string= args "")
         (concat "run " app)
       (concat "run " app " -- " args)))))

(magit-define-popup hasky-stack-clean-popup
  "Show popup for the \"stack clean\" command."
  'hasky-stack
  :switches '((?f "Full"  "--full"))
  :actions  '((?c "Clean" hasky-stack-clean))
  :default-action 'hasky-stack-clean)

(defun hasky-stack-clean (&optional args)
  "Execute \"stack clean\" command with ARGS."
  (interactive
   (list (hasky-stack-clean-arguments)))
  (apply
   #'hasky-stack--exec-command
   hasky-stack--project-name
   hasky-stack--last-directory
   "clean"
   (if (member "--full" args)
       args
     (list hasky-stack--project-name))))

(magit-define-popup hasky-stack-root-popup
  "Show root popup with all supported commands."
  'hasky-stack
  :actions  '((lambda ()
                (concat
                 (propertize hasky-stack--project-name
                             'face 'hasky-stack-project-name)
                 " "
                 (propertize hasky-stack--project-version
                             'face 'hasky-stack-project-version)
                 "\n\n"
                 (propertize "Commands"
                             'face 'magit-popup-heading)))
              (?b "Build"   hasky-stack-build-popup)
              (?i "Init"    hasky-stack-init-popup)
              (?s "Setup"   hasky-stack-setup-popup)
              (?u "Update"  hasky-stack-update)
              (?g "Upgrade" hasky-stack-upgrade-popup)
              (?p "Upload"  hasky-stack-upload-popup)
              (?d "SDist"   hasky-stack-sdist-popup)
              (?x "Exec"    hasky-stack-exec)
              (?r "Run"     hasky-stack-run)
              (?c "Clean"   hasky-stack-clean-popup)
              (?l "Edit Cabal file" hasky-stack-edit-cabal)
              (?y "Edit stack.yaml" hasky-stack-edit-stack-yaml))
  :default-action 'hasky-stack-build-popup
  :max-action-columns 3)

(defun hasky-stack-update ()
  "Execute \"stack update\"."
  (interactive)
  (hasky-stack--exec-command
   hasky-stack--project-name
   hasky-stack--last-directory
   "update"))

(defun hasky-stack-edit-cabal ()
  "Open Cabal file of current project for editing."
  (interactive)
  (let ((cabal-file
         (car (and hasky-stack--last-directory
                   (f-glob "*.cabal" hasky-stack--last-directory)))))
    (when cabal-file
      (find-file cabal-file))))

(defun hasky-stack-edit-stack-yaml ()
  "Open \"stack.yaml\" of current project for editing."
  (interactive)
  (let ((stack-yaml-file
         (car (and hasky-stack--last-directory
                   (f-glob "stack.yaml" hasky-stack--last-directory)))))
    (when stack-yaml-file
      (find-file stack-yaml-file))))

(magit-define-popup hasky-stack-package-action-popup
  "Show package action popup."
  'hasky-stack
  :variables `((?a "auto-newest-version"
                   ,(hasky-stack--acp
                     #'hasky-stack--cycle-bool-variable
                     'hasky-stack-auto-newest-version)
                   ,(hasky-stack--acp
                     #'hasky-stack--format-bool-variable
                     'hasky-stack-auto-newest-version
                     "Auto newest version")))
  :options   '((?r "Resolver to use" "--resolver="))
  :actions   '((?i "Install"      hasky-stack-package-install)
               (?h "Hackage"      hasky-stack-package-open-hackage)
               (?s "Stackage"     hasky-stack-package-open-stackage)
               (?m "Build matrix" hasky-stack-package-open-build-matrix)
               (?g "Home page"    hasky-stack-package-open-home-page)
               (?c "Changelog"    hasky-stack-package-open-changelog))
  :default-action 'hasky-stack-package-install
  :max-action-columns 3)

(defun hasky-stack-package-install (package version &optional args)
  "Install PACKAGE of VERSION globally using ARGS."
  (interactive
   (list hasky-stack--package-action-package
         (hasky-stack--select-package-version
          hasky-stack--package-action-package)
         (hasky-stack-package-action-arguments)))
  (apply
   #'hasky-stack--exec-command
   hasky-stack--package-action-package
   hasky-stack-config-dir
   "install"
   (hasky-stack--package-with-version package version)
   args))

(defun hasky-stack-package-open-hackage (package)
  "Open Hackage page for PACKAGE."
  (interactive (list hasky-stack--package-action-package))
  (browse-url
   (concat "https://hackage.haskell.org/package/"
           (url-hexify-string package))))

(defun hasky-stack-package-open-stackage (package)
  "Open Stackage page for PACKAGE."
  (interactive (list hasky-stack--package-action-package))
  (browse-url
   (concat "https://www.stackage.org/package/"
           (url-hexify-string package))))

(defun hasky-stack-package-open-build-matrix (package)
  "Open Hackage build matrix for PACKAGE."
  (interactive (list hasky-stack--package-action-package))
  (browse-url
   (concat "https://matrix.hackage.haskell.org/package/"
           (url-hexify-string package))))

(defun hasky-stack-package-open-home-page (package)
  "Open home page of PACKAGE."
  (interactive (list hasky-stack--package-action-package))
  (let* ((versions (hasky-stack--package-versions package))
         (latest-version (hasky-stack--latest-version versions))
         (cabal-file (f-join (hasky-stack--index-dir)
                             package
                             latest-version
                             (concat package ".cabal")))
         (homepage (hasky-stack--home-page-from-cabal-file cabal-file)))
    (browse-url homepage)))

(defun hasky-stack-package-open-changelog (package)
  "Open Hackage build matrix for PACKAGE."
  (interactive (list hasky-stack--package-action-package))
  (browse-url
   (concat "https://hackage.haskell.org/package/"
           (url-hexify-string
            (hasky-stack--package-with-version
             package
             (hasky-stack--latest-version
              (hasky-stack--package-versions package))))
           "/changelog")))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; High-level interface

;;;###autoload
(defun hasky-stack-execute ()
  "Show the root-level popup allowing to choose and run a Stack command."
  (interactive)
  (if (hasky-stack--executable)
      (if (hasky-stack--prepare)
          (hasky-stack-root-popup)
        (message "Cannot locate ‘.cabal’ file"))
    (error "%s" "Cannot locate Stack executable on this system")))

;;;###autoload
(defun hasky-stack-new (project-name template)
  "Initialize the current directory by using a Stack template.

PROJECT-NAME is the name of project and TEMPLATE is quite
obviously template name."
  (interactive
   (list (hasky-stack--completing-read
          "Project name: "
          (file-name-nondirectory
           (directory-file-name
            default-directory)))
         (hasky-stack--completing-read
          "Use template: "
          (cons "none" hasky-stack-templates)
          t)))
  (if (hasky-stack--prepare)
      (message "The directory is already initialized, it seems")
    (hasky-stack--exec-command
     project-name
     default-directory
     "new"
     "--bare"
     project-name
     template)))

;;;###autoload
(defun hasky-stack-package-action (package)
  "Open a popup allowing to install or request information about PACKAGE.

This functionality currently relies on existence of ‘tar’
command.  This means that it works on Posix systems, but may have
trouble working on Windows.  Please let me know if you run into
any issues on Windows and we'll try to work around (I don't have
a Windows machine)."
  (interactive
   (list (hasky-stack--completing-read
          "Package: "
          (hasky-stack--packages)
          t)))
  (setq hasky-stack--package-action-package package)
  (hasky-stack-package-action-popup))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setting up post-compilation magic

(defun hasky-stack--compilation-finish-function (buffer str)
  "Function that is called when a compilation process in BUFFER finishes.

STR describes how the process finished."
  (when (and (string-match "^\\*.*-stack\\*$" (buffer-name buffer))
             (string= str "finished\n"))
    (with-current-buffer buffer
      ;; Coverage report
      (goto-char (point-min))
      (when (and hasky-stack-auto-open-coverage-reports
                 (re-search-forward
                  "^The coverage report for .+'s test-suite \".+\" is available at \\(.*\\)$" nil t))
        (browse-url (match-string-no-properties 1)))
      (cl-flet ((open-haddock
                 (regexp)
                 (goto-char (point-min))
                 (when (and hasky-stack-auto-open-haddocks
                            (re-search-forward regexp nil t))
                   (browse-url (f-expand (match-string-no-properties 1)
                                         hasky-stack--last-directory))
                   t)))
        (or (open-haddock "^Documentation created:\n\\(.*\\),$")
            (open-haddock "^Haddock index for local packages already up to date at:\n\\(.*\\)$")
            (open-haddock "^Updating Haddock index for local packages in\n\\(.*\\)$"))))))

(add-to-list 'compilation-finish-functions
             #'hasky-stack--compilation-finish-function)

(provide 'hasky-stack)

;;; hasky-stack.el ends here
