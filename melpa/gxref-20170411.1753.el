;;; gxref.el --- xref backend using GNU Global. -*- lexical-binding: t; -*-

;; Copyright (C) 2016 Dedi Hirschfeld

;; Author: Dedi Hirschfeld
;; URL: https://github.com/dedi/gxref
;; Package-Version: 20170411.1753
;; Package-Commit: 380b02c3c3c2586c828456716eef6a6392bb043b
;; Keywords: xref, global, tools
;; Version: 0.2 alpha
;; Package-Requires: ((emacs "25"))

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

;; A pretty simple (but, at least for me, effective) backend for Emacs 25
;; xref library using GNU Global.

;; ## Overview

;; Emacs 25 introduces a new (and experimental) `xref' package.  The
;; package aims to provide a standardized access to cross-referencing
;; operations, while allowing the implementation of different back-ends
;; which implement that cross-referencing using different mechanisms.  The
;; gxref package implements an xref backend using the GNU Global tool.


;; ## Prerequisites:

;; * GNU Global.
;; * Emacs version >= 25.1

;; ## Installation

;; Gxref is now available on MELPA.  Once you
;; get [MELPA](https://melpa.org/#/getting-started) set up, you can
;; install gxref by typing

;; ```
;; M-x package-install RET gxref RET
;; ```

;; See [here][Installation] if you prefer to install manually.


;; ## <a name="setup"></a>Setting up.

;; Add something like the following to your init.el file:

;; ```elisp
;; (add-to-list 'xref-backend-functions 'gxref-xref-backend)
;; ```

;; This will add gxref as a backend for xref functions.  The backend
;; will be used whenever a GNU Global project is detected.  That is,
;; whenever a GTAGS database file exists in the current directory or
;; above it, or an explicit project [was set](#setting_project).


;; ## <a name="usage"></a>Usage

;; ### Using gxref to locate tags

;; After [setup](#setup), invoking any of the xref functions will use
;; GNU Global whenever a GTAGS file can be located.  By default, xref
;; functions are bound as follows:


;; | Function              | Binding  |
;; |:---------------------:|:--------:|
;; | xref-find-definitions | M-.      |
;; | xref-find-references  | M-?      |
;; | xref-find-apropos     | C-M-.    |
;; | xref-pop-marker-stack | M-,      |

;; If a GTAGS file can't be located for the current buffer, xref will
;; fall back to whatever other backends it's configured to try.

;; ### <a name="setting_project"></a>Project root directory.

;; By default, gxref searches for the root directory of the project,
;; and the GTAGS database file, by looking in the current directory,
;; and then upwards through parent directories until the database is located.
;; If you prefer, you can explicitly set the project directory.
;; This can be done either interactively, by typing `M-x
;; gxref-set-project-dir RET`, or by setting the variable
;; `gxref-gtags-root-dir` to the GTAGS directory.  You can also set up
;; `gxref-gtags-root-dir` as a file-local or a dir-local variable.

;; ### Configuring gxref

;; gxref can be customized in several ways.  use
;; `M-x customize-group RET gxref RET` to start.

;; Additionally, the following variables can be used to affect the execution
;; of GNU Global. You can set them either globally, or as file-local or
;; dir-local variables:

;;  - gxref-gtags-conf
;;    The GTAGS/GLOBAL configuration file to use.

;;  - gxref-gtags-label
;;    GTAGS/GLOBAL Configuration label

;;  - gxref-gtags-lib-path
;;    the library path.  Passed to GNU Global using the GTAGSLIBPATH
;;    environment variable.

;; ## Bug reports

;; If you find any bugs, please tell me about it at
;; the [gxref home page][Repository]
;; ## Disclaimers:

;; Because the xref API in Emacs 25.1 is experimental, it's likely to
;; change in ways that will break this package.  I will try to keep up
;; with API changes.

;; ## Source and License

;; Package source can be found in the github
;; repository [here][Repository].

;; It is released under version 3 of the GPL, which you can
;; find [here][License]

;; [Repository]: https://github.com/dedi/gxref
;; [Installation]: https://github.com/dedi/gxref/wiki/Installing-and-setting-up-gxref
;; [License]: https://www.gnu.org/licenses/gpl-3.0.en.html


;;; Code:

(require 'cl-lib)
(require 'xref)

;;;###autoload
(defgroup gxref nil
  "XRef backend using GNU Global."
  :group 'xref)

;;;###autoload
(defcustom gxref-global-exe "global"
  "Path to GNU Global executable."
  :type 'string
  :group 'gxref)

;;;###autoload
(defcustom gxref-create-db-cmd "gtags"
  "Command to create the gtags database."
  :type 'string
  :group 'gxref)

;;;###autoload
(defcustom gxref-update-db-on-save t
  "A flag indicating whether to update the GTAGS database when a file is saved."
  :type 'boolean
  :group 'gxref)


;;;###autoload
(defcustom gxref-project-root-dir nil
  "The root directory of the project.
If not defined, 'global -p' will be used to find it."
  :type '(radio (const :tag "None" nil)
                 directory)
  :safe 'directory-name-p
  )


;;;###autoload
(defcustom gxref-gtags-conf nil
  "Explicit GTAGS/GLOBAL configuration file."
  :type '(radio (const :tag "None" nil)
                file)
  :safe 'file-name-absolute-p)

;;;###autoload
(defcustom gxref-gtags-label nil
  "Explicit GTAGS/GLOBAL label."
  :type '(radio (const :tag "None" nil)
                string))

;;;###autoload
(defcustom gxref-gtags-lib-path nil
  "Explicit GLOBAL libpath."
  :type '(radio (const :tag "None" nil)
                 directory)
  :safe 'directory-name-p)



(defun gxref--prepare-process-environment()
  "Figure out the process environment to use for running GLOBAL/GTAGS"
  (append
   process-environment
   (when gxref-project-root-dir
     (list (concat "GTAGSROOT=" gxref-project-root-dir)))
   (when gxref-gtags-conf     (list (concat "GTAGSCONF=" gxref-gtags-conf)))
   (when gxref-gtags-label    (list (concat "GTAGSLABEL=" gxref-gtags-label)))
   (when gxref-gtags-lib-path (list (concat "GTAGSLIB=" gxref-gtags-lib-path))))
  )

(defun gxref--global-to-list (args)
  "Run GNU Global in an external process.
Return the output as a list of strings.  Return nil if an error
occured.  ARGS is the list of arguments to use when running
global"
  (let ((process-environment (gxref--prepare-process-environment)))
  (condition-case nil
      (apply #'process-lines gxref-global-exe args)
    (error nil))))


(defun gxref--global-find-project ()
  "Run global to find db path."
      (car (gxref--global-to-list '("-p"))))


(defun gxref--find-project-root ()
  "Return the project root for the current project.  Return nil if none."
  (or gxref-project-root-dir
      (gxref--global-find-project)))


(defun gxref--make-xref-from-file-loc (file line column desc)
  "Create an xref object pointing to the given file location.
FILE, LINE, and COLUMN point to the location of the xref, DESC is
a description of it."
  (xref-make desc (xref-make-file-location file line column)))


(defun gxref--make-xref-from-gtags-x-line (ctags-x-line)
  "Create and return an xref object pointing to a file location.
This uses the output of a based on global -x output line provided
in CTAGS-X-LINE argument.  If the line does not match the
expected format, return nil."
  (if (string-match
       "^\\([^ \t]+\\)[ \t]+\\([0-9]+\\)[ \t]+\\([^ \t\]+\\)[ \t]+\\(.*\\)"
       ctags-x-line)
      (gxref--make-xref-from-file-loc (match-string 3 ctags-x-line)
            (string-to-number (match-string 2 ctags-x-line))
            0
            (match-string 4 ctags-x-line))
    ))


(defun gxref--find-symbol (symbol &rest args)
  "Run GNU Global to find a symbol SYMBOL.
Return the results as a list of xref location objects.  ARGS are
any additional command line arguments to pass to GNU Global."
  (let* ((process-args
          (append args
                  (list "-x" "-a" (shell-quote-argument symbol))))
         (global-output (gxref--global-to-list process-args)))
    (remove nil
            (mapcar #'gxref--make-xref-from-gtags-x-line global-output)
            )))


;;;; Interactive commands.

;;;###autoload
(defun gxref-update-db ()
  "Update GTAGS project database for current project."
  (interactive)
  (unless (gxref--find-project-root) (error "Not under a GTAGS project"))
  ;; TODO: We shoule probably call `call-process' directly, not
  ;; `gxref--global-to-list'`
  (gxref--global-to-list '("-u")))

;;;###autoload
(defun gxref-single-update-db ()
  "Update GTAGS project database for the current file."
  (interactive)
  (unless (gxref--find-project-root) (error "Not under a GTAGS project"))
  (unless (buffer-file-name) (error "Buffer has no file associated with it"))
  ;; `gxref--global-to-list'`
  (gxref--global-to-list (list "--single-update" (buffer-file-name))))


(defun gxref--after-save-hook ()
  "After save hook to maybe update the GTAGS database with changed data."
  (when (and gxref-update-db-on-save (buffer-file-name)
             (gxref--find-project-root))
    (gxref-single-update-db)))

(add-hook 'after-save-hook 'gxref--after-save-hook)


(defun gxref--create-db-internal (project-root-dir &optional display)
  "Run `gxref-create-db-cmd' to create a GTAGS database in PROJECT-ROOT-DIR.
If DISPLAY is true, display the process buffer.  Return the new process."
  (let* ((gtags-buffer (get-buffer-create "*Gxref make db*"))
        (default-directory project-root-dir)
        (process-environment (gxref--prepare-process-environment))
        (make-db-process (start-file-process-shell-command
                          "gxref-make-db"
                          gtags-buffer
                          gxref-create-db-cmd)))
    (when display (display-buffer gtags-buffer))
    make-db-process
  ))


;;;###autoload
(defun gxref-create-db (project-root-dir)
  "Create a GTAGS database in the directory specified as PROJECT-ROOT-DIR."
  (interactive "DCreate db in directory: ")
    (set-process-sentinel
     (gxref--create-db-internal project-root-dir)
     ;; TODO: make sure external process succeeded, and offer the user
     ;; a chance to set gxref-project-root-dir if it seems like we
     ;; created the project not in or above current directory.
     (lambda (_process event)
       (message "Gxref tag %s: %s" project-root-dir
                (replace-regexp-in-string "\n+$" "" event)))))


;;;###autoload
(defun gxref-set-project-dir (project-dir)
  "Explicitly Set the directory of the current project to PROJECT-DIR.
The given project dir will be used for locating the GTAGS file,
until a different project is selected, or `gxref-clear-project-dir'
is called to clear the project.

This function is provided as a convenience, but there are other
ways to determine the current project, which could sometimes be
more comfortable.  One option is to not set the project at all,
in which case a search is performed upwards from the current
directory, until a GTAGS file is found.  Alternatively, you could
explicitly set the variable `gxref-project-root-dir'.  This has
the same effect as using this function, but can be by setting a
file-local or dir-local variable."
  (interactive "DProject Directory: ")
  (setq gxref-project-root-dir (expand-file-name project-dir))
  (if (and (not (gxref--global-find-project))
             (y-or-n-p "No GTAGS file found.  Try to create one?"))
    (set-process-sentinel
     (gxref--create-db-internal gxref-project-root-dir)
     (lambda (_process event)
       (message "Gxref tag %s: %s" project-dir
                (replace-regexp-in-string "\n+$" "" event)))
  )))

;;;###autoload
(defun gxref-clear-project-dir ()
  "Explicitly clear the project directory.
When no project directory is set, a project directory is
determined by searching upwards from the current directory, until
a GTAGS file is found.  See `gxref-set-project-dir' for more details."
  (interactive)
  (setq gxref-project-root-dir nil)
  )

;;;; gxref backend definition.


;;;###autoload
(defun gxref-xref-backend ()
  "Gxref backend for Xref."
  (when (or gxref-project-root-dir
            (gxref--find-project-root))
    'gxref)
  )

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql gxref)))
  (let ((current-symbol (symbol-at-point)))
    (when current-symbol
      (symbol-name current-symbol))))

(cl-defmethod xref-backend-definitions ((_backend (eql gxref)) symbol)
  (gxref--find-symbol symbol "-d"))

(cl-defmethod xref-backend-references ((_backend (eql gxref)) symbol)
  (gxref--find-symbol symbol "-r"))

(cl-defmethod xref-backend-apropos ((_backend (eql gxref)) symbol)
  (gxref--find-symbol symbol "-g"))

(cl-defmethod
    xref-backend-identifier-completion-table ((_backend (eql gxref)))
  "Return a list of terms for completions taken from the symbols in the current buffer.
The current implementation returns all the words in the buffer,
which is really sub optimal."
  (gxref--global-to-list '("-c")))


(provide 'gxref)
;;; gxref.el ends here
