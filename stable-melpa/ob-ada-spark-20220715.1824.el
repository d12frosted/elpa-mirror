;;; ob-ada-spark.el --- Babel functions for Ada & SPARK

;; Copyright (C) 2021-2022 Francesc Rocher

;; Author: Francesc Rocher
;; Maintainer: Francesc Rocher
;; Keywords: languages, tools, outlines
;; Package-Version: 20220715.1824
;; Package-Commit: e2c9b08b62d8cd480f274f548bd97f3a941ae707
;; URL: https://github.com/rocher/ob-ada-spark
;; Package-Requires: ((emacs "26.1") (f "0.20.0"))
;; Version: 1.3.0

;; This file is NOT part of GNU Emacs.

;; ob-ada-spark is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; ob-ada-spark is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with ob-ada-spark. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-Babel support for evaluating Ada & SPARK code and proving SPARK code.
;;
;;   - Initial implementation + First official release
;;   - For more information see <https://github.com/rocher/ob-ada-spark/>

;;; Requirements:

;; * An Ada compiler (gnatmake)
;; * A SPARK formal verification tool (gnatprove)
;; * Emacs ada-mode, optional but strongly recommended, see
;;   <https://www.nongnu.org/ada-mode/>

;;; Code:
(require 'ob)
(require 'f)
(require 'time-stamp)

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("ada" . "adb"))

(defvar org-babel-temporary-directory)

(defvar org-babel-default-header-args:ada '((:assumptions . nil)
                                            (:assertions . t)
                                            (:level . \4)
                                            (:mode . \all)
                                            (:pedantic . nil)
                                            (:prove . nil)
                                            (:report . all)
                                            (:template . nil)
                                            (:unit . nil)
                                            (:version . nil)
                                            (:warnings . nil)
                                            (:with . nil))
  "Ada/SPARK default header arguments.")

(defconst org-babel-header-args:ada '((assumptions . (nil t))
                                      (assertions . ((nil t)))
                                      (level . ((\0 \1 \2 \3 \4)))
                                      (mode . ((check check_all flow prove all)))
                                      (pedantic . (nil t))
                                      (prove . ((nil t)))
                                      (report . ((fail all provers statistics)))
                                      (template . :any)
                                      (unit . :any)
                                      (version . ((\83 \95 \2005 \2012 \2022)))
                                      (warnings . ((off continue error)))
                                      (with . nil))
  "Ada/SPARK specific header arguments.")

(defcustom ob-ada-spark-compile-cmd "gnatmake"
  "Command used to compile Ada/SPARK code into an executable.
May be either a command in the path, like gnatmake, or an
absolute path name, like /opt/ada/bin/gnatmake.
Parameter may be used, like gnatmake -we. If you specify here an
Ada version flag, like -gnat95, then this value can conflict with
the :ada-version variable specified in an Ada block."
  :group 'org-babel
  :type 'string)

(defcustom ob-ada-spark-prove-cmd "gnatprove"
  "Command used to prove SPARK code.
May be either a command in the path, like gnatprove, or an
absolute path name, like /opt/ada/bin/gnatprove.
Parameter may be used, like gnatprove --prover=z3."
  :group 'org-babel
  :type 'string)

(defcustom ob-ada-spark-compiler-enable-assertions "-gnata"
  "Ada compiler flag to enable assertions.
Used when the :assertions variable is set to t in an Ada block."
  :group 'org-babel
  :type 'string)

(defcustom ob-ada-spark-version 2012
  "Language version to evaluate Ada/SPARK blocks.
Works with the GNAT compiler and gnatmake command. If using a
different compiler, then select 'default' here and specify version
flags in the `ob-ada-spark-compile-cmd' variable."
  :group 'org-babel
  :type '(choice
          (const :tag "default" 0)
          (const :tag "Ada 83" 83)
          (const :tag "Ada 95" 95)
          (const :tag "Ada 2005" 2005)
          (const :tag "Ada 2012" 2012)
          (const :tag "Ada 2022" 2022)))

(defcustom ob-ada-spark-default-file-header (lambda () (format "-----------------------------------------------------------------------------
--
--  Source code generated automatically by 'org-babel-tangle' from
--  file %s
--  %s
--
--  DO NOT EDIT!!
--
-----------------------------------------------------------------------------

"
                                                               (buffer-file-name (current-buffer))
                                                               (time-stamp-string "%Y-%02m-%02d %02H:%02M:%02S")))
  "Header written in files generated with `org-babel-tangle'."
  :group 'babel
  :type 'function)

(defconst ob-ada-spark-template-proc-main
  "with Ada.Text_IO; use Ada.Text_IO;
%s
procedure Main is
begin
  %s
end Main;
"
  "Basic procedure template.
Inspired by the Hello World example.")

(defvar ob-ada-spark-temp-file-counter 0
  "Internal counter to generate sequential Ada/SPARK unit names.")

(defun ob-ada-spark-temp-file (prefix suffix &optional unit no-inc)
  "Create a temporary file with a name compatible with Ada/SPARK.
Creates a temporary filename starting with PREFIX, followed by a
number or an Ada unit name, and endded in SUFFIX.

Optional argument UNIT is a string containing the name of an Ada
unit. If it is not specified, then the filename is composed with
the file counter `ob-ada-spark-temp-file-counter'.

When argument NO-INC is t, then the file counter is not
incremented, thus allowing the creation of several temporary
files for different units with the same numbering."
  (let* ((temp-file-directory
          (if (file-remote-p default-directory)
              (concat (file-remote-p default-directory)
                      org-babel-remote-temporary-directory)
            (or (and (boundp 'org-babel-temporary-directory)
                     (f-exists? org-babel-temporary-directory)
                     org-babel-temporary-directory)
                temporary-file-directory)))
         (temp-file-name
          (if (stringp unit)
              (concat unit suffix)
            (format "%s%06d%s"
                    prefix
                    (if no-inc ob-ada-spark-temp-file-counter
                      (setq ob-ada-spark-temp-file-counter
                       (1+ ob-ada-spark-temp-file-counter)))
                    suffix)))
         (file-name (f-join temp-file-directory temp-file-name)))
    (f-touch (f-join temp-file-directory temp-file-name))
    file-name))

(defun org-babel-expand-body:ada (body params &optional processed-params)
  "Expand BODY according to PARAMS, return the expanded body.
PROCESSED-PARAMS is the list of source code block parameters with
expanded variables, as returned by the function
`org-babel-process-params'."
  (let* ((template (cdr (assq :template processed-params)))
         (template-var (concat "ob-ada-spark-template-" template))
         (vars (org-babel--get-vars params))
         (with (cdr (assq :with processed-params))))

    ;; debug/devel only
    ;; (message "--  vars is %S" vars)

    ;; expand literal variables in the body, if any
    (when vars
      (mapc
       (lambda (var)
         (let ((key (car var))
               (val (cdr var)))
           ;; TODO debug message with (key, value) replaced
           (message "--  var %s replaced with '%s'" key val)
           (setq body (s-replace (format "%s" key) (format "%s" val) body))))
       vars))

    ;; if a template is used, replace body in template, otherwise use body
    (if (boundp (intern template-var))
        ;; TODO debug mesage with template info
        (format (eval (intern template-var))
                (if (null with)
                    ""
                  (mapconcat
                   (lambda (w) (format "with %s; use %s;\n" w w))
                   (s-split " " with t)
                   ""))
                body)
      body)))

(defun org-babel-execute:ada (body params)
  "Execute or prove a block of Ada/SPARK code with org-babel.
BODY contains the Ada/SPARK source code to evaluate. PARAMS is
the list of source code block parameters.

This function is called by `org-babel-execute-src-block'"
  (let* ((processed-params (org-babel-process-params params))
         (full-body (org-babel-expand-body:ada
                     body params processed-params))
         (prove (cdr (assq :prove processed-params)))
         (unit (cdr (assq :unit processed-params)))
         (temp-src-file
          (ob-ada-spark-temp-file "ada-src" ".adb" unit)))
    ;; (message "--  processed-params: %s" processed-params) ;; debug only
    (with-temp-file temp-src-file (insert full-body))
    (if (s-equals? prove "t")
        ;; prove SPARK code
        (ob-ada-spark-prove unit temp-src-file processed-params)
      ;; run Ada/SPARK code
      (ob-ada-spark-execute unit temp-src-file processed-params))))

(defun ob-ada-spark-execute (unit temp-src-file processed-params)
  "Execute a block of Ada/SPARK code with org-babel.
UNIT is the name of the Ada/SPARK unit. TEMP-SRC-FILE is the name
of the source file. PROCESSED-PARAMS is the list of source code
block parameters with expanded variables, as returned by the
function `org-babel-process-params'.

This function is called by `org-babel-execute:ada'"
  (let* ((assertions (cdr (assq :assertions processed-params)))
         (version (or (cdr (assq :version processed-params)) 0))
         (default-directory org-babel-temporary-directory)
         (temp-bin-file (ob-ada-spark-temp-file "ada-bin" "" unit t))
         (compile-cmd (format "%s%s%s -o %s %s"
                              ob-ada-spark-compile-cmd
                              (if (> (+ version ob-ada-spark-version) 0)
                                  (format " -gnat%d"
                                          (if (> version 0)
                                              version
                                            ob-ada-spark-version))
                                "")
                              (if (null assertions) ""
                                (concat " " ob-ada-spark-compiler-enable-assertions))
                              temp-bin-file
                              temp-src-file)))

    ;; clean previous evaluation of the same unit
    (if (stringp unit)
        (cl-mapcar
         (lambda (ext)
           (let ((file (f-join default-directory
                               (concat unit ext))))
             (if (f-exists? file) (f-delete file))))
         '("" ".ali" ".o")))

    ;; comile source code
    (if (stringp unit)
        (message "--  compiling Ada/SPARK source code of unit %s" unit)
      (message "--  compiling Ada/SPARK source code block"))
    (message "--  %s" compile-cmd)
    (org-babel-eval compile-cmd "")

    ;; run binary file
    (if (stringp unit)
        (message "--  running unit %s" unit)
      (message "--  running binary file %s" temp-bin-file))
    (org-babel-eval temp-bin-file "")))

(defun ob-ada-spark-prove (unit temp-src-file processed-params)
  "Prove a block of SPARK code with org-babel.
UNIT is the name of the Ada/SPARK unit. TEMP-SRC-FILE is the name
of the temporary file. PROCESSED-PARAMS is the list of source
code block parameters with expanded variables, as returned by the
function `org-babel-process-params'.

This function is called by `org-babel-execute:ada'"
  (let* ((assumptions (cdr (assq :assumptions processed-params)))
         (level  (cdr (assq :level processed-params)))
         (mode  (cdr (assq :mode processed-params)))
         (pedantic (cdr (assq :pedantic processed-params)))
         (report (cdr (assq :report processed-params)))
         (warnings (cdr (assq :warnings processed-params)))
         (default-directory org-babel-temporary-directory)
         (temp-gpr-file
          (ob-ada-spark-temp-file "spark_p" ".gpr" unit))
         (temp-project (f-base temp-gpr-file))
         (prove-cmd (format "%s -P%s%s%s%s%s%s%s -u %s"
                            ob-ada-spark-prove-cmd
                            temp-gpr-file
                            (if (null assumptions) "" " --assumptions")
                            (if (null level) "" (format " --level=%s" level))
                            (if (null mode) "" (format " --mode=%s" mode))
                            (if (null pedantic) "" " --pedantic")
                            (if (null report) "" (format " --report=%s" report))
                            (if (null warnings) "" (format " --warnings=%s" warnings))
                            temp-src-file)))

    ;; create temporary project
    (with-temp-file temp-gpr-file
      (insert (format "project %s is
  for Source_Files use (\"%s\");
  for Main use (\"%s\");
end %s;
"
                      temp-project
                      (f-filename temp-src-file)
                      temp-src-file
                      temp-project)))

    ;; remove gnatprove directory
    (f-delete (f-join org-babel-temporary-directory "gnatprove") t)

    ;; invoke gnatprove
    (if (stringp unit)
        (message "--  proving SPARK source code of unit %s" unit)
      (message "--  proving SPARK source code block"))
    (message "--  %s" prove-cmd)
    (org-babel-eval prove-cmd "")))

(defun org-babel-prep-session:ada-spark (session params)
  "This function does nothing.
Ada and SPARK are compiled languages with no support for
sessions. SESSION and PARAMS are not support."
  (error "Ada & SPARK are compiled languages -- no support for sessions"))

(defvar ada-skel-initial-string--backup "")

(defun ob-ada-spark-pre-tangle-hook ()
  "This function is called just before `org-babel-tangle'.
When using tangle to export Ada/SPARK code to a file, this
function is used to set the header of the file according to the
value of the variable `ob-ada-spark-default-file-header'."
  ;; ada-skel-initial-string is defined in ada-mode and is inserted
  ;; automatically when Emacs sets ada-mode in an empty buffer; switching
  ;; temporarily its value so the ob-ada-spark-default-file-header is
  ;; inserted
  (if (boundp 'ada-skel-initial-string)
      (progn (setq ada-skel-initial-string--backup ada-skel-initial-string)
             (setq ada-skel-initial-string (funcall ob-ada-spark-default-file-header)))))

(defun ob-ada-spark-post-tangle-hook ()
  "This function is called just after `org-babel-tangle'.
Once the file has been generated, this function restores the
value of the header inserted into Ada/SPARK files."
  ;; if ada-skel-initial-string has not been inserted by ada-mode, then
  ;; insert the default header
  (if (boundp 'ada-skel-initial-string)
      (setq ada-skel-initial-string ada-skel-initial-string--backup)
    (save-excursion
      (beginning-of-buffer)
      (insert (funcall ob-ada-spark-default-file-header)))))

(add-hook 'org-babel-pre-tangle-hook #'ob-ada-spark-pre-tangle-hook)
(add-hook 'org-babel-post-tangle-hook #'ob-ada-spark-post-tangle-hook)

(provide 'ob-ada-spark)

;;; ob-ada-spark.el ends here
