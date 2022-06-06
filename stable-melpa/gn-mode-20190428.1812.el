;;; gn-mode.el --- major mode for editing GN (generate ninja) files -*- lexical-binding: t; -*-

;; Copyright (c) 2018-2019 Emily Backes

;; Author: Emily Backes <lucca@accela.net>
;; Maintainer: Emily Backes <lucca@accela.net>
;; Created: 12 November 2018

;; Version: 0.4.1
;; Package-Commit: fcf8e1e500d953364e97e7ebc5708a2c00fa3cd2
;; Package-Version: 20190428.1812
;; Package-X-Original-Version: 0.4.1
;; Keywords: data
;; URL: http://github.com/lashtear/gn-mode
;; Homepage: http://github.com/lashtear/gn-mode
;; Package: gn-mode
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))

;; This file is not part of GNU Emacs.

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;; * Redistributions of source code must retain the above copyright
;;   notice, this list of conditions and the following disclaimer.
;;
;; * Redistributions in binary form must reproduce the above copyright
;;   notice, this list of conditions and the following disclaimer in
;;   the documentation and/or other materials provided with the
;;   distribution.
;;
;; * Neither the names of the authors nor the names of contributors
;;   may be used to endorse or promote products derived from this
;;   software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS
;; OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
;; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:

;; This defines a major-mode for editing GN (ninja generator) config
;; files in Emacs.  Files of this type (e.g. BUILD.gn or *.gni) are
;; common in Chromium-derived projects like Google Chrome and
;; Microsoft Edge (Anaheim).

;;; Code:

(eval-when-compile
  (require 'cl-lib)) ;; using cl-loop

(defgroup gn nil
  "Major mode for editing GN config files in Emacs."
  :group 'languages
  :prefix "gn-")

(defcustom gn-basic-indent 2
  "Indentation of GN structures."
  :type 'integer
  :group 'gn
  :safe t)

(defcustom gn-cleanup-on-load nil
  "Run ‘gn-cleanup’ on load for indentation."
  :type 'boolean
  :group 'gn
  :safe t)

(defcustom gn-cleanup-on-save nil
  "Run ‘gn-cleanup’ on save for indentation."
  :type 'boolean
  :group 'gn
  :safe t)

(defcustom gn-indent-method #'gn-indent-line
  "Select single-line indentation methodology."
  :type '(radio (function-item #'gn-indent-line)
                (function-item #'gn-indent-line-inductive))
  :group 'gn
  :risky t)

(defcustom gn-show-idle-help t
  "Display context-sensitive help when idle."
  :type 'boolean
  :group 'gn
  :risky t)

(defcustom gn-idle-delay 0.125
  "Seconds of delay before showing context-sensitive help.

Use `gn-idle-help` to disable this entirely."
  :type 'number
  :group 'gn
  :risky t)

(defgroup gn-faces nil
  "Configure the faces used by gn font locking."
  :group 'gn
  :group 'faces
  :prefix "gn-")

(defface gn-string-face
  '((t (:inherit font-lock-string-face)))
  "Face for quoted strings in GN configs."
  :group 'gn-faces)

(defface gn-keyword-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for keywords and booleans in GN configs."
  :group 'gn-faces)

(defface gn-numeric-face
  '((t (:inherit font-lock-constant-face)))
  "Face for numbers in GN configs."
  :group 'gn-faces)

(defface gn-variable-face
  '((t (:inherit font-lock-variable-face)))
  "Face for variables in GN configs."
  :group 'gn-faces)

(defface gn-builtin-face
  '((t (:inherit font-lock-builtin-face)))
  "Face for builtin variables in GN configs."
  :group 'gn-faces)

(defface gn-operator-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for gn operators."
  :group 'gn-faces)

(defface gn-tab-face
  '((t (:inherit font-lock-warning-face
                 :background "red")))
  "Face for tab characters, which GN disallows."
  :group 'gn-faces)

(defface gn-warning-face
  '((t (:inherit font-lock-warning-face)))
  "Face for TODO() and urls."
  :group 'gn-faces)

(defface gn-expansion-operator-face
  '((t (:inherit font-lock-regexp-grouping-backslash)))
  "Face for gn operators in string expansions."
  :group 'gn-faces)

(defface gn-expansion-value-face
  '((t (:inherit font-lock-regexp-grouping-construct)))
  "Face for gn values in string expansions."
  :group 'gn-faces)

;; cf. "gn help" in the "Target declarations" section
(defvar gn-target-declarations
  '(("action" "Declare a target that runs a script a single time.")
    ("action_foreach" "Declare a target that runs a script over a set of files.")
    ("bundle_data" "[iOS/macOS] Declare a target without output.")
    ("copy" "Declare a target that copies files.")
    ("create_bundle" "[iOS/macOS] Build an iOS or macOS bundle.")
    ("executable" "Declare an executable target.")
    ("group" "Declare a named group of targets.")
    ("loadable_module" "Declare a loadable module target.")
    ("shared_library" "Declare a shared library target.")
    ("source_set" "Declare a source set target.")
    ("static_library" "Declare a static library target.")
    ("target" "Declare an target with the given programmatic type."))
  "A list of target declarations for GN, and help data.")

;; cf. "gn help" in the "Buildfile functions" section
(defvar gn-buildfile-functions
  '(("assert" "Assert an expression is true at generation time.")
    ("config" "Defines a configuration object.")
    ("declare_args" "Declare build arguments.")
    ("defined" "Returns whether an identifier is defined.")
    ("exec_script" "Synchronously run a script and return the output.")
    ("foreach" "Iterate over a list.")
    ("forward_variables_from" "Copies variables from a different scope.")
    ("get_label_info" "Get an attribute from a target's label.")
    ("get_path_info" "Extract parts of a file or directory name.")
    ("get_target_outputs" "[file list] Get the list of outputs from a target.")
    ("getenv" "Get an environment variable.")
    ("import" "Import a file into the current scope.")
    ("not_needed" "Mark variables from scope as not needed.")
    ("pool" "Defines a pool object.")
    ("print" "Prints to the console.")
    ("process_file_template" "Do template expansion over a list of files.")
    ("read_file" "Read a file into a variable.")
    ("rebase_path" "Rebase a file or directory to another location.")
    ("set_default_toolchain" "Sets the default toolchain name.")
    ("set_defaults" "Set default values for a target type.")
    ("set_sources_assignment_filter" "Set a pattern to filter source files.")
    ("split_list" "Splits a list into N different sub-lists.")
    ("string_replace" "Replaces substring in the given string.")
    ("template" "Define a template rule.")
    ("tool" "Specify arguments to a toolchain tool.")
    ("toolchain" "Defines a toolchain.")
    ("write_file" "Write a file to disk."))
  "A list of buildfile functions for GN, and help data.")

;; cf. "gn help" in the "Built-in predefined variables" section
(defvar gn-builtin-variables
  '(("current_cpu" "[string]" "The processor architecture of the current toolchain.")
    ("current_os" "[string]" "The operating system of the current toolchain.")
    ("current_toolchain" "[string]" "Label of the current toolchain.")
    ("default_toolchain" "[string]" "Label of the default toolchain.")
    ("host_cpu" "[string]" "The processor architecture that GN is running on.")
    ("host_os" "[string]" "The operating system that GN is running on.")
    ("invoker" "[string]" "The invoking scope inside a template.")
    ("python_path" "[string]" "Absolute path of Python.")
    ("root_build_dir" "[string]" "Directory where build commands are run.")
    ("root_gen_dir" "[string]" "Directory for the toolchain's generated files.")
    ("root_out_dir" "[string]" "Root directory for toolchain output files.")
    ("target_cpu" "[string]" "The desired cpu architecture for the build.")
    ("target_gen_dir" "[string]" "Directory for a target's generated files.")
    ("target_name" "[string]" "The name of the current target.")
    ("target_os" "[string]" "The desired operating system for the build.")
    ("target_out_dir" "[string]" "Directory for target output files."))
  "A list of builtin variables for GN, and help data.")

;; cf. "gn help" in the "Variables you set in targets" section
(defvar gn-target-variables
  '(("all_dependent_configs" "[label list]" "Configs to be forced on dependents.")
    ("allow_circular_includes_from" "[label list]" "Permit includes from deps.")
    ("arflags" "[string list]" "Arguments passed to static_library archiver.")
    ("args" "[string list]" "Arguments passed to an action.")
    ("asmflags" "[string list]" "Flags passed to the assembler.")
    ("assert_no_deps" "[label pattern list]" "Ensure no deps on these targets.")
    ("bundle_contents_dir" "[]" "Expansion of {{bundle_contents_dir}} in create_bundle.")
    ("bundle_deps_filter" "[label list]" "A list of labels that are filtered out.")
    ("bundle_executable_dir" "[]" "Expansion of {{bundle_executable_dir}} in create_bundle")
    ("bundle_plugins_dir" "[]" "Expansion of {{bundle_plugins_dir}} in create_bundle.")
    ("bundle_resources_dir" "[]" "Expansion of {{bundle_resources_dir}} in create_bundle.")
    ("bundle_root_dir" "[]" "Expansion of {{bundle_root_dir}} in create_bundle.")
    ("cflags" "[string list]" "Flags passed to all C compiler variants.")
    ("cflags_c" "[string list]" "Flags passed to the C compiler.")
    ("cflags_cc" "[string list]" "Flags passed to the C++ compiler.")
    ("cflags_objc" "[string list]" "Flags passed to the Objective C compiler.")
    ("cflags_objcc" "[string list]" "Flags passed to the Objective C++ compiler.")
    ("check_includes" "[boolean]" "Controls whether a target's files are checked.")
    ("code_signing_args" "[string list]" "Arguments passed to code signing script.")
    ("code_signing_outputs" "[file list]" "Output files for code signing step.")
    ("code_signing_script" "[file name]" "Script for code signing.")
    ("code_signing_sources" "[file list]" "Sources for code signing step.")
    ("complete_static_lib" "[boolean]" "Links all deps into a static library.")
    ("configs" "[label list]" "Configs applying to this target or config.")
    ("data" "[file list]" "Runtime data file dependencies.")
    ("data_deps" "[label list]" "Non-linked dependencies.")
    ("defines" "[string list]" "C preprocessor defines.")
    ("depfile" "[string]" "File name for input dependencies for actions.")
    ("deps" "[label list]" "Private linked dependencies.")
    ("friend" "[label pattern list]" "Allow targets to include private headers.")
    ("include_dirs" "[directory list]" "Additional include directories.")
    ("inputs" "[file list]" "Additional compile-time dependencies.")
    ("ldflags" "[string list]" "Flags passed to the linker.")
    ("lib_dirs" "[directory list]" "Additional library directories.")
    ("libs" "[string list]" "Additional libraries to link.")
    ("output_dir" "[directory]" "Directory to put output file in.")
    ("output_extension" "[string]" "Value to use for the output's file extension.")
    ("output_name" "[string]" "Name for the output file other than the default.")
    ("output_prefix_override" "[boolean]" "Don't use prefix for output name.")
    ("outputs" "[file list]" "Output files for actions and copy targets.")
    ("partial_info_plist" "[filename]" "Path plist from asset catalog compiler.")
    ("pool" "[string]" "Label of the pool used by the action.")
    ("precompiled_header" "[string]" "Header file to precompile.")
    ("precompiled_header_type" "[string]" "\"gcc\" or \"msvc\".")
    ("precompiled_source" "[file name]" "Source file to precompile.")
    ("product_type" "[string]" "Product type for Xcode projects.")
    ("public" "[file list]" "Declare public header files for a target.")
    ("public_configs" "[label list]" "Configs applied to dependents.")
    ("public_deps" "[label list]" "Declare public dependencies.")
    ("response_file_contents" "[string list]" "Contents of .rsp file for actions.")
    ("script" "[file name]" "Script file for actions.")
    ("sources" "[file list]" "Source files for a target.")
    ("testonly" "[boolean]" "Declares a target must only be used for testing.")
    ("visibility" "[label list]" "A list of labels that can depend on a target.")
    ("write_runtime_deps" "[]" "Writes the target's runtime_deps to the given path.")
    ("xcode_extra_attributes" "[scope]" "Extra attributes for Xcode projects.")
    ("test_application_name" "[string]" "Test application name for unit or ui test target."))
  "A list of target-related variables for GN, and help data.")

;; cf. "gn help syntax"
(defvar gn-raw-syntax-keywords
  '(("if" "if ( condition ) { ... } [else...]")
    ("else" "else if ... OR else { ... }")
    ("true" "Boolean true")
    ("false" "Boolean false"))
  "A list of raw syntax keywords for GN, and some attempt at help data.")

(defvar gn-builtin-regexp
  (regexp-opt (mapcar #'car gn-builtin-variables) 'symbols)
  "Regexp of GN language builtin variables.")

(defvar gn-variable-regexp
  (regexp-opt (mapcar #'car gn-target-variables) 'symbols)
  "Regexp of GN language settable target variables.")

(defvar gn-builtin-or-variable-regexp
  (regexp-opt (mapcar #'car
                      (cl-concatenate 'list
                                      gn-builtin-variables
                                      gn-target-variables))
              'symbols)
  "Regexp of GN language known variables of any type.")

(defvar gn-keyword-regexp
  (regexp-opt (mapcar #'car
                      (cl-concatenate 'list
                                      gn-target-declarations
                                      gn-buildfile-functions
                                      gn-raw-syntax-keywords))
              'symbols)
  "Regexp of GN language keywords.")

(defvar gn-integer-regexp
  "\\_<\\(0\\|-?[1-9][0-9]\\{0,18\\}\\)\\_>"
  "Regexp of GN language integers, which must be signed 64bit.")

(defvar gn-hex-regexp
  "\\(?:0x[0-9A-Fa-f]\\{2\\}\\)"
  "Regexp of GN language hex byte references within string expansions.")

(defvar gn-id-regexp
  "\\(?:[A-Za-z_][0-9A-Za-z_]*\\)"
  "Regexp of GN language identifiers.")

(defvar gn-keywords
  `((,gn-keyword-regexp   (1 'gn-keyword-face))
    (,gn-builtin-regexp   (1 'gn-builtin-face))
    (,gn-variable-regexp  (1 'gn-builtin-face))
    (,gn-integer-regexp   (1 'gn-numeric-face))
    (,(concat "\\(\\$\\)\\(" gn-id-regexp "\\)")
     (1 'gn-expansion-operator-face t)
     (2 'gn-expansion-value-face t))
    (,(concat "\\(\\${\\)\\(" gn-id-regexp "\\)\\(}\\)")
     (1 'gn-expansion-operator-face t)
     (2 'gn-expansion-value-face t)
     (3 'gn-expansion-operator-face t))
    (,(concat "\\(\\${\\)\\(" gn-id-regexp "\\)\\(\\.\\)\\(" gn-id-regexp "\\)\\(}\\)")
     (1 'gn-expansion-operator-face t)
     (2 'gn-expansion-value-face t)
     (3 'gn-expansion-operator-face t)
     (4 'gn-expansion-value-face t)
     (5 'gn-expansion-operator-face t))
    (,(concat "\\(\\${\\)\\(" gn-id-regexp "\\)\\(\\[\\)\\(.+?\\)\\(\\]}\\)")
     (1 'gn-expansion-operator-face t)
     (2 'gn-expansion-value-face t)
     (3 'gn-expansion-operator-face t)
     (4 'gn-expansion-value-face t)
     (5 'gn-expansion-operator-face t))
    (,(concat "\\(\\$\\)\\(" gn-hex-regexp "\\)")
     (1 'gn-expansion-operator-face t)
     (2 'gn-expansion-numeric-face t))
    ("^[^#]*?\\(:\\)"     (1 'gn-operator-face t))
    ("\\(\t+\\)"          (1 'gn-tab-face t))
    ("TODO([^)]+)"        (0 'gn-warning-face t))
    ("|[0-9A-Za-z_]+|"    (0 'gn-warning-face t))
    ("\\(?:https?://\\)?\\(?:crbug\\.com\\|github\\.com\\(?:/[-0-9A-Za-z_]+\\)\\{2\\}/issues\\)/[0-9]+"
     (0 'gn-warning-face t)))
  "Keywords used by ‘gn-mode’ font-locking.")

(defvar gn-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry '(?! . ?~) "." st)
    (modify-syntax-entry '(?A . ?Z) "w" st)
    (modify-syntax-entry '(?a . ?z) "w" st)
    (modify-syntax-entry '(?0 . ?9) "w" st)
    (modify-syntax-entry ?_ "_" st)
    (modify-syntax-entry ?\  "-" st)
    (modify-syntax-entry ?\t "." st)
    (modify-syntax-entry ?\{ "(\)" st)
    (modify-syntax-entry ?\} ")\(" st)
    (modify-syntax-entry ?\{ "(\}" st)
    (modify-syntax-entry ?\} ")\{" st)
    (modify-syntax-entry ?\[ "(\]" st)
    (modify-syntax-entry ?\] ")\[" st)
    (modify-syntax-entry ?\n ">" st)
    (modify-syntax-entry ?\r ">" st)
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?# "<" st)
    (modify-syntax-entry ?$ "'" st)
    (modify-syntax-entry ?\\ "\\" st)
    st)
  "Syntax table used in ‘gn-mode’ buffers.")

(defvar gn-mode-abbrev-table nil
  "Abbreviation table used in ‘gn-mode’ buffers.")
(define-abbrev-table 'gn-mode-abbrev-table '())

(defvar gn-mode-map
  (let ((map (make-sparse-keymap "gn mode")))
    (define-key map "\C-c\C-c" 'comment-region)
    map)
  "Keymap used in ‘gn-mode’ buffers.")

(defun gn-region-balance (start end)
  "Determine the structural balance across the described region.

Currently this is called with START at (point-min), so it scans
from the beginning of the buffer for any region, which is not a
good idea for full-buffer re-indentation (O(n^2)).  See
`gn-previous-balance' and `gn-indent-line-inductive' for examples
of more limited and performant scope.

Generally END should be the beginning or end of the current line.
If END is at the beginning of a line, leading closing punctuation
is considered.

This simple lexer does understand and handle the # so that
commented structures do not interfere with indentation.

Dangling-operator structures, e.g.:

    foo +=
      [ \"bar\" ]

require more advanced parsing or additional state tracking and
are currently mis-indented.  Placing the whole structure on one
line, or even just the leading [ will work correctly."
  (save-excursion
    (let ((s (progn
               (goto-char start)
               (point)))
          (e (progn
               (goto-char end)
               (if (bolp)
                   (skip-chars-forward "\t )]}")
                 (end-of-line))
               (point))))
      (cl-loop
       initially (goto-char s)
       do (skip-chars-forward "^{}[]()#" end)
       while (< (point) e)
       if (looking-at "[{[]") sum +1 into balance
       else if (looking-at "[]}]") sum -1 into balance

       ;; handle parenthetical-lists very differently; cf. assert_valid_out_dir
       ;; else if (looking-at "(\\[") do ... hm, needs absolute offsets...

       ;; handle solitary parens differently; cf. asserts in BUILD.gn
       else if (looking-at "(") sum +2 into balance
       else if (looking-at ")") sum -2 into balance

       else if (looking-at "#") do (end-of-line)
       end end end
       if (< (point) (point-max))
       do (progn (forward-char) (skip-chars-forward "^{}[]()#"))
       end
       finally return balance))))

(defun gn-indent-line ()
  "Indent the current line using the whole buffer.

This function uses `gn-region-balance' with start
at (point-min), so it scans from the beginning of the buffer.
Only the current line is changed, but all previous lines are
considered.

If indenting a region, use `gn-indent-region', which will
operate at O(n) rather than O(n^2).  See also
`gn-indent-line-inductive' which assumes prior lines are
correct."
  (interactive "*")
  (save-excursion
    (let* ((bol (progn (beginning-of-line) (point)))
           (eol (progn (end-of-line) (point)))
           (nest (gn-region-balance (point-min) bol))
           (goal (* gn-basic-indent nest))
           (delta (- goal (current-indentation))))
      (when (and (>= goal 0) (not (zerop delta)))
        (indent-rigidly bol eol delta)))))

(defun gn-previous-balance ()
  "Determine the previous indent level.

This does not handle comments specially, except through
`gn-region-balance' on some previous line.  Compare with
`gn-indent-line' for the calculation.

This value should match `gn-region-balance' over the region
from the beginning of the buffer to just before the current
line-- assuming that was indented right."
  (save-excursion
    (let* ((this-line (progn (end-of-line) (point)))
           (prior-start (progn
                          (beginning-of-line)
                          (skip-chars-backward "^[{(")
                          (beginning-of-line)
                          (skip-chars-forward "\t )]}")
                          (point)))
           (prior-end (progn
                        (goto-char this-line)
                        (beginning-of-line)
                        (unless (bobp) (backward-char))
                        (point)))
           (prev-indent (progn
                          (goto-char prior-start)
                          (ceiling (current-indentation)
                                   gn-basic-indent)))
           (local-change (gn-region-balance prior-start prior-end)))
      (+ prev-indent local-change))))

(defun gn-indent-line-inductive ()
  "Indent the current line assuming lines above are correct.

See also `gn-indent-line'."
  (interactive "*")
  (save-excursion
    (let* ((prev-bal (gn-previous-balance))
           (bol (progn (beginning-of-line) (point)))
           (eol (progn (end-of-line) (point)))
           (local-change (gn-region-balance bol bol))
           (goal (* gn-basic-indent (+ prev-bal local-change)))
           (delta (- goal (current-indentation))))
      (when (and (>= goal 0) (not (zerop delta)))
        (indent-rigidly bol eol delta)))))

(defun gn-indent-region (start end)
  "Indent the region START .. END."
  (interactive "*r")
  (let ((garbage-collection-messages nil))
    (cl-symbol-macrolet ((work-end (min end (point-max))))
      (save-excursion
        (cl-loop
         with pr
         initially (progn
                     (goto-char start)
                     (gn-indent-line)
                     (forward-line 1)
                     (setq pr
                           (make-progress-reporter "Indenting region..."
                                                   (point) work-end
                                                   (point) start)))
         while (< (point) work-end)
         do (progn
              (gn-indent-line-inductive)
              (end-of-line)
              (if (not (eobp)) (forward-line))
              (and pr (progress-reporter-update pr (min (point) work-end))))
         finally (progn
                   (and pr (progress-reporter-done pr))
                   (deactivate-mark)))))))

(defun gn-cleanup ()
  "Perform various cleanups of the buffer.

This will re-indent, convert tabs to spaces, and perform general
whitespace cleanup like trailing blank removal.

TODO: this could use gn format."
  (interactive "*")
  (untabify (point-min) (point-max))
  (gn-indent-region (point-min) (point-max))
  (whitespace-cleanup))

;; shamelessly borrowed timer from eldoc-mode and my ksp-cfg-mode
(defvar gn-timer nil
  "GN-mode's timer object.")

(defvar gn-current-idle-delay gn-idle-delay
  "Idle time delay in use by gn-mode's timer.

This is used to notice changes to `gn-idle-delay'.")

(defun gn-explain-variable ()
  "Provide context-sensitive help for a matched variable name.

This assumes that we have just matched `gn-builtin-or-variable-regexp'."
  (let* ((var-name (match-string 1))
         (help-info (or (assoc var-name gn-builtin-variables)
                        (assoc var-name gn-target-variables))))
    (when help-info
      (cl-destructuring-bind (var-type var-desc) (cdr help-info)
        (message "GN variable %s: %s; %s"
                 var-name var-type var-desc)))))

(defun gn-explain-keyword ()
  "Provide context-sensitive help for a matched keyword name.

This assumes that we have just matched `gn-keyword-regexp'."
  (let* ((var-name (match-string 1))
         (help-info (or (assoc var-name gn-target-declarations)
                        (assoc var-name gn-buildfile-functions)
                        (assoc var-name gn-raw-syntax-keywords))))
    (when help-info
      (message "GN keyword %s: %s"
               var-name (cdr help-info)))))

(defun gn-show-help ()
  "Try to display a context-relevant help message.

Looks around the `point' for recognizable structures.  Ensures
the message doesn't go to the *Messages* buffer."
  (let ((message-log-max nil))
    (and
     (not (or this-command
              executing-kbd-macro
              (bound-and-true-p edebug-active)))
     (save-excursion
       ;; Well, let's see what we find.

       ;; First, save match state because we're running inside an
       ;; idle-timer event.  cf. elisp 24 manual 33.6.4.
       (let ((match-state (match-data)))
         (unwind-protect
             (let* ((origin (point))
                    (bol (progn (beginning-of-line) (point))))
               (goto-char origin)

               ;; Backup a step if we're off the end of the line.
               (when (and (eolp)
                          (not (bolp)))
                 (backward-char))

               ;; Ensure we aren't still bonking our heads on the end of the buffer.
               (when (not (eobp))
                 ;; Backup past the boring pair-closes
                 (skip-syntax-backward ")-" bol)

                 ;; If we're looking at something that might be a symbol, find
                 ;; the beginning.
                 (when (memq (char-syntax (char-after)) '(?w ?_))
                   (skip-syntax-backward "w_" bol))

                 (cond
                  ((looking-at gn-builtin-or-variable-regexp)
                   (gn-explain-variable))
                  ((looking-at gn-keyword-regexp)
                   (gn-explain-keyword))
                  (t nil))))
           (set-match-data match-state)))))))

(defun gn-schedule-timer ()
  "Install the context-help timer.

Check first to make certain it is enabled by
`gn-show-idle-help' and not already running.  Adjust delay
time if already running and the `gn-idle-delay' has
changed."
  (or (not gn-show-idle-help)
      (and gn-timer
           (memq gn-timer timer-idle-list))
      (setq gn-timer
            (run-with-idle-timer
             gn-idle-delay nil
             (lambda () (gn-show-help)))))
  (cond ((not (= gn-idle-delay gn-current-idle-delay))
         (setq gn-current-idle-delay gn-idle-delay)
         (timer-set-idle-time gn-timer gn-idle-delay t))))

(defun gn-clear-message ()
  "Clear the message display, if any."
  (let ((message-log-max nil))
    (message nil)))

(defun gn-maybe-cleanup-on-save ()
  "Call `gn-cleanup' from the `before-save-hook' if enabled."
  (when gn-cleanup-on-save
    (gn-cleanup)))

;;;###autoload
(define-derived-mode gn-mode prog-mode "GN"
  "Major mode for editing GN (generate ninja) config files.

\\<gn-mode-map>"
  :group 'gn

  ;; already buffer-local when set
  (setq font-lock-defaults  `(gn-keywords nil nil nil)
        indent-tabs-mode     nil
        tab-width            8
        local-abbrev-table   gn-mode-abbrev-table
        case-fold-search     t)
  (set-syntax-table gn-mode-syntax-table)

  ;; make buffer-local for our purposes
  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'comment-start-skip) "\\s-*#+\\s-*")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'indent-line-function)
       (lambda () (funcall gn-indent-method)))
  (set (make-local-variable 'indent-region-function)
       #'gn-indent-region)
  (set (make-local-variable 'electric-indent-chars)
       (cl-union '(?\( ?\) ?\[ ?\] ?\{ ?\} ?,)
                 electric-indent-chars))

  (add-hook (make-local-variable 'post-command-hook)
            #'gn-schedule-timer nil t)
  (add-hook (make-local-variable 'pre-command-hook)
            #'gn-clear-message nil t)
  (add-hook (make-local-variable 'before-save-hook)
            #'gn-maybe-cleanup-on-save)
  (when gn-cleanup-on-load
    (gn-cleanup)))

(provide 'gn-mode)

;;; gn-mode.el ends here

;; Local Variables:
;; indent-tabs-mode: nil
;; End:
