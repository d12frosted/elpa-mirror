;;; gscholar-bibtex.el --- Retrieve BibTeX from Google Scholar and other online sources(ACM, IEEE, DBLP)

;; Copyright (C) 2014  Junpeng Qiu

;; Author: Junpeng Qiu <qjpchmail@gmail.com>
;; Keywords: extensions
;; Package-Version: 20190130.555
;; Package-Commit: 3b651e3de116860eb1f1aef9b547a561784871fe
;; Version: 0.3.1

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

;; * gscholar bibtex

;;   Retrieve BibTeX entries from Google Scholar, ACM Digital Library, IEEE Xplore
;;   and DBLP by your query. All in Emacs Lisp!

;;   *UPDATE*: ACM Digital Library, IEEE Xplore, and DBLP are now supported though
;;    the package name doesn't suggest that.
;; ** Basic usage
;;    Without package.el:
;;        (add-to-list 'load-path "/path/to/gscholar-bibtex.el")
;;        (require 'gscholar-bibtex)

;;    With package.el: install via melpa!

;;    To use, simply call
;;         M-x gscholar-bibtex

;;   Choose a source, then enter your query and select the results.

;;   Available commands in `gscholar-bibtex-mode', i.e., in the window of search
;;   results:
;;   - n/p: next/previous
;;   - TAB: show BibTeX entry for current search result
;;   - A/W: append/write to `gscholar-bibtex-database-file' (see later)
;;   - a/w: append/write to a file
;;   - c: copy the current BibTeX entry
;;   - x: close BibTeX entry window
;;   - q: quit

;; ** Sources
;;   By default, I enable all sources(Google Scholar, ACM Digital Library, IEEE
;;   Xplore and DBLP). If you don't want to enable some of them, you could call
;;       M-x gscholar-bibtex-turn-off-sources

;;   Similarly, if you want to enable some of them, you could call
;;       M-x gscholar-bibtex-turn-on-sources

;;   To keep the configuration in your init file, you could use the following
;;   format(*NOT* real code):
;;       (gscholar-bibtex-source-on-off action source-name)

;;   Possible values:
;;   - action: :on or :off
;;   - source-name: "Google Scholar", "ACM Digital Library", "IEEE Xplore" or "DBLP"

;;   Say if you want to disable "IEEE Xplore", use the following code:
;;       (gscholar-bibtex-source-on-off :off "IEEE Xplore")

;; ** Default source
;;   If you have a preferred source, you can set it as default so you don't have to
;;   type the name to select the source every time you call `gscholar-bibtex'. Say
;;   if you want to set "Google Scholar" as default:
;;       (setq gscholar-bibtex-default-source "Google Scholar")

;;   Note that in order to make it work, you have to make sure the source name is
;;   correct and you don't disable the source that you set as default, otherwise
;;   the default source setting has no effect. Besides, if you only have one source
;;   enabled, then the enabled source automatically becomes the default, regardless
;;   of the value of `gscholar-bibtex-default-source'.

;; ** Configuring `gscholar-bibtex-database-file'
;;    If you have a master BibTeX file, say refs.bib, as database, and want to
;;    append/write the BibTeX entry to refs.bib without being asked for a
;;    filename to be written every time, you can set
;;    `gscholar-bibtex-database-file':
;;        (setq gscholar-bibtex-database-file "/path/to/refs.bib")

;;    Then use "A" or "W" to append or write to refs.bib, respectively.

;; ** Adding more sources
;;    Currently these three sources cover nearly all my needs, and it is possible
;;    if you need to add more sources.

;;    Basically, you need to implement following five functions(if you're willing,
;;    I think looking the source code is better. The implementation is easy!):
;; #+BEGIN_SRC elisp
;; (defun gscholar-bibtex-SourceName-search-results (query)
;; "In the body, call `gscholar-bibtex--url-retrieve-as-string' to return a string
;; containing query results"
;;   body)

;; (defun gscholar-bibtex-SourceName-titles (buffer-content)
;; "Given the string `buffer-content', return the list of titles"
;;   body)

;; (defun gscholar-bibtex-SourceName-subtitles (buffer-content)
;; "Given the string `buffer-content', return the list of subtitles"
;;   body)

;; (defun gscholar-bibtex-SourceName-bibtex-urls (buffer-content)
;; "Given the string `buffer-content', return the list of urls(or maybe other
;;  feature) of the BibTeX entries, which would be fed to the next function"
;;   body)

;; (defun gscholar-bibtex-SourceName-bibtex-content (arg)
;; "Given the url(or other feature) of a BibTeX entry, return the entry as string.
;; Also call `gscholar-bibtex--url-retrieve-as-string' for convenience"
;;   body)
;; #+END_SRC

;;    Then you need to add a line:
;;        (gscholar-bibtex-install-source "Source Name" 'SourceName)

;;    You should put this line somewhere near the end of `gscholar-bibtex.el',
;;    where you could find several `gscholar-bibtex-install-source' lines.

;;    That's all. Enjoy hacking^_^

;;; Code:

(require 'bibtex)
(require 'xml)
(require 'url)
(require 'json)

(defgroup gscholar-bibtex nil
  "Retrieve BibTeX from Google Scholar and other online sources(ACM, IEEE, DBLP)."
  :group 'bibtex)

(defconst gscholar-bibtex-version "0.3.1"
  "`gscholar-bibtex' version number.")

(defvar gscholar-bibtex-caller-buffer nil
  "Buffer that calls `gscholar-bibtex'.")

(defvar gscholar-bibtex-urls-cache nil
  "Cache for all the urls of BibTeX entries.")

(defvar gscholar-bibtex-entries-cache nil
  "Cache for the retrieved BibTeX entries.")

(defvar gscholar-bibtex-database-file nil
  "Default BibTeX database file.")

(defconst gscholar-bibtex-item-height 3
  "The height for each item.")

(defvar gscholar-bibtex-available-sources nil
  "Avaiable sources for query.")

(defvar gscholar-bibtex-enabled-sources nil
  "List of enabled sources.")

(defvar gscholar-bibtex-disabled-sources nil
  "List of disabled sources.")

(defvar gscholar-bibtex-selected-source nil
  "Currently selected source.")

(defvar gscholar-bibtex-default-source nil
  "Default source name.")

(defconst gscholar-bibtex-result-buffer-name "*gscholar-bibtex Search Results*"
  "Buffer name for Google Scholar search results.")

(defconst gscholar-bibtex-entry-buffer-name "*BibTeX entry*"
  "Buffer name for BibTeX entry.")

(defconst gscholar-bibtex-user-agent-string
  "Mozilla/5.0 (X11; Linux x86_64; rv:46.0) Gecko/20100101 Firefox/46.0"
  "User agent for `gscholar-bibtex'.")

(defconst gscholar-bibtex-function-suffixes-alist
  '((:search-results . "search-results")
    (:titles . "titles")
    (:subtitles . "subtitles")
    (:bibtex-urls . "bibtex-urls")
    (:bibtex-content . "bibtex-content")))

(defconst gscholar-bibtex-help
  (let ((help-message "[<n>/<p>] next/previous; [<TAB>] show BibTeX entry; [<A>/<W>] append/write to database;\
 [<a>/<w>] append/write to file; [<c>] copy entry; [<x>] close BibTeX entry window; [<q>] quit;"))
    (while (string-match "<\\([a-zA-Z]+\\)>" help-message)
      (setq help-message
            (replace-match
             (propertize (match-string 1 help-message) 'face 'font-lock-type-face)
             t t help-message)))
    help-message)
  "Help string for `gscholar-bibtex'.")

;; Face related
(defface gscholar-bibtex-title
  '((t (:height 1.4 :foreground "light sea green")))
  "Face for title"
  :group 'gscholar-bibtex)

(defface gscholar-bibtex-subtitle
  '((t (:height 1.0)))
  "Face for subtitle"
  :group 'gscholar-bibtex)

(defconst gcholar-bibtex-highlight-item-overlay
  (let ((ov (make-overlay 1 1)))
    (overlay-put ov 'face 'highlight)
    ov)
  "Overlay for item highlight.")

(defun gscholar-bibtex--move-to-line (N)
  (goto-char (point-min))
  (forward-line (1- N)))

(defun gscholar-bibtex-prettify-title (s)
  (propertize (or s "") 'face 'gscholar-bibtex-title))

(defun gscholar-bibtex-prettify-subtitle (s)
  (propertize (or s "") 'face 'gscholar-bibtex-subtitle))

(defun gscholar-bibtex-highlight-current-item-hook ()
  (save-excursion
    (let* ((line (gscholar-bibtex--current-beginning-line))
           (beg (progn (gscholar-bibtex--move-to-line line) (point)))
           (end (progn (gscholar-bibtex--move-to-line (+ line 3)) (point))))
      (move-overlay gcholar-bibtex-highlight-item-overlay beg end
                    (current-buffer)))))

;; Major mode
(defvar gscholar-bibtex-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "n" 'gscholar-bibtex-next-item)
    (define-key map "p" 'gscholar-bibtex-previous-item)
    (define-key map (kbd "<tab>") 'gscholar-bibtex-retrieve-and-show-bibtex)
    (define-key map "A" 'gscholar-bibtex-append-bibtex-to-database)
    (define-key map "W" 'gscholar-bibtex-write-bibtex-to-database)
    (define-key map "a" 'gscholar-bibtex-append-bibtex-to-file)
    (define-key map "w" 'gscholar-bibtex-write-bibtex-to-file)
    (define-key map "c" 'gscholar-bibtex-copy-bibtex-entry)
    (define-key map "x" 'gscholar-bibtex-quit-entry-window)
    (define-key map "q" 'gscholar-bibtex-quit-gscholar-window)
    map))

(define-derived-mode gscholar-bibtex-mode fundamental-mode "gscholar-bibtex"
  (setq buffer-read-only t)
  (add-hook 'pre-command-hook 'gscholar-bibtex-show-help nil t)
  (add-hook 'post-command-hook 'gscholar-bibtex-highlight-current-item-hook
            nil t))

(defun gscholar-bibtex-show-help ()
  (message "%s" gscholar-bibtex-help))

(defun gscholar-bibtex-guard ()
  (unless (eq major-mode 'gscholar-bibtex-mode)
    (error "Error: you are not in `gscholar-bibtex-mode'!")))

(defun gscholar-bibtex--string-cleanup (str)
  (while (string-match "\\`^\n+\\|^\\s-+\\|\\s-+$\\|\n+\\|\r+\\|^\r\\'" str)
    (setq str (replace-match "" t t str)))
  (replace-regexp-in-string "[\r\n\t ]+" " " str))

(defun gscholar-bibtex--current-beginning-line ()
  (1+ (* (gscholar-bibtex--current-index) gscholar-bibtex-item-height)))

(defun gscholar-bibtex--current-index ()
  (let ((line-number (+ (line-number-at-pos)
                        (if (= (point) (point-max))
                            -1 0))))
    (/ (1- line-number) gscholar-bibtex-item-height)))

(defun gscholar-bibtex--delete-response-header ()
  (ignore-errors
    (save-match-data
      (goto-char (point-min))
      (delete-region (point-min)
                     (1+ (re-search-forward "^$" nil t)))
      (goto-char (point-min)))))

(defun gscholar-bibtex--replace-html-entities (str)
  (let ((retval str)
        (pair-list
         '(("&amp;" . "&")
           ("&hellip;" . "...")
           ("&quot;" . "\"")
           ("&#[0-9]*;" .
            (lambda (match)
              (format "%c" (string-to-number (substring match 2 -1))))))))
    (dolist (elt pair-list retval)
      (setq retval (replace-regexp-in-string (car elt) (cdr elt) retval)))))

(defun gscholar-bibtex--html-value-cleanup (s)
  (gscholar-bibtex--string-cleanup
   (gscholar-bibtex--replace-html-entities
    (replace-regexp-in-string "<.*?>" "" s))))

(defun gscholar-bibtex--xml-child (children)
  (pcase-let ((`(,child) children)) child))

(defun gscholar-bibtex--xml-node-child (node)
  (gscholar-bibtex--xml-child
   (xml-node-children node)))

(defun gscholar-bibtex--xml-get-child (node child-name)
  (gscholar-bibtex--xml-child
   (xml-get-children node child-name)))

(defun gscholar-bibtex--url-retrieve-as-buffer (url)
  (let* ((url-request-extra-headers
          (append url-request-extra-headers `(("User-Agent" . ,gscholar-bibtex-user-agent-string))))
         (response-buffer (url-retrieve-synchronously url)))
    (with-current-buffer response-buffer
      (gscholar-bibtex--delete-response-header)
      (set-buffer-multibyte t))
    response-buffer))

(defun gscholar-bibtex--url-retrieve-as-string (url)
  (let ((response-buffer (gscholar-bibtex--url-retrieve-as-buffer url))
        retval)
    (with-current-buffer response-buffer
      (setq retval (buffer-string)))
    (kill-buffer response-buffer)
    retval))

(defun gscholar-bibtex-re-search (buffer-content surrounding-regexp subexp-count)
  (save-match-data
    (with-temp-buffer
      (insert buffer-content)
      (let (retval)
        (goto-char (point-min))
        (while (re-search-forward surrounding-regexp nil t)
          (push (gscholar-bibtex--html-value-cleanup
                 (match-string-no-properties subexp-count)) retval))
        (nreverse retval)))))

(defun gscholar-bibtex-next-item ()
  (interactive)
  (gscholar-bibtex-guard)
  (gscholar-bibtex--move-to-line (+ (gscholar-bibtex--current-beginning-line)
                                    gscholar-bibtex-item-height)))

(defun gscholar-bibtex-previous-item ()
  (interactive)
  (gscholar-bibtex-guard)
  (gscholar-bibtex--move-to-line (- (gscholar-bibtex--current-beginning-line)
                                    gscholar-bibtex-item-height)))

(defun gscholar-bibtex-retrieve-and-show-bibtex ()
  (interactive)
  (gscholar-bibtex-guard)
  (let* ((index (gscholar-bibtex--current-index))
         (bibtex-entry
          (progn (when (string= "" (elt gscholar-bibtex-entries-cache index))
                   (aset gscholar-bibtex-entries-cache index
                         (gscholar-bibtex-dispatcher
                          :bibtex-content
                          (nth index gscholar-bibtex-urls-cache))))
                 (elt gscholar-bibtex-entries-cache index)))
         (entry-buffer (get-buffer-create gscholar-bibtex-entry-buffer-name))
         (entry-window (get-buffer-window entry-buffer))
         (gscholar-window (selected-window)))
    (with-current-buffer entry-buffer
      (erase-buffer)
      (insert bibtex-entry)
      (bibtex-mode)
      ;; Have to manually call this to set `bibtex-entry-head', otherwise
      ;; `bibtex-parse-buffers-stealthily' will throw some errors since the our
      ;; BibTeX buffer is not associated with an existing file:-(
      (bibtex-set-dialect)
      (goto-char (point-min)))
    (unless entry-window
      (let ((entry-window (select-window (split-window-below))))
        (set-window-buffer entry-window entry-buffer)
        (display-buffer-record-window 'window entry-window entry-buffer)
        (set-window-prev-buffers entry-window nil))
      (select-window gscholar-window)))
  (gscholar-bibtex-show-help))

(defun gscholar-bibtex--write-bibtex-to-database-impl (&optional append)
  (gscholar-bibtex-guard)
  (gscholar-bibtex-retrieve-and-show-bibtex)
  (unless gscholar-bibtex-database-file
    (setq gscholar-bibtex-database-file
          (read-file-name "gscholar-bibtex database file:")))
  (if gscholar-bibtex-database-file
      (progn
        (with-current-buffer (get-buffer gscholar-bibtex-entry-buffer-name)
          (write-region nil nil gscholar-bibtex-database-file append))
        (message "%s BibTeX entry to %s" (if append "Append" "Write")
                 gscholar-bibtex-database-file))
    (error "Please set `gscholar-bibtex-database-file' first")))

(defun gscholar-bibtex-append-bibtex-to-database ()
  (interactive)
  (gscholar-bibtex--write-bibtex-to-database-impl t))

(defun gscholar-bibtex-write-bibtex-to-database ()
  (interactive)
  (gscholar-bibtex--write-bibtex-to-database-impl))

(defun gscholar-bibtex--write-bibtex-to-file-impl (prompt &optional append)
  (gscholar-bibtex-guard)
  (gscholar-bibtex-retrieve-and-show-bibtex)
  (let ((filename (read-file-name prompt)))
    (with-current-buffer (get-buffer gscholar-bibtex-entry-buffer-name)
      (write-region nil nil filename append))
    (message "%s BibTeX entry to %s" (if append "Append" "Write") filename)))

(defun gscholar-bibtex-append-bibtex-to-file ()
  (interactive)
  (gscholar-bibtex--write-bibtex-to-file-impl "Append BibTeX entry to file: " t))

(defun gscholar-bibtex-write-bibtex-to-file ()
  (interactive)
  (gscholar-bibtex--write-bibtex-to-file-impl "Write BibTeX entry to file: "))

(defun gscholar-bibtex-copy-bibtex-entry ()
  (interactive)
  (gscholar-bibtex-retrieve-and-show-bibtex)
  (with-current-buffer (get-buffer gscholar-bibtex-entry-buffer-name)
    (kill-new (buffer-string))
    (message "The current BiBTeX entry copied.")
    (sit-for 2)
    (gscholar-bibtex-show-help)))

(defun gscholar-bibtex-quit-entry-window ()
  (interactive)
  (gscholar-bibtex-guard)
  (let ((gscholar-window (selected-window))
        (entry-window (get-buffer-window gscholar-bibtex-entry-buffer-name)))
    (when entry-window
      (quit-restore-window entry-window 'kill)
      (select-window gscholar-window))))

(defun gscholar-bibtex-quit-gscholar-window ()
  (interactive)
  (gscholar-bibtex-guard)
  (let ((gscholar-window (selected-window))
        (entry-window (get-buffer-window gscholar-bibtex-entry-buffer-name))
        (caller-window (get-buffer-window gscholar-bibtex-caller-buffer)))
    (gscholar-bibtex-quit-entry-window)
      (quit-restore-window gscholar-window 'kill)
      (if caller-window
          (select-window caller-window)))
  (message ""))

(defun gscholar-bibtex-install-source (source-name source-symbol)
  (let ((retval t))
    (dolist (pair gscholar-bibtex-function-suffixes-alist retval)
      (unless
          (fboundp
           (gscholar-bibtex--get-dispatch-func-name (car pair) source-symbol))
        (setq retval nil)))
    (unless retval
      (error
       "Installation failed! You need to define all necessary functions!"))
    (push `(,source-name . ,source-symbol) gscholar-bibtex-available-sources)))

(defun gscholar-bibtex--get-dispatch-func-name (kind source-symbol)
  (intern
   (concat
    "gscholar-bibtex-"
    (symbol-name source-symbol)
    "-"
    (assoc-default kind gscholar-bibtex-function-suffixes-alist))))

;;; dispatcher
(defun gscholar-bibtex-dispatcher (kind arg)
  (funcall
   (gscholar-bibtex--get-dispatch-func-name
    kind
    (assoc-default gscholar-bibtex-selected-source
                   gscholar-bibtex-enabled-sources))
   arg))

(defun gscholar-bibtex--get-list-symbol-pair (action)
  (let* ((alist '((:on . ("disabled" . "enabled"))
                  (:off . ("enabled" . "disabled"))))
         (names (assoc-default action alist))
         (build-name (lambda (s)
                       (intern (concat "gscholar-bibtex-" s "-sources")))))
    `(,(funcall build-name (car names)) . ,(funcall build-name (cdr names)))))

;;;###autoload
(defun gscholar-bibtex-source-on-off (action source-name)
  (let* ((prompt (if (eq action :on) "available" "enabled"))
         (symbol-pair (gscholar-bibtex--get-list-symbol-pair action))
         (source-list (car symbol-pair))
         (dest-list (cdr symbol-pair))
         (source-pair (assoc source-name (symbol-value source-list))))
    (if source-pair
        (progn
          (set source-list
               (remove source-pair (symbol-value source-list)))
          (push source-pair (symbol-value dest-list)))
      (message
       (concat "Please choose from the " prompt " sources!")))))

(defun gscholar-bibtex--source-on-off-interactive-impl (action)
  (let ((source-list (car (gscholar-bibtex--get-list-symbol-pair action)))
        source-name)
    (while (and (symbol-value source-list)
                (not
                 (string= "" (setq source-name
                                   (completing-read
                                    "Source[empty to exit]:"
                                    (symbol-value source-list))))))
      (gscholar-bibtex-source-on-off action source-name))))

;;; acm
(defun gscholar-bibtex-acm-search-results (query)
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/x-www-form-urlencoded")))
         (url-request-data
          (mapconcat (lambda (arg)
                       (concat (url-hexify-string (car arg))
                               "="
                               (url-hexify-string (cdr arg))))
                     `(("query" . ,(replace-regexp-in-string " " "\+" query)))
                     "&")))
    (gscholar-bibtex--url-retrieve-as-string
     "http://dl.acm.org/results.cfm?h=1")))
(defun gscholar-bibtex-acm-titles (buffer-content)
  (gscholar-bibtex-re-search
   buffer-content
   "<A HREF=\"citation.cfm[^>]*?>\\(.*?\\)</A>" 1))

(defun gscholar-bibtex-acm-subtitles (buffer-content)
  (gscholar-bibtex-re-search
   buffer-content
   "<div class=\"authors\">\\([[:print:][:space:]]*?\\)</div>" 1))

(defun gscholar-bibtex-acm-bibtex-urls (buffer-content)
  (mapcar
   (lambda (href)
     (let ((retval href)
           (case-fold-search t)
           (pair-list '(("coll=DL" . "expformat=bibtex")
                        ("id" . "parent_id")
                        ("\\." . "&id=")
                        ("cfm" . "downformats.cfm"))))
       (dolist (pair pair-list retval)
         (setq retval
               (replace-regexp-in-string (car pair) (cdr pair) retval)))))
   (gscholar-bibtex-re-search
    buffer-content
    "<A HREF=\"citation\.\\(.*?\\)\"" 1)))

(defun gscholar-bibtex-acm-bibtex-content (bibtex-url)
  (gscholar-bibtex--url-retrieve-as-string
   (concat "http://dl.acm.org/" bibtex-url)))

;;; ieee
(defun gscholar-bibtex-ieee-search-results (query)
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          `(("Content-Type" . "application/json;charset=utf-8")
            ("Accept" . "application/json, text/plain, */*")
            ("Referer" .
             ,(format "http://ieeexplore.ieee.org/search/searchresult.jsp?newsearch=true&queryText=%s"
                      (url-hexify-string query)))))
         (url-request-data (format "{\"queryText\":\"%s\",\"newsearch\":\"true\"}" query)))
    (with-current-buffer
        (gscholar-bibtex--url-retrieve-as-buffer "http://ieeexplore.ieee.org/rest/search")
      (goto-char (point-min))
      (assoc-default 'records (json-read)))))

(defun gscholar-bibtex-ieee-titles (records)
  (mapcar (lambda (record) (replace-regexp-in-string "\\(\\[::\\)\\|\\(::\\]\\)" ""
                                                 (assoc-default 'title record)))
          records))

(defun gscholar-bibtex-ieee-subtitles (records)
  (mapcar (lambda (record)
            (concat
             (mapconcat
              (lambda (x) (assoc-default 'preferredName x))
              (assoc-default 'authors record) "; ")
             " -- "
             (assoc-default 'publicationTitle record)))
          records))

(defun gscholar-bibtex-ieee-bibtex-urls (records)
  (mapcar (lambda (record) (assoc-default 'articleNumber record)) records))

(defun gscholar-bibtex-ieee-bibtex-content (bibtex-id)
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/x-www-form-urlencoded")))
         (url-request-data
          (mapconcat (lambda (arg)
                       (concat (url-hexify-string (car arg))
                               "="
                               (url-hexify-string (cdr arg))))
                     `(("recordIds" . ,bibtex-id)
                       ("citations-format" . "citation-only")
                       ("download-format" . "download-bibtex"))
                     "&"))
         (pair-list '(("<br>\\|\r" . "")
                      ("\n\n+" . "\n")
                      ("\n *" . "\n  ")))
         (retval (gscholar-bibtex--url-retrieve-as-string
                  "http://ieeexplore.ieee.org/xpl/downloadCitations")))
    (dolist (pair pair-list retval)
      (setq retval (replace-regexp-in-string (car pair) (cdr pair) retval)))))

;;; Google Scholar
(defun gscholar-bibtex-google-scholar-search-results (query)
  (let* ((url-request-method "GET")
         (system-time-locale "C")
         ;; Fabricate a cookie with a random ID that expires in an hour.
         (random-id (format "%016x" (random (expt 16 16))))
         (expiration (format-time-string "%a, %d %b %Y %H:%M:%S.00 %Z"
                                         (time-add (current-time)
                                                   (seconds-to-time 3600)) t))
         (my-cookie (mapconcat #'identity
                               (list (format "GSP=ID=%s:CF=4" random-id)
                                     (format "expires=%s" expiration)
                                     "path=/"
                                     "domain=scholar.google.com")
                               "; "))
         (url-current-object
          (url-generic-parse-url "http://scholar.google.com")))
    (url-cookie-handle-set-cookie my-cookie)
    (gscholar-bibtex--url-retrieve-as-string
     (concat "https://scholar.google.com/scholar?q="
             ;; To prepare the query string, we need to:
             ;; 1. Remove some extraneous puncutation.
             ;; 2. Hex-encode it.
             ;; 3. Convert encoded spaces to +
             ;; If we encode spaces as + first, url-hexify-string
             ;; hex-encodes the + symbols, and they are not interpreted
             ;; properly as spaces on the server.
             (replace-regexp-in-string "%20" "\+"
                                       (url-hexify-string
                                        (replace-regexp-in-string "[:,]" "" query)))))))

(defun gscholar-bibtex-google-scholar-bibtex-urls (buffer-content)
  (gscholar-bibtex-re-search buffer-content "\\(/scholar\.bib.*?\\)\"" 1))

(defun gscholar-bibtex-google-scholar-titles (buffer-content)
  (gscholar-bibtex-re-search buffer-content "<div class=\"gs_ri\"><h3.*?>\\(.*?\\)</h3>" 1))

(defun gscholar-bibtex-google-scholar-subtitles (buffer-content)
  (gscholar-bibtex-re-search
   buffer-content
   "<div class=\"gs_a\">\\(.*?\\)</div>" 1))

(defun gscholar-bibtex-google-scholar-bibtex-content (bibtex-url)
  (gscholar-bibtex--url-retrieve-as-string
   (concat "https://scholar.google.com" bibtex-url)))

;;; DBLP
(defun gscholar-bibtex-dblp-search-results (query)
  (let* ((url-request-method "GET")
         (response-buffer (gscholar-bibtex--url-retrieve-as-buffer
                           (concat "http://dblp.uni-trier.de/search/publ/api?"
                                   (url-build-query-string
                                    `((q ,query)
                                      (format xml)))))))
    (with-current-buffer response-buffer
      (set-buffer-multibyte t))
    (prog1
        (pcase-let ((`(,(and result `(result . ,_))) (xml-parse-region nil nil response-buffer)))
          (mapcar (lambda (hit)
                    (gscholar-bibtex--xml-get-child hit 'info))
                  (xml-get-children (gscholar-bibtex--xml-get-child result 'hits) 'hit)))
      (kill-buffer response-buffer))))

(defun gscholar-bibtex-dblp-titles (search-results)
  (mapcar (lambda (info)
            (gscholar-bibtex--xml-node-child
             (gscholar-bibtex--xml-get-child info 'title)))
          search-results))

(defun gscholar-bibtex-dblp-subtitles (search-results)
  (mapcar (lambda (info)
            (mapconcat #'gscholar-bibtex--xml-node-child
                       (xml-get-children (gscholar-bibtex--xml-get-child info 'authors) 'author)
                       ", "))
          search-results))

(defun gscholar-bibtex-dblp-bibtex-urls (search-results)
  (mapcar (lambda (info)
            (gscholar-bibtex--xml-node-child
             (gscholar-bibtex--xml-get-child info 'url)))
          search-results))

(defun gscholar-bibtex-dblp-bibtex-content (html-url)
  (string-match "/rec/" html-url)
  (gscholar-bibtex--url-retrieve-as-string
   (replace-match "/rec/bib2/" t t html-url)))

;;;###autoload
(defun gscholar-bibtex-turn-on-sources ()
  (interactive)
  (gscholar-bibtex--source-on-off-interactive-impl :on))

;;;###autoload
(defun gscholar-bibtex-turn-off-sources ()
  (interactive)
  (gscholar-bibtex--source-on-off-interactive-impl :off))

(defun gscholar-bibtex-select-source ()
  (if (= 1 (length gscholar-bibtex-enabled-sources))
      (setq gscholar-bibtex-selected-source
            (caar gscholar-bibtex-enabled-sources))
    (let* ((default-source (assoc
                            gscholar-bibtex-default-source
                            gscholar-bibtex-enabled-sources))
           (source-prompt (if default-source
                              (concat "Select a source[default "
                                      gscholar-bibtex-default-source
                                      "]: ")
                            "Select a source: "))
           (selected-source
            (completing-read source-prompt
                             gscholar-bibtex-enabled-sources)))
      (setq gscholar-bibtex-selected-source
            (if (string= "" selected-source)
                gscholar-bibtex-default-source
              selected-source))))
  (if (not (assoc gscholar-bibtex-selected-source
		  gscholar-bibtex-enabled-sources))
      (error "Please select an installed source!")
    gscholar-bibtex-selected-source))

;;;###autoload
(defun gscholar-bibtex (&optional source query)
  "Look up on a bibliographic SOURCE such as Google Scholar for the given QUERY.
When called interactively, prompts for SOURCE and QUERY string.
Can be called programmatically with SOURCE (to prompt for QUERY
only or SOURCE and QUERY for non-interactive lookup."
  (interactive)
  (setq gscholar-bibtex-selected-source (or source (gscholar-bibtex-select-source)))
  (let* ((query (or query (read-string
			   (concat "Query[" gscholar-bibtex-selected-source "]: "))))
         (search-results (gscholar-bibtex-dispatcher :search-results query))
         (titles (gscholar-bibtex-dispatcher :titles search-results))
         (subtitles (gscholar-bibtex-dispatcher :subtitles search-results))
         (gscholar-buffer
          (get-buffer-create gscholar-bibtex-result-buffer-name)))
    (setq gscholar-bibtex-caller-buffer (current-buffer))
    (setq gscholar-bibtex-urls-cache
          (gscholar-bibtex-dispatcher :bibtex-urls search-results))
    (setq gscholar-bibtex-entries-cache
          (make-vector (length gscholar-bibtex-urls-cache) ""))
    (pop-to-buffer gscholar-buffer)
    (setq buffer-read-only nil)
    (erase-buffer)
    (goto-char (point-min))
    (dotimes (i (length titles))
      (insert (gscholar-bibtex-prettify-title (concat "* " (nth i titles))))
      (newline-and-indent)
      (insert "  "
              (gscholar-bibtex-prettify-subtitle (nth i subtitles)) "\n\n"))
    (goto-char (point-min))
    (gscholar-bibtex-mode)
    (gscholar-bibtex-show-help)))

;; install sources
(gscholar-bibtex-install-source "DBLP" 'dblp)
(gscholar-bibtex-install-source "IEEE Xplore" 'ieee)
(gscholar-bibtex-install-source "ACM Digital Library" 'acm)
(gscholar-bibtex-install-source "Google Scholar" 'google-scholar)
;; initalize
(setq gscholar-bibtex-disabled-sources gscholar-bibtex-available-sources)
;; enable all
(gscholar-bibtex-source-on-off :on "DBLP")
(gscholar-bibtex-source-on-off :on "IEEE Xplore")
(gscholar-bibtex-source-on-off :on "ACM Digital Library")
(gscholar-bibtex-source-on-off :on "Google Scholar")

;; Remove byte compilation warnings
(defvar evil-emacs-state-modes)
(eval-after-load "evil"
  '(add-to-list 'evil-emacs-state-modes 'gscholar-bibtex-mode))

(provide 'gscholar-bibtex)
;;; gscholar-bibtex.el ends here
