This started as an experiment to see concretely where&how SMIE falls down
when trying to handle a language like C, to get an idea of maybe what it
would take to change SMIE to better support C-style syntax.

So, this does provide "SMIE-based indentation for C" and might even do it OK
in practice, but it really doesn't benefit much from SMIE:
- it does a lot of its own parsing by hand.
- its smie-rules-function also does a lot of indentation by hand.
Hopefully at some point, someone will find a way to extend SMIE such that
we can handle C without having to constantly work around SMIE, e.g.
it'd be nice to hook sm-c--while-to-do, sm-c--else-to-if, sm-c--boi,
sm-c--boe, ... into SMIE at some level.

This is not designed to supplant Emacs's built-in c-mode, which does a more
thorough job.  It was not even meant to be used by anyone, really, but
I finally decided to release this because some users pointed out that on
slow machines it can be a worthy lightweigth alternative.

Known limitations:

- This mode makes no attempt to try and handle sanely K&R style function
  definitions (i.e. where the type of arguments is given between the list of
  arguments and the body).  There are 2 good reasons for that: this old
  syntax sucks and should be laid to rest, and it'd be a lot of extra work
  to try and handle it.

Todo:

- This mode mostly limits itself to the C99 syntax, so it would be nice
  to make it handle the syntactic constructs introduced since then.
- We "use but don't use" SMIE.
- CPP directives are treated as comments.  To some extent this is OK, but in
  many other cases it isn't.  See for instance the comment-only-p advice.
- M-q in a comment doesn't do the right thing.


Benchmarks

This code can't be compared to CC-mode since its scope is much more limited
(only tries to handle the kind of code found in Emacs's source code, for
example; does not intend to be extensible to handle C++ or ObjC; does not
offer the same kind of customizability of indentation style, ...).
But in order to make sure it's doing a good enough job on the code for which
it was tuned, I did run some quick benchmarks against CC-mode:

Benchmarks: reindent emacs/src/*.[ch] (skipping macuvs.h and globals.h
because CC-mode gets pathologically slow on them).
   (cd .../emacs/; git reset --hard; mv src/macuvs.h src/globals.h ./);
   files=($(echo .../emacs/src/*.[ch]));
   (cd .../emacs/; mv macuvs.h globals.h src/);
   time make -j4 ${^${files}}.reindent EMACS="emacs24 -Q";
   (cd .../emacs/; git diff|wc)
- Default settings:
  diff|wc =>  86800  379362 2879534
  make -j4  191.57s user 1.77s system 334% cpu   57.78 total
- With (setq sm-c-indent-cpp-basic 0)
  diff|wc =>  59909  275415 2034045
  make -j4  177.88s user 1.70s system 340% cpu   52.80 total
- For reference, CC-mode gets:
  diff|wc =>  79164  490894 3428542
  make -j4  804.83s user 2.79s system 277% cpu 4:51.08 total

IOW, in this "best case" scenario, `sm-c-mode' indented almost as well
as `c-mode' does (as measured by diff|wc), and it did it about
4 times faster.
BEWARE: take this with a large grain of salt, since this is testing
`sm-c-mode' in the most favorable light (IOW it's a very strongly biased
benchmark).
All this says, is that sm-c-mode's indentation might actually be usable if
you use it on C code that is sufficiently similar to Emacs's.