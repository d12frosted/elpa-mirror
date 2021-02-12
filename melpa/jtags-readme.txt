The main purpose of `jtags-mode' is to provide an improved tags lookup
function for Java source code, compared to the ordinary etags package.
While etags knows only the name of the identifier, jtags also knows the
context in which the identifier is used.  This allows jtags to find the
correct declaration at once, instead of the declaration that happens to
appear first in the tags table file.

However, there are cases when jtags cannot lookup tags.  That is because
the etags program included with Emacs does not generate correct tags table
files for Java source code.  For example, the interface java.util.Map is
missing from the tags table files, and therefore cannot be looked up.

In addition to looking up identifiers and showing their declaration or
documentation, the jtags package also contains a function for completing
partly typed identifiers, and functions for managing tags table files.

The following interactive functions are included in jtags mode:

- jtags-member-completion:      find all completions of the partly typed
                                method or variable name at point
- jtags-show-declaration:       look up and display the declaration of the
                                indentifier at point
- jtags-show-documentation:     look up and display the Javadoc for the
                                indentifier at point
- jtags-update-tags-files:      update all tags table files with the latest
                                source code changes
- jtags-update-this-tags-file:  update the tags table file in which the
                                class in the current buffer is tagged
- jtags-clear-caches:           clear internal caches, see section Caching

Throughout this file, the two terms DECLARATION and DEFINITION are used
repeatedly.  The DECLARATION of an identifier is the place in the Java
source code where the identifier is declared, e.g. the class declaration.
The DEFINITION of an identifier is the data structure used by jtags to
describe the declaration, containing file name, line number etc.

Installation:

Place "jtags.el" in your `load-path' and place the following lines in your
init file:

(autoload 'jtags-mode "jtags" "Toggle jtags mode." t)
(add-hook 'java-mode-hook 'jtags-mode)

Configuration:

Add the Emacs "bin" directory to your path, and restart Emacs to make the
etags program available to jtags mode.

Unzip the source code files that come with the JDK and other products you
use, e.g. JUnit.  The etags program can only extract information from source
code files, and not from class files.

Configure the tags table list in your init file.  Include the directories
where you unzipped the external source code files, and the directories where
your project's source code is located.

GNU Emacs example:

(setq tags-table-list '("c:/java/jdk1.8.0/src"
                        "c:/projects/tetris/src"))
(setq tags-revert-without-query 't)

XEmacs example:

(setq tag-table-alist '(("\\.java$" . "c:/java/jdk1.8.0/src")
                        ("\\.java$" . "c:/projects/tetris/src")))
(setq tags-auto-read-changed-tag-files 't)

Type `M-x jtags-update-tags-files' to update all of the files in the tags
table list.  If you do not have write access to all of the tags table files,
e.g. in the JDK installation directory, you can copy the source code tree,
or ask the system administrator to create the tags table files for you.  If
you are running Linux, you can start Emacs using the sudo command once, to
create the tags table files.

The shell command that runs when you update tags table files is defined in
the variable `jtags-etags-command'.  Change this variable to run a specific
version of etags, or to include other source code files in the tags table
files.  After updating a tags table file, any hooks defined in variable
`jtags-after-tags-update-hook' will be called with the updated tags table
file buffer as the current buffer.  This can be used to modify the newly
updated tags table file if needed.

To display Javadoc for third party libraries, you need to customize the
`jtags-javadoc-root-alist' and add Javadoc root URLs for these libraries.
Package jtags now supports both http URLs and file URLs.

If you want to use the jtags submenu, set `jtags-display-menu-flag' to
non-nil.  If this variable is non-nil, the jtags submenu will be displayed
when jtags mode is active.

You can customize all the variables above, as well as the faces used in
member completion.  Type `M-x customize-group' and enter group "jtags" for
the jtags mode variables, or "etags" for the tags table list.

The jtags package defines four key bindings in the `jtags-mode-map':

- C-,   is bound to `jtags-member-completion'
- M-,   is bound to `jtags-show-declaration'
- M-f1  is bound to `jtags-show-documentation'
- C-c , is bound to `jtags-update-this-tags-file'

To define other key bindings, or set other things up, add a hook function
to `jtags-mode-hook'.  The hook function will be called after; entering or
leaving jtags mode.  This is an example:

(add-hook 'jtags-mode-hook (lambda () (message "I'm in jtags-mode.")))

Caching:

To improve performance, jtags caches some data internally, for example
which interfaces a certain class implements.  Most of the time this works
fine, but if the code changes a lot the caches may contain old data.  To
prevent this from happening, all caches are cleared each time the tags
table files are updated.

If you want more control over when the caches are cleared, you can customize
`jtags-after-tags-update-hook' and remove the entry `jtags-clear-caches'.
To clear all internal caches manually, type `M-x jtags-clear-caches'.
