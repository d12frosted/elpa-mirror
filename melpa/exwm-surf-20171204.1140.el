;;; exwm-surf.el --- Interface for Surf (surf.suckless.org) under exwm -*-coding: utf-8 -*-

;; Copyright (C) 2017 craven@gmx.net

;; Author: Peter <craven@gmx.net>
;; URL: https://github.com/ecraven/exwm-surf
;; Package-Version: 20171130
;; Package-Requires: ((emacs "24.4") (exwm "0.16"))
;; Version: 0.1
;; Keywords: extensions
;; Created: 2017-11-30

;;; License:

;; Licensed under the GPLv3.

;;; Commentary:
;;
;; Remember that you need to patch surf for history and incremental search to work!
;; See https://github.com/ecraven/exwm-surf/blob/master/exwm-surf.diff
;;
;; Set your history and bookmark file:
;;
;; (setq exwm-surf-history-file "/home/me/.surf/history")
;; (setq exwm-surf-bookmark-file "/home/me/.surf/bookmarks")
;;
;; Get exwm to run `exwm-surf-init' to create the proper key bindings.
;;
;; (add-hook 'exwm-manage-finish-hook 'exwm-surf-init))
;;
;; You can customize `exwm-surf-key-bindings' to modify them to your liking.
;; The defaults are:
;; - C-s / C-r  Incremental search
;; - C-o        Open a new URL
;; - C-M-o      Edit the current URL
;; - M-b        Go to a bookmark
;; - C-M-b      Add a bookmark
;; - C-w        Copy the current URL to the kill ring
;; - C-y        Send Surf to the URL at the front of the kill ring
;; - M-f        Open the current URL in the default browser (See `browse-url')
;;
;; The search recognizes prefixes (g for duckduckgo, go for google, df for dwarf fortress, ...).
;; See `exwm-search-prefixes-alist'.
;;
;;; Code:
(require 'exwm)

(defgroup exwm-surf nil
  "Emacs interface for the surf browser under exwm."
  :group 'multimedia
  :prefix "exwm-surf-")

(defcustom exwm-surf-history-file nil "The location of the surf history file."
  :group 'exwm-surf
  :type 'string)

(defcustom exwm-surf-bookmark-file nil "The location of the surf bookmark file."
  :group 'exwm-surf
  :type 'string)

(defcustom exwm-surf-search-prefixes-alist '(("g" . "http://duckduckgo.com/?q=%s")
                                             ("go" . "http://www.google.com/search?q=%s")
                                             ("arch" . "http://wiki.archlinux.org/index.php/Special:Search?search=%s&go=Go")
                                             ("wen" . "http://en.wikipedia.org/w/index.php?title=Special:Search&search=%s&go=Go")
                                             ("wde" . "http://de.wikipedia.org/w/index.php?title=Special:Search&search=%s&go=Go")
                                             ("aur" . "https://aur.archlinux.org/packages/?O=0&K=%s")
                                             ("ade" . "http://www.amazon.de/s?field-keywords=%s&link_code=qs&index=blended")
                                             ("aus" . "http://www.amazon.com/s?field-keywords=%s&link_code=qs&index=blended")
                                             ("auk" . "http://www.amazon.co.uk/s?field-keywords=%s&link_code=qs&index=blended")
                                             ("osm" . "http://nominatim.openstreetmap.org/search.php?q=%s")
                                             ("df" . "http://dwarffortresswiki.org/index.php?search=%s&title=Special:Search"))
  "Search prefixes for ‘exwm-surf-history’.

%s is replaced by the search string."
  :group 'exwm-surf
  :type '(alist :key-type (string :tag "Shortcut") :value-type (string :tag "URL")))

(defcustom exwm-surf-key-bindings '(("C-s" . exwm-surf-search)
                                    ("C-r" . exwm-surf-search)
                                    ("C-o" . exwm-surf-history)
                                    ("M-C-o" . exwm-surf-edit-url)
                                    ("M-b" . exwm-surf-bookmark)
                                    ("C-M-b" . exwm-surf-add-bookmark)
                                    ("C-w" . exwm-surf-url-to-kill-ring)
                                    ("C-y" . exwm-surf-yank-url)
                                    ("M-f" . exwm-surf-open-in-browser))
  "Key bindings in Surf buffers."
  :group 'exwm-surf
  :type '(alist :key-type (string :tag "Key") :value-type (symbol :tag "Function")))

(defconst exwm-surf-prop-go "_SURF_GO" "X Atom for _SURF_GO.")
(defconst exwm-surf-prop-uri "_SURF_URI" "X Atom for _SURF_URI.")
(defconst exwm-surf-prop-find "_SURF_FIND" "X Atom for _SURF_FIND.")

(defun exwm-surf-read-lines (path)
  "Return a list of lines of file PATH."
  (with-temp-buffer
    (insert-file-contents path)
    (split-string (buffer-string) "\n" t)))

(defun exwm-surf-open-in-browser ()
  "Open the current Surf URL in the default browser.

See `browse-url'."
  (interactive)
  (let* ((winid (exwm-surf-current-buffer-window-id))
         (url (exwm-surf-get-prop exwm-surf-prop-uri winid)))
    (browse-url url)))

(defun exwm-surf-url-to-kill-ring ()
  "Put the current Surf URL into the kill ring."
  (interactive)
  (let* ((winid (exwm-surf-current-buffer-window-id))
         (url (exwm-surf-get-prop exwm-surf-prop-uri winid)))
    (kill-new url)
    (message "%s" url)))

(defun exwm-surf-yank-url ()
  "Send Surf to the yanked URL."
  (interactive)
  (let* ((winid (exwm-surf-current-buffer-window-id))
         (url (or (car kill-ring) "")))
    (exwm-surf-set-prop exwm-surf-prop-go winid url)
    (message "%s" url)))

(defun exwm-surf-history ()
  "Send Surf to a new URL, providing completion from history.

See `exwm-surf-history-file'."
  (interactive)
  (let* ((winid (exwm-surf-current-buffer-window-id))
         (line (completing-read "Go to URL: " (reverse (exwm-surf-read-lines exwm-surf-history-file))))
         (first-space (cl-position ?  line))
         (first-word (substring-no-properties line 0 first-space))
         (second-space (if first-space (cl-position ?  line :start (1+ first-space)) nil))
         (url (if first-space
                  (if second-space
                      (substring-no-properties line (1+ second-space))
                    (substring-no-properties line (1+ first-space)))
                line))
         (search-prefix (assoc-default first-word exwm-surf-search-prefixes-alist)))
    (if search-prefix
        (exwm-surf-set-prop exwm-surf-prop-go winid (url-encode-url (format search-prefix (substring-no-properties line (1+ first-space)))))
      (when (and url
                 (stringp url)
                 (not (string-empty-p url)))
        (exwm-surf-set-prop exwm-surf-prop-go winid url)))))

(defun exwm-surf-current-buffer-window-id ()
  "Get the X window id of the current buffer."
  (if (derived-mode-p 'exwm-mode)
      (exwm--buffer->id (current-buffer))
    (error "Not an exwm window")))

(defun exwm-surf-bookmark ()
  "Send Surf to a new URL, providing completion from bookmarks.
See `exwm-surf-bookmark-file'."
  (interactive)
  (let* ((winid (exwm-surf-current-buffer-window-id))
         (line (completing-read "Go to bookmark: " (reverse (exwm-surf-read-lines exwm-surf-bookmark-file))))
         (first-space (cl-position ?  line))
         (url (substring-no-properties line 0 first-space)))
    (when (and url
               (stringp url)
               (not (string-empty-p url)))
      (exwm-surf-set-prop exwm-surf-prop-go winid url))))

(defun exwm-surf-add-bookmark ()
  "Add a new bookmark to the current Surf URL.
See `exwm-surf-bookmark-file'."
  (interactive)
  (let* ((winid (exwm-surf-current-buffer-window-id))
         (url (exwm-surf-get-prop exwm-surf-prop-uri winid))
         (tags (read-string "Add bookmark with tags: ")))
    (with-temp-buffer
      (insert url " " tags "\n")
      (append-to-file (point-min) (point-max) exwm-surf-bookmark-file))))

(defun exwm-surf-edit-url ()
  "Edit the current Surf URL."
  (interactive)
  (let* ((winid (exwm-surf-current-buffer-window-id))
         (url (read-string "Edit URL: " (exwm-surf-get-prop exwm-surf-prop-uri winid))))
    (when (and url
               (stringp url)
               (not (string-empty-p url)))
      (exwm-surf-set-prop exwm-surf-prop-go winid url))))

(defun exwm-surf-bind-key (key fun)
  "Bind KEY locally in the current Surf buffer to FUN."
  (let ((k (car (string-to-list (kbd key)))))
    (unless (memq k exwm-input-prefix-keys)
      (push k exwm-input-prefix-keys))
    (local-set-key (kbd key) fun)))

;;;###autoload
(defun exwm-surf-init ()
  "Initialize keybindings in a Surf buffer."
  (when (string= "Surf" exwm-class-name)
    (make-local-variable 'exwm-input-prefix-keys)
    (make-local-variable 'exwm-mode-map)
    (mapcar (lambda (binding)
              (exwm-surf-bind-key (car binding) (cdr binding)))
            exwm-surf-key-bindings)))

(defun exwm-surf-set-prop (prop winid value)
  "Set property PROP on X window WINID to VALUE."
  (start-process-shell-command "xprop" nil (format "xprop -id %s -f %s 8s -set %s \"%s\"" winid prop prop value)))

(defun exwm-surf-get-prop (prop winid)
  "Read property PROP from X window WINID."
  (let ((text (shell-command-to-string (format "xprop -notype -id %s %s" winid prop))))
    (string-match "\"\\(.*\\)\"" text)
    (match-string 1 text)))

;; this is accessed dynamically below
(defvar exwm-surf-winid)

(defun exwm-surf-search ()
  "Incremental search in exwm surf buffers."
  (interactive)
  (let ((keymap (copy-keymap minibuffer-local-map))
        (exwm-surf-winid (exwm-surf-current-buffer-window-id)))
    (define-key keymap (kbd "C-s") (lambda () (interactive) (exwm-surf-set-prop exwm-surf-prop-find exwm-surf-winid "!!INCREMENTAL_SEARCH_NEXT!!")))
    (define-key keymap (kbd "C-r") (lambda () (interactive) (exwm-surf-set-prop exwm-surf-prop-find exwm-surf-winid "!!INCREMENTAL_SEARCH_PREVIOUS!!")))
    (let ((minibuffer-local-map keymap))
      (add-hook 'minibuffer-setup-hook 'exwm-surf-minibuffer-setup)
      (add-hook 'minibuffer-exit-hook 'exwm-surf-minibuffer-exit)
      (read-string "Search: "))))

(defun exwm-surf-minibuffer-setup ()
  "Set up the minibuffer for incremental search."
  (add-hook 'post-command-hook 'exwm-surf-post-command))

(defun exwm-surf-minibuffer-exit ()
  "Clean up the minibuffer after incremental search."
  (remove-hook 'post-command-hook 'exwm-surf-post-command)
  (remove-hook 'minibuffer-setup-hook 'exwm-surf-minibuffer-setup)
  (remove-hook 'minibuffer-exit-hook 'exwm-surf-minibuffer-exit)
  (setq exwm-surf-minibuffer-contents "")
  (exwm-surf-set-prop exwm-surf-prop-find exwm-surf-winid "")) ;; exwm-surf-winid is dynamic

(defvar exwm-surf-minibuffer-contents "" "The last contents of the minibuffer that were sent to Surf.")

(defun exwm-surf-post-command ()
  "Send the minibuffer contents to Surf if they have changed."
  (let ((c (minibuffer-contents)))
    (when (not (string= c exwm-surf-minibuffer-contents))
      (exwm-surf-set-prop exwm-surf-prop-find exwm-surf-winid c) ;; exwm-surf-winid is dynamic
      (setq exwm-surf-minibuffer-contents c))))

(provide 'exwm-surf)
;;; exwm-surf.el ends here
