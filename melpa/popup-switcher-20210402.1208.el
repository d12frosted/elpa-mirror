;;; popup-switcher.el --- switch to other buffers and files via popup. -*- lexical-binding: t -*-

;; Copyright (C) 2013-2020  Kostafey <kostafey@gmail.com>

;; Author: Kostafey <kostafey@gmail.com>
;; URL: https://github.com/kostafey/popup-switcher
;; Package-Version: 20210402.1208
;; Package-Commit: 94e01b9ea7970e86ed0f2fbeaa8cd320b60ae821
;; Keywords: popup, switch, buffers, functions
;; Version: 0.2.15
;; Package-Requires: ((cl-lib "0.3")(popup "0.5.3")(dash "2.10.0"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software Foundation,
;; Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.  */

(require 'cl-lib)
(require 'popup)
(require 'artist)
(require 'recentf)
(require 'dash)                         ; use -mapcat inside psw-flatten-index
(require 'imenu)

(defgroup popup-switcher nil
  "Switch to other buffers and files via popup."
  :group 'popup
  :prefix "psw"
  :link '(url-link "https://github.com/kostafey/popup-switcher"))

(defcustom psw-use-flx nil
  "Non-nil enables `flx' fuzzy matching engine for isearch in popup menus."
  :group 'popup-switcher
  :type 'boolean)

(defcustom psw-popup-position 'fill-column
  "Defines popup position.  Possible values are one of:
point - open popup at point.
center - open popup at window center
fill-column - centered relative to `fill-column'"
  :group 'popup-switcher
  :type '(choice
	  (const :tag "point" :value point)
	  (const :tag "center" :value center)
	  (const :tag "fill-column" :value fill-column)))

(defcustom psw-popup-menu-max-length 15
  "Set maximum number of visible items in popup menus."
  :group 'popup-switcher
  :type 'integer)

(defcustom psw-mark-modified-buffers nil
  "Non-nil means mark modified buffers with star char (*)"
  :type 'boolean
  :group 'popup-switcher)

(defcustom psw-before-menu-hook nil
  "Hook runs before menu showed"
  :type 'hook
  :group 'popup-switcher)

(defcustom psw-after-switch-hook nil
  "Hook runs after buffer switch"
  :type 'hook
  :group 'popup-switcher)

(defcustom psw-uneditable-modes '(circe-channel-mode
                                  circe-query-mode
                                  circe-server-mode
                                  slime-repl-mode
                                  shell-mode)
  "List of major modes unsuitable to keep buffer text manually.
Consequences of menu drawing and probable text changing should not be removed
by buffer editing for this comint-like modes."
  :type 'list
  :group 'popup-switcher)

(defcustom psw-enable-single-dot-to-navigate-files nil
  "Add single dot '.' item to `psw-navigate-files' fn list.
When t any time you run `psw-navigate-files' fn you can select this dot '.'
item, which opens `dired-mode' for current directory."
  :type 'boolean
  :group 'popup-switcher)

(defcustom psw-highlight-previous-buffer nil
  "When t highlight previous buffer for `psw-switch-buffer' fn list.
Highlight current buffer for `psw-switch-buffer' when nil (by default)."
  :type 'boolean
  :group 'popup-switcher)

(defun psw-window-line-number ()
  (save-excursion
    (goto-char (window-start))
    (line-number-at-pos)))

(cl-defun psw-is-temp-buffer (&optional buffer)
  "Find buffers with names bounded with stars like *Messages* or *scratch*."
  (with-current-buffer (or buffer (current-buffer))
    (let ((buffer-name-length (length (buffer-name))))
      (and
       (equal "*" (substring (buffer-name) 0 1))
       (equal "*" (substring (buffer-name)
                             (1- buffer-name-length)
                             buffer-name-length))))))

(defun psw-get-buffer-list (file-buffers-only)
  (cl-remove-if (lambda (buf) (or (minibufferp buf)
                                  (let ((buf-name (buffer-name buf)))
                                    (and (>= (length buf-name) 2)
                                         (equal (substring buf-name 0 2) " *")))
                                  (if file-buffers-only
                                      (or (not (with-current-buffer buf
                                                 (buffer-file-name)))
                                          (psw-is-temp-buffer buf)))))
                (buffer-list)))

(defun psw-copy-face (old-face new-face)
  "Safe copy face to handle absence of `flx-highlight-face' if
`flx-ido' is not installed."
  (when psw-use-flx
    (if (facep old-face)
        (copy-face old-face new-face)
      (setq new-face nil))))

(defvar psw-buffer-modified t
  "Current buffer original modified state.")

(defun psw-popup-menu-point (menu-height popup-items &optional position)
  "Calculate the point for a popup menu.
MENU-HEIGHT - required menu height,
POPUP-ITEMS - items to be shown in the popup,
POSITION - if set, overrides `psw-popup-position' value."
  (let* ((popup-position (or position psw-popup-position 'fill-column)))
    (if (eq popup-position 'point)
        (point)
      (let* ((x (+ (/ (- (if (eq popup-position 'center)
                             (window-width)
                           fill-column)
                         (apply 'max (mapcar 'length popup-items)))
                      2)
                   (window-hscroll)))
             (y (+ (- (psw-window-line-number) 2)
                   (/ (- (window-height) menu-height) 2))))
        (save-excursion
          (artist-move-to-xy x y)
          (point))))))

(cl-defun psw-popup-menu (&key
                          item-names-list
                          fallback
                          (position nil)
                          (initial-index nil))
  "Popup selection menu.
ITEM-NAMES-LIST - list of item names to select.
FALLBACK - popup loop unexpected key handler.
POSITION - if set, overrides `psw-popup-position' var value.
INITIAL-INDEX - if non-nil, provides an initial selected  menu item."
  (if (equal (length item-names-list) 0)
      (error "Popup menu items list is empty."))
  (let* ((menu-height (min psw-popup-menu-max-length
                           (length item-names-list)
                           (- (window-height) 4)))
         (modified (buffer-modified-p))
         (saved-text (buffer-substring (window-start) (window-end)))
         (old-pos (point))
         (inhibit-read-only t))
    (psw-copy-face 'flx-highlight-face 'psw-temp-face)
    (setq psw-buffer-modified modified)
    (save-excursion
      (beginning-of-line)
      (unwind-protect
          (progn
            (psw-copy-face 'popup-isearch-match 'flx-highlight-face)
            (let* ((menu-pos (psw-popup-menu-point
                              menu-height item-names-list position))
                   (target-item-name (popup-menu* item-names-list
                                                  :point menu-pos
                                                  :height menu-height
                                                  :scroll-bar t
                                                  :margin-left 1
                                                  :margin-right 1
                                                  :around t
                                                  :isearch t
                                                  :fallback fallback
                                                  :initial-index initial-index)))
              target-item-name))
        (progn
          (when (and (buffer-modified-p)
                     (not (member major-mode psw-uneditable-modes)))
            (delete-region (window-start) (window-end))
            (insert saved-text)
            (goto-char old-pos)
            (set-buffer-modified-p modified))
          (psw-copy-face 'psw-temp-face 'flx-highlight-face))))))

(defadvice popup-isearch-filter-list (around
                                      psw-popup-isearch-filter-list
                                      activate)
  "Choose between the regular popup-isearch-filter-list and flx-ido-match-internal"
  (if (and psw-use-flx
           (> (length pattern) 0))
      (if (not (require 'flx nil t))
          (progn
            ad-do-it
            (message "Please install flx.el and flx-ido.el if you use fuzzy completion"))
        (if (eq :too-big
                (catch :too-big
                  (setq ad-return-value (flx-ido-match-internal pattern list))))
            ad-do-it))
    ad-do-it))

(defun psw-nil? (x) (equal nil x))

(defun psw-zip (x y)
  (cl-mapcar #'list (setcdr (last x) x) y))

(defun psw-flatten (list-of-lists)
  (apply #'append list-of-lists))

(defun psw-compose (&rest funs)
  "Return function composed of FUNS."
  (let ((lex-funs funs))
    (lambda (&rest args)
      (cl-reduce 'funcall (butlast lex-funs)
                 :from-end t
                 :initial-value (apply (car (last lex-funs)) args)))))

(defun psw-get-plain-string (properties-string)
  "Remove text properties from the string."
  (format "%s" (intern properties-string)))

(cl-defun psw-get-item-by-name (&key item-names-list
                                     items-list
                                     target-item-name)
  "Return the item by it's name."
  (let ((items-map (psw-flatten (psw-zip item-names-list items-list))))
    (lax-plist-get items-map target-item-name)))

(cl-defun psw-switcher (&key
                        items-list
                        item-name-getter
                        switcher
                        (fallback 'popup-menu-fallback)
                        (position nil)
                        (initial-index nil))
  "Simplify create new popup switchers.
ITEMS-LIST - the essence items list to select.
ITEM-NAME-GETTER - function to convert each item to it's text representation.
SWITCHER - function, that describes what do with the selected item.
POSITION - if set, overrides `psw-popup-position' var value.
INITIAL-INDEX - if non-nil, provides an initial selected  menu item."
  (run-hooks 'psw-before-menu-hook)
  (let ((item-names-list (mapcar
                          (lambda (x) (funcall
                                  (psw-compose 'psw-get-plain-string
                                               item-name-getter) x))
                          items-list)))
    (funcall switcher
             (psw-get-item-by-name
              :item-names-list item-names-list
              :items-list items-list
              :target-item-name (psw-popup-menu
                                 :item-names-list item-names-list
                                 :fallback fallback
                                 :position position
                                 :initial-index initial-index))))
  (run-hooks 'psw-after-switch-hook))

;;;###autoload
(defun psw-switch-buffer (&optional arg)
  "Show buffers list menu to switch buffer.
If ARG show only buffers with files and without * in the beginning and end of
the buffer name."
  (interactive "P")
  (psw-switcher
   :items-list (psw-get-buffer-list arg)
   :item-name-getter (lambda (buffer)
                       (with-current-buffer buffer
                         (if (and psw-mark-modified-buffers
                                  (buffer-modified-p)
                                  (not (psw-is-temp-buffer)))
                             (concat (buffer-name) " *")
                           (buffer-name))))
   :switcher 'switch-to-buffer
   :fallback (lambda (key _)
               (if (or (equal (kbd "C-k") key)
                       (equal (kbd "C-d") key))
                   (let* ((menu (car popup-instances))
                          (buff (nth (popup-cursor menu)
                                     (popup-list menu)))
                          (same-buffer-p (when (and (equal
                                                     (buffer-name
                                                      (current-buffer))
                                                     buff))
                                           (set-buffer-modified-p
                                            psw-buffer-modified)
                                           t)))
                     (when (kill-buffer buff)
                       (if (not same-buffer-p)
                           (progn
                             (if (= (1+ (popup-cursor menu))
                                    (length (popup-list menu)))
                                 (popup-previous menu))
                             (setf (popup-list menu)
                                   (remove buff (popup-list menu))
                                   (popup-original-list menu)
                                   (remove buff (popup-original-list menu)))
                             (popup-draw menu))
                         (progn
                           (popup-delete menu)
                           (add-hook 'window-configuration-change-hook
                                     'psw-restore-menu)))))))
   :initial-index (if psw-highlight-previous-buffer 1)))

(defun psw-restore-menu ()
  "Restore menu after the current buffer killed."
  (remove-hook 'window-configuration-change-hook 'psw-restore-menu)
  (psw-switch-buffer))

;;;###autoload
(defun psw-switch-recentf ()
  (interactive)
  (psw-switcher
   :items-list recentf-list
   :item-name-getter 'identity
   :switcher 'find-file))

(defun psw--error-projectile-is-missing ()
  "Projectile is optional, but needed for some commands."
  (user-error "This command requires the projectile library. \
Please install it to use this command"))

;;;###autoload
(defun psw-switch-projectile-files ()
  (interactive)
  (if (and (require 'projectile nil :no-error)
           (fboundp 'projectile-mode)
           (fboundp 'projectile-current-project-files)
           (fboundp 'projectile-project-root))
      (psw-switcher
       :items-list (let ((current-projectile-mode projectile-mode)
                         (files (projectile-current-project-files)))
                     (setq projectile-mode current-projectile-mode)
                     files)
       :item-name-getter 'identity
       :switcher (lambda (file)
                   (find-file
                    (expand-file-name file
                                      (projectile-project-root)))))
    (psw--error-projectile-is-missing)))

;;;###autoload
(defun psw-switch-projectile-projects ()
  (interactive)
  (if (and (require 'projectile nil :no-error)
           (boundp 'projectile-known-projects)
           (fboundp 'projectile-project-files))
      (psw-switcher
       :items-list (sort
                    (cl-mapcar 'cons
                               (mapcar 'projectile-project-name
                                       projectile-known-projects)
                               projectile-known-projects)
                    (lambda (p1 p2) (string-lessp (car p1) (car p2))))
       :item-name-getter 'car
       :switcher (lambda (p)
                   (let ((p-root (cdr p)))
                     (psw-switcher
                      :items-list (projectile-project-files
                                   (expand-file-name p-root))
                      :item-name-getter 'identity
                      :switcher (lambda (file)
                                  (find-file
                                   (expand-file-name file
                                                     p-root)))))))
    (psw--error-projectile-is-missing)))

;;;###autoload
(defun psw-navigate-files (&optional start-path)
  (interactive)
  (let ((start-path (or start-path
                        (expand-file-name ".." (buffer-file-name)))))
    (psw-switcher
     :items-list (cl-remove-if
                  (lambda (path)
                    (and
                     (equal (file-name-nondirectory (car path)) ".")
                     (not psw-enable-single-dot-to-navigate-files)))
                  (directory-files-and-attributes start-path t))
     :item-name-getter (psw-compose 'file-name-nondirectory 'car)
     :switcher (lambda (entity)
                 (let* ((entity-path (car entity))
                        (entity-name (file-name-nondirectory entity-path))
                        (first-attrib (cadr entity)))
                   ;; t for directory,
                   ;; string (name linked to) for symbolic link,
                   ;; or nil.
                   (if first-attrib
                       (if (stringp first-attrib)
                           ;; is a link
                           (progn
                             (message (format "Open symbolic link to '%s'"
                                              first-attrib))
                             (find-file first-attrib))
                         ;; is a directory
                         (if (equal entity-name ".")
                             (dired entity-path)
                           (psw-navigate-files
                            (expand-file-name entity-name start-path))))
                     ;; is a file
                     (find-file entity-path)))))))

(defun psw-flatten-index (imenu-index)
  "Flatten imenu index into a plain list.
IMENU-INDEX - imenu index tree."
  (-mapcat
   (lambda (x)
     (if (imenu--subalist-p x)
         (mapcar (lambda (y) (cons (concat (car x) ":" (car y)) (cdr y)))
                 (psw-flatten-index (cdr x)))
       (list x)))
   imenu-index))

(defun psw-get-imenu-items ()
  (let ((items-list
         (delq imenu--rescan-item
               (psw-flatten-index (or imenu--index-alist
                                      (imenu--make-index-alist))))))
    (mapcar
     (lambda (x) (cons (car x) (if (overlayp (cdr x))
                              (overlay-start (cdr x))
                            (cdr x))))
     items-list)))

;;;###autoload
(defun psw-switch-function ()
  (interactive)
  (psw-switcher
   :items-list (psw-get-imenu-items)
   :item-name-getter 'car
   :switcher (psw-compose 'goto-char 'cdr)))

(provide 'popup-switcher)

;;; popup-switcher.el ends here
