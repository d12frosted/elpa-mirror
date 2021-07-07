;;; notmuch-bookmarks.el --- Add bookmark handling for notmuch buffers  -*- lexical-binding: t; -*-

;; Copyright (C) 2019

;; Author:  Jörg Volbers <joerg@joergvolbers.de>
;; version: 0.1
;; Package-Version: 20200322.1925
;; Package-Commit: ec8edfdbd1ac475530591d73a570ded5c18ed86a
;; Keywords: mail
;; Package-Requires: ((seq "2.20") (emacs "26.1") (notmuch "0.29.3"))
;; URL: https://github.com/publicimageltd/notmuch-bookmarks

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

;; This package adds a global minor mode which allows you to bookmark
;; notmuch buffers via the standard Emacs bookmark functionality. A
;; `notmuch buffer' denotes either a notmuch tree view, a notmuch
;; search view or a notmuch show buffer (message view). With this
;; minor mode active, you can add these buffers to the standard
;; bookmark list and visit them, e.g. by using `bookmark-jump'.
;;
;; To activate the minor mode, add something like the following to
;; your init file:
;;
;; (use-package notmuch-bookmarks
;;   :after notmuch
;;   :config
;;   (notmuch-bookmarks-mode))
;;
;; This package is NOT part of the official notmuch Emacs suite.
;;

;;; Code:

(require 'notmuch)
(require 'subr-x)
(require 'cl-lib)
(require 'seq)
(require 'uniquify)
(require 'bookmark)

;;; Custom Variables:

(defcustom notmuch-bookmarks-prefix "notmuch: "
  "Prefix to add to new notmuch bookmarks, or nil."
  :type 'string
  :group 'notmuch-bookmarks)

(defvar notmuch-bookmarks-bmenu-original-keymap nil
  "Storage for original keymap of `bookmarks-bmenu'.")

(defcustom notmuch-bookmarks-bmenu-filter-key "N"
  "Define this key in the bookmarks menu to filter out notmuch bookmarks.
If this value is nil, do not implement any key."
  :type 'string
  :group 'notmuch-bookmarks)

;; Integrating in bookmarks package:

(defun notmuch-bookmarks-sync-updates ()
  "Save bookmarks and sync with `bookmark-bmenu'."
  (setq bookmark-alist-modification-count
	(1+ bookmark-alist-modification-count))
  (if (bookmark-time-to-save-p)
      (bookmark-save))
  (bookmark-bmenu-surreptitiously-rebuild-list))

(defun notmuch-bookmarks-bmenu ()
  "Display bookmark menu only with notmuch bookmarks."
  (interactive)
  (let* ((bookmark-alist (seq-filter #'notmuch-bookmarks-record-p bookmark-alist)))
    (if (called-interactively-p 'interactive)
	(call-interactively #'bookmark-bmenu-list)
      (bookmark-bmenu-list))))

;;; Jumping to a Bookmark:

(defun notmuch-bookmarks-assert-major-mode (a-major-mode)
  "Throw an error if A-MAJOR-MODE is not supported by the package `notmuch-bookmarks'."
  (unless (seq-contains '(notmuch-show-mode notmuch-tree-mode notmuch-search-mode) a-major-mode)
    (user-error "Notmuch bookmarks does not support major mode: '%s' " a-major-mode)))

(defun notmuch-bookmarks-visit (query the-major-mode)
  "Visit a notmuch buffer of type THE-MAJOR-MODE and open QUERY."
  (cl-case the-major-mode
    (notmuch-tree-mode   (notmuch-tree query))
    (notmuch-show-mode   (notmuch-show query))
    (notmuch-search-mode (notmuch-search query))))

(cl-defun notmuch-bookmarks-jump-handler (bookmark)
  "Standard handler for opening notmuch bookmarks."
  (let* ((.filename    (bookmark-prop-get bookmark 'filename))
	 (.major-mode  (bookmark-prop-get bookmark 'major-mode))
	 (.buffer-name (bookmark-prop-get bookmark 'buffer-name)))
    ;; do some sanity checks:
    (notmuch-bookmarks-assert-major-mode .major-mode)
    (cl-assert (not (null .filename)) nil "Empty query string in bookmark record")
    (cl-assert (stringp .filename)    nil "Bad definition of bookmark query")
    ;; either open existing buffer or create fresh one:
    (if (not (get-buffer .buffer-name))
	(notmuch-bookmarks-visit .filename .major-mode)
      (switch-to-buffer .buffer-name)
      (message "This buffer might not be up to date; you may want to refresh it"))))

;;; Providing unified access across all notmuch modes:

(cl-defgeneric notmuch-bookmarks-get-buffer-query (&optional buffer)
  "Return the notmuch query of BUFFER."
  (user-error "Not defined for this type of buffer: %s" buffer))

(cl-defmethod notmuch-bookmarks-get-buffer-query (&context (major-mode notmuch-tree-mode) &optional buffer)
  "Return the query for notmuch tree mode BUFFER."
  (with-current-buffer (or buffer (current-buffer))
    (notmuch-tree-get-query)))

(cl-defmethod notmuch-bookmarks-get-buffer-query (&context (major-mode notmuch-search-mode) &optional buffer)
  "Return the query for notmuch search mode BUFFER."
  (with-current-buffer (or buffer (current-buffer))
    (notmuch-search-get-query)))

(cl-defmethod notmuch-bookmarks-get-buffer-query (&context (major-mode notmuch-show-mode) &optional buffer)
  "Return the query for notmuch search mode BUFFER."
  (with-current-buffer (or buffer (current-buffer))
    (notmuch-show-get-query)))

;;; Creating a Bookmark:

(cl-defun notmuch-bookmarks-make-record (&key (handler 'notmuch-bookmarks-jump-handler)
					      (a-major-mode major-mode)
					      (name    nil)
					      a-buffer-name
					      filename position annotation)
  "Turn argument list into a bookmark record list."
  `(,(or name (concat notmuch-bookmarks-prefix filename))
    (handler  . ,handler)
    (filename . ,filename)
    (major-mode . ,a-major-mode)
    (buffer-name . ,(or (with-current-buffer a-buffer-name
			  (uniquify-buffer-base-name))
			a-buffer-name))
    (annotation . ,annotation)
    (position . ,position)))

(defun notmuch-bookmarks-record ()
  "Return a bookmark record for the current notmuch buffer."
  (if-let* ((query (notmuch-bookmarks-get-buffer-query)))
      (notmuch-bookmarks-make-record :filename query
				     :a-buffer-name (buffer-name)
				     :a-major-mode major-mode)
    ;; actually, this part of the conditional should never be reached,
    ;; since `notmuch-bookmarks-get-buffer-query' already throws an
    ;; error if called within an unrecognized buffer:
    (user-error "Could not find a query associated with the current buffer, no bookmark made")))

;; Diverse useful stuff for working with bookmarks:

(defun notmuch-bookmarks-copy-bookmark (bookmark)
  "Copies BOOKMARK and discards any additional data, e.g. alerts."
  (cl-assert (notmuch-bookmarks-record-p bookmark))
  (notmuch-bookmarks-make-record
   :name         (bookmark-name-from-full-record bookmark)
   :handler      (bookmark-prop-get bookmark 'handler)
   :filename     (bookmark-prop-get bookmark 'filename)
   :a-major-mode (bookmark-prop-get bookmark 'major-mode)
   :position     (bookmark-prop-get bookmark 'position)
   :annotation   (bookmark-prop-get bookmark 'annotation)
   :a-buffer-name   (bookmark-prop-get bookmark 'buffer-name)))

(defun notmuch-bookmarks-record-p (bookmark)
  "Test whether BOOKMARK points to a notmuch query buffer."
  (eq 'notmuch-bookmarks-jump-handler (bookmark-prop-get bookmark 'handler)))


(defun notmuch-bookmarks-query (bookmark)
  "Return the BOOKMARK's query, iff it is a notmuch bookmark."
  (when (notmuch-bookmarks-record-p bookmark)
    (bookmark-prop-get bookmark 'filename)))

(defun notmuch-bookmarks-get-buffer-bookmark (&optional buffer)
  "Return the bookmark pointing to BUFFER, if any."
  (let* ((buffer-name
	  (with-current-buffer (or buffer (current-buffer))
	    (buffer-name))))
    (seq-find (lambda (bm)
		(string-equal (bookmark-prop-get bm 'buffer-name)
			      buffer-name))
	      (seq-filter #'notmuch-bookmarks-record-p
			  bookmark-alist))))

;;;###autoload
(defun notmuch-bookmarks-edit-name (&optional bookmark)
  "Edit the name of notmuch bookmark BOOKMARK.
If BOOKMARK is nil, use current buffer's bookmark."
  (interactive (list (notmuch-bookmarks-get-buffer-bookmark)))
  (if (not bookmark)
      (user-error "No bookmark defined")
    (let* ((old-name (bookmark-name-from-full-record bookmark))
	   (new-name (read-from-minibuffer (format "Replace name '%s' with new name: " old-name))))
      (unless (string-empty-p (string-trim new-name))
	(bookmark-set-name bookmark new-name)
	(notmuch-bookmarks-sync-updates)
	(message "Bookmark name has been changed.")))))

;;;###autoload
(defun notmuch-bookmarks-edit-query (&optional bookmark called-interactively)
  "Edit the query of notmuch bookmark BOOKMARK.
If BOOKMARK is nil, use current buffer's bookmark.
If CALLED-INTERACTIVELY, visit the new bookmark after editing."
  (interactive (list (notmuch-bookmarks-get-buffer-bookmark) t))
  (if (not bookmark)
      (user-error "No bookmark defined")
    (if (not (notmuch-bookmarks-record-p bookmark))
	(user-error "Bookmark not a notmuch bookmark")
      (let* ((calling-buf (current-buffer))
	     (old_query   (notmuch-bookmarks-query bookmark))
	     (new-query   (notmuch-read-query (format "Replace current query '%s' with: " old_query))))
	(bookmark-prop-set bookmark 'filename new-query)
	(when called-interactively
	  (kill-buffer calling-buf))
	(notmuch-bookmarks-visit new-query (bookmark-prop-get bookmark 'major-mode))
	(bookmark-prop-set bookmark 'buffer-name (buffer-name))
	(notmuch-bookmarks-sync-updates)
	(message "Bookmark has been changed")))))

;;;###autoload
(defun notmuch-bookmarks-set-search-type (&optional bookmark called-interactively)
  "Set the search type (tree or search) of notmuch bookmark BOOKMARK.
If BOOKMARK is nil, use current buffer's bookmark.
If CALLED-INTERACTIVELY, visit the new bookmark after editing."
  (interactive (list (notmuch-bookmarks-get-buffer-bookmark) t))
  (if (not bookmark)
      (user-error "No bookmark defined")
    (if (not (notmuch-bookmarks-record-p bookmark))
	(user-error "Bookmark not a notmuch bookmark")
      (let* ((calling-buf    (current-buffer))
	     (old-type       (bookmark-prop-get bookmark 'major-mode)))
	(if (eq old-type 'notmuch-show-mode)
	    ;; FIXME is this really the case?
	    (user-error "Notmuch show is special and cannot be changed to another search type")
	  (let* ((types          '(("search" notmuch-search-mode) ("tree" notmuch-tree-mode)))
		 (types-by-mode  (seq-map #'seq-reverse types))
		 (new-type       (completing-read (format " Change search type from '%s' to " (assoc-default old-type types-by-mode))
						  types nil t)))
	    (bookmark-prop-set bookmark 'major-mode (car (assoc-default new-type types #'string=)))
	    (when called-interactively
	      (kill-buffer calling-buf))
	    (notmuch-bookmarks-visit (bookmark-prop-get bookmark 'filename) (bookmark-prop-get bookmark 'major-mode))
	    (bookmark-prop-set bookmark 'buffer-name (buffer-name))
	    (notmuch-bookmarks-sync-updates)
	    (message "Bookmark has been changed")))))))

;; Let bookmark-relocate handle notmuch bookmarks:

(defun notmuch-bookmarks-relocate-wrapper (orig-fun bookmark-name)
  "Treat notmuch bookmarks differently when 'relocating' bookmarks.
ORIG-FUN should point to the original function `bookmark-relocate'; 
BOOKMARK-NAME is the name of the bookmark to relocate."
  (if (notmuch-bookmarks-record-p bookmark-name)
      (notmuch-bookmarks-edit-query bookmark-name
				    (called-interactively-p 'interactive))
    (funcall orig-fun bookmark-name)))

;; Install or uninstall the bookmark functionality:

(defun notmuch-bookmarks-set-record-fn ()
  "Set up notmuch bookmark handling for the current buffer.
Function to be added to a major mode hook."
  (notmuch-bookmarks-assert-major-mode major-mode)
  (setq-local bookmark-make-record-function 'notmuch-bookmarks-record))

(defun notmuch-bookmarks-install (&optional uninstall)
  "Install bookmarking for notmuch buffers.
If UNINSTALL is set, uninstall it instead."
  ;; install/uninstall hooks:
  (let* ((hook-fn (if uninstall 'remove-hook 'add-hook)))
    (seq-doseq (hook-name '(notmuch-show-mode-hook
			    notmuch-search-mode-hook
			    notmuch-tree-mode-hook))
      (funcall hook-fn hook-name 'notmuch-bookmarks-set-record-fn)))
  ;; install/uninstall advices:
  (if uninstall
      (advice-remove 'bookmark-relocate
		     #'notmuch-bookmarks-relocate-wrapper)
    (advice-add 'bookmark-relocate
		:around #'notmuch-bookmarks-relocate-wrapper))
  ;; edit bmenu keymap:
  (when notmuch-bookmarks-bmenu-filter-key
    (if uninstall
	(when notmuch-bookmarks-bmenu-original-keymap
	  (setq bookmark-bmenu-mode-map notmuch-bookmarks-bmenu-original-keymap))
      (setq notmuch-bookmarks-bmenu-original-keymap (copy-keymap bookmark-bmenu-mode-map))
      (define-key bookmark-bmenu-mode-map notmuch-bookmarks-bmenu-filter-key 'notmuch-bookmarks-bmenu))))

;;;###autoload
(define-minor-mode notmuch-bookmarks-mode
  "Add notmuch specific bookmarks to the bookmarking system."
  :global t
  (notmuch-bookmarks-install (not notmuch-bookmarks-mode)))

(provide 'notmuch-bookmarks)
;;; notmuch-bookmarks.el ends here
