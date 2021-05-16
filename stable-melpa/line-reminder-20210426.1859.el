;;; line-reminder.el --- Line annotation for changed and saved lines  -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2021  Shen, Jen-Chieh
;; Created date 2018-05-25 15:10:29

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Line annotation for changed and saved lines.
;; Keyword: annotation line number linum reminder highlight display
;; Version: 0.4.5
;; Package-Requires: ((emacs "24.4") (indicators "0.0.4") (fringe-helper "1.0.1"))
;; URL: https://github.com/jcs-elpa/line-reminder

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
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
;;
;; Line annotation for changed and saved lines.
;;

;;; Code:

(require 'cl-lib)
(require 'fringe-helper)

(defgroup line-reminder nil
  "Line annotation for changed and saved lines."
  :prefix "line-reminder-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/line-reminder"))

(defcustom line-reminder-show-option 'linum
  "Option to show indicators in buffer."
  :group 'line-reminder
  :type '(choice (const :tag "linum" linum)
                 (const :tag "indicators" indicators)))

(defface line-reminder-modified-sign-face
  `((t :foreground "#EFF284"))
  "Modifed sign face."
  :group 'line-reminder)

(defface line-reminder-saved-sign-face
  `((t :foreground "#577430"))
  "Modifed sign face."
  :group 'line-reminder)

(defcustom line-reminder-modified-sign-priority 10
  "Display priority for modified sign."
  :type 'integer
  :group 'line-reminder)

(defcustom line-reminder-saved-sign-priority 1
  "Display priority for saved sign."
  :type 'integer
  :group 'line-reminder)

(defcustom line-reminder-linum-format "%s "
  "Format to display annotation using `linum`."
  :type 'string
  :group 'line-reminder)

(defcustom line-reminder-modified-sign "▐"
  "Modified sign."
  :type 'string
  :group 'line-reminder)

(defcustom line-reminder-saved-sign "▐"
  "Saved sign."
  :type 'string
  :group 'line-reminder)

(fringe-helper-define 'line-reminder-bitmap nil
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx.."
  "..xxx..")

(defcustom line-reminder-fringe-placed 'left-fringe
  "Line indicators fringe location."
  :type '(choice (const :tag "On the left fringe" left-fringe)
                 (const :tag "On the right fringe" right-fringe))
  :group 'line-reminder)

(defcustom line-reminder-fringe 'line-reminder-bitmap
  "Line indicators fringe symbol."
  :type 'symbol
  :group 'line-reminder)

(defcustom line-reminder-ignore-buffer-names
  '("[*]Backtrace[*]"
    "[*]Buffer List[*]"
    "[*]Checkdoc Status[*]"
    "[*]Echo Area"
    "[*]helm"
    "[*]Help[*]"
    "magit[-]*[[:ascii:]]*[:]"
    "[*]Minibuf-"
    "[*]Packages[*]"
    "[*]run[*]"
    "[*]shell[*]"
    "[*]undo-tree[*]")
  "Buffer Name list you want to ignore this mode."
  :type 'list
  :group 'line-reminder)

(defcustom line-reminder-disable-commands '()
  "List of commands that wouldn't take effect from this package."
  :type 'list
  :group 'line-reminder)

(defvar-local line-reminder--change-lines '()
  "List of line that change in current temp buffer.")

(defvar-local line-reminder--saved-lines '()
  "List of line that saved in current temp buffer.")

(defvar-local line-reminder--before-max-pt -1
  "Record down the point max for out of range calculation.")

(defvar-local line-reminder--before-begin-pt -1
  "Record down the before begin point.")

(defvar-local line-reminder--before-end-pt -1
  "Record down the before end point.")

(defvar-local line-reminder--before-max-linum -1
  "Record down the before maximum line number.")

(defvar-local line-reminder--before-begin-linum -1
  "Record down the before begin line number.")

(defvar-local line-reminder--before-end-linum -1
  "Record down the before end line number.")

;;; Util

(defun line-reminder--use-indicators-p ()
  "Return non-nil if using indicator, else return nil."
  (equal line-reminder-show-option 'indicators))

(defun line-reminder--line-number-at-pos (&optional pos)
  "Return line number at POS with absolute as default."
  (line-number-at-pos pos t))

(defun line-reminder--total-line ()
  "Return current buffer's maxinum line."
  (line-reminder--line-number-at-pos line-reminder--before-max-pt))

(defun line-reminder--contain-list-string-regexp (in-list in-str)
  "Return non-nil if IN-STR is listed in IN-LIST.

This function uses `string-match-p'."
  (cl-some (lambda (elm) (string-match-p elm in-str)) in-list))

(defun line-reminder--contain-list-integer (in-list in-int)
  "Return non-nil if IN-INT is listed in IN-LIST."
  (cl-some (lambda (elm) (= elm in-int)) in-list))

(defun line-reminder--mark-line-by-linum (ln fc)
  "Mark the line LN by using face name FC."
  (let ((inhibit-message t) (message-log-max nil))
    (ind-create-indicator-at-line ln
                                  :managed t
                                  :dynamic t
                                  :relative nil
                                  :fringe line-reminder-fringe-placed
                                  :bitmap line-reminder-fringe
                                  :face fc
                                  :priority
                                  (cl-case fc
                                    (line-reminder-modified-sign-face
                                     line-reminder-modified-sign-priority)
                                    (line-reminder-saved-sign-face
                                     line-reminder-saved-sign-priority)))))

(defun line-reminder--ind-remove-indicator-at-line (line)
  "Remove the indicator on LINE."
  (save-excursion
    (goto-char (point-min))
    (forward-line (1- line))
    (line-reminder--ind-remove-indicator (point))))

(defun line-reminder--ind-delete-dups ()
  "Remove duplicates for indicators overlay once."
  (when (line-reminder--use-indicators-p)
    (let ((record-lst '()) (new-lst '()) (mkr nil) (mkr-pos -1))
      (dolist (ind ind-managed-absolute-indicators)
        (setq mkr (car ind))
        (setq mkr-pos (marker-position mkr))
        (if (line-reminder--contain-list-integer record-lst mkr-pos)
            (remove-overlays mkr-pos mkr-pos 'ind-indicator-absolute t)
          (push mkr-pos record-lst)
          (push ind new-lst)))
      (setq ind-managed-absolute-indicators new-lst))))

(defun line-reminder--ind-remove-indicator (pos)
  "Remove the indicator to position POS."
  (save-excursion
    (goto-char pos)
    (let ((start-pt (1+ (line-beginning-position))) (end-pt (line-end-position))
          (remove-inds '()))
      (dolist (ind ind-managed-absolute-indicators)
        (let* ((mkr (car ind)) (mkr-pos (marker-position mkr)))
          (when (and (>= mkr-pos start-pt) (<= mkr-pos end-pt))
            (push ind remove-inds))))
      (dolist (ind remove-inds)
        (setq ind-managed-absolute-indicators (remove ind ind-managed-absolute-indicators)))
      (remove-overlays start-pt end-pt 'ind-indicator-absolute t))))

(defun line-reminder--add-line-to-change-line (ln)
  "Add LN to change line list variable."
  (push ln line-reminder--change-lines)
  (when (line-reminder--use-indicators-p)
    (line-reminder--mark-line-by-linum ln 'line-reminder-modified-sign-face)))

(defun line-reminder--remove-line-from-change-line (ln)
  "Remove LN from all line lists variable."
  (setq line-reminder--change-lines (remove ln line-reminder--change-lines))
  (setq line-reminder--saved-lines (remove ln line-reminder--saved-lines))
  (when (line-reminder--use-indicators-p)
    (line-reminder--ind-remove-indicator-at-line ln)))

(defsubst line-reminder--linum-format-string-align-right ()
  "Return format string align on the right."
  (let ((w (length (number-to-string (count-lines (point-min) (point-max))))))
    (format "%%%dd" w)))

(defsubst line-reminder--get-propertized-normal-sign (ln)
  "Return a default propertized normal sign.
LN : pass in by `linum-format' variable."
  (propertize (format (format line-reminder-linum-format
                              (line-reminder--linum-format-string-align-right))
                      ln)
              'face 'linum))

(defsubst line-reminder--get-propertized-modified-sign ()
  "Return a propertized modifoied sign."
  (propertize line-reminder-modified-sign 'face 'line-reminder-modified-sign-face))

(defsubst line-reminder--get-propertized-saved-sign ()
  "Return a propertized saved sign."
  (propertize line-reminder-saved-sign 'face 'line-reminder-saved-sign-face))

(defun line-reminder--propertized-sign-by-type (type &optional ln)
  "Return a propertized sign string by type.
TYPE : type of the propertize sign you want.
LN : Pass is line number for normal sign."
  (cl-case type
    (normal (if (not ln)
                (error "Normal line but with no line number pass in")
              ;; Just return normal linum format.
              (line-reminder--get-propertized-normal-sign ln)))
    (modified (line-reminder--get-propertized-modified-sign))
    (saved (line-reminder--get-propertized-saved-sign))))

(defun line-reminder--linum-format (ln)
  "Core line reminder format string logic here.
LN : pass in by `linum-format' variable."
  (let ((reminder-sign "") (result-sign "")
        (normal-sign (line-reminder--propertized-sign-by-type 'normal ln))
        (is-sign-exists nil))
    (cond
     ;; NOTE: Check if change lines list.
     ((line-reminder--contain-list-integer line-reminder--change-lines ln)
      (progn
        (setq reminder-sign (line-reminder--propertized-sign-by-type 'modified))
        (setq is-sign-exists t)))
     ;; NOTE: Check if saved lines list.
     ((line-reminder--contain-list-integer line-reminder--saved-lines ln)
      (progn
        (setq reminder-sign (line-reminder--propertized-sign-by-type 'saved))
        (setq is-sign-exists t))))

    ;; If the sign exist, then remove the last character from the normal sign.
    ;; So we can keep our the margin/padding the same without modifing the
    ;; margin/padding width.
    (when is-sign-exists
      (setq normal-sign (substring normal-sign 0 (1- (length normal-sign)))))

    ;; Combnie the result format.
    (setq result-sign (concat normal-sign reminder-sign))
    result-sign))

;;; Core

;;;###autoload
(defun line-reminder-clear-reminder-lines-sign ()
  "Clear all the reminder lines' sign."
  (interactive)
  (setq line-reminder--change-lines '())
  (setq line-reminder--saved-lines '())
  (line-reminder--ind-clear-indicators-absolute))

(defun line-reminder--is-valid-line-reminder-situation (&optional beg end)
  "Check if is valid to apply line reminder at the moment.
BEG : start changing point.
END : end changing point."
  (if (and beg end)
      (and (not buffer-read-only)
           (not (line-reminder--contain-list-string-regexp
                 line-reminder-ignore-buffer-names (buffer-name)))
           (<= beg (point-max))
           (<= end (point-max)))
    (and (not buffer-read-only)
         (not (line-reminder--contain-list-string-regexp
               line-reminder-ignore-buffer-names (buffer-name))))))

(defun line-reminder--shift-all-lines-list (in-list start delta)
  "Shift all lines from IN-LIST by from START line with DELTA lines value."
  (let ((index 0))
    (dolist (tmp-linum in-list)
      (when (< start tmp-linum)
        (setf (nth index in-list) (+ tmp-linum delta)))
      (setq index (1+ index))))
  in-list)

(defun line-reminder--shift-all-lines (start delta)
  "Shift all `change` and `saved` lines by from START line with DELTA lines value."
  (setq line-reminder--change-lines
        (line-reminder--shift-all-lines-list line-reminder--change-lines
                                             start
                                             delta))
  (setq line-reminder--saved-lines
        (line-reminder--shift-all-lines-list line-reminder--saved-lines
                                             start
                                             delta)))

(defun line-reminder--remove-lines-out-range ()
  "Remove all the line in the list that are above the last/maxinum line \
or less than zero line in current buffer."
  (let ((last-line-in-buffer (line-reminder--total-line))
        (check-lst (append line-reminder--change-lines line-reminder--saved-lines)))
    (dolist (line check-lst)
      ;; If is larger than last/max line in buffer.
      (when (or (< last-line-in-buffer line) (<= line 0))
        ;; Remove line because we are deleting.
        (line-reminder--remove-line-from-change-line line)))))

(defun line-reminder--remove-lines (beg end comm-or-uncomm-p)
  "Remove lines from BEG to END depends on COMM-OR-UNCOMM-P."
  (let ((cur beg))
    ;; Shift one more line when commenting/uncommenting.
    (when comm-or-uncomm-p (setq end (1+ end)))
    (while (< cur end)
      (if comm-or-uncomm-p
          (line-reminder--add-line-to-change-line cur)
        (line-reminder--remove-line-from-change-line cur))
      (setq cur (1+ cur)))))

(defun line-reminder--add-lines (beg end)
  "Add lines from BEG to END."
  (let ((cur beg))
    (while (<= cur end)
      (line-reminder--add-line-to-change-line cur)
      (setq cur (1+ cur)))))

;;;###autoload
(defun line-reminder-transfer-to-saved-lines ()
  "Transfer the `change-lines' to `saved-lines'."
  (interactive)
  (setq line-reminder--saved-lines
        (append line-reminder--saved-lines line-reminder--change-lines))
  ;; Clear the change lines.
  (setq line-reminder--change-lines '())

  (delete-dups line-reminder--saved-lines)  ; Removed save duplicates
  (line-reminder--remove-lines-out-range)  ; Remove out range.

  (line-reminder--mark-buffer))

(defun line-reminder--ind-clear-indicators-absolute ()
  "Clean up all the indicators."
  (when (line-reminder--use-indicators-p)
    (ind-clear-indicators-absolute)))

(defun line-reminder--mark-buffer ()
  "Mark the whole buffer."
  (when (line-reminder--use-indicators-p)
    (save-excursion
      (line-reminder--ind-clear-indicators-absolute)
      (dolist (ln line-reminder--change-lines)
        (line-reminder--mark-line-by-linum ln 'line-reminder-modified-sign-face))
      (dolist (ln line-reminder--saved-lines)
        (line-reminder--mark-line-by-linum ln 'line-reminder-saved-sign-face)))))

(defun line-reminder--before-change-functions (beg end)
  "Do stuff before buffer is changed with BEG and END."
  (when (and (not (memq this-command line-reminder-disable-commands))
             (line-reminder--is-valid-line-reminder-situation beg end))
    (line-reminder--ind-delete-dups)
    (progn
      (setq line-reminder--before-max-pt (point-max))
      (setq line-reminder--before-max-linum (line-reminder--line-number-at-pos (point-max))))
    (progn
      (setq line-reminder--before-begin-pt beg)
      (setq line-reminder--before-begin-linum (line-reminder--line-number-at-pos beg)))
    (progn
      (setq line-reminder--before-end-pt end)
      (setq line-reminder--before-end-linum (line-reminder--line-number-at-pos end)))))

(defun line-reminder--after-change-functions (beg end len)
  "Do stuff after buffer is changed with BEG, END and LEN."
  (when (and (not (memq this-command line-reminder-disable-commands))
             (line-reminder--is-valid-line-reminder-situation beg end))
    (save-excursion
      ;; When begin and end are not the same, meaning the there is addition/deletion
      ;; happening in the current buffer.
      (let ((begin-linum -1) (end-linum -1) (delta-lines 0)
            (starting-line -1)  ; Starting line for shift
            (max-ln -1)
            (adding-p (< (+ beg len) end))
            ;; Flag to check if currently commenting or uncommenting.
            (comm-or-uncomm-p (and (not (= len 0)) (not (= beg end)))))
        (if (or adding-p comm-or-uncomm-p)
            (setq line-reminder--before-max-pt (+ line-reminder--before-max-pt (- end beg)))
          (setq line-reminder--before-max-pt (- line-reminder--before-max-pt len)))

        (setq max-ln (line-reminder--line-number-at-pos line-reminder--before-max-pt))

        (if adding-p
            (progn
              (setq end-linum (line-reminder--line-number-at-pos end))
              (setq begin-linum (line-reminder--line-number-at-pos beg)))
          (setq beg line-reminder--before-begin-pt)
          (setq end line-reminder--before-end-pt)
          (setq begin-linum line-reminder--before-begin-linum)
          (setq end-linum line-reminder--before-end-linum))

        (goto-char beg)

        (if comm-or-uncomm-p
            (setq delta-lines (- max-ln line-reminder--before-max-linum))
          (setq delta-lines (- end-linum begin-linum))
          (unless adding-p (setq delta-lines (- 0 delta-lines))))

        ;; Just add the current line.
        (line-reminder--add-line-to-change-line begin-linum)

        ;; If adding line, bound is the begin line number.
        (setq starting-line begin-linum)

        ;; NOTE: Deletion..
        (unless adding-p
          (line-reminder--remove-lines begin-linum end-linum comm-or-uncomm-p)
          (line-reminder--shift-all-lines starting-line delta-lines))

        ;; Just add the current line.
        (line-reminder--add-line-to-change-line begin-linum)

        ;; NOTE: Addition..
        (when adding-p
          (line-reminder--shift-all-lines starting-line delta-lines)
          (line-reminder--add-lines begin-linum end-linum))

        (delete-dups line-reminder--change-lines)
        (delete-dups line-reminder--saved-lines)

        ;; Remove out range.
        (line-reminder--remove-lines-out-range)))))

;;; Loading

(defun line-reminder--enable ()
  "Enable `line-reminder' in current buffer."
  (cl-case line-reminder-show-option
    (linum
     (require 'linum)
     (setq-local linum-format 'line-reminder--linum-format))
    (indicators
     (require 'indicators)))
  (add-hook 'before-change-functions #'line-reminder--before-change-functions nil t)
  (add-hook 'after-change-functions #'line-reminder--after-change-functions nil t)
  (advice-add 'save-buffer :after #'line-reminder-transfer-to-saved-lines))

(defun line-reminder--disable ()
  "Disable `line-reminder' in current buffer."
  (remove-hook 'before-change-functions #'line-reminder--before-change-functions t)
  (remove-hook 'after-change-functions #'line-reminder--after-change-functions t)
  (advice-remove 'save-buffer #'line-reminder-transfer-to-saved-lines)
  (line-reminder-clear-reminder-lines-sign))

;;;###autoload
(define-minor-mode line-reminder-mode
  "Minor mode 'line-reminder-mode'."
  :lighter " LR"
  :group line-reminder
  (if line-reminder-mode (line-reminder--enable) (line-reminder--disable)))

(defun line-reminder--turn-on-line-reminder-mode ()
  "Turn on the 'line-reminder-mode'."
  (line-reminder-mode 1))

;;;###autoload
(define-globalized-minor-mode global-line-reminder-mode
  line-reminder-mode line-reminder--turn-on-line-reminder-mode
  :require 'line-reminder)

(provide 'line-reminder)
;;; line-reminder.el ends here
