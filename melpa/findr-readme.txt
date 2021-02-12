This code contains a command, called `findr', which allows you to
search for a file breadth-first.  This works on UNIX, Windows, and
over the network, using efs and ange-ftp. It's pretty quick, and (at
times) is a better and easier alternative to other mechanisms of
finding nested files, when you've forgotten where they are.

You pass `findr' a regexp, which must match the file you're looking
for, and a directory, and then it just does its thing:

M-x findr <ENTER> ^my-lib.p[lm]$ <ENTER> c:/ <ENTER>

If called interactively, findr will prompt the user for opening the
found file(s).  Regardless, it will continue to search, until
either the search is complete or the user quits the search.
Regardless of the exit (natural or user-invoked), a findr will
return a list of found matches.

Two other entrypoints let you to act on regexps within the files:
`findr-search' to search
`findr-query-replace' to replace


; Installation:

(autoload 'findr "findr" "Find file name." t)
(define-key global-map [(meta control S)] 'findr)

(autoload 'findr-search "findr" "Find text in files." t)
(define-key global-map [(meta control s)] 'findr-search)

(autoload 'findr-query-replace "findr" "Replace text in files." t)
(define-key global-map [(meta control r)] 'findr-query-replace)


Change Log:

0.1: Added prompt to open file, if uses so chooses, following
     request and code example from Thomas Plass.
0.2: Made `findr' not stop after the first match, based on the
     request by Thomas Plass.
     Also, fixed a minor bug where findr was finding additional
     files that were not correct matches, based on
     `file-relative-name' misuse (I had to add the 2nd arg to it).
0.3: Added a `sit-for' for redisplay reasons.
     Modifications as suggested by RMS: e.g. docstring.
0.4  Added `findr-query-replace', courtesy of Dan Nelsen.
0.5  Fixed spelling and minor bug in `findr-query-replace' when
     non-byte-compiled.
0.6  http://groups.google.com/groups?selm=cxjhfml4b2c.fsf_-_%40acs5.bu.edu :
From: David Bakhash (cadet@bu.edu)
Subject: Re: latest version of findr.el (5)
Date: 1999/07/31
Courtesy of Dan Nelsen, this version has search-and-replace capabilities.
it's still a bit experimental, so I wouldn't expect too much of it.  But it
hasn't been tested yet for friendly behavior.

The function `findr-query-replace' wasn't working unless you byte-compile the
file.  But, since findr is really designed for speed, that's not a bad thing
(i.e. it forces you to byte-compile it).  It's as simple as:

M-x byte-compile-file <ENTER> /path/to/findr.el <ENTER>

anyhow, I think it should work now.

dave

0.7: Added `findr-search', broke `findr' by Patrick Anderson
0.8: fixed 0.7 breakage by Patrick Anderson
0.9: Added customize variables, added file/directory filter regexp
     minibuffer history by attila.lendvai@gmail.com
0.9.1: Updated date at the top of the file, added .svn filter
0.9.2: Added support for skipping symlinks by attila.lendvai@gmail.com
0.9.3: Smarter minibuffer handling by attila.lendvai@gmail.com
0.9.4: Better handle symlinks by levente.meszaros@gmail.com
0.9.5: Collect resolved files in the result by attila.lendvai@gmail.com
0.9.6: Use a seen hashtable to deal with circles through symlinks by attila.lendvai@gmail.com
0.9.7: Fix wrong calls to message by Michael Heerdegen
0.9.8: Fix 'symbol-calue' typo in non-exposed code path by Michael Heerdegen
0.9.9: Call message less frequent by attila.lendvai@gmail.com
0.9.10: match findr-skip-directory-regexp agaisnt the whole path by attila.lendvai@gmail.com
0.9.11: Fix header line to use ELPA-compliant triple dash by Steve Purcell
