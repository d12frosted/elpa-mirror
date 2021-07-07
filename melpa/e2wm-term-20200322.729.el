;;; e2wm-term.el --- Perspective of e2wm.el for work in terminal

;; Copyright (C) 2014  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: tools, window manager
;; Package-Version: 20200322.729
;; Package-Commit: 74362d6271e736272df32ea807c5a22e4df54a50
;; URL: https://github.com/aki2o/e2wm-term
;; Version: 0.0.6
;; Package-Requires: ((e2wm "1.2") (log4e "0.2.0") (yaxception "0.3.2"))

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
;; This extension provides the frontend for work in terminal, which has the following features.
;; 
;; - invoke command by not a newline key but a dedicated key for avoiding an unintended invocation.
;; - command can be written as multiline because a newline key just inputs a linefeed.
;; - show a help of the command, which you are typing to invoke, automatically into a dedicated window.
;; - show any help command result into not a terminal window but a dedicated window.
;; - show comand histories into a dedicated window and access them quickly.
;; 
;; For more infomation, see <https://github.com/aki2o/e2wm-term/blob/master/README.md>

;;; Dependency:
;; 
;; - e2wm.el ( see <https://github.com/kiwanami/emacs-window-manager> )
;; - yaxception.el ( see <https://github.com/aki2o/yaxception> )
;; - log4e.el ( see <https://github.com/aki2o/log4e> )

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your .emacs or site-start.el file.
;; 
;; (require 'e2wm-term)

;;; Configuration:
;; 
;; ;; Set default terminal
;; (setq e2wm-term:default-backend 'shell)
;; 
;; ;; Make config suit for you. About the config item, see Customization or eval the following sexp.
;; ;; (customize-group "e2wm-term")
;; 

;;; Customization:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "e2wm-term:[^:]" :docstring t)
;; `e2wm-term:default-backend'
;; Symbol for backend used in default.
;; `e2wm-term:use-migemo'
;; Whether to use migemo.el.
;; `e2wm-term:command-helper'
;; String as command for help of command.
;; `e2wm-term:command-pager'
;; String as command for pager.
;; `e2wm-term:command-pager-variables'
;; List of string as environment variable for pager.
;; `e2wm-term:command-cwd-checker'
;; String as command for check of current work directory.
;; `e2wm-term:command-cwd-updaters'
;; List of string as command changes current work directory.
;; `e2wm-term:command-special-chars'
;; List of character has a special role in terminal.
;; `e2wm-term:input-window-height'
;; Number as the height of a input window.
;; `e2wm-term:history-max-length'
;; Number as the number of shown command history in history buffer.
;; `e2wm-term:help-window-default-hide'
;; Whether to hide help window at first.
;; `e2wm-term:help-guess-command'
;; Method to handle the inputed command seems to show help, e.g. "git help status".
;; `e2wm-term:help-guess-regexp'
;; Regexp to find the command handled by `e2wm-term:help-guess-command'.
;; `e2wm-term:shell-use-history'
;; Whether to load the entry of user history file into history buffer.
;; `e2wm-term:shell-password-prompt-regexps'
;; List of regexp to catch up on the fault of `comint-password-prompt-regexp'.
;; 
;;  *** END auto-documentation

;;; API:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'function :prefix "e2wm-term:[^:]" :docstring t)
;; `e2wm-term:regist-backend'
;; Regist BACKEND.
;; `e2wm-term:get-backend'
;; Return backend of NAME.
;; `e2wm-term:current-backend'
;; Return current active backend.
;; `e2wm-term:recipe'
;; Not documented.
;; `e2wm-term:winfo'
;; Not documented.
;; `e2wm-term:dp-init'
;; Not documented.
;; `e2wm-term:dp-leave'
;; Not documented.
;; `e2wm-term:dp-switch'
;; Not documented.
;; `e2wm-term:dp-popup'
;; Not documented.
;; `e2wm-term:dp-display'
;; Not documented.
;; `e2wm-term:def-plugin-input'
;; Not documented.
;; `e2wm-term:input-cwd-update'
;; Update current work directory of input buffer by communicating main buffer process.
;; `e2wm-term:input-header-update'
;; Update `header-line-format' of input buffer using PATH.
;; `e2wm-term:input-value-update'
;; Update the contents of input buffer to VALUE.
;; `e2wm-term:input-current-value'
;; Return the contents of input buffer.
;; `e2wm-term:input-send-value'
;; Input VALUE into main buffer and return marker of the point before input VALUE.
;; `e2wm-term:def-plugin-history'
;; Not documented.
;; `e2wm-term:history-highlight'
;; Highlight entry of history buffer.
;; `e2wm-term:history-sync'
;; Move cursor of main buffer to the pointed entry of history buffer.
;; `e2wm-term:history-add-on-current'
;; Add entry on current buffer.
;; `e2wm-term:history-add'
;; Add entry into history buffer.
;; `e2wm-term:def-plugin-help'
;; Not documented.
;; `e2wm-term:help-command'
;; Put the result of `e2wm-term:command-helper' about CMD into help buffer.
;; `e2wm-term:help-something'
;; Put the result of CMDSTR into help buffer.
;; `e2wm-term:shell-watch-for-password-prompt'
;; Do `comint-watch-for-password-prompt' with replacement of `comint-password-prompt-regexp'.
;; 
;;  *** END auto-documentation
;; [EVAL] (autodoc-document-lisp-buffer :type 'command :prefix "e2wm-term:[^:]" :docstring t)
;; `e2wm-term:show-backends'
;; Show available backends.
;; `e2wm-term:describe-backend'
;; Show configuration of backend of NAME.
;; `e2wm-term:dp-help-toggle-command'
;; Not documented.
;; `e2wm-term:dp-help-maximize-toggle-command'
;; Not documented.
;; `e2wm-term:dp-select-main-buffer'
;; Not documented.
;; `e2wm-term:dp'
;; Start perspective for work in terminal.
;; `e2wm-term:input-invoke-command'
;; Invoke the contents of input buffer.
;; `e2wm-term:input-insert-with-help'
;; Do `self-insert-command' and run `e2wm-term:help-command' about it if any command was inputed.
;; `e2wm-term:input-insert-with-ac'
;; Do `self-insert-command' and `auto-complete'.
;; `e2wm-term:input-completion'
;; Do completion of `e2wm-term:current-backend'.
;; `e2wm-term:input-history-previous'
;; Update the contents of input buffer to previous entry of history buffer.
;; `e2wm-term:input-history-next'
;; Update the contents of input buffer to next entry of history buffer.
;; `e2wm-term:history-move-next'
;; Move cursor to next entry in history buffer.
;; `e2wm-term:history-move-previous'
;; Move cursor to previous entry in history buffer.
;; `e2wm-term:history-send-pt-point'
;; Do `e2wm-term:input-value-update' from the pointed entry string of history buffer.
;; `e2wm-term:history-show-all'
;; Show all entry of history buffer.
;; `e2wm-term:history-grep-abort'
;; Exit from minibuffer of grepping entry of history buffer.
;; `e2wm-term:history-grep'
;; Grep entry of history buffer.
;; `e2wm-term:help-quit'
;; Normalize help window size and select input window.
;; 
;;  *** END auto-documentation
;; [Note] Functions and variables other than listed above, Those specifications may be changed without notice.

;;; Tested On:
;; 
;; - Emacs ... GNU Emacs 24.3.1 (i686-pc-linux-gnu, GTK+ Version 3.4.2) of 2013-08-22 on chindi02, modified by Debian
;; - e2wm.el ... Version 1.2
;; - yaxception.el ... Version 0.3.2
;; - log4e.el ... Version 0.2.0


;; Enjoy!!!


(eval-when-compile (require 'cl))
(require 'e2wm)
(require 'yaxception)
(require 'log4e)
(require 'comint)
(require 'term)
(require 'view)
(require 'auto-complete nil t)
(require 'migemo nil t)


(defgroup e2wm-term nil
  "Perspective of e2wm.el for work in terminal."
  :group 'windows
  :prefix "e2wm-term:")

(defcustom e2wm-term:default-backend 'shell
  "Symbol for backend used in default.

For check available backends, use `e2wm-term:show-backends'/`e2wm-term:describe-backend'."
  :type 'symbol
  :group 'e2wm-term)

(defcustom e2wm-term:use-migemo t
  "Whether to use migemo.el."
  :type 'boolean
  :group 'e2wm-term)

(defcustom e2wm-term:command-helper "man"
  "String as command for help of command."
  :type 'string
  :group 'e2wm-term)

(defcustom e2wm-term:command-pager "cat"
  "String as command for pager."
  :type 'string
  :group 'e2wm-term)

(defcustom e2wm-term:command-pager-variables '("PAGER" "GIT_PAGER")
  "List of string as environment variable for pager."
  :type '(repeat string)
  :group 'e2wm-term)

(defcustom e2wm-term:command-cwd-checker "pwd"
  "String as command for check of current work directory."
  :type 'string
  :group 'e2wm-term)

(defcustom e2wm-term:command-cwd-updaters '("cd")
  "List of string as command changes current work directory."
  :type '(repeat string)
  :group 'e2wm-term)

(defcustom e2wm-term:command-special-chars '(">" "|" "&")
  "List of character has a special role in terminal."
  :type '(repeat string)
  :group 'e2wm-term)

(defcustom e2wm-term:input-window-height 10
  "Number as the height of a input window."
  :type 'integer
  :group 'e2wm-term)

(defcustom e2wm-term:history-max-length 1000
  "Number as the number of shown command history in history buffer."
  :type 'integer
  :group 'e2wm-term)

(defcustom e2wm-term:help-window-default-hide nil
  "Whether to hide help window at first."
  :type 'boolean
  :group 'e2wm-term)

(defcustom e2wm-term:help-guess-command 'ask
  "Method to handle the inputed command seems to show help, e.g. \"git help status\".

This value is one of the following symbols.
 - t   ... always show the command result in help buffer.
 - ask ... ask whether to show the command result in help buffer.
 - nil ... always invoke the command in main buffer."
  :type '(choice (const t)
                 (const ask)
                 (const nil))
  :group 'e2wm-term)

(defcustom e2wm-term:help-guess-regexp " help\\(\\'\\|[ \n]\\)"
  "Regexp to find the command handled by `e2wm-term:help-guess-command'."
  :type 'regexp
  :group 'e2wm-term)

(defcustom e2wm-term:shell-use-history t
  "Whether to load the entry of user history file into history buffer."
  :type 'boolean
  :group 'e2wm-term)

(defcustom e2wm-term:shell-password-prompt-regexps
  '("^Password +for +'[^'\t\n]+': +")
  "List of regexp to catch up on the fault of `comint-password-prompt-regexp'."
  :type '(repeat regexp)
  :group 'e2wm-term)


(log4e:deflogger "e2wm-term" "%t [%l] %m" "%H:%M:%S" '((fatal . "fatal")
                                                       (error . "error")
                                                       (warn  . "warn")
                                                       (info  . "info")
                                                       (debug . "debug")
                                                       (trace . "trace")))
(e2wm-term--log-set-level 'trace)


;;;;;;;;;;;;;
;; Utility

(defmacro e2wm-term::awhen (test &rest body)
  (declare (indent 1))
  `(let ((it ,test)) (when it ,@body)))

(defmacro e2wm-term::aif (test then &rest else)
  (declare (indent 2))
  `(let ((it ,test)) (if it ,then ,@else)))

(defmacro e2wm-term::awhen-buffer-live (buffnm &rest body)
  (declare (indent 1))
  `(let ((it (when ,buffnm (get-buffer ,buffnm))))
     (when (buffer-live-p it) ,@body)))

(defun* e2wm-term::show-message (msg &rest args)
  (apply 'message (concat "[E2WM-TERM] " msg) args)
  nil)

(defsubst e2wm-term::set-visibility (startpt endpt invisible)
  (when (and (> startpt 0)
             (> endpt 0)
             (> endpt startpt))
    (e2wm-term--trace "%s %s region ( %s - %s )"
                      (buffer-name) (if invisible "hide" "show") startpt endpt)
    (put-text-property startpt endpt 'invisible invisible)
    t))


;;;;;;;;;;;;;
;; Backend

(defstruct e2wm-term:$backend name mode map starter invoker completion input-hook history-hook)

(defvar e2wm-term::backend-hash (make-hash-table))
(defvar e2wm-term::current-backend-name nil)

(defvar e2wm-term::last-buffer nil)
(defun e2wm-term::get-backend-buffers ()
  (loop with mode = (e2wm-term:$backend-mode (e2wm-term:current-backend))
        for b in (buffer-list)
        if (eq (buffer-local-value 'major-mode b) mode)
        collect b))

(defun e2wm-term::get-backend-buffer ()
  (e2wm-term::awhen (e2wm-term::get-backend-buffers)
    (setq e2wm-term::last-buffer (nth 0 it))))

(defun e2wm-term::ready-backend-buffer-p ()
  (yaxception:$
    (yaxception:try
      (let ((mode (e2wm-term:$backend-mode (e2wm-term:current-backend)))
            (wnd (wlf:get-window (e2wm:pst-get-wm) 'main))
            (buf (wlf:get-buffer (e2wm:pst-get-wm) 'main)))
        (and (window-live-p wnd) 
             (buffer-live-p buf)
             (eq (buffer-local-value 'major-mode buf) mode))))
    (yaxception:catch 'error e
      (e2wm-term--info "Not ready backend buffer : %s" (yaxception:get-text e)))))

(yaxception:deferror 'e2wm-term:err-invalid-backend-property
                     nil
                     "[E2WM-TERM] Failed regist backend for %s : invalid property"
                     'name)

(defun e2wm-term:regist-backend (backend)
  "Regist BACKEND.

BACKEND is a struct of `e2wm-term:$backend' has the following properties.
 - name         ... required. symbol to identify BACKEND.
 - mode         ... required. symbol as mode of BACKEND.
 - map          ... required. symbol as keymap of BACKEND.
 - starter      ... required. symbol as function to start BACKEND.
 - invoker      ... required. symbol as command to invoke any command in BACKEND buffer.
 - completion   ... optional. symbol as function to complete a input buffer.
 - input-hook   ... optional. symbol as function to run after the input buffer for BACKEND is generated.
 - history-hook ... optional. symbol as function to run after the history buffer for BACKEND is generated."
  (when (e2wm-term:$backend-p backend)
    (if (or (not (e2wm-term:$backend-name backend))
            (not (e2wm-term:$backend-mode backend))
            (not (keymapp (symbol-value (e2wm-term:$backend-map backend))))
            (not (functionp (e2wm-term:$backend-starter backend)))
            (not (functionp (e2wm-term:$backend-invoker backend))))
        (yaxception:throw 'e2wm-term:err-invalid-backend-property
                          :name (e2wm-term:$backend-name backend))
      (puthash (e2wm-term:$backend-name backend) backend e2wm-term::backend-hash))))

(defun e2wm-term:show-backends ()
  "Show available backends."
  (interactive)
  (e2wm-term::show-message
   "Available backend : %s"
   (mapconcat 'symbol-name (loop for k being hash-key in e2wm-term::backend-hash collect k) ", ")))

(defun e2wm-term:describe-backend (name)
  "Show configuration of backend of NAME."
  (interactive
   (list (completing-read
          "Select backend: " (loop for k being hash-key in e2wm-term::backend-hash collect k) nil t nil '())))
  (let* ((b (e2wm-term:get-backend name))
         (props '("mode" "map" "starter" "invoker" "completion" "input-hook" "history-hook"))
         (prompt (concat "%s backend configuration ...\n"
                         (mapconcat 'identity (loop for p in props collect (format "  %s: %%s" p)) "\n"))))
    (if (not (e2wm-term:$backend-p b))
        (e2wm-term::show-message "Invalid backend name : %s" name)
      (e2wm-term::show-message prompt
                               name
                               (e2wm-term:$backend-mode b)
                               (e2wm-term:$backend-map b)
                               (e2wm-term:$backend-starter b)
                               (e2wm-term:$backend-invoker b)
                               (e2wm-term:$backend-completion b)
                               (e2wm-term:$backend-input-hook b)
                               (e2wm-term:$backend-history-hook b)))))

(defun e2wm-term:get-backend (name)
  "Return backend of NAME."
  (gethash (if (stringp name) (intern name) name) e2wm-term::backend-hash))

(yaxception:deferror 'e2wm-term:err-invalid-backend
                     nil
                     "[E2WM-TERM] Current backend is invalid")

(defun e2wm-term:current-backend ()
  "Return current active backend."
  (e2wm-term::aif (e2wm-term:get-backend
                   (e2wm-term::aif e2wm-term::current-backend-name
                       it
                     e2wm-term:default-backend))
      it
    (yaxception:throw 'e2wm-term:err-invalid-backend)))


;;;;;;;;;;;;;;;;;;;;
;; Emulate Keymap

(defsubst e2wm-term::keymap-def-proxy (cmdnm orgmode orgcmd)
  (e2wm-term--trace "start def proxy. cmdnm[%s] orgcmd[%s]" cmdnm orgcmd)
  (eval `(defun ,(intern cmdnm) ()
           (interactive)
           (e2wm-term--trace "do proxy of %s" (symbol-name ',orgcmd))
           (when (e2wm-term::ready-backend-buffer-p)
             (with-selected-window (wlf:get-window (e2wm:pst-get-wm) 'main)
               (when (eq major-mode ',orgmode)
                 (call-interactively ',orgcmd)))))))

(defsubst e2wm-term::keymap-get-sequence-key-strokes (basestr startch endch)
  (e2wm-term--trace "start get sequence key strokes. basestr[%s] startch[%s] endch[%s]"
                     basestr startch endch)
  (loop for ch from (string-to-char startch) to (string-to-char endch)
        collect (concat basestr (make-string 1 ch))))

(defvar e2wm-term::keymap-regexp-sequence-key-stroke
  (rx-to-string `(and (group (not (any space)))
                      " .. "
                      (group (* not-newline))
                      (group (not (any space)))
                      eos)))

(defun e2wm-term::keymap-emulate-info (mapsym mode &optional not-proxy)
  (with-temp-buffer
    (let ((indent-tabs-mode t)
          (map (symbol-value mapsym))
          (invoker (e2wm-term:$backend-invoker (e2wm-term:current-backend))))
      (insert (substitute-command-keys "\\<map>\\{map}"))
      (goto-char (point-min))
      (forward-line 3)
      (loop while (not (eobp))
            for e = (split-string (buffer-substring (point-at-bol) (point-at-eol)) "\t+")
            for keystr = (replace-regexp-in-string
                          "\\\"" "\\\\\"" (replace-regexp-in-string "\\\\" "\\\\\\\\" (pop e)))
            for orgcmd = (when e (intern-soft (pop e)))
            for cmdnm = (when (and orgcmd
                                   (commandp orgcmd)
                                   (not (eq orgcmd invoker)))
                          (if not-proxy
                              (symbol-name orgcmd)
                            (concat "e2wm-term:proxy-" (symbol-name orgcmd))))
            for cmd = (when cmdnm
                        (or (e2wm-term::awhen (intern-soft cmdnm)
                              (when (commandp it) it))
                            (e2wm-term::keymap-def-proxy cmdnm mode orgcmd)))
            ;; Keystroke is sequencial such as "1 .. 9"
            if (and cmd (string-match e2wm-term::keymap-regexp-sequence-key-stroke keystr))
            append (loop for keystr in (e2wm-term::keymap-get-sequence-key-strokes
                                        (match-string-no-properties 2 keystr)
                                        (match-string-no-properties 1 keystr)
                                        (match-string-no-properties 3 keystr))
                         collect `(,keystr ,cmd))
            ;; Keystroke is normal
            else if (and keystr cmd)
            collect `(,keystr ,cmd)
            do (forward-line)))))

(defun* e2wm-term::keymap-emulate (&key override-map
                                        emulate-map-sym
                                        emulate-map-mode
                                        as-proxy)
  (e2wm-term--trace "start emulate keymap. override[%s] emulate-map-sym[%s] emulate-map-mode[%s] as-proxy[%s]"
                    (if override-map t nil) emulate-map-sym emulate-map-mode as-proxy)
  (let ((map (or override-map (make-sparse-keymap))))
    (loop for (keystr cmd) in (e2wm-term::keymap-emulate-info
                               emulate-map-sym emulate-map-mode (not as-proxy))
          do (yaxception:$
               (yaxception:try
                 (e2wm-term--trace "define key. stroke[%s] cmd[%s]" keystr cmd)
                 (define-key map (read-kbd-macro keystr) cmd))
               (yaxception:catch 'error e
                 (e2wm-term--warn "failed define key. stroke[%s] cmd[%s] : %s"
                                  keystr cmd (yaxception:get-text e)))))
    map))


;;;;;;;;;;;;;;;;;
;; Perspective

(defun e2wm-term:recipe ()
  `(| (:left-size-ratio 0.5)
      (- (:lower-max-size ,e2wm-term:input-window-height)
         main input)
      (- (:upper-size-ratio 0.6)
         history
         (- (:upper-size-ratio 0.1)
            help sub))))

(defun e2wm-term:winfo ()
  `((:name main)
    (:name input   :plugin term-input)
    (:name history :plugin term-history)
    (:name help    :plugin term-help :default-hide ,e2wm-term:help-window-default-hide)
    (:name sub     :buffer nil :default-hide t)))

(e2wm:pst-class-register
 (make-e2wm:$pst-class :name    'term
                       :extend  'base
                       :title   "Term"
                       :main    'input
                       :init    'e2wm-term:dp-init
                       :leave   'e2wm-term:dp-leave
                       :switch  'e2wm-term:dp-switch
                       :popup   'e2wm-term:dp-popup
                       :display 'e2wm-term:dp-display
                       :keymap  'e2wm-term:dp-minor-mode-map))

(defvar e2wm-term::dp-next-main-buffer-p nil)
(defun e2wm-term::dp-handle-buffer (buf)
  (let* ((backends (loop for v being hash-value in e2wm-term::backend-hash collect v))
         (modes (loop for b in backends collect (e2wm-term:$backend-mode b)))
         (starters (loop for b in backends collect (e2wm-term:$backend-starter b)))
         (bmode (buffer-local-value 'major-mode buf)))
    (cond ((or e2wm-term::dp-next-main-buffer-p
               (memq bmode modes)
               (memq this-command starters))
           (setq e2wm-term::dp-next-main-buffer-p nil)
           (e2wm:with-advice
            (e2wm:pst-buffer-set 'main buf t nil))
           (e2wm-term::awhen (loop for b in backends
                                   if (or (eq this-command (e2wm-term:$backend-starter b))
                                          (eq bmode (e2wm-term:$backend-mode b)))
                                   return (e2wm-term:$backend-name b))
             (setq e2wm-term::current-backend-name it)
             (e2wm:pst-update-windows))
           t)
          (t
           (e2wm:with-advice
            (e2wm:pst-buffer-set 'sub buf t t))
           t))))

(defun e2wm-term::dp-ensure-main-buffer ()
  (e2wm:message "#DP TERM ensure main buffer")
  (when (not (e2wm-term::get-backend-buffer))
    (let ((e2wm-term::dp-next-main-buffer-p t))
      (funcall (e2wm-term:$backend-starter (e2wm-term:current-backend))))
    (e2wm:pst-window-select-main)))

(defvar e2wm-term:dp-original-pager-hash nil)
(defun e2wm-term::dp-pager-setup ()
  (setq e2wm-term:dp-original-pager-hash (make-hash-table :test 'equal))
  (dolist (v e2wm-term:command-pager-variables)
    (puthash v (getenv v) e2wm-term:dp-original-pager-hash)
    (setenv v e2wm-term:command-pager)))

(defun e2wm-term::dp-pager-restore ()
  (loop for k being hash-key in e2wm-term:dp-original-pager-hash
        for v = (gethash k e2wm-term:dp-original-pager-hash)
        do (setenv k v)))

(defun e2wm-term:dp-init ()
  (when (not e2wm-term::current-backend-name)
    (setq e2wm-term::current-backend-name e2wm-term:default-backend))
  (let* ((term-wm (wlf:no-layout (e2wm-term:recipe) (e2wm-term:winfo)))
         (buf (or (e2wm-term::awhen-buffer-live e2wm-term::last-buffer
                    it)
                  (e2wm-term::get-backend-buffer))))
    (if buf
        (wlf:set-buffer term-wm 'main buf)
      (run-with-idle-timer 0.1 nil 'e2wm-term::dp-ensure-main-buffer))
    (e2wm-term::dp-pager-setup)
    term-wm))

(defun e2wm-term:dp-leave (wm)
  (setq e2wm:prev-selected-buffer nil)
  (setq e2wm-term::last-buffer nil)
  (e2wm-term::dp-pager-restore))

(defun e2wm-term:dp-switch (buf)
  (e2wm:message "#DP TERM switch : %s" buf)
  (e2wm-term::dp-handle-buffer buf))

(defun e2wm-term:dp-popup (buf)
  (e2wm:message "#DP TERM popup : %s" buf)
  (e2wm-term::dp-handle-buffer buf))

(defun e2wm-term:dp-display (buf)
  (e2wm:message "#DP TERM display : %s" buf)
  (e2wm-term::dp-handle-buffer buf))

(defun e2wm-term:dp-help-toggle-command ()
  (interactive)
  (wlf:toggle (e2wm:pst-get-wm) 'help)
  (e2wm:pst-update-windows))

(defun e2wm-term:dp-help-maximize-toggle-command ()
  (interactive)
  ;; (wlf:toggle-maximize (e2wm:pst-get-wm) 'help)
  (wlf:toggle (e2wm:pst-get-wm) 'history)
  (e2wm:pst-update-windows))

(defun e2wm-term:dp-select-main-buffer ()
  (interactive)
  (let ((e2wm:dp-array-buffers-function 'e2wm-term::get-backend-buffers))
    (e2wm:dp-array)))

(defvar e2wm-term:dp-minor-mode-map
  (e2wm:define-keymap
   '(("prefix n" . e2wm-term:history-move-next)
     ("prefix p" . e2wm-term:history-move-previous)
     ("prefix i" . e2wm-term:history-send-pt-point)
     ("prefix g" . e2wm-term:history-grep)
     ("prefix a" . e2wm-term:history-show-all)
     ("prefix h" . e2wm-term:dp-help-toggle-command)
     ("prefix H" . e2wm-term:dp-help-maximize-toggle-command)
     ("prefix t" . e2wm-term:dp-select-main-buffer))
   e2wm:prefix-key))

;;;###autoload
(defun e2wm-term:dp ()
  "Start perspective for work in terminal."
  (interactive)
  (e2wm:pst-change 'term))


;;;;;;;;;;;;;;;;;;
;; Input Plugin

(e2wm:plugin-register 'term-input
                      "Term Input"
                      'e2wm-term:def-plugin-input)

(defvar e2wm-term::input-cwd "")
(defvar ac-source-e2wm-term-input-path
  '((candidates . e2wm-term::input-path-candidates)
    (prefix . "/\\([^/'\"\n]*\\)")
    (requires . 0)))

(defun e2wm-term:def-plugin-input (frame wm winfo)
  (wlf:set-buffer wm (wlf:window-name winfo)
                  (or (get-buffer (e2wm-term::input-buffer-name))
                      (let ((backend (e2wm-term:current-backend)))
                        (with-current-buffer (generate-new-buffer (e2wm-term::input-buffer-name))
                          (e2wm-term:input-mode)
                          (use-local-map
                           (e2wm-term::keymap-emulate
                            :emulate-map-sym 'e2wm-term:input-mode-map
                            :emulate-map-mode 'e2wm-term:input-mode
                            :override-map (e2wm-term::keymap-emulate
                                           :emulate-map-sym (e2wm-term:$backend-map backend)
                                           :emulate-map-mode (e2wm-term:$backend-mode backend)
                                           :as-proxy t)))
                          (when (featurep 'auto-complete)
                            (setq ac-sources '(ac-source-e2wm-term-input-path))
                            (auto-complete-mode t))
                          (e2wm-term::awhen (e2wm-term:$backend-input-hook backend)
                            (funcall it))
                          (buffer-enable-undo)
                          (current-buffer)))))
  (setq e2wm-term::input-cwd "")
  (run-with-idle-timer 1 nil 'e2wm-term:input-cwd-update))

(defun e2wm-term::input-buffer-name ()
  (format " *E2WM-TERM Input for %s*" (e2wm-term:$backend-name (e2wm-term:current-backend))))

(defun e2wm-term::input-cwd-filter (proc res)
  (e2wm:message "#Term-Input cwd filter for %s : %s" (process-name proc) res)
  (loop for cwd in (split-string res "\n")
        if (and (not (string= cwd ""))
                (file-directory-p cwd))
        return (e2wm-term:input-header-update (setq e2wm-term::input-cwd cwd))))

(defun e2wm-term::input-path-candidates ()
  (e2wm:message "#Term-Input path candidates")
  (save-excursion
    (when (re-search-backward "/[^/'\"\n]+\\=" nil t)
      (forward-char 1))
    (let* ((currpt (point))
           (dirpath (loop for re in '("\"" "'" "[^\\\\] +")
                          for path = (save-excursion
                                       (when (re-search-backward re nil t)
                                         (goto-char (match-end 0))
                                         (when (< (point) currpt)
                                           (buffer-substring-no-properties (point) currpt))))
                          for path = (when path (replace-regexp-in-string "\\\\ " " " path))
                          for path = (when path (expand-file-name path))
                          for path = (when path
                                       (if (string-match "\\`/" path)
                                           path
                                         (concat (directory-file-name e2wm-term::input-cwd) "/" path)))
                          if (and path (file-directory-p path))
                          return (progn
                                   (e2wm:message "  #Term-Input path candidates found : %s" path)
                                   path))))
      (when dirpath
        (loop for e in (directory-files dirpath)
              for fullpath = (concat dirpath e)
              if (or (file-regular-p fullpath)
                     (file-symlink-p fullpath)
                     (and (file-directory-p fullpath)
                          (not (string= e "."))))
              collect (replace-regexp-in-string "[\"']" "" (shell-quote-argument e)))))))

(defun e2wm-term:input-cwd-update ()
  "Update current work directory of input buffer by communicating main buffer process."
  (e2wm:message "#Term-Input cwd update")
  (when (e2wm-term::ready-backend-buffer-p)
    (let* ((proc (get-buffer-process (wlf:get-buffer (e2wm:pst-get-wm) 'main)))
           (orgbuf (when (processp proc) (process-buffer proc)))
           (orgfilter (when (processp proc) (process-filter proc))))
    (when (processp proc)
      (yaxception:$
        (yaxception:try
          (set-process-buffer proc nil)
          (set-process-filter proc 'e2wm-term::input-cwd-filter)
          (process-send-string proc (concat e2wm-term:command-cwd-checker "\n"))
          (accept-process-output proc 0.2 nil t))
        (yaxception:finally
          (set-process-buffer proc orgbuf)
          (set-process-filter proc orgfilter)))))))

(defun e2wm-term:input-header-update (path)
  "Update `header-line-format' of input buffer using PATH."
  (e2wm:message "#Term-Input header update : %s" path)
  (with-selected-window (wlf:get-window (e2wm:pst-get-wm) 'input)
    (when (file-directory-p path)
      (setq default-directory path))
    (setq header-line-format (format "CWD: %s" path))))

(defun e2wm-term:input-value-update (value &optional clear-undo)
  "Update the contents of input buffer to VALUE."
  (e2wm:message "#Term-Input value update : %s" value)
  (with-selected-window (wlf:get-window (e2wm:pst-get-wm) 'input)
    (erase-buffer)
    (when (and (stringp value)
               (not (string= value "")))
      (insert value))
    (when clear-undo (setq buffer-undo-list nil))))

(defun e2wm-term:input-current-value ()
  "Return the contents of input buffer."
  (let* ((ret (with-current-buffer (wlf:get-buffer (e2wm:pst-get-wm) 'input)
                (buffer-string)))
         (ret (replace-regexp-in-string "\\`\\s-+" "" ret))
         (ret (replace-regexp-in-string "\\s-+\\'" "" ret)))
    ret))

(defun* e2wm-term:input-send-value (&key value invoke)
  "Input VALUE into main buffer and return marker of the point before input VALUE.

If INVOKE is non-nil, run invoker of `e2wm-term:current-backend' after input VALUE."
  (let* ((value (or value (e2wm-term:input-current-value)))
         (value (replace-regexp-in-string " *[\t\n]+ *" " " value)))
    (with-current-buffer (wlf:get-buffer (e2wm:pst-get-wm) 'main)
      (e2wm:message "#Term-Input send value %s : %s" (if invoke "with invoke" "") value)
      (goto-char (point-max))
      (let ((marker (set-marker (make-marker) (point))))
        (insert value)
        (when invoke
          (with-selected-window (wlf:get-window (e2wm:pst-get-wm) 'main)
            (goto-char (point-max))
            (call-interactively (e2wm-term:$backend-invoker (e2wm-term:current-backend)))))
        marker))))

(defun e2wm-term:input-invoke-command ()
  "Invoke the contents of input buffer.

If the contents seems to show help, do `e2wm-term:help-something'.
Else, do `e2wm-term:input-send-value' for `e2wm-term:input-current-value'."
  (interactive)
  (if (not (e2wm-term::ready-backend-buffer-p))
      (e2wm-term::show-message "%s buffer is not ready."
                               (e2wm-term:$backend-name (e2wm-term:current-backend)))
    (let* ((rawstr (e2wm-term:input-current-value))
           (re (rx-to-string `(and (or ,@e2wm-term:command-special-chars))))
           (include-special (string-match re rawstr))
           (cmdnm (if (string-match "\\`[^ \t\n]+" rawstr)
                      (match-string-no-properties 0 rawstr)
                    "")))
      (e2wm:message "#Term-Input invoke start : %s" rawstr)
      (cond ((string= cmdnm e2wm-term:command-helper)
             ;; help command
             (e2wm-term:help-something rawstr :maximize t :selectp t))
            ((and (not include-special)
                  (string-match " --help\\(\\'\\|[ \n]\\)" rawstr))
             ;; include help option
             (e2wm-term:help-something rawstr :maximize t :selectp t))
            ((and (not include-special)
                  (string-match e2wm-term:help-guess-regexp rawstr)
                  (or (eq e2wm-term:help-guess-command t)
                      (and (eq e2wm-term:help-guess-command 'ask)
                           (y-or-n-p "Show this command result in help buffer?"))))
             ;; maybe something help command
             (e2wm-term:help-something rawstr :maximize t :selectp t))
            (t
             (let ((marker (e2wm-term:input-send-value :value rawstr :invoke t)))
               (e2wm:message "  #Term-Input invoke after : cmdnm:'%s'" cmdnm)
               (run-with-idle-timer 0.2 nil 'e2wm-term:history-add rawstr marker)
               (when (member cmdnm e2wm-term:command-cwd-updaters)
                 (run-with-idle-timer 0.2 nil 'e2wm-term:input-cwd-update)))))
      (e2wm-term:input-value-update nil t))))

(defun e2wm-term:input-insert-with-help (n)
  "Do `self-insert-command' and run `e2wm-term:help-command' about it if any command was inputed."
  (interactive "p")
  (self-insert-command n)
  (let ((inputed (buffer-string)))
    (when (string-match "\\(?:\\`\\||\\) *\\([^ \t\n]+\\) \\'" inputed)
      (e2wm-term:help-command (match-string-no-properties 1 inputed) :delay 1))))

(defun e2wm-term:input-insert-with-ac (n)
  "Do `self-insert-command' and `auto-complete'."
  (interactive "p")
  (self-insert-command n)
  (when (featurep 'auto-complete)
    (auto-complete-1 :triggered 'trigger-key)))

(defun e2wm-term:input-completion ()
  "Do completion of `e2wm-term:current-backend'."
  (interactive)
  (e2wm-term::awhen (e2wm-term:$backend-completion (e2wm-term:current-backend))
    (funcall it)))

(defun e2wm-term:input-history-previous ()
  "Update the contents of input buffer to previous entry of history buffer."
  (interactive)
  (e2wm-term:history-move-previous)
  (e2wm-term:history-send-pt-point))

(defun e2wm-term:input-history-next ()
  "Update the contents of input buffer to next entry of history buffer."
  (interactive)
  (e2wm-term:history-move-next)
  (e2wm-term:history-send-pt-point))

(defvar e2wm-term:input-mode-map
  (e2wm:define-keymap
   '(("<C-return>" . e2wm-term:input-invoke-command)
     ("<SPC>"      . e2wm-term:input-insert-with-help)
     ("C-i"        . e2wm-term:input-completion)
     ("/"          . e2wm-term:input-insert-with-ac)
     ("M-p"        . e2wm-term:input-history-previous)
     ("M-n"        . e2wm-term:input-history-next)
     ("C-c C-p"    . e2wm-term:history-move-previous)
     ("C-c C-n"    . e2wm-term:history-move-next))))

(define-derived-mode e2wm-term:input-mode fundamental-mode "Input")


;;;;;;;;;;;;;;;;;;;;
;; History Plugin

(e2wm:plugin-register 'term-history
                      "Term History"
                      'e2wm-term:def-plugin-history)

(defvar e2wm-term::history-highlight-overlay nil)

(defun e2wm-term:def-plugin-history (frame wm winfo)
  (wlf:set-buffer wm (wlf:window-name winfo)
                  (or (get-buffer (e2wm-term::history-buffer-name))
                      (let ((backend (e2wm-term:current-backend)))
                        (with-current-buffer (generate-new-buffer (e2wm-term::history-buffer-name))
                          (e2wm-term:history-mode)
                          (set (make-local-variable 'e2wm-term::history-highlight-overlay) nil)
                          (add-hook 'post-command-hook 'e2wm-term:history-highlight nil t)
                          (e2wm-term::awhen (e2wm-term:$backend-history-hook backend)
                            (funcall it))
                          (setq buffer-read-only t)
                          (buffer-disable-undo)
                          (current-buffer)))))
  (with-selected-window (wlf:get-window wm (wlf:window-name winfo))
    (goto-char (point-max))
    (recenter -1)))

(defun e2wm-term::history-buffer-name ()
  (format " *E2WM-TERM History for %s*"
          (e2wm-term:$backend-name (e2wm-term:current-backend))))

(defun e2wm-term::history-active-p ()
  (and (e2wm:managed-p)
       (e2wm-term::awhen-buffer-live (wlf:get-buffer (e2wm:pst-get-wm) 'history)
         (eq (buffer-local-value 'major-mode it) 'e2wm-term:history-mode))))

(defun e2wm-term::history-index-at-point (&optional pt)
  (or (get-text-property (or pt (point)) 'e2wm-term:history-index)
      0))

(defun e2wm-term::history-marker-at-point (&optional pt)
  (get-text-property (or pt (point)) 'e2wm-term:history-marker))

(defun e2wm-term::history-nextpt (&optional pt)
  (or (next-single-property-change (or pt (point)) 'e2wm-term:history-index)
      (point-max)))

(defun e2wm-term::history-prevpt (&optional pt)
  (or (previous-single-property-change (or pt (point)) 'e2wm-term:history-index)
      (point-min)))

(defun e2wm-term::history-currpt (&optional pt)
  (let ((idx (e2wm-term::history-index-at-point pt))
        (prevpt (e2wm-term::history-prevpt pt)))
    (if (and (> idx 0)
             (= (e2wm-term::history-index-at-point prevpt) idx))
        prevpt
      (or pt (point)))))

(defvar e2wm-term::history-grep-timer nil)
(defvar e2wm-term::history-last-grep-value "")
(defvar e2wm-term::history-migemo-active-p nil)
(defun e2wm-term::history-grep-start ()
  (e2wm-term--trace "history grep start")
  (setq e2wm-term::history-last-grep-value "")
  (if e2wm-term::history-grep-timer
      (e2wm-term--info "history already grep timer started")
    (setq e2wm-term::history-grep-timer
          (run-with-idle-timer 0.3 t 'e2wm-term::history-grep-do))))

(defun e2wm-term::history-grep-stop ()
  (e2wm-term--trace "history grep stop")
  (let ((timer (symbol-value 'e2wm-term::history-grep-timer)))
    (when timer
      (cancel-timer timer))
    (setq e2wm-term::history-grep-timer nil)))

(defun e2wm-term::history-grep-do ()
  (let* ((iptvalue (with-selected-window (or (active-minibuffer-window)
                                             (minibuffer-window))
                     (minibuffer-contents)))
         (iptvalue (replace-regexp-in-string "^\\s-+" "" iptvalue))
         (iptvalue (replace-regexp-in-string "\\s-+$" "" iptvalue))
         (func (or (when (and e2wm-term::history-migemo-active-p
                              (featurep 'migemo))
                     'migemo-search-pattern-get)
                   'regexp-quote))
         (do-update (not (string= iptvalue e2wm-term::history-last-grep-value)))
         (re-list (when (and do-update (not (string= iptvalue "")))
                    (mapcar (lambda (s) (funcall func s))
                            (split-string iptvalue " +"))))
         (wnd (when do-update (wlf:get-window (e2wm:pst-get-wm) 'history))))
    (when (window-live-p wnd)
      (with-selected-window wnd
        (e2wm-term--trace "history grep update visibility : %s" iptvalue)
        (let ((buffer-read-only nil))
          (when (< (length iptvalue)
                   (length e2wm-term::history-last-grep-value))
            ;; If input is shorter than last time value,
            ;; At the beginning, try to back old contents.
            (e2wm-term::set-visibility (point-min) (point-max) nil))
          (setq e2wm-term::history-last-grep-value iptvalue)
          (save-excursion
            (dolist (re re-list)
              (yaxception:$
                (yaxception:try
                  (e2wm-term--trace "history hide entry start : %s" re)
                  (loop initially (goto-char (point-min))
                        with lastpt = 1
                        while (re-search-forward re nil t)
                        for mtext = (match-string-no-properties 0)
                        ;; If match record is hidden already,
                        if (get-text-property (point) 'invisible)
                        ;; Go to head of next shown record or end of buffer.
                        do (e2wm-term:history-move-next t t)
                        ;; If match record is shown,
                        else
                        do (progn
                             ;; Hide region from the end of last match record to the start of this record.
                             (e2wm-term::set-visibility lastpt (e2wm-term::history-currpt) t)
                             ;; Go to head of next shown record or end of buffer.
                             (e2wm-term:history-move-next t t)
                             (setq lastpt (point)))
                        ;; At last, hide unmatch records on end of buffer.
                        finally do (e2wm-term::set-visibility lastpt (point-max) t)))
                (yaxception:catch 'error e
                  (e2wm-term--error "failed history hide entry : %s\n%s"
                                    (yaxception:get-text e)
                                    (yaxception:get-stack-trace-string e)))))))))))

(defun e2wm-term:history-highlight (&optional pt)
  "Highlight entry of history buffer."
  (e2wm:message "#Term-History highlight")
  (with-selected-window (wlf:get-window (e2wm:pst-get-wm) 'history)
    (let* ((startpt (e2wm-term::history-currpt (or pt (point))))
           (endpt (e2wm-term::history-nextpt startpt))
           (args (list startpt endpt (current-buffer)))
           (buffer-read-only nil))
      (if (<= endpt startpt)
          (when (overlayp e2wm-term::history-highlight-overlay)
            (delete-overlay e2wm-term::history-highlight-overlay))
        (e2wm:message "  #Term-History highlight update : %s"
                      (buffer-substring-no-properties startpt endpt))
        (if (overlayp e2wm-term::history-highlight-overlay)
            (apply 'move-overlay e2wm-term::history-highlight-overlay args)
          (setq e2wm-term::history-highlight-overlay (apply 'make-overlay args))
          (overlay-put e2wm-term::history-highlight-overlay 'face 'highlight))))))

(defun e2wm-term:history-sync ()
  "Move cursor of main buffer to the pointed entry of history buffer."
  (with-current-buffer (wlf:get-buffer (e2wm:pst-get-wm) 'history)
    (let* ((marker (e2wm-term::history-marker-at-point))
           (buf (cond ((markerp marker)
                       (marker-buffer marker))
                      ((= (point) (point-max))
                       (wlf:get-buffer (e2wm:pst-get-wm) 'main))))
           (pt (when (markerp marker)
                 (marker-position marker)))
           (wnd (when (buffer-live-p buf)
                  (get-buffer-window buf))))
      (when (window-live-p wnd)
        (with-selected-window wnd
          (goto-char (or pt (point-max)))
          (recenter (if pt 0 -1)))))))

(defun e2wm-term:history-add-on-current (cmdstr marker)
  "Add entry on current buffer.

CMDSTR is string as entry.
MARKER is marker for the entry point of main buffer."
  (e2wm:message "#Term-History add : %s" cmdstr)
  (when (and (stringp cmdstr)
             (string-match "[^ \t\n]" cmdstr))
    (goto-char (point-max))
    (let* ((buffer-read-only nil)
           (pt (point))
           (nextidx (1+ (e2wm-term::history-index-at-point
                         (when (> pt (point-min)) (1- pt)))))
           (minidx (1+ (- nextidx e2wm-term:history-max-length)))
           (minpt (when (> minidx 1)
                    (loop with pt = (point-min)
                          while (< pt (point-max))
                          for nextpt = (e2wm-term::history-nextpt pt)
                          for idx = (e2wm-term::history-index-at-point nextpt)
                          if (= nextpt pt)  return nil
                          if (= idx minidx) return nextpt
                          else              do (setq pt nextpt)))))
      (insert cmdstr "\n")
      (put-text-property pt (point) 'e2wm-term:history-index nextidx)
      (put-text-property pt (point) 'e2wm-term:history-marker marker)
      (when minpt (delete-region (point-min) minpt))
      pt)))

(defun e2wm-term:history-add (cmdstr marker)
  "Add entry into history buffer.

CMDSTR is string as entry.
MARKER is marker for the entry point of main buffer."
  (with-selected-window (wlf:get-window (e2wm:pst-get-wm) 'history)
    (e2wm-term::awhen (e2wm-term:history-add-on-current cmdstr marker)
      (recenter -1))))

(defun e2wm-term:history-move-next (&optional not-highlight not-sync)
  "Move cursor to next entry in history buffer."
  (interactive)
  (with-selected-window (wlf:get-window (e2wm:pst-get-wm) 'history)
    (goto-char (loop with pt = (point)
                     while (< pt (point-max))
                     do (setq pt (e2wm-term::history-nextpt pt))
                     if (not (get-text-property pt 'invisible)) return pt
                     finally return (point-max)))
    (when (not not-highlight) (e2wm-term:history-highlight))
    (when (not not-sync) (e2wm-term:history-sync))))

(defun e2wm-term:history-move-previous (&optional not-highlight not-sync)
  "Move cursor to previous entry in history buffer."
  (interactive)
  (with-selected-window (wlf:get-window (e2wm:pst-get-wm) 'history)
    (goto-char (loop with pt = (point)
                     while (> pt (point-min))
                     do (setq pt (e2wm-term::history-prevpt pt))
                     if (not (get-text-property pt 'invisible)) return pt
                     finally return (point-min)))
    (when (not not-highlight) (e2wm-term:history-highlight))
    (when (not not-sync) (e2wm-term:history-sync))))

(defun e2wm-term:history-send-pt-point ()
  "Do `e2wm-term:input-value-update' from the pointed entry string of history buffer."
  (interactive)
  (with-current-buffer (wlf:get-buffer (e2wm:pst-get-wm) 'history)
    (e2wm-term:input-value-update
     (replace-regexp-in-string "\\s-+\\'" "" (buffer-substring-no-properties
                                              (e2wm-term::history-currpt)
                                              (e2wm-term::history-nextpt)))))
  (e2wm:pst-window-select-main))

(defun e2wm-term:history-show-all ()
  "Show all entry of history buffer."
  (interactive)
  (with-selected-window (wlf:get-window (e2wm:pst-get-wm) 'history)
    (let ((buffer-read-only nil))
      (e2wm-term::set-visibility (point-min) (point-max) nil))))

(defun e2wm-term:history-grep-abort ()
  "Exit from minibuffer of grepping entry of history buffer."
  (interactive)
  (yaxception:$
    (yaxception:try
      (e2wm-term--trace "history grep abort")
      (e2wm-term::history-grep-stop)
      (e2wm-term:history-show-all))
    (yaxception:finally
      (abort-recursive-edit))))

(defvar e2wm-term:history-grep-map
  (let ((map (copy-keymap minibuffer-local-map)))
    (define-key map (kbd "C-g") 'e2wm-term:history-grep-abort)
    map))

(defun e2wm-term:history-grep (&optional toggle initial-input)
  "Grep entry of history buffer.

- TOGGLE is boolean. If non-nil, search with the reverse config of `e2wm-term:use-migemo'.
- INITIAL-INPUT is string for the initial value of minibuffer."
  (interactive "P")
  (yaxception:$
    (yaxception:try
      (setq e2wm-term::history-migemo-active-p
            (if toggle (not e2wm-term:use-migemo) e2wm-term:use-migemo))
      (let* ((migemomsg (when (and e2wm-term::history-migemo-active-p
                                   (featurep 'migemo))
                          "[MIGEMO] "))
             (prompt (concat migemomsg "Search: ")))
        (when migemomsg
          (put-text-property 0 (- (length migemomsg) 1) 'face migemo-message-prefix-face prompt))
        (e2wm-term:history-show-all)
        (e2wm-term::history-grep-start)
        (when (read-from-minibuffer prompt initial-input e2wm-term:history-grep-map)
          (with-selected-window (wlf:get-window (e2wm:pst-get-wm) 'history)
            (goto-char (point-max))
            (recenter -1))
          t)))
    (yaxception:finally
      (e2wm-term::history-grep-stop))))

(defvar e2wm-term:history-mode-map
  (e2wm:define-keymap
   '(("n"   . e2wm-term:history-move-next)
     ("p"   . e2wm-term:history-move-previous)
     ("j"   . e2wm-term:history-move-next)
     ("k"   . e2wm-term:history-move-previous)
     ("s"   . e2wm-term:history-grep)
     ("a"   . e2wm-term:history-show-all)
     ("C-m" . e2wm-term:history-send-pt-point))))

(define-derived-mode e2wm-term:history-mode fundamental-mode "History")


;;;;;;;;;;;;;;;;;
;; Help Plugin

(e2wm:plugin-register 'term-help
                      "Term Help"
                      'e2wm-term:def-plugin-help)

(defvar e2wm-term::help-buffer-name " *E2WM-TERM Help*")
(defvar e2wm-term::help-last-value "")

(defun e2wm-term:def-plugin-help (frame wm winfo)
  (e2wm-term::help-ensure-buffer wm winfo)
  (setq e2wm-term::help-last-value ""))

(yaxception:deferror 'e2wm-term:err-invalid-helper
                     nil
                     "[E2WM-TERM] Invalid value of e2wm-term:command-helper")

(defun e2wm-term::help-ensure-buffer (&optional wm winfo)
  (let ((wm (or wm (e2wm:pst-get-wm)))
        (wname (if winfo (wlf:window-name winfo) 'help)))
    (or (ignore-errors (wlf:get-buffer wm wname))
        (let ((buf (or (get-buffer e2wm-term::help-buffer-name)
                       (with-current-buffer (generate-new-buffer e2wm-term::help-buffer-name)
                         (e2wm-term:help-mode)
                         (use-local-map (e2wm-term::keymap-emulate
                                         :override-map view-mode-map
                                         :emulate-map-sym 'e2wm-term:help-mode-map
                                         :emulate-map-mode 'e2wm-term:help-mode))
                         (buffer-disable-undo)
                         (current-buffer)))))
          (wlf:set-buffer wm wname buf)
          buf))))

(defun e2wm-term::help-value-update (value)
  (e2wm:message "#Term-Help value update : %s" (truncate-string-to-width (or value "") 20 nil nil t))
  (with-current-buffer (e2wm-term::help-ensure-buffer)
    (let ((buffer-read-only nil))
      (erase-buffer)
      (when value (insert value))
      (goto-char (point-min)))))

(defun e2wm-term::help-ensure-window ()
  (e2wm-term::help-ensure-buffer)
  (when (not (ignore-errors (wlf:get-window (e2wm:pst-get-wm) 'help)))
    (wlf:show (e2wm:pst-get-wm) 'help)))

(defun e2wm-term::help-maximize ()
  (e2wm-term::help-ensure-window)
  (wlf:hide (e2wm:pst-get-wm) 'history))

(defun e2wm-term::help-normalize ()
  (e2wm-term::help-ensure-window)
  (wlf:show (e2wm:pst-get-wm) 'history))

(defvar e2wm-term::help-timer nil)
(defun* e2wm-term::help-show (cmd argstr &key showp maximize selectp delay)
  (let ((cmdstr (when (stringp cmd)
                  (concat cmd
                          (or (when (stringp argstr) (concat " " argstr))
                              "")))))
    (when (and cmdstr
               (not (string= cmdstr ""))
               (not (string= cmdstr e2wm-term::help-last-value))
               (or (and (stringp cmd)
                        (not (string= cmd e2wm-term:command-helper)))
                   (and (stringp argstr)
                        (not (string-match (format "\\`%s " argstr) e2wm-term::help-last-value)))))
      (when e2wm-term::help-timer
        (cancel-timer e2wm-term::help-timer)
        (setq e2wm-term::help-timer nil))
      (if (numberp delay)
          (setq e2wm-term::help-timer
                (run-with-idle-timer delay
                                     nil
                                     'e2wm-term::help-show
                                     cmd
                                     argstr
                                     :showp showp
                                     :maximize maximize
                                     :selectp selectp))
        (e2wm:message "  #Term-Help show : %s" cmdstr)
        (e2wm-term::help-value-update (shell-command-to-string cmdstr))
        (setq e2wm-term::help-last-value cmdstr)
        (when showp (e2wm-term::help-ensure-window))
        (when maximize (e2wm-term::help-maximize))
        (when selectp (e2wm:pst-window-select 'help))))))

(defun* e2wm-term:help-command (cmd &key showp maximize selectp delay)
  "Put the result of `e2wm-term:command-helper' about CMD into help buffer.

CMD is string as command.
If SHOWP is non-nil, show the help window.
If MAXIMIZE is non-nil, show the help window at a maximum.
If SELECTP is non-nil, select the help window.
If DELAY is number, set `run-with-idle-timer' for self."
  (e2wm:message "#Term-Help command : cmdstr[%s] showp[%s] maximize[%s] selectp[%s] delay[%s]"
                cmd showp maximize selectp delay)
  (if (or (not e2wm-term:command-helper)
          (not (string-match "\\`[^ \t\n]+\\'" e2wm-term:command-helper)))
      (yaxception:throw 'e2wm-term:err-invalid-helper)
    (e2wm-term::help-show e2wm-term:command-helper
                          cmd
                          :showp showp
                          :maximize maximize
                          :selectp selectp
                          :delay delay)))

(defun* e2wm-term:help-something (cmdstr &key showp maximize selectp delay)
  "Put the result of CMDSTR into help buffer.

If SHOWP is non-nil, show the help window.
If MAXIMIZE is non-nil, show the help window at a maximum.
If SELECTP is non-nil, select the help window.
If DELAY is number, set `run-with-idle-timer' for self."
  (e2wm:message "#Term-Help something : cmdstr[%s] showp[%s] maximize[%s] selectp[%s] delay[%s]"
                cmdstr showp maximize selectp delay)
  (e2wm-term::help-show cmdstr
                        nil
                        :showp showp
                        :maximize maximize
                        :selectp selectp
                        :delay delay))

(defun e2wm-term:help-quit ()
  "Normalize help window size and select input window."
  (interactive)
  (e2wm-term::help-normalize)
  (e2wm:pst-window-select-main))

(defvar e2wm-term:help-mode-map
  (e2wm:define-keymap
   '(("q" . e2wm-term:help-quit))))

(define-derived-mode e2wm-term:help-mode view-mode "Help")


;;;;;;;;;;;;;;;
;; For Shell

(require 'readline-complete nil t)

(e2wm-term:regist-backend
 (make-e2wm-term:$backend
  :name         'shell
  :mode         'shell-mode
  :map          'shell-mode-map
  :starter      'shell
  :invoker      'comint-send-input
  :completion   'e2wm-term::shell-completion
  :input-hook   'e2wm-term::shell-input-setup
  :history-hook 'e2wm-term::shell-history-setup))

(defun e2wm-term::shell-completion ()
  (let ((comint-dynamic-complete-functions (buffer-local-value
                                            'comint-dynamic-complete-functions
                                            (wlf:get-buffer (e2wm:pst-get-wm) 'main))))
    (completion-at-point)))

(defvar e2wm-term::shell-ac-startpt nil)

(defvar e2wm-term::shell-ac-source-rlc
  '((candidates . e2wm-term::shell-rlc-candidates)
    (prefix . e2wm-term::shell-rlc-prefix)
    (requires . 0)
    (action . (lambda ()
                (when (not (= (point) e2wm-term::shell-ac-startpt))
                  (auto-complete))))))

(defun e2wm-term::shell-input-setup ()
  (when (and (featurep 'readline-complete)
             (featurep 'auto-complete))
    (add-to-list 'ac-sources 'e2wm-term::shell-ac-source-rlc t)
    ;; (add-hook 'rlc-no-readline-hook '(lambda () (auto-complete-mode -1)))
    (set (make-local-variable 'e2wm-term::shell-ac-startpt) nil)))

(defun e2wm-term::shell-rlc-candidates ()
  (when (e2wm-term::ready-backend-buffer-p)
    (setq e2wm-term::shell-ac-startpt (point))
    (let* ((buff (wlf:get-buffer (e2wm:pst-get-wm) 'main))
           (proc (get-buffer-process buff))
           (active-prompt-p (with-current-buffer buff
                              (save-excursion
                                (goto-char (point-max))
                                (loop for (re func) in ac-rlc-prompts
                                      if (looking-back re nil) return t)))))
      (when active-prompt-p
        (yaxception:$
          (yaxception:try
            (set-process-buffer proc (current-buffer))
            (rlc-candidates))
          (yaxception:finally
            (set-process-buffer proc buff)))))))

(defun e2wm-term::shell-rlc-prefix ()
  (when (re-search-backward "\\(?:^\\|[ /\n]\\)\\([^ /\n]*\\)\\=" nil t)
    (match-beginning 1)))

(defun e2wm-term::shell-history-setup ()
  (let* ((fpath (or (getenv "HISTFILE")
                    (when (string-match "zsh" shell-file-name) "~/.zsh_history")
                    (when (string-match "bash" shell-file-name) "~/.bash_history")
                    (when (string-match "ksh" shell-file-name) "~/.sh_history")
                    "~/.history"))
         (entries (when (and fpath
                             (file-exists-p fpath)
                             e2wm-term:shell-use-history)
                    (with-current-buffer (find-file-noselect fpath)
                      (loop with overlines = (- (count-lines (point-min) (point-max))
                                                e2wm-term:history-max-length)
                            initially (progn (goto-char (point-min))
                                             (when (> overlines 0)
                                               (forward-line overlines)))
                            while (not (eobp))
                            for cmdstr = (thing-at-point 'line)
                            for cmdstr = (replace-regexp-in-string "\\`\\s-+" "" cmdstr)
                            for cmdstr = (replace-regexp-in-string "\\s-+\\'" "" cmdstr)
                            for cmdstr = (replace-regexp-in-string " *; *" ";\n " cmdstr)
                            collect cmdstr
                            do (forward-line 1)
                            finally do (kill-buffer))))))
    (dolist (e entries)
      (e2wm-term:history-add-on-current e nil))))

(defun e2wm-term:shell-watch-for-password-prompt (string)
  "Do `comint-watch-for-password-prompt' with replacement of `comint-password-prompt-regexp'.

Try `string-match' to STRING for each entry of `e2wm-term:shell-password-prompt-regexps',
If matched entry is found, replace it with `comint-password-prompt-regexp' temporarily."
  (when (and (e2wm:managed-p)
             (e2wm-term::ready-backend-buffer-p)
             (not (string-match comint-password-prompt-regexp string)))
    (loop for re in e2wm-term:shell-password-prompt-regexps
          if (string-match re string)
          return (let ((comint-password-prompt-regexp re))
                   (comint-watch-for-password-prompt string)))))

(add-to-list 'comint-output-filter-functions 'e2wm-term:shell-watch-for-password-prompt t)


;;;;;;;;;;;;;;
;; For term

(e2wm-term:regist-backend
 (make-e2wm-term:$backend
  :name       'term
  :mode       'term-mode
  :map        'term-mode-map
  :starter    'term
  :invoker    'term-send-input))


(provide 'e2wm-term)
;;; e2wm-term.el ends here
