This library provides new names for old functions.

Many core Lisp functions do not abide by the "package prefix convention"
that Elisp packages are expected to follow, and instead use a naming
that makes for names that sound closer to "plain English", typically
using the form "VERB-NOUN" to focus on what the function does rather
then what it operates on.

In this library, we try to group functions based on their "subject"
and make them share a common prefix.

While this may seem like a futile and impossible endeavor (many functions
can arguably be reasonably placed in several different groups), I think it
can be sufficiently useful, that it is worth trying to get a bit closer to
this impossible goal.

Some of the expected benefits are:
- Making some functionality more discoverable.
- Helping to write code using prefix-based completion.
- Better match the tradition followed in pretty much all programming
  languages (including Elisp, for non-core functions).