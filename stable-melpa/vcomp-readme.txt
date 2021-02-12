Compare version strings.

Similar functionality is available in Emacs; see `version<' and
friends defined in `subr.el'.  Unfortunately those functions have
some limitations.

This library can parse more version strings and doesn't treat
certain versions as equal that are not actually equal.

What is a valid version string is defined jointly by the regular
expression stored in variable `vcomp--regexp' and the function
`vcomp--intern' and best explained with an example.

Function `vcomp--intern' converts a string to the internal format
as follows:

  0.11a_rc3-r1 => ((0 11) (97 103 3 1))

  0.11         => (0 11)  valid separators are ._-
      a        => 97      either 0 or the ascii code of the lower
                          case letter (A is equal to a)
       _rc     => 103     100 alpha
                          101 beta
                          102 pre
                          103 rc
                          104 --
                          105 p
                          _ is optional, - is also valid
          3    => 3       if missing 0 is used
           -r1 => 1       there are no variations of -rN

A less crazy version string would be converted like this:

  1.0.3 => ((1 0 3) (0 104 0 0))

The internal format is only intended for ... internal use but if
you are wondering why a flat list does not do:

  1.97 => (1 97)
  1a   => (1 97)

There are other ways of dealing with this and similar problems.
E.g. the built-in functions treat 1 and 1.0 as equal and only
support pre-releases of sorts but not patches ("-pN") like this
library does.  Having an internal format that doesn't make any
compromises but has to be explained seems like the better option.

Functions `vcomp-compare' and `vcomp--compare-interned' can be used
to compare two versions using any predicate that can compare
integers.

When comparing two versions whose numeric parts have different
lengths `vcomp--compare-interned' fills in -1.

  1.0    => ((1 0) ...)   => ((1 0 -1) ...)
  1.0.0  => ((1 0 0) ...) => ((1 0  0) ...)

So 1.0.0 is greater than 1.0 and 1.0 is greater than 1.  If you
don't want that set `vcomp--fill-number' to 0.

This filling has to happen in `vcomp--compare-interned' as we don't
know the length of the other versions when `vcomp--intern' is called.

Function `vcomp-normalize' can be used to normalize a version string.

  0-11A-Alpha0-r1 => 0.11a_alpha-r1
  2.3d-BETA5      => 2.3d_beta5

That's the way I like my version strings; if you would like this to
be customizable please let me know.
