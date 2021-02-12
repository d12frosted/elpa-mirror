For more detailed configuration & usage, visit:
https://github.com/kuanyui/fm-bookmarks.el

Use existing bookmarks of file managers (e.g. Dolphin, Nautilus,
PCManFM) in Dired.

  (add-to-list 'load-path "/path/to/fm-bookmarks.el")
  (require 'fm-bookmarks)
  (setq fm-bookmarks-enabled-file-managers '(kde4 gnome3 pcmanfm custom media))

  ;; Add customized bookmarks
  (setq fm-bookmarks-custom-bookmarks
        '(("Root" . "/")
          ("Tmp" . "/tmp/")
          ))
  ;; Shortcut to open FM bookmark.
  (global-set-key (kbd "C-x `") #'fm-bookmarks)
  ;; Use ` to open FM bookmark in Dired-mode
  (define-key dired-mode-map (kbd "`") #'fm-bookmarks)
