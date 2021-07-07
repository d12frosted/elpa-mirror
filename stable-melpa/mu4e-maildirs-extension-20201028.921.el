;;; mu4e-maildirs-extension.el --- Show mu4e maildirs summary in mu4e-main-view

;; This file is not part of Emacs

;; Copyright (C) 2013--2017 Andreu Gil Pàmies

;; Filename: mu4e-maildirs-extension.el
;; Version: 0.1
;; Package-Version: 20201028.921
;; Package-Commit: 1167bc6e08996f866e73e9a02f563fd21ac317fd
;; Author: Andreu Gil Pàmies <agpchil@gmail.com>
;; Created: 22-07-2013
;; Description: Show mu4e maildirs summary in mu4e-main-view with unread and
;; total mails for each maildir
;; URL: http://github.com/agpchil/mu4e-maildirs-extension
;; Package-Requires: ((dash "0.0.0"))

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Usage:
;; (require 'mu4e-maildirs-extension)
;; (mu4e-maildirs-extension)

;;; Commentary:

;;; Code:
(require 'mu4e)
(require 'dash)

(defgroup mu4e-maildirs-extension nil
  "Show mu4e maildirs summary in mu4e-main-view with unread and
total mails for each maildir."
  :link '(url-link "https://github.com/agpchil/mu4e-maildirs-extension")
  :prefix "mu4e-maildirs-extension-"
  :group 'external)

(defcustom mu4e-maildirs-extension-action-key "u"
  "Key shortcut to update index and cache."
  :group 'mu4e-maildirs-extension
  :type '(key-sequence))

(defcustom mu4e-maildirs-extension-toggle-maildir-key (kbd "SPC")
  "Key shortcut to expand/collapse maildir at point."
  :group 'mu4e-maildirs-extension
  :type '(key-sequence))

(defcustom mu4e-maildirs-extension-action-text "\t* [u]pdate index & cache\n"
  "Action text to display for updating the index and cache.
If set to 'Don't Display (nil)' it won't be displayed."
  :group 'mu4e-maildirs-extension
  :type '(choice string (const :tag "Don't Display" nil)))

(defcustom mu4e-maildirs-extension-count-command-format
  (concat mu4e-mu-binary " find %s --fields 'i' | wc -l")
  "The command to count a maildir.  [Most people won't need to edit this]."
  :group 'mu4e-maildirs-extension
  :type '(string))

(defcustom mu4e-maildirs-extension-custom-list nil
  "List of folders to show.
If set to nil all folders are shown.

Example:
  '(\"/account1/INBOX\"
    \"/account2/INBOX\")"
  :group 'mu4e-maildirs-extension
  :type '(repeat string))
  ;; :type '(sexp))

(defcustom mu4e-maildirs-extension-ignored-regex
  nil
  "Optional regular expression that is used for filtering list of
maildirs. It's a dynamic alternative to
mu4e-maildirs-extension-custom-list - new maildirs will
automatically appear in the list unless they are explicitly
ignored."
  :group 'mu4e-maildirs-extension
  :type '(choice string (const :tag "Show all maildirs" nil)))

(defcustom mu4e-maildirs-extension-use-bookmarks
  nil
  "If non-nil, show the bookmarks count in the mu4e main view."
  :group 'mu4e-maildirs-extension
  :type 'boolean
  :risky t)

(defcustom mu4e-maildirs-extension-use-maildirs
  t
  "If non-nil, show the maildir summary in the mu4e main view."
  :group 'mu4e-maildirs-extension
  :type 'boolean)

(defcustom mu4e-maildirs-extension-insert-before-str "\n  Misc"
  "The place where the maildirs section should be inserted."
  :group 'mu4e-maildirs-extension
  :type '(choice (const :tag "Basics" "\n  Basics")
                 (const :tag "Bookmarks" "\n  Bookmarks")
                 (const :tag "Misc" "\n  Misc")
                 (const :tag "End of file" "\n")))

(defcustom mu4e-maildirs-extension-bookmark-format " (%u/%t)"
  "The bookmark stats format.

Available formatters:

%u is the unread count
%t is the total count"
  :group 'mu4e-maildirs-extension
  :type '(string))

(defcustom mu4e-maildirs-extension-bookmark-format-spec
  '(lambda(m)
     (list (cons ?u (or (plist-get m :unread) ""))
           (cons ?t (or (plist-get m :total) ""))))
  "A function to build the bookmark format spec."
  :group 'mu4e-maildirs-extension
  :type '(function))

(defcustom mu4e-maildirs-extension-bookmark-hl-regex
  mu4e-maildirs-extension-bookmark-format
  "Regex to highlight when `mu4e-maildirs-extension-bookmark-hl-pred' matches."
  :group 'mu4e-maildirs-extension
  :type '(string))

(defcustom mu4e-maildirs-extension-bookmark-hl-pred
  '(lambda(m)
     (> (or (plist-get m :unread) 0) 0))
  "Predicate function used to highlight."
  :group 'mu4e-maildirs-extension
  :type '(function))

(defcustom mu4e-maildirs-extension-maildir-format "\t%i%p %n (%u/%t)"
  "The maildir format.

Available formatters:

%i is the folder indentation
%p is the maildir prefix
%l is the folder level
%e is the expand flag
%P is the maildir path
%n is the maildir name
%u is the unread count
%t is the total count"
  :group 'mu4e-maildirs-extension
  :type '(string))

(defcustom mu4e-maildirs-extension-maildir-format-spec
  '(lambda(m)
     (list (cons ?i (plist-get m :indent))
           (cons ?p (plist-get m :prefix))
           (cons ?l (plist-get m :level))
           (cons ?e (plist-get m :expand))
           (cons ?P (plist-get m :path))
           (cons ?n (plist-get m :name))
           (cons ?u (or (plist-get m :unread) ""))
           (cons ?t (or (plist-get m :total) ""))))
  "A function to build the maildir format spec."
  :group 'mu4e-maildirs-extension
  :type '(function))

(defcustom mu4e-maildirs-extension-maildir-hl-regex
  mu4e-maildirs-extension-maildir-format
  "Regex to highlight when `mu4e-maildirs-extension-maildir-hl-pred' matches."
  :group 'mu4e-maildirs-extension
  :type '(string))

(defcustom mu4e-maildirs-extension-maildir-hl-pred
  '(lambda(m)
     (> (or (plist-get m :unread) 0) 0))
  "Predicate function used to highlight."
  :group 'mu4e-maildirs-extension
  :type '(function))

(defcustom mu4e-maildirs-extension-before-insert-maildir-hook
  '(mu4e-maildirs-extension-insert-newline-when-root-maildir)
  "Hook called before inserting a maildir."
  :group 'mu4e-maildirs-extension
  :type 'hook)

(defcustom mu4e-maildirs-extension-after-insert-maildir-hook
  '(mu4e-maildirs-extension-insert-newline-when-unread)
  "Hook called after inserting a maildir."
  :group 'mu4e-maildirs-extension
  :type 'hook)

(defcustom mu4e-maildirs-extension-propertize-bm-func
  #'mu4e-maildirs-extension-propertize-bm-handler
  "The function to format the bookmark info.
Default dispays as ' (unread/total)'."
  :group 'mu4e-maildirs-extension
  :type '(function))

(defcustom mu4e-maildirs-extension-propertize-func
  #'mu4e-maildirs-extension-propertize-handler
  "The function to format the maildir info.
Default dispays as '| maildir_name (unread/total)'."
  :group 'mu4e-maildirs-extension
  :type '(function))

(defcustom mu4e-maildirs-extension-maildir-indent 2
  "Maildir indentation."
  :group 'mu4e-maildirs-extension
  :type '(integer))

(defcustom mu4e-maildirs-extension-maildir-indent-char " "
  "The char used for indentation."
  :group 'mu4e-maildirs-extension
  :type '(integer))

(defcustom mu4e-maildirs-extension-default-collapse-level nil
  "The default level to collapse maildirs.
Set `nil' to disable."
  :group 'mu4e-maildirs-extension
  :type '(choice integer nil))

(defcustom mu4e-maildirs-extension-maildir-collapsed-prefix "+"
  "The prefix for collapsed maildir."
  :group 'mu4e-maildirs-extension
  :type '(string))

(defcustom mu4e-maildirs-extension-maildir-expanded-prefix "-"
  "The prefix for expanded maildir."
  :group 'mu4e-maildirs-extension
  :type '(string))

(defcustom mu4e-maildirs-extension-maildir-default-prefix "|"
  "The prefix for default maildir."
  :group 'mu4e-maildirs-extension
  :type '(string))

(defcustom mu4e-maildirs-extension-fake-maildir-separator nil
  "The separator to fake a hierarchy using directory names.
For example:
/Archive
/Archive.foo
/Archive.foo.bar
/Archive.baz

Offlineimap does this when setting `sep = .'."
  :group 'mu4e-maildirs-extension
  :type '(string))

(defcustom mu4e-maildirs-extension-updating-string "\n\t* Updating...\n"
  "The string to show while updating in background."
  :group 'mu4e-maildirs-extension
  :type '(string))

(defcustom mu4e-maildirs-extension-title "  Maildirs\n"
  "The title for the maildirs extension section.
If set to `nil' it won't be displayed."
  :group 'mu4e-maildirs-extension
  :type '(choice string (const :tag "Don't Display" nil)))

(defcustom mu4e-maildirs-extension-hide-empty-maildirs nil
  "Non-nil indicates that maildirs with no new message are hidden."
  :group 'mu4e-maildirs-extension
  :type 'boolean)

(defface mu4e-maildirs-extension-maildir-face
  '((t :inherit mu4e-header-face))
  "Face for a normal maildir."
  :group 'mu4e-maildirs-extension)

(defface mu4e-maildirs-extension-maildir-hl-face
  '((t :inherit mu4e-unread-face))
  "Face for a highlighted maildir."
  :group 'mu4e-maildirs-extension)

(defcustom mu4e-maildirs-extension-parallel-processes 6
  "Max parallel processes."
  :group 'mu4e-maildirs-extension
  :type '(integer))

(defvar mu4e-maildirs-extension-mu-14 (> (string-to-number mu4e-mu-version) 1.3))

(defvar mu4e-maildirs-extension-running-processes 0)

(defvar mu4e-maildirs-extension-queue nil)

(defvar mu4e-maildirs-extension-start-point nil)

(defvar mu4e-maildirs-extension-end-point nil)

(defvar mu4e-maildirs-extension-maildirs nil)

(defvar mu4e-maildirs-extension-bookmarks nil)

(defvar mu4e-maildirs-extension-buffer-name
  ;; mu4e~main-buffer-name used to be private API, but is now public. We
  ;; maintain backward-compatibility with older versions.
  (if (boundp 'mu4e~main-buffer-name)
      mu4e~main-buffer-name
    mu4e-main-buffer-name))

(defvar mu4e-maildirs-extension-index-updated-func
  'mu4e-maildirs-extension-index-updated-handler)

(defvar mu4e-maildirs-extension-main-view-func
  'mu4e-maildirs-extension-main-view-handler)

(defun mu4e-maildirs-extension-index-updated-handler ()
  "Handler for `mu4e-index-updated-hook'."
  (let ((arg (if (get-buffer-window mu4e-maildirs-extension-buffer-name)
                 '(16)
               '(4))))
    (mu4e-maildirs-extension-force-update arg)))

(defun mu4e-maildirs-extension-main-view-handler ()
  "Handler for `mu4e-main-view-mode-hook'."
  (setq mu4e-maildirs-extension-start-point nil)
  (mu4e-maildirs-extension-update)
  (mu4e-maildirs-extension-unqueue-maybe))

(defmacro mu4e-maildirs-extension-with-buffer (&rest body)
  "Switch to `mu4e-maildirs-extension' buffer and yield BODY."
  (declare (indent defun))
  `(let* ((buffer (get-buffer mu4e-maildirs-extension-buffer-name))
          (buffer-window (car (get-buffer-window-list buffer)))
          (old-pos nil)
          (inhibit-read-only t))
     (when buffer
       (cond (buffer-window
              (with-selected-window buffer-window
                (setq old-pos (point))
                (save-excursion
                  ,@body)
                (unless (> old-pos (point-max))
                  (goto-char old-pos))))
             (t
              (with-current-buffer buffer
                (setq old-pos (point))
                (save-excursion
                  ,@body)
                (unless (> old-pos (point-max))
                  (goto-char old-pos))))))))

(defun mu4e-maildirs-extension-unqueue-maybe ()
  (when (< mu4e-maildirs-extension-running-processes
           mu4e-maildirs-extension-parallel-processes)
    (let ((proc-func (pop mu4e-maildirs-extension-queue)))
      (cond (proc-func
             (funcall proc-func)
             (setq mu4e-maildirs-extension-running-processes
                   (1+ mu4e-maildirs-extension-running-processes)))
            (t
             (mu4e-maildirs-extension-update))))))

(defun mu4e-maildirs-extension-bookmark-command (query)
  "Quote the mu bookmark command with arguments in QUERY quoted."
  (format mu4e-maildirs-extension-count-command-format
          (mapconcat #'append
                     (mapcar 'shell-quote-argument (split-string query " "))
                     " ")))

(defun mu4e-maildirs-extension-maildir-command (path flags)
  "Quote the mu maildir command with PATH and FLAGS arguments quoted."
  (let ((query (format "%s %s"
                       (shell-quote-argument (concat "maildir:" (shell-quote-argument path)))
                       (shell-quote-argument flags))))
    (format mu4e-maildirs-extension-count-command-format query)))

(defun mu4e-maildirs-extension-fetch (cmd &optional callback)
  "Execute the mu CMD in a shell process and fetch the result.
Optional call the function CALLBACK on finish."
  (let* ((finish-func `(lambda(proc event)
                         (when (and (memq (process-status proc) '(exit))
                                    (buffer-live-p (process-buffer proc))
                                    ,callback)
                           (let ((buffer (process-buffer proc))
                                 (result nil))
                             (with-current-buffer buffer
                               (setq result
                                     (cond ((= 0 (process-exit-status proc))
                                            (string-to-number
                                             (replace-regexp-in-string "![0-9]"
                                                                       ""
                                                                       (buffer-string))))
                                           (t 0))))
                             (funcall ,callback result)
                             (kill-buffer buffer)
                             (setq mu4e-maildirs-extension-running-processes
                                   (1- mu4e-maildirs-extension-running-processes))
                             (mu4e-maildirs-extension-unqueue-maybe)))))
         (proc `(lambda()
                  (let ((proc (start-process-shell-command "mu4e-maildirs-extension"
                                                           (make-temp-name "mu4e-maildirs-extension")
                                                           ,cmd)))
                    (set-process-sentinel proc ,finish-func)))))

    (add-to-list 'mu4e-maildirs-extension-queue proc t)))

(defun mu4e-maildirs-extension-parse (path)
  "Get the maildir parents of maildir PATH name.
Given PATH \"/foo/bar/alpha\" will return '(\"/foo\" \"/bar\")."
  (let ((name (replace-regexp-in-string "^/" "" path))
        (parents nil)
        (fake-sep mu4e-maildirs-extension-fake-maildir-separator)
        (all-parents nil))
    (setq name (replace-regexp-in-string "\\/\\*$" "" name))
    (setq parents (split-string name "/" t))
    (cond (mu4e-maildirs-extension-fake-maildir-separator
           (mapc #'(lambda(s)
                     (setq all-parents (append all-parents (split-string s fake-sep t))))
                 parents))
          (t (setq all-parents parents)))
    all-parents))

(defun mu4e-maildirs-extension-get-relevant-maildirs ()
  "Get a list of maildirs set (or filtered) according to
  configuration values."
  (or mu4e-maildirs-extension-custom-list
      (let ((list (mu4e-get-maildirs)))
        (if mu4e-maildirs-extension-ignored-regex
            (--remove (string-match mu4e-maildirs-extension-ignored-regex it) list)
          list))))

(defun mu4e-maildirs-extension-paths ()
  "Get maildirs paths."
  (let ((paths (mu4e-maildirs-extension-get-relevant-maildirs))
        (paths-to-show nil))

    (mapc #'(lambda (name)
              (let ((parents (butlast (mu4e-maildirs-extension-parse name)))
                    (path nil))
                (mapc #'(lambda (parent-name)
                          (setq path (concat path "/" parent-name))
                          (unless (member path paths-to-show)
                            (add-to-list 'paths-to-show (format "%s/*" path) t)))
                      parents))

              (add-to-list 'paths-to-show name t))
          paths)
    paths-to-show))

(defun mu4e-maildirs-extension-update-maildir-prefix (m)
  "Get the prefix of maildir M."
  (let* ((l mu4e-maildirs-extension-maildirs)
         (children (mu4e-maildirs-extension-children m l))
         (prefix nil))
    (setq prefix (cond ((and children (plist-get m :expand))
                        mu4e-maildirs-extension-maildir-expanded-prefix)
                       ((and children (not (plist-get m :expand)))
                        mu4e-maildirs-extension-maildir-collapsed-prefix)
                       (t mu4e-maildirs-extension-maildir-default-prefix)))
    (setq m (plist-put m :prefix prefix))
    prefix))

(defun mu4e-maildirs-extension-propertize-handler (m)
  "Propertize the maildir text using M plist."
  (let* ((fmt mu4e-maildirs-extension-maildir-format)
         (hl-regex mu4e-maildirs-extension-maildir-hl-regex)
         (hl-p (funcall mu4e-maildirs-extension-maildir-hl-pred m)))
    (setq fmt (propertize fmt 'face 'mu4e-maildirs-extension-maildir-face))
    (when hl-p
      (setq fmt (replace-regexp-in-string hl-regex
                                          (propertize hl-regex
                                                      'face
                                                      'mu4e-maildirs-extension-maildir-hl-face)
                                          fmt)))
    (format-spec fmt (funcall mu4e-maildirs-extension-maildir-format-spec m))))

(defun mu4e-maildirs-extension-load-bookmarks ()
  "Fetch data or load from cache."
  (unless mu4e-maildirs-extension-bookmarks
    (mapc (lambda(it)
            (let ((query (if mu4e-maildirs-extension-mu-14 (eval (plist-get it :query))
                           (eval (mu4e-bookmark-query it))))
                  (bm (list :data it)))
              (when (stringp query)
                (add-to-list 'mu4e-maildirs-extension-bookmarks bm t)
                (mu4e-maildirs-extension-bm-count bm
                                                  :unread
                                                  (concat "(" query ") AND flag:unread"))
                (mu4e-maildirs-extension-bm-count bm :total query))))
          (mu4e-bookmarks)))
  mu4e-maildirs-extension-bookmarks)

(defun mu4e-maildirs-extension-load-maildirs ()
  "Fetch data or load from cache."
  (unless mu4e-maildirs-extension-maildirs
    (let ((paths (mu4e-maildirs-extension-paths)))
      (setq mu4e-maildirs-extension-maildirs
            (mapcar #'mu4e-maildirs-extension-new-maildir paths))))
  (mapc #'(lambda (it)
            (mu4e-maildirs-extension-count-unread it)
            (mu4e-maildirs-extension-count-total it)
            (mu4e-maildirs-extension-update-maildir-prefix it))
        mu4e-maildirs-extension-maildirs)
  mu4e-maildirs-extension-maildirs)

(defun mu4e-maildirs-extension-action-str (str &optional func-or-shortcut)
  "Custom action without using [.] in STR.
If FUNC-OR-SHORTCUT is non-nil and if it is a function, call it
when STR is clicked (using RET or mouse-2); if FUNC-OR-SHORTCUT is
a string, execute the corresponding keyboard action when it is
clicked."
  (let ((newstr str)
        (map (make-sparse-keymap))
        (func (if (functionp func-or-shortcut)
                  func-or-shortcut
                (if (stringp func-or-shortcut)
                    (lexical-let ((macro func-or-shortcut))
                      (lambda()(interactive)
                        (execute-kbd-macro macro)))))))
    (define-key map [mouse-2] func)
    (define-key map (kbd "RET") func)
    (put-text-property 0 (length newstr) 'keymap map newstr)
    (put-text-property (string-match "[^\n\t\s-].+$" newstr)
      (- (length newstr) 1) 'mouse-face 'highlight newstr)
    newstr))

(defun mu4e-maildirs-extension-run-when-unread (m func args)
  "Call FUNC passing ARGS to it if M contains unread messages."
  (when (or (not mu4e-maildirs-extension-hide-empty-maildirs)
            (> (or (plist-get m :unread) 0) 0))
    (funcall func args)))

(defun mu4e-maildirs-extension-insert-newline-when-root-maildir (m)
  "Insert a newline when M is a root maildir."
  (when (equal (plist-get m :level) 0)
    (insert "\n")))

(defun mu4e-maildirs-extension-insert-newline (m)
  "Insert a newline."
  (insert "\n"))

(defun mu4e-maildirs-extension-insert-newline-when-unread (m)
  "Insert a newline if M contains unread messages."
  (mu4e-maildirs-extension-run-when-unread m #'mu4e-maildirs-extension-insert-newline m))

(defun mu4e-maildirs-extension-count (m key flags)
  "Fetch count results using mu FLAGS and store result in M plist with KEY"
  (let* ((path (plist-get m :path))
         (cmd (mu4e-maildirs-extension-maildir-command path flags))
         (count (plist-get m key))
         (callback `(lambda(result)
                       (let ((m (--first (equal (plist-get it :path) ,path)
                                         mu4e-maildirs-extension-maildirs)))
                         (setq m (plist-put m ,key result))))))
    (unless count
      (mu4e-maildirs-extension-fetch cmd callback))
    (when (numberp count)
      (number-to-string count))))

(defun mu4e-maildirs-extension-count-total (m)
  "Fetch total count of M."
  (or (mu4e-maildirs-extension-count m :total "") ""))

(defun mu4e-maildirs-extension-count-unread (m)
  "Fetch unread count of M."
  (or (mu4e-maildirs-extension-count m :unread "flag:unread") ""))

(defun mu4e-maildirs-extension-propertize-bm-handler (bm)
  "Propertize the bookmark text using BM plist."
  (let* ((fmt mu4e-maildirs-extension-bookmark-format)
         (hl-regex mu4e-maildirs-extension-bookmark-hl-regex)
         (hl-p (funcall mu4e-maildirs-extension-bookmark-hl-pred bm)))
    (setq fmt (propertize fmt 'face 'mu4e-maildirs-extension-maildir-face))
    (when hl-p
      (setq fmt (replace-regexp-in-string hl-regex
                                          (propertize hl-regex
                                                      'face
                                                      'mu4e-maildirs-extension-maildir-hl-face)
                                          fmt)))
    (format-spec fmt (funcall mu4e-maildirs-extension-maildir-format-spec bm))))

(defun mu4e-maildirs-extension-bm-update (bm-point)
  "Update bookmark BM entry at MARKER in mu4e main view."
  (when (cdr bm-point)
    (goto-char (cdr bm-point))
    (delete-region (point) (point-at-eol))
    (insert (funcall mu4e-maildirs-extension-propertize-bm-func (car bm-point)))))

(defun mu4e-maildirs-extension-insert-maildir (m)
  "Insert maildir entry into mu4e main view."
  (insert (mu4e-maildirs-extension-action-str
           (funcall mu4e-maildirs-extension-propertize-func m)
           `(lambda (prefix)
              (interactive "P")
              (let ((maildir ,(plist-get m :path)))
                (if prefix
                    (mu4e~headers-search-execute
                     (format "%s AND flag:unread"
                             (shell-quote-argument (concat "maildir:" maildir)))
                     nil)
                  (mu4e~headers-jump-to-maildir maildir)))))))

(defun mu4e-maildirs-extension-new-maildir (path)
  "Build new maildir plist from maildir PATH."
  (let* ((m nil)
         (current-maildirs (mu4e-maildirs-extension-parse path))
         (level (1- (length current-maildirs))))
    (setq m (plist-put m
                       :name (car (last current-maildirs))))
    (setq m (plist-put m
                       :level
                       level))
    (setq m (plist-put m
                       :expand (or (not mu4e-maildirs-extension-default-collapse-level)
                                   (< level mu4e-maildirs-extension-default-collapse-level))))
    (setq m (plist-put m
                       :path
                       path))
    (setq m (plist-put m
                       :indent
                       (make-string (* mu4e-maildirs-extension-maildir-indent level)
                                    (string-to-char mu4e-maildirs-extension-maildir-indent-char))))
    (setq m (plist-put m
                       :total
                       nil))
    (setq m (plist-put m
                       :unread
                       nil))
    m))

(defun mu4e-maildirs-extension-children (m l)
  "Return a list of children of M."
  (let* ((path (plist-get m :path))
         (sane-path (replace-regexp-in-string "\\/\\*$" "" path)))
    (-filter (lambda(it)
               (let* ((it-path (plist-get it :path)))
                 (and (not (equal it-path path))
                      (string-match sane-path it-path))))
             l)))

(defun mu4e-maildirs-extension-roots (l)
  "Return the list of root maildirs in L."
  (--filter (= (plist-get it :level) 0) l))

(defun mu4e-maildirs-extension-member (path l)
  "Return the maildir with PATH in L."
  (--first (string= (plist-get it :path) path) l))

(defun mu4e-maildirs-extension-is-parent-of (a b)
  "Return t if A is parent of B."
  (let ((path-a (replace-regexp-in-string "\\/\\*$"
                                          ""
                                          (plist-get a :path)))
        (path-b (replace-regexp-in-string "\\/\\*$"
                                          ""
                                          (plist-get b :path))))
    (and (not (equal path-a path-b))
         (string-match path-a path-b))))

(defun mu4e-maildirs-extension-parents (m l)
  "Return the list of parent maildirs of M in L."
  (--filter (mu4e-maildirs-extension-is-parent-of it m) l))

(defun mu4e-maildirs-extension-expanded (l)
  "Return the list of expanded maildirs."
  (-filter (lambda(m)
             (let ((parents (mu4e-maildirs-extension-parents m l)))
               (--all? (plist-get it :expand) parents)))
           l))

(defun mu4e-maildirs-extension-toggle-maildir-at-point (&optional universal-arg)
  ""
  (interactive "P")
  (let ((m nil)
        (l mu4e-maildirs-extension-maildirs)
        (marker (make-marker)))
    (mu4e-maildirs-extension-with-buffer
      (set-marker marker (point-at-bol)))
    (setq m (--first (equal (plist-get it :marker) marker) l))
    (let ((c (when m (mu4e-maildirs-extension-children m l))))
      (when (and m c)
        (setq m (plist-put m :expand (not (plist-get m :expand))))
        (when universal-arg
          (mapc (lambda(it)
                  (when (mu4e-maildirs-extension-children it l)
                    (setq it (plist-put it :expand (plist-get m :expand)))))
                c))))

    (mu4e-maildirs-extension-update)))

(defun mu4e-maildirs-extension-bm-count (bm key flags)
  "Fetch count results using mu FLAGS and store result in M plist with KEY"
  (let* ((data (plist-get bm :data))
         (cmd (mu4e-maildirs-extension-bookmark-command flags))
         (count (plist-get bm key))
         (callback `(lambda(result)
                      (let ((m (--first (equal (plist-get it :data) ',data)
                                        mu4e-maildirs-extension-bookmarks)))
                        (setq m (plist-put m ,key result))))))
    (unless count
      (mu4e-maildirs-extension-fetch cmd callback))
    (when (numberp count)
      (number-to-string count))))

(defun mu4e-maildirs-extension-update ()
  "Insert maildirs summary in `mu4e-main-view'."

  (let ((maildirs (mu4e-maildirs-extension-load-maildirs)))
    (mu4e-maildirs-extension-with-buffer
      (when mu4e-maildirs-extension-use-bookmarks
        (mapc #'mu4e-maildirs-extension-bm-update
              (let (beg bm-points-alist)
                (dolist (bm (mu4e-maildirs-extension-load-bookmarks))
                  (goto-char (if beg beg (point-min)))
                  (setq bm-name (if mu4e-maildirs-extension-mu-14
                                    (plist-get (plist-get bm :data) :name)
                                  (mu4e-bookmark-name (plist-get bm :data))))
                  (setq beg (search-forward bm-name nil t))
                  (push (cons bm beg) bm-points-alist))
                bm-points-alist)))
     (goto-char (point-max))
     (cond ((and mu4e-maildirs-extension-start-point
                 mu4e-maildirs-extension-end-point)
            (delete-region mu4e-maildirs-extension-start-point
                           mu4e-maildirs-extension-end-point))
           (t
            (setq mu4e-maildirs-extension-start-point (make-marker))
            (set-marker mu4e-maildirs-extension-start-point
                        (search-backward mu4e-maildirs-extension-insert-before-str))
            (set-marker-insertion-type mu4e-maildirs-extension-start-point nil)))

     ;; persistent end-point mark
     (setq mu4e-maildirs-extension-end-point (make-marker))
     (set-marker mu4e-maildirs-extension-end-point mu4e-maildirs-extension-start-point)
     (set-marker-insertion-type mu4e-maildirs-extension-end-point t)

     (goto-char mu4e-maildirs-extension-start-point)

     (define-key mu4e-main-mode-map
       mu4e-maildirs-extension-action-key
       'mu4e-maildirs-extension-force-update)

     (when mu4e-maildirs-extension-use-maildirs
       (when mu4e-maildirs-extension-title
        (insert "\n"
                (propertize mu4e-maildirs-extension-title 'face 'mu4e-title-face)))

       (cond (mu4e-maildirs-extension-queue
              (insert mu4e-maildirs-extension-updating-string))
             (mu4e-maildirs-extension-action-text
              (insert "\n"
                      (mu4e~main-action-str mu4e-maildirs-extension-action-text
                                            mu4e-maildirs-extension-action-key))))

       (define-key mu4e-main-mode-map
         mu4e-maildirs-extension-toggle-maildir-key
         'mu4e-maildirs-extension-toggle-maildir-at-point)

       (mapc #'(lambda (m)
                 (run-hook-with-args 'mu4e-maildirs-extension-before-insert-maildir-hook m)
                 (setq m (plist-put m :marker (copy-marker (point-marker))))
                 (mu4e-maildirs-extension-run-when-unread m #'mu4e-maildirs-extension-insert-maildir m)
                 (run-hook-with-args 'mu4e-maildirs-extension-after-insert-maildir-hook m))
             (mu4e-maildirs-extension-expanded maildirs))))))

(defun mu4e-maildirs-extension-force-update (&optional universal-arg)
  "Force update cache and summary.
Default behaviour calls `mu4e-update-index' and update cache/summary if needed.
When preceded with `universal-argument':
4 = clears the cache,
16 = clears the cache and update the summary."
  (interactive "P")
  (cond ((equal universal-arg nil)
         (mu4e-update-index))
        ((equal universal-arg '(4))
         (setq mu4e-maildirs-extension-bookmarks nil)
         (setq mu4e-maildirs-extension-maildirs nil))
        ((equal universal-arg '(16))
         (setq mu4e-maildirs-extension-bookmarks nil)
         (setq mu4e-maildirs-extension-maildirs nil)
         (mu4e-maildirs-extension-update)
         (mu4e-maildirs-extension-unqueue-maybe))))

;;;###autoload
(defun mu4e-maildirs-extension-load ()
  "Initialize."
  (mu4e-maildirs-extension-unload)
  (if (boundp 'mu4e-message-changed-hook)
      (add-hook 'mu4e-message-changed-hook mu4e-maildirs-extension-index-updated-func)
  (add-hook 'mu4e-index-updated-hook mu4e-maildirs-extension-index-updated-func))
  (add-hook 'mu4e-main-mode-hook mu4e-maildirs-extension-main-view-func))

;;;###autoload
(defun mu4e-maildirs-extension-unload ()
  "Un-initialize."
  (if (boundp 'mu4e-message-changed-hook)
      (remove-hook 'mu4e-message-changed-hook mu4e-maildirs-extension-index-updated-func)
    (remove-hook 'mu4e-index-updated-hook mu4e-maildirs-extension-index-updated-func))
  (remove-hook 'mu4e-main-mode-hook mu4e-maildirs-extension-main-view-func))

;;;###autoload
(defalias 'mu4e-maildirs-extension 'mu4e-maildirs-extension-load)

(provide 'mu4e-maildirs-extension)
;;; mu4e-maildirs-extension.el ends here
