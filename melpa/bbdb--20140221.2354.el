;;; bbdb-.el --- provide interface for more easily search/choice than BBDB.

;; Copyright (C) 2014  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: bbdb, news, mail
;; Package-Version: 20140221.2354
;; Package-Commit: 2839e84c894de2513af41053e80a277a1b483d22
;; URL: https://github.com/aki2o/bbdb-
;; Package-Requires: ((bbdb "20140123.1541") (log4e "0.2.0") (yaxception "0.1"))
;; Version: 0.0.2

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
;; This extension provides interface for more easily search/choice than BBDB.
;; BBDB is a address book for MUA like Gnus/Wanderlust.
;; About BBDB, see <http://savannah.nongnu.org/projects/bbdb>.

;;; Dependency:
;; 
;; - bbdb.el ( see <http://savannah.nongnu.org/projects/bbdb> )
;; - yaxception.el ( see <https://github.com/aki2o/yaxception> )
;; - log4e.el ( see <https://github.com/aki2o/log4e> )

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your .emacs or site-start.el file.
;; 
;; (require 'bbdb-)

;;; Configuration:
;; 
;; ;; Make config suit for you. About the config item, see Customization or eval the following sexp.
;; ;; (customize-group "bbdb-")
;; 
;; (bbdb-:setup)

;;; Customization:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "bbdb-:[^:]" :docstring t)
;; `bbdb-:use-migemo'
;; Whether use migemo.el to search record in BBDB.
;; `bbdb-:replace-complete-mail-command'
;; Whether substitute `bbdb-:start-completion' for `bbdb-complete-mail'.
;; `bbdb-:rcpt-header-format'
;; Format of the value of To/Cc/Bcc when update the buffer of `bbdb-:mail-modes'.
;; `bbdb-:start-completion-key'
;; Keystroke for doing `bbdb-:start-completion'.
;; `bbdb-:mail-modes'
;; List of mode that write mail including To/Cc/Bcc header.
;; 
;;  *** END auto-documentation

;;; API:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'command :prefix "bbdb-:[^:]" :docstring t)
;; `bbdb-:next-record'
;; Move next record.
;; `bbdb-:previous-record'
;; Move previous record.
;; `bbdb-:search-record'
;; Search record.
;; `bbdb-:search-record-with-switch'
;; Search record with the reverse configuration of `bbdb-:use-migemo'.
;; `bbdb-:abort-search-record'
;; Exit from minibuffer of searching record.
;; `bbdb-:show-all-record'
;; Show all record.
;; `bbdb-:update'
;; Update BBDB- buffer by the latest record of BBDB.
;; `bbdb-:quit'
;; Close BBDB- buffer.
;; `bbdb-:finish'
;; Close BBDB- buffer and do the following action.
;; `bbdb-:open'
;; Open BBDB- buffer.
;; `bbdb-:start-completion'
;; Start the selection of To/Cc/Bcc on `bbdb-:mail-modes'.
;; 
;;  *** END auto-documentation
;; [Note] Functions and variables other than listed above, Those specifications may be changed without notice.

;;; Tested On:
;; 
;; - Emacs ... GNU Emacs 24.2.1 (i386-mingw-nt5.1.2600) of 2012-12-08 on GNUPACK
;; - bbdb.el ... Version 20140123.1541
;; - yaxception.el ... Version 0.1
;; - log4e.el ... Version 0.2.0


;; Enjoy!!!


(eval-when-compile (require 'cl))
(require 'bbdb)
(require 'font-lock)
(require 'log4e)
(require 'yaxception)
(require 'migemo nil t)


(defgroup bbdb- nil
  "More easily To/Cc/Bcc search/choice than BBDB."
  :group 'news
  :group 'mail
  :prefix "bbdb-:")

(defcustom bbdb-:use-migemo t
  "Whether use migemo.el to search record in BBDB."
  :type 'boolean
  :group 'bbdb-)

(defcustom bbdb-:replace-complete-mail-command t
  "Whether substitute `bbdb-:start-completion' for `bbdb-complete-mail'."
  :type 'boolean
  :group 'bbdb-)

(defcustom bbdb-:rcpt-header-format 'multi-line
  "Format of the value of To/Cc/Bcc when update the buffer of `bbdb-:mail-modes'."
  :type '(choice (const one-line)
                 (const multi-line))
  :group 'bbdb-)

(defcustom bbdb-:start-completion-key nil
  "Keystroke for doing `bbdb-:start-completion'."
  :type 'string
  :group 'bbdb-)

(defcustom bbdb-:mail-modes '(message-mode)
  "List of mode that write mail including To/Cc/Bcc header."
  :type '(repeat symbol)
  :group 'bbdb-)

(defface bbdb-:to-face '((t (:inherit font-lock-keyword-face :highlight t)))
  "Face of the selected record as To."
  :group 'bbdb-)

(defface bbdb-:cc-face '((t (:inherit font-lock-doc-face :highlight t)))
  "Face of the selected record as Cc."
  :group 'bbdb-)

(defface bbdb-:bcc-face '((t (:inherit font-lock-warning-face :highlight t)))
  "Face of the selected record as Bcc."
  :group 'bbdb-)


(log4e:deflogger "bbdb-:" "%t [%l] %m" "%H:%M:%S" '((fatal . "fatal")
                                                    (error . "error")
                                                    (warn  . "warn")
                                                    (info  . "info")
                                                    (debug . "debug")
                                                    (trace . "trace")))
(bbdb-:--log-set-level 'trace)


(defvar bbdb-::buffer-name "*bbdb-*")
(defvar bbdb-::bkup-buffer-name " *bbdb-:bkup*")
(defvar bbdb-::current-migemo-active-p nil)
(defvar bbdb-::current-winconf nil)


;;;;;;;;;;;;;
;; Utility

(defsubst bbdb-::active-p ()
  (eq major-mode 'bbdb-:mode))

(defsubst bbdb-::mail-buffer-p ()
  (memq major-mode bbdb-:mail-modes))

(defun* bbdb-::show-message (msg &rest args)
  (apply 'message (concat "[BBDB-] " msg) args)
  nil)


;;;;;;;;;;;
;; Setup

(defadvice bbdb-complete-mail (around bbdb-:replace activate)
  (if (and bbdb-:replace-complete-mail-command
           (cond ((fboundp 'called-interactively-p)
                  (called-interactively-p 'interactive))
                 (t
                  (interactive-p))))
      (bbdb-:start-completion)
    ad-do-it))

(defun bbdb-::setup-mail-buffer ()
  (yaxception:$
    (yaxception:try
      (when (bbdb-::mail-buffer-p)
        (bbdb-:--trace "start setup mail buffer")
        (when (and (stringp bbdb-:start-completion-key)
                   (not (string= bbdb-:start-completion-key "")))
          (bbdb-:--trace "set local key [%s] for bbdb-:start-completion" bbdb-:start-completion-key)
          (local-set-key (read-kbd-macro bbdb-:start-completion-key) 'bbdb-:start-completion))
        (bbdb-:--trace "finished setup mail buffer")))
    (yaxception:catch 'error e
      (bbdb-::show-message "Failed setup mail buffer : %s" (yaxception:get-text e))
      (bbdb-:--error "failed setup mail buffer : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))))

;;;###autoload
(defun bbdb-:setup ()
  "Do setup for using bbdb-."
  (loop for mode in bbdb-:mail-modes
        for hook = (intern-soft (concat (symbol-name mode) "-hook"))
        if (and hook
                (symbolp hook))
        do (add-hook hook 'bbdb-::setup-mail-buffer t)))


;;;;;;;;;;;;;;;;;
;; Grep Record

(defvar bbdb-::grep-record-timer nil)
(defvar bbdb-::last-grep-record-value "")
(defun bbdb-::start-grep-record ()
  (bbdb-:--trace "start grep record")
  (setq bbdb-::last-grep-record-value "")
  (if bbdb-::grep-record-timer
      (bbdb-:--info "already start grep timer")
    (setq bbdb-::grep-record-timer
          (run-with-idle-timer 0.3 t 'bbdb-::grep-record))))

(defun bbdb-::stop-grep-record ()
  (bbdb-:--trace "stop grep record")
  (let ((timer (symbol-value 'bbdb-::grep-record-timer)))
    (when timer
      (cancel-timer timer))
    (setq bbdb-::grep-record-timer nil)))

(defsubst bbdb-::set-visibility (startpt endpt invisible)
  (when (and (> startpt 0)
             (> endpt 0)
             (> endpt startpt))
    (bbdb-:--trace "%s region from %s to %s" (if invisible "hide" "show") startpt endpt)
    (put-text-property startpt endpt 'invisible invisible)
    t))

(defun bbdb-::grep-record ()
  (yaxception:$
    (yaxception:try
      (bbdb-:--trace "start grep record")
      (let* ((iptvalue (with-selected-window (or (active-minibuffer-window)
                                                 (minibuffer-window))
                         (minibuffer-contents)))
             (iptvalue (replace-regexp-in-string "^\\s-+" "" iptvalue))
             (iptvalue (replace-regexp-in-string "\\s-+$" "" iptvalue))
             (func (or (when (and bbdb-::current-migemo-active-p
                                  (featurep 'migemo))
                         'migemo-search-pattern-get)
                       'regexp-quote))
             (do-update (not (string= iptvalue bbdb-::last-grep-record-value)))
             (re-list (when (and do-update (not (string= iptvalue "")))
                        (mapcar (lambda (s) (funcall func s))
                                (split-string iptvalue " +"))))
             (buff (when do-update (get-buffer bbdb-::buffer-name))))
        (when (buffer-live-p buff)
          (with-current-buffer buff
            (bbdb-:--trace "start update record visibility by [%s]" iptvalue)
            (setq buffer-read-only nil)
            (when (< (length iptvalue)
                     (length bbdb-::last-grep-record-value))
              ;; If input is shorter than last time value,
              ;; At the beginning, try to back old contents.
              (or (bbdb-::restore-record (current-buffer) (point))
                  (bbdb-::set-visibility (point-min) (point-max) nil)))
            (setq bbdb-::last-grep-record-value iptvalue)
            (save-excursion
              (dolist (re re-list)
                (yaxception:$
                  (yaxception:try
                    (bbdb-:--trace "start hide record by %s" re)
                    (loop initially (goto-char (point-min))
                          with lastpt = 1
                          while (re-search-forward re nil t)
                          for mtext = (match-string-no-properties 0)
                          ;; If match record is hidden already,
                          if (get-text-property (point) 'invisible)
                          ;; Go to head of next shown record or end of buffer.
                          do (cond ((bbdb-:next-record t) (beginning-of-line))
                                   (t                     (goto-char (point-max))))
                          ;; If match record is shown,
                          else
                          do (if (not (bbdb-:previous-record t))
                                 (progn (bbdb-:--warn "can't move to head of record : matched [%s]" mtext)
                                        (goto-char (point-max)))
                               (let* ((recstartpt (point-at-bol))
                                      (line (thing-at-point 'line))
                                      (line (replace-regexp-in-string "\\s-+\\'" "" line)))
                                 (bbdb-:--trace "matched [%s] in %s" mtext line)
                                 ;; Hide region from the end of last match record to the start of this record.
                                 (bbdb-::set-visibility lastpt recstartpt t)
                                 ;; Go to head of next shown record or end of buffer.
                                 (cond ((bbdb-:next-record t) (beginning-of-line))
                                       (t                     (goto-char (point-max))))
                                 (setq lastpt (point))))
                          ;; At last, hide unmatch records on end of buffer.
                          finally do (bbdb-::set-visibility lastpt (point-max) t)))
                  (yaxception:catch 'error e
                    (bbdb-:--warn "failed hide record : %s\n%s"
                                  (yaxception:get-text e)
                                  (yaxception:get-stack-trace-string e))))))
            (setq buffer-read-only t)
            (bbdb-:--trace "finished update record visibility by [%s]" iptvalue)))))
    (yaxception:catch 'error e
      (bbdb-::show-message "Failed search record : %s" (yaxception:get-text e))
      (bbdb-:--error "failed grep record : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e))
      (let ((buff (get-buffer bbdb-::buffer-name)))
        (when (buffer-live-p buff)
          (with-current-buffer buff
            (setq buffer-read-only t)))))))


;;;;;;;;;;;;;;;;;;;;;;
;; Record Attribute

(defsubst bbdb-::get-field-regexp (fieldnm &optional fieldvalue regexp-p)
  (let* ((re (format "^[ \t]+\\(%s\\): +" (or fieldnm "[a-zA-Z][a-zA-Z0-9-]+"))))
    (cond (regexp-p   (concat re fieldvalue))
          (fieldvalue (concat re (regexp-quote fieldvalue) "[ \t]*$"))
          (t          re))))

(defsubst bbdb-::get-mail-field-regexp (addr)
  (bbdb-::get-field-regexp "mail"
                           (rx-to-string `(and (? (+ not-newline) "," (* (any " \t")))
                                               ,addr
                                               (any ", \t\r\n")))
                           t))

(defsubst bbdb-::get-current-name-location ()
  (save-excursion
    (let* ((belong nil)
           (startpt (progn (beginning-of-line)
                           (forward-char 2)
                           (point)))
           (endpt (or (when (search-forward " - " (point-at-eol) t)
                        (setq belong t)
                        (- (point) 3))
                      (point-at-eol)))
           (ostartpt (when belong (point)))
           (oendpt (when belong (point-at-eol))))
      (list startpt endpt ostartpt oendpt))))

(defsubst bbdb-::get-current-field-location (&optional fieldnm)
  (save-excursion
    (let* ((rendpt (or (save-excursion (end-of-line)
                                       (when (bbdb-:next-record t)
                                         (beginning-of-line)
                                         (point)))
                       (point-max)))
           (startpt (when (re-search-forward (bbdb-::get-field-regexp fieldnm) rendpt t)
                      (point)))
           (endpt (when startpt (point-at-eol)))
           (fstartpt (when startpt (match-beginning 1)))
           (fendpt (when startpt (match-end 1))))
      (list startpt endpt fstartpt fendpt))))

(defvar bbdb-::dummy-minibuffer-history nil)
(defun bbdb-::collect-rcpt-string-with-mark (markchar)
  (save-excursion
    (bbdb-:--trace "start collect rcpt string with [%s]" markchar)
    (loop with markchar = (or markchar " ")
          with re = (concat "^" markchar " [^ \t\r\n]")
          with allcand = "*Select All*"
          initially (goto-char (point-min))
          while (re-search-forward re nil t)
          do (bbdb-:--trace "found record : %s" (thing-at-point 'word))
          for name = (multiple-value-bind (startpt endpt) (bbdb-::get-current-name-location)
                       (if (or (not startpt) (not endpt))
                           (bbdb-:--warn "not found location of current name")
                         (buffer-substring-no-properties startpt endpt)))
          for addrvalue = (multiple-value-bind (startpt endpt) (bbdb-::get-current-field-location "mail")
                            (if (or (not startpt) (not endpt))
                                (bbdb-:--warn "not found location of current mail")
                              (buffer-substring-no-properties startpt endpt)))
          for addrs = (when (and name addrvalue)
                        (split-string addrvalue ",[ \t]+"))
          for candaddr = (when (> (length addrs) 1)
                           (completing-read (format "Select address of %s: " name)
                                            addrs
                                            nil
                                            t
                                            nil
                                            'bbdb-::dummy-minibuffer-history
                                            allcand))
          if (member candaddr addrs)
          do (setq addrs (list candaddr))
          append (loop for addr in addrs
                       do (bbdb-:--debug "got rcpt string : %s <%s>" name addr)
                       collect (format "%s <%s>" name addr)))))


;;;;;;;;;;;;;;;
;; Font Lock

(defsubst bbdb-::update-current-record-font-lock (face &optional exclude-field)
  (cond (face
         (put-text-property (point-at-bol) (point-at-eol) 'face `(,face highlight)))
        (t
         (put-text-property (point-at-bol) (point-at-eol) 'face 'default)
         (multiple-value-bind (startpt endpt ostartpt oendpt) (bbdb-::get-current-name-location)
           (when (and startpt endpt)
             (put-text-property startpt endpt 'face 'bbdb-name))
           (when (and ostartpt oendpt)
             (put-text-property ostartpt oendpt 'face 'bbdb-organization)))))
  (when (not exclude-field)
    (save-excursion
      (loop with exist-field = t
            while exist-field
            do (setq exist-field nil)
            do (multiple-value-bind (startpt endpt fstartpt fendpt) (bbdb-::get-current-field-location)
                 (when (and startpt endpt fstartpt fendpt)
                   (put-text-property fstartpt fendpt 'face 'bbdb-field-name)
                   (goto-char endpt)
                   (setq exist-field t)))))))


;;;;;;;;;;;;;;;;;
;; Mark Record

(defsubst bbdb-::set-mark-sentinel (ch face)
  (save-excursion
    (beginning-of-line)
    (delete-char 1)
    (insert ch)
    (bbdb-::update-current-record-font-lock face)))

(defun bbdb-::set-mark (ch &optional face)
  (when (bbdb-::active-p)
    (yaxception:$
      (yaxception:try
        (save-excursion
          (end-of-line)
          (when (bbdb-:previous-record t)
            (bbdb-:--trace "start set mark by [%s]" ch)
            (setq buffer-read-only nil)
            (bbdb-::set-mark-sentinel ch face))))
      (yaxception:catch 'error e
        (bbdb-:--error "failed set mark : %s\n%s"
                       (yaxception:get-text e)
                       (yaxception:get-stack-trace-string e))
        (yaxception:throw e))
      (yaxception:finally
        (setq buffer-read-only t)))))

(defun bbdb-::set-mark-all (ch &optional face)
  (when (bbdb-::active-p)
    (yaxception:$
      (yaxception:try
        (bbdb-:--trace "start set mark all by [%s]" ch)
        (setq buffer-read-only nil)
        (save-excursion
          (goto-char (point-min))
          (while (bbdb-:next-record t)
            (bbdb-::set-mark-sentinel ch face))))
      (yaxception:catch 'error e
        (bbdb-:--error "failed set mark all : %s\n%s"
                       (yaxception:get-text e)
                       (yaxception:get-stack-trace-string e))
        (yaxception:throw e))
      (yaxception:finally
        (setq buffer-read-only t)))))

(defmacro bbdb-::defun-set-mark (marktype markchar &optional face)
  (declare (indent 0))
  `(progn
     (defun ,(intern (format "bbdb-:set-%s" marktype)) ()
       ,(format "Set mark to current record to send as '%s'." (capitalize marktype))
       (interactive)
       (yaxception:$
         (yaxception:try
           (bbdb-::set-mark ,markchar ,face))
         (yaxception:catch 'error e
           (bbdb-::show-message "Failed set %s : %s" ,marktype (yaxception:get-text e)))))
     (defun ,(intern (format "bbdb-:set-%s-all" marktype)) ()
       ,(format "Set mark to all records to send as '%s'." (capitalize marktype))
       (interactive)
       (yaxception:$
         (yaxception:try
           (bbdb-::set-mark-all ,markchar ,face))
         (yaxception:catch 'error e
           (bbdb-::show-message "Failed set %s all : %s" ,marktype (yaxception:get-text e)))))))


;;;;;;;;;;;;;;;;;;;;;;;
;; Buffer Management

(defun bbdb-::init-buffer (buff)
  (yaxception:$
    (yaxception:try
      (bbdb-:--trace "start init buffer")
      (with-current-buffer buff
        (setq buffer-read-only nil)
        (erase-buffer)
        (loop with idx = 0
              for r in (bbdb-records)
              do (bbdb-display-record r bbdb-layout idx)
              do (incf idx))
        (string-rectangle (point-min)
                          (progn (goto-char (point-max))
                                 (beginning-of-line)
                                 (point))
                          "  ")
        (goto-char (point-min))
        (while (re-search-forward "^  [^ \t\r\n]" nil t)
          (forward-char -1)
          (put-text-property (point) (+ (point) 1) 'bbdb-::record t))
        (goto-char (point-min))
        (bbdb-:mode)
        (bbdb-:next-record t)
        (set-buffer-modified-p nil)
        (setq buffer-read-only t))
      (bbdb-:--trace "finished bbdb init buffer"))
    (yaxception:catch 'error e
      (bbdb-:--error "failed : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e))
      (when (buffer-live-p buff)
        (kill-buffer buff))
      (yaxception:throw e))))

(defun bbdb-::restore-record (buff &optional pt)
  (bbdb-:--trace "start restore record to %s" (buffer-name buff))
  (let ((bkupbuff (get-buffer bbdb-::bkup-buffer-name)))
    (if (not (buffer-live-p bkupbuff))
        (bbdb-:--info "not alive bbdb- bkup buffer")
      (with-current-buffer bkupbuff
        (copy-to-buffer buff 1 (point-max))
        (bbdb-:--trace "finished restore record")
        (when pt
          (bbdb-:--trace "try to move to point : %s" pt)
          (ignore-errors  (goto-char pt)))
        t))))


;;;;;;;;;;;;;;;;;;;;;
;; For Mail Buffer

(yaxception:deferror 'bbdb-:not-yet-implement nil "Not yet implement function for %s" 'modenm)

(defsubst bbdb-::mail-get-rcpt-string (rcpts)
  (case bbdb-:rcpt-header-format
    (one-line (mapconcat 'identity rcpts ", "))
    (t        (mapconcat 'identity rcpts ",\n\t"))))

(defun* bbdb-::mail-call-function (suffix &rest args)
  (bbdb-:--trace "start mail call function of suffix[%s] : %s" suffix args)
  (let* ((modenm (symbol-name major-mode))
         (modenm (replace-regexp-in-string "-mode\\'" "" modenm))
         (func (when (not (string= modenm "mail"))
                 (intern-soft (concat "bbdb-::" modenm "-" suffix)))))
    (if (functionp func)
        (apply func args)
      (bbdb-:--error "not found mail function : %s" func)
      (yaxception:throw 'bbdb-:not-yet-implement :modenm (symbol-name major-mode)))))

(defun bbdb-::mail-get-addrs (header)
  (bbdb-::mail-call-function "get-addrs" header))

(defun bbdb-::mail-update-rcpt (torcpts ccrcpts bccrcpts)
  (bbdb-::mail-call-function "update-rcpt" torcpts ccrcpts bccrcpts))

(defun bbdb-::mail-open-buffer (torcpts ccrcpts bccrcpts)
  (bbdb-:--trace "start mail open buffer")
  (let (headers)
    (when ccrcpts
      (push (cons "cc" (bbdb-::mail-get-rcpt-string ccrcpts)) headers))
    (when bccrcpts
      (push (cons "bcc" (bbdb-::mail-get-rcpt-string bccrcpts)) headers))
    (compose-mail (bbdb-::mail-get-rcpt-string torcpts) "" headers)))


;;;;;;;;;;;;;;;;;;;;;;
;; For Message Mode

(defvar bbdb-::message-regexp-header-end "^--text follows this line-- *$")
(defsubst bbdb-::message-get-header-endpt ()
  (save-excursion
    (goto-char (point-min))
    (or (when (re-search-forward bbdb-::message-regexp-header-end nil t)
          (beginning-of-line)
          (point))
        (point-max))))

(defsubst bbdb-::message-get-next-header-startpt (&optional header-endpt)
  (save-excursion
    (let ((endpt (or header-endpt (bbdb-::message-get-header-endpt))))
      (when (and (> endpt (point))
                 (re-search-forward "^[A-Z][a-zA-Z0-9-]+: " endpt t))
        (beginning-of-line)
        (point)))))

(defun bbdb-::message-move-header (header)
  (let* ((headernm (or (when (stringp header) (capitalize header))
                       (capitalize (symbol-name header))))
         (headerre (concat "^" headernm ": +"))
         (endpt (bbdb-::message-get-header-endpt))
         (headerpt (save-excursion (goto-char (point-min))
                                   (when (re-search-forward headerre endpt t)
                                     (point)))))
    (if (not headerpt)
        (bbdb-:--info "not found header[%s] in %s" headernm (buffer-name))
      (goto-char headerpt)
      t)))

(defun bbdb-::message-insert-header (header)
  (let* ((headernm (or (when (stringp header) (capitalize header))
                       (capitalize (symbol-name header)))))
    (when (bbdb-::message-move-header 'subject)
      (beginning-of-line)
      (insert headernm ": \n")
      (forward-char -1)
      t)))

(defun bbdb-::message-get-header (header)
  (if (not (bbdb-::message-move-header header))
      ""
    (let* ((header-endpt (bbdb-::message-get-header-endpt))
           (endpt (or (bbdb-::message-get-next-header-startpt header-endpt)
                      header-endpt)))
      (buffer-substring-no-properties (point) endpt))))

(defun bbdb-::message-get-addrs (header)
  (bbdb-:--trace "start message get addrs of %s" header)
  (save-excursion
    (loop for rcpt in (split-string (bbdb-::message-get-header header) "[ \t]*,[ \t\r\n]+")
          for addr = (or (when (string-match "<\\([^>\t\r\n]+\\)>" rcpt)
                           (match-string-no-properties 1 rcpt))
                         (replace-regexp-in-string "\\s-" "" rcpt))
          if (not (string= addr ""))
          collect addr)))

(defun bbdb-::message-update-rcpt (torcpts ccrcpts bccrcpts)
  (bbdb-:--trace "start message update rcpt")
  (save-excursion
    (loop for e in '((to  . torcpts)
                     (cc  . ccrcpts)
                     (bcc . bccrcpts))
          for header = (car e)
          for rcpts = (symbol-value (cdr e))
          for startpt = (or (when (bbdb-::message-move-header header)
                              (point))
                            (when (and rcpts
                                       (bbdb-::message-insert-header header))
                              (point)))
          for endpt = (when startpt
                        (let ((header-endpt (bbdb-::message-get-header-endpt)))
                          (or (bbdb-::message-get-next-header-startpt header-endpt)
                              header-endpt)))
          do (cond ((and startpt rcpts)
                    ;; If user select exists and move/insert to header, replace them
                    (delete-region startpt endpt)
                    (insert (bbdb-::mail-get-rcpt-string rcpts) "\n"))
                   (startpt
                    ;; If user select not exists but old value exists, delete old
                    (goto-char startpt)
                    (beginning-of-line)
                    (delete-region (point) endpt))
                   (rcpts
                    (bbdb-::show-message "Can't update value of %s" (capitalize (symbol-name header))))))))


;;;;;;;;;;;;;;;;;;;;;
;; Mode Definition

;;;###autoload
(define-derived-mode bbdb-:mode nil "BBDB-"
  "More easily To/Cc/Bcc search/choice than BBDB."
  (define-key bbdb-:mode-map (kbd "j") 'bbdb-:next-record)
  (define-key bbdb-:mode-map (kbd "k") 'bbdb-:previous-record)
  (define-key bbdb-:mode-map (kbd "h") 'backward-char)
  (define-key bbdb-:mode-map (kbd "l") 'forward-char)
  (define-key bbdb-:mode-map (kbd "J") 'scroll-up)
  (define-key bbdb-:mode-map (kbd "K") 'scroll-down)
  (define-key bbdb-:mode-map (kbd "s") 'bbdb-:search-record)
  (define-key bbdb-:mode-map (kbd "S") 'bbdb-:search-record-with-switch)
  (define-key bbdb-:mode-map (kbd "a") 'bbdb-:show-all-record)
  (define-key bbdb-:mode-map (kbd "t") 'bbdb-:set-to)
  (define-key bbdb-:mode-map (kbd "c") 'bbdb-:set-cc)
  (define-key bbdb-:mode-map (kbd "b") 'bbdb-:set-bcc)
  (define-key bbdb-:mode-map (kbd "u") 'bbdb-:set-clear)
  (define-key bbdb-:mode-map (kbd "* t") 'bbdb-:set-to-all)
  (define-key bbdb-:mode-map (kbd "* c") 'bbdb-:set-cc-all)
  (define-key bbdb-:mode-map (kbd "* b") 'bbdb-:set-bcc-all)
  (define-key bbdb-:mode-map (kbd "* u") 'bbdb-:set-clear-all)
  (define-key bbdb-:mode-map (kbd "R") 'bbdb-:update)
  (define-key bbdb-:mode-map (kbd "q") 'bbdb-:quit)
  (define-key bbdb-:mode-map (kbd "RET") 'bbdb-:finish))

(defvar bbdb-::grep-record-map
  (let ((map (copy-keymap minibuffer-local-map)))
    (define-key map (kbd "C-g") 'bbdb-:abort-search-record)
    map))


;;;;;;;;;;;;;;;;;;
;; User Command

(defun bbdb-:next-record (&optional quiet)
  "Move next record."
  (interactive)
  (yaxception:$
    (yaxception:try
      (when (bbdb-::active-p)
        (let ((pt (save-excursion
                    (loop while t
                          for pt = (next-single-property-change (point) 'bbdb-::record)
                          if (not pt) return nil
                          if (and (get-text-property pt 'bbdb-::record)
                                  (not (get-text-property pt 'invisible)))
                          return pt
                          else
                          do (goto-char pt)))))
          (if (not pt)
              (when (not quiet) (bbdb-::show-message "Not found next record"))
            (goto-char pt)
            t))))
    (yaxception:catch 'error e
      (when (not quiet)
        (bbdb-::show-message "Failed next record : %s" (yaxception:get-text e)))
      (bbdb-:--error "failed next record : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))))

(defun bbdb-:previous-record (&optional quiet)
  "Move previous record."
  (interactive)
  (yaxception:$
    (yaxception:try
      (when (bbdb-::active-p)
        (let ((pt (save-excursion
                    (loop while t
                          for pt = (previous-single-property-change (point) 'bbdb-::record)
                          if (not pt) return nil
                          if (and (get-text-property pt 'bbdb-::record)
                                  (not (get-text-property pt 'invisible)))
                          return pt
                          else
                          do (goto-char pt)))))
          (if (not pt)
              (when (not quiet) (bbdb-::show-message "Not found previous record"))
            (goto-char pt)
            t))))
    (yaxception:catch 'error e
      (when (not quiet)
        (bbdb-::show-message "Failed previous record : %s" (yaxception:get-text e)))
      (bbdb-:--error "failed previous record : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))))

(defun bbdb-:search-record (&optional toggle initial-input)
  "Search record.

- TOGGLE is boolean. If non-nil, search with the reverse config of `bbdb-:use-migemo'.
- INITIAL-INPUT is string for the initial value of minibuffer."
  (interactive "P")
  (when (bbdb-::active-p)
    (yaxception:$
      (yaxception:try
        (bbdb-:--trace "start search record")
        (copy-to-buffer bbdb-::bkup-buffer-name 1 (point-max))
        (setq bbdb-::current-migemo-active-p (if toggle (not bbdb-:use-migemo) bbdb-:use-migemo))
        (let* ((migemomsg (when (and bbdb-::current-migemo-active-p
                                     (featurep 'migemo))
                            "[MIGEMO] "))
               (prompt (concat migemomsg "Search: ")))
          (when migemomsg
            (put-text-property 0 (- (length migemomsg) 1) 'face migemo-message-prefix-face prompt))
          (bbdb-::start-grep-record)
          (let ((ipt (read-from-minibuffer prompt initial-input bbdb-::grep-record-map)))
            (when (not (string= ipt ""))
              (goto-char (point-min))
              (bbdb-:next-record t))))
        (bbdb-:--trace "finished search record"))
      (yaxception:catch 'error e
        (bbdb-::show-message "Failed search record : %s" (yaxception:get-text e))
        (bbdb-:--error "failed search record : %s\n%s"
                       (yaxception:get-text e)
                       (yaxception:get-stack-trace-string e)))
      (yaxception:finally
        (setq buffer-read-only t)
        (bbdb-::stop-grep-record)))))

(defun bbdb-:search-record-with-switch (&optional initial-input)
  "Search record with the reverse configuration of `bbdb-:use-migemo'.

- INITIAL-INPUT is string for the initial value of minibuffer."
  (interactive)
  (bbdb-:search-record t initial-input))

(defun bbdb-:abort-search-record ()
  "Exit from minibuffer of searching record."
  (interactive)
  (yaxception:$
    (yaxception:try
      (bbdb-:--trace "start abort search record")
      (bbdb-::stop-grep-record)
      (let ((buff (get-buffer bbdb-::buffer-name)))
        (if (not (buffer-live-p buff))
            (bbdb-:--info "not alive bbdb- buffer")
          (with-current-buffer buff
            (save-excursion
              (setq buffer-read-only nil)
              (bbdb-::restore-record (current-buffer) (point))
              (setq buffer-read-only t))))))
    (yaxception:catch 'error e
      (bbdb-::show-message "Failed search record : %s" (yaxception:get-text e))
      (bbdb-:--error "failed abort search record : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))
    (yaxception:finally
      (abort-recursive-edit))))

(defun bbdb-:show-all-record ()
  "Show all record."
  (interactive)
  (when (bbdb-::active-p)
    (yaxception:$
      (yaxception:try
        (bbdb-:--trace "start show all record")
        (setq buffer-read-only nil)
        (bbdb-::set-visibility (point-min) (point-max) nil)
        (goto-char (point-min))
        (bbdb-:next-record t))
      (yaxception:catch 'error e
        (bbdb-::show-message "Failed show all record : %s" (yaxception:get-text e))
        (bbdb-:--error "failed show all record : %s\n%s"
                       (yaxception:get-text e)
                       (yaxception:get-stack-trace-string e)))
      (yaxception:finally
        (setq buffer-read-only t)))))

(bbdb-::defun-set-mark "to"    "T" 'bbdb-:to-face)
(bbdb-::defun-set-mark "cc"    "C" 'bbdb-:cc-face)
(bbdb-::defun-set-mark "bcc"   "B" 'bbdb-:bcc-face)
(bbdb-::defun-set-mark "clear" " ")

(defun bbdb-:update ()
  "Update BBDB- buffer by the latest record of BBDB."
  (interactive)
  (yaxception:$
    (yaxception:try
      (when (bbdb-::active-p)
        (bbdb-:--trace "start update")
        (bbdb-::init-buffer (current-buffer))
        (bbdb-::show-message "Finished update")))
    (yaxception:catch 'error e
      (bbdb-::show-message "Failed update : %s" (yaxception:get-text e)))))

(defun bbdb-:quit ()
  "Close BBDB- buffer."
  (interactive)
  (yaxception:$
    (yaxception:try
      (when (and (bbdb-::active-p)
                 (y-or-n-p "Do you quit bbdb-?"))
        (bbdb-:--trace "quit bbdb")
        (bury-buffer)
        (set-window-configuration bbdb-::current-winconf)))
    (yaxception:catch 'error e
      (bbdb-::show-message "Failed quit : %s" (yaxception:get-text e))
      (bbdb-:--error "failed quit : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))))

(defun bbdb-:finish ()
  "Close BBDB- buffer and do the following action.

- If BBDB- is opened from `bbdb-:mail-modes', update the To/Cc/Bcc header.
- Else, open the mail buffer with the To/Cc/Bcc header."
  (interactive)
  (yaxception:$
    (yaxception:try
      (when (bbdb-::active-p)
        (bbdb-:--trace "start finish")
        (let* ((torcpts (bbdb-::collect-rcpt-string-with-mark "T"))
               (ccrcpts (bbdb-::collect-rcpt-string-with-mark "C"))
               (bccrcpts (bbdb-::collect-rcpt-string-with-mark "B")))
          (bury-buffer)
          (set-window-configuration bbdb-::current-winconf)
          (cond ((bbdb-::mail-buffer-p)
                 (bbdb-::mail-update-rcpt torcpts ccrcpts bccrcpts))
                (t
                 (bbdb-::mail-open-buffer torcpts ccrcpts bccrcpts))))))
    (yaxception:catch 'error e
      (bbdb-::show-message "Failed finish : %s" (yaxception:get-text e))
      (bbdb-:--error "failed finish : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))))

;;;###autoload
(defun bbdb-:open (&optional clean-up tomatches ccmatches bccmatches)
  "Open BBDB- buffer.

- CLEAN-UP is boolean. If non-nil, clean up the condition that select To/Cc/Bcc.
- TOMATCHES is list of Regexp for marking the matched record as To.
- CCMATCHES is list of Regexp for marking the matched record as Cc.
- BCCMATCHES is list of Regexp for marking the matched record as Bcc."
  (interactive "P")
  (yaxception:$
    (yaxception:try
      (bbdb-:--trace "start open. clean-up[%s]\ntomatches: %s\nccmatches: %s\nbccmatches: %s"
                     clean-up
                     (mapconcat 'identity tomatches ", ")
                     (mapconcat 'identity ccmatches ", ")
                     (mapconcat 'identity bccmatches ", "))
      (let* ((init nil)
             (buff (or (get-buffer bbdb-::buffer-name)
                       (progn (setq init t)
                              (get-buffer-create bbdb-::buffer-name))))
             (bbdb-buffer-name bbdb-::buffer-name))
        (setq bbdb-::current-winconf (current-window-configuration))
        (when init
          (bbdb-::init-buffer buff))
        (with-current-buffer buff
          (when clean-up
            (setq buffer-read-only nil)
            (bbdb-::set-visibility (point-min) (point-max) nil)
            (bbdb-:set-clear-all))
          (loop with pt = (point)
                for e in '((bbdb-:set-bcc . bccmatches)
                           (bbdb-:set-cc  . ccmatches)
                           (bbdb-:set-to  . tomatches))
                for setfunc = (car e)
                for matches = (symbol-value (cdr e))
                do (loop for re in matches
                         do (goto-char (point-min))
                         if (and (re-search-forward re nil t)
                                 (bbdb-:previous-record t))
                         do (progn (bbdb-:--trace "set mark by %s from %s" setfunc re)
                                   (funcall setfunc)))
                finally do (goto-char pt)))
        (pop-to-buffer buff)))
    (yaxception:catch 'error e
      (bbdb-::show-message "Failed open : %s" (yaxception:get-text e))
      (bbdb-:--error "failed open : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))))

;;;###autoload
(defun bbdb-:start-completion ()
  "Start the selection of To/Cc/Bcc on `bbdb-:mail-modes'."
  (interactive)
  (yaxception:$
    (yaxception:try
      (when (bbdb-::mail-buffer-p)
        (bbdb-:--trace "start completion")
        (let ((bccmatches (mapcar (lambda (x) (bbdb-::get-mail-field-regexp x)) (bbdb-::mail-get-addrs 'bcc)))
              (ccmatches  (mapcar (lambda (x) (bbdb-::get-mail-field-regexp x)) (bbdb-::mail-get-addrs 'cc)))
              (tomatches  (mapcar (lambda (x) (bbdb-::get-mail-field-regexp x)) (bbdb-::mail-get-addrs 'to))))
          (bbdb-:open t tomatches ccmatches bccmatches))))
    (yaxception:catch 'error e
      (bbdb-::show-message "Failed start completion : %s" (yaxception:get-text e))
      (bbdb-:--error "failed start completion : %s\n%s"
                     (yaxception:get-text e)
                     (yaxception:get-stack-trace-string e)))))


(provide 'bbdb-)
;;; bbdb-.el ends here
