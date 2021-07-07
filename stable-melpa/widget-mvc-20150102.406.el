;;; widget-mvc.el --- MVC framework for the emacs widgets

;; Author: SAKURAI Masashi <m.sakurai at kiwanami.net>
;; Copyright (C) 2013 
;; Keywords: lisp, widget
;; Package-Version: 20150102.406
;; Package-Commit: ff5a85880df7b87f9f480fe3c28438a0712b7b87
;; Version: 0.0.2

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

;; * Overview
;; This library provides following functions:
;;  - Widget Template
;;    - template helpers
;;  - Data Binding
;;  - Validation
;;  - Action Mapping
;;  - Session Attributes
;; 
;; * Widget Template
;; 
;; Sample:
;; 
;; Syntax:
;; 

;; Todo
;;   component
;;   popup select
;;   user-action

;;; Code:

(eval-when-compile (require 'cl))
(require 'widget)
(require 'wid-edit)
(require 'date-field nil t)


;;; Utilities

(defmacro wmvc:aand (test &rest rest)
  "Anaphoric AND."
  (declare (debug (form &rest form)))
  `(let ((it ,test))
     (if it ,(if rest (macroexpand-all `(wmvc:aand ,@rest)) 'it))))

(defvar wmvc:default-buffer-name "*wmvc-buffer*" "[internal] Default buffer name.")

(defun wmvc:get-new-buffer (&optional buffer-name)
  "[internal] Create and return a buffer object.
This function kills the old buffer if it exists."
  (unless buffer-name (setq buffer-name wmvc:default-buffer-name))
  (let ((buf (get-buffer buffer-name)))
    (when (and buf (buffer-live-p buf))
      (kill-buffer buf)))
  (get-buffer-create buffer-name))


;;; get-text

;; ( (lang-id1 (msg-id1 . "message1") (msg-id2 . "message2") ... )
;;   (lang-id2 ... ) )
;; lang-id : t = English
(defvar wmvc:lang-messages nil)

(defun wmvc:lang-register-messages (lang-id messages)
  "Register messages which are returned by `wmvc:get-text'.

LANG-ID is a symbol which equals to a one of keys of `language-info-alist'.
For check the allowed value, see customize of `current-language-environment'.
If this value is t, it's considered as 'English.

MESSAGES : (msg-id1 \"message1\" msg-id2 \"message2\" ... )"
  (let* ((lang-id (if (eq lang-id t) 'English lang-id))
         (lang-pair (assq lang-id wmvc:lang-messages))
         (alist (and lang-pair (cdr lang-pair))))
    (unless (assoc (symbol-name lang-id) language-info-alist)
      (error "Unknown language : %s" lang-id))
    (unless lang-pair
      (setq lang-pair (cons lang-id nil))
      (setq wmvc:lang-messages (cons lang-pair wmvc:lang-messages)))
    (let ((elms messages) key val)
      (while elms
        (setq key (car elms))
        (setq elms (cdr elms))
        (setq val (car elms))
        (setq elms (cdr elms))
        (setq alist (cons (cons key val) alist)))
      (setf (cdr lang-pair) alist))
    lang-pair))

(defun wmvc:get-text (ctx msg-id &rest args)
  "Return a message of MSG-ID.
CTX is a `wmvc:context'. If nil, use `current-language-environment'."
  (let* ((lang-id (if (wmvc:context-p ctx)
                      (wmvc:context-lang ctx)
                    (intern current-language-environment)))
         (pair (assq lang-id wmvc:lang-messages)))
    (unless pair
      (setq pair (assq 'English wmvc:lang-messages)))
    (cond
     ((null pair) msg-id)
     (t 
      (let ((mpair (assq msg-id (cdr pair))))
        (if mpair (apply 'format (cdr mpair) args) msg-id))))))


;;; MVC Context

;; [wmvc:context]
;; lang        : a symbol of the language for messages. If `nil', the framework displays default messages.
;; template    : a list of the form template 
;; model       : an alist of the current model data
;; validations : an alist of the validation functions
;; widget-map  : an alist of the widget instances
;; action-map  : an alist of the action functions
;; attributes  : an alist of custom attributes for user programs

(defstruct wmvc:context lang template model validations widget-map action-map attributes)

(defvar wmvc:context nil)

(defun wmvc:context-attr-set (context name value)
  (let ((attrs (wmvc:context-attributes context)))
    (cond
     ((assq name attrs)
      (let ((pair (assq name attrs)))
        (setf (cdr pair) value)))
     (t (setq attrs (cons (cons name value) attrs))))
    (setf (wmvc:context-attributes context) attrs)))

(defun wmvc:context-attr-get (context name)
  (let ((attrs (wmvc:context-attributes context)))
    (cdr (assq name attrs))))

(defun wmvc:context-widget-map-add (context name widget)
  (let ((widget-map (cons (cons name widget) 
                          (wmvc:context-widget-map context))))
    (setf (wmvc:context-widget-map context) widget-map)))


;;; Template

(defun wmvc:tmpl-build-buffer(buffer context)
  (let ((tmpl-src (wmvc:context-template context))
        (model (wmvc:context-model context)))
    (with-current-buffer buffer
      (setf (wmvc:context-widget-map context) nil)
      (let ((inhibit-read-only t))
        (erase-buffer))
      (remove-overlays)
      (loop for elm in tmpl-src
            do
            (cond
             ((consp elm)
              (wmvc:tmpl-make-widget elm context))
             ((stringp elm)
              (widget-insert elm))
             ((eq elm 'BR)
              (widget-insert "\n"))
             ((not elm) nil)
             (t (error "Found a wrong template element : %s" elm))))
      (wmvc:bind-from-model context)
      (use-local-map widget-keymap)
      (widget-setup)
      (set (make-local-variable 'wmvc:context) context)
      (goto-char (point-min))
      (widget-forward 1))
    (wmvc:context-attr-set context 'error nil)
    buffer))

(defun wmvc:tmpl-widget-create (elm-plist context type &rest args)
  (declare (indent 2))
  (lexical-let* ((action (plist-get elm-plist ':action))
                 (need-validation (plist-get elm-plist ':validation))
                 (notify (lambda (&rest ignore)
                           (wmvc:action-invoke action need-validation)))
                 (args (loop for (k v) on args by 'cddr
                             if v append (list k v)))
                 (help-echo (or (plist-get args ':help-echo)
                                (plist-get elm-plist ':help-echo))))
    (if help-echo (plist-put args ':help-echo help-echo))
    (apply 'widget-create
           (append (list type)
                   (if action (list :notify notify))
                   args))))

(defun wmvc:tmpl-make-widget (elm context)
  "[internal] "
  (let* ((elm-type (car elm))
         (elm-plist (cdr elm)))
    (case elm-type
     ('input (wmvc:tmpl-make-widget-input elm-plist context))
     ('button (wmvc:tmpl-make-widget-button elm-plist context))
     ('message (wmvc:tmpl-make-widget-message elm-plist context)))))

(defun wmvc:tmpl-make-widget-input (elm-plist context)
  (let* ((type (plist-get elm-plist ':type)) 
         (name (plist-get elm-plist ':name))
         (widget
          (case type
            ('const
             (wmvc:tmpl-make-widget-input-const elm-plist context))
            ('text 
             (wmvc:tmpl-make-widget-input-text elm-plist context))
            ('password
             (plist-put elm-plist ':secret t)
             (wmvc:tmpl-make-widget-input-text elm-plist context))
            ('checkbox
             (wmvc:tmpl-make-widget-input-checkbox elm-plist context))
            ('radio
             (wmvc:tmpl-make-widget-input-radio elm-plist context))
            ('select
             (if (plist-get elm-plist ':multiple)
                 (wmvc:tmpl-make-widget-input-mselect elm-plist context)
               (wmvc:tmpl-make-widget-input-select elm-plist context)))
            ('link
             (wmvc:tmpl-make-widget-input-link elm-plist context))
            ('date
             (wmvc:tmpl-make-widget-input-date elm-plist context))
            (t (error "Unknown input type : %s" type)))))
    (wmvc:aand
     (wmvc:context-attr-get context 'error)
     (assq name it) (cdr it)
     (widget-insert (propertize (concat " (" it ") ") 'face 'compilation-error)))
    (wmvc:context-widget-map-add context name widget)))

(defun wmvc:tmpl-make-widget-input-const (elm-plist context)
  (let* ((name (plist-get elm-plist ':name))
         (model (wmvc:context-model context))
         (pair (assq name model))
         (value (or (cdr-safe pair)
                    (plist-get elm-plist ':value)))
         (face (plist-get elm-plist ':face)))
    (when pair
      (setq model (delq pair model)))
    (setf (wmvc:context-model context) (cons (cons name value) model))
    (apply 'widget-create
           (append '(const :format "%{%t%}")
                   (if face (list :sample-face face))))))

(defun wmvc:tmpl-make-widget-input-text (elm-plist context)
  (let ((size (plist-get elm-plist ':size))
        (format (plist-get elm-plist ':format))
        (keymap (plist-get elm-plist ':keymap))
        (area (plist-get elm-plist ':area))
        (secret (if (plist-get elm-plist ':secret) ?*))
        (value (cdr-safe (assq (plist-get elm-plist ':name)
                               (wmvc:context-model context)))))
    (wmvc:tmpl-widget-create elm-plist context
      (if area 'text 'editable-field)
      :secret secret :size size :format format :keymap keymap :value value)))

(defun wmvc:tmpl-make-widget-input-checkbox (elm-plist context)
  (wmvc:tmpl-widget-create elm-plist context 'checkbox))

(defun wmvc:tmpl-make-widget-input-radio (elm-plist context)
  (let ((options (plist-get elm-plist ':options))
        (indent (or (plist-get elm-plist ':indent)
                    (current-column)))
        (format  (or (plist-get elm-plist ':format) "%b%v"))
        (horizontal (plist-get elm-plist ':horizontal)))
    (wmvc:tmpl-widget-create elm-plist context
      'radio-button-choice
      :indent (if horizontal 0 indent) :entry-format format
      :args
      (cond
       ((consp (car options))
        (loop for i = (pop options)
              while i
              for (item-title . value) = i
              for format = (cond ((and horizontal (car options)) "%t ")
                                 ((car options)                  "%t\n")
                                 (t                              "%t"))
              collect
              (list 'item ':tag item-title ':value value ':format format)))
       (t
        (loop for i = (pop options)
              while i
              for format = (cond ((and horizontal (car options)) "%t ")
                                 ((car options)                  "%t\n")
                                 (t                              "%t"))
              collect
              (list 'item ':tag (format "%s" i) ':value i ':format format)))))))

(defun wmvc:tmpl-make-widget-input-select (elm-plist context)
  (let ((options (plist-get elm-plist ':options))
        (title   (or (plist-get elm-plist ':title) "select"))
        (format  (or (plist-get elm-plist ':format) "[%[%t%]] %v"))
        (void    (or (plist-get elm-plist ':void) '(item :format "*Not Selected*")))
        (help-echo (or (plist-get elm-plist ':help-echo)
                       (wmvc:get-text context 'input-select-click-to-choose))))
    (wmvc:tmpl-widget-create elm-plist context
      'menu-choice
      :format format :tag title :help-echo help-echo :void void
      :args
      (cond
       ((consp (car options))
        (loop for i in options
              for (item-title . value) = i
              collect
              (list 'item ':tag item-title ':value value ':format "%t")))
       (t
        (loop for i in options
              collect
              (list 'item ':tag (format "%s" i) ':value i ':format "%t")))))))

(wmvc:lang-register-messages 't '(input-select-click-to-choose "Click to choose"))
(wmvc:lang-register-messages 'Japanese '(input-select-click-to-choose "クリックして選択"))

(defun wmvc:tmpl-make-widget-input-mselect (elm-plist context)
  (let ((options (plist-get elm-plist ':options))
        (indent (or (plist-get elm-plist ':indent)
                    (current-column)))
        (format  (or (plist-get elm-plist ':format) "%b%v"))
        (horizontal (plist-get elm-plist ':horizontal)))
    (wmvc:tmpl-widget-create elm-plist context
      'checklist
      :indent (if horizontal 0 indent) :entry-format format
      :args
      (cond
       ((consp (car options))
        (loop for i = (pop options)
              while i
              for (item-title . value) = i
              for format = (cond ((and horizontal (car options)) "%t ")
                                 ((car options)                  "%t\n")
                                 (t                              "%t"))
              collect
              (list 'item ':tag item-title ':value value ':format format)))
       (t
        (loop for i = (pop options)
              while i
              for format = (cond ((and horizontal (car options)) "%t ")
                                 ((car options)                  "%t\n")
                                 (t                              "%t"))
              collect
              (list 'item ':tag (format "%s" i) ':value i ':format format)))))))

(defun wmvc:tmpl-make-widget-input-link (elm-plist context)
  (let* ((name (plist-get elm-plist ':name))
         (model (wmvc:context-model context))
         (pair (assq name model))
         (url (plist-get elm-plist ':url))
         (info (plist-get elm-plist ':info))
         (file (plist-get elm-plist ':file))
         (value (or url
                    info
                    file
                    (cdr-safe pair)
                    (plist-get elm-plist ':value)))
         (title (or (plist-get elm-plist ':title) value))
         (type (cond (url  'url-link)
                     (info 'info-link)
                     (file 'file-link)
                     (t    'link)))
         (face (plist-get elm-plist ':face)))
    (when pair
      (setq model (delq pair model)))
    (setf (wmvc:context-model context) (cons (cons name value) model))
    (wmvc:tmpl-widget-create elm-plist context
      type
      :tag title :button-face face :mouse-face 'highlight :pressed-face 'highlight)))

(defun wmvc:tmpl-make-widget-input-date (elm-plist context)
  (if (not (featurep 'date-field))
      (error "Can't make date field widget : date-field is not installed yet.")
    (let ((separator (plist-get elm-plist ':separator))
          (year (plist-get elm-plist ':year))
          (month (plist-get elm-plist ':month))
          (day (plist-get elm-plist ':day)))
      (wmvc:tmpl-widget-create elm-plist context
        'date-field
        :separator separator :year year :month month :day day))))

(defun wmvc:tmpl-make-widget-button (elm-plist context)
  (let ((name (plist-get elm-plist ':name))
        (widget (wmvc:tmpl-widget-create elm-plist context
                  'push-button
                  :value (plist-get elm-plist ':title))))
    (when name
      (wmvc:context-widget-map-add context name widget))))

(defun wmvc:tmpl-make-widget-message (elm-plist context)
  (let* ((key (plist-get elm-plist ':key)) 
         (face (plist-get elm-plist ':face))
         (msg (wmvc:context-attr-get context key)))
    (when msg
      (widget-insert
       (if face (propertize msg 'face face) msg)))))

;;; binding / validation

(defun wmvc:bind-from-model (context)
  "[internal] "
  (loop with widget-map = (wmvc:context-widget-map context)
        with model = (wmvc:context-model context)
        for (name . widget) in widget-map
        for (fname . data) = (assq name model)
        do 
        (when (and fname
                   data
                   ;; `widget-value-set' might cause widget value is lost on some widgets.
                   ;; So, the widget value is set in `wmvc:tmpl-make-widget-input'.
                   (not (memq (widget-type widget) '(editable-field text))))
          (widget-value-set widget data)
          (widget-setup))))

(defun wmvc:bind-from-widgets (context)
  (loop with widget-map = (wmvc:context-widget-map context)
        with model = (wmvc:context-model context)
        for (name . widget) in widget-map
        for pair = (assq name model)
        if pair
        do
        (setf (cdr pair) (widget-value widget))
        finally return model))

(defun wmvc:validate-fields (model)
  (let* ((ctx wmvc:context)
         (validations (wmvc:context-validations ctx))
         (fails ; list of (name . fail-message)
          (loop for (name . vs) in validations
                for validation-func = (if (consp vs) (car vs) vs)
                for validation-args = (if (consp vs) (cdr vs))
                for value = (cdr (assq name model))
                for result = (apply validation-func ctx value validation-args)
                if result
                collect (cons name result))))
    (when fails
      (wmvc:context-attr-set ctx 'error fails)
      (wmvc:reload-buffer ctx)
      (throw 'fail nil))))

(wmvc:lang-register-messages 
 't '(
      validation-not-be-empty "should not empty."
      validation-be-integer "should be a number."
      validation-be-decimal-number "should be a decimal number."
      validation-be-greater-than "should be greater than %s."
      validation-be-less-than "should be less than %s"
      validation-be-longer-than "should be longer than %s."
      validation-be-shorter-than "should be shorter than %s"
      ))
(wmvc:lang-register-messages 
 'Japanese '(
      validation-not-be-empty "必須入力"
      validation-be-integer "整数値"
      validation-be-decimal-number "数値"
      validation-be-greater-than "%s 以上の数値"
      validation-be-less-than "%s 以下の数値"
      validation-be-longer-than "%s 文字以上"
      validation-be-shorter-than "%s 文字以下"
      ))

(defun wmvc:validation-not-empty (ctx value &rest args)
  (if (or (null value) (zerop (length value)))
      (wmvc:get-text ctx 'validation-not-be-empty)
    nil))

(defun wmvc:validation-integer (ctx value &rest args)
  (let ((min (plist-get args ':min))
        (max (plist-get args ':max)))
    (cond
     ((not (string-match "^[ ]*[-+]?[0-9]+[ ]*$" value))
      (wmvc:get-text ctx 'validation-be-integer))
     ((and min (< (string-to-number value) min))
      (wmvc:get-text ctx 'validation-be-greater-than min))
     ((and max (> (string-to-number value) max))
      (wmvc:get-text ctx 'validation-be-less-than max))
     (t nil))))

(defun wmvc:validation-decimal (ctx value &rest args)
  (let ((min (plist-get args ':min))
        (max (plist-get args ':max)))
    (cond
     ((not (string-match "^[ ]*[-+]?[0-9]+\\(\\.[0-9]*\\)?[ ]*$" value))
      (wmvc:get-text ctx 'validation-be-decimal-number))
     ((and min (< (string-to-number value) min))
      (wmvc:get-text ctx 'validation-be-greater-than min))
     ((and max (> (string-to-number value) max))
      (wmvc:get-text ctx 'validation-be-less-than max))
     (t nil))))

(defun wmvc:validation-length (ctx value &rest args)
  (let ((min (plist-get args ':min))
        (max (plist-get args ':max)))
    (cond
     ((and (null min) (null max)) nil)
     ((and min (< (length value) min))
      (wmvc:get-text ctx 'validation-be-longer-than min))
     ((and max (> (length value) max))
      (wmvc:get-text ctx 'validation-be-shorter-than max))
     (t nil))))


;;; action

(defun wmvc:action-invoke (action-name need-validation)
  "[internal] "
  (let* ((ctx wmvc:context)
         (action-map (wmvc:context-action-map ctx))
         (action (or (cdr (assq action-name action-map)) action-name))
         (xmodel (wmvc:bind-from-widgets ctx)))
    (catch 'fail
      (when need-validation
        (wmvc:validate-fields xmodel))
      (funcall action xmodel))))


;;; controller

(defun wmvc:reload-buffer (context)
  (let* ((win (get-buffer-window)) 
         (new-buf (wmvc:rebuild-buffer context)))
    (cond
     ((or (null win) (not (window-live-p win)))
      (pop-to-buffer new-buf))
     (t
      (set-window-buffer win new-buf)
      (set-buffer new-buf)))
    new-buf))

(defun wmvc:rebuild-buffer (context)
  (let* ((buf-name (buffer-name))
         (pos (point))
         (buffer (wmvc:get-new-buffer buf-name)))
    (wmvc:tmpl-build-buffer buffer context)
    buffer))

(defun* wmvc:build-buffer(&key buffer tmpl model actions validations attributes lang)
  (let ((context
         (make-wmvc:context 
          :template tmpl :model model 
          :action-map actions :validations validations
          :attributes attributes :lang (or lang (intern current-language-environment)))))
    (unless buffer
      (setq buffer (wmvc:get-new-buffer)))
    (wmvc:tmpl-build-buffer buffer context)
    buffer))

(defun wmvc:widget-focus-to (name)
  (let* ((ctx wmvc:context)
         (widget-map (wmvc:context-widget-map ctx))
         (widget (cdr (assq name widget-map)))
         (pos (and widget (widget-get widget ':from))))
    (when pos
      (goto-char pos))))


;;==================================================
;;; debug

(defun wmvc:demo-template ()
  (interactive)
  (let ((src `(
               ,(propertize "Form Sample" 'face 'info-title-1) BR
               "This is a sample template.\nA normal text is inserted as is." BR
               "BR inserts a line break." BR BR
               (message :name error :face compilation-error) BR
               "  Input A  : "
               (input :name input-a :type text :size 30) BR
               "  Input B  : "
               (input :name input-b :type text :size 30) "(decimal 0 - 12)" BR
               "  Password : "
               (input :name password :type password :size 20) BR
               "  Option   : "
               "Alpha" (input :name check-a :type checkbox) " "
               "Beta"  (input :name check-b :type checkbox) " "
               "Gamma" (input :name check-c :type checkbox) BR
               "  Radio Select : " 
               (input :name radio-a :type radio
                      :options (("select1" . 1) ("select2" . 2) ("select3" . 3) ("select4" . 4)))
               BR
               "  Select1  : "
               (input :name select1 :type select 
                      :options ("select1" "select2" "select3" "select4"))
               BR
               "  Select2  : "
               (input :name select2 :type select :multiple t
                      :options (("select1" . 1) ("select2" . 2) ("select3" . 3) ("select4" . 4)))
               BR
               "  Date : "
               (input :name mdate :type date)
               BR
               "  Link : "
               (input :name linker :type link :url "http://www.gnu.org")
               BR
               "  Const : "
               (input :name hidden-data :type const)
               BR BR
               "    " (button :title "OK" :action on-submit :validation t)
               "  " (button :title "Cancel" :action on-cancel)))
        (model 
         '((input-a . "")  (input-b . "6")
           (password . "") (check-a . t) (check-b . nil) (check-c . nil)
           (radio-a . 4) (select1 . "select2") (select2 . (3))
           (mdate ) (hidden-data . 512)
           ))
        (validations
         '((input-a . wmvc:validation-integer)
           (input-b . (wmvc:validation-decimal :min 0 :max 12))
           (password . (wmvc:validation-length :min 5 :max 10))
           ))
        (action-mapping 
         '((on-submit . wmvc:demo-submit-action)
           (on-cancel . (lambda (model) 
                          (message "canceled")
                          (kill-this-buffer)))))
        (attributes '()))
    (pop-to-buffer
     (wmvc:build-buffer 
      :buffer (wmvc:get-new-buffer)
      :tmpl src :model model :actions action-mapping
      :validations validations :attributes attributes))))

(defun wmvc:demo-submit-action (model)
  (message "MODEL : %S" model)
  (kill-this-buffer))

;; (progn (eval-current-buffer) (wmvc:demo-template))

(provide 'widget-mvc)
;;; widget-mvc.el ends here
