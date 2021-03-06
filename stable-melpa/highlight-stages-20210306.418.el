;;; -*- lexical-binding: t -*-
;;; highlight-stages.el --- highlight staged (quasi-quoted) expressions

;; Copyright (C) 2014-2015 zk_phi

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

;; Author: zk_phi
;; URL: http://hins11.yu-yake.com/
;; Package-Version: 20210306.418
;; Package-Commit: 95daa710f3d8fc83f42c5da38003fc71ae0da1fc
;; Version: 1.1.0

;;; Commentary:

;; Require this script and call function "highlight-stages-global-mode"
;;
;;   (require 'highlight-stages)
;;   (highlight-stages-global-mode 1)

;; For more informations, see Readme.

;;; Change Log:

;; 1.0.0 first released
;; 1.0.1 turned into minor-mode
;; 1.0.2 add MetaOCaml support
;; 1.0.3 use faces instead of calculating background colors
;; 1.1.0 C/C++ preprocessor support

;;; Code:

(require 'cl-lib)

(defconst highlight-stages-version "1.1.0")

;; + customs

(defgroup highlight-stages nil
  "Highlight staged (quasi-quoted) expressions"
  :group 'emacs)

(defcustom highlight-stages-matcher-alist
  '((lisp-mode
     highlight-stages-lisp-quote-matcher . highlight-stages-lisp-escape-matcher)
    (emacs-lisp-mode
     highlight-stages-lisp-quote-matcher . highlight-stages-lisp-escape-matcher)
    (lisp-interaction-mode
     highlight-stages-lisp-quote-matcher . highlight-stages-lisp-escape-matcher)
    (scheme-mode
     highlight-stages-lisp-quote-matcher . highlight-stages-lisp-escape-matcher)
    (gauche-mode
     highlight-stages-lisp-quote-matcher . highlight-stages-lisp-escape-matcher)
    (racket-mode
     highlight-stages-lisp-quote-matcher . highlight-stages-lisp-escape-matcher)
    (clojure-mode
     highlight-stages-lisp-quote-matcher . highlight-stages-clojure-escape-matcher)
    (ocaml-mode
     highlight-stages-metaocaml-quote-matcher . highlight-stages-metaocaml-matcher-escape)
    (tuareg-mode
     highlight-stages-metaocaml-quote-matcher . highlight-stages-metaocaml-escape-matcher)
    (c-mode
     highlight-stages-c-preprocessor-matcher . nil)
    (c++-mode
     highlight-stages-c-preprocessor-matcher . nil)
    (objc-mode
     highlight-stages-c-preprocessor-matcher . nil))
  "List of (MAJOR-MODE . (QUOTE-MATCHER . [ESCAPE-MATCHER])).

QUOTE-MATCHER is a function with 1 parameter, LIMIT, which
searches the next quoted expression. The function must return
non-nil if succeeded, or nil otherwise. A special value 'real
also can be returned by the function, when the quote is
\"real\" (not escapable) quote. This may be useful for lisp-like
languages. When the function returns non-nil, (match-string 0)
must be the expression matched.

ESCAPE-MATCHER is a function with 1 parameter, LIMIT, which
searches the next escaped expression. The function must return
non-nil if succeeded, or nil otherwise. When the function returns
non-nil, (match-string 0) must be the expression matched."
  :type 'alist
  :group 'highlight-stages)

(defcustom highlight-stages-highlight-real-quote t
  "If non-nil, \"real\" (not escapable) quotes are also
  highlighted."
  :type 'boolean
  :group 'highlight-stages)

(defcustom highlight-stages-highlight-priority 1
  "Priority which highlight overlays get."
  :type 'integer
  :group 'highlight-stages)

;; + faces

(defface highlight-stages-negative-level-face
  '((((background light)) (:background "#fefaf1"))
    (t (:background "#003745")))
  "Face used to highlight staged expressions.")

(defface highlight-stages-level-1-face
  '((((background light)) (:background "#fbf1d4"))
    (t (:background "#001e26")))
  "Face used to highlight staged expressions.")

(defface highlight-stages-level-2-face
  '((((background light)) (:background "#faecc6"))
    (t (:background "#001217")))
  "Face used to highlight staged expressions.")

(defface highlight-stages-level-3-face
  '((((background light)) (:background "#f9e8b8"))
    (t (:background "#000608")))
  "Face used to highlight staged expressions.")

(defface highlight-stages-higher-level-face
  '((((background light)) (:background "#f8e3a9"))
    (t (:background "#000000")))
  "Face used to highlight staged expressions.")

;; + utils

(defun highlight-stages--face (level)
  "Choose a face for LEVEL."
  (cond ((< level 0) 'highlight-stages-negative-level-face)
        ((= level 1) 'highlight-stages-level-1-face)
        ((= level 2) 'highlight-stages-level-2-face)
        ((= level 3) 'highlight-stages-level-3-face)
        ((> level 3) 'highlight-stages-higher-level-face)))

(defun highlight-stages--make-overlay (beg end level)
  "Make a overlay. Trims existing overlays if necessary."
  ;; split or delete old overlay
  (dolist (ov (overlays-in beg end))
    (when (eq (overlay-get ov 'category) 'highlight-stages)
      (let ((ov-beg (overlay-start ov))
            (ov-end (overlay-end ov)))
        (cond ((and (< ov-beg beg) (< end ov-end))
               (move-overlay ov ov-beg beg)
               (move-overlay (copy-overlay ov) end ov-end))
              ((< ov-beg beg)
               (move-overlay ov ov-beg beg))
              ((< end ov-beg)
               (move-overlay ov end ov-end))
              (t
               (delete-overlay ov))))))
  ;; we don't need to make an overlay if (level = 0)
  (unless (zerop level)
    (let ((ov (make-overlay beg end)))
      (overlay-put ov 'face (highlight-stages--face level))
      (overlay-put ov 'category 'highlight-stages)
      (overlay-put ov 'priority highlight-stages-highlight-priority))))

(defun highlight-stages--search-forward-regexp (regexp &optional limit)
  "Like (search-forward-regexp REGEXP LIMIT t) but skips comments
  and strings."
  (let ((original-pos (point)) syntax)
    (catch 'found
      (while (search-forward-regexp regexp limit t)
        (setq syntax (save-match-data (syntax-ppss)))
        (when (and (not (nth 3 syntax))
                   (not (nth 4 syntax)))
          (throw 'found (point))))
      (goto-char original-pos)
      nil)))

;; + the jit highlighter

(defun highlight-stages-jit-highlighter (beg end)
  "The jit highlighter of highlight-stages."
  (setq beg (progn (goto-char beg)
                   (beginning-of-defun)
                   (skip-syntax-backward "'-") ; skip newlines?
                   (point))
        end (progn (goto-char end)
                   (end-of-defun)
                   (skip-syntax-forward "'-") ; skip newlines?
                   (point)))
  (remove-overlays beg end 'category 'highlight-stages)
  (highlight-stages--jit-highlighter-1 beg end 0))

(defun highlight-stages--jit-highlighter-1 (beg end base-level)
  "Scan and highlight this level."
  (highlight-stages--make-overlay beg end base-level)
  (goto-char beg)
  (let* ((pair (assq major-mode highlight-stages-matcher-alist))
         (quote-matcher (cadr pair))
         (escape-matcher (cddr pair))
         quote escape)
    (when quote-matcher
      (while (progn
               (setq quote (save-excursion
                             ;; 'real means "real" (non-"quasi") quote
                             (let ((res (funcall quote-matcher end)))
                               (cond ((eq res 'real)
                                      (cons (match-beginning 0) (cons (match-end 0) t)))
                                     (res
                                      (list (match-beginning 0) (match-end 0))))))
                     escape (save-excursion
                              (when (and escape-matcher (funcall escape-matcher end))
                                (list (match-beginning 0) (match-end 0)))))
               (or quote escape))
        (cond ((or (null escape)
                   (and quote (< (car quote) (car escape))))
               (save-excursion
                 (cond ((not (cddr quote))
                        ;; "quasi"-quote -> a staging operator (increment level)
                        (highlight-stages--jit-highlighter-1
                         (car quote) (cadr quote) (1+ base-level)))
                       ((not (zerop base-level))
                        ;; "real"-quote inside "quasi"-quote -> an ordinary symbol
                        (highlight-stages--jit-highlighter-1
                         (car quote) (cadr quote) base-level))
                       (t
                        ;; "real"-quote outside "quasi"-quote
                        (when highlight-stages-highlight-real-quote
                          (highlight-stages--make-overlay (car quote) (cadr quote) 1)))))
               (goto-char (cadr quote)))
              (t
               (save-excursion
                 (highlight-stages--jit-highlighter-1
                  (car escape) (cadr escape) (1- base-level)))
               (goto-char (cadr escape))))))))

;; + matchers for lisp

(defun highlight-stages-lisp-quote-matcher (&optional limit)
  (when (highlight-stages--search-forward-regexp
         "\\(?:`\\|\\(#?'\\)\\)\\|([\s\t\n]*\\(?:backquote\\|\\(quote\\)\\)[\s\t\n]+" limit)
    (prog1 (if (or (match-beginning 1) (match-beginning 2)) 'real t)
      (set-match-data
       (list (point)
             (progn (ignore-errors (forward-sexp 1)) (point)))))))

(defun highlight-stages-lisp-escape-matcher (&optional limit)
  (when (highlight-stages--search-forward-regexp ",@?\\|([\s\t\n]*\\\\,@?+[\s\t\n]+" limit)
    (set-match-data
     (list (point)
           (progn (ignore-errors (forward-sexp 1)) (point))))
    t))

;; + matchers for clojure

(defun highlight-stages-clojure-escape-matcher (&optional limit)
  (when (highlight-stages--search-forward-regexp "~@?" limit)
    (set-match-data
     (list (point)
	   (progn (ignore-errors (forward-sexp 1)) (point))))
    t))

;; + matchers for metaocaml

(defun highlight-stages-metaocaml-quote-matcher (&optional limit)
  (when (highlight-stages--search-forward-regexp "\\.<" limit)
    (let ((beg (point))
          (level 0))
      (while (and (highlight-stages--search-forward-regexp "\\(\\.<\\)\\|\\(>\\.\\)")
                  (progn (cond ((match-beginning 1)
                                (setq level (1+ level)))
                               ((match-beginning 2)
                                (setq level (1- level))))
                         (>= level 0))))
      (set-match-data
       (list beg
             (if (>= level 0) (point-max) (match-beginning 0))))
      t)))

(defun highlight-stages-metaocaml-escape-matcher (&optional limit)
  (when (highlight-stages--search-forward-regexp "\\.~" limit)
    (set-match-data
     (list (point)
           (cond ((looking-at "\\(\\s.\\|\\s_\\)+\\(?:[\s\t\n]\\|$\\)") ; not a sexp
                  (goto-char (match-end 1)))
                 (t
                  (ignore-errors (forward-sexp 1))
                  (point)))))
    t))

;; + matchers for C/C++/Objc

(defun highlight-stages-c-preprocessor-matcher (&optional limit)
  ;; we need to return 'real not to fall into an infinite recursion
  (and (highlight-stages--search-forward-regexp "^[\s\t]*#\\(?:.*\\\\\n\\)*.*$" limit)
       'real))

;; + the mode

;;;###autoload
(define-minor-mode highlight-stages-mode
  "Highlight staged (quasi-quoted) expressions"
  :init-value nil
  :lighter "Stg"
  :global nil
  (if highlight-stages-mode
      (jit-lock-register 'highlight-stages-jit-highlighter)
    (jit-lock-unregister 'highlight-stages-jit-highlighter)
    (remove-overlays (point-min) (point-max) 'category 'highlight-stages)))

;;;###autoload
(define-globalized-minor-mode highlight-stages-global-mode
  highlight-stages-mode
  (lambda () (highlight-stages-mode 1)))

;; + provide

(provide 'highlight-stages)

;;; highlight-stages.el ends here
