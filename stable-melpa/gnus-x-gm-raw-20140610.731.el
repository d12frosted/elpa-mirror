;;; gnus-x-gm-raw.el --- Search mail of Gmail using X-GM-RAW as web interface

;; Copyright (C) 2014  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: gnus
;; Package-Version: 20140610.731
;; Package-Commit: c2c8c5e94ac94f4c40e023452119c088ac59eac9
;; URL: https://github.com/aki2o/gnus-x-gm-raw
;; Version: 0.0.1
;; Package-Requires: ((log4e "0.2.0") (yaxception "0.1"))

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
;; This extension searches mail of Gmail using X-GM-RAW as web interface.
;; You can use this function naturally in the search by `gnus-group-make-nnir-group'.
;; 
;; For more infomation, see <https://github.com/aki2o/gnus-x-gm-raw/blob/master/README.md>

;;; Dependencies:
;; 
;; - yaxception.el ( see <https://github.com/aki2o/yaxception> )
;; - log4e.el ( see <https://github.com/aki2o/log4e> )

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your .emacs or site-start.el file.
;; 
;; (require 'gnus-x-gm-raw)

;;; Configuration:
;; 
;; Nothing.

;;; Customization:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "gnus-x-gm-raw:" :docstring t)
;; `gnus-x-gm-raw:imap-server'
;; IMAP server of Gmail
;; 
;;  *** END auto-documentation

;;; Tested On:
;; 
;; - Emacs ... GNU Emacs 24.3.1 (i686-pc-linux-gnu, GTK+ Version 3.4.2) of 2014-02-22 on chindi10, modified by Debian
;; - log4e.el ... Version 0.2.0
;; - yaxception.el ... Version 0.1


;; Enjoy!!!


(eval-when-compile (require 'cl))
(require 'gnus)
(require 'nnimap)
(require 'log4e)
(require 'yaxception)


(defgroup gnus-x-gm-raw nil
  "Search mail of Gmail using X-GM-RAW as web interface"
  :group 'gnus
  :prefix "gnus-x-gm-raw:")

(defcustom gnus-x-gm-raw:imap-server "imap.gmail.com"
  "IMAP server of Gmail"
  :type 'string
  :group 'gnus-x-gm-raw)


(log4e:deflogger "gnus-x-gm-raw" "%t [%l] %m" "%H:%M:%S" '((fatal . "fatal")
                                                           (error . "error")
                                                           (warn  . "warn")
                                                           (info  . "info")
                                                           (debug . "debug")
                                                           (trace . "trace")))
(gnus-x-gm-raw--log-set-level 'trace)


(defvar gnus-x-gm-raw::active nil)
(defvar gnus-x-gm-raw::search-command-tmpl "UID SEARCH %s")


(defun gnus-x-gm-raw:active-server-p (server)
  (let ((svraddr (nth 1 (assq 'nnimap-address (gnus-server-to-method server)))))
    (and svraddr
         (string= svraddr gnus-x-gm-raw:imap-server))))

(defsubst gnus-x-gm-raw:convert-type-operator (v)
  (let ((v (upcase v)))
    (cond ((string= v "SUBJECT")    "subject:")
          ((string= v "FROM")       "from:")
          ((string= v "TO")         "to:")
          ((string= v "MESSAGE-ID") "rfc822msgid:")
          ((string= v "BODY")       "")
          ((string= v "TEXT")       ""))))

(defun gnus-x-gm-raw:make-literal (args)
  (let (ope-or ope-not ope-phrase ope-type not-first)
    (mapconcat
     'identity
     (loop for e in (mapcar
                     (lambda (e)
                       (gnus-x-gm-raw--trace "make literal current element : %s" e)
                       (cond ((listp e)
                              (gnus-x-gm-raw--trace "start make nest literal")
                              (format "(%s)" (gnus-x-gm-raw:make-literal e)))
                             ((not (stringp e))
                              nil)
                             ((string-match "\\`\"\\(.+\\)\"\\'" e)
                              (gnus-x-gm-raw--trace "start make search value")
                              (let* ((v (match-string-no-properties 1 e))
                                     (v (if ope-phrase (format "\"%s\"" v) v))
                                     (ret (concat (if (and ope-or not-first) "OR " "")
                                                  ope-type
                                                  (if ope-not (concat "-" v) v))))
                                (setq ope-phrase nil)
                                (setq ope-not nil)
                                (setq ope-type nil)
                                (setq not-first t)
                                ret))
                             ((string= e "OR")
                              (setq ope-or t)
                              (gnus-x-gm-raw--trace "active OR operator"))
                             ((string= e "PHRASE")
                              (setq ope-phrase t)
                              (gnus-x-gm-raw--trace "active PHRASE operator"))
                             ((member e '("NOT" "-"))
                              (setq ope-not t)
                              (gnus-x-gm-raw--trace "active NOT operator"))
                             (t
                              (setq ope-type (gnus-x-gm-raw:convert-type-operator e))
                              (gnus-x-gm-raw--trace "converted type operator : %s" ope-type))))
                     (loop for e in args append (split-string e " +")))
           if (stringp e) collect e)
     " ")))

(defun gnus-x-gm-raw:send-command (args)
    (gnus-x-gm-raw--trace "start send command : %s" args)
    (let* ((literal (gnus-x-gm-raw:make-literal args))
           (llength (string-bytes literal))
           (proc (get-buffer-process (current-buffer)))
           (uid (incf nnimap-sequence))
           (cr (if (nnimap-newlinep nnimap-object) "" "\r"))
           (cmd (format "%s UID SEARCH CHARSET UTF-8 X-GM-RAW {%d}%s\n" uid llength cr))
           (waitf (lambda (re)
                    (yaxception:$
                      (yaxception:try
                        (loop with elre = (format "^%s .*$" uid)
                              with cnt = 0
                              while (< cnt 10)
                              do (goto-char (point-min))
                              if (re-search-forward re nil t)
                              return t
                              else if (re-search-forward elre nil t)
                              return (progn (gnus-x-gm-raw--error "got unintended process finish : %s"
                                                                  (match-string 0))
                                            nil)
                              else
                              do (progn (accept-process-output proc 0.2 nil t)
                                        (incf cnt)
                                        (sleep-for 0.5))
                              finally
                              do (gnus-x-gm-raw--error "timeout wait for response of %s" re)))
                      (yaxception:catch 'quit e
                        (gnus-x-gm-raw--info "received quit signal")
                        (when debug-on-quit (debug "Quit"))
                        (delete-process proc)
                        nil))))
           (coding-system-for-write 'utf-8-unix))
      (gnus-x-gm-raw--trace "send command for %s : %s" (process-buffer proc) cmd)
      (setf (nnimap-last-command-time nnimap-object) (current-time))
      (process-send-string proc cmd)
      (when (funcall waitf "^\\+ go ahead\\s-*$")
        (erase-buffer)
        (gnus-x-gm-raw--trace "send search value : %s" literal)
        (process-send-string proc (concat literal cr "\n"))
        (when (funcall waitf (format "^%s OK SEARCH .*$" uid))
          (gnus-x-gm-raw--trace "got process response")
          (goto-char (point-at-bol))
          (setf (nnimap-initial-resync nnimap-object) 0)
          uid))))


(defadvice nnir-run-imap (around gnus-x-gm-raw:activate activate)
  (let ((gnus-x-gm-raw::active (gnus-x-gm-raw:active-server-p (ad-get-arg 1))))
    ad-do-it))

(defadvice nnir-imap-next-symbol (around gnus-x-gm-raw:fix-phrase activate)
  (lexical-let ((quoted (and gnus-x-gm-raw::active (looking-at "\""))))
    ad-do-it
    (when (and quoted ad-return-value)
      (setq ad-return-value (cons 'phrase ad-return-value)))))

(defadvice nnir-imap-expr-to-imap (around gnus-x-gm-raw:fix-phrase activate)
  (if (and gnus-x-gm-raw::active
           (eq (car-safe (ad-get-arg 1)) 'phrase))
      (setq ad-return-value (format "%s PHRASE %S" (ad-get-arg 0) (cdr (ad-get-arg 1))))
    ad-do-it))

(defadvice nnimap-send-command (around gnus-x-gm-raw:fix-command activate)
  (if (and gnus-x-gm-raw::active
           (string= (ad-get-arg 0) gnus-x-gm-raw::search-command-tmpl))
      (setq ad-return-value (gnus-x-gm-raw:send-command (ad-get-args 1)))
    ad-do-it))


(provide 'gnus-x-gm-raw)
;;; gnus-x-gm-raw.el ends here
