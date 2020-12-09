;;; icomplete-vertical.el --- Display icomplete candidates vertically  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Omar Antolín Camarena

;; Author: Omar Antolín Camarena <omar@matem.unam.mx>
;; Keywords: convenience, completion
;; Package-Version: 20201206.759
;; Package-Commit: ef12199fdf53c4a0fe7691850e133dabba58b147
;; Version: 0.2
;; Homepage: https://github.com/oantolin/icomplete-vertical
;; Package-Requires: ((emacs "24.4"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package defines a global minor mode to display Icomplete
;; completion candidates vertically.  You could get a vertical display
;; without this package, by using (setq icomplete-separator "\n"), but
;; that has two problems which `icomplete-vertical-mode' solves:
;;
;; 1. Usually the minibuffer prompt and the text you type scroll off
;;    to the left!  This conceals the minibuffer prompt, and worse,
;;    the text you enter.
;;
;; 2. The first candidate appears on the same line as the one you are
;;    typing in.  This makes it harder to visually scan the candidates
;;    as the first one starts in a different column from the others.
;;
;; For users that prefer the traditional horizontal mode for Icomplete
;; but want to define some commands that use vertical completion, this
;; package provides the `icomplete-vertical-do' macro.  For example to
;; define a command to yank from the kill-ring using completion:
;;
;; (defun insert-kill-ring-item ()
;;   "Insert item from kill-ring, selected with completion."
;;   (interactive)
;;   (icomplete-vertical-do (:separator "\n··········\n" :height 20)
;;     (insert (completing-read "Yank: " kill-ring nil t))))
;;
;; Both the :separator and :height are optional and default to
;; icomplete-vertical-separator and to
;; icomplete-vertical-prospects-height, respectively.
;; If you omit both parts you still need to include the empty
;; parenthesis: (icomplete-vertical-do () ...)!.

;;; Code:

(require 'icomplete)
(require 'cl-lib)

(defgroup icomplete-vertical nil
  "Display icomplete candidates vertically."
  :group 'icomplete)

(defcustom icomplete-vertical-prospects-height 10
  "Minibuffer height when using icomplete vertically."
  :type 'integer
  :group 'icomplete-vertical)

(defun icomplete-vertical-set-separator (separator)
  "Set the vertical candidate separator to SEPARATOR."
  (set-default 'icomplete-vertical-separator separator)
  (when (bound-and-true-p icomplete-vertical-mode)
    (setq icomplete-separator separator)
    (icomplete-vertical--setup-separator)))

(defcustom icomplete-vertical-separator-alist
  '((newline     . "\n")
    (solid-line  . "\n——————————\n")
    (dashed-line . "\n----------\n")
    (dotted-line . "\n··········\n"))
  "Alist of named candidate separators for vertical icompletion.
The symbols used as keys in this alist can be used as values for
`icomplete-vertical-separator', as arguments to
`icomplete-vertical-set-separator' or as the `:separator' option
of `icomplete-vertical-do'.

If you want to add a propertized string as a named separator from
a Custom buffer, select the \"Propertized string\" type from the
list, focus its text field, and enter its value with
\\[universal-argument] \\[eval-expression] followed by your
`propertize' call."
  :type '(alist
          :key-type (symbol :tag "Name")
          :value-type
          (choice (string :tag "String")
                  (sexp :tag "Propertized string")))
  :group 'icomplete-vertical)

(declare-function widget-convert "wid-edit")

(define-widget 'icomplete-vertical-named-separator 'choice
  "A named separator for Icomplete Vertical.
The valid names are the keys of the variable
`icomplete-vertical-separator-alist'."
  :convert-widget
  (lambda (widget)
    (widget-put widget :args
     (cl-loop for (key . _) in icomplete-vertical-separator-alist
              for name = (replace-regexp-in-string "-" " "
                            (capitalize (symbol-name key)))
              collect (widget-convert `(const :tag ,name ,key))))
    widget))

(defcustom icomplete-vertical-separator 'newline
  "Candidate separator when using icomplete vertically.
The separator should contain at least one newline.

If you change the value using setq it won't take effect until the
next time you enter Icomplete Vertical mode.  Customizing makes
it take effect immediately.  To change the value from Lisp code
use `icomplete-vertical-set-separator'.

If you want to set the value to a propertized string from a
Custom buffer, select the \"Custom propertized string\" type from
the list, focus its text field, and enter its value with
\\[universal-argument] \\[eval-expression] followed by your
`propertize' call."
  :type '(choice
          (icomplete-vertical-named-separator :tag "Named separator")
          (string :tag "Custom string")
          (sexp :tag "Custom propertized string"))
  :group 'icomplete-vertical
  :set (lambda (_ separator)
         (icomplete-vertical-set-separator separator)))

(defface icomplete-vertical-separator
  '((default (:inherit shadow)))
  "Face for icomplete-vertical separator.
This face is only applied if the separator string does not
already have face properties."
  :group 'icomplete-vertical)

(defcustom icomplete-vertical-candidates-below-end nil
  "Should candidates appear directly below the end of the input?
If this variable is non-nil the candidates instead of appearing
flush-left, will appear below the end of the minibuffer input."
  :type 'boolean
  :group 'icomplete-vertical)

(defvar icomplete-vertical-saved-state nil
  "Alist of certain variables and their last known value.
Records the values when Icomplete Vertical mode is turned on.
The values are restored when Icomplete Vertical mode is turned off.")

(defmacro icomplete-vertical-save-values (saved &rest bindings)
  "Save state of variables prior to Icomplete Vertical mode activation.
Bind variables according to BINDINGS and set SAVED to an alist of
their previous values.  Each element of BINDINGS is a
list (SYMBOL VALUEFORM) which binds SYMBOL to the value of
VALUEFORM."
  `(setq
    ,saved (list ,@(cl-loop for (var _) in bindings
                            collect `(cons ',var ,var)))
    ,@(apply #'append bindings)))

(defun icomplete-vertical-format-completions (completions)
  "Reformat COMPLETIONS for better aesthetics.
To be used as filter return advice for `icomplete-completions'."
  (save-match-data
    (let ((reformatted
           (if (string-match "^\\((.*)\\|\\[.*\\]\\)?{\\(\\(?:.\\|\n\\)*\\)}"
                             completions)
               (format "%s \n%s"
                       (or (match-string 1 completions) "")
                       (let ((candidates (match-string 2 completions)))
                         (if icomplete-vertical-candidates-below-end
                             (let* ((pad (make-string (current-column) ? ))
                                    (sep (concat "\n" pad)))
                               (concat pad
                                (replace-regexp-in-string "\n" sep candidates)))
                           candidates)))
             completions)))
      (when (eq t (cdr (assq 'resize-mini-windows
                             icomplete-vertical-saved-state)))
        (unless (one-window-p)
          (enlarge-window (- (min icomplete-prospects-height
                                  (cl-count ?\n reformatted))
                             (1- (window-height))))))
      reformatted)))

(defun icomplete-vertical-annotate (completions)
  "Add annotations to COMPLETIONS.
To be used as filter return advice for `icomplete--sorted-completions'."
  (let* ((metadata (completion--field-metadata (icomplete--field-beg)))
         (annotate (completion-metadata-get metadata 'annotation-function)))
    (if (not (and annotate (consp completions)))
        completions
      (let* ((last (last completions))
             (save (cdr last)))
        (setcdr last nil)
        (let ((annotated
               (mapcar
                (lambda (candidate)
                  (let ((annotation (or (funcall annotate candidate) "")))
                    (unless (text-property-not-all
                             0 (length annotation)
                             'face nil
                             annotation)
                      (font-lock-append-text-property
                       0 (length annotation)
                       'face 'completions-annotations
                       annotation))
                    (concat candidate annotation)))
                completions)))
          (setcdr last save)             ; restore
          (setcdr (last annotated) save) ; imitate
          annotated)))))

(defun icomplete-vertical-minibuffer-setup ()
  "Setup minibuffer for a vertical icomplete session.
Meant to be added to `icomplete-minibuffer-setup-hook'."
  (visual-line-mode -1) ; just in case
  (setq truncate-lines t)
  (when (boundp 'auto-hscroll-mode)
    (setq-local auto-hscroll-mode 'current-line))
  (unless (one-window-p)
    (enlarge-window (- icomplete-prospects-height (1- (window-height))))))

(defun icomplete-vertical--setup-separator ()
  "Put the Icomplete Vertical separator in canonical form.
If it is a key in the `icomplete-vertical-separator-alist',
replace it by the corresponding value.  Then apply the default
separator face if the separator is a faceless string."
  (when (symbolp icomplete-separator)
    (let ((lookup (assq icomplete-separator
                        icomplete-vertical-separator-alist)))
      (if lookup
          (setq icomplete-separator (cdr lookup))
        (error "Unknown named icomplete-vertical separator: %s"
               icomplete-separator))))
  (unless (or (get-text-property 0 'face icomplete-separator)
              (next-single-property-change 0 'face icomplete-separator))
    (add-face-text-property 0 (length icomplete-separator)
                            'icomplete-vertical-separator
                            nil
                            icomplete-separator)))

(defun icomplete-vertical-minibuffer-teardown ()
  "Undo minibuffer setup for a vertical icomplete session.
This is used when toggling Icomplete Vertical mode while the
minibuffer is in use."
  (setq truncate-lines nil)
  (unless (one-window-p)
    (enlarge-window (- (1- (window-height))))))

;;;###autoload
(define-minor-mode icomplete-vertical-mode
  "Display icomplete candidates vertically."
  :global t
  (if icomplete-vertical-mode
      (progn
        (icomplete-vertical-save-values
         icomplete-vertical-saved-state
         (icomplete-mode t)
         (icomplete-separator icomplete-vertical-separator)
         (icomplete-hide-common-prefix nil)
         (icomplete-show-matches-on-no-input t)
         (resize-mini-windows 'grow-only)
         (icomplete-prospects-height icomplete-vertical-prospects-height))
        (unless icomplete-mode (icomplete-mode)) ; Don't disable `fido-mode'.
        (icomplete-vertical--setup-separator)
        (advice-add 'icomplete-completions
                    :filter-return #'icomplete-vertical-format-completions)
        (advice-add #'icomplete--sorted-completions
                    :filter-return #'icomplete-vertical-annotate)
        (add-hook 'icomplete-minibuffer-setup-hook
                  #'icomplete-vertical-minibuffer-setup
                  5)
        (when (window-minibuffer-p)
          (icomplete-vertical-minibuffer-setup)))
    (cl-loop for (variable . value) in icomplete-vertical-saved-state
             do (set variable value))
    (unless icomplete-mode (icomplete-mode -1))
    (advice-remove 'icomplete-completions
                   #'icomplete-vertical-format-completions)
    (advice-remove 'icomplete--sorted-completions
                   #'icomplete-vertical-annotate)
    (remove-hook 'icomplete-minibuffer-setup-hook
                 #'icomplete-vertical-minibuffer-setup)
    (when (window-minibuffer-p)
      (icomplete-vertical-minibuffer-teardown))))

;;;###autoload
(defun icomplete-vertical-toggle ()
  "Toggle Icomplete Vertical mode without echo area message."
  (interactive)
  (icomplete-vertical-mode 'toggle))

(defmacro icomplete-vertical-do (params &rest body)
  "Evaluate BODY with vertical completion configured by PARAMS.
The PARAMS argument should be an alist with allowed keys
`:separator' and `:height'.  The separator should contain a
newline and can have text properties controlling its display."
  (declare (indent 1))
  (let ((hook (make-symbol "hook"))
        (verticalp (make-symbol "verticalp")))
    (cl-flet ((config (key var)
                      (let ((val (plist-get params key)))
                        (when val `(,var ,val)))))
      `(cl-flet
           ((,hook ()
                   (when icomplete-vertical-mode
                     (setq ,@(config :separator 'icomplete-separator)
                           ,@(config :height 'icomplete-prospects-height))
                     (icomplete-vertical--setup-separator))))
         (let ((,verticalp icomplete-vertical-mode))
           (icomplete-vertical-mode -1)
           (unwind-protect
               (progn
                 (add-hook 'icomplete-vertical-mode-hook #',hook)
                 (icomplete-vertical-mode)
                 ,@body)
             (icomplete-vertical-mode -1)
             (remove-hook 'icomplete-vertical-mode-hook #',hook)
             (when ,verticalp (icomplete-vertical-mode))))))))

(provide 'icomplete-vertical)
;;; icomplete-vertical.el ends here
