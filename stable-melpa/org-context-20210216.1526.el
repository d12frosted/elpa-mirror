;;; org-context.el --- Contextual capture and agenda commands for Org-mode

;; Copyright (C) 2012-2021 Sylvain Rousseau <thisirs at gmail dot com>

;; Author: Sylvain Rousseau <thisirs at gmail dot com>
;; URL: https://github.com/thisirs/org-context
;; Package-Version: 20210216.1526
;; Package-Commit: a08f1f607f819791b9b95ad4f91c5eaa9fdbb091
;; Version: 0.1
;; Keywords: Org, capture, agenda, convenience

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

;; This package advises `org-capture' and `org-agenda' to allow
;; contextual capture templates and agenda commands.
;;
;; See documentation on https://github.com/thisirs/org-context#org-context

;;; Installation:

;; Put the following in your .emacs:
;;
;; (require 'org-context)
;; (org-context-mode +1)
;;
;; and customize `org-context-capture-alist' and `org-context-capture'
;; for contextual captures and `org-context-agenda-alist'
;; `org-context-agenda' for custom commands.

;;; Code:

(require 'org)
(require 'org-agenda)
(require 'org-capture)
(require 'seq)

(defvar org-context-capture-alist
  nil
  "Alist that specifies contextual capture templates.

Each element is of the form (CONDITION . TEMPLATE-LIST) where
CONDITION is either a symbol matching a major mode or a regular
expression matching the buffer file-name or the buffer name and
TEMPLATE-LIST is a list of contextual capture templates as
described in the Org manual that will be added to the set of
default ones.")

(defvar org-context-capture nil
  "Buffer local variable that holds the templates definitions.")
(make-variable-buffer-local 'org-context-capture)
(put 'org-context-capture 'safe-local-variable 'org-context-capture-safe-p)

(defun org-context-capture-safe-p (templates)
  "Return non-nil if the list of capture templates TEMPLATES is safe.

A template is considered safe if it does not have to evaluate
arbitrary functions."
  (let ((safe t) template)
    (if (listp templates)
        (while (and templates safe)
          (setq template (car templates))
          (if (and
               (listp template)
               (= (length template) 5)
               (or
                (and
                 (consp (nth 3 template))
                 (or
                  (string-match "function$"
                                (symbol-name (car (nth 3 template))))
                  (and (string-match "^file"
                                     (symbol-name (car (nth 3 template))))
                       (not (string-or-null-p (cadr (nth 3 template)))))))
                (string-match "%(" (nth 4 template))))
              (setq safe nil)
            (setq templates (cdr templates))))
      (setq safe nil))
    safe))

(defvar org-context-agenda-alist
  nil
  "Alist of filename patterns vs corresponding custom agenda
  list.")

(defvar org-context-agenda nil
  "Buffer local variable that holds the custom agenda commands.")
(make-variable-buffer-local 'org-context-agenda)
(put 'org-context-agenda 'safe-local-variable 'org-context-agenda-safe-p)

(defun org-context-agenda-safe-p (commands)
  "Return non-nil if the list of agenda commands COMMANDS is safe.

An agenda command is considered safe if it does not have to evaluate
arbitrary functions."
  (let ((safe t)
        (keywords '(agenda agenda* alltodo search stuck tags tags-todo
                           todo tags-tree todo-tree occur-tree))
        command)
    (if (listp commands)
        (while (and commands safe)
          (setq command (car commands))
          (if (and (listp command)
                   (> (length command) 2)
                   (if (stringp (nth 1 command))
                       (or (functionp (nth 2 command))
                           (and (symbolp (nth 2 command))
                                (fboundp (nth 2 command)))
                           (functionp (nth 3 command))
                           (and (symbolp (nth 3 command))
                                (fboundp (nth 3 command))))
                     (or (functionp (nth 1 command))
                         (and (symbolp (nth 1 command))
                              (fboundp (nth 1 command)))
                         (functionp (nth 2 command))
                         (and (symbolp (nth 2 command))
                              (fboundp (nth 2 command))))))
              (setq safe nil)
            (setq commands (cdr commands))))
      (setq safe nil))
    safe))

(defvar org-context-capture-shortcut
  '((question
     "q" "Question" entry
     (file place-holder)
     "* QUESTION %?\n  OPENED: %U")
    (todo
     "t" "Todo" entry
     (file place-holder)
     "* TODO %?\n  OPENED: %U")
    (todo
     "t" "Todo" entry
     (file place-holder)
     "* TODO %? %()\n  OPENED: %U"))
  "Alist of symbols vs their corresponding template.
This is used in `org-context-capture-alist' or
`org-context-capture' to shorten the template definition.")

(defvar org-context-agenda-shortcut
  '((todo "t" alltodo "")
    (agenda "a" "" agenda ""))
  "Alist of symbols vs their corresponding agenda command.
This is used in `org-context-agenda-alist' or
`org-context-agenda' to shorten the agenda command definition.")

(defvar org-context-add-overridden t
  "Add overridden templates in a sub-menu if non-nil.")

(defun org-context-capture--expand-target (template directory &optional replace)
  "Modify the targeted Org file of the capture template TEMPLATE.

If the path of the targeted Org file exists and is not absolute,
expand it against DIRECTORY. If REPLACE is given use it as
file-name and expand it against DIRECTORY."
  (if (and (string-match "\\`file" (symbol-name (car (nth 3 template))))
           (or replace
               (not (and (stringp (cadr (nth 3 template)))
                         (file-name-absolute-p (cadr (nth 3 template)))))))
      (append
       (list (car template) (nth 1 template) (nth 2 template)
             (append (list (car (nth 3 template))
                           (expand-file-name
                            (or replace (cadr (nth 3 template))) directory))
                     (cddr (nth 3 template))))
       (nthcdr 4 template))
    template))

(defun org-context-capture--expand-stolen (template directory)
  "Expand the stolen template TEMPLATE."
  (let (temp key stolen file desc)
    (cond
     ((stringp template)
      (setq stolen template
            key template))

     ((symbolp template)
      (setq stolen template))

     ((listp template)
      (setq key (car template))
      (let* ((rest (cadr template))
             (rest (if (listp rest) rest (list rest))))
        (setq stolen (nth 0 rest)
              file (nth 1 rest)
              desc (nth 2 rest)))))

    (setq file (or file "todo.org"))

    (setq temp
          (if (stringp stolen)
              (assoc stolen org-capture-templates)
            (cdr (assoc stolen org-context-capture-shortcut))))

    ;; Check that we did steal a template
    (unless temp
      (error "Unable to steal template!"))

    ;; Replace key
    (if key (setq temp (cons key (cdr temp))))

    ;; Modify org file path in temp
    (setq temp (org-context-capture--expand-target temp directory file))

    ;; Set description if any
    (if desc (setq temp (cons (car temp) (cons desc (cddr temp)))))

    temp))

(defsubst org-context-capture--submenu-p (template)
  "Return non-nil if TEMPLATE is a capture submenu."
  (and (listp template)
       (= (length template) 2)
       (stringp (cadr template))
       (> (length (cadr template)) 2)))

(defsubst org-context-capture--target-p (template)
  "Return non-nil if TEMPLATE is a regular capture template."
  (and (listp template) (> (length template) 2)))

(defun org-context-capture--expand (templates directory)
  "Expand all capture templates in the list of templates TEMPLATES.
Eventually use DIRECTORY to build the path to the targeted Org
files."
  (mapcar
   (lambda (temp)
     (cond
      ((org-context-capture--submenu-p temp) temp) ;; This template is a sub-menu, return as is.
      ((org-context-capture--target-p temp)
       (org-context-capture--expand-target temp directory))
      (t (org-context-capture--expand-stolen temp directory))))
   templates))

(defun org-context-capture-templates ()
  "Return a set of capture templates including contextual ones.

This function looks into `org-context-capture-alist' or
`org-context-capture' to see if there is any matching capture
templates."
  (let ((file-name (or buffer-file-name
                       (and (eq major-mode 'dired-mode)
                            default-directory)
                       (buffer-name)))
        (org-templates org-capture-templates)
        (alist org-context-capture-alist)
        condition templates directory merge overridden)

    ;; Set `templates' from local variable `org-context-capture' or
    ;; from `org-context-capture-alist' if `org-context-capture' is
    ;; not local. Set `directory' that might be used to have the path
    ;; of the targeted org file in case it is not specified in the
    ;; template.
    (if (local-variable-p 'org-context-capture)
        (setq templates org-context-capture
              directory (let ((dir-local (dir-locals-find-file file-name)))
                          (if dir-local
                              (if (listp dir-local)
                                  (car dir-local)
                                (file-name-directory dir-local))
                            default-directory)))
      (while alist
        (setq condition (caar alist))
        (cond
         ((and (symbolp condition) (eq condition major-mode))
          (setq templates (cdar alist)
                directory nil
                alist nil))
         ((and (stringp condition) (string-match condition file-name))
          (setq directory (and (file-name-absolute-p
                                (match-string 0 file-name))
                               (match-string 0 file-name))
                templates (cdar alist)
                alist nil))
         (t (setq alist (cdr alist))))))

    (when templates
      ;; Expand templates to Org templates
      (setq templates (org-context-capture--expand templates directory))

      ;; Merge contextual templates `templates' and default ones from
      ;; `org-templates' into `merge'

      ;; First add contextual templates
      (setq merge (reverse templates))

      ;; Then move templates from `org-templates' into `merge'
      ;; or `overridden' together with their eventual sub-menu items
      (while org-templates
        (let* ((template (car org-templates))
               (where (if (and (not (assoc (car template) merge))
                               (not (assoc (car template) templates)))
                          'merge 'overridden)))
          (set where (cons template (symbol-value where)))
          (while (and (setq org-templates (cdr org-templates))
                      (> (length (caar org-templates)) 1))
            (set where (cons (car org-templates) (symbol-value where))))))

      ;; And add overridden templates in sub-menu
      (when (and org-context-add-overridden overridden)
        (push '("o" "Overridden") merge)
        (dolist (temp (nreverse overridden))
          (unless (or (stringp (cdr temp))
                      (> (length (car temp)) 1))
            (push (cons (concat "o" (car temp)) (cdr temp))
                  merge)))))

    (or (nreverse merge) org-capture-templates)))

(defun org-capture-advice (func &rest args)
  (let ((org-capture-templates (org-context-capture-templates)))
    (apply func args)))

;; Advising org-agenda

(defsubst org-context-agenda--submenu-p (command)
  "Return non-nil if the agenda command COMMAND is a sub-menu command."
  (and (listp command) (stringp (cdr command))))

(defsubst org-context-agenda--regular-p (command)
  "Return non-nil if the agenda command COMMAND is a regular command."
  (and (listp command) (> (length command) 2)))

(defun org-context-agenda--add-org-agenda-buffer-name (settings directory)
  "Add `org-agenda-buffer-name' setting to SETTINGS."
  (cons `(org-agenda-buffer-name
          ,(format
            "*Agenda(%s:%s)*"
            (if directory
                (file-name-nondirectory
                 (directory-file-name
                  directory)) "??")
            (car command)))
        settings))

(defun org-context-agenda--add-org-agenda-files (alist directory &optional files)
  (unless (assoc 'org-agenda-files alist)
    (setq alist (cons (cons 'org-agenda-files nil) alist)))
  (setq alist
        (mapcar (lambda (entry)
                  (if (eq (car entry) 'org-agenda-files)
                      (list 'org-agenda-files
                            (list 'quote
                                  (mapcar
                                   (lambda (file)
                                     (if (file-name-absolute-p file)
                                         file
                                       (expand-file-name file directory)))
                                   (or files (cadr (cadr entry)) (list "todo.org")))))
                    entry))
                alist)))

(defun org-context-agenda--expand-composite (command directory &optional org-files)
  ;; COMMAND is like (key desc (cmd1 cmd2 ...) general-settings-for-whole-set files)
  (seq-let (key desc subcommands settings files) command
    (setq settings (org-context-agenda--add-org-agenda-files settings directory org-files))
    (setq settings (org-context-agenda--add-org-agenda-buffer-name settings directory))
    (setq subcommands
          (mapcar
           (lambda (command)
             (let ((alist (nth 2 command)))
               (if alist
                   (cons (car command)
                         (list (nth 1 command)
                               (org-context-agenda--add-org-agenda-files alist directory)))
                 command)))
           subcommands))
    (if (null files)
        (list key desc subcommands settings)
      (list key desc subcommands settings files))))

(defun org-context-agenda--expand-simple (command directory &optional org-files)
  ;; COMMAND is like (key desc type match settings files), we only
  ;; have to update settings
  (seq-let (key desc type match settings files) command
    (setq settings (org-context-agenda--add-org-agenda-files settings directory org-files))
    (setq settings (org-context-agenda--add-org-agenda-buffer-name settings directory))
    (if (null files)
        (list key desc type match settings)
      (list key desc type match settings files))))

(defun org-context-agenda--expand-regular (command directory &optional files)
  "Update or add settings slot in agenda command COMMAND.

Add an `org-agenda-buffer-name' setting based on the key in
COMMAND and on DIRECTORY and add an `org-agenda-files' setting
based on DIRECTORY and FILES."
  ;; First normalize different agenda command versions
  (setq command
        (cond
         ((stringp (nth 1 command)) command)
         ((not (nth 1 command)) (cons (car command) (cons "" (cddr command))))
         (t (cons (car command) (cons "" (cdr command))))))

  ;; Regular agenda commands are either simple (key desc type match
  ;; settings files) or composite (key desc (cmd1 cmd2 ...)
  ;; general-settings-for-whole-set files) based on type
  (if (listp (nth 2 command))
      (org-context-agenda--expand-composite command directory files)
    (org-context-agenda--expand-simple command directory files)))

(defun org-context-agenda--expand-alist (alist directory &optional files)
  "Add or update an `org-agenda-files' property in ALIST.

Add an `org-agenda-files' property if not already present and
expand its files against DIRECTORY or expand FILES against
DIRECTORY if no files are present."
  (unless (assoc 'org-agenda-files alist)
    (setq alist (cons (cons 'org-agenda-files nil) alist)))
  (setq alist
        (mapcar (lambda (entry)
                  (if (eq (car entry) 'org-agenda-files)
                      (list 'org-agenda-files
                            (list 'quote
                                  (mapcar
                                   (lambda (file)
                                     (if (file-name-absolute-p file)
                                         file
                                       (expand-file-name file directory)))
                                   (or files (cadr (cadr entry))))))
                    entry))
                alist)))

(defun org-context-agenda--expand-stolen (command directory)
  "Steal an agenda command and expand it."

  (let (key stolen files desc new-command)
    (cond
     ;; Just a key "t"
     ((stringp command)
      (setq stolen command
            key command))

     ;; A symbol
     ((symbolp command)
      (setq stolen command))

     ;; Other configurations
     ((listp command)
      (setq key (car command))
      (let* ((rest (cadr command))
             (rest (if (listp rest) rest (list rest)))
             (f (nth 1 rest)))
        (setq stolen (nth 0 rest)
              files (if (listp f) f (list f))
              desc (nth 2 rest)))))

    (setq command (if (stringp stolen)
                      (assoc stolen org-agenda-custom-commands)
                    (cdr (assoc stolen org-context-agenda-shortcut))))

    ;; Check that we did steal a command
    (unless command
      (error "Unable to steal agenda command!"))

    ;; Replace key
    (if key (setq command (cons key (cdr command))))

    (setq command
          (cond
           ((stringp (nth 1 command)) command)
           ((not (nth 1 command)) (cons (car command) (cons "" (cddr command))))
           (t (cons (car command) (cons "" (cdr command))))))

    ;; Replace description
    (if desc
        (setq command (cons (car command) (cons desc (cddr command)))))

    (setq command
          (org-context-agenda--expand-regular
           command directory files))

    command))

(defun org-context-agenda--expand (commands directory)
  "Expand all agenda commands in list of commands COMMANDS.

Return sub-menu command unchanged. Expand regular commands and
stolen ones. Eventually use DIRECTORY to build the path to the
targeted Org files."
  (mapcar
   (lambda (command)
     (cond
      ((org-context-agenda--submenu-p command) ;; Sub-menu command, return as is
       command)
      ((org-context-agenda--regular-p command) ;; Expand if regular
       (org-context-agenda--expand-regular command directory))
      (t ;; Should be stolen then...
       (org-context-agenda--expand-stolen command directory))))
   commands))

(defun org-context-agenda-commands ()
  "Return a set of agenda commands including contextual ones.

This function looks into `org-context-agenda-alist' or
`org-context-agenda' to see if there is any matching custom
command."
  (let* ((file-name (or buffer-file-name
                        (and (eq major-mode 'dired-mode)
                             default-directory)
                        (buffer-name)))
         (org-commands org-agenda-custom-commands)
         (alist org-context-agenda-alist)
         condition commands directory merge overridden)

    (if (local-variable-p 'org-context-agenda)
        (setq commands org-context-agenda
              directory (let ((dir-local (dir-locals-find-file file-name)))
                          (if dir-local
                              (if (listp dir-local)
                                  (car dir-local)
                                (file-name-directory dir-local))
                            default-directory)))
      (while alist
        (setq condition (caar alist))
        (cond
         ((and (symbolp condition) (eq condition major-mode))
          (setq commands (cdar alist)
                directory nil
                alist nil))
         ((and (stringp condition) (string-match condition file-name))
          (setq directory (and (file-name-absolute-p
                                (match-string 0 file-name))
                               (match-string 0 file-name))
                commands (cdar alist)
                alist nil))
         (t (setq alist (cdr alist))))))

    (when commands
      ;; Expand commands to Org agenda commands
      (setq commands (org-context-agenda--expand commands directory))

      ;; Merge contextual agenda commands `commands' and default ones
      ;; from `org-commands' into `merge'

      ;; First add contextual commands
      (setq merge (reverse commands))

      ;; Then move commands from `org-commands' into `merge'
      ;; or `overridden' together with their eventual sub-menu items
      (while org-commands
        (let* ((command (car org-commands))
               (where (if (and (not (assoc (car command) merge))
                               (not (assoc (car command) commands)))
                          'merge 'overridden)))
          (set where (cons command (symbol-value where)))
          (while (and (setq org-commands (cdr org-commands))
                      (> (length (caar org-commands)) 1))
            (set where (cons (car org-commands) (symbol-value where))))))

      ;; And add overridden commands in sub-menu
      (when (and org-context-add-overridden overridden)
        (push '("o" . "Overridden") merge)
        (dolist (command (nreverse overridden))
          (unless (stringp (cdr command))
            (push (cons (concat "o" (car command)) (cdr command))
                  merge)))))

    (or (nreverse merge) org-agenda-custom-commands)))

(defun org-agenda-advice (func &rest args)
  "Allow contextual agenda commands.

The function `org-context-agenda-commands' is called to retrieve
the new set of custom commands."
  (let ((org-agenda-custom-commands (org-context-agenda-commands)))
    (apply func args)))

;;;###autoload
(defun org-context-agenda-from (file-or-buffer key)
  (let (org-agenda-context-commands buffer)
    (cond
     ((bufferp file-or-buffer)
      (setq buffer file-or-buffer))
     ((get-buffer file-or-buffer)
      (setq buffer (get-buffer file-or-buffer)))
     ((and (stringp file-or-buffer) (find-buffer-visiting file-or-buffer))
      (setq buffer (find-buffer-visiting file-or-buffer)))
     ((stringp file-or-buffer)
      (setq buffer (find-file-noselect file-or-buffer t)))
     (t
      (error "Unknown argument %s" file-or-buffer)))
    (with-current-buffer buffer
      (org-agenda nil key))))

;;;###autoload
(define-minor-mode org-context-mode
  "Minor mode to activate `org-context'."
  :lighter ""
  :global t
  (if org-context-mode
      (progn
        (advice-add 'org-capture :around #'org-capture-advice)
        (advice-add 'org-agenda :around #'org-agenda-advice))
    (advice-remove 'org-capture #'org-capture-advice)
    (advice-remove 'org-agenda #'org-agenda-advice)))

;;;###autoload
(define-obsolete-function-alias 'org-context-activate 'org-context-mode "0.0.5")

(provide 'org-context)

;;; org-context.el ends here
