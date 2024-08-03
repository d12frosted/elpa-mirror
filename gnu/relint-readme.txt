                relint -- Emacs regexp mistake finder
                =====================================

Relint scans Emacs Lisp files for mistakes in regexps, including
deprecated syntax and bad practice. It also checks the regexp-like
arguments to the functions skip-chars-forward, skip-chars-backward,
skip-syntax-forward and skip-syntax-backward.

* Contents

   - Usage
   - Installation
   - Configuration
   - What the diagnostics mean
   - Suppressing diagnostics
   - How it works
   - Bugs


* Usage

  - Check a single file:

      M-x relint-file

  - Check all .el files in a directory tree:

      M-x relint-directory

  - Check current buffer:

      M-x relint-current-buffer

  In the *relint* buffer, pressing "g" will re-run the same check.

  - From batch mode:

      emacs -batch -l relint -f relint-batch FILES-AND-DIRS...

    where directories are scanned recursively.
    (Options for finding relint and xr need to be added after
    -batch, either -f package-initialize or -L DIR.)

  - From Emacs Lisp code, use one of the above functions or

      (relint-buffer BUFFER)

    which returns a list of diagnostics.

  - From other packages:

    The flycheck-relint and flymake-relint packages run relint
    automatically via flycheck and flymake, respectively.
    They are available from the MELPA package archive.


* Installation

  From GNU ELPA (https://elpa.gnu.org/packages/relint.html):

    M-x package-install RET relint RET

  Relint requires the package xr (https://elpa.gnu.org/packages/xr.html);
  it will be installed automatically.


* User options

  - variable 'relint-xr-checks'

      If set to 'all', it enables checks that detect more errors and
      performance problems but may also produce more false warnings.
      The default value is 'nil' which limits warnings to ones that
      are likely to be accurate.

  - variable 'relint-batch-highlight'

      This variable controls the diagnostics output of 'relint-batch'.
      If set to a string pair (BEGIN . END), these strings will be
      used to highlight the part of a regexp that a message is talking
      about. The default value makes that part appear in reverse video
      in a (VT100-compatible) terminal.
      The value 'caret' uses ASCII symbols to mark the interesting part
      instead.
      The value 'nil' disables highlighting entirely.

  - face 'relint-buffer-highlight'

      This is the face used to highlight text warned about for a
      message appearing in the '*relint*' buffer.


* What the diagnostics mean

  Tip: if a regexp string is difficult to understand, consider
  using 'xr' to decode it, as in (xr-pp "your-messy-regexp").

  - Unescaped literal 'X'

    A special character is taken literally because it occurs in a
    position where it does not need to be backslash-escaped. It is
    good style to do so anyway (assuming that it should occur as a
    literal character).

  - Escaped non-special character 'X'
  
    A character is backslash-escaped even though this is not necessary
    and does not turn it into a special sequence. Maybe the backslash
    was in error, or should be doubled if a literal backslash was
    expected.
  
  - Duplicated 'X' inside character alternative
  
    A character occurs twice inside [...]; this is obviously
    pointless. In particular, backslashes are not special inside
    [...]; they have no escaping power, and do not need to be escaped
    in order to include a literal backslash.
  
  - Repetition of repetition
  - Repetition of option
  - Optional repetition
  - Optional option
  
    A repetition construct is applied to an expression that is already
    repeated, such as a*+ or \(x?\)?. These expressions can be written
    with a single repetition and often indicate a different mistake,
    perhaps a missing backslash.

    When a repetition construct is ? or ??, it is termed 'option'
    instead; the principle is the same.

  - Reversed range 'Y-X' matches nothing

    The last character of a range precedes the first and therefore
    includes no characters at all (not even the endpoints). Most such
    ranges are caused by a misplaced hyphen.

  - Character 'B' included in range 'A-C'
  - Range 'A-C' includes character 'B'

    A range includes a character that also occurs individually. This
    is often caused by a misplaced hyphen.

  - Ranges 'A-M' and 'D-Z' overlap

    Two ranges have at least one character in common. This is often
    caused by a misplaced hyphen.

  - Two-character range 'A-B'

    A range only consists of its two endpoints, since they have
    consecutive character codes. This is often caused by a misplaced
    hyphen.

  - Range 'A-z' between upper and lower case includes symbols

    A range spans over upper and lower case letters, which also
    includes some symbols. This is probably unintentional. To cover
    both upper and lower case letters, use separate ranges, as in
    [A-Za-z].

  - Suspect character range '+-X': should '-' be literal?

    A range has + as one of its endpoints, which could mean that the
    hyphen was actually intended to be literal in order to match both
    + and -.
    This check is only enabled when relint-xr-checks = all.

  - Possibly erroneous '\X' in character alternative

    A character alternative includes something that looks like a
    escape sequence, but no escape sequences are allowed there since
    backslash is not a special character in that context.
    It could also be a caused by too many backslashes.

    For example, "[\\n\\t]" matches the characters 'n', 't' and
    backslash, but could be an attempt to match newline and tab.
    This check is only enabled when relint-xr-checks = all.

  - Duplicated character class '[:class:]'

    A character class occurs twice in a single character alternative
    or skip set.

  - Or-pattern more efficiently expressed as character alternative

    When an or-pattern can be written as a character alternative, it
    becomes more efficient and reduces regexp stack usage.
    For example, a\|b is better written [ab], and \s-\|\sw is usually
    better written [[:space:][:word:]]. (There is a subtle difference
    in how syntax properties are handled but it rarely matters.)
    This check is only enabled when relint-xr-checks = all.

  - Duplicated alternative branch

    The same expression occurs in two different branches, like in
    A\|A. This has the effect of only including it once.

  - Branch matches superset/subset of a previous branch

    A branch in an or-expression matches a superset or subset of what
    another branch matches, like in [ab]\|a. This means that one of
    the branches can be eliminated without changing the meaning of the
    regexp.

  - Repetition subsumes/subsumed by preceding repetition

    An repeating expression matches a superset or subset of what the
    previous expression matches, in such a way that one of them is
    unnecessary. For example, [ab]+a* matches the same text as [ab]+,
    so the a* could be removed without changing the meaning of the
    regexp.

  - First/last item in repetition subsumes last/first item (wrapped)

    The first and last items in a repeated sequence, being effectively
    adjacent, match a superset or subset of each other, which makes
    for an unexpected inefficiency. For example, \(?:a*c[ab]+\)* can
    be seen as a*c[ab]+a*c[ab]+... where the [ab]+a* in the middle is
    a slow way of writing [ab]+ which is made worse by the outer
    repetition. The general remedy is to move the subsumed item out of
    the repeated sequence, resulting in a*\(?:c[ab]+\)* in the example
    above.

  - Non-newline follows end-of-line anchor
  - Line-start anchor follows non-newline

    A pattern that does not match a newline occurs right after an
    end-of-line anchor ($) or before a line-start anchor (^).
    This combination can never match.

  - Non-empty pattern follows end-of-text anchor

    A pattern that only matches a non-empty string occurs right after
    an end-of-text anchor (\'). This combination can never match.

  - Use \` instead of ^ in file-matching regexp
  - Use \' instead of $ in file-matching regexp

    In a regexp used for matching a file name, newlines are usually
    not relevant. Line-start and line-end anchors should therefore
    probably be replaced with string-start and string-end,
    respectively. Otherwise, the regexp may fail for file names that
    do contain newlines.

  - Possibly unescaped '.' in file-matching regexp

    In a regexp used for matching a file name, a naked dot is usually
    more likely to be a mistake (missing escaping backslash) than an
    actual intent to match any character except newline, since literal
    dots are very common in file name patterns.

  - Uncounted repetition

    The construct A\{,\} repeats A zero or more times which was
    probably not intended.

  - Implicit zero repetition

    The construct A\{\} only matches the empty string, which was
    probably not intended.

  - Suspect '[' in char alternative

    This warning indicates badly-placed square brackets in a character
    alternative, as in [A[B]C]. A literal ] must come first
    (possibly after a negating ^).

  - Literal '-' not first or last

    It is good style to put a literal hyphen last in character
    alternatives and skip sets, to clearly indicate that it was not
    intended as part of a range.

  - Repetition of zero-width assertion
  - Optional zero-width assertion

    A repetition operator was applied to a zero-width assertion, like
    ^ or \<, which is completely pointless. The error may be a missing
    escaping backslash.

  - Repetition of expression matching an empty string
  - Optional expression matching an empty string

    A repetition operator was applied to a sub-expression that could
    match the empty string; this is not necessarily wrong, but such
    constructs run very slowly on Emacs's regexp engine. Consider
    rewriting them into a form where the repeated expression cannot
    match the empty string.

    Example: \(?:a*b*\)* is equivalent to the much faster \(?:a\|b\)*.

    Another example: \(?:a?b*\)? is better written a?b*. 

    In general, A?, where A matches the empty string, can be
    simplified to just A.

  - Repetition of effective repetition

    A repetition construct is applied to an expression that itself
    contains a repetition, in addition to some patterns that may match
    the empty string. This can lead to bad matching performance.

    Example: \(?:a*b+\)* is equivalent to the much faster \(?:a\|b\)* .

    Another example: \(?:a*b+\)+ is better written a*b[ab]* .

  - Possibly mistyped ':?' at start of group

    A group starts as \(:? which makes it likely that it was really
    meant to be \(?: -- ie, a non-capturing group.
    This check is only enabled when relint-xr-checks = all.

  - Unnecessarily escaped 'X'

    A character is backslash-escaped in a skip set despite not being
    one of the three special characters - (hyphen), \ (backslash) and
    ^ (caret). It could be unnecessary, or a backslash that should
    have been escaped.

  - Single-element range 'X-X'

    A range in a skip set has identical first and last elements. It is
    rather pointless to have it as a range.

  - Stray '\\' at end of string

    A single backslash at the end of a skip set is always ignored;
    double it if you want a literal backslash to be included.

  - Suspect skip set framed in '[...]'

    A skip set appears to be enclosed in [...], as if it were a
    regexp. Skip sets are not regexps and do not use brackets. To
    include the brackets themselves, put them next to each other.

  - Suspect character class framed in '[...]'

    A skip set contains a character class enclosed in double pairs of
    square brackets, as if it were a regexp. Character classes in skip
    sets are written inside a single pair of square brackets, like
    [:digit:].

  - Empty set matches nothing

    The empty string is a skip set that does not match anything, and
    is therefore pointless.

  - Negated empty set matches anything

    The string "^" is a skip set that matches anything, and is therefore
    pointless.

  - 'X' cannot be used for arguments to 'F'

    An expression that looks like a regexp was given as an argument to
    a function that expects a skip-set.

  - Value from 'X' cannot be spliced into '[...]'

    An expression that looks like a regexp was used to form a string
    where it is surrounded by square brackets, as if it were part of a
    character alternative. Regexps are not valid inside character
    alternatives; they use a different syntax.

    If you are just building a string containing a regexp for display
    purposes, consider using other delimiters than square brackets;
    displaying the regexp 0-9 as [0-9] is very misleading.

  - Invalid char 'X' in syntax string

    A string argument to skip-syntax-forward or skip-syntax-backward
    contains a character that doesn't indicate a syntax class. Such a
    string is not a regexp or skip-set, but just a string of syntax
    codes, possibly with a leading ^ for negation.

  - Duplicated char 'X' in syntax string

    A string argument to skip-syntax-forward or skip-syntax-backward
    contains a duplicated class, which is pointless and may indicate a
    mistake. Note that some characters indicate the same syntax class:
    '.' and ' ' (space) both mean the 'space' class.

  - Empty syntax string

    A string argument to skip-syntax-forward or skip-syntax-backward
    is empty or "^", neither of which makes sense.

  - Ineffective string escape '\X'

    A backslash precedes a character that does not need escaping in a
    string literal (any string, not just regexps), like in "hot\-dog".

    If the backslash should be part of the string then it probably
    needs to be doubled; otherwise, it is pointless and should be
    removed to avoid confusion.

    In Emacs versions older than 27.1, a left round or square bracket,
    '(' or '[', at the very start of a line in a multi-line string
    could sometimes fool the Emacs-Lisp mode into believing it to be
    the start of a function, thus people sometimes precede such
    brackets with an otherwise unnecessary backslash. However, there
    is usually no reason to put backslashes before brackets in strings
    in general.

  - Character escape '\x' not followed by hex digit

    In Emacs versions older than 30.1, a hex escape without any actual
    hex digits, as in "\x", was silently accepted as a null byte which
    is not what anyone would expect. If the backslash should be
    included in the string, double it as usual.

  - Suspect range '+-X' or 'X-+'

    A character range with '+' as one of its endpoints is more often an
    incorrect attempt to include both '+' and '-' in the set.


* Suppressing diagnostics

  While relint has been designed to avoid false positives, there may
  be cases where it emits unfounded complaints. Most of the time, it
  is worth the trouble to change the code to make them go away, but
  sometimes it cannot be done in a reasonable way.

  To suppress such diagnostics, add a comment on the form

    ;; relint suppression: REGEXP

  on the line before the code where the error occurred. REGEXP
  matches the message to be suppressed. Multiple suppression
  comment lines can precede a line of code to eliminate several
  complaints on the same line.


* How it works

  Relint uses a combination of ad-hoc rules to locate regexps:

  - Arguments to certain standard functions such as re-search-forward,
    or to user-defined functions whose arguments have regexp-sounding
    names (like 'regexp')

  - Values of variables believed to be a regexp from their name
    (ending in '-regexp', for instance), from their doc string,
    or from their type (for defcustom forms)

  - Assignment to certain standard variables, such as page-delimiter

  It will then try to evaluate expressions statically as far as
  possible in order to arrive at strings which can be analysed. The
  regexp analysis is done by the xr library.

  This means that if relint complains about something that isn't
  actually a regexp, some names in your code may be misleading.


* Bugs

  The simplistic method employed means that many errors will go
  undetected, but false warnings are usually rare.

  If you believe that an error could have been discovered but wasn't,
  or that an unwarranted complaint could be avoided, please report it
  as a bug.

  If you find a complaint hard to understand, don't be afraid to ask.
  Maybe it could be explained in a better way.
