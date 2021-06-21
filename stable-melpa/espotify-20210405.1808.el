;;; espotify.el --- Spotify access library  -*- lexical-binding: t; -*-

;; Author: Jose A Ortega Ruiz <jao@gnu.org>
;; Maintainer: Jose A Ortega Ruiz
;; Keywords: multimedia
;; Package-Version: 20210405.1808
;; Package-Commit: 5bf63dacc5df8a74860e80dabd16afce68a24a36
;; License: GPL-3.0-or-later
;; Version: 0.1
;; Homepage: https://codeberg.org/jao/espotify
;; Package-Requires: ((emacs "26.1"))

;; Copyright (C) 2021  Jose A Ortega Ruiz

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

;; This package provides generic utilities to access Spotify and
;; use its query APIs, as well as controlling local players via
;; their dbus interface.  Although they can be used in other
;; programs, the functions in this package were originally
;; intended for consult-spotify and ivy-spotify.
;; For espotify to work, you need to set valid values for
;; `espotify-client-id' and `espotify-client-secret'.  To get
;; valid values for them, one just needs to register a spotify
;; application at https://developer.spotify.com/my-applications

;; All .el files have been automatically generated from the literate program
;; https://codeberg.org/jao/espotify/src/branch/main/readme.org

;;; Code:

(require 'dbus)

(defgroup espotify nil
  "Access to Spotify API and clients"
  :group 'multimedia)

(defcustom espotify-client-id ""
  "Spotify application client ID."
  :type 'string)

(defcustom espotify-client-secret ""
  "Spotify application client secret."
  :type 'string)

(defcustom espotify-service-name "mopidy"
  "Name of the DBUS service used by the client we talk to.

The official Spotify client uses `spotify', but one can also use
alternative clients such as mopidy or spotifyd."
  :type 'string)

(defcustom espotify-use-system-bus-p t
  "Whether to access the spotify client using the system DBUS."
  :type 'boolean)


(defvar espotify-spotify-api-url
  "https://api.spotify.com/v1"
  "End-point to access Spotify's REST API.")

(defvar espotify-spotify-api-authentication-url
  "https://accounts.spotify.com/api/token"
  "End-point to access Spotify's authentication tokens.")

(defun espotify--basic-auth-credentials ()
  "Get credentials."
  (unless (and (> (length espotify-client-id) 0)
               (> (length espotify-client-secret) 0))
    (user-error "Invalid Spotify credentials: please set `%s' and `%s'"
                "espotify-client-id" "espotify-client-secret"))
  (let ((credential (concat espotify-client-id ":" espotify-client-secret)))
    (concat "Basic " (base64-encode-string credential t))))

(defvar url-http-end-of-headers)

(defun espotify--with-auth-token (callback)
  "Use CALLBACK with a token."
  (let ((url-request-method "POST")
        (url-request-data "&grant_type=client_credentials")
        (url-request-extra-headers
         `(("Content-Type" . "application/x-www-form-urlencoded")
           ("Authorization" . ,(espotify--basic-auth-credentials)))))
    (url-retrieve espotify-spotify-api-authentication-url
                  (lambda (_status)
                    (goto-char url-http-end-of-headers)
                    (funcall callback
                             (alist-get 'access_token (json-read)))))))

(defun espotify--make-search-url (term types &optional filter)
  "Use TERM, TYPES and FILTER to create a URL."
  (when (null types)
    (error "Must supply a non-empty list of types to search for"))
  (let ((term (url-encode-url term)))
    (format "%s/search?q=%s&type=%s&limit=50"
            espotify-spotify-api-url
            (if filter (format "%s:%s" filter term) term)
            (mapconcat #'symbol-name types ","))))

(defun espotify--with-query-results (token url callback)
  "Call CALLBACK with the results of browsing URL with TOKEN."
  (let ((url-request-extra-headers
         `(("Authorization" . ,(concat "Bearer " token)))))
    (url-retrieve url
                  (lambda (_status)
                    (goto-char url-http-end-of-headers)
                    (funcall callback
                             (let ((json-array-type 'list))
                               (thread-first
                                   (buffer-substring (point) (point-max))
                                 (decode-coding-string 'utf-8)
                                 (json-read-from-string))))))))

(defun espotify-get (callback url)
  "Perform a GET query to URL, receiving its results with CALLBACK."
  (espotify--with-auth-token
     (lambda (token)
       (espotify--with-query-results token url callback))))

(defun espotify-search (callback term types &optional filter)
  "Perform a search query for TERM, receiving its results with CALLBACK.

The types of resource we want is given by TYPES, and we can add an additional
query FILTER."
  (espotify-get callback (espotify--make-search-url term types filter)))

(defun espotify--type-items (res type)
  "Auxiliary function for RES and TYPE."
  (alist-get 'items (alist-get (intern (format "%ss" type)) res)))

(defun espotify-search* (callback term types &optional filter)
  "Like `espotify-search', but CALLBACK receives lists of items types.
   TERM FILTER TYPES for checkdoc compliance."
  (let* ((types (if (listp types) types (list types)))
         (cb (lambda (res)
               (let ((its (mapcar (lambda (tp)
                                    (espotify--type-items res tp))
                                  types)))
                 (apply callback its)))))
    (espotify-search cb term types filter)))

(defun espotify-search-all (callback term &optional types filter)
  "Like `espotify-search', but CALLBACK receives a single list of results.
   TERM, FILTER to make checkdoc happy."
  (let ((types (or types '(album track artist playlist))))
    (espotify-search* (lambda (&rest items)
                        (funcall callback (apply #'append items)))
                      term
                      types
                      filter)))

(defun espotify--additional-item-info (item)
  "Helper creating a string description of ITEM's metadata."
  (let ((names (mapcar (lambda (a) (alist-get 'name a))
                       (cons (alist-get 'album item)
                             (alist-get 'artists item))))
        (dname (alist-get 'display_name (alist-get 'owner item))))
    (mapconcat 'identity
               (seq-filter #'identity (append names (list dname)))
               ", ")))

;;;###autoload
(defun espotify-format-item (item)
  "Format the search result ITEM as a string with additional metadata.
The metadata will be accessible via `espotify-candidate-metadata'."
  (propertize (format "%s%s"
                      (alist-get 'name item)
                      (if-let ((info (espotify--additional-item-info item)))
                          (format " (%s)" info)
                        ""))
              'espotify-item item))

;;;###autoload
(defun espotify-candidate-metadata (cand)
  "Extract from CAND (as returned by `espotify-format-item') its metadata."
  (get-text-property 0 'espotify-item cand))

(defvar espotify-search-suffix "="
  "Suffix in the search string launching an actual Web query.")

(defvar espotify-search-threshold 8
  "Threshold to automatically launch an actual Web query.")

(defun espotify--distance (a b)
  "Distance between strings A and B."
  (if (fboundp 'string-distance)
      (string-distance a b)
    (abs (- (length a) (length b)))))

(defun espotify-check-term (prev new)
  "Compare search terms PREV and NEW return the one we should search, if any."
  (when (not (string-blank-p new))
    (cond ((string-suffix-p espotify-search-suffix new)
           (substring new 0 (- (length new)
                               (length espotify-search-suffix))))
          ((>= (espotify--distance prev new) espotify-search-threshold) new))))

(defun espotify--dbus-call (method &rest args)
  "Tell Spotify to execute METHOD with ARGS through DBUS."
  (apply #'dbus-call-method `(,(if espotify-use-system-bus-p :system :session)
                              ,(format "org.mpris.MediaPlayer2.%s"
                                       espotify-service-name)
                              "/org/mpris/MediaPlayer2"
                              "org.mpris.MediaPlayer2.Player"
                              ,method
                              ,@args)))

;;;###autoload
(defun espotify-play-uri (uri)
  "Use a DBUS call to play a URI denoting a resource."
  (espotify--dbus-call "OpenUri" uri))

;;;###autoload
(defun espotify-play-candidate (cand)
 "If CAND is a formatted item string and it has a URL, play it."
 (when-let (uri (alist-get 'uri (espotify-candidate-metadata cand)))
   (espotify-play-uri uri)))

;;;###autoload
(defun espotify-play-pause ()
  "Toggle default Spotify player via DBUS."
  (interactive)
  (espotify--dbus-call "PlayPause"))

;;;###autoload
(defun espotify-next ()
  "Tell default Spotify player to play next track via DBUS."
  (interactive)
  (espotify--dbus-call "Next"))

;;;###autoload
(defun espotify-previous ()
  "Tell default Spotify player to play previous track via DBUS."
  (interactive)
  (espotify--dbus-call "Previous"))

;;;###autoload
(defun espotify-show-candidate-info (candidate)
  "Show low-level info (an alist) about CANDIDATE."
  (pop-to-buffer (get-buffer-create "*espotify info*"))
  (read-only-mode -1)
  (delete-region (point-min) (point-max))
  (insert (propertize candidate 'face 'bold))
  (newline)
  (when-let (item (espotify-candidate-metadata candidate))
    (insert (pp-to-string item)))
  (newline)
  (goto-char (point-min))
  (read-only-mode 1))

;;;###autoload
(defun espotify-play-candidate-album (candidate)
  "Play album associated with selected CANDIDATE."
  (when-let (item (espotify-candidate-metadata candidate))
    (if-let (album (if (string= "album" (alist-get 'type item ""))
                       item
                     (alist-get 'album item)))
        (espotify-play-uri (alist-get 'uri album))
      (error "No album for %s" (alist-get 'name item)))))

;;;###autoload
(defun espotify-yank-candidate-url (candidate)
  "Add to kill ring the Spotify URL of this CANDIDATE."
  (when-let (item (espotify-candidate-metadata candidate))
    (if-let (url (alist-get 'spotify (alist-get 'external_urls item)))
        (kill-new url)
      (message "No spotify URL for this candidate"))))


(provide 'espotify)
;;; espotify.el ends here
