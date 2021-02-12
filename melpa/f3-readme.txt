The below is generated from a README at
https://github.com/cosmicexplorer/f3.

The Fantastic File Finder for emacs. Find files fast, using `helm'. It's
cool, trust me.


Motivation:

There are many file operations that are difficult to perform without
specialized tools. The two this package attempts to solve are:

1. Finding a particular file by name in a large project.
2. Performing operations of arbitrary complexity on many files at once.

The first is usually solved in IDEs by maintaining an index of all files in
the project. However, this requires that the project be of a type that the
IDE supports. The second is usually solved through a mixture of trial and
error, and occasionally the use of `find -exec'. However, as `find' is a
complex command which supports many different search options, it is often
difficult to perform this process efficiently, and if `find' is not used, it
can be time consuming and error-prone to specify a file list manually. This
package provides an interactive interface to the `find' utility using helm
as a frontend to solve both of these problems quickly so you can get back to
work and stop playing around with the command line.


Usage:


Finding Particular Files:

'M-x f3' brings up a helm buffer displaying all open buffers visiting files.
Typing into the minibuffer will narrow down candidates which match the
current text pattern among all open buffers, and also spawn a `find' process
which will intelligently use the minibuffer input to search file paths in
the current project. By default, `f3' attempts to detect the project root;
the method by which it does this can be customized by the variable
`f3-default-directory'. Files which `find' ignores can be customized with
the variable `f3-before-args'. 'RET' visits the currently selected file, and
'TAB' previews the file, killing it after the helm session is quit.

This is often enough to quickly locate files within a given project. For
larger or deeply nested project hierarchies, `find' can become slow;
however, after it is run a few times, the operating system's cache typically
helps speed up the operation. `f3-default-directory' can be customized
per-folder so that `find' does not search the entire project if more speed
is required.

The current "input mode" determines whether `find' searches using wildcards
or regex; see keybindings below.


Performing Operations On Many Files:

When attempting to perform mass operations on files, more search complexity
is often desired. `find' offers a series of predicates and algebraic
operators to narrow down search results. Predicates supported by `f3'
include `-[i]path', `-[i]regex', `-type', `-perm', and also a "raw" mode
which allows inputting arbitrary find arguments verbatim. This is useful for
when the interface offered by `f3' becomes too simplistic.

In addition to simple predicates, `find' offers operators which combine the
results of multiple searches in different ways. The operators (sometimes
called "combinators" in this documentation) supported by `f3' are `-and',
`-or', and parentheses. These are entered mnemonically as `M-*', `M-+', and
`M-('/`M-)', respectively. In this way, a more complex query can be built
up. `M-u' and `M-U' can "undo" and "redo" pattern inputs, allowing for
modification of the find command without having to start again from
scratch.

When the results shown interactively in the helm buffer appear to match what
is desired, `M-d' can be used to "bounce" them to a `find-dired' buffer,
where the files can be acted upon in aggregate with a shell command or lisp
function in a natural way.


Keybindings:

- combinators: these set `f3-current-combinator', take the current pattern
as the find predicate, and clear the minibuffer
    - 'M-+' = union ("or")
    - 'M-*' = intersection ("and")
- groupings: these add open or closed parentheses to the current find
command and clear the minibuffer
    - 'M-(' = open paren
        - `f3' will implicitly close any remaining open parens by adding `)'
to the end of the `find' command line produced
    - 'C-u M-(' = open paren, with `-not' on
    - 'M-) M-+' = close paren / or
        - if there are no unclosed `)', they will be implicitly added
    - 'M-) M-*' = close paren / and
- modes: these do NOT clear the minibuffer, just change the current `find'
predicate
    - 'M-t' = normal text mode (not regex mode)
    - 'M-x' = regex mode
    - 'M-r' = "find" mode (just input raw find arguments)
    - 'M-f' = filetype (`b|c|d|f|l|p|s')
    - 'M-p' = perm
- complement: this toggles whether `-not' is applied to the current
predicate
    - 'M-q' = toggle complement (current)
- actions
    - 'M-d' = exit helm and list the files in a `find-dired' buffer
    - 'RET' = visit
    - 'TAB' = preview
    - 'M-b' = bounce to raw (can use 'M-R' afterwards to restore previous)
- meta
    - 'M-u' = undo whatever was just done
    - 'M-U' = redo
    - 'M-<' = set `mindepth'
    - 'M->' = set `maxdepth'
    - 'M-R' = restore from previous command
    - 'C-M-R' = undo restore (move up and down a previous command stack)
- changing directories
    - 'M-o' = start search from project root
    - 'M-i' = start search from initial choice of `default-directory'
    - 'M-c' = choose directory to search from, starting at whatever the
current choice is
    - 'M-j' = start searching a directory up


Updates:

Run `./update-commentary.el' in this directory to update the commentary
section of the lisp file after changing this README. Run `npm install' if it
complains about node modules.


Further Work:

- add docstrings containing the info in this readme
- show state of undo/redo in some readable way
    - also consider making it a traversable tree like emacs's `undo-tree'
- fix highlighting of results in helm and highlighting of previews
    - maybe use some logic in `f3--filter-buffer-candidates'?


License:

GPL 3.0+

End Commentary
