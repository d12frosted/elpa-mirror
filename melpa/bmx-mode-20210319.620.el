;;; bmx-mode.el --- Batch Mode eXtras

;; Copyright (C) 2018 Jostein Kjønigsen

;; Author: Jostein Kjønigsen <jostein@gmail.com>
;; URL: http://github.com/josteink/bmx-mode
;; Package-Version: 20210319.620
;; Package-Commit: 6f008707efe0bb5646f0c1b0d6f57f0a8800e200
;; Version: 0.1
;; Keywords: c convenience tools
;; Package-Requires: ((emacs "25.1") (cl-lib "0.5") (company "0.9.4") (dash "2.13.0") (s "1.12.0"))

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Extend Emacs' bat-mode to support auto-completion, code-navigation and
;; refactoring capabilities.
;;
;; Once installed, add the following to your .emacs file to configure Emacs
;; and bmx-mode using the bmx-mode default-settings:
;;
;; (require 'bmx-mode)
;; (bmx-mode-setup-defaults)
;;
;; This minor-mode is all Elisp, and thus cross-platform and does not depend
;; on any native platform tools or host OS.

;;; Code:

(require 'company)
(require 'dash)
(require 's)
(require 'ring)

;;;
;;; customizations
;;;

(defgroup bmx-mode nil
  "bmx-mode: Extensions to Emacs' built-in bat-mode."
  :group 'prog-mode)

(defcustom bmx-include-system-variables nil
  "If enabled includes system-variables in variable-completion."
  :type 'boolean
  :group 'bmx-mode)

;;;
;;; utility functions
;;;

(defun bmx--label-normalize (name)
  (if (string-equal (substring-no-properties name 0 1) ":")
      name
    (concat ":" name)))

(defun bmx--label-unnormalize (name)
  (if (string-equal (substring-no-properties name 0 1) ":")
      (substring-no-properties name 1)
    name))

(defun bmx--variable-normalize (name)
  (if (string-equal (substring-no-properties name 0 1) "%")
      name
    (concat "%" name "%")))

(defun bmx--variable-unnormalize (name)
  (if (string-equal (substring-no-properties name 0 1) "%")
      (substring-no-properties name 1 (- (length name) 1))
    name))

(defun bmx--read-input (prompt)
  (if (fboundp 'read-input)
      (read-input prompt)
    (read-string prompt)))

;;;
;;; consts
;;;

(defconst bmx--rx-label-invocation "\\<\\(call\\|goto\\)\s+\\(:?[[:alnum:]_]*\\)")
(defconst bmx--rx-label-declaration "^\\(:[[:alnum:]_]+\\)\\>")

;;;
;;; labels
;;;

(defun bmx--get-labels ()
  (save-excursion
    (goto-char (point-min))

    (let ((result))
      (while (search-forward-regexp bmx--rx-label-declaration nil t nil)
        (add-to-list 'result (match-string-no-properties 1)))

      (sort result 'string-lessp))))

(defun bmx--get-matching-labels (prefix &optional label-list)
  (let ((prefixed (or label-list (bmx--get-labels))))
    (-filter (lambda (item)
               (s-prefix-p prefix item t))
             prefixed)))

(defun bmx-insert-colon-and-complete ()
  "Insert a colon, and initiate syntax-completion when appropriate."
  (interactive)
  (insert ?:)
  (when (looking-back bmx--rx-label-invocation nil)
    (company-manual-begin)))

(defun bmx--company-label-backend (command &optional arg &rest ignored)
  (case command
    (prefix (when
                (and (equal major-mode 'bat-mode)
                     (looking-back bmx--rx-label-invocation nil))
              (match-string 2)))
    (candidates (bmx--get-matching-labels arg))
    (meta (format "This value is named %s" arg))
    (ignore-case t)))

(defun bmx--company-completion-finished-hook (res)
  ;; when completing in front an existing statement like this:
  ;; some.exe params
  ;; call :CKRETsome.exe params
  ;; we may want to insert a space.
  (when (and
         (equal major-mode 'bat-mode)
         (equal ":" (substring-no-properties res 0 1))
         (not (looking-at-p "\s"))
         (not (looking-at-p "$")))
    (insert " ")))

(defun bmx--label-at-point ()
  (cond
   ;; cursor within label used in invocation invocation
   ((looking-back bmx--rx-label-invocation nil)
    (bmx--label-normalize
     (substring-no-properties
      (symbol-name
       (save-excursion
         (or (symbol-at-point)
             ;; in case we are at the :... in which case
             ;; symbol is nil
             (progn
               (forward-char 1)
               (symbol-at-point))))))))

   ;; cursor on keyword used in invocation
   ((or (string-equal "goto" (downcase (symbol-name (symbol-at-point))))
        (string-equal "call" (downcase (symbol-name (symbol-at-point)))))
    (save-excursion
      (search-forward-regexp "\s")
      (forward-word 1)
      (bmx--label-normalize
       (substring-no-properties
        (symbol-name
         (symbol-at-point))))))

   ;; else: label declaration
   ((save-excursion
      (beginning-of-line 1)
      (looking-at bmx--rx-label-declaration))
    (match-string-no-properties 1))

   ;; nada
   (t
    nil)))

(defun bmx--label-find-references (label)
  (let ((rx-label (regexp-quote label))
        (rx-unprefix (regexp-quote (bmx--label-unnormalize label))))

    (occur (concat "\\("
                   "^" rx-label "\\>" ;; any usage with :label and nothing/space after
                   ;; usage without : ... must look for keyword identifiers!
                   "\\|"
                   "\\(goto\\|call\\)\s+"
                   "\\(:?" rx-unprefix "\\)"
                   "\\)\\>"))))

(defun bmx--label-navigate-to (label)
  (xref-push-marker-stack)
  (goto-char (point-min))
  (search-forward-regexp (concat "^" (bmx--label-normalize (regexp-quote label)) "\s*$"))
  (beginning-of-line))

(defun bmx--label-rename-prompt (label)
  (let* ((old-unnormialized (bmx--label-unnormalize label))
         (new-name (bmx--read-input
                    (concat
                     "Enter new name for label '"
                     old-unnormialized
                     "': ")))
         (new-normalized (bmx--label-normalize new-name)))
    (cond
     ((string-equal "" new-name)
      (message "No name provided."))

     ((member new-normalized (bmx--get-labels))
      (when (yes-or-no-p (concat "Label '" new-name "' is already defined. Are you sure?"))
        (bmx--label-rename label new-normalized)))

     (t
      (bmx--label-rename label new-normalized)))))

(defun bmx--label-rename (label new-name)
  (undo-boundary)

  (let ((old-unnormalized (bmx--label-unnormalize label))
        (new-unnormalized (bmx--label-unnormalize new-name)))
    (message "Renaming label '%s' to '%s'..." old-unnormalized new-unnormalized)

    ;; rename declarations
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (concat "^:" (regexp-quote old-unnormalized) "\\>")
              nil t)
        (replace-match (concat ":" new-unnormalized ""))))

    ;; rename GOTO invocations
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (concat "goto\s+:?" (regexp-quote old-unnormalized) "\\>")
              nil t)
        (replace-match (concat "goto :" new-unnormalized))))

    ;; rename CALL invocations
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (concat "call\s+:?" (regexp-quote old-unnormalized) "\\>")
              nil t)
        (replace-match (concat "call :" new-unnormalized))))))

(defun bmx-fixup-labels ()
  "Ensure all label-usage is using a consistent casing and syntax."
  (interactive)
  (dolist (label (bmx--get-labels))
    (bmx--label-rename label label)))

;;;
;;; variables
;;;

(defun bmx--get-system-variables ()
  (mapcar (lambda (item)
            (bmx--variable-normalize
             (car (split-string item "="))))
          process-environment))

(defun bmx--get-variables (&optional no-system-variables)
  (save-excursion
    (goto-char (point-min))

    (let ((result))
      (when (and (not no-system-variables)
                 bmx-include-system-variables)
        (setq result (bmx--get-system-variables)))

      ;; regular unquoted syntax
      ;; set "var=value"
      (while (search-forward-regexp "\\<set\s+\\([a-zA-Z0-9_]+\\)\s*=.*" nil t nil)
        (add-to-list 'result (bmx--variable-normalize (match-string-no-properties 1))))

      ;; variables also support a quoted set syntax
      ;; set "var=value"
      (while (search-forward-regexp "\\<set\s+\"\\([a-zA-Z0-9_]+\\)\s*=.*\"" nil t nil)
        (add-to-list 'result (bmx--variable-normalize (match-string-no-properties 1))))

      (sort result 'string-lessp))))

(defun bmx--get-matching-variables (prefix &optional variables-list)
  (let ((variables (or variables-list (bmx--get-variables))))
    (-filter (lambda (item)
               (s-prefix-p prefix item t))
             variables)))

(defun bmx--company-variable-backend (command &optional arg &rest ignored)
  (case command
    (prefix (when
                (and (equal major-mode 'bat-mode)
                     (looking-back "\\(%[a-zA-Z0-9_]*\\)" nil))
              (match-string 1)))
    (candidates (bmx--get-matching-variables arg))
    (meta (format "This value is named %s" arg))
    (ignore-case t)))

(defun bmx-insert-percentage-and-complete ()
  "Insert a percentage-sign and initiate completion, if reasonable."
  (interactive)
  (insert ?%)

  ;; don't initiate auto-complete for manually typed variables
  ;; not recognized by completion!
  (when (not (looking-back "%\\([[:alnum:]_]+\\)%" nil))
    (company-manual-begin)))


(defun bmx--variable-at-point ()
  (let ((eol))
    (save-excursion
      (move-end-of-line 1)
      (setq eol (point)))

    (save-excursion
      (cond
       ;; cursor at start of variable invocation |%var%
       ((looking-at "%\\([[:alnum:]_]+\\)%")
        (bmx--variable-normalize
         (match-string-no-properties 1)))

       ;; cursor within a variable - %va|r%
       ((looking-at "\\([[:alnum:]_]+\\)%")
        (bmx--variable-normalize
         (substring-no-properties (symbol-name (symbol-at-point)))))

       ;; cursor at end of a variable name - %var|%
       ((and (looking-at "%")
             (looking-back "%\\([[:alnum:]_]+\\)" nil))
        (bmx--variable-normalize
         (match-string-no-properties 1)))

       ;; cursor at end of a variable invocation - %var%|
       ((looking-back "%\\([[:alnum:]_]+\\)%" nil)
        (bmx--variable-normalize
         (match-string-no-properties 1)))

       ;; line has variable declaration
       ((progn
          (beginning-of-line 1)
          (search-forward-regexp "^set\s+\"?\\([[:alnum:]_]+\\)=" eol t 1))
        (bmx--variable-normalize
         (match-string-no-properties 1)))))))

(defun bmx--variable-find-references (variable)
  (let ((search-upper-case nil)
        (rx-unnormalized
         (regexp-quote
          (bmx--variable-unnormalize variable))))
    (occur (concat "\\("
                   (concat "set\s+\"?" rx-unnormalized "=") ;; declarations
                   "\\|"
                   (concat "%" rx-unnormalized "%") ;; usage
                   "\\)"))))

(defun bmx--variable-navigate-to (variable)
  (xref-push-marker-stack)
  (goto-char (point-min))
  (search-forward-regexp (concat
                          "set\s+\"?"
                          (regexp-quote (bmx--variable-unnormalize variable))
                          "=")))

(defun bmx--variable-rename-prompt (variable)
  (let* ((old-unnormialized (bmx--variable-unnormalize variable))
         (new-name (bmx--read-input
                    (concat
                     "Enter new name for variable '"
                     old-unnormialized
                     "': ")))
         (new-normalized (bmx--variable-normalize new-name)))
    (cond
     ((string-equal "" new-name)
      (message "No name provided."))

     ((member new-normalized (bmx--get-variables t))
      (when (yes-or-no-p (concat "Variable '" new-name "' is already defined. Are you sure?"))
        (bmx--variable-rename variable new-normalized)))

     (t
      (bmx--variable-rename variable new-normalized)))))

(defun bmx--variable-rename (variable new-name)
  (undo-boundary)

  (let ((old-unnormalized (bmx--variable-unnormalize variable))
        (new-unnormalized (bmx--variable-unnormalize new-name)))
    (message "Renaming variable '%s' to '%s'..." old-unnormalized new-unnormalized)

    ;; rename declarations
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (concat "set\s+" (regexp-quote old-unnormalized) "=")
              nil t)
        (replace-match (concat "set " new-unnormalized "="))))

    ;; rename invocations
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (concat "%" (regexp-quote old-unnormalized) "%")
              nil t)
        (replace-match (concat "%" new-unnormalized "%"))))))

(defun bmx-fixup-variables ()
  "Ensure all variable-usage is using a consistent casing and syntax."
  (interactive)

  (dolist (variable (bmx--get-variables t))
    (bmx--variable-rename variable variable)))

;;
;; general commands
;;

(defun bmx-find-references-at-point ()
  "Find all references to symbol at point and show them in an *Occur* buffer.

Supports variables and labels."
  (interactive)
  (cond ((bmx--variable-at-point) (bmx--variable-find-references (bmx--variable-at-point)))
        ((bmx--label-at-point) (bmx--label-find-references (bmx--label-at-point)))
        (t (message "No referencable symbol found at point!"))))

(defun bmx-navigate-to-symbol-at-point ()
  "Navigate to the symbol at point.

Supports variables and labels."
  (interactive)
  (cond ((bmx--variable-at-point) (bmx--variable-navigate-to (bmx--variable-at-point)))
        ((bmx--label-at-point) (bmx--label-navigate-to (bmx--label-at-point)))
        (t (message "No referencable symbol found at point!"))))

(defun bmx-rename-symbol-at-point ()
  "Rename the the symbol at point.

Supports variables and labels."
  (interactive)
  (cond ((bmx--variable-at-point) (bmx--variable-rename-prompt (bmx--variable-at-point)))
        ((bmx--label-at-point) (bmx--label-rename-prompt (bmx--label-at-point)))
        (t (message "No referencable symbol found at point!"))))

(defun bmx-fixup-labels-and-variables ()
  "Ensure all label and variable-usage is using a consistent casing and syntax."
  (interactive)
  (bmx-fixup-labels)
  (bmx-fixup-variables))

;;
;; mode setup
;;

;;;###autoload
(defun bmx-mode-setup-defaults ()
  "Configure default-settings for `bmx-mode'."
  (add-hook 'bat-mode-hook #'bmx-mode)
  (add-to-list 'company-backends #'bmx--company-label-backend)
  (add-to-list 'company-backends #'bmx--company-variable-backend)
  (add-hook 'company-completion-finished-hook #'bmx--company-completion-finished-hook))

(defvar bmx-keymap (let ((map (make-sparse-keymap)))
                     (define-key map (kbd ":") #'bmx-insert-colon-and-complete)
                     (define-key map (kbd "%") #'bmx-insert-percentage-and-complete)
                     (define-key map (kbd "M-.") #'bmx-navigate-to-symbol-at-point)
                     (define-key map (kbd "<S-f12>") #'bmx-find-references-at-point)
                     (define-key map (kbd "C-c C-r") #'bmx-rename-symbol-at-point)
                     (define-key map (kbd "C-c C-f") #'bmx-fixup-labels-and-variables)
                     map))

;;;###autoload
(define-minor-mode bmx-mode
  "Small enhancements for editing batch-files."
  :lighter "bat-ide"
  :global nil
  :keymap bmx-keymap)

(provide 'bmx-mode)

;;; bmx-mode.el ends here
