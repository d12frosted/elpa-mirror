;;; sticky-shell.el --- Minor mode that displays the latest shell-prompt in a header -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Andrew De Angelis

;; Author: Andrew De Angelis <bobodeangelis@gmail.com>
;; Maintainer: Andrew De Angelis <bobodeangelis@gmail.com>
;; URL: https://github.com/andyjda/sticky-shell
;; Package-Version: 20230116.1701
;; Package-Commit: 66310eadb69cf229e1b0a104bd024092123dddf3
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.4"))
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
;; The header shows a previous prompt according to the value of
;; `sticky-shell-get-prompt'.
;; This is most useful when working with many lines of output:
;; setting `sticky-shell-get-prompt' to `sticky-shell-prompt-above-visible'
;; will ensure that the command corresponding to the top output-line
;; is always visible.
;; The mode can be set globally (for all shell buffers)
;; with `sticky-shell-global-mode'.

;;; Code:
(eval-when-compile
  (require 'eshell)
  (require 'comint))

(declare-function eshell-previous-prompt "ext:eshell")
(declare-function comint-previous-prompt "ext:comint")

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


(defun sticky-shell--current-line-trimmed ()
  "Return the current line and remove trailing whitespace."
  (let ((prompt (or (thing-at-point 'line) "")))
    ;; remove whitespace at the end of the line:
    (string-trim-right prompt "[ \t\n\r]+")))

(defun sticky-shell--previous-prompt (n)
  "Move to end of Nth previous prompt in the buffer.
Depending on the current mode, call `comint-previous-prompt'
or `eshell-previous-prompt'."
  (if (derived-mode-p 'eshell-mode)
      (eshell-previous-prompt n)
    (comint-previous-prompt n)))

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

;;;###autoload
(define-minor-mode sticky-shell-mode
  "Minor mode to show the previous prompt as a sticky header.
Which prompt to pick depends on the value of `sticky-shell-get-prompt'."
  :group 'comint
  :global nil
  :lighter nil
  (if sticky-shell-mode
      (setq-local header-line-format
                  '(:eval
                    (funcall sticky-shell-get-prompt)))
    (setq-local header-line-format nil)))

;;;###autoload
(define-globalized-minor-mode sticky-shell-global-mode
  sticky-shell-mode sticky-shell--global-on)

(defun sticky-shell--global-on ()
  "Enable `sticky-shell-mode' if appropriate for the buffer."
  (when (or (derived-mode-p 'comint-mode)
            (derived-mode-p 'eshell-mode))
    (sticky-shell-mode +1)))

(provide 'sticky-shell)
;;; sticky-shell.el ends here
