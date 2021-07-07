;;; pinboard-popular.el --- Displays links from the pinboard.in popular page.
;; -*- lexical-binding: t; -*-

;; Adam Simpson <adam@adamsimpson.net>
;; Version: 0.1.2
;; Package-Version: 20180511.1726
;; Package-Commit: c0bc76cd35f8ecf34723c64a702b82eec2751318
;; Package-Requires: ((loop "1.4"))
;; Keywords: pinboard
;; URL: https://github.com/asimpson/pinboard-popular

;;; Commentary:
;; Easily filter and open links from pinboard.in popular page.

;;; Code:
(require 'url)
(require 'loop)

(defun pinboard-popular--re-capture-between(re-start re-end)
  "Return the string between two regexes."
  (let (start end)
    (setq start (re-search-forward re-start))
    (setq end (re-search-forward re-end))
    (buffer-substring-no-properties start end)))

;;;###autoload
(defun pinboard-popular()
  "Download and parse the pinboard.in/popular page."
  (interactive)
  (let ((url "https://pinboard.in/popular/"))
    (url-retrieve url (lambda(_)
                        (let (links link title selection)
                          (keep-lines "bookmark_title" (point-min) (point-max))
                          (loop-for-each-line (progn
                                                (unless (= (point) (point-max))
                                                  (setq link (substring (pinboard-popular--re-capture-between "href=\"" "\"") 0 -1))
                                                  (setq title (decode-coding-string (substring (pinboard-popular--re-capture-between ">" "<") 0 -1) 'utf-8))
                                                  (push (propertize title 'url link) links))))

                          (setq selection (completing-read "Pinboard popular: " (reverse links) nil t))
                          (browse-url (get-text-property 0 'url (car (seq-filter (lambda(x) (string= (substring-no-properties x) selection)) links)))))))))

(provide 'pinboard-popular)

;;; pinboard-popular.el ends here
