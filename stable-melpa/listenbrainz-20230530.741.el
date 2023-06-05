;;; listenbrainz.el --- ListenBrainz API interface -*- coding: utf-8; lexical-binding: t -*-

;; Copyright 2023 FoAM
;;
;; Author: nik gaffney <nik@fo.am>
;; Created: 2023-05-05
;; Version: 0.1
;; Package-Version: 20230530.741
;; Package-Commit: 2386189ec8a19a74d7b8a46e08a9fa6d974a6305
;; Package-Requires: ((emacs "27.1") (request "0.3"))
;; Keywords: music, scrobbling, multimedia
;; URL: https://github.com/zzkt/listenbrainz

;; This file is not part of GNU Emacs.

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

;; An interface to ListenBrainz, a project to store a record of the music that
;; you listen to. The listening data, can be used to provide statistics,
;; recommendations and general exploration.
;;
;; The package can be used programmatically (e.g. from a music player) to auto
;; submit listening data `listenbrainz-submit-listen'. There are other entrypoints
;; for reading user stats such as `listenbrainz-stats-artists' or
;; `listenbrainz-listens'.
;;
;; Some API calls require a user token, which can be found in your ListenBrainz
;; profile. Configure, set or `customize' the `listenbrainz-api-token' as needed.
;;
;; https://listenbrainz.readthedocs.io/


;;; Code:

(require 'request)
(require 'json)


;;; ;; ;; ;  ; ;   ;  ;      ;
;;
;; API config
;;
;;; ; ;; ;;

(defcustom listenbrainz-api-url "https://api.listenbrainz.org"
  "URL for listenbrainz API.
Documentation available at https://listenbrainz.readthedocs.io/"
  :type 'string
  :group 'listenbrainz)

(defcustom listenbrainz-api-token ""
  "An auth token is required for some functions.
Details can be found near https://listenbrainz.org/profile/"
  :type 'string
  :group 'listenbrainz)


;;; ;; ;; ;  ; ;   ;  ;      ;
;;
;; Constants that are relevant to using the API
;;  https://listenbrainz.readthedocs.io/en/production/dev/api/#constants
;;
;; ;; ; ;  ;

(defconst listenbrainz--MAX_LISTEN_SIZE 10240
  "Maximum overall listen size in bytes, to prevent egregious spamming.
listenbrainz.webserver.views.api_tools.MAX_LISTEN_SIZE = 10240")

(defconst listenbrainz--MAX_ITEMS_PER_GET 100
  "The maximum number of listens returned in a single GET request.
listenbrainz.webserver.views.api_tools.MAX_ITEMS_PER_GET = 100")

(defconst listenbrainz--DEFAULT_ITEMS_PER_GET 25
  "The default number of listens returned in a single GET request.
listenbrainz.webserver.views.api_tools.DEFAULT_ITEMS_PER_GET = 25")

(defconst listenbrainz--MAX_TAGS_PER_LISTEN 50
  "The maximum number of tags per listen.
listenbrainz.webserver.views.api_tools.MAX_TAGS_PER_LISTEN = 50")

(defconst listenbrainz--MAX_TAG_SIZE 64
  "The maximum length of a tag.
listenbrainz.webserver.views.api_tools.MAX_TAG_SIZE = 64")

;;; ;; ;; ;  ; ;   ;  ;      ;
;;
;; Timestamps
;;
;;; ;; ;  ;

(defun listenbrainz-timestamp (&optional time)
  "Return a ListenBrainz compatible timestamp for the `current-time' or TIME.
All timestamps used in ListenBrainz are UNIX epoch timestamps in UTC."
  (if time (time-convert time 'integer)
      (time-convert (current-time) 'integer)))


;;; ;; ;; ;  ; ;   ;  ;      ;
;;
;; Formatting & formatters
;;
;;;; ; ;; ;

(defmacro listenbrainz--deformatter (name format-string format-args alist)
  "Generate function with NAME to format data returned from an API call.
The function has the name `listenbrainz--format-NAME`.

The ALIST is the relevant section of the response payload in dotted form as
seen in `let-alist'. The FORMAT-STRING and FORMAT-ARGS are applied to each
element in ALIST and also assumed to be accessors for the ALIST, but can
be any valid `format' string.

For example, format track info from .payload.listens as an `org-mode' table.

 (listenbrainz--deformatter (\"listens\"
                           \"%s | %s | %s | %s |\n\"
                           (.track_metadata.artist_name
                            .track_metadata.track_name
                            .track_metadata.release_name
                            .recording_msid)
                           .payload.listens))

macroexpands to something like ->

 (defun listenbrainz--format-listens (data)
   (let-alist data
              (seq-map
               (lambda (i)
                 (let-alist i
                            (format \"%s | %s | %s | %s |\n\"
                                    .track_metadata.artist_name
                                    .track_metadata.track_name
                                    .track_metadata.release_name
                                    .recording_msid
                                    )))
               .payload.listens)))"

  (let ((f (intern (concat "listenbrainz--format-" name)))
        (doc "Some details from listening data."))
    `(defun ,f (data) ,doc
       (let-alist data
                  (seq-map
                   (lambda (i)
                     (let-alist i
                                (format ,format-string ,@format-args)))
                   ,alist)))))


;; Core API formatters

;; listens -> listenbrainz--format-listens
(listenbrainz--deformatter "listens"
                           "%s | %s |\n"
                           (.track_metadata.artist_name
                            .track_metadata.track_name)
                           .payload.listens)

;; playing now -> listenbrainz--format-playing
(listenbrainz--deformatter "playing"
                           "%s | %s |\n"
                           (.track_metadata.artist_name
                            .track_metadata.track_name)
                           .payload.listens)


;; Statistics API formatters

;; releases -> listenbrainz--format-stats-0
(listenbrainz--deformatter "stats-0"
                           "%s | %s | %s |\n"
                           (.artist_name .release_name .listen_count)
                           .payload.releases)

;; artists -> listenbrainz--format-stats-1
(listenbrainz--deformatter "stats-1"
                           "%s | %s |\n"
                           (.artist_name .listen_count)
                           .payload.artists)

;; recordings -> listenbrainz--format-stats-2
(listenbrainz--deformatter "stats-2"
                           "%s | %s | %s |\n"
                           (.artist_name .track_name .listen_count)
                           .payload.recordings)


;; Social API formatters

;; follows -> listenbrainz--format-followers-list
(listenbrainz--deformatter "followers-list"
                           "%s |\n"
                           (i) ;; note scope
                           .followers)

;; follows -> listenbrainz--format-followers-graph
(listenbrainz--deformatter "followers-graph"
                           "%s -> %s |\n"
                           (i (cdadr data)) ;; note scope
                           .followers)

;; following -> listenbrainz--format-following
(listenbrainz--deformatter "following"
                           "%s |\n"
                           (i) ;; note scope
                           .following)


;;; ;; ;; ;  ; ;   ;  ;      ;
;;
;; Core API Endpoints
;;  https://listenbrainz.readthedocs.io/en/production/dev/api/#core-api-endpoints
;;
;;; ; ;; ; ;   ;

(defun listenbrainz-validate-token (token)
  "Check if TOKEN is valid. Return a username or nil."
  (message "listenbrainz: checking token %s" token)
  (let ((response
          (request-response-data
           (request
            (format "%s/1/validate-token" listenbrainz-api-url)
            :type "GET"
            :headers (list `("Authorization" . ,(format "Token %s" token)))
            :parser 'json-read
            :sync t
            :success (cl-function
                      (lambda (&key data &allow-other-keys)
                        (if (eq t (assoc-default 'valid data))
                            (message "Token is valid for user: %s"
                                     (assoc-default 'user_name data))
                            (message "Not a valid user token"))))))))
    ;; return user_name or nil
    (if (assoc-default 'user_name response)
        (format "%s" (assoc-default 'user_name response))
        nil)))


;;;###autoload
(defun listenbrainz-listens (username &optional count)
  "Get listing data for USERNAME (optionally get COUNT number of items)."
  (message "listenbrainz: getting listens for %s" username)
  (let* ((limit (if count count 25))
         (response
           (request-response-data
            (request
             (format "%s/1/user/%s/listens" listenbrainz-api-url username)
             :type "GET"
             :params (list `("count" . ,limit))
             :parser 'json-read
             :sync t
             :success (cl-function
                       (lambda (&key data &allow-other-keys)
                         (message "Listens for user: %s\n%s" username
                                  (if data data ""))))))))
    (princ (listenbrainz--format-listens response))))


;;;###autoload
(defun listenbrainz-playing-now (username)
  "Get `playing now' info for USERNAME."
  (message "listenbrainz: getting playing now for %s" username)
  (let* ((response
           (request-response-data
            (request
             (format "%s/1/user/%s/playing-now" listenbrainz-api-url username)
             :type "GET"
             :parser 'json-read
             :sync t
             :success (cl-function
                       (lambda (&key data &allow-other-keys)
                         (message "User playing now: %s\n%s" username
                                  (if data data ""))))))))
    (princ (listenbrainz--format-playing response))))


;; see
;; - https://listenbrainz.readthedocs.io/en/production/dev/api-usage/#submitting-listens
;; - https://listenbrainz.readthedocs.io/en/production/dev/json/#json-doc

(defun listenbrainz-submit-listen (type artist track &optional release)
  "Submit listening data to ListenBrainz.
- listen TYPE (string) either \='single\=', \='import\=' or \='playing_now\='
- ARTIST name (string)
- TRACK title (string)
- RELEASE title (string) also  album title."
  (message "listenbrainz: submitting %s - %s - %s" artist track release)
  (let* ((json-null "")
         (now (listenbrainz-timestamp))
         (token (format "Token %s" listenbrainz-api-token))
         (listen (json-encode
                  (list
                   (cons "listen_type" type)
                   (list "payload"
                         (remove nil
                                 (list
                                  (when (string= type "single") (cons "listened_at" now))
                                  (list "track_metadata"
                                        (cons "artist_name" artist)
                                        (cons "track_name" track)
                                        ;; (cons "release_name" release)
                                        ))))))))
    (request
     (format "%s/1/submit-listens" listenbrainz-api-url)
     :type "POST"
     :data listen
     :headers (list '("Content-Type" . "application/json")
                    `("Authorization" . ,token))
     :parser 'json-read
     :success (cl-function
               (lambda (&key data &allow-other-keys)
                 (message "status: %s" (assoc-default 'status data)))))))

;;;###autoload
(defun listenbrainz-submit-single-listen (artist track &optional release)
  "Submit data for a single track (ARTIST TRACK and optional RELEASE)."
  (listenbrainz-submit-listen "single" artist track (when release release)))

;;;###autoload
(defun listenbrainz-submit-playing-now (artist track &optional release)
  "Submit data for track (ARTIST TRACK and optional RELEASE) playing now."
  (listenbrainz-submit-listen "playing_now" artist track (when release release)))


;;; ;; ;; ;  ; ;   ;  ;      ;
;;
;; Statistics API Endpoints
;;  https://listenbrainz.readthedocs.io/en/production/dev/api/#statistics-api-endpoints
;;
;; ; ;; ; ;


;;;###autoload
(defun listenbrainz-stats-recordings (username &optional count range)
  "Get top tracks for USERNAME (optionally get COUNT number of items.
RANGE (str) – Optional, time interval for which statistics should be collected,
possible values are week, month, year, all_time, defaults to all_time."
  (message "listenbrainz: getting top releases for %s" username)
  (let* ((limit (if count count 25))
         (range (if range range "all_time"))
         (response
           (request-response-data
            (request
             (format "%s/1/stats/user/%s/recordings" listenbrainz-api-url username)
             :type "GET"
             :params (list `("count" . ,limit)
                           `("range" . ,range))
             :parser 'json-read
             :sync t
             :success (cl-function
                       (lambda (&key data &allow-other-keys)
                         (message "Top recordings for user: %s\n%s" username
                                  (if data data ""))))))))
    (princ (listenbrainz--format-stats-2 response))))


;;;###autoload
(defun listenbrainz-stats-releases (username &optional count range)
  "Get top releases for USERNAME (optionally get COUNT number of items.
RANGE (str) – Optional, time interval for which statistics should be collected,
possible values are week, month, year, all_time, defaults to all_time."
  (message "listenbrainz: getting top releases for %s" username)
  (let* ((limit (if count count 25))
         (range (if range range "all_time"))
         (response
           (request-response-data
            (request
             (format "%s/1/stats/user/%s/releases" listenbrainz-api-url username)
             :type "GET"
             :params (list `("count" . ,limit)
                           `("range" . ,range))
             :parser 'json-read
             :sync t
             :success (cl-function
                       (lambda (&key data &allow-other-keys)
                         (message "Top releases for user: %s\n%s" username
                                  (if data data ""))))))))
    (princ (listenbrainz--format-stats-0 response))))


;;;###autoload
(defun listenbrainz-stats-artists (username &optional count range)
  "Get top artists for USERNAME (optionally get COUNT number of items.
RANGE (str) – Optional, time interval for which statistics should be collected,
possible values are week, month, year, all_time, defaults to all_time."
  (message "listenbrainz: getting top artists for %s" username)
  (let* ((limit (if count count 25))
         (range (if range range "all_time"))
         (response
           (request-response-data
            (request
             (format "%s/1/stats/user/%s/artists" listenbrainz-api-url username)
             :type "GET"
             :params (list `("count" . ,limit)
                           `("range" . ,range))
             :parser 'json-read
             :sync t
             :success (cl-function
                       (lambda (&key data &allow-other-keys)
                         (message "Top artists for user: %s\n%s" username
                                  (if data data ""))))))))
    (princ (listenbrainz--format-stats-1 response))))


;;; ;; ;; ;  ; ;   ;  ;      ;
;;
;; Social API Endpoints
;;  https://listenbrainz.readthedocs.io/en/production/dev/api/#social-api-endpoints
;;
;;; ; ; ;;;     ;


;;;###autoload
(defun listenbrainz-followers (username &optional output)
  "Fetch the list of followers of USERNAME.
OUTPUT format can be either `list' (default) or `graph'."
  (message "listenbrainz: getting followers for %s" username)
  (let* ((response
           (request-response-data
            (request
             (format "%s/1/user/%s/followers" listenbrainz-api-url username)
             :type "GET"
             :parser 'json-read
             :sync t
             :success (cl-function
                       (lambda (&key data &allow-other-keys)
                         (message "Followers for %s\n%s" username
                                  (if data data ""))))))))
    (if (string= "graph" output)
        (princ (listenbrainz--format-followers-graph response))
        (princ (listenbrainz--format-followers-list response)))))

;;;###autoload
(defun listenbrainz-following (username)
  "Fetch the list of users followed by USERNAME."
  (message "listenbrainz: getting users %s is following" username)
  (let* ((response
           (request-response-data
            (request
             (format "%s/1/user/%s/following" listenbrainz-api-url username)
             :type "GET"
             :parser 'json-read
             :sync t
             :success (cl-function
                       (lambda (&key data &allow-other-keys)
                         (message "Users %s is following\n%s" username
                                  (if data data ""))))))))
    (princ (listenbrainz--format-following response))))


;;;

(provide 'listenbrainz)

;;; listenbrainz.el ends here
