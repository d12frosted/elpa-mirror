;;; smilefjes.el --- View Norwegian Food Safety Authority restaurant ratings  -*- lexical-binding: t; -*-

;; URL: https://github.com/themkat/mos-mode
;; Package-Version: 20230129.2110
;; Package-Commit: 52ec05240efba2d5d4666aabf773a1aa63bb3f1a
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4") (request "0.3.2") (ht "2.3") (dash "2.19.1") (helm "3.8.6"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Simple package for checking if a restaurant have a good rating with the
;; Food Authority of Norway (Mattilsynet).  The rating is given as a smiley
;; (smile is obviously good, straight mouth meh, sad is not so good).
;; Determined by hygienic stuff and more, and is not a test of tastiness.
;; Emojify mode is recommended, but not required.

;;; Code:
(require 'request)
(require 'json)
(require 'helm)
(require 'dash)
(require 'ht)
(require 'url-util)

(defun smilefjes--cities-to-helm-sources (cities)
  "Translates the json-ish format CITIES to a format helm can understand."
  (-flatten (-map (lambda (city-info)
          (-let [(&hash "name" name) city-info]
            (split-string name "/")))
                  (ht-get cities "codes"))))

(defvar smilefjes-selected-city nil)
(defun smilefjes-select-city (cities)
  "Use helm to select a city from the list CITIES.
Collects the resulting city in SMILEFJES-SELECTED-CITY."
  (let ((helm-cities (smilefjes--cities-to-helm-sources cities)))
    (helm :sources (helm-build-sync-source "cities"
                     :candidates helm-cities
                     :action (lambda (city)
                               (setq smilefjes-selected-city city)))
          :buffer "*smilefjes-select-city*")))

(defun smilefjes-fetch-cities ()
  "Fetch a list of cities, and then use the result to select a city."
  (request "https://data.ssb.no/api/klass/v1/classifications/110/codes?from=2022-06-06"
    :headers '(("accept" . "application/json"))
    :parser (lambda ()
              (let ((json-object-type 'hash-table)
                    (json-array-type 'list))
                (json-read)))
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (smilefjes-select-city data)))
    ;; not recommended, but makes our code easier to handle and reason about :P
    :sync t
    :error (cl-function
            (lambda ()
              (message "Failed to fetch Norwegian cities!")))))


(defun smilefjes--restaurants-to-helm-sources (cities)
  "Translate the json-format CITIES to a format understandable by helm."
  (-map (lambda (city-info)
          (-let [(&hash "navn" name "total_karakter" rating) city-info]
            (cons name rating)))
        (ht-get cities "entries")))

(defvar smilefjes-selected-restaurant nil)
(defun smilefjes-select-restaurant (restaurants)
  "Use helm to select a restaurant from the list RESTAURANTS.
Collects the resulting restaurant in SMILEFJES-SELECTED-RESTAURANT."
  (let ((helm-restaurants (smilefjes--restaurants-to-helm-sources restaurants)))
    (helm :sources (helm-build-sync-source "restaurants"
                     :candidates (mapcar #'car helm-restaurants)
                     :action (lambda (restaurant)
                               (setq smilefjes-selected-restaurant (assoc restaurant helm-restaurants))))
          :buffer "*smilefjes-select-restaurant*")))

(defvar smilefjes-restaurants-complete nil)
(defun smilefjes-fetch-mattilsynet-reports (city &optional page)
  "Fetches the Mattilsynet-reports for CITY.  Use PAGE to paginate."
  (request (concat "https://hotell.difi.no/api/json/mattilsynet/smilefjes/tilsyn?poststed=" (url-encode-url city)
                   "&page=" (number-to-string (or page 1)))
      :headers '(("accept" . "application/json"))
      :parser (lambda ()
                (let ((json-object-type 'hash-table)
                      (json-array-type 'list))
                  (json-read)))
      :success (cl-function
                (lambda (&key data &allow-other-keys)
                  (let ((total-pages (ht-get data "pages"))
                        (current-page (or page 1)))
                    (ht-set! smilefjes-restaurants-complete "entries" (append (ht-get data "entries")
                                                                              (ht-get smilefjes-restaurants-complete "entries")))
                    (if (< current-page total-pages)
                        (smilefjes-fetch-mattilsynet-reports city (+ current-page 1))
                      (smilefjes-select-restaurant smilefjes-restaurants-complete)))))
      ;; not recommended, but makes our code easier to handle and reason about :P
      :sync t
      :error (cl-function
              (lambda ()
                (message "Failed to fetch Mattilsynet reports!")))))

(defun smilefjes-rating-to-emoji (rating)
  "Translate the Mattilsynet report number RATING to emoji."
  (cond ((or (string-equal rating "0")
             (string-equal rating "1"))
         ":)")
        ((string-equal rating "2")
         ":/")
        ((string-equal rating "3")
         ":(")
        (t
         "Not rated")))

(defface smilefjes-face
  '((t :height 2.5))
  "Face to make the size a little bigger in the result buffers."
  :group 'smilefjes)

(declare-function emojify-mode "ext:emojify" nil t)

;;;###autoload
(defun smilefjes ()
  "Main entrypoint."
  (interactive)

  ;; reset state
  (setq smilefjes-restaurants-complete (ht ("entries" '())))
  (setq smilefjes-selected-city nil)
  (setq smilefjes-selected-restaurant nil)

  ;; hack to allow bigger data sets to run my awful recursive algorithm above
  (let ((max-lisp-eval-depth 10000))
    (smilefjes-fetch-cities)
    (when smilefjes-selected-city
      (smilefjes-fetch-mattilsynet-reports smilefjes-selected-city)))
  
  ;; Create a buffer with a reports
  (-if-let* ((restaurant-info smilefjes-selected-restaurant)
             (restaurant-name (car restaurant-info))
             (restaurant-rating (cdr restaurant-info))
             (report-buffer (generate-new-buffer (concat "*Mattilsynet smilefjes report for " restaurant-name "*"))))
      (with-current-buffer report-buffer
        (insert restaurant-name)
        (insert ?\n)
        (insert "Rating: ")
        (insert (smilefjes-rating-to-emoji restaurant-rating))
        (when (require 'emojify nil t)
          (emojify-mode))
        (buffer-face-set 'smilefjes-face)
        (read-only-mode)
        (switch-to-buffer report-buffer))))

(provide 'smilefjes)
;;; smilefjes.el ends here
