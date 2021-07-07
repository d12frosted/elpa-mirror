;;; evil-text-object-python.el --- Python specific evil text objects -*- lexical-binding: t; -*-

;; Author: Wouter Bolsterlee <wouter@bolsterl.ee>
;; Version: 1.0.1
;; Package-Version: 20191010.1328
;; Package-Commit: 39d22fc524f0413763f291267eaab7f4e7984318
;; Package-Requires: ((emacs "25") (evil "1.2.14") (dash "2.16.0"))
;; Keywords: convenience languages tools
;; URL: https://github.com/wbolster/evil-text-object-python
;;
;; This file is not part of GNU Emacs.

;;; License:

;; Licensed under the same terms as Emacs.

;;; Commentary:

;; This package provides text objects for Python statements for use
;; with evil-mode.  See the README for more details.

;;; Code:

(require 'dash)
(require 'evil)
(require 'python)

(defgroup evil-text-object-python nil
  "Evil text objects for Python"
  :prefix "evil-text-object-python-"
  :group 'evil)

(defcustom evil-text-object-python-statement-key "l"
  "Key to use for a Python statement in the text object maps."
  :type 'string
  :group 'evil-text-object-python)

(defcustom evil-text-object-python-function-key "f"
  "Key to use for a Python function in the text object maps."
  :type 'string
  :group 'evil-text-object-python)

(defun evil-text-object-python--detect-key(containing-map child)
  "Detect which key in CONTAINING-MAP maps to CHILD."
  ;; Note: this only uses the single match.
  (key-description (car (where-is-internal child containing-map))))

(defun evil-text-object-python--define-key (key text-objects-map text-object)
  "Bind KEY in TEXT-OBJECTS-MAP to TEXT-OBJECT."
  ;; Note: this only defines keys in local keymaps and does not change
  ;; the global text object maps. First detect the prefixes used in
  ;; the global maps (defaults are "i" for the inner text objects map,
  ;; and "a" for the outer text objects map), and use the same prefix
  ;; for the local bindings.
  (define-key evil-operator-state-local-map
    (kbd (format "%s %s" (evil-text-object-python--detect-key evil-operator-state-map text-objects-map) key))
    text-object)
  (define-key evil-visual-state-local-map
    (kbd (format "%s %s" (evil-text-object-python--detect-key evil-visual-state-map text-objects-map) key))
    text-object))

(defun evil-text-object-python--make-text-object (count type)
  "Helper to make text object for COUNT Python statements of TYPE."
  (let ((beg (save-excursion
               (python-nav-beginning-of-statement)
               (when (or (eq this-command 'evil-delete) (eq type 'line))
                 (beginning-of-line))
               (point)))
        (end (save-excursion
               (--dotimes (1- count)
                 (python-nav-forward-statement))
               (python-nav-end-of-statement)
               (when (eq type 'line)
                 (forward-line))
               (point))))
    (evil-range beg end)))

(defun evil-text-object-python--make-func-text-object (count type)
  "Helper to make text object for COUNT Python statements of TYPE."
  (let ((beg (save-excursion
               (python-nav-backward-defun)
               (when (or (eq this-command 'evil-delete) (eq type 'line))
                 (beginning-of-line))
               (point)))
        (end (save-excursion
               (--dotimes (1- count)
                 (python-nav-forward-defun))
               (python-nav-end-of-defun)
               (when (eq type 'line)
                 (forward-line))
               (point))))
    (evil-range beg end)))

;;;###autoload (autoload 'evil-text-object-python-inner-statement "evil-text-object-python" nil t)
(evil-define-text-object evil-text-object-python-inner-statement (count &optional beg end type)
  "Inner text object for the Python statement under point."
  (evil-text-object-python--make-text-object count type))

;;;###autoload (autoload 'evil-text-object-python-outer-statement "evil-text-object-python" nil t)
(evil-define-text-object evil-text-object-python-outer-statement (count &optional beg end type)
  "Outer text object for the Python statement under point."
  :type line
  (evil-text-object-python--make-text-object count type))

;;;###autoload (autoload 'evil-text-object-python-function "evil-text-object-python" nil t)
(evil-define-text-object evil-text-object-python-function (count &optional beg end type)
  "Inner text object for the Python statement under point."
  (evil-text-object-python--make-func-text-object count type))

;;;###autoload
(defun evil-text-object-python-add-bindings ()
  "Add text object key bindings.

This function should be added to a major mode hook.  It modifies
buffer-local keymaps and adds bindings for Python text objects for
both operator state and visual state."
  (interactive)
  (when evil-text-object-python-statement-key
    (evil-text-object-python--define-key
     evil-text-object-python-statement-key
     evil-inner-text-objects-map
     'evil-text-object-python-inner-statement)
    (evil-text-object-python--define-key
     evil-text-object-python-statement-key
     evil-outer-text-objects-map
     'evil-text-object-python-outer-statement))
  (when evil-text-object-python-function-key
    (evil-text-object-python--define-key
     evil-text-object-python-function-key
     evil-inner-text-objects-map
     'evil-text-object-python-function)))

(provide 'evil-text-object-python)
;;; evil-text-object-python.el ends here
