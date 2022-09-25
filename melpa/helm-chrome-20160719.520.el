;;; helm-chrome.el --- Helm interface for Chrome bookmarks -*- lexical-binding: t -*-

;; Filename: helm-chrome.el
;; Description: Helm interface for Chrome bookmarks
;; Author: KAWABATA, Taichi <kawabata.taichi_at_gmail.com>
;; Created: 2013-12-25
;; Version: 1.151223
;; Package-Version: 20160719.520
;; Package-Commit: fd630ace4b4b4f33355a973743bbfe0c90ce4830
;; Package-Requires: ((helm "1.5") (cl-lib "0.3") (emacs "24"))
;; Keywords: tools
;; Human-Keywords: chrome bookmarks
;; URL: https://github.com/kawabata/helm-chrome

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

;; Helm interface for Chrome bookmarks.
;;
;; Warning: Multiple bookmarks with the same name will be overridden.
;; This restriction is for better performance.  If we use Bookmark IDs with
;; candidate-transformer, then the speed would be quite slow.
;;
;; It's also possible to scan through urls of the bookmarks.
;; To do so one need to customize helm-chrome-use-urls variable
;; for the helm-chrome group or just set it's value in config file:
;; (setq helm-chrome-use-urls t).
;; Then reload bookmarks using function helm-chrome-reload-bookmarks.
;;
;; Warning: On a big number of bookmark it may be quite slow.

;;; Code:

(require 'helm)
(require 'cl-lib)
(require 'json)

(defgroup helm-chrome nil
  "Helm interface for Chrome Bookmarks."
  :group 'helm)

(defcustom helm-chrome-file
  (car
   (cl-delete-if-not
    'file-exists-p
    `("~/Library/Application Support/Google/Chrome/Default/Bookmarks"
      "~/AppData/Local/Google/Chrome/User Data/Default/Bookmarks"
      "~/.config/google-chrome/Default/Bookmarks"
      "~/.config/chromium/Default/Bookmarks"
      ,(substitute-in-file-name
        "$LOCALAPPDATA/Google/Chrome/User Data/Default/Bookmarks")
      ,(substitute-in-file-name
        "$USERPROFILE/Local Settings/Application Data/Google/Chrome/User Data/Default/Bookmarks")
      )))
  "The bookmark file for Chrome."
  :group 'helm-chrome
  :type 'file)

(defcustom helm-chrome-use-urls nil
  "Use bookmark urls as source of the data for helm"
  :group 'helm-chrome
  :type 'boolean)

(defvar helm-chrome--json nil)
(defvar helm-chrome--bookmarks nil)

(defun helm-chrome--add-bookmark (json)
  "Add bookmarks from JSON."
  (when (and (listp json) (listp (cdr json)))
    (cond
     ((assoc 'roots json)
      (dolist (item (cdr (assoc 'roots json)))
        (helm-chrome--add-bookmark item)))
     ((equal (cdr (assoc 'type json)) "folder")
      (cl-loop for item across (cdr (assoc 'children json))
               do (helm-chrome--add-bookmark item)))
     ((equal (cdr (assoc 'type json)) "url")
      (let ((helm-chrome-name
             (if (and helm-chrome-use-urls
                      (string-prefix-p  "http" (cdr (assoc 'url json))) t)
                 (concat (cdr (assoc 'name json)) " [" (cdr (assoc 'url json)) "]")
               (cdr (assoc 'name json)))))
        (puthash
         helm-chrome-name
         (cdr (assoc 'url json))
         helm-chrome--bookmarks)))
     )))


(defun helm-chrome-reload-bookmarks ()
  "Reload Chrome bookmarks."
  (interactive)
  (unless (file-exists-p helm-chrome-file)
    (error "File %s does not exist" helm-chrome-file))
  (setq helm-chrome--json (json-read-file helm-chrome-file))
  (setq helm-chrome--bookmarks (make-hash-table :test 'equal))
  (helm-chrome--add-bookmark helm-chrome--json))

(defvar helm-chrome-source
  (helm-build-in-buffer-source "Chrome::Bookmarks"
    :init (lambda () (unless helm-chrome--json
                       (helm-chrome-reload-bookmarks)))
    :data (lambda ()
            (cl-loop for name being the hash-keys of helm-chrome--bookmarks
                     collect name))
    :candidate-number-limit 9999
    :coerce (lambda (candidate) (gethash candidate helm-chrome--bookmarks))
    :action '(("Browse URL(s)" . (lambda (_candidate)
                                   (mapc #'browse-url (helm-marked-candidates))))
              ("Show URL" . message))))

;;;###autoload
(defun helm-chrome-bookmarks ()
  "Search Chrome Bookmark using `helm'."
  (interactive)
  (helm :sources 'helm-chrome-source
        :prompt "Find Bookmark: "
        :buffer "*helm chrome bookmarks*"))

(provide 'helm-chrome)

;;; helm-chrome.el ends here

;; Local Variables:
;; time-stamp-pattern: "10/Version:\\\\?[ \t]+1.%02y%02m%02d\\\\?\n"
;; End:
