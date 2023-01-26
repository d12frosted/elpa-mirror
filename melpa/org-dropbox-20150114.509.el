;;; org-dropbox.el --- move Dropbox notes from phone into org-mode datetree

;;; Copyright (C) 2014 Heikki Lehvaslaiho

;; URL: https://github.com/heikkil/org-dropbox
;; Author: Heikki Lehvaslaiho <heikki.lehvaslaiho@gmail.com>
;; Version: 20141219
;; Package-Requires: ((dash "2.2") (names "20150000") (emacs "24"))
;; Keywords: Dropbox Android notes org-mode

;;; Commentary:
;;
;; This minor mode syncs DropBox notes from mobile devices into org
;; datetree file that can be part of org agenda. The minor mode starts
;; a daemon that periodically scans the note directory.
;;
;; ** Justification
;;
;; I wanted to collect together all interesting articles I saw reading
;; news on my phone applications. I was already using Org mode to keep
;; notes in my computer.
;;
;; The [[http://orgmode.org/manual/MobileOrg.html][MobileOrg]] app in
;; my Android phone is fiddly and does not do things the way I want,
;; so this was a good opportunity to learn lisp while doing something
;; useful.
;;
;; ** Sharing notes
;;
;; On Android phones, installing Dropbox client also adds Dropbox as
;; one of the applications that can be used to share articles from
;; many news applications (e.g. BBC World News, Flipboard). In
;; contrast to many other options, Dropbox saves these links as plain
;; text files -- a good starting point for including them into
;; org-mode.
;;
;; Org mode has a date-ordered hierachical file structure called
;; datetree that is ideal for storing notes and links. This
;; org-dropbox-mode code reads each note in the Dropbox notes folder,
;; formats them to an org element, and refiles them to a correct place
;; in a datetree file for easy searching through org-agenda commands.
;;
;; Each new org headline element gets an inactive timestamp that
;; corresponds to the last modification time of the note file.
;;
;; The locations in the filesystem are determined by two customizable
;; variables -- by default both pointing inside Dropbox:
;;
;; #+BEGIN_EXAMPLE
;;   org-dropbox-note-dir      "~/Dropbox/notes/"
;;   org-dropbox-datetree-file "~/Dropbox/org/reference.org"
;; #+END_EXAMPLE
;;
;; Since different programmes format the shared link differently, the
;; code tries its best to make sense of them. A typical note has the
;; name of the article in the first line and the link following it
;; separated by one or two newlines. The name is put to the header,
;; multiple new lines are reduced to one, and the link is followed by
;; the timestamp. If the title uses dashes (' - '), exclamation marks
;; ('! '), or colons (': '), they are replaced by new lines to wrap
;; the trailing text into the body. In cases where there is no text
;; before the link, the basename of the note file is used as the
;; header.
;;
;; After parsing, the source file is removed from the note directory.
;;
;; Note that most of the time the filename is ignored. The only
;; absolute requirement for the filename is that it has to be unique
;; within the directory. Filename is used as an entry header only if
;; the file does not contain anything usefull, i.e. the content is
;; plain URL.
;;
;; ** Usage
;;
;; Set up variables =org-dropbox-note-dir= and
;; =org-dropbox-datetree-file= to your liking. Authorize your devices
;; to share that Dropbox directory. As long as you save your notes in
;; the correct Dropbox folder, they are copied to your computer for
;; processing and deletion.
;;
;; The processing of notes starts when you enable the minor mode
;; org-dropbox-mode in Emacs, and stops when you disable it. After
;; every refiler run, a message is printed out giving the number of
;; notes processed.
;;
;; An internal timer controls the periodic running of the notes
;; refiler. The period is set in customizable variable
;; =org-dropbox-refile-timer-interval= to run by default every hour
;; (3600 seconds).
;;
;; ** Disclaimer
;;
;; This is first time I have written any reasonable amount of lisp
;; code, so writing a whole package was a jump in the dark. The code has
;; been running reliably for some time now, but if you want to try the
;; code and be absolutely certain you do not lose your notes, comment
;; form =(delete-file file)= from the code.
;;
;; There are undoubtedly many things that can be done better. Feel
;; free to raise issues and submit pull requests.


;; This file is not a part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'org)

;;;###autoload
(define-namespace org-dropbox-
:package org-dropbox
:group org
:version "1.2"

:autoload
(define-minor-mode mode
  "Minor mode adding Dropbox notes to datetree.

With no argument, this command toggles the mode. Non-null prefix
argument turns on the mode. Null prefix argument turns off the
mode.
"
  :init-value nil                   ; Set to 1 to enable by default
  :lighter " Org-Dbox"              ; The indicator for the mode line
  :global 1                         ; Active in all buffers
  (if mode
      (refile-timer-start)
    (refile-timer-stop)))

(defcustom note-dir "~/Dropbox/notes/"
  "Directory where Dropbox shared notes are added."
  :type 'directory)

(defcustom datetree-file "~/Dropbox/org/reference.org"
  "File containing the datetree file to store formatted notes."
  :type 'file)

(defcustom refile-timer-interval (* 60 60)
  "Repeat refiling every N seconds.  Defaults to 3600 sec = 1 h."
  :type 'int)

(defun datetree-file-entry-under-date (txt date)
  "Insert a node TXT into the date tree under DATE.

After insertion sorts entries under DATE based on the timestamp."
  (org-datetree-find-date-create
   (list (nth 4 date) (nth 3 date) (nth 5 date)))
  (show-subtree)
  (forward-line)
  (beginning-of-line)
  (insert txt)
  ;; move up to the day header
  (outline-up-heading 1)
  ;; sort children by the first timestamp
  (org-sort-entries nil ?t))

(defun get-mtime (buffer-file-name)
  "Get the modification time of a file (BUFFER-FILE-NAME)."
  (let* ((attrs (file-attributes (buffer-file-name)))
         (mtime (nth 5 attrs)))
    (format-time-string "%Y-%m-%d %T" mtime)))

(defun notes-to-datetree (dirname buffername)
  "Process files in a directory DIRNAME and place the entries to BUFFERNAME."
  (let (files file file-content mtime lines header entry date counter)
    (setq counter 0)
    (setq files (directory-files dirname t "\\.txt$"))
    (while files
      (setq file (pop files))
      (setq mtime (get-mtime file))
      ;; file contents into a clean string
      (setq file-content (->> (with-current-buffer
                                  (find-file-noselect file)
                                (buffer-string))
                              (replace-regexp-in-string "\t" "") ; remove tabs
                              (replace-regexp-in-string " ?[-!–:—|] " "\n") ; split some long title lines
                              (replace-regexp-in-string " *http:" "\nhttp:") ; separate link from title
                              (replace-regexp-in-string "\n+" "\n") ; remove successive newlines
                              (replace-regexp-in-string "^\n" "") ; remove new line as first char
                              (replace-regexp-in-string "\n$" "") ; remove new line as last char
                              ))
      ;; list of lines from string
      (setq lines (split-string file-content "\n"))
      ;; create org header text to first element of lines
      (if (equal (length lines) 1)
          ;; filename
          (setq lines (cons (concat "**** "
                                    (file-name-sans-extension (file-name-nondirectory file)))
                            lines))
        ;; first line is the title
        (setcar lines (concat "**** " (car lines))))
      ;; create the org entry string
      (setq entry
            (mapconcat 'identity
                       (append lines
                               (list (concat "Entered on [" mtime "]\n")))
                       "\n"))
      ;; save in the datetree
      (setq date (decode-time (org-read-date nil t mtime nil)))
      (with-current-buffer buffername
        (barf-if-buffer-read-only)
        (datetree-file-entry-under-date entry date))
      (setq counter (1+ counter))
      (delete-file file))
    (with-current-buffer buffername (save-buffer))
    (when (> counter 0)
      (message "org-dropbox: processed %d notes" counter))))

(defun refile-notes ()
  "Create `org-mode' entries from DropBox notes and place them in a datetree."
  (interactive)
  (let (buffername)
    (when (file-exists-p datetree-file)
      (setq buffername (buffer-name (find-file-noselect datetree-file)))
      (notes-to-datetree note-dir buffername))))

(defvar refile-timer)

(defun refile-timer-start ()
  "Start running the refiler while pausing for given interval.

The variable refile-timer-interval determines the repeat interval.
The value is in seconds."
  (setq refile-timer
        (run-with-timer 0
                        refile-timer-interval
                        #'refile-notes)))

(defun refile-timer-stop ()
  "Stop running the refiler."
  (cancel-timer refile-timer))

); closing names

(provide 'org-dropbox)
;;; org-dropbox.el ends here
