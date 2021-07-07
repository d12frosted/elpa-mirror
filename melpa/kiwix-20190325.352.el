;;; kiwix.el --- Searching offline Wikipedia through Kiwix.
;;; -*- coding: utf-8 -*-

;; Author: stardiviner <numbchild@gmail.com>
;; Maintainer: stardiviner <numbchild@gmail.com>
;; Keywords: kiwix wikipedia
;; Package-Version: 20190325.352
;; Package-Commit: c662f3dc5d924a4b64b7af4af28f15f27b7cea1e
;; URL: https://github.com/stardiviner/kiwix.el
;; Created: 23th July 2016
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.4") (cl-lib "0.5"))

;;; Commentary:

;;; This currently only works for Linux, not tested for Mac OS X and Windows.

;;; Kiwix installation
;;
;; http://www.kiwix.org

;;; Config:
;;
;; (use-package kiwix
;;   :ensure t
;;   :after org
;;   :commands (kiwix-launch-server kiwix-at-point-interactive)
;;   :bind (:map document-prefix ("w" . kiwix-at-point-interactive))
;;   :init (setq kiwix-server-use-docker t
;;               kiwix-server-port 8080
;;               kiwix-default-library "wikipedia_zh_all_2015-11.zim"))

;;; Usage:
;;
;; 1. [M-x kiwix-launch-server] to launch Kiwix server.
;; 2. [M-x kiwix-at-point] to search the word under point or the region selected string.

;;; Code:


(require 'cl-lib)

(autoload 'org-link-set-parameters "org")
(autoload 'org-store-link-props "org")

(defgroup kiwix-mode nil
  "Kiwix customization options."
  :group 'kiwix-mode)

(defcustom kiwix-server-use-docker t
  "Using Docker container for kiwix-serve or not?"
  :type 'boolean
  :safe #'booleanp
  :group 'kiwix-mode)

(defcustom kiwix-server-port 8000
  "Specify default kiwix-serve server port."
  :type 'number
  :safe #'numberp
  :group 'kiwix-mode)

(defcustom kiwix-server-url (format "http://127.0.0.1:%s/" kiwix-server-port)
  "Specify Kiwix server URL."
  :type 'string
  :group 'kiwix-mode)

(defcustom kiwix-server-command
  (cond
   ((string-equal system-type "gnu/linux")
    "/usr/lib/kiwix/bin/kiwix-serve ")
   ((string-equal system-type "darwin")
    (warn "You need to specify Mac OS X Kiwix path. And send a PR to my repo."))
   ((string-equal system-type "windows-nt")
    (warn "You need to specify Windows Kiwix path. And send a PR to my repo.")))
  "Specify kiwix server command."
  :type 'string
  :group 'kiwix-mode)

(defun kiwix-dir-detect ()
  "Detect Kiwix profile directory exist."
  (let ((kiwix-dir (concat (getenv "HOME") "/.www.kiwix.org/kiwix")))
    (if (file-accessible-directory-p kiwix-dir)
        kiwix-dir
      (warn "ERROR: Kiwix profile directory \".www.kiwix.org/kiwix\" is not accessible."))))

(defcustom kiwix-default-data-profile-name
  (when (kiwix-dir-detect)
    (car (directory-files
          (concat (getenv "HOME") "/.www.kiwix.org/kiwix") nil ".*\\.default")))
  "Specify the default Kiwix data profile path."
  :type 'string
  :group 'kiwix-mode)

(defcustom kiwix-default-data-path
  (when (kiwix-dir-detect)
    (concat (getenv "HOME") "/.www.kiwix.org/kiwix/" kiwix-default-data-profile-name))
  "Specify the default Kiwix data path."
  :type 'string
  :group 'kiwix-mode)

;;;###autoload
(defun kiwix--get-library-name (file)
  "Extract library name from library file."
  (replace-regexp-in-string "\.zim" "" file))

(defvar kiwix-libraries
  (when (kiwix-dir-detect)
    (mapcar #'kiwix--get-library-name
            (directory-files
             (concat kiwix-default-data-path "/data/library/") nil ".*\.zim")))
  "A list of Kiwix libraries.")

;; - examples:
;; - "wikipedia_en_all" - "wikipedia_en_all_2016-02"
;; - "wikipedia_zh_all" - "wikipedia_zh_all_2015-17"
;; - "wiktionary_en_all" - "wiktionary_en_all_2015-17"
;; - "wiktionary_zh_all" - "wiktionary_zh_all_2015-17"
;; - "wikipedia_en_medicine" - "wikipedia_en_medicine_2015-17"

(defun kiwix-select-library (&optional filter)
  "Select Kiwix library name."
  (completing-read "Kiwix library: " kiwix-libraries nil nil filter))

(defcustom kiwix-default-library "wikipedia_en_all.zim"
  "The default kiwix library when library fragment in link not specified."
  :type 'string
  :safe #'stringp
  :group 'kiwix-mode)

(defcustom kiwix-search-interactively t
  "`kiwix-at-point' search interactively."
  :type 'boolean
  :safe #'booleanp
  :group 'kiwix-mode)

(defcustom kiwix-mode-prefix nil
  "Specify kiwix-mode keybinding prefix before loading."
  :type 'kbd
  :group 'kiwix-mode)

;; launch Kiwix server
;;;###autoload
(defun kiwix-launch-server ()
  "Launch Kiwix server."
  (interactive)
  (let ((library-option "--library ")
        (port (concat "--port=" kiwix-server-port " "))
        (daemon "--daemon ")
        (library-path (concat kiwix-default-data-path "/data/library/library.xml")))
    (if kiwix-server-use-docker
        (async-shell-command
         (concat "docker run -d "
                 "--name kiwix-serve "
                 "-v " (file-name-directory library-path) ":" "/data "
                 "kiwix/kiwix-serve"
                 (kiwix-select-library)))
      (async-shell-command
       (concat kiwix-server-command
               library-option port daemon (shell-quote-argument library-path))))))

(defun kiwix-capitalize-first (string)
  "Only capitalize the first word of STRING."
  (concat (string (upcase (aref string 0))) (substring string 1)))

(defun kiwix-query (query &optional library)
  "Search `QUERY' in `LIBRARY' with Kiwix."
  (let* ((kiwix-library (if library library (kiwix--get-library-name kiwix-default-library)))
         (url (concat
               kiwix-server-url kiwix-library "/A/"
               ;; query need to be convert to URL encoding: "禅宗" https://zh.wikipedia.org/wiki/%E7%A6%85%E5%AE%97
               (url-encode-url
                ;; convert space to underline: "Beta distribution" "Beta_distribution"
                (replace-regexp-in-string
                 " " "_"
                 ;; only capitalize the first word. like: "meta-circular interpreter" -> "Meta-circular interpreter"
                 (kiwix-capitalize-first query)
                 nil nil))
               ".html")))
    (browse-url url)))

;;;###autoload
(defun kiwix-at-point (&optional interactively)
  "Search for the symbol at point with `kiwix-query'.

Or When prefix argument `INTERACTIVELY' specified, then prompt
for query string and library interactively."
  (interactive "P")
  (let* ((library (if (or kiwix-search-interactively interactively)
                      (kiwix-select-library)
                    (kiwix--get-library-name kiwix-default-library)))
         (query (if interactively
                    (read-string "Kiwix Search: "
                                 (if mark-active
                                     (buffer-substring (region-beginning) (region-end))
                                   (thing-at-point 'symbol)))
                  (progn (if mark-active
                             (buffer-substring (region-beginning) (region-end))
                           (thing-at-point 'symbol))))))
    (message (format "library: %s, query: %s" library query))
    (if (or (null library)
            (string-empty-p library)
            (null query)
            (string-empty-p query))
        (error "Your query is invalid")
      (kiwix-query query library))))

;;;###autoload
(defun kiwix-at-point-interactive ()
  "Interactively input to query with kiwix."
  (interactive)
  (let ((current-prefix-arg t))
    (call-interactively 'kiwix-at-point)))

;;; Support Org-mode
;;
;; - [[wikipedia:(library):query]]
;; - [[wikipedia:query]]
;;
;; links:
;; - wikipedia:(zh):%E7%A6%85%E5%AE%97
;; - wikipedia:(en):linux
;; - wikipedia:linux
;;
;; - parameter `link' will be (en):linux" or linux".
;;
;; elisp regexp: "\\(?:(\\(.*\\)):\\)?\\([^] \n\t\r]*\\)"
;; - non capturing group (\(?:...\)) for optional library
;; - group 1: library (en or zh)
;; - group 2: link? (match everything but ], space, tab, carriage return, linefeed by using [^] \n\t\r]*)
;; for open wiki search query with local application database.

(defun kiwix-org-get-library (link)
  "Get library from Org-mode `LINK'."
  (if (string-match-p "[a-zA-Z\ ]+" (match-string 2 link)) ; validate query is English
      ;; convert between libraries full name and abbrev.
      (or (match-string 1 link) (kiwix-select-library))
    ;; validate query is non-English
    (kiwix-select-library "zh")))

;;;###autoload
(defun org-wikipedia-link-open (link)
  "Open LINK in external Wikipedia program."
  ;; The regexp: (library):query
  ;; - query : should not exclude space
  (when (string-match "\\(?:(\\(.*\\)):\\)?\\([^]\n\t\r]*\\)"  link) ; (library):query
    (let* ((library (kiwix-org-get-library link))
           (query (match-string 2 link))
           (url (concat
                 kiwix-server-url
                 library "/A/"
                 ;; query need to be convert to URL encoding: "禅宗" https://zh.wikipedia.org/wiki/%E7%A6%85%E5%AE%97
                 (url-encode-url
                  ;; convert space to underline: "Beta distribution" "Beta_distribution"
                  (replace-regexp-in-string
                   " " "_"
                   ;; only capitalize the first word. like: "meta-circular interpreter" -> "Meta-circular interpreter"
                   (kiwix-capitalize-first query)
                   nil nil))
                 ".html")))
      ;; (prin1 (format "library: %s, query: %s, url: %s" library query url))
      (browse-url url))))

;;;###autoload
(defun org-wikipedia-link-export (link description format)
  "Export the Wikipedia LINK with DESCRIPTION for FORMAT from Org files."
  (when (string-match "\\(?:(\\(.*\\)):\\)?\\([^] \n\t\r]*\\)" link)
    (let* ((library (kiwix-org-get-library link))
           (query (url-encode-url (or (match-string 2 link) description)))
           ;; "http://en.wikipedia.org/wiki/Linux"
           ;;         --
           ;;          ^- library: en, zh
           (path (concat "http://" library ".wikipedia.org/wiki/" query))
           (desc (or (match-string 2 link) description)))
      (when (stringp path)
        (cond
         ((eq format 'html) (format "<a href=\"%s\">%s</a>" path desc))
         ((eq format 'latex) (format "\\href{%s}{%s}" path desc))
         (t path))))))

;;;###autoload
(defun org-wikipedia-store-link ()
  "Store a link to a Wikipedia link."
  ;; [C-c o C-l l] `org-store-link'
  ;; remove those interactive functions. use normal function instead.
  (when (eq major-mode 'wiki-mode)
    (let* ((query (read-string "Wikipedia Query with Kiwix: "))
           (library (kiwix-select-library))
           (link (concat "wikipedia:" "(" library "):" query)))
      (org-store-link-props :type "wikipedia"
                            :link link
                            :description query)
      link)))

;;;###autoload
(org-link-set-parameters "wikipedia" ; NOTE: use `wikipedia' for future backend changing.
                         :follow #'org-wikipedia-link-open
                         :store #'org-wikipedia-store-link
                         :export #'org-wikipedia-link-export)

;;;###autoload
(add-hook 'org-store-link-functions 'org-wikipedia-store-link t)

(defun kiwix-mode-enable ()
  "Enable kiwix-mode."
  )

(defun kiwix-mode-disable ()
  "Disable kiwix-mode."
  )

(defvar kiwix-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "kiwix-mode map.")

;;;###autoload
(define-minor-mode kiwix-mode
  "Kiwix global minor mode for searching Kiwix serve."
  :require 'kiwix-mode
  :init-value nil
  :lighter " Kiwix"
  :group 'kiwix-mode
  :keymap kiwix-mode-map
  (if kiwix-mode (kiwix-mode-enable) (kiwix-mode-disable)))

;;;###autoload
(define-global-minor-mode global-kiwix-mode kiwix-mode
  kiwix-mode)


(provide 'kiwix)

;;; kiwix.el ends here
