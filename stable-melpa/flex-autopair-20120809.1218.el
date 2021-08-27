;;; flex-autopair.el --- Automatically insert pair braces and quotes, insertion conditions & actions are highly customizable.

;;-------------------------------------------------------------------
;;
;; Copyright (C) 2012 Yuuki Arisawa
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

;; Author: Yuuki Arisawa <yuuki.ari@gmail.com>
;; URL: https://github.com/uk-ar/flex-autopair.el
;; Created: 22 March 2012
;; Version: 0.3
;; Keywords: keyboard input

;;; Commentary:

;; ########   Compatibility   ########################################
;;
;; Works with Emacs-23.2.1, 23.1.1

;; ########   Quick start   ########################################
;;
;; Add to your ~/.emacs
;;
;; (require 'flex-autopair)
;; (flex-autopair-mode 1)

;;; History:

;; Revision 0.3 2012/06/13 22:25:33
;; * Support Emacs 24. Bug reported by @masutaka.
;; * Add setting to disable flex-autopair-mode in some major-mode. Requested by id:ril.
;; * Make flex-autopair-conditions buffer-local.
;; * Support haskell-mode and coffee-mode by @regluu503.
;;
;; Revision 0.2 2012/04/01 18:27:46
;; * Make flex-autopair-pairs buffer-local.
;; * Add variable to enable echo.
;; * Add function to reload conditions.
;;
;; Revision 0.1 2012/03/22 06:18:19
;; * Initial revision

(require 'cl)
;; Code goes here
(defcustom flex-autopair-pairs
  '((nil . nil))
  "Alist of pairs that should be used each major mode."
  :type '(repeat (cons character character))
  :group 'flex-autopair)
;; '((?\" . ?\"))
(make-variable-buffer-local 'flex-autopair-pairs)

(defcustom flex-autopair-skip-self t
  "If non-nil, skip char instead of inserting a second closing paren.
When inserting a closing paren character right before the same character,
just skip that character instead, so that hitting ( followed by ) results
in \"()\" rather than \"())\".
This can be convenient for people who find it easier to hit ) than C-f."
  :type 'boolean
  :group 'flex-autopair)

(defun flex-autopair-wrap-region (beg end opener closer)
  (let ((marker (copy-marker end)))
    (goto-char beg)
    (insert opener)
    (save-excursion
      (goto-char (marker-position marker))
      (insert closer)
      (goto-char beg)
      (show-paren-function)
      )
    ))

(defun flex-autopair-comment-or-stringp (&optional pos)
  (or (nth 3 (syntax-ppss))
      (nth 4 (syntax-ppss)))
  )

(defun flex-autopair-stringp (&optional pos)
  (nth 3 (syntax-ppss))
  )

(defun flex-autopair-docp (&optional pos)
  (setq pos (or pos (point)))
  (eq (get-text-property pos 'face)
      font-lock-doc-face))

(defun flex-autopair-escapedp (&optional pos)
  (setq pos (or pos (point)))
  (save-excursion
    (goto-char pos)
    (not (zerop (% (skip-syntax-backward "\\") 2))))
  )

;; (defun flex-autopair-get-bounds (symbol)
(defun flex-autopair-beginning-of-boundsp (symbol)
  (if (eq symbol 'region)
      (and (use-region-p)
           (if (< (point) (mark))
               `(,(point) . ,(mark))
             `(,(mark) . ,(point))))
    (let ((bounds
           (bounds-of-thing-at-point symbol)))
      (if (and (eq (car bounds) (point))
               ;; bug for bounds-of-thing-at-point
               (not (eq (point-min) (point-max))))
          bounds nil)
      )))

(defun flex-autopair-openp (syntax &optional pos)
  (setq pos (if (bobp) 1 (1- (or pos (point)))))
  (and (not (eq syntax ?\)))
       (or (eq syntax ?\();; '(?\( ?\" ?\$)
           ;; FIXME: bug with temp buffer
           ;; in string?
           (not (nth 3 (syntax-ppss)))
           )))

(defun flex-autopair-need-spacep ()
  (not (or (eq (char-syntax (preceding-char)) ? )
           (eq (char-syntax (preceding-char)) ?\( );; case for (let (()))
           (eq (char-syntax (preceding-char)) ?');; case for quote '()
           (bolp))))

(defun flex-autopair-match-linep (regexp)
  (save-excursion (re-search-backward regexp (point-at-bol) t))
  )

(defcustom flex-autopair-lisp-conditions
  '(((and (eq last-command-event ?\()
          (flex-autopair-beginning-of-boundsp 'sexp)) . bounds-and-space)
    ((and (eq last-command-event ?\()
          (flex-autopair-need-spacep)) . space-and-pair)
    ((eq last-command-event ?\() . pair)
    ((and (eq last-command-event ?`)
          (flex-autopair-docp)) . pair)
    ((and (eq last-command-event ?`)) . self)
    )
  ""
  :group 'flex-autopair)

(defcustom flex-autopair-c-conditions
  '(((and (eq last-command-event ?<)
          (flex-autopair-match-linep
           "#include\\|#import\\|static_cast\\|dynamic_cast")) . pair)
    ;; work with key-combo
    ((and (eq last-command-event ?<)
          (boundp 'key-combo-mode)
          (eq key-combo-mode t)) . space-self-space)
    ((and (eq last-command-event ?<)) . self)
    ((and (eq last-command-event ?{)) . pair-and-new-line)
    )
  ""
  :group 'flex-autopair)

(defcustom flex-autopair-singlequote-conditions
  '(((and
      (eq last-command-event ?')
      (eq ?w (char-syntax (preceding-char)))) . self)
    ((and
      (eq last-command-event ?')) . pair)
    )
  ""
  :group 'flex-autopair)

(defcustom flex-autopair-user-conditions-high nil
  "Alist of conditions"
  :group 'flex-autopair)
(make-variable-buffer-local 'flex-autopair-user-conditions-high)

(defcustom flex-autopair-user-conditions-low nil
  "Alist of conditions"
  :group 'flex-autopair)
(make-variable-buffer-local 'flex-autopair-user-conditions-low)

(defvar flex-autopair-default-conditions nil
  "")

  ;; :group 'flex-autopair)
(make-variable-buffer-local 'flex-autopair-default-conditions)

(defun flex-autopair-haskell-mode-setup ()
  (add-to-list 'flex-autopair-pairs '(?' . ?'))
  (setq flex-autopair-default-conditions flex-autopair-singlequote-conditions)
  (flex-autopair-reload-conditions)
  )

(defun flex-autopair-lisp-mode-setup ()
  (add-to-list 'flex-autopair-pairs '(?` . ?'))
  (setq flex-autopair-default-conditions flex-autopair-lisp-conditions)
  (flex-autopair-reload-conditions)
  )

(defun flex-autopair-c-mode-setup ()
  (add-to-list 'flex-autopair-pairs '(?< . ?>))
  (setq flex-autopair-default-conditions flex-autopair-c-conditions)
  (flex-autopair-reload-conditions)
  )

(defun flex-autopair-coffee-mode-setup ()
  (add-to-list 'flex-autopair-pairs '(?` . ?`)))

(defun flex-autopair-execute-macro (string)
  (cond
   ((string-match "`!!'" string)
    (destructuring-bind (pre post) (split-string string "`!!'")
      (flex-autopair-execute-macro pre)
      (save-excursion
        (flex-autopair-execute-macro post))
      ))
   (t
    (let ((p (point)))
      (insert string)
      (if (eq ?  (aref string 0))
          (save-excursion
            (goto-char p)
            (just-one-space)))
      (when (string-match "\n" string)
        (indent-according-to-mode)
        (indent-region p (point)))))))

(defun flex-autopair-gen-conditions ()
  `(((flex-autopair-escapedp) . self)
    (overwrite-mode . self)
    ,@flex-autopair-user-conditions-high
    ;; Wrap a pair.
    ((and openp (flex-autopair-beginning-of-boundsp 'region)) . bounds)
    ;; ((and openp (flex-autopair-get-url)) . region);; symbol works better
    ((and openp (flex-autopair-beginning-of-boundsp 'symbol)) . bounds)
    ((and openp (flex-autopair-beginning-of-boundsp 'word)) . bounds)
    ,@flex-autopair-default-conditions
    ,@flex-autopair-user-conditions-low
    ((and openp (flex-autopair-beginning-of-boundsp 'sexp)) . bounds)
    ;; Insert matching pair.
    (openp . pair)
    ;; Skip self.
    ((and closep flex-autopair-skip-self
          (eq (char-after) last-command-event)) . skip)
    (closep . self)
    ;; Default is self-insert-command.
    (t . self)
    ))

(defvar flex-autopair-conditions
  (flex-autopair-gen-conditions)
  "Alist of conditions")
(make-variable-buffer-local 'flex-autopair-conditions)

(defun flex-autopair-reload-conditions ()
  (interactive)
  (setq flex-autopair-conditions
        (flex-autopair-gen-conditions)))

(defun flex-autopair-insert-before (lst index newelt)
  (if (eq index 0)
      (push newelt lst)
    (push newelt (cdr (nthcdr (1- index) lst))))
  lst)

(defcustom flex-autopair-actions
  ;; don't use self-insert-command because of infinite loop in Emacs 24
  '((self . (insert last-command-event))
    (skip . (forward-char 1))
    (pair . (progn (insert last-command-event)
                   (save-excursion
                     (insert closer))))
    (bounds . (flex-autopair-wrap-region (car result)
                                         (cdr result)
                                         opener closer))
    (bounds-and-space . (progn
                          (flex-autopair-wrap-region (car result)
                                                     (cdr result)
                                                     opener closer)
                          (insert " ")
                          (backward-char 1)))
    (space-and-pair . (progn (insert " ")
                             (insert last-command-event)
                             (save-excursion
                               (insert closer))))
    (space-self-space . (progn (if (flex-autopair-need-spacep)
                                   (insert " " ))
                               (insert last-command-event)
                               (insert " ")
                               ));; for key-combo
    (pair-and-new-line . (flex-autopair-execute-macro
                          (format "%c\n`!!'\n%c" opener closer)))
    )
  "Alist of actions"
  :group 'flex-autopair)

(defcustom flex-autopair-echo-actionp t
  "If t, echo which action was executed"
  :group 'flex-autopair)

(defun flex-autopair (syntax)
  (let*
      ((closer (if (eq syntax ?\()
                   (cdr (or (assq last-command-event flex-autopair-pairs)
                            (aref (syntax-table) last-command-event)))
                 last-command-event))
       (opener (if (eq syntax ?\))
                   (cdr (or (assq last-command-event flex-autopair-pairs)
                            (aref (syntax-table) last-command-event)))
                 last-command-event))
       (openp (flex-autopair-openp syntax))
       (closep (not openp))
       (result))
    (catch 'break
      (mapc (lambda (x)
              (when (setq result (eval (car x)))
                (if (and flex-autopair-echo-actionp
                         (not (minibufferp)))
                    (message "%s" (cdr x)))
                (eval (cdr (assq (cdr x) flex-autopair-actions)))
                (throw 'break t))
              ) flex-autopair-conditions)
      )))

(defun flex-autopair-get-command-hook ()
  (if (boundp 'post-self-insert-hook)
      'post-self-insert-hook
    'post-command-hook))

;;;###autoload
(define-minor-mode flex-autopair-mode
  "Toggle automatic parens pairing (Flex Autopair mode).
With a prefix argument ARG, enable Flex Autopair mode if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
the mode if ARG is omitted or nil.

Flex Autopair mode is a minor mode.  When enabled, typing
an open parenthesis automatically inserts the corresponding
closing parenthesis.  \(Likewise for brackets, etc.)"
  :lighter " FA"
  :group 'flex-autopair
  (let ((hook (flex-autopair-get-command-hook)))
    (if flex-autopair-mode
        (add-hook hook #'flex-autopair-post-command-function nil t)
      (remove-hook hook #'flex-autopair-post-command-function t)
      )))

(defun flex-autopair-post-command-function ()
  (let* ((syntax (and (eq (char-before) last-command-event) ; Sanity check.
                      flex-autopair-mode
                      (let ((x (assq last-command-event
                                     flex-autopair-pairs)))
                        (cond
                         (x (if (eq (car x) (cdr x)) ?\" ?\())
                         ((rassq last-command-event flex-autopair-pairs)
                          ?\))
                         (t (char-syntax last-command-event)))))))
    (cond ((and (memq syntax '(?\) ?\( ?\" ?\$)) ;; . is for c <
                (not isearch-mode))
           (undo-boundary)
           ;; for Emacs 24
           (let ((delete-active-region nil))
             (delete-char -1))
           (flex-autopair syntax)))
    ))

(defcustom flex-autopair-disable-modes nil
  "Major modes `flex-autopair-mode' can not run on."
  :group 'flex-autopair)

;; copy from auto-complete-mode-maybe
(defun flex-autopair-mode-maybe ()
  "What buffer `flex-autopair-mode' prefers."
  (when (and (not (minibufferp (current-buffer)))
             (not (memq major-mode flex-autopair-disable-modes))
             (flex-autopair-mode 1)
             )))

;; copy from global-auto-complete-mode
;;;###autoload
(define-global-minor-mode global-flex-autopair-mode
  flex-autopair-mode flex-autopair-mode-maybe
  ;; :init-value t bug?
  :group 'flex-autopair)

;;default config
(global-flex-autopair-mode t)

(add-hook 'haskell-mode-hook
          'flex-autopair-haskell-mode-setup)

(dolist (hook '(lisp-mode-hook emacs-lisp-mode-hook lisp-interaction-mode-hook
                               inferior-gauche-mode-hook scheme-mode-hook))
  (add-hook hook
            'flex-autopair-lisp-mode-setup))

(dolist (hook '(c-mode-hook c++-mode-hook objc-mode-hook))
  (add-hook hook
            'flex-autopair-c-mode-setup))

(add-hook 'coffee-mode-hook
          'flex-autopair-coffee-mode-setup)

(defun flex-autopair-post-command-function-helper ()
  (unless (boundp 'post-self-insert-hook)
    (flex-autopair-post-command-function)
    ))

(defun flex-autopair-test-command (mode command)
  (with-temp-buffer
    (funcall mode)
    (flex-autopair-mode-maybe)
    (setq last-command-event command)
    (call-interactively 'self-insert-command)
    (flex-autopair-post-command-function-helper)
    (list
     (buffer-substring-no-properties (point-min) (point-max))
     (point))
    ))

(defun flex-autopair-test-helper-execute (command)
  (execute-kbd-macro (read-kbd-macro command))
  (buffer-substring-no-properties (point-min) (point-max))
  )

(dont-compile
  (when (fboundp 'describe)
    (describe ("flex-autopair in temp-buffer" :vars ((mode)))
      (shared-context ("execute" :vars (cmd))
        (around
          (when (fboundp 'key-combo-mode)
            (key-combo-mode -1))
          (flex-autopair-mode 1)
          (funcall el-spec:example)))
      (shared-context ("insert & execute" :vars (pre-string))
        (before
          (insert pre-string))
        (include-context "execute"))
      (shared-context ("insert & move & execute" :vars (pre-string pos))
        (before
          (insert pre-string)
          (goto-char pos))
        (include-context "execute"))
      (around
        (global-flex-autopair-mode 1)
        (when (fboundp 'global-key-combo-mode)
          (global-key-combo-mode -1))
        (with-temp-buffer
          (switch-to-buffer (current-buffer))
          (if mode (funcall mode))
          (funcall el-spec:example)))

      (it ()
        (should-not
         (memq 'flex-autopair-post-command-function
               (eval (flex-autopair-get-command-hook)))))
      (it ()
        (c-mode)
        (should
         (memq 'flex-autopair-post-command-function
               (eval (flex-autopair-get-command-hook)))))
      (it ()
        (let ((flex-autopair-disable-modes '(c-mode)))
          (c-mode))
        (should-not
         (memq 'flex-autopair-post-command-function post-command-hook)))
      (context ("in default-mode" :vars ((mode)))
        (before
          (unless (eq major-mode 'fundamental-mode)
            (fundamental-mode)))
        (it ()
          (should-not
           (memq 'flex-autopair-post-command-function
                 (eval (flex-autopair-get-command-hook)))))
        (it "isearch-mode"
          (should (eq major-mode 'fundamental-mode))
          (insert "(");; not to raise error from isearch-search
          (isearch-mode nil);; backward search
          (execute-kbd-macro "(")
          (should (string= (buffer-string) "("))
          (should (eq (point) 1)))
        (context "execute"
          (include-context "execute")
          (it (:vars ((cmd "'")))
            (should (string= (flex-autopair-test-helper-execute cmd) "'"))
            (should (eq (point) 2))
            )
          (it (:vars ((cmd "(")))
            (should (string= (flex-autopair-test-helper-execute cmd) "()"))
            (should (eq (point) 2))
            )
          (it (:vars ((cmd "()")))
            (should (string= (flex-autopair-test-helper-execute cmd) "()"))
            (should (eq (point) 3))
            )
          (it (:vars ((cmd "（")))
            (should (string= (flex-autopair-test-helper-execute cmd) "（）"))
            (should (eq (point) 2))
            )
          )
        (context ("insert & move & execute" :vars (pre-string pos))
          (include-context "insert & move & execute")
          (it (:vars ((cmd "（") (pre-string "あ") (pos 1)))
            (should (string= (flex-autopair-test-helper-execute cmd) "（あ）"))
            (should (eq (point) 2))
            )
          (it (:vars ((cmd "(") (pre-string "()") (pos 1)))
            (should (string= (flex-autopair-test-helper-execute cmd) "(())"))
            (should (eq (point) 2))
            )
          (it (:vars ((cmd "((") (pre-string "") (pos 2)))
            (should (string= (flex-autopair-test-helper-execute cmd) "(())"))
            (should (eq (point) 3))
            )
          (it (:vars ((cmd "(") (pre-string "(word)") (pos 1)))
            (should (string= (flex-autopair-test-helper-execute cmd) "((word))"))
            (should (eq (point) 2))
            )
          (it (:vars ((cmd "(") (pos 1) (pre-string "\"word\"")))
            (should (string= (flex-autopair-test-helper-execute cmd)
                             "(\"word\")"))
            (should (eq (point) 2)))
          ;; (it (:vars ((cmd ")") (pos 2) (pre-string "()")))
          ;;   ;; buffer-string is not () because last-command is not flex-autopair
          ;;   ;; bug?
          ;;   (should (string= (flex-autopair-test-helper-execute ")") "())"))
          ;;   (should (eq (point) 3)))
          ;;??
          ;; (it (:vars ((cmd "(") (pre-string "()") (pos 2)))
          ;;   (should (string= (flex-autopair-test-helper-execute cmd) "(())"))
          ;;   (should (eq (point) 3))
          ;;   )
          )
        (context ("insert & execute" :vars (pre-string))
          (include-context "insert & execute")
          (it (:vars ((cmd "(") (pre-string "a")))
            (should (string= (flex-autopair-test-helper-execute cmd) "a()"))
            (should (eq (point) 3))
            )
          (context "escape"
            (it (:vars ((cmd "(") (pre-string "\\")))
              (should (string= (flex-autopair-test-helper-execute cmd) "\\("))
              (should (eq (point) 3)))
            (it (:vars ((cmd "(") (pre-string "\\\\")))
              (should (string= (flex-autopair-test-helper-execute cmd) "\\\\()"))
              (should (eq (point) 4)))
            )
          )
        (unless delete-selection-mode
          (context ("region & execute" :vars (pre-string))
            (before
              (flex-autopair-mode 1)
              (set-mark (point))
              (insert "word"))
            (it ()
              (should
               (memq 'flex-autopair-post-command-function
                     (eval (flex-autopair-get-command-hook)))))
            (it ()
              (execute-kbd-macro "(")
              (should (string= (buffer-string) "(word)"))
              (should (eq (point) 2))
              )
            (it ()
              (exchange-point-and-mark)
              (execute-kbd-macro "(")
              (should (string= (buffer-string) "(word)"))
              (should (eq (point) 2))
              )
            (it ()
              (execute-kbd-macro ")")
              (should (string= (buffer-string) "word)"))
              (should (eq (point) 6))
              )
            (it ()
              (execute-kbd-macro "\"")
              (should (string= (buffer-string) "\"word\""))
              (should (eq (point) 2))
              )
            )
          )
        )
      (context ("in coffee-mode" :vars ((mode 'coffee-mode)))
        (include-context "execute")
        (it (:vars ((cmd "'")))
          (should (string= (flex-autopair-test-helper-execute cmd) "''"))
          (should (eq (point) 2))
          )
        (it (:vars ((cmd "`")))
          (should (string= (flex-autopair-test-helper-execute cmd) "``"))
          (should (eq (point) 2))
          )
        )
      (context ("in haskell-mode" :vars ((mode 'haskell-mode)))
        (context "execute"
          (include-context "execute")
          (it (:vars ((cmd "'")))
            (should (string= (flex-autopair-test-helper-execute cmd) "''"))
            (should (eq (point) 2))
            )
          (it (:vars ((cmd "`")))
            (should (string= (flex-autopair-test-helper-execute cmd) "``"))
            (should (eq (point) 2))
            )
          )
        (context "insert & execute"
          (include-context "insert & execute")
          (it (:vars ((cmd "'") (pre-string "a")))
            (should (string= (flex-autopair-test-helper-execute cmd) "a'"))
            (should (eq (point) 3))
            )
          )
        )
      (context ("in emacs-lisp-mode" :vars ((mode 'emacs-lisp-mode)))
        (it ()
          (should (equal nil (assoc ?< flex-autopair-pairs))))
        (it ()
          (insert "a")
          (should (flex-autopair-openp ?\")))
        (it ()
          (insert "\"a")
          (should-not (flex-autopair-openp ?\")))
        (it ()
          (insert "\"a ")
          (should-not (flex-autopair-openp ?\")))

        (context "execute"
          (include-context "execute")
          (it (:vars ((cmd "<")))
            (should (string= (flex-autopair-test-helper-execute cmd) "<"))
            (should (eq (point) 2))
            ))
        (context "insert & execute"
          (include-context "insert & execute")
          (it (:vars ((cmd "\"") (pre-string "a")))
            (should (string= (flex-autopair-test-helper-execute cmd) "a\"\""))
            (should (eq (point) 3)))
          (it (:vars ((cmd "(") (pre-string "a")))
            (should (string= (flex-autopair-test-helper-execute cmd) "a ()"))
            (should (eq (point) 4)))
          (it (:vars ((cmd "(") (pre-string "'")))
            (should (string= (flex-autopair-test-helper-execute cmd) "'()"))
            (should (eq (point) 3)))
          (it (:vars ((cmd "\"") (pre-string "\"a")))
            (should (string= (flex-autopair-test-helper-execute cmd) "\"a\""))
            (should (eq (point) 4)))
          (context "escape"
            (it (:vars ((cmd "(") (pre-string "\\")))
              (should (string= (flex-autopair-test-helper-execute cmd) "\\("))
              (should (eq (point) 3)))
            (it (:vars ((cmd "(") (pre-string "\\\\")))
              (should (string= (flex-autopair-test-helper-execute cmd) "\\\\ ()"))
              (should (eq (point) 5)))
            )
          )
        (context "insert & move & execute"
          (include-context "insert & move & execute")
          (it (:vars ((cmd "(") (pos 1) (pre-string "(word)")))
            (should (string= (flex-autopair-test-helper-execute "(")
                             "( (word))"))
            (should (eq (point) 2)))
          (it (:vars ((cmd "(") (pos 1) (pre-string "\"word\"")))
            (should (string= (flex-autopair-test-helper-execute cmd) "( \"word\")"))
            (should (eq (point) 2)))
          (it (:vars ((cmd "\"") (pos 1) (pre-string "(word)")))
            (should (string= (flex-autopair-test-helper-execute cmd) "\"(word)\""))
            (should (eq (point) 2)))
          (it (:vars ((cmd "(") (pos 1)
                      (pre-string "http://example.com/index.html")))
            (should (string= (flex-autopair-test-helper-execute cmd) "(http://example.com/index.html)"))
            (should (eq (point) 2)))
          (it (:vars ((cmd "\"") (pos 1)
                      (pre-string "(http://example.com/index.html)")))
            (should (string= (flex-autopair-test-helper-execute cmd)
                             "\"(http://example.com/index.html)\""))
            (should (eq (point) 2)))
          ;; (it (:vars ((cmd "\"") (pos 2)
          ;;             (pre-string "(http://example.com/index.html)")))
          ;;   (should (string= (flex-autopair-test-helper-execute cmd)
          ;;                    "(\"http://example.com/index.html\")"))
          ;;   (should (eq (point) 3)))
          (it (:vars ((cmd "(") (pos 1)
                      (pre-string "\"http://example.com/index.html\"")))
            (should (string= (flex-autopair-test-helper-execute cmd)
                             "( \"http://example.com/index.html\")"))
            (should (eq (point) 2)))
          )
        )
      (context ("in c-mode" :vars ((mode 'c-mode)))
        (it ()
          (should
           (memq 'flex-autopair-post-command-function
                 (eval (flex-autopair-get-command-hook)))))
        (it ()
          (should (equal '(?< . ?>) (assoc ?< flex-autopair-pairs))))
        (context "execute"
          (include-context "execute")

          (it (:vars ((cmd "'")))
            (should (string= (flex-autopair-test-helper-execute cmd) "''"))
            (should (eq (point) 2))
            )
          (it (:vars ((cmd "(")))
            (should (string= (flex-autopair-test-helper-execute "(") "()"))
            (should (eq (point) 2))
            )
          (it (:vars ((cmd "{")))
            (should (string-match "{\n[\t ]+\n}"
                                  (flex-autopair-test-helper-execute cmd)))
            (should (eq (point) 5))
            )
          (it (:vars ((cmd "()")))
            (should (string= (flex-autopair-test-helper-execute cmd) "()"))
            (should (eq (point) 3)))
          )
        (context "insert & execute"
          (include-context "insert & execute")
          (it (:vars ((cmd "<") (pre-string "#include")))
            (should (string= (flex-autopair-test-helper-execute cmd) "#include<>"))
            (should (eq (point) 10))
            )
          (it (:vars ((cmd "<") (pre-string "dynamic_cast")))
            (should (string= (flex-autopair-test-helper-execute cmd) "dynamic_cast<>"))
            (should (eq (point) 14))
            )
          (it (:vars ((cmd "<") (pre-string "foo")))
            (should (eq key-combo-mode nil))
            (should (string= (flex-autopair-test-helper-execute cmd) "foo<"))
            (should (eq (point) 5))
            )
          )
        (context "insert & move & execute"
          (include-context "insert & move & execute")
          (it (:vars ((cmd "(") (pos 1) (pre-string "()")))
            (should (string= (flex-autopair-test-helper-execute cmd) "(())"))
            (should (eq (point) 2))
            )
          )
        )
      )))

(dont-compile
  (when(fboundp 'expectations)
    ;; (flex-autopair-mode 1)
    (expectations
      (desc "c-mode")
      (expect '("()" 2)
        (flex-autopair-test-command 'c-mode ?\())
      (expect '("{\n  \n}" 5)
        (flex-autopair-test-command 'c-mode ?{))
      (desc "disable by mode")
      (expect '("'" 2)
        (with-temp-buffer
          (let ((flex-autopair-disable-modes '(emacs-lisp-mode)))
            (emacs-lisp-mode))
          (flex-autopair-mode)
          (setq last-command-event ?')
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (desc "for CoffeeScript")
      (expect '("''" 2)
        (with-temp-buffer
          (coffee-mode)
          (flex-autopair-mode-maybe)
          (setq last-command-event ?')
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '("``" 2)
        (with-temp-buffer
          (coffee-mode)
          (flex-autopair-mode-maybe)
          (setq last-command-event ?`)
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (desc "for haskell")
      (expect '("''" 2)
        (with-temp-buffer
          (haskell-mode)
          (flex-autopair-mode-maybe)
          (setq last-command-event ?')
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '("a'" 3)
        (with-temp-buffer
          (haskell-mode)
          (flex-autopair-mode-maybe)
          (insert "a")
          (setq last-command-event ?')
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '("``" 2)
        (with-temp-buffer
          (haskell-mode)
          (flex-autopair-mode-maybe)
          (setq last-command-event ?`)
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (desc "flex-autopair")
      (expect '("#include<>" 10)
        (with-temp-buffer
          (c-mode)
          (flex-autopair-mode-maybe)
          (insert "#include")
          (setq last-command-event ?\<)
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '("dynamic_cast<>" 14)
        (with-temp-buffer
          (c-mode)
          (flex-autopair-mode-maybe)
          (insert "dynamic_cast")
          (setq last-command-event ?\<)
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '("hoge < " 8)
        (with-temp-buffer
          (c-mode)
          (flex-autopair-mode-maybe)
          (insert "hoge")
          (setq last-command-event ?\<)
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '(?< . ?>)
        (with-temp-buffer
          (c-mode)
          (flex-autopair-mode-maybe)
          (assoc ?< flex-autopair-pairs)
          ))
      (expect nil
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (assoc ?< flex-autopair-pairs)
          ))
      (expect '("<" 2)
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (setq last-command-event ?\<)
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '("()" 2)
        (with-temp-buffer
          (flex-autopair-mode 1)
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (desc "isearch-mode")
      (expect '("(" 2)
        (with-temp-buffer
          (setq last-command-event ?\()
          (isearch-mode t)
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (isearch-done)
          (list (buffer-string) (point))
          ))
      (desc "japanese")
      (expect '("（）" 2);; japanese
        (with-temp-buffer
          (flex-autopair-mode 1)
          (setq last-command-event ?\（)
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '("（あ）" 2);; japanese
        (with-temp-buffer
          (save-excursion
            (insert "あ"))
          (flex-autopair-mode 1)
          (setq last-command-event ?\（)
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '("a\"\"" 3)
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (insert "a")
          (setq last-command-event ?\")
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '("a ()" 4)
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (insert "a")
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect t
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (font-lock-mode)
          (flex-autopair-mode-maybe)
          (insert "a")
          (flex-autopair-openp ?\")
          ))
      (expect nil
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (insert "\"a")
          ;; fontify!!
          (font-lock-fontify-buffer)
          (flex-autopair-openp ?\")
          ))
      (expect nil
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (insert "\"a ")
          (font-lock-fontify-buffer)
          (flex-autopair-openp ?\")
          ))
      (expect '("\"a\"" 4)
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (insert "\"a")
          (font-lock-fontify-buffer)
          (setq last-command-event ?\")
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '("a()" 3)
        (with-temp-buffer
          (insert "a")
          (flex-autopair-mode 1)
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '("'()" 3)
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (insert "'")
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (expect '("(())" 3)
        ;; (expect '("()" 2)
        (with-temp-buffer
          (flex-autopair-mode 1)
          (insert "(")
          (save-excursion
            (insert ")"))
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (list (buffer-string) (point))
          ))
      (desc "region")
      (expect "(word)"
        (with-temp-buffer
          (flex-autopair-mode 1)
          (set-mark (point))
          (insert "word")
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string))
        )
      (expect "(word)"
        (with-temp-buffer
          (flex-autopair-mode 1)
          (set-mark (point))
          (insert "word")
          (exchange-point-and-mark)
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "word)"
        (with-temp-buffer
          (set-mark (point))
          (insert "word")
          (setq last-command-event ?\))
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "((word))"
        (with-temp-buffer
          (flex-autopair-mode 1)
          (save-excursion
            (insert "(word)"))
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "( (word))"
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (save-excursion
            (insert "(word)"))
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "\"(word)\""
        (with-temp-buffer
          (save-excursion
            (insert "(word)"))
          (flex-autopair-mode 1)
          (setq last-command-event ?\")
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "(http://example.com/index.html)"
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (save-excursion
            (insert "http://example.com/index.html"))
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "(\"http://example.com/index.html\")"
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (save-excursion
            (insert "(http://example.com/index.html)"))
          (goto-char 2)
          (setq last-command-event ?\")
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "( \"http://example.com/index.html\")"
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (save-excursion
            (insert "\"http://example.com/index.html\""))
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "( \"word\")"
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (save-excursion
            (insert "\"word\""))
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "(\"word\")"
        (with-temp-buffer
          (flex-autopair-mode 1)
          (save-excursion
            (insert "\"word\""))
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "\"word\""
        (with-temp-buffer
          (flex-autopair-mode 1)
          (set-mark (point))
          (insert "word")
          (setq last-command-event ?\")
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "\\("
        (with-temp-buffer
          (insert "\\")
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "\\\\ ()"
        (with-temp-buffer
          (emacs-lisp-mode)
          (flex-autopair-mode-maybe)
          (insert "\\\\")
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect "\\\\()"
        (with-temp-buffer
          (flex-autopair-mode 1)
          (insert "\\\\")
          (setq last-command-event ?\()
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          (buffer-string)
          ))
      (expect '("()" 3)
        (with-temp-buffer
          (flex-autopair-mode 1)
          (insert "(")
          (save-excursion
            (insert ")"))
          (setq last-command-event ?\))
          (call-interactively 'self-insert-command)
          (flex-autopair-post-command-function-helper)
          ;; (buffer-substring-no-properties (point-min) (point-max))
          (list (buffer-string) (point))
          ))
      )))

;; https://github.com/jixiuf/joseph-autopair/blob/master/joseph-autopair.el
;; auto pair with newline
;; after change functions hook
;; delete pair

;; http://code.google.com/p/autopair/
;; auto wrap region
;; blink
;; skip white space?
;; don't pair in comment
;; skip
;; escape quote

;; electric-pair-mode
;; standard for 24
;; pair from syntax table
;; auto wrap region

;; acp.el
;; http://d.hatena.ne.jp/buzztaiki/20061204/1165207521
;; http://d.hatena.ne.jp/kitokitoki/20090823/p1
;; custumizable
;; auto wrap symbol

;; pair kind of comment /**/

;; reference
;; (browse-url "https://github.com/emacsmirror/emacs/blob/master/lisp/electric.el")
;; bug with blink-paren?
;; bug with auto complete?
;; https://github.com/m2ym/auto-complete/issues/85
;; bug with python indent?
;; https://github.com/fgallina/python.el/issues/59
;; todo:
;; http://www.gnu.org/software/emacs/manual/html_node/elisp/Keyboard-Macros.html#Keyboard-Macros
(provide 'flex-autopair)
;;; flex-autopair.el ends here
