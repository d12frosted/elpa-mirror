;;; malinka.el --- A C/C++ project configuration package for Emacs -*- lexical-binding: t; -*-
;;

;; Copyright © 2014-2015 Lefteris Karapetsas <lefteris@refu.co>
;;
;; Author: Lefteris Karapetsas <lefteris@refu.co>
;; URL: https://github.com/LefterisJP/malinka
;; Package-Version: 20171202.1021
;; Package-Commit: d4aa517c7a9022eae16c758c7efdb3a0403542d7
;; Keywords: c c++ project-management
;; Version: 0.3.2
;; Package-Requires: ((s "1.9.0") (dash "2.4.0") (f "0.11.0") (cl-lib "0.3") (rtags "0.0") (projectile "0.11.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.
;;

;;; Commentary:
;; Malinka is a project management Emacs package for C/C++
;;
;; It uses rtags to help the user jump around the code easily and without the
;; mistaken tag jumping that other taggers frequently have with C/C++ code.
;; The main functionality of malinka is to properly populate and communicate the
;; compiler commands to the rtags daemons depending on the project you are working
;; on.
;;
;; Optionally and if you also have flycheck with the clang syntax-checker activated
;; malinka will communicate to flycheck's clang syntax checker the appropriate
;; cpp-defines and include paths so that flycheck can do its syntax checking.
;;
;; The way to define a project is by using `malinka-define-project' and to provide
;; the basic attributes that a project needs.  For more information you can read
;; the function's docstring and the readme file.  For a quick introduction you can
;; visit this blog post http://blog.refu.co/?p=1311

;;; Code:

(require 'cl-lib)
(require 'projectile)
(require 's)
(require 'dash)
(require 'f)
(require 'json)
(require 'rtags)



;;; --- Customizable variables ---
(defgroup malinka nil
  "An Emacs c/c++ project manager"
  :group 'tools ;; Emacs -> Programming -> tools
  :prefix "malinka-"
  :link '(url-link :tag "Github" "https://github.com/LefterisJP/malinka"))

(defcustom malinka-completion-system nil
  "The completion system to use.

Inspired by flycheck's choice of completion system.
Docstrings are also taken from there.

`ido'
     Use IDO.

     IDO is a built-in alternative completion system, without
     good flex matching and a powerful UI.  You may want to
     install flx-ido (see URL `https://github.com/lewang/flx') to
     improve the flex matching in IDO.

nil
     Use the standard unfancy `completing-read'.

     `completing-read' has a very simple and primitive UI, and
     does not offer flex matching.  This is the default setting,
     though, to match Emacs' defaults.  With this system, you may
     want enable option `icomplete-mode' to improve the display
     of completion candidates at least."
  :group 'malinka
  :type '(choice (const :tag "IDO" ido)
                 (const :tag "Completing read" nil))
  :package-version '(malinka . "0.1.0"))

(defcustom malinka-ignored-directories '(".git" ".hg")
  "A list of directories to ignore for file searching."
  :group 'malinka
  :type '(repeat (string :tag "Ignored directory"))
  :safe #'malinka--string-list-p
  :package-version '(malinka . "0.2.0"))

(defun malinka--compiler-create (compiler)
  "Take a COMPILER and create a list of legal string values for it."
  (list compiler (f-full (shell-command-to-string (format "which %s" compiler)))))

(defcustom malinka-supported-compilers `(,(malinka--compiler-create "gcc")
                                         ,(malinka--compiler-create "cc")
                                         ,(malinka--compiler-create "g++")
                                         ,(malinka--compiler-create "clang")
                                         ,(malinka--compiler-create "clang++")
                                         ,(malinka--compiler-create "c++"))
  "A list of compiler executable names that are recognized and supported by malinka."
  :group 'malinka
  :type '(repeat (string :tag "Supported compilers"))
  ;; :safe #'malinka--string-list-p
  :package-version '(malinka . "0.2.0"))

(defcustom malinka-supported-file-types '("c" "cc" "cpp" "C" "c++" "cxx"
                                          "h" "hh" "hpp" "H" "h++" "cxx"
                                          "tcc")
  "File extensions that malinka will treat as related source and header files."
  :group 'malinka
  :type '(repeat (string :tag "Supported file types"))
  :safe #'malinka--string-list-p
  :package-version '(malinka . "0.2.0"))

(defcustom malinka-supported-header-types '("h" "hh" "hpp" "H" "h++")
  "File extensions that malinka will treat as related header files."
  :group 'malinka
  :type '(repeat (string :tag "Supported file types"))
  :safe #'malinka--string-list-p
  :package-version '(malinka . "0.3.0"))

(defcustom malinka-mode-line " malinka"
  "The string to show in the mode line when malinka minor mode is active."
  :group 'malinka
  :package-version '(malinka . "0.3.0"))

(defcustom malinka-print-info? t "If true malinka will be printing some info messages of the actions it takes"
  :group 'malinka
  :type 'boolean
  :safe #'booleanp
  :package-version '(malinka . "0.3.0"))

(defcustom malinka-print-warning? nil "If true malinka will be printing warning messages in case things go wrong but can be taken care of"
  :group 'malinka
  :type 'boolean
  :safe #'booleanp
  :package-version '(malinka . "0.3.0"))

(defcustom malinka-print-debug? nil "If true malinka will be printing a lot of DEBUG messages. Only useful for debugging"
  :group 'malinka
  :type 'boolean
  :safe #'booleanp
  :package-version '(malinka . "0.3.0"))

(defcustom malinka-print-xdebug? nil "If true malinka will be printing extreme DEBUG messages. Only useful for debugging. Warning: This WILL spam the *Messages* buffer"
  :group 'malinka
  :type 'boolean
  :safe #'booleanp
  :package-version '(malinka . "0.3.0"))

(defcustom malinka-idle-project-check-seconds 5
  "The idle time in seconds to wait until we perform a project change check."
  :group 'malinka
  :type 'number)

(defvar malinka--timer-idle-project-check nil
  "The timer created by `malinka-enable-idle-project-check'.")

;;; --- Global project variables ---

(defvar malinka--current-project-name nil)
(defvar malinka--projects-map
  (make-hash-table :test 'equal)
  "Global hash map containing all projects known to malinka.")

;; --- Helper Macros ---
(defmacro malinka--project-name-get (attribute name)
  "Get the value of ATTRIBUTE for project NAME."
  `(let ((project-map (gethash ,name malinka--projects-map)))
     (,(intern (format "malinka--project-%s" (symbol-name attribute))) project-map)))

(defmacro malinka--error (fmt &rest args)
  "Issue an internal error, by passing FMT and ARGS to (error)."
  `(error (concat "Malinka-error: " ,fmt) ,@args))

(defmacro malinka-user-error (fmt &rest args)
  "Issue a user error, by passing FMT and ARGS to (error)."
  `(user-error (concat "Malinka-user-error: " ,fmt) ,@args))

(defmacro malinka--info (fmt &rest args)
  "Depending on the value of `malinka-print-info?' this macro will print messages by passing FMT and ARGS to message."
  `(when malinka-print-info?
     (message (concat "Malinka-info: " ,fmt) ,@args)))

(defmacro malinka--warning-always (fmt &rest args)
  "This macro will print messages by passing FMT and ARGS to message."
  `(message (concat "Malinka-warning: " ,fmt) ,@args))

(defmacro malinka--warning (fmt &rest args)
  "Depending on the value of `malinka-print-warning?' this macro will print messages by passing FMT and ARGS to message."
  `(when malinka-print-warning?
     (message (concat "Malinka-warning: " ,fmt) ,@args)))

(defmacro malinka--debug (fmt &rest args)
  "Depending on the value of `malinka-print-debug?' this macro will print messages by passing FMT and ARGS to message."
  `(when malinka-print-debug?
     (message (concat "Malinka-debug: " ,fmt) ,@args)))

(defmacro malinka--xdebug (fmt &rest args)
  "Depending on the value of `malinka-print-xdebug?' this macro will print extreme debug messages by passing FMT and ARGS to message."
  `(when malinka-print-xdebug?
     (message (concat "Malinka-xdebug: " ,fmt) ,@args)))

;;; --- Timers ---
(defun malinka-idle-project-check-timer-update (seconds)
  "Set the value in SECONDS after which the idle project check will happen.

If `seconds' is nil or 0 then idle project check is disabled."
  (when malinka--timer-idle-project-check
    (cancel-timer malinka--timer-idle-project-check))
  (setq malinka--timer-idle-project-check
        (and seconds (/= seconds 0)
             (run-with-idle-timer seconds t 'malinka--idle-project-check))))

(defun malinka--idle-project-check ()
  "Run an idle project check for the current malinka project.

Run each time `malinka-idle-project-check-seconds' have passed
 and `malinka-enable-idle-project-check' is non nil."
  (let ((buffer (current-buffer)))
    (when (and
           (malinka--enabled-in-buffer-? buffer)
           (malinka--buffer-is-c? buffer))
      (let* ((filename (buffer-file-name buffer))
             (query (malinka--file-belongs-to-project filename)))
        (when query
          (let ((project  (nth 0 query))
                (fileattr (nth 1 query))
                (inhibit-message t))
            (malinka--rtags-assert-rdm-runs)
            (malinka--async-rtags-is-indexing?
             (lambda (rtags-indexing-p)
               (if rtags-indexing-p
                   ;; Make sure that rtags knows about project.
                   (malinka--try-make-project-known-and-loaded project)
                 ;; if file check results show that the project is not configured
                 ;; nothing is being configured right now
                 ;; and it's not a cmake 2.8.5 project or bear project then configure it
                 ;; TODO: For cmake 2.8.5 we need to somehow parse a files-list
                 ;; TODO: Does added bear and compile-db-cmd type need some processing here?
                 (if (and (eq fileattr 'not-configured)
                          (not (malinka--project-compatible-cmake? project))
                          (not (malinka--project-being-configured? project)))
                     (progn
                       (malinka--info
                        "Project \"%s\" does not seem to be configured. Configuring ..."
                        (malinka--project-name project))
                       (malinka--project-map-update-compiledb project))
                   (malinka--try-make-project-known-and-loaded project))))
             )))))))

(defun malinka--try-make-project-known-and-loaded (project)
  "Asynchronously check if PROJECT is known to Rtags.
If PROJECT is known, check if it is loaded. If it isn't loaded, load it.
If PROJECT is not known to Rtags, let Rtags know about it."
  (malinka--async-rtags-project-known?
   project
   (lambda (project-known-p)
     (if project-known-p
         (progn
           (malinka--debug "Rtags knows about \"%s\"."
                           (malinka--project-name project))
           (malinka--watch-file-for-updates project)
           (malinka--async-rtags-project-loaded?
            project
            (lambda (project-loaded-p)
              (if project-loaded-p
                  (malinka--debug "\"%s\" is loaded by Rtags."
                                  (malinka--project-name project))
                (malinka--info
                 "Rtags knows about \"%s\" but does not have it loaded. Loading it."
                 (malinka--project-name project))
                (malinka--try-select-project project)))))
       (malinka--info
        "Rtags does not know about \"%s\". Informing it."
        (malinka--project-name project))
       (malinka--watch-file-for-updates project)
       (malinka--project-create-or-select-compiledb project)))))

;;; --- Utility functions ---
(defun malinka--file-indexed-by-project (filepath project)
  "Check if FILEPATH is indexed by PROJECT.

This function assumes that we do know that `filepath' belongs to `project'.
If `filepath' is a header file the 'header symbol is returned.
If `project' has a `malinka--file-attributes' for the file it is returned.
If not then the 'not-configured symbol is returned."
  ;; if it's a header we won't have any configured attributes. Return nil
  (if (malinka--cheader? filepath)
      (intern "header")
    ;; else try to find the configured file attributes in the malinka project
    (let ((fileattr
           (-reduce-from
            (lambda (input item)
              (if (not input)
                  (let* ((thisname (malinka--file-attributes-name item))
                         (thisdir (malinka--file-attributes-directory item))
                         (thispath (f-join thisdir thisname)))
                    (when (f-equal? filepath thispath) item))
                ;; else input is an actual value so still return it
                input)) nil (malinka--project-files-list project))))

      (if fileattr fileattr
        ;; else
        (intern "not-configured")))))

(defun malinka--file-find-closest-project (filename found-projects)
  "Find the closest project match for FILENAME from FOUND-PROJECTS.
`found-projects' should be a list of tuples of the form
 (project distance-from-root) or nil.  Where distance-from-root is `filename''s
distance from the project's root directory.

If it does and is configured then return a tuple with the `malinka--project'
 and  the `malinka--file-attributes' item of the file.
If it does but no file attribute can be found then return a tuple with
 `malinka--project' it should belong to and the symbol 'not-configured.
If it does but but is a header file then return a tuple with
 `malinka--project' it should belong to and the symbol 'header
Else return nil."
  (when found-projects
    (let* ((matched-list
            (-reduce-from (lambda (return item)
                            (let ((project (nth 0 item))
                                  (distance-from-root (nth 1 item))
                                  (other-distance (nth 1 return)))
                              (if (< distance-from-root other-distance)
                                  `(,project ,distance-from-root)
                                return)))
                          (nth 0 found-projects) found-projects))
           (matched-project (nth 0 matched-list))
           (index-result (malinka--file-indexed-by-project filename matched-project)))
      (cond
       ((malinka--file-attributes-p index-result)
        `(,matched-project ,index-result))
       ((eq index-result 'header)
        `(,matched-project ,(intern "header")))
       ((eq index-result 'not-configured)
        `(,matched-project ,(intern "not-configured")))
       (t
        (malinka--error "Should never happen.  Unexpected index-result: %s" index-result))))))

(defun malinka--file-belongs-to-project (filename)
  "Determines if the FILENAME belongs to a known malinka project.

If it does and is configured then return a tuple with the `malinka--project'
 and  the `malinka--file-attributes' item of the file.
If it does but no file attribute can be found then return a tuple with
 `malinka--project' it should belong to and the symbol 'not-configured.
If it does but but is a header file then return a tuple with
 `malinka--project' it should belong to and the symbol 'header
Else return nil."
  ;; check which project the file may belong to
  (let ((found-projects '()))
    (maphash (lambda (name project)
               (let ((rootdir (malinka--project-root-directory project)))
                 (when (f-descendant-of? filename rootdir)
                   (let ((distance-from-root
                          (length (f-split (f-relative filename rootdir)))))
                     (add-to-list 'found-projects
                                  `(,project ,distance-from-root))))))
             malinka--projects-map)
    (malinka--file-find-closest-project filename found-projects)))

(defun malinka--process-relative-dirs (input-list project-root)
  "Process the INPUT-LIST and return relative dirs to PROJECT-ROOT."
  (--map-when
   (or (s-starts-with? "../" it) (s-starts-with? "./" it))
   (s-prepend project-root it) input-list))

;;; --- Predicate functions ---
(defun malinka--buffer-is-c? (buffer)
  "Checks if buffer is of C/C++ mode"
  (let ((mode (with-current-buffer buffer major-mode)))
    (or (string-equal mode "c++-mode") (string-equal mode "c-mode"))))

(defun malinka--enabled-in-buffer-? (buffer)
  "Checks if buffer has `malinka-mode' enabled."
  (with-current-buffer buffer
    (bound-and-true-p malinka-mode)))

(defun malinka--string-list-p (obj)
  "Determine if OBJ is a list of strings.
Copied from flycheck.el and not used directly to not introduce dependency"
  (and (listp obj) (-all? #'stringp obj)))

(defun malinka--configure-project-p (name)
  "Check if project NAME should be configured.

Returns true if the project with NAME exists in the project map and
if it has the same name check predicate then it also checks that it's not
the current project."
  (let ((project-map (gethash name malinka--projects-map)))
    (when project-map
      ;; if we need to check for the name, do that, else return true
      (if (cdr (assoc 'same-name-check (cdr project-map)))
          (not (string= malinka--current-project-name name))
        t))))

(defun malinka--project-being-configured? (project)
  "Check if project is currently being configured."
  (let* ((name      (malinka--project-name project))
         (buffname  (format "*malinka-compile-command-%s*" name))
         (buffname2 (format "*malinka-compile-command-%s*" name)))
    (when (or (get-buffer buffname) (get-buffer buffname2)) t)))

(defun malinka--cfile? (file)
  "Return non-nil only if the FILE is related to C/C++."
  (-contains? malinka-supported-file-types (f-ext file)))

(defun malinka--cheader? (file)
  "Return non-nil only if the FILE is a C/C++ header."
  (-contains? malinka-supported-header-types (f-ext file)))

(defun malinka--word-is-compiler? (word)
  "Determine if WORD is a compiler command."
  (--any?
   (or (s-equals? word (nth 0 it))
       (s-equals? word (nth 1 it))
       ;; unfortunately in archlinux `which gcc' returns /usr/sbin but there is a copy in /usr/bin too. Need to cover both
       (s-equals? word (f-join "/" "usr" "bin" (nth 0 it)))
       ;; if the user has ccache, then he probably uses the symlinks
       (s-equals? word (f-join "/" "usr" "lib" "ccache" (nth 0 it))))
   malinka-supported-compilers))

;;; --- Malinka Assertion Functions ---
(defun malinka--assert-directory (dir description &optional user)
  "Assert that DIR is an existing directory with DESCRIPTION.
Otherwise throw an error.  If USER is t then it's a user error, otherwise
 it's an internal error."
  (unless (stringp dir)
    (if user
        (malinka-user-error "Should provide a string for %s" description)
      (malinka--error "Non-string type for %s variable detected" description)))
  (unless (f-directory? dir)
    (if user
        (malinka-user-error
         "Provided string \"%s\" for %s is not a directory" dir description)
      (malinka--error
       "%s variable string \"%s\" is not a directory" description dir))))

(defun malinka--assert-string (var description &optional user)
  "Assert that VAR with DESCRIPTION is a string and throw an error otherwise.
If USER is t then it's a user error, otherwise it's an internal error."
  (unless (stringp var)
    (if user
        (malinka-user-error "Should provide a string for %s" description)
      (malinka--error "Non-string type for %s variable detected" description))))

;;; --- Elisp internal API
(cl-defstruct malinka--project
  name
  root-directory
  build-directory
  compile-db-cmd
  configure-cmd
  compile-cmd
  test-cmd
  run-cmd
  files-list
  watch-file
  watch-file-descriptor
  renew-compile-commands-p)

(cl-defstruct malinka--file-attributes
  name
  directory
  executable
  includes
  defines
  arguments)


(cl-defstruct compile-command directory executable file)


(defun malinka--process-compile-cmd (compile-cmd
                                     configure-cmd
                                     root-directory
                                     build-directory)
  "Process COMPILE-CMD for a project at ROOT-DIRECTORY issued inside BUILD-DIRECTORY."
  (when compile-cmd
    (unless root-directory
      (progn
        (malinka--error
         "Provided compile-cmd \"%s\" for a project without a root directory"
         compile-cmd)
        nil))
    (malinka--assert-string compile-cmd "compile command" t)
    (let ((new-compile-cmd
           (if build-directory
               (if (malinka--build-cmd-is-type? configure-cmd "cmake")
                   (format
                    "if [ ! -d %s ]; then mkdir -p %s && cd %s && %s; else cd %s; fi; %s"
                    build-directory build-directory build-directory configure-cmd
                    build-directory compile-cmd)
                 ;; else
                 (format "cd %s && %s" build-directory compile-cmd))
             ;;else
             compile-cmd)))

      (when (require 'projectile nil 'noerror)
        (puthash root-directory
                 new-compile-cmd
                 projectile-compilation-cmd-map))
      new-compile-cmd)))

(defun malinka--process-test-cmd (test-cmd
                                  root-directory
                                  test-directory)
  "Process TEST-CMD for a project at ROOT-DIRECTORY with a given TEST-DIRECTORY."
  (when test-cmd
    (unless root-directory
      (progn
        (malinka--error
         "Provided test-cmd \"%s\" for a project without a root directory"
         test-cmd)
        nil))
    (malinka--assert-string test-cmd "test command" t)
    (let ((new-test-cmd
           (if test-directory
               (format "cd %s && %s" test-directory test-cmd)
             ;;else
             test-cmd)))
      (when (require 'projectile nil 'noerror)
        (puthash root-directory
                 new-test-cmd
                 projectile-test-cmd-map))
      new-test-cmd)))

(defun malinka--process-run-cmd (run-cmd root-directory)
  "Process RUN-CMD for a project at ROOT-DIRECTORY."
  (when run-cmd
    (unless root-directory
      (progn
        (malinka--error
         "Provided run-cmd \"%s\" for a project without a root directory"
         run-cmd)
        nil))
    (malinka--assert-string run-cmd "run command" t)
    (let ((new-run-cmd
           (format "cd %s && %s" root-directory run-cmd)))
      (when (require 'projectile nil 'noerror)
        (puthash root-directory
                 new-run-cmd
                 projectile-run-cmd-map))
      new-run-cmd)))

(defun* malinka-define-project (&key (name nil)
                                     (root-directory nil)
                                     (build-directory nil)
                                     (test-directory nil)
                                     (configure-cmd nil)
                                     (compile-cmd nil)
                                     (compile-db-cmd nil)
                                     (test-cmd nil)
                                     (run-cmd nil)
                                     (watch-file nil))
  "Define a c/c++ project named NAME.

Provide the ROOT-DIRECTORY of the project.

You should provide a `build-directory' which is where the `configure-cmd' and
the `compile-cmd' is issued from. If it is the same as the root directory then
it can be omitted.

A user has to provide a `compile-cmd' which will specify how the project in question
is going to be compiled. In addition the user should provide a `configure-cmd'
which will allow malinka to parse the compilation output and populate project data.
Most of the times, the `configure-cmd' will be the same as the compile command
only with a dry run option appended. Noteable exception is:
  cmake > 2.85
where all you need to do is provide the usual build configure step.

The `compile-db-cmd' specifies how to create compile_commands.json exactly. If
it is provided, malinka will not parse `configure-cmd' output to get
compile_commands.json.

The `compile-cmd' will be forwarded to projectile
as the project's compile command. Default keybinding: C-c p c

A user can also provide a `test-cmd' which will be forwarded to projectile
as the project's test command. Default keybinding: C-c p P. If a `test-directory'
is given then the test command will be run from there, if not it will be ran from the
root directory.

A project can also have a `run-cmd' which will be forwarded to projectile as the
project's run command. Default keybinding: C-c p u.

Project can be notified to rebuild the compile-commands file when `watch-file' changes.

The project is added to the global `malinka--projects-map'"
  (condition-case-unless-debug nil
      (progn
        (malinka--assert-string name "project name" t)
        (malinka--assert-directory root-directory "project root directory" t)
        ;; unless it's a cmake command, make sure build-dir exists
        (unless (malinka--build-cmd-is-type? configure-cmd "cmake")
          (malinka--assert-directory build-directory "project build directory" t))
        (when configure-cmd (malinka--assert-string configure-cmd "configure command" t))
        (when compile-db-cmd (malinka--assert-string compile-db-cmd "compile-db-cmd command" t))

        (let* ((new-root-directory (f-slash root-directory))
               (new-build-directory (f-slash build-directory))
               (new-test-directory (if test-directory (f-slash test-directory) new-root-directory))
               (new-run-cmd (malinka--process-run-cmd run-cmd new-root-directory))
               (new-compile-cmd (malinka--process-compile-cmd
                                 compile-cmd
                                 configure-cmd
                                 new-root-directory
                                 new-build-directory))
               (new-test-cmd (malinka--process-test-cmd
                              test-cmd
                              new-root-directory
                              new-test-directory)))

          (when (gethash name malinka--projects-map)
            (malinka--warning "Redefining project map for \"%s\"" name))

          (puthash name (make-malinka--project
                         :name name
                         :root-directory new-root-directory
                         :build-directory new-build-directory
                         :configure-cmd configure-cmd
                         :compile-db-cmd compile-db-cmd
                         :compile-cmd new-compile-cmd
                         :test-cmd new-test-cmd
                         :run-cmd run-cmd
                         :files-list '()
                         :watch-file watch-file
                         :watch-file-descriptor nil
                         :renew-compile-commands-p nil)
                   malinka--projects-map)))
    (error
     (malinka--warning-always
      "Could not setup a project due to an error at (malinka-define-project). Skipping that project."))))

(defun malinka--project-add-file (project
                                  name directory
                                  executable defines
                                  includes arguments)
  "Add a new files' attributes to a PROJECT.

NAME is the name of the file without the directory.  DIRECTORY is the directory
the file is located in.

EXECUTABLE is the compiler executable that compiles the file.
DEFINES are the compiler defines.
INCLUDES are the compiler includes.
ARGUMENTS are all the other compiler arguments for the file."
  (let ((files-list (malinka--project-files-list project)))
    ;; TODO Search if file is already in project and issue a warning
    (setf (malinka--project-files-list project)
          (push (make-malinka--file-attributes
                 :name name
                 :directory directory
                 :executable executable
                 :includes includes
                 :defines defines
                 :arguments arguments)
                files-list))))

(defun malinka--list-add-list-or-elem (list elem)
  "Add element to LIST.

ELEM can be either a single element or another list"
  (if (listp elem)
      (append elem list)
    (cons elem list)))

(defun malinka--defined-project-names ()
  "Return all defined project names known to malinka sorted alphabetically."
  ;; if we got emacs version >= 24.4
  (if (require 'subr-x nil 'noerror)
      (hash-table-keys malinka--projects-map)
    ;; else use maphash
    (let ((projects ()))
      (maphash (lambda (key val) (push key projects)) malinka--projects-map)
      (sort projects #'string<))))

(defun malinka--project-detect-root ()
  "Attempts to detect the project root for the current buffer.

Basically uses projectile's root searching utilities.
No need to reinvent the wheel."
  (let* ((dir (file-truename default-directory))
         (found-dir (--reduce-from
                     (or acc (funcall it dir)) nil
                     projectile-project-root-files-functions)))
    (when found-dir (file-truename found-dir))))


(defun malinka--project-detect-name ()
  "Detect the name of the project of the current buffer."
  (let ((dir (malinka--project-detect-root)))
    (when dir
      (malinka--project-name-from-root dir))))

(defun malinka--project-name-from-root (root-dir)
  "Deduce project name from ROOT-DIR."
  (when root-dir
    (file-name-nondirectory (directory-file-name root-dir))))


(defun malinka--build-cmd-is-type? (build-cmd build-type)
  "Defun if a BUILD-CMD string contains BUILD-TYPE."
  (let* ((words (s-split " " build-cmd))
         (first (car words)))
    ;; just check if the first word is BUILD-TYPE
    (when (s-equals? first build-type) t)))

(defun malinka--project-cmake? (project-map)
  "Detect if the malinka PROJECT-MAP contains a cmake build command."
  (malinka--build-cmd-is-type? (malinka--project-configure-cmd project-map) "cmake"))

(defun malinka--have-bear? ()
  "Detect if bear is installed on the system."
  (let ((path (s-split ":" (getenv "PATH"))))
    (malinka--have-bear-impl path)))

(defun malinka--have-bear-impl (path)
  "Detect if bear is in path on the system."
  (if path
      (if (file-executable-p (f-join (car path) "bear")) t
        (malinka--have-bear?-help (cdr path)))
    nil))

(defun malinka--project-compatible-cmake? (project-map)
  "Detect if the malinka PROJECT-MAP contains a cmake build command and if it is of a compatible version.

Compatible means that it's of a big enough version in order to be able to generate a compilation database."
  (when (and
         (malinka--project-cmake? project-map)
         (malinka--cmake-compatible-version?)) t))

(defun malinka--cmake-compatible-version? ()
  "Detect if we have cmake version greater than 2.8.5 to support compilation database creation"
  (let* ((str (shell-command-to-string "cmake --version"))
         (got-cmake (s-match "cmake version \\([0-9]+\\)\.\\([0-9]+\\)\.\\([0-9]+\\)" str)))
    (when got-cmake
      (let ((major-version (string-to-number (nth 1 got-cmake)))
            (minor-version (string-to-number(nth 2 got-cmake)))
            (patch-version (string-to-number(nth 3 got-cmake))))
        (malinka--debug "We got cmake version %s.%s.%s" major-version
                        minor-version
                        patch-version)
        (cond
         ((>= major-version 3) t)
         ((= major-version 2)
          (cond
           ((= minor-version 8)
            (if (>= patch-version 5) t nil))
           ((> minor-version 8) t)
           ((< minor-version 8) nil)))
         (:else ;; major version being 1 means not supported
          nil))))))

(defun malinka--project-contains-compile-db-cmd? (project-map)
  "Detect if the malinka PROJECT-MAP contains non-empty compile-db-cmd."
  (not (s-blank? (malinka--project-compile-db-cmd project-map))))

(defun malinka--build-cmd-for-compiledb (project-map project-type)
  "Generate correct compile-db build cmd for different project type.

Currenttly supported PROJECT-TYPE are: compile-db-cmd, cmake, bear."
  (let* ((build-dir (malinka--project-build-directory project-map))
         (compile-db-cmd (malinka--project-compile-db-cmd project-map))
         (configure-cmd (malinka--project-configure-cmd project-map)))
    (cond ((s-equals? project-type "compile-db-cmd")
           (format "cd %s && %s" build-dir compile-db-cmd))
          ((s-equals? project-type "cmake")
           (format "cd %s && %s -DCMAKE_EXPORT_COMPILE_COMMANDS=ON" build-dir configure-cmd))
          ((s-equals? project-type "bear")
           (format "cd %s && bear -a %s" build-dir configure-cmd))
          (t (malinka--error "Error: %s is not supported. Supported types: compile-db-cmd, cmake, bear",
                             project-type)))))

(defun malinka--create-compiledb (project-map project-type)
  "Create a compilation database for a PROJECT-MAP with provided PROJECT-TYPE."
  (let* ((compile-db-cmd (malinka--project-compile-db-cmd project-map))
         (configure-cmd (malinka--project-configure-cmd project-map))
         (nbuild-cmd (malinka--build-cmd-for-compiledb project-map project-type))
         (project-name (malinka--project-name project-map))
         (process-name  (format "malinka-%s-command-%s" project-type project-name))
         (finish-handle (format "malinka--handle-%s-finish" project-type)))
    (malinka--info "Executing %s command: \"%s\"" project-type nbuild-cmd)
    (malinka--info "Waiting for %s to finish" nbuild-cmd)
    (let ((process (start-process-shell-command process-name
                                                (format "*%s*" process-name)
                                                nbuild-cmd)))
      (set-process-query-on-exit-flag process nil)
      (set-process-sentinel process (intern finish-handle))
      (process-put process 'malinka-project-map project-map))))

(defun malinka--handle-cmake-finish (process event)
  "Handle all events from the project cmake command PROCESS.
EVENT is ignored."
  (when (memq (process-status process) '(signal exit))
    (let* ((project-map       (process-get process 'malinka-project-map))
           (project-name      (malinka--project-name project-map))
           (build-dir         (malinka--project-build-directory project-map))
           (root-dir          (malinka--project-root-directory project-map))
           (buffer            (process-buffer process))
           (compile-database  (f-join build-dir "compile_commands.json"))
           (output       (with-current-buffer buffer
                           (save-excursion
                             (goto-char (point-min))
                             (s-replace "\\\"" "\""
                                        (buffer-string))))))
      (malinka--info "Cmake command for \"%s\" finished. Proceeding to process the output" project-name)
      (kill-buffer buffer)
      ;; for some reason irony seems to stop autodetecting the compile database
      ;; in cmake build dir so let' copy it to the root directory too. Not very elegant solution
      (unless (string-equal root-dir build-dir)
        (let ((root-cdb (f-join root-dir "compile_commands.json")))
          (when (f-exists? root-cdb) (f-delete root-cdb))
          (f-copy compile-database root-cdb)))
      (with-temp-buffer
        (malinka--select-project build-dir)))))

(defun malinka--handle-bear-finish (process event)
  "Handle all events from the project bear command PROCESS.
EVENT is ignored."
  (when (memq (process-status process) '(signal exit))
    (let* ((project-map       (process-get process 'malinka-project-map))
           (project-name      (malinka--project-name project-map))
           (build-dir         (malinka--project-build-directory project-map)))
      (malinka--info "Bear command for \"%s\" finished. Proceeding to process the output" project-name)
      ;; TODO We'd better do a basic check for generated compile_commands.json,
      ;; such like: whether the compile_commands.json is empty, like just
      ;; contains "[ ]". Because bear may failed, which will generate a
      ;; compile_commands.json file with only "[ ]".
      (with-temp-buffer
        (malinka--select-project build-dir)))))

(defun malinka--handle-compile-db-cmd-finish (process event)
  "Handle all events from the project compiledb-cmd command PROCESS.
EVENT is ignored."
  (when (memq (process-status process) '(signal exit))
    (let* ((project-map       (process-get process 'malinka-project-map))
           (project-name      (malinka--project-name project-map))
           (build-dir         (malinka--project-build-directory project-map))
           (nbuild-cmd        (malinka--build-cmd-for-compiledb project-map "compile-db-cmd")))
      (malinka--info "%s command for \"%s\" finished. Proceeding to process the output" nbuild-cmd project-name)
      ;; TODO Do we need to handle irony issue as in malinka--handle-cmake-finish?
      (with-temp-buffer
        (malinka--select-project build-dir)))))

;;; --- Rtags Integration ---

(defun malinka--rtags-assert-rdm-runs ()
  "Assert that the rtags daemon is running."
  ;; if the process has been messed with by outside sources clean it up
  (let ((status (if rtags-rdm-process (process-status rtags-rdm-process) nil)))
    (when (or (not status) (memq status '(exit signal closed failed)))
      (when rtags-rdm-process
        (delete-process rtags-rdm-process))
      (setq rtags-rdm-process nil)
      (when (get-buffer "*rdm*")
        (kill-buffer "*rdm*"))))
  (if (rtags-start-process-unless-running)
      t
    ;; else
    (malinka--error "Could not find rtags daemon in the system")))

(defun malinka--async-rtags-invoke-with (callback &rest args)
  "Invoke rc (rtags executable) with ARGS as arguments.

Returns the output of the command in CALLBACK."
  (when (malinka--rtags-assert-rdm-runs)
    (let* ((rc (rtags-executable-find "rc"))
           (cmd (s-join " " (cons rc args))))
      (when rc
        (async-shell-command-to-string cmd callback)))))

(defun malinka--async-rtags-is-indexing? (callback)
  "Check if rtags is currently indexing anything asynchronously."
  (malinka--async-rtags-invoke-with
   (lambda (result)
     (funcall callback (= (string-to-number result) 1)))
   "--is-indexing"))

(defun malinka--async-rtags-project-known? (project callback)
  "Check if rtags knows about PROJECT."
  (malinka--async-rtags-invoke-with
   (lambda (output)
     (let* ((project-root
             (expand-file-name (malinka--project-root-directory project)))
            (loadedlist (or
                         (s-match project-root output)
                         (s-match (format "%s.*" project-root) output))))
       (funcall callback loadedlist)))
   "-w"))

(defun malinka--async-rtags-project-loaded? (project callback)
  "Check if rtags has loaded PROJECT."
  (malinka--async-rtags-invoke-with
   (lambda (output)
     (let* ((loadedlist (s-match "\\(.*\\) <=" output))
            (dir (when loadedlist (nth 1 loadedlist))))
       (when dir
         (funcall
          callback (f-equal? dir (malinka--project-root-directory project))))))
   "-w"))

(defun async-shell-command-to-string (command callback)
  "Execute shell command COMMAND asynchronously in the background.
Return the temporary output buffer which command is writing to
during execution.
When the command is finished, call CALLBACK with the resulting
output as a string.
Synopsis:
  (async-shell-command-to-string \"echo hello\" (lambda (s) (message \"RETURNED (%s)\" s)))
"
  (let ((output-buffer (generate-new-buffer " *temp*")))
    (set-process-sentinel
     (start-process "Shell" output-buffer shell-file-name shell-command-switch command)
     (lambda (process _signal)
       (when (memq (process-status process) '(exit signal))
         (with-current-buffer output-buffer
           (let ((output-string
                  (buffer-substring-no-properties
                   (point-min)
                   (point-max))))
             (funcall callback output-string)))
         (kill-buffer output-buffer))))
    output-buffer))

;;; --- Functions related to creating the compilation database ---

(defun malinka--json-format-escapes (str)
  "Unescapes/escape special characters before signing off a json encoded STR."
  (s-replace "\\\/" "/" str))

(defun malinka--project-command-form-defines (cpp-defines)
  "Form the CPP-DEFINES part of the build command."
  (s-join " "
          (--map (s-prepend "-D" (malinka--json-format-escapes it)) cpp-defines)))

(defun malinka--project-command-form-includes (include-dirs)
  "Form the INCLUDE-DIRS part of the build command."
  (s-join " "
          (--map (s-prepend "-I" (malinka--json-format-escapes it)) include-dirs)))

(defun malinka--project-form-command (project-map file-attr)
  "Form the compile command for a PROJECT-MAP's FILE-ATTR."

  (let* ((defines       (malinka--file-attributes-defines file-attr))
         (includes      (malinka--file-attributes-includes file-attr))
         (arguments     (malinka--file-attributes-arguments file-attr))
         (executable    (malinka--file-attributes-executable file-attr))
         (filename      (malinka--file-attributes-name file-attr))
         (abs-filename  (f-join (malinka--file-attributes-directory file-attr) filename)))
    (s-concat executable
              " "
              (s-join " " arguments)
              " "
              (malinka--project-command-form-defines defines)
              " "
              (malinka--project-command-form-includes includes)
              " -c -o "
              (s-append ".o " (f-no-ext abs-filename))
              abs-filename)))

(defun malinka--project-create-json-list (project)
  "Create the json association list for this PROJECT."
  (-map
   (lambda (item)
     (let* ((command-string (malinka--project-form-command project item))
            (filename       (malinka--file-attributes-name item))
            (abs-filename   (f-join (malinka--file-attributes-directory item) filename)))
       (json-encode-alist
        `((directory . ,(malinka--project-build-directory project))
          (command . ,command-string)
          (file . ,abs-filename)))))
   (malinka--project-files-list project)))

(defun malinka--project-json-representation (project)
  "Return the json representation of the compilation DB for PROJECT."
  ;; build an association list with all the data for each file
  ;; json-encode does not seem to work for a list of dicts, so we
  ;; have to build it manually
  (let* ((json-list (malinka--project-create-json-list project)))
    (format "[\n%s\n]" (s-join
                        ",\n" (-map 'malinka--json-format-escapes json-list)))))

(defun malinka--compiledb-write (str name)
  "Create and write STR to db file NAME."
  (f-touch name)
  (f-write-text  str 'utf-8 name)
  (malinka--info "malinka: Created %s" name))

(defun malinka--project-compiledb-create (project-map &optional dir)
  "Create a json compilation database for the PROJECT-MAP and writes it to disk.

The default directory to write it is the root directory of the project.
If DIR is provided then its' written there.
For more information on the compilations database please refer here:
http://clang.llvm.org/docs/JSONCompilationDatabase.html"
  (let* ((write-dir (if dir dir (malinka--project-root-directory project-map)))
         (db-file-name (f-join write-dir "compile_commands.json"))
         (json-string (malinka--project-json-representation project-map)))
    (malinka--compiledb-write json-string db-file-name)))

(defvar malinka--renew-compile-commands-file nil
  "When this is t, `malinka--project-create-or-select-compiledb' will rebuild
the compile_commands.json file instead of using the current one.")

(defun malinka--watch-file-for-updates (project)
  "Watch file for changes. If file changes update compile_commands.json file."
  (when (and (fboundp 'file-notify-valid-p)
             (fboundp 'file-notify-add-watch))
    (unless (file-notify-valid-p (malinka--project-watch-file-descriptor project))
      (let ((watch-file (malinka--project-watch-file project)))
        (when watch-file
          (setf (malinka--project-watch-file-descriptor project)
                (file-notify-add-watch
                 (expand-file-name watch-file) '(change)
                 (lambda (_event)
                   (malinka--info
                    "Watch file changed, schedule compile_commands to be rebuilt.")
                   (setf (malinka--project-renew-compile-commands-p project) t)))))))))

(defun malinka--project-create-or-select-compiledb (project)
  "Create or select if existing PROJECT's compilation database."
  (let* ((rootdir    (malinka--project-root-directory project))
         (builddir   (malinka--project-build-directory project))
         (rebuild    (malinka--project-renew-compile-commands-p project))
         (rootcdb    (f-join rootdir "compile_commands.json"))
         (buildcdb   (f-join builddir "compile_commands.json")))
    (cond
     (rebuild
      (setf (malinka--project-renew-compile-commands-p project) nil)
      (malinka--project-map-update-compiledb project))
     ((f-exists? rootcdb)
      (malinka--select-project rootdir))
     ((f-exists? buildcdb)
      (malinka--select-project builddir))
     (:else
      (malinka--project-map-update-compiledb project)))))

(defun malinka--project-map-update-compiledb (project-map)
  "Update the compilation database for PROJECT-MAP.

The control flow is:
1. If compile-db-cmd is given, use it to create compile_commands.json.
2. If it's cmake and the cmake version is compatible then create the
compilation database with cmake.
3. If the user's system has bear, prepend that to the compilation command to
create the database
4. Else execute the build command, parse the output and create the database
manually."
  (cond ((malinka--project-contains-compile-db-cmd? project-map)
         (malinka--create-compiledb project-map "compile-db-cmd"))
        ((malinka--project-compatible-cmake? project-map)
         (malinka--create-compiledb project-map "cmake"))
        ((malinka--have-bear?)
         (malinka--create-compiledb project-map "bear"))
        ;; else execute the compile command and parse the output
        (t (malinka--project-execute-compile-cmd project-map))))

(defun malinka--try-select-project (project)
  "Try to find and select a compilation database in PROJECT."
  (let* ((rootdir    (malinka--project-root-directory project))
         (builddir   (malinka--project-build-directory project))
         (rootcdb    (f-join rootdir "compile_commands.json"))
         (buildcdb   (f-join builddir "compile_commands.json")))
    (cond
     ((f-exists? rootcdb)
      (malinka--select-project rootdir))
     ((f-exists? buildcdb)
      (malinka--select-project builddir))
     (:else
      (malinka--warning "Could not select a compilation database for \"%s\"" (malinka--project-name project))))))

(defun malinka--select-project (directory)
  "Select a malinka project at DIRECTORY.
A compilecommands.json compilation database must already exist there.
This feeds the compilation database to rtags."
  (let ((cdb-file (f-join directory "compile_commands.json")))
    (when (malinka--rtags-assert-rdm-runs)
      (if (f-exists? cdb-file)
          (progn
            (malinka--info "Feeding compile database file: \"%s\" to RTAGS" cdb-file)
            (malinka--async-rtags-invoke-with
             (lambda (_result) t) "-J" directory))
        ;; else
        (malinka-user-error "Could not find a compilation database file in directory %s" directory)))))

(defun malinka--handle-compile-finish (process event)
  "Handle all events from the project compilation PROCESS.

This is basically the starting point of creating the data required by malinka.
EVENT is ignored."
  (when (memq (process-status process) '(signal exit))
    (let* ((project-map  (process-get process 'malinka-project-map))
           (project-name (malinka--project-name project-map))
           (root-dir     (malinka--project-root-directory project-map))
           (buffer       (process-buffer process))
           (output       (with-current-buffer buffer
                           (save-excursion
                             (goto-char (point-min))
                             (s-replace "\\\"" "\""
                                        (buffer-string))))))
      (malinka--info "Compilation for \"%s\" finished. Proceeding to process the output" project-name)
      (kill-buffer buffer)
      (malinka--configoutput-process project-map output)
      (malinka--project-compiledb-create project-map)
      (with-temp-buffer
        (malinka--select-project root-dir)))))



;; --- Minibuffer utilities ---
(defvar malinka--read-project-history nil
  "`completing-read' history of `malinka--read-project'.")

(defun malinka--default-project ()
  "Select a default project if possible.  If not return nil."
  (let ((name (malinka--project-detect-name)))
    (when (-contains? (malinka--defined-project-names) name)
      name)))


;; --- Makefile/Build command reading ---
(defun malinka--configoutput-line-get-file (words index)
  "Return the compiled file from a list of WORDS at the given INDEX.

Note: INDEX can also be nil in which case nil is returned."
  (when index
    (nth index words)))

(defun malinka--includes-make-absolute (includes project)
  "Return the INCLUDES list of PROJECT with all relative paths turned absolute."
  (let ((build-dir (malinka--project-build-directory project)))
    (-map-when 'f-relative (lambda (path) (f-join build-dir path)) includes)))


(defun malinka--sublist-add-if-not-existing (attribute-list ind element)
  "Add to ATTRIBUTE-LIST's IND sublist ELEMENT, if it does not already exist.

Returns the modified list if modified and the same list if not."
  (let ((sublist (nth ind attribute-list)))
    (if (-contains? sublist element)
        attribute-list
      ;;else
      (-replace-at ind (-snoc sublist element) attribute-list))))


(defun malinka--buildcmd-ignore-argument-p (arg)
  "Return true if ARG of the build command should be ignored."
  (or
   (malinka--word-is-compiler? arg)
   (malinka--cfile? arg)
   ;; ignore object files
   (s-ends-with? ".o" arg)
   ;; ignore -o argument
   (equal "-o" arg)
   ;; ignore -c argument
   (equal "-c" arg)))

(defun malinka--configoutput-process-path (filepath build-dir)
  "Figure out the proper directory and name for a given FILEPATH.

Judging from the BUILD-DIR this function figures out
the proper directory and filename for the path.

Returns a tuple in the form of '(DIRECTORY FILENAME)"
  (let ((name (f-filename filepath))
        (dir  (f-dirname filepath)))
    (if (f-relative? filepath)
        (let ((fullpath (f-join build-dir filepath)))
          (unless (f-file? fullpath)
            (malinka--error "Error in compile command detected.  \"%s\" is not a file" fullpath))
          `(,(f-dirname fullpath) ,name))
      ;; else it's absolute
      `(,dir ,name))))

(defun malinka--configoutput-process-word (attributes-list word)
  "Process an ATTRIBUTES-LIST WORD for a project's compile command.

The given ATTRIBUTES-LIST is in the form: '(DEFINES INCLUDES ARGUMENTS)"

  (cond
   ((s-starts-with? "-D" word)
    (let ((cpp-define (s-chop-prefix "-D" word)))
      (malinka--sublist-add-if-not-existing attributes-list 0 cpp-define)))

   ((s-starts-with? "-I" word)
    (let ((include-dir
           (s-chop-prefix "-I" word)))
      (malinka--sublist-add-if-not-existing attributes-list 1 include-dir)))

   ((malinka--buildcmd-ignore-argument-p word)
    attributes-list)

   (:else
    ;; All other choices should be compiler arguments
    (malinka--sublist-add-if-not-existing attributes-list 2 word))))

(defun malinka--configoutput-process-words (words)
  "Process a project's compile command WORDS and return compile attributes.

The returned compile attributes are in the form:
'(DEFINES INCLUDES ARGUMENTS)"
  (-reduce-from 'malinka--configoutput-process-word '(nil nil nil) words))



(defun malinka--configoutput-process-line (project line)
  "If PROJECT's LINE is a compile command, process it."
  (malinka--debug "Analyzing line %s for project %s" line project)
  (let* ((words (s-split " " line))
         ;; check if the command asks us to cd to a directory
         (cd-index (--find-index (s-equals? it "cd") words))
         (cd-dir   (when cd-index (nth (+ cd-index 1) words)))
         ;; find compile command and its starting index
         (compile-start-index (--find-index
                               (malinka--word-is-compiler? it) words))
         (compiler-executable (when compile-start-index
                                (nth compile-start-index words)))
         ;; find compiled file
         (compiled-file-index (when compile-start-index
                                (--find-index (malinka--cfile? it) words)))
         (compiled-file (malinka--configoutput-line-get-file words compiled-file-index)))

    (if compile-start-index
        (progn
          (malinka--xdebug "words: %s" words)
          (malinka--debug "cd directory index: %s" cd-index)
          (malinka--debug "cd directory: %s" cd-dir)
          (malinka--debug "compile-start-index: %s" compile-start-index)
          (malinka--debug "compiler-executable: %s" compiler-executable)
          (malinka--debug "compiled-file-index: %s" compiled-file-index)
          (malinka--debug "compiled-file: %s" compiled-file)
          (if (not compiled-file)
              (progn
                (malinka--warning "Compiled file not found during line analysis")
                project)
            ;; else add new file to files list
            (let* ((build-dir (if cd-dir cd-dir (malinka--project-build-directory project)))
                   (path-list (malinka--configoutput-process-path compiled-file build-dir))
                   (dir       (nth 0 path-list))
                   (file-name (nth 1 path-list))
                   (attributes-list (malinka--configoutput-process-words words))
                   (defines   (nth 0 attributes-list))
                   (includes  (nth 1 attributes-list))
                   (arguments (nth 2 attributes-list))
                   (new-includes (malinka--includes-make-absolute includes project)))
              (malinka--project-add-file project
                                         file-name
                                         dir
                                         compiler-executable
                                         defines
                                         new-includes
                                         arguments)
              project)
            ;; else this line is not a compile command
            project))
      ;;else this line is not a compile command
      project)))

(defun malinka--augment-configure-cmd (configure-cmd build-dir)
  "Augment a CONFIGURE-CMD at the given BUILD-DIR.

If it's a cmake command and it made it this far it means user's cmake is
unable to create the compilation database so add VERBOSE=1 to output the
compilation commands so we have to request cmake to be verbose"
  (if (malinka--build-cmd-is-type? configure-cmd "cmake")
      (format "cd %s && %s && make VERBOSE=1" build-dir configure-cmd)
    (format "cd %s && %s" build-dir configure-cmd)))

(defun malinka--project-execute-compile-cmd (project-map)
  "Execute the `configure-cmd' of PROJECT-MAP with and setup the compile process."
  (let* ((configure-cmd    (malinka--project-configure-cmd project-map))
         (project-name (malinka--project-name project-map))
         (build-dir (malinka--project-build-directory project-map))
         (process-name  (format "malinka-compile-command-%s" project-name))
         (augmented-config-cmd (malinka--augment-configure-cmd configure-cmd build-dir)))
    (malinka--info "Executing configure command: %s" augmented-config-cmd)
    (malinka--info "Waiting for compilation to finish")
    (let ((process (start-process-shell-command process-name
                                                (format "*%s*" process-name)
                                                augmented-config-cmd)))
      (set-process-query-on-exit-flag process nil)
      (set-process-sentinel process 'malinka--handle-compile-finish)
      (process-put process 'malinka-project-map project-map))))

(defun malinka--configoutput-process (project-map output)
  "Process PROJECT-MAP OUTPUT of a configuration phase.

Populates the project's `malinka--file-attributes' list."
  (let ((lines (s-lines output)))
    (-reduce-from
     'malinka--configoutput-process-line
     project-map
     lines)))


(defun malinka--read-project (prompt &optional default)
  "Select a malinka project from minibuffer with PROMPT.

If DEFAULT is provided then this is shown as the default
choice of a prompt.

Returns the project as string or nil if not found."
  (let* ((candidates (malinka--defined-project-names))
         (input (pcase malinka-completion-system
                  (`ido (ido-completing-read prompt candidates nil
                                             'require-match default
                                             'malinka--read-project-history
                                             default))
                  (_ (completing-read prompt candidates nil 'require-match
                                      default 'malinka--read-project-history
                                      default)))))
    (if (string= input "")
        (user-error "No project name entered")
      input)))


;; --- Interactive functions ---

;;;###autoload
(defun malinka-project-configure (name given-root-dir)
  "Configure a project by querying for both NAME and GIVEN-ROOT-DIR.

If multiple projects with the same name in different directories may
exist then it's nice to provide the ROOT-DIR of the project to configure"
  (interactive
   (let* ((project-name
           (malinka--read-project "Project: " (malinka--default-project)))
          (project-root-dir (malinka--project-name-get root-directory project-name))
          (given-dir (if project-root-dir project-root-dir
                       (read-directory-name "Project root: "))))
     (list project-name given-dir)))

  (malinka--info "Configuring project %s" name)

  (let ((root-dir (f-canonical given-root-dir))
        (project-map (gethash name malinka--projects-map)))

    (malinka--debug "Project's root dir is %s" root-dir)
    (unless project-map (malinka-user-error "Could not find project map for %s" name))
    (malinka--project-map-update-compiledb project-map)))

;;;###autoload
(defun malinka-project-select (name given-root-dir)
  "Select a project by querying for both NAME and GIVEN-ROOT-DIR.

If multiple projects with the same name in different directories may
exist then it's nice to provide the ROOT-DIR of the project to configure"
  (interactive
   (let* ((project-name
           (malinka--read-project "Project: " (malinka--default-project)))
          (project-root-dir (malinka--project-name-get root-directory project-name))
          (given-dir (if project-root-dir project-root-dir
                       (read-directory-name "Project root: "))))
     (list project-name given-dir)))

  (malinka--info "Configuring project %s" name)

  (let* ((root-dir (f-canonical given-root-dir))
         (project-map (gethash name malinka--projects-map))
         (project-build-dir (malinka--project-build-directory project-map)))

    (malinka--debug "root dir is %s" root-dir)

    (if project-map
        (malinka--select-project
         (if (malinka--project-compatible-cmake? project-map) project-build-dir root-dir))
      ;; else - given project NAME not found
      (malinka-user-error "Project %s is not known.  Use malinka-define-project to fix this" name))))

;;;###autoload
(define-minor-mode malinka-mode
  "Enables all malinka functionality for the current buffer"
  :lighter malinka-mode-line
  :group 'malinka
  :require 'malinka
  :global nil
  (cond (malinka-mode
         (malinka-idle-project-check-timer-update malinka-idle-project-check-seconds))
        (:else
         (malinka-idle-project-check-timer-update nil))))

;;; --- Interface with flycheck if existing ---
(eval-after-load 'flycheck
  (progn
    (defun malinka-flycheck-clang-interface()
      "Configure flycheck clang's syntax checker according to what we know."
      (with-current-buffer (current-buffer)
        (let ((buffer (current-buffer)))
          (when (malinka--buffer-is-c? buffer)
            (let* ((filename (buffer-file-name buffer))
                   (query (malinka--file-belongs-to-project filename)))
              (when query
                (let ((fileattr (nth 1 query)))
                  (when (malinka--file-attributes-p fileattr)
                    (let ((defines  (malinka--file-attributes-defines fileattr))
                          (includes (malinka--file-attributes-includes fileattr)))
                      (setq flycheck-clang-definitions defines)
                      (setq flycheck-clang-include-path includes))))))))))

    (add-hook 'flycheck-before-syntax-check-hook
              'malinka-flycheck-clang-interface)))

(provide 'malinka)
;;; malinka.el ends here
