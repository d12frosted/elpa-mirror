;;; persp-fr.el --- In persp-mode, show perspective list in the GUI window title

;; Copyright (C) 2016 - 2019 Francesc Rocher

;; Author: Francesc Rocher <francesc.rocher@gmail.com>
;; URL: http://github.com/rocher/persp-fr
;; Package-Version: 20191108.754
;; Package-Commit: 1adbb6a9f9a4db580a9b7ed8b4091738e01345e6
;; Version: 0.0.5
;; Package-Requires: ((emacs "25.1") (persp-mode "2.9.6") (dash "2.13.0"))
;; Keywords: perspectives, workspace, windows, convenience

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

;; This code is an extension of the `persp-mode' mode that uses your
;; GUI window title (aka Emacs frame name) to show the list of current
;; perspectives and indicates the current one.  It also permits to
;; move the current perspective to the left, right, first or last
;; position.

;; Installation:

;; From the MELPA: M-x package-install RET `persp-fr' RET.

;; From a file: M-x `package-install-file' RET 'path to this file' RET
;; Or put this file into your load-path.

;; Usage:

;; The same as `persp-mode':

;;    (require 'persp-fr)    ;; was (require 'persp-mode)
;;    (persp-fr-start)

;; Customization:

;; The customization group lets you tweak few parameters: M-x `customize-group'
;; RET 'persp-fr' RET.

;; Useful keys to change to next/previous perspective, as in most user
;; interfaces using tabs, and to move current perspective to left/right:

;;     (global-set-key [(control prior)] 'persp-prev)
;;     (global-set-key [(control next)] 'persp-next)
;;     (global-set-key [(control meta next)] 'persp-fr-move-right)
;;     (global-set-key [(control meta prior)] 'persp-fr-move-left)


;; Tested only under Linux / Gnome.  Feedback welcome!

;; Thanks to:
;;    - Naoya Yamashita, for fixing some lint issues

;;; Code:

(require 'persp-mode)
(require 'dash)
(require 'cl-lib)

(defgroup persp-fr nil
  "Customization of the `persp-fr' mode."
  :tag "persp-fr"
  :group 'environment)

(defcustom persp-fr-use-prefix-numbers t
  "When non-nil, perspective names are prefix with a number.
Useful to move to a perspective with a key binding."
  :tag "Use prefix numbers in perspective names"
  :type '(boolean)
  :group 'persp-fr)

(defcustom persp-fr-title-max-length nil
  "Limit the length of the title shown in the window title."
  :tag "Max length of frame titles."
  :type '(choice
          (const :tag "unlimited" nil)
          (integer :tag "limited" :value 64
                   :validate
                   (lambda(widget)
                     (when (or (null (integerp (widget-value widget)))
                               (< (widget-value widget)  1))
                       (widget-put
                        widget :error
                        (format-message
                         "Invalid value, must be an integer greater than 0"))
                       widget))))
  :set (lambda (symbol value)
         (custom-set-default symbol value)
         (when (fboundp 'persp-fr-update)
           (persp-fr-update nil)))
  :group 'persp-fr)

(defcustom persp-fr-title-prefix nil
  "Prefix to be used in the window title."
  :tag "Window title prefix"
  :type '(choice
          (const :tag "default frame name" nil)
          (string :tag "literal text"))
  :set (lambda (symbol value)
         (custom-set-default symbol value)
         (when (fboundp 'persp-fr-update)
           (persp-fr-update nil)))
  :group 'persp-fr)

(defcustom persp-fr-move-cycle-at-end t
  "When non-nil, perform cycle move.
`persp-fr-move-left' and `persp-fr-move-right' functions will cycle
the perspective if it is moved further the beginning or the end."
  :tag "Cycle moved perspectives"
  :type '(boolean)
  :group 'persp-fr)

(defvar persp-fr-default-frame-name (frame-parameter nil 'name))

(defun persp-fr-update (&optional hook &rest rest)
  "Keep a list of perspective names in the frame title.

\(fn &optional HOOK &rest REST)"
  (let ((current (get-current-persp)))
    (unless (and (eq hook 'persp-before-kill-functions)
                 (eq (car rest) current))
      (setq current (safe-persp-name current))
      (let ((persp-list (persp-names-current-frame-fast-ordered))
            (i 0)
            title)
        (when (eq hook 'persp-before-kill-functions)
          (setq persp-list
                (delete (safe-persp-name (car rest))
                        persp-list)))
        (setq title
              (concat (or persp-fr-title-prefix
                          persp-fr-default-frame-name
                          current)
                      "   - "
                      (mapconcat
                       #'(lambda (persp)
                           (let ((persp-name persp))
                             (if persp-fr-use-prefix-numbers
                                 (progn
                                   (setq i (1+ i))
                                   (setq persp-name (format "%d=%s" i persp))))
                             (if (string= current persp)
                                 (concat "[ " persp-name " ]")
                               persp-name)))
                       persp-list
                       " - ")
                      " -"))
        (if (and persp-fr-title-max-length
                 (> (length title) persp-fr-title-max-length))
            (setq title (concat (substring title 0 persp-fr-title-max-length) " ..")))
        (set-frame-name title)))))

(defun persp-fr-current-name ()
  "Return current persp name."
  (let* ((persp (get-current-persp)))
    (if (null persp)
        persp-nil-name
      (persp-name persp))))

(defun persp-fr-switch-nth (persp-num)
  "Switch to perspective number PERSP-NUM.
Perspectives are numbered from left to right starting with 1."
  (interactive "nperspective number: ")
  (let* ((persp-list (persp-names-current-frame-fast-ordered))
         (persp-list-length (length persp-list)))
    (if (and (<= 1 persp-num) (<= persp-num persp-list-length))
        (progn
          (persp-switch (nth (1- persp-num) persp-list))
          (message (format "switched to perspective %s" (nth (1- persp-num) persp-list))))
      (message "invalid perspective number"))))

(defun persp-fr-move-first ()
  "Move current perspective to the first place."
  (interactive)
  (let* ((name (persp-fr-current-name))
         (idx (-elem-index name persp-names-cache))
         (lst (-remove-at idx persp-names-cache)))
    (setq persp-names-cache (cons name lst)))
  (persp-fr-update))

(defun persp-fr-move-last ()
  "Move current perspective to the last place."
  (interactive)
  (let* ((name (persp-fr-current-name))
         (idx (-elem-index name persp-names-cache))
         (lst (-remove-at idx persp-names-cache)))
    (setq persp-names-cache (-snoc lst name)))
  (persp-fr-update))

(defun persp-fr-move-left ()
  "Move current perspective to the left."
  (interactive)
  (let* ((name (persp-fr-current-name))
         (idx (-elem-index name persp-names-cache))
         (lst (-remove-at idx persp-names-cache)))
    (setq persp-names-cache
          (if (= idx 0)
              (if persp-fr-move-cycle-at-end
                  (-snoc lst name)
                persp-names-cache)
            (-insert-at (- idx 1) name lst))))
  (persp-fr-update))

(defun persp-fr-move-right ()
  "Move current perspective to the right."
  (interactive)
  (let* ((cper (get-current-persp))
         (name (persp-fr-current-name))
         (idx (-elem-index name persp-names-cache))
         (lst (-remove-at idx persp-names-cache)))
    (setq persp-names-cache
          (if (= idx (length lst))
              (if persp-fr-move-cycle-at-end
                  (cons name lst)
                persp-names-cache)
            (-insert-at (+ idx 1) name lst))))
  (persp-fr-update))

;;;###autoload
(defun persp-fr-start ()
  "Start `persp-fr' mode.
This is exactly the same as `persp-mode', but perspective names
are shown in the frame title."
  (interactive)
  (cl-macrolet ((add-persp-hooks
                 (&rest hooks)
                 (let (code)
                   (dolist (hook hooks)
                     (push
                      `(add-hook
                        ',hook
                        #'(lambda (&rest rest)
                            (apply #'persp-fr-update ',hook rest)))
                      code))
                   `(progn ,@code))))
    (add-persp-hooks persp-before-kill-functions persp-activated-functions
                     persp-created-functions persp-renamed-functions
                     focus-in-hook))
  (persp-fr-update))

(provide 'persp-fr)
;;; persp-fr.el ends here
