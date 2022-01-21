;;; vunit-mode.el --- VUnit Runner Interface -*- lexical-binding: t -*-

;; Copyright (C) 2021  Lukas Lichtl <support@embed-me.com>

;; Author: Lukas Lichtl <support@embed-me.com>
;; URL: https://github.com/embed-me
;; Package-Version: 20220121.1644
;; Package-Commit: 13311cc9fba6e73cf859dd5defefd330cc41b489
;; Version: 1.0
;; Package-Requires: ((hydra "0.14.0")(emacs "24.3"))
;; Keywords: VUnit, Python, tools

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A trivial global minor mode for VUnit which hooks to the
;; VHDL major mode and interfaces with a VUnit run script by
;; making use of the compile package inside Emacs.

;; The basic requirements are that the HDL simulator is in the
;; path and that VUnit is installed in the python environment.

;; Before compilation, the `vunit-path' must me specified.
;; This can either be done in the init file or the user will be
;; prompted for it.

;; Per default `vunit-run-script' assumes "run.py", but this
;; is also user configurable.  For a full list of available
;; configurations run "M-x customize" and search for vunit.

;; Keys highlighted in blue will execute the specified action and
;; quit the vunit-mode command window.
;; The ones marked in red, however, will add additional flags
;; to the actions available in blue.

;; The default keybinding to invoke vunit-mode is "C-x x".

;;; Code:

(require 'hydra)

(defgroup vunit nil
  "VUnit HDL Interface for Emacs."
  :group 'tools
  :prefix "vunit-")

;;; user setable variables

(defcustom vunit-python-executable "python"
  "The Python executable used by VUnit."
  :group 'vunit
  :type 'string)

(defcustom vunit-path nil
  "Specify the path to the VUnit directory."
  :group 'vunit
  :type 'string)

(defcustom vunit-run-script "run.py"
  "Name of the python script to run."
  :group 'vunit
  :type 'string)

(defcustom vunit-run-outdir "vunit_out"
  "Name of the VUnit output directory."
  :group 'vunit
  :type 'string)

(defcustom vunit-num-threads 1
  "Number of threads to use in parallel."
  :group 'vunit
  :type 'integer)

;; Create a "special" variable so that it is dynamically
;; bound (even if `lexical-binding' is t)
(defvar compilation-scroll-output)
(defcustom vunit-auto-scroll t
  "Auto-scroll to bottom in the compile buffer."
  :group 'vunit
  :type 'boolean
  :set #'(lambda (symbol value)
           (set-default symbol value)
           (setq compilation-scroll-output value)))

;;; internal variables

(defconst vunit--flag-gui "--gui")
(defconst vunit--flag-verbose "--verbose")
(defconst vunit--flag-keep-compiling "--keep-compiling")
(defconst vunit--flag-fail-fast "--fail-fast")
(defconst vunit--flag-log-level "--log-level debug")

(defvar vunit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-x x") #'vunit-buffer-menu/body)
    map)
  "Keymap for VUnit Hydra.")

(defvar vunit-flags '()
  "Additional flags for the python script.")

(defconst vunit--regex-testcase "run\s*(\"\\([^\"]*\\)\")"
  "Regular expression for testcases.")

;;; internal functions

(defun vunit-open-script ()
  "Open vunit script."
  (interactive)
  (find-file-other-window (vunit--run-script-path)))

(defun vunit-compile ()
  "Compile all modules."
  (interactive)
  (vunit--run "--compile"))

(defun vunit-clean ()
  "Clean output products."
  (interactive)
  (vunit--run "--clean"))

(defun vunit-files ()
  "List all files in compile order."
  (interactive)
  (vunit--run "--files"))

(defun vunit-list ()
  "List all testcases."
  (interactive)
  (vunit--run "--list"))

(defun vunit-sim ()
  "Simulate with filter."
  (interactive)
  (vunit--run (read-string "Testcase: ")))

(defun vunit-sim-all ()
  "Simulate all modules."
  (interactive)
  (vunit--run ""))

(defun vunit-sim-file ()
  "Simulate currently opened file/buffer."
  (interactive)
  (vunit--run (format "*.%s.*" (file-name-base buffer-file-name))))

(defun vunit-sim-cursor ()
  "Simulate testcase at cursor."
  (interactive)
  (with-current-buffer (buffer-name)
    (save-excursion
      (if (not (vunit--match-line))
          (re-search-backward vunit--regex-testcase nil 'noerror))
      (if (vunit--match-line)
          (vunit--run (format "*.%s" (vunit--match-line)))
        (message "No testcase...")))))

(defun vunit--run (param)
  "Run VUnit python script with `PARAM'."
  (compile (format "%s %s %s --output-path %s --no-color --num-threads %d %s"
                   vunit-python-executable
                   (vunit--run-script-path)
                   param
                   (vunit--run-outdir-path)
                   vunit-num-threads
                   (vunit--flag-to-string))))

(defun vunit--run-script-path ()
  "Full absolute path to the run script."
  (when (not vunit-path)
    (vunit-get-path))
  (format "%s%s" vunit-path vunit-run-script))

(defun vunit--run-outdir-path ()
  "Full absolute path to the output directory."
  (when (not vunit-path)
    (vunit-get-path))
  (format "%s%s" vunit-path vunit-run-outdir))

(defun vunit-get-path ()
  "Parse for VUnit directory."
  (interactive)
  (setq vunit-path (read-directory-name "Select VUnit Path: ")))

(defun vunit--match-line ()
  "Simulate the testcase at the current line."
  (let ((linestring (thing-at-point 'line t)))
    (if (string-match vunit--regex-testcase linestring)
        (match-string 1 linestring))))

(defun vunit-toggle-flag (flag)
  "Remove or Add `FLAG' to the command and message back."
  (interactive)
  (if (vunit--flag-enabled flag)
      (vunit--rm-flag flag)
    (vunit--add-flag flag))
  (vunit--flag-enabled-message))

(defun vunit--flag-enabled-message ()
  "Message activated flags."
  (message "Flags: %s" (vunit--flag-to-string)))

(defun vunit--flag-to-string ()
  "Return string representation of list."
  (mapconcat #'identity vunit-flags " "))

(defun vunit--flag-enabled (flag)
  "Return t if `FLAG' is set, nil otherwise."
  (member flag vunit-flags))

(defun vunit--add-flag (flag)
  "Add `FLAG' for the python script run."
  (add-to-list 'vunit-flags flag))

(defun vunit--rm-flag (flag)
  "Remove `FLAG' for the python script run."
  (setq vunit-flags (delete flag vunit-flags)))

;;;###autoload
(define-minor-mode vunit-mode
  "Minor Mode to interface with VUnit script."
  :group 'vunit
  :lighter " VUnit"
  :keymap vunit-mode-map)

;;;###autoload
(define-globalized-minor-mode global-vunit-mode
  vunit-mode vunit--turn-on)

(defun vunit--turn-on ()
  "Bind the variable `vunit-mode' to the `vhdl-mode'."
  (when (derived-mode-p 'vhdl-mode)
    (vunit-mode 1)))

;;;###autoload
(defhydra vunit-buffer-menu
  (:color blue
          :pre (vunit--flag-enabled-message))
  "
^Basic^                ^Compile^        ^Simulate^          ^Flags^
^^^^^^^-----------------------------------------------------------------------
_o_: Open Script       _c_: All         _a_: All            _g_: GUI
_r_: List Tests        ^ ^              _s_: Filter         _v_: Verbose
_f_: List Files        ^ ^              _b_: Buffer         _e_: Keep-Compiling
_x_: Clean             ^ ^              _t_: Cursor         _p_: Fail-Fast
^ ^                    ^ ^              ^ ^                 _d_: Debug
^ ^
"
  ("o" vunit-open-script nil)
  ("r" vunit-list     nil)
  ("f" vunit-files    nil)
  ("c" vunit-compile  nil)
  ("x" vunit-clean    nil)
  ("b" vunit-sim-file nil)
  ("t" vunit-sim-cursor nil)
  ("a" vunit-sim-all  nil)
  ("s" vunit-sim      nil)
  ("g" (vunit-toggle-flag vunit--flag-gui) nil :color pink)
  ("v" (vunit-toggle-flag vunit--flag-verbose) nil :color pink)
  ("e" (vunit-toggle-flag vunit--flag-keep-compiling) nil :color pink)
  ("p" (vunit-toggle-flag vunit--flag-fail-fast) nil :color pink)
  ("d" (vunit-toggle-flag vunit--flag-log-level) nil :color pink))

(easy-menu-define vunit-menu vunit-mode-map
  "Vunit Menu"
  '("Vunit"
    :visible vunit-mode
    ("Basic"
     :help "Basic commands"
     ["Open Script" vunit-open-script
      :help "Open vunit script"]
     ["List Tests" vunit-list
      :help "List all testcases"]
     ["List Files" vunit-files
      :help "List all files in compile order"]
     ["Clean" vunit-clean
      :help "Clean output products"])
    ("Compile"
     :help "Compile commands"
     ["All" vunit-compile
      :help "Compile all modules"])
    ("Simulate"
     :help "Simulation commands"
     ["All" vunit-sim-all
      :help "Simulate all modules"]
     ["Filter" vunit-sim
      :help "Simulate with filter"]
     ["Buffer" vunit-sim-file
      :help "Simulate current file/buffer"]
     ["Cursor" vunit-sim-cursor
      :help "Simulate testcase at cursor"])
    ("Flags"
     :help "Flags set for the command to run"
     [vunit--flag-gui
      (vunit-toggle-flag vunit--flag-gui)
      :help "Open GUI"
      :style toggle
      :selected (vunit--flag-enabled vunit--flag-gui)]
     [vunit--flag-verbose
      (vunit-toggle-flag vunit--flag-verbose)
      :help "Verbose"
      :style toggle
      :selected (vunit--flag-enabled vunit--flag-verbose)]
     [vunit--flag-keep-compiling
      (vunit-toggle-flag vunit--flag-keep-compiling)
      :help "Keep-Compiling"
      :style toggle
      :selected (vunit--flag-enabled vunit--flag-keep-compiling)]
     [vunit--flag-fail-fast
      (vunit-toggle-flag vunit--flag-fail-fast)
      :help "Fail-fast"
      :style toggle
      :selected (vunit--flag-enabled vunit--flag-fail-fast)]
     [vunit--flag-log-level
      (vunit-toggle-flag vunit--flag-log-level)
      :help "Log-level Debug"
      :style toggle
      :selected (vunit--flag-enabled vunit--flag-log-level)])))

(provide 'vunit-mode)

;;; vunit-mode.el ends here
