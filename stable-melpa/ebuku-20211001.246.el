;;; ebuku.el --- Interface to the buku Web bookmark manager -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2021  Alexis <flexibeast@gmail.com>, Erik Sjöstrand <sjostrand.erik@gmail.com>, Junji Zhi [https://github.com/junjizhi]

;; Author: Alexis <flexibeast@gmail.com>, Erik Sjöstrand <sjostrand.erik@gmail.com>, Junji Zhi [https://github.com/junjizhi]
;; Maintainer: Alexis <flexibeast@gmail.com>
;; Created: 2019-11-07
;; URL: https://github.com/flexibeast/ebuku
;; Package-Version: 20211001.246
;; Package-Commit: 0f853e9fd7647a33b38925727d283f5731fafef8
;; Keywords: bookmarks,buku,data,web,www
;; Version: 0
;; Package-Requires: ((emacs "25.1"))

;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;

;;; Commentary:

;; Ebuku provides a basic interface to the
;; [buku](https://github.com/jarun/buku) Web bookmark manager.

;; ## Table of Contents

;; - [Installation](#installation)
;; - [Usage](#usage)
;; - [Customisation](#customisation)
;; - [TODO](#todo)
;; - [Issues](#issues)
;; - [License](#license)

;; ## Installation

;; Install [Ebuku from MELPA](https://melpa.org/#/ebuku), or put the
;; `ebuku' folder in your load-path and do a `(load "ebuku")'.

;; ## Usage

;; Create an Ebuku buffer with `M-x ebuku'.

;; In the `*Ebuku*' buffer, the following bindings are available:

;; * `s' - Search for a bookmark (`ebuku-search').

;; * `r' - Show recently-added bookmarks (`ebuku-search-on-recent').

;; * `*' - Show all bookmarks (`ebuku-show-all').

;; * `-' - Toggle results limit (`ebuku-toggle-results-limit').

;; * `g' - Refresh the search results, based on last search (`ebuku-refresh').

;; * `RET' - Open the bookmark at point in a browser (`ebuku-open-url').

;; * `n' - Move point to the next bookmark URL (`ebuku-next-bookmark').

;; * `p' - Move point to the previous bookmark URL (`ebuku-previous-bookmark').

;; * `a' - Add a new bookmark (`ebuku-add-bookmark').

;; * `d' - Delete a bookmark (`ebuku-delete-bookmark').  If point is on
;;   a bookmark, offer to delete that bookmark; otherwise, ask for the
;;   index of the bookmark to delete.

;; * `e' - Edit a bookmark (`ebuku-edit-bookmark').  If point is on a
;;   bookmark, edit that bookmark; otherwise, ask for the index of the
;;   bookmark to edit.

;; * `C' - Copy the URL of the bookmark at point to the kill ring
;;   (`ebuku-copy-url').

;; * `q' - Quit Ebuku.

;; Bindings for Evil are available via the
;; [evil-collection](https://github.com/emacs-evil/evil-collection)
;; package, in `evil-collection-ebuku.el`.

;; ### Completion

;; Ebuku provides two cache variables for use by completion frameworks
;; (e.g. Ivy or Helm): `ebuku-bookmarks' and `ebuku-tags', which can
;; be populated via the `ebuku-update-bookmarks-cache' and
;; `ebuku-update-tags-cache' functions, respectively.

;; ## Customisation

;; The `ebuku' customize-group can be used to customise:

;; * the path to the `buku' executable;

;; * the path to the buku database;

;; * the number of recently-added bookmarks to show;

;; * which bookmarks to show on startup;

;; * the maximum number of bookmarks to show;

;; * whether to automatically retrieve URL metadata when adding a
;;   bookmark; and

;; * the faces used by Ebuku.

;; ## TODO

;; * One should be able to edit bookmarks directly in the `*Ebuku*'
;;   buffer, à la `wdired'.  Much of the infrastructure to support this
;;   is already in place, but there are still important details yet to
;;   be implemented.

;; <a name="issues"></a>

;; ## Issues / bugs

;; If you discover an issue or bug in Ebuku not already
;; noted:

;; * as a TODO item, or

;; * in [the project's "Issues" section on
;;   GitHub](https://github.com/flexibeast/ebuku/issues),

;; please create a new issue with as much detail as possible,
;; including:

;; * which version of Emacs you're running on which operating system,
;;   and

;; * how you installed Ebuku.

;; ## License

;; [GNU General Public License version
;; 3](https://www.gnu.org/licenses/gpl.html), or (at your option) any
;; later version.

;;; Code:

;;
;; User-customisable settings.
;;

(require 'browse-url)

(defgroup ebuku nil
  "Emacs interface to the buku bookmark manager."
  :group 'external)

(defcustom ebuku-buku-path (executable-find "buku")
  "Absolute path of the `buku' executable."
  :type '(file :must-match t)
  :group 'ebuku)

(defcustom ebuku-cache-default-args '("--print")
  "Default arguments to `ebuku-update-cache'."
  :type '(repeat string)
  :group 'ebuku)

(defcustom ebuku-database-path (cond
                                ((eq system-type 'windows-nt)
                                 (substitute-in-file-name
                                  "%APPDATA%\buku\bookmarks.db"))
                                ((getenv "XDG_DATA_HOME")
                                 (substitute-in-file-name
                                  "$XDG_DATA_HOME/buku/bookmarks.db"))
                                ((getenv "HOME")
                                 (substitute-in-file-name
                                  "$HOME/.local/share/buku/bookmarks.db"))
                                (t
                                 "./bookmarks.db"))
  "Absolute path of the buku database."
  :type '(file :must-match t)
  :group 'ebuku)

(defcustom ebuku-display-on-startup 'all
  "What to display in the search results area on startup.

Specify `\\='all' for all bookmarks; `\\='recent' for recent additions; or
`nil' for no bookmarks."
  :type '(radio (const :tag "All bookmarks" all)
                (const :tag "Recent additions" recent)
                (const :tag "No bookmarks" nil))
  :group 'ebuku)

(defcustom ebuku-mode-hook nil
  "Functions to run when starting `ebuku-mode'."
  :type '(repeat function)
  :group 'ebuku)

(defcustom ebuku-recent-count 3
  "Number of recently-added bookmarks to show."
  :type 'integer
  :group 'ebuku)

(defcustom ebuku-results-limit 1000
  "Maximum number of bookmarks to show.

Set this variable to 0 for no maximum."
  :type 'integer
  :group 'ebuku)

(defcustom ebuku-retrieve-url-metadata t
  "Whether to automatically retrieve URL metadata when adding a bookmark."
  :type 'boolean
  :group 'ebuku)


(defgroup ebuku-faces nil
  "Faces for `ebuku-mode'."
  :group 'ebuku)

(defface ebuku-comment-face
  '((t
     :inherit default))
  "Face for *Ebuku* bookmark comments."
  :group 'ebuku-faces)

(defface ebuku-heading-face
  '((t
     :height 2.0
     :weight bold))
  "Face for *Ebuku* headings."
  :group 'ebuku-faces)

(defface ebuku-help-face
  '((t
     :inherit default))
  "Face for *Ebuku* help text."
  :group 'ebuku-faces)

(defface ebuku-separator-face
  '((t
     :inherit default))
  "Face for *Ebuku* separators."
  :group 'ebuku-faces)

(defface ebuku-tags-face
  '((t
     :inherit default))
  "Face for *Ebuku* bookmark tags."
  :group 'ebuku-faces)

(defface ebuku-title-face
  '((t
     :inherit default))
  "Face for *Ebuku* bookmark titles."
  :group 'ebuku-faces)

(defface ebuku-url-face
  '((t
     :inherit link))
  "Face for *Ebuku* bookmark URLs."
  :group 'ebuku-faces)

(defface ebuku-url-highlight-face
  '((t
     :inherit highlight))
  "Face for highlighting *Ebuku* bookmark URLs."
  :group 'ebuku-faces)


;;
;; Keymaps.
;;

(defvar ebuku-mode-map
  (let ((km (make-sparse-keymap)))
    (define-key km (kbd "a") #'ebuku-add-bookmark)
    (define-key km (kbd "d") #'ebuku-delete-bookmark)
    (define-key km (kbd "e") #'ebuku-edit-bookmark)
    (define-key km (kbd "g") #'ebuku-refresh)
    (define-key km (kbd "n") #'ebuku-next-bookmark)
    (define-key km (kbd "p") #'ebuku-previous-bookmark)
    (define-key km (kbd "r") #'ebuku-search-on-recent)
    (define-key km (kbd "s") #'ebuku-search)
    (define-key km (kbd "*") #'ebuku-show-all)
    (define-key km (kbd "-") #'ebuku-toggle-results-limit)
    (define-key km (kbd "<RET>") #'ebuku-open-url)
    (define-key km (kbd "C") #'ebuku-copy-url)
    (define-key km [mouse-1] #'ebuku-open-url)
    (define-key km [mouse-2] #'ebuku-open-url)
    km))


;;
;; Internal variables.
;;

(defvar ebuku--last-search nil
  "Internal variable containing the parameters of the last search.")

(defvar ebuku--last-results-limit 0
  "Internal variable for use by `ebuku-toggle-results-limit'.")

(defvar ebuku--results-start nil
  "Internal variable containing buffer location of start of search results.")


;;
;; Internal functions.
;;

(defun ebuku--call-buku (args)
  "Internal function for calling `buku' with list ARGS."
  (unless ebuku-buku-path
    (error "Couldn't find buku: check 'ebuku-buku-path'"))
  (apply #'call-process
         `(,ebuku-buku-path nil t nil
                            "--np" "--nc"
                            "--db" ,ebuku-database-path
                            ,@args)))

(defun ebuku--create-mode-menu ()
  "Internal function to create the `ebuku-mode' menu."
  (easy-menu-define ebuku--menu ebuku-mode-map "Menu bar entry for Ebuku"
    '("Ebuku"
      ["Search" (ebuku-search) :keys "s"]
      ["Recent" (ebuku-search-on-recent) :keys "r"]
      ["Show all" (ebuku-show-all) :keys "*"]
      ["Toggle results limit" (ebuku-toggle-results-limit) :keys "-"]
      ["Refresh" (ebuku-refresh) :keys "g"]
      "---"
      ["Open bookmark" (ebuku-open-url) :keys "RET"]
      ["Copy bookmark" (ebuku-copy-url) :keys "C"]
      ["Next bookmark" (ebuku-next-bookmark) :keys "n"]
      ["Previous bookmark" (ebuku-previous-bookmark) :keys "p"]
      "---"
      ["Add bookmark" (ebuku-add-bookmark) :keys "a"]
      ["Delete bookmark" (ebuku-delete-bookmark) :keys "d"]
      ["Edit bookmark" (ebuku-edit-bookmark) :keys "e"]
      "---"
      ["Customize" (customize-group 'ebuku) :keys "c"]
      ["Quit" (kill-buffer) :keys "q"])))

(defun ebuku--delete-bookmark-helper (index)
  "Internal function to delete the buku bookmark at INDEX.

buku doesn't provide a `--force' option for `--delete'; instead,
it always prompts the user for confirmation.  This function starts
an asychrononous buku process to delete the bookmark, to which we
can then send 'y' to confirm.  (The user will have already been
prompted for confirmation by the \\[ebuku-delete-bookmark] command.)"
  (unless ebuku-buku-path
    (error "Couldn't find buku: check 'ebuku-buku-path'"))
  (let ((proc (start-process
               "ebuku-delete"
               nil
               ebuku-buku-path "--delete" index)))
    (set-process-sentinel proc 'ebuku--delete-bookmark-sentinel)
    (process-send-string proc "y\n")))

(defun ebuku--delete-bookmark-sentinel (_proc event)
  "Internal function to wait for buku to complete bookmark deletion.

Argument PROC is the buku process started by `ebuku--delete-bookmark-helper'.

Argument EVENT is the event received from that process."
  (if (string= "finished\n" event)
      (progn
        (ebuku-refresh)
        (message "Bookmark deleted."))
    (error "Failed to delete bookmark")))

(defun ebuku--get-index-at-point ()
  "Internal function to get the buku index of the bookmark at point."
  (get-char-property (point) 'buku-index))

(defun ebuku--get-bookmark-at-index (index)
  "Internal function to get bookmark data for INDEX."
  (let ((title "")
        (url "")
        (comment "")
        (tags ""))
    (with-temp-buffer
      (if (ebuku--call-buku `("--print" ,index))
          (progn
            (goto-char (point-min))
            (re-search-forward "^[[:digit:]]+\\.\\s-+\\(.+\\)$" nil t)
            (setq title (match-string 1))
            (re-search-forward "^\\s-+> \\(.+\\)$" nil t)
            (setq url (match-string 1))
            (if (re-search-forward "^\\s-+\\+ \\(.+\\)$" nil t)
                (setq comment (match-string 1)))
            (if (re-search-forward "^\\s-+# \\(.+\\)$" nil t)
                (setq tags (match-string 1))))
        (error (concat "Failed to get bookmark data for index " index))))
    `((title . ,title) (url . ,url) (comment . ,comment) (tags ,tags))))

(defun ebuku--get-bookmark-count ()
  "Internal function to get the number of bookmarks in the buku database."
  (with-temp-buffer
    (if (ebuku--call-buku `("--print" "-1"))
        (progn
          (goto-char (point-min))
          (if (re-search-forward "^\\([[:digit:]]+\\)\\." nil t)
              (match-string 1)
            "0"))
      (error "Failed to get bookmark count"))))

(defun ebuku--search-helper (type prompt &optional term exclude)
  "Internal function to call `buku' with appropriate search arguments.

Argument TYPE is a string: the type of buku search.

Argument PROMPT is a string: the minibuffer prompt for that search.

Argument TERM is a string: the search term.

Argument EXCLUDE is a string: keywords to exclude from search results."
  (let* ((count "0")
         (term (if term
                   term
                 (read-from-minibuffer prompt)))
         (exclude (if exclude
                      exclude
                    (read-from-minibuffer "Exclude keywords? ")))
         (search (concat type " " term
                         (if (not (string= "" exclude))
                             (concat " --exclude " exclude))))
         (title-line-re
          (concat
           ;; Result number, or index number when using '--print'.
           "^\\([[:digit:]]+\\)\\. "
           ;; Title.
           "\\(.+?\\)"
           ;; Index number when not using '--print'.
           "\\(?: \\[\\([[:digit:]]+\\)\\]\\)?\n"
           ))
         (title "")
         (index "")
         (url "")
         (comment "")
         (tags ""))
    (with-temp-buffer
      (if (string= "" exclude)
          (ebuku--call-buku `(,type ,term))
        (ebuku--call-buku `(,type ,term "--exclude" ,exclude)))
      (setq ebuku--last-search `(,type ,prompt ,term ,exclude))
      (if (string= "--print" type)
          (cond
           ((string= "[recent]" prompt)
            (setq count (number-to-string ebuku-recent-count)))
           ((string= "[all]" prompt)
            (setq count (ebuku--get-bookmark-count))))
        (if (re-search-backward "^\\([[:digit:]]+\\)\\." nil t)
            (setq count (match-string 1))
          (setq count "0")))
      (goto-char (point-min))
      (with-current-buffer "*Ebuku*"
        (let ((inhibit-read-only t))
          (goto-char ebuku--results-start)
          (kill-region (point) (point-max))
          (cond
           ((string= "0" count)
            (insert (concat "  No results found for '" search "'.\n\n")))
           ((string= "1" count)
            (insert (concat "  Found 1 result for '" search "'.\n\n")))
           (t
            (progn
              (if (or (< (string-to-number count) ebuku-results-limit)
                      (= 0 ebuku-results-limit))
                  (insert (concat "  Found "
                                  count
                                  " results for '"
                                  search
                                  "'.\n\n"))
                (if (> (string-to-number count) ebuku-results-limit)
                    (progn
                      (insert (concat "  Found "
                                      (number-to-string ebuku-results-limit)
                                      " results for '"
                                      search
                                      "'.\n"))
                      (insert (concat "  (Omitted "
                                      (number-to-string
                                       (- (string-to-number count)
                                          ebuku-results-limit))
                                      " results due to non-zero value\n"
                                      "   of 'ebuku-results-limit'.)\n\n"))))))))))
      (unless (string= "0" count)
        (while (re-search-forward title-line-re nil t)
          (if (string= "--print" type)
              (progn
                (setq index (match-string 1))
                (setq title (match-string 2)))
            (progn
              (setq title (match-string 2))
              (setq index (match-string 3))))
          (re-search-forward "^\\s-+> \\([^\n]+\\)") ; URL
          (setq url (match-string 1))
          (forward-line)
          (let ((line (buffer-substring
                       (line-beginning-position)
                       (line-end-position))))
            ;; If this line not empty, it's either a comment or tags.
            (if (not (string= "" line))
                (if (string-match "^\\s-+[+]" line)
                    ;; It's a comment.
                    (progn
                      (string-match "^\\s-+[+] \\(.+\\)$" line)
                      (setq comment (match-string 1 line))
                      (forward-line)
                      (let ((line (buffer-substring
                                   (line-beginning-position)
                                   (line-end-position))))
                        (if (not (string= "" line))
                            ;; Line isn't empty, so it must contain tags.
                            (progn
                              (string-match "^\\s-+[#] \\(.*\\)$" line)
                              (setq tags (match-string 1 line))))))
                  ;; It's tags.
                  (string-match "^\\s-*[#] \\(.*\\)$" line)
                  (setq tags (match-string 1 line)))))
          (with-current-buffer "*Ebuku*"
            (let ((inhibit-read-only t))
              (insert (propertize "  --  "
                                  'buku-index index)
                      (propertize title
                                  'buku-index index
                                  'data title
                                  'face 'ebuku-title-face)
                      (propertize "\n"
                                  'buku-index index)
                      (propertize "      "
                                  'buku-index index)
                      (propertize url
                                  'buku-index index
                                  'data url
                                  'face 'ebuku-url-face
                                  'mouse-face 'ebuku-url-highlight-face
                                  'help-echo "mouse-1: open link in browser")
                      (propertize "\n"
                                  'buku-index index))
              (unless (string= "" comment)
                (insert
                 (propertize "      "
                             'buku-index index)
                 (propertize comment
                             'buku-index index
                             'data comment
                             'face 'ebuku-comment-face)
                 (propertize "\n"
                             'buku-index index)))
              (unless (string= "" tags)
                (insert
                 (propertize "      "
                             'buku-index index)
                 (propertize tags
                             'buku-index index
                             'data tags
                             'face 'ebuku-tags-face)
                 (propertize "\n"
                             'buku-index index)))
              (insert "\n")))
          (setq comment ""
                tags ""))
        (with-current-buffer "*Ebuku*"
          (goto-char (point-min))
          (goto-char ebuku--results-start)
          (forward-line 2))))))

;;
;; User-facing variables.
;;

(defvar ebuku-bookmarks '()
  "Cache of bookmarks in the buku database.

This cache is populated by the `ebuku-update-bookmarks-cache' command.
Each bookmark is an alist with the keys 'title 'url 'index 'tags 'comment.")

(defvar ebuku-tags '()
  "Cache of tags in the buku database.

This cache is populated by the `ebuku-update-tags-cache' command.")

;;
;; User-facing functions.
;;

(defun ebuku-add-bookmark ()
  "Add a bookmark to the buku database."
  (interactive)
  (let ((url "")
        (index "")
        (title "")
        (tags "")
        (comment ""))
    (setq url (read-from-minibuffer "Bookmark URL? "))
    (if ebuku-retrieve-url-metadata
        (with-temp-buffer
          (if (ebuku--call-buku `("--add" ,url))
              (progn
                (goto-char (point-min))
                (if (re-search-forward
                     "already exists at index \\([[:digit:]]+\\)" nil t)
                    (user-error (concat
                                 "Bookmark already exists at index "
                                 (match-string 1))))
                (re-search-forward "^\\([[:digit:]]+\\)\\. \\(.+\\)$")
                (setq index (match-string 1))
                (setq title (match-string 2))
                (if (re-search-forward "^\\s-+\\+ \\(.+\\)$" nil t)
                    (setq comment (match-string 3))))
            (error "Failed to add bookmark"))))
    (setq title (read-from-minibuffer "Bookmark title? " title))
    (setq tags (read-from-minibuffer "Bookmark tag(s)? " tags))
    (setq comment (read-from-minibuffer "Bookmark comment? " comment))
    (if ebuku-retrieve-url-metadata
        (with-temp-buffer
          (if (ebuku--call-buku `("--update" ,index
                                  "--title" ,title
                                  "--comment" ,comment
                                  "--tag" ,tags))
              (progn
                (ebuku-refresh)
                (message "Bookmark added."))
            (error "Failed to modify bookmark metadata")))
      (with-temp-buffer
        (if (ebuku--call-buku `("--add" ,url
                                "--title" ,title
                                "--tag" ,tags
                                "--comment" ,comment))
            (progn
              (ebuku-refresh)
              (message "Bookmark added."))
          (error "Failed to add bookmark"))))))

(defun ebuku-delete-bookmark ()
  "Delete a bookmark from the buku database.

If point is on a bookmark, offer to delete that bookmark;
otherwise, ask for the index of the bookmark to delete."
  (interactive)
  (let ((index (ebuku--get-index-at-point)))
    (if (not index)
        (setq index (read-from-minibuffer "Bookmark index to delete? ")))
    (let ((bookmark (ebuku--get-bookmark-at-index index)))
      (if bookmark
          (let ((title (cdr (assoc 'title bookmark))))
            (if (y-or-n-p (concat "Delete bookmark \"" title "\"? "))
                (ebuku--delete-bookmark-helper index)))
        (error (concat "Failed to get bookmark data for index " index))))))

(defun ebuku-edit-bookmark ()
  "Edit a bookmark in the buku database.

If point is on a bookmark, offer to edit that bookmark;
otherwise, ask for the index of the bookmark to edit."
  (interactive)
  (let ((index (ebuku--get-index-at-point)))
    (if (not index)
        (setq index (read-from-minibuffer "Bookmark index to edit? "))
      (let ((bookmark (ebuku--get-bookmark-at-index index)))
        (if bookmark
            (let ((title (read-from-minibuffer
                          "Title? "
                          (cdr (assoc 'title bookmark))))
                  (url (read-from-minibuffer
                        "URL? "
                        (cdr (assoc 'url bookmark))))
                  (tags (read-from-minibuffer
                         "Tags? "
                         (cdr (assoc 'tags bookmark))))
                  (comment (read-from-minibuffer
                            "Comment? "
                            (cdr (assoc 'comment bookmark)))))
              (with-temp-buffer
                (if (ebuku--call-buku `("--update" ,index
                                        "--title" ,title
                                        "--url" ,url
                                        "--comment" ,comment
                                        "--tag" ,tags))
                    (progn
                      (ebuku-refresh)
                      (message "Bookmark updated."))
                  (error "Failed to update bookmark"))))
          (error (concat "Failed to get bookmark data for index " index)))))))

(defun ebuku-gather-bookmarks (&optional type term exclude)
  "Return a list of bookmarks.

Each bookmark is an alist with the keys 'title 'url 'index 'tags 'comment.
The bookmarks is fetched from buku with the following arguments:

  - TYPE (string): the type of buku search (default \"--print\").
  - TERM (string): what to search for.
  - EXCLUDE (string): keywords to exclude from the search results."
  (let ((results)
        (type (or type "--print"))
        (title-line-re
         (concat
          ;; Result number, or index number when using '--print'.
          "^\\([[:digit:]]+\\)\\. "
          ;; Title.
          "\\(.+?\\)"
          ;; Index number when not using '--print'.
          "\\(?: \\[\\([[:digit:]]+\\)\\]\\)?\n")))
    (with-temp-buffer
      (ebuku--call-buku
       (remq nil
             `(,type ,term ,@(when (and exclude (not (string-empty-p exclude)))
                               `("--exclude" ,exclude)))))
      (goto-char (point-min))
      (while (re-search-forward title-line-re nil t)
        (let ((data))
          (if (or (string= "--print" type)
                  (string= "-p" type))
              (progn
                (map-put data 'index (match-string 1))
                (map-put data 'title (match-string 2)))
            (map-put data 'title (match-string 2))
            (map-put data 'index (match-string 3)))
          (re-search-forward "^\\s-+> \\([^\n]+\\)") ; URL
          (map-put data 'url (match-string 1))
          (forward-line)
          (when (looking-at "^\\s-+[+] \\(.+\\)$")
            (map-put data 'comment (match-string 1))
            (forward-line))
          (when (looking-at "^\\s-+[#] \\(.+\\)$")
            (map-put data 'tags (or (split-string
                                     (or (match-string 1)
                                         "")
                                     "," t)
                                    '())))
          (push data results)))
      results)))

(defun ebuku-next-bookmark ()
  "Move point to the next bookmark URL."
  (interactive)
  (re-search-forward "^\\s-+http" nil t 1)
  (beginning-of-line)
  (re-search-forward "^\\s-+" nil t 1))

(defun ebuku-open-url ()
  "Open the URL for the bookmark at point."
  (interactive)
  (let ((index (get-char-property (point) 'buku-index)))
    (if index
        (save-excursion
          (goto-char (1+ (previous-single-property-change (point) 'buku-index)))
          (forward-line)
          (goto-char (next-single-property-change (point) 'data))
          (browse-url-at-point))
      (user-error "No bookmark at point"))))

(defun ebuku-copy-url ()
  "Copy the URL of the bookmark at point to the kill ring."
  (interactive)
  (let ((index (get-char-property (point) 'buku-index)))
    (if index
        (save-excursion
          (goto-char (1+ (previous-single-property-change (point) 'buku-index)))
          (forward-line)
          (goto-char (next-single-property-change (point) 'data))
          (let ((url-to-copy (browse-url-url-at-point)))
            (kill-new url-to-copy)
            (message "Copied: %s" url-to-copy)))
      (user-error "No bookmark URL at point"))))

(defun ebuku-previous-bookmark ()
  "Move point to the previous bookmark URL."
  (interactive)
  (re-search-forward "^\\s-+http" nil t -1)
  (beginning-of-line)
  (re-search-forward "^\\s-+" nil t 1))

(defun ebuku-refresh ()
  "Refresh the list of search results, based on last search."
  (interactive)
  (if ebuku--last-search
      (let ((term (nth 2 ebuku--last-search)))
        (if (and (not (string= "[recent]" (nth 1 ebuku--last-search)))
                 (string-match "^-\\([[:digit:]]+\\)$" term))
            (let ((count (string-to-number (match-string 1 term))))
              (if (/= count ebuku-results-limit)
                  (setf (nth 2 ebuku--last-search)
                        (concat "-"
                                (number-to-string ebuku-results-limit))))
              (apply #'ebuku--search-helper ebuku--last-search))
          (apply #'ebuku--search-helper ebuku--last-search)))))

(defun ebuku-search (char)
  "Search the buku database for bookmarks.

Argument CHAR is the character selected by the user to specify
the type of search to be performed."
  (interactive "cSearch on a[n]y, a[l]l, [t]ag or [r]egex?")
  (cond
   ((char-equal char ?n) (ebuku-search-on-any))
   ((char-equal char ?l) (ebuku-search-on-all))
   ((char-equal char ?t) (ebuku-search-on-tag))
   ((char-equal char ?r) (ebuku-search-on-reg))))

(defun ebuku-search-on-all ()
  "Do a `buku' search using '--sall'."
  (interactive)
  (ebuku--search-helper "--sall" "Keyword? "))

(defun ebuku-search-on-any ()
  "Do a `buku' search using '--sany'."
  (interactive)
  (ebuku--search-helper "--sany" "Keyword? "))

(defun ebuku-search-on-recent ()
  "Do a `buku' search for recently-added bookmarks."
  (interactive)
  (ebuku--search-helper "--print"
                        "[recent]" ; Dummy prompt to indicate prefab 'search'
                        (concat "-"
                                (number-to-string ebuku-recent-count))
                        ""))

(defun ebuku-search-on-reg ()
  "Do a `buku' search using '--sreg'."
  (interactive)
  (ebuku--search-helper "--sreg" "Regex? "))

(defun ebuku-search-on-tag ()
  "Do a `buku' search using '--stag'."
  (interactive)
  (ebuku--search-helper "--stag" "Tag? "))

(defun ebuku-show-all ()
  "Do a `buku' search for as many bookmarks as possible.

The maximum number of bookmarks to show is specified by
`ebuku-results-limit'."
  (interactive)
  (ebuku--search-helper "--print"
                        "[all]" ; Dummy prompt to indicate prefab 'search'
                        (concat "-"
                                (number-to-string ebuku-results-limit))
                        ""))

(defun ebuku-toggle-results-limit ()
  "Toggle whether to limit results to `ebuku-results-limit'."
  (interactive)
  (if (> ebuku-results-limit 0)
      (progn
        (setq ebuku--last-results-limit ebuku-results-limit)
        (setq ebuku-results-limit 0))
    (setq ebuku-results-limit ebuku--last-results-limit))
  (ebuku-refresh))

(defun ebuku-update-bookmarks-cache (&optional type term exclude)
  "Repopulate the `ebuku-bookmarks' variable.

The arguments TYPE, TERM, and EXCLUDE are passed to `ebuku-gather-bookmarks'.
If an argument is excluded, get it from `ebuku-cache-default-args'."
  (interactive)
  (setq ebuku-bookmarks
        (ebuku-gather-bookmarks
         (or type (nth 0 ebuku-cache-default-args))
         (or term (nth 1 ebuku-cache-default-args))
         (or exclude (nth 2 ebuku-cache-default-args)))))

(defun ebuku-update-tags-cache ()
  "Repopulate the `ebuku-tags' variable."
  (interactive)
  (let ((tags '()))
    (ebuku-update-bookmarks-cache)
    (dolist (bookmark ebuku-bookmarks)
      (setq tags (nconc (map-elt bookmark 'tags) tags)))
    (setq ebuku-tags (sort (seq-uniq tags) 'string-collate-lessp))))


;;;###autoload
(define-derived-mode ebuku-mode special-mode "Ebuku"
  "Major mode for interacting with the buku bookmark manager.

\\{ebuku-mode-map}"
  :group 'ebuku)


;;;###autoload
(defun ebuku ()
  "Start Ebuku, an interface to the buku bookmark manager."
  (interactive)
  (if (get-buffer "*Ebuku*")
      (switch-to-buffer "*Ebuku*")
    (progn
      (setq ebuku--last-search nil)
      (with-current-buffer (generate-new-buffer "*Ebuku*")
        (goto-char (point-min))
        (insert "\n")
        (insert (propertize
                 " Ebuku\n"
                 'face 'ebuku-heading-face))
        (insert (propertize
                 "  ----------\n\n"
                 'face 'ebuku-separator-face))
        (setq ebuku--results-start (point))
        (cond
         ((eq 'all ebuku-display-on-startup)
          (ebuku-show-all))
         ((eq 'recent ebuku-display-on-startup)
          (ebuku-search-on-recent))
         ((eq nil ebuku-display-on-startup)
          (insert "  [ Please specify a search, or press 'r' for recent additions. ]")))
        (goto-char ebuku--results-start)
        (add-text-properties (point-min) (point)
                             '(read-only t intangible t))
        (ebuku--create-mode-menu)
        (setq header-line-format nil)
        (ebuku-mode))
      (switch-to-buffer "*Ebuku*"))))


;; --

(provide 'ebuku)

;;; ebuku.el ends here
