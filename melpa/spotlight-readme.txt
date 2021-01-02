
Provides two functions. These are:

`spotlight' prompts for a query string and searches the
spotlight database with dynamic updates for each new character
entered. You'll be given a list of files that match. Selecting a
file will launch `swiper' for that file searching for the query
string.

Alternatively, the user can use M-RET to dynamically
filter the list of matching files to reduce the number of matches
before selecting a file.

`spotlight-fast' is the same as `spotlight' but the user is
prompted for a query string to search the spotlight database
without incremental updates. This can be much faster than
`spotlight'. The list of matching files containing the query string
in their bodies are presented and the user can select the file or
type a string to dynamically filter the list of files by filename.
The selected file is then opened and a `swiper' search using the
original query is launched.

Customise the variable `spotlight-min-chars' to set the minimum
number of characters that must be entered before the first
spotlight search is performed in `spotlight'. Setting
`spotlight-min-chars' to a lower number will result in more matches
and can lead to slow performance.

Customise the variable `spotlight-default-base-dir' to specify the default
base directory for the spotlight search for both `spotlight' and
`spotlight-live'. The spotlight database will be queried for files
below this directory. Default is user's home directory. Use '/' to
search everywhere. Alternatively, both `spotlight' and
`spotlight-fast' can be called with a prefix argument, in which
case they will prompt for a base directory.

Credits:

Some of the code is based on parts of counsel.el by Oleh Krehel
at https://github.com/abo-abo/swiper

The dynamic filtering is done with the ivy library by the same
author

Thanks to commenters on https://www.reddit.com/r/emacs for feedback
on an early version of the package
