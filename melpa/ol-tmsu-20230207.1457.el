;;; ol-tmsu.el --- Org-mode links to TMSU queries    -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Wojciech Siewierski

;; Author: Wojciech Siewierski
;; URL: https://github.com/vifon/tmsu.el
;; Package-Version: 20230207.1457
;; Package-Commit: 9672d193a51f2848696445528de757aa21b2b686
;; Keywords: files, outlines, hypermedia
;; Version: 0.9
;; Package-Requires: ((emacs "28.1") (tmsu "0.9"))

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

;; org-mode links to TMSU queries.

;;; Code:

(require 'ol)
(eval-when-compile
  (require 'subr-x))

(require 'tmsu-dired)


(defconst org-tmsu-link-regex
  (rx (group (*? any))
      "::"
      (group (*? any))
      (? "::"
         (group (* any)))
      eol)
  "A regex matching an `org-mode' link this module generates.")

(defun org-tmsu-open-link (link &optional _arg)
  "Implement the :follow handler for org LINKs saved from `tmsu-dired-query'.

See `org-link-parameters' for the details."
  (string-match org-tmsu-link-regex link)
  (let ((dir   (match-string 1 link))
        (query (match-string 2 link))
        (flags (match-string 3 link)))
    (tmsu-dired-query dir (split-string query ",") flags)))

(defun org-tmsu-store-link ()
  "Implement the :store handler for org LINKs saved from `org-store-link'.

See `org-link-parameters' for the details."
  (when (and (eq major-mode 'dired-mode)
             (bound-and-true-p tmsu-dired-query-args))
    (let* ((dir default-directory)
           (query (string-join tmsu-dired-query-args ","))
           (flags tmsu-dired-query-flags)
           (link (if flags
                     (concat "tmsu:" dir "::" query "::" flags)
                   (concat "tmsu:" dir "::" query)))
           (desc (funcall tmsu-dired-pretty-description-function)))
      (org-link-store-props :type "tmsu"
                            :link link
                            :description desc
                            :directory dir
                            :query query))))

(org-link-set-parameters
 "tmsu"
 :follow #'org-tmsu-open-link
 :store #'org-tmsu-store-link)

(provide 'ol-tmsu)
;;; ol-tmsu.el ends here
