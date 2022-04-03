;;; notmuch-transient.el --- Command dispatchers for Notmuch  -*- lexical-binding: t -*-

;; Copyright (C) 2020-2021 Free Software Foundation, Inc.

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://git.sr.ht/~tarsius/notmuch-transient
;; Keywords: mail
;; Package-Version: 20220402.1625
;; Package-Commit: d8994bd33d50cc70e0c0bb04588ab384f5104185

;; Package-Requires: ((emacs "27.1") (notmuch "0.31.4"))

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package command provides dispatcher for existing Notmuch
;; commands, as well as some new commands for dealing with tags.

;; Everything is still incomplete and very much subject to change.

;;; Code:

(require 'let-alist)
(require 'transient)

(require 'notmuch)

;;; Variables

(defvar notmuch-transient-add-bindings t
  "Whether loading `notmuch-transient' adds binding to existing keymaps.")

(defvar notmuch-transient-prefix (kbd "C-d")
  "The prefix key used for various transient commands.")

;;; Hello

;;;###autoload (autoload 'notmuch-hello-mode-transient "notmuch-transient" nil t)
(transient-define-prefix notmuch-hello-mode-transient ()
  "Command dispatcher for \"notmuch hello\" buffers."
  [["Search"
    ("s" "plain"         notmuch-search)
    ("z" "tree"          notmuch-tree)
    ("u" "unthreaded"    notmuch-unthreaded)]
   ["Repeat search"
    ("t" "tag"           notmuch-search-by-tag)
    ("j" "saved"         notmuch-search-transient)]
   ["Actions"
    ("m" "new mail"      notmuch-mua-new-mail)
    ("G" "poll"          notmuch-poll-and-refresh-this-buffer)
    ("g" "refresh"       notmuch-refresh-this-buffer)]])

;;; Tree

;;;###autoload (autoload 'notmuch-tree-mode-transient "notmuch-transient" nil t)
(transient-define-prefix notmuch-tree-mode-transient ()
  "Command dispatcher for \"notmuch tree\" buffers."
  :suffix-description #'transient-command-summary-or-name
  [["Do"
    ("m" "new mail"        notmuch-tree-new-mail)
    ("r" "reply sender"    notmuch-tree-reply-sender)
    ("R" "reply all"       notmuch-tree-reply)
    ("f" "forward"         notmuch-tree-forward-message)
    ("b" "resend"          notmuch-show-resend-message)]
   ["Tag"
    ("t" "toggle"          notmuch-tag-transient)
    ("+" "add tag"         notmuch-tree-add-tag)
    ("-" "remove tag"      notmuch-tree-remove-tag)
    ("*" "tag all"         notmuch-tree-tag-thread)]]
  [["Message"
    ("V" "view raw"        notmuch-tree-view-raw-message)
    ("|" "pipe"            notmuch-show-pipe-message)]
   ["Part"
    ("v" "view all"        notmuch-show-view-all-mime-parts)]
   ["Miscellaneous"
    ("w" "save attachments" notmuch-show-save-attachments)
    ("c" "stash..."        notmuch-show-stash-transient)]]
  [["Search"
    ("s" "plain"           notmuch-tree-to-search)
    ("z" "tree"            notmuch-tree-to-tree)]
   ["Repeat search"
    ("j" "saved"           notmuch-search-transient)]
   ["Display"
    ("S" notmuch-search-from-tree-current-query)
    ("U" notmuch-unthreaded-from-tree-current-query)
    ("Z" notmuch-tree-from-unthreaded-current-query)]])

;;; Search

;;;###autoload (autoload 'notmuch-search-mode-transient "notmuch-transient" nil t)
(transient-define-prefix notmuch-search-mode-transient ()
  "Transient popup for \"notmuch search\" buffers."
  [["Reply"
    ("r" "reply to sender" notmuch-search-reply-to-thread-sender)
    ("R" "reply to all"    notmuch-search-reply-to-thread)]
   ["Stash"
    ("c i" "id"            notmuch-search-stash-thread-id)
    ("c q" "query"         notmuch-stash-query)]]
  [["Display"
    ("Z" "tree"            notmuch-tree-from-search-current-query)
    ("U" "unthreaded"      notmuch-unthreaded-from-search-current-query)]
   ["Refine"
    ("o" "toggle order"    notmuch-search-toggle-order)
    ("t" "filter by tag"   notmuch-search-filter-by-tag)
    ("l" "filter"          notmuch-search-filter)]
   ["Tag"
    ("k" "tag menu"        notmuch-tag-transient)
    ("+" "add tag"         notmuch-search-add-tag)
    ("-" "remove tag"      notmuch-search-remove-tag)
    ("a" "archive"         notmuch-search-archive-thread)
    ("*" "tag all"         notmuch-search-tag-all)]])

;;;###autoload (autoload 'notmuch-search-stash-transient "notmuch-transient" nil t)
(transient-define-prefix notmuch-search-stash-transient ()
  "Command dispatcher for stashing from \"notmuch search\" buffers."
  [["Stash"
    ("i" "tread id" notmuch-search-stash-thread-id)
    ("q" "query"    notmuch-stash-query)]])

;;; Show

;;;###autoload (autoload 'notmuch-show-mode-transient "notmuch-transient" nil t)
(transient-define-prefix notmuch-show-mode-transient ()
  "Command dispatcher for \"notmuch show\" buffers."
  [["Do"
    ("r" "reply to sender" notmuch-show-reply-sender)
    ("R" "reply to all"    notmuch-show-reply)
    ("f" "forward"         notmuch-show-forward-message)
    ("F" "forward open"    notmuch-show-forward-open-messages)
    ("b" "resend"          notmuch-show-resend-message)
    ("e" "resume"          notmuch-show-resume-message)]
   ["Archive"
    ("X" "thread & exit"   notmuch-show-archive-thread-then-exit)
    ("x" "message & exit"  notmuch-show-archive-message-then-next-or-exit)
    ("A" "thread"          notmuch-show-archive-thread-then-next)
    ("a" "message"         notmuch-show-archive-message-then-next-or-next-thread)]
   ["Tag"
    ("k" "tag menu"        notmuch-tag-transient)
    ("+" "add tag"         notmuch-show-add-tag)
    ("-" "remove tag"      notmuch-show-remove-tag)
    ("*" "tag all"         notmuch-show-tag-all)]]
  [["Message"
    ("V" "view raw"         notmuch-show-view-raw-message)
    ("|" "pipe"             notmuch-show-pipe-message)
    ("#" "print"            notmuch-show-print-message)]
   ["Part"
    (". s" "save"               notmuch-show-save-part)
    (". v" "view"               notmuch-show-view-part)
    (". o" "view interactively" notmuch-show-interactively-view-part)
    (". |" "pipe"               notmuch-show-pipe-part)
    (". m" "choose mime"        notmuch-show-choose-mime-of-part)]
   ["Miscellaneous"
    ("w" "save attachments"     notmuch-show-save-attachments)
    ("c" "stash..."             notmuch-show-stash-transient)
    ("B" "browse urls"          notmuch-show-browse-urls)]]
  [["Toggle"
    ("h" "header visibility"  notmuch-show-toggle-visibility-headers :transient t)
    ("!" "elide non-matching" notmuch-show-toggle-elide-non-matching :transient t)
    ("$" "process crypto"     notmuch-show-toggle-process-crypto :transient t)
    ("<" "thread indentation" notmuch-show-toggle-thread-indentation :transient t)
    ("t" "line truncation"    toggle-truncate-lines :transient t)]
   ["Filter"
    ("l" "limit"            notmuch-show-filter-thread)]
   ["Display"
    ("Z" "tree"             notmuch-tree-from-show-current-query)
    ("U" "unthreaded"       notmuch-unthreaded-from-show-current-query)]])

;;;###autoload (autoload 'notmuch-show-stash-transient "notmuch-transient" nil t)
(transient-define-prefix notmuch-show-stash-transient ()
  "Command dispatcher for stashing from \"notmuch show\" buffers."
  ["Stash"
   [("f" "from"           notmuch-show-stash-from)
    ("t" "to"             notmuch-show-stash-to)
    ("c" "cc"             notmuch-show-stash-cc)
    ("s" "subject"        notmuch-show-stash-subject)
    ("d" "date"           notmuch-show-stash-date)]
   [("i" "id"             notmuch-show-stash-message-id)
    ("I" "id (stripped)"  notmuch-show-stash-message-id-stripped)
    ("F" "filename"       notmuch-show-stash-filename)
    ("T" "tags"           notmuch-show-stash-tags)]
   [("l" "link"           notmuch-show-stash-mlarchive-link)
    ("L" "link and go"    notmuch-show-stash-mlarchive-link-and-go)
    ("G" "git send-email" notmuch-show-stash-git-send-email)]])

;;;###autoload (autoload 'notmuch-show-part-transient "notmuch-transient" nil t)
(transient-define-prefix notmuch-show-part-transient ()
  "Command dispatcher for acting on parts from \"notmuch show\" buffers."
  [["Part"
    ("s" "save"               notmuch-show-save-part)
    ("v" "view"               notmuch-show-view-part)
    ("o" "view interactively" notmuch-show-interactively-view-part)
    ("|" "pipe"               notmuch-show-pipe-part)
    ("m" "choose mime"        notmuch-show-choose-mime-of-part)]])

;;; Repeating

;;;###autoload (autoload 'notmuch-search-transient "notmuch-transient" nil t)
(transient-define-prefix notmuch-search-transient ()
  "Repeat a saved search.

Repeat a search, which is saved and associated
with a key in option `notmuch-saved-searches'.

This is a replacement for `notmuch-jump-search'."
  ["Search"
   :class transient-row
   :setup-children notmuch-search-transient--setup
   :pad-keys t]
  (interactive)
  (when (derived-mode-p 'notmuch-tree-mode)
    (notmuch-tree-close-message-window))
  (transient-setup 'notmuch-search-transient))

(defun notmuch-search-transient--setup (_)
  (cl-mapcan (lambda (search)
               (let-alist (transient-plist-to-alist search)
                 (and .key
                      (transient--parse-child
                       'notmuch-search-transient
                       (list (key-description .key)
                             .name
                             (lambda ()
                               (interactive)
                               (notmuch-transient--search
                                .search-type .query .sort-order)))))))
             notmuch-saved-searches))

;;;; Compatibility kludges

(defun notmuch-transient--search (type query order)
  (cl-case type
    (tree       (notmuch-tree query))
    (unthreaded (notmuch-unthreaded query))
    (t          (notmuch-search query
                                (cl-case order
                                  (newest-first nil)
                                  (oldest-first t)
                                  (t notmuch-search-oldest-first))))))

;;; Tagging

;;;###autoload (autoload 'notmuch-tag-transient "notmuch-transient" nil t)
(transient-define-prefix notmuch-tag-transient ()
  "Quickly apply or reverse common tagging operations.

Operations are specified in `notmuch-tagging-keys'.  During
a transitional period you have to additionally add an entry
to `notmuch-transient--tagging-inverse-name'.

This is a replacement for `notmuch-tag-jump'."
  :init-value #'notmuch-tag-transient--init
  [:description notmuch-tag-transient--description
   :setup-children notmuch-tag-transient--setup
   :pad-keys t]
  (interactive)
  (when (derived-mode-p 'notmuch-tree-mode)
    (notmuch-tree-close-message-window))
  (transient-setup 'notmuch-tag-transient))

(defun notmuch-tag-transient--init (obj)
  (oset obj value (notmuch-transient--get-tags)))

(defun notmuch-tag-transient--description ()
  (format "Current tags: %s" (oref transient--prefix value)))

(defun notmuch-tag-transient--setup (_)
  (cl-mapcan (pcase-lambda (`(,key ,tags ,desc))
               (when (symbolp tags)
                 (setq tags (symbol-value tags)))
               (transient--parse-child
                'notmuch-tag-transient
                (list (key-description key)
                      desc
                      (lambda ()
                        (interactive)
                        (notmuch-transient--do-tag
                         (notmuch-transient-tag-infix--get-changes
                          (transient-suffix-object)))
                        (transient-init-value transient-current-prefix))
                      :class 'notmuch-transient-tag-infix
                      :tags tags)))
             notmuch-tagging-keys))

(defclass notmuch-transient-tag-infix (transient-infix)
  ((transient :initform 'transient--do-exit)
   (tags :initarg :tags)))

(cl-defmethod transient-init-value ((obj notmuch-transient-tag-infix))
  (let ((value (oref transient--prefix value)))
    (oset obj value
          (delq nil (mapcar (lambda (change)
                              (car (member (substring change 1) value)))
                            (oref obj tags))))))

(cl-defmethod transient-format-description ((obj notmuch-transient-tag-infix))
  (let ((desc (oref obj description))
        (change (car (oref obj tags))))
    (if (xor (member (substring change 1)
                     (oref transient--prefix value))
             (= (aref change 0) ?+))
        (propertize desc 'face 'bold)
      (cdr (assoc desc (bound-and-true-p
                        notmuch-transient--tagging-inverse-name))))))

(cl-defmethod transient-format-value ((obj notmuch-transient-tag-infix))
  (let ((value (oref transient--prefix value)))
    (mapconcat (lambda (change)
                 (let ((tag (substring change 1))
                       (op  (aref change 0)))
                   (if (xor (member tag value)
                            (= op ?+))
                       (propertize
                        change 'face
                        (list :foreground (if (= op ?+)
                                              "dark green"
                                            "dark red")))
                     change)))
               (notmuch-transient-tag-infix--get-changes obj)
               " ")))

(defun notmuch-transient-tag-infix--get-changes (obj)
  (let* ((value   (oref (or transient--prefix transient-current-prefix) value))
         (changes (oref obj tags))
         (change  (car changes)))
    (if (xor (member (substring change 1) value)
             (= (aref change 0) ?+))
        changes
      (mapcar (lambda (change)
                (let ((op (aref change 0)))
                  (concat (if (= op ?+) "-" "+")
                          (substring change 1))))
              changes))))

;;;; Compatibility kludges

(defvar notmuch-transient--tagging-inverse-name
  '(("Archive"      . "Unarchive")
    ("Mark read"    . "Mark unread")
    ("Flag"         . "Unflag")
    ("Mark as spam" . "Unmark as spam")
    ("Delete"       . "Undelete")))

(defun notmuch-transient--get-tags ()
  (cl-case major-mode
    (notmuch-search-mode (notmuch-search-get-tags))
    (notmuch-show-mode   (notmuch-show-get-tags))
    (notmuch-tree-mode   (notmuch-tree-get-tags))))

(defun notmuch-transient--do-tag (changes)
  (cl-case major-mode
    (notmuch-search-mode (notmuch-search-tag changes))
    (notmuch-show-mode   (notmuch-show-tag   changes))
    (notmuch-tree-mode   (notmuch-tree-tag   changes))))

;;; Inject

(when notmuch-transient-add-bindings

  (define-key notmuch-hello-mode-map  notmuch-transient-prefix #'notmuch-hello-mode-transient)
  (define-key notmuch-tree-mode-map   notmuch-transient-prefix #'notmuch-tree-mode-transient)
  (define-key notmuch-search-mode-map notmuch-transient-prefix #'notmuch-search-mode-transient)
  (define-key notmuch-show-mode-map   notmuch-transient-prefix #'notmuch-show-mode-transient)

  (define-key notmuch-search-mode-map "c" #'notmuch-search-stash-transient)
  (define-key notmuch-show-mode-map   "c" #'notmuch-show-stash-transient)
  (define-key notmuch-tree-mode-map   "c" #'notmuch-show-stash-transient)

  (define-key notmuch-show-mode-map   "." #'notmuch-show-part-transient)

  (define-key notmuch-common-keymap   "j" #'notmuch-search-transient)
  (define-key notmuch-tree-mode-map   "j" #'notmuch-search-transient)

  (define-key notmuch-search-mode-map "k" #'notmuch-tag-transient)
  (define-key notmuch-tree-mode-map   "k" #'notmuch-tag-transient)
  (define-key notmuch-show-mode-map   "k" #'notmuch-tag-transient))

;;; _
(provide 'notmuch-transient)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; notmuch-transient.el ends here
