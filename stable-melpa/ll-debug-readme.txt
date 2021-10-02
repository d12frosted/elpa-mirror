ll-debug.el provides commands to support a low level debug style.
It features quick insertion of various debug output statements and
improved functions for commenting and uncommenting chunks of code.

I don't use debuggers very much. I know they can be a big help in
some situations and I tried some of them, but I find it almost
always more direct/convenient/enlightening to put a quick 'printf'
into a critical area to see what is happening than to fire up a big
clumsy extra program where it takes me ages just to step through to
the interesting point. In order to avoid repeated typing of
'printf("I AM HERE\n");' and similar stuff, I created
`ll-debug-insert'. It inserts a statement into your
sourcecode that will display a debug message. It generates
unique messages on each invocation (the message consists of a big
fat DEBUG together with a counter and the current filename).

See variable `ll-debug-statement-alist' if you want to know which
modes are currently supported by ll-debug. You can add new modes
with `ll-debug-register-mode'.

When I have found the buggy spot, I like to keep a version of the
old code in place, just in case I mess things up.
`ll-debug-copy-and-comment-region-or-line' helps here, it makes a
copy of the current line (or the current region, if active) and
comments out the original version.

I always missed a keystroke that toggles the 'comment state' of a
line (or region) of sourcecode. I need to turn a line or a block of
code on and off quickly. `ll-debug-toggle-comment-region-or-line'
does just that.

Finally, if you want to spit out the values of a lot of variables
you can use `ll-debug-insert' with a C-u prefix arg. It calls
mode-specific skeletons that keep asking for variable names (and
sometimes format specifiers) in the minibuffer. If you just press
return here the skeleton interaction ends and a statement to print
the names and the values of the variables is inserted in the
buffer.

If you want to get rid of the debug messages, use
`ll-debug-revert'. It finds and removes the lines with the debug
output statements, asking for confirmation before it removes
anything.


Prerequisites:

I made the latest version of ll-debug with GNU Emacs 26.3.
Please let me know if other versions work.


Installation:

Get the newest version of ll-debug.el via
https://github.com/replrep/ll-debug
or
http://www.cbrunzema.de/software.html#ll-debug

and put it in your load-path. Add the following form to your init
file (~/.emacs or ~/.emacs.d/init.el):

 (require 'll-debug)

Now you can bind ll-debug commands to keystrokes yourself or just
call `ll-debug-mode'. `ll-debug-mode' is a minor mode that installs
`ll-debug-mode-map'. It clobbers C-v, which may not be completely
emacs-political-correct, but it happens to be the stuff I use
daily, it is only a suggestion, blah, if you don't like it, don't
use it blah blah, do it your own way blah bla blah and don't flame
me.... `ll-debug-mode-map' has the following keybindings:

C-v C-v   `ll-debug-toggle-comment-region-or-line'
C-v v     `ll-debug-uncomment-region-or-line'
C-v C-y   `ll-debug-copy-and-comment-region-or-line'
C-v C-d   `ll-debug-insert'

If you want to activate `ll-debug-mode' automatically for certain
modes, put it into the usual hooks, e.g.

(add-hook 'cperl-mode-hook #'ll-debug-mode)


Usage example 1:

If you activate `ll-debug-mode', hitting C-v C-d
in a c-mode buffer called 'main.c' produces:

   printf("DEBUG-1-main.c\n");

a second C-v C-d prints

   printf("DEBUG-2-main.c\n");

and so on. The following conversation uses the variable output (the
part in '[' and ']' takes place in the minibuffer):

C-u C-v C-d [ foo <RET> s <RET> bar <RET> d <RET> baz <RET> f <RET> <RET> ]

This gives:

   printf("DEBUG-3-main.c foo:%s  bar:%d  baz:%f\n", foo, bar, baz);


Usage example 2:

In a lisp-mode buffer called 'tree.lisp' this:

C-v C-d
C-v C-d
C-u C-v C-d [ foo <RET> bar <RET> baz <RET> <RET> ]

produces the following lines:

(CL:format t "DEBUG-1-tree.lisp~%")
(CL:format t "DEBUG-2-tree.lisp~%")
(CL:format t "DEBUG-3-tree.lisp foo:~S  bar:~S  baz:~S~%" foo bar baz)


Usage example 3:

The keybindings in `ll-debug-mode-map' will call a alternative
versions for variable output if one ore more C-u prefix args are
given. An alternative version is currently available in
(c)perl-mode only. So, in a (c)perl-mode buffer called 'answer.pl'
these keys

C-u C-u C-v C-d [ @quux <RET> %thud <RET> $grunt <RET> <RET> ]

produce:

print "DEBUG-1-answer.pl ", Data::Dumper->Dump([\@quux, \%thud, $grunt], [qw/*quux *thud grunt/]), "\n";


Customisation:

You can use a different string for the debug messages by setting the
variable `ll-debug-output-prefix'. If you set it e.g. to "# DEBUG-"
your debug output won't disturb gnuplot datafiles anymore.

If you don't like c++'s streams, you can request the printf style
output by putting the following in your init file:

 (setcdr (assq 'c++-mode ll-debug-statement-alist)
         (cdr (assq 'c-mode ll-debug-statement-alist)))


If you want to have dynamic output not only according to the major
mode, you can substitute functions in `ll-debug-statement-alist'.
For example, the following snippet uses prefix 'printk' instead of
'printf' if you are editing c-sources in a file on a path
containing a 'linux' component:

 (setf (ll-debug-struct-prefix (cdr (assq 'c-mode
                                          ll-debug-statement-alist)))
        #'(lambda ()
            (if (string-match "linux" (buffer-file-name))
                "printk("
              "printf(")))



Please read the documentation for `ll-debug-insert' and
`ll-debug-expand' to see what is possible.


If you want to teach ll-debug new modes, see
`ll-debug-register-mode' and consider sending a patch to
<mail@cbrunzema.de>.


History:
2021-03-27  alstjr7375
        * Add support for rust
2020-11-28  Claus Brunzema
        * Prepare/cleanup for Melpa
        * Version 2.0.3
2020-11-26  Claus Brunzema
        * Small fixes and cleanup
        * Remove compatibility hacks (sorry xemacs...)
        * Add support for javascript, typescript and clojure
        * Version 2.0.2
2020-11-15  alstjr7375
        * Deprecated lib cl to cl-lib
        * Active lexical binding
        * Version 2.0.1
2004-12-28  Claus Brunzema
        * Major rewrite using defstruct.
        * New ll-debug-insert instead of
          ll-debug-insert-debug-output and
          ll-debug-insert-variable-output.
        * New ll-debug-register-mode.
        * Version 2.0.0
2003-05-21  Claus Brunzema
        * Added java support.
        * Moved prefix calculation stuff into new
          ll-debug-insert-debug-output-statement.
        * Some cleanup.
        * Version 1.3.0
2003-05-15  Claus Brunzema
        * Added ll-debug-install-suggested-keybindings.
2003-03-10  Claus Brunzema
        * Added package/namespace identifiers to common lisp/c++ code
        * Version 1.2.6
2003-03-10  Claus Brunzema
        * Put in ll-debug-output-prefix instead of the hardcoded
          default (thanks to Stefan Kamphausen for the idea with
          gnuplot).
        * More documentation.
        * Version 1.2.5
2003-01-30  Claus Brunzema
        * added ll-debug-insert-emacs-lisp-variable-output.
        * ll-debug-insert-perl-variable-output doesn't insert
          the '$' automatically anymore. That always confused me.
        * various cleanup and documentation changes.
        * Version 1.2.3
2003-01-29  Claus Brunzema
        * added ll-debug-insert-perl-variable-dumper-output.
2003-01-28  Claus Brunzema
        * after (un)commenting a single line the point is moved
          to the next line.
2002-11-20  Claus Brunzema
        * added ll-debug-insert-scheme-variable-output.
        * Version 1.2.0
2002-11-11  Claus Brunzema
        * added ll-debug-create-next-debug-string (thanks to Scott Frazer).
        * updated skeletons to use ll-debug-create-next-debug-string.
        * Version 1.1.0
2002-11-09  Claus Brunzema
        * added DEBUG to skeletons.
        * added ll-debug-revert (thanks to Scott Frazer for the idea).
        * removed automatic linebreaks from skeletons, so ll-debug-revert
          doesn't leave half statemets behind.
2002-10-15  Claus Brunzema
        * fixed ll-debug-region-or-line-comment-start to look
          for comment-chars starting a line only (thanks to Stefan
          Kamphausen for the bug report).
        * Code cleanup.
        * Version 1.0.0
2002-09-04  Claus Brunzema
        * fixed point position after
          ll-debug-copy-and-comment-region-or-line
        * Version 0.2.2
2002-08-17  Claus Brunzema
        * use (search-forward comment-start ...) instead of
          (re-search-forward comment-start-skip ...).
        * use ll-debug-region-or-line-comment-start instead of
          the optional ignore-current-column argument for
          ll-debug-region-or-line-start.
        * ll-debug-copy-and-comment-region-or-line works correctly
          now if point is in the middle of the line.
        * Version 0.2.1
2002-08-11  Claus Brunzema
        * Variable output support for Common Lisp, perl and c.
        * Various cleanup.
        * Version 0.2.0
2002-08-08  Claus Brunzema
        * Uncommenting doesn't check the current column anymore
          (thanks to Stefan Kamphausen).
        * More blurb.
        * Version 0.1.1
2002-08-07  Claus Brunzema
        * First public version 0.1.0


ToDo:
* Check if the strange log calculation in ll-debug-insert is really
  necessary. I want the number of C-u keypresses to dispatch
  alternatives on the content slot value of a ll-debug-struct, but
  every C-u multiplies prefix-numeric-value by 4. Is there a better
  way to do this?
* Make preferred output stream customizable.
