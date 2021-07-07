This is a derived major mode that runs within dired emulating many of the features of
ranger <https://github.com/hut/ranger>. This minor mode shows a stack of the
parent directories and updates the parent buffers while nvaigating the file
system. The preview window takes some of the ideas from Peep-Dired
<https://github.com/asok/peep-dired> to display previews for selected files
in the primary dired buffer. This package tries its best to make a seamless
user experience from ranger created for python.

; FEATURES

Replaces dired buffer with features from Ranger
- show window stack of parent directories
- show preview window of selected directory or file
- fast navigation using vi-like keybindings
- move through navigation history
- copy and paste functionality utilizing a copy ring

; KNOWN ISSUES

- window specific settings needed
 - current tab
 - history
 - current-file
 - cloasing last ranger does not clear variables
 - multiple ranger windows

; HISTORY

version 0.9.1,   2015-07-19 changed package to ranger
version 0.9.2,   2015-07-26 improve exit from ranger, bookmark support
version 0.9.3,   2015-07-31 deer mode, history navigation
version 0.9.4,   2015-08-20 fixed most bugs when reverting from ranger
version 0.9.5,   2015-09-11 delete all accessed buffers, add details to echo
version 0.9.6,   2015-09-13 copy and paste functionality added
version 0.9.7,   2015-10-04 multiple ranger window support, override dired
version 0.9.8,   2015-10-04 ranger is now a major mode
version 0.9.8.1, 2016-08-23 ranger-override-dired-mode
version 0.9.8.4, 2016-10-02 more mappings to match ranger
