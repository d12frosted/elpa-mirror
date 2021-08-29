;;; metal-archives.el --- List future releases using Metal-Archives API  -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C)  8 January 2019
;;

;; Author: Sébastien Le Maguer <lemagues@tcd.ie>
;; Package-Requires: ((emacs "26.3") (alert "1.2") (ht "2.3") (request "0.2.2"))
;; Package-Version: 20210223.1638
;; Package-Commit: a218d63b990365edeef6a2394f72d1f2286aeeae
;; Keywords: lisp, calendar
;; Version: 0.1
;; Homepage: https://github.com/seblemaguer/metal-archives.el

;; metal-archives is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; metal-archives is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with metal-archives.  If not, see http://www.gnu.org/licenses.

;;; Commentary:
;;
;; Package which list future releases using the Metal-Archive (metal-archives.com) API.
;;


;;; Code:

(require 'request)
(require 'json)
(require 'ht)
(require 'alert)



(cl-defstruct metal-archives-entry artist album type genre date)

(defcustom metal-archives-max-vue 10
  "The maximum number of retrieved entries."
  :type 'int
  :group 'metal-archives)

(defconst metal-archives-input-date-regexp "\\([a-zA-Z]*\\) \\([0-9]\\{1,2\\}\\)[a-z]\\{2\\}, \\([0-9]\\{4\\}\\)"
  "Regexp to parse the date coming from metal-archives.com.")

(defconst metal-archives-output-date-format "\\1 \\2, \\3"
  "Substitution regexp generated based on the groups captured by the input regexp.")

(defvar metal-archives-favorite-handle 'metal-archives-favorite-alert
  "The handle of a release of an artist which is wanted.")

(defvar metal-archives-favorite-artists (ht-create)
  "Hash-table of favorite artist.  The key correspond to the artist name, the value to the priority value.")

(defvar metal-archives-entry-database '()
  "The release entry database set.")




(defcustom metal-archives-artist-map-filename (format "%s/artist-map.cache" user-emacs-directory) ;
  "The cache containing the hashtable which key are the favorite artists and the corresponding value is the priority."
  :type 'file
  :group 'metal-archives)

(defun metal-archives-load-artists-map ()
  "Loading the artist priority map stored in FiLENAME."
  (interactive)
  (setq metal-archives-favorite-artists (ht-create))

  (with-current-buffer (find-file metal-archives-artist-map-filename)
    (goto-char (point-min))
    (while (not (eobp))
      (let ((elts)
            (line (buffer-substring-no-properties
                   (line-beginning-position) (line-end-position))))
        (setq elts (split-string line "\t"))
        (ht-set metal-archives-favorite-artists (nth 0 elts) (intern (nth 1 elts))))
      (forward-line 1))

    ;; Close the buffer
    (kill-this-buffer)))



(defun metal-archives~add-entry-to-db (vector-entry)
  "Parse an VECTOR-ENTRY coming from the metal-archives.com website.
A metal-archives-entry is then created and added to `metal-archives-entry-database'."
  (let* ((artist (decode-coding-string (replace-regexp-in-string "<a[^>]*>\\([^<]*\\)<.*" "\\1" (aref vector-entry 0)) 'utf-8)) ;; NOTE: MA gives a string encoded in Latin-1
         (album (decode-coding-string (replace-regexp-in-string "<a[^>]*>\\([^<]*\\)<.*" "\\1" (aref vector-entry 1)) 'utf-8))
         (type (decode-coding-string (replace-regexp-in-string "[ -]" "_" (aref vector-entry 2)) 'utf-8))
         (genre (decode-coding-string (aref vector-entry 3) 'utf-8))
         (date (replace-regexp-in-string metal-archives-input-date-regexp
                                         metal-archives-output-date-format
                                         (aref vector-entry 4)))
         (entry (make-metal-archives-entry :artist artist :album album :type type :genre genre :date date)))
    (when (member artist (ht-keys metal-archives-favorite-artists))
      (funcall metal-archives-favorite-handle entry))

    (unless (member entry metal-archives-entry-database)
      (push entry metal-archives-entry-database))))


(defun metal-archives-favorite-alert (entry)
  "Alert handle to signal a new release ENTRY."
  (alert (format "%s from %s will be released on %s"
                 (metal-archives-entry-album entry)
                 (metal-archives-entry-artist entry)
                 (metal-archives-entry-date entry))
         :category 'release
         :severity (ht-get metal-archives-favorite-artists (metal-archives-entry-artist entry))))



(defun metal-archives-retrieve-next-releases ()
  "Retrieve the next releases for metal from metal-archives.com."
  (interactive)
  (let*
      ((thisrequest (request "https://www.metal-archives.com/release/ajax-upcoming/json/1"
                      :params '(("sEcho" . 1))
                      :parser 'json-read
                      :sync t
                      :error
                      (cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
                                     (error "Got error: %S" error-thrown)))))

       (data (request-response-data thisrequest))
       (nb-elements (assoc-default 'iTotalRecords data))
       (entries (assoc-default 'aaData data))
       (i (length entries)))

    ;; Initialisation (by adding current entries as we are forced to get them)
    (setq metal-archives-entry-database '())
    (mapc 'metal-archives~add-entry-to-db entries)

    ;; Add the following up entries to the data base
    (while (< i nb-elements)
      (progn
        (setq thisrequest  (request "https://www.metal-archives.com/release/ajax-upcoming/json/1"
                             :params `(("sEcho" . 1) ("iDisplayStart" . ,i)) ;; FIXME: actually not used ! ("iDisplayLength" . metal-archives-max-vue))
                             :parser 'json-read
                             :sync t

                             :error
                             (cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
                                            (error "Got error: %S" error-thrown))))
              data (request-response-data thisrequest)
              entries (assoc-default 'aaData data)
              i (+ i (length entries)))
        (mapc 'metal-archives~add-entry-to-db entries)))))



(defun metal-archives~format-entry (entry)
  "Generate an entry for the metal archives release buffer."
  (let* ((tabulated-entry (vector
                           (metal-archives-entry-date entry)
                           (metal-archives-entry-artist entry)
                           (metal-archives-entry-album entry)
                           (metal-archives-entry-genre entry)
                           (metal-archives-entry-type entry))))
    (list "0" tabulated-entry)))


(define-derived-mode metal-archives-list-mode tabulated-list-mode "metal-archives-list-mode"
  "Major mode of the metal archives release buffer."
  (setq tabulated-list-format [("Date" 15 t)
                               ("Artist" 25 nil)
                               ("Album"  40 nil)
                               ("Genre" 25 t)
                               ("Type"  0 nil)]);; last columnt takes what left
  (setq tabulated-list-entries
        (mapcar 'metal-archives~format-entry metal-archives-entry-database))
  (setq tabulated-list-padding 4
        tabulated-list-sort-key (cons "Date" nil))
  (tabulated-list-init-header)
  (tabulated-list-print t))

(defun metal-archives-list-releases ()
  "List the releases in a tabulated buffer named *Metal Releases*."
  (interactive)
  (with-current-buffer (get-buffer-create "*Metal Releases*")
    (metal-archives-list-mode))
  (switch-to-buffer  "*Metal Releases*"))



(provide 'metal-archives)

;;; metal-archives.el ends here
