;;; evil-extra-operator.el --- Evil operator for evaluating codes, taking notes, searching via google, etc.

;; Copyright (C) 2014-2021 by Dewdrops

;; Author: Dewdrops <v_v_4474@126.com>
;; URL: http://github.com/Dewdrops/evil-extra-operator
;; Package-Version: 20210225.1239
;; Package-Commit: fb249889acacc3e28869491195391fa6f617ae56
;; Version: 0.2
;; Keywords: evil, plugin
;; Package-Requires: ((evil "1.0.7"))

;; This file is NOT part of GNU Emacs.

;;; License:
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package provides some extra operators for Emacs Evil, to evaluate codes,
;; search via google, translate text, folding region, etc.
;;
;; Commands provided by this package:
;; evil-operator-eval, evil-operator-google-translate,
;; evil-operator-google-search, evil-operator-highlight, evil-operator-fold,
;; evil-operator-org-capture, evil-operator-remember, evil-operator-clone,
;; evil-operator-query-replace
;;
;; Installation:
;;
;; put evil-extra-operator.el somewhere in your load-path and add these
;; lines to your .emacs:
;; (require 'evil-extra-operator)
;; (global-evil-extra-operator-mode 1)

;;; Code:

(require 'evil)

(defgroup evil-extra-operator nil
  "Extra operator for evil"
  :prefix "evil-extra-operator"
  :group 'evil)

(defcustom evil-extra-operator-google-translate-key (kbd "g.")
  "Default binding for evil-operator-google-translate."
  :type 'key-sequence
  :group 'evil-extra-operator)

(defcustom evil-extra-operator-google-search-key (kbd "gG")
  "Default binding for evil-operator-google-search."
  :type 'key-sequence
  :group 'evil-extra-operator)

(defcustom evil-extra-operator-eval-key (kbd "gr")
  "Default binding for evil-operator-eval."
  :type 'key-sequence
  :group 'evil-extra-operator)

(defcustom evil-extra-operator-highlight-key (kbd "gh")
  "Default binding for evil-operator-highlight."
  :type 'key-sequence
  :group 'evil-extra-operator)

(defcustom evil-extra-operator-fold-key (kbd "gs")
  "Default binding for evil-operator-fold."
  :type 'key-sequence
  :group 'evil-extra-operator)

(defcustom evil-extra-operator-org-capture-key (kbd "go")
  "Default binding for evil-operator-org-capture."
  :type 'key-sequence
  :group 'evil-extra-operator)

(defcustom evil-extra-operator-remember-key (kbd "gR")
  "Default binding for evil-operator-remember"
  :type 'key-sequence
  :group 'evil-extra-operator)

(defcustom evil-extra-operator-eval-modes-alist
  '((lisp-mode slime-eval-region)
    (scheme-mode geiser-eval-region)
    (clojure-mode cider-eval-region)
    (ruby-mode ruby-send-region)
    (enh-ruby-mode ruby-send-region)
    (python-mode python-shell-send-region)
    (julia-mode julia-shell-run-region))
  "Alist used to determine evil-operator-eval's behaviour.
Each element of this alist should be of this form:

 (MAJOR-MODE EVAL-FUNC [ARGS...])

MAJOR-MODE denotes the major mode of buffer. EVAL-FUNC should be a function
with at least 2 arguments: the region beginning and the region end. ARGS will
be passed to EVAL-FUNC as its rest arguments"
  :type '(alist :key-type symbol)
  :group 'evil-extra-operator)

(defcustom evil-extra-operator-eval-replace-modes-alist
  '()
  "Alist used to determine evil-operator-eval-replace's behaviour.
Each element of this alist should be of this form:

 (MAJOR-MODE EVAL-FUNC [ARGS...])

MAJOR-MODE denotes the major mode of buffer. EVAL-FUNC should be a function
with at least 2 arguments: the region beginning and the region end. ARGS will
be passed to EVAL-FUNC as its rest arguments"
  :type '(alist :key-type symbol)
  :group 'evil-extra-operator)

;;;###autoload
(autoload 'evil-operator-eval "evil-extra-operator"
  "Evil operator for evaluating code." t)
;;;###autoload
(autoload 'evil-operator-google-translate "evil-extra-operator"
  "Evil operator for translating text via google translate." t)
;;;###autoload
(autoload 'evil-operator-google-search "evil-extra-operator"
  "Evil operator for google search." t)
;;;###autoload
(autoload 'evil-operator-highlight "evil-extra-operator"
  "Evil operator for region highlight." t)
;;;###autoload
(autoload 'evil-operator-fold "evil-extra-operator"
  "Evil operator for folding region." t)
;;;###autoload
(autoload 'evil-operator-org-capture "evil-extra-operator"
  "Evil operator for org-capture." t)
;;;###autoload
(autoload 'evil-operator-remember "evil-extra-operator"
  "Evil operator for remember-region" t)
;;;###autoload
(autoload 'evil-operator-query-replace "evil-extra-operator"
  "Evil operator to query and replace a region throughout the current buffer" t)
;;;###autoload
(autoload 'evil-operator-clone "evil-extra-operator"
  "Evil operator to create a clone of a motion" t)

(evil-define-operator evil-operator-eval-replace (beg end)
  "Evil operator for replacing contents with result from eval."
  :move-point nil
  (interactive "<r>")
  (let* ((ele (assoc major-mode evil-extra-operator-eval-replace-modes-alist))
         (f-a (cdr-safe ele))
         (func (car-safe f-a))
         (args (cdr-safe f-a))
         (text (buffer-substring-no-properties beg end))
         (result (if (fboundp func)
                     (apply func beg end args)
                   (format "%s" (eval (read text))))))
    (delete-region beg end)
    (insert result)))

(evil-define-operator evil-operator-eval (beg end)
  "Evil operator for evaluating code."
  :move-point nil
  (interactive "<r>")
  (let* ((ele (assoc major-mode evil-extra-operator-eval-modes-alist))
         (f-a (cdr-safe ele))
         (func (car-safe f-a))
         (args (cdr-safe f-a)))
    (if (fboundp func)
        (apply func beg end args)
      (eval-region beg end t))))

(evil-define-operator evil-operator-google-translate (beg end type)
  "Evil operator for translating text via google translate."
  :move-point nil
  (interactive "<R>")
  (unless (require 'google-translate nil t)
    (error "You must install the google-translate package to use evil-operator-google-translate"))
  (let* ((langs (google-translate-read-args nil nil))
         (source-language (car langs))
         (target-language (cadr langs)))
    (google-translate-translate
     source-language target-language
     (.eeo/make-url-args beg end type))))

(evil-define-operator evil-operator-google-search (beg end type)
  "Evil operator for google search."
  :move-point nil
  (interactive "<R>")
  (browse-url
   (concat "http://www.google.com/search?q="
           (url-hexify-string
            (.eeo/make-url-args beg end type)))))

(defun .eeo/make-url-args (beg end type)
  (if (eq type 'block)
      (let ((s nil))
        (evil-apply-on-block
         (lambda (b e) (setq s (cons (buffer-substring b e) s)))
         beg end nil)
        (mapconcat 'identity (nreverse s) " "))
    (buffer-substring beg end)))

(evil-define-operator evil-operator-highlight (beg end type)
  "Evil operator for region highlight."
  :move-point nil
  (interactive "<R>")
  (unless (require 'highlight nil t)
    (error "You must install the highlight package to use evil-operator-highlight"))
  (if (eq type 'block)
      (evil-apply-on-block #'hlt-highlight-region beg end nil)
    (hlt-highlight-region beg end)))

(evil-define-operator evil-operator-fold (beg end type)
  "Evil operator for folding region."
  :move-point nil
  (interactive "<R>")
  (unless (require 'fold-this nil t)
    (error "You must install the fold-this package to use evil-operator-fold"))
  (if (eq type 'block)
      (evil-apply-on-block #'fold-this beg end nil)
    (fold-this beg end)))

(evil-define-operator evil-operator-org-capture (beg end)
  "Evil operator for org-capture."
  (interactive "<r>")
  (unless (require 'org nil t)
    (error "You must install the org package to use evil-operator-org-capture"))
  (unless (region-active-p)
    (goto-char beg)
    (set-mark-command nil)
    (goto-char end))
  (org-capture))

(evil-define-operator evil-operator-remember (beg end type)
  "Evil operator for remember-region"
  :move-point nil
  (interactive "<R>")
  (unless (require 'remember nil t)
    (error "You must install the remember package to use evil-operator-remember"))
  (let* ((s nil)
         (cont
          (if (eq type 'block)
              (progn
                (evil-apply-on-block
                 (lambda (b e)
                   (setq s (cons (buffer-substring b e) s)))
                 beg end nil)
                (mapconcat 'identity (nreverse s) "\n"))
            (buffer-substring beg end))))
    (with-temp-buffer
      (insert cont)
      (if remember-all-handler-functions
          (run-hooks 'remember-handler-functions)
        (run-hook-with-args-until-success 'remember-handler-functions))
      (remember-destroy))))

(evil-define-operator evil-operator-query-replace (beg end type)
  "Evil operator to query and replace a region throughout the current buffer"
  :move-point nil
  (interactive "<r>")
  (let ((replaced-string (buffer-substring beg end))
        (replacement-str (read-string "Replace with:")))
    (goto-char (point-min))
    (query-replace (regexp-quote replaced-string) replacement-str)
    (kill-new replaced-string)))

(evil-define-operator evil-operator-clone (beg end type)
  "Evil operator to create a clone of a motion"
  :move-point nil
  (interactive "<r>")
  (let* (
        (content (buffer-substring beg end))
        (contains-new-line (not (null (string-match "\n" content))))
        (ends-with-newline (not (null (string-match "\n\\'" content))))
        (new-line-spec (list contains-new-line ends-with-newline)))
    (goto-char beg)
    (insert
     (cond
      ((equal new-line-spec '(t t)) content)
      ((equal new-line-spec '(t nil)) (concat content "\n"))
      ((equal new-line-spec '(nil nil)) content)
      (t content)))))


;;;###autoload
(define-minor-mode evil-extra-operator-mode
  "Buffer local minor mode to enable extra operators for Evil."
  :lighter ""
  :keymap (make-sparse-keymap)
  (evil-normalize-keymaps))

;;;###autoload
(defun evil-extra-operator-mode-install () (evil-extra-operator-mode 1))

;;;###autoload
(define-globalized-minor-mode global-evil-extra-operator-mode
  evil-extra-operator-mode evil-extra-operator-mode-install
  "Global minor mode of extra operator for Evil.")

(evil-define-key 'motion evil-extra-operator-mode-map
  evil-extra-operator-google-search-key
  'evil-operator-google-search)
(evil-define-key 'normal evil-extra-operator-mode-map
  evil-extra-operator-google-search-key
  'evil-operator-google-search)
(evil-define-key 'motion evil-extra-operator-mode-map
  evil-extra-operator-google-translate-key
  'evil-operator-google-translate)
(evil-define-key 'normal evil-extra-operator-mode-map
  evil-extra-operator-google-translate-key
  'evil-operator-google-translate)
(evil-define-key 'motion evil-extra-operator-mode-map
  evil-extra-operator-eval-key
  'evil-operator-eval)
(evil-define-key 'normal evil-extra-operator-mode-map
  evil-extra-operator-eval-key
  'evil-operator-eval)
(evil-define-key 'motion evil-extra-operator-mode-map
  evil-extra-operator-remember-key
  'evil-operator-remember)
(evil-define-key 'normal evil-extra-operator-mode-map
  evil-extra-operator-remember-key
  'evil-operator-remember)
(evil-define-key 'motion evil-extra-operator-mode-map
  evil-extra-operator-org-capture-key
  'evil-operator-org-capture)
(evil-define-key 'normal evil-extra-operator-mode-map
  evil-extra-operator-org-capture-key
  'evil-operator-org-capture)
(evil-define-key 'motion evil-extra-operator-mode-map
  evil-extra-operator-highlight-key
  'evil-operator-highlight)
(evil-define-key 'normal evil-extra-operator-mode-map
  evil-extra-operator-highlight-key
  'evil-operator-highlight)
(evil-define-key 'motion evil-extra-operator-mode-map
  evil-extra-operator-fold-key
  'evil-operator-fold)
(evil-define-key 'normal evil-extra-operator-mode-map
  evil-extra-operator-fold-key
  'evil-operator-fold)

(provide 'evil-extra-operator)
;;; evil-extra-operator.el ends here
