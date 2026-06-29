Notes-mode
----------
by John Heidemann, <johnh@isi.edu>

For documentation, see
	notes-mode.info
	HTML/notes-mode.html
or	<http://www.isi.edu/~johnh/SOFTWARE/NOTES_MODE/>


 WHAT'S NEW IN NOTES-MODE?
 -------------------------
 
Changed (2014-12-19): version 1.30
 
Added support for EasyPG.
Support for mailcrypt remains, but that library has seen no progress since 2002.
Support for npgp is gone.
 
 
WHAT IS NOTES-MODE?
-------------------

(From the info documentation)

Notes-mode is an indexing system for on-line note-taking.
Notes-mode is composed of two parts, the visible part, a major-mode for
emacs to aid note-taking; and the invisible part, scripts which
periodically index your notes for you.

For more sales, including
	Why keep notes?
	Why keep notes on-line?
	Why keep notes with notes-mode?
see <http://www.isi.edu/~johnh/SOFTWARE/NOTES_MODE/notes-mode_1.html>


REQUIREMENTS
------------

Notes-mode requires Perl-5.  For information: http://www.perl.com


INSTALLATION
------------

For each user:
	1. Run notesinit
		(from where it's installed, /usr/local/bin/notesinit
		by default)

After you've installed notes mode you're encouraged to subscribe
to the mailing lists:
Send the message "subscribe" to
	notes-mode-announce-request@heidemann.la.ca.us and 
	notes-mode-talk-request@heidemann.la.ca.us.
(Or use majordomo@heidemann.la.ca.us.)


COPYRIGHT
---------

Notes-mode is Copyright (C) 1994-2002,2012  Free Software Foundation, Inc.
Notes-mode comes with ABSOLUTELY NO WARRANTY.
This is Free Software, and you are welcome to redistribute it under certain
conditions.  See the file ``COPYING'' for details about both of
these conditions.


TODO
----

- figure out how to pass the configured file names to the Perl scripts.
- Use `completion-at-point-functions'.
- Use epa/epg for encryption.
- Figure out what to do about mkall.
- Use defcustom and get rid of "* in docstrings.
- Remove notes-use-font-lock.
- Don't run notes-first just because we load the .el files.
- Unify notes-utility-dir and notes-bin-dir.
- Add support for mouse-1-click-follows-link.

