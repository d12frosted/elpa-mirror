The default behavior of ido SPACE key will try to insert SPACE if it makes
sense (a.k.a, the common part of all matches contains SPACE). However,
when ido is used to complete lisp functions or variables, like what smex
does, HYPHEN is used as separator. This extension for ido inserts SPACE or
HYPHEN whenever either one makes sense, just like what built-in M-x does.

Example:

(ido-completing-read "test: " '("ido-foo-bar" "ido-space" "ido-test"))

    | Key Sequence | Result |
    |--------------+--------|
    | i            | "i"    |
    | SPACE        | "ido-" |

(ido-completing-read "test: " '("ido foo-bar" "ido space" "ido test"))

    | Key Sequence | Result |
    |--------------+--------|
    | i            | "i"    |
    | SPACE        | "ido " |

(ido-completing-read "test: " '("ido-foo-bar" "ido-space" "idotest"))

    | Key Sequence | Result |
    |--------------+--------|
    | i            | "i"    |
    | SPACE        | "ido"  |
    | SPACE        | "ido-" |

When HYPHEN can be inserted and SPACE cannot, insert HYPHEN when user enter SPACE.

(ido-completing-read "test: " '("ido-foo-bar" "ido-space" "ido test"))

    | Key Sequence | Result                           |
    |--------------+----------------------------------+
    | i            | "i"                              |
    | SPACE        | "ido"                            |
    | SPACE        | "ido"  Completion popup is shown |
    | SPACE        | "ido "                           |

If both HYPHEN and SPACE can be inserted, SPACE first brings the completion
popup window, if user types SPACE again, then SPACE itself is inserted.
