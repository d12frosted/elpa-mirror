;;; counsel-chrome-bm.el --- Browse your Chrom(e/ium) bookmarks with Ivy -*- lexical-binding: t; -*-

;; Copyright (C) 2021  BlueBoxWare

;; Author: BlueBoxWare (BlueBoxWare@users.noreply.github.com)
;; Url: https://github.com/BlueBoxWare/counsel-chrome-bm
;; Package-Version: 20211018.1346
;; Package-Commit: 4d88ab0fcc5ecf463e953c63c5532a62701ead53
;; Version: 1.0.0
;; Package-Requires: ((emacs "25.1") (counsel "0.13.0"))
;; Keywords: hypermedia

;;; License:

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
;;
;;   Soft requirement: jq (URL <https://stedolan.github.io/jq/>).
;;   Counsel-chrome-bm will work without jq, but it will be slow when you have
;;   a lot of bookmarks.
;;
;; This package provides the commands `counsel-chrome-bm' and
;; `counsel-chrome-bm-all', which allow you to browse your Chrome bookmarks
;; with `ivy'.  Chromium and many Chromium-based browser are supported too.
;; Use `counsel-chrome-bm-file' to specify your bookmarks file if it is
;; not auto-detected.
;;
;; By default jq will be used if available.  Set `counsel-chrome-bm-jq' to the
;; executable of jq if jq is not on the PATH.  If jq is not available the
;; package will fall back to using Emacs' JSON parsing.  This will be done
;; synchronous and might be slow if you have a lot of bookmarks, but on the
;; other hand it allows for fuzzy searching, which using jq does not.  If you
;; don't want to use jq even when available, set `counsel-chrome-bm-no-jq' to t.
;;
;; Known supported browsers are: Chrome, Chromium, Vivaldi, Edge and Brave.
;; Known not working browsers are: Opera.

;;; Code:

(require 'seq)
(require 'ivy)
(require 'counsel)
(require 'json)

;;;
;;; Settings
;;;

(defgroup counsel-chrome-bm nil
  "Counsel interface for Chrome bookmarks."
  :group 'counsel
  :prefix "counsel-chrome-bm-")

(defcustom counsel-chrome-bm-jq nil
  "Path to jq (URL <https://stedolan.github.io/jq/>) if jq is not on the PATH."
  :type 'file)

(defcustom counsel-chrome-bm-file
  (seq-find #'file-readable-p
            (mapcar
             (lambda (p)
               (substitute-in-file-name (concat p "/Default/Bookmarks")))
             '("~/.config/google-chrome"
               "~/.config/chromium"
               "$LOCALAPPDATA/Google/Chrome/User Data"
               "$LOCALAPPDATA/Chromium/User Data"
               "$USERPROFILE/Local Settings/Application Data/Google/Chrome/User Data"
               "$USERPROFILE/Local Settings/Application Data/Chromium/User Data"
               "$LOCALAPPDATA/Microsoft/Edge/User Data"
               "$USERPROFILE/Local Settings/Application Data/Microsoft/Edge/User Data"
               "~/Library/Application Support/Google/Chrome"
               "~/Library/Application Support/Chromium"
               "~/.config/vivaldi"
               "$LOCALAPPDATA/Vivaldi/User Data"
               "$USERPROFILE/Local Settings/Application Data/Vivaldi/User Data"
               "~/Library/Application Support/Vivaldi")))
  "The bookmarks file to use."
  :type 'file)

(defcustom counsel-chrome-bm-ignore-key '("trash")
  "List of keys of the 'roots' object to ignore.
A list of keys of the 'roots' object in the bookmarks file which should be
ignored by `counsel-chrome-bm'.  Case-sensitive.

Bookmarks under these keys and any of their folders will not be included.

Standard keys in a Chrome bookmark file are 'bookmark_bar', 'synced' and
'other'.  Some Chromium based browsers add additional keys.

The default is '(\"trash\"): the \"trash\" key is used by Vivaldi to store
deleted bookmarks.  We don't use `counsel-chrome-bm-ignore-folder' for this
because the name of the folder is localized."
  :type '(list string))

(defcustom counsel-chrome-bm-ignore-folder '()
  "A list of folder names (strings) to ignore by `counsel-chrome-bm'.
Case-sensitive.  Bookmarks in these folders and any subfolders will not be
included."
  :type '(list string))

(defcustom counsel-chrome-bm-url-prefix " - "
  "String to print before the URL of a bookmark starts."
  :type 'string)

(defcustom counsel-chrome-bm-url-suffix ""
  "String to print after the URL of the bookmark."
  :type 'string)

(defcustom counsel-chrome-bm-default-action nil
  "The default action to execute when selecting a bookmark.
Must be a function which will receive two string arguments.  The first is the
title, the second the url of the selected bookmark.  See
`counsel-chrome-bm-actions-alist' for a number of provided actions.

When nil, a selection of actions to choose from will be shown.
When `counsel-chrome-bm' or `counsel-chrome-bm-all' are executed with a prefix
argument the selection of actions will always be shown."
  :type 'function)

(defcustom counsel-chrome-bm-actions-alist
  (seq-filter (lambda (e)
                e)
              (list
               (cons "Open" #'counsel-chrome-bm--open)
               (cons "Open in EWW" #'counsel-chrome-bm--open-in-eww)
               (cons "Copy title" #'counsel-chrome-bm--copy-title)
               (cons "Copy url" #'counsel-chrome-bm--copy-url)
               (cons "Insert title" #'counsel-chrome-bm--insert-title)
               (cons "Insert url" #'counsel-chrome-bm--insert-url)
               (if (fboundp 'org-insert-link)
                   (cons "Insert org link" #'counsel-chrome-bm--insert-org-link))
               (if (fboundp 'markdown-insert-inline-link)
                   (cons "Insert markdown link"
                         #'counsel-chrome-bm--insert-markdown-link))))
  "Alist of possible actions after selecting a bookmark.
When called with a prefix argument or when `counsel-chrome-bm-default-action' is
nil, `counsel-chrome-bm' and `counsel-chrome-bm-all' will prompt which of these
action to perform on the selected bookmark.

The car is the name of the action to display and the cdr is a function which
will receive 2 string arguments, the first being the title of the bookmark,
the second the url."
  :type '(alist :key-type string :value-type function))

(defcustom counsel-chrome-bm-no-jq nil
  "When true, do not attempt to use jq but always use native json functionality."
  :type 'boolean)

(defface counsel-chrome-bm-title '((t :inherit default))
  "Face for the title part of a bookmark.")

(defface counsel-chrome-bm-url '((t :inherit link))
  "Face for the URL part of a bookmark.")

(defface counsel-chrome-bm-url-prefix '((t :inherit default))
  "Face for the string printed before the URL of a bookmark starts.")

(defface counsel-chrome-bm-url-suffix '((t
                                         :inherit counsel-chrome-bm-url-prefix))
  "Face for the string printed after the URL of a bookmark.")

;;;
;;; Actions
;;;
(defun counsel-chrome-bm--open (_title url)
  "Open URL with the default browser."
  (browse-url url))

(defun counsel-chrome-bm--insert-title (title _url)
  "Insert TITLE in the current buffer."
  (with-ivy-window
    (insert title)))

(defun counsel-chrome-bm--insert-url (_title url)
  "Insert URL in the current buffer."
  (with-ivy-window (insert url)))

(defun counsel-chrome-bm--insert-org-link (title url)
  "Insert TITLE and URL as Org link if `org-insert-link' is available.
Does nothing if `org-insert-link' is unavailable."
  (if (fboundp 'org-insert-link)
      (with-ivy-window (org-insert-link '() url title))))

(defun counsel-chrome-bm--insert-markdown-link (title url)
  "Insert TITLE and URL as markdown link.
Does nothing if `markdown-insert-inline-link' is unavailable."
  (if (fboundp 'markdown-insert-inline-link)
      (with-ivy-window (markdown-insert-inline-link title url))))

(defun counsel-chrome-bm--copy-title (title _url)
  "Copy TITLE."
  (kill-new title))

(defun counsel-chrome-bm--copy-url (_title url)
  "Copy URL."
  (kill-new url))

(defun counsel-chrome-bm--open-in-eww (_title url)
  "Open URL in eww."
  (eww url))

;;;
;;; Helpers
;;;
(defconst counsel-chrome-bm--separator ?\x1C)

(defvar counsel-chrome-bm--initialized nil)

(defvar counsel-chrome-bm--last-cmd "")

(defvar counsel-chrome-bm--no-jq-message-shown nil)

(defun counsel-chrome-bm--get-bookmarks-from-folder (json all)
  "Read bookmarks from JSON folder object.
Ignore ignore lists if ALL is non nil."
  (if (or all (not (member (alist-get 'name json)
                           counsel-chrome-bm-ignore-folder)))
      (let ((bookmarks '()))
        (mapc (lambda (child)
                (if (not (equal (alist-get 'type child)
                                "folder"))
                    (push (concat (alist-get 'name child)
                                  (string counsel-chrome-bm--separator)
                                  (alist-get 'url child))
                          bookmarks))
                (setq bookmarks
                      (nconc bookmarks
                             (counsel-chrome-bm--get-bookmarks-from-folder
                              child all))))
              (alist-get 'children json))
        bookmarks)))


(defun counsel-chrome-bm--read-bookmarks-from-json (json all)
  "Read bookmarks from JSON.
Ignore ignore lists if ALL is non nil."
  (let ((bookmarks '()))
    (mapc (lambda (root)
            (if (or all (not (member (symbol-name (car root))
                                     counsel-chrome-bm-ignore-key)))
                (setq bookmarks
                      (nconc bookmarks
                             (counsel-chrome-bm--get-bookmarks-from-folder
                              root all)))))
          (alist-get 'roots json))
    bookmarks))

(defun counsel-chrome-bm--create-cmd (all str)
  "Create jq query command with search string STR.
Ignore ignore lists if ALL is non nil."
  (let ((search-string (json-encode-string str)))
    (concat
     ".roots"
     (if (and counsel-chrome-bm-ignore-key (not all))
         (concat
          " | del("
          (mapconcat (lambda (n)
                       (format ".[%s]" (json-encode-string n)))
                     counsel-chrome-bm-ignore-key ", ")
          ")[] | ")
       "[] | ")
     (if (and counsel-chrome-bm-ignore-folder (not all))
         (concat
          "select("
          (mapconcat (lambda (n)
                       (format "(.name // \"\") != %s" (json-encode-string n)))
                     counsel-chrome-bm-ignore-folder " and ")
          ") | "))
     "recurse(.children[]?"
     (if (and counsel-chrome-bm-ignore-folder (not all))
         (concat
          "; (.type // \"\") != \"folder\" or ("
          (mapconcat (lambda (n)
                       (format "(.name // \"\") != %s" (json-encode-string n)))
                     counsel-chrome-bm-ignore-folder " and ")
          ")"))
     ") | select(.type != \"folder\") | "
     (if str
         (format
          "select(((.name // \"\") | contains(%s)) or ((.url // \"\") | contains(%s))) | "
          search-string search-string))
     " .name + \""
     (format "\\u%04x" counsel-chrome-bm--separator)
     "\" + .url ")))

(defun counsel-chrome-bm--split (str)
  "Split STR into a cons of title and url."
  (if str
      (if (string= str (counsel-chrome-bm--parse-error-msg)) (cons str "")
        (let ((bm (split-string str (string counsel-chrome-bm--separator))))
          (if (> (length bm) 1)
              (cons (car bm) (cadr bm))
            (cons (car bm) (car bm)))))
    (cons "" "")))

(defun counsel-chrome-bm--split-and-call (func str)
  "Split STR into a cons of title and url and pass it to FUNC."
  (let ((bm (counsel-chrome-bm--split str)))
    (funcall func (car bm) (cdr bm))))

(defun counsel-chrome-bm--transformer (str)
  "Ivy display transformer for `counsel-chrome-bm' and `counsel-chrome-bm-all'.
Lays out and propertizes STR."
  (let ((bm (counsel-chrome-bm--split str)))
    (concat
     (propertize (car bm) 'face 'counsel-chrome-bm-title)
     (if (not (string= str (counsel-chrome-bm--parse-error-msg)))
         (concat
          (propertize
           (or counsel-chrome-bm-url-prefix "")
           'face 'counsel-chrome-bm-url-prefix)
          (propertize
           (cdr bm) 'face 'counsel-chrome-bm-url)
          (propertize
           (or counsel-chrome-bm-url-suffix "")
           'face 'counsel-chrome-bm-url-suffix))))))

(defun counsel-chrome-bm--title-only-transformer (str)
  "Ivy display transformer for `counsel-chrome-bm' and `counsel-chrome-bm-all'.
Extracts title from STR and propertizes it.  Used for `ivy-rich'."
  (let ((bm (counsel-chrome-bm--split str)))
    (propertize (car bm) 'face 'counsel-chrome-bm-title)))

(defun counsel-chrome-bm--url-only-transformer (str)
  "Ivy display transformer for `counsel-chrome-bm' and `counsel-chrome-bm-all'.
Extracts url from STR and propertizes it.  Used for `ivy-rich'."
  (let ((bm (counsel-chrome-bm--split str)))
    (propertize (cdr bm) 'face 'counsel-chrome-bm-url)))

(defun counsel-chrome-bm--dispatch (bookmark)
  "Pass BOOKMARK to the correct action based on settings."
  (let* ((split (split-string bookmark (string counsel-chrome-bm--separator)))
         (title (car split))
         (url (cadr split)))
    (if (and counsel-chrome-bm-default-action (not current-prefix-arg))
        (funcall counsel-chrome-bm-default-action title url)
      (ivy-read "Action: " counsel-chrome-bm-actions-alist
                :require-match t
                :history 'counsel-chrome-bm--action-history
                :caller 'counsel-chrome-bm--dispatch
                :re-builder #'ivy--regex-plus
                :action (lambda (action)
                          (funcall (cdr action) title url))))))

(defun counsel-chrome-bm--jq ()
  "Return jq executable based on settings."
  (if counsel-chrome-bm-jq
      (expand-file-name counsel-chrome-bm-jq)
    (executable-find "jq")))

(defun counsel-chrome-bm--check-for-problems ()
  "Check for issues and throws an error if any issue is found."
  (cond ((not counsel-chrome-bm-file)
         (error "Variable counsel-chrome-bm-file is not set"))
        ((not (file-readable-p counsel-chrome-bm-file))
         (error "Can not read file %s" (expand-file-name
                                        counsel-chrome-bm-file)))
        ((and counsel-chrome-bm-jq
              (not (file-executable-p (expand-file-name counsel-chrome-bm-jq))))
         (error "Can not execute %s" (expand-file-name counsel-chrome-bm-jq)))))

(defun counsel-chrome-bm--parse-error-msg ()
  "Create error message for parse errors in file `counsel-chrome-bm-file'."
  (format
   "Could not parse %s: not a bookmark file?"
   (expand-file-name counsel-chrome-bm-file)))

(defun counsel-chrome-bm--read-jq (all str)
  "Run jq with `counsel--async-command'.  Use STR as search string.
Ignore ignore lists if ALL is non nil."
  (or
   (ivy-more-chars)
   (progn
     (let ((cmd (format
                 "%s -r '%s' \"%s\""
                 (counsel-chrome-bm--jq)
                 (replace-regexp-in-string
                  "'"
                  "'\"'\"'"
                  (counsel-chrome-bm--create-cmd all str))
                 (expand-file-name counsel-chrome-bm-file))))
       (setq counsel-chrome-bm--last-cmd cmd)
       (counsel--async-command cmd))
     nil)))

(defun counsel-chrome-bm--read-native (all)
  "Read bookmarks from `counsel-chrome-bm-file'.
Uses native json functionality.  If ALL is non nil, ignore lists are ignored."
  (counsel-chrome-bm--read-bookmarks-from-json
   (condition-case err
       (json-read-file (expand-file-name counsel-chrome-bm-file))
     ((json-end-of-file end-of-buffer)
      (error "%s: %s"
             (counsel-chrome-bm--parse-error-msg)
             (error-message-string err))))
   all))

(defun counsel-chrome-bm--read-filtered-jq (str)
  "Ivy read function for `counsel-chrome-bm--read'.
Search for STR."
  (counsel-chrome-bm--read-jq nil str))

(defun counsel-chrome-bm--read-all-jq (str)
  "Ivy read function for `counsel-chrome-bm--read'.
Search for STR, ignore ignore-lists."
  (counsel-chrome-bm--read-jq t str))

(defun counsel-chrome-bm--read (all caller)
  "Setup and run `ivy-read' on behalf of CALLER.
Ignore ignore-lists if ALL is non-nil."
  (unless counsel-chrome-bm--initialized (counsel-chrome-bm-initialize))
  (counsel-chrome-bm--check-for-problems)
  (let* ((jq (counsel-chrome-bm--jq))
         (use-jq (and jq (not counsel-chrome-bm-no-jq) (file-executable-p jq)))
         (provider (cond ((and use-jq all (not counsel-chrome-bm-no-jq))
                          #'counsel-chrome-bm--read-all-jq)
                         ((and use-jq (not counsel-chrome-bm-no-jq))
                          #'counsel-chrome-bm--read-filtered-jq)
                         (all
                          (counsel-chrome-bm--read-native t))
                         (t
                          (counsel-chrome-bm--read-native nil)))))
    (when (and
           (not use-jq)
           (not counsel-chrome-bm--no-jq-message-shown)
           (not counsel-chrome-bm-no-jq))
      (setq counsel-chrome-bm--no-jq-message-shown t)
      (message
       "counsel-chrome-bm: Could not find jq. Falling back to native JSON parsing."))
    (when use-jq
      (counsel-set-async-exit-code caller
                                   4
                                   (counsel-chrome-bm--parse-error-msg))
      (counsel-set-async-exit-code caller
                                   5
                                   (counsel-chrome-bm--parse-error-msg)))
    (ivy-read
     "Bookmark: "
     provider
     :require-match t
     :history 'counsel-chrome-bm--history
     :preselect (ivy-thing-at-point)
     :caller caller
     :action #'counsel-chrome-bm--dispatch
     :dynamic-collection use-jq)))

;;;
;;; Commands
;;;

;;;###autoload
(defun counsel-chrome-bm ()
  "Browse Chrome bookmarks with `ivy'.
Respects `counsel-chrome-bm-ignore-folder' and `counsel-chrome-bm-ignore-key'.

Executes `counsel-chrome-bm-default-action' on the selected bookmark.  If
`counsel-chrome-bm-default-action' is nil, it will present a list of actions
to choose from.

When called with a prefix argument it will ignore
`counsel-chrome-bm-default-action' and always ask which action to perform."
  (interactive)
  (counsel-chrome-bm--read nil 'counsel-chrome-bm))

;;;###autoload
(defun counsel-chrome-bm-all ()
  "Browse all Chrome bookmarks.
Ignores `counsel-chrome-bm-ignore-folder' and `counsel-chrome-bm-ignore-key'.

Executes `counsel-chrome-bm-default-action' on the selected bookmark.  If
`counsel-chrome-bm-default-action' is nil, it will present a list of actions
to choose from.

When called with a prefix argument it will ignore
`counsel-chrome-bm-default-action' and always ask which action to perform."
  (interactive)
  (counsel-chrome-bm--read t 'counsel-chrome-bm-all))

;;;###autoload
(defun counsel-chrome-bm-initialize ()
  "Initialize `counsel-chrome-bm'.
Normally this command is automatically called when necessary. But if you want
to configure your own extra actions for `counsel-chrome-bm' with
`ivy-set-actions' or `ivy-add-actions', you'll have to make sure to call this
command first, e.g.:

\(use-package counsel-chrome-bm
  :config
  (counsel-chrome-bm-initialize)
  (ivy-set-actions 'counsel-chrome-bm '( <etc> ))

The same goes for changing `ivy-more-chars-alist'."
  (interactive)
  (dolist (cmd '(counsel-chrome-bm counsel-chrome-bm-all))
    (add-to-list 'ivy-more-chars-alist (cons cmd 0))
    (ivy-configure cmd
      :display-transformer-fn #'counsel-chrome-bm--transformer)
    (ivy-set-actions cmd `(("i"
                            ,(lambda (x)
                               (counsel-chrome-bm--split-and-call
                                #'counsel-chrome-bm--insert-url x))
                            "insert url")
                           ("O"
                            ,(lambda (x)
                               (counsel-chrome-bm--split-and-call
                                #'counsel-chrome-bm--open x))
                            "open")
                           ("w"
                            ,(lambda (x)
                               (counsel-chrome-bm--split-and-call
                                #'counsel-chrome-bm--copy-url x))
                            "copy url")))
    (when (and (fboundp 'ivy-rich-set-columns) (fboundp 'ivy-rich-mode))
        (dolist (cmd '(counsel-chrome-bm counsel-chrome-bm-all))
          (ivy-rich-set-columns cmd
                                '((counsel-chrome-bm--title-only-transformer
                                   (:width 0.5))
                                  (counsel-chrome-bm--url-only-transformer
                                   (:width 0.5)))))
        (ivy-rich-mode)
        (ivy-rich-mode)))
  (setq counsel-chrome-bm--initialized t))

(provide 'counsel-chrome-bm)

;;; counsel-chrome-bm.el ends here
