;;; cmake-project.el --- Integrates CMake build process with Emacs

;; Copyright (C) 2012, 2013 Alexander Lamaison

;; Author:  Alexander Lamaison <alexander.lamaison@gmail>
;; Maintainer: Alexander Lamaison <alexander.lamaison@gmail>
;; URL: http://github.com/alamaison/emacs-cmake-project
;; Package-Version: 20171121.1115
;; Package-Commit: a7cf9e4c01c4683e14b6942cc5cc5e8cddc98721
;; Version: 0.7
;; Keywords: c cmake languages tools

;; This is free software: you can redistribute it and/or modify
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
;;
;; Projects using CMake do not integrate well into the Emacs ecosystem
;; which often assumes the existence of Makefiles.  This library
;; improves that situation somewhat.
;;

;;; Bugs/todo:

;; - TODO: Make binary directory confiurable
;; - TODO: Extract Flymake command from compile command to pick up
;;         any user changes to build directory
;; - TODO: Find a better way to support header-only directories with
;;         no CMakeLists.txt.

;;; History:

;; 0.1 - Initial version with compile command and Flymake support
;; 0.2 - Made compatible with Marmalade
;; 0.3 - Bug fixes
;; 0.4 - Command to configure new CMake build tree
;; 0.5 - Option to choose the generator when configuring
;; 0.6 - Fix bug configuring paths that do not have spaces
;; 0.7 - Pick up build directory from pre-set `cmake-project-build-directory'
;;

;;; Code:

; Based on `upward-find-file' at http://emacswiki.org/emacs/CompileCommand
(defun cmake-project--upward-find-last-file (filename &optional startdir)
  "Move up directories until we stop finding a certain
filename. When we stop finding it, return the last directory in
which we found it. If the starting directory doesn't include it,
return nil. Start at startdir or . if startdir not given"

  (let ((dirname (expand-file-name
                  (if startdir startdir ".")))
        (found-tip nil) ; set if we stop finding it so we know when to exit loop
        (top nil))  ; top is set when we get
                    ; to / so that we only check it once

    (if (not (file-exists-p (expand-file-name filename dirname)))
        nil ; not even in initial dir!

      ;; While we've still got the file keep looking to find where we lose it
      (while (not (or found-tip top))
        ;; If we're at / set top flag.
        (if (string-match "^\\([a-zA-Z]:\\)?/$" (expand-file-name dirname))
            (setq top t)

          ;; Check for the file in the directory above
          (let ((parent (expand-file-name ".." dirname)))
            (if (not (file-exists-p (expand-file-name filename parent)))
                (setq found-tip t)
              ;; If we found it, keep going till we don't
              (setq dirname parent)))))

      (if (and found-tip (not top)) dirname nil))))

(defun cmake-project-find-root-directory ()
  "Find the top-level CMake directory."
  (file-name-as-directory
   (cmake-project--upward-find-last-file "CMakeLists.txt")))

(defcustom cmake-project-default-build-dir-name "bin/"
  "Default name for CMake build tree directories."
  :type 'directory
  :group 'data)

(defvar cmake-project-build-directory nil
  "Current configured build directory for current buffer.")

(defvar cmake-project-architecture ""
  "This is the MSWindows system architecture cmake will build the source code for.")
;; Here nil means x86/32bit which is selected by default when no
;; architecture is mentioned, hence nil/"". Other options available are
;; "Win64" and "ARM".  This is only available and used in cmake
;; systems in Microsoft Windows. Cmake for unix gets the correct
;; architecture for the project by default and this option is not used
;; for unix systems.

(defun cmake-project--changed-build-directory (new-build-directory)
  (unless new-build-directory
    (error "Build directory was not set"))
  (setq cmake-project-build-directory new-build-directory)
  (setq compile-command (cmake-project-current-build-command))
  ;; Rerun flymake if the mode is enabled
  (when (local-variable-p 'flymake-mode (current-buffer))
    (flymake-mode-off)
    (flymake-mode-on)))

(defun cmake-project-find-build-directory ()
  "Return an already-configured CMake build directory based on
current directory."
  (concat (file-name-as-directory (cmake-project-find-root-directory))
          cmake-project-default-build-dir-name))

(defun cmake-project-current-build-command ()
  "Command line to compile current project as configured in the
build directory."
  (concat "cmake --build "
          (shell-quote-argument (expand-file-name
                                 cmake-project-build-directory))))

;; Build command directory extraction regexp.  Might be useful some day:
;; "cmake\\s-+--build\\s-+\\(?:\"\\([^\"]*\\)\\\"\\|\\(\\S-*\\)\\)"

(defun cmake-project-flymake-init ()
  (list (executable-find "cmake")
        (list "--build" (expand-file-name cmake-project-build-directory))))

(defadvice flymake-get-file-name-mode-and-masks (around cmake-flymake-advice)
  "Override default flymake initialisers for C/C++ source files."
  (let ((flymake-allowed-file-name-masks
         (append (list '(".[ch]\\(pp\\)?\\'$" cmake-project-flymake-init))
                 flymake-allowed-file-name-masks)))
    ad-do-it))

(defadvice flymake-post-syntax-check (before cmake-flymake-post-syntax-check)
  "Override the treatment of the make process error code.
Flymake expects the make tool to return an error code only if the
specific file it is checking contains an error, and it thinks
there is a fatal configuration error if this is not the case.
That is because Flymake is designed to syntax check one file at a
time.  We can't do that because CMake doesn't provide a way to
build individual files (or at least we can't find one).
Therefore, this advice converts the normal build failure error
code (2 for `make`, 1 for Visual Studio) to a success code (0) to
prevent a fatal Flymake shutdown."
  (if (eq (ad-get-arg 0) 2) (ad-set-arg 0 0)) ; make
  (if (eq (ad-get-arg 0) 1) (ad-set-arg 0 0)) ; Visual Studio
  )

(defun cmake-project--split-directory-path (path)
  (let ((dir-agnostic-path (directory-file-name path)))
    (cons
     (file-name-directory dir-agnostic-path)
     (file-name-as-directory (file-name-nondirectory dir-agnostic-path)))))

(defun cmake-project-set-architecture (generator)
  "This method will add the correct architecture to GENERATOR as selected by the user for MSWindows."
  ;; If on MS-Windows remove the mock string "Arch" generated by cmake by default
  (if (string= (substring generator (- (length generator) 7)) " [arch]")
      (progn
	(setq generator (substring generator 0 (- (length generator) 7)))
	;; Now add the correct architecture as defined by the user and return it.
	(if (string= cmake-project-architecture "")
	    (concat generator cmake-project-architecture)
	  (concat generator " " cmake-project-architecture) ;; If not nil add a space too before architecture.
	  ))
    (concat generator "");;else do nothing
    )
  )

(defun cmake-project--available-generators ()
  (let ((help-text (shell-command-to-string "cmake --help"))
        (regexp (concat
                 "The following generators are available on this platform:\n"
                 "\\([^\\']*\\)\\'"))
        (out))
    (string-match regexp help-text)
    (let ((gens-chunk (match-string 1 help-text)))
      (while (string-match
              "\\s-+\\([^=\n]+?\\)\\s-*=[^\n]+?\n\\([^\\']*\\)\\'" gens-chunk)
        (setq out (add-to-list 'out (match-string 1 gens-chunk) 1))
        (setq gens-chunk (match-string 2 gens-chunk)))
      out)))

;;;###autoload
(defun cmake-project-configure-project (build-directory generator &optional flags)
  "Configure or reconfigure a CMake build tree.
BUILD-DIRECTORY is the path to the build-tree directory.  If the
directory does not already exist, it will be created.  The source
directory is found automatically based on the current
buffer. With a prefix argument additional CMake flags can be
specified interactively."
  (interactive
   (let ((directory-parts
          (when cmake-project-build-directory (cmake-project--split-directory-path
                                               cmake-project-build-directory))))
     (let ((root (car directory-parts))
           (directory-name (cdr directory-parts)))
       (list (read-directory-name
              "Configure in directory: " root nil nil directory-name)
             (completing-read
              "Generator (optional): "
              (cmake-project--available-generators) nil t)
             (if current-prefix-arg
              (read-from-minibuffer "Additional CMake flags (optional): "))))))
  (let ((source-directory (cmake-project-find-root-directory))
        (build-directory (file-name-as-directory build-directory)))
    (unless (file-exists-p build-directory) (make-directory build-directory))
    ;; Must force `default-directory' here as `compilation-start' has
    ;; a bug in it. It is supposed to notice the `cd` command and
    ;; adjust `default-directory' accordingly but it gets confused by
    ;; spaces in the directory path, even when properly quoted.
    ;;
    ;; TODO: this isn't actually the directory we want. It needs the
    ;; source directory.
    (let ((default-directory build-directory))
      (compilation-start
       (concat
         ;; HACK: force compilation-start to cd to default-directory
         ;; by inserting dummy cd at front.  Without this, the old
         ;; broken version may pick up quoted path without spaces and
         ;; then assume the quotes are part of the path causing an
         ;; error (see
         ;; https://github.com/alamaison/emacs-cmake-project/issues/1)
        "cd . && "
        "cd " (shell-quote-argument (expand-file-name build-directory))
        " && cmake "
        (unless (string= "" flags) (concat flags " "))
        (shell-quote-argument
         (expand-file-name source-directory))
        (if (string= "" generator)
            ""
	  ;; Set the user defined architecture on windows.
          (concat " -G " (shell-quote-argument (cmake-project-set-architecture generator)))
	  )))
      (cmake-project--changed-build-directory build-directory))))

;;;###autoload
(define-minor-mode cmake-project-mode
  "Minor mode that integrates a CMake-based project with Emacs
build tools such as the CompileCommand and Flymake."
  :lighter " CMake"

  (cond
   ;; Enabling mode
   (cmake-project-mode

    (make-local-variable 'cmake-project-build-directory)
    (make-local-variable 'compile-command)
	(let ((build-directory (if cmake-project-build-directory
							   cmake-project-build-directory
							 (cmake-project-find-build-directory))))
	  (cmake-project--changed-build-directory build-directory))

    (ad-enable-advice
     'flymake-get-file-name-mode-and-masks 'around 'cmake-flymake-advice)
    (ad-enable-advice
     'flymake-post-syntax-check 'before 'cmake-flymake-post-syntax-check)
    (ad-activate 'flymake-get-file-name-mode-and-masks))

   ;; Disabling mode
   (t
    (kill-local-variable 'compile-command)
    (kill-local-variable 'cmake-project-build-directory)

    (ad-disable-advice
     'flymake-post-syntax-check 'before 'cmake-flymake-post-syntax-check)
    (ad-disable-advice
     'flymake-get-file-name-mode-and-masks 'around 'cmake-flymake-advice)
    (ad-activate 'flymake-get-file-name-mode-and-masks))))

(provide 'cmake-project)

;;; cmake-project.el ends here
