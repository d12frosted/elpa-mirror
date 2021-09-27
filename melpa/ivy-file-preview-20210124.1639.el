;;; ivy-file-preview.el --- Preview the current ivy file selection  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021  Shen, Jen-Chieh
;; Created date 2020-09-07 23:42:35

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Preview the current ivy file selection.
;; Keyword: file ivy swiper preview select selection
;; Version: 0.4.5
;; Package-Version: 20210124.1639
;; Package-Commit: 368c0c2db6b2ff279a956b8075eaf9ba2c334234
;; Package-Requires: ((emacs "25.1") (ivy "0.8.0") (s "1.12.0") (f "0.20.0"))
;; URL: https://github.com/jcs-elpa/ivy-file-preview

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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This global minor mode enhanced the user experience while controlling
;; through `ivy' interface during some previewable commands.
;;
;; You can enable this minor mode by doing the following execution,
;;
;;   `(ivy-file-preview-mode 1)`
;;
;; Some previewable commands can be a file, path, or search restult.
;; The file and path can be either absolute/relative file path.  The
;; search result accepts cons cell for either (line . column) or a
;; integer (position).
;;

;;; Code:

(require 'cl-lib)
(require 'f)
(require 's)
(require 'subr-x)

(require 'ivy)

(defgroup ivy-file-preview nil
  "Preview the current ivy file selection."
  :prefix "ivy-file-preview-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/ivy-file-preview"))

(defcustom ivy-file-preview-preview-only t
  "Preview the file instead of actually opens the file."
  :type 'boolean
  :group 'ivy-file-preview)

(defcustom ivy-file-preview-details t
  "Preview file only when there are more details in the selection."
  :type 'boolean
  :group 'ivy-file-preview)

(defcustom ivy-file-preview-overlay-p t
  "Show overlays while previewing."
  :type 'boolean
  :group 'ivy-file-preview)

(defcustom ivy-file-preview-overlay-delay-time 0.4
  "Time to delay before display overlays."
  :type 'float
  :group 'ivy-file-preview)

(defvar ivy-file-preview--preview-files '()
  "Files that are previewing, and will be closed after action is done.")

(defvar ivy-file-preview--selected-file ""
  "Record down the current selected file.")

(defvar ivy-file-preview--window-status '()
  "Record windows status for when canceling command.")

(defvar ivy-file-preview--overlays '()
  "List of overlays.")

(defvar ivy-file-preview--current-overlay nil
  "Record down the current selected overlay.")

(defvar ivy-file-preview--ivy-text ""
  "Record down the ivy text to prevent make overlay if not need to.")

(defvar ivy-file-preview--overlay-timer nil
  "Timer to make overlays in buffer.")

(defvar ivy-file-preview--current-dir ""
  "Record the current present directory.
It could either by `project-directory' or `default-directory'")

(defvar ivy-file-preview--this-command nil
  "Record of this command when entering minibuffer.")

(defvar ivy-file-preview--first-cand-index nil
  "Record of first candidate's index.")

;;
;; (@* "External" )
;;

(defvar ivy-searcher--candidates)

;;
;; (@* "Custom" )
;;

(defun ivy-file-preview--ivy-searcher-p ()
  "Return non-nil if current command is from `ivy-searcher'."
  (memq ivy-file-preview--this-command '(ivy-searcher-search-file
                                         ivy-searcher-search-project)))

(defun ivy-file-preview--init-ov-data ()
  "Initialize overlays data."
  ;; NOTE: Custom overlays data.
  ;;
  ;; Here is where I get the possible custom overlay data.
  ;;
  ;; ---
  ;; TODO: These are commands that I may want to implement.
  ;;
  ;;  - `counsel-ag'
  (cond
   ;; Ivy Searcher
   ((ivy-file-preview--ivy-searcher-p)
    (setq ivy-file-preview--first-cand-index
          (cl-position
           nil ivy-searcher--candidates
           :test
           (lambda (_key cand)
             (pop cand)
             (string= ivy-file-preview--selected-file (plist-get cand :file))))))))

;;
;; (@* "Util" )
;;

(defun ivy-file-preview--match-end (&optional pos index)
  "Get matching end by currently selected candidate.

An optional argument POS is use to calculate the position that relative to the
length of `ivy-text'.

An optional argument INDEX is use to find current ivy candidate."
  (unless pos (setq pos (point)))
  (if index
      (when ivy-file-preview--first-cand-index
        (setq index (+ index ivy-file-preview--first-cand-index)))
    (setq index ivy--index))
  (cond ((ivy-file-preview--ivy-searcher-p)
         (let* ((cand (nth index ivy-searcher--candidates))
                (plist-data (cdr cand))
                (end-pt (plist-get plist-data :end)))
           (or end-pt (+ pos (length ivy-text)))))
        (t (+ pos (length ivy-text)))))

(defun ivy-file-preview--project-path ()
  "Get current project path."
  (cdr (project-current)))

(defun ivy-file-preview--get-file-path (fn)
  "Resolve FN for full file path."
  (let ((project-dir (ivy-file-preview--project-path)))
    (when (string-match-p "/" fn) (setq ivy-file-preview--current-dir project-dir))
    (cond ((and (string-match-p "/" fn) project-dir)
           (setq fn (f-join project-dir fn)))
          (t (setq fn (f-join ivy-file-preview--current-dir fn)))))
  fn)

(defun ivy-file-preview--goto-line (ln)
  "Goto LN line number."
  (goto-char (point-min))
  (forward-line (1- ln)))

(defun ivy-file-preview--safe-kill-timer (tmr)
  "Kill TMR safely."
  (when (timerp tmr) (cancel-timer tmr)))

(defun ivy-file-preview--convert-pos-delta (ln col)
  "Convert LN and COL to position point."
  (save-excursion (forward-line ln) (+ (point) col)))

(defun ivy-file-preview--make-overlay (beg end &optional current-ov)
  "Make a new overlay with BEG, END and face (FC).
If CURRENT-OV is non-nil it create overlay that are currently selected."
  (let ((ol (make-overlay beg end)))
    (overlay-put ol 'face (if current-ov 'ivy-current-match
                            'ivy-minibuffer-match-highlight))
    (overlay-put ol 'priority (if current-ov 100 0))
    (push ol ivy-file-preview--overlays)  ; NOTE: Eventually get managed to list.
    ol))

(defun ivy-file-preview--make-current-overlay (&optional beg end)
  "Make current selected overlay with BEG and END."
  (unless beg (setq beg (point)))
  (unless end (setq end (+ beg (length ivy-text))))
  (setq ivy-file-preview--current-overlay
        (ivy-file-preview--make-overlay beg end t)))

(defun ivy-file-preview--delete-overlays ()
  "Delete all overlays in list."
  (ivy-file-preview--safe-kill-timer ivy-file-preview--overlay-timer)
  (dolist (ov ivy-file-preview--overlays) (delete-overlay ov))
  (setq ivy-file-preview--overlays nil)
  (setq ivy-file-preview--current-overlay nil))

(defun ivy-file-preview--put-window-plist (prop val)
  "Set property list with PROP and VAL."
  (setq ivy-file-preview--window-status
        (plist-put ivy-file-preview--window-status prop val)))

;;
;; (@* "Core" )
;;

(defun ivy-file-preview--candidates ()
  "Return current ivy candidates."
  (or ivy--old-cands ivy--all-candidates '()))

(defun ivy-file-preview--no-candidates-p ()
  "Return nil if there is no candidate in current ivy session."
  (>= 0 (length (ivy-file-preview--candidates))))

(defun ivy-file-preview--extract-candidates-overlay-data ()
  "Extract the overlay data from current ivy candidates."
  (ivy-file-preview--init-ov-data)
  (let* ((fn (s-replace ivy-file-preview--current-dir "" ivy-file-preview--selected-file))
         (cands (ivy-file-preview--candidates))
         (cands-len (length cands)) current-cand entered ln-data
         ln col
         cand-fn (results '()) break (index 0))
    (while (and (not break) (< index cands-len))
      (setq current-cand (nth index cands)
            ln-data (ivy-file-preview--read-selection current-cand)
            cand-fn (nth 0 ln-data))
      (if (string= cand-fn fn)
          (progn
            (setq ln (nth 1 ln-data) col (nth 2 ln-data))
            (push (list :line-number ln :column col) results)
            (setq entered t))
        (when entered (setq break t)))
      (setq index (1+ index)))
    (reverse results)))

(defun ivy-file-preview--swap-current-overlay ()
  "Delete the previous selected overlay and swap with current selected overlay."
  (let* ((start (point)) (end (ivy-file-preview--match-end start)))
    (move-overlay ivy-file-preview--current-overlay start end)))

(defun ivy-file-preview--make-overlays ()
  "Make overlays through out the whole buffer."
  (let ((ov-data (ivy-file-preview--extract-candidates-overlay-data))
        (index 0)
        pos end ln col
        current-ov-p
        (current-ln (line-number-at-pos)) delta-ln)
    (dolist (data ov-data)
      (setq ln (plist-get data :line-number) col (plist-get data :column))
      (if (not col)
          (setq pos ln)
        (setq ln (string-to-number ln) col (string-to-number col)
              delta-ln (- ln current-ln)
              pos (ivy-file-preview--convert-pos-delta delta-ln col)
              end (ivy-file-preview--match-end pos index)))
      (setq current-ov-p (= pos (point)))
      (ivy-file-preview--make-overlay pos end)
      (when current-ov-p
        (ivy-file-preview--make-current-overlay pos end))
      (setq index (1+ index)))))

(defun ivy-file-preview--delay-make-overlays ()
  "Seconds to delay display overlays."
  (with-selected-window minibuffer-scroll-window
    (ivy-file-preview--delete-overlays)
    (ivy-file-preview--make-overlays)))

(defun ivy-file-preview--open-file (fn pos)
  "Open the file path (FN) and move to POS.
If POS is nil then it won't moves."
  (let ((is-file-p t) (just-fn (f-filename fn)))
    (cond ((file-exists-p fn)
           (setq ivy-file-preview--selected-file fn)
           (find-file fn))
          ((not ivy-file-preview-details) (setq is-file-p nil))
          ((or (find-buffer-visiting fn) (get-buffer just-fn))
           (setq ivy-file-preview--selected-file just-fn)
           (switch-to-buffer just-fn))
          (t
           (setq ivy-file-preview--selected-file ""
                 is-file-p nil)))
    (when is-file-p
      (cond ((consp pos)
             (ivy-file-preview--goto-line (car pos))
             (move-to-column (cdr pos))
             (recenter))
            ((integerp pos)
             (goto-char (1+ pos))
             (recenter))
            ((not pos) (goto-char (point-min)))
            (t (error "Invalid position details: %s" pos))))
    is-file-p))

(defun ivy-file-preview--do-preview (fn pos)
  "Do file preview execution.
FN is the file path.  POS can either be one of the following type:
  * integer : Position in file.
  * cons cell : Contain two integer. (line-number & column)
  * nil : Just open it without moving the point."
  (with-selected-window minibuffer-scroll-window
    (let (valid-file-p)
      (when (and ivy-file-preview-preview-only
                 (not (find-buffer-visiting fn))
                 (buffer-file-name))
        (push fn ivy-file-preview--preview-files))
      (unless (string= ivy-file-preview--selected-file fn)
        (ivy-file-preview--delete-overlays))
      (setq valid-file-p (ivy-file-preview--open-file fn pos))
      (when (and ivy-file-preview-overlay-p ivy-file-preview-details valid-file-p)
        (if (and (string= ivy-file-preview--ivy-text ivy-text)
                 ivy-file-preview--current-overlay)
            (ivy-file-preview--swap-current-overlay)
          (ivy-file-preview--safe-kill-timer ivy-file-preview--overlay-timer)
          (setq ivy-file-preview--overlay-timer
                (run-with-timer ivy-file-preview-overlay-delay-time nil
                                #'ivy-file-preview--delay-make-overlays)))
        (setq ivy-file-preview--ivy-text ivy-text)))))

(defun ivy-file-preview--read-selection (selection)
  "Read SELECTION and return list of data (file, line, column)."
  (let ((buf-lst (buffer-list)) buf-name buf-regex sel-lst)
    (setq found
          (cl-some (lambda (buf)
                     (setq buf-name (buffer-name buf)
                           buf-regex (format "^%s" (regexp-quote buf-name)))
                     (string-match-p buf-regex selection))
                   buf-lst))
    (setq selection (s-replace-regexp buf-regex "" selection)
          sel-lst (split-string selection ":"))
    (list (if found buf-name (nth 0 sel-lst)) (nth 1 sel-lst) (nth 2 sel-lst))))

(defun ivy-file-preview--after-select (&rest _)
  "Execution after selection."
  (if (and ivy-file-preview-details
           (or (string-empty-p ivy-text) (ivy-file-preview--no-candidates-p)))
      (progn
        (ivy-file-preview--delete-overlays)
        (ivy-file-preview--back-to-pos))
    (let* ((cands (ivy-file-preview--candidates))
           (current-selection (or (nth ivy--index cands) ""))
           (sel-lst (ivy-file-preview--read-selection current-selection))
           (fn (nth 0 sel-lst)) (ln (nth 1 sel-lst)) (cl (nth 2 sel-lst))
           can-preview-p)
      (setq can-preview-p (if ivy-file-preview-details ln t))
      (when can-preview-p
        (setq ln (ignore-errors (cl-parse-integer ln))
              cl (ignore-errors (cl-parse-integer cl)))
        (setq fn (ivy-file-preview--get-file-path fn))
        (ivy-file-preview--do-preview fn (if cl (cons ln cl) ln))))))

(defun ivy-file-preview--back-to-pos ()
  "Back to starting position."
  (with-selected-window minibuffer-scroll-window
    (switch-to-buffer (plist-get ivy-file-preview--window-status :file))
    (goto-char (plist-get ivy-file-preview--window-status :position))))

(defun ivy-file-preview--cancel-revert ()
  "Revert frame status if user cancel the commands."
  (unless ivy-exit
    (setq ivy-file-preview--selected-file "")
    (switch-to-buffer (plist-get ivy-file-preview--window-status :file))
    (set-window-point minibuffer-scroll-window (plist-get ivy-file-preview--window-status :window-point))))

(defun ivy-file-preview--enter ()
  "Execution after minibuffer setup."
  (setq ivy-file-preview--this-command this-command
        ivy-file-preview--window-status '()
        ivy-file-preview--current-dir default-directory)
  (with-selected-window minibuffer-scroll-window
    (ivy-file-preview--put-window-plist :file (current-buffer))
    (ivy-file-preview--put-window-plist :window-point (window-point))
    (ivy-file-preview--put-window-plist :position (point))))

(defun ivy-file-preview--exit ()
  "Execution before minibuffer exits."
  (ivy-file-preview--cancel-revert)
  (ivy-file-preview--delete-overlays)
  (delete-dups ivy-file-preview--preview-files)
  (dolist (fn ivy-file-preview--preview-files)
    (unless (string= ivy-file-preview--selected-file fn)
      (ignore-errors (kill-buffer (f-filename fn)))))
  (setq ivy-file-preview--selected-file ""
        ivy-file-preview--ivy-text ""
        ivy-file-preview--current-dir ""
        ivy-file-preview--preview-files '()
        ivy-file-preview--this-command nil))

;;
;; (@* "Entry" )
;;

(defun ivy-file-preview--enable ()
  "Enable `ivy-file-preview'."
  (add-hook 'minibuffer-setup-hook #'ivy-file-preview--enter)
  (add-hook 'minibuffer-exit-hook #'ivy-file-preview--exit)
  (advice-add 'ivy--exhibit :after #'ivy-file-preview--after-select))

(defun ivy-file-preview--disable ()
  "Disable `ivy-file-preview'."
  (remove-hook 'minibuffer-setup-hook #'ivy-file-preview--enter)
  (remove-hook 'minibuffer-exit-hook #'ivy-file-preview--exit)
  (advice-remove 'ivy--exhibit #'ivy-file-preview--after-select))

;;;###autoload
(define-minor-mode ivy-file-preview-mode
  "Minor mode 'ivy-file-preview-mode'."
  :global t
  :require 'ivy-file-preview
  :group 'ivy-file-preview
  (if ivy-file-preview-mode (ivy-file-preview--enable) (ivy-file-preview--disable)))

(provide 'ivy-file-preview)
;;; ivy-file-preview.el ends here
