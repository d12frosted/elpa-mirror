;;; mpdel-embark.el ---  Integrate MPDel with Embark   -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2023  Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>
;; Keywords: multimedia
;; Package-Version: 20230103.2021
;; Package-Commit: 31d91a62b680fb4472ec34c04ac6af80bb3cf4b8
;; Url: https://github.com/mpdel/mpdel-embark
;; Package-requires: ((emacs "26.1") (mpdel "2.0.0") (libmpdel "2.0.0") (embark "0.19"))
;; Version: 0.4.0

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

;; TODO

;;; Code:
(require 'libmpdel)
(require 'mpdel-core)
(require 'mpdel-song)
(require 'embark)


(defvar mpdel-embark--commands
  '(mpdel-core-add-to-current-playlist
    mpdel-core-add-to-stored-playlist
    mpdel-core-dired
    mpdel-core-insert-current-playlist
    mpdel-core-replace-current-playlist
    mpdel-core-replace-stored-playlist)
  "List of commands in variable `mpdel-core-map' to make available in embark.

All commands in the list must use `mpdel-core-selected-entities'
to get the currently-selected entities.")


;;;###autoload
(defun mpdel-embark-setup ()
  "Configure embark to be used with MPDel."
  (interactive)

  (define-key mpdel-core-map (kbd "i") #'mpdel-embark-list)

  (dolist (command mpdel-embark--commands)
    (setf (alist-get command embark-around-action-hooks)
          (list #'mpdel-embark--fake-selected-entities)))

  (dolist (category '(libmpdel-artist libmpdel-album libmpdel-song))
    (setf (alist-get category embark-transformer-alist) #'mpdel-embark--get-target-from-string)
    (setf (alist-get category embark-keymap-alist) 'mpdel-embark-map)))

;;;###autoload
(defun mpdel-embark-list (&optional entity)
  "Select a child of ENTITY.
If ENTITY is nil, select from all artists."
  (interactive)
  (let ((entity (or entity 'artists)))
    (libmpdel-completing-read-entity
     #'mpdel-embark--main-action
     (format "Entity: ")
     entity
     :category (mpdel-embark--child-category entity))))

(cl-defgeneric mpdel-embark--main-action (entity)
  "Execute the default action when ENTITY is selected.
Open minibuffer completion on the children of ENTITY by default."
  (mpdel-embark-list entity))

(cl-defmethod mpdel-embark--main-action ((song libmpdel-song))
  "Display information about SONG."
  (mpdel-song-open song))

(cl-defgeneric mpdel-embark--child-category (entity)
  "Return the category, a symbol, for children of ENTITY.
The category tells the minibuffer completion engine what is the
type of the listed candidates, e.g., `libmpdel-song'.")

(cl-defmethod mpdel-embark--child-category ((_entity (eql artists)))
  "Return the category for children of 'artists."
  'libmpdel-artist)

(cl-defmethod mpdel-embark--child-category ((_artist libmpdel-artist))
  "Return the category for children of ARTIST."
  'libmpdel-album)

(cl-defmethod mpdel-embark--child-category ((_album libmpdel-album))
  "Return the category for children of ALBUM."
  'libmpdel-song)

(cl-defun mpdel-embark--fake-selected-entities (&rest rest &key run target type &allow-other-keys)
  "Execute RUN with selected MPDel entities set to TARGET.
The REST of the arguments and TYPE are passed to RUN.
Used as value for `embark-around-action-hooks'.

TARGET is a MPDel entity.  RUN is a function ultimately executing
one of the MPDel commands in `mpdel-embark--commands'."
  (cl-letf (((symbol-function 'mpdel-core-selected-entities)
             (lambda () (list target))))
    (apply run :target target :type type rest)))

(defun mpdel-embark--get-target-from-string (type target)
  "Return (TYPE . ENTITY) where ENTITY is derived from TARGET.
Used as value for `embark-transformer-alist'.

TYPE is a completion category such as \"libmpdel-album\".  TARGET
is either a string completion candidate with a
\\='libmpdel-entity text property or a MPDel entity."
  (cons type (if (stringp target)
                 (get-text-property 0 'libmpdel-entity target)
               target)))

(defvar mpdel-embark-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map embark-general-map)
    (map-keymap
     (lambda (key command)
       (when (cl-member command mpdel-embark--commands)
         (define-key map (vector key) command)))
     mpdel-core-map)
    map)
  "Embark keymap for MPDel.

The keymap includes all commands of `mpdel-embark--commands' with
the same bindings as in variable `mpdel-core-map'.")

(provide 'mpdel-embark)
;;; mpdel-embark.el ends here

;; LocalWords:  minibuffer MPDel keymap
