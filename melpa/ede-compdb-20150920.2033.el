;;; ede-compdb.el --- Support for compilation database projects in EDE

;; Copyright (C) 2013-2014 Alastair Rankine

;; Author: Alastair Rankine <alastair@girtby.net>
;; Keywords: development ninja build cedet ede
;; Package-Version: 20150920.2033
;; Package-Commit: 23c91082270fcef24ea791b848f1604e36888ff0
;; Package-Requires: ((ede "1.2") (semantic "2.2") (cl-lib "0.4"))

;; This file is not part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; EDE-compdb is a library that enables the Emacs Development Environment (EDE),
;; to be used with a compilation database, as provided by build tools such as
;; CMake or Ninja.  This enables CEDET to be automatically configured for use to
;; support parsing, navigation, completion, and so on.  This is especially useful
;; for C and C++ projects which are otherwise quite tricky to configure for use
;; with CEDET and other libraries.
;; 
;; See the documentation at https://github.com/randomphrase/ede-compdb for
;; quickstart and usage information

;;; Code:

(require 'ede)
(require 'json)
(require 'rx)
(require 'tramp)

(eval-when-compile
  (require 'cl-lib))

(declare-function semantic-gcc-fields "semantic/bovine/gcc")
(declare-function semantic-gcc-query "semantic/bovine/gcc")

;;; Autoload support

;;;###autoload
(defun ede-compdb-load-project (dir)
  "Create an instance of option `ede-compdb-project' for DIR."
  ;; TODO: Other project types keep their own cache of active projects - do we need to as well?
  (ede-compdb-project (file-name-nondirectory (directory-file-name dir))
                      :compdb-file "compile_commands.json"
                      :directory (file-name-as-directory dir)))

;;;###autoload
(defun ede-ninja-load-project (dir)
  "Create an instance of option `ede-ninja-project' for DIR."
  ;; TODO: Other project types keep their own cache of active projects - do we need to as well?
  (ede-ninja-project (file-name-nondirectory (directory-file-name dir))
                     :compdb-file "build.ninja"
                     :directory (file-name-as-directory dir)))
                 
;;;###autoload
(eval-after-load "ede/auto"
  '(ede-add-project-autoload
    (ede-project-autoload "compdb"
                          :name "Compilation DB"
                          :file 'ede-compdb
                          :proj-file "compile_commands.json"
                          :load-type 'ede-compdb-load-project
                          :class-sym 'ede-compdb-project)))

;;;###autoload
(eval-after-load "ede/auto"
  '(ede-add-project-autoload
    (ede-project-autoload "ninja"
                          :name "Ninja"
                          :file 'ede-compdb
                          :proj-file "build.ninja"
                          :load-type 'ede-ninja-load-project
                          :class-sym 'ede-ninja-project)))


;;; Classes:

(defclass compdb-entry (eieio-named)
  (
   (command-line
    :type string :initarg :command-line :protection :protected
    :documentation "The full command line to compile a given file")
   (directory
    :type string :initarg :directory
    :documentation "Directory in which to invoke the compile command")
   (compiler
    :type string :initarg :compiler
    :documentation "The compiler portion of the full command line (may be multi-word)")
   (include-path
    :type list :initarg :include-path :initform '()
    :documentation "List of directories to search for include files")
   (includes
    :type list :initarg :includes :initform '()
    :documentation "List of implicitly included files")
   (defines
    :type list :initarg :defines :initform '()
    :documentation "List of predefined macros")
   (undefines
    :type list :initarg :undefines :initform '()
    :documentation "list of undefined macros")
   (sysroot
    :type string :initarg :sysroot
    :documentation "Sysroot prefix, prepended to all system include paths if set")
   )
  "An entry in the compilation database"
  )

(defclass ede-compdb-project (ede-project)
  (
   (keybindings :initform (("b" . ede-project-configurations-set)
                           ("B" . ede-compdb-set-configuration-directory)))
   (compdb-file
    :initarg :compdb-file :type string
    :documentation "The filename for the compilation database, eg \"compile_commmands.json\". This is evaluated relative to the current configuration directory.")
   (configuration-directories
    :type (or list string) :initarg :configuration-directories
    :documentation "For each configuration, a directory in which to locate the configuration database file. This is evaluated relative to :directory")
   (build-command
    :type string :initarg :build-command :initform "make -k"
    :documentation "A shell command to build the entire project. Invoked from the configuration directory.")

   (compdb
    :initform (make-hash-table :test 'equal)
    :documentation "The compilation database, as a hash keyed on source file")

   (compdb-file-timestamp
    :initform nil :protection :protected
    :documentation "The last mod time for the compdb file")
   (compdb-file-size
    :initform nil :protection :protected
    :documentation "The last measured size of the compdb file")
   )
  )

(defclass ede-ninja-project (ede-compdb-project)
  (
   (build-command
    :type string :initarg :build-command :initform "ninja"
    :documentation "A shell command to build the entire project. Invoked from the configuration directory.")
   (phony-targets
    :type list :initform '()
    :documentation "Phony targets which ninja can build")
   (build-rules
    :type list :initarg :build-rules :initform '("CXX_COMPILER" "C_COMPILER")
    :documentation "Ninja build rules for compiler commands.")
   )
  "Variant of ede-compdb-project, extended to take advantage of the ninja build tool."
)

(defclass ede-compdb-target (ede-target)
  ;; TODO: this is not really in keeping with the ede-target. Currently we create targets for each source file.
  (
   (compilation :type (or null compdb-entry) :initarg :compilation)
   (project :type ede-compdb-project :initarg :project)
   )
  "Represents a target, namely something that can be built"
  )

;;; Hooks:

(defvar ede-compdb-project-rescan-hook nil
  "Hook called by `ede-compdb' for each buffer which is affected when the compilation database is reloaded.")

;;; Compiler support:

(defvar ede-compdb-compiler-cache nil "Cached include paths for each compiler detected.")

(defconst ede-compdb-compiler-search-path-start-rx
  "^#include \\(\"...\"\\|<...>\\) search starts here:$"
  "Regex to identify the start of an include path list in the compiler's -v output.")

(defconst ede-compdb-compiler-search-path-end-rx
  "^End of search list.$"
  "Regex to identify the end of an include path list in the compiler's -v output.")

(defconst ede-compdb-compiler-search-path-dir-rx
  "^ +\\(.+?\\)\\( (framework directory)\\)?$"
  "Regex to identify each include directory in the compiler's -v output.")

(defun ede-compdb-parse-compiler-includes ()
  "Parse the current buffer for system includes."
  
  (while (not (or (eobp) (looking-at ede-compdb-compiler-search-path-start-rx)))
    (forward-line))
      
  (let (result)
    (while (not (or (eobp) (looking-at ede-compdb-compiler-search-path-end-rx)))
      (when (looking-at ede-compdb-compiler-search-path-dir-rx)
        ;; For now ignore framework directories
        (unless (match-string 2)
          (setq result (cons (file-truename (match-string 1)) result))))
      (forward-line))

    (reverse result)))

(defun ede-compdb-get-compiler-includes (comp &optional dir)
  "Return a list of system include paths by querying the compiler COMP in directory DIR."
  (let ((default-directory (or dir default-directory)))
    (with-temp-buffer
      (process-file comp nil t nil "-x" "c++" "-v" "-E" "-")
      (goto-char (point-min))
      (ede-compdb-parse-compiler-includes))))

(defun ede-compdb-compiler-include-path (comp &optional dir)
  "Look up include paths for COMP in directory DIR, and  add to INCLUDE-PATHS."
  (let ((path (cdr (assoc comp ede-compdb-compiler-cache))))
    (unless path
      (setq path (ede-compdb-get-compiler-includes comp dir))
      (add-to-list 'ede-compdb-compiler-cache (cons comp path)))
    path))

(defun ede-compdb-make-path (base-path path)
  "Using BASE-PATH return the path to PATH.
If base-path is accessed using Tramp then the necessary components from
base-path are applied to path making it accessible over Tramp."
  (if (tramp-tramp-file-p base-path)
      (let ((tramp-file (tramp-dissect-file-name base-path)))
        (tramp-make-tramp-file-name
         (tramp-file-name-method tramp-file)
         (tramp-file-name-user tramp-file)
         (tramp-file-name-host tramp-file)
         path))
    path))

;;; compdb-entry methods:

(defmethod get-command-line ((this compdb-entry))
  (parse-command-line-if-needed this)
  (oref this command-line))

(defmethod parse-command-line-if-needed ((this compdb-entry))
  "For performance reasons we delay parsing the compdb command
line until needed. Call this before accessing any slots derived
from the command line (which is most of them!)"
  ;; compiler slot is used to determine whether we need to parse the command line
  (unless (slot-boundp this :compiler)
    (parse-command-line this)))

(defconst ede-compdb-entry-combined-args-rx
  (rx
   string-start
   (submatch
    (or (: "-" (any "DUIF"))
        "-isystem"
        "--sysroot"))
   (optional
    (submatch (+? (not (any "=")))))
   (optional
    "="
    (submatch (1+ any)))
   string-end
   )
  "Regex to identify and parse combined arguments like -DFOO=bar, -I/dir, etc.")

(defconst ede-compdb-entry-sysroot-directory-rx
  (rx
   string-start
   "="
   (optional "/")
   (group (1+ any))
   string-end)
  "Regex to identify directories which are relative to sysroot")

(defmethod parse-command-line ((this compdb-entry))
  "Parse the :command-line slot of THIS to derive :compiler, :include-path, etc."
  (let ((args (split-string (oref this command-line)))
        (seenopt nil)
        (case-fold-search nil))
    ;; parsing code inspired by `command-line'
    (while args
      (let ((argi (pop args)) argval eqval)
        ;; Handle -DFOO, -UFOO, etc arguments
        (when (string-match ede-compdb-entry-combined-args-rx argi)
          (setq argval (match-string 2 argi))
          (setq eqval (match-string 3 argi))
          (setq argi (match-string 1 argi)))
        (when (char-equal ?- (string-to-char argi))
          (setq seenopt t))
        (pcase argi
          (`"-D"
           (object-add-to-list this :defines (cons (or argval (pop args)) eqval) t))
          (`"-U"
           (object-add-to-list this :undefines (or argval (pop args)) t))
          ;; TODO: support gcc notation "=dir" where '=' is the sysroot prefix
          ((or `"-I" `"-F" `"-isystem")
           (object-add-to-list this :include-path (file-name-as-directory (or argval (pop args))) t))
          (`"-include"
           (object-add-to-list this :includes (pop args) t)) ;; append
          (`"-imacros"
           (object-add-to-list this :includes (pop args))) ;; prepend
          ((or `"--sysroot" `"-isysroot")
           (oset this sysroot (file-name-as-directory (or eqval (pop args)))))
          ;; TODO: -nostdinc, -nostdlibinc, -nobuildinic
          )
        (unless seenopt
          (oset this compiler (if (slot-boundp this :compiler) (concat (oref this compiler) " " argi) argi)))
        )
      )

    ;; Add sysroot prefix to include-path
    (when (slot-boundp this :sysroot)
      (let ((rep (concat (regexp-quote (oref this sysroot)) "\\1")))
        (cl-maplist
         (lambda (d) (setcar d (replace-regexp-in-string ede-compdb-entry-sysroot-directory-rx rep (car d))))
         (oref this include-path))))

    ;; Evaluate relative directories in include-path
    (cl-maplist
     (lambda (d) (setcar d (file-name-as-directory (expand-file-name (car d) (oref this directory)))))
     (oref this include-path))
    ))

(defmethod get-defines ((this compdb-entry))
  "Get the preprocessor defines for THIS compdb entry. Returns a list of strings, suitable for use with -D arguments."
  (parse-command-line-if-needed this)
  (mapcar
   ;; Convert ("SYM" . "DEF") into "SYM=DEF"
   (lambda (def) (if (cdr def)
                     (concat (car def) "=" (cdr def))
                   (car def)))
   (oref this defines)))

(defmethod get-include-path ((this compdb-entry) &optional excludecompiler)
  "Get the system include path used by THIS compdb entry.
If EXCLUDECOMPILER is t, we ignore compiler include paths"
  (parse-command-line-if-needed this)
  (append
   (oref this include-path)
   (list (oref this directory))
   (unless excludecompiler
     (let ((path (ede-compdb-compiler-include-path (oref this compiler) (oref this directory))))
       (if (slot-boundp this :sysroot)
           (mapcar (lambda (d) (concat (directory-file-name (oref this sysroot)) d)) path)
         path)))
   ))

(defmethod get-includes ((this compdb-entry))
  "Get the include files used by THIS compdb entry. Relative paths are resolved."
  (parse-command-line-if-needed this)
  (mapcar (lambda (I)
            (expand-file-name I (oref this directory)))
          (oref this includes)))

;;; ede-compdb-target methods:

(defmethod ede-system-include-path ((this ede-compdb-target) &optional excludecompiler)
  "Get the system include path used by project THIS target.
If EXCLUDECOMPILER is t, we ignore compiler include paths"
  (project-rescan-if-needed (oref this project))
  (let ((comp (oref this compilation)))
    (when comp
      (get-include-path comp excludecompiler))))

(defmethod ede-preprocessor-map ((this ede-compdb-target))
  "Get the preprocessor map for target THIS."
  (project-rescan-if-needed (oref this project))
  (let ((comp (oref this compilation)))
    (when comp
      (parse-command-line-if-needed comp)
      ;; Stolen from cpp-root
      (require 'semantic/db)
      (let ((spp (oref comp defines)))
        (mapc
         (lambda (F)
           (let* ((expfile (expand-file-name F (oref comp directory)))
                  (table (when expfile
                           ;; Disable EDE init on preprocessor file load
                           ;; otherwise we recurse, cause errs, etc.
                           (let ((ede-constructing t))
                             (semanticdb-file-table-object expfile))))
                  )
             (cond
              ((not (file-exists-p expfile))
               (message "Cannot find file %s in project." F))
              ((string= expfile (buffer-file-name))
               ;; Don't include this file in it's own spp table.
               )
              ((not table)
               (message "No db table available for %s." expfile))
              (t
               (when (semanticdb-needs-refresh-p table)
                 (semanticdb-refresh-table table))
               (setq spp (append spp (oref table lexical-table)))))))
         (oref (oref this compilation) includes))
        spp))))

(defmethod project-compile-target ((this ede-compdb-target))
  "Compile the current target THIS."
  (project-compile-target (oref this project) this))

(defmethod ede-project-root ((this ede-compdb-target))
  "Returns the root project for target THIS."
  (oref this project))

(defun ede-object-system-include-path ()
  "Return the system include path for the current buffer."
  (when ede-object
    (ede-system-include-path ede-object)))

(defun ede-compdb-flymake-init ()
  "Init function suitable for use with function `flymake-mode'."
  (when (and ede-object (slot-boundp ede-object :compilation) (oref ede-object :compilation))
    (let* ((comp (oref ede-object compilation))
           (args (split-string (get-command-line comp)))
           (temp-file (flymake-init-create-temp-buffer-copy
                       'flymake-create-temp-inplace))
           ret)
      ;; Process args, building up a new list as we go. Each new element is added to the head of the
      ;; list, so we need to reverse it once done
      (while args
        (let ((argi (pop args)))
          (cond
            ;; substitude /dev/null for the output file
           ((equal argi "-o")
            (setq ret (cons "/dev/null" (cons argi ret)))
            (pop args))

            ;; substitute -S for -c (ie just compile, don't assemble)
           ((equal argi "-c")
            (setq ret (cons "-S" ret)))

           ;; Don't do any makefile generation
           ((member argi '("-M" "-MM" "-MMD" "-MG" "-MP" "-MD")))
           ((member argi '("-MF" "-MT" "-MQ"))
            (pop args))

            ;; substitute temp-file for the input file
           ((file-equal-p (expand-file-name argi (oref comp directory)) buffer-file-name)
            (setq ret (cons temp-file ret)))
           (t
            (setq ret (cons argi ret)))
           )))
      (setq ret (reverse ret))
      (list (pop ret) ret (oref comp directory))
      )))


;;; ede-compdb-project methods:

(defmethod current-configuration-directory-path ((this ede-compdb-project) &optional config)
  "Returns the path to the configuration directory for CONFIG, or for :configuration-default if CONFIG not set"
  (let ((dir (nth (cl-position (or config (oref this configuration-default)) (oref this configurations) :test 'equal)
                  (oref this configuration-directories))))
    (and dir (file-name-as-directory (expand-file-name dir (oref this directory))))))

(defmethod current-configuration-directory ((this ede-compdb-project) &optional config)
  "Returns the validated configuration directory for CONFIG, or for :configuration-default if CONFIG not set"
  (let ((dir (current-configuration-directory-path this config)))
    (unless dir
      (error "No directory for configuration %s" config))
    (unless (and (file-exists-p dir) (file-directory-p dir))
      (error "Directory not found for configuration %s: %s" config dir))
    dir))
    
(defmethod set-configuration-directory ((this ede-compdb-project) dir &optional config)
  "Sets the directory for configuration CONFIG to DIR.  The
current configuration directory is used if CONFIG not set."
  (let ((config (or config (oref this configuration-default))))
    (setcar (nthcdr (cl-position config(oref this configurations) :test 'equal)
                    (oref this configuration-directories))
            dir)
    (message "Configuration \"%s\" directory set to: %s" config dir)))

(defmethod current-compdb-path ((this ede-compdb-project))
  "Returns a path to the current compdb file"
  (expand-file-name (oref this compdb-file) (current-configuration-directory-path this)))

(defmethod insert-compdb ((_this ede-compdb-project) compdb-path)
  "Inserts the compilation database into the current buffer"
  (insert-file-contents compdb-path))

(defmethod other-file-list ((_this ede-compdb-project) fname)
  "Returns a list of 'other' files for FNAME."
  ;; Use projectile-get-other-files if defined, or ff-other-file-list (see below) if not
  (or (and (fboundp 'projectile-get-other-files)
           (projectile-project-p)
           (projectile-get-other-files fname (projectile-current-project-files) t))
      (ff-other-file-list)))

(defmethod compdb-entry-for-buffer ((this ede-compdb-project))
  "Returns an instance of ede-compdb-entry suitable for use with
the current buffer. In general, we do a lookup on the current
buffer file in the compdb hashtable. If not present, we look
through the list of other files provided by `ff-all-other-files'
an d pick one that is present in the compdb hashtable."
  (let ((fname (file-truename (buffer-file-name))))
    (or
     ;; If the file is in the compilation database, use that
     (gethash fname (oref this compdb))
     ;; If one the 'other' files are in the compilation database, use the first match
     (let ((others (other-file-list this fname)) found)
       (while (and others (not found))
         (setq found (gethash (file-truename (car others)) (oref this compdb)))
         (setq others (cdr others)))
       found)
     ;; Otherwise search the compilation database for the 'best' match. In this
     ;; case the best match is the one with the longest matching prefix.
     (let (bestmatch bestmatchlen)
       (maphash (lambda (path entry)
                  (let ((matchlen (cl-mismatch path fname)))
                    (when (or (not bestmatchlen) (< bestmatchlen matchlen))
                      (setq bestmatch entry)
                      (setq bestmatchlen matchlen)
                      )))
                (oref this compdb))
       bestmatch)
     )))

(defmethod project-rescan ((this ede-compdb-project))
  "Reload the compilation database."
  (clrhash (oref this compdb))
  (let* ((compdb-path (current-compdb-path this))
         (builddir (current-configuration-directory this))
         (oldprojdir (oref this directory))
         (newprojdir oldprojdir)
         ;; externbuild set for out-of-source builds
         (externbuild (when (not (string-prefix-p oldprojdir builddir)) builddir))
         (json-array-type 'list)
         json-compdb)

    (with-current-buffer (get-buffer-create (format "*compdb:%s*" (oref this name)))
      (erase-buffer)
      (insert-compdb this compdb-path)
      (goto-char (point-min))
      (message "Reading Compilation Database from %s ..." compdb-path)
      (setq json-compdb (json-read)))

    (let ((progress-reporter (make-progress-reporter "Building Compilation Entries..." 0 (length json-compdb)))
          (iter 1))
      
      (dolist (E json-compdb)
        (let* ((directory (file-name-as-directory (ede-compdb-make-path compdb-path (cdr (assoc 'directory E)))))
               (filename (expand-file-name (ede-compdb-make-path compdb-path (cdr (assoc 'file E))) directory))
               (filetruename (file-truename filename))
               (command-line (cdr (assoc 'command E)))
               (compilation
                (compdb-entry filename
                              :command-line command-line
                              :directory directory))
               (srcdir (file-name-as-directory (file-name-directory filename))))

          ;; Add this entry to the database
          (puthash filetruename compilation (oref this compdb))
          
          ;; If we haven't set a project dir, or this entry's directory is a prefix of the current
          ;; project dir, then update the project dir. However, we ignore external build
          ;; directories, because they could be in a completely different part of the filesystem.
          (when (and (or (not externbuild) (not (string-prefix-p externbuild newprojdir)))
                     (or (not newprojdir) (string-prefix-p srcdir newprojdir)))
            (setq newprojdir srcdir))

          (progress-reporter-update progress-reporter iter)
          (setq iter (1+ iter))
          ))
      
      (progress-reporter-done progress-reporter)
      )
            
    (let ((stats (file-attributes compdb-path)))
      (oset this compdb-file-timestamp (nth 5 stats))
      (oset this compdb-file-size (nth 7 stats)))

    ;; Project may have moved to a new directory - reset if so
    (unless (equal oldprojdir newprojdir)
      (oset this :directory newprojdir)
      (when oldprojdir
        ;; TODO: is this all that is required?
        (ede-project-directory-remove-hash oldprojdir)))

    ;; Remove targets without a buffer - we won't be able to update the compilation entry otherwise
    (oset this targets
          (remq nil
                (mapcar (lambda (T) (when (get-file-buffer (expand-file-name (oref T path) oldprojdir)) T))
                        (oref this targets))))

    ;; Update all remaining targets
    (dolist (T (oref this targets))
      
      (with-current-buffer (get-file-buffer (expand-file-name (oref T :path) oldprojdir))

        ;; Update path to target
        (when (and (not (equal oldprojdir newprojdir)) (slot-boundp T 'path))
          (oset T :path (ede-convert-path this (expand-file-name (oref T path) oldprojdir))))

        ;; Update compilation
        (oset T :compilation (compdb-entry-for-buffer this))

        (run-hooks 'ede-compdb-project-rescan-hook)))
    
    ))

(defmethod project-rescan-if-needed ((this ede-compdb-project))
  "Reload the compilation database if the corresponding watch file has changed."
  (let ((stats (file-attributes (current-compdb-path this))))
    ;; Logic stolen from ede/arduino.el
    ;; stats will be null if compdb file is not present
    (when (and stats
               (or (not (oref this compdb-file-timestamp))
                   (/= (or (oref this compdb-file-size) 0) (nth 7 stats))
                   (not (equal (oref this compdb-file-timestamp) (nth 5 stats)))))
      (project-rescan this))))

(defmethod initialize-instance :AFTER ((this ede-compdb-project) &rest _fields)
  (unless (slot-boundp this 'targets)
    (oset this :targets nil))

  (unless (slot-boundp this 'compdb-file)
    (oset this compdb-file (file-name-nondirectory (expand-file-name (oref this file)))))

  (unless (slot-boundp this 'configuration-directories)
    ;; Short-cut: set the current configuration directory by supplying a full pathname to :compdb-file
    (let ((confdir (or (file-name-directory (oref this compdb-file)) ".")))
      (oset this configuration-directories
            (mapcar (lambda (c)
                      (if (string= c (oref this configuration-default))
                          confdir nil))
                  (oref this configurations)))))

  (let ((nconfigs (length (oref this configurations)))
        (ndirs (length (oref this configuration-directories))))
    (unless (= nconfigs ndirs)
      (error "Need %d items in configuration-directories, %d found" nconfigs ndirs)))

  ;; Needed if we've used the above short-cut
  (oset this compdb-file (file-name-nondirectory (oref this compdb-file)))

  (unless (slot-boundp this 'file)
    ;; Set the :file from :directory/:compdb-file
    (oset this file (expand-file-name (oref this compdb-file) (oref this directory))))

  (unless (slot-boundp this 'directory)
    ;; set a starting :directory so that we can evaluate current-configuration-directory
    (oset this directory (file-name-directory (expand-file-name (oref this file)))))

  ;; Rescan if compdb exists
  (if (file-exists-p (current-compdb-path this))
      (project-rescan this)
    (message "Error reading Compilation Database: %s not found" (current-compdb-path this)))
  )

(defmethod ede-find-subproject-for-directory ((proj ede-compdb-project)
                                              _dir)
  "Return PROJ, for handling all subdirs below DIR."
  proj)

(defmethod ede-find-target ((this ede-compdb-project) buffer)
  "Find an EDE target in THIS for BUFFER.
If one doesn't exist, create a new one."
  (let* ((path (ede-convert-path this buffer-file-name))
         (ans (object-assoc path :path (oref this targets))))
    (when (not ans)
      (project-rescan-if-needed this)
      (with-current-buffer buffer
        (setq ans (ede-compdb-target
                   path
                   :path path
                   :compilation (compdb-entry-for-buffer this)
                   :project this)))
      (object-add-to-list this :targets ans)
      )
    ans))

(defmethod project-compile-target ((this ede-compdb-project) target)
  "Build TARGET using :build-command. TARGET may be an instance
of `ede-compdb-target' or a string."
  (project-rescan-if-needed this)
  (let* ((entry (when (and (ede-compdb-target-p target) (slot-boundp target :compilation))
                  (oref target compilation)))
         (cmd (if entry (get-command-line entry)
                (concat (oref this build-command) " "
                        (if (ede-compdb-target-p target) (oref target name) target))))
         (default-directory (if entry (oref entry directory)
                              (current-configuration-directory this))))
    (compile cmd)
    ))

(defmethod project-compile-project ((this ede-compdb-project))
  "Build the project THIS using :build-command"
  (let ((default-directory (current-configuration-directory this)))
    (compile (oref this build-command))
    ))

(defmethod ede-menu-items-build ((_this ede-compdb-project) &optional _current)
  "Override to add a custom target menu item"
  (append (call-next-method)
          (list
           [ "Set Configuration Directory..." ede-compdb-set-configuration-directory ])))

(defun ede-compdb-set-configuration-directory (dir &optional proj config)
  "Set DIR to the configuration directory of PROJ with configuration CONFIG."
  (interactive "DConfiguration Directory: ")
  (set-configuration-directory (or proj (ede-current-project)) dir config))

;;; ede-compdb-project methods:

(defvar ede-ninja-target-regexp "^\\(.+\\): \\(phony\\|CLEAN\\)$"
  "Regexp to identify phony targets in the output of ninja -t targets.")

(defmethod project-rescan ((this ede-ninja-project))
  "Get ninja to describe the set of phony targets, add them to the target list"
  (call-next-method)
  (with-temp-buffer
    (let ((default-directory (current-configuration-directory this)))
      (oset this phony-targets nil)
      (erase-buffer)
      (process-file "ninja" nil t t "-f" (oref this compdb-file) "-t" "targets" "all")
      (let ((progress-reporter (make-progress-reporter "Scanning targets..." (point-min) (point-max))))
        (goto-char 0)
        (while (re-search-forward ede-ninja-target-regexp nil t)
          ;; Don't use object-add-to-list, it is too slow
          (oset this phony-targets (cons (match-string 1) (oref this phony-targets)))
          (progress-reporter-update progress-reporter (point))
          )
        (progress-reporter-done progress-reporter))
      )))

(defmethod insert-compdb ((this ede-ninja-project) compdb-path)
  "Use ninja's compdb tool to insert the compilation database
into the current buffer. COMPDB-PATH represents the current path
to :compdb-file"
  (message "Building compilation database...")
  (let ((default-directory (file-name-directory compdb-path)))
    (apply 'process-file (append `("ninja" nil t nil "-f" ,(oref this compdb-file) "-t" "compdb") (oref this :build-rules)))))

(defmethod project-interactive-select-target ((this ede-ninja-project) prompt)
  "Interactively query for a target. Argument PROMPT is the prompt to use."
  (let ((tname (completing-read prompt (oref this phony-targets) nil nil nil 'ede-ninja-target-history)))
    ;; Create a new target and return it - doesn't matter that it's not in :targets list...
    (ede-compdb-target tname :name tname :project this)))

(provide 'ede-compdb)

;;; Utility functions:

(defun ff-other-file-list ()
  "Return a list of the 'other' files for the current buffer.
Generation of other files uses the same rules and variables as
defined for `ff-other-file-name', but does not stop at the first
file found."
  (require 'find-file)

  (let* ((dirs (ff-list-replace-env-vars
                (if (symbolp ff-search-directories)
                    (symbol-value ff-search-directories)
                  ff-search-directories)))
         (alist (if (symbolp ff-other-file-alist)
                    (symbol-value ff-other-file-alist)
                  ff-other-file-alist))
         (fname (file-name-nondirectory (buffer-file-name)))
         (basename (file-name-sans-extension fname))
         (suffixes (car (assoc-default fname alist 'string-match))))

    (when suffixes
      (when (and (atom suffixes) (fboundp suffixes))
        (setq suffixes (funcall suffixes (buffer-file-name))))
        
      ;; A couple of minor differences from ff-other-file-name:
      ;;
      ;; 1. We search by suffix per directory, not the other way around.
      ;; 2. We don't expand wildcards in the directory list.
      ;;
      ;; The doco for ff-search-directories says it will expand '*' chars in the
      ;; directory list, and gives an example of "/usr/local/*/src/*". But in
      ;; fact the ff-get-file-name function will only handle terminating '*'
      ;; characters. However, expanding wildcards here might lead to an
      ;; explosion of paths, so let's just not...

      (let (ret)
        (dolist (D dirs)
          (dolist (S suffixes)
            ;; Collect in reverse order
            (setq ret (cons (concat (file-name-as-directory D) (concat basename S)) ret))
            ))

        (nreverse ret)
        ))))

;;; ede-compdb.el ends here
