;;; ido-flex-with-migemo.el --- use ido with flex and migemo

;; Copyright (C) 2017 by ROCKTAKEY

;; Author: ROCKTAKEY  <rocktakey@gmail.com>

;; Version: 0.0.0
;; Package-Version: 20190408.350
;; Package-Commit: aa93aa05947eb6c106bb9523ff3163b8574c4eac

;; URL: https://github.com/ROCKTAKEY/ido-flex-with-migemo

;; Keywords: matching

;; Package-Requires: ((flx-ido "0.6.1") (migemo "1.9.1") (emacs "24.4"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;; Commentary:

;; ROCKTAKEY


;; Table of Contents
;; _________________

;; 1 Usage
;; 2 Variable
;; .. 2.1 ido-flex-with-migemo-excluded-func-list


;; 1 Usage
;; =======

;;   If you turn on "ido-flex-with-migemo-mode," you can use ido with both
;;   flex and migemo.


;; 2 Variable
;; ==========

;; 2.1 ido-flex-with-migemo-excluded-func-list
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;;   This is list of function you don't want to use ido-flex-with-migemo in.
;;   Here's an example:

;;   ,----
;;   | 1  (require 'smex)      ;;you have to install "smex" if you use this example
;;   | 2  (add-to-list 'ido-flex-with-migemo-excluded-func-list '(smex))
;;   `----

;;; Code:

(require 'migemo)
(require 'flx-ido)
(advice-remove 'ido-set-matches-1 'ad-Advice-ido-set-matches-1)


(defgroup ido-flex-with-migemo nil
  "Group of `ido-flex-with-migemo-mode'"
  :group 'ido)

(defcustom ido-flex-with-migemo-excluded-func-list
  '(ido-describe-bindings
    describe-variable
    describe-function
    smex)
  "This is list of function you don't want to use ido-flex-with-migemo."
  :group 'ido-flex-with-migemo
  :type '(repeat function))

(defcustom ido-flex-with-migemo-least-char 2
  "migemo in ido is inactivated if length of query is less than this value. "
  :group 'ido-flex-with-migemo
  :type 'number)

(defface ido-flex-with-migemo-migemo-face
  '((((background light)) (:background  "#ded0ff" :italic t))
    (((background dark))  (:background  "#0e602f" :italic t)))
  "this face is used when ido is used with migemo.")


(defun ido-flex-with-migemo--migemo-match (query items)
  "Return list of match to QUERY in ITEMS on migemo."
  (let ((regexp (migemo-get-pattern query))
        result)
    (cl-loop
     for x in items with str
     do (setq str (if (listp x) (car x) x))
     if (string-match regexp str)
     collect
     (if (listp x)
         (cons (propertize (car x) 'face 'ido-flex-with-migemo-migemo-face)
               (cdr x))
       (propertize x 'face 'ido-flex-with-migemo-migemo-face)))))

(defun ido-flex-with-migemo--flex-with-migemo-match (query items)
  "Return list of match to QUERY in ITEMS on migemo and flex."
  (let ((flex-items   (flx-ido-match query items))
        (migemo-items (ido-flex-with-migemo--migemo-match query items)))
    (setq migemo-items
          (cl-remove-if (lambda (arg) nil nil
                          (member arg flex-items))
                        migemo-items))
    (append flex-items migemo-items)))


(defun ido-flex-with-migemo--set-matches-1 (orig-func &rest args)
  "Advice for ORIG-FUNC with ARGS.
Choose among the regular `ido-set-matches-1', `ido-flex-with-migemo--match' and `flx-ido-match'."
  (let (ad-return-value)

    (if (or (not ido-flex-with-migemo-mode) ; if ido-flex-with-migemo-mode off
            (not migemo-process)
            ;;  command is excluded
            (memq this-command ido-flex-with-migemo-excluded-func-list)
            (>= ido-flex-with-migemo-least-char (length ido-text)))

        (if (not flx-ido-mode)          ; if flex-ido-mode off
            (funcall orig-func args)
          ;; if flex-ido-mode on
          (let ((query ido-text)
                (original-items (car args)))
            (flx-ido-debug "query: %s" query)
            (flx-ido-debug "id-set-matches-1 sees %s items"
                           (length original-items))
            (setq ad-return-value (flx-ido-match query original-items)))
          (flx-ido-debug "id-set-matches-1 returning %s items starting with %s "
                         (length ad-return-value) (car ad-return-value)))
      ;; if apply ido-flex-with-migemo
      (let ((query ido-text)
            (original-items (car args)))
        (flx-ido-debug "query: %s" query)
        (flx-ido-debug "ido-set-matches-1 sees %s items"
                       (length original-items))
        (setq
         ad-return-value
         (ido-flex-with-migemo--flex-with-migemo-match query original-items)))
      (flx-ido-debug "ido-set-matches-1 returning %s items starting with %s "
                     (length ad-return-value) (car ad-return-value)))
    ad-return-value))

(advice-add 'ido-set-matches-1 :around  'ido-flex-with-migemo--set-matches-1)

;;;###autoload
(define-minor-mode ido-flex-with-migemo-mode
  "Toggle ido flex with migemo mode."
  :init-value nil
  :lighter ""
  :group 'ido-flex-with-migemo
  :global t
  ;; (if ido-flex-with-migemo-mode
  ;;     (advice-add 'ido-set-matches-1 :around  'ido-flex-with-migemo--set-matches-1)
  ;;   (advice-remove 'ido-set-matches-1 'ido-flex-with-migemo--set-matches-1)
  ;;   )
  (unless migemo-process
    (message "ido-flex-with-migemo: No migemo process.")))

(provide 'ido-flex-with-migemo)


;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; ido-flex-with-migemo.el ends here
