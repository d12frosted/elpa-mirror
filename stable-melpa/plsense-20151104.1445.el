;;; plsense.el --- provide interface for PlSense that is a development tool for Perl.

;; Copyright (C) 2013  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: perl, completion
;; Package-Version: 20151104.1445
;; Package-Commit: d50f9dccc98f42bdb42f1d1c8142246e03879218
;; URL: https://github.com/aki2o/emacs-plsense
;; Version: 0.4.8
;; Package-Requires: ((auto-complete "1.4.0") (log4e "0.2.0") (yaxception "0.2.0"))

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
;; This extension provides interface for PlSense.
;; PlSense is a development tool for Perl.
;; PlSense provides Completion/Help about Module/Function/Variable optimized for context.
;; 
;; For more infomation,
;; see <https://github.com/aki2o/plsense/blob/master/README.md>
;; see <https://github.com/aki2o/emacs-plsense/blob/master/README.md>

;;; Dependency:
;; 
;; - PlSense ( see <https://github.com/aki2o/plsense> )
;; - auto-complete.el ( see <https://github.com/auto-complete/auto-complete> )
;; - yaxception.el ( see <https://github.com/aki2o/yaxception> )
;; - log4e.el ( see <https://github.com/aki2o/log4e> )

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your .emacs or site-start.el file.
;; 
;; (require 'plsense)

;;; Configuration:
;; 
;; ;; Key Binding
;; (setq plsense-popup-help-key "C-:")
;; (setq plsense-display-help-buffer-key "M-:")
;; (setq plsense-jump-to-definition-key "C->")
;; 
;; ;; Make config suit for you. About the config item, see Customization or eval the following sexp.
;; ;; (customize-group "plsense")
;; 
;; (plsense-config-default)

;;; Customization:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "plsense-[^\-]" :docstring t)
;; `plsense-popup-help-key'
;; Keystroke for popup help about something at point.
;; `plsense-display-help-buffer-key'
;; Keystroke for display help buffer about something at point.
;; `plsense-jump-to-definition-key'
;; Keystroke for jump to method definition at point.
;; `plsense-enable-modes'
;; Major modes plsense is enabled on.
;; `plsense-server-start-automatically-p'
;; Whether start server process when execute `plsense-setup-current-buffer'.
;; `plsense-ac-trigger-command-keys'
;; Keystrokes for doing `ac-start' with self insert.
;; `plsense-use-plcmp-candidate'
;; Whether to use the function of perl-completion.el
;; `plsense-plcmp-candidate-foreground-color'
;; Font color of candidate when use perl-completion.el.
;; 
;;  *** END auto-documentation

;;; API:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'command :prefix "plsense-[^\-]" :docstring t)
;; `plsense-setup-current-buffer'
;; Do setup for using plsense in current buffer.
;; `plsense-version'
;; Show PlSense Version.
;; `plsense-server-status'
;; Show status of server process.
;; `plsense-server-start'
;; Start server process.
;; `plsense-server-stop'
;; Stop server process.
;; `plsense-server-refresh'
;; Refresh server process.
;; `plsense-server-task'
;; Show information of active task on server process.
;; `plsense-buffer-is-ready'
;; Show whether or not plsense is available on current buffer.
;; `plsense-popup-help'
;; Popup help about something at point.
;; `plsense-display-help-buffer'
;; Display help buffer about something at point.
;; `plsense-jump-to-definition'
;; Jump to method definition at point.
;; `plsense-delete-help-buffer'
;; Delete help buffers.
;; `plsense-reopen-current-buffer'
;; Re-open current buffer.
;; `plsense-update-location'
;; Update location of plsense process.
;; `plsense-delete-all-cache'
;; Delete all cache data of plsense.
;; `plsense-update-current-buffer'
;; Request updating about contents of current buffer to server process.
;; 
;;  *** END auto-documentation
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'macro :prefix "plsense-[^\-]" :docstring t)
;; `plsense-server-sync-trigger-ize'
;; Define advice to FUNC for informing changes of current buffer to server.
;; 
;;  *** END auto-documentation
;; [Note] Functions and variables other than listed above, Those specifications may be changed without notice.

;;; Tested On:
;; 
;; - PlSense ... version 0.10
;; - Emacs ... GNU Emacs 23.3.1 (i386-mingw-nt5.1.2600) of 2011-08-15 on GNUPACK
;; - auto-complete.el ... Version 1.4.0
;; - yaxception.el ... Version 0.1
;; - log4e.el ... Version 0.2.0


;; Enjoy!!!


(eval-when-compile (require 'cl))
(require 'rx)
(require 'regexp-opt)
(require 'auto-complete)
(require 'eldoc)
(require 'ring)
(require 'etags)
(require 'pos-tip nil t)
(require 'log4e)
(require 'yaxception)

(defgroup plsense nil
  "Auto completion for Perl."
  :group 'completion
  :prefix "plsense-")

(defcustom plsense-popup-help-key nil
  "Keystroke for popup help about something at point."
  :type 'string
  :group 'plsense)

(defcustom plsense-display-help-buffer-key nil
  "Keystroke for display help buffer about something at point."
  :type 'string
  :group 'plsense)

(defcustom plsense-jump-to-definition-key nil
  "Keystroke for jump to method definition at point."
  :type 'string
  :group 'plsense)

(defcustom plsense-enable-modes '(perl-mode cperl-mode)
  "Major modes plsense is enabled on."
  :type '(repeat symbol)
  :group 'plsense)

(defcustom plsense-server-start-automatically-p nil
  "Whether start server process when execute `plsense-setup-current-buffer'."
  :type 'boolean
  :group 'plsense)

(defcustom plsense-ac-trigger-command-keys '("SPC" ">" "$" "@" "%" "&" "{" "[" "(" "/")
  "Keystrokes for doing `ac-start' with self insert."
  :type '(repeat string)
  :group 'plsense)

(defcustom plsense-use-plcmp-candidate t
  "Whether to use the function of perl-completion.el"
  :type 'boolean
  :group 'plsense)

(defcustom plsense-plcmp-candidate-foreground-color "red"
  "Font color of candidate when use perl-completion.el.

If nil, not change color of `ac-candidate-face'/`ac-selection-face'."
  :type 'string
  :group 'plsense)


(log4e:deflogger "plsense" "%t [%l] %m" "%H:%M:%S" '((fatal . "fatal")
                                                     (error . "error")
                                                     (warn  . "warn")
                                                     (info  . "info")
                                                     (debug . "debug")
                                                     (trace . "trace")))
(plsense--log-set-level 'trace)


(defvar plsense--proc nil)
(defvar plsense--server-start-p nil)
(defvar plsense--server-response "")
(defvar plsense--config-path "~/.plsense")
(defvar plsense--current-file "")
(defvar plsense--current-package "")
(defvar plsense--current-method "")
(defvar plsense--ignore-done-response-p nil)
(defvar plsense--help-buffer-name "*plsense help*")

(defvar plsense--current-file-name "")
(make-variable-buffer-local 'plsense--current-file-name)
(defvar plsense--current-ready-status "No")
(make-variable-buffer-local 'plsense--current-ready-status)
(defvar plsense--current-ready-check-timer nil)
(make-variable-buffer-local 'plsense--current-ready-check-timer)

(defvar plsense--last-add-source "")
(make-variable-buffer-local 'plsense--last-add-source)

(defvar plsense--last-assist-start-point 0)
(make-variable-buffer-local 'plsense--last-assist-start-point)
(defvar plsense--last-assist-end-point 0)
(make-variable-buffer-local 'plsense--last-assist-end-point)
(defvar plsense--last-ac-candidates nil)
(make-variable-buffer-local 'plsense--last-ac-candidates)

(defvar plsense--last-eldoc-start-point 0)
(make-variable-buffer-local 'plsense--last-eldoc-start-point)
(defvar plsense--last-eldoc-end-point 0)
(make-variable-buffer-local 'plsense--last-eldoc-end-point)
(defvar plsense--last-eldoc-code "")
(make-variable-buffer-local 'plsense--last-eldoc-code)
(defvar plsense--last-method-information "")
(make-variable-buffer-local 'plsense--last-method-information)

(defvar plsense--regexp-package (rx-to-string `(and bol (* space) "package" (+ space) (group (+ (any "a-zA-Z0-9:_"))) (* space) ";")))
(defvar plsense--regexp-sub (rx-to-string `(and bol (* space) "sub" (+ space) (group (+ (any "a-zA-Z0-9_"))))))
(defvar plsense--regexp-comment (rx-to-string `(and "#" (* not-newline) "\n")))
(defvar plsense--regexp-error (rx-to-string `(and bol (or "ERROR" "FATAL") ":" (+ space) (group (+ not-newline)) "\n")))


;;;;;;;;;;;;;
;; Utility

(defun* plsense--show-message (msg &rest args)
  (apply 'message (concat "[PLSENSE] " msg) args)
  nil)

(defun plsense--active-p ()
  (memq major-mode plsense-enable-modes))

(defun plsense--ready-p ()
  (and plsense--server-start-p
       (string= plsense--current-file-name (buffer-file-name))
       (string= plsense--current-ready-status "Yes")))

(defun plsense--try-to-ready ()
  (when (and (not (plsense--ready-p))
             (not plsense--current-ready-check-timer))
    (plsense--open-buffer (current-buffer))))

(defun plsense--get-source-for-help ()
  (let* ((endpt (save-excursion
                  (or (when (re-search-forward "[^a-zA-Z0-9:_]" nil t)
                        (- (point) 1))
                      (point-max))))
         (startpt (save-excursion
                    (or (when (search-backward ";" nil t)
                          (+ (point) 1))
                        (point-min))))
         (code (buffer-substring-no-properties startpt endpt))
         (code (replace-regexp-in-string plsense--regexp-comment "" code))
         (code (replace-regexp-in-string "\n" "" code)))
    code))

(defun plsense--get-help-buffer (doc)
  (when (and (stringp doc)
             (not (string= doc "")))
    (with-current-buffer (generate-new-buffer plsense--help-buffer-name)
      (insert doc)
      (goto-char (point-min))
      (view-mode-enter)
      (current-buffer))))


;;;;;;;;;;;;;;;;;;;;;
;; PlSense Process

(defsubst plsense--server-response-finished-p ()
  (when (and plsense--ignore-done-response-p
             (string-match "\\`Done\n>\\s-\\'" plsense--server-response))
    (plsense--trace "Ignored done response of server")
    (setq plsense--server-response ""))
  (string-match "\n?>\\s-\\'" plsense--server-response))

(defun plsense--get-process ()
  (or (and (processp plsense--proc)
           (eq (process-status (process-name plsense--proc)) 'run)
           plsense--proc)
      (plsense--start-process)))

(defun plsense--exist-process ()
  (and (processp plsense--proc)
       (process-status (process-name plsense--proc))
       t))

(defun plsense--start-process ()
  (if (not (file-exists-p plsense--config-path))
      (error "[PlSense] Not exist '%s'. do 'plsense' on shell." (expand-file-name plsense--config-path))
    (plsense--info "Start plsense process.")
    (when (plsense--exist-process)
      (kill-process plsense--proc)
      (sleep-for 1))
    (setq plsense--ignore-done-response-p nil)
    (setq plsense--server-response "")
    (let ((proc (start-process-shell-command "plsense" nil "plsense --interactive"))
          (waiti 0))
      (set-process-filter proc 'plsense--receive-server-response)
      (process-query-on-exit-flag proc)
      (while (and (< waiti 50)
                  (not (plsense--server-response-finished-p)))
        (accept-process-output proc 0.2 nil t)
        (incf waiti))
      (plsense--info "Finished start plsense process.")
      (setq plsense--proc proc))))

(defun plsense--stop-process ()
  (when (plsense--exist-process)
    (process-send-string plsense--proc "exit\n")))

(defun plsense--receive-server-response (proc res)
  (plsense--trace "Received server response.\n%s" res)
  (yaxception:$
    (yaxception:try
      (when (stringp res)
        (cond ((string-match plsense--regexp-error res)
               (plsense--handle-err-response (match-string-no-properties 1 res)))
              (t
               (setq plsense--server-response (concat plsense--server-response res))))))
    (yaxception:catch 'error e
      (plsense--error "failed receive server response : %s\n%s"
                      (yaxception:get-text e)
                      (yaxception:get-stack-trace-string e)))))

(defun* plsense--handle-err-response (res &key inform-compile-error)
  (cond ((string-match "\\`Not yet exist \\[[a-zA-Z0-9:_]+\\] of \\[\\(.+\\)\\]" res)
         (plsense--show-message "Please exec 'plsense-reopen-current-buffer' on '%s'" (match-string-no-properties 1 res))
         (sleep-for 1))
        ((string-match "\\`Not found \\[[a-zA-Z0-9_]+\\] in \\[[a-zA-Z0-9:_]+\\] of \\[\\(.+\\)\\]" res)
         (plsense--show-message "Please exec 'plsense-reopen-current-buffer' on '%s'" (match-string-no-properties 1 res))
         (sleep-for 1))
        ((string= "Not yet set current file/module by onfile/onmod command" res)
         (plsense--show-message "Please exec 'plsense-reopen-current-buffer' on '%s'" (buffer-name))
         (sleep-for 1))
        ((string-match "\\`Check the module status" res)
         nil)
        ((and (string-match "\\`Failed compile" res)
              (not inform-compile-error))
         nil)
        (t
         (plsense--show-message res)
         (sleep-for 1))))


;;;;;;;;;;;;;;;;;;;
;; Access Server

(defun* plsense--request-server (cmdstr &key waitsec force)
  (when (or force (plsense--ready-p))
    (plsense--debug "Start request server. cmdstr[%s] waitsec[%s]" cmdstr waitsec)
    (cond (waitsec
           ;; with sync
           (let ((res (plsense--get-server-response cmdstr :waitsec waitsec :force force)))
             (and (string-match "^Done$" res)
                  (not (string-match "^Failed$" res))
                  t)))
          (t
           ;; with async
           (process-send-string (plsense--get-process) (concat cmdstr "\n"))
           t))))

(defun* plsense--get-server-response (cmdstr &key waitsec force ignore-done)
  (if (and (not force)
           (not (plsense--ready-p)))
      ""
    (plsense--debug "Start get server response. cmdstr[%s] waitsec[%s]" cmdstr waitsec)
    (let ((proc (plsense--get-process))
          (waiti 0)
          (maxwaiti (* (or waitsec 1) 5)))
      (setq plsense--ignore-done-response-p ignore-done)
      (setq plsense--server-response "")
      (process-send-string proc (concat cmdstr "\n"))
      (plsense--trace "Start wait response from server.")
      (while (and (< waiti maxwaiti)
                  (not (plsense--server-response-finished-p)))
        (accept-process-output proc 0.2 nil t)
        (incf waiti))
      (cond ((not (< waiti maxwaiti))
             (plsense--warn "Timeout get response of %s" cmdstr)
             plsense--server-response)
            (t
             (plsense--trace "Got response from server.")
             (replace-match "" nil nil plsense--server-response))))))


;;;;;;;;;;;;;;;;;;;;
;; Manage PlSense

(defun plsense--open-buffer (buff)
  (let ((fpath (buffer-file-name buff)))
    (when (and (file-exists-p fpath)
               (not (file-directory-p fpath))
               plsense--server-start-p
               (plsense--request-server (concat "open " (expand-file-name fpath)) :waitsec 10 :force t))
      (plsense--info "Open %s is done." fpath)
      (plsense--show-message "Now loading '%s' ..." (buffer-name))
      (sleep-for 1)
      (setq plsense--current-file fpath)
      (setq plsense--current-package "main")
      (setq plsense--current-method "")
      (setq plsense--current-ready-status "Now Loading")
      (plsense--run-ready-check-timer))))

(defun plsense--update-buffer (buff)
  (let* ((fpath (buffer-file-name buff)))
    (when (and (file-exists-p fpath)
               (not (file-directory-p fpath))
               plsense--server-start-p)
      (plsense--request-server (concat "update " (expand-file-name fpath)) :force t))))

(defun plsense--add-pointed-source ()
  (save-excursion
    (yaxception:$
      (yaxception:try
        (plsense--try-to-ready)
        (when (plsense--ready-p)
          (let* ((currpt (point))
                 (startpt (or (when (re-search-backward plsense--regexp-sub nil t)
                                (point))
                              (when (re-search-backward plsense--regexp-package nil t)
                                (point))
                              (point-min)))
                 (code (buffer-substring-no-properties startpt currpt))
                 (code (replace-regexp-in-string plsense--regexp-comment "" code))
                 (code (replace-regexp-in-string "\n" "" code)))
            (when (not (string= code plsense--last-add-source))
              (setq plsense--last-add-source code)
              (plsense--trace "Start add source : %s" code)
              (when (and (plsense--set-current-file)
                         (plsense--set-current-package)
                         (plsense--set-current-method))
                (plsense--request-server (concat "codeadd " code)))))))
      (yaxception:catch 'error e
        (plsense--error "failed add pointed source : %s\n%s"
                        (yaxception:get-text e)
                        (yaxception:get-stack-trace-string e))))))

(defun plsense--set-current-file (&optional wait force)
  (let ((fpath (buffer-file-name)))
    (cond ((and (file-exists-p fpath)
                (not (file-directory-p fpath))
                (or force
                    (not (string= fpath plsense--current-file))))
           (cond ((plsense--request-server (concat "onfile " fpath) :waitsec (and wait 1))
                  (setq plsense--current-file fpath)
                  t)
                 (t
                  (plsense--show-message "Failed set current file for '%s'" fpath)
                  nil)))
          (t
           t))))

(defun plsense--set-current-package (&optional wait force)
  (let ((pkg (plsense--get-current-package)))
    (if (and (not force)
             (string= pkg plsense--current-package))
        t
      (cond ((plsense--request-server (concat "onmod " pkg) :waitsec (and wait 1))
             (setq plsense--current-package pkg)
             t)
            (t
             (plsense--show-message "Failed set current package for '%s'" pkg)
             nil)))))

(defun plsense--get-current-package ()
  (save-excursion
    ;; Current may be start line of package definition.
    (goto-char (point-at-eol))
    (or (when (re-search-backward plsense--regexp-package nil t)
          (match-string-no-properties 1))
        "main")))

(defun plsense--set-current-method (&optional wait force)
  (let ((mtd (or (plsense--get-current-method)
                 "")))
    (if (and (not force)
             (string= mtd plsense--current-method))
        t
      (cond ((plsense--request-server (concat "onsub " mtd) :waitsec (and wait 1))
             (setq plsense--current-method mtd)
             t)
            (t
             (plsense--show-message "Failed set current method for '%s'" mtd)
             nil)))))

(defun plsense--get-current-method ()
  (save-excursion
    ;; Current may be start line of method definition.
    (goto-char (point-at-eol))
    ;; Current may be last line of method definition.
    (when (string= (format "%c" (char-before)) "}")
      (forward-char -1))
    (let* ((startpt (point))
           (subnm (when (re-search-backward plsense--regexp-sub nil t)
                    (match-string-no-properties 1)))
           (subsrc (when subnm
                     (buffer-substring-no-properties (point) startpt)))
           (subsrc (when subsrc
                     (replace-regexp-in-string plsense--regexp-comment "" subsrc)))
           (openbraces (when subsrc
                         (- (length subsrc)
                            (length (replace-regexp-in-string "{" "" subsrc)))))
           (closebraces (when subsrc
                          (- (length subsrc)
                             (length (replace-regexp-in-string "}" "" subsrc))))))
      (when (and subnm
                 subsrc
                 (> openbraces closebraces))
        subnm))))


;;;;;;;;;;;;;;;;;
;; Check Ready

(defun plsense--run-ready-check-timer ()
  (let ((fpath (buffer-file-name))
        (procnm (plsense--get-ready-check-process_name (buffer-name))))
    (when (and (file-exists-p fpath)
               (not (file-directory-p fpath))
               (plsense--active-p)
               (not (plsense--ready-p)))
      (plsense--debug "Set timer to check ready for %s" fpath)
      (when (process-status procnm)
        (kill-process procnm))
      (plsense--cancel-check-ready)
      (setq plsense--current-ready-check-timer
            (run-with-timer 5 5 'plsense--start-check-ready (buffer-name))))))

(defun plsense--get-ready-check-process_name (buffnm)
  (format "plsense-ready-%s" buffnm))

(defun plsense--start-check-ready (buffnm)
  (let* ((buff (get-buffer buffnm))
         (fpath (when (buffer-live-p buff)
                  (buffer-file-name buff)))
         (procnm (plsense--get-ready-check-process_name buffnm)))
    (when (buffer-live-p buff)
      (with-current-buffer buff
        (if (or (not (file-exists-p fpath))
                (file-directory-p fpath)
                (not (plsense--active-p))
                (not plsense--server-start-p)
                (plsense--ready-p))
            (plsense--cancel-check-ready)
          (when (not (eq (process-status procnm) 'run))
            (plsense--trace "Start check ready of %s" buffnm)
            (when (process-status procnm)
              (kill-process procnm))
            (let ((proc (start-process-shell-command procnm
                                                     nil
                                                     (format "plsense ready \"%s\"" (expand-file-name fpath)))))
              (set-process-filter proc 'plsense--receive-check-ready-result)
              (process-query-on-exit-flag proc))))))))

(defun plsense--cancel-check-ready ()
  (when plsense--current-ready-check-timer
    (cancel-timer plsense--current-ready-check-timer)
    (setq plsense--current-ready-check-timer nil)))

(defun plsense--receive-check-ready-result (proc res)
  (let* ((buffnm (replace-regexp-in-string "^plsense-ready-" "" (process-name proc)))
         (buff (get-buffer buffnm)))
    (when (buffer-live-p buff)
      (with-current-buffer buff
        (setq plsense--current-file-name (buffer-file-name))
        (when (stringp res)
          (cond ((string-match plsense--regexp-error res)
                 (plsense--handle-err-response (match-string-no-properties 1 res)))
                (t
                 (setq plsense--current-ready-status (replace-regexp-in-string "\n" "" res)))))
        (when (or (plsense--ready-p)
                  (not plsense--server-start-p))
          (when (plsense--ready-p)
            (plsense--info "%s is ready." (buffer-name))
            (plsense--show-message "'%s' is ready." (buffer-name))
            (sleep-for 2))
          (plsense--cancel-check-ready))))))


;;;;;;;;;;;;;;;;;;;
;; Auto Complete

(defvar ac-source-plsense-include
  '((candidates . plsense--get-ac-candidates)
    (prefix . "\\(?:use\\|require\\) +\\([a-zA-Z0-9_:]+\\)")
    (symbol . "p")
    (document . plsense--get-ac-document)
    (requires . 1)
    (cache)
    (limit . 500)))

(defvar ac-source-plsense-variable
  '((candidates . plsense--get-ac-candidates)
    (prefix . "\\(?:\\$\\|@\\|%\\|\\$#\\)\\([a-zA-Z0-9_:]*\\)")
    (symbol . "v")
    (document . plsense--get-ac-document)
    (requires . 0)
    (cache)
    (limit . 500)))

(defvar ac-source-plsense-sub
  '((candidates . plsense--get-ac-candidates)
    (prefix . "&\\([a-zA-Z0-9_:]+\\)")
    (symbol . "s")
    (document . plsense--get-ac-document)
    (requires . 0)
    (cache)
    (limit . 500)))

(defvar ac-source-plsense-arrow
  '((candidates . plsense--get-ac-candidates)
    (prefix . "->\\([a-zA-Z0-9_]*\\)")
    (symbol . "m")
    (document . plsense--get-ac-document)
    (requires . 0)
    (cache)
    (limit . 200)))

(defvar ac-source-plsense-hash-member
  '((candidates . plsense--get-ac-candidates)
    (prefix . "\\(?:->\\|[a-zA-Z0-9_]\\|\\]\\){\\s-*\\([a-zA-Z0-9_-]*\\)")
    (symbol . "h")
    (document . plsense--get-ac-document)
    (requires . 0)
    (cache)
    (limit . 200)))

(defvar ac-source-plsense-constructor
  '((candidates . plsense--get-ac-candidates)
    (prefix . "\\(?:=>\\|=\\|(\\)\\s-*{\\s-*\\([a-zA-Z0-9_-]*\\)")
    (symbol . "c")
    (document . plsense--get-ac-document)
    (requires . 0)
    (cache)
    (limit . 200)))

(defvar ac-source-plsense-quoted
  '((candidates . plsense--get-ac-candidates)
    (prefix . "qw\\(?:/\\|{\\|\\[\\|(\\|!\\||\\)\\(.*\\)")
    (symbol . "q")
    (document . plsense--get-ac-document)
    (requires . 0)
    (cache)
    (limit . 200)))

(defvar ac-source-plsense-list-element
  '((candidates . plsense--get-ac-candidates)
    (prefix . ",\\s-+\\([a-zA-Z0-9_-]*\\)")
    (symbol . "e")
    (document . plsense--get-ac-document)
    (requires . 0)
    (cache)
    (limit . 200)))

(defvar ac-source-plsense-word
  '((candidates . plsense--get-ac-candidates)
    (prefix . "\\(?:\\s-\\|^\\|;\\|,\\|}\\|\\[\\|(\\|\"\\|'\\)\\s-*\\([a-zA-Z0-9_:]+\\)")
    (symbol . "w")
    (document . plsense--get-ac-document)
    (requires . 1)
    (cache)
    (limit . 200)))

(defun plsense--insert-with-ac-trigger-command (n)
  (interactive "p")
  (self-insert-command n)
  (auto-complete-1 :triggered 'trigger-key))

(defun plsense--get-ac-candidates ()
  (yaxception:$
    (yaxception:try
      (plsense--try-to-ready)
      (when (plsense--ready-p)
        (let* ((currpt (point))
               (startpt (or (save-excursion
                              (when (search-backward ";" nil t)
                                (+ (point) 1)))
                            (point-min)))
               (code (buffer-substring-no-properties startpt currpt))
               (code (replace-regexp-in-string plsense--regexp-comment "" code))
               (code (replace-regexp-in-string "\n" "" code)))
          (if (and (= startpt plsense--last-assist-start-point)
                   (> currpt plsense--last-assist-end-point)
                   (string-match "\\`[a-zA-Z0-9_-]*\\'"
                                 (buffer-substring-no-properties plsense--last-assist-end-point
                                                                 currpt)))
              plsense--last-ac-candidates
            (plsense--trace "Start get ac candidates : %s" code)
            (setq plsense--last-assist-start-point startpt)
            (setq plsense--last-assist-end-point currpt)
            (setq plsense--last-ac-candidates
                  (or (when (and (plsense--set-current-file)
                                 (plsense--set-current-package)
                                 (plsense--set-current-method))
                        (let* ((ret (plsense--get-server-response (concat "assist " code) :waitsec 2 :ignore-done t))
                               (ret (replace-regexp-in-string " " "" ret)))
                          (loop for e in (split-string ret "\n")
                                if (not (string= e ""))
                                collect e)))
                      (when (and plsense-use-plcmp-candidate
                                 (functionp 'plcmp-ac-candidates))
                        (yaxception:$
                          (yaxception:try
                            (if (< (length ac-prefix) ac-auto-start)
                                (progn (setq plsense--last-assist-start-point 0)
                                       nil)
                              (if plsense-plcmp-candidate-foreground-color
                                  (loop for cand in (plcmp-ac-candidates)
                                        collect (propertize cand
                                                            'face
                                                            `((t (:foreground ,plsense-plcmp-candidate-foreground-color)))))
                                (plcmp-ac-candidates))))))))))))
    (yaxception:catch 'error e
      (plsense--show-message (yaxception:get-text e))
      (plsense--error "failed get ac candidates : %s\n%s"
                      (yaxception:get-text e)
                      (yaxception:get-stack-trace-string e))
      nil)))

(defun plsense--get-ac-document (selected)
  (yaxception:$
    (yaxception:try
      (if (not (stringp selected))
          ""
        ;; ref #10
        ;; (set-text-properties 0 (string-width selected) nil selected)
        (plsense--trace "Start get ac document : %s" selected)
        (let ((doc (plsense--get-server-response (concat "assisthelp " selected) :waitsec 2 :ignore-done t)))
          (when doc
            (with-temp-buffer
              (let ((standard-output (current-buffer)))
                (princ doc)
                (buffer-string)))))))
    (yaxception:catch 'error e
      (plsense--show-message (yaxception:get-text e))
      (plsense--error "failed get ac document : %s\n%s"
                      (yaxception:get-text e)
                      (yaxception:get-stack-trace-string e))
      "")))


;;;;;;;;;;;
;; ElDoc

(defun plsense--echo-method-usage ()
  (yaxception:$
    (yaxception:try
      (plsense--try-to-ready)
      (when (plsense--ready-p)
        (save-excursion
          (let* ((currpt (point))
                 (bracept (loop with depth = 1
                                for bspt = (save-excursion (or (when (search-backward "(" nil t) (point))
                                                               (point-min)))
                                for bept = (save-excursion (or (when (search-backward ")" nil t) (point))
                                                               (point-min)))
                                while (> (point) (point-min))
                                do (cond ((> bspt bept) (decf depth) (goto-char bspt))
                                         (t             (incf depth) (goto-char bept)))
                                if (= depth 0) return (point)
                                finally return (point-min)))
                 (startpt (or (when (search-backward ";" nil t) (+ (point) 1))
                              (point-min)))
                 (arg-text (buffer-substring-no-properties bracept currpt))
                 (arg-text (replace-regexp-in-string "([^(]*)" "" arg-text))
                 (curridx (length (split-string arg-text ",")))
                 (code (or (when (< startpt bracept) (buffer-substring-no-properties startpt bracept))
                           ""))
                 (code (replace-regexp-in-string plsense--regexp-comment "" code))
                 (code (replace-regexp-in-string "\n" "" code))
                 (subinfo (cond ((and (= startpt plsense--last-eldoc-start-point)
                                      (= bracept plsense--last-eldoc-end-point)
                                      (string= code plsense--last-eldoc-code))
                                 plsense--last-method-information)
                                ((string-match "[^\\s-]" code)
                                 (setq plsense--last-method-information
                                       (or (when (and (plsense--set-current-file)
                                                      (plsense--set-current-package)
                                                      (plsense--set-current-method))
                                             (setq plsense--last-eldoc-start-point startpt)
                                             (setq plsense--last-eldoc-end-point bracept)
                                             (setq plsense--last-eldoc-code code)
                                             (plsense--get-server-response (concat "subinfo " code) :ignore-done t))
                                           "")))
                                (t
                                 "")))
                 (mtdnm "Unknown")
                 (args)
                 (retinfo "Unknown"))
            (when (not (string= subinfo ""))
              (loop for line in (split-string subinfo "\n")
                    if (string-match "^NAME: \\([^\n]+\\)" line)
                    do (setq mtdnm (match-string-no-properties 1 line))
                    if (string-match "^ARG[1-9]: \\([^\n]+\\)" line)
                    do (push (match-string-no-properties 1 line) args)
                    if (string-match "^RETURN: \\([^\n]+\\)" line)
                    do (setq retinfo (match-string-no-properties 1 line)))
              (princ (concat (propertize mtdnm 'face 'font-lock-function-name-face)
                             " ("
                             (loop with i = 1
                                   with ret = ""
                                   for arg in (reverse args)
                                   if (> i 1)
                                   do (setq ret (concat ret ", "))
                                   if (= i curridx)
                                   do (setq ret (concat ret (propertize arg 'face 'bold)))
                                   else
                                   do (setq ret (concat ret arg))
                                   do (incf i)
                                   finally return ret)
                             ") "
                             retinfo)))))))
    (yaxception:catch 'error e
      (plsense--show-message (yaxception:get-text e))
      (plsense--error "failed echo method usage : %s\n%s"
                      (yaxception:get-text e)
                      (yaxception:get-stack-trace-string e)))))


;;;;;;;;;;;;;;;
;; For Setup

;;;###autoload
(defun plsense-setup-current-buffer ()
  "Do setup for using plsense in current buffer."
  (interactive)
  (yaxception:$
    (yaxception:try
      (when (plsense--active-p)
        ;; Key binding
        (loop for stroke in plsense-ac-trigger-command-keys
              if (not (string= stroke ""))
              do (local-set-key (read-kbd-macro stroke) 'plsense--insert-with-ac-trigger-command))
        (when (and (stringp plsense-popup-help-key)
                   (not (string= plsense-popup-help-key "")))
          (local-set-key (read-kbd-macro plsense-popup-help-key) 'plsense-popup-help))
        (when (and (stringp plsense-display-help-buffer-key)
                   (not (string= plsense-display-help-buffer-key "")))
          (local-set-key (read-kbd-macro plsense-display-help-buffer-key) 'plsense-display-help-buffer))
        (when (and (stringp plsense-jump-to-definition-key)
                   (not (string= plsense-jump-to-definition-key "")))
          (local-set-key (read-kbd-macro plsense-jump-to-definition-key) 'plsense-jump-to-definition))
        ;; For auto-complete
        (add-to-list 'ac-sources 'ac-source-plsense-include)
        (add-to-list 'ac-sources 'ac-source-plsense-variable)
        (add-to-list 'ac-sources 'ac-source-plsense-sub)
        (add-to-list 'ac-sources 'ac-source-plsense-arrow)
        (add-to-list 'ac-sources 'ac-source-plsense-hash-member)
        (add-to-list 'ac-sources 'ac-source-plsense-constructor)
        (add-to-list 'ac-sources 'ac-source-plsense-quoted)
        (add-to-list 'ac-sources 'ac-source-plsense-list-element)
        (add-to-list 'ac-sources 'ac-source-plsense-word)
        (auto-complete-mode t)
        ;; For eldoc
        (set (make-local-variable 'eldoc-documentation-function) 'plsense--echo-method-usage)
        (turn-on-eldoc-mode)
        ;; For perl-completion
        (yaxception:$
          (yaxception:try
            (when (and plsense-use-plcmp-candidate
                       (or (featurep 'perl-completion)
                           (require 'perl-completion nil t)))
              (perl-completion-mode t))))
        ;; Other
        (when (and (not plsense--server-start-p)
                   plsense-server-start-automatically-p)
          (plsense-server-start))
        (plsense--try-to-ready)
        (plsense--info "finished setup for %s" (current-buffer))))
    (yaxception:catch 'error e
      (plsense--show-message "Failed setup : %s" (yaxception:get-text e))
      (plsense--error "failed setup : %s\n%s"
                      (yaxception:get-text e)
                      (yaxception:get-stack-trace-string e)))))


;;;###autoload
(defmacro plsense-server-sync-trigger-ize (func)
  "Define advice to FUNC for informing changes of current buffer to server.

FUNC is symbol not quoted. e.g. (plsense-server-sync-trigger-ize newline)"
  `(when (functionp ',func)
     (defadvice ,func (after plsense-add-source activate)
       (when (plsense--active-p)
         (plsense--add-pointed-source)))))


;;;###autoload
(defun plsense-config-default ()
  "Do setting recommemded configuration."
  ;; Activate auto-complete and setup plsense automatically when open plsense-enable-modes buffer.
  (loop for mode in plsense-enable-modes
        for hook = (intern-soft (concat (symbol-name mode) "-hook"))
        do (add-to-list 'ac-modes mode)
        if (and hook
                (symbolp hook))
        do (add-hook hook 'plsense-setup-current-buffer t))
  ;; Request updating contents of current buffer to server automatically when save buffer.
  (add-hook 'after-save-hook 'plsense-update-current-buffer t)
  ;; Define advice for informing changes of current buffer to server
  (plsense-server-sync-trigger-ize newline)
  (plsense-server-sync-trigger-ize newline-and-indent)
  (plsense-server-sync-trigger-ize yank)
  (plsense-server-sync-trigger-ize yas/commit-snippet))


;;;;;;;;;;;;;;;;;;
;; User Command

;;;###autoload
(defun plsense-version ()
  "Show PlSense Version."
  (interactive)
  (message (shell-command-to-string "plsense --version")))

;;;###autoload
(defun plsense-server-status ()
  "Show status of server process."
  (interactive)
  (message (plsense--get-server-response "serverstatus" :waitsec 30 :force t :ignore-done t)))

;;;###autoload
(defun plsense-server-start ()
  "Start server process."
  (interactive)
  (plsense--show-message "Start server ...")
  (if (not (plsense--request-server "serverstart" :waitsec 60 :force t))
      (plsense--show-message "Start server is failed.")
    (setq plsense--server-start-p t)
    (plsense--info "Start server is done.")
    (plsense--show-message "Start server is done."))
  (sleep-for 1))

;;;###autoload
(defun plsense-server-stop ()
  "Stop server process."
  (interactive)
  (setq plsense--server-start-p nil)
  (if (not (plsense--request-server "serverstop" :waitsec 60 :force t))
      (plsense--show-message "Stop server is failed.")
    (plsense--info "Stop server is done.")
    (plsense--stop-process)
    (plsense--show-message "Stop server is done."))
  (sleep-for 1))

;;;###autoload
(defun plsense-server-refresh ()
  "Refresh server process."
  (interactive)
  (if (not (plsense--request-server "refresh" :waitsec 60 :force t))
      (plsense--show-message "Refresh is failed.")
    (plsense--info "Referesh server is done.")
    (plsense--show-message "Refresh is done."))
  (sleep-for 1))

;;;###autoload
(defun plsense-server-task ()
  "Show information of active task on server process."
  (interactive)
  (let ((ret (plsense--get-server-response "ps" :waitsec 10 :force t :ignore-done t)))
    (if (string= ret "")
        (plsense--show-message "no task now.")
      (message ret))))

;;;###autoload
(defun plsense-buffer-is-ready ()
  "Show whether or not plsense is available on current buffer."
  (interactive)
  (message plsense--current-ready-status))

;;;###autoload
(defun plsense-popup-help ()
  "Popup help about something at point."
  (interactive)
  (yaxception:$
    (yaxception:try
      (plsense--try-to-ready)
      (when (and (plsense--ready-p)
                 (plsense--set-current-file)
                 (plsense--set-current-package)
                 (plsense--set-current-method))
        (let* ((code (plsense--get-source-for-help))
               (doc (plsense--get-server-response (concat "codehelp " code) :waitsec 2 :ignore-done t)))
          (cond ((string= doc "")
                 (plsense--show-message "Can't identify anything at point."))
                ((and (functionp 'ac-quick-help-use-pos-tip-p)
                      (ac-quick-help-use-pos-tip-p))
                 (pos-tip-show doc 'popup-tip-face nil nil 300 popup-tip-max-width))
                (t
                 (popup-tip doc))))))
    (yaxception:catch 'error e
      (plsense--show-message (yaxception:get-text e))
      (plsense--error "failed popup help : %s\n%s"
                      (yaxception:get-text e)
                      (yaxception:get-stack-trace-string e)))))

;;;###autoload
(defun plsense-display-help-buffer ()
  "Display help buffer about something at point."
  (interactive)
  (yaxception:$
    (yaxception:try
      (plsense--try-to-ready)
      (when (and (plsense--ready-p)
                 (plsense--set-current-file)
                 (plsense--set-current-package)
                 (plsense--set-current-method))
        (let* ((code (plsense--get-source-for-help))
               (doc (plsense--get-server-response (concat "codehelp " code) :waitsec 4 :ignore-done t))
               (buff (plsense--get-help-buffer doc)))
          (when (buffer-live-p buff)
            (display-buffer buff)))))
    (yaxception:catch 'error e
      (plsense--show-message (yaxception:get-text e))
      (plsense--error "failed display help buffer : %s\n%s"
                      (yaxception:get-text e)
                      (yaxception:get-stack-trace-string e)))))

;;;###autoload
(defun plsense-jump-to-definition ()
  "Jump to method definition at point."
  (interactive)
  (yaxception:$
    (yaxception:try
      (plsense--try-to-ready)
      (when (and (plsense--ready-p)
                 (plsense--set-current-file)
                 (plsense--set-current-package)
                 (plsense--set-current-method))
        (let* ((code (plsense--get-source-for-help))
               (subinfo (plsense--get-server-response (concat "subinfo " code) :waitsec 4 :ignore-done t))
               (fpath (when (string-match "^FILE: \\([^\n]+\\)" subinfo)
                        (match-string-no-properties 1 subinfo)))
               (row (or (when (string-match "^LINE: \\([0-9]+\\)" subinfo)
                          (string-to-number (match-string-no-properties 1 subinfo)))
                        0))
               (col (or (when (string-match "^COL: \\([0-9]+\\)" subinfo)
                          (string-to-number (match-string-no-properties 1 subinfo)))
                        0)))
          (if (or (not fpath)
                  (not (file-exists-p fpath))
                  (= row 0)
                  (= col 0))
              (progn (plsense--show-message "Not found definition location at point.")
                     (plsense--trace "Not found location file[%s] row[%s] col[%s]" fpath row col))
            (ring-insert find-tag-marker-ring (point-marker))
            (find-file fpath)
            (goto-char (point-min))
            (forward-line (- row 1))
            (forward-char (- col 1))))))
    (yaxception:catch 'error e
      (plsense--show-message (yaxception:get-text e))
      (plsense--error "failed jump to definition : %s\n%s"
                      (yaxception:get-text e)
                      (yaxception:get-stack-trace-string e)))))

;;;###autoload
(defun plsense-delete-help-buffer ()
  "Delete help buffers."
  (interactive)
  (loop for buff in (buffer-list)
        if (and (buffer-live-p buff)
                (string-match "\\`\\*plsense help\\*" (buffer-name buff)))
        do (kill-buffer buff)))

;;;###autoload
(defun plsense-reopen-current-buffer ()
  "Re-open current buffer."
  (interactive)
  (setq plsense--current-ready-status "No")
  (plsense--open-buffer (current-buffer)))

;;;###autoload
(defun plsense-update-location ()
  "Update location of plsense process."
  (interactive)
  (let ((ret (cond ((and (plsense--set-current-file t t)
                         (plsense--set-current-package t t)
                         (plsense--set-current-method t t))
                    "done")
                   (t
                    "failed"))))
    (plsense--show-message "Update location is %s." ret)))

;;;###autoload
(defun plsense-delete-all-cache ()
  "Delete all cache data of plsense."
  (interactive)
  (if (not (plsense--request-server "removeall" :waitsec 120))
      (plsense--show-message "Delete all cache is failed.")
    (plsense--info "Delete all cashe is done.")
    (plsense--show-message "Delete all cache is done."))
  (sleep-for 1))

;;;###autoload
(defun plsense-update-current-buffer ()
  "Request updating about contents of current buffer to server process."
  (interactive)
  (when (plsense--active-p)
    (plsense--update-buffer (current-buffer))))


(provide 'plsense)
;;; plsense.el ends here
