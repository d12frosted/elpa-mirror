;;; rails-i18n.el --- Seach and insert i18n on ruby code -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Otávio Schwanck dos Santos

;; Author: Otávio Schwanck dos Santos <otavioschwanck@gmail.com>
;; Keywords: tools languages
;; Package-Version: 20211026.1404
;; Package-Commit: 86be9e70f6fe90484f88d6c68c2f337f6ecd5651
;; Version: 0.2
;; Package-Requires: ((emacs "27.2") (yaml "0.1.0") (dash "2.19.1") (projectile "2.6.0-snapshot"))
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

(require 'savehist)
(require 'subr-x)
(require 'yaml)
(require 'dash)
(require 'projectile)

(defgroup rails-i18n nil
  "Search for and insert rails i18n."
  :group 'tools
  :group 'languages)

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

(defun rails-i18n--read-lines (file-path)
  "Return file-path's file content. FILE-PATH: Path of yaml."
  (condition-case nil (yaml-parse-string (with-temp-buffer
                                           (insert-file-contents file-path)
                                           (buffer-string))) (error nil)))

(defun rails-i18n--quotes ()
  "Return the quote to be used."
  (if rails-i18n-use-double-quotes "\"" "'"))

;;;###autoload
(defun rails-i18n-insert-no-cache ()
  "Search and insert the i18n, refreshing the cache."
  (interactive)
  (message "Reading the yml files.  it can take some time...")
  (let* ((collection (rails-i18n--parse-yamls))
         (selected-i18n (completing-read "Select your I18n: " collection)))
    (rails-i18n--set-cache collection)
    (rails-i18n--insert-i18n selected-i18n)))

;;;###autoload
(defun rails-i18n-insert-with-cache ()
  "Search and insert the i18n, searching on cache.  If cache is nil, refresh the cache."
  (interactive)
  (let ((cached-i18n (rails-i18n--get-cached)))
    (if cached-i18n
        (rails-i18n--insert-i18n (completing-read "Select your I18n: " cached-i18n))
      (rails-i18n-insert-no-cache))))

(defun rails-i18n--get-cached ()
  "Get the cached routes if not exists."
  (cdr (assoc (funcall rails-i18n-project-name-function) rails-i18n-cache)))

(defun rails-i18n--insert-i18n (i18n-string)
  "Insert the i18n on code. I18N-STRING: string to be inserted."
  (let ((ignore-class (rails-i18n--guess-use-class))
        (has-arguments (string-match-p "%{\\([a-z]+[_]*[a-z]*\\)}"
                                       (nth 1 (split-string i18n-string rails-i18n-separator)))))
    (insert
     (if ignore-class "" "I18n.")
     "t(" (rails-i18n--quotes) (rails-i18n--format-substring i18n-string ignore-class) (rails-i18n--quotes) ")")
    (when has-arguments (forward-char -1) (insert ", "))))

(defun rails-i18n--format-substring (i18n-string ignore-class)
  "Format the substring depending of mode. IGNORE-CLASS: boolean taht indicates if I18n class was ignored. I18N-STRING: String to be inserted."
  (let ((string-to-be-inserted (nth 0 (split-string i18n-string rails-i18n-separator))))
    (if
        ignore-class
        (rails-i18n--insert-for-view string-to-be-inserted)
      string-to-be-inserted)))

(defun rails-i18n--insert-for-view (i18n-string)
  "Insert with view rules. I18N-STRING: String to be inserted."
  (let ((string-to-be-inserted (substring i18n-string 1 (length i18n-string))))
    (if (string-match "app/views" (buffer-file-name))
        (replace-regexp-in-string (rails-i18n--controller-and-action-name) "" string-to-be-inserted)
      string-to-be-inserted)))

(defun rails-i18n--controller-and-action-name ()
  "Current controller and action."
  (let*
      ((without-project-name (replace-regexp-in-string (concat (funcall rails-i18n-project-root-function) "app/views") "" (buffer-file-name)))
       (without-underline (replace-regexp-in-string "/_" "/" without-project-name))
       (slash-changed (replace-regexp-in-string "/" "." without-underline))
       (fixed-string (string-join (butlast (split-string slash-changed "\\.") 2) ".")))
    (substring fixed-string 1 (length fixed-string))))

(defun rails-i18n--guess-use-class ()
  "Guess if current file needs to pass the class."
  (string-match-p "app/views\\|app/helpers" (buffer-file-name)))

(defun rails-i18n--set-cache (val)
  "Set the cache values. VAL:  Value to set."
  (when (assoc (funcall rails-i18n-project-name-function) rails-i18n-cache)
    (setq rails-i18n-cache (remove (assoc (funcall rails-i18n-project-name-function) rails-i18n-cache) rails-i18n-cache)))
  (setq rails-i18n-cache (cons `(,(funcall rails-i18n-project-name-function) . ,val) rails-i18n-cache)))

(defun rails-i18n--parse-yamls ()
  "Return the parsed yaml list."
  (let ((files (rails-i18n--get-yaml-files))
        (result))
    (mapc
     (lambda (file)
       (let ((parsed-file (rails-i18n--read-lines file)))
         (if (eq (type-of parsed-file) 'hash-table)
             (push (flatten-list
                    (rails-i18n--parse-yaml
                     []
                     parsed-file )) result)
           (message "[warning] Cannot read %s - error on parse. (keep calm, still loading the yamls.)"
                    (file-name-nondirectory file)))))
     files)
    (-distinct (flatten-list result))))

(defun rails-i18n--get-yaml-files ()
  "Find all i18n files."
  (directory-files-recursively
   (concat (funcall rails-i18n-project-root-function) rails-i18n-locales-directory) rails-i18n-locales-regexp))

(defun rails-i18n--parse-yaml (previous-key yaml-hash-table)
  "Parse the yaml into an single list.  PREVIOUS-KEY: key to be mounted.  YAML-HASH-TABLE:  Value to be parsed."
  (if (eq (type-of yaml-hash-table) 'hash-table)
      (progn
        (let (result)
          (maphash
           (lambda (k v)
             (push (rails-i18n--parse-yaml
                    (append previous-key
                            (make-vector 1 (format "%s" k)) nil) v) result))
           yaml-hash-table)

          result))
    (rails-i18n--mount-string previous-key yaml-hash-table)))

(defun rails-i18n--mount-string (previous-key string)
  "Create the string to be selected. PREVIOUS-KEY: list of keys to mount. STRING: Value to the i18n."
  (concat "."
          (string-join (remove (nth 0 previous-key) previous-key) ".")
          rails-i18n-separator
          (propertize (format "%s" string) 'face 'bold)))

(defun rails-i18n--watch-rb ()
  "Watch if yaml file is saved, if its a i18n file, upgrade cache."
  (when (and
         (buffer-file-name)
         (string-match-p rails-i18n-locales-regexp (file-name-nondirectory (buffer-file-name)))
         (string-match-p rails-i18n-locales-directory (buffer-file-name)))
    (add-hook 'after-save-hook #'rails-i18n--upgrade-single-file-cache 100 t)))

(defun rails-i18n--upgrade-cache-for (result)
  "Upgrade cache for just one project / file.  RESULT:  Texts to be upgraded."
  (let* ((currentI18n (cdr (assoc (funcall rails-i18n-project-name-function) rails-i18n-cache)))
         (cleanedI18n (rails-i18n--remove-old currentI18n result)))
    (rplacd (assoc (funcall rails-i18n-project-name-function) rails-i18n-cache)
            (-distinct (flatten-list (push result cleanedI18n))))))

(defun rails-i18n--remove-old (current-i18n result)
  "Remove old i18n and change to new. CURRENT-I18N: i18n at moment, RESULT: new file i18ns parsed."
  (mapcar
   (lambda (element)
     (when
         (not (cl-member (nth 0 (split-string element rails-i18n-separator))
                         (mapcar (lambda (oldElement) (nth 0 (split-string oldElement rails-i18n-separator))) result)
                         :test #'string-match))
       element))
   current-i18n))

(defun rails-i18n--upgrade-single-file-cache ()
  "Upgrade rails-i18n when file is changed (when possible)."
  (let* ((yaml (rails-i18n--read-lines (buffer-file-name)))
         (has-cache (rails-i18n--get-cached))
         (result))
    (if (and (eq (type-of yaml) 'hash-table) has-cache)
        (progn
          (message "Upgrading file cache (rails-i18n)...  Press C-g to cancel.")
          (push (flatten-list
                 (rails-i18n--parse-yaml
                  []
                  yaml )) result)
          (rails-i18n--upgrade-cache-for (-distinct (flatten-list result)))
          (message "Cache upgraded!"))
      (message "Rails i18n: Cache not found or cannot parse yaml."))))

(defun rails-i18n--add-to-savehist ()
  "Add rails-i18n-cache to savehist."
  (add-to-list 'savehist-additional-variables 'rails-i18n-cache))

;;;###autoload
(define-minor-mode rails-i18n-global-mode
  "Toggle cache hooks and watchs for rails-i18n."
  :global t
  :lighter " i18n"
  (if rails-i18n-global-mode
      (progn
        (add-to-list 'savehist-additional-variables 'rails-i18n-cache)
        (add-hook rails-i18n-yaml-mode-hook #'rails-i18n--watch-rb))
    (progn
      (setq savehist-additional-variables (delete 'rails-i18n-cache savehist-additional-variables))
      (remove-hook rails-i18n-yaml-mode-hook #'rails-i18n--watch-rb))))

(provide 'rails-i18n)
;;; rails-i18n.el ends here
