;;; helm-dictionary.el --- Helm source for looking up dictionaries

;; Copyright 2013 Titus von der Malsburg <malsburg@posteo.de>

;; Author: Titus von der Malsburg <malsburg@posteo.de>
;;         Michael Heerdegen <michael_heerdegen@web.de>
;; Maintainer: Titus von der Malsburg <malsburg@posteo.de>
;; URL: https://github.com/emacs-helm/helm-dictionary
;; Package-Version: 20201006.1511
;; Package-Commit: b316a1d55e58645d59a84d33851d46fab3cd54b5
;; Version: 1.0.0
;; Package-Requires: ((helm "1.5.5"))

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

;; This helm source can be used to look up words in local (offline)
;; dictionaries.  It also provides short-cuts for various online
;; dictionaries, which is useful in situations where the local
;; dictionary doesn't have an entry for a word.
;;
;; Dictionaries are available for a variety of language pairs.  See
;; the project page for an incomplete list:
;;
;;     https://github.com/emacs-helm/helm-dictionary

;;; Install:

;; Put this file on your Emacs-Lisp load path and add the following in
;; your Emacs startup file:
;;
;;     (require 'helm-dictionary)
;;
;; Alternatively, you can use autoload:
;;
;;     (autoload 'helm-dictionary "helm-dictionary" "" t)
;;
;; In order to specify a dictionary set the variable
;; `helm-dictionary-database' to the filename of that dictionary.
;;
;; A dictionary for German and English can be found in the Debian
;; package trans-de-en.  This package is also available in many
;; distributions derived from Debian such as Ubuntu.  Alternatively,
;; this dictionary can also be downloaded here:
;; 
;;   http://www-user.tu-chemnitz.de/~fri/ding/
;;
;; A dictionary for German and Spanish can be found here:
;;
;;   https://savannah.nongnu.org/projects/ding-es-de
;;
;; A variety of dictionaries with English as the source or target
;; language can be found here:
;;
;;   https://en.wiktionary.org/wiki/User:Matthias_Buchmeier
;;
;; These dictionaries were automatically created from the Wiktionary
;; database.  Their size and quality may vary.  Also generated from
;; Wiktionary are the following dictionaries with Russian as the
;; source or target language:
;;
;;   http://wiktionary-export.nataraj.su/en/
;;
;; If the local dictionary doesn't have an entry for a word, it can be
;; useful to try online dictionaries available on the
;; web.  Helm-dictionary has a dummy source that provides shortcuts
;; for looking up the currently entered string in these online
;; dictionaries.  The variable `helm-dictionary-online-dicts'
;; specifies which online dictionaries should be listed.  The value of
;; that variable is a list conses.  The first element of each cons
;; specifies the name of an online dictionary for display during
;; searches.  The second element is the URL used for retrieving search
;; results from the respective dictionary.  This URL has to contain a
;; "%s" at the position where the search term should be inserted.
;;

;; The browser specified in `helm-dictionary-browser-function' will be
;; used to show results from online dictionaries.  If this variable is
;; nil (default), the value of the variable
;; `browse-url-browser-function' will be used (the currently
;; configured Emacs-wide default browser).  If that variable is also
;; nil, helm uses the first available browser in
;; `helm-browse-url-default-browser-alist'.

;;; Usage:

;; Use the command `helm-dictionary' to start a new search.  As usual,
;; a search is case-insensitive unless the expression contains capital
;; letters.  Regular expressions can also be used as search
;; terms.  During a search, you can use `M-n` to search for the word
;; at which you called `helm-dictionary`.

;; There are two actions available: insert the currently selected term
;; in the source language (left) or in the target language (right) at
;; point, i.e., the cursor position at which `helm-dictionary' was
;; called.

;; In the section "Look up online", you can choose among several online
;; dictionaries.  If you select one of the entries listed in this
;; section, a browser will be used to display search results from the
;; respective dictionary.

;;; Code:

(require 'cl-lib)
(require 'helm)
(require 'helm-net)
(require 'helm-easymenu)

(defgroup helm-dictionary nil
  "Helm plugin for looking up a dictionary."
  :group 'helm)

(defcustom helm-dictionary-database "/usr/share/trans/de-en"
  "The file containing the dictionary, or an alist of offline
dictionaries where the key of each entry is the name of the
dictionary and the value is the file."
  :group 'helm-dictionary
  :type  '(choice
           (file)
           (alist :key-type string :value-type: file)))

(defcustom helm-dictionary-online-dicts
  '(("translate.reference.com de->eng" .
     "http://translate.reference.com/translate?query=%s&src=de&dst=en")
    ("translate.reference.com eng->de" .
     "http://translate.reference.com/translate?query=%s&src=en&dst=de")
    ("Leo eng<->de" .
     "http://dict.leo.org/ende?lp=ende&lang=de&search=%s")
    ("en.wiktionary.org" . "http://en.wiktionary.org/wiki/%s")
    ("de.wiktionary.org" . "http://de.wiktionary.org/wiki/%s")
    ("Linguee eng<->de" . "http://www.linguee.de/deutsch-englisch/search\
?sourceoverride=none&source=auto&query=%s"))
  "Alist of online dictionaries.  The key of each entry is the
name of the online dictionary.  The value is the URL used for
retrieving results.  This URL must contain a %s at the position
where the search term should be inserted."
  :group 'helm-dictionary
  :type '(alist :key-type string :value-type string))

(defcustom helm-dictionary-browser-function nil
  "The browser that is used to access online dictionaries.  If
nil (default), the value of `browse-url-browser-function' is
used.  If that value is nil, Helm uses the first available
browser in `helm-browse-url-default-browser-alist'"
  :group 'helm-dictionary
  :type '(choice
          (const         :tag "Default" :value nil)
          (function-item :tag "Emacs W3" :value  browse-url-w3)
          (function-item :tag "W3 in another Emacs via `gnudoit'"
                         :value  browse-url-w3-gnudoit)
          (function-item :tag "Mozilla" :value  browse-url-mozilla)
          (function-item :tag "Firefox" :value browse-url-firefox)
          (function-item :tag "Chromium" :value browse-url-chromium)
          (function-item :tag "Galeon" :value  browse-url-galeon)
          (function-item :tag "Epiphany" :value  browse-url-epiphany)
          (function-item :tag "Netscape" :value  browse-url-netscape)
          (function-item :tag "eww" :value  eww-browse-url)
          (function-item :tag "Text browser in an xterm window"
                         :value browse-url-text-xterm)
          (function-item :tag "Text browser in an Emacs window"
                         :value browse-url-text-emacs)
          (function-item :tag "KDE" :value browse-url-kde)
          (function-item :tag "Elinks" :value browse-url-elinks)
          (function-item :tag "Specified by `Browse Url Generic Program'"
                         :value browse-url-generic)
          (function-item :tag "Default Windows browser"
                         :value browse-url-default-windows-browser)
          (function-item :tag "Default Mac OS X browser"
                         :value browse-url-default-macosx-browser)
          (function-item :tag "GNOME invoking Mozilla"
                         :value browse-url-gnome-moz)
          (function-item :tag "Default browser"
                         :value browse-url-default-browser)
          (function      :tag "Your own function")
          (alist         :tag "Regexp/function association list"
                         :key-type regexp :value-type function)))

(easy-menu-add-item nil '("Tools" "Helm" "Tools") ["Dictionary" helm-dictionary t])


;; The function `window-width' does not necessarily report the correct
;; number of characters that fit on a line.  This is a
;; work-around.  See also this bug report:
;; http://debbugs.gnu.org/cgi/bugreport.cgi?bug=19395
(defun helm-dictionary-window-width ()
  (if (and (not (featurep 'xemacs))
           (display-graphic-p)
           overflow-newline-into-fringe
           (/= (frame-parameter nil 'left-fringe) 0)
           (/= (frame-parameter nil 'right-fringe) 0))
      (window-body-width)
    (1- (window-body-width))))

(defun helm-dictionary-transformer (candidates)
  "Formats entries retrieved from the data base."
  (cl-loop for i in candidates
           with entry and l1terms and l2terms
           and width = (with-helm-window (helm-dictionary-window-width))
           with left-col-width = (1- (/ width 2))
           with right-col-width = (- width (/ width 2))
           unless (or (string-match "\\`#" i)
                      (not (string-match " :: ?" i)))
           do (progn (setq entry (split-string i " :: ?"))
                     (setq l1terms (split-string (car entry) " | "))
                     (setq l2terms (split-string (cadr entry) " | ")))
           and append
           (cl-loop for l1term in l1terms
                    for l2term in l2terms
                    if (or (string-match helm-pattern l1term)
                           (string-match helm-pattern l2term))
                    collect
                    (cons 
                     (concat
                      (truncate-string-to-width l1term left-col-width 0 ?\s)
                      " "
                      (truncate-string-to-width l2term right-col-width 0 ?\s))
                     (cons l1term l2term)))))


(defun helm-dictionary-insert-l1term (entry)
  (insert
    (replace-regexp-in-string
      " *{.+}\\| *\\[.+\\]" "" (car entry))))

(defun helm-dictionary-insert-l2term (entry)
  (insert
    (replace-regexp-in-string
      " *{.+}\\| *\\[.+\\]" "" (cdr entry))))

(defun helm-dictionary-build (name file)
  (helm-build-in-file-source name file
    :candidate-transformer 'helm-dictionary-transformer
    :action '(("Insert source language term" . helm-dictionary-insert-l1term)
              ("Insert target language term" . helm-dictionary-insert-l2term))))


(defvar helm-source-dictionary-online
  (helm-build-sync-source "Look up online"
    :match (lambda (_candidate) t)
    :candidates helm-dictionary-online-dicts
    :multimatch nil
    :nohighlight t
    :action (lambda (cand)
              (let ((browse-url-browser-function
                     (or helm-dictionary-browser-function
                         browse-url-browser-function)))
                (helm-browse-url (format cand (url-hexify-string helm-pattern))))))
  "Source for online look-up.")

;;;###autoload
(defun helm-dictionary ()
  (interactive)
  (let ((helm-source-dictionary
         (mapcar
          (lambda (x) (helm-dictionary-build (car x) (cdr x)))
          (if (stringp helm-dictionary-database)
              (list (cons "Search dictionary" helm-dictionary-database))
            helm-dictionary-database)))
        (input (thing-at-point 'word)))
    (helm :sources (append helm-source-dictionary (list helm-source-dictionary-online))
          :full-frame t
          :default input
          :candidate-number-limit 500
          :buffer "*helm dictionary*")))

(provide 'helm-dictionary)

;; Local Variables:
;; byte-compile-warnings: (not cl-functions obsolete)
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; helm-dictionary.el ends here
