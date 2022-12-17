;;; auto-complete-pcmp.el --- Provide auto-complete sources using pcomplete results

;; Copyright (C) 2014  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: completion
;; Package-Version: 20140303.255
;; Package-Commit: 2595d3dab1ef3549271ca922f212928e9d830eec
;; URL: https://github.com/aki2o/auto-complete-pcmp
;; Package-Requires: ((auto-complete "1.4.0") (log4e "0.2.0") (yaxception "0.1"))
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
;; This extension provides the functions of auto-complete for handling Programmable Completion.
;; You can define the source of auto-complete.el by using them for handling pcomplete.
;; For more information, see <https://github.com/aki2o/auto-complete-pcmp/blob/master/README.org>

;;; Dependency:
;; 
;; - auto-complete.el ( see <https://github.com/auto-complete/auto-complete> )
;; - yaxception.el ( see <https://github.com/aki2o/yaxception> )
;; - log4e.el ( see <https://github.com/aki2o/log4e> )

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your .emacs or site-start.el file.
;; 
;; (require 'auto-complete-pcmp)

;;; API:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'command :prefix "ac-pcmp/" :docstring t)
;; `ac-pcmp/self-insert-command-with-ac-start'
;; Do `self-insert-command' and `auto-complete'.
;; 
;;  *** END auto-documentation
;; [EVAL] (autodoc-document-lisp-buffer :type 'function :prefix "ac-pcmp/" :docstring t)
;; `ac-pcmp/get-ac-candidates'
;; Return the result of `pcomplete'.
;; `ac-pcmp/do-ac-action'
;; Do the same action that `pcomplete' does after completion.
;; 
;;  *** END auto-documentation
;; [Note] Functions and variables other than listed above, Those specifications may be changed without notice.

;;; Tested On:
;; 
;; - Emacs ... GNU Emacs 24.3.1 (i686-pc-linux-gnu, GTK+ Version 3.4.2) of 2013-08-22 on chindi02, modified by Debian
;; - auto-complete.el ... Version 1.4.0
;; - yaxception.el ... Version 0.1
;; - log4e.el ... Version 0.2.0


;; Enjoy!!!


(eval-when-compile (require 'cl))
(require 'auto-complete)
(require 'pcomplete)
(require 'log4e)
(require 'yaxception)


(log4e:deflogger "ac-pcmp" "%t [%l] %m" "%H:%M:%S" '((fatal . "fatal")
                                                     (error . "error")
                                                     (warn  . "warn")
                                                     (info  . "info")
                                                     (debug . "debug")
                                                     (trace . "trace")))
(ac-pcmp--log-set-level 'trace)


(defvar ac-pcmp--active-p nil)
(defvar ac-pcmp--candidates nil)
(defvar ac-pcmp--status nil)
(defvar ac-pcmp--point nil)


(defadvice pcomplete-completions (after ac-pcmp activate)
  (when (and ac-pcmp--active-p
             (not ac-pcmp--candidates))
    (setq ac-pcmp--candidates ad-return-value)
    (ac-pcmp--trace "got candidates by pcomplete-completions")))

(defadvice pcomplete-show-completions (around ac-pcmp activate)
  (if (not ac-pcmp--active-p)
      ad-do-it
    (when (not ac-pcmp--candidates)
      (setq ac-pcmp--candidates (ad-get-arg 0))
      (ac-pcmp--trace "got candidates by pcomplete-show-completions"))
    (setq ad-return-value nil)))

(defadvice pcomplete-stub (before ac-pcmp activate)
  (when (and ac-pcmp--active-p
             (not ac-pcmp--candidates))
    (setq ac-pcmp--candidates (ad-get-arg 1))
    (ac-pcmp--trace "got candidates by pcomplete-stub")))

(defadvice pcomplete-stub (after ac-pcmp activate)
  (when ac-pcmp--active-p
    (setq ac-pcmp--status (car ad-return-value))
    (ac-pcmp--trace "got status : %s" ac-pcmp--status)
    (setq ad-return-value nil)))


(defun* ac-pcmp--show-message (msg &rest args)
  (apply 'message (concat "[AC-PCMP] " msg) args)
  nil)


(defun ac-pcmp/get-ac-candidates ()
  "Return the result of `pcomplete'."
  (yaxception:$
    (yaxception:try
      (ac-pcmp--trace "start get ac candidates")
      (let ((ac-pcmp--active-p t)
            (ac-pcmp--candidates nil))
        (setq ac-pcmp--status 'none)
        (setq ac-pcmp--point (point))
        (call-interactively 'pcomplete)
        (ac-pcmp--trace "got candidates : %s" ac-pcmp--candidates)
        ac-pcmp--candidates))
    (yaxception:catch 'error e
      (ac-pcmp--show-message "Failed get ac candidates : %s" (yaxception:get-text e))
      (ac-pcmp--error "failed get ac candidates : %s\n%s"
                      (yaxception:get-text e)
                      (yaxception:get-stack-trace-string e)))))

(defun ac-pcmp/do-ac-action ()
  "Do the same action that `pcomplete' does after completion."
  (yaxception:$
    (yaxception:try
      (ac-pcmp--trace "start ac action")
      (let* ((stub pcomplete-stub)
             (addsuffix (memq ac-pcmp--status '(sole shortest)))
             (raw-p pcomplete-last-completion-raw))
        (when (and (boundp 'pcomplete-suffix-list)
                   (not (memq (char-before) pcomplete-suffix-list))
                   addsuffix)
          (ac-pcmp--trace "do insert-and-inherit pcomplete-termination-string")
          (insert-and-inherit pcomplete-termination-string))
        (setq pcomplete-last-completion-length (- (point) ac-pcmp--point))
        (ac-pcmp--trace "set pcomplete-last-completion-length : %s"
                        pcomplete-last-completion-length)
        (setq pcomplete-last-completion-stub stub)
        (ac-pcmp--trace "set pcomplete-last-completion-stub : %s"
                        pcomplete-last-completion-stub)))
    (yaxception:catch 'error e
      (ac-pcmp--show-message "Failed ac action : %s" (yaxception:get-text e))
      (ac-pcmp--error "failed ac action : %s\n%s"
                      (yaxception:get-text e)
                      (yaxception:get-stack-trace-string e)))))

(defun ac-pcmp/self-insert-command-with-ac-start (n)
  "Do `self-insert-command' and `auto-complete'."
  (interactive "p")
  (self-insert-command n)
  (auto-complete-1 :triggered 'trigger-key))


(provide 'auto-complete-pcmp)
;;; auto-complete-pcmp.el ends here
