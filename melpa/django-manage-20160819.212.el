;;; django-manage.el --- Django minor mode for commanding manage.py

;; Copyright (C) 2015 Daniel Gopar

;; Author: Daniel Gopar <gopardaniel@yahoo.com>
;; Package-Requires: ((hydra "0.13.2"))
;; Package-Version: 20160819.212
;; Package-Commit: e72b1cf2fdbb5c624d19169176e60467b4918fe2
;; Version: 0.1
;; Keywords: languages

;; This file is NOT part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Simple package to be to be able to control `manage.py', the standard
;; file that every Django project comes with.  You are able to call any
;; command with `django-manage-command' plus it comes with code
;; completion so third party plugins will also be completed.

;;; Code:

(condition-case nil
    (require 'python)
  (error
   (require 'python-mode)))
(require 'hydra)

(defcustom django-manage-shell-preference 'pyshell
  "What shell to use."
  :type 'symbol
  :options '(eshell term pyshell)
  :group 'shell)

(defcustom django-manage-server-ipaddr "127.0.0.1"
  "What address Django will use when running the dev server."
  :type 'string
  :group 'server)

(defcustom django-manage-server-port "8000"
  "What port Django will use when running the dev server."
  :type 'string
  :group 'server)

(defcustom django-manage-prompt-for-command nil
  "When non-nil will ask for confirmation on command.
Will affect every function other than `django-manage-command'."
  :type 'boolean
  :group 'django-manage)

(defcustom django-manage-root ""
  "The directory where 'manage.py' lives."
  :type 'string
  :group 'django-manage)
(make-local-variable 'django-manage-root)

(defun django-manage-root ()
  "Return the root directory of Django project."
  ;; Check if projectile is in use, and if it is. Return root directory
  (if (not (string= django-manage-root ""))
      django-manage-root
    (if (fboundp 'projectile-project-root)
        (projectile-project-root)
      ;; Try looking for the directory holding 'manage.py'
      (locate-dominating-file default-directory "manage.py"))))

(defun django-manage-python-command ()
  "Return Python version to use with args."
  (if (boundp 'python-shell-interpreter)
      (concat python-shell-interpreter " " python-shell-interpreter-args)
    ;; For old python.el
    (mapconcat 'identity (cons python-python-command python-python-command-args) " ")))

(defun django-manage-get-commands ()
  "Return list of django commands."
  (let ((help-output
         (shell-command-to-string (concat python-shell-interpreter " "
                                          (shell-quote-argument (django-manage-root)) "manage.py -h"))))
    (setq dj-commands-str
          (with-temp-buffer
            (progn
              (insert help-output)
              (beginning-of-buffer)
              (delete-region (point) (search-forward "Available subcommands:" nil nil nil))
              ;; cleanup [auth] and stuff
              (beginning-of-buffer)
              (save-excursion
                (replace-regexp "\\[.*\\]" ""))
              (buffer-string))))
    ;; get a list of commands from the output of manage.py -h
    ;; What would be the pattern to optimize this ?
    (setq dj-commands-str (s-split "\n" dj-commands-str))
    (setq dj-commands-str (-remove (lambda (x) (string= x "")) dj-commands-str))
    (setq dj-commands-str (mapcar (lambda (x) (s-trim x)) dj-commands-str))
    (sort dj-commands-str 'string-lessp)))

(defun django-manage-command (command &optional no-prompt)
  "Allow to run any `manage.py' command.
Argument COMMAND command for django to run.
Optional Argument NO-PROMPT if non-nil will *not* ask if you wish to pass extra arguments."
  ;; nil nil: enable user to exit with any command. Still, he can not edit a completed choice.
  (interactive (list (completing-read "Command: " (django-manage-get-commands) nil nil)))
  (if (not no-prompt)
      ;; Now ask to edit the command. How to do the two actions at once ?
      (setq command (read-shell-command "Run command like this: " command)))
  (compile (concat (django-manage-python-command) " "
                   (shell-quote-argument (django-manage-root)) "manage.py " command)))

(defun django-manage-makemigrations (&optional app-name)
  "Run \"makemigrations app-name\", will prompt for \"app-name\".
You can leave blank to simply run \"makemigrations\".
To choose arguments call `django-manage-command'.
Optional argument APP-NAME name of django app create migrations."
  (interactive "sName: ")
  (django-manage-command (concat "makemigrations " app-name)
                         (not django-manage-prompt-for-command)))

(defun django-manage-flush ()
  "Run \"flush --noinput\". To choose arguments call `django-manage-command'."
  (interactive)
  (django-manage-command "flush --noinput"
                         (not django-manage-prompt-for-command)))

(defun django-manage-runserver ()
  "Start the development server. To change what address and port to use,
customize `django-manage-server-ipaddr' and `django-manage-server-port'
If you want to pass arguments, then call `django-manage-command'"
  (interactive)
  (let ((parent-dir (file-name-base (substring (django-manage-root) 0 -1))))
      (compile (concat (django-manage-python-command) " "
                   (shell-quote-argument (django-manage-root)) "manage.py runserver "
                   django-manage-server-ipaddr ":" django-manage-server-port))
      (with-current-buffer "*compilation*"
        (rename-buffer (format "*runserver[%s]*" parent-dir)))))

(defun django-manage-migrate ()
  "Run \"migrate\".  To choose arguments call `django-manage-command'."
  (interactive)
  (django-manage-command "migrate"
                         (not django-manage-prompt-for-command)))

(defun django-manage-assets-rebuild ()
  "Run \"assets rebuild\".  To choose arguments call `django-manage-command'."
  (interactive)
  (django-manage-command "assets rebuild"
                         (not django-manage-prompt-for-command)))

(defun django-manage-startapp (name)
  "Run \"startapp name\".  Will prompt for name of app.
To choose arguments call `django-manage-command'.
Argument NAME name of app to create."
  (interactive "sName:")
  (django-manage-command (concat "startapp " name)
                         (not django-manage-prompt-for-command)))

(defun django-manage-makemessages ()
  "Run \"makemessages --all --symlinks\".
To pass arguments call `django-manage-command'."
  (interactive)
  (django-manage-command "makemessages --all --symlinks"
                         (not django-manage-prompt-for-command)))

(defun django-manage-compilemessages ()
  "Run \"compilemessages\".  To pass arguments call `django-manage-command'."
  (interactive)
  (django-manage-command "compilemessages"
                         (not django-manage-prompt-for-command)))

(defun django-manage-test (name)
  "Run \"test name\".  Will prompt for Django app name to test.
To pass arguments call `django-manage-command'.
Argument NAME name of django app to test."
  (interactive "sTest app:")
  (django-manage-command (concat "test " name)
                         (not django-manage-prompt-for-command)))

(defun django-manage--prep-shell (pref-shell)
  "Prepare the shell with users preference.
Argument PREF-SHELL users shell of choice"
  ;; If a preexisting shell buffer exists return that one. If not create it
  (let* ((parent-dir (file-name-base (substring (django-manage-root) 0 -1)))
         (default-directory (django-manage-root))
         (buffer-shell-name
          (format (if (string= pref-shell "shell") "*Django Shell[%s]*" "*Django DBshell[%s]*") parent-dir)))
    ;; If it exists return it
    (if (get-buffer buffer-shell-name)
        (switch-to-buffer buffer-shell-name)
      ;; Shell didn't exist, so let's create it
      (if (eq 'term django-manage-shell-preference)
          (term (concat (django-manage-python-command) " "
                        (shell-quote-argument (django-manage-root)) "manage.py " pref-shell)))
      (if (eq 'eshell django-manage-shell-preference)
          (progn
            (unless (get-buffer eshell-buffer-name)
              (eshell))
            (insert (concat (django-manage-python-command) " "
                            (shell-quote-argument (django-manage-root)) "manage.py " pref-shell))
            (eshell-send-input)))
      (if (eq 'pyshell django-manage-shell-preference)
          (let ((setup-code "os.environ.setdefault(\"DJANGO_SETTINGS_MODULE\", \"%s.settings\")")
                (cmd ";from django.core.management import execute_from_command_line")
                (exe (if (string= pref-shell "shell")
                         ";import django;django.setup()"
                       (format ";execute_from_command_line(['manage.py', '%s'])" pref-shell))))
            (run-python (python-shell-parse-command))
            (python-shell-send-string (concat (format setup-code parent-dir) cmd exe))
            (switch-to-buffer (python-shell-get-buffer))))
      (rename-buffer buffer-shell-name))))

(defun django-manage-shell ()
  "Start Python shell with Django already configured."
  (interactive)
  (django-manage--prep-shell "shell"))

(defun django-manage-dbshell ()
  "Start Database shell."
  (interactive)
  (django-manage--prep-shell "dbshell"))

(defun django-manage-insert-transpy (from to &optional buffer)
  "Wraps highlighted region in _(...) for i18n.
Argument FROM start point TO wrap.
Optional argument BUFFER end point to wrap."
  ;; From http://garage.pimentech.net/libcommonDjango_django_emacs/
  ;; Modified a little
  (interactive "*r")
  (save-excursion
    (save-restriction
      (narrow-to-region from to)
      (goto-char from)
      (iso-iso2sgml from to)
      (insert "_(")
      (goto-char (point-max))
      (insert ")")
      (point-max))))

(defhydra django-manage-hydra (:color blue
                                      :hint nil)
  "
                    Manage.py
--------------------------------------------------

_mm_: Enter manage.py commnand    _r_: runserver      _f_: Flush             _t_: Run rest
_ma_: Makemigrations             _sa_: Start new app  _i_: Insert transpy
_mg_: Migrate                    _ss_: Run shell      _a_: Rebuild Assets
_me_: Make messages              _sd_: Run DB Shell   _c_: Compile messages

_q_: Cancel

"
  ("mm" django-manage-command)
  ("ma" django-manage-makemigrations)
  ("mg" django-manage-migrate)
  ("me" django-manage-makemessages)

  ("r"  django-manage-runserver "Start server")
  ("sa" django-manage-startapp)
  ("ss" django-manage-shell)
  ("sd" django-manage-dbshell)

  ("f"  django-manage-flush)
  ("a"  django-manage-assets-rebuild)
  ("c"  django-manage-compilemessages)
  ("t"  django-manage-test)

  ("i"  django-manage-insert-transpy)
  ("q"  nil "cancel"))

(defvar django-manage-map
      (let ((map (make-keymap)))
        (define-key map (kbd "C-c C-x") 'django-manage-hydra/body)
        map))

(defun django-manage-setup ()
  "Determine whether to start minor mode or not."
  (when (and (stringp buffer-file-name)
             (locate-dominating-file default-directory "manage.py"))
    (django-manage)))

;;;###autoload
(define-minor-mode django-manage
  "Minor mode for handling Django's manage.py"
  :lighter " Manage"
  :keymap django-manage-map)

(easy-menu-define django-manage-menu django-manage-map "Django menu"
  '("Django"
    ["Start an app" django-manage-startapp t]
    ["Run tests" django-manage-test t]
    ["Make migrations" django-manage-makemigrations t]
    ["Flush database" django-manage-flush t]
    ["Runserver" django-manage-runserver t]
    ["Run database migrations" django-manage-migrate t]
    ["Rebuild assets" django-manage-assets-rebuild t]
    ["Make translations" django-manage-makemessages t]
    ["Compile translations" django-manage-compilemessages t]
    ["Open Python shell" django-manage-shell t]
    ["Open database shell" django-manage-dbshell t]
    ["Run other command" django-manage-command t]
    "-"
    ["Insert translation mark" django-manage-insert-transpy t]))

(easy-menu-add django-manage-menu django-manage-map)

(provide 'django-manage)

;;; django-manage.el ends here
