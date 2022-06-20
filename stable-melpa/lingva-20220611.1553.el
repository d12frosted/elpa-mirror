;;; lingva.el --- Access Google Translate via lingva.ml  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 marty hiatt

;; Author: marty hiatt <martianhiatus [a t] riseup [d o t] net>
;; Homepage: https://codeberg.org/martianh/lingva.el
;; Package-Requires: ((emacs "25.1"))
;; Package-Version: 20220611.1553
;; Package-Commit: 5008210246b5dc0abddec5ecbb833faaf117cb49
;; Version: 0.2
;; Keywords: convenience, translation, wp, text

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

;; Interact with the Lingva.ml API from within Emacs. Lingva.ml provides
;; access to Google Translate with no tracking, like Invidious does for
;; YouTube. See the readme for more information.

;;; Code:

(require 'json)

(when (require 'pdf-tools nil :no-error)
  (declare-function pdf-view-active-region-text "pdf-view"))

(defvar url-http-end-of-headers)
(defvar url-request-method)

(defgroup lingva nil
  "Interact with Lingva.ml instances."
  :prefix "linvga"
  :group 'external)

(defcustom lingva-instance "https://lingva.ml"
  "The lingva instance to use."
  :type 'string)

;; let user choose these from lingva-languages
(defcustom lingva-source "auto"
  "The default language to translate from, as a two letter code.
For details of what languages are availble and their
corresponding codes, see `lingva-languages'."
  :type 'string)

(defcustom lingva-target "en"
  "The default language to translate to, as a two letter code.
For details of what languages are availble and their
corresponding codes, see `lingva-languages'."
  :type 'string)

(defvar lingva-languages
  '(("auto" . "Detect")
    ("af" . "Afrikaans")
    ("sq" . "Albanian")
    ("am" . "Amharic")
    ("ar" . "Arabic")
    ("hy" . "Armenian")
    ("az" . "Azerbaijani")
    ("eu" . "Basque")
    ("be" . "Belarusian")
    ("bn" . "Bengali")
    ("bs" . "Bosnian")
    ("bg" . "Bulgarian")
    ("ca" . "Catalan")
    ("ceb" . "Cebuano")
    ("ny" . "Chichewa")
    ("zh" . "Chinese")
    ("zh_HANT" . "Chinese (Traditional)")
    ("co" . "Corsican")
    ("hr" . "Croatian")
    ("cs" . "Czech")
    ("da" . "Danish")
    ("nl" . "Dutch")
    ("en" . "English")
    ("eo" . "Esperanto")
    ("et" . "Estonian")
    ("tl" . "Filipino")
    ("fi" . "Finnish")
    ("fr" . "French")
    ("fy" . "Frisian")
    ("gl" . "Galician")
    ("ka" . "Georgian")
    ("de" . "German")
    ("el" . "Greek")
    ("gu" . "Gujarati")
    ("ht" . "Haitian Creole")
    ("ha" . "Hausa")
    ("haw" . "Hawaiian")
    ("iw" . "Hebrew")
    ("hi" . "Hindi")
    ("hmn" . "Hmong")
    ("hu" . "Hungarian")
    ("is" . "Icelandic")
    ("ig" . "Igbo")
    ("id" . "Indonesian")
    ("ga" . "Irish")
    ("it" . "Italian")
    ("ja" . "Japanese")
    ("jw" . "Javanese")
    ("kn" . "Kannada")
    ("kk" . "Kazakh")
    ("km" . "Khmer")
    ("rw" . "Kinyarwanda")
    ("ko" . "Korean")
    ("ku" . "Kurdish (Kurmanji)")
    ("ky" . "Kyrgyz")
    ("lo" . "Lao")
    ("la" . "Latin")
    ("lv" . "Latvian")
    ("lt" . "Lithuanian")
    ("lb" . "Luxembourgish")
    ("mk" . "Macedonian")
    ("mg" . "Malagasy")
    ("ms" . "Malay")
    ("ml" . "Malayalam")
    ("mt" . "Maltese")
    ("mi" . "Maori")
    ("mr" . "Marathi")
    ("mn" . "Mongolian")
    ("my" . "Myanmar (Burmese)")
    ("ne" . "Nepali")
    ("no" . "Norwegian")
    ("or" . "Odia (Oriya)")
    ("ps" . "Pashto")
    ("fa" . "Persian")
    ("pl" . "Polish")
    ("pt" . "Portuguese")
    ("pa" . "Punjabi")
    ("ro" . "Romanian")
    ("ru" . "Russian")
    ("sm" . "Samoan")
    ("gd" . "Scots Gaelic")
    ("sr" . "Serbian")
    ("st" . "Sesotho")
    ("sn" . "Shona")
    ("sd" . "Sindhi")
    ("si" . "Sinhala")
    ("sk" . "Slovak")
    ("sl" . "Slovenian")
    ("so" . "Somali")
    ("es" . "Spanish")
    ("su" . "Sundanese")
    ("sw" . "Swahili")
    ("sv" . "Swedish")
    ("tg" . "Tajik")
    ("ta" . "Tamil")
    ("tt" . "Tatar")
    ("te" . "Telugu")
    ("th" . "Thai")
    ("tr" . "Turkish")
    ("tk" . "Turkmen")
    ("uk" . "Ukrainian")
    ("ur" . "Urdu")
    ("ug" . "Uyghur")
    ("uz" . "Uzbek")
    ("vi" . "Vietnamese")
    ("cy" . "Welsh")
    ("xh" . "Xhosa")
    ("yi" . "Yiddish")
    ("yo" . "Yoruba")
    ("zu" . "Zulu"))
  "The list of languages to choose from.
Can be used for either source or target for a lingva query.
\n Can be updated by running `lingva-update-lingva-languages'.")

(defvar lingva-languages-url
  (concat lingva-instance "/api/v1/languages")
  "The URL for a lingva source and target languages list query.")

(defun lingva--get-languages ()
  "Return the languages supported by the server."
  (let* ((url-request-method "GET")
         (response-buffer (url-retrieve-synchronously
                           lingva-languages-url t))
         (json-array-type 'list))
    (with-current-buffer response-buffer
      (goto-char (point-min))
      (search-forward "\n\n")
      (json-read))))

(defun lingva--return-langs-as-list ()
  "Return a list of cons cells containing languages supported by the server."
  (let* ((lingva-langs-response (lingva--get-languages))
         (langs-response (cdar lingva-langs-response)))
    (mapcar (lambda (x)
              (cons (cdar x)
                    (cdadr x)))
            langs-response)))

(defun lingva-update-lingva-languages ()
  "Set `lingva-languages' to the data returned by the server."
  (interactive)
  (setq lingva-languages (lingva--return-langs-as-list)))

(defun lingva--get-query-region ()
  "Get current region for default search."
  (if (equal major-mode 'pdf-view-mode)
      (when (region-active-p)
        (pdf-view-active-region-text))
    (when (use-region-p)
      (buffer-substring-no-properties (region-beginning) (region-end)))))

(defun lingva--get-text-query (text region)
  "Get the text query to send.
\nEither from TEXT, or REGION, or current word, or user input."
  (replace-regexp-in-string
   "/" "|"
   (or text
       (read-string
        (format "Translate (%s): " (or region (current-word) ""))
        nil nil (or region (current-word))))))

(defun lingva--read-lang (source-or-target langs)
  "Read a language from list LANGS.
\n SOURCE-OR-TARGET is whether the language selected is a source
language or target language."
  (let ((response
         (completing-read (format "%s language: "
                                  (upcase-initials
                                   (symbol-name source-or-target)))
                          langs)))
    (alist-get response langs nil nil #'equal)))

(defun lingva--reverse-langs (langs)
  "Reverse the alist of LANGS."
  (mapcar (lambda (x)
            (cons (cdr x) (car x)))
          langs))

;;;###autoload
(defun lingva-translate (&optional arg text variable-pitch)
  "Prompt for TEXT to translate and return the translation in a buffer.
By default, in order, text is given as a second argument, the
current region, the word at point, or user input. With a single
prefix ARG, prompt to specify a source language different to
`lingva-source'. With a second prefix ARG, promp to to specify
both a source language different to `lingva-source' and a target
language different to `lingva-target'."
  (interactive "P")
  (let* ((url-request-method "GET")
         (lingva-langs-reversed
          (lingva--reverse-langs lingva-languages))
         (lingva-source-temp
          (if (and arg (>= (car arg) 4)) ; if 1 or 2 prefix args
              (lingva--read-lang 'source lingva-langs-reversed)
            lingva-source))
         (lingva-target-temp
          (if (equal arg '(16))         ; only if 2 prefix args
              (lingva--read-lang 'target lingva-langs-reversed)
            lingva-target))
         (region (lingva--get-query-region))
         (text (lingva--get-text-query text region))
         (query (url-hexify-string text)))
    (url-retrieve
     (concat lingva-instance "/api/v1/"
             lingva-source-temp "/"
             lingva-target-temp "/"
             query)
     (lambda (_status)
       (apply #'lingva--translate-callback
              (lingva--translate-process-json)
              (list variable-pitch lingva-source-temp lingva-target-temp))))))

(defun lingva--translate-callback (json &optional variable-pitch source target)
  "Display the translation returned in JSON in a buffer.
\nWhen VARIABLE-PITCH is non-nil, activate `variable-pitch-mode'.
SOURCE and TARGET and the languages translated to and from."
  (if (equal 'error (caar json))
      (error "Error - %s" (alist-get 'error json))
    (with-current-buffer (get-buffer-create
                          (concat "*lingva-" source "-" target "*"))
      (let ((inhibit-read-only t)
            (json-processed
             (replace-regexp-in-string "|" "/" (alist-get
                                                'translation json))))
        (special-mode)
        (erase-buffer)
        (insert json-processed)
        (kill-new json-processed)
        (message "Translation copied to clipboard.")
        (switch-to-buffer-other-window (current-buffer))
        (visual-line-mode)
        ;; handle borked filling:
        (when variable-pitch (variable-pitch-mode 1))
        (setq-local header-line-format
                    (propertize
                     (format "Lingva translation from %s to %s:"
                             (alist-get source lingva-languages
                                        nil nil #'equal)
                             (alist-get target lingva-languages
                                        nil nil #'equal))
                     'face font-lock-comment-face))
        (goto-char (point-min))))))

(defun lingva--translate-process-json ()
  "Parse the JSON from the HTTP response."
  (goto-char (point-min))
  (re-search-forward "^$" nil 'move)
  (let ((json-string
         (decode-coding-string
          (buffer-substring-no-properties (point) (point-max))
          'utf-8)))
    (json-read-from-string json-string)))

;; process the http response:
(defun lingva--response ()
  "Capture response buffer content as string."
  (with-current-buffer (current-buffer)
    (buffer-substring-no-properties (point-min) (point-max))))

(defun lingva--response-body (pattern)
  "Return substring matching PATTERN from `lingva--response'."
  (let ((resp (lingva--response)))
    (string-match pattern resp)
    (match-string 0 resp)))

(defun lingva--status ()
  "Return HTTP Response Status Code from `lingva--response'."
  (let* ((status-line (lingva--response-body "^HTTP/1.*$")))
    (string-match "[0-9][0-9][0-9]" status-line)
    (match-string 0 status-line)))

(provide 'lingva)
;;; lingva.el ends here
