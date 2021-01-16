;;; eta.el --- standard and multi dispatch key bind -*- lexical-binding: t -*-

;; Copyright (C) Chris Zheng

;; Author: Chris Zheng
;; Keywords: convenience, usability
;; Package-Version: 20210115.1655
;; Package-Commit: c7540ac50163f368fec1918dfc334304d9b36c51
;; Homepage: https://www.github.com/zcaudate/eta
;; Package-Requires: ((emacs "25.1") (ht "2.2") (dash "2.17"))
;; Version: 0.01

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Eta provides two macros for standardising and associating
;; intent with key-bindings: a standard version `eta-bind` and
;; multi-dispatch version for standardisation of functionality across
;; major modes: `eta-modal-init` and `eta-modal`
;;

;;; Requirements:
(require 'ht)    ;; maps
(require 'seq)
(require 'dash)

;;; Code:

(defvar eta-var-lock nil)
(defvar eta-var-commands        (ht-create))
(defvar eta-var-modal-bindings  (ht-create))
(defvar eta-var-modal-functions (ht-create))
(defvar eta-var-modal-lookup    (ht-create))
(defvar eta-var-meta-config     "ESC 0")

(defun eta-put-command (key fn)
  "Gets a command from hashtable.
Argument KEY the command key.
Argument FN the command function."
  (if (and eta-var-lock
           (ht-get eta-var-commands key))
      (error (concat "key " (symbol-name key) " already exists"))
    (ht-set eta-var-commands key fn)))

(defun eta-get-command (key)
  "Gets a command function given KEY."
  (gethash key eta-var-commands))

;;
;; eta-bind
;;

(defun eta-bind-fn (declaration &rest specs)
  "Function to generate bind form.
Argument DECLARATION either *, <map> or empty.
Optional argument SPECS the actual bindings."
  (-let* ((bind-map (if (seq-empty-p declaration)
                        nil
                      (seq-elt declaration 0)))
          (body (seq-mapcat (lambda (spec)
                              (-let [(key bindings fn) spec]
                                (when fn
                                  (eta-put-command key (cadr fn))
                                  (seq-map (lambda (binding)
                                             `(progn ,(cond ((eq bind-map '*) `(bind-key* ,binding ,fn))
                                                            (bind-map  `(bind-key ,binding ,fn ,bind-map))
                                                            (t  `(bind-key ,binding ,fn)))
                                                     (vector ,key ,binding ,fn)))
                                           bindings))))
                            (seq-partition specs 3))))
    (cons 'list body)))

(defmacro eta-bind (declaration &rest specs)
  "Actual binding macro.
Argument DECLARATION ethier [*], <map> or [].
Optional argument SPECS the actual bindings."
  (declare (indent 1))
  (apply 'eta-bind-fn declaration specs))

;;
;; setup for eta-modal
;;
(defun eta-modal-key ()
  "The keys for a mode."
  (ht-get eta-var-modal-lookup major-mode))


(defun eta-modal-dispatch (fn-key &rest args)
  "Function for mode dispatch.
Argument FN-KEY the function key.
Optional argument ARGS function arguments."
  (let* ((mode-key (ht-get eta-var-modal-lookup major-mode))
         (fn-table (if mode-key
                       (ht-get eta-var-modal-functions mode-key)))
         (fn       (if fn-table
                       (ht-get fn-table fn-key))))
    (if fn
        (apply 'funcall fn args)
      (error (concat "Function unavailable ("
                       (symbol-name mode-key)
                       " "
                       (symbol-name fn-key) ")")))))

;;
;; eta-modal-init
;;

(defun eta-modal-init-create-mode-fn (fn-key bindings params)
  "Create a multi function.
Argument FN-KEY the function key.
Argument BINDINGS the bindings for the key.
Argument PARAMS function params."
  (-let* ((fn-name (intern (concat "eta-modal-fn"
                                   (symbol-name fn-key))))
          (args    (seq-map 'intern params)))
    (ht-set eta-var-modal-bindings fn-key bindings)
    `(progn (defun ,fn-name (,@args)
              (interactive ,@params)
              (eta-modal-dispatch ,fn-key ,@args))
            (eta-bind nil ,fn-key ,bindings (quote ,fn-name)))))

(defun eta-modal-init-form (declaration &rest specs)
  "Initialises the mode form.
Argument DECLARATION The mode form.
Optional argument SPECS the mode specs."
  (-let ((body (seq-map (lambda (args)
                          (apply 'eta-modal-init-create-mode-fn args))
                        (seq-partition specs 3))))
    (cons 'progn body)))

(defmacro eta-modal-init (declaration &rest specs)
  "The init macro.
Argument DECLARATION The mode-init-macro.
Optional argument SPECS the mode specs."
  (declare (indent 1))
  (apply 'eta-modal-init-form declaration specs))

;;
;; eta-modal
;;

(defun eta-modal-create-config-fn (mode-key mode-name mode-config)
  "The associated config file.
Argument MODE-KEY the key of the mode.
Argument MODE-NAME the mode name.
Argument MODE-CONFIG the mode config."
  (-let* ((fn-name   (intern (concat "eta-modal-config"
                                     (symbol-name mode-key))))
          (mode-map  (intern (concat (symbol-name mode-name) "-map"))))
    `(progn
       (defun ,fn-name ()
         (interactive)
         (eta-jump-to-config ,mode-config))
       (bind-key eta-var-meta-config (quote ,fn-name) ,mode-map))))

(defun eta-modal-form (declaration &rest specs)
  "The mode form.
Argument DECLARATION mode declaration.
Optional argument SPECS mode specs."
  (-let* (([mode-key mode-name &rest more] declaration)
          (mode-file-name (if (not (seq-empty-p more)) (seq-elt more 0)))
          (mode-table (ht-create))
          (_    (ht-set eta-var-modal-functions mode-key mode-table))
          (_    (ht-set eta-var-modal-lookup mode-name mode-key))
          (conf-body (eta-modal-create-config-fn mode-key mode-name (or mode-file-name load-file-name)))
          (body      (seq-map (lambda (spec)
                               (-let* (((fn-key fn) spec)
                                       (mode-fn-key (intern (concat (symbol-name fn-key) (symbol-name mode-key)))))
                                 (ht-set mode-table fn-key (cadr fn))))
                             (seq-partition specs 2))))
    conf-body))

(defmacro eta-modal (declaration config &rest specs)
  "The eta modal macro.
Argument DECLARATION The modal declaration.
Argument CONFIG the config.
Optional argument SPECS mode specs."
  (declare (indent 1))
  (apply 'eta-modal-form declaration config specs))

(provide 'eta)
;;; eta.el ends here
