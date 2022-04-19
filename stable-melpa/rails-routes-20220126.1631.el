;;; rails-routes.el --- Search for and insert rails routes    -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Otávio Schwanck

;; Author: Otávio Schwanck <otavioschwanck@gmail.com>
;; Keywords: tools languages
;; Homepage: https://github.com/otavioschwanck/rails-routes
;; Version: 0.3
;; Package-Requires: ((emacs "27.2") (inflections "1.1"))

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

;; This is a package to help you find and insert rails routes into your code.
;; Instead of going to the terminal or loading the path in the browser, you just call 'rails-routes-insert',
;; It will fetch and save on cache all routes used by your application, so you have a reliable and easy way to search
;; and insert your routes.
;;
;; New on 0.3
;; - Remove projectile dependency
;; - Add command to insert routes ignoring cache
;; - Improve cache upgrade
;;
;; New on 0.2
;; Add rails-routes-jump to jump to the route controller.  Works with activeadmin.

;;; Code:
(require 'subr-x)
(require 'inflections)
(require 'cl-lib)

(defgroup rails-routes nil
  "Search for and insert rails routes."
  :group 'tools
  :group 'languages)

(defun rails-routes--default-project-package ()
  "Return the default project package."
  (if (featurep 'projectile) 'projectile 'project))

(defcustom rails-routes-project-package (rails-routes--default-project-package)
  "Project package to access project functions."
  :type 'symbol)

(defcustom rails-routes-search-command "RUBYOPT=-W0 rails routes"
  "Command executed to search the routes."
  :type 'string)

(defcustom rails-routes-insert-after-path "_path"
  "What will be inserted after calling `rails-routes-insert'."
  :type 'string)

(defcustom rails-routes-cache-path (concat user-emacs-directory ".local/rails-routes")
  "Where the cache will be saved."
  :type 'string)

(defcustom rails-routes-class-name "Rails.application.routes.url_helpers."
  "Prefix used to access rails routes outside the views."
  :type 'string)

(defcustom rails-routes--cache-loaded nil
  "If t, means that rails routes already loaded the cache."
  :type 'boolean)

(defun rails-routes-project-name-function ()
  "Get the project name."
  (cond
   ((eq rails-routes-project-package 'projectile) (when (fboundp 'projectile-project-name) (projectile-project-name)))
   ((eq rails-routes-project-package 'project) (rails-routes--get-project-name-for-project))))

(defun rails-routes-project-root-function ()
  "Get the project root."
  (cond
   ((eq rails-routes-project-package 'projectile) (when (fboundp 'projectile-project-root) (projectile-project-root)))
   ((eq rails-routes-project-package 'project) (string-replace "~/"
                                                          (concat (car (split-string
                                                                (shell-command-to-string "echo $HOME") "\n")) "/")
                                                          (when (fboundp 'project-root) (project-root (project-current)))))))

(defun rails-routes--get-project-name-for-project ()
  "Return projects name for project."
  (let* ((splitted-project-path (split-string (cdr (project-current)) "/"))
         (splitted-length (length splitted-project-path))
         (project-name (nth (- splitted-length 2) splitted-project-path)))
    project-name))

(defun rails-routes--save-cache ()
  "Save rails routes cache file."
  (save-excursion
    (let ((buf (find-file-noselect rails-routes-cache-path)))
      (set-buffer buf)
      (erase-buffer)
      (cl-loop for var in '(rails-routes-cache rails-routes-cache-validations) do
            (print (list 'setq var (list 'quote (symbol-value var)))
                   buf))
      (save-buffer)
      (kill-buffer))))

(defun rails-routes--load-cache ()
  "Love rails routes cache file."
  (when (and (file-exists-p rails-routes-cache-path) (not rails-routes--cache-loaded))
    (load rails-routes-cache-path)))

(defvar rails-routes-cache '())
(defvar rails-routes-cache-validations '())

(defun rails-routes--set-cache (val)
  "Set routes cache to VAL."
  (when (assoc (rails-routes-project-name-function) rails-routes-cache)
    (setq rails-routes-cache (remove (assoc (rails-routes-project-name-function) rails-routes-cache) rails-routes-cache)))
  (setq rails-routes-cache (cons `(,(rails-routes-project-name-function) . ,val) rails-routes-cache)))

(defun rails-routes--set-cache-validations (val)
  "Set validations cache to VAL."
  (when (assoc (rails-routes-project-name-function) rails-routes-cache-validations)
    (setq rails-routes-cache-validations
          (remove (assoc (rails-routes-project-name-function) rails-routes-cache-validations) rails-routes-cache-validations)))
  (setq rails-routes-cache-validations (cons `(,(rails-routes-project-name-function) . ,val) rails-routes-cache-validations)))

(defun rails-routes-clear-cache ()
  "Clear rails routes cache."
  (interactive)
  (setq rails-routes-cache '())
  (setq rails-routes-cache-validations '())
  (rails-routes--save-cache))

(defun rails-routes--run-command ()
  "Run rails-routes-search-command and return it."
  (message "Fetching routes.  Please wait.")
  (let ((command-result (cl-remove-if-not
                         (lambda (element)
                           (let ((len (length (split-string element " +"))))
                             (or (eq len 5) (eq len 4))))
                         (split-string (shell-command-to-string rails-routes-search-command) "\n"))))

      (rails-routes--set-cache command-result)
      (rails-routes--set-cache-validations t)
      (rails-routes--save-cache)
    command-result))

(defun rails-routes--get-routes-cached ()
  "Get the routes, using the cache if possible."
  (let ((routes-result (if (cdr (assoc (rails-routes-project-name-function) rails-routes-cache-validations))
                           (cdr (assoc (rails-routes-project-name-function) rails-routes-cache))
                         (rails-routes--run-command))))
    (if (not routes-result)
        (rails-routes--run-command)
      routes-result)))

(defun rails-routes--guess-route (controller-full-path)
  "Guess the route name from CONTROLLER-FULL-PATH.
CONTROLLER-FULL-PATH is the controller name plus action."
  (let ((controller-path (nth 0 (split-string controller-full-path "#"))))
    (replace-regexp-in-string "\/" "_" controller-path)))

;;;###autoload
(defun rails-routes-insert-no-cache ()
  "Clean cache, then, call rails-routes-insert."
  (interactive)
  (rails-routes-clear-cache)
  (rails-routes-insert))

(defun rails-routes--guess-ignore-class ()
  "Return t if class need to be inserted."
  (string-match-p "app/views\\|app/controllers\\|app/helpers" (buffer-file-name)))

;;;###autoload
(defun rails-routes-insert ()
  "Ask for the route you want and insert on code.
With prefix argument INSERT-CLASS, fully-qualify the route with
the `rails-routes-class-name' prefix."
  (interactive)
  (rails-routes--load-cache)
  (let* ((selected-value (split-string (completing-read "Route: " (rails-routes--get-routes-cached)) " +"))
         (selected-route (nth (if (eq (length selected-value) 5) 3 2) selected-value)))
    (when (not (rails-routes--guess-ignore-class)) (insert rails-routes-class-name))
    (rails-routes--insert-value selected-value)
    (when (or (string-match-p ":id" selected-route)
              (string-match-p ":[a-zA-Z0-9]+_id" selected-route))
      (progn (insert "()") (backward-char)))))

(defun rails-routes--insert-value (selected-value)
  "Insert the selected_value.  SELECTED-VALUE: Item im list."
  (insert (if (eq (length selected-value) 5) (nth 1 selected-value)
            (rails-routes--guess-route (nth 3 selected-value)))
          rails-routes-insert-after-path))

;;;###autoload
(defun rails-routes-invalidate-cache ()
  "Invalidate cache when the file that will be saved is routes.rb."
  (when (string-match-p "routes.rb" (buffer-file-name))
    (rails-routes--set-cache-validations nil)
    (rails-routes--save-cache)))

(defun rails-routes--remove-path-or-url (path)
  "Remove any \"_path\" or \"_url\" suffix from PATH."
  (replace-regexp-in-string "\\(_path\\|_url\\)\\'" "" path))

(defun rails-routes--find-controller (path)
  "Find controller for path in routes list.
PATH: a rails routes path or url."
  (let ((routes (rails-routes--get-routes-cached))
        (response nil))
    (dolist (item routes)
      (let ((parsed_item (split-string item " +")))
        (when (string-equal (nth 1 parsed_item) path)
          (setq response (nth 4 parsed_item)))))
    response))

(defun rails-routes--singularize-string (word)
  "Singularize all words in a route.  WORD: any_word."
  (setq word (substring word 5))
  (let ((words (split-string word "_")))
    (string-join (mapcar #'inflection-singularize-string words) "_")))

(defun rails-routes--goto-activeadmin-controller (controller-name action)
  "Try to go to activeadmin first, if not exists, go to app/controllers.
CONTROLLER-NAME: Path of controller.  ACTION:  Action of the path."
  (let* ((project-root (rails-routes-project-root-function))
         (moved nil)
         (normal-path (expand-file-name (concat "app/admin" (rails-routes--singularize-string controller-name) ".rb") project-root))
         (expanded-path
          (expand-file-name (concat "app/admin"
                                    (replace-regexp-in-string "_" "/" (rails-routes--singularize-string controller-name)) ".rb")
                            project-root)))

    (when (file-exists-p normal-path)
      (find-file normal-path)
      (setq moved t))

    (when (and (not moved) (file-exists-p expanded-path))
      (find-file expanded-path)
      (setq moved t))

    (if moved
        (progn
          (goto-char (point-min))
          (search-forward (concat "member_action :" action) (point-max) t)
          (search-forward (concat "collection_action :" action) (point-max) t))
      (rails-routes--go-to-controller controller-name action))))

(defun rails-routes--go-to-controller-and-action (full-action)
  "Go to controller and then, go to def action_name.
FULL-ACTION: action showed on rails routes."
  (let ((controller-name (nth 0 (split-string full-action "#"))) (action (nth 1 (split-string full-action "#"))))
    (if (string-match-p "admin" controller-name)
        (rails-routes--goto-activeadmin-controller controller-name action)
      (rails-routes--go-to-controller controller-name action))))

(defun rails-routes--go-to-controller (controller action)
  "Go to controller using action.  CONTROLLER: controller showed on rails routes.
ACTION: action showed on rails routes."
  (find-file (rails-routes--controller-full-path controller))
  (search-forward (concat "def " action) (point-max) t))

(defun rails-routes--controller-full-path (controller-name)
  "Return the path of a rails controller using only the name.
CONTROLLER-NAME: Name of the controller."
  (concat (rails-routes-project-root-function) "app/controllers/" controller-name "_controller.rb"))

;;;###autoload
(defun rails-routes-jump ()
  "Go to the route at point."
  (interactive)
  (let* ((path (symbol-name (symbol-at-point)))
         (controller (rails-routes--find-controller (rails-routes--remove-path-or-url path))))
    (if controller
        (rails-routes--go-to-controller-and-action controller) (message "Route not found."))
    (recenter)))

(defun rails-routes--set-routes-hook ()
  "Set the hook for 'after-save-hook' only for routes.rb."
  (when (and (buffer-file-name)
             (string-equal "routes.rb" (file-name-nondirectory (buffer-file-name)))
             (assoc (rails-routes-project-name-function) rails-routes-cache)
             (assoc (rails-routes-project-name-function) rails-routes-cache-validations))
    (add-hook 'after-save-hook #'rails-routes-invalidate-cache nil t)))

(provide 'rails-routes)
;;; rails-routes.el ends here
