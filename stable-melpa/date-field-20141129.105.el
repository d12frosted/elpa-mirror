;;; date-field.el --- Date widget

;; Copyright (C) 2013  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: widgets
;; Package-Version: 20141129.105
;; Package-Commit: 11c9170d1f7b343233f7716d4c0a62be024c1654
;; URL: https://github.com/aki2o/emacs-date-field
;; Version: 0.0.1
;; Package-Requires: ((dash "2.9.0") (log4e "0.2.0") (yaxception "0.3.2"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; 
;; You'll be able to use a date widget by the following code
;; 
;; (widget-create 'date-field)
;; 
;; For more infomation, see <https://github.com/aki2o/emacs-date-field/blob/master/README.md>

;;; Dependencies:
;; 
;; - dash.el ( see <https://github.com/magnars/dash.el> )
;; - log4e.el ( see <https://github.com/aki2o/log4e> )
;; - yaxception.el ( see <https://github.com/aki2o/yaxception> )

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your elisp file.
;; 
;; (require 'date-field)

;;; Configuration:
;; 
;; Nothing.

;;; Customization:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "date-field-[^-]" :docstring t)
;; 
;;  *** END auto-documentation

;;; API:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'function :prefix "date-field-[^-]" :docstring t)
;; `date-field-highlight-column'
;; Highlight active column of current date widget using `date-field-column-face'.
;; `date-field-prompt-value'
;; Behave for a prompt-value property of WIDGET.
;; `date-field-validate'
;; Behave for a validate property of WIDGET.
;; `date-field-default-get'
;; Behave for a default-get property of WIDGET.
;; `date-field-value-set'
;; Behave for a value-set property of WIDGET.
;; `date-field-value-get'
;; Behave for a value-get property of WIDGET.
;; `date-field-value-create'
;; Behave for a value-create property of WIDGET.
;; `date-field-value-delete'
;; Behave for a value-delete property of WIDGET.
;; `date-field-match'
;; Behave for a match property of WIDGET.
;; 
;;  *** END auto-documentation
;; [EVAL] (autodoc-document-lisp-buffer :type 'command :prefix "date-field-[^-]" :docstring t)
;; `date-field-left'
;; Move active column to left.
;; `date-field-right'
;; Move active column to right.
;; `date-field-up'
;; Increment active column value.
;; `date-field-down'
;; Decrement active column value.
;; 
;;  *** END auto-documentation
;; [Note] Functions and variables other than listed above, Those specifications may be changed without notice.

;;; Tested On:
;; 
;; - Emacs ... GNU Emacs 24.3.1 (i686-pc-linux-gnu, GTK+ Version 3.4.2) of 2014-02-22 on chindi10, modified by Debian
;; - dash.el ... Version 2.9.0
;; - log4e.el ... Version 0.2.0
;; - yaxception.el ... Version 0.3.2

;; Enjoy!!!

;;; Code:

(eval-when-compile (require 'cl))
(require 'wid-edit)
(require 'dash)
(require 'log4e)
(require 'yaxception)


(defface date-field-face
  '((t (:inherit widget-field)))
  "Face for full date field."
  :group 'widget-faces)

(defface date-field-column-face
  '((t (:background "steel blue" :foreground "white")))
  "Face for active column of date field."
  :group 'widget-faces)


(log4e:deflogger "date-field" "%t [%l] %m" "%H:%M:%S" '((fatal . "fatal")
                                                        (error . "error")
                                                        (warn  . "warn")
                                                        (info  . "info")
                                                        (debug . "debug")
                                                        (trace . "trace")))
(date-field--log-set-level 'trace)


;;;;;;;;;;;;;
;; Utility

(defvar date-field--column-list '(year1 year2 year3 year4 month1 month2 day1 day2))

(defmacro date-field-aif (test then &rest else)
  (declare (indent 2))
  `(let ((it ,test)) (if it ,then ,@else)))

(defun date-field--format-column (col &optional year-p)
  (let ((col (cond ((stringp col) (string-to-number col))
                   ((numberp col) col)
                   (t             0)))
        (fmt (if year-p "%04d" "%02d")))
    (format fmt col)))

(defun date-field--make-columns (value separator)
  (when (stringp value)
    (let ((ret (split-string value separator)))
      (when (and (= (length ret) 3)
                 (loop for e in ret
                       always (string-match "\\`[0-9]+\\'" e)))
        (mapcar 'string-to-number ret)))))

(defun date-field--make-decoded-time (value separator)
  (let ((vcols (date-field--make-columns value separator)))
    `(0 0 0 ,@(reverse vcols) 0 nil 0)))

(yaxception:deferror 'date-field-invalid-time nil "Maybe you tried to update field to invalid date")

(defun date-field--make-value-by-time (decoded-time separator)
  (let* ((fmt (concat "%Y" separator "%m" separator "%d"))
         (time (yaxception:$
                 (yaxception:try
                   (apply 'encode-time (or decoded-time
                                           (decode-time (current-time)))))
                 (yaxception:catch 'error e
                   (let ((year (nth 5 decoded-time))
                         (month (nth 4 decoded-time))
                         (day (nth 3 decoded-time)))
                     (date-field--error "faild encode time : %s" decoded-time)
                     (if (and year month day)
                         (yaxception:throw 'date-field-invalid-time)
                       (yaxception:throw e)))))))
    (format-time-string fmt time)))

(defun date-field--make-value (year month day separator)
  (concat (date-field--format-column year t)
          separator
          (date-field--format-column month)
          separator
          (date-field--format-column day)))

(defun date-field--get-buffer (widget)
  (let ((ov (widget-get widget :full-overlay)))
    (when (overlayp ov)
      (overlay-buffer ov))))

(defun date-field--get-next-member (list member)
  (loop with found = nil
        for e in list
        if found
        return e
        else if (eq e member)
        do (setq found t)
        finally return (nth 0 list)))

(defun date-field--get-next-column-name (colnm)
  (date-field--get-next-member date-field--column-list colnm))

(defun date-field--get-previous-column-name (colnm)
  (date-field--get-next-member (reverse date-field--column-list) colnm))

(defun date-field--get-widget-at (&optional pos)
  (let ((widget (widget-at pos)))
    (when (and widget
               (eq (widget-type widget) 'date-field))
      widget)))

(defun date-field--get-column-point-pairs (widget)
  (let ((from (widget-get widget :from))
        (sepwidth (string-width (widget-get widget :separator))))
    `((year1  . ,from)
      (year2  . ,(+ from 1))
      (year3  . ,(+ from 2))
      (year4  . ,(+ from 3))
      (month1 . ,(+ from 3 sepwidth 1))
      (month2 . ,(+ from 3 sepwidth 2))
      (day1   . ,(+ from 3 sepwidth 2 sepwidth 1))
      (day2   . ,(+ from 3 sepwidth 2 sepwidth 2)))))

(defun date-field--get-column-name-at (pos &optional widget)
  (let* ((widget (or widget (date-field--get-widget-at pos)))
         (pairs (when widget
                  (date-field--get-column-point-pairs widget))))
    (loop for (colnm . pt) in pairs
          if (= pt pos) return colnm)))

(defun date-field--get-column-point (widget colnm)
  (let ((pairs (date-field--get-column-point-pairs widget)))
    (assoc-default colnm pairs)))


;;;;;;;;;;;;;;;;;;;;;
;; Highlight Column

(defvar date-field--column-overlay nil)
(make-variable-buffer-local 'date-field--column-overlay)

(defun date-field--move-column-overlay (widget colnm)
  (let ((pt (date-field--get-column-point widget colnm)))
    (if (overlayp date-field--column-overlay)
        (move-overlay date-field--column-overlay pt (1+ pt))
      (setq date-field--column-overlay (make-overlay pt (1+ pt) nil t nil))
      (overlay-put date-field--column-overlay 'face 'date-field-column-face)
      (overlay-put date-field--column-overlay 'evaporate t))))

(defun date-field--over-column-overlay-p (widget)
  (let ((pt (when (overlayp date-field--column-overlay)
              (overlay-start date-field--column-overlay))))
    (and pt
         (>= pt (widget-get widget :from))
         (<= pt (widget-get widget :to)))))

(defun date-field--get-column-name-under-overlay (&optional widget)
  (date-field--get-column-name-at (overlay-start date-field--column-overlay) widget))

(defun date-field--get-active-point ()
  (if (overlayp date-field--column-overlay)
      (overlay-start date-field--column-overlay)
    (point)))

(defun date-field--highlight-column-interactively (srchfunc)
  (let* ((pos (date-field--get-active-point))
         (widget (date-field--get-widget-at pos))
         (colnm (when widget
                  (date-field--get-column-name-at pos widget)))
         (ncolnm (when colnm
                   (funcall srchfunc colnm))))
    (when ncolnm
      (date-field--move-column-overlay widget ncolnm))))

(defun date-field-highlight-column ()
  "Highlight active column of current date widget using `date-field-column-face'."
  (yaxception:$
    (yaxception:try
      (date-field--trace "start highlight column.")
      (let ((widget (date-field--get-widget-at)))
        (cond (widget
               (when (not (date-field--over-column-overlay-p widget))
                 (date-field--move-column-overlay widget 'day2)))
              (t
               (when (overlayp date-field--column-overlay)
                 (delete-overlay date-field--column-overlay))))))
    (yaxception:catch 'error e
      (date-field--error "failed highlight column : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e)))))

(defun date-field-left ()
  "Move active column to left."
  (interactive)
  (yaxception:$
    (yaxception:try
      (date-field--trace "start left.")
      (date-field--highlight-column-interactively 'date-field--get-previous-column-name))
    (yaxception:catch 'error e
      (date-field--error "failed left : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e))
      (message "Failed date-field-left : %s" (yaxception:get-text e)))))

(defun date-field-right ()
  "Move active column to right."
  (interactive)
  (yaxception:$
    (yaxception:try
      (date-field--trace "start right.")
      (date-field--highlight-column-interactively 'date-field--get-next-column-name))
    (yaxception:catch 'error e
      (date-field--error "failed right : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e))
      (message "Failed date-field-right : %s" (yaxception:get-text e)))))


;;;;;;;;;;;;;;;;;;
;; Update Column

(defun date-field--update-decoded-time (decoded-time unit-name quantity)
  (date-field--trace "start update decoded time.\ndecoded-time... %s\nunit-name... %s\nquantity... %s"
                     decoded-time unit-name quantity)
  (let ((days (case unit-name
                (year  (* quantity 365))
                (month (* quantity 30))
                (day   quantity))))
    (append (-slice decoded-time 0 3)
            (list (+ (nth 3 decoded-time) days))
            (-slice decoded-time 4))))

(defun date-field--update-column-interactively (increment-p)
  (let* ((pos (date-field--get-active-point))
         (widget (date-field--get-widget-at pos))
         (colnm (when widget
                  (date-field--get-column-name-at pos widget)))
         (unit-name (case colnm
                      ((year1 year2 year3 year4) 'year)
                      ((month1 month2)           'month)
                      ((day1 day2)               'day)))
         (quantity (case colnm
                     ((year4 month2 day2) 1)
                     ((year3 month1 day1) 10)
                     (year2               100)
                     (year1               1000)))
         (quantity (when quantity
                     (if increment-p (+ quantity) (- quantity))))
         (value (when widget
                  (date-field-value-get widget)))
         (separator (when widget
                      (widget-get widget :separator)))
         (time (when value
                 (date-field--make-decoded-time value separator)))
         (utime (when time
                  (date-field--update-decoded-time time unit-name quantity))))
    (when utime
      (date-field-value-set widget
                            (date-field--make-value-by-time utime separator)))))

(defun date-field-up ()
  "Increment active column value."
  (interactive)
  (yaxception:$
    (yaxception:try
      (date-field--trace "start up.")
      (date-field--update-column-interactively t))
    (yaxception:catch 'error e
      (date-field--error "failed up : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e))
      (message "Failed date-field-up : %s" (yaxception:get-text e)))))

(defun date-field-down ()
  "Decrement active column value."
  (interactive)
  (yaxception:$
    (yaxception:try
      (date-field--trace "start down.")
      (date-field--update-column-interactively nil))
    (yaxception:catch 'error e
      (date-field--error "failed down : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e))
      (message "Failed date-field-down : %s" (yaxception:get-text e)))))


;;;;;;;;;;;;;;;;;;;;;
;; Widget Behavior

(defun date-field-prompt-value (widget prompt value unbound)
  "Behave for a prompt-value property of WIDGET."
  (yaxception:$
    (yaxception:try
      (date-field--trace "start prompt value : %s" value)
      (widget-value widget))
    (yaxception:catch 'error e
      (date-field--error "failed prompt value : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e))
      (yaxception:throw e))))

(defun date-field-validate (widget)
  "Behave for a validate property of WIDGET."
  (yaxception:$
    (yaxception:try
      (date-field--trace "start validate.")
      (let* ((separator (widget-get widget :separator))
             (re (concat "\\`[0-9][0-9][0-9][0-9]"
                         (regexp-quote separator)
                         "[0-9][0-9]"
                         (regexp-quote separator)
                         "[0-9][0-9]\\'")))
        (unless (string-match re (widget-apply widget :value-get))
          widget)))
    (yaxception:catch 'error e
      (date-field--error "failed validate : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e))
      (yaxception:throw e))))

(defun date-field-default-get (widget)
  "Behave for a default-get property of WIDGET."
  (yaxception:$
    (yaxception:try
      (date-field--trace "start default get.")
      (date-field--make-value-by-time nil (widget-get widget :separator)))
    (yaxception:catch 'error e
      (date-field--error "failed default get : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e))
      (yaxception:throw e))))

(defun date-field-value-set (widget value)
  "Behave for a value-set property of WIDGET."
  (yaxception:$
    (yaxception:try
      (date-field--trace "start value set : %s" value)
      (let* ((from (widget-get widget :from))
             (to (widget-get widget :to))
             (buffer (date-field--get-buffer widget))
             (separator (widget-get widget :separator))
             (vcols (date-field--make-columns value separator))
             (ret (date-field-aif vcols
                      (apply 'date-field--make-value (append it (list separator)))
                    (date-field--make-value-by-time nil separator)))
             (rcols (date-field--make-columns ret separator))
             (colnm (when (date-field--over-column-overlay-p widget)
                      (date-field--get-column-name-under-overlay widget))))
        (when (and from to (buffer-live-p buffer))
          (with-current-buffer buffer
            (let ((inhibit-read-only t))
              (goto-char (1+ from))
              (insert ret)
              (delete-char (1- (length ret)))
              (goto-char from)
              (delete-char 1)
              (widget-put widget :value ret)
              (widget-put widget :year  (nth 0 rcols))
              (widget-put widget :month (nth 1 rcols))
              (widget-put widget :day   (nth 2 rcols))
              (when colnm
                (date-field--move-column-overlay widget colnm)))))))
    (yaxception:catch 'error e
      (date-field--error "failed value set : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e))
      (yaxception:throw e))))

(defun date-field-value-get (widget)
  "Behave for a value-get property of WIDGET."
  (yaxception:$
    (yaxception:try
      (date-field--trace "start value get.")
      (let* ((from (widget-get widget :from))
             (to (widget-get widget :to))
             (buffer (date-field--get-buffer widget)))
        (if (and from to (buffer-live-p buffer))
            (with-current-buffer buffer
              (buffer-substring-no-properties from to))
          (widget-default-get widget))))
    (yaxception:catch 'error e
      (date-field--error "failed value get : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e))
      (yaxception:throw e))))

(defun date-field-value-create (widget)
  "Behave for a value-create property of WIDGET."
  (yaxception:$
    (yaxception:try
      (date-field--trace "start value create.")
      (let* ((separator (widget-get widget :separator))
             (keymap (widget-get widget :keymap))
             (dcols (date-field--make-columns (date-field-default-get widget) separator))
             (year (date-field-aif (widget-get widget :year)
                       (string-to-number (date-field--format-column it t))
                     (nth 0 dcols)))
             (month (date-field-aif (widget-get widget :month)
                        (string-to-number (date-field--format-column it))
                      (nth 1 dcols)))
             (day (date-field-aif (widget-get widget :day)
                      (string-to-number (date-field--format-column it))
                    (nth 2 dcols)))
             (value (date-field--make-value year month day separator))
             (from (point))
             (to (progn (insert value)
                        (point)))
             (ov (make-overlay from to nil t nil)))
        (overlay-put ov 'face 'date-field-face)
        (overlay-put ov 'evaporate t)
        (overlay-put ov 'field widget)
        (when keymap
          (overlay-put ov 'local-map keymap))
        (widget-put widget :full-overlay ov)
        (widget-put widget :value value)
        (add-hook 'post-command-hook 'date-field-highlight-column t t)))
    (yaxception:catch 'error e
      (date-field--error "failed value create : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e))
      (yaxception:throw e))))

(defun date-field-value-delete (widget)
  "Behave for a value-delete property of WIDGET."
  (yaxception:$
    (yaxception:try
      (date-field--trace "start value delete.")
      (let ((ov (widget-get widget :full-overlay)))
        (when (overlayp ov)
          (delete-overlay ov))
        (widget-put widget :full-overlay nil)))
    (yaxception:catch 'error e
      (date-field--error "failed value delete : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e))
      (yaxception:throw e))))

(defun date-field-match (widget value)
  "Behave for a match property of WIDGET."
  (yaxception:$
    (yaxception:try
      (date-field--trace "start match : %s" value)
      (when (date-field--make-columns value (widget-get widget :separator))
        t))
    (yaxception:catch 'error e
      (date-field--error "failed match : %s\n%s"
                         (yaxception:get-text e)
                         (yaxception:get-stack-trace-string e))
      (yaxception:throw e))))


;;;;;;;;;;;;;;;;;;;
;; Define Widget

(defvar date-field-keymap
  (let ((map (copy-keymap widget-keymap)))
    (define-key map (kbd "j") 'date-field-up)
    (define-key map (kbd "k") 'date-field-down)
    (define-key map (kbd "h") 'date-field-left)
    (define-key map (kbd "l") 'date-field-right)
    (define-key map (kbd "n") 'date-field-up)
    (define-key map (kbd "p") 'date-field-down)
    (define-key map (kbd "b") 'date-field-left)
    (define-key map (kbd "f") 'date-field-right)
    map)
  "Keymap on date widget.")

(define-widget 'date-field 'default
  "A date field.

Getting value:
 `widget-value' returns a string like \"yyyy/mm/dd\" (in default separator).
  A year/month/day property using `widget-get' returns a number of that.

Setting value:
 `widget-value-set' accepts only string to fit the format of the date-field value.
 If a given value is invalid, set current date.

Optional properties for `widget-create':
 - keymap    ... `date-field-keymap' is used in default.
 - separator ... a string to separate year/month/day. \"/\" in default.
 - year      ... init value of year.  current year in default.
 - month     ... init value of month. current month in default.
 - day       ... init value of day.   current day in default."
  :convert-widget 'widget-value-convert-widget
  :keymap date-field-keymap
  :format "%v"
  :help-echo "j,n:[up column value] k,p:[down column value] h,b:[select left column] l,f:[select right column]"
  :value nil
  :prompt-value 'date-field-prompt-value
  :action 'widget-field-action
  :validate 'date-field-validate
  :error "Field's value doesn't match allowed forms"
  :default-get 'date-field-default-get
  :value-set 'date-field-value-set
  :value-get 'date-field-value-get
  :value-create 'date-field-value-create
  :value-delete 'date-field-value-delete
  :match 'date-field-match
  :separator "/")


(provide 'date-field)
;;; date-field.el ends here
