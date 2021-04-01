;;; helm-firefox.el --- Firefox bookmarks -*- lexical-binding: t -*-

;; Copyright (C) 2012 ~ 2015 Thierry Volpiatto <thierry.volpiatto@gmail.com>

;; Version: 1.1
;; Package-Version: 20210331.1900
;; Package-Commit: 58a7ff023c76857ca9cd82075c8743446a50c055
;; Package-Requires: ((helm "1.5") (cl-lib "0.5") (emacs "24.1"))
;; URL: https://github.com/emacs-helm/helm-firefox

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


;;; Code:
(require 'cl-lib)
(require 'helm)
(require 'helm-utils)
(require 'helm-adaptive)
(require 'helm-net)


(defgroup helm-firefox nil
  "Helm libraries and applications for Firefox navigator."
  :group 'helm)

(defvar helm-firefox-bookmark-url-regexp "\\(https\\|http\\|ftp\\|about\\|file\\)://[^ \"]*")
(defvar helm-firefox-bookmarks-regexp ">\\([^><]+.\\)</[aA]>")

(defface helm-firefox-title
    '((t (:inherit 'font-lock-type-face)))
  "Face used for firefox bookmark titles."
  :group 'helm-firefox)

(defun helm-get-firefox-user-init-dir (directory)
  "Guess the default Firefox user directory name."
  (with-temp-buffer
    (insert-file-contents
     (expand-file-name "profiles.ini" directory))
    (goto-char (point-min))
    (prog1
        (cl-loop with dir
                 with atime = 0
                 while (re-search-forward "Path=" nil t)
                 for tmpdir = (expand-file-name
                               (buffer-substring-no-properties
                                (point) (point-at-eol))
                               directory)
                 for bmkfile = (expand-file-name "bookmarks.html" tmpdir)
                 for at = (if (file-exists-p bmkfile)
                              (float-time (nth 5 (file-attributes bmkfile)))
                            (max atime 0))
                 when (> at atime)
                 do (setq dir tmpdir
                          atime at)
                 finally return (file-name-as-directory
                                 (expand-file-name
                                  dir directory)))
      (kill-buffer))))

(defvar helm-firefox-bookmark-user-directory nil
  "The Firefox user directory.

This variable is set automatically by helm-firefox, you should not
have to modify it yourself.

Should be located in `helm-firefox-default-directory', you may have
several different directories there if you use different firefox
versions, if the default found by helm-firefox is not the one you want
to use, look at your \"profiles.ini\" file which profile you are
currently using, Firefox use by default the one of the recentest
Firefox installation, it is adviced to use Firefox sync instead of
changing this default value.")

(defcustom helm-firefox-default-directory "~/.mozilla/firefox/"
  "The root directory containing firefox config.
On Mac OS X, probably set to \"~/Library/Application Support/Firefox/\".

DO NOT use `setq' to configure this variable."
  :group 'helm-firefox
  :type 'string
  :set (lambda (var val)
         (set var val)
         (setq helm-firefox-bookmark-user-directory
               (helm-get-firefox-user-init-dir val))))

(defun helm-guess-firefox-bookmark-file ()
  "Return the path of the Firefox bookmarks file."
  (expand-file-name "bookmarks.html" helm-firefox-bookmark-user-directory))

(defvar helm-firefox-bookmarks-alist nil)
(defvar helm-source-firefox-bookmarks
  (helm-build-sync-source "Firefox Bookmarks"
    :init (lambda ()
            (setq helm-firefox-bookmarks-alist
                  (helm-html-bookmarks-to-alist
                   (helm-guess-firefox-bookmark-file)
                   helm-firefox-bookmark-url-regexp
                   helm-firefox-bookmarks-regexp)))
    :candidates (lambda ()
                  (cl-loop for (bmk . url) in helm-firefox-bookmarks-alist
                           collect (concat bmk "\n" url)))
    :multiline t
    :filtered-candidate-transformer
     '(helm-adaptive-sort
       helm-firefox-highlight-bookmarks)
    :action (helm-make-actions
             "Browse Url"
             (lambda (_candidate)
               (let ((urls (helm-marked-candidates)))
                 (cl-loop for cand in urls
                          do (helm-browse-url cand))))
             "Copy Url"
             (lambda (url)
               (kill-new url)
               (message "`%s' copied to kill-ring" url)))))

(defun helm-firefox-bookmarks-get-value (elm)
  (assoc-default elm helm-firefox-bookmarks-alist))

(defun helm-firefox-highlight-bookmarks (bookmarks _source)
  (cl-loop for bmk in bookmarks
           for split = (split-string bmk "\n")
           collect (cons (concat (propertize
                                  (car split)
                                  'face 'helm-firefox-title)
                                 "\n"
                                 (cadr split))
                         (cadr split))))

;;;###autoload
(defun helm-firefox-bookmarks ()
  "Preconfigured `helm' for firefox bookmark.
You will have to enable html bookmarks in firefox:
open \"about:config\" in firefox and double click on this line to enable value
to true:

user_pref(\"browser.bookmarks.autoExportHTML\", false);

You should have now:

user_pref(\"browser.bookmarks.autoExportHTML\", true);

After closing firefox, you will be able to browse your bookmarks."
  (interactive)
  (helm :sources `(helm-source-firefox-bookmarks
                   ,(helm-build-dummy-source "DuckDuckgo"
                     :action (lambda (candidate)
                               (helm-browse-url 
                                (format helm-surfraw-duckduckgo-url
                                        (url-hexify-string candidate))))))
        :truncate-lines t
        :buffer "*Helm Firefox*"))


(provide 'helm-firefox)

;; Local Variables:
;; byte-compile-warnings: (not cl-functions obsolete)
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; helm-firefox.el ends here
