;;; code-stats.el --- Code::Stats plugin             -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Xu Chunyang

;; Author: Xu Chunyang <mail@xuchunyang.me>
;; Homepage: https://github.com/xuchunyang/code-stats-emacs
;; Package-Requires: ((emacs "25") (request "0.3.0"))
;; Package-Version: 20181110.1952
;; Package-Commit: 20d60ded0743f01206c3c2e92ab73788def9adcb
;; Created: 2018-07-13T13:29:18+08:00
;; Version: 0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Code::Stats plugin for Emacs
;;
;; See https://github.com/xuchunyang/code-stats-emacs for more info

;;; Code:

(require 'cl-lib)
(require 'request)
(require 'json)

;; Set it to https://beta.codestats.net for testing
(defvar code-stats-url "https://codestats.net")

(defvar code-stats-token nil)

(defvar-local code-stats-xp 0
  "XP for the current buffer.")

(defvar code-stats-xp-cache nil
  "XP for the killed buffers.")

(defun code-stats-post-self-insert ()
  (cl-incf code-stats-xp))

(defun code-stats-cache-xp ()
  (when (> code-stats-xp 0)
    (push (cons (code-stats-get-language)
                code-stats-xp)
          code-stats-xp-cache)))

;;;###autoload
(define-minor-mode code-stats-mode
  "Code Stats Minor Mode."
  :init-value nil
  :lighter " Code::Stats"
  (if code-stats-mode
      (progn
        (add-hook 'post-self-insert-hook #'code-stats-post-self-insert :append :local)
        (add-hook 'kill-buffer-hook #'code-stats-cache-xp nil :local))
    (remove-hook 'post-self-insert-hook #'code-stats-post-self-insert :local)
    (remove-hook 'kill-buffer-hook #'code-stats-cache-xp :local)))

(defvar code-stats-languages
  '((c-mode . "C")
    (c++-mode . "C++")
    (emacs-lisp-mode . "Emacs Lisp")
    (lisp-interaction-mode . "Emacs Lisp")
    (html-mode . "HTML")
    (mhtml-mode . "HTML")
    (js2-mode . "JavaScript")
    (sh-mode . "Shell"))
  "Alist of mapping `major-mode' to language name.")

(defun code-stats-get-language ()
  (or (alist-get major-mode code-stats-languages)
      (if (stringp mode-name)
          mode-name
        (replace-regexp-in-string "-mode\\'" "" (symbol-name major-mode)))))

(defun code-stats-xps-merge (xps)
  (cl-loop for (language . xp) in xps
           with new-xps = '()
           if (assoc language new-xps)
           do (cl-incf (cdr (assoc language new-xps)) xp)
           else
           do (push (cons language xp) new-xps)
           finally return (sort new-xps (lambda (a b) (string< (car a) (car b))))))

;; (("Emacs-Lisp" . 429) ("Racket" . 18))
(defun code-stats-collect-xps ()
  (let (xps)
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (when (and code-stats-mode (> code-stats-xp 0))
          (let ((language (code-stats-get-language)))
            (push (cons language code-stats-xp) xps)))))
    (code-stats-xps-merge (append code-stats-xp-cache xps))))

(defun code-stats-reset-xps ()
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when code-stats-mode
        (setq code-stats-xp 0))))
  (setq code-stats-xp-cache nil))

(defun code-stats-build-pulse ()
  (let ((xps (code-stats-collect-xps)))
    (when xps
      `((coded_at . ,(format-time-string "%FT%T%:z"))
        (xps . [,@(cl-loop for (language . xp) in xps
                           collect `((language . ,language)
                                     (xp . ,xp)))])))))

;; TODO: Log sent pulse
;;;###autoload
(defun code-stats-sync (&optional wait)
  "Sync with Code::Stats.
If WAIT is non-nil, block Emacs until the process is done."
  (let ((pulse (code-stats-build-pulse)))
    (when pulse
      (when wait
        (message "[code-stats] Syncing Code::Stats..."))
      (request (concat code-stats-url "/api/my/pulses")
               :sync wait
               :type "POST"
               :headers `(("X-API-Token"  . ,code-stats-token)
                          ("User-Agent"   . "code-stats-emacs")
                          ("Content-Type" . "application/json"))
               :data (json-encode pulse)
               :parser #'json-read
               :error (cl-function
                       (lambda (&key data error-thrown &allow-other-keys)
                         (message "[code-stats] Got error: %S - %S"
                                  error-thrown
                                  (cdr (assq 'error data)))))
               :success (cl-function
                         (lambda (&key _data &allow-other-keys)
                           ;; (message "%s" (cdr (assq 'ok data)))
                           (code-stats-reset-xps)))))))

(provide 'code-stats)
;;; code-stats.el ends here
