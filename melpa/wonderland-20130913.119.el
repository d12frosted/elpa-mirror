;;; wonderland.el --- declarative configuration for Emacsen -*- lexical-binding: t -*-

;; Copyright (c) 2013 Christina Whyte <kurisu.whyte@gmail.com>

;; Version: 0.1.1
;; Package-Version: 20130913.119
;; Package-Commit: 89d274ad694b0e748efdac23ccd60b7d8b73d7c6
;; Package-Requires: ((dash "2.0.0") (dash-functional "1.0.0") (multi "2.0.0") (emacs "24"))
;; Keywords: configuration profile wonderland
;; Author: Christina Whyte <kurisu.whyte@gmail.com>
;; URL: http://github.com/kurisuwhyte/emacs-wonderland

;; This file is not part of GNU Emacs.

;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;; 
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;; 
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.


;;; Commentary
;;
;; See README.md (or http://github.com/kurisuwhyte/emacs-wonderland#readme)

;;; Installation

;; ( TODO: ... )

;;; Code:
(eval-when-compile (require 'cl))
(require 'dash)
(require 'dash-functional)
(require 'multi)


;;;; State ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar wonderland/features (make-hash-table)
  "An map of Features registered for Wonderland.")


;;;; API ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defmacro wonderland/defeature (name &rest forms)
  (let ((feature (gensym)))
    `(let ((,feature (wonderland/-feature-from-forms ',name ',forms)))
       (puthash ',name ,feature wonderland/features)
       ,feature)))

(defun wonderland/load-feature (name)
  (let* ((feature      (gethash name wonderland/features))
         (full-profile (wonderland/-resolving-dependencies feature))
         (packages     (wonderland-feature-packages full-profile))
         (state        (wonderland-feature-state full-profile))
         (keymaps      (wonderland-feature-keymaps full-profile))
         (modes        (wonderland-feature-modes full-profile))
         (hooks        (wonderland-feature-hooks full-profile)))

    (-each packages 'wonderland/-package-load)
    (-each state    'wonderland/-define-state)
    (-each keymaps  'wonderland/-execute-keymap)
    (-each modes    'wonderland/-execute-pattern)
    (-each hooks    'wonderland/-attach-hook)
    full-profile))


;;;; Structs ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(cl-defstruct wonderland-feature
  name
  dependencies
  packages
  keymaps
  state
  modes
  hooks)

(cl-defstruct wonderland-dependency
  id)

(cl-defstruct wonderland-package
  id method url)

(cl-defstruct wonderland-state
  name value)

(cl-defstruct wonderland-mode-pattern
  pattern mode)

(cl-defstruct wonderland-hook
  name action)

(cl-defstruct wonderland-keymap
  mode keymap)


;;;; Dependencies ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun wonderland/-is-form-a-dependency? (form)
  (eq (car form) 'need))

(defun wonderland/-dependency-from-form (id)
  (make-wonderland-dependency :id id))

(defun wonderland/-resolving-dependencies (feature)
  (let ((deplist (-map 'wonderland/-feature-with-resolved-dependencies
                       (wonderland-feature-dependencies feature))))
    (-reduce-from 'wonderland/-merge-dependency feature deplist)))

(defun wonderland/-feature-with-resolved-dependencies (dependency)
  (wonderland/-resolving-dependencies
   (gethash (wonderland-dependency-id dependency) wonderland/features)))

(defun wonderland/-merge-dependency (feature dependency)
  (make-wonderland-feature
   :name         (wonderland-feature-name feature)
   :dependencies nil
   :packages     (-concat (wonderland-feature-packages dependency)
                          (wonderland-feature-packages feature))
   :keymaps      (-concat (wonderland-feature-keymaps dependency)
                          (wonderland-feature-keymaps feature))
   :state        (-concat (wonderland-feature-state dependency)
                          (wonderland-feature-state feature))
   :modes        (-concat (wonderland-feature-modes dependency)
                          (wonderland-feature-modes feature))
   :hooks        (-concat (wonderland-feature-hooks dependency)
                          (wonderland-feature-hooks feature))))


;;;; Packages ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun wonderland/-is-form-a-package? (form)
  (eq (car form) 'package))

(defun wonderland/-package-schema (name)
  (let ((pair (split-string name ":")))
    (cond
     ((= (length pair) 1)    (list 'elpa name))
     (:t                     pair))))

(defun wonderland/-package-from-form (id &optional url)
  (let ((schema (wonderland/-package-schema (or url ""))))
    (make-wonderland-package :id      id
                             :method  (car schema)
                             :url     (cadr schema))))

(defmulti wonderland/-package-load (pkg) (wonderland-package-method pkg))

(defmulti-method wonderland/-package-load 'elpa (pkg)
  (let ((id (wonderland-package-id pkg)))
    (unless (package-installed-p id)
      (package-install id)
      (require id))))


;;;; State ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun wonderland/-is-form-a-var? (form)
  (eq (car form) 'def))

(defun wonderland/-state-from-form (name value)
  (make-wonderland-state :name  name
                         :value value))

(defun wonderland/-define-state (state)
  (set (wonderland-state-name state)
       (wonderland-state-value state)))


;;;; Hooks ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun wonderland/-is-form-a-hook? (form)
  (eq (car form) 'hook))

(defun wonderland/-hook-from-form (name action)
  (make-wonderland-hook :name   name
                        :action action))

(defun wonderland/-attach-hook (hook)
  (add-hook (wonderland-hook-name hook)
            (wonderland-hook-action hook)))


;;;; Mode patterns ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun wonderland/-is-form-a-pattern? (form)
  (eq (car form) 'mode))

(defun wonderland/-pattern-from-form (mode pattern)
  (make-wonderland-mode-pattern :mode    mode
                                :pattern pattern))

(defun wonderland/-execute-pattern (pattern)
  (add-to-list 'auto-mode-alist
               (cons (wonderland-mode-pattern-pattern pattern)
                     (wonderland-mode-pattern-mode pattern))))


;;;; Keymap functions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun wonderland/-is-form-a-keymap? (form)
  (eq (car form) 'keymap))

(defun wonderland/-keymap-from-form (mode &rest keymap)
  (make-wonderland-keymap :mode   mode
                          :keymap keymap))

(defun wonderland/-execute-keymap (keymap)
  (let ((map  (wonderland-keymap-keymap keymap))
        (mode (wonderland-keymap-mode keymap)))
    (if (eq mode 'global)  (wonderland/-define-global-keymap map)
      (wonderland/-define-mode-keymap mode map))))

(defun wonderland/-define-global-keymap (keymap)
  (-each keymap (lambda (item)
                  (global-set-key (kbd (car item)) (cdr item)))))

(defun wonderland/-define-mode-keymap (mode keymap)
  (add-hook (concatenate-symbols mode '-hook)
            (lambda ()
              (-each keymap (lambda (item)
                              (local-set-key (kbd (car item)) (cdr item)))))))



;;;; Helper functions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun wonderland/-feature-from-forms (name forms)
  (make-wonderland-feature
   :name         name
   :dependencies (wonderland/-dependencies-from-forms forms)
   :packages     (wonderland/-packages-from-forms forms)
   :keymaps      (wonderland/-keymaps-from-forms forms)
   :state        (wonderland/-vars-from-forms forms)
   :modes        (wonderland/-modes-from-forms forms)
   :hooks        (wonderland/-hooks-from-forms forms)))


(defun wonderland/-extract-forms-with (forms filter-fn factory-fn)
  (->> forms
       (-filter filter-fn)
       (-map (lambda (xs) (apply factory-fn (cdr xs))))))

(defun wonderland/-dependencies-from-forms (forms)
  (wonderland/-extract-forms-with forms
                                  'wonderland/-is-form-a-dependency?
                                  'wonderland/-dependency-from-form))

(defun wonderland/-packages-from-forms (forms)
  (wonderland/-extract-forms-with forms
                                  'wonderland/-is-form-a-package?
                                  'wonderland/-package-from-form))

(defun wonderland/-vars-from-forms (forms)
  (wonderland/-extract-forms-with forms
                                  'wonderland/-is-form-a-var?
                                  'wonderland/-state-from-form))

(defun wonderland/-hooks-from-forms (forms)
  (wonderland/-extract-forms-with forms
                                  'wonderland/-is-form-a-hook?
                                  'wonderland/-hook-from-form))

(defun wonderland/-modes-from-forms (forms)
  (wonderland/-extract-forms-with forms
                                  'wonderland/-is-form-a-pattern?
                                  'wonderland/-pattern-from-form))

(defun wonderland/-keymaps-from-forms (forms)
  (wonderland/-extract-forms-with forms
                                  'wonderland/-is-form-a-keymap?
                                  'wonderland/-keymap-from-form))


;;;; General utility functions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun concatenate-symbols (&rest symbols)
  (intern (-reduce-from (lambda (result item)
                          (concat result (symbol-name item)))
                        "" symbols)))


;;;; Emacs syntax/indentation, etc ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(put 'wonderland/defeature 'lisp-indent-function 1)

(eval-after-load "lisp-mode"
  '(progn
     (font-lock-add-keywords 'emacs-lisp-mode
                             '(("\\<\\(wonderland/defeature\\)\\>" . 'font-lock-keyword-face)))
     (--each (buffer-list)
       (with-current-buffer it
         (when (and (eq major-mode 'emacs-lisp-mode)
                    (boundp 'font-lock-mode)
                    font-lock-mode)
           (font-lock-refresh-defaults))))))


(provide 'wonderland)
;;; wonderland.el ends here
