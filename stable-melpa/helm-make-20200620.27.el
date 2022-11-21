;;; helm-make.el --- Select a Makefile target with helm

;; Copyright (C) 2014-2019 Oleh Krehel

;; Author: Oleh Krehel <ohwoeowho@gmail.com>
;; URL: https://github.com/abo-abo/helm-make
;; Package-Version: 20200620.27
;; Package-Commit: ebd71e85046d59b37f6a96535e01993b6962c559
;; Version: 0.2.0
;; Keywords: makefile

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; A call to `helm-make' will give you a `helm' selection of this directory
;; Makefile's targets.  Selecting a target will call `compile' on it.

;;; Code:

(require 'subr-x)
(require 'cl-lib)
(eval-when-compile
  (require 'helm-source nil t))

(declare-function helm "ext:helm")
(declare-function helm-marked-candidates "ext:helm")
(declare-function helm-build-sync-source "ext:helm")
(declare-function ivy-read "ext:ivy")
(declare-function projectile-project-root "ext:projectile")

(defgroup helm-make nil
  "Select a Makefile target with helm."
  :group 'convenience)

(defcustom helm-make-do-save nil
  "If t, save all open buffers visiting files from Makefile's directory."
  :type 'boolean
  :group 'helm-make)

(defcustom helm-make-build-dir ""
  "Specify a build directory for an out of source build.
The path should be relative to the project root.

When non-nil `helm-make-projectile' will first look in that directory for a
makefile."
  :type '(string)
  :group 'helm-make)
(make-variable-buffer-local 'helm-make-build-dir)

(defcustom helm-make-sort-targets nil
  "Whether targets shall be sorted.
If t, targets will be sorted as a final step before calling the
completion method.

HINT: If you are facing performance problems set this to nil.
This might be the case, if there are thousand of targets."
  :type 'boolean
  :group 'helm-make)

(defcustom helm-make-cache-targets nil
  "Whether to cache the targets or not.

If t, cache targets of Makefile. If `helm-make' or `helm-make-projectile'
gets called for the same Makefile again, and the Makefile hasn't changed
meanwhile, i.e. the modification time is `equal' to the cached one, reuse
the cached targets, instead of recomputing them. If nil do nothing.

You can reset the cache by calling `helm-make-reset-db'."
  :type 'boolean
  :group 'helm-make)

(defcustom helm-make-executable "make"
  "Store the name of make executable."
  :type 'string
  :group 'helm-make)

(defcustom helm-make-ninja-executable "ninja"
  "Store the name of ninja executable."
  :type 'string
  :group 'helm-make)

(defcustom helm-make-niceness 0
  "When non-zero, run make jobs at this niceness level."
  :type 'integer
  :group 'helm-make)

(defcustom helm-make-arguments "-j%d"
  "Pass these arguments to `helm-make-executable' or
`helm-make-ninja-executable'. If `%d' is included, it will be substituted
 with the universal argument."
  :type 'string
  :group 'helm-make)

(defcustom helm-make-require-match t
  "When non-nil, don't allow selecting a target that's not on the list."
  :type 'boolean)

(defcustom helm-make-named-buffer nil
  "When non-nil, name compilation buffer based on make target."
  :type 'boolean)

(defcustom helm-make-comint nil
  "When non-nil, run helm-make in Comint mode instead of Compilation mode."
  :type 'boolean)

(defcustom helm-make-fuzzy-matching nil
  "When non-nil, enable fuzzy matching in helm make target(s) buffer."
  :type 'boolean)

(defcustom helm-make-completion-method 'helm
  "Method to select a candidate from a list of strings."
  :type '(choice
          (const :tag "Helm" helm)
          (const :tag "Ido" ido)
          (const :tag "Ivy" ivy)))

(defcustom helm-make-nproc 1
  "Use that many processing units to compile the project.

If `0', automatically retrieve available number of processing units
using `helm--make-get-nproc'.

Regardless of the value of this variable, it can be bypassed by
passing an universal prefix to `helm-make' or `helm-make-projectile'."
  :type 'integer)

(defvar helm-make-command nil
  "Store the make command.")

(defvar helm-make-target-history nil
  "Holds the recently used targets.")

(defvar helm-make-makefile-names '("Makefile" "makefile" "GNUmakefile")
  "List of Makefile names which make recognizes.
An exception is \"GNUmakefile\", only GNU make understands it.")

(defvar helm-make-ninja-filename "build.ninja"
  "Ninja build filename which ninja recognizes.")

(defun helm--make-get-nproc ()
  "Retrieve available number of processing units on this machine.

If it fails to do so, `1' will be returned.
"
  (cond
    ((member system-type '(gnu gnu/linux gnu/kfreebsd cygwin))
     (if (executable-find "nproc")
         (string-to-number (string-trim (shell-command-to-string "nproc")))
       (warn "Can not retrieve available number of processing units, \"nproc\" not found")
       1))
    ;; What about the other systems '(darwin windows-nt aix berkeley-unix hpux usg-unix-v)?
    (t
     (warn "Retrieving available number of processing units not implemented for system-type %s" system-type)
     1)))

(defvar helm-make--last-item nil)

(defun helm--make-action (target)
  "Make TARGET."
  (setq helm-make--last-item target)
  (let* ((targets (and (eq helm-make-completion-method 'helm)
                       (or (> (length (helm-marked-candidates)) 1)
                           ;; Give single marked candidate precedence over current selection.
                           (unless (equal (car (helm-marked-candidates)) target)
                             (setq target (car (helm-marked-candidates))) nil))
                       (mapconcat 'identity (helm-marked-candidates) " ")))
         (make-command (format helm-make-command (or targets target)))
         (compile-buffer (compile make-command helm-make-comint)))
    (when helm-make-named-buffer
      (helm--make-rename-buffer compile-buffer (or targets target)))))

(defun helm--make-rename-buffer (buffer target)
  "Rename the compilation BUFFER based on the make TARGET."
  (let ((buffer-name (format "*compilation in %s (%s)*"
                             (abbreviate-file-name default-directory)
                             target)))
    (when (get-buffer buffer-name)
      (kill-buffer buffer-name))
    (with-current-buffer buffer
      (rename-buffer buffer-name))))

(defvar helm--make-build-system nil
  "Will be 'ninja if the file name is `build.ninja',
and if the file exists 'make otherwise.")

(defun helm--make-construct-command (arg file)
  "Construct the `helm-make-command'.

ARG should be universal prefix value passed to `helm-make' or
`helm-make-projectile', and file is the path to the Makefile or the
ninja.build file."
  (format (concat "%s%s -C %s " helm-make-arguments " %%s")
          (if (= helm-make-niceness 0)
              ""
            (format "nice -n %d " helm-make-niceness))
          (cond
            ((equal helm--make-build-system 'ninja)
             helm-make-ninja-executable)
            (t
             helm-make-executable))
          (replace-regexp-in-string
           "^/\\(scp\\|ssh\\).+?:.+?:" ""
           (shell-quote-argument (file-name-directory file)))
          (let ((jobs (abs (if arg (prefix-numeric-value arg)
                             (if (= helm-make-nproc 0) (helm--make-get-nproc)
                               helm-make-nproc)))))
            (if (> jobs 0) jobs 1))))

(defcustom helm-make-directory-functions-list
  '(helm-make-current-directory helm-make-project-directory helm-make-dominating-directory)
  "Functions that return Makefile's directory, sorted by priority."
  :type
  '(repeat
    (choice
     (const :tag "Default directory" helm-make-current-directory)
     (const :tag "Project directory" helm-make-project-directory)
     (const :tag "Dominating directory with makefile" helm-make-dominating-directory)
     (function :tag "Custom function"))))

;;;###autoload
(defun helm-make (&optional arg)
  "Call \"make -j ARG target\". Target is selected with completion."
  (interactive "P")
  (let ((makefile nil))
    (cl-find-if
     (lambda (fn) (setq makefile (helm--make-makefile-exists (funcall fn))))
     helm-make-directory-functions-list)
    (if (not makefile)
        (error "No build file in %s" default-directory)
      (setq helm-make-command (helm--make-construct-command arg makefile))
      (helm--make makefile))))

(defconst helm--make-ninja-target-regexp "^\\(.+\\): "
  "Regexp to identify targets in the output of \"ninja -t targets\".")

(defun helm--make-target-list-ninja (makefile)
  "Return the target list for MAKEFILE by parsing the output of \"ninja -t targets\"."
  (let ((default-directory (file-name-directory (expand-file-name makefile)))
        (ninja-exe helm-make-ninja-executable) ; take a copy in case buffer-local
        targets)
    (with-temp-buffer
      (call-process ninja-exe nil t t "-f" (file-name-nondirectory makefile)
                    "-t" "targets" "all")
      (goto-char (point-min))
      (while (re-search-forward helm--make-ninja-target-regexp nil t)
        (push (match-string 1) targets))
      targets)))

(defun helm--make-target-list-qp (makefile)
  "Return the target list for MAKEFILE by parsing the output of \"make -nqp\"."
  (let ((default-directory (file-name-directory
                            (expand-file-name makefile)))
        targets target)
    (with-temp-buffer
      (insert
       (shell-command-to-string
        (format "make -f %s -nqp __BASH_MAKE_COMPLETION__=1 .DEFAULT 2>/dev/null"
                makefile)))
      (goto-char (point-min))
      (unless (re-search-forward "^# Files" nil t)
        (error "Unexpected \"make -nqp\" output"))
      (while (re-search-forward "^\\([^%$:#\n\t ]+\\):\\([^=]\\|$\\)" nil t)
        (setq target (match-string 1))
        (unless (or (save-excursion
		      (goto-char (match-beginning 0))
		      (forward-line -1)
		      (looking-at "^# Not a target:"))
                    (string-match "^\\([/a-zA-Z0-9_. -]+/\\)?\\." target))
          (push target targets))))
    targets))

(defun helm--make-target-list-default (makefile)
  "Return the target list for MAKEFILE by parsing it."
  (let (targets)
    (with-temp-buffer
      (insert-file-contents makefile)
      (goto-char (point-min))
      (while (re-search-forward "^\\([^: \n]+\\) *:\\(?: \\|$\\)" nil t)
        (let ((str (match-string 1)))
          (unless (string-match "^\\." str)
            (push str targets)))))
    (nreverse targets)))

(defcustom helm-make-list-target-method 'default
  "Method of obtaining the list of Makefile targets.

For ninja build files there exists only one method of obtaining the list of
targets, and hence no `defcustom'."
  :type '(choice
          (const :tag "Default" default)
          (const :tag "make -qp" qp)))

(defun helm--make-makefile-exists (base-dir &optional dir-list)
  "Check if one of `helm-make-makefile-names' and `helm-make-ninja-filename'
 exist in BASE-DIR.

Returns the absolute filename to the Makefile, if one exists,
otherwise nil.

If DIR-LIST is non-nil, also search for `helm-make-makefile-names' and
`helm-make-ninja-filename'."
  (let* ((default-directory (file-truename base-dir))
         (makefiles
          (progn
            (unless (and dir-list (listp dir-list))
              (setq dir-list (list "")))
            (let (result)
              (dolist (dir dir-list)
                (dolist (makefile `(,@helm-make-makefile-names ,helm-make-ninja-filename))
                  (push (expand-file-name makefile dir) result)))
              (reverse result))))
         (makefile (cl-find-if 'file-exists-p makefiles)))
    (when makefile
      (cond
        ((string-match "build\.ninja$" makefile)
         (setq helm--make-build-system 'ninja))
        (t
         (setq helm--make-build-system 'make))))
    makefile))

(defvar helm-make-db (make-hash-table :test 'equal)
  "An alist of Makefile and corresponding targets.")

(cl-defstruct helm-make-dbfile
  targets
  modtime
  sorted)

(defun helm--make-cached-targets (makefile)
  "Return cached targets of MAKEFILE.

If there are no cached targets for MAKEFILE, the MAKEFILE modification
time has changed, or `helm-make-cache-targets' is nil, parse the MAKEFILE,
and cache targets of MAKEFILE, if `helm-make-cache-targets' is t."
  (let* ((att (file-attributes makefile 'integer))
         (modtime (if att (nth 5 att) nil))
         (entry (gethash makefile helm-make-db nil))
         (new-entry (make-helm-make-dbfile))
         (targets (cond
                    ((and helm-make-cache-targets
                          entry
                          (equal modtime (helm-make-dbfile-modtime entry))
                          (helm-make-dbfile-targets entry))
                     (helm-make-dbfile-targets entry))
                    (t
                     (delete-dups
                      (cond
                        ((equal helm--make-build-system 'ninja)
                         (helm--make-target-list-ninja makefile))
                        ((equal helm-make-list-target-method 'qp)
                         (helm--make-target-list-qp makefile))
                        (t
                         (helm--make-target-list-default makefile))))))))
    (when helm-make-sort-targets
      (unless (and helm-make-cache-targets
                   entry
                   (helm-make-dbfile-sorted entry))
        (setq targets (sort targets 'string<)))
      (setf (helm-make-dbfile-sorted new-entry) t))

    (when helm-make-cache-targets
      (setf (helm-make-dbfile-targets new-entry) targets
            (helm-make-dbfile-modtime new-entry) modtime)
      (puthash makefile new-entry helm-make-db))
    targets))

;;;###autoload
(defun helm-make-reset-cache ()
  "Reset cache, see `helm-make-cache-targets'."
  (interactive)
  (clrhash helm-make-db))

(defun helm--make (makefile)
  "Call make for MAKEFILE."
  (when helm-make-do-save
    (let* ((regex (format "^%s" default-directory))
           (buffers
            (cl-remove-if-not
             (lambda (b)
               (let ((name (buffer-file-name b)))
                 (and name
                      (string-match regex (expand-file-name name)))))
             (buffer-list))))
      (mapc
       (lambda (b)
         (with-current-buffer b
           (save-buffer)))
       buffers)))
  (let ((targets (helm--make-cached-targets makefile))
        (default-directory (file-name-directory makefile)))
    (delete-dups helm-make-target-history)
    (cl-case helm-make-completion-method
      (helm
       (require 'helm)
       (helm :sources (helm-build-sync-source "Targets"
                        :header-name (lambda (name) (format "%s (%s):" name makefile))
                        :candidates 'targets
                        :fuzzy-match helm-make-fuzzy-matching
                        :action 'helm--make-action)
             :history 'helm-make-target-history
             :preselect helm-make--last-item))
      (ivy
       (unless (window-minibuffer-p)
         (ivy-read "Target: "
                   targets
                   :history 'helm-make-target-history
                   :preselect (car helm-make-target-history)
                   :action 'helm--make-action
                   :require-match helm-make-require-match)))
      (ido
       (let ((target (ido-completing-read
                      "Target: " targets
                      nil nil nil
                      'helm-make-target-history)))
         (when target
           (helm--make-action target)))))))

;;;###autoload
(defun helm-make-projectile (&optional arg)
  "Call `helm-make' for `projectile-project-root'.
ARG specifies the number of cores.

By default `helm-make-projectile' will look in `projectile-project-root'
followed by `projectile-project-root'/build, for a makefile.

You can specify an additional directory to search for a makefile by
setting the buffer local variable `helm-make-build-dir'."
  (interactive "P")
  (require 'projectile)
  (let ((makefile (helm--make-makefile-exists
                   (projectile-project-root)
                   (if (and (stringp helm-make-build-dir)
                            (not (string-match-p "\\`[ \t\n\r]*\\'" helm-make-build-dir)))
                       `(,helm-make-build-dir "" "build")
                     `(,@helm-make-build-dir "" "build")))))
    (if (not makefile)
        (error "No build file found for project %s" (projectile-project-root))
      (setq helm-make-command (helm--make-construct-command arg makefile))
      (helm--make makefile))))

(defvar project-roots)

(defun helm-make-project-directory ()
  "Return the current project root directory if found."
  (if (and (fboundp 'project-current) (project-current))
      (car (project-roots (project-current)))
    nil))

(defun helm-make-current-directory()
  "Return the current directory."
  default-directory)

(defun helm-make-dominating-directory ()
  "Return the dominating directory that contains a Makefile if found"
  (locate-dominating-file default-directory 'helm--make-makefile-exists))

(provide 'helm-make)

;;; helm-make.el ends here
