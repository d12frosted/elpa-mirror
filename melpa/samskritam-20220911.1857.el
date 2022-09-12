;;; samskritam.el --- Library to get samskrit word definition, translate to/from -*- lexical-binding: t -*-

;; Copyright (C) 2022 Krishna Thapa

;; Description: Samskrit definitions and translations
;; Author: Krishna Thapa <thapakrish@gmail.com>
;; URL: https://github.com/thapakrish/samskritam
;; Package-Version: 20220911.1857
;; Package-Commit: 664fd843589072663399d9cc5ea176dfce823208
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1") (google-translate "0.12.0"))
;; Keywords: convenience, language, samskrit, sanskrit, dictionary, translation

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package uses:
;; Google Translate to translate to/from Sanskrit
;; Sends request to https://ambuda.org/ for dictionary definition of words
;; Add Vedic characters to devanagari-inscript
;;
;;; Code:


(require 'url-parse)
(require 'url-http)
(require 'google-translate)
(require 'google-translate-smooth-ui)


(defvar samskritam-mode)

(defgroup samskritam nil
  "Provide functions for word definitions and translations."
  :group 'convenience)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; Translate ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defcustom samskritam-mode-line '(:eval (propertize " SKT" 'face 'mode-line-emphasis))
  "String to show in the mode-line of Samskritam.
Setting this to nil removes from the mode-line."
  :group 'samskritam
  :type '(choice (const :tag "Off" nil)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; Dictionary ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar samskritam-word-limit 20
  "Maximum amount of results to display.")


(defcustom samskritam-mode-line-position 0
  "Position in mode-line to place `samskritam-mode-line'."
  :type 'integer
  :group 'samskritam)


(defcustom samskritam-word-displayfn-alist nil
  "Alist for display functions per service.
By default, `message' is used."
  :type '(alist
          :key-type (symbol :tag "Name of service")
          :value-type (function :tag "Display function")))

(defun samskritam-word-displayfn (service)
  "Return the display function for SERVICE."
  (or (cdr (assoc service samskritam-word-displayfn-alist))
      #'message))

(defcustom samskritam-word-services
  '((vacaspatyam "https://ambuda.org/tools/dictionaries/vacaspatyam/%s" samskritam-word--parse-vacaspatyam)
    (mw "https://ambuda.org/tools/dictionaries/mw/%s" samskritam-word--parse-mw))
  "Services for `samskritam-word`.
A list of lists of the format (symbol url function-for-parsing).
Instead of an url string, url can be a custom function for retrieving results."
  :type '(alist
          :key-type (symbol :tag "Name of service")
          :value-type (group
                       (string :tag "Url (%s denotes search word)")
                       (function :tag "Parsing function"))))

(defcustom samskritam-word-default-service 'mw
  "The default service for `samskritam-word` commands.
Must be one of `samskritam-word-services'"
  :type '(choice
	  (const mw)
          (const vacaspatyam)
          symbol))

(defun samskritam-word--to-string (word service)
  "Get definition of WORD from SERVICE."
  (let* ((servicedata (assoc service samskritam-word-services))
         (retriever (nth 1 servicedata))
         (parser (nth 2 servicedata))
         (url-user-agent
          (if (eq (nth 0 servicedata) 'vacaspatyam)
              "Mozilla/5.0 (Macintosh; Intel Mac OS X 11_5_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36"
            url-user-agent)))
    (if (functionp retriever)
        (funcall retriever word)
      ;; adapted `url-insert-file-contents'
      (let* ((url (format retriever (downcase word)))
             (buffer (url-retrieve-synchronously url t t)))
        (with-temp-buffer
          (url-insert-buffer-contents buffer url)
	  (message "Got from url %s" url)
          (funcall parser))))))

(defun samskritam-word--expand (regex definition service)
  "Expand word given REGEX DEFINITION SERVICE."
  (let ((case-fold-search nil))
    (when (string-match regex definition)
      (concat
       definition
       "\n" (match-string 1 definition) ":\n"
       (mapconcat (lambda (s) (concat "  " s))
                  (split-string
                   (samskritam-word--to-string (match-string 1 definition) service)
                   "\n")
                  "\n")))))

;;;###autoload
(defun samskritam-word (word service &optional choose-service)
  "Define WORD by referencing various dictionary SERVICE.
By default uses `samskritam-word-default-service', but a prefix arg
lets the user CHOOSE-SERVICE."
  (interactive "MWord: \ni\nP")
  (let* ((service (or service
                      (if choose-service
                          (intern
                           (completing-read
                            "Service: " samskritam-word-services))
                        samskritam-word-default-service)))
         (results (samskritam-word--to-string word service)))

    (funcall
     (samskritam-word-displayfn service)
     (cond ((not results)
            "0 definitions found")
           ((samskritam-word--expand "Plural form of \\(.*\\)\\.$" results service))
           ((samskritam-word--expand "Past participle of \\(.*\\)\\.$" results service))
           ((samskritam-word--expand "Present participle of \\(.*\\)\\.$" results service))
           (t
            results)))))

(declare-function pdf-view-active-region-text "ext:pdf-view")

;;;###autoload
(defun samskritam-word-at-point (arg &optional service)
  "Use `samskritam-word' to define word at point.
When the region is active, define the marked phrase.
Prefix ARG lets you choose service.

In a non-interactive call SERVICE can be passed."
  (interactive "P")
  (let ((word
         (cond
          ((eq major-mode 'pdf-view-mode)
           (car (pdf-view-active-region-text)))
          ((use-region-p)
           (buffer-substring-no-properties
            (region-beginning)
            (region-end)))
          (t
           (substring-no-properties
            (thing-at-point 'word))))))
    (samskritam-word word service arg)))

(defface samskritam-word-face-1
  '((t :inherit font-lock-keyword-face))
  "Face for the part of speech of the definition.")

(defface samskritam-word-face-2
  '((t :inherit default))
  "Face for the body of the definition.")

(defun samskritam-word--join-results (results)
  "Join RESULTS for display."
  (mapconcat
   #'identity
   (if (> (length results) samskritam-word-limit)
       (cl-subseq results 0 samskritam-word-limit)
     results)
   "\n"))

(defun samskritam-word--regexp-to-face (regexp face)
  "Map word that mathces with REGEXP to FACE type."
  (goto-char (point-min))
  (while (re-search-forward regexp nil t)
    (let ((match (match-string 1)))
      (replace-match
       (propertize match 'face face)))))

(defconst samskritam-word--tag-faces
  '(("<\\(?:em\\|i\\)>\\(.*?\\)</\\(?:em\\|i\\)>" italic)
    ("<\\(?:b\\|i\\)>\\(.*?\\)</\\(?:b\\|i\\)>" bold)
    ("<cite>\\(.*?\\)</cite>" link)
    ("<abbr>\\(.*?\\)</abbr>" bold-italic)
    ("<strong>\\(.*?\\)</strong>" match)
    ("<span lang=\"[^\"]*\">\\([^<]*\\)</span>" variable-pitch)
    ("<span class=\"[^\"]*\">\\([^<]*\\)</span>" error)
    ("<span>\\(.*?\\)</span>" shadow)))

(defun samskritam-word--convert-html-tag-to-face (str)
  "Replace semantical HTML markup in STR with the relevant faces."
  (with-temp-buffer
    (insert str)
    (cl-loop for (regexp face) in samskritam-word--tag-faces do
             (samskritam-word--regexp-to-face regexp face))
    (buffer-string)))



(defun samskritam-word--parse-mw ()
  "Parse output from mw site and return formatted list."
  (message "This message is from MW word parser!")
  (save-match-data
    (let (results beg _part)
      ;;      (message "Output is: %s" results)
      (while (re-search-forward "<li class=\"dict-entry mw-entry\">" nil t)
        (skip-chars-forward " ")
        (setq beg (point))
        (when (re-search-forward "</li>")
          (push (concat
		 (propertize
                  (buffer-substring-no-properties beg (match-beginning 0))
                  'face 'samskritam-word-face-2))
                results)))
      (when (setq results (nreverse results))
        (samskritam-word--convert-html-tag-to-face (samskritam-word--join-results results))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; Devanagari Script ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Input method and key binding configuration.
(defvar samskritam-alternative-input-methods
      '(("devanagari-inscript" . [?\C-\\])))

(defvar samskritam-default-input-method
      (caar samskritam-alternative-input-methods))


(defun samskritam-toggle-alternative-input-method (method &optional arg interactive)
  "METHOD to toggle input method.  Takes in INTERACTIVE ARG."
  (if arg
      (toggle-input-method arg interactive)
    (let ((previous-input-method current-input-method))
      (when current-input-method
        (deactivate-input-method))
      (unless (and previous-input-method
                   (string= previous-input-method method))
        (activate-input-method method)))))

(defun samskritam-reload-alternative-input-methods ()
  "Load alternative input method."
  (dolist (config samskritam-alternative-input-methods)
    (let ((method (car config)))
      (global-set-key (cdr config)
                      `(lambda (&optional arg interactive)
                         ,(concat "Behaves similar to `toggle-input-method', but uses \""
                                  method "\" instead of `default-input-method'")
                         (interactive "P\np")
                         (samskritam-toggle-alternative-input-method ,method arg interactive))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(define-minor-mode samskritam-mode
  "Toggle Samskritam mode."
  :global t
  :version "0.1.0"
  :lighter ""
  :group 'samskritam
  :keymap (let ((map (make-sparse-keymap))) map)
  (if samskritam-mode
      ;; Turning the mode ON
      (progn
	;;	(google-translate--search-tkk)
	(samskritam-reload-alternative-input-methods)
	(add-to-list 'google-translate-supported-languages-alist '("Sanskrit"  . "sa")))

    ;; Turning the mode OFF

    ;; TODO: Clean UP
    ;; ()
    ))

(provide 'samskritam)
;;; samskritam.el ends here
