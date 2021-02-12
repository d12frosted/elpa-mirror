Do something like the following to set this up:

(setq calendar-longitude 25.5)
(setq calendar-latitude 17.5)
(setq calendar-location-name "Some place")
(use-package celestial-mode-line
  :config
  (setq global-mode-string '("" celestial-mode-line-string display-time-string))
  (celestial-mode-line-start-timer))

The default icons are:
(defvar celestial-mode-line-phase-representation-alist '((0 . "○") (1 . "☽") (2 . "●") (3 . "☾")))
(defvar celestial-mode-line-sunrise-sunset-alist '((sunrise . "☀↑") (sunset . "☀↓")))

You can get text-only icons as follows:
(defvar celestial-mode-line-phase-representation-alist '((0 . "( )") (1 . "|)") (2 . "(o)") (3 . "|)")))
(defvar celestial-mode-line-sunrise-sunset-alist '((sunrise . "*^") (sunset . "*v")))
