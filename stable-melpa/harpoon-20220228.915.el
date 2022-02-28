;;; harpoon.el --- Bookmarks on steroids    -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Otávio Schwanck

;; Author: Otávio Schwanck <otavioschwanck@gmail.com>
;; Keywords: tools languages
;; Package-Version: 20220228.915
;; Package-Commit: 0b0f98fca3f40db88c27c0005f20f5b4c37f7e01
;; Homepage: https://github.com/otavioschwanck/harpoon.el
;; Version: 0.4
;; Package-Requires: ((emacs "27.2") (f "0.20.0") (hydra "0.14.0"))

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

;; This is a plugin base on harpoon from vim (by ThePrimeagen).  Is like a
;; bookmark manager on steroids.
;; You can easily add, reorder and delete bookmarks.  The bookmarks are
;; separated by project and branch.

;;; Changelog
;;; 0.4
;;; Added hydra support

;;; Code:
(require 'f)
(require 'subr-x)

(defun harpoon--default-project-package ()
  "Return the default project package."
  (if (featurep 'projectile) 'projectile 'project))

(defvar harpoon-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<return>") #'harpoon-find-file) map))

(defgroup harpoon nil
  "Organize bookmarks by project and branch."
  :group 'tools)

(defcustom harpoon-without-project-function 'harpoon--package-name
  "When project is not found, use this function instead."
  :type 'string)

(defcustom harpoon-cache-file (concat user-emacs-directory ".local/harpoon/")
  "Where the cache will be saved."
  :type 'string)

(defcustom harpoon-project-package (harpoon--default-project-package)
  "Project package to access project functions."
  :type 'symbol)

(defcustom harpoon-separate-by-branch t
  "Harpoon separated by branch."
  :type 'boolean)

(defvar harpoon-cache '()
  "Cache for harpoon.")

(defvar harpoon--current-project-path nil
  "Current project path on harpoon.  Its only transactional.")

(defvar harpoon--project-path nil
  "Current project name on harpoon.  Its only transactional.")

(defvar harpoon-cache-loaded nil
  "Cache for harpoon.")

(defun harpoon-project-root-function ()
  "Get the project root."
  (cond
   ((eq harpoon-project-package 'projectile) (when (fboundp 'projectile-project-root) (projectile-project-root)))
   ((eq harpoon-project-package 'project) (string-replace "~/"
                                                          (concat (car (split-string
                                                                        (shell-command-to-string "echo $HOME") "\n")) "/")
                                                          (when (fboundp 'project-root) (project-root (project-current)))))))

(defun harpoon--current-file-directory ()
  "Return current directory path sanitized."
  (harpoon--sanitize (file-name-directory buffer-file-name)))

(defun harpoon--has-project ()
  "Get the project name."
  (let ((project-name (harpoon--get-project-name)))
    (not (or (string= project-name "") (string= project-name "-") (string= project-name nil)))))

(defun harpoon--get-project-name ()
  "Get the harpoon project name."
  (condition-case nil (cond
   ((eq harpoon-project-package 'projectile) (when (fboundp 'projectile-project-name) (projectile-project-name)))
   ((eq harpoon-project-package 'project) (harpoon--get-project-name-for-project)))
    (error nil)))

(defun harpoon-project-name-function ()
  "Get the project name."
  (if (harpoon--has-project) (harpoon--get-project-name) (funcall harpoon-without-project-function)))

(defun harpoon--get-project-name-for-project ()
  "Return projects name for project."
  (let* ((splitted-project-path (split-string (cdr (project-current)) "/"))
         (splitted-length (length splitted-project-path))
         (project-name (nth (- splitted-length 2) splitted-project-path)))
    project-name))

(defun harpoon--get-branch-name ()
  "Get the branch name for harpoon."
  (car (split-string
        (shell-command-to-string
         (concat "cd " (harpoon-project-root-function) "; git rev-parse --abbrev-ref HEAD")) "\n")))

(defun harpoon--cache-key ()
  "Key to save current file on cache."
  (if (harpoon--has-project) (if harpoon-separate-by-branch
      (concat (harpoon--sanitize (harpoon-project-name-function))
              "#"
              (harpoon--sanitize (harpoon--get-branch-name)))
    (harpoon--sanitize (harpoon-project-name-function)))
    (harpoon--sanitize (harpoon-project-name-function))))

(defun harpoon--create-directory ()
  "Create harpoon cache dir if doesn't exist."
  (unless (f-directory? harpoon-cache-file)
    (make-directory harpoon-cache-file)))


(defun harpoon--file-name ()
  "File name for harpoon on current project."
  (concat harpoon-cache-file (harpoon--cache-key)))

(defun harpoon--buffer-file-name ()
  "Parse harpoon file name."
  (if (harpoon--has-project) (s-replace-regexp (harpoon-project-root-function) "" (buffer-file-name)) (buffer-file-name)))

(defun harpoon--sanitize (string)
  "Sanitize word to save file.  STRING: String to sanitize."
  (s-replace-regexp "/" "---" string))

(defun harpoon--go-to (line-number)
  "Go to specific file on harpoon (by line order). LINE-NUMBER: Line to go."
  (let* ((file-name (s-replace-regexp "\n" ""
                                      (shell-command-to-string
                                       (format "head -n %s < %s | tail -n 1"
                                               line-number
                                               (if (eq major-mode 'harpoon-mode) (file-truename (buffer-file-name)) (harpoon--file-name))))))
         (full-file-name (if (and (fboundp 'project-root) (harpoon--has-project)) (concat (or harpoon--project-path (harpoon-project-root-function)) file-name) file-name)))
    (if (file-exists-p full-file-name)
        (find-file full-file-name)
      (message "File not found."))))

;;;###autoload
(defun harpoon-go-to-1 ()
  "Go to file 1 on harpoon."
  (interactive)
  (harpoon--go-to 1))

;;;###autoload
(defun harpoon-go-to-2 ()
  "Go to file 2 on harpoon."
  (interactive)
  (harpoon--go-to 2))

;;;###autoload
(defun harpoon-go-to-3 ()
  "Go to file 3 on harpoon."
  (interactive)
  (harpoon--go-to 3))

;;;###autoload
(defun harpoon-go-to-4 ()
  "Go to file 4 on harpoon."
  (interactive)
  (harpoon--go-to 4))

;;;###autoload
(defun harpoon-go-to-5 ()
  "Go to file 5 on harpoon."
  (interactive)
  (harpoon--go-to 5))

;;;###autoload
(defun harpoon-go-to-6 ()
  "Go to file 6 on harpoon."
  (interactive)
  (harpoon--go-to 6))

;;;###autoload
(defun harpoon-go-to-7 ()
  "Go to file 7 on harpoon."
  (interactive)
  (harpoon--go-to 7))

;;;###autoload
(defun harpoon-go-to-8 ()
  "Go to file 8 on harpoon."
  (interactive)
  (harpoon--go-to 8))

;;;###autoload
(defun harpoon-go-to-9 ()
  "Go to file 9 on harpoon."
  (interactive)
  (harpoon--go-to 9))

;;;###autoload
(defun harpoon-add-file ()
  "Add current file to harpoon."
  (interactive)
  (harpoon--create-directory)
  (let ((harpoon-current-file-text
         (harpoon--get-file-text)))
    (if (string-match-p (harpoon--buffer-file-name) harpoon-current-file-text)
        (message "This file is already on harpoon.")
      (progn
        (f-write-text (concat harpoon-current-file-text (harpoon--buffer-file-name) "\n") 'utf-8 (harpoon--file-name))
        (message "File added to harpoon.")))))

;;;###autoload
(defun harpoon-quick-menu-hydra ()
  "Open harpoon quick menu with hydra."
  (interactive)
  (require 'hydra)
  (let ((candidates (harpoon--hydra-candidates)))
    (eval `(defhydra harpoon-hydra (:exit t :column 1)
"
          ||                          ||
          ||  ╭╮ ╭╮                   ||
          ||  ┃┃ ┃┃                   ||
          ||  ┃╰━╯┣━━┳━┳━━┳━━┳━━┳━╮   ||
          ||  ┃╭━╮┃╭╮┃╭┫╭╮┃╭╮┃╭╮┃╭╮╮  ||
          ||  ┃┃ ┃┃╭╮┃┃┃╰╯┃╰╯┃╰╯┃┃┃┃  ||
          ||  ╰╯ ╰┻╯╰┻╯┃╭━┻━━┻━━┻╯╰╯  ||
          ||           ┃┃             ||
          ||           ╰╯             ||
          ||                          ||
"
             ,@candidates
             ("SPC" harpoon-toggle-quick-menu "Open Menu" :column "Other Actions")
             ("f" harpoon-toggle-file "Open Harpoon File" :column "Other Actions")
             ("c" harpoon-clear "Clear Harpoon" :column "Other Actions")
             ("s" harpoon-add-file "Save Current File to Harpoon" :column "Other Actions"))))

  (when (fboundp 'harpoon-hydra/body) (harpoon-hydra/body)))

(defun harpoon--hydra-candidates ()
  "Candidates for hydra."
  (let ((line-number 0)
        (full-candidates (seq-take (delete "" (split-string (harpoon--get-file-text) "\n")) 9)))
    (mapcar (lambda (item)
              (setq line-number (+ 1 line-number))
              (list (format "%s" line-number)
                    (intern (concat "harpoon-go-to-" (format "%s" line-number)))
                    (harpoon--format-item-name item)
                    :column (if (< line-number 6) "1-5" "6-9")))
            full-candidates)))

(defun harpoon--format-item-name (item)
  "Format item on harpoon. ITEM = Item to be formated.
FULL-CANDIDATES:  Candidates to be edited."
  (if (string-match-p "/" item)
      (let ((splitted-item (split-string item "/")))
        (harpoon--already-includes-text item splitted-item)) item))

(defun harpoon--already-includes-text (item splitted-item)
  "Return the name to be used on hydra.
ITEM = Full item.  SPLITTED-ITEM = Item splitted.
FULL-CANDIDATES = All candidates to look."
  (let ((file-base-name (nth (- (length splitted-item) 1) splitted-item))
        (candidates (seq-take (delete "" (split-string (harpoon--get-file-text) "\n")) 9)))
    (if (member file-base-name (mapcar (lambda (x)
                                         (nth (- (length (split-string x "/")) 1) (split-string x "/")))
                                       (delete item candidates)))
        (concat file-base-name " at " (string-join (butlast splitted-item) "/"))
      file-base-name)))

(defun harpoon--get-file-text ()
  "Get text inside harpoon file."
  (if (file-exists-p (harpoon--file-name))
      (f-read (harpoon--file-name) 'utf-8) ""))

(defun harpoon--package-name ()
  "Return harpoon package name."
  "harpoon")

;;;###autoload
(defun harpoon-toggle-file ()
  "Open harpoon file."
  (interactive)
  (unless (eq major-mode 'harpoon-mode)
    (harpoon--create-directory)
    (setq harpoon--current-project-path (when (harpoon--has-project) (harpoon-project-root-function)))
    (find-file (harpoon--file-name) '(:dedicated t))
    (harpoon-mode)))

;;;###autoload
(defun harpoon-toggle-quick-menu ()
  "Open quickmenu."
  (interactive)
  (let ((result (harpoon--fix-quick-menu-items)))
    (when (and result (not (string-equal result "")))
      (find-file (if (harpoon--has-project) (concat (harpoon-project-root-function) (harpoon--remove-number result))
                   (harpoon--remove-number result))))))

(defun harpoon--remove-number (file)
  "Remove number of the file. FILE = Filename to remove the number."
  (nth 1 (split-string file " - ")))

(defun harpoon--fix-quick-menu-items ()
  "Fix harpoon quick menu items."
  (if (harpoon--has-project)
      (completing-read "Harpoon to file: " (harpoon--add-numbers-to-quick-menu (delete "" (split-string (harpoon--get-file-text) "\n"))))
    (completing-read "Harpoon to file: " (harpoon--add-numbers-to-quick-menu (delete "" (split-string (harpoon--get-file-text) "\n"))))))

(defun harpoon--add-numbers-to-quick-menu (files)
  "Add numbers to files.  FILES = Files to add the numbers."
  (let ((line-number 0))
    (mapcar (lambda (line) (setq line-number (+ 1 line-number)) (concat (format "%s" line-number) " - " line)) files)))

(define-derived-mode harpoon-mode nil "Harpoon"
  "Mode for harpoon."
  (setq-local require-final-newline mode-require-final-newline)
  (setq-local harpoon--project-path harpoon--current-project-path)
  (setq harpoon--current-project-path nil)
  (display-line-numbers-mode t))

;;;###autoload
(defun harpoon-clear ()
  "Clear harpoon files."
  (interactive)
  (when (yes-or-no-p "Do you really want to clear harpoon file? ")
    (if (eq major-mode 'harpoon-mode)
        (progn (f-write "" 'utf-8 (file-truename (buffer-file-name)))
               (kill-buffer))
      (f-write "" 'utf-8 (harpoon--file-name)))
    (message "Harpoon cleaned.")))

;;;###autoload
(defun harpoon-find-file ()
  "Visit file on `harpoon-mode'."
  (interactive)
  (let* ((line (buffer-substring-no-properties (point-at-bol) (point-at-eol)))
         (path (concat harpoon--project-path line)))
    (if (file-exists-p path)
        (progn (save-buffer)
               (kill-buffer)
               (find-file path))
      (message "File not found."))))

(provide 'harpoon)
;;; harpoon.el ends here
