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
