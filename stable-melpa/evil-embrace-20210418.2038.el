;;; evil-embrace.el --- Evil integration of embrace.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Junpeng Qiu

;; Author: Junpeng Qiu <qjpchmail@gmail.com>
;; Package-Requires: ((emacs "24.4") (embrace "0.1.0") (evil-surround "0"))
;; Package-Version: 20210418.2038
;; Package-Commit: 464e8ec52ff78edf3c9060143fc375f6ce5f275f
;; Keywords: extensions

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

;;                              ______________

;;                               EVIL-EMBRACE

;;                               Junpeng Qiu
;;                              ______________


;; Table of Contents
;; _________________

;; 1 Overview
;; 2 Why
;; 3 Usage
;; 4 Screencasts


;; Evil integration of [embrace.el].


;; [embrace.el] https://github.com/cute-jumper/embrace.el


;; 1 Overview
;; ==========

;;   This package provides evil integration of [embrace.el]. Since
;;   `evil-surround' provides a similar set of features as `embrace.el',
;;   this package aims at adding the goodies of `embrace.el' to
;;   `evil-surround' and making `evil-surround' even better.


;; [embrace.el] https://github.com/cute-jumper/embrace.el


;; 2 Why
;; =====

;;   `evil-surround' is good when there is a text object defined. But
;;   unfortunately, if you want to add custom surrouding pairs,
;;   `evil-surround' will not be able to delete/change the pairs if there
;;   are no evil text objects defined for these pairs. For example, if you
;;   want to make `\textbf{' and `}' as a surround pair in `LaTeX-mode',
;;   you can't either change or delete the surround pair since there is no
;;   text object for `\textbf{' and `}'. However, using `embrace', you can
;;   define whatever surrounding pairs you like, and adding, changing, and
;;   deleting will *always* work.

;;   The idea of this package is that let `evil-surround' handle the keys
;;   that corresponds to existing text objects (i.e., `(', `[', etc.),
;;   which is what `evil-surround' is good at, and make `embrace' handles
;;   all the other keys of custom surrounding pairs so that you can also
;;   benefit from the extensibility that `embrace' offers.

;;   In a word, you can use the default `evil-surround'. But whenever you
;;   want to add a custom surrounding pair, use `embrace' instead. To see
;;   how to add a custom pair in `embrace', look at the README of
;;   [embrace.el].


;; [embrace.el] https://github.com/cute-jumper/embrace.el


;; 3 Usage
;; =======

;;   To enable the `evil-surround' integration:
;;   ,----
;;   | (evil-embrace-enable-evil-surround-integration)
;;   `----

;;   And use `evil-embrace-disable-evil-surround-integration' to disable
;;   whenever you don't like it.

;;   The keys that are processed by `evil-surround' are saved in the
;;   variable `evil-embrace-evil-surround-keys'. The default value is:
;;   ,----
;;   | (?\( ?\[ ?\{ ?\) ?\] ?\} ?\" ?\' ?< ?> ?b ?B ?t ?w ?W ?s ?p)
;;   `----

;;   Note that this variable is buffer-local. You should change it in the
;;   hook:
;;   ,----
;;   | (add-hook 'LaTeX-mode-hook
;;   |     (lambda ()
;;   |        (add-to-list 'evil-embrace-evil-surround-keys ?o)))
;;   `----

;;   Only these keys saved in the variable are processed by
;;   `evil-surround', and all the other keys will be processed by
;;   `embrace'.

;;   If you find the help message popup annoying, use the following code to
;;   disable it:
;;   ,----
;;   | (setq evil-embrace-show-help-p nil)
;;   `----


;; 4 Screencasts
;; =============

;;   Use the following settings:
;;   ,----
;;   | (add-hook 'org-mode-hook 'embrace-org-mode-hook)
;;   | (evil-embrace-enable-evil-surround-integration)
;;   `----

;;   In an org-mode file, we can change the surrounding pair in the
;;   following way (note that this whole process can't be achieved solely
;;   by `evil-surround'):

;;   [./screencasts/evil-embrace.gif]

;;; Code:

(require 'embrace)
(require 'evil-surround)

(defvar evil-embrace-show-help-p t
  "Whether to show the help or not.")

(defvar evil-embrace-evil-surround-keys '(?\( ?\[ ?\{ ?\) ?\] ?\} ?\" ?\' ?< ?> ?b ?B ?t ?\C-\[ ?w ?W ?s ?p)
  "Keys that should be processed by `evil-surround'")
(make-variable-buffer-local 'evil-embrace-evil-surround-keys)

;; ----------- ;;
;; help system ;;
;; ----------- ;;
(defface evil-embrace-section-title-face
  '((t .  (:inherit font-lock-doc-face)))
  "Face for section title."
  :group 'embrace)

(defun evil-embrace--get-help-string ()
  (let ((evil-keys evil-embrace-evil-surround-keys)
        (extra-keys
         (cl-set-difference (mapcar #'car embrace--pairs-list)
                            evil-embrace-evil-surround-keys))
        evil-list extra-list)
    (dolist (k evil-embrace-evil-surround-keys)
      (let (key value)
        (if (char-equal ?\C-\[ k)
            (setq key "ESC"
                  value "quit")
          (setq key (format "%c" k)
                value
                (car (last
                      (split-string
                       (symbol-name
                        (lookup-key evil-inner-text-objects-map key))
                       "-")))))
        (push (list
               (propertize key 'face 'embrace-help-key-face)
               (propertize embrace-help-separator 'face 'embrace-help-separator-face)
               (propertize value 'face 'embrace-help-mark-func-face))
              evil-list)))
    (setq extra-list
          (mapcar (lambda (k)
                    (embrace--pair-struct-to-keys
                     (assoc-default k embrace--pairs-list)))
                  extra-keys))
    (concat (propertize "evil-surround" 'face 'evil-embrace-section-title-face)
            "\n"
            (embrace--create-help-string evil-list)
            "\n"
            (propertize "evil-embrace" 'face 'evil-embrace-section-title-face)
            "\n"
            (embrace--create-help-string extra-list))))

(defun evil-embrace--show-pair-help-buffer ()
  (and evil-embrace-show-help-p
       (embrace--show-help-buffer (evil-embrace--get-help-string))))

;; --------------------------- ;;
;; `evil-surround' integration ;;
;; --------------------------- ;;
(defvar evil-embrace--evil-surround-region-def (symbol-function 'evil-surround-region))

(evil-define-operator evil-embrace-evil-surround-region (beg end type char &optional force-new-line)
  (interactive "<R>c")
  (if (member char evil-embrace-evil-surround-keys)
      (funcall evil-embrace--evil-surround-region-def beg end type char
               force-new-line)
    (embrace--add-internal beg end char)))

(defun evil-embrace-evil-surround-delete (char &optional outer inner)
  (interactive "c")
  (cond
   ((and outer inner)
    (delete-region (overlay-start outer) (overlay-start inner))
    (delete-region (overlay-end inner) (overlay-end outer))
    (goto-char (overlay-start outer)))
   (t
    (if (member char evil-embrace-evil-surround-keys)
        (let* ((outer (evil-surround-outer-overlay char))
               (inner (evil-surround-inner-overlay char)))
          (unwind-protect
              (when (and outer inner)
                (evil-surround-delete char outer inner))
            (when outer (delete-overlay outer))
            (when inner (delete-overlay inner))))
      (embrace--delete char)))))

(defun evil-embrace-evil-surround-change (char &optional outer inner)
  (interactive "c")
  (let (overlay)
    (cond
     ((and outer inner)
      (unless (evil-surround-delete-char-noop-p char)
        (evil-surround-delete char outer inner))
      (let ((key (read-char)))
        (if (member key evil-embrace-evil-surround-keys)
            (evil-surround-region (overlay-start outer)
                                  (overlay-end outer)
                                  nil (if (evil-surround-valid-char-p key) key char))
          (embrace--insert key (copy-overlay outer)))))
     (t
      (if (member char evil-embrace-evil-surround-keys)
          (let* ((outer (evil-surround-outer-overlay char))
                 (inner (evil-surround-inner-overlay char)))
            (unwind-protect
                (when (and outer inner)
                  (evil-surround-change char outer inner))
              (when outer (delete-overlay outer))
              (when inner (delete-overlay inner))))
        (setq overlay (embrace--delete char t))
        (let ((key (read-char)))
          (if (member key evil-embrace-evil-surround-keys)
              (evil-surround-region (overlay-start overlay)
                                    (overlay-end overlay)
                                    nil (if (evil-surround-valid-char-p key) key char))
            (embrace--insert key overlay))
          (when overlay (delete-overlay overlay))))))))

(defun evil-embrace-show-help-advice (orig-func &rest args)
  (evil-embrace--show-pair-help-buffer)
  (unwind-protect
      (apply orig-func args)
    (embrace--hide-help-buffer)))

;;;###autoload
(defun evil-embrace-enable-evil-surround-integration ()
  (interactive)
  (advice-add 'evil-surround-region :override 'evil-embrace-evil-surround-region)
  (advice-add 'evil-surround-change :override 'evil-embrace-evil-surround-change)
  (advice-add 'evil-surround-delete :override 'evil-embrace-evil-surround-delete)
  (advice-add 'evil-surround-edit :around 'evil-embrace-show-help-advice)
  (advice-add 'evil-Surround-edit :around 'evil-embrace-show-help-advice))

;;;###autoload
(defun evil-embrace-disable-evil-surround-integration ()
  (interactive)
  (advice-remove 'evil-surround-region 'evil-embrace-evil-surround-region)
  (advice-remove 'evil-surround-change 'evil-embrace-evil-surround-change)
  (advice-remove 'evil-surround-delete 'evil-embrace-evil-surround-delete)
  (advice-remove 'evil-surround-edit 'evil-embrace-show-help-advice)
  (advice-remove 'evil-Surround-edit 'evil-embrace-show-help-advice))

(provide 'evil-embrace)
;;; evil-embrace.el ends here
