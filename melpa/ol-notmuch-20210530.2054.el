;;; ol-notmuch.el --- Links to notmuch messages   -*- lexical-binding: t; -*-

;; Copyright (C) 2010-2011  Matthieu Lemerre
;; Copyright (C) 2010-2021  The Org Contributors

;; Author: Matthieu Lemerre <racin@free.fr>
;; Maintainer: Jonas Bernoulli <jonas@bernoul.li>
;; Keywords: hypermedia, mail
;; Package-Version: 20210530.2054
;; Package-Commit: 126fb446d8fa9e54cf21103afaf506fd81273c02
;; Homepage: https://git.sr.ht/~tarsius/ol-notmuch

;; Package-Requires: ((emacs "25.1") (notmuch "0.32") (org "9.4.5"))

;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs or Org mode.

;;; Commentary:

;; This file implements links to notmuch messages and "searches".  A
;; search is a query to be performed by notmuch; it is the equivalent
;; to folders in other mail clients.  Similarly, mails are referred to
;; by a query, so both a link can refer to several mails.

;; Links have one the following form
;; notmuch:<search terms>
;; notmuch-search:<search terms>.

;; The first form open the queries in notmuch-show mode, whereas the
;; second link open it in notmuch-search mode.  Note that queries are
;; performed at the time the link is opened, and the result may be
;; different from when the link was stored.

;;; Code:

(require 'notmuch)
(require 'ol)

;;; Message links

(defcustom org-notmuch-open-function 'org-notmuch-follow-link
  "Function used to follow notmuch links.
Should accept a notmuch search string as the sole argument."
  :group 'org-notmuch
  :type 'function)

;;;###autoload
(with-eval-after-load 'org
  (org-link-set-parameters "notmuch"
                           :store  #'org-notmuch-store-link
                           :follow #'org-notmuch-open))

;;;###autoload
(defun org-notmuch-store-link ()
  "Store a link to one or more notmuch messages."
  (when (memq major-mode '(notmuch-show-mode notmuch-tree-mode))
    ;; The value is passed around using variable `org-store-link-plist'.
    (org-link-store-props
     :type       "notmuch"
     :message-id (notmuch-show-get-message-id t)
     :subject    (notmuch-show-get-subject)
     :from       (notmuch-show-get-from)
     :to         (notmuch-show-get-to)
     :date       (org-trim (notmuch-show-get-date)))
    (org-link-add-props :link (org-link-email-description "notmuch:id:%m"))
    (org-link-add-props :description (org-link-email-description))
    org-store-link-plist))

;;;###autoload
(defun org-notmuch-open (path _)
  "Follow a notmuch message link specified by PATH."
  (funcall org-notmuch-open-function path))

(defun org-notmuch-follow-link (search)
  "Follow a notmuch link to SEARCH.
Can link to more than one message, if so all matching messages are shown."
  (notmuch-show search))

;;; Search links

;;;###autoload
(with-eval-after-load 'org
  (org-link-set-parameters "notmuch-search"
                           :store  #'org-notmuch-search-store-link
                           :follow #'org-notmuch-search-open))

;;;###autoload
(defun org-notmuch-search-store-link ()
  "Store a link to a notmuch search."
  (when (eq major-mode 'notmuch-search-mode)
    (org-link-store-props
     :type        "notmuch-search"
     :link        (concat "notmuch-search:"  notmuch-search-query-string)
     :description (concat "Notmuch search: " notmuch-search-query-string))))

;;;###autoload
(defun org-notmuch-search-open (path _)
  "Follow a notmuch search link specified by PATH."
  (notmuch-search path))

;;; Tree links

;;;###autoload
(with-eval-after-load 'org
  (org-link-set-parameters "notmuch-tree"
                           :store  #'org-notmuch-tree-store-link
                           :follow #'org-notmuch-tree-open))

;;;###autoload
(defun org-notmuch-tree-store-link ()
  "Store a link to a notmuch tree."
  (when (eq major-mode 'notmuch-tree-mode)
    (org-link-store-props
     :type        "notmuch-tree"
     :link        (concat "notmuch-tree:"  (notmuch-tree-get-query))
     :description (concat "Notmuch tree: " (notmuch-tree-get-query)))))

;;;###autoload
(defun org-notmuch-tree-open (path _)
  "Follow a notmuch tree link specified by PATH."
  (notmuch-tree path))

;;; _
(provide 'ol-notmuch)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; ol-notmuch.el ends here
