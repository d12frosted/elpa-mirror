;;; salt-mode.el --- Major mode for Salt States -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Ben Hayden

;; Author: Ben Hayden <hayden767@gmail.com>
;; Maintainer: Glynn Forrest <me@glynnforrest.com>
;; URL: https://github.com/glynnforrest/salt-mode
;; Package-Version: 20200210.1200
;; Package-Commit: c46b24e7fdf4a46df5507dc9c533bbc0064a46fa
;; Keywords: languages
;; Version: 0.2
;; Package-Requires: ((emacs "24.4") (yaml-mode "0.0.12") (mmm-mode "0.5.4") (mmm-jinja2 "0.1"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file incorporates work covered by the following copyright and
;; permission notice:

;;   Licensed under the Apache License, Version 2.0 (the "License"); you may not
;;   use this file except in compliance with the License.  You may obtain a copy
;;   of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
;;   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
;;   License for the specific language governing permissions and limitations
;;   under the License.

;;; Commentary:

;; GNU Emacs major mode for editing Salt States.

;; Provides syntax highlighting, indentation, and jinja templating.

;; Syntax highlighting: Fontification supports YAML & Jinja using mmm-mode

;; Tag complete: Using mmm-mode you can generate insert templates:
;; C-c % {
;;   generates {{ _ }} with cursor where the underscore is
;; C-c % #
;; C-c % %
;;   for {# and {% as well.

;; In-Emacs documentation: ElDoc and help buffers are available
;; if you have Salt installed.

;;; Code:

(require 'yaml-mode)
(require 'mmm-auto)
(require 'mmm-jinja2)
(require 'thingatpt)
(require 'json)
(require 'subr-x)
(require 'cl-lib)
(require 'rst)

(defgroup salt nil
  "SaltStack major mode."
  :link '(custom-group-link :tag "Font Lock Faces group" font-lock-faces)
  :prefix "salt-mode-"
  :group 'languages)

(defcustom salt-mode-indent-level 2
  "Indentation of YAML statements."
  :type 'integer
  :group 'salt
  :safe 'integerp)

(defcustom salt-mode-python-program "python"
  "Python executable to use to inspect Salt state functions.

Depending on your system's configuration, you might need to set
this to `python2' or `python3'."
  :type '(file :must-match t)
  :group 'salt)

(defun salt-mode--flyspell-predicate ()
  "Only spellcheck comments and documentation within salt-mode.

Salt strings are usually configuration file data, and not
suitable for spellchecking."
  (memq (get-text-property (- (point) 1) 'face)
        '(font-lock-comment-face font-lock-doc-face)))

(put 'salt-mode 'flyspell-mode-predicate #'salt-mode--flyspell-predicate)

(defun salt-mode--indented-re (lo hi)
  "Return a regexp to match a line with an indent level between LO and HI."
  (format "^%s\\{%d,%d\\}" (make-string salt-mode-indent-level ?\s) lo hi))

(defun salt-mode-bounds-of-state-function-at-point ()
  "Return the bounds of the state function name at the current point."
  (save-excursion
    (skip-chars-backward "a-z0-9_.: ")
    (when (looking-at (concat (salt-mode--indented-re 1 2)
                              "\\([a-z0-9_]+\\.[a-z0-9_]+\\)"))
      (cons (match-beginning 1) (match-end 1)))))

(defun salt-mode-forward-state-function (&optional arg)
  "Move point forward ARG state function definitions.
Move backward if ARG is negative. If ARG is omitted or nil, move
forward one state function definition."
  (interactive "p")
  ;; Use "." as a cheap check for finding potential functions. This
  ;; gets a little hairy because of the optional :, which isn't
  ;; part of the bounds but works best when skipped as if it were.
  (let ((arg (or arg 1)))
    (while (< arg 0)
      (skip-chars-backward "^a-z0-9_.:")
      (let ((bounds (salt-mode-bounds-of-state-function-at-point)))
        (while (and (not bounds) (skip-chars-backward "^."))
          (backward-char)
          (setq bounds (salt-mode-bounds-of-state-function-at-point)))
        (goto-char (car bounds))
        (setq arg (1+ arg))))
    (while (> arg 0)
      (skip-chars-forward "^a-z0-9_.:")
      (let ((bounds (salt-mode-bounds-of-state-function-at-point)))
        (while (and (not bounds) (skip-chars-forward "^."))
          (forward-char)
          (setq bounds (salt-mode-bounds-of-state-function-at-point)))
        (goto-char (cdr bounds))
        (skip-chars-forward ":")
        (setq arg (1- arg))))))

(defun salt-mode-backward-state-function (&optional arg)
  "Move point backward ARG state function definitions.
Move forward if ARG is negative. If ARG is omitted or nil, move
backward one state function definition."
  (interactive "p")
  (forward-thing 'salt-mode-state-function (- (or arg 1))))

(put 'salt-mode-state-function 'bounds-of-thing-at-point
     #'salt-mode-bounds-of-state-function-at-point)

(put 'salt-mode-state-function 'forward-op
     #'salt-mode-forward-state-function)

(defun salt-mode-bounds-of-state-module-at-point ()
  "Return the bounds( of the state module name at the current point."
  (save-excursion
    (skip-chars-backward "a-z0-9_.: ")
    (when (looking-at (concat (salt-mode--indented-re 1 2)
                              "\\([a-z0-9_]+\\)"))
      (cons (match-beginning 1) (match-end 1)))))

(put 'salt-mode-state-module 'bounds-of-thing-at-point
     #'salt-mode-bounds-of-state-module-at-point)

(defun salt-mode--state-module-at-point ()
  "Get the state module at point, either pkg or pkg.installed, or return nil."
  (let ((thing (or (thing-at-point 'salt-mode-state-function t)
                   (thing-at-point 'salt-mode-state-module t))))
    (unless thing
      (save-excursion
        (beginning-of-line)
        ;; jump around to find the closest state module if we're in a function
        ;; assume this if the current line is indented and isn't a comment
        (when (and (looking-at (salt-mode--indented-re 1 3))
                   (save-excursion
                     (skip-chars-forward " ")
                     (not (looking-at "#"))))
          ;; first check if the module is on the current line, e.g.
          ;; | file.managed
          (skip-chars-forward " ")
          (unless (thing-at-point 'salt-mode-state-function)
              ;; no module on this line, try jumping backwards to the last state function
              (ignore-errors (salt-mode-backward-state-function)))
          (setq thing (thing-at-point 'salt-mode-state-function t)))))
    thing))

(defconst salt-mode--query-template "
try:
    import salt.config
    from salt.minion import SMinion
    import json
    opts = salt.config.minion_config('')
    opts['file_client'] = 'local'
    minion = SMinion(opts)
except Exception as exc:
    raise SystemExit(repr(exc))
else:
    print(json.dumps(%s, indent=4))"
  "Python template to query the Salt minion state.

This does not load the full local minion configuration, so will not
be able to access custom states and modules.")

(defun salt-mode--query-minion (program)
  "Run Python code PROGRAM on a virtual Salt minion.

Error handling is the responsibility of the caller; failures
may occur starting the Python process or parsing its output."
  (with-temp-buffer
    (process-file salt-mode-python-program nil t nil "-c"
                  (format salt-mode--query-template program))
    (goto-char (point-min))
    (let ((json-array-type 'list)
          (json-object-type 'hash-table))
      (json-read))))

(defun salt-mode--query-minion-async (program hide-errors callback)
  "Run Python code PROGRAM on a virtual Salt minion.

JSON response data is passed to CALLBACK when it is ready. Errors
result in a message but no signal.

Any errors will be demoted to simple messages. If HIDE-ERRORS is not
nil, don't print any of these messages to the minibuffer.
"
  (declare (indent 2))
  (let ((inhibit-message hide-errors))
    (with-demoted-errors "Unable to query Salt minion: %s"
      (set-process-sentinel
       (start-file-process "salt-async"
                           ;; Work around TRAMP bug in TRAMP 2.2 / Emacs 25.1;
                           ;; remote buffers cannot be passed by name.
                           (get-buffer-create
                            (generate-new-buffer-name " *salt-async*"))
                           salt-mode-python-program "-c"
                           (format salt-mode--query-template program))
       (lambda (process _event)
         ;; Do this again so the sentinel messages are inhibited too
         (let ((inhibit-message hide-errors))
           (when (memq (process-status process) '(exit signal))
             (with-current-buffer (process-buffer process)
               (with-demoted-errors "Error querying Salt minion: %s"
                 (goto-char (point-min))
                 (condition-case nil
                     (let ((json-array-type 'list)
                           (json-object-type 'hash-table))
                       (funcall callback (json-read)))
                   ((json-readtable-error)
                    (message "Error querying Salt minion: %s"
                             (string-trim-right (buffer-string))))))
               (kill-buffer)))))))))

(defvar salt-mode--state-argspecs nil
  "Information about Salt states.")

(defvar salt-mode--data-fetch-attempted nil)

(defun salt-mode-refresh-data (&optional first-time-only hide-errors)
  "Refresh the information about available Salt states.

If FIRST-TIME-ONLY is not nil, only refresh data if it has not been
tried before.

If HIDE-ERRORS is not nil, don't print any error messages to the minibuffer.

If eldoc definitions aren't available and you think they should be
(you have the salt python packages on your system), try running this
function without arguments and observe any messages.
"
  (interactive)
  (unless (and first-time-only salt-mode--data-fetch-attempted)
    (setq salt-mode--data-fetch-attempted t)
    (salt-mode--query-minion-async "minion.functions.sys.state_argspec('*')" hide-errors
      (lambda (result)
        (when (and result (hash-table-p result))
          (setq salt-mode--state-argspecs result)
          (message "Salt mode data refresh completed. Loaded %d Salt state function argument specifications."
                   (hash-table-count result)))))))

(defun salt-mode--state-doc (module-or-function)
  "Return documentation for the given state MODULE-OR-FUNCTION."
  (let ((doc (gethash module-or-function
                      (salt-mode--query-minion
                       (format "minion.functions.sys.state_doc(%S)"
                               module-or-function)))))
    (when doc (replace-regexp-in-string "^    " "" doc))))

(defun salt-mode--execution-doc (module-or-function)
  "Return documentation for the given execution MODULE-OR-FUNCTION."
  (gethash module-or-function
           (salt-mode--query-minion
            (format "minion.functions.sys.doc(%S)"
                    module-or-function))))

(defcustom salt-mode-hide-eldoc-argument-values
  '(nil :json-false "")
  "Default values to hide from the ElDoc function summary."
  :group 'salt
  :type '(set (const :tag "Null" nil)
              (const :tag "Empty string" "")
              (const :tag "False" :json-false)
              (const :tag "True" t)))

(defconst salt-mode--false-string
  (propertize "false" 'face 'font-lock-constant-face)
  "String to use for showing false values.")

(defconst salt-mode--true-string
  (propertize "true" 'face 'font-lock-constant-face)
  "String to use for showing true values.")

(defconst salt-mode--null-string
  (propertize "null" 'face 'font-lock-constant-face)
  "String to use for showing null values.")

(defconst salt-mode--mandatory-string
  (propertize "?" 'face 'font-lock-keyword-face)
  "String to use for showing true values.")

(defconst salt-mode--kwargs-string
  (propertize "... " 'face 'font-lock-keyword-face)
  "String to use for unknown keyword arguments.")

(defun salt-mode--format-argspec (name default)
  "Format argument NAME with value DEFAULT for display."
  (let ((name (propertize name 'face 'font-lock-variable-name-face)))
    (if (member default salt-mode-hide-eldoc-argument-values)
        name
      (format "%s: %s" name
              (cond ((eq default :json-false) salt-mode--false-string)
                    ((eq default t) salt-mode--true-string)
                    ((eq default :mandatory) salt-mode--mandatory-string)
                    ((not default) salt-mode--null-string)
                    (t (propertize
                        (prin1-to-string default)
                        'face 'font-lock-string-face)))))))

(defun salt-mode--eldoc ()
  "ElDoc support for salt-mode."
  (when salt-mode--state-argspecs
    (let* ((state-function (salt-mode--state-module-at-point))
           (argspec (gethash state-function salt-mode--state-argspecs)))
      (when argspec
        (let* ((args (gethash "args" argspec))
               (defaults (gethash "defaults" argspec))
               (all-defaults
                (append (make-list (- (length args) (length defaults)) :mandatory)
                        defaults)))
          (format "%s: [ %s %s]"
                  state-function
                  (string-join
                   (cl-mapcar #'salt-mode--format-argspec
                              (cdr args)
                              (cdr all-defaults))
                   ", ")
                  (if (gethash "kwargs" argspec)
                      salt-mode--kwargs-string "")))))))

(defvar salt-mode--doc-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    (define-key map "g" nil)
    map))

(define-derived-mode salt-mode--doc-mode special-mode "SaltStack Doc "
  "This mode is used to display SaltStack documentation."
  (font-lock-add-keywords nil rst-font-lock-keywords)
  (read-only-mode t))

(put #'salt-mode--doc-mode 'mode-class 'special)

(defun salt-mode--doc-read-arg ()
  "Read a Salt state function from the minibuffer."
  (let* ((default (salt-mode--state-module-at-point))
         (prompt (if (not default)
                     "Open salt doc, e.g. file.managed: "
                   (set-text-properties 0 (length default) nil default)
                   (format "Open salt doc (%s): " default)))
         (word (if (or current-prefix-arg (not default)
                       (and salt-mode--state-argspecs
                            (null (gethash default salt-mode--state-argspecs))))
                   (completing-read
                    prompt
                    (when salt-mode--state-argspecs
                      (hash-table-keys salt-mode--state-argspecs))
                    nil
                    (when salt-mode--state-argspecs 'confirm)
                    nil nil default)
                 default)))
    (list word)))

(defun salt-mode-describe-state (module-or-function)
  "Show documentation for the given state MODULE-OR-FUNCTION.

When called interactively, use the module at point. If no module
is found or a prefix argument is supplied, prompt for the module
to use.

This command requires Salt be installed."
  (interactive (salt-mode--doc-read-arg))
  (with-current-buffer-window
   "*Salt State Doc*" nil nil
   (let ((header (concat "Salt - States - " module-or-function "\n")))
     (princ header)
     (princ (make-string (1- (length header)) ?=))
     (princ "\n"))
   (with-temp-message
       (format "Loading documentation for %s..." module-or-function)
     (princ (or (salt-mode--state-doc module-or-function)
                "No documentation available.")))
   (goto-char (point-min))
   (salt-mode--doc-mode)))

(defun salt-mode-browse-doc (module)
  "Browse to the documentation for the state module `MODULE'.

`MODULE' may be the name of a state module (pkg), or the name of a
state module and method (pkg.installed).

When called interactively, use the module at point. If no module
is found or a prefix argument is supplied, prompt for the module
to use."
  (interactive (salt-mode--doc-read-arg))
  (let* ((pieces (split-string module "\\." t " +"))
         (module (car pieces))
         (url (format "https://docs.saltstack.com/en/latest/ref/states/all/salt.states.%s.html" module))
         (method (cadr pieces)))
    (browse-url (if method (concat url "#salt.states." module "." method) url))))

(defconst salt-mode-toplevel-keywords
  '("include" "exclude" "extend")
  "Keys with special meaning at the top level of state files.")

(defconst salt-mode-requisite-types
  '("listen" "listen_in" "onchanges" "onchanges_any" "onchanges_in"
    "onfail" "onfail_any" "onfail_in" "prereq" "prereq_in"
    "require" "require_any" "require_in" "use" "use_in"
    "watch" "watch_any" "watch_in")
  "Keys that identify requisite relations between states.

More about requisites can be found in the Salt documentation,
https://docs.saltstack.com/en/latest/ref/states/requisites.html")

(defconst salt-mode-match-types
  '("glob" "pcre" "grain" "grain_pcre" "list" "pillar" "pillar_pcre"
    "pillar_exact" "ipcidr" "data" "range" "compound" "nodegroup")
  "Minion matcher types used in top files.

More information about minion targeting can be found at URL
https://docs.saltstack.com/en/latest/ref/states/top.html")

(defconst salt-mode-state-keywords
  '("check_cmd" "failhard" "fire_event" "fun" "name" "names"
    "onfail_stop" "onlyif" "order" "parallel" "reload_grains"
    "reload_modules" "reload_pillar" "retry" "runas"
    "runas_password" "saltenv" "state" "unless")
  "Global state keywords.

These keywords are present in all state modules. Keywords specific to the state module, such as 'source' in file.managed, will be highlighted differently.

The actual list of keywords can be found at URL (see STATE_RUNTIME_KEYWORDS)
https://github.com/saltstack/salt/blob/develop/salt/state.py")

(defconst salt-mode-orch-keywords
  '("arg" "fail_function" "fail_with_changes" "highstate"
    "kwarg" "sls" "succeed_with_changes" "tgt" "tgt_type")
  "Orchestrate keywords.

The actual list of orchestrate keywords can be found at URL
https://docs.saltstack.com/en/latest/topics/orchestrate/orchestrate_runner.html")

(defface salt-mode-keyword-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for special Salt highstate keywords (e.g. `include')."
  :group 'salt)

(defface salt-mode-state-keyword-face
  '((t (:inherit font-lock-builtin-face)))
  "Face for global Salt state keywords (e.g. `check_cmd', `retry')."
  :group 'salt)

(defface salt-mode-orch-keyword-face
  '((t (:inherit font-lock-builtin-face)))
  "Face for Salt orchestrate keywords (e.g. `sls', `tgt')."
  :group 'salt)

(defface salt-mode-requisite-face
  '((t (:inherit font-lock-builtin-face)))
  "Face for Salt state requisites (e.g. `require', `watch_in')."
  :group 'salt)

(defface salt-mode-state-function-face
  '((t (:inherit font-lock-function-name-face)))
  "Face for Salt state functions (e.g. `file.managed')."
  :group 'salt)

(defface salt-mode-state-id-face
  '((t (:inherit font-lock-constant-face)))
  "Face for unquoted Salt state IDs."
  :group 'salt)

(defface salt-mode-environment-face
  '((t (:inherit font-lock-constant-face)))
  "Face for unquoted Salt environment names."
  :group 'salt)

(defface salt-mode-match-type-face
  '((t (:inherit font-lock-builtin-face)))
  "Face for Salt minion match types."
  :group 'salt)

(defface salt-mode-file-source-face
  '((t (:inherit font-lock-builtin-face)))
  "Face for salt:// in Salt file sources."
  :group 'salt)

(defconst salt-mode-keywords
  `((,(format "^%s:" (regexp-opt salt-mode-toplevel-keywords t))
     (1 'salt-mode-keyword-face))
    (,(format "^ +- *%s:" (regexp-opt salt-mode-requisite-types t))
     (1 'salt-mode-requisite-face))
    (,(format "^ +- *%s:" (regexp-opt salt-mode-state-keywords t))
     (1 'salt-mode-state-keyword-face))
    (,(format "^ +- *%s:" (regexp-opt salt-mode-orch-keywords t))
     (1 'salt-mode-orch-keyword-face))
    ("^\\([^ \"':#\n][^\"':#\n]*\\):"
     (1 'salt-mode-state-id-face))
    ("^ +\\([a-z][a-z0-9_]*\\.[a-z][a-z0-9_]*\\):?"
     (1 'salt-mode-state-function-face))
    (": *\\(salt://\\)"
     (1 'salt-mode-file-source-face))
    ;; TODO:
    ;; - Match state IDs in extend: forms and requisite lists.
    ;; - Don't match requisites unless they're under functions.
    ;; - Handle top, pillar, and orch files specially.
    )
  "Regexps for YAML keys with special meaning in SLS files.")

(defconst salt-mode-top-file-keywords
  `((,(format "^ +- *\\(match\\) *: *%s" (regexp-opt salt-mode-match-types t))
     (1 'salt-mode-keyword-face)
     (2 'salt-mode-match-type-face))
    ("^\\([^[:space:]]+\\):"
     (1 'salt-mode-environment-face))
    ;; TODO:
    ;; - Highlighting for compound matchers.
    )
  "Regexps for Salt top files.")

(defconst salt-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-M-b") #'salt-mode-backward-state-function)
    (define-key map (kbd "C-M-f") #'salt-mode-forward-state-function)
    (define-key map (kbd "C-c C-d") #'salt-mode-describe-state)
    ;; (define-key map (kbd "C-M-n") 'salt-mode-forward-state-id)
    ;; (define-key map (kbd "C-M-p") 'salt-mode-backward-state-id)
    map) "Keymap for `salt-mode'.")

(defvar-local salt-mode--file-type 'salt
  "The type of SLS file the buffer is currently visiting, either 'salt or 'top.")

(defun salt-mode--detect-file-type ()
  "Suggest the value of salt-mode--file-type according to the current file."
  (if (null buffer-file-name) 'salt
    (if (equal (file-name-nondirectory buffer-file-name) "top.sls")
        'top 'salt)))

(defun salt-mode-set-file-type (type)
  "Set the file type of the current file and refresh font locking."
  (interactive (list (intern (completing-read "Set file type: " '("salt" "top")))))
  (if (not (member type '(salt top)))
      (error (format "File type must be 'salt or 'top, %s given." type)))
  (setq salt-mode--file-type type)
  (salt-mode--set-keywords))

(defun salt-mode--set-keywords ()
  "Set keywords appropriate for the value of salt-mode--file-type."
  (font-lock-remove-keywords nil salt-mode-top-file-keywords)
  (font-lock-remove-keywords nil salt-mode-keywords)
  (font-lock-add-keywords
   nil
   (cond ((equal salt-mode--file-type 'salt)
          salt-mode-keywords)
         ((equal salt-mode--file-type 'top)
          salt-mode-top-file-keywords)
         (t salt-mode-keywords)))
  (if (fboundp 'font-lock-flush)
      (font-lock-flush)
    ;; use defontify as a fallback in emacs 24
    (font-lock-defontify)))

(add-to-list 'mmm-set-file-name-for-modes 'salt-mode)
(mmm-add-mode-ext-class 'salt-mode "\\.sls\\'" 'jinja2)

;;;###autoload
(define-derived-mode salt-mode yaml-mode "SaltStack"
  "A major mode to edit Salt States.

To view documentation in Emacs or inline with ElDoc, Python and
the Salt Python libraries must be installed on the system
containing the files being edited. (A running minion is not
required.)"
  (setq tab-width salt-mode-indent-level
        indent-tabs-mode nil
        electric-indent-inhibit t
        mmm-global-mode 'maybe)

  (setq-local yaml-indent-offset salt-mode-indent-level)
  (setq-local eldoc-documentation-function #'salt-mode--eldoc)
  (salt-mode-set-file-type (salt-mode--detect-file-type))
  (unless mmm-in-temp-buffer
    (salt-mode-refresh-data t t)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sls\\'" . salt-mode))

(provide 'salt-mode)

;;; salt-mode.el ends here
