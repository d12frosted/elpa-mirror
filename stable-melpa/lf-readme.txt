This library provides common desirable “L”anguage “F”eatures:

0. A unifed interface for defining both variables and functions. LF-DEFINE.

1. A way to define typed, constrained, variables. LF-DEFINE.

2. A way to define type specifed functions. LF-DEFINE.

3. A macro to ease variable updates:  (lf-define very-long-name (f it))
                                    ≋ (setq very-long-name (f very-long-name))

4. A more verbose, yet friendlier, alternative to SETF: LF-DEFINE.


Minimal Working Example:

    (lf-define age 0 [(integerp it) (<= 0 it 100)])

    (lf-define age 123) ;; ⇒ Error: Existing constraints for “age” violated!
                        ;;  “age” is not updated; it retains old value.

    (lf-define age 29)  ;; OK, “age” is now 29.


This file has been tangled from a literate, org-mode, file.

There are numerous examples in tests.el.
