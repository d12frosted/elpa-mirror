This file contains a command to read Perl documentation in Emacs.
It uses two external commands which come with Perl: `perldoc` to
locate the Perl documentation for the Perl modules installed on
your system, and `pod2html` to format the documentation to HTML.
This HTML version is then displayed using Emacs' "simple HTML
renderer" shr.

Motivation

Perl documentation is written in a markup format called POD ("Plain
Old Documentation") and is usually converted to other formats for
reading by humans.  The documentation used to be available in Emacs
for a long time in 'info' or 'man' format.  However, Perl does no
longer ship 'info' files, and the software available from CPAN
never did.  'man' is not available on all platforms and allows only
rather restricted formatting, most notably linking between
documents does not work.

On the other hand, Perl provides a converter from POD to HTML.
HTML is well supported by Emacs and is well suited for presentation
of structured documents.

The user visible benefits over the other formats are:

 * Works nicely on platforms which do not have man

 * Unlike with 'man', Hyperlinks between POD documents work and
  resolve to POD documentation on your system, no web server
  required.

 * Makes use of Emacs faces: variable-pitch font for text,
   fixed-pitch for code, italics for, well, italics