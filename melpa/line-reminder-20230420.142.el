;;; line-reminder.el --- Line annotation for changed and saved lines  -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2023  Shen, Jen-Chieh
;; Created date 2018-05-25 15:10:29

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/emacs-vs/line-reminder
;; Package-Version: 20230420.142
;; Package-Commit: 583bff387b361e1fe442f57e9ad1f6f8e87dedf4
;; Version: 0.5.1
;; Package-Requires: ((emacs "25.1") (indicators "0.0.4") (fringe-helper "1.0.1") (ov "1.0.6") (ht "2.0"))
;; Keywords: convenience annotation

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
(require 'subr-x)

(require 'fringe-helper)
(require 'ht)
(require 'ov)

(defgroup line-reminder nil
  "Line annotation for changed and saved lines."
  :prefix "line-reminder-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/emacs-vs/line-reminder"))

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

(defcustom line-reminder-modified-sign-priority 20
  "Priority for modified lines overlays."
  :type 'integer
  :group 'line-reminder)

(defcustom line-reminder-saved-sign-priority 10
  "Priority for saved lines overlays."
  :type 'integer
  :group 'line-reminder)

(defcustom line-reminder-thumb-modified-sign-priority 20
  "Priority for modified lines thumbnail overlays."
  :type 'integer
  :group 'line-reminder)

(defcustom line-reminder-thumb-saved-sign-priority 10
  "Priority for saved lines thumbnail overlays."
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

(defcustom line-reminder-thumb-modified-sign "▐"
  "String to display modified line thumbnail."
  :type 'string
  :group 'line-reminder)

(defcustom line-reminder-thumb-saved-sign "▐"
  "String to display saved line thumbnail."
  :type 'string
  :group 'line-reminder)

(defcustom line-reminder-fringe-placed 'left-fringe
  "Line indicators fringe location."
  :type '(choice (const :tag "On the left fringe" left-fringe)
                 (const :tag "On the right fringe" right-fringe))
  :group 'line-reminder)

(fringe-helper-define 'line-reminder--default-bitmap nil
  "..xxx.." "..xxx.." "..xxx.." "..xxx.." "..xxx.." "..xxx.." "..xxx.."
  "..xxx.." "..xxx.." "..xxx.." "..xxx.." "..xxx.." "..xxx.." "..xxx.."
  "..xxx.." "..xxx.." "..xxx.." "..xxx.." "..xxx.." "..xxx.." "..xxx.."
  "..xxx.." "..xxx..")

(defcustom line-reminder-bitmap 'line-reminder--default-bitmap
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

(defvar-local line-reminder--line-status (ht-create)
  "Reocrd modified/saved lines' status in hash-table.")

(defvar-local line-reminder--before-max-pt -1
  "Record down the point max for out of range calculation.")

(defvar-local line-reminder--cache-max-line nil
  "Cache prevent counting max line twice.")

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

(defvar-local line-reminder--undo-cancel-p nil
  "If non-nil, we should remove record of changes/saved lines for undo actions.")

(defvar-local line-reminder--thumb-ovs (ht-create)
  "Overlays indicate thumbnail.")

;;
;; (@* "External" )
;;

(defvar linum-format)
(defvar ind-managed-absolute-indicators)
(defvar buffer-undo-tree)
(defvar undo-tree-mode)

(declare-function ind-create-indicator-at-line "ext:indicators.el")
(declare-function ind-clear-indicators-absolute "ext:indicators.el")
(declare-function undo-tree-current "ext:undo-tree.el")
(declare-function undo-tree-node-previous "ext:undo-tree.el")

;;
;; (@* "Util" )
;;

(defmacro line-reminder--mute-apply (&rest body)
  "Execute BODY without message."
  (declare (indent 0) (debug t))
  `(let (message-log-max)
     (with-temp-message (or (current-message) nil)
       (let ((inhibit-message t)) ,@body))))

(defmacro line-reminder--with-no-redisplay (&rest body)
  "Execute BODY without any redisplay execution."
  (declare (indent 0) (debug t))
  `(let ((inhibit-redisplay t)
         (inhibit-modification-hooks t)
         after-focus-change-function
         buffer-list-update-hook
         display-buffer-alist
         window-configuration-change-hook
         window-scroll-functions
         window-size-change-functions
         window-state-change-hook
         jit-lock-mode)
     ,@body))

(defmacro line-reminder--with-selected-window (window &rest body)
  "Same with `with-selected-window' but safe.

See macro `with-selected-window' description for arguments WINDOW and BODY."
  (declare (indent 1) (debug t))
  `(when (window-live-p ,window) (with-selected-window ,window ,@body)))

(defun line-reminder--goto-line (line)
  "Jump to LINE."
  (goto-char (point-min))
  (forward-line (1- line)))

(defun line-reminder--use-indicators-p ()
  "Return non-nil if using indicator."
  (eq line-reminder-show-option 'indicators))

(defun line-reminder--line-number-at-pos (&optional pos)
  "Return line number at POS with absolute as default."
  (ignore-errors (line-number-at-pos pos t)))

(defun line-reminder--contain-list-string-regexp (in-list in-str)
  "Return non-nil if IN-STR is listed in IN-LIST.

This function uses `string-match-p'."
  (cl-some (lambda (elm) (string-match-p elm in-str)) in-list))

(defun line-reminder--get-string-sign (face)
  "Return string sign priority by FACE."
  (cl-case face
    (`line-reminder-modified-sign-face line-reminder-modified-sign)
    (`line-reminder-saved-sign-face line-reminder-saved-sign)
    (`line-reminder-thumb-modified-sign-face line-reminder-thumb-modified-sign)
    (`line-reminder-thumb-saved-sign-face line-reminder-thumb-saved-sign)))

(defun line-reminder--get-priority (face)
  "Return overlay priority by FACE."
  (cl-case face
    (`line-reminder-modified-sign-face line-reminder-modified-sign-priority)
    (`line-reminder-saved-sign-face line-reminder-saved-sign-priority)
    (`line-reminder-thumb-modified-sign-face line-reminder-thumb-modified-sign-priority)
    (`line-reminder-thumb-saved-sign-face line-reminder-thumb-saved-sign-priority)))

(defun line-reminder--get-face (sign &optional thumbnail)
  "Return face by SIGN.

If optional argument THUMBNAIL is non-nil, return in thumbnail faces."
  (cond ((numberp sign)
         (when-let ((sign (ht-get line-reminder--line-status sign)))
           (line-reminder--get-face sign thumbnail)))
        (thumbnail
         (cl-case sign
           (`modified 'line-reminder-thumb-modified-sign-face)
           (`saved 'line-reminder-thumb-saved-sign-face)))
        (t
         (cl-case sign
           (`modified 'line-reminder-modified-sign-face)
           (`saved 'line-reminder-saved-sign-face)))))

(defun line-reminder--mark-line-by-linum (line face)
  "Mark the LINE by using FACE name."
  (line-reminder--mute-apply
    ;; XXX: We set variable `ind-managed-absolute-indicators' to `nil' to
    ;; save huge performance from function `ind-update-absolute'.
    (let (ind-managed-absolute-indicators)
      (ind-create-indicator-at-line
       line :managed t :dynamic t :relative nil :fringe line-reminder-fringe-placed
       :bitmap line-reminder-bitmap :face face
       :priority (line-reminder--get-priority face)))))

(defun line-reminder--ind-remove-indicator-at-line (line)
  "Remove the indicator on LINE."
  (save-excursion
    (line-reminder--goto-line line)
    (remove-overlays (line-beginning-position) (line-end-position) 'ind-indicator-absolute t)))

(defun line-reminder--add-change-line (line)
  "Add LINE with `modified' flag."
  (when (line-reminder--use-indicators-p)
    (unless (equal (ht-get line-reminder--line-status line) 'modified)
      (ht-set line-reminder--line-status line 'modified)
      (line-reminder--mark-line-by-linum line 'line-reminder-modified-sign-face))))

(defun line-reminder--remove-change-line (line)
  "Remove LINE from status."
  (ht-remove line-reminder--line-status line)
  (when (line-reminder--use-indicators-p)
    (line-reminder--ind-remove-indicator-at-line line)))

(defsubst line-reminder--linum-format-string-align-right ()
  "Return format string align on the right."
  (let ((w (length (number-to-string (count-lines (point-min) (point-max))))))
    (format "%%%dd" w)))

(defsubst line-reminder--get-propertized-normal-sign (line)
  "Return a default propertized normal sign.
LINE : pass in by `linum-format' variable."
  (propertize (format (format line-reminder-linum-format
                              (line-reminder--linum-format-string-align-right))
                      line)
              'face 'linum))

(defun line-reminder--propertized-sign-by-type (type &optional line)
  "Return a propertized sign string by type.
TYPE : type of the propertize sign you want.
LINE : Pass is line number for normal sign."
  (cl-case type
    (`normal (if (not line)
                 (error "Normal line but with no line number pass in")
               ;; Just return normal linum format.
               (line-reminder--get-propertized-normal-sign line)))
    (`modified (propertize line-reminder-modified-sign 'face 'line-reminder-modified-sign-face))
    (`saved (propertize line-reminder-saved-sign 'face 'line-reminder-saved-sign-face))))

(defun line-reminder--linum-format (line)
  "Core line reminder format string logic here.
LINE : pass in by `linum-format' variable."
  (let ((sign (ht-get line-reminder--line-status line))
        (normal-sign (line-reminder--propertized-sign-by-type 'normal line))
        reminder-sign)
    (when sign
      (setq reminder-sign (line-reminder--propertized-sign-by-type sign)
            ;; If the sign exist, then remove the last character from the normal
            ;; sign. So we can keep our the margin/padding the same without
            ;; modifing the margin/padding width.
            normal-sign (substring normal-sign 0 (1- (length normal-sign)))))
    ;; Combnie the result format
    (concat normal-sign reminder-sign)))

;;
;; (@* "Entry" )
;;

(defun line-reminder--enable ()
  "Enable `line-reminder' in current buffer."
  (cl-case line-reminder-show-option
    (`linum
     (require 'linum)
     (setq-local linum-format 'line-reminder--linum-format))
    (`indicators
     (require 'indicators)))
  (ht-clear line-reminder--line-status)
  (ht-clear line-reminder--thumb-ovs)
  (add-hook 'before-change-functions #'line-reminder--before-change nil t)
  (add-hook 'after-change-functions #'line-reminder--after-change nil t)
  (add-hook 'post-command-hook #'line-reminder--post-command nil t)
  ;; XXX: We add advice to `save-buffer', but we never need to remove it since
  ;; we have checked `line-reminder-mode' inside `line-reminder--save-buffer'
  ;; function.
  (advice-add 'save-buffer :after #'line-reminder--save-buffer)
  ;; XXX: Don't use local for these hooks/functions, without the local flag
  ;; it will be much faster for large operations (paste, save, etc)
  (add-hook 'window-scroll-functions #'line-reminder--thumb-scroll)
  (add-hook 'window-size-change-functions #'line-reminder--thumb-size-change))

(defun line-reminder--disable ()
  "Disable `line-reminder' in current buffer."
  (remove-hook 'before-change-functions #'line-reminder--before-change t)
  (remove-hook 'after-change-functions #'line-reminder--after-change t)
  (remove-hook 'post-command-hook #'line-reminder--post-command t)
  (line-reminder-clear-reminder-lines-sign)
  ;; XXX: Don't use local for these hooks/functions, without the local flag
  ;; it will be much faster for large operations (paste, save, etc)
  (remove-hook 'window-scroll-functions #'line-reminder--thumb-scroll)
  (remove-hook 'window-size-change-functions #'line-reminder--thumb-size-change))

;;;###autoload
(define-minor-mode line-reminder-mode
  "Minor mode `line-reminder-mode'."
  :lighter " LR"
  :group line-reminder
  (if line-reminder-mode (line-reminder--enable) (line-reminder--disable)))

(defun line-reminder--turn-on-line-reminder-mode ()
  "Turn on the `line-reminder-mode'."
  (line-reminder-mode 1))

;;;###autoload
(define-globalized-minor-mode global-line-reminder-mode
  line-reminder-mode line-reminder--turn-on-line-reminder-mode
  :require 'line-reminder)

;;
;; (@* "Core" )
;;

;;;###autoload
(defun line-reminder-clear-reminder-lines-sign ()
  "Clear all the reminder lines' sign."
  (interactive)
  (ht-clear line-reminder--line-status)
  (ht-clear line-reminder--thumb-ovs)
  (line-reminder--ind-clear-indicators-absolute)
  (line-reminder--thumb-delete-ovs))

(defun line-reminder--custom-file-saving ()
  "Return t if we are saving `custom-file'."
  (and (or print-escape-control-characters inhibit-read-only)
       (equal (buffer-file-name) (ignore-errors (expand-file-name custom-file)))))

(defun line-reminder--valid-situation-p (beg end)
  "Return non-nil, if the conditions are matched.

Arguments BEG and END are passed in by before/after change functions."
  (and
   (not (line-reminder--custom-file-saving))
   (not buffer-read-only)
   (not (line-reminder--contain-list-string-regexp
         line-reminder-ignore-buffer-names (buffer-name)))
   (not (memq this-command line-reminder-disable-commands))
   (if (and beg end) (and (<= beg (point-max)) (<= end (point-max))) t)))

(defmacro line-reminder--with-valid-situation (beg end &rest body)
  "Execute BODY around `line-reminder--valid-situation-p' function.

See function `line-reminder--valid-situation-p' description for arguments BEG
and END."
  (declare (indent 2) (debug t))
  `(when (line-reminder--valid-situation-p ,beg ,end)
     ,@body))

(defun line-reminder--shift-all-lines (start delta)
  "Shift all `change`/`saved` lines by from START line with DELTA."
  (unless (zerop delta)
    ;; Clean up all indicators before shifting!
    (when (line-reminder--use-indicators-p)
      (ht-map (lambda (line _sign)
                (when (< start line)
                  (line-reminder--ind-remove-indicator-at-line line)))
              line-reminder--line-status))
    (let ((new-ht (ht-create)))
      (ht-map (lambda (line sign)
                (if (< start line)
                    (let ((new-line (+ line delta)))
                      (ht-set new-ht new-line sign)
                      (line-reminder--mark-line-by-linum new-line
                                                         (line-reminder--get-face sign)))
                  (ht-set new-ht line sign)))
              line-reminder--line-status)
      (setq line-reminder--line-status new-ht))))  ; update

(defun line-reminder--remove-lines-out-range ()
  "Remove all lines outside of buffer."
  (when line-reminder--cache-max-line
    (ht-map (lambda (line _value)
              (when (or (< line-reminder--cache-max-line line) (<= line 0))
                (line-reminder--remove-change-line line)))
            line-reminder--line-status)))

(defun line-reminder--remove-lines (beg end comm-or-uncomm-p)
  "Remove lines from BEG to END depends on COMM-OR-UNCOMM-P."
  (let ((cur beg))
    ;; Shift one more line when commenting/uncommenting
    (when comm-or-uncomm-p (cl-incf end))
    (while (< cur end)
      (if comm-or-uncomm-p
          (line-reminder--add-change-line cur)
        (line-reminder--remove-change-line cur))
      (cl-incf cur))))

(defun line-reminder--add-lines (beg end)
  "Add lines from BEG to END."
  (let ((cur beg))
    (while (<= cur end)
      (line-reminder--add-change-line cur)
      (cl-incf cur))))

;;;###autoload
(defun line-reminder-transfer-to-saved-lines ()
  "Transfer the `change-lines' to `saved-lines'."
  (interactive)
  (ht-map  ; convert to saved
   (lambda (line _value) (ht-set line-reminder--line-status line 'saved))
   line-reminder--line-status)
  (line-reminder--remove-lines-out-range)  ; Remove out range.
  (line-reminder--mark-buffer))

(defun line-reminder--ind-clear-indicators-absolute ()
  "Clean up all the indicators."
  (when (line-reminder--use-indicators-p) (ind-clear-indicators-absolute)))

(defun line-reminder--mark-buffer ()
  "Mark the whole buffer."
  (when (line-reminder--use-indicators-p)
    (save-excursion
      (line-reminder--ind-clear-indicators-absolute)
      (ht-map
       (lambda (line sign)
         (line-reminder--mark-line-by-linum line (line-reminder--get-face sign)))
       line-reminder--line-status)
      (line-reminder--thumb-render-buffer))))

(defun line-reminder--before-change (beg end)
  "Do stuff before buffer is changed with BEG and END."
  (line-reminder--with-valid-situation beg end
    ;; If buffer consider virtual buffer like `*scratch*`, then always
    ;; treat it as modified
    (setq line-reminder--undo-cancel-p (and (buffer-file-name) undo-in-progress))
    (setq line-reminder--before-max-pt (point-max)
          line-reminder--before-max-linum (line-reminder--line-number-at-pos (point-max))
          line-reminder--before-begin-pt beg
          line-reminder--before-begin-linum (line-reminder--line-number-at-pos beg)
          line-reminder--before-end-pt end
          line-reminder--before-end-linum (line-reminder--line-number-at-pos end))))

(defun line-reminder--after-change (beg end len)
  "Do stuff after buffer is changed with BEG, END and LEN."
  (line-reminder--with-valid-situation beg end
    ;; When begin and end are not the same, meaning the there is addition/deletion
    ;; happening in the current buffer.
    (let ((adding-p (< (+ beg len) end))
          begin-linum end-linum delta-lines
          starting-line  ; Starting line for shift
          ;; Flag to check if currently commenting or uncommenting
          (comm-or-uncomm-p (and (not (= len 0)) (not (= beg end)))))
      (setq line-reminder--before-max-pt
            (if (or adding-p comm-or-uncomm-p)
                (+ line-reminder--before-max-pt (- end beg))
              (- line-reminder--before-max-pt len)))

      (setq line-reminder--cache-max-line
            (line-reminder--line-number-at-pos (min line-reminder--before-max-pt
                                                    (point-max))))

      (if adding-p
          (setq end-linum (line-reminder--line-number-at-pos end)
                begin-linum (line-reminder--line-number-at-pos beg))
        (setq beg line-reminder--before-begin-pt
              end line-reminder--before-end-pt
              begin-linum line-reminder--before-begin-linum
              end-linum line-reminder--before-end-linum))

      (if comm-or-uncomm-p
          (setq delta-lines (- line-reminder--cache-max-line line-reminder--before-max-linum))
        (setq delta-lines (- end-linum begin-linum))
        (unless adding-p (setq delta-lines (- 0 delta-lines))))

      ;; If adding line, bound is the begin line number
      (setq starting-line begin-linum)

      ;; NOTE: Deletion..
      (unless adding-p
        (line-reminder--remove-lines begin-linum end-linum comm-or-uncomm-p)
        (line-reminder--shift-all-lines starting-line delta-lines)
        (line-reminder--add-change-line begin-linum))

      ;; NOTE: Addition..
      (when adding-p
        (line-reminder--shift-all-lines starting-line delta-lines)
        (line-reminder--add-lines begin-linum end-linum))

      (line-reminder--remove-lines-out-range)  ; Remove out range
      (line-reminder--thumb-render-buffer))))  ; Display thumbnail

;;
;; (@* "Save" )
;;

(defun line-reminder--save-buffer (&rest _)
  "Advice execute after function `save-buffer'."
  (when line-reminder-mode (line-reminder-transfer-to-saved-lines)))

;;
;; (@* "Undo" )
;;

(defun line-reminder--undo-tree-root-p ()
  "Return non-nil, if undo is at the root of the undo list."
  (or (eq buffer-undo-list t)
      (null (undo-tree-node-previous (undo-tree-current buffer-undo-tree)))))

(defun line-reminder--undo-root-p ()
  "Compatible version to check root of undo list for different undo packages."
  (cond
   ((and (featurep 'undo-tree) undo-tree-mode)
    (ignore-errors (line-reminder--undo-tree-root-p)))
   (t (eq pending-undo-list t))))

(defun line-reminder--post-command ()
  "Post command for undo cancelling."
  (when (and line-reminder--undo-cancel-p (line-reminder--undo-root-p))
    (ht-clear line-reminder--line-status)
    (line-reminder--ind-clear-indicators-absolute)
    (line-reminder--thumb-delete-ovs)
    (ht-clear line-reminder--thumb-ovs)))

;;
;; (@* "Thumbnail" )
;;

(defcustom line-reminder-thumbnail nil
  "Show thumbnail in the opposite fringe from `line-reminder-fringe-placed'."
  :type 'boolean
  :group 'line-reminder)

(fringe-helper-define 'line-reminder--default-thumbnail-bitmap nil
  "xx...." "xx...." "xx...." "xx...." "xx...." "xx...." "xx...."
  "xx...." "xx...." "xx...." "xx...." "xx...." "xx...." "xx...."
  "xx...." "xx...." "xx...." "xx...." "xx...." "xx...." "xx...."
  "xx...." "xx....")

(defcustom line-reminder-thumbnail-bitmap 'line-reminder--default-thumbnail-bitmap
  "Bitmap for thumbnail."
  :type 'symbol
  :group 'line-reminder)

(defface line-reminder-thumb-modified-sign-face
  `((t :foreground "#EFF284"))
  "Modifed sign face."
  :group 'line-reminder)

(defface line-reminder-thumb-saved-sign-face
  `((t :foreground "#577430"))
  "Modifed sign face."
  :group 'line-reminder)

(defun line-reminder--oppose-fringe (fringe)
  "Return opposite FRINGE type."
  (cl-case fringe
    (`left-fringe  'right-fringe)
    (`right-fringe 'left-fringe)))

(defun line-reminder--thumb-create-tty-ov (face fringe priority)
  "Create single tty thumbnail overlay with FACE in FRINGE with PRIORITY."
  (let* ((msg (line-reminder--get-string-sign face))
         (len (length msg))
         (msg (progn (add-face-text-property 0 len face nil msg) msg))
         (display-string `(space :align-to (- ,fringe 2)))
         (display-string (concat (propertize "." 'display display-string) msg))
         (ov (make-overlay (line-beginning-position) (line-end-position))))
    (put-text-property 0 1 'cursor t display-string)
    (ov-set ov
            'after-string display-string
            'window (selected-window)
            'priority (1+ priority)
            'line-reminder-thumb t)
    ov))

(defun line-reminder--thumb-create-fringe-ov (face fringe priority)
  "Create single fringe thumbnail overlay with FACE in FRINGE with PRIORITY."
  (let* ((pos (point))
         ;; If `pos' is at the beginning of line, overlay of the
         ;; fringe will be on the previous visual line.
         (pos (if (= (line-end-position) pos) pos (1+ pos)))
         (display-string `(,fringe ,line-reminder-thumbnail-bitmap ,face))
         (ov (make-overlay pos pos)))
    (ov-set ov
            'after-string (propertize "." 'display display-string)
            'fringe-helper t
            'window (selected-window)
            'priority (1+ priority)
            'line-reminder-thumb t)
    ov))

(defun line-reminder--thumb-create-ov (face)
  "Create single thumbnail overlay with FACE."
  (let* ((fringe (line-reminder--oppose-fringe line-reminder-fringe-placed))
         (priority (line-reminder--get-priority face))
         (fnc (if (display-graphic-p)
                  #'line-reminder--thumb-create-fringe-ov
                #'line-reminder--thumb-create-tty-ov))
         (ov (funcall fnc face fringe priority))
         (key (selected-window)))
    (push ov (ht-get line-reminder--thumb-ovs key))))

(defun line-reminder--thumb-show (window &rest _)
  "Show thumbnail using overlays inside WINDOW."
  (line-reminder--with-no-redisplay
    (line-reminder--with-selected-window window
      (when line-reminder--cache-max-line
        (let ((window-lines (float (max 0 (1- (window-text-height)))))
              (buffer-lines (float line-reminder--cache-max-line))
              (guard (ht-create)) added start-point percent-line face)
          (when (< window-lines buffer-lines)
            (save-excursion
              (goto-char (window-start))  ; start from 0 percent
              (setq start-point (point))
              (ht-map
               (lambda (line sign)
                 (setq face (line-reminder--get-face sign t)
                       percent-line (* (/ line buffer-lines) window-lines)
                       percent-line (floor percent-line)
                       added (ht-get guard percent-line))
                 ;; Prevent creating overlay twice on the same line
                 (when (null added)
                   (goto-char start-point)
                   (when (zerop (forward-line percent-line))
                     (ht-set guard percent-line sign)
                     (line-reminder--thumb-create-ov face))))
               line-reminder--line-status))))))))

(defun line-reminder--thumb-size-change (&optional frame &rest _)
  "Render thumbnail for all visible windows."
  (line-reminder--with-no-redisplay
    (dolist (win (window-list frame)) (line-reminder--thumb-render-window win))))

(defun line-reminder--thumb-scroll (&optional window &rest _)
  "Render thumbnail on WINDOW."
  (line-reminder--with-no-redisplay
    (line-reminder--thumb-render-window (or window (selected-window)))))

(defun line-reminder--thumb-render-buffer (&optional buffer-or-name)
  "Render thumbnail for BUFFER-OR-NAME."
  (dolist (win (get-buffer-window-list (or (current-buffer) buffer-or-name) nil t))
    (line-reminder--thumb-render-window win)))

(defun line-reminder--thumb-render-window (window)
  "Render thumbnail for WINDOW."
  (when line-reminder-thumbnail
    (line-reminder--with-selected-window window
      (when line-reminder-mode
        (line-reminder--thumb-delete-ovs)
        (line-reminder--thumb-show window)))))

(defun line-reminder--thumb-delete-ovs ()
  "Delete thumbnail overlays."
  (let ((key (selected-window)))
    (mapc 'delete-overlay (ht-get line-reminder--thumb-ovs key))
    (ht-set line-reminder--thumb-ovs key nil)))

(provide 'line-reminder)
;;; line-reminder.el ends here
