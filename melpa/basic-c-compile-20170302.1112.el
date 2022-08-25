;;; basic-c-compile.el --- Quickly create a Makefile, compile and run C.

;; The MIT License (MIT)

;; Copyright (c) 2016 nick96

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;; Author: Nick Spain <nicholas.spain96@gmail.com>
;; Version: 1.5.9
;; Package-Version: 20170302.1112
;; Package-Commit: 335e96e19647ad7245fb68cf7e68cf86c5023d23
;; Keywords: C, Makefile, compilation, convenience
;; URL: https://github.com/nick96/basic-c-compile
;; Package-Requires: ((cl-lib "0.5") (f "0.19.0"))

;;; Commentary:

;; basic-c-compile aims to augment your C programming workflow.  It
;; provides commands to create a Makefile, compile file(s) and run
;; file(s).  The specifics of many of these commands can be changed
;; using the customisable variables for this package.  They are all
;; described in README.org.
;;
;; Basic setup:
;; Add (require 'basic-c-compile) to you init file.

;;; Bugs:
;; Compilation hangs if basic-c-compile-run-c is called and it find
;; that the outfile is out of date.  Press enter to get passed this.

;;; TODO:
;; Refactor to utilise s, f and dash libraries -- makes code cleaner
;; Remove rebuild in Makefile -- Make does this for us

;;; Code:

(require 'cl-lib)
(require 'f)

;; User customisation
;; These can be changed by the user in their init file
;; or using the customisation menu.

(defgroup basic-c-compile nil
  "Quickly create a makefile, compile and run your C program."
  :prefix "basic-c-compile-"
  :group 'tools)


(defcustom basic-c-compile-compiler "gcc"
  "Compiler used to compile file(s).

This variable is used by `basic-c-compile-file' to tell
`basic-c-compile--sans-makefile' and
`basic-c-compile--create-makefile' which compiler to use."
  :group 'basic-c-compile
  :type 'string
  :options '("clang"))

(defcustom basic-c-compile-all-files "all"
  "Changes the selection of files compiled.
'all' will compile all files in directory.  'selection' will give
you a prompt to list the file.  Any other setting will only
compile the current file.

This variable is used by `basic-c-compile--files-to-compile' to
return a string of the file(s) to be compiled."
  :group 'basic-c-compile
  :type 'string
  :options '("all" "selection" nil))

(defcustom basic-c-compile-compiler-flags "-Wall"
  "String of flags for compiler.

This variable is used by `basic-c-compile-file' to tell
`basic-c-compile--sans-makefile' and
`basic-c-compile--create-makefile' what flags to give the
compiler."
  :group 'basic-c-compile
  :type 'string
  :options '("-Wall -Werror"))

(defcustom basic-c-compile-auto-comp t
  "Boolean option for automatically compiling out of date outfiles.

This variable is checked when `basic-c-compile-run-c' is called.
If it is true then the source file(s) are recompiled."
  :group 'basic-c-compile
  :type 'boolean
  :options '(nil))

(defcustom basic-c-compile-outfile-extension "o"
  "String of extension to put onto the end of the outfile.

This variable is 'o' by default.  If you do change this variable
hen you must also change `basic-c-compile-make-clean'."
  :group 'basic-c-compile
  :type 'string
  :options '(nil "a"))

(defcustom basic-c-compile-make-clean "rm -f *.o"
  "String of line or lines to put in Makefile's clean section.

This option is set to 'rm -f *.o' because by default the
`basic-c-compile-outfile-extension' is set to 'o'.  This makes it
easier to just have general command to remove the outfile.
However, the convention is to have no extension.  Do this by
setting `basic-c-compile-outfile-extension' to nil.  Doing so
means you will have to change this variable as well."
  :group 'basic-c-compile
  :type 'string
  :options '("find . -type f -executable -delete"
             "gfind . -type f -executable -delete"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Interactive functions

;;;###autoload
(defun basic-c-compile-makefile ()
  "Create a Makefile of the form shown in README.org.
This function uses the variables `basic-c-compile-compiler',
`basic-c-compile-all-files' and `basic-c-compile-compiler-flags'.
It uses `basic-c-compile--files-to-compile' in conjunction with
`basic-c-compiler-all-files' to determine files to be the
Makefile's INFILE."
  (interactive)
  (basic-c-compile--create-makefile basic-c-compile-compiler
				    (basic-c-compile--files-to-compile
				     basic-c-compile-all-files
				     (buffer-file-name))
				    (buffer-file-name)
				    basic-c-compile-outfile-extension
				    basic-c-compile-compiler-flags
				    basic-c-compile-make-clean
				    "Makefile"))

;; Refactor this
;;;###autoload
(defun basic-c-compile-file ()
  "Compile file with or without a Makefile.
A y-or-n prompt is called to determine if you want to use the
Makefile of not.  If you say yes ('y') and there is no Makefile
in the directory then one is make using
`basic-c-compile--makefile'.  The presence of a outfile is
check for, if there is not one then 'rebuild' is called,
otherwise 'build' is called."
  (interactive)
  (let* ((path (file-name-directory (buffer-file-name)))
         (infile (file-name-nondirectory (buffer-file-name)))
         (outfile (concat (file-name-nondirectory
                           (file-name-sans-extension infile))
                          ;; Outfile extension depends on -outfile-extension
                          (if basic-c-compile-outfile-extension
                              (format ".%s"
                                      basic-c-compile-outfile-extension)
                            ""))))

    (if (y-or-n-p "Compile with Makefile? ")
        ;; Check for presence of Makefile to stop creating duplicates
        (if (member "Makefile" (directory-files path))
            (if (member outfile (directory-files path))
                (basic-c-compile--with-makefile "rebuild")
              (basic-c-compile--with-makefile "build"))
          (basic-c-compile--create-makefile
	   basic-c-compile-compiler
	   (basic-c-compile--files-to-compile basic-c-compile-all-files
					      (file-name-nondirectory
					       (buffer-file-name)))
	   infile
	   basic-c-compile-outfile-extension
	   basic-c-compile-compiler-flags
	   basic-c-compile-make-clean
	   "Makefile")
          (basic-c-compile--with-makefile "build"))
      (basic-c-compile--sans-makefile basic-c-compile-compiler
                                      basic-c-compile-compiler-flags
                                      (basic-c-compile--files-to-compile
				       basic-c-compile-all-files
				       (buffer-file-name))
                                      infile
                                      basic-c-compile-outfile-extension))))

;;;###autoload
(defun basic-c-compile-run-c ()
  "Run the program.
If the C source file is new than the outfile and
`basic-c-compile-auto-comp' is true, then the file will be
compiled before it is run."
  (interactive)
  (let* ((infile (file-name-nondirectory (buffer-file-name)))
         (outfile (if basic-c-compile-outfile-extension
                      (concat (file-name-sans-extension infile)
                              "."
                              basic-c-compile-outfile-extension)
                    (file-name-sans-extension (file-name-nondirectory
                                               (buffer-file-name))))))
    ;; Compile file if you forgot to before running it.
    (when (and (file-newer-than-file-p infile
                                       outfile)
               basic-c-compile-auto-comp)
      (message "Basic-c-compile updated %s to be current with %s."
               outfile
               infile)
      (basic-c-compile-file))
    (basic-c-compile--run-c-file infile
                                 basic-c-compile-outfile-extension)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Non-interactive functions

(defun basic-c-compile--c-file-extension-p (file-name)
  "Return t if FILE-NAME has extension '.c', otherwise nil."
  (equal (f-ext file-name) "c"))

;; Is this function necessary??
(defun basic-c-compile--files-to-compile (var-files-to-compile
                                          file
                                          &optional str-files-to-compile)
  "Return a list of files to compile.
Contents of list depends VAR-FILES-TO-COMPILE.  If 'all' then all '.c' files in
FILE directory will be compiled.  For selected; if STR-FILES-TO-COMPILE is
specified, then files in that list will be compiled (this is mostly for testing
purposes)."
  (cond ((equal var-files-to-compile "all")
         (mapconcat 'identity
                    (mapcar #'shell-quote-argument
                            (mapcar #'file-name-nondirectory
                                    (cl-remove-if-not
				     #'basic-c-compile--c-file-extension-p
				     (directory-files (file-name-directory
						       file)))))
                    " "))
         ((equal var-files-to-compile "selection")
         (if str-files-to-compile
             str-files-to-compile
           (read-string "Enter files:")))
         (t (shell-quote-argument file))))

(defun basic-c-compile--sans-makefile (compiler
                                       flags
                                       files-to-compile
                                       file
                                       extension)
  "Use COMPILER with flags FLAGS and without a Makefile to
compile FILES-TO-COMPILE as the name of current FILE with
extension EXTENSION."
  (compile (format "%s %s %s -o %s%s"
                   compiler
                   flags
                   files-to-compile
                   (shell-quote-argument (file-name-sans-extension file))
                   (if extension
                       (format ".%s" extension)
                     ""))))

(defun basic-c-compile--with-makefile (arg)
  "Compile file using the Makefile with specified ARG (build,
clean or rebuild)."
  (compile (format "make %s" arg)))

(defun basic-c-compile--create-makefile (compiler
                                         files-to-compile
                                         file
                                         extension
                                         compiler-flags
                                         clean
                                         makefile)
  "Create makefile of rules for compiler COMPILER on FILES-TO-COMPILE.
Out-file will have name FILE.EXTENSION compiled with flags
COMPILER-FLAGS and makefile with clean command CLEAN will be
written to MAKEFILE."
  (let ((makefile-contents
         (format (s-join "\n" '("CC = %s"
				"INFILE = %s"
				"OUTFILE = %s%s"
				"FLAGS = %s\n"
				"build: $(INFILE)"
				"\t$(CC) $(FLAGS) $(INFILE) -o $(OUTFILE)\n"
				"clean:"
				"\t%s\n"
				"rebuild: clean build"))
                 compiler
                 (if (listp files-to-compile)
                     (s-join " "
			     (mapcar #'shell-quote-argument
				     (mapcar #'file-name-nondirectory
					     files-to-compile)))
                   (shell-quote-argument (file-name-nondirectory
					  files-to-compile)))
		 (shell-quote-argument (file-name-nondirectory
					(file-name-sans-extension file)))
                 (if extension
                     (format ".%s" extension)
		   "")
                 compiler-flags
                 clean)))
    (f-write makefile-contents 'utf-8 makefile)))


;; Should this be in a non-interactive function, it has side effects?
(defun basic-c-compile--run-c-file (file extension)
  "Run FILE.EXTENSION with the output printing in a temporary buffer."
  (compile (format "./%s%s"
                   (shell-quote-argument (file-name-sans-extension file))
                   (if extension
                       (format ".%s" extension) ""))))


(provide 'basic-c-compile)
;;; basic-c-compile.el ends here
