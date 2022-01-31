This set of functions aims to implement many (but not all) of the features
of the package 'Zetteldeft', while circumventing and eliminating any
dependency on 'Deft', or any other external packages for that matter. It
does not use any backend cache or database, but instead queries a
directory of notes directly, treating and utilizing that directory as a
sufficient database unto itself.

To that end, these functions rely, at the lowest level, on simple calls to
'grep', which returns lists of files, links, and tags to
'completing-read', from which files can be opened and links and tags can
be inserted into an open buffer.

The primary connector between notes is the simple link, which takes the
form of an ID number enclosed in double-brackets, eg, [[202012091130]]. A
note's ID number, by default, is a twelve-digit string corresponding to
the date and time the note was originally created. For example, a note
created on December 9th, 2020 at 11:30 will have the zk ID "202012091130".
Linking to such a note involves nothing more than placing the string
[[202012091130]] into another note in the directory.

A note's filename is constructed as follows: the zk ID number followed by
the title of the note followed by the file extension, e.g. "202012091130
On the origin of species.txt". A key consequence of this ID/linking scheme
is that a note's title can change without any existing links to the note
being broken, wherever they might be in the directory.

The directory is a single folder containing all notes.

The structural simplicity of this set of functions is---one hopes, at
least---in line with the structural simplicity of the so-called
"Zettelkasten method," of which much can be read in many places, including
at https://www.zettelkasten.de.
