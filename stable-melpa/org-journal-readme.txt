Adapted from http://www.emacswiki.org/PersonalDiary

Functions to maintain a simple personal diary / journal in Emacs.
Feel free to use, modify and improve the code! - mtvoid, bastibe

This file is also available from marmalade as
http://marmalade-repo.org/packages/journal. After installing, add
the line (require 'org-journal) to your .emacs or init.el to activate
it. You also need to specify the directory where your journal files
will be saved. You can do this by setting the variable journal-dir
(remember to add a trailing slash). journal-dir is also a
customizable variable. The default value for journal-dir is
~/Documents/journal/.

Inside the journal directory, a separate file is created for each
day with a journal entry, with a file name in the format YYYYMMDD
(this is customizable). Each journal entry is an org-mode file that
begins with a date entry on the top, followed by entries for a
different times. Any subsequent entries on the same day are written
in the same file, with their own timestamp. You can customize the
date and time formats (or remove them entirely). To start writing a
journal entry, press "C-c C-j". You can also open the current day's
entry without adding a new entry with "C-u C-c C-j".

You can browse through existing journal entries on disk via the
calendar. All dates for which an entry is present are highlighted.
Pressing "j" will open it up for viewing. Pressing "C-j" will open
it for viewing, but not switch to it. Pressing "[" or "]" will
select the date with the previous or next journal entry,
respectively. Pressing "i j" will create a new entry for the chosen
date.

TODO items from the previous day will carry over to the current
day. This is customizable through org-journal-carryover-items.

Quick summary:
To create a new journal entry for the current time and day: C-c C-j
To open today's journal without creating a new entry: C-u C-c C-j
In calendar view: j m to mark entries in calendar
                  j r to view an entry in a new buffer
                  j d to view an entry but not switch to it
                  j n to add a new entry
                  j s w to search all entries of the current week
                  j s m to search all entries of the current month
                  j s y to search all entries of the current year
                  j s f to search all entries of all time
                  j s F to search all entries in the future
                  [ to go to previous entry
                  ] to go to next entry
When viewing a journal entry: C-c C-b to view previous entry
                              C-c C-f to view next entry
