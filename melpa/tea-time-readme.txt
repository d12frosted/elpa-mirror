This package allows you to set up time intervals and after this
inteval is elapsed Emacs will notify you with sound and notification.
It could be useful if you like make a tea or if you would like to
be more productive by setting time limit for a task.

If available, notification would be done with great tool
mumbles ( http://www.mumbles-project.org )
If not, then simply use standard emacs message.

; Requirements:

tested on Emacs 23

; Installation:

Add below code in your .emacs

(require 'tea-time)
(setq tea-time-sound "path-to-sound-file")

If you're running on Mac OS X you'll need to add this
(setq tea-time-sound-command "afplay %s")

You can customize the sound command variable to any player you want
where %s will be the sound file configured at tea-time-sound setting
