;;; migemo.el --- Japanese incremental search through dynamic pattern expansion -*- lexical-binding: t; -*-

;; $Id: migemo.el.in,v 1.9 2012/06/24 04:09:59 kaworu Exp $
;; Copyright (C) Satoru Takabayashi

;; Author: Satoru Takabayashi <satoru-t@is.aist-nara.ac.jp>
;; URL: https://github.com/emacs-jp/migemo
;; Package-Version: 20200913.12
;; Package-Commit: f756cba3d5268968da361463c2e29b3a659a3de7
;; Version: 1.9.2
;; Keywords:
;; Package-Requires: ((cl-lib "0.5"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;

;;; Code:

(require 'cl-lib)

(defgroup migemo nil
  "migemo - Japanese incremental search trough dynamic pattern expansion."
  :group 'matching)

(defcustom migemo-command "cmigemo"
  "*Name or full path of the executable for running migemo."
  :group 'migemo
  :type '(choice
          (const :tag "CMIGEMO" "cmigemo")
          (const :tag "Ruby Migemo" "ruby")
          (string :tag "Other")))

(defcustom migemo-options '("-q" "--emacs")
  "*Options for migemo command."
  :group 'migemo
  :type '(repeat string))

(defcustom migemo-white-space-regexp "[ 　\t\r\n]*"
  "*Regexp representing white spaces."
  :group 'migemo
  :type 'string)

;; for Ruby/Migemo
;; (setq migemo-command "ruby")
;; (setq migemo-options '("-S" "migemo" "-t" "emacs" "-i" "\a"))
;; (setq migemo-dictionary "somewhere/migemo/utf-8/migemo-dict")
;; (setq migemo-user-dictionary nil)
;; (setq migemo-regex-dictionary nil)

(defcustom migemo-directory nil
  "*Directory where migemo files are placed."
  :group 'migemo
  :type 'directory)

(defcustom migemo-isearch-enable-p t
  "*Enable the migemo feature on isearch or not."
  :group 'migemo
  :type 'boolean)

(defcustom migemo-use-default-isearch-keybinding t
  "*If non-nil, set migemo default keybinding for isearch in `migemo-init'."
  :group 'migemo
  :type 'boolean)

(defcustom migemo-dictionary (expand-file-name "migemo-dict" migemo-directory)
  "*Migemo dictionary file."
  :group 'migemo
  :type '(file :must-match t))

(defcustom migemo-user-dictionary (expand-file-name "user-dict" migemo-directory)
  "*Migemo user dictionary file."
  :group 'migemo
  :type '(choice
          (file :must-match t)
          (const :tag "Do not use" nil)))

(defcustom migemo-regex-dictionary (expand-file-name "regex-dict" migemo-directory)
  "*Migemo regex dictionary file."
  :group 'migemo
  :type '(choice
          (file :must-match t)
          (const :tag "Do not use" nil)))

(defcustom migemo-pre-conv-function nil
  "*Function of migemo pre-conversion."
  :group 'migemo
  :type '(choice
          (const :tag "Do not use" nil)
          function))

(defcustom migemo-after-conv-function nil
  "*Function of migemo after-conversion."
  :group 'migemo
  :type '(choice
          (const :tag "Do not use" nil)
          function))

(defcustom migemo-coding-system 'utf-8-unix
  "*Default coding system for migemo.el."
  :group 'migemo
  :type 'coding-system)

(defcustom migemo-use-pattern-alist nil
  "*Use pattern cache."
  :group 'migemo
  :type 'boolean)

(defcustom migemo-use-frequent-pattern-alist nil
  "*Use frequent patttern cache."
  :group 'migemo
  :type 'boolean)

(defcustom migemo-pattern-alist-length 512
  "*Maximal length of `migemo-pattern-alist'."
  :group 'migemo
  :type 'integer)

(defcustom migemo-pattern-alist-file
  (locate-user-emacs-file "migemo-pattern" ".migemo-pattern")
  "*Path of migemo alist file.  If nil, don't save and restore the file."
  :group 'migemo
  :type 'file)

(defcustom migemo-frequent-pattern-alist-file
  (locate-user-emacs-file "migemo-frequent" ".migemo-freqent")
  "*Path of migemo frequent alist file.  If nil, don't save and restore the file."
  :group 'migemo
  :type 'file)

(defcustom migemo-accept-process-output-timeout-msec 5
  "*Timeout of migemo process communication."
  :group 'migemo
  :type 'integer)

(defcustom migemo-isearch-min-length 1
  "*Minimum length of word to start isearch."
  :group 'migemo
  :type 'integer)

;; internal variables
(defvar migemo-process nil)
(defvar migemo-buffer nil)
(defvar migemo-current-input-method nil)
(defvar migemo-current-input-method-title nil)
(defvar migemo-input-method-function nil)
(defvar migemo-search-pattern nil)
(defvar migemo-pattern-alist nil)
(defvar migemo-frequent-pattern-alist nil)
(defvar migemo-search-pattern-alist nil)
(defvar migemo-do-isearch nil)
(defvar migemo-register-isearch-keybinding-function nil)

;; For warnings of byte-compile. Following functions are defined in XEmacs
(declare-function set-process-input-coding-system "code-process")
(declare-function set-process-output-coding-system "code-process")

(defsubst migemo-search-pattern-get (string)
  (let ((pattern (cdr (assoc string migemo-search-pattern-alist))))
    (unless pattern
      (setq pattern (migemo-get-pattern string))
      (setq migemo-search-pattern-alist
            (cons (cons string pattern)
                  migemo-search-pattern-alist)))
    pattern))

(defun migemo-toggle-isearch-enable ()
  (interactive)
  (setq migemo-isearch-enable-p (not migemo-isearch-enable-p))
  (message (if migemo-isearch-enable-p
               "t"
             "nil")))

(defun migemo-start-process (name buffer program args)
  (let* ((process-connection-type nil)
         (proc (apply 'start-process name buffer program args)))
    (if (fboundp 'set-process-coding-system)
        (set-process-coding-system proc
                                   migemo-coding-system
                                   migemo-coding-system)
      (set-process-input-coding-system  proc migemo-coding-system)
      (set-process-output-coding-system proc migemo-coding-system))
    proc))

(defun migemo-init ()
  (when (and migemo-use-frequent-pattern-alist
             migemo-frequent-pattern-alist-file
             (null migemo-frequent-pattern-alist))
    (setq migemo-frequent-pattern-alist
          (migemo-pattern-alist-load migemo-frequent-pattern-alist-file)))
  (when (and migemo-use-pattern-alist
             migemo-pattern-alist-file
             (null migemo-pattern-alist))
    (setq migemo-pattern-alist
          (migemo-pattern-alist-load migemo-pattern-alist-file)))
  (when (and migemo-use-default-isearch-keybinding
             migemo-register-isearch-keybinding-function)
    (funcall migemo-register-isearch-keybinding-function))
  (or (and migemo-process
           (eq (process-status migemo-process) 'run))
      (let ((options
             (delq nil
                   (append migemo-options
                           (when (and migemo-user-dictionary
                                      (file-exists-p migemo-user-dictionary))
                             (list "-u" migemo-user-dictionary))
                           (when (and migemo-regex-dictionary
                                      (file-exists-p migemo-regex-dictionary))
                             (list "-r" migemo-regex-dictionary))
                           (list "-d" migemo-dictionary)))))
        (setq migemo-buffer (get-buffer-create " *migemo*"))
        (setq migemo-process (migemo-start-process
                              "migemo" migemo-buffer migemo-command options))
        (set-process-query-on-exit-flag migemo-process nil)
        t)))

(defun migemo-replace-in-string (string from to)
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (let ((migemo-do-isearch nil))
      (while (search-forward from nil t)
        (replace-match to nil t)))
    (buffer-substring (point-min) (point-max))))

(defun migemo-get-pattern (word)
  (cond
   ((< (length word) migemo-isearch-min-length)
    "")
   (t
    (let (deactivate-mark pattern freq alst)
      (set-text-properties 0 (length word) nil word)
      (migemo-init)
      (when (and migemo-pre-conv-function
                 (functionp migemo-pre-conv-function))
        (setq word (funcall migemo-pre-conv-function word)))
      (setq pattern
            (cond
             ((setq freq (and migemo-use-frequent-pattern-alist
                              (assoc word migemo-frequent-pattern-alist)))
              (cdr freq))
             ((setq alst (and migemo-use-pattern-alist
                              (assoc word migemo-pattern-alist)))
              (setq migemo-pattern-alist (cons alst (delq alst migemo-pattern-alist)))
              (cdr alst))
             (t
              (with-current-buffer (process-buffer migemo-process)
                (delete-region (point-min) (point-max))
                (process-send-string migemo-process (concat word "\n"))
                (while (not (and (> (point-max) 1)
                                 (eq (char-after (1- (point-max))) ?\n)))
                  (accept-process-output migemo-process
                                         0 migemo-accept-process-output-timeout-msec))
                (setq pattern (buffer-substring (point-min) (1- (point-max)))))
              (when (and (memq system-type '(windows-nt OS/2 emx))
                         (> (length pattern) 1)
                         (eq ?\r (aref pattern (1- (length pattern)))))
                (setq pattern (substring pattern 0 -1)))
              (when migemo-use-pattern-alist
                (setq migemo-pattern-alist
                      (cons (cons word pattern) migemo-pattern-alist))
                (when (and migemo-pattern-alist-length
                           (> (length migemo-pattern-alist)
                              (* migemo-pattern-alist-length 2)))
                  (setcdr (nthcdr (1- (* migemo-pattern-alist-length 2))
                                  migemo-pattern-alist) nil)))
              pattern)))
      (if (and migemo-after-conv-function
               (functionp migemo-after-conv-function))
          (funcall migemo-after-conv-function word pattern)
        (migemo-replace-in-string pattern "\a" migemo-white-space-regexp))))))

(defun migemo-pattern-alist-load (file)
  "Load migemo alist FILE."
  (setq file (expand-file-name file))
  (when (file-readable-p file)
    (with-temp-buffer
      (let ((coding-system-for-read migemo-coding-system)
            (buffer-file-coding-system migemo-coding-system)))
      (insert-file-contents file)
      (goto-char (point-min))
      (condition-case err
          (read (current-buffer))
        (error
         (message "Error while reading %s; %s"
                  (file-name-nondirectory file)
                  (error-message-string err))
         nil)))))

(defun migemo-pattern-alist-save (&optional clear)
  "Save migemo alist file."
  (interactive)
  (when (and migemo-use-pattern-alist
             migemo-pattern-alist-file
             (or migemo-pattern-alist clear))
    (let ((file (expand-file-name migemo-pattern-alist-file)))
      (when (file-writable-p file)
        (when clear
          (setq migemo-pattern-alist nil))
        (when (and migemo-pattern-alist-length
                   (> (length migemo-pattern-alist) migemo-pattern-alist-length))
          (setcdr (nthcdr (1- migemo-pattern-alist-length)
                          migemo-pattern-alist) nil))
        (with-temp-buffer
          (let ((coding-system-for-write migemo-coding-system)
                (buffer-file-coding-system migemo-coding-system))
            (if (fboundp 'pp)
                (pp migemo-pattern-alist (current-buffer))
              (prin1 migemo-pattern-alist (current-buffer)))
            (write-region (point-min) (point-max) file nil 'nomsg)))
        (setq migemo-pattern-alist nil)))))

(defun migemo-kill ()
  "Kill migemo process."
  (interactive)
  (when (and migemo-process (eq (process-status migemo-process) 'run))
    (kill-process migemo-process)
    (setq migemo-process nil)
    (when (get-buffer migemo-buffer)
      (kill-buffer migemo-buffer))))

(defun migemo-pattern-alist-clear ()
  "Clear migemo alist data & file."
  (interactive)
  (migemo-kill)
  (migemo-pattern-alist-save 'clear)
  (migemo-init))

(defun migemo-frequent-pattern-make (fcfile)
  "Create frequent pattern from `frequent-chars'."
  (interactive "ffrequent-chars: ")
  (migemo-pattern-alist-save 'clear)
  (when migemo-frequent-pattern-alist-file
    (migemo-kill)
    (migemo-init)
    (let ((file (expand-file-name migemo-frequent-pattern-alist-file))
          (migemo-use-pattern-alist nil)
          (migemo-use-frequent-pattern-alist nil)
          (migemo-after-conv-function (lambda (_x y) y))
          word)
      (setq migemo-frequent-pattern-alist nil)
      (with-temp-buffer
        (let ((coding-system-for-write migemo-coding-system)
              (buffer-file-coding-system migemo-coding-system)))
        (insert-file-contents fcfile)
        (goto-char (point-min))
        (message "Make frequently pattern...")
        (while (not (eobp))
          (when (looking-at "^[a-z]+$")
            (setq word (match-string 0))
            (message "Make frequently pattern...%s" word)
            (setq migemo-frequent-pattern-alist
                  (cons (cons word (migemo-get-pattern word))
                        migemo-frequent-pattern-alist)))
          (forward-line 1))
        (when (file-writable-p file)
          (setq migemo-frequent-pattern-alist
                (nreverse migemo-frequent-pattern-alist))
          (erase-buffer)
          (if (fboundp 'pp)
              (pp migemo-frequent-pattern-alist (current-buffer))
            (prin1 migemo-frequent-pattern-alist (current-buffer)))
          (write-region (point-min) (point-max) file nil 'nomsg)))
      (migemo-kill)
      (migemo-init)
      (message "Make frequently pattern...done"))))

(defun migemo-expand-pattern () "\
Expand the Romaji sequences on the left side of the cursor
into the migemo's regexp pattern."
       (interactive)
       (let ((pos (point)))
         (goto-char (- pos 1))
         (if (re-search-backward "[^-a-zA-Z]" (line-beginning-position) t)
             (forward-char 1)
           (beginning-of-line))
         (let* ((str (buffer-substring-no-properties (point) pos))
                (jrpat (migemo-get-pattern str)))
           (delete-region (point) pos)
           (insert jrpat))))

(defun migemo-forward (word &optional bound noerror count)
  (interactive "sSearch: \nP\nP")
  (if (delq 'ascii (find-charset-string word))
      (setq migemo-search-pattern word)
    (setq migemo-search-pattern (migemo-search-pattern-get word)))
  (search-forward-regexp migemo-search-pattern bound noerror count))

(defun migemo-backward (word &optional bound noerror count)
  (interactive "sSearch backward: \nP\nP")
  (if (delq 'ascii (find-charset-string word))
      (setq migemo-search-pattern word)
    (setq migemo-search-pattern (migemo-search-pattern-get word)))
  (if (null migemo-do-isearch)
      (search-backward-regexp migemo-search-pattern bound noerror count)
    (or (and (not (eq this-command 'isearch-repeat-backward))
             (not (get-char-property (point) 'invisible (current-buffer)))
             (or (and (looking-at migemo-search-pattern)
                      (match-beginning 0))
                 (and (not (eq (point) (point-min)))
                      (progn (forward-char -1)
                             (and (looking-at migemo-search-pattern)
                                  (match-beginning 0))))))
        (search-backward-regexp migemo-search-pattern bound noerror count))))

;; experimental
;; (define-key global-map "\M-;" 'migemo-dabbrev-expand)
(defcustom migemo-dabbrev-display-message nil
  "*Display dabbrev message to minibuffer."
  :group 'migemo
  :type 'boolean)

(defcustom migemo-dabbrev-ol-face 'highlight
  "*Face of migemo-dabbrev overlay."
  :group 'migemo
  :type 'face)

(defvar migemo-dabbrev-pattern nil)
(defvar migemo-dabbrev-start-point nil)
(defvar migemo-dabbrev-search-point nil)
(defvar migemo-dabbrev-pre-patterns nil)
(defvar migemo-dabbrev-ol nil)
(defun migemo-dabbrev-expand-done ()
  (remove-hook 'pre-command-hook 'migemo-dabbrev-expand-done)
  (unless (eq last-command this-command)
    (setq migemo-search-pattern-alist nil)
    (setq migemo-dabbrev-pre-patterns nil))
  (when migemo-dabbrev-ol
    (delete-overlay migemo-dabbrev-ol)))

(defun migemo-dabbrev-expand ()
  (interactive)
  (let ((end-pos (point))
        matched-start matched-string)
    (if (eq last-command this-command)
        (goto-char migemo-dabbrev-search-point)
      (goto-char (- end-pos 1))
      (if (re-search-backward "[^a-z-]" (line-beginning-position) t)
          (forward-char 1)
        (beginning-of-line))
      (setq migemo-search-pattern-alist nil)
      (setq migemo-dabbrev-start-point (point))
      (setq migemo-dabbrev-search-point (point))
      (setq migemo-dabbrev-pattern
            (buffer-substring-no-properties (point) end-pos))
      (setq migemo-dabbrev-pre-patterns nil))
    (if (catch 'found
          (while (if (> migemo-dabbrev-search-point migemo-dabbrev-start-point)
                     (and (migemo-forward migemo-dabbrev-pattern (point-max) t)
                          (setq migemo-dabbrev-search-point (match-end 0)))
                   (if (migemo-backward migemo-dabbrev-pattern (point-min) t)
                       (setq migemo-dabbrev-search-point (match-beginning 0))
                     (goto-char migemo-dabbrev-start-point)
                     (forward-word 1)
                     (message (format "Trun back for `%s'" migemo-dabbrev-pattern))
                     (and (migemo-forward migemo-dabbrev-pattern (point-max) t)
                          (setq migemo-dabbrev-search-point (match-end 0)))))
            (setq matched-start (match-beginning 0))
            (unless (re-search-forward ".\\>" (line-end-position) t)
              (end-of-line))
            (setq matched-string (buffer-substring-no-properties matched-start (point)))
            (unless (member matched-string migemo-dabbrev-pre-patterns)
              (let ((matched-end (point))
                    (str (copy-sequence matched-string))
                    lstart lend)
                (if (and (pos-visible-in-window-p matched-start)
                         (pos-visible-in-window-p matched-end))
                    (progn
                      (if migemo-dabbrev-ol
                          (move-overlay migemo-dabbrev-ol matched-start (point))
                        (setq migemo-dabbrev-ol (make-overlay matched-start (point))))
                      (overlay-put migemo-dabbrev-ol 'evaporate t)
                      (overlay-put migemo-dabbrev-ol 'face migemo-dabbrev-ol-face))
                  (when migemo-dabbrev-ol
                    (delete-overlay migemo-dabbrev-ol))
                  (when migemo-dabbrev-display-message
                    (save-excursion
                      (save-restriction
                        (goto-char matched-start)
                        (setq lstart (progn (beginning-of-line) (point)))
                        (setq lend (progn (end-of-line) (point)))
                        (setq str (concat "【" str "】"))
                        (message "(%d): %s%s%s"
                                 (count-lines (point-min) matched-start)
                                 (buffer-substring-no-properties lstart matched-start)
                                 str
                                 (buffer-substring-no-properties matched-end lend)))))))
              (throw 'found t))
            (goto-char migemo-dabbrev-search-point)))
        (progn
          (setq migemo-dabbrev-pre-patterns
                (cons matched-string migemo-dabbrev-pre-patterns))
          (delete-region migemo-dabbrev-start-point end-pos)
          (forward-char 1)
          (goto-char migemo-dabbrev-start-point)
          (insert matched-string))
      (goto-char end-pos)
      (message (format "No dynamic expansion for `%s' found"
                       migemo-dabbrev-pattern)))
    (add-hook 'pre-command-hook 'migemo-dabbrev-expand-done)))

(defsubst migemo--isearch-regexp-function ()
  (or (bound-and-true-p isearch-regexp-function)
      (bound-and-true-p isearch-word)))

;; Use migemo-{forward,backward} instead of search-{forward,backward}.
(defadvice isearch-search (around migemo-search-ad activate)
  "Adviced by migemo."
  (when migemo-isearch-enable-p
    (setq migemo-do-isearch t))
  (unwind-protect
      ad-do-it
    (setq migemo-do-isearch nil)))

(defadvice isearch-search-and-update (around migemo-search-ad activate)
  "Adviced by migemo."
  (let ((isearch-adjusted isearch-adjusted))
    (when (and migemo-isearch-enable-p
               (not isearch-forward) (not isearch-regexp) (not (migemo--isearch-regexp-function)))
      ;; don't use 'looking-at'
      (setq isearch-adjusted t))
    ad-do-it))

(defadvice search-forward (around migemo-search-ad activate)
  "Adviced by migemo."
  (if migemo-do-isearch
      (setq ad-return-value
            (migemo-forward (ad-get-arg 0) (ad-get-arg 1) (ad-get-arg 2) (ad-get-arg 3)))
    ad-do-it))

(defadvice search-backward (around migemo-search-ad activate)
  "Adviced by migemo."
  (if migemo-do-isearch
      (setq ad-return-value
            (migemo-backward (ad-get-arg 0) (ad-get-arg 1) (ad-get-arg 2) (ad-get-arg 3)))
    ad-do-it))

(when (and (boundp 'isearch-regexp-lax-whitespace)
           (fboundp 're-search-forward-lax-whitespace)
           (fboundp 'search-forward-lax-whitespace))
  (setq isearch-search-fun-function 'isearch-search-fun-migemo)

  (when (fboundp 'isearch-search-fun-default)
    (defadvice multi-isearch-search-fun (after support-migemo activate)
      (setq ad-return-value
            `(lambda (string bound noerror)
               (cl-letf (((symbol-function 'isearch-search-fun-default)
                          'isearch-search-fun-migemo))
                 (funcall ,ad-return-value string bound noerror))))))

  (defun isearch-search-fun-migemo ()
    "Return default functions to use for the search with migemo."
    (cond
     ((migemo--isearch-regexp-function)
      (lambda (string &optional bound noerror count)
        ;; Use lax versions to not fail at the end of the word while
        ;; the user adds and removes characters in the search string
        ;; (or when using nonincremental word isearch)
        (let* ((state-string-func (if (fboundp 'isearch--state-string)
                                      'isearch--state-string
                                    'isearch-string-state))
               (lax (not (or isearch-nonincremental
                             (eq (length isearch-string)
                                 (length (funcall state-string-func (car isearch-cmds))))))))
          (funcall
           (if isearch-forward #'re-search-forward #'re-search-backward)
           (if (functionp (migemo--isearch-regexp-function))
               (funcall (migemo--isearch-regexp-function) string lax)
             (word-search-regexp string lax))
           bound noerror count))))
     ((and isearch-regexp isearch-regexp-lax-whitespace
           search-whitespace-regexp)
      (if isearch-forward
          're-search-forward-lax-whitespace
        're-search-backward-lax-whitespace))
     (isearch-regexp
      (if isearch-forward 're-search-forward 're-search-backward))
     ((and (if (boundp 'isearch-lax-whitespace) isearch-lax-whitespace t)
           search-whitespace-regexp migemo-do-isearch)
      (if isearch-forward 'migemo-forward 'migemo-backward))
     ((and (if (boundp 'isearch-lax-whitespace) isearch-lax-whitespace t)
           search-whitespace-regexp)
      (if isearch-forward 'search-forward-lax-whitespace
        'search-backward-lax-whitespace))
     (migemo-do-isearch
      (if isearch-forward 'migemo-forward 'migemo-backward))
     (t
      (if isearch-forward 'search-forward 'search-backward))))
  )

;; Turn off input-method automatically when C-s or C-r are typed.
(defadvice isearch-mode (before migemo-search-ad activate)
  "Adviced by migemo."
  (setq migemo-search-pattern nil)
  (setq migemo-search-pattern-alist nil)
  (when (and migemo-isearch-enable-p
             (boundp 'current-input-method))
    (setq migemo-current-input-method current-input-method)
    (setq migemo-current-input-method-title current-input-method-title)
    (setq migemo-input-method-function input-method-function)
    (setq current-input-method nil)
    (setq current-input-method-title nil)
    (setq input-method-function nil)
    (when migemo-current-input-method
      (unwind-protect
          (run-hooks
           'input-method-inactivate-hook
           'input-method-deactivate-hook)
        (force-mode-line-update)))))

(defadvice isearch-done (after migemo-search-ad activate)
  "Adviced by migemo."
  (setq migemo-search-pattern nil)
  (setq migemo-search-pattern-alist nil)
  (when (and migemo-isearch-enable-p
             (boundp 'current-input-method))
    (let ((state-changed-p (not (equal current-input-method migemo-current-input-method))))
      (setq current-input-method migemo-current-input-method)
      (setq current-input-method-title migemo-current-input-method-title)
      (setq input-method-function migemo-input-method-function)
      (when state-changed-p
        (unwind-protect
            (apply #'run-hooks (if current-input-method
                                   '(input-method-activate-hook)
                                 '(input-method-inactivate-hook
                                   input-method-deactivate-hook)))
          (force-mode-line-update))))))

(defcustom migemo-message-prefix-face 'highlight
  "*Face of minibuffer prefix."
  :group 'migemo
  :type 'face)

(defadvice isearch-message-prefix (after migemo-status activate)
  "Adviced by migemo."
  (let ((ret ad-return-value)
        (str "[MIGEMO]"))
    (when (and migemo-isearch-enable-p
               (not (or isearch-regexp (migemo--isearch-regexp-function))))
      (setq ad-return-value (concat str " " ret)))))

;;;; for isearch-lazy-highlight (Emacs 21)
;; Avoid byte compile warningsfor other emacsen
(defvar isearch-lazy-highlight-wrapped)
(defvar isearch-lazy-highlight-start)
(defvar isearch-lazy-highlight-end)

(when (fboundp 'isearch-lazy-highlight-new-loop)
  (defadvice isearch-lazy-highlight-new-loop (around migemo-isearch-lazy-highlight-new-loop
                                                     activate)
    "adviced by migemo"
    (if (and migemo-isearch-enable-p
             (not (migemo--isearch-regexp-function))
             (not isearch-regexp))
        (let ((isearch-string (migemo-search-pattern-get isearch-string))
              (isearch-regexp t))
          ad-do-it)
      ad-do-it)))

(when (fboundp 'replace-highlight)
  (defadvice replace-highlight (around migemo-replace-highlight activate)
    "adviced by migemo"
    (let ((migemo-isearch-enable-p nil))
      ad-do-it)))

;;;; for isearch-highlightify-region (XEmacs 21)
(when (fboundp 'isearch-highlightify-region)
  (defadvice isearch-highlightify-region (around migemo-highlightify-region
                                                 activate)
    "adviced by migemo."
    (if migemo-isearch-enable-p
        (let ((isearch-string (migemo-search-pattern-get isearch-string))
              (isearch-regexp t))
          ad-do-it)
      ad-do-it)))

;; supports C-w C-d for GNU emacs only [migemo:00171]
(when (and (not (featurep 'xemacs))
           (fboundp 'isearch-yank-line))
  (defun migemo-register-isearch-keybinding ()
    (define-key isearch-mode-map "\C-d" 'migemo-isearch-yank-char)
    (define-key isearch-mode-map "\C-w" 'migemo-isearch-yank-word)
    (define-key isearch-mode-map "\C-y" 'migemo-isearch-yank-line)
    (define-key isearch-mode-map "\M-m" 'migemo-isearch-toggle-migemo))

  (setq migemo-register-isearch-keybinding-function 'migemo-register-isearch-keybinding)

  (defun migemo-isearch-toggle-migemo ()
    "Toggle migemo mode in isearch."
    (interactive)
    (unless (or isearch-regexp (migemo--isearch-regexp-function))
      (discard-input)
      (setq migemo-isearch-enable-p (not migemo-isearch-enable-p)))
    (when (fboundp 'isearch-lazy-highlight-new-loop)
      (let ((isearch-lazy-highlight-last-string nil))
        (condition-case nil
            (isearch-lazy-highlight-new-loop)
          (error
           (isearch-lazy-highlight-new-loop nil nil)))))
    (isearch-message))

  (defun migemo-isearch-yank-char ()
    "Pull next character from buffer into search string with migemo."
    (interactive)
    (when (and migemo-isearch-enable-p
               (not isearch-regexp) isearch-other-end)
      (setq isearch-string (buffer-substring-no-properties
                            isearch-other-end (point)))
      (setq isearch-message isearch-string))
    (let ((search-upper-case (unless migemo-isearch-enable-p
                               search-upper-case)))
      (isearch-yank-string
       (save-excursion
         (and (not isearch-forward) isearch-other-end
              (goto-char isearch-other-end))
         (buffer-substring-no-properties (point)
                                         (progn (forward-char 1) (point)))))))

  (defun migemo-isearch-yank-word ()
    "Pull next character from buffer into search string with migemo."
    (interactive)
    (when (and migemo-isearch-enable-p
               (not isearch-regexp) isearch-other-end)
      (setq isearch-string (buffer-substring-no-properties
                            isearch-other-end (point)))
      (setq isearch-message isearch-string))
    (let ((search-upper-case (unless migemo-isearch-enable-p
                               search-upper-case)))
      (isearch-yank-string
       (save-excursion
         (and (not isearch-forward) isearch-other-end
              (goto-char isearch-other-end))
         (buffer-substring-no-properties (point)
                                         (progn (forward-word 1) (point)))))))

  (defun migemo-isearch-yank-line ()
    "Pull next character from buffer into search string with migemo."
    (interactive)
    (when (and migemo-isearch-enable-p
               (not isearch-regexp) isearch-other-end)
      (setq isearch-string (buffer-substring-no-properties
                            isearch-other-end (point)))
      (setq isearch-message isearch-string))
    (let ((search-upper-case (unless migemo-isearch-enable-p
                               search-upper-case)))
      (isearch-yank-string
       (save-excursion
         (and (not isearch-forward) isearch-other-end
              (goto-char isearch-other-end))
         (buffer-substring-no-properties (point)
                                         (line-end-position))))))
  )

(add-hook 'kill-emacs-hook 'migemo-pattern-alist-save)

(provide 'migemo)

;; sample
;; 0123 abcd ABCD ひらがな カタカナ 漢字 !"[#\$]%^&_':`(;)<*=+>,?-@./{|}~

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; migemo.el ends here
