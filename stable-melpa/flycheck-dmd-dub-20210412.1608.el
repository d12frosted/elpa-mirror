;;; flycheck-dmd-dub.el --- Sets flycheck-dmd-include-paths from dub package information

;; Copyright (C) 2014 Atila Neves

;; Author:  Atila Neves <atila.neves@gmail.com>
;; Version: 0.12
;; Package-Version: 20210412.1608
;; Package-Commit: 818bfed45ac8597b6ad568c71eb9428138a125c8
;; Package-Requires: ((flycheck "0.24") (f "0.18.2"))
;; Keywords: languages
;; URL: http://github.com/atilaneves/flycheck-dmd-dub

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package uses "dub describe" to obtain a list of all
;; dependencies of a D dub project and sets the variable flycheck-dmd-include-paths
;; so that flycheck syntax checking knows how to call the compiler
;; and pass it include flags to find the dependencies

;; If it's not clear what any one function does, consult the unit tests
;; in the tests directory.

;; Usage:
;;
;;      (add-hook 'd-mode-hook 'flycheck-dmd-dub-set-include-path)

;;; Code:

(require 'json)
(require 'flycheck)
(require 'f)
(require 'cl-lib)

(defgroup flycheck-dmd-dub nil
  "Sets flycheck dmd compiler flags from dub package information"
  :prefix "flycheck-dmd-dub-"
  :group 'flycheck)

(defcustom
  flycheck-dmd-dub-use-cache-p
  nil
  "Non-nil means that `flycheck-dmd-dub-set-variables' reuses the result of dub describe by using cache file."
  :type 'boolean
  :group 'flycheck-dmd-dub)

(defcustom
  fldd-no-recurse-dir
  nil
  "If set, will stop flycheck-dmd-dub from recursing upwards after finding the dub package root."
  :type 'boolean
  :group 'flycheck-dmd-dub)

(defcustom
  fldd--cache-file
  ".fldd.cache"
  "File to cache the result of dub describe."
  :type 'string
  :safe #'stringp)

(defcustom
  fldd-dub-configuration
  nil
  "If set, will use this dub configuration when calling dub describe (e.g. unittest -> dub describe -c unittest)."
  :group 'flycheck-dmd-dub
  :type 'string
  :safe #'stringp)

(defvar fldd--cache-dir
  (make-temp-file "fldd" 'dir)
  "A temporary directory to store dub describe outputs.")

(defun fldd--json-read-from-string (string)
  "Call `json-parse-string' on STRING if available."
  (if (fboundp 'json-parse-string)      ;introduced at Emacs version 27.1
      (json-parse-string string
                         ;; these are needed to mimic behaviour of `json-read-from-string'
                         :object-type 'alist
                         :null-object nil
                         :false-object :json-false)
    (json-read-from-string string)))


(defun fldd--dub-pkg-version-to-suffix (version)
  "From dub dependency to suffix for the package directory.
VERSION is what follows the colon in a dub.json file such as
'~master' or '>=1.2.3' and returns the suffix to compose the
directory name with."
  (cond
   ((equal version "~master") "-master") ; e.g. "cerealed": "~master" -> cerealed-master
   ((equal (substring version 1 2) "=") (concat "-" (substring version 2))) ;>= or ==
   (t nil)))



(defun fldd--dub-pkgs-dir ()
  "Return the directory where dub packages are found."
  (let ((windub (concat (or (getenv "LOCALAPPDATA") (getenv "APPDATA"))
                        "\\dub\\packages\\")))
    (cond ((eq system-type 'windows-nt) windub)
          ((eq system-type 'cygwin)
           (cygwin-convert-file-name-from-windows windub))
          (t "~/.dub/packages/"))))


(defun fldd--dub-pkg-to-dir-name (pkg)
  "Return the directory name for a dub package dependency.
PKG is a package name such as 'cerealed': '~master'."
  (let ((pkg-name (car pkg))
        (pkg-suffix (fldd--dub-pkg-version-to-suffix (cdr pkg))))
    (concat (fldd--dub-pkgs-dir) pkg-name pkg-suffix)))

(defun fldd--pkg-to-path-key (pkg key)
  "Take a PKG assoc list and return the value for KEY."
  (let ((import-paths (cdr (assq key pkg)))
        (path (cdr (assq 'path pkg))))
    (mapcar (lambda (p)
              (expand-file-name
               p
               (if (eq system-type 'cygwin)
                   (cygwin-convert-file-name-from-windows path)
                 path)))
            import-paths)))


(defun fldd--pkg-to-dir-names (pkg)
  "Return a directory name for the assoc list PKG."
  (fldd--pkg-to-path-key pkg 'importPaths))

(defun fldd--pkg-to-string-import-paths (pkg)
  "Return a directory name for the assoc list PKG."
  (fldd--pkg-to-path-key pkg 'stringImportPaths))


(defun fldd--flatten(x)
  "Flatten sequence X."
  (cond ((null x) nil)
        ((listp x) (append (fldd--flatten (car x)) (fldd--flatten (cdr x))))
        (t (list x))))


(defun fldd--pkgs-to-dir-names (pkgs)
  "Return a list of dir names for assoc list PKGS."
  (delete-dups (fldd--flatten (mapcar #'fldd--pkg-to-dir-names (cdr pkgs)))))

(defun fldd--pkgs-to-string-import-paths (pkgs)
  "Return a list of dir names for assoc list PKGS."
  (delete-dups (fldd--flatten (mapcar #'fldd--pkg-to-string-import-paths (cdr pkgs)))))


(defun fldd--get-dub-package-dirs-json-string (json)
  "Get package directories from dub output.
Return the directories where the packages are for the assoclist
in this JSON string.  Any characters before the first opening
brace are discarded before parsing."
  (let ((data (ignore-errors (fldd--json-read-from-string json))))
    (and data (fldd--get-dub-package-dirs-json data))))

(defun fldd--get-dub-package-dirs-json (json)
  "Get package directories from dub output.
Return the directories where the packages are for the assoclist
in this JSON.  Any characters before the first opening
brace are discarded before parsing."
  (let ((packages (assq 'packages json)))
    (fldd--pkgs-to-dir-names packages)))


(defun fldd--get-dub-package-string-import-paths-json-string (json)
  "Get package directories from dub output.
Return the directories where the packages are for the assoclist
in this JSON string.  Any characters before the first opening
brace are discarded before parsing."
  (let ((data (ignore-errors (fldd--json-read-from-string json))))
    (and data (fldd--get-dub-package-string-import-paths-json data))))

(defun fldd--get-dub-package-string-import-paths-json (json)
  "Get package directories from dub output.
Return the directories where the packages are for the assoclist
in this JSON.  Any characters before the first opening
brace are discarded before parsing."
  (let ((packages (assq 'packages json)))
    (fldd--pkgs-to-string-import-paths packages)))

(defun fldd--get-dub-package-versions-json (json)
  "Get versions from JSON."
  (let* ((packages (cdr (assq 'packages json)))
         (package (elt packages 0)))
    (cdr (assq 'versions package))))

(defun fldd--get-dub-package-dflags-json (json)
  "Get versions from JSON."
  (let* ((packages (cdr (assq 'packages json)))
         (package (elt packages 0)))
    (cdr (assq 'dflags package))))


(defun fldd--json-normalise (output)
  "Normalises OUTPUT to it's valid JSON."
  (substring output (string-match "{" output) (length output)))

(defun fldd--get-project-dir ()
  "Locates the project directory by searching up for either package.json or dub.json."
  (let ((dir (fldd--locate-topmost
              (lambda (dir)
                (or
                 (file-exists-p (expand-file-name "dub.sdl" dir))
                 (file-exists-p (expand-file-name "dub.json" dir))
                 (file-exists-p (expand-file-name "package.json" dir)))))))
    (when dir
      (file-truename dir)
      (let ((project-dir
             (if (eq system-type 'windows-nt)
                 (replace-regexp-in-string ":" "_" dir)
               dir)))
        (file-truename project-dir)))))

(defun fldd--locate-topmost (name)
  "Locate the topmost directory containing NAME.

NAME can be a filename or a predicate, like the `locate-dominating-file' argument."
  (fldd--locate-topmost-impl name default-directory nil))

(defun fldd--locate-topmost-impl (name dir last-found)
  "Locate the topmost NAME from DIR using LAST-FOUND as a 'plan B'.

NAME can be a filename or a predicate, like the `locate-dominating-file' argument."
  (let ((new-dir (locate-dominating-file dir name)))
    (if new-dir
        (if fldd-no-recurse-dir
            new-dir
          (fldd--locate-topmost-impl name (expand-file-name ".." new-dir) new-dir))
      last-found)))


(defun fldd--get-dub-describe-output ()
  "Return the output from dub with package description."
  (let* ((raw-dub-cfgs-cmd "dub --annotate build --print-configs --build=docs")
         (dub-cfgs-cmd (fldd--maybe-add-no-deps raw-dub-cfgs-cmd))
         ;;(configs-output (shell-command-to-string dub-cfgs-cmd)) ;; disabled for now
         (configs-output "") ;; disabled for now due to slowness
         (raw-dub-desc-cmd (if fldd-dub-configuration (concat "dub describe -c " fldd-dub-configuration) "dub describe"))
         (dub-desc-cmd (fldd--maybe-add-no-deps raw-dub-desc-cmd)))
    (fldd--message "Calling dub describe with '%s'" dub-desc-cmd)
    (fldd--json-normalise (shell-command-to-string dub-desc-cmd))))

(defun fldd--maybe-add-no-deps (raw-command)
  "Add --nodeps to RAW-COMMAND if dub.selections.json exists."
  (let* ((dub-selections-json (concat (fldd--get-project-dir) "dub.selections.json"))
         (has-selections (file-exists-p dub-selections-json)))
    (if (not has-selections)
        raw-command
      ;; else
      (let* ((selections (json-read-file dub-selections-json))
             (dependencies (cdr (assoc 'versions selections))))
        (if (fldd--packages-fetched? dependencies)
            (concat raw-command " --nodeps --skip-registry=all")
          raw-command)))))

(defun fldd--message (str &rest vars)
  "Output a message with STR and formatted by VARS."
  (message (apply #'format (concat "flycheck-dmd-dub [%s]: " str) (cons (current-time-string) vars))))


(defun fldd--packages-fetched? (dependencies)
  "If all packages in DEPENDENCIES have been fetched."
  (fldd--all (mapcar #'fldd--dependency-fetched? dependencies)))

(defun fldd--dependency-fetched? (dependency)
  "If DEPENDENCY has already been fetched."
  (let ((package (symbol-name (car dependency)))
        (version (cdr dependency)))
    (if (stringp version)
        (fldd--package-fetched? package version)  ; check dub cache
      ;; else it's (path . <path>)
      (when (stringp (cdr version))
        (file-exists-p (cdr version))))))

(defun fldd--all (lst)
  "If all elements in LST are true."
  (cl-reduce (lambda (a b) (and a b)) lst))

(defun fldd--package-fetched? (package version)
  "If PACKAGE version VERSION has been fetched by dub."
  (file-exists-p (fldd--package-dir-name package version)))

(defun fldd--package-dir-name (package version)
  "Given PACKAGE and VERSION, return the directory name in the dub cache."
  (let* ((version0 (cl-subseq version 0 1))
         (version-from-1 (cl-subseq version 1))
         (real-version (if (equal version0 "~") version-from-1 version)))
    (concat "~/.dub/packages/" package "-" real-version)))

(defun fldd--describe-cache-invalidated? (project-dir cache-file)
  "If the `dub describe' cache is invalidated for PROJECT-DIR given CACHE-FILE."
  (if (not (file-exists-p cache-file))
      t
    (let ((default-directory project-dir))
      (or (fldd--file-exists-and-is-newer? "dub.selections.json" cache-file)
          (fldd--file-exists-and-is-newer? "dub.sdl" cache-file)
          (fldd--file-exists-and-is-newer? "dub.json" cache-file)
          (fldd--file-exists-and-is-newer? "package.json" cache-file)))))

(defun fldd--file-exists-and-is-newer? (file1 file2)
  "If FILE1 exists and is newer than FILE2."
  (and (file-exists-p file1) (fldd--1st-file-newer? file1 file2)))

(defun fldd--1st-file-newer? (file1 file2)
  "If FILE1 is newer than FILE2."
  (let ((timestamp1 (fldd--get-timestamp file1))
        (timestamp2 (fldd--get-timestamp file2)))
    (or (null timestamp2) (time-less-p timestamp2 timestamp1))))

(defun fldd--get-timestamp (file)
  "Return the timestamp of FILE.
If FILE does not exist, return nil."
  (when (file-exists-p file)
    (nth 5 (file-attributes file))))

(defun fldd--set-variables (import-paths string-import-paths versions dflags)
  "Use IMPORT-PATHS, STRING-IMPORT-PATHS, VERSIONS and DFLAGS to flycheck dmd variables."
  (make-local-variable 'flycheck-dmd-include-path)
  (make-local-variable 'flycheck-dmd-args)
  (setq flycheck-dmd-include-path import-paths)
  (let* ((flags)
         (flags (append (mapcar (lambda (x) (concat "-version=" x)) versions) flags))
         (flags (append dflags flags))
         (flags (append (mapcar (lambda (x) (concat "-J" x)) string-import-paths) flags))
         (flags (fldd--maybe-add-flag flags "-unittest"))
         (flags  (fldd--maybe-add-flag flags "-w")))
    (setq flycheck-dmd-args flags)))

(defun fldd--maybe-add-flag (flags flag)
  "Concat FLAGS and FLAG if the latter is not already present."
  (if (member flag flags) flags (cons flag flags)))

(defun fldd--cache-is-updated-p ()
  "Return non-nil if `fldd--cache-file' is up-to-date."
  (let ((conf-timestamp (fldd--get-timestamp "dub.selections.json"))
        (cache-timestamp (fldd--get-timestamp fldd--cache-file)))
    (and conf-timestamp cache-timestamp
         (time-less-p conf-timestamp cache-timestamp))))


;;;###autoload
(defun flycheck-dmd-dub-set-variables ()
  "Set all flycheck-dmd variables.
It also outputs the values of `import-paths' and `string-import-paths'
to `fldd--cache-file' to reuse the result of dub describe."
  (interactive)
  (let ((project-dir (fldd--get-project-dir)))
    (when project-dir
      (let ((default-directory project-dir))
        (if (and flycheck-dmd-dub-use-cache-p (fldd--cache-is-updated-p))
            (fldd--set-variables-from-cache project-dir)
          ;; else
          (fldd--set-variables-from-dub-describe project-dir))))))

(defun fldd--set-variables-from-dub-describe (project-dir)
  "Set variables form the output of running `dub describe' in PROJECT-DIR."
  (fldd--message "Setting variables from dub describe")
  (fldd--set-variables-from-json-string (fldd--describe-json-for project-dir)))

(defun fldd--describe-json-for (project-dir)
  "Get dub describe JSON for PROJECT-DIR."
  (let* ((default-directory project-dir)
         (cache-file-name (fldd--dub-describe-cache-file-name))
         (cache-file-dir (file-name-directory cache-file-name)))
    (if (fldd--describe-cache-invalidated? project-dir cache-file-name)
        (progn
          (fldd--message "Cache invalidated, running dub describe.")
          (let ((dub-desc-output (fldd--get-dub-describe-output)))
            (fldd--message "Caching result of dub describe")
            (when (not (file-exists-p cache-file-dir))
              (fldd--message "Creating directory %s" cache-file-dir)
              (make-directory cache-file-dir 't))
            (f-write dub-desc-output 'utf-8 cache-file-name)
            dub-desc-output))
      (f-read cache-file-name))))

(defun fldd--dub-describe-cache-file-name ()
  "The file name to cache the describe output for PROJECT-DIR."
  (concat
   fldd--cache-dir
   (fldd--get-project-dir)
   (if fldd-dub-configuration (file-name-as-directory fldd-dub-configuration) "")
   "dub_describe.json"))

(defun fldd--set-variables-from-json-string (json-string)
  "Parse the output of running of the `dub describe' JSON-STRING."
  (fldd--message "Setting variables from JSON string")
  (let* ((json (fldd--json-read-from-string json-string))
         (import-paths (fldd--get-dub-package-dirs-json json))
         (string-import-paths (fldd--get-dub-package-string-import-paths-json json))
         (versions (fldd--get-dub-package-versions-json json))
         (dflags (fldd--get-dub-package-dflags-json json)))
    (fldd--set-variables import-paths string-import-paths versions dflags)
    (when flycheck-dmd-dub-use-cache-p
      (let ((cache-text (with-output-to-string
                          (print `((import-paths . ,import-paths)
                                   (string-import-paths . ,string-import-paths))))))
        (f-write cache-text 'utf-8 fldd--cache-file)))))

(defun fldd--set-variables-from-cache (project-dir)
  "Set flycheck variables from the cache for PROJECT-DIR."
  (fldd--message "Setting variables from cache")
  (let* ((alist (read (f-read fldd--cache-file)))
         (import-paths (cdr (assq 'import-paths alist)))
         (string-import-paths (cdr (assq 'string-import-paths alist)))
         (versions)
         (dflags))
    (fldd--set-variables import-paths string-import-paths nil nil)))

(defun flycheck-dmd-dub-add-version (version)
  "Add VERSION to the list of dmd arguments when calling flycheck."
  (add-to-list 'flycheck-dmd-args (concat "-version=" version)))

(defun fldd-add-version (version)
  "Add VERSION to the list of dmd arguments when calling flycheck."
  (flycheck-dmd-dub-add-version version))

;;;###autoload
(defun fldd-run ()
  "Set all flycheck-dmd variables.
It also outputs the values of `import-paths' and `string-import-paths'
to `fldd--cache-file' to reuse the result of dub describe."
  (interactive)
  (flycheck-dmd-dub-set-variables))



;; FIXME: DELETE
(defun fldd--get-dub-package-dirs ()
  "Get package directories."
  (fldd--get-dub-package-dirs-json-string (fldd--describe-json-for (fldd--get-project-dir))))


(provide 'flycheck-dmd-dub)
;;; flycheck-dmd-dub ends here

;;; flycheck-dmd-dub.el ends here
