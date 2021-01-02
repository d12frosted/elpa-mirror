
A global minor-mode to navigate and edit text objects. Objed enables modal
editing and composition of commands, too. It combines ideas of other
Editors like Vim or Kakoune and tries to align them with regular Emacs
conventions.

For more information also see:

- My Blog: https://www.with-emacs.com/categories/objed/
- Project Readme: https://github.com/clemera/objed/blob/master/README.asc
- Project News: https://github.com/clemera/objed/blob/master/News.asc.

Text objects are textual patterns like a line, a top level definition, a
word, a sentence or any other unit of text. When `objed-mode' is enabled,
certain editing commands (configurable) will activate `objed' and enable
its modal editing features. When active, keys which would usually insert a
character are mapped to objed commands. Other keys and commands will
continue to work as they normally would and exit this editing state again.

By default important self inserting keys like Space or Return are not bound
to modal commands and will exit `objed' on insertion. This makes it
convenient to move around and continue adding new text.

With activation `objed' shows the current object type in the mode-line. The
textual content of the object is highlighted visually in the buffer and the
cursor color is changed, too. The user can now navigate by units of this
object, change the object state or switch to other object types.

The object state is either "inner" or "whole" and is indicated in the
modeline by (i) or (w) after the object type. With inner state, anything
that would be considered delimiters or padding around an object is
excluded.

The user can apply operations to objects. By marking objects before
applying an operation, s?he can even operate on multiple objects at once.
This works similar to the way you interact with files in `dired'. When
marking an object the point moves on to the next object of this type.

The object type used for initialization is determined by the mapping of the
entry command (see `objed-cmd-alist'). For example using
`beginning-of-defun' will activate `objed' using the `defun' object as
initial object type. With command `next-line', `objed' would initialize
with the `line' object.

Objeds modal state provides basic movement commands which move by line,
word or character. Those switch automatically to the corresponding object
type, otherwise they work the same as the regular Emacs movement commands.
Other commands only activate the part between the initial position and the
new position moved to. By repeating commands you can often expand/proceed
to other objects. This way you can compose movement and editing operations
very efficiently.

The expansion commands distinguish between block objects (objects built out
of lines of text) and context objects (programming constructs like strings,
brackets or textual components like sentences). This way you can quickly
expand to the desired objects.

For example to move to the end of the paragraph, the user would first move
to the end of the line with "e". This would activate the text between the
starting position and the end of the line. The user can now continue to the
end of the paragraph by by pressing "e" again. Now s?he is able to proceed
even further by pressing "e" again OR to continue by adding new text to the
end of the paragraph OR to continue by acting on the text moved over, for
example killing it by pressing "k".

As often with text editing, the explanation sounds more complicated than
using it. To get a better impression of the editing workflow with `objed'
have look at https://github.com/clemera/objed where you can find some
animated demos.

To learn more about available features and commands have a look at the
descriptions below or the Docstrings and bindings defined in `objed-map'.
To define your own operations and text objects see `objed-define-op' and
`objed-define-object'.

Although some features are still experimental the basic user interface will
stay the same.


CONTRIBUTE:

I'm happy to receive pull requests or ideas to improve this package. Some
parts suffer from the bottom up approach of developing it, but this also
allowed me to experiment a lot and try ideas while working on them,
something that Emacs is especially good at. Most of the features are tested
using `emacs-lisp-mode' but hopefully there aren't to many problems using
modes for other languages, I tried my best to write text objects in a
language agnostic way. Testing this and writing more tests in general would
be an important next step.

This package would never been possible without the helpful community around
Emacs. Thank you all and see you in parendise...Share the software!


