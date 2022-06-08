;;; isend-mode.el --- Interactively send parts of an Emacs buffer to an interpreter

;; Copyright (C) 2012 François Févotte
;; Author:  François Févotte <fevotte@gmail.com>
;; URL:     https://github.com/ffevotte/isend-mode.el
;; Package-Version: 20190201.832
;; Package-Commit: 38ace354d579eb364d4f95b9ea16081c171ea604
;; Version: 0.2

;; This file is NOT part of Emacs.

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


;;; Commentary:

;; `isend-mode' is an Emacs extension allowing interaction with code
;; interpreters in `ansi-term' or `term' buffers. Some language-specific
;; modes (e.g. `python-mode') already provide similar features; `isend-mode'
;; does the same in a language-agnostic way.


;; Basic usage:

;; 1. Open an `ansi-term' buffer where the interpreter will live.
;;    For example:
;;
;;      M-x ansi-term RET /bin/sh RET

;; 2. Open a buffer with the code you want to execute, and associate it
;;    to the interpreter buffer using the `isend-associate' command (also
;;    aliased to `isend'). For example:
;;
;;      M-x isend-associate RET *ansi-term* RET

;; 3. Press C-RET (or M-x `isend-send') to send the current line to the
;;    interpreter. If the region is active, all lines spanned by the region
;;    will be sent (i.e. no line will be only partially sent). Point is
;;    then moved to the next non-empty line (but see configuration variable
;;    `isend-skip-empty-lines').


;; Contributing:

;; If you make improvements to this code or have suggestions, please do not
;; hesitate to fork the repository or submit bug reports on github. The
;; repository is at:
;;
;;     https://github.com/ffevotte/isend-mode.el

;;; Code:

;; Get rid of warning about `term-send-input' not being defined.
(require 'term)

;; if-let
(require 'subr-x)



;; Customization variables

;;;###autoload
(defgroup isend nil
  "Interactively send parts of an Emacs buffer to an interpreter."
  :group 'processes)

;;;###autoload
(defcustom isend-forward-line t
  "If non-nil, `isend-send' advances by one line after sending content."
  :group 'isend
  :type  'boolean)

;;;###autoload
(defcustom isend-skip-empty-lines t
  "If non-nil, `isend-send' skips empty lines (i.e. lines containing only spaces).

Note that this is effective only for sending single lines. To strip whitespace
from sent regions use `isend-strip-empty-lines'."
  :group 'isend
  :type  'boolean)

;;;###autoload
(defcustom isend-strip-empty-lines nil
  "If non-nil, `isend-send' strips empty lines (i.e. lines containing only spaces).

Note that this works when sending an entire region. If enabled, all lines containing
whitespace only will be stripped from the region before it is sent."
  :group 'isend
  :type  'boolean)

;;;###autoload
(defcustom isend-delete-indentation nil
  "If non-nil, `isend-send' deletes indentation in regions sent.

Note that this only works when sending a region (as opposed to a
single line). Relative indentation with respect to the first line
in the region is preserved.

This is useful to send e.g. Python blocks.")

;;;###autoload
(defcustom isend-end-with-empty-line nil
  "If non-nil, `isend-send' appends an empty line to everything you send.

This is useful, for example, when working with python code,
in which whitespace terminates definitions."
  :group 'isend
  :type  'boolean)

;;;###autoload
(defcustom isend-bracketed-paste nil
  "If non-nil, `isend-send' will use \"bracketed paste\".

Bracketed paste surrounds the contents it sends with escape
sequences indicating to the underlying process that this content
is being pasted."
  :group 'isend
  :type  'boolean)

;;;###autoload
(defcustom isend-send-line-function nil
  "Function used by `isend-send' to send a single line.

This function is called in a buffer containing the text to be
sent. It can modify it as needed before it is sent to the
process. It also receives as argument the destination buffer, in
case some interaction with it would be useful.

Possible values include:
- nil (default)
- `isend--ipython-cpaste'
- `isend--ipython-paste'"
  :group 'isend
  :type  'function)

;;;###autoload
(defcustom isend-send-region-function nil
  "Function used by `isend-send' to send a region.

This function is called in a buffer containing the text to be
sent. It can modify it as needed before it is sent to the
process.  It also receives as argument the destination buffer,
in case some interaction with it would be useful.

Possible values include:
- nil (default)
- `isend--ipython-cpaste'
- `isend--ipython-paste'"
  :group 'isend)

;;;###autoload
(defcustom isend-mark-defun-function 'mark-defun
  "Function used by `isend-defun' to select a function definition.

This function should take no argument.

Possible values include:
- `mark-defun' (default)
- `isend--python-mark-defun'"
  :group 'isend)



;; Setup helpers

;; Put something like this in your init file to use:
;;
;;   (add-hook 'isend-mode-hook 'isend-default-shell-setup)

;;;###autoload
(defun isend-default-shell-setup ()
  (when (eq major-mode 'sh-mode)
    (set (make-local-variable 'isend-skip-empty-lines)     t)
    (set (make-local-variable 'isend-strip-empty-lines)    nil)
    (set (make-local-variable 'isend-delete-indentation)   nil)
    (set (make-local-variable 'isend-end-with-empty-line)  nil)
    (set (make-local-variable 'isend-bracketed-paste)      nil)
    (set (make-local-variable 'isend-send-line-function)   nil)
    (set (make-local-variable 'isend-send-region-function) nil)
    (set (make-local-variable 'isend-mark-defun-function)  #'mark-defun)))

;;;###autoload
(defun isend-default-python-setup ()
  (when (eq major-mode 'python-mode)
    (set (make-local-variable 'isend-skip-empty-lines)     nil)
    (set (make-local-variable 'isend-strip-empty-lines)    t)
    (set (make-local-variable 'isend-delete-indentation)   t)
    (set (make-local-variable 'isend-end-with-empty-line)  t)
    (set (make-local-variable 'isend-bracketed-paste)      t)
    (set (make-local-variable 'isend-send-line-function)   nil)
    (set (make-local-variable 'isend-send-region-function) nil)
    (set (make-local-variable 'isend-mark-defun-function)  #'isend--python-mark-defun)))

;;;###autoload
(defun isend-default-ipython-setup ()
  (when (eq major-mode 'python-mode)
    (set (make-local-variable 'isend-skip-empty-lines)     nil)
    (set (make-local-variable 'isend-strip-empty-lines)    nil)
    (set (make-local-variable 'isend-delete-indentation)   nil)
    (set (make-local-variable 'isend-end-with-empty-line)  nil)
    (set (make-local-variable 'isend-bracketed-paste)      nil)
    (set (make-local-variable 'isend-send-line-function)   nil)
    (set (make-local-variable 'isend-send-region-function) #'isend--ipython-paste)
    (set (make-local-variable 'isend-mark-defun-function)  #'isend--python-mark-defun)))

;;;###autoload
(defun isend-default-julia-setup ()
  (when (eq major-mode 'julia-mode)
    (set (make-local-variable 'isend-skip-empty-lines)     t)
    (set (make-local-variable 'isend-strip-empty-lines)    nil)
    (set (make-local-variable 'isend-delete-indentation)   nil)
    (set (make-local-variable 'isend-end-with-empty-line)  nil)
    (set (make-local-variable 'isend-bracketed-paste)      t)
    (set (make-local-variable 'isend-send-line-function)   nil)
    (set (make-local-variable 'isend-send-region-function) nil)
    (set (make-local-variable 'isend-mark-defun-function)  #'mark-defun)))



;; User interface

(define-minor-mode isend-mode
  "Toggle ISend (Interactive Send) mode\\<isend-mode-map>.
With ARG, turn ISend mode on if ARG is positive, otherwise
turn it off.

This mode allows sending commands from a regular buffer to an
interpreter in a terminal buffer (such as `ansi-term' or
`eshell')

Note that you should NOT manually activate this mode. You should
use `isend-associate' instead.

When ISend mode is enabled and a destination buffer has been
defined using `isend-associate', you can send lines or regions to
the associated buffer using \\[isend-send] (or `isend-send').


\\{isend-mode-map}"
  :init-value nil
  :lighter    " Isend"
  :keymap     '(([C-return] . isend-send)))

(defvar isend--command-buffer)
(make-variable-buffer-local 'isend--command-buffer)

;;;###autoload
(defun isend-associate (buffername)
 "Set the buffer to which commands will be sent using `isend-send'.
This should usually be something like '*ansi-term*' or '*terminal*'."
 (interactive "bAssociate buffer to terminal: ")
 (setq isend--command-buffer buffername)
 (isend-mode 1))

;;;###autoload
(defalias 'isend 'isend-associate)



(defun isend-send ()
  "Send the current line to a terminal.
Use `isend-associate' to set the associated terminal buffer. If
the region is active, all lines spanned by it are sent."
  (interactive)
  (isend--check)

  (let* ((region-active (region-active-p))

         ;; The region to be sent
         (bds   (isend--region-boundaries))
         (begin (car bds))
         (end   (cdr bds))

         ;; Configuration variables values need to be taken from
         ;; the origin buffer (they are potentially local)
         (isend-strip-empty-lines-1    isend-strip-empty-lines)
         (isend-delete-indentation-1   isend-delete-indentation)
         (isend-end-with-empty-line-1  isend-end-with-empty-line)
         (isend-send-region-function-1 isend-send-region-function)
         (isend-send-line-function-1   isend-send-line-function)
         (isend-bracketed-paste-1      isend-bracketed-paste)

         ;; Buffers involved
         (origin (current-buffer))
         (destination (get-buffer isend--command-buffer)))

    ;; A temporary buffer is used to apply filters
    (with-temp-buffer
      (insert-buffer-substring origin begin end)

      ;; Phase 1 - Apply filters on the region
      (when region-active
        (when isend-strip-empty-lines-1
          (delete-matching-lines "^[[:space:]]*$" (point-min) (point-max)))

        (when isend-delete-indentation-1
          (goto-char (point-min))
          (back-to-indentation)
          (indent-rigidly (point-min) (point-max) (- (current-column))))

        (when isend-end-with-empty-line-1
          (goto-char (point-max))
          (insert "\n")))

      (if region-active
          (and isend-send-region-function-1
               (funcall isend-send-region-function-1 destination))
        (and isend-send-line-function-1
             (funcall isend-send-line-function-1 destination)))

      (when isend-bracketed-paste-1
        (goto-char (point-min)) (insert "\e[200~")
        (goto-char (point-max)) (insert "\e[201~"))

      ;; Phase 2 - Actually send the region to the associated buffer
      (let ((contents (buffer-substring-no-properties (point-min) (point-max))))
        (isend--send-dest contents destination))))

  (deactivate-mark)

  ;; Move point to the next line
  (when isend-forward-line
    (isend--next-line)))


(defun isend-send-buffer ()
  (interactive)
  (save-excursion
    (mark-whole-buffer)
    (isend-send)))


(defun isend-send-defun ()
  (interactive)
  (save-excursion
    (funcall isend-mark-defun-function)
    (isend-send)))


(defun isend-display-buffer ()
  (interactive)
  (isend--check)
  (display-buffer isend--command-buffer))


;; Helper functions

(defun isend--check ()
  "Check whether the current buffer has been associated to a terminal."
  (when (not (boundp 'isend--command-buffer))
    (error "No associated terminal buffer. You should run `isend-associate'")))

(defun isend--region-seed ()
  "Return a 'seed' of the region to be sent.
The result is a cons cell of the form (beg . end)"
  (cond
   ;; If the region is active, use region boundaries
   ((use-region-p)
    (cons (region-beginning)
          (- (region-end) 1)))

   ;; If the region is not active and `isend-skip-empty-lines' is non-nil,
   ;; move forward to the first non-empty line.
   (isend-skip-empty-lines
    (skip-chars-forward "[:space:]\n")
    (cons (point)
          (point)))

   ;; Otherwise, use current point
   (t
    (cons (point)
          (point)))))

(defun isend--region-boundaries ()
  "Return the boundaries of the region to be sent.
The result is a cons cell of the form (beg . end)
The region is expanded so that no line is only partially sent."
  (let* ((bds (isend--region-seed))
         (beg (car bds))
         (end (cdr bds)))

    ;; Expand the region to span whole lines
    (goto-char beg)
    (setq beg (line-beginning-position))
    (goto-char end)
    (setq end (line-end-position))
    (when (= beg (point-max))
      (error "Nothing more to send!"))
    (cons beg end)))

(defun isend--next-line ()
  "Move point to the next line.
Empty lines are skipped if `isend-skip-empty-lines' is non-nil."
  (goto-char (line-end-position))
  (if isend-skip-empty-lines
      (when (> (skip-chars-forward "[:space:]\n") 0)
        (goto-char (line-beginning-position)))
    (beginning-of-line 2)))

(defun isend--ipython-cpaste (destination)
  ""
  (isend--send-dest "%cpaste" destination)
  (sleep-for 0.1)
  (goto-char (point-max)) (insert "\n--"))

(defun isend--ipython-paste (destination)
  ""
  (clipboard-kill-ring-save (point-min) (point-max))
  (erase-buffer)(insert "%paste"))

(defun isend--python-mark-defun ()
  "Mark the current top-level python block.

A block is defined as in `python-nav-beginning-of-block' and
`python-nav-end-of-block'. A top-level block begins without
indentation."
  (let ((loop t))
    (while loop
      (unless (python-nav-beginning-of-block)
        (error "Not in a python block"))
      (if (bolp)
          (setq loop nil)
        (forward-line -1))))
  (push-mark (point))
  (python-nav-end-of-block)
  (exchange-point-and-mark))


;; Supported destination buffer types

(defun isend--send-dest (contents destination)
  (with-current-buffer destination
    (cond
     ((eq major-mode 'term-mode)
      (isend--send-dest-term contents))
     ((eq major-mode 'vterm-mode)
      (isend--send-dest-vterm contents))
     (t
      (isend--send-dest-default contents)))))

(defun isend--send-dest-default (contents)
  ;; Move to the process mark if there is one
  (if-let ((process (get-buffer-process (current-buffer))))
      (goto-char (process-mark process)))

  ;; Insert the contents
  (let ((inhibit-read-only t))
    (insert contents))

  ;; Other buffer: call whatever is bound to 'RET'
  (funcall (key-binding (kbd "RET"))))

(defun isend--send-dest-term (contents)
  ;; Move to the process mark
  (goto-char (process-mark (get-buffer-process (current-buffer))))

  ;; Insert the contents
  (let ((inhibit-read-only t))
    (insert contents))

  ;; Send input
  (term-send-input))

(defun isend--send-dest-vterm (contents)
  (vterm-send-string contents)
  (vterm-send-return))


(provide 'isend-mode)

;;; isend-mode.el ends here
