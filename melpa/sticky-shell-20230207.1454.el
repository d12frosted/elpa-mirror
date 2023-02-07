;;; sticky-shell.el --- Minor mode to keep track of previous prompt in your shell  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Andrew De Angelis

;; Author: Andrew De Angelis <bobodeangelis@gmail.com>
;; Maintainer: Andrew De Angelis <bobodeangelis@gmail.com>
;; URL: https://github.com/andyjda/sticky-shell
;; Package-Version: 20230207.1454
;; Package-Commit: 030535451b7c12eea3a94dfc1a439b8baa96944b
;; Version: 1.0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: processes, terminals, tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License Version 3,
;; as published by the Free Software Foundation.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a minor mode that creates a header in a shell buffer.
;; The header shows a previous prompt according to the customizable value of
;; `sticky-shell-get-prompt'.
;;
;; This is most useful when working with many lines of output:
;; you can ensure that the command corresponding to the top output-line
;; is always visible by setting `sticky-shell-get-prompt' to
;; `sticky-shell-prompt-above-visible' (its default value).
;;
;; To enable the mode, run `sticky-shell-mode' in any shell buffer.
;;
;; To enable the mode globally (for all shell buffers)
;; run `sticky-shell-global-mode'.
;;
;; `sticky-shell-mode' currently supports any mode derived from the following:
;; `shell-mode', `eshell-mode', `term-mode', `vterm-mode'.
;; It should be easy to add support for additional modes:
;; see `sticky-shell-supported-modes'.
;;
;; Because headers have to fit within one line, sometimes the final part of the
;; prompt is not visible.  To ensure that the prompt's beginning and end are
;; always both visible, you can use `sticky-shell-shorten-header-mode'.
;;
;; If you'd like this shorten-header mode to be enabled by default, you should
;; add `sticky-shell-shorten-header-set-mode' to `sticky-shell-mode-hook'
;;
;; Note that `sticky-shell-shorten-header-mode' doesn't work properly in
;; `term-mode' and `vterm-mode'. This is not because of an issue with
;; `sticky-shell-shorten-header-mode' itself, but because `sticky-shell-mode'
;; uses `(thing-at-point 'line)' to read a prompt: in terminal modes, this
;; function returns a line within the borders of a window rather than up to the
;; first newline character. The result is that the header will always be cut-off
;; at the window-border.
;; Right now I'd rather keep this general implementation simple rather than
;; overfit for these particular modes.
;; You can always define your own `sticky-shell-get-prompt' function that works
;; as desired: if this function returns a string that doesn't fit fully within
;; one line, `sticky-shell-shorten-header-mode' would work as usual.

;;; Code:

;;;; core
(defgroup sticky-shell nil
  "Display a sticky header with latest shell-prompt."
  :group 'terminals)

(defcustom sticky-shell-get-prompt
  #'sticky-shell-prompt-above-visible
  "Function used by `sticky-shell-mode' to pick the prompt to show in the header.
Available values are: `sticky-shell-latest-prompt',
`sticky-shell-prompt-above-visible',
`sticky-shell-prompt-above-cursor',
`sticky-shell-prompt-before-cursor'
or you can write your own function and assign it to this variable."
  :group 'sticky-shell
  :type 'function)

;; supported modes
(declare-function eshell-previous-prompt "ext:eshell")
(declare-function comint-previous-prompt "ext:comint")
(declare-function term-previous-prompt "ext:term")
(declare-function vterm-previous-prompt "ext:vterm")

(defcustom sticky-shell-supported-modes
  (list
   'eshell-mode #'eshell-previous-prompt
   'comint-mode #'comint-previous-prompt
   'term-mode #'term-previous-prompt
   'vterm-mode #'vterm-previous-prompt)
  "Property-list: each supported mode paired with its previous-prompt function.
This list is checked by `sticky-shell-mode' when setting the value of
`sticky-shell-previous-prompt-function'.
Note that some of these functions, like `vterm-previous-prompt',
require you to set the prompt's regexp first.
See the functions' own documentation for more info"
  :group 'sticky-shell
  :type 'plist)

(defvar sticky-shell-previous-prompt-function
  #'comint-previous-prompt
  "Function called to retrieve the previous propmt.
Varies depending on which mode the current major-mode is derived from.")

(defface sticky-shell-shorten-header-ellipsis
  '((t :inherit default))
  "Face used for the ellipsis shortening the sticky-shell header."
  :group 'sticky-shell)

(defun sticky-shell--current-line-trimmed ()
  "Return the current line and remove trailing whitespace."
  (let ((prompt (or (thing-at-point 'line) "")))
    ;; remove whitespace at the end of the line:
    (string-trim-right prompt "[ \t\n\r]+")))

(defun sticky-shell--previous-prompt (n)
  "Move to end of Nth previous prompt in the buffer.
Depending on the current mode, call `comint-previous-prompt'
or `eshell-previous-prompt'."
  (funcall sticky-shell-previous-prompt-function n))

;;;; get prompt
(defun sticky-shell-latest-prompt ()
  "Get the latest prompt that was run."
  (interactive)
  (save-excursion
    (goto-char (point-max))
    (forward-line -1)
    (sticky-shell--previous-prompt 1)
    (sticky-shell--current-line-trimmed)))

(defun sticky-shell-prompt-above-visible ()
  "Get the prompt above the top visible line in the current window.
This ensures that the prompt in the header corresponds to top output-line"
  (interactive)
  (save-excursion
    (goto-char (window-start))
    (sticky-shell--previous-prompt 1)
    (sticky-shell--current-line-trimmed)))

(defun sticky-shell-prompt-above-cursor ()
  "Get the prompt above the cursor's current line."
  (interactive)
  (save-excursion
    (move-beginning-of-line 1)
    (sticky-shell--previous-prompt 1)
    (sticky-shell--current-line-trimmed)))

;;;; shorten header
(defun sticky-shell--fit-within-line (header)
  "Shorten HEADER, ensuring its beginning and end are visible within the line.
The shortening logic is:
 - if the header already fits in the available space in the line:
   don't do anything
 - else:
 - get the difference between the header and the `window-max-chars-per-line'
 - divide the header in two
 - from each header-half, remove half of the difference (in characters)
 - now our header fits the line
 - add an ellipsis (\"...\") between the two halves
 - remove three chars from the second half to make room for the ellipsis
The \"...\" is propertized with the face `sticky-shell-shorten-header-ellipsis'"
  (let* ((header-length (length header))
         (diff (- header-length (window-max-chars-per-line))))
    (if (<= diff 0)
        header
      (format "%s%s%s"
              ;; first half of the header, minus half the difference
              (seq-take header
                        (- (/ header-length 2)
                           (/ diff 2)))
              (propertize "..." 'face 'sticky-shell-shorten-header-ellipsis)
              ;; second half of the header, minus half the difference
              ;; and making room for the three dots
              (seq-drop header
                        (+ (+ (/ header-length 2)
                              (/ diff 2))
                           3))))))

(defun sticky-shell--shorten-header ()
  "Apply `sticky-shell--fit-within-line' to `header-line-format'.
`header-line-format' should look like this:
\(:eval (funcall `sticky-shell-get-prompt')),
so we take the part after `eval'
and wrap it within `sticky-shell--fit-within-line'"
  (let ((header-function (cadr header-line-format)))
    (setq-local header-line-format
                `(:eval (sticky-shell--fit-within-line ,header-function)))))


(defun sticky-shell--restore-header ()
  "Remove `sticky-shell--fit-within-line' from `header-line-format'."
  (when (eq (caadr header-line-format) #'sticky-shell--fit-within-line)
    (let ((header-function (cadadr header-line-format)))
      (setq-local header-line-format
                  `(:eval ,header-function)))))

(defun sticky-shell-shorten-header-set-mode ()
  "Enable/disable `sticky-shell-shorten-header-mode' if appropriate.
Only enable `sticky-shell-shorten-header-mode' with `sticky-shell-mode' enabled.
When `sticky-shell-mode' is disabled,
make sure to disable `sticky-shell-shorten-header-mode'.
This is the function you should add to `sticky-shell-mode-hook'
if you want your header to default to shortened."
  (sticky-shell-shorten-header-mode
   (or (bound-and-true-p sticky-shell-mode) -1)))

;;;; modes
;;;###autoload
(define-minor-mode sticky-shell-mode
  "Minor mode to show the previous prompt as a sticky header.
Which prompt to pick depends on the value of `sticky-shell-get-prompt'."
  :group 'comint
  :global nil
  :lighter nil
  (if sticky-shell-mode
      (setq-local header-line-format
                  '(:eval ; question: why do we use :eval instead of `eval' here??
                    (funcall sticky-shell-get-prompt))
                  sticky-shell-previous-prompt-function
                  ;; TODO: is plist-get the best approach here?
                  ;; the fact we have to use _ignored_args makes it kinda hacky
                  (or (plist-get
                       sticky-shell-supported-modes nil
                       (lambda (mode _ignored_arg)
                         (derived-mode-p mode)))
                      ;; default to `comint-previous-prompt'
                      #'comint-previous-prompt))
    (setq-local header-line-format nil
                sticky-shell-shorten-header-mode nil)))

;;;###autoload
(define-globalized-minor-mode sticky-shell-global-mode
  sticky-shell-mode sticky-shell--global-on)

(defun sticky-shell--global-on ()
  "Enable `sticky-shell-mode' if appropriate for the buffer."
  (when (plist-get
         sticky-shell-supported-modes nil
         (lambda (mode _ignored_arg)
           (derived-mode-p mode)))
    (sticky-shell-mode +1)))


(define-minor-mode sticky-shell-shorten-header-mode
  "Minor mode to shorten the header, making the beginning and end both visible.
Because this mode depends on `sticky-shell-mode',
it is good practice to set it using `sticky-shell-shorten-header-set-mode',
which ensures to only enable it if `sticky-shell-mode' is already enabled,
while making sure to disable it when `sticky-shell-mode' is disabled."
  :group 'sticky-shell
  :global nil
  :lighter nil
  (cond (sticky-shell-mode
         (if sticky-shell-shorten-header-mode
             (sticky-shell--shorten-header)
           (sticky-shell--restore-header)))
        (sticky-shell-shorten-header-mode
         (progn
           (message
            "Cannot enable `sticky-shell-shorten-header-mode' while `sticky-shell-mode' is disabled")
           (setq-local sticky-shell-shorten-header-mode nil)))))


(provide 'sticky-shell)
;;; sticky-shell.el ends here
