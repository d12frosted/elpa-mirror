GNU Hyperbole (pronounced Gnew Hi-per-bo-lee), or just Hyperbole, is like
Markdown for hypertext, letting you use little or no markup in files to
produce easy-to-navigate hypermedia files.  It is an easy-to-use, yet
powerful and programmable hypertextual information management system
implemented as a GNU Emacs package.  It offers rapid views and interlinking
of all kinds of textual information, utilizing Emacs for editing.  It can
dramatically increase your productivity and greatly reduce the number of
keyboard/mouse keys you'll need to work efficiently.

Hyperbole lets you:

1. Quickly create hyperlink buttons either from the keyboard or by dragging
between a source and destination window with a mouse button depressed.
Later activate buttons by pressing/clicking on them or by giving the name of
the button.

2. Activate many kinds of `implicit buttons' recognized by context within
text buffers, e.g. URLs, grep output lines, and git commits.  A single key
or mouse button automatically does the right thing in dozens of contexts;
just press and go.

3. Build outlines with multi-level numbered outline nodes, e.g. 1.4.8.6,
that all renumber automatically as any node or tree is moved in the
outline.  Each node also has a permanent hyperlink anchor that you can
reference from any other node;

4. Manage all your contacts quickly with hierarchical categories and embed
hyperlinks within each entry.  Or create an archive of documents with
hierarchical entries and use the same search mechanism to quickly find any
matching entry;

5. Use single keys to easily manage your Emacs windows or frames and quickly
retrieve saved window and frame configurations;

6. Search for things in your current buffers, in a directory tree or across
major web search engines with the touch of a few keys.

The common thread in all these features is making retrieval, management and
display of information fast and easy.  That is Hyperbole's purpose.

----

See the "INSTALL" file for installation instructions and the "README.md" file
for general information.

There is no need to manually edit this file unless there are specific
customizations you would like to make, such as whether a Hyperbole Action
Mouse Key is bound to the middle mouse button.  (See the call of the
function, `hmouse-install', below).

Other site-specific customizations belong in "hsettings.el".