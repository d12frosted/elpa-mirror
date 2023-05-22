;;; harpoon.el --- Bookmarks on steroids    -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Otávio Schwanck

;; Author: Otávio Schwanck <otavioschwanck@gmail.com>
;; Keywords: tools languages
;; Package-Version: 20230521.1907
;; Package-Commit: 7b64b701e46b9117217c8b01e49e00db78463985
;; Homepage: https://github.com/otavioschwanck/harpoon.el
;; Version: 0.5
;; Package-Requires: ((emacs "27.2") (f "0.20.0") (hydra "0.14.0") (project "0.8.1"))

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
;;; 0.5
;;; Fix when project is not loaded
;;;
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
   ((eq harpoon-project-package 'project) (replace-regexp-in-string "~/"
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
  (let* ((splitted-project-path (split-string (car (last (project-current))) "/"))
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
    (make-directory harpoon-cache-file t)))

(defun harpoon--file-name ()
  "File name for harpoon on current project."
  (concat harpoon-cache-file (harpoon--cache-key)))

(defun harpoon--buffer-file-name ()
  "Parse harpoon file name."
  (if (harpoon--has-project) (s-replace-regexp (harpoon-project-root-function) "" (buffer-file-name)) (buffer-file-name)))

(defun harpoon--sanitize (string)
  "Sanitize word to save file.  STRING: String to sanitize."
  (s-replace-regexp "/" "---" string))

;;;###autoload
(defun harpoon-go-to (line-number)
  "Go to specific file on harpoon (by line order). LINE-NUMBER: Line to go."
  (require 'project)

  (let* ((file-name (s-replace-regexp "\n" ""
                                      (with-temp-buffer
                                        (insert-file-contents-literally
                                         (if (eq major-mode 'harpoon-mode)
                                             (file-truename (buffer-file-name))
                                           (harpoon--file-name)))
                                        (goto-char (point-min))
                                        (forward-line (- line-number 1))
                                        (buffer-substring-no-properties (line-beginning-position) (line-end-position)))))
         (full-file-name (if (and (fboundp 'project-root) (harpoon--has-project)) (concat (or harpoon--project-path (harpoon-project-root-function)) file-name) file-name)))
    (if (file-exists-p full-file-name)
        (find-file full-file-name)
      (message (concat full-file-name " not found.")))))

(defun harpoon--delete (line-number)
  "Delete an item on harpoon. LINE-NUMBER: Line of item to delete."
  (harpoon-toggle-file)
  (goto-char (point-min)) (forward-line (- line-number 1))
  (kill-whole-line)
  (save-buffer)
  (kill-buffer)
  (harpoon-delete-item))


;;;###autoload
(defun harpoon-delete-1 ()
  "Delete item harpoon on position 1."
  (interactive)
  (harpoon--delete 1))

;;;###autoload
(defun harpoon-delete-2 ()
  "Delete item harpoon on position 1."
  (interactive)
  (harpoon--delete 2))

;;;###autoload
(defun harpoon-delete-3 ()
  "Delete item harpoon on position 1."
  (interactive)
  (harpoon--delete 3))

;;;###autoload
(defun harpoon-delete-4 ()
  "Delete item harpoon on position 1."
  (interactive)
  (harpoon--delete 4))

;;;###autoload
(defun harpoon-delete-5 ()
  "Delete item harpoon on position 1."
  (interactive)
  (harpoon--delete 5))

;;;###autoload
(defun harpoon-delete-6 ()
  "Delete item harpoon on position 1."
  (interactive)
  (harpoon--delete 6))

;;;###autoload
(defun harpoon-delete-7 ()
  "Delete item harpoon on position 1."
  (interactive)
  (harpoon--delete 7))

;;;###autoload
(defun harpoon-delete-8 ()
  "Delete item harpoon on position 1."
  (interactive)
  (harpoon--delete 8))

;;;###autoload
(defun harpoon-delete-9 ()
  "Delete item harpoon on position 1."
  (interactive)
  (harpoon--delete 9))

;;;###autoload
(defun harpoon-go-to-1 ()
  "Go to file 1 on harpoon."
  (interactive)
  (harpoon-go-to 1))

;;;###autoload
(defun harpoon-go-to-2 ()
  "Go to file 2 on harpoon."
  (interactive)
  (harpoon-go-to 2))

;;;###autoload
(defun harpoon-go-to-3 ()
  "Go to file 3 on harpoon."
  (interactive)
  (harpoon-go-to 3))

;;;###autoload
(defun harpoon-go-to-4 ()
  "Go to file 4 on harpoon."
  (interactive)
  (harpoon-go-to 4))

;;;###autoload
(defun harpoon-go-to-5 ()
  "Go to file 5 on harpoon."
  (interactive)
  (harpoon-go-to 5))

;;;###autoload
(defun harpoon-go-to-6 ()
  "Go to file 6 on harpoon."
  (interactive)
  (harpoon-go-to 6))

;;;###autoload
(defun harpoon-go-to-7 ()
  "Go to file 7 on harpoon."
  (interactive)
  (harpoon-go-to 7))

;;;###autoload
(defun harpoon-go-to-8 ()
  "Go to file 8 on harpoon."
  (interactive)
  (harpoon-go-to 8))

;;;###autoload
(defun harpoon-go-to-9 ()
  "Go to file 9 on harpoon."
  (interactive)
  (harpoon-go-to 9))

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
  (let ((candidates (harpoon--hydra-candidates "harpoon-go-to-")))
    (eval `(defhydra harpoon-hydra (:exit t :column 1)
             "

        ██╗  ██╗ █████╗ ██████╗ ██████╗  ██████╗  ██████╗ ███╗   ██╗
        ██║  ██║██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██╔═══██╗████╗  ██║
        ███████║███████║██████╔╝██████╔╝██║   ██║██║   ██║██╔██╗ ██║
        ██╔══██║██╔══██║██╔══██╗██╔═══╝ ██║   ██║██║   ██║██║╚██╗██║
        ██║  ██║██║  ██║██║  ██║██║     ╚██████╔╝╚██████╔╝██║ ╚████║
        ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝      ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝
                                                            "
             ,@candidates
             ("SPC" harpoon-toggle-quick-menu "Open Menu" :column "Other Actions")
             ("d" harpoon-delete-item "Delete some harpoon" :column "Other Actions")
             ("f" harpoon-toggle-file "Open Harpoon File" :column "Other Actions")
             ("c" harpoon-clear "Clear Harpoon" :column "Other Actions")
             ("s" harpoon-add-file "Save Current File to Harpoon" :column "Other Actions"))))

  (when (fboundp 'harpoon-hydra/body) (harpoon-hydra/body)))


(defun harpoon--hydra-candidates (method)
  "Candidates for hydra. METHOD = Method to execute on harpoon item."
  (let ((line-number 0)
        (full-candidates (seq-take (delete "" (split-string (harpoon--get-file-text) "\n")) 9)))
    (mapcar (lambda (item)
              (setq line-number (+ 1 line-number))
              (list (format "%s" line-number)
                    (intern (concat method (format "%s" line-number)))
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


;;;###autoload
(defun harpoon-delete-item ()
  "Delete items on harpoon."
  (interactive)
  (let ((candidates (harpoon--hydra-candidates "harpoon-delete-")))
    (eval `(defhydra harpoon-delete-hydra (:exit t :column 1 :color red)
             "

   /0000000\\
   | 00000 |
   | | | | |
   | TRASH |
   | | | | |
   \\-------/

Select items to delete:
"
             ,@candidates
             ("SPC" harpoon-quick-menu-hydra "Back to harpoon" :column "Other Actions")
             ("q" hydra-keyboard-quit "Quit" :column "Other Actions"))))

  (when (fboundp 'harpoon-delete-hydra/body) (harpoon-delete-hydra/body)))


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
