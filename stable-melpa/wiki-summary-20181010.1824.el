;;; wiki-summary.el --- View Wikipedia summaries in Emacs easily.

;; Copright (C) 2015 Danny Gratzer <jozefg@cmu.edu>

;; Author: Danny Gratzer
;; URL: https://github.com/jozefg/wiki-summary.el
;; Package-Version: 20181010.1824
;; Package-Commit: fa41ab6e50b3b80e54148af9d4bac18fd0405000
;; Keywords: wikipedia, utility
;; Package-Requires: ((emacs "24"))
;; Version: 0.1

;;; Commentary:

;; It's often the case when reading some document in Emacs (be it
;; code text or prose) that I come across a word or phrase that I
;; don't know. In order to simplify my feedback loop when wiki-summary
;; lets me look up something in a couple seconds.
;;
;; To use this package, simply call M-x wiki-summary (or bind it to a key).
;; This will prompt you for an article title to search. For convience,
;; this will default to the word under the point. When you hit enter
;; this will query Wikipedia and if an article is found, bring up the
;; title in a separate window. Spaces will be properly escaped so
;; something like "Haskell (programming language)" will bring up the
;; intended page.
;;
;; I'm not sure exactly what else people would want out of this package.
;; Feature request issues are welcome.

(require 'url)
(require 'json)
(require 'thingatpt)

(eval-when-compile
  ; This stops the compiler from complaining.
  (defvar url-http-end-of-headers))

(defcustom wiki-summary-language-string "en"
  "Language string for the API URL call, i.e.: 'en', 'fr', etc.")

(defvar wiki--pre-url-format-string
  "https://%s.wikipedia.org/w/api.php?continue=&action=query&titles=")

(defvar wiki--post-url-format-string
  "&prop=extracts&exintro=&explaintext=&format=json&redirects")

;;;###autoload
(defun wiki-summary/make-api-query (s)
  "Given a wiki page title, generate the url for the API call
   to get the page info"
  (let ((pre (format wiki--pre-url-format-string wiki-summary-language-string))
        (post wiki--post-url-format-string)
        (term (url-hexify-string (replace-regexp-in-string " " "_" s))))
    (concat pre term post)))

;;;###autoload
(defun wiki-summary/extract-summary (resp)
  "Given the JSON reponse from the webpage, grab the summary as a string"
  (let* ((query (plist-get resp 'query))
         (pages (plist-get query 'pages))
         (info (cadr pages)))
    (plist-get info 'extract)))

;;;###autoload
(defun wiki-summary/format-summary-in-buffer (summary)
  "Given a summary, stick it in the *wiki-summary* buffer and display the buffer"
  (let ((buf (generate-new-buffer "*wiki-summary*")))
    (with-current-buffer buf
      (princ summary buf)
      (fill-paragraph)
      (goto-char (point-min))
      (text-mode)
      (view-mode))
    (pop-to-buffer buf)))

;;;###autoload
(defun wiki-summary/format-summary-into-buffer (summary buffer)
  "Given a summary, stick it in the *wiki-summary* buffer and display the buffer"
  (let ((this-buffer (get-buffer buffer)))
    (with-current-buffer (get-buffer this-buffer)
      (barf-if-buffer-read-only)
      (insert summary)
      (fill-paragraph))
    (display-buffer (get-buffer this-buffer))))

;;;###autoload
(defun wiki-summary (s)
  "Return the wikipedia page's summary for a term"
  (interactive
   (list
    (read-string (concat
                  "Wikipedia Article"
                  (if (thing-at-point 'word)
                      (concat " (" (thing-at-point 'word) ")")
                    "")
                  ": ")
                 nil
                 nil
                 (thing-at-point 'word))))
  (save-excursion
    (url-retrieve (wiki-summary/make-api-query s)
       (lambda (events)
         (message "") ; Clear the annoying minibuffer display
         (goto-char url-http-end-of-headers)
         (let ((json-object-type 'plist)
               (json-key-type 'symbol)
               (json-array-type 'vector))
           (let* ((result (json-read))
                  (summary (wiki-summary/extract-summary result)))
             (if (not summary)
                 (message "No article found")
               (wiki-summary/format-summary-in-buffer summary))))))))

;;;###autoload
(defun wiki-summary-insert (s)
  "Return the wikipedia page's summary for a term"
  (interactive
   (list
    (read-string (concat
                  "Wikipedia Article"
                  (if (thing-at-point 'word)
                      (concat " (" (thing-at-point 'word) ")")
                    "")
                  ": ")
                 nil
                 nil
                 (thing-at-point 'word))))
  (save-excursion
    (url-retrieve
     (wiki-summary/make-api-query s)
     (lambda (events buf)
       (message "") ; Clear the annoying minibuffer display
       (goto-char url-http-end-of-headers)
       (let ((json-object-type 'plist)
             (json-key-type 'symbol)
             (json-array-type 'vector))
         (let* ((result (json-read))
                (summary (wiki-summary/extract-summary result)))
           (if (not summary)
               (message "No article found")
             (wiki-summary/format-summary-into-buffer summary buf)))))
     (list (buffer-name (current-buffer))))))

(provide 'wiki-summary)

;;; wiki-summary.el ends here

