;;; teletext-yle.el --- Teletext provider for Finnish national network YLE -*- lexical-binding: t -*-
;;
;; SPDX-License-Identifier: ISC
;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-teletext-yle
;; Package-Version: 20210927.825
;; Package-Commit: 9c8f4b503923c4ec688e2dcc9dff62d71bc55933
;; Package-Requires: ((emacs "24.3") (teletext "0.1"))
;; Version: 0.1.0
;; Keywords: comm help hypermedia
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Provides a teletext broadcast from YLE, the Finnish national
;; television network.  A TV tuner is not needed for browsing: an
;; ordinary internet connection is enough.  The service is free of
;; charge and you don't need to have your own YLE account.
;;
;; The broadcast is retrieved from YLE's official HTTP API.  This
;; Emacs package is not made by YLE and is not endorsed by them or
;; affiliated with them in any way.
;;
;; Note: The vast majority of YLE teletext pages are in Finnish with a
;; small selection in Swedish and only news headlines in English.
;;
;;; Code:

(require 'json)
(require 'url)

(require 'teletext)

(defvar teletext-yle--auth
  (list "7ae4681c" "effd5dd0d540d1eaade99c1ab466be0a")
  "API key used to download teletext pages from YLE.

The default key is shared with all Emacs users as an act of
goodwill.  Please use it only for casual browsing.  The API has a
rate limit.  Exceeding the limit will block all requests for about
an hour.  If you want to do experiments that might exceed it,
please get your own free key at <https://developer.yle.fi/>.")

(defvar teletext-yle--cache (make-hash-table)
  "Cache for recently retrieved YLE teletext pages.")

(defun teletext-yle--page-url (page)
  "Internal helper to get the API URL for an YLE teletext PAGE."
  (concat "https://external.api.yle.fi"
          "/v1/teletext/pages/" (number-to-string page) ".json"
          "?app_id="  (nth 0 teletext-yle--auth)
          "&app_key=" (nth 1 teletext-yle--auth)))

(defconst teletext-yle--colors
  '("Black" "Red" "Green" "Yellow" "Blue" "Magenta" "Cyan" "White")
  "Internal list of colors from the YLE teletext API.")

(defconst teletext-yle--graphics-colors
  (mapcar (lambda (color) (concat "G" color)) teletext-yle--colors)
  "Internal list of colors from the YLE teletext API.")

(defconst teletext-yle--keyword-re
  (concat (regexp-quote "{")
          (regexp-opt (append
                       teletext-yle--colors
                       teletext-yle--graphics-colors
                       '("BB" "NB")
                       '("Flash" "Steady" "Conceal" "Hold" "Release")
                       '("ESC" "NH" "DH" "CG" "SG" "EB" "SB" "DW" "DS"))
                      t)
          (regexp-quote "}"))
  "Internal regular expression to match one YLE teletext keyword.")

(defun teletext-yle--decode-line ()
  "Internal helper to display one line of text on an YLE teletext page."
  (let ((bg "black") (fg "white") (graphics-p nil) (case-fold-search nil))
    (while (not (eolp))
      (let ((keyword nil) (start (point)))
        (cond ((re-search-forward teletext-yle--keyword-re (point-at-eol) t)
               (setq keyword (match-string 1))
               (replace-match " ")
               (goto-char (match-beginning 0)))
              (t
               (goto-char (point-at-eol))))
        (let ((end (point)))
          (cond (graphics-p
                 (delete-region start end)
                 (teletext-insert-spaces bg (- end start)))
                (t
                 (teletext-put-color bg fg start end))))
        (cond ((equal keyword "BB")
               (setq bg "black"))
              ((equal keyword "NB")
               (setq bg fg))
              ((member keyword teletext-yle--colors)
               (setq graphics-p nil fg (downcase keyword)))
              ((member keyword teletext-yle--graphics-colors)
               (setq graphics-p t fg (downcase (substring keyword 1)))))))
    (teletext-insert-spaces bg (- 40 (- (point) (point-at-bol))))))

(defun teletext-yle--download-page-json (page)
  "Internal helper to get the JSON for an YLE teletext PAGE."
  (let ((url (teletext-yle--page-url page)))
    (with-temp-buffer
      (condition-case _
          (let ((url-show-status nil))
            (url-insert-file-contents url)
            (json-read))
        ((file-error)
         (message "Teletext page not found")
         nil)
        ((json-error end-of-file)
         (message "Error decoding teletext page")
         nil)))))

(defun teletext-yle--get-page-json (page force)
  "Internal helper to get the JSON for an YLE teletext PAGE.

Previously visited pages are cached in `teletext-yle--cache`.
This function retrieves the page from cache unless the cache is
stale or FORCE is non-nil.  A newly downloaded page is put in
cache."
  (let ((cached (unless force (gethash page teletext-yle--cache))))
    (when cached
      (let* ((timestamp (nth 0 cached))
             (age (truncate (time-to-seconds (time-since timestamp)))))
        (when (> age 60)
          (remhash page teletext-yle--cache)
          (setq cached nil))))
    (or (and cached (nth 1 cached))
        (let ((json (teletext-yle--download-page-json page)))
          (puthash page (list (current-time) json) teletext-yle--cache)
          json))))

(defun teletext-yle--insert-from-json (parsed-json page subpage)
  "Internal helper to insert the contents of an YLE teletext PAGE.

SUBPAGE is the subpage (1..n) of that page.  PARSED-JSON is an
Emacs Lisp representation of the JSON response corresponding to
PAGE from the YLE API."
  (cl-flet ((vector-to-list (x) (cl-map 'list #'identity x))
            (assoc* (key x) (cdr (assoc key x))))
    (let* ((page-json (assoc* 'page (assoc* 'teletext parsed-json)))
           (subpages (vector-to-list (assoc* 'subpage page-json)))
           (this-subpage
            (or (cl-some (lambda (this-subpage)
                           (let* ((snumber (assoc* 'number this-subpage))
                                  (number (and snumber
                                               (string-to-number snumber))))
                             (and (equal number subpage)
                                  this-subpage)))
                         subpages)
                (car subpages))))
      (mapc (lambda (line)
              (let ((text (assoc* 'Text line)))
                (when text
                  (let ((start (point)))
                    (insert text)
                    (goto-char start))))
              (teletext-yle--decode-line)
              (insert "\n"))
            (vector-to-list
             (assoc* 'line (cl-some (lambda (x)
                                      (and (equal "all" (assoc* 'type x)) x))
                                    (vector-to-list
                                     (assoc* 'content this-subpage))))))
      (list (cons 'page page)
            (cons 'subpage (if (null this-subpage) 1
                             (string-to-number
                              (assoc* 'number this-subpage))))
            (cons 'subpages (max 1 (length subpages)))
            (cons 'prev-page (let ((pg (assoc* 'prevpg page-json)))
                               (and pg (string-to-number pg))))
            (cons 'next-page (let ((pg (assoc* 'nextpg page-json)))
                               (and pg (string-to-number pg))))
            (cons 'network-heading "YLE TEKSTI-TV")
            (cons 'network-page-text "Sivu:")
            (cons 'network-time-format "{dd}.{mm}. {HH}:{MM}")))))

(defun teletext-yle--page (network page subpage force)
  "Internal helper to insert the contents of YLE PAGE/SUBPAGE.

NETWORK must be \"YLE\"."
  (cl-assert (equal network "YLE"))
  (teletext-yle--insert-from-json
   (teletext-yle--get-page-json page force)
   page subpage))

(defun teletext-yle--networks ()
  "Internal helper to get the YLE teletext network list."
  '("YLE"))

;;;###autoload
(defun teletext-yle-provide ()
  "Add YLE to the teletext network list."
  (teletext-provide
   'teletext-yle
   :networks #'teletext-yle--networks
   :page #'teletext-yle--page))

;;;###autoload
(teletext-yle-provide)

(provide 'teletext-yle)

;;; teletext-yle.el ends here
