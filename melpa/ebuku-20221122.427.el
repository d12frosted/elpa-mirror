;;; ebuku.el --- Interface to the buku Web bookmark manager -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2022  Alexis <flexibeast@gmail.com>, Erik Sjöstrand <sjostrand.erik@gmail.com>, Junji Zhi [https://github.com/junjizhi], Hilton Chain <hako@ultrarare.space>

;; Author: Alexis <flexibeast@gmail.com>, Erik Sjöstrand <sjostrand.erik@gmail.com>, Junji Zhi [https://github.com/junjizhi], Hilton Chain <hako@ultrarare.space>
;; Maintainer: Alexis <flexibeast@gmail.com>
;; Created: 2019-11-07
;; URL: https://github.com/flexibeast/ebuku
;; Package-Version: 20221122.427
;; Package-Commit: 0c6cf404a49bd68800221446df186fffa0139325
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

;; * `T' - Copy the title of the bookmark at point to the kill ring
;;   (`ebuku-copy-title').

;; * `I' - Copy the index of the bookmark at point to the kill ring
;;   (`ebuku-copy-index').

;; * `q' - Quit Ebuku.

;; Bindings for Evil are available via the
;; [evil-collection](https://github.com/emacs-evil/evil-collection)
;; package, in `evil-collection-ebuku.el`.

;; The index of a bookmark can be displayed in the echo area by moving
;; the screen pointer over the leading `--' text for the bookmark.

;; ### Completion

;; Ebuku provides two cache variables for use by completion frameworks
;; (e.g. Ivy or Helm): `ebuku-bookmarks' and `ebuku-tags', which can
;; be populated via the `ebuku-update-bookmarks-cache' and
;; `ebuku-update-tags-cache' functions, respectively.

;; ## Customisation

;; The `ebuku' customize-group includes variables for:

;; * the path to the `buku' executable;

;; * the path to the buku database;

;; * the number of recently-added bookmarks to show;

;; * which bookmarks to show on startup;

;; * the maximum number of bookmarks to show;

;; * whether to automatically retrieve URL metadata when adding a
;;   bookmark; and

;; * the faces used by Ebuku;

;; * whether to use `sqlite' to refresh the `ebuku-bookmarks' and
;;   `ebuku-tags' cache variables (requires separate installation of
;;   `sqlite3' executable).

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
(require 'map)

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

(defcustom ebuku-database-path
  (cond
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

(defcustom ebuku-post-deletion-point-location 'previous
  "Bookmark to which point should be moved after a deletion."
  :type '(radio (const :tag "Previous" previous)
                (const :tag "Next" next))
  :group 'ebuku)

(defcustom ebuku-recent-count 3
  "Number of recently-added bookmarks to show."
  :type 'integer
  :group 'ebuku)

(defcustom ebuku-refresh-caches-on-results-refresh nil
  "Whether to refresh the `ebuku-bookmarks' and `ebuku-tags' cache variables
when refreshing results.

The time taken to refresh the caches depends on whether `sqlite' is being
used, as determined by the `ebuku-use-sqlite' variable."
  :type 'boolean
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

(defcustom ebuku-sqlite-path (executable-find "sqlite3")
  "Absolute path of the `sqlite3' executable."
  :type 'file
  :group 'ebuku)

(defcustom ebuku-use-sqlite nil
  "Whether to use `sqlite' to update the `ebuku-bookmarks' and `ebuku-tags'
cache variables.

Using `sqlite' rather than `buku' can be several times faster, but the
`sqlite3' executable must be installed separately."
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
    (define-key km (kbd "I") #'ebuku-copy-index)
    (define-key km (kbd "T") #'ebuku-copy-title)
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

(defvar ebuku--new-index nil
  "Internal variable containing the index of the newly-added bookmark.")

(defvar ebuku--results-start nil
  "Internal variable containing buffer line of start of search results.")


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

(defun ebuku--collect-bookmarks-via-sqlite ()
  "Internal function to update `ebuku-bookmarks' cache via `sqlite'."
  (if (not ebuku-sqlite-path)
      (error "Can't find `sqlite3' executable")
    (let ((inhibit-message t))
      (with-temp-buffer
        ;; Use 'US', the Unit Separator character, to separate bookmark fields.
        (call-process ebuku-sqlite-path
                      nil t nil
                      "-separator" "\037"
                      ebuku-database-path
                      "select * from bookmarks;")

        ;; Refresh cache.
        (goto-char (point-min))
        (setq ebuku-bookmarks '())
        (while (re-search-forward (concat "^"
                                          "\\([^\037]+\\)"
                                          "\037"
                                          "\\([^\037]+\\)"
                                          "\037"
                                          "\\([^\037]+\\)"
                                          "\037"
                                          "\\([^\037]*\\)"
                                          "\037"
                                          "\\([^\037]*\\)"
                                          "$")
                                  nil t)
          (let* ((bookmark))
            (setf (map-elt bookmark 'index) (match-string 1))
            (setf (map-elt bookmark 'url) (match-string 2))
            (setf (map-elt bookmark 'title) (match-string 3))
            (setf (map-elt bookmark 'tags) (split-string (match-string 4) "," t))
            (setf (map-elt bookmark 'comment) (match-string 5))
            (setq ebuku-bookmarks (cons bookmark ebuku-bookmarks))))))))

(defun ebuku--collect-tags-via-sqlite ()
  "Internal function to update `ebuku-tags' cache via `sqlite'."
  (if (not ebuku-sqlite-path)
      (error "Can't find `sqlite3' executable")
    (let ((inhibit-message t))
      (with-temp-buffer
        (call-process ebuku-sqlite-path
                      nil t nil
                      ebuku-database-path
                      "select tags from bookmarks;")

        ;; Remove lines with no tags.
        (goto-char (point-min))
        (flush-lines "^,$")
        ;; Delete first ',', then join all lines.
        (goto-char (point-min))
        (delete-char 1)
        (while (re-search-forward ",\n" nil t)
          (replace-match ""))
        ;; Split on ',' to create one tag per line.
        (goto-char (point-min))
        (while (re-search-forward "," nil t)
          (replace-match "\n"))
        ;; Sort lines into lexicographic order.
        (sort-lines nil (point-min) (point-max))
        ;; Remove duplicates.
        (delete-duplicate-lines (point-min) (point-max) nil t)

        ;; Refresh cache.
        (goto-char (point-min))
        (setq ebuku-tags '())
        (while (re-search-forward "^\\(.+\\)$" nil t)
          (setq ebuku-tags (cons (match-string 1) ebuku-tags)))))))

(defun ebuku--copy-component (component)
  "Internal function to copy COMPONENT of bookmark at point to kill ring."
  (let ((index (get-char-property (point) 'buku-index)))
    (if index
        (save-excursion
          (goto-char
           (1+ (previous-single-property-change
                (point)
                'buku-index)))
          (cond
           ((eq component 'index)
            (progn
              (kill-new index)
              (message "Copied: %s" index)))
           ((eq component 'title)
            (goto-char (next-single-property-change (point) 'data))
            (let ((title (get-char-property (point) 'data)))
              (kill-new title)
              (message "Copied: %s" title)))
           ((eq component 'url)
            (forward-line)
            (goto-char (next-single-property-change (point) 'data))
            (let ((url (get-char-property (point) 'data)))
              (kill-new url)
              (message "Copied: %s" url)))))
      (user-error "No bookmark at point"))))

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
            ;; Trim any trailing newlines.
            (goto-char (point-min))
            (while (re-search-forward "^\n$" nil t)
              (replace-match ""))
            ;; Collect bookmark components.
            (goto-char (point-min))
            (re-search-forward
             "^[[:digit:]]+\\.\\s-+\\(.+\\)$" nil t)
            (setq title (match-string 1))
            (re-search-forward
             "^\\s-+> \\(.+\\)$" nil t)
            (setq url (match-string 1))
            (if (re-search-forward
                 "^\\s-+\\+ \\(\\(?:.\\|\n\\)+\\)" nil t)
                (progn
                  (if (match-string 1)
                      (let ((match (match-string 1)))
                        (if (string-match
                             "\\(\\(?:.\\|\n\\)+?\\)\n\\s-+# \\(.+\\)"
                             match)
                            (progn
                              (setq comment (match-string 1 match))
                              (setq tags (match-string 2 match)))
                          (setq comment match)))))
              (if (re-search-forward
                   "^\\s-+\\# \\(.+\\)" nil t)
                  (setq tags (match-string 1)))))
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

(defun ebuku--goto-line (n)
  "Internal function to move to line N in buffer.

The docstring for `goto-line' states that it's for interactive use only,
and suggests instead using the code in the body of this function."
  (goto-char (point-min))
  (forward-line (1- n)))

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
                    (if (string= "[index]" prompt)
                        ""
                      (read-from-minibuffer "Exclude keywords? "))))
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
           "\\(?: \\[\\([[:digit:]]+\\)\\]\\)?"
           ))
         (title "")
         (index "")
         (url "")
         (comment "")
         (tags "")
         (current-index (or ebuku--new-index
                            (ebuku--get-index-at-point)))
         (previous-index (let ((pos (previous-single-property-change
                                     (point)
                                     'buku-index)))
                           (if pos
                               (get-char-property (- pos 2) 'buku-index)
                             nil)))
         (next-index (let ((pos (next-single-property-change
                                 (point)
                                 'buku-index)))
                       (if pos
                           (get-char-property (1+ pos) 'buku-index)
                         nil)))
         (first-result-line (+ ebuku--results-start 2)))
    (setq ebuku--new-index nil)
    (with-temp-buffer
      (if (string= "" exclude)
          (ebuku--call-buku `(,type ,term))
        (ebuku--call-buku `(,type ,term "--exclude" ,exclude)))
      (setq ebuku--last-search `(,type ,prompt ,term ,exclude))
      (if (string= "--print" type)
          (cond
           ((string= "[index]" prompt)
            (setq count "1"))
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
          (ebuku--goto-line ebuku--results-start)
          (beginning-of-line)
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
        (while (re-search-forward
                (concat title-line-re "\n")
                nil
                t)
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
                    (let ((start (line-beginning-position)))
                      (progn
                        (re-search-forward
                         (concat "\\("
                                 "^\\s-+[#]" ; tags line
                                 "\\|"
                                 title-line-re ; new bookmark
                                 "\\|"
                                 "\\'" ; end of buffer
                                 "\\)"))
                        (beginning-of-line)
                        (let* ((end (point))
                               (comment-string
                                (buffer-substring start (- end 2))))
                          (setq comment
                                (progn
                                  (string-match
                                   "^\\s-+[+] "
                                   comment-string)
                                  (substring comment-string
                                             (match-end 0)
                                             nil))))
                        (let ((line (buffer-substring
                                     (line-beginning-position)
                                     (line-end-position))))
                          (cond
                           ((string-match "^\\s-+[#] \\(.*\\)$" line)
                            (setq tags (match-string 1 line)))
                           ((string-match title-line-re line)
                            (forward-line -1))))))
                  ;; It's tags.
                  (progn
                    (string-match "^\\s-*[#] \\(.*\\)$" line)
                    (setq tags (match-string 1 line))))))
          (with-current-buffer "*Ebuku*"
            (let ((inhibit-read-only t))
              (insert (propertize "  --  "
                                  'buku-index index
                                  'help-echo index)
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
                (setq comment (replace-regexp-in-string "\n" "\n      " comment))
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
          (progn
            (if current-index
                (progn
                  (goto-char (point-min))
                  (let ((prop-match
                         (text-property-search-forward
                          'buku-index
                          current-index
                          t)))
                    (if prop-match
                        (goto-char (prop-match-beginning prop-match))
                      (cond
                       ((eq ebuku-post-deletion-point-location 'previous)
                        (if (and previous-index
                                 (setq prop-match
                                       (text-property-search-forward
                                        'buku-index
                                        previous-index
                                        t)))
                            (goto-char (prop-match-beginning prop-match))
                          (ebuku--goto-line first-result-line)))
                       ((eq ebuku-post-deletion-point-location 'next)
                        (if (and next-index
                                 (setq prop-match
                                       (text-property-search-forward
                                        'buku-index
                                        next-index
                                        t)))
                            (goto-char (prop-match-beginning prop-match))
                          (ebuku--goto-line first-result-line)))))))
              (ebuku--goto-line first-result-line))
            (if (eq (window-buffer) (current-buffer))
                (recenter))))))))


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
                    (let ((index (match-string 1)))
                      (if (y-or-n-p
                           (concat
                            "Bookmark already exists at index "
                            index
                            " "
                            "(\""
                            (cdr (assoc
                                  'title
                                  (ebuku--get-bookmark-at-index index)))
                            "\")"
                            "; display? "))
                          (ebuku--search-helper "--print" "[index]" index))
                      (user-error "Bookmark already exists")))
                (re-search-forward "^\\([[:digit:]]+\\)\\. \\(.+\\)$")
                (setq index (match-string 1))
                (setq title (match-string 2))
                (if (re-search-forward "^\\s-+\\+ \\(.+\\)$" nil t)
                    (setq comment (match-string 3))))
            (error "Failed to add bookmark"))))
    (setq title (read-from-minibuffer "Bookmark title? " title))
    (setq tags (mapconcat
                #'identity
                (completing-read-multiple "Bookmark tag(s)? " ebuku-tags)
                ","))
    (setq comment (read-from-minibuffer "Bookmark comment? " comment))
    (if ebuku-retrieve-url-metadata
        (progn
          (with-temp-buffer
            (if (not (ebuku--call-buku `("--update" ,index
                                         "--title" ,title
                                         "--comment" ,comment
                                         "--tag" ,tags)))
                (error "Failed to modify bookmark metadata")
              (progn
                (goto-char (point-min))
                (re-search-forward "^\\([[:digit:]]+\\)\\.")
                (setq ebuku--new-index (match-string 1)))))
          (progn
            (ebuku-refresh)
            (message "Bookmark added.")))
      (progn
        (with-temp-buffer
          (if (not (ebuku--call-buku `("--add" ,url
                                       "--title" ,title
                                       "--tag" ,tags
                                       "--comment" ,comment)))
              (error "Failed to add bookmark")
            (progn
              (goto-char (point-min))
              (re-search-forward "^\\([[:digit:]]+\\)\\.")
              (setq ebuku--new-index (match-string 1))))
          (progn
            (ebuku-refresh)
            (message "Bookmark added.")))))))

(defun ebuku-copy-index ()
  "Copy the index of the bookmark at point to the kill ring."
  (interactive)
  (ebuku--copy-component 'index))

(defun ebuku-copy-title ()
  "Copy the title of the bookmark at point to the kill ring."
  (interactive)
  (ebuku--copy-component 'title))

(defun ebuku-copy-url ()
  "Copy the URL of the bookmark at point to the kill ring."
  (interactive)
  (ebuku--copy-component 'url))

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
                  (tags (mapconcat
                         #'identity
                         (completing-read-multiple
                          "Tags? "
                          ebuku-tags
                          nil
                          nil
                          (cadr (assoc 'tags bookmark)))
                         ","))
                  (comment (read-from-minibuffer
                            "Comment? "
                            (cdr (assoc 'comment bookmark)))))
              (with-temp-buffer
                (if (not (ebuku--call-buku `("--update" ,index
                                             "--title" ,title
                                             "--url" ,url
                                             "--comment" ,comment
                                             "--tag" ,tags)))
                    (error "Failed to update bookmark")))
              (ebuku-refresh)
              (message "Bookmark updated."))
          (error (concat "Failed to get bookmark data for index " index)))))))

(defun ebuku-gather-bookmarks (&optional type term exclude)
  "Return a list of bookmarks.

Each bookmark is an alist with the keys 'title 'url 'index 'tags 'comment.
The bookmarks are fetched from buku with the following arguments:

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
                (setf (map-elt data 'index) (match-string 1))
                (setf (map-elt data 'title) (match-string 2)))
            (setf (map-elt data 'title) (match-string 2))
            (setf (map-elt data 'index) (match-string 3)))
          (re-search-forward "^\\s-+> \\([^\n]+\\)") ; URL
          (setf (map-elt data 'url) (match-string 1))
          (forward-line)
          (when (looking-at "^\\s-+[+] \\(.+\\)$")
            (setf (map-elt data 'comment) (match-string 1))
            (forward-line))
          (when (looking-at "^\\s-+[#] \\(.+\\)$")
            (setf (map-elt data 'tags) (or (split-string
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

(defun ebuku-previous-bookmark ()
  "Move point to the previous bookmark URL."
  (interactive)
  (re-search-forward "^\\s-+http" nil t -1)
  (beginning-of-line)
  (re-search-forward "^\\s-+" nil t 1))

(defun ebuku-refresh ()
  "Refresh the list of search results, based on last search."
  (interactive)
  (if ebuku-refresh-caches-on-results-refresh
      (progn
        (ebuku-update-bookmarks-cache)
        (ebuku-update-tags-cache)))
  (if ebuku--last-search
      (let* ((term (nth 2 ebuku--last-search)))
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
                        (concat
                         "-"
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
  (if ebuku-use-sqlite
      (ebuku--collect-bookmarks-via-sqlite)
    (setq ebuku-bookmarks
          (ebuku-gather-bookmarks
           (or type (nth 0 ebuku-cache-default-args))
           (or term (nth 1 ebuku-cache-default-args))
           (or exclude (nth 2 ebuku-cache-default-args))))))

(defun ebuku-update-tags-cache ()
  "Repopulate the `ebuku-tags' variable."
  (interactive)
  (if ebuku-use-sqlite
      (ebuku--collect-tags-via-sqlite)
    (let ((tags '()))
      (ebuku-update-bookmarks-cache)
      (dolist (bookmark ebuku-bookmarks)
        (setq tags (nconc (map-elt bookmark 'tags) tags)))
      (setq ebuku-tags (sort (seq-uniq tags) 'string-collate-lessp)))))


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
      (ebuku-update-tags-cache)
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
        (setq ebuku--results-start (line-number-at-pos))
        (cond
         ((eq 'all ebuku-display-on-startup)
          (ebuku-show-all))
         ((eq 'recent ebuku-display-on-startup)
          (ebuku-search-on-recent))
         ((eq nil ebuku-display-on-startup)
          (insert "  [ Please specify a search, or press 'r' for recent additions. ]")))
        (ebuku--goto-line ebuku--results-start)
        (add-text-properties (point-min) (point)
                             '(read-only t intangible t))
        (forward-line 2)
        (ebuku--create-mode-menu)
        (setq header-line-format nil)
        (ebuku-mode))
      (switch-to-buffer "*Ebuku*"))))


;; --

(provide 'ebuku)

;;; ebuku.el ends here
