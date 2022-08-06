;;; rails-i18n.el --- Seach and insert i18n on ruby code -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Otávio Schwanck dos Santos

;; Author: Otávio Schwanck dos Santos <otavioschwanck@gmail.com>
;; Keywords: tools languages
;; Version: 0.2
;; Package-Requires: ((emacs "27.2") (yaml "0.1.0") (dash "2.19.1"))
;; Homepage: https://github.com/otavioschwanck/rails-i18n.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This is a package to help you find and insert rails i18n into your code.
;; Instead of going to the yaml files and copy i18n by i18n, you just call 'rails-i18n-insert-with-cache',
;; It will fetch and save on cache all i18n used by your application, so you have a reliable and easy way to search
;; and insert your i18ns.

;;; Code:

(require 'subr-x)
(require 'yaml)
(require 'dash)

(defgroup rails-i18n nil
  "Search for and insert rails i18n."
  :group 'tools
  :group 'languages)

(defun rails-i18n--default-project-package ()
  "Return the default project package."
  (if (featurep 'projectile) 'projectile 'project))

(defcustom rails-i18n-project-package (rails-i18n--default-project-package)
  "Project package to access project functions."
  :type 'symbol)

(defcustom rails-i18n-cache-path (concat user-emacs-directory ".local/rails-i18n")
  "Where the cache will be saved."
  :type 'string)

(defcustom rails-i18n--cache-loaded nil
  "If t, means that rails i18n already loaded the cache."
  :type 'boolean)

(defcustom rails-i18n-use-double-quotes nil
  "If t, use double quotes instead single-quotes."
  :type 'boolean)

(defcustom rails-i18n-project-root-function 'projectile-project-root
  "Function used to get project root."
  :type 'symbol)

(defcustom rails-i18n-project-name-function 'projectile-project-name
  "Function used to get project name."
  :type 'symbol)

(defcustom rails-i18n-locales-directory "config/locales"
  "I18n locales folder."
  :type 'string)

(defcustom rails-i18n-locales-regexp "\\.yml$"
  "Query to get the the yamls to i18n."
  :type 'string)

(defcustom rails-i18n-separator ":  "
  "Query to get the the yamls to i18n."
  :type 'string)

(defvar rails-i18n-cache '() "Initialize the i18n cache.")
(defvar rails-i18n-yaml-mode-hook 'yaml-mode-hook "Hook used to add rails-i18n cache upgrader.")

(defun rails-i18n-project-name-function ()
  "Get the project name."
  (cond
   ((eq rails-i18n-project-package 'projectile) (when (fboundp 'projectile-project-name) (projectile-project-name)))
   ((eq rails-i18n-project-package 'project) (rails-i18n--get-project-name-for-project))))

(defun rails-i18n-project-root-function ()
  "Get the project root."
  (cond
   ((eq rails-i18n-project-package 'projectile) (when (fboundp 'projectile-project-root) (projectile-project-root)))
   ((eq rails-i18n-project-package 'project) (string-replace "~/"
                                                          (concat (car (split-string
                                                                (shell-command-to-string "echo $HOME") "\n")) "/")
                                                          (when (fboundp 'project-root) (project-root (project-current)))))))

(defun rails-i18n--get-project-name-for-project ()
  "Return projects name for project."
  (let* ((splitted-project-path (split-string (cdr (project-current)) "/"))
         (splitted-length (length splitted-project-path))
         (project-name (nth (- splitted-length 2) splitted-project-path)))
    project-name))


(defun rails-i18n--read-lines (filePath)
  "Return filePath's file content. FILEPATH: Path of yaml."
  (condition-case nil (yaml-parse-string (with-temp-buffer
                                           (insert-file-contents filePath)
                                           (buffer-string))) (error nil)))

(defun rails-i18n--save-cache ()
  "Save rails routes cache file."
  (save-excursion
    (let ((buf (find-file-noselect rails-i18n-cache-path)))
      (set-buffer buf)
      (erase-buffer)
      (cl-loop for var in '(rails-i18n-cache) do
            (print (list 'setq var (list 'quote (symbol-value var)))
                   buf))
      (save-buffer)
      (kill-buffer))))

(defun rails-i18n--load-cache ()
  "Love rails routes cache file."
  (when (and (file-exists-p rails-i18n-cache-path) (not rails-i18n--cache-loaded))
    (load rails-i18n-cache-path)))

(defun rails-i18n--quotes ()
  "Return the quote to be used."
  (if rails-i18n-use-double-quotes "\"" "'"))

;;;###autoload
(defun rails-i18n-insert-no-cache ()
  "Search and insert the i18n, refreshing the cache."
  (interactive)
  (message "Reading the yml files.  it can take some time...")
  (let* ((collection (rails-i18n--parse-yamls))
         (selectedI18n (completing-read "Select your I18n: " collection)))
    (rails-i18n--set-cache collection)
    (rails-i18n--insert-i18n selectedI18n)))

;;;###autoload
(defun rails-i18n-insert-with-cache ()
  "Search and insert the i18n, searching on cache.
If cache is nil, refresh the cache."
  (interactive)
  (rails-i18n--load-cache)
  (let ((cachedI18n (rails-i18n--get-cached)))
    (if cachedI18n
        (rails-i18n--insert-i18n (completing-read "Select your I18n: " cachedI18n))
      (rails-i18n-insert-no-cache))))

(defun rails-i18n--get-cached ()
  "Get the cached routes if not exists."
  (cdr (assoc (rails-i18n-project-name-function) rails-i18n-cache)))

(defun rails-i18n--insert-i18n (i18nString)
  "Insert the i18n on code. I18NSTRING: string to be inserted."
  (let ((ignoreClass (rails-i18n--guess-use-class))
        (hasArguments (string-match-p "%{\\([a-z]+[_]*[a-z]*\\)}"
                                      (nth 1 (split-string i18nString rails-i18n-separator)))))
    (insert
     (if ignoreClass "" "I18n.")
     "t(" (rails-i18n--quotes) (rails-i18n--format-substring i18nString ignoreClass) (rails-i18n--quotes) ")")
    (when hasArguments (forward-char -1) (insert ", "))))

(defun rails-i18n--format-substring (i18nString ignoreClass)
  "Format the substring depending of mode.
IGNORECLASS: boolean taht indicates if I18n class was ignored.
I18NSTRING: String to be inserted."
  (let ((stringToBeInserted (nth 0 (split-string i18nString rails-i18n-separator))))
    (if
        ignoreClass
        (rails-i18n--insert-for-view stringToBeInserted)
      stringToBeInserted)))

(defun rails-i18n--insert-for-view (i18nString)
  "Insert with view rules. I18NSTRING: String to be inserted."
  (let ((stringToBeInserted (substring i18nString 1 (length i18nString))))
    (if (string-match "app/views" (buffer-file-name))
        (replace-regexp-in-string (rails-i18n--controller-and-action-name) "" stringToBeInserted)
      stringToBeInserted)))

(defun rails-i18n--controller-and-action-name ()
  "Current controller and action."
  (let*
      ((withoutProjectName (replace-regexp-in-string (concat (rails-i18n-project-root-function) "app/views") "" (buffer-file-name)))
       (withoutUnderline (replace-regexp-in-string "/_" "/" withoutProjectName))
       (slashChanged (replace-regexp-in-string "/" "." withoutUnderline))
       (fixedString (string-join (butlast (split-string slashChanged "\\.") 2) ".")))
    (substring fixedString 1 (length fixedString))))

(defun rails-i18n--guess-use-class ()
  "Guess if current file needs to pass the class."
  (string-match-p "app/views\\|app/helpers" (buffer-file-name)))

(defun rails-i18n--set-cache (val)
  "Set the cache values. VAL:  Value to set."
  (when (assoc (rails-i18n-project-name-function) rails-i18n-cache)
    (setq rails-i18n-cache (remove (assoc (rails-i18n-project-name-function) rails-i18n-cache) rails-i18n-cache)))
  (setq rails-i18n-cache (cons `(,(rails-i18n-project-name-function) . ,val) rails-i18n-cache))
  (rails-i18n--save-cache))

(defun rails-i18n--parse-yamls ()
  "Return the parsed yaml list."
  (let ((files (rails-i18n--get-yaml-files))
        ($result))
    (mapc
     (lambda (file)
       (let ((parsed-file (rails-i18n--read-lines file)))
         (if (eq (type-of parsed-file) 'hash-table)
             (push (flatten-list
                    (rails-i18n--parse-yaml
                     []
                     parsed-file )) $result)
           (message "[warning] Cannot read %s - error on parse. (keep calm, still loading the yamls.)"
                    (file-name-nondirectory file)))))
     files)
    (-distinct (flatten-list $result))))

(defun rails-i18n--get-yaml-files ()
  "Find all i18n files."
  (directory-files-recursively
   (concat (rails-i18n-project-root-function) rails-i18n-locales-directory) rails-i18n-locales-regexp))

(defun rails-i18n--parse-yaml (previousKey yamlHashTable)
  "Parse the yaml into an single list.
PREVIOUSKEY: key to be mounted.  YAMLHASHTABLE:  Value to be parsed."
  (if (eq (type-of yamlHashTable) 'hash-table)
      (progn
        (let ($result)
          (maphash
           (lambda (k v)
             (push (rails-i18n--parse-yaml
                    (append previousKey
                            (make-vector 1 (format "%s" k)) nil) v) $result))
           yamlHashTable)

          $result))
    (rails-i18n--mount-string previousKey yamlHashTable)))

(defun rails-i18n--mount-string (previousKey string)
  "Create the string to be selected.
PREVIOUSKEY: list of keys to mount. STRING: Value to the i18n."
  (concat "."
          (string-join (remove (nth 0 previousKey) previousKey) ".")
          rails-i18n-separator
          (propertize (format "%s" string) 'face 'bold)))

(defun rails-i18n--watch-rb ()
  "Watch if yaml file is saved, if its a i18n file, upgrade cache."
  (when (and
         (buffer-file-name)
         (string-match-p rails-i18n-locales-regexp (file-name-nondirectory (buffer-file-name)))
         (string-match-p rails-i18n-locales-directory (buffer-file-name)))
    (add-hook 'after-save-hook #'rails-i18n--upgrade-single-file-cache) 100 t))

(defun rails-i18n--upgrade-cache-for (result)
  "Upgrade cache for just one project / file.  RESULT:  Texts to be upgraded."
  (let* ((currentI18n (cdr (assoc (rails-i18n-project-name-function) rails-i18n-cache)))
         (cleanedI18n (rails-i18n--remove-old currentI18n result)))
    (rplacd (assoc (rails-i18n-project-name-function) rails-i18n-cache)
            (-distinct (flatten-list (push result cleanedI18n))))))

(defun rails-i18n--remove-old (currentI18n result)
  "Remove old i18n and change to new.
CURRENTI18N: i18n at moment, RESULT: new file i18ns parsed."
  (mapcar
   (lambda (element)
     (when
         (not (cl-member (nth 0 (split-string element rails-i18n-separator))
                         (mapcar (lambda (oldElement) (nth 0 (split-string oldElement rails-i18n-separator))) result)
                         :test #'string-match))
       element))
   currentI18n))

(defun rails-i18n--upgrade-single-file-cache ()
  "Upgrade rails-i18n when file is changed (when possible)."
  (let* ((yaml (rails-i18n--read-lines (buffer-file-name)))
         (hasCache (rails-i18n--get-cached))
         ($result))
    (if (and (eq (type-of yaml) 'hash-table) hasCache)
        (progn
          (message "Upgrading file cache (rails-i18n)...  Press C-g to cancel.")
          (push (flatten-list
                 (rails-i18n--parse-yaml
                  []
                  yaml )) $result)
          (rails-i18n--upgrade-cache-for (-distinct (flatten-list $result)))
          (message "Cache upgraded!"))
      (message "Rails i18n: Cache not found or cannot parse yaml."))))

(provide 'rails-i18n)
;;; rails-i18n.el ends here
