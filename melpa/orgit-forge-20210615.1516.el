;;; orgit-forge.el --- Org links to Forge issue buffers  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021  The Magit Project Contributors

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Maintainer: Jonas Bernoulli <jonas@bernoul.li>

;; Package-Requires: ((emacs "25.1") (forge "0.2") (magit "3.0") (org "9.4") (orgit "1.7"))
;; Package-Version: 20210615.1516
;; Package-Commit: 365b75609a9454dccf5681eb6075ca53bd32af85
;; Homepage: https://github.com/magit/orgit-forge
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This library is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This library is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this library.  If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; This package defines the Org link typ `orgit-topic', which can be
;; used to link to Forge topic buffers.

;;; Code:

(require 'forge)
(require 'orgit)

(defcustom orgit-topic-description-format "%P%N %T"
  "Format used for `orgit-topic' links.
%o Owner of repository.
%n Name of repository.
%P Type prefix of topic.
%N Number of topic.
%T Title of topic."
  :package-version '(orgit-forge . "0.1.0")
  :group 'orgit
  :type 'string)

;;;###autoload
(with-eval-after-load "org"
  (orgit-link-set-parameters "orgit-topic"
                             :store    'orgit-topic-store
                             :follow   'orgit-topic-open
                             :export   'orgit-topic-export
                             :complete 'orgit-topic-complete-link))

;;;###autoload
(defun orgit-topic-store ()
  "Store a link to a Forge-Topic mode buffer.

When the region selects a topic, then store a link to the
Forge-Topic mode buffer for that topic."
  (cond ((eq major-mode 'forge-topic-mode)
         (orgit-topic-store-1 forge-buffer-topic))
        ((derived-mode-p 'magit-mode)
         (when-let ((sections (or (magit-region-sections 'issue)
                                  (magit-region-sections 'pullreq))))
           (dolist (section sections)
             (orgit-topic-store-1 (oref section value)))
           t))
        ((derived-mode-p 'forge-topic-list-mode)
         (orgit-topic-store-1 (forge-get-topic (tabulated-list-get-id))))))

(defun orgit-topic-store-1 (topic)
  (org-link-store-props
   :type "orgit-topic"
   :link (format "orgit-topic:%s" (oref topic id))
   :description (let ((repo (forge-get-repository t)))
                  (format-spec orgit-topic-description-format
                               `((?o . ,(oref repo owner))
                                 (?n . ,(oref repo name))
                                 (?P . ,(forge--topic-type-prefix topic))
                                 (?N . ,(oref topic number))
                                 (?T . ,(oref topic title)))))))

;;;###autoload
(defun orgit-topic-open (id)
  (forge-visit (forge-get-topic id)))

;;;###autoload
(defun orgit-topic-export (id desc format)
  (orgit--format-export (forge-get-url (forge-get-topic id))
                        desc
                        format))

;;;###autoload
(defun orgit-topic-complete-link (&optional arg)
  (format "orgit-topic:%s"
          (let ((default-directory (magit-read-repository arg)))
            (oref (forge-get-topic (forge-read-topic "Topic")) id))))

;;; _
(provide 'orgit-forge)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; orgit-forge.el ends here
