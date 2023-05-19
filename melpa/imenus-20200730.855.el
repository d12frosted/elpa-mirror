;;; imenus.el --- Imenu for multiple buffers and without subgroups

;; Copyright © 2014–2018, 2020 Alex Kost

;; Author: Alex Kost <alezost@gmail.com>
;; Created: 19 Dec 2014
;; Version: 0.2
;; Package-Requires: ((cl-lib "0.5"))
;; URL: https://github.com/alezost/imenus.el
;; Keywords: tools convenience

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provides an `imenus' command which may be used as a
;; substitution for "M-x imenu".  It allows to jump to imenu items in
;; multiple buffers.  Also it provides additional key bindings for
;; rescanning, "isearch"-ing and performing "occur" using a current
;; minibuffer input.

;; To install the package manually, add the following to your init file:
;;
;;   (add-to-list 'load-path "/path/to/imenus-dir")
;;   (autoload 'imenus "imenus" nil t)
;;   (autoload 'imenus-mode-buffers "imenus" nil t)

;; The main purpose of this package is to provide a framework to use
;; `imenu' indexes of multiple buffers/files.  For example, you may
;; search for imenu items in elisp files of your "~/.emacs.d/" directory
;; with a command like this:
;;
;; (defun imenus-my-elisp-files ()
;;   "Perform `imenus' on elisp files from `user-emacs-directory'."
;;   (interactive)
;;   (imenus-files
;;    (directory-files user-emacs-directory t "^[^.].*\\.el\\'")))

;;; Code:

(require 'cl-lib)
(require 'imenu)
(require 'misearch)

(defgroup imenus nil
  "Easy jumping to buffers places."
  :group 'convenience)

(defgroup imenus-faces nil
  "Imenus faces."
  :group 'imenus
  :group 'faces)

(defface imenus-section-face
  '((t :inherit font-lock-comment-face))
  "Face used for titles of sections."
  :group 'imenus-faces)

(defcustom imenus-sort-function nil
  "Function used to sort imenus items.
The function should take 2 arguments and return t if the first
element should come before the second.  The arguments are cons
cells: (NAME . POSITION).
If nil, do not use any sorting (faster)."
  :type '(choice (const :tag "No sorting" nil)
		 (const :tag "Sort by name" imenu--sort-by-name)
		 (function :tag "Another function"))
  :group 'imenus)

(defcustom imenus-item-name-function #'imenus-item-name-default
  "Function used to name imenus items.
The function should take 3 arguments: imenu item name, imenu
subsection name and a buffer where the item come from."
  :type '(choice (function-item imenus-item-name-default)
                 (function-item imenus-item-name-full)
		 (function :tag "Another function"))
  :group 'imenus)

(defcustom imenus-delimiter "|"
  "String used to separate parts of an index item name."
  :type 'string
  :group 'imenus)

(defcustom imenus-inherit-input-method t
  "If non-nil, inherit the input method from the current buffer.
This value is passed as the last argument to
`imenus-completing-read-function'.  See `completing-read' for
details."
  :type 'boolean
  :group 'imenus)

(defvar imenus-completing-read-function completing-read-function
  "Function used to read a string from minibuffer with completions.
It should accept the same arguments as `completing-read'.")

(defvar imenus-actions
  '((isearch . imenus-isearch)
    (occur   . multi-occur))
  "Alist of exit statuses and functions.
Whenever imenus prompt is finished with a non-nil
`imenus-exit-status', an according function is called with 2
arguments: list of buffers and a user input string.")

(defvar imenus-exit-status nil
  "Exit status of the current (latest) imenus command.
This variable is used to define what action should be done after
quitting the minibuffer (rescan an index, switch to isearch, etc.)")

(defvar imenus-minibuffer-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "M-r") 'imenus-rescan)
    (define-key map (kbd "M-s") 'imenus-exit-to-isearch)
    (define-key map (kbd "M-o") 'imenus-exit-to-occur)
    map)
  "Keymap with additional imenus commands for minibuffer.")

(defvar-local imenus-index nil
  "Imenus index alist of a current buffer.
Elements in the alist have the following form:

  (ITEM-NAME . POSITION)

POSITION is the buffer position of the item.  To go to the item
is to switch to the buffer and to move point to that position.
POSITION is passed to `imenus-goto'.")

(cl-defstruct (imenus-position
               (:constructor nil)
               (:constructor imenus-make-position
                             (buffer imenu-position))
               (:copier nil))
  buffer imenu-position)

(defun imenus-minibuffer-setup ()
  "Prepare minibuffer for imenus needs."
  (use-local-map
   (make-composed-keymap imenus-minibuffer-map
                         (current-local-map))))

(declare-function ido-select-text "ido" nil)
(declare-function ivy-immediate-done "ivy" nil)

(defun imenus-exit-minibuffer ()
  "Quit the current minibuffer command.
Make this command return the current user input."
  (cond
   ((boundp 'ido-cur-item)                      ; if inside ido
    (ido-select-text))
   ((memq 'ivy--queue-exhibit post-command-hook) ; if inside ivy
    (ivy-immediate-done))
   (t (exit-minibuffer))))

(defun imenus-rescan ()
  "Rescan the current imenus index."
  (interactive)
  (setq imenus-exit-status 'rescan)
  (imenus-exit-minibuffer))

(defun imenus-exit-to-isearch ()
  "Exit from imenu prompt; start isearch with the current input."
  (interactive)
  (setq imenus-exit-status 'isearch)
  (imenus-exit-minibuffer))

(defun imenus-exit-to-occur ()
  "Exit from imenu prompt; start `occur' using the current input."
  (interactive)
  (setq imenus-exit-status 'occur)
  (imenus-exit-minibuffer))

(defun imenus-item-name-default (item-name &optional section _buffer)
  "Concatenate SECTION and ITEM-NAME with `imenus-delimiter'."
  (if section
      (concat (propertize section 'face 'imenus-section-face)
              imenus-delimiter item-name)
    item-name))

(defun imenus-item-name-full (item-name section buffer)
  "Concatenate BUFFER name, SECTION and ITEM-NAME with `imenus-delimiter'."
  (concat (buffer-name buffer) imenus-delimiter
          (imenus-item-name-default item-name section)))

(defun imenus-item-name (item-name section buffer)
  "Make an item name by calling `imenus-item-name-function'."
  (funcall (if (functionp imenus-item-name-function)
               imenus-item-name-function
             #'imenus-item-name-default)
           item-name section buffer))

(defun imenus-imenu-item-to-imenus-item (item section buffer)
  "Convert imenu index ITEM into imenus index item.
Change its name and transform imenu position into imenus position."
  (cons (imenus-item-name (car item) section buffer)
        (imenus-make-position buffer (cdr item))))

(defun imenus-imenu-index-to-imenus-index (index buffer &optional section)
  "Convert imenu INDEX into imenus index."
  (cl-mapcan (lambda (item)
               (when item
                 (if (imenu--subalist-p item)
                     (let ((name     (car item))
                           (subindex (cdr item)))
                       (imenus-imenu-index-to-imenus-index
                        subindex buffer
                        (if section
                            (concat section imenus-delimiter name)
                          name)))
                   (list (imenus-imenu-item-to-imenus-item
                          item section buffer)))))
             index))

(defun imenus-sort-index-maybe (index)
  "Sort INDEX depending on `imenus-sort-function'."
  (if (functionp imenus-sort-function)
      (sort index imenus-sort-function)
    index))

(defun imenus-buffer-index (buffer &optional rescan)
  "Return imenus index for BUFFER.
If RESCAN is non-nil, rescan imenu items.

This is an auxiliary function; do not use it if you want to get
an imenus index for a single buffer.  Use `imenus-buffers-index'
instead: it takes care about a rescan option."
  (with-current-buffer buffer
    (when (or rescan (null imenus-index))
      (setq imenu--index-alist nil)
      (imenu--make-index-alist t)
      (setq imenus-index
            (imenus-imenu-index-to-imenus-index
             imenu--index-alist buffer)))
    imenus-index))

(defun imenus-buffers-index (buffers &optional rescan)
  "Return imenus index for list of BUFFERS.
If RESCAN is non-nil, rescan imenu items."
  (let ((index (if (cdr buffers)
                   ;; Multiple buffers.
                   (cl-mapcan (lambda (buf)
                                (copy-sequence
                                 (imenus-buffer-index buf rescan)))
                              buffers)
                 ;; Single buffer.
                 (imenus-buffer-index (car buffers) rescan))))
    ;; Add a rescan option to the index.
    (cons imenu--rescan-item
          (imenus-sort-index-maybe index))))

(defun imenus-goto (item)
  "Go to imenus ITEM."
  (let* ((name       (car item))
         (imenus-pos (cdr item))
         (buffer     (imenus-position-buffer imenus-pos))
         (imenu-pos  (imenus-position-imenu-position imenus-pos)))
    (pop-to-buffer buffer
                   '((display-buffer-reuse-window
                      display-buffer-same-window)))
    (push-mark nil t)
    ;; Imenu item can have 2 forms.  See `imenu' and the docstring of
    ;; `imenu--index-alist'.
    (pcase imenu-pos
      (`(,position ,function . ,args)
       (apply function name position args))
      (position
       (funcall imenu-default-goto-function nil position)))
    (run-hooks 'imenu-after-jump-hook)))

(defun imenus-prepare-index (index)
  "Replace space with `imenu-space-replacement' in INDEX items."
  ;; The code is taken from `imenu--completion-buffer'.
  (if (not imenu-space-replacement)
      index
    (mapcar (lambda (item)
              (cons (subst-char-in-string
                     ?\s (aref imenu-space-replacement 0) (car item))
                    (cdr item)))
            index)))

(defun imenus-completing-read (index &optional prompt initial-input)
  "Prompt for an INDEX item and return it.
This function is almost the same as `imenu--completion-buffer'.
The main difference is it returns a user input string (not nil)
if this string does not match any item."
  (setq imenus-exit-status nil)
  (let* ((index (imenus-prepare-index index))
         (name (thing-at-point 'symbol))
         (name (and (stringp name)
                    (imenu-find-default name index)))
         (prompt (or prompt
                     (and name
                          (imenu--in-alist name index)
                          (format "Index item (default '%s'): " name))
                     "Index item: "))
         (minibuffer-setup-hook minibuffer-setup-hook))
    (or imenu-eager-completion-buffer
        (add-hook 'minibuffer-setup-hook 'minibuffer-completion-help))
    (add-hook 'minibuffer-setup-hook 'imenus-minibuffer-setup)
    (let* ((input (funcall imenus-completing-read-function
                           prompt index nil nil initial-input
                           'imenu--history-list name
                           imenus-inherit-input-method))
           (item (assoc input index)))
      (if (or imenus-exit-status (null item))
          input
        item))))

(defun imenus-buffers (buffers &optional rescan prompt initial-input)
  "Prompt for a place from a list of BUFFERS and jump to it.
If a user input does not match any item, start Isearch-ing of the
current input.
Interactively, use the current buffer."
  (let* ((index (imenus-buffers-index buffers rescan))
         (input (imenus-completing-read index prompt initial-input)))
    (cond ((eq imenus-exit-status 'rescan)
           (imenu--cleanup index)
           (imenus-buffers buffers 'rescan prompt input))
          ((equal input imenu--rescan-item)
           (imenu--cleanup index)
           (imenus-buffers buffers 'rescan prompt initial-input))
          (imenus-exit-status
           (let ((fun (cdr (assq imenus-exit-status imenus-actions))))
             (and fun (funcall fun buffers input))))
          ((consp input)
           (imenus-goto input)))))

(defun imenus-files (files &optional rescan prompt initial-input)
  "Perform `imenus' on FILES."
  (imenus-buffers (mapcar #'find-file-noselect files)
                  rescan prompt initial-input))

;;;###autoload
(defun imenus (buffers)
  "Prompt for a place from a list of BUFFERS and jump to it.
Interactively, use the current buffer.  With a prefix argument,
prompt for multiple buffers.

In a minibuffer prompt you may use the following commands:
\\{imenus-minibuffer-map}"
  (interactive
   (list (if current-prefix-arg
             (multi-isearch-read-buffers)
           (list (current-buffer)))))
  (imenus-buffers buffers))

;;;###autoload
(defun imenus-mode-buffers (mode)
  "Perform `imenus' on all buffers with MODE.
Interactively, use the major mode of the current buffer."
  (interactive (list major-mode))
  (let ((buffers (cl-remove-if-not
                  (lambda (buf)
                    (eq (buffer-local-value 'major-mode buf)
                        mode))
                  (buffer-list))))
    (imenus-buffers buffers)))


;;; Isearch

(defvar imenus-isearch-string nil
  "String to be used as a default isearch string.")

(defun imenus-isearch (buffers &optional string)
  "Start Isearch on a list of BUFFERS.
Use STRING as an initial string for searching."
  (let ((imenus-isearch-string string))
    (when (and string
               (not (string= string "")))
      (if (cdr buffers)
          (multi-isearch-buffers buffers)
        (isearch-mode t))
      (isearch-search)
      (isearch-push-state)
      (isearch-update))))

(defun imenus-isearch-setup ()
  "Set up isearch for searching `imenus-isearch-string'.
Intended to be added to `isearch-mode-hook'."
  (when imenus-isearch-string
    (setq isearch-string imenus-isearch-string
          isearch-message imenus-isearch-string)
    (add-hook 'isearch-mode-end-hook 'imenus-isearch-end)))

(defun imenus-isearch-end ()
  "Clean up after terminating imenus isearch."
  (setq imenus-isearch-string nil)
  (remove-hook 'isearch-mode-end-hook 'imenus-isearch-end))

(add-hook 'isearch-mode-hook 'imenus-isearch-setup)

(provide 'imenus)

;;; imenus.el ends here
