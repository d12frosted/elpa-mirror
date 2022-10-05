;;; epic.el --- Evernote Picker for Cocoa Emacs

;; Copyright (C) 2011-2015 Yoshinari Nomura.
;; All rights reserved.

;; Author:  Yoshinari Nomura <nom@quickhack.net>
;; Created: 2011-06-23
;; Version: 0.2
;; Package-Version: 20170210.23
;; Package-Commit: a41826c330eb0ea061d58a08cc861b0c4ac8ec4e
;; Package-Requires: ((htmlize "1.47"))
;; Keywords: evernote, applescript
;; URL: https://github.com/yoshinari-nomura/epic

;;; Commentary:

;; Epic is a small elisp to access Evernote process via AppleScript.
;; Please check README at https://github.com/yoshinari-nomura/epic/
;; for details.

;;; Code:

(require 'htmlize)

;;;
;;; customizable variables
;;;

;;
;; Send email forwarding to Evernote server by using Mew.
;;

(defvar epic-evernote-mail-address
  "your-evernote-importer-address0@???.evernote.com"
  "Evernote importer address assigned your evernote account.")

(defvar epic-evernote-mail-headers
  '("Message-Id:"
    "Subject:"
    "From:"
    "To:"
    "Cc:"
    "Date:")
  "Mail headers which need to be remained in the head of created note."
  )

;; XXX: some cache control to be added.
(defvar epic-cache-notebooks nil)
(defvar epic-cache-tags      nil)

(defvar epic-default-evernote-stack "Projects")

(defvar epic-sandbox-tmp-directory nil
  "Temporal directory on importing/exporting attachments from/to Evernote.
This directory should be located within the sandbox of Evernote.app
like: ~/Library/Containers/com.evernote.Evernote/Data/epic-tmp")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Notebooks

;;;###autoload
(defun epic-create-notebook (name)
  "Create NAME notebook in Evernote."
  (interactive "sNew notebook name: ")
  (if (epic-notebook-exists-p name)
      (error "Notebook ``%s'' already exists." name)
    (do-applescript (format "
      tell application \"Evernote\"
        create notebook %s
      end tell
      " (epic/as-quote name)))
    (message "Notebook ``%s'' is created." name)))

(defun epic-notebooks ()
  "Return the name list of notebooks in Evernote."
  (or epic-cache-notebooks
      (setq epic-cache-notebooks
            (epic/get-name-list "notebooks"))))

(defun epic-find-notebook-titles-in-stack (&optional stack-name)
  "Return the notebook titles in STACK-NAME.
If STACK-NAME is omitted, ``epic-default-evernote-stack'' is used."
  (epic-find-notebook-titles
   (concat "stack:" (or stack-name epic-default-evernote-stack))))

(defun epic-read-notebook (&optional default)
  "Completing read for notebooks of Evernote.
 This is supposed to work better with anything.el package."
  (epic/completing-read "Notebook: " (epic-notebooks)
                        'epic-notebook-history (or default "")))

(defun epic-notebook-exists-p (name)
  "Return t if notebook NAME exists in Evernote."
  (= 1 ;; XXX: current do-applescript can't return bool.
     (do-applescript (format "
       tell application \"Evernote\"
         if (notebook named %s exists) then
           return 1
         end if
         return 0
       end tell
       " (epic/as-quote name)))))

(defun epic-rename-notebook (old-name new-name)
  "Rename notebook OLD-NAME to NEW-NAME in Evernote.
Both args must be strings.  Do nothing if NEW-NAME already exists."
  (if (and (epic-notebook-exists-p old-name)
           (not (epic-notebook-exists-p new-name)))
      (do-applescript (format "
        tell application \"Evernote\"
          set name of notebook %s to %s
        end tell
        " (epic/as-quote old-name) (epic/as-quote new-name)))))

(defun epic-find-notebook-titles (query-string)
  "Return notebook names that have any notes matched by QUERY-STRING.
QUERY-STRING is detailed in https://dev.evernote.com/doc/articles/search_grammar.php"
  (epic/split-lines
    (do-applescript (format "
      tell application \"Evernote\"
        set noteList to find notes %s
        set notebookTitles to {}
        set retstring to \"\"
        repeat with n in noteList
          set notebookname to (name of (notebook of n))
          if (notebookname is not in notebookTitles) then
            set notebookTitles to notebookTitles & notebookname
          end if
        end repeat
        repeat with n in notebookTitles
          set retstring to retstring & n & \"\n\"
        end repeat
        retstring
      end tell
      " (epic/as-quote query-string)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Notes

(defun epic-selected-note-uris ()
  "Return the URI list of the selected notes in Evernote GUI.
 URIs are in the form of evernote://..."
  (epic/split-lines
   (do-applescript "
      tell application \"Evernote\"
        set noteList  to selection
        set noteLink to \"\"
        repeat with n in noteList
          set noteLink to (noteLink & (note link of n) & \"\n\")
        end repeat
      end tell
      ")))

(defun epic-nullify-note (note-link)
  "Wipe the content of note specified by NOTE-LINK.
It does not delete the note."
  (do-applescript (format "
    tell application \"Evernote\"
      set aNote to find note %s
      if (exists aNote)
        set (HTML content of aNote) to \"\"
      end if
    end tell
    " (epic/as-quote note-link)))
  note-link)

(defun epic-selected-note-list ()
  "Return selected notes as a list of (uri . title) cons cell
 like: ((\"title1\" . \"evernote:///...\")
        (\"title2\" . \"evernote:///...\"))."
  (let ((uris   (epic-selected-note-uris))
        (titles (epic-selected-note-titles))
        (result '()))
    (while (and (car uris) (car titles))
      (setq result (cons (cons (car uris) (car titles)) result))
      (setq uris   (cdr uris))
      (setq titles (cdr titles)))
    result))

(defun epic-selected-note-titles ()
  "Return the titles of selected notes in Evernote."
  (sit-for 0.1) ;; required in case called as DnD-callbacks.
  (epic/split-lines
   (do-applescript "
     tell application \"Evernote\"
       set noteList  to selection
       set noteTitle to \"\"
       repeat with n in noteList
         set noteTitle to (noteTitle & (title of n) & \"\n\")
       end repeat
     end tell
     ")))

(defun epic-find-note-titles (query-string)
  "Return the titles of notes matched by QUERY-STRING in Evernote.
QUERY-STRING is detailed in https://dev.evernote.com/doc/articles/search_grammar.php"
  (sit-for 0.1) ;; required in case called as DnD-callbacks.
  (epic/split-lines
    (do-applescript (format "
      tell application \"Evernote\"
        set noteList to find notes %s
        set noteTitle to \"\"
        repeat with n in noteList
          set noteTitle to (noteTitle & (title of n) & \"\n\")
        end repeat
      end tell
      " (epic/as-quote query-string)))))

(defun epic-open-note (note-link)
  "Open Evernote window of NOTE-LINK."
  (do-applescript (format "
    tell application \"Evernote\"
      set aNote to find note %s
      if (exists aNote)
        open note window with aNote
        activate
        return note link of aNote as string
      end if
    end tell
    " (epic/as-quote note-link))))

(defun epic-note-title (note-link)
  "Return a title string of NOTE-LINK."
  (sit-for 0.1) ;; required in case called as DnD-callbacks.
  (do-applescript (format "
    tell application \"Evernote\"
      set aNote to find note %s
      if (exists aNote)
        return title of aNote as string
      end if
    end tell
    " (epic/as-quote note-link))))

(defun epic-note-tags (note-link)
  "Return a list of tags as string in NOTE-LINK."
  (epic/split-lines
     (do-applescript (format "
       tell application \"Evernote\"
         set aNote to find note %s
         set aList to \"\"
         if (exists aNote)
           set aTagList to (tags of aNote)
           if (exists aTagList)
             repeat with n in aTagList
               set aList to (aList & (name of n) & \"\n\")
             end repeat
             return aList
           end if
         end if
       end tell
       " (epic/as-quote note-link)))))

(defun epic-note-attachments (note-link)
  "Return a list of filenames of attachment in NOTE-LINK."
  (do-applescript (format "
    tell application \"Evernote\"
      set aNote to find note %s
      set aList to \"\"
      if (exists aNote) and (exists attachments of aNote)
        repeat with n in (attachments of aNote)
          write n to %s & \":\" & (filename of n)
          set aList to (aList & (filename of n) & \"\n\")
        end repeat
        return aList
      end if
    end tell
    " (epic/as-quote note-link)
    (epic/as-quote
     (epic/as-expand-file-name (epic/sandbox-tmp-directory))))))

(defun epic-export-note (note-link filename &optional export-tags format)
  "Export a note specified by NOTE-LINK to FILENAME.
If optional argument EXPORT-TAGS is 'true (default), export tags in note.
Optional argument FORMAT is one of 'ENEX or ‌'HTML (default)."
  (do-applescript (format "
    tell application \"Evernote\"
      set aNote to find note %s
      if (exists aNote)
        export {aNote} to (POSIX file %s) %s %s
      end if
    end tell
    " (epic/as-quote note-link)
    (epic/as-quote (expand-file-name filename))
    (epic/as-option "tags" (or export-tags 'true))
    (epic/as-option "format" (or format 'HTML)))))


(defun epic-read-note-title (&optional default)
  "Same as ``read-string'' with the exception of a descriptive prompt."
  (read-string "Title: " default 'epic-title-history default))

;;;###autoload
(defun epic-create-note-from-region (beg end title notebook tags)
  "Create a note article of Evernote from the text between BEG to END.
 Set TITLE (string), NOTEBOOK (stirng), and TAGS (list of string)
 to the article, and store it to Evernote."
  (interactive
   (list (region-beginning) (region-end)
         (epic-read-note-title)
         (epic-read-notebook)
         (epic-read-tag-list)))
  (let* ((htmlize-output-type 'font)
         (html-string (htmlize-region-for-paste beg end)))
    (epic-create-note-from-html-string html-string title notebook tags)))

(defun epic-create-note-from-file (file-name title &optional notebook tags attachments)
  "Create a note aricle of Evernote from the FILE-NAME.
 Set TITLE (stirng), NOTEBOOK (string), and TAGS (list of string)
 to the article, and store it to Evernote."
  (do-applescript (format "
    tell application \"Evernote\"
      set aNote to (create note from file (POSIX file %s) title %s %s %s %s)
      open note window with aNote
      activate
    end tell
    " (epic/as-quote (expand-file-name file-name))
    (epic/as-quote title)
    (epic/as-option "notebook" notebook)
    (epic/as-option "tags" tags)
    (epic/as-option "attachments" attachments))))

(defun epic-create-note-from-html-string (html-string title &optional notebook tags attachments)
  "Create a note aricle of Evernote from the FILE-NAME.
 Set TITLE (stirng), NOTEBOOK (string), and TAGS (list of string)
 to the article, and store it to Evernote."
  (do-applescript (format "
    set noteLink to missing value
    tell application \"Evernote\"
      set aNote to (create note with html %s title %s %s %s %s)
      synchronize
      repeat while noteLink is missing value
        delay 0.5 -- wait for synchronize
        set noteLink to (note link of aNote)
      end repeat
      open note window with aNote
      activate
      return noteLink as string
    end tell
    " (epic/as-quote html-string)
    (epic/as-quote title)
    (epic/as-option "notebook" notebook)
    (epic/as-option "tags" tags)
    (epic/as-option "attachments" attachments))))

(defun epic-append-attachment-to-note (filename note-link)
  "Append FILENAME to an existing note specified by NOTE-LINK."
  (let ((attachment (epic/as-copy-file-to-sandbox filename)))
    (do-applescript (format "
      tell application \"Evernote\"
        set aNote to find note %s
        if (exists aNote)
          open note window with aNote
          activate
          append aNote attachment (POSIX file %s)
          return note link of aNote as string
        else
          return 0
        end if
      end tell
    " (epic/as-quote note-link)
    (epic/as-quote
     (expand-file-name attachment))))))

(defun epic-append-html-to-note (html-string note-link)
  "Append HTML-STRING to an existing note specified by NOTE-LINK."
  (do-applescript (format "
    tell application \"Evernote\"
      set aNote to find note %s
      if (exists aNote)
        append aNote html %s
        return note link of aNote as string
      else
        return 0
      end if
    end tell
    " (epic/as-quote note-link)
    (epic/as-quote html-string))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Sandbox manipulattion

(defun epic/sandbox-tmp-directory ()
  "Return sandbox directory where Evernote has access right."
  (let ((dir (or epic-sandbox-tmp-directory temporary-file-directory)))
    (unless (file-directory-p dir)
      (make-directory dir t))
    dir))

(defun epic/as-sandbox-path-for-attachment (filename)
  "Return new path if FILENAME is located out of the sandbox for Evernote."
  (expand-file-name
   (file-name-nondirectory filename) (epic/sandbox-tmp-directory)))

(defun epic/as-write-region-to-sandbox (start end filename)
  "Write region START to END into FILENAME in the sandbox of Evernote.
If the directory of FILENAME is out of the sandbox, it will be adjusted.
Return new filename in the sandbox."
  (let ((sandbox-file (epic/as-sandbox-path-for-attachment filename)))
    (write-region start end sandbox-file)
    sandbox-file))

(defun epic/as-copy-file-to-sandbox (filename)
  "Copy FILENAME to the sandbox where Evernote can access.
Return new filename in the sandbox."
  (let ((sandbox-file (epic/as-sandbox-path-for-attachment filename)))
    (unless (string= filename sandbox-file)
      (copy-file filename sandbox-file t t))
    sandbox-file))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Tags

(defun epic-tags ()
  "Return the name list of tags in Evernote."
  (or epic-cache-tags
      (setq epic-cache-tags
            (epic/get-name-list "tags"))))

(defun epic-read-tag (&optional default)
  "Completing read for tags of Evernote.
 This is supposed to work better with anything.el package."
  (epic/completing-read "Tag: " (epic-tags) 'epic-tag-history (or default "")))

(defun epic-read-tag-list ()
  "Completing read for tags of Evernote.
 This repeats ``epic-read-tag'' until the input is blank, and returns
 the tags in list-form."
  (let (tag (tag-list '()))
    (while (not (string= "" (setq tag
                                  (epic/completing-read
                                   "Add tag (finish to blank): "
                                   (epic-tags)
                                   'epic-tag-history ""))))
      (setq tag-list (cons tag tag-list))
      (setq tag ""))
    (nreverse tag-list)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; UI Control of Evernote App

;; XXX: I don't want to open another collection window.
;; Hint for fix?
;;   http://discussion.evernote.com/topic/9621-applescript-to-open-specific-notebook/
(defun epic-open-collection-window (query-string)
  "Open Evernote collection window with QUERY-STRING."
  (if (string-match "^evernote://" query-string)
      (do-applescript (format "
        do shell script (\"open \" & %s)
        " (epic/as-quote query-string)))
    (do-applescript (format "
      tell application \"Evernote\"
        open collection window with query string %s
        activate
      end tell
      " (epic/as-quote query-string)))))

;;;###autoload
(defun epic-open-notebook-in-collection-window (notebook-name)
  "Open Evernote notebook window specified by NOTEBOOK-NAME."
  (interactive
   (list (epic-read-notebook)))
  (epic-open-collection-window
   (format "notebook:\"%s\"" notebook-name)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Org mode support

(declare-function org-export-get-environment "ox")
(declare-function org-export-to-buffer "ox")
(declare-function org-add-link-type "org")

;; Org-mode becomes to recognize evernote:// links
(eval-after-load 'org
  '(if (and (boundp 'org-link-protocols)
            (not (assoc "evernote" org-link-protocols)))
       ;; org version 8
       (org-add-link-type "evernote" 'epic-org-evernote-note-open)
     ;; org version 9
     (org-link-set-parameters "evernote"
                              :follow #'epic-org-evernote-note-open)))

;; C-cC-o (org-open-at-point) works on evernote:// links.
(defun epic-org-evernote-note-open (path)
  (browse-url (concat "evernote:" path)))

(defmacro epic/org-header-narrowing (&rest form)
  `(save-excursion
     (save-restriction
       (goto-char (point-min))
       (while (and (looking-at "^#\\+") (not (eobp)))
         (forward-line 1))
       (narrow-to-region (point-min) (point))
       (goto-char (point-min))
       ,@form)))

(defun epic-org-get-link ()
  (epic/org-header-narrowing
   (if (re-search-forward "^#\\+EPIC_LINK:\s*\\([^\n\s]*\\)" nil t)
       (buffer-substring-no-properties (match-beginning 1) (match-end 1)))))

(defun epic-org-put-link (link)
  (if (epic-org-get-link)
      (epic/org-header-narrowing
       (re-search-forward "^#\\+EPIC_LINK:.*$" nil t)
       (replace-match (concat "#+EPIC_LINK: " link)))
    (epic/org-header-narrowing
     (goto-char (point-max))
     (insert (format "#+EPIC_LINK: %s\n" link)))))

;;;###autoload
(defun epic-create-note-from-org-buffer ()
  "Export current org buffer into a note of Evernote in the form of HTML.
The original org buffer is also attached to the exported note.
Epic inserts the link string in the org buffer like:
  #+EPIC_LINK: evernote:///view/123456/s1/xxxxxxxx-xxxx-.../
to keep the correspondence with the previously exported note.
Using this link, epic will export to the same note as before (nullify the
previously exported note and re-export into it)."
  (interactive)
  (let* ((htmlize-output-type 'font)
         (org-html-xml-declaration nil)
         (org-file (buffer-file-name))
         (org-plist (org-export-get-environment 'html))
         (org-title (or (plist-get org-plist :title) ""))
         (note-link nil))
    (if (setq note-link (epic-org-get-link))
        (epic-nullify-note note-link)
      ;; make empty note
      (setq note-link (epic-create-note-from-html-string "" org-title)))
    (epic-append-html-to-note
     (save-excursion
       (save-window-excursion
         (with-current-buffer
             (org-export-to-buffer 'html "*Orglue HTML Export*")
           (buffer-substring (point-min) (point-max)))))
     note-link)
    (epic-org-put-link note-link)
    (epic-append-attachment-to-note
     (epic/as-write-region-to-sandbox
      (point-min) (point-max) (buffer-file-name))
     note-link)))

;;;###autoload
(defun epic-insert-selected-note-as-org-links ()
  "Capture selected notes in Evernote, and insert org-style links."
  (interactive)
  (insert
   (mapconcat
    (lambda (x)
      (format "[[%s][%s]]" (car x) (cdr x)))
    (epic-selected-note-list)
    "\n")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Helm support

(defvar helm-c-source-evernote-tags
  '((name . "Evernote Tags")
    (candidates . epic-tags)
    (migemo)
    (action
     ("Insert Tag Name" .
      (lambda (candidate) (insert "#" candidate) candidate)))
    ))

(defvar helm-c-source-evernote-notebooks
  '((name . "Evernote Notebooks")
    (candidates . epic-notebooks)
    (migemo)
    (action
     ("Pop To Notebook in Evernote" .
      (lambda (candidate)
        (epic-open-notebook-in-collection-window candidate)))
     ("Insert Notebook Name" .
      (lambda (candidate)
        (insert "@" candidate) candidate)))
    ))

(defvar helm-c-source-evernote-notebooks-in-stack
  '((name . "Evernote Notebooks In Stack")
    (candidates . epic-find-notebook-titles-in-stack)
    (migemo)
    (action
     ("Pop To Notebook in Evernote" .
      (lambda (candidate)
        (epic-open-notebook-in-collection-window candidate)))
     ("Insert Notebook Name" .
      (lambda (candidate)
        (insert "@" candidate) candidate)))
    ))

(declare-function helm "helm")

;;;###autoload
(defun epic-helm ()
  "Insert or jump using helm.el package.
Insert the name of selected tag of Evernote with the prefix of `#'.
Insert the name of selected notebook of Evernote with the prefix of `@'.
Pop to Evernote App and open the selected notebook."
  (interactive)
  (helm
   '(
     helm-c-source-evernote-tags
     helm-c-source-evernote-notebooks-in-stack
     helm-c-source-evernote-notebooks
     )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Mew support

(declare-function mew-summary-message-number2 "mew-syntax")
(declare-function mew-summary-folder-name "mew-syntax")
(declare-function mew-summary-set-message-buffer "mew-summary3")
(declare-function mew-header-get-value "mew-header")
(declare-function mew-summary-forward "mew-summary3")
(declare-function mew-header-replace-value "mew-header")
(declare-function mew-header-goto-body "mew-header")

;;;###autoload
(defun epic-mew-create-note (title notebook tags)
  "Import a mail article into the local Evernote app.
 The mail article must be selected and displayed
 by typing ``.'' (mew-summary-analyze-again) in the mew-summary buffer."
  (interactive
   (list (epic-read-note-title (nth 4 (epic/mew-get-message-info)))
         (epic-read-notebook)
         (epic-read-tag-list)))
  (when (memq major-mode '(mew-summary-mode mew-virtual-mode))
    (let* ((msgnum (mew-summary-message-number2))
           (folder-name (mew-summary-folder-name)))
      (save-window-excursion
        (mew-summary-set-message-buffer folder-name msgnum)
        (epic-create-note-from-region
         (window-start (get-buffer-window))
         (point-max) title notebook tags)))))

(defun epic/mew-get-message-info ()
  (when (memq major-mode '(mew-summary-mode mew-virtual-mode))
      (let ((msgnum (mew-summary-message-number2))
            (folder (mew-summary-folder-name))
            (window) (begin) (end) (subject))
        (save-window-excursion
          (mew-summary-set-message-buffer folder msgnum)
          (setq window  (get-buffer-window))
          (setq begin   (window-start window))
          (setq end     (point-max))
          (setq subject (mew-header-get-value "Subject:")))
        (list folder msgnum begin end subject))))

(defun epic/mew-get-message-header-as-string (folder-name msgnum)
  (save-window-excursion
    (mew-summary-set-message-buffer folder-name msgnum)
    (mapconcat (lambda (header)
                 (let (value)
                   (if (setq value (mew-header-get-value header))
                       (format "%s %s\n" header value))))
               epic-evernote-mail-headers
               "")))

;;;###autoload
(defun epic-mew-forward-to-evernote ()
  "Foward a mail to Evernote with the original headers."
  (interactive)
  (when (memq major-mode '(mew-summary-mode mew-virtual-mode))
    (let* ((msgnum (mew-summary-message-number2))
           (folder-name (mew-summary-folder-name))
           (mew-forward-string "")
           (mew-ask-send nil)
           (headers (epic/mew-get-message-header-as-string folder-name msgnum)))
      (mew-summary-forward)
      (mew-header-replace-value "To:" epic-evernote-mail-address)
      (mew-header-goto-body)
      (insert headers)
      (insert " \n")
      (goto-char (point-min))
      (search-forward-regexp "^Subject: " nil t)
      ;; (mew-draft-send-message)
      )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Helpers for Applescript

(defmacro epic/as-tell-evernote (body &rest params)
  `(format
     (concat "tell application \"Evernote\"\n"
             ,body
             "end tell\n")
     ,@params))

(defun epic/get-name-list (obj-name)
  "Return the name list of tags or notebooks in Evernote.
 OBJ-NAME must be ``tags'' or ``notebooks''"
  (epic/split-lines
    (do-applescript (format "
      tell application \"Evernote\"
        set retval to \"\"
        set aList to %s
        repeat with x in aList
          set retval to (retval & (name of x) & \"\n\")
        end repeat
      end tell
      " obj-name))))

(defun epic/as-quote (obj)
  "Make AppleScript literals from lisp OBJ (list, string, integer, symbol)."
  (cond
   ((stringp obj) ;; (["\]) -> \$1
    (format "\"%s\"" (replace-regexp-in-string "[\"\\]" "\\\\\\&" obj)))
   ((listp obj)
    (concat "{" (mapconcat 'epic/as-quote obj ", ") "}"))
   ((eq t obj)
    "true")
   (t ;; integer or symbol assumed
    (format "%s" obj))
   ))

(defun epic/as-option (opt-name opt-value)
  "Make AppleScript optional OPT-NAME phrase if OPT-VALUE is not blank."
  (if (or (null opt-value)
          (and (stringp opt-value)
               (string= opt-value "")))
      ""
    (format "%s %s" opt-name (epic/as-quote opt-value))))

(defun epic/as-expand-file-name (path)
  "Convert PATH from POSIX style to AppleScript style.
Example: ~/Library/Containers/com.evernote.Evernote/Data/epic-tmp is
converted to Users:nom:Containers:com.evernote.Evernote:Data:epic-tmp."
  (substring (replace-regexp-in-string "/" ":" (expand-file-name path)) 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; for debug

(defun epic/as-quote-test (obj)
  (do-applescript (format "return %s" (epic/as-quote obj))))

(defconst epic/as-quote-script
"
on escape_string(str)
  set text item delimiters to \"\"
  set escaped to \"\"
  repeat with c in text items of str
    if c is in {quote, \"\\\\\"} then
      set c to \"\\\\\" & c
    end if
    set escaped to escaped & c
  end repeat
end escape_string

on emacs_converter(obj)
  set c to (class of obj)
  if c is in {real, integer, number} then
    return obj
  else if c is in {text, string} then
    return quote & escape_string(obj) & quote
  else if obj = {} then
    return \"()\"
  else if c is in {boolean}
    if obj then
      return \"t\"
    else
      return \"nil\"
    end if
  else if c is in {list} then
    set res to \"(\"
    repeat with e in obj
      set res to (res & emacs_converter(e) & \" \")
    end repeat
    set res to (res & \")\")
    return res
  end if
end emacs_converter
")

(defun epic/test (obj)
  (do-applescript
   (concat epic/as-quote-script
           (format "emacs_converter(%s)" (epic/as-quote obj)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Misc

(defun epic/chomp (str &optional LF)
  (if (and (< 0 (length str)) (string= (substring str -1) (or LF "\n")))
      (substring str 0 -1)
    str))

(defun epic/split-lines (lines &optional LF)
  (and lines (not (string= lines ""))
       (split-string (epic/chomp lines) (or LF "\n"))))

(defun epic/completing-read (prompt collection hist &optional default)
  "Completing read for getting along with migemo and anything.el package."
  (let ((anything-use-migemo t))
    (completing-read prompt collection nil 'force
                     nil hist default)))

(provide 'epic)

;;; Copyright Notice:

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;; 3. Neither the name of the team nor the names of its contributors
;;    may be used to endorse or promote products derived from this software
;;    without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE TEAM AND CONTRIBUTORS ``AS IS'' AND
;; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
;; PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE TEAM OR CONTRIBUTORS BE
;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
;; BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
;; OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
;; IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; epic.el ends here
