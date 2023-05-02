;;; bbww.el --- Improved word-jumping functions -*- lexical-binding: t -*-

;; Author: Nathan Nichols
;; Maintainer: Nathan Nichols
;; Version: 1.0
;; Package-Version: 20230501.1455
;; Package-Commit: 1b385b4224369358cba9b9bac7ba480df75b945e
;; Package-Requires: ((mwim "1.0") (emacs "24.3"))

;; Homepage: http://chud.wtf
;; Keywords: convenience, files


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
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

;; Provides alternatives to `forward-word', `backward-word',
;; `backward-kill-word', `forward-kill-word' that are generally less
;; greedy, especially when the backward region contains a newline.

;; commentary

;;; Code:

(require 'mwim)

(defun bbww-kill-backward-whitespace ()
  "Kill block of whitespace before point.
Useful for killing blocks of whitespace that are within a single line."
  (interactive "*")
  (delete-region (point)
                 (progn (skip-chars-backward " \t\r\n\v\f") (point))))


(defun bbww-get-forward-region (&optional arg)
  "Return the region between point before  `forward-word'.
`ARG' is argument passed to `forward-word'."
  (interactive)
  (let ((p1 (point)))
         (forward-word arg)
         (let* ((p2 (point))
                (forward-region (buffer-substring-no-properties p1 p2)))
           (goto-char p1)
           forward-region)))

(defun bbww-get-backward-region (&optional arg)
  "Return the region between point before/after calling `backward-word' `ARG'."
  (interactive)
  (bbww-get-forward-region (- (or arg 1))))

(defun bbww-get-curr-line ()
  "Return current line as a string."
  (buffer-substring (line-beginning-position) (line-end-position)))

(defun bbww-looking-bidi (regexp dir)
  "Passes REGEXP to either `looking-at' or `looking-back' depending on DIR."
  (cond
   ((> dir 0) (looking-back regexp nil))
   ((< dir 0) (looking-at regexp))))

(defun bbww-mwim-bidi (dir)
  "Call either `mwim-end' or `mwim-beginning' depending on DIR."
  (cond
   ((> dir 0) (mwim-end))
   ((< dir 0) (mwim-beginning))))

(defun bbww-skip-chars-bidi (chars dir)
  "Passes CHARS to `skip-chars-forward' or `skip-chars-backward' depending on DIR."
  (cond
     ((> 0 dir) (skip-chars-forward chars))
     ((< 0 dir) (skip-chars-backward chars))))

(defun bbww-skip-whitespace-block (&optional arg)
  "Passes ARG to `bbww-skip-chars-bidi' if provided."
  (let ((arg (or arg 1)))
    (bbww-skip-chars-bidi " \t\r\n\v\f" arg)))

(defun bbww-walk-back-line (&optional arg)
  "Move to the `mwim-end' of the last non-whitespace line before current line.
ARG specifies the direction."
  (forward-line (- arg))
  (bbww-mwim-bidi arg)
  (if (string-match-p (bbww-get-curr-line) "\s+")
      (bbww-skip-whitespace-block arg)))

(defun bbww-backward-word (&optional arg)
  "Make `backward-word' less greedy when moving across lines.
ARG specificies direction."
  (interactive "^p") ;; ^ = handle marker/region correctly
  (let* (
         (arg (or arg 1))
         (bw-region (bbww-get-backward-region arg)))
    (cond ;; First, see if there is just whitespace ahead of the point.
          ((bbww-looking-bidi "\s*\n+\s*" arg) (bbww-skip-whitespace-block arg))

          ;; If not on whitepace but still deleting across lines, move to the
          ;; mwim-start/end of the last non-whitespace line before current line.
          ((string-match-p "\n" bw-region) (bbww-walk-back-line arg))
          ;; If here, just do backward word because the point will
          ;; stay within the same line as it started.
          (t (backward-word arg))))
  (point))

(defun bbww-forward-word (&optional arg)
  "A less greedy version of `forward-word'.
ARG is passed to `bbww-backward-word' if provided."
  (interactive "^") ;; ^ = handle marker/region correctly
  (let ((arg (or arg -1)))
    (bbww-backward-word arg)))

;;

;;!
;; TEST CASE: put point on the above "!" and do bbww-backward-word. See if it works correctly.

(defun bbww-backward-kill-word (arg)
  "Like `backward-kill-word' but less greedy.
ARG is passed to `bbww-backward-word' if provided."
  (interactive "*p")
  (let ((arg (or arg 1)))
    (delete-region (point)
                   (bbww-backward-word arg))))

(defun bbww-forward-line ()
  "Move forward one line and then call `mwim-end'."
  (interactive "^")
  (forward-line -1)
  (mwim-end))

(defun bbww-backward-line ()
  "Move backward one line and then call `mwim-end'."
  (interactive "^")
  (forward-line 1)
  (mwim-end))

;; Crash course on key bindings:
;;
;; - Key bindings are stored in dictionaries called keymaps
;; - The global map is the default keymap
;; - Major and minor modes may define keymaps
;; - Minor mode keymaps take precedence over major mode keymaps
;;
;; Thus, to avoid problems such as the Python major mode setting
;; <C-backspace> to backward-kill-word, we have the option of
;; overwriting backward-kill-word or defining the bindings in a minor
;; mode which is active everywhere. The minor mode method is
;; preferable to changing the behavior of a built-in function.

(defcustom bbww-mode-lighter " bbww"
  "Command `editorconfig-mode' lighter string."
  :type 'string
  :group 'bbww)

(defvar bbww-keymap (let ((km (make-keymap)))
                 (define-key km (kbd "<C-left>") #'bbww-backward-word)
                 (define-key km (kbd "<C-right>") #'bbww-forward-word)
                 (define-key km (kbd "<C-backspace>") #'bbww-backward-kill-word)
                 (define-key km (kbd "M-DEL") #'bbww-kill-backward-whitespace)
                 km))

;;;###autoload
(define-minor-mode bbww-mode
  "Minor mode for better backward word (bbww)."
  :global t
  :lighter bbww-mode-lighter
  :keymap bbww-keymap
  :group 'bbww
  ;; This basically makes bbww-keymap active everywhere.
  ;; The keymaps in `emulation-mode-map-alists' take precedence over
  ;; `minor-mode-map-alist', so can't be overriden by a minor mode.
  (if bbww-mode
      (add-to-list 'emulation-mode-map-alists `((bbww-mode . ,bbww-keymap)))
    (delete `((bbww-mode . ,bbww-keymap)) emulation-mode-map-alists)))

;;;###autoload
(defun bbww-init-global-bindings ()
  "Set up recommended keybindings."
  (interactive)
  ;; Define in global key-map instead so that they'll be overwritten
  ;; by major mode For example, <M-left> and <M-right> are used by
  ;; org-mode, and we don't want to break org-mode unneccesarily.
  ;; TODO: Implement functions that replace `org-metaleft',
  ;; `org-metaright', `org-metaup' and `org-metadown'
  (define-key (current-global-map) (kbd "<M-up>") #'bbww-forward-line)
  (define-key (current-global-map) (kbd "<M-down>") #'bbww-backward-line)
  (define-key (current-global-map) (kbd "<M-left>") #'bbww-backward-word)
  (define-key (current-global-map) (kbd "<M-right>") #'bbww-forward-word))

(provide 'bbww)
;;; bbww.el ends here
