;;; ace-isearch.el --- A seamless bridge between isearch, ace-jump-mode, avy, helm-swoop and swiper -*- coding: utf-8; lexical-binding: t -*-

;; Copyright (C) 2014-2020 by Akira TAMAMORI

;; Author: Akira Tamamori
;; URL: https://github.com/tam17aki/ace-isearch
;; Package-Version: 20210830.746
;; Package-Commit: 8439136206a42e41ef95af923e0dc3bbd4fa306c
;; Version: 1.0
;; Created: Sep 25 2014
;; Package-Requires: ((emacs "24"))

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 3 of the License, or (at your option) any later
;; version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License along with
;; this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; `ace-isearch.el' provides a minor mode that combines `isearch',
;; `ace-jump-mode', `avy', `helm-swoop' and `swiper'.
;;
;; The "default" behavior (`ace-isearch-jump-based-on-one-char' t) can be
;; summarized as:
;;
;; L = 1     : `ace-jump-mode' or `avy'
;; 1 < L < 6 : `isearch'
;; L >= 6    : `helm-swoop' or `swiper'
;;
;; where L is the input string length during `isearch'.  When L is 1, after a
;; few seconds specified by `ace-isearch-jump-delay', `ace-jump-mode' or `avy'
;; will be invoked. Of course you can customize the above behaviour.
;;
;; If (`ace-isearch-jump-based-on-one-char' nil), L=2 characters are required
;; to invoke `ace-jump-mode' or `avy' after `ace-isearch-jump-delay'. This has
;; the effect of doing regular `isearch' for L=1 and L=3 to 6, with the ability
;; to switch to 2-character `avy' or `ace-jump-mode' (not yet supported) once
;; `ace-isearch-jump-delay' has passed. Much easier to do than to write about :-)

;;; Installation:
;;
;; To use this package, add following code to your init file.
;;
;;   (require 'ace-isearch)
;;   (global-ace-isearch-mode +1)

;;; Code:

;; obsolete functions and variables
(define-obsolete-function-alias 'ace-isearch-switch-submode
  'ace-isearch-switch-function "0.1.3")
(define-obsolete-variable-alias 'ace-isearch-submode
  'ace-isearch-function "0.1.3")
(define-obsolete-variable-alias 'ace-isearch-input-idle-jump-delay
  'ace-isearch-jump-delay "0.1.3")
(define-obsolete-variable-alias 'ace-isearch-input-idle-func-delay
  'ace-isearch-func-delay "0.1.3")
(define-obsolete-variable-alias 'ace-isearch-use-ace-jump
  'ace-isearch-use-jump "0.1.3")

;; suppress byte-compile warnings
(declare-function ace-jump-mode-pop-mark "ace-jump-mode")
(declare-function ace-jump-do "ace-jump-mode")
(declare-function avy-pop-mark "avy")
(declare-function avy-isearch "avy")
(declare-function helm-swoop "helm-swoop")
(declare-function swiper "swiper")

(defgroup ace-isearch nil
  "Group of ace-isearch."
  :group 'convenience
  :prefix "ace-isearch-")

(defcustom ace-isearch-function 'ace-jump-word-mode
  "Function name to invoke ace-jump-mode or avy based on 1 character."
  :type '(choice (const :tag "Use ace-jump-word-mode." ace-jump-word-mode)
                 (const :tag "Use ace-jump-char-mode." ace-jump-char-mode)
                 (const :tag "Use avy-goto-word-1." avy-goto-word-1)
                 (const :tag "Use avy-goto-subword-1." avy-goto-subword-1)
                 (const :tag "Use avy-goto-char." avy-goto-char))
  :group 'ace-isearch)

(defcustom ace-isearch-2-function 'avy-goto-char-2
  "Function name to invoke ace-jump-mode or avy based on 2 characters."
  :type '(choice (const :tag "Use avy-goto-char-2." avy-goto-char-2)
                 (const :tag "Use avy-goto-char-2-above." avy-goto-char-2-above)
                 (const :tag "Use avy-goto-char-2-below." avy-goto-char-2-below))
  :group 'ace-isearch)

(if (not (require 'ace-jump-mode nil 'noerror))
    (if (require 'avy nil 'noerror)
        (setq ace-isearch-function 'avy-goto-word-1
              ace-isearch-2-function 'avy-goto-char-2)
      (user-error "You need to install either ace-jump-mode or avy.")))

(defcustom ace-isearch-function-from-isearch 'ace-isearch-helm-swoop-from-isearch
  "Symbol name of function which is invoked when the length of `isearch-string'
is longer than or equal to `ace-isearch-input-length'."
  :type 'symbol
  :group 'ace-isearch)

(if (not (or (require 'helm-swoop nil 'noerror)
             (if (require 'helm-occur nil 'noerror)
                 (setq ace-isearch-function-from-isearch 'ace-isearch-helm-occur-from-isearch)
               nil)))
    (if (require 'swiper nil 'noerror)
        (setq ace-isearch-function-from-isearch 'ace-isearch-swiper-from-isearch)
      (user-error "You need to install either helm-swoop, helm-occur or swiper.")))

(defcustom ace-isearch-lighter " AceI"
  "Lighter of ace-isearch-mode."
  :type 'string
  :group 'ace-isearch)

(defcustom ace-isearch-jump-based-on-one-char t
  "If true, jump for L=1 after delay of `ace-isearch-jump-delay', otherwise
require L=2 characters to jump."
  :type 'boolean
  :group 'ace-isearch)

(defcustom ace-isearch-jump-delay 0.3
  "Delay seconds for invoking `ace-jump-mode' or `avy' during isearch."
  :type 'number
  :group 'ace-isearch)

(defcustom ace-isearch-func-delay 0.0
  "Delay seconds for invoking `ace-isearch-function-from-isearch' during isearch."
  :type 'number
  :group 'ace-isearch)

(defcustom ace-isearch-input-length 6
  "Length of input string required for invoking `ace-isearch-function-from-isearch'
during isearch."
  :type 'integer
  :group 'ace-isearch)

(defcustom ace-isearch-use-jump t
  "If `nil', `ace-jump-mode' or `avy' is never invoked.

If `t', it is always invoked if the length of `isearch-string' is
equal to 1 or 2, cf. value of `ace-isearch-jump-based-on-one-char'.

If `printing-char', it is invoked only if you hit a printing
character to search for as a first input.  This prevents it from
being invoked when repeating a one character search, yanking a
character or calling `isearch-delete-char' leaving only one
character."
  :type '(choice (const :tag "Always" t)
                 (const :tag "Only after a printing character is input" printing-char)
                 (const :tag "Never" nil))
  :group 'ace-isearch)

(defcustom ace-isearch-use-function-from-isearch t
  "When non-nil, invoke `ace-isearch-function-from-isearch' if the length
of `isearch-string' is longer than or equal to `ace-isearch-input-length'."
  :type 'boolean
  :group 'ace-isearch)

(defcustom ace-isearch-fallback-function 'ace-isearch-helm-swoop-from-isearch
  "Symbol name of function that is invoked when isearch fails and
`ace-isearch-use-fallback-function' is non-nil."
  :type 'symbol
  :group 'ace-isearch)

(defcustom ace-isearch-use-fallback-function nil
  "When non-nil, invoke `ace-isearch-fallback-function' when isearch fails."
  :type 'boolean
  :group 'ace-isearch)

(defcustom ace-isearch-on-evil-mode nil
  "If non nil, ace-isearch-mode can be used on Evil mode."
  :type 'boolean
  :group 'ace-isearch)

(defvar ace-isearch--ace-jump-function-list
  (list "ace-jump-word-mode" "ace-jump-char-mode"))

(defvar ace-isearch--ace-jump-2-function-list
  (list))

(defvar ace-isearch--avy-function-list
  (list "avy-goto-word-1" "avy-goto-subword-1"
        "avy-goto-word-or-subword-1" "avy-goto-char"))

(defvar ace-isearch--avy-2-function-list
  (list "avy-goto-char-2" "avy-goto-char-2-above"
        "avy-goto-char-2-below"))

(defvar ace-isearch--function-list
  (append ace-isearch--ace-jump-function-list ace-isearch--avy-function-list)
  "List of functions for jumping using 1 character.")

(defvar ace-isearch-2--function-list
  (append ace-isearch--ace-jump-2-function-list ace-isearch--avy-2-function-list)
  "List of functions for jumping using 2 characters.")

(defvar ace-isearch--ace-jump-or-avy)

(defsubst ace-isearch--isearch-regexp-function ()
  (or (bound-and-true-p isearch-regexp-function)
      (bound-and-true-p isearch-word)))

(defun ace-isearch-switch-function ()
  (interactive)
  (let ((func (completing-read
               (format "Function for ace-isearch (current is %s): "
                       ace-isearch-function)
               ace-isearch--function-list nil t)))
    (setq ace-isearch-function (intern-soft func))
    (ace-isearch--make-ace-jump-or-avy)
    (message "Function for ace-isearch is set to %s." func)))

(defun ace-isearch-2-switch-function ()
  (interactive)
  (let ((func (completing-read
               (format "Function for ace-isearch-2 (current is %s): "
                       ace-isearch-2-function)
               ace-isearch-2--function-list nil t)))
    (setq ace-isearch-2-function (intern-soft func))
    (ace-isearch-2--make-ace-jump-or-avy)
    (message "Function for ace-isearch-2 is set to %s." func)))

(defun ace-isearch--fboundp (func flag)
  (declare (indent 1))
  (when flag
    (when (eq func nil)
      (error "function name must be specified!"))
    (unless (fboundp func)
      (error (format "function %s is not bounded!" func)))
    t))

(defun ace-isearch--jumper-function ()
  (let ((ace-isearch-input-min-length
         (if ace-isearch-jump-based-on-one-char
             1
           2)))
    (cond (;; using avy/ace-jump since L=1 or L=2 reached (depending on `ace-isearch-jump-based-on-one-char')
           (and (= (length isearch-string) ace-isearch-input-min-length)
                (and (if ace-isearch-on-evil-mode
                         t
                       (not isearch-regexp))
                     (or (not (ace-isearch--isearch-regexp-function))
                         (not (eq search-default-mode nil))))
                (ace-isearch--fboundp (if ace-isearch-jump-based-on-one-char
                                          ace-isearch-function ace-isearch-2-function)
                  (or (eq ace-isearch-use-jump t)
                      (and (eq ace-isearch-use-jump 'printing-char)
                           (eq this-command 'isearch-printing-char))))
                (sit-for ace-isearch-jump-delay))
           (isearch-done t t)
           ;; go back to the point where isearch started
           (goto-char isearch-opoint)
           (if (or (< (point) (window-start)) (> (point) (window-end)))
               (message "Notice: Character '%s' could not be found in the \"selected visible window\"." isearch-string))
           (if ace-isearch-jump-based-on-one-char
               (funcall ace-isearch-function (string-to-char isearch-string))
             (funcall ace-isearch-2-function (aref isearch-string 0) (aref isearch-string 1)))
           ;; work-around for emacs 25.1
           (setq isearch--current-buffer (buffer-name (current-buffer))
                 isearch-string ""))

          ;; switching from isearch to helm/swiper since `ace-isearch-jump-delay' passed without isearch result
          ((and (> (length isearch-string) ace-isearch-input-min-length)
                (< (length isearch-string) ace-isearch-input-length)
                (not isearch-success)
                (sit-for ace-isearch-jump-delay))
           (if (ace-isearch--fboundp ace-isearch-fallback-function
                 ace-isearch-use-fallback-function)
               (funcall ace-isearch-fallback-function)))

          ;; switching from isearch to helm/swiper since `ace-isearch-input-length' reached
          ((and (>= (length isearch-string) ace-isearch-input-length)
                (if ace-isearch-on-evil-mode
                    t
                  (not isearch-regexp))
                (ace-isearch--fboundp ace-isearch-function-from-isearch
                  ace-isearch-use-function-from-isearch)
                (sit-for ace-isearch-func-delay))
           (isearch-done t t)
           (funcall ace-isearch-function-from-isearch)
           ;; work-around for emacs 25.1
           (setq isearch--current-buffer (buffer-name (current-buffer))
                 isearch-string "")))))

(defun ace-isearch-pop-mark ()
  "Jump back to the last location of `ace-jump-mode' invoked or `avy-push-mark'."
  (interactive)
  (cond ((eq ace-isearch--ace-jump-or-avy 'ace-jump)
         (ace-jump-mode-pop-mark))
        ((eq ace-isearch--ace-jump-or-avy 'avy)
         (avy-pop-mark))))

(defun ace-isearch--make-ace-jump-or-avy ()
  (let ((func-str (format "%s" ace-isearch-function)))
    (cond ((member func-str ace-isearch--function-list)
           (cond ((member func-str ace-isearch--ace-jump-function-list)
                  (setq ace-isearch--ace-jump-or-avy 'ace-jump))
                 ((member func-str ace-isearch--avy-function-list)
                  (setq ace-isearch--ace-jump-or-avy 'avy))))
          (t
           (error (format "Function name %s for ace-isearch is invalid!"
                          ace-isearch-function))))))

(defun ace-isearch-2--make-ace-jump-or-avy ()
  (let ((func-str (format "%s" ace-isearch-2-function)))
    (cond ((member func-str ace-isearch-2--function-list)
           (cond ((member func-str ace-isearch--ace-jump-2-function-list)
                  (setq ace-isearch--ace-jump-or-avy 'ace-jump))
                 ((member func-str ace-isearch--avy-2-function-list)
                  (setq ace-isearch--ace-jump-or-avy 'avy))))
          (t
           (error (format "Function name %s for ace-isearch-2 is invalid!"
                          ace-isearch-2-function))))))

(defun ace-isearch-helm-occur-from-isearch ()
  "Invoke `helm-swoop' from ace-isearch."
  (interactive)
  (let ((bufs (list (current-buffer)))
        ($query (if isearch-regexp
                    isearch-string
                  (regexp-quote isearch-string))))
    (isearch-update-ring isearch-string isearch-regexp)
    (let (search-nonincremental-instead)
      (ignore-errors (isearch-done t t)))
    (helm-multi-occur-1 bufs $query)))

(defun ace-isearch-helm-swoop-from-isearch ()
  "Invoke `helm-swoop' from ace-isearch."
  (interactive)
  (let (($query (if isearch-regexp
                    isearch-string
                  (regexp-quote isearch-string))))
    (isearch-update-ring isearch-string isearch-regexp)
    (let (search-nonincremental-instead)
      (ignore-errors (isearch-done t t)))
    (helm-swoop :query $query)))

(defun ace-isearch-swiper-from-isearch ()
  "Invoke `swiper' from ace-isearch."
  (interactive)
  (let (($query (if isearch-regexp
                    isearch-string
                  (regexp-quote isearch-string))))
    (isearch-update-ring isearch-string isearch-regexp)
    (let (search-nonincremental-instead)
      (ignore-errors (isearch-done t t)))
    (swiper $query)))

;;;###autoload
(defun ace-isearch-jump-during-isearch ()
  "Jump to one of the current isearch candidates."
  (interactive)
  (if (< (length isearch-string) ace-isearch-input-length)
      (cond ((eq ace-isearch--ace-jump-or-avy 'ace-jump)
             (let ((ace-jump-mode-scope 'window))
               (isearch-exit)
               (ace-jump-do (regexp-quote isearch-string))))
            ((eq ace-isearch--ace-jump-or-avy 'avy)
             (let ((avy-all-windows nil))
               (avy-isearch))))))

;;;###autoload
(define-minor-mode ace-isearch-mode
  "Minor-mode that combines isearch, ace-jump-mode, avy, helm-swoop and swiper seamlessly."
  :group      'ace-isearch
  :init-value nil
  :global     nil
  :lighter    ace-isearch-lighter
  (if ace-isearch-mode
      (progn
        (add-hook 'isearch-update-post-hook 'ace-isearch--jumper-function nil t)
        (if ace-isearch-jump-based-on-one-char
            (ace-isearch--make-ace-jump-or-avy)
          (ace-isearch-2--make-ace-jump-or-avy)))
    (remove-hook 'isearch-update-post-hook 'ace-isearch--jumper-function t)))

(defun ace-isearch--turn-on ()
  (unless (minibufferp)
    (ace-isearch-mode +1)))

;;;###autoload
(define-globalized-minor-mode global-ace-isearch-mode
  ace-isearch-mode ace-isearch--turn-on
  :group 'ace-isearch)

(provide 'ace-isearch)
;;; ace-isearch.el ends here
