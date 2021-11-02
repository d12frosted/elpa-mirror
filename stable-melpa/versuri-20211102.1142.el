;;; versuri.el --- The lyrics package -*- lexical-binding: t -*-

;; Copyright (C) 2019-2020 Mihai Olteanu

;; Author: Mihai Olteanu <mihai_olteanu@fastmail.fm>
;; Version: 1.0
;; Package-Version: 20211102.1142
;; Package-Commit: eafc925e3089aa80cefd6ceeb0cb87abce5490a9
;; Package-Requires: ((emacs "26.1") (dash "2.16.0") (request "0.3.0") (anaphora "1.0.4") (esxml "0.1.0") (s "1.12.0") (esqlite "0.3.1"))
;; Keywords: multimedia
;; URL: https://github.com/mihaiolteanu/versuri/

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

;; A package to fetch lyrics from well-known websites and store them in a local
;; sqlite database.

;; Features:
;; - makeitpersonal, genius, songlyrics, metrolyrics, musixmatch and azlyrics
;; are all supported
;; - add new websites or modify existing ones with `versuri-add-website'
;; - search the database with `completing-read' and either for all the entries in the
;; database, all the entries for a given artist or all the entries where the
;; lyrics field contains a given string.
;; - synchronous bulk request for lyrics for a given list of songs.

;;; Code:

(require 'xdg)
(require 'subr-x)
(require 'cl-lib)
(require 'dash)
(require 'request)
(require 'anaphora)
(require 'esxml-query)
(require 's)
(require 'esqlite)

(defconst versuri--db-file-name "/versuri.db"
  "Name of the db containing all the lyrics.")

(defconst versuri--db-process nil
  "The process containing the opened db stream.")

(defun versuri--db-stream ()
  "Return the db stream or create and open it if doesn't exist."
  (unless versuri--db-process
    (let ((db-path (concat (xdg-config-home)
                           versuri--db-file-name)))
      (esqlite-execute db-path
        (concat "CREATE TABLE IF NOT EXISTS lyrics ("
                "id     INTEGER PRIMARY KEY AUTOINCREMENT "
                "               UNIQUE "
                "               NOT NULL, "
                "artist TEXT    NOT NULL "
                "               COLLATE NOCASE, "
                "song   TEXT    NOT NULL "
                "               COLLATE NOCASE, "
                "lyrics TEXT    COLLATE NOCASE);"))
      (setf versuri--db-process
            (esqlite-stream-open db-path))))
  versuri--db-process)

(defun versuri--db-read (query)
  "Call the QUERY on the database and return the result."
  (esqlite-stream-read (versuri--db-stream) query))

(defun versuri--db-get-lyrics (artist song)
  "Retrieve the stored lyrics for ARTIST and SONG."
  (aif (versuri--db-read
        (format "SELECT lyrics FROM lyrics WHERE artist=\"%s\" AND song=\"%s\""
                artist song))
      (car (car it))))

(defun versuri--db-search-lyrics-like (lyrics)
  "Retrieve all entries that contain lyrics like LYRICS."
  (versuri--db-read
   (format "SELECT * from lyrics WHERE lyrics like '%%%s%%'"
           (s-replace "'" "''" lyrics))))

(defun versuri--db-artists-like (artist)
  "Retrieve all entries that contain artists like ARTIST."
  (versuri--db-read
   (format "SELECT * from lyrics WHERE artist like '%%%s%%'"
           (s-replace "'" "''" artist))))

(defun versuri--db-all-entries ()
  "Select everything from the database."
  (versuri--db-read "SELECT * from lyrics"))

(defun versuri--db-save-lyrics (artist song lyrics)
  "Save the LYRICS for ARTIST and SONG in the database."
  (esqlite-stream-execute (versuri--db-stream)
   (format "INSERT INTO lyrics(artist,song,lyrics) VALUES(\"%s\", \"%s\", \"%s\")"
           (esqlite-escape-string artist ?\")
           (esqlite-escape-string song ?\")
           (esqlite-escape-string (s-trim lyrics) ?\"))))

(defun versuri-delete-lyrics (artist song)
  "Remove entry for ARTIST and SONG form the database."
  (print (format "%s - %s" artist song))
  (esqlite-stream-execute
   (versuri--db-stream)
   (format "DELETE FROM lyrics WHERE artist=\"%s\" and song=\"%s\""
           artist song)))

(defun versuri--do-search (str)
  (let ((entries (cond ((s-blank? (s-trim str))
                        (versuri--db-all-entries))
                       ((s-equals-p " " (substring str 0 1))
                        (versuri--db-artists-like (s-trim str)))
                       (t (versuri--db-search-lyrics-like str)))))
    (cl-multiple-value-bind (artist-max-len song-max-len)
        (cl-loop for entry in entries
                 maximize (length (cadr entry)) into artist
                 maximize (length (caddr entry)) into song
                 finally (return (cl-values artist song)))
      (mapcan
       (lambda (song)
         (mapcar (lambda (verse)
                   (list
                    ;; Build a table of artist/song/verse with padding.
                    (format (s-format  "%-$0s   %-$1s   %s" 'elt
                                       ;; Add the padding
                                       `(,artist-max-len ,song-max-len))
                            ;; Add the actual artist, song and verse.
                            (cadr song) (caddr song) verse)
                    ;; Artist and song, recoverable in :action lambda.
                    (cadr song) (caddr song)))
                 ;; Go through all the verses in the lyrics column for each entry.
                 (if (not (or (seq-empty-p str)
                              (s-equals-p " " (substring str 0 1))))
                     (seq-uniq
                      (mapcan (lambda (line)
                                (s-match (format ".*%s.*" str) line))
                              (s-lines (cadddr song))))
                   ;; First line of the lyrics.
                   (list (car (s-lines (cadddr song)))))))
       ;; All entries in db that contain str in the lyrics column.
       entries))))

(defun versuri-search (str)
  "Search the database for all entries that match STR.
Use `completing-read' to let the user select one of the entries
and return it.  Each entry contains the artist name, song name
and a verse line.

If STR is empty, this is a search through all the entries in the
database.

If STR starts with an empty space, this is a search for all
artists that contain STR in their name.

Otherwise, this is a search for all the lyrics that contain STR.
There can be more entries with the same artist and song name if
the STR matches multiple lines in the lyrics."
  (interactive "MSearch lyrics: ")
  (let* ((res (versuri--do-search str))
         (song (when res
                 (completing-read "Select Lyrics: " res))))
    (when song
      (cdr (assoc song res #'string=)))))

(defalias 'versuri-ivy-search #'versuri-search)

(defconst versuri--websites nil
  "A list of all the websites where lyrics can be searched.")

(cl-defstruct versuri--website
  name template separator query)

(defun versuri-add-website (name template separator query)
  "Define a new website where lyrics can be searched.
If a website with the given NAME already exists, replace it.  If
not, define a new lyrics website structure and add it to the list
of known websites for lyrics searches.

NAME is a user-friendly name of the website.

TEMPLATE is the website URL with placeholders for ${artist} and
${song}.  Replacing these templates with actual artist and song
names results in a valid URL that can be used to return the
lyrics.

SEPARATOR is used in conjunction with TEMPLATE to build the
requested URL.  The empty spaces in the artist and song name are
replaced with SEPARATORs.  Some websites use dashes, others plus
signs, for example.

QUERY is used in the parsing phase of the HTML response.  It
specifies the CSS selectors used by elquery to extract the lyrics
part of the HTML page.

See the already defined websites for examples for all of the
above parameters."
  (let ((new-website (make-versuri--website
                      :name name
                      :template template
                      :separator separator
                      :query query)))
    ;; Replace the entry if there is already a website with the same name.
    (aif (cl-position name versuri--websites
                      :test #'equal
                      :key #'versuri--website-name)
        (setf (nth it versuri--websites) new-website)
      ;; Freshly add it, otherwise.
      (push new-website versuri--websites))))

(versuri-add-website "makeitpersonal"
  "https://makeitpersonal.co/lyrics?artist=${artist}&title=${song}"
  "-" "p")

(versuri-add-website "genius"
  "https://genius.com/${artist}-${song}-lyrics"
  "-" "div.lyrics p")

(versuri-add-website "songlyrics"
  "https://www.songlyrics.com/${artist}/${song}-lyrics/"
  "-" "p#songLyricsDiv")

(versuri-add-website "metrolyrics"
  "https://www.metrolyrics.com/${song}-lyrics-${artist}.html"
  "-" "p.verse")

(versuri-add-website "musixmatch"
  "https://www.musixmatch.com/lyrics/${artist}/${song}"
  "-" "p.mxm-lyrics__content span")

(versuri-add-website "azlyrics"
  "https://www.azlyrics.com/lyrics/${artist}/${song}.html"
  "" "div.container.main-page div.row div:nth-child(2) div:nth-of-type(5)")

(defun versuri-find-website (name)
  "Find a website by NAME in the list of defined websites."
  (cl-find-if (lambda (website)
                (equal website name))
              versuri--websites
              :key #'versuri--website-name))

(defun versuri--build-url (website artist song)
  "Use the WEBSITE definition to build a valid URL.
ARTIST and SONG are replaced in the WEBSITE template after they
are cleaned up according to the site specific URL format rules."
  (let* ((sep (versuri--website-separator website))
         ;; All known websites remove the quote in the url.
         (artist (s-replace "'" "" artist))
         (song   (s-replace "'" "" song))
         ;; Replace spaces with the site specific separator.
         (artist (s-replace " " sep artist))
         (song   (s-replace " " sep song)))
    (s-format (versuri--website-template website)
              'aget
              `(("artist" . ,artist)
                ("song"   . ,song)))))

(defun versuri--request (website artist song callback)
  "Request the lyrics for ARTIST and SONG at WEBSITE.
`callback' is called with the response data or with nil in case
of an error."
  (request (versuri--build-url website artist song)
           :parser 'buffer-string
           :sync nil
           :success (cl-function
                     (lambda (&key data &allow-other-keys)
                       (funcall callback data)))
           :error (lambda ()
                    ;; Website does not have the lyrics for this song
                    (funcall callback nil))
           :status-code
           '((403 . (lambda ()
                      ;; Nothing to do if you got banned.
                      (funcall callback nil)))))
  nil)

(defun versuri--parse (website html)
  "Parse the HTML for lyrics according to the WEBSITE rules."
  (let* ((tree (with-temp-buffer
                 (insert html)
                 (libxml-parse-html-region (point-min) (point-max))))
         (queried (esxml-query-all
                   (versuri--website-query website)
                   tree)))
    ;; Gather all available strings in a single string. This string represents
    ;; the lyrics.
    (-tree-reduce-from
     (lambda (curr res)
       (s-concat (if (stringp curr)
                     curr
                   "")
                 res))
     ""
     queried)))

(cl-defun versuri-lyrics
    (artist song callback &optional (websites versuri--websites))
  "Pass the lyrics for ARTIST and SONG to the CALLBACK function.

Async call. If the lyrics is found in the database, use that.
Otherwise, search through WEBSITES for them. If found, save
them to the database and recursively call this function again.

By default, WEBSITES is bound to the list of all the known
websites. To avoid getting banned, a random website is taken on
every request. If the lyrics is not found on that website, repeat
the call with the remaining websites."
  (if-let (lyrics (versuri--db-get-lyrics artist song))
      (funcall callback lyrics)
    (when-let (website (nth (random (length websites))
                            websites))
        (versuri--request website artist song
          (lambda (resp)
            (if (and resp
                     ;; makeitpersonal
                     (not (s-contains? "Sorry, We don't have lyrics" resp)))
                ;; Positive response
                (when-let (lyrics (versuri--parse website resp))
                  (versuri--db-save-lyrics artist song lyrics)
                  (versuri-lyrics artist song callback))
              ;; Lyrics not found, try another website.
              (versuri-lyrics artist song callback
                              (-remove-item website websites))))))))

(defvar versuri--artist nil)
(defvar versuri--song nil)
(defvar versuri--buffer nil)

(defun versuri-lyrics-forget ()
  "Forget the current lyrics and kill the buffer."
  (interactive)
  (versuri-delete-lyrics versuri--artist versuri--song)
  (kill-buffer versuri--buffer))

(defun versuri-lyrics-try-another-site ()
  "Find another website for this lyrics.
Similar to `versuri-lyrics-forget', but the lyrics is then
searched and displayed again in a new buffer.  Not all websites
have the same lyrics for the same song.  Some might be
incomplete, some might be ugly."
  (interactive)
  (versuri-delete-lyrics versuri--artist versuri--song)
  (kill-buffer versuri--buffer)
  (versuri-display versuri--artist versuri--song))

(defvar versuri-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m (kbd "q") #'kill-current-buffer)
    (define-key m (kbd "x") #'versuri-lyrics-forget)
    (define-key m (kbd "r") #'versuri-lyrics-try-another-site)
    m)
  "Keymap for `versuri-mode'.")

(define-derived-mode versuri-mode fundamental-mode "versuri"
  "Major mode for versuri lyrics buffers."
  (make-local-variable 'versuri--artist)
  (make-local-variable 'versuri--song)
  (make-local-variable 'versuri--buffer)
  (read-only-mode))

(defun versuri-display (artist song)
  "Search and display the lyrics for ARTIST and SONG in a buffer.

Async call.  When found, the lyrics are inserted in a new
`versuri-mode' buffer.  If the buffer with the same lyrics
already exists, switch to it and don't create a new buffer."
  (versuri-lyrics artist song
    (lambda (lyrics)
      (let ((name (format "%s - %s | lyrics" artist song)))
        (aif (get-buffer name)
            (switch-to-buffer it)
          (let ((b (generate-new-buffer name)))
            (with-current-buffer b
              (save-excursion
                (insert (format "%s - %s\n\n" artist song))
                (insert lyrics))
              (versuri-mode)
              (setq-local versuri--artist artist)
              (setq-local versuri--song song)
              (setq-local versuri--buffer it))
            (switch-to-buffer b)))))))

(defun versuri-save (artist song)
  "Search and save the lyrics for ARTIST and SONG.

Async call.  When found, the lyrics are saved in the database.
If lyrics already in the database, do nothing."
  (versuri-lyrics artist song #'ignore))

(defun versuri-save-bulk (songs max-timeout)
  "Save the lyrics for all SONGS.

SONGS is a list of '(artist song) lists.
To avoid getting banned by the lyrics websites, wait a maximum of
MAX-TIMEOUT seconds between requests.

Sync call! Depending on the number of entries in the SONGS list,
it can take a while.  In the meantime, Emacs will be blocked.
Better use it while on a coffee break."
  (dolist (song songs)
    (message "%s - %s" (car song) (cadr song))
    (versuri-save (car song) (cadr song))
    (sleep-for (random max-timeout)))
  (message "Done."))

(provide 'versuri)

;;; versuri.el ends here
