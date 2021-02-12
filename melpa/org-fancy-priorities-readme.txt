
Org mode is great.  It is powerful, versatile and customizable.  Unfortunately,  I
always found the task priorities functionality a bit underwhelming, not in
terms of usability, but more in the visual department.

Inspired by https://github.com/sabof/org-bullets, I created a
minor mode that displays org priorities as custom strings.  This mode does
NOT change your files in any way, it only displays the priority part of a
heading as your preferred string value.

Set the org-fancy-priorities-list variable either with a list of strings in descending
priority importance, or an alist that maps each priority character to a custom string.

(setq org-fancy-priorities-list '("HIGH" "MID" "LOW" "OPTIONAL"))

or

(setq org-fancy-priorities-list '((?A . "❗")
                                 (?B . "⬆")
                                 (?C . "⬇")
                                 (?D . "☕")
                                 (?1 . "⚡")
                                 (?2 . "⮬")
                                 (?3 . "⮮")
                                 (?4 . "☕")
                                 (?I . "Important")))
