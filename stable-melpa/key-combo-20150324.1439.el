;;; key-combo.el --- map key sequence to commands
;; 
;;-------------------------------------------------------------------
;;
;; Copyright (C) 2011, 2012 Yuuki Arisawa
;;
;; This file is NOT part of Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA
;;
;;-------------------------------------------------------------------
;; 
;; Author: Yuuki Arisawa <yuuki.ari@gmail.com>
;; Maintainer: Vitalie Spinu <spinuvit@gmail.com>
;; URL: https://github.com/uk-ar/key-combo
;; Package-Version: 20150324.1439
;; Package-Commit: 2fb5c65bc82d5bd2964e2b163822429ab45d90a1
;; Created: 30 November 2011
;; Version: 1.6
;; Keywords: keyboard input

;;; Commentary:
;; 
;; ########   Compatibility   ########################################
;;
;; Works with Emacs-23.2.1, 23.1.1
;; 
;; ########   Quick start   ########################################
;;
;; Add to your ~/.emacs
;;
;; (require 'key-combo)
;; (key-combo-mode 1)
;;
;; and some chords, for example
;;
;;  (key-combo-define-global (kbd "=") '(" = " " == " " === " ))
;;  (key-combo-define-global (kbd "=>") " => ")
;;
;; or load default settings
;;
;;  (key-combo-load-default)

;;; History:
;;
;; Revision 1.6 2015/03/24 15:24:37
;; * eldoc and company-mode work correctly with key-combo commands
;; * Partial fix for multiple-cursors
;; * Several IME fixes and improvements
;; * Support vector format in definition of key-combos
;; * Add global-key-combo-mode-map to support global keys
;; * Enable the use of SPC key
;; * Add key-combo-disable-modes to disable in some modes
;; 
;; Revision 1.5.1 2012/06/06 21:36:28
;; * Bug fix which use flex-autopair by mistake.
;;
;; Revision 1.5 2012/04/20 22:24:26
;; * Bug fix when just after string.
;; * Add !== for js and php's not triple-equal by tomykaira.
;; * Change some default settings.
;;
;; Revision 1.4.1 2012/04/04 21:05:48
;; * Bug fix for first key in c-mode and other modes.
;;
;; Revision 1.4 2012/04/03 20:15:21
;; * Regard first key as key-combo-execute-original when first key is not assigned
;; * Auto indent when inserting string have new line
;;
;; Revision 1.3 2012/03/13 22:00:23
;; * Make works well for other elisp which use post command hook
;;
;; Revision 1.2 2012/02/10 22:15:52
;; * Add support to use SKK. Bug reported by ballforest
;; * Bug fix for html mode.
;;
;; Revision 1.1 2012/02/08 21:56:27
;; * Add key-combo-define-local function to set key for local keymap.
;; * Add a lot of default setting in pogin's blog.
;;
;; Revision 1.0 2012/01/31 22:03:50
;; * Change clean-up function to use undo
;;
;; Revision 0.7 2012/01/17 21:25:10
;; * Insert white space dwim
;;
;; Revision 0.6 2012/01/16 21:17:01
;; * Allow cleanup function as nil
;; * Add key-combo-return function,
;; which can move to point of command beginning.
;; * Allow meta key for key-combo key.
;; * Save undo history when self-insert-command.
;;
;; Revision 0.5 2012/01/13 23:02:39
;; * Support function as key-combo command
;;
;; Revision 0.4
;; * Map key to minor mode to toggle enable and disable.
;;
;; Revision 0.3
;; * Not to cleanup when 1 sequence key
;; * Bugfix by tomykaira
;; * Refactoring
;; * Add test cases
;;
;; Revision 0.2
;; * First release
;;
;; Revision 0.1
;; * Initial revision

;; Code

(require 'cl)

;; for remove-if
(defvar key-combo-debug nil)

(defvar key-combo-loop-option 'only-same-key;'allways 'only-same-key 'never
  "Loop mode setting.
\n'allways:do loop both same key sequence and not same key sequence.
\n'only-same-key:do loop only same key sequence.
\n'never:don't loop.")

(defun key-combo-describe ()
  "List key combo bindings in a help buffer."
  (interactive)
  (describe-bindings [key-combo]))

;; (mac-input-source-is-ascii-capable)

(defun key-combo-make-key-vector (key)
  (vector 'key-combo
          ;; "_" is for error when key is " "
          (intern (concat "_" (key-description (vconcat key))))))

;; key-combo-key-binding
(defun key-combo-key-binding (key)
  ;; copy from `key-binding'
  "Return the binding for command KEY in key-combo keymaps.
KEY is a string or vector, a sequence of keystrokes.
The binding is probably a symbol with a function definition."
  (key-binding (key-combo-make-key-vector (vconcat key))))

(defun key-combo-lookup-key (keymap key)
  ;; copy from `key-binding'
  "Return the binding for command KEY in key-combo keymaps.
KEY is a string or vector, a sequence of keystrokes.
The binding is probably a symbol with a function definition."
    (lookup-key keymap (key-combo-make-key-vector (vconcat key))))

(defun key-combo-execute-original ()
  (interactive)
  (call-interactively (key-binding (this-command-keys-vector))))

(defalias 'key-combo-execute-orignal 'key-combo-execute-original)

;; should be replace by union
(defun key-combo-memq (a b)
  (setq a (if (consp a) a (list a)))
  (setq b (if (consp b) b (list b)))
  (apply
   'append
   (delete-if
    'null
    (mapcar
     (lambda (x) (if (memq x b) (list x) nil))
     a))))

;; From context-skk.el
;; http://openlab.ring.gr.jp/skk/skk/main/context-skk.el
(defun key-combo-in-stringp ()
  (nth 3 (syntax-ppss)))

(defun key-combo-in-commentp ()
  (nth 4 (syntax-ppss)))

(defun key-combo-comment-or-stringp ()
  (if (or (key-combo-in-stringp) (key-combo-in-commentp))
      t
    nil))

(defun key-combo-execute-macro (string)
  (cond
   ((string-match "`!!'" string)
    (destructuring-bind (pre post) (split-string string "`!!'")
      (key-combo-execute-macro pre)
      (save-excursion
        (key-combo-execute-macro post))))
   (t
    (let ((p (point)))
      (if (and (eq ?  (char-before))
               (eq ?  (aref string 0)))
          (delete-char -1))
      (insert string)
      (when (string-match "\n" string)
        (indent-according-to-mode)
        (indent-region p (point)))))))

(defun key-combo-get-command (command)
  (unless (key-combo-elementp command)
    (error "%s is not command" command))
  (cond
   ((functionp command) command)
   ((listp command) command)
   ((not (stringp command)) nil)
   (t
    command)))

(defun key-combo-elementp (element)
  (or (functionp element)
      (stringp element)
      ;;for unset key
      (null element)))

;;;###autoload
(defun key-combo-define (keymap key commands)
  "In KEYMAP, define key sequence KEY as COMMANDS.
KEYMAP is a keymap.\n
KEY is a string or a vector of symbols and characters meaning a
sequence of keystrokes and events.  Non-ASCII characters with codes
above 127 (such as ISO Latin-1) can be included if you use a vector.\n
COMMANDS can be an interactive function, a string, nil, or list of these COMMAND.
If COMMANDS is string, treated as a smartchr flavor keyboard macro.
If COMMANDS is nil, the key-chord is removed.
If COMMANDS is list, treated as sequential commands."
  ;;copy from key-chord-define
  (let ((base-key (list (car (listify-key-sequence key)))))
    (cond
     ;;for sequence '(" = " " == ")
     ((and (not (key-combo-elementp commands))
           (key-combo-elementp (car-safe commands)))
      (let ((seq-keys base-key));;list
        (mapc #'(lambda(command)
                  (key-combo-define keymap (vconcat seq-keys) command)
                  (setq seq-keys
                        (append seq-keys base-key)))
              commands)))
     (t
      (unless (key-combo-elementp commands)
        (error "%s is not command" commands))
      ;; regard first key as key-combo-execute-original
      (let ((first (lookup-key keymap
                               (key-combo-make-key-vector base-key))))
        (when
            (and (eq (safe-length (listify-key-sequence key)) 2)
                 (null first))
        (define-key keymap
            (key-combo-make-key-vector base-key)
            'key-combo-execute-original)))
      (define-key keymap
        (key-combo-make-key-vector key)
        (key-combo-get-command commands))))))

;;;###autoload 
(defun key-combo-define-global (keys command)
  "Give KEY a global binding as COMMAND.\n
See also `key-combo-define'\n
Note that if KEY has a local binding in the current buffer,
that local binding will continue to shadow any global binding
that you make with this function."
  ;;(interactive "sSet key chord globally (2 keys): \nCSet chord \"%s\" to command: ")
  (key-combo-define (current-global-map) keys command))

;;;###autoload
(defun key-combo-define-local (keys command)
  "Give KEY a local binding as COMMAND.\n
See also `key-combo-define'\n
The binding goes in the current buffer's local map,
which in most cases is shared with all other buffers in the same major mode."
  ;;(interactive "sSet key chord globally (2 keys): \nCSet chord \"%s\" to command: ")
  (key-combo-define (current-local-map) keys command))

;; < { [ should use flex-autopair
(defvar key-combo-global-default
  '(;; instead of using (goto-char (point-min))
    ;; use beginning-of-buffer for keydescription
    ("C-a"   . (back-to-indentation move-beginning-of-line
                                    beginning-of-buffer key-combo-return))
    ("C-e"   . (move-end-of-line end-of-buffer key-combo-return))))

(defvar key-combo-lisp-default
  '(("."  . (key-combo-execute-original))
    (". SPC" . " . ")
    ("SPC"  . (key-combo-execute-original))
    ("SPC ." . " . ")
    (","  . (key-combo-execute-original))
    (",@" . " ,@");; for macro
    (";"  . ";; ")
    ;; (";"  . (";; " ";;; " "; ")) ;cannot use because of comment
    (";=" . ";=> ")
    ("="  . ("= " "eq " "equal "))
    (">=" . ">= ")
    ("C-M-x" . (key-combo-execute-original
                (lambda ()
                  (let ((current-prefix-arg '(4)))
                    (call-interactively 'eval-defun)))));; lamda for message
    ("-"  . (key-combo-execute-original));; for symbol name
    ;; ("/" . ("/`!!'/" "/* `!!' */") );;for regexp, comment
    ))

(defvar key-combo-lisp-mode-hooks
  '(lisp-mode-hook
    emacs-lisp-mode-hook
    lisp-interaction-mode-hook
    inferior-gauche-mode-hook
    scheme-mode-hook))

(defun key-combo-read-kbd-macro (start)
  (when (or (equal (elt start 0) ?\ )
            (equal (elt start (1- (length start))) ?\ ))
    ;; (error "To bind the key SPC, use \" \", not [SPC]")
    (error "To bind the key SPC, use SPC, not \" \""))
  (read-kbd-macro start))

(defmacro define-key-combo-load (name)
  "define-key-combo-load is deprecated"
  `(defun ,(intern (concat "key-combo-load-" name "-default")) ()
     (dolist (key ,(intern (concat "key-combo-" name "-default")))
       (key-combo-define-local (key-combo-read-kbd-macro (car key)) (cdr key)))))

;; for algol like language
(defcustom key-combo-common-mode-hooks
  '(c-mode-common-hook;; It's run immediately before the language specific hook.
    php-mode-hook
    ruby-mode-hook
    cperl-mode-hook
    javascript-mode-hook
    js-mode-hook
    js2-mode-hook)
  "Hooks that enable `key-combo-common-default' setting"
  :group 'key-combo)

;; (browse-url "http://bojovs.github.com/2012/04/24/ruby-coding-style/")
(defcustom key-combo-common-default
  '((","  . ", ")
    ("="  . (" = " " == " " === " ));;" === " for js
    ("=>" . " => ")
    ("=~" . " =~ ");;for ruby regexp
    ("=*" . " =* ")                     ;for c
    ("+"  . (" + " "++"))
    ("+=" . " += ")
    ("-"  . (" - " "--"))               ;undo when unary operator
    ("-=" . " -= ")
    ("->" . " -> ");; for haskell,coffee script. overwrite in c
    (">"  . (key-combo-execute-original " >> "))
    ;; " > " should be bind in flex-autopair
    (">=" . " >= ")
    (">>=" . " >>= ")
    ("%"  . " % ")
    ("%="  . " %= ")
    ("^"  . " ^ ");; XOR for c
    ("^="  . " ^= ");; for c
    ("!" . key-combo-execute-original)
    ;; NOT for c
    ;; don't use " !" because of ruby symbol
    ;; and unary operator
    ("!="  . " != " ) ;;" !== " for js and php
    ("!==" . " !== ") ;;" !== " for js and php
    ("!~" . " !~ ")   ; for ruby
    ("~" . key-combo-execute-original)
    ;; for unary operator
    ("::" . " :: ") ;; for haskell
    ;; (":" . ":");;for ruby symbol
    ("&"  . (" & " " && "))             ;overwrite in c
    ("&=" . " &= ");; for c
    ("&&=" . " &&= ")                   ; for ruby
    ("*"  . " * " )                     ;overwrite in c
    ("*="  . " *= " )
    ("**"  . "**" )                     ;for power
    ("**=" . " **=" )                     ;for power
    ;; ("?" . "? `!!' :"); ternary operator should be bound in yasnippet?
    ;; ("?=");; for coffeescript?
    ("<" . (key-combo-execute-original " << "))
    ;; " < " should be bound in flex-autopair
    ("<=" . " <= ")
    ;; ("<?" . "<?`!!'?>");; for what?
    ("<<=" . " <<= ");; bit shift for c
    ("<-" . " <- ")
    ("<!" . "<!-- `!!' -->");; for html comment
    ("|"  . (" | " " || "));; bit OR and OR for c
    ;;ToDo: ruby block
    ("|=" . " |= ");; for c
    ("||=" . " ||= ")                   ; for ruby
    ;; ("/" . (" / " "// " "/`!!'/")) ;; devision,comment start or regexp
    ("/" . (key-combo-execute-original))
    ("/ SPC" . " / ")
    ("/=" . " /= ")
    ("*/" . "*/")
    ("/*" . "/* `!!' */")
    ("/* RET" . "/*\n`!!'\n*/");; add *? m-j
    ;; ("/* RET" . "/*\n*`!!'\n*/");; ToDo:change style by valiable
    ("{" . (key-combo-execute-original))
    ("{ RET" . "{\n`!!'\n}"))
  "Default binding which enabled by `key-combo-common-mode-hooks'"
  :group 'key-combo)

(defcustom key-combo-org-default
  '(("C-a" . (org-beginning-of-line
              beginning-of-buffer
              key-combo-return));;back-to-indentation
    ("C-e" . (org-end-of-line
              end-of-buffer
              key-combo-return)))
  "Default binding which enabled by `org-mode-hook'"
  :group 'key-combo)

(defcustom key-combo-pointer-default
  '(("*" . ("*" "**" "***"))
    ("&" . ("&" "&&" "&&&"))
    ("->" . "->"))
  "Default binding for c-mode,c++-mode,objc-mode"
  :group 'key-combo)

;;;###autoload
(defmacro key-combo-define-hook (hooks name keys)
  `(progn
     (defun ,(nth 1 name) ()
       (key-combo-load-default-1 (current-local-map) ,keys))
     (key-combo-load-by-hooks ,hooks ,name)))

;;;###autoload
(defun key-combo-load-default ()
  (interactive)
  (global-key-combo-mode t)
  (key-combo-load-default-1 (current-global-map)
                            key-combo-global-default)
  (key-combo-define-hook key-combo-common-mode-hooks
                         'key-combo-common-load-default
                         key-combo-common-default)
  (key-combo-define-hook key-combo-lisp-mode-hooks
                         'key-combo-lisp-load-default
                         key-combo-lisp-default)
  (key-combo-define-hook '(c-mode-hook c++-mode-hook)
                         'key-combo-pointer-load-default
                         key-combo-pointer-default)
  (key-combo-define-hook 'objc-mode-hook
                         'key-combo-objc-load-default
                         (append key-combo-pointer-default
                                 '(("@"  . "@\"`!!'\""))))
  (key-combo-define-hook 'org-mode-hook
                         'key-combo-org-load-default
                         key-combo-org-default)
  (key-combo-define-hook '(html-mode-hook
                           css-mode-hook
                           javascript-mode-hook
                           js-mode-hook
                           makefile-mode-hook
                           js2-mode-hook)
                         'key-combo-property-default
                         '((":"  . ": ")))
  ;; align is better for property?
  )

;; hooks function-name keys
(defun key-combo-load-by-hooks (hooks func)
  (let ((hooks (if (consp hooks) hooks (list hooks))))
    (dolist (hook hooks)
      (add-hook hook func t))))

(defun key-combo-load-default-1 (map keys)
  (dolist (key keys)
    (key-combo-define map (key-combo-read-kbd-macro (car key)) (cdr key))))

(declare-function key-combo-set-start-position "key-combo")
(declare-function key-combo-return "key-combo")
;;(declare-function key-combo-return "")
(lexical-let ((key-combo-start-position nil))
  (defun key-combo-set-start-position (pos)
    (setq key-combo-start-position pos))
  (defun key-combo-return ()
    "Return to the position when sequence of calls of the same command was started."
    (unless (eq key-combo-start-position nil)
      (progn
        (goto-char (car key-combo-start-position))
        ;; (set-window-start (selected-window) (cdr key-combo-start-position))
        ))))

;;(browse-url "http://q.hatena.ne.jp/1226571494")
(defun key-combo-count-boundary (last-undo-list)
  (length (remove-if-not 'null last-undo-list)))

(defun key-combo-undo ()
  "returns buffer undo list"
  ;; (message "count:%d" (1+ (key-combo-count-boundary buffer-undo-list)))
  (primitive-undo (1+ (key-combo-count-boundary buffer-undo-list))
                  buffer-undo-list))

(defun key-combo-command-execute (command)
  "returns buffer undo list"
  (cond
   ((stringp command)
    (key-combo-execute-macro command))
   ((commandp command)
    (call-interactively command))
   ((functionp command)
    (funcall command))
   (t (error "%s is not command" command)))
  (undo-boundary))

(defvar key-combo-command-keys nil)
(defvar key-combo-need-undop t)

(defun key-combo ()
  ;; because of prefix arg
  (interactive)
  (let ((command (key-combo-key-binding key-combo-command-keys)))
    (if (and key-combo-need-undop
             (not (eq buffer-undo-list t)))
        (key-combo-undo))
    (key-combo-command-execute command)
    (setq key-combo-need-undop t)))

(defvar key-combo-original-undo-list nil)

(defun key-combo-finalize ()
  (when (and (not (eq buffer-undo-list t))
	     key-combo-original-undo-list)
    (setq buffer-undo-list
	  (append buffer-undo-list key-combo-original-undo-list)))
  (setq key-combo-original-undo-list nil)
  (setq key-combo-command-keys nil))

;;;###autoload
(define-minor-mode key-combo-mode
  "Toggle key combo."
  :lighter " KC"
  :group 'key-combo
  :keymap (make-sparse-keymap)
  (if key-combo-mode
      (add-hook 'pre-command-hook
                ;;post-self-insert-hook
                #'key-combo-pre-command-function nil t)
    (remove-hook 'pre-command-hook
                 #'key-combo-pre-command-function t)))

(defcustom key-combo-disable-modes nil
  "Major modes `key-combo-mode' can not run on."
  :group 'key-combo)

;; copy from auto-complete-mode-maybe
(defun key-combo-mode-maybe ()
  "What buffer `key-combo-mode' prefers."
  (when (and (not (minibufferp (current-buffer)))
             (not (memq major-mode key-combo-disable-modes))
             (key-combo-mode 1)
             ;; (key-combo-setup)
             )))

;; copy from global-auto-complete-mode
;;;###autoload
(define-global-minor-mode global-key-combo-mode
  key-combo-mode key-combo-mode-maybe
  ;; :init-value t bug?
  :group 'key-combo)

(defvar multiple-cursors-mode nil)

(defun key-combo-pre-command-function ()
  (when (and key-combo-mode
	     (not multiple-cursors-mode))
   (let ((command-key-vector (this-command-keys-vector))
	 (first-timep (not (eq last-command 'key-combo))))
     (setq key-combo-command-keys
	   ;; use last-command-event becase of testability
	   (vconcat key-combo-command-keys command-key-vector))
     (unless (key-combo-key-binding key-combo-command-keys);;retry
       ;; need undo?
       (if (and (not (eq 2 (length key-combo-command-keys)))
		(equal [] (delete (aref key-combo-command-keys 0)
				  key-combo-command-keys)))
	   (setq key-combo-need-undop t)
	 ;; (setq first-timep t)
	 (setq key-combo-need-undop nil))
       (setq key-combo-command-keys command-key-vector))
     (cond ((and (not (minibufferp))
		 (not isearch-mode)
		 (key-combo-key-binding key-combo-command-keys)
		 (not (and (key-combo-comment-or-stringp)
			   (memq (key-binding command-key-vector)
				 '(self-insert-command skk-insert)))))
	    (setq this-command 'key-combo)
	    (cond (first-timep
		   ;; for test
		   ;; (setq key-combo-command-keys nil)
		   ;; (key-combo-finalize)
		   ;; first time
		   (setq key-combo-original-undo-list buffer-undo-list
			 buffer-undo-list nil)
		   (key-combo-set-start-position (cons (point) (window-start)))
		   (cond ((memq (key-binding command-key-vector)
				'(self-insert-command skk-insert))
			  (undo-boundary)
			  (key-combo-command-execute
			   (key-binding
			    command-key-vector))
			  (setq key-combo-need-undop t))))
		  ;; continue
		  ((eq key-combo-need-undop nil)
		   ;; finalize
		   (unless (eq buffer-undo-list t)
		     (setq key-combo-original-undo-list
			   (append buffer-undo-list
				   key-combo-original-undo-list)))
		   ;; (setq key-combo-command-keys nil)
		   (setq buffer-undo-list nil))))
	   (t
	    (if (eq last-command 'key-combo)
		(key-combo-finalize)))))))

(eval-after-load "eldoc"
  '(eldoc-add-command "key-combo"))

(eval-after-load "company"
  '(add-to-list 'company-begin-commands 'key-combo))


;; (listify-key-sequence
;;  (kbd "M-C-d M-C-d"))
;; (listify-key-sequence
;;  "\M-\C-d\M-\C-d")
;; (append
;;  (kbd "M-C-d M-C-d") nil)
;; (append
;;  "\M-\C-d\M-\C-d" nil);; not expected!!
;; ;; (vconcat
;; ;;  "\M-\C-d\M-\C-d")
;; (event-convert-list '(control meta ?a))
;;; (local-set-key "\M-\C-d" 'hoge)

;;todo filter
;; filter for mode
;; filter for inside string ""
;; filter for inside comment ;;

;; copy from terminal
;; xterm
;; http://ttssh2.sourceforge.jp/manual/ja/usage/tips/vim.html
;; http://d.hatena.ne.jp/guyon/20090224/1235485381
;; Bracketed Paste Mode
;; http://togetter.com/li/289305
;; http://www.bookshelf.jp/texi/elisp-manual/21-2-8/jp/elisp_40.html#SEC654
;; http://shyouhei.tumblr.com/post/63240207/pos-command-hook

;; support lamda func
(provide 'key-combo)
;;; key-combo.el ends here
