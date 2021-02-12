
This minor mode syncs DropBox notes from mobile devices into org
datetree file that can be part of org agenda. The minor mode starts
a daemon that periodically scans the note directory.

** Justification

I wanted to collect together all interesting articles I saw reading
news on my phone applications. I was already using Org mode to keep
notes in my computer.

The [[http://orgmode.org/manual/MobileOrg.html][MobileOrg]] app in
my Android phone is fiddly and does not do things the way I want,
so this was a good opportunity to learn lisp while doing something
useful.

** Sharing notes

On Android phones, installing Dropbox client also adds Dropbox as
one of the applications that can be used to share articles from
many news applications (e.g. BBC World News, Flipboard). In
contrast to many other options, Dropbox saves these links as plain
text files -- a good starting point for including them into
org-mode.

Org mode has a date-ordered hierachical file structure called
datetree that is ideal for storing notes and links. This
org-dropbox-mode code reads each note in the Dropbox notes folder,
formats them to an org element, and refiles them to a correct place
in a datetree file for easy searching through org-agenda commands.

Each new org headline element gets an inactive timestamp that
corresponds to the last modification time of the note file.

The locations in the filesystem are determined by two customizable
variables -- by default both pointing inside Dropbox:

#+BEGIN_EXAMPLE
  org-dropbox-note-dir      "~/Dropbox/notes/"
  org-dropbox-datetree-file "~/Dropbox/org/reference.org"
#+END_EXAMPLE

Since different programmes format the shared link differently, the
code tries its best to make sense of them. A typical note has the
name of the article in the first line and the link following it
separated by one or two newlines. The name is put to the header,
multiple new lines are reduced to one, and the link is followed by
the timestamp. If the title uses dashes (' - '), exclamation marks
('! '), or colons (': '), they are replaced by new lines to wrap
the trailing text into the body. In cases where there is no text
before the link, the basename of the note file is used as the
header.

After parsing, the source file is removed from the note directory.

Note that most of the time the filename is ignored. The only
absolute requirement for the filename is that it has to be unique
within the directory. Filename is used as an entry header only if
the file does not contain anything usefull, i.e. the content is
plain URL.

** Usage

Set up variables =org-dropbox-note-dir= and
=org-dropbox-datetree-file= to your liking. Authorize your devices
to share that Dropbox directory. As long as you save your notes in
the correct Dropbox folder, they are copied to your computer for
processing and deletion.

The processing of notes starts when you enable the minor mode
org-dropbox-mode in Emacs, and stops when you disable it. After
every refiler run, a message is printed out giving the number of
notes processed.

An internal timer controls the periodic running of the notes
refiler. The period is set in customizable variable
=org-dropbox-refile-timer-interval= to run by default every hour
(3600 seconds).

** Disclaimer

This is first time I have written any reasonable amount of lisp
code, so writing a whole package was a jump in the dark. The code has
been running reliably for some time now, but if you want to try the
code and be absolutely certain you do not lose your notes, comment
form =(delete-file file)= from the code.

There are undoubtedly many things that can be done better. Feel
free to raise issues and submit pull requests.


This file is not a part of GNU Emacs.
