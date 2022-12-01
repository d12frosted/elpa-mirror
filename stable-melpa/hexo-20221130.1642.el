;;; hexo.el --- Major mode & tools for Hexo      -*- lexical-binding: t; -*-

;; Author: Ono Hiroko (kuanyui) <azazabc123@gmail.com>
;; Keywords: tools, hexo
;; Package-Version: 20221130.1642
;; Package-Commit: 709c069ec0f9ffd8bc2f8fff18a66d80bc205f6d
;; Package-Requires: ((emacs "24.3"))
;; X-URL: https://github.com/kuanyui/hexo.el
;; Version: {{VERSION}}

;; License: MIT
;; Ono Hiroko (kuanyui) (c) Copyright 2016-2017

;;; Commentary:
;;
;; Screenshots & Documents are available on
;; https://github.com/kuanyui/hexo.el

;; Use Hexo elegantly in Emacs.
;;
;; To start, M-x hexo.  Press h to get help

;;; Code:
(require 'cl-lib)
(require 'tabulated-list)
(require 'ido)
(require 'cl)
(require 'subr-x)

(defgroup hexo nil
  "Manage Hexo with Emacs"
  :prefix "hexo-" :link '(url-link "http://github.com/kuanyui/hexo.el"))

(defgroup hexo-faces nil
  "Faces used in `hexo-mode'"
  :group 'hexo :group 'faces)

(defvar-local hexo-root-dir nil
  "Root directory of a hexo-mode buffer")
(put 'hexo-root-dir 'permanent-local t)

(defvar-local hexo-tabulated-list-entries-filter nil
  "Save a FUNCTION for filtering entries.
See `hexo-setq-tabulated-list-entries'")
(put 'hexo-tabulated-list-entries-filter 'permanent-local t)

(defvar hexo-posix-compatible-shell-file-path nil
  "Forcely specify a POSIX-compatible shell executable path for hexo-mode.
  This is only usable if you've set `shell-file-name' beyond
bash/zsh (ex: fish). hexo.el supports only POSIX-compatible
shell, so please tell me where it is.")

(defvar hexo-shell-command-switch nil
  "Forcely specify the switch for shell command (ex: \"-ic\" for bash).
 If nil, hexo.el will use `shell-command-switch' by default.
Please choose a POSIX-compatible shell.")

(defvar hexo-process nil
  "Hexo process object.")

(defvar hexo-new-format 'md
  "The article format for `hexo-new'. Available formats: `md', `org'")

(defvar hexo-nvm-enabled nil
  "Whether use nvm to run hexo. See `hexo-nvm-use-version'.")


(defvar hexo-nvm-dir (getenv "NVM_DIR")
  "If you want to use nvm to run hexo, the value of this variable should be $NVM_DIR
  (By default, it should be ~/.nvm)")

(defvar hexo-nvm-use-version "6"
  "Specify the Node version with nvm.

This should be a string, which will be passed to \"nvm use VERSION\".
For example, \"6.17.1\", \"6\"

Please see the Hexo official documentation, there's a
compatibility table of Hexo version & Node version:

https://hexo.io/docs/#Required-Node-js-version")

;; ======================================================
;; Faces
;; ======================================================

(defface hexo-status-post
  '((((class color) (background light)) (:bold t :foreground "#008700" :background "#d7ff87"))
    (((class color) (background dark)) (:bold t :foreground "#d7ff00" :background "#4e4e4e")))
  ""
  :group 'hexo-faces)

(defface hexo-status-draft
  '((((class color) (background light)) (:bold t :foreground "#ff5d17" :background "#ffd787"))
    (((class color) (background dark)) (:bold t :foreground "#ff8700" :background "#4e4e4e")))
  ""
  :group 'hexo-faces)

(defface hexo-status-page
  '((((class color) (background light)) (:bold t :foreground "#005f87" :background "#afd7ff"))
    (((class color) (background dark)) (:bold t :foreground "#005f87" :background "#afd7ff")))
  ""
  :group 'hexo-faces)

(defface hexo-tag
  '((((class color) (background light)) (:foreground "#005f87" :background "#afd7ff"))
    (((class color) (background dark)) (:foreground "#87dfff" :background "#3a3a3a":underline t)))
  ""
  :group 'hexo-faces)

(defface hexo-category
  '((((class color) (background light)) (:foreground "#6c0099" :background "#ffd5e5"))
    (((class color) (background dark)) (:foreground "#d18aff" :background "#3a3a3a" :underline t)))
  ""
  :group 'hexo-faces)

(defface hexo-date
  '((((class color) (background light)) (:foreground "#875f00"))
    (((class color) (background dark)) (:foreground "#ffffaf")))
  ""
  :group 'hexo-faces)

(defface hexo-title
  '((((class color) (background light)) (:foreground "#236f73"))
    (((class color) (background dark)) (:foreground "#87d7af")))
  ""
  :group 'hexo-faces)

(defface hexo-mark
  '((((class color) (background light)) (:foreground "#ff4ea3" :bold t))
    (((class color) (background dark)) (:foreground "#ff4ea3" :bold t)))
  ""
  :group 'hexo-faces)

;; ======================================================
;; Small tools
;; ======================================================

(defmacro hexo-shell-env (&rest body)
  "Overwrite variables for shell temporarily"
  `(let ((shell-file-name (or hexo-posix-compatible-shell-file-path shell-file-name))
         (shell-command-switch (or hexo-shell-command-switch shell-command-switch)))
     (progn ,@body)))

(defmacro hexo-mode-only (&rest body)
  `(if (eq major-mode 'hexo-mode)
       (progn ,@body)
     (message "Please run his command in `hexo-mode' buffer (M-x `hexo').")))

(defmacro hexo-mode-article-only (&rest body)
  `(if (tabulated-list-get-id)
       (progn ,@body)
     (message "No article found at this position.")))

(defmacro hexo-repo-only (&rest body)
  `(if (or hexo-root-dir (hexo-find-root-dir))
       (progn ,@body)
     (message "Please run his command under a Hexo repo directory.\nIf still encounter this problem, please make sure this repo has node_modules/ with `hexo` installed.")))

(defmacro hexo-ensure-hexo-executable-available (&rest body)
  "In BODY, variable `hexo-executable-path' is available."
  `(let ((hexo-executable-path (hexo-find-hexo-executable)))
     (if hexo-executable-path
         (progn ,@body)
       (message "Cannot find hexo executable in node_modules/ of this repository nor in $PATH"))))

(defun hexo-find-hexo-executable (&optional from-path)
  "Try to find hexo in node_modules/ directory.
  If not found, try to `executable-find' hexo in your system."
  (let* ((root-dir (hexo-find-root-dir from-path))
         (guessed-hexo (hexo-path-join root-dir "/node_modules/hexo/bin/hexo")))
    (if (and (not (eq system-type 'windows-nt)) ; why windows-nt? I forgot.
             root-dir
             (file-exists-p guessed-hexo))
        guessed-hexo
      (executable-find "hexo"))))

(defun hexo-path-join (&rest paths)
  "Like os.path.join() in Python 3"
  (let* ((-paths (remove-if (lambda (x) (or (null x)
                                            (equal "" x)))
                            paths))
         (raw-head (car -paths))
         (raw-tail (cdr -paths))
         (head (if (string-suffix-p "/" raw-head)
                   (substring raw-head 0 -1)
                 raw-head))
         (tail (mapcar (lambda (x)
                         (cond ((and (string-prefix-p "/" x) (string-suffix-p "/" x))
                                (substring x 1 -1))
                               ((string-prefix-p "/" x) (substring x 1))
                               ((string-suffix-p "/" x) (substring x 0 -1))
                               (t x)))
                       raw-tail)))
    (string-join (cons head tail) "/")))


(defun hexo-message (format-string &rest args)
  "The same as `message', but it `propertize' all ARGS with
  `font-lock-keyword-face'"
  (apply #'message format-string (mapcar
                                  (lambda (arg)
                                    (propertize (format "%s" arg) 'face 'font-lock-keyword-face))
                                  args)))

(defun hexo-get-file-content-as-string (file-path)
  (with-temp-buffer
    (insert-file-contents file-path)
    (buffer-string)))

(defun hexo-overwrite-file-with-string (file-path string)
  "Overwrite the whole file content to STRING.
  If the file has been opened, `save-buffer' it before overwriting.
  Return t if the file is writable, else nil."
  (if (file-writable-p file-path)
      (let ((file-buffer-obj (hexo-get-buffer-if-file-opened file-path)))
        (if file-buffer-obj (with-current-buffer file-buffer-obj (save-buffer)))
        (with-temp-file file-path (insert string))
        (if file-buffer-obj (with-current-buffer file-buffer-obj (revert-buffer nil t t)))
        t)
    nil))

(defun hexo-get-buffer-if-file-opened (file-path)
  "If the FILE-PATH is opened by any buffer, return the buffer
  object."
  (cdr (assoc (file-truename file-path)
              (hexo-get-all-opened-files))))

(defun hexo-get-all-opened-files ()
  "Get all currently opened files in Emacs.
  Return ((FILE-PATH . BUFFER) ...)"
  (cl-remove-if (lambda (x) (null (car x)))
                (mapcar (lambda (buf) (cons (buffer-file-name buf) buf))
                        (buffer-list))))

(defun hexo-get-file-head-lines (file-path &optional n)
  "Get the first N lines of a file as a list."
  (with-temp-buffer
    (insert-file-contents file-path)
    (let ((lines (split-string (buffer-string) "\n" t)))
      (if (null n)
          lines
        (cl-remove-if #'null (cl-subseq lines 0 (min (1- n)
                                                     (length lines))))))))

(defun hexo-get-file-head-lines-as-string (file-path &optional n)
  "Get first N lines of a file as a string."
  (mapconcat #'identity (hexo-get-file-head-lines file-path n) "\n"))

(defun hexo-path (path)
  "Return a formal formatted path string.
  If path is a directory, suffix will be / added. Else, remove /."
  (cond ((null path) nil)
        ((file-directory-p path)
         (if (not (string-suffix-p "/" path))
             (file-truename (concat path "/"))
           (file-truename path)))
        (t
         (if (string-suffix-p "/" path)
             (substring path 0 (1- (length path)))
           path))))

(defun hexo-find-root-dir (&optional from-path)
  "Try to find the root dir of a Hexo repository.
  Output contains suffix '/' "
  (let* ((--from (or from-path hexo-root-dir default-directory))
         (from (hexo-path --from))
         (nodes (split-string from "/")))  ; '("~" "my-hexo-repo" "node_modules")
    ;; Check if `from' contains any parent named `node_modules'.
    ;; If contains, `cd ..` until no `node_modules' exists.
    ;; <ex> ~/my-hexo-repo/node_modules/hexo-generator-category/node_modules/hexo-pagination/
    ;;   => ~/my-hexo-repo/
    (if (member "node_modules" nodes)
        (let* ((from-nth (length (member "node_modules" nodes)))
               (nodes-without-node_modules (reverse (nthcdr from-nth (reverse nodes))))
               (path-string (mapconcat #'identity nodes-without-node_modules "/")))
          (hexo-path path-string))
      (hexo-path (locate-dominating-file from "node_modules/hexo")))))


(defun hexo-ask-for-root-dir ()
  (let ((dir (hexo-find-root-dir (read-directory-name
                                  "Please input the root path of an exist Hexo repository: "))))
    (if dir
        dir
      (progn (message "Seems not a valid Hexo repository. Please try again.")
             (sit-for 5)
             (hexo-ask-for-root-dir)))))

(defun hexo-sort-string-list (string-list)
  (sort string-list #'string<))

(defun hexo-remove-duplicates-in-string-list (string-list)
  (cl-remove-duplicates string-list :test #'string=))

;; ======================================================
;; Main
;; ======================================================

(define-derived-mode hexo-mode tabulated-list-mode "Hexo"
  "Major mode for manage Hexo articles."
  (hl-line-mode 1)
  (hexo-setq-tabulated-list-format)
  (setq tabulated-list-sort-key '("Date" . t)) ;Sort by Date default
  (setq tabulated-list-padding 3)
  (add-hook 'tabulated-list-revert-hook 'hexo-setq-tabulated-list-format nil t) ; `setq' new columns sizes
  (add-hook 'tabulated-list-revert-hook 'hexo-setq-tabulated-list-entries t t) ; `setq' the data
  (tabulated-list-init-header)
  )

(defun hexo-command-revert-tabulated-list ()
  ;; Because `tabulated-list-init-header' must be called *after*
  ;; `tabulated-list-revert' for dynamic columns sizes (see
  ;; `hexo-generate-tabulated-list-format'), but `tabulated-list'
  ;; provide only a hook called *before* revert.
  "Refresh the articles list.
  Disable current filter (ex: tag) is exist."
  (interactive)
  (hexo-mode-only
   (setq hexo-tabulated-list-entries-filter nil) ; remove entries filter <ex> tag filter
   (tabulated-list-revert)              ; native revert function
   (tabulated-list-init-header)))       ; adjust column sizes

(defun hexo-setq-tabulated-list-format ()
  (setq tabulated-list-format (hexo-generate-tabulated-list-format)))

(defun hexo-generate-tabulated-list-format ()
  "This function is for adjusting column size according to
  `window-size'"
  (let* ((status 6)
         (date 11)
         (categories 16)
         (left-width (- (window-width)
                        (+ status date categories 20))) ;20 spaces are remained for Tags
         (filename (min 40
                        (floor (* left-width 0.4))))
         (title (min 48
                     (- left-width filename))))
    (vector (list "Status" status t)
            (list "Filename" filename t)
            (list "Title" title t)
            (list "Date"  date t)
            (list "Categories"  categories t)
            (list "Tags"  0 t))))

(defun hexo-setq-tabulated-list-entries ()
  "This function is used as a hook for `tabulated-list-revert-hook'.
  Also see: `hexo-generate-tabulated-list-entries'"
  (setq tabulated-list-entries
        (hexo-generate-tabulated-list-entries hexo-root-dir hexo-tabulated-list-entries-filter)))

(defun hexo-directory-files (dir-path)
  "The same as `directory-files', but remove:
  0. all not .md files
  1. temporary files
  2. special files (e.g. '..')
  3. invalid files (e.g. a broken symbolic link)
  "
  (if (file-exists-p dir-path)
      (cl-remove-if (lambda (x) (or
                                 (not (file-exists-p x))
                                 (and (not (string-suffix-p ".md" x))
                                      (not (string-suffix-p ".org" x)))
                                 (member (file-name-base x) '("." ".."))
                                 ;;(string-suffix-p "#" x) ;useless
                                 (string-suffix-p "~" x)))
                    (directory-files dir-path 'full))
    '()                                 ;if dir-path is not exist, return nil.
    ))

(defun hexo-generate-tabulated-list-entries (&optional repo-root-dir filter)
  "Each element in `tabulated-list-entries' is like:
  (FileFullPath [\"post\" \"test.md\" \"Title\" \"2013/10/24\" \"category\" \"tag, tag2\"])
  id           ^ entry
  FILTER is a function with one arg."
  (let ((entries (mapcar #'hexo-generate-file-entry-for-tabulated-list
                         (hexo-get-all-article-files repo-root-dir 'include-drafts))))
    (if filter
        (cl-remove-if-not filter entries)
      entries)))

(defun hexo-get-all-article-files (&optional repo-root-dir include-drafts)
  "Return a files list containing full-paths of all articles."
  (let* ((root (or (hexo-find-root-dir repo-root-dir)
                   hexo-root-dir
                   (hexo-find-root-dir)))
         (source-dir (hexo-path-join root "/source/"))
         (posts-dir (hexo-path-join source-dir "/_posts/"))
         (drafts-dir (hexo-path-join source-dir "/_drafts/")))
    (append (hexo-directory-files posts-dir)
            (if include-drafts (hexo-directory-files drafts-dir) '()))
    ))

(defun hexo-remove-regexp (regexp string)
  (replace-regexp-in-string regexp "" string t))

(defun hexo-trim-quotes (string)
  (hexo-remove-regexp "[\"']$" (hexo-remove-regexp "^[\"']" (hexo-trim-spaces string))))

(defun hexo-trim-spaces (string)
  (hexo-remove-regexp " *$" (hexo-remove-regexp "^ *" string)))

(defun hexo-trim (string)
  (hexo-trim-quotes (hexo-trim-spaces string)))

(defun hexo-parse-tags (string)
  "Return a list containing tags"
  (cond ((or (string-match "\\[\\(.*\\)\\]" string) (string-match "\\(.*,.*\\)" string))
         (let* ((raw (match-string 1 string)) ; "this", "is", "tag"
                (raw (replace-regexp-in-string ", " "," raw 'fixedcase)))
           (remove "" (mapcar #'hexo-trim-quotes (split-string raw ",")))))
        ((string-match "^ *$" string)
         '())
        (t
         (list (hexo-trim string)))))

(defun hexo-get-article-info (file-path)
  "Return a list:
  '((title . title)
    (date . date)
    (tags . (tags ...))
    (categories . (categories ...)))"
  (let ((head-lines (hexo-get-file-head-lines file-path 10)))
    (cl-remove-if
     #'null
     (mapcar (lambda (line)
               (cond ((string-match "title: *\\(.+\\)" line)
                      (cons 'title (hexo-trim (match-string 1 line))))
                     ((string-match "date: *<?\\([0-9-/.]+\\)" line) ;hide time
                      (cons 'date (match-string 1 line)))
                     ((string-match "tags: *\\(.+\\)" line)
                      (cons 'tags (hexo-parse-tags (match-string 1 line))))
                     ((string-match "categories: *\\(.+\\)" line)
                      (cons 'categories (hexo-parse-tags (match-string 1 line))))
                     (t nil)))
             head-lines))))

(defun hexo-cdr-assq (key article-info)
  (let ((string (cdr (assq key article-info))))
    (if (null string) "[None]" string)))

(defun hexo-generate-file-entry-for-tabulated-list (file-path)
  "Generate the entry of FILE-PATH for `tabulated-list-mode'.
  <ex> (FileFullPath [\"post\" \"test.md\" \"Title\" \"2013/10/24\" \"category\" \"tag, tag2\"])
  ^ id           ^ entry
  ----------------------------------------------------------
  In `tabulated-list-mode', use `tabulated-list-get-id' and
  `tabulated-list-get-entry' to get it."
  (let ((info (hexo-get-article-info file-path)))
    (list file-path
          (vector
           (if (equal (hexo-get-article-parent-dir-name file-path) "_posts")
               (propertize "post" 'face 'hexo-status-post)
             (propertize "draft" 'face 'hexo-status-draft))
           (file-name-base file-path)
           (propertize (hexo-cdr-assq 'title info) 'face 'hexo-title)
           (propertize (hexo-cdr-assq 'date info) 'face 'hexo-date)
           (mapconcat (lambda (x) (propertize x 'face 'hexo-category))
                      (cdr (assq 'categories info)) "/")
           (mapconcat (lambda (x) (propertize x 'face 'hexo-tag))
                      (hexo-sort-string-list (cdr (assq 'tags info))) " ")
           ))))

(defun hexo-get-attribute-in-file-entry (key file-entry)
  "FILE-ENTRY is a `vector' generated by
  `hexo-generate-file-entry-for-tabulated-list'.

  The struct of FILE-ENTRY is defined in `tabulated-list-format'.
  <ex> [(\"Status\" 6 nil) (\"Filename\" 48 nil) (\"Title\" 48 nil)]
  KEY is a downcased symbol. <ex> 'status "
  (let ((index (cl-position key tabulated-list-format
                            :test (lambda (ele lst)
                                    (equal (capitalize (symbol-name ele))
                                           (car lst))))))
    (aref file-entry index)))

(defun hexo-get-article-parent-dir-name (file-path)
  "Return _posts or _drafts"
  (file-name-nondirectory
   (directory-file-name
    (file-name-directory file-path))))

;;;###autoload
(defun hexo (&optional custom-repo-root-path)
  "Start *Hexo*. "
  (interactive)
  (require 'finder-inf nil t)
  (let* ((hexo-buffer (get-buffer-create "*Hexo*"))
         (win (get-buffer-window hexo-buffer))
         (--hexo-root (or custom-repo-root-path
                          hexo-root-dir ;if already under `hexo-mode', this var should be non-nil
                          (hexo-find-root-dir default-directory) ;Try to find from pwd
                          (hexo-ask-for-root-dir))))
    (with-current-buffer hexo-buffer
      (cd (setq hexo-root-dir --hexo-root))
      (hexo-mode))
    (if win
        (select-window win)
      (switch-to-buffer hexo-buffer))
    (hexo-command-revert-tabulated-list)
    (tabulated-list-print 'remember-pos)))


;; ======================================================
;; Commands for hexo-mode only
;; ======================================================

;;;;; Prefix
(define-key hexo-mode-map (kbd "T") nil)
(define-key hexo-mode-map (kbd "s") nil)
(define-key hexo-mode-map (kbd "M") nil)
;; Files
(define-key hexo-mode-map (kbd "RET") 'hexo-command-open-file)
(define-key hexo-mode-map (kbd "SPC") 'hexo-command-show-article-info)
(define-key hexo-mode-map (kbd "N") 'hexo-new)
(define-key hexo-mode-map (kbd "R") 'hexo-command-rename-file)
(define-key hexo-mode-map (kbd "<f2>") 'hexo-command-rename-file)
(define-key hexo-mode-map (kbd "D") 'hexo-command-delete-file)
;; View
(define-key hexo-mode-map (kbd "g") 'hexo-command-revert-tabulated-list)
(define-key hexo-mode-map (kbd "S") 'tabulated-list-sort)
(define-key hexo-mode-map (kbd "f") 'hexo-command-filter-tag)
;; Edit
(define-key hexo-mode-map (kbd "T T") 'hexo-touch-files-in-dir-by-time)
(define-key hexo-mode-map (kbd "T S") 'hexo-toggle-article-status)
(define-key hexo-mode-map (kbd "t") 'hexo-command-tags-toggler)
;; Marks
(define-key hexo-mode-map (kbd "m") 'hexo-command-mark)
(define-key hexo-mode-map (kbd "u") 'hexo-command-unmark)
(define-key hexo-mode-map (kbd "M a") 'hexo-command-add-tags)
(define-key hexo-mode-map (kbd "M r") 'hexo-command-remove-tags)
;; Server
(define-key hexo-mode-map (kbd "s r") 'hexo-server-run)
(define-key hexo-mode-map (kbd "s s") 'hexo-server-stop)
(define-key hexo-mode-map (kbd "s d") 'hexo-server-deploy)
;; Modes
(define-key hexo-mode-map (kbd "h") 'hexo-command-quick-help)
(define-key hexo-mode-map (kbd "?") 'hexo-command-quick-help)
(define-key hexo-mode-map (kbd "Q") 'kill-buffer-and-window)

(defun hexo-get-help-string ()
  (let* ((help-str (concat
                    (propertize
                     "File             View              Edit                 Mark                Server             Mode\n" 'face 'header-line)
                    "[RET] Open       [  g] Refresh     [T T] Touch time     [  m] Mark          [s r] Run server   [  ?] Show this help\n"
                    "[SPC] Show Info  [  S] Sort        [T S] Toggle status  [  u] Unmark        [s s] Stop server  [  Q] Quit\n"
                    "[  N] New        [  f] Filter tag  [  t] Tags toggler   [M a] Add tags      [s d] Deploy\n"
                    "[  R] Rename                                            [M r] Remove tags\n"
                    "[  D] Delete"))
         (help-str-without-brackets (replace-regexp-in-string "[][]" " " help-str 'fixedcase)))
    (mapc (lambda (begin-end)
            (add-face-text-property (car begin-end)
                                    (cdr begin-end)
                                    '(face 'hexo-status-post)
                                    t help-str-without-brackets))
          (hexo-string-match-positions "\\(\\[.+?\\]\\)" help-str 1)) ;all position
    help-str-without-brackets))

(defun hexo-command-quick-help ()
  "Show quick help message."
  (interactive)
  (hexo-mode-only
   (message (hexo-get-help-string))))

(defun hexo-string-match-positions (regexp string &optional subexp-depth)
  "Get all matched REGEXP position in a STRING.
  SUBEXP-DEPTH is 0 by default."
  (if (null subexp-depth)
      (setq subexp-depth 0))
  (let ((pos 0) result)
    (while (and (string-match regexp string pos)
                (< pos (length string)))
      (let ((m (match-end subexp-depth)))
        (push (cons (match-beginning subexp-depth) (match-end subexp-depth)) result)
        (setq pos m)))
    (nreverse result)))

(defun hexo-command-open-file ()
  "Open the file under the cursor"
  (interactive)
  (hexo-mode-only
   (hexo-mode-article-only
    (find-file (tabulated-list-get-id)))))

(defun hexo-command-delete-file ()
  "Delete the file under the cursor"
  (interactive)
  (hexo-mode-only
   (hexo-mode-article-only
    (if (yes-or-no-p (format "Are you sure to delete file '%s' ?\nATTENTION: THIS ACTION CANNOT BE UNDONE!" (tabulated-list-get-id)))
        (let ((filename (tabulated-list-get-id)))
          (delete-file filename)
          (hexo-command-revert-tabulated-list)
          (message (format "File \"%s\" deleted successfully." filename)))
      (message "Action cancelled; nothing deleted.")
      ))))

(defun hexo-command-rename-file (&optional init-value)
  "Rename (mv) the filename of the article under the cursor."
  (interactive)
  (hexo-mode-only
   (hexo-mode-article-only
    (let ((status (hexo-get-attribute-in-file-entry 'status (tabulated-list-get-entry))))
      (if (or (equal status "draft")
              (and (equal status "post")
                   (yes-or-no-p "This article is a post instead a draft.\nRenaming it may change its permanemt link. Continue?")))
          (let* ((original-file-path (tabulated-list-get-id))
                 (pwd (file-name-directory original-file-path))
                 (original-name-without-ext (or init-value (file-name-base original-file-path)))
                 (original-file-ext (file-name-extension original-file-path t))
                 (new-name-without-ext (read-from-minibuffer
                                        (format "Rename '%s' to: " original-name-without-ext)
                                        original-name-without-ext))
                 (new-file-path (format "%s/%s%s" pwd new-name-without-ext original-file-ext)))
            (if (file-exists-p new-file-path)
                (progn (hexo-message "Filename '%s' already existed. Please try another name." new-name-without-ext)
                       (sit-for 5)
                       (hexo-command-rename-file new-name-without-ext))
              (progn (rename-file original-file-path new-file-path)
                     (revert-buffer)
                     (search-forward new-name-without-ext)
                     (message "Rename successful!"))))
        (message "Rename cancelled."))))))

(defun hexo-get-article-tags-list (file-path)
  (let ((info (hexo-get-article-info file-path)))
    (cdr (assq 'tags info))))

(defun hexo-command-tags-toggler ()
  "Add / Remove tags of a single article.
If you need to add / remove multiple tags on multiple articles,
use (`hexo-command-mark' + `hexo-command-unmark')
& (`hexo-command-add-tags' + `hexo-command-remove-tags') instead."
  (interactive)
  (hexo-mode-only
   (hexo-mode-article-only
    (let* ((file-path (tabulated-list-get-id))
           (old-tags-list (hexo-get-article-tags-list file-path))
           (new-tags-list (hexo--edit-tags-iter old-tags-list (hexo-get-all-tags))))
      (hexo-overwrite-tags-to-file file-path new-tags-list)
      (tabulated-list-revert)
      (message "Done!")))))

(defun hexo-ask-for-tags-list (all-tags &optional selected-tags prompt)
  ;;[TODO] SELECTED-TAGS may rename to INIT-TAGS
  "Interactively ask user for a tags list SELECTED-TAGS"
  (hexo-repo-only
   (let* ((tag (ido-completing-read
                (format "%s (C-j to apply or create tag)\nCurrent tags ==> %s\n"
                        (or prompt "Tags selector")
                        (hexo-format-tags-list selected-tags))
                all-tags nil nil)))
     (cond ((string= "" tag)
            selected-tags)
           ((member tag selected-tags)
            (hexo-ask-for-tags-list all-tags (remove tag selected-tags) prompt))
           (t  ;create new tag
            (hexo-ask-for-tags-list (hexo-remove-duplicates-in-string-list (cons tag all-tags))
                                    (cons tag selected-tags)
                                    prompt))))))


(defun hexo-merge-string-list (list1 list2)
  "Return a sorted string list"
  (hexo-sort-string-list
   (hexo-remove-duplicates-in-string-list (append list1 list2))))

(defun hexo-substract-string-list (list subset-list)
  "Return ( LIST - SUBSET-LIST )"
  (hexo-sort-string-list
   (cl-remove-if (lambda (x) (member x subset-list))
                 list)))

(defun hexo-command-add-tags ()
  "Add tags to all marked (`hexo/marked' & `hexo-command-unmark') articles.
If you want to edit the tags list of a single article, use
`hexo-command-tags-toggler' instead."
  (interactive)
  (hexo-mode-only
   (let ((marked-files (hexo-get-marked-files-path)))
     (if marked-files
         ;; Multiple files
         (let ((adding-tags (hexo-ask-for-tags-list (hexo-get-all-tags)
                                                    nil
                                                    (format "Append what tags to %s articles?" (length marked-files)))))
           (mapc (lambda (file)
                   (let ((merged-tags-for-this-file (hexo-merge-string-list adding-tags (hexo-get-article-tags-list file))))
                     (hexo-overwrite-tags-to-file file merged-tags-for-this-file)))
                 marked-files)
           (tabulated-list-revert))
       ;; Single file
       (message "Please mark files first (press m).
       If you want to edit the tags of a single file, use hexo-command-tags-toggler (press t) instead.")
       ))))

(defun hexo-command-remove-tags ()
  "Remove tags from all marked (`hexo/marked' & `hexo-command-unmark') articles.
If you want to edit the tags list of a single article, use
`hexo-command-tags-toggler' instead."
  (interactive)
  (hexo-mode-only
   (let ((marked-files (hexo-get-marked-files-path)))
     (if marked-files
         ;; Multiple files
         (let ((will-remove-tags (hexo-ask-for-tags-list (hexo-get-all-tags-in-files marked-files)
                                                         nil
                                                         (format "Substract what tags in %s articles? " (length marked-files)))))
           (mapc (lambda (file)
                   (let ((tags-for-this-file (hexo-substract-string-list (hexo-get-article-tags-list file) will-remove-tags)))
                     (hexo-overwrite-tags-to-file file tags-for-this-file)))
                 marked-files)
           (tabulated-list-revert))
       ;; Single file
       (message "Please mark files first (press m).
If you want to edit the tags of a single file, use hexo-command-tags-toggler (press t) instead.")
       ))))

(defun hexo-overwrite-tags-to-file (file-path tags-list)
  "TAGS-LIST is a string list"
  (let* ((formatted-tags-list (hexo-format-tags-list tags-list))
         (file-ext (file-name-extension file-path))
         (old-file-content (hexo-get-file-content-as-string file-path))
         (new-file-content (with-temp-buffer
                             (insert old-file-content)
                             (goto-char (point-min))
                             (if (equal file-ext "org")
                                 (progn (re-search-forward "^ *#\\+tags:.*" nil t)
                                        (replace-match (format "#+TAGS: %s" formatted-tags-list) t))
                               (progn (re-search-forward "^tags:.*" nil t)
                                      (replace-match (format "tags: [%s]" formatted-tags-list) t)))
                             (buffer-string))))
    (hexo-overwrite-file-with-string file-path new-file-content)))

(defun hexo-get-all-tags (&optional root-dir)
  (hexo-sort-string-list
   (hexo-remove-duplicates-in-string-list
    (cl-mapcan (lambda (file-path)
                 (cdr (assq 'tags (hexo-get-article-info file-path))))
               (hexo-get-all-article-files root-dir 'include-drafts)))))

(defun hexo-get-all-tags-in-files (&optional files-list)
  (hexo-sort-string-list
   (hexo-remove-duplicates-in-string-list
    (cl-mapcan (lambda (file-path)
                 (cdr (assq 'tags (hexo-get-article-info file-path))))
               files-list))))

(defun hexo--edit-tags-iter (this-file-tags-list all-tags)
  (let ((tag (ido-completing-read
              (format "Add / Remove Tags (C-j to apply) :\n Current tags => %s\n" this-file-tags-list)
              all-tags nil nil)))
    (cond ((string= "" tag)
           this-file-tags-list)
          ((member tag this-file-tags-list) ;tag exist in this file
           (hexo--edit-tags-iter (remove tag this-file-tags-list) all-tags))
          (t
           (hexo--edit-tags-iter
            (hexo-sort-string-list (cons tag this-file-tags-list))
            (hexo-sort-string-list (hexo-remove-duplicates-in-string-list (cons tag all-tags))))))))

(defun hexo-format-tags-list (tags-list)
  (format "%s"
          (mapconcat #'identity tags-list ", ")))

(defun hexo-command-show-article-info ()
  "Show article's info in minibuffer, so the columns won't be
truncated by `tabulated-list'."
  (interactive)
  (hexo-mode-only
   (hexo-mode-article-only
    (let ((formatted-file-entry (hexo-format-file-entry (tabulated-list-get-entry))))
      (message formatted-file-entry)))))

(defun hexo-format-file-entry (file-entry)
  "FILE-ENTRY is a `vector'. See `hexo-get-attribute-in-file-entry'
 and `hexo-generate-file-entry-for-tabulated-list'"
  (let* ((keys-string-list (cl-map 'list #'car tabulated-list-format)) ; ("Status" "Filename"...)
         (max-length (apply #'max (mapcar #'length keys-string-list))))
    (concat
     (propertize "  File Information\n" 'face 'header-line 'bold t)
     (mapconcat
      (lambda (key-string)
        (concat (propertize
                 (concat "  "
                         ;;align with space (32)
                         (make-string (- max-length (length key-string)) 32)
                         key-string
                         " ") 'face 'linum)
                " "
                (hexo-get-attribute-in-file-entry (intern (downcase key-string)) file-entry)
                "  "))
      keys-string-list
      "\n"
      ))))

(defun hexo-command-filter-tag ()
  "Filter articles by tag"
  (interactive)
  (hexo-mode-only
   (let ((tag (ido-completing-read "Filter tag: "
                                   (hexo-get-all-tags (hexo-find-root-dir)) nil t)))
     (if (string= "" tag)
         (message "No tag inputed, abort.")
       ;; Assign variable `hexo-tabulated-list-entries-filter' as our filter function
       (progn (setq hexo-tabulated-list-entries-filter
                    ;; Hallelujah lexical-binding!
                    (lambda (x) ;car is id (file-path), cdr is ([status ...])
                      (let* ((info (hexo-get-article-info (car x)))
                             (tags-list (cdr (assq 'tags info))))
                        (member tag tags-list))))
              (tabulated-list-revert)
              (hexo-message "Press %s to disable filter" "g"))))))

(defun hexo-command-mark ()
  "Mark the article under cursor."
  (interactive)
  (hexo-mode-only
   (hexo-mode-article-only
    (tabulated-list-put-tag (propertize " m" 'face 'hexo-mark) t))))

(defun hexo-command-unmark ()
  "Unmark the article under cursor."
  (interactive)
  (hexo-mode-only
   (hexo-mode-article-only
    (tabulated-list-put-tag "  " t))))

(defun hexo-get-marked-files-path ()
  (with-current-buffer "*Hexo*"
    (save-excursion
      (goto-char (point-min))
      (let (file-pathes)
        (while (not (eobp))
          (cond ((eq (char-after (1+ (point))) ?m)
                 (push (tabulated-list-get-id) file-pathes)
                 (forward-line))
                (t
                 (forward-line))))
        file-pathes
        ;; [TODO] Maybe show a temp buffer *Marked Files* like `dired-mark-pop-up'?
        ))))


;; ======================================================
;; Universal Commands
;; ======================================================
;; Following commands are available outside hexo-mode.

;;;###autoload
(defun hexo-new ()                      ;[TODO] Add tags when hexo-new
  "Call `hexo new` anywhere as long as in any child directory
 under a Hexo repository.
That's to say, you can use this function to create new post, even though
under theme/default/layout/"
  (interactive)
  (hexo-repo-only
   (hexo-ensure-hexo-executable-available
    (hexo-shell-env
     (let* ((stdout (shell-command-to-string (format "%s new '%s'"
                                                     hexo-executable-path
                                                     (hexo--new-read-url-from-user))))
            (created-md-file-path (progn (string-match "Created: \\(.+\\)$" stdout)
                                         (match-string 1 stdout)))
            (created-org-file-path (concat (file-name-sans-extension created-md-file-path) ".org")))
       (message stdout) ; for debug
       (cond ((eq hexo-new-format 'org)
              (rename-file created-md-file-path created-org-file-path)
              (hexo-command-revert-tabulated-list)
              (previous-line)
              (find-file created-org-file-path)
              (goto-char 0) (replace-regexp "date:.*"
                                            (concat "#+DATE: " (format-time-string "<%Y-%m-%d %a %H:%M>")))
              (goto-char 0) (replace-regexp "^ *tags: *" "#+TAGS: " )
              (goto-char 0) (flush-lines "---")
              (goto-char (point-max))
              (insert "#+LAYOUT: \n#+CATEGORIES: \n")
              (goto-char 0)
              (replace-regexp "title: .+$"
                              (format "#+TITLE: %s"
                                      (read-from-minibuffer "Article Title: "
                                                            (car minibuffer-history))))
              )
             (t
              (hexo-command-revert-tabulated-list)
              (previous-line)
              (find-file created-md-file-path)
              (goto-char 0)
              (replace-regexp "title: .+$"
                              (format "title: \"%s\""
                                      (read-from-minibuffer "Article Title: "
                                                            (car minibuffer-history))))))
       (save-buffer))))))

(defun hexo--new-read-url-from-user (&optional init-content)
  (interactive)
  (let* ((used-urls (mapcar #'file-name-base
                            (hexo-get-all-article-files nil 'include-drafts)))
         (url (read-from-minibuffer "Article URL: " (or init-content ""))))
    (if (member url used-urls)
        (progn (message "This url has been used, please try another one.")
               (sit-for 2)
               (hexo--new-read-url-from-user url))
      url)))


;;;###autoload
(defun hexo-touch-files-in-dir-by-time ()
  "`touch' markdown article files according their \"date: \" to
make it easy to sort file according date in Dired or `hexo-mode'."
  (interactive)
  (hexo-repo-only
   (let ((touch-commands-list (mapcar (lambda (file)
                                        (let ((head (hexo-get-file-head-lines-as-string file 5)))
                                          (if (string-match "^date: \\([0-9]+\\)-\\([0-9]+\\)-\\([0-9]+\\) \\([0-9]+\\):\\([0-9]+\\):\\([0-9]+\\)$" head)
                                              (format "touch -t %s%s%s%s%s.%s %s"
                                                      (match-string 1 head)
                                                      (match-string 2 head)
                                                      (match-string 3 head)
                                                      (match-string 4 head)
                                                      (match-string 5 head)
                                                      (match-string 6 head)
                                                      file)
                                            " ")))    ;If not found "date: ", return an empty command
                                      (hexo-get-all-article-files))))
     (hexo-shell-env (shell-command (mapconcat #'identity touch-commands-list ";")))
     (revert-buffer)
     (message "Done."))))

;;;###autoload
(defun hexo-toggle-article-status ()
  "Move current file between _post and _draft;
You can run this function in dired or a hexo article."
  (interactive)
  (cond ((and (eq major-mode 'hexo-mode) hexo-root-dir)
         (let* ((file-path (tabulated-list-get-id))
                (file-name (file-name-base file-path)))
           (if (hexo--toggle-article-status file-path)
               (progn (tabulated-list-revert)
                      (search-forward file-name nil t))
             (message "Two filenames duplicated in _posts/ and _drafts/. Abort."))))
        ((and (member major-mode '(org-mode markdown-mode gfm-mode))
              (hexo-find-root-dir))
         (let ((new-path (hexo--toggle-article-status (buffer-file-name))))
           (if new-path
               (progn (find-alternate-file new-path)
                      (hexo-message "Now this file is in '%s'"
                                    (hexo-get-article-parent-dir-name new-path)))
             (message "Two filenames duplicated in _posts/ and _drafts/. Abort."))))
        ((and (eq major-mode 'dired-mode)
              (hexo-find-root-dir)
              (or  (string-suffix-p ".md" (dired-get-file-for-visit))
                   (string-suffix-p ".org" (dired-get-file-for-visit)))
              (member (hexo-get-article-parent-dir-name (dired-get-file-for-visit)) '("_posts" "_drafts")))
         (hexo--toggle-article-status (dired-get-file-for-visit)))
        (t
         (message "You can only run this command in either:
1. The buffer of an article
2. Hexo-mode
3. Dired-mode (remember to move your cursor onto a valid .md file first)"))))

(defun hexo--toggle-article-status (file-path)
  "Move file (`rename-file') between _posts and _drafts.
If success, return the new file path, else nil."
  (let* ((from (hexo-get-article-parent-dir-name file-path))
         (to (if (string= from "_posts") "_drafts" "_posts"))
         (to-path (hexo-path-join (hexo-find-root-dir file-path)
                                  "/source/" to (file-name-nondirectory file-path))))
    (if (file-exists-p to-path)
        (prog1 nil
          (message (format "A file with the same name has existed in %s, please rename and try again." to)))
      (prog1 to-path
        (rename-file file-path to-path)
        (hexo-message "Now article '%s' is in '%s'" (file-name-base to-path) to)
        ))))


;; ======================================================
;; Commands for article buffers only
;; ======================================================

;;;###autoload
(defun hexo-update-current-article-date ()
  "Update article's date stamp (at the head) by current time.
Please run this function in the article."
  (interactive)
  (cond
   ((not (member major-mode '(markdown-mode org-mode gfm-mode)))
    (message "Please run this function in a markdown file or org-mode file. Action cancelled."))
   ((yes-or-no-p "This operation may *change the permanent link* of this article, continue? ")
    (save-excursion
      (goto-char (point-min))
      (save-match-data
        (cond ((eq major-mode 'org-mode)
               (let ((current-time (format-time-string "<%Y-%m-%d %a %H:%M>")))
                 (if (not (re-search-forward "#\\+DATE:.+" nil :no-error))
                     (message "Didn't find any time stamp in this article, abort.")
                   (progn (replace-match (concat "#+DATE: " current-time))
                          (save-buffer)
                          (message (concat "Date updated: " current-time))))))
              (t
               (let ((current-time (format-time-string "%Y-%m-%d %H:%M:%S")))
                 (if (not (re-search-forward "date: [0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} [0-9]\\{2\\}:[0-9]\\{2\\}:[0-9]\\{2\\}" nil :no-error))
                     (message "Didn't find any time stamp in this article, abort.")
                   (progn (replace-match (concat "date: " current-time))
                          (save-buffer)
                          (message (concat "Date updated: " current-time))))))))))))


(defun hexo-get-permalink-format (&optional root-or-file-path)
  "Get permalink format string from config file.
<ex> /:year/:month/:day/:title/  =>  /%Y/%m/%d/:title/"
  (let* ((config-file-path (format "%s/_config.yml" (hexo-find-root-dir root-or-file-path)))
         (config-text (with-temp-buffer (insert-file-contents config-file-path)
                                        (buffer-string)))
         (permalink-format-raw (progn (string-match "^permalink: ?\\(.+\\)" config-text)
                                      (match-string 1 config-text)))
         (permalink-format (replace-regexp-in-string
                            ":year" "%Y"
                            (replace-regexp-in-string
                             ":month" "%m"
                             (replace-regexp-in-string
                              ":day" "%d"
                              permalink-format-raw))))
         (root (progn (string-match "^root: \\(.+\\)" config-text)
                      (match-string 1 config-text))))
    (concat root permalink-format)))


(defun hexo-get-article-title-and-permalink (file-path)
  "return a dotted pair (TITLE . PERMALINK)"
  (let* ((head (hexo-get-file-head-lines-as-string file-path 5))
         (date (progn (string-match "date:\\(.+\\)" head)
                      (hexo-trim (match-string 1 head))))
         (title (progn (string-match "title:\\(.+\\)" head)
                       (hexo-trim (match-string 1 head)))))
    (cons title
          (replace-regexp-in-string ":title" (file-name-base file-path)
                                    (format-time-string (hexo-get-permalink-format file-path)
                                                        (apply #'encode-time (parse-time-string date)))))))

(defun hexo-completing-read-post (&optional repo-root-dir)
  "Use `ido-completing-read' to read filename in _posts/.
Return absolute path of the article file."
  (let ((article (format "%s/source/_posts/%s.md"
                         (hexo-find-root-dir repo-root-dir)
                         (ido-completing-read
                          "Select Article: "
                          (mapcar #'file-name-base (hexo-get-all-article-files repo-root-dir nil)) ;not include drafts
                          nil t))))
    (if (file-exists-p article)
        article
      (replace-regexp-in-string "md$"  "org" article))
    ))

(defun  hexo-get-article-title (file-path)
  (let ((head (hexo-get-file-head-lines-as-string file-path 3)))
    (string-match "title:\\(.+\\)" head)
    (hexo-trim (match-string 1 head))))

;;;###autoload
(defun hexo-insert-article-link ()
  "Insert a link to other article in _posts/."
  (interactive)
  (if (or (not (member major-mode '(markdown-mode gfm-mode org-mode)))
          (not (hexo-find-root-dir)))
      (message "This command only usable in a hexo article buffer (markdown or org).")
    (let* ((file-path (hexo-completing-read-post))
           (title+permalink (hexo-get-article-title-and-permalink file-path))
           (title (car title+permalink))
           (permalink (cdr title+permalink))
           (link-format (if (eq major-mode 'org-mode)
                            (list (format "[[%s][%s]]" permalink title)
                                  (format "[[%s]]" permalink))
                          (list (format "[%s](%s)" title permalink)
                                (format "[](%s)" permalink))))
           (pos (point))
           )
      (insert (ido-completing-read "Select one to insert: " link-format)))))

;;;###autoload
(defun hexo-insert-file-link ()
  "Insert the link toward the files in source/ ,
exclude _posts/ & _drafts/"
  (interactive)
  (if (or (not (member major-mode '(markdown-mode gfm-mode org-mode)))
          (not (hexo-find-root-dir)))
      (message "This command only usable in a hexo article buffer (markdown or org-mode).")
    (let* ((source-dir-fullpath (concat (hexo-find-root-dir) "source/"))
           (file-fullpath (file-truename ;[FIXME] Fucking useless ido-read-file-name
                           (ido-read-file-name "Input file path: "
                                               source-dir-fullpath
                                               nil
                                               t
                                               nil
                                               (lambda (x) (not (or (string-match "_posts/" x)
                                                                    (string-match "_drafts/" x)))))))
           (file-link (substring file-fullpath (1- (length source-dir-fullpath))))
           (text (file-name-nondirectory file-fullpath)))
      (insert (ido-completing-read "Select one to insert: "
                                   (list (if (eq major-mode 'org-mode)
                                             (format "[[%s][%s]]" file-link text)
                                           (format "[%s](%s)" text file-link))
                                         file-link))))))

;;;###autoload
(defun hexo-follow-post-link ()
  "`find-file' a markdown format link.
  [FIXME] Currently, this function only support a link with
  file-name as suffix. e.g.
  [Link](/2015/08/19/coscup-2015/)
  [Link](/2015/08/19/coscup-2015)
  [Link](/coscup-2015/)
"
  (interactive)
  (let* ((permalink (hexo-substring-permalink-under-cursor))
         (file-path (if permalink (hexo-get-file-path-from-post-permalink permalink) nil)))
    (cond ((null permalink)
           (message "Cursor is not on a link. Abort"))
          ((and permalink (file-exists-p file-path))
           (find-file file-path)
           (hexo-message "Open '%s'" file-path))
          ((not (file-exists-p file-path))
           (message "The article seems not to exist, or not a file in your hexo repo. Abort")))))

(defun hexo-substring-permalink-under-cursor ()
  "[Link](/2015/coscup-2015/) => /2015/coscup-2015/
Return the link. If not found link under cursor, return nil."
  (save-excursion
    (if (member major-mode '(markdown-mode gfm-mode))
        (let* ((original (point))
               (beg (search-backward "["))
               (end (search-forward ")"))
               (str (buffer-substring beg end))
               (url (progn (string-match "\\[.+?\\](\\(.+?\\))" str)
                           (match-string 1 str))))
          (if (and (>= original beg) (<= original end))
              url
            nil))
      (let* ((original (point))
             (beg (search-backward "[["))
             (end (search-forward "]]"))
             (str (buffer-substring beg end))
             (url (progn (string-match "\\[\\[\\(.+?\\)\\].*" str)
                         (match-string 1 str))))
        (if (and (>= original beg) (<= original end))
            url
          nil)))

    ))

(defun hexo-get-file-path-from-post-permalink (permalink &optional repo-root-dir)
  "/2015/coscup-2015/ <= this is permalink
This is merely resonable for files in _posts/."
  (let* ((filename-without-ext (progn (string-match "/?\\([^/]+\\)/?$" permalink)
                                      (match-string 1 permalink)))
         (filepath-without-ext (format "%s/source/_posts/%s"
                                       (hexo-find-root-dir repo-root-dir)
                                       filename-without-ext)))
    (find-if (lambda (fullpath) (file-exists-p fullpath))
             (mapcar (lambda (ext) (format "%s.%s" filepath-without-ext ext))
                     '("org" "md")))))

;; ======================================================
;; Run Hexo process in Emacs
;; ======================================================

(defvar hexo-process-buffer-name "*hexo-process*")

(defun hexo-open-buffer-and-run-shell-command (command-string &optional repo-path)
  "COMMAND-STRING example:
\"hexo clean && hexo generate && hexo server --debug\""
  (hexo-shell-env
   (if (process-live-p hexo-process)
       (progn (interrupt-process hexo-process)
              (sit-for 0.5)))            ;WTF
   (if (get-buffer hexo-process-buffer-name)
       (kill-buffer hexo-process-buffer-name))
   (let ((buffer-obj (get-buffer-create hexo-process-buffer-name))
         (shell-scripts (hexo-replace-hexo-command-to-path command-string repo-path)))
     (if hexo-nvm-enabled
         (setq shell-scripts
               (format "source %s && nvm use %s && %s"
                       (hexo-path-join hexo-nvm-dir "nvm.sh")
                       hexo-nvm-use-version
                       shell-scripts)))
     (pop-to-buffer buffer-obj)
     (with-current-buffer buffer-obj
       (setq default-directory (hexo-find-root-dir repo-path)))
     (async-shell-command shell-scripts buffer-obj buffer-obj)
     (setq hexo-process (get-buffer-process buffer-obj))
     (set-process-filter hexo-process 'comint-output-filter)
     )))


(defun hexo-replace-hexo-command-to-path (command-string &optional repo-path)
  "Replace all '__HEXO__' in COMMAND-STRING to hexo command's path"
  (hexo-ensure-hexo-executable-available
   (replace-regexp-in-string "__HEXO__" hexo-executable-path command-string t)))

(defun hexo-server-run ()
  "Run a Hexo server process (posts only / posts + drafts)"
  (interactive)
  (hexo-repo-only
   (let ((type (ido-completing-read "[Hexo server] Type: " '("posts-only" "posts+drafts") nil t)))
     (cond ((string= type "posts+drafts")
            (hexo-open-buffer-and-run-shell-command "__HEXO__ clean && __HEXO__ generate && echo '====== START SERVER =====' &&  __HEXO__ server --debug --drafts"))
           ((string= type "posts-only")
            (hexo-open-buffer-and-run-shell-command "__HEXO__ clean && __HEXO__ generate && echo '====== START SERVER =====' &&  __HEXO__ server --debug"))))))

(defun hexo-server-deploy ()
  "Deploy via hexo server."
  (interactive)
  (hexo-repo-only
   (hexo-open-buffer-and-run-shell-command "__HEXO__ clean && __HEXO__ generate && __HEXO__ deploy")))

(defun hexo-server-stop ()
  "Stop all Hexo server processes (posts only / posts + drafts)"
  (interactive)
  (if (process-live-p hexo-process)
      (progn (interrupt-process hexo-process)
             (sit-for 0.5)
             (kill-buffer hexo-process-buffer-name)
             (message "Server stopped ~!"))
    (message "No active server found")))


(provide 'hexo)
;;; hexo.el ends here
