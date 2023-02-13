;;; jet.el --- Emacs integration for jet Clojure tool -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023 Eric Dallo
;;
;; Author: Eric Dallo <ercdll1337@gmail.com>
;; Maintainer: Eric Dallo <ercdll1337@gmail.com>
;; Created: january 24, 2023
;; Version: 1.0.0
;; Package-Version: 20230213.1615
;; Package-Commit: 90fcdec479d2b1755a1410ae65d53d421f7683c9
;; Keywords: tools
;; Homepage: https://github.com/ericdallo/jet.el
;; Package-Requires: ((emacs "27.1") (transient "0.3.7"))
;;
;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Emacs integration for jet Clojure tool: https://github.com/borkdude/jet
;;
;;  The main entrypoint is the `jet' command which will use `transient'
;;  to display a smooth interface to customize the command to be executed.
;;
;;  The other public functions are available to be used as quick commands
;;  or to keybind.
;;
;;; Code:

(require 'transient)
(require 'subr-x)

(defcustom jet-command "jet"
  "The jet command name to run."
  :group 'jet
  :type 'string)

(defcustom jet-default-args '()
  "The default args to jet command, useful for quick runs."
  :group 'jet
  :type '(repeat string))

(defcustom jet-menu-max-length-to-echo 70
  "The max length to show echo region in `jet-menu'."
  :group 'jet
  :type 'number)

(defvar jet-version-string "1.0.0")

(defvar jet-output-buffer-name "*jet output*")
(defvar jet-error-buffer-name "*jet error*")

(defvar jet-major-mode-alist '(("edn" . 'clojure-mode)
                               ("json" . 'json-mode)
                               ("yaml" . 'yaml-mode)
                               ("transit" . 'ignore)))

(defun jet--assert-jet-on-path ()
  "Asserts if jet is on path."
  (unless (executable-find jet-command)
    (error "The jet command was not found on Emacs PATH")))

(defun jet--run (command &rest args)
  "Run COMMAND with ARGS."
  (jet--assert-jet-on-path)
  (with-output-to-string
    (with-current-buffer standard-output
      (shell-command
       (string-join (append (list command) (seq-map #'shell-quote-argument args)) " ")
       t
       jet-error-buffer-name))))

(defun jet--thing-at-point ()
  "Return the active region or the thing at point."
  (string-trim
   (if (use-region-p)
       (buffer-substring-no-properties (region-beginning) (region-end))
     (or (thing-at-point 'sexp t)
         (thing-at-point 'defun t)))))

(defun jet--major-mode-fn-for (to)
  "Return the major mode function for TO."
  (alist-get to jet-major-mode-alist 'clojure-mode nil #'string=))

(defun jet-menu--suffixes->args (suffixes)
  "Transform SUFFIXES in a single string."
  (string-join
   (delq nil (seq-map (lambda (obj)
                        (when-let (((cl-typep obj 'transient-option))
                                   (arg (oref obj value)))
                          (concat (oref obj argument) arg)))
                      suffixes))
   " "))

(defun jet-menu--transient-suffix-by-name (name suffixes)
  "Return transient-sufix by NAME checking SUFFIXES."
  (seq-find (lambda (obj)
              (and (cl-typep obj 'transient-option)
                   (equal name (oref obj argument))))
            suffixes))

(defun jet-menu--command ()
  "Return the command description for the `jet-menu' transient."
  (let* ((command jet-command)
         (args (jet-menu--suffixes->args transient--suffixes))
         (thing (oref transient--prefix scope))
         (show-echo? (<= (length thing) jet-menu-max-length-to-echo)))
    (concat (propertize "Jet command builder" 'face 'transient-heading)
            "\n\n"
            (propertize (concat (when show-echo? (concat "echo '" thing "' |\n")) command " " args)
                        'face 'transient-inactive-argument)
            "\n")))

(defun jet-menu--run (thing args)
  "Run jet for THING at cursor and ARGS and return result."
  (apply #'jet--run
         (format "echo '%s' | %s" thing jet-command)
         args))

(defun jet-menu--interactive-args ()
  "Interactive args for `jet-menu--run' functions."
  (list (or (and transient-current-prefix (oref transient-current-prefix scope))
            (jet--thing-at-point))
        (or (transient-args transient-current-command)
            jet-default-args)))

(defun jet--fontlock-string-with-mode (str mode)
  "Fontlock STR with MODE."
  (with-temp-buffer
    (insert str)
    (delay-mode-hooks (funcall mode))
    (ignore-errors (font-lock-ensure))
    (buffer-string)))

(transient-define-infix jet-menu--from ()
  :argument "--from="
  :class 'transient-option
  :choices '("edn" "json" "transit" "yaml")
  :description "From what transform"
  :key "i")

(transient-define-infix jet-menu--to ()
  :argument "--to="
  :class 'transient-option
  :choices '("edn" "json" "transit" "yaml")
  :description "To what transform"
  :key "o")

(transient-define-infix jet-menu--keywordize ()
  :argument "--keywordize"
  :class 'transient-switch
  :description "if present, keywordizes JSON keys using `keyword` function"
  :key "k")

(transient-define-infix jet-menu--no-pretty ()
  :argument "--no-pretty"
  :class 'transient-switch
  :description "Whether to not pretty-print the result"
  :key "n")

(transient-define-infix jet-menu--colors ()
  :argument "--colors="
  :class 'transient-option
  :choices '("auto" "true" "false")
  :description "Use colored output while pretty-printing"
  :key "c")

(transient-define-infix jet-menu--edn-reader-opts ()
  :argument "--edn-reader-opts="
  :class 'transient-option
  :description "Use colored output while pretty-printing"
  :key "e")

(transient-define-infix jet-menu--func ()
  :argument "--func="
  :class 'transient-option
  :description "A single-arg Clojure function, or a path to a file that contains a function, that transforms input"
  :key "f")

(transient-define-infix jet-menu--thread-last ()
  :argument "--thread-last="
  :class 'transient-option
  :description "Implicit thread last"
  :key "t")

(transient-define-infix jet-menu--thread-first ()
  :argument "--thread-first="
  :class 'transient-option
  :description "Implicit thread first"
  :key "T")

(transient-define-infix jet-menu--query ()
  :argument "--query="
  :class 'transient-option
  :description "Given a jet-lang query, transforms input"
  :key "q")

(transient-define-infix jet-menu--collect ()
  :argument "--collect"
  :class 'transient-switch
  :description "Given separate values, collects them in a vector"
  :key "C")

;; Public API

;;;###autoload
(defun jet-print (thing &optional args)
  "Run jet for THING at cursor and ARGS printing to messages buffer."
  (interactive (jet-menu--interactive-args))
  (let ((to (seq-find (lambda (arg) (string= arg "--to=")) args)))
    (message (jet--fontlock-string-with-mode (string-trim (jet-menu--run thing args))
                                             (jet--major-mode-fn-for to)))))

;;;###autoload
(defun jet-paste-cursor (thing &optional args)
  "Run jet for THING at cursor and ARGS pasting to current buffer."
  (interactive (jet-menu--interactive-args))
  (let ((result (string-trim (jet-menu--run thing args))))
    (if (use-region-p)
        (replace-region-contents (region-beginning) (region-end) (lambda () result))
      (insert result))))

;;;###autoload
(defun jet-paste-buffer (thing &optional args)
  "Run jet for THING at cursor and ARGS pasting to current buffer."
  (interactive (jet-menu--interactive-args))
  (let* ((result (string-trim (jet-menu--run thing args)))
         (color-option (seq-find (lambda (arg) (string= arg "--colors=")) args))
         (to (seq-find (lambda (arg) (string= arg "--to=")) args))
         (apply-mode? (or (not color-option)
                          (string= "true" color-option)
                          (string= "auto" color-option))))
    (with-current-buffer (get-buffer-create jet-output-buffer-name)
      (erase-buffer)
      (insert result)
      (when apply-mode?
        (delay-mode-hooks (funcall (jet--major-mode-fn-for to))))
      (display-buffer (current-buffer)))))

;;;###autoload
(defun jet-to-clipboard (thing &optional args)
  "Run jet for THING at cursor and ARGS copying to clipboard."
  (interactive (jet-menu--interactive-args))
  (with-temp-buffer
    (insert (string-trim (jet-menu--run thing args)))
    (clipboard-kill-region (point-min) (point-max)))
  (message "Copied jet result to clipboard"))

;;;###autoload
(defun jet-debug (thing &optional args)
  "Print the jet command for THING at cursor and ARGS."
  (interactive (jet-menu--interactive-args))
  (apply #'message (format "echo '%s' | %s" thing jet-command) args))

;;;###autoload (autoload 'jet-menu "jet-menu" "Run jet for THING." t)
(transient-define-prefix jet-menu (thing)
  "Run jet for THING."
  [:description
   jet-menu--command
   "\nCommon Options"
   (jet-menu--from)
   (jet-menu--to)
   (jet-menu--keywordize)
   (jet-menu--no-pretty)
   (jet-menu--edn-reader-opts)
   "\nAdvanced Options"
   (jet-menu--func)
   (jet-menu--thread-last)
   (jet-menu--thread-first)
   (jet-menu--query)
   (jet-menu--collect)]
  ["Actions"
   ("x" "Execute and print" jet-print)
   ("p" "Execute and paste to cursor" jet-paste-cursor)
   ("P" "Execute and paste to new buffer" jet-paste-buffer)
   ("y" "Execute and copy to clipboard" jet-to-clipboard)
   ("D" "Print command for debugging" jet-debug)]

  (interactive (list (jet--thing-at-point)))
  (transient-setup 'jet-menu nil nil :scope thing))

;;;###autoload
(defun jet ()
  "Run jet interactive command builder."
  (interactive)
  (jet-menu (jet--thing-at-point)))

;;;###autoload
(defun jet-print-version ()
  "Print the jet version."
  (interactive)
  (message (string-trim (jet--run jet-command "--version"))))

(provide 'jet)
;;; jet.el ends here
