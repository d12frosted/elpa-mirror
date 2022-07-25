;;; robot-log.el --- Major mode for viewing RobotFramework debug log files -*- lexical-binding: t -*-

;; Copyright © 2022 Maxim Cournoyer <maxim.cournoyer@gmail.com>

;; Keywords: convenience files
;; Package-Version: 20220719.1301
;; Package-Commit: 26da47597aa97be9649cb60f4da6d94d47d0c0ac
;; Homepage: https://git.sr.ht/~apteryx/emacs-robot-log
;; Package-Requires: ((emacs "28.1"))
;; Version: 0.1.4
;; SPDX-License-Identifier: GPL-3.0-or-later

;; robot-log is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; robot-log is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with robot-log.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provides a major mode (`robot-log-mode') for highlighting
;; RobotFramework debug logs, as produced by
;; (https://raw.githubusercontent.com/robotframework/
;; robotframework/master/src/robot/output/debugfile.py).  This mode is
;; heavily inspired by `guix-build-log' from the `emacs-guix' package;
;; thanks to its authors!

;;; Code:

;;; Workaround for https://debbugs.gnu.org/cgi/bugreport.cgi?bug=56473.
(require 'subr-x)

(defvar robot-log-handling-syntaxes (list "TRY")
  "The syntaxes likely to handle failures.")

(defvar robot-log-handling-keywords
  (list "BuiltIn.Run Keyword And Expect Error"
        "BuiltIn.Run Keyword And Ignore Error"
        "BuiltIn.Wait Until Keyword Succeeds"
        "BuiltIn.Run Keyword And Continue On Failure"
        "BuiltIn.Run Keyword And Return Status"
        "BuiltIn.Run Keyword And Warn On Failure")
  "The keywords likely to handle failures.")


;;;
;;; Regexps.
;;;

(defvar robot-log-timestamp-regexp
  "^[0-9]\\{8\\} [0-9]\\{2\\}:[0-9]\\{2\\}:[0-9]\\{2\\}\\.[0-9]\\{3\\}"
  "Regexp for the message timestamp.")

(defvar robot-log-level-regexp
  "\\(NONE\\|TRACE\\|DEBUG\\|INFO\\|WARN\\|ERROR\\|FAIL\\|SKIP\\)")

(defun robot-log-level-regexp (&optional level text type name)
  "Return a regexp to match a marker for LEVEL, TEXT, TYPE and NAME.
LEVEL should be a base 0 integer.  TEXT defaults to \"START\"; it
should be the opening text such as \"START\" or \"END\".  TYPE
defaults to ' \\([^:]*\\): ', which matches any type name.  NAME
defaults to the '\\([^[(]*\\) ', which matches any keyword name.
When LEVEL is not provided, the regexp matches for any level."
  (let ((hyphen-regexp (if level
                           (string-join (make-list level "-"))
                         "-*"))
        (text (or text "START"))
        (type (concat " " (or type "\\([^:]*\\): ")))
        (name (or name "\\([^[(]*\\) ")))
    (concat robot-log-timestamp-regexp " - "
            robot-log-level-regexp " - "
            "\\+\\(" hyphen-regexp "\\) " text
            ;; Match the keyword type and name, if any, as 3rd and 4th
            ;; groups.
            type                  ;keyword type, e.g.: TEST or KEYWORD
            name)))               ;name, e.g.: BuiltIn.Log or ""

(defun robot-log-start-level-regexp (&optional level type name)
  "Return a regexp matching a START directive.
LEVEL, TYPE and NAME are to be used as documented for
function `robot-log-level-regexp'."
  (robot-log-level-regexp level "START" type name))

(defun robot-log-end-level-regexp (&optional level type name)
  "Return a regexp matching an END directive.
LEVEL, TYPE and NAME are to be used as documented for function
`robot-log-level-regexp'."
  (robot-log-level-regexp level "END" type name))

(defvar robot-log-none-level-regexp " - \\(NONE\\) - "
  "Regexp for the none level text.")

(defvar robot-log-trace-level-regexp " - \\(TRACE\\) - "
  "Regexp for the trace level text.")

(defvar robot-log-debug-level-regexp " - \\(DEBUG\\) - "
  "Regexp for the debug level text.")

(defvar robot-log-info-level-regexp " - \\(INFO\\) - "
  "Regexp for the info level text.")

(defvar robot-log-warning-level-regexp " - \\(WARN\\) - "
  "Regexp for the warning level text.")

(defvar robot-log-error-level-regexp " - \\(ERROR\\) - "
  "Regexp for the error level text.")

(defvar robot-log-fail-level-regexp " - \\(FAIL\\) - "
  "Regexp for the fail level text.")

(defvar robot-log-skip-level-regexp " - \\(SKIP\\) - "
  "Regexp for the skip level text.")

(defvar robot-log-keyword-start-regexp
  "\\(\\+-* START KEYWORD:\\) \\(.*\\) \\[\\(.*\\)\\]"
  "Regexp for the start line of a keyword.")

(defvar robot-log-keyword-end-regexp
  "\\(\\+-* END KEYWORD:\\) \\(.*\\) (\\(.*\\))"
  "Regexp for the ending line of a keyword.")

(defvar robot-log-start-regexp
  (robot-log-start-level-regexp)
  "Regexp for the start line of any RobotFramework item.")

(defvar robot-log-builtin-keyword-regexp
  "\\+-* \\(START\\|END\\) KEYWORD: \\(BuiltIn.*\\) [[()]")

(defvar robot-log-imenu-generic-expression
  `((nil robot-log-keyword-start-regexp 1))
  "Imenu generic expression for `robot-log-mode'.")


;;;
;;; Font lock configuration.
;;;

(defgroup robot-log-faces nil
  "Faces for `robot-log-mode'."
  :group 'robot-log)

(defface robot-log-keyword-start
  '((default :inherit font-lock-function-name-face))
  "Face for RobotFramework keywords (start)."
  :group 'robot-log-faces)

(defface robot-log-keyword-arguments
  '((default :foreground "LightBlue"))
  "Face for RobotFramework keyword arguments."
  :group 'robot-log-faces)

(defface robot-log-keyword-end
  '((default :inherit font-lock-function-name-face))
  "Face for RobotFramework keywords (end)."
  :group 'robot-log-faces)

(defface robot-log-builtin-keyword
  '((default :inherit font-lock-builtin-face))
  "Face for RobotFramework builtin keywords."
  :group 'robot-log-faces)

(defface robot-log-keyword-exit-status
  '((default :inherit compilation-mode-line-exit))
  "Face for RobotFramework keyword exit statuses."
  :group 'robot-log-faces)

(defface robot-log-none-level
  '((default))
  "Face for RobotFramework none level text."
  :group 'robot-log-faces)

(defface robot-log-trace-level
  '((default))
  "Face for RobotFramework trace level text."
  :group 'robot-log-faces)

(defface robot-log-debug-level
  '((default))
  "Face for RobotFramework debug level text."
  :group 'robot-log-faces)

(defface robot-log-info-level
  '((default :inherit compilation-info))
  "Face for RobotFramework info level text."
  :group 'robot-log-faces)

(defface robot-log-warning-level
  '((default :inherit compilation-warning))
  "Face for RobotFramework warning level text."
  :group 'robot-log-faces)

(defface robot-log-error-level
  '((default :inherit compilation-error))
  "Face for RobotFramework error level text."
  :group 'robot-log-faces)

(defface robot-log-fail-level
  '((default :inherit compilation-error))
  "Face for RobotFramework fail level text."
  :group 'robot-log-faces)

(defface robot-log-skip-level
  '((default :foreground "DarkGoldenrod"))
  "Face for RobotFramework skip level text."
  :group 'robot-log-faces)

(defvar robot-log-font-lock-keywords
  `((,robot-log-trace-level-regexp
     (1 'robot-log-trace-level))
    (,robot-log-debug-level-regexp
     (1 'robot-log-debug-level))
    (,robot-log-info-level-regexp
     (1 'robot-log-info-level))
    (,robot-log-warning-level-regexp
     (1 'robot-log-warning-level))
    (,robot-log-error-level-regexp
     (1 'robot-log-error-level))
    (,robot-log-fail-level-regexp
     (1 'robot-log-fail-level))
    (,robot-log-skip-level-regexp
     (1 'robot-log-skip-level))
    (,robot-log-none-level-regexp
     (1 'robot-log-none-level))
    (,robot-log-keyword-start-regexp
     (2 'robot-log-keyword-start)
     (3 'robot-log-keyword-arguments))
    (,robot-log-keyword-end-regexp
     (2 'robot-log-keyword-end)
     (3 'robot-log-keyword-exit-status))
    (,robot-log-builtin-keyword-regexp
     (2 'robot-log-builtin-keyword t)))
  "A list of `font-lock-keywords' for `robot-log-mode'.")


;;;
;;; Navigation.
;;;

(defun robot-log-search-forward (regexp arg)
  "Like `re-search-forward', but with normalized cursor position.
REGEXP and ARG are to be used as documented by function
`re-search-forward'."
  (let ((position (or (save-excursion
                        (end-of-line (if (> arg 0) 1 0)) ;skip current line
                        (re-search-forward regexp nil 'noerror (or arg 1)))
                      (user-error "No more items"))))
    (goto-char position)
    (beginning-of-line)))

(defun robot-log-next (&optional arg)
  "Move to the next start mark, repeating ARG times.
Move backward when ARG is negative.  It returns a list containing
the keyword level, its type and its name, when available."
  (interactive "^p")
  (when (zerop arg) (user-error "Arg cannot be 0"))
  (robot-log-search-forward robot-log-start-regexp arg)
  (list (length (match-string 2))
        (substring-no-properties (match-string 3))
        (substring-no-properties (match-string 4))))

(defun robot-log-previous (&optional arg)
  "Move to the previous start mark, repeating ARG times.
Move backward when ARG is negative."
  (interactive "^p")
  (when (zerop arg) (user-error "Arg cannot be 0"))
  (robot-log-next (- (or arg 1))))

(defun robot-log-current-start-level ()
  "Return the current line start marker level (depth)."
  (let ((hyphens (or (save-excursion
                       (beginning-of-line)
                       (re-search-forward robot-log-start-regexp
                                          (point-at-eol) 'noerror)
                       (match-string 2))
                     (user-error "No start marker on current line"))))
    (length hyphens)))

(defun robot-log-next-same-level (&optional arg)
  "Move to the next keyword which is at the same depth.
The search is repeated ARG times.  Move backward when ARG is negative."
  (interactive "^p")
  (when (zerop arg) (user-error "Arg cannot be 0"))
  (let ((level (robot-log-current-start-level)))
    (robot-log-search-forward (robot-log-start-level-regexp level) arg)))

(defun robot-log-previous-same-level (&optional arg)
  "Move to the previous keyword which is at the same depth.
The search is repeated ARG times.  Move backward when ARG is
negative."
  (interactive "^p")
  (when (zerop arg) (user-error "Arg cannot be 0"))
  (robot-log-next-same-level (- (or arg 1))))

(defun robot-log-search-start-backward ()
  "Return the starting marker and its level on the current line or before.
The result is returned as a pair."
  (save-excursion
    (end-of-line)
    (let ((start (re-search-backward robot-log-start-regexp nil 'noerror)))
      (unless start
        (user-error "No start marker on current line or before"))
      (goto-char start)
      (end-of-line)         ;the opening line is preserved as a header
      (cons (point) (length (match-string 2))))))

(defun robot-log-start-end-points ()
  "Return the start and end points surrounding the current marker."
  (let* ((start-and-level (robot-log-search-start-backward))
         (start (car start-and-level))
         (level (cdr start-and-level))
         (end-regexp (robot-log-end-level-regexp level)))
    (save-excursion
      (end-of-line)
      (let ((end (re-search-forward end-regexp nil 'noerror)))
        (unless end
          (user-error "No end keyword/marker"))
        (goto-char end)
        (cons start (point-at-eol))))))

(defun robot-log-hide ()
  "Hide the body of the current item."
  (interactive)
  (let* ((start-end (robot-log-start-end-points))
         (start (car start-end))
         (end (cdr start-end)))
    (remove-overlays start end 'invisible t)
    (let ((overlay (make-overlay start end)))
      (overlay-put overlay 'evaporate t)
      (overlay-put overlay 'invisible t))))

(defun robot-log-show ()
  "Show the body of the current item."
  (interactive)
  (let ((start-end (robot-log-start-end-points)))
    (remove-overlays (car start-end) (cdr start-end) 'invisible t)))

(defun robot-log-unhide-all ()
  "Unhide everything."
  (interactive)
  (remove-overlays (point-min) (point-max) 'invisible t))

(defun robot-log-hidden-p ()
  "Return non-nil, if the body of the current item is hidden."
  (let ((start (car (robot-log-start-end-points))))
    (seq-find (lambda (overlay)
                (overlay-get overlay 'invisible))
              (overlays-at start))))

(defun robot-log-toggle ()
  "Toggle the body of the current item."
  (interactive)
  (if (robot-log-hidden-p)
      (robot-log-show)
    (robot-log-hide)))

(defun robot-log-fold-level (level)
  "Fold items corresponding to LEVEL or higher."
  (interactive "Nfold level: ")
  (robot-log-unhide-all)
  (let ((regexp (robot-log-level-regexp nil level)))
    (goto-char (point-min))
    (named-let next ((position (re-search-forward regexp nil 'noerror)))
      (when position
        (goto-char position)
        (robot-log-hide)
        (next (re-search-forward regexp nil 'noerror))))
    (goto-char (point-min))))

(defun robot-log-next-error (&optional arg)
  "Go to the next error, repeating ARG times.
When ARG is negative, reverse the search direction."
  (interactive "^p")
  (when (zerop arg) (user-error "Arg cannot be 0"))
  (robot-log-search-forward
   (concat "\\(" robot-log-error-level-regexp
           "\\|" robot-log-fail-level-regexp "\\)") arg))

(defun robot-log-previous-error (&optional arg)
  "Move to the previous error, repeating ARG times.
When ARG is negative, reverse the search direction."
  (interactive "^p")
  (when (zerop arg) (user-error "Arg cannot be 0"))
  (robot-log-next-error (- (or arg 1))))

(defun robot-log-handling-keyword-p (keyword)
  "Check whether the KEYWORD is for handling errors."
  (member keyword robot-log-handling-keywords))

(defun robot-log-handling-syntax-p (syntax)
  "Check whether the SYNTAX is for handling errors."
  (member syntax robot-log-handling-syntaxes))

;;; This variable holds the sections of the file which are covered by
;;; error handling keywords or syntaxes.
(defvar-local robot-log--handled-lines nil)

(defun robot-log-merge-spans (spans)
  "Simplify SPANS, merging overlapping entries together."
  (let ((sorted-spans (sort spans (lambda (x y)
                                    (< (car x) (car y))))))
    (reverse
     (seq-reduce (lambda (results val)
                   (let* ((start (car val))
                          (end (cdr val))
                          (prev-val (car results))
                          (prev-start (and prev-val (car prev-val)))
                          (prev-end (and prev-val (cdr prev-val))))
                     (if prev-val
                         (if (>= prev-end start)
                             (cons (cons prev-start (max prev-end end))
                                   (cdr results))
                           (cons val results))
                       (cons val results))))
                 sorted-spans '()))))

(defun robot-log-compute-handled-lines ()
  "Find out which lines of the log files are nested in handling keywords.

The result is computed only once and cached."
  (unless robot-log--handled-lines
    (setq
     robot-log--handled-lines
     (robot-log-merge-spans
      (save-excursion
        (seq-remove
         #'not
         (mapcan
          (lambda (item)
            (let* ((type (and (member item robot-log-handling-syntaxes)
                              item))
                   (name (and (not type) item)))
              (named-let next ((start (point-min))
                               (handled-spans '()))
                (goto-char start)
                (let ((start-regexp (robot-log-start-level-regexp nil type
                                                                  name)))
                  (if (re-search-forward start-regexp nil 'noerror)
                      (let* ((pos (point))
                             (level (length (match-string 2)))
                             (line (line-number-at-pos))
                             (end-regexp (robot-log-end-level-regexp
                                          level type name)))
                        (re-search-forward end-regexp nil)
                        (next pos (cons (cons line (line-number-at-pos))
                                        handled-spans)))
                    (reverse handled-spans))))))
          (append robot-log-handling-syntaxes robot-log-handling-keywords)))))))
  robot-log--handled-lines)

(defun robot-log-handled-p (&optional line)
  "Predicate to check if LINE is subject to error handling."
  (robot-log-compute-handled-lines)
  (let ((line (or line (line-number-at-pos))))
    (seq-find (lambda (span)
                (let ((start (car span))
                      (end (cdr span)))
                  (and (>= line start)
                       (<= line end))))
              robot-log--handled-lines)))

(defun robot-log-next-unhandled-error (&optional arg)
  "Go to the next un-handled error, repeating ARG times.
When ARG is negative, reverse the search direction.  Un-handled
means that the error doesn't have any error handling parent
syntax or keywords."
  (interactive "^p")
  (when (zerop arg) (user-error "Arg cannot be 0"))
  (robot-log-compute-handled-lines)
  (let ((unhandled-error
         (save-excursion
           (named-let iter ((count 1))
             (let ((position
                    (named-let next ((pos nil))
                      (if pos
                          pos
                        (robot-log-next-error (if (< arg 0) -1 1))
                        (next (if (not (robot-log-handled-p))
                                  (point)
                                nil))))))
               (if (< count (abs arg))
                   (iter (1+ count))
                 position))))))
    (when unhandled-error
      (goto-char unhandled-error))))

(defun robot-log-previous-unhandled-error (&optional arg)
  "Go to the previous un-handled error, repeating ARG times.
When ARG is negative, reverse the search direction.  Un-handled
means that the error doesn't have any error handling parent
syntax or keywords."
  (interactive "^p")
  (when (zerop arg) (user-error "Arg cannot be 0"))
  (robot-log-next-unhandled-error (- (or arg 1))))

(defvar robot-log-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "n") 'robot-log-next)
    (define-key map (kbd "p") 'robot-log-previous)
    (define-key map (kbd "N") 'robot-log-next-same-level)
    (define-key map (kbd "P") 'robot-log-previous-same-level)
    (define-key map (kbd "TAB") 'robot-log-toggle)
    (define-key map (kbd "l") 'robot-log-fold-level)
    (define-key map (kbd "L") 'robot-log-unhide-all)
    (define-key map (kbd "e") 'robot-log-next-error)
    (define-key map (kbd "E") 'robot-log-previous-error)
    (define-key map (kbd "u") 'robot-log-next-unhandled-error)
    (define-key map (kbd "U") 'robot-log-previous-unhandled-error)
    map)
  "The default key map for the `robot-log-mode' minor mode.")

;;; Append to the auto-mode alist, because many modes may want to own
;;; the .log file extension and .log is not mandatory for
;;; RobotFramework debug log files.
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.log\\'" . robot-log-mode) t)

;;;###autoload
(define-derived-mode robot-log-mode special-mode
  "Robot-Log"
  "Major mode for viewing RobotFramework debug logs.

\\{robot-log-mode-map}"
  (setq font-lock-defaults `(,robot-log-font-lock-keywords))
  (setq imenu-generic-expression robot-log-imenu-generic-expression))

(provide 'robot-log)

;;; robot-log.el ends here
