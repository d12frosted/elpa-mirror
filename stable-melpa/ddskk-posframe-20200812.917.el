;;; ddskk-posframe.el --- Show Henkan tooltip for ddskk via posframe       -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Maintainer: Naoya Yamashita <conao3@gmail.com>
;; Keywords: tooltip convenience posframe
;; Package-Version: 20200812.917
;; Package-Commit: 299493dd951e5a0b43b8213321e3dc0bac10f762
;; Version: 1.0.9
;; URL: https://github.com/conao3/ddskk-posframe.el
;; Package-Requires: ((emacs "26.1") (posframe "0.4.3") (ddskk "16.2.50"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the Affero GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the Affero
;; GNU General Public License for more details.

;; You should have received a copy of the Affero GNU General Public
;; License along with this program.  If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;; ddskk-posframe.el provide Henkan tooltip for ddskk via posframe.
;;
;; You only need to enable minor-mode; `ddskk-posframe-mode'.
;;
;; More information is [[https://github.com/conao3/ddskk-posframe.el][here]]

;;; Code:

(require 'posframe)
(require 'skk)

(defgroup ddskk-posframe nil
  "Show Henkan tooltip for `skk' via `posframe'."
  :group 'completion)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Custom variables
;;

(defcustom ddskk-posframe-style 'point
  "The style of ddskk-posframe."
  :group 'ddskk-posframe
  :type 'symbol)

(defcustom ddskk-posframe-font nil
  "The font used by ddskk-posframe.
When nil, Using current frame's font as fallback."
  :group 'ddskk-posframe
  :type '(choice (const :tag "inherit" nil)
                 string))

(defcustom ddskk-posframe-width nil
  "The width of ddskk-posframe."
  :group 'ddskk-posframe
  :type '(choice (const :tag "default" nil)
                 number))

(defcustom ddskk-posframe-height nil
  "The height of ddskk-posframe."
  :group 'ddskk-posframe
  :type '(choice (const :tag "default" nil)
                 number))

(defcustom ddskk-posframe-min-width nil
  "The width of ddskk-min-posframe."
  :group 'ddskk-posframe
  :type '(choice (const :tag "non-width" nil)
                 number))

(defcustom ddskk-posframe-min-height nil
  "The height of ddskk-min-posframe."
  :group 'ddskk-posframe
  :type '(choice (const :tag "non-width" nil)
                 number))

(defcustom ddskk-posframe-border-width 1
  "The border width used by ddskk-posframe.
When 0, no border is showed."
  :group 'ddskk-posframe
  :type '(choice (const :tag "non-width" nil)
                 number))

(defcustom ddskk-posframe-parameters nil
  "The frame parameters used by ddskk-posframe."
  :group 'ddskk-posframe
  :type '(choice (const :tag "no-parameters" nil)
                 number))

(defface ddskk-posframe
  '((t (:inherit default)))
  "Face used by the ddskk-posframe."
  :group 'ddskk-posframe)

(defface ddskk-posframe-border
  '((t (:inherit default :background "gray50")))
  "Face used by the ddskk-posframe's border."
  :group 'ddskk-posframe)

(defvar ddskk-posframe-buffer " *ddskk-posframe-buffer*"
  "The posframe-buffer used by ddskk-posframe.")

(defvar ddskk-posframe--display-p nil
  "The status of `ddskk-posframe--display'.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Functions
;;

(defun ddskk-posframe--display (str &optional poshandler)
  "Show STR in ddskk posframe via POSHANDLER."
  (if (not (posframe-workable-p))
      (warn "ddskk-posframe is busy now!")
    (setq ddskk-posframe--display-p t)
    (posframe-show
     ddskk-posframe-buffer
     :font ddskk-posframe-font
     :string str
     :position (point)
     :poshandler poshandler
     :background-color (face-attribute 'ddskk-posframe :background nil t)
     :foreground-color (face-attribute 'ddskk-posframe :foreground nil t)
     :height ddskk-posframe-height
     :width ddskk-posframe-width
     :min-height (or ddskk-posframe-min-height 1)
     :min-width (or ddskk-posframe-min-width 10)
     :internal-border-width ddskk-posframe-border-width
     :internal-border-color (face-attribute 'ddskk-posframe-border :background nil t)
     :override-parameters ddskk-posframe-parameters)))

(defun ddskk-posframe-display (str)
  "Display STR via `posframe' by `ddskk-posframe-style'."
  (let ((func (intern (format "ddskk-posframe-display-at-%s" ddskk-posframe-style))))
    (if (functionp func)
        (funcall func str)
      (funcall (intern (format "ddskk-posframe-display-at-%s" "point")) str))))

(eval
 `(progn
    ,@(mapcar
       (lambda (elm)
         `(defun ,(intern (format "ddskk-posframe-display-at-%s" (car elm))) (str)
            ,(format "Display STR via `posframe' at %s" (car elm))
            (ddskk-posframe--display str #',(intern (format "posframe-poshandler-%s" (cdr elm))))))
       '((window-center      . window-center)
         (frame-center       . frame-center)
         (window-bottom-left . window-bottom-left-corner)
         (frame-bottom-left  . frame-bottom-left-corner)
         (point              . point-bottom-left-corner)))))

(defun ddskk-posframe-display-at-frame-bottom-window-center (str)
  "Display STR via `posframe' at frame-bottom-window-center."
  (ddskk-posframe--display
   str (lambda (info)
         (cons (car (posframe-poshandler-window-center info))
               (cdr (posframe-poshandler-frame-bottom-left-corner info))))))

(defun ddskk-posframe-cleanup ()
  "Cleanup ddskk-posframe."
  (when (ddskk-posframe-workable-p)
    (posframe-hide ddskk-posframe-buffer)
    (setq ddskk-posframe--display-p nil)))

(defun ddskk-posframe-workable-p ()
  "Test ddskk-posframe workable status."
  (and (>= emacs-major-version 26)
       (not (or noninteractive
                (not (display-graphic-p))))))

(defun ddskk-posframe-window ()
  "Return the posframe window displaying `ddskk-posframe-buffer'."
  (frame-selected-window
   (buffer-local-value 'posframe--frame
                       (get-buffer ddskk-posframe-buffer))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Minormode definition
;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Advices
;;

(defvar ddskk-posframe-advice-alist
  '((skk-henkan             . ddskk-posframe--skk-henkan)
    (skk-henkan-in-minibuff . ddskk-posframe--skk-henkan-in-minibuff)))

(defun ddskk-posframe--skk-henkan (fn &rest args)
  "Around advice for `skk-henkan', FN with ARGS."
  (apply fn args)
  (ddskk-posframe-cleanup))

(defun ddskk-posframe--skk-henkan-in-minibuff (fn &rest args)
  "Around advice for `skk-henkan-in-minibuff', FN with ARGS."
  (ddskk-posframe-display "↓辞書登録中↓")
  (apply fn args))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Variables
;;

(defvar ddskk-posframe-saved-variables-alist nil)
(defvar ddskk-posframe-variables-alist
  '((skk-show-tooltip     . t)
    (skk-tooltip-function . ddskk-posframe-display)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Minormode
;;

;;;###autoload
(define-minor-mode ddskk-posframe-mode
  "Enable ddskk-posframe-mode."
  :init-value nil
  :global t
  :lighter " SKK-pf"
  :group 'ddskk-posframe
  (let ((advices    ddskk-posframe-advice-alist)
        (vars       ddskk-posframe-variables-alist)
        (saved-vars ddskk-posframe-saved-variables-alist))
    (if ddskk-posframe-mode
        (progn
          (mapc (lambda (elm)
                  (let ((pair (assoc (car elm) ddskk-posframe-saved-variables-alist)))
                    (if pair
                        (setcdr pair (symbol-value (car elm)))
                      (push `(,(car elm) . ,(symbol-value (car elm)))
                            ddskk-posframe-saved-variables-alist))))
                vars)
          (eval
           `(progn
              ,@(mapcar (lambda (elm) `(advice-add ',(car elm) :around ',(cdr elm))) advices)
              ,@(mapcar (lambda (elm) `(setq-default ,(car elm) ',(cdr elm))) vars))))
      (eval
       `(progn
          ,@(mapcar (lambda (elm) `(advice-remove ',(car elm) ',(cdr elm))) advices)
          ,@(mapcar (lambda (elm) `(setq-default ,(car elm) ',(cdr elm))) saved-vars))))))

(provide 'ddskk-posframe)
;;; ddskk-posframe.el ends here
