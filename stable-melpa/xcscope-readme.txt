
This is a cscope interface for (X)Emacs.
It currently runs under Unix only.

Using cscope, you can easily search for where symbols are used and defined.
Cscope is designed to answer questions like:

        Where is this variable used?
        What is the value of this preprocessor symbol?
        Where is this function in the source files?
        What functions call this function?
        What functions are called by this function?
        Where does the message "out of space" come from?
        Where is this source file in the directory structure?
        What files include this header file?
        Where was this variable assigned-to?

Send comments to dima@secretsauce.net



***** INSTALLATION *****

* NOTE: this interface currently runs under Unix only.

Installation steps:

0. (It is, of course, assumed that cscope is already properly
   installed on the current system.)

1. Install xcscope.el through your system package manager, MELPA or by
   loading the file with

     (require 'xcscope)

2. Call (cscope-setup). This can go into the .emacs to always enable
   xcscope.el at emacs startup

3. If you intend to use xcscope.el often you can optionally edit your
   ~/.emacs file to add keybindings that reduce the number of keystrokes
   required.  For example, the following will add "C-f#" keybindings, which
   are easier to type than the usual "C-c s" prefixed keybindings.  Note
   that specifying "global-map" instead of "cscope-minor-mode-keymap" makes the
   keybindings available in all buffers:

(define-key global-map [(control f3)]  'cscope-set-initial-directory)
(define-key global-map [(control f4)]  'cscope-unset-initial-directory)
(define-key global-map [(control f5)]  'cscope-find-this-symbol)
(define-key global-map [(control f6)]  'cscope-find-global-definition)
(define-key global-map [(control f7)]
  'cscope-find-global-definition-no-prompting)
(define-key global-map [(control f8)]  'cscope-pop-mark)
(define-key global-map [(control f9)]  'cscope-history-forward-line)
(define-key global-map [(control f10)] 'cscope-history-forward-file)
(define-key global-map [(control f11)] 'cscope-history-backward-line)
(define-key global-map [(control f12)] 'cscope-history-backward-file)
     (define-key global-map [(meta f9)]  'cscope-display-buffer)
     (define-key global-map [(meta f10)] 'cscope-display-buffer-toggle)

6. Restart (X)Emacs.  That's it.




***** USING THIS MODULE *****

* Basic usage:

If all of your C/C++/lex/yacc source files are in the same
directory, you can just start using this module.  If your files are
spread out over multiple directories, see "Advanced usage", below.

Just edit a source file, and use the pull-down or pop-up (button 3)
menus to select one of:

        Find symbol
        Find global definition
        Find called functions
        Find functions calling a function
        Find text string
        Find egrep pattern
        Find a file
        Find files #including a file

The cscope database will be automatically created in the same
directory as the source files (assuming that you've never used
cscope before), and a buffer will pop-up displaying the results.
You can then use button 2 (the middle button) on the mouse to edit
the selected file, or you can move the text cursor over a selection
and press [Enter].

The third mouse button is bound to a popup menu for cscope. Shift-mouse
button 3 invokes the last find command again. E.g. if you look for the symbol
'main' and afterwards you want to look for another symbol, just press Shift
and click the third button.

Each cscope search adds its results to the *cscope* buffer. These sets of
results can be navigated and manupulated similar to patches in diff-mode.:

 - n/p navigates over individual results
 - k kills individual results

 - N/P or M-n/M-p navigates over file results
 - M-k kills file results

 - M-N/M-P navigates over result sets
 - M-K kills result sets

 - Navigation from outside the *cscope* buffer (C-c s n/p/N/P) is restricted to
   the result set at (point)

Any result set in the *cscope* buffer can be re-run with the 'r' key.


* Locating the cscope databases:

This module will first use the variable, `cscope-database-regexps', to search
for a suitable database directory. If a database location cannot be found
using this variable then a search is begun at the variable,
`cscope-initial-directory', if set. If not set and we're running this search
from the *cscope* buffer, the search is begun from the directory of the
search at point. Otherwise, the current directory is used. If the directory
is not a cscope database directory then the directory's parent, parent's
parent, etc. is searched until a cscope database directory is found, or the
root directory is reached. If the root directory is reached, the current
directory will be used.

A cscope database directory is one in which EITHER a cscope database
file (e.g., "cscope.out") OR a cscope file list (e.g.,
"cscope.files") exists.  If only "cscope.files" exists, the
corresponding "cscope.out" will be automatically created by cscope
when a search is done.  By default, the cscope database file is called
"cscope.out", but this can be changed (on a global basis) via the
variable, `cscope-database-file'.  There is limited support for cscope
databases that are named differently than that given by
`cscope-database-file', using the variable, `cscope-database-regexps'.

Note that the variable, `cscope-database-regexps', is generally not
needed, as the normal hierarchical database search is sufficient
for placing and/or locating the cscope databases.  However, there
may be cases where it makes sense to place the cscope databases
away from where the source files are kept; in this case, this
variable is used to determine the mapping.  One use for this
variable is when you want to share the database file with other
users; in this case, the database may be located in a directory
separate from the source files.

Setting the variable, `cscope-initial-directory', is useful when a
search is to be expanded by specifying a cscope database directory
that is a parent of the directory that this module would otherwise
use.  For example, consider a project that contains the following
cscope database directories:

    /users/jdoe/sources
    /users/jdoe/sources/proj1
    /users/jdoe/sources/proj2

If a search is initiated from a .c file in /users/jdoe/sources/proj1
then (assuming the variable, `cscope-database-regexps', is not set)
/users/jdoe/sources/proj1 will be used as the cscope data base directory.
Only matches in files in /users/jdoe/sources/proj1 will be found.  This
can be remedied by typing "C-c s a" and then "M-del" to remove single
path element in order to use a cscope database directory of
/users/jdoe/sources.  Normal searching can be restored by typing "C-c s A".


* Keybindings:

All keybindings use the "C-c s" prefix, but are usable only while
editing a source file, or in the cscope results buffer:

     C-c s s         Find symbol.
     C-c s =         Find assignments to this symbol
     C-c s d         Find global definition.
     C-c s g         Find global definition (alternate binding).
     C-c s G         Find global definition without prompting.
     C-c s c         Find functions calling a function.
     C-c s C         Find called functions (list functions called
                     from a function).
     C-c s t         Find text string.
     C-c s e         Find egrep pattern.
     C-c s f         Find a file.
     C-c s i         Find files #including a file.

These pertain to navigation through the search results:

     C-c s b         Display *cscope* buffer.
     C-c s B         Auto display *cscope* buffer toggle.
     C-c s n         Next symbol.
     C-c s N         Next file.
     C-c s p         Previous symbol.
     C-c s P         Previous file.
     C-c s u         Pop mark.

These pertain to setting and unsetting the variable,
`cscope-initial-directory', (location searched for the cscope database
 directory):

     C-c s a         Set initial directory.
     C-c s A         Unset initial directory.

These pertain to cscope database maintenance:

     C-c s L         Create list of files to index.
     C-c s I         Create list and index.
     C-c s E         Edit list of files to index.
     C-c s W         Locate this buffer's cscope directory
                     ("W" --> "where").
     C-c s S         Locate this buffer's cscope directory.
                     (alternate binding: "S" --> "show").
     C-c s T         Locate this buffer's cscope directory.
                     (alternate binding: "T" --> "tell").
     C-c s D         Dired this buffer's directory.


* Advanced usage:

If the source files are spread out over multiple directories,
you've got a few choices:

1. If all of the directories exist below a common directory
   (without any extraneous, unrelated subdirectories), you can tell
   this module to place the cscope database into the top-level,
   common directory.  This assumes that you do not have any cscope
   databases in any of the subdirectories.  If you do, you should
   delete them; otherwise, they will take precedence over the
   top-level database.

   If you do have cscope databases in any subdirectory, the
   following instructions may not work right.

   It's pretty easy to tell this module to use a top-level, common
   directory:

   a. Make sure that the menu pick, "Cscope/Index recursively", is
      checked (the default value).

   b. Select the menu pick, "Cscope/Create list and index", and
      specify the top-level directory. This will index the sources
      in the background, so you can do other things if indexing
      takes a long time. A list of files to index will be created in
      "cscope.files", and the cscope database will be created in
      "cscope.out".

   Once this has been done, you can then use the menu picks
   (described in "Basic usage", above) to search for symbols.

   Note, however, that, if you add or delete source files, you'll
   have to either rebuild the database using the above procedure,
   or edit the file, "cscope.files" to add/delete the names of the
   source files.  To edit this file, you can use the menu pick,
   "Cscope/Edit list of files to index".


2. If most of the files exist below a common directory, but a few
   are outside, you can use the menu pick, "Cscope/Create list of
   files to index", and specify the top-level directory.  Make sure
   that "Cscope/Index recursively", is checked before you do so,
   though.  You can then edit the list of files to index using the
   menu pick, "Cscope/Edit list of files to index".  Just edit the
   list to include any additional source files not already listed.

   Once you've created, edited, and saved the list, you can then
   use the menu picks described under "Basic usage", above, to
   search for symbols.  The first time you search, you will have to
   wait a while for cscope to fully index the source files, though.
   If you have a lot of source files, you may want to manually run
   cscope to build the database:

           cd top-level-directory    # or wherever
           rm -f cscope.out          # not always necessary
           cscope -b


3. If the source files are scattered in many different, unrelated
   places, you'll have to manually create cscope.files and put a
   list of all pathnames into it.  Then build the database using:

           cd some-directory         # wherever cscope.files exists
           rm -f cscope.out          # not always necessary
           cscope -b

   Next, read the documentation for the variable,
   "cscope-database-regexps", and set it appropriately, such that
   the above-created cscope database will be referenced when you
   edit a related source file.

   Once this has been done, you can then use the menu picks
   described under "Basic usage", above, to search for symbols.


* Interesting configuration variables:

"cscope-truncate-lines"
     This is the value of `truncate-lines' to use in cscope
     buffers; the default is the current setting of
     `truncate-lines'.  This variable exists because it can be
     easier to read cscope buffers with truncated lines, while
     other buffers do not have truncated lines.

"cscope-use-relative-paths"
     If non-nil, use relative paths when creating the list of files
     to index.  The path is relative to the directory in which the
     cscope database will be created.  If nil, absolute paths will
     be used.  Absolute paths are good if you plan on moving the
     database to some other directory (if you do so, you'll
     probably also have to modify `cscope-database-regexps').
     Absolute paths may also be good if you share the database file
     with other users (you'll probably want to specify some
     automounted network path for this).

"cscope-index-recursively"
     If non-nil, index files in the current directory and all
     subdirectories.  If nil, only files in the current directory
     are indexed.  This variable is only used when creating the
     list of files to index, or when creating the list of files and
     the corresponding cscope database.

"cscope-name-line-width"
     The width of the combined "function name:line number" field in
     the cscope results buffer.  If negative, the field is
     left-justified.

"cscope-option-...." Various options passed to the 'cscope' process. Controls
     things like include directories, database compression, database type,
     etc.

"cscope-display-cscope-buffer"
     If non-nil, display the *cscope* buffer after each search
     (default).  This variable can be set in order to reduce the
     number of keystrokes required to navigate through the matches.

"cscope-database-regexps"
	List to force directory-to-cscope-database mappings.
	This is a list of `(REGEXP DBLIST [ DBLIST ... ])', where:

	REGEXP is a regular expression matched against the current buffer's
	current directory.  The current buffer is typically some source file,
	and you're probably searching for some symbol in or related to this
	file.  Basically, this regexp is used to relate the current directory
	to a cscope database.  You need to start REGEXP with "^" if you want
	to match from the beginning of the current directory.

	DBLIST is a list that contains one or more of:

	    ( DBDIR )
	    ( DBDIR ( OPTIONS ) )
	    ( t )
	    t

	Here, DBDIR is a directory (or a file) that contains a cscope
	database.  If DBDIR is a directory, then it is expected that the
	cscope database, if present, has the filename given by the variable,
	`cscope-database-file'; if DBDIR is a file, then DBDIR is the path
	name to a cscope database file (which does not have to be the same as
	that given by `cscope-database-file').  If only DBDIR is specified,
	then that cscope database will be searched without any additional
	cscope command-line options.  If OPTIONS is given, then OPTIONS is a
	list of strings, where each string is a separate cscope command-line
	option.

	In the case of "( t )", this specifies that the search is to use the
	normal hierarchical database search.  This option is used to
	explicitly search using the hierarchical database search either before
	or after other cscope database directories.

	If "t" is specified (not inside a list), this tells the searching
	mechanism to stop searching if a match has been found (at the point
	where "t" is encountered).  This is useful for those projects that
	consist of many subprojects.  You can specify the most-used
	subprojects first, followed by a "t", and then followed by a master
	cscope database directory that covers all subprojects.  This will
	cause the most-used subprojects to be searched first (hopefully
	quickly), and the search will then stop if a match was found.  If not,
	the search will continue using the master cscope database directory.

	Here, `cscope-database-regexps' is generally not used, as the normal
	hierarchical database search is sufficient for placing and/or locating
	the cscope databases.  However, there may be cases where it makes
	sense to place the cscope databases away from where the source files
	are kept; in this case, this variable is used to determine the
	mapping.

	This module searches for the cscope databases by first using this
	variable; if a database location cannot be found using this variable,
	then the current directory is searched, then the parent, then the
	parent's parent, until a cscope database directory is found, or the
	root directory is reached.  If the root directory is reached, the
	current directory will be used.

	A cscope database directory is one in which EITHER a cscope database
	file (e.g., "cscope.out") OR a cscope file list (e.g.,
	"cscope.files") exists.  If only "cscope.files" exists, the
	corresponding "cscope.out" will be automatically created by cscope
	when a search is done.  By default, the cscope database file is called
	"cscope.out", but this can be changed (on a global basis) via the
	variable, `cscope-database-file'.  There is limited support for cscope
	databases that are named differently than that given by
	`cscope-database-file', using the variable, `cscope-database-regexps'.

	Here is an example of `cscope-database-regexps':

	(setq cscope-database-regexps
	      '(
		( "^/users/jdoe/sources/proj1"
		  ( t )
		  ( "/users/jdoe/sources/proj2")
		  ( "/users/jdoe/sources/proj3/mycscope.out")
		  ( "/users/jdoe/sources/proj4")
		  t
		  ( "/some/master/directory" ("-d" "-I/usr/local/include") )
		  )
		( "^/users/jdoe/sources/gnome/"
		  ( "/master/gnome/database" ("-d") )
		  )
		))

	If the current buffer's directory matches the regexp,
	"^/users/jdoe/sources/proj1", then the following search will be
	done:

	    1. First, the normal hierarchical database search will be used to
       locate a cscope database.

	    2. Next, searches will be done using the cscope database
       directories, "/users/jdoe/sources/proj2",
       "/users/jdoe/sources/proj3/mycscope.out", and
       "/users/jdoe/sources/proj4".  Note that, instead of the file,
       "cscope.out", the file, "mycscope.out", will be used in the
       directory "/users/jdoe/sources/proj3".

	    3. If a match was found, searching will stop.

	    4. If a match was not found, searching will be done using
       "/some/master/directory", and the command-line options "-d"
       and "-I/usr/local/include" will be passed to cscope.

	If the current buffer's directory matches the regexp,
	"^/users/jdoe/sources/gnome", then the following search will be
	done:

	    The search will be done only using the directory,
	    "/master/gnome/database".  The "-d" option will be passed to
	    cscope.

	If the current buffer's directory does not match any of the above
	regexps, then only the normal hierarchical database search will be
	done.


* Other notes:

1. This module is called, "xcscope", because someone else has
   already written a "cscope.el" (although it's quite old).


* KNOWN BUGS:

1. Cannot handle whitespace in directory or file names.

2. The support for cscope databases different from that specified by
   `cscope-database-file' is quirky.  If the file does not exist, it
   will not be auto-created (unlike files names by
   `cscope-database-file').  You can manually force the file to be
   created by using touch(1) to create a zero-length file; the
   database will be created the next time a search is done.
